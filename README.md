# flickrAPI

**FlickrAPI** demonstrate how to use FlickrAPI in iOS using Swift  [Flickr API](https://www.flickr.com/services/api).

Main features are:
1.    Use the Flickr API (https://www.flickr.com/services/api/) to allow user searching for photos with specific words
2.    Show the results of the search in an infinite scroll list where each cell contains at least a photo
3.    When tapping on a cell the user of the app will display the full screen photo and its details. User can zoom in and zoom out the photo by pinch action.

Technical points:
1.    Application support iOS8.0 or more recent.
2.    Images are downloaded asynchronously and saved into a cache (capacity: 500 images). This is in memory cache, we can create multi level cache for better use.

Screen shoot:
