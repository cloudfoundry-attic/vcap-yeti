# Matches if the service with name and version is found in the result of
# system_service.
RSpec::Matchers.define :have_service do |name, version|
  match do |system_services|
    system_services.fetch(name, {}).fetch(:versions, []).include?(version)
  end

  failure_message_for_should do
    name, version = expected
    "should support service #{name} version #{version}"
  end

end
