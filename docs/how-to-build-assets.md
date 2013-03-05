==================================================
Assets build process
==================================================

Introduction
==============================================================
Assets is the set of binaries/apps that used in yeti cases. The purpose of this doc is to introduce how to create one new binary and use it in yeti case.

About Yeti roles
-----------------------
Yeti supports two roles:

1. Yeti User: who runs yeti scripts to verify environment, but does not develop any Yeti case, such like SRE, Core Dev Team.

2. Yeti Dev: who needs to develop/maintain Yeti cases, such like QA.


Steps
=======================

1. Checkout Repo & update
-----------------------
``git clone git@github.com:cloudfoundry/vcap-yeti.git``

``cd vcap-yeti && bash update.sh``

2. Put your App Code in assets & Test locally
-----------------------
``vcap-yeti/assets`` is the folder of assets source code, you can see code organized by frameworks.

Folder tree is like:

    |--- assets

      |--- rails3

      |--- grails

      |--- spring

      |--- ...

You can put your app code under corresponding framework folder.

Take spring as an example:

``cd vcap-yeti/assets/spring/ && mkdir <your_app_name>``

The folder ``vcap-yeti/assets/spring/<your_app_name>`` is workspace of your app, now you can put your app code here.

You could test your app by pushing it to dev instance , and verify functions manually first.

3. Update build task & build your app
-----------------------
Notes: If your app doesn’t need build, skip this step.

``cd vcap-yeti/tools;``

Edit Rakefile

constant TESTS_TO_BUILD is the arr of app build path, add your app path to TESTS_TO_BUILD

``rake build;``

After rake task finished, check the binary folder:

``cd vcap-yeti/.assets_binaries``

And the binary file should exist.

4. Update assets.yml
-----------------------
``assets.yml`` is the config file of all assets.

``cd vcap-yeti/config;``

Edit assets.yml, add your app configs.

e.g.

      spring_app_test: # app name used in yeti case

        instances: 1

          memory: 320

          path: ".assets-binaries/spring_test_app.war" # path of your binary/app

5. Use your app locally in case
-----------------------
Now you can use app in your yeti case:

e.g.

``app = create_push_app("spring_app_test")``

Test locally to make sure the functions being correct.

6. Commit your change
-----------------------
Commit your app code and submit a pull request to vcap_test_assets. And also don’t forget to commit yeti changes: ``config/assets.yml``, ``tools/Rakefile``...

Once it has been merged, please notice QA to upload binary to blobs server.



That’s all about assets build steps, Thank you.
