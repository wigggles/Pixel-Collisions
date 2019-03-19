#=====================================================================================================================================================
# Working load step system.
#=====================================================================================================================================================
class Load_Que
  include Konfigure
  #---------------------------------------------------------------------------------------------------------
  def initialize
    @index    = 0
    @sub_index= 0
    @micro    = [0, 1]
    @@finished = false
    @list      = []
    @@progress = [0, 1]
    @font = Gosu::Font.new($window, Gosu::default_font_name, 28)
    $window.update_interval = 1.0
    @cap_up = 0
  end
  #---------------------------------------------------------------------------------------------------------
  def data(index)
    return @list[index]
  end
  #---------------------------------------------------------------------------------------------------------
  def add(step_sym, main_call, internals = 0)
    @list.push([step_sym, main_call, internals])
  end
  #---------------------------------------------------------------------------------------------------------
  def step
    ext = '.' * @cap_up
    @cap_up += 1
    @cap_up = 0 if @cap_up > 3
    $window.caption = " Loading#{ext}"
    if @list.empty? or @index > @list.size
      return []
    end
    # proceed with stepping foreword
    step, main, intern = @list[@index]
    if intern.nil?
      return []
    end
    if intern > 0 and @sub_index < intern
      return [step, main, @sub_index, @micro]
    end
    @sub_index= 0
    @index += 1
    return [step, main, intern, @micro]
  end
  #---------------------------------------------------------------------------------------------------------
  def current_chunk
    current = @micro[0]
    @micro[0] += @micro[2]
    return current
  end
  #---------------------------------------------------------------------------------------------------------
  def chunkers
    return ((@micro[1] / @micro[2]).ceil)
  end
  #---------------------------------------------------------------------------------------------------------
  def set_micro(max, divide)
    @micro = [0, max, divide]
  end
  #---------------------------------------------------------------------------------------------------------
  def advance_micro(value)
    @micro[0] = value
  end
  #---------------------------------------------------------------------------------------------------------
  def advance_sub
    @sub_index += 1
  end
  #---------------------------------------------------------------------------------------------------------
  def finish
    @list      = []
    @index     = 0
    @@finished = true
    $window.update_interval = UP_MS_DRAW
  end
  #---------------------------------------------------------------------------------------------------------
  def done?
    return @@finished
  end
  #---------------------------------------------------------------------------------------------------------
  def working_progress_values
    return @@progress
  end
  #---------------------------------------------------------------------------------------------------------
  def update_progress(at, done, header)
    @@progress = [at, done, header]
  end
  #---------------------------------------------------------------------------------------------------------
  def current_progress
    max = @@progress[1] > 0 ? @@progress[1] : 1 # no dividing by zero
    return [@@progress[2], (@@progress[0].to_f / max.to_f).to_f]
  end
  #---------------------------------------------------------------------------------------------------------
  def draw
    $window.draw_rect(0, 0, $window.width, $window.height, 0xff_ffffff, 0)
    # status
    header, percentage = current_progress
    # percentage bar
    bw = $window.width  / 2
    bh = $window.height / 16
    $window.draw_rect($window.width / 2 - (bw / 2), $window.height / 2 - (bh / 2), bw, bh, 0xff_000000, 10)
    # bar filler
    pw = (bw.to_f * percentage.to_f).round
    #puts "loading #{pw} #{$loading_screen[0]} / #{$loading_screen[1]}"
    px = $window.width / 2 - (bw / 2)
    py = $window.height / 2 - (bh / 2) - 2
    $window.draw_rect(px, py + 6, pw, bh - 8, 0xff_00ff00, 20)
    # header line
    @font.draw(header, px, py - 32, 100, 1, 1, 0xFF_000000)
  end
end