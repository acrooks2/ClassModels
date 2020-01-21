breed [asiminas asimina]
breed [nectars nectar]
breed [caterpillars caterpillar]
breed [butterflies butterfly]
breed [eggs egg]

patches-own [
  energy
  ;n-asimina
  ;n-nectar ]
]

caterpillars-own [ life ]
butterflies-own [ life ]
eggs-own [ life ]

To setup

  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks

  setup-patches

  set-default-shape asiminas "plant"
  create-asiminas number-of-asiminas [
    set color yellow
    setxy random-xcor random-ycor
    set energy energy-from-asimina ]


  set-default-shape nectars "plant"
  create-nectars number-of-nectars [
    setxy random-xcor random-ycor
    set color blue
    set energy energy-from-nectar ]

  set-default-shape caterpillars "bug"

  create-eggs number-of-eggs [
    setxy random-xcor random-ycor
    set color orange
    set life 1
  ]

  set-default-shape butterflies "butterfly"

  set-default-shape eggs "dot"


  plot count Eggs

  plot count Butterflies

end





to go

  asimina-grow-new-leaves ; Simulates leaf flush in the spring. New leaves form that are most palatable to caterpillars

  ask butterflies
  [
    lay-eggs ; ask the butterflies to lay eggs some proportion of which will eclose into caterpillars
  ]

  eclose ; Eggs laid by adults emerging from the previous season as new leaves are growing, hatch into caterpillars

  ask caterpillars
  [
    eat-asimina ; when it comes upon Asimina, it consumes the energy and converts it to life
    move-caterpillar ; asks the caterpillar to move around its environment in search of food
    death ; if the caterpillar has not consumed enough asimina it will die
  ]

  harm-asimina ; caterpillars eating Asimina harm the plant to a small degree

  asimina-mature-leaves ; distinguished the time of the season where leaves are mature and no longer palatable to caterpillars

  ask caterpillars [reproduce] ; caterpillars pupate and emerge as adults

  grow-asimina ; models the growth of asimina plants during the season

  reproduce-asimina ; models the sprouting of new plants from plants that have sufficient energy to reproduce

  nectar-vary ; shows the nectar sources of adults in blue. If nectar is consumed this indicator turns the patch white.

  ask butterflies
  [
    move-butterfly ; asks the butterflies to move through the environment
    eat-nectar ; models the nectar consumption of adult butterflies, an important resource that converts energy to life
    death ; if the butterfly has not consumed enough nectar it will die.
  ]

  nectar-grow

  plot count Butterflies

  ask butterflies
  [
    lay-eggs ; ask the butterflies to lay eggs some proportion of which will eclose into caterpillars
  ]

  asimina-no-leaves ; models winter. no leaves are available for caterpillars

  no-nectar

  senesce-asimina ; shows asimina plants that have run the course of their life.

  plot count Eggs

  tick
end



to setup-patches
  ask patches [
    set pcolor grey
    set energy 1
  ]
end



to asimina-grow-new-leaves

  ask asiminas [
    if pcolor = grey [set pcolor green]
    if pcolor = black [set pcolor green]
    set energy (energy + random-poisson 5)

    ifelse show-energy?
    [set label energy]
    [set label ""]

  ]
end





to eclose
  ask eggs [if pcolor = green [hatch-caterpillars 1 [set life 5]]]

  ask eggs [die]

end



to move-caterpillar
  ask caterpillars [

    if life < 5 [
      right random 87 forward 1
      left random 87 forward 1]
    set life (life - 1)

    ifelse show-life?
    [set label life]
    [set label ""]

  ]
end




to eat-asimina
  ask caterpillars [
    if pcolor = green [set life (life + random 3 )]

    if pcolor = grey [set life life / 2]
    if pcolor = black [set life life / 2]

    ifelse show-life?
    [set label life]
    [set label ""]
  ]
end




to reproduce
  ask caterpillars[ if life > 4 [hatch-butterflies 1 [set life 5]]]
  ask caterpillars[ die]
end




to nectar-vary
  ask nectars [
    if pcolor = grey [set pcolor blue]
    set energy energy-from-nectar

    ifelse show-energy?
    [set label energy]
    [set label ""]

  ]

end




to asimina-mature-leaves
  ask asiminas [
    if pcolor = green [set pcolor brown]
    set energy energy-from-asimina / 2


    ifelse show-energy?
    [set label energy]
    [set label ""] ]

end





to move-butterfly
  ask butterflies [ right random 180 forward random-float 10
    set life (life - sqrt energy-from-nectar)

    ifelse show-life?
    [set label life]
    [set label ""]

  ]
end





to eat-nectar
  ask butterflies
  [ if pcolor = blue [set pcolor white]
    set life (life + energy-from-nectar)
    if pcolor = grey [ set life (life * 0.8 )]

    ifelse show-life?
    [set label life]
    [set label ""]
  ]
end

to nectar-grow
  ask patches
  [ if pcolor = white [set pcolor grey]
    set energy 0 ]
end

to lay-eggs
  ask butterflies [
    if life > 20  [ hatch-eggs 10]
    setxy random-xcor random-ycor
    set life (life / sqrt energy-from-nectar) ]

  ask butterflies [die]
end



to grow-asimina
  ask patches [ if energy >= 1 [set energy (energy-from-asimina + 1)]]
end



to harm-asimina
  ask patches [ if pcolor = black [set energy energy - 1]]
end



to reproduce-asimina
  ask patches [ if energy-from-asimina > 10 [sprout-asiminas 1 [set energy 1]]]

end


to asimina-no-leaves
  ask asiminas [
    if pcolor = brown [set pcolor grey]
    set energy (energy-from-asimina / energy-from-asimina)

    ifelse show-energy?
    [set label energy]
    [set label ""]

  ]
end


to no-nectar
  ask patches [ if pcolor = blue [set pcolor grey]]
end



to senesce-asimina
  ask patches [ if energy-from-asimina >= 25 [ set pcolor red]]
end




to death
  ask caterpillars [
    if life <= 0 [ die ]
    if life >= 1000 [ die ]]
  ask butterflies [
    if life <= 0 [ die ]
    if life >= 1000 [ die ]]
end

To Immigration
  create-eggs 50 [ set color orange]
  ask eggs [ setxy random-xcor random-ycor]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
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
2
10
66
43
NIL
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
71
11
134
44
NIL
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
2
159
174
192
energy-from-asimina
energy-from-asimina
0
10
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
2
197
174
230
energy-from-nectar
energy-from-nectar
0
10
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
2
87
174
120
number-of-asiminas
number-of-asiminas
0
1000
605.0
1
1
NIL
HORIZONTAL

SLIDER
1
124
173
157
number-of-nectars
number-of-nectars
0
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
2
52
174
85
number-of-eggs
number-of-eggs
0
1000
178.0
1
1
NIL
HORIZONTAL

SWITCH
710
14
844
47
show-energy?
show-energy?
1
1
-1000

MONITOR
709
154
821
199
NIL
Count Caterpillars
17
1
11

MONITOR
710
208
816
253
NIL
Count Butterflies
17
1
11

MONITOR
710
101
787
146
NIL
Count Eggs
17
1
11

SWITCH
712
58
823
91
show-life?
show-life?
1
1
-1000

BUTTON
4
242
100
275
NIL
Immigration
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
718
295
918
445
Populations
Ticks
Individuals
0.0
100.0
0.0
500.0
true
true
"" ""
PENS
"Butterflies" 1.0 1 -8630108 true "" ""

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
  <experiment name="sweep1" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number-of-eggs">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-nectars">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-life?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-asimina">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-asiminas">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-from-nectar">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-energy?">
      <value value="false"/>
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
