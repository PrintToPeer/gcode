module Gcode
  # provides methods to make human readable output.
  module PrettyOutput

private

    def seconds_to_words(seconds)
      [[60, :seconds], [60, :minutes], [24, :hours], [1000, :days]].map{ |count, name|
        if seconds > 0
          seconds, n = seconds.divmod(count)
          "#{n.to_i} #{name}"
        end
      }.compact.reverse.join(' ')
    end

  end
end