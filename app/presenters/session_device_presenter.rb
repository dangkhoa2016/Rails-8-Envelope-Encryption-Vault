class SessionDevicePresenter
  Device = Data.define(:browser, :operating_system, :category) do
    def label
      [ browser, operating_system ].compact.join(" on ")
    end
  end

  def self.for(user_agent)
    new(user_agent).device
  end

  def initialize(user_agent)
    @user_agent = user_agent.to_s
  end

  def device
    Device.new(
      browser: browser,
      operating_system: operating_system,
      category: category
    )
  end

  private

  attr_reader :user_agent

  def browser
    case user_agent
    when %r{Edg(?:e|A|iOS)?/}i then "Microsoft Edge"
    when %r{OPR/}i then "Opera"
    when %r{CriOS/}i then "Chrome"
    when %r{Chrome/}i then "Chrome"
    when %r{FxiOS/}i then "Firefox"
    when %r{Firefox/}i then "Firefox"
    when %r{Version/[\d.]+.*Safari/}i then "Safari"
    else "Unknown browser"
    end
  end

  def operating_system
    case user_agent
    when /Windows NT 10\.0/i then "Windows"
    when /Windows NT/i then "Windows"
    when /Android/i then "Android"
    when /(?:iPhone|iPad|iPod)/i then "iOS"
    when /Mac OS X/i then "macOS"
    when /CrOS/i then "ChromeOS"
    when /Linux/i then "Linux"
    else "Unknown OS"
    end
  end

  def category
    return "Tablet" if user_agent.match?(/iPad|Tablet/i)
    return "Mobile" if user_agent.match?(/Mobile|Android|iPhone|iPod/i)

    "Desktop"
  end
end
