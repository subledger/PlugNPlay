require 'net/http'
require 'json'

module PlugNPlay
  class Client
    def initialize(uri, user, password, timeout = 60)
      @pnp_uri = uri
      @pnp_user = user
      @pnp_password = password
      @pnp_timeout = timeout
    end

    def post(endpoint, event, data)
      uri = URI(endpoint)
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = @pnp_timeout

      req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
      req.basic_auth(@pnp_user, @pnp_password)
      req.body = {
        "name" => event,
        "data" => data
      }.to_json

      res = http.request(req)
      JSON.parse(res.body, { symbolize_names: true })
    end

    def trigger(event, data = {})
      self.post("#{@pnp_uri}/api/1/event/trigger", event, data)
    end

    def read(event, data = {})
      self.post("#{@pnp_uri}/api/1/event/read", event, data)
    end

    def method_missing(method, *args)
      if method.to_s.start_with? "payout_"
        args[0][:account_role] = method[7..-1]
        self.trigger("payout", args[0])

      elsif method.to_s.start_with? "get_"
        self.read(method.to_s[4..-1], args[0])

      else not ["post"].include? method.to_s
        self.trigger(method, args[0])
      end
    end
  end
end
