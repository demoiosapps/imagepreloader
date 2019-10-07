//
//  ImagePreloader.swift
//  ImagePreloader
//
//  Created by R on 16.09.2019.
//  Copyright © 2019 R. All rights reserved.
//

import UIKit

@IBDesignable class ImagePreloader: UIImageView {
    
    // Storyboard
    @IBInspectable public var placeholder: UIImage?
    @IBInspectable public var progressColor: UIColor = .blue
    @IBInspectable public var progressRadius: CGFloat = 4
    @IBInspectable public var circle: Bool = true

    // Request
    static var requestTimeout: TimeInterval = 60
    static var responseTimeout: TimeInterval = 60
    
    // Debug
    #if DEBUG
    static var isDebug = true
    #endif

    // Cache
    static var cacheMaxImages: UInt = 100
    static var cacheMaxSize: UInt64 = 100_000_000
    static var cacheDir = "ImagePreloader"
    
    // Post processing
    var isCropCircle = true
    
    // Retry
    static var retryCount = 10
    static var retryInterval: TimeInterval = 1
    
    private lazy var request = ImagePreloaderRequest(progress: { [weak self] downloaded, total in
        self?.updateProgress(downloaded: downloaded, total: total)
    }) { [weak self] image, request in
        guard let self = self else { return }
        let image = self.isCropCircle ? self.cropCircle(image) : image
        self.updateImage(image)
        if let image = image,
            let request = request {
            ImagePreloaderCache.write(image: image, for: self.identifier(for: request))
        }
    }
    
    var url: String? {
        get {
            return request.url
        }
        set {
            if let url = newValue {
                download(url)
            } else {
                clear()
            }
        }
    }
    var isLoading: Bool {
        return request.isLoading
    }
    
    private var progressLayer = CAShapeLayer()
    
    override var bounds: CGRect {
        didSet {
            if circle {
                layer.cornerRadius = bounds.width / 2
            }
        }
    }
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        define()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        define()
    }
    
    private func define() {
        createProgress()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        image = image ?? placeholder
        if circle {
            contentMode = .scaleAspectFill
            layer.masksToBounds = true
            layer.cornerRadius = bounds.width / 2
        }
    }

    // MARK: - Download
    
    // You can make it more complex dependent on task
    private func identifier(for request: URLRequest) -> String {
        if let url = request.url?.absoluteString {
            return Data(url.utf8).base64EncodedString()
        } else {
            return UUID().uuidString
        }
    }

    func download(_ url: String) {
        if let url = URL(string: url) {
            download(request: URLRequest(url: url))
        }
    }
    
    // Download with custom request
    // for example with specific headers or method type
    func download(request: URLRequest) {
        guard request.url?.absoluteString != nil else {
            return
        }
        // try load from cache first
        ImagePreloaderCache.image(for: identifier(for: request)) { [weak self] image in
            self?.clear()
            if image != nil {
                #if DEBUG
                if ImagePreloader.isDebug {
                    print("ImagePreloader - load from cache \(request.url?.absoluteString ?? "")")
                }
                #endif
                self?.updateImage(image)
            } else {
                self?.request.run(request)
            }
        }
    }
        
    // MARK: - Request
    
    func cancel() {
        request.cancel()
    }
    
    func pause() {
        request.pause()
    }
    
    func resume() {
        request.resume()
    }
    
    
    // MARK: - Change image
    
    func clear() {
        cancel()
        clearProgress()
        image = placeholder
    }
    
    func updateImage(_ image: UIImage?) {
        if image == nil {
            clear()
        } else {
            self.image = image ?? placeholder
            self.clearProgress()
        }
    }

    // MARK: - Progress
    
    private func updateProgress(downloaded: Int64, total: Int64) {
        let percent = Double(downloaded) / Double(total)
        
        if CGFloat(percent) <= progressLayer.strokeEnd {
            return
        }
        
        let circularPath = UIBezierPath(arcCenter: CGPoint(x: frame.width / 2, y: frame.height / 2), radius: (frame.width - progressRadius * 1.6) / 2, startAngle: -.pi / 2, endAngle: 3 * .pi / 2, clockwise: true)
        progressLayer.path = circularPath.cgPath
        progressLayer.strokeColor = progressColor.cgColor
        progressLayer.lineWidth = progressRadius

        let circularProgressAnimation = CABasicAnimation(keyPath: "strokeEnd")
        circularProgressAnimation.duration = 0.2
        circularProgressAnimation.toValue = percent
        circularProgressAnimation.fillMode = .forwards
        circularProgressAnimation.isRemovedOnCompletion = false
        progressLayer.add(circularProgressAnimation, forKey: "progressAnim")

    }

    private func clearProgress() {
        // you can add custom animation
        //progressLayer.removeAllAnimations()
        progressLayer.strokeColor = UIColor.clear.cgColor
    }
    
    private func createProgress() {
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.lineCap = .round
        progressLayer.lineWidth = progressRadius
        progressLayer.strokeEnd = 0
        progressLayer.strokeColor = progressColor.cgColor
        layer.addSublayer(progressLayer)
    }
    
    // MARK: - Cache

    static func cleanCache() {
        ImagePreloaderCache.clean()
    }

    static func clearCache() {
        ImagePreloaderCache.clear()
    }
    
    // MARK: - Post processing
    
    func cropCircle(_ image: UIImage?) -> UIImage? {
        if image == nil { return nil }
        let imageLayer = CALayer()
        let minSize = image!.size.width > image!.size.height ? image!.size.height : image!.size.width
        let x = (image!.size.width - minSize) / 2
        let y = (image!.size.height - minSize) / 2
        let rect = CGRect(x: x, y: y, width: minSize, height: minSize)
        imageLayer.frame = frame
        imageLayer.contents = image!.cgImage?.cropping(to: rect)
        imageLayer.masksToBounds = true
        imageLayer.cornerRadius = bounds.width / 2
        UIGraphicsBeginImageContext(bounds.size)
        imageLayer.render(in: UIGraphicsGetCurrentContext()!)
        let croppedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return croppedImage ?? image
    }

}

