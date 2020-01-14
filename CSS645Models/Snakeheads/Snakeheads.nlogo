;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; create breeds ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [killifishes killifish]
breed [snakeheads snakehead]
snakeheads-own [ age gender lastMeal ]
killifishes-own [ age gender ]

globals [ snakeheads-born killifishes-born killifishes-dead snakeheads-starve females males snakeheadAdultAge lastGender]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;setup;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  ask patches [set pcolor blue]

  set females 0
  set males 0
  set snakeheadAdultAge 130 ;; this age represents sexual maturity at which point spawning can occur

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; set up killifishes ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-default-shape killifishes "killifish"
  create-killifishes killifish-number ;; use slider to set initial number of killifishes
  [
    setxy random-xcor random-ycor
    set size 1.5
    set age random (max-killifishes-age) ;; set initial age to random value between 0 and 103 weeks old (2 yrs)
    ifelse (lastGender = 0)  [set lastGender 1] [set lastGender 0] ;; flipflop gender each time to get even distribution of males/females
    set gender lastGender ; 0 or 1
    ifelse gender = 0 [set color pink] [set color cyan]
  ]


  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; set up snakeheads ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set-default-shape snakeheads "snakehead"
  create-snakeheads snakehead-number ;; use slider to set initial number of snakeheads
  [
    setxy random-xcor random-ycor
    set size 2.5
    set age random (max-snakeheads-age) ;; set initial age to random value between 0 and 311 weeks (6 yrs)
    set gender random 2 ; 0 or 1
    ifelse gender = 0 [set color red] [set color green]

    TrackAdults age gender 1 ;; used to track number of adult female and male snakeheads for purposes of mating, will use to calculate proportion
 ]

  reset-ticks ;;; one tick equals one week
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; track age ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; track counts for adult male and female snakeheads when they 1) are intially created 2) are born 3) age 4) die
;; this function calls those cases
to TrackAdults [ ageX genderX delta ]

  ;; delta is 1 for birth or getting older, but -1 for death; if not of age yet the function is not triggered
  if ageX >= snakeheadAdultAge ;; only increase when of age
  [
      ifelse genderX = 0
        [ set females females + delta ]
        [ set males males + delta ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; run ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  if not any? turtles [stop]
  ;if ticks > 572 [stop]
  ;if not any? snakeheads [stop]
  ;if not any? killifishes [stop]

  ask snakeheads
  [
    move-snakeheads
    catch-killifishes
    spawn-snakeheads
    set age age + 1
    if age = snakeheadAdultAge
      [ TrackAdults age gender 1 ] ;; only increase the count after 130th birthday, not every year

    if age > max-snakeheads-age
    [
      TrackAdults age gender -1 ;; subtract 1
      die
    ]
  ]

  ask killifishes
  [
    move-killifishes
    spawn-killifishes
    set age age + 1
    if age > max-killifishes-age
    [
      set killifishes-dead killifishes-dead + 1
      die
    ]
  ]

  tick
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; move ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to move-snakeheads
  right random 360 left random 360
  forward 3
end

to move-killifishes
    right random 360 left random 360
    forward 2
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; EAT killifish ;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to catch-killifishes  ;;snakehead procedure

  let weeknum remainder (ticks + 52) 52  ;; which week number is it anually; use remainder to allow for repeating of valid week number after year 1
  ;; Prior to age 1 year(52 weeks) they are assumed to eat something else and do not starve
  ;; they eat 90% of food between weeks 9-45 (anually)
  if age > 52
  [
    ifelse weeknum > 8 and weeknum < 46 ;; During this time of year they eat every week
    [ TryToEat ]
    [ if random 10 = 1 [ TryToEat ] ] ;; only eat 10% of time during winter months (nov - feb)

    ;; if there is no food for a long time they starve;; idea adapted from Sharks and Minnows Evolution netlogo tutorial
    if lastMeal > maxWeeksBeforeStarving
    [
      set snakeheads-starve snakeheads-starve + 1
      TrackAdults age gender -1 ;; subtract 1 adult
      die
    ]
  ]

end

to TryToEat

      ;;  If snakeheads are close together, spread out to find food
      let foodCompetitor one-of snakeheads in-radius 1 ;; creates new local variable; if there are snakeheads w/in radius of 1
      ;; chose one at random and make it a food competitor
      if foodCompetitor != nobody and lastMeal > 2 ;; if food competitor present and it's been more than 2 weeks, move for food
        [ left random 360 forward 6 ]
      ;; NOTE -here seemed too restrictive, snakeheads were starving a lot; in-radius seems more realistic - will thrust for food

      let prey one-of killifishes in-radius 3 ;; example taken from lynx hare netlogo tutorial
      ifelse prey != nobody
      [
        ask prey [die]
        set lastMeal 0 ;; just ate
      ]
      ;; else didnt eat
      [ set lastMeal lastMeal + 1 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;   spawn  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to spawn-killifishes

  ; which week number is it anually -
  let weeknum remainder (ticks + 52) 52

  if weeknum = 28 ;; once a year in the summertime.
  [
    if age >= 51 and gender = 0 ;; adult females
    [
      let numKids (( number-killifish-kids) + 1)
      set killifishes-born killifishes-born + numKids
      hatch-killifishes numKids

      [
        set age 0
        ifelse (lastGender = 0)  [set lastGender 1] [set lastGender 0] ;; flipflop gender each time to even numbers
        set gender lastGender ; 0 or 1
        ifelse gender = 0 [set color pink] [set color cyan]
      ]
    ]
  ]
end


to spawn-snakeheads ;;chose to start at week 24 to account for water temp)and

  ; which week number is it anually -
  let weeknum remainder (ticks + 52) 52

  ;; starting at week 24, spawn snakehead per-year, weeks in a row; this is controlled by slider
  if weeknum > 23 and weeknum < (24 + snakehead-spawns-per-year)  ;; how many times a year do they breed
  [
    if age > snakeheadAdultAge and gender = 0 ;; adult females spawn
    [
      ;;example, 1 male adult and 1 female adult get together and spawn. This means need 1 male for every female.
      ;; if 10 males 5 females = 100% of females spawn
      ;; but if 5 males, 10 females = 50% of females spawn
      let PercentFemalesToSpawn 0
      if females > 0 ;; avoids division by zero. else leave as 0%
        [ set PercentFemalesToSpawn ( males / females ) ] ;;adults

      ;;    10 females but only 50% can spawn
      ;;    random 10 means 0-9
      ;;    is that 0-9 <= 50%, meaning < 5
      ;;    thus 0-4 will spawn
      if females != 0 and random females <= (females * PercentFemalesToSpawn) ;;idea adapted/morphed from monte carlo implementations (wolf/sheep, wolf/moose, etc)
      [
        ;; ok - if female pregnant - how many?
        let numKids ((random number-snakehead-kids) + 1) ;; random 54 to 76 (via slider)
        set snakeheads-born snakeheads-born + numKids
        hatch-snakeheads numKids
        [
          set age 0 ;; born age zero, consequently not an adult
          set gender random 2 ; 0 or 1
          ifelse gender = 0 [set color red] [set color green]
          set lastMeal 0 ; start out not hungry
        ]
      ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; plot ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-plot
  set-current-plot "population"
  set-current-plot-pen "killifishes"
  plot count killifishes
  set-current-plot-pen "snakeheads"
  plot count snakeheads
 ; plot count snakeheads-born

end


@#$#@#$#@
GRAPHICS-WINDOW
398
12
1199
814
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-30
30
-30
30
1
1
1
weeks
30.0

BUTTON
6
10
75
43
Set Up
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
95
10
158
43
Go
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
8
56
180
89
killifish-number
killifish-number
0
500
100.0
1
1
NIL
HORIZONTAL

SLIDER
8
98
180
131
snakehead-number
snakehead-number
0
500
6.0
1
1
NIL
HORIZONTAL

PLOT
9
568
310
818
population
time
Totals
0.0
520.0
0.0
500.0
true
true
"" ""
PENS
"killifishes" 1.0 0 -2064490 true "" "plot count killifishes"
"snakeheads" 1.0 0 -13840069 true "" "plot count snakeheads"

SLIDER
8
185
201
218
max-snakeheads-age
max-snakeheads-age
0
416
330.0
1
1
NIL
HORIZONTAL

MONITOR
10
514
90
559
# Snakeheads
count snakeheads
17
1
11

MONITOR
99
514
173
559
# Killifishes
count killifishes
17
1
11

SLIDER
9
145
201
178
max-killifishes-age
max-killifishes-age
0
208
104.0
1
1
NIL
HORIZONTAL

MONITOR
202
514
307
559
# Snakeheads born
snakeheads-born
17
1
11

SLIDER
10
233
226
266
maxWeeksBeforeStarving
maxWeeksBeforeStarving
0
52
12.0
1
1
NIL
HORIZONTAL

SLIDER
10
274
201
307
number-snakehead-kids
number-snakehead-kids
54
76
54.0
1
1
NIL
HORIZONTAL

SLIDER
10
311
202
344
number-killifish-kids
number-killifish-kids
2
13
2.0
1
1
NIL
HORIZONTAL

SLIDER
13
355
249
388
snakehead-spawns-per-year
snakehead-spawns-per-year
0
5
1.0
1
1
NIL
HORIZONTAL

MONITOR
201
463
303
508
NIL
snakeheads-starve
17
1
11

MONITOR
10
464
165
509
Adult Female Snakeheads
females
17
1
11

MONITOR
10
415
151
460
Adult Male Snakeheads
males
17
1
11

MONITOR
200
412
303
457
# Killifishes born
killifishes-born
17
1
11

MONITOR
270
360
378
405
# dead killifishes 
killifishes-dead
17
1
11

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

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

killifish
false
0
Polygon -1184463 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1184463 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30
Polygon -1184463 true false 138 207 108 237 63 237 78 222 63 177

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

snakehead
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
Polygon -7500403 true true 242 102 242 73 218 67 191 71 168 95 181 101
Line -16777216 false 226 102 158 95
Line -16777216 false 171 208 225 205
Polygon -1 true false 252 111 232 103 213 132 210 165 223 193 229 204 247 201 237 170 236 137
Polygon -1 true false 135 98 140 137 135 204 154 210 167 209 170 176 160 156 163 126 171 117 156 96
Polygon -16777216 true false 192 117 171 118 162 126 158 148 160 165 168 175 188 183 211 186 217 185 206 181 172 171 164 156 166 133 174 121
Polygon -1 true false 40 121 46 147 42 163 37 179 56 178 65 159 67 128 59 116

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
  <experiment name="vary snakehead pop number" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count Killifishes = 0 or
count Snakeheads = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="snakehead-number" first="2" step="2" last="25"/>
  </experiment>
  <experiment name="vary snakehead pop number" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>count Killifishes = 0 or
count Snakeheads = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="snakehead-number" first="2" step="2" last="25"/>
  </experiment>
  <experiment name="Killifish population_baseline" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="208"/>
    <exitCondition>count killifishes = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="killifish-number" first="25" step="75" last="300"/>
  </experiment>
  <experiment name="snakehead population_baseline" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="208"/>
    <exitCondition>count snakeheads  = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="snakehead-number" first="6" step="25" last="100"/>
    <enumeratedValueSet variable="number-snakehead-kids">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxWeeksBeforeStarving">
      <value value="208"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="260"/>
    <metric>count snakeheads</metric>
    <metric>count killifishes</metric>
    <enumeratedValueSet variable="killifish-number">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="snakehead-number" first="6" step="10" last="50"/>
    <enumeratedValueSet variable="number-snakehead-kids">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-killifish-kids">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="snakehead population_baseline2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="208"/>
    <exitCondition>count snakeheads  = 0</exitCondition>
    <metric>count turtles</metric>
    <steppedValueSet variable="snakehead-number" first="25" step="75" last="250"/>
    <enumeratedValueSet variable="number-snakehead-kids">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxWeeksBeforeStarving">
      <value value="208"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 1_new" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="260"/>
    <metric>count snakeheads</metric>
    <metric>count killifishes</metric>
    <enumeratedValueSet variable="killifish-number">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="snakehead-number" first="6" step="10" last="50"/>
    <enumeratedValueSet variable="number-snakehead-kids">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-killifish-kids">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxWeeksBeforeStarving">
      <value value="12"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2" repetitions="25" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="260"/>
    <metric>count snakeheads</metric>
    <metric>count killifishes</metric>
    <enumeratedValueSet variable="killifish-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="snakehead-number">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-snakehead-kids">
      <value value="54"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-killifish-kids">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxWeeksBeforeStarving">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="snakehead-spawns-per-year">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 3" repetitions="25" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="260"/>
    <metric>count snakeheads</metric>
    <metric>count killifishes</metric>
    <enumeratedValueSet variable="killifish-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="snakehead-number">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-snakehead-kids">
      <value value="76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-killifish-kids">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maxWeeksBeforeStarving">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="snakehead-spawns-per-year">
      <value value="1"/>
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
