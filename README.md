# Pixel Based Collisions


This was written as a sample of using Gosu for rendering an image as a colidiable tileset.
It contains an Active class loop call back manager for Update and Draw.

There is also a sample on how loading cache works and saving data to file as an exported Object compressed with gzib.


### Requirements

Just Gosu and a compatible Ruby version.

https://rubygems.org/gems/gosu

https://www.ruby-lang.org/en/documentation/installation/


### Notes

If you change the Image used for the map, you will also have to delete the map collision cache data and rebuild it by loading into the map. Other wise changes to collisions by their pixel colors will not be correct to the updated map Image.

### Screen Shot

![alt text](https://raw.githubusercontent.com/wigggles/Pixel-Collisions/master/Media/ScreenShots/ScreenShot.png "")