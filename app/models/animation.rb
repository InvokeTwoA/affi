# -*- encoding: utf-8 -*-
class Animation < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }

  def post_article
    title = "#{title} 無料動画まとめ"
    body = ApplicationController.new.render_to_string(
      :template => 'animations/_article',
      :layout => false,
      :locals => { 
        :resource => self, 
      }
    )

    # はてなブログに投稿
    self.post_hatena_blog(title, body, self.blog_url)
  end

  def hima_url(no)
    "[http://himado.in/?keyword=#{self.title}%20#{no}:title=#{no}話]"

  end

  def say_url(no)
    "[http://say-move.org/comesearch.php?q=#{self.title}%20#{no}&sort=comedate&genre=&sitei=&mode=&err_flg=undefined&p=1:title=#{no}話]"
  end

  def youtube_url(no)
    "[https://www.youtube.com/results?search_query=#{self.title}%E3%80%80#{no}:title=#{no}話]]"
  end

  class << self
    def post_hatena_blog(title, body, url = nil)
      user = 'siki_kawa'
      api_key = 'rfu388pqwx'
      auth = Atompub::Auth::Wsse.new(
        username: user,
        password: api_key
      )
      client = Atompub::Client.new(auth: auth)

      entry = Atom::Entry.new(
        title: title.encode('BINARY', 'BINARY'),
        content: body.encode('BINARY', 'BINARY')
       )
      if url.nil?
        url = 'https://blog.hatena.ne.jp/siki_kawa/anime-douga.hateblo.jp/atom/entry'
        client.create_entry(url, entry);
      else 
        url = "https://blog.hatena.ne.jp/siki_kawa/anime-douga.hateblo.jp/atom/blog/#{url}"
        client.update_entry(url, entry);
      end
    end

  end

end