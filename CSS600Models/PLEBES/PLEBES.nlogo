breed [voters voter]
breed [candidates candidate]

voters-own [ party voter-position abstain]
candidates-own [ party median-voter-history my-position my-strategy my-strategy-history]
globals [NUM-OF-VOTERS
  blue-win red-win orange-win green-win magenta-win
  party-bias
  current-winner
  median-voter median-red-voter median-blue-voter median-orange-voter median-magenta-voter median-green-voter
  current-winner-position
  tally
  drift-direction
  std-drift-direction
]

to setup
  clear-all
  reset-ticks
  set NUM-OF-VOTERS 711

  setup-candidates
  setup-voters
  set blue-win 0
  set red-win 0
  set party-bias 0
  set tally [0 0 0 0 0]
  set drift-direction 1
end
to setup-candidates
  if candidate-count >= 1 [
    create-candidates 1 [
      set color red
      set size 10
      set xcor random 100
      set ycor 5
      set heading 0
      set shape "face neutral"
      set median-voter-history[]
      set my-strategy-history[]
      set my-strategy candidate-strategy
    ]
  ]
  if candidate-count >= 2 [
    create-candidates 1 [
      set color blue
      set size 10
      set xcor random -100
      set ycor 5
      set shape "face neutral"
      set heading 0
      set median-voter-history[]
      set my-strategy candidate-strategy
      set my-strategy-history[]
    ]
  ]
  if candidate-count >= 3 [

    create-candidates 1 [
      set color orange
      set size 10

      set xcor (random -200) + 100
      while [xcor > max-pxcor or xcor < min-pxcor] [
        set xcor (random -200) + 100
      ]
      set ycor 5
      set shape "face neutral"
      set heading 0
      set median-voter-history[]
      set my-strategy candidate-strategy
      set my-strategy-history[]
    ]
  ]
  if candidate-count >= 4 [

    create-candidates 1 [
      set color green
      set size 10

      set xcor (random -200) + 100
      while [xcor > max-pxcor or xcor < min-pxcor] [
        set xcor (random -200) + 100
      ]
      set ycor 5
      set shape "face neutral"
      set heading 0
      set median-voter-history[]
      set my-strategy candidate-strategy
      set my-strategy-history[]
    ]
  ]
  if candidate-count >= 5 [

    create-candidates 1 [
      set color magenta
      set size 10

      set xcor (random -200) + 100
      while [xcor > max-pxcor or xcor < min-pxcor] [
        set xcor (random -200) + 100
      ]
      set ycor 5
      set shape "face neutral"
      set heading 0
      set median-voter-history[]
      set my-strategy candidate-strategy
      set my-strategy-history[]
    ]
  ]
end
to realign-candidate-position
  let mycolor color
  let median-base-voter 0
  let compromise-voter 0
  let fences-voter 0
  let myposition 0
  let base-strategy-count 0
  let compromise-strategy-count 0
  let overall-strategy-count 0
  let fences-strategy-count 0

  if candidate-strategy != "stand-your-ground" [
    if color = red [set median-base-voter median-red-voter]
    if color = blue [set median-base-voter median-blue-voter]
    if color = orange [set median-base-voter median-orange-voter]
    if color = magenta [set median-base-voter median-magenta-voter]
    if color = green [set median-base-voter median-green-voter]
    ifelse my-position > 0 [
      carefully[set fences-voter median [xcor] of voters with [(color = grey or color = mycolor) and xcor > 0]][]
    ][
      carefully[set fences-voter median [xcor] of voters with [(color = grey or color = mycolor) and xcor < 0]][]
    ]
    set compromise-voter (median-base-voter + median-voter) / 2

    ;get possible positions as proximate voters at each median y-intercept of base vot
    ask patch median-base-voter 0 [set base-strategy-count count voters in-radius max-distance-to-candidate with [color = mycolor]]
    ask patch median-voter 0 [set overall-strategy-count count voters in-radius max-distance-to-candidate]
    ask patch compromise-voter 0 [set compromise-strategy-count count voters in-radius max-distance-to-candidate with [color = grey or color = mycolor]]
    ask patch fences-voter 0 [set fences-strategy-count count voters in-radius max-distance-to-candidate with [color = grey or color = mycolor]]
    ifelse candidate-strategy = "dynamic" [
      ;choose strategy
      if base-strategy-count >= compromise-strategy-count [ set my-strategy "base" ]
      if compromise-strategy-count > base-strategy-count [ set my-strategy "compromise" ]
      if fences-strategy-count > base-strategy-count and fences-strategy-count > compromise-strategy-count [ set my-strategy "fences" ]
    ][
      set my-strategy candidate-strategy
    ]
    ;set position
    if my-strategy = "base" [ set my-position median-base-voter]
    if my-strategy = "compromise" [set my-position compromise-voter]
    if my-strategy = "overall" [ set my-position median-voter]
    if my-strategy = "fences" [ set my-position fences-voter]
    ;store history
    set median-voter-history fput my-position median-voter-history
    set my-strategy-history fput my-strategy my-strategy-history

    ;forget
    if length median-voter-history > candidate-memory [
      set median-voter-history remove-item candidate-memory median-voter-history
    ]
    ;move slowly
    carefully [
      set xcor mean median-voter-history
    ][
      print "oops"
    ]
  ]
end
to setup-voters
  create-voters NUM-OF-VOTERS [
    set party random 2
    set size 2
    set abstain 0
    set voter-position max-pxcor + 1
    set-voter-position
  ]
end
to set-voter-position
  let attempts 0
  let lean random party-lean
  let mode 0
  ifelse voter-position > max-pxcor [ set mode random 2 ][ifelse voter-position > 0 [ set mode 1 ][ set mode 0 ]]
  ifelse lean > 0 [
    set mode 1
    ][ifelse lean < 0 [
      set mode 0
    ][set mode random 2
    ]
  ]
  while [voter-position > max-pxcor or voter-position < min-pxcor or attempts = 0] [
    let alpha 0
    if mode = 1 [set alpha alpha + left-right-bias]
    if mode = 0 [set alpha alpha - left-right-bias]
    set voter-position (random-normal alpha std)
    set attempts attempts + 1
    if attempts > 100 [
      set voter-position 0
    ]
  ]
  set xcor voter-position
  set ycor random 10
  set-voter-allegiance
end
to set-voter-allegiance
;find closest candidate
  let my-candidate nobody
  let my-color color
  let my-choices candidates in-radius (max-distance-to-candidate + random independent-margin)
  ifelse not any? my-choices [
    set abstain 1
    set color grey
  ][
    set my-candidate one-of my-choices
    set abstain 0
    ask my-candidate [set my-color color]
    set color my-color
  ]
end
to kill-all-voters
  ask voters [die]
end
to clear-vote
  ask patches with [pycor > 0][set pcolor black]
end
to vote
  let orange-count 0
  let magenta-count 0
  let red-count 0
  let blue-count 0
  let green-count 0
  set tally [0 0 0 0 0]

  ask voters [
    if color = orange [set orange-count orange-count + 1]
    if color = magenta [set magenta-count magenta-count + 1]
    if color = red [set red-count red-count + 1]
    if color = blue [set blue-count blue-count + 1]
    if color = green [set green-count green-count + 1]
  ]

  set tally replace-item 0 tally orange-count
  set tally replace-item 1 tally magenta-count
  set tally replace-item 2 tally red-count
  set tally replace-item 3 tally blue-count
  set tally replace-item 4 tally green-count

  declare-winner
end
to declare-winner
  let winner-position position max tally tally
  ask candidates [ set shape "face sad"]
  if winner-position = 0 [ set orange-win orange-win + 1 set current-winner "orange"  ask candidates with [color = orange] [set shape "face happy"]]
  if winner-position = 1 [ set magenta-win magenta-win + 1 set current-winner "magenta" ask candidates with [color = magenta] [set shape "face happy"]]
  if winner-position = 2 [ set red-win red-win + 1 set current-winner "red" ask candidates with [color = red] [set shape "face happy"]]
  if winner-position = 3 [ set blue-win blue-win + 1 set current-winner "blue" ask candidates with [color = blue] [set shape "face happy"]]
  if winner-position = 4 [ set green-win green-win + 1 set current-winner "green" ask candidates with [color = green] [set shape "face happy"]]
end
to get-median-voters
  set median-voter median [xcor] of voters
  carefully[set median-red-voter median [xcor] of voters with [color = red]][]
  carefully[set median-blue-voter median [xcor] of voters with [color = blue]][]
  carefully[set median-orange-voter median [xcor] of voters with [color = orange]][]
  carefully[set median-green-voter median [xcor] of voters with [color = green]][]
  carefully[set median-magenta-voter median [xcor] of voters with [color = magenta]][]
end
to draw-medians
  ask patches with [pycor < 0] [ set pcolor black ]
  ask patches with [pycor < 0 and pxcor = int(median-voter)] [ set pcolor white ]
  if any? candidates with [color = red] [ask patches with [pycor < 0 and pxcor = int(median-red-voter)] [ set pcolor red ]]
  if any? candidates with [color = blue] [ask patches with [pycor < 0 and pxcor = int(median-blue-voter)] [ set pcolor blue ]]
  if any? candidates with [color = orange] [ask patches with [pycor < 0 and pxcor = int(median-orange-voter)] [ set pcolor orange ]]
  if any? candidates with [color = magenta] [ask patches with [pycor < 0 and pxcor = int(median-magenta-voter)] [ set pcolor magenta ]]
  if any? candidates with [color = green] [ask patches with [pycor < 0 and pxcor = int(median-green-voter)] [ set pcolor green ]]

  if any? candidates with [color = red] and current-winner = "red" [set current-winner-position mean [xcor] of candidates with [color = red]]
  if any? candidates with [color = blue] and current-winner = "blue" [set current-winner-position mean [xcor] of candidates with [color = blue]]
  if any? candidates with [color = magenta] and current-winner = "magenta" [set current-winner-position mean [xcor] of candidates with [color = magenta]]
  if any? candidates with [color = orange] and current-winner = "orange" [set current-winner-position mean [xcor] of candidates with [color = orange]]
  if any? candidates with [color = green] and current-winner = "green" [set current-winner-position mean [xcor] of candidates with [color = green]]

  ask patches with [pycor < 0 and pxcor = int(current-winner-position)] [ set pcolor yellow ]
end
to drift
  if simulate-extremism-drift [
    if random drift-delay = 1 [
      if left-right-bias >= 100 [ set drift-direction 0]
      if left-right-bias <= 1 [ set drift-direction 1]
      ifelse drift-direction = 1 [
        set left-right-bias left-right-bias + 1
      ][
        set left-right-bias left-right-bias - 1
      ]
    ]
  ]
  if simulate-diffusion [
    if random drift-delay = 1 [
      if std >= 100 [ set std-drift-direction 0]
      if std <= 0 [ set std-drift-direction 1]
      ifelse std-drift-direction = 1 [
        set std std + 1
      ][
        set std std - 1
      ]
    ]
  ]
end
to go
  ;kill-all-voters
  get-median-voters
  draw-medians
  ask voters [ set-voter-position ]
  ask candidates [ realign-candidate-position ]
  clear-vote
  vote
  tick
  drift
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1022
103
-1
-1
4.0
1
10
1
1
1
0
0
0
1
-100
100
-10
10
1
1
1
ticks
30.0

BUTTON
67
42
133
75
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

PLOT
212
382
634
683
voter distribution
NIL
NIL
-100.0
100.0
0.0
50.0
false
false
"" ""
PENS
"default" 1.0 1 -2674135 true "" "histogram [xcor] of voters with [color = red]"
"pen-1" 1.0 1 -13345367 true "" "histogram [xcor] of voters with [color = blue]"
"pen-2" 1.0 1 -7500403 true "" "histogram [xcor] of voters with [color = grey]"
"pen-3" 1.0 1 -1184463 true "" "histogram [xcor] of voters with [color = yellow]"
"pen-4" 1.0 1 -955883 true "" "histogram [xcor] of voters with [color = orange]"
"pen-5" 1.0 1 -5825686 true "" "histogram [xcor] of voters with [color = magenta]"
"pen-6" 1.0 1 -10899396 true "" "histogram [xcor] of voters with [color = green]"

BUTTON
70
97
133
130
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

SLIDER
8
221
201
254
left-right-bias
left-right-bias
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
8
293
202
326
std
std
0
100
20.0
1
1
NIL
HORIZONTAL

BUTTON
72
138
135
171
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
8
330
202
363
independent-margin
independent-margin
0
100
12.0
1
1
NIL
HORIZONTAL

MONITOR
1197
284
1289
329
median-blue
median [xcor] of voters with [color = blue]
2
1
11

MONITOR
1194
237
1289
282
median-red
median [xcor] of voters with [color = red]
2
1
11

MONITOR
1194
189
1288
234
median voter
median [xcor] of voters
2
1
11

PLOT
210
107
628
227
median voter
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
"default" 1.0 0 -16777216 true "" "plot median [xcor] of voters"

PLOT
632
107
1022
227
median candidate
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
"default" 1.0 0 -16777216 true "" "plot median [xcor] of candidates"

CHOOSER
8
404
201
449
candidate-strategy
candidate-strategy
"dynamic" "base" "compromise" "overall" "stand-your-ground"
0

SLIDER
8
451
201
484
candidate-memory
candidate-memory
1
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
1028
190
1092
235
Turnout
count voters with [abstain = 0] / count voters
2
1
11

PLOT
637
382
1021
684
turnout
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -8630108 true "" "plot (count voters with [abstain = 0] / count voters) * 100"

MONITOR
1093
237
1191
282
red strategy
[my-strategy] of candidate 1
17
1
11

MONITOR
1095
284
1192
329
blue strategy
[my-strategy] of candidate 0
17
1
11

PLOT
211
230
1021
380
strategy
NIL
NIL
0.0
2.0
0.0
2.0
true
true
"" ""
PENS
"overall" 1.0 1 -7500403 true "" "plot count candidates with [my-strategy = \"overall\"]"
"compromise" 1.0 1 -13840069 true "" "plot count candidates with [my-strategy = \"compromise\"]"
"base" 1.0 1 -14454117 true "" "plot count candidates with [my-strategy = \"base\"]"
"stand-ground" 1.0 1 -1184463 true "" "plot count candidates with [my-strategy = \"stand-your-ground\"]"
"fences" 1.0 1 -2064490 true "" "plot count candidates with [my-strategy = \"fences\"]"

MONITOR
1027
237
1092
282
NIL
red-win
0
1
11

MONITOR
1027
284
1094
329
NIL
blue-win
0
1
11

PLOT
212
687
1020
837
ruling policy position
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
"red" 1.0 1 -2674135 true "" "ifelse current-winner = \"red\" [plot mean [xcor] of candidates with [color = red]][plot 0]"
"centerline" 1.0 0 -7500403 true "" "plot 0"
"blue" 1.0 1 -13345367 true "" "ifelse current-winner = \"blue\" [plot mean [xcor] of candidates with [color = blue]][plot 0]"
"orange" 1.0 1 -955883 true "" "ifelse current-winner = \"orange\" [plot mean [xcor] of candidates with [color = orange]][plot 0]"
"green" 1.0 1 -13840069 true "" "ifelse current-winner = \"green\" [plot mean [xcor] of candidates with [color = green]][plot 0]"
"magenta" 1.0 1 -5825686 true "" "ifelse current-winner = \"magenta\" [plot mean [xcor] of candidates with [color = magenta]][plot 0]"

SLIDER
8
366
202
399
max-distance-to-candidate
max-distance-to-candidate
0
100
12.0
1
1
NIL
HORIZONTAL

MONITOR
1094
190
1190
235
NIL
current-winner
17
1
11

SLIDER
8
258
201
291
party-lean
party-lean
-10
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
8
186
201
219
candidate-count
candidate-count
2
5
2.0
1
1
NIL
HORIZONTAL

MONITOR
1027
333
1094
378
NIL
orange-win
0
1
11

MONITOR
1027
380
1093
425
NIL
magenta-win
0
1
11

MONITOR
1027
427
1093
472
NIL
green-win
0
1
11

MONITOR
1096
332
1192
377
orange strategy
[my-strategy] of candidate 2
17
1
11

MONITOR
1096
380
1192
425
green strategy
[my-strategy] of candidate 3
17
1
11

MONITOR
1097
427
1192
472
magenta strategy
[my-strategy] of candidate 4
17
1
11

MONITOR
1196
331
1289
376
median-orange
median [xcor] of voters with [color = orange]
2
1
11

MONITOR
1196
379
1289
424
median-green
median [xcor] of voters with [color = green]
2
1
11

MONITOR
1196
426
1290
471
median-magenta
median [xcor] of voters with [color = magenta]
2
1
11

MONITOR
1292
237
1349
282
red %
(count voters with [color = red]) / count voters
2
1
11

MONITOR
1293
283
1350
328
blue %
(count voters with [color = blue]) / count voters
2
1
11

MONITOR
1294
331
1351
376
orange %
(count voters with [color = orange]) / count voters
2
1
11

MONITOR
1295
379
1351
424
green %
(count voters with [color = green]) / count voters
2
1
11

MONITOR
1296
427
1351
472
magenta %
(count voters with [color = magenta]) / count voters
2
1
11

SWITCH
8
487
201
520
simulate-extremism-drift
simulate-extremism-drift
1
1
-1000

SWITCH
8
523
200
556
simulate-diffusion
simulate-diffusion
1
1
-1000

SLIDER
9
560
201
593
drift-delay
drift-delay
0
10
2.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the media-seeking behavior of political candidates in a population of varying distribution across a left-right political axis.

## HOW IT WORKS

The population is represented by a bi-modal normal distribution, with which a number of candidates (default two) must compete for votes by arranging themselves in proximity.

## HOW TO USE IT

Adjust the left-right bias (movement away from center), party lean (global shift of the center) and standard deviation (spread, low for peaked, high for flat) to define the population structure.

## THINGS TO NOTICE

There is no requirement that candidates appear opposite each other. 

When you increase the candidate count, that does not necessarily increase the divesity of winners. It will tend to produce two dominant winners.

## THINGS TO TRY

The "Simulate Exremism Drift" and "Simulate Diffusion" toggles will dynamically adjust the population drift over time. This is helpful in visualizing the interdependency of the parameters over regular intervals.

## EXTENDING THE MODEL

Right now the population is randomized at each tick according to the statiscal defintions of the normal distribution. It would be useful to make this population persistent over time and imbue the voter agents with more autonomy, memory and cognition.

## NETLOGO FEATURES

The complexity of political district structures and voting methods makes it difficult to visualize in a simple x+y+time frame. This model is fairly abstract, but to model a heterogeneous electoral system faithfully is probably not possible within these confines.

## RELATED MODELS

"Voting" is a very simple, very abstract example, similar to the Schelling segregation model.
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
  <experiment name="basic_two_party_baseline" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <metric>red-win</metric>
    <metric>blue-win</metric>
    <metric>(count voters with [color = red]) / count voters</metric>
    <metric>(count voters with [color = blue]) / count voters</metric>
    <enumeratedValueSet variable="std">
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
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="0"/>
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
  </experiment>
  <experiment name="basic_multi_party_baseline" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <metric>red-win</metric>
    <metric>blue-win</metric>
    <metric>orange-win</metric>
    <metric>green-win</metric>
    <metric>magenta-win</metric>
    <metric>(count voters with [color = red]) / count voters</metric>
    <metric>(count voters with [color = blue]) / count voters</metric>
    <metric>(count voters with [color = green]) / count voters</metric>
    <metric>(count voters with [color = magenta]) / count voters</metric>
    <metric>(count voters with [color = orange]) / count voters</metric>
    <enumeratedValueSet variable="std">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="basic_two_candidate_polarity_turnout" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <enumeratedValueSet variable="std">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="0"/>
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
  </experiment>
  <experiment name="basic_two_candidate_polarity_turnout_50pct_distance" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <enumeratedValueSet variable="std">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="1"/>
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
  </experiment>
  <experiment name="basic_two_candidate_polarity_turnout_25pct_distance" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <enumeratedValueSet variable="std">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="1"/>
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
  </experiment>
  <experiment name="basic_two_candidate_polarity_turnout_12pct_distance" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <enumeratedValueSet variable="std">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="1"/>
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
  </experiment>
  <experiment name="basic_multi_party_baseline_20181216_turnoutonly" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 100</exitCondition>
    <metric>count voters with [abstain = 0] / count voters</metric>
    <enumeratedValueSet variable="std">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="party-lean">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="independent-margin">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-count">
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-memory">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-distance-to-candidate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="candidate-strategy">
      <value value="&quot;dynamic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="left-right-bias">
      <value value="0"/>
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
