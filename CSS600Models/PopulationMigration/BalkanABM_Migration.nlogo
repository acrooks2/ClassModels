breed [ people person ]
breed [ officials official ]


globals [
  migrated ;; number of people that have migrated (sum of number that have met kill criteria in simulation)
  never-taxed
  taxed-once
  taxed-twice
  taxed-more-than-twice
  young-adults-migrated
  adults-migrated
  old-adults-migrated
  elderly-migrated
  ;; corruption-index ;;the corruption index of a country
  ;; officials-number ;;the officials number per 1000 of a country
  ;; unemployment-rate ;;the unemployment rate of a country
  ;;child ;; 0-14
  ;;young-adults ;; 15-24 people of retirement age not necessarily retired 63 as percentage of pop
  ;;adults ;; 25-53
  ;;old-adults ;; 53-64
  ;;elderly ;; 64 - up
]

;;;
;;;
;;;
people-own [ taxed unemployed age tolerance ]
officials-own [ ]

to setup
  clear-all
  setup-people
  setup-officials
  setup-globals
  reset-ticks
end

to setup-people
  create-people (population * child) [ setxy random-xcor random-ycor set age 14 set size max-component-size * child  set tolerance 100]
  create-people (population * young-adults) [ setxy random-xcor random-ycor set age 25 set size max-component-size * young-adults]
  create-people (population * adults) [ setxy random-xcor random-ycor set age 53 set size max-component-size * adults]
  create-people (population * old-adults) [ setxy random-xcor random-ycor set age 64 set size max-component-size * old-adults]
  create-people (population * elderly) [ setxy random-xcor random-ycor set age 73 set size max-component-size * elderly]
  ask people [ set color white ]
  ask people [ set shape "person" ]
  ask people [ set taxed 0 ]

  ;;set days unemployed to random variable for the proper age groups
  ask n-of (population * unemployment-rate) people with [age > 15 and age < 64] [ set color grey ]
  ;;; set random tolerances for age groups
  ;;; select age group, random tolerances within selected people
  ;;; children cant leave

  ask people with [age < 14] [set tolerance 100 set unemployed 365 ]

  ;;; select all young adults set tolerance 0-100 on standard distribution
  ask people with [age > 13 and age < 26] [set tolerance random 100]

  ;;; select all adults set tolerance 0-100 on standard distribution
  ask people with [age < 27 and age < 55] [set tolerance random 100]

  ;;; select all old adults set tolerance 0-100 on std. dist
  ask people with [age < 56 and age < 65] [set tolerance random 100 ]

  ;;; select all elderly and set their tolerance
  ask people with [age > 64]
  [ifelse corruption-index = 0 [set tolerance random 100 set unemployed 350 set taxed 0] [set tolerance random 100 set unemployed 350 set taxed 3]]

end

to setup-officials
  create-officials officials-number [ setxy random-xcor random-ycor ]
  ask officials [ set color blue ]
  ask officials [ set shape "wolf" ]
  ask officials [ set size 1.5 ]
  ask n-of ( officials-number - ( officials-number * (1 - ((corruption-index * 2 ))))) officials [ set color red ]
 end

to setup-globals
  set migrated 0

  ;; set corruption-index 0.37 ;;percentage
  ;; set officials-number 110 ;;
  ;; set unemployment-rate 0.33 ;; percentage
  ;; set young-adults 0.18
  ;; set child 0.25
  ;; set adults 0.42
  ;; set old-adults 0.08
  ;; set elderly 0.07
  ;; set young-adults-thresh 8600
  ;; set adults-thresh 9000
  ;; set old-adults-thresh 9400
  ;; set elderly-thresh 9500
end

;;;
;;; GO PROCEDURE
;;;
to go
  if ticks = 365
    [stop]
  move-people
  migrate-people
  is-unemployed
  near-official
  ;; near-official
  count-taxed-buckets
  tick
end

to move-people
  ask people [
    right random 360
    forward 1
   ]
end

to migrate-people
  ;;;tolerance*will_leave>threshold

  ;;; select all young adults set tolerance 0-100 on standard distribution
  ask people with [taxed > 2 or unemployed > 300 and age > 13 and age < 26] [if tolerance * random 100 > young-adults-thresh [set young-adults-migrated young-adults-migrated + 1 set migrated migrated + 1 die]]

  ;;; select all adults set tolerance 0-100 on standard distribution
  ask people with [taxed > 2 or unemployed > 300 and age < 27 and age < 55] [if tolerance * random 100 > adults-thresh [set adults-migrated adults-migrated + 1 set migrated migrated + 1 die]]

  ;;; select all old adults set tolerance 0-100 on std. dist
  ask people with [taxed > 2 and unemployed > 320 and age < 56 and age < 65] [if tolerance * random 100 > old-adults-thresh [set old-adults-migrated old-adults-migrated + 1 set migrated migrated + 1 die]]

  ;;; select all elderly and set their tolerance
  ask people with [taxed > 2 and unemployed > 350 and age > 64] [if tolerance * random 100  > elderly-thresh [set elderly-migrated elderly-migrated + 1 set migrated migrated + 1 die]]
end

to near-official
  ;;; for every person if near a red official increase taxed [taxed = taxed+1]

  ask people
  [ ifelse corruption-index = 0 [] [let closest min-one-of other officials with [color = red] [distance myself] if (distance closest <= .25) [set taxed taxed + 1] ] ]
end

to is-unemployed
  ask people with [color = grey] [set unemployed unemployed + 1]
end

to count-taxed-buckets
  set never-taxed count people with [ taxed < 1 ]
  set taxed-once count people with [ taxed = 1 ]
  set taxed-twice count people with [ taxed = 2 ]
  set taxed-more-than-twice count people with [ taxed > 2 ]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
813
614
-1
-1
18.03030303030303
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
days
30.0

BUTTON
3
111
66
144
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

SLIDER
5
3
177
36
population
population
0
2000
900.0
75
1
NIL
HORIZONTAL

BUTTON
115
111
178
144
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
0

SLIDER
4
39
176
72
officials-number
officials-number
0
750
225.0
5
1
NIL
HORIZONTAL

SLIDER
3
75
175
108
corruption-index
corruption-index
0
1
0.38
.01
1
NIL
HORIZONTAL

SLIDER
8
146
180
179
unemployment-rate
unemployment-rate
0
.75
0.32
.01
1
NIL
HORIZONTAL

MONITOR
108
187
194
232
corrupt-officials
count officials with [ color = red ]
17
1
11

MONITOR
3
186
92
231
unemployed
count people with [ color = grey ]
17
1
11

SLIDER
11
283
183
316
child
child
0
1
0.2
.01
1
NIL
HORIZONTAL

SLIDER
11
319
183
352
young-adults
young-adults
0
1
0.35
.01
1
NIL
HORIZONTAL

SLIDER
11
355
183
388
adults
adults
0
1
0.31
.01
1
NIL
HORIZONTAL

SLIDER
11
390
183
423
old-adults
old-adults
0
1
0.07
.01
1
NIL
HORIZONTAL

SLIDER
11
425
183
458
elderly
elderly
0
1
0.07
.01
1
NIL
HORIZONTAL

TEXTBOX
29
233
179
278
Population Demographics (as percent)
12
0.0
1

TEXTBOX
414
631
564
661
User Interface
12
0.0
1

SLIDER
405
650
608
683
max-component-size
max-component-size
0
10
5.0
1
1
NIL
HORIZONTAL

MONITOR
8
463
84
508
Migrated
migrated
17
1
11

MONITOR
8
511
87
556
taxed once
taxed-once
17
1
11

MONITOR
109
464
183
509
never taxed
never-taxed
17
1
11

MONITOR
104
513
191
558
taxed twice
taxed-twice
17
1
11

MONITOR
54
557
131
602
taxed > 2
taxed-more-than-twice
17
1
11

SLIDER
890
63
1121
96
young-adults-thresh
young-adults-thresh
0
10000
7200.0
100
1
NIL
HORIZONTAL

TEXTBOX
893
13
1043
58
Tolerance thresholds for unemployment and corruption
12
0.0
1

SLIDER
893
104
1123
137
adults-thresh
adults-thresh
0
10000
7000.0
100
1
NIL
HORIZONTAL

SLIDER
895
144
1124
177
old-adults-thresh
old-adults-thresh
0
10000
9500.0
100
1
NIL
HORIZONTAL

SLIDER
897
182
1125
215
elderly-thresh
elderly-thresh
0
9500
9500.0
100
1
NIL
HORIZONTAL

PLOT
823
374
1371
610
Migration 
Days
#Migrated
0.0
365.0
0.0
20.0
true
true
"" ""
PENS
"Total migrated" 1.0 0 -16777216 true "" "plot migrated"
"young adults migrated" 1.0 0 -7500403 true "" "plot young-adults-migrated"
"adults migrated" 1.0 0 -2674135 true "" "plot adults-migrated"
"old-adults-migrated" 1.0 0 -955883 true "" "plot old-adults-migrated"
"elderly-migrated" 1.0 0 -6459832 true "" "plot elderly-migrated"
"pen-5" 1.0 0 -1184463 true "" ""

MONITOR
1274
147
1363
192
Population #
count people
17
1
11

PLOT
822
217
1370
367
Remaining Population
NIL
NIL
0.0
366.0
0.0
10.0
true
true
"" ""
PENS
"People Remaining" 1.0 0 -16777216 true "" "plot count people"

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
