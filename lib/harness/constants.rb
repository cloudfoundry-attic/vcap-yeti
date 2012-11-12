
module BVT
  module Harness

    ## multi versions of runtime. constant for category and runtimes.
    VCAP_BVT_INFO_RUNTIME = {
      :ruby=>['ruby19', 'ruby18'],
      :java=>['java6', 'java7'],
      :node=>['node', 'node06', 'node08']
    }
  end
end

