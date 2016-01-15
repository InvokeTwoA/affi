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

      word = ["グラビアアイドル", "アイドル写真集", 'レースクィーン'].sample
      response = self.search_amazon(word)
      puts 'search amazon'
      puts "count = #{response.items.count}"
      response.items.each_with_index do |res, i|
        # 商品情報を取得
        asin = res.get('ASIN')
        if Article.where(asin: asin).any?
          puts "asin #{asin} already exist"
          next
        end

        # 同じ人の商品を取得
        author = res.get('Author')
        relative_asins = self.get_relative_asins(author, asin)

        # 関連商品
        similar_goods_asins = self.get_similar_goods_asins(res)

        # 記事作成
        body = ApplicationController.new.render_to_string(
          :template => 'roots/_article',
          :layout => false,
          :locals => { 
            :res => res, 
            relative_asins: relative_asins,
            similar_goods_asins: similar_goods_asins 
          }
        )

        # 記事作成
        title        = res.get('ItemAttributes/Title')
        entry = Atom::Entry.new(
          title: title.encode('BINARY', 'BINARY'),
          content: body.encode('BINARY', 'BINARY')
         )
        atom_res = client.create_entry(url, entry);
        print "atom_res=#{atom_res}"
        Article.create(title: title, body: body, asin: asin, author: author)
        break
      end
      puts 'complete'
    end


    def search_amazon(word)
      # デバッグモードで実行したい場合はコメントを外す
      Amazon::Ecs.debug = true
      res = Amazon::Ecs.item_search(word,
        search_index:   'Books',
        response_group: 'Large',
        country:        'jp'
      )
      res
    end

    def test
      word = ["グラビアアイドル", "アイドル写真集"].sample
      response = self.search_amazon(word)
      response.items.each_with_index do |res, i|
        asin = res.get('ASIN')
        if Article.where(asin: asin).any?
          puts "asin #{asin} already exist"
          next
        end

        author = res.get('Author')
        relative_asins = self.get_relative_asins(author, asin)

        # 関連商品
        similar_goods_asins = self.get_similar_goods_asins(res)

        # 記事作成
        body = ApplicationController.new.render_to_string(
          :template => 'roots/_article',
          :layout => false,
          :locals => { 
            :res => res, 
            relative_asins: relative_asins,
            similar_goods_asins: similar_goods_asins 
          }
        )
        puts body
        title        = res.get('ItemAttributes/Title')
        Article.create(title: title, body: body, asin: asin, author: author)
        break
      end
    end

    def get_relative_asins(author, asin)
      return if author.blank?
      puts "author = #{author}"
      relative_asins = []
      relative_response = self.search_amazon(author)
      relative_response.items.each_with_index do |relative_res|
        relative_asin = relative_res.get('ASIN')
        next if relative_asin == asin
        relative_asins.push relative_asin
      end
      relative_asins
    end

    # amazon API の関連商品
    def get_similar_goods_asins(res)
      asins = []
      #asin = res.get('SimilarProducts/SimilarProduct/ASIN')
      similar_products = res.get_element('SimilarProducts')
      similar_products.elem.children.each do |child|
        asins.push child.xpath("ASIN").text
      end
      asins
    end
  end
end
