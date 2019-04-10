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
    @font = Gosu::Font.new($program, Gosu::default_font_name, 28)
    $program.update_interval = 1.0
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
    $program.caption = " Loading#{ext}"
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
    $program.update_interval = UP_MS_DRAW
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
    $program.draw_rect(0, 0, $program.width, $program.height, 0xff_ffffff, 0)
    # status
    header, percentage = current_progress
    # percentage bar
    bw = $program.width  / 2
    bh = $program.height / 16
    $program.draw_rect($program.width / 2 - (bw / 2), $program.height / 2 - (bh / 2), bw, bh, 0xff_000000, 10)
    # bar filler
    pw = (bw.to_f * percentage.to_f).round
    #puts "loading #{pw} #{$loading_screen[0]} / #{$loading_screen[1]}"
    px = $program.width / 2 - (bw / 2)
    py = $program.height / 2 - (bh / 2) - 2
    $program.draw_rect(px, py + 6, pw, bh - 8, 0xff_00ff00, 20)
    # header line
    @font.draw(header, px, py - 32, 100, 1, 1, 0xFF_000000)
  end
end