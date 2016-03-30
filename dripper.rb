require 'yaml'
require 'pp'
require 'optparse'


require_relative './initalize.rb'


#引数の読みこみ
OptionParser.new do |opt|
  opt.version = '0.0.1'
  opt.on('-i','--init','初回起動時')         {|v| $init = v}
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
end

=begin
config = YAML.load_file('config.yml')
targetSites = config["targetSites"]
cronTime = config["cronTime"]

p targetSites
p cronTime
=end
