require "json"

module Hutils::Ltap
  class PaperTrailDrainer
    PAPER_TRAIL_URL = "https://papertrailapp.com"

    def initialize(key:, timeout:, query:, url:, verbose:)
      @api = Excon.new(PAPER_TRAIL_URL,
        headers: {
          "X-Papertrail-Token" => key
        })
      @query = query
      @timeout = timeout
      @verbose = verbose
    end

    def run
      messages = []
      min_id = nil
      start = Time.now

      loop do
        new_messages, reached_beginning, min_id = fetch_page(min_id)
        messages += new_messages

        # break if PaperTrail has indicated that we've reached the beginning of
        # our results, or if we've approximately hit our timeout
        if reached_beginning || (Time.now - start).to_i > @timeout
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
      debug("backend_timeout: #{data["backend_timeout"] || false} " +
        "min_id: #{data["min_id"]} " +
        "reached_beginning: #{data["reached_beginning"] || false}")
      messages = data["events"].map { |e| e["message"].strip }
      [messages, data["reached_beginning"], data["min_id"]]
    end
  end
end
