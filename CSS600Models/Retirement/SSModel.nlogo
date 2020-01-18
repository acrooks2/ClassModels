;;;Agent Based Model of the Dynamics of the Social Security Trust Fund

;;There are two types of turtles in this world. They are either workers or retirees.
breed [workers worker]
breed [retirees retiree]

;;This is where the aggregate values of the trust fund and
;;number of workers and retirees are stored.
globals [
  tf-balance  ;; the amount of money in the Social Security Trust Fund
  current-workers  ;; the number of current workers
  current-retirees ;; the number of current retirees
  total-population ;; the total number of workers AND retirees
  worker-retiree-ratio ;; the ratio of current workers to current retirees
]

turtles-own [
  age ;; how old the turtle is
  working-income ;; how much a workers gets in income
  retire-inclination ;;the random variable used to determine how a person decides to retire
  income-distribution-random ;;the random variable used to determine the income group a turtle gets put in
  retirees-nearby ;; the number of neighbors that are retirees
  workers-nearby ;; the number of neighbors that are workers
  total-nearby ;; the sum of retirees-nearby and workers-nearby
  above? ;; a boolean that is true if the ratio of retirees to the total neighbors is above a certain threshold
  should-I-retire ;;a random variable used to decide if a "random" retiree will retire in the current period
  chance-to-die  ;;a random variable used for deciding if a turtle will die
]

to setup
  ca
  create-workers (initial-number-of-workers)
  [
    set age 20 + random 45 ;; this gives every one of the initial number of workers
                           ;; their own age somewhere between 20 and 64 years old
    set color green        ;; all workers are green
    setxy age random-ycor  ;; all workers move across the visualization as they age
  ]
  create-retirees (initial-number-of-retirees)
  [
    set age 65 + random 21     ;; this gives every one of the initial number of workers
                               ;; their own age somewhere betwen 65 and 85
    set color orange           ;; all retirees are colored orange
    setxy age random-ycor      ;; all workers move across the visualization as they age
  ]
  set-default-shape turtles "person"
  ask turtles [
    set retire-inclination random 99                ;; this variable is a random number in the range 0 - 99.  it is used to assign the method with which a worker will decide to retire
    set income-distribution-random random 99        ;; this variable is a random number in the range 0 - 99.  it is used to assign the income distribution
    set-working-income                              ;; this call the method that assigns the workers income
    set above? false
    set chance-to-die random-float 1.00
  ]
  reset-ticks
end

to go
  ;; Workers go first
  ;; Retirees go second
  ask turtles [
        if (color = red) [
      set color orange]        ;;this turns the color of the retirees that retired in the last period to orange so all retirees are orange
  ]
  ask workers [
    pay-ss
    set age age + 1
    decide-if-retire
    move
    grim-reaper
  ]
  ask retirees [
    get-benefits
    set age age + 1
    move
    grim-reaper
  ]

update-total-population
if total-population = 0 [stop]
if tf-balance <= 0 [stop]
update-ratio
create-new-generation



  tick
end

to pay-ss  ;; each workers adds a percentage of their income to Social Security (up to a user decided threshold)
  ifelse working-income > SS-Tax-Limit [
    set tf-balance (SS-Tax-Limit * total-SS-tax-rate + tf-balance)] [   ;; The SS-Tax-Limit is the threshold above which SS taxes are not deducted
  set tf-balance (working-income * total-SS-tax-rate + tf-balance)
    ]
end

to get-benefits      ;; this pays a benefit for a retiree that is equal to the average yearly Social Security benefit
  set tf-balance (tf-balance - yearly-SS-benefit)
end

to move
  set xcor age
end

to grim-reaper
  if age >= 65 AND age < 100 AND (random-float 1.00 < .03) [
   die]
  if age = 100 [
    die

  ]

end

to decide-if-retire
  rational-retire  ;;workers retire at the earliest legal age (set at 65 in this model)
  imitate-retire   ;;workers check their social network and retire if the ratio of retirees to workers is above a certain threshold
  random-retire    ;;workers retire with 50/50 probability each tick after reaching the age of 65


end

to rational-retire
  if age >= 65 AND retire-inclination <= 14 [
    set breed retirees
    set color red
  ]
end

to imitate-retire
  if (age >= 65) AND (retire-inclination > 14 AND retire-inclination <= 94) [
   check-social-network
  ]
  if above? [
    set breed retirees
    set color red
  ]
end

to check-social-network
    ;; in next two lines, we use "neighbors" to test the eight patches
    ;; surrounding the current patch
    set retirees-nearby count (turtles-on neighbors)
      with [color = orange]
    set workers-nearby count (turtles-on neighbors)
      with [color = green]
    set total-nearby retirees-nearby + workers-nearby

    ifelse retirees-nearby >= ( retirement-threshold * total-nearby )
    [set above? true] [set above? false]


end

to random-retire
  if age >= 65 AND (retire-inclination > 94 AND retire-inclination <= 99) [
    set should-I-retire random 99
  ]
  if should-I-retire > 49 [
    set breed retirees
    set color red
  ]
end

;;this part sets up the income distribution in the model;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-working-income                                                                          ;
  high-test                                                                                    ;
  four-test                                                                                    ;
  three-test                                                                                   ;
  two-test                                                                                     ;
  one-test                                                                                     ;
end                                                                                            ;
                                                                                               ;
                                                                                               ;
to high-test                                                                                   ;
  if income-distribution-random <= 4 [                                                         ;
    set working-income 200000                                                                  ;
  ]                                                                                            ;
end                                                                                            ;
                                                                                               ;
to four-test                                                                                   ;
  if income-distribution-random > 4 AND income-distribution-random <= 22 [                     ;
    set working-income 150000                                                                  ;
  ]                                                                                            ;
end                                                                                            ;
                                                                                               ;
to three-test                                                                                  ;
  if income-distribution-random > 22 AND income-distribution-random <= 52 [                    ;
    set working-income 75000                                                                   ;
  ]                                                                                            ;
end                                                                                            ;
                                                                                               ;
to two-test                                                                                    ;
  if income-distribution-random > 52 AND income-distribution-random <= 76 [                    ;
    set working-income 37500                                                                   ;
  ]                                                                                            ;
end                                                                                            ;
                                                                                               ;
to one-test                                                                                    ;
  if income-distribution-random > 76 AND income-distribution-random <= 99 [                    ;
    set working-income 12500                                                                   ;
  ]                                                                                            ;
end                                                                                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;This is the code to create a new generation of workers that is "born" at a certain rate
to create-new-generation
  create-workers (pop-growth-rate * total-population) [

    set age 20 ;; this gives every one of the initial number of workers
               ;; their own age somewhere between 20 and 64 years old
    set color green        ;; all workers are green
    setxy age random-ycor
        set retire-inclination random 99                ;; this variable is a random number in the range 0 - 99.  it is used to assign the method with which a worker will decide to retire
    set income-distribution-random random 99        ;; this variable is a random number in the range 0 - 99.  it is used to assign the income distribution
    set-working-income                              ;; this call the method that assigns the workers income
    set above? false
    set chance-to-die random-float 1.00
    ]
end


;;updates the total population
to update-total-population
  set total-population ((count workers) + (count retirees))
end

;;updates the worker to retiree ratio
to update-ratio
  ifelse (count retirees) = 0 [stop][
  set worker-retiree-ratio ((count workers) / (count retirees))]
end
@#$#@#$#@
GRAPHICS-WINDOW
263
23
574
335
-1
-1
3.0
1
10
1
1
1
0
0
1
1
0
100
0
100
0
0
1
ticks
30.0

SLIDER
9
93
203
126
initial-number-of-retirees
initial-number-of-retirees
10
500
10.0
10
1
NIL
HORIZONTAL

SLIDER
8
54
250
87
initial-number-of-workers
initial-number-of-workers
1000
10000
4200.0
10
1
people
HORIZONTAL

BUTTON
6
10
69
43
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

PLOT
958
244
1158
394
tf-balance
time
tf-balance
0.0
100.0
0.0
1.0E8
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot tf-balance"

SLIDER
9
136
181
169
total-SS-tax-rate
total-SS-tax-rate
0
.2
0.09
.01
1
NIL
HORIZONTAL

MONITOR
958
393
1111
438
tf-balance
tf-balance
0
1
11

BUTTON
80
11
157
44
go-once
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
590
96
746
129
retirement-threshold
retirement-threshold
0
1
0.22
.01
1
NIL
HORIZONTAL

INPUTBOX
10
221
165
281
SS-Tax-Limit
118000.0
1
0
Number

PLOT
752
25
952
175
Workers and Retirees
time
number
0.0
80.0
0.0
5000.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count workers"
"pen-1" 1.0 0 -2674135 true "" "plot count retirees"

BUTTON
166
11
258
44
go-forever
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
590
25
745
85
pop-growth-rate
0.0115
1
0
Number

PLOT
957
26
1157
176
Worker to Retiree Ratio
time
Worker to Retiree Ratio
0.0
80.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot worker-retiree-ratio"

SLIDER
9
180
181
213
yearly-SS-benefit
yearly-SS-benefit
10000
20000
14000.0
500
1
NIL
HORIZONTAL

MONITOR
957
176
1157
221
WorkerToRetiree-Ratio
worker-retiree-ratio
1
1
11

PLOT
580
325
955
475
Age Distribution of Workers Retireing in current period
age
turtles
0.0
10.0
0.0
10.0
true
false
"set-plot-x-range 65 max-pxcor\nset-plot-y-range 0 count retirees\nset-histogram-num-bars 35" ""
PENS
"turtles" 1.0 1 -16777216 true "" "histogram [xcor] of turtles with [color = red]"

MONITOR
12
443
253
488
Average Retirement Age
mean [xcor] of retirees with [color = red]
1
1
11

PLOT
11
295
211
445
Average Retirement Age
time
age
0.0
10.0
65.0
70.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if (any? retirees with [color = red]) [plot mean [xcor] of retirees with [color = red] ]"

@#$#@#$#@
## WHAT IS IT?

This is an agent based model of the dynamics of the Social Security and the Social Security Trust Fund.  It uses an implementation of Robert Axtell’s Retirement model for the purposes of modelling the retirement decision.

## HOW IT WORKS

When you set up the model and press go you will see a cohort of people march across the screen.  Green turtles are workers and Orange turtles are retirees.  At each step the workers’ pay money to Social Security and Retirees receive money in benefits.  Social Security is a pay-as-you-go system and so when the current tax receipts exceed the current benefits the trust fund increases and when current tax receipts are less than current benefits the trust fund decreases.

In order for a turtle to receive benefits they must first change from being a worker to being a retiree.  This is done using a model suggested by Robert Axtell.  There are three ways in which a worker can decide to retire.  Fifteen percent of the turtles are "rational" where they retire at the earliest legal age (65 in this model).  Five percent of the turtles are "random" meaning that at each tick they have a 50/50 chance of retiring.  The remainder of the turtles are what Axtell calls "imitators".  These imitators will only retire if the fraction of their unique social network that are retired exceeds a certain preset threshold.  

## HOW TO USE IT

Begin by pressing setup and leaving the default parameters as they are.  Once you press go the turtles will begin to march across the screen. Each tick represents one year. You can see the monitors show the histogram of the average retirement age, the worker to retiree ratio and the trust fund balance.  You have the ability to change various parameters including the Social Security tax rate, the yearly benefit amount paid to retirees, the Social Security tax limit, the population growth rate and the threshold that above which, imitating workers will make the decision to retire.
  
## THINGS TO NOTICE

Notice that when you setup the model using the default parameters and press go there is a very high initial worker to retire ratio.  This is because when a pay-as-you-go Social Security system is started all workers are all of a sudden a part of the system but there are no retirees (or very few retirees) that are included.  As time goes on a workers transition from being to workers to retirees the ratio decreases.

Notice that when you setup the model using the default parameters and press go the trust fund balance is increasing. This is because there are many workers paying money to Social Security and relatively few people drawing Social Security.  As the ratio of workers to retirees decreases there is an eventual turning point for the trust fund balance where it begins to decrease. 

## THINGS TO TRY

Try changing the retirement-threshold.  How does this change the average age at which workers decide to retire?

Try increasing the SS-Tax-Limit to something over a million.  How does this change how long the trust fund has a positive balance?

Try changing the tax rate or the benefit amount and see how this effects how long the trus fund has a positive balance.

## EXTENDING THE MODEL

Currently the workers social network is determined by its neighbors (not a random network with edges).  This model could be extended to implement a social network that is based on edges an nodes.

Currently there is a distribution of wealth with five different discrete income levels.  It might be interesting to institute a more continuous distribution in the population.

## CREDITS AND REFERENCES

Axtell, R., & Epstein, J. (1999). Coordination in Transient Social Networks: An Agent-Based Computational Model of the Timing of Retirement. CSED Working Paper Series No. 1, (Series No. 1). Retrieved December 1, 2014, from http://www.brookings.edu/~/media/research/files/reports/1999/5/retirement axtell/csed_wp01.pdf
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
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="300"/>
    <metric>mean [xcor] of retirees with [color = red]</metric>
    <enumeratedValueSet variable="yearly-SS-benefit">
      <value value="14000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-SS-tax-rate">
      <value value="0.09"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retirement-threshold">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
      <value value="0.4"/>
      <value value="0.5"/>
      <value value="0.6"/>
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-of-workers">
      <value value="4000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-of-retirees">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SS-Tax-Limit">
      <value value="118000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pop-growth-rate">
      <value value="0.0115"/>
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
