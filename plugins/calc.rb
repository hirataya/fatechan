# -*- coding: utf-8 -*-

require "google_calc"

class Fatechan::Plugin::Calc
  include Cinch::Plugin
  listen_to :channel

  def listen(m)
    return if not m.command == "PRIVMSG"
    if m.message =~ /^calc[\s:]\s*(.*)/ then
      p $1
      if result = GoogleCalc.calc($1) then
        m.channel.notice "#{m.user.nick}: #{result}"
      else
        m.channel.notice "#{m.user.nick}: Error: Invalid expression."
      end
    end
  end
end
