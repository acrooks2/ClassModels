globals[
 ;car driving variables
 deceleration
 acceleration
 speed-limit


 ;GA variables
 generation-count
 max-light-time
 sim-length
 crossing-times
]

breed [cars car]
breed [strategies strategy]

cars-own[
 speed
 travel-time  ;; keeps track of how long the car has been in the system
]

strategies-own[
  light-times ;; will be double the number of intersections
              ;; first number is ns time, second is ew time
  fitness
]

patches-own[
 road?          ;;flag denoting whether or not the patch is a road
 origin?        ;;flag denoting whether or not the patch is a spawn point
 destination?   ;; flag denoting whether or not the patch is a destination
 intersection?  ;; flag denoting whether the patch is an intersection

 ;origin variables
 spawn-rate       ;;1/lambda from poisson distribution
 spawn-countdown  ;;countdown to the next spawn
 new-car-heading  ;;direction that new cars drive in

 ;intersection variables
 green-light-ns? ; true if green light is ns, false if ew
 ew-time         ; length of green light in ew direction
 ns-time         ; length of green light in ns direction
 green-light-countdown ;countdown until light direction change
]


to setup
  clear-all
  reset-ticks


  ;setup the world
  setup-roads
  setup-origins-destinations
  setup-intersections
  set-default-shape cars "car"


  ;define global variables
  set deceleration 0.026
  set acceleration 0.0045
  set speed-limit 1

  set max-light-time 500
  set sim-length 5000
  set generation-count 0
  set crossing-times []

  ;generate initial strategy set
  setup-strategies

  ;write header row to results files
  file-open results-filename
  file-type "generation,fitness,"
  let i 0
  while [i < count patches with [intersection?]]
  [ file-type (word "I" i "-ns,")
    file-type (word "I" i "-ew,")
    set i i + 1
  ]
  file-print ""
  file-close

end

to setup-roads
  ;set all patches to brown and set flags to false
  ask patches[
    set pcolor brown + 3
    set road? false
    set origin? false
    set destination? false
    set intersection? false
  ]

  ; keep track of x and y locs so intersection definition is easy
  let x-road-locs []
  let y-road-locs []

  ; iterate through for number of ns roads and determine even spacing across the world
  let i 1
  while [i <= num-ns-roads]
  [
    ; determine even spacing
    let this-road-loc round (min-pxcor + world-width * i / (num-ns-roads + 1))
    ; color the patch
    ask patches with [pxcor = this-road-loc][
      set pcolor black
      set road? true
    ]
    ; store loc for later
    set x-road-locs lput this-road-loc x-road-locs
    set i i + 1
  ]
    ; iterate through for number of ew roads and determine even spacing across the world
  let yspread max-pycor - min-pycor
  set i 1
  while [i <= num-ew-roads]
  [
    ; determine even spacing
    let this-road-loc round (min-pycor + world-height * i / (num-ew-roads + 1))
    ; color the patch
    ask patches with [pycor = this-road-loc][
      set pcolor black
      set road? true
    ]
    ; store loc for later
    set y-road-locs lput this-road-loc y-road-locs
    set i i + 1
  ]

  ;define intersetions as any road with four neighboring roads
  ask patches with [ count neighbors4 with [pcolor = black] = 4][
    set intersection? true
  ]
end

to setup-origins-destinations
  ; cars enter from the west and north
  ;define origins as any road patch on the westernmost patch or northernmost patch
  ask patches with [road? and (pxcor = min-pxcor or pycor = max-pycor)][
    set origin? true
    set spawn-rate 20
    set spawn-countdown random-poisson spawn-rate
    ifelse pxcor = min-pxcor
    [ set new-car-heading 90]
    [ set new-car-heading 180]
  ]
  ; cars exit from the east and south
  ; destinations do nothing right now. in future will allow cars to seek multiple destinations
  ask patches with [road? and (pxcor = max-pxcor or pycor = min-pycor)][
    set destination? true
  ]
end

to setup-intersections
  ;set the intiial time for intersections and set the green light direction to ns
  ask patches with [intersection?][
    set green-light-ns? true
    set ew-time 50
    set ns-time 50
    set green-light-countdown ns-time
    set-signal-colors
  ]
end

to set-signal-colors
  ;set the colors of the traffic lights next to intersections
  ifelse green-light-ns?
    [
      ask patch-at -1 0 [ set pcolor red ]
      ask patch-at 0 1 [ set pcolor green ]
    ]
    [
      ask patch-at -1 0 [ set pcolor green ]
      ask patch-at 0 1 [ set pcolor red ]
    ]
end

to setup-strategies
  ;generate an intiial set of GA strategies
  create-strategies GA-pop-size[
    ; place strategy in bottom left corner and make it invisible
    set xcor min-pxcor
    set ycor min-pycor
    set color brown + 3
    set light-times []
    let j 0
    ; generate strategies with random initial light times
    while [j < count patches with [intersection?]]
    [
      set light-times lput ((random max-light-time) + 1) light-times
      set light-times lput ((random max-light-time) + 1) light-times
      set j j + 1
    ]
  ]
end


to evolve
  test-strategies
  write-results
  reproduce-strategies
  set generation-count generation-count + 1
end

to test-strategies
  foreach sort strategies[ ?1 ->
    set crossing-times []
    ;remove cars left over from last simulation
    ask cars[
      die
    ]
    ; set intersection light times
    ask ?1 [
      let i 0
      foreach sort patches with [intersection?][ ??1 ->
        ask ??1[
          set ns-time item (2 * i) [light-times] of myself
          set ew-time item ((2 * i) + 1) [light-times] of myself
          set green-light-ns? true
          set green-light-countdown ns-time
          set-signal-colors
        ]
        set i i + 1
      ]
    ]

    ; run the simulation to assess fitness
    let i 0
    while [i < sim-length]
    [ go
      set i i + 1 ]

    ;extract fitness from all the remaining cars
    ask cars[
      set crossing-times lput travel-time crossing-times
    ]
    ask ?1 [
      set fitness mean crossing-times
    ]
  ]
end

to write-results
  ;write out the fitness of each individual to the output file
  file-open results-filename
  ask strategies[
    file-type (word generation-count ",")
    file-type (word fitness ",")
    foreach light-times [ ?1 ->
      file-type (word ?1 ",")
    ]
    file-print ""
  ]
  file-close
  ;plot this generation's fitness
  set-current-plot "generational-fitness"
  plotxy generation-count mean [fitness] of strategies
end

to reproduce-strategies
  ;; truncation selection
  ; evolve best strategies
  ;define parents as best 50% of pop
  let parents sublist (sort-on [fitness] strategies) 0 (GA-pop-size * 0.5)
  ;kill off worst 50% off pop
  foreach sublist (sort-on [fitness] strategies) (GA-pop-size * 0.5) GA-pop-size[ ?1 ->
    ask ?1 [die]
  ]

  ; select two parents at random without replacement and mate them to create next generation
  while [not empty? parents][
    let parent1 one-of parents
      let genome1 [light-times] of parent1
      set parents remove parent1 parents

      let parent2 one-of parents
      let genome2 [light-times] of parent2
      set parents remove parent2 parents

      ;; create genome split in the middle and mutate genes
      create-strategies 1 [
        set color brown + 3
        set xcor min-pxcor
        set ycor min-pycor
        set light-times sentence (sublist genome1 0 (length genome1 / 2)) (sublist genome2 (length genome2 / 2) (length genome2))
        if random-float 1 < mutation-rate[
          set light-times replace-item (random length light-times) light-times ((random max-light-time) + 1)
        ]
      ]

      ;; create genome split in the middle and mutate genes
      create-strategies 1 [
        set color brown + 3
        set xcor min-pxcor
        set ycor min-pycor
        set light-times sentence (sublist genome2 0 (length genome2 / 2)) (sublist genome1 (length genome1 / 2) (length genome1))
        let i 0
        while [i < length light-times][
          if random-float 1 < mutation-rate[
            set light-times replace-item i light-times ((random max-light-time) + 1)
          ]
          set i i + 1
        ]
      ]
  ]
end


to go
  update-lights
  update-car-speeds
  drive-cars
  spawn-cars
  tick
end

to update-lights
  ; if the countdown has reached 0, switch the light direction and reset the countdown
  ; otherwise, reduce the countdown by 1
  ask patches with [intersection?][
   ifelse green-light-countdown = 0
   [ ifelse green-light-ns?
     [ set green-light-ns? false
       set green-light-countdown ew-time]
     [ set green-light-ns? true
       set green-light-countdown ns-time]
     set-signal-colors
   ]
   [ set green-light-countdown green-light-countdown - 1]
  ]
end

to update-car-speeds
  ; the code in this method is a modification and combination of code from Traffic Basic and Traffic Grid
  ask cars[
    ; if the car is on a red light, stop
    ; otherwise, if it has another car directly ahead of it, make it match the speed and then slow down some
    ; otherwise, have it accelerate by a fixed amount
    if patch-ahead 1 != nobody
    [
      ifelse pcolor = red
      [ set speed 0 ]
      [ let car-ahead 0
        ifelse ([intersection?] of patch-ahead 1 and not block-intersections?)
        [ set car-ahead one-of turtles-on patch-ahead 2]
        [ set car-ahead one-of turtles-on patch-ahead 1]
        ifelse car-ahead != nobody
        [ set speed [speed] of car-ahead
          set speed speed - deceleration
          if speed < 0
          [set speed 0]
        ]
        ;; otherwise, speed up
        [ set speed speed + acceleration
          if speed > speed-limit
          [set speed speed-limit]
        ]
      ]
    ]
  ]
end

to drive-cars
  ; move cars forward according to their speed
  ask cars[
    if patch-ahead speed = nobody
    [ set crossing-times lput travel-time crossing-times
      die ]
    set travel-time travel-time + 1
    fd speed
  ]
end

to spawn-cars
  ; if the countdown timer for an origin has reached 0, spawn a car and reset the countdown timer to a new value drawn from the Poisson distribution
  ; otherwise, decrease the timer
  ask patches with [origin?][
   ifelse spawn-countdown = 0
   [ sprout-cars 1
     [
       set heading [new-car-heading] of myself
       set speed speed-limit
       set travel-time 0
     ]
     set spawn-countdown random-poisson spawn-rate
   ]
   [ set spawn-countdown spawn-countdown - 1]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
324
33
761
471
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
37
38
100
71
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
41
192
104
225
NIL
go
NIL
1
T
OBSERVER
NIL
G
NIL
NIL
1

SLIDER
39
268
211
301
GA-pop-size
GA-pop-size
10
40
20.0
2
1
NIL
HORIZONTAL

BUTTON
40
229
109
262
NIL
evolve
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
38
347
238
497
generational-fitness
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
"default" 1.0 0 -16777216 true "" ""

SLIDER
39
307
211
340
mutation-rate
mutation-rate
0
1
0.05
0.01
1
NIL
HORIZONTAL

SWITCH
130
190
294
223
block-intersections?
block-intersections?
1
1
-1000

SLIDER
123
36
295
69
num-ew-roads
num-ew-roads
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
126
77
298
110
num-ns-roads
num-ns-roads
0
10
1.0
1
1
NIL
HORIZONTAL

INPUTBOX
41
117
298
177
results-filename
results.csv
1
0
String

@#$#@#$#@
For more information, see "Using a Genetic Algorithm for Optimization of Traffic Signal Timing in a Grid"

## WHAT IS IT?

This model simulates a traffic grid and uses a genetic algorithm to determine the optimal signal timing throughout the system.

## HOW IT WORKS

Car agents:
If on a red light space, set speed to 0
Otherwise, if the patch ahead has a car on it then the car first matches the speed of that car and then decelerates by a fixed amount
Otherwise, the car accelerates by a fixed amount
When block-intersections? is false, cars will look ahead two patches when looking through an intersection

Intersection agents:
When the light is switched to green in the NS direction, a countdown of length ns-time begins
When the countdown reaches 0, the light becomes green in the EW direction, and a countdown of length ew-time begins
This process is repeated

GA Strategies:
Encode a NS and EW time for each light in the system.
Solutions are selected using truncation selection.
Reproduction occurs with midpoint crossover.

## HOW TO USE IT

setup will create the world and generate an initial strategy population.
num-ew-roads sets the number of east-west roads.
num-ns-roads sets the number of north-south roads.
results-filename sets the filename for results to be output to.
go steps the simulation for one step.
block-intersections? modifies the car decision rules as described above
evolve simulates each strategy for the number of ticks equal to sim-length. Then, strategies reproduce and the next generation is created. This process continues until evolve is unpressed, at which point the evaluation of the current generation finishes and the simulation stops.
GA-pop-size is the size of the genetic algorithm population
mutation-rate is the rate of mutation during GA reproduction

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
<experiments>
  <experiment name="four-intersections" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>evolve</go>
    <timeLimit steps="2000000"/>
    <enumeratedValueSet variable="block-intersections?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GA-pop-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-ew-roads">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-ns-roads">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filename">
      <value value="&quot;four-intersection-parents1.csv&quot;"/>
      <value value="&quot;four-intersection-parents2.csv&quot;"/>
      <value value="&quot;four-intersection-parents3.csv&quot;"/>
      <value value="&quot;four-intersection-parents4.csv&quot;"/>
      <value value="&quot;four-intersection-parents5.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-rate">
      <value value="0.05"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="two-intersections" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>evolve</go>
    <timeLimit steps="2000000"/>
    <enumeratedValueSet variable="block-intersections?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GA-pop-size">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-ew-roads">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-ns-roads">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="filename">
      <value value="&quot;two-intersection-parents1.csv&quot;"/>
      <value value="&quot;two-intersection-parents2.csv&quot;"/>
      <value value="&quot;two-intersection-parents5.csv&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mutation-rate">
      <value value="0.05"/>
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
