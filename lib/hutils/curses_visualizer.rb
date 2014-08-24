require "curses"

module Hutils
  class CursesVisualizer
    def initialize(colors:, compact:, highlights:, root:)
      @colors = colors
      @highlights = highlights
      @line_buffer = []
      @root = root
    end

    def run
      Curses.cbreak      # no need for a newline to get type chars
      Curses.curs_set(0) # invisible
      Curses.noecho      # don't echo character on a getch

      Curses.start_color
      Curses.use_default_colors

      Curses.init_pair(COLOR_KEY, -1, Curses::COLOR_BLUE)
      Curses.init_pair(COLOR_HIGHLIGHT, Curses::COLOR_BLACK, Curses::COLOR_YELLOW)

      Curses.init_screen

      trap("SIGINT", "SIGTERM") do
        Curses.close_screen
        # @todo: curses shutdown?
        $stdout.puts "Caught deadly signal"
        $stdout.flush
        exit(0)
      end

      # set root node as "expanded"
      @root.tags[:expanded] = true

      @need_repaint = true
      @selected_line = 0
      build_line_buffer

      loop do
        if @need_repaint
          build_line_buffer
          paint
          @need_repaint = false
        end
        handle_key
      end
    end

    private

    COLOR_KEY = 1
    COLOR_HIGHLIGHT = 2

    def build_line_buffer
      @line_buffer = []

      traverse_tree(@root) do |node|
        @line_buffer << node
      end

      # remove the root node; it's not actually displayed
      @line_buffer.shift

      if @selected_line >= @line_buffer.count
        @selected_line = @line_buffer.count - 1
      end
    end

    def traverse_tree(node, &block)
      yield node
      if node.tags[:expanded]
        node.slots.each { |child| traverse_tree(child, &block) }
      end
    end

    def collapse_all
      collapse_node(@root)
    end

    def collapse_node(node)
      node.tags[:expanded] = false if node != @root
      node.slots.each { |child| collapse_node(child) }
    end

    def expand_all(node = @root)
      node.tags[:expanded] = true if node != @root
      node.slots.each { |child| expand_all(child) }
    end

    def toggle_node
      if node = @line_buffer[@selected_line]
        node.tags[:expanded] = !node.tags[:expanded]
      end
    end

    def expanded_str(node)
      if node.slots.count > 0
        node.tags[:expanded] ? "[-]" : "[+]"
      else
        "   "
      end
    end

    def handle_key
      case Curses.getch
      when Curses::KEY_RESIZE then need_repaint
      when ' ' then toggle_node && need_repaint
      when ?c then collapse_all && need_repaint
      when ?e then expand_all && need_repaint
      when ?j then move_next
      when ?k then move_prev
      when ?o then toggle_node && need_repaint
      when ?q then exit(0)
      end
    end

    def move_next
      old_selected_line = @selected_line

      @selected_line += 1
      if @selected_line == @line_buffer.count
        @selected_line = @line_buffer.count - 1
      end

      paint_line(old_selected_line)
      paint_line(@selected_line)
    end

    def move_prev
      old_selected_line = @selected_line

      @selected_line -= 1
      if @selected_line < 0
        @selected_line = 0
      end

      paint_line(old_selected_line)
      paint_line(@selected_line)
    end

    def need_repaint
      @need_repaint = true
    end

    def paint
      Curses.clear

      @line_buffer.each_with_index do |node, line|
        break if line > Curses.lines
        paint_node(node, line)
      end

      Curses.refresh
    end

    def paint_line(line)
      paint_node(@line_buffer[line], line)
    end

    def safe_addstr(str, num_cols_written)
      if num_cols_written + str.length > Curses.cols
        left = Curses.cols - num_cols_written
        str = str.dup[0, left]
      end
      Curses.addstr(str)
      num_cols_written + str.length
    end

    # `line` should already be incremented to the correct position before
    # entering this method
    def paint_node(node, line)
      n = 0
      Curses.setpos(line, 0)

      if @selected_line == line
        Curses.attron(Curses::A_UNDERLINE)
      end

      n = safe_addstr("\t" * (node.depth - 1), n)
      n = safe_addstr(expanded_str(node) + " ", n)
      node.common.to_a.sort_by { |k, v| k }.each do |k, v|
        if v == true
          color(COLOR_KEY) { n = safe_addstr("#{k}", n) }
        else
          if @highlights.include?(k)
            color(COLOR_HIGHLIGHT) { n = safe_addstr("#{k}=#{v}", n) }
          else
            color(COLOR_KEY) { n = safe_addstr("#{k}", n) }
            n = safe_addstr("=#{v}", n)
          end
        end
        n = safe_addstr(" ", n)
      end

      Curses.attroff(Curses::A_UNDERLINE)
    end

    def color(key, &block)
      if @colors
        Curses.attron(Curses::color_pair(key) | Curses::A_NORMAL) { yield }
      else
        yield
      end
    end
  end
end
