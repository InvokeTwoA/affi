require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Affi
  class Application < Rails::Application
    config.time_zone = 'Tokyo'
    config.i18n.default_locale = :ja
    config.active_record.default_timezone = :local
    config.encoding = 'utf-8'

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.generators do |g|
      g.template_engine :haml
      g.helper false
      g.stylesheets false
      g.javascripts false
      g.test_framework = "rspec"
      g.controller_specs = false
    end
  end
end
