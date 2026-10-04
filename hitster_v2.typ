#import "@preview/cades:0.3.1": qr-code
#import "@preview/cetz:0.3.1"

// Seiteneinrichtung (A4)
#set page(
  paper: "a4",
  margin: (x: 10mm, y: 12mm),
)

// --- KONFIGURATION ---
#let card-size = 65mm
#let bleed = 2mm // Toleranzbereich für Schnitt und Falz
#let card-color-back = rgb("e33b3b")  // Hitster-Rot
#let card-color-front = rgb("1a1a1a") // Dunkelgrau/Schwarz

// Hitster-Farbpalette für die Neon-Ringe
#let c-cyan    = rgb("00a8e8")
#let c-red     = rgb("e33b3b")
#let c-yellow  = rgb("fadd00")
#let c-purple  = rgb("9d4edd")

// Vorderseite: QR-Code mit versetzten, unterbrochenen Kreisbögen
// Vorderseite (QR-Code mit gestrichelten / unterbrochenen Neon-Ringen)
#let front-side(url) = {
  box(width: card-size + bleed, height: card-size + bleed * 2, fill: card-color-front, clip: true)[
    #align(center + horizon)[
      // Äußerer Ring (Cyan) – 2 große Abschnitte
      #place(center + horizon, circle(
        radius: 29mm,
        stroke: (paint: rgb("00a8e8"), thickness: 1.5pt, dash: (80pt, 25pt, 50pt, 25pt))
      ))
      
      // 2. Ring (Rot) – versetzt unterbrochen
      #place(center + horizon, rotate(40deg, circle(
        radius: 26mm,
        stroke: (paint: rgb("e33b3b"), thickness: 1.5pt, dash: (110pt, 30pt, 30pt, 20pt))
      )))
      
      // 3. Ring (Gelb)
      #place(center + horizon, rotate(-35deg, circle(
        radius: 23mm,
        stroke: (paint: rgb("fadd00"), thickness: 1.5pt, dash: (65pt, 20pt, 75pt, 25pt))
      )))
      
      // 4. Ring (Lila)
      #place(center + horizon, rotate(85deg, circle(
        radius: 20mm,
        stroke: (paint: rgb("9d4edd"), thickness: 1.5pt, dash: (80pt, 25pt, 40pt, 20pt))
      )))
      
      // Innerer Ring (Cyan / Akzent)
      #place(center + horizon, rotate(15deg, circle(
        radius: 17mm,
        stroke: (paint: rgb("00a8e8"), thickness: 1.5pt, dash: (50pt, 20pt, 40pt, 15pt))
      )))

      // QR-Code auf weißem Träger
      #rect(fill: white, inset: 2mm, radius: 1mm)[
        #qr-code(url, width: 22mm)
      ]
    ]
  ]
}

// Rückseite (Interpret oben, Jahr groß in der Mitte, Titel unten)
#let back-side(artist, title, year, top100, danceability) = {
  box(width: card-size + bleed, height: card-size + bleed * 2, fill: card-color-back, clip: true)[
    #set text(font: "Liberation Sans", fill: black)

    #align(center + horizon)[
      #v(6mm)
      #text(size: 13pt, weight: "medium")[#artist]

      #v(1fr)

      #text(size: 40pt, weight: "bold", tracking: -1pt)[#year]

      #v(1fr)

      #text(size: 11pt, style: "italic")[#title]
      #v(6mm)
    ]

    // Details in den Ecken
    #place(bottom + left, dx: 4mm, dy: -4mm)[
      #text(size: 6pt, weight: "bold", fill: rgb("222222"))[#top100]
    ]
    #if danceability != "NA" and danceability != "" [
      #place(bottom + right, dx: -4mm, dy: -4mm)[
        #text(size: 6pt, fill: rgb("333333"))[#danceability]
      ]
    ]
  ]
}

// Karte mit Schnittmarken und Falzlinie
#let make-card(artist, title, year, url, top100, danceability) = {
  let w = card-size + bleed
  let h = card-size + bleed * 2

  box(width: w * 2 + 10mm, height: h + 10mm)[
    #align(center + horizon)[
      #grid(
        columns: (w, w),
        front-side(url),
        back-side(artist, title, year, top100, danceability)
      )
    ]

    // Äußere Schnittmarken
    #place(top + left, dx: 5mm, dy: 0mm, line(length: 4mm, stroke: 0.4pt))
    #place(top + left, dx: 0mm, dy: 5mm, line(length: 4mm, angle: 90deg, stroke: 0.4pt))

    #place(top + right, dx: -5mm, dy: 0mm, line(length: 4mm, stroke: 0.4pt))
    #place(top + right, dx: 0mm, dy: 5mm, line(length: 4mm, angle: 90deg, stroke: 0.4pt))

    #place(bottom + left, dx: 5mm, dy: 0mm, line(length: 4mm, stroke: 0.4pt))
    #place(bottom + left, dx: 0mm, dy: -5mm, line(length: 4mm, angle: 90deg, stroke: 0.4pt))

    #place(bottom + right, dx: -5mm, dy: 0mm, line(length: 4mm, stroke: 0.4pt))
    #place(bottom + right, dx: 0mm, dy: -5mm, line(length: 4mm, angle: 90deg, stroke: 0.4pt))

    // Gestrichelte Faltlinie in der Mitte
    #place(top + center, dy: 0mm)[
      #line(length: h + 10mm, angle: 90deg, stroke: (paint: luma(120), thickness: 0.5pt, dash: "dashed"))
    ]
  ]
}

// --- CSV EINLESEN ---
#let raw-data = csv("S&A Top100_manual_sort_short.csv")
#let headers = raw-data.at(0).map(h => h.trim())
// #let data-rows = raw-data.slice(1)
#let data-rows = raw-data.slice(1, 5)

#let get(row, col-name, fallback: "") = {
  let idx = headers.position(h => h == col-name)
  if idx != none and idx < row.len() {
    let val = row.at(idx).trim()
    if val != "" { val } else { fallback }
  } else {
    fallback
  }
}

// Grid-Ausgabe der Karten
#grid(
  columns: (1fr),
  row-gutter: 4mm,
  ..data-rows.map(row => {
    let artist = get(row, "artist", fallback: "Unbekannt")
    let title = get(row, "title", fallback: "Unbekannt")
    let year = get(row, "release_year", fallback: "—")
    let url = get(row, "spotify_url", fallback: "https://spotify.com")
    let top100 = get(row, "Top 100 Konsolidiert", fallback: "")
    let danceability = get(row, "Danceability", fallback: "")

    make-card(artist, title, year, url, top100, danceability)
  })
)