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

    def trigger(event, data = {})
      uri = URI("#{@pnp_uri}/api/1/event/trigger")
      http = Net::HTTP.new(uri.host, uri.port)
      http.read_timeout = @pnp_timeout
      
      req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
      req.basic_auth(@pnp_user, @pnp_password)
      req.body = {
        "name" => event,
        "data" => data
      }.to_json
      
      res = http.request(req)
      JSON.parse(res.body)
    end

    def method_missing(method, *args)
      self.trigger(method, args[0])
    end
  end
end
