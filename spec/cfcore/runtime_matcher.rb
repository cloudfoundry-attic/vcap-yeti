# Matches if the runtime with name and version is found in the result of
# system_runtimes.
RSpec::Matchers.define :have_runtime do |name, version|
  match do |system_runtimes|
    system_runtimes.fetch(name, {})[:version] =~ /\A#{Regexp.escape(version)}/
  end

  failure_message_for_should do
    name, version = expected
    "should support runtime #{name} version #{version}"
  end

end
