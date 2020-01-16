extensions [ gis ]

globals[
 us-map-dataset  ;;GIS data
 num_infected    ;;total number of people infected
 num_uninfected  ;;total number of people uninfected
 pct-infected    ;;percentage infected
 chance-to-infect-others1  ;;probability to infect others
 list-pctHIV    ;;a list of percantage infected in different states. used to draw colors.
]
turtles-own[
  infected?   ;;is it infected with HIV?
  coupled?   ;;is it coupled with another agent?
  partner   ;;his/her partner
  chance-to-infect-others  ;;probability to infect others
  age
  traveled?  ;;did he do a long-dstance travel? if he did, return to where he was at the end of this tick.
  last-position  ;;where he was before travel
  myID  ;;ID number
 ]
patches-own[centroid? ;;if it is a centroid of a polygon or not
            ID  ;;ID number
            popu  ;;popuation. centroid only.
            pctHIV  ;;percentage infected. centroid only.
            maxticket  ;;max ticket number, used to do weighted selection for travel. centroid only.
            minticket  ;;min ticket number, used to do weighted selection for travel. centroid only.
            red-here  ;; number of infected agent in this state. centroid only.
            green-here ;; number of uninfected agent in this state. centroid only.
  ]




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;setup

to setup
 ca
 reset-ticks
 gis:load-coordinate-system (word "data/states.prj")
 set us-map-dataset gis:load-dataset "data/states.shp"   ;;reading data from shapefile


  ;;each polygon identifies a patch at centroid, which records all the information about the data.

  foreach gis:feature-list-of us-map-dataset
  [ ?1 -> let center-point gis:location-of gis:centroid-of ?1
    ask patch item 0 center-point item 1 center-point [
      ;if ID != gis:property-value ? "ID_ID" [print "ERROR"]    ;;verify they have identical ID
      set centroid? true
      set ID gis:property-value ?1 "ID"
      set popu gis:property-value ?1 "POPU"
      set pctHIV gis:property-value ?1 "pctHIV"
      set minticket gis:property-value ?1 "min"
      set maxticket gis:property-value ?1 "max"
      ] ]

 ;;draw scaled color based on percentage infected
   foreach gis:feature-list-of us-map-dataset
  [ ?1 -> gis:set-drawing-color scale-color red (gis:property-value ?1 "pctHIV") 0.015 0.00040
    gis:fill ?1 2.0 ]

  gis:set-drawing-color grey
  gis:draw us-map-dataset 1

  gis:apply-coverage us-map-dataset "ID" ID


  ;;create turtles in polygons based on data
  let y 1
  while [y <= 49] [

     ask patches with [centroid? = true and ID = y]
     [let popu1 round (popu / 100000)
      set num_infected (round (pctHIV * popu1) )
      set num_uninfected popu1 - num_infected]

     repeat num_infected [ask one-of patches with [ID = y] [sprout 1 [set shape "person" set size 1.5 set infected? true assign-color set age random 5]  ]]
     repeat num_uninfected [ask one-of patches with [ID = y] [sprout 1 [set shape "person" set size 1.5 set infected? false assign-color set age random 5]  ]]

     set y y + 1
     ]
   check-switches
end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;go




to go
  ;;when age = 6, die, and sprout a new agent. new agents has 1% chance to be HIV infected.
  ask turtles [if age = 6 [ask patch-here [sprout 1 [set shape "person" set size 1.5
          ifelse random 100 = 1 [set infected? true][set infected? false]
          assign-color set age random 5]]die]]

  check-switches  ;;check condom use and risk assessment


  ;;reset
  ask turtles[
    set myID [ID] of patch-here
  set coupled? false
  set partner nobody]


  ask turtles[
  move            ;;either local move or long-distance travel
  couple          ;;find a partner if it can.
  ]

  ask turtles with [coupled? = true] [interact]   ;;interact with partner.
  ask turtles [set age age + 1]


  ask turtles with [traveled? = true][move-to last-position]   ;;after long-distance travel, move back to the state it is from.

  set pct-infected (count turtles with [color = red]) / (count turtles)
  tick

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;helper functions



to move
  set traveled? false
  ifelse random 100 < prob-for-long-distance-travel [
    ;;long distance travel
    set last-position patch-here
    set traveled? true
    ;;weighted selection of states using the lottery method
    let pick (random 1130 + 1)
  ask patches with [centroid? = true] [if minticket <= pick and maxticket >= pick [ask myself [move-to one-of patches with [ID = [ID] of myself] ]]]]

  ;;local travel
  [ let nearby-patches patches in-radius 5
    set nearby-patches nearby-patches with [ID = [myID] of myself]
    move-to one-of nearby-patches]

end

to couple

  let potential-partner one-of turtles in-radius 5
                          with [not coupled? and myID = [myID] of myself]
  if potential-partner != nobody
      [ set partner potential-partner
        set coupled? true
        ask partner [ set coupled? true ]
        ask partner [ set partner myself ]]
end

to interact
  if infected? = true [ if random-float 100 < chance-to-infect-others [ask partner [set infected? true set color red]]]
end


to assign-color  ;; turtle procedure. change color to red if infected.
  ifelse not infected?
    [ set color green ][set color red]
end


;; In each tick a check is made to see if sliders have been changed.
;; If one has been, the corresponding turtle variable is adjusted

to check-switches

  set chance-to-infect-others1 100

  if Condom-Use
    [ set chance-to-infect-others1 chance-to-infect-others1 * 0.2]

  if Risk-assessment = 4
    [set chance-to-infect-others1 0]

   ask turtles with [infected? = true] [set chance-to-infect-others chance-to-infect-others1 ]


end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;drawing scaled-color based on simulation results.

;;draw scaled-color based on percentage of HIV cases
to draw
  set list-pctHIV []
  ask patches with [centroid? = true][

      let myturtles turtles-on patches with [ID = [ID] of myself]

      set red-here count myturtles with [color = red]
      set green-here count myturtles with [color = green]


    ifelse red-here + green-here > 0 [set pctHIV red-here / (red-here + green-here)][set pctHIV 0]
    set list-pctHIV lput pctHIV list-pctHIV
    ]


   ;;draw the color
   foreach gis:feature-list-of us-map-dataset
   [ ?1 -> let thepctHIV [pctHIV] of patches with [centroid? = true and ID = gis:property-value ?1 "ID"]


   gis:set-drawing-color scale-color red item 0 thepctHIV (max list-pctHIV + 0.1) min list-pctHIV
    gis:fill ?1 2.0 ]

end


;;draw scaled-color based on count of HIV cases
to draw2
  set list-pctHIV []
  ask patches with [centroid? = true][

      let myturtles turtles-on patches with [ID = [ID] of myself]

      set red-here count myturtles with [color = red]
      set green-here count myturtles with [color = green]


    set pctHIV red-here
    set list-pctHIV lput pctHIV list-pctHIV
    ]


   ;;draw the color
   foreach gis:feature-list-of us-map-dataset
   [ ?1 -> let thepctHIV [pctHIV] of patches with [centroid? = true and ID = gis:property-value ?1 "ID"]


   gis:set-drawing-color scale-color red item 0 thepctHIV (max list-pctHIV ) min list-pctHIV
    gis:fill ?1 2.0 ]

end
@#$#@#$#@
GRAPHICS-WINDOW
234
10
980
757
-1
-1
1.8404
1
10
1
1
1
0
1
1
1
-200
200
-200
200
0
0
1
ticks
30.0

BUTTON
93
10
156
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

SWITCH
14
99
129
132
Condom-Use
Condom-Use
1
1
-1000

MONITOR
17
238
91
283
Infected
count turtles with [color = red]
17
1
11

MONITOR
107
238
179
283
Total
count turtles
17
1
11

MONITOR
18
288
91
333
Uninfected
count turtles with [color = green]
17
1
11

BUTTON
18
51
81
84
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
13
143
146
176
Risk-assessment
Risk-assessment
1
4
2.0
1
1
NIL
HORIZONTAL

PLOT
15
350
215
500
Percentage Infected
NIL
NIL
0.0
10.0
0.0
0.2
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot pct-infected"

SLIDER
11
193
222
226
prob-for-long-distance-travel
prob-for-long-distance-travel
0
100
66.0
1
1
NIL
HORIZONTAL

BUTTON
91
52
154
85
NIL
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
1024
195
1090
228
NIL
draw2
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
1020
81
1086
114
draw1
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
1023
130
1129
186
Draw scaled-color according to percentage HIV
11
0.0
1

TEXTBOX
1026
247
1116
343
Draw scaled-color according to count of HIV
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the impact of population density and travel on the diffusion of HIV in the 48 contiguous states and the District of Columbia (hereafter referred to as a state). This model has possible implications for those inerested in examining how to best pinpoint HIV prevention education efforts. The model is set spatially based on state polygon data from ArcGIS. The polygons are populated based on the US population on a 1/100,000th scale. The five most travelled states have a gravity pull that allows the travel to be determined based on that weight.

Here is a map showing the original data on percentage of HIV cases in the U.S.

![Picture not found](file:data/ushiv.jpg)



## HOW IT WORKS

The agents in the model represent individuals who belong to a state as their home state and are either infected or not. Infected agents are red. Uninfected agents are green. The number that are infected at setup is based on the percentage of HIV infected in each state on a scale of 1/100,000 of the real HIV infected population. 

At each time step, the agents travel. Whether they travel within their state or outside of their state is based on the probability set on the PROB-FOR-LONG-DISTANCE-TRAVEL slider. Once they travel they look around for an uncoupled partner within a radius of 5. If they find a partner, they then interact if they are infected to replicate the possible ability the infection to transfer. The rate at which the infection tranfers from an infected individual to an uninfected individual is determined by the CONDOM-USE switch and the RISK-ASSESSMENT slider. Then, the agents who are outside of their state return to their home state and the time step ends.



## HOW TO USE IT

There is a switch that allows CONDOM-USE to be turned on or off, a RISK-ASSESSMENT slider that sets the number HIV testings for the agents per year, and a slider that sets the probability that the agents travel long distance. Long distance travel is defined as an agent leaving their state. The CONDOM-USE switch, when ON, creates an 80% chance of transmission. The RISK-ASSESSMENT slider, when set to 4 times per year, ensures 100% condom-use.

In addtion to changing the CONDOM-USE switch, RISK-ASSESSMENT slider, and PROB-FOR-LONG-DISTANCE-TRAVEL, there are to DRAW buttons. DRAW 1 allows the viewer to set the colors of the states based on percentage of HIV infection. DRAW 2 allows the viewer to set the colors of states based on the count of HIV infected agents.

## THINGS TO NOTICE

Running the program in its default settings demonstrates how the gravity of the highly traveled states continues to keep infection rates high in those areas. 

Notice the impact of how starting population rates distributed at the setup, continue to impact how the HIV rates diffuse.


## THINGS TO TRY

Next, notice what the CONDOM-USE switch when turned on does to the transmission rates. Then, add to this the RISK-ASSESSMENT slider, set to 4, impacts this rate. Under both conditions, set the PROB-FOR-LONG-DISTANCE-TRAVEL low to high to see how that diffusion rate is distributed.

## EXTENDING THE MODEL

Additional modifications that would add further insights would be to add variation to the agents to mimic demographics.

## NETLOGO FEATURES

This NETLOGO model uses shape file imports to replicate the geographic space. To allow the agents to maintain a home state the state polygon are set as centroids.

## RELATED MODELS

There is a NETLOGO model library model that addresses AIDS diffusion. This model does not include a geographic element, but it does incorporate a condom usage and risk assessment setting to mirror real world attempts to limit transmission of the disease.


## CREDITS AND REFERENCES

The separate AIDS model mentioned above is cited as:

Wilensky, U. (1997). NetLogo AIDS model. http://ccl.northwestern.edu/netlogo/models/AIDS. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.
Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.
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
