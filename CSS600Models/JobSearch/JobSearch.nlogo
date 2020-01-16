;a simple model of job search and unemployment benefits

Globals [
minimumWage
UI
productivity
priceofgoods
unemploymentrate-list
]


breed [firms firm]
breed [workers worker]
directed-link-breed [jobs job]
links-own [wage]

firms-own [hiring? maxValue numberofworkers numberofjobs wageoffer lastwageoffer profit periodsofloss]
workers-own [reservationWage timeUnemployed employed? currentwage previouswage moneyinthebank firmoffer UIbenefit]

to setup ; initialize workers and firms, set shape of the agents and spread them
         ; throughout the x y space. set firm shape and size based on numberofworkers
         ; initialize reservationWage values over interval [c,maxWage], where c
         ; where c is ifelse function of a constant, or unemployment benefit minimum
         ; initialize wageoffer values over interval [minWageOffer,maxWage]
         ; where minWageOffer is either 0 or minimum wage level set by government
clear-all
  ;Globals
  set unemploymentrate-list []
  set minimumWage minwage

  set UI unemploymentInsurance
  set productivity 2
  set priceofgoods 10

  create-firms NumberofFirms [
    setxy random 32 random 32
    set shape "square"
    set size 1
    set color yellow
    set maxValue (minimumWage + random (50))
    set numberofworkers 1
    set numberofjobs 1
    set wageoffer 0
    set lastwageoffer 0
    set hiring? true
    set periodsofloss 0
  ]

  create-workers LaborForce [
    setxy random 32 random 32
    set shape "person"
    set size .75
    set color green
    set reservationWage random (50)
    set employed? false
    set previouswage 0
    set moneyinthebank 0
    set UIbenefit UI
  ]

reset-ticks
end

to go
  do-jobmatch ; the main function of job search with wage contracts
  calculate-profit ; this block calculates profit and 'kills' firms or grows firms
  collect-benefits; provides unemployment insurance to unmatched workers
  job-destruction; we will have the option of randomly destroying links
  calc-unemployment; update graph of unemployment rate, number of firms, wage statistics
  tick
  if ticks > 2000 [stop]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to do-jobmatch
  ask workers with [not any? my-links][
    ifelse employed? = false [ ;            trying to do this for all employees
      let candidatefirms firms in-radius 5 with [hiring? = true]
      ifelse any? candidatefirms [
        let targetfirm min-one-of candidatefirms [distance myself]
        move-to targetfirm
        set firmOffer [maxValue] of one-of firms-here ; one-of firms-here
        ifelse firmOffer > reservationWage [
          set currentwage firmOffer
          ifelse currentwage >= UIBenefit [
              create-job-to one-of firms-here[ set hidden? true] ;WHY CAN"T I SET link.wage = wageoffer??
              set employed? true
            set timeunemployed 0
              ask one-of firms-here [
                set numberofworkers count my-links
                set size 1 + (numberofworkers / 100)
                set wageoffer [currentwage] of myself ]
      ]
        [ set employed? false
          set currentwage UIBenefit
          set color red
          set timeunemployed timeunemployed + 1
        ]
      ]
       [
        set employed? false
        set currentwage UI
        set color red
        set timeunemployed timeunemployed + 1
    ]
  ]
    [face one-of other firms
      fd 1]
  ]
    [set previouswage currentwage
      set moneyinthebank moneyinthebank + previouswage
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to calculate-profit
  ask firms [
    let totalcost  numberofworkers * wageoffer
    let output  numberofworkers * productivity
    set profit  (output * priceofgoods) - totalcost
  ifelse profit < 0 [
      ifelse maxValue > minimumWage [set maxValue maxValue - 1] [set maxValue minimumWage] ; reduce wage offer
      set periodsofloss periodsofloss + 1
    ]
    [set periodsofloss 0]
    if periodsofloss >= 10 [
      die]
    ;ifelse numberofworkers > 100 [set hiring? false] [set hiring? true]
  ]

  histogram [profit] of firms
  histogram [numberofworkers] of firms
  histogram [timeunemployed] of workers
end



;;;;;;;;;;;;;;;;;
to collect-benefits
  ask workers with [employed? = false] [
    ifelse timeunemployed < 10
    [ set UIbenefit UI]
  [set UIbenefit 0]
]
end


;;;;;;;;;;;;;;;;;;;;;;;;
to job-destruction
  let %d jobdestructionrate ; where 10% is the job destruction rate
  let n count jobs
  ask (n-of (%d * n) jobs) [die]
  ask workers with [not any? my-links]
  [set employed? false]

  if count firms < 10 [
    create-firms 3 [
    setxy random 32 random 32
    set shape "square"
    set size 1
    set color yellow
    set maxValue (minimumWage + random-float (40))
    set numberofworkers 0
    set numberofjobs 0
    set wageoffer 0
    set lastwageoffer 0
    set hiring? true
    set periodsofloss 0
      ]
  ]

end

to calc-unemployment
  let currentUnemploymentRate 0
  let avg-unemployment 0
  let a count workers with [employed? = false]
  let b count workers
  set currentUnemploymentRate (a / b)
  set unemploymentrate-list lput (count workers with [employed? = false] / (count workers)) unemploymentrate-list
  set avg-unemployment (mean unemploymentrate-list)

  ;let unemploymentrate  ((count workers with [employed? = false])/(count workers))

  ;let unemploymentspell max (timeunemployed)
  ;let averagewage mean (wageoffer)

end


;  in the first iteration of this model we are going to keep it simple:
;     we will not update unemployment insurance to reflect people's last wage
;     we will also not have firms update their wageoffer downward after a success or
;       upward following unsuccess
;     we will allow firm growth to be unlimited, and have firms be able to die, but not
;        be born
;     we will have a switch to have on random job destruction
;     we will not have agents decide whether or not they want to work based on
;        money in the bank
@#$#@#$#@
GRAPHICS-WINDOW
210
10
548
349
-1
-1
10.0
1
8
1
1
1
0
1
1
1
0
32
0
32
1
1
1
ticks
30.0

SLIDER
36
11
208
44
LaborForce
LaborForce
0
1000
500.0
1
1
NIL
HORIZONTAL

BUTTON
5
90
68
123
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

SLIDER
36
51
208
84
NumberOfFirms
NumberOfFirms
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
145
90
208
123
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

INPUTBOX
578
19
733
79
jobdestructionrate
0.05
1
0
Number

BUTTON
75
90
138
123
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
584
128
924
278
Unemployment Rate
ticks
unemployment rate
0.0
2000.0
0.0
0.9
false
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count workers with [employed? = false] / (count workers))"

SLIDER
735
20
907
53
MinWage
MinWage
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
735
55
921
88
unemploymentInsurance
unemploymentInsurance
0
50
20.0
1
1
NIL
HORIZONTAL

MONITOR
5
150
98
195
average wage
mean [currentwage] of workers with [employed? = true]
3
1
11

MONITOR
100
150
205
195
employed number
count workers with [employed? = true]
17
1
11

MONITOR
5
255
147
300
max wage offer by firm
max [maxValue] of firms
3
1
11

MONITOR
5
360
94
405
count of firms
count firms
17
1
11

PLOT
585
290
925
440
histogram
NIL
NIL
0.0
101.0
0.0
111.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [timeunemployed] of workers"

MONITOR
5
310
140
355
Lowest Firm Wage Offer
min [maxValue] of firms
3
1
11

MONITOR
100
360
212
405
size of largest firm
max [numberofworkers] of firms
2
1
11

MONITOR
5
205
100
250
Mean Unemployment Spell
mean [timeunemployed] of workers
3
1
11

MONITOR
110
205
205
250
max unemployment spell
max [timeunemployed] of workers
17
1
11

MONITOR
230
360
292
405
sd unemp
standard-deviation unemploymentrate-list
3
1
11

MONITOR
310
360
382
405
avg unemp
mean  unemploymentrate-list
3
1
11

@#$#@#$#@
## WHAT IS IT?

This is a simple model of job search and unemployment dynamics using zero intelligence agents. 

## HOW IT WORKS

Two main types of agents in this model: workers and firms. 
Workers - these agents are created and assigned a random value from a uniform distribution that is their reservation wage.
Firms - these agents are created and assigned a random value (maxValue) from a uniform distribution that they are willing to pay for labor. Firms use exogenous variables price and labor productivity to create and sell output. Firms keep track of their profits, positive or negative.

Every period, unemployed workers move to their nearest firm. If the wage offer of the firm exceeds the worker's reservation wage, and exceeds the unemployment benefit and the minimum wage, the worker will accept the offer and take the job. If the wage offer does not exceed this amount, the worker continues her search to another nearby firm. If no firm is nearby, they locate the nearest firm and move towards it while collecting unemployment benefits if any.

Firms calculate their profit every period. If they have negative profits, they reduce their wage offer by $1 in order to reduce costs. After 10 consecutive periods of negative profits, the firm dies.

Every period a percentage of jobs are randomly destroyed, leading to another job search of previously employed workers. 

If there are fewer than 10 firms at any point, new firms are created. There is no maximum number of workers any one firm may hire.

## HOW TO USE IT

Choose the numebr of workers and number of firms, along with the job destruction rate, the minimum wage, and unemployment benefits. Click Setup and then Go (forever). The simulation ends after 2000 iterations.

## THINGS TO NOTICE

Watch the monitors to see the average wage offer of workers with jobs, the number of firms that remain, and the largest firm size. The plots also show the unemployment rate over time, as well as a historgram of the length of unemployment spells experienced by workers. 

## THINGS TO TRY

Adjust the minimum wage and the unemployment benefit to isolate the effect of these policies on the unemployment rate and firm sizes. 

## EXTENDING THE MODEL

Too many to list here, but see the accompanying paper. 

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
  <experiment name="baseline" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean [currentwage] of workers with [employed? = TRUE]</metric>
    <metric>min [maxValue] of firms</metric>
    <metric>max [numberofworkers] of firms</metric>
    <metric>count firms</metric>
    <metric>mean unemploymentrate-list</metric>
    <metric>standard-deviation unemploymentrate-list</metric>
    <metric>mean [timeunemployed] of workers</metric>
    <enumeratedValueSet variable="jobdestructionrate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemploymentInsurance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfFirms">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MinWage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LaborForce">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VaryingMinWage" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean [currentwage] of workers with [employed? = TRUE]</metric>
    <metric>min [maxValue] of firms</metric>
    <metric>max [numberofworkers] of firms</metric>
    <metric>count firms</metric>
    <metric>mean unemploymentrate-list</metric>
    <metric>standard-deviation unemploymentrate-list</metric>
    <metric>mean [timeunemployed] of workers</metric>
    <enumeratedValueSet variable="jobdestructionrate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemploymentInsurance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfFirms">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MinWage">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
      <value value="15"/>
      <value value="20"/>
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LaborForce">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VaryingMinWage" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean [currentwage] of workers with [employed? = TRUE]</metric>
    <metric>min [maxValue] of firms</metric>
    <metric>max [numberofworkers] of firms</metric>
    <metric>count firms</metric>
    <metric>mean unemploymentrate-list</metric>
    <metric>standard-deviation unemploymentrate-list</metric>
    <metric>mean [timeunemployed] of workers</metric>
    <enumeratedValueSet variable="jobdestructionrate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemploymentInsurance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfFirms">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MinWage">
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LaborForce">
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="VaryingMinWage" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>mean [currentwage] of workers with [employed? = TRUE]</metric>
    <metric>min [maxValue] of firms</metric>
    <metric>max [numberofworkers] of firms</metric>
    <metric>count firms</metric>
    <metric>mean unemploymentrate-list</metric>
    <metric>standard-deviation unemploymentrate-list</metric>
    <metric>mean [timeunemployed] of workers</metric>
    <enumeratedValueSet variable="jobdestructionrate">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemploymentInsurance">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfFirms">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="MinWage">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="LaborForce">
      <value value="500"/>
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
1
@#$#@#$#@
