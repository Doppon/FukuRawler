require 'open-uri'

url = gets.chomp

io = OpenURI.open_uri(url)

File.open("scan.html", "w") do |f| 
  f.puts(io)
end
