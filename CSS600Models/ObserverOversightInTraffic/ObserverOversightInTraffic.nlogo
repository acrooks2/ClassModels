breed [ cars car]
breed [ police person]

globals [
  sign
  car-counter ;; keeps track of how many cars from a given lane have passed the roadblock
  efficiency-list ;; a list that keeps track of the car-counter values
  efficiency-time-left ;; the time between changing lights for the left side (for the viewer)
  efficiency-time-right ;;the time between changing lights for the right side (for the viewer)

  waiting-list-left ;; splits the efficiency-list to extract the top lane behavior
  waiting-list-right ;; splits the efficiency-list to extract the bottom lane behavior
  reduce-left ;; the sum of the elements in the waiting-list-left list
  reduce-right ;; the sum of the elements in the waiting-list-right list

  top-lane ;; defined by all patches in the top lane
  bottom-lane ;; defined by all patches in the bottom lane
  left-side ;; defined by all patches on the left side of the roadblock
  left-cnt ;; the number of cars on the left-side
  right-side ;; defined by all patches on the right side of the roadblock
  right-cnt ;; the number of cars on the right-side
  road-block ;; defined by all the patches of the roadblock

  honking-level ;; holds the value of the number of cars honking at the police man
  allCarsThrough ;; holds the value of the number of ticks when all cars have passed the roadblock

]

cars-own [
  lane ;; this tells which lane a car belongs to (0 is bottom lane, 1 is top lane)
  patience ;; a value which reflects how likely a car is to honk at the police man
  passed? ;; a boolean that returns true when a car has passed the roadblock at least once
]

patches-own [
  signal-patch-top? ;; returns true only for the patch the top lane uses to recieve input from police
  signal-patch-bottom? ;; returns true only for the patch the bottom lane uses to recieve input from police
]

;;;;;;;;;;;;;;;;;;;;
;;SETUP PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  ask patches [ setup-road ]
  setup-cars
  setup-police
  set sign "rightward"
  prepare-signs
  set allCarsThrough 0
  setup-efficiency-list
  reset-ticks
end

;; We modified the setup-road procedure from Wilensky's Traffic Basic to create two opposing lanes
;; of traffic. The top lane is moving leftward; the bottom lane is moving rightward.
to setup-road
  set pcolor green + 3
  ;
  ; setup the top-lane and the bottom-lane
  ;
  set top-lane patches with [pycor = 1]
  ask top-lane [ set pcolor gray ]

  set bottom-lane patches with [pycor = -1 ]
  ask bottom-lane [ set pcolor gray ]

  ;
  ; setup the left-side and the right-side
  ;
  set left-side patches with [pycor = -1  and pxcor < -8 and pxcor > -25]
  set right-side patches with [pycor = 1 and pxcor > 8 and pxcor < 25]

  ;
  ; establish the basic graphics and booleans of the road
  ;
  set signal-patch-top? false ;; default for all patches
  set signal-patch-bottom? false ;; default for all patches
  if ((pycor > -3) and (pycor < 3)) [ set pcolor gray ]
  if ((pycor = 0) and ((pxcor mod 3) = 0)) [ set pcolor yellow ]
  if ((pycor = 3) or (pycor = -3)) [ set pcolor black ]

  ;; setup the parameters of the roadblock in the bottom lane
  set road-block patches with [ ((pycor > -3) and (pycor < 0) and (pxcor > -7) and (pxcor < 7)) ]
  ask road-block [
    set pcolor red  ;; provides red graphic of roadbloack
  ]

  ;; these if-statements establish which patch is the signal-patch for each lane
  ;; when a car is on these respective patches, they look to the polieman for stop/go directives
  if ((pxcor = -9) and (pycor = -1)) [set signal-patch-bottom? true]
  if ((pxcor = 9) and (pycor = 1)) [set signal-patch-top? true]
end

to prepare-signs
  ifelse sign = "leftward" ;; a leftward sign means that the top lane is allowed to drive
  [ ask patch -2 4 [ set pcolor red ] ;; sign for bottom lane is red
    ask patch 2 4 [ set pcolor green ] ;; sign for top lane is green
  ]
  [ ;; else, there is a rightward sign meaning the bottom lane is allowed to drive
    ask patch -2 4 [ set pcolor green ] ;; sign for bottom lane is green
    ask patch 2 4 [ set pcolor red ] ;; sign for top lane is red
  ]
end

;; This procedure creates a single turtle of the police breed
to setup-police
  set-default-shape police "person police"
  ask one-of patches [ sprout-police 1
    ;; establish the visuals of the police turtle
    ask police [
      setxy 0 4 ;; position of the police man
      set size 2
      set color orange + 2
      ;; when the learning? switch is on, start with the user input from time-between-sign-change
      ;; slider to initialize the following to variables. Police will update both to increase efficiency.
      set efficiency-time-left time-between-sign-change
      set efficiency-time-right time-between-sign-change
    ]
  ]
end

;; This procedure creates the cars on the road
to setup-cars
  if number-of-cars > world-width
  [ ;; this user-message is from Wilensky's Traffic Basic model
    user-message (word "There are too many cars for the amount of road.  Please decrease the NUMBER-OF-CARS slider to below "
      (world-width + 1)
      " and press the SETUP button again.  The setup has stopped.")
    stop
  ]

  set-default-shape cars "car"

  if top-heavy = true and bottom-heavy = true
    [ ;; this user-message occurs when both top and bottom heavy are turned on
      user-message (word "There cannot be a situation with both top-heavy and bottom-heavy turned on where "
        "both with have higher percentage of cars.  Please choose a different combination"
        " and press the SETUP button again.  The setup has stopped.")
      stop
    ]

  if (top-heavy = true and bottom-heavy = false)
  [
    ask patches [
      if count(cars) < number-of-cars [ ;; create the number of cars input by the user
        sprout-cars number-of-cars * 0.60   ;;must be 60% minimum to be top-heavy
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane 1
          ;; cars in the top lane are blue and heading leftward
          set shape "car-flipped"
          setxy random-pxcor 1
          set heading 270
          set color blue
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
        sprout-cars number-of-cars * 0.20   ;;must be 20% minimum for the bottom lane
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane 0
          ;; cars in the top lane are blue and heading leftward
          setxy random-pxcor -1
          set heading 90
          set color pink
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
        sprout-cars number-of-cars - count(cars)
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane (random 2) ;; randomly assign cars to either the top (lane = 1) or bottom (lane = 0)
          ifelse lane = 0
          [ ;; cars in the bottom lane are pink and heading rightward
            setxy random-pxcor -1
            set heading 90
            set color pink
          ]
          [ ;; cars in the top lane are blue and heading leftward
            set shape "car-flipped"
            setxy random-pxcor 1
            set heading 270
            set color blue
          ]
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
      ]
    ]
  ]

  if (top-heavy = false and bottom-heavy = true)
  [
    ask patches [
      if count(cars) < number-of-cars [ ;; create the number of cars input by the user
        sprout-cars (number-of-cars * 0.20)   ;;must be 20% minimum
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane 1
          ;; cars in the top lane are blue and heading leftward
          set shape "car-flipped"
          setxy random-pxcor 1
          set heading 270
          set color blue
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
        sprout-cars (number-of-cars * 0.60)   ;;must be 26% minimum to be bottom-heavy
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane 0
          ;; cars in the top lane are blue and heading leftward
          setxy random-pxcor -1
          set heading 90
          set color pink
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
        sprout-cars number-of-cars - count(cars)
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane (random 2) ;; randomly assign cars to either the top (lane = 1) or bottom (lane = 0)
          ifelse lane = 0
          [ ;; cars in the bottom lane are pink and heading rightward
            setxy random-pxcor -1
            set heading 90
            set color pink
          ]
          [ ;; cars in the top lane are blue and heading leftward
            set shape "car-flipped"
            setxy random-pxcor 1
            set heading 270
            set color blue
          ]
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
      ]
    ]
  ]


  if top-heavy = false and bottom-heavy = false
  [
    ask patches [
      if count(cars) < number-of-cars [ ;; create the number of cars input by the user
        sprout-cars number-of-cars
        [
          set size 1.5
          set passed? false ;; default for all cars at start of model run
          set lane (random 2) ;; randomly assign cars to either the top (lane = 1) or bottom (lane = 0)
          ifelse lane = 0
          [ ;; cars in the bottom lane are pink and heading rightward
            setxy random-pxcor -1
            set heading 90
            set color pink
          ]
          [ ;; cars in the top lane are blue and heading leftward
            set shape "car-flipped"
            setxy random-pxcor 1
            set heading 270
            set color blue
          ]
          remove-from-roadblock ;; this procedure removes cars from the roadblock area
          separate-cars ;; this procedure makes sure no cars are overlapping
        ]
      ]
    ]
  ]
end

to setup-efficiency-list
  ;; initialize the following variable and lists
  set efficiency-list [ ]
  set car-counter 0

  set waiting-list-left [ ]
  set waiting-list-right [ ]
end

;; this proceedure is based on Wilensky's Traffic Basic model
;; makes sure no cars are overlapping on the same patch
to separate-cars
  if any? other turtles-here
    [ fd 1
      separate-cars ]
end

;; this procedure redistributes the cars in the bottom lane (lane 0) so that they
;; do not start on the roadblock
to remove-from-roadblock
  while [ xcor > -10 and xcor < 10 ] ;; while on roadblock
    [ set xcor random-pxcor ] ;; assign to a new random location in bottom lane
end

;;;;;;;;;;;;;;;;;;;;;;
;;RUNTIME PROCEDURES;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  step
  tick
end

to step
  move-cars ;; procedure that determines how each car moves forward; calls the drive procedure

  ifelse learning? ;; model behaves differently depending on whether the police man can learn or not
  [
    ;; when the learning? switch is ON
    ask cars [ set patience (1 + random 99) ] ;; assign each car a random value for patience
    ifelse sign = "leftward"
      [
        ;; if sign is leftward
        ;; whenever the time alloted by efficiency-time-right has passed
        if ticks mod (efficiency-time-right) = 0 and ticks != 0
          [ ifelse any? cars with [pxcor > -9 and pxcor < 9 ]  ;; allow cars passing roadblock to complete maneuver
            [ ask patches with [pcolor = green]
              [ set pcolor yellow ] ;; change the green sign to yellow
            ]
            [ change-signs ;; once all cars are pass the roadblock, switch the signs
              set honking-level 0 ;; reset honking-level
            ]
          ]
      ]
      [
        ;; if sign is rightward
        ;; whenever the time alloted by efficiency-time-right has passed
        if ticks mod (efficiency-time-left) = 0 and ticks != 0
          [ ifelse any? cars with [pxcor > -9 and pxcor < 9 ] ;; allow cars passing roadblock to complete maneuver
            [ ask patches with [pcolor = green]
              [ set pcolor yellow ] ;; change the green sign to yellow
            ]
            [ change-signs ;; once all cars are pass the roadblock, switch the signs
              set honking-level 0 ;; reset honking-level
            ]
          ]
      ]
    police-learning ;; and finally, execute the police-learning procedure
  ]

  ;; when the learning? switch is OFF
  ;; whenever the time alloted by efficiency-time-right has passed
  [ if ticks mod (time-between-sign-change) = 0 and ticks != 0
    [ ifelse any? cars with [pxcor > -9 and pxcor < 9] ;; allow cars passing roadblock to complete maneuver
      [ ask patches with [pcolor = green]
        [ set pcolor yellow ] ;; change the green sign to yellow
      ]
      [ change-signs ] ;; once all cars are pass the roadblock, switch the signs
    ]
  ]

  update-efficiency-list

  ;; when the stopwatch? switch is ON
  if stopwatch? [
    if not any? cars with [passed? = false ] ;; if all cars have passed the roadblock at least once
    [ set allCarsThrough ticks ;; set the allCarsThrough value to the number of current ticks
      set stopwatch? false ;; turn the switch off
    ]
  ]
end

to move-cars
  ask cars [
    if lane = 0
    [  ;; if car is a "bottom lane" car
      ifelse [signal-patch-bottom?] of patch-here = true ;; determine if the car on the signal-patch of its lane
        [
          ifelse sign = "leftward" or [pcolor] of patch -2 4 = yellow  ;; if the police person is allowing leftward traffic
          [ fd 0 ;; do not proceed forward
            ask cars-on left-side [
              ask self [
                if patience < 60 ;; about 60% chance the car will "honk" at police man
                [ set honking-level honking-level + 1 ;; update honking-level
                  set patience 100 ] ;; this prevents cars from honking more than once
              ]
            ]
          ]

          [
            merge ;; if the police man is allowing rightward traffic, merge up into top lane
            set passed? true ;; update the passed? boolean
          ]
        ]
      ;; if not on the signal patch, just follow the drive procedure
        [ drive ]
      ;; this tells the cars when to merge back down into the bottom lane
      if [signal-patch-top?] of patch-at 1 0 = true
        [ merge ]
    ]

    if lane = 1
    [  ;; car is a "top lane" car
      ifelse [signal-patch-top?] of patch-here = true ;; determine if the car on the signal-patch of its lane
        [
          ifelse sign = "rightward" or [pcolor] of patch 2 4 = yellow  ;; if the police person is allowing rightward traffic
          [ fd 0 ;; do not proceed forward
            ask cars-on right-side [
              ask self [
                if patience < 60 ;; about 60% chance the car will "honk" at police man
                [ set honking-level honking-level + 1 ;; update honking-level
                  set patience 100 ] ;; this prevents cars from honking more than once
              ]
            ]
          ]
          [ fd 1 ;; cars go forward one patch so they can be counted in car-counter
                 ;; drive ;; if the police man is allowing leftward traffic, drive pass roadblock
            set passed? true ;; update passed? boolean
          ]
        ]
      ;; if the car is not on a signal patch, then follow the drive proceedure
        [ drive ]
    ]
  ]
end

to drive
  ask self [
    ;; these first two ifelse statements check to see if the upcoming three patches are the signal patch
    ;; and if one of them is, the car effectively slows down
    ifelse [signal-patch-bottom?] of patch-at 1 0 = true
    or [signal-patch-bottom?] of patch-at 2 0 = true
    or [signal-patch-bottom?] of patch-at 3 0 = true
    [ let car-ahead one-of turtles-on patch-ahead 1
      ifelse car-ahead != nobody
        [ fd 0 ] ;; if there is a car on the patch in front of you, stop
        [ fd 1 ] ;; otherwise, only go forward one patch
    ]

    [ ifelse [signal-patch-top?] of patch-at -1 0 = true
      or [signal-patch-top?] of patch-at -2 0 = true
    or [signal-patch-bottom?] of patch-at -3 0 = true
    [ let car-ahead one-of turtles-on patch-ahead 1
      ifelse car-ahead != nobody
        [ fd 0 ] ;; if there is a car on the patch in front of you, stop
        [ fd 1 ]
    ]

    ;; this determines how many patches a car can drive through in one tick
    ;; to simulate various speeds
    [ let car-ahead one-of turtles-on patch-ahead 1
      ifelse car-ahead != nobody ;; if there is a car one patch ahead
        [ fd 0 ] ;; stop
        [
          let car-ahead-2 one-of turtles-on patch-ahead 2
          ifelse car-ahead-2 != nobody ;; if there is a car two patches ahead
            [ fd 1 ;; only go forward one patch
              fd 0 ] ;; otherwise, stop
            [
              let car-ahead-3 one-of turtles-on patch-ahead 3
              ifelse car-ahead-3 != nobody ;; if there is a car three patches ahead
              [ fd 2 ;; only go forward two patches
                fd 0 ] ;; otherwise, stop
              [ fd 3 ] ;; if there are no cars ahead for three patches, go forward three patches
            ]
        ]
    ]
    ]
  ]

  ; uncomment this procedure for a very simple drive procedure (for testing/de-bugging)
  ;  ask self [
  ;    let car-ahead one-of turtles-on patch-ahead 1
  ;    ifelse car-ahead = nobody
  ;    [ fd 1 ]
  ;    [ fd 0 ]
  ;  ]
end


;; this procedure is based loosely on Wilensky's Intersection model
to change-signs
  ;; this procedure switches the two stop/go signs
  ifelse sign = "leftward"
    [ set sign "rightward"
      prepare-signs ;; re-draw the signs
    ]
    [ set sign "leftward"
      prepare-signs ;; re-draw the signs
    ]
end

;; this code block executes if the learning? switch is ON
to police-learning
  ;; count the number of cars on both the left and right side
  set right-cnt count cars-on right-side
  set left-cnt count cars-on left-side

  ask police [
    ;; if leftward-moving traffic is just clearing the roadblock
    if sign = "leftward" and ([pcolor] of patch 2 4 = yellow)
      [ if honking-level / left-cnt > 1.5 ;; and if a certain proportion of the top lane is honking
        [ ifelse ( left-cnt ) > right-cnt ;; if there are more cars on the left side than the right
          [ if efficiency-time-left <  count cars with [color = pink] * 1.5
            [set efficiency-time-left efficiency-time-left + 1] ;; allow more time for the top lane to pass
          ]
          [ if efficiency-time-left > 5
            [set efficiency-time-left efficiency-time-left - 1] ;; allow less time for the top lane to pass
          ]
        ]
      ]

    ;; if rightward-moving traffic is just clearing the roadblock
    if sign = "rightward" and ([pcolor] of patch -2 4 = yellow)
      [ if honking-level / right-cnt > 1.5 ;; and if a certain proportion of the bottom lane is honking
        [ifelse ( right-cnt ) > left-cnt ;; if there are more cars on the right side than the left
          [  if efficiency-time-right < count cars with [color = blue] * 1.5
            [set efficiency-time-right efficiency-time-right + 1 ] ;; allow more time for the bottom lane to pass
          ]
          [if efficiency-time-right > 5
            [set efficiency-time-right efficiency-time-right - 1 ] ;; allow less time for the bottom lane to pass
          ]
        ]
      ]
  ]
end

;; this proceedure describes how a car in the bottom lane should merge past the roadblock
to merge
  ask self [
    ;; if the car is in the bottom lane, merge up
    ifelse ycor = -1 [
      ifelse (not any? turtles-at 0 2)
      [ set ycor 1 ]
      [fd 0]
    ]
    [
      ;; if the car is in the top lane, merge down
      ifelse (not any? turtles-at 0 -2)
      [ set ycor -1 ]
      [fd 0]
    ]
  ]
end

to update-efficiency-list
  if ticks != 0 [
    ifelse sign = "leftward"
    ;; if leftward moving traffic is allowed to pass the roadblock
    [ ifelse ticks mod (time-between-sign-change) = 0 and [pcolor] of patch 2 4 != yellow
      ;; if the time-between-sign-change is up
      [ set waiting-list-left lput car-counter waiting-list-left ;; add car-counter value to efficiency-list
        set car-counter 0 ;; then, reset car-counter
      ]
      [ ;; if cars are still allowed through the intersection
        if any? cars with [pxcor = 8 and pycor = 1]
        [ set car-counter car-counter + 1 ] ;; update car-counter
      ]
    ]

    ;; if rightward moving traffic is allowed to pass the roadblock
    [ ifelse ticks mod (time-between-sign-change) = 0 and [pcolor] of patch -2 4 != yellow
      ;; if the time-between-sign-change is up
      [ set waiting-list-right lput car-counter waiting-list-right ;; add car-counter value to efficiency-list
        set car-counter 0 ;; then, reset car-counter
      ]
      [ ;; if cars are still allowed through the intersection
        if any? cars with [pxcor = -9 and pycor = 1]
        [ set car-counter car-counter + 1 ] ; update car-counter
      ]
    ]
  ]

  ;; if waiting-list-left is not empty
  if waiting-list-left != [ ]
  [set reduce-left reduce + ( waiting-list-left)] ;; sum up the top lane bahavior

  ;; if waiting-list-left is not empty
  if waiting-list-right != [ ]
 [set reduce-right reduce + waiting-list-right] ;; sum up the bottom lane bahavior
end
@#$#@#$#@
GRAPHICS-WINDOW
13
266
782
469
-1
-1
14.9231
1
10
1
1
1
0
1
0
1
-25
25
-6
6
1
1
1
ticks
30.0

BUTTON
73
75
145
116
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
157
76
228
116
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

SLIDER
49
28
253
61
number-of-cars
number-of-cars
1
45
20.0
1
1
NIL
HORIZONTAL

SWITCH
21
133
134
166
learning?
learning?
0
1
-1000

SLIDER
21
172
293
205
time-between-sign-change
time-between-sign-change
0
20
15.0
1
1
ticks
HORIZONTAL

MONITOR
795
277
940
322
#cars to pass roadblock
car-counter
17
1
11

MONITOR
443
214
559
259
#cars in top lane
count cars with [color = blue]
17
1
11

MONITOR
567
214
685
259
#cars in bottom lane
count cars with [color = pink]
17
1
11

MONITOR
880
328
965
373
right side cnt
count cars-on right-side
17
1
11

MONITOR
795
328
873
373
left side cnt
count cars-on left-side
17
1
11

MONITOR
795
379
912
424
NIL
efficiency-time-left
17
1
11

MONITOR
918
379
1042
424
NIL
efficiency-time-right
17
1
11

MONITOR
795
430
881
475
NIL
honking-level
17
1
11

SWITCH
142
133
268
166
stopwatch?
stopwatch?
1
1
-1000

MONITOR
23
215
135
260
stopwatch value
allCarsThrough
17
1
11

SWITCH
145
221
253
254
top-heavy
top-heavy
1
1
-1000

SWITCH
260
221
388
254
bottom-heavy
bottom-heavy
0
1
-1000

PLOT
760
10
1190
207
Total Number of Cars Able to Pass Roadblock
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
"top lane" 1.0 0 -13345367 true "" "plot reduce-left"
"bottom lane" 1.0 0 -2064490 true "" "plot reduce-right"

PLOT
319
10
750
207
#Cars that Pass Roadblock Before Sign Changes
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
"top lane" 1.0 0 -13345367 true "" "if sign = \"leftward\" [plot car-counter]"
"bottom lane" 1.0 0 -2064490 true "" "if sign = \"rightward\" [plot car-counter]"

@#$#@#$#@
## WHAT IS IT?

This model was created to model the traffic patterns that emerge when two opposing lanes of traffic are forced to cooperate to get passed a roadblock. It is also intended to investigate the role that a traffic director, such as police person, may have on the efficiency of traffic.

In this model, there are two opposing lanes of traffic and a police person. The police person can either follow a very simple rule to direct traffic by allowing each lane to proceed for a given number of ticks or he can learn from the traffic pattern and attempt to maximize efficiency.

The cars drive according to a non-continuous perception of speed. They are allowed to move forward at most three patches as long as the interceding patches are devoid of any other cars. Similarly, cars can either move ahead two patches, one patch, or no patches at all if they are directly behind another car.

## HOW TO USE IT

The "**setup**" button sets up the cars based on the NUMBER slider, which determines how many cars are on the road. The user can also choose to make one lane have a disproportionate number of cars using the "**top-heavy**" and "**bottom-heavy**" switches. If neither switch is on, then both lanes will have approximately the same number of cars. If the "top-heavy" switch is on and the "bottom-heavy" switch is off, then the top lane will have about 60-80% of all the cars. If the "bottom-heavy" switch is on and the "top-heavy" switch is off, then the bottom lane will have about 60-80% of all the cars. Turning both switches on will result in a user-error since it is impossible to have both lanes with a majority of the traffic.

This model allows for the police person to direct traffic based on either learned behavior or a simple rule. To turn on the learning feature, use the "**learning?**" switch.

When the "learning?" switch is not on, the police person will direct traffic based on the "**time-between-sign-change**" slider. This slider determines how many ticks the police person allows to pass before stopping the moving lane of traffic and allowing the waiting lane to proceed.

The "**stopwatch?**" switch measures how long it takes for each car to pass the roadblock at least once and then outputs this value to the "stopwatch value" monitor. This is an important tool when it comes to measuring efficiency.

The "**go**" button starts the model. The cars wrap around the world making the road a continuous loop of traffic.

## THINGS TO NOTICE

When police-learning is turned off, it does not matter if one lane or the other is top heavy; about the same number of cars will be able to pass the roadblock in each lane. However, the more ticks-between-sign-change allowed, the more cars will be able to pass at one time.

The plot titled "Total Number of Cars Able to Pass Roadblock" shows the number of cars from the top lane able to pass the roadblock (the blue line) in reference to the number of cars from the bottom lane able to pass the roadblock (the pink line). There is some variation between these two lines, but there is no significant difference over multiple trial runs.

## THINGS TO TRY

Try changing the number of cars on the road to see how the "stopwatch value" changes. This can be seen as a form of efficiency: the lower the "stopwatch value" the more efficient the traffic pattern.

Try turning the "learning?" switch on and off for different numbers of cars on the road. Again, observe the "stopwatch value." Is traffic more efficienct when the police person is able to learn and adjust his own behavor?

## EXTENDING THE MODEL

It would be interesting to integrate the effects of a more complicated system for driving. Specifically, one could integrate the driving procedure from the Wilensky Basic Traffic model which includes variables for acceleration, deceleration, and speed as opposed to non-continuous patch movement. 

One could also enable the police person to implement a few different manners of traffic conducting. In our model, the police person depends largely on measuring the number of cars that make it passed the road block in a given number of ticks. In this way, the police person measures efficiency. Future studies we could allow for an option where the police person decides when to stop one lane or the other depending on a fixed number of cars. So, perhaps the police person would always allow five cars from one direction to pass before stopping them and allowing five from the other to proceed. We might also try to develop a more complicated manner of determining when to change the signals, such as having the police person look down the moving lane and stop traffic at the point where he sees a natural break.

## NETLOGO FEATURES

There are two main monitors and two plots in this model. 

The first main monitor, "stopwatch value," shows how many ticks have passed until every car has passed the roadblock at least once. The second main monitor, "Number of Cars to Pass the Roadblock," shows how many cars have passed the roadblock in the moving lane.

The efficiency-time-right and efficiency-time-left monitors display that amount of time that each lane of traffic has to pass the roadblock. These values will only change when the learning switch is on.

The plot "Number Cars that Pass Roadblock Before Sign Changes" depicts the timeline of the total number of cars in each lane that pass the roadblock. The plot "Total Number of Cars able to Pass Roadblock" depicts the sum, or reduce value, of the number of cars that pass the roadblock.

## RELATED MODELS

"Traffic Basic" models the wave-like pattern that evolves from traffic jams.

"Traffic 2 Lanes" models how two lanes of traffic heading in the same direction merge back and forth.

"Intersection" models two lanes of traffic that intersect perpendicularly at a light.

## Authorship

We referred to three models created by Uri Wilensky for insight on our own model: 
"Traffic Basic" Copyright 1997, "Traffic 2 Lanes" Copyright 1998, and "Intersection" Copyright 1998.
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

car-flipped
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

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

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

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
setup
repeat 180 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Baseline time-between-sign-change" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="time-between-sign-change" first="1" step="2" last="19"/>
  </experiment>
  <experiment name="Baseline number-of-cars" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-cars" first="0" step="5" last="45"/>
    <enumeratedValueSet variable="top-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-sign-change">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Learning time-between-sign-change" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="time-between-sign-change" first="1" step="2" last="19"/>
  </experiment>
  <experiment name="Learning number-of-cars" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="number-of-cars" first="0" step="5" last="45"/>
    <enumeratedValueSet variable="top-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-sign-change">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Baseline top-heavy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-heavy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-sign-change">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Baseline bottom-heavy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-sign-change">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Learning top-heavy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-heavy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-sign-change">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Learning bottom-heavy" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count cars with [color = blue]</metric>
    <metric>count cars with [color = pink]</metric>
    <metric>allCarsThrough</metric>
    <metric>reduce-left</metric>
    <metric>reduce-right</metric>
    <enumeratedValueSet variable="learning?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bottom-heavy">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="top-heavy">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stopwatch?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="time-between-sign-change">
      <value value="10"/>
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
