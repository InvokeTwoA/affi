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

      entry = Atom::Entry.new(
        title: "test".encode('BINARY', 'BINARY'),
        content: <<'ENDOFCONENT'.encode('BINARY', 'BINARY'))
* if
- a
- b
ENDOFCONENT

      res = client.create_entry(url, entry);

      Article.create(title: "now #{Time.now}", body: res)
    end
  end
end
