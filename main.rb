require 'open-uri'
require 'pry'

def search(base, html_file_name, url)
  open("./#{base}/#{html_file_name}", "wb") do |html|
    open(url) do |io|
      # print(io.content_type)
      # => text/html
      html.write(io.read)
    end
  end
end

# 入力受付
print("URL: "); url = gets.chomp
url_length = url.length

# File.dirname(url)
# => "https://www.apple.com"
#
# File.basename(url)
# => "jp"
#
# File.path(url)
# => "https://www.apple.com/jp/"
#

# HTTPリクエストによって取得したbodyをローカルファイルに書き込み
fileName = File.basename(url)

html_file_name = "index.html"
open(html_file_name, "wb") do |html|
  open(url) do |io|
    print(io.content_type)
    # => text/html
    html.write(io.read)
  end
end

# CSSのパスを置換
open(html_file_name, "r") do |f|
  buffer = f.read
  buffer.gsub!(/href=\"/, 'href="'+url[0..url_length-5])
  open(html_file_name, "w") do |html|
    html.write(buffer)
  end
end

exec "open #{html_file_name}"
