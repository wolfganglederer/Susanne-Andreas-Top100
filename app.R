# ==============================================================================
# S&A-Hochzeit: Top 100 Gäste-Playlist Shiny App
# Thema: "Liebe geht durch den Magen" (RadioEins Style)
# Host: Posit Connect (https://connect.posit.cloud/)
# Style Guide: Tidyverse Style Guide
# ==============================================================================

library(shiny)
library(bslib)
library(tidyverse)
library(sortable)
library(httr2)
library(DBI)
library(RPostgres)

# ------------------------------------------------------------------------------
# 1. Konfiguration & Hilfsfunktionen
# ------------------------------------------------------------------------------

APP_PASSWORD <- Sys.getenv("APP_PASSWORD")

GEOGRAPHIC_OPTIONS <- c(
  "Bayern",
  "Baden-Württemberg",
  "Berlin",
  "Brandenburg",
  "Bremen",
  "Hamburg",
  "Hessen",
  "Mecklenburg-Vorpommern",
  "Niedersachsen",
  "Nordrhein-Westfalen",
  "Rheinland-Pfalz",
  "Saarland",
  "Sachsen",
  "Sachsen-Anhalt",
  "Schleswig-Holstein",
  "Thüringen",
  "Österreich",
  "Irland"
)

get_spotify_access_token <- function() {
  client_id <- Sys.getenv("SPOTIFY_CLIENT_ID")
  client_secret <- Sys.getenv("SPOTIFY_CLIENT_SECRET")

  if (nchar(client_id) == 0 || nchar(client_secret) == 0) {
    return(NULL)
  }

  tryCatch(
    {
      resp <- httr2::request("https://accounts.spotify.com/api/token") |>
        httr2::req_body_form(grant_type = "client_credentials") |>
        httr2::req_auth_basic(client_id, client_secret) |>
        httr2::req_perform() |>
        httr2::resp_body_json()

      resp$access_token
    },
    error = function(e) {
      warning("Spotify Token konnte nicht abgerufen werden: ", e$message)
      NULL
    }
  )
}

search_spotify_tracks <- function(query, token) {
  if (is.null(query) || nchar(trimws(query)) < 2) {
    return(tibble::tibble())
  }

  if (is.null(token)) {
    return(tibble::tibble(
      id = paste0("demo_", seq_len(5)),
      title = paste("Demo Song", query, seq_len(5)),
      artist = "Demo Artist",
      release_year = 2020,
      spotify_url = "https://open.spotify.com"
    ))
  }

  tryCatch(
    {
      resp <- httr2::request("https://api.spotify.com/v1/search") |>
        httr2::req_url_query(
          q = query,
          type = "track",
          limit = 10,
          market = "DE"
        ) |>
        httr2::req_headers(Authorization = paste("Bearer", token)) |>
        httr2::req_perform() |>
        httr2::resp_body_json()

      items <- resp$tracks$items
      if (length(items) == 0) {
        return(tibble::tibble())
      }

      purrr::map_dfr(items, function(item) {
        year <- as.integer(substr(item$album$release_date, 1, 4))
        tibble::tibble(
          id = item$id,
          title = item$name,
          artist = paste(
            purrr::map_chr(item$artists, ~ .x$name),
            collapse = ", "
          ),
          release_year = ifelse(is.na(year), 2000, year),
          spotify_url = item$external_urls$spotify
        )
      })
    },
    error = function(e) {
      warning("Spotify Suche fehlgeschlagen: ", e$message)
      tibble::tibble()
    }
  )
}

get_db_connection <- function() {
  host <- Sys.getenv("SUPABASE_HOST", "db.ojmcdtktzxgthnckagpg.supabase.co")
  port <- as.numeric(Sys.getenv("SUPABASE_PORT", "6543"))
  dbname <- Sys.getenv("SUPABASE_DBNAME", "postgres")
  user <- Sys.getenv("SUPABASE_USER", "postgres")
  password <- Sys.getenv("SUPABASE_PASSWORD")

  DBI::dbConnect(
    RPostgres::Postgres(),
    host = host,
    port = port,
    dbname = dbname,
    user = user,
    password = password,
    sslmode = "require"
  )
}

save_guest_data_to_supabase <- function(guest_info, songs_df) {
  conn <- get_db_connection()
  on.exit(DBI::dbDisconnect(conn), add = TRUE)

  DBI::dbWithTransaction(conn, {
    guest_query <- "
      INSERT INTO public.guests (email, name, birth_year, state_country, updated_at)
      VALUES ($1, $2, $3, $4, NOW())
      ON CONFLICT (email)
      DO UPDATE SET
        name = EXCLUDED.name,
        birth_year = EXCLUDED.birth_year,
        state_country = EXCLUDED.state_country,
        updated_at = NOW();
    "
    DBI::dbExecute(
      conn,
      guest_query,
      params = list(
        guest_info$email,
        guest_info$name,
        as.integer(guest_info$birth_year),
        guest_info$state
      )
    )

    delete_query <- "DELETE FROM public.guest_top_songs WHERE guest_email = $1;"
    DBI::dbExecute(conn, delete_query, params = list(guest_info$email))

    if (nrow(songs_df) > 0) {
      insert_song_query <- "
        INSERT INTO public.guest_top_songs
        (guest_email, rank_position, artist, title, release_year, spotify_url)
        VALUES ($1, $2, $3, $4, $5, $6);
      "
      for (i in seq_len(nrow(songs_df))) {
        DBI::dbExecute(
          conn,
          insert_song_query,
          params = list(
            guest_info$email,
            as.integer(i),
            songs_df$artist[i],
            songs_df$title[i],
            as.integer(songs_df$release_year[i]),
            songs_df$spotify_url[i]
          )
        )
      }
    }
  })
}

# JS-Hilfsfunktion, um Buttons mit Enter/Return auszulösen
js_enter_click <- '
$(document).on("keyup", function(e) {
  if(e.keyCode == 13){
    if($("#app_password_input").is(":focus")) {
      $("#btn_login").click();
    } else if ($("#search_query").is(":focus")) {
      $("#btn_search").click();
    }
  }
});
'

wedding_theme <- bs_theme(
  version = 5,
  bootswatch = "lux",
  primary = "#C05C7E",
  secondary = "#4A5568",
  success = "#28A745",
  background = "#FAF8F5",
  font_scale = 1.05
)

ui <- page_fluid(
  theme = wedding_theme,
  lang = "de",

  tags$head(
    tags$script(HTML(js_enter_click)),
    tags$style(HTML(
      "
      body { background-color: #FAF8F5; font-family: 'Montserrat', sans-serif; }
      .app-header { text-align: center; padding: 30px 15px 15px 15px; background: linear-gradient(135deg, #FFF6F8 0%, #F5E6EC 100%); border-bottom: 2px solid #E2C2D0; margin-bottom: 25px; border-radius: 0 0 15px 15px; }
      .app-title { font-weight: 700; color: #C05C7E; letter-spacing: 1px; }
      .wizard-card { background: #FFFFFF; border-radius: 12px; box-shadow: 0 8px 24px rgba(0,0,0,0.06); padding: 30px; margin-bottom: 30px; }
      .song-item { background: #FFFFFF; border: 1px solid #E2E8F0; border-left: 5px solid #C05C7E; border-radius: 8px; padding: 12px 16px; margin-bottom: 8px; cursor: grab; display: flex; align-items: center; justify-content: space-between; transition: all 0.2s ease; }
      .song-item:hover { box-shadow: 0 4px 12px rgba(192, 92, 126, 0.15); }
      .drag-handle { color: #A0AEC0; font-size: 1.2rem; margin-right: 12px; cursor: grab; }
      .rank-badge { background: #C05C7E; color: white; font-weight: bold; border-radius: 50%; width: 28px; height: 28px; display: inline-flex; align-items: center; justify-content: center; margin-right: 12px; font-size: 0.9rem; }
      .btn-primary { background-color: #C05C7E; border-color: #C05C7E; }
      .btn-primary:hover { background-color: #A34866; border-color: #A34866; }
      .login-modal { max-width: 420px; margin: 80px auto; background: white; padding: 30px; border-radius: 16px; box-shadow: 0 10px 30px rgba(0,0,0,0.15); }
    "
    ))
  ),

  div(
    class = "app-header",
    h1(class = "app-title", "Susanne & Andreas - Die Top 100"),
    p(
      class = "text-muted",
      em("„Lieder zu denen du immer tanzt“ - Deine Top 10!")
    )
  ),

  uiOutput("login_screen_ui"),
  uiOutput("main_app_ui")
)

# ------------------------------------------------------------------------------
# 3. Server-Logik
# ------------------------------------------------------------------------------

server <- function(input, output, session) {
  authenticated <- reactiveVal(FALSE)
  current_step <- reactiveVal(1)

  # Speichere die demografischen Daten in reactiveValues,
  # damit sie zwischen den Schritten nicht verloren gehen!
  user_data <- reactiveValues(
    email = "",
    name = "",
    birth_year = 1975,
    state = "Bayern"
  )

  selected_songs <- reactiveVal(
    tibble::tibble(
      id = character(),
      title = character(),
      artist = character(),
      release_year = integer(),
      spotify_url = character()
    )
  )

  spotify_token <- reactiveVal(NULL)

  observe({
    spotify_token(get_spotify_access_token())
  })

  # --- Login Screen ---
  output$login_screen_ui <- renderUI({
    if (authenticated()) {
      return(NULL)
    }

    div(
      class = "login-modal text-center",
      h3("Willkommen!", class = "mb-3", style = "color: #C05C7E;"),
      p(
        "Bitte gib das Passwort aus deiner Einladungsemail ein, um fortzufahren:"
      ),
      passwordInput(
        "app_password_input",
        NULL,
        placeholder = "Passwort eingeben..."
      ),
      actionButton(
        "btn_login",
        "Einloggen",
        class = "btn-primary w-100 mt-2",
        icon = icon("key")
      ),
      uiOutput("login_error_msg")
    )
  })

  observeEvent(input$btn_login, {
    req(input$app_password_input)
    if (trimws(input$app_password_input) == APP_PASSWORD) {
      authenticated(TRUE)
    } else {
      output$login_error_msg <- renderUI({
        div(
          class = "text-danger mt-2",
          "Falsches Passwort. Bitte überprüfe deine Einladungsemail."
        )
      })
    }
  })

  # --- Haupt-UI ---
  output$main_app_ui <- renderUI({
    req(authenticated())

    div(
      style = "max-width: 950px; margin: 0 auto;",

      div(
        class = "d-flex justify-content-between mb-4 px-2",
        span(
          class = if (current_step() == 1) {
            "fw-bold text-primary"
          } else {
            "text-muted"
          },
          "1. Erklärung"
        ),
        span(
          class = if (current_step() == 2) {
            "fw-bold text-primary"
          } else {
            "text-muted"
          },
          "2. Über Dich"
        ),
        span(
          class = if (current_step() == 3) {
            "fw-bold text-primary"
          } else {
            "text-muted"
          },
          "3. Deine Top 10 Songs"
        )
      ),

      div(
        class = "wizard-card",
        switch(
          as.character(current_step()),
          "1" = ui_step_1(),
          "2" = ui_step_2(),
          "3" = ui_step_3()
        )
      )
    )
  })

  # --- Schritt 1: Erklärung ---
  ui_step_1 <- function() {
    tagList(
      h2("Willkommen zur Top 100 Wahl!", style = "color: #C05C7E;"),
      hr(),
      p(
        "Susanne und Andreas sind große Fans von ",
        a(
          "RadioEins Top 100",
          href = "https://www.radioeins.de/musik/top_100/",
          target = "_blank"
        ),
        ", deshalb wollen wir für sie zur Hochzeit eine eigene Top 100 Liste zum Thema erstellen:"
      ),
      div(
        class = "p-3 mb-3 rounded",
        style = "background-color: #FFF0F5; border-left: 4px solid #C05C7E;",
        h4(
          "💃🪩 Lieder zu denen du immer Tanzt 🪩🕺",
          style = "color: #C05C7E; margin: 0;"
        ),
        p(
          "Nenne gerne Lieder mit denen du etwas verbindest!",
          class = "mb-0 mt-1"
        )
      ),
      h5("So gehts weiter:"),
      tags$ol(
        tags$li(
          "Gehe mit ",
          strong('"WEITER"'),
          " zur nächsten Seite und gib dort ein paar Informationen über dich ein, um Susannes Statistiker-Seite zu erfreuen!"
        ),
        tags$li(
          "Auf der nächsten Seite kannst du Songs auf Spotify suchen und sie in deine persönliche Top 10 Liste einfügen. Die Tabelle kannst du dann per Drag & Drop sortieren (Platz 1 = Dein absoluter Lieblingssong). Es müssen keine 10 Lieder sein, weniger sind auch okay. Überlege dir vorher welche Lieder du auswählen willst, ein Zwischenspeichern ist nicht möglich."
        ),
        tags$li(
          "Mit ",
          strong('"LISTE ABSENDEN"'),
          " speicherst du deine Auswertungen und bist fertig!"
        )
      ),
      hr(),
      div(
        class = "d-flex justify-content-end",
        actionButton("btn_to_step2", "Weiter ➔", class = "btn-primary btn-lg")
      )
    )
  }

  observeEvent(input$btn_to_step2, {
    current_step(2)
  })

  # --- Schritt 2: Demografie ---
  ui_step_2 <- function() {
    tagList(
      h2("Ein paar Angaben zu dir", style = "color: #C05C7E;"),
      p("Damit wir am Ende spannende Statistiken auswerten können!"),
      hr(),
      div(
        class = "row g-3",
        div(
          class = "col-md-6",
          textInput(
            "email_input",
            "E-Mail-Adresse (Eindeutiger Schlüssel)*",
            value = user_data$email,
            placeholder = "deine.email@beispiel.de"
          )
        ),
        div(
          class = "col-md-6",
          textInput(
            "name_input",
            "Dein Name*",
            value = user_data$name,
            placeholder = "Vorname Nachname"
          )
        ),
        div(
          class = "col-md-6",
          numericInput(
            "birth_year_input",
            "Geburtsjahr*",
            value = user_data$birth_year,
            min = 1930,
            max = 2020,
            step = 1
          )
        ),
        div(
          class = "col-md-6",
          selectInput(
            "state_input",
            "Bundesland / Herkunft*",
            choices = GEOGRAPHIC_OPTIONS,
            selected = user_data$state
          )
        )
      ),
      uiOutput("step2_validation_error"),
      hr(),
      div(
        class = "d-flex justify-content-between",
        actionButton(
          "btn_back_to_step1",
          "⬅ Zurück",
          class = "btn-outline-secondary"
        ),
        actionButton(
          "btn_to_step3",
          "Weiter zur Songauswahl ➔",
          class = "btn-primary"
        )
      )
    )
  }

  # Wenn Zurück geklickt wird: Daten zwischenspeichern!
  observeEvent(input$btn_back_to_step1, {
    user_data$email <- input$email_input
    user_data$name <- input$name_input
    user_data$birth_year <- input$birth_year_input
    user_data$state <- input$state_input
    current_step(1)
  })

  # Wenn Weiter geklickt wird: Daten prüfen und zwischenspeichern!
  observeEvent(input$btn_to_step3, {
    email <- trimws(input$email_input)
    name <- trimws(input$name_input)

    if (nchar(email) == 0 || !grepl("^[^@]+@[^@]+\\.[^@]+$", email)) {
      output$step2_validation_error <- renderUI(div(
        class = "text-danger mt-2",
        "Bitte gib eine gültige E-Mail-Adresse ein."
      ))
      return()
    }
    if (nchar(name) == 0) {
      output$step2_validation_error <- renderUI(div(
        class = "text-danger mt-2",
        "Bitte gib deinen Namen ein."
      ))
      return()
    }

    user_data$email <- email
    user_data$name <- name
    user_data$birth_year <- input$birth_year_input
    user_data$state <- input$state_input

    current_step(3)
  })

  # --- Schritt 3: Song Auswahl ---
  ui_step_3 <- function() {
    tagList(
      h2("Deine Top 10 Songauswahl", style = "color: #C05C7E;"),
      p(
        "Suche nach Songs zum Thema Liebe, Essen & Trinken und füge sie deiner Liste hinzu."
      ),
      hr(),

      div(
        class = "row",

        # Linke Spalte: Suche
        div(
          class = "col-md-5 border-end",
          h4("🔍 Spotify-Suche"),
          textInput(
            "search_query",
            NULL,
            placeholder = "Songtitel oder Interpret..."
          ),
          actionButton(
            "btn_search",
            "Suchen",
            class = "btn-primary w-100 mb-3",
            icon = icon("search")
          ),
          uiOutput("search_results_ui")
        ),

        # Rechte Spalte: Ergebnisse (Nur noch die Drag & Drop Liste!)
        div(
          class = "col-md-7",
          div(
            class = "d-flex justify-content-between align-items-center mb-2",
            h4("🎵 Deine Top 10 Liste", class = "mb-0"),
            span(
              class = "badge bg-primary fs-6",
              uiOutput("song_count_badge", inline = TRUE)
            )
          ),
          p(
            class = "text-muted small",
            "Bringe die Lieder per Drag & Drop (Sortiersymbol ☰) in deine Wunschreihenfolge (Platz 1 = Bester Song)."
          ),

          # Hier ist NUR NOCH die sortierbare Liste
          uiOutput("sortable_songs_list")
        )
      ),

      hr(),
      div(
        class = "d-flex justify-content-between align-items-center",
        actionButton(
          "btn_back_to_step2",
          "⬅ Zurück",
          class = "btn-outline-secondary"
        ),
        actionButton(
          "btn_submit_final",
          "🚀 Liste Absenden",
          class = "btn-success btn-lg"
        )
      )
    )
  }

  observeEvent(input$btn_back_to_step2, {
    current_step(2)
  })

  search_results_data <- reactiveVal(tibble::tibble())

  observeEvent(input$btn_search, {
    req(input$search_query)
    withProgress(message = "Suche bei Spotify...", {
      res <- search_spotify_tracks(input$search_query, spotify_token())
      search_results_data(res)
    })
  })

  output$search_results_ui <- renderUI({
    res <- search_results_data()
    if (nrow(res) == 0) {
      return(p(
        class = "text-muted text-center py-3",
        "Keine Lieder gefunden. Gib oben einen Suchbegriff ein."
      ))
    }

    div(
      style = "max-height: 500px; overflow-y: auto;",
      purrr::map(seq_len(nrow(res)), function(i) {
        track <- res[i, ]
        div(
          class = "card mb-2 p-2",
          div(
            class = "d-flex justify-content-between align-items-center",
            div(
              style = "max-width: 75%;",
              strong(track$title),
              br(),
              span(
                class = "text-muted small",
                paste(track$artist, "•", track$release_year)
              )
            ),
            actionButton(
              inputId = paste0("add_song_", track$id),
              label = "+ Hinzufügen",
              class = "btn-sm btn-outline-primary",
              onclick = sprintf(
                "Shiny.setInputValue('add_song_click', '%s', {priority: 'event'});",
                track$id
              )
            )
          )
        )
      })
    )
  })

  observeEvent(input$add_song_click, {
    track_id <- input$add_song_click
    track_to_add <- search_results_data() |> filter(id == track_id)

    if (nrow(track_to_add) == 1) {
      current <- selected_songs()
      if (track_id %in% current$id) {
        showNotification(
          "Dieser Song ist bereits in deiner Liste!",
          type = "warning"
        )
        return()
      }
      if (nrow(current) >= 10) {
        showNotification(
          "Du hast bereits 10 Songs ausgewählt! Bitte entferne zuerst einen Song.",
          type = "error"
        )
        return()
      }
      selected_songs(bind_rows(current, track_to_add))
    }
  })

  observeEvent(input$remove_song_click, {
    selected_songs(selected_songs() |> filter(id != input$remove_song_click))
  })

  output$song_count_badge <- renderText({
    paste0(nrow(selected_songs()), " / 10 Songs")
  })

  # --- Die sortierbare Liste rendern (Mit Rang-Update-Mechanik) ---
  output$sortable_songs_list <- renderUI({
    songs <- selected_songs()
    if (nrow(songs) == 0) {
      return(div(
        class = "alert alert-info text-center mt-3",
        "Noch keine Songs ausgewählt. Nutze die Suche links!"
      ))
    }

    items_html <- purrr::map(seq_len(nrow(songs)), function(i) {
      song <- songs[i, ]
      div(
        class = "song-item",
        `data-id` = song$id,
        div(
          class = "d-flex align-items-center",
          span(class = "drag-handle", "☰"),

          # Die .rank-badge Klasse sorgt für das farbige Badge mit der Zahl
          span(class = "rank-badge rank-display", i),

          div(
            strong(song$title),
            br(),
            span(
              class = "text-muted small",
              paste(song$artist, "•", song$release_year)
            )
          )
        ),
        div(
          a(
            href = song$spotify_url,
            target = "_blank",
            class = "btn btn-sm btn-outline-secondary me-1",
            title = "Auf Spotify anhören",
            icon("spotify")
          ),
          actionButton(
            paste0("remove_", song$id),
            "✕",
            class = "btn btn-sm btn-outline-danger",
            onclick = sprintf(
              "Shiny.setInputValue('remove_song_click', '%s', {priority: 'event'});",
              song$id
            )
          )
        )
      )
    })

    tagList(
      div(id = "sortable_song_container", items_html),
      sortable_js(
        css_id = "sortable_song_container",
        options = sortable_options(
          onUpdate = htmlwidgets::JS(
            "
            function(evt) {
              // 1. Hole alle Elemente in der neuen Reihenfolge
              var container = document.getElementById('sortable_song_container');
              var children = Array.from(container.children);

              // 2. Passe die angezeigten Zahlen in den Badges dynamisch an
              children.forEach(function(el, index) {
                var badge = el.querySelector('.rank-display');
                if (badge) {
                  badge.innerText = index + 1;
                }
              });

              // 3. Sende die neue Reihenfolge-ID-Liste an den R Server
              var order = children.map(function(el) { return el.getAttribute('data-id'); });
              Shiny.setInputValue('reordered_song_ids', order, {priority: 'event'});
            }
          "
          )
        )
      )
    )
  })

  observeEvent(input$reordered_song_ids, {
    new_order_ids <- input$reordered_song_ids
    current <- selected_songs()
    if (length(new_order_ids) == nrow(current)) {
      reordered <- current |> slice(match(new_order_ids, id))
      selected_songs(reordered)
    }
  })

  # --- Submit Finale Liste ---
  observeEvent(input$btn_submit_final, {
    songs <- selected_songs()
    if (nrow(songs) == 0) {
      showModal(modalDialog(
        title = "Keine Songs gewählt",
        "Bitte wähle mindestens einen Song aus.",
        easyClose = TRUE
      ))
      return()
    }
    if (nrow(songs) > 10) {
      songs <- head(songs, 10)
    }

    guest_info <- list(
      email = user_data$email,
      name = user_data$name,
      birth_year = user_data$birth_year,
      state = user_data$state
    )

    withProgress(message = "Speichere deine Liste in der Datenbank...", {
      tryCatch(
        {
          save_guest_data_to_supabase(guest_info, songs)
          showModal(modalDialog(
            title = div(
              style = "color: #C05C7E;",
              "🎉 Vielen Dank für deine Musiktipps!"
            ),
            p(
              "Deine Top 10 Playliste für Susanne & Andreas wurde erfolgreich gespeichert."
            ),
            p(
              "Wir freuen uns darauf, deine Lieblingssongs auf der Hochzeit zu feiern!"
            ),
            easyClose = FALSE,
            footer = actionButton(
              "btn_finish_reload",
              "Fertigstellen",
              class = "btn-primary"
            )
          ))
        },
        error = function(e) {
          showModal(modalDialog(
            title = "Fehler beim Speichern",
            paste("Fehler:", e$message),
            easyClose = TRUE
          ))
        }
      )
    })
  })

  observeEvent(input$btn_finish_reload, {
    session$reload()
  })
}

shinyApp(ui = ui, server = server)
