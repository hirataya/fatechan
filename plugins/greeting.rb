# -*- coding: utf-8 -*-

class Fatechan::Plugin::Greeting
  include Cinch::Plugin
  listen_to :join

  def initialize(*args)
    super
  end

  def listen(m)
    return if @done
    if m.user.nick == bot.nick then
      m.channel.notice(
        config["message"] ||
        "#{Fatechan::NAME} #{Fatechan::VERSION} <#{Fatechan::URL}>; " +
        "#{RUBY_DESCRIPTION}"
      )
    end
    @done = true
  end
end
