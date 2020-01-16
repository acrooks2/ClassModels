
;; Define attributes of each employee agent
turtles-own [
  adopted?                    ;; Binary that signifies that the employee has adopted the wellness plan
  currentPrivacyAttitude     ;; Range 0 to 1 -> 0 = Never give up data; 1 = Always give up data
  updatedPrivacyAttitude     ;; Temporary value used when thresholds are updated
  willingnessToChange         ;; Range 0 to 1 ->  1 = Always change privacy attitude; 0 = Never change privacy attitude
]

;; Define global variables
globals [
  adoptersTotal   ;; Total number of employees that adopt the plan
  nodeCount       ;; Total number of employees in the population (nodes in the graph)
  adopterPercent  ;; Percentage of employees that have adopted

  HRtickCounter   ;; Counts ticks between HR material releases
  HRtickInterval  ;; Current interval length to release HR material
  HRpulseIndicator  ;; Used to show when HR released material to employees

  PVtickCounter   ;; Counts ticks between privacy violations
  PVtickInterval  ;; Current interval between privacy violations
  PLRandomValue    ;; Global Privacy Random Value Holder
]

;;;;;;;;;;;;;;;;;;;;;;
;;; Load Graph From File and Initialize the Simulation
;;; Graph is an undirected graph with no link weights
;;; Modified Code from:  http://ccl.northwestern.edu/netlogo/5.0/docs/nw.html#load-matrix
;;;;;;;;;;;;;;;;;;;;;;
extensions [ nw ]
undirected-link-breed [ employeelinks employeelink ]
to load-graph
  clear-all
  set nodeCount 0

  ;; This builds a node list as the network is read-in from file.
  let node-list []

  ;; The networkFilename specified in the interface chooser
  nw:load-graphml networkFilename [
  ;; nw:load-graphml "Data/TestGraph4Nodes.graphml" [
    set color gray
    set adopted? False
    set node-list lput self node-list
    set nodeCount nodeCount + 1  ;; Increment the node counter
  ]
  let node-set turtle-set node-list

  init-employee-attributes ;; Initialze random values and seed adopters

  ask turtles [set shape "circle"]

  layout  ;; Layout the nodes
  resize-nodes
  check-adopters
  initialize-HR
  initialize-PV
  clear-all-plots
  display
  reset-ticks
end

;;;;;;;;;;;;;;;;;;;;;;
;; Initialize the variables to support the HR materials distribution
;;;;;;;;;;;;;;;;;;;;;;
to initialize-HR
  set HRtickCounter 0  ;; Counts ticks between HR material releases
  set HRtickInterval HRminimumTickInterval   ;; Initially set Interval to be shortest
  set HRpulseIndicator 0  ;; Reset the pulse indicator value
end

;;;;;;;;;;;;;;;;;;;;;;
;; Initialize the variables to support the privacy violation feature
;;;;;;;;;;;;;;;;;;;;;;
to initialize-PV
  set PVtickCounter 0  ;; Counts ticks between privacy violations
  set PVtickInterval privacyMinimumTickInterval   ;; Initially set Interval to be shortest
end

;;;;;;;;;;;;;;
;;; Layout Nodes
;;; -------------------
;;; NOTE:  Modified code segment from Giant Component Sample Model by Uri Wilensky, 2005.
;;; Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/.
;;; Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
;;;;;;;;;;;;;;
to layout
  ;; the number 10 here is arbitrary; more repetitions slows down the
  ;; model, but too few gives poor layouts
  repeat 20 [
    do-layout
    display  ;; so we get smooth animation
  ]
end

to do-layout
  layout-spring (turtles with [any? link-neighbors]) links 0.4 15 1
end


;;;;;;;;;;;;;;;;;;;;;;
;; Initialize all the employee attributes
;;;;;;;;;;;;;;;;;;;;;;
to init-employee-attributes
  let n 0  ;; Start at node 0
  set adoptersTotal 0

  ;; Loop through all the nodes and reset to random values
  while [n < nodeCount] [
    ask turtle n [
      set currentPrivacyAttitude (random 100) * 0.01
      set updatedPrivacyAttitude 0
      set willingnessToChange (random 100) * 0.01

      ;; Seed the network with initial adopters
      if currentPrivacyAttitude >= adoptionThreshold [
        set adopted? True
        set color green
        set adoptersTotal (adoptersTotal + 1)
      ]
    ]
    set n n + 1  ;; Increment counter
  ]
  display  ;; update the display for new colors
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Resize the nodes based on their privacy threshold value
;; The larger the privacy value, the larger the node size in the graph
to resize-nodes
    ask turtles [ set size sqrt (currentPrivacyAttitude * 5) ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Check for adopters -- Nodes that have thresholds > adoptionThreshold
;; Recolor the nodes based on their adoption status
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to check-adopters
  set adoptersTotal 0   ;; Reset the adopters count

  ;; Loop through all turtles and count adopters
  ask turtles [
      ;; Check to see if each turtle is above the adoptionThreshold
      ifelse currentPrivacyAttitude >= adoptionThreshold [
        set adopted? True
        ;; set color white   ;; Blink white
        ;; display
        set color green
        set adoptersTotal (adoptersTotal + 1) ]
      [set adopted? False
        set color gray ]
   ]

  ;; display  ;; update the display for new colors
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Block Update the Privacy attitude values after updates are computed
;; Copy the updatedPrivacy values into the currentPrivacy values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to block-update-privacy

  ;; Loop through all the nodes set the color based on adoption
 ask turtles [
      set currentPrivacyAttitude updatedPrivacyAttitude  ;; Copy updatedPrivacy to currentPrivacy
      ]
end

;;;;;;;;;;;;;;;;;;;;;;
;; Propagate employee opinions between each other
;; [This code segment modified from
;;;;;;;;;;;;;;;;;;;;;;
to propagate-privacy-thresholds
  ;; Loop through all the employee nodes
  ask turtles [
    let neighbors-who-meet-confidence-threshold link-neighbors with [ abs(currentPrivacyAttitude - ([currentPrivacyAttitude] of myself)) <= boundedConfidenceThreshold  ]

    ;; print "\nMy current privacy attitude"
    ;; show currentPrivacyAttitude

    ;; print "------ Next is privacy attitude of all neighbors-who-meet-confidence-threshold"

    let Attitude-delta 0  ;; Clear the attitude delta value for the current employee

    ;; Loop through all my neighbors who meet the confidence threshold
    ask neighbors-who-meet-confidence-threshold [
      ;; show currentPrivacyAttitude
      ;; Sum up the deltas between my currentPrivacyAttitude and my eligbile neighbors
      set Attitude-delta (Attitude-delta + (currentPrivacyAttitude - [currentPrivacyAttitude] of myself))
    ]

    ;; print "----- The Attitude-delta sum is below ----"
    ;; show Attitude-delta

    ;; print "----- Count of eligible neighbors below ---"
    ;; show count neighbors-who-meet-confidence-threshold

    ;; Average delta across eligible neighbors to get mean
    set Attitude-delta Attitude-delta / (1 + count neighbors-who-meet-confidence-threshold)

    ;; set updatedPrivacyAttitude (currentPrivacyAttitude + Attitude-delta)  ;; This line does not include resistance factor

    ;; Update the attitude including the willingnessToChange factor
    ifelse (count neighbors-who-meet-confidence-threshold) > 0
      [ set updatedPrivacyAttitude ((currentPrivacyAttitude) + (willingnessToChange * Attitude-delta)) ]
      [ set updatedPrivacyAttitude currentPrivacyAttitude ]

    ;; if updatedPrivacyAttitude < 0 [set updatedPrivacyAttitude 0]  ;; Prevent negative attitudes

    ;; print "---- updatedPrivacyAttitude value below"
    ;; show updatedPrivacyAttitude
    ]
end

;;;;;;;;;;;;;;;;;;;;;;
;; Propagate HR material based on adoption rate
;;;;;;;;;;;;;;;;;;;;;;
to distribute-HR-material
  ;; Check to see if we've reached the current tick interval
  if HRtickCounter >= HRtickInterval [
    set HRpulseIndicator (HRpulseIndicator + 1) mod 2 ;; Toggle the HR pulse indicator for the display
    set HRtickCounter 0 ;; Reset the tick counter
    set adoptersTotal 0   ;; Reset the adopters count

    ;; Loop through all nodes and impact privacy attitudes by distributing HR material
    ask turtles [
      ;; Test to see if we're within the boundedConfidenceThreshold
      if abs(1 - currentPrivacyAttitude) < HRboundedConfidenceThreshold [
         set updatedPrivacyAttitude (currentPrivacyAttitude + (1.0 - currentPrivacyAttitude) * willingnessToChange)
         set currentPrivacyAttitude updatedPrivacyAttitude
         set size sqrt (currentPrivacyAttitude * 10)  ;; Resize
      ]

      ;; Check for new adopters
      ifelse currentPrivacyAttitude >= adoptionThreshold [
        set adopted? True
        set color green
        set adoptersTotal (adoptersTotal + 1) ]
      [set adopted? False
        set color gray ]
    ]

  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;; Simulate generating privacy violations onto the population
;;;;;;;;;;;;;;;;;;;;;;
to cause-privacy-violation
  ;; Check to see if we've reached the current tick interval
  if PVtickCounter >= PVtickInterval [
    ;; set PVpulseIndicator (PVpulseIndicator + 1) mod 2   ;; Temp value to make an EKG effect
    set PVtickCounter 0 ;; Reset the tick counter
    set adoptersTotal 0   ;; Reset the adopters count

    ;; Compute a random privacy violation amount (0 to 1) using power law distribution
    ;; 1 = Horrible violation that drags down a person's attitude
    ;; 0 = No violation -- No impact to the person's attitude
    ;; ------------------------------
    ;; NOTE:  This power law algorithm modified from discussion found at:
    ;; Stack Overflow:  Python : generating random numbers from a power law distribution
    ;; https://stackoverflow.com/questions/31114330/python-generating-random-numbers-from-a-power-law-distribution
    ;; ------------------------------
    let PLexponent -1.5 ;; Set the power law exponent
    let lowerBound 0.01 ;; Zero is not allowed
    let upperBound 1.0  ;; We want our range to be between 0 and 1
    let uniformRandomValue random-float 1   ;; Generate a uniform random dist value between 0 and 1 to transform to power-law dist
    set PLRandomValue (lowerBound ^ PLexponent + (upperBound ^ PLexponent - lowerBound ^ PLexponent) * uniformRandomValue) ^ (1 / PLexponent)
    ;; print "------ Random privacy violation value below"
    ;; print PLRandomValue

    ;; Loop through all nodes and impact privacy attitudes by random privacy violations
    ask turtles [

      ;; Test to see if we're within the privacy violation boundedConfidenceThreshold
      if abs(PLRandomValue - currentPrivacyAttitude) < PVboundedConfidenceThreshold [
         set updatedPrivacyAttitude (currentPrivacyAttitude - (PLRandomValue * willingnessToChange))
         if updatedPrivacyAttitude < 0 [set updatedPrivacyAttitude 0]  ;; Make sure we don't go negative
         set currentPrivacyAttitude updatedPrivacyAttitude
         set size sqrt (currentPrivacyAttitude * 10)  ;; Resize
      ]

      ;; Check for new adopters
      ifelse currentPrivacyAttitude >= adoptionThreshold [
        set adopted? True
        set color green
        set adoptersTotal (adoptersTotal + 1) ]
      [set adopted? False
        set color gray ]
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;;; Main Procedure ;;;
;;;;;;;;;;;;;;;;;;;;;;

to go
  propagate-privacy-thresholds  ;; Compute updated privacy attitudes
  block-update-privacy  ;; Block copy the privacy attitude updates
  check-adopters  ;; Set the adopter flags and recolor nodes
  resize-nodes  ;; Resize the nodes based on updated privacy attitudes value

  ;; Handle the HR feature
  set HRtickCounter HRtickCounter + 1  ;; Increment the HR material tick counter
  ;; If the HR material is enabled, then run the HR propaganda distribution code
  if enableHRinformationDistribution? [
    distribute-HR-material ]

  ;; Handle the Privacy Violation feature
  set PVtickCounter PVtickCounter + 1  ;; Increment the privacy violation material tick counter
  ;; If the privacy violation generator is enabled, then run the privacy generator code
  if enablePrivacyViolations? [
    cause-privacy-violation ]

  display
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
590
38
1302
751
-1
-1
21.333333333333332
1
10
1
1
1
0
0
0
1
-16
16
-16
16
1
1
1
ticks
30.0

BUTTON
362
15
514
48
Load Graph & Reset
load-graph
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
371
55
499
88
Single Step
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

MONITOR
23
66
110
111
Total Nodes
nodeCount
17
1
11

MONITOR
392
485
538
530
Adoption Percentage (%)
(adoptersTotal / nodeCount) * 100
3
1
11

PLOT
12
538
575
749
Percentage Wellness Plan Adopters
Ticks
Percentage
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"% Adopters" 1.0 0 -16777216 true "" "plot adoptersTotal / nodeCount"
"Mean Attitude" 1.0 0 -2674135 true "" "plot mean [currentPrivacyAttitude] of turtles"

SLIDER
352
141
527
174
adoptionThreshold
adoptionThreshold
0
1
0.75
0.01
1
NIL
HORIZONTAL

BUTTON
370
98
504
131
Run Continously
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

MONITOR
235
484
348
529
Nodes Adopting
adoptersTotal
17
1
11

SWITCH
17
209
283
242
enableHRinformationDistribution?
enableHRinformationDistribution?
0
1
-1000

SLIDER
17
289
284
322
HRminimumTickInterval
HRminimumTickInterval
0
100
20.0
1
1
NIL
HORIZONTAL

MONITOR
61
486
190
531
Mean Privacy Attitude
mean [currentPrivacyAttitude] of turtles
3
1
11

TEXTBOX
41
186
281
214
--------  HR Influence Controls --------
11
0.0
1

SLIDER
23
121
261
154
boundedConfidenceThreshold
boundedConfidenceThreshold
0
1
0.35
0.01
1
NIL
HORIZONTAL

SLIDER
19
248
282
281
HRboundedConfidenceThreshold
HRboundedConfidenceThreshold
0
1
0.5
0.01
1
NIL
HORIZONTAL

TEXTBOX
331
185
624
213
-------- Privacy Violations Generator ------\n
11
0.0
1

SWITCH
316
209
573
242
enablePrivacyViolations?
enablePrivacyViolations?
0
1
-1000

SLIDER
316
290
578
323
privacyMinimumTickInterval
privacyMinimumTickInterval
1
100
5.0
1
1
NIL
HORIZONTAL

CHOOSER
23
11
343
56
networkFilename
networkFilename
"Data/TestGraph4Nodes.graphml" "Data/SmallWorld-50Nodes-Ver1.graphml" "Data/SmallWorld-100Nodes-Ver1.graphml" "Data/SmallWorld-250Nodes-Ver1.graphml" "Data/SmallWorld-500Nodes-Ver1.graphml" "Data/SmallWorld-1000Nodes-Ver1.graphml" "Data/SmallWorld-2000Nodes-Ver1.graphml"
0

MONITOR
120
66
273
111
Graph Cluster Coefficient
mean [ nw:clustering-coefficient ] of turtles
3
1
11

SLIDER
315
248
576
281
PVboundedConfidenceThreshold
PVboundedConfidenceThreshold
0
1
1.0
0.01
1
NIL
HORIZONTAL

PLOT
316
331
580
451
Transient Privacy Micro-Violation Level
NIL
NIL
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot PLRandomValue"

PLOT
18
329
284
449
HR Information Distribution Events
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot HRpulseIndicator"

TEXTBOX
716
10
1216
35
PROJECT GUPPI - Give UP Private Information
20
0.0
1

TEXTBOX
30
455
581
478
-------------------------------------------
20
0.0
1

@#$#@#$#@
## WHAT IS IT?

The conceptual model is described in the accompanying research paper.

## HOW IT WORKS

The model is described in the accompanying research paper.

NOTE:
-- Network node sizes are proportional to the node's privacyAttitude value.

-- When a node's privacyAttitude attribute is greater than or equal to the adoptionThreshold, its color will change from grey to green on the network display.

## HOW TO USE IT

Steps to use the model:

1) Select a test network under the pulldown options in the top-left corner ("networkFilename" pulldown).

2) Select a "boundedConfidenceThreshold" value for the core HK algorithm.  (Suggest starting at 0.35) 

3) Select an "adoptionThreshold" value.  (Suggest 0.75).  This value is the privacyAttitude threshold at which a node gives up private information and adopts the wellness program.  

4) Press the "Load Graph & Reset"

5) Press "Run Continuously" to observe results.  Press again to stop.

6) Turn on the "enableHRinformationDistribution?" switch to enable the HR information influence engine.

7) Select an "HRboundedConfidenceThreshold" value for the modified HK algorithm that includes external HR influences.  (Suggest starting at 0.5)

8) Select an "HRminimumTickInterval" value, which is the number of simulation ticks between each HR information distribution events.

9) Press the "Load Graph & Reset".  HR distribution events will be displayed as vertical lines in the "HR Information Distribution Events" box.

10) Press "Run Continuously" to observe results.  Press again to stop.

11) Turn on the "enablePrivacyViolations?" switch to enable the privacy violation generation engine.

12) Select an "PVboundedConfidenceThreshold" value for the modified HK algorithm that includes external privacy violation influences.  (Suggest starting at 1.0)

13) Select an "privacyMinimumTickInterval" value, which is the number of simulation ticks between each privacy micro-violation event.

14) Press the "Load Graph & Reset".  Privacy micro-violations will be shown as spikes of various magnitude in the "Transient Privacy Micro-Violation Level" box.

15) Press "Run Continuously" to observe results.  Press again to stop.


## CREDITS AND REFERENCES

The code section that imports a graph GML was adapted from code from the online NetLogo help file for the NetLogo network extension found at:
http://ccl.northwestern.edu/netlogo/5.0/docs/nw.html#load-matrix

The Layout Nodes code section that arranges nodes on the display is a modified code segment from:
Giant Component Sample Model by Uri Wilensky, 2005.
Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/.
Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

The random power-law value genereator algorithm is modified from discussion found at:
Stack Overflow:  Python : generating random numbers from a power law distribution https://stackoverflow.com/questions/31114330/python-generating-random-numbers-from-a-power-law-distribution
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
