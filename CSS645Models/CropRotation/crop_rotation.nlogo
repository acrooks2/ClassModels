extensions [table]

;;;;; Global Variables ;;;;;;
globals [
  crops-list-all
  crops-table-nitrogen-requirements
  crops-table-weeds
  crops-table-disease
  crops-table-harvest-time
  crops-shapes
  crops-table-abbreviations

  crop-yield-totals
  crop-planting-totals
  crop-rule-totals

  rules-list-all

  beet
  buckwheat
  carrot
  cucurbit
  grass
  legume
  lettuce
  lily
  mustard
  nightshade
  rose
  cover
  fallow
]

;;;;; Patch Variables ;;;;;
patches-own [
  patch-id
  patch-nitrogen-level
  patch-crop-history
  patch-current-crop
  patch-available-crops
  patch-crop-harvest-week
  patch-crop-harvest-yield
  patch-previous-crop
  patch-previous-crop-yield
  patch-previous-crop-selection-rule
  patch-crop-weed-loss
  patch-crop-disease-loss
]



to setup

  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-globals
  setup-fields
  setup-turtles

  foreach sort patches [ ?1 ->
    ask ?1 [
      update-patch-label
      set-crop-shape
      update-crop-size
    ]
  ]
end


to go
  do-next-week
  if (verbose-output) [show "-----"]

  tick

  ;my-update-plots
  update1-plots
  if (ticks = 208) [
    stop-simulation
    stop
  ]

end

; Procedure to do clean up at the end of the simulation
to stop-simulation
  foreach sort patches [ ?1 ->
    ask ?1 [
      if (patch-current-crop != fallow)[
        do-harvest-crop
      ]
    ]
  ]
  ; print out end of simulation results.
  let header "Type"
  foreach crops-list-all[ ?1 ->
    set header (word header ":" ?1)
  ]
  set header (word header ":NM:NSD")
  show header
  print-crop-totals
  set header "Type"
  foreach rules-list-all[ ?1 ->
    set header (word header ":" ?1)
  ]
  set header (word header ":NM:NSD")
  show header
  print-crop-rule-totals

end ; harvest all at end


    ; This procedure is called each week.
to do-next-week
  foreach sort patches [ ?1 ->
    ask ?1 [

      if (patch-crop-harvest-week = ticks)[
        ifelse (patch-current-crop = fallow)
        [do-plant-crop]
        [do-harvest-crop]
      ]

      update-patch-label
      set-crop-shape
      update-crop-size

    ]

  ]
end

; Select a crop using the agent rules.  Keep track of history.  Adjust patch visuals.  Set harvest date.
to do-plant-crop

  let patch-to-plant-crop select-crop-to-plant

  ; keep track of rules used
  table:put crop-rule-totals patch-previous-crop-selection-rule ( (table:get crop-rule-totals patch-previous-crop-selection-rule) + 1)

  ; adjust patch nitrogen level
  set patch-nitrogen-level patch-nitrogen-level - table:get crops-table-nitrogen-requirements patch-to-plant-crop

  ; adjust patch color
  set-patch-color

  ; add crop to history (newest crops first)
  set patch-crop-history fput patch-to-plant-crop patch-crop-history

  ; set patch's crop, harvest date
  set patch-current-crop patch-to-plant-crop
  set-patch-crop-harvest-week

  ; show message
  if (verbose-output) [
    print-planting-message]


  ;add planting to total number of plantings.
  table:put crop-planting-totals patch-to-plant-crop ( (table:get crop-planting-totals patch-to-plant-crop) + 1)

end

; Harvest.  Calculate weeds, disease, yield.  Set field to fallow for 5 weeks.
to do-harvest-crop

  ; show message
  if (verbose-output) [print-harvest-message]

  ; calculate the weeds level
  set-patch-crop-weed-loss

  ; calculate the disease level
  set-patch-crop-disease-loss

  ; calculate the yield
  set patch-crop-harvest-yield ( (1 - patch-crop-weed-loss) * (1 - patch-crop-disease-loss))


  ;if (verbose-output) [print-yield]   xxxxx

  ;add yield to totals
  table:put crop-yield-totals patch-current-crop ( (table:get crop-yield-totals patch-current-crop) + patch-crop-harvest-yield)

  ; set crop to fallow for two weeks
  set patch-previous-crop patch-current-crop
  set patch-previous-crop-yield patch-crop-harvest-yield
  set patch-current-crop fallow
  set patch-crop-harvest-week (ticks + 5) ;5 weeks empty period
end


; harvest week is 1/3 chance date in table, 1/3 chance -1 week, 1/3 chance +1 week.
to set-patch-crop-harvest-week
  set patch-crop-harvest-week  ticks + table:get crops-table-harvest-time patch-current-crop + (  (random 3) - 1)
end

; Estimate yield loss to weeds.
  ; Estimate of the weeds is tanh(x) using parameter in weeds table as input.
to set-patch-crop-weed-loss

  let tan-in random-float (table:get crops-table-weeds patch-current-crop)
  set patch-crop-weed-loss get-tanh tan-in

end

; Estimate yield loss to disease.
  ; Estimate of the weeds is tanh(x) using parameter in disease table as input.
to set-patch-crop-disease-loss

  ; Estimate of the weeds is susecptibility * tanh(x)
  let tan-in random-float (table:get crops-table-disease patch-current-crop)
  set patch-crop-disease-loss get-tanh tan-in

end


; List of all crops
to set-all-crops-list
  set crops-list-all (list beet buckwheat carrot cucurbit grass legume lettuce lily mustard nightshade rose cover fallow)
end

; Table of Nitrogen requirements
to set-crops-table-nitrogen-requirements

  set crops-table-nitrogen-requirements table:make
  table:put crops-table-nitrogen-requirements beet 2
  table:put crops-table-nitrogen-requirements buckwheat 2
  table:put crops-table-nitrogen-requirements carrot 6
  table:put crops-table-nitrogen-requirements cucurbit 6
  table:put crops-table-nitrogen-requirements grass 4
  table:put crops-table-nitrogen-requirements legume 2
  table:put crops-table-nitrogen-requirements lettuce 6
  table:put crops-table-nitrogen-requirements lily 6
  table:put crops-table-nitrogen-requirements mustard 6
  table:put crops-table-nitrogen-requirements nightshade 4
  table:put crops-table-nitrogen-requirements rose 4
  ;cover crop adds this amount to the soil
  table:put crops-table-nitrogen-requirements cover -15
  ;fallow needs no nitrogen
  table:put crops-table-nitrogen-requirements fallow 0
end

; Table of weeds levels
to   set-crops-table-weeds
  set crops-table-weeds table:make
  table:put crops-table-weeds beet 0.5
  table:put crops-table-weeds buckwheat 0.5
  table:put crops-table-weeds carrot 0.1
  table:put crops-table-weeds cucurbit 0.5
  table:put crops-table-weeds grass 1.5
  table:put crops-table-weeds legume 0.5
  table:put crops-table-weeds lettuce 0.8
  table:put crops-table-weeds lily 0.5
  table:put crops-table-weeds mustard 1.5
  table:put crops-table-weeds nightshade 0.5
  table:put crops-table-weeds rose 0.1
  table:put crops-table-weeds cover 0.1
  table:put crops-table-weeds fallow 0
end

; Table of disease levels
to set-crops-table-disease
  set crops-table-disease table:make
  table:put crops-table-disease beet 0.5
  table:put crops-table-disease buckwheat 0.25
  table:put crops-table-disease carrot 0.5
  table:put crops-table-disease cucurbit 0.5
  table:put crops-table-disease grass 0.8
  table:put crops-table-disease legume 1.0
  table:put crops-table-disease lettuce 0.8
  table:put crops-table-disease lily 1.0
  table:put crops-table-disease mustard 0.25
  table:put crops-table-disease nightshade 0.8
  table:put crops-table-disease rose 0.8
  table:put crops-table-disease cover 0.5
  table:put crops-table-disease fallow 0
end

; Table of weeks needed to harvest
to set-crops-table-harvest-time
  set crops-table-harvest-time table:make
  table:put crops-table-harvest-time beet 8
  table:put crops-table-harvest-time buckwheat 12
  table:put crops-table-harvest-time carrot 13
  table:put crops-table-harvest-time cucurbit 8
  table:put crops-table-harvest-time grass 12
  table:put crops-table-harvest-time legume 9
  table:put crops-table-harvest-time lettuce 6
  table:put crops-table-harvest-time lily 15
  table:put crops-table-harvest-time mustard 10
  table:put crops-table-harvest-time nightshade 10
  table:put crops-table-harvest-time rose 10
  table:put crops-table-harvest-time cover 6
  ; farmers can let their land lay fallow for 6 weeks (single growing period)
  table:put crops-table-harvest-time fallow 6
end

; Table of abbreviations for crops
to   set-crops-table-abbreviations
  set crops-table-abbreviations table:make
  table:put crops-table-abbreviations beet "Be"
  table:put crops-table-abbreviations buckwheat "Bu"
  table:put crops-table-abbreviations carrot "Ca"
  table:put crops-table-abbreviations cucurbit "Cu"
  table:put crops-table-abbreviations grass "Gr"
  table:put crops-table-abbreviations legume "Lg"
  table:put crops-table-abbreviations lettuce "Lt"
  table:put crops-table-abbreviations lily "Li"
  table:put crops-table-abbreviations mustard "Mu"
  table:put crops-table-abbreviations nightshade "Ni"
  table:put crops-table-abbreviations rose "Ro"
  table:put crops-table-abbreviations cover "Co"
  table:put crops-table-abbreviations fallow "Fa"
end

; Table of crop names
to set-crop-names
  set  beet "beet"
  set  buckwheat "buckwheat"
  set  carrot "carrot"
  set  cucurbit "cucurbit"
  set  grass "grass"
  set  legume "legume"
  set  lettuce "lettuce"
  set  lily "lily"
  set  mustard "mustard"
  set  nightshade "nightshade"
  set  rose "rose"
  set  cover "cover"
  set  fallow "fallow"
end

; Table of crop shapes
to set-crop-shapes
  set crops-shapes table:make
  table:put crops-shapes beet "box"
  table:put crops-shapes buckwheat "car"
  table:put crops-shapes carrot "flower"
  table:put crops-shapes cucurbit "leaf"
  table:put crops-shapes grass "person"
  table:put crops-shapes legume "plant"
  table:put crops-shapes lettuce "house"
  table:put crops-shapes lily "sheep"
  table:put crops-shapes mustard "square"
  table:put crops-shapes nightshade "target"
  table:put crops-shapes rose "tree"
  table:put crops-shapes cover "wheel"
  table:put crops-shapes fallow "x"
end


; Selects a crop to plant using the 13 rules listed.
to-report select-crop-to-plant

  let low-yield .1
  let random-fallow 0.05
  let low-nitrogen 2
  let medium-nitrogen 4

  ;1.  Review crop history
  ; remove crop from fields permanently if bad weeds/disease
  if (( (patch-crop-disease-loss > 0.65) or (patch-crop-weed-loss > 0.75) ) and
    patch-previous-crop != cover and patch-previous-crop != fallow) [
 ; show ("-------")
  set patch-available-crops remove patch-current-crop patch-available-crops
    ]

  ; Build a list of the possible crops to plans
  let possible-crops []
  foreach patch-available-crops[ ?1 -> set possible-crops fput ?1 possible-crops ]

  ;2.  If there are no possible crops to plant, let the field lay fallow.
  if empty? possible-crops [
    set patch-previous-crop-selection-rule "Rule_2"
    report fallow
  ]

  ;3.  Fallow fields for weed or pest control.
  ; Note: This is the rule that will be used at field setup

  if ( (patch-previous-crop-yield < low-yield) and (patch-previous-crop != fallow)) [
    set patch-previous-crop-selection-rule "Rule_3"
    set patch-previous-crop-yield 1
    report fallow
  ]

  ;4.  Random fallow periods.
  if random-float 1 < random-fallow [
    set patch-previous-crop-selection-rule "Rule_4"
    report fallow
  ]

  ;5.  Build soil fertility with cover crops
  if patch-nitrogen-level < low-nitrogen [
    set patch-previous-crop-selection-rule "Rule_5a"
    report cover
  ]

  if (patch-nitrogen-level < medium-nitrogen and (random-float 1 < .25) ) [
    set patch-previous-crop-selection-rule "Rule_5b"
    report cover
  ]


  ;6.  Only plant a crop when sufficient nutrients exist in the soil.
  ; remove any crops that require too much nitrogen
  foreach possible-crops[ ?1 ->

    if ( (table:get crops-table-nitrogen-requirements ?1) > patch-nitrogen-level)[
      set possible-crops remove ?1 possible-crops
    ]
  ]

  if empty? possible-crops [
    set patch-previous-crop-selection-rule "Rule_6a"
    report fallow
  ]
  if ( (length possible-crops) = 1) [
    set patch-previous-crop-selection-rule "Rule_6b"
    report first possible-crops
  ]

  ; 7.  Never grow a crop consecutively
  if (member? patch-previous-crop possible-crops)[
    set possible-crops remove patch-previous-crop possible-crops
  ]

  if empty? possible-crops [
    set patch-previous-crop-selection-rule "Rule_7a"
    report fallow
  ]
  if ( (length possible-crops) = 1) [
    set patch-previous-crop-selection-rule "Rule_7b"
    report first possible-crops
  ]

  ;8.  Single crops less than 25% of total farm
  foreach possible-crops[ ?1 ->
    if ( (count patches with [patch-current-crop = ?1] + 1) > (0.25 * count patches) and
      (?1 != cover) and (?1 != grass) )[
      set possible-crops remove ?1 possible-crops
    ]
  ]
  if empty? possible-crops [
    set patch-previous-crop-selection-rule "Rule_8a"
    report fallow
  ]
  if ( (length possible-crops) = 1) [
    set patch-previous-crop-selection-rule "Rule_8b"
    report first possible-crops
  ]

  ;9.  Nightshade after beets or lettuce
  if ( ( (patch-previous-crop = beet) or (patch-previous-crop = lettuce) ) and
    (member? nightshade possible-crops) and
    (random-float 1 < 0.90))[
  set patch-previous-crop-selection-rule "Rule_9"
  report nightshade
    ]

  ; 10.  Fallow after lily
  if ( (patch-previous-crop = lily) and (random-float 1 < 0.90))[
    set patch-previous-crop-selection-rule "Rule_10"
    report fallow
  ]


  ;11.  Grass after cover
  if ( (patch-previous-crop = cover) and
    (member? grass possible-crops) and
    (random-float 1 < 0.95))[
  set patch-previous-crop-selection-rule "Rule_11"
  report grass
    ]

  ; 12.  Beets after lettuce or mustard.
  if ( ( (patch-previous-crop = lettuce) or (patch-previous-crop = mustard) ) and
    (member? beet possible-crops) and
    (random-float 1 < 0.95))[
  set patch-previous-crop-selection-rule "Rule_12"
  report beet
    ]

  ;13.  Random Selection
  set patch-previous-crop-selection-rule "Rule_13"
  report one-of patch-available-crops

end


;;;;;;;;; SETUP FIELDS ;;;;;;;;;;
to setup-fields
  let counter 0
  foreach sort patches [ ?1 ->
    ask ?1 [
      ; initialize nitrogen between Min-Init-Nitrogen and Max-Init-Nitrogen
      set patch-nitrogen-level round (random-normal init-nitrogen-mean init-nitrogen-sd)
      if (patch-nitrogen-level < 0)[set patch-nitrogen-level 0]

      ; initialize crop history to no crops
      set patch-crop-history[]

      ; Set current crop and previous crop to fallow (no crop)
      set patch-current-crop fallow
      set patch-previous-crop fallow

      ; Copy list of all crops to each field
      set patch-available-crops[]
      foreach crops-list-all [ ??1 ->
        set patch-available-crops fput ??1 patch-available-crops
      ]
      ; but remove fallow from the possible crop selections
      set patch-available-crops remove fallow patch-available-crops

      ; Set all fields to a previous yield of 1 - needed for crop selection
      set patch-previous-crop-yield 1

      set-patch-color

      ;update-patch-label
      set patch-id counter
      set counter counter + 1

    ]
  ]
end

;;;;;;;; SETUP GLOBALS ;;;;;;;;; See crop_data.nls
to setup-globals

  ;do this first
  set-crop-names

  set-all-crops-list
  set-crops-table-nitrogen-requirements
  set-crops-table-weeds
  set-crops-table-disease
  set-crops-table-harvest-time
  set-crops-table-abbreviations
  set-crop-shapes

  set-rules-list-all

  set-crop-yield-totals
  set-crop-planting-totals
  set-crop-rule-totals

end

;;; setup turtles
to setup-turtles
  foreach sort patches [ ?1 ->
    ask ?1 [

      ; turtles are used for patch shapes only.
      sprout 1 [
        facexy xcor (max-pycor + 1)
        set shape (table:get crops-shapes patch-current-crop)
        set color blue
        set size .8
      ]
    ]
  ]
end

; initialize the table for the yield totals
to set-crop-yield-totals

  set crop-yield-totals table:make
  foreach crops-list-all[ ?1 ->
    table:put crop-yield-totals ?1 0
  ]

end

; initialize the table for the planting totals
to set-crop-planting-totals

  set crop-planting-totals table:make
  foreach crops-list-all[ ?1 ->
    table:put crop-planting-totals ?1 0
  ]

end

to set-rules-list-all
  set rules-list-all [
    "Rule_2" "Rule_3" "Rule_4" "Rule_5a" "Rule_5b" "Rule_6a"
    "Rule_6b" "Rule_7a" "Rule_7b" "Rule_8a"
    "Rule_8b" "Rule_9" "Rule_10" "Rule_11"
    "Rule_12" "Rule_13" ]
end

to set-crop-rule-totals

  set crop-rule-totals table:make
  foreach rules-list-all[ ?1 ->
    table:put crop-rule-totals ?1 0
  ]

end


;Update the patch label
to update-patch-label
  set plabel(word patch-id ": " patch-nitrogen-level "," (table:get crops-table-abbreviations patch-current-crop) "," patch-crop-harvest-week)
end

; Print crop totals
to print-crop-totals
  print-crop-yield-totals
  print-crop-planting-totals
end

; Print total yields
to print-crop-yield-totals
  let y "TOTAL-YIELDS"
  foreach crops-list-all[ ?1 ->
    ifelse (length (word table:get crop-yield-totals ?1) >= 4)
    [set y (word y ":" (substring (word table:get crop-yield-totals ?1) 0 4))]
    [set y (word y ":" table:get crop-yield-totals ?1)]
  ]
  set y (word y ":" init-nitrogen-mean ":" init-nitrogen-sd)
    show y
end

; Print crop planting totals
to print-crop-planting-totals
  let y "TOTAL-PLANTINGS"
  foreach crops-list-all[ ?1 ->
    set y (word y ":" table:get crop-planting-totals ?1)
  ]
  set y (word y ":" init-nitrogen-mean ":" init-nitrogen-sd)
  show y
end

; Print totals of rules used.
to print-crop-rule-totals
  let y "TOTAL-RULES"
  foreach rules-list-all[ ?1 ->
    set y (word y ":" table:get crop-rule-totals ?1)
  ]
  set y (word y ":" init-nitrogen-mean ":" init-nitrogen-sd)
  show y
end

; Print verbose harvest message.
to print-harvest-message

  ifelse (length (word patch-crop-harvest-yield) >= 4)
  [show (word patch-id " " "HARVEST " patch-current-crop " "  (substring (word patch-crop-harvest-yield) 0 4))]
  [show (word patch-id " " "HARVEST " patch-current-crop " " patch-crop-harvest-yield)]

end

; Print Verbose planting message
to print-planting-message
  show (word patch-id " " "PLANTING " patch-current-crop " <" patch-previous-crop-selection-rule "> ")
end


; Print crop distributions
to print-current-crop-distribution
  let y "DISTRIBUTION: "
  foreach crops-list-all[ ?1 ->
    set y (word y " " ?1 ":" count patches with [patch-current-crop = ?1])
  ]
end

; Update patch color depending on Nitrogen level
to set-patch-color

  ; lime is 65.  range for nitrogen is 63(dark) - 67 (light)
  ; range for nitrogen is 0 (low) to max of patches

  let max-current-nitrogen max [patch-nitrogen-level] of patches

  let color-temp 67 - (patch-nitrogen-level / (max-current-nitrogen / 4) );
  if (color-temp < 63)[ set color-temp 63]
  if (color-temp > 67)[ set color-temp 67]

  set pcolor color-temp

end

; Update crop icon - larger is closer to harvest.
to update-crop-size
  foreach sort turtles-here [ ?1 ->
    ask ?1 [
      let weeks-to-harvest (table:get crops-table-harvest-time patch-current-crop) - (patch-crop-harvest-week - ticks)
      set size  (weeks-to-harvest / table:get crops-table-harvest-time patch-current-crop) * .8 ; mult .8 so it doesn't get too big.
    ]
  ]
end

; Set crop shape
to set-crop-shape
  ; set the shape on the patch
  foreach sort turtles-here [ ?1 ->
    ask ?1[
      set shape table:get crops-shapes patch-current-crop
    ]
  ]

end

; Updates the counts of crops in the patches.
to update1-plots
  update-current-crops-count-plot
end

; don't graph fallow.
to update-current-crops-count-plot
  set-current-plot "current-crops-count-plot"
  foreach crops-list-all[ ?1 ->
    if (?1 != fallow) [
      set-current-plot-pen ?1
      plot count patches with [patch-current-crop = ?1]
    ]
  ]
end

; Print yields
to print-yield
  show ( word patch-current-crop " " patch-crop-harvest-yield )
end

; Hyperbolic tangent
to-report get-tanh [x]
  report ((exp (2 * x)) - 1) / ((exp (2 * x)) + 1)
end
@#$#@#$#@
GRAPHICS-WINDOW
214
10
882
679
-1
-1
60.0
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
10
0
10
0
0
1
ticks
30.0

BUTTON
8
10
74
43
Setup
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
79
10
146
43
Go
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

MONITOR
10
45
67
94
Year
(floor (ticks / 52))
0
1
12

MONITOR
79
45
136
94
Week
ticks mod 52
0
1
12

SLIDER
5
98
178
131
init-nitrogen-mean
init-nitrogen-mean
1
51
10.0
1
1
NIL
HORIZONTAL

SLIDER
9
133
181
166
init-nitrogen-sd
init-nitrogen-sd
1
10
2.0
1
1
NIL
HORIZONTAL

PLOT
891
14
1244
312
current-crops-count-plot
Week
Number of Fields
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"beet" 1.0 0 -2674135 true "" ""
"buckwheat" 1.0 0 -955883 true "" ""
"carrot" 1.0 0 -6459832 true "" ""
"cucurbit" 1.0 0 -1184463 true "" ""
"grass" 1.0 0 -10899396 true "" ""
"legume" 1.0 0 -14835848 true "" ""
"lettuce" 1.0 0 -13345367 true "" ""
"lily" 1.0 0 -8630108 true "" ""
"mustard" 1.0 0 -2064490 true "" ""
"nightshade" 1.0 0 -7500403 true "" ""
"rose" 1.0 0 -1184463 true "" ""
"cover" 1.0 0 -11221820 true "" ""

SWITCH
11
172
166
205
verbose-output
verbose-output
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This simulation is designed to look at crop rotations on organic farms.  Fields are initialized with nitrogen levels from the user set parameters.  After setup, the farmer selects and plants a crop using a set of 13 rules.  At harvest time, crops yields are calculated by simulating values for weeds and disease in that field.  After harvest, the field is set to fallow for 5 weeks and then crops are selected again.  The simulation runs for 208 weeks (4 years).

## HOW IT WORKS

The simulation uses 13 rules outlined in crop_selection.
1.  Review crop history
2.  If there are no possible crops to plant, let the field lay fallow.
3.  Fallow fields for weed or pest control.
4.  Random fallow periods.
5.  Build soil fertility with cover crops
6.  Only plant a crop when sufficient nutrients exist in the soil.
7.  Never grow a crop consecutively
8.  Single crops less than 25% of total farm
9.  Nightshade after beets or lettuce
10.  Fallow after lily
11.  Grass after cover
12.  Beets after lettuce or mustard.
13.  Random Selection

Patches are labeled with their ID, Nitrogen level, Crop, and week crop will be harvested.

The crops in the simulation are:
beet, buckwheat, carrot, cucurbit, grass, legume, lettuce,lily, mustard, nightshade, rose, and cover. "fallow" means that there is no crop planted on the field.

## HOW TO USE IT

Set levels for the initial nitrogen values and click setup and then go.  If you want more detailed information about plantings, rules executed, and specific yields, click 'on' for the verbose output.

## THINGS TO NOTICE

See how crops are selected using the rules with the verbose output.

## THINGS TO TRY

Try setting different values for the Nitrogen levels.  How does this effect the crops selected for the fields?

## EXTENDING THE MODEL

What other variables could be added to either the fields (slope, drainage, moisture content, etc) or the crops (Phorphorus requirements, moisture requirements)

## NETLOGO FEATURES

Nothing to Report

## RELATED MODELS

Nothing to Report

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
