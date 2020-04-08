;==============================================================================================
; This NetLogo model explores the phenomenon of a Common Pool Resource (CPR) Dilemma.  The scenario is described as follows:
;   1)  There are two star-crossed noble houses, living in a fantastic, magical world.
;   2)  Growing in a wellspring at the center of the city, there are magic purple truffles that can be gathered.
;   3)  Truffles are extremely valuable, and both houses crave them.
;   4)  Competition over this limited resource has fueled rivalry and strife between the two noble houses.
;   5)  Truffles grow only within the wellspring, and can be replenished over time.  However, the regrowth is a function of surrounding truffle levels.
;   6)  Both noble houses send trufflers to gather the truffles.  The number of active trufflers increases over time.
;   7)  The trufflers each have a bag to hold their gatherings.  When his bag is full, the truffler returns to his faction's front door to deliver his truffles payload.
;   8)  Ultimately, this is a tragedy (of the commons) regarding two star-crossed noble houses.  Therefore, the truffles wellspring will inevitably be depleted.
;==============================================================================================


;----------------------------------------------
; Declare all the global variables & breeds
;----------------------------------------------
globals [
  truffles-patches      ; purple patches representing the wellspring of truffles
  truffles-per-patch    ; default number of truffles on a single wellspring patch (also dictates truffler bag size)
  wellspring-capacity   ; the wellspring's maximum truffles capacity
  remaining-truffles    ; the total number of truffles currently remaining in the wellspring
  sliding-window        ; storage list of recent values for 'remaining-truffles'
  previous-average      ; the previous moving average value for 'remaining-truffles'

  montague-color        ; House Montague's faction color
  capulet-color         ; House Capulet's faction color
  montague-door         ; patch representing House Montague's front door
  capulet-door          ; patch representing House Capulet's front door
  montague-coffer       ; House Montague's coffer of truffles
  capulet-coffer        ; House Capulet's coffer of truffles
  montague-prev-balance ; House Montague's previous account balance of truffles
  montague-cashflow     ; House Montague's truffles cash flow
  montague-trufflers    ; House Montague's number of active trufflers
]

breed [trufflers truffler]    ; trufflers will gather truffles

;----------------------------------------------
; Declare all the common agent attributes
;----------------------------------------------
trufflers-own [
  faction             ; the noble house that they serve
  truffles            ; the number of truffles currently in their bag
  max-truffles        ; the max capacity of the truffler's bag
]

patches-own [
  pflag               ; flag indicating if the patch is within the truffles wellspring
  ptruffles           ; the current amount of truffles on this patch
  max-ptruffles       ; the max limit of truffles on this patch
]

;----------------------------------------------
; Setup the simulation
;----------------------------------------------
to Setup
  clear-all
  ask patches [ set pcolor 67 ]

  ; Initialize default global variables
  set truffles-per-patch 10

  ; Populate the sliding window with dummy values
  set sliding-window n-values 5 [random 300]
  ; Initialize the first moving average value
  set previous-average mean sliding-window

  ; Create the truffles wellspring
  set truffles-patches patches with [ (distancexy 0 0) <= 15 ]
  ask truffles-patches [
    set pcolor violet
    set pflag 1
    set max-ptruffles truffles-per-patch
    set ptruffles max-ptruffles
  ]
  set wellspring-capacity sum [ptruffles] of truffles-patches
  set remaining-truffles wellspring-capacity

  ; Set the noble house faction colors
  set montague-color red
  set capulet-color cyan

  ; Set the house front doors
  set montague-door patches with [(pxcor = -22) and (pycor > -4 and pycor < 4)]
  set capulet-door patches with [(pxcor = 22) and (pycor > -4 and pycor < 4)]

  ; Initialize the factions' coffers
  set montague-prev-balance 0
  set montague-coffer 0
  set capulet-coffer 0

  ; Create the 2 houses of Montague and Capulet, with associated faction colors
  CreateHouses

  ; Create a fence around the city of Verona
  ask patches with-max [pxcor] [set pcolor brown]
  ask patches with-min [pxcor] [set pcolor brown]
  ask patches with-max [pycor] [set pcolor brown]
  ask patches with-min [pycor] [set pcolor brown]

  ; Create the Montague trufflers
  CreateTrufflers 1 montague-color montague-door "Montague"
  set montague-trufflers count trufflers with [faction = "Montague"]

  ; Create the Capulet trufflers
  CreateTrufflers 1 capulet-color capulet-door "Capulet"

  reset-ticks

end

to CreateHouses

  ;---------------------------------------------------
  ; Create the houses
  ask patches with [(distancexy 0 0 > 22) and (distancexy 0 0 < 28) and (pycor > -10 and pycor < 10)]
  [ set pcolor 9 ]

  ;---------------------------------------------------
  ; Create the Montague front door
  ask patches with [(pxcor = -22) and (pycor > -4 and pycor < 4)] [
    set pcolor montague-color + 3
  ]
  ; Label the Montague house
  ask patch -21 12 [
    set plabel-color montague-color
    set plabel "Montague"
  ]

  ;---------------------------------------------------
  ; Create the Capulet front door
  ask patches with [(pxcor = 22) and (pycor > -4 and pycor < 4)] [
    set pcolor capulet-color + 1
  ]
  ; Label the Capulet house
  ask patch 26 12 [
    set plabel-color capulet-color - 2
    set plabel "Capulet"
  ]

end

to CreateTrufflers [number-servants faction-color spawn-point faction-name]
  create-trufflers number-servants [
    set shape "person"
    set size 2
    set color faction-color
    set label-color black
    move-to one-of spawn-point with-min [count turtles-here]
    set faction faction-name                  ; set the truffler's faction
    set max-truffles truffles-per-patch      ; max number of truffles the truffler can take in one trip
    set truffles 0                            ; start with an empty truffles bag
  ]
end

;----------------------------------------------
; Run the simulation
;----------------------------------------------
to Go

  ; Display the coffer of House Montague
  ask patch -21 -12 [
    set plabel-color montague-color
    set plabel montague-coffer
  ]

  ; Display the coffer of House Capulet
  ask patch 26 -12 [
    set plabel-color capulet-color - 2
    set plabel capulet-coffer
  ]

  ; Simulate the trufflers' actions
  ask trufflers [
    HuntTruffles
    set label truffles     ; Display the number of truffles in each truffler's bag
  ]

  ; Calculate Montague's cash flow of truffles
  set montague-cashflow (montague-coffer - montague-prev-balance)
  set montague-prev-balance montague-coffer

  ;================================================================
  ; Decide when more trufflers should be added
  ;   The initial trufflers need some time to start generating a flow of truffles
  ;   Wait for 5 ticks to allow the Transient State to elapse
  if (ticks > 5) [

    ; Option A:  Blindly add more resource demand, without reacting to the health of the resource
    ;   Trufflers will be added at regular time intervals (with a fixed time period/frequency)
    if (Truffler-Wave-Trigger = "Time Interval") [
      let tick-countdown remainder ticks Truffler-Wave-Period
      if (tick-countdown = 0) [
        CreateTrufflers Truffler-Wave-Size montague-color montague-door "Montague"
        CreateTrufflers Truffler-Wave-Size capulet-color capulet-door "Capulet"
      ]
    ]

    ; Option B:  Titrate the resource demand, by actively reacting to the health of the resource
    ;   Trufflers will only be added when a Steady-State has been reached, or if the resource is rebounding (with an event-driven occurence)
    if (Truffler-Wave-Trigger = "Resource Cue") [
      if (Average-Trend >= 0) [
        CreateTrufflers Truffler-Wave-Size montague-color montague-door "Montague"
        CreateTrufflers Truffler-Wave-Size capulet-color capulet-door "Capulet"
      ]
    ]
    ;   Trufflers will be removed when the moving average is decreasing too much
    if (Truffler-Wave-Trigger = "Resource Cue") [
      let total-trufflers count trufflers
      if (Average-Trend < Truffle-Decline-Threshold and total-trufflers > 2) [
        ask one-of trufflers with [faction = "Montague"] [die]
        ask one-of trufflers with [faction = "Capulet"] [die]
      ]
    ]

  ]
  ;================================================================

  ; Count the number of active Montague trufflers
  set montague-trufflers count trufflers with [faction = "Montague"]

  ; Truffles regrow over time, as a function of neighboring truffle density
  ask truffles-patches [
    RegrowTruffles
    RecolorTruffles
  ]

  ; Compute the remaining truffles in the wellspring
  set remaining-truffles sum [ptruffles] of truffles-patches

  ; End the simulation when the truffles wellspring is ruined, never to regrow truffles again
  if (remaining-truffles = 0) [
    print "A Tragedy (of the Commons) has occurred...."
    stop
  ]

  tick

end

; Function to use when checking for the moving average's trend
to-report Average-Trend

  ; Update the sliding window
  set sliding-window fput remaining-truffles but-last sliding-window

  let current-average mean sliding-window
  let deviation ( (current-average - previous-average) / (previous-average + 0.01) ) * 100   ; multiply by 100 to convert to percentage
  set previous-average current-average

  report deviation

end

; Go hunt for some truffles
to HuntTruffles

  ; Trufflers move to the most truffle-rich patch, preferring least distance
  let vacant-patches truffles-patches with [not any? turtles-here]
  let target-patches vacant-patches with-max [ptruffles]
  move-to one-of target-patches with-min [distance myself]

  ; Is the bag full?
  ;   If full, deliver the truffle payload back to your faction's front door
  ;   If not full, grab some more truffles to fill your bag
  ifelse (truffles = max-truffles) [
    ; The bag is full, so deliver the payload back home
    DeliverPayload
  ][
    ; The bag is not full, so keep taking more truffles
    ifelse (ptruffles > 0) [
      ; Stay on the current wellspring patch if it still has truffles
      TakeTruffles
    ][
      ; The current wellspring patch is empty, so shift to the neighboring patch with the most truffles
      uphill ptruffles
      TakeTruffles
    ]
  ]

end

; Physically put some truffles into your bag
to TakeTruffles

  ; Fill your bag with the truffles available on your current patch
  ;   The 'Truffle-Harvest-Rate' governs how fast the bag can be filled
  let remaining-capacity (max-truffles - truffles)
  let number-taken min( list (remaining-capacity) (Truffler-Scoop-Size) (ptruffles) )

  ; Put the truffles into the bag
  set ptruffles (ptruffles - number-taken)
  set truffles (truffles + number-taken)

end

; Deliver the truffle payload back home, when your bag is full
to DeliverPayload

  if faction = "Montague" [
    move-to one-of montague-door with-min [count turtles-here]
    set montague-coffer (montague-coffer + truffles)
    set truffles 0
  ]

  if faction = "Capulet" [
    move-to one-of capulet-door with-min [count turtles-here]
    set capulet-coffer (capulet-coffer + truffles)
    set truffles 0
  ]

end

; The truffles wellspring will regrow some truffles
to Regrowtruffles

  ; Define the 8-neighbor truffles-patches inside the wellspring
  let wellspring-neighbors neighbors with [pflag = 1]

  ; Define the truffles regrowth rate, which is a function of the neighboring amount of truffles
  ;   If the surrounding amount of truffles is high, the regrowth is high
  ;   If the surrounding amount of truffles is low, the regrowth is low
  let regrowth-factor round( (mean [ptruffles] of wellspring-neighbors) / truffles-per-patch )

  ; Regrow the truffles, but cap it at the max value
  set ptruffles min( list (max-ptruffles) (ptruffles + Truffle-Regrowth-Coefficient * regrowth-factor) )

end

; Update the patch colors to reflect how many truffles are available
;   Saturated color   = more truffles
;   Desaturated color = fewer truffles
to Recolortruffles
  set pcolor ( violet + 4.9 * (1 - ptruffles / max-ptruffles) )
end
@#$#@#$#@
GRAPHICS-WINDOW
248
57
890
450
-1
-1
10.4
1
20
1
1
1
0
0
0
1
-30
30
-18
18
0
0
1
ticks
30.0

BUTTON
9
27
108
60
Setup
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
130
27
229
60
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
109
229
142
Truffle-Regrowth-Coefficient
Truffle-Regrowth-Coefficient
0
3
1.0
1
1
x
HORIZONTAL

SLIDER
8
201
229
234
Truffler-Scoop-Size
Truffler-Scoop-Size
2
10
10.0
2
1
truffles
HORIZONTAL

PLOT
906
10
1325
160
Truffles in Wellspring
ticks
Truffles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" "plot remaining-truffles"

SLIDER
8
302
228
335
Truffler-Wave-Size
Truffler-Wave-Size
0
5
1.0
1
1
servants
HORIZONTAL

PLOT
906
179
1106
329
Montague-Coffer
ticks
Truffles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot montague-coffer"

PLOT
1125
347
1325
497
Montague-Trufflers
ticks
Servants
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot montague-trufflers"

CHOOSER
8
399
191
444
Truffler-Wave-Trigger
Truffler-Wave-Trigger
"Time Interval" "Resource Cue"
1

SLIDER
8
250
229
283
Truffler-Wave-Period
Truffler-Wave-Period
5
20
20.0
5
1
ticks
HORIZONTAL

SLIDER
7
462
227
495
Truffle-Decline-Threshold
Truffle-Decline-Threshold
-0.5
0
-0.02
0.01
1
%
HORIZONTAL

PLOT
1125
179
1325
329
Montague-Cash-Flow
ticks
Truffles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot montague-cashflow"

TEXTBOX
11
85
161
103
Resource Supply
14
0.0
1

TEXTBOX
10
177
160
195
Resource Demand
14
0.0
1

TEXTBOX
11
373
161
391
Decision Rule
14
0.0
1

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
<experiments>
  <experiment name="experiment_TimeInterval" repetitions="1" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Go</go>
    <timeLimit steps="5000"/>
    <metric>remaining-truffles</metric>
    <metric>montague-coffer</metric>
    <metric>montague-cashflow</metric>
    <metric>montague-trufflers</metric>
    <steppedValueSet variable="Truffler-Wave-Period" first="5" step="5" last="20"/>
    <steppedValueSet variable="Truffler-Scoop-Size" first="7" step="1" last="10"/>
    <enumeratedValueSet variable="Truffle-Decline-Threshold">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Truffler-Wave-Size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Truffler-Wave-Trigger">
      <value value="&quot;Time Interval&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Truffle-Regrowth-Coefficient">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_ResourceCue" repetitions="1" runMetricsEveryStep="true">
    <setup>Setup</setup>
    <go>Go</go>
    <timeLimit steps="5000"/>
    <metric>remaining-truffles</metric>
    <metric>montague-coffer</metric>
    <metric>montague-cashflow</metric>
    <metric>montague-trufflers</metric>
    <enumeratedValueSet variable="Truffler-Wave-Period">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Truffler-Scoop-Size" first="7" step="1" last="10"/>
    <steppedValueSet variable="Truffle-Decline-Threshold" first="-0.1" step="0.02" last="0"/>
    <enumeratedValueSet variable="Truffler-Wave-Size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Truffler-Wave-Trigger">
      <value value="&quot;Resource Cue&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Truffle-Regrowth-Coefficient">
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
