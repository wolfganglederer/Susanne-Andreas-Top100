meine_variablen <- c(
  "APP_PASSWORD",
  "SUPABASE_HOST",
  "SUPABASE_PORT",
  "SUPABASE_DBNAME",
  "SUPABASE_USER",
  "SUPABASE_PASSWORD",
  "SPOTIFY_CLIENT_ID",
  "SPOTIFY_CLIENT_SECRET"
)

# 2. App hochladen und Variablen automatisch setzen lassen
rsconnect::deployApp(
  appFiles = "app.R",
  appName = "Susanne-Andreas-Top100",
  envVars = meine_variablen,
  forceUpdate = TRUE
)
