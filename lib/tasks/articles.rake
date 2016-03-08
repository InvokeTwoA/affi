namespace :articles do
  desc '新しい記事入稿'
  task new_post: :environment do

    # アニメ記事の更新
    begin
      Animation.active.update_article
    rescue => e
      Article.create(title: "アニメ更新", body: "失敗しました #{e.message}", failed_flag: true, target: "animate")
    end

    # グラビア関係の記事を追加
    begin
      Article.new_post('idol')
    rescue
    end

    # メイド関係の記事を追加（下書きで）
=begin
    begin
      # Article.new_post('maid', nil, false, 'maid')
    rescue
    end
=end
  end

  task reset_data: :environment do
    Article.destroy_all
  end
end
