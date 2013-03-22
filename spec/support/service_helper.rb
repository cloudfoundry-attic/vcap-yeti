RSpec::Matchers.define :have_service do |name, version|
  default_provider = 'core'
  match do |system_services|
    system_services.fetch(name, {})[default_provider].fetch(:versions, []).include?(version)
  end

  failure_message_for_should do
    name, version = expected
    "should support service #{name} version #{version}"
  end

end