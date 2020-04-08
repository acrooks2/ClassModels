;;References and Acknowledgement

;;https://simulatingcomplexity.wordpress.com/2014/08/20/turtles-in-space-integrating-gis-and-netlogo/
;;https://groups.yahoo.com/neo/groups/netlogo-users/conversations/topics/8215
;;http://stackoverflow.com/questions/22967983/how-to-use-the-primitive-patch-right-and-ahead-when-the-world-wrapping-is-disa
;;http://netlogo-users.18673.x6.nabble.com/To-random-kill-turtles-td5003842.html
;;http://netlogo-users.18673.x6.nabble.com/checking-each-values-in-patch-list-against-turtle-list-td5004719.html
;https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=checkk%20if%20a%20turtle%20is%20within%20distance%20of%20another%20turtle%20netlogo
;http://stackoverflow.com/questions/26187573/test-the-color-of-patches-in-a-radius
;http://stackoverflow.com/questions/3571141/netlogo-runtime-error-turtles-on
;https://ccl.northwestern.edu/netlogo/2.0/docs/dictionary.html#and
;http://netlogo-users.18673.x6.nabble.com/random-number-between-two-extremes-td4863647.html
;http://netlogo-users.18673.x6.nabble.com/getting-player-turtle-to-face-mouse-xcor-ycor-td4868302.html
;http://stackoverflow.com/questions/24786908/get-mean-heading-of-neighboring-turtles
;http://stackoverflow.com/questions/23015625/netlogo-finding-the-average-value-of-a-set-of-turtles



extensions [ gis csv ]
globals [
  roads

  number-riders-picked
  number-riders-picked-per-turn
  average-number-riders-picked-per-turn

  number-passengers-dropped
  number-passengers-dropped-per-turn
  average-number-passengers-dropped-per-turn
  pickup-count-average
  dropoff-count-average

  number-riders-gave-up
  number-drivers-who-gave-up
  number-of-riders-who-gave-up-per-turn
  number-of-drivers-who-gave-up-per-turn
  average-number-riders-gave-up-per-turn

  average-energy-level
  average-distance-travelled-passenger
  average-distance-wout-passenger

  average-cash
  number-passengers-in-ride
  average-wait-time-riders

  total-cash
  profit

  turn
  ]

breed [riders rider ]
breed [drivers driver]
patches-own [district-name population road-here]
drivers-own [energy cash minutes-driven driver-destination passenger-carry riders-nearby passenger-id time-in-ride nearby-drivers pickup-count dropoff-count]
riders-own [wait-time rider-destination]

to setup
  clear-all
  reset-ticks
  gis:load-coordinate-system (word "Data/Roads_ALL.prj")
  set roads gis:load-dataset "Data/Roads_all.shp"
  gis:set-world-envelope (gis:envelope-union-of(gis:envelope-of roads))

  draw
  load_drivers
  load-riders
  if scenario = "Saturday" [scenario-saturday]
  set number-riders-gave-up 0
  set number-riders-picked 0


end

to go
  if scenario = "Saturday" [scenario-saturday]
  move
  tick
  set turn turn + 1
  if one-day and turn = 1440 ; one day simulation
  [stop]
end


to move

  if move-method = "random-local" [random-move-drivers]
  if move-method = "normal-random-local-move" [destination-move]
  if move-method = "voronoi-move" [voronoi-move]
  random-create-riders
  random-create-drivers
  if kill-switch [random-kill-turtles]
  pick-up
  drop-off
  time-count-adjustments
end

to draw

  ask patches [set pcolor black]
  gis:set-drawing-color brown
  gis:draw roads 1

  ask patches
  [if gis:intersects? roads self [set road-here 1]]
end

to load_drivers

  clear-turtles
  let tralight gis:find-features roads "FEATURECOD" "INTERSECTION"
  let tralight-random n-of drivers-count tralight

  let random-number-of-drivers int random-normal drivers-count (drivers-count / 7)

  foreach tralight-random
  [ ?1 -> let centroid gis:location-of gis:centroid-of ?1
    if (not empty? centroid) and ( count turtles < random-number-of-drivers)
    [if random-normal 1 1 > 0.5
      [create-drivers 1
      [set xcor item 0 centroid
        set ycor item 1 centroid
        set size 0.75
        set shape "car"
        set energy random-normal 360 120
        set color red
        ;set label-color black
        ]]] ]
end

to load-riders

  let tralight gis:find-features roads "FEATURECOD" "INTERSECTION"
  let tralight-random n-of riders-per-time-unit tralight

  let random-number-of-riders int random-normal riders-per-time-unit (riders-per-time-unit / 7)

  let possible-destinations gis:find-features roads "FEATURECOD" "INTERSECTION"
  let random-destination n-of 1 possible-destinations

  foreach tralight-random
  [ ?1 -> let centroid gis:location-of gis:centroid-of ?1
    if (not empty? centroid) and ( count riders < riders-per-time-unit) ;;and (random-normal 1 1 < 0.5)
    [if random-normal 1 1 > 0.5
      [create-riders 1
      [set xcor item 0 centroid
        set ycor item 1 centroid
        set size 1.5
        set shape "person"
        set color yellow
        set rider-destination random-destination
        ;set label-color black
        ]]] ]
end

to random-move-drivers ;; This function is just a test function and should not be used.
  ask drivers [
    rt random 360
    ;if road-here = 1 [fd 1]]
    let target-patch patch-ahead local-regional-scale
    ifelse target-patch != nobody and [road-here] of target-patch = 1
    [move-to target-patch] [rt random -360]
  ]
end

to random-create-drivers

  let tralight gis:find-features roads "FEATURECOD" "INTERSECTION"

  let driver-count-difference drivers-count - count drivers
  if driver-count-difference < 0 [set driver-count-difference 0]

  let tralight-random n-of driver-count-difference tralight

  let random-number-of-drivers (random driver-count-difference)
  let tralight-random-set n-of random-number-of-drivers tralight-random

  foreach tralight-random-set
  [ ?1 -> let centroid gis:location-of gis:centroid-of ?1
    if (not empty? centroid) and ( count riders < drivers-count) ;;and (random-normal 1 1 < 0.5)
    [if random-normal 1 1 > 0.5
      [create-drivers 1
      [set xcor item 0 centroid
        set ycor item 1 centroid
        set size .75
        set shape "car"
        set energy random-normal 360 120
        set color red
        ;set label-color black
        ]]] ]
end

to random-create-riders

  let tralight gis:find-features roads "FEATURECOD" "INTERSECTION"

  let rider-count-difference riders-per-time-unit - count riders
  if rider-count-difference < 0 [set rider-count-difference 0]

  let tralight-random n-of rider-count-difference tralight

  let random-number-of-riders (random rider-count-difference)
  let tralight-random-set n-of random-number-of-riders tralight-random

  let possible-destinations gis:find-features roads "FEATURECOD" "INTERSECTION"
  let random-destination n-of 1 possible-destinations

  foreach tralight-random-set
  [ ?1 -> let centroid gis:location-of gis:centroid-of ?1
    if (not empty? centroid) and ( count riders < riders-per-time-unit) ;;and (random-normal 1 1 < 0.5)
    [if random-normal 1 1 > 0.5
      [create-riders 1
      [set xcor item 0 centroid
        set ycor item 1 centroid
        set size 1.0
        set shape "person"
        set color yellow
        set rider-destination random-destination
        ;set label-color black
        ]]] ]
end

to random-kill-turtles

  let random-kill-count abs random-normal 0 1

  if random-kill-count < count riders
  [ask n-of random-kill-count riders [die]
    set number-riders-gave-up number-riders-gave-up + random-kill-count
    set number-of-riders-who-gave-up-per-turn random-kill-count
    ]

  let drivers-with-no-riders drivers with [passenger-carry = 0]

  if random-kill-count < count drivers-with-no-riders
  [let drivers-who-die n-of random-kill-count drivers-with-no-riders
   ask drivers-who-die
    [ set profit profit + (sum [cash] of drivers-who-die)
      die]]

    set number-drivers-who-gave-up number-drivers-who-gave-up + random-kill-count
    set number-of-drivers-who-gave-up-per-turn random-kill-count


end

to pick-up
  let last-turn-pick number-riders-picked
  ask drivers [
  set riders-nearby one-of riders in-radius 2
  if (passenger-carry = 0) and (riders-nearby != nobody)
  [
    set passenger-id [who] of riders-nearby
    set passenger-carry 1
    set color white
    set driver-destination [rider-destination] of riders-nearby
    set pickup-count pickup-count + 1
    set cash cash + 3.65

    set number-riders-picked number-riders-picked + 1

    ask riders-nearby [die]
  ]
  ]
  set number-riders-picked-per-turn number-riders-picked - last-turn-pick
  set average-number-riders-picked-per-turn ((average-number-riders-picked-per-turn + number-riders-picked-per-turn) / 2) ; This is the running average
end

to destination-move

  ask drivers
  [
    ifelse passenger-carry = 1
    [
      foreach driver-destination
      [ ?1 ->
        let centroid gis:location-of gis:centroid-of ?1
        let xcoo item 0 centroid
        let ycoo item 1 centroid
        facexy xcoo ycoo
        ]

      let target-patch patch-ahead local-regional-scale

      ifelse target-patch != nobody and [road-here] of target-patch = 1
      [fd local-regional-scale]

      [
        rt (-45 + (random 90))
        let new-target-patch patch-ahead local-regional-scale
        if target-patch != nobody and [road-here] of target-patch = 1
        [fd local-regional-scale]
        ]
      ]
    [
      ;ask drivers [
        rt random 360
        ;if road-here = 1 [fd 1]]
        let target-patch patch-ahead local-regional-scale
        ifelse target-patch != nobody and [road-here] of target-patch = 1
        [fd local-regional-scale] [rt random -360]
        ;]
      ]
    ]
end

to voronoi-move
    ask drivers
  [
    ifelse passenger-carry = 1
    [
      foreach driver-destination
      [ ?1 ->
        let centroid gis:location-of gis:centroid-of ?1
        let xcoo item 0 centroid
        let ycoo item 1 centroid
        facexy xcoo ycoo
        ]

      let target-patch patch-ahead local-regional-scale

      ifelse target-patch != nobody and [road-here] of target-patch = 1
      [fd local-regional-scale]

      [
        rt (-45 + (random 90))
        let new-target-patch patch-ahead local-regional-scale
        if target-patch != nobody and [road-here] of target-patch = 1
        [fd local-regional-scale]
        ]
      ]
    [
     set nearby-drivers other drivers with [ distance myself < voronoi-vision]
    if count nearby-drivers = 0
    [
      rt random 360
        ;if road-here = 1 [fd 1]]
        let target-patch patch-ahead local-regional-scale
        ifelse target-patch != nobody and [road-here] of target-patch = 1
        [fd local-regional-scale] [rt random -360]
    ]

    if count nearby-drivers = 1
    [
      let random-driver one-of nearby-drivers
      face random-driver
      rt 180
      let target-patch patch-ahead local-regional-scale
      ifelse target-patch != nobody and [road-here] of target-patch = 1
      [fd local-regional-scale] [rt (-10 + random 20)]]

    if count nearby-drivers > 1
    [
      let random-driver one-of nearby-drivers
      face random-driver
      rt 180
      let target-patch patch-ahead local-regional-scale
      ifelse target-patch != nobody and [road-here] of target-patch = 1
      [fd local-regional-scale] [rt (-10 + random 20)]

      ]
      ]
      ]
end

to time-count-adjustments
  let last-turn-gave-up number-riders-gave-up
    ask riders
  [
    if any? riders
    [set wait-time wait-time + 1
    if wait-time > max-wait-time [
      die
      ;set number-riders-gave-up number-riders-gave-up + 1
      ;set number-of-riders-who-gave-up-per-turn (number-of-riders-who-gave-up-per-turn + (number-riders-gave-up - last-turn-gave-up))
      ;set average-number-riders-gave-up-per-turn ((average-number-riders-gave-up-per-turn + number-of-riders-who-gave-up-per-turn) / 2)
      ]

    ;set number-riders-gave-up number-riders-gave-up + random-kill-count <- just for reference from random kill function
    ;set number-of-riders-who-gave-up-per-turn random-kill-count <- just for reference from random kill function
    ]
  ]

 ask drivers
 [
   ifelse passenger-carry = 1
   [
     set time-in-ride time-in-ride + 1
     set cash cash + 0.60
     set energy energy - 0.75
     set minutes-driven minutes-driven + 1
     set nearby-drivers other drivers with [ distance myself < 3]
     if energy <= 0
     [die]
     if time-in-ride > 90
     [die]
   ]
   [ set time-in-ride 0
     set energy energy - 1
     set cash cash - 0.1
     set minutes-driven minutes-driven + 1
     set nearby-drivers other drivers with [ distance myself < 3]
     if energy <= 0
     [ set profit profit + cash
       die]
   ]
   set total-cash sum [cash] of drivers
 ]

 if any? drivers
 [set average-energy-level mean [energy] of drivers
  set pickup-count-average mean [pickup-count] of drivers
  set dropoff-count-average mean [dropoff-count] of drivers
  set average-cash mean [cash] of drivers
  set number-passengers-in-ride sum [passenger-carry] of drivers
 ]


 if any? riders
 [set average-wait-time-riders mean [wait-time] of riders]

end

to drop-off
  let last-turn-drop number-passengers-dropped
  ask drivers[
     if passenger-carry = 1
    [
      foreach driver-destination
      [ ?1 ->
        let centroid gis:location-of gis:centroid-of ?1
        let xcoo item 0 centroid
        let ycoo item 1 centroid


    if (distancexy xcoo ycoo < 2)[

      set driver-destination 0
      set passenger-carry 0
      set passenger-id 0
      set time-in-ride 0
      set number-passengers-dropped number-passengers-dropped + 1
      set dropoff-count dropoff-count + 1
      set color red
    ]
    ]
    ]

  ]
  set number-passengers-dropped-per-turn number-passengers-dropped - last-turn-drop
  set average-number-passengers-dropped-per-turn ((average-number-passengers-dropped-per-turn + number-passengers-dropped-per-turn) / 2) ; This is the running average
end

to scenario-saturday

  if turn = 0
  [
  set drivers-count 10
  set riders-per-time-unit 5]

    if turn = 180
  [
  set drivers-count 20
  set riders-per-time-unit 10]
    if turn = 360
  [
  set drivers-count 50
  set riders-per-time-unit 20]
    if turn = 420
  [
  set drivers-count 50
  set riders-per-time-unit 10]
    if turn = 510
  [
  set drivers-count 45
  set riders-per-time-unit 25]
    if turn = 570
  [
  set drivers-count 50
  set riders-per-time-unit 15]
    if turn = 630
  [
  set drivers-count 25
  set riders-per-time-unit 10]
    if turn = 750
  [
  set drivers-count 40
  set riders-per-time-unit 5]
    if turn = 810
  [
  set drivers-count 45
  set riders-per-time-unit 5]
    if turn = 870
  [
  set drivers-count 60
  set riders-per-time-unit 30]
    if turn = 930
  [
  set drivers-count 80
  set riders-per-time-unit 40]
    if turn = 990
  [
  set drivers-count 100
  set riders-per-time-unit 40]
    if turn = 1050
  [
  set drivers-count 90
  set riders-per-time-unit 10]
    if turn = 1110
  [
  set drivers-count 80
  set riders-per-time-unit 10]
    if turn = 1170
  [
  set drivers-count 75
  set riders-per-time-unit 30]
    if turn = 1260
  [
  set drivers-count 65
  set riders-per-time-unit 30]
    if turn = 1380
  [
  set drivers-count 35
  set riders-per-time-unit 10]


end
@#$#@#$#@
GRAPHICS-WINDOW
299
15
1042
759
-1
-1
12.05
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
minutes
30.0

BUTTON
5
14
99
57
Setup
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
124
20
204
54
Go Once
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

BUTTON
219
19
282
52
go
Go
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
7
80
180
113
drivers-count
drivers-count
0
200
10.0
1
1
NIL
HORIZONTAL

SLIDER
7
130
180
163
riders-per-time-unit
riders-per-time-unit
0
200
5.0
1
1
NIL
HORIZONTAL

MONITOR
1077
10
1249
55
Time (1 Minute Increments)
ticks
0
1
11

MONITOR
1078
68
1158
113
# of Drivers
count drivers
17
1
11

MONITOR
1174
68
1317
113
# of Hailing Riders
count riders
17
1
11

SLIDER
6
176
179
209
max-wait-time
max-wait-time
0
30
20.0
1
1
NIL
HORIZONTAL

PLOT
1056
122
1340
242
Driver Rider Count
Time
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"Total Drivers" 1.0 0 -16777216 true "" "plot count drivers"
"Total Riders" 1.0 0 -2674135 true "" "plot count riders"

PLOT
1056
242
1344
362
Working/Idle Drivers
Time
Number of Drivers
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Busy Driver" 1.0 0 -16777216 true "" "plot count drivers with [passenger-carry = 1]"
"Idle Drivers" 1.0 0 -2674135 true "" "plot count drivers with [passenger-carry = 0]"

CHOOSER
6
222
201
267
move-method
move-method
"random-local" "normal-random-local-move" "voronoi-move"
1

SWITCH
8
286
121
319
kill-switch
kill-switch
0
1
-1000

SLIDER
5
341
177
374
voronoi-vision
voronoi-vision
0
20
3.0
1
1
NIL
HORIZONTAL

SLIDER
6
394
178
427
local-regional-scale
local-regional-scale
0
2
0.5
0.1
1
NIL
HORIZONTAL

PLOT
1058
364
1343
484
Number of Agents Who Gave Up
Time
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Riders" 1.0 0 -13840069 true "" "plot number-of-riders-who-gave-up-per-turn"
"Drivers" 1.0 0 -13345367 true "" "plot number-of-drivers-who-gave-up-per-turn"

MONITOR
1264
10
1398
55
Total Riders Giving Up
number-riders-gave-up
0
1
11

MONITOR
1418
10
1557
55
Total Drivers Giving Up
number-drivers-who-gave-up
0
1
11

PLOT
1347
121
1665
241
Riders Picked Up &  Dropped Off
Turn
Picked/Dropped This Turn
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Average Pickups" 1.0 0 -13840069 true "" "plot pickup-count-average"
"Average Dropoffs" 1.0 0 -955883 true "" "plot dropoff-count-average"

MONITOR
1359
65
1522
110
Total # of Riders Picked Up
number-riders-picked
0
1
11

MONITOR
1571
10
1712
55
NIL
average-number-riders-picked-per-turn
0
1
11

MONITOR
1541
65
1744
110
Total Dropoffs 
number-passengers-dropped-per-turn
0
1
11

PLOT
1348
243
1663
363
Average Cash
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Driver Cash" 1.0 0 -13791810 true "" "plot average-cash"

PLOT
1349
366
1664
486
Passengers in Ride
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Passengers" 1.0 0 -4699768 true "" "plot number-passengers-in-ride"

PLOT
1060
487
1341
607
Rider Wait Time
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Rider" 1.0 0 -7171555 true "" "plot average-wait-time-riders"

PLOT
1351
487
1663
607
Energy Level (in remaining minutes)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Rider" 1.0 0 -817084 true "" "plot average-energy-level"

SWITCH
127
285
230
318
one-day
one-day
0
1
-1000

MONITOR
1065
762
1224
807
Total Cash ($)
total-cash
0
1
11

MONITOR
1237
761
1345
806
Fare Per Ride ($)
total-cash / number-riders-picked
3
1
11

MONITOR
1361
761
1449
806
Profit ($)
profit
0
1
11

PLOT
1061
604
1664
754
Profitability (Driver)
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot profit"

CHOOSER
8
468
146
513
Scenario
Scenario
"Saturday" "None"
0

MONITOR
855
44
1039
105
Hour of the day
ticks / 60
0
1
15

MONITOR
1472
762
1566
807
Total Profit ($)
total-cash + profit
0
1
11

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
  <experiment name="experiment 1 saturday random" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-cash + profit</metric>
    <enumeratedValueSet variable="Scenario">
      <value value="&quot;Saturday&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voronoi-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="kill-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drivers-count">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-regional-scale">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-wait-time">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="riders-per-time-unit">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-method">
      <value value="&quot;normal-random-local-move&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 1 saturday Voronoi" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-cash + profit</metric>
    <enumeratedValueSet variable="Scenario">
      <value value="&quot;Saturday&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voronoi-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="kill-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drivers-count">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-regional-scale">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-wait-time">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="riders-per-time-unit">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-method">
      <value value="&quot;normal-random-local-move&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 1 stationary Voronoi" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-cash + profit</metric>
    <enumeratedValueSet variable="Scenario">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voronoi-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="kill-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drivers-count">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-regional-scale">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-wait-time">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="riders-per-time-unit">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-method">
      <value value="&quot;normal-random-local-move&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 1 stationary random" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>total-cash + profit</metric>
    <enumeratedValueSet variable="Scenario">
      <value value="&quot;None&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="voronoi-vision">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="kill-switch">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drivers-count">
      <value value="49"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="local-regional-scale">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-wait-time">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="riders-per-time-unit">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="one-day">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="move-method">
      <value value="&quot;normal-random-local-move&quot;"/>
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
