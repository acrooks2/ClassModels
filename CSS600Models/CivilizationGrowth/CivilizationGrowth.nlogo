;;;;;THE::EVOLUTION::OF::CIVILIZATIONS;;;;;

globals [ ]

civs-own [
  pen-color
  farm ;;agentset
  farm-size ;;size of agentset
  fs-prev-tick ;;Civilization farm-size at previous tick
  farm-RoP ;;Civlization Rate of Production
  farm-RoC ;;Civilization Rate of Consumption
  farm-excess ;;Civilization Excess of Production (if positive)
  excess-prev-tick ;;Civilization Excess of Production at previous tick
  SoL ;;Standard of Living, -5 to 5, 5=lavish -5=poverty 0=middle class
  SoL-max
  SoL-min
  RoExp ;;Civilization Rate of Expansion ;;(present farm-excess - past farm-excess)/(past farm-excess)
  RoExp-prev-tick ;;Civilization Rate of Expansion at previous tick
  choice ;;Civilization's decision to invest in RoP (1) or SoL (2)
]

patches-own [
  belongs-to
  RoP ;;random yield land capable of producing
  conflict-value
]

breed [civs civ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ca
  setup-civs
  setup-land
  ask turtles
    [ set-farm-in-radius farm-size ]
  reset-ticks
end

to setup-civs ;;TURTLES
  create-civs number-civs [
    ;create-temporary-plot-pen (word WHO)
    set shape "person farmer"
    set size 1.3
    set color 28
    setxy random-pxcor random-pycor
    set pen-color one-of [15 25 45 65 75 85 95 105 115 125 135]
    ifelse farm-size-uniform?
      [ set farm-size 3 ]
    [ set farm-size random 5 + 1 ] ;;Give each civ a random farm size between 1 and 5
  ]
end

to setup-land ;;PATCHES
  ask patches [ set belongs-to nobody ]
  ask patches [ set RoP random 50 ]
  repeat 5 [ ask patches [
    set RoP mean [RoP] of neighbors]]
  ask patches [ set pcolor scale-color 39 RoP 0 100
  ]
end

to set-farm-in-radius [d] ;;create the farm
  move-to one-of patches with [ not any? other patches in-radius d with [belongs-to != nobody] ] ;;don't overlap
  set farm patches in-radius farm-size ;;create "farm" agentset made up of patches around the farmer
  ask farm [ set belongs-to myself ]
  set farm-RoP sum [ RoP ] of patches in-radius farm-size ;;create total RoP of civ by summing the RoP of each patch in the farm
  set farm-RoC count patches in-radius farm-size * 23 ;;23 people live on each patch and consume 1 product each
  set farm-excess (farm-ROP - farm-RoC) ;;calcualte delta of production and consumption; if positive, excess exists
  ask civs [
    ifelse SoL-uniform?
    [ set SoL 0 ]
    [ ifelse farm-excess > 0
      [ set SoL random-float 5 ] ;;if farm-excess exists (positive), set Standard of Living to random between 0 & 5 (middle class -> lavish)
      [ set SoL random-float -5 ] ;;if farm-excess does not exist (negative), set SoL to random between -5 & 0 (poverty -> middle class)
    ]
  ]
  set SoL-max 5
  set SoL-min -5
  ask farm [ set pcolor scale-color 67 RoP 0 75 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  step
end

to step
  ask civs [
    invest
    expand
    conflict ]
  tick
end

to invest ;;if there is excess, invest it in farm-RoP OR SoL by random probability
  let p random 100 ;;local variable
  set excess-prev-tick farm-excess ;;capture current farm-excess value before updating
  set RoExp-prev-tick RoExp ;;capture current RoExp value before updating
  set fs-prev-tick farm-size

  if choice = 0 [ ;;Neutral choice on initiation
    if (farm-excess > 0 and p <= 40) [
      set farm-RoP ( farm-RoP + farm-excess )
      set choice 1 ];;Excess acts as Instrument of Expansion to increase RoP with 40% probability
    if ( farm-excess > 0 and p > 60 and SoL < SoL-max ) [
      set SoL ( SoL + 0.50 )
      set choice 2] ;;Excess increases SoL with 60% probaility
    if ( farm-excess > 0 and p > 60 ) [
      set farm-RoC ( farm-RoC + ( count patches in-radius farm-size * 2 ))
      set choice 2 ] ;;if SoL increases, RoC must also increase proportionally
    if farm-excess < 0 and SoL >= SoL-min [
      set SoL ( SoL - 0.10 )
      set choice 0 ] ;;Decrease SoL if not excess
  ]
  if choice = 1 [ ;;Choice to invest in RoP
    if ( farm-excess > 0 and p <= 40 ) [
      set farm-RoP ( farm-RoP + farm-excess )
      set SoL ( SoL + 0.10 )
      set choice 1 ];;Excess acts as Instrument of Expansion to increase RoP with 40% probability
  ]
  if choice = 2 [ ;;Choice to invest in SoL
    if ( farm-excess > 0 and p > 60 and SoL < SoL-max ) [
      set SoL ( SoL + 0.50 )
      set choice 2] ;;Excess increases SoL with 60% probaility
    if ( farm-excess > 0 and p > 60 ) [
      set farm-RoC ( farm-RoC + ( count patches in-radius farm-size * 2 ))
      set choice 2 ] ;;if SoL increases, RoC must also increase proportionally
  ]

  set farm-excess (farm-ROP - farm-RoC) ;;update farm-excess with new RoP value
  set RoExp ((farm-excess - excess-prev-tick) / (excess-prev-tick)) ;;Calculate civ RoE
end

to expand ;;Called from STEP
  if RoExp >= 0.50 and RoExp-prev-tick >= 0.50 and ticks >= 5 [ ;;See whether or not the civ is expanding step over step
    set farm-size ( farm-size + 1 ) ;;create its new farm-size
    assess ]
end

to assess ;;Called from EXPAND
  if farm-size > fs-prev-tick [ ;;If the farm-size grew last tick...
    ask (patches in-radius farm-size) with [belongs-to != nobody and belongs-to != myself] [ ;;determine if new candidate patches belong to a civ
      show "Nock...Draw...Loose!"
      set plabel "C"
      set conflict-value 1] ;;If they do, give some indication in the UI that there will be conflict
  ]
end

to conflict ;;Called from STEP
  if farm-size <= fs-prev-tick and any? patches in-radius farm-size with [conflict-value = 1] [ ;;If the farm-size did not grow last tick and there is conflict in its radius...
    ask patches in-radius farm-size [
      set conflict-value 0 ;;remove the indication of conflict before it dies
      set plabel "" ] ;;remove the C that indicated conflict before it dies
    die ;;............die. This indicates that an expanding civ was encroaching on a civ that was not very strong.
  ]
  if farm-size > fs-prev-tick [ ;;otherwise, if the civ grew last tick and there is no conflict, expand
    expand-civ]
  ;ifelse farm-size <= fs-prev-tick and any? patches in-radius farm-size with [conflict-value = 1]
  ;[die]
  ;[expand-civ ]
end

to expand-civ ;;Called from CONFLICT
  if RoExp >= 0.50 and RoExp-prev-tick >= 0.50 and ticks >= 5 [ ;;If the civ is growing tick over tick (and there is no conflict)
    ;set farm-size ( farm-size + 1 )
    set farm patches in-radius farm-size ;;Assess new candidate patches
    ask farm [
      set belongs-to myself ] ;;claim the patches
    let tmp-RoP farm-RoP
    ask patches in-radius farm-size [
      set pcolor scale-color 67 RoP 0 75 ] ;;color them and expand
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
228
10
1081
864
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
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
2
12
71
45
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
2
48
221
81
number-civs
number-civs
3
20
10.0
1
1
NIL
HORIZONTAL

BUTTON
159
12
222
45
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

BUTTON
83
12
146
45
NIL
step
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
1088
266
1457
386
Rate of Expansion by Civilization
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
"RoExp" 1.0 0 -16777216 true "" "ask turtles [\n  if farm-size > fs-prev-tick [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color pen-color\n  plotxy ticks RoExp \n]\n]\n\n"

PLOT
1087
10
1457
264
Mean Civilization Stats
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
"Excess" 1.0 1 -16777216 true "" "plotxy ticks mean [farm-excess] of civs "
"RoC" 1.0 0 -2139308 true "" "plotxy ticks mean [farm-RoC] of civs"
"RoP" 1.0 0 -13791810 true "" "plotxy ticks mean [farm-RoP] of civs"

PLOT
2
86
220
327
Civilization Size
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
"Civ" 1.0 1 -16777216 true "" "ask turtles [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color pen-color\n  plotxy ticks farm-size \n]"

PLOT
2
335
221
502
Civ Size of Expanding Civs
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
"Size" 1.0 0 -16777216 true "" "ask turtles [\n  if farm-size > fs-prev-tick [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color pen-color\n  plotxy ticks farm-size \n]\n]\n\n"

PLOT
1089
389
1457
539
Rate of Production of Expanding Civs
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
"RoP" 1.0 0 -16777216 true "" "ask turtles [\n  if farm-size > fs-prev-tick [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color pen-color\n  plotxy ticks farm-RoP\n]\n]\n\n"

PLOT
1090
542
1457
692
Excess of Expanding Civs
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
"Excess" 1.0 0 -16777216 true "" "ask turtles [\n  if farm-size > fs-prev-tick [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color pen-color\n  plotxy ticks farm-excess\n]\n]\n\n"

PLOT
1089
696
1458
846
Standard of Living of Civs
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
"SoL" 1.0 0 -16777216 true "" "ask turtles [\n  if farm-size = fs-prev-tick [\n  create-temporary-plot-pen (word who)\n  set-plot-pen-color pen-color\n  plotxy ticks SoL \n]\n]\n\n"

SWITCH
2
506
221
539
farm-size-uniform?
farm-size-uniform?
1
1
-1000

SWITCH
2
544
221
577
SoL-uniform?
SoL-uniform?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

The purpose of this model is to assess civilization formation, progression, and conflict, and to explore the conditions under which these processes occur. 

## HOW IT WORKS

On model initation, several Civilizations, "Civs," are created. These Civs possess certain attributes, some derived at random and some derived from the "farms," or groups of patches, on which they were initiated. 

The factors that influence a Civ's potential to grow and expand are things like:

farm-size: patch count of Farm radius 

Rate of Production (farm-RoP): aggregate of the randomized RoP of every patch in the Farm

Rate of Consumption (farm-RoC): set value of consumption for every patch in the Farm representative of how many people live in that Civ 

Surplus (farm-excess): the difference between farm-RoP and farm-RoC. If positive, the Civ is said to have a surplus. If negative, the Civ is said to be in decline.  

Standard of Living (SoL): number between -5 and 5; -5 is abject poverty, 0 is middle class, and 5 is lavish lifestyle. If a Civ initiates with a surplus, this value is set randomly between 0 and 5; if a Civ initiates in decline, this value is set randomly between -5 and 0.  

Rate of Expansion (RoExp): rate at which a Civ is developing surplus or declining, calculated with 
RoExp=(farm−excess)−(excess−prev−tick) / (excess−prev−tick)
 where excess-prev-tick is equal to the Civ’s farm-excess at the previous time step.  

At the sixth time step, if farm-excess exists, the Civ makes a choice regarding where to invest that surplus. If invested directly in farm-RoP (representing investment in technology and science), the farm will expand freely until such time as it collides with another Civ and Conflict occurs. The Civ can also choose to invest directly in SoL (representing investment in leisure, luxury, and the arts), and, if it does so, farm-RoC will increase and the Civ will again assess if it still has a Surplus after this adjustment.

## HOW TO USE IT

The three buttons at the top, SETUP, STEP, and GO, initiate the modeland run through its time steps (each representing one calendar year) either one at a time (STEP) or serially without pause (GO). 

Change the number-civs slider bar to create more or fewer total Civilizations on model initiation. It is recommended to start with 10 Civs.

The on/off switches in the bottom left control:

1. Whether to keep farm-size uniform across all initiated Civs or to let the farm-size be random.

2. Whether to keep the SoL uniform across all initiated Civs (at 0) or to let the SoL be calculated randomly (positively or negatively, depending on its initiating farm-excess). 

It is suggested to STEP through the model one year at a time observing as the Civs expand, conflict, die, adn conquer.  

"C's" occur on patches where conflict occurs.

## THINGS TO NOTICE

Notice the Civilization Size graph. Pay attention to the relative sizes of each Civ as they expand and the size of the largest Civ at time of final dominance.

Pay attention to Standard of Living of Civs, especially if SoL is set to 0 for all Civs on initiation.

It is recommended to use the Command Center to observe individual Civs and their respective variables (use "inspect Civ 1") as the dynamics play out. 


## EXTENDING THE MODEL

The next iteration of this model will need to include internal Civ dynamics, internal Civ heterogeneity, Civ stagnation and decline without conflict, and more complex conflict procedures.


## CREDITS AND REFERENCES

The theoretical foundations for this model are found in Carroll Quigley's 1961 book The Evolution of Civilizations. 

Quigley, C., & Marina, W. (1979). The evolution of civilizations: An introduction to historical analysis. Indianapolis, IN (originally published in 1961): Liberty Fund.
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

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

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
