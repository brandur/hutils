require "term/ansicolor"
require "time"

module Hutils
  class TextVisualizer
    class LineVisualizer
      include Term::ANSIColor

      def initialize(colors:, compact:, highlights:, out:)
        @colors = colors
        @compact = compact
        @highlights = highlights
        @out = out
      end

      def display(message, indent: "", time: nil)
        if time
          @out.print "#{colorize(:cyan, time.iso8601)} "
        end
        message.to_a.sort_by { |k, v| k }.map { |k, v|
          pair_to_string(k, v)
        }.each_with_index { |display, i|
          if @compact
            @out.print(indent) if i == 0
            @out.print("#{display} ")
          else
            marker = i == 0 ? "+ " : "  "
            @out.puts "#{indent}#{marker}#{display}"
          end
        }
        @out.puts ""
      end

      private

      def colorize(method, str)
        if @colors
          send(method, str)
        else
          str
        end
      end

      def pair_to_string(k, v)
        if v == true
          colorize(:green, k)
        else
          if @highlights.include?(k)
            colorize(:on_yellow, colorize(:black, "#{k}: #{v}"))
          else
            "#{colorize(:green, k)}: #{v}"
          end
        end
      end
    end

    def initialize(colors:, compact:, highlights:, root:, out:)
      @colors = colors
      @compact = compact
      @highlights = highlights
      @out = out
      @root = root

      @line_visualizer = LineVisualizer.new(
        colors: colors,
        compact: compact,
        highlights: highlights,
        out: out
      )
    end

    def display
      display_node(@root)
    end

    private

    def display_node(node)
      if !node.common.empty?
        # the "- 1" is because the root node is empty
        indent = "\t" * (node.depth - 1)
        @line_visualizer.display(node.common, indent: indent)
      end
      node.slots.each { |slot| display_node(slot) }
    end
  end
end
