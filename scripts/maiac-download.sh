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
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h24v07.061.2025034202919/MCD19A2.A2025031.h24v07.061.2025034202919.hdf | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
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
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o /content/MCD19A2_HDF_JAN2025/$stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document=/content/MCD19A2_HDF_JAN2025/$stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h24v07.061.2025034202919/MCD19A2.A2025031.h24v07.061.2025034202919.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h25v07.061.2025034204001/MCD19A2.A2025031.h25v07.061.2025034204001.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h24v06.061.2025034203734/MCD19A2.A2025031.h24v06.061.2025034203734.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025031.h25v06.061.2025034214831/MCD19A2.A2025031.h25v06.061.2025034214831.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025030.h25v06.061.2025034190205/MCD19A2.A2025030.h25v06.061.2025034190205.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025030.h24v07.061.2025034193650/MCD19A2.A2025030.h24v07.061.2025034193650.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025030.h24v06.061.2025034192821/MCD19A2.A2025030.h24v06.061.2025034192821.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025030.h25v07.061.2025034193558/MCD19A2.A2025030.h25v07.061.2025034193558.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025029.h25v06.061.2025030212904/MCD19A2.A2025029.h25v06.061.2025030212904.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025029.h25v07.061.2025030224313/MCD19A2.A2025029.h25v07.061.2025030224313.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025029.h24v06.061.2025030224744/MCD19A2.A2025029.h24v06.061.2025030224744.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025029.h24v07.061.2025030225410/MCD19A2.A2025029.h24v07.061.2025030225410.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025028.h25v06.061.2025030195447/MCD19A2.A2025028.h25v06.061.2025030195447.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025028.h24v06.061.2025030202000/MCD19A2.A2025028.h24v06.061.2025030202000.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025028.h25v07.061.2025030202109/MCD19A2.A2025028.h25v07.061.2025030202109.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025028.h24v07.061.2025030203838/MCD19A2.A2025028.h24v07.061.2025030203838.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025027.h24v07.061.2025029141627/MCD19A2.A2025027.h24v07.061.2025029141627.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025027.h24v06.061.2025029140334/MCD19A2.A2025027.h24v06.061.2025029140334.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025027.h25v07.061.2025029144448/MCD19A2.A2025027.h25v07.061.2025029144448.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025027.h25v06.061.2025029145229/MCD19A2.A2025027.h25v06.061.2025029145229.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025026.h24v06.061.2025029123449/MCD19A2.A2025026.h24v06.061.2025029123449.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025026.h25v06.061.2025029124230/MCD19A2.A2025026.h25v06.061.2025029124230.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025026.h24v07.061.2025029124704/MCD19A2.A2025026.h24v07.061.2025029124704.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025026.h25v07.061.2025029133750/MCD19A2.A2025026.h25v07.061.2025029133750.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025025.h24v07.061.2025029105823/MCD19A2.A2025025.h24v07.061.2025029105823.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025025.h24v06.061.2025029110435/MCD19A2.A2025025.h24v06.061.2025029110435.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025025.h25v07.061.2025029115640/MCD19A2.A2025025.h25v07.061.2025029115640.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025025.h25v06.061.2025029111518/MCD19A2.A2025025.h25v06.061.2025029111518.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025024.h24v07.061.2025027231949/MCD19A2.A2025024.h24v07.061.2025027231949.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025024.h24v06.061.2025027233615/MCD19A2.A2025024.h24v06.061.2025027233615.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025024.h25v06.061.2025027235605/MCD19A2.A2025024.h25v06.061.2025027235605.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025024.h25v07.061.2025029075438/MCD19A2.A2025024.h25v07.061.2025029075438.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025023.h24v07.061.2025027202548/MCD19A2.A2025023.h24v07.061.2025027202548.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025023.h24v06.061.2025027203232/MCD19A2.A2025023.h24v06.061.2025027203232.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025023.h25v06.061.2025027222154/MCD19A2.A2025023.h25v06.061.2025027222154.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025023.h25v07.061.2025028231028/MCD19A2.A2025023.h25v07.061.2025028231028.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025022.h24v07.061.2025027172954/MCD19A2.A2025022.h24v07.061.2025027172954.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025022.h24v06.061.2025027172654/MCD19A2.A2025022.h24v06.061.2025027172654.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025022.h25v06.061.2025027191355/MCD19A2.A2025022.h25v06.061.2025027191355.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025022.h25v07.061.2025028022216/MCD19A2.A2025022.h25v07.061.2025028022216.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025021.h25v07.061.2025022204940/MCD19A2.A2025021.h25v07.061.2025022204940.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025021.h24v07.061.2025022205519/MCD19A2.A2025021.h24v07.061.2025022205519.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025021.h25v06.061.2025022204744/MCD19A2.A2025021.h25v06.061.2025022204744.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025021.h24v06.061.2025022211048/MCD19A2.A2025021.h24v06.061.2025022211048.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025020.h24v06.061.2025022063056/MCD19A2.A2025020.h24v06.061.2025022063056.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025020.h25v06.061.2025022064713/MCD19A2.A2025020.h25v06.061.2025022064713.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025020.h25v07.061.2025022070536/MCD19A2.A2025020.h25v07.061.2025022070536.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025020.h24v07.061.2025022120116/MCD19A2.A2025020.h24v07.061.2025022120116.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025019.h25v06.061.2025022052647/MCD19A2.A2025019.h25v06.061.2025022052647.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025019.h24v07.061.2025022060839/MCD19A2.A2025019.h24v07.061.2025022060839.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025019.h24v06.061.2025022061507/MCD19A2.A2025019.h24v06.061.2025022061507.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025019.h25v07.061.2025022062725/MCD19A2.A2025019.h25v07.061.2025022062725.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025018.h25v07.061.2025022044800/MCD19A2.A2025018.h25v07.061.2025022044800.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025018.h25v06.061.2025022045405/MCD19A2.A2025018.h25v06.061.2025022045405.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025018.h24v07.061.2025022051353/MCD19A2.A2025018.h24v07.061.2025022051353.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025018.h24v06.061.2025022052135/MCD19A2.A2025018.h24v06.061.2025022052135.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025017.h25v07.061.2025022033035/MCD19A2.A2025017.h25v07.061.2025022033035.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025017.h25v06.061.2025022033401/MCD19A2.A2025017.h25v06.061.2025022033401.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025017.h24v07.061.2025022043001/MCD19A2.A2025017.h24v07.061.2025022043001.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025017.h24v06.061.2025022043000/MCD19A2.A2025017.h24v06.061.2025022043000.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025016.h25v06.061.2025021171017/MCD19A2.A2025016.h25v06.061.2025021171017.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025016.h25v07.061.2025021171842/MCD19A2.A2025016.h25v07.061.2025021171842.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025016.h24v07.061.2025021173804/MCD19A2.A2025016.h24v07.061.2025021173804.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025016.h24v06.061.2025021173303/MCD19A2.A2025016.h24v06.061.2025021173303.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025015.h25v07.061.2025016232348/MCD19A2.A2025015.h25v07.061.2025016232348.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025015.h24v06.061.2025016232721/MCD19A2.A2025015.h24v06.061.2025016232721.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025015.h25v06.061.2025016232926/MCD19A2.A2025015.h25v06.061.2025016232926.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025015.h24v07.061.2025017001604/MCD19A2.A2025015.h24v07.061.2025017001604.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025014.h25v06.061.2025015204555/MCD19A2.A2025014.h25v06.061.2025015204555.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025014.h25v07.061.2025015205946/MCD19A2.A2025014.h25v07.061.2025015205946.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025014.h24v06.061.2025015213349/MCD19A2.A2025014.h24v06.061.2025015213349.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025014.h24v07.061.2025015215327/MCD19A2.A2025014.h24v07.061.2025015215327.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025013.h24v07.061.2025015030353/MCD19A2.A2025013.h24v07.061.2025015030353.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025013.h24v06.061.2025015034444/MCD19A2.A2025013.h24v06.061.2025015034444.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025013.h25v06.061.2025015034513/MCD19A2.A2025013.h25v06.061.2025015034513.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025013.h25v07.061.2025015034947/MCD19A2.A2025013.h25v07.061.2025015034947.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025012.h24v07.061.2025015021339/MCD19A2.A2025012.h24v07.061.2025015021339.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025012.h25v06.061.2025015023747/MCD19A2.A2025012.h25v06.061.2025015023747.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025012.h24v06.061.2025015024453/MCD19A2.A2025012.h24v06.061.2025015024453.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025012.h25v07.061.2025015025354/MCD19A2.A2025012.h25v07.061.2025015025354.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025011.h24v07.061.2025015012227/MCD19A2.A2025011.h24v07.061.2025015012227.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025011.h25v06.061.2025015014059/MCD19A2.A2025011.h25v06.061.2025015014059.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025011.h25v07.061.2025015015926/MCD19A2.A2025011.h25v07.061.2025015015926.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025011.h24v06.061.2025015020214/MCD19A2.A2025011.h24v06.061.2025015020214.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025010.h24v07.061.2025015002953/MCD19A2.A2025010.h24v07.061.2025015002953.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025010.h25v06.061.2025015003106/MCD19A2.A2025010.h25v06.061.2025015003106.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025010.h25v07.061.2025015003708/MCD19A2.A2025010.h25v07.061.2025015003708.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025010.h24v06.061.2025015003544/MCD19A2.A2025010.h24v06.061.2025015003544.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025009.h24v07.061.2025010232125/MCD19A2.A2025009.h24v07.061.2025010232125.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025009.h24v06.061.2025010232302/MCD19A2.A2025009.h24v06.061.2025010232302.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025009.h25v07.061.2025010234605/MCD19A2.A2025009.h25v07.061.2025010234605.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025009.h25v06.061.2025010234656/MCD19A2.A2025009.h25v06.061.2025010234656.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025008.h24v07.061.2025010194848/MCD19A2.A2025008.h24v07.061.2025010194848.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025008.h25v06.061.2025010194615/MCD19A2.A2025008.h25v06.061.2025010194615.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025008.h25v07.061.2025010195118/MCD19A2.A2025008.h25v07.061.2025010195118.hdf
https://data.lpdaac.earthdatacloud.nasa.gov/lp-prod-protected/MCD19A2.061/MCD19A2.A2025008.h24v06.061.2025010201055/MCD19A2.A2025008.h24v06.061.2025010201055.hdf
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