echo -e "\n### update yeti code"
git pull
echo -e "\n### update yeti submodule, i.e. assets"
git submodule update --init --recursive
echo -e "\n### bunlde install ruby gems"
bundle install
echo -e "\n### sync pre-compiled java apps"
rake sync_assets
