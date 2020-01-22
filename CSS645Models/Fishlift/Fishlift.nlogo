;;---------------------------------------------------
;;
;;    Migration of Anadromous Fish Using a Fish Lift
;;
;;---------------------------------------------------

;; Globals
;
; Two agentsets -- Adult and Juvenile American Shad ;; juveniles are represented using "yoy" or young of year
;
;;

turtles-own [energy in_upstream? in_downstream?]
patches-own[in_river? downstream? upstream? fishlift? fishlift-memory near-fishlift?]
globals [total_shad fishlift_used]

breed[shad shads]
breed[yoy yoys]

;;;; Setup environment, turtles, patches
;
; setup imports .gif file of river.  River map was created in ArcGIS and exported as a .gif file.
;
;;;;


to setup
  __clear-all-and-reset-ticks
  setup-patches
  setup-turtles

end

to setup-patches
  import-pcolors-rgb "Project_new_1.gif"
  ask patches [set in_river? true set upstream? false set downstream? false set near-fishlift? false] ;; sets initual parameters for entire world
  ask patches with [pcolor = [92 137 68]][set in_river? false]                                        ;; fish world is based on RGB values
  ask patches with [pcolor = [115 178 255]][set downstream? true set upstream? false]
  ask patches with [pcolor = [122 182 245]][set upstream? true set downstream? false]
  ask patches with [pcolor = [190 210 255]][set in_river? false]
  ask patches with [pcolor = [0 0 0]][set in_river? false]
  ask patches with [pcolor = [0 0 0]][set fishlift? true set near-fishlift? true]
  ask patches with [pcolor = [115 38 0]][set in_river? false]
  ask patches [setup-fishlift]

end


to setup-fishlift                                ;;Adapted from the Ants model in NetLogo's model Library, gives weight to fishlift center patch and applies
  set fishlift?(distancexy 51 -100) < 10         ;; weights to the surrounding patches with the center being the highest value
  set fishlift-memory 200 - distancexy 51 -100
  set fishlift_used 0                            ;;set initial count of # fish using lift to zero
end

;;===================
;; Create all turtles
;;===================

to setup-turtles

  set-default-shape shad "fish"
  create-shad 2000
  [set energy random (2 * gain-from-food) set color red set size 8]       ;; Energy variable adapted from the wolf-sheep predation model in NetLogo's model library
  display-labels

  set-default-shape yoy "fish"
  create-yoy 2000
  [set energy 1 set color blue set size 8]                                ;; This is adapted from the wolf-sheep predation model in NetLogo's model library
  display-labels


  ask turtles [if in_river?
    [setxy random-xcor random-ycor]
    ifelse agent_in_river
      [fd 1]
      [die]]

  ask yoy [if upstream?
    [setxy random-xcor random-ycor]
    ifelse upstream?
      [fd 1]
      [die]]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;....................Movement Rules.......
;
; At each dail time step -- begins first week of April for 200 days
;
; Adult and juvenile turtles migrate upstream in spring; migration continues for 50 days
;
; All immature turtles continue to swim and grow for 100 days
;
; Adult turtles migrate downstream in fall; migration continues for 50 days
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;
;......................Main Go Module................
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;


to go
  if not any? turtles [stop]

  ask turtles [
  move-turtles
  set energy energy - 1             ;; from wolf-sheep predation model ;; energy is deducted for moving
  eat-food                          ;; from wolf-sheep predation model ;; replenish energy by eating
  grow
  check-death                       ;; from wolf-sheep predation model ;; if energy < 0 die
  ]


  ;-----------------World Rules----------------------;
  ;
  ;; Below is an artificial wrapping of the world from the top and side of the model space where the river exits so all fish are transported to either end
  ;; I was not able to determine how to randomly allow fish to enter the ends of the river to swim towards the fish lift in a more realistic way.

  ask turtles[
    if pycor >= 257 [setxy 410 -100 fd 1 set heading random 360]
    if pxcor = 413 [setxy -300 260 set heading random 360 fd 2]
    if pxcor = -413 [setxy -354 258]
  ]


  ;------------------Temporal Parameters-------------;
  ;
  ;One tick = one day
  ;Time horizon = 365 days
  ;

  if ticks <= 50                                    ;; This represents April through June, when American shad migrate upstream to spawn ;; each tick = one day
  [ask shad[migrate_upstream]                       ;; Not enough of them move through the lift by tick 50; probably moves per iteration should be increased
    ask yoy [wiggle]]

  if ticks > 50 and ticks <= 150                    ;; This represents summer, all juvenile fish swim, eat, and grow, while adults migrate downstream
  [ask patches with [pcolor = [115 38 0]][set in_river? true] ;;allows passage of fish across dam presumable over the top or through turbines
  ask patches with [pcolor = [0 0 0]][set in_river? true]   ;; allows passage of fish across fishlift (through an exit flume)
  ask yoy[wiggle]                                   ;; They move and gain energy, which relates to their growth
  ask shad [migrate_downstream]]                    ;; adults swim downstream

  if ticks > 150 and ticks <= 275                   ;; Represents September through November
  [ask patches with [pcolor = [115 38 0]][set in_river? true]
  ask patches with [pcolor = [0 0 0]][set in_river? true]
  ask turtles[migrate_downstream]]


  if ticks > 275 ;; stop simulation when one migration cycle is reached
  [stop]

  tick
end

to move-turtles

   ifelse edge_of_river ;;subroutine borrowed from John Clark's Piracy model; had a lot of difficulty with this; fish do not behave as intended;
    [turn-around]
    [fd 2]
    ifelse edge_of_river
     [turn-around]
     [fd 2]
end


to migrate_upstream
   set energy energy - 2           ; lose energy swimming upstream
   ifelse turtle_in_upstream
   [downhill fishlift-memory]      ; this code means "swim away from the fishlift", so by extension, swim upstream
   [uphill fishlift-memory         ; otherwise swim away from the fishlift (This is also adapted from Ants.nlogo)
     ifelse near-fishlift?         ; if in the fishlift zone, teleport to other side of dam
     [setxy 4 -77
        fd 1 set heading random 360 set fishlift_used (fishlift_used + 1)] ; add fish to fishlift counter
     [fd 1 set heading random 360]]
     if xcor = 48 and ycor = -80                                           ; this was added to try to move more fish over the lift area
     [jump 5 set heading random 360 set fishlift_used (fishlift_used + 1)] ;add fish to fishlift counter

   ifelse edge_of_river                                                    ; added additional turning parameters to try to mitigate river side collision
      [turn-around]
      [fd 1]
      ifelse edge_of_river
        [turn-around]
        [fd 1]
end

to migrate_downstream

  set energy energy - 1            ; lose energy swimming downstream, but not as much
  if turtle_in_upstream
  [uphill fishlift-memory]         ; if fish is upstream from lift, swim towards fishlift; this simulates swimming through exit flume
  wiggle
  if pxcor = 413 [setxy -390 260 set heading random 360 fd 2] ; if fish reaches side of world, reappear at top of river (wraps fish world at one coordinate)

  ifelse turtle_in_downstream
      [ifelse edge_of_river        ; Migrating downstream is where the fish kept dying from wall collisions.  This is trying to turn them around again.
          [lt 90 fd 1]             ; if at edge of river, turn left 90 degrees then move forward
          [fd 2 set heading 95      ; If not at edge, move 2, heading towards ocean
             ifelse edge_of_river
                  [lt 30 fd 1]
                  [fd 2 set heading 95]
          ]]
        [ifelse edge_of_river
          [rt 90 fd 1]
          [fd 2
             ifelse edge_of_river
                  [rt 30 fd 1]
                  [fd 2 wiggle]
          ]]
   ifelse agent_in_river
   [ifelse edge_of_river
     [turn-around]
     [fd 2]]
   [setxy 49 -81 set heading random 95]   ; utlimately none of these turns produced the correct behavior for turning around.  This transports
                                          ; any fish still on land to the downstream area of the dam near the fishlift
end

to eat-food
  if pcolor = [122 182 245]               ; fish are presumably not eating much while trying to migrate upstream so most energy is gained on the upstream side
    [set energy (energy + 10)]

  if pcolor = [115 178 255]               ; fish downstream gain less energy due to less eating
    [set energy (energy + 5)]

  ifelse show-energy?                     ; this allows energy labels to be turned on and off; from Wolf Sheep predation model
  [set label energy]
  [set label ""]
end

to grow
  if energy > length-threshold            ; this was adapted from the Wolf Sheep predation reproduction procedure
  [set energy energy / 2
   set color red set breed shad]          ; change from yoy to adult shad if energy is > 600
end                                       ; there is an error in this logic as these fish now migrate downstream in summer as though they
                                          ; they just spawned.  I leave them as red yoy to prevent this, but the population graph will not update
to check-death
  if energy <= 0 [die]                    ; die if you starve
end

to turn-around
    bk 1 rt 90 fd 1 set heading random 360    ; this tries to turn fish away from edges of river; adapted from John Clark's pirate model
    ifelse edge_of_river
    [rt 30]
    [fd 1]
       ifelse edge_of_river
       [rt 30 fd 1 ]
       [fd 1 ]

end

to wiggle                                     ; to simulate fish type movement; taken from the Moths model in NetLogo's model library
  rt random 40
  lt random 40
  if not can-move? 1 [rt 180]
end

;;------------------Helper procedures----------------------

to do-plots
  set-current-plot "Fish Population over Time"      ; sets up population plots
  set-current-plot-pen "Shad"
  plot count turtles
  set-current-plot-pen "Yoy"
  plot count yoy
  set-current-plot-pen "Adults"
  plot count shad

end

to-report agent_in_river                             ; reports if fish is on a land patch or river patch
  report [in_river?] of patch-here
end

to-report near-fishlift                              ; reports when fish are in the fishlift (from Ants nest in Netlogo)
  let n patch-ahead 1
  let d patch-left-and-ahead 30 1
  let f patch-right-and-ahead 30 1
  if n = nobody [report false]
  if d = nobody [report false]
  if f = nobody [report false]

  report [fishlift?] of n                           ; used multiple variables to get more than one patch to drive fishlift movement due to crowding
  report [fishlift?] of d
  report [fishlift?] of f
end

to-report edge_of_river                             ; look ahead two patches, if not river color, in_river is false
  let r patch-ahead 2
  if r = nobody [report false]
  report not[in_river?] of r
end

to-report turtle_in_upstream                        ; reports if agent is on an upstream patch
  report[upstream?] of patch-here
end

to-report turtle_in_downstream                      ; reports if agent is on a downstream patch
  report [downstream?] of patch-here
end


to display-labels                                      ; for displaying energy; taken from Wolf Sheep predation model
  ask turtles [set label ""]
  if show-energy?[
    ask turtles [set label round energy]]
end
@#$#@#$#@
GRAPHICS-WINDOW
308
12
1143
542
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
-413
413
-260
260
0
0
1
ticks
30.0

BUTTON
20
19
87
52
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

BUTTON
104
19
167
52
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

MONITOR
24
322
134
375
count adults
count shad
0
1
13

SWITCH
20
58
169
91
show-energy?
show-energy?
1
1
-1000

PLOT
311
572
1141
722
Fish Population over Time
Time (Ticks)
No. Fish
0.0
375.0
0.0
400.0
true
true
"plot count shad\nplot count yoy\nplot count turtles" ""
PENS
"Adults" 1.0 0 -14070903 true "" "plot count shad"
"Juveniles" 1.0 0 -2674135 true "" "plot count yoy"
"Total shad" 1.0 0 -955883 true "" "plot count turtles"

SLIDER
20
99
192
132
gain-from-food
gain-from-food
0
50
5.0
1
1
NIL
HORIZONTAL

MONITOR
24
207
136
252
No. Fish Using Lift
fishlift_used
17
1
11

MONITOR
25
381
168
434
count young of year
count yoy
0
1
13

MONITOR
24
260
142
313
count total shad
count turtles
17
1
13

CHOOSER
28
154
166
199
length-threshold
length-threshold
600
0

@#$#@#$#@
## ## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## ## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## ## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## ## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## ## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## ## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## ## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## ## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## ## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

fish left
false
0
Polygon -1 true false 256 131 279 87 285 86 300 120 285 150 300 180 287 214 280 212 255 166
Polygon -1 true false 165 195 181 235 205 218 224 210 254 204 240 165
Polygon -1 true false 225 45 217 77 229 103 214 114 134 78 165 60
Polygon -7500403 true true 270 136 149 77 74 81 20 119 8 146 8 160 13 170 30 195 105 210 149 212 270 166
Circle -16777216 true false 55 106 30

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
