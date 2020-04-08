globals [valence-radius]

;; turtle properties are explained in detail in the information tab
turtles-own [
  own-valence
  own-salience
  group-valence
  group-max-salience
  group-id
  stay-in-group
  neighbor-list
  ordered-neighbors
  ordered-neighbors-2
  stay-group-level
]

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-patches
  setup-turtles
  ; set the valence-radius, ie the distance that agents will look at to consider their neighborhood.
  ; Maybe this could become a user input if we want to let users mess around with things?
  set valence-radius 2

  if (version = "extremism-model") [
    set valence-radius 2
  ]
end

to setup-patches
  ask patches [ set pcolor white]
end

; create 100 turtles, randomly distribute on board, give them random initial values (uniformly distributed)
; should consider whether to do non-uniform distribution, though uniform seems to make as much sense
to setup-turtles
  create-turtles 100
  ask turtles [ setxy random-xcor random-ycor ]
  ask turtles [ set own-valence random 100 ]
  ask turtles [ set color (120 + (own-valence / 10) ) ]
  if (version = "extremism-model") [
    ask turtles [ set own-salience random 100 ]
    ask turtles [ set size ( .65 + (own-salience / 100) ) ]
  ]
  ask turtles [ set stay-in-group 0 ]
  ask turtles [ set stay-group-level 5 ]
end

; add a go-once because the model moves fast and figures are better this way
to go-once
  go
end

; move (or stay still if in group), check the neighbors and then change valence if that is necessary in
; this model version (in the basic, no updating occurs)
to go
  ask turtles [if stay-in-group < 1 [
  move-turtles ]
  ]

  check-neighbor-valence

  update-valence

  do-plots
end

; most basic random walk there is
to move-turtles
    right random 360
    forward 1
end

;; we need to check the valence state of the neighbors within some radius
;; and if the neighbors are close in valence, they will form a group
;; and preferably, stop moving and gather together

;; should I add a step about them moving closer together? that might look better...
to check-neighbor-valence
  ask turtles [
  set neighbor-list turtles in-radius valence-radius
  set group-valence (mean [own-valence] of neighbor-list)
  ]

  ask turtles [

    ; First, make sure length of neighborlist longer than one, so dont just stop moving by itself
    if (count neighbor-list > 1) [
    if (abs (own-valence - group-valence) < stay-group-level) [
    set stay-in-group 1
  ]
    ]
  ]
end



to update-valence
  if (version = "basic-model") [
    ;; do nothing in the basic model
    ask turtles [ set color (120 + (own-valence / 10) ) ]

    ]
  if (version = "norms-model") [
    ;; in the norms, agents become more like the average of the group (and at a rapid rate, simple averaging)
    ask turtles [
  if (stay-in-group > 0)  [
    set own-valence ( (own-valence + group-valence) / 2 )
  ]

  set color (120 + (own-valence / 10) )
    ]
  ]
  if (version = "extremism-model") [
    ask turtles [

      ; first create a list of ordered neighbors, within radius r, sorted by value of their valences
      ; take that list and if the low valence guy is more extreme than the high valence guy, go low
      ; if vice-versa, then go high
      ; in either case, move more slowly (maintain own at 4/5; change at 1/5)
      ; update colors

    set ordered-neighbors (sort-by [ [?1 ?2] -> [own-valence] of ?1 > [own-valence] of ?2 ] (turtles in-radius valence-radius ) )
    ;set ordered-neighbors-2 (sort-by [ [own-valence] of ?1 < [own-valence] of ?2] (turtles in-radius valence-radius ) )

    ifelse ( [own-valence] of (last ordered-neighbors) < (100 - [own-valence] of (first ordered-neighbors) ) ) [
    ;;set ordered-neighbors ( sort-by [own-salience] (turtles with [member? self ordered-neighbors]) )
    ;;set group-max-salience ( [own-valence] of (first ordered-neighbors) )
    set own-valence ( ((4 * own-valence)  + ( [own-valence] of (last ordered-neighbors) ) )/ 5 )
    ] [
    set own-valence ( ((4 * own-valence)  + ( [own-valence] of (first ordered-neighbors) ) )/ 5 )
    ]

    set color (120 + (own-valence / 10) )
    set size ( .65 + (own-salience / 100) )

    ]
  ]
end


to do-plots
  ;; we just want to have an example of a particular individual, rather than means (which disguise a lot of the
  ;; movement. we pick turtle-1, because we want it to be consistent and it doesn't really matter since
  ;; all other distribution of features is random
  set-current-plot "Valences"
  set-current-plot-pen "turtle-1"
  plot [own-valence] of turtle 1
  set-current-plot-pen "neighbors"
  plot [group-valence] of turtle 1

  ;; for the standard deviation we obviously have to look at the population as a whole. Nice that stdev is built in.
  set-current-plot "Stdev"
  set-current-plot-pen "default"
  plot (standard-deviation [own-valence] of turtles)

end
@#$#@#$#@
GRAPHICS-WINDOW
216
11
757
553
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
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
8
10
71
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

BUTTON
9
52
72
85
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

BUTTON
82
53
159
86
NIL
go-once
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
9
94
213
139
version
version
"basic-model" "norms-model" "extremism-model"
2

PLOT
11
156
211
306
Valences
time
valence
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"turtle-1" 1.0 0 -955883 true "" ""
"neighbors" 1.0 0 -11221820 true "" ""

PLOT
11
318
211
468
Stdev
time
standard deviation
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

@#$#@#$#@
## WHAT IS IT?

This model demonstrates the role of emotion in group formation and behavior. In the most basic versions, agents move and at each step they check the emotional states of their neighbors. If the average of their neighbors' emotions is within some bound of their own, then they stop moving and stay with those emotionally similar neighbors.

There are also two other models, developed on the basis of psychological research. The first is the norms model, in which the group imposes norms, so that the individual members become more similar to the group's values with time.

In the second, extremism model, the group provides reassurance and emotionally extreme members have a greater influence, so that members of the group become more emotionally extremem with time.

## HOW IT WORKS

We will explain how the model works by outlining two aspects, the properties of the agents and their behaviors.

Agent attributes:

Agents have several features. First, they are located in a position on the map and thus given an (x-,y-)coordinate. The map is actually a 40x40 unit torus, wrapping around both the horizontal and vertical axes. The agents have several properties related strictly to themselves:
{Own-valence}: the agent's own valence value
{Own-salience}: the agent's own salience value
These values take the form of a uniformly-distributed random number between 0 and 100. Because valence and salience do not have any ``real" values, it is reasonable to assign the artificial values in this way. However, exploration of whether a uniform distribution is more or less realistic than a normal distribution could also be explored.

These values are reflected in the visualization of the model. The agents have a single color whose brightness models the value of valence that the agent has, while its size shows the agent's salience. Lighter colors mean higher valence, while darker colors have lower valence.

Agents are also provided some radius valence-radius, that they will use to check for any neighbors. It is possible to establish a simpler Moore or von Neumann neighborhood, but we chose for this model to  a greater flexibility of movement through space.

The agents also have a number of features that provide them with information about their neighbors and help them make decisions about those neighbors:
{Neighbor-list}: the list of all other agents within radius r of an agent
{Group ID: if the agent is in a group, will provide ID -- this feature is not operational at present
{Stay-group-level}: how close an agent's valence must be to the group in order to join the group}
Of those features, the most involved is the stay-group-level. This value is set by the user. At each round, if the agent has neighbors, it calculates their average valence. If the difference between the agent's and the group's valences are smaller than this cutoff, the agent will join the group.

Finally, the agent makes calculations about its neighbors and group members, where we abbreviate the valence-radius with r:
{Group-valence}: the average valence of all agents within radius r of the agent
{Group-salience}: the average salience of all agents within radius r
{Group-max-salience}: the maximum salience of any agent within radius r
{Stay-in-group}: a binary for whether an agent will stay with its group in this round
These four attributes are calculated based on the values of the properties of neighbors or group members near each agent.

Agent behaviors:

We will also outline the behaviors the agents use. The default behavior of each agent is to make a turn of a randomly selected number of degrees (between 0 and 360) and then move forward in that direction one step. This is a basic form of a simple random walk.

At each step, the agents update their information about their neighbors. For any neighbor within the radius, valence-radius, that they consider, they add that agent to their neighbor-list list. Then, they calculate a number of values (group-valence, group-salience, and group-max-salience) using simple averages and maximum values from the agents who were added to that list.

Next the agents determine if they wish to stay in a group with their current neighbors. Using the stay-group-level value as a cutoff, they calculate the absolute value of the difference between the group's valence and their own. If the difference is small enough to be below the cutoff, that is, if the agent is sufficiently similar to those around it, it will stop moving. For the simplest model, that is the entire process.

## HOW TO USE IT

The model is extremely straightforward to use. Simply select a model type (the basic, norms or extreme model), press setup and then go. All of the changes necessary to model different behaviors are made automatically in the model type selection.

## THINGS TO NOTICE

There are several things to note, outlined in greater depth in the paper. But I will suggest in very rough outlines those aspects here.

For the basic model, note how the edges of the groups are often gradiated. Unlike the other models, there is no sharp distinction and similar-enough but different agents will often end up on the edges of groups.

For the norms model, note that the standard deviation generally decreases as the groups form, although the groups will have many different median valence values.

For the extremism model, note how moderate agents who are not quickly incorporated into a group will often travel for very long periods of time before finding a group (because the values are already so extreme).

## THINGS TO TRY

This model was designed with aesthetics and extreme user-friendliness in mind. There are no things for the user to try without changing the actual programming logic.

## EXTENDING THE MODEL

There are several interesting extensions. The easiest would be the creation of "leaders" who have a greater effect on group emotion than others (without necessarily having extreme feelings).

The most interesting would be the incorporation of environmental factors, which could better model the "origins" aspect Kagan highlights (which is explained in the paper).

Another good extension might be to make negative groups more likely to splinter.

## NETLOGO FEATURES

This model does not make use of any particularly unusual NetLogo features, though the group ID is not operational at present because of NetLogo difficulties in determining and updating the feature.
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
