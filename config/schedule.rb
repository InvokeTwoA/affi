#set :output, "/Users/n_itou/work/affi/log/cron_log.log"
set :output, 'log/cron.log'
set :environment, :development

every 1.hours do
  runner 'Article.new_post'
end
