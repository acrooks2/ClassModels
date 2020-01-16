;An Agent Based Model using the SEIR to model Opiod Abuse in The United States
;
;


globals [
  ;prob-prescr-opioid
  likelihood-seeking-rehab
  likelihood-sharing-extra
  likelihood-presc-trafficker
  likelihood-presc-pillmill
  opioid-crim
  mj-crim
  pillmill-crim
]


breed [people person]
breed [pillmills pillmill]
breed [traffickers trafficker]
breed [dead-people dead-person]

people-own [
  HRC1-coeff
  HRC2-coeff
  HRC3-coeff
  prob-prescr-opioid
  SEIR-status
  attitude-towards-drugs
  processed?
  weeks ; weeks at current state/ SEIR status
]

patches-own [

]

to setup
  clear-all
  setup-globals
  setup-patches
  setup-agents
  reset-ticks

  type "mean of atd is " print mean [attitude-towards-drugs] of people
  type "mean of probprescropiate is " print mean [prob-prescr-opioid] of people
  type "min of probprescropiate is " print min [prob-prescr-opioid] of people
  type "max of probprescropiate is " print max [prob-prescr-opioid] of people

end

to setup-globals

  ;set prob-prescr-opioid .332
  set likelihood-seeking-rehab .059
  set likelihood-sharing-extra .537
  set likelihood-presc-trafficker .05
  set likelihood-presc-pillmill .02
  set opioid-crim  opioid-criminalization
  set mj-crim marijuana-criminalization
  set pillmill-crim pill-mill-criminalization
end


to go
  if ticks >= 600 [ stop ] ;stop ticks at 200
  ;move
  step
  tick
end



;
;setup the patches
;

to setup-patches
  ask patches [
  set pcolor black
  ]
end


;
;setup the agents with defaults and user input
;

to setup-agents

  let pillmill-pop-size pill-mill-criminalization * 3  ;THIS SHOULD BE SET TO CRIMINaLIZATION LOW M H
  let traffickers-pop-size opioid-criminalization * 3

  ;
  ; Create people
  ;

  create-people population-size [
    set size 5
    set color white
    set shape "person student"
    set heading random 360
    setxy random-pxcor random-pycor
    set attitude-towards-drugs log-normal .15 .5
    set prob-prescr-opioid random-gamma 2 1 ;alpha = mean * mean / variance; lambda = 1 / (variance / mean).)

    setup-SEIR-status ; This handles turtles starting in EIR status

    set-HRC1-coeff
    set-HRC2-coeff
    set-HRC3-coeff


    ;print attitude-towards-drugs ;to check dist of attitudes towards drugs


  ]


  ;
  ; Create the pill mills
  ;
  create-pillmills pillmill-pop-size [

    set size 5
    set color blue + 1
    set shape "person doctor"
    set heading random 360
    setxy random-pxcor random-pycor
  ]


  ;
  ; Create the drug traffickers
  ;
  create-traffickers traffickers-pop-size [
    set size 5
    set color blue + 1
    set shape "person service"
    set heading random 360
    setxy random-pxcor random-pycor
  ]


end

;
; Setup SEIR Status
;


to setup-SEIR-status

  if random 100 <= 45 [ ; 44.5% of susceptibility rate
    set SEIR-status "s"
    set color yellow + 3
    ]

  if SEIR-status = "s" [
    if random 100 <= 82 [ ;82% exposure to opioid drug rate
      set SEIR-status "e"
      set color orange - 1
    ]
  ]

  if SEIR-status = "e" [
    if random 100 <= 13 [ ;13% infection rate (misuse/non-medical use) given exposed
      set SEIR-status "i"
      set color red
     ]
  ]

  if SEIR-status = "i" [ ;
    if random 100 <= 6 [ ;6% recovery rate given infected (received treatment)
      set SEIR-status "r"
      set color lime - 1
     ]
   ]

end


to step

  move
  ;get-prescribed-opiate

 ; print  opioid-crim print prob-prescr-opioid print mj-crim
  ;(( opioid-crim * prob-prescr-opioid)+(mj-crim * atd ))

  pillmill-infect
  trafficker-infect
  remove-susceptibility
  become-susceptible
  become-exposed
  become-infected
  become-recovered
  die-from-overdose
end

to move
  ask people[
    right random 360
    forward 2
    set processed? "no"
    set weeks weeks + 1
    ;type weeks
  ]

    ask traffickers [
    right random 360
    forward 2
  ]
end




to set-HRC1-coeff ; where atd is the attitude-towards-drugs
  set HRC1-coeff (( opioid-crim * prob-prescr-opioid)+(mj-crim * attitude-towards-drugs ))

end

to set-HRC2-coeff  ; where atd is the attitude-towards-drugs
  set HRC2-coeff (opioid-crim * (likelihood-sharing-extra + likelihood-presc-trafficker + likelihood-presc-pillmill))+(mj-crim * (likelihood-sharing-extra + likelihood-presc-trafficker + likelihood-presc-pillmill + attitude-towards-drugs)) +
  (pillmill-crim * (- likelihood-sharing-extra + likelihood-presc-trafficker - likelihood-presc-pillmill))
end

to set-HRC3-coeff
  set HRC3-coeff (( opioid-crim * (- prob-prescr-opioid))+(mj-crim * (- likelihood-seeking-rehab) ))
end



to pillmill-infect ;This procedure simulates someone encoutnering a pillmill when already exposed, and being infected
 ask pillmills [

  let nearby-exposed (people-on neighbors) with [ SEIR-status = "e" ] ;and whatever

    ask nearby-exposed [
      if weeks >= 6 [
        if random 100 < 15 [
           set SEIR-status "i"
           set color red
           set processed? "yes"
        ]
      ]
    ]
 ]
end

to trafficker-infect ;This procedure simulates someone encoutnering a pillmill when already exposed, and being infected
 ask traffickers [

  let nearby-exposed (people-on neighbors) with [ SEIR-status = "e" ] ;and whatever


     ask nearby-exposed [
      if weeks >= 6 [
      if random 100 < 15 [
        set SEIR-status "i"
        set color red
        set processed? "yes"
      ]
      ]
  ]
 ]
end

to remove-susceptibility
   ask people  with [SEIR-status = "s" and processed? = "no" and weeks >= 6 ] [
    if HRC1-coeff < 3 [ ; if susceptible for 6 weeks, remove susceptibility
      set SEIR-status 0
      set color white
      set processed? "yes"
      set weeks 0
    ]
   ]

end



to become-susceptible
  ask people  with [(SEIR-status = 0 or SEIR-status = "r") and processed? = "no"] [
    set-HRC1-coeff
   ; type self type " - "print HRC1-coeff

    if HRC1-coeff > 3 [
      set SEIR-status "s"
      set color yellow + 3
      set processed? "yes"
      set weeks 0
    ]
  ]

   ask people  with [SEIR-status = "e" and processed? = "no" and weeks >= 12] [ ;if the survived 3 attempts at being infected by a pillmill doctor, then they can go back to just being susceptible
     ; if HRC1-coeff < 3 [
       set SEIR-status "s"
       set color yellow + 3
       set processed? "yes"
       set weeks 0
  ; ]
   ]
end

to become-exposed
    ask people  with [SEIR-status = "s" and processed? = "no"] [
    set-HRC1-coeff
    ;type self type " - "print HRC1-coeff
    if HRC1-coeff > 3 [ ;5 is the threshold
       set SEIR-status "e"
       set color orange - 1
       set processed? "yes"
       set weeks 0
      ]


  ]
end

to become-infected
   ask people  with [SEIR-status = "e" and processed? = "no"] [
     set-HRC2-coeff
     ;type "HRC2Coeff of " type self type " - "print HRC2-coeff
    if HRC2-coeff > 3.109 [ ;13% infection rate (misuse/non-medical use) given exposed
      set SEIR-status "i"
      set color red
      set processed? "yes"
      set weeks 0
      ]

    ;allow movement back to

  ]
end

to become-recovered
   ask people  with [SEIR-status = "i"and processed? = "no"] [
   set-HRC3-coeff
   ;type "HRC3Coeff of " type self type " - "print HRC3-coeff
    if HRC3-coeff > -.3 [ ;

      set SEIR-status "r"
      set color lime - 1
      set processed? "yes"
      ]
  ]
end

to die-from-overdose
  ask people with [SEIR-status = "i" and processed? = "no" and weeks >= 100] [
    if random 10000 < 2 [ ;2% death from overdose rate
      set breed dead-people
      set color red
      set size 5
      set shape "ambulance"

      ]
  ]

end


to-report  log-normal [#mu #sigma]
  let beta ln (1 + ((#sigma ^ 2) / (#mu ^ 2)))
  let x exp (random-normal (ln (#mu) - (beta / 2)) sqrt beta)
  report x
end
@#$#@#$#@
GRAPHICS-WINDOW
510
10
1876
755
-1
-1
5.012
1
10
1
1
1
0
0
0
1
-135
135
-73
73
1
1
1
ticks
30.0

BUTTON
25
15
89
48
Setup
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
100
15
163
48
Step
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

BUTTON
172
15
235
48
Go
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
25
65
230
98
opioid-criminalization
opioid-criminalization
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
265
65
465
98
marijuana-criminalization
marijuana-criminalization
1
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
25
110
230
143
pill-mill-criminalization
pill-mill-criminalization
1
5
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
282
17
452
58
3 being high criminilization\nCurrent US conditions are about 3
11
0.0
1

PLOT
10
160
480
345
Distribution of attitudes
age
distribution
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"attitudes" 10.0 1 -5825686 true "set-histogram-num-bars 10" "histogram [attitude-towards-drugs] of people"

PLOT
10
360
480
510
Distrib of probability being prescribed Opioid
NIL
NIL
1.0
15.0
0.0
30.0
true
true
"" ""
PENS
"hrc1-coeff" 1.0 1 -16777216 true "" "histogram [prob-prescr-opioid] of people"

PLOT
15
540
480
690
Distribution of SEIR Statuses
time
count
0.0
200.0
0.0
50.0
true
false
"" ""
PENS
"s" 1.0 0 -526419 true "" "plot count people with [SEIR-status = \"s\"]"
"e" 1.0 0 -3844592 true "" "plot count people with [SEIR-status = \"e\"]"
"i" 1.0 0 -2674135 true "" "plot count people with [SEIR-status = \"i\"]"
"r" 1.0 0 -955883 true "" "plot count people with [SEIR-status = \"r\" ]"
"0" 1.0 0 -1 true "" "plot count people with [SEIR-status = 0]"

MONITOR
85
710
157
755
Susceptible
count people with [SEIR-Status = \"e\"]
17
1
11

MONITOR
170
710
227
755
Exposed
count people with [SEIR-Status = \"e\" ]
17
1
11

MONITOR
315
710
387
755
Recovered
count people with [ SEIR-Status = \"r\" ]
17
1
11

MONITOR
240
710
297
755
Infected
count people with [ SEIR-Status = \"i\" ]
17
1
11

MONITOR
405
710
477
755
Overdoses
count dead-people
17
1
11

MONITOR
15
710
72
755
Total
count people
17
1
11

SLIDER
265
110
465
143
population-size
population-size
1
300
297.0
1
1
people
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model attempts to model the influence of policy on Illict Opiate User

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
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

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

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

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
1
@#$#@#$#@
