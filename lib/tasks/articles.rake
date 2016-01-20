namespace :articles do
  desc '新しい記事入稿'
  task new_post: :environment do
    # グラビア関係の記事を追加
    Article.new_post

    # 無料アニメを追加（ただし、更新日がマッチしたもののみ）
    wdays = ["日", "月", "火", "水", "木", "金", "土"]
    youbi = wdays[Time.now.wday]
    hour =  Time.now.hour
    Animation.recent.each do |animation|
      next unless youbi == animation.update_wday
      next unless hour == animation.update_hour
      animation.story_no += 1
      animation.save!
      animation.post_article
    end
  end

  task reset_data: :environment do
    Article.destroy_all
  end
end
