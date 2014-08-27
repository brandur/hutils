require "spec_helper"

describe Hutils::Ltap::TimeBoundParser do
  it "parses time bounds" do
    assert_equal (time - 60), parse("-1m")
    assert_equal (time - 60 * 60), parse("-1h")
  end

  it "parses time bounds without numbers" do
    assert_equal (time - 60), parse("-m")
  end

  it "returns nil for unparseable strings" do
    assert_equal nil, parse("gook")
  end

  def parse(str)
    Hutils::Ltap::TimeBoundParser.new.parse(str, from: time)
  end

  def time
    @time ||= Time.at(1409161226)
  end
end
