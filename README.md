# GeoPackage MapCache iOS

#### MapCache iOS ####

The [GeoPackage Libraries](http://ngageoint.github.io/GeoPackage/) were developed at the [National Geospatial-Intelligence Agency (NGA)](http://www.nga.mil/) in collaboration with [BIT Systems](http://www.bit-sys.com/). The government has "unlimited rights" and is releasing this software to increase the impact of government investments by providing developers with the opportunity to take things in new directions. The software use, modification, and distribution rights are stipulated within the [MIT license](http://choosealicense.com/licenses/mit/).


### Pull Requests ###
If you'd like to contribute to this project, please make a pull request. We'll review the pull request and discuss the changes. All pull request contributions to this project will be released under the MIT license.

Software source code previously released under an open source license and then modified by NGA staff is considered a "joint work" (see 17 USC § 101); it is partially copyrighted, partially public domain, and as a whole is protected by the copyrights of the non-government authors and must be released according to the terms of the original open source license.

### iOS App ###

<a href='https://apps.apple.com/us/app/mapcache-by-nga/id1477252454'>
    <img src="https://github.com/ngageoint/GeoPackage/raw/master/docs/images/app-store-logo.png" height=56>
</a>

### About ###

[GeoPackage MapCache](http://ngageoint.github.io/geopackage-mapcache-ios/) is a [GeoPackage Library](http://ngageoint.github.io/GeoPackage/) app for iOS that utilizes and demonstrates the functionality in [GeoPackage iOS](https://github.com/ngageoint/geopackage-ios).  The GeoPackage SDK is an iOS Objective-C library implementation of the Open Geospatial Consortium [GeoPackage](http://www.geopackage.org/) [spec](http://www.geopackage.org/spec/). The app and SDK are listed as [OGC GeoPackage Implementations](http://www.geopackage.org/#implementations_nga) by the National Geospatial-Intelligence Agency.


The MapCache app provides read and write access to GeoPackage files, including features and tiles. Features are visualized and editable on the map. Tiles are visualized on the map and can be loaded from a tile provider or WMS url.

### Build ###

[![Build Archive](https://github.com/ngageoint/geopackage-mapcache-ios/workflows/Build%20Archive/badge.svg)](https://github.com/ngageoint/geopackage-mapcache-ios/actions?query=workflow%3A%22Build+Archive%22)

Build this repository using Xcode and/or CocoaPods:

    pod repo update
    pod install

Open mapcache-ios.xcworkspace in Xcode or build from command line:

    xcodebuild -workspace 'mapcache-ios.xcworkspace' -scheme mapcache-ios build

Run tests from Xcode or from command line:

    xcodebuild test -workspace 'mapcache-ios.xcworkspace' -scheme mapcache-ios -destination 'platform=iOS Simulator,name=iPhone 6s'
