---
pagetitle: Gesellschaftsmonitoring COVID19, Daten Pädagogische Hochschule Zürich
---

![](https://github.com/bildungsmonitoringZH/bildungsmonitoringZH.github.io/raw/master/assets/ktzh_bi_logo_de-300x88.jpg)
![](https://github.com/bildungsmonitoringZH/bildungsmonitoringZH.github.io/raw/master/assets/phzh_logo-300x88.jpg)

# Gesellschaftsmonitoring COVID19, Daten Pädagogische Hochschule Zürich

Daten zur Nutzung  im Rahmen des Projekts [Gesellschaftsmonitoring COVID19](https://statistikzh.github.io/covid19monitoring/)

## Datenlieferant

Pädagogische Hochschule Zürich

## Beteiligte

Pascal Schmitt <pascal.schmitt@phzh.ch>, Pädagogische Hochschule Zürich

Flavian Imlig <flavian.imlig@bi.zh.ch>, Bildungsdirektion

## Indikatorenbeschreibung

### Nutzung der Lernplattform ILIAS, durchschnittliche parallele Sessions

ILIAS ist die Lernplattform für Aus- und Weiterbildung der PHZH. Sie wird genutzt von den Dozierenden und den Studierenden.

Der Indikator beschreibt durchschnittliche Anzahl paralleler Sessions auf ILIAS. Diese Anzahl entspricht ungefähr dem Durchschnittswert der gleichzeitig eingeloggten, aktiven Benutzer im Tagesverlauf. Aktiv heisst, dass innerhalb von 5 Minuten mindestens einmal geklickt wurde. Der Indikator zeigt damit die Intensität der Nutzung.

Die Zeitreihe beginnt am 1. August 2019 und damit vor dem Beginn des Herbstsemesters 2019.

Aus technischen Gründen müssen die Daten im Zeitraum von 7. Oktober bis 1. November 2020 ausgeschlossen werden.

## Vorgehen

* Export der _Session Statistics_ aus ILIAS
* manueller Upload ins Verzeichnis `data_ilias`
* R-Skript `prepareILIASdata.R` zum Generieren der erforderlichen Datenstruktur, automatisch ausgeführt nach dem Upload.