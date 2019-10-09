# ImagePreloader iOS

UI component to preload and cache remote images like avatars.

![](preview.gif)

### Usage

```
@IBOutlet weak var avatar: ImagePreloader!

override func viewDidLoad() {
    super.viewDidLoad()
    avatar.url = "https://www.cats.org.uk/media/2299/tortie-cat-looking-up.jpg"
}
```

### Configure

You can configure component from storyboard or programmatically.
```
avatar.isCropCircle = true
avatar.placeholder = UIImage(named: "cat")
avatar.progressColor = .blue
avatar.progressRadius = 4
avatar.circle = true
```
You can also change the space for the cache.
```
ImagePreloader.cacheMaxImages = 100
ImagePreloader.cacheMaxSize = 100_000_000
```
