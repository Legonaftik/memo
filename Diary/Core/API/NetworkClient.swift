//
//  NetworkClient.swift
//  Diary
//
//  Created by Vladimir Pavlov on 25/02/2018.
//  Copyright © 2018 Vladimir Pavlov. All rights reserved.
//

import Foundation

enum NetworkClientError: Error {
  case unknownError
  case jsonDecodingError
  case requestConfigurationError
  case serverTimeRequestError(Error)
  case notesRequestError(Error)
  case logicalError
}

protocol INetworkClient {
  func serverTime(completion: @escaping (Result<Date>) -> Void)
  func notes(token: String, beginDate: Date?, completion: @escaping (Result<NotesResponse>) -> Void)
  func create(_ note: Note, token: String, completion: @escaping (Result<Note>) -> Void)
  func update(_ note: Note, token: String, completion: @escaping (Result<Note>) -> Void)
  func delete(_ note: Note, token: String, completion: @escaping (Result<Bool>) -> Void)
  func deleteAllNotes(token: String, completion: @escaping (Result<Void>) -> Void)
  func uploadImage(with imageData: Data, for note: Note, token: String, completion: @escaping (Result<URL>) -> Void)
  func image(with url: URL, completion: @escaping (Result<Data>) -> Void)
}

final class NetworkClient: INetworkClient {

  private let baseURL = URL(string: "https://www.bestdiary.ru/api")!
  private let decoder = JSONDecoder()
  private lazy var requestFactory: URLRequestFactory = {
    return URLRequestFactory(baseURL: self.baseURL)
  }()

  func serverTime(completion: @escaping (Result<Date>) -> Void) {
    let request = self.requestFactory.makeServerTimeRequest()

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NetworkClientError.serverTimeRequestError(NetworkClientError.logicalError)))
        return
      }

      do {
        let serverTimeResponse = try self.decoder.decode(ServerTimeResponse.self, from: data)
        completion(.success(serverTimeResponse.serverTime))
      } catch {
        completion(.failure(error))
      }
    }
    task.resume()
  }

  func notes(token: String, beginDate: Date? = nil, completion: @escaping (Result<NotesResponse>) -> Void) {
    let request = self.requestFactory.makeNotesRequest(token: token, beginDate: beginDate)

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NetworkClientError.notesRequestError(NetworkClientError.logicalError)))
        return
      }

      do {
        let notesResponse = try self.decoder.decode(NotesResponse.self, from: data)
        completion(.success(notesResponse))
      } catch {
        completion(.failure(error))
      }
    }
    task.resume()
  }

  func create(_ note: Note, token: String, completion: @escaping (Result<Note>) -> Void) {
    guard let request = self.requestFactory.makeCreateNoteRequest(token: token, note: note) else {
      completion(.failure(NetworkClientError.requestConfigurationError))
      return
    }

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NetworkClientError.notesRequestError(NetworkClientError.logicalError)))
        return
      }

      do {
        let updatedNote = try self.noteWithUpdatedRemoteID(for: note, responseData: data)
        completion(.success(updatedNote))
      } catch {
        completion(.failure(error))
      }
    }
    task.resume()
  }

  func update(_ note: Note, token: String, completion: @escaping (Result<Note>) -> Void) {
    let req: URLRequest?
    if note.remoteID == 0 {
      req = self.requestFactory.makeCreateNoteRequest(token: token, note: note)
    } else {
      req = self.requestFactory.makeUpdateNoteRequest(token: token, note: note)
    }

    guard let request = req else {
      completion(.failure(NetworkClientError.requestConfigurationError))
      return
    }

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NetworkClientError.notesRequestError(NetworkClientError.logicalError)))
        return
      }

      do {
        let updatedNote = try self.noteWithUpdatedRemoteID(for: note, responseData: data)
        completion(.success(updatedNote))
      } catch {
        completion(.failure(error))
      }
    }
    task.resume()
  }

  func delete(_ note: Note, token: String, completion: @escaping (Result<Bool>) -> Void) {
    guard let remoteID = note.remoteID else {
      completion(.failure(NetworkClientError.logicalError))
      return
    }
    let request = self.requestFactory.makeDeleteNoteRequest(token: token, remoteID: remoteID)

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard data != nil else {
        completion(.failure(NetworkClientError.notesRequestError(NetworkClientError.logicalError)))
        return
      }

      completion(.success(true))
    }
    task.resume()
  }

  func deleteAllNotes(token: String, completion: @escaping (Result<Void>) -> Void) {
    completion(.failure(NetworkClientError.unknownError))
  }

  func uploadImage(with imageData: Data, for note: Note, token: String,
                   completion: @escaping (Result<URL>) -> Void) {
    let request = self.requestFactory.makeUploadImageRequest(token: token,
                                                             imageJPEG: imageData,
                                                             note: note)

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data else {
        completion(.failure(NetworkClientError.logicalError))
        return
      }

      do {
        let imageResponse = try self.decoder.decode(ImageResponse.self, from: data)
        completion(.success(imageResponse.imageURL))
        return
      } catch {
        completion(.failure(error))
        return
      }
    }

    task.resume()
  }

  func image(with url: URL, completion: @escaping (Result<Data>) -> Void) {
    let task = URLSession.shared.dataTask(with: url) { data, response, error in
      if let error = error {
        completion(.failure(error))
        return
      }

      guard let data = data,
        let response = response as? HTTPURLResponse,
        response.statusCode == 200 else {
        completion(.failure(NetworkClientError.unknownError))
        return
      }

      completion(.success(data))
    }

    task.resume()
  }

  // - Helpers

  private func noteWithUpdatedRemoteID(for note: Note, responseData data: Data) throws -> Note {
    let createNoteResponse = try self.decoder.decode(CreateNoteResponse.self, from: data)
    var noteWithUpdatedRemoteID = note
    noteWithUpdatedRemoteID.remoteID = createNoteResponse.remoteID
    return noteWithUpdatedRemoteID
  }
}
