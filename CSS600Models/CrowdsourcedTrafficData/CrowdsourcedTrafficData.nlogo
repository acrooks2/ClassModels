globals[intrafficnetwork obstacle-on-road roads intersection1 intersection2 obstacleknown numbercarstopped turtlenetworkcarstopped carspassed
  networkcars-list othercars-list difference
  stat-flag tvalue std1 std2]
turtles-own [turtlenetwork just-turned1 just-turned2 lxcor lycor stopped1tick stopped2tick carstopped switchedlane
  traveltime endtime tickcounter inobstaclearea]
patches-own [ intersection1? intersection2?]


to setup
  clear-all
  set-default-shape turtles "car"

  setup-patches

  create-turtles numcars? ;create the number of cars specified on the interface
  [
    setup-cars
  ]
  reset-ticks
  set obstacle-on-road false ;flag for obstacle on road
  set obstacleknown false ;flag if the obstacle is known
  set numbercarstopped 0 ;total number of cars stopped
  set turtlenetworkcarstopped 0 ; number of network cars stopped
  set carspassed 0 ;number of cars which crossed the screen
  set networkcars-list 0
  set othercars-list 0
  set stat-flag 0
  set tvalue 0
  checktrafficnetwork
end

;draw the road and set the intersections
to setup-patches

  ask patches
  [
    set pcolor green
  ]

  set roads patches with ;create the road
  [
    ((pycor > -2) and (pycor < 1)) or ;middle

    ((pycor > -5) and (pycor < 4) and (pxcor > 5) and (pxcor < 7)) or
    ((pycor > -5) and (pycor < 4) and (pxcor > -8) and (pxcor < -6)) or
    ((pycor > -5) and (pycor < -3) and (pxcor > -8) and (pxcor < 7)) or ;bottom
    ((pycor >= 3) and (pycor < 4) and (pxcor > -8) and (pxcor < 7))     ;top
  ]

  set intersection1 patches with ;marks first intersection
    [((pxcor = -7) and (pycor = 0)) or ((pxcor = -7) and (pycor = -1))]

  set intersection2 patches with ;marks second intersection
    [((pxcor = 6) and (pycor = 0)) or ((pxcor = 6) and (pycor = -1))]

  setup-intersection
  ask roads [ set pcolor 1] ;make roads black
end

to setup-intersection ;sets the intersection
  ask intersection1 [set intersection1? true]
  ask intersection2 [set intersection2? true]
end

to setup-cars ;set default values for the cars
  put-on-empty-road
  set heading 90 ;heading
  set carstopped false ;indicates if the car is stopped
  set switchedlane false ;indicates if the car just switched lanes
  set traveltime 0 ;keeps track of travel time
  set endtime 0 ;time to cross the screen
  set tickcounter 0 ;keeps track of the number of ticks
  set inobstaclearea false ;determines if near the obstacle
  set turtlenetwork false ;keeps track of whether in network
end

to checktrafficnetwork ;determines the number of cars in traffic network
  if trafficnetwork? = true
  [
    set intrafficnetwork true
    ask n-of (percentage-in-network? / 100 * numcars?) turtles [set color white]
  ]
end

to activeturtlenetwork  ;sets the turtles in traffic network
  set turtlenetwork true
end

to put-on-empty-road ;puts turtles on an empty road patch
  move-to one-of roads with [not any? turtles-on self]
end

to check-intersection1 ;checks to see if the turtle is in the first intersection, change heading to 0 or 180
  if (intersection1? = true and just-turned1 = 0)
  [
    set just-turned1 1

    ifelse ((xcor = -7) and (ycor = 0))
    [
      set heading 0
    ]
    [
      set heading 180
    ]
  ]
end

to check-intersection2 ;if at a intersection2 change heading to 90
  if (intersection2? = true and just-turned2 = 0) [
    set just-turned2 1
    if heading = 0 [ set heading 90]
    if heading = 180 [ set heading 90]
  ]
end

to go
  draw-plotaverage ;creates the plot
  ask patches
  [
    check-obstacle ;checks to see if there is an obstacle
  ]

  ask turtles
  [
    record-data ;records the data

    ifelse ((color = white) and (trafficnetwork?)) ;if the car is white and the trafficnetwork is on
    [
      set turtlenetwork true
    ]
    [
      set turtlenetwork false
    ]
    if ((xcor = -15) and ((ycor = 0) or (ycor = -1))) ;reset intersection turns
    [
      set just-turned1 0
      set just-turned2 0
      set tickcounter 0
      set inobstaclearea false
    ]
    ifelse ((xcor = 1) and ((ycor = 0) or (ycor = -1))) ;if car is near the obstacle, keep track of ticks
    [
      set tickcounter tickcounter + 1
      set inobstaclearea true
    ]
    [
      set tickcounter 0
      set inobstaclearea false
    ]
    ifelse ((xcor = lxcor) and (ycor = lycor)) ;;checks to see if car moved
    [
      if (stopped1tick = true)  ;if car did not move for one tick
      [
        if (stopped2tick = true) ;if car did not move for two ticks
        [

          if (carstopped = false)  ;indicator that car has stopped
          [
            set carstopped true
            set numbercarstopped numbercarstopped + 1 ;keep track of number of cars stopped

            if (turtlenetwork = true)
            [
              set turtlenetworkcarstopped turtlenetworkcarstopped + 1
            ]
          ]
          ifelse not any? turtles-on patch-ahead 1 ;if no cars are in the patch ahead move forward
          [
            if ((xcor = 1) and (ycor = -1)) ;if car is on the main strip, they can move to the other lane
            [
               move-otherlane
            ]
          ]
          [ ;move to other lane
            if (((ycor = -1) or (ycor = 0)) )
            [
              move-otherlane
            ]
          ]
        ]
        set stopped2tick true   ;if car did not move for two ticks
      ]
      set stopped1tick true ;if car did not move for one tick
    ]
    [
      if (carstopped = true) ;if the car starts moving again, decrement the numbercarstopped counter
      [
        set carstopped false
        if (numbercarstopped > 0)
        [
          set numbercarstopped numbercarstopped - 1
        ]
      ]
    ]
    set lxcor xcor ;sets lxcor value (last xcor)
    set lycor ycor ;sets lycor value (last ycor)

    ifelse ((obstacle-on-road = true) and((xcor >= 1 and xcor < 1.5) and (ycor = -1)))
    [
        ;stops the first car after obstacle
    ]
    [

      ;if the obstacle is known and turtlenetwork is true, a percentage of the network cars take the alternate route
      if ((obstacleknown = true) and (turtlenetwork = true))
      [
        let a random 100
        if (a < in-network-alternate-route?)
        [
          check-intersection1
        ]
      ]
      if ((obstacle-on-road = true) and (numbercarstopped >= 7 ))    ;if the obstacle is on the road and the 7 regular cars are stopped
      [                                                              ;a percentage of the regular cars can take the alternate route
        let b random 100
        if (b < outofnetwork-alternateroute?)
        [
          check-intersection1 ;changes the heading of the car in the intersection if necessary
        ]
      ]
      check-intersection2 ;changes the heading of the car in the intersection if necessary

      ;sets the heading of the turtles depending on location
      if (xcor >= 5.9 and ycor <= 3.25 and ycor > 0.1) [set heading 180]
      if (xcor >= 5.9 and ycor >= -6.25 and ycor < -1.1) [set heading 0]
      if (xcor >= 5.9 and ycor <= 0.1 and ycor >= -0.1) [set heading 90]

      if (just-turned1 = 0) ;if at intersection1 and justturned, do not reset heading
      [
        if (xcor = -7 and ycor > 0.1) [set heading 0]
        if (xcor = -7 and ycor = 0) [set heading 90]
        if (xcor = -7 and ycor < -1) [set heading 180]
      ]
      if (xcor = -7 and ycor >= 3) [set heading 90]
      if (xcor = -7 and ycor <= -4) [set heading 90]

      if not any? turtles-on patch-ahead 1 ;checks to see if there is a turtle on the patch ahead
      [
        ifelse (switchedlane = false) ;if they switched lanes, don't move forward otherwise they would move twice in one tick
        [
          if (((inobstaclearea = true) and (tickcounter >= slowrateofflow?) and (obstacle?)) or (inobstaclearea = false) or (obstacle? = false)) ;determines when to advance the car
          [
            fd 1
          ]
        ]
        [
          set switchedlane false ;if switchedlane was true, reset it so the car can move the next tick
        ]
      ]

      if ((xcor = 2) and ((ycor = 0) or (ycor = -1)) and (obstacle? = false) and (turtlenetwork = true))
      [
        clear-obstacle
      ]

    ]
    if (xcor > 14) ;keeps track of the number of cars who passed
    [
      set carspassed carspassed + 1
    ]
  ]

  if ((turtlenetworkcarstopped >= 2) and (obstacle?)) ;if two or more network cars are stopped and obstacle is on inform the network
  [
    set obstacleknown true
  ]


  tick

  createlist
end

to move-otherlane ;allows the turtle to switch lanes only the two middle lanes
  ifelse (ycor = -1) ;checks the lane
  [
    if not any? turtles-on patch-at-heading-and-distance 0 1 ;checks to see if the spot above is empty
    [
      set heading 0
      fd 1
      set heading 90
      set switchedlane true
    ]
  ]
  [
    ifelse (((xcor = 1) or (xcor = 2)) and (ycor = 0))
    [
      ;do not let them advance - because that's where the obstacle is
    ]
    [
      if not any? turtles-on patch-at-heading-and-distance 180 1 ;checks to see if the spot below is empty
      [
        set heading 180
        fd 1
        set heading 90
        set switchedlane true
      ]
    ]
  ]
end

to check-obstacle ;checks to see there is a obstacle
    ifelse (obstacle?)
    [
      if (obstacle-on-road = false) ;sets an obstacle at a pre-determined spot
      [
        ask (patch 2 -1)
        [
          set pcolor blue
        ]
        set obstacle-on-road true
      ]
    ]
    [
     if (obstacle-on-road = true)
     [
       ask (patch 2 -1)
       [
         set pcolor 1 ;changes the patch back to black
       ]
     set obstacle-on-road false
     ]
    ]
end

to clear-obstacle ;removes the obstacle and resets the variables
   ;ask (patch 2 -1)
   ;[
   ;  set pcolor 1 ;changes the patch back to black
   ;]
   ;set obstacle-on-road false
   set obstacleknown false
   set numbercarstopped 0
   set turtlenetworkcarstopped 0
end

to createlist
  set networkcars-list ([endtime] of turtles with [color = white])
  set othercars-list ([endtime] of turtles with [color != white])

  if (length networkcars-list > 0)
  [
    ttest networkcars-list othercars-list
    standarddeviation
  ]
end

to standarddeviation
  set std1 standard-deviation networkcars-list
  set std2 standard-deviation othercars-list
end

to ttest [y1list y2list]

  ; the purpose of this procedure is to return whether there is a significant difference between two resuts.

  let s1 0
  let s2 0
  let y1bar 0
  let y2bar 0
  let n1 0
  let n2 0
  let s 0
  let sd 0
  ;let tvalue 0
  let df 0
  let ttable 0
  let critical 0


  set ttable [100 12.706 4.303 3.182 2.776 2.571 2.447 2.365 2.306 2.262
              2.228 2.201 2.179 2.160 2.145 2.131 2.120 2.110 2.101 2.093
              2.086 2.08 2.074 2.069 2.064 2.06 2.056 2.052 2.048 2.045
              2.042 2.021 2 1.98 1.96] ; two-tail critical values at 0.05
  ;if (length networkcars-list > 0)

  set s1 variance networkcars-list
  set y1bar mean networkcars-list

  set s2 variance othercars-list

  set y2bar mean othercars-list
  set n1 length networkcars-list
  set n2 length othercars-list
  set df (n1 - 1) + (n2 - 1)
  set s ((n1 - 1) * s1 + (n2 - 1) * s2) / ((n1 - 1) + (n2 - 1))
  set sd sqrt (s * (n1 + n2) / (n1 * n2))
  if (sd != 0)
  [
  set tvalue abs (y1bar - y2bar) / sd
  ]

  if (df <= 30)
    [set critical item df ttable
     if (tvalue > critical)
       [set stat-flag true

       ]

    ]

  if (df > 30 and df <= 40)
    [set critical item 31 ttable
     if (tvalue > critical)
       [set stat-flag true
;        show "Statistical significance found"
       ]
;       [show "Not Statistically significant"]
    ]

  if (df > 40 and df <= 60)
    [set critical item 32 ttable
     if (tvalue > critical)
       [set stat-flag true
;        show "Statistical significance found"
       ]
;       [show "Not Statistically significant"]
    ]

  if (df > 60 and df <= 120)
    [set critical item 33 ttable
     if (tvalue > critical)
       [set stat-flag true

       ]

    ]

  if (df > 120)
    [set critical item 34 ttable
     if (tvalue > critical)
       [set stat-flag true

       ]

    ]

end

to record-data ;records the time it takes to travel across the screen
  if ((xcor = -11) and ((ycor = 0) or (ycor = -1)))
  [
    set traveltime 0
  ]
  set traveltime traveltime + 1
  if (xcor = 11)
  [
    set endtime traveltime
  ]
end

to draw-plotaverage ;draws the average plot
  set-current-plot "Average Travel Time"
  let whiteturtles count turtles with [color = white]
  let otherturtles count turtles with [color != white]

    if ((trafficnetwork?) and (whiteturtles > 0) and (otherturtles > 0));create plot with turtles in network and not in network
    [
      set-current-plot-pen "network-cars" ;plot all turtles in network
      set-plot-pen-color blue
      plot mean [endtime] of turtles with [color = white]

      set-current-plot-pen "nonnetwork-cars" ;plot all turtles not in network
      set-plot-pen-color green
      plot mean [endtime] of turtles with [color != white]

      set difference (mean [endtime] of turtles with [color != white] - mean [endtime] of turtles with [color = white])
    ]

    set-current-plot-pen "all-cars" ;plot all turtles
    set-plot-pen-color red
    plot mean [endtime] of turtles
end
@#$#@#$#@
GRAPHICS-WINDOW
230
11
734
516
-1
-1
16.0
1
10
1
1
1
0
1
1
1
-15
15
-15
15
0
0
1
ticks
30.0

BUTTON
32
57
95
90
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
109
57
172
90
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

SWITCH
9
118
117
151
obstacle?
obstacle?
0
1
-1000

SLIDER
8
160
180
193
numcars?
numcars?
10
50
30.0
1
1
NIL
HORIZONTAL

SWITCH
8
204
148
237
trafficnetwork?
trafficnetwork?
0
1
-1000

SLIDER
9
246
191
279
percentage-in-network?
percentage-in-network?
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
9
363
225
396
outofnetwork-alternateroute?
outofnetwork-alternateroute?
0
100
24.0
1
1
NIL
HORIZONTAL

MONITOR
744
89
833
134
all-cars
mean [endtime] of turtles
2
1
11

MONITOR
843
87
940
132
network-cars
mean [endtime] of turtles with [color = white]
2
1
11

MONITOR
947
86
1066
131
nonnetwork-cars
mean [endtime] of turtles with [color != white]
2
1
11

PLOT
746
149
1042
332
Average Travel Time
Time
Average Travel
0.0
100.0
0.0
75.0
true
true
"" ""
PENS
"all-cars" 1.0 0 -2674135 true "" ""
"network-cars" 1.0 0 -13345367 true "" ""
"nonnetwork-cars" 1.0 0 -10899396 true "" ""

PLOT
747
347
1044
497
Number Cars Passed
Time
cars
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot carspassed"

SLIDER
9
285
198
318
in-network-alternate-route?
in-network-alternate-route?
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
9
324
181
357
slowrateofflow?
slowrateofflow?
0
25
3.0
1
1
NIL
HORIZONTAL

MONITOR
823
515
912
560
numberofcars
carspassed
2
1
11

MONITOR
10
505
67
550
NIL
tvalue
2
1
11

MONITOR
9
405
152
450
numberofcarsinnetwork
count turtles with [color = white]
0
1
11

MONITOR
10
454
172
499
numberofcarsnotinnetwork
count turtles with [color != white]
0
1
11

MONITOR
844
32
901
77
NIL
std1
2
1
11

MONITOR
947
35
1004
80
NIL
std2
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model models the traffic flow and congestion with an information network.  The car follows simple rules as they try to move across the road as quickly as possible.  An
obstacle can be place to slow down traffic.  Cars can be part of an information network
where they share information about traffic congestion.

This model demonstrates how traffic congestion can be avoided or reduced with the use
of an information network.

## HOW IT WORKS

Click the SETUP button to setup the cars.
Click the GO button to start the model.

## HOW TO USE IT
Set the obstacle? switch to place an obstacle on the road.

Select the number of cars in the model.

Set the trafficnetwork? to turn the information network on and off.

Set the percentage-in-network? slider to select the percentage of cars in the network.

Set the in-network-alternate-route? slider to select the percentage of in network cars
to take the alternate route.

Set the slowrateofflow? slider to select how much to slow the rate of flow.

Set the outofnetwork-alternate-route? to select the percentage of of cars not in the
network to take the alternate route.

## THINGS TO NOTICE
The cars start at random positions on the road.  They will move to the main road since
that is the quickest route.  When an obstacle is added, the cars will try to move
around the obstacle.

To model an information network the trafficnetwork? must be on and the percentage-in-network? must be greater than 0.  The cars will not take an alternate
route until the in-network-alternate-route is greater than 0.

Traffic congestion can be simulated with the slowrateofflow? slider.  The higher the
rate, the longer it takes to move around the obstacle.

Cars that are not in the network can also take the alternate route by selecting
the outofnetwork-alternate-route? greater than zero.

## THINGS TO TRY

Try varying the number of cars, the slowrateofflow and the in-network-alternate-route
sliders to see the affects to the traffic congestion.

## EXTENDING THE MODEL
The model can be extended by adding more roads or allowing the obstacle location to vary.


## NETLOGO FEATURES

The plot shows the average time it take for a car to move across the road.  There is
a plot for all cars, cars in network and cars not in the network.

There is also a plot that counts the number of cars that cross the road for the whole simulation.

## CREDITS AND REFERENCES

Wilensky, U. (1997). NetLogo Traffic Basic model. http://ccl.northwestern.edu/netlogo/models/TrafficBasic. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

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
<experiments>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alternateroute?">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment no network" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alternateroute?">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment rateofflow15" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rateofflow?">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alternateroute?">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment rateofflow15innetwork50alternateroute15" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rateofflow?">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alternateroute?">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow0test" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow5" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow10" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow15" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow20" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow0testtvalue" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>endtime</metric>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow5percentinnetwork30" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow5percentinnetwork70" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow10innetwork alternateroute 25" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow5innetwork alternateroute 75" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow5numcars50" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow0" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="rateofflow10innetwork alternateroute 75" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>carspassed</metric>
    <metric>tvalue</metric>
    <metric>mean [endtime] of turtles</metric>
    <metric>mean [endtime] of turtles with [color = white]</metric>
    <metric>mean [endtime] of turtles with [color != white]</metric>
    <enumeratedValueSet variable="percentage-in-network?">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slowrateofflow?">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numcars?">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="obstacle?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="in-network-alternate-route?">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outofnetwork-alternateroute?">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trafficnetwork?">
      <value value="true"/>
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
