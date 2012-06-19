echo -e "\n### update yeti code"
git pull
echo -e "\n### update yeti submodule, i.e. assets"
git submodule update --init --recursive
echo -e "\n### bundle install ruby gems"
ext_opt=$1
if [[ $ext_opt = 'ci' ]]
then
  bundle install
else
  bundle install --without ci
fi
echo -e "\n### sync pre-compiled java apps"
rake sync_assets
