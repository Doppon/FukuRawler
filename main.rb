require 'open-uri'

# 入力受付
print("URL: "); url = gets.chomp


file_list = []
url_length = url.length
html_file_name = "scan.html"


# HTTPリクエストによって取得したbodyをローカルファイルに書き込み
open(url) { |file|
  file.each_line { |line| file_list << line }
}
File.open(html_file_name, "w") do |f|
  f.puts(file_list.join)
end


# CSSのパスを置換
f = File.open(html_file_name, "r")
buffer = f.read
buffer.gsub!(/href=\"/, 'href="'+url[0..url_length-5])
f = File.open(html_file_name, "w")
f.write(buffer)
f.close
