Yeti User Manual
================

What is Yeti
------------

Yeti stands for "Yet Extraordinary Test Infrastructure" and is an rspec-based
basic validation test for cloud foundry environments.

<br>*Under development*

This repository contains tests for [vcap](https://github.com/cloudfoundry/vcap).

## Dependencies
1. Ruby 1.9.2
2. Bundle >= 1.1
3. admin user/password is needed for parallel run, if you don't have it, run serial like:
```bundle exec rake full[1]```
<br>It is recommended to manage Ruby runtime via RVM or rbenv

## _Tested Operating Systems_
1. Mac OS X 64bit, 10.6 and above
2. Ubuntu 10.04 LTS 64bit

How to run it
-------------
1. ```git clone git://github.com/cloudfoundry/vcap-yeti.git```
2. ```cd vcap-yeti```
3. ```./update.sh      ## this is not required for running administrative test cases```
4. ```bundle exec rake full```
5. During the first time, Yeti will prompt you for information about your environment:
    - target
    - test user/test password
    - admin user/admin password
   <br>This information is saved to ~/.bvt/config.yml file.
   <br>When run the second time around, Yeti will not prompt for the information again.

Notes:
-----
1. To be compatible with BVT, some environment variables are preserved in Yeti:
```
||Environment Variables       ||Function            ||Example                                ||
|VCAP_BVT_TARGET              |target environment   |VCAP_BVT_TARGET=cloudfoundry.com         |
|VCAP_BVT_USER                |test user            |VCAP_BVT_USER=pxie@vmware.com            |
|VCAP_BVT_USER_PASSWD         |test user password   |VCAP_BVT_USER_PASSWD=<MY-PASSWORD>       |
|VCAP_BVT_ADMIN_USER          |admin user           |VCAP_BVT_ADMIN_USER=admin@admin.com      |
|VCAP_BVT_ADMIN_USER_PASSWD   |admin user password  |VCAP_BVT_ADMIN_USER_PASSWD=<ADMIN-PASSWD>|
|VCAP_BVT_SHOW_PENDING        |show pending cases   |VCAP_BVT_SHOW_PENDING=true               |
|VCAP_BVT_SERVICE_PG_MAXDBSIZE|service quota(MB)    |VCAP_BVT_SERVICE_PG_MAXDBSIZE=128        |
|VCAP_BVT_ADMIN_CLIENT        |admin client of uaa  |VCAP_BVT_ADMIN_CLIENT=admin              |
|VCAP_BVT_ADMIN_SECRET        |admin secret of uaa  |VCAP_BVT_ADMIN_SECRET=adminsecret        |
|ACM_URL                      |acm base url         |ACM_URL=<URL>                            |
|ACM_USER                     |acm user             |ACM_USER=<user>                          |
|ACM_PASSWORD                 |acm user password    |ACM_PASSWORD=<***>                       |
|SERVICE_BROKER_TOKEN         |service broker token |SERVICE_BROKER_TOKEN=<token>             |
|SERVICE_BROKER_URL           |service broker url   |SERVICE_BROKER_URL=http://...            |
|VCAP_BVT_LONGEVITY           |run testing N times  |VCAP_BVT_LONGEVITY=100                   |
```

2. In order to support parallel running, and administrative test cases, Yeti will ask administrative
   account information.
   <br>However, yeti will not abuse administrative privileges, just list users, create users,
   <br>delete users created by the test script.
3. rake tests/full use parallel by default, you could run in serial by specifying thread number=1:
   ```bundle exec rake full[1]```
4. As dev setup has limited resources, we strongly recommend running 1-4 threads against dev_setup.

FAQ:
----
1. What does "pending" mean and what is the correct number of pending cases?
   <br>A: *Pending* means your target environment is missing some prerequisites, usually a service,
       framework or runtime.
      <br>The number of pending cases depends on your target environment and environment variables.
      - For example, php/python is not available in the production environment so all php/python
      related test cases should be pending.

2. What's update.sh?
   <br>A: For assets that need to be compiled such as Java applications, Yeti leverages a common
      blob store to hold all these precompiled assets.  Therefore, users do not need maven to build
      java-based applications locally, the binaries just need to be sync'd from blobs.cloudfoundry.com.
      update.sh script automatically checks to see if there are new assets, so Yeti users need to
      run the update.sh script before running Yeti tests.

3. What is an _example_?
   <br>A: An Example is an RSpec naming convention for a test case scenario which may include several
   steps, if any of the steps within an example fail then the test case will be marked as failed.

4. Where are binary assets stored?
   <br>A: Binary assets are stored in http://blobs.cloudfoundry.com which is a simple Sinatra application
      with blob service backend hosted on Cloud Foundry. These assets are then synchronized via the
      update.sh script into the .assets-binaries directory of vcap-yeti.

5. How do I submit binary assets?
   <br>A: Currently binaries are generated manually based on source code updates to vcap-assets. In
   the near future, source code updates will trigger a job to compile sources and update
   blobs.cloudfoundry.com.

6. Where is the log file stored?
   <br>A: There two log files, runtime and error logs
      - Runtime log is stored in ~/.bvt/bvt.log

7. What runtimes/frameworks/services should my environment have?
   <br>Dev setup:
   - runtimes: java, ruby18, ruby19, node, node06, node08, php, python2, erlangR14B01
   - frameworks: java_web, sinatra, grails, rack, play, lift, spring, rails3, node, standalone, php,
   django, wsgi, otp_rebar
   - services: mongodb, mysql, postgresql, rabbitmq, redis, vblob, filesystem
   <br>(env variable CLOUD_FOUNDRY_EXCLUDED_COMPONENT can disable components, for details, please
   check README under vcap/dev_setup.)

   Dev instance:
   - runtimes: java, java7, ruby18, ruby19, node, node06, node08
   - frameworks: java_web, sinatra, grails, rack, play, lift, spring, rails3, node, standalone
   - services: mongodb, mysql, postgresql, rabbitmq, redis, vblob

   Production:
   - runtimes: java, java7, ruby18, ruby19, node, node06, node08
   - frameworks: java_web, sinatra, grails, rack, play, lift, spring, rails3, node, standalone
   - services: mongodb, mysql, postgresql, rabbitmq, redis

   (updated on July 19th, 2012)

8. Runtime errors
   <br>Sometimes runtime errors happen during Yeti execution,
   - 504 Gateway Error: Application fail to be started in 30 seconds
   - 502 Internal Error: Application fail to connect to service instance, including provision/un-provision
     bind/unbind.
   - 404 Not Found: Route fail to redirect request to specific application URL

9. Run specific case
   <br>User can run specific case via passing spec file with specify line number of an example
    or group as parameter
    For example:
    bundle exec rspec ./spec/simple/rails_console/ruby18_rails3_spec.rb:95

10. Build java-based assets
    <br>Please refer to docs/how-to-build-assets.md

Rake Tasks:
-----------
- admin
<br>run admin test cases
- tests
<br>run core tests in parallel, e.g. rake test\[5\] (default to 10, max = 16)
- full
<br>run full tests in parallel, e.g. rake full\[5\] (default to 10, max = 16)
- random
<br>run all bvts randomly, e.g. rake random\[1023\] to re-run seed 1023
- java
<br>run java tests (spring, java_web) in parallel
<br>e.g. rake java\[5\] (default to 10, max = 16)
- jvm
<br>run jvm tests (spring, java_web, grails, lift) in parallel
<br>e.g. rake jvm\[5\] (default to 10, max = 16)
- ruby
<br>run ruby tests (rails3, sinatra, rack) in parallel
<br>e.g. rake ruby\[5\] (default to 10, max = 16)
- services
<br>run service tests (mongodb/redis/mysql/postgres/rabbitmq/neo4j/vblob) in parallel
<br>e.g. rake services\[5\] (default to 10, max = 16)
- clean
<br>clean up test environment(only run this task after interruption).
<br>1, Remove all apps and services under test user
<br>2, Remove all test users created in admin_user_spec.rb
- help
<br>list help commands

File a Bug:
-----------
To file a bug against Cloud Foundry Open Source and its components, sign up and use our bug tracking
 system: [http://cloudfoundry.atlassian.net](http://cloudfoundry.atlassian.net)
