#!/bin/bash

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (zeno29): " username
    username=${username:-zeno29}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h24v07.061.2025034202919/MCD19A2.A2025031.h24v07.061.2025034202919.hdf"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h24v07.061.2025034202919/MCD19A2.A2025031.h24v07.061.2025034202919.hdf -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h24v07.061.2025034202919/MCD19A2.A2025031.h24v07.061.2025034202919.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        detect_app_approval
    fi
}

setup_auth_wget() {
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        filename="${line##*/}"
        stripped_query_params="${filename%%\?*}"
        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o "/content/MCD19A2_HDF_JAN2025/$stripped_query_params" -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        filename="${line##*/}"
        stripped_query_params="${filename%%\?*}"
        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document "/content/MCD19A2_HDF_JAN2025/$stripped_query_params" --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025007.h24v06.061.2025009030805/MCD19A2.A2025007.h24v06.061.2025009030805.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025007.h24v07.061.2025009030527/MCD19A2.A2025007.h24v07.061.2025009030527.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025007.h25v07.061.2025009030758/MCD19A2.A2025007.h25v07.061.2025009030758.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025007.h25v06.061.2025009030907/MCD19A2.A2025007.h25v06.061.2025009030907.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025006.h25v07.061.2025008105019/MCD19A2.A2025006.h25v07.061.2025008105019.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025006.h24v06.061.2025008105905/MCD19A2.A2025006.h24v06.061.2025008105905.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025006.h24v07.061.2025008120944/MCD19A2.A2025006.h24v07.061.2025008120944.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025006.h25v06.061.2025008125724/MCD19A2.A2025006.h25v06.061.2025008125724.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025005.h25v06.061.2025006171539/MCD19A2.A2025005.h25v06.061.2025006171539.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025005.h24v07.061.2025006185011/MCD19A2.A2025005.h24v07.061.2025006185011.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025005.h25v07.061.2025006194746/MCD19A2.A2025005.h25v07.061.2025006194746.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025005.h24v06.061.2025006205418/MCD19A2.A2025005.h24v06.061.2025006205418.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025004.h25v07.061.2025005200256/MCD19A2.A2025004.h25v07.061.2025005200256.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025004.h25v06.061.2025005200428/MCD19A2.A2025004.h25v06.061.2025005200428.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025004.h24v06.061.2025005200753/MCD19A2.A2025004.h24v06.061.2025005200753.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025004.h24v07.061.2025005215253/MCD19A2.A2025004.h24v07.061.2025005215253.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025003.h24v06.061.2025004163407/MCD19A2.A2025003.h24v06.061.2025004163407.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025003.h24v07.061.2025004163707/MCD19A2.A2025003.h24v07.061.2025004163707.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025003.h25v06.061.2025004163057/MCD19A2.A2025003.h25v06.061.2025004163057.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025003.h25v07.061.2025004171450/MCD19A2.A2025003.h25v07.061.2025004171450.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025002.h25v06.061.2025003195208/MCD19A2.A2025002.h25v06.061.2025003195208.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025002.h25v07.061.2025003203836/MCD19A2.A2025002.h25v07.061.2025003203836.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025002.h24v07.061.2025003212806/MCD19A2.A2025002.h24v07.061.2025003212806.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025002.h24v06.061.2025003220316/MCD19A2.A2025002.h24v06.061.2025003220316.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025001.h25v07.061.2025002235002/MCD19A2.A2025001.h25v07.061.2025002235002.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025001.h25v06.061.2025003055514/MCD19A2.A2025001.h25v06.061.2025003055514.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025001.h24v06.061.2025003060200/MCD19A2.A2025001.h24v06.061.2025003060200.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025001.h24v07.061.2025003084716/MCD19A2.A2025001.h24v07.061.2025003084716.hdf
EDSCEOF