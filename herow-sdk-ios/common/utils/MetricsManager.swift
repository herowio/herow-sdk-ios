//
//  MetricManager.swift
//  ConnectPlaceCommon
//
//  Created by Damien on 15/07/2020.
//

import Foundation
import MetricKit
import UIKit
@objc public class MetricsManager: NSObject, MXMetricManagerSubscriber, ResetDelegate {
   public static let MetricsFileNameKey = "METRIC_FILE_NAME_KEY"
    let df = DateFormatter()
    public  override init() {
        super.init()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        if #available(iOS 13.0, *) {
            MXMetricManager.shared.add(self)
        } else {
            GlobalLogger.shared.debug("MetricsManager - works only for ios > ios13")
        }
    }

    deinit {
        if #available(iOS 13.0, *) {
            MXMetricManager.shared.remove(self)
        } else {
            GlobalLogger.shared.debug("MetricsManager - works only for ios > ios13")
        }
    }

    @available(iOS 13.0, *)
    public func didReceive(_ payloads: [MXMetricPayload]) {
        reset()
        saveToFile(payloads)
        //Send to server for processing
    }

    @available(iOS 13.0, *)
    func saveToFile(_ payloads: [MXMetricPayload]) {
        DispatchQueue.global(qos: .background).async {
            var data = Data()
            for payload in payloads {
                data.append(payload.jsonRepresentation())
            }

            let now = self.df.string(from: Date())
            let filename = "metrics - \(UIDevice.current.identifierForVendor?.uuidString ?? "no device id") - \(now).txt"

            if FileUtils.saveToFileSync(fileName: filename, data: data) == false {
                GlobalLogger.shared.debug("MetricsManager - fail to save metrics on file")
            } else {
                UserDefaults.standard.set(filename, forKey: MetricsManager.MetricsFileNameKey)
                UserDefaults.standard.synchronize()
            }
        }
    }

    public func getLastMetricsName() -> String? {
        return UserDefaults.standard.string(forKey: MetricsManager.MetricsFileNameKey)
    }

    public func getLastPayloads( _ callBack: ((Data?)->())?) {
        DispatchQueue.global(qos: .background).async {
            guard let filename =  UserDefaults.standard.string(forKey: MetricsManager.MetricsFileNameKey) else {
                callBack?(nil)
                return
            }
            let data = FileUtils.loadFromFileSync(fileName: filename)
            DispatchQueue.main.async {
                callBack?(data)
            }
        }
    }

    public func reset(completion: ()->()) {
        DispatchQueue.global(qos: .background).async {
            guard let filename =  UserDefaults.standard.string(forKey: MetricsManager.MetricsFileNameKey) else {
                return
            }

            if FileUtils.deleteFileSync(fileName: filename) == false {
                GlobalLogger.shared.debug("MetricsManager - fail to delete metrics on file")
            } else {
                UserDefaults.standard.removeObject(forKey: MetricsManager.MetricsFileNameKey)
                UserDefaults.standard.synchronize()
            }

        }
        completion()
    }
}
