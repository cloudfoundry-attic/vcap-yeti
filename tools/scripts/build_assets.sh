#!/bin/bash
############################################################
### README
### set crontab
### */10 * * * *
### build assets every 10 minutes
###########################################################

BUILD_HOME=/home/cfqa/cf/test
ASSETS_REPO=https://github.com/cloudfoundry/vcap-yeti/
GIT=git

echo "------------------------------------------------------"
echo "- build assets begin"
echo "- build home: $BUILD_HOME"
echo "------------------------------------------------------"
#### create remote repo folder if not exists
if [ ! -d $BUILD_HOME/remote ];then
  mkdir -p $BUILD_HOME/remote
fi
if [ ! -d $BUILD_HOME/local ];then
  mkdir -p $BUILD_HOME/local
fi


echo "------------------------------------------------------"
rm -rf $BUILD_HOME/remote/vcap-yeti

echo "- git clone $ASSETS_REPO"
### download code from remote repo.
cd $BUILD_HOME/remote
git clone $ASSETS_REPO
echo "-----------------------------------------------------"
if [ $? -eq 0 ];then
  echo "- git clone succeed"
  echo "-----------------------------------------------------"
  cd $BUILD_HOME/remote/vcap-yeti
  git submodule update --init
  cd $BUILD_HOME/remote/vcap-yeti/assets
  REMOTE_COMMIT=(`git log | head -1`)
  REMOTE_COMMIT_ID=${REMOTE_COMMIT[1]}
  echo "-----------------------------------------------------"
  echo "- remote commit id: $REMOTE_COMMIT_ID"
  echo "------------------------------------------------------"
fi


if [ -d $BUILD_HOME/local/vcap-yeti ];then
  cd $BUILD_HOME/local/vcap-yeti/assets
  LOCAL_COMMIT=(`git log | head -1`)
  LOCAL_COMMIT_ID=${LOCAL_COMMIT[1]}
  echo "- local commit id: $LOCAL_COMMIT_ID"
  echo "------------------------------------------------------"
fi

BUILD_FLAG=""

if [ "$REMOTE_COMMIT_ID" == "$LOCAL_COMMIT_ID" ];then
  echo "- local builds are latest, no need to build"
  echo "- build exits"
  echo "------------------------------------------------------"
  exit 0;
else
  if [ "$LOCAL_COMMIT_ID" == "" ];then
    BUILD_FLAG="build"
  else
    cd $BUILD_HOME/remote/vcap-yeti/assets
    git diff $REMOTE_COMMIT_ID $LOCAL_COMMIT_ID | grep "diff --git" > $BUILD_HOME/.gitdiff
    grep -E "\#\{TESTS_PATH\}" $BUILD_HOME/local/vcap-yeti/tools/Rakefile > $BUILD_HOME/.javaassets
  fi
fi

while read line
do
  build_path=`echo $line | awk -F'#{TESTS_PATH}' '{print $2}'| sed s/\"\,//g`
  result=`grep $build_path $BUILD_HOME/.gitdiff`
  if [ "$result" != "" ];then
    BUILD_FLAG="build"
    break;
  fi
done < $BUILD_HOME/.javaassets

if [ $BUILD_FLAG == "build" ];then
  echo "- build begins"
  echo "------------------------------------------------------"
  rm -rf $BUILD_HOME/local/vcap-yeti
  mv $BUILD_HOME/remote/vcap-yeti $BUILD_HOME/local/
  cd $BUILD_HOME/local/vcap-yeti/tools
  rake build 2>&1 1>$BUILD_HOME/.buildlog
  if [ $? -eq 0 ];then
    echo "- build success"
    echo "------------------------------------------------------"
  else
    rm -rf $BUILD_HOME/buildfail/
    mkdir $BUILD_HOME/buildfail/
    mv $BUILD_HOME/local/vcap-yeti $BUILD_HOME/buildfail/
    echo "- build fail"
    echo "------------------------------------------------------"
  fi
fi

