;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Agent-based Implementation of
;; Needs-based Pattern of Life
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;; Implemented in Netlogo 5.0.3, upgraded to 6.1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals
[
  active-patches          ;; patchset of non-border patches
  temp1 temp2 temp3       ;; temporary variables that can be used to store temorary values
  m-time                  ;; time in minutes
  day                     ;; day
  target-anchor           ;; current location to be targeted
  pause-from              ;; sets the lower limit for pause time
  pause-to                ;; sets the upper limit for pause time
  prior-location          ;; previous location (patch) used to retain the current patch when switching to a new needs-based target
  prior-target-patch      ;; previous target patch --- used to retain the current patch the current target is on when switching to a new needs-based target
  prior-target-anchor     ;; previous target anchor-type --- used to retain the current anchor-type of the current target when switching to a new needs-based target
  current-target-anchor
  physiological-target?   ;; important determiniant if Physiological need is active
  social-target?          ;; important determiniant if Social need is active
  ADN                     ;; Average Distance between Nodes (used to measure general spatial dispersion)
  ADBNN                   ;; Average Distance Between Nearest Neighborss (used to measure general spatial clustering)
  nADN                    ;; normalized Average Distance between Nodes (used to measure general spatial dispersion and compare to other runs)
  nADBNN                  ;; normalized Average Distance Between Nearest Neighborss (used to measure general spatial clustering and compare to other runs)
]

breed [anchors anchor]    ;; geospatial locations of potential relevance to the subject
breed [subjects subj]     ;; primary subject
breed [pavers paver]      ;; "probes" initally used to create roads, but then used by the subject to navigate the space

anchors-own
[anchor-type]             ;; type of location -- "home," work," "play," or "food"

pavers-own
[
  target-patch            ;; goal for the paver...
  current-patch           ;; current patch that the paver can compare to its goal
  p-speed                 ;; designates a speed for the paver to transfer to the road patch
  path                    ;; accumulated patches while searching for goal (target-patch).  the winning paver will transfer its path to the subject patch
]

subjects-own
[
  PN                      ;; physiological need
  PGi                     ;; physiological inhibitory goal (threshold)
  PGc                     ;; physiological need critical
  SN                      ;; social need
  SGi                     ;; social need threshold
  target-patch            ;; anchor to which agent is heading...
  current-patch           ;; achor on which the agent currently is....
  target-location?        ;; location chosen
  pause-count             ;; pause counter
  path                    ;; current path
  path-found?             ;; indicates path found
  move?                   ;; indicates the agent can move
]

patches-own
[
  SGt-patch    ;; environmental factor that affects social need accumulator
  SGi-patch    ;; environmental factor that affects social need inhibitor
  road         ;; designates a road
  speed        ;; designates a speed limit
  waypoint?    ;; is this patch a waypoint (intersection)?
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; to add {} accumulator...
;; *add SET-PATCH-{} to BUILD-ENVIRONMENT
;; *add ITERATE-PATCH-{} to SET-PATCH-{}
;; *add {}N to subject
;; *add {}Gi to subject
;; *add {}-target? to globals
;; *add SET-{} to SET-ACCUMULATORS
;; *add RESET-PATCH-{} to SET-{}
;; *add SET-{}-ACCUMULATOR to SET-{}
;; *add ASSESS-{} to SET-{}
;; *add SET-{}M to SET-{}-ACCUMULATOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; START SIMULATION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
  set-switches
  set tick-number days * 14400
  set day 1
  set-time
  if day <= 1 [output-headers]
  set physiological-target? false
  set social-target? false
  if ticks = 0
  [
    set target-anchor "home"
    set pause-from ceiling((4200 - ticks ) / 10)
    set pause-to ceiling((4200 - ticks) / 10)
  ]
  manage-movement
  run-ADNN
  auto-export
  stop
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; procedures within the GO Procedure
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-switches
  if acquisitional-goals? = false
  [set use-proximity? false set home=food? false]
end
to set-day
  if day != ceiling(ticks / 14400)
  [
;    auto-export ;.......................................................................Un-comment if you want to automatically coolect a screen graqb for each day of the simulation
    set day ceiling(ticks / 14400)
    output-print ""
    if day <= days [output-print (word "DAY: " day)]
  ]
end
to set-time
  let h floor((ticks / 600) - (floor(ticks / (600 * 24)) * 24))
  let m precision((ticks / 600) - (floor(ticks / (600 * 24)) * 24))2 - floor((ticks / 600) - (floor(ticks / (600 * 24)) * 24))
  ifelse (m * 60) >= 10 [set m (word floor(m * 60))][set m (word "0" floor(m * 60))]
  set m-time (word h ":" m)
end
to output-headers
  ; print simulation run parameters
  output-print "SIMULATION SETTINGS"
  output-print "Environment..."
  output-print (word "seed-num:....................." seed-num)
  output-print (word "homes:........................" home-number)
  output-print (word "works:........................" work-number)
  output-print (word "plays:........................" play-number)
  output-print (word "food:........................." food-number)
  output-print (word "food cluster?:................" cluster? " (size: " cluster-size ")")
  output-print (word "road complexity:.............." spatial-complexity)
  output-print ""
  output-print "Subject goals..."
  output-print (word "use acquisitional goals?:....." acquisitional-goals?)
  output-print (word "use proximity?:..............." use-proximity? " (size: " proximity")")
  output-print (word "home=food?:..................." home=food?)
  output-print (word "home=play?:..................." home=play?)
  output-print ""
  output-print "Physiological..."
  output-print (word "p-threshold (initial):........" physiology-initial)
  output-print (word "p-threshold (critical):......." physiology-critical)
  output-print (word "metabolism (physiological):..." pm)
  output-print (word "metabolism (social):.........." sm)
  output-print "--------------------------------------------------------------"
  output-print ""
end
to auto-export ; export .png capture of view
  if auto-export? = true
  [
    if print-roads? = false [set visualize "blank" set-visualize]
    ask anchors with [color != red][set size 4]
    export-view (word "/views/seed-num_" seed-num "_" acquisitional-goals? "_" use-proximity? "_" home=food? "_" home=play? "_" overlay-views? "_" pm "_" day "_" days ".png")
    ask anchors with [color != red][set size 6]
    set visualize "roads" set-visualize
    if overlay-views? = false and day < days
    [clear-drawing]
    export-output (word "/views/seed-num_" seed-num "_" acquisitional-goals? "_" use-proximity? "_" home=food? "_" home=play? "_" overlay-views? "_" pm "_" days "_" days"_ouptput.txt")
  ]
end
to manage-movement
  output-print (word "DAY: " day)
  output-print (word "at: " ticks " [" m-time "] -- start at " target-anchor "...")
  while [ticks <= tick-number]
  [to-navigate]
end

to to-navigate
;  output-print "TO-NAVIGATE" ;...........................................................Un-comment to log procedure
  set-pause
  loop
  [
    let j 0 let k 0
    ask subjects [set j target-patch set k patch-here]
    if j = k
    [ask subjects [set target-patch "na" set path [] set path-found? false set move? false set target-location? false] stop]
    if ticks > tick-number [stop]
    set-pm
;    output-print "PH-A"      ;...........................................................Un-comment to log procedure
    pause-here
;    output-print "FP-A"      ;...........................................................Un-comment to log procedure
    find-path
;    output-print "MS-A"      ;...........................................................Un-comment to log procedure
    move-subject
  ]
end

to set-pause
;  output-print "SET-PAUSE"   ;...........................................................Un-comment to log procedure
  ask subjects
  [
    if count anchors-here with [anchor-type = "food"] > 0
    [set pause-count (random 30) + 30 output-print (word "    pause-here -- " pause-count " minutes")]
    if count anchors-here with [anchor-type = "play"] > 0
    [set pause-count (random 120) + 60 output-print (word "    pause-here -- " pause-count " minutes")]
    if count anchors-here with [anchor-type != "food" and anchor-type != "play"] > 0
    [set pause-count (random (pause-to - pause-from)) + pause-from output-print (word "    pause-here -- " pause-count " minutes")]
  ]
end

to pause-here
;  output-print "PAUSE-HERE-A";...........................................................Un-comment to log procedure
  let p false
  ask subjects
  [
    if pause-count > 0
    [set pause-count pause-count - 1 set p true]
  ]
  if p = true
  [
    let i 1
    let j false
    while [i <= 10]
    [
      tick
      set-time
      set-day
      set i i + 1
      if acquisitional-goals? = true
      [set-accumulators]
    ]
  ]
end


to find-path
  ask subjects
  [
    if pause-count = 0
    [
;      output-print "FIND-PATH" ;.......................................................Un-comment to log procedure
      set-accountable-time
      while [move? = false]
      [
        if target-location? = false [set-target-patch]
        if target-location? = true
        [
          ifelse target-patch != patch-here
          [
;            output-print "FIND-PATH -- create pavers" ;.................................Un-comment to log procedure
            let t target-patch
            ask patch-here
            [
              if count pavers-here = 0
              [
                sprout-pavers count neighbors4 with [road = 1]
                [set shape "circle" set size 2 set color blue set target-patch t set path [] set path lput patch-here path]
              ]
            ]
            ;; to create pavers for every direction of road that has not yet been explored
            set temp1 0
            repeat count pavers[ask one-of pavers-here [initiate-pavers]]
            ;; to send pavers out from suject to explore the space.  chose the path associated with the first one to reach the target
            continue-path
          ]
          [ set move? false set path []; output-print "FIND-PATH -- stop " ;.............Un-comment to log procedure
            stop
          ]
        ]
      ]
    ]
  ]
end

to set-accountable-time
  let dt ticks - (14400 * floor(ticks / 14400))
  if physiological-target? = false
    [
;      output-print "SET-ACCOUNTABLE-TIME" ;..............................................Un-comment to log procedure
      let f (random 301) - 300
      let t (random 301) - 300
      if dt >= 0 and dt < 4200 + t
      [
;        output-print "0:00 - 7:00" ;.....................................................Un-comment to log procedure
        set target-anchor "home"
        set pause-from ceiling((4200 + t - dt ) / 10)
        set pause-to ceiling((4200 + t - dt) / 10)
      ]
      if dt >= 4200 + t and dt < 10200 + f
      [
;        output-print "7:00 - 17:00" ;....................................................Un-comment to log procedure
        set target-anchor "work"
        set pause-from ceiling((10200 + f - dt ) / 10)
        set pause-to ceiling((10200 + f - dt) / 10)
      ]
      if dt >= 10200 + f and dt < 14400 + t
      [
;        output-print "17:00 - 20:00" ;...................................................Un-comment to log procedure
        set target-anchor "home"
        set pause-from ceiling((14400 + t - dt ) / 10)
        set pause-to ceiling((14400 + t - dt) / 10)
      ]
      if dt >= 14400
      [
;        output-print "later than 24:00" ;................................................Un-comment to log procedure
        set target-anchor "home"
        set pause-from ceiling((dt - dt ) / 10)
        set pause-to ceiling((dt - dt) / 10)
      ]
    ]
end

to set-target-patch
;  output-print "SET-TARGET-PATCH" ;......................................................Un-comment to log procedure
  check-proximity
  set target-location? true
  set move? false
  set path-found? false
  output-print (word "at: " ticks " [" m-time "] -- subject thinking about [" target-anchor "]...")
  set current-target-anchor target-anchor
end

to check-proximity
  ifelse use-proximity? = true
    [
      ifelse count other anchors with [anchor-type = target-anchor] in-radius proximity > 0
      [set target-patch [patch-here] of one-of other anchors with [anchor-type = target-anchor] in-radius proximity]
      [set target-patch [patch-here] of min-one-of other anchors with [anchor-type = target-anchor][distance myself]]
    ]
    [set target-patch [patch-here] of one-of other anchors with [anchor-type = target-anchor]]
end

to initiate-pavers
  set heading temp1
  ask patch-here [set road 2]
  ifelse [road] of patch-ahead 1 = 1
  [fd 1]
  [
    set temp1 temp1 + 90 initiate-pavers
    set path lput patch-here path
  ]
  ask patch-here [set road 2]
  set current-patch patch-here
end

to continue-path
  while [move? = false]
  [
    ask pavers
      [
        if count neighbors4 with [road = 1] > 1 and count pavers-here < 4
        [hatch-pavers 1[set heading heading + 90] hatch-pavers 1[set heading heading - 90]]
      ]
    ask pavers
    [
      ifelse [road] of patch-ahead 1 = 1
      [move-step]
      [
        rt 90
        ifelse [road] of patch-ahead 1 = 1
        [move-step]
        [
          lt 180
          ifelse [road] of patch-ahead 1 = 1 [move-step][die]
        ]
      ]
      if current-patch = target-patch
      [
        let p path
        ask subjects [set path p set path-found? true]
      ]
    ]
    ask subjects
    [
      if path-found? = true
      [
        ask pavers [die]
        set move? true
        ask patches with [road = 2] [set road 1]
      ]
    ]
  ]
  ask active-patches with [road = 2][set road 1]
  set temp1 1
end

to move-step
  fd [speed] of patch-here
  if [waypoint?] of patch-here = true
  [set path lput patch-here path]
  ask patch-here [set road 2]
  set current-patch patch-here
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; to move the subject
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to move-subject
;  output-print "MOVE-SUBJECT" ;.....................................................Un-comment to log procedure
  let t false
  let ti false
  ask subjects
  [
    if target-location? = true
    [
       if temp1 < length path
      [
        face item temp1 path
        fd [speed] of patch-here
        if item temp1 path = patch-here[set temp1 temp1 + 1]
        set ti true
      ]
      if (temp1 >= length path or target-patch = patch-here)
      [
        ifelse physiological-target? = true
        [set physiological-target? false]
        [
          ifelse social-target? = true
          [set social-target? false]
          [set target-location? false]
        ]
        output-print (word "at: " ticks " [" m-time "] -- subject at " [anchor-type] of anchors-here "...")

        set t false
        set move? false
        ask anchors-here[set color red]
      ]
    ]
  ]
  if ti = true
  [
    tick
    set-time
    set-day
    if acquisitional-goals? = true
    [
      set-accumulators
    ]
  ]
  if t = false
  [stop]
end

to set-accumulators
;  output-print "SET-ACCUMULATORS" ;...........................................................Un-comment to log procedure
  set-physiology
  set-social
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PHYSIOLOGY ACCUMULATOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-physiology
  ask subjects
  [
    let t1 "home"
    if home=food? = false [set t1 "food"]
    ifelse ((count anchors-here with [anchor-type = t1] > 0 or count anchors-here with [anchor-type = "food"] > 0) and target-patch = "na")
    [set PN 0 ]
    [
      set-pm
      set PGi physiology-initial
      set PGc physiology-critical
      set PN PN + ((random-normal 1 2) * pm)
      if PN > PGi
      [
        ; EXPERIMENTAL -- uses PGc and PGi to establish a range in which the subject can "activate" the goal.  Not used in current tests (Both PGc and PGi set to same number -- always a breach)
        let s random((PGc - PGi) ^ 1.75)
        let b (PN - PGi) ^ 1.75
        ifelse b >= s ; BREACH
        [
;          output-print (word "at: " ticks " [" m-time "] -- PHYSIOLOGICAL BREACH...") ;......Un-comment to log procedure
          if physiological-target? = false
          [
;            output-print (word "at: " ticks " [" m-time "] -- PHYSIOLOGICAL BREACH...") ;....Un-comment to log procedure
            set pause-count 0
            set prior-location patch-here
            set prior-target-patch target-patch
            set prior-target-anchor current-target-anchor
            set physiological-target? true
            let x false
            if target-patch != "na"
            [
              ask anchors-on target-patch
              [
                if anchor-type = "food" or anchor-type = "home"
                [set x true]
              ]
            ]
            if x = false
            [
              set-closest-physiological-target
;              output-print "FP-B" ;...........................................................Un-comment to log procedure
              find-path
            ]
          ]
        ]
        [
          output-print (word "at: " ticks " [" m-time "] -- NO BREACH...")
          if physiological-target? = true
          [
            set physiological-target? false
            set target-patch prior-target-patch
            ifelse target-patch = "na" [set target-location? false][set target-location? true]
            set move? false
            set path []
            set path-found? false
;            output-print "FP-C"   ;...........................................................Un-comment to log procedure
            find-path
          ]
        ]
      ]
    ]
  ]
end
to set-closest-physiological-target
  let t1 "home"
  if home=food? = false [set t1 "food"]
  ifelse use-proximity? = true
  [
    ifelse count other anchors with [anchor-type = "food" or anchor-type = t1] in-radius proximity > 0
    [set target-patch [patch-here] of one-of other anchors with [anchor-type = "food" or anchor-type = t1] in-radius proximity]
    [set target-patch [patch-here] of min-one-of other anchors with [anchor-type = "food" or anchor-type = t1][distance myself]]
  ]
  [set target-patch [patch-here] of one-of other anchors with [anchor-type = "food" or anchor-type = t1]]
;  output-print target-patch
  set target-location? true
  set move? false
  set path-found? false
  let t [anchor-type] of one-of anchors-on target-patch
  output-print (word "at: " ticks " [" m-time "] -- subject thinking about navigating to [" t "]...")
  set current-target-anchor target-anchor
end
to set-pm
  if ticks >= 0 and ticks < 3000 [set pm 1]
  if ticks >= 3000 and ticks < 13800 [set pm 1]
  if ticks >= 13800 [set pm 1]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SOCIAL ACCUMULATOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-social
  reset-patch-social
  set-social-accumulator
  assess-social
end
to reset-patch-social
  ask subjects
  [
    ask patch-here
    [set SGt-patch (random 3) - 1 set SGi-patch 40 + ((random 5) - 2)]
  ]
end
to set-social-accumulator
  ask subjects
  [
    let t1 "home"
    if home=play? = false [set t1 "play"]
    ifelse ((count anchors-here with [anchor-type = t1] > 0 or count anchors-here with [anchor-type = "play"] > 0) and target-patch = "na")
    [set SN 0 ]
    [
      let n 0
      let i 0
      ask patch-here
      [set n SGt-patch set i SGi-patch]
      set SN SN + (n * Sm)
      set SGi i
      ;    set SGc SGi + 5
      if SN <= 0 [set SN 0]
      let s false
    ]
  ]
end
to assess-social
  ask subjects
  [
    if SN > SGi
    [
;      output-print "SOCIAL BREACH" ;.........................................................................Un-comment to log procedure
      if physiological-target? = false
      [
        if social-target? = false
        [
          set pause-count 0
          set prior-location patch-here
          set prior-target-patch target-patch
          set prior-target-anchor current-target-anchor
          set social-target? true
          let x false
          if target-patch != "na"
          [
            ask anchors-on target-patch
              [
                if anchor-type = "food" or anchor-type = "play"
                [set x true]
              ]
          ]
         if x = false
         [
          set-closest-social-target
          ; outtput-print "FP-B" ;.................................................Un-comment to log procedure
          find-path
          ]
        ]
      ]
    ]
  ]
end
to set-closest-social-target
  let t1 "home"
  if home=play? = false [set t1 "play"]
  ifelse use-proximity? = true
  [
    ifelse count other anchors with [anchor-type = "play" or anchor-type = t1] in-radius proximity > 0
    [set target-patch [patch-here] of one-of other anchors with [anchor-type = "play" or anchor-type = t1] in-radius proximity]
    [set target-patch [patch-here] of min-one-of other anchors with [anchor-type = "play" or anchor-type = t1][distance myself]]
  ]
  [set target-patch [patch-here] of one-of anchors with [anchor-type = "play" or anchor-type = t1]]
  set target-location? true
  set move? false
  set path-found? false
  let t [anchor-type] of one-of anchors-on target-patch
  output-print (word "at: " ticks " [" m-time "] -- subject thinking about navigating to [" t "]...")
  set current-target-anchor target-anchor
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to draw
  if mouse-down?
  [ask patch mouse-xcor mouse-ycor [set road 0 set pcolor 58]]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CREATE ENVIRONMENT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to build-environment
  clear-all
   output-print "initiate setup..."
  if new-seed? = true
  [set seed-num 429496729 - (random 214748364)]
  random-seed seed-num

  create-space
  create-all-anchors
  create-roads
  create-waypoints
  set-patch-social
  create-subject
  set m-time "0:00"
  set day 1
  set target-anchor "home"
  set physiological-target? false
  set social-target? false
  reset-ticks
  output-print "setup complete..."
  output-print "environment built."
  output-print "------------------"
  output-print ""
end
to save-environment
  clear-output
  export-world "environment.csv"
  output-print "environment saved as 'environment.csv...'"
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; use setup to initiate the model
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-from-save
  clear-all
  import-world "environment.csv"
  reset-ticks
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create the initial model space by setting all patches to none roads (road = 0),
;; setting the general space color (58), and then setting up a house zone (red),
;; play zone (blue), and work zone (green).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-space
  output-print "creating inital area and zones..."
  ask patches
  [
    set road 0
    set waypoint? false
    set speed precision ((random-normal 3 0.5) * 0.01) 3
    set pcolor 58
    if pycor < min-pycor + 80 and pycor > min-pycor + 20 and pxcor < min-pxcor + 80 and pxcor > min-pxcor + 20 [set pcolor red]
    if pycor > max-pycor - 80 and pycor < max-pycor - 20 and pxcor < min-pxcor + 80 and pxcor > min-pxcor + 20 [set pcolor blue]
    if pycor > min-pycor + 50 and pycor < max-pycor - 50 and pxcor < max-pxcor - 20 and pxcor > max-pxcor - 80 [set pcolor green]
  ]
  set-border
end
to set-border
  output-print "creating geospatial border..."
  ask patches with [abs pycor >= (max-pycor - 1) or abs pxcor >= (max-pxcor - 1)]
  [set pcolor black]
  set active-patches patches with [pcolor != black]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create the initial anchors agents (home, work, play, and food)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-all-anchors
  output-print "creating home location(s)..."
  set temp1 home-number set temp2 "home" set temp3 red
  new-anchors
  output-print "creating work location(s)..."
  set temp1 work-number set temp2 "work" set temp3 green
  new-anchors
  output-print "creating play locations(s)..."
  set temp1 play-number set temp2 "play" set temp3 blue
  new-anchors
  ask active-patches[set pcolor 1]
  output-print "creating food locations(s)..."
  set temp1 food-number set temp2 "food" set temp3 1
  new-anchors
  assign-shapes
  ask anchors [ask patch-here [set pcolor grey]]
end
to new-anchors
  if cluster? = true and temp2 = "food"
  [
    ask anchors with [anchor-type = "home" or anchor-type = "work" or anchor-type = "play"]
    [ask n-of temp1 active-patches in-radius cluster-size with [self != myself][sprout-anchors 1 [set color 9 set anchor-type temp2 set size 6]]]
  ]
  ask n-of temp1 active-patches with [pcolor = temp3][sprout-anchors 1 [set color 9 set anchor-type temp2 set size 6]]
end
to assign-shapes
  ask anchors with [anchor-type = "home"][set shape "house"]
  ask anchors with [anchor-type = "work"][set shape "work"]
  ask anchors with [anchor-type = "food"][set shape "food"]
  ask anchors with [anchor-type = "play"][set shape "face happy"]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; create a road system using the pavers.  spatial-complexity slider controls how many pavers
;; are created per anchor...increasing the potential number of different routes between anchors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-roads
  output-print "creating road system..."
  ask anchors
  [
    ask patch-here
    [
      set speed 0.15
      sprout-pavers spatial-complexity
      [set shape "circle" set p-speed precision ((random-normal 35 5) * 0.01) 3 set target-patch [patch-here] of one-of anchors]
    ]
  ]
  set temp1 count pavers
  while [temp1 > 0]
  [
    set temp1 count pavers
    ask pavers
    [
      let p p-speed
      let x xcor
      let y ycor
      let xt [pxcor] of target-patch
      let yt [pycor] of target-patch
      let x-xt xt - x
      let y-yt yt - y
      ifelse x-xt != 0
      [if x-xt > 0 [set xcor (x + 1)] if x-xt < 0 [set xcor (x - 1)]]
      [if y-yt > 0 [set ycor (y + 1)] if y-yt < 0 [set ycor (y - 1)]]
      ifelse (xcor = xt and ycor = yt) or [pcolor] of patch-here = black [die][ask patch-here [set pcolor gray set speed p]]
    ]
  ]
  ask patches with [pcolor = gray][set road 1]
end

to create-waypoints
  output-print "creating waypoints..."
  ask active-patches
  [
    if road = 1 and count other neighbors4 with [road = 1] > 2
    [set waypoint? true]
    if road = 1 and count other neighbors4 with [road = 1] = 2 and [road] of patch-at 0 1 != [road] of patch-at 0 -1 and [road] of patch-at 1 0 != [road] of patch-at -1 0
    [set waypoint? true]
  ]
  ask anchors
  [ask patch-here [set waypoint? true]]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sets the stress zones and inhibitory zones associated with stress
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-patch-social
  output-print "creating stress zones..."
  ask active-patches [set SGt-patch (random 11) - 5 set SGi-patch random 5]
  repeat 2 [iterate-patch-social]
end
to iterate-patch-social
  ask active-patches [set SGt-patch mean [SGt-patch] of neighbors set SGi-patch mean [SGi-patch] of neighbors]
  set-visualize
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sets the visualization used based on the visualize chooser on the interface
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-visualize
  if visualize = "SGt"[ask active-patches [set pcolor 65 - SGt-patch]]
  if visualize = "SGi"[ask active-patches [set pcolor 95 - SGi-patch]]
  if visualize = "roads"[ask active-patches [set pcolor 58] ask active-patches with [road = 1] [set pcolor grey]]
  if visualize = "blank"[ask active-patches [set pcolor 9]]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; creates and initalizes the primary subject of the model
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to create-subject
;  output-print "creating subject..."
  ask one-of anchors with [anchor-type = "home"]
  [
    set color red
    ask patch-here
    [
      sprout-subjects 1
      [
        set shape "person"
        set color blue
        set size 4
        pen-down
        set pen-size 2
        set target-patch "na"
        set path []
        set path-found? false
        set PN 0
        set PGi 0
        set PGc 0
        set target-location? false
        set move? false
      ]
    ]
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Create spatial metrics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to run-ADNN
  let A []
  let n []

  set ADN 0
  set ADBNN 0
  set nADN 0
  set nADBNN 0
  ask anchors with [color = red]
  [set A lput n-of (count other anchors with [color = red] ) [distance myself] of other anchors with [color = red]  A]
  ask anchors with [color = red and (anchor-type = "home" or anchor-type = "work")]
  [set n lput n-of (count other anchors with [color = red and (anchor-type = "home" or anchor-type = "work")] ) [distance myself] of other anchors with [color = red and (anchor-type = "home" or anchor-type = "work")]  n]

  let B []
  let C []
  let D []
  let i 0
  while [i < length A]
  [
    set B lput mean item i A B
    set C lput min item i A C
    set i i + 1
  ]
  set ADN precision (mean B) 2
  set ADBNN precision (mean C) 2

  carefully
  [
    let j 0
    while [j < length n]
    [
      set D lput mean item j n D
      set j j + 1
    ]
    set nADN precision (ADN / mean D) 2
    set nADBNN precision (ADBNN / mean D) 2
  ]
  []
  output-print "----------------------------------------------"
  output-print (word "Average Distance between Nodes:.........................." ADN)
  output-print (word "Average Distance Between Nearest Neighbors:.............." ADBNN)
  output-print (word "normalized Average Distance between Nodes:..............." nADN)
  output-print (word "normalized Average Distance Between Nearest Neighbors:..." nADBNN)
  output-print ""
  output-print (word "count home-locations visited:................." count anchors with [anchor-type = "home" and color = red])
  output-print (word "count work-locations visited:................." count anchors with [anchor-type = "work" and color = red])
  output-print (word "count play-locations visited:................." count anchors with [anchor-type = "play" and color = red])
  output-print (word "count food-locations visited:................." count anchors with [anchor-type = "food" and color = red])
end


@#$#@#$#@
GRAPHICS-WINDOW
315
10
861
557
-1
-1
2.68
1
10
1
1
1
0
0
0
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
10
95
160
128
setup-from-save
setup-from-save
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
130
160
163
NIL
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

SLIDER
1235
25
1268
145
pm
pm
0
2
1.0
0.01
1
NIL
VERTICAL

SLIDER
1235
185
1268
305
sm
sm
0
1
1.0
0.01
1
NIL
VERTICAL

CHOOSER
695
585
787
630
visualize
visualize
"roads" "SGt" "SGi" "blank"
0

BUTTON
790
585
860
618
reset
set-visualize
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
185
280
305
313
home-number
home-number
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
185
315
305
348
work-number
work-number
1
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
185
385
305
418
food-number
food-number
1
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
185
350
305
383
play-number
play-number
1
10
7.0
1
1
NIL
HORIZONTAL

SLIDER
165
510
305
543
spatial-complexity
spatial-complexity
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
210
455
305
488
cluster-size
cluster-size
1
50
30.0
1
1
NIL
HORIZONTAL

SWITCH
210
420
305
453
cluster?
cluster?
0
1
-1000

OUTPUT
875
325
1275
530
8

SWITCH
165
165
305
198
new-seed?
new-seed?
1
1
-1000

INPUTBOX
165
200
305
260
seed-num
2.41973435E8
1
0
Number

BUTTON
165
95
305
128
NIL
build-environment
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
165
130
305
163
NIL
save-environment
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
35
315
155
348
use-proximity?
use-proximity?
1
1
-1000

SLIDER
60
350
155
383
proximity
proximity
1
100
50.0
1
1
NIL
HORIZONTAL

PLOT
874
25
1234
145
physiology
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
"default" 1.0 0 -16777216 true "" "ask subjects [plot PN]"
"PGi" 1.0 0 -13840069 true "" "ask subjects [plot PGi]"
"PGc" 1.0 0 -2674135 true "" "ask subjects [plot PGc]"

PLOT
875
185
1235
305
social
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
"default" 1.0 0 -16777216 true "" "ask subjects [plot SN]"
"SGi" 1.0 0 -2674135 true "" "ask subjects [plot SGi]"
"0" 1.0 0 -13345367 true "" "plot 0"

SWITCH
5
280
155
313
acquisitional-goals?
acquisitional-goals?
1
1
-1000

TEXTBOX
220
265
270
283
ANCHORS
10
55.0
1

TEXTBOX
220
495
255
513
ROADS
10
55.0
1

SLIDER
875
145
1030
178
physiology-initial
physiology-initial
0
14400
4000.0
1
1
NIL
HORIZONTAL

MONITOR
1485
275
1660
320
phy target?
physiological-target?
17
1
11

MONITOR
876
535
926
580
time
m-time
0
1
11

TEXTBOX
30
75
130
93
RUN SIMULATION
12
105.0
1

TEXTBOX
50
265
100
283
SETTINGS
10
105.0
1

BUTTON
1196
535
1276
568
export output
export-output (word seed-num \"_\" acquisitional-goals? \"_\" use-proximity? \"_\" home=food? \"_\" days \".txt\")
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
35
385
155
418
home=food?
home=food?
1
1
-1000

BUTTON
1485
65
1655
98
set-accountable-time (test)
set-accountable-time
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
1515
100
1655
133
to-navigate (test)
to-navigate
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
1485
30
1655
63
manage-movement (test)
manage-movement
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
1540
135
1655
168
pause-here (test)
pause-here
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
1540
170
1655
203
find-path (test)
find-path
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
1485
230
1660
275
prior target
prior-target-patch
17
1
11

SLIDER
10
165
160
198
days
days
1
31
5.0
1
1
NIL
HORIZONTAL

BUTTON
485
585
565
618
export view
export-view (word seed-num \"_\" acquisitional-goals? \"_\" use-proximity? \"_\" home=food? \"_\" days \".png\")
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
5
475
155
508
auto-export?
auto-export?
1
1
-1000

SWITCH
5
510
155
543
overlay-views?
overlay-views?
0
1
-1000

TEXTBOX
170
75
305
93
CREATE ENVIRONMENT
12
55.0
1

INPUTBOX
10
200
160
260
tick-number
72000.0
1
0
Number

MONITOR
1485
365
1660
410
NIL
target-anchor
17
1
11

MONITOR
1485
410
1570
455
NIL
pause-from
17
1
11

MONITOR
1575
410
1660
455
NIL
pause-to
17
1
11

MONITOR
926
535
976
580
NIL
day
17
1
11

MONITOR
986
535
1036
580
NIL
ADN
2
1
11

MONITOR
1036
535
1086
580
NIL
ADBNN
2
1
11

SWITCH
35
415
155
448
home=play?
home=play?
1
1
-1000

MONITOR
1485
320
1660
365
soc target?
social-target?
17
1
11

TEXTBOX
35
460
130
478
OUTPUT OPTIONS
10
105.0
1

SWITCH
570
585
690
618
print-roads?
print-roads?
1
1
-1000

TEXTBOX
565
15
580
33
 N
14
0.0
0

TEXTBOX
610
25
815
45
 |---------------------------| 5 mi
11
0.0
0

MONITOR
1086
535
1136
580
NIL
nADN
2
1
11

MONITOR
1136
535
1186
580
NIL
nADBnn
2
1
11

TEXTBOX
20
35
310
65
TO SETUP THE MODEL AND RUN A SIMULATION, PLEASE REFER TO THE INFO TAB...
12
15.0
1

TEXTBOX
20
10
300
30
BEHAVIORAL PATTERN OF LIFE
16
0.0
1

TEXTBOX
410
545
445
563
VIEW
12
0.0
1

TEXTBOX
875
10
1025
28
ACCUMULATORS
10
0.0
1

TEXTBOX
880
310
1030
328
OUTPUT
10
0.0
1

TEXTBOX
1485
10
1650
28
PROCEDURE TESTS
11
0.0
1

TEXTBOX
1485
210
1635
228
VERIFICATION MONITORS
11
0.0
1

TEXTBOX
160
540
320
595
-------------------------------------\n|                                               | \n|                                               |\n---------EXPERIMENTAL----------
11
14.0
1

BUTTON
165
550
305
583
erase-road
draw
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
1035
145
1280
186
-----------------------------------------\n|                                                     | EXPERIMENTAL\n-----------------------------------------
11
15.0
1

SLIDER
1040
145
1195
178
physiology-critical
physiology-critical
physiology-initial
physiology-initial + 500
4000.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
# Agent-based Implementation of Needs-based Pattern of Life


## WHAT IS IT?

Computational modeling of the complex social process of offending is proposed as an essential research effort to address limitations in traditional understanding of criminal offending.  An important part of this effort is the incorporation of temporal and spatial factors that define a subject’s activity space and are driven by internal needs.  This model to explores the relationship between spatial and temporal awareness, needs, and activity space.  The resulting implementation exhibits evidence that needs-based accumulators can create qualitatively convincing deviations from accountable time scheduling.    

## SETUP and RUNNING THE MODEL

### To Setup the Model...

In order for this model to run correctly it must have an environment.  There are two ways for a model environment to be initalized.

#### if there is a file named "environment.csv" in the same file folder location as the model's netlogo file, then an environment has already been created and the model can be intialized from the _setup-from-save_ button. 

#### if there is no "environment.csv" file in the same file folder location, or this is the first time the model is being run, or you wish to create a new environment, then create an environment using the following steps...

  1. If you wish the model to use the random seed value displayed in the _seed-num_ input field, set the _new-seed?_ switch to "off".  If you want a new seed-number generated set the _new-seed?_ switch to "on."  
  .

  2. set the anchor sliders, _cluster?_ switch, _cluster-size_ and _spatial-complexity_ to the desired values.
  .

  3. click the _build-environment_ button.  The environment will be built in the view.  depending on the complexity of the environment, it may take a few moments.  When done, the following will appear in the _output_...
      .  
      _'initiate setup..._
      _'creating inital area and zones..._
      _'creating geospatial border..._
      _'creating home location(s)..._
      _'creating work location(s)..._
      _'creating play locations(s)..._
      _'creating food locations(s)..._
      _'creating road system..._
      _'creating waypoints..._
      _'creating stress zones..._
      _'setup complete..._
      _'environment built._
      .
    
  4. if you don't like the environment that was created, either adjust settings or ask for a new seed and click the _build-environment_ button again until you have built a desired environment.
  .

  5. if you are happy with the environment, click the _save-environment_ button.  The following will appear in the _output_...
    .
    _'environment saved as 'environment.csv...'_
    .  
  6. You now have an evironment that can be re-loaded into the model using the _setup-from-save_ button.  Each time this environment is initialized using this csv file, it will reset any parameter changes you have made to the saved csv file.  If you wish to make parameter changes (either in the Settings, Output Options, Anchors or Roads sections) and save the environment file, once the parameters have beeen changed, click the "save-environment" buitton and the new parameters are saved as part of a new environment without changing the anchor-points or road structure.

### To Run The Model...

To run the model click the _go_ button

The Interface section below gives a detailed account of what each of the interface items does, 

## INTERFACE

### Run Simulation

**setup-from-save (button)**
allows a user to initiate the model using an environment file (environment.csv) as long as it is saved to the same root folder as the model's netlogo file

**go (button)**
runs the model for the number of ticks indicated in the _tick-number_ input field

**days (slider)**
user can determine how many days the model will simulate in the subject's pattern of life

**tick-number (input)**
the number of days indicated by the user in the _days_ slider is translated into ticks and displayed automatically once the model run begins (**DO NOT MANUALLY SET THIS VALUE** --- it will be automatically calculated and reset to reflect the "days" slider).

### Settings

**acquisitional-goals? (switch)**
_ON:_ use needs-based targets to supplement the accountable time schedule  
_OFF:_ only use the accountable time schedule to generate the pattern of life.

**use-proximity? (switch)**
_ON:_ search for needs-based targets within a proximity (set by _proximity_ slider) 
_OFF:_ randomly select needs-based targets from the environment

**proximity (slider)**
distance from current location that will be searched for a viable needs-based target location 

**home=food? (switch)**
_ON:_ if the physiological accumulator is breached, "home" **is** considered a "food" location
_OFF:_ if the physiological accumulator is breached, "home" **is not** considered a "food" location

**home=play? (switch)**
_ON:_ if the social accumulator is breached, "home" **is** considered a "play" location
_OFF:_ if the social accumulator is breached, "home" **is not** considered a "play" location

### Output Options

**auto-export? (switch)**
_ON:_ the model will automatically export a png file of the view space
_OFF:_ the model will not automatically export a png file of the view space

**overlay-views (switch)**
_ON:_ the model will overlay the subjects travel for each day on the same view
_OFF:_ the model will erase the subjects travel routes and start a new route each day

### Create Environment

**build-environment (button)**
creates a new environment based on the anchor numbers and _spatial-complexity_ parameter

**save-environment (button)**
saves the current environment as a file named "environment.csv" in root folder of the model's netlogo file

**new-seed? (switch)**
_ON:_ the model will randomly select a new seed number and display it in the _seed-num_ input
_OFF:_ the model use the current seed number displayed in the _seed-num_ input

**seed-num (input)**
displays the seed number that will be used by the random number generator.  This number can be randomly selected by turning the _new-seed?_ switch "on," or a new seed number can be manually entered.

### Anchors

**home-number (slider)**
sets the number of "home" anchor-points to be instantiaed in the model environment

**work-number (slider)**
sets the number of "work" anchor-points to be instantiaed in the model environment

**play-number (slider)**
sets the number of "play" anchor-points to be instantiaed in the model environment

**food-number (slider)**
sets the number of "food" anchor-points to be instantiaed in the model environment

**cluster? (switch)**
_ON:_ (_food-number_) food locations will be clustered around each non-food anchor
_OFF:_ food locations will not be clustered, (_food-number_) will be randomly distributed in the environment

**cluster-size (slider)**
determines how closely food locations will be clustered around other anchors if the _cluster?_ switch is "on"

### Roads

**spatial-complexity (slider)**
determines how many potential routes may be generated between anchors

**erase-road (button)**
**EXPERIMENTAL**-- allows user to erase portions of a road to simulate route unavailability and force the subject to establish new routes

### View

**export view (button)**
exports the current view in the view space as a png file to the model's root file location

**print-roads? (switch)**
_ON:_ when capturing the view show the road system
_OFF:_ when capturing the view do not show the road system (sometimes easier to see anchors and travel routes)

**visualize (chooser)**
gives the user the option to view different model environment layers in the view space

**reset (button)**
resets the _visualize_ button to reflect the user's choice.

### Accumulators

**physiology (plot)**
displays the subject's physiological (hunger) affect accumulation over time

**pm (slider)**
subject's physiological "metabolism" 

**physiology-initial (slider)**
sets the subject's the upper limit of the subject's _inhibitory goal_ (threshold)

**physiology-critical (slider)**
**EXPERIMENTAL**-- sets a critical level for the subject's _inhibitory goal_ (threshold).  intended to be the upper limit of a "range" in which the subject has a power-law distributed probability of activating his _acquisitional goal_.  THis is not used in the current implementation and is currently set to the same value as the _physiology-initial_ slider

#### social (plot)
displays the subject's social affect accumulation over time

#### sm (slider)
subject's social "metabolism" 

### Output

**output (output)**
displays model parameters, information, and metric output

**time (monitor)**
displays current time (hh:mm) simulated in model

**day (monitor)**
displays current day simulated in the model

**ADN (monitor)**
displays Average Distance between Nodes as a measure of dispersion for the model's spatial output 

**ADBNN (monitor)**
displays Average Distance Between Nearest Neighbors as a measure of clustering for the model's spatial output 

**nADN (monitor)**
displays normalized Average Distance between Nodes as a measure of dispersion for the model's spatial output and normalized for comparison to other model configurations  

**nADBNN (monitor)**
displays normalized Average Distance Between Nearest Neighbors as a measure of clustering for the model's spatial output and normalized for comparison to other model configurations  

**export output (button)**
exports current _output_ box contents to a text file

### Procedure Tests
series of buttons used to activate procedures in the code for testing purposes

### Verification Monitors
series of monitors for displaying outputs for model testing and validation procedures.


###References

Beauregard, E., Proulx, J., Rossmo, K., Leclerc, B., & Allaire, J. (2007). Script Analysis of the Hunting Process of Serial Sex Offenders. Criminal Justice and Behavior, 25, 1069-1084.
Berk, R. (2008). How you can tell if the simulations in computational criminology are any good. Journal of Experimental Criminology, 4, 289-308.
Brantingham, P., & Brantingham, P. (1984). Patterns in Crime. New York, New York: MacMillian Publishing Co.
Brantingham, P., & Brantingham, P. (1993). Environment, Routine, and Situation: Toward a Pattern Theory of Crime. In R. Clarke, & M. Felson (Eds.), Routine Activity and Rational Choice, Advances in Criminological Theory (Vol. 5, pp. 259-294). New Brunswick, NJ: Transaction Publishers.
Cioffi-Revilla, C. (2014). Introduction to Computational Social Science: Principles and Applications. London and Heidelberg: Springer-Verlag.
Clarke, P., & Evans, F. (1954). Distance to Nearest Neighbor as a Measure of Spatial Relationships in Populations. Ecology, 35(4), 445-453.
Cohen, L., & Felson, M. (1979). Social Change and Crime Rate Trends: A Routine Activities Approach. American Sociological Review, 44(4), 588-608.
Corbett, J. (n.d.). CSISS Classics -- Torsten Hagerstrand: Time Geography. Retrieved March 6, 2015, from Center for Spatially Integrated Social Science: Spatial Resources for the Social Sciences: http://www.csiss.org/classics/content/29
Crooks, A., & Castle, C. (2011). The Integration of Agent-based Modeling and Geographical Information for Geospatial Simulation. In A. Heppenstall, A. Crooks, L. See, & M. Batty (Eds.), Agent-based Models of Geographical Systems. Berlin, Germany: Springer.
Felson, M. (2002). Crime and Everyday Life. Thousand Oaks, CA: Sage.
Felson, R., & Steadman, H. (1983). Situational Factors in Disputes Leading to Criminal Violence. Criminology, 21(1), 59-74.
Gottman, J. M. (1998). Psychology and the Study of Marital Processes. Annual Revue of Psychology, 49, 169-197.
Gottman, J., Notarius, C., Markman, H., Bank, S., Yoppi, B., & Rubin, M. E. (1976). Behavior Exchange Theory and Marital Decision Making. Journal of Personality and Social Psychology, 34(1), 14-23.
Heppenstall, A. J., Crooks, A. L., & Batty, M. (2011). Agent-based Models of Geographical Systems. Berlin, Germany: Springer.
Johnson, S., & Groff, E. (2014, May). Strengthening Theoretical Testing in Criminology Using Agent-based Modeling. Journal of Research in Crime and Delinquency, 1-17.
Kennedy, W. (2011). Modeling Human Behaviour in Agent-based Models. In A. Heppenstall, A. Crooks, L. See, & M. Batty (Eds.), Agent-based Models of Geographical Systems. Berlin, Germany: Springer.
Kwan, M.-P. (1998). Space-Time and Integral Measures of Individual Accessibility: A Comparative Analysis Using a Point-based Framework. Geographical Analysis, 30(3), 191-216.
Leclerc, B., & Wortley, R. (Eds.). (2013). Cognition and Crime: Offender Decision Making and Script Analyses. New York: Routledge.
Liu, L., & Eck, J. (Eds.). (2008). Artificial Crime Analysis Systems: Using computer simulations and geographic information systems. Hershey, Pennsylvania: Information Science Reference.
Luckenbill, D. (1977). Criminal Homicide as a Situational Transaction. Social Problems, 176-186.
Malleson, N. (2011). Using Agent-based Models to Simulate Crime. In A. Heppenstall, A. Crooks, L. See, & M. Batty (Eds.), Agent-based Models of Geographical Systems. Berlin, Germany: Springer.
Maslow, A. H. (1943). A Theory of Human Motivation. Psychological Review, 50, 370 - 396.
Miller, H. J. (2007). Modelling accessibility using space-time prism concepts within geographical information systems. International Journal of Geographical Information Systems, 5(3), 287-301.
Miller, J., & Page, S. (2007). Complex Adaptive Systems. Princeton, New Jersey: Princeton University Press.
Polaschek, D. L., Hudson, S. M., Ward, T., & Siegert, R. J. (2001). Rapists' Offense Processes: A preliminary descriptive model. Journal of Interpersonal Violence, 16, 523-544.
Pred, A. (1977). The Choreography of Existence: Comments on Hagerstrand's Time-Geography and its Usefulness. Economic Geography, 53(2), 207-221.
Rossmo, D. K. (1995). Place, Space, and Police Investigations: Hunting serial violent criminals. In J. Eck, & D. Weisburd, Crime and Place (pp. 217-235). Monsey, New York: Criminal Justice Press/Willow Tree Press.
Schank, R., & Abelson, R. (1975). Scripts, Plans, and Knowledge. Proceedings of the 4th International Joint Conference on Artificial intelligence (pp. 151-157). San Francisco, CA: Morgan Kaufmann Publishers Inc.
Schank, R., & Abelson, R. (1977). Scripts, Plans, Goals and Understanding: An inquiry into human knowledge structures. Hillsdale, New Jersey: Erlbaum.
Simon, H. (1996). The Sciences of the Artificial (3rd ed.). Cambridge, Massachusetts: MIT Press.
Ward, T., Hudson, S. M., & Keenan, T. (1998). A Self-regulation Model of the Sexual Offense Process. Sexual Abuse: A Journal of Research and Treatment, 10(2), 141-157.
Warren, J., Reboussin, R., & Hazelwood, R. (1995). Geographic and Temporal Sequencing of Serial Rape: Final report submitted to the National Institute of Justice. United States Department of Justice, National Institute of Justice. Washington: Federal Bureau of Investigation.
Welinsky, U. (1999). Netlogo. 5.0.3. Center for Connected Learning and Computer-based Modeling, Northwestern University. Retrieved from http://ccl.northwestern.edu/netlogo/



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

building store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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
Circle -7500403 true true 15 15 270
Circle -16777216 false false 15 15 270
Circle -16777216 true false 58 73 182
Circle -7500403 true true 69 69 162
Rectangle -7500403 true true 45 120 270 180
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60

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

food
false
0
Polygon -7500403 true true 30 105 45 255 105 255 120 105
Rectangle -7500403 true true 15 90 135 105
Polygon -7500403 true true 75 90 105 15 120 15 90 90
Polygon -7500403 true true 135 225 135 240 150 255 270 255 285 240 285 225 210 225
Polygon -7500403 true true 135 195 135 180 165 150 255 150 285 180 285 195 150 195
Rectangle -7500403 true true 135 195 285 225
Line -16777216 false 15 105 135 105
Line -16777216 false 75 90 105 15
Line -16777216 false 105 255 120 105
Line -16777216 false 45 255 105 255
Line -16777216 false 45 255 30 105
Line -16777216 false 15 90 135 90
Line -16777216 false 105 15 120 15
Line -16777216 false 90 90 120 15
Polygon -16777216 false false 135 225 135 240 150 255 270 255 285 240 285 225
Polygon -16777216 false false 135 195 135 180 165 150 255 150 285 180 285 195

house
false
0
Line -16777216 false 75 105 75 45
Line -16777216 false 105 90 105 45
Rectangle -7500403 true true 45 150 255 270
Rectangle -16777216 true false 120 195 180 270
Polygon -7500403 true true 15 150 150 45 285 150
Line -16777216 false 15 150 285 150
Rectangle -16777216 true false 75 195 105 240
Rectangle -16777216 true false 195 195 225 240
Rectangle -7500403 true true 75 45 105 105
Line -16777216 false 45 150 45 270
Line -16777216 false 255 150 255 270
Line -16777216 false 45 270 255 270
Line -16777216 false 285 150 150 45
Line -16777216 false 15 150 150 45
Line -16777216 false 75 45 105 45

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

work
false
0
Rectangle -7500403 true true 45 15 255 285
Rectangle -16777216 true false 120 210 180 285
Rectangle -16777216 true false 75 120 105 165
Rectangle -16777216 true false 135 120 165 165
Rectangle -16777216 true false 195 120 225 165
Rectangle -16777216 true false 195 45 225 90
Rectangle -16777216 true false 135 45 165 90
Rectangle -16777216 true false 75 45 105 90
Rectangle -16777216 true false 195 210 225 255
Rectangle -16777216 true false 75 210 105 255
Line -16777216 false 45 180 255 180
Line -16777216 false 45 285 255 285
Line -16777216 false 45 15 45 285
Line -16777216 false 45 15 255 15
Line -16777216 false 255 15 255 285

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
  <experiment name="experiment sm-1.0 ag-true" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment sm-0.5 ag-true" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment ag-false" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment baseline parameter sweep-sm" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="work-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="play-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-complexity">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment baseline parameter sweep-pm" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pm">
      <value value="0"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="work-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="play-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-complexity">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment baseline parameter sweep-anchors" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home-number">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="work-number">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="play-number">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-complexity">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment baseline parameter sweep-cluster" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="work-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="play-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-complexity">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment baseline parameter sweep-complexity" repetitions="1" runMetricsEveryStep="false">
    <setup>build-environment
save-environment
setup-from-save</setup>
    <go>go</go>
    <metric>ADN</metric>
    <metric>ADBNN</metric>
    <metric>nADN</metric>
    <metric>nADBNN</metric>
    <metric>count anchors with [anchor-type = "play" and color = red]</metric>
    <metric>count anchors with [anchor-type = "food" and color = red]</metric>
    <enumeratedValueSet variable="acquisitional-goals?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="use-proximity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=food?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home=play?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="overlay-views?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sm">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="home-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="work-number">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="play-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-number">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cluster?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spatial-complexity">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
VIEW
110
10
498
398
0
0
0
1
1
1
1
1
0
1
1
1
-100
100
-100
100

CHOOSER
5
10
100
55
layer
layer
\"use\" \"privacy\" \"stressor\" \"none\"
0

BUTTON
5
55
100
88
visualize
NIL
NIL
1
T
OBSERVER
NIL
NIL

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
