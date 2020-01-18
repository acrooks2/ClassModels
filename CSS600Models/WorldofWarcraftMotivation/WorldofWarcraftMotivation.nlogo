turtles-own [
;Psychological attributes:
  mA          ;Motivation for achievement
  mS          ;Motivation for sociability

  social-need ;Expected interaction
  achiev-need ;Expected challenge

  interest    ;Experienced interest for the game
  tolerance   ;Tolerance to frustration

  ret-mem     ;Memory given to retribution
  soc-mem     ;Memory given to socialization

  time        ;Time available to play

;Game-related attributes:
  ingame      ;0=potential player, 1=currently playing, 2=stopped playing
  month-entry
  week        ;week of the monthly subscription they are currently on (1-4)
  level       ;in-game character level, allows to evaluate time needed to get achievments and sociability
  retribution
  interaction

  decision    ;Evaluation for staying next month: 0=leave, 1=stay
  initial-cost;Cost of entry,

  ]

globals [
  temp befriend ;Used as temporal variable
  year-entry
  ]



to setup
  clear-all
  reset-ticks

  set year-entry []

;WoW Vanilla Settings. Challenge: Effort requiered to be overcomed by Time (assuming RPGame requires time investment but not high skills). Sociability: Level of Interaction provided by Game Mechanics.
  set Challenge 25
  set Sociability 75

  crt players [
    setxy random 100 random 100
    set shape "circle"     set color red      set size 1


;Gamer Atributes:

;Threshold to become interested in playing. Decision to play is also influenced by amount of friends playing.
    set initial-cost (random-normal Initial 500)

    ;Motivation Overall or Interest.
    ;Interest in general, Tolerance in general. If interest becomes lower than tolerated then user decides to quit the game.
    set interest (random-normal 5 1)
    if interest < 0 [ set interest 1]
    set tolerance (interest / 2)

;Casual relationships and Friends needed to fulfill socialization needs:
    set social-need ((random-normal 3 1))

    set time (random-normal 22 3)
    if time < 0 [set time 1]
    if time > 70 [set time 70]

;Motivation Thresholds> Gives relevance to: Achievment and Social.
    update-motivation

;Game Related Conditions
    set decision 0
    set ingame 0
    set week 0
    set level 0
    set retribution 1
    set interaction 1
    set ret-mem [0 0 0]
    set soc-mem [0 0 0]
    set month-entry 1000
;Get some friends in real-world:
    if RL-Friends > random players [create-link-with one-of turtles with [self != myself] ask my-links [set color red]]
  ]

  ;Visual layout arrangement.
  repeat 10 [layout-spring (turtles with [any? link-neighbors]) links 0.1 0.1 0.5]

end

to update-motivation
  ;Normal distributed motivation
  set mA random-normal mA-mean 2.5
  set mS random-normal mS-mean 2.5
end




; The Simulation Process: The simulation runs for 9 years, each Tick is a week. Every certain periods the Game changes its Settings (Challenge and Sociability) [to extension].
;                         Players decide to enter the game or not [to enter-game]. If they are in the game they play, during gameplay players may form casual relationships or
;                         friendships. The evaluation of staying in the game goes through Retribution in Achievement (time vs Challenge) or Interaction in Socialization
;                         (Friends vs Desired-Minimum-Socialization (soc-need). Players compare their actual experience with the last week, if they feel they interact or achieve
;                         more they get interested in playing more. Decision about which element to consider is prioritized by mA and mS in a Fast and Frugal decision tree.


to go
  ifelse Predict? [if ticks > 700 [ record-year-entry stop]][if ticks > 470 [ record-year-entry stop ]]
  expansion
  enter-game
  play-game
  assess-next-month
  lose-connection
  layout
  plotitout
  leave-game
  tick
end

;Game Settings of Different Game Phases or Expansions
to expansion
   ;If Forecasting allows to
   if Predict? and ticks = 476 [print "Warlords of Draenor" set Challenge Test-C set Sociability Test-S]

   ifelse ticks = 376 [print "Pandaria" set Challenge (Challenge - 5)]                                                                    ;
  [ifelse ticks = 292 [print "Cataclysm" set Challenge (Challenge - 5) set Sociability (Sociability - 10)]  ;Game easier for lvl 1-80, "Raid finder", Battleground finder.
  [ifelse ticks = 192 [print "Lich King" set Challenge (Challenge - 5) set Sociability (Sociability - 10)]  ;Game easier for lvl 1-70, "Dungeon Finder" (social short-cut).
  [if ticks = 104 [print "Burning Crusade" set Challenge (Challenge)]]]]                                ;Game made easier for levels 1-60, Dungeons more accessible to players.
end


to play-game
  ask turtles [
    ;Visual display of status.
    ifelse ingame = 1 [set color green][set color red]

    ;Active-players actions:
    if ingame = 1 [

    ;Asuming a certain time and a difficult threshold does not represent END-GAME + DECICATED PLAYERS which may be a significant part of the game adaptive system.

    ;While playing players deal with progress and its difficulty (if the time required is too high or too low they lose interest).
    ifelse time > Challenge [ifelse time > (Challenge * 2) [set retribution (retribution - 1)]    ;Too high.
                                                           [set retribution (retribution + 1)]]   ;Acceptable challenge according to time available.
                                                           [set retribution (retribution - 1)]    ;Too low.

    ;While playing they also interact and form friendships.
    ifelse Sociability > random 100 [ friend ][ unfriend ]

    ;Amount of relationships (casual and friends) affect interaction levels.
    ifelse (count link-neighbors with [ingame = 1]) > social-need [set interaction (interaction + 1)][set interaction (interaction - 1)]

    ;Update Memory
    set ret-mem fput retribution ret-mem
    set soc-mem fput interaction soc-mem

    ;Time passes for players.
    set week (week + 1)
    if week > 4 [set week 1]

    ;Forget last item of memory
    set ret-mem butlast ret-mem
    set soc-mem butlast soc-mem
    ]
  ]
end


to assess-next-month
  ;Every 4 weeks players evaluate if they want to play another month. The process is made by a Fast and Frugal decision tree arranged by priority of Motivation (mA or mS)
  ask turtles [
    if ingame = 1 and week = 4[
      ifelse interest < tolerance [set decision 0][set decision 1]
      if mA > mS [
        ifelse  (first ret-mem < item 1 ret-mem) [set interest (interest - 0.1)] [ifelse (first soc-mem < item 1 soc-mem) [set interest (interest + 0.05)][set interest (interest - 0.1)]]]   ;MUY SIMILAR HAY QUE CAMBIAR
      if mS > mA [
        ifelse  (first soc-mem < item 1 soc-mem) [set interest (interest - 0.1)] [ifelse (first ret-mem < item 1 ret-mem) [set interest (interest + 0.05)][set interest (interest - 0.1)]]]
        ]
    ]
end


to enter-game
  ;For those out of the game (ingame = 0 or 2)
  ask turtles [
    ;Never played the game:
    if ingame = 0 [ifelse count link-neighbors with [color = red] > ((social-need) / 2) [set ingame 1 set color green set decision 1 set month-entry ticks]  ;Enters by Friend Rec.
                                [if 1 > random 200 [if initial-cost < (count turtles with [ingame = 1]) [set ingame 1 set decision 1 set month-entry ticks]]]]   ;Enters by Community Rec.
    ;Already played:
    if ingame = 2 [ifelse mA > mS [if 1 > random 1000 [set ingame 1 set color green set decision 1 set interest (tolerance + 1)]]
                                  [if count link-neighbors with [color = green] > social-need [set ingame 1 set color green set decision 1 if interest < tolerance [set interest (tolerance + 1)]]]]
  ]
end

to leave-game ;get leave rate, timing
  ask turtles [
    if decision = 0 and ingame = 1 [set ingame 2 set color red]                                 ;if the interest comes lower to the tolerance level he leaves
  ]
end

;Friend - Unfriend
to friend
  repeat Friend-factor [
  set temp (random players)
  ask turtle (temp) [if ingame = 1 [set befriend 1]]
  ;Take a random turtle. If it is inside the game allow to make friends with the other turtle (befriend = 1).
  ;If already has a casual relationship it has a probability to establish a friendship with the linked turtle.
  ifelse link-neighbor? turtle (temp) [if random 10 < 1 [if (count my-links with [color = green]) > 0 [ask one-of my-links with [color = green] [set color blue]]]]
  ;If they are not connected then they generate a casual relationship.
  [if temp != who and befriend = 1[create-link-with turtle (temp) ]
  ask my-links with [other-end = turtle (temp)] [set color green]
  set befriend 0]]
end

to unfriend
  ;Loses casual relationships.
  if count my-links with [color = green] > 0 [
  ask my-links with [color = green] [die]
  ]
end

to lose-connection
  ;When turtle leaves the game has a probability to lose friends.
  ask turtles [
    if ingame = 2 [
      if 1 > random 10 [if (count my-links with [color = green]) > 0 [ask one-of my-links with [color = green][die]]]
      ]
    if 1 > random 10000 [if count my-links with [color = blue] > 0 [ask one-of my-links with [color = blue][die]]] ;Is real to consider but strong frienships are considered permanent in the model
  ]
end

to layout
  layout-spring (turtles with [any? link-neighbors]) links 0.1 0.1 3   ;Spreads nodes to show a clear view of the network (not really)
end

to plotitout
  set-current-plot "Active-Players"
  set-current-plot-pen "Players"
  plot count turtles with [ingame = 1]
  set-current-plot-pen "pen-1"
  plot 0
;Marks to show Expansion Releases:
  if ticks = 104 [plot 200]
  if ticks = 192 [plot 200]
  if ticks = 292 [plot 200]
  if ticks = 376 [plot 200]
  if ticks = 476 [plot 200]

  set-current-plot "Friends"
  set-current-plot-pen "Real life"
  plot count links with [color = red]
  set-current-plot-pen "Mates"
  plot count links with [color = green]
  set-current-plot-pen "Friends"
  plot count links with [color = blue]
  set-current-plot "Motivation Activity"
  set-current-plot-pen "Achievement"
  plot count turtles with [mA > mS and ingame = 1]
  set-current-plot-pen "Social"
  plot count turtles with [mS > mA and ingame = 1]
  set-current-plot "First Play Distribution"
  set-current-plot-pen "Frequency"
  set-plot-pen-mode 1
  plot-pen-reset
  set-plot-pen-color blue
  plot count turtles with [month-entry < 8]
  plot (count turtles with [month-entry < 112]) - (count turtles with [month-entry < 60])
  plot (count turtles with [month-entry < 164]) - (count turtles with [month-entry < 112])
  plot (count turtles with [month-entry < 216]) - (count turtles with [month-entry < 164])
  plot (count turtles with [month-entry < 268]) - (count turtles with [month-entry < 216])
  plot (count turtles with [month-entry < 320]) - (count turtles with [month-entry < 268])
  plot (count turtles with [month-entry < 372]) - (count turtles with [month-entry < 320])
  plot (count turtles with [month-entry < 424]) - (count turtles with [month-entry < 372])

end

to record-year-entry
  set year-entry lput (count turtles with [month-entry < 8]) year-entry
  set year-entry lput ((count turtles with [month-entry < 112]) - (count turtles with [month-entry < 60])) year-entry
  set year-entry lput ((count turtles with [month-entry < 164]) - (count turtles with [month-entry < 112])) year-entry
  set year-entry lput ((count turtles with [month-entry < 216]) - (count turtles with [month-entry < 164])) year-entry
  set year-entry lput ((count turtles with [month-entry < 268]) - (count turtles with [month-entry < 216])) year-entry
  set year-entry lput ((count turtles with [month-entry < 320]) - (count turtles with [month-entry < 268])) year-entry
  set year-entry lput ((count turtles with [month-entry < 372]) - (count turtles with [month-entry < 320])) year-entry
  set year-entry lput ((count turtles with [month-entry < 424]) - (count turtles with [month-entry < 372])) year-entry
  print year-entry
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
723
424
-1
-1
5.0
1
10
1
1
1
0
1
1
1
0
100
0
80
0
0
1
ticks
30.0

BUTTON
12
12
76
45
NIL
Setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
78
12
141
45
NIL
Go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

PLOT
749
169
949
319
Friends
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
"Real life" 1.0 0 -2674135 true "" "plot count links with [color = red]"
"Mates" 1.0 0 -13840069 true "" "plot count links with [color = green]"
"Friends" 1.0 0 -13345367 true "" "plot count links with [color = blue]"

PLOT
956
10
1156
160
Active-Players
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
"Players" 1.0 0 -16777216 true "" ""
"pen-1" 1.0 0 -2674135 true "" ""

MONITOR
1158
10
1262
55
Average Friends
(count links with [color = green]) / count turtles with [ingame = 1]
17
1
11

SLIDER
12
56
184
89
mA-mean
mA-mean
0
10
7.5
0.5
1
NIL
HORIZONTAL

SLIDER
12
95
184
128
mS-mean
mS-mean
0
10
7.0
0.5
1
NIL
HORIZONTAL

PLOT
956
169
1156
319
Motivation Activity
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
"Achievement" 1.0 0 -10899396 true "" ""
"Social" 1.0 0 -13345367 true "" ""

BUTTON
143
12
206
45
Step
Go
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
11
370
183
403
Challenge
Challenge
0
70
25.0
1
1
NIL
HORIZONTAL

SLIDER
11
409
183
442
Sociability
Sociability
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
12
132
184
165
RL-Friends
RL-Friends
0
1000
30.0
5
1
NIL
HORIZONTAL

PLOT
749
11
949
161
First Play Distribution
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
"Frequency" 1.0 1 -13345367 true "" ""

SLIDER
12
169
184
202
Initial
Initial
0
1500
150.0
10
1
NIL
HORIZONTAL

SLIDER
13
293
185
326
Friend-factor
Friend-factor
0
20
5.0
1
1
NIL
HORIZONTAL

SWITCH
747
388
850
421
Predict?
Predict?
1
1
-1000

SLIDER
861
377
1033
410
Test-C
Test-C
0
100
25.0
5
1
NIL
HORIZONTAL

SLIDER
861
413
1033
446
Test-S
Test-S
0
100
95.0
5
1
NIL
HORIZONTAL

INPUTBOX
55
217
122
277
players
1000.0
1
0
Number

@#$#@#$#@
## WHAT IS IT?

This model attempts to 

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
  <experiment name="Normal 100 sin Expand" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Normal 100 con Expand" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <metric>count turtles with [mA &gt; mS and ingame = 1]</metric>
    <metric>count turtles with [mS &gt; mA and ingame = 1]</metric>
    <metric>count links with [color = green]</metric>
    <metric>count links with [color = blue]</metric>
    <metric>count links with [color = red]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="mS 0, 10, 0.5" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="2.5"/>
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
      <value value="5"/>
      <value value="5.5"/>
      <value value="6"/>
      <value value="6.5"/>
      <value value="7"/>
      <value value="7.5"/>
      <value value="8"/>
      <value value="8.5"/>
      <value value="9"/>
      <value value="9.5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="mA 0, 10, 0.5" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="2.5"/>
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
      <value value="5"/>
      <value value="5.5"/>
      <value value="6"/>
      <value value="6.5"/>
      <value value="7"/>
      <value value="7.5"/>
      <value value="8"/>
      <value value="8.5"/>
      <value value="9"/>
      <value value="9.5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="chal over soc" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="soc over chal" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Size Without Expand" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
      <value value="1000"/>
      <value value="1250"/>
      <value value="1500"/>
      <value value="1750"/>
      <value value="2000"/>
      <value value="2250"/>
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Friending Factor WO Exps" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
      <value value="7"/>
      <value value="9"/>
      <value value="11"/>
      <value value="13"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="RLF wo Exps" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="1"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="450"/>
      <value value="500"/>
      <value value="600"/>
      <value value="700"/>
      <value value="800"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="InitCost wo Exps" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="450"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="mS 0, 10, 0.5 con Exp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="2.5"/>
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
      <value value="5"/>
      <value value="5.5"/>
      <value value="6"/>
      <value value="6.5"/>
      <value value="7"/>
      <value value="7.5"/>
      <value value="8"/>
      <value value="8.5"/>
      <value value="9"/>
      <value value="9.5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="mA 0, 10, 0.5 con Exp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
      <value value="2"/>
      <value value="2.5"/>
      <value value="3"/>
      <value value="3.5"/>
      <value value="4"/>
      <value value="4.5"/>
      <value value="5"/>
      <value value="5.5"/>
      <value value="6"/>
      <value value="6.5"/>
      <value value="7"/>
      <value value="7.5"/>
      <value value="8"/>
      <value value="8.5"/>
      <value value="9"/>
      <value value="9.5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="chal over soc con Exp" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="soc over chal con Exps" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Size With Expand" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="250"/>
      <value value="500"/>
      <value value="750"/>
      <value value="1000"/>
      <value value="1250"/>
      <value value="1500"/>
      <value value="1750"/>
      <value value="2000"/>
      <value value="2250"/>
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Friending Factor with Exps" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
      <value value="7"/>
      <value value="9"/>
      <value value="11"/>
      <value value="13"/>
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="RLF with Exp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="1"/>
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="450"/>
      <value value="500"/>
      <value value="600"/>
      <value value="700"/>
      <value value="800"/>
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="InitCost with Exp" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="50"/>
      <value value="100"/>
      <value value="150"/>
      <value value="200"/>
      <value value="250"/>
      <value value="300"/>
      <value value="450"/>
      <value value="500"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="TEST" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [ingame = 1 and ms &gt; mA]</metric>
    <metric>count turtles with [ingame = 1 and mS &lt; mA]</metric>
    <metric>count turtles with [ingame = 1]</metric>
    <enumeratedValueSet variable="mA-mean">
      <value value="7.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Predict?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Initial">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="RL-Friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-S">
      <value value="95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Challenge">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mS-mean">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Friend-factor">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Sociability">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Test-C">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="players">
      <value value="1000"/>
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
