require 'open-uri'
require "nokogiri"
require 'pry'

# 
def search(base, html_file_name, url)
  open("./#{base}/#{html_file_name}", "wb") do |html|
    open(url) do |io|
      if io.content_type == "text/html"
        html.write(io.read)
      else
        puts("ERROR THE CONTENT TYPE IS #{io.content_type}.")
      end
    end
  end
end

# 
def get_apple_domain(url)
  # "https://www.apple.com/jp/"
  # ↓
  # "https://www.apple.com/"
  return url[0..-4]
end

# 
def get_site_links(url)
  hrefs = []
  links = []
  doc = Nokogiri::HTML(open(url))
  doc.css("a").each do |el|
    hrefs << el[:href]
  end
  doc.css("link").each do |el|
    links << el[:href]
  end
  return hrefs, links
end

def mkdir()
end

# 入力受付
print("URL: "); url = gets.chomp
url_length = url.length
html_file_name = "index.html"

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
base = File.basename(url)
begin
  Dir.mkdir(base)
rescue => e
  puts(e)
end

search(base, html_file_name, url)

urls =  get_site_links(url)
hrefs = urls[0]
links = urls[1]
# 取得で来たリンクのフォルダ内構成づくり
hrefs.each do |l|
  begin
    # jp配下のディレクトリ作成
    if l[0..3] == "/jp/"
      mkdir_name = l[1..-1]
      Dir.mkdir(mkdir_name)
      # index作成

      if mkdir_name[-1] == "/"
        open_link = "./#{mkdir_name}#{html_file_name}"
      else
        open_link = "./#{mkdir_name}/#{html_file_name}"
      end

      open("./#{mkdir_name}/#{html_file_name}", "wb") do |html|
        open(get_apple_domain(url)+mkdir_name) do |io|
          if io.content_type == "text/html"
            html.write(io.read)
          else
            puts("ERROR THE CONTENT TYPE IS #{io.content_type}.")
          end
        end
      end
    end
  rescue => e
    puts(e)
  end
end

# 0階層目のhrefのパスを置換
open("./#{base}/#{html_file_name}", "r") do |f|
  buffer = f.read
  buffer.gsub!(/href=\"/, 'href="'+url[0..url_length-5])
  open(html_file_name, "w") do |html|
    html.write(buffer)
  end
end

exec "open ./#{base}/#{html_file_name}"
