# -*- encoding: utf-8 -*-
require 'atomutil'
require 'rubygems'
require 'google/api_client'
require 'trollop'
class Article < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
  scope :success, -> { where("failed_flag != ?", false) }
  scope :active, -> { where("deleted_at IS NULL") }

  # はてなブログから記事削除
  def rm_hatena_blog
    url = "#{SecretsKeyValue.return_value('hatena_idol_url')}/#{self.blog_id}"
    user = SecretsKeyValue.return_value('hatena_idol_user')
    api_key = SecretsKeyValue.return_value('hatena_idol_key')
    Hatena.delete_blog(user, api_key, url)
    self.deleted_at = Time.now
    self.save!
  end

  # 本番にあがってない記事を削除
  def rm_blog
    self.deleted_at = Time.now
    self.save!
  end

  def upload_hatena
    blog_id = Article.post_hatena_blog(self.title, self.body)
    self.update(blog_id: blog_id, staging_flag: false)
  end

  class << self
    def new_post(mode = nil, word = nil, post = true)
      if word.nil?
        keyword = Keyword.select_word(mode) if word.nil?
      else
        keyword = Keyword.find_by_name word
      end
      word = keyword.name
      response = nil
      completed = false
      start_page = keyword.search_page

      article = Article.create(title: word, body: "これから入稿します", failed_flag: true, target: 'グラビア')
      (start_page..400).each_with_index do |i|
        page = i
        if keyword.search_page < i
          keyword.search_page = i
          keyword.save!
        end
        tmp_response = self.search_amazon(word, page)
        if tmp_response.items.count == 0 
          article.update(body: "ヒット件数が0件でした(itemsのcountが0)")
          return
        end
        tmp_response.items.each do |item|
          if Article.is_item_ok?(item) == true
            completed = true
            response = item
            break
          end
          break if completed == true
        end
        break if completed == true
      end
      # もうデータを取り尽くしていればエラーを出力して処理終了
      if completed == false
        article.update(body: "ヒット件数が0件でした(eachした結果)")
        return
      end
      asin = response.get('ASIN')
      image_url = response.get("LargeImage/URL")

      # 関連商品
      similar_goods_asins = self.get_similar_goods_asins(response)

      # 記事作成
      body = ApplicationController.new.render_to_string(
        :template => 'articles/_article',
        :layout => false,
        :locals => { 
          :res => response, 
          similar_goods_asins: similar_goods_asins 
        }
      )
      # 記事タイトル(特定アイドル名だったらカテゴリにする)
      title = response.get('ItemAttributes/Title')
      category = nil
      if Keyword.idol.pluck(:name).include? word
        title = "[#{word}]#{title}"
        category = word
      end

      # はてなブログに投稿
      if post == true
        blog_id = self.post_hatena_blog(title, body)
        article.update(title: title, body: body, asin: asin, failed_flag: false, category: category, image_url: image_url, blog_id: blog_id)
      else
        article.update(title: title, body: body, asin: asin, failed_flag: false, category: category, image_url: image_url, staging_flag: true)
      end
      article
    end

    #  はてなブログに記事投稿
    def post_hatena_blog(title, body)
      url = "#{SecretsKeyValue.return_value('hatena_idol_url')}"
      user = SecretsKeyValue.return_value('hatena_idol_user')
      api_key = SecretsKeyValue.return_value('hatena_idol_key')
      entry = Atom::Entry.new(
        title: title.encode('BINARY', 'BINARY'),
        content: body.encode('BINARY', 'BINARY')
      )
      #blog_id = Hatena.post_blog(user, api_key, url, entry)
      #return blog_id
      auth = Atompub::Auth::Wsse.new(
        username: user,
        password: api_key
      )
      client = Atompub::Client.new(auth: auth)
      res = client.create_entry(url, entry);
      return res.split("/").last
    end

    def search_amazon(word, page = 1)
      search_index = 'Books'
      #Amazon::Ecs.debug = true
      res = Amazon::Ecs.item_search(word,
        search_index:   search_index,
        response_group: 'Large',
        condition: 'All',
        country:        'jp',
        itemPage: page,
      )
      res
    end

    def test(mode=nil)
      word = Keyword.select_word(mode)
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
          :template => 'articles/_article',
          :layout => false,
          :locals => { 
            :res => res, 
            relative_asins: relative_asins,
            similar_goods_asins: similar_goods_asins 
          }
        )
        title        = res.get('ItemAttributes/Title')
        Article.create(title: title, body: body, asin: asin, author: author, failed_flag: false)
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
      if similar_products.present? && similar_products.elem.present?
        similar_products.elem.children.each do |child|
          asins.push child.xpath("ASIN").text
        end
      end
      asins
    end

    # amazon 検索結果を検証
    def is_item_ok?(item)
      if item.get('ItemAttributes/IsAdultProduct') == "1"
        return false
      end
      # 画像がない事は意外に多い
      #if item.get("LargeImage/URL") == nil
      #  puts "image not found"
      #  return false
      #end
      asin = item.get('ASIN')
      if Article.where(asin: asin).any?
        return false
      end
      true
    end
  end
end
