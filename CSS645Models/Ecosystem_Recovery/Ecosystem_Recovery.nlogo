breed [predators predator]  ;; These three breeds represent the three species replicatied in the tri-trophic cascade
breed [prey a_prey]         ;; currently being studied in Yellowstone National Park
breed [willows willow]


globals [
  sex                 ;;Represented by either a 0 for female or 1 for male
  week                ;;One tick in the simulation
  year                ;;Consists of 52 ticks or weeks
  wolf_reprod_rate
  elk_reprod_rate
  calf_mortality_rate   ;; Reproduciton rates and mortality rates established from National Parks Service data
  pup_mortality_rate
  litter_size
  pop_pred
  pop_prey
  pop_willows
  pups
  calves
  saplings
  starve_pred
  old_age_pred_death
  starve_prey
  old_age_prey_death
  eaten_willow
  predation
  ]

patches-own [
  landcover    ;;Not utilized
  water    ;;Not utilized
  biomass
  overgrazed
  ]

turtles-own [
  herdmates  ;;Used to establish herd using the Boids algorithm.
  nearest-herd  ;;Used to establish herd using the Boids algorithm.
  pack ;;Not utilized
  health  ;;overall determinate of animal fitness
  energy  ;;measure of the animal or plant's ability to continue living
  age
  max_age
  hunger     ;;Not utilized
  ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Set Up Model ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  reset-ticks

  set week 0
  set year 0
  set wolf_reprod_rate  PredatorReproduction  ;;based on user inputed values from empirical data
  set elk_reprod_rate  PreyReproduction
  set calf_mortality_rate  CalfMortality
  set pup_mortality_rate  WhelpMortality



  ask patches [
    set pcolor green
    set biomass round(random-normal 85 10)
    set overgrazed 0


    ]

 create-predators number-of-predators [  ;;establihsed the number and energy level of the predator breed
   setxy  -10  -10
   set color black
   set shape "wolf"
   set energy round(random-normal 85 10)
   set age random 3
   set max_age round(random-normal 7 1)
   set health 100
   set sex random 1
   set hunger 0
   set heading 225
 ]

  create-prey number-of-prey [  ;;establihsed the number and energy level of the prey breed
   setxy -20 -20
   set color white
   set shape "sheep"
   set energy round(random-normal 85 10)
   set age random 3
   set max_age round(random-normal 11 1)
   set health 100
   set sex random 1
   set heading 45
 ]

  create-willows willow-stands [ ;;establihsed the number and energy level of the willows breed
   setxy random-xcor random-ycor
   set color brown
   set shape "plant"
   set energy round(random-normal 85 10)
   set age round(random-normal 8 4)
   set max_age 100
   set health 100
  ]



end








;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Run Model ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
if not any? turtles [stop]
if year = 15 [stop]
tick
tree_return  ;;randomly seeds new trees based on wind or water born seeds or cuttings
set pop_pred count predators
set pop_prey count prey
set pop_willows count willows
set week week + 1
if week = 52 [set week 0 set year year + 1]
 ask patches  ;;updates the avaiablity of grass and changes the state of the grass if it has been overgrazed by elk
[
check_overgrazing
regrow
]

ask predators  ;;routines set aside specifically for activities of the predators
[
  live
  hunt
  kill
  death_pred
  grow_old_pred
  reproduce_predator
]

ask prey    ;;routines set aside specifically for activities of the prey
[
  form_herd
  live
  forage
  graze_trees
  death_prey
  grow_old_prey
  reproduce_prey
]

ask willows  ;;routines set aside specifically for activities of the willows
[
  live
  tree_growth
  death_willow
  grow_old
  reproduce_willows
]


end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Agent Routines ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; living cost energy and currently it cost the same to all species
to live
  set energy energy - 2
  if energy <= 50
  [set health health - 5]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Predator Routines ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to hunt
  if energy < 90 [ let target one-of prey in-cone 20 120 ;;based upon the perception of the predators
  if target != nobody [
  face target
  fd 1 ]]
end

to kill
  if energy < 100 and random-float 1 <= .42[ ;;predators will only kill if they are hungry and not every encounter ends with a kill
  let target one-of prey in-radius 1
  if target != nobody
  [ ask target [ set predation predation + 1
      die ]
  set energy energy + EnergyFromPrey]
  ]
end

to reproduce_predator  ;;based on empirical data outlining the reproductive behavior of wolves in the wild
  set litter_size random MaxLitterSize

  if pop_pred != 1 and week = 16 and sex = 0 and energy >= 50
  [
    if random-float 1 < wolf_reprod_rate [
    hatch ( litter_size * pup_mortality_rate ) [
      set age 0
      rt random-float 360 fd 1
      set pups pups + ( litter_size * pup_mortality_rate )]
    ]
  ]
end

to death_pred ;;Kills a predator if it runs out of health or energy
  if energy < 0 [
    set starve_pred starve_pred + 1
    die]
  ;;if health < 0 [die]

end

to grow_old_pred ;;Kills a predator if it reaches its maximum age
  if week = 51 [set age age + 1]
  if age >= max_age [
    set old_age_pred_death old_age_pred_death + 1
    die]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Prey Routines ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to graze_grass
  if pcolor = green [set biomass biomass - 10
  if energy < 100 [
  set energy energy + EnergyFromGrass]]
end

to rd_move
  ifelse any? predators in-cone 2 90
  [ right 180 fd 1
    set energy energy - 2]

  [form_herd
  fd 1]
end

to forage
  let target one-of willows in-cone 10 120
  ifelse target != nobody [face target fd 1][form_herd fd 1]
end

to graze_trees
  ifelse any? willows in-radius 1
  [ let target one-of willows in-radius 1
    move-to target
   ;; if target health > 30
    ask target [set health health - 1]
    if energy < 100 [
      set energy energy + EnergyFromWillows]]
  [graze_grass]
end

to reproduce_prey ;;based on empirical data outlining the reproductive behavior of elk in the wild

   if pop_prey != 1 and week = 20 and sex = 0 and energy >= 50
  [

    if random-float 1 < (elk_reprod_rate * calf_mortality_rate) [
    hatch 1 [
     set age 0
    rt random-float 360 fd 1
    set calves calves + 1]
    ]
  ]
end

to death_prey ;;Kills a prey if it runs out of health or energy
  if energy < 0 [    set starve_prey starve_prey + 1  die]
  if health < 0 [    set starve_prey starve_prey + 1  die]

end

to grow_old_prey ;;Kills a prey if it reaches its maximum age
  if week = 51 [set age age + 1]
  if age >= max_age [    set old_age_prey_death old_age_prey_death + 1 die]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Herd Routines ;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Wilensky, Uri. Netlogo Flocking Model. 1998. Center for Connected Learning and Computer-Based Modeling. <http://ccl.northwestern.edu.netlogo/models/Flocking>.

to form_herd
  find_herd
  if any? herdmates
    [find-nearest-herd
      ifelse distance nearest-herd < 5
      [separate]
      [align
        cohere]]
end

to find_herd
  set herdmates other prey in-radius 5
end

to find-nearest-herd
  set nearest-herd min-one-of herdmates [distance myself]
end

to separate
  turn-away ([heading] of nearest-herd) 1.50
end

to turn-away [new-heading max-turn]
  turn-at-most (subtract-headings heading new-heading) max-turn
end

to align
  turn-towards average-herdmate-heading 5.00
end

to-report average-herdmate-heading
  let x-component sum [dx] of herdmates
  let y-component sum [dy] of herdmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to cohere
  turn-towards average-heading-towards-herdmates 3.0
end

to-report average-heading-towards-herdmates
  let x-component mean [sin (towards myself + 180)] of herdmates
  let y-component mean [cos (towards myself + 180)] of herdmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

to turn-at-most [turn max-turn]
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end

to turn-towards [new-heading max-turn]
  turn-at-most (subtract-headings new-heading heading) max-turn
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Willow Routines ;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to reproduce_willows ;;based on empirical data outlining the reproductive behavior of elk in the wild
  if health > willow_reprod and week < 28 and week > 12 and age > 10 and pop_willows < 8000
  [ hatch 1 [
      set age 0
      rt random-float 360 fd random-float 5
      set saplings saplings + 1]
  ]
 end

  to tree_growth ;;regenerates tree health and energy
    if health < 100 [set health health + 5]
    if health > 95
    [set energy energy + 10]
  end

 to tree_return  ;;returns trees to the environment through spontaneous generation
    if not any? willows and week = 10 [
      create-willows 10 [
   setxy random-xcor random-ycor
   set color brown
   set shape "plant"
   set energy round(random-normal 85 10)
   set age random 5
   set max_age round(random-normal 50 35)
   set health 100
      ]
    ]
 end

to death_willow ;;Kills a willow if it runs out of health or energy
  if energy < 0 [ set eaten_willow eaten_willow + 1 die]
  if health < 0 [ set eaten_willow eaten_willow + 1 die]

end

to grow_old ;;Kills a prey if it reaches its maximum age
  if week = 51 [set age age + 1]
  if age >= max_age [die]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;Patch Routines ;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to check_overgrazing ;;once a patch has been grazed out of all of its avaiable biomass it changes to brown and prey can not longer feed on it

  if biomass <= 0
    [set pcolor brown]
end

to regrow ;;regrows grass during the growing season

    if pcolor = green and week < 40 and week > 8[ set biomass biomass + 2]
    if pcolor = brown and week < 40 and week > 8[ set biomass biomass + 15]
    if biomass >= 50 [ set pcolor green]
end
@#$#@#$#@
GRAPHICS-WINDOW
222
10
1023
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
1
1
1
-30
30
-20
20
0
0
1
Weeks
30.0

SLIDER
3
50
192
83
number-of-predators
number-of-predators
0
200
50.0
1
1
NIL
HORIZONTAL

SLIDER
4
90
176
123
number-of-prey
number-of-prey
0
5000
1000.0
10
1
NIL
HORIZONTAL

BUTTON
0
10
82
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

BUTTON
85
10
148
43
Step
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
150
10
213
43
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
6
138
178
171
willow-stands
willow-stands
0
100
30.0
1
1
NIL
HORIZONTAL

PLOT
4
182
204
332
Predators
Time (weeks)
# of Predators
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -5298144 true "" "plot count predators"

PLOT
6
341
206
491
Prey
Time (weeks)
# of Prey
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14439633 true "" "plot count prey"

MONITOR
1031
14
1088
59
Year
Year
17
1
11

MONITOR
1032
64
1089
109
Week
week
17
1
11

PLOT
8
506
208
656
Willows
Time (weeks)
# of stands
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count willows"

TEXTBOX
413
584
563
602
Predator Reproduction Rate
11
0.0
1

TEXTBOX
610
580
760
598
Prey Reproduction Rate
11
0.0
1

TEXTBOX
791
577
961
605
Willow Reproduction Health Req.
11
0.0
1

SLIDER
790
606
962
639
willow_reprod
willow_reprod
0
100
75.0
1
1
NIL
HORIZONTAL

MONITOR
1032
112
1133
157
# of Predators
pop_pred
17
1
11

MONITOR
1033
160
1100
205
# of Prey
pop_prey
17
1
11

MONITOR
1033
210
1119
255
# of Willows
pop_willows
17
1
11

MONITOR
1032
286
1118
331
Calves Born
calves
17
1
11

MONITOR
1121
286
1178
331
Whelps
pups
17
1
11

MONITOR
1182
286
1247
331
Saplings
saplings
17
1
11

TEXTBOX
1034
354
1184
372
Predator Deaths
11
0.0
1

TEXTBOX
1037
433
1187
451
Prey Deaths
11
0.0
1

MONITOR
1035
372
1110
417
Starvation
starve_pred
17
1
11

MONITOR
1113
372
1176
417
Old Age
old_age_pred_death
17
1
11

SLIDER
611
600
783
633
PreyReproduction
PreyReproduction
0
1
0.9
.05
1
NIL
HORIZONTAL

SLIDER
612
639
784
672
CalfMortality
CalfMortality
0
1
0.33
.01
1
NIL
HORIZONTAL

SLIDER
413
601
603
634
PredatorReproduction
PredatorReproduction
0
1
0.25
.1
1
NIL
HORIZONTAL

TEXTBOX
1038
520
1188
538
Willow Deaths
11
0.0
1

MONITOR
1037
449
1112
494
Starvation
starve_prey
17
1
11

MONITOR
1116
449
1179
494
Old Age
old_age_prey_death
17
1
11

MONITOR
1182
449
1254
494
Predation
predation
17
1
11

MONITOR
1039
536
1111
581
Predation
eaten_willow
17
1
11

TEXTBOX
1035
269
1185
287
Births
11
0.0
1

SLIDER
413
639
585
672
MaxLitterSize
MaxLitterSize
0
6
4.0
1
1
NIL
HORIZONTAL

SLIDER
413
675
585
708
WhelpMortality
WhelpMortality
0
1
0.5
.1
1
NIL
HORIZONTAL

SLIDER
230
603
402
636
EnergyFromGrass
EnergyFromGrass
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
230
639
402
672
EnergyFromPrey
EnergyFromPrey
0
25
25.0
1
1
NIL
HORIZONTAL

SLIDER
230
674
403
707
EnergyFromWillows
EnergyFromWillows
0
25
15.0
1
1
NIL
HORIZONTAL

TEXTBOX
235
585
385
603
Caloric Value
11
0.0
1

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
<experiments>
  <experiment name="NoPred" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count prey</metric>
    <metric>count willows</metric>
    <enumeratedValueSet variable="MaxLitterSize">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EnergyFromWillows">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="willow_reprod">
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="CalfMortality">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PreyReproduction">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="PredatorReproduction">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="willow-stands">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-predators">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-prey">
      <value value="600"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="WhelpMortality">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EnergyFromGrass">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="EnergyFromPrey">
      <value value="25"/>
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
