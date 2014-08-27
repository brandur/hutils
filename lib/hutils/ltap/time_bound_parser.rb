module Hutils::Ltap
  # A parser designed to support the same style of relative time that Splunk
  # does, but note that absolute dates and "snap to" times are not supported.
  #
  # See here for more information on this format:
  #
  #      http://docs.splunk.com/Documentation/Splunk/6.1.3/SearchReference/SearchTimeModifiers
  class TimeBoundParser
    def parse(str, from: Time.now.getutc)
      if str =~ /^([+\-])([0-9]+)?([a-z]+)$/
        to_date($2 || 1, $3, from: from)
      else
        nil
      end
    end

    private

    def to_date(num, unit, from: from)
      unit_time = case unit
      when "s", "sec", "secs", "second", "seconds"
        1
      when "m", "min", "minute", "minutes"
        60
      when "h", "hr", "hrs", "hour", "hours"
        60 * 60
      when "d", "day", "days"
        60 * 60 * 24
      when "w", "week", "weeks"
        60 * 60 * 24 * 7
      when "mon", "month", "months"
        60 * 60 * 24 * 7 * 30
      when "q", "qtr", "qtrs", "quarter", "quarters"
        60 * 60 * 24 * 7 * 30 * 3
      when "y", "yr", "yrs", "year", "years"
        60 * 60 * 24 * 7 * 30 * 365
      end
      from - num.to_f * unit_time
    end
  end
end
