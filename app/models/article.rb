# -*- encoding: utf-8 -*-
require 'atomutil'
class Article < ActiveRecord::Base
  scope :recent, -> { order('id DESC') }

  class << self
    def new_post
      #url =  URI.parse('https://blog.hatena.ne.jp/siki_kawa/kawa-e.hateblo.jp/atom/entry')
      url = 'https://blog.hatena.ne.jp/siki_kawa/kawa-e.hateblo.jp/atom'

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
=begin
      header = {
        "X-WSSE" => self.get_wsse(user, api_key),
        "Accept" => "application/x.atom+xml, application/xml, text/xml, */*"
      }
      uri = 'http://yahoo.co.jp/'
      tags = "test"
      xml = "<entry xmlns=\"http://purl.org/atom/ns#\">
      <title>dummy</title>
      <link rel=\"related\" type=\"text/html\" href=\"#{uri}\" />
      <summary type=\"text/plain\">#{tags}
      </summary></entry>"

      response = Net::HTTP.start(api.hostname, api.port) do |http|
        http.post(api, xml, header)
      end
      xml = Nokogiri::XML(response.body)
=end
    end

    def get_wsse(user, api_key)
      created = Time.now.iso8601
      nonce = ''
      20.times do 
        nonce << rand(256).chr
      end
      passdigest = Digest::SHA1.digest(nonce + created + api_key)
      return "UsernameToken Username=\"#{user}\", " +
             "PasswordDigest=\"#{Base64.encode64(passdigest).chomp}\", " + 
             "Nonce=\"#{Base64.encode64(nonce).chomp}\", " +
             "Created=\"#{created}\""
    end
  end
end
