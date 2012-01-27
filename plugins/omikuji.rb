# -*- coding: utf-8 -*-

class Fatechan::Plugin::Omikuji
  include Cinch::Plugin
  set :reacting_on, :channel
  match /^(?:omikuji|おみくじ):?$/i

  @@kuji =
    ["大吉"] + ["中吉"]*2 + ["小吉"]*3 + ["吉"]*4 +
    ["末吉"]*3 + ["凶"]*2 + ["大凶"]

  def execute(m)
    return if not m.command == "PRIVMSG"

    time = Time.now
    kuji = @@kuji[(
      time.to_i +
      time.utc_offset +
      m.user.nick.unpack("C*").inject { |sum, x| sum + x }
    )%@@kuji.size]

    m.channel.notice "#{m.user.nick}: #{kuji}"
  end
end
