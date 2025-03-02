class Rack::Attack
  throttle("logins/create", limit: 5, period: 15.minutes) do |request|
    request.ip if request.path == "/logins" && request.post?
  end
end
