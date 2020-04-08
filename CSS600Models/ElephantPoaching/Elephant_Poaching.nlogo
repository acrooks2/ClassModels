globals
[
  ;; the speed an elephant will move (slightly slower than poachers)
  elephant-step
  ;; arbitrary size for elephants
  elephant-size
  ;; the maximum rate elephant tusks can grow
  max-tusk-growth-rate
  ;; the minimum amount of energy required for an elephant to be able to reproduce
  min-energy-to-reproduce
  ;; minimum age for an elephant to reproduce
  min-reproduce-age
  ;; age at which elephants die
  max-age
  ;; the rate at which food regrows on a patch after being eaten
  food-growth-rate
  ;; the speed a poacher will move (slightly faster than elephants)
  poacher-step
  ;; arbitrary size for poachers
  poacher-size
  ;; the distance a poacher can see in patches
  poacher-vision
  ;; simulated economic demand for elephant ivory
  ivory-demand
  ;; variable used to calculate the unfilled ivory demand
  temp-ivory-demand
  ;; mean tusk weight of all elephants used to calculate elephants' chances of reproduction
  tusk-mean
  ;; standard deviation of all elephants' tusk weight used to calculate elephants' chances of reproduction
  tusk-std
]

;; two breeds in the model
breed [elephants elephant]
breed [poachers poacher]

;; elephant attributes
elephants-own
[
  energy
  age
  tusk-weight
  tusk-growth-rate
  chance-of-reproducing
]

;; poacher attributes
poachers-own
[
  ;; unsold ivory in poacher's possession
  ivory
  ;; elephant that the poacher is pursuing
  target
  ;; the amount of money a poacher has (equal to money from sale of ivory minus money spent between sales)
  funds
  ;; level of funds where poacher will drop out of the market
  funds-threshold
]

patches-own
[
  ;; amount of food on a patch
  food-energy
  ;; ticks until patch can regrow food
  countdown
]

to setup
  ca
  ;; initialize elephant variables
  set elephant-size 1.2
  set elephant-step 0.3
  set min-reproduce-age 10
  set min-energy-to-reproduce 10
  set max-age 50
  set max-tusk-growth-rate 5.8
  ;; initialize poacher variables
  set poacher-size 1
  set poacher-step 1
  set poacher-vision 10
  ;; initialize patch variables
  set food-growth-rate 10
  ;; initialize global variables
  set ivory-demand initial-ivory-demand
  ;; initialize agents and environment
  initialize-elephants
  initialize-poachers
  initialize-food

  reset-ticks
end

;; see individual go procedures for details of functionality
to go
  ;; if there are any living elephants, do go procedures
  ;; else stop the model
  ifelse any? elephants [
    update-ivory-demand
    calculate-tusk-mean-and-stdev
    elephants-go
    poachers-go
    patches-go
    tick
  ]
  [stop]
end

;; calculate the mean and standard deviation of all elephant tusks for purposes of determining
;; the chance each elephant has of reproducing - elephants with larger tusks will have higher
;; probability of reproducing than elephants with smaller tusks
to calculate-tusk-mean-and-stdev
  if count elephants > 1 [
    set tusk-mean mean [tusk-weight] of elephants
    set tusk-std standard-deviation [tusk-weight] of elephants
  ]
end

;; this procedure randomly increases or decreases the demand for ivory to simulate fluctuation
to update-ivory-demand
  ;; random fluctuations
  if demand-behavior = "random" [
    ;; Equally likely that demand will increase or decrease
    ifelse random 2 = 1
    ;; increase the demand by no more than 3% of current demand
    [set ivory-demand (ivory-demand + random-float (ivory-demand * 0.03))
    ;; demand can never be negative or zero
    if ivory-demand <= 0 [
      set ivory-demand 1]
    ]
    ;; decrease demand by no more than 3% of current demand
    [set ivory-demand (ivory-demand - random-float (ivory-demand * 0.03))
    ;; demand can never be negative or zero
      if ivory-demand <= 0 [
        set ivory-demand 1]
      ]

    if ivory-demand > max-ivory-demand [
      set ivory-demand max-ivory-demand
    ]
    ;; temporary ivory demand variable is required so that when poachers fulfill the demand
    ;; there is no need to affect the actual ivory demand - whatever the actual ivory demand
    ;; is, poachers will try to fulfill it with the ivory they have collected, so to track the
    ;; fulfilled demand, ivory sales are subtracted from the temporary ivory demand variable.
    set temp-ivory-demand ivory-demand
  ]

  ;; increasing demand
  if demand-behavior = "increasing" [
    ;; Equally likely that demand will increase or decrease
    ifelse random 2 = 1
    ;; increase the demand by no more than 3% of current demand
    [set ivory-demand (ivory-demand + random-float (ivory-demand * 0.03))
    ;; demand can never be negative or zero
    if ivory-demand <= 0 [
      set ivory-demand 1]
    ]
    ;; decrease demand by no more than 1% of current demand
    [set ivory-demand (ivory-demand - random-float (ivory-demand * 0.01))
    ;; demand can never be negative or zero
      if ivory-demand <= 0 [
        set ivory-demand 1]
      ]

    if ivory-demand > max-ivory-demand [
      set ivory-demand max-ivory-demand
    ]
    ;; temporary ivory demand variable is required so that when poachers fulfill the demand
    ;; there is no need to affect the actual ivory demand - whatever the actual ivory demand
    ;; is, poachers will try to fulfill it with the ivory they have collected, so to track the
    ;; fulfilled demand, ivory sales are subtracted from the temporary ivory demand variable.
    set temp-ivory-demand ivory-demand
  ]

  ;; decreasing demand
  if demand-behavior = "decreasing" [
    ;; Equally likely that demand will increase or decrease
    ifelse random 2 = 1
    ;; increase the demand by no more than 1% of current demand
    [set ivory-demand (ivory-demand + random-float (ivory-demand * 0.01))
    ;; demand can never be negative or zero
    if ivory-demand <= 0 [
      set ivory-demand 1]
    ]
    ;; decrease demand by no more than 3% of current demand
    [set ivory-demand (ivory-demand - random-float (ivory-demand * 0.03))
    ;; demand can never be negative or zero
      if ivory-demand <= 0 [
        set ivory-demand 1]
      ]

    if ivory-demand > max-ivory-demand [
      set ivory-demand max-ivory-demand
    ]
    ;; temporary ivory demand variable is required so that when poachers fulfill the demand
    ;; there is no need to affect the actual ivory demand - whatever the actual ivory demand
    ;; is, poachers will try to fulfill it with the ivory they have collected, so to track the
    ;; fulfilled demand, ivory sales are subtracted from the temporary ivory demand variable.
    set temp-ivory-demand ivory-demand
  ]
end

to elephants-go
  ask elephants [
    elephants-move
    eat-food
    reproduce
    death
  ]
end

to poachers-go
  ask poachers [
    ;; if poaching isn't lucrative enough, poachers will quit
    if funds < funds-threshold [die]
    ;; if the poacher has been able to sell all the ivory it has collected, it will hunt another elephant
    if ivory <= 0 [hunt-elephants]
    ;; procedure for poachers to try to sell their ivory
    go-to-market
    ;; poachers' funds are reduced at a greater rate depending on the amount of ivory in their possession
    ;; this simulates a higher economic burden of storing more ivory
    ifelse ivory > 0
    [set funds (funds - (ivory ^ (ivory / 100)))]
    [set funds (funds - 1)]
  ]
end

to patches-go
  ask patches [
    grow-food
  ]
end

;; this procedure is necessary to initialize the elephant population with
;; tusks at the correct size for their initial age
to set-initial-tusk-weight [initial-elephant-age]
  let starting-point 1
  ;; since every initial elephant at setup has a tusk weight of 0, and 0 can't grow at a rate,
  ;; start the tusk weight off at the elephant's tusk growth rate
  let temp-tusk-weight (tusk-growth-rate / 100)
  ;; for each year in the elephant's age, increase the elephant's tusk weight by tusk growth rate
  while [starting-point <= initial-elephant-age] [
    set temp-tusk-weight (temp-tusk-weight + (temp-tusk-weight * (tusk-growth-rate / 100)))
    set starting-point (starting-point + 1)
    set tusk-weight temp-tusk-weight
  ]
end

to initialize-elephants
  ;;start number of elephants off with random energy, random age, random tusk growth rate and random location
  create-elephants num-elephants
  [
    set color (grey)
    set size elephant-size
    set energy 20 + random 20 - random 20
    set age 1 + random max-age
    set tusk-growth-rate 1 + random-float max-tusk-growth-rate
    setxy random world-width random world-height
  ]
  ask elephants [
    set-initial-tusk-weight (age)
  ]
end

;; create number of poachers and initialize poacher attributes
to initialize-poachers
  create-poachers num-poachers
  [
    ;; to distinguish poachers from elephants
    set color red
    set ivory 0
    set target nobody
    set funds random 100
    set funds-threshold random 20
    setxy random world-width random world-height
  ]
end

;; patches all start off with 50 food
to initialize-food
  ask patches
  [
    set food-energy 50
    food-color
  ]
end

to elephants-move
  ;; energy cost for moving
  set energy (energy - 1)
  set age (age + 1)
  ifelse tusk-weight = 0
  ;; start tusk growth for all baby elephants
  [set tusk-weight (tusk-growth-rate / 100)]
  ;; else, increase tusk weight by growth rate percentage
  [set tusk-weight (tusk-weight + (tusk-weight * (tusk-growth-rate / 100)))]
  rt random 50 - random 50
  fd elephant-step
end

to eat-food
  ;; if food is plentiful enough on patch
  if food-energy > 10 [
    ;; consume 10 food
    set food-energy (food-energy - 10)
    ;; get energy from food
    set energy (energy + 2)
    ;; set the patch's regrowth countdown
    set countdown random 25
  ]
end

to reproduce
  ;; elephants must be old enough and have enough energy to reproduce
  if energy > min-energy-to-reproduce and age > min-reproduce-age
  [
    ;; this normalizes the tusk-weight data for the next step
    let reproducing-factor (tusk-weight - tusk-mean) / tusk-std
    ;; this transforms the normalized data into an exponential relationship between
    ;; tusk size and the chance of reproducing at each step
    set chance-of-reproducing (((reproducing-factor + 3) ^ 2) / 100)
    if chance-of-reproducing > random-float 1 [
      ;; energy cost of reproducing
      set energy (energy / 2)
      let offspring-energy (energy / 2)
      hatch 1 [
        ;; allow for genetic variation in offspring
        mutate-tusk-growth-rate
        set size elephant-size
        set color (grey)
        set energy offspring-energy
        set tusk-weight 0
        set age 0
        rt random 360 fd elephant-step
      ]
    ]
  ]
end

;; this procedure accounts for genetic mutation of tusk growth rate from parent to offspring
to mutate-tusk-growth-rate
  ;; equal chance of mutation increasing or decreasing offspring tusk growth rate
  ifelse random 2 = 1
  [set tusk-growth-rate (tusk-growth-rate + random-float (tusk-growth-rate * 0.10))]
  [set tusk-growth-rate (tusk-growth-rate - random-float (tusk-growth-rate * 0.10))]
  ;; prevent elephants from having a tusk growth rate higher than the max
  if tusk-growth-rate > max-tusk-growth-rate [set tusk-growth-rate (max-tusk-growth-rate)]
  ;; prevent elephants from having a negative tusk growth rate
  if tusk-growth-rate <= 0 [set tusk-growth-rate (0.01)]
end

;; elephants die of old age
to death
  if age > max-age or energy < 0 [die]
end

;; poacher activity
to hunt-elephants
  ;; check if the poacher is currently hunting an elephant (poacher has a target elephant)
  ifelse target = nobody
  ;; if the poacher is not currently hunting an elephant then
  [
    ;; find the elephant in vision cone with the largest tusks and make it the target for hunting
    let potential-targets nobody
    set potential-targets elephants in-cone poacher-vision 120
    if any? potential-targets [
      set target one-of potential-targets with-max [tusk-weight]
    ]
  ]
  ;; if the poacher is currently hunting (has a target elephant) then face the target
  [set heading towards target]
  ;; move toward the target
  fd poacher-step
  ;; once the poacher catches up to the target elephant, kill it and collect its ivory
  if target != nobody and target != 0 [
    if member? target turtles-here [
      set ivory (ivory + (100 * [tusk-weight] of target))
      ask target [die]
    ]
  ]
end

;; poachers need to try to sell the ivory they have collected
to go-to-market
  let ivory-sale 0
  ;; if there is unfulfilled demand for ivory and poacher has ivory to sell, then
  if temp-ivory-demand > 0 and ivory > 0 [
    ;; if there is more demand for ivory than poacher can supply, then
    ifelse temp-ivory-demand > ivory
    ;; poacher sells all of its ivory
    [set ivory-sale (ivory)]
    ;; if the poacher has more ivory than there is demand for, sell as much ivory as possible to fulfill the demand
    [set ivory-sale (ivory - temp-ivory-demand)]
  ]
  ;; perform the ivory sale transaction
  ;; reduce unfulfilled demand
  set temp-ivory-demand (temp-ivory-demand - ivory-sale)
  ;; reduce the amount of ivory possessed by the poacher
  set ivory (ivory - ivory-sale)
  ;; increase the poachers funds from the sale
  set funds (funds + (ivory-sale))
  ;; if unfulfilled demand for ivory still exists, another poacher will enter the market because they believe they
  ;; can make money on the excess demand
  if temp-ivory-demand > 0 and count poachers < max-poachers [
    hatch 1 [
      set color red
      set ivory 0
      set funds random 100
      set funds-threshold random 20
      setxy random world-width random world-height
    ]
  ]
end

;; patches procedure
to grow-food
  ;; countdown to regrowing food
  set countdown (countdown - 1)
  if countdown <= 0
    ;; food grows back at designated rate
    [set food-energy (food-energy + food-growth-rate)
      ;; don't let the food energy of a patch go above 100
      if food-energy > 100
      [set food-energy 100]
  ]
  food-color
end

;; patches procedure
to food-color
  ;; set the patch color based on the amount of food energy the patch contains (more green means more energy)
  ifelse food-energy > 0
  [set pcolor (scale-color green food-energy (100 * 2) 0)]
  [set pcolor (white)]
end

;; this procedure is controlled from the interface to allow the user to change the ivory demand without waiting for
;; it to randomly increase
to increase-demand
  set ivory-demand (ivory-demand + 10)
end

;; this procedure is controlled from the interface to allow the user to change the ivory demand without waiting for
;; it to randomly decrease
to decrease-demand
  set ivory-demand (ivory-demand - 10)
end
@#$#@#$#@
GRAPHICS-WINDOW
436
13
1054
632
-1
-1
6.04
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

BUTTON
5
10
71
43
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
78
10
141
43
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
4
65
222
98
num-elephants
num-elephants
0
4000
1000.0
1
1
NIL
HORIZONTAL

PLOT
5
147
205
297
number of elephants
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
"default" 1.0 0 -9276814 true "" "plot count elephants"

SLIDER
4
105
176
138
num-poachers
num-poachers
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
190
106
371
139
initial-ivory-demand
initial-ivory-demand
0
100
100.0
1
1
NIL
HORIZONTAL

PLOT
4
471
204
621
ivory demand
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
"default" 1.0 0 -16777216 true "" "plot ivory-demand"

PLOT
7
307
207
457
unsold ivory
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
"default" 1.0 0 -8630108 true "" "plot sum [ivory] of poachers"

PLOT
216
148
416
298
total tusk weight
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
"default" 1.0 0 -13791810 true "" "plot sum [tusk-weight] of elephants"

PLOT
214
310
414
460
average poacher funds
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
"default" 1.0 0 -5825686 true "" "plot mean [funds] of poachers"

PLOT
214
474
414
624
poachers
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
"default" 1.0 0 -2674135 true "" "plot count poachers"

PLOT
5
637
205
787
average tusk weight
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
"default" 1.0 0 -16777216 true "" "plot mean [tusk-weight] of elephants * 100"

PLOT
218
642
418
792
average poacher ivory
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
"default" 1.0 0 -16777216 true "" "plot mean [ivory] of poachers"

BUTTON
663
648
803
681
NIL
increase-demand
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
816
648
959
681
NIL
decrease-demand
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
239
66
425
99
max-poachers
max-poachers
1
5000
4000.0
10
1
NIL
HORIZONTAL

CHOOSER
166
10
304
55
demand-behavior
demand-behavior
"random" "increasing" "decreasing"
0

SLIDER
664
696
838
729
max-ivory-demand
max-ivory-demand
0
5000
400000.0
10
1
NIL
HORIZONTAL

PLOT
437
645
637
795
plot 1
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
"default" 1.0 0 -16777216 true "" "plot max [funds] of poachers"

@#$#@#$#@
## WHAT IS IT?

This model represents an abstract environment in which elephants and poachers interact. The purpose is to show the effects of economic demand for ivory, and subsequent impact on poaching behavior, and ultimately the effects of poaching on elephant populations.

## HOW IT WORKS

A population of elephants and poachers is initiated in an environment with food resources for elephants to consume. The elephants move around the environment while aging, expending energy, and consuming food to replenish energy. Elephants die if they reach the age of 50 or run out of energy. Each elephant has an attribute that determines the growth rate of its tusks, which is important because the larger the elephant's tusks the more likely it is to reproduce. When an elephant reproduces, it passes on its tusk growth rate gene to its offspring, with some random genetic mutation, making it more likely that the average tusk weight of all elephants will increase over time, unless there are interfering factors. Elephants also expend half of their current energy to reproduce. Poachers only move around the environment when they are hunting elephants. They hunt when there is economic demand for ivory, and they have already sold all of the ivory they have collected. Poachers have limited vision in the direction they are heading, and they will hunt the elephant with the largest tusk they can "see". Poachers move slightly faster than elephants, and when they catch the elephant they are hunting, the elephant is killed and the poacher collects ivory equal to the value of the elephant's tusk weight. The poacher will then try to sell the ivory, and, depending on the unfulfilled demand, will either be able to sell all of the ivory it has collected, some of the ivory it has collected, or none. Poachers receive money from the sale of ivory, and they also expend money at a rate that increases with the amount of ivory they have. This simulates the increased economic burden of storing larger quantities of ivory. The poachers' calculation of the economic utility of poaching compared to other activities is represented by a threshold amount of money below which they will stop poaching because they could make more money doing something else. If the existing poachers are unable to fulfill the demand for ivory, then new poachers will enter the market.

## HOW TO USE IT
To setup the model, select the starting model parameter values using the sliders, and then click "setup". Once the model initializes, click "go". If you want to stop the simulation, click "go" again. If you want to manually increase or decrease the economic demand for ivory, click the "increase-demand" or "decrease-demand" buttons respectively. This will increase or decrease the demand for ivory by 10 each time the corresponding button is clicked (ivory demand cannot be negative or 0).

Model parameter descriptions:

"num-elephants" - determines the number of elephants in the initial population.

"reproduction-chance" - the exponent in the function that determines an elephants statistical chance of reproducing; as the exponent increases it is more likely that elephants with relatively small tusks will reproduce. As the exponenet decreases, elephants with relatively large tusks will still have a very high chance of reproducing, but elephants with relatively small tusks will not be likely to reproduce.

"num-poachers" - determines the number of poachers in the initial population.

"initial-ivory-demand" - determines the economic demand for ivory at the beginning of a simulation.

Model plot descriptions:

The number of elephants plot shows the total number of elephants currently alive in the environment.

The total tusk weight plot shows the total weight of all the living elephants' tusks.

The unsold ivory plot shows the total amount of ivory that is currently held by all active poachers.

The average poacher funds plot shows the average amount of money all active poachers have.

The ivory demand plot shows the current economic demand for ivory.

The poachers plot shows the total number of active poachers in the environment.

The average tusk weight plot shows the mean tusk weight for all living elephants.

The average poacher ivory plot shows the mean amount of ivory currently held by all active poachers.

The average elephant age plot shows the mean age of all living elephants in the environment.

## THINGS TO NOTICE

What happens as the demand for ivory increases? What happens when it decreases? What happens when it stays relatively stable?

What happens if there are no poachers?

How does the initial number of elephants and poachers affect the simulation over time?

## THINGS TO TRY

Run the model with no poachers.

Run the model with very high/very low initial ivory demand.

Run the model with different "reproduction-chance" values.

## EXTENDING THE MODEL

Currently the model assumes a uniformly rich distribution of food for elephants to consume in the environment. An extension of the model could include the ability to adjust the distribution of food, or seasonal variations in the availability of food in different areas of the environment. Other extensions could involve giving the user the ability to adjust more model parameters to understand how variations affect the outcomes. Also, economic demand for ivory is randomly determined in this model, so another method of determining demand could possibly improve the model's usefulness.

## RELATED MODELS

The Bug Hunt Predators and Invasive Species model included in the NetLogo Models Library contains similar evolutionary and hunting behavior that are incorporated into this model.

## CREDITS AND REFERENCES

Citation:
Novak, M. and Wilensky, U. (2011). NetLogo Bug Hunt Predators and Invasive Species model. http://ccl.northwestern.edu/netlogo/models/BugHuntPredatorsandInvasiveSpecies. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
  <experiment name="Experiment_01" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3000"/>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <metric>mean [funds] of poachers</metric>
    <metric>mean [ivory] of poachers</metric>
    <metric>ivory-demand</metric>
    <metric>sum [ivory] of poachers</metric>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-chance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
      <value value="400"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_02" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="600"/>
    <metric>count elephants</metric>
    <enumeratedValueSet variable="num-elephants">
      <value value="1620"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-chance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_03" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1500"/>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <metric>ivory-demand</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;increasing&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-chance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_04" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1500"/>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <metric>ivory-demand</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;decreasing&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-chance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_05" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1500"/>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <metric>ivory-demand</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-chance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment_06" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count elephants</metric>
    <metric>mean [food-energy] of patches</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
      <value value="4000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-poachers">
      <value value="4000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Effects_of_Demand" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-poachers">
      <value value="4000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Effects_of_Increasing_Demand" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <metric>ivory-demand</metric>
    <metric>mean [funds] of poachers</metric>
    <metric>mean [ivory] of poachers</metric>
    <metric>max [funds] of poachers</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;increasing&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-poachers">
      <value value="4000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ivory-demand">
      <value value="400"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="unlimited demand increase" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count elephants</metric>
    <metric>count poachers</metric>
    <metric>mean [tusk-weight] of elephants</metric>
    <metric>ivory-demand</metric>
    <metric>mean [funds] of poachers</metric>
    <metric>mean [ivory] of poachers</metric>
    <metric>max [funds] of poachers</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;increasing&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-poachers">
      <value value="400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ivory-demand">
      <value value="400000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="histogram" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>[funds] of poachers</metric>
    <enumeratedValueSet variable="demand-behavior">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-elephants">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-poachers">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-ivory-demand">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-poachers">
      <value value="400000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-ivory-demand">
      <value value="400000"/>
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
