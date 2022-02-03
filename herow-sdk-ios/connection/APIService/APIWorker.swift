//
//  APIWorker.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation
import UIKit


protocol RequestStatusListener: AnyObject {
    func didReceiveResponse(_ statusCode: Int)
}
internal enum Method: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

protocol APIWorkerProtocol {
    associatedtype ResponseType
    func getData(endPoint: EndPoint , completion: @escaping (ResponseType?, NetworkError?) -> Void)
    
}

internal class APIWorker<T: Decodable>: APIWorkerProtocol {

    typealias ResponseType = T
    var shouldHaveResponse = true
    var queue = OperationQueue()
    private var session: URLSession
    private var sessionCfg: URLSessionConfiguration
    private var currentTask: URLSessionDataTask?
    private var baseURL: String
    private let endPoint: EndPoint
    private let decoder = JSONDecoder()
    weak  var  statusCodeListener: RequestStatusListener?
    var headers = [String:String]()
    var responseHeaders: [AnyHashable: Any]?
    private var backgroundTaskId: UIBackgroundTaskIdentifier =  UIBackgroundTaskIdentifier.invalid
    private var allowMultiOperation: Bool = false
    private var ready = false
    private var blockOPeration : BlockOperation?
    private var completion: ((Result<ResponseType, Error>) -> Void)?
    internal init(urlType: URLType, endPoint: EndPoint = .undefined, allowMultiOperation: Bool = false) {
        self.baseURL = urlType.value
        self.endPoint = endPoint
        self.sessionCfg = URLSessionConfiguration.default
        self.sessionCfg.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: sessionCfg)
        self.allowMultiOperation = allowMultiOperation
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
    }

    func reset() {
        self.currentTask = nil
        self.queue.cancelAllOperations()
    }
    public func setUrlType(_ urlType: URLType) {
        self.baseURL = urlType.value
        ready = true
    }

    internal func buildURL(endPoint: EndPoint) -> String {
        var realEndPoint = endPoint

        switch endPoint {
        case.undefined:
            realEndPoint = self.endPoint
        default: break
        }
        return baseURL + realEndPoint.value
    }

    internal func get<ResponseType:Decodable>( _ type: ResponseType.Type, endPoint: EndPoint = .undefined, callback: ((Result<ResponseType, Error>) -> Void)?) {
        doMethod(type, method: .get,endPoint: endPoint, callback: callback)
    }

    internal func post<ResponseType:Decodable>( _ type: ResponseType.Type, param: Data?, callback: ((Result<ResponseType, Error>) -> Void)?) {
        doMethod(type, method: .post ,param: param, callback: callback)
    }

    internal func put<ResponseType:Decodable>( _ type: ResponseType.Type, param: Data?, callback: ((Result<ResponseType, Error>) -> Void)?) {
        doMethod(type, method: .put ,param: param, callback: callback)
    }

    internal  func doMethod<ResponseType: Decodable>( _ type: ResponseType.Type,method: Method, param: Data? = nil, endPoint: EndPoint = .undefined, callback: ((Result<ResponseType, Error>) -> Void)?)  {

        var task: URLSessionDataTask?
        self.completion = {result in
            callback?(result as! Result<ResponseType, Error>)
            self.queue.cancelAllOperations()
            self.currentTask = nil
            if self.backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
            GlobalLogger.shared.info("APIWorker ends backgroundTask with identifier : \( self.backgroundTaskId)")
                self.backgroundTaskId = .invalid
            }
        }

        if !Reachability.isConnectedToNetwork() {
            GlobalLogger.shared.warning("APIWorker - \(self.endPoint.value) response: \(NetworkError.noNetwork)")

            completion?(Result.failure(NetworkError.noNetwork))
            return
        }

        guard let url = URL(string: buildURL(endPoint: endPoint)) else {
<<<<<<< HEAD
            GlobalLogger.shared.warning("APIWorker - \(self.endPoint.value) response: \(NetworkError.badUrl)")
            completion(Result.failure(NetworkError.badUrl))
=======
            completion?(Result.failure(NetworkError.badUrl))
>>>>>>> 7bbe320 (Update apiworker)
            return
        }

        if currentTask != nil && allowMultiOperation == false {
<<<<<<< HEAD
            GlobalLogger.shared.warning("APIWorker - \(self.endPoint.value) response: \(NetworkError.workerStillWorking)")
            completion(Result.failure(NetworkError.workerStillWorking))
=======
            GlobalLogger.shared.error("APIWorker - \(self.endPoint.value) response: \(NetworkError.workerStillWorking)")
            completion?(Result.failure(NetworkError.workerStillWorking))
>>>>>>> 7bbe320 (Update apiworker)
            return
        }

        if (queue.operationCount == 0 || allowMultiOperation) && ready  {
            if self.backgroundTaskId == .invalid {
            self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                withName: "herow.io.APIWorker.backgroundTaskID" + url.absoluteString,
                expirationHandler: {
                    if self.backgroundTaskId != .invalid {
<<<<<<< HEAD
                        GlobalLogger.shared.warning("APIWorker - \(self.endPoint.value) response: \n\(NetworkError.backgroundTaskExpiration)")
                        completion(Result.failure(NetworkError.backgroundTaskExpiration))
=======
                        GlobalLogger.shared.error("APIWorker - \(self.endPoint.value) response: \n\(NetworkError.backgroundTaskExpiration)")
                        self.completion?(Result.failure(NetworkError.backgroundTaskExpiration))
>>>>>>> 7bbe320 (Update apiworker)
                    }
                })
            }
            blockOPeration = BlockOperation { [weak self] in
                var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 30)
                request.allHTTPHeaderFields = self?.headers
                request.httpMethod = method.rawValue
                if let param = param {
                    request.httpBody = param
                }

                task = self?.session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                    if let _ = error {
                        self?.completion?(Result.failure(NetworkError.badUrl))
                        return
                    }
                    guard let response = response as? HTTPURLResponse  else {
                        GlobalLogger.shared.error(NetworkError.invalidResponse)
                        self?.completion?(Result.failure(NetworkError.invalidResponse))
                        return
                    }
                    let statusCode = response.statusCode
                    self?.statusCodeListener?.didReceiveResponse(statusCode)
                    if (HttpStatusCode.HTTP_OK..<HttpStatusCode.HTTP_MULT_CHOICE) ~= statusCode {
                        guard let data = data  else {
                            self?.completion?(Result.failure(NetworkError.noData))
                            return
                        }
                        do {
                            self?.responseHeaders = response.allHeaderFields
                            let jsonResponse = (String(decoding: data, as: UTF8.self))
                            GlobalLogger.shared.debug("APIWorker - \(endPoint.value) response: \n\(jsonResponse)")
                            if type != NoReply.self {
                                if let responseObject  = try self?.decoder.decode(type, from: data) {
                                    GlobalLogger.shared.verbose("APIWorker - \(url) success : \(statusCode) headers:\(( request.allHTTPHeaderFields) ?? [String:String]() ), response:\(responseObject)")
                                    
                                    self?.completion?(Result.success(responseObject as! T))
                                return
                                } else {
<<<<<<< HEAD
                                    GlobalLogger.shared.error("APIWorker - \(url) fail : responseObject nil")
                                    completion(Result.failure(NetworkError.noData))
=======
                                    GlobalLogger.shared.verbose("APIWorker - \(url) fail : responseObject nil")
                                    self?.completion?(Result.failure(NetworkError.noData))
>>>>>>> 7bbe320 (Update apiworker)
                                    return
                                }
                            }
                            let voidResponse = NoReply()
                            self?.completion?(Result.success(voidResponse as! T))
                        } catch {
                            GlobalLogger.shared.error(NetworkError.serialization)
                            self?.completion?(Result.failure(NetworkError.serialization))

                        }
                    } else {
                        GlobalLogger.shared.error("APIWorker - \(url) \(NetworkError.invalidStatusCode) : \(statusCode) headers:\((self?.headers) ?? [String:String]() )")
                        self?.completion?(Result.failure(NetworkError.invalidStatusCode))

                    }
                })
                task?.resume()
                self?.currentTask = task
            }
            if let block = blockOPeration {
                queue.addOperation(block)
            }
        } else {
<<<<<<< HEAD
            GlobalLogger.shared.warning("APIWorker - \(url) \(NetworkError.requestExistsInQueue)")
            completion(Result.failure(NetworkError.requestExistsInQueue))
=======
            GlobalLogger.shared.error("APIWorker - \(url) \(NetworkError.requestExistsInQueue)")
            completion?(Result.failure(NetworkError.requestExistsInQueue))
>>>>>>> 7bbe320 (Update apiworker)
        }
    }

    internal func getData(endPoint: EndPoint = .undefined, completion: @escaping (ResponseType?, NetworkError?) -> Void) {
        var data: ResponseType?
        var netWorkError: NetworkError? = nil
        self.get(ResponseType.self, endPoint: endPoint) { (result) in
            switch result {
            case .success(let response):
                data = response
            case .failure(let error):
                netWorkError = error as? NetworkError
            }
            completion(data, netWorkError)
        }
    }

    internal func postData(param: Data? = nil,completion: @escaping (ResponseType?, NetworkError?) -> Void) {
        var data: ResponseType?
        var netWorkError: NetworkError? = nil
        self.post(ResponseType.self, param: param) { (result) in
            switch result {
            case .success(let response):
                data = response
            case .failure(let error):
                netWorkError = error as? NetworkError
            }
            completion(data, netWorkError)
        }
    }

    internal func putData(param: Data? = nil,completion: @escaping (ResponseType?, NetworkError?) -> Void) {
        var data: ResponseType?
        var netWorkError: NetworkError? = nil
        self.put(ResponseType.self, param: param) { (result) in
            switch result {
            case .success(let response):
                data = response
            case .failure(let error):
                netWorkError = error as? NetworkError
            }
            completion(data, netWorkError)
        }
    }
}
