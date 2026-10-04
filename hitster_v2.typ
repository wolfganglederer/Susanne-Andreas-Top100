#import "@preview/cades:0.3.1": qr-code

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

// Vorderseite (QR-Code mit Neon-Ringen)
#let front-side(url) = {
  box(width: card-size + bleed, height: card-size + bleed * 2, fill: card-color-front, clip: true)[
    #align(center + horizon)[
      // Neon-Ringe im Hitster-Stil
      #place(center + horizon, circle(radius: 28mm, stroke: 1.5pt + rgb("00a8e8")))
      #place(center + horizon, circle(radius: 25mm, stroke: 1.5pt + rgb("e33b3b")))
      #place(center + horizon, circle(radius: 22mm, stroke: 1.5pt + rgb("fadd00")))
      #place(center + horizon, circle(radius: 19mm, stroke: 1.5pt + rgb("9d4edd")))
      #place(center + horizon, circle(radius: 16mm, stroke: 1.5pt + rgb("00a8e8")))
      
      // QR-Code mit weißem Träger
      #rect(fill: white, inset: 2mm, radius: 1mm)[
        #qr-code(url, width: 22mm)
      ]
    ]
  ]
}

// Rückseite (Interpret, großes Jahr, Titel & Metadaten)
#let back-side(artist, title, year, top100, danceability) = {
  box(width: card-size + bleed, height: card-size + bleed * 2, fill: card-color-back, clip: true)[
    #set text(font: "Liberation Sans", fill: black)
    
    #align(center + horizon)[
      #v(6mm)
      // Artist oben
      #text(size: 13pt, weight: "medium")[#artist]
      
      #v(1fr)
      
      // Release Year (groß in der Mitte)
      #text(size: 40pt, weight: "bold", tracking: -1pt)[#year]
      
      #v(1fr)
      
      // Songtitel unten kursiv
      #text(size: 11pt, style: "italic")[#title]
      #v(6mm)
    ]
    
    // Eckdaten (Hitster-Style)
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

// Kombinierte Faltkarte mit Schnitt- und Falzmarken
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
    
    // Schnittmarken Ecken
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
#let data-rows = raw-data.slice(1)

// Sichere Getter-Funktion (verhindert 'found none')
#let get(row, col-name, fallback: "") = {
  let idx = headers.position(h => h == col-name)
  if idx != none and idx < row.len() {
    let val = row.at(idx).trim()
    if val != "" { val } else { fallback }
  } else {
    fallback
  }
}

// Karten rendern
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