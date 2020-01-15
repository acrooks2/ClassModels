extensions [gis nw]

globals[
 SDmap
 SDroads
 SDfires-origins
 SDfires
 day
 total-happiness
]

breed [vertices vertex]  ;;for constructing roads
breed [people person]
breed [fires fire]

people-own[
  known-fires  ;;the fires that one is aware of
  happiness  ;;the level of happsiness is affected by distance to fires
  happiness-decrease-congestion  ;;happiness decrease due to congestion he met
  home-patch  ;;where one lives
  near-node  ;;the nearest road node
  target ;;the safe patch to go
  target-node;;the closest node to target
  shortest-path ;;shortest path to its target node
  steps ;; its step on the path
  informed?  ;;true if he/she knows a fire
  otw? ;;if he is on the way already
]

vertices-own[
  myneighbors ;;neighbor nodes
  test ;;variable used for testing
  vertex-shortest-path  ;;from here to target node
  Roadsafe?  ;;if it is safe (not safe if burned)
  ]

fires-own [
  on?  ;;fires on or off? based on date
  firename  ;;name of this fire
  days  ;;on which day does the fire appear
  new-fire  ;;1 if it is new
  ]

patches-own [
  centroid?  ;;if it is centroid
  popu  ;;populaton
  ID
  patch-fire  ;;name of the fire on this patch
  safe? ;;is this patch safe or not
]




to setup

  ca
  reset-ticks

 set SDroads gis:load-dataset "data/Major_Roads/Export_Output.shp"
 set SDmap gis:load-dataset "data/map/Export_Output_2.shp"
 set SDfires gis:load-dataset "data/fires/Export_OutputFIRE.shp"


 gis:set-world-envelope gis:envelope-of SDmap

 foreach gis:feature-list-of SDmap [gis:set-drawing-color 35  gis:fill ? 1.0]

 gis:apply-coverage SDfires "FIRE_NAME" patch-fire
 gis:apply-coverage SDmap "ID" ID


 foreach gis:feature-list-of SDfires [

  ;;locate fires
  let location gis:location-of gis:centroid-of ?
     if not empty? location
           [
             create-fires 1[
                set xcor item 0 location
                set ycor item 1 location
                set size 1.2
                set shape "fire"
                set color red
                set days gis:property-value ? "days"
                set firename gis:property-value ? "FIRE_NAME"
                set hidden? true
                set on? false
                ]]]


 ;;locate roads
 foreach gis:feature-list-of SDroads[

  foreach gis:vertex-lists-of ? ; for the road feature, get the list of vertices
       [
        let previous-node-pt nobody

        foreach ?  ; for each vertex in road segment feature
         [
          let location gis:location-of ?
          if not empty? location
           [
             create-vertices 1
               [;set myneighbors n-of 0 turtles ;;empty
                set xcor item 0 location
                set ycor item 1 location
                set size 0.2
                set shape "circle"
                set color brown
                set hidden? true
                set Roadsafe? true


              ;; create link to previous node
              ifelse previous-node-pt = nobody
                 [] ; first vertex in feature
                 [create-link-with previous-node-pt] ; create link to previous node
                  set previous-node-pt self]
               ;]
           ]]] ]

;;delete duplicate vertices (there may be more than one vertice on the same patch due to reducing size of the map). therefore, this map is simplified from the original map.

  ;;delete-duplicates
      ask vertices [
    if count vertices-here > 1[
      ask other vertices-here [

        ask myself [create-links-with other [link-neighbors] of myself]
        die]
      ]
    ]


  ;;delete some nodes not connected to the network
  ask vertices [set myneighbors link-neighbors]
  delete-not-connected
  ask vertices [set myneighbors link-neighbors]


 ask links [set thickness 0.25 set color 6]

 ;gis:set-drawing-color 65
 ;gis:draw SDroads 1.0


 ;;create people according to popu
 foreach gis:feature-list-of SDmap [

   let create-popu round ((1 / times) * gis:property-value ? "popu")

   if create-popu > 0 [let mypatches patches with [gis:contains? ? self = true]

   repeat create-popu [ask one-of mypatches [sprout 1 [set breed people set shape "circle" set color green set size 0.5 ]]]]
   ]



 ;;some settings
  ask patches [set safe? true]
  ask people [set informed? false set otw? false set happiness 88 set known-fires no-turtles set target 0 set target-node nobody
              set near-node min-one-of vertices in-radius 10 [distance myself ] ]
  set day 1


end



to go
  set total-happiness total-happiness + sum [happiness] of people

  spread-fire

  get-informed

   repeat 8 [  ;;8 hours to move in a day (tick). move one node per tick
       ask people with [informed? = true] [move]
       ask people with [otw? = true and target != 0] [arrive]
       ]

  ;;arriving target
  ;ask people with [otw? = true] [if distance target-node < 1 [move-to target set otw? false set informed? false set target 0
  ;                                                              set near-node min-one-of vertices in-radius 10 [distance myself ] ] ]

  ask people with [informed? = true] [let nearest-fire min-one-of fires with [on? = true] [distance myself] if nearest-fire != nobody[ set happiness distance nearest-fire - happiness-decrease-congestion ]]
  ask people with [informed? = false] [set happiness 88]
  tick
  set day day + 1
  ;if ticks = 25 [stop]
end


to get-informed
  ;;there are three ways to get informed
  ;;1. see the fire in vision
  ;;2. hear about it from social media


  ;;1
  ask people [set known-fires (turtle-set known-fires fires in-radius vision with [on? = true])]
  ask people [if count fires with [on? = true] in-radius vision > 0[set informed? true set home-patch patch-here]]



  if social_networks = true [
  ;;2
  ;;people post about fires that they know on social media
  ask n-of round (0.5 * (count people with [informed? = true]) ) people with [informed? = true] [ ask n-of random 597 people [set known-fires (turtle-set known-fires [known-fires] of myself)]]

  ]
end

to move
      ifelse otw? = true [

        set near-node min-one-of vertices [distance myself ] ;;equals the node it is sitting on


        if target-node != nobody [
           arrive  ;;try to arrive if it can
           let x 0
           if item (steps + 1) shortest-path = nobody [set x 1]
           ask known-fires [ foreach [shortest-path] of myself [if distance myself < vision [set x 1]]]
           if x = 1 [set target 0 set target-node nobody]]

        if target-node = nobody [get-target   get-shortest-path]




        ;;move to next step
        if informed? = true[
          set steps steps + 1
          carefully[
          let next-node item steps shortest-path
          let x people-on next-node
        ifelse count x with [otw? = true] < cars-allowed-on-lane [move-to next-node ][set happiness-decrease-congestion happiness-decrease-congestion + 1]]
          [get-target   get-shortest-path]
          ]]

        ;if steps < length shortest-path[
           ;let next-node item steps shortest-path
           ;let x people-on next-node
           ;if count x with [otw? = true] < cars-allowed-on-lane [move-to next-node set steps steps + 1]]]
       [move-to-road]
end


to move-to-road  ;;try to move to a road
    set near-node min-one-of vertices [distance myself ]
    let x people-on near-node
    ifelse count x with [otw? = true]  < cars-allowed-on-lane [move-to near-node set otw? true][set happiness-decrease-congestion happiness-decrease-congestion + 1]

end

to get-shortest-path

        ask near-node [set vertex-shortest-path nw:turtles-on-path-to [target-node] of myself]
        set shortest-path [vertex-shortest-path] of near-node


        let look-radius vision ;;the radius he looks for road
        let try 0
        while [length shortest-path <= 1][ ;;this happens when the road a round the agent or around the target is burned
                                     ifelse try < 20 [
                                     set try try + 1
                                     let road-to-go one-of vertices in-radius look-radius  ;;move to a further node if stuck in bruned roads
                                     if road-to-go != nobody [move-to road-to-go set near-node min-one-of vertices [distance myself ]
                                     set look-radius look-radius + 1
                                     ask near-node [set vertex-shortest-path nw:turtles-on-path-to [target-node] of myself]
                                     set shortest-path [vertex-shortest-path] of near-node ]]
                                     [get-target get-shortest-path]  ;;try a new target
        ]

        set steps 0

end

to spread-fire

  ask fires [if (day) = days [set on? true st]]

  repeat 3 [ask fires with [on? = true] [ask patches in-radius 1 with [(patch-fire = [firename] of myself) and (count fires-here = 0) ][
        sprout 1 [set breed fires set firename [patch-fire] of myself set shape "fire" set size 1.2 set color red set on? true set new-fire 1]]]]

  ask fires with [on? = true] [ask patches in-radius burn-radius [set safe? false] ask vertices in-radius burn-radius [set Roadsafe? false die]]
end

to delete-not-connected
   ask vertices [set test 0]
 ask one-of vertices [set test 1]
 repeat 500 [
   ask vertices with [test = 1]
   [ask myneighbors [set test 1]]]
 ask vertices with [test = 0][die]

end


to get-target
  ;set shortest-path []
  ;while [ shortest-path = []][
  ;ifelse random-float 1.0 <= 1 [ ;;50% want to move in county; 50% move out of county
     set target one-of patches with [ ID > 0 and distance myself > vision and distance min-one-of [known-fires] of myself [distance myself] > vision]  ;;when slecting destination, people avoid fires they know
     set target-node min-one-of vertices [distance [target] of myself]
     ;ask near-node [set vertex-shortest-path nw:turtles-on-path-to [target-node] of myself]
     ;set shortest-path [vertex-shortest-path] of near-node
    ; ]
end

to restart
  reset-ticks
  ask people [die]
  ask vertices [die]
  ask fires [ if new-fire = 1 [die]  set on? false ht ]

   ;;create people according to popu
   foreach gis:feature-list-of SDmap [

     let create-popu round ((1 / times) * gis:property-value ? "popu")

     if create-popu > 0 [let mypatches patches with [gis:contains? ? self = true]

     repeat create-popu [ask one-of mypatches [sprout 1 [set breed people set shape "circle" set color green set size 0.5]]]]
   ]

   ;;locate roads
 foreach gis:feature-list-of SDroads[

  foreach gis:vertex-lists-of ? ; for the road feature, get the list of vertices
       [
        let previous-node-pt nobody

        foreach ?  ; for each vertex in road segment feature
         [
          let location gis:location-of ?
          if not empty? location
           [
             create-vertices 1
               [;set myneighbors n-of 0 turtles ;;empty
                set xcor item 0 location
                set ycor item 1 location
                set size 0.2
                set shape "circle"
                set color brown
                set hidden? true
                set Roadsafe? true


              ;; create link to previous node
              ifelse previous-node-pt = nobody
                 [] ; first vertex in feature
                 [create-link-with previous-node-pt] ; create link to previous node
                  set previous-node-pt self]
               ;]
           ]]] ]

   ;;delete duplicate vertices (there may be more than one vertice on the same patch due to reducing size of the map). therefore, this map is simplified from the original map.

  ;;delete-duplicates
      ask vertices [
    if count vertices-here > 1[
      ask other vertices-here [

        ask myself [create-links-with other [link-neighbors] of myself]
        die]
      ]
    ]


  ;;delete some nodes not connected to the network
  ask vertices [set myneighbors link-neighbors]
  delete-not-connected
  ask vertices [set myneighbors link-neighbors]


  ask links [set thickness 0.25 set color 6]

   ;;some settings
  ask patches [set safe? true]
  ask people [set informed? false set otw? false
              set near-node min-one-of vertices in-radius 10 [distance myself ] set known-fires no-turtles]
  set day 1
end


to arrive
  if near-node = target-node or distance target-node < 1 [move-to target set otw? false set informed? false set target 0 set target-node nobody
                                                          set near-node min-one-of vertices in-radius 10 [distance myself ] stop]

end
@#$#@#$#@
GRAPHICS-WINDOW
229
20
1093
633
-1
-1
9.705
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
87
0
59
0
0
1
days
30.0

BUTTON
13
23
76
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
85
23
148
56
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

MONITOR
16
73
109
118
population =
count people
17
1
11

INPUTBOX
116
70
188
130
times
5000
1
0
Number

BUTTON
157
24
220
57
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
15
145
187
178
vision
vision
1
20
5
1
1
NIL
HORIZONTAL

TEXTBOX
18
389
214
459
Start date: Oct 27th 2007\nLocation: San Deiago County, CA\n1 tick = 1 day\n1 patch = 0.5 mile
11
0.0
1

SLIDER
17
192
189
225
cars-allowed-on-lane
cars-allowed-on-lane
1
10
15
1
1
NIL
HORIZONTAL

SLIDER
18
238
190
271
burn-radius
burn-radius
1
5
1
1
1
NIL
HORIZONTAL

SWITCH
16
287
190
320
social_networks
social_networks
1
1
-1000

PLOT
1116
73
1560
385
happiness
days
total happiness level
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [happiness] of people"

MONITOR
1115
18
1208
63
avg happiness
total-happiness / ticks
17
1
11

SLIDER
17
337
198
370
anxiety-caused-by-congestion
anxiety-caused-by-congestion
0
50
10
1
1
NIL
HORIZONTAL

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment-off-new" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 25</exitCondition>
    <metric>sum [happiness] of people</metric>
    <enumeratedValueSet variable="social_networks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="burn-radius">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="anxiety-caused-by-congestion">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cars-allowed-on-lane">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="times">
      <value value="5000"/>
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
