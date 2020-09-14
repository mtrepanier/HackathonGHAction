require 'active_support/core_ext/numeric' # from gem 'activesupport'

class Time
  # Time#round already exists with different meaning in Ruby 1.9
  def round_off(seconds = 60)
    Time.at((self.to_f / seconds).round * seconds).utc
  end

  def floor(seconds = 60)
    Time.at((self.to_f / seconds).floor * seconds).utc
  end
end