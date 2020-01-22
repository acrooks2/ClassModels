extensions [ bitmap ]
;; read in bitmap with Haiti damage using buttons on front page; can load in updated map
;; ensure that bitmap is in same directory on server (if applet) or computer (if file) where model is stored.

patches-own [ elevation ]

turtles-own
[
  start-patch
  patches-visited
  resources
]

to setup
;;  clear-all
  clear-turtles
  clear-all-plots
  reset-ticks
  setup-patches
  setup-turtles
  do-plots
end

to setup-patches
  ask patches [ set pcolor pcolor ] ;; pcolor is patch color, color is turtle color
end

to setup-turtles
  create-turtles number [ set size 8 ] ;; turtles representing families can have density set by hand, to reflect outflows/refugees or inflows from other sites
  ask turtles [
    setxy random-xcor random-ycor ;; scatter turtles, representing 1 family each, around the 2 km by 2km landscape
    set patches-visited 0
    set start-patch patch-here
    set color ( pcolor - 2 )      ;; turtles start with color of patches (slightly darker) reflecting current acute state of damage

    ifelse color >= 50            ;; turtles whose home pixel is green (65) or blue (85) are okay; everyone else is not
      [ set resources (resources + 4) ]
    [ set resources (resources + 1) ] ;; turtles whose home pixel was badly damaged lost resources (yellow/45, brown/35, orange/25, red/15, white or black)
  ]
end

to go
  if not any? turtles [
    stop
  ]
  if ticks >= 500 [ stop ]       ;; timescale is 5 ticks per day, representing meal-seeking times, so 500 ticks == 100 days == first ~3 months post-disaster
    ; Now, patch elevation represents food resources for humanitarian relief operations: more height = more food, starting with 2 distribution points
  ask patches
    [
      let elev1 100 - distancexy 30 30
      let elev2 50 - distancexy 120 100
      ifelse elev1 > elev2
         [set elevation elev1]
         [set elevation elev2]
         ;;  elevation is not color-coded, reflecting difficulty of info sharing / discovery of sites -- turtles must explore locally to find food
      ifelse elev1 <= 5            ;; resupply food at site 1, otherwise reduce elevation representing food consumption
         [set elev1 100]
         [set elev1 (elev1 - 5) ]
      ifelse elev2 <= 15            ;; resupply food at site 2, otherwise reduce elevation representing food consumption
         [set elev2 200]
         [set elev2 (elev2 - 5) ]    ]
  move-turtles
  check-death
  tick                    ;; put tick counter BEFORE do-plots
  do-plots
end



to move-turtles
  ask turtles [
    right random 360
    forward random 10
    set resources color - 1
    if elevation >= [elevation] of max-one-of neighbors [elevation] [stop]
    ifelse random-float 1 < q  ;; q constrains movement probability
       [ uphill elevation ]
       [ move-to one-of neighbors ]
    set patches-visited patches-visited + 1
    let distance-moved distance start-patch
    if distance-moved = 0 [set resources resources - 2]
    if distance-moved = 0 [set distance-moved 1]
    set color resources
   ]
end

to check-death
   ask turtles [
      if resources <= 0 [ die ]  ;; Each turtle runs check-death to see if resources are less/equal to 0. If true, turtle must die (die = NetLogo primitive).
  ]                              ;; in real world, "death" would likely represent internal displacement to other locations
end

to do-plots

   show count turtles
   if count turtles >= 1
   [
     plot ( mean [resources] of turtles with [color < 50] + 1 ) ;; families in bad shape
   ]
end
@#$#@#$#@
GRAPHICS-WINDOW
276
10
750
485
-1
-1
2.33
1
10
1
1
1
0
0
0
1
0
199
0
199
0
0
1
ticks
30.0

BUTTON
11
8
67
42
Setup
Setup
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
217
8
272
78
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

MONITOR
11
109
71
142
Worst / red
count patches with [pcolor = 15 ]
1
1
8

SLIDER
11
43
120
76
number
number
0
1000
900.0
1
1
NIL
HORIZONTAL

MONITOR
57
145
107
178
Orange
count patches with [pcolor = 25 ]
1
1
8

MONITOR
101
110
151
143
Yellow
count patches with [pcolor = 45 ]
1
1
8

MONITOR
140
145
190
178
Brown
count patches with [pcolor = 35 ]
1
1
8

MONITOR
217
145
267
178
   Blue
count patches with [pcolor = 85 ]
1
1
8

SLIDER
122
44
214
77
q
q
0
100
90.0
1
1
NIL
HORIZONTAL

BUTTON
10
186
205
219
NIL
import-pcolors filename
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
10
220
271
265
filename
filename
"haiti-damage-2km-12Jan2010.bmp"
0

TEXTBOX
13
79
277
112
                                Patch Damage  \n --Most Severe . . . . . . . . . . . . . . . . . . . . .  Least Severe--
9
122.0
0

MONITOR
184
110
234
143
Green
count patches with [pcolor = 65 ]
1
1
8

BUTTON
68
8
144
42
NIL
clear-patches
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
7
171
275
201
. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
11
0.0
1

BUTTON
145
8
215
42
NIL
clear-turtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
172
268
267
313
OK Families
count turtles with [ color > 51 ]
1
1
11

MONITOR
10
268
167
313
Families in Bad Shape
count turtles with [ color < 51 ]
1
1
11

PLOT
8
314
267
505
Average Resources of Families in Bad Shape
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
"turtles-red" 1.0 0 -2674135 true "" ""
"turtles-orange" 1.0 0 -955883 true "" ""
"turtles-brown" 1.0 0 -6459832 true "" ""
"turtles-yellow" 1.0 0 -1184463 true "" ""
"turtles-green" 1.0 0 -10899396 true "" ""
"turtles-blue" 1.0 0 -13791810 true "" ""

@#$#@#$#@
## WHAT IS IT?

This model is intended to allow naive humanitarian relief providers see the impacts of food delivery / food scarcity on families in the immediate 30 days after a major complex disaster, modeled after the Jan 2010 Haiti earthquake.  After the first 30 days, professionals take over food distribution.  In the immediate aftermath, well-intentioned but less-experienced humanitarian relief providers can actually worsen the situation, such as was seen in Haiti.  Relief workers passed out food at the port, attracting thousands of hungry people, who then clogged the port and blocked logistic resupply of basic necessities such as food, water, emergency shelter, and emergency medical aid.  Because hungry people crowded to get food, dangerous situations resulted from the competition, requiring security to preclude food riots and diverting resources from feeding hungry people.  This model brings Agent-Based Modeling (ABM) and Geospatial Information Systems (GIS) together to create a lightweight scenario planning tool for humanitarian relief workers to experiment with changes in food distribution on the affected families, seeking ways to increase effectiveness of food distribution with less security risk.  The ultimate target hardware is a disconnected iPhone or other handheld computing device, such as a humanitarian aid worker would use in the first 10 to 30 days post-disaster, so simplifying complexity and reducing the model to bare essentials is important.

## HOW IT WORKS

The landscape is a simplified version of the damage maps of a 2-kilometer (km) by 2 km square of Port-au-Prince, Haiti, color-coded to show damage from least (blue) to next (green) through brown, yellow, orange, and finally red (most severe damage).  Each pixel on the 200 pixel by 200 pixel world equals a 10 meter by 10 meter square on the ground.

Turtles represent families, just as the United Nations World Food Programme and other humanitarian relief organizations are bundling relief by family wherever possible.  Turtles have resources, a proxy for food (other humanitarian resupply requirements can be iterated in similar models).   Turtles pick up their initial state - and state of their resources - as a direct mirror of the damage done to their home patch:  patch color becomes turtle's initial color, and the basis for their initial resources.  This reflects the ground truth that if your home was completely destroyed in the earthquake, you have no food resources -- despite your pre-earthquake status.  As resources decline, the turtle's color changes down the scale from acceptable (blue) through green, brown, yellow, orange, red, and black.  If the turtle has no more resources, it "dies" in the model, most likely a proxy for real-world flight to another area such as the Dominican Republic, as seen on the ground.

Amid this world landscape are 2 food distribution points, represented in size by elevation:  larger distribution point is a taller peak, with a larger base for more turtles to hill climb up.  Food competition is represented by the hilltop seeking behavior.  If turtles can climb more, they do and get more resources; otherwise, resources decline.  The peaks are not visible to the naive planner, reinforcing the difficulty of discerning them without effective communications: the turtles spend time seeking locally, without long vision of what is occurring.  Over time, clustering occurs and the planners can discern the center of the food distribution points.

Since the goal of the model is to model the earliest phases of post-disaster humanitarian operations, the model runs for 500 ticks, which at 5 ticks per day (the food-seeking times), represents the first 100 days = ~3 months of post-disaster acute response. After the acute phase is complete, professional relief organizations take over the chronic phase of recovery and rebuilding -- different interpersonal dynamics and logistics considerations dominate this later stage.

Output to the user includes:
-- Starting status of the landscape patches from most damaged (red) to least damaged (blue), by pixel count.  Note that the 40,000 pixels include some which are "neutral," represented by black/dark brown roads and white water features (both needed for logistical transport).
-- Map of the 2 km by 2 km sector in Port-au-Prince, from the 12 Jan 2010 damage map by G-MOSAIC.
-- Counters of families whose resource status is acceptable (colored blue or green) and not okay (brown, yellow, orange, red and other) are shown, above the plot of the mean value of resources of families in the non-blue/non-green range, "families in bad shape."  The goal here is to cue the humanitarian relief provider to track the current situation of those families in most dire need, not simply to average the resource status of all the families.  As resources are consumed, turtles "die" (real world:  likely leave the region), cuing the relief provider to determine where to put the next food resupply operations, in current elevated sites or in more smaller sites dispersed throughout the zone modeled.

## HOW TO USE IT

The user should clear turtles, if any, and press the "Import-pcolors filename" button to load the color-coded bitmap of Haiti into the model.  Other bitmaps can be loaded in by pressing the button marked "Import-pcolors user-file," setting the patch color (pcolor) with the latest version of the 200 pixel by 200 pixel map, representing 2 km by 2 km on the ground.  (Elevation changes currently need to be adjusted within the model procedures.)  Once the map is loaded, user should press "setup" button to breed turtles, install the elevations which represent food resources, and begin the movement and resource changes.

Data preparation of the map is important.  Note that the map is color-coded when captured in a 200 pixel by 200 pixel representation of 2 km by 2 km on the ground.  The color-coding convention used starts with blue as least-damaged, and goes upward in severity of damage through green, brown, yellow, orange, and red (most severe damage).  Water features are marked white, and significant roads are colored black.  Replacement maps should be the same size, and same color-coding.  An enhancement would be to load the elevation (representing food resources) by patch or pixel.

## THINGS TO NOTICE

The current simplified version of the model has an interesting output of the turtles whose resources are "not okay," that is, not blue or green status.  As resources get scarce, turtles "die," which momentarily increases the average resources-per-turtle -- but soon enough things get worse, since there's no follow-on resupply built into the model as needed (ideally, there would be food resupply operations each 10 days, sufficient to care for the inhabitant families and the relief providers).

As an extension, here automatic consumption of food reduces the stock of resources 5 feet in elevation for every tick; a more sophisticated extension could reduce by turtle, by tick.  Then, after the elevation reaches a set lower limit, such as 50 feet, the elevation is automatically raised, representing resupply of food rations (once the logistical resupply operations become more practiced or smoother).

## THINGS TO TRY

Interesting results occur when the family density slider is varied from 250 families in the space up to the maximum of 1000.  Competition for food makes the dynamics increase rapidly, simulating the dangerous situations on the ground such as food riots.

## EXTENDING THE MODEL

The model could be extended in a number of ways, within the consideration of keeping the model as small and as simple as possible, so that the target hardware of the iPhone and the target user of the naive humanitarian aid planner could still allow for significant user-driven modeling.

    As an extension, automatic consumption could reduce the stock of resources 5 feet in elevation for every tick and/or for every turtle which lands on the site, depending on what consumption function is desired to see.  Then, after the elevation reaches a set lower limit, such as 50 feet, the elevation could be automatically raised a specific amount, representing resource resupply of projected days of supply of food, once the logistical resupply operations become more practiced or smoother.

Key extensions could include:
-- Vision can be extended by epoch, from initial to 25 neighbor square at Day 11 or Day 21 of the initial 30 days of post-disaster humanitarian relief operations.
-- Portability of the food distribution sites could be modeled, again in sync with epoch 2 (Day 11) or Epoch 3 (Day 21) of the first phase of post-disaster humanitarian relief operations.
-- Distance traveled as a drain on resources can be modeled, and the distance variables are inserted into the model as "hooks" for extension.
-- Other output imagery to help the naive planner can replace the resources, again within the constraints of the display on the handheld computer / iPhone.

## NETLOGO FEATURES

Bitmap loading to load data into patch colors was a helpful way to visualize damage and understand the resource impact on the families who lived in those areas.

## RELATED MODELS

Wilensky, U. (1999).  NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL; with the NetLogo model Sugarscape-III, based on Epstein, J. M., and R. Axtell (1996). Growing artificial societies: Social science from the bottom up. Cambridge, Massachusetts: The MIT Press.

Railsback, S.F.  and V. Grimm (2009).  A Course in Individual-based and Agent-based Modeling - Scientific Modeling with NetLogo.  http://www.railsback-grimm-abm-book.com/
with the NetLogo model Butterflies-Hilltopping.

## CREDITS AND REFERENCES

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University. Evanston, IL.

Railsback, S.F.  and V. Grimm (2009.  A Course in Individual-based and Agent-based Modeling - Scientific Modeling with NetLogo.  http://www.railsback-grimm-abm-book.com/

Map:  European Union Global Monitoring System (GMES) (2010).  Haiti 2010 Earthquake G-MOSAIC Rapid Mapping service (GMES services for Management of Operations, Situation Awareness and Intelligence for regional Crises), activated 14 Jan 2010.  http://www.gmes-gmosaic.eu/fileadmin/haiti2010/GMOSAIC_Haiti_Activation_Index_of_Products.kml
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
