globals [
  available-colors ;; used for coloring, purely aesthetic
  stable? ;; used for reporting: has the model reached a steady state?
  percent-happy ;; reporting variable
  min-state-ideology
  max-state-ideology
  mean-state-ideology
  sd-state-ideology
  min-town-ideology
  max-town-ideology
  mean-town-ideology
  sd-town-ideology
]

breed [towns town]
breed [households household]
breed [cbds cbd]
breed [states state]

towns-own [
  my-color ;; aesthetic
  town-policies ;; binary string representing issues
  location  ;; distance from cbd, if cbd? = true
  referendum ;; vote on a given issue
  my-state ;; which state a town belongs to
  desirability ;; area
]

households-own [
  my-issues ;; binary string representing issue positions
  happy? ;; is the household in a community with acceptable polities?
]
states-own [
  state-policies ;; same as town-policies
  referendum ;; vote on a given issue
  quadrant
]

;;;;;;;;;;;;;;;;;;;;;
;; SETUP FUNCTIONS ;;
;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  reset-ticks
  
  ; set various globals
  set stable? false
  set-default-shape households "x"
  set-default-shape towns "circle 2"
  set-default-shape cbds "box"
  set-default-shape states "flag"

  
  ; central business district initializes first to have who id 0
  if cbd? [
    create-cbds 1 [ 
      setxy (max-pxcor / 2) (max-pycor / 2) 
      set color gray]]
  
  ; error checking
  if num-issues mod 2 = 1 [ error "num-issues must be even"] 
  
  ; generate the agents
  if scenario = "default" [ generate-towns ]
  if scenario = "16" [ generate-16-towns ]
  if scenario = "64" [ generate-64-towns ]
  setup-households  
  if states? [
    spawn-states
  ]
  
  if color-boundaries? [ color-towns ]
  update-desirability 
  
  ; execute "tick 0"
  ask households [evaluate]
  update-stats
end

to spawn-states 
  let x ceiling (max-pxcor * .75) 
  let y floor (max-pycor * .25)
  ask patch x x [ sprout-states 1 [ set quadrant 1 ] ]
  ask patch x y [ sprout-states 1 [ set quadrant 2 ] ]
  ask patch y x [ sprout-states 1 [ set quadrant 3 ] ]
  ask patch y y [ sprout-states 1 [ set quadrant 4 ] ]  
  ask states [ set color black 
    set state-policies []
    repeat num-issues / 2 [set state-policies fput (random 2) state-policies ]    
  ]
  ask towns [
    set my-state min-one-of states [ distance myself ] 
  ]
end

to color-towns
  ;this code is basically unreadable
  ;what it does is this: if states?, color patches quadrant by quadrant. patches only consider the location of towns in the same quadrant as themselves
  ;if not states?, color as a regular Voronoi tesselation
  ifelse states?[
    ask patches with [ pxcor >= (max-pxcor / 2) and pycor >= (max-pycor / 2) ] [ set pcolor [ color ] of min-one-of towns with [ my-state = one-of states with [ quadrant = 1 ]] [ distance myself ]]
    ask patches with [ pxcor >= (max-pxcor / 2) and pycor < (max-pycor / 2) ] [ set pcolor [ color ] of min-one-of towns with [ my-state = one-of states with [ quadrant = 2 ]] [ distance myself ]]
    ask patches with [ pxcor < (max-pxcor / 2) and pycor >= (max-pycor / 2) ] [ set pcolor [ color ] of min-one-of towns with [ my-state = one-of states with [ quadrant = 3 ]] [ distance myself ]]
    ask patches with [ pxcor < (max-pxcor / 2) and pycor < (max-pycor / 2) ] [ set pcolor [ color ] of min-one-of towns with [ my-state = one-of states with [ quadrant = 4 ]] [ distance myself ]]
  ]
  [ ask patches [
    set pcolor [ color ] of min-one-of towns [ distance myself ]]]
end


to generate-towns 
  ;; Generate towns as Voronoi tesellations. Much of this code is adapted from Wilensky (2006).
  ask towns [
    set color [ 255 255 255 0 ]
    set location 0 ]
  set available-colors shuffle filter [(? mod 10 >= 2) and (? mod 10 <= 8)] n-values 140 [?]
  ;  if num-households > count patches
  ;    [ user-message (word "This area only has room for " count patches " towns.")
  ;      stop ]
  
  ;; create towns  
  ask n-of num-communities patches [
    sprout-towns 1 [
      if line? [setxy 0 who - 1]
      set size 1
      set color first available-colors
      set available-colors butfirst available-colors
      set my-color color
      if cbd?
        [ set location ((distance cbd 0) / 44) ]
      set-town-policies
    ]
  ]
  ask patches [ set pcolor white ]

end

to generate-64-towns
set num-communities 64
  ask towns [
    set color [ 255 255 255 0 ]
    set location 0 ]
  set available-colors shuffle filter [(? mod 10 >= 2) and (? mod 10 <= 8)] n-values 140 [?]
  
  let one (max-pxcor * (1 / 16))
  let two (max-pxcor * (3 / 16))
  let three (max-pxcor * (5 / 16)) 
  let four (max-pxcor * (7 / 16))
  let five (max-pxcor * (9 / 16))
  let six (max-pxcor * (11 / 16))
  let seven (max-pxcor * (13 / 16))
  let eight (max-pxcor * (15 / 16))
  
;  let one 7.5
;  let two 22.5
;  let three 37.5
;  let four 52.5
  
  let x 0 
  repeat 64 [
    ask n-of 1 patches [ 
      sprout-towns 1 [
        ; ugly location code
        if floor (x / 8) = 0 [ set xcor one ]
        if floor (x / 8) = 1 [ set xcor two ]
        if floor (x / 8) = 2 [ set xcor three ]
        if floor (x / 8) = 3 [ set xcor four ]
        if floor (x / 8) = 4 [ set xcor five ]
        if floor (x / 8) = 5 [ set xcor six ]
        if floor (x / 8) = 6 [ set xcor seven ]
        if floor (x / 8) = 7 [ set xcor eight ]
        
        
        if x mod 8 = 0 [ set ycor one ]
        if x mod 8 = 1 [ set ycor two ]
        if x mod 8 = 2 [ set ycor three ]
        if x mod 8 = 3 [ set ycor four ]
        if x mod 8 = 4 [ set ycor five ]
        if x mod 8 = 5 [ set ycor six ]
        if x mod 8 = 6 [ set ycor seven ]
        if x mod 8 = 7 [ set ycor eight ]        

        set size 1
        set color first available-colors
        set available-colors butfirst available-colors
        set my-color color
        if cbd?
        [ set location ((distance cbd 0) / 35) ] ;TODO: normalize distance
        set-town-policies
      ]
    ]
    set x x + 1
  ]
  ask patches [ set pcolor white ]
end
to generate-16-towns
set num-communities 16
  ask towns [
    set color [ 255 255 255 0 ]
    set location 0 ]
  set available-colors shuffle filter [(? mod 10 >= 2) and (? mod 10 <= 8)] n-values 140 [?]
  
  let one ceiling (max-pxcor * .125)
  let two floor (max-pxcor * .375)
  let three ceiling (max-pxcor * .625)
  let four floor (max-pxcor * .875)
  
;  let one 7.5
;  let two 22.5
;  let three 37.5
;  let four 52.5
  
  let x 0 
  repeat 16 [
    ask n-of 1 patches [ 
      sprout-towns 1 [
        ; ugly location code
        if floor (x / 4) = 0 [ set xcor one ]
        if floor (x / 4) = 1 [ set xcor two ]
        if floor (x / 4) = 2 [ set xcor three ]
        if floor (x / 4) = 3 [ set xcor four ]
        
        if x mod 4 = 0 [ set ycor one ]
        if x mod 4 = 1 [ set ycor two ]
        if x mod 4 = 2 [ set ycor three ]
        if x mod 4 = 3 [ set ycor four ]
        
        set size 1
        set color first available-colors
        set available-colors butfirst available-colors
        set my-color color
        if cbd?
        [ set location ((distance cbd 0) / 44.55) ] ;TODO: normalize distance
        set-town-policies
      ]
    ]
    set x x + 1
  ]
  ask patches [ set pcolor white ]
end

to set-town-policies
  ;if cbd? is true, town policies are biased by distance from cbd. Directly on cbd = [ 1 1 1 ... 1 1]
  let x 0
  ifelse states? 
  [set x num-issues / 2 ]
  [set x num-issues ] 
  
  ifelse cbd?
  [
    set town-policies []
    repeat x [
      ifelse random-float 1 > location 
      [ set town-policies fput 1 town-policies ]
      [ set town-policies fput 0 town-policies ]
    ]
  ]
  [
    set town-policies []
    repeat x [set town-policies fput (random 2) town-policies ]    
  ]
end

to setup-households
  create-households num-households
  ask households [
    set color gray 
    set happy? false]
  
  ;; create random binary list of issue positions for each household, e.g. [0 1 1 0 1],
  ;; and position them randomly
  ask households [
    setxy random-pxcor random-pycor
    set my-issues []
    repeat num-issues [set my-issues fput (random 2) my-issues ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;
;; RUNTIME FUNCTIONS ;;
;;;;;;;;;;;;;;;;;;;;;;;
to go
  tick
  
  if ticks >= max-length [
    stop ]
  
  if all? households [happy?] [
    set stable? true
    stop ]
  
  move-unhappy
  if ticks mod town-election-cycle = 0 [ hold-referenda-town ]
  if states? and ticks mod state-election-cycle = 0 [ hold-referenda-state ]
  ask households [ evaluate ]
  update-stats
end

to step
  go
end

to evaluate 
  let my-pcolor [pcolor] of self
  let similarity 0
  let local-policies []
  
  ifelse states?  
    ;;true
    [ ask min-one-of states [ distance myself ] [
      foreach state-policies [
        set local-policies lput ? local-policies]]
;    ask min-one-of towns [ distance myself] [
;      foreach town-policies 
;      [ set local-policies lput ? local-policies]] ]
    ask min-one-of towns [ distance myself] [
      foreach reverse town-policies 
      [ set local-policies fput ? local-policies]] ]
    ;;false
    [ ask min-one-of towns [distance myself] [
      foreach town-policies 
      [ set local-policies lput ? local-policies]]]
  
  
  
  ;   show my-issues
  ;   show local-policies
  (foreach my-issues local-policies  [
    if ?1 = ?2 [
      set similarity (similarity + 1)]])
  
  ;  show similarity
  ; < should be the correct comparison, you want, e.g. 6/12 to evaluate to true
  ifelse similarity < (num-issues * (intensity / 100)) 
    [ set happy? false ]
    [ set happy? true ]
  
  ; handle equality case randomly to avoid bias on even values of intensity
  if similarity = (num-issues * (intensity / 100)) [
    ifelse random 2 = 1 
    [ set happy? true ]
    [ set happy? false ]]
  
end

to hold-referenda-state
  ask states [ set referendum [] ]
  ask households [ 
    let vote my-issues
    repeat num-issues / 2 [ set vote butlast vote ] 
;    show vote ; debug
    ask min-one-of states [distance myself] 
      [ set referendum lput vote referendum ]]
  
  ask states [
    ;    show state-policies
    let issue 0
    let new-policies []
    repeat num-issues / 2 [
      let votes []
      foreach referendum 
        [ set votes fput item issue ? votes ]
      let winner median votes
      ifelse winner = 1 or winner = 0
      [ set new-policies lput winner new-policies ]
      [ set new-policies lput item issue state-policies new-policies ]
      
      set issue issue + 1 ]
    ;   show new-policies
    set state-policies new-policies ]
end


to hold-referenda-town
  ;show ticks
  
  ;; x is a variable representing either the set of all issues or half that;
  ;; used to avoid excessive conditionals around the state? variable
  let x 0
  ifelse states?
  [ set x num-issues / 2 ]
  [ set x num-issues ]
  
  
  ask towns [ set referendum [] ]
  ask households [ 
    let vote my-issues
    repeat num-issues - x [ set vote butfirst vote ] 
    ;    show vote ; debug
    ask min-one-of towns [distance myself] 
      [ set referendum lput vote referendum ]]
  
  
  
  
  ask towns [
    ;     show town-policies
    let near-me my-color
    if count households with [ pcolor = near-me ] > 0 [
      let issue 0
      let new-policies []
      repeat x [
        let votes []
        foreach referendum 
          [ set votes fput item issue ? votes ]
        if not empty? votes [ let winner median votes  
        ifelse winner = 1 or winner = 0
        [ set new-policies lput winner new-policies ]
        [ set new-policies lput item issue town-policies new-policies ]
        set issue issue + 1 ]]
      ;       show new-policies
      set town-policies new-policies ]]
end

to move-unhappy
  ask households with [happy? = false] 
   [ setxy random-pxcor random-pycor ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; VISUALIZATION & DEBUGGING ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to shade-houses
  ask households [
    set color gray
    let x reduce + my-issues
    if x / num-issues < 0.4 
      [set color white ]
    if x / num-issues > 0.6
      [set color black ]] 
end

to update-desirability 
  ask towns 
  [ let col my-color
    set desirability count patches with [ pcolor = col ]]
end

to update-stats
  set percent-happy 100 * (count households with [happy? = true]) / (count households)
  
  let town-ideologies []
  let state-ideologies []
  if states? [ ask states [ set state-ideologies lput summarize-ideology state-policies state-ideologies ] ]
  ask towns [ set town-ideologies lput summarize-ideology town-policies town-ideologies ]
  
  if states? [
    set min-state-ideology min state-ideologies
    set max-state-ideology max state-ideologies
    set mean-state-ideology mean state-ideologies
    set sd-town-ideology standard-deviation town-ideologies
  ]
  
  set min-town-ideology min town-ideologies
  set max-town-ideology max town-ideologies
  set mean-town-ideology mean town-ideologies
  set sd-town-ideology standard-deviation town-ideologies
end

to-report summarize-ideology [policies]
  report (reduce + policies) / length policies
end
@#$#@#$#@
GRAPHICS-WINDOW
503
19
1025
562
-1
-1
8.0
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
63
0
63
0
0
1
ticks
30.0

BUTTON
9
37
75
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
138
37
201
70
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

BUTTON
75
37
138
70
step
step
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
34
104
206
137
num-communities
num-communities
10
80
64
1
1
NIL
HORIZONTAL

SLIDER
34
137
206
170
num-households
num-households
1000
5000
2000
50
1
NIL
HORIZONTAL

SLIDER
34
170
206
203
num-issues
num-issues
2
100
50
2
1
NIL
HORIZONTAL

MONITOR
202
26
307
71
percent-happy
percent-happy
1
1
11

SLIDER
34
203
206
236
max-length
max-length
200
2000
500
100
1
NIL
HORIZONTAL

SLIDER
34
236
206
269
intensity
intensity
1
100
50
1
1
NIL
HORIZONTAL

MONITOR
307
26
364
71
NIL
stable?
17
1
11

SWITCH
388
55
491
88
cbd?
cbd?
1
1
-1000

SWITCH
388
120
491
153
line?
line?
1
1
-1000

SWITCH
388
87
491
120
states?
states?
0
1
-1000

SLIDER
207
104
384
137
state-election-cycle
state-election-cycle
0
50
20
1
1
NIL
HORIZONTAL

SLIDER
207
137
384
170
town-election-cycle
town-election-cycle
0
50
20
1
1
NIL
HORIZONTAL

PLOT
290
186
490
336
town ideologies
ideology
count
0.0
1.0
0.0
15.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [summarize-ideology town-policies] of towns"

PLOT
290
336
490
486
state ideologies
ideology
count
0.0
1.0
0.0
5.0
false
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram [summarize-ideology state-policies] of states"

SWITCH
387
153
491
186
color-boundaries?
color-boundaries?
0
1
-1000

MONITOR
10
342
80
387
town-min
min-town-ideology
2
1
11

MONITOR
79
342
148
387
town-max
max-town-ideology
2
1
11

MONITOR
10
298
80
343
state-min
min-state-ideology
2
1
11

MONITOR
79
298
148
343
state-max
max-state-ideology
2
1
11

TEXTBOX
118
281
188
299
Ideologies\n
13
0.0
1

MONITOR
147
342
216
387
town-mean
mean-town-ideology
2
1
11

MONITOR
147
298
216
343
state-mean
mean-state-ideology
2
1
11

CHOOSER
388
10
491
55
scenario
scenario
"default" "16" "64"
2

MONITOR
215
298
280
343
state-sd
sd-state-ideology
17
1
11

MONITOR
215
342
280
387
town-sd
sd-town-ideology
2
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
NetLogo 5.1.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="early sweep" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>min-state-ideology</metric>
    <metric>mean-state-ideology</metric>
    <metric>max-state-ideology</metric>
    <metric>sd-state-ideology</metric>
    <metric>min-town-ideology</metric>
    <metric>mean-town-ideology</metric>
    <metric>max-town-ideology</metric>
    <metric>sd-town-ideology</metric>
    <enumeratedValueSet variable="num-issues">
      <value value="10"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-households" first="1000" step="100" last="2000"/>
    <enumeratedValueSet variable="intensity">
      <value value="45"/>
      <value value="50"/>
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="state-election-cycle">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-election-cycle">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="test-setup" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>step</go>
    <timeLimit steps="1"/>
    <metric>percent-happy</metric>
    <enumeratedValueSet variable="max-length">
      <value value="500"/>
    </enumeratedValueSet>
    <steppedValueSet variable="intensity" first="45" step="1" last="55"/>
    <steppedValueSet variable="num-communities" first="5" step="5" last="30"/>
    <steppedValueSet variable="num-households" first="500" step="100" last="1000"/>
    <steppedValueSet variable="num-issues" first="10" step="20" last="90"/>
  </experiment>
  <experiment name="testsetup2" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>step</go>
    <timeLimit steps="1"/>
    <metric>percent-happy</metric>
    <enumeratedValueSet variable="max-length">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intensity">
      <value value="49"/>
      <value value="50"/>
      <value value="51"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-communities">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-issues">
      <value value="9"/>
      <value value="10"/>
      <value value="11"/>
      <value value="89"/>
      <value value="90"/>
      <value value="91"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="sample runs" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <final>if count households with [happy?] = num-households [set stable? true]</final>
    <metric>percent-happy</metric>
    <metric>min-state-ideology</metric>
    <metric>max-state-ideology</metric>
    <metric>mean-state-ideology</metric>
    <metric>min-town-ideology</metric>
    <metric>max-town-ideology</metric>
    <metric>mean-state-ideology</metric>
    <metric>stable?</metric>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;64&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cbd?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-households">
      <value value="2000"/>
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intensity">
      <value value="30"/>
      <value value="5"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-election-cycle">
      <value value="5"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="state-election-cycle">
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="states?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-issues">
      <value value="10"/>
      <value value="10"/>
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="intensity" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>min-state-ideology</metric>
    <metric>mean-state-ideology</metric>
    <metric>max-state-ideology</metric>
    <metric>sd-state-ideology</metric>
    <metric>min-town-ideology</metric>
    <metric>mean-town-ideology</metric>
    <metric>max-town-ideology</metric>
    <metric>sd-town-ideology</metric>
    <enumeratedValueSet variable="num-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="state-election-cycle">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intensity">
      <value value="41"/>
      <value value="42"/>
      <value value="43"/>
      <value value="44"/>
      <value value="46"/>
      <value value="47"/>
      <value value="48"/>
      <value value="49"/>
      <value value="51"/>
      <value value="52"/>
      <value value="53"/>
      <value value="54"/>
      <value value="56"/>
      <value value="57"/>
      <value value="58"/>
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-issues">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-election-cycle">
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="early dynamics" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>min-state-ideology</metric>
    <metric>mean-state-ideology</metric>
    <metric>max-state-ideology</metric>
    <metric>sd-state-ideology</metric>
    <metric>min-town-ideology</metric>
    <metric>mean-town-ideology</metric>
    <metric>max-town-ideology</metric>
    <metric>sd-town-ideology</metric>
    <enumeratedValueSet variable="num-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="states?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-length">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="state-election-cycle">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="line?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intensity">
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-issues">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-election-cycle">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-communities">
      <value value="64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;64&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="color-boundaries?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cbd?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="irregular" repetitions="30" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>min-state-ideology</metric>
    <metric>mean-state-ideology</metric>
    <metric>max-state-ideology</metric>
    <metric>sd-state-ideology</metric>
    <metric>min-town-ideology</metric>
    <metric>mean-town-ideology</metric>
    <metric>max-town-ideology</metric>
    <metric>sd-town-ideology</metric>
    <metric>percent-happy</metric>
    <enumeratedValueSet variable="max-length">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-issues">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="states?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="town-election-cycle">
      <value value="5"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cbd?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-households">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="scenario">
      <value value="&quot;default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intensity">
      <value value="40"/>
      <value value="45"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="state-election-cycle">
      <value value="5"/>
      <value value="20"/>
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
