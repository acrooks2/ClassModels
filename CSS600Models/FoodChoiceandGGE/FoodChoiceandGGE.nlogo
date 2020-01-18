globals [
  ;; the intial amounts of meals
  initial-sustainable-meals-0
  initial-nutritional-meals-0
  initial-traditional-meals-0

  ;; amounts of meals consumed
  sustainable-meals-consumed
  nutritional-meals-consumed
  traditional-meals-consumed    initial

  ;; total GHGEs
  total-ghg-emissions
  sustainable-ghg-emissions     ;; Subtotals
  nutritional-ghg-emissions     ;;
  traditional-ghg-emissions     ;;
]

;; the person only cares about the nutritional value of his meal
;; he will always choose the available meal of the highest nutritional value
breed [health-centric-persons health-centric-person]

;; the person only cares about the Global Warming Potential (GWP) of his meal
;; he will always choose the available meal of the lowest GWP
breed [environ-centric-persons environ-centric-person]

to setup
  clear-all
  setup-globals
  setup-people
  reset-ticks
end

to setup-globals
  set initial-sustainable-meals-0 initial-sustainable-meals
  set initial-nutritional-meals-0 initial-nutritional-meals
  set initial-traditional-meals-0 initial-traditional-meals
end

to setup-people
  set-default-shape turtles "person"
  crt initial-people
  [ setxy random-xcor random-ycor
    ifelse (random-float 1.0 < probability-eco-centric)
     [set breed environ-centric-persons
      set color green
     ]
     [set breed health-centric-persons
      set color sky - 2
     ]
  ]
end

;;
;;GO PROCEDURES
;;
to go
  ;; all available meals are eaten up, stop
  if (sustainable-meals-consumed = initial-sustainable-meals-0)
     and (nutritional-meals-consumed = initial-nutritional-meals-0)
     and (traditional-meals-consumed = initial-traditional-meals-0)
   [stop]
  ;; turtles choose to eat
  ask turtles [
    move
    eat
    ]
  tick
end

;;
;; GLOBAL PROCEDURES
;;
;; calculate GHGEs
to caculate-ghges
   ;; GHGEs
   set sustainable-ghg-emissions (unit-ghge-sustainable * sustainable-meals-consumed)
   set nutritional-ghg-emissions (unit-ghge-nutritional * nutritional-meals-consumed)
   set traditional-ghg-emissions (unit-ghge-traditional * traditional-meals-consumed)
   set total-ghg-emissions (sustainable-ghg-emissions + nutritional-ghg-emissions + traditional-ghg-emissions)
end

;;
;; TURTLE PROCEDURES
;;

;; Move - turtle
to move
  rt random-float 360
  fd 1
end

;;
;; Eat - turtle
;;
to eat
  ifelse breed = environ-centric-persons
    [eat-sustainably]
    [if breed = health-centric-persons
      [ eat-healthy ]
    ]
end

;;
;; Eat-sustainably - turtle
;;
to eat-sustainably
 ;; eat S first until it's eaten up
  if (initial-sustainable-meals-0 > 0) and (sustainable-meals-consumed < initial-sustainable-meals-0)
        [set sustainable-meals-consumed sustainable-meals-consumed + 1]

  ;; when S is eaten up and if unit-ghges: N < T, eat N
  if (sustainable-meals-consumed = initial-sustainable-meals-0) ;; S is eaten up
     and (unit-ghge-nutritional < unit-ghge-traditional) ;; N < T
      [
        if (initial-nutritional-meals-0 > 0) and (nutritional-meals-consumed < initial-nutritional-meals-0) ;; if N is still available
         [set nutritional-meals-consumed nutritional-meals-consumed + 1]
       ;;when N is eaten up, eat T until it's eaten up
       if (nutritional-meals-consumed = initial-nutritional-meals-0)  ;; N is eaten up
           and (initial-traditional-meals-0 > 0) and (traditional-meals-consumed < initial-traditional-meals-0) ;; T is still available
            [set traditional-meals-consumed traditional-meals-consumed + 1]
      ]

  ;; when S is eaten up and if unit-ghges N > T, eat T
  if (sustainable-meals-consumed = initial-sustainable-meals-0) ;; S is eaten up
     and (unit-ghge-nutritional > unit-ghge-traditional) ;; N > T
      [ if (initial-traditional-meals-0 > 0) and (traditional-meals-consumed < initial-traditional-meals-0)
              [set traditional-meals-consumed traditional-meals-consumed + 1]
           ;;when T is eaten up, eat N until it's eaten up
           if (traditional-meals-consumed = initial-traditional-meals-0) ;;T is eaten up
              and (initial-nutritional-meals-0 > 0) and (nutritional-meals-consumed < initial-nutritional-meals-0) ;; N is still available
                 [set nutritional-meals-consumed nutritional-meals-consumed + 1]
      ]

  ;; when S is eaten up and if unit-ghges N = T, eat N, T randomly until they are both eaten up
  if (sustainable-meals-consumed = initial-sustainable-meals-0) ;;S is eaten up
     and (unit-ghge-nutritional = unit-ghge-traditional) ;; N = T
     [
        ifelse (random 100 < 50)
         [ if (initial-traditional-meals-0 > 0)  and (traditional-meals-consumed < initial-traditional-meals-0) ;; T is still available
               [set traditional-meals-consumed traditional-meals-consumed + 1]
         ]
         [ if (initial-nutritional-meals-0 > 0) and (nutritional-meals-consumed < initial-nutritional-meals-0) ;; N is still available
               [set nutritional-meals-consumed nutritional-meals-consumed + 1]
         ]
      ]
end

;;
;; Eat-healthy - turtle
;;
to eat-healthy
  ;; eat N first until it's eaten up
  if (initial-nutritional-meals-0 > 0) and (nutritional-meals-consumed < initial-nutritional-meals-0)
    [set nutritional-meals-consumed nutritional-meals-consumed + 1]

    ;; when N is eaten up and if nutrition-value: S > T, eat S unitl it's eaten up
    if (nutritional-meals-consumed = initial-nutritional-meals-0) ;;N is eaten up
       and (nutritional-value-sustainable > nutritional-value-traditional) ;; S > T
    [
      if (initial-sustainable-meals-0 > 0) and (sustainable-meals-consumed < initial-sustainable-meals-0) ;; S is still available
            [set sustainable-meals-consumed sustainable-meals-consumed + 1]
      ;;when S is eaten up, eat T until it's eaten up
      if (sustainable-meals-consumed = initial-sustainable-meals-0) ;;S is eaten up
         and (traditional-meals-consumed < initial-traditional-meals-0) and (initial-traditional-meals-0 > 0) ;;T is still available
            [set traditional-meals-consumed traditional-meals-consumed + 1]
    ]

    ;; when N is eaten up and if nutrition-value: S < T, eat T
    if (nutritional-meals-consumed = initial-nutritional-meals-0) ;;N is eaten up
       and (nutritional-value-sustainable < nutritional-value-traditional) ;; S < T
    [
      if (initial-traditional-meals-0 > 0) and (traditional-meals-consumed < initial-traditional-meals-0) ;; T is available
            [set traditional-meals-consumed traditional-meals-consumed + 1]
       ;;when T is eaten up, eat S until it's eaten up
       if (traditional-meals-consumed = initial-traditional-meals-0) ;;T is eaten up
          and (initial-sustainable-meals-0 > 0) and (sustainable-meals-consumed < initial-sustainable-meals-0) ;;S is available
           [set sustainable-meals-consumed sustainable-meals-consumed + 1]
    ]

    ;; when N is eaten up and if nutrition-value S = T, eat S, T randomly until they are both eaten up
      if (nutritional-meals-consumed = initial-nutritional-meals-0) ;; N is eaten up
         and (nutritional-value-sustainable = nutritional-value-traditional) ;; S = T
      [  ifelse (random 100 < 50)
            [ if (initial-traditional-meals-0 > 0)  and (traditional-meals-consumed < initial-traditional-meals-0) ;; T is available
               [set traditional-meals-consumed traditional-meals-consumed + 1]
            ]
            [ if (initial-sustainable-meals-0 > 0) and (sustainable-meals-consumed < initial-sustainable-meals-0) ;;S is available
               [set sustainable-meals-consumed sustainable-meals-consumed + 1]
            ]
      ]
end

;;
;; MONITOR PROCEDURES
;;
;;1.sustainable meals consumed
to-report sustainable-meals-consumed-r
  report sustainable-meals-consumed
end

;;2.nutritional meals consumed
to-report nutritional-meals-consumed-r
  report nutritional-meals-consumed
end

;;3.traditional meals consumed
to-report traditional-meals-consumed-r
  report traditional-meals-consumed
end

;;4.sustainable meals' total emissions
to-report sustainanle-ghg-emissions-r
  set sustainable-ghg-emissions (unit-ghge-sustainable * sustainable-meals-consumed)
  report sustainable-ghg-emissions
end

;;5.nutritional meals' total emissions
to-report nutritional-ghg-emissions-r
  set nutritional-ghg-emissions (unit-ghge-nutritional * nutritional-meals-consumed)
  report nutritional-ghg-emissions
end

;;6.traditional meals' total emissions
to-report traditional-ghg-emissions-r
  set traditional-ghg-emissions (unit-ghge-traditional * traditional-meals-consumed)
  report traditional-ghg-emissions
end

;;7.total emissions
to-report total-ghg-emissions-r
  set total-ghg-emissions sum (list sustainable-ghg-emissions nutritional-ghg-emissions traditional-ghg-emissions)
  report total-ghg-emissions
end
@#$#@#$#@
GRAPHICS-WINDOW
966
10
1237
282
-1
-1
7.97
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
29
115
250
148
Initial-Sustainable-Meals
Initial-Sustainable-Meals
0
50000
49999.0
1
1
NIL
HORIZONTAL

BUTTON
522
46
588
79
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

BUTTON
605
46
668
79
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

SLIDER
259
116
480
149
Initial-Nutritional-Meals
Initial-Nutritional-Meals
0
50000
50000.0
1
1
NIL
HORIZONTAL

SLIDER
28
155
261
188
Initial-Traditional-Meals
Initial-Traditional-Meals
0
80000
50000.0
1
1
NIL
HORIZONTAL

CHOOSER
27
256
192
301
unit-ghge-sustainable
unit-ghge-sustainable
0.42
0

CHOOSER
27
307
192
352
unit-ghge-nutritional
unit-ghge-nutritional
1.3 4.7
0

CHOOSER
27
359
192
404
unit-ghge-traditional
unit-ghge-traditional
1.3 4.7
0

CHOOSER
206
257
400
302
nutritional-value-sustainable
nutritional-value-sustainable
2.75 3.98
0

CHOOSER
206
309
401
354
nutritional-value-nutritional
nutritional-value-nutritional
5.1
0

CHOOSER
206
361
401
406
nutritional-value-traditional
nutritional-value-traditional
2.75 3.98
0

MONITOR
514
109
706
154
Sustainable Meals Consumed
sustainable-meals-consumed-r
0
1
11

MONITOR
515
154
706
199
Nutritional Meals Consumed
nutritional-meals-consumed-r
0
1
11

MONITOR
706
108
901
153
Tradiational Meals Consumed
traditional-meals-consumed-r
0
1
11

MONITOR
950
361
1081
406
Total GHG Emissions
total-ghg-emissions-r
0
1
11

SLIDER
30
51
295
84
probability-eco-centric
probability-eco-centric
0
1.00
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
295
51
491
84
initial-people
initial-people
0
500
200.0
1
1
NIL
HORIZONTAL

MONITOR
950
406
1082
451
sustainanle-GHGEs
sustainanle-ghg-emissions-r
0
1
11

MONITOR
951
450
1083
495
nutritional-GHGEs
nutritional-ghg-emissions-r
0
1
11

MONITOR
949
495
1083
540
traditional-GHGEs
traditional-ghg-emissions-r
0
1
11

PLOT
428
243
950
540
GHG Emissions Over Time
time
GHGEs
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total GHGEs" 1.0 0 -13345367 true "" "plot total-ghg-emissions"
"sustainable" 1.0 0 -11085214 true "" "plot sustainable-ghg-emissions"
"nutritional" 1.0 0 -955883 true "" "plot nutritional-ghg-emissions"
"traditional" 1.0 0 -6459832 true "" "plot traditional-ghg-emissions"

MONITOR
951
317
1039
362
Time (Ticks)
ticks
0
1
11

@#$#@#$#@
## WHAT IS IT?

The Meals model is conceptual model to investigate the relationship between people's food choice and the total time of consumption of a given amount of meals associated with a given amount of greenhous gas emissions (GHGEs). The longer it takes for a number of people to consume all meals, the less GHGEs will be per a given amount of time.

## HOW IT WORKS

Inspired by the Cooperation model and previous works on the relationship between public health and climate change, this model has two key components: (1) two ranking systems and (2) two simple behavior rules, people’s eating preferences. They define the basic behavior of the model. Other components include: the meals (sustainable, nutritional, traditional) to represent the corresponding three types of food, two types of people, eco-centric and health-centric to reflect people’s eating preference, and GHGEs. 

In this model, the initial amounts of meals and people and the likelihood of a person being eco-centric are given by the model users. During a particular simulation run, people will consume one unit of meal per time tick according to their eating preferences and the availability of their desired meals at that time tick. Once a unit of meal is consumed, its GHGEs are calculated by multiplying the one unit with the unit GHGEs of that type of meals and added to its total emissions. The total GHGEs of this model are calculated by adding the three subtotals of the three types of meals. A plot shows how the three subtotals of GHGEs and total GHGEs change over time. Six monitors reflect the total amounts of each type of meals consumed and their associated total GHGEs. The model will stop when all meals have been consumed.

The core of this model is people’s eating preference. This preference is determined by the ranking systems and behavior rules:

Ranking Systems

The first ranking system is about the relative Global Warming Potential (GWP) of each type of meals measured by unit GHGEs. This model assumes that the sustainable meals will always have the lowest GWP while the nutritional and traditional meals may have equal or different but must have higher GWP than sustainable meals. Given the specific number of GWP, the GWP ranking of these meals could be determined. Under the previous assumption, only three different rankings are possible in this model (from lowest GWP to highest): (1) sustainable meals > nutritional meals > traditional meals; (2) sustainable meals > traditional meals > nutritional meals; (3) sustainable meals > traditional meals = nutritional meals.

In the model, three numbers: 0.42, 1.3, 4.6, are assigned as unit GHGEs, which in turn reflects GWP. These numbers come from Carlsson-Kanyama and González’s 2009 paper on the potential contributions of food consumption patterns to climate change to make them more realistic since unit GHGEs will be used to calculate the total GHGEs later on. However, these numeric values don’t really matter in this model. For one thing, the numbers are mainly used to determine the GWP ranking of the three meals so the specific value doesn’t matter as long as the GWP ranking can be determined. For the other, even though unit GHGEs will be used to calculate total GHGEs, the model is quite conceptual so any number of unit GHGEs will work.
The second ranking system is about the relative nutritional value of each type of meals. Similar to the GWP ranking system, this model assumes that nutritional meals will always have the highest nutritional value while sustainable meals and traditional meals may have equal or different nutritional values but must have lower nutritional values than nutritional meals. Under this assumption, only three nutritional value rankings are possible: (1) nutritional meals > sustainable meals > traditional meals; (2) nutritional meals > traditional meals > sustainable meals; (3) nutritional meals > traditional meals = sustainable meals. The same as the GWP ranking system, three numbers are assigned: 2.75, 3.98, 5.1. These numbers are totally arbitrary since their only function is to determine the rank.

Behavior Rules

Two separate behavior rules are applied to agents: (1) eat-healthy and (2) eat-sustainably. Health-centric people will only eat healthy and eco-centric people will only eat sustainably.

The eat-healthy rule means that health-centric people will only eat the most nutritious meals available. That is if nutritional meals are available, they will eat nutritional meals until the meals are eaten up. Then they will eat the next nutritional meals available until these meals are also eaten up. Their least choice will be the least nutritional meals. If the other two are no longer available, they will eat these meals until they are eaten up. If the rest two meals have equal nutritional values, these people will eat them random until eat them up.

The eat-sustainably rule is similar to the eat-healthy rule but refer to the GWP ranking system. Eco-centric people will only eat the most sustainable meals available. In this model, these meals will always be the sustainable meals. So they will always eat sustainable meals first and after they eat them up, they will look at other meals. If the other meals have different GWP, they will eat the one with lower GWP first and then the remaining one. If the other meals have equal GWP, they will eat these meals randomly.


## HOW TO USE IT

(1) Choose a value for PROBABILITY-ECO-CENTRIC, the probability of a person being eco-centric
(2) Choose a value for INITIAL-PEOPLE
(3) Choose the initial amount of each type of meals: INITIAL-SUSTAINANBLE-MEALS,INITIAL-NUTRITIONAL-MEALS, INITIAL-TRADITIONAL-MEALS
(4) Determine the unit GHGEs and nutritional values for each type of meals

## THINGS TO NOTICE

(1) The time ticks per simulation run
(2) The shapes of curves and the relationships between curves in the plot: "GHG Emissions over Time"

## THINGS TO TRY

(1) Try different values of PROBABILITY-ECO-CENTRIC
(2) Try different combination of all meals' unit GHGEs and nutritional values
(3) Try different combination of amounts of each type of meals
(4) Try to vary the ratio of number of people and amounts of meals


## EXTENDING THE MODEL

(1) Add more complex behvavior rules
(2) Add more features of meals and more complex ranking systems

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

Cooperation

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
  <experiment name="1. SNT + NST" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="3.98"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-environ-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="4.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="2. SNT + NTS" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="3.98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="2.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-environ-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="4.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="3. SNT + NT=S (2.75)" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="2.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-eco-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="4.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="5. STN + NTS" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="3.98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="2.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-environ-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="1.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="6. STN + NT=S (2.75)" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="2.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-eco-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="1.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="7. ST=N (1.3) + NST" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="3.98"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-eco-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="1.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="8. ST=N (1.3) + NTS" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="3.98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="2.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-eco-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="1.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="9. ST=N (1.3) + NT=S (2.75)" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="2.75"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-eco-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="1.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="snt nst test" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <metric>sustainable-ghg-emissions</metric>
    <metric>nutritional-ghg-emissions</metric>
    <metric>traditional-ghg-emissions</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="3.98"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="probability-environ-centric">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="4.7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="4. STN + NST" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="nutritional-value-traditional">
      <value value="2.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-people">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Sustainable-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-sustainable">
      <value value="0.42"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Nutritional-Meals">
      <value value="30000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-nutritional">
      <value value="5.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial-Traditional-Meals">
      <value value="50000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nutritional-value-sustainable">
      <value value="3.98"/>
    </enumeratedValueSet>
    <steppedValueSet variable="probability-environ-centric" first="0" step="0.1" last="1"/>
    <enumeratedValueSet variable="unit-ghge-nutritional">
      <value value="4.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unit-ghge-traditional">
      <value value="1.3"/>
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
