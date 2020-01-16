;Advising Impact on Retention (AIR MODEL) .nlogo
;
;demonstration model in Netlogo
;
;this version is of the setup of students on a college campus
;uses breeds, patch-specific attributes and colored patches.
;this version also uses sliders to gage student and advisor attributes
;
;-----------------------------------------------------------------------------------
breed [ students student ] ; two breeds of turtles, student breed and adviosr breed
breed [ advisors advisor ]

globals [Drop-out]

students-own [
trust-level  ; student breed owns trust, satisfaction with advising, grit, whether they are advised or not
grit-level
advised?
advising-cooldown ; advising cooldown is the period of time between when students are eligible to be advised again
]

advisors-own [
care-level                 ;advisor breed owns care for their work in advising student with empathy "care"
Information-level         ; information relates to the competency of the advsior and wether they have the correct knowlegde/content
]


to setup
  clear-all                  ;for the setup command, all the previous setting are cleared
  setup-patches                  ; patches, students, advisors, and ticks are reset
  setup-students
  setup-advisors
  reset-ticks
end


to go
  move-students   ; go command has the move-students function, as well as the advise function, with each of these in a tick
 tick
end


to setup-patches
   ask patches
  [ set pcolor 101  ; patches are set to dark blue
  ]
end

to move-students

  ask students
  [ right random 360 forward 1          ; students move around randomly at first,
  ifelse any? advisors-on neighbors and not advised? ; if they come upon a neighbor breed and haven't been " not" advised (default is false, so this would be true)
    [ advise
      set advised? true                               ; advised is set to false (default) value as part of what students own when they first populate
      set advising-cooldown cool-down
    ]
      ;else
    [ ifelse advised? and advising-cooldown = 0               ; based on Netlogo HIV model
        [ set advised? false
        ]
        ;else
        [ if advising-cooldown > 0
            [ set advising-cooldown advising-cooldown - 1
            ]
        ]
    ]
    assign-color
  ]
 check-retention


end


to check-retention

  let total-red-turtles count students with [color = red]
  let counter (total-red-turtles / student-number ) * 2  ; based on 60% precent retention, 40% drop out
  let student-retention  1


  ask students with [color = red]        ; https://stackoverflow.com/questions/37666498/how-to-create-new-generation-of-turtles-every-10-ticks
    [
      if student-retention < counter      ;https://stackoverflow.com/questions/27360422/how-can-i-count-dead-turtles-in-netlogo
      [
      set student-retention student-retention + 1 ; the number of students dropping out should reflect the 60-65 retention rate, but was made lower
      set drop-out drop-out + 1                   ; to relfect other factors that contribute to retention
      die
      ]
  ]

end



to setup-students
  create-students student-number      ; create student population based on slider
   ask students                        ; have students be blue, set shape, set default advised? to false as the default
   [ set color blue - 23
    set shape "person"
    set size 1.5                           ; set initial trust level and grit level to represent slider in the interface- can be adjusted
    set advised? false                     ; end trust level will depend on how the advising session was
    set trust-level trust
    set grit-level grit
    set advising-cooldown 3     ; cool down period is a timer between when students were last advised and can be advised again
  ]                             ; this keeps the same students from being avdised over and over again


end

to assign-color


    ifelse trust-level < 25
    [ set color red ]                 ; agents are color-coded depending on their trust/staisfaction-level with advising

  [ ifelse trust-level > 25 and trust-level < 75
      [  set color violet  ] ;if advising is average
      [ set color cyan ]; good advising is cyan beyond 75%
      ]

end



to setup-advisors
  create-advisors 1 [setxy 0 0 set size 2.5 set label 1]
;  create-advisors 1  [ setxy 10 10 set size 2.5 set label 1]            ; the advisors are set to certain patches. These were randomly choosen, could do random??
  create-advisors 1 [ setxy  -9 9 set size 2.5 set label 2]
  create-advisors 1 [ setxy 9 9   set size 2.5 set label 3]
  create-advisors 1  [ setxy 9 -9  set size 2.5 set label 4]
  create-advisors 1 [ setxy -9 -9  set size 2.5 set label 5]
  ask advisors
   [set color yellow                                              ; set color, set shape and set care and information to reference sliders
    set shape "star"
    set care-level care
    set information-level information
  ]
end



to advise
  let my-advisor one-of advisors-on neighbors                     ;http://netlogo-users.18673.x6.nabble.com/How-to-identify-neighbors-td4994740.html
  let my-advisor-care [care-level] of my-advisor
  let my-advisor-info [information-level] of my-advisor
  let student-grit grit-level
  let student-trust trust-level


  let student-felt-care? false                                ; this will set the initial default value for the actual advising interaction
  let student-got-information? false                           ; in order to have the values of the interaction affect the end trust of student


  if random 100  <= my-advisor-care           ; advisor care is less or equal to whatever the slider of care-level is set to in each run
  [ set student-felt-care? true                                         ; this means an advising interaction took place
  ]

  if random 100  <= my-advisor-info              ; advisor information on slider-infromation-level
  [set student-got-information? true             ; advising interaction took place with info-level set

  ]

  ifelse student-felt-care? and student-got-information? ; student has both care and information values
  [ let current-trust-level student-trust
    let new-trust-level random 25 +  75               ; this allows for individual attributes among advisors and gives meaning to "good" advising versus "bad"
    let average-trust-level new-trust-level + current-trust-level
    set trust-level average-trust-level / 2
  ]
  [ ifelse student-felt-care? and not student-got-information?             ; Refernces inculde Netlogo HIV model, Bidding Market, Signaling Game, Simple Birth Rates, Netlogo programming guide
      [ let current-trust-level student-trust                              ; Scott, Stephen, and Matthew Koehler (2011). A Field Guide to NetLogo, Version 1.1.
      let new-trust-level random 25 + 40
         let average-trust-level new-trust-level + current-trust-level
         set trust-level average-trust-level / 2
      ]
      [ ifelse not student-felt-care? and student-got-information?      ; values were estimated based on literature regaridng trust, care and grit. Information was included based on competency of job
        [let current-trust-level student-trust
            let new-trust-level random 25 +  30
            let average-trust-level new-trust-level + current-trust-level ; https://ccl.northwestern.edu/netlogo/docs/
            set trust-level average-trust-level / 2
        ]
        [ let current-trust-level student-trust
            let new-trust-level random 25
            let average-trust-level new-trust-level + current-trust-level
            set trust-level average-trust-level / 2
        ]
    ]

ifelse student-felt-care? and student-got-information? ; student has both care and information values
  [ let current-grit-level student-grit
    let new-grit-level random 25 + random 75               ; this allows for individual attributes among advisors and gives meaning to "good" advising versus "bad"
    let average-grit-level new-grit-level + current-grit-level
    set grit-level average-grit-level / 3
  ]
  [ ifelse student-felt-care? and not student-got-information?             ; Refernces inculde Netlogo HIV model, Bidding Market, Signaling Game, Simple Birth Rates, Netlogo programming guide
      [ let current-grit-level student-grit                             ; Scott, Stephen, and Matthew Koehler (2011). A Field Guide to NetLogo, Version 1.1.
      let new-grit-level random 25 + random 40
         let average-grit-level new-grit-level + current-grit-level
         set trust-level average-grit-level / 3
      ]
      [ ifelse not student-felt-care? and student-got-information?      ; literature regaridng trust, care, grit and mindset. Information was included based on competency of job;
        [let current-grit-level student-grit
        let new-grit-level random 25 + random 30
   let average-grit-level new-grit-level + current-grit-level       ; values for both trust and grit chosen to make sure the ranges were represented
           set grit-level average-grit-level / 3           ; 3 was chosen so grit has slightly less impact than care
        ]
        [ let current-grit-level student-grit
            let new-grit-level random 25
            let average-grit-level new-grit-level + current-grit-level
            set grit-level average-grit-level / 3
        ]
        ]

  ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
242
10
679
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
1
1
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

SLIDER
12
126
184
159
trust
trust
0
100
65.0
1
1
NIL
HORIZONTAL

SLIDER
12
169
184
202
grit
grit
0
100
71.0
1
1
NIL
HORIZONTAL

SLIDER
12
233
184
266
care
care
0
100
92.0
1
1
NIL
HORIZONTAL

SLIDER
11
275
184
308
information
information
0
100
88.0
1
1
NIL
HORIZONTAL

BUTTON
15
15
81
48
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
90
15
153
48
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
926
110
1209
300
Trust Levels
Advising Sessions
Students
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Low" 1.0 0 -2674135 true "" "plot count students with [color = red]"
"Neutral" 1.0 0 -8630108 true "" "plot count students with [color = violet]"
"High" 1.0 0 -11221820 true "" "plot count students with [color = cyan]"

MONITOR
682
69
913
114
Trust below 25%
count students with [trust-level < 25]
17
1
11

SLIDER
12
54
184
87
student-number
student-number
0
1300
700.0
1
1
NIL
HORIZONTAL

MONITOR
681
124
912
169
Trust between 25% and 75%
count students with [trust-level > 25 and trust-level < 75]
17
1
11

MONITOR
681
177
913
222
Trust 75% and greater
count students with [ trust-level > 75]
17
1
11

TEXTBOX
12
105
162
123
Student Attributes
11
0.0
1

TEXTBOX
14
214
164
232
Advisor Attributes
11
0.0
1

SLIDER
8
355
181
388
cool-down
cool-down
0
20
3.0
1
1
NIL
HORIZONTAL

TEXTBOX
709
37
876
64
Student trust levels after advising 
11
32.0
1

TEXTBOX
11
332
225
363
Time between advising sessions
11
0.0
1

TEXTBOX
984
84
1151
117
Student Trust X Advising Sessions
11
0.0
1

MONITOR
684
278
848
323
NIL
Drop-out
17
1
11

TEXTBOX
686
248
857
276
Number of students who drop out
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model of student retention in an academic environment. The model looks at the advising interaction by modeling the student's trust in an advisor, as well as the advisors care for students. The aim of the model is to show how greater academic retention is affected by the smaller interactions of students with advisors, and how the relationship between trust and care can have larger effects. 

## HOW IT WORKS

The model has two breeds, students and advisors. The students have the attributes of trust and grit. Trust changes after interactions with advisors, depending on the care advisors have for students, as well as the information/content knowledge advisors share with students. Students have grit which mitigates a bad advising session. Low trust is anything below 25%, 25 %-75% is average trust, and high trust is 75% and higher. The advising cooldown keeps students who are near advisors from being advised over and over again to create turnover in who is getting advised.

## HOW TO USE IT
Setup: sets up all the turtles and patches, clears previous runs
go: go has the turtles moving, as well as holding the counter (ticks)
trust: the trust slider is used to set the initial level of trust students have
grit: is a student attribute which is also adjusted. It can mitigate bad advising as it represents the students intrinsic motivation level
care: is an advisor attribute represented by a slider which can be increased or decreased to represent the range of care
information: is an advisor attribute represented by a slider, which also can be adjusted to demonstrate the range of knowledge an advisor can have

## THINGS TO NOTICE

Care and trust are related. When care is low, even if students have high initial trust, trust gets damaged. Information and grit can mitigate a bad advising session.

## THINGS TO TRY
Set sliders to maximum, mid values and low values. The different combinations showcase the different effects of the attributes.

## EXTENDING THE MODEL

Add more turtle memory, have the advisors have more heterogeneity, add more variables and parameters 

## NETLOGO FEATURES

Netlogo allows for representation of each student and advisors as individuals, which would make it more robust to increase heterogeneity

## RELATED MODELS

This was based on the HIV model, also looked at the Signal Game and El Farol models.

## CREDITS AND REFERENCES
Wilensky, U. (1997). NetLogo HIV model. http://ccl.northwestern.edu/netlogo/models/HIV. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL. 

Rand, W., Wilensky, U. (2007). NetLogo El Farol model. http://ccl.northwestern.edu/netlogo/models/ElFarol. Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL.

Wilensky, U. (2016). NetLogo Signaling Game model. http://ccl.northwestern.edu/netlogo/models/SignalingGame. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
  <experiment name="experiment" repetitions="1" sequentialRunOrder="false" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30"/>
    <metric>count students with [trust-level &lt; 25]</metric>
    <metric>count students with [trust-level &gt; 25 and trust-level &lt; 75]</metric>
    <metric>count students with [trust-level &gt; 75]</metric>
    <metric>drop-out</metric>
    <enumeratedValueSet variable="cool-down">
      <value value="0"/>
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="care">
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grit">
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="information">
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-number">
      <value value="700"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trust">
      <value value="25"/>
      <value value="50"/>
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
