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
      # Thread#value -> スレッドが終了するまで待ち、戻り値を得る
      h[filename] = thread.value
    rescue
      # $! -> Exception | nil
      h[filename] = $!
    end
  end
end
