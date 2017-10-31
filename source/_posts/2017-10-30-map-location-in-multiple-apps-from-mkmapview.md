---
layout: post
title: "Open Map Location in Multiple Apps from MKMapView"
date: 2017-10-30 09:50:45
comments: true
description: "Open Map Location in Multiple Apps from MKMapView"
keywords: "swift,mkmapview,ios"
categories:
- iOS
tags:
- iOS
---

You've probably seen in a lot of apps where tapping on a map location or address gives you the option to open that location in one of the map applications installed on your phone. Perhaps you tap on the address for an event in the Facebook app, and it gives you the option to see that location in Apple Maps, Google Maps, or Waze, depending on what apps you have on your phone. I wanted to attach this functionality to an `MKMapView` in an app I'm currently working on
in a clean, encapsulated way, and thought I would share that in a post. I took what I had learned from a few other great articles, and combined them to fit my needs.

## Requirements

To get started, I had to decide what map applications I wanted to support. Everyone will obviously have Apple Maps on their phone, but may also optionally have Google Maps or Waze as well. I decided to stick with these "big three" and go from there. Next, if there was only one app available on the phone (e.g. Apple Maps), I didn't want to show a list with only one option, so tapping on the `MKMapView` would skip the selection step and directly open in Apple Maps. The final thing to keep in mind for my situation was that the actualy map view was located in a child view controller of the currently displayed top-level controller, so I wanted to offer the map selection pop-up in the parent view controller, even though the prompt would be triggered from the child view controller.

<img src="https://imgur.com/IgpRAyB.png" width="50%">

## Initial Setup

The first thing we need to do is to "whitelist" Google Maps and Waze in the **Info.plist** configuration file. Create an array entry with the key of *LSApplicationQueriesSchemes*. This will allow the app to determine if Waze and Google Maps are installed and available to be used on the device. From the Apple docs:

<blockquote>
LSApplicationQueriesSchemes (Array - iOS) Specifies the URL schemes you want the app to be able to use with the canOpenURL: method of the UIApplication class. For each URL scheme you want your app to use with the canOpenURL: method, add it as a string in this array.
</blockquote>

These URL schemes, unique to each app, allow for inter-application communcation, and you can read more about them [here](https://developer.apple.com/library/content/featuredarticles/iPhoneURLScheme_Reference/Introduction/Introduction.html).
For our two map applications, we'll add the array entries *comgooglemaps* and *waze*.

<img src="https://imgur.com/OwndhKz.png" width="100%">

## Building Scheme Info

Since Apple Maps already has a nice built-in API for opening itself from another iOS application with a particular location and configuration, I wanted to construct a similar, encapsulating interface for the other third-party map schemes as well. For Google Maps and Waze, we need to build out:

1. A mechanism to determine if each app is available to use on the device
2. The actual URL for opening the app with the location information

I began this process with a simple protocol, aptly named `MapAppScheme`:

{% highlight swift %}
import Foundation
import MapKit

protocol MapAppScheme {
    var label: String { get } // The label for the option in the list
    var scheme: URL? { get } // The URL scheme used to determine if the app is available
    var annotation: MKAnnotation { get set } // The coordinates (latitutde and longitude) for the location
    var url: URL? { get } // The URL to open the application with the required info
}
{% endhighlight %}

From here, it's pretty straightfoward to "flesh out" the two schemes.

### Google Maps

{% highlight swift %}
import Foundation
import MapKit

struct GoogleMapsScheme: MapAppScheme {
    var label: String = "Google Maps"
    var scheme: URL? = URL(string: "comgooglemaps://") // Scheme needs to be wrapped in a URL object
    var annotation: MKAnnotation

    init(annotation: MKAnnotation) {
        self.annotation = annotation
    }

    var url: URL? {
        let stringScheme = scheme?.absoluteString

        // Try to use the name of the location, replacing spaces with +, otherwise use the latitude and longitude
       guard let destination: String = annotation.title??.replacingOccurrences(of: " ", with: "+") ?? "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)" else {
            return nil
        }

        return URL(string: "\(String(describing: stringScheme!))?saddr=&daddr=\(destination)&center=\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)")
    }
}
{% endhighlight %}

The code speaks for itself, but ideally the `url` property will be constructed with either a location name:

*comgooglemaps://?saddr=&daddr=Billy+Goat+Hill&center=37.7415,122.4330*

Or the coordinates:

*comgooglemaps://?saddr=&daddr=37.7415,122.4330&center=37.7415,122.4330*

The way the URL is constructed will enter the location as the destination for traveling directions, with the starting location left blank. You can learn more about the Google Maps URL scheme [here](https://developers.google.com/maps/documentation/urls/ios-urlscheme).

### Waze

{% highlight swift %}
import Foundation
import MapKit

struct WazeScheme: MapAppScheme {
    var label: String = "Waze"
    var scheme: URL? = URL(string: "waze://")
    var annotation: MKAnnotation

    init(annotation: MKAnnotation) {
        self.annotation = annotation
    }

    var url: URL? {
        // Try to get the location name
        let destination = annotation.title??.addingPercentEncoding(withAllowedCharacters: .alphanumerics)

        // Build the query params
        var searchQuery = [
            URLQueryItem(name: "ll", value: "\(annotation.coordinate.latitude),\(annotation.coordinate.longitude)")
        ]

        // Add location name to query params if available
        if let dest = destination {
            searchQuery.append(URLQueryItem(name: "q", value: dest))
        }

        var wazeUrl =  URLComponents(string: "https://waze.com/ul")
        // Attach query params to URL
        wazeUrl?.queryItems = searchQuery

        return wazeUrl?.url
    }
}
{% endhighlight %}

The Waze scheme is very similar to Google Maps, although the annotation's title will be URL escaped instead of using **+**'s.

*https://waze.com/ul?q=66%20Billy%20Goat%20Hill&ll=37.7415,122.4330*

Additionally, since the Waze URL scheme is a more traditional URL, I built it using the `URLComponent` class instead of interpolating the results into the URL string directly. You can learn more about the Waze URL scheme [here](https://developers.google.com/waze/api/).

## Consolidating the Results

Now that the schemes are built out, I constructed a helper class to determine which of the two I could use.

{% highlight swift %}
import Foundation
import MapKit

class MapAppsHelper {
    fileprivate let mapSchemes: [MapAppScheme]
    let annotation: MKAnnotation

    init(annotation: MKAnnotation) {
        self.annotation = annotation

        mapSchemes = [
            GoogleMapsScheme(annotation: annotation),
            WazeScheme(annotation: annotation)
        ]
    }

    lazy private(set) var availableMapApps: [String: URL] = {
        var availableSchemes: [String: URL] = [:]

        for scheme in mapSchemes {
            // If the app is available, add the URL to the list of available schemes
            if let schemeUrl = scheme.scheme, UIApplication.shared.canOpenURL(schemeUrl), let url = scheme.url {
                availableSchemes[scheme.label] = url
            }
        }
        // ["Google Maps": "urlForGoogleMaps", ...]
        return availableSchemes
    }()
}
{% endhighlight %}

We first check if the scheme is available by using the `canOpenURL` function, then add our constructed URL to the list of `availableSchemes`. I then created a `MapActionSheetViewController`, which is a `UIAlertController` action sheet.

{% highlight swift %}
import UIKit
import MapKit

class MapActionSheetViewController: UIAlertController {
    fileprivate let mapOptions: [String: URL]

    init(mapOptions: [String: URL], renderAppleMaps: @escaping () -> ()) {
        // Pass in the results from our MapAppsHelper
        self.mapOptions = mapOptions
        super.init(nibName: nil, bundle: nil)
        // Pass in the closure containing the logic to render the location inside Apple Maps
        buildActions(renderAppleMaps)
    }

    override var preferredStyle: UIAlertControllerStyle {
        return .actionSheet
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    fileprivate func buildActions(_ renderAppleMaps: @escaping () -> ()) {
        // Add the Apple Maps option with the closure containing the logic for rendering the location in Apple Maps
        addAction(UIAlertAction(title: "Apple Maps", style: .default, handler: { (action) in
            renderAppleMaps()
        }))

        // Add one or more actions for our third-party map applications
        mapOptions.forEach { option in
            addAction(UIAlertAction(title: option.key, style: .default, handler: { (action) in
                UIApplication.shared.open(option.value, options: [:], completionHandler: nil)
            }))
        }

        // Add an option to cancel opening the location in a map application
        addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
    }
}
{% endhighlight %}

There's a lot going on here, but hopefully the code with comments will make clear what's going on. Basically as we add options to the action sheet, we associate the logic for opening each map application with the correct URL (or executing a closure in the case of Apple Maps) to that option. As we wrap up, hopefully this will all make sense. However, for a visual representation, this will render the highlighted section below.

<img src="https://imgur.com/TNmtyKn.png" width="50%">

One final thing to note about the `renderAppleMaps` closure; we are passing this functionality in rather than declaring it inside the controller since we might have the case where the only map app available is Apple Maps. Therefore, rather than writing the code to open the location in Apple Maps in two places in the codebase, we can write it in one place and pass it in if we need to, or just execute it when the `MKMapView` is tapped.

## Wiring Up the View

As mentioned at the beginning of the article, the `MKMapView` is actually inside the view of a child view controller, and we want to render our `UIAlertController` action sheet in the parent controller. The child view controller is called `ParkDetailsMapViewController`, and the parent controller is the `ParkViewController`.

<img src="https://imgur.com/kINutAH.png" width="50%">

We can accomplish this by setting up a `UITapGestureRecognizer` on the `MKMapView`, then setting the `ParkViewController` parent as the delegate to a protocol declared in the child `ParkDetailsMapViewController`. When the `MKMapView` is tapped, trigger the delegate to show the action sheet. First, the `ParkDetailsMapViewController`, in which I'm only showing the relevant parts.

{% highlight swift %}
import MapKit

protocol ParkDetailsMapViewControllerDelegate: class {
    // Define this in the parent ParkViewController
    func renderMapSelectionActionSheet(mapOptions: [String: URL], renderAppleMaps: @escaping () -> ())
}
class ParkDetailsMapViewController: UIViewController {
    let mapAppsHelper: MapAppsHelper

    init(annotation: MKAnnotation) {
        // Pass in the MKAnnotation from the MKMapView
        mapAppsHelper = MapAppsHelper(annotation: annotation)
        ...
        // mapView variable declaration left out, however just a basic MKMapView setup
        mapView.addAnnotationWithRegion(annotation)
    }

    private var mapTapGesureRecognizer: UITapGestureRecognizer?
    weak var delegate: ParkDetailsMapViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // When the map view is tapped, call the openInMaps function
        mapTapGesureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openInMaps))
        mapView.addGestureRecognizer(mapTapGesureRecognizer!)
        ...
    }
{% endhighlight %}

I added the `openInMaps` function as a private extension to the controller.

{% highlight swift %}
fileprivate extension ParkDetailsMapViewController {
    @objc func openInMaps(_ sender: UITapGestureRecognizer) {
        // If we have more than Apple Maps available, trigger the rendering of the action sheet
        if mapAppsHelper.availableMapApps.count > 0 {
            delegate?.renderMapSelectionActionSheet(mapOptions: mapAppsHelper.availableMapApps, renderAppleMaps: {
                self.mapView.openInMaps(self.mapAppsHelper.annotation)
            })
        } else {
            // Open directly in Apple Maps
            mapView.openInMaps(mapAppsHelper.annotation)
        }
    }
}
{% endhighlight %}

If you notice, the two arguments we're sending to the `renderMapSelectionActionSheet` delegate function happen to match the arguments required for the initialization of the `MapActionSheetViewController`. You can probably guess where we'll be creating that controller instance....

Before we jump over to the parent `ParkViewController`, I want to point out that the `openInMaps` function on the `mapView` variable is actually an extension attached to the `MKMapView` for opening the location in Apple Maps.

{% highlight swift %}
extension MKMapView {
    // How far to zoom the map
    private var regionRadius: CLLocationDistance {
        return 2000
    }

    func addAnnotationWithRegion(_ annotation: MKAnnotation) {
        addAnnotation(annotation)
        // Center the map view around the location
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        setRegion(coordinateRegion, animated: true)
    }

    func openInMaps(_ annotation: MKAnnotation) {
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: region.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: region.span)
        ]
        // Set up the location marker in the map view
        let placemark = MKPlacemark(coordinate: annotation.coordinate, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = annotation.title!
        // Launch in Apple Maps
        mapItem.openInMaps(launchOptions: options)
    }
}
{% endhighlight %}

Hopefully the code and comments are enough of an explanation, but feel free to play around with different values here to see what kind of results you get in the map view.

## Finishing Touches

The last piece is one of the most straightforward, where we actually build out the `renderMapSelectionActionSheet` delegate function. At this point, all we need to do is take the arguments passed in, instantiate the `MapActionSheetViewController` with those arguments, and present the view controller.

{% highlight swift %}
class ParkViewController: UIViewController, ParkDetailsMapViewControllerDelegate, UIScrollViewDelegate {
    ...
    func renderMapSelectionActionSheet(mapOptions: [String: URL], renderAppleMaps: @escaping () -> ()) {
        let actionSheet = MapActionSheetViewController(mapOptions: mapOptions, renderAppleMaps: renderAppleMaps)
        // Show the action sheet
        present(actionSheet, animated: true, completion: nil)
    }
    ...
}
{% endhighlight %}

And voilà! Our finished product (sorry for the heavy duty GIF).

<img src="https://imgur.com/MmQeuGx.gif" width="50%">

## Conclusion

In this particular case, we are using an `MKMapView` to trigger our map app options, but you could very well do it with a `UITableViewCell` or `UILabel` location address as well. This is one way I felt worked best for this particular codebase, but there are many other great tutorials on how to do this out scattered about the interwebs. I hope you've been able to pick up a few good ideas from this lesson on your iOS journey. Thanks for reading!