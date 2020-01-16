turtles-own [ pop schl hlth u1 u2 u3 u4 u5 feasible-towns ]
patches-own [ gpop gschl ghlth ]
globals [utility]

to setup
  clear-all
  (ifelse
  towns = 5 [ setup-5towns ]
  towns = 3 [ setup-3towns ]
  [ setup-1town ])
  reset-ticks
end

to setup-5towns
  ;
  create-turtles population / 5 [
    setting
    setxy 5 0
  ]
  create-turtles population / 5 [
    setting
    setxy -5 0
  ]
  create-turtles population / 5 [
    setting
    setxy 0 5
  ]
  create-turtles population / 5 [
    setting
    setxy 0 -5
  ]
  create-turtles population / 5 [
    setting
    setxy 0 0
  ]
end

to setup-3towns
  create-turtles population / 3 [
    setting
    setxy 5 0
  ]
  create-turtles population / 3 [
    setting
    setxy -5 0
  ]
  create-turtles population / 3 [
    setting
    setxy 0 5
  ]
end

to setup-1town
  create-turtles population [
    setting
    setxy 5 0
  ]
end

to setting
    set color blue
    set size 2.0
    set shape "person"
    set pop one-of (range 1 11)
    set schl one-of (range 1 11)
    set hlth one-of (range 1 11)
end

to go
  if ticks > 60 [stop]
  elect
  calculate
  check-barrier
  migrate
  social-utility
  tick
end

to elect
  if towns > 0 [
    ask patch 5 0 [
      ifelse count turtles-on patch 5 0 > 0 [
      set gpop median [pop] of turtles-on patch 5 0
      set gschl median [schl] of turtles-on patch 5 0
      set ghlth median [hlth] of turtles-on patch 5 0
      ]
      [ empty-town ]
    ]
  ]
  if towns > 2 [
    ask patch 0 5 [
      ifelse count turtles-on patch 0 5 > 0 [
      set gpop median [pop] of turtles-on patch 0 5
      set gschl median [schl] of turtles-on patch 0 5
      set ghlth median [hlth] of turtles-on patch 0 5
      ]
      [ empty-town ]
    ]
    ask patch -5 0 [
      ifelse count turtles-on patch -5 0 > 0 [
      set gpop median [pop] of turtles-on patch -5 0
      set gschl median [schl] of turtles-on patch -5 0
      set ghlth median [hlth] of turtles-on patch -5 0
      ]
      [ empty-town ]
    ]
  ]
  if towns > 4 [
    ask patch 0 -5 [
      ifelse count turtles-on patch 0 -5 > 0 [
      set gpop median [pop] of turtles-on patch 0 -5
      set gschl median [schl] of turtles-on patch 0 -5
      set ghlth median [hlth] of turtles-on patch 0 -5
      ]
      [ empty-town ]
    ]
    ask patch 0 0 [
     ifelse count turtles-on patch 0 0 > 0 [
      set gpop median [pop] of turtles-on patch 0 0
      set gschl median [schl] of turtles-on patch 0 0
      set ghlth median [hlth] of turtles-on patch 0 0
      ]
      [ empty-town ]
    ]
  ]
end

to empty-town
;When towns are empty, they have no public goods nor entry barriers.
    set gpop 1
    set gschl 0
    set ghlth 0
end

to calculate
  ask turtles [
    let up1 (count turtles-on patch 5 0 / 100 - pop) ^ 2
    let us1 ([gschl] of patch 5 0 - schl) ^ 2
    let uh1 ([ghlth] of patch 5 0 - hlth) ^ 2
    set u1 ( up1 + us1 + uh1 ) ^ 0.5

    let up2 (count turtles-on patch 0 5 / 100 - pop) ^ 2
    let us2 ([gschl] of patch 0 5 - schl) ^ 2
    let uh2 ([ghlth] of patch 0 5 - hlth) ^ 2
    set u2 ( up2 + us2 + uh2 ) ^ 0.5

    let up3 (count turtles-on patch -5 0 / 100 - pop ) ^ 2
    let us3 ([gschl] of patch -5 0 - schl) ^ 2
    let uh3 ([ghlth] of patch -5 0 - hlth) ^ 2
    set u3 ( up3 + us3 + uh3 ) ^ 0.5

    let up4 (count turtles-on patch 0 -5 / 100 - pop) ^ 2
    let us4 ([gschl] of patch 0 -5 - schl) ^ 2
    let uh4 ([ghlth] of patch 0 -5 - hlth) ^ 2
    set u4 ( up4 + us4 + uh4 ) ^ 0.5

    let up5 (count turtles-on patch 0 0 / 100 - pop) ^ 2
    let us5 ([gschl] of patch 0 0 - schl) ^ 2
    let uh5 ([ghlth] of patch 0 0 - hlth) ^ 2
    set u5 ( up5 + us5 + uh5 ) ^ 0.5
  ]
end

to check-barrier
  ask turtles [
    ( ifelse
        towns = 1 [ set feasible-towns [] ]
        towns = 3 [ set feasible-towns (list u1 u2 u3) ]
        [set feasible-towns (list u1 u2 u3 u4 u5)]
    )
  ]
  if Endogenous-Barrier [
    ;let denominator sum [gpop] of patches
    let p1 count turtles-on patch 5 0
    let p2 count turtles-on patch 0 5
    let p3 count turtles-on patch -5 0
    let p4 count turtles-on patch 0 -5
    let p5 count turtles-on patch 0 0
    if towns > 0 [
      ask turtles [
        set feasible-towns []
        let barrier-1 100 * [gpop] of patch 5 0
        let barrier-2 100 * [gpop] of patch 0 5
        let barrier-3 100 * [gpop] of patch -5 0
        if barrier-1 > p1 [set feasible-towns lput u1 feasible-towns ]
        if barrier-2 > p2 [set feasible-towns lput u2 feasible-towns ]
        if barrier-3 > p3 [set feasible-towns lput u3 feasible-towns ]
      ]
    ]
    if towns > 4 [
      ask turtles [
        let barrier-4 100 * [gpop] of patch 0 -5
        let barrier-5 100 * [gpop] of patch 0 0
        if barrier-4 > p4 [set feasible-towns lput u4 feasible-towns ]
        if barrier-5 > p5 [set feasible-towns lput u5 feasible-towns ]
      ]
    ]
  ]
end


to migrate
  ask turtles-on patch 5 0 [
    ifelse feasible-towns = []
    [ move-to patch 5 0 ]
    [
      set feasible-towns lput u1 feasible-towns
      let next min feasible-towns
      (ifelse
        next = u1 [ move-to patch 5 0 ]
        next = u2 [ move-to patch 0 5 ]
        next = u3 [ move-to patch -5 0 ]
        next = u4 [ move-to patch 0 -5 ]
        next = u5 [ move-to patch 0 0 ]
      )
    ]
  ]

  ask turtles-on patch 0 5 [
    ifelse feasible-towns = []
    [ move-to patch 0 5 ]
    [
      set feasible-towns lput u2 feasible-towns
      let next min feasible-towns
      (ifelse
        next = u2 [ move-to patch 0 5 ]
        next = u1 [ move-to patch 5 0 ]
        next = u3 [ move-to patch -5 0 ]
        next = u4 [ move-to patch 0 -5 ]
        next = u5 [ move-to patch 0 0 ]
      )
    ]
  ]

  ask turtles-on patch -5 0 [
    ifelse feasible-towns = []
    [ move-to patch -5 0 ]
    [
      set feasible-towns lput u3 feasible-towns
      let next min feasible-towns
      (ifelse
        next = u3 [ move-to patch -5 0 ]
        next = u1 [ move-to patch 5 0 ]
        next = u2 [ move-to patch 0 5 ]
        next = u4 [ move-to patch 0 -5 ]
        next = u5 [ move-to patch 0 0 ]
      )
    ]
  ]

  ask turtles-on patch 0 -5 [
    ifelse feasible-towns = []
    [ move-to patch 0 -5 ]
    [
      set feasible-towns lput u4 feasible-towns
      let next min feasible-towns
      (ifelse
        next = u4 [ move-to patch 0 -5 ]
        next = u1 [ move-to patch 5 0 ]
        next = u2 [ move-to patch 0 5 ]
        next = u3 [ move-to patch -5 0 ]
        next = u5 [ move-to patch 0 0 ]
      )
    ]
  ]

  ask turtles-on patch 0 0 [
    ifelse feasible-towns = []
    [ move-to patch 0 0 ]
    [
      set feasible-towns lput u5 feasible-towns
      let next min feasible-towns
      (ifelse
        next = u5 [ move-to patch 0 0 ]
        next = u1 [ move-to patch 5 0 ]
        next = u2 [ move-to patch 0 5 ]
        next = u3 [ move-to patch -5 0 ]
        next = u4 [ move-to patch 0 -5 ]
      )
    ]
  ]
end

to social-utility
  let u11 sum [u1] of turtles-on patch 5 0
  let u22 sum [u2] of turtles-on patch 0 5
  let u33 sum [u3] of turtles-on patch -5 0
  let u44 sum [u4] of turtles-on patch 0 -5
  let u55 sum [u5] of turtles-on patch 0 0
  set utility (u11 + u22 + u33 + u44 + u55) / population
end
@#$#@#$#@
GRAPHICS-WINDOW
218
24
381
188
-1
-1
4.7
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
24
22
87
55
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
106
22
169
55
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
23
68
169
101
population
population
0
5000
1200.0
100
1
NIL
HORIZONTAL

PLOT
21
202
381
444
Population
time
population
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Town 1" 1.0 0 -16777216 true "" "plot count turtles-on patch 5 0"
"Town 2" 1.0 0 -7500403 true "" "plot count turtles-on patch 0 5"
"Town 3" 1.0 0 -2674135 true "" "plot count turtles-on patch -5 0"
"Town 4" 1.0 0 -955883 true "" "plot count turtles-on patch 0 -5"
"Town 5" 1.0 0 -6459832 true "" "plot count turtles-on patch 0 0"

SWITCH
23
108
191
141
Endogenous-Barrier
Endogenous-Barrier
1
1
-1000

PLOT
389
202
711
444
Barrier
time
population
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Barrier 1" 1.0 0 -16777216 true "" "plot [gpop] of patch 5 0 * 100"
"Barrier 2" 1.0 0 -7500403 true "" "plot [gpop] of patch 0 5 * 100"
"Barrier 3" 1.0 0 -2674135 true "" "plot [gpop] of patch -5 0 * 100"
"Barrier 4" 1.0 0 -955883 true "" "plot [gpop] of patch 0 -5 * 100"
"Barrier 5" 1.0 0 -6459832 true "" "plot [gpop] of patch 0 0 * 100"

MONITOR
397
138
503
183
NIL
utility
17
1
11

CHOOSER
23
146
161
191
Towns
Towns
1 3 5
2

PLOT
720
203
1064
449
Population / Barrier
NIL
Population / Barrier
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"P-B Town 1" 1.0 0 -16777216 true "" "plot count turtles-on patch 5 0 / ( [gpop] of patch 5 0 * 100 )"
"P-B Town 2" 1.0 0 -7500403 true "" "plot count turtles-on patch 0 5 / 100 / [gpop] of patch 0 5"
"P-B Town 3" 1.0 0 -2674135 true "" "plot count turtles-on patch -5 0 / 100 / [gpop] of patch -5 0"
"P-B Town 4" 1.0 0 -955883 true "" "plot count turtles-on patch 0 -5 / 100 / [gpop] of patch 0 -5"
"P-B Town 5" 1.0 0 -6459832 true "" "plot count turtles-on patch 0 0 / 100 / [gpop] of patch 0 0"

@#$#@#$#@
## WHAT IS IT?

This is a Tiebout's model that examplify the idea of club good. People will see population size of town as a variable to decide where to live. Thus, migration barriers will endogenously emerge without assuming transportation cost. 

I use this model to analyze the welfare implication of this migraiton barrier in Tiebout's model. The whole mechanism is similar with the Tiebout's model by [Kollman et al. (1997)](https://www.jstor.org/stable/2951336?seq=1)

## HOW IT WORKS
Before you setup the model, the overall popualtion and the number of towns must be specified. Those will not change after running the model. Initially, the population will be evenly distributed to each town, for instance, if you choose 500 turtles and 5 towns, each town will start with 100 residents. 

These residents have their unique preference value (utility-optimazied bundle) on population size, quantity of school, and qunatity of hospital. The values are uniformly random from 1 to 10. They migrate to the town which has closest bundle to their optimal bundle. For indivudal _i_, he will migrate to town _m_ which minimize the following equation,

(cpm/100 - pi)^2 + (sm - si)^2 + (hm - hi)^2

where pi, si, and hi is his/her favorite population size, quantity of school and quantity of hospital respectively. cpm is the population of town _m_. pm, sm, and hm are the median values of pi, si and hi for all individuals who currently live in town _m_. It also implies a democratic governments in all towns. sm and hm could be interpreted as the actual implemented public goods in town _m_. 

pm is the migration barrier. When you turn on the barrier, for any indivudal, s/he could only migrate to the towns where cpm < pm; but s/he can always stay in his/her current town anyway.

In each tick, the government moves first, that is, implementing public goods (median values). Then all agents calculate the feasible best destination and migrate. After all agents settle down, the model enter next tick.

## HOW TO USE IT

For detect my research resutls, you should setup the model as what I highlight in my paper (where I also give the reasons). Click go, the model will run until 61 tick. Usually it will reach a equilibrium before 30 ticks. You could see this from the population diagram.

Then you can document the number in the monitor of utility. The utility is the average of all individuals' utilities - a square root of the equation shown in the previous section. It represents the social welfare.

For other purposes, You can set any population and town, open or close the migration barrier as you wish. It's better to set the popualtion that could be divided by towns. :)

## THINGS TO NOTICE

The barrier diagram shows the population barrier in each town throughout ticks. The line in population/barrier diagram could be interpreted as whether there exists effective migration barriers (cpm > pm) now. If the number is bigger than one, it is effective, vice versa.  

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
