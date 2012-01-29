# -*- coding: utf-8 -*-

require "uri"
require "cgi"
require "stringio"
require "zlib"
require "open-uri"
require "openssl"
require "nokogiri"
require "kconv"
require "image_size"

class Fatechan::Plugin::GetURITitle
  include Cinch::Plugin
  listen_to :channel

  private

  def proc_fragment(uri)
    if uri.fragment =~ /^!(.*)/ then
      query = "_escaped_fragment_=" + CGI.escape($1)
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
    title = doc.xpath("//title").first
    title = title.text if title
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
      title.sub!(/[\0-\x1F\x7F].*/, "")
      title.gsub!(/\s{2,}/, " ")
      title.sub!(/(.{#{config[:max_title_length] || 50}}).*/m) { "#{$1}..." }
    end
    title
  end

  def get_uri_title(uri, options)
    begin
      fp = open(uri, "r:binary", options)
    rescue OpenURI::HTTPError => e
      return "Error: #{e.message}"
    end

    case fp.content_encoding.first
    when /^(?:x-)?gzip$/i
      content = Zlib::GzipReader.wrap(fp).read
    when /^(?:x-)?deflate$/i
      content = Zlib::Inflate.inflate(fp.read)
    else
      content = fp.read
    end

    case fp.content_type.downcase
    when "text/html"
      title = get_html_title(content)
    when "text/plain"
      title = get_text_title(content)
    when %r{image/}
      title = "#{f.content_type}; #{get_image_info(content)}"
    end

    normalize_title(title) || fp.content_type || "Untitled"
  end

  public

  def listen(m)
    return if not m.command == "PRIVMSG"
    URI.extract(m.message, %w{http https}) do |uri|
      uri = proc_fragment(URI(uri))

      options = {
        :ssl_verify_mode => OpenSSL::SSL::VERIFY_NONE,
      }.merge(config[:agent] || {})

      title = get_uri_title(uri, options)

      m.channel.notice "#{m.user.nick}: #{title}"
    end
  end
end
