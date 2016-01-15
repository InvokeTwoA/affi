namespace :articles do
  desc '新しい記事入稿'
  task new_post: :environment do
    Article.new_post
  end

  task reset_data: :environment do
    Article.destroy_all
  end
end
