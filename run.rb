#!/usr/bin/env ruby
#=====================================================================================================================================================
# Additional tutorials and usefull information.
#   https://github.com/vaiorabbit/ruby-opengl
#   http://larskanis.github.io/opengl/tutorial.html
#=====================================================================================================================================================
puts "\n" * 3 # some top buffer for terminal notifications.
puts "*" * 70
#-----------------------------------------------------------------------------------------------------------------------------------------------------
# https://www.codecademy.com/articles/ruby-command-line-argv
APP_NAME = 'Desktop Garage'
case ARGV.first
when 'debug'
  puts "#{APP_NAME} is in debug mode."
end
#-----------------------------------------------------------------------------------------------------------------------------------------------------
ROOT = File.expand_path('.',__dir__)
puts "starting up..."
# Gem used for OS window management and display libs as well as User input call backs.
require 'gosu'    # https://rubygems.org/gems/gosu
#-----------------------------------------------------------------------------------------------------------------------------------------------------
# System wide vairable settings.
require "#{ROOT}/Konfigure.rb"
include Konfigure # inclusion of CONSTANT settings system wide.

#=====================================================================================================================================================
# Load all additional source scripts. Files need to be in directory ALPHABETICAL order if refrenced in a later object source file.
script_dir = File.join(ROOT, "AdditionalClasses")
if FileTest.directory?(script_dir)
  # map to hash parrent directory
  files = [script_dir].map do |path|
    if File.directory?(path)
      Dir[File.join(path, '**', '*.rb')] # grab EVERY .rb file in provided directory.
    else # dir to file
      path
    end
  end.flatten
  # require all located source file_dirs
  files.each do |source_file|
    begin
      require(source_file)
    rescue => error # catch syntax errors on a file basis
      temp = source_file.split('/').last
      puts("FO Error: loading dir (#{temp})\n#{error}")
    end
  end
end

#=====================================================================================================================================================
# Gosu display window for the program.
#=====================================================================================================================================================
class Program < Gosu::Window
  #---------------------------------------------------------------------------------------------------------
	def initialize
    @@active_class = nil
		super(RESOLUTION[0], RESOLUTION[1], {:update_interval => UP_MS_DRAW, :fullscreen => ISFULLSCREEN})
		$program = self
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

