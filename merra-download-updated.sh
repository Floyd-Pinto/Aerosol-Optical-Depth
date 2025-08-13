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
    echo "https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250107.nc4"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 5 --netrc-file "$netrc" https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250107.nc4 -w '\n%{http_code}' | tail  -1`
    if [ "$approved" -ne "200" ] && [ "$approved" -ne "301" ] && [ "$approved" -ne "302" ]; then
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    status=$(curl -s -z "$(date)" -w '\n%{http_code}' https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250107.nc4 | tail -1)
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
        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o "/content/MERRA2_NC4_JAN2025_WEEK/$stripped_query_params" -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
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
        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document "/content/MERRA2_NC4_JAN2025_WEEK/$stripped_query_params" --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250107.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250106.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250105.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250104.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250103.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250102.nc4
https://data.gesdisc.earthdata.nasa.gov/data/MERRA2/M2T1NXAER.5.12.4/2025/01/MERRA2_400.tavg1_2d_aer_Nx.20250101.nc4
EDSCEOF