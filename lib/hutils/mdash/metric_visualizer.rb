require "curses"

module Hutils::Mdash
  class MetricVisualizer
    def initialize(tracker:)
      @tracker = tracker
    end

    def run
      Curses.cbreak      # no need for a newline to get type chars
      Curses.curs_set(0) # invisible
      Curses.noecho      # don't echo character on a getch

      Curses.start_color
      Curses.use_default_colors

      Curses.init_screen

      loop do
        paint
        sleep(2)
      end
    end

    private

    def paint
      Curses.clear

      n = -1
      @tracker.metrics.sort_by { |_, m| m.num_seen }.reverse.each do |name, metric|
        n += 1
        break if n >= Curses.lines

        Curses.setpos(n, 0)
        Curses.addstr(name)
        Curses.addstr("\t")
        Curses.addstr("(#{metric.type})")
        Curses.addstr("\t")
        Curses.addstr(metric.value.to_s)
      end

      Curses.refresh
    end
  end
end
