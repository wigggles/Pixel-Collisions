#=====================================================================================================================================================
# An Active class that manages all map related things.
#=====================================================================================================================================================
class Map_Stage < Base_Active
  DEBUG_COLISION = true # display player polly points and step locations
  
  STEP_SLOPE  = [10,10]  # angle of step ability [length, hight]
  MOVESPEED   = 6       # player move speed in pixels per tick
  GRAVITY     = 4.2     # down/up ward force on entities
  #---------------------------------------------------------------------------------------------------------
  def initialize(file_name)
    super()
    # prep some working variables
    @jump       = [0, 15, false] # [hight, time, grounded?]
    @swimming   = false
    @climbing   = false
    # set screen camera
    @camera_pending_move_x = 0
    @camera_pending_move_y = 0
    @camera_should_x = 0
    @camera_should_y = 0
    @camera_is_x = 0
    @camera_is_y = 0
    @map_name = file_name
    # map properties
    @@tilemap = nil
  end
  #---------------------------------------------------------------------------------------------------------
  def calc_camera_movement(verbose = 0)
    # calculate where the camera should be
    @camera_should_x = $program.width / 2 + @player[1] + (@player[0].width / 2)
    @camera_should_y = $program.height / 2 - @player[2] - (@player[0].height / 2)
    # calculate how much the camera should move
    @camera_pending_move_x = (@camera_should_x - @camera_is_x) / 30
    @camera_pending_move_y = (@camera_should_y - @camera_is_y) / 40
    # calculate where the camera IS
    @camera_is_x += @camera_pending_move_x
    @camera_is_y += @camera_pending_move_y
    if verbose > 0
      s = "Camera status: Position: #{@camera_is_x.to_s}, #{@camera_is_y.to_s}. Going to #{@camera_should_x.to_s}, " + 
          "#{@camera_should_y.to_s}. Moving #{@camera_pending_move_x.to_s}, #{@camera_pending_move_y.to_s}"
      puts s
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def update_button_triggers
    if Gosu::button_down?(41) # esc
      $program.swap_active(Main_Menu.new)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def after_load
    # sets player location on the map
    x, y = @@tilemap.get_player_start
    puts "Setting player at #{x}, #{y}"
    move_player(x, y, true)
    super
  end
  #---------------------------------------------------------------------------------------------------------
  def cache_load
    $loading_screen.update_progress(0, 1, 'Initializing Map')
    # prepare loading list
    # (:step_id, 'data to load', internal_steps = 0)
    $loading_screen.add(:tex_map, 'biger_map.png', 3) 
    $loading_screen.add(:player, 'player.png')
    super # flag that no more steps to add
  end
  #---------------------------------------------------------------------------------------------------------
  def load_step
    # break down type step load operation
    data = super
    if data.empty?
      return # finished
    end
    # continue with steps
    current_step, data, intern, micro = data
    case current_step
    when :tex_map
      case intern # load internal stepping index
      when 0 # create new container class object for cache data
        $loading_screen.update_progress(0, 1, 'Loading Image')
        @@tilemap = PixelMapCache.new(@map_name, [5000, 5000])
        $loading_screen.advance_sub
      when 1
        # once loaded, call internal active class load stepping
        prog = @@tilemap.load_step
        $loading_screen.update_progress(prog[0],  prog[1], prog[2])
        if prog[0] >= prog[1] # reports back progress of completion
          $loading_screen.advance_sub
        end
      when 2
        # create a pre cache for faster load next time
        if @@tilemap.pre_cached
          $loading_screen.update_progress(98, 100, 'Loaded Cache')
        else
          $loading_screen.update_progress(89, 100, 'Saving Cache')
          @@tilemap.save_cache?
        end
        $loading_screen.advance_sub
      end
    when :player
      @player = [Gosu::Image.new("Media/#{data}", retro: true), 0, 0] # [image, x map pos, y map pos]
      poly_intersect = []; bottom = @player[0].height - 4
      poly_intersect.push([@player[0].width / 2, @player[0].height / 4]) # head
      poly_intersect.push([@player[0].width / 8, bottom])                # left foot
      poly_intersect.push([@player[0].width / 8 * 5, bottom])            # right foot
      # extra points
      poly_intersect.push([28, 58])            # body  left b
      poly_intersect.push([28, 86])            # body  left t
      poly_intersect.push([62, 58])            # body right b
      poly_intersect.push([52, 86])            # body right t
      # add to player container array
      @player.push(poly_intersect); @left = true
    when :image
      
    when :music
      
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def move_player(nx, ny, is_start = false)
    # look for collision
    type = nil
    @player[3].each do |poly_intersect|
      px = @player[1] + nx + poly_intersect[0]
      py = @player[2] + ny + poly_intersect[1]
      unless is_start
        contact = map_collision(px, py)
      end
      unless contact.nil?
        type = contact
        break
      end
    end
    # check collision type
    case type
    when :solid
      # can not move to location
      return false
    when :water
      @climbing = false
      @swimming = true
    when :ladder
      @climbing = true
      @swimming = false
    else
      @swimming = false
      @climbing = false
      # empty space
    end
    if is_start
      @player[1] = nx - $program.width / 4
      @player[2] = ny + $program.height / 2
      @camera_is_x = nx - $program.width + @player[1] - ($program.width * 2) + ($program.width / 4)
      @camera_is_y = -(ny - $program.height) - $program.height - ($program.height / 4)
      puts "Setting screen @ [#{@camera_is_x}, #{@camera_is_y}] | #{@player[1]}, #{@player[2]}"
    else
      # scroll map / move player
      @player[1] += nx
      @player[2] += ny
    end
    # can move to location
    return true
  end
  #---------------------------------------------------------------------------------------------------------
  def update
    return unless @@can_draw
    update_button_triggers
    # 'gravity'
    nx = 0; ny = 0
    unless @climbing
      if @swimming
        @jump[2] = false
        move_player(0, GRAVITY / 4)
      else # jumping
        unless @jump[0] > 0
          if move_player(0, GRAVITY)
            ny += GRAVITY
          else
            @jump[2] = true
          end
        else
          ny -= MOVESPEED * 2
          @jump[0] -= MOVESPEED * 2
        end
      end
    else
      # climbing
      @jump[2] = false
    end
    # move input
    moving = [false, false, false, false]
    if Gosu::button_down?(80)
      moving[0] = true # left
      @left = true
    elsif Gosu::button_down?(79)
      moving[1] = true # right
      @left = false
    end
    moving[3] = true if Gosu::button_down?(81)  # down
    if Gosu::button_down?(82) and (@jump[2] or @swimming or @climbing)
      moving[2] = true # up
    elsif !Gosu::button_down?(82)
      @jump[0] = 0
    end
    nx -= MOVESPEED if moving[0] # left
    nx += MOVESPEED if moving[1] # right
    ny += MOVESPEED if moving[3] # down
    if moving[2] # up / jumping
      if @swimming or @climbing
        ny -= MOVESPEED
        @jump[0] = MOVESPEED
      else # jumping
        @jump[0] = MOVESPEED * 2 * @jump[1]
        @jump[2] = false
      end
    end
    # update map location
    step_needed = move_player(nx, ny)
    # trying to step up?
    if !step_needed and (@jump[2] or @swimming or @climbing)
      leg = STEP_SLOPE
      y = @player[2] - leg[1] + @player[0].height
      if moving[0]
        x = @player[1] - nx - leg[0]
        unless map_collision(x, y) == :solid
          ny -= (MOVESPEED * CONDENSE_MAP) / 2
        end
      elsif moving[1]
        x = @player[1] + nx + leg[0] + @player[3][2][0]
        unless map_collision(x, y) == :solid
          ny -= (MOVESPEED * CONDENSE_MAP) / 2
        end
      end
      move_player(nx, ny)
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def map_collision(x, y)
    # check cache for type
    return @@tilemap.collision?(x, y) # uses symbol if found
  end
  #---------------------------------------------------------------------------------------------------------
  def draw
    return unless @@can_draw
    self.calc_camera_movement
    Gosu::translate(-@camera_is_x + $program.width, @camera_is_y) do
      @@tilemap.draw(0, 0)
      @player[0].draw(@player[1], @player[2], 200)
      if DEBUG_COLISION
        # show collisions
        @player[3].each do |poly_intersect|
          px = @player[1] + poly_intersect[0]
          py = @player[2] + poly_intersect[1]
          $program.draw_rect(px - 2, py - 2, 5, 5, 0xff_ff00ff, 300)
        end
        # show step spots
        leg = STEP_SLOPE
        y = @player[2] - leg[1] + @player[0].height
        x = @player[1] - leg[0] + @player[3][1][0]
        $program.draw_rect(x - 2, y - 2, 5, 5, 0xff_00ffff, 300)
        x = @player[1] + leg[0] + @player[3][2][0]
        $program.draw_rect(x - 2, y - 2, 5, 5, 0xff_00ffff, 300)
      end
    end
  end
end