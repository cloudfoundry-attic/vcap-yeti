# Matches if the framework with runtime name and version is found in the
# result of system_frameworks.
RSpec::Matchers.define :have_framework do |name, rt_name, rt_version|
  match do |system_frameworks|
    system_frameworks.fetch(name, {}).fetch(:runtimes, []).find do |rt|
      rt[:name] == rt_name && rt[:version] =~ /\A#{Regexp.escape(rt_version)}/
    end
  end

  failure_message_for_should do
    name, rt_name, rt_version = expected
    "should support framework #{name} on runtime #{rt_name} version #{rt_version}"
  end

end
