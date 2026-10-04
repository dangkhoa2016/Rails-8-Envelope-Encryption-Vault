class RateLimitBoundary
  def initialize(app)
    @rack_attack = Rack::Attack.new(app)
  end

  def call(env)
    @rack_attack.call(env)
  end
end
