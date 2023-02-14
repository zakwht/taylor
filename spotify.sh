#!/bin/bash

# get basic auth token from env
source .env
basic=$(echo "$CLIENT_ID:$SECRET" | base64)

# get token
# token=$(curl -d "grant_type=client_credentials" \
#   --request POST \
#   --url https://accounts.spotify.com/api/token \
#   --header "Authorization: Basic ${basic%?}" \
#   --header "Content-Type: application/x-www-form-urlencoded" \
#   | jq -r .access_token)


artist_id="06HL4z0CvFAxyc27GXpf02"

# get all albums (> album-ids.json)
# curl --request GET \
#   --url "https://api.spotify.com/v1/artists/$artist_id/albums?limit=50&include_groups=album&market=CA" \
#   --header "Authorization: Bearer $token" \
#   --header "Content-Type: application/json" \
#   | jq '.items | [.[] | {id: .id, name: .name}]' \
#   > "album-ids.json"

# manual step: select ids from albums

# album_index=0
# while read album_id; do
#   ((album_index++))
#   album_name=$(curl --request GET \
#     --url "https://api.spotify.com/v1/albums/$album_id" \
#     --header "Authorization: Bearer $token" \
#     --header 'Content-Type: application/json' \
#     | jq -r .name)

#   echo $album_index, $album_name

#   curl --request GET \
#   --url "https://api.spotify.com/v1/albums/$album_id/tracks?limit=50" \
#   --header "Authorization: Bearer $token" \
#   --header "Content-Type: application/json" \
#   | jq --arg album_name "$album_name" --arg album_index $album_index \
#   '.items | [.[] | {id: .id, name: .name, album: $album_name, album_index: $album_index}]' \
#   > "albums/$album_id.json"
# done < album-ids.txt

for f in albums/*.json; do 
  cat $f | jq -r '.[] | [.album_index, .album, .id, .name] | @csv' >> out.txt
  # echo "$f"; 
done

# all_tracks=""
# for f in albums/*.json; do 
#   all_tracks+=$(cat $f | jq -r '.[] | [.album_index, .album, .id, .name] | @scv')
# done

# # jq '.[]' <<< $all_tracks
# echo $all_tracks



# sort into normal - then bonus - alt hidden

