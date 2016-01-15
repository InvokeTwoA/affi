namespace :articles do
  desc '新しい記事入稿'
  task new_post: :environment do
    Article.new_post
  end
end
