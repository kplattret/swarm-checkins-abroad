require "httparty"
require "dotenv"

Dotenv.load(".env", "~/.env")

class Swarm
  CLIENT_ID = ENV["SWARM_CLIENT_ID"]
  CLIENT_SECRET = ENV["SWARM_CLIENT_SECRET"]
  ACCESS_TOKEN = ENV["SWARM_ACCESS_TOKEN"]
  HOME_COUNTRY = "GB"
  MAX_QUERY_LIMIT = 250

  class << self
    def list_checkins_abroad
      # total_count = api_request(limit: 1)[:checkins][:count]
      total_count = 500
      progression_count = 0
      offset = 0
      checkins_abroad = []
      formatted_checkins = []

      while progression_count < total_count
        checkins = api_request(offset: offset)[:checkins][:items]
        progression_count += checkins.count
        offset += MAX_QUERY_LIMIT
        checkins.reject! { |checkin| checkin[:venue][:location][:cc] == HOME_COUNTRY }
        checkins_abroad.push(*checkins)
      end

      checkins_abroad.each do |raw_checkin|
        checkin = serialised(raw_checkin)
        venue = [checkin[:venue], checkin[:city], checkin[:country]].compact.join(", ")
        item = [checkin[:time].strftime("%d/%m/%Y %H:%M"), venue].join(" – ")
        formatted_checkins << item
      end

      File.open("./checkins-abroad.md", 'w') { |f| f.write(formatted_checkins.join("\n"))  }
    end

    # private
    def serialised(checkin)
      {
        time: Time.at(checkin[:createdAt]).utc + (checkin[:timeZoneOffset] * 60),
        venue: checkin[:venue][:name],
        city: checkin[:venue][:location][:city],
        country: checkin[:venue][:location][:country]
      }
    end

    def api_request(limit: MAX_QUERY_LIMIT, offset: 0)
      base_url = "https://api.foursquare.com/v2/users/self/checkins"
      params = "?oauth_token=#{ACCESS_TOKEN}\
        &v=#{Time.now.utc.strftime("%Y%m%d")}\
        &sort=newestfirst\
        &limit=#{limit}\
        &offset=#{offset}"
      response = HTTParty.get(base_url + params, format: :plain)
      JSON.parse(response, symbolize_names: true)[:response]
    end

    private :api_request, :serialised
  end
end

Swarm.list_checkins_abroad
