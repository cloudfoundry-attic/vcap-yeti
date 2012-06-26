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
It is recommended to manage Ruby runtime via RVM or rbenv

## _Tested Operating Systems_
1. Mac OS X 64bit, 10.6 and above
2. Ubuntu 10.04 LTS 64bit

How to run it
-------------
1. ```git clone ssh://<YOUR-NAME>@reviews.cloudfoundry.org:29418/vcap-yeti```
2. ```cd vcap-yeti```
3. ```./update.sh      ## this is not required for running administrative test cases```
4. ```bundle exec rake tests```
5. During the first time, Yeti will prompt you for information about your environment:
    - target
    - test user/test password
    - admin user/admin password
   <br>This information is saved to ~/.bvt/config.yml file.
   <br>When run the second time around, Yeti will not prompt for the information again.

Notes:
-----
1. To be compatible with BVT, these environment variables are preserved in Yeti:
```
||Environment Variables    ||Function                  ||Example                                ||
|VCAP_BVT_TARGET           |Declare target environment |VCAP_BVT_TARGET=cloudfoundry.com         |
|VCAP_BVT_USER             |Declare test user          |VCAP_BVT_USER=pxie@vmware.com            |
|VCAP_BVT_USER_PASSWD      |Declare test user password |VCAP_BVT_USER_PASSWD=<MY-PASSWORD>       |
|VCAP_BVT_ADMIN_USER       |Declare admin user         |VCAP_BVT_ADMIN_USER=admin@admin.com      |
|VCAP_BVT_ADMIN_USER_PASSWD|Declare admin user password|VCAP_BVT_ADMIN_USER_PASSWD=<ADMIN-PASSWD>|
```

2. In order to support parallel running, and administrative test cases, Yeti will ask administrative
   account information.
   <br>However, yeti will not abuse administrative privileges, just list users, create users,
   <br>delete users created by the test script.
3. yeti run in parallel by default, you could input following command to run in serial
   ```bundle exec rake tests[1]```

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
   <br>A: Binary assets are stored in blobs.cloudfoundry.com which is a simple Sinatra application
      with blob service backend.  These assets are then synchronized via the update.sh script into
      the .assets-binaries directory of vcap-yeti.

5. How do I submit binary assets?
   <br>A: Currently binaries are generated manually based on source code updates to vcap-assets.  In
   the near future, source code updates will trigger a job to compile sources and update
   blobs.cloudfoundry.com.

6. Where is the log file stored?

   <br>A: There two log files, runtime and error logs
      - Runtime log is stored in ~/.bvt/bvt.log
      - Error log is stored in ~/.bvt/error.log
