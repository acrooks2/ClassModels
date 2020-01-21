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
  cooperate      ; Global strategy
  prev-cooperate ; Last round's strategy
  prev-color     ; Last round's color.
  change-count   ; How many times
]

; ----------------
; SETUP PROCEDURES
; -----------------

to setup
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
        set score 0               ; Set the starting score.

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
  clear-all-plots
  reset-ticks

  ask states
  [
    set score 0
    set change-count 0
    ifelse random-float 1.0 < prob-coop
      [set cooperate true]
      [set cooperate false]
    set prev-cooperate cooperate
    update-color
  ]
end

to interact
  ; Form of interaction code based on
  ; "PD Basic Evolutionary," NetLogo Model Library, Wilensky, 2002.

  let total-cooperators count link-neighbors with [cooperate]
  let total-defectors count link-neighbors with [not cooperate]
  ifelse cooperate
    [set score score + total-cooperators]
    [set score score + (total-cooperators * defection-bonus)]
end

to change-strategies
  set prev-cooperate cooperate
  let max-score [score] of max-one-of link-neighbors [score]
  if max-score > score [
  set cooperate [cooperate] of max-one-of link-neighbors [score]
  ]
  update-color
end

to update-color
  ; Color scheme taken from "PD Basic Evolutionary," NetLogo Model Library, Wilensky, 2002.
  ; Notation is Current-Prev; e.g. CD: Now Cooperating, previous round Defected
  set prev-color color

  ifelse cooperate
    [
      ifelse prev-cooperate
      [set color blue]   ; CC
      [set color yellow] ; CD
    ]
    [
      ifelse prev-cooperate
      [set color green]  ; DC
      [set color red]    ; DD
    ]
end

to go
  set flag false
  ask turtles [interact]
  ask turtles [
    change-strategies
    if color != prev-color [
      set flag true
      set change-count change-count + 1
      ]
    ]
  tick
  update-plot
  if not flag [stop]
end


; --------------------
; Plotting Procedures
; --------------------

; Plotting function forms modified from
;"PD Basic Evolutionary," NetLogo Model Library, Wilensky, 2002.

to plot-draw [pen-name color-name]
  set-current-plot-pen pen-name
  plot count turtles with [color = color-name]
end

to update-plot
  set-current-plot "Count"
  plot-draw "CC" blue
  plot-draw "DD" red
  plot-draw "DC" green
  plot-draw "CD" yellow

  set-current-plot "Payoffs"
  set-current-plot-pen "Cooperators"
  if count states with [cooperate] > 0 [plot mean [score] of states with [cooperate] ]
  set-current-plot-pen "Defectors"
  if count states with [not cooperate] > 0 [ plot mean [score] of states with [not cooperate] ]
end


; -------------------------------------
; Parameter Sweet and Export Procedures
; -------------------------------------

; We write our own parameter sweep in order to avoid loading
; the data every time,  and to achieve better control over the model output.


to go-for-sweep
  set flag false
  ask turtles [interact]
  ask turtles [
    change-strategies
    if color != prev-color [
      set flag true
      set change-count change-count + 1
      ]
    ]
  tick
end

to param-sweep
  set iteration 0
  set prob-coop 0.05
  set defection-bonus 1

  file-open "Output-Summary.csv"
  file-type "Iteration, Prob-Coop, Defection-Bonus, States, Cooperating-States \n"
  file-close

  file-open "Output.csv"
  file-type "Iteration, Name, Cooperate, Change-Count, Score \n"
  file-close

  repeat 19 [ ; Prob-Coop Loop
    set defection-bonus 1
    repeat 26 [ ; Defection-Bonus loop
      repeat 4 [ ; Internal loop

       prep-model
       repeat 100 [go-for-sweep]
       ; Write the model summary
       file-open "Output-Summary.csv"
       file-type word iteration ","
       file-type word prob-coop ","
       file-type word defection-bonus ","
       file-type word count states ","
       file-type count states with [cooperate]
       file-type " \n"
       file-close
       ;Write the state-specific data:
       export-states

    set iteration iteration + 1
     ]

    set defection-bonus defection-bonus + 0.05]
  set prob-coop prob-coop + 0.05]
end


to export-states
  file-open "Output.csv"
  ;file-type "Iteration, Name, Cooperate, Change-Count, Score \n"
  ask states [
    ;file-type word behaviorspace-run-number ","
    file-type word iteration ","
    file-type word name ","
    file-type word cooperate ","
    file-type word change-count ","
    file-type word score " \n"
  ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
120
10
729
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
4
46
68
79
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
141
110
174
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

SLIDER
736
10
908
43
prob-coop
prob-coop
0
1
0.5
0.01
1
NIL
HORIZONTAL

BUTTON
736
81
829
114
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

SLIDER
736
45
908
78
defection-bonus
defection-bonus
0
2
1.75
0.01
1
NIL
HORIZONTAL

BUTTON
737
116
800
149
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
154
936
304
Count
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
"CC" 1.0 0 -13345367 true "" ""
"DD" 1.0 0 -2674135 true "" ""
"DC" 1.0 0 -10899396 true "" ""
"CD" 1.0 0 -955883 true "" ""

PLOT
736
306
999
456
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
"Cooperators" 1.0 0 -13345367 true "" ""
"Defectors" 1.0 0 -2674135 true "" ""

BUTTON
802
115
881
148
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

TEXTBOX
4
10
107
40
Load GIS data and build network
12
0.0
1

BUTTON
7
343
107
438
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
11
243
108
330
Will execute parameter sweep within range specified in code, and export results.
11
0.0
1

TEXTBOX
8
110
115
138
Export state network to CSV edgelist
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model simulates the emergence of international norms of inter-state behavior, by having state-level agents play an iterated prisoner's dilemma game with their neighbors, as determined by GIS data.

## HOW IT WORKS

In this model, each state has a single behavior: it either cooperates or defects with all of its neighbors. The model is initialized by assigning each state an initial behavior randomly, with a certain probability; this is done to ensure that the results of the parameter sweep represent the true effects of interactions across the geography rather than artifacts of fixed initial conditions. All the states begin with an initial score of 0.

At each tick of the model, each pair of neighbors plays a prisoner's dilemma with their given actions. The states' scores are then increased simultaneously based on the resulting payoffs. Next, each state compares its own score to that of its neighbors, and will change its behavior for the next tick to match that played in the current tick by the neighbor with the highest score, provided that score is greater than its own. Simply put, each state will adopt the behavior of the state doing best among its neighbors. Of course, if a state is doing better than all its neighbors, it will have no reason to change its behavior.

## HOW TO USE IT

Press the 'Setup' button ONCE to load the GIS data and build the network. Note that loading the data will take some time.

The sliders can be used to manually adjust the parameters. Pressing 'Prep Model' will reset all the agents according to the current parameters.

To conduct a full parameter sweep, press the big 'Parameter Sweep' button. The particular range of values to be analyzed is hard-coded into the param-sweep procedure.

'Export Network' will export an edgelist of all links, which can be imported into any network analysis tool.

## NETLOGO FEATURES

This model uses the GIS extension to load vector data and find bordering regions. The code provides a demonstration of how to work with the GIS attribute table.

The hand-coded parameter sweep represents an alternative to BehaviorSpace, in order to avoid the time overhead involved in reloading the GIS data for each iteration.

## RELATED MODELS

This model is paired with "Geopolitical Prisoner's Dilemma Model 2" as part of a single research project.

This model utilizes code from the "PD Evolutionary Basic" model and the "GIS General Examples" code and data, in the NetLogo Model Library. See copyright notices below.


## CREDITS AND REFERENCES


Copyright notice for "GIS General Examples":

Copyright 2008 Uri Wilensky. This code may be freely copied, distributed, altered, or otherwise used by anyone for any legal purpose.

Copyright notice for "PD Evolutionary Basic":
Permission to use, modify or redistribute this model is hereby granted, provided that both of the following requirements are followed: a) this copyright notice is included. b) this model will not be redistributed for profit without permission from Uri Wilensky. Contact Uri Wilensky for appropriate licenses for redistribution for profit.
This model was created as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227.
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
