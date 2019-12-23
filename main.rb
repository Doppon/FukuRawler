require 'open-uri'

print("URL: ")
url = gets.chomp

a = []

open(url) {|file|
  file.each_line do |line|
    a << line
  end
}

moji = a.join

File.open("scan.html", "w") do |f|
  f.puts(moji)
end
