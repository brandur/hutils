require "curses"

module Hutils::Mdash
  class MetricVisualizer
    def initialize(colors:, tracker:)
      @colors = colors
      @tracker = tracker
    end

    def run
      Curses.cbreak      # no need for a newline to get type chars
      Curses.curs_set(0) # invisible
      Curses.noecho      # don't echo character on a getch

      Curses.start_color
      Curses.use_default_colors
      Curses.init_pair(COLOR_NAME, Curses::COLOR_GREEN, -1)
      Curses.init_pair(COLOR_TYPE, Curses::COLOR_BLUE, -1)
      Curses.init_pair(COLOR_EOF, Curses::COLOR_BLACK, Curses::COLOR_YELLOW)

      Curses.init_screen

      loop do
        paint
        sleep(2)
      end
    end

    private

    COLOR_NAME = 1
    COLOR_TYPE = 2
    COLOR_EOF = 3

    def color(key, &block)
      if @colors
        Curses.attron(Curses::color_pair(key) | Curses::A_NORMAL) { yield }
      else
        yield
      end
    end

    def paint
      Curses.clear

      n = -1
      @tracker.metrics.sort_by { |_, m| m.num_seen }.reverse.each do |name, metric|
        n += 1
        break if n >= Curses.lines

        Curses.setpos(n, 0)
        color(COLOR_NAME) { Curses.addstr(name) }

        Curses.setpos(n, 60)
        color(COLOR_TYPE) { Curses.addstr("(#{metric.type})") }

        Curses.setpos(n, 75)
        if metric.type == "count"
          Curses.addstr(metric.value.to_i.to_s)
        elsif metric.type == "measure"
          Curses.addstr(metric.value.round(1).to_s)
        elsif metric.type == "sample"
          Curses.addstr(metric.value.round(1).to_s)
        end

        Curses.setpos(n, 90)
        Curses.addstr(metric.unit || "")
      end

      if @tracker.eof
        Curses.setpos(Curses.lines - 1, Curses.cols - 5)
        color(COLOR_EOF) { Curses.addstr("[EOF]") }
      end

      Curses.refresh
    end
  end
end
