require 'yaml'
require 'pp'
require 'sqlite3'
require 'sequel'

require 'open-uri'
require 'nokogiri'

def init()
  config = YAML.load_file('config.yml')
  targetSites = config["targetSites"]

  db = SQLite3::Database.new("./db/dripper.db")
  db.close()


  #何かオプションを指定する場合は下記に追記する
  options = {:encoding=>"utf8"}

  #DBに接続
  db = Sequel.sqlite('./db/dripper.db' , options)

  # create an items table
  db.create_table :sites do
    primary_key :id
    String :name
    String :url
    Date  :update_date
    BLOB :html
  end

  # create a dataset from the items table
  sites = db[:sites]
  # config.ymlに書かれたサイトのレコードを作る
  targetSites.each{|site|
    # スクレイピング先のURL
    charset = nil
    url = site["url"]
    html = open(url) do |f|
      charset = f.charset # 文字種別を取得
      f.read # htmlを読み込んで変数htmlに渡す
    end

    doc = Nokogiri::HTML.parse(html, nil, charset)
    p doc.title
    date = Time.now.strftime("%Y%m%d-%H:%M:%S")
    sites.insert(:name => doc.title, :url => url,:update_date => date,:html => doc.to_html)

  }

  #アイテムの数を表示してみる
  puts "item : #{sites.count}"
  dataset = db[:sites].all
  dataset.each{|e|
    puts e
  }
end
