# -*- encoding: utf-8 -*-
require 'atomutil'
require 'rubygems'
require 'google/api_client'
require 'trollop'
class Article < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
  scope :success, -> { where("failed_flag != ?", false) }
  scope :active, -> { where("deleted_at != ?", true) }

  YOUTUBE_DEVELOPER_KEY = 'AIzaSyAzoxN3WVjJ-Oa1eu0BontCw-G8W15MyuM'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'

  # はてなブログから記事削除
  def rm_hatena_blog
    url = "https://blog.hatena.ne.jp/siki_kawa/kawa-e.hateblo.jp/atom/entry/#{self.blog_id}"
    user = 'siki_kawa'
    api_key = 'rfu388pqwx'
    auth = Atompub::Auth::Wsse.new(
      username: user,
      password: api_key
    )
    client = Atompub::Client.new(auth: auth)
    client.delete_entry(url);
    self.deleted_at = Time.now
    self.save!
  end

  def upload_hatena
    blog_id = self.post_hatena_blog(self.title, self.body)
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
            puts "page = #{page}. get data"
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
    end

    #  はてなブログに記事投稿
    def post_hatena_blog(title, body)
      url = 'https://blog.hatena.ne.jp/siki_kawa/kawa-e.hateblo.jp/atom/entry'
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
      res = client.create_entry(url, entry);
      return res.split("/").last
    end

    def search_amazon(word, page = 1)
      #search_index = ['Books', 'DVD'].sample
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

    def search_youtube(keyword)
      opts = Trollop::options do
        opt :q, keyword, :type => String, :default => 'Google'
        opt :max_results, 'Max results', :type => :int, :default => 25
      end
      client, youtube = self.get_youtube_service
      begin
        # Call the search.list method to retrieve results matching the specified
        # query term.
        search_response = client.execute!(
          :api_method => youtube.search.list,
          :parameters => {
            :part => 'snippet',
            :q => opts[:q],
            :maxResults => opts[:max_results]
          }
        )
        videos = []
        channels = []
        playlists = []

        search_response.data.items.each do |search_result|
          case search_result.id.kind
            when 'youtube#video'
              videos << "#{search_result.snippet.title} (#{search_result.id.videoId})"
            when 'youtube#channel'
              channels << "#{search_result.snippet.title} (#{search_result.id.channelId})"
            when 'youtube#playlist'
              playlists << "#{search_result.snippet.title} (#{search_result.id.playlistId})"
          end
        end
        puts "Videos:\n", videos, "\n"
        puts "Channels:\n", channels, "\n"
        puts "Playlists:\n", playlists, "\n"
      rescue Google::APIClient::TransmissionError => e
        puts "error"
        puts e.result.body
      end
    end

    def get_authenticated_service
      client = Google::APIClient.new(
        :application_name => $PROGRAM_NAME,
        :application_version => '1.0.0'
      )
      youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)

      file_storage = Google::APIClient::FileStorage.new("#{$PROGRAM_NAME}-oauth2.json")
      if file_storage.authorization.nil?
        client_secrets = Google::APIClient::ClientSecrets.load
        flow = Google::APIClient::InstalledAppFlow.new(
          :client_id => client_secrets.client_id,
          :client_secret => client_secrets.client_secret,
          :scope => [YOUTUBE_SCOPE]
        )
        client.authorization = flow.authorize(file_storage)
      else
        client.authorization = file_storage.authorization
      end

      return client, youtube
    end

    def get_youtube_service
      client = Google::APIClient.new(
        :key => YOUTUBE_DEVELOPER_KEY,
        :authorization => nil,
        :application_name => 'kawa-e',
        :application_version => '1.0.0'
      )
      youtube = client.discovered_api(YOUTUBE_API_SERVICE_NAME, YOUTUBE_API_VERSION)
      return client, youtube
    end

    # amazon 検索結果を検証
    def is_item_ok?(item)
      if item.get('ItemAttributes/IsAdultProduct') == "1"
        puts 'false. adult product'
        return false
      end
      # 画像がない事は意外に多い
      #if item.get("LargeImage/URL") == nil
      #  puts "image not found"
      #  return false
      #end
      asin = item.get('ASIN')
      if Article.where(asin: asin).any?
        puts "asin already posted"
        return false
      end
      puts "this item is ok!"
      true
    end
  end
end
