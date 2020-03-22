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
        puts("ERROR: THE CONTENT TYPE IS #{io.content_type}.")
      end
    end
  end
end

# 
def get_apple_domain(url)
  # "https://www.apple.com/jp/"
  # ↓
  # "https://www.apple.com"
  File.dirname(url)
end

# 指定された URL のサイト内にあるリンクを全てここで一時的に [hrefs, links] に渡している
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

# 入力受付
print("URL: "); url = gets.chomp

# 定数宣言
url_length = url.length
html_file_name = "index.html"


# HTTP リクエストによって取得した body をローカルファイルに書き込み
# File.basename(url)
# => "jp"
base = File.basename(url)
begin
  Dir.mkdir(base)
rescue => e
  puts(e)
end

search(base, html_file_name, url)

hrefs, links = get_site_links(url)
# 取得で来たリンクのフォルダ内構成づくり
hrefs.each do |l|
  # パス "#" の対策
  if l == "#"
    puts("INFO: SKIP PATH #")
    next
  end

  begin
    # jp配下のディレクトリ作成
    if l[0..3] == "/jp/"
      # 最初の / を切り取り
      mkdir_name = l[1..-1]

      # 最後の / の切り取り( もし末尾に "/" が付いていた場合 )
      mkdir_name = mkdir_name[0..-2] if mkdir_name[-1] == "/"

      # jp/shop/goto/bag
      # ["jp", "shop", "goto", "bag"]
      dir_names = mkdir_name.split("/")
      # 配列の個数が 2 以上のとき、すなわち階層が 2 階層以上だった場合
      if dir_names.length > 2
        dir_names.length.times do |i|
          dir_path = ""
          max_count = i

          i.times do |j|
            dir_path += dir_names[j]
            dir_path += "/" if j <= (max_count - 1)
          end

          # 例外処理をさせないとループから抜けてしまう
          begin
            Dir.mkdir(dir_path)
            puts("INFO: CREATED - #{dir_path}")
          rescue => e
            if e.message.length >= 11 && e.message[0..10] == "File exists"
              next
            end
            puts(e)
          end
        end
      end

      Dir.mkdir(mkdir_name)
      puts("INFO: CREATED - #{mkdir_name}")

      # index作成

      open("./#{mkdir_name}/#{html_file_name}", "wb") do |html|
        open(get_apple_domain(url) + "/" + mkdir_name) do |io|
          if io.content_type == "text/html"
            html.write(io.read)
          else
            puts("ERROR: THE CONTENT TYPE IS #{io.content_type}.")
          end
        end
      end
    end
  rescue => e
    if e.message.length >= 11 && e.message[0..10] == "File exists"
      next
    end
    puts(e)
  end
end

# 0階層目のhrefのパスを置換
open("./#{base}/#{html_file_name}", "r") do |f|
  buffer = f.read
  buffer.gsub!(/href=\"/, 'href="' + url[0..url_length-5])
  open("./#{base}/#{html_file_name}", "w") do |html|
    html.write(buffer)
  end
end

# 最初のページにあたる ./jp/index.html のオープン
# exec "open ./#{base}/#{html_file_name}"
