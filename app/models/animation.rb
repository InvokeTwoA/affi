# -*- encoding: utf-8 -*-
class Animation < ActiveRecord::Base
  scope :recent, -> { order('updated_at DESC') }

  def post_article
    title = "[#{self.category}]#{self.title} 無料動画まとめ"
    body = ApplicationController.new.render_to_string(
      :template => 'animations/_article',
      :layout => false,
      :locals => { 
        :resource => self, 
      }
    )

    # はてなブログに投稿
    post_hatena_blog(title, body)
  end

  def link_tag(url, no)
    "<a target='_brank' href='#{url}'>#{no}話</a>"
  end

  def hima_url(no)
    "http://himado.in/?keyword=#{self.title}%20#{no}"
  end

  def ani_url(no)
    "http://www.anitube.se/search/?search_id=#{self.eng_title}%20#{no}"
  end

  def niko_url(no)
    "http://www.nicovideo.jp/search/#{self.title}%20#{no}"
  end

  def say_url(no)
    "http://say-move.org/comesearch.php?q=#{self.title}%20#{no}&sort=comedate&genre=&sitei=&mode=&err_flg=undefined&p=1:title=#{no}話"
  end

  def youtube_url(no)
    "https://www.youtube.com/results?search_query=#{self.title}%E3%80%80#{no}:title=#{no}話"
  end

  # 記事がなければ新規作成。あれば更新をかける
  def post_hatena_blog(title, body)
    url = "#{SecretsKeyValue.return_value('hatena_anime_url')}"
    user = SecretsKeyValue.return_value('hatena_idol_user')
    api_key = SecretsKeyValue.return_value('hatena_idol_key')
    if self.blog_id.nil? || self.blog_id == "" || self.blog_id.blank?
      blog_id = Hatena.post_blog(user, api_key, url, title, body)
      self.blog_id = blog_id
      self.save!
    else 
      url = "#{url}/#{self.blog_id}"
      Hatena.update_blog(user, api_key, url, title, body)
    end
  end
end
