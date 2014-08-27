require "json"

module Hutils::Ltap
  class PaperTrailDrainer
    PAPER_TRAIL_URL = "https://papertrailapp.com"

    def initialize(earliest:, key:, timeout:, query:, url:, verbose:)
      @api = Excon.new(PAPER_TRAIL_URL,
        headers: {
          "X-Papertrail-Token" => key
        })
      @earliest = earliest
      @query = query
      @timeout = timeout
      @verbose = verbose
    end

    def run
      messages = []
      min_id = nil
      start = Time.now

      loop do
        new_messages, reached_beginning, min_id, min_time = fetch_page(min_id)
        messages += new_messages

        # break if PaperTrail has indicated that we've reached the beginning of
        # our results
        if reached_beginning
          debug("breaking: reached beginning")
          break
        end

        # or if we've reached back before our earliest
        if min_time && min_time < @earliest
          debug("breaking: before earliest: #{@earliest}")
          break
        end

        # or if we've approximately hit our timeout
        if (Time.now - start).to_i > @timeout
          debug("breaking: reached timeout")
          break
        end
      end

      messages
    rescue RateLimited
      $stderr.puts "Papertrail rate limit reached"
      messages
    end

    def cancel_job
      debug("cancelled [noop]")
    end

    private

    class RateLimited < StandardError
    end

    def debug(str)
      if @verbose
        puts str
      end
    end

    def fetch_page(max_id)
      resp = @api.get(
        path: "/api/v1/events/search.json",
        expects: [200, 429],
        query: {
          max_id: max_id,
          q: @query
        }.reject { |k, v| v == nil })

      if resp.status == 429
        raise RateLimited
      end

      data = JSON.parse(resp.body)
      events = data["events"]
      debug("backend_timeout: #{data["backend_timeout"] || false} " +
        "min_id: #{data["min_id"]} " +
        "reached_beginning: #{data["reached_beginning"] || false}")

      [
        events.map { |e| e["message"].strip },
        data["reached_beginning"],
        data["min_id"],
        events.last ? Time.parse(events.last["received_at"]) : nil
      ]
    end
  end
end
