extensions [ gis csv ]
globals [
  supermarkets ;a vector dataset of points for supermarket locations
  notSupermarkets ;a vector dataset points for locations that are in the supermarket data but are marked "F" for supermarkets
  censusBlocks ; a vector dataset of polygons for the outline of census blocks
  wards
  Sj ;a variable from Guy's (1983) gaussian measure for food accessibility
  available-colors ; used in the creation of the voronoi polygons
  accessibility-index-reserve ;used in the creation of the accessibility index
  lorenz-points ;used in the creation of the lorenz curve graph
  temp-mean ; used to make the heat map of accessibility
  people-with-store
]

patches-own [
  GEOID ;the unique ID associated with each census block
  education ;the education value from the census dataset
  population ;the population value from the census dataset
  foodstamps ;the foodstamps value from the census dataset
  poverty ;the poverty value from the census dataset
  centroid? ;is TRUE is the patch is the center of the polygon (i.e. the center of the census block)
  person-here? ;is TRUE is there is a person on the patch...used in the creation of the population of people
  store-score ;the accessibility score for each store for a unique person...one store can have different store-scores becuase it is also unique to each person
  supermarket-here? ;marked TRUE is there is a supermarket on the patch
  notSupermarket-here? ;marked TRUE is there is a store that is not a supermarket on the patch
  obesity
  heartDisease
  overallHealth
  wardName
]

breed [people person]
people-own [
  edu ; [education] of patch-here) / ([population] of patch-here
  fs ; [foodstamps] of patch-here) / ([population] of patch-here
  pov ; [poverty] of patch-here) / ([population] of patch-here
  stores-in-radius ; patch set of patches with supermarket-here? = TRUE or notSupermarket-here? = TRUE
  accessibility ;a persons accessibility score
  countdown ; the number of days before a person "goes to the store"
  my-GEOID
  my-ward
  health
  heart
  overweight
  store-choice
]

breed [points point] ; used in the creation of new supermarkets and the visualization of the voronoi polygons
points-own []



to setup ;load the gis data
  clear-all
  reset-ticks
  gis:load-coordinate-system (word "Data/Shaped DC CensusBlock Data.prj")
  set supermarkets gis:load-dataset "Data/DCSupermarkets.shp" ;;;this is the store location data
  set censusBlocks gis:load-dataset "Data/Shaped DC CensusBlock Data.shp"
  set notSupermarkets gis:load-dataset "Data/DCNOTSupermarkets.shp"
  set wards gis:load-dataset "Data/Shaped Ward and Health Data.shp"
end


to draw ; draw the map and apply the vector data to the rastor in netlogo for the socioeconomic data
  clear-drawing
  reset-ticks
  ; gis:set-world-envelope gis:envelope-of censusBlocks
  gis:set-world-envelope (gis:envelope-union-of ;(gis:envelope-of sites)
    (gis:envelope-of notSupermarkets)
    (gis:envelope-of supermarkets)
    (gis:envelope-of censusBlocks)
    (gis:envelope-of wards)
    )

  ask patches [set pcolor white]

  gis:apply-coverage censusBlocks "GEOIDABM" GEOID
  gis:apply-coverage censusBlocks "POP" population
  gis:apply-coverage censusBlocks "EDU" education
  gis:apply-coverage censusBlocks "POV" foodstamps
  gis:apply-coverage censusBlocks "FOODSTAMPS" poverty

  gis:apply-coverage wards "NAME" wardName
  gis:apply-coverage wards "HEALTHPER" overallHealth
  gis:apply-coverage wards "OBESITYRA" obesity
  gis:apply-coverage wards "HEARTDISE" heartDisease



  ;I would like to make sales volume the value used for the "Sj" variable in the accessibility calculation
  ;unfortunately the VectorDataset must be a polygon dataset; points and lines are not supported...so I'll save this code for later
  ;gis:apply-coverage supermarkets "SALESVOL" sales
  ;gis:apply-coverage notSupermarkets "SALESVOL" sales

  gis:set-drawing-color red
  gis:draw notSupermarkets 2
  mark-notSupermarkets
  gis:set-drawing-color green
  gis:draw supermarkets 3
  mark-supermarkets

  gis:set-drawing-color black
  gis:draw censusBlocks   1

  gis:set-drawing-color orange
  gis:draw wards 2

end



to make-pop ;
  find-centroids
  ask patches with [centroid? = TRUE] [sprout-people (population / populationDenominator) ;denominator of 500 can be changed to make more or less people
    [ set countdown (1 + random 7)
      set shape "circle"
      set color black
      set size .55
      set edu random-normal (([education] of patch-here) / ([population] of patch-here)) 0.139 ;standard deviation drawn from empirical data
      ifelse random-float 1 < edu [set edu 0][set edu 1] ;0 is lower education and 1 means higher education
      set fs random-normal (([foodstamps] of patch-here) / ([population] of patch-here)) 0.063 ;standard deviation drawn from empirical data
      ifelse random-float 1 < fs [set fs 1][set fs 0]
      set pov random-normal (([poverty] of patch-here) / ([population] of patch-here)) 0.057 ;standard deviation drawn from empirical data
      ifelse random-float 1 < pov [set pov 1][set pov 0]
      set my-GEOID ([GEOID] of patch-here)
      set my-ward ([wardName] of patch-here)
      set health random-normal ([overallHealth] of patch-here) 7.199
      set heart ([heartDisease] of patch-here) ;random-normal ([heartDisease] of patch-here) 80.8
      set overweight random-normal ([obesity] of patch-here) 11.15
      ask patch-here [set person-here? TRUE]
      let tempGEOID [GEOID] of patch-here
      if [person-here?] of patch-here = TRUE [move-to one-of patches with [GEOID = tempGEOID]]
    ]
  ]


end



to mark-supermarkets
  ask patches[
    if gis:intersects? supermarkets self [set supermarket-here? TRUE]
  ]
end

to mark-notSupermarkets
  ask patches[
    if gis:intersects? notSupermarkets self [set notSupermarket-here? TRUE]
  ]
end


;to search-for-stores
;  ask people [
;    set stores-in-radius patches in-radius radius-size with [supermarket-here? = TRUE or notSupermarket-here? = TRUE]
;    ]
;end

to calculate-accessibility
  ;search-for-stores
  ;ask people [
  set stores-in-radius patches in-radius radius-size with [supermarket-here? = TRUE or notSupermarket-here? = TRUE]
  ask stores-in-radius
  [
    let dij distancexy ([xcor] of myself) ([ycor] of myself)
    ;show dij
    ifelse notSupermarket-here? = TRUE [set Sj 0.026] [set Sj 1.0]
    set store-score (Sj * exp(0.5 * ((dij * -1) / d*)))
    ;show temp

  ]
  set accessibility sum ([store-score] of stores-in-radius)
  set store-choice max-one-of stores-in-radius [store-score]

  ;show accessibility
  ;]
  ;print "stop"
  ;update-plots
end

to calculate-accessibility-plus
  set stores-in-radius patches in-radius radius-size with [supermarket-here? = TRUE or notSupermarket-here? = TRUE]
  ask stores-in-radius
  [
    let dij distancexy ([xcor] of myself) ([ycor] of myself)
    ;If the agent is determined to have some form of food assistance that will add to the Sj term in the equation and cause the
    ;overall accessibility to increase for that agent regardless of what happens in the rest of the calculation.
    ;Increasing the affordability and overall ability of people to acquire food is a basic function of food assistance
    ;that is reflected in this modification of the Sj term in the accessibility equation.
    ifelse (notSupermarket-here? = TRUE) AND ([fs] of myself = 0) [set Sj 0.026][if (notSupermarket-here? = TRUE) AND ([fs] of myself = 1) [set Sj (0.026 * 1.2)]]
    ifelse (supermarket-here? = TRUE) AND ([fs] of myself = 0) [set Sj 1.0][if (supermarket-here? = TRUE) AND ([fs] of myself = 1) [set Sj (1 * 1.2)]]
    ;Education will increase the Sj term of supermarkets and will decrease the Sj term of non-supermarkets.
    ;Lack of education will increase the Sj term of non-supermarkets and will decrease the Sj term of supermarkets.
    ifelse ((Sj = 0.026) OR (Sj = (0.026 * 1.2))) AND ([edu] of myself = 1) [set Sj (Sj - education-factor) ][if ((Sj = 0.026) OR (Sj = (0.026 * 1.2))) AND ([edu] of myself = 0)[set Sj (Sj + education-factor)]]
    ifelse ((Sj = 1.0) OR (Sj = (1 * 1.2))) AND ([edu] of myself = 1) [set Sj (Sj + education-factor) ][if ((Sj = 1.0) OR (Sj = (1 * 1.2))) AND ([edu] of myself = 0)[set Sj (Sj - education-factor)]]
    ;If the agent is determined to be in poverty then their d* term will be lower and if they are determined to not be in poverty their d* term will be higher.
    ifelse ([pov] of myself = 1) [set store-score (Sj * exp(0.5 * ((dij * -1) / (d* - 0.2))))][set store-score (Sj * exp(0.5 * ((dij * -1) / (d* + 0.2))))]
  ]
  set accessibility sum ([store-score] of stores-in-radius)
  if accessibility < 0 [set accessibility 0]
  set store-choice max-one-of stores-in-radius [store-score]
  ;one-of stores-in-radius with max store-score
end




to voronoi ;Wilensky, U. (2006). NetLogo Voronoi model.
           ;http://ccl.northwestern.edu/netlogo/models/Voronoi.
           ;Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
           ;modified by Harold Walbert, 2016
           ;clear-all
           ;; too dark and too light are hard to distinguish from each other,
           ;; so only use 13-17, 23-27, ..., 133-137
  set available-colors shuffle filter [ ?1 -> (?1 mod 10 >= 3) and (?1 mod 10 <= 7) ]
  n-values 140 [ ?1 -> ?1 ]
  set-default-shape points "circle"
  ask points [set size 0.01]
  ask patches with [supermarket-here? = TRUE] [ make-point ]
  ask patches [ recolor ]
end

to make-point ; patch procedure
  sprout-points 1 [
    set size 0.0001
    set color first available-colors
    set available-colors butfirst available-colors
  ]
end

to recolor  ;; can be patch or turtle procedure
  set pcolor [color] of min-one-of points [distance myself]
end



to go
  ask people [
    set countdown (countdown - 1)
    if countdown = 0 [
      ifelse Calculate-Accessibility-Using-Socioeconomic-Data? = TRUE [calculate-accessibility-plus][calculate-accessibility]
    ]
  ]
  ifelse (max [countdown] of people) <= 0 [
    update-lorenz-and-accessibilityIndex
    set people-with-store people with [store-choice != nobody]
    tick
    ;analyze-food-insecurity
    stop
  ][
  update-lorenz-and-accessibilityIndex
  tick-advance 1
  ]

end


to calculate-accessibility-AllAtOnce ;this code is just from the turtle perspective so the calculate-accessibility button will work
                                     ;search-for-stores
  ask people [
    set stores-in-radius patches in-radius radius-size with [supermarket-here? = TRUE or notSupermarket-here? = TRUE]
    ask stores-in-radius
    [
      let dij distancexy ([xcor] of myself) ([ycor] of myself)
      ;show dij
      ifelse notSupermarket-here? = TRUE [set Sj 0.5] [set Sj 1.0]
      set store-score (Sj * exp(0.5 * ((dij * -1) / d*)))
      ;show temp

    ]
    set accessibility sum ([store-score] of stores-in-radius)
    ;show accessibility
  ]
  ;print "stop"
  update-plots
end



to find-centroids ;code from Yang Zhou and customized by Harold Walbert
  let n 1
  foreach gis:feature-list-of censusBlocks
  [ ?1 -> let center-point gis:location-of gis:centroid-of ?1
    ask patch item 0 center-point item 1 center-point [
      set centroid? true
    ]
    set n n + 1 ]
end

;;This code is a modification of code from Uri Wilensky (Copyright 1998 Uri Wilensky)
;;Modified by Harold Walbert, 2016
;; this procedure recomputes the value of gini-index-reserve
;; and the points in lorenz-points for the Lorenz and Gini-Index plots
to update-lorenz-and-accessibilityIndex
  let sorted-accessibility sort [accessibility] of people
  let total-accessibility sum sorted-accessibility
  let accessibility-sum-so-far 0
  let index 0
  set accessibility-index-reserve 0
  set lorenz-points []

  ;; now actually plot the Lorenz curve -- along the way, we also
  ;; calculate the Gini index.
  ;; (see the Info tab for a description of the curve and measure)
  repeat (count people) [
    set accessibility-sum-so-far (accessibility-sum-so-far + item index sorted-accessibility)
    set lorenz-points lput ((accessibility-sum-so-far / total-accessibility) * 100) lorenz-points
    set index (index + 1)
    set accessibility-index-reserve
    accessibility-index-reserve +
    (index / (count people)) -
    (accessibility-sum-so-far / total-accessibility)
  ]
end




to analyze-food-insecurity
  ask people with [accessibility > mean [accessibility] of people] [set size 2 set color green]
  ask people with [accessibility < mean [accessibility] of people] [set size 1.5 set color yellow]
  ask people with [(accessibility < mean [accessibility] of people) and ((pov > mean [pov] of people) or (fs > mean [fs] of people))] [set size 1 set color orange]
  ask people with [(accessibility < mean [accessibility] of people) and ((pov > mean [pov] of people) or (fs > mean [fs] of people)) and (edu < mean [edu] of people)] [set size 0.55 set color red]
  update-plots
end

to create-one-supermarket
  let CountPoints (count points)
  if mouse-down? = true and mouse-inside? = true
  [create-points 1 [
    setxy mouse-xcor mouse-ycor
    ask patch-here [set supermarket-here? TRUE]
  ]
  ]
  if (count points) > CountPoints [stop]
end


to color-censusBlocks
  ask people [set size 0]
  ask patches with [centroid? = TRUE] [
    let temp-GEOID ([GEOID] of self)
    let temp-agentset (people with [my-GEOID = temp-GEOID])
    if count temp-agentset > 0 [set temp-mean (mean [accessibility] of temp-agentset)]
;    ask patches with [population > 0 and GEOID = temp-GEOID] [set pcolor (temp-mean * 2)] ;this doesn't make as good of a heat map
    ask patches with [population > 0 and GEOID = temp-GEOID] [set pcolor scale-color red temp-mean (min [accessibility] of people) (max [accessibility] of people)]
  ]
end

to health-heatMap
  ask people [set size 0]
  ask patches with [centroid? = TRUE] [
    let temp-GEOID ([GEOID] of self)
    let temp-agentset (people with [my-GEOID = temp-GEOID])
    if count temp-agentset > 0 [set temp-mean (mean [heart] of temp-agentset)]
;    ask patches with [population > 0 and GEOID = temp-GEOID] [set pcolor (temp-mean * 2)] ;this doesn't make as good of a heat map
    ask patches with [population > 0 and GEOID = temp-GEOID] [set pcolor scale-color red temp-mean (min [heart] of people) (max [heart] of people)]
  ]
end

to Educate
  ask people with [edu = 0][if (random 5 = 0) [set edu 1]]
end

to add-supermarkets
 ask patch 7 -14 [set supermarket-here? TRUE]
 ask patch 5 -4 [set supermarket-here? TRUE]
 ask patch 14 -14 [set supermarket-here? TRUE]
 ask patch 21 -5 [set supermarket-here? TRUE]
 ask patch 4 1 [set supermarket-here? TRUE]
 ask patch 22 6 [set supermarket-here? TRUE]
 ask patch 17 10 [set supermarket-here? TRUE]
 ask patch -5 -28 [set supermarket-here? TRUE]
 ask patch -16 32 [set supermarket-here? TRUE]
end
@#$#@#$#@
GRAPHICS-WINDOW
225
10
736
522
-1
-1
5.53
1
10
1
1
1
0
0
0
1
-45
45
-45
45
0
0
1
days
30.0

BUTTON
3
43
58
76
1. setup
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
62
44
117
77
2. draw
draw
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
748
59
828
104
population
count people
17
1
11

MONITOR
745
12
830
57
censusBlocks
count patches with [centroid? = true]
17
1
11

BUTTON
120
45
221
78
3. make-pop
make-pop
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
20
121
192
154
radius-size
radius-size
0
10
6.0
1
1
NIL
HORIZONTAL

BUTTON
48
311
173
344
Show Voronoi Polygons
ask people [set size 0]\nvoronoi
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
832
12
964
57
# of Supermarkets
count (patches with [supermarket-here? = TRUE])
17
1
11

MONITOR
833
59
965
104
# of Convenience Stores
count (patches with [notSupermarket-here? = TRUE])
17
1
11

MONITOR
953
111
1055
156
sum of accessibility
sum ([accessibility] of people)
1
1
11

SLIDER
20
157
192
190
d*
d*
0.3
2.0
1.1
0.1
1
NIL
HORIZONTAL

BUTTON
48
346
174
379
Hide Voronoi Polygons
ask points [die]\nask patches [set pcolor white]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
953
157
1056
202
mean accessibility
mean [accessibility] of people
3
1
11

MONITOR
953
203
1057
248
max accessibility
max [accessibility] of people
3
1
11

MONITOR
954
250
1056
295
min accessibility
min [accessibility] of people
3
1
11

PLOT
748
111
951
295
Histogram of Accessibility
accessibility bins
num people
0.0
5.0
0.0
5.0
true
false
"" "set-histogram-num-bars 10"
PENS
"default" 1.0 1 -16777216 true "" "histogram [accessibility] of people\nset-histogram-num-bars 10"

BUTTON
165
80
220
113
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
6
80
155
113
calculate-accessibility
calculate-accessibility-AllAtOnce
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
749
297
952
461
Lorenz Curve
Pop %
Accessibility %
0.0
100.0
0.0
100.0
false
true
"" ""
PENS
"lorenz" 1.0 0 -2674135 true "" "if ticks > 0 [\nplot-pen-reset\nset-plot-pen-interval 100 / (count people)\nplot 0\nforeach lorenz-points plot\n]"
"equal" 100.0 0 -16777216 true "plot 0\nplot 100" ""

MONITOR
955
297
1056
342
Accessibility-Index
(accessibility-index-reserve / (count people)) / 0.5
3
1
11

PLOT
1061
111
1221
261
Accessibility Measures
NIL
NIL
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -10899396 true "" "plot-pen-reset\nset-plot-pen-color green\nplot count people with [color = green]\nset-plot-pen-color yellow\nplot count people with [color = yellow]\nset-plot-pen-color orange\nplot count people with [color = orange]\nset-plot-pen-color red\nplot count people with [color = red]"

BUTTON
37
383
207
416
Create One Supermarket
create-one-supermarket
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
988
21
1107
54
Accessibility Heat Map
color-censusBlocks
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
988
55
1107
88
Hide Heat Map
ask patches [set pcolor white]\n;ask people with [accessibility > mean [accessibility] of people] [set size 2 set color green]\n;ask people with [accessibility < mean [accessibility] of people] [set size 1.5 set color yellow]\n;ask people with [(accessibility < mean [accessibility] of people) and ((pov > mean [pov] of people) or (fs > mean [fs] of people))] [set size 1 set color orange]\n;ask people with [(accessibility < mean [accessibility] of people) and ((pov > mean [pov] of people) or (fs > mean [fs] of people)) and (edu < mean [edu] of people)] [set size 0.55 set color red]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
42
193
167
253
populationDenominator
300.0
1
0
Number

SLIDER
27
271
199
304
education-factor
education-factor
0
1
0.5
0.1
1
NIL
HORIZONTAL

SWITCH
755
488
1044
521
Calculate-Accessibility-Using-Socioeconomic-Data?
Calculate-Accessibility-Using-Socioeconomic-Data?
0
1
-1000

MONITOR
957
345
1133
390
Percent choosing Supermarkets
100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)
1
1
11

MONITOR
957
392
1134
437
Percent choosing notSupermarkets
100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people)
1
1
11

BUTTON
984
442
1101
475
Show choice of Store
ask people-with-store with [[notSupermarket-here?] of store-choice = TRUE] [set shape \"square\" set size 1.5 set color red]\nask people-with-store with [[supermarket-here?] of store-choice = TRUE] [set shape \"leaf\" set size 1.5 set color green]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
1137
365
1276
410
Supermarket Choice Ratio
(100 * (count people-with-store with [[supermarket-here?] of store-choice = TRUE]) / (count people)) / (100 * (count people-with-store with [[notSupermarket-here?] of store-choice = TRUE]) / (count people))
3
1
11

BUTTON
41
472
118
505
Educate
Educate
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
122
468
218
513
Education Percent
count people with [edu = 1] / count people
2
1
11

BUTTON
83
426
216
459
Add Supermarkets
add-supermarkets
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
10
426
80
459
Recalculate
ask people [set countdown (1 + random 7)]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
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
