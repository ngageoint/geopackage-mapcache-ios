# Change Log
All notable changes to this project will be documented in this file.
Adheres to [Semantic Versioning](http://semver.org/).

---

## 1.25 - Legacy (TBD)

* TBD

## [1.24 - Legacy](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.24) (04-21-2020)

* geopackage-ios version 4.0.1

## [1.23 - Legacy](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.23) (03-12-2020)

* geopackage-ios version 4.0.0
* XYZ tile rebranding, previously referred to as Standard
* Queries by specified columns

## [1.22 - Legacy](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.22.legacy) (10-15-2019)

* geopackage-ios version 3.3.0

## [1.21](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.21) (04-04-2019)

* geopackage-ios version 3.2.0
* Feature Style support
* AFNetworking version 3.2.1
* Fingertips version 0.5.0 (only used when animate_screen_touches property is set to YES)

## [1.20](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.20) (10-05-2018)

* geopackage-ios version updated to 3.1.0
* Feature Index Manager connection closures
* GeoPackage Cache utilization

## [1.19](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.19) (07-16-2018)

* geopackage-ios version updated to 3.0.1
* Recommended project updates

## [1.18](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.18) (05-18-2018)

* geopackage-ios version updated to 3.0.0
* Feature Overlays turn on a single composite overlay with linked tiles and features
* GeoPackage tile type handler rank lowered from Owner to Default

## [1.17](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.17) (03-21-2018)

* geopackage-ios version updated to 2.0.2
* Tile Scaling limited (read-only) support for displaying missing tiles using nearby zoom levels
* Zoom to tiles using the intersection between the Contents and Tile Matrix Set bounds
* Fix loss of decimal precision when editing tile table bounds

## [1.16](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.16) (02-15-2018)

* geopackage-ios version updated to 2.0.1
* Expand the contents bounding box when adding or editing features
* Enable default polygon fill color
* Keyboard constraint bug fix

## [1.15](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.15) (11-21-2017)

* geopackage-ios version updated to 1.4.0
* Updated button image sizes
* Geometry simplifications for displayed map features based upon zoom level
* Only display and maintain features in the current map views
* Maintain active feature indices when editing map features
* Queryable map features (previously only available for feature tiles)
* Update geometry envelopes when editing features
* Increase default max map features & max points per tile to 5000, max features per tile to 2000
* Updated preloaded GeoPackage url example files

## [1.14](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.14) (07-31-2017)

* geopackage-ios version updated to 1.3.0
* Improved handling of unknown Contents bounding boxes
* Prevent app crash from invalid or unsupported geometries
* Bounding of degree projected boxes before Web Mercator transformations

## [1.13](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.13) (07-10-2017)

* geopackage-ios version updated to 1.2.3
* Improved handling of unknown Contents bounding boxes

## [1.12](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.12) (06-14-2017)

* geopackage-ios version updated to 1.2.2
* Added AFNetworking 3.1 dependency which was removed from geopackage-ios
* GeoPackage sample data and tile server updates
* Feature Tile Overlay fix for WGS84 bounding boxes above or below the Web Mercator limits
* Edit Feature Tile Overlay fix preventing saved edit of max features per tile
* Replace use of deprecated pinColor with pinTintColor

## [1.11](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.11) (02-02-2017)

* geopackage-ios version updated to 1.2.1
* Fingertips dependency

## [1.10](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.10) (06-23-2016)

* geopackage-ios version updated to 1.2.0
* EPSG field and default settings for loading tiles from a URL
* Preloaded tile URL updates

## [1.9](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.9) (05-10-2016)

* geopackage-ios version updated to 1.1.11
* Natural Earth Rivers GeoPackage URL

## [1.8](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.8) (03-18-2016)

* geopackage-ios version updated to 1.1.10

## [1.7](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.7) (02-22-2016)

* geopackage-ios version updated to 1.1.8

## [1.6](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.6) (02-12-2016)

* geopackage-ios version updated to 1.1.7

## [1.5](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.5) (02-10-2016)

* Table linking improvements when displaying a tile table linked to a feature table
* Ignore drawing Feature Overlay tiles that exist in linked tile tables
* geopackage-ios version updated to 1.1.6

## [1.4](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.4) (02-09-2016)

* Table linking between feature and tile tables
* geopackage-ios version updated to 1.1.5

## [1.3](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.3) (12-14-2015)

* geopackage-ios version updated to 1.1.3

## [1.2](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.2) (11-20-2015)

* Display data column information when it exists - [Issue #5](https://github.com/ngageoint/geopackage-mapcache-ios/issues/5)
* Change the mapcache-ios scheme to be a shareable project for command line builds

## [1.1](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.1) (11-05-2015)

* Add NGA Table Index Extension support and combine with existing metadata indexing, index to either or both
* Max features per tile support for feature overlays and feature tile generation
* Feature Overlay Query support to provide map click feedback when clicking on feature tile geometries

## [1.0](https://github.com/ngageoint/geopackage-mapcache-ios/releases/tag/1.0) (10-27-2015)

* Initial Release
