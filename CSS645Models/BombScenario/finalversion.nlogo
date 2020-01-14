; Bomb placement agent based model

;
; P

breed [ officers officer ]
breed [ citizens citizen ]
breed [ bombers bomber ]
breed [ bombs bomb ]

extensions [ gis ]

globals [
  patches-dataset  ; global var for patches; used by GIS extension
  arrestedTotal    ; totals the number of arrested for a potential graph
]
turtles-own [
  suspiciousness   ; amount of time spent by a turtle on the platform. only iterated for citizens and bombers.
  memory           ; list of visited locations used by bombers so they avoid visiting visited patches if possible
  oldHeading       ; the previous heading, used when agents are faced with a null space
]
citizens-own [
  inPlace?         ; used to stop the citizens from moving once they have moved into a local maximum location
  goingDirection   ; random 1 or 2 value used to determine when train arrivals will remove them from the platform
  targetCell       ; the cell that the citizen is moving to occupy
]
patches-own [
  occupied?        ; used to denote cells that currently have a citizen. used to stop other citizens from attempting to occupy the same cell
  patch-type       ; required by the GIS extension. stores the cell value from the ASCII file
  neighborhood     ; area visible to the agents
  bombRadius       ; the blast radius of a bomb set off by the bomber
]

; SETUP
; Sets up the model space including the
; neighborhood and bomb radius, and adds
; officers to the space

to setup
  ca
  reset-ticks
  setup-world
  setup-officers
  ask patches [ set neighborhood patches in-radius 15 ]
  ask patches [ set bombRadius patches in-radius 2 ]
end

; SETUP-WORLD
; This function is used to import the ASCII
; file that will be used as the background
; and the movement space in the model
;
; This section of the model was created by
; consulting the GIS Extension
; section of the NetLogo help page and the Happy
; Halloween Zombie Agent-Based Model posted by
; Andrew Crooks to GISAgents.org on 29 October
; 2014 in order to assist in loading the ASCII
; dataset.

to setup-world
  set-patch-size 4
  resize-world -46 46 -267 267

  set patches-dataset gis:load-dataset "lenfant_new_clipped3.asc"
  gis:set-world-envelope gis:envelope-of patches-dataset
  match-cells-to-patches
  gis:apply-raster patches-dataset patch-type

  ask patches [
    set pcolor patch-type

  ]
end

; MATCH-CELLS-TO-PATCHES
; Sets the world in Netlogo to the values from the ASCII
; dataset.
;
; This section of the model was created by
; consulting the Happy
; Halloween Zombie Agent-Based Model posted by
; Andrew Crooks to GISAgents.org on 29 October
; 2014 in order to assist in loading the ASCII
; dataset.

to match-cells-to-patches
  gis:set-world-envelope gis:raster-world-envelope patches-dataset 0 0
  clear-turtles
end

; SETUP-OFFICERS
; This function is used to create the officers.
; The officers are created before the start of
; the model because they are assumed to be on
; the model space prior to the start of events.

to setup-officers
  ask n-of officer-number patches with [ pcolor > 0 ] [
    sprout-officers 1
      [
         set color blue
         set shape "person"
         set size 1.0
         set memory []
         set oldHeading -1
      ]
  ]
end

; GO
; This function is used to kick off the model

to go
  enter-citizens
  find-best-cell
  police-move
  train-arrive
  bomber-arrive
  bomber-move
  tick
  updatePlots
  export-coords
end

; ENTER-CITIZENS
; Input: the user-defined rate at which citizens are entering
; the scene. Value starts at .2 (1 citizen enters every 5 seconds)
; which is the average rate of entrance into L'Enfant Plaza Metro
; Station during the AM Peak
; This function is designed to bring the citizens onto the model
; space. They all enter at the main escalators and are assigned a
; goingDirection which will be used to determine when they will
; be removed from the model space by a notional train

to enter-citizens
  if (ticks mod 5 = 0) [
    create-citizens ( arrival-rate * 5 ) [
      setxy 28 -90
      set goingDirection random 2
      set oldHeading -1
      ]
    ]
end

to bomber-arrive
  if (ticks mod 200 = 0) [
    create-bombers 1 [
      setxy 28 -90
      set memory []
      ]
    ]
end

; TRAIN-ARRIVE
; This function is used to model a train arriving at the station.
; It is set to a user defined value. When the ticks reach the
; user defined interval, citizens of a random goingDirection value
; will be removed from the model space (technically by killing them)

to train-arrive
  if (ticks mod ( train-arrival-time * 60 ) = 0) [

    ask citizens [
      if goingDirection = random 2 [ die ]
      if [patch-type] of one-of neighborhood with [ occupied? = 0 ] > ( patch-type + .1 ) [
        set inPlace? 0
      ]
    ]
  ]
  ask patches [if count citizens-here = 0 [ set occupied? 0 ] ]
end

; FIND-BEST-CELL
; This function is used by the citizens in order
; to determine their optimal location on the
; model space. The basic calculus in plain English is
; as follows:
; If citizens are not presently in their local maximum location,
; they will look for the most attractive unoccupied cell in
; their neighborhood and move towards it.
; If the citizens find that they are surrounding by occupied cells,
; they will stay in place
; If in the process of moving towards their desired cell, they come
; across a black cell (representing a non-walkable space in the model)
; they will change their heading.
; As a citizen is in place, they continue to monitor their
; neighborhood for more attractice cells. If a more attractive
; cell opens up (usually when a train arrives and takes away 1/2 the
; citizens), then the citizen will move towards that cell
; As each citizen stays on the platform, their suspiciousness value will rise.

to find-best-cell
  ask citizens [
    if inPlace? = 0 [
      carefully   ; carefully is included in case the citizen finds itself with all cells in current neighborhood occupied
        [ set targetcell max-one-of neighborhood with [ occupied? = 0 ] [ patch-type ] ] [ set inPlace? 1 ]

      face targetcell

      let nextCell ifelse-value (patch-ahead 1 = patch-here)
        [ patch-ahead 2 ]
        [ patch-ahead 1 ]

      if [pcolor] of nextCell = 0
        [face max-one-of neighbors [patch-type]]
      fd 1

      if (patch-here = targetcell and occupied? = 0) [ set inPlace? 1 set occupied? 1 ]
      ]

    if inPlace? = 1 [
       if [patch-type] of one-of neighborhood with [ occupied? = 0 ] > ( patch-type ) [
        set inPlace? 0
        ask patch-here [ set occupied? 0 ]

      ]
    ]
    set suspiciousness suspiciousness + 1
  ]
end

; POLICE-MOVE
; The purpose of this function is for police to move across
; the model space. The intent of the police is to move towards
; the turtle with the maximum value of suspiciousness in their
; neighborhood.

to police-move
  ask officers [
    face max-one-of turtles-on neighborhood [ suspiciousness ]
    let nextCell ifelse-value (patch-ahead 1 = patch-here)
      [ patch-ahead 2 ]
      [ patch-ahead 1 ]
    if [pcolor] of nextCell = 0
      [face max-one-of neighbors [patch-type] ]
    fd 1
    find-n-frisk
   ]
end

; FIND-N-FRISK
; In addition to having a name that sounds like
; cat food, this function is used by the police to
; determine the local most suspicious turtle and
; arrest them.

to find-n-frisk
  if any? (turtles-on neighborhood) with [suspiciousness > suspiciousness-threshold ] [
    let stopNfrisk one-of (turtles-on neighborhood) with [suspiciousness > suspiciousness-threshold]
    ask stopNfrisk [die]
    set arrestedTotal arrestedTotal + 1
  ]
end

; BOMBER-MOVE
; Function used by the bomber to move about
; the model space. The bomber moves randomly,
; except it attempts to not visit the same
; patches more than once.

to bomber-move
  ask bombers [
    turn-until-free  0
    fd 1
    set memory lput patch-here memory
    set suspiciousness suspiciousness + 1
    place-bomb
  ]
end

; TURN-UNTIL-FREE
; Input: n is a counter used to keep track of
; how many times the agent has turned. Once it
; has made a full 360, it has not found a neighbor
; cell that it has not yet visited, so it will
; visit a visited cell
;
; This function is used by the bomber to
; avoid visited patches. When confronted
; with a patch that it has already visited,
; it will turn left 45 degrees until it can
; move to an unvisited cell that is not in
; the null space. If it cannot do that, it
; will move through a visited patch.
;
; The code for this portion of the model was
; adapted from a response to a question on
; StackExchange related to a similar query
; answered by Nicolas Payette on 1 September
; 2014. The query can be found here:
; http://stackoverflow.com/questions/25605195/avoid-visited-patch-netlogo

to turn-until-free [ n ]
  let target ifelse-value (patch-ahead 1 = patch-here) ;if patch-ahead 1 is the same patch because heading is at an extreme angle, target is two ahead instead
    [ patch-ahead 2 ]
    [ patch-ahead 1 ]
  let seen? member? target memory ;set seen? to be if the target patch is a member of the memory list
  if-else n < 8 ; allow for 8 turns
    [ if seen? or [pcolor] of target = 0 [ lt 45 turn-until-free n + 1 ] ] ;if target has been visited, turn, and increment counter
    [ if [pcolor] of target = 0 [ lt 45 turn-until-free n + 1 ] ] ;if all neighboring cells have been visited, re-visit one that is not out of bounds
end

; PLACE-BOMB
; If the conditions for a bomber are met,
; then they produce a bomb on their current
; patch. The conditions are that the citizens
; on the blast radius must be at least 1/6 the
; number of those in the visible neighborhood.
; Also there must be at least 20 citizens on the
; blast radius.

to place-bomb
  if (6 * (count citizens-on bombRadius) > count citizens-on neighborhood) and
  count citizens-on bombRadius > 10 and
  count officers-on neighbors = 0 [
    hatch-bombs 1 [
      set shape "face sad"
      set size 6.0
    ]
  ]
end

to updatePlots

  set-current-plot "count-citizens"
  plot count citizens

  set-current-plot "bombs"
  plot count bombs

  set-current-plot "arrested-total"
  plot arrestedTotal


end

; EXPORT-COORDS
; Process used to produce shapefiles of the
; resulting bombs from the model space in order
; to create a density diagram.

to export-coords
  if (ticks mod 5000 = 0 and count bombs > 0) [ gis:store-dataset gis:turtle-dataset bombs (word "result" suspiciousness-threshold "_" officer-number "_" arrival-rate "_" train-arrival-time )]
end
@#$#@#$#@
GRAPHICS-WINDOW
263
10
643
2159
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-46
46
-267
267
0
0
1
ticks
30.0

BUTTON
111
1147
174
1180
NIL
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
174
1147
237
1180
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

SLIDER
71
1230
244
1263
officer-number
officer-number
0
10
5.0
1
1
NIL
HORIZONTAL

PLOT
652
1156
853
1306
count-citizens
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
"default" 1.0 0 -16777216 true "" "plot count citizens"

SLIDER
50
1192
244
1225
suspiciousness-threshold
suspiciousness-threshold
0
3000
1250.0
50
1
NIL
HORIZONTAL

PLOT
652
1309
853
1459
arrested-total
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
"default" 1.0 0 -16777216 true "" "plot arrestedTotal"

PLOT
653
1466
854
1616
bombs
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
"default" 1.0 0 -16777216 true "" "plot count bombs"

SLIDER
71
1268
243
1301
arrival-rate
arrival-rate
.2
5
9.0
.2
1
NIL
HORIZONTAL

MONITOR
653
1619
748
1664
NIL
count bombers
0
1
11

SLIDER
74
1311
246
1344
train-arrival-time
train-arrival-time
1
15
6.0
1
1
NIL
HORIZONTAL

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
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>count citizens</metric>
    <metric>arrestedTotal</metric>
    <metric>count bombs</metric>
    <steppedValueSet variable="suspiciousness-threshold" first="1000" step="500" last="2000"/>
    <steppedValueSet variable="officer-number" first="0" step="5" last="10"/>
    <steppedValueSet variable="arrival-rate" first="0.2" step="1" last="5"/>
    <enumeratedValueSet variable="train-arrival-time">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>count turtles</metric>
    <metric>arrestedTotal</metric>
    <metric>count bombs</metric>
    <enumeratedValueSet variable="train-arrival-time">
      <value value="5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="officer-number" first="0" step="5" last="10"/>
    <steppedValueSet variable="arrival-rate" first="0.2" step="2" last="5"/>
    <enumeratedValueSet variable="suspiciousness-threshold">
      <value value="1000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="arrested v total" repetitions="15" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>count turtles</metric>
    <metric>arrestedTotal</metric>
    <metric>count bombs</metric>
    <enumeratedValueSet variable="suspiciousness-threshold">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arrival-rate">
      <value value="0.2"/>
      <value value="0.5"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="train-arrival-time">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>count turtles</metric>
    <metric>arrestedTotal</metric>
    <metric>count bombs</metric>
    <enumeratedValueSet variable="suspiciousness-threshold">
      <value value="720"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arrival-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="train-arrival-time">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="police ramp up" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>count turtles</metric>
    <metric>arrestedTotal</metric>
    <metric>count bombs</metric>
    <enumeratedValueSet variable="suspiciousness-threshold">
      <value value="720"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="arrival-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="officer-number" first="0" step="2" last="10"/>
    <enumeratedValueSet variable="train-arrival-time">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="target rich" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="2000"/>
    <metric>count turtles</metric>
    <metric>arrestedTotal</metric>
    <metric>count bombs</metric>
    <enumeratedValueSet variable="suspiciousness-threshold">
      <value value="720"/>
    </enumeratedValueSet>
    <steppedValueSet variable="arrival-rate" first="1" step="2" last="10"/>
    <enumeratedValueSet variable="officer-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="train-arrival-time">
      <value value="6"/>
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
