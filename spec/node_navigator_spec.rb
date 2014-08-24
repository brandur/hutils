require "spec_helper"

require "hutils/node_navigator"

describe Hutils::NodeNavigator do
  before do
    @root = Hutils::Node.new(nil, {})
  end

  it "traverses next to the next slot" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    assert_equal n1, run_next(n0)
  end

  it "traverses next to a child slot on an expanded node" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    n0_0 = n(n0, :n0_0)
    n0.slots << n0_0

    n0.tags[:expanded] = true

    assert_equal n0_0, run_next(n0)
  end

  it "doesn't traverse next to a child slot on a collapsed node" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    n0_0 = n(n0, :n0_0)
    n0.slots << n0_0

    n0.tags[:expanded] = false

    assert_equal n1, run_next(n0)
  end

  it "traverses from a child slot up to a sibling of its parent" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    n0_0 = n(n0, :n0_0)
    n0.slots << n0_0

    n0.tags[:expanded] = true

    assert_equal n1, run_next(n0_0)
  end

  it "doesn't traverse next up to root" do
    n0 = n(@root, :n0)
    @root.slots << n0

    assert_equal n0, run_next(n0)
  end

  it "traverses prev to the prev slot" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    assert_equal n0, run_prev(n1)
  end

  it "traverses prev up to a parent node" do
    n0 = n(@root, :n0)
    @root.slots << n0

    n0_0 = n(n0, :n0_0)
    n0.slots << n0_0

    assert_equal n0, run_prev(n0_0)
  end

  it "traverses prev to an expanded subnode" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    n0_0 = n(n0, :n0_0)
    n0.slots << n0_0

    n0.tags[:expanded] = true

    assert_equal n0_0, run_prev(n1)
  end

  it "doesn't traverse prev to a collapsed subnode" do
    n0 = n(@root, :n0)
    n1 = n(@root, :n1)
    @root.slots << n0 << n1

    n0_0 = n(n0, :n0_0)
    n0.slots << n0_0

    n0.tags[:expanded] = false

    assert_equal n0, run_prev(n1)
  end

  it "doesn't traverse prev up to root" do
    n0 = n(@root, :n0)
    @root.slots << n0

    assert_equal n0, run_prev(n0)
  end

  def n(parent, name)
    # we "name" the nodes to give us an easier debugging these tests
    Hutils::Node.new(parent, { name => true })
  end

  def run_next(node)
    Hutils::NodeNavigator.new.next_node(node)
  end

  def run_prev(node)
    Hutils::NodeNavigator.new.prev_node(node)
  end
end
