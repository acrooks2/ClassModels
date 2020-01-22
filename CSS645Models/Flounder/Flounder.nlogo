breed [fish a-fish]
breed [aas aa]
breed [bbs bb]
breed [fish2 a-fish2]
breed [norfish1s norfish1]
breed [norfish2s norfish2]
breed [sofish1s sofish]
breed [sofish2s sofish2]
breed [rays ray]
breed [sharks shark]
breed [ray1s ray1]
breed [shark1s shark1]
breed [ray2s ray2]
breed [shark2s shark2]
breed [prey1s prey1]
breed [prey2s prey2]
breed [prey3s prey3]
breed [prey4s prey4]
fish-own [ideal-temp rep]
turtles-own [energy]
patches-own [pt temp]

to setup
  clear-all
  create-fish 200 [set color violet + 3 setxy -50 0 set size 1]
  create-fish2 200 [set color blue + 3 setxy -50 20 set size 1]

  ask bbs [set color cyan + 2]

  ask turtles [set energy energy + 50000]
  set-default-shape rays "circle"
  set-default-shape prey1s "square"
  set-default-shape sharks "circle"
  set-default-shape prey2s "square"
  set-default-shape prey3s "square"
  set-default-shape prey4s "square"


  set-default-shape ray1s "circle"
  set-default-shape shark1s "circle"
  set-default-shape ray2s "circle"
  set-default-shape shark2s "circle"

  create-rays 2 [set color gray setxy 0 0 set size 1]
  create-prey1s 100 [set color green + 3 setxy -25 0 set size .5]
  create-sharks 2 [set color gray setxy 0 22 set size 1]
  create-prey2s 100 [set color green + 3  setxy -25 22 set size .5]
  create-prey3s 100 [set color green + 3  setxy 0 13 set size .5]
  create-prey4s no_of_inshore_prey [set color green + 3  setxy -50 13 set size .5]
  ask patches [
    set temp (pycor + 34 ) ;;this gives the mid atlantic temp range from 36 to 57 F. The last two highest degrees represent a predicted change in temperature.
    set pcolor (scale-color red temp (Temp_Increase + TempRange - 20) (Temp_Increase + TempRange + 10))]
  reset-ticks
end

to go
  ask fish
  [disperse
    set energy energy - 1
    findtemp eatprey mn1
  ]

  ask aas
  [mn5 set energy energy - 1
    mn7 set energy energy - 1
    eatprey
  ]
  ask bbs
  [mn10 set energy energy - 1
    eatprey
  ]

  ask fish2
  [disperse2
    set energy energy - 1
    normig1
    eatprey
  ]

  ask norfish1s
  [normig4 set energy energy - 1
    normig6 set energy energy - 1
    eatprey
  ]

  ask norfish2s
  [normig10 set energy energy - 1
    eatprey
  ]

  ask sofish1s
  [somig4 set energy energy - 1
    somig6 set energy energy - 1
    eatprey
  ]
  ask sofish2s
  [somig10 set energy energy - 1
    eatprey
  ]
  ask rays
  [movrays set energy energy - .1
    eatfish
  ]
  ask sharks
  [movsharks set energy energy - .1
    eatfish
  ]
  ask ray1s
  [movrays4 set energy energy - .1
    movrays6 set energy energy - .1
    eatfish
  ]
  ask ray2s
  [movrays10 set energy energy - .1
    eatfish
  ]
  ask shark1s
  [movsharks4 set energy energy - .1
    movsharks6 set energy energy - .1
    eatfish
  ]
  ask shark2s
  [movsharks10 set energy energy - .1
    eatfish
  ]
  ask prey1s
  [movprey1
    grow
  ]

  ask prey2s
  [movprey2
    grow
  ]
  ask prey3s
  [movprey3
    grow
  ]
  ask prey4s
  [movprey4
    grow
  ]

  tick
end


to movprey1
  rt random-float 90 - random-float 90
  fd .02
end

to movprey2
  rt random-float 90 - random-float 90
  fd .02
end

to movprey3
  rt random-float 90 - random-float 90
  fd .02
end

to movprey4
  rt random-float 90 - random-float 90
  fd .02
end


to movrays
  face patch -50 2
  rt random 500
  lt random 501
  fd .05
  movrays1
end

to movsharks
  face patch -50 22
  rt random 500
  lt random 501
  fd .05
  movsharks1
end


to disperse
  face patch 0 5
  rt random 500
  lt random 501
  fd .05
  somig1
end

to findtemp
  let cand count neighbors with
  [(Temp_Increase + TempRange) > temp ]
  if cand = Temperature_Sensitivity_Threshold
  [set color violet - 1]
  if color = violet - 1 [mn1]
end

to eatprey
  let alga1
  one-of prey1s-here
  if alga1 != nobody
    [ ask alga1  [ die ]
      set energy energy + 5000 ]
  let alga2
  one-of prey2s-here
  if alga2 != nobody
    [ ask alga2 [ die ]
      set energy energy + 5000 ]
  let alga3
  one-of prey3s-here
  if alga3 != nobody
  [ ask alga3 [ die ]
    set energy energy + 5000 ]

  let alga4
  one-of prey4s-here
  if alga4 != nobody
  [ ask alga4 [ die ]
    set energy energy + 5000 ]
end

to eatfish
  let p1 one-of fish-here
  let p2 one-of aas-here
  let p3 one-of bbs-here
  let p4 one-of sofish1s-here
  let p5 one-of sofish2s-here
  let p6 one-of fish2-here
  let p7 one-of norfish1s-here
  let p8 one-of norfish2s-here


  if p1 != nobody
      [ ask  p1 [ die ]
        set energy energy + 1000
        if energy > 50 [stop]]
  if p2 != nobody
      [ ask p2 [ die ]
        set energy energy + 1000
        if energy > 50 [stop] ]
  if p3 != nobody
      [ ask p3 [ die ]
        set energy energy + 1000
        if energy > 50 [stop]]
  if p4 != nobody
      [ ask p4 [ die ]
        set energy energy + 1000
        if energy > 50 [stop] ]
  if p5 != nobody
      [ ask p5 [ die ]
        set energy energy + 1000
        if energy > 50 [stop]]

  if p6 != nobody
  [ ask p6 [ die ]
    set energy energy + 1000
    if energy > 50 [stop]]

  if p7 != nobody
  [ ask p7 [ die ]
    set energy energy + 1000
    if energy > 50 [stop]]

  if p8 != nobody
  [ ask p8 [ die ]
    set energy energy + 1000
    if energy > 50 [stop]]


end


to grow
  if ticks = 1000 [hatch 5 die]
  if ticks = 3000 [hatch 2 die]
  if ticks = 5000 [hatch 2 die]
  if ticks = 10000 [hatch 2 die]
  if ticks = 20000 [hatch 2 die]
  if ticks = 30000 [hatch 10 die]
  if ticks = 35000 [hatch 5 die]
  if ticks = 40000 [hatch 5 die]
  if ticks = 45000 [hatch 5 die]
  if ticks = 50000 [hatch 5 die]
end



to mn1
  if color = violet - 1
  [face patch 0 20
    rt random 500
    lt random 501
    fd .08]
  mn2
end


to mn2
  let band count turtles-on patch 0 20
  if band > .1 [ask fish-on patch 0 20 [set color lime]]
  mn3
end

to mn3
  if color = lime
  [mn4]
end

to mn4
  hatch-aas 5
  [set color cyan - 3]
  let newf count aas
  if newf > 1 [die]
end


to mn5
  face patch -50 20
  rt random 500
  lt random 501
  fd .1
  mn6
end


to mn6
  ask aas-on patch -50 20
  [set color cyan - 1 mn7]
end

to mn7
  if color = cyan - 1 [
    face patch 0 20
    rt random 500
    lt random 501
    fd .13
  ]
  mn8
end


to mn8
  ask aas-on patch 0 20 [if color = cyan - 1
    [mn9]]
end

to mn9
  hatch-bbs 5
  [set color cyan + 3]
  let newf1 count bbs
  if newf1 > 1 [die]
end

to mn10
  face patch -50 20
  rt random 500
  lt random 501
  fd .15
end



to eatprey7
  let alga7
  one-of prey1s-here
  if alga7 != nobody
  [ ask alga7 [ die ]
    set energy energy + 1000 ]
end

to somig1
  let cofish count turtles-on patch 0 5
  if cofish > .1 [ask fish-on patch 0 5 [set color yellow - 1]]
  somig2
end

to somig2
  if color =  yellow - 1
  [somig3]
end

to somig3
  hatch-sofish1s 5
  [set color yellow]
  let cofish1 count sofish1s
  if cofish1 > 1 [die]
end

to somig4
  face patch -50 2
  rt random 500
  lt random 501
  fd .05
  somig5
end

to somig5
  ask sofish1s-on patch -50 2
  [set color yellow + 1 somig6]
end

to somig6
  if color = yellow + 1 [
    face patch 0 2
    rt random 500
    lt random 501
    fd .08
  ]
  somig8
end

to somig8
  ask sofish1s-on patch 0 2 [if color = yellow + 1
    [somig9]]
end

to somig9
  hatch-sofish2s 20
  [set color yellow + 2]
  let cofish2 count sofish2s
  if cofish2 > 1 [die]
end

to somig10
  face patch -50 2
  rt random 500
  lt random 501
  fd .1
end


to movrays1
  let corays count turtles-on patch -50 2
  if corays > .1 [ask rays-on patch -50 2 [set color gray - 1]]
  movrays2
end

to movrays2
  if color =  gray - 1
  [movrays3]
end

to movrays3
  hatch-ray1s 1
  [set color gray]
  let corays1 count ray1s
  if corays1 > 1 [die]
end

to movrays4
  face patch 0 2
  rt random 500
  lt random 501
  fd .08
  movrays5
end

to movrays5
  ask ray1s-on patch 0 2
  [set color gray + 1 movrays6]
end

to movrays6
  if color = gray + 1 [
    face patch -50 2
    rt random 500
    lt random 501
    fd .1
  ]
  movrays8
end

to movrays8
  ask ray1s-on patch -50 2 [if color = gray + 1
    [movrays9]]
end

to movrays9
  hatch-ray2s 1
  [set color gray + 2]
  let corays2 count ray2s
  if corays2 > 1 [die]
end

to movrays10
  face patch 0 2
  rt random 500
  lt random 501
  fd .13
end


to movsharks1
  let cosharks count turtles-on patch -50 22
  if cosharks > .1 [ask sharks-on patch -50 22 [set color gray - 1]]
  movsharks2
end

to movsharks2
  if color =  gray - 1
  [movsharks3]
end

to movsharks3
  hatch-shark1s 1
  [set color gray - 2]
  let cosharks1 count shark1s
  if cosharks1 > 1 [die]
end

to movsharks4
  face patch 0 22
  rt random 500
  lt random 501
  fd .08
  movsharks5
end

to movsharks5
  ask shark1s-on patch 0 22
  [set color gray + 1 movsharks6]
end

to movsharks6
  if color = gray + 1 [
    face patch -50 22
    rt random 500
    lt random 501
    fd .1
  ]
  movsharks8
end

to movsharks8
  ask shark1s-on patch -50 22 [if color = gray + 1
    [movsharks9]]
end

to movsharks9
  hatch-shark2s 1
  [set color gray + 2]
  let cosharks2 count shark2s
  if cosharks2 > 1 [die]
end

to movsharks10
  face patch 0 22
  rt random 500
  lt random 501
  fd .13
end


to disperse2
  face patch 0 20
  rt random 500
  lt random 501
  fd .05
  normig1
end

to normig1
  if color = blue + 3
  [normig2]
end

to normig2
  let ncofish count fish2-on patch 0 18
  if ncofish > .1 [ask fish2-on patch 0 18 [normig3]]
end

to normig3
  hatch-norfish1s 5
  [set color blue + 1]
  let ncofish1 count norfish1s
  if ncofish1 > 1 [die]
  normig4
end

to normig4
  face patch -50 18
  rt random 500
  lt random 501
  fd .08
  normig5
end

to normig5
  ask norfish1s-on patch -50 18
  [set color blue normig6]
end

to normig6
  if color = blue [
    face patch 0 18
    rt random 500
    lt random 501
    fd .1
  ]
  normig8
end

to normig8
  ask norfish1s-on patch 0 18 [if color = blue
    [normig9]]
end

to normig9
  hatch-norfish2s 20
  [set color blue - 1]
  let ncofish2 count norfish2s
  if ncofish2 > 1 [die]
end

to normig10
  face patch -50 18
  rt random 500
  lt random 501
  fd .13
end
@#$#@#$#@
GRAPHICS-WINDOW
266
60
1217
494
-1
-1
18.5
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
0
0
22
0
0
1
ticks
20.0

BUTTON
836
572
902
605
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
924
573
987
606
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
5
45
213
78
Temp_Increase
Temp_Increase
0
17
13.6
3.4
1
NIL
HORIZONTAL

SLIDER
4
84
249
117
Temperature_Sensitivity_Threshold
Temperature_Sensitivity_Threshold
0
10
8.75
.25
1
NIL
HORIZONTAL

SLIDER
6
121
178
154
TempRange
TempRange
35
56
52.0
1
1
NIL
HORIZONTAL

PLOT
481
522
641
642
Migrating Fish
Time
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Fish" 1.0 0 -2674135 true "" "plot count fish with [color = violet - 1]"

PLOT
2
404
256
529
Predator Energy 1stMig
Time
Energy
-1000.0
3000.0
-1000.0
3000.0
true
false
"" ""
PENS
"South Pred" 1.0 0 -2674135 true "" "ifelse ticks < 22000 [plot mean [energy] of rays] [stop]"
"North Pred" 1.0 0 -14070903 true "" "ifelse ticks < 19000 [plot mean [energy] of sharks] [stop]"

PLOT
0
161
256
281
Fish Energy 1stMig
Time
Energy
-1000.0
3000.0
-1000.0
3000.0
true
false
"" ""
PENS
"South Fish" 1.0 0 -2674135 true "" "ifelse ticks < 38000 [plot mean [energy] of fish] [stop]"
"North Fish" 1.0 0 -13345367 true "" "ifelse ticks < 38000 [plot mean [energy] of fish2] [stop]"

MONITOR
388
595
467
640
South Prey
Count prey1s
17
1
11

MONITOR
386
526
465
571
North Prey
count prey2s
17
1
11

PLOT
1
283
256
403
Fish Energy 2nd Mig
Time
Energy
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Northfish" 1.0 0 -14454117 true "" "if ticks > 60000 [stop]\nif ticks > 23000 [plot mean [energy] of norfish1s]"
"SouthFish" 1.0 0 -2674135 true "" "if ticks > 78000 [stop]\nif ticks > 23000 [plot mean [energy] of sofish1s]"

PLOT
1
529
256
649
Pred Energy 2ndMig
Time
Energy
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"South Pred" 1.0 0 -2674135 true "" "if ticks > 78000 [stop]\nifelse ticks > 25000 [plot mean [energy] of ray1s] [stop]"
"North Pred" 1.0 0 -13345367 true "" "if ticks > 78000 [stop]\nifelse ticks > 23000 [plot mean [energy] of shark1s] [stop]"

PLOT
651
520
823
647
Migrating Fish Energy
Time
Energy
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"2nd mig" 1.0 0 -14462382 true "" "if ticks > 40000 [stop]\nif ticks > 5700 [plot mean [energy] of aas]"
"1st mig" 1.0 0 -11783835 true "" "if ticks > 8500 [stop]\nif ticks > 1800 [plot mean [energy] of fish with [color = violet - 1]]"

SLIDER
833
523
1011
556
no_of_inshore_prey
no_of_inshore_prey
0
100
100.0
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
