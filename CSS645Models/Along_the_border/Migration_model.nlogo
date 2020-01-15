;Migration Model
;CSS 645- final project
;Spring 2019
;Computational Social Science
;George Mason University

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [gis csv]; gis extension for Netlogo
globals [ bb_full bb_zoom us_states border_line mex_states pts_border layer_id ADMIN-Name idlist ordered_patches]; global variables in the model- not all are being actively used
patches-own [station-name country-mex country-us border-here crossing-here crossing-name border_wall counter count1 mex-name] ; this are variables that patches owne and can be coded specifically
breed [people person]; only one breed of turtle; migrants
turtles-own [border-crossing-label district_status my-trajectory time-infected flockmates nearest-neighbor target-patch my-target on-circuit? avoid-water? memory border-crossed-here ]; turtle variables, not all used
breed [crossing-labels crossing-label]; not currently used
breed [district-labels district-label]; not used, this was hard coded
crossing-labels-own [name]; also not included
district-labels-own [state-name] ; also not included


to setup

 clear-all
  reset-ticks
  gis:load-coordinate-system (word "data/mexstates.prj"); projection file
  ;set us_states gis:load-dataset"data/bbox_border.shp"
  ;set bb_zoom gis:load-dataset "data/bbox_zoom.shp"
  set us_states gis:load-dataset "data/us_states.shp" ; united states portion of the map
  set border_line gis:load-dataset "data/Mexico_and_US_Border.shp" ; black border line
  set mex_states gis:load-dataset "data/mexstates.shp" ; mexico portion of the map
  set pts_border gis:load-dataset "data/pts_border.shp"; actual ports of entry

end


to draw
  clear-drawing
  reset-ticks
  gis:set-world-envelope (gis:envelope-union-of ;(gis:envelope-of bb_full)   ;https://github.com/msgeocss/intro_spatial_abm
                                                 ;(gis:envelope-of pts_border)
                                                 (gis:envelope-of mex_states)
                                                 ); This enveloped included the centroids that allowed
  ;agents to flock and get counted. The pts_border envelope was a zoomed in version, but had a harder
  ;time capturing the agents at the borders of the Netlogo grid.

  ask patches [set pcolor 89]; color for all patches before map is added.

gis:apply-coverage us_states "COUNTRY" country-us ; converting the data to variables in Netlogo
gis:apply-coverage mex_states "COUNTRY" country-mex
gis:apply-coverage pts_border "SECTOR" border-here

  ask patches
  [if gis:intersects? pts_border self ; setting crossing_here and adding the map to be coverted to
  [set crossing-here 1] ; allow for Netlogo to use the map
]


 gis:set-drawing-color gray + 3 ; setting color
  gis:draw us_states 2 ; setting size

 gis:set-drawing-color gray + 3
 gis:draw mex_states 2
;
  gis:set-drawing-color black
  gis:draw border_line 4
  ask patches with [border_line = true] ; this is setting the border to black, along with the size
  [set pcolor black]

  gis:set-drawing-color orange
  gis:draw pts_border 7

  ask patches
  [if gis:intersects? pts_border self
    [set crossing-here 1 ]; this is duplicate, but I am keeping it in the code for now.
  ]


  ask patches with [ country-us = "US"]
  [set pcolor green + 3] ; color for the US portion



  ask patches with [country-mex = "MX"]
  [ set pcolor green + 3] ; setting the color for Mexico

  ask patches with [crossing-here = 1 ]
  [set pcolor orange]

  ;https://stackoverflow.com/questions/31496372/is-there-a-way-to-set-patch-color-for-multiple-patches-with-a-single-line-of-cod

ask patches
  [if gis:intersects? border_line self
    [set border_wall 2]; this isn't really doing anything


    ask patches with [border_wall = 2]
   [; set pcolor black]
    ]
  ]

end


to label-districts ; this is hard coding the patches to be the actual ports of entry.

  ask patches at-points [[12 8] [13 7] [14 7]]
  [set station-name "RG" ; Rio Grande Valley (McAllen) ; station name refers to the turtle variable in migrate that allows for them to be counted
    set crossing-here 1] ; as they pass the borders ; crossing-here is referring to the actual GIS border points.
    ask patch 15 6
   [ set plabel "RG"
     set plabel-color black] ;https://stackoverflow.com/questions/25261191/keep-track-of-visited-patches-in-netlogo/25263527#25263527



  ask patches at-points [[9 13] [9 11] [10 11]]
  [set station-name "LR"; Laredo
  set crossing-here 1]
ask patch 12 14
[ set plabel "LR"
  set plabel-color black]

  ask patches at-points [[4 18] [4 19] [5 18] [6 17]]
[set station-name "DR"; Del Rio
  set crossing-here 1]
ask patch 8 19
[set plabel "DR"
  set plabel-color black]

  ask patches at-points [[ -2 17] ];[ -1 17]] ;[0 17]]
    [set station-name "BB"; Big Bend (Marfa)
      set crossing-here 1]
    ask patch -2 20
    [set plabel "BB"
      set plabel-color black]

  ask patches at-points [[ -14 26] [ -13 25] [-12 25]]
  [set station-name "EP" ; El Paso
    set crossing-here 1]
  ask patch -8 25
  [set plabel "EP"
    set plabel-color black]


  ask patches at-points [[ -28 24] [-27 23] [-25 24]]
  [set station-name "TS" ; Tuscon
    set crossing-here 1]
  ask patch -26 27
  [set plabel "TS"
    set plabel-color black]

  ask patches at-points [[-38 28] [ -37 29] [ -37 28] [ -39 29] [-37 29] [-38 29]]
  [set station-name "YM"; Yuma
    set crossing-here 1]
  ask patch -33 29
  [set plabel "YM"
    set plabel-color black]


   ask patches at-points [[-41 29] [ -40 28] [ -39 28]]
  [set station-name "EC"; El Centro
    set crossing-here 1]
  ask patch -41 26
  [set plabel "EC"
    set plabel-color black]


  ask patches at-points [[-47 27] [ -46 27] [ -45 27] [-45 28]]
  [set station-name "SD"; San Diego
    set crossing-here 1]
  ask patch -49 28
  [set plabel "SD"
    set plabel-color black]




end

to setup-turtles
; ca
  ask n-of 100 patches with [country-mex = "MX"] ;n-of random turtles are generated in the MX portion of the map. This is random and represents migrants
  [sprout 1 ; from all backgrounds.
    [
    set shape "person" ; shape, size, kept default color
    set size 1
      set flockmates no-turtles ; initially no flockmates
      let my-closest-border-patch min-one-of (patches  with [crossing-here = 1 ]) [ distance myself ]; initializing with closest border patch
      face my-closest-border-patch ;or anywhere else ;http://netlogo-users.18673.x6.nabble.com/How-to-count-each-time-two-turtles-cross-over-the-same-patch-td5002817.html
      set border-crossed-here false ; face the border patch, and all have not crossed the border to begin with.
  ;    set target-patch one-of patches with [pcolor = black]
    ]
  ]

reset-ticks ; rest when setup is started
end

;to go
;
;  ask turtles
; [
;    move
;    migrate]
;
;end


to migrate ; migrate function. Agents follow the 'Flocking algorithm from the Netlogo Flocking model'


ask turtles

  [

    flock

  ]


   ask turtles [
    fd 0.3 ; the agents move forward at at 0.3
  ]

ask turtles [
    avoid-water]

 ask turtles
  [if pcolor = 89 ;;https://stackoverflow.com/questions/36019543/turtles-move-to-nearest-patch-of-a-certain-color-how-can-this-process-be-sped
    [
      hide-turtle    ; this hides turtles that head towards the water. I wanted to count them, so decided on hide instead of die.
    ]
  ]
 ask turtles
  [ if pcolor = 89
   [
      move-to one-of patches with [pcolor = green + 3] ; this doesn't work at the time of submission. The idea was to have the turtles turn back to the patch
   ] ; this proved hard to implement given the flocking code.


 ]  ;https://github.com/YangZhouCSS?tab=repositories

    ask turtles [ ; this refers to the hard coded ports. This is how the turtles get counted

      let my-patch patch-here
      if  [crossing-here] of my-patch = 1 and border-crossed-here = false [

      set border-crossed-here true;
      set border-crossing-label [station-name] of my-patch
      let my-plabel [plabel] of my-patch ; had to tie the variable to the turtle, because plabel along didn't work.

      ]

      ]

 ask turtles

[
       if ycor >= 30 ;greater smaller than inclusive
      [
         hide-turtle ; hides turtles who get to the top of the Netlogo grid.
    ]
] ;https://stackoverflow.com/questions/21082596/on-netlogo-what-command-do-i-use-to-make-a-turtle-stop-if-the-patch-it-wants-to ]
tick;

end

to avoid-water ; this code is not called anywhere. I have it here for future modifications where agents turn away from the water




    let land-here (neighbors with [ pcolor = green + 3])

;
 if any? turtles-on patches in-radius 3 with [pcolor = 89]

    ;[ ask turtles
        [
      Move-to one-of land-here ]








end

to flock
  find-flockmates
  if any? flockmates
  [find-nearest-neighbor
    ifelse distance nearest-neighbor < minimum-separation ; this part is my modification of the flocking model to include nearest neighbor to the border.
    [separate]
    [align
      cohere]
 ;cross-border
  ]

  ;ask turtles

;[ if patch-ahead border_wall = true

  ;let target-patch = false
  if patch-ahead 1 = target-patch

   ;[ if patch-ahead pcolor = black
   [stop]
;]

end


;
 to move


  let my-origin ["MX"] ; this is to have migrants choose the closest border point. Not only ports of entry, but entire border line.

   ;ask turtles [avoid-water]

ask turtles [avoid-water]

 ask turtles

[
       if ycor >= 29 ;greater smaller than inclusive
      [
         hide-turtle ; hides turtles at the top of the grid, otherwise they get stuck.
    ]
  ]



ask turtles [
   let my-closest-border-patch min-one-of other patches with [crossing-here = 1 ] [ distance self ]
let my-patch patch-here
let my-distance-from-border [distance my-closest-border-patch] of my-patch ;
     ;https://stackoverflow.com/questions/42985154/netlogo-ask-turtle-to-set-destination-and-keep-walking-towards-it-until-reached
    fd 1
  ]



  ask turtles [
      let my-patch patch-here
      if  [crossing-here] of my-patch = 1 and border-crossed-here = false [

      set border-crossed-here true;
      set border-crossing-label [station-name] of my-patch
      let my-plabel [plabel] of my-patch




    ]
      ]

  ask turtles
   [if pcolor = 89
   [
     hide-turtle; hides turtle in water
    ]
  ]

 ; ask turtles

;[
   ;    if ycor >= 30 ;greater smaller than inclusive
  ;    [
  ;       hide-turtle ; hides turtles at the top of the grid, otherwise they get stuck.
   ; ]
 ;; ]



tick;
end;

to find-flockmates  ;; turtle procedure  ; Flocking model- Netlogo- Wilensky, 1998

let my-closest-border-patch min-one-of other patches with [crossing-here = 1 ] [ distance self ]
let my-patch patch-here
let my-distance-from-border [distance my-closest-border-patch] of my-patch
let turtle-neighbors flockmates;
set flockmates no-turtles

 ask turtles-on neighbors
 [
    let neighbor-closest-border-patch min-one-of other patches with [crossing-here = 1] [distance self]; this sets up the flock-mates based on
    let neighbor-patch patch-here ; based on my immediate neighbors. The agents do not see ahead, beyond the 8 patches in a Moore neighborhood configuration.
    let neighbor-distance-from-border [distance my-closest-border-patch] of neighbor-patch
    if my-distance-from-border >= neighbor-distance-from-border
    [
      set turtle-neighbors (turtle-set turtle-neighbors self);
    ]
 ]

  set flockmates turtle-neighbors


end


to find-nearest-neighbor ;; turtle procedure
  set nearest-neighbor min-one-of flockmates [distance myself]; my closest flockmate is my nearest neighbor
end

;;; SEPARATE

to separate  ;; turtle procedure
  turn-away ([heading] of nearest-neighbor) max-separate-turn; separate from getting too close, keeps a reasonable distance
end

;;; ALIGN

to align  ;; turtle procedure
  turn-towards average-flockmate-heading max-align-turn ; sets heading of all turtles for flocking
end

to-report average-flockmate-heading  ;; turtle procedure
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates ; this is calculated to have all turtles with heading of flockmates
  let y-component sum [dy] of flockmates
  ifelse (x-component = 0 and y-component = 0)
    [ report heading ]
    [ report atan x-component y-component ]
end
;
;;; COHERE

to cohere  ;; turtle procedure
  turn-towards average-heading-towards-flockmates max-cohere-turn
end

to-report average-heading-towards-flockmates  ;; turtle procedure
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates ; this was modifed from 360, since I wanted them to only have the range of vision foward
  let y-component mean [cos (towards myself + 180)] of flockmates ; towards the border
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings new-heading heading) max-turn; sets heading
end

to turn-away [new-heading max-turn]  ;; turtle procedure
  turn-at-most (subtract-headings heading new-heading) max-turn; turns away flock differently
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0 ; flocking towards a different direction
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end
@#$#@#$#@
GRAPHICS-WINDOW
198
10
957
473
-1
-1
7.443
1
10
1
1
1
0
0
0
1
-50
50
-30
30
0
0
1
Weeks
30.0

BUTTON
7
147
70
180
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
88
148
151
181
NIL
draw
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
8
21
158
39
Migration Model
11
0.0
1

BUTTON
19
187
137
220
NIL
label-districts
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
80
270
159
303
NIL
migrate
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
1399
10
1492
55
NIL
count turtles
17
1
11

SLIDER
12
314
184
347
vision
vision
0
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
0
430
184
463
minimum-separation
minimum-separation
1
5
1.75
0.25
1
NIL
HORIZONTAL

SLIDER
2
393
185
426
max-align-turn
max-align-turn
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
9
353
181
386
max-cohere-turn
max-cohere-turn
0
20
20.0
1
1
NIL
HORIZONTAL

SLIDER
7
472
188
505
max-separate-turn
max-separate-turn
0
20
0.0
1
1
NIL
HORIZONTAL

BUTTON
20
227
133
260
NIL
setup-turtles
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
7
269
72
302
NIL
move
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
986
10
1110
55
Rio Grande (McAllen)
count turtles with [border-crossing-label = \"RG\"]
17
1
11

MONITOR
1134
11
1191
56
Laredo
count turtles with [border-crossing-label = \"LR\"]
17
1
11

MONITOR
1210
10
1267
55
Del Rio
count turtles with [border-crossing-label = \"DR\"]
17
1
11

MONITOR
1286
10
1351
55
Big Bend
count turtles with [border-crossing-label = \"BB\"]
17
1
11

MONITOR
986
75
1043
120
El Paso
count turtles with [border-crossing-label = \"EP\"]
17
1
11

MONITOR
1058
73
1117
118
Tuscon
count turtles with [border-crossing-label = \"TS\"]
17
1
11

MONITOR
1136
72
1193
117
Yuma
count turtles with [border-crossing-label = \"YM\"]
17
1
11

MONITOR
1211
74
1274
119
El Centro
count turtles with [border-crossing-label = \"EC\"]
17
1
11

MONITOR
1284
73
1349
118
San Diego
count turtles with [border-crossing-label = \"SD\"]
17
1
11

TEXTBOX
9
55
159
139
1. setup\n2. draw\n3. label-distrcits\n4. setup-turtles (agents generated by the 100)\n5. migrate OR move
11
0.0
1

PLOT
987
146
1520
403
Migrants at port-of-entry over time
Weeks
Migrants
0.0
10.0
0.0
10.0
true
true
";set-plot-y-range 0 10" ""
PENS
"Rio Grande (McAllen)" 1.0 0 -11221820 true "" "plot count turtles with [border-crossing-label = \"RG\"]"
"Laredo" 1.0 0 -13493215 true "" "plot count turtles with [border-crossing-label = \"LR\"]"
"Del Rio" 1.0 0 -10649926 true "" "plot count turtles with [border-crossing-label = \"DR\"]"
"Big Bend" 1.0 0 -8630108 true "" "plot count turtles with [border-crossing-label = \"BB\"]"
"El Paso" 1.0 0 -14070903 true "" "plot count turtles with [border-crossing-label = \"EP\"]"
"Tuscon" 1.0 0 -2674135 true "" "plot count turtles with [border-crossing-label = \"TS\"]"
"Yuma" 1.0 0 -955883 true "" "plot count turtles with [border-crossing-label = \"YM\"]"
"El Centro" 1.0 0 -4757638 true "" "plot count turtles with [border-crossing-label = \"EC\"]"
"San Diego" 1.0 0 -15040220 true "" "plot count turtles with [border-crossing-label = \"SD\"]"

@#$#@#$#@
## WHAT IS IT?

This is a model about migration from people using the southwestern United States-Mexico border to enter the United States. The model looks at the behavior and decision-making in regard to how they travel to the border, and how group dynamics and the influence of other people can play a role in the trajectory.

## HOW IT WORKS

The agents are generated on a grid at random. They then have the goal of getting to a border point. In most cases they will head to the closest border. However, the migrate function uses adapted code from the Flocking Netlogo Model, that has the migrants in a more social cohesive group for migrating. The initial turtle heading changes from being the closet border, to the individual that is at the closet point of entry. The migrant will then change course to follow what would be the most "social"/popular border based on the group of people they are with.

The "move" function is simpler and only accounts for distance. Migrant agents simply set their heading to the closet border point of entry/ or border and travel there. The purpose is to see what the pattern of flocking is, and how it differs from "moving" to the nearest border point that only looks at distance.

There are two different functions, with four different parameters that can be used for the ‘migrate’ function. 

Setup: This clear and resets everything, as well as setting up an default functions that needs to be called during the initialization process.

Draw: This draws the GIS map that is rasterized in Netlogo

Label Districts: The districts and ports of entry are labeled 

Setup agents: The agents are set up and sprout in the Mexico grid in random sets of 100
Migrate: This focuses only on the ports of entry.

Alignment -How much people move together with those they will flock with

Separation – distance between the migrants. People flock and avoid moving on top of each because of this

Cohesion- migrants stay together/cohesion of group

Vision: Same goal, range of vision is trying to get to the border. The vision range of the migrants. In the original “Flocking” model, this is set to 360 around them, but this is changed to 180 to ensure that they are facing the border and flocking/following others towards the border.

max-separate- turn away from my nearest neighbor, non-cohesion.

Move:  This has agents moving to the closest border, not only the ports of entry.



## HOW TO USE IT

Setup to reset everything
Draw the map
Label the ports of entry which matter for the count of turtles.
Migrate or move and compare numbers and outcomes. 


## THINGS TO NOTICE and THINGS TO TRY

How do the 'move' and 'migrate' commands differ? What happens when the parameters are adjusted. Does this have an effect on the behaviour of the mirgant 'turtles'?

## EXTENDING THE MODEL

The ports of entry could be more dynamic to allow the model to test for scenarios in which migrants would head towards a closed or oversaturated port of entry and decide to try the next one.

This is a rough network of people that come together to head toward the border. This is theoretical but adding roads and real networks could provide additional insight about how people behave.


## NETLOGO FEATURES

The Migration model was adapted but keeps the mathematics behind the flocking algorithm intact. This note is from the original “Flocking” model “Notice the need for the subtract-headings primitive and special procedure for averaging groups of headings. Just subtracting the numbers, or averaging the numbers, doesn’t give you the results you’d expect, because of the discontinuity where headings wrap back to 0 once they reach 360 *. “The Migration model was adapted but keeps the mathematics behind the flocking algorithm intact.

*This was changed in the Migrant model to 180 degrees to keep the migrants' heading towards the border.

## RELATED MODELS

•	Flocking
•	Moths 
•	Flocking Vee Formation 
•	Flocking - Alternative Visualizations 


## CREDITS AND REFERENCES

This model is inspired by the Flocking model in Netlogo, which was in turn “inspired by the Boids simulation invented by Craig Reynolds. The algorithm we use here is roughly similar to the original Boids algorithm, but it is not the same. The exact details of the algorithm tend not to matter very much – as long as you have alignment, separation, and cohesion, you will usually get flocking behavior resembling that produced by Reynolds’ original model. Information on Boids is available at http://www.red3d.com/cwr/boids/.”
Wilensky, U. (1998). NetLogo Flocking model. http://ccl.northwestern.edu/netlogo/models/Flocking. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

Batty, M. (2001), 'Agent-based Pedestrian Modeling', Environment and Planning B, 28(3): 321-326.

Batty, M. (2003), Agent-Based Pedestrian Modelling, Centre for Advanced Spatial Analysis (University College London): Working Paper 61, London, UK.

Batty, M., Desyllas, J. and Duxbury, E. (2003), 'Safety in Numbers? Modelling Crowds and Designing Control for the Notting Hill Carnival', Urban Studies, 40(8): 1573-1590.
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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="max-cohere-turn">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-separate-turn">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-align-turn">
      <value value="0"/>
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
