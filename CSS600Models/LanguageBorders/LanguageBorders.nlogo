patches-own [
  Language  ;; a patch's spoken language value
  Neighbor-av  ;; the optimal local language based on neighbors' languages
  ability  ;; the precision with which an agent can adopt the optimal local language
  temp-ability  ;; place holder in procedure for ensuring that "ability" was interger only
]

to setup
  clear-all
  ask patches[
    ifelse pycor > (Initial-Percent-Green * 40)  ;; allows you to adjust population distribution
    [ set pcolor blue ]
    [ set pcolor Green ]
    ifelse pcolor = blue   ;; initial language, Language Blue is 105, Green is 55
    [ set Language 105 ]
    [ set Language 55 ]
    if Ability-for-Languages?  ;; Setting up if agents will be using a precison based language acquisition ability
    [ distribute-ability ]   ;; which distribution?
  ]
  create-corners  ;;  Sets up yellow circle turtles to define the corners of the grid reporters
  ask turtles [
    hide-turtle ]
  reset-ticks
end

to go
  ask patches [
    Check-Neighbors
    Update-Color
  ]
  ifelse corners?  ;; sets up the yellow circle turtles to define the corners of the Grid reporters
  [ ask turtles [ show-turtle] ]
  [ ask turtles [ hide-turtle] ]
  ifelse ( ticks = 5000 )  ;; stops the model at 5000 ticks
  [ stop ]
  [ tick ]
  end

to distribute-ability
  if normal? [ set temp-ability ( random-normal normal-mean 1 ) ]
  if poisson? [ set temp-ability ( random-poisson poisson-mean ) ]
  if temp-ability < 0 [ set temp-ability 0 ]  ;; to ensure that patches couldn't have a precision value less than 0
  set ability ( ( round temp-ability ))  ;; rounds the distributed temp-ability to the nearest integer
end

to Check-Neighbors
  set neighbor-av neighbor-average
  ifelse Rounding?  ;; if Rounding? is on, than agents have a uniformlly distributed ability
    [ set Language precision my-average Rounding-Precision ]
    [ check-AFL ]  ;; if Rounding? is off, is Ability-for-Languages? on
end

to check-AFL
  ifelse Ability-for-Languages?
  [ set Language precision my-average ability ] ;; sets Language equal to the neighborhood ideal language averaged with the agents current language with a precision of the agent's ability
  [ set Language my-average ]  ;; if Rounding? and Ability-for-Languages? is off, then agents will perfectly (with precision of 17) adopt the local optimal language
end


to-report neighbor-average  ;; finds the mean language of moore neighbors, this is the optimal local language
  report ( sum [ Language ] of neighbors ) / ( count neighbors )
end

to-report my-average
  report ( neighbor-av + Language ) / 2  ;; this sets it up that the agent tries to find the mean of their current language and the ideal neighborhood lanugage
end

to Update-Color  ;;  this changes the color of the patches to their lanugage number, the rules to do with precision and slight shifts are to remove black and white from the color changes (to "smooth" out the transitions between colors)
  set pcolor precision Language 0  ;; to remove white from progression
  ifelse ( pcolor = 100 or pcolor = 90 or pcolor = 80 or pcolor = 70 or pcolor = 60 )  ;; to remove black from progression
    [ set pcolor ( pcolor + 2.5 ) ]
    [ set pcolor ( pcolor + 0 ) ]
  ifelse ( pcolor = 101 or pcolor = 91 or pcolor = 81 or pcolor = 71 or pcolor = 61 )  ;; to remove black from progression
    [ set pcolor ( pcolor + 2 ) ]
    [ set pcolor ( pcolor + 0 ) ]
  ifelse ( pcolor = 102 or pcolor = 92 or pcolor = 82 or pcolor = 72 or pcolor = 62 )  ;; to remove black from progression
    [ set pcolor ( pcolor + 1.5 ) ]
    [ set pcolor ( pcolor + 0 ) ]
  ifelse ( pcolor = 99 or pcolor = 89 or pcolor = 79 or pcolor = 69 or pcolor = 59 )  ;; to remove white from progression
    [ set pcolor ( pcolor - 1.5 ) ]
    [ set pcolor ( pcolor + 0 ) ]
  ifelse ( pcolor = 98 or pcolor = 88 or pcolor = 78 or pcolor = 68 or pcolor = 58 )  ;; to remove white from progression
    [ set pcolor ( pcolor - 1 ) ]
    [ set pcolor ( pcolor + 0 ) ]
end

to create-corners  ;; this sets up turtles that are circle and yellow on the corners of the Grid reporters, this is simply to help with visual reference (so when you look at a reporter for Grid 4, you know which patches are in that region)
  ask patch -20 40 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -10 40 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 0 40 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 10 40 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 20 40 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -20 30 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -10 30 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 0 30 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 10 30 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 20 30 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -20 20 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -10 20 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 0 20 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 10 20 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 20 20 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -20 10 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -10 10 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 0 10 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 10 10 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 20 10 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
   ask patch -20 0 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch -10 0 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 0 0 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 10 0 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
  ask patch 20 0 [
    sprout 1 [
      set color yellow
      set size 0.5
      set shape "circle"]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
313
10
854
552
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
-20
20
0
40
0
0
1
ticks
30.0

BUTTON
157
10
253
43
Go (Toggle)
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
70
10
155
43
Go (Step)
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
4
10
68
43
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

SLIDER
6
54
178
87
Initial-Percent-Green
Initial-Percent-Green
0
1
0.5
.1
1
NIL
HORIZONTAL

SWITCH
3
90
116
123
Rounding?
Rounding?
1
1
-1000

SLIDER
119
90
291
123
Rounding-Precision
Rounding-Precision
0
4
4.0
1
1
NIL
HORIZONTAL

SWITCH
3
127
183
160
Ability-for-Languages?
Ability-for-Languages?
0
1
-1000

SWITCH
0
171
103
204
normal?
normal?
0
1
-1000

SWITCH
-1
218
102
251
poisson?
poisson?
1
1
-1000

CHOOSER
106
163
244
208
normal-mean
normal-mean
1 2 3 4
1

CHOOSER
104
215
242
260
poisson-mean
poisson-mean
1 2 3 4
3

SWITCH
182
54
285
87
corners?
corners?
1
1
-1000

MONITOR
7
280
64
325
55-65
count patches with [(language < 65) and (language >= 55)]
1
1
11

MONITOR
247
217
307
262
Average
( sum [ Language ] of patches ) / ( count patches )
4
1
11

MONITOR
66
280
123
325
65-75
count patches with [(language < 75) and (language >= 65)]
1
1
11

MONITOR
124
280
181
325
75-85
count patches with [(language < 85) and (language >= 75)]
1
1
11

MONITOR
183
280
240
325
85-95
count patches with [(language < 95) and (language >= 85)]
1
1
11

MONITOR
242
280
299
325
95-105
count patches with [(language <= 105) and (language >= 95)]
1
1
11

MONITOR
7
352
64
397
Grid1
Mean ([language] of patches with [(pxcor > -20 and pxcor < -10) and (pycor < 40 and pycor > 30)])
4
1
11

MONITOR
66
353
123
398
Grid2
Mean ([language] of patches with [(pxcor > -10 and pxcor < 0) and (pycor < 40 and pycor > 30)])
4
1
11

MONITOR
125
353
182
398
Grid3
Mean ([language] of patches with [(pxcor > 0 and pxcor < 10) and (pycor < 40 and pycor > 30)])
4
1
11

MONITOR
184
353
241
398
Grid4
Mean ([language] of patches with [(pxcor > 10 and pxcor < 20) and (pycor < 40 and pycor > 30)])
4
1
11

MONITOR
6
400
63
445
Grid5
Mean ([language] of patches with [(pxcor > -20 and pxcor < -10) and (pycor < 30 and pycor > 20)])
4
1
11

MONITOR
65
400
122
445
Grid6
Mean ([language] of patches with [(pxcor > -10 and pxcor < 0) and (pycor < 30 and pycor > 20)])
4
1
11

MONITOR
124
400
181
445
Grid7
Mean ([language] of patches with [(pxcor > 0 and pxcor < 10) and (pycor < 30 and pycor > 20)])
4
1
11

MONITOR
183
400
240
445
Grid 8
Mean ([language] of patches with [(pxcor > 10 and pxcor < 20) and (pycor < 30 and pycor > 20)])
4
1
11

MONITOR
6
447
63
492
Grid9
Mean ([language] of patches with [(pxcor > -20 and pxcor < -10) and (pycor < 20 and pycor > 10)])
4
1
11

MONITOR
65
447
122
492
Grid10
Mean ([language] of patches with [(pxcor > -10 and pxcor < 0) and (pycor < 20 and pycor > 10)])
4
1
11

MONITOR
124
447
181
492
Grid11
Mean ([language] of patches with [(pxcor > 0 and pxcor < 10) and (pycor < 20 and pycor > 10)])
4
1
11

MONITOR
183
447
240
492
Grid12
Mean ([language] of patches with [(pxcor > 10 and pxcor < 20) and (pycor < 20 and pycor > 10)])
4
1
11

MONITOR
6
493
63
538
Grid13
Mean ([language] of patches with [(pxcor > -20 and pxcor < -10) and (pycor < 10 and pycor > 0)])
4
1
11

MONITOR
65
493
122
538
Grid14
Mean ([language] of patches with [(pxcor > -10 and pxcor < 0) and (pycor < 10 and pycor > 0)])
4
1
11

MONITOR
124
493
181
538
Grid15
Mean ([language] of patches with [(pxcor > 0 and pxcor < 10) and (pycor < 10 and pycor > 0)])
174
1
11

MONITOR
182
493
239
538
Grid16
Mean ([language] of patches with [(pxcor > 10 and pxcor < 20) and (pycor < 10 and pycor > 0)])
4
1
11

MONITOR
248
169
305
214
Patches
count patches
1
1
11

MONITOR
312
584
382
629
Ability = 0
count patches with [(ability = 0 )]
17
1
11

MONITOR
383
584
453
629
Ability = 1
count patches with [(ability = 1 )]
17
1
11

MONITOR
454
584
524
629
Ability = 2
count patches with [(ability = 2 )]
17
1
11

MONITOR
525
584
595
629
Ability = 3
count patches with [(ability = 3 )]
17
1
11

MONITOR
595
584
665
629
Ability = 4
count patches with [(ability = 4 )]
17
1
11

MONITOR
665
584
735
629
Ability = 5
count patches with [(ability = 5 )]
17
1
11

MONITOR
735
584
805
629
Ability = 6
count patches with [(ability = 6 )]
17
1
11

MONITOR
805
584
884
629
Ability >= 7
count patches with [(ability >= 7 )]
17
1
11

@#$#@#$#@
## WHAT IS IT?

This simple model is meant to simulate the creation of a blended language along the border of two language groups (such as along the border of the Danelaw and Anglo-Saxon England in the 900s CE).  The model allows for initial language population size adjustments and allows for agents to be assigned a language acquisition ability to model the creation of regional dialects of the blended language.

## HOW IT WORKS

On each tick, agents survery their neighbors (Moore) to determine what the average language spoken in their area is and they make moves to then adopt this ideal average language by taking adopting the average of local optimal and their current language.  This is meant to simulate an individual adopting the most commonly used words in their area in order to communicate most optimally with their neighbors.  If Ability-for-Languages is turned on, the agents will be able to accurately survey their neighbors but will be limited in how well they replicate the local language by their randomly assigned (either globally Poisson or normally distributed) Ability-for-Language.  This feature only allows the agents to adopt the local language with a certain degree of precision (a Netlogo precision of 0 only allows them to adopt the lanugage up to an integer, while a precision of 4 allows them to adopt the local language to 4 decimal places).  After the have adjusted their language to the mean of their current language and the optimal local language with as much precision as they are able, agents update their color (generally speaking agents of a similar color should have a similar language value, although exceptions occur due to adjustments to remove black from the model).

## HOW TO USE IT

To get an understanding for the basic rules of the precision feature in Netlogo, set Ability-for-Languages? off and set Rounding? on.  This will allow you to universally assign a precision value (language ability) for all agents.  You can also run the model with Rounding? and Ability-for-Lanugages? set to off in which case all agents are able to set themselves to the local language with a precision of 17.  Set Rounding? off and set Ability-for-Languages? on to begin to experiment with different distributions of language acquisition ability within the population.  You can select to have the population have Language Ability assigned via a normal or a Poisson distribution.  NOTE: It is important to have only the normal? or the Poisson? selectors on at a time; if both are selected to be on, the model will have a Poisson distribution alone. 

## THINGS TO NOTICE

The most interesting behavior occurs when you begin to distribute language ability based on normal or Poisson distributions.  Look at the Grid reporters to see local averages across the space (TIP: if you set corners? to on, you will create yellow, circle turtles which will mark out the corners of the grids).  The grid reporters are laid out in the same pattern as the grids, so for instance Grid 1 is the upper-most left square and grid 16 is the square on the lower-most, right position.

## THINGS TO TRY

Run the model with a normal and Poisson distributions with means of 2, 3 and 4.  Notice how Grid reporters reflect pockets of different colored local dialects.

## EXTENDING THE MODEL

It would be very interesting to build geospatial elements into this model.  The inclusion of difficult to cross mountains, rivers, etc would likely greatly enhance the model's dialect creation ability.  It would also be interesting to add agent networks that would play into agent language adoption beyond just the Moore neighborhood.

## NETLOGO FEATURES

Agent language ability is linked to the Netlogo feature of precision, whereby a precision value of 4 limits a number to only 4 decimal places of precision (thus a precision of 0 drops everything after the decimal and reduces a number to an integer).  Due to the layout of the Netlogo color swatches, the patches' color does not always exactly equal it's language value.  The Netlogo color swatches include black and white in the spectrum which made it difficult to track language progression.  Thus when a patch's languge value would result in a color change to black or white, the color is shifted slightly to remain more in the blue-green spectrum (thus it is sometimes possible to see patches that have the same color but a different language value).  Generally speaking, that will only occur when the patches are seperated by interveneing color transitions.


## RELATED MODELS

Language Change model (Netlogo Models Library, under the Social Science heading): This model looks ate language change based on Networks.  It would be interesting to incorportate this network structure into a model like this.

Rumor Mill model (Netlogo Models Library, under the Social Science heading):  This model is somewhat similar in that a rumor is spread throughout a community based on neighbors.  In many ways, our language model acts similarly whereby language changes spread from the border zone outward (generally speaking the closer you are to the intial border, the more your language will have a changed over the model run).
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

square2
false
0
Rectangle -7500403 true true 30 30 270 270

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
