require "uri"
require "cgi"
require "open-uri"
require "nokogiri"

module GoogleCalc
  def self.calc(expr, &block)
    uri = sprintf("http://www.google.com/search?hl=ja&q=%s", CGI.escape(expr))
    #p uri

    result = nil
    open(uri, "r:utf-8", "User-Agent" => "Mozilla/5.0") do |fp|
      content = fp.read
      #p content
      doc = Nokogiri::HTML(content)
      result = doc.xpath("//h2[@class='r']").first
    end

    return nil if not result

    #result = result.text
    result = result.inner_html
    result.gsub!(%r{<sup>(.*?)</sup>}) { "^#{$1}" }
    result.gsub!(%r{<font size="-2"> </font>}, "")
    result.strip!
    result.gsub!(/\s{2,}/, " ")

    block.call(result) if block
    result
  end
end
