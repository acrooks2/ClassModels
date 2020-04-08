extensions [ gis csv ]
globals [ counties ;; counties and their bounaries
  rivers ;; rivers in NC
  roads ;; Class 1 and Class 2 roads, with some class 3 roads in very rural areas
  cities ;; cities with population over 5000 in NC

  total_population  ;; Total population in cities
  Charlotte
  Raleigh
  Winston-Salem
  Fayetteville
  coast-n
  coast-s
  evacuees-in-safe-area
  evacuees-not-safe
  evacuees-in-safe-city

]

patches-own [
  popu
  city-name
  city-here
  road-here
  north-coast
  south-coast
  area-status
]

turtles-own [ status ]

breed [people ;; agents
  person  ;; agents
]

people-own [home-city
  status
  residence
  evacuation-status

]


to Setup
  Clear-all
  reset-ticks
  gis:load-coordinate-system (word "data/projection_LLWGS84.prj") ;; model projection
  set counties gis:load-dataset "data/BoundaryCounty_Polygon_LLWGS84.shp" ;; county boundaries
  set rivers gis:load-dataset "data/MajorHydro_LLWGS84.shp" ;; rivers
  set roads gis:load-dataset "data/Road_Test2.shp" ;; loading of roads ended up being fixed by changing the geometry of the road shapefile into a geometry that worked - rivers
  set cities gis:load-dataset "data/MunicipalBoundaries5k_LLWGS84.shp"  ;;dataset limited down to municipal ares with populations over 5,000
  set coast-n gis:load-dataset "data/COAST_N.shp"  ;; northern coast
  set coast-s gis:load-dataset "data/COAST_S.shp"  ;; southern coast
  set Charlotte patches with [pxcor > -90 and pxcor < 3 and pycor > -40  and pycor < 7]  ;; Setting 4 corners of area to designate travel location
  set Raleigh patches with [pxcor > 3 and pxcor < 90 and pycor > 7 and pycor < 40]  ;; Setting 4 corners of area to designate travel location
  set Winston-Salem patches with [pxcor > -90 and pxcor < 3 and pycor < 40 and pycor > 7]  ;; Setting 4 corners of area to designate travel location
  set Fayetteville patches with [pxcor > 3 and pxcor < 90 and pycor < 7 and pycor > -40]  ;; Setting 4 corners of area to designate travel location

  ask patches [set area-status "safe-here"]

  gis:apply-coverage cities "MUNICIPA_1" city-name  ;; allows to find city names in the shapefiles
  gis:apply-coverage cities "POPULATION" popu       ;; allows to find population numbers in the shapefiles
  gis:apply-coverage coast-s "VALUE" south-coast
  gis:apply-coverage coast-n "VALUE" north-coast

  ask patches with [popu < 1] [set popu 0]


end

to Draw                  ;; draws the map of North Carolina, with counties, cities, roads and rivers
  clear-drawing
  reset-ticks
  gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of counties)
    (gis:envelope-of rivers)
    (gis:envelope-of roads)
    (gis:envelope-of cities)
    )

  ask patches [set pcolor white]
gis:set-drawing-color gray
  gis:draw counties 1     ;; draws counties

    gis:set-drawing-color blue
  gis:draw rivers 1       ;; draws rivers

    gis:set-drawing-color black
  gis:draw roads 1        ;; draws roads

    gis:set-drawing-color red
  gis:fill cities 1       ;; draws cities

ask patches
     [if gis:intersects? roads self
         [set road-here 1   ;; sets intersections
    ] ]

ask patches
     [if gis:intersects? cities self
         [set city-here 1

  ] ]


end

to load-pop  ;; loads the populatuion of cities with over 5,000 people, then divides the total by 1000
  reset-ticks
  clear-all-plots
  ask people [die]


  ;;ask patches with [popu > 0] [sprout 1]
  ask patches with [popu > 0]

  [let c-name city-name
    let p-patch-city count patches with [city-name = c-name]
    let small_pop (popu / 1000 / p-patch-city)
  sprout-people small_pop
    [set home-city city-name set shape "dot" set size .75 set label "" set status "S" set color black ]
  ]

   ask people [rt random 360 fd random-float .9] ; space them out a little

    ask people
    [set residence "inland"]


    ask people-on patches with [south-coast = 1] [set residence "south coast"]  ;; designates north and south coastal regions
    ask people-on patches with [north-coast = 2] [set residence "north coast"]

    ask people [set evacuation-status 0]  ;; Initial evacuation status


end


to go-south  ;; starts evacuation of southern region
  tick
  evacuate-south
  move
  if ticks >= 720 [ stop ]  ;;set this number to either 720 for 24 hours, or 1440 for 48 hours.
end

;; ask people [if any? neighbors with [road-here = 1]  ;; tests to get people to move
  ;; [move-to one-of neighbors with [road-here = 1]]
;; ]

to evacuate-south
 ask people with [residence = "south coast"]
  [set evacuation-status 1]
  ask patches with [south-coast = 1] [set area-status "evacuate-here"]


end



to go-north  ;; starts evacuation of northern region
  tick
  evacuate-north
  move
  if ticks >= 720 [ stop ]  ;;set this number to either 720 for 24 hours, or 1440 for 48 hours.
end

;; ask people [if any? neighbors with [road-here = 1]  ;; tests to get people to move
  ;; [move-to one-of neighbors with [road-here = 1]]
;; ]

to evacuate-north
 ask people with [residence = "north coast"]
  [set evacuation-status 1]
  ask patches with [north-coast = 2] [set area-status "evacuate-here"]



end

to go-all  ;; starts evacuation of northern region and southern region at the same time
  tick
  evacuate-all
  move
  if ticks >= 1440 [ stop ]  ;;set this number to either 720 for 24 hours, or 1440 for 48 hours.
end

;; ask people [if any? neighbors with [road-here = 1]  ;; tests to get people to move
  ;; [move-to one-of neighbors with [road-here = 1]]
;; ]

to evacuate-all
 ask people with [residence = "north coast" or residence = "south coast"]
  [set evacuation-status 1]
  ask patches with [south-coast = 1 or north-coast = 2] [set area-status "evacuate-here"]


end

to move  ;; tells agents to move toward closest "safe city"


  let cities-to-go-to ["CHARLOTTE" "RALEIGH" "WINSTRON-SALEM" "FAYETTEVILLE" "DURHAM" "CARY" "CONCORD" "HUNTERSVILLE" "GREENSBORO" "BURLINGTON"]
  let safe-patches (patches with [member? city-name cities-to-go-to])


  ask people with [evacuation-status = 1]
  [let road-neighbors (neighbors with [road-here = 1])
    if any? road-neighbors
   [ move-to min-one-of road-neighbors [distance one-of safe-patches] ;;sends agents to nearest large city. This can lead to agents needing to make decision on where to go, if two cities are equidistant.
  ]]

  update-globals
 end


to update-globals  ;; designates areas that are safe and not-safe
  let cities-to-go-to ["CHARLOTTE" "RALEIGH" "WINSTRON-SALEM" "FAYETTEVILLE" "DURHAM" "CARY" "CONCORD" "HUNTERSVILLE" "GREENSBORO" "BURLINGTON"]  ;; specifies city polygons

  set evacuees-in-safe-area count people with [evacuation-status = 1 and [area-status] of patch-here = "safe-here"]
  set evacuees-in-safe-city count people with [evacuation-status = 1 and [area-status] of patch-here = "safe-here" and [city-name] of patch-here = one-of cities-to-go-to]
   ; is member? ["CHARLOTTE" "RALEIGH" "WINSTRON-SALEM" "FAYETTEVILLE" "DURHAM" "CARY"]]
  set evacuees-not-safe count people with [evacuation-status = 1 and [area-status] of patch-here = "evacuate-here"]



end
@#$#@#$#@
GRAPHICS-WINDOW
148
10
1332
545
-1
-1
6.5
1
10
1
1
1
0
0
0
1
-90
90
-40
40
0
0
1
ticks
30.0

BUTTON
9
12
73
45
NIL
Setup\n
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
77
12
140
45
NIL
Draw
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
15
56
134
89
Load Population
load-pop
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
17
255
135
300
Total People Agent
count people
17
1
11

BUTTON
16
129
135
162
Evacuate South
go-south\n
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
18
306
135
351
Charlotte
count turtles-on patches with [city-name = \"CHARLOTTE\" or city-name = \"CONCORD\" or city-name = \"HUNTERSVILLE\"]
17
1
11

MONITOR
18
455
136
500
Fayetteville
count turtles-on patches with [city-name = \"FAYETTEVILLE\"]
17
1
11

MONITOR
18
356
135
401
Raliegh-Durham
count turtles-on patches with [city-name = \"RALEIGH\" or city-name = \"DURHAM\" or city-name = \"CARY\"]
17
1
11

MONITOR
18
406
135
451
Winston-Salem
count turtles-on patches with [city-name = \"WINSTON-SALEM\" or city-name = \"GREENSBORO\" or city-name = \"BURLINGTON\"]
17
1
11

PLOT
1334
10
1576
160
Population
Ticks
Population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Charlotte" 1.0 0 -16777216 true "" "plot count turtles-on patches with [city-name = \"CHARLOTTE\" or city-name = \"CONCORD\" or city-name = \"HUNTERSVILLE\"]"
"Raleigh" 1.0 0 -7500403 true "" "plot count turtles-on patches with [city-name = \"RALEIGH\" or city-name = \"DURHAM\" or city-name = \"CARY\"]"
"Fayetteville" 1.0 0 -2674135 true "" "plot count turtles-on patches with [city-name = \"FAYETTEVILLE\"]"
"Winston-Salem" 1.0 0 -955883 true "" "plot count turtles-on patches with [city-name = \"WINSTON-SALEM\" or city-name = \"GREENSBORO\" or city-name = \"BURLINGTON\"]"

BUTTON
16
165
134
198
Evacuate North
go-north
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
7
202
142
235
Evacuate All Coast
go-all
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
17
504
136
549
Evacuee Count
count turtles with [evacuation-status = 1]
17
1
11

MONITOR
1335
465
1463
510
Evacuees Safe Cities
evacuees-in-safe-city
17
1
11

MONITOR
1473
465
1591
510
Evacuees not Safe
evacuees-not-safe
17
1
11

MONITOR
1388
512
1542
557
NIL
evacuees-in-safe-area
17
1
11

PLOT
1334
161
1576
311
Coastal Evacuees
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
"North Coast" 1.0 0 -16777216 true "" "plot count turtles-on patches with [north-coast = 2]"
"South Coast" 1.0 0 -7500403 true "" "plot count turtles-on patches with [south-coast = 1]"
"All Coast" 1.0 0 -2674135 true "" "plot count turtles-on patches with [south-coast = 1 or north-coast = 2]"

PLOT
1334
312
1598
462
Safe/Not-Safe Evacuees
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
"Evacuees Safe (City)" 1.0 0 -16777216 true "" "plot evacuees-in-safe-city"
"Evacuees Safe Area" 1.0 0 -7500403 true "" "plot evacuees-in-safe-area"
"Evacuees Not Safe" 1.0 0 -2674135 true "" "plot evacuees-not-safe"

@#$#@#$#@
## WHAT IS IT?

This model will show evacuation from the coast of North Carolina to the "safer" zones of the larger cities inland.

## HOW IT WORKS

The agents will follow the roads from their "home cities" to the nearest "safe zone" city inland.

## HOW TO USE IT

Setup - this sets up the data
Draw - Draws the map of North Carolina, including the counties, cities with populations greater than 5000 people, roads, and rivers
Load Population - loads the population of the cities / 1000
Total People Agents - shows the total number of agents being measured
Evacuate South - Evacuates the southern coast of North Carolina
Evacuate North - Evacuates the northern coast of North Carolina
Evacuate All - Evacuates both the norther and southern coasts of North Carolina
Charlotte - Shows the number of agents within the city
Fayetteville - Shows the number of agents within the city
Raleigh - Shows the number of agents within the city
Winston-Salem - Shows the number of agents within the city
Graph - Shows number of agents evacuating to each city

## THINGS TO NOTICE

Notice backlogs of agents trying to enter "safe zone" cities

## THINGS TO TRY

Start an evacuate of the south, then start one of the north

## EXTENDING THE MODEL

Adding a simulate hurricane to specifically designate evacuees. 
Limit number of evacuees to a "safe zone" city. 
Block roads with flooding. 
Determine return to home city timeframe and have agents return if safe.
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
  <experiment name="Experiment_evac_south_720" repetitions="25" runMetricsEveryStep="true">
    <setup>load-pop</setup>
    <go>go-south</go>
    <timeLimit steps="720"/>
    <metric>evacuees-in-safe-city</metric>
    <metric>evacuees-in-safe-area</metric>
    <metric>evacuees-not-safe</metric>
  </experiment>
  <experiment name="Experiment_evac_north_720" repetitions="25" runMetricsEveryStep="true">
    <setup>load-pop</setup>
    <go>go-north</go>
    <timeLimit steps="720"/>
    <metric>evacuees-in-safe-city</metric>
    <metric>evacuees-in-safe-area</metric>
    <metric>evacuees-not-safe</metric>
  </experiment>
  <experiment name="Experiment_evac_all_720" repetitions="25" runMetricsEveryStep="true">
    <setup>load-pop</setup>
    <go>go-all</go>
    <timeLimit steps="720"/>
    <metric>evacuees-in-safe-city</metric>
    <metric>evacuees-in-safe-area</metric>
    <metric>evacuees-not-safe</metric>
  </experiment>
  <experiment name="Experiment_evac_south_1440" repetitions="25" runMetricsEveryStep="true">
    <setup>load-pop</setup>
    <go>go-south</go>
    <timeLimit steps="1440"/>
    <metric>evacuees-in-safe-city</metric>
    <metric>evacuees-in-safe-area</metric>
    <metric>evacuees-not-safe</metric>
  </experiment>
  <experiment name="Experiment_evac_north_1440" repetitions="25" runMetricsEveryStep="true">
    <setup>load-pop</setup>
    <go>go-north</go>
    <timeLimit steps="1440"/>
    <metric>evacuees-in-safe-city</metric>
    <metric>evacuees-in-safe-area</metric>
    <metric>evacuees-not-safe</metric>
  </experiment>
  <experiment name="Experiment_evac_all_1440" repetitions="25" runMetricsEveryStep="true">
    <setup>load-pop</setup>
    <go>go-all</go>
    <timeLimit steps="1440"/>
    <metric>evacuees-in-safe-city</metric>
    <metric>evacuees-in-safe-area</metric>
    <metric>evacuees-not-safe</metric>
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
