# ファイルを並列呼び出しするための関数
def conread(filenames)
  h = {} # 戻り値の空ハッシュを作成

  # スレッド
  filenames.each do |filename|
    h[filename] = Thread.new do
      # ファイル読み込みの処理
      open(filename) { |f| f.read }
    end
  end
end

# ハッシュを反復処理
# wip
