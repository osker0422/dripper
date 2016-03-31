require 'yaml'
require 'pp'
require 'sqlite3'
require 'sequel'

require 'open-uri'
require 'nokogiri'

require 'diff/lcs'
require 'diffy'

#更新チェックのために指定されたURLのHTMLを拾ってきて
#ファイル名を返す
def getHtml(targetUrl)

  # スクレイピング先のURL
  charset = nil
  html = open(targetUrl) do |f|
    charset = f.charset # 文字種別を取得
    f.read # htmlを読み込んで変数htmlに渡す
  end

  doc = Nokogiri::HTML.parse(html, nil, charset)

  File.open("./tmp/"+doc.title+".html", "w") do |file|
    file.puts doc.to_html
  end

  return ("./tmp/"+doc.title+".html")

end

#ターゲットのURLからデータベースに格納された
#前に保存されているHTMLファイルを引っ張ってくる
def getOrgHtmlFile(targetUrl)
  #何かオプションを指定する場合は下記に追記する
  options = {:encoding=>"utf8"}

  #DBに接続
  db = Sequel.sqlite('./db/dripper.db' , options)


  dataset = db[:sites].filter(:url => targetUrl)
  dataset.each{|e|
    File.open("./tmp/org.html", "w") do |file|
      file.puts e[:html]
    end
  }

  return ("./tmp/org.html")


end

#引数で渡されたHTML同士でDiffを実行、差分をテキストにして吐き出す
def diffOutputText(orgHtmlFilePath,newHtmlFilePath)
  orgFile = File.open(orgHtmlFilePath,"r")
  newFile = File.open(newHtmlFilePath,"r")

  orgt = orgFile.read
  newt = newFile.read

  diff =  Diffy::Diff.new(orgt,newt, :allow_empty_diff => true, :context => 0).to_s.force_encoding('utf-8')

  return diff

end

#渡されたDiffオブジェクトからAddされたものだけ（行頭に+がついている）を
#抽出する
def extractAdd(diff)
  addition = String.new
  diff.each_line {|line|
    initial = line[0, 1]
    if (initial == '+')
      addition += line[1, line.length]
    end
  }
  return addition

end

#改行コードの依存を避けるために改行コードをLFに統一する。
def changeLineFeed(filePath)
  puts "method call changeLineFeed"

  orgFile = open(filePath,'rb')
  changedFile = open("tmp/tmpfile.html",'wb')

  changedFile.puts orgFile.read.gsub(/\r\n?/,"\n")


  orgFile.close
  changedFile.close

  File.rename("tmp/tmpfile.html",filePath)

end


#テキストの中に渡された文字列が含まれるかを検査する
#含まれていた場合Trueを返す
def serchWordOnText(filepath,wordset)
  p wordset
  findKeywordArr = Array.new

  File.foreach(filepath) do |line|
    if line =~ /#{wordset}/i
      findKeywordArr.push(line)
    end
  end
  #p findKeywordArr
  return findKeywordArr
end


def chkUpdateJob()
    config = YAML.load_file('config.yml')
    sites = config["targetSites"]
    wordsets = config["wordsets"]
    p wordsets
    mailBody = File.open("tmp/mailbody.txt","a")

    sites.each do |site|
      newHtmlFilePath = getHtml(site["url"])
      wordset = String.new
      wordsets.each{ |word|
        key =  word.keys
        if key[0] == site["word"]
          wordset = word.values
          wordset = wordset[0]
        elsif site["word"] == "all"
          wordset = "all"
        end
      }
      orgHtmlFilePath = getOrgHtmlFile(site["url"])
      changeLineFeed(newHtmlFilePath)
      changeLineFeed(orgHtmlFilePath)

      #Diffを取る
      diff = diffOutputText(orgHtmlFilePath,newHtmlFilePath)

      #diffの中から追加されたものだけを持ってくる
      addition = extractAdd(diff)

      additionfile =  File.open("./tmp/addition.html", "w")
      additionfile.puts(addition)
      additionfile.close


      if wordset != "all"

        result = serchWordOnText("./tmp/addition.html",wordset)
        result.each do |line|
          mailBody.puts line
        end

      else

        additionfile =  File.open("./tmp/addition.html", "r")
        additionfile.each do |line|
          mailBody.puts line
        end
      end
    end

end

=begin
#更新を持ってくる
#newHtmlFilePath = getHtml("http://srad.jp/")
newHtmlFilePath = "tmp/スラド -- アレゲなニュースと雑談サイト.html"
#前のを持ってくる
#orgHtmlFilePath = getOrgHtmlFile("http://srad.jp/")

orgHtmlFilePath = "tmp/org.html"

changeLineFeed(newHtmlFilePath)
changeLineFeed(orgHtmlFilePath)

#Diffを取る
diff = diffOutputText(orgHtmlFilePath,newHtmlFilePath)

#diffの中から追加されたものだけを持ってくる
addition = extractAdd(diff)

#p addition

additionfile =  File.open("./tmp/addition.html", "w")
additionfile.puts(addition)
additionfile.close

wordset = "プログラム|hogehoge|総投票数："
result = serchWordOnText("./tmp/addition.html",wordset)
p result

=end


chkUpdateJob()
