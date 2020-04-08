extensions [ gis ]
globals [ population-dataset
          headquarters-dataset
          all_data-dataset
          city-dataset
          road-dataset
          citycost-dataset
          m-attacks
]

breed [bhturtles bhturtle]
breed [attacks attack]
bhturtles-own [goal jerk]
attacks-own [maidu]

patches-own [Dist_City Dist_Cap Dist_HQs Grid_Pop Is_Major_City Is_HQ Is_Capital City_ID City00 City01	City02	City03	City04	City05	City06	City07	City08	City09	City10	City11	City12
City13 City14	City15	City16	City17	City18	City19	City20	City21	City22	City23	City24	City25 City26
]
;;----------------------------------------------------SETUP------------------------------------------------------------------------------
to setup
  ca
  ; Load all of the datasets
  set population-dataset gis:load-dataset "Data/Full_Pop_final.shp"
  set headquarters-dataset gis:load-dataset "Data/Turtle_Area_Start.shp"
  set all_data-dataset gis:load-dataset "Data/Grid_all_data.shp"
  set city-dataset gis:load-dataset "Data/MajorCityPt.shp"
  set road-dataset gis:load-dataset "Data/Roads_Simple.shp"
  set citycost-dataset gis:load-dataset "Data/City_Costs_buff.shp"

  ; Set the world envelope to extent
  gis:set-world-envelope  (gis:envelope-of population-dataset)

  ;Visualizing a map of sorts
  ;set visual for grid
  gis:set-drawing-color white
  gis:fill population-dataset 2
  gis:draw population-dataset 1
  ; just to see hq area for turtles if i use that
  gis:set-drawing-color brown + 2
  gis:draw headquarters-dataset 10
  ;visualize roads
  gis:set-drawing-color black
  gis:draw road-dataset 1
  ;visualize cities
  gis:set-drawing-color blue
  gis:fill city-dataset 3
  gis:draw city-dataset 3


  ;;Read cost attributes from dataset & patchify
  gis:apply-coverage all_data-dataset "MC_CD" Dist_City ; used it identify where the major cities are
  gis:apply-coverage all_data-dataset "CITY_ID" City_ID ; used to call the cost surface for the goal city chosen
  gis:apply-coverage all_data-dataset "BHHQ_CD" Dist_HQs  ; used to set up bhturtles
  gis:apply-coverage population-dataset "FULLPOP" Grid_Pop  ;population data
  gis:apply-coverage citycost-dataset "MAX_CITY00" City00   gis:apply-coverage citycost-dataset "MAX_CITY13" City13
  gis:apply-coverage citycost-dataset "MAX_CITY01" City01   gis:apply-coverage citycost-dataset "MAX_CITY14" City14
  gis:apply-coverage citycost-dataset "MAX_CITY02" City02   gis:apply-coverage citycost-dataset "MAX_CITY15" City15
  gis:apply-coverage citycost-dataset "MAX_CITY03" City03   gis:apply-coverage citycost-dataset "MAX_CITY16" City16
  gis:apply-coverage citycost-dataset "MAX_CITY04" City04   gis:apply-coverage citycost-dataset "MAX_CITY17" City17
  gis:apply-coverage citycost-dataset "MAX_CITY05" City05   gis:apply-coverage citycost-dataset "MAX_CITY18" City18
  gis:apply-coverage citycost-dataset "MAX_CITY06" City06   gis:apply-coverage citycost-dataset "MAX_CITY19" City19
  gis:apply-coverage citycost-dataset "MAX_CITY07" City07   gis:apply-coverage citycost-dataset "MAX_CITY20" City20
  gis:apply-coverage citycost-dataset "MAX_CITY08" City08   gis:apply-coverage citycost-dataset "MAX_CITY21" City21
  gis:apply-coverage citycost-dataset "MAX_CITY09" City09   gis:apply-coverage citycost-dataset "MAX_CITY22" City22
  gis:apply-coverage citycost-dataset "MAX_CITY10" City10   gis:apply-coverage citycost-dataset "MAX_CITY23" City23
  gis:apply-coverage citycost-dataset "MAX_CITY11" City11   gis:apply-coverage citycost-dataset "MAX_CITY24" City24
  gis:apply-coverage citycost-dataset "MAX_CITY12" City12   gis:apply-coverage citycost-dataset "MAX_CITY25" City25
  gis:apply-coverage citycost-dataset "MAX_CITY26" City26

  ask patches with [Dist_City = 0][set Is_Major_City 1]  ;;set patch variable Is_Major_City to 1 if there is a city here
  ask patches with [Dist_HQs = 0][set Is_HQ 1]  ;;set patch variable Is_HQ to 1 if there is a HQ here
  ask patches with [City12 < 3000] [set Is_Capital 1];;set capital Maiduguri

  make-bhturtles

reset-ticks
end

;;----------------------------------------------------TO DOs------------------------------------------------------------------------------


to make-bhturtles
  ask bhturtles [die]
  create-bhturtles 3 [set shape "person soldier" set size 9]

  ask bhturtles [
    move-to one-of patches with [Is_HQ = 1]
    set goal one-of patches with [Is_Major_City = 1] ]
end

to go
  move-turtles
  tick
end

to move-turtles
ask bhturtles [
    ifelse patch-here = goal   ;;arriving at goal
      [ set goal one-of patches with [Is_Major_City = 1] be-a-jerk ]  ;;choose a new city as goal randomly
      [walk-towards-goal]]
end

to walk-towards-goal ;; Walk across the cost surface based on goal choice
  if [City_ID] of goal = 0 [walk-across-cost0]
  if [City_ID] of goal = 1 [walk-across-cost1]
  if [City_ID] of goal = 2 [walk-across-cost2]
  if [City_ID] of goal = 3 [walk-across-cost3]
  if [City_ID] of goal = 4 [walk-across-cost4]
  if [City_ID] of goal = 5 [walk-across-cost5]
  if [City_ID] of goal = 6 [walk-across-cost6]
  if [City_ID] of goal = 7 [walk-across-cost7]
  if [City_ID] of goal = 8 [walk-across-cost8]
  if [City_ID] of goal = 9 [walk-across-cost9]
  if [City_ID] of goal = 10 [walk-across-cost10]
  if [City_ID] of goal = 11 [walk-across-cost11]
  if [City_ID] of goal = 12 [walk-across-cost12]
  if [City_ID] of goal = 13 [walk-across-cost13]
  if [City_ID] of goal = 14 [walk-across-cost14]
  if [City_ID] of goal = 15 [walk-across-cost15]
  if [City_ID] of goal = 16 [walk-across-cost16]
  if [City_ID] of goal = 17 [walk-across-cost17]
  if [City_ID] of goal = 18 [walk-across-cost18]
  if [City_ID] of goal = 19 [walk-across-cost19]
  if [City_ID] of goal = 20 [walk-across-cost20]
  if [City_ID] of goal = 21 [walk-across-cost21]
  if [City_ID] of goal = 22 [walk-across-cost22]
  if [City_ID] of goal = 23 [walk-across-cost23]
  if [City_ID] of goal = 24 [walk-across-cost24]
  if [City_ID] of goal = 25 [walk-across-cost25]
  if [City_ID] of goal = 26 [walk-across-cost26]

end

to be-a-jerk  ;; Attack a city
    if random aggressive-1-in-n-chance = 0  [hatch-attacks 1 [set color red set shape "face sad" set size 7]]
end

;;----------------------------------------------------WALK ON COSTS------------------------------------------------------------------------------
to walk-across-cost0
    fd 1 pen-down
    let p min-one-of neighbors [City00] ;find the least cost to travel to next big city
    if [City00] of p < City00 [
      face p
      move-to p]
end

to walk-across-cost1
    fd 1 pen-down
    let p min-one-of neighbors [City01] ;find the least cost to travel to next big city
    if [City01] of p < City01 [
      face p
      move-to p]
end

to walk-across-cost2
    fd 1 pen-down
    let p min-one-of neighbors [City02] ;find the least cost to travel to next big city
    if [City02] of p < City02 [
      face p
      move-to p]
end

to walk-across-cost3
    fd 1 pen-down
    let p min-one-of neighbors [City03] ;find the least cost to travel to next big city
    if [City03] of p < City03 [
      face p
      move-to p]
end

to walk-across-cost4
    fd 1 pen-down
    let p min-one-of neighbors [City04] ;find the least cost to travel to next big city
    if [City04] of p < City04 [
      face p
      move-to p]
end

to walk-across-cost5
    fd 1 pen-down
    let p min-one-of neighbors [City05] ;find the least cost to travel to next big city
    if [City05] of p < City05 [
      face p
      move-to p]
end

to walk-across-cost6
    fd 1 pen-down
    let p min-one-of neighbors [City06] ;find the least cost to travel to next big city
    if [City06] of p < City06 [
      face p
      move-to p]
end

to walk-across-cost7
    fd 1 pen-down
    let p min-one-of neighbors [City07] ;find the least cost to travel to next big city
    if [City07] of p < City07 [
      face p
      move-to p]
end

to walk-across-cost8
    fd 1 pen-down
    let p min-one-of neighbors [City08] ;find the least cost to travel to next big city
    if [City08] of p < City08 [
      face p
      move-to p]
end

to walk-across-cost9
    fd 1 pen-down
    let p min-one-of neighbors [City09] ;find the least cost to travel to next big city
    if [City09] of p < City09 [
      face p
      move-to p]
end

to walk-across-cost10
    fd 1 pen-down
    let p min-one-of neighbors [City10] ;find the least cost to travel to next big city
    if [City10] of p < City10 [
      face p
      move-to p]
end

to walk-across-cost11
    fd 1 pen-down
    let p min-one-of neighbors [City11] ;find the least cost to travel to next big city
    if [City11] of p < City11 [
      face p
      move-to p]
end

to walk-across-cost12
    fd 1 pen-down
    let p min-one-of neighbors [City12] ;find the least cost to travel to next big city
    if [City12] of p < City12 [
      face p
      move-to p]
end

to walk-across-cost13
    fd 1 pen-down
    let p min-one-of neighbors [City13] ;find the least cost to travel to next big city
    if [City13] of p < City13 [
      face p
      move-to p]
end

to walk-across-cost14
    fd 1 pen-down
    let p min-one-of neighbors [City14] ;find the least cost to travel to next big city
    if [City14] of p < City14 [
      face p
      move-to p]
end

to walk-across-cost15
    fd 1 pen-down
    let p min-one-of neighbors [City15] ;find the least cost to travel to next big city
    if [City15] of p < City15 [
      face p
      move-to p]
end

to walk-across-cost16
    fd 1 pen-down
    let p min-one-of neighbors [City16] ;find the least cost to travel to next big city
    if [City16] of p < City16 [
      face p
      move-to p]
end

to walk-across-cost17
    fd 1 pen-down
    let p min-one-of neighbors [City17] ;find the least cost to travel to next big city
    if [City17] of p < City17 [
      face p
      move-to p]
end

to walk-across-cost18
    fd 1 pen-down
    let p min-one-of neighbors [City18] ;find the least cost to travel to next big city
    if [City18] of p < City18 [
      face p
      move-to p]
end

to walk-across-cost19
    fd 1 pen-down
    let p min-one-of neighbors [City19] ;find the least cost to travel to next big city
    if [City19] of p < City19 [
      face p
      move-to p]
end

to walk-across-cost20
    fd 1 pen-down
    let p min-one-of neighbors [City20] ;find the least cost to travel to next big city
    if [City20] of p < City20 [
      face p
      move-to p]
end

to walk-across-cost21
    fd 1 pen-down
    let p min-one-of neighbors [City21] ;find the least cost to travel to next big city
    if [City21] of p < City21 [
      face p
      move-to p]
end

to walk-across-cost22
    fd 1 pen-down
    let p min-one-of neighbors [City22] ;find the least cost to travel to next big city
    if [City22] of p < City22 [
      face p
      move-to p]
end

to walk-across-cost23
    fd 1 pen-down
    let p min-one-of neighbors [City23] ;find the least cost to travel to next big city
    if [City23] of p < City23 [
      face p
      move-to p]
end

to walk-across-cost24
    fd 1 pen-down
    let p min-one-of neighbors [City24] ;find the least cost to travel to next big city
    if [City24] of p < City24 [
      face p
      move-to p]
end

to walk-across-cost25
    fd 1 pen-down
    let p min-one-of neighbors [City25] ;find the least cost to travel to next big city
    if [City25] of p < City25 [
      face p
      move-to p]
end

to walk-across-cost26
    fd 1 pen-down
    let p min-one-of neighbors [City26] ;find the least cost to travel to next big city
    if [City26] of p < City26 [
      face p
      move-to p]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
664
565
-1
-1
2.0
1
10
1
1
1
0
0
0
1
0
222
0
272
0
0
1
ticks
30.0

BUTTON
20
17
76
51
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
127
17
190
50
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

PLOT
683
407
1165
564
Susceptible Population
Time
 Max Susceptible
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Pop" 1.0 0 -955883 true "" "plot sum [Grid_Pop] of bhturtles"

PLOT
684
201
1165
383
Susceptible Population by Terror Turtle
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
"default" 1.0 0 -6459832 true "" "plot [Grid_Pop] of turtle 0"
"pen-1" 1.0 0 -8630108 true "" "plot [Grid_Pop] of turtle 1"
"pen-2" 1.0 0 -11221820 true "" "plot [Grid_Pop] of turtle 2"

MONITOR
27
243
182
288
Est. Population near TT 2
[Grid_Pop] of turtle 2
17
1
11

MONITOR
27
192
182
237
Est. Population near TT 1
[Grid_Pop] of turtle 1
17
1
11

MONITOR
40
431
184
476
TT 2 Distance from Goal
[Dist_City] of turtle 2
17
1
11

MONITOR
40
379
184
424
TT 1 Distance from Goal
[Dist_City] of turtle 1
17
1
11

MONITOR
39
327
183
372
TT 0 Distance from Goal
[Dist_City] of turtle 0
17
1
11

MONITOR
1054
13
1142
58
NIL
count attacks
17
1
11

PLOT
685
12
1039
178
Max Potential Affected By Attack
Time
Population
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot sum [Grid_Pop] of attacks"

SLIDER
19
70
203
103
aggressive-1-in-n-chance
aggressive-1-in-n-chance
1
10
2.0
1
1
NIL
HORIZONTAL

MONITOR
28
139
180
184
Est. Population near TT 0
[Grid_Pop] of turtle 0
17
1
11

MONITOR
1055
75
1179
120
Attacks in Maiduguri
count attacks with [Is_Capital = 1]
17
1
11

@#$#@#$#@
## WHAT IS IT?
This model is designed on the Boko Haram terrorist group based in Borno State, Nigeria. The model is a simple exploration of estimating population at risk to when a Boko Haram group (Terror Turtle) is near as well as counting the max potential affected by an attack by Boko Haram. 

MWLITTELPWNES: Modeling likely indicators tempting turtle events linking population weights in estimating susceptibility

## HOW IT WORKS

Terror Turtle randomly chooses a city and walks across cost surface to the city. User defines how aggresive the terror turtle is. Based on the user definition of Aggression, the terror turtle will attack.

## HOW TO USE IT

Choose a level of aggression. If 2 is chosen, there is a 1-in-2 chance an attack will occur.

## THINGS TO NOTICE

Counts of population and routes taken

## THINGS TO TRY



## EXTENDING THE MODEL

1) Weighting the city choice by population instead of random choice
2) Specify likely routes
3) Introduce behaviors
4) Memory of where prior attacks occured
5) Add in peace keeping soldiers affecting terror turtle decisions

## NETLOGO FEATURES

Buffer was added around the dataset to prevent turtles from falling off the layer

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

person soldier
false
0
Rectangle -7500403 true true 127 79 172 94
Polygon -10899396 true false 105 90 60 195 90 210 135 105
Polygon -10899396 true false 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Polygon -10899396 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -6459832 true false 120 90 105 90 180 195 180 165
Line -6459832 false 109 105 139 105
Line -6459832 false 122 125 151 117
Line -6459832 false 137 143 159 134
Line -6459832 false 158 179 181 158
Line -6459832 false 146 160 169 146
Rectangle -6459832 true false 120 193 180 201
Polygon -6459832 true false 122 4 107 16 102 39 105 53 148 34 192 27 189 17 172 2 145 0
Polygon -16777216 true false 183 90 240 15 247 22 193 90
Rectangle -6459832 true false 114 187 128 208
Rectangle -6459832 true false 177 187 191 208

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
