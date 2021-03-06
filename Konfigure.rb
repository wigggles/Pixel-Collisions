#=====================================================================================================================================================
# Global configuration settings.
#=====================================================================================================================================================
module Konfigure
  #---------------------------------------------------------------------------------------------------------
  RESOLUTION   = [800, 600] # Display Gosu::Window size.
  ISFULLSCREEN = false      # Draw in full screen mode?
  UP_MS_DRAW  = 15    # 60 FPS = 16.6666 : 50 FPS = 20.0 : 40 FPS = 25.222
  #---------------------------------------------------------------------------------------------------------
  # Just the file name of the map to load, the extra information attached to the file name on the image is
  # for update information about the image to build the cache. Loading this cached object is much faster
  # then building it each time the image is loaded as a map environment conatianded by the ' Map_Stage ' 
  # object.
  LVL_ONE = 'TestMap' # level to load first  : Big_Map : Yuge_Map : TestMap
  #---------------------------------------------------------------------------------------------------------  
  MAP_CHUNK   = 750   # size of the pixel map collision chunk clusters
  CONDENSE_MAP= 3     # condense the pixel cache, I.E. instead of every pixel, every 2 or third one.
  #---------------------------------------------------------------------------------------------------------
end