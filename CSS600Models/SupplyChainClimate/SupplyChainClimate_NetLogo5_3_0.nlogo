globals [
  shoreline              ;; shoreline of the water body
  slr-chance             ;; sea level rise (slr) likelihood counter
  hurricane-chance       ;; hurricane likelihood indicator
  total-net-worth        ;; total cash-level of all organizations
  cash-before-hurricane  ;; total cash-level before current hurricane
  cash-after-hurricane   ;; total cash-level after current hurricane
  new-hurricane-damage   ;; cash-level loss from new hurricanes
  total-hurricane-damage ;; total cash-level loss from hurricanes
  original-market        ;; number of firms in original market
  firms-remaining        ;; number of firms left in the world
  average-firm-distance  ;; average firm distance to the shore
  ghg-emissions-total    ;; total emissions intensity for market
  finish-build           ;; new firm creation "date"
]

breed [firms firm]            ;; individual organizations supplying a given federal agency
breed [trucks truck]          ;; trucks used to complete assignments
breed [hurricanes hurricane]  ;; hurricanes that can impact organizations

firms-own [
  ghg-intensity          ;; the amount of GHG emissions per unit of work/product produced, in MTCO2e
  ghg-emissions          ;; emissions for this turn, depending on intensity and number of trucks
  cash-level             ;; remaining operating capital in the bank
  assignments            ;; number of assigned missions (work to do)
  firm-climate-aversion  ;; firm-specific climate aversion, based on experience
  firm-policy-aversion   ;; firm-specific policy aversion, based on experience
  shore-distance         ;; distance to the shore
  initial-cash           ;; how much money a firm started with
  initial-shore-distance ;; initial disctance from the shoreline
  number-of-moves        ;; number of times a firm has moved
  total-slr-losses       ;; loses incurred by movement required by sea level rise
  ticks-survived         ;; indicator for the longest surviving firm in the market
]

trucks-own [
  parent-company        ;; parent firm of the truck
  job-complete          ;; whether or not the assignment has been completed
]

to setup
  clear-all
  ;; create the world - land and water
    set shoreline max-pxcor - 5 ;; establishes the shoreline of the water body
  ask patches [
    if pxcor > shoreline [  ;; sets a deepening blue water color for the water body
      set pcolor scale-color blue pxcor 30 19
    ]
    if pxcor <= shoreline
      [ set pcolor green + 3.5 ] ;; sets a vegetative land tone for the earth
  ]
  ;; create firms on land-based patches, with or without preference for shoreline development
  set-default-shape firms "house"
  ;; prevent errors from adding too many firms if they shrink the world excessively
     ;; also prevent density of firm distribution from being too high for aesthetic puproses
  if number-firms > floor ( count patches with [ pxcor <= shoreline ] / 4 ) [
    user-message ( word "This world only has room for " floor (count patches with [ pxcor <= shoreline ] / 4) " firms." )
      stop
      ]
  create-firms number-firms [
    ;; y-coordinate is assigned randomly - no preferrable y-cor because impacts are equally variable across this axis
    set ycor random-float 2 * max-pycor
    ifelse initial-shoreline-development-selector
    ;; Shoreline development weighted exponentially with the selector ON - towards shore when set > 5, and away when set < 5
    [ set xcor shoreline - abs ( shoreline - min-pxcor ) * ( random-float 1 ) ^ ( initial-shoreline-preference / 5 ) ]
    ;; x-coordinate is set randomly when the selector is OFF, within the land patches only
    [ set xcor shoreline - random-float ( shoreline - min-pxcor ) ]
    set color black ;; all firms start as black
    set cash-level abs random-normal 100 100 ;; starting capital is variable but reasonably bounded
    ;; set several starting variables and static indicators for all firms
    set assignments 0 ;; no initial work assignments
    set firm-climate-aversion 1 ;; floor value for fear of climate impacts (1 to avoid divide by zero errors)
    set firm-policy-aversion 1  ;; floor value for fear of policy impacts (1 to avoid divide by zero errors)
    set shore-distance shoreline - xcor ;; initial distance from the shore
    set initial-cash cash-level ;; starting capital stored for review at any point in time
    set initial-shore-distance shoreline - xcor ;; starting capital stored for review at any point in time
    set number-of-moves 0 ;; initializes counter for firms to record number of moves made since birth
    set total-slr-losses 0 ;; initializes counter for firms to record cash loss from slr since birth
    set ticks-survived 0 ;; initializes counter for firms to record number of ticks since birth (age proxy)
    ]
  set original-market count firms ;; sets a static initial market count of firms for later calculations
  set-default-shape hurricanes "flag"
  set-default-shape trucks "truck"
  ;; initialize various variables not linked to individual firms or patches
  set slr-chance 0 ;; initializes chance of slr at zero
  set hurricane-chance 0 ;; initializes chance of hurricane at zero
  set finish-build 0 ;; initializes firm build length ticker at zero
  reset-ticks ;; starts time at zero for new run
end


to go ;; begin the model run
  if not any? firms [ stop ] ;; ends the program if all firms are eliminated
  if shoreline <= min-pxcor [stop] ;; ends the program if slr has consumed the landscape
  update-variables  ;; calls the variable update procedure
  generate-firms    ;; calls the variable update procedure
  set-assignments   ;; calls the variable update procedure
  generate-trucks   ;; calls the variable update procedure
  move-trucks       ;; calls the variable update procedure
  ;; call the slr procedure, if the slider is set to ON
  if slr-on-? [
    sea-level-rise
  ]
  ;; call the hurricane generation procedure, if the slider is set to ON
  if hurricanes-on-? [
    generate-hurricanes
  ]
  move-firms        ;; calls the variable update procedure
  update-cash-state ;; calls the variable update procedure
  tick              ;; advances the tick ( ~ 1 = day as a rough abstraction )
end


;; update variables based on sliders, ticks, randomness, bounded rationality, and general resets

to update-variables
;; update slr chance
   ;; updates the chance of slr with each tick ( if slr-on-? button is ON )
   ;; rate of slr based on a slider with exponential gain, increasing the chance of slr each tick
   ;; increases are normally distributed with wide tails
ifelse slr-on-? [
  set slr-chance slr-chance +  ticks ^ (sea-level-rise-rate ^ 2 / 1000) * random-normal 1 3
] [
set slr-chance 0 ;; zeroes slr chance if the switch is turned off
]
;; update hurricane chance
   ;; updates the chance of hurricane with each tick ( if hurricanes-on-? button is ON )
   ;; hurricane occurance rate based on a slider with exponential gain, increasing the chance with each tick
   ;; increases are normally distributed with wide tails
ifelse hurricanes-on-? [
  set hurricane-chance hurricane-chance + ticks ^ (increasing-hurricane-frequency ^ 2 / 1000) * random-normal 1 3
] [
set hurricane-chance 0 ;; zeroes hurricane chance if the switch is turned off
]
;; determine the total market value based upon the net worth of all the individual firms added together
set total-net-worth sum [
  cash-level
  ]
of firms
;; total hurricane damage to date for display based on new damages added to the running total
set total-hurricane-damage total-hurricane-damage + new-hurricane-damage
;; calculate average distance of all firms from the shore for plotting
if count firms > 0 [ ;; prevents potential divide by zero errors
set average-firm-distance ( sum [
  shore-distance ]
of firms / count firms )
]
;; reset counters from previous ticks to prepare for further calculations
set new-hurricane-damage 0
set cash-before-hurricane 0
set cash-after-hurricane 0
;; determine number of firms remaining for plotting
set firms-remaining count firms
;; update firm variables used in subsequent calculations
ask firms [
  set assignments 0 ;; reset assignment marker to zero
  set shore-distance shoreline - xcor ;; resets firm  distance to shoreline to account for moves
  set ghg-emissions ( count trucks with [ parent-company = myself ] * [ ghg-intensity ] of self )
  ] ;; calculates firm ghg emissions based upon the number of active jobs and ghg-intensity of the firm
;; determine the total current ghg-emissions per turn for plotting
set ghg-emissions-total sum [
  ghg-emissions ]
of firms
;; update color of patches to blue for water, if necessary, following sufficient slr
ask patches [
  if pxcor >= shoreline and pxcor < max-pxcor - 4  [ ;; updates light blue color for the new water shoreline when required
    set pcolor blue + 3
    ]
  ]
end


;; new firms enter the market if the conditions are right

to generate-firms
  ;; check to see if the required lag time has passed following a decision to build a firm(s)
  ;; ensrure that the market does not grow out of control
  if finish-build > 0 and ticks >= finish-build and original-market - count firms >= 0 [
  ;; allow for variability in the number of firms created to reflect market dynamics ( filling a perceived gap )
  create-firms abs random-normal 1 ( original-market - count firms ) ^ .01 [
    ;; see notes in setup subsection above for explanation of these steps
    set ycor random-float 2 * max-pycor
    ifelse initial-shoreline-development-selector
    [ set xcor shoreline - abs ( shoreline - min-pxcor ) * ( random-float 1 ) ^ ( initial-shoreline-preference / 5 ) ]
    [ set xcor shoreline - random-float ( shoreline - min-pxcor ) ]
    set color black
    set cash-level abs random-normal 100 100
    set assignments 0
    set firm-climate-aversion 1
    set firm-policy-aversion 1
    set shore-distance shoreline - xcor
    set initial-cash cash-level
    set initial-shore-distance shoreline - xcor
    set number-of-moves 0
    set total-slr-losses 0
    set ticks-survived 0
    ]
  ;; reset the wait time following finalization of firm creation
  set finish-build 0
  ]
  ;; time to create new firms ranges from a couple months to a couple years - this provides the lag
  if finish-build = 0 and count firms < random-normal ( original-market / 2 ) ( original-market / 10 ) [
    set finish-build ticks + random-normal abs 50 150 ;; significant bounded variation allowed for build times
  ]
end


;; firms are assigned work if they meet ghg-intensity standards

to set-assignments ;; approves firms with ghg-intensity at or below a government threshold for a particular bid, which varies by tick according to the following calculations
  ask firms [
    set ghg-intensity ( ( shoreline - xcor ) / ( shoreline + 25 ) * 5 ) ;; updates ghg-intensity based on required travel distance to complete work
    ]
  ask firms with [ ;; firms with ghg-intensity > couple std dev away from policy will not receive much work, but always possible each tick using normal distributions
    ghg-intensity <= random-normal ( 8 - ghg-policy-strength ) 3 ] [
    set assignments 1 ;; work is now assigned
    ]
    ask firms with [ ;; firms not assigned work become more averse to high ghg-intensity operations, eventually increasing their desire to move closer to the client
      assignments = 0 ] [
        set firm-policy-aversion firm-policy-aversion + abs random-normal 0 10 ;; allows firms to react to lack of assignments quite differently
      ]
end


;; firms create trucks to complete work, when assigned

to generate-trucks
  ask firms with [ assignments = 1 ] [
  hatch-trucks 1 [  ;; firms with assignments generate a truck to complete the work
    set parent-company myself ;; identifies the firm as the truck's parent for tracking and attribute aggregation
    set color brown
    set heading 90 ;; trucks first head toward shore to complete mission
    set job-complete 0 ;; job begins as incomplete ( 0 )
    ]
  ]
end


;; trucks move to and from their destination to complete assignments

to move-trucks
  ask trucks [ ;; if parent company has died, the truck also dies to prevent stragglers
    if parent-company = nobody [
      die
    ]
    if distancexy shoreline ycor < 1 [ ;;turn around at the shore when job has been completed
      set heading 270
      set job-complete 1
    ]
    if ( distance parent-company < 1 and job-complete = 1 ) [ ;; truck has returned to parent company after reaching the shore
      ask parent-company [
        set cash-level cash-level + 1 ;; mission is complete, so parent company receives payment
      ]
      die ;; truck completed mission, so it dies to indicate that the mission is over an payment rendered
    ]
    if ( distance parent-company >= 1 and job-complete = 1 ) [
      set heading towards parent-company ;; job is complete but not back to home firm yet, so head toward firm
      fd 1 ;; move 1 patch per turn
    ]
    if job-complete = 0 [ ;; job not yet comple
      set heading 90 ;; set ( or ensure that still set ) heading toward shore to complete job
      fd 1 ;; move 1 patch per turn
    ]
  ]
end


;; determine slr if threshold exceeded for counter

to sea-level-rise
  ;; assumed constant slope in world
  if slr-chance > 100 [ ;; determine if threshold exceeded for slr
    set shoreline shoreline - random-float .01 ;; establishes new shoreline upon slr with some variability - slr is not linear
    set slr-chance 0 ;; resets slr-chance for the next iteration of possible slr
    ;; move firms back from shoreline if they must to avoid drowning
    ask firms [
      ;; moves firm back from shoreline at least one space, potentially more depending upon risk aversion over time
      if xcor > shoreline [
        set xcor shoreline - abs ( ( shoreline - min-pxcor ) * ( random-float 1 ) ) ;; destination selection allows variability
        set cash-level cash-level - cost-to-move ;; cost of moving impacts overall cash level
        set firm-climate-aversion firm-climate-aversion + abs random-normal 2500 1000 ;; slr-induced movement greatly increases aversion
        set total-slr-losses total-slr-losses + cost-to-move ;; tracks total cash spent moving in response to slr for reference
        set number-of-moves number-of-moves + 1 ;; adds to count of total times firm has moved
      ]
    ]
    ;; if trucks are caught by slr they die
    ask trucks [
      if xcor >= shoreline - 1 [
        die
      ]
    ]
  ]
end


;; determine hurricane activity if threshold exceeded for counter

to generate-hurricanes
  ask hurricanes [ ;; removes any hurricanes from the previous tick - impacts are assessed in one tick
    die
  ]
  if hurricane-chance > 100 [ ;; determine if threshold exceeded for hurricane
    set hurricane-chance 0 ;; reset counter prior to calculating hurricane impacts
    ;; determine pre-hurricane cash value to later calculate damage impacts after the storm
    set cash-before-hurricane sum [
      cash-level
      ]
    of firms
    ;; generate quantity of hurricane impacts with heaviest concentration in deep water and lessening towards and past the shoreline
    ask patches [
      sprout-hurricanes random-normal ( pxcor - shoreline - 5 ) 5 [ ;; noreal distribution of hurricane damage with very wide tails
        set color red
        ]
    ask firms [;; allows firms to "analyze" and react to climate risk differently by adjusting risk analysis metrics and cash levels variably
    ;; hurricane damages are based on quantity of hits, calculated above, but also the quality of the hit calculated here
    set cash-level cash-level - ( count hurricanes-here * increasing-hurricane-intensity ^ 3 / 100 ) * abs random-normal .01 .1
    ;; climate aversion generated from hurricanes is highly variable, depending upon level of impact
    set firm-climate-aversion
    firm-climate-aversion + ;; existing level of aversion, plus the following below
    count hurricanes-here * abs ( random-normal 1 1  ) + ;; very large influence from direct hits
    sum [count hurricanes-here] of neighbors * abs ( random-normal .1 .1 ) + ;; large influence from adjacent hits
    count hurricanes with [ distance myself <= 5 and distance myself > 1 ] * ( random-normal .01 .01 ) +; moderate influence from closeby landfall
    count hurricanes with [ distance myself <= 10 and distance myself > 5 ] * ( random-normal .0001 .0001 ) +; small influence from mid-range landfall
    count hurricanes with [ distance myself <= 25 and distance myself > 10 ] * ( random-normal .000001 .000001 ) +; minimal influence from long-distance landfall
    count hurricanes with [ distance myself > 25 ] * ( random-normal .000000001 .000000001 ) ; least, nearly negligible, influence from very distant landfall
    ]
    ;; if hit by a hurricane, trucks die
    ask trucks [
       if count hurricanes-here > 0 [
         die
         ]
       ]
      ]
    ;; determine overall property damages from current hurricane activity
    set cash-after-hurricane sum [
      cash-level
      ]
    of firms
    set new-hurricane-damage cash-before-hurricane - cash-after-hurricane
    ]
end


;; determine which firms decide to move in response to climate and policy aversions

to move-firms
  ;; determine which firms want to move closer to the shore due to policy aversion, and adjusts retained aversions to accomodate new locational risk profile
  ask firms with [
    ;; only move if desire is strong ( magnitude ), starkly greater than aversion to moving in the other direction ( relative magnitude ), and have enough cash cushion
    firm-policy-aversion - firm-climate-aversion >= cost-to-move * 2 and cash-level > cost-to-move * 2 and distancexy shoreline ycor >= 1 ] [
    if ( ( firm-policy-aversion - firm-climate-aversion ) > ( random-normal 10000 2000 ) and ( firm-policy-aversion / firm-climate-aversion ) > random-normal 2.5 .25 ) [
    ifelse ( firm-policy-aversion / firm-climate-aversion ) <= 10 [ ;; vast majority of movers
      ;; determine new location for those that decide to move, based upon relative aversion to policy over climate
      set xcor xcor + abs ( ( shoreline - xcor ) * ( random-float 1 ) ^ ( ( firm-climate-aversion / firm-policy-aversion ) ^ abs random-normal 1 1 ) )
      ;; adjust retained policy aversion downward following the move to retain memory of aversion, but allow "aversion healing" by reducing risk exposure
      set firm-policy-aversion firm-policy-aversion * ( random-float 1 ) ^ ( firm-climate-aversion / firm-policy-aversion )
      ;; adjust retained climate aversion downward to retain memory of aversion, but reduce it to account for decision to move closer to the risk
      set firm-climate-aversion firm-climate-aversion * ( random-float 1 ) ^ ( firm-policy-aversion / firm-climate-aversion )
    ] [
      ;; prevent runaway exponential calculations if firm is extremely averse to policy risks ( for remaining minority of movers )
      set xcor shoreline - abs random-normal .5 .5 ; set new location very close to the shore to account for extreme policy aversion
      set firm-climate-aversion 1 ; set climate aversion to minimal value given extreme policy aversion
      set firm-policy-aversion firm-policy-aversion / 10 ;; adjust policy aversion downward to account for risk reduction from moving to the coast
    ]
    set cash-level cash-level - cost-to-move
    set number-of-moves number-of-moves + 1
    ]
    ]
    ;; determine which firms want to farther from the shore due to climate aversion, and adjusts retained aversions to accomodate new locational risk profile
    ask firms with [
      ;; only move if desire is strong ( magnitude ), starkly greater than aversion to moving in the other direction ( relative magnitude ), and have enough cash cushion
      firm-climate-aversion - firm-policy-aversion >= cost-to-move * 2 and cash-level > cost-to-move * 2 and distancexy min-pxcor ycor >= 1 ] [
      if ( ( firm-climate-aversion - firm-policy-aversion ) > ( random-normal 10000 2000 ) and ( firm-climate-aversion / firm-policy-aversion ) > random-normal 2.5 .25 ) [
      ifelse ( firm-climate-aversion / firm-policy-aversion ) <= 10 [ ;; vast majority of movers
        ;; determine new location for those that decide to move, based upon relative aversion to climate over policy
        set xcor xcor - abs ( ( xcor - min-pxcor ) * ( random-float 1 ) ^ ( ( firm-policy-aversion / firm-climate-aversion ) ^ abs random-normal 1 1 ) )
        ;; adjust retained policy aversion downward to retain memory of aversion, but reduce it to account for decision to move closer to the risk
        set firm-policy-aversion firm-policy-aversion * ( random-float 1 ) ^ ( firm-climate-aversion / firm-policy-aversion )
        ;; adjust retained climate aversion downward following the move to retain memory of aversion, but allow "aversion healing" by reducing risk exposure
        set firm-climate-aversion firm-climate-aversion * ( random-float 1 ) ^ ( firm-policy-aversion / firm-climate-aversion )
      ] [
      ;; prevent runaway exponential calculations if firm is extremely averse to climate risks
      set xcor min-pxcor + abs random-normal .5 .5 ; set new location very far from the shore to account for extreme climate aversion
      set firm-policy-aversion 1 ; set policy aversion to minimal value given extreme climate aversion
      set firm-climate-aversion firm-climate-aversion / 10 ;; adjust climate aversion downward to account for risk reduction from moving far from the coast
      ]
      set cash-level cash-level - cost-to-move ;; decrease cash level by quantity required to move
      set number-of-moves number-of-moves + 1 ;; increase counter for total number of moves
      ]
      ]
end


;; account for costs and firm viabiltiy

to update-cash-state
  ask firms [
    ;; apply variable maintenance cost for firms to account for non-policy and non-climate related expenditures - helps to prevent stagnation of climate averse firms
    set cash-level cash-level - random-normal ( maintenance-cost / 100 ) ( maintenance-cost / 50 ) ;; maintenance requirements, occasional influx from divestitures, etc.
    if cash-level <= 0 [ ;; firms die if they run out of cash for any reason during the turn
      die
      ]
    set ticks-survived ticks-survived + 1 ;; update counter to record number of ticks the firm has survived
    ;; keep track of the oldest surviving firm (s) for visual monitoring
    ifelse any? firms with [ ticks-survived > [ ticks-survived ] of myself ] [
      set color grey ] [ ;; newer firm (s) are grey
      set color black ;; oldest firm (s) are black
      ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
309
6
947
665
25
25
12.314
1
10
1
1
1
0
0
1
1
-25
25
-25
25
1
1
1
ticks
30.0

SLIDER
37
72
249
105
number-firms
number-firms
5
100
20
1
1
NIL
HORIZONTAL

BUTTON
60
15
140
48
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

BUTTON
142
15
222
48
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

SLIDER
57
279
229
312
sea-level-rise-rate
sea-level-rise-rate
0
10
7
1
1
NIL
HORIZONTAL

SLIDER
59
510
231
543
ghg-policy-strength
ghg-policy-strength
1
10
6
1
1
NIL
HORIZONTAL

SLIDER
34
396
257
429
increasing-hurricane-frequency
increasing-hurricane-frequency
0
10
7
1
1
NIL
HORIZONTAL

SLIDER
39
430
252
463
increasing-hurricane-intensity
increasing-hurricane-intensity
1
10
7
1
1
NIL
HORIZONTAL

SLIDER
59
172
231
205
cost-to-move
cost-to-move
0
500
180
10
1
NIL
HORIZONTAL

SWITCH
18
589
289
622
initial-shoreline-development-selector
initial-shoreline-development-selector
0
1
-1000

PLOT
953
304
1347
424
Total Market Value
ticks
Total ($)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot total-net-worth"

SLIDER
55
624
252
657
initial-shoreline-preference
initial-shoreline-preference
1
25
13
1
1
NIL
HORIZONTAL

MONITOR
1004
10
1080
55
Market Value
total-net-worth
2
1
11

PLOT
953
181
1347
301
Firms In Market
ticks
# Firms
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot firms-remaining"

PLOT
953
58
1347
178
Facility Hurricane Damage
ticks
Total ($)
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" "plot total-hurricane-damage"

SWITCH
73
363
215
396
hurricanes-on-?
hurricanes-on-?
0
1
-1000

SWITCH
88
246
191
279
slr-on-?
slr-on-?
0
1
-1000

MONITOR
1154
10
1252
55
Hurricane Chance
hurricane-chance
2
1
11

MONITOR
1253
10
1347
55
SLR Chance
slr-chance
2
1
11

MONITOR
953
10
1003
55
Firms
count firms
17
1
11

MONITOR
1085
10
1149
55
Shoreline
shoreline
2
1
11

PLOT
954
547
1348
667
Market GHG Emissions
ticks
MtCO2e
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -955883 true "" "plot ghg-emissions-total"

PLOT
954
425
1348
545
Average Distance to Shore
ticks
# Patches
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot average-firm-distance"

SLIDER
59
123
231
156
maintenance-cost
maintenance-cost
0
50
15
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores potential market dynamics of a physical supply chain in response to climate change policies and climate change risks. The intent if the tool is tool inform scenario analyses on the influence of these policies and risks versus outcomes in the market - such as market size, profits, and greenhouse gas (ghg) emission levels, etc. The market sits on a shoreline where fims must balance the risks of sea level rise (long-term climate change risk) and hurricanes (a proxy for any potentially damaging short-term weather event, the frequency and intensity of which are influenced by climate change), versus the risk of not receiving work due to policies against high emissions intensity when locating themselves too far from the clients (on the shoreline).

## HOW TO USE IT

###A. Set Up and Initialize the Run
####1. _setup_ : button to set up the firms
####2. _go_ : button to start the simulation

###B. Choose the Market
####1. _number-firms_ : slider to chose the total market size
####2. _initial-shoreline-development-selector_ : switch to turn ON/OFF preferential tratment for shoreline development
####3. _initial-shoreline-preference slider_ : adjusts the preference for shoreline development
>  1 - 4  : prefer development away from the shore ( 1 = farthest from shore )
>  5      : neutral development preference ( same as above switch set to OFF )
>  6 - 25 : prefer development close to the shore ( 25 = closest to the shore )

###C. Set Business Costs
####1. _maintenance-cost_ : slider to set operational costs not related to climate
####2. _cost-to-move_: slider to set cost incurred to move the business location

###D. Adjust Sea Level Rise (SLR) Parameters
####1. _slr-on-?_ : switch to turn ON/OFF slr
####2. _sea-level-rise-rate_ : slider to set rate of slr

###E. Adjust Hurricane Parameters
####1. _hurricanes-on-?_ : switch to turn ON/OFF hurricanes
####2. _increasing-hurricane-intensity_ : slider to set increasing hurricane intensity over time due to climate chance
####3. _increasing-hurricane-frequency_ : slider to set increasing hurricane frequency over time due to climate chance

###F. Adjust Policy Parameter
####1. _ghg-policy-strength_ : slider to choose the strength of ghg regulation

## THINGS TO NOTICE

###A. Where Do Firms Locate Themselves Over Time?

Are firms concentrating on the shore, away from the shore, or in the middle? Or are they well distributed across the landscape? Has this involved a large transition from the original positioning? Who is the oldest survivor and what is interesting about their starting and current attributes?

###B. How Robust is the Market?

Have your settings caused instability or large losses of firms in a short window of time? Are the firms generating sufficient income and leading to a large overall market value? Is this the case for this run only or do additional runs end with the  same results?

###C. How Intense are GHG Emissions?

Have emissions evened out or are they rather dynamic? How does this correspond with the location of the firms across the landscape? Does it make sense with the settings you have in place? At what rate do GHG emissions change in comparison with other indicators?

## THINGS TO TRY

###A. Play with the Switches

Examine what happens to the market when you add and subtract climate risk from the calculations. If you remove both, is there still a way for agents to fail and perish?

###B. Play with the Sliders

See which sliders make the largest difference in market functionality and GHG emission consequences. Note interaction between different sliders and any setting that tend to cause volatility in the model run.

###C. Try Different Market Arrangements

Adjust the size of the market and the original proclivity for coastal development. See if these differences alter the overall functionality of the market or if they only adjust the relative magnitude of the results.

###D. Run a Parameter Sweep

Parameter sweeps with this model take a very long time due to the nature of climate change modeling (on the order of many years). See if any interesting dynamics come in to play with a widely applicable parameter sweep.


## EXTENDING THE MODEL

###A. Transporation Networks

Currently, trucks move directly to the shore and back to the parent firm. Increased depth of understanding may evolve from considering spatial factors relating to roadway networks and bottle-necks, as well as the use of other modes of transportation (such as freight or airplanes).

###B. Adaptive Policy

Policy levers are very abrupt and it would be interesting to see what the implications of lag time and/or adaptive policy has on the market. This could be conducted manually by moving the lever when either market or emission signals hit certain levels.

###C. Network Effects

Firms do not make choices in a vacuum and it would be interesting to see how collusion and risk pooling might affect market dynamics.

###D. Other Climate Effects

Taking the y-axis as a north-south indicator, it would be interesting to see what would happen if temperature changes were considered in the calculation methodologies. It would also be nice to incorporate precipitation cycles; however, adding too many additional considerations is likely to favor needless complication of instructive complexity.


## NETLOGO FEATURES

Note the extensive use of normal distributions with very wide tails in this application. This plays to the dynamics of business decision making as well as climate - there is significant variability around these parameters despite a fairly normal decision pathway when averaged at the macro level.


## CREDITS AND REFERENCES

No code was borrowed for this application.


## HOW TO CITE

If you mention this model in a publication, I ask that you include a citationa for the model itself and for the NetLogo software.
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
  <experiment name="FinalProject1" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>count firms</metric>
    <metric>list total-net-worth</metric>
    <metric>list average-firm-distance</metric>
    <metric>list total-hurricane-damage</metric>
    <enumeratedValueSet variable="increasing-hurricane-frequency">
      <value value="1"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-shoreline-development-selector">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-to-move">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="increasing-hurricane-intensity">
      <value value="1"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hurricanes-on-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-firms">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="maintenance-cost">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="slr-on-?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sea-level-rise-rate">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ghg-policy-strength">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-shoreline-preference">
      <value value="14"/>
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
