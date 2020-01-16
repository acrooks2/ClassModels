;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; NetLogo version 6.1.0

;; This goal of this NetLogo program is to demonstrate two theories on labor market discrimination
;; (0) Replicate current discrimination impacts for hiring and unemployment
;; (1) Taste-Based Discrimination  <-- this one is a future extension opportunity
;; (2) Statistical Discrimination  <-- this one is a future extension opportunity

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; name the global variables
globals[
  Group1-Num-Employed
  Group2-Num-Employed
  Group1-Num-Unemployed
  Group2-Num-Unemployed
  Group1-Percent-Unemployed
  Group2-Percent-Unemployed
  Group1-Average-JobTenure
  Group2-Average-JobTenure
  Group1-Average-UnemploymentDuration
  Group2-Average-UnemploymentDuration
  Group1-to-Group2-UnemploymentDuration-ratio
]

;; group is either discriminated (group 1, green turtles) or non-discriminated (group 2, violet turtles)
;; employed-status is 1 if employed or 0 if unemployed
;; job-tenure increments by 1 month (each tick) while still employed
;; unemployment-duration increments by 1 month (each tick) while still unemployed
;; prev-color stores previous color to represent whether the turtle was employed/unemployed the previous month
turtles-own [group employed-status job-tenure unemployment-duration prev-color]

;; setup procedure
to setup
  ;; clear to world
  clear-all

  ;; set background to be white
  ask patches [
    set pcolor white
  ]

  ;; create turtles based on sum of the counts of the two groups
  create-turtles (Group1-Count + Group2-Count) [ setxy random-xcor random-ycor ]
  ;; set all turtles to be violet
  ask turtles [
    ;; violet turtles are group 2
    set color violet
    set prev-color violet
    set shape "face happy"
    set group 2

    ;; set initial employed-status as employed
    set employed-status 1

    ;; median job tenure in 2018 per BLS is 4.2 years
    ;; https://www.bls.gov/news.release/tenure.nr0.htm
    ;; set initial job tenure as random-normal distribution with mean 4.2 years and standard deviation 2 years
    set job-tenure random-normal 4.2 2

    ;; simplifying assumption: make sure job-tenure is not 0
    if job-tenure = 0 [
      ;; set to be mean value if it was set to 0
      set job-tenure 4.2
    ]

    ;; simplifying assumption: set initial unemployment duration to be 0
    set unemployment-duration 0.0
  ]
  ;; set group 1 turtles to be green
  ask n-of Group1-Count turtles [
    ;; green turtles are group 1
    set color green
    set prev-color green
    set shape "face sad"
    set group 1
  ]
  ;; when a turtle becomes unemployed they will be orange

  ;; set initial employment statistics based on all turtles being employed
  set Group1-Num-Employed Group1-Count
  set Group2-Num-Employed Group2-Count
  set Group1-Num-Unemployed 0
  set Group2-Num-Unemployed 0
  set Group1-Percent-Unemployed 0.0
  set Group2-Percent-Unemployed 0.0
  set Group1-Average-JobTenure (mean [job-tenure] of turtles with [group = 1])
  set Group1-Average-UnemploymentDuration (mean [unemployment-duration] of turtles with [group = 1])
  set Group2-Average-JobTenure (mean [job-tenure] of turtles with [group = 2])
  set Group2-Average-UnemploymentDuration (mean [unemployment-duration] of turtles with [group = 2])
  ;; set to be 2.0 so no division by zero error
  ;; this initial value is meant to be place-holders to let model run
  set Group1-to-Group2-UnemploymentDuration-ratio 2.0

  ;; reset ticks
  reset-ticks
end

;; go procedure
to go
  ;; run model for 30 years of ticks, where each tick represents 1 month
  ;; 30 * 12 = 360 ticks
  if ticks >= 360 [ stop ]

  ;; decide whether to leave job or get new job
  leave-job

  ;; update unemployment percentages
  set Group1-Percent-Unemployed (Group1-Num-Unemployed / (Group1-Num-Employed + Group1-Num-Unemployed))
  set Group2-Percent-Unemployed (Group2-Num-Unemployed / (Group2-Num-Employed + Group2-Num-Unemployed))

  ;; update job tenure and unemployment duration
  set Group1-Average-JobTenure (mean [job-tenure] of turtles with [group = 1])
  set Group1-Average-UnemploymentDuration (mean [unemployment-duration] of turtles with [group = 1])
  set Group2-Average-JobTenure (mean [job-tenure] of turtles with [group = 2])
  set Group2-Average-UnemploymentDuration (mean [unemployment-duration] of turtles with [group = 2])

  ;; update ratios
  set Group1-to-Group2-UnemploymentDuration-ratio (Group1-Average-UnemploymentDuration / Group2-Average-UnemploymentDuration)

  ;; increment tick
  tick
end

;; leave job procedure
to leave-job
  if Discrimination-Setting = "Current Conditions Replication" [
    ask turtles [
      ;; median job tenure in 2018 per BLS is 4.2 years
      ;; https://www.bls.gov/news.release/tenure.nr0.htm

      ;; simplifying assumption: you do not change jobs prior to 4.2 years at current job
      if job-tenure < 4.2 AND employed-status = 1 [
        ;; increment job-tenure by 1 month, where each tick represents one month on the job
        set job-tenure (job-tenure + (1 / 12))
        set prev-color color
      ]

      ;; condition where you have at least 4.2 years of job tenure and possibly leave your job
      if job-tenure >= 4.2 AND employed-status = 1 [
        ;; simplifying assumption: once you reach 4.2 years you consider changing job with 50/50 chance
        ifelse (random-float 1.0) > 0.5
        [
          ;; leave job
          set job-tenure 0.0
          set prev-color color
          set color orange
        ]
        [
          ;; stay at job
          ;; increment job-tenure by 1 month, where each tick represents one month on the job
          set job-tenure (job-tenure + (1 / 12))
          set prev-color color
        ]
      ]

      ;; condition where you are not employed and want a job
      ;; splits out into two sequences, one for each group
      ;; this is where the taste-based discrimination is set up
      ;; reference: https://www.nber.org/digest/sep03/w9873.html
      ;; call back rates for applicants with white-sounding-names is 1 in 10
      ;; call back rates for applicants with African American-sounding-names is 1 in 15
      ;; simplifying assumption: have the above-referenced probabilities of getting a job each month if currently unemployed
      if employed-status = 0 [
        ;; group 1 is subject to labor market discrimination
        if group = 1 [
          ifelse (random-float 1.0) > (Group1-Discrimination-Level)
          [
            ;; condition where did not get new job this month
            set prev-color color
          ]
          [
            ;; condition where did get new job this month
            ;; increment job-tenure by 1 month, where each tick represents one month on the job
            set job-tenure (job-tenure + (1 / 12))
            set prev-color orange
            set color green
          ]
        ]
        ;; group 2 is not subject to labor market discrimination
        if group = 2 [
          ifelse (random-float 1.0) > (Group2-Discrimination-Level)
          [
            ;; condition where did not get new job this month
            set prev-color color
          ]
          [
            ;; condition where did get new job this month
            ;; increment job-tenure by 1 month, where each tick represents one month on the job
            set job-tenure (job-tenure + (1 / 12))
            set prev-color orange
            set color violet
          ]
        ]
      ]

      ;; call is-employed to update employment/unemployment statistics
      is-employed
    ]
  ]
  if Discrimination-Setting = "Taste Based" [
    ;; future extenions
  ]
  if Discrimination-Setting = "Statistical" [
    ;; future extension
  ]
end

;; is employed procedure
to is-employed

  ;; if recently became unemployed then update employment/unemployment counts
  if color = orange AND prev-color != orange [

    ;; change employed-status to be unemployed
    set employed-status 0
    ;; change job-tenure to be 0 since newly unemployed
    set job-tenure 0
    ;; set unemployment-duration to be 1 month
    set unemployment-duration (1 / 12)

    ;; update counts
    if group = 1 [
      set Group1-Num-Employed (Group1-Num-Employed - 1)
      set Group1-Num-Unemployed (Group1-Num-Unemployed + 1)
    ]
    if group = 2 [
      set Group2-Num-Employed (Group2-Num-Employed - 1)
      set Group2-Num-Unemployed (Group2-Num-Unemployed + 1)
    ]
  ]

  ;; if recently became employed then update employment/unemployment counts
  if color != orange AND prev-color = orange [

    ;; change employed status to be employed
    set employed-status 1
    ;; increment job-tenure by 1 month
    set job-tenure (1 / 12)
    ;; change unemployment-duration to be 0 since newly employed
    set unemployment-duration 0

    ;; update counts
    if group = 1 [
      set Group1-Num-Employed (Group1-Num-Employed + 1)
      set Group1-Num-Unemployed (Group1-Num-Unemployed - 1)
    ]
    if group = 2 [
      set Group2-Num-Employed (Group2-Num-Employed + 1)
      set Group2-Num-Unemployed (Group2-Num-Unemployed - 1)
    ]
  ]

  ;; if remained unemployed then update employment/unemployment counts
  if color = orange AND prev-color = orange [
    ;; change unemployment-duration to be 0 since newly employed
    set unemployment-duration (unemployment-duration + (1 / 12))
  ]

  ;; if remained employed then updated employed/unemployment counts
  if color != orange AND prev-color != orange [
    ;; increment job-tenure by 1 month
    set job-tenure (job-tenure + (1 / 12))
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; END OF PROGRAM ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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
1
1
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
28
23
91
56
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
103
23
166
56
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
0

CHOOSER
11
72
186
117
Discrimination-Setting
Discrimination-Setting
"Current Conditions Replication" "Taste Based" "Statistical"
0

INPUTBOX
7
139
90
199
Group1-Count
2500.0
1
0
Number

INPUTBOX
105
139
191
199
Group2-Count
2500.0
1
0
Number

MONITOR
209
455
349
500
NIL
Group1-Num-Employed
4
1
11

MONITOR
353
455
493
500
NIL
Group2-Num-Employed
4
1
11

PLOT
1090
10
1523
272
Unemployment Percentages
Time
Percent Unemployed
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Group 1" 1.0 0 -10899396 true "" "plotxy ticks Group1-Percent-Unemployed"
"Group 2" 1.0 0 -8630108 true "" "plotxy ticks Group2-Percent-Unemployed"

TEXTBOX
11
352
185
647
NOTE:\n\nGroup1 (green sad face) - subject to labor market discrimination\n\nGroup2 (purple happy face) - not subject to labor market discrimination\n\nFace color changes to orange when unemployed\n\n***\n\nBaseline discrimination levels are (1 out of 15) for Group1 and (1 out of 10) for Group2. These values are similar to actual conditions from resume study call-back rates.
11
0.0
1

PLOT
650
10
1085
273
Average Job Tenure - Employed Turtles
Time (months)
Avg. Job Tenure (years)
0.0
10.0
0.0
5.0
true
true
"" ""
PENS
"Group 1" 1.0 0 -10899396 true "" "plotxy ticks Group1-Average-JobTenure"
"Group 2" 1.0 0 -8630108 true "" "plotxy ticks Group2-Average-JobTenure"

PLOT
651
343
1087
598
Average Unemployment Duration - Unemployed Turtles
Time (months)
Avg. Unemployment Duration (years)
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Group 1" 1.0 0 -10899396 true "" "plotxy ticks Group1-Average-UnemploymentDuration"
"Group 2" 1.0 0 -8630108 true "" "plotxy ticks Group2-Average-UnemploymentDuration"

INPUTBOX
7
210
161
270
Group1-Discrimination-Level
0.0666667
1
0
Number

INPUTBOX
6
274
161
334
Group2-Discrimination-Level
0.1
1
0
Number

PLOT
1091
343
1524
598
Group1 to Group2 Unemployment Duration Ratio
Time (months)
Ratio of Unemployment Duration
0.0
10.0
0.0
4.0
true
true
"" ""
PENS
"Ratio" 1.0 0 -16777216 true "" "plotxy ticks Group1-to-Group2-UnemploymentDuration-ratio"

MONITOR
1090
276
1245
321
Group1-Percent-Unemployed
Group1-Percent-Unemployed
4
1
11

MONITOR
1249
276
1402
321
Group2-Percent-Unemployed
Group2-Percent-Unemployed
4
1
11

MONITOR
1187
603
1429
648
Group1-to-Group2-UnemploymentDuration-ratio
Group1-to-Group2-UnemploymentDuration-ratio
4
1
11

MONITOR
653
601
862
646
Group1-Average-UnemploymentDuration
Group1-Average-UnemploymentDuration
4
1
11

MONITOR
866
601
1075
646
Group2-Average-UnemploymentDuration
Group2-Average-UnemploymentDuration
4
1
11

MONITOR
209
505
349
550
Group1-Num-Unemployed
Group1-Num-Unemployed
4
1
11

MONITOR
353
505
494
550
Group2-Num-Unemployed
Group2-Num-Unemployed
4
1
11

MONITOR
651
277
800
322
Group1-Average-JobTenure
Group1-Average-JobTenure
4
1
11

MONITOR
803
277
951
322
Group2-Average-JobTenure
Group2-Average-JobTenure
4
1
11

@#$#@#$#@
## WHAT IS IT?

Economic researchers and labor statisticians have noted for many decades that there are structural differences in U.S. labor market outcomes between African American and white workers. This NetLogo model replicates existing discrimination levels using a simulated environment of two groups of worker agents.

## HOW IT WORKS

Agents start out employed, and then can either leave their job or stay employed. If they leave their job, the agent must overcome the discrimination level for their group to become employed again. If the discrimination level for Group 1 is greater than the discrimination level for Group 2, then the Group 1 agents are subject to labor market discrimination. Group 1 agents are represented by the green sad face symbols. Group 2 agents are represented by the purple happy face symbols. When an agent becomes unemployed their color changes to orange. Each tick represents 1 month.

## HOW TO USE IT

Enter in the number of worker agents belonging to Group 1, which is subject to labor market discrimination. Enter in the number of worker agents belonging to Group 2, which is not subject to labor market discrimination. Enter in the levels of discrimination faced by each of the groups. The level used for the Group 1 should be larger than the level for Group 2. Click Setup, and then click Go.

## THINGS TO NOTICE

By using the recommended discrimination levels the ratio of unemployment durations should be around 2.

## THINGS TO TRY

The user can manipulate the discrimination rates experienced by the two groups of worker agents. The user can also manipulate the populations of each of the two groups of worker agents.

## EXTENDING THE MODEL

This NetLogo model can be extended to demonstrate taste-based and statistical discrimination. Implementing these extensions would likely involve incorporating firm agents, in addition to the existing worker agents.

## NETLOGO FEATURES

N/A

## RELATED MODELS

N/A

## CREDITS AND REFERENCES

Bertrand, M., & Mullainathan, S. (2004). Are Emily and Greg more employable than Lakisha and Jamal? A field experiment on labor market discrimination. American economic review, 94(4), 991-1013.

Employee Tenure Summary. (2018). Retrieved from https://www.bls.gov/news.release/tenure.nr0.htm

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
