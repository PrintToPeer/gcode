require 'gcode/codes'

module Gcode
  # Represents a single line in a Gcode file, parse expression tester: {http://rubular.com/}
  class Line
    include Codes

    # @!macro attr_accessor
    #   @!attribute [rw] $1
    #     @param speed_multiplier [Float] number speed (F) will be multiplied by.
    #     @return [nil] if the speed multiplier is not set.
    #     @return [Float] the speed multiplier (print moves only).
    #   @!attribute [rw] $2
    #     @param extrusion_multiplier [Float] number extrusions (E) will be multiplied by.
    #     @return [nil] if the extrusion multiplier is not set.
    #     @return [Float] the extrusion multiplier.
    #   @!attribute [rw] $3
    #     @param travel_multiplier [Float] number travel move speeds (F) will be multiplied by.
    #     @return [nil] if the travel multiplier is not set.
    #     @return [Float] the travel multiplier.
    #   @!attribute [rw] $4
    #     @param tool_number [Fixnum] the tool used in the command.
    #     @return [Fixnum] the tool used in the command.
    #   @!attribute [rw] $5
    #     @param f [Float] speed of the command (in mm/minute).
    #     @return [Float] the speed of the command (in mm/minute).
    attr_accessor :speed_multiplier, :extrusion_multiplier,
                  :travel_multiplier, :tool_number, :f, :x_add,
                  :y_add, :z_add

    # @!macro attr_reader
    #   @!attribute [r] $1
    #     @return [String] the line, upcased and stripped of whitespace.
    #   @!attribute [r] $2
    #     @return [nil] if the line wasn't valid Gcode.
    #     @return [MatchData] the raw matches from the regular expression evaluation.
    attr_reader :raw, :matches

    # Gcode matching pattern
    GCODE_PATTERN = /^(?<line>(?<command>((?<command_letter>[G|M|T])(?<command_number>\d{1,3}))) ?(?<regular_data>([S](?<s_data>\d*))? ?([P](?<p_data>\d*))? ?([X](?<x_data>[-]?\d+\.?\d*))? ?([Y](?<y_data>[-]?\d+\.?\d*))? ?([Z](?<z_data>[-]?\d+\.?\d*))? ?([F](?<f_data>\d+\.?\d*))? ?([E|A](?<e_data>[-]?\d+\.?\d*))?)? ?(?<string_data>[^;]*)?)? ?;?(?<comment>.*)?$/

    # Creates a {Line}
    # @param line [String] a line of Gcode.
    # @return [false] if line is empty or doesn't match the evaluation expression.
    # @return [Line]
    def initialize(line)
      return false if line.nil? || line.empty?
      @raw = line
      @matches = @raw.match(GCODE_PATTERN)
      return false if @matches.nil?
      # assign_values
      @f = @matches[:f_data].to_f unless @matches[:f_data].nil?
      @tool_number = command_number if !command_letter.nil? && command_letter == 'T'
    end

    # Checks if the given line is more than just a comment.
    # @return [Boolean] true if empty/invalid
    def empty?
      command.nil?
    end

    # Checks if the command in the line causes movement.
    # @return [Boolean] true if command moves printer, false otherwise.
    def is_move?
      command == RAPID_MOVE || command == CONTROLLED_MOVE
    end

    # Checks whether the line is a travel move or not.
    # @return [Boolean] true if line is a travel move, false otherwise.
    def travel_move?
      is_move? && e.nil?
    end

    # Checks whether the line is as extrusion move or not.
    # @return [Boolean] true if line is an extrusion move, false otherwise.
    def extrusion_move?
      is_move? && !e.nil? && e > 0
    end

    # Checks wether the line is a full home or not.
    # @return [Boolean] true if line is full home, false otherwise.
    def full_home?
      command == HOME && !x.nil? && !y.nil? && !z.nil?
    end

    # Returns the line, modified if multipliers are set and a line number is given.
    # @return [String] the line.
    def to_s(line_number = nil)
      # return line if line_number.nil? || !line_number.is_a?(Fixnum)
      # return prefix_line(line, line_number) if @extrusion_multiplier.nil? && @speed_multiplier.nil?

      new_f = multiplied_speed
      new_e = multiplied_extrusion

      x_string = !x.nil? ? " X#{x+@x_add.to_f}" : ''
      y_string = !y.nil? ? " Y#{y+@y_add.to_f}" : ''
      z_string = !z.nil? ? " Z#{z+@z_add.to_f}" : ''
      e_string = !e.nil? ? " E#{new_e}" : ''
      f_string = !f.nil? ? " F#{new_f}" : ''
      p_string = !p.nil? ? " P#{p}" : ""
      s_string = !s.nil? ? " S#{s}" : ""
      string = !string_data.nil? ? " #{string_data}" : ''

      prefix_line("#{command}#{s_string}#{p_string}#{x_string}#{y_string}#{z_string}#{f_string}#{e_string}#{string}".strip, line_number)
    end

## Line value functions

    # Striped version of the input Gcode, or nil if not valid Gcode
    # @return [String] striped line of Gcode.
    # @return [nil] if no Gcode was present .
    def line
      if @line.nil? && !@matches[:line].nil?
        @line = @matches[:line].strip
      else
        @line
      end
    end

    # The command in the line, nil if no command is present.
    # @return [String] command in the line.
    # @return [nil] if no command is present.
    def command
      @matches[:command]
    end

    # The command letter of the line, nil if no command is present.
    # @return [String] command letter of the line.
    # @return [nil] if no command is present.
    def command_letter
      @matches[:command_letter]
    end

    # The command number of the line, nil if no command is present.
    # @return [Fixnum] command number of the line.
    # @return [nil] if no command is present.
    def command_number
      if @command_number.nil? && !@matches[:command_number].nil?
        @command_number = @matches[:command_number].to_i
      else
        @command_number
      end
    end

    # The X value of the line, nil if no X value is present.
    # @return [Float] X value of the line.
    # @return [nil] if no X value is present.
    def x
      if @x.nil? && !@matches[:x_data].nil?
        @x = @matches[:x_data].to_f
      else
        @x
      end
    end

    # The Y value of the line, nil if no Y value is present.
    # @return [Float] Y value of the line.
    # @return [nil] if no Y value is present.
    def y
      if @y.nil? && !@matches[:y_data].nil?
        @y = @matches[:y_data].to_f
      else
        @y
      end
    end

    # The Z value of the line, nil if no Z value is present.
    # @return [Float] Z value of the line.
    # @return [nil] if no Z value is present.
    def z
      if @z.nil? && !@matches[:z_data].nil?
        @z = @matches[:z_data].to_f
      else
        @z
      end
    end

    # The E value of the line, nil if no E value is present.
    # @return [Float] E value of the line.
    # @return [nil] if no E value is present.
    def e
      if @e.nil? && !@matches[:e_data].nil?
        @e = @matches[:e_data].to_f
      else
        @e
      end
    end

    # The S value of the line, nil if no S value is present.
    # @return [Fixnum] S value of the line.
    # @return [nil] if no S value is present.
    def s
      if @s.nil? && !@matches[:s_data].nil?
        @s = @matches[:s_data].to_i
      else
        @s
      end
    end

    # The P value of the line, nil if no P value is present.
    # @return [Fixnum] P value of the line.
    # @return [nil] if no P value is present
    def p
      if @p.nil? && !@matches[:p_data].nil?
        @p = @matches[:p_data].to_i
      else
        @p
      end
    end

    # The string data of the line, nil if no string data is present.
    # @return [String] string data of the line.
    # @return [nil] if no string data is present
    def string_data
      if @string_data.nil? && (!@matches[:string_data].nil? || !@matches[:string_data].empty?)
        @string_data = @matches[:string_data].strip
      else
        @string_data
      end
    end

    # The comment of the line, nil if no comment is present.
    # @return [String] comment of the line.
    # @return [nil] if no comment is present
    def comment
      if @comment.nil? && !@matches[:comment].nil?
        @comment ||= @matches[:comment].strip
      else
        @comment
      end
    end

private

    def multiplied_extrusion
      if !e.nil? && valid_multiplier?(@extrusion_multiplier)
        return e * @extrusion_multiplier
      else
        e
      end
    end

    def multiplied_speed
      if travel_move? && valid_multiplier?(@travel_multiplier)
        return f * @travel_multiplier
      elsif extrusion_move? && valid_multiplier?(@speed_multiplier)
        return f * @speed_multiplier
      else
       return f
      end
    end

    def valid_multiplier?(multiplier)
      !multiplier.nil? && (multiplier.class == Fixnum || multiplier.class == Float) && multiplier > 0
    end

    def get_checksum(command)
      command.bytes.inject{|a,b| a^b}.to_s
    end

    def prefix_line(command, line_number)
      return command if line_number.nil?
      prefix = 'N' + line_number.to_s + ' ' + command
      (prefix+'*'+get_checksum(prefix))
    end

  end
end