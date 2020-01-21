;; GIS model based on incindiary model This model is a work in progress for a north Australian landscape fire simulation game
;; https://rohanfisher.wordpress.com/2014/07/12/kimberly-incendiary-sim-netlogo-model/
extensions [gis nw]


breed [local-populations local-population]
breed [area-of-saturations area-of-saturation]
breed [terrorist-cluster terror-cluster]
breed [township area-of-influence]
terrorist-cluster-own [ radicalism l-type influence radio-broadcaster]
township-own []


;; The nodes are terrorist-cluster. They are given a breed name
globals [
  scale-free
  avg-green-influence
  avg-red-influence
  avg-green-radicalism
  avg-red-radicalism
  percent-radicals
  percent-neutrals
  green-radicalism
  red-radicalism
  overtaken-townships
  percent-non-radicals
  total-radicalism?
  tslb-dataset
  dem-dataset
  radical-spread-value-dataset
  wetness-dataset
  cell-saturation
  border
  randmovement
  count-clusters
  component-size giant-component-size giant-start-node
  wd wd-1 wd-2 wd-3 wd-4 wd-5 wd-6 wd-7  ]

patches-own [
  Wetness
  cluster
  elevation
  radicalism-spread-area
  radical-spread-value
  tslb
  slope
  cell
  spread-ability
  radicalism-spread-area-time
  explored?
  direction-flow
]


;; create agents:
;;first-order 0 = anti-radical,
;;first-order 1 = varying levels of radicalism
to create-cell [ xcor-v ycor-v first-order ]


  let xcor-l xcor-v
  let ycor-l ycor-v
  let radical amt-initial-radicalism * .01
  let inf  red-influence  * .01
  let c red


  if ( first-order = 0 )
  [
    if  random (100 ) > agent-distribution-away-cities
    [
      let rx 1.0
      let ry 1.0
      if random (100) < 50 [ set rx -1.0 ]
      if random (100) < 50 [ set ry -1.0 ]

      ask one-of township [
        set xcor-l xcor + (random (20) * rx)
        set ycor-l ycor + (random (20) * ry)
      ]

      if xcor-l > max-pxcor [set xcor-l max-pxcor]
      if xcor-l < min-pxcor [set xcor-l min-pxcor]

      if ycor-l > max-pycor [set ycor-l max-pycor]
      if ycor-l < min-pycor [set ycor-l min-pycor]

    ]

    set radical  random (25) * .01 ;;.25
    set inf  random ( green-influence )  * .01
    if radical > 1 [ print radical ]


  ]

  ;; create an initial terrorist agent
  let partner nobody
  create-terrorist-cluster 1 [
    set shape "person"
    set xcor xcor-l
    set ycor ycor-l
    set size 10
    set radio-broadcaster false
    set l-type first-order
    set color c
    set influence inf
    set radicalism radical

    if scale-free = true
    [
      set partner (min-one-of (other terrorist-cluster with [not link-neighbor? myself ] in-radius link-distance )
        [distance myself ])
    ]

    if partner != nobody  [ create-link-with partner]

  ]
end



to-report find-partner
  report [one-of both-ends] of one-of links
end



to setup-scale-free
  set scale-free not clustered-vs-scale-free-network
end



;; do standard netlogo setup
to setup
  __clear-all-and-reset-ticks
  set-default-shape turtles "circle"
  view-new
  ask patches [set slope 1]
  ask patches [set cell 1]
  ask patches [set radicalism-spread-area-time 1]
  set border patches with [ count neighbors != 8 ]
  setup-patches

  setup-scale-free

  ask one-of patches [ set pcolor 1 ]

  create-influence-areas

end

;; generate havens
to create-influence-areas

  repeat ( num-havens )
  [
    create-township 1 [
      set shape "house"
      set xcor random-xcor
      set ycor random-ycor
      set size 20
      set color white - 1

    ]
  ]

  ;; create training environments
  repeat ( num-training-environments )
  [
    create-terrorist-cluster 1 [
      set shape "flag"
      set xcor random-xcor
      set ycor random-ycor
      set size 15
      set influence red-influence * .01
      set radicalism 1.3
      set color red

    ]
  ]

end


;; update network links, counts network clusters
to update-links


  ;; random 2% creates a new link within clustered network
  if random (100) < 2 and scale-free = false
  [

    clear-links
    foreach sort-on [ influence ] terrorist-cluster
    [ ?1 -> ask ?1
      [
        let ld link-distance
        repeat degree [

          let choice (min-one-of (other terrorist-cluster with [not link-neighbor? myself ] in-radius ld )
            [distance myself ])
          if choice != nobody  [
            create-link-with choice

            ask my-links [ set color gray ]

          ]
    ]  ] ]

  ]

end


;; generate radicals
to emerge-radicals

  if random (100) < secondary-order-leadership
  [
    let x random-xcor
    let y random-ycor

    let allblack true

    ask one-of patches with [ pcolor = 1 ]
    [
      ask neighbors4 [ if pcolor != 1 [ set allblack false ] ]

      set x pxcor
      set y pycor
    ]

    if allblack = true [  create-cell x y 1 ]

  ]


end

;;; create new leader that is anti-radical
to create-pro-policy-leader

  if random (100 ) < leader-emergence
  [
    let count-leaders count terrorist-cluster with [ l-type = 0 ]
    if count-leaders < max-emergent-leaders
    [
      let x random-xcor
      let y random-ycor
      create-cell x y 0
      ask patch x y
      [  sprout-local-populations 1
        [
          ask patches in-cone 1 360
          [ sprout-local-populations 1
            [
              set radicalism-spread-area radicalism-spread-area - 100   ]    ]  ]
        display
      ]

    ]

  ]

end




to go

  ask border   [  ask turtles-here [ die ]  ]
  ask turtles  [calc-slope]
  set randmovement random 30

  ask  area-of-saturations [
    ;;set growth 1.4

    ask neighbors [set spread-ability  (((log (tslb + 1) 2.7) * (radical-spread-value + 1)) * (((log 4 1.8) + 1) / growth))]]
  ask turtles [calc-cellinfluence]

  ask local-populations
    [ ask neighbors with [ (randmovement < ((spread-ability * cell) + (slope * .5))) and radicalism-spread-area = 100 ][emerge]
      set breed area-of-saturations ]
  ask area-of-saturations
    [ ask neighbors with [ ((randmovement + (radicalism-spread-area-time * 10)) < ((spread-ability * cell) + (slope * .5))) and radicalism-spread-area = 100 ][emerge]]
  set cell-saturation ((count patches with [pcolor = 1]) * 0.0081)
  fade-area-of-saturations
  update-links
  create-pro-policy-leader
  emerge-radicals
  update-network-function
  check-townships
  set-colors
  plot-items
  tick
end

;; check to see if haven/township should turn red
to check-townships

  ask township
  [
    if ([pcolor] of patch xcor ycor = 1)
    [
      set color red
    ]
  ]

end


;; change colors of cluster based on level of radicalism
to set-colors

  ask  terrorist-cluster
  [
    if radicalism < .3 [ set color green ]
    if radicalism >= .3 and radicalism < .7 [ set color gray ]
    if radicalism >= .8 and radicalism < .9 [ set color red ]
    if radicalism >= .9   [ set color red ]

  ]


end

;; plot
to plot-items

  let rad-threshold .7
  if count terrorist-cluster != 0 [set percent-radicals count terrorist-cluster with [ radicalism > rad-threshold ]  /  count terrorist-cluster * 100 ]
  if count terrorist-cluster != 0 [set percent-neutrals count terrorist-cluster with [ radicalism > .3 and radicalism < .7 ]  /  count terrorist-cluster * 100 ]
  if count terrorist-cluster != 0 [set percent-non-radicals count terrorist-cluster with [ radicalism < .3 ]  /  count terrorist-cluster * 100 ]

  if count terrorist-cluster != 0
  [
    let rad 0
    ask terrorist-cluster
    [
      set rad rad + radicalism
    ]

    set total-radicalism? ( rad / count terrorist-cluster ) * 100
  ]

  ;; townships have been taken over
  set overtaken-townships ( count township with [ color = red ] / count township ) * 100.0

  ;;get avg influence over groups
  set avg-green-influence 0
  set avg-green-radicalism 0
  let count-leaders count terrorist-cluster with [ l-type = 0 ]
  ask terrorist-cluster with [ l-type = 0 ]
  [
    set avg-green-influence avg-green-influence + influence
    set avg-green-radicalism avg-green-radicalism + radicalism
  ]
  set avg-green-influence avg-green-influence / count terrorist-cluster
  set avg-green-radicalism avg-green-radicalism / count terrorist-cluster

  set count-leaders count terrorist-cluster with [ l-type = 1 ]
  if count-leaders > 0
  [
    set avg-red-influence 0
    set avg-red-radicalism 0
    ;; nwo bad guys
    ask terrorist-cluster with [ l-type = 1 ]
    [
      set avg-red-influence avg-red-influence + influence
      set avg-red-radicalism avg-red-radicalism + radicalism
    ]
    set avg-red-influence avg-red-influence / count terrorist-cluster
    set avg-red-radicalism avg-red-radicalism / count terrorist-cluster

  ]

  ;; radicalism-per-group
  if count terrorist-cluster != 0
  [
    let rad 0
    ask terrorist-cluster with [ l-type = 0 ]
    [
      set rad rad + radicalism
    ]

    let denom count terrorist-cluster with [ l-type = 0 ]
    if denom != 0 [ set green-radicalism ( rad / denom ) * 100 ]
  ]

  ;; radicalism-per-group
  if count terrorist-cluster != 0
  [
    let rad 0
    ask terrorist-cluster with [ l-type = 1 ]
    [
      set rad rad + radicalism
    ]

    let denom count terrorist-cluster with [ l-type = 1 ]
    if denom != 0 [ set red-radicalism ( rad / denom ) * 100 ]
  ]


end

to emerge  ;; patch procedure
  sprout-local-populations 1
  [ set radicalism-spread-area radicalism-spread-area - 100 ]
  set pcolor black
end



to fade-area-of-saturations
  ask area-of-saturations
    [ set  radicalism-spread-area-time radicalism-spread-area-time + 1

      ifelse ( radicalism-spread-area-time > 7 )
        [set pcolor 1 die]
      [set pcolor  1]

  ]


end

to setup-patches
  import-pcolors-rgb "data/KIMB_1.png"
  ask patches [set radicalism-spread-area 100]
  set dem-dataset gis:load-dataset "data/KIMB_DEM_1.asc"
  set tslb-dataset gis:load-dataset "data/KIMB_YSLB_2.asc"
  set radical-spread-value-dataset gis:load-dataset "data/KIMB_VEG_1.asc"
  set wetness-dataset gis:load-dataset "data/KIMB_WET_2.asc"
  gis:apply-raster dem-dataset elevation
  gis:apply-raster tslb-dataset  tslb
  gis:apply-raster radical-spread-value-dataset radical-spread-value
  gis:apply-raster wetness-dataset wetness
  gis:set-world-envelope
  (gis:envelope-of tslb-dataset)
  ask patches [set tslb tslb + 1]
end

to calc-slope
  let e1 [elevation] of patch-at 0 1
  show e1
  let s1 (e1 - [elevation] of patch-here) / .9
  ask patch-at 0 1 [set slope s1]

  let e2 [elevation] of patch-at 1 0
  let s2 (e2 - [elevation] of patch-here ) / .9
  ask patch-at 1 0 [set slope s2]

  let e3 [elevation] of patch-at 0 -1
  let s3 (e3 - [elevation] of patch-here ) / .9
  ask patch-at 0 -1 [set slope s3]

  let e4 [elevation] of patch-at -1 0
  let s4 (e4 - [elevation] of patch-here ) / .9
  ask patch-at -1 0 [set slope s4]

  let e5 [elevation] of patch-at 1 -1
  let s5 (e5 - [elevation] of patch-here ) / .9
  ask patch-at 1 -1 [set slope s5]

  let e6 [elevation] of patch-at -1 -1
  let s6 (e6 - [elevation] of patch-here ) / .9
  ask patch-at -1 -1 [set slope s6]

  let e7 [elevation] of patch-at 1 1
  let s7 (e7 - [elevation] of patch-here ) / .9
  ask patch-at 1 -1 [set slope s7]

  let e8 [elevation] of patch-at -1 1
  let s8 (e8 - [elevation] of patch-here ) / .9
  ask patch-at -1 -1 [set slope s8]
end



to change-cell-speed

end

;; calculates radical cell influence
to calc-cellinfluence
  if (direction-flow = "N")
  [ ask patch-at 0 1 [set cell wd]
    ask patch-at 1 1 [set cell wd-1]
    ask patch-at 1 0 [set cell wd-2]
    ask patch-at 1 -1 [set cell wd-3]
    ask patch-at 0 -1 [set cell wd-4]
    ask patch-at -1 -1 [set cell wd-5]
    ask patch-at -1 0 [set cell wd-6]
    ask patch-at -1 1 [set cell wd-7]]
  if (direction-flow = "NE")
    [ ask patch-at 0 1 [set cell wd-7]
      ask patch-at 1 1 [set cell wd]
      ask patch-at 1 0 [set cell wd-1]
      ask patch-at 1 -1 [set cell wd-2]
      ask patch-at 0 -1 [set cell wd-3]
      ask patch-at -1 -1 [set cell wd-4]
      ask patch-at -1 0 [set cell wd-5]
      ask patch-at -1 1 [set cell wd-6]]
  if (direction-flow = "E")
    [ ask patch-at 0 1 [set cell wd-6]
      ask patch-at 1 1 [set cell wd-7]
      ask patch-at 1 0 [set cell wd]
      ask patch-at 1 -1 [set cell wd-1]
      ask patch-at 0 -1 [set cell wd-2]
      ask patch-at -1 -1 [set cell wd-3]
      ask patch-at -1 0 [set cell wd-4]
      ask patch-at -1 1 [set cell wd-5]]
  if (direction-flow = "SE")
  [ ask patch-at 0 1 [set cell wd-5]
    ask patch-at 1 1 [set cell wd-6]
    ask patch-at 1 0 [set cell wd-7]
    ask patch-at 1 -1 [set cell wd]
    ask patch-at 0 -1 [set cell wd-1]
    ask patch-at -1 -1 [set cell wd-2]
    ask patch-at -1 0 [set cell wd-3]
    ask patch-at -1 1 [set cell wd-4]]
  if (direction-flow = "S")
  [ ask patch-at 0 1 [set cell wd-4]
    ask patch-at 1 1 [set cell wd-5]
    ask patch-at 1 0 [set cell wd-6]
    ask patch-at 1 -1 [set cell wd-7]
    ask patch-at 0 -1 [set cell wd]
    ask patch-at -1 -1 [set cell wd-1]
    ask patch-at -1 0 [set cell wd-2]
    ask patch-at -1 1 [set cell wd-3]]
  if (direction-flow = "SW")
  [ ask patch-at 0 1 [set cell wd-3]
    ask patch-at 1 1 [set cell wd-4]
    ask patch-at 1 0 [set cell wd-5]
    ask patch-at 1 -1 [set cell wd-6]
    ask patch-at 0 -1 [set cell wd-7]
    ask patch-at -1 -1 [set cell wd]
    ask patch-at -1 0 [set cell wd-1]
    ask patch-at -1 1 [set cell wd-2]]
  if (direction-flow = "W")
  [ ask patch-at 0 1 [set cell wd-2]
    ask patch-at 1 1 [set cell wd-3]
    ask patch-at 1 0 [set cell wd-4]
    ask patch-at 1 -1 [set cell wd-5]
    ask patch-at 0 -1 [set cell wd-6]
    ask patch-at -1 -1 [set cell wd-7]
    ask patch-at -1 0 [set cell wd]
    ask patch-at -1 1 [set cell wd-1]]
  if (direction-flow = "NW")
  [ ask patch-at 0 1 [set cell wd-1]
    ask patch-at 1 1 [set cell wd-2]
    ask patch-at 1 0 [set cell wd-3]
    ask patch-at 1 -1 [set cell wd-4]
    ask patch-at 0 -1 [set cell wd-5]
    ask patch-at -1 -1 [set cell wd-6]
    ask patch-at -1 0 [set cell wd-7]
    ask patch-at -1 1 [set cell wd]]
end


;; view data from original GIS model (different formats)
To view-new
  if View = "Satellite Image" [import-pcolors-rgb "data/KIMB_LANDSAT.png"]
  if view = "TSLB"  [import-pcolors-rgb "data/KIMB_YSLB.png"]
  if View = "DEM" [import-pcolors-rgb "data/KIMB_DEM.png"]
  if view = "DEM-SHADE"  [import-pcolors-rgb "data/KIMB_DEM_HS.png"]
  if view = "Wetness"  [import-pcolors-rgb "data/KIMB_WETNESS.png"]
end



;; communicate with local links
to update-network-function

  ;; check if neighbors have misinformation
  ;; if threshold is met than do something
  ask  terrorist-cluster
    [
      ;; increment the total number of  agents
      ifelse random-float 100  < information-spread-probability and count (link-neighbors ) > 0;; infect with probability p and
        [
          let neighbors-num count link-neighbors

          let total 0
          ask link-neighbors [ set total total + radicalism  ]
          set total total / neighbors-num
          set radicalism ( total * (1 - influence)) + radicalism * (influence)


          ask my-links [ set color white ]

      ]
      [
        ask my-links [ set color gray ]
      ]


  ]


end

@#$#@#$#@
GRAPHICS-WINDOW
198
10
969
580
-1
-1
1.011
1
10
1
1
1
0
0
0
1
-377
377
-277
277
1
1
1
ticks
30.0

BUTTON
18
23
73
56
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
84
23
139
56
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

CHOOSER
-22
532
87
577
View
View
"Satellite Image" "TSLB" "Wetness" "DEM" "DEM-SHADE"
0

BUTTON
88
537
159
570
View
view-new
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
14
200
186
233
link-distance
link-distance
0
200
25.0
1
1
NIL
HORIZONTAL

SLIDER
11
302
185
335
leader-emergence
leader-emergence
0
50
7.0
1
1
NIL
HORIZONTAL

SLIDER
11
401
185
434
distance-add-cell
distance-add-cell
0
100
69.0
1
1
NIL
HORIZONTAL

SLIDER
7
481
184
514
secondary-order-leadership
secondary-order-leadership
0
100
34.0
1
1
NIL
HORIZONTAL

SLIDER
15
237
186
270
degree
degree
0
8
8.0
1
1
NIL
HORIZONTAL

SLIDER
11
442
183
475
growth
growth
.1
3
1.15
.01
1
NIL
HORIZONTAL

SLIDER
1405
170
1610
203
information-spread-probability
information-spread-probability
0
100
15.0
1
1
NIL
HORIZONTAL

PLOT
974
10
1386
278
average radicalism within group
NIL
NIL
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"radicals" 1.0 0 -2674135 true "" "plot percent-radicals"
"non-radical" 1.0 0 -13840069 true "" "plot percent-non-radicals"
"average radicalism" 1.0 0 -11221820 true "" "plot total-radicalism?"
"neutrals" 1.0 0 -7500403 true "" "plot percent-neutrals"

SLIDER
12
342
187
375
max-emergent-leaders
max-emergent-leaders
0
1000
219.0
1
1
NIL
HORIZONTAL

SLIDER
3
71
180
104
num-havens
num-havens
0
50
9.0
1
1
NIL
HORIZONTAL

SLIDER
1405
128
1607
161
agent-distribution-away-cities
agent-distribution-away-cities
0
100
26.0
1
1
NIL
HORIZONTAL

BUTTON
1508
387
1643
420
reset-network
setup-scale-free
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
979
522
1203
555
clustered-vs-scale-free-network
clustered-vs-scale-free-network
1
1
-1000

SWITCH
1401
213
1573
246
radio-communication
radio-communication
1
1
-1000

SLIDER
1399
257
1571
290
radio-power
radio-power
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
7
119
189
152
num-training-environments
num-training-environments
0
50
5.0
1
1
NIL
HORIZONTAL

SLIDER
981
445
1153
478
green-influence
green-influence
0
100
51.0
1
1
NIL
HORIZONTAL

SLIDER
981
478
1153
511
red-influence
red-influence
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
1332
283
1532
438
radicals vs non radicals
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
"non-radicals" 1.0 0 -13840069 true "" "plot count terrorist-cluster with [ l-type = 0 ]"
"radicals" 1.0 0 -2674135 true "" "plot count terrorist-cluster with [ l-type = 1 ]"

TEXTBOX
23
171
173
199
Home Grown (link distance + degree)
11
0.0
1

PLOT
976
281
1332
439
average-radicalism-total-in-environment
NIL
NIL
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"avg-red-radicalism" 1.0 0 -2674135 true "" "plot avg-red-radicalism"
"avg-green-radicalism" 1.0 0 -14439633 true "" "plot avg-green-radicalism"

SLIDER
1164
447
1351
480
amt-initial-radicalism
amt-initial-radicalism
0
100
67.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model is a work in progress for a north Australian landscape fire simulation game. The primary idea is to show how a range of variables effect fire spread when conducting aerial incendiary management burns early in the dry season and how these fuel reduction fires effect the spread of late season wild fires. 

This model is based on an area north of Derby in the West Kimberly region of Western Australia. 


## HOW IT WORKS

The model currently uses the following variable to determine if a pixel will ignite:

- a vegetation map (from SAVBAT veg mapping) and a time since burnt layer (from NAFI) to produce fuel load variable. This is the default layer displayed. Eucalyptus wood lands are displayed a olive greens, sandstone grass and scrublands as browns and mangrove communities as bright green.

- an elevation layer (SRTM-DEM) is used to determine slope in relation to fire spread direction.

- a topographic wetness layer, derived from the DEM, is used to represent differntial landscape curing.

- Curing as an value from 1 (wet season) to 4 (late dry season). 

- Wind speed from none (no wind influence) to strong. Wind speed increses the directionality and likelyhood of a pixel ignighting.

- wind direction (the direction a fire will spread)

The algorithm used to combine these variables to determine fire spread is currently fairly arbitrary and needs more work.

## HOW TO USE IT

Use the view drop list to display a one of a range of landscape layers. Click the drop incendaries button and use the cursor to ignite some initial pixels. Change curing, wind direction and wind speed to set your fire senario. Use the variable-wind button to allow the model to  randomly change the wind speed asthe model runs.


## THINGS TO NOTICE

Fires should not run down slope as well asup slope. 

## THINGS TO TRY

Try running the model to set fire breaks early in the in the dry season (curing 2) then run the model with some single ignition points late in the dry (curing 4). Are you able to prevent fires spreading through your early season burns.

Try runing the model with some of the different landscape layers displayed.y

Try running it projected over a sandpit sculpted with refernece to the elevation layer.

## EXTENDING THE MODEL

- A more sophisticated burn probability algorithm
- Variable fire spread speed
- Burn severity
- A more sophisticated wind direction/speed algorithm
- An estimate of chopper time/cost 
- An estimate of burn cost to burn area and fire severity as a measure of management     burn effectiveness.


## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

Based on fire break model

## CREDITS AND REFERENCES

Rohan Fisher (rohan.fisher@cdu.edu.au)
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="degree" repetitions="4" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>total-radicalism?</metric>
    <enumeratedValueSet variable="distance-add-cell">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-communication">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-distance">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clustered-vs-scale-free-network">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-townships">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary-order-leadership">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth">
      <value value="1.15"/>
    </enumeratedValueSet>
    <steppedValueSet variable="degree" first="1" step="1" last="8"/>
    <enumeratedValueSet variable="max-emergent-leaders">
      <value value="219"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-spread-probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-influence">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-emergence">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="View">
      <value value="&quot;Satellite Image&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-influence">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-training-environments">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-distribution-away-cities">
      <value value="26"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="red-influence" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>total-radicalism?</metric>
    <enumeratedValueSet variable="link-distance">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-spread-probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clustered-vs-scale-free-network">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="View">
      <value value="&quot;Satellite Image&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-townships">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-communication">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-emergent-leaders">
      <value value="219"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-add-cell">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-influence">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="secondary-order-leadership">
      <value value="18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-distribution-away-cities">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-training-environments">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth">
      <value value="1.32"/>
    </enumeratedValueSet>
    <steppedValueSet variable="red-influence" first="0" step="5" last="100"/>
    <enumeratedValueSet variable="leader-emergence">
      <value value="7"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="amt-initial radicalism" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>total-radicalism?</metric>
    <enumeratedValueSet variable="secondary-order-leadership">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-spread-probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clustered-vs-scale-free-network">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-emergent-leaders">
      <value value="219"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-townships">
      <value value="9"/>
    </enumeratedValueSet>
    <steppedValueSet variable="amt-initial-radicalism" first="5" step="5" last="100"/>
    <enumeratedValueSet variable="num-training-environments">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-distance">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-emergence">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degree">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-influence">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth">
      <value value="1.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-distribution-away-cities">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-communication">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-influence">
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-add-cell">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="View">
      <value value="&quot;Satellite Image&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="highradical-greeninfluence" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>total-radicalism?</metric>
    <enumeratedValueSet variable="secondary-order-leadership">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-spread-probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clustered-vs-scale-free-network">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-emergent-leaders">
      <value value="138"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-townships">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="amt-initial-radicalism">
      <value value="88"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-training-environments">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-distance">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-emergence">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degree">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-influence">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth">
      <value value="1.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-distribution-away-cities">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-communication">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="green-influence" first="0" step="5" last="100"/>
    <enumeratedValueSet variable="radio-power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-add-cell">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="View">
      <value value="&quot;Satellite Image&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="training-environments" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>total-radicalism?</metric>
    <enumeratedValueSet variable="secondary-order-leadership">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-spread-probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clustered-vs-scale-free-network">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-emergent-leaders">
      <value value="138"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-townships">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="amt-initial-radicalism">
      <value value="67"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-training-environments" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="link-distance">
      <value value="37"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="leader-emergence">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="degree">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-influence">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth">
      <value value="1.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-distribution-away-cities">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-communication">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-influence">
      <value value="48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-add-cell">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="View">
      <value value="&quot;Satellite Image&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="leader-emergence" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>total-radicalism?</metric>
    <enumeratedValueSet variable="secondary-order-leadership">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information-spread-probability">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="clustered-vs-scale-free-network">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-emergent-leaders">
      <value value="138"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-townships">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="amt-initial-radicalism">
      <value value="67"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-training-environments">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="link-distance">
      <value value="37"/>
    </enumeratedValueSet>
    <steppedValueSet variable="leader-emergence" first="1" step="5" last="100"/>
    <enumeratedValueSet variable="degree">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="red-influence">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth">
      <value value="1.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-distribution-away-cities">
      <value value="26"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-communication">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="green-influence">
      <value value="48"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="radio-power">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distance-add-cell">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="View">
      <value value="&quot;Satellite Image&quot;"/>
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
