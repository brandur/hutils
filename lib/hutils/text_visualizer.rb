require "term/ansicolor"

module Hutils
  class TextVisualizer
    extend Term::ANSIColor
    include Term::ANSIColor

    def self.display_message(message, colors:, compact:, highlights:, out:, indent: "")
      message.to_a.sort_by { |k, v| k }.map { |k, v|
        pair_to_string(k, v, colors: colors, highlights: highlights)
      }.each_with_index { |display, i|
        if compact
          out.print(indent) if i == 0
          out.print("#{display} ")
        else
          marker = i == 0 ? "+ " : "  "
          out.puts "#{indent}#{marker}#{display}"
        end
      }
      out.puts ""
    end

    def initialize(colors:, compact:, highlights:, root:, out:)
      @colors = colors
      @compact = compact
      @highlights = highlights
      @out = out
      @root = root
    end

    def display
      display_node(@root)
    end

    private

    def self.colorize(method, str, colors:)
      if colors
        send(method, str)
      else
        str
      end
    end

    def self.pair_to_string(k, v, colors:, highlights:)
      if v == true
        colorize(:green, k, colors: colors)
      else
        if highlights.include?(k)
          colorize(:on_yellow, colorize(:black, "#{k}: #{v}", colors: colors), colors: colors)
        else
          "#{colorize(:green, k, colors: colors)}: #{v}"
        end
      end
    end

    def display_node(node)
      if !node.common.empty?
        # the "- 1" is because the root node is empty
        indent = "\t" * (node.depth - 1)
        TextVisualizer.display_message(node.common,
          colors: @colors,
          compact: @compact,
          highlights: @highlights,
          indent: indent,
          out: @out)
      end
      node.slots.each { |slot| display_node(slot) }
    end
  end
end
