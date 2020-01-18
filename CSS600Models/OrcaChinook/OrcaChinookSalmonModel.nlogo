breed [orcas an-orca]
breed [salmon a-salmon]
breed [fishermen fisherman]

fishermen-own
[
  salmon-caught ;; to keep track of number of salmon caught for MSY
  ]


orcas-own
[
  age-orcas ;; age of orca
  orcas-life-expectancy  ;; maximum age range that an orca can reach
]

salmon-own
[
  age-salmon ;; age of salmon
  salmon-life-expectancy  ;; maximum age range that a salmon can reach
]

to setup
  clear-all
  reset-ticks

  ask patches [ set pcolor blue ] ;; nearshore ocean

  set-default-shape salmon "fish"
    create-salmon initial-number-salmon ;; uses the value of the number slider to create salmon
    [ initial-salmon-vars  ;; life expectancy code from/adapted from Wilensky, U. (1998). NetLogo Wealth Distribution model.
  set age-salmon random salmon-life-expectancy ]
    ask salmon [
      set color gray
    set size 1
    setxy random-xcor random-ycor ]

  set-default-shape orcas "shark"
  create-orcas initial-number-orcas ;; uses the value of the number slider to create orcas
  [ initial-orca-vars  ;; life expectancy code from/adapted from Wilensky, U. (1998). NetLogo Wealth Distribution model.
  set age-orcas random orcas-life-expectancy ]
    ask orcas [
      set color black
    set size 4.5
    setxy random-xcor random-ycor ]

  set-default-shape fishermen "boat top"
  create-ordered-fishermen initial-number-fishermen ;;creates fishermen (fishermen code adapted from Marlantas, A. (2008). Lake Victoria model.)
  [
  set color orange
  set size 6
  facexy -2 0
  setxy random-xcor random-ycor
  ]

  update-plot1
  update-plot2
  reset-ticks
end

to initial-salmon-vars  ;; life expectancy code from/adapted from Wilensky, U. (1998). NetLogo Wealth Distribution model.
  set age-salmon 1
  set salmon-life-expectancy salmon-life-expectancy-min +
                        random (salmon-life-expectancy-max - salmon-life-expectancy-min + 1)
end

to initial-orca-vars  ;; life expectancy code from/adapted from Wilensky, U. (1998). NetLogo Wealth Distribution model.
  set age-orcas 1
  set orcas-life-expectancy orcas-life-expectancy-min +
                        random (orcas-life-expectancy-max - orcas-life-expectancy-min + 1)
end

to go
  if ticks >= 200 [stop]

  ask salmon [
    move-salmon      ;; salmon swim
    reproduce-salmon  ;; salmon reproduction
    salmon-age-die   ;; salmon reach life expectancy
    too-many-salmon  ;; salmon reach carrying capacity
  ]

  ask orcas [
    move-orcas        ;; orcas look for salmon
    if count salmon >= 50 [eat-salmon]  ;; orcas eat salmon
    orcas-age-die     ;; orcas reach life expectancy
    reproduce-orcas   ;; orca reproduction
    if count salmon < 50 [ die ]  ;; not enough salmon to sustain orcas
    too-many-orcas   ;; orcas reach carrying capacity
  ]

  ask fishermen [
     troll  ;; fishermen troll for salmon
     if count salmon >= maximum-sustainable-yield [catch-salmon]
  ]
  tick ;; increase the tick counter by 1 each time through
  update-plot1  ;; update salmon population plot
  update-plot2  ;; update orca population plot
end

to move-salmon
  right random 360
  forward 1
end

to move-orcas
  right random 50
  left random 50
  forward 1
end

to troll ; fishermen will "troll" rather than move randomly (fishermen code adapted from Marlantas, A. (2008). Lake Victoria model.)
   right 0
   forward 1
end

to eat-salmon  ;; Orcas catching salmon
  ask orcas
      [let prey one-of salmon-here                    ;; tries to locate salmon (code adapted from Marlantas, A. (2008). Lake Victoria model.)
  if prey != nobody
   [ ask prey [ die ]]]                ;; prey die
end

to catch-salmon  ;;Fishermen catching salmon
  ask fishermen
      [let prey one-of salmon-here                    ;; tries to locate salmon
  if prey != nobody
   [ ask prey [ die ]]]                ;; prey die
        end

to salmon-age-die  ;; life expectancy code from/adapted from Wilensky, U. (1998). NetLogo Wealth Distribution model.
  set age-salmon (age-salmon + 1) ;; if older than the life expectancy then die
  if (age-salmon >= salmon-life-expectancy)
  [die]
end

to orcas-age-die  ;; life expectancy code from/adapted from Wilensky, U. (1998). NetLogo Wealth Distribution model.
  set age-orcas (age-orcas + 1) ;; if older than the life expectancy then die
  if (age-orcas >= orcas-life-expectancy)
  [die]
end

to reproduce-salmon
    if age-salmon > 3 [
      hatch 1 [ rt random-float 360 fd 1
        set color gray
      set shape "fish"
      set size 1
      set age-salmon 0
    ]
  ]
end

to reproduce-orcas
    if (age-orcas > 17) and (age-orcas < 45) [
      hatch 1 [ rt random-float 360 fd 1
        set color black
      set shape "shark"
      set size 4.5
      set age-orcas 0
      ]
      ]
end

to too-many-salmon  ;; carrying capacity code adapted from Wilensky, U. (1997). NetLogo Simple Birth Rates model.
  let num-salmon count salmon
  if num-salmon <= 7000 ;; kill salmon in excess of carrying capacity
    [ stop ]
  let chance-to-die (num-salmon - 7000) / num-salmon
    ask salmon
  [
    if random-float 1.0 < chance-to-die
      [ die ]
  ]
end

to too-many-orcas  ;; carrying capacity code adapted from Wilensky, U. (1997). NetLogo Simple Birth Rates model.
  let num-orcas count orcas
  if num-orcas <= 300 ;; kill turtles in excess of carrying capacity
    [ stop ]
  let chance-to-die (num-orcas - 300) / num-orcas
    ask orcas
  [
    if random-float 1.0 < chance-to-die
      [ die ]
  ]
end

to update-plot1
  set-current-plot "Chinook-Salmon-Population"
  set-current-plot-pen "Salmon"
  plot count salmon
end

to update-plot2
  set-current-plot "Orca-Population"
  set-current-plot-pen "orcas"
  plot count orcas
end
@#$#@#$#@
GRAPHICS-WINDOW
293
10
764
482
-1
-1
14.030303030303031
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
1
1
1
ticks
30.0

BUTTON
12
13
95
74
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
105
13
191
75
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
0

SLIDER
12
110
285
143
initial-number-salmon
initial-number-salmon
0
5000
5000.0
100
1
(x200) individuals
HORIZONTAL

TEXTBOX
13
92
163
110
Chinook Salmon Variables
11
0.0
1

SLIDER
12
152
240
185
salmon-life-expectancy-min
salmon-life-expectancy-min
0
10
10.0
1
1
years
HORIZONTAL

SLIDER
12
194
245
227
salmon-life-expectancy-max
salmon-life-expectancy-max
0
10
7.0
1
1
years
HORIZONTAL

TEXTBOX
15
248
165
266
Orca Variables
11
0.0
1

SLIDER
12
268
230
301
initial-number-orcas
initial-number-orcas
0
200
200.0
1
1
individuals
HORIZONTAL

SLIDER
12
310
239
343
orcas-life-expectancy-min
orcas-life-expectancy-min
0
100
40.0
1
1
years
HORIZONTAL

SLIDER
12
350
244
383
orcas-life-expectancy-max
orcas-life-expectancy-max
0
100
100.0
1
1
years
HORIZONTAL

TEXTBOX
15
406
165
424
Fishery Variables
11
0.0
1

SLIDER
14
427
231
460
initial-number-fishermen
initial-number-fishermen
0
20
20.0
1
1
boats
HORIZONTAL

PLOT
772
10
1018
205
Chinook-Salmon-Population
Time (iterations)
Salmon Population (x100)
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"Salmon" 1.0 0 -14737633 true "" "plot count salmon"

PLOT
773
215
1019
422
Orca-Population
Time (iterations)
Orca Population (individuals)
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"Orcas" 1.0 0 -16777216 true "" "plot count orcas"

SLIDER
4
468
290
501
maximum-sustainable-yield
maximum-sustainable-yield
0
5000
5000.0
100
1
(x200) salmon
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

boat top
true
0
Polygon -7500403 true true 150 1 137 18 123 46 110 87 102 150 106 208 114 258 123 286 175 287 183 258 193 209 198 150 191 87 178 46 163 17
Rectangle -16777216 false false 129 92 170 178
Rectangle -16777216 false false 120 63 180 93
Rectangle -7500403 true true 133 89 165 165
Polygon -11221820 true false 150 60 105 105 150 90 195 105
Polygon -16777216 false false 150 60 105 105 150 90 195 105
Rectangle -16777216 false false 135 178 165 262
Polygon -16777216 false false 134 262 144 286 158 286 166 262
Line -16777216 false 129 149 171 149
Line -16777216 false 166 262 188 252
Line -16777216 false 134 262 112 252
Line -16777216 false 150 2 149 62

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

fish 2
false
0
Polygon -1 true false 56 133 34 127 12 105 21 126 23 146 16 163 10 194 32 177 55 173
Polygon -7500403 true true 156 229 118 242 67 248 37 248 51 222 49 168
Polygon -7500403 true true 30 60 45 75 60 105 50 136 150 53 89 56
Polygon -7500403 true true 50 132 146 52 241 72 268 119 291 147 271 156 291 164 264 208 211 239 148 231 48 177
Circle -1 true false 237 116 30
Circle -16777216 true false 241 127 12
Polygon -1 true false 159 228 160 294 182 281 206 236
Polygon -7500403 true true 102 189 109 203
Polygon -1 true false 215 182 181 192 171 177 169 164 152 142 154 123 170 119 223 163
Line -16777216 false 240 77 162 71
Line -16777216 false 164 71 98 78
Line -16777216 false 96 79 62 105
Line -16777216 false 50 179 88 217
Line -16777216 false 88 217 149 230

fish 3
false
0
Polygon -7500403 true true 137 105 124 83 103 76 77 75 53 104 47 136
Polygon -7500403 true true 226 194 223 229 207 243 178 237 169 203 167 175
Polygon -7500403 true true 137 195 124 217 103 224 77 225 53 196 47 164
Polygon -7500403 true true 40 123 32 109 16 108 0 130 0 151 7 182 23 190 40 179 47 145
Polygon -7500403 true true 45 120 90 105 195 90 275 120 294 152 285 165 293 171 270 195 210 210 150 210 45 180
Circle -1184463 true false 244 128 26
Circle -16777216 true false 248 135 14
Line -16777216 false 48 121 133 96
Line -16777216 false 48 179 133 204
Polygon -7500403 true true 241 106 241 77 217 71 190 75 167 99 182 125
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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

shark
false
0
Polygon -7500403 true true 283 153 288 149 271 146 301 145 300 138 247 119 190 107 104 117 54 133 39 134 10 99 9 112 19 142 9 175 10 185 40 158 69 154 64 164 80 161 86 156 132 160 209 164
Polygon -7500403 true true 199 161 152 166 137 164 169 154
Polygon -7500403 true true 188 108 172 83 160 74 156 76 159 97 153 112
Circle -16777216 true false 256 129 12
Line -16777216 false 222 134 222 150
Line -16777216 false 217 134 217 150
Line -16777216 false 212 134 212 150
Polygon -7500403 true true 78 125 62 118 63 130
Polygon -7500403 true true 121 157 105 161 101 156 106 152

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
