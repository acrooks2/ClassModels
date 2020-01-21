; --------------
; INITIAL SETUP
; --------------

extensions [gis table]
globals [
  countries-dataset  ; The GIS dataset
  flag               ; Used to note when the model stops changing.
  iteration
  ]

patches-own [country-name]

breed [states state] ; Class of States -- our basic agents.
states-own [
  name           ; The state's name.
  key-feature    ; The state's predominant map feature (usually the state itself, if it's contiguous).

  score          ; Cumulative score
  init-score     ; Starting score

  change-count   ; How many times the state has changed status.

  play-table     ; A table holding each state's play on each of it's neighbors.
  hegemon        ; TRUE if the state is a hegemon; otherwise false.
  init-hegemon   ; The state's initial hegemon value.
  next-strongest ; The next-strongest neighbor.
  next-weakest   ; The next-weakest neighbor.
  ranking        ; The state's relative ranking among its neighbors (1 == lowest).

]

; ----------------
; SETUP PROCEDURES
; -----------------

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  load-data
  draw-countries
  generate-states
  build-network
  expand-network
  clean-up-network
end

to load-data
  ; GIS data and code for loading it taken from
  ; "GIS General Examples," NetLogo Model Library, Wilensky 2008
  set countries-dataset gis:load-dataset "data/countries.shp"
  gis:set-world-envelope (gis:envelope-of countries-dataset)

  ; Assign each patch the name of its country
  gis:apply-coverage countries-dataset "SOVEREIGN" country-name
end

to draw-countries
  ; Taken from "GIS General Examples," NetLogo Model Library, Wilensky 2008
  gis:set-drawing-color white
  gis:draw countries-dataset 1
end

to generate-states
  ; Loop over all features and create one agent per sovereign.
  foreach gis:feature-list-of countries-dataset [ ?1 ->
    ifelse any? states with [name = gis:property-value ?1 "SOVEREIGN"]
    ;If true, Do this:
    [
      ; If the new feature name is the same as the Sovereig (this is the home territory)
      ask states with [name = gis:property-value ?1 "SOVEREIGN"] [
        if gis:property-value ?1 "CNTRY_NAME" = gis:property-value key-feature "SOVEREIGN"
        [
          let location gis:location-of gis:centroid-of ?1
          set xcor item 0 location
          set ycor item 1 location
         ]
      ]
    ]

    ; Otherwise, do this:
    ; Create a new State agent:
    [
      create-states 1 [
        ; Initialize geographic properties:
        set key-feature ?1
        set name gis:property-value key-feature "SOVEREIGN" ; Set the state name based on the feature.
        ; Set the coordinates as the centroid
        let location gis:location-of gis:centroid-of ?1
        set xcor item 0 location
        set ycor item 1 location

        ; Initialize non-geospatial properties:
        set play-table table:make ; Initialize the new table.
        set score 0               ; Set the starting score.
        set hegemon false         ; All states start out as non-hegemonic.
        set ranking -1            ; States have no default rank.

        ; Set appearance:
        set shape "circle"
        set size 5
        set color gray

      ]
    ]

  ]

end

to build-network
  ; Build the mutual border network
  ; Create a link between any two states that share a border.
  foreach gis:feature-list-of countries-dataset
  [ ?1 ->
    let country ?1
    foreach gis:feature-list-of countries-dataset [ ??1 ->
      if gis:intersects? country ??1 and country != ??1 [
        let name1 gis:property-value country "SOVEREIGN"
        let name2 gis:property-value ??1 "SOVEREIGN"
        let country1 one-of states with [name = name1]
        let country2 one-of states with [name = name2]
        ask country1 [ create-link-with country2]
      ]
    ]

  ]
end

to expand-network
  ; Avoid singletons by connecting each unconnected state to the nearest two states.
  ask states with [count link-neighbors = 0]
  [
    foreach list 1 2 [
    let choice (min-one-of (other turtles with [not link-neighbor? myself]) [distance myself])
    if choice != nobody [create-link-with choice]
    ]
  ]

end

to clean-up-network
  ; Clean up:
  ; Remove Antactica
  ask states with [name = "Antarctica"]  [
    ask my-links [die]
    die
    ]
  ;Rename the DRC to avoid issues with the comma in CSV files:
  ask states with [name = "Congo, DRC"] [set name "DR Congo"]

  ; Manually add some edges which ought to be there:
  let country1 one-of states with [name = "Dominican Republic"]
  let country2 one-of states with [name = "St. Kitts & Nevis"]
  ask country1 [create-link-with country2]

  set country1 one-of states with [name = "Trinidad & Tobago"]
  set country2 one-of states with [name = "Venezuela"]
  let country3 one-of states with [name = "Guyana"]
  ask country1 [
    create-link-with country2
    create-link-with country3
  ]

  set country1 one-of states with [name = "United Kingdom"]
  set country2 one-of states with [name = "France"]
  ask country1 [create-link-with country2]

end


to print-links
  ask links
  [
    print [name] of both-ends
  ]
end

to export-links
  file-open "WorldNetwork.csv"
  file-type "Source, Dest \n"
  ask links [
    foreach [name] of both-ends [ ?1 ->
      file-type ?1
      file-type ","
    ]
    file-type "\n"
  ]
  file-close
end

; -----------------
; Model Procedures
; -----------------


to prep-model
  reset-ticks
  clear-all-plots

  ask states [
        ; Initialize non-geospatial properties:
        set play-table table:make         ; Initialize the new table.

        ; Set the starting score.
        if score-dist = "Uniform"     [set score random 20]           ; Set the score uniformly between 0 and 19
        if score-dist = "Exponential" [set score random-exponential 10]

        if score-dist = "Norm-GDP" [
          set score gis:property-value key-feature "NORMGDP"
        ]

        set init-score score
        set hegemon false
        set ranking -1                    ; States have no default rank.
        set change-count 0

        ; Set graphic properties
        set label precision score 0
  ]

  ; Initialize hegemony:
  ask states [
    if score > [score] of max-one-of link-neighbors [score]
    [ set hegemon true]
    set init-hegemon hegemon
    update-color
  ]
  update-plot

end

to go
  set flag false
  ask states [update-assessments]
  ask states [compute-payoff]
  ask states [update-tit-for-tat]
  ask states [update-color]

  if not flag [stop]
  tick

  update-plot
end

to update-assessments
  ; Agent procedure.
  ; Assess all network neighbors, to find overall local ranking and next highest/lowest neighbors.

  set next-strongest  -1
  set next-weakest  -1

  let temp-rank 0

  ; Find the next-strongest and next-weakest neighbors.

  foreach [who] of link-neighbors
  [ ?1 ->
    let other-score [score] of state ?1
    ifelse other-score > score
    [
      ; If this state's score is greater than mine
      ; AND if the state's score is less than the current highest score (if assigned)
      ifelse next-strongest > 0
        [
          if other-score < [score] of state next-strongest [set next-strongest ?1]
          ]
        [set next-strongest ?1]

    ]

    [
      ; If this state's score is less than mine
      set temp-rank temp-rank + 1
      ; AND if the state's score is greater than the current highest score (if assigned)
      ifelse next-weakest > 0
        [
          if other-score > [score] of state next-weakest [set next-weakest ?1]
         ]
        [set next-weakest ?1]

    ]
  ]

  ;Now, update the play strategies accordingly.
  if ranking != temp-rank
  [
    set flag true
    set ranking temp-rank
    set change-count change-count + 1
    foreach [who] of link-neighbors
    [ ?1 ->
      table:put play-table ?1 "cooperate"
    ]
  ]
  if next-strongest > 0 [ table:put play-table next-strongest "defect" ]
  if next-weakest > 0 [table:put play-table next-weakest "defect" ]

  ; Update hegemonity:
  ifelse next-strongest = -1
    [set hegemon true]
    [set hegemon false]

end

to compute-payoff
  ; Compute the payoff based on each dyads' actions
  ; Current payoff matrix is:
  ;    C   D
  ; C 2,2 0,3
  ; D 3,0 0,0


  let my-index who
  foreach [who] of link-neighbors
  [ ?1 ->
    let my-play table:get play-table ?1
    let partner-action [table:get play-table my-index] of state ?1
    ifelse my-play = "cooperate"
    [
      ifelse partner-action = "cooperate"
      [set score score + 2]; Cooperate / Cooperate payoff]
      [set score score - 0]; Cooperate / Defect payoff]
      ]
    [
      ifelse partner-action = "cooperate"
      [set score score + 3]; Defect / Cooperate payoff]
      [set score score + 0]; Defect / Defect payoff]
    ]

    table:put play-table ?1 partner-action ; Tit-for-Tat -- Play the last move back.
  ]

  set label precision score 0
end

to update-tit-for-tat
  ;For each state, default their action to the counterpart's last action.

  let my-index who
  foreach [who] of link-neighbors
  [ ?1 ->
    let new-play [table:get play-table my-index] of state ?1
    table:put play-table ?1 new-play
  ]
end


to update-color
  ifelse hegemon = true
  [set color green]
  [set color gray]
end


to toggle-labels
  let labels-on [label] of one-of states
  ifelse labels-on = ""
  [
    ask states [set label precision score 0]
  ]
  [
    ask states [set label ""]
  ]
end


; --------------------
; Plotting Procedures
; --------------------

to update-plot
  set-current-plot "Payoffs"
  set-current-plot-pen "Hegemons"
  plot mean [score] of states with [hegemon]
  set-current-plot-pen "Others"
  plot mean [score] of states with [not hegemon]

  set-current-plot "Scores"
  set-plot-x-range min [score] of states  max [score] of states
  set-histogram-num-bars 10
  histogram [score] of states

  set-current-plot "HegemonCount"
  plot count states with [hegemon]
end


; -------------------------------------
; Parameter Sweet and Export Procedures
; -------------------------------------

; We write our own parameter sweep in order to avoid loading
; the data every time,  and to achieve better control over the model output.

to go-for-sweep
  set flag false
  ask states [update-assessments]
  ask states [compute-payoff]
  ask states [update-tit-for-tat]
  ;ask states [update-color]

  if not flag [stop]
  tick

  ;update-plot
end

to param-sweep

  file-open "Output.csv"
  file-type "Iteration, Name, Initial-Hegemon, Hegemon, Initial-Score, Score, Change-Count \n"
  file-close
  set iteration 0
  set score-dist "Uniform"
  repeat 1000 [
    if iteration = 500 [set score-dist "Exponential"]
    prep-model
    repeat 60 [go-for-sweep]
    export-states
    set iteration iteration + 1
  ]
end


to export-states
  file-open "Output.csv"
  ask states [
    ;file-type word behaviorspace-run-number ","
    file-type word iteration ","
    file-type word name ","
    file-type word init-hegemon ","
    file-type word hegemon ","
    file-type word init-score ","
    file-type word score ","
    file-type word change-count " \n"
  ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
119
10
728
420
-1
-1
1.0
1
10
1
1
1
0
1
0
1
0
600
0
400
1
1
1
ticks
30.0

BUTTON
6
48
70
81
Setup
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

BUTTON
4
191
110
224
Export Network
export-links
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
735
60
828
93
Prep Model
prep-model
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
736
95
799
128
Go
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

PLOT
736
134
999
284
Payoffs
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Hegemons" 1.0 0 -10899396 true "" ""
"Others" 1.0 0 -7500403 true "" ""

BUTTON
801
94
880
127
Go Once
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

BUTTON
880
20
986
53
Toggle Labels
toggle-labels
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
887
84
958
129
Hegemons
count states with [hegemon]
0
1
11

PLOT
737
288
937
438
Scores
NIL
NIL
0.0
500.0
0.0
10.0
true
false
"" ""
PENS
"default" 10.0 1 -16777216 true "" ""

PLOT
940
287
1140
437
HegemonCount
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
"default" 1.0 0 -10899396 true "" ""

CHOOSER
734
11
875
56
score-dist
score-dist
"Uniform" "Exponential" "Norm-GDP"
1

TEXTBOX
5
10
115
49
Load GIS data and build network
12
0.0
1

TEXTBOX
7
156
118
187
Export state network to CSV edgelist
11
0.0
1

BUTTON
8
331
114
423
Parameter Sweep
param-sweep
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
10
256
118
333
Will execute parameter sweep within range specified in code, and export results.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model simulates the bilateral interactions of states using the iterated prisoner's dilemma as a framework, with each state having a different behavior towards each of its neighbors, as determined by GIS data. We track the emergence of regional hegemons, defined as states with higher scores (more powerful) than all their neighbors.

## HOW IT WORKS

In this model, state-agents are explicitly attempting to become the local hegemon, defined as having a higher score than any of their neighbors. States do this by choosing to cooperate or defect according to the following rules: each tick, a state ranks the scores of all its neighbors and itself, from lowest to highest; it will always defect against the neighbors with the next-highest and next-lowest ranks -- its most immediate local rivals. Regarding all other neighbors, a state will play a tit-for-tat strategy: it will begin by cooperating, and thereafter play the same action for each neighbor as that neighbor played for it the previous tick. Each time a state's relative ranking among its neighbors changes, it will reset its tit-for-tat memory and default to cooperating.

## HOW TO USE IT

Press the 'Setup' button ONCE to load the GIS data and build the network. Note that loading the data will take some time.

The score-dist selector chooses the initial distribution of scores: uniform, exponential, or based on normalized GDP data.

To conduct a full parameter sweep, press the big 'Parameter Sweep' button. The particular range of values to be analyzed is hard-coded into the param-sweep procedure.

'Export Network' will export an edgelist of all links, which can be imported into any network analysis tool.

## NETLOGO FEATURES

This model uses the GIS extension to load vector data and find bordering regions. The code provides a demonstration of how to work with the GIS attribute table.

The model uses the hash table extension in order to allow agents to associate data with specific other agents (in this case neighbors) as indexed by the agents' WHO number. This represents a computationally efficient alternative to an array of all agents, only filled in at the indexes of the particular neighbors.

The hand-coded parameter sweep represents an alternative to BehaviorSpace, in order to avoid the time overhead involved in reloading the GIS data for each iteration.

## RELATED MODELS

This model is paired with "Geopolitical Prisoner's Dilemma Model 2" as part of a single research project.

This model utilizes code and data from the "GIS General Examples" code in the NetLogo Model Library. See copyright notices below.

## CREDITS AND REFERENCES

Copyright notice for "GIS General Examples":

Copyright 2008 Uri Wilensky. This code may be freely copied, distributed, altered, or otherwise used by anyone for any legal purpose.
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
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

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
  <experiment name="experiment" repetitions="4" runMetricsEveryStep="false">
    <setup>setup
build-network
expand-network
clean-up-network
prep-model</setup>
    <go>go</go>
    <final>export-states</final>
    <timeLimit steps="500"/>
    <metric>count states</metric>
    <metric>count states with [color = blue]</metric>
    <steppedValueSet variable="defection-bonus" first="1" step="0.1" last="2.5"/>
    <steppedValueSet variable="prob-coop" first="0.05" step="0.05" last="0.95"/>
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
