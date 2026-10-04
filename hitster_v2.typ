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
#let c-cyan    = rgb("#0182b5")
#let c-red     = rgb("#cf244c")
#let c-orange  = rgb("#cd4a11")
#let c-yellow  = rgb("fadd00")
#let c-purple  = rgb("#562d4e")

// Vorderseite: QR-Code mit versetzten, unterbrochenen Kreisbögen
// Vorderseite (QR-Code mit gestrichelten / unterbrochenen Neon-Ringen)
// Hilfsfunktion: Zeichnet einen Kreis mit genau einer Lücke
#let broken-ring(r, gap-deg, stroke-color, rot) = {
  // Umfang berechnen: 2 * pi * r
  let circum = 2 * calc.pi * r
  let gap-len = (gap-deg / 360deg) * circum
  let dash-len = circum - gap-len

  place(center + horizon, rotate(rot, circle(
    radius: r,
    stroke: (
      paint: stroke-color,
      thickness: 1.6pt,
      dash: (dash-len, gap-len)
    )
  )))
}

// Vorderseite (QR-Code mit Neon-Ringen, jeweils genau 1 Lücke)
// Vorderseite (QR-Code mit 8 Neon-Ringen, jeweils genau 1 Lücke)
#let front-side(url) = {
  box(width: card-size + bleed, height: card-size + bleed * 2, fill: card-color-front, clip: true)[
    #align(center + horizon)[
      
      // 8 Ringe von außen nach innen, jeweils um ~2 mm versetzt:
      #broken-ring(29.0mm, 50deg, c-red,    75deg)
      #broken-ring(27.0mm, 50deg, c-cyan,   265deg)
      #broken-ring(25.0mm, 42deg, c-yellow,   20deg)
      #broken-ring(23.0mm, 55deg, c-red,  200deg)
      #broken-ring(21.0mm, 30deg, c-purple,    15deg)
      #broken-ring(19.0mm, 40deg, c-orange,      200deg)
      #broken-ring(17.0mm, 55deg, c-cyan,  120deg)
      #broken-ring(15.0mm, 90deg, c-yellow,  0deg)

      // QR-Code auf weißem Träger
      #rect(fill: white, inset: 2mm, radius: 1mm)[
        #qr-code(url, width: 22mm)
      ]
    ]
  ]
}
// Farbpalette für die Rückseiten (sattes Rot wie beim Original plus kontraststarke helle/mittlere Töne)
#let back-colors = (
  rgb("e33b3b"), // 1. Hitster-Klassik-Rot
  rgb("ff7a33"), // 2. Kräftiges Orange
  rgb("#c79901"), // 3. Sonnengelb
  rgb("4ecdc4"), // 4. Helles Türkis / Mint
  rgb("7bc043"), // 5. Frisches Maigrün
  rgb("b388eb"), // 6. Pastell-Lila / Flieder
  rgb("ff85a1"), // 7. Kräftiges Rosa / Koralle
  rgb("64b5f6"), // 8. Himmelblau
)

// Rückseite mit dynamischer Hintergrundfarbe
#let back-side(artist, title, year, top100, danceability, bg-color) = {
  box(width: card-size + bleed, height: card-size + bleed * 2, fill: bg-color, clip: true)[
    #set text(font: "Liberation Sans", fill: black)

    #align(center + horizon)[
      #v(8mm)
      // Artist oben
      #text(size: 14pt, weight: "bold")[#artist]

      #v(1fr)

      // Release Year (groß in der Mitte)
      #text(size: 65pt, weight: "bold", tracking: -1pt)[#year]

      #v(1fr)

      // Songtitel unten kursiv
      #text(size: 14pt, style: "italic")[#title]
      #v(8mm)
    ]

    // Details in den Ecken
    #place(bottom + left, dx: 4mm, dy: -4mm)[
      #text(size: 6pt, weight: "bold", fill: rgb("#ffffff"))[#top100]
    ]
    #if danceability != "NA" and danceability != "" [
      #place(bottom + right, dx: -4mm, dy: -4mm)[
        #text(size: 6pt, fill: rgb("333333"))[#danceability]
      ]
    ]
  ]
}
#let make-card(artist, title, year, url, top100, danceability, bg-color) = {
  let w = card-size + bleed
  let h = card-size + bleed * 2

  box(width: w * 2 + 10mm, height: h + 10mm)[
    #align(center + horizon)[
      #grid(
        columns: (w, w),
        front-side(url),
        back-side(artist, title, year, top100, danceability, bg-color)
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
#let data-rows = raw-data.slice(1, 4)

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
  ..data-rows.enumerate().map(((idx, row)) => {
    let artist = get(row, "artist", fallback: "Unbekannt")
    let title = get(row, "title", fallback: "Unbekannt")
    let year = get(row, "release_year", fallback: "—")
    let url = get(row, "spotify_url", fallback: "https://spotify.com")
    let top100 = get(row, "Top 100 Konsolidiert", fallback: "")
    let danceability = get(row, "Danceability", fallback: "")

    // Rotiert zyklisch durch die Farbpalette
    let bg-color = back-colors.at(calc.rem(idx, back-colors.len()))

    make-card(artist, title, year, url, top100, danceability, bg-color)
  })
)