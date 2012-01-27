# -*- coding: utf-8 -*-

require "tzinfo"

class Fatechan::Plugin::Time
  include Cinch::Plugin
  set :reacting_on, :channel
  match /^(time|時刻|ちめ):?$/i

  def execute(m)
    zones = config["zones"] || %w{Asia/Tokyo}
    return if not m.command == "PRIVMSG"
    utc = Time.now.gmtime
    time = zones.map { |a|
      tz = TZInfo::Timezone.get(a)
      tz.utc_to_local(utc).strftime("%m/%d %H:%M (") +
      tz.period_for_utc(utc).abbreviation.to_s + ")"
    }.join ", "
    m.channel.notice "#{m.user.nick}: #{time}"
  end
end
