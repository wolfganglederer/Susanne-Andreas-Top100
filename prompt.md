# Aufgabe

Für eine Hochzeit soll eine Top 100 Playliste aus den Top de eingeladenen Gäste erstellt werden
Dazu wollen wir im vorhinein von den Gästen ihre Top 10 Lieder abfragen.

# Shiny App


Baue dazu eine Shiny App die auf posit https://connect.posit.cloud/ gehostet werden soll.

Es braucht einen Splash-Screen auf dem ein einfaches Passwort, das in der Einladungsemail mitversendet wird. Das muss nich super sicher sein, es soll nur nicht Gäste behindern

Die App soll schrittweise vorgehen und jede Seiter soll mit Weiter und zurück zum nächsten Schritt führen:

## 1. Schritt Erklärung

Stelle folgenden Text dar:

  Susanne und Andreas sind große Fans von [RadioEins Top 100](https://www.radioeins.de/musik/top_100/), deshalb wollen wir für sie zur Hochzeit eine eigene Top 100 Liste zum Thema:

  **Leibe geht durch den Magen** (Alle Songs zu Liebe, Essen und Trinken!)

  Wie gehts weiter:

    1. Gehe mit **weiter** zur nächsten Seite und gib dort ein paar Informationen über dich ein um Susannes Statistiker Seite zu erfreuen! (**weiter**)
    2. Auf der nächsten Seite wählst kannst du eine Song auf Sopotify suchen und ihn in die Tabelle daneben einfügen. Die Tabelle kannst du dann per drag and drop sortieren bis du damit zufrieden bist. (1 Bestes Lied , ...)
    3. Mit Liste Absenden, die Liste speichern und dann bist du auch schon fertig.


## 2. Schritt Demografische Abfragen

Frage folgende Informationen ab:

- Email-Adresse (eindeutiger Schlüssel)
- Namen
- Geburtsjahr
- Bundesland in dem man lebt (Auswahl der 16 deutschen Bundesländer + Österreich, Irland)


## 3. Schritt

Man wählt Lieder mittels der Spotify-Suche aus und kann sie in eine Tabelle einfügen. (Am besten eine DT-Tabelle)

- Diese Tabelle muss man umsortieren können. (Füge ein Sortier-Symbol ein mit dem man die Lieder per drag and drop sortieren kann)
- Es muss möglich sein, dass Lieder gelöscht werden.
- Überprüfe, ob es mehr als 10 Lieder sind. Entferne dann die überflüssigen Lieder
- In der Tabelle, sollt der Interpret, Der Titel, das ErscheinungsJahr und ein ein Link zu Spotify sein, dass man das Lied überprüfen kann (In einem Eigenen Tab).

Nachdem die Auswahl abgeschlossen ist, soll das Ergebnis in eine Supabase Datenbank geschrieben werden.

# Supabase

Schreibe bitte den Code für die Supabase Datenbank.

Die Environment Variablen:

SUPABASE_HOST="db.ojmcdtktzxgthnckagpg.supabase.co"
SUPABASE_PORT="6543"
SUPABASE_DBNAME="postgres"
SUPABASE_USER="postgres"
SUPABASE_PASSWORD="xxxxxxxxxxx"
SUPABASE_SCHEMA="public"


SUPABASE_URL="https://ojmcdtktzxgthnckagpg.supabase.co"
SUPABASE_PUBLISHABLE_KEY="xxxxxxxxxxxxxxxxxxxxx"
SUPABASE_SECRET_KEY="xxxxxxxxxxxxxxxxxxxxxxx"

sind vorhanden. 

Das Projekt heißt : S&A-Hochzeit

Direct connection STring ist: postgresql://postgres:[YOUR-PASSWORD]@db.ojmcdtktzxgthnckagpg.supabase.co:5432/postgres

- Es muss Email, Name, Geburtsjahr und Bundesland gespeichert werden.
- Es müssen die Top 10 von jedem Gast: Titel, Interpret, Erscheinungsjahr, Spotify-Link in einer Tabelle gespeichert werden.


# Hinweise

- Halte dich bitte an den tidyverse Style Guide
- Benutze das Tidyverse wenn möglich
- Kommentiere den Code wenn nötig. Kommentiere das warum, nicht das was.



Das Passwort kann man nicht mit Return absenden.
Bei zurück werden die demografischen Daten nicht mehr angezeigt. 
Es gibt in der Songauswahlt 2 Tabellen. Nur eine ist notwendig.
Wenn man mit drag and drop die Die Lieder umsortiert wird der Rang nicht angepasst
Es wäre schön wenn man die Suche mit Return starten könnte.
