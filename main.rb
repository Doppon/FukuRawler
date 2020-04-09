require_relative 'crawler.rb'

# クローリング
Crawler.new.build

# 最初のページにあたる ./jp/index.html のオープン
# system("open ./#{base}/#{html_file_name}")
