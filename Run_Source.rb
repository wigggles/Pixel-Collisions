#!/usr/bin/env ruby
# https://stackoverflow.com/questions/29073826/env-ruby-r-no-such-file-or-directory
puts "\n" * 3 # some top buffer for terminal notifications.
# https://www.codecademy.com/articles/ruby-command-line-argv
APP_NAME = 'Desktop Garage'
case ARGV.first
when 'debug'
  puts "#{APP_NAME} is in debug mode."
end
#=====================================================================================================================================================
# Base Program Window.
#=====================================================================================================================================================
module Konfigure
  #---------------------------------------------------------------------------------------------------------
  UP_MS_DRAW  = 15    # 60 FPS = 16.6666 : 50 FPS = 20.0 : 40 FPS = 25.222
    
  LVL_ONE = 'TestMap' # level to load first  : Big_Map : Yuge_Map : TestMap
  MAP_CHUNK   = 750   # size of the pixel map collision chunk clusters
  CONDENSE_MAP= 3     # condense the pixel cache, I.E. instead of every pixel, every 2 or third one.
  #---------------------------------------------------------------------------------------------------------
end
#-----------------------------------------------------------------------------------------------------------------------------------------------------
ROOT = File.expand_path('.',__dir__)
puts "strating"
require 'gosu'
require "#{ROOT}/requireAll.rb"; include RequireAll
#-----------------------------------------------------------------------------------------------------------------------------------------------------
script_main_dir = File.join(ROOT, "AdditionalClasses")
if FileTest.directory?(script_main_dir)
  begin
    require_all(script_main_dir) rescue LoadError
  rescue => error
    puts error
  end
else
  puts "Could not locate the main scripts directory, where is it?!"
  puts script_main_dir
end

#=====================================================================================================================================================
# Gosu display window for the game.
#=====================================================================================================================================================
class Program < Gosu::Window
  include Konfigure
  #---------------------------------------------------------------------------------------------------------
	def initialize
    @@active_class = nil
		super(800, 600, {:update_interval => UP_MS_DRAW, :fullscreen => false})
		$window = self
    # set current class loop
    swap_active(Main_Menu.new)
	end
  #---------------------------------------------------------------------------------------------------------
	def button_down(id)
		super
    #puts ("Button detected: #{id}")
	end
  #---------------------------------------------------------------------------------------------------------
  def swap_active(klass)
    if klass.is_a?(Object)
      $loading_screen = Load_Que.new
      @slow_down = 5 # ensure Gosu is ready to make draw requests when loading
      unless @@active_class.nil?
        @@active_class.destroy
      end
      @@active_class = klass
    else
      puts "Un-supported active klass type, ( #{klass.class} )"
      exit
    end
  end
  #---------------------------------------------------------------------------------------------------------
	def update
    super # empty caller
    # update active class loop
    if $loading_screen.done?
      return if @@active_class.destroyed?
      @@active_class.update
      self.caption = " FPS: #{Gosu.fps}"
    else
      # continue loading each step untill done
      @slow_down -= 1 if @slow_down > 0
      if @slow_down <= 0
        unless @@active_class.cached_preped?
          @@active_class.cache_load
        else
          @@active_class.load_step
        end
      end
    end
	end
  #---------------------------------------------------------------------------------------------------------
	def draw
    # if not new data, draw active class to screen
    if $loading_screen.done?
      return if @@active_class.destroyed?
      @@active_class.draw
    else # is loading map data
      $loading_screen.draw
    end
	end
end

#=====================================================================================================================================================
Program.new.show

