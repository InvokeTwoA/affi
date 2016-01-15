require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(*Rails.groups)

module Affi
  class Application < Rails::Application
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

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

  class Application < Rails::Application
    Amazon::Ecs.options = {
      :associate_tag =>     'ayanoochi-22',
      :AWS_access_key_id => 'AKIAI5TN655PDXJZEQLA',
      :AWS_secret_key =>   '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'
    }
  end

end
