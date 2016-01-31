class SecretsKeyValue < ActiveRecord::Base
  class << self
    def return_value(key)
      secrets_key_value = find_by(k: key)
      if secrets_key_value.present?
        secrets_key_value.v
      else
        puts "k is not exist. #{key}"
      end
    end
  end
end
