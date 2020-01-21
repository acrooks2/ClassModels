
globals [
  destination-patches ;; agentset of green patches standing for the tourism destination and containing visitors
  home-patches        ;; agentset of black patches containing potential visitors
  attendance          ;; the quantity of visitors at a specific time
  reputation          ;; reputation of the destination
  attraction          ;; attraction degree of the destination
]

;breed [ landscape-visitors landscape-visitor ]
;breed [ social-visitors social-visitor ]

turtles-own [
  evaluation          ;; visitor's satisfaction after visiting
  revisit-interval    ;; the interval between two times of visiting
  social?             ;; seperate visitors into social-oriented who care more about attraction of destination and landscape-oriented who care more about crowded degree
]

;;;;;;;;;;;;;;;;
;;;; setup ;;;;;
;;;;;;;;;;;;;;;;

to setup
  clear-all
  setup-environment
  setup-visitors
  reset-ticks
end

to setup-environment
  ;;create recreation destination
  set destination-patches patches with [pxcor > 30]
  ask destination-patches [set pcolor green]

  ;;create non-recreation destination
  set home-patches patches with [pxcor <= 30 ]

  set reputation 0   ;;initialize the reputation of the destination
  set attraction 300 ;;initialize the attraction of the destination
end

to setup-visitors
  ;;initialize the turtles' color, size, location and the time of first visiting
  ;;making the turtles the first bunch of potential visitors
  set-default-shape turtles "person"
  crt initial-number [
    set color white
    set size 2
    move-to-empty-one-of home-patches
    set revisit-interval random 9 + 1
  ]
  ;;initialize turtle characters as half social-oriented and half environment-oriented
  ask turtles [
    ifelse (random-float 100 < 50)
      [set social? true]
      [set social? false]
  ]


end

;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; to go ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;
to go
  tick
  ask turtles [
    ;;count backwards for the tick of visiting
    set revisit-interval revisit-interval - 1
    ifelse revisit-interval = 0
    ;; when the visiting time arrives, travel and evaluate
      [ move-to-empty-one-of destination-patches
        evaluate
        set attendance attendance + 1
        ;;an extended set of the model to see if innovaton works for extending the lifecycle of tourism destination
        ifelse (innovative?)
        ;;for the visiting of each visitor, the attraction of the destination will detoriorate by 1
        ;;the income of the destination will be used for maintaining, if 80% of the income can be used to maintain, it will make up the detorioration for one visitor
        ;;innovative measures can make 10% more attraction
        [ ifelse (ticks <= 30)
          [set attraction attraction - 1 + maintaining-rate / 100 + 0.2]
          [set attraction attraction - 1 + maintaining-rate / 100 + 0.2 + 0.1]
        ]
        [set attraction attraction - 1 + maintaining-rate / 100 + 0.2]
        ;;the second extended set of the model to see if promotion works for extending the lifecycle of tourism destination
        ;;if promotion is applied, one potential visitor is added for each tick
        if promotive? = true
        [hatch 1
         [set color white
          set size 2
          ifelse (random-float 100 < 50)
           [set social? true]
           [set social? false]
          move-to-empty-one-of home-patches
          set revisit-interval random 9 + 1]
        ]
        ;;the third extended set of the model to see if scale extension works for extending the lifecycle of tourism destination
;        if extension?
;        [ if ticks = 80
;          [set capacity capacity + 100]
;
;        ]
      ]
      [ move-to-empty-one-of home-patches ]
    set attendance count turtles-on destination-patches

    ;;initialize a list to contain the evaluations of each visitor
    let evaluation-list []
    set evaluation-list fput evaluation evaluation-list
    ;;even a visitor is satisfied every time visiting the destination, it won't revisit because of visiting too many times or some other reasons such as being an alien visitor
    let l length evaluation-list
    if l = random 9 + 1 [die]
  ]
  if extension?
   [if ticks = 70
     [set capacity capacity + 100]]
;  if extension?
;       [ let mean-list []
;          let k 10
;          set k length mean-list
;          ;;let n 1
;          set mean-list fput attendance mean-list
;          show mean mean-list
;        ]
  if count turtles = 0 [stop]

end



to evaluate
  ;;if evaluation = 3, the reputation will be enhanced by 2 and 2 more potential visitors in the same type will be added, the visitor may come back in a relatively short period
  ;;if evaluation = 2, the reputation will be enhanced by 1 and 1 more potential visitors in the same type will be added, the visitor may come back in a relatively long period
  ;;if evaluation = 1, the reputation and potential visitors will not be influenced, the visitor may come back in a very long time
  ;;if evaluation = 0, the reputation will be decreased by 1 and 1 potential visitors in the same type will be deleted, the visitor will not revisit and will be removed from the simulation
  ifelse (social? = true)
  ;;the evaluation rule of soical-oriented visitors
    [if attraction >= 250 and attendance <= 0.5 * capacity
      [set evaluation 3
       set reputation reputation + 2
       set revisit-interval random 4
       hatch 2
         [set color white
          set size 2
          set social? true
          move-to-empty-one-of home-patches
          set revisit-interval random 9 + 1]
       ]
     if attraction >= 250 and attendance > 0.5 * capacity and attendance < capacity
      [set evaluation 2
       set reputation reputation + 1
       set revisit-interval random 8
       hatch 1
         [set color white
          set size 2
          set social? true
          move-to-empty-one-of home-patches
          set revisit-interval random 9 + 1]
        ]
     if attraction <= 250 and attraction > 50 and attendance <= 0.5 * capacity
      [set evaluation 1
       set revisit-interval random 30]
;     if attraction < 50
;      [ set evaluation 0
;       set reputation reputation - 2
;       die
;       let x one-of turtles with [ social? = true ]
;       ask x [die]
;      ]
     if attraction <= 250 and attraction > 50 and attendance > 0.5 * capacity and attendance < capacity
      [set evaluation 1
       set revisit-interval random 30
        ]
     if attendance >= capacity
      [ set evaluation 0
       set reputation reputation - 2
       die
       let x one-of turtles with [ social? = true ]
       ask x [die]
      ]
     if attraction <= 50
      [ set evaluation 0
       set reputation reputation - 2
       die
       let x one-of turtles with [ social? = true ]
       ask x [die]
      ]
    ]

    ;;the evaluation rules of environment-oriented visitors
    [if attraction >= 250 and attendance <= 0.5 * capacity
      [set evaluation 3
       set reputation reputation + 2
       set revisit-interval random 4
       hatch 2
         [set color white
          set size 2
          set social? false
          move-to-empty-one-of home-patches
          set revisit-interval random 9 + 1]
       ]
     if attraction >= 250 and attendance > 0.5 * capacity and attendance < 0.8 * capacity
      [set evaluation 1
       set revisit-interval random 30]
     if attendance >= 0.8 * capacity
      [ set evaluation 0
       set reputation reputation - 2
       die
       let x one-of turtles with [social? = false]
       ask x [die]
      ]
     if attraction <= 250 and attraction > 0 and attendance <= 0.5 * capacity
      [set evaluation 2
       set reputation reputation + 1
       set revisit-interval random 8
       hatch 1
         [set color white
          set size 2
          set social? false
          move-to-empty-one-of home-patches
          set revisit-interval random 9 + 1]
        ]
     if attraction <= 250 and attendance > 0.5 * capacity and attraction > 0 and attendance < 0.8 * capacity
      [set evaluation 1
       set revisit-interval random 30
      ]
     if attraction <= 0
      [set evaluation 0
       set reputation reputation - 2
       die
       let x one-of turtles with [social? = false]
       ask x [die]
      ]
     ]

end

to move-to-empty-one-of [locations]
  move-to one-of locations
  while [any? other turtles-here] [
    move-to one-of locations
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
237
8
1372
444
-1
-1
7.0
1
10
1
1
1
0
1
1
1
-80
80
-30
30
0
0
1
ticks
30.0

BUTTON
12
26
78
59
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
121
25
184
58
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
12
72
184
105
maintaining-rate
maintaining-rate
0
100
80.0
10
1
%
HORIZONTAL

SWITCH
12
200
141
233
innovative?
innovative?
1
1
-1000

SLIDER
12
112
184
145
initial-number
initial-number
0
100
30.0
10
1
NIL
HORIZONTAL

PLOT
12
288
212
438
Attendance
time
people
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"attendance" 1.0 0 -16777216 true "" "plotxy ticks attendance"

SLIDER
12
154
184
187
capacity
capacity
0
1000
410.0
10
1
NIL
HORIZONTAL

MONITOR
160
195
233
240
attraction
attraction
10
1
11

MONITOR
160
241
238
286
reputation
reputation
17
1
11

SWITCH
13
243
141
276
promotive?
promotive?
1
1
-1000

PLOT
12
440
212
590
Potential-visitors
time
people
0.0
10.0
0.0
10.0
true
false
"plot initial-number" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [xcor <= 30]"

SWITCH
242
478
366
511
extension?
extension?
1
1
-1000

MONITOR
243
521
324
566
attendance
attendance
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is an agent-based model on the famous tourism lifecycle theory of Bulter's. As the amount of arrivals in a destination is one of the most intuitional measures to see the prosperous of the destination, this model tries to simulate in the demand side of tourism, dealing with the changes in attendance to see if the improving procedure of a destination complies the lifecycle theory. 

## HOW IT WORKS

The basic of this model is an evaluation mechanism that pushes the dynamics in the whole system including the change in potential visitors, revisit rate of visitors and the revisit interval of each agent. Attendance number of each time is plotted to see if that complies tourism lifecycle theory.

## HOW TO USE IT

The slider of maintaining rate changes the percentage of cover on the deterioration of visitors' attending. Initial number slider can change the innitial number of potential visitors when setup the model. Capacity slider changes the capacity of the destination, which is a limitation on number of attendance and will change visitors' experience.
Different strategies such as innovative, promotive and extension can be set by set on the switches.

## THINGS TO NOTICE

Notice the changes in attendance and potential visitors, observe the trends of curves in different set of parameters. Also pay attention to the reputation, which is influenced by the satisfactory of visitors.


## EXTENDING THE MODEL

Add economic factors which is an influential thing for market, such as income of people and set the correlation between income and choices of visiting according to real data, to see how economic factors can influence the lifecycle of destinations.



## CREDITS AND REFERENCES

Arthur, W. B. (1994). Inductive reasoning and bounded rationality. The American economic review, 406-411.

Butler, R. W. (1980). The concept of a tourist area cycle of evolution: implications for management of resources. The Canadian Geographer/Le Géographe canadien, 24(1), 5-12.

Rand, W. and Wilensky, U. (2007). NetLogo El Farol model. http://ccl.northwestern.edu/netlogo/models/ElFarol. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 
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
