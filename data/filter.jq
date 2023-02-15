def filter:
  .
  | [ inputs ]
  | add
  | map(. + { altversion: 0, bonus: 0, single: 0, vault: 0, tv: 0 })
  | map(select(.id | inside($track_bonus)).bonus = 1)
  | map(select(.id | inside($track_single)).single = 1)
  | map(select(.id | inside($track_altversion)).altversion = 1)
  | map(select(.album | contains("Taylor's Version")).tv = 1)  
  | map(select(.name | contains("(From The Vault)")).vault = 1)
  | map(. + { album_index: .album_index | tonumber })
  | sort_by(.bonus)
  | sort_by(.album_index)
  | map([.id, .name, .position, .album, .album_index, .altversion, .single, .bonus, .vault, .tv])
  | map(@csv) 
  | .[]
  | gsub("’";"'");

filter
