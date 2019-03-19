#=====================================================================================================================================================
# Base Active Class functions.
#=====================================================================================================================================================
class Base_Active
  include Konfigure
  def initialize()
    # tell the active class loop handler that it can start stepping
    @load_ready = false
    @destroyed  = false
    @@can_draw  = false
  end
  #---------------------------------------------------------------------------------------------------------
  def after_load
    @@can_draw = true
    $loading_screen.finish
  end
  #---------------------------------------------------------------------------------------------------------
  def cache_load
    # be sure to flag no more steps to add
    @load_ready = true
  end
  #---------------------------------------------------------------------------------------------------------
  def update
    
  end
  #---------------------------------------------------------------------------------------------------------
  def draw
    
  end
  #---------------------------------------------------------------------------------------------------------
  def cached_preped?
    return @load_ready
  end
  #---------------------------------------------------------------------------------------------------------
  def load_step
    loading = $loading_screen.step
    if loading.empty?
      after_load
    end
    return loading
  end
  #---------------------------------------------------------------------------------------------------------
  def destroyed?
    return @destroyed
  end
  #---------------------------------------------------------------------------------------------------------
  def destroy
    @destroyed = true
  end
end

#=====================================================================================================================================================
# For saving and loading object data.
#=====================================================================================================================================================
require "zlib"
module Data_Manager
  #---------------------------------------------------------------------------------------------------------
  def self.saveM(object, fname)
    @file = File.open("#{ROOT}/#{fname}.ro", 'wb')
      @file.write(Marshal.dump(object))
    @file.close
  end
  #---------------------------------------------------------------------------------------------------------
  def self.loadM(fname)
    object = Marshal.load(File.binread("#{ROOT}/#{fname}.ro"))
    return object
  end
  #---------------------------------------------------------------------------------------------------------
  def self.save_gzib(object, fname)
    Zlib::GzipWriter.open("#{fname}.gz") do |gz|
      gz.write(Marshal.dump(object))
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def self.load_gzib(fname)
    data = nil
    if File.exist?("#{ROOT}/#{fname}.gz")
      Zlib::GzipReader.open("#{fname}.gz") do |gz|
        data = Marshal.load(gz.read)
      end
    else
      puts "File not found.\n#{caller[0]}\n#{"#{ROOT}/#{fname}.gz"}"
    end
    return data
  end
end
