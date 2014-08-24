require "spec_helper"
require "stringio"

require "hutils/text_visualizer"

describe Hutils::TextVisualizer do
  it "displays a tree" do
    root = Hutils::Node.new(nil, {})
    request_id = Hutils::Node.new(root, { request_id: "1a1" })
    root.slots << request_id
    user = Hutils::Node.new(request_id, { user: "jdoe@heroku.com" })
    authenticated = Hutils::Node.new(user, { authenticated: true })
    responded = Hutils::Node.new(user, { responded: true, elapsed: "0.01" })
    user.slots << authenticated << responded
    instrumentation = Hutils::Node.new(request_id, { instrumentation: true })
    request_id.slots << user << instrumentation

    assert_equal <<-eos, run_visualizer(root)
+ request_id: 1a1

	+ user: jdoe@heroku.com

		+ authenticated

		+ elapsed: 0.01
		  responded

	+ instrumentation

    eos
  end

  it "displays a tree in compact mode" do
    root = Hutils::Node.new(nil, {})
    request_id = Hutils::Node.new(root, { request_id: "1a1" })
    root.slots << request_id
    user = Hutils::Node.new(request_id, { user: "jdoe@heroku.com" })
    authenticated = Hutils::Node.new(user, { authenticated: true })
    responded = Hutils::Node.new(user, { responded: true, elapsed: "0.01" })
    user.slots << authenticated << responded
    instrumentation = Hutils::Node.new(request_id, { instrumentation: true })
    request_id.slots << user << instrumentation

    @compact = true
    assert_equal <<-eos, run_visualizer(root)
request_id: 1a1 
	user: jdoe@heroku.com 
		authenticated 
		elapsed: 0.01 responded 
	instrumentation 
    eos
  end

  def run_visualizer(node)
    io = StringIO.new
    Hutils::TextVisualizer.new(
      colors: false,
      compact: @compact,
      highlights: [],
      out: io,
      root: node
    ).display
    io.string
  end
end
