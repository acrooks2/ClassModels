extensions [ gis csv ]
globals [ county-dataset district-dataset pop-dataset distinct-census-tracts distinct-districts results-dataset valid-patches total-satisfaction district-size-stdev-val]
patches-own [ district precinct redweight blueweight is-covered pop preferred-centroid census-tract census-tract-population census-tract-share]
;;breed [ county-vertices county-vertex ]
;;breed [ district-vertices district-vertex ]
breed [ voters voter ]
breed [ centroids centroid ]
centroids-own [ district-number share ]
voters-own [ district-number party pred pblue will-vote]

;*********SETUP*********
to setup
  clear-all
  set district-size-stdev-val 0
  set distinct-districts ["0"]
  ask patches [
    set pcolor black
    set district "0"
    set precinct "0"
    set is-covered 1
    set redweight 1
    set blueweight 1
  ]

  setup-gis
  color-patches
  populate-map
  show "Setup complete."
  reset-ticks

end
to setup-gis

  show "Loading GIS data..."

  set county-dataset gis:load-dataset "Data/OrangeCountyBorder.shp"
  set results-dataset gis:load-dataset "Data/OrangeCounty2016Results.shp"
  set pop-dataset gis:load-dataset "Data/Population2017.shp"

  if district-choice = 2009 [
    set district-dataset gis:load-dataset "Data/OrangeCountyDistricts2009.shp"
  ]
  if district-choice = 2011 [
    set district-dataset gis:load-dataset "Data/OrangeCountyDistricts2011.shp"
  ]

  show "Mapping patches to districts..."
  gis:apply-coverage district-dataset "DISTRICT" district

  let coverage patches gis:intersecting district-dataset
  ask patches [
    if not member? self coverage [
      set district "0"
      set pcolor black
      set precinct "0"
      set is-covered 0
    ]
  ]
  get-distinct-districts

  show "Mapping 2016 results..."
  gis:apply-coverage results-dataset "PRES_CLINT" blueweight
  gis:apply-coverage results-dataset "PRES_TRUMP" redweight
  gis:apply-coverage results-dataset "VOTINGP" precinct

  show "Mapping Census..."
  gis:apply-coverage pop-dataset "HD01_VD01" census-tract-population
  gis:apply-coverage pop-dataset "NAME" census-tract

  show "Cleaning-up GIS"
  ;;deal with nulls and NaN from GIS import
  ask patches with [is-covered = 1][
    ;;deal with nulls and NaN from GIS import
    carefully [if empty? redweight [ set redweight 0]][]
    carefully [if empty? blueweight [ set blueweight 0]][]
    carefully [if not is-number? redweight [ set redweight 0]][]
    carefully [if not is-number? blueweight [ set blueweight 0]][]
    carefully [
      ifelse(redweight <= 0) or (redweight >= 0)[][ set redweight 0]
    ][]
    carefully [
      ifelse(blueweight <= 0) or (blueweight >= 0)[][ set blueweight 0]
    ][]
  ]

  color-patches
  show "Done mapping."
end
;;REMOVE NOT-A-NUMBER ERRRORS FROM GIS IMPORT
to remove-nan
  let i 1
  foreach distinct-districts [[?] ->
    carefully [
      if ? < "00" []
    ][
      set distinct-districts remove-item i distinct-districts
    ]
  ]
end
;;POPULATION DISTRIBUTION
;;FROM EMPIRICAL SOURCE
to get-distinct-census-tracts
  ;;in case this has been cleared, revalidate valid patches -- it's cheap
  setup-valid-patches
  set distinct-census-tracts []
  ask valid-patches [
    set distinct-census-tracts lput census-tract distinct-census-tracts
  ]
  set distinct-census-tracts remove-duplicates distinct-census-tracts
end
;;COLOR EMPIRICAL DISTRICTS (DOES NOT APPLY TO REDISTRICTING)
to get-distinct-districts
  set distinct-districts []
  ask patches with[is-covered = 1] [
    set distinct-districts lput district distinct-districts
  ]
  set distinct-districts remove-duplicates distinct-districts
  set distinct-districts remove "0" distinct-districts
end

to color-patches
  let colortest 45
  let this-district "0"
  show "Coloring patches..."
  foreach distinct-districts [[?] ->
    carefully [
    ask patches with [is-covered = 1 and district = (word ?)] [ set pcolor colortest ]
    set colortest colortest + 10
    ][

    ]
  ]
  ;;OUTSIDE MAP
  ;;ensure no district or precinct
  ask patches with [pcolor = black][
    set district "0"
    set precinct "0"
  ]
  remove-nan
  ;;refresh distinct districts
  get-distinct-districts
  show "Done coloring patches."
end
to populate-map
  show "Populating map..."
  ask voters [die]
  setup-valid-patches
  get-distinct-census-tracts
  let p 0
  let i length distinct-census-tracts - 1

  ;;get population
  while [i > 0] [
    ask one-of patches with [census-tract = item i distinct-census-tracts][
      set p p + census-tract-population
    ]
   set i i - 1
  ]
  show p
  ;;get representative voter count at 1/1000 scale
  let voter-count round (p / 1000)

  ;;distribute population according to census share by tract
  set i length distinct-census-tracts - 1

  while [i > 0] [
    ask one-of valid-patches with [census-tract = item i distinct-census-tracts][
      let test-n round(census-tract-population / 1000)
      sprout-voters test-n [
        set size 8
        set party random 2
        set district-number [district] of myself
        set-affinity
        set heading random 360
      ]
    ]
   set i i - 1
  ]


end
to set-affinity
  ifelse empirical-partisanship [
      carefully [
        set pred [redweight] of patch-here
        set pblue [blueweight] of patch-here
      ][
        set pred 50
        set pblue 50
      ]
    ][
      set pred 50
      set pblue 50
    ]
    let p pred + pblue + 1
    ifelse random p <= pred [
      set color red
      set party 0
    ][
      set color blue
      set party 1
    ]
    voter-turnout
end
to voter-turnout
  let myturnout random 100
  ifelse myturnout <= turnout [
    set will-vote 1
  ][
    set will-vote 0
  ]
end
to move-voters
  show "Distributing voters..."
  ask voters [
    let my-district district
    move-to one-of patches with [district = my-district and (redweight > 0 or blueweight > 0)]
    ;set district-number [district] of patch-here
    set-affinity
  ]
  show "Done moving."
end
to go
  ;;voters move within district, this adds some variance based on precinct affinity between polls
  ifelse ticks < max-ticks [
    move-voters

    foreach distinct-districts [[?] ->

      let redcount count voters with [district-number = ? and color = red]
      let bluecount count voters with [district-number = ? and color = blue]

      ifelse redcount > bluecount [
        ask patches with [ district = ? ] [
          set pcolor red
        ]
      ][
        ask patches with [district = ?] [
          set pcolor blue
        ]
      ]
    ]
    set total-satisfaction voter-satisfaction
    tick
  ][
    dumpresults
    stop
  ]
end

;;precint-level results for 2016 presidential
to shade-2016-results
  ask patches with [is-covered = 1][
    ifelse redweight + blueweight > 0 [
      ifelse redweight > blueweight [
        set pcolor red
      ][
        set pcolor blue
      ]
    ]
    [
      set pcolor black
    ]
  ]
end

to-report red-districts
  let _uniquedistricts remove-duplicates [district-number] of voters with [color = red and pcolor = red]
  report length _uniquedistricts
end

to-report blue-districts
  let _uniquedistricts remove-duplicates [district-number] of voters with [color = blue and pcolor = blue]
  report length _uniquedistricts
end
;*********REDISTRICTING
;
to setup-behaviorspace-redistrict
  clear-all
  set distinct-districts ["0"]
  ask patches [
    set pcolor black
    set district "0"
    set precinct "0"
    set is-covered 1
    set redweight 1
    set blueweight 1
  ]

  setup-gis
  color-patches
  populate-map
  show "Preliminatry setup complete."
  setup-redistrict
end
to setup-redistrict
  set district-size 711
  let n ceiling (count voters / district-size)
  reset-ticks
  clear-districts
  setup-valid-patches
  setup-hotellings-centroids n
  choose-hotellings-centroid
  ask centroids [set share count voters with [district = [district] of myself]]
  while [n > 0] [
    set distinct-districts lput n distinct-districts
    set n n - 1
  ]
end
to go-redistrict
  let n ceiling (count voters / district-size)
  ifelse district-size-stdev > 25 and ticks < max-ticks [
    redistrict
    set total-satisfaction voter-satisfaction
    tick
  ][
    ask voters [ set-affinity ]
    set total-satisfaction voter-satisfaction
    dumpresults
    stop
  ]

end
;;;hotelling's law (roughly implemented)
to setup-valid-patches
  set valid-patches patches with [pcolor != black and is-covered = 1]
  ask valid-patches [set pop count voters-here]
end
to setup-hotellings-centroids [n]
  ask centroids [die]
  let test-district 1
  let test-color 15
  while [n > 0][
    create-centroids 1 [
      move-to one-of valid-patches
      set shape "circle"
      set size 10
      set color test-color
      set district test-district
    ]
    set test-color test-color + 10
    set test-district test-district + 1
    set n n - 1
  ]

end
to choose-hotellings-centroid
  ask valid-patches [
    let test-centroid min-one-of centroids [distance myself]
    set pcolor [color] of test-centroid
    set district [district] of test-centroid
  ]
end
to redistrict
  let n ceiling (count voters / district-size)
  if n > 0 [
    let threshold count voters / n
    ask centroids with [share < threshold] [
      if any? centroids with [share > [share] of myself] [
        ;;let target-centroids max-n-of 2 centroids with [share > [share] of myself][distance myself]
        face max-one-of centroids with [share > [share] of myself] [share]
        fd 2
      ]
    ]
    ask centroids with [share > threshold] [
      if any? centroids with [share < [share] of myself] [
        ;;let target-centroids max-n-of 2 centroids with [share > [share] of myself][distance myself]
        face min-one-of centroids with [share < [share] of myself] [share]
        set heading heading - 180
        fd 2
      ]
    ]
    ask centroids [
      if [district] of patch-here = "0" [
        move-to min-one-of valid-patches [distance myself]
      ]
    ]

    choose-hotellings-centroid
    ask voters [ set district [district] of patch-here]
    ask centroids [set share count voters with [district = [district] of myself]]
  ]
  ;;ask centroids [show district]
  ;;ask centroids [show share]
end
;;utility / output functions
to clear-districts
  set distinct-districts []
  ask patches with [ district != "0" ][
    set pcolor 5
    set district "TBD"
  ]
  ask patches with [ district = "0"][set pcolor black]
end
to-report voter-satisfaction
  let i length distinct-districts
  let satisfaction 0
  let satisfied 0
  let dissatisfied 0

  while [i > 0] [
    let item-value item (i - 1) distinct-districts
    let v0 count voters with [district = item-value and party = 0 and will-vote = 1]
    let v1 count voters with [district = item-value  and party = 1 and will-vote = 1]
    let p0 count voters with [district = item-value  and party = 0 ]
    let p1 count voters with [district = item-value  and party = 1 ]

    if v0 > v1 [
      set satisfied satisfied + p1
      set dissatisfied dissatisfied + p0
    ]
    if v0 < v1 [
      set satisfied satisfied + p0
      set dissatisfied dissatisfied + p1
    ]
    if (satisfied + dissatisfied) != 0 [
      set satisfaction satisfied / (satisfied + dissatisfied)
    ]
    set i i - 1
  ]
  report satisfaction * 100
end
to-report district-size-stdev
  let n length distinct-districts
  ifelse (n > 0) [
    let test-mean (sum [share] of centroids) / n
    let diff-mean 0
    let i n
    while [i > 0] [
      set diff-mean diff-mean + (sum [share] of centroids with [district = i] - test-mean) ^ 2
      set i i - 1
    ]
    set n length distinct-districts
    if n > 1 [
      set district-size-stdev-val sqrt((1 / (n - 1)) * diff-mean)
      report district-size-stdev-val
    ]
  ][

  ]
end
;; utility function return true if not-a-number
to-report isNaN [x]
  report not (x > 0 or x < 0 or x = 0)
end
to dumpresults
  if results-output [
    export-interface (word "results/interface_" date-and-time ".png")
    export-view (word "results/view_" date-and-time ".png")
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
719
520
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-250
250
-250
250
1
1
1
ticks
30.0

BUTTON
4
188
70
221
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
67
20
205
65
district-choice
district-choice
2009 2011
0

INPUTBOX
4
304
81
364
district-size
711.0
1
0
Number

MONITOR
7
464
141
509
number of districts
length distinct-districts
0
1
11

MONITOR
5
368
140
413
agents
count voters
17
1
11

MONITOR
6
416
140
461
Effective Population
count voters * 1000
0
1
11

MONITOR
68
512
125
557
party 1
count voters with [party = 1]
0
1
11

MONITOR
7
512
64
557
party 0
count voters with [party = 0]
0
1
11

BUTTON
74
188
137
221
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
727
14
887
134
Satisfaction
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-satisfaction"

BUTTON
141
187
204
220
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
372
531
483
564
NIL
move-voters
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
6
71
203
104
empirical-partisanship
empirical-partisanship
0
1
-1000

SLIDER
6
109
202
142
turnout
turnout
0
100
24.0
1
1
NIL
HORIZONTAL

BUTTON
212
531
369
564
NIL
shade-2016-results
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
618
532
737
565
NIL
clear-districts
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
4
259
113
299
setup redistrict
setup-redistrict
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
116
258
206
300
redistrict
go-redistrict
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
724
187
905
307
district size
NIL
NIL
0.0
1000.0
0.0
1.0
true
true
"" ""
PENS
"districts" 1.0 1 -16777216 true "" "histogram [share] of centroids"
"goal" 1.0 1 -2674135 true "" "histogram [711] "

PLOT
729
316
889
436
stdev district size
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot district-size-stdev-val"

MONITOR
758
135
864
180
NIL
total-satisfaction
2
1
11

SLIDER
6
145
202
178
max-ticks
max-ticks
0
1000
500.0
1
1
NIL
HORIZONTAL

BUTTON
487
531
615
564
repopulate map
populate-map
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
744
532
892
565
results-output
results-output
0
1
-1000

MONITOR
729
434
889
479
NIL
district-size-stdev
2
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <metric>length distinct-districts</metric>
    <metric>blue-districts</metric>
    <metric>red-districts</metric>
    <metric>count voters with [party = 0]</metric>
    <metric>count voters with [party = 1]</metric>
    <metric>(count turtles with [pcolor = color] / count turtles) * 100</metric>
    <enumeratedValueSet variable="turnout">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="district-size">
      <value value="711"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="district-choice">
      <value value="2011"/>
      <value value="2009"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="empirical-partisanship">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-empirical" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="10"/>
    <metric>total-satisfaction</metric>
    <metric>count voters with [party = 0 and will-vote = 1]</metric>
    <metric>count voters with [party = 1 and will-vote = 1]</metric>
    <enumeratedValueSet variable="turnout">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="district-size">
      <value value="711"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="district-choice">
      <value value="2009"/>
      <value value="2011"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="results-output">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="empirical-partisanship">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-redistrict" repetitions="100" runMetricsEveryStep="false">
    <setup>setup-behaviorspace-redistrict</setup>
    <go>go-redistrict</go>
    <timeLimit steps="500"/>
    <metric>total-satisfaction</metric>
    <metric>count voters with [party = 0 and will-vote = 1]</metric>
    <metric>count voters with [party = 1 and will-vote = 1]</metric>
    <enumeratedValueSet variable="turnout">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="district-size">
      <value value="711"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="district-choice">
      <value value="2011"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="results-output">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="empirical-partisanship">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ticks">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
