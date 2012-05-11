# What is Yeti

Yeti stands for "Yet Extraordinary Test Infrastructure"
it is rspec-based basic validation test
*Under development*

This repository contains tests for [vcap](https://github.com/cloudfoundry/vcap).

# Dependencies
RVM (Ruby Version Manager) is used to manage different ruby version on unix-based box
please follow the guideline, https://rvm.io/ to install RVM on your box.

_Supported Operation System_
1. Mac OS X 64bit, 10.6 and above
2. Ubuntu 10.04 LTS 64bit

# How to run it
1. gerrit-clone ssh://<YOUR-NAME>@reviews.cloudfoundry.org:29418/vcap-yeti
2. cd vcap-yeti
3. git submodule update --init --recursive ## if run admin cases, this step can be skipped
4. bundle install
5. bundle exec rake tests
6. At first time, yeti will ask you several questions about
    - target
    - test user/test passwd
    - admin user/admin passwd
   on Terminal interactively.
   And save those information into ~/.bvt/config.yml file.
   Therefore, when running again, yeit will never ask those questions again.

Note:
1. To be compatible with BVT, target should not include,"http://api." prefix string.
   For example, "cloudfoundry.com" is a valid target URL.
2. And to be compatible with BVT, environment variables are still available in yeti.
||Environment Variables    ||Function                  ||Example                                ||
|VCAP_BVT_TARGET           |Declare target environment |VCAP_BVT_TARGET=cloudfoundry.com         |
|VCAP_BVT_USER             |Declare test user          |VCAP_BVT_USER=pxie@vmware.com            |
|VCAP_BVT_USER_PASSWD      |Declare test user password |VCAP_BVT_USER_PASSWD=<MY-PASSWORD>       |
|VCAP_BVT_ADMIN_USER       |Declare admin user         |VCAP_BVT_ADMIN_USER=admin@admin.com      |
|VCAP_BVT_ADMIN_USER_PASSWD|Declare admin user password|VCAP_BVT_ADMIN_USER_PASSWD=<ADMIN-PASSWD>|
3. In order to support administrative test case, yeti will ask admin user/admin passwd information.
   However, yeti will not abuse administrative privilege for every operation,
   just list users, create normal user, delete normal user which created in test script.
4. Currently yeti run in serial, you could 'tail -f ~/.bvt/bvt.log' to get what is going on

FAQ:
1. what does "pending" mean and what is the correct number of pending cases that i should see?
   A: "pending" means your target environment misses some preconditions,
      usually a service, framework or runtime.
      The number of pending cases denpends on your target environment and environment variables.
      For example, postgreSQL service is not available on dev_setup environment. Therefore, 
      user run yeti against dev_setup environment, there should be some pending cases related
      to PostgreSQL service, and prompt message like "postgresql service is not available on 
      target environment, #{url}"
      On the other hand, mysql service should be available on dev_setup environment. When user
      run yeti against dev_setup, and get some pending message like "mysql service is not
      available on target environment, #{url}". That should be a problem.

# License

Cloud Foundry uses the Apache 2.0 license. See
[LICENSE](https://github.com/cloudfoundry/vcap-tests/blob/master/LICENSE) for details.

# Copyright

Copyright (c) 2009-2012 VMware, Inc.
