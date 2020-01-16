
; Artificial Market & Bullwhip theory model in NetLogo
;
; this model will attempt to create an environment
; suitable for the analysis of the Bullwhip effect.
; It will then ; determine which intrinsic factors play
; the largest role in reducing the effects
; (and overall occurance) of the Bullwhip Effect
;
;
; COMPARING FORECASTING METHODS ON REDUCING THE BULLWHIP EFFECT
; -----------------------------------------------------------------

;;;EXTENSIONS
extensions [
  matrix
]
;;;GLOBALS

globals [
  STOCKS ;initial stock for retailers and wholesalers
  BUFFERS ;buffer (minimum amount of stock kept on hand) for retailers and wholesalers
  RETURN_FLAG ;keeps time so customers can casually return the second tick after their invasion
]


;;;BREEDS
breed [customers customer]
breed [retailers retailer]
breed [retailers2 retailer2] ;only going to be used to test linear forecasting
breed [wholesalers wholesaler]
breed [distributors distributor]
breed [aliens alien]

;;;attributes/traits/features
;turtles-own []
customers-own [frequency order_to_retailer lucky_number]
;frequency: how often this person shops a week (when they do), order_to_retailer: order to retailer,
; lucky_number -> stochastic choice for who will be purchasing that day
retailers-own [stock buffer backorder demand_log prediction prediction_log order_to_wholesaler]
;stock: how much inventory, buffer:stock kept at all times, backorder: demand that could not be supplied
; demand_log: demand history, prediction: prediction for next tick
; prediction_log: past predictions, order_to_wholesaler: order to wholesaler
retailers2-own [stock buffer backorder demand_log prediction prediction_log order_to_wholesaler]
wholesalers-own [stock buffer backorder demand_log prediction prediction_log order_to_distributor]
;same as retailer
distributors-own [demand_log prediction prediction_log]
;^

;;; PROCEDURES
to setup
  clear-all ;clear environment
  ;ask patches [set pcolor 66] ;turns environment white
  random-seed 47822


  ;create the customers, retailers, wholesalers, and distributors

  create-customers N_Customers [
    set frequency 0
    ;aethetics
    set size 1
    set color (random-normal 35.5 1)
    set shape "person"
  ]

  ;create retailers
  create-retailers N_Retailers [
    ;stock is initialized
    set stock STOCKS
    ;stock buffer
    set buffer BUFFERS
    ;initiate demand log
    set demand_log []
    ;initiate backorder
    set backorder 0
    ;initiate prediction
    set prediction 0
    ;initiate prediction log
    set prediction_log [0]
    ;aethetics
    set size 4
    set shape "truck"
    set color 135
  ]

    ;create retailers
  create-retailers2 N_Retailers [
    ;stock is initialized
    set stock STOCKS
    ;stock buffer
    set buffer BUFFERS
    ;initiate demand log
    set demand_log []
    ;initiate backorder
    set backorder 0
    ;initiate prediction
    set prediction 0
    ;initiate prediction log
    set prediction_log [0]
    ;aethetics
    set size 4
    set shape "truck"
    set color 103
  ]

    ;create wholesalers
  create-wholesalers N_Wholesalers [
    ;stock is initialized
    set stock STOCKS * (count turtles with [breed = retailers]) / (count turtles with [breed = wholesalers])
    ;stock buffer used is the total if all customers ordered half of the maximum quantity once
    set buffer BUFFERS * (count turtles with [breed = retailers]) / (count turtles with [breed = wholesalers])
    ;initiate demand log
    set demand_log []
    ;initiate prediction
    set prediction 0
    ;initiate prediction log
    set prediction_log [0]
    ;aethetics
    set size 4
    set shape "house"
    set color 86
    setxy 9 11
  ]

    ;create distributors
  create-distributors N_Distributors [
    ;stock is assumed to be infinite

    ;initiate demand log
    set demand_log []
    ;initiate prediction
    set prediction 0
    ;initiate prediction log
    set prediction_log [0]
    ;aethetics
    set size 5
    set shape "house"
    set color 25
    setxy 9 11
  ]

  ;get a frequency for each customer
  ask customers [frequency_chooser]
  ;set order amount
  ask customers [order_chooser]

  ;move all turtles to an open spot
  ask customers [get_open_customers]
  ask retailers [get_open_not_customers]
  ask retailers2 [get_open_not_customers]
  ask wholesalers [get_open_not_customers]
  ask distributors [get_open_not_customers]


  ;assign each customer to a retailer
  ;link-up
  ;did  not usemuch, but its there for potential analysis with customer markets

  color-patches

  reset-ticks
end

to go

  step

end

to ten_steps
  ;used for a button on interface
  repeat 10 [step]

end


;allows for stepping through the simulation one tick at a time
to step

  ;orders get sent from customers
  ;retailers demand logs updated
  ;orders then have to be compared to the retailers stock
  ;retailers decide how much stock to order
  ;wholesalers demand logs updated
  ;orders then have to be compared to the wholesalers stock
  ;wholesalers decide how much stock to order

  ;to return customers from  the aliens
  ;RETURN_FLAG starts at 0
  if (RETURN_FLAG >= 1)[
    ifelse (RETURN_FLAG = 1)[
    create-customers (N_Customers - (count turtles with [breed = customers])) [
      set frequency 0
      ;aethetics
      set size 1
      set color (random-normal 125.5 1)
      set shape "person"
      ;establish traits for new customers and then scatter them
      ask customers with [xcor = 0] [frequency_chooser]
      ask customers with [xcor = 0] [order_chooser]
      ask customers with [xcor = 0] [get_open_customers]
  ]
    set RETURN_FLAG RETURN_FLAG - 1]
    [set RETURN_FLAG RETURN_FLAG - 1]]

  if (((count turtles with [breed = customers]) < N_Customers) and RETURN_FLAG = 0)
  [set RETURN_FLAG return-in-weeks]


  ask customers[whos_shopping]

  ask retailers[update_retailers_demand_log]
  ask retailers2[update_retailers_demand_log]
  ask retailers[make-prediction]
  ask retailers2[make-prediction]
  ask retailers[update_retailers]
  ask retailers2[update_retailers]

  ask wholesalers[update_wholesalers_demand_log]
  ask wholesalers[make-prediction]
  ask wholesalers[update_wholesalers]

  ask distributors[update_distributors_demand_log]
  ask distributors[make-prediction]




  ;hardcoded figures in interface, butleft these here just in  case
;  make-retailers-plot
;  make-wholesalers-plot
;  make-distributors-plot

;  customers-demand-plot
;  retailers-demand-plot
;  wholesalers-demand-plot

  ;provides variability & noise
  ask customers [frequency_chooser]
  tick
end


;;;;;;;;;;;;;;;;;;;;;;;;;
;;SUBROUTINES/FUNCTIONS;;
;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-globals
  set STOCKS ((count turtles with [breed = customers]) * (random Max_Purchase * 0.5 + 1))
  set BUFFERS ((count turtles with [breed = customers]) * random Max_Purchase * 0.5)
  set RETURN_FLAG 0
end

to whos_shopping
  ;assigns each turtle a random "group" based on the random number
  set lucky_number random 3
end

to get_open_customers
  ;moves each turtle to an unoccupied space
  setxy random-xcor random-ycor
  while [any? other turtles-here or ycor >= 8 or ycor <= -15 or xcor >= 15 or xcor <= -15 or xcor = 0]
      [get_open_customers]
end

to get_open_not_customers
  ;moves each turtle to an unoccupied space
  setxy random-xcor random-ycor
  while [any? other turtles-here or ycor <= 8 or ycor >= 15 or xcor >= 15 or xcor <= -15]
      [get_open_not_customers]
end

to color-patches
  ;colors the background green
  ask patches [
    set pcolor scale-color
    green 19
    5 30
  ]
end

to link-up
  ;creates a link between a customer and his/her retailer
  ;also creates a link between each retailer and  its wholesaler
   ask customers [create-link-with one-of other turtles with [breed = retailers or breed = retailers2]]
   ask retailers [create-link-with one-of other turtles with [breed = wholesalers]]
  ask retailers2 [create-link-with one-of other turtles with [breed = wholesalers]]
   ask wholesalers [create-link-with one-of other turtles with [breed = distributors]]
end

to frequency_chooser
  ;will determine a frequency for how  often the customer purchases something from the retailer
  let temp round (random-normal 2 2)
  ifelse (temp > 0)
  [set frequency temp]
  [set frequency 1]
end

to order_chooser
  ;will determine a customer's order per shopping trip amount
  let temp ((random-normal round(Max_purchase / 2) ((Max_purchase - round(Max_purchase / 2)) / 3)))
  ;this was chosen to keep most puchases 0<x<max with a mean around half of the max
  ifelse (temp > 0) ;if the amount is greater than 0
  [ifelse (temp > Max_purchase) ;know >0 so now test to see if >Max
    [set order_to_retailer Max_purchase] ;if greater than max, set to max
    [set order_to_retailer temp] ;if not greater than max set to tem
  ] ;now we do something if thenumber is less than 0
  [set order_to_retailer ((random-float  Max_purchase - .1) + .1)]
  ;sets the order to a random amount between .1 and the max
end

to update_retailers_demand_log
  ;will  update the demand log

  ;adds most recent customer demand
  set demand_log lput(sum [order_to_retailer] of customers with [lucky_number = 0]) demand_log
end

to update_retailers

  ;compares this demand to the current stock
  ifelse (((last demand_log) + backorder) > stock)
  ;if there is not enough stock, the company goes into backorder and must wait until the next delivery
  [set backorder ((last demand_log ) - stock)
    set stock 0
    ;make the order enough to fufill backorder & reach buffer
    set order_to_wholesaler (backorder + (buffer - stock))
    ;ordered stock is added immediately
    set stock (stock + backorder + (buffer - stock))]
  ;if the demand is smaller than our stock, we subtract it from the stock
  [set stock (stock - (last demand_log))
    ;reset backorder
    set backorder 0
    ;if under the buffer limit, an  order is made
    if ((buffer - stock) > 0)
    [set order_to_wholesaler (backorder + (buffer - stock))
     ;ordered stock is added immediately
     set stock (stock + (backorder + (buffer - stock)))]]
  ;deciding to order more or not based on the forecasting
  if (stock - prediction) < buffer
  [set order_to_wholesaler (order_to_wholesaler + (prediction - stock))
   set stock (stock + (order_to_wholesaler + (prediction - stock)))]
end


to update_wholesalers_demand_log
  ;will  update the demand log
  ;adds most recent retailer demand
  set demand_log lput(sum [order_to_wholesaler] of retailers) demand_log
end


to update_wholesalers

  ;compares this demand to the current stock
  ifelse (((last demand_log) + backorder) > stock)
  ;if there is not enough stock, the institution goes into backorder and must wait until the next delivery
  [set backorder ((last demand_log ) - stock)
    set stock 0
    set order_to_distributor (backorder + (buffer - stock))
    ;get order immediately
    set stock (stock + (backorder + (buffer - stock)))]
  ;if the demand is smaller than our stock, we subtract it from the stock
  [set stock (stock - (last demand_log))
    ;reset backorder
    set backorder 0
    ;if under the buffer limit, an  order is made
    if ((buffer - stock) > 0)
    [set order_to_distributor (backorder + (buffer - stock))
     set stock (stock + (backorder + (buffer - stock)))]]
  ;deciding to order more or not based on the forecasting
  if ((stock - prediction) < buffer)
  [set order_to_distributor (order_to_distributor + (prediction - stock))
   set stock (stock + (order_to_distributor + (prediction - stock)))]
end

to update_distributors_demand_log
  ;will  update the demand log
  ask distributors[set demand_log lput(sum [order_to_distributor] of wholesalers) demand_log]
end



to make-prediction
  ;will take a demand_log and update the current prediction -- using netlogo's matrix:forecast-continuous-growth

  ;forecasting happens at x-time intervals: chosen  by user
  ;used for retailers, wholesalers, and distributors
  let prediction_holder [] ;will gather prediction info
  ifelse (((ticks mod retailers_increment) = 0 and (breed = retailers or breed =  retailers2)) or ((ticks mod wholesalers_increment) = 0 and breed = wholesalers))[
        ;this initial if else tests to see which consumers are shopping this week ... helps create a semi-diverse consumer market
    ifelse (length(demand_log) >= 1) and (max demand_log > 0) ;attempting to avoid empty lists at all costs
    [ifelse (breed != retailers2) [set prediction_holder matrix:forecast-continuous-growth demand_log]
      [set prediction_holder matrix:forecast-linear-growth demand_log]]
    [set prediction_holder lput(last prediction_log) prediction_holder ;condition if (length(demand_log) >= 1) and (max demand_log > 0) fails
      set prediction_holder lput(min demand_log) prediction_holder ;sets the constant (intercept) for prediction line
      set prediction_holder lput(0) prediction_holder ; sets the growth percentage to 0% .... ifno prediction can be made, no growth can occur
      set prediction_holder lput(0) prediction_holder] ;this is the r squared value... I put zero so I can tell that the prediction alg. was not used
    set prediction item 0 prediction_holder
    set prediction_log lput(prediction) prediction_log
  ]
  [set prediction_holder lput(last prediction_log) prediction_holder
    set prediction item 0 prediction_holder
    set prediction_log lput(prediction) prediction_log]

  ;for the base model, all we really care about is item 0, which is just the  predicted value
end




to lottery_winner
  ;this is here to cause a shock in the system
  ;let winner last [demand_log] of one-of retailers
  ;ask retailers[set demand_log lput(winner + winner * Max_Purchase * lotto_winners) demand_log]
  ask customers [set order_to_retailer (order_to_retailer + random (Max_Purchase)) * frequency]
  ;this creates a large, yet random spike in  demand
end


to alien_strike
  create-aliens alien-amount [
    set size 0.5
    set color (random-normal 121 0.5)
    set shape "circle"
    setxy random-pxcor random-pycor
    while [ycor >= 8 or ycor <= -15 or xcor >= 15 or xcor <= -15]
    [setxy random-pxcor random-pycor]
  ]
  ask customers [if any? other turtles-here [die]]

  ask aliens [die]
end
;--------------------------------------------------------------------------------------------------
to make-retailers-plot
  set-current-plot "Customer Demand vs Retailer's Prediction"
  set-current-plot-pen "true"
  plot (sum [order_to_retailer] of customers with [lucky_number = 0])
  set-current-plot-pen "prediction"
  plot last [prediction_log] of one-of retailers
end

to make-wholesalers-plot
  set-current-plot "Retailer Demand vs Wholesaler Prediction"
  set-current-plot-pen "true"
  plot last ([order_to_wholesaler]) of retailers
  set-current-plot-pen "prediction"
  plot last [prediction_log] of one-of wholesalers
end

to make-distributors-plot
  set-current-plot "Wholesaler Demand vs Distributor Prediction"
  set-current-plot-pen "true"
  plot last ([order_to_distributor]) of wholesalers
  set-current-plot-pen "prediction"
  plot last [prediction_log] of one-of distributors
end


;supply curves
;code was giving errors so I hard coded them into the interface

to customers-demand-plot
  set-current-plot "Customer Demand"
  set-current-plot-pen "default"
  plot (sum [order_to_retailer] of customers with [lucky_number = 0])
end

to retailers-prediction-plot
  set-current-plot "Retailer Prediction of Customer Demand"
  set-current-plot-pen "default"
  plot last ([prediction_log]) of one-of retailers
end

to wholesalers-prediction-plot
  set-current-plot "Wholesaler Prediction"
  set-current-plot-pen "default"
  plot last ([prediction_log]) of one-of Wholesalers
end
;
;
@#$#@#$#@
GRAPHICS-WINDOW
199
10
618
430
-1
-1
12.455
1
10
1
1
1
0
0
0
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

SLIDER
23
148
195
181
N_Customers
N_Customers
1
250
100.0
1
1
NIL
HORIZONTAL

BUTTON
66
262
198
348
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
23
181
196
214
Max_Purchase
Max_Purchase
1
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
21
216
210
272
Max_Purchase refers to the quantity per order. Some customers order 5 times a week
11
0.0
1

BUTTON
0
262
65
302
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

BUTTON
-2
347
200
430
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

PLOT
1155
10
1446
208
Customer Demand vs Retailer's Prediction
Time (weeks)
Transaction Amount
0.0
100.0
700.0
1800.0
true
true
"" ""
PENS
"true" 1.0 0 -16777216 true "" "plot (sum [order_to_retailer] of customers with [lucky_number = 0])"
"continuous prediction" 1.0 0 -2674135 true "" "plot last [prediction_log] of one-of retailers"
"linear prediction" 1.0 0 -8990512 true "" "plot last [prediction_log] of one-of retailers2"

PLOT
1206
439
1496
614
Retailer Demand vs Wholesaler Prediction
Time (weeks)
 Transaction Amount
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"true" 1.0 0 -16777216 true "" "plot last ([order_to_wholesaler]) of retailers"
"prediction" 1.0 0 -2674135 true "" "plot last [prediction_log] of one-of wholesalers"

CHOOSER
57
10
195
55
N_Distributors
N_Distributors
1
0

PLOT
618
10
873
208
Customer Demand
Time (weeks)
Transaction Amount
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (sum [order_to_retailer] of customers with [lucky_number = 0])"

PLOT
756
209
1048
435
Retail's Predicted Demand Curve (continuous)
Time (weeks)
Transaction Amount
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Customers" 1.0 0 -16777216 true "" "plot last ([prediction_log]) of one-of retailers"

PLOT
618
432
854
592
Wholesaler Demand
Time (weeks)
Transaction Amount
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"whole" 1.0 0 -16777216 true "" "plot last ([prediction_log]) of one-of Wholesalers"

MONITOR
873
10
1156
75
Actual Customer Transactions
sum [order_to_retailer] of customers with [lucky_number = 0]
3
1
16

MONITOR
617
313
756
378
Predicted Customer Transactions
last [prediction_log] of one-of retailers
3
1
16

BUTTON
449
430
618
489
Lottery Winner(s)
lottery_winner
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
239
433
448
466
retailers_increment
retailers_increment
1
10
3.0
1
1
NIL
HORIZONTAL

CHOOSER
57
102
195
147
N_Retailers
N_Retailers
1
0

CHOOSER
57
56
195
101
N_Wholesalers
N_Wholesalers
1
0

MONITOR
621
245
755
314
Percent Error (as a percent)
(abs ((sum [order_to_retailer] of customers with [lucky_number = 0]) -  (last [prediction_log] of one-of retailers)))/(sum [order_to_retailer] of customers with [lucky_number = 0]) * 100
4
1
17

SLIDER
239
465
448
498
wholesalers_increment
wholesalers_increment
1
10
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
244
506
394
554
Allows user to decide how often (in weeks) the predictions are updated
13
0.0
1

SLIDER
270
557
442
590
alien-amount
alien-amount
1
1000
400.0
1
1
NIL
HORIZONTAL

BUTTON
449
490
617
582
Alien Invasion
alien_strike
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
-2
302
65
348
10 steps
ten_steps
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
88
559
260
592
return-in-weeks
return-in-weeks
1
100
10.0
1
1
NIL
HORIZONTAL

PLOT
1049
207
1338
438
Retailer's Predicted Demand (linear)
Time (weeks)
Transaction Amount
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot last ([prediction_log]) of one-of retailers2"

MONITOR
1340
305
1512
370
Predicted Customer Transactions
last [prediction_log] of one-of retailers2
3
1
16

MONITOR
1340
239
1513
304
Percent Error
(abs ((sum [order_to_retailer] of customers with [lucky_number = 0]) -  (last [prediction_log] of one-of retailers2)))/(sum [order_to_retailer] of customers with [lucky_number = 0]) * 100
3
1
16

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
  <experiment name="num_cust" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>(abs ((sum [order_to_retailer] of customers with [lucky_number = 0]) -  (last [prediction_log] of one-of retailers)))/(sum [order_to_retailer] of customers with [lucky_number = 0]) * 100</metric>
    <enumeratedValueSet variable="lotto_winners">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alien-amount">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Distributors">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Wholesalers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-in-weeks">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Retailers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailers_increment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wholesalers_increment">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Max_Purchase" first="10" step="5" last="50"/>
    <enumeratedValueSet variable="N_Customers">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="aliens" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <metric>count turtles</metric>
    <metric>(abs ((sum [order_to_retailer] of customers with [lucky_number = 0]) -  (last [prediction_log] of one-of retailers)))/(sum [order_to_retailer] of customers with [lucky_number = 0]) * 100</metric>
    <metric>(abs ((sum [order_to_retailer] of customers with [lucky_number = 0]) -  (last [prediction_log] of one-of retailers2)))/(sum [order_to_retailer] of customers with [lucky_number = 0]) * 100</metric>
    <enumeratedValueSet variable="lotto_winners">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="alien-amount" first="50" step="50" last="600"/>
    <enumeratedValueSet variable="N_Distributors">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Wholesalers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-in-weeks">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Retailers">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailers_increment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wholesalers_increment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Purchase">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Customers">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="lotto_winners">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alien-amount">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Distributors">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Wholesalers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-in-weeks">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Retailers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailers_increment">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wholesalers_increment">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Purchase">
      <value value="52"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Customers">
      <value value="103"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="BASE" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="lotto_winners">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alien-amount">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Distributors">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Wholesalers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="return-in-weeks">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Retailers">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="retailers_increment">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wholesalers_increment">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max_Purchase">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="N_Customers">
      <value value="100"/>
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
