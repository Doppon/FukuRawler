# ファイルを並列呼び出しするための関数
def conread(filenames)
  h = {} # 戻り値の空ハッシュを作成

  # スレッドの作成
  filenames.each do |filename|
    h[filename] = Thread.new do
      # ファイル読み込みの処理
      open(filename) { |f| f.read }
    end
  end

  # ハッシュを反復処理
  h.each_pair do |filename, thread|
    begin
      # thread.value の意味に注目
      h[filename] = thread.value
    rescue
      # $! の意味に注目
      h[filename] = $!
    end
  end
end
