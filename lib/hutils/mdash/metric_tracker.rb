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

    class MeasureMetric < Metric
      attr_accessor :samples_60s
      attr_accessor :samples_300s

      def initialize
        super(type: "measure")

        @samples_60s = SampleSet.new(60)
        @samples_300s = SampleSet.new(300)
      end

      def value=(v)
        @value = v
        @samples_60s.add(v)
        @samples_60s.prune
        @samples_300s.add(v)
        @samples_300s.prune
      end
    end

    class Sample
      attr_accessor :time
      attr_accessor :value

      def initialize(time, value)
        @time = time
        @value = value
      end
    end

    class SampleSet
      def initialize(window)
        @set = []
        @window = window
      end

      def add(value)
        @set << Sample.new(Time.now, value)
      end

      def p50
        values.sort[(@set.count.to_f * 0.50).to_i]
      end

      def p95
        values.sort[(@set.count.to_f * 0.95).to_i]
      end

      def p99
        values.sort[(@set.count.to_f * 0.99).to_i]
      end

      def prune
        bound = Time.now - @window
        # the internal array is inherently ordered
        while (s = @set[0]) && s.time < bound
          @set.shift
        end
      end

      private

      def values
        @set.map { |s| s.value }
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
      metric = @metrics[name] ||= MeasureMetric.new
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
