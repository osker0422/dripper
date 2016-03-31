require 'clockwork'
require 'yaml'
require_relative './chkUpdate.rb'

include Clockwork

handler do |job|
  case job
  when 'clock.job'
    # 10 秒毎の処理
    chkUpdateJob()
  end
end

#configから読んだ
config = YAML.load_file('config.yml')
@time = config["clockTime"]
every( @time.seconds, 'clock.job')
