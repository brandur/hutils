module Hutils
  class NodeNavigator
    def next_node(node, ignore_expanded: false)
      # if expanded and we have children, move onto the first
      if !ignore_expanded && node.tags[:expanded] && node.slots.count > 0
        return node.slots[0]
      end

      index = node.parent.slots.index(node)

      # Otherwise, if the node is the last in its slot, then move to the
      # parent's next slot. If the parent is root, then we can go no further.
      if index == node.parent.slots.count - 1
        if node.parent.parent != nil
          new_node = next_node(node.parent, ignore_expanded: true)
          # if the sub-iteration couldn't find a next node, stay where we are
          new_node != node.parent ? new_node : node
        else
          node
        end
      # otherwise, just move to the next slot
      else
        node.parent.slots[index + 1]
      end
    end

    def prev_node(node)
      index = node.parent.slots.index(node)

      if index == 0
        if node.parent.parent != nil
          node.parent
        else
          # don't ever move up to root
          return node
        end
      # otherwise, move to the previous node in the list
      else
        new_node = node.parent.slots[index - 1]

        # But wait! We don't just want to move to the previous node directly, we
        # actually want to move to the last child of its deepest expanded
        # subnode.
        while new_node.tags[:expanded] && new_node.slots.count > 0
          new_node = new_node.slots.last
        end

        new_node
      end
    end
  end
end
