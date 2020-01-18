;;
;; Model to examine certain questions about relative rates of damage
;; suffered by each side in the Battle of Tours (732), which pitted
;; Moorish cavalry against Frankish infantry
;;
;;

breed [Moor person] ;;  the Moors
Moor-own [
  target  ;;Moors are cavalry, and have a place they are attacking (randomly chosen for each assault)
  speed  ;; Moors also have a speed they move at (randomly chosen for each assault)
  ]

patches-own [health] ;;Since the Franks were described in the battle as "standing like a wall of ice", the
;; Franks are represented by fixed spaces
;; health is a representation of the number of times each patch can be assaulted before it "dies"

globals [
  Rally-Target-1  ;; One of three places Moors go, prior to commencing assault.  This represents left flank, right flank, and center
 wall-height ;; Reprsents how far from the top of the screen the Franks extend.  This determines where the three points of Rally-Target-1 are located.
 wall ;; used to determine the composition of the Franks formation
 Ice  ;; Number of patches that are currently colored white
 Init-Moors ;; Beginning number of Moors; used to report the Casualties as a percentage
 Init-Ice  ;; Beginning number of Franks; used to report the Casualties as a percentage
 Franks  ;; Used to show the relative strength of Franks to the Moors; it equals Ice x 5, so each Patch represents 5 Franks
  ]

turtles-own [energy]       ;; Moors have energy to move.  When they run out of energy, they die.


to setup  ;; clear variables, get get ready for program execution
  clear-all
    set-default-shape moor "default" ;; Moors are represented by arrows, which provide a good visual of direction
  reset-ticks
patch-setup

set Init-Moors number-moors ;; Slider value.  Slider steps by 25, up to maximum of 2500
create-moor Init-Moors [
  setxy random-xcor min-pycor ;; Moors assigned to random x location, along the bottom of screen

set size 1.25 ;; not too big, not too small
set energy 6 ;; shows the number of assaults they can make on the Franks
set color 5 + 10 * energy ;; Color varies with health from Green down to Brown
ask moor [ Sortie ] ;; This provides an initial assault rally target (Rall-Target-1), and an initial speed
]


end


to go
set Ice count patches with [pcolor = white]  ;; See how many Franks there are, and update this information at each Tick.

while [ ticks <= 1000 ] [   ;; stop running when 10 simulated hours have elapsed

     ask moor [Rally-Point-1 ] ;; Send Moors to a specific spot on the left flank, right flank, or center of the Franks' lines
ask moor [ Combat ]  ;; If Moors are in a spot where they can fight, they will fight
ask moor [Rally]  ;; after Moors have fought, regroup, and go again

tick
]
end


to patch-setup  ;; this code only runs at initial set up
set wall-height Infantry-Line ;; wall-height is used to determine how big the patch of ice (Franks will be); it is also where the Moors will rally, prior to attacking
set Franks Infantry-line ^ 2 ;; Franks is the total number of Franks in a solid square, where each side is Infantry-Line long

if wall-shape = "Solid" [  ;; This is a solid square
set wall patches with [
  (pxcor <= wall-height / 2 ) and ( pxcor >= 0 - wall-height / 2 ) ;; Puts half the Ice (Franks) on each side of 0 i.e., it centers the wall in the screen
  and  pycor >= ( max-pycor - wall-height) ;;bottom limit of the wall
]
]

if wall-shape = "Hollow" [ ;; This is Franks 1 patch deep
  set wall-height ceiling ( Franks / 3 ) ;; since they are 1 deep, equal numbers on all three sides
  set wall patches with [
  (pxcor = ceiling ( wall-height / 2 ) ) and pycor >= ( max-pycor - wall-height)  ;; Puts a line of Ice (Franks) on the far right side of 0
  or
  ( pxcor = 0 - ceiling ( wall-height / 2 ) )  and  pycor >= ( max-pycor - wall-height)  ;; Puts a line of Ice (Franks) on the far left side of 0
  or
  ( (pxcor <= ceiling (wall-height / 2 ) ) and ( pxcor >= 0 - ceiling (wall-height / 2 ) ) ;; puts a horizontal line of Ice (Franks)  on each side of 0
  and  pycor = ( max-pycor - wall-height) )  ;; Establishes y coordinate for location of horizontal line of Franks

  ]
]

if wall-shape = "Thick" [ ;; Thick formation, where the Franks are 2 patches deep
  set wall-height ceiling ( Franks / 5 )  ;;Similar to Hollow structure, but not extending so far
  set wall patches with [
  (pxcor = ceiling ( wall-height / 2 ) ) and pycor >= ( max-pycor - wall-height)  ;; Puts a line of Ice (Franks) on the far right side of 0
  or
    (pxcor = ceiling ( wall-height / 2 ) - 1 ) and pycor >= ( max-pycor - wall-height) ;; Puts a second line of Ice (Franks) behind the first one
  or

  ( pxcor = 0 - ceiling ( wall-height / 2 ) )  and  pycor >= ( max-pycor - wall-height)
  or   ;; puts a double line of Ice (Franks) on the far left side of 0
  ( pxcor = 1 - ceiling ( wall-height / 2 ) )  and  pycor >= ( max-pycor - wall-height)

  or
  ( (pxcor <= ceiling (wall-height / 2 ) ) and ( pxcor >= 0 - ceiling (wall-height / 2 ) )
  and  pycor = ( max-pycor - wall-height) )
  or  ;; Puts 2 horizontal lines of Ice (Franks) on each side of 0
    ( (pxcor <= ceiling (wall-height / 2 ) ) and ( pxcor >= 0 - ceiling (wall-height / 2 ) )
  and  pycor = 1 + ( max-pycor - wall-height) )

  ]
]

ask wall [set pcolor white ]       ;; now that the wall is laid out, make it visible (white)
set Init-Ice count patches with [pcolor = white]  ;; Get the initial value of Franks, which helps with reporting the percentage of Casualties
set Ice count patches with [pcolor = white]  ;; Reports currrent number of Franks, including at startup
ask patches [ set health 60 ]  ;; Measure of how much damage the Franks can take
end



to Rally-Point-1 ;; rally here before beginning attack

  if (heading = 270 and xcor <= min-pxcor + 1) or (heading = 90 and xcor >= max-pxcor - 1) [ set heading 0 ] ;; Moors have gone Left or Right, are at
                           ;; bottom of screen, and have reached the lane to turn North, so turn them North i.e., heading 0

  if ( target = 1 ) and ( pycor >= max-pycor - (wall-height / 2 ) ) ;; They are on the left flank, and have reached their Rally point
  [ attack-left-flank ] ;; in position to attack, so --- attack!

  if (target = 3 ) and ( pycor >= max-pycor - (wall-height / 2 ) )  ;; they are on the Right flank, and have reached their Rally point
  [ attack-right-flank ] ;; in position to attack, so --- attack!

if (target = 2 ) and (pycor = ceiling (min-pycor + (max-pycor - ( wall-height / 2)  )) ) and (heading < 180)
                    ;; Their target is the Front, and they are half-way to the wall, and they are not returning from an attack
[
set heading 30 - (random-float 60 ) ; head toward a target mostly ahead of Moor (may end up on flanks, too)
]

  movement ;; Moors have a heading, so now time to move

end


to Sortie

set speed random-float 1.0 ;; assign a random speed to each Moor
set Rally-Target-1 random-float 3 ;; Assign a random Rally point:  Left flank, center, or Right Flank

if Rally-Target-1 <= 1 [ ;; Left flank, so go Left
  set target 1
  set heading 270
  ]

if Rally-Target-1 > 1 and Rally-Target-1 < 2 ;; Center is target, so go north
[
  set target 2
  set heading 0
  ]

if Rally-Target-1  >= 2 ;; Right flank is target, so go Right
[
  set target 3
  set heading 90
  ]

end


to movement
   fd speed
   if speed < 0.5 [  ;; was having problems with stragglers, so slowest needs to be faster
     set speed  0.5 ] ;; this sets the slowest movement to 1/2 of fastest
end


to attack-left-flank ;; this only takes effect when a Moor reaches the rally point
 if heading = 0 [ ;; This would only work with a Conditional
set heading 45 + random-float 80  ;; head for a random spot, somewhere in the 80-degree arc on the center of this side of wall
  ]

end

to attack-right-flank ;; This only takes effect when a Moor reaches the rally point
if heading = 0 [ ;; This Procedure requires a conditional
;   set heading 225 + wall-height * 1.5 + (random-float 90) ;; head for a random spot, somewhere in the 90-degree arc on the center of this side of wall
set heading 235 + random-float 80
]
end

;;No Need for an "attack-center", as there is no specific rally point needed for that, and it would be unneccessarily complicated

to Combat ;; relates to each a Moor (turtle) in turn
if pcolor = white ;; i.e. the Moor has reached the Wall (Frankish lines)
[
  set health health - speed  ;; reduce health of ice by speed of the Moor
  if health <= 0 [ set pcolor blue] ;; if ice has no more health, it's dead/melted
 if heading != 180 [ forward -2 ];; Moor needs to get out of combat, so jump backwards 2 spaces.  Those inside the Wall just continue foward.
  set heading 180 ;; Head to reconstitute and re-attack point
  set energy energy - 1 ;; Attacking incurs damage to Moor
 ]

  if pycor = max-pycor [ set heading 180 set energy energy - .5 ]  ;; Moor missed the Ice, and ended up at top of screen.
  ;; Return to beginning point, and try again, with loss of some energy (1/2 of what would be used in an attack)

  if pxcor = max-pxcor [ fd -2 set heading 180 set energy energy - .5 ]  ;; Moor missed the Ice, and ended on extreme left or right edge of screen
  if pxcor = min-pxcor [ fd -2 set heading 180 set energy energy - .5 ] ;; so jump away from the edge, and
  ;; Return to beginning point, and try again, with loss of some energy (1/2 of what would be used in an attack)

 if energy <= 0 [die] ;; Been hit by too many Franks

 set color 5 + 10 * energy ;; Color varies with health from Green down to Brown

end

to rally
  if heading = 180 and pycor = min-pycor + 3 ;; Moors have returned from fight, and are 3 patches from bottom
  [
    set xcor 1 ;; jump to near center
    set ycor min-pycor ;; jump 3 patches to bottom of screen
    sortie ;; get a new target, and re-attack
  ]
if heading = 180 and pycor = min-pycor ;; Moor return from fight, but did not land eactly on 3rd patch from bottom--ended up at bottom of screen
[
  set xcor 1 ;; already at bottom of screen, so no need to move there
  sortie ;; get a new target, and re-attack
]

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
806
607
-1
-1
12.0
1
10
1
1
1
0
0
0
1
-24
24
-24
24
0
0
1
ticks
30.0

BUTTON
139
69
202
102
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
26
68
90
101
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

SLIDER
17
147
189
180
Number-Moors
Number-Moors
25
2500
1200.0
25
1
NIL
HORIZONTAL

MONITOR
23
523
102
568
Moors
Count Moor
17
1
11

CHOOSER
48
227
187
272
Wall-Shape
Wall-Shape
"Solid" "Hollow" "Thick"
2

SLIDER
14
186
187
219
Infantry-Line
Infantry-Line
1
15
10.0
1
1
NIL
HORIZONTAL

MONITOR
121
515
178
560
Franks
Ice * 5
17
1
11

MONITOR
18
318
147
363
Moor Casualty %age
100 * ( 1 - ((Count Moor) / Init-Moors  ))
2
1
11

MONITOR
51
389
184
434
Frank Casualty %age
100 * ( 1 - (Ice / Init-Ice ) )
2
1
11

@#$#@#$#@
## WHAT IS IT?

This model is a re-creation of part of the Battle of Tours (732).  It models three different likely Frankish (infantry) formations, and the relative casualties each side (Moors, Franks) would take, depending on their starting numbers.

## HOW IT WORKS

This model works by simulating a number of cavalry charges by the Moors, against a fixed, stationary line of Frankish infantry.  The Observer can control the number of Moors, the number of Franks, and has a choice of three Frankish formations.
Primary results are the number of active Franks and Moors, and the casualties suffered by each side, expressed as a percentage of their starting values.
This model runs for 1001 Ticks, which represents 10 hours, about the length of time the actual Battle of Tours would have been fought before withdrawal-->retreat-->panic at the end.

## HOW TO USE IT

Use the Sliders to determine the Number of Moors and the Number of Franks.
The slider for Number-Moors generates a value that is multiplied by 25 to get the full number of Moors that participate in the model.
The Infantry-Line slider determines how many Franks are on each side of their formation; the total number of Franks will vary slightly for each formation at the same number for Infantry-Line.

## THINGS TO NOTICE

How different formations yield different casualty results for the same numbers of troops on each side.
Notice the changing colors of the Moors, from Green down to Brown.  Color is a reflection of health.

## THINGS TO TRY

Adjust the relative numbers of troops on each side; play with different infantry formations.

## EXTENDING THE MODEL

Add terrain features
Develop a way for the Franks to act independently, including closing their line when breached


## NETLOGO FEATURES

Although it is possible for 2 breeds of turtles for both sides, this model works by using patches to represent one side of the battle and turtles (arrows) for the other

## RELATED MODELS

No NetLogo Models in the Libary are directly related to this one, but the Wolves/Sheep Predation model helped inform the relationship between patch color and turtles' activity.
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
