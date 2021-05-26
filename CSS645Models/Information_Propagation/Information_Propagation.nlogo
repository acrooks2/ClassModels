;;Simulate information propragation in physical and cyber spaces
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals
[
  clique
  previous-clique
  percent-clique
  clique-now
  percent-clique-now
  percent-red
  percent-blue
  total-people
  count-red-fol
  count-blue-fol
  count-violet-fol
  median-gov-p
]

breed [governors governor]
breed [citizens citizen]
breed [followers follower]

turtles-own
[
  party
  count-down    ;; a count down clock to decide the time a turtle should hear the msg: when count-down = -1.
  times-heard    ;; tracks times the msg has been heard
  p ; probability of spreading the msg
  new-p ; adjusted by mutural conditions between two contacting turtles
]

governors-own
[
  gov-year ; 48 dispersed patches holding each governor's incumbent year [2007,2015] -- imported from text file
  gov-vote ; 48 dispersed patches holding each governor's vote share -- imported from text file
  gov-twyear
  gov-fol ; 48 dispersed patches holding each governor's followers' count -- imported from text file
  physical-world-influence
  cyber-world-influence
]

patches-own [
  layer-sid
  layer-spop
  layer-sdens
  layer-sparty
  layer-svote
  layer-govid
  layer-govparty
  layer-govyear
  layer-govvote
  layer-govtwyear
  layer-govfol
  ]

to setup
  clear-all
  setup-USstates
  setup-governors
  ifelse cyber?
  [setup-citizens setup-followers] [setup-citizens]
  set clique 0
  reset-ticks
end

to setup-USstates
  file-open "Data/stateid.txt" let patch-sid file-read file-close
  (foreach sort patches patch-sid
     [ [?1 ?2] -> ask ?1 [ set layer-sid ?2 ] ] )  ;store stateid in layer-sid
  ask patches
    [set pcolor layer-sid]

  file-open "Data/statedensity.txt" let patch-sdens file-read file-close
  (foreach sort patches patch-sdens
     [ [?1 ?2] -> ask ?1 [ set layer-sdens ?2 ] ] ) ;store statedens in layer-sdens

  file-open "Data/govid.txt" let patch-gid file-read file-close
  (foreach sort patches patch-gid
     [ [?1 ?2] -> ask ?1 [ set layer-govid ?2 ] ] )

  file-open "Data/govparty.txt" let patch-gp file-read file-close
  (foreach sort patches patch-gp
     [ [?1 ?2] -> ask ?1 [ set layer-govparty ?2 ] ] )

  file-open "Data/govyear.txt" let patch-gyr file-read file-close
  (foreach sort patches patch-gyr
     [ [?1 ?2] -> ask ?1 [ set layer-govyear ?2 ] ] )

  file-open "Data/govvote.txt" let patch-gvote file-read file-close
  (foreach sort patches patch-gvote
     [ [?1 ?2] -> ask ?1 [ set layer-govvote ?2 ] ] )

  file-open "Data/govtwyear.txt" let patch-gty file-read file-close
  (foreach sort patches patch-gty
     [ [?1 ?2] -> ask ?1 [ set layer-govtwyear ?2 ] ] )

  file-open "Data/govfol.txt" let patch-gf file-read file-close
  (foreach sort patches patch-gf
     [ [?1 ?2] -> ask ?1 [ set layer-govfol ?2 ] ] )

  file-open "Data/sparty.txt" let patch-sparty file-read file-close
  (foreach sort patches patch-sparty
     [ [?1 ?2] -> ask ?1 [ set layer-sparty ?2 ] ] )

  file-open "Data/svote.txt" let patch-sv file-read file-close
  (foreach sort patches patch-sv
     [ [?1 ?2] -> ask ?1 [ set layer-svote ?2 ] ] )
end

to setup-governors
clear-turtles
ask patches with [layer-govid >= 0][
sprout-governors 1
[set shape "person" set size 8
  set party layer-govparty
  ifelse party = 1 [set color red] [set color blue]
  set gov-year layer-govyear
  set gov-vote layer-govvote
  ;let max-year max-one-of patches [ layer-govyear ] ;this returns the patch index. e.g., (patch 112,-45)
  let max-govyear max [layer-govyear] of patches
  let min-govyear min [layer-govyear] of patches with [layer-govyear >= 0]
  let max-govvote max [layer-govvote] of patches
  let min-govvote min [layer-govvote] of patches with [layer-govvote >= 0]
  set physical-world-influence ((gov-year - min-govyear + 1) / (max-govyear - min-govyear + 1)) * ((gov-vote - min-govvote + 1) / (max-govvote - min-govvote + 1))

  set gov-twyear layer-govtwyear
  set gov-fol layer-govfol
  let max-govtwyear max [layer-govtwyear] of patches
  let min-govtwyear min [layer-govtwyear] of patches with [layer-govtwyear >= 0]
  let max-govfol max [layer-govfol] of patches
  let min-govfol min [layer-govfol] of patches with [layer-govfol >= 0]
  set cyber-world-influence ((gov-twyear - min-govtwyear + 1) / (max-govtwyear - min-govtwyear + 1)) * ((gov-fol - min-govfol + 1) / (max-govfol - min-govfol + 1))

  let origin-count-red-fol sum [layer-govfol] of patches with [layer-sparty = 1 and layer-govid >= 0] ;1633668
  let origin-count-blue-fol sum [layer-govfol] of patches with [layer-sparty = 2 and layer-govid >= 0] ;1515354
  set count-red-fol round(origin-count-red-fol * 0.92 / 1000) ;1503
  set count-blue-fol round(origin-count-blue-fol * 0.92 / 1000) ;1394
  set count-violet-fol round((origin-count-red-fol + origin-count-blue-fol) / 1000) - count-red-fol - count-blue-fol  ; 252

  set count-down 0
  set times-heard 0
  ifelse cyber?
  [set p physical-world-influence + cyber-world-influence] [set p physical-world-influence]
  ]
]
;show [p] of governors
;set median-gov-p median [p] of governors
;show median-gov-p
end

to setup-citizens
 ; clear-turtles
  ask patches with [layer-sid >= 0][
;    ifelse citizen-prop-to-pop?
;    sprout-citizens ceiling(layer-sdens / 1000)   ;initialize citizens # according to population density -->[1,10], or 1 per patch.
    sprout-citizens 1
;    ask citizens
    [set shape "circle"
      let vote layer-svote
      let s precision (random-float 100) 1  ; a random number between 0 and 100 with 1 decimal digit
      ifelse s < vote
      [set party layer-sparty][
      ifelse s < 92
      [set party 3 - layer-sparty][set party 3]]
      set p precision (random-float 0.6505) 4

      set count-down -10 ; so if this citizen is not reached, his count-down will keep decreasing
      set times-heard 0
      set color gray
    ]
  ]
      ;show count citizens  ; 85614
      ;show count patches with [layer-sid >= 0] ; 85614
  end

to setup-followers
  ;clear-turtles
  ask n-of count-red-fol patches with [layer-sid >= 0][
    sprout-followers 1
    [set-fol
      set party 1
      set color red]]
  ask n-of count-blue-fol patches with [layer-sid >= 0][
    sprout-followers 1
    [set-fol
      set party 2
      set color blue]]
  ask n-of count-violet-fol patches with [layer-sid >= 0][
    sprout-followers 1
    [set-fol
      set party 3
      set color one-of [ red blue]]]
  ;show count followers  ; 3149
  end

  to set-fol
        set shape "triangle" set size 2
        set p precision (random-float 0.6505) 4
        set count-down random 24
        set times-heard 0
  end

to go
  if all? turtles [times-heard > 0]
  [stop]
  if ticks = 72
  [stop]
  tick
  ask turtles
  [set count-down count-down - 1
  if count-down = -1
  [spread-msg]]

  if decay?  ; set a random percent of knowing-sth. turtles change back to oblivion (gray - 1) when their times-heard >= a setting value
  [ask n-of (percent-decay * count turtles with [color = red or color = blue]) turtles with [color = red or color = blue or color = violet]
   [ if times-heard >= decay-after-times-heard
     [set color gray - 1]]]

  ask turtles with [color = red or color = blue or color = gray - 1] ; ask all turtles that have ever heard of the msg, times-heard + 1
  [set times-heard times-heard + 1]

;  let x count turtles with [color = red or color = blue or color = gray - 1] ;; just for test
;  show x
;
;  print max [times-heard] of turtles ;;  at tick 72: latest first heard = max times heard = 72
;  print min [times-heard] of turtles  ;;  min times heard = 0 always

  if noise?  ;; randomly change a percent of citizens who are oblivious of the msg to red/blue, and also to a msg source
  [ask n-of (percent-noise * count turtles with [color = gray or color = gray - 1]) turtles with [color = gray or color = gray - 1]
    [set color one-of [red blue]
      set count-down 0]
    ]

  set previous-clique clique
  set clique count turtles with [times-heard > 0]
  set clique-now count turtles with [color = red or color = blue]
  set percent-clique clique / count turtles
  set percent-clique-now clique-now / count turtles
  set percent-red count turtles with [color = red] / count turtles
  set percent-blue count turtles with [color = blue] / count turtles
  set total-people count turtles
end

to spread-msg
  let targets nobody
  ifelse count turtles-on neighbors > 1
  [set targets n-of 2 turtles-on neighbors][set targets turtles-on neighbors]
  ask targets [
  ifelse party = [party] of myself [set new-p p + 0.11]                 ; cyber? doesn't influence the values setting if only two decimal digits are considered
  [ifelse party = 3 [set new-p p - 0.09] [set new-p p - 0.20]]
  if new-p > median-gov-p  and times-heard <= chances-to-change-mind
  [set color [color] of myself
  set count-down 0]
  ]
end

to recolor-by-first-heard
  ask patches
  [set pcolor black]
  ask turtles
  [set color black
   set shape "circle" set size 1
   let f ticks - times-heard
      set color scale-color orange f ticks 0]
  ask governors
  [set shape "person" set size 3]
  if cyber?
  [ask followers
    [set shape "triangle" set size 2]]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1104
394
-1
-1
1.5
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
590
-249
0
0
0
1
ticks
30.0

BUTTON
65
10
131
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
39
124
142
157
cyber?
cyber?
0
1
-1000

BUTTON
112
48
175
81
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

MONITOR
847
478
904
523
clique
clique
0
1
11

PLOT
6
420
289
585
population_1
time
population
0.0
72.0
0.0
65000.0
true
true
"" ""
PENS
"blue" 1.0 0 -13345367 true "" "plot count turtles with [color = blue]"
"red" 1.0 0 -2674135 true "" "plot count turtles with [color = red]"
"total" 1.0 0 -9276814 true "" "plot count turtles with [color = blue or color = red]"

BUTTON
14
49
77
82
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
847
532
951
577
percent-clique
percent-clique
4
1
11

MONITOR
969
419
1057
464
percent-red
percent-red
4
1
11

MONITOR
968
468
1062
513
percent-blue
percent-blue
4
1
11

MONITOR
843
424
932
469
total-people
total-people
0
1
11

SLIDER
5
86
191
119
chances-to-change-mind
chances-to-change-mind
0
5
2.0
1
1
NIL
HORIZONTAL

PLOT
598
420
830
582
Successive Differences
time
difference
0.0
72.0
0.0
3500.0
true
false
"set-plot-y-range 0 precision (count patches / 100) -2" ""
PENS
"default" 1.0 0 -5825686 true "" "plot clique - previous-clique"

BUTTON
31
371
182
404
recolor-by-first-heard
recolor-by-first-heard
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
296
421
590
583
population_1
time
Count
0.0
72.0
0.0
65000.0
true
true
"" ""
PENS
"clique" 1.0 0 -955883 true "" "plot clique"
"clique-now" 1.0 0 -8630108 true "" "plot clique-now"

SLIDER
11
235
183
268
percent-decay
percent-decay
0
0.1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
10
199
189
232
decay-after-times-heard
decay-after-times-heard
0
72
36.0
12
1
NIL
HORIZONTAL

SWITCH
38
164
141
197
decay?
decay?
0
1
-1000

MONITOR
969
517
1041
562
clique-now
clique-now
0
1
11

MONITOR
970
566
1089
611
percent-clique-now
percent-clique-now
4
1
11

SLIDER
10
309
182
342
percent-noise
percent-noise
0
0.10
0.05
0.01
1
NIL
HORIZONTAL

SWITCH
40
275
143
308
noise?
noise?
1
1
-1000

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
