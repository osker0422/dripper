require 'yaml'
require 'pp'
require 'optparse'


require_relative './initalize.rb'
require_relative './update.rb'


#引数の読みこみ
OptionParser.new do |opt|
  opt.version = '0.0.1'
  opt.on('-i','--init','初回起動時')         {|v| $init = v}
  opt.on('-u','--update','既存データベースの手動更新')   {|v| $update = v}
  opt.on('-c','--clock','定期的に実行する')   {|v| $clock = v}
  opt.on('-h','--help','show this message') { puts opt; exit }
  begin
    opt.parse!
  rescue
    puts "Invalid option. \nsee #{opt}"
    exit
  end
end


if $init == true
  puts "init option selected"
  init()

elsif $update == true
  puts "update option selected"
  update()

elsif $clock == true
  puts "clock option selected"
  `clockwork clock.rb`
end

=begin
config = YAML.load_file('config.yml')
targetSites = config["targetSites"]
cronTime = config["cronTime"]

p targetSites
p cronTime
=end
