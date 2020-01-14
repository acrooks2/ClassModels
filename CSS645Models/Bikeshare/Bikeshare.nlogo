;Bikeshare Model ver.1.0
;This model borrows heavily from the models available in:
;Wilensky, U. (1999). NetLogo Model Library (Version 5.0.1)[Computer software].Evanston, CA: Northwestern University.
;
;----------------------------------------------------------------------------------------------------------------------
globals [
  depart-failure
  rack-full
  success-trip
  rebalance
  station-queue
  extra-bikes
  ]
breed [stations station]
breed [bikes bike]
breed [trucks truck]
breed [depots depot]
stations-own [
  open-rack
  available-bike
  station-status; 0 = bike available & space available; 1 = either bike or space unavailable
  bike-queue
  ]
bikes-own [
  destination ; the current destination
  bike-status; 0 = not in operation; 1 = in operation; 2 = on-queue
  host ; the station stationed
  ]
depots-own [
  station-pending
]
trucks-own [
  host
  destination
  in-operation?
  ]

to setup
  ca
  verify-parameters
  setup-globals
  setup-stations
  setup-depots
  reset-ticks
end
to go
  if daily-sim = true [ if ticks = 960 [stop]]
  update-parameters
  stations-go
  bikes-go
  trucks-go
  tick
end
to verify-parameters
  if num-rack/station < num-bikes/station [
    user-message (word"invalid number of racks and bikes at a station")
    stop]
end

to setup-globals
  set-default-shape depots "box"
  set-default-shape trucks "truck"
  set-default-shape stations "house"
  set-default-shape bikes "dot"
end

to setup-stations
  create-stations num-stations [
    set color white
    set size 1
    setxy random-xcor random-ycor
    set available-bike num-bikes/station
    set open-rack num-rack/station - num-bikes/station
    set bike-queue 0]
  ask stations [
    hatch-bikes num-bikes/station[
      set color pink
      set size 1
      set destination myself
      set host myself
      set bike-status 0]]
end

to setup-depots
  create-depots 1 [
    setxy random-xcor random-ycor
    set color brown
    set station-pending 0]
  ask depots [
    hatch-trucks num-trucks [
      set color orange
      set host myself
      set destination myself
      set in-operation? false]]
end

to update-parameters
  ask stations [
    set available-bike count bikes with [host = myself]
    set open-rack num-rack/station - available-bike]
end

to stations-go
  ask stations [
    if random-float 100 < tripgen-frequency [initiate-trip]
  ]
end

to bikes-go
  ask bikes [
    if bike-status = 2 [
      if [open-rack] of destination > 0 [arrive]]
    if bike-status = 1 [
      ifelse distance destination < 2 [
        reach
        ][ fd 1 ]]]
end

to trucks-go
  ask trucks [
    if in-operation? = true [
      ifelse distance destination > 1.5 [fd 1][rebalance2]]
    if in-operation? = false [
      ifelse distance host > 2 [
        face host
        fd 1]
      [move-to host]]]
end

to initiate-trip
  ifelse available-bike <= 0 [
    trip-fail][
    set available-bike available-bike - 1
    set open-rack open-rack + 1
    ask one-of bikes with [host = myself][bike-depart]]
end
to trip-fail
  set station-status 1
  set depart-failure depart-failure + 1
  request-rebalancing
end
to request-rebalancing
  set station-status 1
  ask one-of depots [rebalance-initiate]
end
to bike-depart
  set destination one-of stations
  face destination
  set bike-status 1
  set color green
  fd 0.5
end
to reach
  ifelse [open-rack] of destination > 0 [
    move-to destination
    arrive ][
    if [station-status] of destination = 0 [
    ask destination [request-rebalancing]]
    move-to destination
    set color yellow
    set rack-full rack-full + 1
    set bike-status 2]
end
to arrive
  set host destination
  ask host [
    set open-rack open-rack - 1
    set available-bike available-bike + 1 ]
  set color red
  set bike-status 0
  set success-trip success-trip + 1
end
to rebalance-initiate
  if count trucks with [in-operation? = false] > 0 [
    ask one-of trucks with [in-operation? = false] [
      rebalance1]]
end
to rebalance1
  set destination one-of stations with [station-status = 1]
  face destination
  set in-operation? true
  fd 1
end
to rebalance2
  move-to destination
  ask destination [
    if available-bike <= 0 [
      hatch-bikes num-bikes/station [
        set color pink
        set size 1
        set destination myself
        set host myself
        set bike-status 0]
      set open-rack num-rack/station - num-bikes/station
      set available-bike num-bikes/station
      set extra-bikes extra-bikes - num-rack/station
;      if extra-bikes > 0 [
;        hatch-bikes 1 [
;          set color pink
;          set size 1
;          set destination myself
;          set host myself
;          set bike-status 0]
;        set open-rack open-rack - 1
;        set available-bike available-bike + 1
;        set extra-bikes extra-bikes - 1]
      ]
    if open-rack <= 0 [
      eliminate
      set open-rack num-rack/station - num-bikes/station
      set available-bike num-bikes/station]
    set station-status 0]
  set rebalance rebalance + 1
  rebalance3
end
to eliminate
  set extra-bikes extra-bikes + num-rack/station - num-bikes/station
  ask bikes with [host = myself] [ die ]
  hatch-bikes num-bikes/station [
    set color pink
    set size 1
    set destination myself
    set host myself
    set bike-status 0]
end
to rebalance3
  ifelse all? stations [station-status = 0][
  set destination one-of depots
  face destination
  fd 1
  set in-operation? false][
  rebalance1]
end
@#$#@#$#@
GRAPHICS-WINDOW
279
10
680
412
-1
-1
11.91
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
116
10
209
43
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
211
10
277
43
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

BUTTON
190
45
277
78
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
3
45
188
78
num-trucks
num-trucks
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
3
80
188
113
num-bikes/station
num-bikes/station
1
50
18.0
1
1
NIL
HORIZONTAL

SLIDER
3
115
188
148
num-stations
num-stations
1
200
70.0
1
1
NIL
HORIZONTAL

SLIDER
3
150
188
183
num-rack/station
num-rack/station
1
30
20.0
1
1
NIL
HORIZONTAL

MONITOR
3
267
103
312
Rack Full Incident
rack-full
17
1
11

MONITOR
102
220
189
265
NIL
success-trip
17
1
11

SLIDER
3
185
188
218
tripgen-frequency
tripgen-frequency
0
10
3.0
.5
1
%
HORIZONTAL

PLOT
3
436
682
556
Bikes on-the-road / on-queue at stations
time
Bikes
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"service" 1.0 0 -13840069 true "" "plot count bikes with [bike-status = 1]"
"waiting" 1.0 0 -2674135 true "" "plot count bikes with [bike-status = 2]"

PLOT
684
10
924
130
# bikes at stations
NIL
NIL
0.0
50.0
0.0
50.0
true
true
"" ""
PENS
"max" 1.0 0 -13840069 true "" "plot max [available-bike] of stations"
"min" 1.0 0 -2674135 true "" "plot min [available-bike] of stations"
"mean" 1.0 0 -16777216 true "" "plot mean [available-bike] of stations"
"median" 1.0 0 -7500403 true "" "plot median [available-bike] of stations"

PLOT
684
131
924
251
# open racks at stations
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
"max" 1.0 0 -13840069 true "" "plot max [open-rack] of stations"
"min" 1.0 0 -2674135 true "" "plot min [open-rack] of stations"
"mean" 1.0 0 -16777216 true "" "plot mean [open-rack] of stations"
"median" 1.0 0 -5987164 true "" "plot median [open-rack] of stations"

MONITOR
104
267
204
312
NIL
depart-failure
17
1
11

MONITOR
190
127
277
172
bikes on road
count bikes
17
1
11

MONITOR
190
267
276
312
NIL
rebalance
17
1
11

PLOT
3
313
276
433
# bikes
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
"on the road" 1.0 0 -16777216 true "" "plot count bikes"
"depot" 1.0 0 -2674135 true "" "plot extra-bikes"
"systemwide" 1.0 0 -10141563 true "" "plot count bikes + extra-bikes"

MONITOR
190
80
277
125
# depot bikes
extra-bikes
17
1
11

MONITOR
3
220
100
265
#bikes on queue
count bikes with [bike-status = 2]
17
1
11

SWITCH
3
10
113
43
daily-sim
daily-sim
0
1
-1000

MONITOR
191
220
276
265
empty station
count stations with [available-bike <= 0]
17
1
11

@#$#@#$#@
## WHAT IS IT?

The model pertains to the rebalancing operation of a bikesharing program, modeled after the challenges that the Capital Bikeshare if facing, at the present version.

## HOW IT WORKS

After adjusting the input parameters as you like, then click "initiate" once, then click "go." 

## HOW TO USE IT

960 ticks would be equivalent to a 16-hour/day operation. 1 tick is assumed to be equivalent to 1 minute. The maximum travel duration would be approximately 45 minutes.

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY



## EXTENDING THE MODEL

The future versions of the model should be extended to model the bikesharing trip demand, by accounting for heterogeneous characteristics for the station agents (e.g. neighborhood characteristics)and bikes (e.g. trip purposes, time, day, etc.), and so forth.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

Wilensky, U. (1999). NetLogo Model Library (Version 5.0.1)[Computer software].Evanston, CA: Northwestern University.
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

depot
false
0
Rectangle -7500403 true true 45 165 180 187
Polygon -7500403 true true 225 195 225 150 210 135 195 105 165 105 165 195
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 195 120 195 150 180 150 180 120
Circle -16777216 true false 174 174 42
Rectangle -7500403 true true 151 150 165 195
Circle -16777216 true false 114 174 42
Circle -16777216 true false 54 174 42
Circle -7500403 false true 54 174 42
Circle -7500403 false true 114 174 42
Circle -7500403 false true 174 174 42
Rectangle -6459832 true false 15 15 30 285
Rectangle -6459832 true false 30 270 285 285
Rectangle -6459832 true false 270 15 285 270
Rectangle -6459832 true false 30 15 270 30

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

thin-circle
false
0
Circle -955883 false false 42 42 216

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
  <experiment name="experiment 13" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 14" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 15" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 16" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 17" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Base" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 11 additional" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 2 additional" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 4 additional" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bikes</metric>
    <metric>success-trip</metric>
    <metric>depart-failure</metric>
    <metric>rebalance</metric>
    <metric>extra-bikes</metric>
    <metric>max [available-bike] of stations</metric>
    <metric>min [available-bike] of stations</metric>
    <metric>mean [available-bike] of stations</metric>
    <metric>median [available-bike] of stations</metric>
    <metric>max [open-rack] of stations</metric>
    <metric>min [open-rack] of stations</metric>
    <metric>mean [open-rack] of stations</metric>
    <metric>median [open-rack] of stations</metric>
    <enumeratedValueSet variable="num-bikes/station">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-rack/station">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="daily-sim">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-stations">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tripgen-frequency">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-trucks">
      <value value="4"/>
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
