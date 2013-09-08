require 'gcode/codes'
require 'gcode/line'
require 'gcode/pretty_output'

module Gcode
  # A class that represents a processed Gcode file.
  class Object
    include Codes
    include PrettyOutput

    # An array of the raw Gcode with each line as an element.
    # @return [Array] of raw Gcode without the comments stripped out.
    attr_accessor :raw_data
    # @!macro attr_reader
    #   @!attribute [r] $1
    #     @return [Array<Line>] an array of {Line}s.
    #   @!attribute [r] $2
    #     @return [Float] the smallest X coordinate of an extrusion line.
    #   @!attribute [r] $3
    #     @return [Float] the biggest X coordinate of an extrusion line.
    #   @!attribute [r] $4
    #     @return [Float] the smallest Y coordinate of an extrusion line.
    #   @!attribute [r] $5
    #     @return [Float] the biggest Y coordinate of an extrusion line.
    #   @!attribute [r] $6
    #     @return [Float] the smallest Z coordinate.
    #   @!attribute [r] $7
    #     @return [Float] the biggest Z coordinate.
    #   @!attribute [r] $8
    #     @return [Array<Float>] the amount in mm of fliament extruded with the index representing the extruder.
    #   @!attribute [r] $9
    #     @return [Float] the distance in total that the X axis will travel in mm.
    #   @!attribute [r] $10
    #     @return [Float] the distance in total that the Y axis will travel in mm.
    #   @!attribute [r] $11
    #     @return [Float] the distance in total that the Z axis will travel in mm.
    #   @!attribute [r] $12
    #     @return [Float] the distance in total that the E axis will travel in mm.
    #     @todo implement this
    #   @!attribute [r] $13
    #     @return [Float] the width of the print.
    #   @!attribute [r] $14
    #     @return [Float] the depth of the print.
    #   @!attribute [r] $15
    #     @return [Float] the height of the print.
    #   @!attribute [r] $16
    #     @return [Fixnum] the number of layers in the print.
    #   @!attribute [r] $17
    #   @return [Float] the estimated durration of the print in seconds.
    #   @!attribute [r] $18
    #   @return [Array] of the lines that only contained comments found in the file.
    #   @!attribute [r] $19
    #   @return [Array<Hash<Fixnum>>] ranges of commands with their respective layer represented by the array index.
    attr_reader :lines, :x_min, :x_max, :y_min, :y_max, :z_min, :z_max,
                :filament_used, :x_travel, :y_travel, :z_travel, :e_travel,
                :width, :depth, :height, :layers, :total_duration, :comments,
                :layer_ranges

    # Creates a Gcode {Object}.
    # @param data [String] path to a Gcode file on the system.
    # @param data [Array] with each element being a line of Gcode.
    # @param auto_process [Boolean] enable/disable auto processing.
    # @param default_speed [Float] the default speed (in mm/minute) for moves that don't have one declared.
    # @param acceleration [Float] the acceleration rate set in the printer' firmware.
    # @return [Object] if data is valid, returns a Gcode {Object}.
    # @return [false] if data is not an array, path, didn't contain Gcode or default_speed wasn't a number grater than 0.
    def initialize(options = {})
      if options.is_a?(Array)
        temp_data = options
        options = {}
        options[:data] = temp_data
        temp_data = nil
      end
      options = default_options.merge!(options)
      return false unless positive_number?(options[:default_speed])
      return false unless positive_number?(options[:acceleration])
      if options[:data].class == String && self.class.is_file?(options[:data])
        options[:data] = self.class.get_file(options[:data])
      end
      return false if options[:data].nil? || options[:data].class != Array
      @options = options
      set_variables
      @raw_data.each do |line|
        line = set_line_properties(Line.new(line))
        if line
          unless line.empty?
            @lines << line
          else
            @comments << line.comment
          end
        end
      end
      process if options[:auto_process]
      return false if empty?
    end

    # Checks if the given string is a file and if it exists.
    # @param file [String] path to a file on the system.
    # @return [Boolean] true if is a file that exists on the system, false otherwise.
    def self.is_file?(file)
      !file.nil? && !file.empty? && File.exist?(file) && File.file?(file)
    end

    # Returns an array of the lines of the file if it exists.
    # @param file [String] path to a file on the system.
    # @return [Array] containting the lines of the given file as elements.
    # @return [false] if given string isn't a file or doesn't exist.
    def self.get_file(file)
      return false unless self.is_file?(file)
      IO.readlines(file)
    end

    # alias for {#empty?}.
    # @see #empty?
    def blank?
      empty?
    end

    # Checks if there are any {Line}s in {#lines}.
    # @return [Boolean] true if no lines, false otherwise.
    def empty?
      @lines.empty?
    end

    # Opposite of {#empty?}.
    # @see #empty?
    def present?
      !empty?
    end

    # Checks if the Gcode object contains multiple materials.
    # @return [nil] if processing hasn't been done.
    # @return [Boolean] true if multiple extruders used, false otherwise.
    def multi_material?
      return nil unless @width
      @filament_used.length > 1
    end

    # Returns estimated durration of the print in a human readable format.
    # @return [String] human readable estimated durration of the print.
    def durration_in_words
      seconds_to_words(@total_duration)
    end

    # Get the layer number the given command number is in.
    # @param command_number [Fixnum] number of the command who's layer number you'd lke to know.
    # @return [Fixnum] layer number for the given command number.
    # @return [nil] if the given command number is invalid or if the object wasn't processed.
    def in_what_layer?(command_number)
      return nil if @width.nil? || !command_number.is_a?(Fixnum) || command_number < 0 || command_number > @lines.length
      layer = 1
      @layers.times do
        return layer if (@layer_ranges[layer][:lower]..@layer_ranges[layer][:upper]).include?(command_number)
        layer += 1
      end
      nil
    end

    def write_to_file(output_file, encoding = "us-ascii")
      begin
        fd = File.open(output_file, 'w+')
        @lines.each do |line|
          fd.write (line.to_s+"; #{line.comment.to_s}"+"\n").encode(encoding)
        end
      ensure
        fd.close
      end
    end

private

    def default_options
      {default_speed: 2400, auto_process: true, acceleration: 1500, add_speed: false}
    end

    def process
      set_processing_variables

      @lines.each do |line|
        case line.command
        when USE_INCHES
          @imperial = true
        when USE_MILLIMETRES
          @imperial = false
        when ABS_POSITIONING
          @relative = false
        when REL_POSITIONING
          @relative = true
        when ABS_EXT_MODE
          @relative_extrusion = false
        when REL_EXT_MODE
          @relative_extrusion = true
        when SET_POSITION
          @set_position_called = true
          set_positions(line)
        when HOME
          home_axes(line)
        when RAPID_MOVE
          movement_line(line)
        when CONTROLLED_MOVE
          count_layers(line)
          movement_line(line)
          calculate_time(line)
        when DWELL
          @total_duration += line.p/1000 unless line.p.nil?
        end
        @current_line += 1
      end
      @layer_ranges[@layers][:upper] = @current_line
      set_dimensions
    end

    def set_dimensions
      @width = @x_max - @x_min
      @depth = @y_max - @y_min
      @height = @z_max - @z_min
    end

    def calculate_time(line)
      line.f.nil? ? @speed_per_second = @last_speed_per_second : @speed_per_second = line.f / 60
      current_travel = hypot3d(@current_x, @current_y, @current_z, @last_x, @last_y, @last_z)
      distance = (2*((@last_speed_per_second+@speed_per_second)*(@speed_per_second-@last_speed_per_second)*0.5)/@acceleration).abs
      if distance <= current_travel && !(@last_speed_per_second+@speed_per_second).zero? && !@speed_per_second.zero?
        move_duration = (2*distance/(@last_speed_per_second+@speed_per_second))+((current_travel-distance)/@speed_per_second)
      else
        move_duration = Math.sqrt(2*distance/@acceleration)
      end
      @total_duration += move_duration
    end

    def count_layers(line)
      if !line.z.nil? && line.z > @current_z
        @layer_ranges[@layers][:upper] = @current_line
        @layers += 1
        @layer_ranges[@layers] = {}
        @layer_ranges[@layers][:lower] = @current_line
      end
    end

    def hypot3d(x1, y1, z1, x2 = 0.0, y2 = 0.0, z2 = 0.0)
      Math.hypot(x2-x1, Math.hypot(y2-y1, z2-z1))
    end

    def movement_line(line)
      measure_travel(line)
      set_last_values
      set_current_position(line)
      calculate_filament_usage(line)
      set_limits(line)
    end

    def measure_travel(line)
      if @relative
        @x_travel += to_mm(line.x).abs unless line.x.nil?
        @y_travel += to_mm(line.y).abs unless line.y.nil?
        @z_travel += to_mm(line.z).abs unless line.z.nil?
      else
        @x_travel += (@current_x - to_mm(line.x)).abs unless line.x.nil?
        @y_travel += (@current_y - to_mm(line.y)).abs unless line.y.nil?
        @z_travel += (@current_z - to_mm(line.z)).abs unless line.z.nil?
      end
    end

    def home_axes(line)
      if !line.x.nil? || line.full_home?
        @x_travel += @current_x
        @current_x = 0
      end
      if !line.y.nil? || line.full_home?
        @y_travel += @current_y
        @current_y = 0
      end
      if !line.z.nil? || line.full_home?
        @z_travel += @current_z
        @current_z = 0
      end
    end

    def positive_number?(number, grater_than = 0)
      number.is_a?(Numeric) && number >= grater_than
    end

    def set_last_values
      @last_x = @current_x
      @last_y = @current_y
      @last_z = @current_z
      @last_e = @current_e
      @last_speed_per_second = @speed_per_second
    end

    def set_positions(line)
      @current_x = to_mm(line.x) unless line.x.nil?
      @current_y = to_mm(line.y) unless line.y.nil?
      @current_z = to_mm(line.z) unless line.z.nil?
      unless @relative_extrusion
        @filament_used[line.tool_number] = 0 if @filament_used[line.tool_number].nil?
        @filament_used[line.tool_number] += @current_e
      end
      @current_e = to_mm(line.e) unless line.e.nil?
    end

    def set_current_position(line)
      if @relative
        @current_x += to_mm(line.x) unless line.x.nil?
        @current_y += to_mm(line.y) unless line.y.nil?
        @current_z += to_mm(line.z) unless line.z.nil?
      else
        @current_x = to_mm(line.x) unless line.x.nil?
        @current_y = to_mm(line.y) unless to_mm(line.y).nil?
        @current_z = to_mm(line.z) unless line.z.nil?
      end
      if @relative_extrusion
        @current_e += to_mm(line.e) unless line.e.nil?
      else
        @current_e = to_mm(line.e) unless line.e.nil?
      end
    end

    def calculate_filament_usage(line)
      return if @set_position_called
      @filament_used[line.tool_number] = 0 if @filament_used[line.tool_number].nil?
      @filament_used[line.tool_number] = @current_e
    end

    def set_limits(line)
      if line.extrusion_move?
        unless line.x.nil?
          @x_min = @current_x if @current_x < @x_min
          @x_max = @current_x if @current_x > @x_max
        end
        unless line.y.nil?
          @y_min = @current_y if @current_y < @y_min
          @y_max = @current_y if @current_y > @y_max
        end
      end
      unless line.z.nil?
        @z_min = @current_z if @current_z < @z_min
        @z_max = @current_z if @current_z > @z_max
      end
    end

    def set_line_properties(line)
      return false unless line
      return line if line.command.nil?
      @tool_number = line.tool_number unless line.tool_number.nil?
      line.tool_number = @tool_number if line.tool_number.nil?
      @speed = line.f unless line.f.nil?
      line.f = @speed if line.f.nil? && @options[:add_speed]
      line.x_add = @options[:x_add]
      line.y_add = @options[:y_add]
      line.z_add = @options[:z_add]
      line
    end

    def set_processing_variables
      @x_travel = 0
      @y_travel = 0
      @z_travel = 0
      @current_x = 0
      @current_y = 0
      @current_z = 0
      @current_e = 0
      @last_x = 0
      @last_y = 0
      @last_z = 0
      @last_e = 0
      @x_min = 999999999
      @y_min = 999999999
      @z_min = 0
      @x_max = -999999999
      @y_max = -999999999
      @z_max = -999999999
      @filament_used = []
      @layers = 1
      @layer_ranges = []
      @layer_ranges[1] = {}
      @layer_ranges[1][:lower] = 0
      @current_line = 0
      # Time
      @speed_per_second = 0.0
      @last_speed_per_second = 0.0
      @move_duration = 0.0
      @total_duration = 0.0
      @acceleration = 1500.0 #mm/s/s  ASSUMING THE DEFAULT FROM SPRINTER !!!!
    end

    def set_variables
      @raw_data = @options[:data]
      @imperial = false
      @relative = false
      @tool_number = 0
      @speed = @options[:default_speed].to_f
      @acceleration = @options[:acceleration]
      @lines = []
      @comments = []
    end

    def to_mm(number)
      return number unless @imperial
      number *= 25.4 if !number.nil?
    end

  end
end