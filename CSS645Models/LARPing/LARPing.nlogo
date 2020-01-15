extensions [ gis csv ]
globals [ DC_quads DC_boundaries avg-time-free avg-times-arrested avg-recid-rate ]
patches-own [quadrant boundary? ]
turtles-own [ age times-incarcerated resources resource-count recid-rate status home-quad sentence-duration incarceration-start incar-length ticks-free ]

to Setup
  reset-ticks
  ask turtles [die]
  ;set turtle attributes
  ;Create turtles. Move turtles to quadrant. Set turtle home-quad to quadrant
  create-turtles 7300
  ask turtles [set color blue]
  ask turtles [move-to one-of patches with [quadrant = one-of ["NW" "NE" "SE" "SW"] and boundary? = 0]]
  ask turtles [set home-quad [quadrant] of patch-here]
  ask turtles [set color blue]
  ask turtles [set age random 15 + 18]

  ;set turtle status (incarcerated or non-incarcerated) for Incarcerated slider  of turtles and set initial sentence duration
  ask turtles [set status "not-incarcerated" set times-incarcerated 1]
  ask n-of (count turtles * (Percent_Incarcerated / 100)) turtles [set status "incarcerated" set color 45]
  ask turtles with [status = "incarcerated"] [set sentence-duration random 12 + 1 set incarceration-start 0]

  ;set recidivism rate for non-incarcerated turtles to from interface
  ask turtles [set recid-rate random-normal Recidivism_Rate 10]

  ;The code below turns the turtle attribute "resources" into a list that will be used in the model
  ask turtles [set resources (list)]

end

to Draw
  clear-all
  clear-drawing
  reset-ticks
  ask patches [set pcolor white]
  ;Load GIS into NetLogo for visualization
  gis:load-coordinate-system (word "Data/DC_Quadrants.prj")
  set DC_quads gis:load-dataset "Data/DC_Quadrants.shp"
  set DC_boundaries gis:load-dataset "Data/DC_boundaries.shp"
  gis:set-world-envelope (gis:envelope-of DC_quads)
  gis:apply-coverage DC_quads "QUADRANT" quadrant
  ask patches
  [
    if quadrant = "NW" [set pcolor 36]
    if quadrant = "NE" [set pcolor 36]
    if quadrant = "SE" [set pcolor 36]
    if quadrant = "SW" [set pcolor 36]
  ]
  gis:set-drawing-color brown
  gis:draw DC_quads 1
  ;gis:fill DC_quads 1

  gis:set-drawing-color black
  gis:draw DC_boundaries 4

  ask patches
     [set boundary? 0
    if gis:intersects? DC_boundaries self
         [set boundary? 1 ] ]
end

;Procedures for Go
to go
  if ticks >= 120 [ stop ]
  tick
  assign-resources
  free-to-incarcerated
  check-incarceration-length
  incarcerated-to-free
  check-freedom-length
  kill-old-turtles
  update-globals

end

;agents check their incarceration lenght opposed to the number of ticks that have passed
to check-incarceration-length
  ask turtles with [status = "incarcerated"] [set incar-length (ticks - incarceration-start)]

end


to incarcerated-to-free
  ;procedures for agents when released from jail
  ask turtles with [status = "incarcerated"] [
    if sentence-duration = incar-length [
      set status "not-incarcerated"
      set color blue
      set size 1
      set incarceration-start 0
      set incar-length 0
      set sentence-duration 0]]

end

to free-to-incarcerated
  ;procedures when sentenced to jail
  ask turtles with [status = "not-incarcerated"]
  [if (random-float 100 < recid-rate)
    [set sentence-duration random 12 + 1
     set size (2)
     set status "incarcerated"
     set color 45
     set incarceration-start ticks
     set times-incarcerated (times-incarcerated + 1)
     set resources (list)]]

end

to assign-resources
  ;each year of the simulation the model will add additional re-entry programs to agent's "resource" list and reduces their recidivism rate
  ;agents age 1 year every 4 ticks

  if ticks mod 4 = 0 [
    ask n-of Housing turtles with [status = "not-incarcerated"] [set resources lput "housing" resources]
    ask n-of Employment turtles with [status = "not-incarcerated"]  [set resources lput "employment" resources]
    ask n-of Reach_In turtles with [status = "incarcerated"]  [set resources lput "reach_in" resources]
    ask n-of Record_Expungement turtles with [status = "not-incarcerated"] [if ticks-free >= 4 [set resources lput "re" resources]]
    ask turtles [set age (age + 1)]


  ;Remove duplicates (if any) from the 'resources' list
   ask turtles [set resources remove-duplicates resources]

  ;The following code lowers the recidivism rates for agents based on the type of reentry program they are accepted to.
   ask turtles with [member? "housing" resources] [set recid-rate (recid-rate * 0.6) set size 2]
   ask turtles with [member? "employment" resources] [set recid-rate (recid-rate * 0.8) set size 4]
   ask turtles with [member? "re" resources] [set recid-rate (recid-rate * 0.8) set size 4]
   ask turtles with [member? "reach_in" resources] [set recid-rate (recid-rate * 0.76)]

   ; the following code sets the cumulative effect of being selected to multiple reentry programs
   ask turtles with [length resources = 3] [set recid-rate (recid-rate * 0.05) set color green set size 4] ;author's estimation
   ask turtles with [length resources = 4 ] [set recid-rate (recid-rate * 0.03) set size 6] ;author's estimation
  ]
end

to check-freedom-length
  ;; agents increase the "ticks-free" variable by 1 each tick they spend in a "not-incarcerated status"
  ask turtles with [status = "not-incarcerated"] [set ticks-free (ticks-free + 1)]

end

to kill-old-turtles ;kills agents once they reach 65 years old. At that time they are unlikely to be arrested.
  ask turtles [if age > 65 [die]]

end

to update-globals
 set avg-time-free mean [ticks-free] of turtles
 set avg-times-arrested mean [times-incarcerated] of turtles
 set avg-recid-rate mean [recid-rate] of turtles

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
629
430
-1
-1
3.0
1
10
1
1
1
0
0
0
1
-68
68
-68
68
0
0
1
ticks
30.0

BUTTON
4
32
79
65
1. Draw
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
73
32
152
65
2. Setup
Setup
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
5
69
153
102
3. Go
Go
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
0
149
172
182
Housing
Housing
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
0
189
172
222
Employment
Employment
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
0
228
172
261
Reach_In
Reach_In
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
-1
266
171
299
Record_Expungement
Record_Expungement
0
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
-1
308
171
341
Recidivism_Rate
Recidivism_Rate
0
100
68.0
1
1
NIL
HORIZONTAL

SLIDER
-2
353
170
386
Percent_Incarcerated
Percent_Incarcerated
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
642
18
842
168
Incarcerated_Agents
Time
# of Agents
0.0
160.0
0.0
7300.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot count turtles with [status = \"incarcerated\"]"

PLOT
643
185
845
335
# Of Arrests Vs Time Released
Time
Average Time Free
0.0
120.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -11085214 true "" "plot avg-time-free"

MONITOR
208
433
301
478
NIL
count turtles
17
1
11

MONITOR
411
433
512
478
num incarcerated
count turtles with [status = \"incarcerated\"]
17
1
11

MONITOR
517
433
629
478
repeat offender
count turtles with [times-incarcerated > 1]
17
1
11

MONITOR
421
483
627
528
repeat offenders w resources
count turtles with [times-incarcerated > 1 and length resources > 0]
17
1
11

MONITOR
204
484
410
529
number of all people with resources
count turtles with [length resources > 0]
17
1
11

MONITOR
309
434
405
479
avg recid-rate
avg-recid-rate
17
1
11

PLOT
-1
388
197
526
Average Recidivism Rate
Time
Average Recidivism Rate
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot avg-recid-rate"

PLOT
639
377
839
527
Average Arrests per Agent
Time
# of Arrests
0.0
0.0
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot avg-times-arrested"

@#$#@#$#@
## WHAT IS IT?

This model explores how criminal re-entry programs, as used across the United States and around the world, can help to lower the recidivism risk of criminal offenders. 

The model is intended to act as a tool for policy makers to examine the potential effects that a layered approach to re-entry programs can have on their respective cities, towns, or states. 

Four distinct and overlapping re-entry programs utilized within this model: Housing, Record Expungement, Employment and Reach-In services. All of these programs have been adopted in some part of the United States with varying levels of success at lowering recidivism. 

Users of this model can assess how creating and adjusting budgets to support one, few, or all of these types of re-entry programs can slow the rate of rearrest for offenders within their jurisdiction.

## HOW IT WORKS

The model demonstrates agents being arrested over time. Once an agent becomes incarcerated it turns yellow. Agents who are released from prison change their status to "not-incarcerated" and turn blue and slightly larger. 

Agents lower their recidivism rate if and when they are accepted to reentry programs. When an agent is accepted to three or more reentry programs they turn green, indicating that they as likely to be rearrested as any random individual. 

## HOW TO USE IT

To initialize the model click the Draw then Setup buttons. This will generate the model environment and the default agentset. 

The reentry program sliders; Housing, Employment, Reach_in and Record_Expungement can be set between 0 and 200 to match a user's budget capabilities. Set the sliders to indicate how many agents per year can be accepted into each program.

The Recidivism_Rate and Percent_Incarcerated sliders set the initial recidivism rate of the agents based on the recidivism rate of the user's city and the number of agents who will begin in an incarcerated status. 

## THINGS TO NOTICE

Some interesting things to notice are as follows:

- Agents can still become incarcerated once accepted into a reentry program
- The trend in incarceration status can fluctuate depending on the settings

## THINGS TO TRY

- After estimating the cost of each program, try adjusting the sliders to the maximum and minimum that your budget can allow for. Then see what combinations of reentry programs can lower the average recidivism rate the fastest. 

## EXTENDING THE MODEL

There are several planned expansions of this current model:

- Add arrest metadata to couple agent location within the simulation to the location of their arrest.

- Add demographic data (age, sex, ethnicitiy, etc.) for amore complex holistic view of the criminal justice system.

- Telecouple this model to our PAROLE model to add behavioral complexity and test criminal behavior and parole decisionmaking theories. 

## NETLOGO FEATURES

N/A

## RELATED MODELS

N/A

## CREDITS AND REFERENCES

The GIS shapefile for this model was obtained from the government of D.C.'s Open Data DC repository. (website: https://dc.gov/page/open-data)  
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
  <experiment name="Recidivism Experiment 4" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [status = "incarcerated"]</metric>
    <metric>avg-time-free</metric>
    <metric>avg-times-arrested</metric>
    <metric>count turtles with [times-incarcerated &gt; 1 and length resources &gt; 0]</metric>
    <enumeratedValueSet variable="Employment">
      <value value="0"/>
      <value value="10"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Reach_In">
      <value value="0"/>
      <value value="10"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent_Incarcerated">
      <value value="0"/>
      <value value="10"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Recidivism_Rate">
      <value value="0"/>
      <value value="10"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Record_Expungement">
      <value value="0"/>
      <value value="10"/>
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Housing">
      <value value="0"/>
      <value value="10"/>
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Employment">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Reach_In">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent_Incarcerated">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Recidivism_Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Record_Expungement">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Housing">
      <value value="0"/>
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
