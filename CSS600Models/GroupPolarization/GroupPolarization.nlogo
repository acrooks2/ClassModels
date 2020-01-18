globals [
  argument-pool-1
  argument-pool-2
  temp-1 ;;for ploting
  temp-2 ;;for ploting
  active-id ;; for differnt pick-buddy mode (not use now)
  show-network?
  shift
  ]

turtles-own [
  influence ;; this variable doesn't deal with social comparison
  ;;but deal with  persuasive argument/ self-categorization theory/social decision scheme Friedkin p 859-60 (not use now)
  pool-id
  individual-ap ;; a list of individual argument pool
  compared-argument ;; variable to deal with social comparison hypothesis brown p. 215 1.3 / brown p.219 2.3
  pre-temp ;; initial argument
  pre-temp-0 ;; item 0 of initial argument
  post-temp ;; strongest or compared argument depend on the mode
  post-temp-0;; item 0 of compared argument
  temp-argument ;; randomly chosen argument for interaction
  my-buddies
  my-buddy
  buddied?
  ]

patches-own []
extensions  []

to setup
  ;;random-seed 1
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks ;; ca
  ask patches [set pcolor gray - 3]
  set show-network? true
  crt-turtles
  pool-setup-1 ;; Brown p.219- 1.1
  pool-setup-2
  intialize-individual-ap ;; Brown p.219 1.2
  setup-pre-temp ;;
  setup-post-temp
  update-initial-plot ;; extract item 0 from both argument pools and pre-temp
  do-initial-plots ;; plot the two APs
  update-pre-color
  define-group ;; social influence network which covers social decision scheme as well
end

to go
  pick-buddy
  highlight-link
  pick-argument
  interact
  sort-ap
  forget
  dehighlight-link
  lose-buddy
  update-compared-argument
  update-color
  update-turtles
  calculate-shift
  do-plot
  clear-links
  ask n-of (chance-to-move * tnumber / 100) turtles [move]
  define-group

  tick
end

to crt-turtles
  if tnumber > count patches [
    user-message (word "This pond only has room for "count patches" turtles.") stop]
  ask n-of tnumber patches [
    sprout 1 [
      set shape "person"
      set size 1
      set influence random 100
      set buddied? false
      ]
  ]
end

to move ;;simulate people leave and join groups
  rt random-float 360
  fd 1
  move-to patch-here
end

to define-group ;;to define group and create network
  ask turtles [
    ifelse range-of-interaction = 3 [
      ;set my-buddies sort (turtles in-radius 2)
      set my-buddies sort other (turtles in-radius 2)
      ;set my-buddies-list sort my-buddies
      if show-network? [foreach my-buddies [ ?1 -> if ?1 != self [create-link-with ?1] ]]][
      ifelse range-of-interaction = 2 [
        ;set my-buddies sort (turtles-on neighbors)
        set my-buddies sort other (turtles-on neighbors)
        ;set my-buddies-list sort my-buddies
        if show-network? [foreach my-buddies [ ?1 -> if ?1 != self [create-link-with ?1] ]]][
        ;set my-buddies sort (turtles-on neighbors4)
        set my-buddies sort other (turtles-on neighbors4)
        ;set my-buddies-list sort my-buddies
        if show-network? [foreach my-buddies [ ?1 -> if ?1 != self [create-link-with ?1] ]]]
        ]
  ]
end


to pick-buddy ;; to pick a target
    ask turtles with [not empty? my-buddies] [
;      if not empty? my-buddies = true [
        if my-buddy = 0 [
        set my-buddy one-of my-buddies
        ask my-buddy [
          ifelse my-buddy = 0
          [
            set my-buddy myself
            set buddied? true
            ask myself [set buddied? true]
          ]
          [
            ask myself [set buddied? false]
          ]
        ]
      ]
    ]
end

to highlight-link ;; to highlight the link between two activating agents
  ask turtles [
    if (buddied? = true) AND (my-buddy != 0) [
      ask link [who] of my-buddy who [
        set color orange
        ]
    ]
  ]
end

to pick-argument ;; to set the temp arugment
  ask turtles [
    if (buddied? = true) AND (my-buddy != 0) [
      set temp-argument post-temp
      ]
  ]
end

to interact ;; to convey the opion to randomly chosen argument
  ask turtles [
    if (buddied? = true) AND (my-buddy != 0) [
      let a temp-argument
      ask my-buddy [
        set individual-ap lput a individual-ap
        ]
      ]
    ]
end

to sort-ap ;; to sort the magnitude of arguments and remove duplicate
  ask turtles [
    if  (buddied? = true) AND (my-buddy != 0) [
      set individual-ap sort-by [ [?1 ?2] -> item 1 ?1 > item 1 ?2 ] individual-ap
    ]
  ]
end

to forget ;; to forget the less persuavise argument
  ask turtles [
    if (buddied? = true) AND (my-buddy != 0) [
;      if link-neighbor? my-buddy [
      set individual-ap remove-duplicates individual-ap
      if (length individual-ap > ap-capacity) [
      set individual-ap remove-item ap-capacity individual-ap
      ]
    ]
  ]
end

to dehighlight-link ;; to recolor the link
  ask turtles [
    if (my-buddy != nobody) AND (my-buddy != 0) [
      ask link [who] of my-buddy who [
        set color white
        ]
    ]
  ]
end

to lose-buddy ;; to reset variables for next pick
  ask turtles with [not empty? my-buddies] [
    set my-buddies []
    set my-buddy 0
    set buddied? false
    set temp-argument 0
  ]
 end

to intialize-individual-ap ;; to intialize individual argument pool
  ask turtles [
    set individual-ap n-of ap-capacity argument-pool-1
    set pool-id 1
  ]
  ask n-of (tnumber * percentage / 100) turtles [
    set individual-ap n-of ap-capacity argument-pool-2
    set pool-id 2
    set shape "person business"
  ]
end

to setup-pre-temp ;; to decide the initial belief level by social compariosn at individual level
  ask turtles [
    let x []
    let x-mean 0
    set x map [ ?1 -> item 0 ?1 ] individual-ap
    set x-mean mean x
    ;set pre-temp item int random ap-capacity individual-ap
    let a item 0 individual-ap
    foreach individual-ap [ ?1 ->
      if abs (item 0 ?1 - x-mean) <= abs (item 0 a - x-mean) [
         set pre-temp ?1
      ]
    ]
  ]
end

to setup-post-temp
  ask turtles [
    set post-temp pre-temp
  ]
end

to update-compared-argument ;; to update the belief by social compariosn after every round
  ask turtles [
    let x []
    let x-mean 0
    set x map [ ?1 -> item 0 ?1 ] individual-ap
    set x-mean mean x
    let a item 0 individual-ap
    foreach individual-ap [ ?1 ->
      if abs (item 0 ?1 - x-mean) <= abs (item 0 a - x-mean) [
         set compared-argument ?1
      ]
    ]
  ]

;  ask turtles [
;    let a item 0 individual-ap
;    foreach individual-ap [
;      if item 1 ? >= item 1 a [
;         set strongest-argument ?
;      ]
;    ]
;  ]
end

to update-pre-color ;; to update color by belief level
  ask turtles [
    let a item 0 pre-temp
    ifelse a >= 6
    [set color scale-color red  a 10 6]
    [set color scale-color blue a  0 4]
  ]
  ask turtles with [item 0 pre-temp = 5] [
    set color white
  ]
end

to update-color
  ask turtles [
    let a item 0 compared-argument
    ifelse a >= 6
    [set color scale-color red  a 10 6]
    [set color scale-color blue a  0 4]
  ]
  ask turtles with [item 0 compared-argument = 5] [
    set color white
  ]
end

to pool-setup-1 ;; to setup argument-pool-1 by number of arguments in the pool
  set argument-pool-1 n-values apnumber  [n-values 2 [int random-normal 50 20]]
  let loop-step 0
  let x 0
  loop [
    set x int random-normal ap1-mean ap1-sd
    set argument-pool-1 (replace-item loop-step argument-pool-1
      (replace-item 0 (item loop-step argument-pool-1) x))

    while [x > 10 or x < 0] [set x int random-normal ap1-mean ap1-sd]
    set argument-pool-1 (replace-item loop-step argument-pool-1
      (replace-item 0 (item loop-step argument-pool-1) x))

    set loop-step loop-step + 1
    if loop-step = apnumber [stop]
  ]
end

to pool-setup-2 ;; to setup argument-pool-2 by number of arguments in the pool
  set argument-pool-2 n-values apnumber  [n-values 2 [int random-normal 50 20]]
  let loop-step 0
  let x 0
  loop [
    set x int random-normal ap2-mean ap2-sd
    set argument-pool-2 (replace-item loop-step argument-pool-2
      (replace-item 0 (item loop-step argument-pool-2) x))

    while [x > 10 or x < 0] [set x int random-normal ap2-mean ap2-sd]
    set argument-pool-2 (replace-item loop-step argument-pool-2
      (replace-item 0 (item loop-step argument-pool-2) x))

    set loop-step loop-step + 1
    if loop-step = apnumber [stop]
  ]
end

to update-initial-plot
  set temp-1 map [ ?1 -> item 0 ?1 ] argument-pool-1
  set temp-2 map [ ?1 -> item 0 ?1 ] argument-pool-2
  ask turtles [
    set pre-temp-0 item 0 pre-temp
  ]
end

to update-turtles
  ask turtles [
    set post-temp compared-argument
    set post-temp-0 item 0 compared-argument
    ]
end

to do-initial-plots
  set-current-plot "ap1-histrogram"
  histogram temp-1
  set-current-plot "ap2-histrogram"
  histogram temp-2
  set-current-plot "pre-ap-histrogram"
  histogram [pre-temp-0] of turtles
end

to calculate-shift
  let x []
  let y []
  let z []
  set x [pre-temp-0] of turtles
  set y [post-temp-0] of turtles
  (foreach x y [ [?1 ?2] -> set z fput (abs (?1 - ?2)) z ] )
  set shift (sum z)
; set shift (sum [pre-temp-0] of turtles - sum [post-temp-0] of turtles) / tnumber * 100
end


to do-plot
  set-current-plot "post-ap-histrogram"
  histogram [post-temp-0] of turtles
  ;set-current-plot "shift"
  ;plot shift
end
@#$#@#$#@
GRAPHICS-WINDOW
420
10
974
565
-1
-1
16.55
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

SLIDER
12
47
184
80
tnumber
tnumber
0
1089
1089.0
1
1
NIL
HORIZONTAL

SLIDER
12
14
184
47
apnumber
apnumber
0
1000
500.0
1
1
NIL
HORIZONTAL

BUTTON
11
125
98
158
show ap-1
show argument-pool-1
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
4
295
204
445
ap1-histrogram
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
"default" 1.0 1 -16777216 true "" ""

SLIDER
16
222
188
255
ap1-mean
ap1-mean
0
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
16
255
188
288
ap1-sd
ap1-sd
0
5
2.0
1
1
NIL
HORIZONTAL

SLIDER
218
222
390
255
ap2-mean
ap2-mean
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
218
255
390
288
ap2-sd
ap2-sd
0
5
2.0
1
1
NIL
HORIZONTAL

BUTTON
12
164
97
197
show ap-2
show argument-pool-2
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
104
123
190
156
NIL
show temp-1
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
206
295
406
445
ap2-histrogram
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
"default" 1.0 1 -16777216 true "" ""

BUTTON
102
163
192
196
NIL
show temp-2
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
9
85
75
118
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
217
79
389
112
ap-capacity
ap-capacity
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
217
47
389
80
chance-to-move
chance-to-move
0
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
148
86
211
119
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
80
85
143
118
NIL
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

SLIDER
218
15
390
48
range-of-interaction
range-of-interaction
1
3
2.0
1
1
NIL
HORIZONTAL

PLOT
206
447
406
597
post-ap-histrogram
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
"default" 1.0 1 -16777216 true "" ""

PLOT
4
447
204
597
pre-ap-histrogram
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
"default" 1.0 1 -16777216 true "" ""

SLIDER
218
133
390
166
percentage
percentage
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
199
173
267
218
turtle-id-1
count turtles with [pool-id = 1]
17
1
11

MONITOR
268
173
348
218
turtle-id-2
count turtles with [pool-id = 2]
17
1
11

MONITOR
354
172
411
217
Shift
Shift
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model aims to synthesize existing hypotheses of group polarization especially social comparison hypothesis and persuasive argument by filling the gap between verbal theorizing and simulation (Brown, 1998). Critiques from Friedkin (1999) and new ideas from the authors are also added to the models.

## HOW DOES THE BASIC MODEL WORKS?

Each agent has a limited individual argument pool to hold particular number of arguments draw from the greater pool which represent cultural preference toward a certain issue. First, an agent each takes turn to mutually exchange an argument with one un-partnered agent from the range of interaction. The interaction stops when no more exchange possible (Every agent has agent(s) in the group is partnered or unable to partnered, because every possible agents are partnered).Then, each agent updates by picking the strongest argument from the individual pool.

## HOW TO USE IT

First, you should decided the number of agents (tnumber) and number of arguments (apnumber) in the pool. Each argument is a list which contains two values (belief direction, magnitude of argument). The belief direction of larger argument pool is set by manipulating two sliders (ap1-mean and ap1-sd). Beyond the basic setting of the model, (range-of-interaction) can be decided to simulate different social distance, the (chance-to-move) are used to imitate enter or exit the group.

## THINGS TO TRY

The model is also capable to test group polarization when agents draw belief from two separated pool. (percentage) are used to determined the ratio of two population. It�s also interesting to change how many argument an agent can store in individual argument pool.

## CREDITS AND REFERENCES


Brown, Roger.�Social Psychology. 2nd ed. New York City, New York: The Free Press, 2003. 200-248. Print.
Friedkin, Noah. "Choice Shift and Group Polarization."American Sociological Review. 64. (1999): 856-875.
    Print.�
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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

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
