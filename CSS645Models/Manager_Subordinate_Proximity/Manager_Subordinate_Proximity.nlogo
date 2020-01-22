
extensions [
  nw
]

;; create two breeds to differentiate between people/employees and cells
breed [indis indi] ;; should probably have a separate breed for managers - had previously but went to single breed
breed [cells cell]   ;; for lattice network on top of patches

turtles-own [
  flr          ;; variable to store object's floor in building
  objecttype   ;; variable to classify type of object
]

globals [
  ;; sets of rooms
  bathrooms
  kitchens
  printers
  meetingrooms
  elevator
  destinations1
  destinations2
  destinations
  ;; managers (easier to refer to by object name)
  mgr1
  mgr2
  ;; some agentsets to keep track of teams (and on floors)
  mgr1hasntseen
  mgr2hasntseen
  mgr1flr1emps
  mgr1flr2emps
  mgr2flr1emps
  mgr2flr2emps
]

indis-own [
  manager?         ;; BOOLEAN if agent is a manager
  deskloc          ;; store agent's assigned desk
  destination      ;; where agent is going
  destination-path ;; list of cells on path to destination
  countdown        ;; each agent has a counter before s/he gets up and does something
  wait-countdown   ;; a countdown for how long an agent stays at a particular place
  mymgr            ;; my manager
  mymgrsmflr?      ;; BOOLEAN if agent's manager is on same floor
  crowdistmgr      ;; TO IMPLEMENT - determine point-to-point distance between manager and subordinate
  pathdistmgr      ;; TO IMPLEMENT
  timewmgr         ;; actually time spent colocated with manager (in seconds)
  peopleiveseen    ;; agentset of people Ive seen
]

  cells-own [
    traversible? ;; BOOLEAN to track if agent can walk here
    path-counter ;; tracks number of seconds an agent has been here
  ]

patches-own [
;  pflr        ;; which floor?
;  pobjecttype ;; variable to classify type of object here
]

links-own [
  weight       ;; use to impact likelihood of taking elevator since increased weight increases weighted-path distance
]

to setup-office
  clear-all

  ;; currently working from a single, static floorplan that I drew and exported - additional space configurations could be
  ;;   tested in future iterations/models
    import-world "floorplan"  ;; BUG - this imports the *world* including parameter settings, which interferes with BehaviorSpace - not sure how to fix this

;; CREATE SPATIAL ENVIRONMENT
;;   create floor divider and elevator
ask patches [ if pxcor = 0 [ set pcolor red ] ] ;; representation of space between two floors of building
ask patch 0 0 [ set pcolor yellow ]             ;; represents elevator

;; create cell objects on top of patches (to link them together as a lattice)
  ask patches [
    sprout 1 [
      set color [pcolor] of self
      set breed cells
      set shape "dot"
      ;; use boolean flag to track whether a cell is reachable/walkable by agents
      ifelse (color != white) and (color != red) and (color != brown) [ ; and (color != yellow) [
        set traversible? TRUE ]
        [ set traversible? FALSE ]
      ;; have each cell set what it is
      if (color = violet) [ set objecttype "Kitchen" ]
            if (color = blue) [ set objecttype "Bathroom" ]
                  if (color = grey) [ set objecttype "Printer" ]
                        if (color = green) [ set objecttype "Meeting Room" ]
                              if (color = brown) [ set objecttype "Desk" ]
                                    if (color = white) [ set objecttype "Wall" ]
                                          if (color = black) [ set objecttype "Space" ]
                                                if (color = red) [ set objecttype "Between floors" ]
                                                     if (color = yellow) [ set objecttype "Elevator" ]
       ht ; hide the spawned cells so they don't mess up the visualization
    ]
  ]

;; create lattice network
  ask cells with [ traversible? = TRUE ] [
    let fullset cells-on neighbors4
    let linkset (fullset with [traversible? = true ]) ;; only want traversible cells
    create-links-with linkset [ set weight 1.0 ]
  ]
 set elevator one-of cells with [ objecttype = "Elevator" ]
 ask elevator [
   create-link-with one-of cells-on patch -1 0
   create-link-with one-of cells-on patch 1 0
   let elevlinks my-links
   let wt elevator-barrier
   ask elevlinks [ set weight elevator-barrier ]
   ]
 ;; hide the cell-cell links (comment the following line to see the lattice)
  ask links [hide-link]

  ;; set floors
  ask cells [ set-floor ]

  ;; use agentsets/lists to keep track of possible destinations
  set bathrooms ( cells with [ objecttype = "Bathroom" ] )
  set kitchens  ( cells with [ objecttype = "Kitchen" ] )
  set printers  ( cells with [ objecttype = "Printer" ] )
  set meetingrooms ( cells with [ objecttype = "Meeting Room"  ] )
  set destinations (turtle-set bathrooms kitchens printers meetingrooms)
  set destinations1 ( destinations with [ flr = 1 ] )
  set destinations2 ( destinations with [ flr = 2 ] )
  ask patches with [ pcolor = 115 ] [ set plabel "Kit" ]
    ask patches with [ pcolor = 5 ] [ set plabel "Prt" ]
      ask patches with [ pcolor = 55 ] [ set plabel "Mtg" ]
        ask patches with [ pcolor = 105 ] [ set plabel "Bth" ]
  reset-ticks
end

to setup-employees
  if (count cells > 465) [
    user-message("WARNING - potentially more than one layer of cells!")
    stop
  ]
  ;; basically, "setup" to populate the office with employees
  set-default-shape indis "person"
  ;; first, add managers
  ask patch -14 -6 [
    sprout 1 [
      set breed indis
      set color 97
      set manager? TRUE
      set mgr1 self
    ]
  ]

  ask patch 2 -6 [
      sprout 1 [
        set breed indis
        set color 117
        set manager? TRUE
        set mgr2 self
      ]
  ]

  repeat round (%-desks-filled / 100 * count patches with [ pcolor = brown ])
  [   ;; slider allows for fewer employees than seats
    ask one-of patches with [ pcolor = brown and ( count indis-on neighbors4 with [ pcolor = black ] ) = 0 ] [
      ask one-of neighbors4 with [ pcolor = black ]  ;; instead of putting employees *on* desks, they sit adjacent to them in an "open office" environment
  [ sprout 1
    [
      set breed indis
      ;; set color blue
      set manager? FALSE
      if (mgr-same-floor-only) [  ;; if parameter set to same floor manager only, link with the manager on my floor
        ifelse xcor < 0
          [ create-link-with one-of indis with [ (manager? = TRUE) and (xcor < 0) ] ]
          [ create-link-with one-of indis with [ ( manager? = TRUE) and (xcor > 0) ] ]
      ]
      if (not mgr-same-floor-only) [  ;; otherwise, link with either manager
;        let rand random-float 1
;        ifelse (rand <= 0.5) [ create-link-with mgr1 ]
;                             [ create-link-with mgr2 ]
        create-link-with one-of indis with [ manager? = TRUE ]
      ]
      set mymgr one-of link-neighbors
      ask links [ hide-link ]
      set color [ color ] of one-of link-neighbors - 3
    ]
  ]
  ]
  ]
;; set variables common to both manager and employee agents
;; set floor variables
ask turtles [ set-floor ]
ask indis [ set-instance-vars ]
setup-agentsets ;; to track teams
reset-ticks
end

;; agents set their individual instance variables
to set-instance-vars
  set deskloc one-of cells-here
  if (manager? = FALSE) [
  ifELSE ( [flr] of mymgr = [flr] of self ) [
    set mymgrsmflr? TRUE ]
  [ set mymgrsmflr? FALSE ]
  ]
  set peopleiveseen no-turtles
  reset-counter
  select-destination
end

;; these agentsets make it easier to refer to groups of agents in the model
to setup-agentsets
  ask mgr1 [
    set mgr1hasntseen link-neighbors
  ]

  ask mgr2 [
    set mgr2hasntseen link-neighbors
  ]

  ask mgr1 [
    set mgr1flr1emps link-neighbors with [ flr = 1 ]
    set mgr1flr2emps link-neighbors with [ flr = 2 ]
  ]

  ask mgr2 [
    set mgr2flr1emps link-neighbors with [ flr = 1 ]
    set mgr2flr2emps link-neighbors with [ flr = 2 ]
  ]
end

to reset-counter  ;; done during setup and when agent returns to desk ;; NOTE - added 0.2 multiplier just to speed up simulation
  set countdown 0.2 * abs (random-normal 3600 1800) ;; random 20  ; abs (random-normal 120 30)
  set wait-countdown 0.2 * random-poisson 300
end

;; agents track their "home" floor
to set-floor
  if (xcor < 0) [ set flr 1 ]
  if (xcor > 0) [ set flr 2 ]
end

;; following code block inspired by Powell (2013) Workplace Collaboration model (http://modelingcommons.org/browse/one_model/3705)
to draw
  reset-ticks
  if mouse-down? [
    let x round mouse-xcor
    let y round mouse-ycor

    if (draw-what? = "printer") [
      ask patch x y [ set pcolor grey ]
    ]

    if (draw-what? = "bathroom") [
      ask patch x y [ set pcolor yellow ]
    ]

    if (draw-what? = "desk") [
      ask patch x y [ set pcolor brown ]
    ]

    if (draw-what? = "nothing(clear)") [
      ask patch x y [ set pcolor black ]
    ]

    if (draw-what? = "kitchen") [
      ask patch x y [ set pcolor violet ]
    ]

    if (draw-what? = "wall") [
      ask patch x y [ set pcolor white ]
    ]

    if (draw-what? = "meeting room") [
      ask patch x y [ set pcolor green ]
    ]

    if (draw-what? = "elevator") [
      ask patch x y [ set pcolor yellow ]
    ]

    if (draw-what? = "employee") [
      ask patch x y [ sprout 1 [
          set breed indis
          set-instance-vars ]
      ]
    ]

    if (draw-what? = "manager") [
      ask patch x y [ sprout 1 [
          set breed indis
          set manager? TRUE
          set color red
          set-instance-vars ]
      ]
    ]

    ]
    tick
  end

; EXPORT OFFICE FLOORPLAN
to export-floorplan
  export-world "floorplan"
end

; IMPORT OFFICE FLOORPLAN
to import-floorplan
  import-world "floorplan"
end

;; end citation of Powell

to go
  if ( ticks = 30000) [ stop ] ;; stopping condition - 30K seconds, or roughly one 8-hour workday
  if any? indis with [ countdown < 1 ] [
    ask indis [
      if countdown < 1 [
        set-path
        move
      ]
     ]
  ]
  ;; TRACK ENCOUNTERS
  ask indis [
    if any? other indis-here [
      if member? one-of link-neighbors indis-here [  ;; if my boss is one of the agents here
        if manager? = FALSE [
          set timewmgr timewmgr + 1             ;;   increment my "time with" counter
        ]
      ]
      record-encounter
    ]
  ]
;
  ;; decrement countdown
  ask indis [ set countdown countdown - 1
    set label timewmgr ]
  tick
end

;; keep track of which agents are here, and if my manager is here, remove myself from the "hasn't seen" agentset
to record-encounter
  let tempagentset other indis-here

  set peopleiveseen (turtle-set peopleiveseen tempagentset)
  if (any? tempagentset with [mymgr = myself])  [
      ask tempagentset with [ mymgr = myself ] [
        if ( [flr] of mymgr = 1) [
         set mgr1hasntseen other mgr1hasntseen ]
        if ( [flr] of mymgr = 2) [
         set mgr2hasntseen other mgr2hasntseen ]
       ]
  ]
  ;; the above is very, very ugly and could probably be coded better!
end

;; simple random selection of destination, incorporating probability of meeting on other floor
to select-destination
  ifelse ( flr = 1 ) [
    set destination one-of destinations1 ]
  [ set destination one-of destinations2 ]
  if ( [ objecttype ] of destination = "Meeting Room" ) [
    let rand random-float 1
    if (rand < prob-of-having-mtg-on-other-floor) [
      set destination one-of meetingrooms with [ flr != [ flr ] of myself ]
    ]
  ]
end

;; use the NW extension to calculate the shortest path between current location and my destination
;;   NOTE:  I learned how to do this from studying Powell's model
to set-path

  nw:set-context cells links

  let shortestpath 0
  let node one-of cells-here ;; cell on which employee is standing / current spatial network node

  if (node != destination) [
    ask node [ set shortestpath nw:turtles-on-path-to ( [ destination ] of myself ) ] ;; ask current cell/node to determine shortest network path to calling agent's destination
    set destination-path shortestpath
  ]

  if (node = destination) and (destination != deskloc) [
    set wait-countdown wait-countdown - 1
    if wait-countdown < 1 [
      set destination deskloc
      ask node [ set shortestpath nw:turtles-on-path-to ( [ destination ] of myself ) ] ;; go back to my desk
      set destination-path shortestpath
    ]
  ]

    if (node = destination) and (destination = deskloc) [
      reset-counter
      select-destination
;    select-destination
;    ask node [ set shortestpath nw:turtles-on-path-to ( [ destination ] of myself ) ]
;    set destination-path shortestpath
  ]
end

to move
  if (show-trails?) [
    pen-down ]
  if (length destination-path > 0) [
    let nextstep item 1 destination-path
    move-to nextstep
    ask nextstep [ set path-counter path-counter + 1
      ; set color path-counter / 100 ; trying to visualize the most frequent paths
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
278
4
930
325
-1
-1
20.8
1
10
1
1
1
0
0
0
1
-15
15
-7
7
0
0
1
seconds
30.0

BUTTON
2
47
110
80
NIL
setup-office\n
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
956
25
1019
58
NIL
draw
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
956
60
1094
105
draw-what?
draw-what?
"wall" "desk" "kitchen" "bathroom" "printer" "meeting room" "elevator" "employee" "manager" "nothing(clear)"
1

BUTTON
958
147
1094
180
NIL
export-floorplan
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
959
186
1095
219
NIL
import-floorplan
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
1031
25
1094
58
clear
clear-all
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
2
98
174
131
%-desks-filled
%-desks-filled
1
100
80.0
1
1
NIL
HORIZONTAL

BUTTON
2
172
141
205
NIL
setup-employees
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
2
135
194
168
mgr-same-floor-only
mgr-same-floor-only
1
1
-1000

BUTTON
3
270
66
303
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

BUTTON
70
270
133
303
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

SWITCH
3
307
165
340
show-trails?
show-trails?
1
1
-1000

BUTTON
947
254
1112
287
hide/unhide cell layer
ifelse any? cells with [ hidden? = FALSE ]\n[ ask cells [ ht ] ]\n[ ask cells [ SET hidden? FALSE ] ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
570
353
941
503
Manager-Subordinate overlap
NIL
NIL
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"mgr1_flr1_emps" 1.0 0 -13345367 true "" "if (mgr1flr1emps != 0) [\nplot sum [ timewmgr ] of mgr1flr1emps\n]"
"mgr1_flr2_emps" 1.0 0 -11221820 true "" "if (mgr1flr2emps != 0) [\nplot sum [ timewmgr ] of mgr1flr2emps\n]"
"mgr2_flr2_emps" 1.0 0 -8630108 true "" "if (mgr2flr2emps != 0) [\nplot sum [ timewmgr ] of mgr2flr2emps\n]"
"mgr2_flr1_emps" 1.0 0 -5825686 true "" "if (mgr2flr1emps != 0) [\nplot sum [ timewmgr ] of mgr2flr1emps\n]"

SLIDER
2
10
253
43
elevator-barrier
elevator-barrier
1
100
20.0
1
1
NIL
HORIZONTAL

TEXTBOX
961
10
1111
28
OFFICE FLOORPLAN TOOLS
11
0.0
1

SLIDER
2
233
255
266
prob-of-having-mtg-on-other-floor
prob-of-having-mtg-on-other-floor
0
1
0.7
0.1
1
NIL
HORIZONTAL

TEXTBOX
987
236
1137
254
OTHER TOOLS
11
0.0
1

PLOT
207
353
563
503
Destinations (should be abt equivalent)
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
"kitchens" 1.0 0 -8630108 true "" "plot sum [ path-counter ] of kitchens"
"printers" 1.0 0 -7500403 true "" "plot sum [ path-counter ] of printers"
"mtg rooms" 1.0 0 -10899396 true "" "plot sum [ path-counter ] of meetingrooms"
"bathrooms" 1.0 0 -13345367 true "" "plot sum [ path-counter ] of bathrooms"

MONITOR
943
298
1038
343
elevator trips
[ path-counter ] of elevator
17
1
11

MONITOR
4
356
152
401
% haven't seen boss today
( precision (\n  count indis with [ (timewmgr = 0) and (manager? = FALSE) ] / \n  count indis with [ manager? = FALSE ]\n) 4 ) * 100
17
1
11

MONITOR
200
165
255
210
# emps
count indis with [manager? = FALSE]
17
1
11

MONITOR
4
405
150
450
NIL
mgr1hasntseen
17
1
11

MONITOR
4
453
150
498
NIL
mgr2hasntseen
17
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
  <experiment name="parameter_sweep" repetitions="1" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
    <enumeratedValueSet variable="show-trails?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-desks-filled">
      <value value="10"/>
      <value value="40"/>
      <value value="70"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mgr-same-floor-only">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boss-takes-random-walks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-having-mtg-on-other-floor">
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-what?">
      <value value="&quot;desk&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevator-barrier">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NEED_BASELINES-bothways" repetitions="1" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
    <enumeratedValueSet variable="show-trails?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-desks-filled">
      <value value="10"/>
      <value value="40"/>
      <value value="70"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mgr-same-floor-only">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boss-takes-random-walks?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prob-of-having-mtg-on-other-floor">
      <value value="0.1"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-what?">
      <value value="&quot;desk&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="elevator-barrier">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_same_floor_0.2probmtgotherfloor" repetitions="10" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr1</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr2</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
  </experiment>
  <experiment name="experiment_same_floor_0.5probmtgotherfloor_mgrsamefloor" repetitions="12" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr1</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr2</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
  </experiment>
  <experiment name="experiment_same_floor_0.5probmtgotherfloor_mgrsamefloor20runs" repetitions="20" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr1</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr2</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
  </experiment>
  <experiment name="experiment_same_floor_0.3probmtgotherfloor_mgrdiffloor20runs" repetitions="20" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr1</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr2</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
  </experiment>
  <experiment name="experiment_same_floor_0.7probmtgotherfloor_mgrdiffloor20runs" repetitions="20" runMetricsEveryStep="false">
    <setup>setup-office
setup-employees</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>turtle-set [ peopleiveseen ] of mgr1</metric>
    <metric>count [ peopleiveseen ] of mgr1</metric>
    <metric>count mgr1hasntseen</metric>
    <metric>mgr1hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr1</metric>
    <metric>turtle-set [ peopleiveseen ] of mgr2</metric>
    <metric>count [ peopleiveseen ] of mgr2</metric>
    <metric>count mgr2hasntseen</metric>
    <metric>mgr2hasntseen</metric>
    <metric>count [ link-neighbors ] of mgr2</metric>
    <metric>count agents with [ (timewmgr = 0) and (manager? = FALSE ) ]</metric>
    <metric>count agents with [ manager? = FALSE ]</metric>
    <metric>mean [ count peopleiveseen ] of agents with [ manager? = FALSE ]</metric>
    <metric>[path-counter] of elevator</metric>
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
