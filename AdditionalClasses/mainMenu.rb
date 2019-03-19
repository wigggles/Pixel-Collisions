#=====================================================================================================================================================
# A basic main menu class loop.
#=====================================================================================================================================================
class Main_Menu < Base_Active
  SELECTION_PAUSE = 10
  #---------------------------------------------------------------------------------------------------------
  def initialize
    super
    @index = 0
    @input_pause = 0
    @item_list = ['New Game', 'Exit']
    @font = Gosu::Font.new($window, Gosu::default_font_name, 28)
  end
  #---------------------------------------------------------------------------------------------------------
  def action
    case @index
    when 0 # new
      $window.swap_active(Map_Stage.new(LVL_ONE))
    when 1 # exit
      exit
      return
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def update
    return unless @@can_draw
    @input_pause -= 1 if @input_pause > 0
    moving = [false, false, false, false]
    if Gosu::button_down?(80)
      moving[0] = true # left
    elsif Gosu::button_down?(79)
      moving[1] = true # right
    end
    if Gosu::button_down?(81) 
      moving[2] = true # down
    elsif Gosu::button_down?(82)
      moving[3] = true # up
    end
    # update move action
    if moving[3]    # up
      cursor(-1)
    elsif moving[2] # down
      cursor(1)
    end
    # selection action
    if Gosu::button_down?(44) or Gosu::button_down?(40) # space or enter
      action
    end
    # exit action
    if Gosu::button_down?(41) # esc
      $window.close!
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def cursor(ammount)
    return if @input_pause > 0
    @input_pause = SELECTION_PAUSE
    @index += ammount
    if @index < 0
      @index = @item_list.size - 1
    elsif @index > @item_list.size - 1
      @index = 0
    end
  end
  #---------------------------------------------------------------------------------------------------------
  def draw
    return unless @@can_draw
    # background
    $window.draw_rect(0, 0, $window.width, $window.height, 0xff_ffffff, 0)
    # draw selection display list
    x, y = $window.width / 2 - 76, $window.height / 2 - 32
    i = 0
    @item_list.each do |selection|
      y += i * 32 # ascend vertically
      if i == @index
        color = [0xFF_ff00ff, 0xFF_000000] # selected
      else
        color = [0xFF_000000, 0xFF_ffffff] # un-selected
      end
      # draw selection text and box
      $window.draw_rect(x, y, 128, 32, color[0], 1)
      @font.draw(selection, x + 4, y + 4, 10, 1, 1, color[1])
      i += 1
    end
  end
end
