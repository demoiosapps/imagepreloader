//
//  ImagePreloaderRequest.swift
//  ImagePreloader
//
//  Created by R on 16.09.2019.
//  Copyright © 2019 R. All rights reserved.
//

import UIKit

class ImagePreloaderRequest: NSObject {

    private var task: URLSessionDownloadTask?
    private var retries = 0

    var url: String? {
        return task?.currentRequest?.url?.absoluteString
    }
    var isLoading: Bool {
        return task?.state == .running
    }

    typealias Result = (_ image: UIImage?, _ request: URLRequest?) -> Void
    typealias Progress = (_ downloaded: Int64, _ total: Int64) -> Void
    private var result: Result?
    private var progress: Progress?
    
    init(progress: @escaping Progress, result: @escaping Result) {
        self.progress = progress
        self.result = result
    }
    
    func cancel() {
        task?.cancel()
    }
    
    func pause() {
        task?.suspend()
    }
    
    func resume() {
        task?.resume()
    }
    
    func run(_ request: URLRequest) {
        run(request: request, retry: 0)
    }
    
    func run(request: URLRequest, retry: Int = 0) {
        self.retries = retry
        let configuration = URLSessionConfiguration.background(withIdentifier: UUID().uuidString)
        configuration.timeoutIntervalForRequest = ImagePreloader.requestTimeout
        configuration.timeoutIntervalForResource = ImagePreloader.responseTimeout
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        #if DEBUG
        if ImagePreloader.isDebug {
            print("ImagePreloader - \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        }
        #endif
        
        task = session.downloadTask(with: request as URLRequest)
        task?.resume()
    }

    func retry(_ request: URLRequest) {
        DispatchQueue.main.async { [weak self] in
            self?.progress?(0, 1)
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + ImagePreloader.retryInterval) { [weak self] in
            if let self = self,
                request == self.task?.currentRequest {
                #if DEBUG
                print("ImagePreloader - retry \(self.retries + 1)")
                #endif
                self.run(request: request, retry: self.retries + 1)
            }
        }
    }
}

extension ImagePreloaderRequest: URLSessionDownloadDelegate {
        
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        
        let status = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
        
        #if DEBUG
        if ImagePreloader.isDebug {
            print("ImagePreloader - (\(status))")
        }
        #endif

        let request = task?.currentRequest
        if let data = try? Data(contentsOf: location),
            let image = UIImage(data: data) {
            DispatchQueue.main.async { [weak self] in
                self?.result?(image, request)
            }
        } else {
            if retries < ImagePreloader.retryCount,
                let request = request {
                retry(request)
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.result?(nil, request)
                }
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        DispatchQueue.main.async { [weak self] in
            self?.progress?(totalBytesWritten, totalBytesExpectedToWrite)
        }
    }
}
