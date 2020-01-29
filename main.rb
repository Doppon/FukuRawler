require 'open-uri'

print("URL: "); url = gets.chomp

file_list = []
url_length = url.length
html_file_name = "scan.html"

open(url) { |file|
  file.each_line { |line| file_list << line }
}

File.open(html_file_name, "w") do |f|
  f.puts(file_list.join)
end

f = File.open(html_file_name,"r")
buffer = f.read();
buffer.gsub!(/href=\"/, 'href="'+url[0..url_length-5])
f = File.open(html_file_name,"w")
f.write(buffer)
f.close()
