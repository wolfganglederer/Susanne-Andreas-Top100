#import "@preview/cades:0.3.1": qr-code

// Seiteneinrichtung (A4)
#set page(
  paper: "a4",
  margin: (x: 10mm, y: 12mm),
)

// --- KONFIGURATION MASSE ---
#let card-size = 65mm
#let bleed = 2mm       // Farbiger Überstand an ALLEN 4 Seiten
#let gap = 12mm         // Abstand zwischen Vorder- und Rückseite
#let mark-len = 4mm    // Länge der Schnittmarken
#let mark-off = 3mm    // 3mm Offset > 2mm Bleed -> ragt nicht in die Farbe!

// --- FARBEN ---
#let card-color-back = rgb("e33b3b")
#let card-color-front = rgb("1a1a1a")

// Hitster-Farbpalette für die Neon-Ringe
#let c-cyan    = rgb("#0182b5")
#let c-red     = rgb("#cf244c")
#let c-orange  = rgb("#cd4a11")
#let c-yellow  = rgb("fadd00")
#let c-purple  = rgb("#562d4e")

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

// --- VORDERSEITE ---
#let broken-ring(r, gap-deg, stroke-color, rot) = {
  let circum = 2 * calc.pi * r
  let gap-len = (gap-deg / 360deg) * circum
  let dash-len = circum - gap-len

  place(center + horizon, rotate(rot, circle(
    radius: r,
    stroke: (paint: stroke-color, thickness: 1.6pt, dash: (dash-len, gap-len))
  )))
}

#let front-side(url) = {
  box(width: card-size + bleed * 2, height: card-size + bleed * 2, fill: card-color-front, clip: true)[
    #align(center + horizon)[
      #broken-ring(29.0mm, 50deg, c-red,      75deg)
      #broken-ring(27.0mm, 50deg, c-cyan,    265deg)
      #broken-ring(25.0mm, 42deg, c-yellow,   20deg)
      #broken-ring(23.0mm, 55deg, c-red,     200deg)
      #broken-ring(21.0mm, 30deg, c-purple,   15deg)
      #broken-ring(19.0mm, 40deg, c-orange,  200deg)
      #broken-ring(17.0mm, 55deg, c-cyan,    120deg)
      #broken-ring(15.0mm, 90deg, c-yellow,    0deg)

      #rect(fill: white, inset: 0mm, radius: 0mm)[
        #qr-code(url, width: 22mm)
      ]
    ]
  ]
}

// --- RÜCKSEITE ---
#let back-side(artist, title, year, top100, danceability, bg-color) = {
  box(width: card-size + bleed * 2, height: card-size + bleed * 2, fill: bg-color, clip: true)[
    #set text(font: "Liberation Sans", fill: black)

    #align(center + horizon)[
      #box(width: card-size, height: card-size)[
        #align(center + horizon)[
          #v(8mm)
          #text(size: 14pt, weight: "bold")[#artist]
          #v(1fr)
          #text(size: 65pt, weight: "bold", tracking: -1pt)[#year]
          #v(1fr)
          #text(size: 14pt, style: "italic")[#title]
          #v(8mm)
        ]

        #place(bottom + left, dx: 4mm, dy: -4mm)[
          #text(size: 6pt, weight: "bold", fill: rgb("#ffffff"))[#top100]
        ]
        #if danceability != "NA" and danceability != "" [
          #place(bottom + right, dx: -4mm, dy: -4mm)[
            #text(size: 6pt, fill: rgb("333333"))[#danceability]
          ]
        ]
      ]
    ]
  ]
}

// --- SCHNITTMARKEN HELFER ---
#let crop-marks(x, y, w, h) = {
  // Oben Links
  place(top + left, dx: x - mark-off - mark-len, dy: y, line(length: mark-len, stroke: 0.35pt))
  place(top + left, dx: x, dy: y - mark-off - mark-len, line(length: mark-len, angle: 90deg, stroke: 0.35pt))
  // Oben Rechts
  place(top + left, dx: x + w + mark-off, dy: y, line(length: mark-len, stroke: 0.35pt))
  place(top + left, dx: x + w, dy: y - mark-off - mark-len, line(length: mark-len, angle: 90deg, stroke: 0.35pt))
  // Unten Links
  place(top + left, dx: x - mark-off - mark-len, dy: y + h, line(length: mark-len, stroke: 0.35pt))
  place(top + left, dx: x, dy: y + h + mark-off, line(length: mark-len, angle: 90deg, stroke: 0.35pt))
  // Unten Rechts
  place(top + left, dx: x + w + mark-off, dy: y + h, line(length: mark-len, stroke: 0.35pt))
  place(top + left, dx: x + w, dy: y + h + mark-off, line(length: mark-len, angle: 90deg, stroke: 0.35pt))
}

// --- KARTE ZUSAMMENBAUEN ---
#let make-card(artist, title, year, url, top100, danceability, bg-color) = {
  let front-x = mark-len + mark-off + bleed
  let front-y = mark-len + mark-off + bleed
  let back-x  = front-x + card-size + gap
  let back-y  = front-y

  let box-w = back-x + card-size + bleed + mark-off + mark-len
  let box-h = front-y + card-size + bleed + mark-off + mark-len

  box(width: box-w, height: box-h)[
    #place(top + left, dx: front-x - bleed, dy: front-y - bleed)[
      #front-side(url)
    ]
    #place(top + left, dx: back-x - bleed, dy: back-y - bleed)[
      #back-side(artist, title, year, top100, danceability, bg-color)
    ]

    #crop-marks(front-x, front-y, card-size, card-size)
    #crop-marks(back-x, back-y, card-size, card-size)

    // Durchgängige Faltlinie im Spalt (von ganz oben bis ganz unten)
    #let fold-x = front-x + card-size + gap / 2
    #place(top + left, dx: fold-x, dy: 0mm)[
      #line(length: box-h, angle: 90deg, stroke: (paint: luma(120), thickness: 0.5pt))
    ]
  ]
}

// --- CSV EINLESEN ---
#let raw-data = csv("S&A Top100_manual_sort_short.csv")
#let headers = raw-data.at(0).map(h => h.trim())
#let data-rows = raw-data.slice(1, 3)

#let get(row, col-name, fallback: "") = {
  let idx = headers.position(h => h == col-name)
  if idx != none and idx < row.len() {
    let val = row.at(idx).trim()
    if val != "" { val } else { fallback }
  } else {
    fallback
  }
}

// --- KARTEN GENERIEREN ---
#grid(
  columns: (1fr),
  row-gutter: 8mm,
  ..data-rows.enumerate().map(((idx, row)) => {
    let artist = get(row, "artist", fallback: "Unbekannt")
    let title = get(row, "title", fallback: "Unbekannt")
    let year = get(row, "release_year", fallback: "—")
    let url = get(row, "spotify_url", fallback: "https://spotify.com")
    let top100 = get(row, "Top 100 Konsolidiert", fallback: "")
    let danceability = get(row, "Danceability", fallback: "")

    let bg-color = back-colors.at(calc.rem(idx, back-colors.len()))
    make-card(artist, title, year, url, top100, danceability, bg-color)
  })
)