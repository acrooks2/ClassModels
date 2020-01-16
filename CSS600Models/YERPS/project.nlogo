; ABM Interactional Theory
; Youth and Environment Risk and Protective Scores (YERP)
;
;


globals [
  home-patches         ;; agentset of blue patches representing the home areas
  school-patches       ;; agentset of brown patches representing the school areas
  neighborhood-patches ;; agentset of green patches representing the neighborhood areas
]

turtles-own [
  individual-risk           ;; an individual's probability of engaging in antisocial behavior
  individual-pro            ;; an individual's probability of engaging in a prosocial behavior
  prosocial                 ;; an individual's tally of total prosocial experiences
  antisocial                ;; an individual's tally of total antisocial experiences

  family-risk               ;; an individual family's risk probability
  family-pro                ;; an individual family's protective probability
]

patches-own [
  pro-opp      ;; each patch has a prosocial opportunity score
  risk-opp     ;; each patch has a risk opportunity score
]

to setup
  clear-all
  resize-world -16 16 -20 20

  ;; create the home patches
  set home-patches patches with [pycor < -15]
  ask home-patches [
    set pcolor blue
    set pro-opp 1       ;; family risk sits with the youth, as their "home" and "family" aren't location specific
    set risk-opp 1    ;; family risk sits with the youth, as their "home" and "family" aren't location specific
  ]

  ;; create the school patches
  set school-patches patches with [pycor > 15]
  ask school-patches [
    set pcolor brown

    ;; Risk and protective opportunities that randomly fall along the exponential distribution
    ;; centered on user-controlled mean,
    ;; but bounded between .01 and .99 so this variable can operate as a probability

    set risk-opp random-exponential-in-bounds  (schools-risk / 100) .01 .99
    set pro-opp random-exponential-in-bounds (schools-protective / 100) .01 .99
  ]

  ;; create the neighborhood patches
  set neighborhood-patches patches with [ (pycor < 16) and (pycor > -16)]
  ask neighborhood-patches [
    set pcolor green

    ;; Risk and protective opportunities that randomly fall along the exponential distribution
    ;; centered on user-controlled mean,
    ;; but bounded between .01 and .99 so this variable can operate as a probability

    set risk-opp random-exponential-in-bounds (community-risk / 100) .01 .99
    set pro-opp random-exponential-in-bounds (community-protective / 100) .01 .99
  ]

  ;; create the youths
  let NUM-TURTLES 150
  create-turtles NUM-TURTLES [
    set color gray
    set size 1.0
    set shape "person"
    set heading 0

    ;; The family and risk protective factors randomly fall along the exponential distribution
    ;; centered on user-controlled mean,
    ;; but bounded between .01 and .99 so this variable can operate as a probability.

    set family-risk random-exponential-in-bounds (risk-level / 100) .01 .99
    set family-pro random-exponential-in-bounds (protective-level / 100) .01 .99

    ;; Individual risk and protective factor is based on the family's risk and protective
    ;; factor, since there will be varying influence of family on youth.
    ;; Youth score is centered on family's score and is drawn randomly from the
    ;; normal distribution, but bounded between .01 and .99 so this variable
    ;; can perate as a probability. Standard deviation is arbitrarily set at .02.

    set individual-risk random-normal-in-bounds family-risk .02 .01 .99
    set individual-pro random-normal-in-bounds family-pro .02 .01 .99

    ;; the model starts with the youth as a blank slate, so 0 values for prosocial and antisocial.

    set prosocial 0
    set antisocial 0

    setxy random-pxcor random-pycor

    ;; start all the youth at home
    move-to one-of home-patches
  ]
  reset-ticks

end

to go

  ;; Each tick represents a day. This is the only way for the model to stop,
  ;; depending on the number of days you want this to run.

  let MAX-TICKS 1800
  repeat MAX-TICKS [
    step
  ]
end

;; To move through a day, youth go to school, there's an after school period,
;; then youth are at home in the evenings. Then the ticks steps forward.

to step
  turtles-go-to-school
  turtles-after-school
  turtles-evenings
  tick
end



to turtles-go-to-school
  ask turtles [move-to one-of school-patches]

  ;; Set school day to 6 hours, (e.g., 7am-2pm).
  ;; At each hour, if the youth is in school, the youth will make a decision about whether to leave early.
  ;; If they've already left school, that youth will follow the procedure for being in the community.

  let SCHOOL-HOUR 6
  repeat SCHOOL-HOUR [
    ask turtles [
       if (member? patch-here school-patches) [turtle-leaves-early]
       if (member? patch-here neighborhood-patches) [turtle-in-community]
    ]
  ]

  ;; At the end of the school day, if the youth is still in school (i.e., stayed the whole day):
  ;; depending on the schools protective score (a probability which represents
  ;; the likelihood of a teacher, class, etc being positively impactful on the youth)
  ;; the youth's prosocial tally will go up. Then, the youth moves into the neighborhood.

  ;; If not still in school, depending on the neighborhood risk score (a probability which
  ;; represents the likelihood that they will meet a deviant peer, etc), the youth's
  ;; antisocial tally will go up.

  ask turtles [
    ifelse (member? patch-here school-patches) [
      if(random-float 1.00 < pro-opp) [set prosocial prosocial + .10]
      move-to one-of neighborhood-patches]
    [ if random-float 1.00 < risk-opp [set antisocial antisocial + .10 ]]
  ]
end

to turtles-after-school

  ;; Set after school time to 5 hours (e.g., 2-7pm).
  ;; Here, youth are allowed to roam around the neighborhood.

  let AFTER-HOUR 5
  repeat AFTER-HOUR [
    ask turtles [
      turtle-in-community
     ]
  ]
end

to turtles-evenings

  ;; Set the evening duration with family to 4 hours (e.g., 7-11pm).

  let EVENING-HOUR 4
  repeat EVENING-HOUR [
    ask turtles [
      ifelse (member? patch-here home-patches) [turtle-at-home]
      [move-to one-of home-patches]
    ]
  ]

  ;; This provides an indication of whether the youth has had more
  ;; antisocial experiences (red) or prosocial experiences (lime).

  ask turtles [
    ifelse antisocial > prosocial [set color red ]
      [set color lime ]
  ]
end

to turtle-leaves-early

  ;; If the turtle is in school, chance of leaving early depends on individual and school risk.
  ;; Depending on the location's prosocial opportunity probability (pro-opp), the youth may stay in school
  ;; (i.e., move to a different location within school).

  ;; If not, depending on the location's risk opportunity probability (risk-opp),
  ;; the youth may be faced with an antisocial opportunity. Depending on the
  ;; youth's risk score (probability), they may choose to leave school early.

  ifelse (member? patch-here school-patches) and (random-float 1.00 < pro-opp )
      [move-to one-of school-patches]
  [if (member? patch-here school-patches) and (random-float 1.00 < risk-opp)
    [if random-float 1.00 < individual-risk [move-to one-of neighborhood-patches]]
    ]
end

to turtle-in-community

  ;; First, have youth move randomly, but
  ;; make sure they stay in the neighborhood patches.

    if random-float 1.00 < .10 [set heading random 360]
    if patch-ahead 1 != nobody [
       if member? patch-ahead 1 neighborhood-patches [
          forward 1
       ]
  ]

    ;; While the youth is in the community, based on the youth's location,
    ;; there will be a chance (pro-opp) the youth
    ;; encounters a positive influence and/or has a pro-social opportunity.

    ;; If the youth does not have a prosocial opportunity, based on the youth's location,
    ;; there will be a chance (risk-opp) the youth
    ;; encounters a negative influence or has an anti-social opportunity.

    ifelse random-float 1.00 < ( pro-opp) [
      turtle-meets-positive-influence]
   [if random-float 1.00 < ( risk-opp) [turtle-meets-negative-influence] ]
end


;; If the turtle meets a positive influence, there is a chance based on the youth's
;; protective factor (individual-pro) that they will seize the opportunity. If they
;; choose the positive opportunity, their prosocial experience score goes up.

to turtle-meets-positive-influence
    if random-float 1.00 < (individual-pro ) [
      set prosocial prosocial + .10]
end

;; If the turtle meets a negative influence, there is a chance based on the youth's
;; risk factor (individual-risk) that they will seize the opportunity. If they
;; choose the negative opportunity, their antisocial experience score goes up.

to turtle-meets-negative-influence
    if random-float 1.00 < (individual-risk) [
      set antisocial antisocial + .10]
end

to turtle-at-home

  ;; While at home, turtle might take in family risk or protective influence.
  ;; Based on the family risk score (probability), and ensuring the individual-risk score stays within the
  ;; bounds of a probability, additionally, whether the youth's risk score is higher than protective score,
  ;; the youth's individual risk score(probability) may go up, or if not, the youth's individual risk score
  ;; may go down.

  ifelse (random-float 1.00 < (family-risk )) and (individual-risk < .98 ) and (individual-risk > individual-pro) [
    set individual-risk individual-risk + .001
  ] [ if individual-risk > .02 and (individual-risk < individual-pro) [set individual-risk individual-risk - .001 ]]


  ;; Based on the family protective score (probability), and ensuring the individual-protective score stays within the
  ;; bounds of a probability, additionally, whether the youth's protective score is higher than risk score,
  ;; the youth's individual protective score(probability) may go up, or if not, the youth's individual protective score
  ;; may go down.

  ifelse (random-float 1.00 < (family-pro )) and (individual-pro < .98) and (individual-pro > individual-risk) [
       set individual-pro individual-pro + .001
  ] [ if individual-pro > .02 and (individual-pro < individual-risk) [set individual-pro individual-pro - .001 ] ]
end


;; This procedure checks to see that the value produced by the random-normal
;; function stays within bounds. If not, another number is randomly
;; drawn.

to-report random-normal-in-bounds [med dev mmin mmax]
  let result random-normal med dev
  if result < mmin or result > mmax
    [ report random-normal-in-bounds med dev mmin mmax ]
  report result
end

;; This procedure checks to see that the value produced by the random-exponential
;; function stays within bounds. If not, another number is randomly
;; drawn.

to-report random-exponential-in-bounds [med mmin mmax]
  let result random-exponential med
  if result < mmin or result > mmax
    [ report random-exponential-in-bounds med mmin mmax ]
  report result
end
@#$#@#$#@
GRAPHICS-WINDOW
571
17
1008
559
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
1
1
-16
16
-20
20
0
0
1
ticks
30.0

BUTTON
33
16
99
49
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
125
16
188
49
go
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
13
63
179
96
risk-level
risk-level
1
99
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
17
103
229
121
set family risk level between 1-99
11
0.0
1

SLIDER
14
123
181
156
schools-risk
schools-risk
1
99
50.0
1
1
NIL
HORIZONTAL

SLIDER
15
162
183
195
community-risk
community-risk
1
99
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
19
201
337
219
set school and community risk level between 1-99
11
0.0
1

PLOT
10
398
198
518
family risk 
score
frequency
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -2674135 true "" "histogram [family-pro] of turtles"

PLOT
11
272
197
392
Family protective 
score
frequency
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -13345367 true "" "histogram [family-pro] of turtles"

MONITOR
216
217
286
262
Prosocial
mean [prosocial] of turtles
1
1
11

MONITOR
12
221
86
266
Antisocial
mean [antisocial] of turtles
1
1
11

SLIDER
194
62
353
95
protective-level
protective-level
1
99
50.0
1
1
NIL
HORIZONTAL

SLIDER
192
123
360
156
schools-protective
schools-protective
1
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
196
161
359
194
community-protective
community-protective
1
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
115
222
198
267
% antisocial
count turtles with [antisocial > prosocial] / count turtles
2
1
11

PLOT
202
272
384
392
School Protective
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -13345367 true "" "histogram [pro-opp] of school-patches"

PLOT
202
397
385
519
School Risk
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -2674135 true "" "histogram [risk-opp] of school-patches"

PLOT
390
271
566
391
Community Protective
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -13345367 true "" "histogram [pro-opp] of neighborhood-patches"

PLOT
391
396
566
518
Community Risk
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -2674135 true "" "histogram [risk-opp] of neighborhood-patches"

PLOT
377
126
564
258
risk and protective scores
NIL
NIL
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.01 1 -2674135 true "" "histogram [individual-risk] of turtles"
"pen-1" 0.01 1 -13345367 true "" "histogram [individual-pro] of turtles"

@#$#@#$#@
## WHAT IS IT?

This model is developed to examine and test Interactional Theory (Thornberry, 1987; Thornberry & Krohn, 2005). More specifically, it examines the bidirectional causality premise, which posits that youth delinquency results from the youth's interaction with their environments. Secondly, it also allows for understanding the proportionality of cause and effect premise, which posits that the more risk, the more likely and the more severe the resulting delinquency.

## HOW IT WORKS

The model consists of youth who move through their days. Their days consist of time spent at school (brown patches), time spent in the community (green patches), and time spent at home (blue patches). Throughout their days, the youth may face prosocial or antisocial opportunities, depending on risk associated with their school and neighborhood environments. While at home, the youth's risk or protective factors may be modified based on their family's risk and protective scores.

Youth turn red if their antisocial experiences outweigh their prosocial experiences, and they turn lime green if their prosocial experiences outweigh their antisocial experiences.

## HOW TO USE IT

In the model, there are the standard setup and go buttons, which sets up the model and runs the simulation.

There are six user-controlled sliders, which control family risk and family protective factors, school risk and school protective factors, and community risk and community protective factors. 

There are several plots and monitors to track the functioning of the model. The six plots at the botttom show the resulting distribution of risk and protective scores that are sett by the user. These do not change as the model runs. These are probabilities, so while they are assigned a random value from the exponential distribution with the user-controlled value as the mean, they are also bound between 0 and 1.

The risk and protective scores, which is the plot to the right of the six sliders, shows the individual risk (red) and protective (blue) scores. These are assigned as a random distribution around the family's risk and protective scores. These are modified as the model runs.

Finally, in the middle of the console, there are monitors that indicate the average prosocial and average antisocial score, and indicates the percentage of youth with a higher antisocial than prosocial score.

## THINGS TO NOTICE

While the prosocial and antisocial scores continue to increase indefinitely as the model runs, the percent antisocial (youth with a greater antisocial than prosocial score) stabilizes pretty quickly. The individual risk and protetctive scores tend to max out or bottom out fairly quickly. This reflects the path dependency that can often result in the lives of these youths.


## THINGS TO TRY

Test the impact of environmental risk by setting the family risk level high, and playing around with the school and community risk settings. Also, test the interaction of prosocial and antisocial influences by setting all the protective influences high and hte risk influences low, and vice versa, to see if they offset each other.

## EXTENDING THE MODEL

Future possibilities include adding siblings based on where turtles begin, and/or create friend networks, so that the youth is also influenced by siblings or youth in their nettworks.

Future possibilities also involve modifying the code to reflect a single continum of high-risk to high-protective, rather than treating it as two distinct processes.

## CREDITS AND REFERENCES

Thornberry, T. P. (1987). Toward an interactional theory of delinquency. Criminology, 25(4), 863–892. https://doi.org/10.1111/j.1745-9125.1987.tb00823.x

Thornberry, T. P., & Krohn, M. D. (2005). Applying interactional theory to the explanation of continuity and change in antisocial behavior. In Integrated developmental and life-course theories of offending (pp. 183–210). New Brunswick, NJ: Transaction Publishers.
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
  <experiment name="Systematic Differences" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1"/>
    <metric>count turtles with [antisocial &gt; prosocial] / count turtles</metric>
    <metric>mean [prosocial] of turtles</metric>
    <metric>min [prosocial] of turtles</metric>
    <metric>median [prosocial] of turtles</metric>
    <metric>max [prosocial] of turtles</metric>
    <metric>mean [antisocial] of turtles</metric>
    <metric>min [antisocial] of turtles</metric>
    <metric>median [antisocial] of turtles</metric>
    <metric>max [antisocial] of turtles</metric>
    <metric>count turtles with [individual-risk &lt; .02]</metric>
    <metric>count turtles with [individual-risk &gt; .98]</metric>
    <metric>count turtles with [individual-pro &lt; .02]</metric>
    <metric>count turtles with [individual-pro &gt; .98]</metric>
    <metric>mean [family-risk] of turtles</metric>
    <metric>min [family-risk] of turtles</metric>
    <metric>median [family-risk] of turtles</metric>
    <metric>max [family-risk] of turtles</metric>
    <metric>mean [family-pro] of turtles</metric>
    <metric>min [family-pro] of turtles</metric>
    <metric>median [family-pro] of turtles</metric>
    <metric>max [family-pro] of turtles</metric>
    <metric>mean [risk-opp] of school-patches</metric>
    <metric>min [risk-opp] of school-patches</metric>
    <metric>median [risk-opp] of school-patches</metric>
    <metric>max [risk-opp] of school-patches</metric>
    <metric>mean [pro-opp] of school-patches</metric>
    <metric>min [pro-opp] of school-patches</metric>
    <metric>median [pro-opp] of school-patches</metric>
    <metric>max [pro-opp] of school-patches</metric>
    <metric>mean [risk-opp] of neighborhood-patches</metric>
    <metric>min [risk-opp] of neighborhood-patches</metric>
    <metric>median [risk-opp] of neighborhood-patches</metric>
    <metric>max [risk-opp] of neighborhood-patches</metric>
    <metric>mean [pro-opp] of neighborhood-patches</metric>
    <metric>min [pro-opp] of neighborhood-patches</metric>
    <metric>median [pro-opp] of neighborhood-patches</metric>
    <metric>max [pro-opp] of neighborhood-patches</metric>
    <enumeratedValueSet variable="schools-risk">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community-protective">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-level">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community-risk">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schools-protective">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protective-level">
      <value value="25"/>
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="350"/>
    <metric>list [individual-risk] of turtles</metric>
    <metric>list [individual-pro] of turtles</metric>
    <enumeratedValueSet variable="schools-risk">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community-protective">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risk-level">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="community-risk">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="schools-protective">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="protective-level">
      <value value="50"/>
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
