# -*- encoding: utf-8 -*-
require 'atomutil'
require 'rubygems'
require 'google/api_client'
require 'trollop'
class Article < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }
  scope :success, -> { where("failed_flag != ?", false) }


  YOUTUBE_DEVELOPER_KEY = 'AIzaSyAzoxN3WVjJ-Oa1eu0BontCw-G8W15MyuM'
  YOUTUBE_API_SERVICE_NAME = 'youtube'
  YOUTUBE_API_VERSION = 'v3'

  class << self
    def new_post(mode = nil, word = nil)
      word = Keyword.select_word(mode) if word.nil?
      response = self.search_amazon(word)
      if response.items.count == 0
        Article.create(title: word, body: "ヒット件数が0件でした", asin: nil, author: nil, failed_flag: true, category: nil, target: 'グラビア')
      else 
        completed = false
        response.items.each do |res|
          # 商品情報を取得
          asin = res.get('ASIN')
          if Article.where(asin: asin).any?
            puts "asin #{asin} already exist"
            next
          end

          # アダルト商品は除外
          if res.get('ItemAttributes/IsAdultProduct') == 1
            puts "adult product"
            next
          end
          # 同じ人の商品を取得
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
          # 記事タイトル(特定アイドル名だったらカテゴリにする)
          title = res.get('ItemAttributes/Title')
          category = nil
          if Keyword.idol.pluck(:name).include? word
            title = "[#{word}]#{title}"
            category = word
          end

          # はてなブログに投稿
          self.post_hatena_blog(title, body)

          Article.create(title: title, body: body, asin: asin, author: author, failed_flag: false, category: category, target: 'グラビア')
          completed = true
          break
        end
        if completed == false
          Article.create(title: word, body: "ヒット件数が0件でした(eachした結果)", asin: nil, author: nil, failed_flag: true, category: nil, target: 'グラビア')
        end
      end
    end

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
      client.create_entry(url, entry);
    end

    def search_amazon(word)
      #search_index = ['Books', 'DVD'].sample
      #search_index = 'DVD'
      search_index = 'Books'
      Amazon::Ecs.debug = true
      res = Amazon::Ecs.item_search(word,
        search_index:   search_index,
        response_group: 'Large',
        condition: 'All',
        country:        'jp'
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
  end
end
