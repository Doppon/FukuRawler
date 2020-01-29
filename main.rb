require 'open-uri'

print("URL: "); url = gets.chomp

file_list = []
url_length = url.length

open(url) { |file|
  file.each_line { |line| file_list << line }
}

File.open("scan.html", "w") do |f|
  f.puts(file_list.join)
end

f = File.open("scan.html","r")
buffer = f.read();

buffer.gsub!(/href=\"/, 'href="'+url[0..url_length-5])
f = File.open("scan.html","w")
f.write(buffer)
f.close()
