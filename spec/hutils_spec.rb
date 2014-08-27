require "spec_helper"

describe Hutils::Parser do
  it "parses basic values" do
    res = run_parser("a=b")
    assert_equal({ "a" => "b" }, res[0])
  end

  it "parses multiple values" do
    res = run_parser("a=b c=d")
    assert_equal({ "a" => "b", "c" => "d" }, res[0])
  end

  it "parses multiple lines" do
    res = Hutils::Parser.new("a=b\r\nc=d").parse
    assert_equal([{ "a" => "b" }, { "c" => "d" }], res.map { |e| e[0]})
  end

  it "parses single quoted strings" do
    res = run_parser("a='b c'")
    assert_equal({ "a" => "b c" }, res[0])
  end

  it "parses double quoted strings" do
    res = run_parser(%{a="b c"})
    assert_equal({ "a" => "b c" }, res[0])
  end

  it "parses a complex string" do
    res = run_parser(%{a=b c='d e' f="g h" i=j})
    assert_equal({ "a" => "b", "c" => "d e", "f" => "g h", "i" => "j" }, res[0])
  end

  it "parses single terms" do
    res = run_parser("a=b c")
    assert_equal({ "a" => "b", "c" => true }, res[0])
  end

  it "strips a timestamp from the beginning of lines" do
    res = run_parser("2014-08-21T21:33:47.766994+00:00: a=b")
    assert_equal({ "a" => "b" }, res[0])
    assert_equal Time.parse("2014-08-21T21:33:47.766994+00:00"), res[1]
  end

  it "strips a timestamp and process from the beginning of lines" do
    res = run_parser("2014-08-21T21:30:02.929936+00:00 app[api-qcworker-1]: a=b")
    assert_equal({ "a" => "b" }, res[0])
    assert_equal Time.parse("2014-08-21T21:30:02.929936+00:00"), res[1]
  end

  def run_parser(str)
    # just return the first line
    Hutils::Parser.new(str).parse[0]
  end
end

describe Hutils::TreeBuilder do
  it "adds a simple child node" do
    node = run_tree_builder([
      { request_id: "1a1" }
    ])
    assert_tree({ common: {}, slots: [
      { common: { request_id: "1a1" }, slots: [] }
    ]}, node)
  end

  it "can split a node to group common attributes" do
    node = run_tree_builder([
      { request_id: "1a1", instrumentation: true },
      { request_id: "1a1", authentication: true }
    ])
    assert_tree({ common: {}, slots: [
      { common: { request_id: "1a1" }, slots: [
        { common: { instrumentation: true }, slots: [] },
        { common: { authentication: true }, slots: [] }
      ]}
    ]}, node)
  end

  it "can ascend a tree on a non-match" do
    node = run_tree_builder([
      { instrumentation: true },
      { authentication: true }
    ])
    assert_tree({ common: {}, slots: [
      { common: { instrumentation: true }, slots: [] },
      { common: { authentication: true }, slots: [] }
    ]}, node)
  end

  it "can handle a more complex trace" do
    node = run_tree_builder([
      { request_id: "1a1", instrumentation: true, at: "start" },
      { request_id: "1a1", rate_limit: true, limited: false },
      { request_id: "1a1", authenticated: true, user: "jdoe@heroku.com" },
      { request_id: "1a1", user: "jdoe@heroku.com", response: true },
      { request_id: "1a1", instrumentation: true, at: "finish" }
    ])
    assert_tree({ common: {}, slots: [
      { common: { request_id: "1a1" }, slots: [
        { common: { instrumentation: true, at: "start" }, slots: [] },
        { common: { limited: false, rate_limit: true }, slots: [] },
        { common: { user: "jdoe@heroku.com" }, slots: [
          { common: { authenticated: true }, slots: [] },
          { common: { response: true }, slots: [] }
        ] },
        { common: { instrumentation: true, at: "finish" }, slots: [] },
      ]}
    ]}, node)
  end

  def assert_tree(expected, node)
    assert_equal(expected[:common], node.common)
    expected[:slots].each_with_index do |child, i|
      assert_tree(child, node.slots[i])
    end
  end

  def run_tree_builder(lines)
    Hutils::TreeBuilder.new(lines).build
  end
end
