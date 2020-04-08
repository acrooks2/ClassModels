;; *** MODEL OF CREATIVE CLASS IN CITY  ***********************************************************


globals [
  n-number
  percent-educated            ;; % of pop with college education; this value used for plot, calculated in brain-drain procedure
  percent-educated-cr         ;; % of creative with college education; value used for plot, calculated in brain-drain procedure
  indexofgini
  percent-poor
  percent-middle
  percent-rich
  ]

turtles-own [
  new               ;; allows for turtles created as result of pop-growth rate to get attributes
  hood-start
  afford-rent       ;; can turtle afford rent as percentage of income yes (1) or no (0)
  satisfied?        ;; satisifed when they are not looking to move, can afford rent, and have similar neighbors of same color
  content-w-neighbor;; percent of similar neighbors desired
  tolerance         ;; percent of similar neighbors desired
  similar-nearby    ;; number of turtles os same color on neighboring patches
  other-nearby      ;; number of turtles not of same color on neighbor patches
  total-nearby      ;; sum of previous two variables
  creative          ;;yes/no+
  creative-h        ;;highly creative yes/no
  creative-m        ;;medium creative yes/no
  creative-l        ;;low creative yes/no
  celebrity-status  ;; makes the most partnerships
  income            ;;normal dist
  income-start        ;;
  current-rent
  rent-%           ;; calculation of rent from patch/month
  rent-yr           ;; calculation of rent per year
  p-savings         ;;yes/no to invest to move or start business
  educated          ;;university degree yes/no
;;  employment-status ;;student, employed, notworking
;;  entrepreneurial   ;;yes/no desire to start own business, tried to get funding, training
  HighCreative?     ;; If true, the person is considered to be high-creative
  partnered?        ;; If true, the person is paired with an investment or creative inspiration partner.
  partner-timeshare ;; How long the person prefers to partner with investor/creative inspiration.
  partner           ;; The person paired up with for business venture or creative inspiration.
  ]


patches-own [
  neighborhood     ;; neighborhood region displayed
  outside          ;; not assigned a neighborhood
  hood-list        ;; list of neighborhoods overlapping
  landuse          ;; landuse value assigned ranges from 0-7
  amenities        ;; placeholder
  pop-count        ;; count of turtles on patch - used to classify patches as high-density residential
  pop-dens         ;; placeholder if wanted to specify density
  occupancy-start  ;; how many turtles were here at start
  %full            ;; % full based on pop-count compared to occupancy-start
  rent-start       ;; rent as assigned
  rent-current     ;; rent calculated
  creative-space   ;; true/false
  creative-value   ;; sum of value adde by turtles with creativity visiting patch
  creative-dens-p  ;; the start-pop of creative people per patch
  num-satisfied    ;; number of satisfied here
  pop-count-cr     ;; creative population counts use to assign creative value and creative space
  pop-count-crt
  pop-count-cr-h
  pop-count-cr-m
  pop-count-cr-ht
  pop-count-cr-mt
  pop-count-cr-n   ;; new pop count used to decline in number of creatives visit
  pop-count-cr-diff;; diff of count of creative pop to current count of creative pop if negative then gained value, otherwise decrease
  pop-count-cr-minus;; factor to subtract for loss of creative value
  ]


;; ***** TO SET UP ************************************
to setup           ;; Procedures that run when setup button is pressed
  clear-all
  setup-landuse
  setup-rent
  reset-ticks
  create-people
  setup-people
  create-neighborhoods
  setup-creative-space
  check-affordability
  update-variables
end


;; ***** DEFINE PATCH LANDUSE VALUES ************************************
;; average landuse for select city .....
to setup-landuse
    ask patches [set landuse 0];;  0 undeveloped white 24%
    ask n-of (1681 * 0.60) patches [set landuse 1] ;; 1 is residential light orange 31% ** this is where turtles can live
    ask n-of (1681 * 0.1) patches [set landuse 2] ;; 2 is commercial yellow 6%
    ask n-of (1681 * 0.1) patches [set landuse 3] ;; 3 is can't develop eg. airport etc gray 6%
    ;; landuse 4  place holder for high dense
    ask n-of (1681 * 0.1) patches [set landuse 5] ;; 5 is water light blue 19%
    ask n-of (1681 * 0.1) patches [set landuse 6] ;; 6 green areas 9%
end


;; ***** SETUP INITIAL RENTS ****************************

to setup-rent  ;; rent is average monthly rent in units
    ask patches [set rent-start random avg-rent set rent-current rent-start] ;; assign rent as normal distrubution around user specifed avg rent
end


;; ********CREATE INITIAL PEOPLE *******************************************************************

to create-people ;;used at set up only
   create-turtles start-pop [set creative-l 1 set size 1 set new 1] ;; ;; creates user-specified start-pop of turtles low creative
end

;; ******** ASSIGN ATTRIBUTES TO PEOPLE AND NEW POP GROWTH ********************
to setup-people
  ;; population growth rate
   if ticks >= 1 [if pop-growth-rate < 0 [ask n-of (count turtles * (abs pop-growth-rate / 100) / 12) turtles [die]]] ;; population decline
   if ticks >= 1  [create-turtles ((count turtles * (pop-growth-rate / 100)) / 12) [set creative 0 set creative-l 1 set size 1 set new 1] ] ;; create new turtles

  ;; assign attributs to new turtles

  ;; assign education
    ask n-of (count turtles with [new = 1 ] * (%educated / 100)) turtles with [new = 1]  [set educated 1]

  ;; move turtles to residential patch and assign neighborhood
    ask turtles with [new = 1]
        [move-to one-of patches with [landuse = 1]
          set hood-start [neighborhood] of patch-here]
     if ticks > 1 [if allow-development = false
        [ask turtles with [new = 1 and hood-start = 0]
          [move-to one-of patches with [landuse = 1 and outside = 0]
           set hood-start [neighborhood] of patch-here]]]

 ;; assign income as gamma curve
  if income-dist = "gamma"
    [let income-diff (top10% - percapita)
    let income-avg ((top10% + 9 * percapita) / 10) ;;weighted average
    let income-variance (income-diff * income-diff / 2)
    let alpha (percapita * percapita / income-variance)
    let lambda (1 / (income-variance / income-avg))
    ask turtles with [new = 1] [ set income-start int random-gamma (alpha * 2.5) (lambda * 2) set income income-start]
    ask turtles with [income-start < 1] [set income-start 1 set income income-start]]

    if income-dist = "bi-modal"
    [ask turtles with [new = 1] [set income-start int random-normal percapita 3 set income income-start]
     ask n-of (count turtles with [new = 1] * .1) turtles with [new = 1] [set income-start int random-normal top10% 1 set income income-start]
     ask turtles with [income-start <= 1] [set income-start 1 set income income-start]]

   ask turtles with [educated = 1] [set income income * 1.01]

 set percent-poor (count turtles with [income <= (percapita * .8)] / count turtles * 100)
 set percent-middle (count turtles with [income > (percapita * .8) and income <= 75000] / count turtles * 100)
 set percent-rich (count turtles with [income > 75000] / count turtles * 100)

;; assign rents to turtles
    ask turtles with [new = 1]
         [set current-rent [rent-current] of patch-here
          set rent-yr ([rent-current] of patch-here * 12)
          set rent-% (rent-yr / income * 100) ;; percentange of income that goes to rent
           ifelse rent-% >= rent%-of-income [set afford-rent 0] [set afford-rent 1] ] ;; if rent/yr for this patch less than income, poverty threshold then afford

 ;; assign creativity (assume creatives have a little more income, but high creatives have much more)
    ask n-of (count turtles with [new = 1] / 10)  turtles with [new = 1]   ;; 10% of pop is medium creative people
       [set creative 1 set creative-m 1 set creative-h 0 set creative-l 0 set income (income * 1.02)]
    ask n-of (count turtles with [new = 1] * (%PopHighCreative / 100)) turtles with [new = 1];; user specifies percent high creative - % of high creative assigned below
         [set creative 1 set creative-h 1 set creative-l 0 set creative-m 0 set income (income * 1.03)]



 ;; assign attributes that affect behavior
    ask turtles with [new = 1]
      [set partnered? false
       set partner nobody
       set tolerance int random-normal tolerance-for-others 6] ;; assigns normal dist around mean
        ask n-of (count turtles with [new = 1] * .2) turtles with [new = 1] [set tolerance random 100] ;;ask 20% to be random tolerance

  ;; makes the turtles not new anymore
     ask turtles [set new 0]
end


;; ***** CREATE NEIGHBORHOODS *******************
to create-neighborhoods ;; create neighborhoods as 7 random circles
  ask patches [set hood-list list (50) (50)] ;;created list with 50 as 2 last items in list
  repeat 7
   [set n-number n-number + 1    ;; iteration so can add name to neighborhood and add name
    ask n-of 1 patches
    [let p self
     let a max list 7 round (random-normal 7 (1 * 7))
     ask patches with [distance p <= a]
      [set neighborhood n-number
       set hood-list fput neighborhood hood-list  ;; a patch can be part of overlapping neighborhoods
       ask turtles-here with [hood-start = 0] [set hood-start n-number set color (orange + hood-start)] ] ;;for some strange reason removing the set color from here ruins the display
     ]]
   ask patches with [neighborhood = 0] [set outside 1 set hood-list fput neighborhood hood-list]

   ask turtles with [hood-start = 0]
     [move-to one-of patches with [landuse = 1 and neighborhood != 0]
        set hood-start [neighborhood] of patch-here]

end


;; ***** SET UP CREATIVE SPACE *******************
to setup-creative-space ;; create creative space to start based on density of creatives present, assigns creative value, bumps up rent on creative-space
 ask patches [

    set pop-count count turtles-here
    set occupancy-start pop-count

    set pop-count-cr-h count turtles-here with [creative-h = 1] ;; count high creative on patch
    set pop-count-cr-m count turtles-here with [creative-m = 1] ;; count medium creative
    set pop-count-cr count turtles-here with [creative = 1]     ;; count of creative people same as (pop-count-cr-h + pop-count-cr-m)
    set creative-dens-p creative-dens                           ;; user defines start-pop of creatives per patch used to define creative space (default is 3)

       ;;creates initial creative spaces when enough creative tutrles and not in an outside area (e.g. not in a neighbhorhood)
       ;;assigns rent as double cost and assigns creative value of 10 for high creative, and 5 for medium creative
    if pop-count-cr >= creative-dens-p
       [if allow-development = true [set creative-space 1 set rent-start (rent-start * 2) set creative-value ((pop-count-cr-h * 10) + (pop-count-cr-m * 5))]
        if allow-development = false [ifelse outside = 1 [] [set creative-space 1 set rent-start (rent-start * 2) set creative-value ((pop-count-cr-h * 10) + (pop-count-cr-m * 5))] ]
   ]]
end


;; *******GO PROCEDURES *******************************************************************
to go        ;; Procedures that run when go button is pressed
  setup-people ;;to create new people from pop-growth rate
  brain-drain  ;; educated leave
  move-unsatisfied
  update-cr-land-value
  check-partner  ;;  CONTROLS TURTLE INTERACTION AND SPREADS CREATIVITY - high creative turtles get larger after inspring others, comment out to check just schelling segregation rules
  check-affordability
  update-variables
  tick
end


;; ********* BRAIN-DRAIN  *************

to brain-drain  ;; some educated or creative turtles disappear or appear based on user-specified percent
;; if losing smart people
 if ticks > 1 [
 if %brain-drain > 0 ;; convert smart or creative people to low creative and uneducated
  [ask n-of (count turtles with [educated = 1 or creative = 1] * (%brain-drain / 100) / 12) turtles with [educated = 1 or creative = 1]
       [set educated 0 set creative 0 set creative-h 0 set creative-m 0 set creative-l 1 set income income-start] ]   ;; brain-drain expressed as changing turtle from educated or creative to non-educated or non-creative

;; if gaining smart people
  if %brain-drain < 0;; when no pop growth, but neg brain-drain converts existing population to creative based on percent of existing educated
    [ifelse (count turtles with [educated = 1] * (abs %brain-drain / 100) / 12 > count turtles with [educated = 0]) []
     [ask n-of (count turtles with [educated = 1] * (abs %brain-drain / 100) / 12) turtles with [educated = 0]
      [set educated 1 set new 1 set income (income * 1.5) ;;increases income
         ifelse creative = 1 []
           [ask n-of (count turtles with [new = 1] / 20) turtles with [new = 1] [set creative-m 1 set creative 1 set new 0];; ask 10% of new brainy people to be medium creative
            ask n-of (count turtles with [new = 1] * ((count turtles with [creative-h = 1] / count turtles) / 100)) turtles with [new = 1]
               [set creative-h 1 set creative 1 set new 0] ;;creates new high creatives based on current % of high creatives
            ]
       set new 0 ]
      ]
     ]
 ]
  set percent-educated count turtles with [educated = 1] / count turtles * 100  ;; used for plots
  set percent-educated-cr count turtles with ([educated = 1 and creative = 1]) / count turtles * 100  ;; used for plots

end


;; ************ SEGREGATION / TOLERANCE OF OTHER (BY COLOR OF TURTLE DISPLAYED) ***************
to check-similar-tolerance  ;;checks color of neighbors and then tolerance for similiarity
  ask turtles
    [set similar-nearby count (turtles-on neighbors) with [color = [color] of myself]
     set other-nearby count (turtles-on neighbors) with [color != [color] of myself]
     set total-nearby similar-nearby + other-nearby
     ]
  if segregation = true  ;; if neighbors ratio is greater than tolerance-for-others then make turtles satisfied, otherwise not satisfied
    [ask turtles
      [ifelse similar-nearby >= ( (100 - tolerance-for-others) * total-nearby / 100 ) [set content-w-neighbor 1 ] [set content-w-neighbor 0]]
     ]
 end


;; ********* STOP WHEN SATISFIED TURTLES AND TO MOVE UNSATISFIED TURTLES THAT CAN'T AFFORD RENT *************
to move-unsatisfied    ;; turtles move randomly around landscape trying to find a place to be satisfied

ask turtles with [creative = 1]  ;; creatives don't have the poverty threshold to account for their preference to be there
  [if [creative-space] of patch-here = 1
    [if ([rent-current] of patch-here * 12) < income [set afford-rent 1 set satisfied? 1]]]

 ask turtles with [afford-rent = 1]  ;;if can afford rent and satisifed, and on residential patch, stop
       [if [landuse] of patch-here = 1
          [ifelse segregation = true
             [if content-w-neighbor = 1 [ set satisfied? 1]]
             []]
       ]
  ask turtles with [afford-rent = 0]
     [ifelse segregation = true
             [if satisfied? = 0 [move]] [move]]
end

to move
    ifelse restrict-movement-to-neighborhood = true ;;if restrict movement is on, move to patch within neighborhood.
          [rt random-float 360                      ;;turn right
            ifelse member? hood-start hood-list     ;; check to see if neighborhood of turtle is in patch list of neighborhoods that overlap that patch
                 [fd random-float 1]                ;; move forward if patch is in neighbhorhood list
                 ;;move to nearest patch in neighborhood if current patch is not
                 [let numb hood-start move-to min-one-of patches with [member? numb hood-list] [distance myself]]]
    [rt random-float 360  fd random-float 1 ]  ;;if no restriction is on, keep moving
end


;;ASSIGN creative VALUE FOR HIGH CREATIVE AREAS******************
;; ********** Turtle Interaction with patches *****************
;; add value - if a high-creative turtle lands on high creative patch it add value of 10 to patch, medium turtles add 5
;; change color - if creative value is 50 it changes to darker color, when creative-value >= 100 then color is black
;; spread creative patches - when a patch has creative value 100 or more, its neighbor4 patches change to landuse=7 and magenta
;; however won't change landuse and color of those that are landuse canton, transit, water

to update-cr-land-value
   ask patches
     [ set pop-count-cr (count turtles-here with [creative = 1])        ;; count creative turtles on patch
       if pop-count-cr > creative-dens [ifelse allow-development = false [ifelse outside = 1 [] [set creative-space 1]] [set creative-space 1]] ;; if # of creative turtles matches threshold, make it a creative space

        set pop-count (count turtles-here) ;; update pop density each time for all patches
        set num-satisfied count turtles-here with [satisfied? = 1] ;; count satisfied turtles
        set pop-count-cr-m count turtles-here with [creative-m = 1] ;; count creative turtles of medium on this patch at this time
        set pop-count-cr-h count turtles-here with [creative-h = 1] ;; count creative turtles of medium on this patch at this time

        ;; counter to subtract value for every 5 ticks no creative visit
        if pop-count-cr = 0  [set pop-count-cr-diff pop-count-cr-diff + 1] ;; if no creative turtles visit, add one to counter called diff
          if ticks > 1 and pop-count-cr-diff > 5 [set pop-count-cr-minus (pop-count-cr-minus + 1) set pop-count-cr-diff 0] ;;after 5 times no creative visit, add to minus counter, reset diff to zero

        if creative-space = 1 [  ;; for creative patches calculate value
        set pop-count-cr-ht (pop-count-cr-ht + (count turtles-here with [creative-h = 1]))  ;; count tally of high creative visits over time
        set pop-count-cr-mt (pop-count-cr-mt + (count turtles-here with [creative-m = 1]))  ;; count tally of medium creative visits over time
        set pop-count-crt (pop-count-cr-mt + pop-count-cr-ht) ;; count total creative turtles visits over time

        ifelse num-satisfied = pop-count [set creative-value creative-value] ;; calculate creative value: each high creative 10, medium 5; subtract the count for minus
         [set creative-value ((pop-count-cr-ht * 10) + (pop-count-cr-mt * 5) - (pop-count-cr-minus * 10))]

        set creative-value (creative-value * (pop-count-cr / creative-dens))

        if creative-value <= 0  [set creative-space 0 set creative-value 0]
        if creative-value > 0 and creative-value < 50 [set creative-space 1]
        if creative-value >= 50 and creative-value < 100 [set rent-current (rent-start * 1.05)]
        if creative-value >= 100 [set rent-current (rent-start * 1.1)]
        if creative-value >= 300 [set rent-current (rent-start * 1.5)]
        if creative-value >= 500
              [set creative-value 500 set rent-current (rent-start * 2)
               ask neighbors [ifelse allow-development = true
                                 [if (creative-space != 1) [set creative-space 1]]
                                 [ if (creative-space != 1 and outside != 1 and landuse != 4 and landuse != 5 and landuse != 3) [set creative-space 1 ]]]  ;;change neighbors4 to creative space.
                ]
          ]
      ]
        end

;; ******** INTERACTION BETWEEN TURTLES **********
;; PEOPLE INSPIRE AND INVEST IN OTHERS

to check-partner  ;; all turtles can partner if not partnered, look to couple, inspire, and uncouple
  ask turtles
    [if not partnered? and (random-float 10.0 < 2) [find-partner]
    inspire
    uncouple]
end

;; probability of if two red meet in a creative patch they are most likely to create something
;; if red and blue interact probabliity is lower
;; if green and red match (if green is high risk taking (and high inome and ....) then  maybe coud be come blue

to find-partner ;; and to change and sprout
    let potential-partner one-of (turtles-at -1 0) with [not partnered?] ;; ask turtles at or near space if partnered then checks parameters for partnering
  if potential-partner != nobody
 ;; if turtle is creative-h 1 and
   [ if random-float 10.0 < 2 ;;[intro-extro-tend] of potential-partner ;; consider removing????????  based on percentages ....to allow partner/change etc
      [ set partner potential-partner
        set partnered? true
        ask partner [ set partnered? true ]
        ask partner [ set partner myself ]
        move-to patch-here ;; move to center of patch
        move-to patch-here ;; partner moves to center of patch
      ]
   ]
end

;;
to inspire  ;; to raise creativiy level  of individuals
  if creative-h = 1 and partnered?   ;;if 2 high creatives meet in area of creative-space they increase income
      [if [creative-h] of partner = 1 and [creative-value] of patch-here >= 500 [set income (income * 1.05) set celebrity-status (celebrity-status + 1)]  ;; those that partner a lot become "celebrity"
           if celebrity-status > 2 [set size 2] ];;those that are partnering most get bigger for visual
  if creative-m = 1 and partnered?  ;; if medium creative partners with high creative, on area of amenities then it becomes a high creative and gains a little income
      [if [creative-m] of partner = 1 and [creative-value] of patch-here >= 500 [set creative 1 set creative-h 1 set creative-m 0 set income (income * 1.02)]]
  if creative-m = 1 and partnered?  ;; if medium creative partners with high creative, on area of amenities then it becomes a high creative and gains a little income
      [if [creative-h] of partner = 1 and [creative-value] of patch-here >= 300 [set creative 1 set creative-h 1 set creative-m 0 set income (income * 1.02)]]
  if creative-l = 1 and partnered?  ;; if low creative partners with high creative, on area of amenities then it gets bigger
       [if [creative-m] of partner = 1 and [creative-value] of patch-here > 100 [set creative 1 set creative-m 1 set creative-l 0 set income (income * 1.02)]]
  if creative-l = 1 and partnered?  ;; if low creative partners with high creative, on area of amenities then it gets bigger
       [if [creative-h] of partner = 1 and [creative-space] of patch-here = 1 [set creative 1 set creative-m 1 set creative-l 0 set income (income * 1.02)]]

end


;; placeholder probability of starting business
to start-business
end


to uncouple  ;; turtle procedure
  if partnered?
        [ set partnered? false
          ask partner [ set partner-timeshare 0 ]
          ask partner [ set partner nobody ]
          ask partner [ set partnered? false ]
          set partner nobody ]
end


;; *********** CHECK affordability and occupancy  *************
to check-affordability
   ask turtles
    [if [landuse] of patch-here = 1
       [ifelse allow-development = false
         [if [outside] of patch-here = 1 [set afford-rent 0]]
         [set current-rent [rent-current] of patch-here
          set rent-yr ([rent-current] of patch-here * 12)
           ifelse rent-yr > income [set rent-% 100] [set rent-% (rent-yr / income * 100)]
           ifelse rent-% > 40 [set afford-rent 0] [set afford-rent 1]  ;; if rent/yr for this patch less than income, poverty threshold then afford
         ]
      ]
   ]
end


;; *********** UPDATE VARIABLES *************

to update-variables
  check-similar-tolerance
  check-display
  plot-histograms
end

to check-display
;; to update-Display and turtles colors
ask patches
  [if _Display = "none"  [set pcolor gray + 3]

  if _Display = "Landuse"
  [if landuse = 0 [set pcolor white] ;; undeveloped
   if landuse = 1 [set pcolor orange + 4] ;; residential
   if landuse = 1 and occupancy-start > 5 [set pcolor orange + 1] ;; high dense residential

   if landuse = 2 [set pcolor yellow + 3] ;; commercial
   if landuse = 3 [set pcolor gray + 2] ;; off-limits
   if landuse = 5 [set pcolor 109] ;; water
   if landuse = 6 [set pcolor green + 3] ];; green space

  if _Display = "Neighborhoods"
  [set pcolor neighborhood + 1.5
    if neighborhood = 0 [set pcolor white]]  ;; gray scale

  if _Display = "Rents"
  [if rent-current < (avg-rent * .9) [set pcolor 75 + 4]
    if rent-current >= (avg-rent * .9) [set pcolor 75 + 2]
    if rent-current >= (avg-rent * 1.1) [set pcolor 75]
    if rent-current >= (avg-rent * 2) [set pcolor 75 - 2] ]

  if _Display = "creative potential"
  [ if creative-space = 0 [set pcolor gray + 3]
    if creative-space = 1 [set pcolor 129]]
   ]

;; show creative spaces
  if show-creative-space = true
   [ask patches
   [ if creative-value > 0 and creative-value < 50 [set pcolor 128]  ;; set creative-space 1] ;;color patch based on value
     if creative-value >= 50 and creative-value < 100 [set pcolor 126] ;; set rent (rent * 1.05)]  ;; pink = pos
     if creative-value >= 100 [set pcolor 124]
     if creative-value >= 300 [set pcolor 122]
      if creative-value >= 500 [set pcolor 120]
     ]]

;; to update turtles color
ask turtles
 [ ifelse _Turtle_color = "hide" [set hidden? true] [set hidden? false]
   if _Turtle_color = "black" [set color black]
   if _Turtle_color = "by Neighborhood"  [set color (orange + hood-start - 1)]
   if _Turtle_color = "afford rent" [ifelse afford-rent = 1 [set color red] [set color black]]

   if _Turtle_color = "Creative"
   [if creative-h = 1 [set color magenta]
   if creative-m = 1 [set color magenta + 2]
   if creative-l = 1 [set color green - 2]]

  if _Turtle_color = "Income"
    [if income < (percapita * .9) [set color black + 2]
    if income >= (percapita * .9) and income <= (percapita * 1.1) [set color blue]
    if income > (percapita * 1.1) and (income <= 75000) [set color blue]
    if income > 75000 and income < (top10% * .8) [set color red]
    if income >= (top10% * .8) and income < (top10% * 1.2) [set color red]
    if income >= (top10% * 1.2)  [set color red]]
  ]
end


to plot-histograms
 set-current-plot "Lorenz Curve"
 clear-plot
 set-current-plot-pen "Equal"  ;; draw a straight line from lower left to upper right
 plot 0
 plot 100
 set-current-plot-pen "Lorenz"
 set-plot-pen-interval 100 / count turtles
 plot 0

 let SortedWealths sort [Income] of turtles
 let TotalWealth sum SortedWealths
 let WealthSumSoFar 0
 let GiniIndex 0
 let GiniIndexReserve 0

 repeat count turtles [
 set WealthSumSoFar (WealthSumSoFar + item GiniIndex SortedWealths)
 plot (WealthSumSoFar / TotalWealth) * 100
 set GiniIndex (GiniIndex + 1)
 set GiniIndexReserve GiniIndexReserve + (GiniIndex / count turtles) - (WealthSumSoFar / TotalWealth)]
;; plot GiniIndex
;; set-current-plot "Gini Index"
 set IndexOfGini (GiniIndexReserve / count turtles) / 0.5
;; plot (GiniIndexReserve / count turtles) / 0.5

  set-current-plot "Income Distribution"
  set-current-plot-pen "Income-dist"
  if income-dist = "gamma" [set-histogram-num-bars 500]
  if income-dist = "bi-modal" [set-histogram-num-bars 100]
  histogram [income] of turtles
  set-current-plot-pen "Income-cr"
  if income-dist = "gamma" [set-histogram-num-bars 500]
  if income-dist = "bi-modal" [set-histogram-num-bars 100]
  histogram [income] of turtles with [creative = 1]

  set-current-plot "Rents Distribution"
  set-current-plot-pen "Rents-Creative"
  set-histogram-num-bars 100
  histogram [rent-current] of patches with [creative-space = 1]
  set-current-plot-pen "Rents"
  set-histogram-num-bars 100
  histogram [rent-start] of patches with [landuse = 1]

end


; Copyright 1997 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
341
10
759
429
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
1
1
1
months
5.0

MONITOR
247
84
336
129
%CreativeSpace
count patches with [creative-space > 0] / 1681 * 100
1
1
11

SLIDER
5
20
136
53
start-pop
start-pop
1200
2500
1830.0
10
1
NIL
HORIZONTAL

SLIDER
3
308
183
341
tolerance-for-others
tolerance-for-others
0
100
30.0
1
1
%
HORIZONTAL

BUTTON
3
96
83
129
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
84
96
164
129
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
5
58
136
91
%PopHighCreative
%PopHighCreative
0
50
10.0
1
1
NIL
HORIZONTAL

MONITOR
249
311
329
356
% unsatisfied
count turtles with ([satisfied? = 0]) / (count turtles) * 100
2
1
11

MONITOR
765
16
876
61
GCI (City Incomes)
sum [income] of turtles
0
1
11

SLIDER
139
58
243
91
Creative-dens
Creative-dens
0
5
3.0
1
1
NIL
HORIZONTAL

PLOT
766
65
926
185
Income Distribution
income
count
0.0
500000.0
0.0
30.0
true
false
"" ""
PENS
"Income-dist" 1.0 1 -16777216 true "" ""
"income-cr" 1.0 1 -5825686 true "" ""

SWITCH
4
272
135
305
segregation
segregation
1
1
-1000

SLIDER
5
395
157
428
avg-rent
avg-rent
0
1500
788.0
1
1
(monthly)
HORIZONTAL

MONITOR
193
311
244
356
%similar
sum [similar-nearby] of turtles / sum [total-nearby] of turtles * 100
2
1
11

MONITOR
881
16
964
61
avg income
mean [income] of turtles
0
1
11

MONITOR
967
17
1060
62
median income
median [income] of turtles
0
1
11

TEXTBOX
6
343
112
361
Avg Yearly Income
11
0.0
1

SLIDER
193
359
337
392
top10%
top10%
75000
300000
180000.0
1000
1
units
HORIZONTAL

SLIDER
2
358
188
391
percapita
percapita
100
75000
30320.0
10
1
units
HORIZONTAL

SLIDER
3
217
141
250
%brain-drain
%brain-drain
-10
50
-10.0
1
1
%yr
HORIZONTAL

SLIDER
2
141
232
174
pop-growth-rate
pop-growth-rate
-10
10
3.0
1
1
%yr
HORIZONTAL

MONITOR
242
135
329
180
NIL
count turtles
17
1
11

SLIDER
3
180
141
213
%educated
%educated
0
100
50.0
1
1
college
HORIZONTAL

PLOT
149
183
331
303
Brain Drain
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"%educ-st" 1.0 0 -16448764 true "" "plot %educated"
"%educated" 1.0 0 -12895429 true "" "plot percent-educated"
"%educ-cr" 1.0 0 -5825686 true "" "plot percent-educated-cr"

MONITOR
259
252
325
297
%educated
count turtles with [educated = 1] / count turtles * 100
1
1
11

MONITOR
997
361
1083
406
%Hi Creative
count turtles with [creative-h = 1] / count turtles * 100
0
1
11

PLOT
936
187
1096
307
Rich
time
percent
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"poor < .8 percap" 1.0 0 -16777216 true "" "plot percent-poor"
"middle" 1.0 0 -13345367 true "" "plot percent-middle"
"rich > 75K" 1.0 0 -2674135 true "" "plot percent-rich"

PLOT
931
64
1091
184
Lorenz Curve
Pop%
Wealth%
0.0
100.0
0.0
100.0
false
true
"" ""
PENS
"Equal" 100.0 0 -16777216 true ";; draw a straight line from lower left to upper right\nset-current-plot-pen \"equal\"\nplot 0\nplot 100" ""
"Lorenz" 1.0 0 -2674135 true "" ";;if ticks > 1 [plot-pen-reset\n;;set-plot-pen-interval 100 / count turtles\n;;plot 0\n;;foreach lorenz-points plot]"

MONITOR
1038
133
1088
178
GINI
indexofgini
3
1
11

BUTTON
167
96
241
129
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

SWITCH
27
433
315
466
restrict-movement-to-neighborhood
restrict-movement-to-neighborhood
0
1
-1000

CHOOSER
345
455
500
500
_Display
_Display
"Landuse" "Neighborhoods" "Rents" "none" "creative potential"
0

CHOOSER
463
455
587
500
_Turtle_color
_Turtle_color
"Creative" "by Neighborhood" "Income" "black" "hide" "afford rent"
0

SWITCH
593
456
760
489
show-creative-space
show-creative-space
0
1
-1000

PLOT
765
189
934
309
Creatives
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
"hi-creative" 1.0 0 -5825686 true "" "plot count turtles with [creative-h = 1]"
"med-creative" 1.0 0 -2382653 true "" "plot count turtles with [creative-m = 1]"
"lo-creative" 1.0 0 -15302303 true "" "plot count turtles with [creative-l = 1]"

TEXTBOX
11
256
161
274
Segregation by color
11
0.0
1

MONITOR
853
258
923
303
%creative
count turtles with [creative = 1] / count turtles * 100
0
1
11

MONITOR
1002
312
1079
357
celebrities
count turtles with [celebrity-status >= 3]
0
1
11

SWITCH
46
470
206
503
allow-development
allow-development
0
1
-1000

MONITOR
243
35
340
80
%residental land
count patches with [landuse = 1 and outside = 0] / count patches * 100
0
1
11

TEXTBOX
239
20
339
38
Within city bounds
11
0.0
1

MONITOR
211
467
342
512
total %land for develop
count patches with [landuse = 0 or outside = 1] / count patches * 100
0
1
11

SLIDER
161
395
337
428
rent%-of-income
rent%-of-income
1
200
40.0
1
1
poverty
HORIZONTAL

CHOOSER
140
11
232
56
income-dist
income-dist
"gamma" "bi-modal"
0

PLOT
766
315
981
435
Rents Distribution
rents
count
0.0
5000.0
0.0
10.0
true
true
"" ""
PENS
"Rents" 1.0 1 -16777216 true "" ""
"Rents-creative" 1.0 1 -5825686 true "" ""

MONITOR
893
382
969
427
%in-poverty
count turtles with [afford-rent = 0] / count turtles * 100
0
1
11

@#$#@#$#@
## WHAT IS IT?

This project models the interactions of creative agents with their environment and with each other in a random city. Each agent moves around in hopes of finding a places to be satistifed to live there. As time goes on, agents may partner with other agents and sometimes get inspired to become more creative or to be entrepreneurial. Depending on the circumstances, creative clusters within the city may emerge.

This project was inspired by the writings of Richard Florida and Edward Glaeser about the Creative Class.

## HOW TO USE IT

Click the SETUP button to establish the environment. The initial display of this random city is the landuse categories typical of many cities: residential, dense residential, commercial, green space, water, gray areas, and undeveloped. The residential landuse category is the starting point for these low, medium, and high creative turtles that exist in the sapce.

The turtles may move about the city if they don't like their current location. Their satisfaction is based on the affordability of the rent, occupancy, and perhaps the similarity of its neighbors.

The monitor for % residential land use shows the amount of residential land within the city limits. For most cities residential landuse may account for between 20 and 40% of the total area of a city. Click the setup button to see how the % changes as well as the display and distribution of agents across the model-scape.

The monitor for % creative space shows the % of land in the model that meets the creative-density threshold to be considered a creative space, which is then colored magenta.

Prior to set up, the user may specify a starting population, % of the population that is high creative to start, creative density threshold of a space, and lastly the income distribution to apply income across the population as either gamma or bimodal distribution. All other sliderse may be adjusted during the model run.

## THINGS TO NOTICE

Upon setup, large areas with no agents may represent undeveloped or areas outside the city limits, but who already have a planned landuse assigned or that may represent the most likely landuse of that space in the future.

Choosing an income-distribution of gamma will skew the income of the population to be very unequal and also very poor. This poor population can not afford rent and are very unsatisfied so as a result they keep moving. With the bi-modal distribution, the population has a very large middle-class and may be less unhappy with their current location and may choose not to move. Varying the percapita and top10%, the avg-rent, and rent as percent of income will have the greatest impact on the model as currently designed.

Over time, creative spaces may emerge into creative clusters. When a patch reaches the maximum creative value based on density of creative turtles located there or that visit there, will result in the neighboring patches to be considered as creative spaces as well with the potential to gain creative value.

As turtles move around and partner, especially in creative spaces, "celebrities" emerge that have many connections and partners.

## THINGS TO TRY

Vary the population growth rate and brain-drain to observe their impacts on the model.

Do changing the toggles for segregation, restriction of movement, and enabling development have great impact on the model's end result?

To analyze the environment and the turtles, change the visualization features at the bottom of the model and step through the model run one step at a time.


## EXTENDING THE MODEL

Incorporate social networks into this model to see who partners.

Load in a background environment such as GIS data to change the background display.

Add in the R extension to perform spatial correlation and statistics in the NetLogo environment.

## NETLOGO FEATURES

`n-of` and `sprout` are used to create turtles while ensuring no patch has more than one turtle on it.

When a turtle moves, `move-to` is used to move the turtle to the center of the patch it eventually finds.

## CREDITS AND REFERENCES

Economist, The. 2010. “Economics Focus: Agents of Change.” The Economist, July 22. http://www.economist.com/node/16636121.

Florida, Richard. 2002. “The Rise of the Creative Class.” Washington Monthly (May). http://www.washingtonmonthly.com/features/2001/0205.florida.html.
———. 2012. The Rise of the Creative Class--Revisited: 10th Anniversary Edition--Revised and Expanded. Second ed. Basic Books.

Glaeser, Edward L. 2011. Triumph of the City: How Our Greatest Invention Makes Us Richer, Smarter, Greener, Healthier, and Happier. First ed. Penguin Press HC, The

## HOW TO CITE

* Wilensky, U. (1997).  NetLogo Creative City model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.
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
