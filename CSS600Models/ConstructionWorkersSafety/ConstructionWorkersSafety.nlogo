breed[managers manager]
breed[workers worker]


workers-own[
  risk_attitude
  risk_acceptance
  project_identity
  unsafe_behavior
  group_id
  weight_on_social_influence
  workgroup_norm
  management_norm
  perception_coefficient
  perceived_risk
  incident_rate
  old_management_norm
  old_unsafe_behavior
  old_risk_attitude
  old_perception_coefficient
  workers_memory
]

managers-own[
  management_feedback
  managers_risk_acceptance;
  old_management_feedback
  group_id
]


to setup
  clear-all
  reset-ticks

  create-workers 200 [
    set group_id ceiling (who / 10 );200 divided by 10 workers to give 20 GroupIDs
    if who = 0 [set group_id 1]
    set risk_attitude random-float 1 ;;
    set risk_acceptance random-float 1
    set project_identity random-float 1
    set unsafe_behavior random 2
    set workgroup_norm random-float 1
    set management_norm random-float 1
    set perception_coefficient 0.6 + random-float (1.2 - 0.6)
    set weight_on_social_influence random-float 1
    set perceived_risk random-float 1
    set incident_rate random-float 1
  ]

  create-managers 20 [
    set hidden? true
    move-to one-of patches
    set group_id who - 199
    set management_feedback random 2
    set managers_risk_acceptance random-float 1
  ]

  ask workers[
    move-to one-of managers with [group_id = [group_id] of myself] fd 1]

ask workers [set hidden? true]

end

to go

  ask workers;; EFFECT OF INCIDENTS ON RISK ATTITUDE OF WORKERS
  [
    If incident_rate < 0.1 + random-float (0.3 - 0.1);
    [set risk_attitude 0.6 + random-float (0.9 - 0.6)];Worker revises risk attitude to be more risk-seeking due to low rate of incident
    If incident_rate > 0.3 + random-float (0.6 - 0.3)
    [set risk_attitude 0.3 + random-float (0.6 - 0.3)];;Worker revises risk attitude to be more risk-averse after an accident

    If incident_rate > 0.7 + random-float (1.0 - 0.7)
    [set risk_attitude 0.1 + random-float (0.3 - 0.1)];Worker revises risk attitude to be more risk-averse after an accident

;;  INCIDENT RATES IN VARIOUS SITE RISK CONDITONS
    if unsafe_behavior = 1 and site_risk < 0.1 + random-float (0.3 - 0.1)
    [set incident_rate 0 + random-float (0.3 - 0.1) ];; Low probability of incident in low site risk

    if unsafe_behavior = 1 and site_risk > 0.3 + random-float (0.6 - 0.3)
    [set incident_rate 0.3 + random-float (0.6 - 0.3)];; medium probability of incident in medium site risk

    if unsafe_behavior = 1 and site_risk > 0.7 + random-float (1.0 - 0.7)
    [set incident_rate 0.7 + random-float (1.0 - 0.7)];; high probability of incident in high site risk

  ]

  ; EFFECT OF MANAGEMENT FEEDBACK ON SAFE BEHAVIOR.

  ask workers
  [
    if random-float perceived_risk > random-float risk_acceptance [set unsafe_behavior 0 set incident_rate 0 + random-float (0.3 - 0)]
    if random-float perceived_risk < random-float risk_acceptance [set unsafe_behavior 1 set incident_rate 0.6 + random-float (1.0 - 0.6)]

  ]


  ask workers;; EQUATION OF WORKER'S RISK PERCEPTION
  [
    set old_risk_attitude risk_attitude
    set old_perception_coefficient perception_coefficient ; EQUATION 1
    set perception_coefficient old_perception_coefficient - (risk_attitude - old_risk_attitude);Risk perception co-efficient is a ratio of perceived risk to actual risk
    set perceived_risk perception_coefficient * site_risk; EQUATION 2

    ;; EQUATION OF WORKER'S RISK ACCEPTANCE
    set risk_acceptance ((1 - weight_on_social_influence) * risk_attitude) +
      (weight_on_social_influence * (project_identity * management_norm) + ((1 - project_identity) * workgroup_norm));;EQUATION 3-Worker's risk acceptance is a function of risk attitude,management norm, workgroup norm and project identity.

  ;; EQUATION OF WORKGROUP NORM
    let old_workgroup_norm workgroup_norm
   let k count workers with [unsafe_behavior = 1]
  let sumPRA sum [risk_acceptance] of workers
    set workgroup_norm ((1 - 1 / 15) * old_workgroup_norm + 1 / 15 * (1 / (k + 1)) * sumPRA);; EQUATION 4: Workgroup norm is the sum of previous workgroup norm and the current perception of the average of coworkers' risk acceptance

    set old_management_norm management_norm
    set management_norm ((1 - 1 / 15) * old_management_norm + 1 / 15 * mean [managers_risk_acceptance] of managers);;EQUATION 6: Management norm is the sum of previous management norm and the current perception of managers' risk acceptance

  ]

ask workers
[

; EFFECT OF MANAGEMENT FEEDBACK ON SAFE BEHAVIOR.

    set old_unsafe_behavior unsafe_behavior
   if old_unsafe_behavior = 0 and ([management_feedback] of managers = 1)
      [set unsafe_behavior 0 set incident_rate 0.1 + random-float (0.2 - 0.1)]; Worker performs safe behavior when given a feedback with minimum incident rate

    if old_unsafe_behavior = 1 and ([management_feedback] of managers) = 0
    [set unsafe_behavior 1 set incident_rate 0.3 + random-float (0.6 - 0.3)]; Worker performs unsafely without feedback which increases incident rate

    if old_unsafe_behavior = 1 and ([management_feedback] of managers) = 1
    [set unsafe_behavior 0 set incident_rate 0.1 + random-float (0.2 - 0.1)]; Worker performs safe behavior when given a feedback


    ;STICTNESS OF FEEDBACK
     if old_unsafe_behavior = 1 and strict_feedback < 0.1 + random-float (0.3 - 0.1)
      [set unsafe_behavior 1 set incident_rate 0.5 + random-float (0.8 - 0.5)]; Worker performs unsafe behavior with minimum strictness and maximum incident rate

   if old_unsafe_behavior = 1 and strict_feedback > 0.3 + random-float (0.6 - 0.3)
      [set unsafe_behavior 0 set incident_rate 0.3 + random-float (0.6 - 0.3)]; Worker performs safe behavior with medium strictness and medium incident rate

     if old_unsafe_behavior = 1 and strict_feedback > 0.6 + random-float (1.0 - 0.6)
      [set unsafe_behavior 0 set incident_rate 0.1 + random-float (0.2 - 0.1)]; Worker performs safely with maximum strictness and minimum incident rate



    ;FREQUENCY OF FEEDBACK
     if old_unsafe_behavior = 1 and frequent_feedback < 0.1 + random-float (0.3 - 0.1)
      [set unsafe_behavior 1 set incident_rate 0.5 + random-float (0.8 - 0.5)]; Worker performs unsafe behavior with minimum feedback frequency and maximum incident rate

   if old_unsafe_behavior = 1 and frequent_feedback > 0.4 + random-float (0.6 - 0.4)
      [set unsafe_behavior 0 set incident_rate 0.3 + random-float (0.5 - 0.3)]; Worker performs safe behavior with medium  feedback frequency and medium incident rate

     if old_unsafe_behavior = 1 and frequent_feedback > 0.7 + random-float (1.0 - 0.7)
      [set unsafe_behavior 0 set incident_rate 0 + random-float (0.2 - 0.1)]; Worker performs safely with maximum  feedback frequency and minimum incident rate

]

tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
6
37
83
70
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
89
36
152
69
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

PLOT
430
10
647
199
WN, RA  and MN
time
mean
0.0
100.0
0.0
1.0
true
true
"" ""
PENS
"MN" 1.0 0 -13840069 true "plot mean [workgroup_norm] of workers" "plot mean [management_norm] of workers"
"RA" 1.0 0 -7500403 true "" "plot mean [risk_acceptance] of workers"
"WN" 1.0 0 -2674135 true "" "plot mean [workgroup_norm] of workers"

SLIDER
5
87
177
120
site_risk
site_risk
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
5
133
177
166
strict_feedback
strict_feedback
0
1.0
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
5
179
177
212
frequent_feedback
frequent_feedback
0
1
0.5
0.1
1
NIL
HORIZONTAL

MONITOR
4
228
115
273
Mean incident_rate
mean[ incident_rate ] of workers
2
1
11

MONITOR
125
228
182
273
UB
count workers with [unsafe_behavior = 1]
0
1
11

PLOT
646
10
953
201
RA and R.ACC
time
mean
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Risk Attitude" 1.0 0 -955883 true "" "plot mean [risk_attitude] of workers"
"Risk Acceptance" 1.0 0 -5298144 true "" "plot mean [risk_acceptance] of workers"

PLOT
429
198
648
379
MN and RA
time
mean
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"MN" 1.0 0 -11221820 true "" "plot mean [management_norm] of workers"
"RA" 1.0 0 -5298144 true "" "plot mean [risk_attitude] of workers"

PLOT
646
198
953
379
SR and IR
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"SR" 1.0 0 -13840069 true "" "plot mean [site_risk] of workers"
"IR" 1.0 0 -2674135 true "" "plot mean [incident_rate] of workers"

PLOT
210
198
430
379
SF and IR in HRS
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"SF" 1.0 0 -9276814 true "" "plot mean [strict_feedback] of workers"
"IR" 1.0 0 -5298144 true "" "plot mean [incident_rate] of workers"

PLOT
210
10
432
199
RA and IR in MRS
time
mean
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"RA" 1.0 0 -14070903 true "" "plot mean [risk_attitude] of workers"
"IR" 1.0 0 -5298144 true "" "plot mean [incident_rate] of workers"

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
