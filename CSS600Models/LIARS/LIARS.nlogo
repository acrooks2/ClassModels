turtles-own [
  individuality
  supporters   ; how many neighboring patches have a turtle with my color?
  opposers     ; how many have a turtle of another color?
  support
  opposition
  strength
  blue-falsified? ; is the agent falsifying their preferences?
  red-falsified?
  private-vote-red ; private preferences of the agents
  private-vote-blue
  public-vote-red ; agents' public preferences, which may or may not be the same as their private vote
  public-vote-blue
]

globals [show-falsified?
         red-falsified
         blue-falsified
         public-red-support
         public-blue-support
         private-red-support
         private-blue-support
         red-actual
         blue-actual
         red-poll
         blue-poll
         red-poll-error
         blue-poll-error
         population]

to setup
  clear-all
  ; create turtles on random patches.
  set show-falsified? true
  ask patches [
    set pcolor white
    if random 100 < density [   ; set the occupancy density
      sprout 1 [
        ; 105 is the color number for "blue"
        ifelse random 100 < party-split
        ; populates agents initially according to proportion of party-split slider
            [set color 15]
            [set color 105]
        set size 1
        set strength 1 ; default strength
        set shape "square"
        set individuality random-float individ-cap ; set individuality initial value
        ifelse color = 15
            [ set private-vote-red 1]
            [ set private-vote-blue 1]
      ]
    ]
  ]
  set population count turtles with [color = 15 or color = 105]
  reset-ticks
end

to warm-up ; sort agents initially into opinion blocks
           ; note that sorting here does not take individuality into account and uses default strength value of 1.0
           ; individuality values and different strength values therefore only come into effect after sorting
           ; this is done to avoid biasing the initial sorting, which is just supposed to create some balanced terrain
           ; the only thing that will unbalance the terrain is party-split
let number-changed 125
let warm-strength 1.0
  while [number-changed >= 125] [
    let temp-number-changed 0
    ask turtles [
      set supporters turtles with [ color = [ color ] of myself and  who  != [ who ] of myself]
      set opposers turtles with [ color != [ color ] of myself and  who  != [ who ] of myself]
      set support sqrt sum [(warm-strength / ((distance myself) ^ 2)) ^ 2] of supporters
      set opposition sqrt sum [(warm-strength / ((distance myself) ^ 2)) ^ 2] of opposers
      if support < opposition [
        ifelse color = 15
        [ set color 105
          set private-vote-blue 1
          set private-vote-red 0]
        [ set color 15
          set private-vote-blue 0
          set private-vote-red 1]
        set temp-number-changed temp-number-changed + 1
      ]
]
set number-changed temp-number-changed
; number-changed and temp-number-changed keep track of how many agents are changing their minds each round
; once number-changed falls below the threshold of 125 (approximately 5% of the grid population), warm-up ends
  ]
end


to update-turtles
  ask turtles [
    ifelse color = 15
      [set public-vote-blue 0
       set public-vote-red 1
       set strength red-strength]
      [set public-vote-blue 1
       set public-vote-red 0
       set strength blue-strength]
    set supporters turtles with [ color = [ color ] of myself and  who  != [ who ] of myself]     ; count my supporters
    set opposers turtles with [ color != [ color ] of myself and  who  != [ who ] of myself]      ; count my enemies
    set support sqrt sum [(strength / ((distance myself) ^ 2)) ^ 2] of supporters + individuality ; sum up support
    set opposition sqrt sum [(strength / ((distance myself) ^ 2)) ^ 2] of opposers                ; sum up opposition from enemies
    if support < opposition [                                                                     ; if enemies outweigh my friends, I'll switch colors
     ifelse color = 15
      [ set color 105
        set red-falsified?  1]
      [ set color 15
        set blue-falsified?  1]]


    set public-red-support sum [public-vote-red] of turtles
    set public-blue-support sum [public-vote-blue] of turtles
    set private-red-support sum [private-vote-red] of turtles
    set private-blue-support sum [private-vote-blue] of turtles

    set red-poll public-red-support / population * 100 ; percentage of total population recorded as supporting red
    set blue-poll public-blue-support / population * 100

    set red-actual private-red-support / population * 100 ; percentage of total population that actually supports red
    set blue-actual private-blue-support / population * 100

    set red-poll-error red-poll - red-actual
    set blue-poll-error blue-poll - blue-actual

    set red-falsified count turtles with [ red-falsified? = 1] / count turtles  * 100
    set blue-falsified count turtles with [ blue-falsified? = 1] / count turtles  * 100
  ]
end

to show-falsified
  ; highlights falsifying turtles
  ifelse show-falsified?
    [ask turtles with [ color =  15  and blue-falsified? = 1] [
      set color 17]
    ask turtles with [ color =  105  and red-falsified? =  1] [
      set color 107]
    set show-falsified? false]

    [ask turtles with [ color =  17  and blue-falsified? = 1] [
      set color 15]
     ask turtles with [ color =  107  and red-falsified? =  1] [
      set color 105]
    set show-falsified? true]

end

to go
  while [ticks < 12] [
    update-turtles
    tick ]
end
@#$#@#$#@
GRAPHICS-WINDOW
213
10
629
427
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

SLIDER
3
3
175
36
density
density
0
100
90.0
1
1
NIL
HORIZONTAL

BUTTON
5
241
68
274
NIL
setup\n
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
70
241
133
274
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
5
277
205
427
Falsification Proportion
time
% falsified
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot red-falsified"
"pen-1" 1.0 0 -14070903 true "" "plot blue-falsified\n\n"

BUTTON
5
206
85
239
NIL
warm-up
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
4
108
176
141
blue-strength
blue-strength
0
2
1.0
0.1
1
NIL
HORIZONTAL

SLIDER
4
72
176
105
red-strength
red-strength
0
2
1.2
0.1
1
NIL
HORIZONTAL

SLIDER
4
38
176
71
party-split
party-split
0
100
87.0
1
1
NIL
HORIZONTAL

BUTTON
89
206
197
239
NIL
show-falsified\n
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
636
10
836
160
Polling
Time
% Support
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot red-poll"
"pen-1" 1.0 0 -13345367 true "" "plot blue-poll"

MONITOR
636
317
744
362
public red agents
count turtles with [public-vote-red = 1]
17
1
11

MONITOR
635
365
747
410
public blue agents
count turtles with [public-vote-blue = 1]
17
1
11

PLOT
636
162
836
312
Actual Support
Time
% Support
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot red-actual\n\n"
"pen-1" 1.0 0 -13345367 true "" "plot blue-actual\n"

MONITOR
752
318
868
363
private red agents
count turtles with [private-vote-red = 1]
17
1
11

MONITOR
749
364
869
409
private blue agents
count turtles with [private-vote-blue = 1]
17
1
11

SLIDER
4
145
176
178
individ-cap
individ-cap
1
5
1.0
1
1
NIL
HORIZONTAL

MONITOR
637
415
724
460
red-poll-error
red-poll-error
1
1
11

MONITOR
727
415
819
460
blue-poll-error
blue-poll-error
1
1
11

MONITOR
873
317
992
362
falsified red agents
count turtles with [public-vote-red = 1 and private-vote-blue = 1]
17
1
11

MONITOR
873
364
997
409
falsified blue agents
count turtles with [public-vote-blue = 1 and private-vote-red = 1]
17
1
11

@#$#@#$#@
## WHAT IS IT?

The LIARS model is an agent-based model of preference falsification, where agents calculate whether or not to deliberately misrepresent their voting intentions based on feedback from their neighbors.

## HOW IT WORKS

Agents are endowed with a level of strength and individuality. At each step, agents calculate the total support by counting the number of other agents the same color as them, and then modifying that by those agents' strength and distance away from the calculating agent. If total support + an agent's individuality factor outweighs opposition (calculated similarly but counting agents of the opposite color), an agent will stay the same color. However, if opposition outweighs support, the agent will decide to falsify their preferences and pretend to be the opposite color. 

## HOW TO USE IT

First, populate the grid with the "setup" button, which will spawn agents on patches to a total proportion set by the "density" slider. Next, warm up the model by using the "warm-up" option, which initially sorts agents into opinion neighborhoods to mimic the geographic layout of political affiliation that we see in real life. Next, hit the "go" button which will lead the model through 12 ticks, each tick representing one month in a pre-election campaign cycle. At each step, agents will update their preferences and decide whether or not to falsify. Agent distribution, falsification, and polling is kept track of by monitors and plots on either side of the main grid:

Falsification Proportion tells you what percentage of red agents and blue agents are actively falsifying.

Polling tells you the levels of "reported" support for each party, which only looks at the expressed preferences of agents and not their true preferences. In other words, falsifying agents' opinions will count as support for that color's candidate.

Actual Support tells you the actual levels of support for each party, according to the true preferences of each agent, which do not change over time. 

Public Red Agents and Public Blue Agents tells you how many agents are currently reporting to be either red or blue according to their publicly expressed preferences.

Private Red Agents and Private Blue Agents conversely tell you how many actual red and blue agents there are according to their private preferences.

Falsified Red Agents and Falsified Blue Agents tell you how many fake red and blue agents there are, i.e. how many red and blue agents are actually blue or red agents pretending to be their respective opposite colors.

Finally, Red Poll Error and Blue Poll Error take the difference between reported polling and actual support to provide a measure of polling error. 

In addition to the monitors and plots, there are a number of options and sliders to use to change the attributes of agents and the grid. 

"density" controls how dense the population is in % terms. For example, a density value of 88 will mean that 88% of the grid will be populated.

"party-split" controls the starting proportion of red agents versus blue agents.

"red-strength" and "blue-strength" control the starting distribution of strength values for each party.  	

"individ-cap" sets a maximum value for how the individuality attribute of each agent.

## THINGS TO NOTICE

Notice that after finishing a run of the model, you can hit the "show-falsified" button that will highlight actively falsified agents, to give you an idea of the geographic distribution of such agents.

## THINGS TO TRY

Try putting one party at a disadvantage numerically, but giving them an advantage in strength. For instance, set a 40-60 or even 30-70 party split, but give the minority party a large advantage in strength of preference expression, and see what happens. 

## EXTENDING THE MODEL

Add more choices for agents to falsify as, including "uncertain" or "not going to vote," so that there's not as much symmetrical polling error. 

Can also add in "regions" for the grid so that different areas have different initial starting characteristics, similar to actual states or districts in real world countries. 

You could also try to change how the "individuality" and "strength" factors are allocated. Rather than randomly assigning individuality, for instance, you could make one party more individualistic than the other. As for strength, instead of assigning it as a flat value based on the slider to one party, perhaps it could be allocated randomly with a ceiling, similar to individuality.

One other thing to try might be to create high-strength individuals each round that represent media personalities, politicians, etc., that wield outsize influence on public opinion.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

Check out the SITSIM model of Latané, as mentioned below. 

## CREDITS AND REFERENCES

The code for agents determining whether or not to preference falsify is based in large part on the SITSIM model of Latané in his 1996 paper, Dynamic Social Impact: The Creation of Culture by Communication. The precise equation used to replicate the SITSIM model comes from Gilbert & Troitzsch's 2005 book, "Simulation for the Social Scientist." Inspiration for using neighborhoods to think about preference falsification also came from Schelling's 1972 segregation model. 
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
  <experiment name="experiment" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="true">
    <setup>setup
warm-up</setup>
    <go>go</go>
    <timeLimit steps="12"/>
    <metric>red-poll-error</metric>
    <metric>blue-poll-error</metric>
    <metric>red-falsified</metric>
    <metric>blue-falsified</metric>
    <steppedValueSet variable="density" first="50" step="10" last="100"/>
    <steppedValueSet variable="party-split" first="40" step="10" last="60"/>
    <steppedValueSet variable="blue-strength" first="1" step="0.2" last="2"/>
    <steppedValueSet variable="individ-cap" first="1" step="1" last="3"/>
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
