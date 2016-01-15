# -*- encoding: utf-8 -*-
require 'atomutil'
class Article < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }

  class << self
    def new_post
      url = 'https://blog.hatena.ne.jp/siki_kawa/kawa-e.hateblo.jp/atom/entry'

      # WSSE authentication
      user = 'siki_kawa'
      api_key = 'rfu388pqwx'

      auth = Atompub::Auth::Wsse.new(
        username: user,
        password: api_key
      )
      client = Atompub::Client.new(auth: auth)

      res2 = self.search_amazon
      res2.items do |res|
        asin = res.first_item.get('ASIN')
        next if Article.where(asin: asin).any?
        title = res.first_item.get('ItemAttributes/Title')
        release_date = res.first_item.get('ItemAttributes/ReleaseDate')
        content = res.first_item.get('EditorialReviews/EditorialReview/Content')

        entry = Atom::Entry.new(
          title: title.encode('BINARY', 'BINARY'),
          content: <<"ENDOFCONENT".encode('BINARY', 'BINARY'))
====
[asin:#{ asin }:image:large]
【目次】
[:contents]
* 発売日
#{ release_date }
* 内容紹介
#{ content }

ENDOFCONENT
        res = client.create_entry(url, entry);
        Article.create(title: "now #{Time.now}", body: res, asin: asin)
        break
      end
    end


    def search_amazon
      # デバッグモードで実行したい場合はコメントを外す
      #Amazon::Ecs.debug = true
      res = Amazon::Ecs.item_search("グラビアアイドル",
        search_index:   'Books',
        response_group: 'Medium',
        country:        'jp'
      )
      res
    end
  end

end
