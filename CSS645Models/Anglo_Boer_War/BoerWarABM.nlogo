;; ABM of Anglo-Boer War's guerilla phase

globals [
  battles
  british-dead
  debt
  initial-british-force
  initial-boer-force
  num-british
  num-boer
  Cost-of-burning
  Cost-per-tick
  Cost-per-soldier
  Cost-per-blockhouse
  casualty-rate-boer
  casualty-rate-brit
  size-difference
  burning-threshold
]

breed [boer-troops boer-troop]
breed [brit-troops brit-troop]
breed [bunkers bunker]
breed [farmers farmer]
breed [fires fire]
breed [blockhouses blockhouse]

patches-own [
  boer-sign ;; counts how many times a boer army has passed over the patch
]

turtles-own [
]

brit-troops-own [
  reinforcement-timer ;; counts ticks after a wave reinforcement
  strength ;; number of men in the army
  old-strength ;; placeholder variable to allow for easier computations of new values
  old-food  ;; placeholder variable to allow for easier computations of new values
  food ;; food stockpile
  move? ;; boolean if movement forward is possible
]

boer-troops-own [
  strength ;; number of men in the army
  old-strength ;; placeholder variable to allow for easier computations of new values
  old-food ;; placeholder variable to allow for easier computations of new values
  food ;; food stockpile
  move? ;; boolean if movement forward is possible
]

farmers-own [
  helped-boers  ;; tallies how many times the farm has aided the boers
  harvest-timer ;; counts ticks after a harvest, will result in more food after 52 ticks
  checked?  ;; has the british army checked this farm recently?
  food  ;;  ho much food in this crop
]

to setup
  clear-all
  reset-ticks

  set initial-british-force 30000
  set initial-boer-force 15000
  set num-british 5
  set num-boer 5
  set Cost-of-burning 25
  set Cost-per-tick 25
  set Cost-per-soldier 2
  set Cost-per-blockhouse 25
  set burning-threshold 1

  ask patches  ;; sets up the veldt
    [ set pcolor brown
      set boer-sign 0 ]

  set-default-shape farmers "house colonial"  ;; creation of boer homestead/farms
  create-farmers 50
  [
    setxy random-xcor random-ycor
    set color brown
    set size 1.5
    set food (precision (random-float 5000) 2)  ;; random food in the harvest
    ask farmers
    [      ask patches in-radius 6  ;;  creates a zone that boers can forage from
      [ set pcolor green ] ]
  ]

  set-default-shape blockhouses "house"  ;; default blockhouse setup
  create-blockhouses 0
  [set color blue]

  set-default-shape brit-troops "person"  ;; british army creation
  create-brit-troops num-british
  [
    setxy random-xcor random-ycor
    set size 2
    set color red
    set strength (precision (initial-british-force / num-british) 0)
    set food (precision (strength * 10) 2)
    set reinforcement-timer 0
  ]

  set-default-shape boer-troops "person"  ;; boer army creation
  create-boer-troops num-boer
  [
    setxy random-xcor random-ycor
    set size 2
    set color cyan
    set strength (precision (initial-boer-force / num-boer) 0)
    set food (precision (strength * 5) 2)
  ]

  set-default-shape fires "fire" ;; fire depiction for battles/farm burning
  create-fires 0
  [
    set color yellow
    set size 2
  ]
end

to go
  clear-fires
  check-death
  check-food
  harvest
  reinforcement
  move-boers
  move-british
  if ( sum [strength] of boer-troops <= 0 )
  [ stop ]
  if ticks > 30000
  [ stop ]
  set debt (debt + Cost-per-tick) ;; updats war debt with the cost of continuing to wage the war
  tick
end

to harvest  ;;  every 52 ticks after having been harvested, the farmers will have another harvest
  ask farmers[
    ifelse harvest-timer >= 52
    [set food (precision (random-float 5000) 2)
      set harvest-timer 0]
    [ set harvest-timer  (harvest-timer + 1) ]
      ]
end

to reinforcement
  ask brit-troops[
    ifelse reinforcement-timer >= 104 ;; British armies regain full compliment after 104 ticks
    [
      set strength (precision (initial-british-force / num-british) 0)
      set food (precision (strength * 10) 2)
    ]
    [set reinforcement-timer (reinforcement-timer + 1)]
    if reinforcement-timer >= 105
    [set reinforcement-timer 0]
  ]
end

to check-death
  ask boer-troops
  [if strength < 100
    [ die ]
  ]
  ask brit-troops
  [if strength < 100
    [ die ]
  ]
end

to clear-fires
  ask fires
  [ die ]
end

to check-food
  ask boer-troops
  [if food > 100 * strength
    [set food (100 * strength)]
  ]
end

to move-boers
  ask boer-troops
  [
    if pcolor = grey
    [set strength (strength - 25)]
    ask patch-here
      [set boer-sign (boer-sign + 1)]
    look-for-objectives
  ]
end

to look-for-objectives
  ask boer-troops
  [
    ifelse ( count brit-troops in-radius 5 > 0 ) ;; looks for British troops in area first
    [ evaluate-enemy ]
    [ search-targets ]
  ]
end

to evaluate-enemy ;; are british troops larger than me?
  ask ( brit-troops in-radius 11 )
  [
    ifelse strength >= [strength] of myself
    [ ask myself [ flee ] ] ;; yes? run
    [ ask myself [ engage ] ] ;; no? attack
  ]
end

to search-targets
  ifelse count farmers in-radius 25 > 0  ;; look for nearby farms
  [evaluate-farm]
  [ifelse count (farmers with-min [distance myself]) > 0  ;; closest farmer
    [set heading towards min-one-of farmers [distance myself]
      fd 1]
    [set heading random 360
      fd 1]
  eat
  ]
end

to evaluate-farm
  ifelse sum [food] of farmers in-radius 25 > 100
  [ gather-food ]
  [ ifelse count (farmers in-radius 25 with-max [food]) > 0
    [set heading towards max-one-of (farmers in-radius 25) [ food ]
      fd 1]
    [set heading random 360
      fd 1]
  ]
end

to gather-food
  set old-food food
  set heading towards max-one-of farmers in-radius 25 [food]
  fd 1
  if count farmers in-radius 1 > 0
  [
    set food ( old-food + ( sum [food] of farmers in-radius 1) )
    ask farmers in-radius 1
    [ set food 0
      set harvest-timer 0
      set helped-boers (helped-boers + 1)]
  ]
end

to move-british
  ask brit-troops
  [
    ifelse ( count boer-troops in-radius 10 > 0 )
    [ evaluate-enemy-brit ]
    [ hunt-boers ]
  ]
end

to evaluate-farm-brit
  ifelse farm-burning?
  [ investigate-farm ]
  [ search-area ]
end

to search-area
  ifelse (count farmers with [ helped-boers > 0 ] > 0)
  [  ifelse (count farmers in-radius 1 > 0)
    [ask farmers
      [set helped-boers 0]
    set heading random 360
    fd 1]
    [set heading towards one-of farmers with [ helped-boers > 0 ]
    fd 1]
  ]
  [set heading random 360
    fd 1]
end

to investigate-farm
  ifelse ( count farmers with [ helped-boers > 0 ] > 0)
  [set heading towards max-one-of farmers [helped-boers]
  fd 1
  if count farmers in-radius 1 > 0
  [
    ifelse sum ( [helped-boers] of farmers in-radius 1 ) > burning-threshold
    [burn-farm]
    [set heading towards max-one-of farmers [ helped-boers ]
      fd 1]
    ask farmers in-radius 3
      [ set helped-boers 0]
  ]
  ]
   [set heading random 360
    fd 1]
end

to burn-farm
  hatch-fires 1
  ask fires in-radius 1
  [ set size 1
    set color yellow ]
  ask farmers in-radius 1
  [ die ]
  set debt (debt + cost-of-burning)
end

to engage
  ifelse  ( count brit-troops in-radius 1 >= 1 )
  [ battle ]
  [ ifelse count brit-troops in-radius 11 > 0
    [set heading towards one-of (brit-troops in-radius 11)
      fd 1
      eat]
    [set heading random 360
      set move? ( can-move? 1 )
      ifelse move? = true
      [fd 1]
      [set heading random 360
        fd 1]
      eat]
  ]
end

to flee
  ifelse count brit-troops in-radius 11 > 0
  [
    set heading ( ( towards one-of (brit-troops in-radius 11)) - 180 )
    set move? ( can-move? 1 )
    ifelse move? = true
    [fd 1]
    [set heading random 360
      fd 1
      eat]
  ]
  [set heading random 360
    set move? ( can-move? 1 )
    ifelse move? = true
    [fd 1]
    [set heading random 360
      fd 1
      eat]]
end

to battle
  set battles (battles + 1)
  hatch-fires 1
  [ set color yellow
    set size 3]
  calculate-victor
end

to calculate-victor
  ifelse (sum [strength] of boer-troops in-radius 1) >= (sum [strength] of brit-troops in-radius 1)
  [ boer-victory ]
  [ british-victory ]
end

to boer-victory
  casualty-ratio-calculate
  ask boer-troops in-radius 1
  [ set old-strength strength
    set old-food food
    set strength precision (old-strength - ( 0.1 * old-strength * casualty-rate-boer)) 0
    set food (old-food + (0.5 * (sum [food] of brit-troops in-radius 1)))
    eat
    if strength < 0
    [ die ]
  ]
  ask brit-troops in-radius 1
  [ set old-strength strength
    set old-food food
    set strength precision (old-strength - ( 0.1 * old-strength * casualty-rate-brit)) 0
    set debt (debt + (( 0.1 * old-strength * casualty-rate-brit) * Cost-per-soldier))
    set british-dead (british-dead + ( 0.1 * old-strength * casualty-rate-brit) )
    set food (0.5 * food)
    set heading random 360
    fd 6
    if strength < 0
    [ die ]
  ]
end

to british-victory
  casualty-ratio-calculate
  ask brit-troops in-radius 1
  [ set old-strength strength
    set strength precision (old-strength - ( 0.1 * old-strength * casualty-rate-brit)) 0
    set debt (debt + (( 0.1 * old-strength * casualty-rate-brit) * Cost-per-soldier))
    set british-dead (british-dead + ( 0.1 * old-strength * casualty-rate-brit) )
     if strength < 0
    [ die ]
  ]
  ask boer-troops in-radius 1
  [ set old-strength strength
    set old-food food
    set strength precision (old-strength - ( 0.1 * old-strength * casualty-rate-boer)) 0
    set food (0.9 * food)
    set heading random 360
    fd 6
    eat
     if strength < 0
    [ die ]
  ]
end

to casualty-ratio-calculate
  set size-difference ( abs( (sum [strength] of brit-troops in-radius 1) - (sum [strength] of boer-troops in-radius 1) ) + 1 )
  set casualty-rate-boer ( 1 / ( (sum [strength] of boer-troops in-radius 1) / size-difference ) )
  set casualty-rate-brit ( 1 / ( (sum [strength] of brit-troops in-radius 1) / size-difference ) )
end

to eat
  if food <= 0
  [ set food 0 ]
  if pcolor = brown
  [
    set old-food food
    set food (old-food - ( strength * 0.5))
  ]
  if pcolor = green
  [
    set old-food food
    set food (old-food - (strength * 0.25))
  ]
  if pcolor = grey
  [
    set old-food food
    set food (old-food - (strength * 0.75))
  ]
  if food <= 0
  [
    set old-strength strength
    set strength (old-strength - 100)
  ]
end

to hunt-boers
  ifelse blockhouse-building? = true
  [ ask brit-troops
    [
      ifelse ( count patches in-radius 10 with [ boer-sign > blockhouse-threshold ] > 0 )
      [ intiate-blockhouse ]
      [ evaluate-farm-brit ]
    ]
  ]
  [ evaluate-farm-brit ]
end

to intiate-blockhouse
  set heading towards max-one-of patches in-radius 10 [boer-sign]
  fd 1
  if count patches with [ boer-sign > blockhouse-threshold ] in-radius 1 > 0
  [ build-blockhouse
    ask patches in-radius 2
    [ set boer-sign 0 ]
  ]
end

to build-blockhouse
  set debt ( debt + Cost-per-blockhouse )
  hatch-blockhouses 1
  ask blockhouses in-radius 1
  [ set size 1
    set color blue
    ask patches in-radius 2
    [set pcolor grey
      set boer-sign 0]
  ]
end

to evaluate-enemy-brit
  ask ( boer-troops in-radius 10 )
  [
    ifelse strength >= [strength] of myself
    [ ask myself [ flee-brit ] ]
    [ ask myself [ engage-brit ] ]
  ]
end

to engage-brit
  ifelse  ( count boer-troops in-radius 1 >= 1 )
  [ battle ]
  [ ifelse count boer-troops in-radius 10 > 0
    [set heading towards one-of (boer-troops in-radius 10)
      fd 1 ]
    [set heading random 360
      set move? ( can-move? 1 )
      ifelse move? = true
      [fd 1]
      [set heading random 360
        fd 1]]
  ]
end

to flee-brit
  ifelse count boer-troops in-radius 11 > 0
  [
    set heading ( ( towards one-of (boer-troops in-radius 11)) - 180 )
    set move? ( can-move? 1 )
    ifelse move? = true
    [fd 1]
    [set heading random 360
      fd 1]
  ]
  [set heading random 360
    set move? ( can-move? 1 )
    ifelse move? = true
    [fd 1]
    [set heading random 360
      fd 1]]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1206
1007
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
0
75
0
75
0
0
1
ticks
30.0

BUTTON
1
10
65
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

SWITCH
12
59
145
92
farm-burning?
farm-burning?
0
1
-1000

SWITCH
12
98
181
131
blockhouse-building?
blockhouse-building?
0
1
-1000

BUTTON
66
10
145
43
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
146
10
209
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

MONITOR
8
339
102
384
Green Patches
count patches with [pcolor = green]
17
1
11

MONITOR
102
339
197
384
Brown Patches
count patches with [pcolor = brown]
17
1
11

MONITOR
7
393
64
438
Boers
sum [strength] of boer-troops
17
1
11

MONITOR
67
393
124
438
British
sum [strength] of brit-troops
17
1
11

MONITOR
150
51
207
96
Farms
count farmers
17
1
11

MONITOR
126
392
183
437
Battles
battles
17
1
11

MONITOR
14
448
91
493
War Debt
precision (debt) 0
17
1
11

MONITOR
95
449
174
494
British Dead
precision (british-dead) 0
17
1
11

SLIDER
12
176
184
209
blockhouse-threshold
blockhouse-threshold
1
3
1.0
1
1
NIL
HORIZONTAL

MONITOR
13
505
93
550
Blockhouses
count blockhouses
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model is meant to simulate several different British strategies to respond to the continued raids of Boer guerillas in the closing years of the Anglo-Boer War of 1899-1902.  British armies seek to engage Boer forces and defeat them in battle.  They can also engage in farm razeing and blockhouse construction to restrict Boer movement throughout the spatial environment.  These actions also come at a cost for the British as the British are responsible for housing Boer civilians in concentration and for the construction costs of creating the blockhouses.

## HOW IT WORKS

Boer armies travel the map searching to resupply at friendly farms so long as they are not threatened by a larger British force.  British armies travel the map hunting Boer units and if they are authorized to use farm burning and blockhouse building strategies, they will evaluate the best locations in their immediate area to either remove Boer-supporting farms or build Boer-movement-restricting blockhouses.  Each time step is meant to simulate half a week, thus 104 ticks is equal to a simulated year.

## HOW TO USE IT

Toggle British combat rules (farm-burning and blockhouse-building) to evaluate the efficacy of the varying strategies (and all combinations there of) in defeating the Boer guerilla forces.  Various monitors will report total numbers of British troops killed in action, the cumulative cost of the war for the British, the number of blockhouses built, as well as the number of burned farms.

## THINGS TO NOTICE

Examine the British casualties sustained and the overall duration of the conflict to best evaluate which strategies are more effective in defeating the Boer force.  Also notice that without a specialized counter-insurgency strategy it is very difficult for the British to win the campaign.


## EXTENDING THE MODEL

Useful additions to this model would be the inclusion of real world GIS data of the historical region as well as historical starting locations for the varying armies.  Additionally the inclusion of logistical units travelling to British units might allow for an enhanced model of Boer guerilla activity.  Additionally, greater information on the casualty rates from historical skirmishes might help better improve the combat sub-model.
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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

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

house colonial
false
0
Rectangle -7500403 true true 270 75 285 255
Rectangle -7500403 true true 45 135 270 255
Rectangle -16777216 true false 124 195 187 256
Rectangle -16777216 true false 60 195 105 240
Rectangle -16777216 true false 60 150 105 180
Rectangle -16777216 true false 210 150 255 180
Line -16777216 false 270 135 270 255
Polygon -7500403 true true 30 135 285 135 240 90 75 90
Line -16777216 false 30 135 285 135
Line -16777216 false 255 105 285 135
Line -7500403 true 154 195 154 255
Rectangle -16777216 true false 210 195 255 240
Rectangle -16777216 true false 135 150 180 180

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
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30000"/>
    <metric>count boer-troops</metric>
    <metric>count farmers</metric>
    <metric>count battles</metric>
    <metric>precision (debt) 0</metric>
    <metric>precision (british-dead) 0</metric>
    <metric>count blockhouses</metric>
    <enumeratedValueSet variable="farm-burning?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blockhouse-threshold">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="blockhouse-building?">
      <value value="false"/>
      <value value="true"/>
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
