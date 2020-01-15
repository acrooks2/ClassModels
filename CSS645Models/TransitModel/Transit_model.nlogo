;; Conceptual model of commuter transit
;; Model supports multi-modal trip-chaining and commuter decision making

;; global attributes for objects
globals [
  cell-size;; length (distance) equiv of crossing a cell one side to the other
  cell-size-unit ;; unit of measure as string e.g. "miles"

  time-tick ;; what one tick represents
  time-tick-unit ;; unit of measure as string e.g. "seconds"

  agent-rep ;; how many units one agent represents e.g. 1 agent = 10 people
  agent-unit ;; unit of measure of agent rep as string e.g. "people" or "cars"

  passerby-per-route
  local-resid-high-dense

  capacity-per-lane ;; how many cars per lane per cell

  tempx ;; variables needed for passing xy location between patch and turtle
  tempy ;; variables needed for passing xy location between patch and turtle

  route-list ;; placeholder for am or pm commuter route list

  time-value ;; variable to pass %at cap between patch and turtle

  total-average-speed-calc-impact
  total-average-trip-time
  %happy

  toll-road-pass-thru

 trans-max-cap-per-lane-check ;;to see if updates to screen

  ]

turtles-own [
  commuter-type ;; 1 passerby, 2 local, 3 outside
  commuter-status ;; 1 at home, 2 am commute, 3 at work, 4 pm commute, 5 return home
  commuter-ready ;; 0 for at home or work, 1 ready to start commute

  home-loc
  work-loc

  commute-mode ;; 1 car 2 bus 3 metro
  commute-public-transit-willingness
  pay-parking

  commute-am-time-start
  commute-pm-time-start

  am-route-list ;; morning commute segments
  pm-route-list

  previous-patch ;; cell from 1 tick ago
  previous-patch2 ;; cell from 2 ticks ago, used to calculate speed
  possible-patches ;; neighoring cells can possibly move to
  next-patch ;; cell the commuter will go to next

  current-trip-start-tick ;; tick at time took first step calculated in commute
  cells-traversed ;; based on number of cells traversed calculated in commute
  current-trip-end-tick ;; tick at reach work-loc calculated in commute
  current-prev-time ;; time when current location assigned calc in commute
  current-prev2-time ;; time at previous-patch2 assign  calc in commute

  current-trip-time ;; current trip time based on value assigned
  current-trip-time-ticks ;; current time spend in commute since start calc in metrics
  current-speed ;; based on distance between current and previous-patch2 and time diff
  current-trip-speed-avg ;; based on tick time since start and number of cells traversed calc in metrics

  commuter-impact-time-check ;; calculates time for cell based on % at cap
  trip-time-from-commuter-impact-on-patch ;; time based on impacts of % at cap
  commuter-impact-trip-speed-avg ;; speed based on opt-time
  patch-capacity  ;; %at capacity of patch-here, used to colorize agent

  opt-time-check
  trip-time-from-patch-opt-time
  opt-trip-speed-avg ;; speed based on opt-time

  best-time-check
  trip-time-from-patch-best-time
  best-trip-speed-avg ;; speed based on best-time

  commute-trips ;; count of commute trips taken

  total-trip-distance ;; total number of cells traversed calc in metrics
  total-trip-time ;; time based on impact from commuters
  total-trip-speed-avg ;; speed based on impact from commuters

  memory-am-commute-trip-times-list
  memory-am-commute-trip-distance-list
  memory-am-commute-speed-avg-list
  memory-am-commute-rating-list
  memory-commute-trip-cost-list

  commute-mean-time
  commute-mean-time-avg-all ;; average time of all commutes
  best3-commute-time-avg ;; best commute time (could be lowest 3 commutes averaged)
  past3-commute-time-avg ;; average time of past 3 commutes

  commute-happiness-rating ;; -1 not happy, 0 indifferent, 1 happy based on current commute compared to past 3 average
  commute-rating-list ;; memory of commute-happiness-rating
  commute-overall-rating ;; sum of commute rating list

  inefficiency ;; if under avg city speed, extra fuel spent
  car-gas-cost ;; gas and inefficiency not car price or depreciation
  toll-fare-cost ;; car, bus, or metro
  other-costs ;; e.g. parking
  commute-trip-cost ;; total costs per trip


   ]

patches-own [
  trans-cat ;; for colorizing  ;; 1 for toll road, 2 for state major, 3 for state minor, 4 for county, 5 for local
  trans-id ;; id number assigned to the route
  name ;; road name
  speed-limit ;; speed limit
  best-time ;; shortest time with no traffic no lights
  opt-time ;; time with lights
  lanes ;; number of lanes
  max-capacity ;; cell capacity
  current-count ;; number of commuters here
  percent-at-capacity ;; calculates % at capacity
  LOS ;; level of service rating

  density ;; residential

  ]


;;****************************
;;   SETUP / INITIALIZATION
;;*****************************
 ;; SETUP and Transit, people, background, globals
 to import-transit ;; procedure to load transit color grid world and background map image
    clear-all
    import-world "Data/transit_background_w_people world.csv"
    import-drawing "Data/background_reston_map.png"
    initialize-values ;; set globals
    reset-ticks
 end

 ;;
 ;; Initialize values
 ;;
 ;; assign global and attributes to agents
 to initialize-values
   ;; initialize globals
    set cell-size .04
    set cell-size-unit "miles"
    set time-tick 2.7
    set time-tick-unit "seconds"

    ask turtles [
        set color 65
        set previous-patch patch-here
        set memory-am-commute-trip-times-list []
        set memory-am-commute-trip-distance-list []
        set memory-am-commute-speed-avg-list []
        set memory-am-commute-rating-list []
        set memory-commute-trip-cost-list []
        set commute-rating-list []

        set commute-mode 1 ;; 1 car 2 bus 3 metro ;; for now single mode
    ]

    ask patches
    [
      set max-capacity lanes * trans-capacity-per-lane ;; from GUI
      ]
 end



;;****************************
;;      GO
;;*****************************
 ;; GO PROCEDURES
 to go
    commute ;; move, receive and eval info, make decisions at intersections, arrive at end
    calc-metrics ;; calc metrics of current trip speed, distance, travel time for current, trip, and memory
    check-loc ;; check location to see if arrived at work or home
    eval-commute ;; assess happiness with commute and update memory
    update-variables ;; update values for plots
    tick
 end

;;
;;  COMMUTE
;;
;; to move forward one cell, pick cell from Moore with trans-id in agent route list, if not previous 2 cells then face it and move to cell
 to commute
    if ticks > 0 ;; need this or else error with divisible by zero
     [
        ;; allows commuters to trickle into system at designated times,
      ;; USE THESE TWO LINES IF USING A SCHEDULER, ALSO SEE 2 LINES AT VERY END OF EVAL-COMMUTE
        ;; if all? turtles [commuter-ready = 0]
        ;;     [ask turtles [set commuter-ready 1]]

       ;; for commuters ready to move....
       ask turtles with [commuter-ready = 1] ;; 1 = ready to commute, 0 = just got home or to work
         [  set size 1
           ;; get commuter route list based on where commuter is to indicate time of day as morning or afternoon
           if commuter-status = 1 or commuter-status = 2 [set route-list am-route-list] ;; if at home or doing morning commute
           if commuter-status = 4 [set route-list pm-route-list] ;; if starting afternoon commute

          ;; let diff ticks -  current-prev-time  ;; for debugging commuters that get stuck at intersections
           ;;if diff > 50 [ set size 2 rt 180]

           ;; find neighboring cell to move to that is in the route list but not past 2 cells already been to
           let numb-list route-list ;; local varable so patches can read turtle route list
           set possible-patches neighbors with [member? trans-id numb-list]  ;; of the 8 neighbor cells, pick those with matching road-id to calling turtle
           set next-patch (one-of possible-patches) ;; picks one of the set and assigns as next patch to possibly go to

           ;; this step adds noise to model, if picked a patch that was one of past 2 previous ones visited, then pick again, if happens again then skip
           if next-patch != 0 ;; needed or else error from null set on first tick or end of view
              [ifelse next-patch = previous-patch or next-patch = previous-patch2 ;; if picked cell that was previously traversed pick again)
                 [set next-patch (one-of possible-patches)] ;; this causes some natural delays if second pick is still a previous

                 ;; update values of previous patches visited
                 [if next-patch != previous-patch  ;; else statement to move
                     [set previous-patch2 previous-patch  ;; reset variables for previous before moving
                      set current-prev2-time current-prev-time ;; pass back the time value that matches
                      set previous-patch patch-here ;; reset variables before moving
                      ;;set current-prev-time ticks ;; set new time for this location
                     ;; set current-prev-time (commuter-impact-time-check) ;; set new time for this location based on sum of impact time


                      ;; face next patch and move forward one step and change status to commuter
                      face next-patch  ;; orient (change heading so can move fd 1 to next cell)

                      ;; if just starting out commute from home or work, update status to commuting before actually moving
                      if patch-here = home-loc [set commuter-status 2] ;; am commuter
                      if patch-here = work-loc [set commuter-status 4] ;; pm commuter
                      if current-trip-start-tick = 0 [set current-trip-start-tick commuter-impact-time-check] ;; start of new trip with this tick for time setting

                      ;; move forward one cell
                      fd 1

                      ;; after moving forward update distance and time ticks
                      set cells-traversed (cells-traversed + 1) ;; update distance traveled used in metrics
                     ]
                   ]
                 ]
            ]
       ]
 end


;;
;;  CALCULATE METRICS
;;
;; calc metrics on commute in progress
;; Commuter-Environment impacts
 to calc-metrics

    ;; Update transportation percent at capacity and assign time impact on commuters
    ask patches with [trans-id >= 1]
       [;; calcuate cell %capacity based on count of agents on cell vs max capacity (number of lanes * user specified max capacity)
         set current-count count turtles-here
         set percent-at-capacity ((current-count / max-capacity) * 100  )

         ;; update cells % at capacity and corresponding time-penalty, non-linear
         if percent-at-capacity < 11 [set time-value (opt-time * .92) ask turtles-here [set patch-capacity percent-at-capacity]]
         if percent-at-capacity >= 11 and percent-at-capacity <= 30 [set time-value (opt-time * 1) ask turtles-here [set patch-capacity percent-at-capacity]]
         if percent-at-capacity >= 31 and percent-at-capacity <= 50 [set time-value (opt-time * 1.2) ask turtles-here [set patch-capacity percent-at-capacity]]
         if percent-at-capacity >= 51 and percent-at-capacity <= 65 [set time-value (opt-time * 1.7) ask turtles-here [set patch-capacity percent-at-capacity]]
         if percent-at-capacity >= 66 and percent-at-capacity <= 80 [set time-value (opt-time * 3) ask turtles-here [set patch-capacity percent-at-capacity]]
         if percent-at-capacity >= 81 and  percent-at-capacity <= 90 [set time-value (opt-time * 6) ask turtles-here [set patch-capacity percent-at-capacity]]
         if percent-at-capacity >= 91 [set time-value (opt-time * 30) ask turtles-here [set patch-capacity percent-at-capacity]]

         ;; updates time impacts for commuters on the cell, based on cells % at capacity
         ask turtles-here [set commuter-impact-time-check time-value]
         ]

    ;; Update commuter's current commute metrics (time and speed - note that distance is calculated in the commute section)
    ask turtles with [((commuter-status = 2) or (commuter-status = 4)) and commuter-ready = 1]  ;; ask only turtles currently commuting
       [;; need to have crossed 2 cells to compute distance and speed
        if cells-traversed >= 2
          [;; calculate travel time as difference from current time and time when started commute
           ;; note that for analysis there are 4 different ways to calculate times
           ;; time from just simulation number of ticks
           set current-trip-time-ticks (ticks - current-trip-start-tick)
           ;; time based on sum of cell's assign best-time for cells traversed (think of max typical speed or as free-flow time with no traffic or lights)
           set best-time-check [best-time] of patch-here
           set trip-time-from-patch-best-time (trip-time-from-patch-best-time + best-time-check)
           ;; time based on sum of cell's optimum time (which takes into account typical speed effects such as slowing in curves or uphills and traffic lights)
           set opt-time-check [opt-time] of patch-here
           set trip-time-from-patch-opt-time (trip-time-from-patch-opt-time + opt-time-check)
           ;; time based on sum of cell's %at capacity and corresponding time impact (this takes into account congestion resulting from other commuters on cell)
           set current-prev-time trip-time-from-commuter-impact-on-patch
           set current-trip-time (trip-time-from-commuter-impact-on-patch + commuter-impact-time-check)

           set trip-time-from-commuter-impact-on-patch (trip-time-from-commuter-impact-on-patch + commuter-impact-time-check)

           ;; calculate speed as difference in time and distance between current cell and the cell from 2 prevous time units ago
           if ticks != current-prev2-time
              [ifelse distance previous-patch2 = 0 [set current-speed 0] ;; so no division by zero
                   [set current-speed ((distance previous-patch2 * cell-size) / ((current-trip-time - current-prev2-time) / 3600)) ] ;; current speed is based on time and distance from previous-patch2

              ;; calculate average speed so far on trip based on sum of "time" gathered over cells traversed
              if current-trip-time-ticks != 0
                [;; speed based on cells traversed (calculated in commute) and total current trip time
                  set current-trip-speed-avg ((cells-traversed * cell-size) / (current-trip-time-ticks / 3600))
                 ;; calculate speed based on time from sum of opt time value of cells (note divide by 2 for standardizing comparison otherwise speed seems too low)
                  set opt-trip-speed-avg ((cells-traversed * cell-size) / ((trip-time-from-patch-opt-time / 2) / 3600))
                 ;; calculate speed based on time from sum of best time value of cells (note divide by 2 for standardizing comparison otherwise speed seems too low)
                  set best-trip-speed-avg ((cells-traversed * cell-size) / ((trip-time-from-patch-best-time / 2) / 3600)) ;; speed based on cells traversed (calculated in commute) and total current trip time
                 ;; calculate speed based on commuter impact time on cell
                  set commuter-impact-trip-speed-avg  (((cells-traversed * cell-size) / ((trip-time-from-commuter-impact-on-patch) / 3600)) * 2 );; speed based on cells traversed (calculated in commute) and total current trip time
                 ]
              ]
           ]
         ]
 end



;;
;;  CHECK LOCATION
;;
;; if arrived at work or home, change commute status, calculate total trip metrics, update memory
 to check-loc
    ;; update commute status if arrived at home or work
    ask turtles ;; this ask turtles line makes it really slow
      [;; if doing am-commute, did you arrive at work? if so change status to at work
        if patch-here = work-loc
           [if commuter-status = 2 [set commuter-status 3 set commuter-ready 0]]
        ;; if doing pm-commute, did you arrive at home? if so change status to at home
        if patch-here = home-loc
           [if commuter-status = 4 [set commuter-status 5 set commuter-ready 0]]
        ;; if a passerby on toll road and at western most edge, jump to home
        if patch-here =  patch -32 -1 ;; specific to Reston
           [if commuter-status = 4 [move-to home-loc set commuter-status 5 set commuter-ready 0]]
        ]

     ;; update total trip metrics now that commuter is done with commute
     ask turtles with [(commuter-ready = 0) and ((commuter-status = 3) or (commuter-status = 5))] ;; if at work or home following commute
        [ ;; calculate trip stats based on trip times and speed from impact with other commuters calculated above
            set commute-trips commute-trips + 1
            ;; update trip metrics based on commuter impact, could swap out for ticks, best-time, or opt-time as well
            set total-trip-time trip-time-from-commuter-impact-on-patch
            set total-trip-distance (cells-traversed * cell-size)
            set total-trip-speed-avg commuter-impact-trip-speed-avg

            ;; calculate trip costs
               if commute-mode = 1 ;; by car
                 [;; driving fuel cost impacted by average speed
                  ifelse commuter-impact-trip-speed-avg < avg-fuel-effic-rating-city
                         [set inefficiency (1 + ((avg-fuel-effic-rating-city - commuter-impact-trip-speed-avg) / avg-fuel-effic-rating-city))]
                         [set inefficiency 1]
                  set car-gas-cost ((total-trip-distance / avg-fuel-effic-rating-city) * inefficiency * gas-price-per-gallon )

                 ;; other costs (parking at metro)
                   if pay-parking = 1
                      [set other-costs metro-car-parking-cost]
                 ;; tolls/fares cost
                    if member? 2674 am-route-list ;; specific to Reston, if took toll road east beyond Reston
                       [set toll-fare-cost car-toll-costs-one-way]
                  ]
               if commute-mode = 2 [set toll-fare-cost  bus-fare-costs-one-way] ;; need to fix if multimodal
               if commute-mode = 3 [set toll-fare-cost  metro-fare-peak-one-way] ;; need to fix if multimodal
            set commute-trip-cost car-gas-cost + other-costs + toll-fare-cost ;; sum of trip costs

            ;; update memory
            set memory-am-commute-trip-times-list fput total-trip-time memory-am-commute-trip-times-list
            set memory-am-commute-trip-distance-list fput total-trip-distance memory-am-commute-trip-distance-list
            set memory-am-commute-speed-avg-list fput total-trip-speed-avg memory-am-commute-speed-avg-list
            set memory-commute-trip-cost-list fput commute-trip-cost memory-commute-trip-cost-list

            ;; clear out values
            set previous-patch2 patch-here
            set previous-patch patch-here
            set cells-traversed 0
            set current-trip-start-tick 0
            set current-trip-time-ticks 0
            set current-trip-speed-avg 0
            set trip-time-from-patch-opt-time 0
            set trip-time-from-patch-best-time 0
            set commuter-impact-time-check 0
            set trip-time-from-commuter-impact-on-patch 0
           ]
 end


;;
;; EVALUATE COMMUTE
;;
;; after each commute assess contentment with commute trip time compared to expectations based on previous commutes
;; at end of day at home, assess overall contenment with commute history, in future can modify behavior based on this value
 to eval-commute
    ask turtles with [commuter-status = 3 or commuter-status = 5]
      [;; compare current commute to others
        if commute-trips >= 2 and commute-trips < 4
           [ let temp-list1 memory-am-commute-trip-times-list
             set commute-mean-time-avg-all mean temp-list1
             set commute-mean-time commute-mean-time-avg-all
           ]
        ;; calculates average of past commute times, and then average of 3 of past, best commutes which could be used for analysis
        if commute-trips >= 4
          [;; calculate average commute time, could use a weighted average perhaps
              let temp-list memory-am-commute-trip-times-list
              set commute-mean-time-avg-all mean temp-list
            ;; calculate average of past 3 commutes
              let past-3 sublist temp-list 0 2
              set past3-commute-time-avg mean past-3 ;; takes average of last 3 commutes before actually sorting list
            ;; calculate average of best 3 commutes
              let sort-list sort temp-list ;; sort to start with lowest
              let best-3 sublist sort-list 0 2
              set best3-commute-time-avg mean best-3
             ;; set the value to be used for to compare against current commute
             set commute-mean-time past3-commute-time-avg
            ]
      ;; Assess happiness with current commute
       ;; compare total trip time (from check location section) to the mean of previous commutes
      if commute-trips >= 2
         [ ;; -1 unhappy 0 indifferent 1 very happy
           if total-trip-time > commute-mean-time [set commute-happiness-rating -1]
           if total-trip-time = commute-mean-time [set commute-happiness-rating 0]
           if total-trip-time < commute-mean-time [set commute-happiness-rating 1]
           set commute-rating-list fput commute-happiness-rating commute-rating-list
         ]
      ]

  ;; Assess overall happiness by summing up commute ratings over time, when at home
  ;; can only change something when get home at end of day to prep for next day
    ask turtles with [commute-trips >= 4 and commuter-status = 5]
        [set commute-overall-rating sum commute-rating-list]

  ;; Get ready for next commute
    ;; wait for all others to finish commute before going again
    ask turtles with [commuter-status = 3 or commuter-status = 5]
        [;; turn around 180 degrees to do reverse direction for next commute
          rt 180
          ;; move to start locations and change status
          if commuter-status = 3 [move-to patch 32 -15 set commuter-status 4 ] ;; for Reston model, move to west bound toll road
          if commuter-status = 5 [set commuter-status 1] ;; if at home at end of pm commute, change to morning commute.
          set commuter-ready 1 ;; this allows commuters to move constantly, COMMENT OUT IF USING A SCHEDULER
          ;;set size 0 ;; make them disappear USE THIS IF USING A SCHEDULER
         ]
 end



;;
;;  UPDATE VARIABLES
;;
;; update plots and any user changes
 to update-variables
   ;; check for any user changes to variables and display for commuters
    if trans-max-cap-per-lane-check < trans-capacity-per-lane or trans-max-cap-per-lane-check > trans-capacity-per-lane
        [ask patches
            [set max-capacity lanes * trans-capacity-per-lane ];; from GUI
          set trans-max-cap-per-lane-check trans-capacity-per-lane
          ]
    ;; Pick list for displaying commuters
    if commuter-color = "same" [ask turtles [set color green]]
    if commuter-color = "speed" [ask turtles with [current-speed >= 50] [set color green] ;; fast
                                 ask turtles with [current-speed < 50] [set color yellow] ;; medium
                                 ask turtles with [current-speed <= 30] [set color red]] ;; slow
    if commuter-color = "congestion" [ask turtles with [patch-capacity >= 50] [set color red]  ;; congestion %capacity
                                     ask turtles with [patch-capacity < 50] [set color yellow] ;; medium congestion
                                     ask turtles with [patch-capacity <= 30] [set color green]] ;; low congestion
    if commuter-color = "trip-time" [ask turtles with [total-trip-time >= (total-average-trip-time + (total-average-trip-time / 4))] [set color red] ;; slow
                                 ask turtles with [total-trip-time < (total-average-trip-time + (total-average-trip-time / 4))] [set color green] ;; medium
                                 ask turtles with [total-trip-time <= (total-average-trip-time - (total-average-trip-time / 4))] [set color blue]] ;; fast
    if commuter-color = "trip-speed" [ask turtles with [commuter-impact-trip-speed-avg >= 50] [set color green] ;; fast
                                 ask turtles with [commuter-impact-trip-speed-avg < 50] [set color yellow] ;; medium
                                 ask turtles with [commuter-impact-trip-speed-avg <= 30] [set color red]] ;; slow
    if commuter-color = "happy" [ask turtles with [commute-overall-rating >= 2] [set color blue] ;; happy
                                 ask turtles with [commute-overall-rating < 2] [set color yellow] ;; indifferent
                                 ask turtles with [commute-overall-rating <= 1] [set color red]] ;; not happy

  ;; calculate global variables used for plots
    if ticks > 2
       [let div0check count turtles with [commuter-status = 2] ;; need this to prevent error message for division by 0
         if div0check != 0
         [ set total-average-speed-calc-impact (sum [commuter-impact-trip-speed-avg] of turtles / (count turtles))
           set total-average-trip-time (sum [total-trip-time] of turtles / (count turtles))
           set %happy ((count turtles with [commute-overall-rating >= 2] / count turtles) * 100)
          ]
       ]

 ;; histogram of current speed
  set-current-plot "Current Speed"
  set-current-plot-pen "Speed"
  set-histogram-num-bars 2000
  histogram [current-speed] of turtles


 ;; histogram of trip time
  set-current-plot "Trip Times"
  set-current-plot-pen "Commute Time"
  set-histogram-num-bars 1000
  histogram [total-trip-time / 60] of turtles

 ;; histogram of commute time
  set-current-plot "Trip Speed Avg"
  set-current-plot-pen "Trip Speed"
  set-histogram-num-bars 1000
  histogram [total-trip-speed-avg] of turtles



 end
@#$#@#$#@
GRAPHICS-WINDOW
228
62
1276
631
-1
-1
16.0
1
10
1
1
1
0
0
0
1
-32
32
-17
17
0
0
1
ticks
15.0

BUTTON
307
12
370
45
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

PLOT
11
68
216
223
Average Speeds
Time
Speed (mph)
0.0
30.0
0.0
3.0
true
true
"" ""
PENS
"Trip" 1.0 0 -955883 true "" "plot total-average-speed-calc-impact"
"Current" 1.0 0 -7500403 true "" "plot (sum [current-speed] of turtles / count turtles)"

MONITOR
8
10
134
55
Number of Agents
count turtles
17
1
11

BUTTON
234
11
300
44
Setup
import-transit
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
409
13
624
46
trans-capacity-per-lane
trans-capacity-per-lane
1
200
30.0
1
1
per cell
HORIZONTAL

SLIDER
1307
133
1504
166
gas-price-per-gallon
gas-price-per-gallon
.01
5.99
3.47
.01
1
$
HORIZONTAL

SLIDER
1302
172
1513
205
car-toll-costs-one-way
car-toll-costs-one-way
.25
10.00
4.75
.25
1
$
HORIZONTAL

SLIDER
1298
216
1517
249
bus-fare-costs-one-way
bus-fare-costs-one-way
.25
10.00
4.75
.25
1
$
HORIZONTAL

SLIDER
1299
256
1515
289
metro-car-parking-cost
metro-car-parking-cost
.25
25.00
0.25
.25
1
$
HORIZONTAL

SLIDER
1300
298
1517
331
metro-fare-peak-one-way
metro-fare-peak-one-way
.10
15.00
7.5
.10
1
$
HORIZONTAL

SLIDER
1293
95
1516
128
Avg-Fuel-Effic-Rating-City
Avg-Fuel-Effic-Rating-City
1
50
28.0
1
1
mpg
HORIZONTAL

CHOOSER
656
10
794
55
commuter-color
commuter-color
"same" "speed" "congestion" "trip-time" "trip-speed" "happy"
3

PLOT
7
365
215
485
Trip Times
Commute Time (mins)
Number
0.0
50.0
0.0
75.0
false
false
"" ""
PENS
"Commute Time" 1.0 1 -16777216 true "" ""

PLOT
7
493
217
616
Trip Speed Avg
Trip Avg Speed (mph)
Number
0.0
75.0
0.0
75.0
false
false
"" ""
PENS
"Trip Speed" 1.0 1 -16777216 true "" ""

TEXTBOX
1312
27
1498
89
These variables are associated with trip costs. However they do not currently impact behavior, so they are moved out of the way.
11
0.0
1

PLOT
9
232
213
356
Current Speed
Speed (mph)
Number
0.0
85.0
0.0
200.0
false
false
"" ""
PENS
"Speed" 1.0 1 -16777216 true "" ""

MONITOR
141
11
208
56
avg speed
sum [current-speed] of turtles / count turtles
2
1
11

TEXTBOX
11
618
221
674
Note that Trip Times and Trip Speed Avg are calculated at end of each commute. And one agent = 10 people.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is an abstract model to simulate commuter behavior. The environment and representation of commuters is based on data for Reston, VA.

## HOW IT WORKS

The model imports a pre-made environment with defined transit routes and commuters with pre-coded commute routes for the morning and afternoon. The commuters trip time and speed is impacted by the amount of other commuters in the same space.

For population size, 1 agent represents 10 commuters. 

## HOW TO USE IT

The model is very simplistic and the user may change the capacity of the lanes to view impacts on speed, congestion, and trip times. The user can change the display color of the commuters. The display colors indicate red for bad conditions such as slow speeds or long travel times or high congestion.

## THINGS TO NOTICE

Changing the capacity to lower values results in big impacts on time and speed. Free-flow traffic exists with values of 100 and up.

The commuters do not exactly appear to follow the routes on the map exactly due to the cell size used for the raster background. That level of quality is a tradeoff for simplicity of representation.

There are also sliders related to transit costs that do work, but currently do not yield any impact on commuter behavior.

## THINGS TO TRY

Change the display of the commuters and inspect them.

## EXTENDING THE MODEL

This model is a foundation to build upon with discreet timing that represents hourly or sub-hourly traffic volumes rather than daily volumes all at once. Additional modes of transit can be added as well as more complex commuter behavior such as route changing, time changing for commute start times, and changing transit modes.

## NETLOGO FEATURES

The model imports a world.csv file from another model's export, and also imports a map background display.

## RELATED MODELS

Traffic models are similar but at a different scope.
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
