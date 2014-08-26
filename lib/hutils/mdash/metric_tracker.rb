module Hutils::Mdash
  class MetricTracker
    class Metric
      attr_accessor :num_seen
      attr_accessor :type
      attr_accessor :unit
      attr_accessor :value

      def initialize(type: type)
        @num_seen = 0
        @type = type
        @value = 0
      end
    end

    attr_accessor :eof
    attr_accessor :metrics

    def initialize
      @metrics = {}
    end

    def process(message)
      message.each do |k, v|
        if k =~ /^count#/
          name, value, _ = parse(k, v)
          count(name, value)
        elsif k =~ /^measure#/
          name, value, unit = parse(k, v)
          measure(name, value, unit)
        elsif k =~ /^sample#/
          name, value, unit = parse(k, v)
          sample(name, value, unit)
        end
      end
    end

    private

    def count(name, value)
      metric = @metrics[name] ||= Metric.new(type: "count")
      metric.num_seen += 1
      metric.value += value.to_i
    end

    def measure(name, value, unit)
      metric = @metrics[name] ||= Metric.new(type: "measure")
      metric.num_seen += 1
      metric.unit = unit
      metric.value = value.to_f
    end

    def parse(k, v)
      _, name = k.split("#")
      if v =~ /([0-9.]+)(.*)/
        [name, $1, $2]
      else
        [name, 1, nil]
      end
    end

    def sample(name, value, unit)
      metric = @metrics[name] ||= Metric.new(type: "sample")
      metric.num_seen += 1
      metric.unit = unit
      metric.value = value.to_f
    end
  end
end
