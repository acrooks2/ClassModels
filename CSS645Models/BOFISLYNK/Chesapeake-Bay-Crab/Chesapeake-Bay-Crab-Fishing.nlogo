;; -----------------------------------------------------------------------
;; chesapeake-bay-crab-fishing.nlogo
;;
;; agent-based model to demonstrate population dynamics of crabs and
;; and economics of commercial crab fishing in the Chesapeake Bay area
;;
;; -----------------------------------------------------------------------


;; =============================================================
;;
;; Global declarations
;;
;; =============================================================
;;
;; Note: the following are the definitions of
;; NetLogo variables mapped into the Schafer model
;;
;; Schaefer variable      Definition          NetLogo Model variable
;; -----------------      ----------          ----------------------
;; x                      population-size     (crab variable)
;; r                      growth-rate         (GUI slider)
;; K                      carrying-capacity   (GUI slider)
;; q                      catchability-rate   (GUI slider)
;; E                      num-vessels         (GUI slider)
;;

breed [crabs crab]
breed [fishermen fishman]
;; --------------------------------------------------------------
;;
;; global variables
;;
;; --------------------------------------------------------------
globals [

  ;; totals
  total-population-size   ; cumulative total population size of crabs for all time periods
  total-catch-size        ; total catch size of all fishermen this time period
  previous-catch-size     ; catch size previous time period
  annual-catch-size       ; total catch size this year (prev-catch + total-catch-size)

  ;; crab globals
  num-active-pods         ; number of locations with active crab populations
  mean-pod-size           ; average number of crabs at the location

  ;; fishermen globals
  num-active-fishermen    ; number of active fishermen (i.e. number of vessels)
  mean-fisherman-wealth   ; mean wealth of all fishermen

  ;; time globals
  initial-year            ; first year of simulation
  final-year              ; final year of simulation
  current-year            ; current year of the simulation

]

;; --------------------------------------------------------------
;; crab breed definitions
;;
;; define crab breed attributes
;;
;; --------------------------------------------------------------

crabs-own [
  population-size      ; total number of crabs in this pod

  ;;
  ;; currently not used, could be used if model extended
  ;; for a more realistic age cohort model
  ;;
  ;popsize-yr0          ; number of crabs aged 0 to 1 yr
  ;popsize-yr1          ; number of crabs aged 1 to 2 yr
  ;popsize-yr2          ; number of crabs aged 2 to 3 yr
  ;popsize-yr3          ; number of crabs aged 3 yrs
]

;; --------------------------------------------------------------
;; fisherman breed attributes
;;
;; define fisherman breed attributes
;;
;; --------------------------------------------------------------

fishermen-own [
  catch-size           ; current catch size in crabs
  wealth               ; current wealth in arbitrary economic units
  operating-expense    ; cost of operating the business
]

;; --------------------------------------------------------------
;; patches definitions
;;
;; setup spatial feature for geo-based fishing restrictions
;;
;; --------------------------------------------------------------
patches-own [
  fishing-allowed
]


;; --------------------------------------------------------------
;; setup-globals
;;
;; establish initial values for global variables
;;
;; --------------------------------------------------------------
to setup-globals
  ;; catchability-rate
  set total-population-size sum [population-size] of crabs
  set total-catch-size 0
  set previous-catch-size 0
  set annual-catch-size 0

  ifelse ((count fishermen) > 0)
  [set mean-fisherman-wealth mean [wealth] of fishermen]
  [set mean-fisherman-wealth 0]

  set mean-pod-size mean [population-size] of crabs

  set num-active-pods count crabs
  set num-active-fishermen count fishermen

  set initial-year 1982
  set final-year 1999
  set current-year initial-year

end



;; =============================================================
;;
;; Setup functions
;;
;; =============================================================


;; --------------------------------------------------------------
;; setup-chesapeake
;;
;; setup the chesapeake abstract spatial model and geography
;;
;; --------------------------------------------------------------
to setup-chesapeake
  define-bay
end

;; --------------------------------------------------------------
;; define-bay
;;
;; make the bay all blue (for the water)
;; and configure the fishing availability
;;
;; --------------------------------------------------------------
to define-bay
  ;;
  ;; set basic configuration
  ;;
  ask patches
  [
    set pcolor blue
    set fishing-allowed true
  ]

  ;;
  ;; reconfigure if spatial restrictions are active
  ;;
  if (spatial-restriction = true) [
    ask patches [
      ;;
      ;; note:
      ;; this can be used to implement a small checkerboard model
      ;; if ((pxcor mod 2) = 0) and ((pycor mod 2) = 0)

      ;;
      ;; implement large spatial restriction model
      ;;
      if ((pxcor <= 0) and (pycor < 0)) or ((pxcor >= 0) and (pycor > 0))  ;; large safe havens model
      [
        set fishing-allowed false
        set pcolor (blue - 3) ;; make off-limits patches a dark blue color
      ]
    ]
  ]
end

;; --------------------------------------------------------------
;; setup-crabs
;;
;; setup and locate the crab populations
;;
;; --------------------------------------------------------------
to setup-crabs[ num ]
  create-crabs num [
    set shape "blue crab"
    set color (blue + 3)
    set population-size pod-size

    ;;set size 1.0
    set size (population-size / carrying-capacity)
    if (size < 0.25) [
      set size 0.25
    ]

    setxy random-xcor random-ycor
    set heading 0
  ]
end

;; --------------------------------------------------------------
;; setup-fishermen
;;
;; setup and locate the fishermen
;;
;; --------------------------------------------------------------
to setup-fishermen[ num ]
  let MAX-WEALTH 100
  let MAX-EXPENSES 10

    create-fishermen num [
    set shape "crab boat"
    set size 2.0
    set color (gray + 2)
    set catch-size 0
    set wealth (random MAX-WEALTH) + 1
    set operating-expense (random MAX-EXPENSES) + 1
    setxy random-xcor random-ycor
    set heading 0
  ]
end

;; --------------------------------------------------------------
;; setup
;;
;; setup the model
;;
;; --------------------------------------------------------------
to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-chesapeake

  setup-crabs num-pods
  setup-fishermen num-vessels

  setup-globals

  setup-plot
  setup-histogram

  do-plot
  do-histogram
end


;; ===============================================================
;; ===============================================================
;; go
;;
;; main "go" procedure for simulation
;;
;; ===============================================================
;; ===============================================================
to go
  step
end


;; --------------------------------------------------------------
;; step
;;
;;
;; step function executes one time tick of action
;; (also useful for slow motion)
;;
;; --------------------------------------------------------------
to step

  ;;
  ;; check for end of simulation time, stop if occurred
  ;;
  if (current-year >= final-year) [ stop ]

  ;;
  ;; check for crab extinction, stop simulation if crabs extinct
  ;;
  if not any? crabs [ stop ]
  if sum [population-size] of crabs <= 0 [ stop ]

  ;; ------------
  ;; crab actions
  ;; ------------
  ask crabs [
    crab-move
    crab-breed
  ]

  ;; -----------------
  ;; fishermen actions
  ;; -----------------
  fishermen-add-new-vessels
  ask fishermen [
    set catch-size 0
    fishermen-move
    ;; fishermen-harvest
    fishermen-harvest-spatial
    fishermen-sell
    fishermen-pay-excess-catch-tax
  ]

  ;; ---------------------------------------
  ;; check for overfished pods, die if empty
  ;; ---------------------------------------
  ask crabs [
    if (population-size <= 1) [
      die
    ]
  ]

  ;; ------------------------------------------
  ;; check for bankrupt fishermen, die if broke
  ;; ------------------------------------------
  ask fishermen [
    if (wealth <= 1) [
      die
    ]
  ]

  ;; -----------------------------------
  ;; update globals and refresh displays
  ;; -----------------------------------
  tick
  update-globals
  do-plot
  do-histogram
end

;; --------------------------------------------------------------
;; update globals
;;
;; keep track of some key variables for display purposes
;;
;; --------------------------------------------------------------
to update-globals

  set total-population-size sum [population-size] of crabs
  set previous-catch-size total-catch-size
  set total-catch-size sum [catch-size] of fishermen
  set annual-catch-size (previous-catch-size + total-catch-size)

  ifelse (count fishermen) > 0
  [set mean-fisherman-wealth mean [wealth] of fishermen]
  [set mean-fisherman-wealth 0]

  ifelse (count crabs) > 0
  [set mean-pod-size mean [population-size] of crabs]
  [set mean-pod-size 0]

  set num-active-pods count crabs
  set num-active-fishermen count fishermen

  if ((ticks > 0) and ((ticks mod 2) = 0)) [
    set current-year (current-year + 1)
  ]
end


;; =============================================================
;;
;; Crab functions
;;
;; =============================================================


;; --------------------------------------------------------------
;; crab-move
;;
;; basic crab movement
;;
;; --------------------------------------------------------------
to crab-move
  ;;
  ;; move in the summer/fall, sleep during the winter
  ;;
  let CRAB_MOVE_FREQUENCY 2
  let move-flag 0
  if ((ticks mod CRAB_MOVE_FREQUENCY) = 0) [
    set move-flag 1
  ]

  ;;
  ;; if it's summer/fall, move
  ;; if it's winter/spring, don't move
  ;;
  ;; min and max movement distances are in km
  ;; km_per_cell allows conversion from actual movement in km
  ;; to NetLogo cell distances.
  ;;
  ;; scale is set by analyzing total Chesapeake Bay area divided
  ;; by number of cells in model.  Default is 33x33 cells.
  ;;
  ;;
  let MIN_MOVE_DISTANCE 14
  let MAX_MOVE_DISTANCE 70
  let KM_PER_CELL 2.7

  let move-distance (random (MAX_MOVE_DISTANCE - MIN_MOVE_DISTANCE) / KM_PER_CELL )
  if (move-flag = 1) [
    rt random 50
    lt random 50
    fd move-distance
  ]
  set heading 0
end

;; --------------------------------------------------------------
;; crab-breed
;;
;; define crab reproduction
;;
;; --------------------------------------------------------------
to crab-breed

  ;;
  ;; only breed in summer/fall, sleep during the winter
  ;;
  ;; to implement this, let 2 ticks == 1 year, so
  ;; breeding occurs every other tick
  ;;
  let CRAB_BREED_FREQUENCY 2
  let breed-flag 0
  if ((ticks mod CRAB_BREED_FREQUENCY) = 0) [
    set breed-flag 1
  ]

  ;;
  ;; dxdt is from the equation for a Schaefer model
  ;;
  if (breed-flag = 1) [
    let dxdt 0
    set dxdt (growth-rate * population-size) * (1 - (population-size / carrying-capacity))
    set population-size (population-size + dxdt)

    ;;
    ;; pod dies out if too small
    ;;
    if (population-size <= 1) [
      die
    ]

    ;;
    ;; change crab icon display size based on population-size
    ;;
    ;; provides quick visual of how big the pod is compared to
    ;; how big it could be.  Override size if less than 0.25 since
    ;; it's too hard to see on the screen if below 0.25
    ;;
    set size (population-size / carrying-capacity)
    if (size < 0.25) [
      set size 0.25
    ]
  ]
end


;; =============================================================
;;
;; Fishermen functions
;;
;; =============================================================


;; --------------------------------------------------------------
;; fishermen-add-new-vessels
;;
;; define adding new fishermen.  Since fishermen occasionally
;; go broke, this method simulates new fishermen joining the
;; fleet (or displaced fishermen returning from other lines
;; of work).
;;
;; --------------------------------------------------------------
to fishermen-add-new-vessels
  let current-fleet-size (count fishermen)
  if ((current-fleet-size < num-vessels) and (num-vessels > 0)) [
    let i 0
    let num (num-vessels - current-fleet-size)
    while [i < num] [
      let prob (1.0 - (current-fleet-size / num-vessels))
      if ((random-float 1.0) > prob) [
        setup-fishermen 1
      ]
      set i (i + 1)
    ]
  ]
end

;; --------------------------------------------------------------
;; fishermen-move
;;
;; define fishermen movement.  This simulates fishermen sailing
;; about in the bay area.
;;
;; Note: this is a *gross* oversimplification.  In real life,
;; fishermen sail fairly wide distances and drop crab pots in
;; the summer, or do dredging in the winter.  The model only
;; allows very limited sailing distances.  Since each cell
;; is approx 2.7 km by 2.7 km, a 10 cell voyage is only 27 km
;; distance.  However, due to the temporal resolution of the
;; model, this means the fisherman is only harvesting in a 27 km
;; region every 6 months.
;;
;; --------------------------------------------------------------
to fishermen-move
  let sailing-distance random 10
  let new-heading random 360
  ifelse ((random-float 1.0) > 0.5)
  [rt new-heading]
  [lt new-heading]
  fd sailing-distance
  set heading 0
end

;; --------------------------------------------------------------
;; fishermen-harvest [harvest-radius]
;;
;; driver function to manage fishermen harvesting of crabs
;;
;; harvest-radius is the radius in which the fisherman can "see"
;; to look for crab pods to harvest.
;;
;; harvesting is subject to "excess-tax" policy, which is a
;; policy alternative that puts an increasing graduated tax
;; on harvests that are in excess of the fleet's mean harvest
;; size.  Fishermen are taxed highly if they take a catch that
;; is in excess of the mean catch size of the fleet, which
;; incentivizes them to limit their catch sizes for economic
;; purposes.
;;
;; if the excess-tax is set to 0, then this policy is not enforced.
;; if the excess-tax is set to > 0, then the excess catch is taxed
;; at the excess-tax rate for the quantity of catch above the
;; fleet average catch size.
;;
;; --------------------------------------------------------------
to fishermen-harvest[ harvest-radius ]
  let CATCH-RADIUS harvest-radius

  let crabs-this-catch 0
  let total-catch 0
  let targetList crabs in-radius CATCH-RADIUS


  ifelse (extra-tax = 0) [
    ;;
    ;; no excess catch taxation policy in place
    ;;

    ;; conduct the harvest
    ;;
    ask targetList [
      if population-size > 0 [
        set crabs-this-catch ((random-float catchability-rate) * population-size)
        set population-size (population-size - crabs-this-catch)
        set total-catch (total-catch + crabs-this-catch)
      ]
    ]
    set catch-size (catch-size + total-catch)
  ]
  [
    ;;
    ;; excess catch will be heavily taxed
    ;;

    ;; determine average and sd of fleet catch size
    let average-catch-size mean [catch-size] of fishermen
    let sd-catch-size sqrt (variance [catch-size] of fishermen)
    if (sd-catch-size = 0)
    [set sd-catch-size 1]

    ;; conduct the harvest
    ;;
    ask targetList [
      if population-size > 0 [
        set crabs-this-catch ((random-float catchability-rate) * population-size)

        ;;
        ;; before actually taking the harvest,
        ;; check to see if this puts us over quota...
        ;;
        ifelse ((total-catch + crabs-this-catch) < average-catch-size) [
          ;;
          ;; go ahead and harvest, since we're still under quota
          ;;
          set population-size (population-size - crabs-this-catch)
          set total-catch (total-catch + crabs-this-catch)
        ]
        [
          ;;
          ;; harvest with reduced probability, since we're already over catch
          ;;
          let prob-harvest (1 / (( (total-catch + crabs-this-catch) / sd-catch-size) ^ 1))
          if (prob-harvest > (random-float 1.0)) [
            set population-size (population-size - crabs-this-catch)
            set total-catch (total-catch + crabs-this-catch)
          ]
        ]
      ]
    ]
    set catch-size (catch-size + total-catch)
  ]
end

;; --------------------------------------------------------------
;; fishermen-harvest-spatial
;;
;; define fishermen harvesting of crabs, subject to spatial
;; harvesting constraints.  If fishing is allowed, then
;; harvesting is conducted within a specified radius.  If fishing
;; is not allowed, it means that the vessel has sailed into a
;; restricted area and can not harvest in this area.
;;
;; --------------------------------------------------------------
to fishermen-harvest-spatial

  ;;
  ;; check to see if fishing is allowed here
  ;;
  let fishing-allowed-here true
  let location patch-here
  ask location [
    set fishing-allowed-here fishing-allowed
  ]

  ;;
  ;; proceed to fish if allowed at this location
  ;;
  if (fishing-allowed-here = true) [
    ;let CATCH-RADIUS random 4 + 1
    let CATCH-RADIUS 1
    fishermen-harvest CATCH-RADIUS
  ]
end

;; --------------------------------------------------------------
;; fishermen-sell
;;
;; define economics of selling crabs.  Fishermen compute their
;; gross profit, gross expenses, and determine their net return.
;; the net return is subject to basic taxation.  The final
;; after tax return is added (subtracted) to the fisherman's
;; cumulative wealth.
;;
;; --------------------------------------------------------------
to fishermen-sell
  let SALES_INTERVAL 1

  if ((ticks > 0) and ((ticks mod SALES_INTERVAL) = 0)) [

    ;;
    ;; optional future work:
    ;; do this if you are using a dynamic market price
    ;; based on current and previous catch sizes.  market price
    ;; can fluctuate based on ratio of current fleet catch
    ;; with previous fleet catch, simulating changes in the
    ;; supply side of the market
    ;;
    ;; let market-price ((sum [catch-size] of fishermen) / total-catch-size)
    ;;

    ;;
    ;; compute individual fisherman results
    ;;
    let market-price market-price-per-unit
    ask fishermen [
      let gross-profit (catch-size * market-price)
      let gross-expenses (catch-size * production-cost-per-unit)
      let net-return (gross-profit - gross-expenses)
      let after-tax-return (net-return * (1.0 - base-tax))

      set wealth (wealth + after-tax-return - (random operating-expense))
    ]
  ]
end

;; --------------------------------------------------------------
;; fishermen-pay-excess-catch-tax
;;
;;
;; fishermen have to pay a high tax for any catch
;; over the average catch size for the period.  This is only
;; the case if the excess-tax value is set to > 0.0
;;
;; --------------------------------------------------------------
to fishermen-pay-excess-catch-tax

  ;; determine how frequently fishermen sell their catch
  ;; default is every tick (~ 6 months in simulated time).
  let SALES_INTERVAL 1

  ;;
  ;; is excess-tax policy being used?
  ;;
  if (extra-tax > 0) [
    if ((ticks > 0) and ((ticks mod SALES_INTERVAL) = 0)) [

      let mean-catch-size mean [catch-size] of fishermen
      let sd-catch-size sqrt (variance [catch-size] of fishermen)

      ;;
      ;; compute individual fisherman taxation on excess catch
      ;;
      ask fishermen [
        let excess-catch-size (catch-size - mean-catch-size)
        if (excess-catch-size > 0) [
          let excess-tax-factor (excess-catch-size / sd-catch-size )
          let excess-catch-tax (excess-catch-size * excess-tax-factor)
          set wealth (wealth - excess-catch-tax)
        ]
      ]
    ]
  ]
end


;; =============================================================
;;
;; Plot functions
;;
;; =============================================================


;; --------------------------------------------------------------
;; setup plot
;;
;; setup the plot. This currently doesn't do anything, but
;; is put here in case special plot setup is needed later,
;; such as setting ranges or other configurations.
;;
;; --------------------------------------------------------------
to setup-plot
  ;;set-current-plot "crab-population"
  ;;set-plot-y-range 0 number
end

;; --------------------------------------------------------------
;; setup-histogram
;;
;; set up the histogram of fisherman wealth categories
;;
;; --------------------------------------------------------------
to setup-histogram
  set-current-plot "fisherman-wealth"
  set-plot-x-range 0 10
  set-plot-y-range 0 100
  set-histogram-num-bars 10
end

;; --------------------------------------------------------------
;; do-plot
;;
;; update the plots.
;; crab-population:  plot of current crab population
;; total-catch:      plot of total crab harvest
;; fisherman-wealth: plot of fisherman accumulated wealth
;;
;; --------------------------------------------------------------
to do-plot
  set-current-plot "crab-population"

  set-current-plot-pen "crabs"
  plot sum [population-size] of crabs

  set-current-plot "annual-catch"
  set-current-plot-pen "catch"
  ;plot total-catch-size
  plot annual-catch-size

  set-current-plot "fisherman-wealth"
  set-current-plot-pen "wealth"
  ;;plot mean [log wealth 10] of fishermen
  ifelse ((count fishermen) > 0)
  [plot mean [wealth] of fishermen]
  [plot 0]
end

;; --------------------------------------------------------------
;; do-histogram
;;
;; update the histogram
;;
;; --------------------------------------------------------------
to do-histogram
  set-current-plot "wealth-groups"
  set-current-plot-pen "wealth"
  histogram [log wealth 10] of fishermen
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
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
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
8
15
71
48
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
77
16
140
49
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
654
12
814
132
crab-population
time
size
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"crabs" 1.0 0 -11221820 true "" ""

SLIDER
8
136
189
169
growth-rate
growth-rate
0.0
1.0
0.07
0.01
1
NIL
HORIZONTAL

BUTTON
144
16
207
49
step
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
8
210
191
243
num-vessels
num-vessels
0
500
120.0
10
1
NIL
HORIZONTAL

SLIDER
8
174
189
207
carrying-capacity
carrying-capacity
0
1000000
790000.0
10000
1
NIL
HORIZONTAL

SLIDER
9
247
190
280
catchability-rate
catchability-rate
0
1.0
0.15
0.01
1
NIL
HORIZONTAL

SLIDER
7
59
135
92
num-pods
num-pods
0
10000
400.0
100
1
NIL
HORIZONTAL

SLIDER
7
97
134
130
pod-size
pod-size
0
250000
20000.0
10000
1
crabs
HORIZONTAL

MONITOR
652
137
814
182
total crab population
total-population-size
0
1
11

MONITOR
655
299
786
344
total catch size
total-catch-size
0
1
11

SLIDER
10
349
192
382
market-price-per-unit
market-price-per-unit
0
10
3.3
0.10
1
NIL
HORIZONTAL

SLIDER
10
386
193
419
production-cost-per-unit
production-cost-per-unit
0
10
2.4
0.10
1
NIL
HORIZONTAL

SLIDER
9
427
101
460
base-tax
base-tax
0
4.0
0.2
0.05
1
NIL
HORIZONTAL

MONITOR
740
186
828
231
mean pod size
mean-pod-size
2
1
11

MONITOR
657
411
778
456
mean fisherman wealth
mean-fisherman-wealth
2
1
11

MONITOR
653
186
740
231
num active pods
num-active-pods
0
1
11

MONITOR
655
250
788
295
num active fishermen
num-active-fishermen
0
1
11

PLOT
839
139
999
259
wealth-groups
income category
log(wealth)
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"wealth" 1.0 1 -10899396 true "" ""

SWITCH
10
299
191
332
spatial-restriction
spatial-restriction
1
1
-1000

MONITOR
932
413
989
458
Year
current-year
0
1
11

PLOT
838
12
998
132
annual-catch
time
size
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"catch" 1.0 0 -2674135 true "" ""

PLOT
838
269
998
389
fisherman-wealth
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"wealth" 1.0 0 -10899396 true "" ""

MONITOR
790
412
863
457
percent catch
(sum [catch-size] of fishermen) / (total-population-size + 1)
2
1
11

MONITOR
136
75
208
120
total-pop
num-pods * pod-size
0
1
11

MONITOR
870
413
927
458
F
(total-catch-size) / ((1.0 + growth-rate) * total-population-size)
2
1
11

SLIDER
103
427
195
460
extra-tax
extra-tax
0
1.0
0.15
0.05
1
NIL
HORIZONTAL

MONITOR
656
347
784
392
annual catch size
annual-catch-size
0
1
11

@#$#@#$#@
## WHAT IS IT?

This model is used to explore population dynamics and harvest economics of the Blue Crab in the Chesapeake Bay

## HOW IT WORKS

The model uses two main classes of agents: crabs and fishermen.  Crab agents represent a group of crabs (called a "pod").  Fishermen agents represent a single fisherman on a vessel.

The model simulates 1982 to 1999 in order to compare with published crab harvest data.  Each tick represents 6 months of real time.  Crabs move and reproduce during the summer/fall seasons, and do not move or reproduce during the winter/spring seasons.

The model includes three types of scenarios.  The first scenario is the "default" scenario, in which fisherman may sail anywhere in the waterscape and harvest without any restrictions.  The second scenario implements a spatial restriction, such that fishermen are not allowed to harvest in certain geographic areas.  The third scenario implements a tax-based harvest limiting policy, in which fishermen are heavily taxed for harvesting more than the average catch taken by the fishing fleet each period.

The model begins by defining constants and the initial waterscape, establishing the crab populations, and placing the fishermen.  The main "go" method for the model alternates between actions for the crab and fishermen populations. The crabs move (in the summer/fall season only), then breed once per year (again in the summer/fall season). The fishermen move, harvest, sell their catch, pay taxes, accumulate wealth, and potentially pay additional taxes if they overfish.

## HOW TO USE IT

There are a number of parameter settings on the model.

num-pods:
controls the number of pods of crabs in the simulation.

pod-size:
controls the number of crabs in each pod in the simulation.
The total initial crab population is defined by the product of num-pods * pod-size.  Typical estimated values for the Chesapeake Bay crab population vary, however, figures of from 230 to 870 million are plausible.

growth-rate:
controls the reproductive efficiency of the crab populations.  Typical values range from 3% to 15% or more.

carrying-capacity:
controls the maximum number of crabs in a pod. In population biology,
the carrying capacity K is a function of the geographic region in which the population resides, and reflects the influcences of habitat suitability.  In this model, K is stylized to represent the maximum size a crab pod can obtain, even though crab pods move from place to place.  The relationship  between carrying-capacity and pod-size is important: as pod-size approaches carrying-capacity, the rate of growth for the pod declines.  If pod-size is greater than carrying capacity, the the rate of growth becomes negative and the population declines until it reaches the carrying capacity value.  In the simulation, changing the carrying-capacity value then indirectly governs the regeneration rate of the crab population.

num-vessels:
controls the size of the fishing fleet.  Each vessel is assumed to be independent and represents one fisherman.

catchability-rate:
controls the efficiency of the fishing operation.  This value is used to represent the ability of the fleet to harvest the target species.  It includes the effectiveness of the fishing equipment as well as the ability of the species to avoid being captured.  Typical values for crab fishing are about 17%.

spatial-restriction:
This toggle is used to enable and disable the use of spatial restrictions on crab fishing.  If disabled, vessels may sail anywhere in the waterscape and fish at will.  If enabled, large sections of the waterscape are "off limits" for fishing, and vessels sailing in these regions are not allowed to fish.  The effect of this is to limit the fishing pressure on the crabs.

market-price-per-unit:
arbitrary value used to express the market price for crabs.  This is not intended to be aligned with any particular currency, but rather is used as a stylized measurement of the economic value of a harvested crab.

production-cost-per-unit:
arbitrary value used to represent production costs associated with harvesting crabs.  This is not intended to be aligned with any particular currency, but rather is used as a stylized measurement of the economic cost associated with harvesting a crab.

base-tax:
arbitrary amount by which the entire catch is taxed.  This is roughly equivalent to a "sales tax" except that it is paid by the fisherman rather than the buyer.  The intent is to represent state-sponsored taxation of crab fishing as an economic tool to regulate harvesting.

extra-tax:
arbitrary amount by which harvests in excess of the mean harvest are taxed. Under this method, if the extra-tax is 0, then excess harvesting is not taxed.  However, if the extra-tax is > 0, then each fisherman's harvest is compared to the average catch size for the fleet, and any amount in excess of the average is taxed using a graduated scale of (base-tax * sd), where sd is the number of standard deviations above the mean for the excessive catch size. Thus, fishermen are incentivized to limit catches that would put them over the mean catch size, as this would result in negative utility even though they are harvesting more crabs.



## THINGS TO NOTICE

The base scenario is sensitive to the relationship between pod-size and carrying-capacity.

Note the differences in population dynamics when the spatial restrictions are used and not used, even with all other things being equal.

## THINGS TO TRY

1. Try changing the pod-size and num-pods to alter the population size.
2. Try changing the number of vessels in the fleet or the catchability-rate
3. Try altering the base-tax and extra-tax rates to see the effect on harvesting

## EXTENDING THE MODEL

The crab population model is very simple now, and does not account for variations in age in the population. This is important for crab biology, as only mature 3 year old females can reproduce.  In addition, most harvesting is limited to 2 or 3 year old crabs (the actual restrictions are usually based on carapice size).

The crab movement model is very simple, and does not reflect geographically realistic migration patterns. These could be incorporated to more accurately show the spatial location of crabs at different times of the year.

The model uses a stylized landscape. A more explict model could use a better representation of the Chesapeake Bay geography.

The economic model is very simple. More advanced models could be implemented, such as using subsidies for under-harvesting, for example.

## NETLOGO FEATURES

No particularly unusual NetLogo features were used.

## RELATED MODELS

Some related models in the Biology library may be of interest.  The Wolf Sheep predation and the Rabbits Grass Weeds models are good demonstrations of population dynamics involving harvest and competition.

## CREDITS AND REFERENCES

An excellent reference on the mathematics of sustainable fisheries harvesting is:

Clark, Colin.  Mathematical Bioeconomics: The Optimal Management of Renewable Resources. John Wiley and Sons,  New York, NY.  1990.
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

blue crab
true
8
Polygon -11221820 true true 120 195 90 225 135 195 165 195 210 225 180 195
Polygon -11221820 true true 105 210 75 225 75 240 105 240
Polygon -11221820 true true 195 210 195 240 225 240 225 225 195 210
Polygon -11221820 true true 120 165 90 165 60 195 90 180 120 180
Polygon -11221820 true true 105 150 75 150 45 180 75 165 105 165
Polygon -11221820 true true 105 120 75 120 60 105 60 90 30 60 75 90 60 45 90 90 75 105 105 105
Polygon -11221820 true true 195 120 225 120 240 105 240 90 255 60 225 90 240 45 210 90 225 105 195 105
Polygon -11221820 true true 195 150 225 150 255 180 225 165 195 165
Polygon -11221820 true true 180 165 210 165 240 195 210 180 180 180
Polygon -11221820 true true 165 180 195 180 225 210 195 195 165 195
Polygon -11221820 true true 105 120 120 105 180 105 195 120 225 135 180 195 120 195 75 135 105 120
Polygon -11221820 true true 135 180 105 180 75 210 105 195 135 195
Line -11221820 true 135 105 135 90
Line -11221820 true 165 105 165 90

boat
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

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

crab boat
true
0
Polygon -7500403 true true 30 150 50 194 255 195 270 150 240 150 120 150 120 120 75 120 75 150
Polygon -7500403 true true 210 165 165 90 225 165 240 90

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
<experiments>
  <experiment name="base scenario" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="36"/>
    <metric>total-population-size</metric>
    <metric>annual-catch-size</metric>
    <enumeratedValueSet variable="extra-tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-restriction">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="production-cost-per-unit">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-vessels">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-price-per-unit">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-tax">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-pods">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catchability-rate">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pod-size">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrying-capacity">
      <value value="750000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="spatial restriction scenario" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="36"/>
    <metric>total-population-size</metric>
    <metric>annual-catch-size</metric>
    <enumeratedValueSet variable="extra-tax">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-restriction">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="production-cost-per-unit">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-vessels">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-price-per-unit">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-tax">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-pods">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catchability-rate">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pod-size">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrying-capacity">
      <value value="750000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="extra tax scenario" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="36"/>
    <metric>total-population-size</metric>
    <metric>annual-catch-size</metric>
    <enumeratedValueSet variable="extra-tax">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-restriction">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="production-cost-per-unit">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-vessels">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="market-price-per-unit">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="base-tax">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-pods">
      <value value="5000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catchability-rate">
      <value value="0.17"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-rate">
      <value value="0.14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pod-size">
      <value value="150000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="carrying-capacity">
      <value value="750000"/>
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
