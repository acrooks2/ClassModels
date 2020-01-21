breed [ deers deer]
breed [ hunters person]

globals [
  parkland             ; all of the park area
  park1 park2 park3    ; segments of the total park
  garden-trap          ; trap area
  residential          ; the residential areas of the map
  road                 ; the road, Route 1
  needs-counter        ; number of deer killed for food purposes
  environ-counter      ; number of deer killed for environmental purposes
  recreat-counter      ; number of deer killed for recreation
  deer-road-deaths     ; counter for number of deer that are hit by cars
  risky-hunting        ; counter for the number of deer killed outside the park
  deer-killed-in-trap  ; counter for the number of deer killed in the trap
  initial-total-lives  ; total number of deer lives at setup
]

deers-own [
  energy-level         ; how much energy they have now
  lives                ; how many deer in herd
  vision               ; how far they can see/hear hunters
  risk                 ; how used to humans the deer are
  possible-moves       ; stores neighboring patches with enough energy
]

hunters-own [
 motivation            ; needs-based, recreation-based, environmental-based
 kill-percentage       ; percentage female deer hit
 max-kill              ; max number of deer hunter will kill determined by motivation
 kill-count            ; number of deer the hunter has killed
 risk                  ; kill deer outside "law"
 vision                ; how far the hunter can see
; marksmanship          ; how good a shot the hunter is
 risky-level           ; how risky taking a shot outside the park seems, heterogeneous
 trapper?              ; boolean returns true if this hunter is stationed around the garden trap
]

patches-own [
  energy-available     ; how much energy the patch can offer to deer
  max-energy-available ; maximum amount of energy the patch can ever have
  danger               ; danger to deer to graze here, higher in residential area
  area                 ; used to define limits if the parkland
  Huntley-Park?        ; boolean that returns true only for parkland patches
  near-road?           ; boolean returns true if 1 patch away from the road
  trap?                ; boolean returns true for patches that represent a garden trap
  around-trap?         ; boolean returns true for patches surrounding the garden trap
]


;;;;;;;;;;;;;;;;;;;;
;;SETUP PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ; if none of the motivation switches are on
  if needs-hunters? = false and environmental-hunters? = false and recreational-hunters? = false
    [ user-message (word "Eror: There must be at least one motivation switch turned on.")
      stop ]

  setup-counters
  setup-landscape ; setup energy-available on patches
  update-patch-color ; setup color visuals of patches
  setup-deers
  setup-hunters
  if trapping? [delineate-trappers] ; if the switch is on, make four of the hunters trappers

  reset-ticks
end

to setup-counters ; initialize all counters
  set needs-counter 0
  set environ-counter 0
  set recreat-counter 0
  set deer-road-deaths 0
  set risky-hunting 0
  set deer-killed-in-trap 0
end

to setup-landscape
  set residential patches ; all patches are "residential" at first
  ask residential [
    set pcolor lime ; default
    set Huntley-Park? false ; boolean returns false, default
    set near-road? false ; boolean returns false, default
    set trap? false ; boolean returns false, default
    set around-trap? false ; boolean returns false, default
    set energy-available (12 + random 20)
    set max-energy-available energy-available ; save as maximum energy available
  ]

  set road patches with [pxcor = 12] ; re-set these patches as road
  ask road [
    set pcolor gray ; gray in color
    set near-road? true ; this is the road! hunters can not shoot here
    set energy-available 0 ; no energy from consumption on road
  ]

  ; this code block enables us to create the unique shape of park
  set park1 patches with [pycor >  -10 and pycor < 8 and pxcor < 6 ]
  ask park1 [set area 1] ; define these limits as area 1
  set park2 patches with [pycor > 6  and pycor < 10 and pxcor < -15 ]
  ask park2 [set area 1] ; define these limits as area 1
  set park3 patches with [pycor > -1  and pycor < 8 and pxcor < 7 and pxcor > 5 ]
  ask park3 [set area 1] ; define these limits as area 1

  set parkland patches with [area = 1] ; parkland is all patches defined above as park1, park2, or park3
  ask parkland [
    set pcolor green ; default
    set Huntley-Park? true ; boolean returns true
    ifelse acorn-year? ; if this model run represents an "acorn" year
    [set energy-available (25 + random 20)] ; then there is considerably more energy in the park
    [set energy-available (12 + random 10)] ; than there would be otherwise
    set max-energy-available energy-available ; save as maximum energy available
  ]

  ask patches with [pxcor = 11] [set near-road? true] ; these patches border the road
  ask patches with [pxcor = 13] [set near-road? true] ; these patches border the road

  if trapping? = true ; if the hunters are allowed to use traps to hunt deer
  [ ; create a rectangle of land in the park to represent a garden trap
    set garden-trap patches with [pxcor > -15 and pxcor < -11 and pycor > -5 and pycor < 0]
    ask garden-trap [set energy-available (30 + random 10) ; very yummy foliage here!
      set trap? true]
    ask patches with [pxcor >= -15 and pxcor <= -11 and pycor >= -5 and pycor <= 0 and not trap?]
    [set around-trap? true] ; patches around the trap return true for this boolean
  ]
end

to update-patch-color
  ask residential [ ; set up the color visuals of the residential area
    ifelse (energy-available >= 10 and energy-available <= 20)
      [set pcolor green + 2]
      [set pcolor green + 1]
  ]

  ask parkland [ ; set up the color visuals of the parkland
    ifelse acorn-year?
      [ ifelse (energy-available >= 25 and energy-available <= 35)
        [set pcolor green - 1]
        [set pcolor green - 2] ]
      [ ifelse (energy-available >= 12 and energy-available <= 18)
        [set pcolor green - 1]
        [set pcolor green - 2]
      ]
  ]

  repeat 2 [diffuse pcolor 0.5] ; diffuse the color scheme

  ask road [set pcolor gray] ; make sure road is gray

  if trapping? = true [ ask garden-trap [set pcolor turquoise] ] ; set color for garden trap
end

to setup-deers
  set-default-shape deers "deer" ; set shape
  create-deers initial-number-herds ; create the number of deer as input on interface
    ask deers [
      setxy random-xcor random-ycor ; move to random location
      set size 1 ; set size
      set lives 1 + random 4 ; set initial number of deer in herd
      set energy-level (lives * (2 + random 1) + random 5) ; set initial energy-level
      separate-deer ; make sure no deer are overlapping
    ]
     set initial-total-lives (sum [lives] of deers)
end

to separate-deer
  if any? other deers-here ; if there are other deer on your patch
  [setxy random-xcor random-ycor ; move to a different patch
    separate-deer] ; and check again
end

to setup-hunters
  set-default-shape hunters "person" ; set shape
  create-hunters initial-number-hunters ; create the number of hunters as input on interface
  ask hunters [
    setxy random-pxcor random-pycor ; move to random location
    set size 1 ; set size
    set color white ; set color
    set trapper? false ; boolean returns false, default

    ; if only one of the motivation switches is ON
    if needs-hunters? or environmental-hunters? or recreational-hunters?
    [ if needs-hunters?
      [ set motivation "needs" ; define
        set max-kill  1 + random 1] ; set max-kill number
    if environmental-hunters?
      [ set motivation "environmental" ; define
        set max-kill 3 + random 2] ; set max-kill number
    if recreational-hunters?
      [ set motivation "recreation" ; define
        set max-kill 11 ] ; set max-kill number
    ]

    ; if two of the motivation switches are ON
    if (needs-hunters? and environmental-hunters?) or
    (needs-hunters? and recreational-hunters?) or
    (environmental-hunters? and recreational-hunters?)
    [ let motivation1 ""
      let motivation2 ""
      let kill-number1 0
      let kill-number2 0

      ifelse needs-hunters?
        [ set motivation1 "needs"
          set kill-number1 1 + random 1
          ifelse environmental-hunters?
          [ set motivation2 "environmental"
            set kill-number2 3 + random 2 ]
          [ set motivation2 "recreation"
            set kill-number2 6 + random 5 ]
        ]
        [ set motivation1 "environmental"
          set kill-number1 3 + random 2
          set motivation2 "recreation"
          set kill-number2 6 + random 5  ]

      let m random 2 ; create a stand-in value for use below
      if m = 0 [
        set motivation motivation1 ; define
        set max-kill kill-number1 ; set max-kill number
      ]
      if m = 1 [
        set motivation motivation2 ; define
        set max-kill kill-number2 ; set max-kill number
      ]
    ]

    ; if all three of the motivation switches are ON
    if needs-hunters? and environmental-hunters? and recreational-hunters?
      [ let m random 3 ; create a stand-in value for use below
        if m = 0 [
          set motivation "needs" ; define
          set max-kill 1 + random 1 ] ; set max-kill number
        if m = 1 [
          set motivation "environmental" ; define
          set max-kill 3 + random 2 ] ; set max-kill number
        if m = 2 [
          set motivation "recreation" ; define
          set max-kill 6 + random 5  ] ; set max-kill number
      ]

    set vision 2 + (random 3) ; set vision parameter, heterogeneous
    set kill-count 0 ; initialize, no deer killed yet
   ; set marksmanship random-float 1.0 ; set markmanship, heterogeneous
    set risky-level random-float 1.0 ; set the risky-level, heterogeneous

    separate-hunters ; make sure no hunters are overlapping
  ]

end

to separate-hunters
  if any? other hunters-here ; if there are other hunters on your patch
  [setxy random-xcor random-ycor ; move to a different patch
    separate-hunters] ; and check again
  if trapping? [
  if any? hunters-on garden-trap
   [setxy random-xcor random-ycor ; move to a different patch
    separate-hunters] ; and check again
  ]
end

to delineate-trappers
  ;if trapping? ; if the trapping is on, then place hunters around the garden trap
   ; [
      repeat number-trappers [ ; for four of the hunters
      ask one-of hunters with [trapper? = false] ; who are not already trappers
        [ set trapper? true ; make them a trapper
          let trapping-patch one-of patches with [around-trap? and not any? other hunters-here]
          let trapping-xcor [pxcor] of trapping-patch ; save the xcor of a vacant patch around the trap
          let trapping-ycor [pycor] of trapping-patch ; save the xcor of a vacant patch around the trap
          setxy trapping-xcor trapping-ycor ; move trapper to this location
          set motivation "trapping" ; change motivation
          set max-kill 100 ; change max-kill, trappers can essentially shoot as many deer as they want
        ]
    ]
   ; ]
end

to go
  step ; iterate through the step procedure
  tick ; increment the clock

  ; ARCHERY SEASON in Fairfax County is 8 months long (240 ticks)
  if archery-season?
  [if ticks = 240
    [stop]
    ]
end

to step
  move-deer
  move-hunters
  grow-grass
  deer-killed-on-road
end

to move-deer
  ask deers [

    let old-location patch-here ; save the patch the deer starts on

    set heading random 360 ; pick a random direction
    fd 1 ; go forward 1 patch

    let distance-traveled (distance old-location) ; calculate how far the deer herd has traveled
    set energy-level (energy-level - ((distance-traveled * lives) / 1.1)) ; take into account energy lost from traveling
    set old-location patch-here ; update current location

    let needed-energy ((2 + random 1) * lives) ; save the deer's needed energy as a constant, 2-3 units per deer in herd
    set possible-moves neighbors ; deer can move to any of the patches in their Moore neighborhood

    let best-possible-move max-one-of possible-moves [energy-available] ; deer always move to patch with the most energy
    move-to best-possible-move ; move here

    ifelse (needed-energy >= [energy-available] of patch-here)
      [ set lives (lives - 1) ; if there are no patches with enough energy, lose a life
        set needed-energy ((2 + random 1) * lives) ; re-define to account for lost life
        ifelse [energy-available] of patch-here > needed-energy ; if new patch has enough energy
        [ set energy-level (energy-level + needed-energy)
          ask patch-here [set energy-available (energy-available - needed-energy) ] ; patch loses energy
        ]
        [ set energy-level (energy-level + [energy-available] of patch-here)
          ask patch-here [set energy-available 0 ]; patch loses energy
        ]
      ]
      [ set energy-level (energy-level + needed-energy)
        ask patch-here [set energy-available (energy-available - needed-energy) ] ; patch loses energy
      ]

    set distance-traveled (distance old-location) ; calculate how far the deer herd has traveled again
    set energy-level (energy-level - ((distance-traveled * lives) / 1.1)) ; take into account energy lost from traveling

    if energy-level < 0 [
      set energy-level 0 ; can't have less than 0 units of energy
      set lives (lives - 1)] ; herds with 0 energy lose a life
    if lives <= 0 [die] ; herds with no more deer, die
  ]
end

to move-hunters
  ask hunters [
    ifelse motivation = "trapping"
    [
      if any? deers-on garden-trap [
      let possible-prey deers-on garden-trap ; find all deer in vision
      let prey one-of possible-prey ; hunter picks one at random and attempts to shoot
       if random-float 1.0 < 0.1 [ ; if sucessful hit
          ask prey [
            ifelse lives > 1
            [set lives (lives - 1)] ; the herd either loses one of its number
            [die] ; or, if only one deer left in the herd, it dies
          ]
          set kill-count (kill-count + 1) ; increment counter for hunter
          set deer-killed-in-trap (deer-killed-in-trap + 1) ; increment global
       ]
      ]
    ]

    [
    set heading random 360 ; he picks a random direction
    fd 1 ; and goes forward 1 patch

    if any? deers in-radius vision [ ; if there are deer in the hunter's vision
      let possible-prey deers in-radius vision ; find all deer in vision
      let prey one-of possible-prey ; hunter picks one at random and attempts to shoot
      ifelse [Huntley-Park?] of patch-here ; if the deer is in Huntley Meadows Park, it is legal to shoot
        [ if random-float 1.0 < 0.1 [ ; if sucessful hit
          ask prey [
            ifelse lives > 1
            [set lives (lives - 1)] ; the herd either loses one of its number
            [die] ; or, if only one deer left in the herd, it dies
          ]
          set kill-count (kill-count + 1) ; increment counter for hunter
          if motivation = "needs" [set needs-counter (needs-counter + 1)]
          if motivation = "environmental" [set environ-counter (environ-counter + 1)]
          if motivation = "recreation" [set recreat-counter (recreat-counter + 1)]
        ] ]

        [ if risky-hunting? ; if risky (illegal) shootings are allowed in the model and
         ; if the hunter is not in Huntley Park, shooting deer is risky, and he can't shoot near the road
          [ if random-float 1.0 < risky-level and [near-road?] of patch-here = false
            [ if random-float 1.0 < 0.1 [ ; if sucessful hit
              ask prey [
                ifelse lives > 1
                [set lives (lives - 1)] ; the herd either loses one of its number
                [die] ; or, if only one deer left in the herd, it dies
              ]
              set kill-count (kill-count + 1) ; increment counter for hunter
              if motivation = "needs" [set needs-counter (needs-counter + 1)]
              if motivation = "environmental" [set environ-counter (environ-counter + 1)]
              if motivation = "recreation" [set recreat-counter (recreat-counter + 1)]
              set risky-hunting (risky-hunting + 1)
            ]
            ]
          ]
        ]
    ]
    if kill-count >= max-kill [die] ; hunters "die" when they have acheived their max-kill
  ]
  ]
end

to grow-grass
  ask parkland [ ; regrow foliage in parkland
    if energy-available < (max-energy-available - 1) ; as long as the max is not reached
    [set energy-available (energy-available + 2)] ] ; grow back by 2 units each tick

  ask residential [ ; regrow foliage in residential area
    if energy-available < (max-energy-available - 1) ; as long as the max is not reached
    [set energy-available (energy-available + 1)] ] ; grow back by 1 unit each tick
end

to deer-killed-on-road
  if any? deers-on patches with [near-road?] ; if there are any deer near the road
  [if random-float 105 < 1 ; based on research probability
    [ask one-of deers-on patches with [near-road?]
      [die] ; kill off one of these deer
    set deer-road-deaths (deer-road-deaths + 1) ; increment counter
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
442
12
1220
416
-1
-1
20.811
1
10
1
1
1
0
0
0
1
-18
18
-9
9
0
0
1
ticks
30.0

BUTTON
14
24
76
57
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
79
24
142
57
NIL
step
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
23
66
208
99
initial-number-herds
initial-number-herds
0
200
110.0
10
1
NIL
HORIZONTAL

SLIDER
23
104
201
137
initial-number-hunters
initial-number-hunters
0
100
45.0
5
1
NIL
HORIZONTAL

PLOT
19
256
413
404
Populations of Deer
time
pop.
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Parkland Deer" 1.0 0 -13791810 true "" "plot count deers-on parkland"
"Residential Deer" 1.0 0 -5825686 true "" "plot (count deers) - (count deers-on parkland)"

SWITCH
13
196
128
229
acorn-year?
acorn-year?
1
1
-1000

SWITCH
131
196
249
229
trapping?
trapping?
0
1
-1000

BUTTON
145
24
208
57
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
19
413
414
558
Deer Deaths
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Needs based" 1.0 0 -8630108 true "" "plot needs-counter"
"Environmental" 1.0 0 -13345367 true "" "plot environ-counter"
"Recreational" 1.0 0 -14835848 true "" "plot recreat-counter"
"Trapper" 1.0 0 -7500403 true "" "plot deer-killed-in-trap"

MONITOR
832
440
959
485
Needs-based hunters
count hunters with [motivation = \"needs\"]
17
1
11

MONITOR
961
440
1094
485
Environmental hunters
count hunters with [motivation = \"environmental\"]
17
1
11

MONITOR
1096
440
1216
485
Recreational hunters
count hunters with [motivation = \"recreation\"]
17
1
11

SWITCH
234
32
413
65
needs-hunters?
needs-hunters?
0
1
-1000

SWITCH
234
69
413
102
environmental-hunters?
environmental-hunters?
0
1
-1000

SWITCH
234
107
413
140
recreational-hunters?
recreational-hunters?
0
1
-1000

SWITCH
253
196
401
229
risky-hunting?
risky-hunting?
1
1
-1000

MONITOR
442
443
552
488
NIL
deer-road-deaths
17
1
11

MONITOR
556
443
654
488
NIL
risky-hunting
17
1
11

SWITCH
240
149
401
182
archery-season?
archery-season?
0
1
-1000

MONITOR
442
493
573
538
NIL
deer-killed-in-trap
17
1
11

SLIDER
23
142
203
175
number-trappers
number-trappers
0
10
3.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model is an abstraction of Huntley Meadows Park in Fairfax County, Virginia. The purpose of the model is to simulate the effect of hunters during archery season on the population of White Tail Deer in the park and residential area that borders it.

The deer agents of this model move around the landscape and consume energy from the patches. This behavior is based on the Optimal Foraging Theory. The energy available at each patch is heterogeneous within a range that depends on whether the area is classified as Parkland or Residential. Hunters shoot deer until they achieve their individual maximum kill number, at which point they leave the simulation.

## HOW IT WORKS AND HOW TO USE IT

The landscape of the model is divided into three sections: Parkland, Residential, and Road. Each patch represents a 250 x 250 square foot area. Patches in the Parkland and the Residential area generally have the same range of energy available for deer to consume. However, when the switch ACORN-YEAR? is on, patches in the Parkland are assigned a higher range of energy available. This represents a season of high acorn production and motivates the deer to remain in the park. Road patches have zero energy available for deer to eat.

Use the INITIAL-NUMBER-HERDS slider to set the number of deer herds at setup. Each herd represents a random number of deer between 1 to 5 total, although the icon only visually depicts one. The INITIAL-NUMBER-HUNTERS slider determines the number of hunters at setup, some number of which may be subdivided into trappers as set by the NUMBER-TRAPPERS slider.

Trappers are a subset of hunters who have a very high max-kill number, allowing them to kill essentially as many deer as they want. However, trappers are only in the model when the TRAPPING? switch is on. When this switch is on, a garden is setup in the parkland with very high-yield energy from patches, motivating deer to graze there. Traps are used in Huntley Meadows Park to allow hunters easier kills, and are somewhat controversial for this reason.

In addition to trappers, there are three other types of motivations for hunters: needs, environmental, and recreational hunting. Needs hunters have a max-kill in the range of [1,2], environmental hunters in the range of [3,5], and recreational hunters in the range of [6,11]. The user can determine which kinds of hunters are in the simulation using the NEEDS-HUNTERS?, ENVIRONMENTAL-HUNTERS?, and RECREATIONAL-HUNTERS? switches.

Deer deaths are also effected by the road patches, which represent Route 1. When a deer agent is near the road, it will die with a probability of 1 in 105 chance (based on highway data). Hunters can never shoot deer on the road or within one patch of the road, as this is illegal in Virginia. When the RISKY-HUNTING? switch is on, however, hunters are allowed to shoot deer in the Residential area, otherwise they are restricted to hunting in the Parkland only.

Finally, the switch ARCHERY-SEASON? limits the model to running for only 240 ticks. This is because the archery hunting season in Fairfax County is about 8 months long. In this model, one tick represents one day and so the hunting season can be abstracted as 240 ticks (representing 240 days).

## THINGS TO TRY

How is the behavior of the deer different when the ACORN-SWITCH? is on versus off? Do the deer tend to gather in Huntley Meadows park during acorn years as demonstrated in the real world?

What happens when RISKY-HUNTING? is on, holding all else constant? Do more or less hunters achieve their max-kill parameter? Does the behavior of the deer change depending on the status of this switch?

Do the different hunter motivations (needs, environmental, and recreational) seem to have a strong impact on the simulation? In other words, do certain max-kill parameters significantly effect the change in deer population?

Are the trappers more successful that the other hunters? Do they kill more deer proportionally to the other hunters and more consistently over the course of the simulation?
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

deer
false
15
Polygon -6459832 true false 200 193 197 249 179 249 177 196 165 165 135 165 90 150 78 179 72 211 49 209 48 181 37 149 25 120 45 105 75 90 103 84 165 105 195 120 240 60 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -6459832 true false 73 210 86 251 62 249 48 208
Polygon -6459832 true false 25 114 15 120 15 135 30 150 39 123
Rectangle -7500403 true false 15 90 30 120
Polygon -7500403 true false 225 60 225 75 225 60 240 75 225 75 240 75 225 60
Line -7500403 false 210 60 210 75
Line -7500403 false 210 60 240 75
Line -7500403 false 210 75 240 75
Polygon -7500403 true false 210 60 210 75 240 75 210 60 240 75
Polygon -7500403 true false 240 60 255 45 255 75
Rectangle -16777216 true false 240 75 255 90

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>deer-killed-on-trap</metric>
    <enumeratedValueSet variable="recreational-hunters?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="environmental-hunters?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risky-hunting?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-herds">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="needs-hunters?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trapping?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archery-season?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acorn-year?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-trappers">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-hunters">
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Presentation results" repetitions="50" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="240"/>
    <metric>initial-total-lives</metric>
    <metric>needs-counter + environ-counter + recreat-counter + deer-killed-in-trap</metric>
    <metric>needs-counter</metric>
    <metric>environ-counter</metric>
    <metric>recreat-counter</metric>
    <metric>deer-killed-in-trap</metric>
    <metric>count deers-on parkland</metric>
    <metric>(count deers) - (count deers-on parkland)</metric>
    <metric>count hunters with [motivation = "needs"]</metric>
    <metric>count hunters with [motivation = "environmental"]</metric>
    <metric>count hunters with [motivation = "recreational"]</metric>
    <metric>deer-road-deaths</metric>
    <metric>risky-hunting</metric>
    <enumeratedValueSet variable="environmental-hunters?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-trappers">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="recreational-hunters?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-herds">
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="needs-hunters?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trapping?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="acorn-year?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-hunters">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="risky-hunting?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="archery-season?">
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
