# -*- coding: utf-8 -*-

require "uri"
require "open-uri"
require "nokogiri"
require "kconv"
require "image_size"

class Fatechan::Plugin::GetURITitle
  include Cinch::Plugin
  listen_to :channel

  private

  def proc_fragment(uri)
    if uri.fragment =~ /^!(.*)/ then
      query = "_escaped_fragment_=" + URI.escape($1)
      if uri.query then
        uri.query += "&" + query
      else
        uri.query = query
      end
    end
    uri.fragment = nil
    uri
  end

  def get_html_title(content)
    doc = Nokogiri::HTML(content)

    # XXX: Should use lower-case function if XPath 2.0 is available.
    html_content_type = doc.xpath(%{
      //meta[
        translate(
          @http-equiv,
          'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
          'abcdefghijklmnopqrstuvwxyz'
        ) = 'content-type'
      ][1]
    })

    if html_content_type =~ /charset=([\w_-]+)/ then
      encoding = $1
    else
      encoding = Kconv.guess(content)
    end

    content.
      force_encoding(encoding).
      encode(invalid: :replace, undef: :replace)

    doc = Nokogiri::HTML(content)
    title = doc.xpath("//title").first.text
    title = nil if title =~ /^\s*$/
    title
  end

  def get_text_title(content)
    title = content
    title.
      force_encoding(Kconv.guess(title)).
      encode(invalid: :replace, undef: :replace)
    title
  end

  def get_image_info(content)
    size = ImageSize.new(content)
    "size=#{size.width}x#{size.height}"
  end

  def normalize_title(title)
    if title then
      title.strip!
      title.sub!(/[\0-\x1F\x7E].*/, "")
      title.gsub!(/\s{2,}/, " ")
      title.sub!(/(.{50}).*/m) { "#{$1}..." }
    end
    title
  end

  public

  def listen(m)
    return if not m.command == "PRIVMSG"
    URI.extract(m.message, %w{http https}) do |uri|
      uri = proc_fragment(URI(uri))

      open(uri, "r:binary") do |f|
        title = nil
        content = f.read

        if f.content_type == "text/html" then
          title = get_html_title(content)
        elsif f.content_type == "text/plain" then
          title = get_text_title(content)
        elsif f.content_type =~ %r{image/} then
          tutle = "#{f.content_type}; #{get_image_info(content)}"
        end

        title = normalize_title(title) || f.content_type || "Untitled"

        m.channel.notice "#{m.user.nick}: #{title}"
      end
    end
  end
end