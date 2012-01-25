# -*- coding: utf-8 -*-

class Fatechan::Plugin::Omikuji
  include Cinch::Plugin
  listen_to :channel

  @@kuji =
    ["大吉"] + ["中吉"]*2 + ["小吉"]*3 + ["吉"]*4 +
    ["末吉"]*3 + ["凶"]*2 + ["大凶"]

  def listen(m)
    return if not m.command == "PRIVMSG"
    return if not m.message =~ /^(?:omikuji|おみくじ):?$/i
    m.channel.notice "#{m.user.nick}: #{@@kuji.sample}"
  end
end
