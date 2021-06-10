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
    let semaphore = DispatchSemaphore(value: 1)
    internal init(urlType: URLType, endPoint: EndPoint = .undefined, allowMultiOperation: Bool = false) {
        self.baseURL = urlType.rawValue
        self.endPoint = endPoint
        self.sessionCfg = URLSessionConfiguration.default
        self.sessionCfg.timeoutIntervalForRequest = 30.0
        self.session = URLSession(configuration: sessionCfg)
        self.allowMultiOperation = allowMultiOperation
        queue.qualityOfService = .background
        queue.maxConcurrentOperationCount = 1
    }

    public func setUrlType(_ urlType: URLType) {
        self.baseURL = urlType.rawValue
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
        semaphore.wait()
        let completion: (Result<ResponseType, Error>) -> Void = {result in
            callback?(result)
            if self.backgroundTaskId != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
            GlobalLogger.shared.verbose("APIWorker ends backgroundTask with identifier : \( self.backgroundTaskId)")
                self.backgroundTaskId = .invalid
            }
            self.currentTask = nil
            self.semaphore.signal()
        }
        guard let url = URL(string: buildURL(endPoint: endPoint)) else {
            completion(Result.failure(NetworkError.badUrl))
            return
        }
        if (queue.operationCount == 0 || allowMultiOperation) && ready  {
            if self.backgroundTaskId == .invalid {
            self.backgroundTaskId = UIApplication.shared.beginBackgroundTask(
                withName: "herow.io.APIWorker.backgroundTaskID" + url.absoluteString,
                expirationHandler: {
                    if self.backgroundTaskId != .invalid {
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskId)
                    GlobalLogger.shared.verbose("APIWorker ends backgroundTask with identifier : \( self.backgroundTaskId)")
                        self.backgroundTaskId = .invalid
                    }
                })
            }
            let blockOPeration = BlockOperation { [weak self] in
                var request = URLRequest(url: url)
                request.allHTTPHeaderFields = self?.headers
                request.httpMethod = method.rawValue
                if let param = param {
                    request.httpBody = param
                }

                self?.currentTask = self?.session.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
                    if let _ = error {
                        completion(Result.failure(NetworkError.badUrl))
                        return
                    }
                    guard let response = response as? HTTPURLResponse  else {
                        GlobalLogger.shared.error(NetworkError.invalidResponse)
                        completion(Result.failure(NetworkError.invalidResponse))
                        return
                    }
                    let statusCode = response.statusCode
                    self?.statusCodeListener?.didReceiveResponse(statusCode)
                    if (HttpStatusCode.HTTP_OK..<HttpStatusCode.HTTP_MULT_CHOICE) ~= statusCode {
                        guard let data = data  else {
                            completion(Result.failure(NetworkError.noData))
                            return
                        }
                        do {
                            self?.responseHeaders = response.allHeaderFields
                            let jsonResponse = (String(decoding: data, as: UTF8.self))
                            GlobalLogger.shared.debug("APIWorker - \(endPoint.value) response: \n\(jsonResponse)")
                            if type != NoReply.self {
                                if let responseObject  = try self?.decoder.decode(type, from: data) {
                                    GlobalLogger.shared.verbose("APIWorker - \(url) success : \(statusCode) headers:\((self?.headers) ?? [String:String]() )")
                                completion(Result.success(responseObject))
                                return
                                } else {
                                    GlobalLogger.shared.verbose("APIWorker - \(url) fail : responseObject nil")
                                    completion(Result.failure(NetworkError.noData))
                                    return
                                }
                            }
                            let voidResponse = NoReply()
                            completion(Result.success(voidResponse as! ResponseType))
                        } catch {
                            GlobalLogger.shared.error(NetworkError.serialization)
                            completion(Result.failure(NetworkError.serialization))
                            self?.currentTask = nil
                        }
                    } else {
                        GlobalLogger.shared.error("APIWorker - \(url) \(NetworkError.invalidStatusCode) : \(statusCode) headers:\((self?.headers) ?? [String:String]() )")
                        completion(Result.failure(NetworkError.invalidStatusCode))

                    }
                })
                self?.currentTask?.resume()
            }
            queue.addOperation(blockOPeration)
        } else {
            GlobalLogger.shared.error("APIWorker - \(url) \(NetworkError.requestExistsInQueue)")
            completion(Result.failure(NetworkError.requestExistsInQueue))
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
