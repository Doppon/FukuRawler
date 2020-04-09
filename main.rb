require_relative 'crawler.rb'

# 最初のページにあたる ./jp/index.html のオープン
# system("open ./#{base}/#{html_file_name}")

Crawler.new.build
