# -*- coding: utf-8 -*-

require "optparse"
require "yaml"
require "cinch"
require "util"
Encoding.default_internal = "utf-8"

class Fatechan
  VERSION = "0.1"
  NAME = "IRC bot Fate Testarossa (Fate-chan)"

  @@default_config = {
    nick: (1..8).to_a.map { ("a".."z").to_a.sample }.join(""),
    user: "fate",
    realname: "Fate Testarossa (Fate-chan)",
    server: "irc.freenode.net",
    port: 6667,
    encoding: "utf-8",
    channels: ["#FatechanMoe"],
  }

  private

  def expand(dir, files)
    return [] if not files
    dir = "./" + dir if not dir =~ /^\//
    result = []
    if files.kind_of?(Array) then
      files
    else
      [files]
    end.each do |inc|
      result += Dir.glob(dir + "/" + inc)
    end

    result
  end

  def load_plugins(pinfo)
    files =
      expand(pinfo["dir"], pinfo["include"]) -
      expand(pinfo["dir"], pinfo["exclude"])

    files.each do |file|
      require file
    end

    Util.get_classes.select { |c| c.include?(Cinch::Plugin) }
  end

  public

  def initialize
    config_file = "bot.yml"
    opt = OptionParser.new
    opt.on("-c FILE") do |file|
      config_file = file
    end
    opt.parse!

    @conf = YAML.load_file(config_file)

    plugin_classes = load_plugins(@conf["plugin"])
    $stderr.puts "Plugin(s): #{plugin_classes}"

    if not @bot = Cinch::Bot.new then
      $stderr.puts "Could not initialize Cinch::Bot"
      exit 1
    end

    @bot.config.plugins[:prefix] = nil
    @bot.loggers.level = (@conf["bot"]["log_level"] || :debug).to_sym

    @bot.configure do |bc|
      @@default_config.merge(@conf["irc"]).each_pair do |key, value|
        bc[key.to_sym] = value
      end

      bc.plugins.plugins = plugin_classes

      @conf["plugin"]["option"].each_pair do |key, value|
        if Util.get_classes.find { |c| c.to_s == key } then
          bc.plugins.options[eval key] = value
        end
      end
    end
  end

  def start
    @bot.start
  end

  module Plugin
  end
end
