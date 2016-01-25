class SecretsKeyValue < ActiveRecord::Base
  class << self
    def return_value(key)
      secrets_key_value = find_by(k: key)
      secrets_key_value.v
    end
  end
end
