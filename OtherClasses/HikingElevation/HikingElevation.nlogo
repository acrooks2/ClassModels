extensions [gis]       ; GIS Raster Data will be imported

globals [
  parkData             ; A variable to store the data from the .asc file (GIS data)
  min-elev             ; The lowest elevation in the file  Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
  max-elev             ; The highest elevation in the file  Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
  goal-patch-x         ; The x-coordinate of the visitor's destination.
  goal-patch-y         ; The y-coordinate of the visitor's destination.
  start?               ; The simulation will not start until the park manager clicks the map to set a destination.
  entrance-patch-x     ; The x-coordinate of the park entrance (where visitors start and end).
  entrance-patch-y     ; The y-coordinate of the park entrance.
  track-elevation      ; After the simulation stabilizes, a single turtle is chosen. It's elevation is reported to this global variable - which is plotted in the graph elevation vs. time.
  world-clock          ; My model had some anomilies when tick counts where less than 500. This variable helps me prevent certain processes from happening before the 500 tick mark. This is a work-around.
]

patches-own [
  elevation              ; Each patch is assigned an elevation, based on the imported data.
  tread-count            ; Patches record how many times they are stepped on.
]

turtles-own[
  happy?                  ; A visitor is happy if they reach their destination.
  steep?                  ; This is true if a visitor always takes the steepest possible route. False - the flatest route is taken.
  outbound?               ; Outbound? is true if a visitor is beginning their hike - walking toward their destination. When a visitor is hiking back to the entrance / parking lot, it is false.
  hike-time-elapsed       ; Tracks how long a visitor has been hiking. This is unique to each visitor/turtle.
  hike-time-planned       ; Each visitor has a specific amount of time they plan to hike.
  target                  ; This is the patch where they plan to move to next, based on the parameters.
  closest                 ; This is their immediate neighboring patch that is closest to their destination.
  my-elevation            ; Visitors know their current elevation - this variable is used to help create the elevation vs. time plot.
  my-neighboring-patches  ; Each visitor has 8 neighboring patches, based on Moore's neighborhood.
  counter                 ; This variable is used to help figure out which 3 of the 8 neighbors are nearest to the visitor's destination. There is probably a better way to code what I used counter for.
  turn-around-time
]


to setup
  ca
  reset-ticks
  ; Source of GIS Data: http://geoserve.asp.radford.edu/merged_dems/dem_utm_zone_17.htm
  ; County: Grayson
  ; Citation: “Merged County DEMs: UTM Zone 17.” UTM Zone 17, Radford University, 26 Sept. 2000, 	geoserve.asp.radford.edu/merged_dems/dem_utm_zone_17.htm.
  set parkData gis:load-dataset "Clipped-Grayson.asc"  ; The Clipped-Grayson.asc file should be in the same folder as this file.

  gis:set-world-envelope gis:envelope-of parkData  ; Makes it so that the dataset spans the entire NetLogo world. Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
  gis:apply-raster parkData elevation   ; Assignes the raster elevation data to the variable elevation.  Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
  display_elevation   ; Runs the function to shade the map based on elevation (white = higher elevation).
  file-close          ; Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw

  set start? false   ; The park manager has not set a destination yet - so the simulation should wait for the park manager.
  select-goal        ; This code runs each tick, and gives the park manager the opportunity to set or change the visitors' destination.
  ask patches [set tread-count 160] ; The tread-count is used in rgb values for patches. By giving all patches a baseline tread-count it makes it so that when trails appear, they have some green shading, rather than being black.
end

to go
  create-visitors   ; With each tick of the model, one new visitor arrives at the park entrance.
  select-goal       ; Gives the park manager the opportunity to set or change the visitors' destination.
  ask turtles [
    set my-neighboring-patches (patch-set neighbors)  ; Each turtle identifies its 8 nearest neighbors (Moore's neighborhood).
    compute-nearest-patches ; Each turtle determines where it should move to next
    move-visitors ; Visitors move one patch closer to their destination
    if start? [   ; The model does not start counting time until the park manager sets a destination.
      set hike-time-elapsed hike-time-elapsed + num-minutes-per-patch-traversed  ; The amount of time required to cross a patch is added to the amount of time a visitor has been hiking when it moves to a new patch with each tick.
    ]
  ]

  ; By tick 500, the model has stabilized, so a single turtle's elevation should be chosen to plot.
  if is-turtle? turtle 500 [  ; Source: http://netlogo-users.18673.x6.nabble.com/How-to-know-a-turtle-is-still-alive-td4869800.html  Citation: “How to Know a Turtle Is Still Alive?” NetLogo-Users - How to Know a Turtle Is Still Alive?, June 2010, netlogo-users.18673.x6.nabble.com/How-to-know-a-turtle-is-still-alive-td4869800.html.
    set track-elevation [my-elevation] of turtle 500  ; The global track-elevation variable is used to report a turtles elevation with each time step to the elevation vs. time graph
  ]
  set world-clock world-clock + 1  ; Tracks how long the simulation has been running. This is useful for waiting to start functions of the model until the 300th tick.
  tick
end


to display_elevation  ; This function prints the shaded elevation map, based on the data's elevation ranges.
  set min-elev gis:minimum-of parkData   ; Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
  set max-elev gis:maximum-of parkData   ; Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
  ask patches [set pcolor scale-color black elevation min-elev max-elev]  ; Source: Yang Zhou's Crater Lake Model, http://geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw
end

to create-visitors
  set-default-shape turtles "person" ; It's too small to see, but the yellow dots have shapes of 'people'
  ask patch 259 50 [sprout 1 [   ; With each tick, a visitor arrives at the entrance
    set size 5 ; Makes the people easier to see
    set happy? false  ; Visitors are not happy until the park gives them a reason to be happy (they reach their destination)
    set color rgb 255 150 0 ; Bright Orange visitors are outbound
    ifelse (random 100) < Percent-Preferring-Steepness [set steep? true] [set steep? false]    ; Visitors are randomly assigned to the steepest, or the flattest route. But the proportions of each depend on the parameter set by the park manager.
    set outbound? true ; All visitors are initially outbound
    set entrance-patch-x 259
    set entrance-patch-y 50
    set hike-time-elapsed 0 ; Initially, visitors have hiked for zero time
    ; Generate an amount of time a visitor plans to hike based on a noraml distribution
    set hike-time-planned random-normal Mean-hike-time-planned Standard-Deviation-hike-time-planned     ; Source: http://ccl.northwestern.edu/netlogo/docs/dict/random-reporters.html  Citation: “Random-Normal.” NetLogo Help: Random-Exponential Random-Gamma Random-Normal Random-Poisson, Northwestern University, ccl.northwestern.edu/netlogo/docs/dict/random-reporters.html.
    ]
  ]
end

to select-goal
  if mouse-down? [ ; This records where the park manager clicks to set the destination for the visitors
    set goal-patch-x mouse-xcor
    set goal-patch-y mouse-ycor
    set start? true
  ]
  ask patch goal-patch-x goal-patch-y [
    set pcolor red  ; Color the destination patch red.
  ]
end


to compute-nearest-patches
    ; If a visitor reaches its destination, record that it reached its destination, and then turn it around to return to the entrance.
    if ([distance-nowrap patch goal-patch-x goal-patch-y] of patch-here <= 1) AND start? AND world-clock > 300 [  ; Source: https://stackoverflow.com/questions/15998359/how-can-i-compute-the-distance-between-two-patches    Citation: “How Can I Compute the Distance between Two Patches?” Simulation - How Can I Compute the Distance between Two Patches? - Stack Overflow, Stack Overflow, Apr. 2013, stackoverflow.com/questions/15998359/how-can-i-compute-the-distance-between-two-patches.
      set outbound? false
      set happy? true
      set turn-around-time hike-time-elapsed ; Records how long a visitor hiked in one direction.
    ]
  ; When visitors return to the entrance, they should leave the model.
  ask turtles with [ ([distance-nowrap patch entrance-patch-x entrance-patch-y] of patch-here <= 1) AND not outbound?] [
    set hike-time-elapsed 0
    die
  ]

  ; Visitors should leave half their planned hike time for the return journey. Through testing, I discovered that dividing by 4 (not 2) worked, even for different speeds. I don't know why
  if (hike-time-elapsed > (hike-time-planned / 4) AND start? AND world-clock > 300) [
    set outbound? false
    set turn-around-time hike-time-elapsed  ; Records how long a visitor hiked in one direction.
  ] ;; Visitors will alot half their hiking time to the return trip.
  if outbound? [
    set counter 0 ; This variable is used to identify the 3 neighbors closest to the destination.
    ; Create a sorted set of a turtle's neighboring patches, based on distance.
    foreach sort-on [distance-nowrap patch goal-patch-x goal-patch-y] my-neighboring-patches [n ->   ; Source: http://netlogo-users.18673.x6.nabble.com/How-to-convert-agentsets-to-a-list-td4864408.html, Source: https://ccl.northwestern.edu/netlogo/3.0/docs/dictionary.html#distance-nowrap
                                                                                                     ; Citation: Steiner, James. “How to Convert Agentsets to a List.” NetLogo-Users - How to Convert Agentsets to a List, 24 May 2008, netlogo-users.18673.x6.nabble.com/How-to-convert-agentsets-to-a-list-td4864408.html. , Citation: “Distance-Nowrap.” NetLogo 3.0.2 User Manual: Primitives Dictionary, Northwestern University, ccl.northwestern.edu/netlogo/3.0/docs/dictionary.html#distance-nowrap.
                                                                                                     ; Another source for sort-on syntax: http://ccl.northwestern.edu/netlogo/docs/dictionary.html#sort-on     Citation: “NetLogo Dictionary.” NetLogo 6.0.2 User Manual: NetLogo Dictionary, Northwestern University, ccl.northwestern.edu/netlogo/docs/dictionary.html#sort-on
      if (counter = 0) [
        ; Assign the neighbor closest to the destination as the initial target, to possibly be overridden later.
        if (abs([elevation] of n - ([elevation] of patch-here))) < max-elev-change [    ; I learned the "[variable] of patch" syntax from: Source: https://stackoverflow.com/questions/32929873/add-a-patch-to-an-agentset-and-remove-a-patch-from-an-agents    Citation: “Add a Patch to an Agentset and Remove a Patch from an Agents.” Netlogo - Add a Patch to an Agentset and Remove a Patch from an Agents - Stack Overflow, Stack Overflow, 4 Oct. 2015, stackoverflow.com/questions/32929873/add-a-patch-to-an-agentset-and-remove-a-patch-from-an-agents.
          set target n ]]
      set counter counter + 1
      if counter = 1 [ set closest n] ; Record the patch closest to the destination, to use in case a visitor ends up in a local maximum, based on model logic.
      if counter <= 3 AND outbound? [  ; Outbound vs. returning visitors have different destinations.
        if steep? [
          ; Prevent visitors from climbing or walking off of a cliff, while finding the steepest of the three patches nearest to the destination.
          if (abs([elevation] of n - ([elevation] of patch-here)) > abs([elevation] of target - [elevation] of patch-here)) AND (abs([elevation] of n - ([elevation] of patch-here))) < max-elev-change [
            set target n
          ]
        ]
        ; Prevent visitors from climbing or walking off of a cliff, while finding the flattest of the three patches nearest to the destination.
        if not steep? [
          if (abs([elevation] of n - [elevation] of patch-here) < abs([elevation] of target - [elevation] of patch-here)) AND (abs([elevation] of n - ([elevation] of patch-here))) < max-elev-change [
            set target n
          ]
        ]
      ]
      ; Prevent the torus-effect of netlogo - prevents a visitor from moving to one of the patches bordering the world.
      while [[pxcor] of target = 0 OR [pxcor] of target = 261 OR [pycor] of target = 184 OR [pycor] of target = 0] [ set target one-of neighbors]   ; Source for one-of syntax: https://stackoverflow.com/questions/32929873/add-a-patch-to-an-agentset-and-remove-a-patch-from-an-agents    Citation: “Add a Patch to an Agentset and Remove a Patch from an Agents.” Netlogo - Add a Patch to an Agentset and Remove a Patch from an Agents - Stack Overflow, Stack Overflow, 4 Oct. 2015, stackoverflow.com/questions/32929873/add-a-patch-to-an-agentset-and-remove-a-patch-from-an-agents.
    ]
  ]
  ; Visitors returning to the entrance need different instructions, because their destination has changed.
  if not outbound? [
    set counter 0
    ; Sort the visitor's neighboring patches based on their distance to the entrance (the returning visitor's destination).
    foreach sort-on [distance-nowrap patch entrance-patch-x entrance-patch-y] my-neighboring-patches [n ->   ;Source: https://ccl.northwestern.edu/netlogo/3.0/docs/dictionary.html#distance-nowrap
      if counter = 0 [ set target n] ; Assign an initial target
      set counter counter + 1
      if counter = 1 [ set closest n] ; Record the patch closest to the destination, to use in case a visitor ends up in a local maximum, based on model logic.
      if counter <= 3 [
        ; Find the steepest of the 3 neighboring patches nearest to the park entrance - that do not violate the maximum elevation change threshold.
        if steep? [
          if (abs([elevation] of n - ([elevation] of patch-here)) > abs([elevation] of target - [elevation] of patch-here)) AND (abs([elevation] of n - ([elevation] of patch-here))) < max-elev-change [ ;set target n]      ;;if elevation n > elevation patch nearest-patch-x nearest-patch-y
            set target n
          ]
        ]
        ; Find the flattest of the 3 neighboring patches nearest to the park entrance - that do not violate the maximum elevation change threshold.
        if not steep? [
          if (abs([elevation] of n - [elevation] of patch-here) < abs([elevation] of target - [elevation] of patch-here)) AND (abs([elevation] of n - ([elevation] of patch-here))) < max-elev-change [ ;[set target n]
            set target n
          ]
        ]
      ]
      ; Prevent turtles from wrapping around the world (torus effect).
      while [[pxcor] of target = 0 OR [pxcor] of target = 261 OR [pycor] of target = 184 OR [pycor] of target = 0] [ set target one-of neighbors]
    ]
  ]

  set my-elevation [elevation] of patch-here  ; This tells turtles their elevation... which is used to help create the elevation vs. time plot.
end

to move-visitors
  ; Prevent visitors from getting stuck in a local maximum... yes, this may cause a visitor to walk off a cliff. This is documented in the write-up.
  if patch-here = target [
    set target closest
    set hike-time-elapsed hike-time-elapsed - 1 ; This cancels out time when the visitor stands still... because the reporters should assume visitors are always moving.
  ]
  if start? [ ; Do not let turtles move until the park manager has clicked a destination, telling them where to go.
    move-to target ; Visitors move to a neighboring patch
  ]
  if not outbound? [set color rgb 170 135 0] ; Visitors returning to the entrance are a dull orange color

  ask patch-here [set tread-count tread-count - 0.6] ; tread-count is used to create a fading-to-bright-green effect. When a turtle steps on a patch, it darkens the green.
  if tread-count < 0 [ set tread-count 0] ; Red-Green-Blue colors must be between 0 and 255. This prevents the errors that would occur if a negative color code were entered.
  if tread-count < 100 [    ; To prevent infrequently traveled paths from being recorded
    ask patch-here [set pcolor rgb tread-count 255 tread-count] ;; tread-count can be 255, max. By decreasing the tread count, the green color gets brighter.
  ]
end

; References used in writing NetLogo Code - Summary of Citations (also embedded in the ode comments):
; “Add a Patch to an Agentset and Remove a Patch from an Agents.” Netlogo - Add a Patch to an Agentset and Remove a Patch from an Agents - Stack Overflow, Stack Overflow, 4 Oct. 2015, stackoverflow.com/questions/32929873/add-a-patch-to-an-agentset-and-remove-a-patch-from-an-agents.
; “Categories of Primitives.” NetLogo User Manual: Primitives Dictionary, Northwestern University, ccl.northwestern.edu/netlogo/2.0/docs/dictionary.html.
; “Distance-Nowrap.” NetLogo 3.0.2 User Manual: Primitives Dictionary, Northwestern University, 	ccl.northwestern.edu/netlogo/3.0/docs/dictionary.html#distance-nowrap.
; “How Can I Compute the Distance between Two Patches?” Simulation - How Can I Compute the Distance between Two Patches? - Stack Overflow, Stack Overflow, Apr. 2013, stackoverflow.com/questions/15998359/how-can-i-compute-the-distance-between-two-patches.
; “How to Know a Turtle Is Still Alive?” NetLogo-Users - How to Know a Turtle Is Still Alive?, June 2010, netlogo-users.18673.x6.nabble.com/How-to-know-a-turtle-is-still-alive-td4869800.html.
; “Random-Normal.” NetLogo Help: Random-Exponential Random-Gamma Random-Normal Random-Poisson, 	Northwestern University, ccl.northwestern.edu/netlogo/docs/dict/random-reporters.html.
; “NetLogo Dictionary.” NetLogo 6.0.2 User Manual: NetLogo Dictionary, Northwestern University, 	ccl.northwestern.edu/netlogo/docs/dictionary.html#sort-on.
; Steiner, James. “How to Convert Agentsets to a List.” NetLogo-Users - How to Convert Agentsets to a List, 24 May 2008, 	netlogo-users.18673.x6.nabble.com/How-to-convert-agentsets-to-a-list-td4864408.html.
; Zhou, Yang. “Geospatial Computational Social Science.” Rainfall and Erosion Model of the Crater Lake National Park 	Using Netlogo, 1 Oct. 2015, geospatialcss.blogspot.com/2015/10/rainfall-model-of-crater-lake-national.html?spref=tw.
@#$#@#$#@
GRAPHICS-WINDOW
124
10
664
393
-1
-1
2.033
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
261
0
183
0
0
1
ticks
30.0

BUTTON
17
37
80
70
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
17
121
80
154
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

SLIDER
673
10
878
43
Percent-Preferring-Steepness
Percent-Preferring-Steepness
0
100
55.0
5
1
%
HORIZONTAL

SLIDER
673
88
901
121
Mean-hike-time-planned
Mean-hike-time-planned
15
480
480.0
15
1
minutes
HORIZONTAL

BUTTON
15
80
109
113
Go Forever
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
959
371
1202
404
max-elev-change
max-elev-change
5
30
20.0
1
1
meters
HORIZONTAL

SLIDER
674
127
973
160
Standard-Deviation-hike-time-planned
Standard-Deviation-hike-time-planned
0
30
5.0
1
1
minutes
HORIZONTAL

SLIDER
673
49
921
82
num-minutes-per-patch-traversed
num-minutes-per-patch-traversed
0.5
5
0.5
0.5
1
minutes
HORIZONTAL

TEXTBOX
9
162
118
414
Orange: Visitors hiking towards their destination.\n\nGold: Visitors returning to their cars.\n\nGreen: Where visitors have walked.\n\nNote: Please wait at least 600 ticks before using model results.
12
0.0
1

TEXTBOX
208
397
689
415
After Clicking Go Forever, set a destination by clicking a point on the terrain.
11
0.0
1

TEXTBOX
931
51
1073
81
Number of minutes required to hike across a patch.
11
0.0
1

PLOT
677
169
950
397
Elevation vs. Time
NIL
NIL
500.0
1300.0
600.0
1700.0
false
false
"" ""
PENS
"elevation" 1.0 0 -16777216 true "" "plot track-elevation"

MONITOR
958
216
1274
261
Number of Park Visitors Who Reached their Destination
count turtles with [happy? = true]
1
1
11

MONITOR
958
269
1231
314
Number of Visitors in the Park on their Return Journey
count turtles with [outbound? = false]
1
1
11

TEXTBOX
961
167
1213
211
Wait at least 500 ticks before reading the monitors counting the number of park visitors who reached their destination.
11
0.0
1

MONITOR
957
319
1267
364
Max Time Any Turtle in the Park has hiked Outbound (minutes)
max [turn-around-time] of turtles\n\n;max [hike-time-elapsed] of turtles
1
1
11

TEXTBOX
1079
10
1261
145
Please let the model run 300 ticks before clicking a destination
22
0.0
1

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
