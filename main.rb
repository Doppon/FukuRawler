require 'open-uri'

print("URL: "); url = gets.chomp

a = []
url_length = url.length

open(url) { |file|
  file.each_line { |line| a << line }
}

File.open("scan.html", "w") do |f|
  f.puts(a.join)
end

f = File.open("scan.html","r")
buffer = f.read();

buffer.gsub!(/href=\"/, 'href="'+url[0..url_length-5])
f = File.open("scan.html","w")
f.write(buffer)
f.close()
