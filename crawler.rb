require 'open-uri'
require "nokogiri"
require 'pry'

#
def init_apple_jp_root(url)
  base = url
  begin
    Dir.mkdir(base)
  rescue => e
    puts(e)
  end
end

# 
def get_apple_domain(url)
  File.dirname(url) # "https://www.apple.com/jp/" -> "https://www.apple.com"
end

#
def get_site_links(url)
  hrefs = [] # aタグ
  links = [] # linkタグ
  srcs = []  # javascriptのタグ

  doc = Nokogiri::HTML(open(url))

  doc.css("a").each do |el|
    hrefs << el[:href]
  end
  doc.css("link").each do |el|
    links << el[:href]
  end
  doc.css('script').each do |script|
    srcs << script.attribute("src")&.value
  end
  # nil が含まれている場合に要素を削除
  srcs.compact

  return hrefs + links + srcs
end

#
def loop_mkdir(mkdir_name, l)
  # 最初の / を切り取り | 基本的に "/" から始まってる
  mkdir_name = l[1..-1] if l[0] == "/"
  # 最後の / の切り取り( もし末尾に "/" が付いていた場合 )
  if mkdir_name[-1] == "/"
    mkdir_name = mkdir_name[0..-2]
    last_is_file = false
  else
    last_is_file = true
  end

  # jp/shop/goto/bag
  # ["jp", "shop", "goto", "bag"]
  dir_names = mkdir_name.split("/")

  if last_is_file
    # ["jp", "shop", "goto", "bag", "hoge.css"]
    # ["jp", "shop", "goto", "bag"]
    dir_names = dir_names[0..-2]
  end

  # 配列の個数が 2 以上のとき、すなわち階層が 2 階層以上だった場合
  if dir_names.length > 2
    1.upto(dir_names.length) do |i|
      dir_path = ""
      max_count = i

      i.times do |j|
        dir_path += dir_names[j]
        dir_path += "/" if j <= (max_count - 1)
      end

      # 例外処理をさせないとループから抜けてしまう
      begin
        Dir.mkdir(dir_path)
        # puts("INFO: CREATED - #{dir_path}")
      rescue => e
        if e.message.length >= 11 && e.message[0..10] == "File exists"
          next
        end
        puts(e)
      end
    end
  end

  mkdir_name
end

# 入力受付
print("URL: "); url = gets.chomp

# 定数宣言
url_length = url.length
html_file_name = "index.html"


# HTTP リクエストによって取得した body をローカルファイルに書き込み
base = File.basename(url) # "https://www.apple.com/jp/" -> "jp"
init_apple_jp_root(base)

open("./#{base}/#{html_file_name}", "wb") do |html|
  open(url) do |io|
    if io.content_type == "text/html"
      html.write(io.read)
    else
      puts("ERROR: THE CONTENT TYPE IS #{io.content_type}.")
    end
  end
end

hrefs = get_site_links(url)
# 取得で来たリンクのフォルダ内構成づくり
hrefs.each do |l|
  # 仮に何も要素が入ってなかった場合
  next unless l

  # TODO: もしかしたら変更するかも
  if l[0..7] == "https://"
    next
  end

  # パス "#" の対策
  if l == "#"
    # puts("INFO: SKIP PATH #")
    next
  end

  begin
    # ディレクトリの作成( 階層的 )
    mkdir_name = ""
    mkdir_name = loop_mkdir(mkdir_name, l)

    # ディレクトリの作成( 階層なし )
    if mkdir_name.empty?
      #
    elsif (/.css/ =~ l)
      # ディレクトリが生成されないように
    elsif (/.js/ =~ l)
      # ディレクトリが生成されないように
    else
      Dir.mkdir(mkdir_name)
    end
    # puts("INFO: CREATED - #{mkdir_name}")

    open(get_apple_domain(url) + "/" + mkdir_name) do |io|
      # index.html の作成
      if io.content_type == "text/html"
        open("./#{mkdir_name}/#{html_file_name}", "wb") do |html|
          html.write(io.read)
        end
      # css の作成
      elsif io.content_type == "text/css"
        open(".#{l}", "wb") do |css|
          css.write(io.read)
          puts("INFO: CREATED - CSS - #{l}")
        end
      # js の作成
      elsif io.content_type == "application/x-javascript"
        open(".#{l}", "wb") do |js|
          js.write(io.read)
          puts("INFO: CREATED - JavaScript - #{l}")
        end
      else
        puts("ERROR: THE CONTENT TYPE IS #{io.content_type}.")
      end
    end
  rescue => e
    if e.message.length >= 11 && e.message[0..10] == "File exists"
      next
    end

    if e.message.length >= 21 && e.message[0..20] == "redirection forbidden"
      msg = e.message.split(" -> ")
      redirect_link = msg.last
      # TODO: サーチさせにいく
      next
    end

    puts(e)
  end
end

# 0階層目のhrefのパスを置換
open("./#{base}/#{html_file_name}", "r") do |f|
  buffer = f.read
  buffer.gsub!(/href=\"/, 'href=".')
  # CSS のパスは root からになっているので root にするように( ./ -> ../ )
  buffer.gsub!(/href=\"[^\"]+.css\"/) { |s| "#{s[0..5]}.#{s[6..-1]}" }
  # jS  のパスは root からになっているので root にするように(  / -> ../ )
  buffer.gsub!(/src=\"[^\"]+.js\"/) { |s| "#{s[0..4]}..#{s[5..-1]}" }

  open("./#{base}/#{html_file_name}", "w") do |html|
    html.write(buffer)
  end
end

# TODO: クローリングの中で処理するように変更
open_file_path = "./v/home/d/built/styles/main.built.css"
open(open_file_path, "r") do |f|
  buffer = f.read
  ary = buffer.scan(/background-image:url\(\"[^\"]+\"/)

  ary.each do |a|
    # パスの指定
    # background-image:url("---" の中身が取得できる
    p = a[22..-2]


    # ディレクトリ作成
    mkdir_name = ""
    mkdir_name = loop_mkdir(mkdir_name, p)
    # ディレクトリの作成( 階層なし )
    if mkdir_name.empty?
      #
    elsif (/.css/ =~ p)
      # ディレクトリが生成されないように
    elsif (/.js/ =~ p)
      # ディレクトリが生成されないように
    elsif (/.png/ =~ p)
      # ディレクトリが生成されないように
    elsif (/.jpg/ =~ p)
      # ディレクトリが生成されないように
    elsif (/.jpeg/ =~ p)
      # ディレクトリが生成されないように
    else
      Dir.mkdir(mkdir_name)
    end
    # puts("INFO: CREATED - #{mkdir_name}")


    # リンク先の取得( 画像 )
    open(".#{p}", "wb") do |img|
      # 実際のコンテンツの中身取得
      open("https://www.apple.com" + p) do |io|
        img.puts(io.read)
        puts("INFO: CREATED - IMG - #{p}")
      end
    end
  end

  # TODO: 書き込みパスからの相対パスあぶり出し
  # openしてるパスから変換
  # openしてるパス: ./v/home/d/built/styles/main.built.css
  #
  # 
  # "./v/home/d/built/styles/main.built.css".split("/").count
  # => 7
  #
  # ../../../../../../v/home/d/built/images/mac-takeover/graph
  # 

  back_path = ""
  (open_file_path.split("/").count - 1).times { back_path += "../" }
  back_path = back_path[0..-2] # ..//v/home などを避けるため

  # TODO: /background-image:url\(\"[^\"]+\"/ の正規表現で柔軟な対応にする
  buffer.gsub!(/\/v\/home\/d/, "../..")

  open(open_file_path, "w") do |css|
    css.write(buffer)
  end
end
