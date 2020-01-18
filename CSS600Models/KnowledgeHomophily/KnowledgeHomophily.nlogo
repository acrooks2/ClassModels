
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set up a breed of turtles
;; researchers seek those with similar knowledge
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [researchers researcher]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; researchers have...
;;   knowledge:             What they know
;;   jaccard-similarity:    How similar they are to other they can see
;;   color:                 How similar they are to others {built-in variable}
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
researchers-own  [knowledge jaccard-similarity]

globals [
  average-similarity  ;; The average Jacard Index for all researchers
  old-mean
  new-mean
  var
  bits                ;; Length of the concept
  social-space-size   ;; neighborhood is 3, 5, or 7
  colors
  do-once
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Get everything initialized
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all
  ;; Setup the display colors
  set colors [14 15 17 27 37 47 57 67 66 64 64]
  ;; Setup for running mean and variance
  set old-mean 0
  set new-mean 0
  set var 0
  ;; Setup for plot
  set do-once false
  ;; Setup researcher graphic
  set-default-shape researchers "person student"
  ;; Rename knowledge-size to bits
  set bits knowledge-size
  ;; Randomly place the researchers
  ask n-of number-researchers patches [
    sprout-researchers 1 [
      set color 14
      set knowledge create-knowledge bits
    ]
  ]
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Three social-space sizes are available
  ;; Sets size based on chooser selection by user
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  if social-space-sizes = "3x3" [set social-space-size 3]
  if social-space-sizes = "5x5" [set social-space-size 5]
  if social-space-sizes = "7x7" [set social-space-size 7]
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Either Go button has been pressed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  seek-others
  set average-similarity mean [jaccard-similarity] of researchers
  tick
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Calculate a running mean and running variance
  ;; Based on the paper:
  ;; Note on a Method for Calculating Corrected Sums of Squares and Products
  ;; B. P. Welford
  ;; Technometrics , Vol. 4, No. 3 (Aug., 1962), pp. 419-420
  ;; Published by: American Statistical Association and American Society for Quality
  ;; Article Stable URL: http://www.jstor.org/stable/1266577
  ;; Discussed here:
  ;; http://www.johndcook.com/standard_deviation.html
  ;; Implemented from pseudo code at:
  ;; http://dsp.stackexchange.com/questions/811/determining-the-mean-and-standard-deviation-in-real-time
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  set old-mean new-mean
  set new-mean new-mean + ((average-similarity - new-mean) / ticks)
  set var var + ((average-similarity - new-mean) * (average-similarity - old-mean))
  if ticks = 1000 [stop]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Seek other similar researchers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to seek-others
  ask researchers [
    ifelse not any? turtles-on social-space social-space-size [
      set color 14
      set jaccard-similarity 0
    ][
      let researcher1-id who
      let researcher2-id -1
      let researcher2-similarity 0
      let researcher2-similarity-id -1
      ;; Find researcher with most similar knowledge
      ask turtles-on social-space social-space-size [
        set researcher2-id who
        let researcher1-similarity jaccard-index researcher1-id researcher2-id
        ;; Looking for the other researcher with highest similarity
        if researcher1-similarity > researcher2-similarity [
          set researcher2-similarity researcher1-similarity
          set researcher2-similarity-id researcher2-id
        ]
      ]
      ;; The other researcher with highest similarity is compared to the minimum required similarity
      if researcher2-similarity > minimum-similarity [
        let researcher1-heading 0
        let researcher2-heading 0
        ask turtle researcher1-id [
          set researcher1-heading heading
          set jaccard-similarity researcher2-similarity
        ]
        ask turtle researcher2-similarity-id [
          set researcher2-heading heading
        ;  set jaccard-similarity researcher2-similarity
        ]
        let new-heading ((researcher1-heading + researcher2-heading) / 2)
        ask turtle researcher1-id [set heading new-heading]
        ;ask turtle researcher2-similarity-id [set heading new-heading]
      ]
      ask turtle researcher1-id [set color item (int (jaccard-similarity * 10)) colors]
      ;ask turtle researcher2-id [set color item (int (jaccard-similarity * 10)) colors]
    ]
    fd 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Jaccard Index
;; Calculate the similarity between the knowledge
;; of two researchers.
;; Input:
;;   id1, id2 - The unique turtle ID number
;;              assigned to two researchers
;; Return:
;;   The Jaccard Index as a number between 0 & 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report jaccard-index [id1 id2]
  let k1 0
  let k2 0
  ask turtle id1 [set k1 knowledge]
  ask turtle id2 [set k2 knowledge]
  let intersection 0
  let union 0
  let i 0
  let bit-and 0
  let bit-or 0
  let return-value 0
  repeat bits [
    ifelse (item i k1 = 1) and (item i k2 = 1) [
      set bit-and 1
    ][
      set bit-and 0
    ]
    ifelse (item i k1 = 1) or (item i k2 = 1) [
      set bit-or 1
    ][
      set bit-or 0
    ]
    set intersection intersection + bit-and
    set union union + bit-or
    set i i + 1
  ]
  ifelse union > 0 [
    set return-value intersection / union
  ][
    set return-value 0
  ]
  report return-value
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Create a concept
;; Each concept is a list of
;; binary numbers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report create-knowledge [ks]
  let return-value []
  repeat ks [
    set return-value lput random 2 return-value
  ]
  report return-value
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This reporter was inspired by the NetLogo code example "Neighborhood Example."
;; Input:
;;    n - The neighbor size expressed as the number of square on the side of a square
;; Returns:
;;    A set of patches relative to a location
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to-report social-space [ n ]
  ;; Use neighbors if n = 3.
  if n = 3 [report neighbors]
  ;; If n = 5, we will look at the 24 surrounding patches, relative to the calling turtle.
  ;; The code is styled for human readability.
  if n = 5 [
    report (patches at-points [[-2  2] [-1  2] [0  2] [1  2] [2  2]
                               [-2  1] [-1  1] [0  1] [1  1] [2  1]
                               [-2  0] [-1  0]        [1  0] [2  0]
                               [-2 -1] [-1 -1] [0 -1] [1 -1] [2 -1]
                               [-2 -2] [-1 -2] [0 -2] [1 -2] [2 -2]]
    )
  ]
  ;; If n = 7, there are 48 patches to consider.
  if n = 7 [
    report (patches at-points [[-3  3] [-2  3] [-1  3] [0  3] [1  3] [2  3] [3  3]
                               [-3  2] [-2  2] [-1  2] [0  2] [1  2] [2  2] [3  2]
                               [-3  1] [-2  1] [-1  1] [0  1] [1  1] [2  1] [3  1]
                               [-3  0] [-2  0] [-1  0]        [1  0] [2  0] [3  0]
                               [-3 -1] [-2 -1] [-1 -1] [0 -1] [1 -1] [2 -1] [3 -1]
                               [-3 -2] [-2 -2] [-1 -2] [0 -2] [1 -2] [2 -2] [3 -2]
                               [-3 -3] [-2 -3] [-1 -3] [0 -3] [1 -3] [2 -3] [3 -3]]
    )
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
628
429
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-20
20
-20
20
0
0
1
ticks
30.0

SLIDER
20
10
195
43
number-researchers
number-researchers
2
200
200.0
1
1
NIL
HORIZONTAL

CHOOSER
20
50
195
95
knowledge-size
knowledge-size
2 3 4 5 6 7 8
6

BUTTON
64
195
154
228
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
65
235
155
268
Go Once
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

BUTTON
65
275
155
308
Go Lots
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
636
11
916
161
Average Similarity
Time
Similarity
0.0
10.0
0.0
1.0
true
false
"" ";let minX 0\n;let minY 0\n;let maxY 1\n;if ticks > 200 [\n;  set minX (ticks - 200)\n;  if not do-once [\n;    set minY average-similarity - (sqrt (var / ticks) * 3.0)\n;    set maxY average-similarity + (sqrt (var / ticks) * 3.0)\n;    set-plot-y-range ((round (minY * 10)) / 10) ((round (maxY * 10)) / 10)\n;    set do-once True\n;  ]\n;]\n;set-plot-x-range (minX) (round ((ticks + 1) * 10)) / 10"
PENS
"default" 1.0 0 -16777216 true "" "plot average-similarity"

CHOOSER
20
102
195
147
social-space-sizes
social-space-sizes
"3x3" "5x5" "7x7"
0

SLIDER
20
155
195
188
minimum-similarity
minimum-similarity
0
1
0.0
.01
1
%
HORIZONTAL

MONITOR
636
164
744
209
Cumulative Mean
new-mean
4
1
11

MONITOR
731
164
915
209
Cumulative Standard Deviation
sqrt (var / ticks)
5
1
11

@#$#@#$#@
## WHAT IS IT?

This model creates associations between agents based on how similar their knowledge is to each other. The model purposely avoids the explicit use social networks and instead relies upon implicit networks formed by agents who by happenstance find themselves within the same social space. This knowledge homophily is explored by measuring the agent population's similarity and visually by observing the formation of clusters.

## HOW IT WORKS

The simulation begins with agents in a torus grid environment with random positions and headings. This environment simulates a single room, perhaps at a conference. All agents 'know' the same single concept, which has a uniform number of components. Knowledge of the individual components is randomly assigned giving each agent the potential of dissimilar knowledge.

As each agent moves through another agent’s social space, they examine the knowledge of those they meet and determine whose knowledge is most similar to their own. If that similarity is greater than some minimum, they turn half way toward that other agent's heading in an attempt to stay close by. Over time, agents form clusters that travel together within the environment.

## HOW TO USE IT

There are four parameters that can be adjusted during model initialization:

**number-researchers (slider):** This ranges from two to two hundred in increments of one. It sets determines the number of agents that will be in the simulation.

**knowledge-size (chooser):** Determines the length, in bits, of the agent concept size. The parameter ranges from two to eight in increments of one.

**social-space-sizes (chooser):** Sets the size of the agent's social space expressed as a Moore neighborhood of 3x3, 5x5, or 7x7.

**minimum-similarity (slider):** Sets the value that any Jaccard Index must be above for consideration of agent similarity. This parameter ranges from 0.00 to 1.00 in increments of 0.01

Press the `Setup` button to initialize the model.

Press the `Go` button for the model to move forward one tick.

Press the `Go Lots` button for the model to move forward continuously.

The model will stop at 1,000 ticks.

## THINGS TO NOTICE

The average similarity plot, cumulative mean, and cumulative standard deviation will be updated each tick.

Agents use a color found in NetLogo's color palette to indicate the Jaccard Index value of their similarity to other agents. There are ten color categories ranging from dark red, through yellow, and ending at dark green. Agents with less similarity than others are more red than green and agents with more similarity are more green than red.


## THINGS TO TRY

Vary the sliders and chooser to see the effect on the ability of the agents to form clusters.

## EXTENDING THE MODEL

Examine situations where agents know a variety of concepts, each of which is of a different bit size.

People outside the simulation world know more than one concept and this could be examined in a simulation by randomly assigning multiple concepts, each of various sizes.

## NETLOGO FEATURES

A cumulative (running) mean, variance, and standard deviation is calculated.

## RELATED MODELS

See the NetLogo models 'Flocking' and 'Neighborhood Example' in the models library.

## CREDITS AND REFERENCES

Calculate a running mean and running variance is based on the paper:

Welford, B. P. (1962, August). Note on a Method for Calculating Corrected Sums of Squares and Products. Technometrics, 4(3), 419-420. Retrieved December 1, 2013, from http://www.jstor.org/stable/1266577

Discussed here: http://www.johndcook.com/standard_deviation.html

Implemented from pseudo code at: http://dsp.stackexchange.com/questions/811/determining-the-mean-and-standard-deviation-in-real-time
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
<experiments>
  <experiment name="experiment-256-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="256"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-128-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="128"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-64-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="64"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-32-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="32"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-16-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="16"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-8-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="8"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-4-3x3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;3x3&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-256-7x7" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;7x7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="256"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment-128-7x7" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>new-mean</metric>
    <metric>sqrt (var / ticks)</metric>
    <enumeratedValueSet variable="neighborhood-sizes">
      <value value="&quot;7x7&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-authors">
      <value value="200"/>
    </enumeratedValueSet>
    <steppedValueSet variable="minimum-similarity" first="0" step="0.01" last="1"/>
    <enumeratedValueSet variable="knowledge-size">
      <value value="128"/>
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
1
@#$#@#$#@
