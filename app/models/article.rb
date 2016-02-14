require 'atomutil'
class Article < ActiveRecord::Base
  scope :recent, -> { order('updated_at DESC') }
  scope :success, -> { where("failed_flag != ?", false) }
  scope :active, -> { where("deleted_at IS NULL") }

  # ブログ更新（本文とカテゴリ）
  def update_blog(mode)
    url_type = "hatena_#{mode}_url"
    url = "#{SecretsKeyValue.return_value(url_type)}/#{self.blog_id}"
    user = SecretsKeyValue.return_value('hatena_idol_user')
    api_key = SecretsKeyValue.return_value('hatena_idol_key')
    title = "#{convert_category}#{self.title}"
    body = "記事更新 #{I18n.l(Time.now)} \n #{self.body}"
    Hatena.update_blog(user, api_key, url, title, body)
  end

  def convert_category
    conv_category = ""
    self.category.split(',').each do |value|
      conv_category += "[#{value}]"
    end
    conv_category
  end

  # はてなブログから記事削除
  def rm_hatena_blog(mode)
    url_type = "hatena_#{mode}_url" 
    url = "#{SecretsKeyValue.return_value(url_type)}/#{self.blog_id}"
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

  # はてなブログに反映する
  def upload_hatena(mode)
    blog_id = Article.post_hatena_blog(self.title, self.body, mode)
    self.update(blog_id: blog_id, staging_flag: false)
  end

  class << self
    def new_post(mode = nil, word = nil, post = true, url_type)
      if url_type == 'maid'
        keyword = Keyword.select_maid_word
      elsif word.nil?
        url_type = 'idol'
        keyword = Keyword.select_idol_word(mode) if word.nil?
      else
        url_type = 'idol'
        keyword = Keyword.find_by_name word
      end
      word = keyword.name
      response = nil
      completed = false
      start_page = keyword.search_page

      article = Article.create(title: word, body: "これから入稿します", failed_flag: true, target: url_type)
      (start_page..400).each_with_index do |i|
        page = i
        if keyword.search_page < i
          keyword.search_page = i
          keyword.save!
        end
        tmp_response = self.search_amazon(word, page)
        if tmp_response.items.count == 0 
          article.update(body: "ヒット件数が0件でした(itemsのcountが0)")
          keyword.inactive_flag = true
          keyword.save!
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
      if url_type == 'maid'
      elsif Keyword.idol.pluck(:name).include? word
        blog_title = "[#{word}]#{title}"
        category = word
      elsif keyword.category.present?
        category = keyword.category
        blog_title = title
      else
        blog_title = title
      end

      # はてなブログに投稿
      if post == true
        blog_id = self.post_hatena_blog(blog_title, body, url_type)
        article.update(title: title, body: body, asin: asin, failed_flag: false, category: category, image_url: image_url, blog_id: blog_id)
      else
        article.update(title: title, body: body, asin: asin, failed_flag: false, category: category, image_url: image_url, staging_flag: true)
      end
      article
    end

    #  はてなブログに記事投稿
    def post_hatena_blog(title, body, mode)
      url_type = "hatena_#{mode}_url"
      url     = SecretsKeyValue.return_value(url_type)
      user    = SecretsKeyValue.return_value('hatena_idol_user')
      api_key = SecretsKeyValue.return_value('hatena_idol_key')
      blog_id = Hatena.post_blog(user, api_key, url, title, body)
      return blog_id
    end

    def search_amazon(word, page = 1)
      search_index = 'Books'
      Amazon::Ecs.options = {
        associate_tag:     SecretsKeyValue.return_value('aws_associate_tag'),
        AWS_access_key_id: SecretsKeyValue.return_value('aws_access_key'),
        AWS_secret_key:    SecretsKeyValue.return_value('aws_secret_key')
      }
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
      # アダルトはNG
      if item.get('ItemAttributes/IsAdultProduct') == "1"
        return false
      end

      # 画像がなければNG
      if item.get("LargeImage/URL") == nil
        puts "image not found"
        return false
      end

      # 既にASINが記事で使われていたらNG
      asin = item.get('ASIN')
      if Article.where(asin: asin).any?
        return false
      end
      title = item.get('ItemAttributes/Title')
      return false unless NgWord.is_ok?(title)
      true
    end
  end
end
