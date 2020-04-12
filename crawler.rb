require "open-uri"
require "nokogiri"
require "pry"
require "fileutils"

class Crawler
  #
  def init_apple_jp_root(url, html_file_name)
    base = File.basename(url) # "https://www.apple.com/jp/" -> "jp"

    is_dir_exist = Dir.exist?(base)
    if !is_dir_exist
      # /jp ディレクトリの作成
      FileUtils.mkdir(base)
      puts("INFO: CREATED - DIR - .#{base}")
    else
      puts("INFO: SKIP    - DIR - .#{base}")
    end

    is_html_exist = File.exist?("./#{base}/#{html_file_name}")
    if !is_html_exist
      # /jp/index.html の作成
      open("./#{base}/#{html_file_name}", "wb") do |html|
        open(url) do |io|
          if io.content_type == "text/html"
            html.write(io.read)
          else
            puts("ERROR: THE CONTENT TYPE IS #{io.content_type}.")
          end
        end
      end
    else
      puts("INFO: SKIP    - HTML - ./#{base}/#{html_file_name}")
    end
  end

  #
  def replace_root_file_path(base, html_file_name)
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
  def craw_css(css_file_path)
    open(css_file_path, "r") do |f|
      # CSS ファイル内に存在するリンクの取得
      buffer = f.read
      background_images = buffer.scan(/background-image:url\(\"[^\"]+\"/)

      # マルチスレッドの初期化
      h = {} # 戻り値の空ハッシュを作成

      background_images.each do |background_image|
        # 相対パスの場合
        #   background_image が ../ や ../../ の場合
        #     css_file_path
        #       "./ac/globalnav/5/ja_JP/styles/ac-globalnav.built.css"
        #
        #     background_images.first[22..-2]
        #       "../images/globalnav/apple/image_large.svg"
        #
        #     File.dirname(css_file_path)
        #       "./ac/globalnav/5/ja_JP/styles"
        #
        #     File.dirname(css_file_path) + "/" + background_images.first[22..-2]
        #       "./ac/globalnav/5/ja_JP/styles/../images/globalnav/apple/image_large.svg"
        #
        #
        # 絶対パスの場合
        #   background_image が /v/home/d/~ などの場合
        #     css_file_path
        #       "./ac/globalfooter/5/ja_JP/styles/ac-globalfooter.built.css"
        #
        #     background_images.last[22..-2]
        #       "/ac/flags/1/images/jp/32.png"
        #
        #     ".#{background_images.last[22..-2]}"
        #       "./ac/flags/1/images/jp/32.png"

        h[background_image] = Thread.new do
          background_image_url = background_image[22..-2] # background-image:url("---" の中身が取得できる

          # もしエンコードした XML として svg が埋め込まれている場合
          if /svg\+xml/ =~ background_image_url
            next
          end

          # ディレクトリ作成
          if (/.css|.js|.png|.jpg|.jpeg|.svg/ =~ background_image_url)
            dir_name = File.dirname(background_image_url) # 最後の拡張子が含まれるファイルを除外

            is_dir_exist = Dir.exist?(dir_name)
            if !is_dir_exist
              FileUtils.mkdir_p(".#{dir_name}")
              puts("INFO: CREATED - DIR - .#{dir_name}")
            else
              puts("INFO: SKIP    - DIR - .#{dir_name}")
            end
          else
            is_dir_exist = Dir.exist?(background_image_url)
            if !is_dir_exist
              FileUtils.mkdir_p(".#{background_image_url}")
              puts("INFO: CREATED - DIR - .#{background_image_url}")
            else
              puts("INFO: SKIP    - DIR - .#{background_image_url}")
            end
          end

          # リンク先の取得( 画像 )
          is_exist = File.exist?(".#{background_image_url}")
          if !is_exist
            open(".#{background_image_url}", "wb") do |img|
              open("https://www.apple.com" + background_image_url) do |io|
                img.puts(io.read)
                puts("INFO: CREATED - IMG - #{background_image_url}")
              end
            end
          else
            puts("INFO: SKIP    - IMG - #{background_image_url}")
          end
        end
      end

      # ハッシュを反復処理
      h.each_pair do |filename, thread|
        begin
          # Thread#value -> スレッドが終了するまで待ち、戻り値を得る
          h[filename] = thread.value
        rescue
          # $! -> Exception | nil
          h[filename] = $!
        end
      end

      # TODO: 書き込みパスからの相対パスあぶり出し
      #
      # "./v/home/d/built/styles/main.built.css".split("/").count
      # => 7
      #
      # ../../../../../../v/home/d/built/images/mac-takeover/graph
      #
      back_path = ""
      (css_file_path.split("/").count - 1).times { back_path += "../" }
      back_path = back_path[0..-2] # ..//v/home などを避けるため

      # TODO: /background-image:url\(\"[^\"]+\"/ の正規表現で柔軟な対応にする
      buffer.gsub!(/\/v\/home\/d/, "../..")

      open(css_file_path, "w") do |css|
        css.write(buffer)
      end
    end
  end

  #
  def main(url, html_file_name)
    hrefs = get_site_links(url)
    hrefs.each do |l|
      # 仮に何も要素が入ってなかった場合
      next unless l

      # 外部リンクだった場合
      if l[0..7] == "https://" || l[0..6] == "http://"
        # TODO: クローリングさせるように
        puts("INFO: SKIP    - OUTSIDE URL: #{l}")
        next
      end

      # パス "#" の対策
      if l == "#" || l[0] == "#"
        puts("INFO: SKIP    - PATH: #{l}")
        next
      end

      begin
        # ディレクトリ作成
        if (/.css/ =~ l) || (/.js/ =~ l)
          dir_name = File.dirname(l) # 最後の拡張子が含まれるファイルを除外
          is_dir_exist = Dir.exist?(dir_name)
          if !is_dir_exist
            FileUtils.mkdir_p(".#{dir_name}")
            puts("INFO: CREATED - DIR - .#{dir_name}")
          else
            puts("INFO: SKIP    - DIR - .#{dir_name}")
          end
        else
          is_dir_exist = Dir.exist?(l)
          if !is_dir_exist
            FileUtils.mkdir_p(".#{l}")
            puts("INFO: CREATED - DIR - .#{l}")
          else
            puts("INFO: SKIP    - DIR - .#{l}")
          end
        end

        open(get_apple_domain(url) + l) do |io|
          # index.html の作成
          if io.content_type == "text/html"
            open("./#{l}/#{html_file_name}", "wb") do |html|
              html.write(io.read)
            end
          # css の作成
          elsif io.content_type == "text/css"
            open(".#{l}", "wb") do |css|
              css.write(io.read)
              puts("INFO: CREATED - CSS - #{l}")

              # CSS内のクローリング( 主に画像 )
              open_file_path = ".#{l}"
              craw_css(open_file_path)
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
          puts("INFO: SKIP    - REDIRECTION URL: #{redirect_link}")
          next
        end

        puts(e)
      end
    end
  end

  #
  def build()
    # 入力受付
    print("URL: ")

    # 定数宣言
    url = gets.chomp
    html_file_name = "index.html"

    # 初期化
    init_apple_jp_root(url, html_file_name)

    # メイン処理
    main(url, html_file_name)
  end
end
