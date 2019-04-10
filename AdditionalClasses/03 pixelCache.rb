#=====================================================================================================================================================
# Internal handle for image pixel related collision data.
#=====================================================================================================================================================
class Map_Stage::PixelMapCache
  include Konfigure
  attr_reader :pre_cached
  #---------------------------------------------------------------------------------------------------------
  def initialize(name, size = [500, 500])
    #--------------------------------
    @@collision_type = { # values in color RGBA
      # color_flag => :collision_type
      "ffffffff" => :solid,
      "22b14cff" => :solid,
      "5598c3ff" => :solid,
      "0065a6ff" => :solid,
      "0000ffff" => :water,
      "ff8500ff" => :ladder,
      "351c00ff" => :ladder,
      "321e1fff" => :player_start
    }
    #--------------------------------
    @z = 100
    file_name = name
    unless File.exist?("#{ROOT}/Media/Maps/#{file_name}.png")
      file_name = hunt_for_file(file_name)
      if file_name.nil?
        puts "Could not find map file: #{name}"
      end
    end
    if file_name.include?(' P.')
      name, fsize = file_name.split(' P.')
      size = fsize.split(/[xX]/)
    end
    @width  = size[0].to_i
    @height = size[1].to_i
    @name = name
    @file_name = file_name
    @load_step = [0, 0]
    @pre_cached = false
    width = (@width / MAP_CHUNK) + 1; height = (@height / MAP_CHUNK) + 1
    @load_index = 1; @load_size = width * height
    @screen_chunks  = [($program.width / MAP_CHUNK).ceil + 1, ($program.height / MAP_CHUNK).ceil + 1]
    #@@image_chunks  = {}
    @@collision_map = {}
    @@image = nil
    #puts "Creating a new PixelMapCache: #{@file_name} | Steps: #{@load_size}"
    check_for_pre_cache
  end
  #---------------------------------------------------------------------------------------------------------
  def file_dir
    return "Media/Maps/PreCaches/#{@name}"
  end
  #---------------------------------------------------------------------------------------------------------
  def get_player_start
    pos = @@collision_map["pl_st"]
    if pos.nil?
      puts "There was no starting pixel found to define player starting position. Use Color: #{@@collision_type.key(:player_start)}"
      return [0,0]
    end
    return pos
  end
  #---------------------------------------------------------------------------------------------------------
  def save_cache?
    return false if @pre_cached
    # save pre cached collisions for next load.
    #Data_Manager.saveM(@@collision_map, file_dir)    # Data size inflates a lot
    Data_Manager.save_gzib(@@collision_map, file_dir) # Compressed inflation, smaller files
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  def check_for_pre_cache
    # if there is a pre cache and its up to date with map image load it
    if File.exist?("#{ROOT}/Media/Maps/PreCaches/#{@name}.gz")
      @@collision_map = Data_Manager.load_gzib(file_dir)
      @pre_cached = true
      puts "Using a cached collision file for map."
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def self.pack_pixel(string_value)
    o,r,g,b = string_value.scan(/.{2}/)
    data = ["#{o}#{r}#{g}#{b}"].pack('H*')
    return data
  end
  #---------------------------------------------------------------------------------------------------------
  def collision_type
    return @@collision_type
  end
  #---------------------------------------------------------------------------------------------------------
  def hunt_for_file(partial_name)
    file_name = ''
    Dir.glob("#{ROOT}/Media/Maps/**/*.png") do |path|
      if path =~ /.*\.png$/
        full_name = path.split('/').last
        if full_name.include?(partial_name)
          full_name.sub!('.png', '')
          file_name = full_name
          break
        end
      end
    end
    #puts file_name
    return file_name
  end
  #---------------------------------------------------------------------------------------------------------
  def load_step
    if @@image.nil?
      @@image = Gosu::Image.new("Media/Maps/#{@file_name}.png", retro: true)
    end
    prog = [@load_index, @load_size]; per = (prog[0].to_f / prog[1].to_f * 100).round
    rx = @load_step[0] * MAP_CHUNK
    ry = @load_step[1] * MAP_CHUNK
    unless @pre_cached
      image = nil
      if (@load_step[0] + 1) * MAP_CHUNK >  @width
        width = @width % MAP_CHUNK
      else
        width = MAP_CHUNK
      end
      height = (@load_step[1] + 1) * MAP_CHUNK > @height ? @height % MAP_CHUNK : MAP_CHUNK
      view_port = [rx, ry, width, height]
      #puts "[#{(@load_step[0] + 1) * MAP_CHUNK}] #{@width} [#{@width % MAP_CHUNK}]"
      image = Gosu::Image.new("Media/Maps/#{@file_name}.png", retro: true, rect: view_port) rescue nil
      if image.nil?
        puts "Error loading map: #{@name} | \"Media/Maps/#{@file_name}.png\" File was not found?"
        exit
      end
      temp_map = image.to_blob.unpack('H*')[0] # 'H*' 'M'
      temp_map = temp_map.scan(/.{8}/) # 8 4
      #puts "Map: #{temp_map.size}\n#{temp_map.join(', ')}"; exit
      collisions = {}
      0.upto(temp_map.size / CONDENSE_MAP) do |i|
        collision = collision_type[temp_map[i*CONDENSE_MAP]]
        next if collision.nil? # don't make space and cache nil collisions
        x = i % width; y = i / width
        #puts "Detected! [#{x},#{y}] = #{collision}"
        if collision == :player_start
          collisions["#{x}_#{y}"] = nil
          if @@collision_map["pl_st"].nil?
            @@collision_map["pl_st"] = [rx + x, ry + y]
            puts "Player starting position found pixel: #{rx + x}, #{ry + y}"
          end
        else
          collisions["#{x}_#{y}"] = collision
        end
      end
      @@collision_map["#{@load_step[0]}_#{@load_step[1]}"] = collisions
      #@@image_chunks["#{@load_step[0]}_#{@load_step[1]}"]  = image
      prog.push('Building Cache')
    else
      prog.push('Refrencing Collisions')
    end
    #puts "  Loading ImageMap. %#{per} -> #{@load_step[0]} | #{@load_step[1]} | CHUNK: [#{view_port.join(', ')}]"
    # update current position in job que task
    @load_step[0] += 1
    if rx + MAP_CHUNK >= @width
      @load_step[1] += 1
      @load_step[0] = 0
    end
    if @load_step[1] > (@height / MAP_CHUNK).ceil
      return [1, 1]
    end
    @load_index += 1
    return prog # report back progress in load stepping job
  end
  #---------------------------------------------------------------------------------------------------------
  def update
    
  end
  #---------------------------------------------------------------------------------------------------------
  def draw(screen_x, screen_y)
    #if @@image.nil?
    #  rx = (screen_x.abs / MAP_CHUNK).floor
    #  ry = (screen_y.abs / MAP_CHUNK).floor
    #  #puts "#{screen_y.round}:#{MAP_CHUNK} | #{rx}m#{ry}"
    #  begin
    #    # needs work on alignment
    #    mx = rx + @screen_chunks[0]; my = ry + @screen_chunks[1]
    #    rx.upto(mx) do |map_x|
    #      ry.upto(my) do |map_y|
    #        sx = map_x * MAP_CHUNK + screen_x
    #        sy = map_y * MAP_CHUNK + screen_y
    #        image = @@image_chunks["#{map_x}_#{map_y}"]
    #        unless image.nil?
    #          image.draw(sx.floor, sy.floor, @z)
    #        end
    #      end
    #    end
    #  rescue => error
    #    puts "Pixel Map Draw Error:\n  [#{rx}, #{ry}]\n  #{error}\n  #{error.backtrace[0]}"
    #    puts "  Screen LOC: #{screen_x} , #{screen_y}\n\n"
    #    exit
    #  end
    #else
      @@image.draw(screen_x.floor, screen_y.floor, @z)
    #end
  end
  #---------------------------------------------------------------------------------------------------------
  def collision?(map_x, map_y)
    return :solid if map_x < 0 or map_y < 0
    return :solid if map_x >= @width or map_y >= @height
    rx = (map_x / MAP_CHUNK).floor; rx = 0 if rx < 0
    ry = (map_y / MAP_CHUNK).floor; ry = 0 if ry < 0
    map_x = (map_x.round % MAP_CHUNK)
    map_y = (map_y.round % MAP_CHUNK)
    collision_type = nil
    begin
      # @@collision_map[rx][ry][map_x][map_y]
      quadrent = @@collision_map["#{rx}_#{ry}"]
      x = (map_x/CONDENSE_MAP).floor; y = (map_y/CONDENSE_MAP).floor
      collision_type = quadrent["#{x}_#{y}"]
    rescue => error
      puts "Pixel Map Buffer Error:\n  Q['#{rx}_#{ry}'] T['#{x}_#{y}']\n  #{error}\n  #{error.backtrace[0]}"
      puts "  EXT:\n#{collision_type}\n"
      exit
    end
    #unless collision_type.nil?
    #  puts "Q['#{rx}_#{ry}'] T['#{map_x}_#{map_y}'] = #{collision_type}"
    #end
    return collision_type
  end
  #---------------------------------------------------------------------------------------------------------
  def dispose
    #@@image_chunks  = nil
    @@collision_map = nil
    @@image = nil
  end
end
