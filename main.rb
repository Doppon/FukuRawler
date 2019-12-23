require 'open-uri'

print("URL: ")
url = gets.chomp

a = []

open(url) {|file|
  file.each_line do |line|
    a << line
  end
}

File.open("scan.html", "w") do |f|
  f.puts(a.join)
end
