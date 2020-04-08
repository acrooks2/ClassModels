;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; MULTI-TRACK DIPLOMACY OPINION DYNAMICS MODEL
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; We began development of this model, starting from work from Jan Lorenz (2012) and have used his basic code and model
;; framework. We have extended it to include MHK (Fu et al., 2015), and our model, MDHK.



;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; AGENTS
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

breed [citizens citizen]
breed [track2s track2]
breed [track1s track1]
breed [opinionMarkers opinionMarker]

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; GLOBAL AND AGENT VARIABLES
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;; variables to display the parameters of the beta distribution from which the current eps-values are drawn
;; the slider-variables min_eps, max_eps, alpha, beta are changed to current_... when new_confidence_bounds is called
globals
[
  g.propOpenMinded           ;; proportion of open minded citizens
  g.propModerateMinded       ;; proportion of moderate minded citizens
  g.propClosedMinded         ;; proportion of closed minded citizens

  g.agentSet.openMinded      ;; agentset of open-minded citizens
  g.agentSet.moderateMinded  ;; agentset of moderate-minded citizens
  g.agentSet.closedMinded    ;; agentset of closed-minded citizens

  g.openMinded_min           ;; interval min for epsilon of open-minded citizens
  g.openMinded_max           ;; interval max for epsilon of open-minded citizens
  g.moderateMinded_min       ;; interval min for epsilon of moderate-minded citizens
  g.moderateMinded_max       ;; interval max for epsilon of moderate-minded citizens
  g.closedMinded_min         ;; interval min for epsilon of closed-minded citizens
  g.closedMinded_max         ;; interval max for epsilon of closed-minded citizens

  g.opinion-T1               ;; mean opinion for T1 leadership
  g.opinion-T2               ;; mean opinion for all T2 leadership
]

turtles-own
[
  agent.opinion          ;; opinion on interval [0, 1]
  agent.opinionList      ;; opinion-list is to hold the list of the last max-pxcor opinions

  agent.mindedness       ;; integer denoting mindedness of agent (0=open, 1=moderate, 2=closed)

  agent.epsilon          ;; epsilon is the bound of confidence
  agent.alpha            ;; alpha is the self-influence weighting for an agent's opinion
  agent.beta-C           ;; beta-C is the agent's opinion weighting for influential neighbor citizens
  agent.beta-T2          ;; beta-T2 is the agent's opinion weighting for T2 influence
  agent.beta-T1          ;; beta-T1 is the agent's opinion weighting for T1 influence
]

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; SETUP
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to setup
  ;;random-seed 05101977                              ;; assign seed for model result replicability
  if (specifySeed = true) [ random-seed randomSEED ]

  clear-all
  ask patches [ set pcolor white ]

  set g.propOpenMinded 0.3 ;;0.5
  set g.propModerateMinded 0.5 ;;0.3
  set g.propClosedMinded 0.2 ;;0.2

;  set g.propClosedMinded citizen.closedMinded
;  set g.propOpenMinded (1 - g.propClosedMinded)
;  set g.propModerateMinded 0

  set g.openMinded_min 0.40                         ;; as per Fu et al. (2015)
  set g.openMinded_max 0.90                         ;; as per Fu et al. (2015)
  set g.moderateMinded_min 0.20                     ;; as per Fu et al. (2015)
  set g.moderateMinded_max 0.30                     ;; as per Fu et al. (2015)
  set g.closedMinded_min 0.01                       ;; as per Fu et al. (2015)
  set g.closedMinded_max 0.05                       ;; as per Fu et al. (2015)

  create-citizens population.citizens               ;; instantiate the citizen population
  [
    set size 1
    set shape "dot"
    set color blue

    agent.initializeOpinions
    agent.asignMindedness                           ;; assign mindedness of the citizen as open-, moderate-, or closed-minded
  ]

  ;; if the user specifies leadership figures, instantiate Track I and II leader populations
  ;if (communication_regime = "MDHK (MHK with leaders)")
  ;[
    create-track2s population.Track2                ;; instantiate the Track II leader population
    [
      set size 4
      set shape "shape.T2"
      set color orange
      set pen-size 2.5

      agent.initializeOpinions
      ;; NOTE: T2 mindedness is assigned in the agent.applyHeterogeneousConfidence method
    ]

    create-track1s population.Track1                  ;; instantiate the Track I leader population
    [
      set size 5
      set shape "shape.T1"
      set color red
      set pen-size 5

      agent.initializeT1Opinion
      ;; NOTE: T1 mindedness is assigned in the agent.applyHeterogeneousConfidence method
    ]
  ;]

  ;; assign epsilon values
  agent.applyHeterogeneousConfidence                ;; give all agents heterogeneous bounds of confidence (epsilon)

  model.updateGlobalMeanOpinions
  ;;model.showT1Opinion

  ;;model.drawT1Opinion
  ;;model.drawT2Opinion

  reset-ticks
end

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; MAIN
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to go
  if ticks >= 100
  [
    if (outputHist = true)
    [
      ;;let _filename (word "opinionClusterplot_" (random-float 1.0) ".csv")
      let _filename (word "C:/Users/bhorio/Documents/My - GMU/CSS600/Project/plots/" "opinionClusterplot_" (random-float 1.0) ".csv")
      export-plot "Citizen Opinion" _filename
    ]
    stop
  ]

  ;; add the current opinion to the agent's opinion list
  ask turtles
  [
    set agent.opinionList lput agent.opinion agent.opinionList      ;; put opinion after opinion-list to use it as "old" value for simulatanous update in HK
  ]

  ifelse (communication_regime = "DW (select one)")
  [
    ;; DW MODEL

;;;    repeat count turtles [ask one-of turtles [ agent.updateOpinion ]]    ;; in original DW we chose N random pairs each tick
    repeat count citizens [ask one-of citizens [ agent.updateOpinion ]]    ;; in original DW, we choose N random pairs each tick
  ]
  [
    ;; HK MODEL

;;;    ask turtles     ;; in all other versions there is an update for each agent every tick
    ask citizens           ;; ask all citizens to update their opinion every tick
    [
      agent.updateOpinion
    ]
  ]

;;;  ask turtles      ;; update the opinion-list
  ask citizens      ;; update the opinion-list
  [
    ;; replaces the last entry in the opinion list with the agent's updated opinion
    set agent.opinionList replace-item ( length agent.opinionList - 1) agent.opinionList agent.opinion
  ]

  ask turtles      ;; cut oldest values for "rolling" opinion list
;;  ask citizens      ;; cut oldest values for "rolling" opinion list
  [
;;    if (length agent.opinionList = max-pxcor - 10)
    if (length agent.opinionList = max-pxcor + 1)
    [
      ;; updates the opinion list to include all historical data but the earliest entry, thereby creating a "rolling" list
      set agent.opinionList butfirst agent.opinionList
    ]
  ]

  model.updateGlobalMeanOpinions               ;; update globals for leadership mean opinion

;;  ask opinionMarkers [ set ycor g.opinion-T1 ]


  model.drawTrajectories                       ;; plot the opinion landscape
  ;;model.drawT1Opinion                          ;; overlay plot line for mean T1 opinion
  ;;model.drawT2Opinion                          ;; overlay plot line for mean T2 opinion (all T2's)

  tick                                         ;; advance the simulation clock
end

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; AGENT METHODS
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to agent.initializeOpinions
  set agent.opinion agent.calcNewOpinion        ;; call's the agent's function to generate a new opinion
  set agent.opinionList (list agent.opinion)    ;; adds the inital opinion as a first entry to the agent's opinion list
  setxy 0 (agent.opinion * max-pycor)           ;; sets x-position to 0, and y-position to some position within the y-axis range
end

to agent.initializeT1Opinion
  set agent.opinion 0.5                         ;; call's the agent's function to generate a new opinion
  set agent.opinionList (list agent.opinion)    ;; adds the inital opinion as a first entry to the agent's opinion list
  setxy 0 (agent.opinion * max-pycor)           ;; sets x-position to 0, and y-position to some position within the y-axis range
end

to agent.asignMindedness
  let _draw random-float 1
  ifelse ( _draw <= g.propOpenMinded )
  [
    set agent.mindedness 0              ;; open-minded
  ]
  [
    ifelse (_draw <= (1 - g.propClosedMinded))
    [
      set agent.mindedness 1            ;; moderate-minded
    ]
    [
      set agent.mindedness 2            ;; closed-mindedness
    ]
  ]
end

to agent.updateOpinion

  ;; *** DW MODEL ***
  if (communication_regime = "DW (select one)")
  [
    ;; adjust opinion with random partner
    let partner one-of turtles
    if (abs (agent.opinion - [agent.opinion] of partner) < agent.epsilon )
    [
      set agent.opinion (agent.opinion + [agent.opinion] of partner) / 2

      ask partner
      [
        if (abs (agent.opinion - [agent.opinion] of myself) < agent.epsilon )
        [
          set agent.opinion (agent.opinion + [agent.opinion] of myself) / 2
        ]
      ]
    ]
  ]

  ;; *** HK MODEL ***
  if (communication_regime = "HK (select all)")
  [
    ;; *** original HK MODEL ***
    ;; adjust opinion to mean of all in agents closer than an agent's epsilon
    set agent.opinion agent.aggregateOpinion ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of turtles )
  ]

  ;; *** MHK MODEL ***
  if (communication_regime = "MHK (HK with self-weight)")
  [
    ;; *** HK model as per Fu (2015) with heterogeneous bounds, influential neighbor sets that exclude yourself, and self-weight
    let _influentialCitizens ( filter [ ?1 -> abs(last agent.opinionList - ?1) < agent.epsilon ] [last agent.opinionList] of other citizens )

    if ( not empty? _influentialCitizens )  ;; implies that else, agent keeps thier old opinion
    [
      set agent.opinion ( (alpha.citizen * agent.opinion) + ((1 - alpha.citizen) * mean _influentialCitizens) )
    ]
  ]

  ;; *** MDHK MODEL ***
  if (communication_regime = "MDHK (MHK with leaders)")
  [
    ;; *** MDHK model, extending Fu (2015) to include leadedrship influences of multi-track diplomacy
    ;; 'filter' generates the subset of 'influential' neighbors, after which the mean/median is set as the opinion
    ;; 'filter' reports a list containing only those items of a list for which the task reports true (params: criteria, list (not including agent itself))
    ask citizens
    [
      let _influentialCitizens ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of other citizens )
      let _influentialT2s ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of track2s )
      let _influentialT1s ( [last agent.opinionList] of track1s )

      let _mergedInfluences (sentence _influentialCitizens _influentialT2s _influentialT1s)

      let _citizenComponent 0
      let _t2Component 0
      let _t1Component 0

      if ( not empty? _mergedInfluences )   ;; implies that else, agent keeps thier old opinion
      [
        set agent.opinion agent.calcOpinionUpdate agent.opinion
                                                  _influentialCitizens
                                                  _influentialT2s
                                                  _influentialT1s
                                                  alpha.citizen
                                                  beta.citizen-citizen
                                                  beta.citizen-T2
                                                  beta.citizen-T1
        ;if ( not empty? _influentialCitizens ) [ set _citizenComponent (agent.beta-C * mean _influentialCitizens) ]
        ;if ( not empty? _influentialT2s ) [ set _t2Component (agent.beta-T2 * mean _influentialT2s) ]
        ;if ( not empty? _influentialT1s ) [ set _t1Component (agent.beta-T1 * mean _influentialT1s) ]

        ;set agent.opinion ( (alpha.citizen * agent.opinion) + ((1 - alpha.citizen) * (_citizenComponent + _t2Component + _t1Component)) )
      ]
    ]

    ask track2s
    [
      let _influentialCitizens ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of citizens )
      let _influentialT2s ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of other track2s )
      let _influentialT1s ( [last agent.opinionList] of track1s )

      let _mergedInfluences (sentence _influentialCitizens _influentialT2s _influentialT1s)

      if ( not empty? _mergedInfluences )   ;; implies that else, agent keeps thier old opinion
      [
        set agent.opinion agent.calcOpinionUpdate agent.opinion
                                                  _influentialCitizens
                                                  _influentialT2s
                                                  _influentialT1s
                                                  alpha.T2
                                                  beta.T2-citizen
                                                  beta.T2-T2
                                                  beta.T2-T1

        ;let _citizenComponent (agent.beta-C * mean _influentialCitizens)
        ;let _t2Component (agent.beta-T2 * mean _influentialT2s)
        ;let _t1Component (agent.beta-T1 * mean _influentialT1s)

        ;set agent.opinion ( (agent.alpha * agent.opinion) + ((1 - agent.alpha) * (_citizenComponent + _t2Component + _t1Component)) )
      ]
    ]

    ask track1s
    [
      let _influentialCitizens ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of citizens )
      let _influentialT2s ( filter [ ?1 -> abs(last agent.opinionList - ?1) <= agent.epsilon ] [last agent.opinionList] of track2s )
      let _influentialT1s []
      ;;let _influentialT1s ( [last agent.opinionList] of track1s )

      let _mergedInfluences (sentence _influentialCitizens _influentialT2s ) ;;_influentialT1s)

      if ( not empty? _mergedInfluences )   ;; implies that else, agent keeps thier old opinion
      [
        set agent.opinion agent.calcOpinionUpdate agent.opinion
                                                  _influentialCitizens
                                                  _influentialT2s
                                                  _influentialT1s
                                                  alpha.T1
                                                  beta.T1-citizen
                                                  beta.T1-T2
                                                  0                           ;; assumes that we only have one T1 figurehead, thus no other T1's to weight

        ;let _citizenComponent (agent.beta-C * mean _influentialCitizens)
        ;let _t2Component (agent.beta-T2 * mean _influentialT2s)

        ;set agent.opinion ( (agent.alpha * agent.opinion) + ((1 - agent.alpha) * (_citizenComponent + _t2Component)) )
      ]
    ]
  ]
end

;; /**
;;  * Used for MDHK model runs only; calculates opinion changes as a result of weighted interactions with influential populations
;;  **/
to-report agent.calcOpinionUpdate [ opinion C-opinions T2-opinions T1-opinions alpha beta-C beta-T2 beta-T1 ]
  let _citizenComponent 0
  let _t2Component 0
  let _t1Component 0

  if ( not empty? C-opinions ) [ set _citizenComponent (beta-C * mean C-opinions) ]
  if ( not empty? T2-opinions ) [ set _t2Component (beta-T2 * mean T2-opinions) ]
  if ( not empty? T1-opinions ) [ set _t1Component (beta-T1 * mean T1-opinions) ]

  report ( (alpha * opinion) + ((1 - alpha) * (_citizenComponent + _t2Component + _t1Component)) )
end

;;/**
;; * Returns a random opinion value on the continuous interval [0, 1].
;; */
to-report agent.calcNewOpinion
  report random-float 1
end

;;/**
;; * Returns mean or median of an input set of opinions, as specified by user on the GUI.
;; * params: opinions   list of agent opinions
;; */
to-report agent.aggregateOpinion [opinions]
  report mean opinions
end

to agent.applyHeterogeneousConfidence

  ;;set g.agentSet.openMinded other citizens with [agent.mindedness = 0]
  ;;set g.agentSet.moderateMinded other citizens with [agent.mindedness = 1]
  ;;set g.agentSet.closedMinded other citizens with [agent.mindedness = 2]

  ;; citizen epsilons are derived on static intervals for agent mindedness categories; defined as global variables for interval min/max
  ask citizens with [ agent.mindedness = 0 ] [ set agent.epsilon (uniformDraw (g.openMinded_min) (g.openMinded_max)) ]
  ask citizens with [ agent.mindedness = 1 ] [ set agent.epsilon (uniformDraw (g.moderateMinded_min) (g.moderateMinded_max)) ]
  ask citizens with [ agent.mindedness = 2 ] [ set agent.epsilon (uniformDraw (g.closedMinded_min) (g.closedMinded_max)) ]

  ;; track II agents assumed with one uniformly drawn epsilon from a user-specified interval min/max
  ask track2s [ set agent.epsilon (uniformDraw (T2.epsilon-min) (T2.epsilon-max)) ]

  ;; track I agents assumed with one uniformly drawn epsilon from a user-specified interval min/max
  ask track1s [ set agent.epsilon (uniformDraw (T1.epsilon-min) (T1.epsilon-max)) ]

  update-plots
end

to-report uniformDraw [ minVal maxVal ]
  report (minVal + random-float(maxVal - minVal))
end

;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;; MODEL METHODS
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

to model.drawTrajectories
  ;; let turtles move with their opinion trajectories from left to right across the world drawing trajectories or coloring patches
  clear-drawing
  ask turtles
  [
    pen-up
    setxy 0 (item 0 agent.opinionList * max-pycor)
  ]

  ifelse (visualization = "Colored histogram over time")
  [
    ask turtles [ pen-up ]
  ]
  [
    ask turtles [ pen-down ]
  ]


  let _t-counter 1
  while [ _t-counter < (length ( [agent.opinionList] of turtle 1 )) ]
  [
    ask turtles
    [
      setxy _t-counter (item _t-counter agent.opinionList * max-pycor)
    ]

    ifelse (visualization = "Colored histogram over time")
    [
      ask patches with [pxcor = _t-counter ]
      [
        set pcolor model.getColorCode ((count turtles-here) / population.citizens) 0.2
      ]
    ]
    [
      ask patches
      [
        set pcolor white
      ]
    ]

    set _t-counter _t-counter + 1
  ]


end

;;/**
;; * Updates the global variables for tracking mean opinion for all T1's and T2's.
;; */
to model.updateGlobalMeanOpinions
  if (communication_regime = "MDHK (MHK with leaders)")
  [
    set g.opinion-T1 (mean [ycor] of track1s)
    set g.opinion-T2 (mean [ycor] of track2s)
  ]
end

to model.showT1Opinion
  create-opinionMarkers 1
  [
    set shape "shape.T1-arrow"
    setxy (max-pxcor - 5) g.opinion-T1
    set size 4
  ]
end

to model.drawT1Opinion
  ;; make this a dashed line!
  crt 1
  [
    setxy 0 g.opinion-T1
    pen-down
    set color red
    facexy 120 g.opinion-T1
    fd 120
    die
  ]
end

to model.drawT2Opinion
  ;; make this a dashed line!
  crt 1
  [
    setxy 0 g.opinion-T2
    pen-down
    set color blue
    facexy 120 g.opinion-T2
    fd 120
    die
  ]
end

to-report model.getColorCode [x max_x]
  ;; report a color as "x=0 --> violet", "x=max_x --> red" on the color axis violet,blue,cyan,green,yellow,orange,red
  report __hsb-old (190 - 190 * (x / max_x)) 255 255
end
@#$#@#$#@
GRAPHICS-WINDOW
241
10
834
387
-1
-1
4.84211
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
120
0
75
1
1
1
ticks
30.0

BUTTON
8
241
74
274
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
156
241
218
274
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
5
108
223
141
population.citizens
population.citizens
0
1000
150.0
1
1
NIL
HORIZONTAL

CHOOSER
6
301
220
346
communication_regime
communication_regime
"HK (select all)" "MHK (HK with self-weight)" "MDHK (MHK with leaders)" "DW (select one)"
3

PLOT
201
441
371
561
Citizen Epsilon
epsilon
NIL
0.0
1.0
0.0
30.0
false
false
"" "set-plot-y-range 0 round(population.citizens / 8)"
PENS
"default" 0.02 1 -16777216 true "" "histogram [agent.epsilon] of citizens"

TEXTBOX
7
222
157
240
Setup and Go
12
0.0
1

CHOOSER
850
10
1138
55
visualization
visualization
"Colored histogram over time" "Agents' trajectories"
1

PLOT
849
58
1207
218
Citizen Opinion
opinion
count
0.0
1.0
0.0
0.0
true
false
"" "set-plot-y-range 0 round(population.citizens / 8)"
PENS
"default" 0.02 1 -13345367 true "" "histogram [agent.opinion] of citizens"

TEXTBOX
6
283
250
301
Communication and Opinion Update
12
0.0
1

MONITOR
201
561
371
606
citizen epsilon (mean)
mean [agent.epsilon] of citizens
4
1
11

PLOT
849
230
1209
407
Average Opinion
time
opinion
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Citizens" 1.0 0 -13345367 true "" "plot mean [agent.opinion] of citizens"
"T2 Leaders" 1.0 0 -955883 true "" "if (communication_regime = \"MDHK (MHK with leaders)\") [plot mean [agent.opinion] of track2s]"
"T1 Leader" 1.0 0 -2674135 true "" "if (communication_regime = \"MDHK (MHK with leaders)\") [plot mean [agent.opinion] of track1s]"

SLIDER
5
144
223
177
population.Track1
population.Track1
0
5
1.0
1
1
NIL
HORIZONTAL

SLIDER
4
181
222
214
population.Track2
population.Track2
0
25
5.0
1
1
NIL
HORIZONTAL

TEXTBOX
10
10
229
61
CONTINUOUS OPINION DYNAMICS\nOF MULTI-TRACK DIPLOMACY 
12
0.0
1

TEXTBOX
9
40
225
96
__________________________________\nThis model explores opinion dynamics of a population under conditions of leadership opinion influences.
11
0.0
1

TEXTBOX
8
418
158
436
CITIZEN POPULATION
12
0.0
1

SLIDER
6
450
194
483
alpha.citizen
alpha.citizen
0
1
0.5
0.01
1
self-weighting
HORIZONTAL

SLIDER
406
449
607
482
alpha.T2
alpha.T2
0
1
0.5
0.01
1
self-weighting
HORIZONTAL

SLIDER
823
450
1024
483
alpha.T1
alpha.T1
0
1
1.0
0.01
1
self-weighting
HORIZONTAL

TEXTBOX
203
426
388
454
Citizen epsilon (confidence threshold)
10
0.0
1

TEXTBOX
9
433
159
451
Citizen alpha (self-weight)
10
0.0
1

SLIDER
5
505
194
538
beta.citizen-citizen
beta.citizen-citizen
0
1
0.38
0.01
1
weighting
HORIZONTAL

SLIDER
5
540
194
573
beta.citizen-T2
beta.citizen-T2
0
1
0.34
0.01
1
weighting
HORIZONTAL

SLIDER
5
575
194
608
beta.citizen-T1
beta.citizen-T1
0
1
0.35
0.01
1
weighting
HORIZONTAL

TEXTBOX
9
489
214
515
Citizen beta's (NOTE: b1 + b2 + b3 = 1)
10
0.0
1

TEXTBOX
406
418
556
436
TRACK II POPULATION
12
0.0
1

TEXTBOX
408
433
558
451
Track II alpha (self-weight)
10
0.0
1

TEXTBOX
407
486
602
512
Track II beta's (NOTE: b1 + b2 + b3 = 1)
10
0.0
1

SLIDER
406
503
607
536
beta.T2-citizen
beta.T2-citizen
0
1
0.34
0.01
1
weighting
HORIZONTAL

SLIDER
406
539
608
572
beta.T2-T2
beta.T2-T2
0
1
0.33
0.01
1
weighting
HORIZONTAL

SLIDER
406
574
608
607
beta.T2-T1
beta.T2-T1
0
1
0.33
0.01
1
weighting
HORIZONTAL

SLIDER
616
451
788
484
T2.epsilon-min
T2.epsilon-min
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
616
486
788
519
T2.epsilon-max
T2.epsilon-max
0
1
0.05
0.01
1
NIL
HORIZONTAL

TEXTBOX
618
435
790
461
Track II epsilon (confidence bounds)
10
0.0
1

MONITOR
618
560
789
605
T2 epsilon (mean)
mean [agent.epsilon] of track2s
4
1
11

TEXTBOX
823
419
973
437
TRACK I POPULATION
12
0.0
1

TEXTBOX
825
434
975
452
Track I alpha (self-weight)
10
0.0
1

TEXTBOX
824
487
1028
513
Track I beta's (NOTE: b1 + b2 = 1)
10
0.0
1

SLIDER
824
502
1024
535
beta.T1-citizen
beta.T1-citizen
0
1
0.5
0.01
1
weighting
HORIZONTAL

SLIDER
825
537
1024
570
beta.T1-T2
beta.T1-T2
0
1
0.5
0.01
1
weighting
HORIZONTAL

TEXTBOX
1036
433
1210
459
Track I epsilon (confidence bounds)
10
0.0
1

SLIDER
1035
449
1207
482
T1.epsilon-min
T1.epsilon-min
0
1
0.01
0.01
1
NIL
HORIZONTAL

SLIDER
1035
483
1207
516
T1.epsilon-max
T1.epsilon-max
0
1
0.05
0.01
1
NIL
HORIZONTAL

MONITOR
1035
559
1209
604
T1 epsilon (mean)
mean [agent.epsilon] of track1s
4
1
11

BUTTON
83
241
146
274
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

INPUTBOX
7
353
87
413
randomSEED
5101977.0
1
0
Number

SWITCH
88
380
211
413
outputHist
outputHist
1
1
-1000

SWITCH
88
347
211
380
specifySeed
specifySeed
0
1
-1000

SLIDER
6
629
215
662
citizen.closedMinded
citizen.closedMinded
0
1
0.0
0.01
1
percent
HORIZONTAL

@#$#@#$#@
# Continuous Opinion Dynamics under Bounded Confidence 
### using code and Info tab descriptions from Jan Lorenz, with modifications by the students.

## WHAT IS IT?

A model of **continuous opinion dynamics under hetergeneous bounded confidence**, which includes 

  * its two main variants of communication regimes (as in [Deffuant et al 2000](http://dx.doi.org/10.1142/S0219525900000078) with &mu;=0.5 and as in  [Hegselmann and Krause 2002](http://jasss.soc.surrey.ac.uk/5/3/2.html))
  * Modified HK (Fu et al., 2015)
  * Multi-track Diplomacy HK (MDHK)

Visualizations:

  * a rolling colored histogram of opinion density over time
  * rolling trajectories of opinions over time colored by the bound of confidence 
  * a bar plot histogram of current opinions 
  * trajectories of the mean and the median opinion over time.  


## HOW IT WORKS

### In a nutshell

Agents adjust their opinion gradually towards the opinions of others when the distance in opinion is within their bound of confidence. When using MDHK, you can explore the influence of multi-track leadership on opinion formation. Note that if using MDHK, you must have T2 and T1 agent populations greater than 0, or it will crash. This will be fixed in future versions. 

### Variables

Each of N agent has its **opinion** between 0.0 and 1.0 as a dynamic variable and its **bound of confidence** (epsilon) as a static variable. Other variables relate to self-weighting of opinion, and weighting for other opinions from multi-track leadership. 

### Setup

Each agent is assigned its initial opinion as a random number between 0.0 and 1.0 from the uniform distribution and positioned on the y-axis of the world. Each agent is assigned its bound of confidence and other user-specified variables.

### Dynamics

Each tick agents are asked to adjust their opinions with respect to the opinions of others that they determine to be influential.

**Communication and aggregation:**

  * "DW (select one)": Each tick each agent is asked to select a random partner and changes its opinion to the average of the two opinions but only when the opinion of the partner is closer than eps to the own opinion.
N randomly selected agents are chosen each tick (so some agents possibly more than once) and both agents (the selected one and the randomly selected partner) both adjust opinions. (This is the version of Deffuant et al 2000)
  * "HK (select all)": Each tick each agent is asked to change its opinion to the aggregated opinion of all opinions which are closer than eps to its opinion. The aggregate opinion can be the mean or the median. All agents do the change simultaneously. (This is the version of Hegselmann and Krause 2002. 
  * "MHK": Essentially the HK model, except they agents consider their own opinions independently, weighted by some self-weight.
  * "MHK": Essentially the MHK model, except multi-track leadership influences are introduced. All agents consider the opinions in some way for citizens, Track II leaders, and Track I leaders.


## HOW TO USE IT

Click "setup" to inititialize agents with opinions random and uniformly distributed between 0.0 and 1.0. Agents are located at the left border of the world with their opinions spreading over the vertical axis. Further, on confidence bounds are initialized for each agent as random draws from a beta distribution under the current choice of the four parameters. 

Click "go" to start the simulation. Agents move with ticks from left to right, displaying their opinion with the position on the vertical axis. This goes over into a "rolling" graphic in the world, where the last 120 ticks are shown (respectively the last max-pxcor ticks). Visualization can be chosen as trajectories of agents or as color-coded histograms. In colored histograms each patch's color is associated to the number of agents at this patch. 


## THINGS TO NOTICE

Agents move towards the right-hand side of the world with one step each tick. This goes over into a "rolling" plot. 

Notice how agents form **clusters** in the opinion space. See how these clusters **evolve**, **drift** and **unite** in the "**Colored histograms over time**"-visualization. 

Look at the role of agents with different bounds of confidence in the "**Agents' trajectories**"-visualization. 

Look at the current distribution of opinions in the **bar plot histogram** on the right hand side and compare it to the colored histogram (the most recent colored vertical line in the world at the right hand side).

Look how the **mean and the median opinion** evolve over time. The mean represents the center of mass of the distribution (cf. the current histogram). The median represents an unbeatable opinion under pairwise majority decisions. (This holds when agents have single-peaked preferences with peaks at their opinion, cf. [median voter theorem](http://en.wikipedia.org/wiki/Median_voter_theorem)).

Look how the histogram of bounds of confidence matches the probability density function of the beta distribution when you click "new_confidence_bounds". 


## RELATED MODELS AND PAPERS

**Original HK and DW models**
Hegselmann, R. & Krause, U. [Opinion Dynamics and Bounded Confidence, Models, Analysis and Simulation](http://jasss.soc.surrey.ac.uk/5/3/2.html) Journal of Artificial Societies and Social Simulation, 2002, 5, 2
Deffuant, G.; Neau, D.; Amblard, F. & Weisbuch, G. [Mixing Beliefs among Interacting Agents](http://dx.doi.org/10.1142/S0219525900000078) Advances in Complex Systems, 2000, 3, 87-98
Weisbuch, G.; Deffuant, G.; Amblard, F. & Nadal, J.-P. [Meet, discuss, and segregate!](http://dx.doi.org/10.1002/cplx.10031) Complexity, 2002, 7, 55-63

**General model including HK and DW**
Urbig, D.; Lorenz, J. & Herzberg, H. [Opinion dynamics: The effect of the number of peers met at once](http://jasss.soc.surrey.ac.uk/11/2/4.html) Journal of Artificial Societies and Social Simulation, 2008, 11, 4

**On noise:** 
Pineda, M.; Toral, R. & Hernandez-Garcia, E. [Noisy continuous-opinion dynamics](http://stacks.iop.org/1742-5468/2009/P08001) Journal of Statistical Mechanics: Theory and Experiment, 2009, 2009, P08001 (18pp)
Mäs, M.; Flache, A. & Helbing, D. [Individualization as Driving Force of Clustering Phenomena in Humans](http://dx.doi.org/10.1371/journal.pcbi.1000959) PLoS Comput Biol, Public Library of Science, 2010, 6, e1000959

**On heterogeneous bounds of confidence**
Lorenz, J. [Heterogeneous bounds of confidence: Meet, Discuss and Find Consensus!](http://dx.doi.org/10.1002/cplx.20295) Complexity, 2010, 15, 43-52

**On extremism**
Deffuant, G.; Neau, D.; Amblard, F. & Weisbuch, G. [How Can Extremism Prevail? A Study Based on the Relative Agreement Interaction Model](http://jasss.soc.surrey.ac.uk/5/5/1.html) Journal of Artificial Societies and Social Simulation, 2002, 5, 1
Deffuant, G. [Comparing Extremism Propagation Patterns in Continuous Opinion Models](http://jasss.soc.surrey.ac.uk/9/3/8.html) Journal of Artificial Societies and Social Simulation, 2006, 9, 8

**Survey, Motivation and Variation**
Lorenz, J. [Continuous Opinion Dynamics under bounded confidence: A Survey](http://dx.doi.org/10.1142/S0129183107011789) Int. Journal of Modern Physics C, 2007, 18, 1819-1838
Urbig, D. [Attitude Dynamics with Limited Verbalisation Capabilities](http://www.jasss.surrey.ac.uk/6/1/2.html) Journal of Artificial Societies and Social Simulation, 2003, 6, 2
Lorenz, J. & Urbig, D. [About the Power to Enforce and Prevent Consensus by Manipulating Communication Rules](http://dx.doi.org/10.1142/S0219525907000982) Advances in Complex Systems, 2007, 10, 251
Amblard, F. & Deffuant, G. [The role of network topology on extremism propagation with the relative agreement opinion dynamics](http://dx.doi.org/10.1016/j.physa.2004.06.102) Physica A: Statistical Mechanics and its Applications, 2004, 343, 725-738 
Groeber, P.; Schweitzer, F. & Press, K. [How Groups Can Foster Consensus: The Case of Local Cultures](http://jasss.soc.surrey.ac.uk/12/2/4.html) Journal of Artificial Societies and Social Simulation, 2009, 12, 4




## CREDITS AND REFERENCES

Copyright 2012 Jan Lorenz. http://janlo.de, post@janlo.de for the orginal NetLogo code and for the majority of this fantastic Info tab write-up.

![Creative Commons Attribution-ShareAlike 3.0 Unported License](http://i.creativecommons.org/l/by-sa/3.0/88x31.png)
 
This work is licensed under the Creative Commons Attribution-ShareAlike 3.0 Unported License. To view a copy of this license, visit http://creativecommons.org/licenses/by-sa/3.0/ .
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

shape.t1
false
0
Circle -7500403 true true 60 90 120
Rectangle -2674135 true false 180 15 255 30
Rectangle -2674135 true false 210 30 225 90
Rectangle -2674135 true false 270 15 285 90

shape.t1-arrow
false
0
Rectangle -16777216 true false 165 105 240 120
Rectangle -16777216 true false 195 120 210 195
Rectangle -16777216 true false 270 105 285 180
Line -16777216 false 0 150 150 150
Line -16777216 false 0 150 60 105
Line -16777216 false 0 150 60 195
Rectangle -16777216 true false 255 105 270 120
Rectangle -16777216 true false 255 180 300 195

shape.t2
false
0
Circle -7500403 true true 60 90 120
Rectangle -16777216 true false 150 15 225 30
Rectangle -16777216 true false 180 30 195 90
Rectangle -16777216 true false 255 15 285 30
Rectangle -16777216 true false 240 30 255 45
Rectangle -16777216 true false 285 30 300 45
Rectangle -16777216 true false 270 45 285 60
Rectangle -16777216 true false 255 60 270 75
Rectangle -16777216 true false 240 75 300 90

shape.t2-arrow
false
0
Rectangle -11221820 true false 150 105 225 120
Rectangle -11221820 true false 180 120 195 180
Rectangle -2674135 true false 240 165 255 180
Line -16777216 false 0 150 150 150
Line -16777216 false 0 150 60 105
Line -16777216 false 0 150 60 195
Rectangle -11221820 true false 285 120 300 135
Rectangle -11221820 true false 240 165 300 180
Rectangle -11221820 true false 255 150 270 165
Rectangle -11221820 true false 270 135 285 150
Rectangle -11221820 true false 255 105 285 120
Rectangle -11221820 true false 240 120 255 135

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
  <experiment name="test" repetitions="2" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <enumeratedValueSet variable="alpha.T1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha.T2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="outputHist">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specifySeed">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="T1.epsilon-max">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population.Track2">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population.Track1">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.T2-citizen">
      <value value="0.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="T1.epsilon-min">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.citizen-T2">
      <value value="0.34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.T2-T2">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.T1-T2">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alpha.citizen">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population.citizens">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.T1-citizen">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="communication_regime">
      <value value="&quot;MHK (HK with self-weight)&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.citizen-T1">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="T2.epsilon-min">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="randomSEED">
      <value value="5101977"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.citizen-citizen">
      <value value="0.38"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="T2.epsilon-max">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta.T2-T1">
      <value value="0.33"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="visualization">
      <value value="&quot;Agents' trajectories&quot;"/>
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
