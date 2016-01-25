#!/usr/local/bin/ruby
# -*- encoding: utf-8 -*-
require 'atomutil'
class Hatena < ActiveRecord::Base
  class << self
    # 投稿に成功した場合はブログIDを返す
    def post_blog(user, api_key, url, title, body)
      auth = Atompub::Auth::Wsse.new(
        username: user,
        password: api_key
      )
      Rails.logger.info "t=#{title.encoding.to_s}"
      Rails.logger.info "b=#{body.encoding.to_s}"

      entry = Atom::Entry.new(
        title: title.force_encoding("BINARY"),
        content: body.force_encoding("BINARY")
      )
      client = Atompub::Client.new(auth: auth)
      res = client.create_entry(url, entry);
      return res.split("/").last
    end

    def delete_blog(user, api_key, url)
      auth = Atompub::Auth::Wsse.new(
        username: user,
        password: api_key
      )
      client = Atompub::Client.new(auth: auth)
      client.delete_entry(url);
    end
  end
end
