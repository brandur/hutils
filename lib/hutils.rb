require_relative "hutils/stripper"
require_relative "hutils/text_visualizer"

module Hutils
  class Node
    def initialize(parent, common)
      @common = common
      @parent = parent
      @slots = []
      @tags = {}
    end

    # The set of common attributes that are shared by all slots in this branch of
    # the tree.
    attr_accessor :common

    # Parent node.
    attr_accessor :parent

    # Ordered child nodes of this node.
    attr_accessor :slots

    # Arbitrary tags that applications can associate on a node.
    attr_accessor :tags

    # The set of common attributes that are shared by all slots in this branch of
    # the tree, but accounting for all parent nodes as well.
    def common_complete
      @common.merge(@parent ? @parent.common_complete : {})
    end

    def depth
      @parent ? @parent.depth + 1 : 0
    end

    def print
      indent = "  " * depth
      $stdout.puts "#{indent}[ #{depth} ]#{@common}"
      slots.each { |node| node.print }
    end

    def replace_slot(old, new)
      @slots.each_with_index do |node, i|
        if old == node
          @slots[i] = new
          return
        end
      end
      abort("bad replace")
    end

    def root
      @parent ? @parent.root : self
    end

    def root?
      @parent == nil
    end
  end

  class Parser
    def initialize(str)
      @str = str
    end

    def parse
      lines = @str.split("\n").map { |line| normalize(line) }
      lines.map! do |line|
        pairs = line.scan(/(?:['"](?:\\.|[^'"])*['"]|[^'" ])+/).map do |pair|
          key, value = pair.split("=")
          [key, value].each do |str|
            str.gsub!(/^['"]?(.*?)['"]?$/, '\1') if str
          end
          [key, value || true]
        end
        Hash[pairs]
      end
    end

    private

    def normalize(line)
      line = line.strip
      line.gsub(/^[T0-9\-:+.]+( [a-z]+\[[a-z0-9\-_.]+\])?: /, '')
    end
  end

  class TreeBuilder
    def initialize(lines)
      @lines = lines
    end

    def build
      root = Node.new(nil, {})
      node = root
      @lines.each do |pairs|
        node = build_node(node, pairs)
      end
      root
    end

    private

    def diff(hash1, hash2)
      same = hash1.dup.delete_if { |k, v| hash2[k] != v }

      extra1 = hash1.dup
      same.each { |k, _| extra1.delete(k) }

      extra2 = hash2.dup
      same.each { |k, _| extra2.delete(k) }

      [same, extra1, extra2]
    end

    def debug(title, data, node)
      return unless ENV["DEBUG"] == "true"
      puts "---"
      puts title
      data.each { |k, v| puts "#{k}: #{v}" }
      node.root.print if node
      puts ""
    end

    def build_node(node, pairs)
      complete = node.common_complete
      same, complete_extra, pairs_extra = diff(complete, pairs)

      if complete == same
        if pairs_extra.empty?
          # we've hit a rare case of a line which is a duplicate of its immediate
          # successor: do nothing
        else
          # all common is shared but we have extra: add a new child node
          new = Node.new(node, pairs_extra)
          node.slots << new
          node = new
          debug("simple leaf addition", { pairs_extra: pairs_extra }, node)
        end
      else
        # First of all, determine whether our node has any data in common with
        # the current node.
        local_same, _, _ = diff(node.common, pairs)

        # Then figure out that given a split, what the old node's new set would
        # look like in the context of a shared common parent.
        _, other_extra, _ = diff(node.common, local_same)

        # And finally, determine whether the parent hierarchy contains any data
        # that is incompatible with our new node because it's not shared.
        _, illegal_extra, _ = diff(complete_extra, other_extra)

        if !local_same.empty? && illegal_extra.empty?
          # create a replacement node and swap it into place
          new_parent = Node.new(node.parent, local_same)
          node.common = other_extra
          node.parent = new_parent
          new_parent.slots << node
          new_parent.parent.replace_slot(node, new_parent)

          new = Node.new(new_parent, pairs_extra)
          new_parent.slots << new
          node = new
          debug("split", { pairs_extra: pairs_extra }, node)
        else
          debug("before tree ascention", { pairs: pairs }, nil)
          # Nothing is shared, ascend the tree until something is. Eventually
          # something will be because the root node contains an empty hash of common
          # attributes.
          node = build_node(node.parent, pairs)
          debug("after tree ascention", { pairs: pairs }, nil)
        end
      end

      node
    end
  end
end
