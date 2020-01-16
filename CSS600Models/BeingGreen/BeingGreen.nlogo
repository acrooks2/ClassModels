turtles-own [
 action-taker? ;; if true the person takes pro-environmental action.
 susceptible? ;; true if social pressure > 50%
 internal? ;; true if locus of control > 50%
 responsible? ;; true if social responsibility > 50%
 ;; these values are controlled by sliders:
 locus-of-control ;; does the person believe he has the power to change extrenal outcomes?
 sense-of-responsibility ;; does the person feel a sense of personal responsibility?
 PBC ;; perceived behavioral control; belief regarding the ability to perform the behavior
 social-pressure ;; how susceptiable is the person to social pressures?
]

;;; Setup Procedures:

to setup
  clear-all
  setup-people
  reset-ticks
end

to setup-people
  crt initial-people
    [ setxy random-xcor random-ycor
      set shape "person"
      ;; 10% of the people start out as action-takers
      set action-taker? (who < initial-people * 0.10)
      assign-locus-of-control
      assign-sense-of-responsibility
      assign-PBC
      assign-social-pressure
      assign-color
      ifelse social-pressure > 70 [set susceptible? true] [set susceptible? false]
      ifelse locus-of-control > 70 [set internal? true] [set internal? false ]
      ifelse sense-of-responsibility > 70 [set responsible? true] [set responsible? false]
      ]
end

;; Different people are displayed in 2 different colors:
;; green is an action-taker
;; red is everyone else; i.e. not action takers

to assign-color  ;; turtle procedure
  ifelse action-taker?
    [ set color green ]
    [ set color red ]
end

;; The following procedures assign turtle variables which can be manipulated by the sliders.
;; The procedure RANDOM-NORMAL is used so that the turtle variables have an approximately
;; "normal" distribution around the average values set by the sliders.

to assign-locus-of-control  ;; turtle procedure
  set locus-of-control random-normal average-locus-of-control 10
end

to assign-sense-of-responsibility  ;; turtle procedure
  set sense-of-responsibility random-normal average-sense-of-responsibility 10
end

to assign-PBC  ;; turtle procedure
  set PBC random-normal average-PBC 10
end

to assign-social-pressure  ;; turtle procedure
  set social-pressure random-normal average-social-pressure 10
end



;;; GO Procedures:

;; a green agent will move until they find a red agent, then interact with them in order to "influenece"
;; a red agent will move until they are "cornered" by a green agent...

to go
  if all? turtles [action-taker?]
    [ stop ]
  ask turtles
    [move ]
  ask turtles with [action-taker?] [ interact ]
  ask turtles [ test ]
  ask turtles [ assign-color ]
  ask turtles [evaluate-parameters]
  tick
end

;; People move about at random.

to move  ;; turtle procedure
  rt random-float 360
  fd 1
end

;; Action takers (green agents) check their patch and neighborhood for
;; red agents. If there are red agents, they "influence". otherwise, they move

to interact ;; turtle procedure
  let nearby-red (turtles-on neighbors)
    with [not action-taker?]
    if nearby-red != nobody
    [ask nearby-red [influence]]
end

;;to influence
  ;;set pcolor grey
;;end


;; a green agent can influence a red agent only if he is susceptible, external
;; and responsible. If these conditions are not met, the red agent's PBC
;; increases and both agents move.

to influence  ;; turtle procedure
  if not susceptible?
  [set social-pressure (social-pressure + 1) move]

  if susceptible? and not internal?
  [set PBC (PBC + 5) set locus-of-control (locus-of-control + 1) move ]

  if susceptible? and internal? and not responsible?
  [set PBC (PBC + 5)
  set sense-of-responsibility (sense-of-responsibility + 5) move ]

  if susceptible? and internal? and responsible?
  [set PBC (PBC + 5) move]
end

;; following every interaction the agents are checked. If locus of control is
;; larger than 70%, social responsibility is larger than 70% and PBC is
;; larger than 70%, the agent automatically becomes an action taker.

to test ;; turtle procedure
  if locus-of-control > 70 and sense-of-responsibility > 70 and
  PBC > 70
  [set action-taker? true set color green]
end

to evaluate-parameters
  ifelse social-pressure > 70 [set susceptible? true] [set susceptible? false]
  ifelse locus-of-control > 70 [set internal? true] [set internal? false ]
  ifelse sense-of-responsibility > 70 [set responsible? true] [set responsible? false]
end

;;; Monitor procedure:

to-report action-rate
  ifelse any? turtles
    [ report (count turtles with [action-taker?] / count turtles) * 100 ]
    [ report 0 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
307
15
773
482
-1
-1
13.9
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
42
37
112
70
SETUP
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
123
37
186
70
NIL
GO
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
199
31
282
76
Action Rate
action-rate
3
1
11

SLIDER
40
100
253
133
average-locus-of-control
average-locus-of-control
0
100
50.0
10
1
NIL
HORIZONTAL

SLIDER
43
142
249
175
average-social-pressure
average-social-pressure
0
100
50.0
10
1
NIL
HORIZONTAL

SLIDER
21
183
276
216
average-sense-of-responsibility
average-sense-of-responsibility
0
100
50.0
10
1
NIL
HORIZONTAL

SLIDER
41
223
258
256
average-PBC
average-PBC
0
100
20.0
10
1
NIL
HORIZONTAL

PLOT
23
315
284
504
Action vs No Action
time
people
0.0
1000.0
0.0
1000.0
true
true
"set-plot-y-range 0 (initial-people + 50)" ""
PENS
"No Action" 1.0 0 -2674135 true "" "plot count turtles with [not action-taker?]"
"Action " 1.0 0 -10899396 true "" "plot count turtles with [action-taker?]"

SLIDER
53
268
225
301
initial-people
initial-people
10
1000
200.0
10
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model attempts to evaluate how environmentally friendly behavior spreads within a target population. It uses four key parameters drawn from the theory of planned behavior and social cognitive theory to observe how these parameters affect behavior.  

## HOW IT WORKS

There are two types of agents in the model, differentiated by their color: green agents are "action takers" or people already engaged in climate friendly behavior. red agents are not action takers. In the initial setup, 10% of the population start as green. 

When the model starts, green and red agents begin to interact. Every interaction the parameters represented by the sliders are checked. If the person is susceptible to social pressure, he will be influenced by the green agent and move closer towards taking action. When a person's percieved behavioral control, social responsibility, and locus of control increase above a certain threshold (> 70), the red agent will turn to action taker and its color will turn green. 

## HOW TO USE IT

SETUP: sets up the model's initial conditions
GO: begins the simulation. The simulation stops when all agents turn green, i.e. action takers.

Model Parameters: all on a scale from 1-100. Randomly distributed among the agents around the value selected by the slider:

- Avergae-locus-of-control: does the person believe he has the power to change extrenal outcomes? 
- Average-sense-of-responsibility: does the person feel a sense of personal responsibility?
- Average-PBC: perceived behavioral control; does the person believe he has the ability to perform the examined behavior?
- Average-social-pressure: Is the person susceptiable to person to social pressures? 

The plot shows the number of green and red agents over time. The monitor displays the percentage of green agents over the total population-- the action taking rate.

## THINGS TO TRY

When running the model, try and change the value of the sliders to see how the rate of environmentally friendly behavior change. See how the time to contagion change when parameters are set low or high. Change the number of initial people to see how that parameter changes the rate of behavior.

## EXTENDING THE MODEL

Currently the model does not evaluate interactions between red agents. Try and add interactions with influential red agents which move an agent further from taking action. See what happens if you allow green agents to go back to red. 

## NETLOGO FEATURES

The model uses the NetLogo random-normal procedure to introduce heterogeneity for the agents. The procedure creates a random distribution where the mean is the value selected by the slider and the standard deviation can be adjusted.  

## CREDITS AND REFERENCES

Theory based on: Ajzen, I. (2002). Perceived behavioral control, self-efficacy, locus of control, and the theory of planned behavior. Journal of Applied Social Psychology, 32 , 665-683.

Many model features were influenced by: Yang, C. and Wilensky, U. (2011). NetLogo epiDEM Basic model. http://ccl.northwestern.edu/netlogo/models/epiDEMBasic. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 
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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles with [action-taker?]</metric>
    <steppedValueSet variable="average-social-pressure" first="40" step="10" last="100"/>
    <steppedValueSet variable="average-locus-of-control" first="40" step="10" last="100"/>
    <steppedValueSet variable="average-sense-of-responsibility" first="40" step="10" last="100"/>
    <steppedValueSet variable="average-PBC" first="40" step="10" last="100"/>
    <steppedValueSet variable="initial-people" first="50" step="100" last="1000"/>
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
