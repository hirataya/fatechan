# -*- coding: utf-8 -*-

require "tzinfo"

class Fatechan::Plugin::Time
  include Cinch::Plugin
  listen_to :channel

  def listen(m)
    zones = config["zones"] || %w{Asia/Tokyo}
    return if not m.command == "PRIVMSG"
    if m.message =~ /^(time|時刻|ちめ):?$/ then
      utc = Time.now.gmtime
      time = zones.map { |a|
        tz = TZInfo::Timezone.get(a)
        tz.utc_to_local(utc).strftime("%m/%d %H:%M (") +
        tz.period_for_utc(utc).abbreviation.to_s + ")"
      }.join ", "
      m.channel.notice "#{m.user.nick}: #{time}"
    end
  end
end
