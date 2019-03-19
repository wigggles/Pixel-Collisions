#=====================================================================================================================================================
# Included require all source script loading abilities, can load directories of sources files. Does this alphabetically.
#=====================================================================================================================================================
module RequireAll
  PRINT_LOAD_ERROR = true # there was an issue loading with out this. * Wiggles patch *
  #-------------------------------------------------------------------------------------------------------------------------------------------
  def require_all(*args)
    # Handle passing an array as an argument
    args.flatten!
    if args.size > 1
      # Expand files below directories
      files = args.map do |path|
        if File.directory? path
          Dir[File.join(path, '**', '*.rb')]
        else
          path
        end
      end.flatten
    else
      arg = args.first
      begin
        # Try assuming we're doing plain ol' require compat
        if arg.is_a?(Array)
          stat = File.stat(arg)
        else
          if arg.is_a?(String)
            stat = File.stat(arg) rescue nil
          end
          if stat.nil? # * PATCHED *
            if PRINT_LOAD_ERROR
              print("Require All Error: #{stat}\n no such file to load -- #{arg}\n\n")
            end
            return false
          end
        end
        if stat.file?
          files = [arg]
        elsif stat.directory?
          files = Dir.glob File.join(arg, '**', '*.rb')
        else
          raise ArgumentError, "#{arg} isn't a file or directory"
        end
      rescue Errno::ENOENT
        # If the stat failed, maybe we have a glob!
        files = Dir.glob arg
        # Maybe it's an .rb file and the .rb was omitted
        if File.file?(arg + '.rb')
          require(arg + '.rb')
          return true
        end
        # If we ain't got no files, the glob failed
        if files.empty?
          if PRINT_LOAD_ERROR
            puts "RequireAll: No such file to load -- #{arg}"
          end
          return false
        end
      end
    end
    # If there's nothing to load, you're doing it wrong!
    if files.empty?
      if PRINT_LOAD_ERROR
        puts "RequireAll Load Error: no files to load in Dir given."
      end
      return false
    end
    files.map! { |file| File.expand_path file }
    files.sort! # organize the files alphabetically for initialization
    if PRINT_LOAD_ERROR
      #puts 'Loading source files:' 
      #puts "#{files.join("\n ")}"
    end
    begin
      failed = []
      first_name_error = nil
      files.each do |file|
        begin
          require file
        rescue NameError => ex
          failed << file
          first_name_error ||= ex
        rescue ArgumentError => ex
          raise unless ex.message["is not missing constant"]
          STDERR.puts "Warning: require_all swallowed ActiveSupport 'is not missing constant' error"
          STDERR.puts ex.backtrace[0..9]
        end
      end
      if failed.size == files.size
        raise first_name_error
      else
        files = failed
      end
    end until failed.empty?
    true
  end
  #-------------------------------------------------------------------------------------------------------------------------------------------
  def require_rel(*paths)
    paths.flatten!
    source_directory = File.dirname caller.first.sub(/:\d+$/, '')
    paths.each do |path|
      require_all File.join(source_directory, path)
    end
  end
end