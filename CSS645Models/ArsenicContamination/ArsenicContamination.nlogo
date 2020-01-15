patches-own [
  neighborhood  ;; surrounding patches within vision radius
  population    ;; people exist in a patch
  water-depth   ;; depth of ground water level from which people extract water
  contaminant   ;; already existed arsenic concentration in patch
  contamination ;; level of contamination depends on ground water depth, arsenic concentration,
                ;; use of water from alternative source rather than contaminated water, population pressure
  safe?         ;; level of arsenic contamination in water that is safe for use
  poisonous?    ;; level of extreme arsenic contamination in water that is not safe for use or toxic
  available-water?  ;; ground water depth that is easy for extraction
  person
]
turtles-own [       ;; status of a turtle during model run
  not-happy?
   ]

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ;; creating # of new turtles on a current patch and initialize the variables
  ask patches [
    sprout random-float 5 [
      set color blue
      set shape "circle"
      set size 0.5
    ]
  set neighborhood patches in-radius vision
  set water-depth random-in-range 1 200
  ;; setting patchcolor according to water depth
  set pcolor scale-color gray water-depth 200 1


  ;; population is high where water depth is low and vise versa

ifelse water-depth < 100 [set contaminant random-in-range 51 100][set contaminant random-in-range 0 50]
  ifelse water-depth < 100 [set population random-in-range 6 10][set population random-in-range 0 5]
  ;; contamination proportional to population, contaminant and inversely proportional to water depth and alternative use


  set safe? false
  set poisonous? false
  set available-water? false
  ]

  ask turtles [ set not-happy? false ]

  my-update-plots
end

to go
  ask patches [update-patches]
  ask turtles [update-turtles]

  tick
  my-update-plots
end

to update-patches
  set person count turtles-here
  set population population + person
  set contamination (population * contaminant / water-depth / alternative-use / rainfall)
       ifelse contamination < 10 [set safe? true] [set safe? false]
     ifelse contamination > 50 [set poisonous? true] [set poisonous? false]

     ifelse water-depth < 100 [set available-water? true] [set available-water? false]

    run visualization
end

to update-turtles
  ifelse contamination > 200 [turn-back][
  ifelse (available-water?) [set not-happy? false] [set not-happy? true]
  if not-happy? [search]]   ;; keep going until find suitable patch
end

to search
  let move-candidates (patch-set patch-here (patches in-radius vision))
  let targets move-candidates with [available-water?]
  ifelse any? targets [move-to one-of targets] [search]
end

to turn-back
   let turn-back-candidates (patch-set patch-here (patches in-radius vision))
   let targets turn-back-candidates with [not poisonous?]
   ifelse any? targets [move-to one-of targets] [turn-back]
end

to-report random-in-range [low high]
  report low + random (high - low + 1)
end

;; visualization procedure

to no-visualization
  set pcolor scale-color gray water-depth 1 100
end

;; color patches according to contamination level
to color-patches-by-contamination-level
  ifelse safe? [set pcolor green] [ifelse poisonous?
    [set pcolor red] [set pcolor yellow]]
end

;; plotting
to my-update-plots
  let safe-count count patches with [safe?]
  let poisonous-count count patches with [poisonous?]

  set-current-plot "Contamination level"
  set-current-plot-pen "safe"
  plot safe-count
  set-current-plot-pen "poisonous"
 plot poisonous-count
  set-current-plot-pen "risky"    ;; contamination level that is risky for using
  plot count patches - safe-count - poisonous-count
end
@#$#@#$#@
GRAPHICS-WINDOW
360
12
878
531
-1
-1
10.0
1
10
1
1
1
0
1
1
1
0
50
-50
0
1
1
1
ticks
30.0

BUTTON
34
27
97
60
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
128
35
191
68
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
61
88
233
121
vision
vision
0.0
10
5.0
.1
1
patches
HORIZONTAL

CHOOSER
33
506
287
551
visualization
visualization
"no-visualization" "color-patches-by-contamination-level"
1

PLOT
28
145
228
295
Contamination level
time
patches
0.0
20.0
0.0
150.0
true
true
"" ""
PENS
"safe" 1.0 0 -10899396 true "" ""
"risky" 1.0 0 -1184463 true "" ""
"poisonous" 1.0 0 -2674135 true "" ""

MONITOR
35
313
128
362
safe patches
count patches with [safe?]
1
1
12

MONITOR
156
333
285
382
poisonous patches
count patches with [poisonous?]
1
1
12

MONITOR
49
382
143
431
risky patches
count patches with [not safe? and not poisonous?]
1
1
12

SLIDER
161
401
333
434
alternative-use
alternative-use
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
91
458
263
491
rainfall
rainfall
1
50
7.0
.1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This project models the contamination of Arsenic in ground water as a result of interactions between human and the surrounding environment. Man tries to live where level of aquifer is within a reach ground water abstraction is easy for everyday use and as he continues using water the water level declines and Arsenic gradually contaminate the ground water. The  contamination process is inversly affected by rainfall and alternative use of water. At first people go to places with low water depth and after contamination exceeds a certain level people search for safe places and so the safe locations gradually become unsafe and the whole location can be contaminated over time.

## HOW IT WORKS

Every patch has a random value for ground water depth and a contaminant (presence of arsenic bearing materials in soil)value set according to water depth. at starting, a population value is set which allows updated values with moveing turtles/persons.  The conceptual equation used in the model is :

   contamination = population * contaminant / alternative-use / water-depth / rain

At first, turtle/person move to a patch that has water depth less than 100 (meter) and sprout 5. When contamination of that patch exceeds a value of 300, the patches that have water depth more than 100 are affected. A patch which has a contamination value less than 10 is considered as safe and become poisonous when contamination is above 50. In between values indicate risky patches that are potential to be poisonous.

## HOW TO USE IT

Use the sliders to pick the initial settings for the model.  vision determines the number of patches in each direction that a person can see.
alternative-use and rainfall are variables that can be changed before starting a simulation.water-depth is randomly set up by the model.

Click SETUP to initialize the setup procedure with random water-depth values. Click GO to begin the simulation.

The visualization chooser allows You to choose between no vusualization and to see state of patches by color.

## THINGS TO NOTICE

Watch how a patch vary in contamination value with different water-depth, contaminant level, alternative-use and rainfall.
watch how alternative-use can influence the level of arsenic by changing the slider.See how different transition of state vary with different settings of the variables.

## THINGS TO TRY

Change the sliders to change the values of the variables, speciallt alternative-use and rainfall. See how patches show difference with different value of these variables. You can also change the values within a simulation.
Take a value of alternative-use 5 and rainfall 5 and run the model. Then change the values and take alternative-use 30 and rainfall 10 and so on.watch what changes happen.

## EXTENDING THE MODEL

You can use GIS for getting real world reference as well as you can get more spatial arrangement because in real world water-depth and contaminant are fixed and there can be more accurate spatial distribution.

## NETLOGO FEATURES

Note the use of a patch variable to store precomputed neighborhood agentsets. This improves performance because the neighborhoods don't have to be calculated over and over again.

## CREDITS AND REFERENCES

The model is a part of the term final paper of Sptial Agent Based Modeling. Thanks goes to Dr.Andrew Crooks, the course teacher for his support, advice and guidence.
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
