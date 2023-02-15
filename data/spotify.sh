#!/bin/bash

# get basic auth token from env
source .env
basic=$(echo "$CLIENT_ID:$SECRET" | base64)

get_token() {
  curl -d "grant_type=client_credentials" \
    --request POST \
    --url https://accounts.spotify.com/api/token \
    --header "Authorization: Basic ${basic%?}" \
    --header "Content-Type: application/x-www-form-urlencoded" \
    | jq -r .access_token
}

get_album_ids() {
  artist_id="06HL4z0CvFAxyc27GXpf02"
  token=$(get_token)
  curl --request GET \
    --url "https://api.spotify.com/v1/artists/$artist_id/albums?limit=50&include_groups=album&market=CA" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq '.items | [.[] | {id: .id, name: .name}]' \
    > "album-ids.json"
}

get_tracks() {
  album_index=0
  token=$(get_token)
  while read album_id; do
    ((album_index++))
    album_name=$(curl --request GET \
      --url "https://api.spotify.com/v1/albums/$album_id" \
      --header "Authorization: Bearer $token" \
      --header 'Content-Type: application/json' \
      | jq -r .name)

    echo $album_index, $album_name

    curl --request GET \
      --url "https://api.spotify.com/v1/albums/$album_id/tracks?limit=50" \
      --header "Authorization: Bearer $token" \
      --header "Content-Type: application/json" \
      | jq --arg album_name "$album_name" --arg album_index "$album_index" \
      '.items | [.[] | {id: .id, name: .name, album: $album_name, album_index: $album_index}]' \
      > "albums/$album_id.json"
  done < album-ids.txt

  node fetch.js
}

generate_csv() {
  inputs=""
  while read id; do 
    inputs+="albums/$id.json "
  done < album-ids.txt

  track_altversion=$(<track-altversion.txt)
  track_bonus=$(<track-bonus.txt)
  track_single=$(<track-single.txt)

  echo "id,name,peak,album,albumIndex,isAltVersion,isSingle,isBonus,isVault,isTv" > all-tracks.csv
  jq -n -r \
    --arg track_altversion "$track_altversion" \
    --arg track_bonus "$track_bonus" \
    --arg track_single "$track_single" \
    -f filter.jq \
    $inputs \
    >> all-tracks.csv
}

generate_csv
