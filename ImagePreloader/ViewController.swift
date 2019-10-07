//
//  ViewController.swift
//  ImagePreloader
//
//  Created by R on 16.09.2019.
//  Copyright © 2019 R. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var avatar: ImagePreloader!
    @IBOutlet weak var nextButton: UIButton!
    
    var images: [String] = [
        "https://cdn.pixabay.com/photo/2017/11/09/21/41/cat-2934720_960_720.jpg",
        "https://cdn.pixabay.com/photo/2015/11/16/22/14/cat-1046544_960_720.jpg",
        "https://cdn.pixabay.com/photo/2017/08/23/08/33/cats-eyes-2671903_960_720.jpg",
        "https://cdn.pixabay.com/photo/2016/01/20/13/05/cat-1151519_960_720.jpg",
        "https://cdn.pixabay.com/photo/2017/02/15/12/12/cat-2068462_960_720.jpg",
        "https://cdn.pixabay.com/photo/2017/11/13/07/14/cat-eyes-2944820_960_720.jpg",
        "https://cdn.pixabay.com/photo/2018/03/26/02/05/cat-3261420_960_720.jpg",
        "https://www.cats.org.uk/media/2299/tortie-cat-looking-up.jpg?width=50000"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        avatar.layer.borderColor = UIColor.black.cgColor
        avatar.layer.borderWidth = 1
        
        /*
         Use for test
        */
        
        //avatar.isCropCircle = false
        //ImagePreloader.cacheMaxImages = 100
        //ImagePreloader.cacheMaxSize = 100_000_000
        //ImagePreloader.cleanCache()

        nextButton.layer.borderColor = UIColor.black.cgColor
        nextButton.layer.cornerRadius = 10
        nextButton.layer.borderWidth = 1
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        loadNextImage()
    }

    // MARK: - Action buttons

    @IBAction func clearCacheButton(_ sender: Any) {
        ImagePreloader.clearCache()
    }
    
    @IBAction func nextButton(_ sender: Any) {
        loadNextImage()
    }
    
    // MARK: - Load image
    
    func loadNextImage() {
        let url = images.popLast()!
        images.insert(url, at: 0)
        avatar.url = url
    
        /*
         Imitate pause & resume
        */
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.avatar.pause()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.avatar.resume()
        }
        */
    }
    
}
