module Hutils::Ltap
  class TimeBoundParser
    def parse(str, from: Time.now.getutc)
      if str =~ /^([+\-])([0-9]?)([a-z]+)$/
        to_date($2.empty? ? 1 : $2, $3, from: from)
      else
        nil
      end
    end

    private

    def to_date(num, unit, from: from)
      unit_time = case unit
      when "s"
        1
      when "m"
        60
      when "h"
        60 * 60
      when "d"
        60 * 60 * 24
      when "w"
        60 * 60 * 24 * 7
      when "mon"
        60 * 60 * 24 * 7 * 30
      when "q"
        60 * 60 * 24 * 7 * 30 * 3
      when "y"
        60 * 60 * 24 * 7 * 30 * 365
      end
      from - num.to_f * unit_time
    end
  end
end
