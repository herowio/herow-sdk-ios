//
//  APIWorker.swift
//  herow-sdk-ios
//
//  Created by Damien on 19/01/2021.
//

import Foundation
import UIKit

private enum Method: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
}

protocol APIWorkerProtocol {
    associatedtype ResponseType
    func getData(completion: @escaping (ResponseType?, NetworkError?) -> Void)
}

internal class APIWorker<T: Decodable>: APIWorkerProtocol {

    typealias ResponseType = T
    private var session: URLSession
    private var sessionCfg: URLSessionConfiguration
    private var currentTask: URLSessionDataTask?
    private let baseURL: String
    private let endPoint: String
    var headers: [String:String]?
    
    internal init(urlType: URLType, endPoint: EndPoint) {
        self.baseURL = urlType.rawValue
        self.endPoint = endPoint.rawValue
        self.sessionCfg = URLSessionConfiguration.default
        self.sessionCfg.timeoutIntervalForRequest = 10.0
        self.session = URLSession(configuration: sessionCfg)
    }
    private func buildURL() -> String {
        return baseURL + endPoint
    }

    private func get<ResponseType:Decodable>( _ type: ResponseType.Type, callback: ((Result<ResponseType, Error>) -> Void)?) {
        doMethod(type, method: .get, callback: callback)
    }

    private func post<ResponseType:Decodable>( _ type: ResponseType.Type, param: Data?, callback: ((Result<ResponseType, Error>) -> Void)?) {
        doMethod(type, method: .post ,param: param, callback: callback)
    }

    private func put<ResponseType:Decodable>( _ type: ResponseType.Type, param: Data?, callback: ((Result<ResponseType, Error>) -> Void)?) {
        doMethod(type, method: .put ,param: param, callback: callback)
    }

    private  func doMethod<ResponseType: Decodable>( _ type: ResponseType.Type,method: Method, param: Data? = nil, callback: ((Result<ResponseType, Error>) -> Void)?)  {

        let completion: (Result<ResponseType, Error>) -> Void = {result in
            callback?(result)
            self.currentTask = nil
        }

        if let task = currentTask {
            task.cancel()
        }
        guard let url = URL(string: buildURL()) else {
            completion(Result.failure(NetworkError.badUrl))
            return
        }
        var request = URLRequest(url: url)
        if let headers = self.headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        request.httpMethod = method.rawValue
        if let param = param {
            request.httpBody = param
        }
        currentTask = session.dataTask(with: request, completionHandler: { (data, response, error) in
            if let error = error {
                completion(Result.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse  else {
                completion(Result.failure(NetworkError.invalidResponse))
                return
            }
            if (HttpStatusCode.HTTP_OK..<HttpStatusCode.HTTP_MULT_CHOICE) ~= response.statusCode {
                guard let data = data  else {
                    completion(Result.failure(NetworkError.noData))
                    return
                }
                do {
                    let decoder = JSONDecoder()
                    let responseObject  = try decoder.decode(type, from: data)
                    completion(Result.success(responseObject))

                } catch {
                    print(error)
                    completion(Result.failure(NetworkError.serialization))
                    self.currentTask = nil
                }
            } else {
                completion(Result.failure(NetworkError.invalidStatusCode))

            }
        })
        currentTask?.resume()
    }

   internal func getData(completion: @escaping (ResponseType?, NetworkError?) -> Void) {
        var data: ResponseType?
        var netWorkError: NetworkError? = nil
        self.get(ResponseType.self) { (result) in
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
