require 'open-uri'

print("URL: "); url = gets.chomp

a = []

open(url) { |file|
  file.each_line { |line| a << line }
}

File.open("scan.html", "w") do |f|
  f.puts(a.join)
end
