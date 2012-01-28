# -*- coding: utf-8 -*-

require "optparse"
require "pp"
require "yaml"
require "cinch"
require "util"
Encoding.default_internal = "utf-8"

class Fatechan
  VERSION = "0.1"
  NAME = "IRC bot Fate Testarossa (Fate-chan)"
  URL = "https://github.com/hirataya/fatechan"

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
      expand(pinfo[:dir], pinfo[:include]) -
      expand(pinfo[:dir], pinfo[:exclude])

    files.each do |file|
      require file
    end

    Util.get_classes.select { |c| c.include?(Cinch::Plugin) }
  end

  def make_hash_keys_symbol(data)
    if data.is_a?(Hash) then
      newhash = {}
      data.each_pair do |key, value|
        if key.is_a?(String) and key =~ /^\+(.*)/ then
          newhash[$1] = make_hash_keys_symbol(value)
        else
          newhash[key.to_sym] = make_hash_keys_symbol(value)
        end
      end
      data = newhash
    elsif data.is_a?(Array) then
      data.each_with_index do |value, index|
        data[index] = make_hash_keys_symbol(value)
      end
    end
    data
  end

  public

  def initialize
    config_file = "bot.yml"
    opt = OptionParser.new
    opt.on("-c FILE") do |file|
      config_file = file
    end
    opt.parse!

    @conf = make_hash_keys_symbol(YAML.load_file(config_file))

    if not @bot = Cinch::Bot.new then
      $stderr.puts "Could not initialize Cinch::Bot"
      exit 1
    end

    @bot.loggers.level = (@conf[:bot][:log_level] || :debug).to_sym

    plugin_classes = load_plugins(@conf[:plugin])
    @bot.loggers.info "Plugin(s) loaded: #{plugin_classes}"
    @bot.config.plugins[:prefix] = nil

    @bot.configure do |bc|
      @@default_config.merge(@conf[:irc]).each_pair do |key, value|
        bc[key] = value
      end

      bc.plugins.plugins = plugin_classes

      @conf[:plugin][:option].each_pair do |key, value|
        if Util.get_classes.find { |c| c.to_s == key.to_s } then
          bc.plugins.options[eval key.to_s] = value
          @bot.loggers.debug "Config(#{key}) = #{value.pretty_inspect}"
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
