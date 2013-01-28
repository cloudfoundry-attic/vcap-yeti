#!/bin/sh

bundle exec rake tests

#
# [ -d "$WORKSPACE/reports" ] && rm -rf $WORKSPACE/reports
#
# export PATH=$VCAP_RUBY19/bin:$VCAP_GIT/bin:$PATH
#
# BVT_TEMP_ROOT=/tmp/bvt
# mkdir -p ${BVT_TEMP_ROOT}
# echo "1"
# BVT_TEMP=`mktemp -d --tmpdir=${BVT_TEMP_ROOT}`
# mkdir -p $BVT_TEMP
# echo "the dir is: $BVT_TEMP_ROOT"
# SSH_ROOT=$BVT_TEMP/.ssh
# mkdir -p $SSH_ROOT
#
# cp ~/.ssh/* $SSH_ROOT
#
# #YETI_CONFIG_ROOT=$BVT_TEMP/yeti
# #mkdir -p $YETI_CONFIG_ROOT
#
# #cat <<-EOT > $YETI_CONFIG_ROOT/config.yml
# #---
# #target: vcap.me
# #user:
# #  email: test@vcap.me
# #  passwd: "goodluck"
# #EOT
#
# #cat $YETI_CONFIG_ROOT/config.yml
#
# ssh-keygen -f $SSH_ROOT/known_hosts -R reviews.cloudfoundry.org
# ssh-keyscan -p 29418 reviews.cloudfoundry.org >> $SSH_ROOT/known_hosts
#
# ssh-keygen -f $BVT_TEMP/known_hosts -R github.com
# ssh-keyscan github.com >> $BVT_TEMP/known_hosts
#
# ADD_VCAP_NOPASS=`mktemp`
# cat <<-EOT > $ADD_VCAP_NOPASS
# #!/bin/bash
# echo "vcap  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
#
# [ -f "/sbin/insserv" ] || ln -s /usr/lib/insserv/insserv /sbin/insserv
# EOT
#
# DEV_SETUP_RUNNER=`mktemp`
#
# cat <<-EOT > $DEV_SETUP_RUNNER
# #!/bin/bash
# set -x
# #set -o errexit
#
# sudo mkdir -p /etc/init.d
#
# [ -d "~/cloudfoundry" ] && rm -rf ~/cloudfoundry
# mkdir ~/cloudfoundry
#
# cp -rf /tmp/$WORKSPACE ~/cloudfoundry/vcap
#
# export CLOUD_FOUNDRY_EXCLUDED_COMPONENT=
# ~/cloudfoundry/vcap/dev_setup/bin/vcap_dev_setup -a | tee /tmp/vcap_setup.log
#
# EOT
#
# TEST_RUNNER=`mktemp`
# cat <<-EOT > $TEST_RUNNER
# #!/bin/bash
# set -x
#
# #sleep 3600
# . ~/.cloudfoundry_deployment_profile
# export CLOUD_FOUNDRY_EXCLUDED_COMPONENT=
# ~/cloudfoundry/vcap/dev_setup/bin/vcap_dev start
#
# ~/cloudfoundry/vcap/dev_setup/bin/vcap_dev status
#
# cd ~/cloudfoundry/vcap
# [ -d "vcap-yeti" ] && rm -rf vcap-yeti
# git clone ssh://ci-bot@172.31.129.32:29418/vcap-yeti.git
#
# sudo apt-get update
# sudo apt-get install -y default-jdk
#
# vmc target api.vcap.me
# vmc register --email test@vcap.me --password goodluck --verify goodluck -t
#
# vmc target api.vcap.me
# vmc register --email dev@cloudfoundry.org --password goodluck --verify goodluck -t
#
# export VCAP_BVT_TARGET=http://api.vcap.me
# export VCAP_BVT_USER=test@vcap.me
# export VCAP_BVT_USER_PASSWD=goodluck
# export VCAP_BVT_ADMIN_USER=dev@cloudfoundry.org
# export VCAP_BVT_ADMIN_USER_PASSWD=goodluck
# export VCAP_BVT_CI_SINGLE_REPORT=true
#
# cd ~/cloudfoundry/vcap/vcap-yeti
# ./update ci
# #bundle exec rake tests | tee $BVT_TEMP/vcap_tests.log
# #rake -f /home/vcap/cloudfoundry/.deployments/devbox/deploy/rubies/ruby-1.9.2-p180/lib/ruby/gems/1.9.1/gems/ci_reporter-1.7.0/stub.rake ci:setup:rspec tests | tee /tmp/vcap_tests.log
#
# bundle install --deployment
# #ci_reporter_stub=\`find ./vendor -name stub.rake\`
# #bundle exec rake -f \$ci_reporter_stub ci:setup:rspec full[1] | tee /tmp/vcap_tests.log
# bundle exec rake full[1] | tee /tmp/vcap_tests.log
# bundle exec rake rerun_failure[1] | tee /tmp/vcap_tests_rerun.log
# bundle exec rake rerun_failure[1] | tee /tmp/vcap_tests_rerun.log
#
# [ -f "~/.bvt/bvt.log" ] && cp ~/.bvt/bvt.log /tmp
#
# #[ -d "spec/reports" ] && cp -rf spec/reports /tmp
# [ -d "reports" ] && cp -rf reports /tmp
#
# EOT
#
# #HANDLE=`$WARDEN_REPL -e -c "create bind_mount:$WORKSPACE,/tmp/$WORKSPACE,ro disk_size_mb:8196 grace_time:200"`
# HANDLE=`$WARDEN_REPL_V2 -- create \
# --bind_mounts[0].src_path $WORKSPACE --bind_mounts[0].dst_path /tmp/$WORKSPACE --bind_mounts[0].mode RO \
# --grace_time 100 | awk '{print $3}'`
#
# #$WARDEN_REPL -e -x -c "
# #copy $HANDLE in $SSH_ROOT /home/vcap/
# #copy $HANDLE in $ADD_VCAP_NOPASS /tmp
# #"
# $WARDEN_REPL_V2 -- copy_in --handle $HANDLE --src_path $SSH_ROOT --dst_path /home/vcap/
# $WARDEN_REPL_V2 -- copy_in --handle $HANDLE --src_path $ADD_VCAP_NOPASS --dst_path /tmp
# rm -f $ADD_VCAP_NOPASS
#
# #cd "`dirname ${WARDEN_REPL}`/../root/linux/instances/${HANDLE}"
# #cd /var/vcap/packages/warden/warden/root/linux/instances/${HANDLE}
# echo ${WARDEN_INSTANCES}/${HANDLE}
# cd ${WARDEN_INSTANCES}/${HANDLE}
# sudo ssh -F ssh/ssh_config root@container chmod +x $ADD_VCAP_NOPASS
# sudo ssh -F ssh/ssh_config root@container $ADD_VCAP_NOPASS
#
# #$WARDEN_REPL -e -x -c "copy $HANDLE in $DEV_SETUP_RUNNER /tmp"
# #rm -f $DEV_SETUP_RUNNER
# $WARDEN_REPL_V2 -- copy_in --handle $HANDLE --src_path $DEV_SETUP_RUNNER --dst_path /tmp
# rm -f $DEV_SETUP_RUNNER
#
# #$WARDEN_REPL -e -x -c "
# #run $HANDLE chmod +x $DEV_SETUP_RUNNER
# #run $HANDLE $DEV_SETUP_RUNNER
# #copy $HANDLE out /tmp/vcap_setup.log $BVT_TEMP vcap:vcap
# #"
# $WARDEN_REPL_V2 -- run --handle $HANDLE --script "chmod +x $DEV_SETUP_RUNNER"
# $WARDEN_REPL_V2 -- run --handle $HANDLE --script "$DEV_SETUP_RUNNER"
# $WARDEN_REPL_V2 -- copy_out --handle $HANDLE --src_path /tmp/vcap_setup.log --dst_path $BVT_TEMP
#
# grep "Status:.* Success" $BVT_TEMP/vcap_setup.log > /dev/null 2>&1
# if [ $? != 0 ]; then
#   rm -rf $BVT_TEMP
#   exit 1
# fi
#
# #$WARDEN_REPL -e -x -c "copy $HANDLE in $TEST_RUNNER /tmp"
# #rm -f $TEST_RUNNER
#
# $WARDEN_REPL_V2 -- copy_in --handle $HANDLE --src_path $TEST_RUNNER --dst_path /tmp
# rm -f $TEST_RUNNER
#
# $WARDEN_REPL -e -x -c "
# run $HANDLE chmod +x $TEST_RUNNER
# run $HANDLE $TEST_RUNNER
# copy $HANDLE out /tmp/reports $WORKSPACE vcap:vcap
# copy $HANDLE out /tmp/bvt.log /tmp vcap:vcap
##destroy $HANDLE
##"
##
##rm -rf $BVT_TEMP