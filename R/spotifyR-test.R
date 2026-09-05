library(spotifyr)
library(httr)

access_token <- get_spotify_access_token()

# Fehler in httr localhost darf nicht drin stehen, sondern es mis eine IP adresse sein

assignInNamespace("oauth_callback", function() "http://127.0.0.1:1410/", ns = "httr")

get_my_top_artists_or_tracks(type = 'tracks', time_range = 'short_term', limit = 5)


access_token <- get_spotify_authorization_code(
  scope = c('user-top-read', 'user-read-recently-played')
)

my_top_tracks <- get_my_top_artists_or_tracks(
  type = 'tracks',
  time_range = 'short_term',
  limit = 5,
  authorization = access_token
) |> View()


access_token <- get_spotify_access_token()

get_playlist_tracks(playlist_id = "12jUsIDUZZytashQC15stO")

https://open.spotify.com/playlist/0Dxag4AcshPqFdRjKmmKop?si=jY6atqejQDW1HpWptzjeUA
https://open.spotify.com/playlist/12jUsIDUZZytashQC15stO?si=u_7hRQLQQ7OyoNmEZXhYPg
https://open.spotify.com/playlist/18wAju2tFhO9n4ZBEYBpXx?si=zDmP1Y9FTJK4vqHA0xZcsw

pub_token <- get_spotify_access_token()

access_token <- get_spotify_authorization_code(
  scope = c(
    'playlist-read-private',
    'playlist-read-collaborative',
    'user-top-read'
  )
)

tracks <- get_playlist_tracks(
  playlist_id = "18wAju2tFhO9n4ZBEYBpXx"
)


# 3. Frisches User Token holen (Browser öffnet sich zur Bestätigung)
user_token <- get_spotify_authorization_code(
  scope = c('playlist-read-private', 'playlist-read-collaborative')
)

# 4. Playlist abrufen mit dem neuen user_token
playlist_tracks <- get_playlist_tracks(
  playlist_id = "12jUsIDUZZytashQC15stO",
  authorization = user_token$credentials$access_token
)

head(playlist_tracks)
