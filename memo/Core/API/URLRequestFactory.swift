//
//  URLRequestFactory.swift
//  memo
//
//  Created by Vladimir Pavlov on 13/05/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

struct URLRequestFactory {

  // MARK: - Interface

  init(baseURL: URL) {
    self.baseURL = baseURL
  }

  func makeServerTimeRequest() -> URLRequest {
    return URLRequest(url: self.baseURL.appendingPathComponent("get_server_time"))
  }

  func makeNotesRequest(token: String, beginDate: Date? = nil) -> URLRequest {
    let url = self.baseURL.appendingPathComponent(PathComponent.notes.rawValue)

    var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)!
    if let beginDate = beginDate {
      let beginDateString = String(Int(beginDate.timeIntervalSince1970))
      urlComponents.queryItems = [URLQueryItem(name: "begin_date", value: beginDateString)]
    }

    var request = URLRequest(url: urlComponents.url!)
    request.setValue(token, forHTTPHeaderField: HTTPHeader.authorization.rawValue)
    return request
  }

  func makeCreateNoteRequest(token: String, note: Note, timeoutInterval: TimeInterval = 30) -> URLRequest? {
    var request = URLRequest(url: self.baseURL.appendingPathComponent(PathComponent.note.rawValue),
                             cachePolicy: .useProtocolCachePolicy,
                             timeoutInterval: timeoutInterval)
    request.httpMethod = HTTPMethod.post.rawValue
    request.setValue(token, forHTTPHeaderField: HTTPHeader.authorization.rawValue)
    request.setValue("\(ContentType.applicationJSON.rawValue); charset=utf-8",
      forHTTPHeaderField: HTTPHeader.contentType.rawValue)

    do {
      let encodedNote = try JSONEncoder().encode(note)
      request.httpBody = encodedNote
    } catch {
      return nil
    }

    return request
  }

  func makeUpdateNoteRequest(token: String, note: Note, timeoutInterval: TimeInterval = 30) -> URLRequest? {
    var request = URLRequest(url: self.baseURL.appendingPathComponent(PathComponent.note.rawValue),
                             cachePolicy: .useProtocolCachePolicy,
                             timeoutInterval: timeoutInterval)
    request.httpMethod = HTTPMethod.patch.rawValue
    request.setValue(token, forHTTPHeaderField: HTTPHeader.authorization.rawValue)
    request.setValue("\(ContentType.applicationJSON.rawValue); charset=utf-8",
      forHTTPHeaderField: HTTPHeader.contentType.rawValue)

    do {
      let encodedNote = try JSONEncoder().encode(note)
      request.httpBody = encodedNote
    } catch {
      return nil
    }

    return request
  }

  func makeDeleteNoteRequest(token: String, remoteID: UInt) -> URLRequest {
    var urlComponents = URLComponents(url: self.baseURL.appendingPathComponent(PathComponent.note.rawValue),
                                      resolvingAgainstBaseURL: false)!
    let remoteIDQueryItem = URLQueryItem(name: "remote_id", value: String(remoteID))
    urlComponents.queryItems = [remoteIDQueryItem]

    var request = URLRequest(url: urlComponents.url!)
    request.httpMethod = HTTPMethod.delete.rawValue

    return request
  }

  func makeUploadImageRequest(token: String, imageJPEG: Data, note: Note) -> URLRequest {
    let url = self.baseURL.appendingPathComponent(PathComponent.image.rawValue)
    var urlComponents = URLComponents(url: url,
                                      resolvingAgainstBaseURL: false)!

    urlComponents.queryItems = [
      URLQueryItem(name: "remote_id", value: String(note.remoteID!))
    ]

    var request = URLRequest(url: urlComponents.url!)
    request.httpMethod = HTTPMethod.put.rawValue
    request.setValue(token, forHTTPHeaderField: HTTPHeader.authorization.rawValue)
    let boundary = "----WebKitFormBoundary7MA4YWxkTrZu0gW"
    request.setValue("\(ContentType.multipartFormData.rawValue); boundary=\(boundary)",
      forHTTPHeaderField: HTTPHeader.contentType.rawValue)

    var body = Data()
    body.append("--\(boundary)\r\n".data(using: .utf8)!)
    body.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpeg\"\r\n".data(using: .utf8)!)
    body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
    body.append(imageJPEG)
    body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
    request.httpBody = body

    return request
  }

  // MARK: - Private

  private enum PathComponent: String {
    case note, notes
    case image = "note/image"
  }

  private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
  }

  private enum HTTPHeader: String {
    case authorization = "Authorization"
    case contentType = "Content-Type"
  }

  private enum ContentType: String {
    case applicationJSON = "application/json"
    case multipartFormData = "multipart/form-data"
  }

  private let baseURL: URL
}
