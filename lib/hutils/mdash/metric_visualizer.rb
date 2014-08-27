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
      Curses.init_pair(COLOR_HEADER, Curses::COLOR_YELLOW, -1)
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

    COLOR_HEADER = 1
    COLOR_NAME = 2
    COLOR_TYPE = 3
    COLOR_EOF = 4

    def color(key, &block)
      if @colors
        Curses.attron(Curses::color_pair(key) | Curses::A_NORMAL) { yield }
      else
        yield
      end
    end

    def paint
      Curses.clear

      Curses.setpos(0, 40)
      color(COLOR_HEADER) { Curses.addstr("type") }
      Curses.setpos(0, 45)
      color(COLOR_HEADER) { Curses.addstr("last") }
      Curses.setpos(0, 55)
      color(COLOR_HEADER) { Curses.addstr("unit") }
      Curses.setpos(0, 65)
      color(COLOR_HEADER) { Curses.addstr("p50 (5m)") }
      Curses.setpos(0, 75)
      color(COLOR_HEADER) { Curses.addstr("p95 (5m)") }
      Curses.setpos(0, 85)
      color(COLOR_HEADER) { Curses.addstr("p99 (5m)") }

      n = 0
      @tracker.metrics.sort_by { |_, m| m.num_seen }.reverse.each do |name, metric|
        n += 1
        break if n >= Curses.lines

        Curses.setpos(n, 0)
        color(COLOR_NAME) { Curses.addstr(name) }

        Curses.setpos(n, 40)
        color(COLOR_TYPE) { Curses.addstr(metric.type[0].upcase) }

        Curses.setpos(n, 45)
        if metric.type == "count"
          Curses.addstr(metric.value.to_i.to_s)
        elsif metric.type == "measure"
          Curses.addstr(metric.value.round(1).to_s)
        elsif metric.type == "sample"
          Curses.addstr(metric.value.round(1).to_s)
        end

        Curses.setpos(n, 55)
        Curses.addstr(metric.unit || "")

        if metric.type == "measure"
          Curses.setpos(n, 65)
          Curses.addstr(metric.samples_60s.p50.round(1).to_s)

          Curses.setpos(n, 75)
          Curses.addstr(metric.samples_60s.p95.round(1).to_s)

          Curses.setpos(n, 85)
          Curses.addstr(metric.samples_60s.p99.round(1).to_s)
        end
      end

      if @tracker.eof
        Curses.setpos(Curses.lines - 1, Curses.cols - 5)
        color(COLOR_EOF) { Curses.addstr("[EOF]") }
      end

      Curses.refresh
    end
  end
end
