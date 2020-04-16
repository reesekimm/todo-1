//
//  NetworkManager.swift
//  ToDoListApp
//
//  Created by Cory Kim on 2020/04/09.
//  Copyright © 2020 corykim0829. All rights reserved.
//

import Foundation

enum RequestError: String, Error, CustomStringConvertible {
    case ServerError = "서버 통신 요청에 실패했습니다."
    case URLSessionError = "네트워크 요청에 실패했습니다."
    case JSONDecodingError = "데이터를 가져오는 중에 오류가 발생했습니다."
    case UnauthorizedError = "아이디와 비밀번호를 확인해주세요"
    
    var description: String {
        return self.rawValue
    }
}

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private let baseURL = "http://13.124.169.123"
    
    private func requestDataToServer(method: NetworkManager.methodType, token: String? = nil, completion: @escaping (Result<Data?, RequestError>) -> Void) {
        let successStatusCode = 200
        var urlRequest = RequestURL(path: "/api/columns", method: method)
        if let token = token {
            urlRequest.setValue("jwt=\(token)", forHTTPHeaderField: "Cookie")
        }
        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let response = response as? HTTPURLResponse else { return }
            if response.statusCode != successStatusCode {
                completion(.failure(.ServerError))
                return
            }
            if error != nil {
                completion(.failure(.URLSessionError))
                return
            }
            completion(.success(data))
        }.resume()
    }
    
    private func requestLogInToServer(body: Data?, completion: @escaping (Result<(String, UserInfo), RequestError>) -> Void) {
        let successStatusCode = 200
        let unauthorizedStatusCode = 401
        
        URLSession.shared.dataTask(with: RequestURL(path: "/api/login", method: .post, body: body)) { (data, response, error) in
            guard
                let url = response?.url,
                let response = response as? HTTPURLResponse,
                let fields = response.allHeaderFields as? [String: String]
                else { return }
            
            let cookies = HTTPCookie.cookies(withResponseHeaderFields: fields, for: url)
            HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
            var token = ""
            
            for cookie in cookies {
                var cookieProperties = [HTTPCookiePropertyKey: Any]()
                cookieProperties[.name] = cookie.name
                cookieProperties[.value] = cookie.value
                cookieProperties[.domain] = cookie.domain
                cookieProperties[.path] = cookie.path
                cookieProperties[.version] = cookie.version
                cookieProperties[.expires] = Date().addingTimeInterval(31536000)

                let newCookie = HTTPCookie(properties: cookieProperties)
                HTTPCookieStorage.shared.setCookie(newCookie!)

                token = cookie.value
            }
            
            switch response.statusCode {
            case unauthorizedStatusCode:
                completion(.failure(.UnauthorizedError)); return
            case successStatusCode: break
            default: break
            }
            
            if error != nil {
                completion(.failure(.URLSessionError))
                return
            }
            
            guard let data = data else {
                completion(.failure(.ServerError))
                return
            }
            
            let decoder = JSONDecoder()
            guard let userInfo = try? decoder.decode(UserInfo.self, from: data) else {
                completion(.failure(.JSONDecodingError))
                return
            }
            
            completion(.success((token, userInfo)))
        }.resume()
    }
    
    func requestData<T: Codable>(method: NetworkManager.methodType = .get, token: String?, completion: @escaping (Result<T, RequestError>) -> Void) {
        requestDataToServer(method: method, token: token) { (result) in
            switch result {
            case .success(let data):
                let decoder = JSONDecoder()
                guard let data = data else { return }
                guard let userData = try? decoder.decode(T.self, from: data) else {
                    completion(.failure(.JSONDecodingError))
                    return
                }
                completion(.success(userData))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func requestLogIn(user: User, completion: @escaping (Result<(String, UserInfo), RequestError>) -> Void) {
        let encoder = JSONEncoder()
        let data = try? encoder.encode(user)
        requestLogInToServer(body: data) { (result) in
            switch result {
            case .success((let token, let userInfo)):
                completion(.success((token, userInfo)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    func requestDataWithBody<ResponseData: Decodable, T: Encodable>(method: methodType, body: T, optionalData: Any? = nil, completion: @escaping (Result<ResponseData, RequestError>) -> Void) {
        
        let encoder = JSONEncoder()
        let encodedData = try? encoder.encode(body)
        guard let columnId = optionalData as? Int else { return }
        let request = RequestURL(path: "/api/columns/\(columnId)/cards", method: method, body: encodedData)
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            let decoder = JSONDecoder()
            guard let data = data else {
                completion(.failure(.ServerError))
                return
            }
            guard let decodedData = try? decoder.decode(ResponseData.self, from: data) else {
                completion(.failure(.JSONDecodingError))
                return
            }
            if error != nil {
                completion(.failure(.URLSessionError))
            }
            completion(.success(decodedData))
        }.resume()
    }
    
    func requestData(from URLString: String, method: NetworkManager.methodType = .get, completion: @escaping (Result<Data, RequestError>) -> Void) {
        guard let url = URL(string: URLString) else { return }
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data else {
                completion(.failure(.URLSessionError))
                return
            }
            if error != nil {
                completion(.failure(.URLSessionError))
                return
            }
            completion(.success(data))
        }.resume()
    }
}

extension NetworkManager {
    
    enum methodType: String, CustomStringConvertible {
        case get = "get"
        case put = "put"
        case post = "post"
        case delete = "delete"
        
        var description: String {
            return self.rawValue
        }
    }
    
    private func RequestURL(path: String, method: methodType, body: Data? = nil) -> URLRequest {
        let URLForRequest = URL(string: baseURL + path)!
        var request = URLRequest(url: URLForRequest)
        request.httpMethod = method.description
        if body != nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        return request
    }
}
