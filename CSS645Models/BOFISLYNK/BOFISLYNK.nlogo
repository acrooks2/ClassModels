;; BOATS and FISH interactions Agent-Based Modelling: A tool for Fisheries Management
;;                          BOFISLYNK


globals [boat1_count boat2_count boat3_count fish_count ]
;; boat and fish are both breeds of turtle.
breed [boat1 boat1s]
breed [boat2 boat2s]
breed [boat3 boat3s]
breed [fish fishes]
 boat1-own [Running_cost_boat1 additional_fuel1 fish_caught1] ;; running cost = operating cost - other expenses
 boat2-own [Running_cost_boat2 additional_fuel2 fish_caught2]
 boat3-own [Running_cost_boat3 additional_fuel3 fish_caught3]
      ;; boats have operating cost

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;SET UP;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches [ set pcolor blue ]
  set-default-shape boat1 "boat"
   create-boat1 Initial_count_boat1
      [set color red
    set size 1.75  ;;

    setxy random-xcor random-ycor
    set Running_cost_boat1 (Operating_cost_boat1 * (Percentage_running_cost_boat1 / 100))]

  set-default-shape boat2 "boat"
   create-boat2 Initial_count_boat2
      [set color yellow
    set size 1.5  ;;

    setxy random-xcor random-ycor
     set Running_cost_boat2 (Operating_cost_boat2 * Percentage_running_cost_boat2 / 100)]

  set-default-shape boat3 "boat"
   create-boat3 Initial_count_boat3
      [set color green
    set size 1.25  ;;

    setxy random-xcor random-ycor
    set Running_cost_boat3 (Operating_cost_boat3 * Percentage_running_cost_boat3 / 100)]

  set-default-shape fish "fish"
   create-fish Initial_count_fish  ;; create the fishes, then initialize their variables
    [set color brown
    set size 0.75  ;;
    setxy random-xcor random-ycor]

  do-plots

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;TO GO ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  if ticks >= 500 [ stop ]  ;; stop after 500 ticks

   ask boat1
     [move_boat1
     spend_fuel_boat1
     catch_boat1-fish
     get_fuel_boat1
     stay_boat1
     leave_boat1
     increase_boat1]

   ask boat2
      [move_boat2
      spend_fuel_boat2
      catch_boat2-fish
      get_fuel_boat2
      stay_boat2
      leave_boat2
      increase_boat2]

   ask boat3
     [move_boat3
      spend_fuel_boat3
      catch_boat3-fish
      get_fuel_boat3
      stay_boat3
      leave_boat3
      increase_boat3]

    ask fish[move_fish reproduce-fish]
tick
  do-plots

end

;;;;;;;;;;;;;;;;;;;;;;;;;;FISH PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


 to move_fish
      ask fish [right random 360 forward 0.5]
   end

   to reproduce-fish
      set fish_count Initial_count_fish  + Initial_count_fish * Reproduction_rate / 1000
      move_fish
   end



 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;BOATS PROCEDURES;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 to move_boat1
  ask boat1 [right random 360 forward 3]
 end

to spend_fuel_boat1
 ask boat1 [set Running_cost_boat1 Running_cost_boat1 - Running_cost_boat1 /  trip_length_boat1];; fuel is spent as the boat moves
 end

 to catch_boat1-fish  ;;
  ask boat1 [set fish_caught1 fish in-radius 0.3  ask fish_caught1 [die]];; fish in circle of radius 0.3 is caught
 end

 to get_fuel_boat1
  ask boat1 [set additional_fuel1 cost_one_fish * count fish_caught1];; fish caught is priced and used as fuel
 end


 to stay_boat1
 every trip_length_boat1
  [ask boat1 [if additional_fuel1 = Running_cost_boat1 [move_boat1]  ]] ;; stay in business if fish catch is enough to cover running cost at the end of fishing trip
 end

 to leave_boat1
  every trip_length_boat1
  [ask boat1 [if additional_fuel1 < Running_cost_boat1 [die]] ]    ;; boat leaves business if not enough fish is caught at the end of fishing trip
  end

 to increase_boat1
   every trip_length_boat1
   [ask boat1 [if additional_fuel1 > Operating_cost_boat1 + Running_cost_boat1 [hatch 100]]]    ;; additional boat gets into the business if more than enough fish is caught at the end of fishing trip
 end


;;;;;;;;;;;;;;;;;;;;;
  to move_boat2
  ask boat2 [right random 360 forward 2]
 end

 to spend_fuel_boat2
  ask boat2 [set Running_cost_boat2 Running_cost_boat2 - Running_cost_boat2 /  trip_length_boat2]
 end

 to catch_boat2-fish  ;;
  ask boat2 [set fish_caught2 fish in-radius 0.1   ask fish_caught2 [die]]
 end

 to get_fuel_boat2
  ask boat2 [set additional_fuel2 cost_one_fish * count fish_caught2]
 end ;; get money for fuel by catching fish


 to stay_boat2
 every  trip_length_boat2
  [ ask boat2 [if additional_fuel2 = Running_cost_boat2 [move_boat2]  ]] ;; stay in business if fish catch is enough to cover running cost
 end

 to leave_boat2
  every  trip_length_boat2
  [ask boat2 [if additional_fuel2 < Running_cost_boat2 [die]]]      ;; boat leaves business if not enough fish is caught at the end of fishing trip
  end

 to increase_boat2
   every trip_length_boat2
   [ask boat2 [if additional_fuel2 > Operating_cost_boat2 + Running_cost_boat2 [hatch 1]]]    ;; additional boat gets
    ;; into the business if more than enough fish is caught at the end of fishing trip
 end


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 to move_boat3
  ask boat3 [right random 360 forward 1]
 end

 to spend_fuel_boat3
  ask boat3 [set Running_cost_boat3 Running_cost_boat3 - Running_cost_boat3 /  trip_length_boat3]
 end

 to catch_boat3-fish  ;;
  ask boat3 [set fish_caught3 fish in-radius 0.05   ask fish_caught3 [die]]
 end

 to get_fuel_boat3
  ask boat3 [set additional_fuel3 cost_one_fish * count fish_caught3]
 end ;; get money for fuel by catching fish


 to stay_boat3
 every  trip_length_boat3
  [ ask boat3 [if additional_fuel3 = Running_cost_boat3 [move_boat3]  ]] ;; stay in business if fish catch is enough to cover running cost
 end

 to leave_boat3
  every  trip_length_boat3
  [ask boat3 [if additional_fuel3 < Running_cost_boat3 [die]]]      ;; boat leaves business if not enough fish is caught at the end of fishing trip
  end

 to increase_boat3
   every trip_length_boat3
   [ask boat3 [if additional_fuel3 > Operating_cost_boat3 + Running_cost_boat3 [hatch 1]]]    ;; additional boat gets
    ;; into the business if more than enough fish is caught at the end of fishing trip
 end




   ;;;;;;;;;;;;;;;;;;;;;;;;;;;PLOTS ;;;;;

   to do-plots
  set-current-plot "Totals" ;;
  set-current-plot-pen "boat1" ;;
  plot count boat1
 set boat1_count count boat1
  set-current-plot-pen "boat2" ;;
  plot count boat2
 set boat2_count count boat2
  set-current-plot-pen "boat3" ;;
  plot count boat3 ;;
 set boat3_count count boat3
  set-current-plot-pen "fish" ;;
  plot count fish ;;
end

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;






@#$#@#$#@
GRAPHICS-WINDOW
354
26
857
530
-1
-1
15.0
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
32
40
95
73
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
122
41
185
74
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

MONITOR
879
99
971
144
Count Boat1
boat1_count
17
1
11

MONITOR
975
99
1067
144
Count Boat2
boat2_count
17
1
11

MONITOR
1073
99
1165
144
Count Boat3
boat3_count
17
1
11

MONITOR
984
154
1063
199
Count fish
fish_count
17
1
11

SLIDER
109
85
281
118
Initial_count_fish
Initial_count_fish
0
40
16.0
1
1
NIL
HORIZONTAL

SLIDER
23
188
251
221
Operating_cost_boat1
Operating_cost_boat1
10000
100000
0.0
10000
1
dollar
HORIZONTAL

SLIDER
20
330
241
363
Operating_cost_boat2
Operating_cost_boat2
10000
50000
10000.0
10000
1
dollar
HORIZONTAL

SLIDER
-3
466
212
499
Operating_cost_boat3
Operating_cost_boat3
1000
5000
1000.0
1000
1
dollar
HORIZONTAL

SLIDER
23
155
195
188
Initial_count_boat1
Initial_count_boat1
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
20
298
192
331
Initial_count_boat2
Initial_count_boat2
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
-1
434
171
467
Initial_count_boat3
Initial_count_boat3
0
10
1.0
1
1
NIL
HORIZONTAL

PLOT
939
247
1139
397
Totals
time
Agents
0.0
300.0
0.0
40.0
true
true
"" ""
PENS
"Boat1" 2.0 0 -2674135 true "" ""
"Boat2" 1.0 0 -2064490 true "" ""
"Boat3" 1.0 0 -10899396 true "" ""
"Fish" 1.0 0 -6459832 true "" ""

TEXTBOX
973
407
1123
435
Fishing industries versus fish population dynamics
11
0.0
0

SLIDER
110
119
287
152
Reproduction_rate
Reproduction_rate
0
42
5.0
1
1
%0
HORIZONTAL

SLIDER
23
221
195
254
Trip_length_boat1
Trip_length_boat1
0
15
1.0
1
1
NIL
HORIZONTAL

SLIDER
21
362
193
395
Trip_length_boat2
Trip_length_boat2
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
-1
498
171
531
Trip_length_boat3
Trip_length_boat3
0
5
1.0
1
1
NIL
HORIZONTAL

SLIDER
23
253
270
286
Percentage_running_cost_boat1
Percentage_running_cost_boat1
0
100
14.0
1
1
%
HORIZONTAL

SLIDER
21
395
268
428
Percentage_running_cost_boat2
Percentage_running_cost_boat2
0
100
7.0
1
1
%
HORIZONTAL

SLIDER
-1
529
246
562
Percentage_running_cost_boat3
Percentage_running_cost_boat3
0
100
1.0
1
1
%
HORIZONTAL

SLIDER
304
43
337
193
cost_one_fish
cost_one_fish
500
2000
0.0
100
1
NIL
VERTICAL

@#$#@#$#@
## WHAT IS IT?

The model is exploring the interaction between fishing boats and fish in the marine environment.

## HOW IT WORKS

Three types of boats are considered in this model to represent the different scenarios that involve fishing activities. The boats differ in size, fishing capacity and speed. They also differ in operating costs,from which the running costs are computed based on  a percentage, which is set by the user. The boats navigate randomly in the marine environment, catch fish as they move and spend fuel in doing so. The cost of fuel is the running cost of the fishing boat. The operating cost of the boat includes the running cost and other expenses (labor, insurance, boat payment, etc) and is paid from selling the harvested fish.
-fishing boat1 type is the biggest,can catch fish in radius of 0.3 and has
the longest range of fishing trips (also set by the user). Fishing boats therefore need fish to stay in business. They have to leave the business if they do not get enough fish and may also increase in number if they get enough to cover the operating cost and additional running cost. They leave the ports with full tank (fuel tank). In the model, a test is given to each boat at every end of the boat trip to see if they stay in business or leave or if their shipowner decide to add more boats depending on the fish harvested.
The fish navigate randomly in the marine environment. They reproduce based on the reproduction rate set by the user. They are caught by the fishing boats and die. The maximum reproduction rate of fish is considered the one in marine reserve; 446% in 15 years.

## HOW TO USE IT

The user is given the option to enter the data on sliders to capture the initial count of fish and the reproduction rate.
The data regarding the boats can also be entered by the user by the use of the sliders.
The sliders for the boats include:
-Number of boats
-Operating cost
-Percentage of running cost from the operating cost
-Length of fishing trip
The sliders for the fish include:
-Initial number of fish
-Reproduction rate
The command setup sets the original data entered by the user on the screen at time 0. When the command go is activated, the model is running.
Plots are available to show the change in the count of fish and fishing boats over time. It is possible to capture the counts of the boats and fish on the monitors.

## THINGS TO NOTICE

The count of fish diminishes much faster as many ships are operated. The ships also decrease in number when there are no longer fish to catch.
The reproduction rate of fish plays an important role in maintaining fish population but the reproduction on a daily basis is not significant


## THINGS TO TRY

By taking the extremes of each slider, the user should take notice of the change in number of the fish population and the fishing boats. As an example, if the number of fish is taken to the highest extreme, high number of fishing boats can stay in business and may even grow in number. When very small of fish is available, fishing boats cannot survive and leave the business. There may also be a difference if the fish production rate is pushed to the high extreme with regard to the sustainability of the fishing acitivities as fish population grows faster (the equivalent of a reproduction rate in marine reserve)

## EXTENDING THE MODEL

Improving spatial component of the model by the use of GIS may provide more accurate output as locations of the different interactions may be illustrated and analyzed when the program is applied to a particular marine area

## NETLOGO FEATURES

The provision of fish population should be the result of prior study of the area to be considered. The range in fish reproduction gives the user a broad choice in this matter, but that choice needs to be defined beforehand through research to provide more accurate output.

## RELATED MODELS

Not yet defined.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

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
