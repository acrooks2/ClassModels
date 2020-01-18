;; Illegal elephant poaching model for simulating elephant poaching
;; Rangers arrest poachers with and without drones
;; Elephant move in herd and randomly
;; Number of elephants, poachers, rangers, drones and their radious vision are adujstable
;========================================================================================


;;global variables
globals [
  poacher-seen-drone    ;;poachers seen by drone
  number                ;;number of poacher seen by drone
]

;;set up types of agents
breed [elephants elephant]     ;;defining elephants breeds
breed [poachers poacher]       ;;defining poachers breeds
breed [rangers ranger]         ;;defining rangers breeds
breed [drones drone]           ;;defining drones breeds

;;properties for each agents
elephants-own [herdmates nearest-neighbor speed]
poachers-own [elephant-near e-nearest]
rangers-own [poacher-seen p-nearest]


;;observer methods/global methods
to setup
  clear-all       ;;clear previous runand setup initial agents
  setup-elephants ;;call setup-elephant function
  setup-patches   ;;call setup-patches function
  setup-poachers  ;;call setup-poachers function
  setup-rangers   ;;call setup-rangers function
  setup-drones    ;;cal setup-drones function
  reset-ticks
end

to setup-patches ;;
  ask patches [set pcolor 48] ;;no grass for now
end

to setup-elephants
  create-elephants elephant-number ;;create assigned number of elephant
  set-default-shape elephants "pentagon"
  ask elephants [ set color grey]
  ask elephants [ setxy random-xcor random-ycor] ;;put elephants at random starting places
  ask elephants [set speed .01]
end


to setup-poachers
  create-poachers poachers-number ;;create assigned number of poachers
  set-default-shape poachers "person"
  ask poachers [set color red]
  ask poachers [setxy random-xcor random-ycor];; put poachers at random starting places
end

to setup-rangers
  create-rangers rangers-number ;;create assigned number of rangers
  set-default-shape rangers "person"
  ask rangers [set color blue]
  ask rangers [setxy random-xcor random-ycor] ;; put rangers at random starting places
end

to setup-drones
  create-drones drones-number ;;create assigned number of drones
  set-default-shape drones "airplane"
  ask drones [set color green]
  ask drones [setxy random-xcor random-ycor] ;;put drones at random starting places
end


to go   ;run the simulation
  if ticks >= 720 [stop]
  move  ;;call move function
  tick
end

;;Refrence:Uri Wilensky 1998
;;===============================================================

to herd
  set speed .01
  right random 50 forward .5
  set herdmates other elephants in-radius 5                      ;;add all herdmate of elephant radius to agent subset
   if any? herdmates                                             ;;test if elephant has got herdmate
    [set nearest-neighbor min-one-of herdmates [distance myself] ;;assign the nearest
       ifelse distance nearest-neighbor > 3                      ;;test the min distance to join or dijoin herd
        [separate]                                               ;;call seperate function
        [align                                                   ;;call align function
         cohere ]]                                               ;;call cohere function
end

to separate                                                      ;;turn away to disjoin herd
  turn-away ([heading] of nearest-neighbor) 45                   ;;set the angle as 45 degrees
end


to align                                                         ;;call turn-toward to join herd
  turn-towards average-herdmate-heading 40                       ;;set the align angle as 45 degree
end

to-report average-herdmate-heading
  let x-component sum [dx] of herdmates                          ;;We can't just average the heading variables here.
  let y-component sum [dy] of herdmates                          ;;For example, the average of 1 and 359 should be 0,
   ifelse x-component = 0 and y-component = 0                    ;;not 180.  So we have to use trigonometry.
    [ report heading ]
    [ report atan x-component y-component ]
end

to cohere                                                        ;;call to turn-towrds cohere with the herd
  turn-towards average-heading-towards-herdmates 10              ;;set the cohere angle as 10 degree
end

to-report average-heading-towards-herdmates
  let x-component mean [sin (towards myself + 180)] of herdmates ;;"towards myself" gives us heading from other elephants to me
  let y-component mean [cos (towards myself + 180)] of herdmates ;;but we want the heading from me to the other elephants,
  ifelse x-component = 0 and y-component = 0                     ;;so we add 180
    [ report heading ]
    [ report atan x-component y-component ]
end

to turn-towards [new-heading max-turn]
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to turn-at-most [turn max-turn]                                   ;;turn right by "turn" degrees (or left if "turn" is negative),
  ifelse abs turn > max-turn                                      ;; but never turn more than "max-turn" degrees
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

;;============================================================


to move
  ifelse elephant-move-herd                    ;;test if elephants move in herd or randomly
   [ask elephants [herd]]                      ;;elephant move in herd
   [ask elephants [right random 360 forward 1]];;elephant move randmly
  ask poachers [right random 360 forward 1     ;;poachers move randomly
                 catch-elephants]              ;;call catch elephant
  ask drones [right random 360 forward 1       ;;drone move randomly
               set-position]                   ;;call set-position function
  ask rangers [
      ifelse ranger-with-drones              ;;rangers use dorones
      [catch-poachers-drone]                 ;;call catch-poacher-drone to move and catch
      [right random 360 forward 1            ;;drones move randomly
       catch-poachers] ]                     ;;call catch-poacher function

end

to catch-elephants                                          ;;poacher catch elephants
  set elephant-near elephants in-radius poacher-vision      ;;add all elephants of poacher vision to agent subset
  set e-nearest min-one-of elephant-near [distance myself]  ;;assign the neares elephant of the subset
     if e-nearest != nobody                                 ;;test if poacher get one
      [move-to e-nearest;;elephant-near                     ;;move toward prey(elephant)
        ask e-nearest [ die ] ]                             ;; kill it
end

to catch-poachers                                           ;;ranger catch poachers
  set poacher-seen poachers in-radius ranger-vision         ;;add all poacher of ranger vision to agent subset
  set p-nearest min-one-of poacher-seen[distance myself]    ;;assign the neares poacher of the subset
  if p-nearest != nobody                                    ;;test if ranger get one
  [ move-to p-nearest                                       ;;move toward prey(poacher)
    ask p-nearest [die]]                                    ;;kill it
end

to set-position                                             ;;drones set the position of poachers
   set poacher-seen-drone poachers in-radius drones-vision  ;;add all poacher of drone vision to agent subset
end


to catch-poachers-drone                                        ;;ranger catch poacher using drones(poacher position)
  set number count (poacher-seen-drone)                        ;;set number of poachers seen by drone
  if number >= 1                                               ;;test if drones get atleast one,for first round
  [set p-nearest min-one-of poacher-seen-drone[distance myself];;assign the nearest poacher for each rangers
     if p-nearest != nobody                                    ;;test if ranger get one
     [move-to p-nearest                                        ;;move toward prey(poacher)
     ask p-nearest [die]]]                                     ;;kill it
end
@#$#@#$#@
GRAPHICS-WINDOW
397
10
834
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
ticks
30.0

BUTTON
205
206
278
255
setup
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
295
240
360
273
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
1

BUTTON
294
188
357
221
go
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

PLOT
6
285
224
435
Number of Elephants
Time (ticks)
# elephants
0.0
200.0
0.0
10.0
true
true
"" ""
PENS
"elephants" 1.0 0 -7500403 true "" "plot count elephants"

SLIDER
100
10
272
43
elephant-number
elephant-number
2
200
100.0
1
1
NIL
HORIZONTAL

SLIDER
190
93
362
126
rangers-number
rangers-number
1
50
1.0
1
1
NIL
HORIZONTAL

SWITCH
-1
234
186
267
ranger-with-drones
ranger-with-drones
0
1
-1000

SLIDER
11
52
183
85
poacher-vision
poacher-vision
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
10
93
182
126
ranger-vision
ranger-vision
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
191
53
363
86
poachers-number
poachers-number
1
50
1.0
1
1
NIL
HORIZONTAL

SLIDER
10
131
182
164
drones-vision
drones-vision
10
200
115.0
5
1
NIL
HORIZONTAL

SLIDER
189
131
361
164
drones-number
drones-number
1
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
235
298
358
343
remain-elephants
count elephants
17
1
11

MONITOR
233
353
360
398
remain-poachers
count poachers
17
1
11

SWITCH
0
193
186
226
elephant-move-herd
elephant-move-herd
1
1
-1000

@#$#@#$#@
## WHAT IS IT?
This model simulates poaching of African elephants and the enforcement or prevention of poaching using park rangers and unmanned aerial vehicles, also known as drones.

## HOW IT WORKS

Elephants move randomly throughout the space. Poachers move randomly until they see an elephant within their vision radius and then move toward it. When a poacher interacts with an elephant (touches it), it kills it. Rangers behave similarly to poachers, except their target agent breed is poachers. When drones are turned on, drones fly randomly around the space and seek out poachers. When a poacher is detected within their vision radius, the ranger receives a message to move to the coordinate where the poacher was located and kill the poacher. Elephants also have the ability to herd - if herding is turned on, elephants begin to move together in groups.

## HOW TO USE IT

Adjust parameters including the number of elephants, rangers, poachers, and drones as well as vision of the poachers, rangers, and drones. Turn herding and drones on and off to explore different results. Click SETUP and GO (once or forever). The model will run for 720 ticks before stopping. The plot displays the number of elephants. Monitors display the number of elephants and poachers remaining throughout the model run. 

## THINGS TO NOTICE

Poachers have an inherent advantage in this model; most combination of parameters cause the elephant population to decline initially. This is an artefact of the random setup programmed in the model. All agents are placed on random positions at setup. 

## THINGS TO TRY

Try turning herding on and off to see how the elephants move together. Try turning the drones off and increasing the number of drones to see how quickly the elephant population goes from being poached to being protected.

## EXTENDING THE MODEL

Biological variables, such as reproduction and eating, could be included in a longer-term model. The speed of different agents could be included as an adjustable parameter to introduce additional heterogeneity. Elephants could be modified to flee poachers as they approach by spotting them within a certain vision radius.
Elephant memory and the avoidance of poachers could be built as a machine learning model. Also, agents and poachers could be programmed to “flip” to the other type of agent with some probability. Rangers could be dishonest and become poachers. Poachers could also change their preferences to become rangers.  In addition, as the ivory trade continues, ivory becomes more scarce and prices are expected to increase. This scarcity contributes further to the value of ivory products and the supply and demand phenomenon may drive more poachers to seek out ivory. This feedback could be included in future iterations of the model by including a reproduction rate for poachers, the rate which is linked to the price of ivory. Furthermore, the model could be applied to different species, such as rhinos and tigers, which exhibit different behaviors. Finally, the model could be connected to a real place and time by including GIS layers in the ABM.


## NETLOGO FEATURES

The in-radius command was particularly useful for this model and helps direct the behaviors of poachers and rangers.

## RELATED MODELS

The flocking model was adapted for to simulate the elephant herding behavior (Wilensky 1998). 

## CREDITS AND REFERENCES

Wilensky, Uri. “NetLogo Flocking model.” Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 1998. http://ccl.northwestern.edu/netlogo/models/Flocking 
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
  <experiment name="Graph 1: no drones, no herd, same vision, different numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 2: no drones, no herd, different vision, same numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 3: yes drones, no herd, same vision, different numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 4: yes drones, no herd, different vision, same numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 5: no drones, yes  herd, same vision, different numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 6: no drones, yes herd, different vision, same numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 7: yes drones, yes herd, same vision, different numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 8: yes drones, yes herd, different vision, same numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 9: testing drone vision, yes herd" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 10: testing drone vision, no herd" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="35"/>
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 11: testing number of drones, yes herd" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 12: testing number of drones, no herd" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 13: yes drones, no herd, same vision, different numbers DRONE VISION" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Graph 14: yes drones, no herd, different vision, same numbers" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="ranger-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poachers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drones-vision">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ranger-with-drones">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elephant-move-herd">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rangers-number">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="poacher-vision">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
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
