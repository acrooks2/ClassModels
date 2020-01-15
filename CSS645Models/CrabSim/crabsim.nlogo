;; CrabSim v1.0
;; by Ellen Badgley
;; GMU - CSS 645 (Spatial Agent-Based Modeling)

;; This model is a (stylized) exploration of the optimality of foraging behavior in sand-bubbler crabs (specifically Scopimera inflata)
;; compared to a theoretical optimal forager within the same environment and with the same feeding area constraints.  It was inspired by
;; Zimmer-Faust, R.K., 1987. Substrate selection and use by a deposit-feeding crab. Ecology 68, 955–970.
;; See the accompanying paper for full explanations.
;;
;; Code examples (for color-coded histogram) adapted from:
;; Isaac, Alan G. 2011. NetLogo simulation: an introduction. https://subversion.american.edu/aisaac/notes/netlogo-intro.xhtml.

;; Breeds
breed [crabs crab]  ;; The main agent, representing a crab-like organism.
breed [pellets pellet]  ;; A sand pellet (currently only a marker of where a crab has fed).
breed [burrows burrow]  ;; The central burrow object, used only as a graphic indication.

;; Global variables
globals [
  food-mean       ;; The mean food amount; set to 1.0 for this simulation.
  foraging-radius ;; (Movement) The radius of units within which a crab forages; set to 20.
  step-distance   ;; (Movement) Travel distance for a SBC-like forager -- set to 0.9 (from initial calibration).
  angle-increment ;; (Movement) Angle at which each successive trip out (or in) is made -- set to 2.5 (from initial calibration).
  feeding-proportion ;; (Feeding) Amount of the food on the patch that the crab will take -- set to 1.0 (all) for this simulation.
  total-food-in-radius     ;; The sum total of the food within the allowed radius.
  num-forageable-patches   ;; The number of patches with a food-amount greater than the foraging-threshold.
  ]

;; Crab variables
crabs-own [
  foraging-method ;; A string describing the foraging method of the crab, either "SBC-like" or "optimal".
  total-food         ;; (Output) Total food taken by the crab.
  total-rotation     ;; (Output) Total degrees through which the SBC-like crab has foraged.
  total-distance-traveled ;; (Output) Total distance traveled by the crab.
  total-patches-foraged ;; (Output) Total patches foraged by the crab.
  total-patches-visited ;; (Output) Total patches visited by the crab.
  done-foraging?
  dest-patch ;; Destination patch, for the optimal forager only
  ]

;; Patch variables
patches-own [
  patch-food-amount-sbc ;; Amount of food available to the SBC-like forager
  patch-food-amount-optimal ;; Amount of food available to the optimal forager
  sbc-visited? ;; Has the SBC-like forager visited this patch?
  optimal-visited? ;; Has the optimal forager visited this patch?
  ]

;; Setup simulation and all agents
to setup
  clear-all
  setup-globals  ;; Global variables
  setup-patches  ;; Patches
  setup-turtles  ;; Turtles

  ;; Tell the optimal forager to pick its first target (the richest patch)
  ask crab 2 [set dest-patch max-one-of [patches in-radius foraging-radius] of patch 0 0 [patch-food-amount-optimal]]

  recolor-patches
  reset-ticks
end

;; Setup global variables, populating fixed values.
to setup-globals
  set foraging-radius 20
  set step-distance 0.8
  set angle-increment 2.5
  set food-mean 1.0
  set feeding-proportion 1.0
end

;; Setup patches
to setup-patches

  ;; Get the actual std. dev. of food distribution (in cases where food amounts aren't 1.0)
  let food-stddev food-mean * food-coeff-of-variation

  ;; The distribution of food values across patches depends on the food distribution method chosen.
  ;; Random: food values follow a normal distribution (food-mean and food-stddev)
  if food-distribution = "random" [
    ask patches [set patch-food-amount-sbc random-normal food-mean food-stddev]
  ]

  ;; Constant: all food values are equal to food-mean
  if food-distribution = "constant" [
    ask patches [set patch-food-amount-sbc food-mean]
  ]

  ;; Experimental set up "A" (Zimmer-Faust 1987): natural substrate (normal distribution) with two "empty dishes" 180 degress apart.
  if food-distribution = "zimmer-faust A" [

    ;; Start with a normal/random distribution
    ask patches [set patch-food-amount-sbc random-normal food-mean food-stddev]

    ;; Then, zero out food amounts in the two circles
    ask patch 0 foraging-radius [
      ask patches in-radius (foraging-radius / 2) [
        set patch-food-amount-sbc 0.0
      ]
    ]
    ask patch 0 (foraging-radius * -1) [
      ask patches in-radius (foraging-radius / 2) [
        set patch-food-amount-sbc 0.0
      ]
    ]
  ]

  ;; Experimental set up "B" (Zimmer-Faust 1987): sterilized substrate with two "dishes" of natural substrate 180 degress apart.
  if food-distribution = "zimmer-faust B" [

    ;; Start with no food
    ask patches [set patch-food-amount-sbc 0.0 ]

    ;; Set random food within the two circles
    ask patch foraging-radius 0 [
      ask patches in-radius (foraging-radius / 2) [
        set patch-food-amount-sbc random-normal food-mean 0.1
      ]
    ]
    ask patch (foraging-radius * -1) 0 [
      ask patches in-radius (foraging-radius / 2) [
        set patch-food-amount-sbc random-normal food-mean 0.1
      ]
    ]
  ]

  ;; Make sure that the optimal forager and the SBC-like forager have the same food distribution, and also set the "visited?" flags to false
  ask patches [
    set patch-food-amount-optimal patch-food-amount-sbc
    set sbc-visited? false
    set optimal-visited? false
  ]

  ;; Some convenience methods:
  let temppatches [patches in-radius foraging-radius] of patch 0 0
  ;; Count the total food within the foraging radius.
  set total-food-in-radius sum [patch-food-amount-sbc] of temppatches
  ;; Count the patches that can be fed upon (food amount greater than feeding-threshold).  This helps determine when the crab is "done".
  set num-forageable-patches count temppatches with [patch-food-amount-sbc > ((feeding-threshold / 100.0) * food-mean)]

end

;; Update and recolor patches: show food values in yellow for either the optimal or sbc-like crab, as chosen.
to recolor-patches
  let mfood food-mean * 2
  ifelse (crab-to-show = "optimal") [
    ask patches [set pcolor scale-color yellow patch-food-amount-optimal mfood 0.0]
  ]  [
    ask patches [set pcolor scale-color yellow patch-food-amount-sbc mfood 0.0]
  ]
end


;; Setup turtles (in this case only crab and burrow).
to setup-turtles

  ;; Setup burrow - no behavior, just a place-holder.
  create-burrows 1 [
    set color black
    set shape "circle"
    set size 1
  ]

  ;; Setup crabs (2): one optimal, one SBC-like.
  create-crabs 2  [
    set color red
    set size 2
    set heading random 360
    set total-food 0
    set total-rotation 0
    set total-distance-traveled 0
    set total-patches-foraged 0
    set total-patches-visited 0
    set done-foraging? false
    crab-move-forward 1
  ]

  ;; Tell the crabs which foraging methods they will use.
  ask crab 1 [
    set foraging-method "sbc-like"
    ]

  ask crab 2 [
    set color blue
    set foraging-method "optimal"
    ]
end

;; Helper functions to move the crab AND add the distance traveled to its running total.

;; Move forward
to crab-move-forward [dist]
  forward dist
  set total-distance-traveled total-distance-traveled + dist
end

;; Jump to a coordinate
to crab-jump-xy [x y]
  set total-distance-traveled total-distance-traveled + distancexy x y
  setxy x y
end

;; Jump to a patch
to crab-jump-patch [curr-dest-patch]
  set total-distance-traveled total-distance-traveled + distance curr-dest-patch
  move-to curr-dest-patch
end

;; Crab move method: will be called at every tick.
to move

  ;; Determine if the crab is done foraging: it has (SBC-like) completed a full circle, or (all) harvested all the available patches.
  if (total-rotation >= 360 or (total-patches-foraged >= num-forageable-patches)) [
    set done-foraging? true
    if (foraging-method = "optimal") [
      move-to patch 0 0
    ]
    stop
  ]

  ;; Movement method for the SBC-like crab (out and back, around the circle).
  if (foraging-method = "sbc-like") [

    ;; First, look ahead and see if the next step will take the crab out of the allowed radius.
    ifelse  ([distancexy 0 0] of patch-ahead step-distance > foraging-radius) [

      ;; The crab is almost outside the safe circle, so it turns right, steps ahead, and turns back towards the burrow.
      let new-dist 2 * PI * foraging-radius / (360 / angle-increment)
      rt 90
      crab-move-forward new-dist
      facexy 0 0

      ;; Increment the total-rotation.
      set total-rotation total-rotation + angle-increment

    ] [
      ;; Otherwise, just step forward.
      crab-move-forward step-distance
    ]


    if (not sbc-visited?) [
        set sbc-visited? true
        set total-patches-visited total-patches-visited + 1
      ]

    ;; Om nom nom.
    feed

    ;; Is the crab too close to the burrow?  If so, jump to the burrow, then turn around.
    if (distancexy 0 0) < 1.0 [
      crab-jump-xy 0 0
      set heading heading + 180 + angle-increment
      set total-rotation total-rotation + angle-increment
      crab-move-forward 1
    ]

  ]

  ;; Optimal forager
  if (foraging-method = "optimal") [
    ;; Face the destination patch
    face dest-patch

    ;; Jump to the destination patch
    crab-jump-patch dest-patch

     ;; Change the visited? flag on the patch and increment the crab's total-patches-visited count, if appropriate.
     ;; (The optimal forager should never visit the same patch twice.)
     if (not optimal-visited?) [
        set optimal-visited? true
        set total-patches-visited total-patches-visited + 1
      ]

    ;; Nom nom.
    feed

    ;; Pick a new dest-patch.
    set dest-patch max-one-of [patches in-radius foraging-radius] of patch 0 0 [patch-food-amount-optimal]
  ]
end

;; Do feeding
to feed

  ;; Sanity check: if the crab has somehow moved to a patch outside the foraging radius, don't feed.
  if not member? patch-here [patches in-radius foraging-radius] of patch 0 0 [
    stop
  ]

  let did-feed? false

  ;; Feeding is the same for both "SBC-like" and "optimal" crabs; the only difference is the patch variable they examine for food content,
  ;; since there are separate layers for both agents.

  ;; SBC-like forager
  if (foraging-method = "sbc-like") [

      ;; Check to see that the patch-food-amount exceeds the foraging threshold.  If so, feed.
      if (patch-food-amount-sbc > (feeding-threshold / 100.0) * food-mean) [

        let current-food-taken patch-food-amount-sbc * (feeding-proportion) ;; Calculate the food to take
        set total-food total-food + current-food-taken ;; Increment the crab's total-food
        set patch-food-amount-sbc patch-food-amount-sbc - current-food-taken ;; Remove food from patch

        ;; Optionally, leave a sand pellet to show that feeding has occurred here
        if (show-food-pellets? and crab-to-show = "sbc-like") [
          hatch-pellets 1 [
            set color red
            set shape "circle"
            set size 0.75
          ]
        ]

        set did-feed? true
      ]
    ]

    ;; Optimal forager
    if (foraging-method = "optimal") [

      ;; Check to see that the patch-food-amount exceeds the foraging threshold.  If so, feed.
      if (patch-food-amount-optimal > (feeding-threshold / 100.0) * food-mean) [

        let current-food-taken patch-food-amount-optimal * (feeding-proportion) ;; Calculate the food to take
        set total-food total-food + current-food-taken ;; Increment the crab's total-food
        set patch-food-amount-optimal patch-food-amount-optimal - current-food-taken ;; Remove food from patch

        ;; Optionally, leave a sand pellet to show that feeding has occurred here
        if (show-food-pellets? and crab-to-show = "optimal") [
          hatch-pellets 1 [
            set color blue
            set shape "circle"
            set size 0.75
          ]
        ]

        set did-feed? true
      ]
    ]

    ;; If feeding occurred, increment total-patches-foraged
    if did-feed? [
      set total-patches-foraged total-patches-foraged + 1
    ]
end

;; step
to step
  move
end

;; Update the bar chart of food-by-distance.
;; Code for color-coded bars adapted from:
;; Isaac, Alan G. 2011. NetLogo simulation: an introduction. https://subversion.american.edu/aisaac/notes/netlogo-intro.xhtml.
to update-food-histogram
  set-current-plot "Food by Distance Traveled"
  plot-pen-reset
  create-temporary-plot-pen "temp"
  set-plot-pen-mode 1     ;; bar mode
  set-plot-pen-color red
  plot [total-food / total-distance-traveled] of crab 1
  set-plot-pen-color blue
  plot [total-food / total-distance-traveled] of crab 2
end

;; Go!
to go

  if not any? turtles [ stop ]
  ;; if both crabs are done foraging, the simulation ends
  if ([done-foraging?] of crab 1 and [done-foraging?] of crab 2) [
    stop
  ]

  ask crabs [step]

  ;; Recolor display and update plots
  recolor-patches
  update-food-histogram
  tick

end
@#$#@#$#@
GRAPHICS-WINDOW
395
10
893
529
30
30
8.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
ticks
30.0

CHOOSER
15
20
355
65
food-distribution
food-distribution
"random" "constant" "zimmer-faust A" "zimmer-faust B"
0

BUTTON
25
280
92
313
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
155
280
218
313
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
285
280
348
313
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

SWITCH
15
195
170
228
show-food-pellets?
show-food-pellets?
0
1
-1000

SLIDER
15
130
355
163
feeding-threshold
feeding-threshold
0
100
60
10
1
percent
HORIZONTAL

PLOT
905
10
1315
260
Cumulative Food by Proportion of Habitat Harvested
Proportion of Habitat Harvested
Cumulative Food
0.0
1.0
0.0
1.0
false
true
"" ""
PENS
"sbc-like" 1.0 0 -2674135 true "" "plotxy ([total-patches-foraged] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0) ([total-food] of crab 1 / total-food-in-radius)"
"optimal" 1.0 0 -13345367 true "" "plotxy ([total-patches-foraged] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0) ([total-food] of crab 2 / total-food-in-radius)"
"pen-2" 1.0 0 -7500403 false "" ";; we don't want the \"auto-plot\" feature to cause the\n;; plot's x range to grow when we draw the axis.  so\n;; first we turn auto-plot off temporarily\nauto-plot-off\n;; now we draw an axis by drawing a line from the origin...\nplotxy 0 0.5\n;; ...to a point that's way, way, way off to the right.\nplotxy 10 0.5\n;; now that we're done drawing the axis, we can turn\n;; auto-plot back on again"
"pen-3" 1.0 0 -7500403 false "" ";; we don't want the \"auto-plot\" feature to cause the\n;; plot's x range to grow when we draw the axis.  so\n;; first we turn auto-plot off temporarily\nauto-plot-off\n;; now we draw an axis by drawing a line from the origin...\nplotxy 0.5 0\n;; ...to a point that's way, way, way off to the right.\nplotxy 0.5 10\n;; now that we're done drawing the axis, we can turn\n;; auto-plot back on again"

SLIDER
15
80
355
113
food-coeff-of-variation
food-coeff-of-variation
0.0
0.5
0.1
0.1
1
NIL
HORIZONTAL

CHOOSER
200
195
355
240
crab-to-show
crab-to-show
"sbc-like" "optimal"
0

PLOT
165
335
375
525
Food by Distance Traveled
NIL
Food Units
0.0
2.0
0.0
1.0
false
false
"" ""
PENS
"sbc-like" 1.0 0 -2674135 true "" ""
"optimal" 1.0 0 -13345367 true "" ""

PLOT
905
270
1315
525
Cumulative Food by Proportion of Habitat Visited
Proportion of Habitat Visited
Cumulative Food
0.0
1.0
0.0
1.0
false
true
"" ""
PENS
"sbc-like" 1.0 0 -2674135 true "" "plotxy ([total-patches-visited] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0) ([total-food] of crab 1 / total-food-in-radius)"
"optimal" 1.0 0 -13345367 true "" "plotxy ([total-patches-visited] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0) ([total-food] of crab 2 / total-food-in-radius)"
"pen-2" 1.0 0 -7500403 false "" ";; we don't want the \"auto-plot\" feature to cause the\n;; plot's x range to grow when we draw the axis.  so\n;; first we turn auto-plot off temporarily\nauto-plot-off\n;; now we draw an axis by drawing a line from the origin...\nplotxy 0 0.5\n;; ...to a point that's way, way, way off to the right.\nplotxy 10 0.5\n;; now that we're done drawing the axis, we can turn\n;; auto-plot back on again"
"pen-3" 1.0 0 -7500403 false "" ";; we don't want the \"auto-plot\" feature to cause the\n;; plot's x range to grow when we draw the axis.  so\n;; first we turn auto-plot off temporarily\nauto-plot-off\n;; now we draw an axis by drawing a line from the origin...\nplotxy 0.5 0\n;; ...to a point that's way, way, way off to the right.\nplotxy 0.5 10\n;; now that we're done drawing the axis, we can turn\n;; auto-plot back on again"

@#$#@#$#@
## WHAT IS IT?

The purpose of the CrabSim model is to investigate the foraging behavior of sand-bubbler crabs (Scopimera inflata and related species) in light of optimal foraging theory.  The model is based on Zimmer-Faust’s 1987 foraging study of Scopimera inflata, which incorporated empirical observations (including experimental components) and mathematical modeling of observed and optimal crab foraging behavior (Zimmer-Faust, 1987).  The goal of the model’s initial phase of development (CrabSim 1.0) is to evaluate this IBM implementation of a central-place forager against the predictions made by the original mathematical model, identify correspondences and discrepancies, and investigate situations where the IBM implementation may provide an advantage.

## CREDITS AND REFERENCES

This model is based on the mathematical model in:

Zimmer-Faust, R.K., 1987. Substrate selection and use by a deposit-feeding crab. Ecology 68, 955–970.

Code examples (for color-coded histogram) adapted from:

Isaac, Alan G. 2011. NetLogo simulation: an introduction.
https://subversion.american.edu/aisaac/notes/netlogo-intro.xhtml.
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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[total-food / total-distance-traveled] of crab 1</metric>
    <metric>[total-food] of crab 1 / total-food-in-radius</metric>
    <metric>[total-food] of crab 1 / ticks</metric>
    <enumeratedValueSet variable="feeding-threshold">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-food-pellets?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-optimal-forager?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="angle-increment" first="1.5" step="0.5" last="4.5"/>
    <enumeratedValueSet variable="food-distribution">
      <value value="&quot;constant&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-stddev">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="step-distance" first="0.1" step="0.1" last="1.5"/>
  </experiment>
  <experiment name="exp2" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[total-patches-foraged] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-food] of crab 1 / total-food-in-radius</metric>
    <metric>[total-patches-foraged] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-food] of crab 2 / total-food-in-radius</metric>
    <enumeratedValueSet variable="food-distribution">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="food-coeff-of-variation" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="crab-to-show">
      <value value="&quot;sbc-like&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-food-pellets?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="feeding-threshold" first="0" step="20" last="80"/>
    <enumeratedValueSet variable="use-feeding-threshold?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="vary-coeff-of-variation" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[total-patches-foraged] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-patches-visited] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-food] of crab 1 / total-food-in-radius</metric>
    <metric>[total-patches-foraged] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-patches-visited] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-food] of crab 2 / total-food-in-radius</metric>
    <enumeratedValueSet variable="food-distribution">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="food-coeff-of-variation" first="0" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="crab-to-show">
      <value value="&quot;sbc-like&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-food-pellets?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="feeding-threshold">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="vary-feeding-threshold" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>[total-patches-foraged] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-patches-visited] of crab 1 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-food] of crab 1 / total-food-in-radius</metric>
    <metric>[total-patches-foraged] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-patches-visited] of crab 2 / count [patches in-radius foraging-radius] of patch 0 0</metric>
    <metric>[total-food] of crab 2 / total-food-in-radius</metric>
    <enumeratedValueSet variable="food-distribution">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-coeff-of-variation">
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="crab-to-show">
      <value value="&quot;sbc-like&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-food-pellets?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="feeding-threshold" first="0" step="10" last="100"/>
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
