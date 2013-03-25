module WithAppHelper
  def with_app(app_asset_name, opts={})
    before(:all) { @app = create_push_app(app_asset_name) }
    after(:all) { @session.cleanup! } unless opts[:debug]
    define_method(:app) { @app }
  end
end

RSpec.configure do |config|
  config.extend(WithAppHelper)
end
