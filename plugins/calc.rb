# -*- coding: utf-8 -*-

require "google_calc"

class Fatechan::Plugin::Calc
  include Cinch::Plugin
  set :reacting_on, :channel
  match /^calc[\s:]\s*(.*)/

  def execute(m, expr)
    return if not m.command == "PRIVMSG"
    if result = GoogleCalc.calc(expr) then
      m.channel.notice "#{m.user.nick}: #{result}"
    else
      m.channel.notice "#{m.user.nick}: Error: Invalid expression."
    end
  end
end
