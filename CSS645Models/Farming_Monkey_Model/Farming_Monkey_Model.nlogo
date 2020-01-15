;; Monkeys and farmers are both breeds of turtle
;; Patch variables:
;; plotAge counts age of farm and fallowed plots
;; Fallow - after a patch becomes a farm it begins to age. Patches become fallow between five and ten years.
;; Regrowth - after land becomes fallow the forest begins to regrow.
;; land-cover-types for patches are 1 for forest, 2 for farm, 3 for dead/regrow

globals
[
  nearbyfarmer
  nearbymonkeys
]

patches-own
[
  fruittree
  fruitcount   ;; amount of fruit (energy) available per red fruit patch
  newland-countdown
  land-cover-type
  threat-level
  safe-area
]

breed [ monkeys monkey ]
breed [ farmers farmer ]

monkeys-own
[
  energy
  home-base
  day-length
  age
  sex
  babies-inlifetime
  babies
  monkeyleader
]

farmers-own
[ radius ]

;;;;;;;;;;;;;;;;;;;;;;
;; SETUP PROCEDURES ;;
;;;;;;;;;;;;;;;;;;;;;;

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches [
    set pcolor green
    set land-cover-type 1 ]
  initialize-fruit
  initialize-monkeys
  initialize-farmers
end

to initialize-fruit
  ask patches
  [
    if ( random 100 < 5 )
    [
      set pcolor magenta                 ;;red patches denote fruit bearing trees
      set fruitcount random 50           ;;create tree patches with fruit bearing trees
      set fruittree 8
    ]
  ]
end

;; This initializes the farmers on the bottom of the habitat area.  In this theoretical habitat
;; there is a road on the southern edge of the frame where the farmers begin their subsistence farming.

to initialize-farmers
  set-default-shape farmers "person"
  set nearbyfarmer moore-offsets edge-effect
  ask n-of initial-number-farmers patches with [ ( pycor = min-pycor ) ] [ sprout-farmers 1
    [
  ask patches at-points nearbyfarmer
  [
    set threat-level 1
  ]
    ]
  ]
  ask farmers
  [
  set color red
  if ( pcolor = green ) or ( pcolor = magenta )
  [
    set pcolor yellow
    set newland-countdown one-of [ 2 3 4 ]
    set land-cover-type 2
    move-to patch-here
    set radius neighbors
  ]

  ]
end

;; The follow code is an alternative initialization of the farmers.  This code sprouts the farmers
;; to the left and right sides of the habitat area. To use remove all ;; from the below section and
;; and add ;; to all lines in the above section.

;;to initialize-farmers
;;  set-default-shape farmers "person"
;;  set nearbyfarmer moore-offsets edge-effect
;;  ask n-of ( initial-number-farmers / 2) patches with [ (pxcor = max-pxcor ) ] [ sprout-farmers 1
;;    [
;;      ask patches at-points nearbyfarmer
;;      [
;;        set threat-level 1
;;      ]
;;    ]
;;  ]
;;  ask n-of (initial-number-farmers / 2 ) patches with [ (pxcor = min-pxcor )] [ sprout-farmers 1
;;    [
;;
;;  ask patches at-points nearbyfarmer
;;  [
;;    set threat-level 1
;;  ]
;;    ]
;;  ]
;;  ask farmers
;;  [
;;  set color red
;;  if ( pcolor = green ) or ( pcolor = magenta )
;;  [
;;    set pcolor yellow
;;    set newland-countdown one-of [ 2 3 4 ]
;;    set land-cover-type 2
;;    move-to patch-here
;;    set radius neighbors
;;  ]
;;  ]
;;end

;; This creates the Moore radius threat level for the edge effects.  It is implemented by the farming
;; agents.  Each time the agent moves the threat level of the neighborhood patches in the chosen radius
;; are given a threat level of 1.

to-report moore-offsets [ n ]
  let result [list pxcor pycor] of patches with [abs pxcor <= n and abs pycor <= n]
  report result
end


to-report moore-offsets2 [ n ]
  let result [list pxcor pycor] of patches with [abs pxcor <= n and abs pycor <= n]
  report result
end


;; The monkeys also use the Moore offset to check for their safety.

to initialize-monkeys
  set-default-shape monkeys "default"
  set nearbymonkeys moore-offsets2 edge-effect
  ask one-of patches with [ pxcor = random-pxcor and ( pycor > ( min-pycor + 5 ) ) ]  [ sprout-monkeys initial-number-monkeys ;;create monkeys
  [
    ask patches at-points nearbymonkeys
    [
      set safe-area 5
    ]
  ]
  ]

  ask monkeys
  [
    set color sky
    set size 1
    set energy random 10
    set age random 10
    set day-length 2    ;; The day-length refers to a day-night cycle : If the monkey is hungry
                        ;; it goes out to forage during the day.  At night all monkeys return home.
                        ;; This is just to simulate how monkeys forage during the day and return home
                        ;; at night.
    ;;set sex one-of [ 0 1 ]
    let population initial-number-monkeys
    let female who <= ( ( population / 3 ) * 2 )   ;; average ratio of female to male is 2 to 1
    if female [
       set sex 1
       ;;set time-btwn-birth random 5 ;; time between births is average 3- 4 years
       set babies-inlifetime one-of [ 3 4 ]   ;; average female monkey birth to 3 - 4 monkeys in her life
       set babies 0

       ]
    set home-base patch-here   ;; Where the monkeys are sprouted is their home tree (patch) area.
  ]
end




;;;;;;;;;;;;;;;;;;;
;; GO PROCEDURES ;;
;;;;;;;;;;;;;;;;;;;

to go
  if not any? patches with [ pcolor = green ] [ stop ]
  let sim-stop all? farmers [ pycor = max-pycor ]
  if sim-stop [ stop ]
  if not any? monkeys [ stop ]

  if not any? patches with [ pcolor = magenta and threat-level = 0 ]
     [ ask monkeys [ return-home ]
       stop ]


  ask monkeys
  [
    set energy energy - 1
    set day-length day-length - 1
    set age age + .5
    find-fruit
    eat-fruit
    return-home
    reproduce
    predation
    check-leader
    natural-death
    resource-death
    wiggle
  ]

  ask farmers
  [
    if pycor = max-pycor [ stop ]
    set-threat-level
    time-to-move
  ]

  ask patches
  [
    still-fruit
    check-if-newlandneeded

  ]
  update-plot1
  update-plot2
  tick
end

;;;;;;;;;;;;;;;;;;;;
;; MONKEY ACTIONS ;;
;;;;;;;;;;;;;;;;;;;;

;; Spider monkeys are lead by a female monkey.  If the leader dies a new one takes its place.
;; Some research indicates that the female monkeys lead the monkeys.

to check-leader
  if sex = 1
  [
    if not any? monkeys with [ monkeyleader = 1 ]
     [
       ask one-of monkeys [ set monkeyleader 1 ]
     ]
  ]
end

;; Like humans, monkeys need to eat daily. So all monkeys forage.
to find-fruit
  if not any? patches with [ pcolor = magenta and threat-level = 0 ]
  [ stop ]

  set energy energy - 1  ;; moving takes energy.
  if any? patches with [ ( pcolor = magenta ) and ( fruitcount > 0 ) ]
   [
    ifelse not any? patches with [ ( pcolor = magenta ) and ( threat-level = 0 ) ]
    [stop ]
    [ move-to one-of patches with [ pcolor = magenta and threat-level = 0 ] ]  ;; got one error

   ]

  move-to patch-here

end

to eat-fruit
  if fruitcount > 0
   [
    set energy energy + random 20
    set fruitcount fruitcount - 1
   ]
end

;; Monkeys return home each night to sleep.
to return-home
  home-safe

  if ( day-length <= 0 ) or ( not any? patches with [ pcolor = magenta ] )
  [
    move-to home-base
    set day-length day-length + 2
    set energy energy - 1  ;; moving takes energy.
  ]
end

;; The spider monkey leader is always female.  If she feels the home tree is no longer safe
;; the leader monkey finds a new tree and the other monkeys follow her.  They create a new home tree.
to home-safe
 if monkeyleader = 1 and day-length <= 0
  [
    move-to home-base
    if not any? patches with [ threat-level = 0 ]
    [
      die
      ask other monkeys [ die ]
    ]
    if any? neighbors with [ threat-level = 1 ]
    [
    move-to one-of patches with [ threat-level = 0 ]
    set home-base patch-here
    let newhome-base patch-here
    set nearbymonkeys moore-offsets2 edge-effect
    ask patches at-points nearbymonkeys
    [ set safe-area 5 ]
    ask other monkeys [ set home-base newhome-base ]
    ]
 ]
end

;; Unlike other models in the NetLogo library. Population is split into male and female.
;; Only the females give birth and lose energy.  Females are a limiting factor of the populations growth.
;; Females are a limiting resource as they put a large investment of energy into reproduction.
;; Less females means less population growth. No females leads to population death.

to reproduce
  if sex = 1 and age > 5
  [
    if babies < babies-inlifetime
    [
      set energy (energy / 2 )
      set babies babies + 1
      hatch-monkeys 1 [
        set sex one-of [ 0 1 ]
        set age 0
        set babies 0
        set monkeyleader 0
      ]
    ]
  ]
end

to predation
  if random-float 100 < predation-rate [ die ]   ;; Spider Monkey natural predators are jaguars and pumas. Predation is rare.
end

;; The natural population of the monkeys fluctuates with the carrying capacities.  Monkeys die of
;; old age.  Death from carrying capacity is either caused by over population or a monkey has moved
;; to join a new monkey group not in the simulation.

to natural-death
  if energy < 0 [ die ]
  if age > 25 [ die ]  ;; average life expectancy of spider monkey is 20 - 30 years
  let num-monkeys count monkeys
  if num-monkeys <= initial-number-monkeys [ stop ]
  let chance-to-die (num-monkeys - initial-number-monkeys ) / num-monkeys
  ask monkeys
  [ if random-float 1.0 < chance-to-die [ die ]]

end


;; As the monkey's habitat shrinks the carrying capacity of the land decreases and the monkey
;; population size begins to decrease.  Eventually there is not enough land for the monkeys and
;; they die.

to habitat-death


  let landarea count patches
  let farmfallow count patches with [ pcolor = black or pcolor = yellow ]
  let forested count patches with [ pcolor = green or pcolor = magenta ]
  let num-monkeys count monkeys
  if forested > farmfallow
  [ stop ]
  if forested <= ( landarea * .5 )
  [
    let carrying-capacity.5 ( initial-number-monkeys * .75 )
    let chance-to-die (num-monkeys - carrying-capacity.5 ) / num-monkeys
    ask monkeys
    [ if random-float 5 < chance-to-die [ die] ]
  ]

  if forested <= ( landarea * .25 )
  [
    let carrying-capacity.25 ( initial-number-monkeys * .5 )
    let chance-to-die.25 ( num-monkeys - carrying-capacity.25 ) / num-monkeys
    ask monkeys
    [ if random-float 2 < chance-to-die.25 [ die ] ]
  ]
  if forested <= ( landarea * .125 )
  [
    let carrying-capacity.125 ( initial-number-monkeys * .25 )
    let chance-to-die.125 (num-monkeys - carrying-capacity.125 ) / num-monkeys
    ask monkeys
    [ if random-float 1 < chance-to-die.125 [ die] ]
  ]
end

to resource-death
  let num-monkeys count monkeys
  let fruit-trees count patches with [ fruittree = 8 ]
  let remaining-fruit-trees count patches with [ pcolor = magenta and threat-level = 0 ]
  if remaining-fruit-trees <= ( fruit-trees * .5 )
  [
    let resource-capacity ( initial-number-monkeys * .75 )
    let chance-to-die ( num-monkeys - resource-capacity ) / num-monkeys
    ask monkeys
    [ if random-float 2 < chance-to-die [ die ] ]
  ]
end


to wiggle
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end

;;;;;;;;;;;;;;;;;;;;;;
;; FARMER MOVEMENTS ;;
;;;;;;;;;;;;;;;;;;;;;;

to time-to-move
  if newland-countdown <= 0
  [ check-radius ]
end

;; This action tries to prevent the farmers from moving forward into the land.  The farmer must first select
;; the land immediately around him before he can move forward into the forest.
to check-radius
  if not any? patches with [ pcolor = green ] [ stop ]

  if any? radius with [ pcolor = green ]
  [ find-new-land ]

  if not any? radius with [ pcolor = green ]
  [
    if newland-countdown <= 0
    [
      face one-of neighbors
      forward 1
      move-to patch-here
      check-if-forest
      check-radius
      ]
    ]
end

;; The farmers is only to cut down forest.  If he ends up in a field he has to look again for forest.
to check-if-forest
  if pcolor = green or pcolor = magenta
  [
    ifelse pcolor = black or pcolor = yellow
    [
      check-radius
    ]
    [
    move-to patch-here
    set radius neighbors
    set pcolor yellow
    set newland-countdown one-of [ 2 3 4 ]

    ]
  ]
end

;; Once all the farm land in their area is farmed the farmer moves on to new land.
to find-new-land
    if not any? patches with [ pcolor = green ][stop]

    if newland-countdown <= 0
    [
    if any? radius with [ pcolor = green ]
    [
     move-to one-of radius with [ pcolor = green ]

       if any? other farmers-here
        [ find-new-land ]

       if pcolor = black
        [ find-new-land ]

       move-to patch-here

       if ( pcolor = green ) or ( pcolor = magenta )
       [
         move-to patch-here
         set pcolor yellow
         set newland-countdown one-of [ 2 3 4 ]
       ]
    ]]

   if not any? radius with [ pcolor = green ]
    [
    if newland-countdown <= 0
     [ check-radius ]
    ]
end

;; This action set the threat level of the patches around the farm.  This is the edge effect.
;; The monkeys do not want to be near the forest edge so they no longer forage in these areas.
to set-threat-level
  set nearbyfarmer moore-offsets edge-effect
  ask farmers
  [
    ask patches at-points nearbyfarmer
    [ set threat-level 1 ]
  ]

end

;;;;;;;;;;;;;;;;;;;
;; PATCH ACTIONS ;;
;;;;;;;;;;;;;;;;;;;


to still-fruit
  if pcolor = magenta and fruitcount <= 0
  [
    set fruitcount random 50
  ]

end

to check-if-newlandneeded
  if pcolor = yellow
  [
    if newland-countdown > 0
    [ set newland-countdown newland-countdown - 1 ]

  if newland-countdown <= 0
    [
      set pcolor black
      set land-cover-type 3     ;; Land cover type 3 is deforested fallow land.

    ]
  ]
end

;;;;;;;;;;;;;;;;;
;; UPDATE PLOT ;;
;;;;;;;;;;;;;;;;;

to update-plot1
  let forest count patches with [ pcolor = green or pcolor = magenta ]
  set forest count patches with [ pcolor = green or pcolor = magenta ]
  let fruit count patches with [ pcolor = magenta and threat-level != 1 ]
  set fruit count patches with [ pcolor = magenta and threat-level != 1 ]
  set-current-plot "Population"
  set-current-plot-pen "monkeys"
  plot count monkeys
  set-current-plot-pen "forest"
  plot forest / 16 ;; divide by six to keep it within similar range as monkey population
  set-current-plot-pen "fruit"
  plot fruit
end

to update-plot2
  let female count monkeys with [ sex = 1 ]
  let male count monkeys with [ sex = 0 ]
  set female count monkeys with [ sex = 1 ]
  set male count monkeys with [ sex = 0 ]
  set-current-plot "Sex"
  set-current-plot-pen "female"
  plot female
  set-current-plot-pen "male"
  plot male
end

;; References:  Some of the procedures used above are modified from pre-exhisting models found in the NetLogo
;; Library.  The models used to develop ideas are:  Wolf Sheep Predation, Simple Birth Rates, Rabbits Grass Weeds
;; and Fire model.  The code examples examined for ideas were: Neighborhoods Example, Move Towards Target Example
;; Lattice-Walking Turtles Example, Hatch Example.  (Wilensky, 1997)
;; Wilensky, U., 1997. NetLogo Wolf Sheep Predation model.
;; http://ccl.northwestern.edu/netlogo/models/WolfSheepPredation.
;; Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
GRAPHICS-WINDOW
334
12
752
411
-1
-1
10.0
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
-19
19
0
0
1
ticks
30.0

BUTTON
6
10
73
43
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

SLIDER
7
56
156
89
initial-number-monkeys
initial-number-monkeys
30
50
50.0
10
1
NIL
HORIZONTAL

BUTTON
82
11
145
44
step
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
161
10
251
43
go forever
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

MONITOR
258
294
321
339
#monkeys
count monkeys
17
1
11

MONITOR
259
391
323
436
Male
count monkeys with [ sex = 0 ]
17
1
11

MONITOR
259
342
322
387
Female
count monkeys with [ sex = 1 ]
17
1
11

SLIDER
6
97
157
130
predation-rate
predation-rate
0
2
0.0
1
1
%
HORIZONTAL

SLIDER
165
96
317
129
edge-effect
edge-effect
1
10
10.0
1
1
NIL
HORIZONTAL

SLIDER
165
56
317
89
initial-number-farmers
initial-number-farmers
10
20
10.0
5
1
NIL
HORIZONTAL

MONITOR
255
185
318
230
%Forest
count patches with [ pcolor = green or pcolor = red ] / count patches * 100
3
1
11

PLOT
6
134
249
284
Population
time
pop
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"monkeys" 1.0 0 -13791810 true "" ""
"forest" 1.0 0 -10899396 true "" ""
"fruit" 1.0 0 -5825686 true "" ""

PLOT
6
292
249
442
Sex
time
pop
0.0
100.0
0.0
30.0
true
true
"" ""
PENS
"female" 1.0 0 -2064490 true "" ""
"male" 1.0 0 -13345367 true "" ""

MONITOR
255
136
318
181
%Cut
count patches with [ pcolor = black ] / count patches * 100
3
1
11

MONITOR
255
236
320
281
Fruit Trees
count patches with [ pcolor = magenta and threat-level = 0 ]
17
1
11

@#$#@#$#@
## WHAT IS IT?

Model of deforestation caused by subsistence farming and the creation of edge effects and its impact on a population of spider monkeys

## HOW IT WORKS

Farmers move when their farm becomes fallow or they need more land to support their family.  Monkeys forage daily and return to their home tree.  When the monkeys are threatened by the encroaching forest edge they move further into the forest.

## THINGS TO NOTICE

When the home tree location is no longer safe the monkeys retreat into the forest and establish a new home tree location.

## EXTENDING THE MODEL

One change that can be put into effect is the initiation of the farmer agents.  The traditional model initializes the farmers at the bottom of the screen.  An alternative method initiates the farmers to the right and left of the screen.

## CREDITS AND REFERENCES

The written procedural codes in the model are a combination of borrowed and modified pre-existing procedures and procedures developed by the author.  The calculations and procedures that were modified from pre-existing agent-based models to suit the needs of this model were found for free in the NetLogo library (Wilensky, 1997).  The calculation for predation was modified from the Wolf Sheep Predation model (Wilensky, 1997).  Pieces of the natural death and habitat death calculation/procedure were modified from the Simple Birth Rate model (Wilensky, 1997).  Other procedures were written as a mash up of individual procedures found in NetLogo as well as added pieces that were developed by the author.
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
