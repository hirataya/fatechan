# -*- coding: utf-8 -*-

class Fatechan::Plugin::Greeting
  include Cinch::Plugin
  listen_to :join

  def listen(m)
    return if @done
    if m.user == bot then
      m.channel.notice(
        config["message"] ||
        "#{Fatechan::NAME}, Version #{Fatechan::VERSION} <#{Fatechan::URL}>; " +
        "#{RUBY_DESCRIPTION}"
      )
    end
    @done = true
  end
end
