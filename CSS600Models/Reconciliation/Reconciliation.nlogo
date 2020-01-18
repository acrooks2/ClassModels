; RECONCILIATION MODEL
; Optional set-up procedure includes segregation code by Uri Wilensky (see info tab for more information).

; CODE TABLE OF CONTENTS:
; 1. Initializing Variables and Breeds
; 2. Setup
; 3. Adjust Conflict Narrative of Border Agents
; 4. Adjust All Agents' Sentiment
; 5. Update Globals and Plots
; 6. Go and Step
; 7. Run Tests
; 8. Follow an Agent

;=====================================
;1. INITIALIZING VARIABLES AND BREEDS
;=====================================

globals [
  percent-unhappy  ; for use in Schelling set-up
  numBorder        ; number of border agents in model (does not change after set-up)
  avg-conf-narr    ; average of border agents' belief in conflict narrative
  avg-green-conf-narr ; average of green border agents' belief in conflict narrative
  avg-red-conf-narr ; average of red border agents' belief in conflict narrative
  avg-alt-narr     ; average of border agents' belief in alternative narrative
  avg-red-sentiment ; average sentiment of all red agents
  avg-green-sentiment ; average sentiment of all green agents
  remaining-red-conflict-narr ; number of red agents who are still invested in the conflict narrative
  remaining-green-conflict-narr ; number of green agents who are still invested in the conflict narrative
  avg-gap          ; average of gap between border agents' belief in conflict narrative and alter. narrative
  numStep          ; number of steps model takes after setup and before hitting a stopping condition
]

turtles-own [
  ; schelling set-up  (from Uri Willensky's model)
  ;------------------
  happy?
  similar-nearby
  other-nearby
  total-nearby

  ; reconciliation procedures
  ;--------------------------
  leader?             ; is agent a leader?
  border?             ; is agent on the border?
  starting-sentiment  ; agent's setup sentiment
  sentiment           ; records agent's sentiment during model run
  action              ; number representing each agent's action at each step
  observation         ; agent's observation of another agent's action at each step
  partner             ; links observer to actor
  last-obs            ; records previous observed action at each step
  conflict-narrative  ; records agent's conflict-narrative level during model run
  alternative-narrative ; records agent's alternative-narrative level during model run
  gap                 ; difference between agent's conflict-narrative and alternative-narrative
  neighbors-set       ; agentset of agent's neighbors
  nearby-leaders      ; agentset of leaders near agent
  nearby-leader       ; the leader that an agent will follow
  nearby-sentiment-list  ; list of sentiments of agent's neighbors
  nearby-leader-sentiment  ; sentiment of selected leader near agent
  explanation1        ; text field for follow-agent commentary
  explanation2        ; text field for follow-agent commentary
  explanation3        ; text field for follow-agent commentary
]

breed [red-turtles red-turtle]  ; two types of agents
breed [green-turtles green-turtle]

;=========
;2. SETUP
;=========

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set-default-shape turtles "square"   ; all agents begin as squares
  set avg-gap 2   ; due to stopping conditions
  ask turtles [set leader? false] ; start with no leaders
  ifelse schelling?
    [schelling-setup]
    [split-setup]
  set numBorder (count turtles with [border? = true])
  set remaining-red-conflict-narr count red-turtles with [border? = true]
  set remaining-green-conflict-narr count green-turtles with [border? = true]
  ask turtles with [border?] [
    set conflict-narrative conflict-narrative-lvl ; set the agents at a common narrative level set by the user
    set alternative-narrative 5 ; must be greater than 0 to work with some of the psych models.
    set action 0
    set observation 0
    ]
  ask n-of (num-leaders / 2) red-turtles [set color 45 set leader? true]   ; put half of the leaders on red side
  ask n-of (num-leaders / 2) green-turtles [set color 45 set leader? true] ; and half on the green. turn leaders yellow.
  ask turtles [
    set neighbors-set turtles in-radius 2 with [breed = [breed] of myself] ;put neighbors in agentset
    set nearby-leaders turtles in-radius 4 with [leader? = true]           ;put nearby leaders in agentset,
    set nearby-leaders nearby-leaders with [breed = [breed] of myself]     ;if they're of your breed.
    set nearby-leader one-of nearby-leaders                           ; pick one for each agent to follow.
    ]
  poll-neighbors
  shade-color
end

to schelling-setup     ; adapted from Uri Willensky's model
  ask n-of 1500 patches [ sprout-red-turtles 1 ]                ; set up 1500 red agents.
  ask n-of (1500 / 2) turtles [ set breed green-turtles ]       ; turn half green.
  ask red-turtles [set color red]
  ask green-turtles [set color green ]
  ask turtles [
    set starting-sentiment (20 + random 21) ; start all agents' sentiment in range of 20-40
    set sentiment starting-sentiment        ; record original sentiment for future reference
    ]
  update-setup
  loop [ifelse all? turtles [happy?]  ; when agents are all happy with their neighborhood,
    [shade-color                      ; shade them according to their sentiment
     id-border-residents              ; and turn border agents blue
     stop ]
    [ask turtles with [ not happy? ] [ find-new-spot ] ; until then, keep moving them until they are happy
     update-setup
     tick ]
  ]
end

to find-new-spot  ; move 10-patches at a time in a random direction until finding one unoccupied
                  ; from Uri Willensky's model
  rt random-float 360
  fd random-float 10
  if any? other turtles-here
    [ find-new-spot ]
  move-to patch-here
end

to split-setup   ; set up 750 red agents on the right side and 750 green on the left.
  ask n-of (1500 / 2) patches with [pxcor > 0]
    [ sprout-red-turtles 1 ]
  ask n-of (1500 / 2) patches with [pxcor < 0]
    [ sprout-green-turtles 1 ]
  ask red-turtles [set color red]
  ask green-turtles [set color green ]
  tick
  ask turtles [
    set starting-sentiment (20 + random 21)  ; start all agents' sentiment in range of 20-40
    set sentiment starting-sentiment         ; record original sentiment for future reference
    ]
  tick
  shade-color                           ; shade agents according to their sentiment
  id-border-residents                   ; turn border agents blue
end

to update-setup
  update-schelling-turtles
  update-globals-setup
end

to update-schelling-turtles ; from Uri Willensky's model (with hard-coded happiness threshold)
  ask turtles [
    set similar-nearby count (turtles-on neighbors) with [color = [color] of myself]
    set other-nearby count (turtles-on neighbors) with [color != [color] of myself]
    set total-nearby similar-nearby + other-nearby
    set happy? similar-nearby >= ( 75 * total-nearby / 100 )
    ]
end

to update-globals-setup  ; from Uri Willensky's model
  let similar-neighbors sum [similar-nearby] of turtles
  let total-neighbors sum [total-nearby] of turtles
  set percent-unhappy (count turtles with [not happy?]) / (count turtles) * 100
end

;=============================================
;3. ADJUST CONFLICT NARRATIVE OF BORDER AGENTS
;=============================================

to id-border-residents ; figure out if agent has mixed neighbors; if so, change its shape to visually identify
  ask turtles [
    ifelse all? turtles in-radius 2 [breed = [breed] of myself]
      [ set border? false ]
      [ set border? true
        set shape "circle" ]
    ]
end

to take-action ; each border agent takes an action, represented by 0-100, set randomly and then influenced by
               ;   the last action it observed from the other group
  ask turtles with [ border? ]
    [ set action random 90 + (last-obs / 10) ] ; max is around 100. 90% random, 10% last action.
                                               ; Action occasionally is negative, but this does not matter.
end

to observe-a-neighbor ; select one other-group agent within a 2-agent radius and observe its action
  ask turtles [
    set partner one-of (turtles in-radius 2 with [breed != [breed] of myself])
    if partner != nobody ; don't try to observe if you have no one to observe
      [ set observation [action] of partner ]
    ]
end

to interpret-action ; decide whether the observed action fits into the conflict narrative, and
                    ; construct or deconstruct an alternative narrative
  ask turtles with [border?]    ; Non-border agents have nothing to observe, so they have no action to interpret.
    [ ifelse observation > conflict-narrative
      ; Can the observed action be explained through framework of conflict narrative?
      ; (The higher the conflict narrative, the more likely that any action can be explained through that framework.)

      ; If conflict narrative can't explain observation, this opens psychological space for positive interpretation,
      ;    i.e. an alternative narrative.
      [ set explanation1 "obs outside conf-narr"
        set alternative-narrative (alternative-narrative + (95 - alternative-narrative) * reduction-factor)
        set last-obs observation ] ; record last observation (this agent's next action will be slightly higher,
                                 ;   and thus more likely to also challenge the conflict narrative -- as a result)

      ; If conflict narrative can explain observation, this reinforces the conflict narrative and deconstructs
      ;    any alternative narrative.
      [ set explanation1 "obs within conf-narr"
        set last-obs observation * -1 ] ; record last observation as a negative (this agent's next action will be
                                        ; slightly lower, thus less likely to challenge the conflict narrative
    ]
end

to adjust-narrative ; adjust the strength of the conflict narrative.
           ; (The higher the consider-alternative threshold, the stronger the alternative narrative has to be
           ;  before it affects the conflict narrative.)

  ask turtles with [ border? ]
    [ ifelse alternative-narrative > consider-alternative * conflict-narrative ; if the alternative narrative passes threshold
      [ set explanation2 "consider alternative"
        ifelse (random 100) + 1 > conflict-narrative ; give it a chance to adjust to a challenge
        [ set explanation3 "go with alt-narr"
          set conflict-narrative conflict-narrative - (reduction-factor * conflict-narrative)  ; decrease conflict-narrative
          set alternative-narrative 5 ]; restart alt-narr after successful challenge

        [ set explanation3 "reject alt-narr"
          set conflict-narrative conflict-narrative + (reduction-factor * (95 - conflict-narrative)) ;increase conflict-narrative
          set alternative-narrative 5 ]; restart alt-narr after challenge failure

        if conflict-narrative < conflict-narrative-lvl [set color gray]

        if conflict-narrative < 5
         [ set conflict-narrative 0 ; if not stopped, the conflict cycle will produce very small numbers eating up computing resources
          set alternative-narrative 0 ; otherwise gap will be negative
          set color blue ] ; turn agent blue to indicate that conflict narrative has been replaced by alternative narrative
        ]
     [ set explanation2 "don't consider alt-narr"   ; if alternative does not pass original threshold, stop evaluation.
       set explanation3 ""]
   ]
end

;================================
;4. ADJUST ALL AGENTS' SENTIMENT
;================================

to adjust-border-sentiment  ; border turtles adjust their sentiment based on how their conflict-narr compares to where it started
  ask turtles with [ border? ]
    [ set gap (conflict-narrative - alternative-narrative)   ; this is a global for display purposes
      set sentiment (conflict-narrative-lvl - conflict-narrative) / conflict-narrative-lvl * 75 ; make sentiment equal to
                            ; how far conflict-narrative has declined since start, as percent of original level.
                            ; Slight decline = still low sentiment, but not 0. Significant decline = neutral sentiment.
                            ; Then for sentiment to hit 75, not 100, when conflict narrative is completely replaced,
                            ; multiply by 75 rather than 100.

                            ; Note: Uncomment next line if you want to assume that border agents' starting sentiment
                            ; is already as low as it can go. Our default is not to make that assumption.
      ;if sentiment < starting-sentiment [set sentiment starting-sentiment]
   ]
end

to poll-neighbors  ; border agents and interior agents alike recalculate their sentiment based on their
                   ; in-group neighbors' sentiments (average within radius of 2 neighbors and
                   ; double-strength for any leaders within radius of 4 neighbors)
  ask turtles [
    set nearby-sentiment-list [sentiment] of neighbors-set   ;put neighbors' sentiments in list
    if nearby-leader != nobody [
      set nearby-leader-sentiment [sentiment] of nearby-leader  ;record agent's leader's sentiment
      set nearby-sentiment-list fput nearby-leader-sentiment nearby-sentiment-list
      set nearby-sentiment-list fput nearby-leader-sentiment nearby-sentiment-list
              ;add each agent's leader's sentiment twice into the sentiment list to illustrate influence of leaders
      ]
    set sentiment mean nearby-sentiment-list  ;set each agent's sentiment to the average from that list
    if sentiment < 0 [set sentiment 0]
    ]
end

to shade-color   ; angry agents appear brighter than tolerant ones
  ask turtles [ set color scale-color [color] of self sentiment 100 0 ]
end

;============================
;5. UPDATE GLOBALS AND PLOTS
;============================

to update
  update-globals
  my-update-plots
end

to update-globals
  set avg-conf-narr ( mean [conflict-narrative] of turtles with [border?])
  set avg-red-conf-narr ( mean [conflict-narrative] of red-turtles with [border?])
  set avg-green-conf-narr ( mean [conflict-narrative] of green-turtles with [border?])
  set avg-alt-narr ( mean [alternative-narrative] of turtles with [border?])
  set avg-red-sentiment ( mean [sentiment] of red-turtles )
  set avg-green-sentiment ( mean [sentiment] of green-turtles )
  set avg-gap (mean [gap] of turtles with [border?])
  set remaining-red-conflict-narr (count red-turtles with [conflict-narrative > 0])
  set remaining-green-conflict-narr (count green-turtles with [conflict-narrative > 0])
end

to my-update-plots
  set-current-plot "Average Narrative Levels"
  set-current-plot-pen "avg-conf-narr"
  plot avg-conf-narr

  set-current-plot "Average Narrative Levels"
  set-current-plot-pen "avg-red-conf-narr"
  plot avg-red-conf-narr

  set-current-plot "Average Narrative Levels"
  set-current-plot-pen "avg-green-conf-narr"
  plot avg-green-conf-narr

  set-current-plot "Average Narrative Levels"
  set-current-plot-pen "avg-alt-lvl"
  plot avg-alt-narr

  set-current-plot "Average Sentiment"
  set-current-plot-pen "all-red"
  plot avg-red-sentiment

  set-current-plot "Average Sentiment"
  set-current-plot-pen "all-green"
  plot avg-green-sentiment
end

;===============
;6. GO AND STEP
;===============

to step
  if (avg-gap > 1 ) [   ; put stopping condition here as well as in "go" because runTests uses "step" only
    take-action ; this is the action performed by a neighbor
    observe-a-neighbor ; this is an agent looking for an interaction
    interpret-action ; this is how the agent interprets the action through his conflict narrative
    adjust-narrative ; if warranted, see if conflict-narrative needs adjusting
    adjust-border-sentiment ; adjust sentiment as needed as result of observations
    poll-neighbors  ; discuss among your neighbors and adjust sentiment as needed
    shade-color     ; show sentiment via color
    update
    set numStep (numStep + 1)
    tick
    ]
end

to go
  ifelse (avg-gap > 1 )    ; without this condition, it will stop stepping at this point, but "go"
                           ; button will stay pressed, because nothing told it to stop trying to step.
    [step]
    [stop]
end

;=============
;7. RUN TESTS
;=============

to runTests
  let numReps 5        ; <-- number of repetitions of test per variable combination
  let maxSteps 10000   ; <-- number of steps to run per test
  let reduction-factorList (list 0.2)  ; <-- list reduction-factor values to test here
  let conflict-narrative-lvlList (list 20 50 80) ; <-- list conflict-narrative-lvl values to test here
  let consider-alternativeList (list 0.1 0.5 0.8) ; <-- list consider-alternative values to test here
  let num-leadersList (list 30 150)     ; <-- list num-leaders values to test here
  set schelling? true  ; <-- will test be on Schelling or not?

  let a 0
  let b 0
  let c 0
  let d 0
  let i 0
  let rs 1
  set rs 1

  let file user-new-file
  if file-exists? file
    [print "file exists"
     stop ]
  file-open file

  file-print "Reconciliation Model: Parameter Sweep"
  file-type "Schelling? " file-print schelling?
  file-type "reduction-factor " file-print reduction-factorList
  file-type "conflict-narrative-lvl " file-print conflict-narrative-lvlList
  file-type "consider-alternative " file-print consider-alternativeList
  file-type "num-leaders " file-print num-leadersList

  file-print "steps,border agents,reduction-factor,conflict-narrative,consider-alternative,num-leaders,avg-gaps,avg-red-sentiment,avg-green-sentiment,unBlue agents"

  ;data to print as csv:
  foreach reduction-factorList[ ?1 ->
    set a ?1
    set reduction-factor a

    foreach conflict-narrative-lvlList[ ??1 ->
      set b ??1
      set conflict-narrative-lvl b

      foreach consider-alternativeList[ ???1 ->
        set c ???1
        set consider-alternative c

        foreach num-leadersList[ ????1 ->
          set d ????1
          set num-leaders d

          set i 0
          set rs 1
          while [i < numReps] [
            random-seed rs
            setup
            repeat maxSteps[step]
            let remainingUnblue(remaining-red-conflict-narr + remaining-green-conflict-narr)
            set i (i + 1)
            set rs (rs + 1)

            file-type numStep file-type "," file-type numBorder file-type "," file-type a file-type ","
            file-type b file-type "," file-type c file-type "," file-type d file-type ","
            file-type avg-gap file-type "," file-type avg-red-sentiment file-type ","
            file-type avg-green-sentiment file-type "," file-print remainingUnblue
          ]
        ]
      ]
    ]
  ]

  file-print " "
  file-close
end

;===================
;8. FOLLOW ONE AGENT
;===================

to followAgent
  let maxSteps 10000   ; <-- number of steps to run per test (will stop early if conflict-narrative disappears)

  ; select settings for follow-agent test
  set reduction-factor 0.2
  set conflict-narrative-lvl 50
  set consider-alternative 0.10
  set num-leaders 75
  set schelling? false

  ; set up model run according to those settings
  setup

  ; choose a red border agent to follow
  let pick-agent one-of red-turtles with [border? = true]
  set pick-agent pick-agent

  let file user-new-file
  if file-exists? file
    [print "file exists"
     stop ]
  file-open file

  file-print "Reconciliation Model: Life of a Border Agent"
  file-type "Schelling? " file-print schelling?
  file-type "reduction-factor " file-print reduction-factor
  file-type "conflict-narrative-lvl " file-print conflict-narrative-lvl
  file-type "consider-alternative " file-print consider-alternative
  file-type "num-leaders " file-print num-leaders
  file-type "agent number " file-print pick-agent
  file-type "starting sentiment " file-print [starting-sentiment] of pick-agent

  ;column headers:
  file-print "step,observation,first,therefore,and-then,conflict-narrative,alt-narr,gap,sentiment"

  ;data to print as csv:
  while [[conflict-narrative] of pick-agent > 0]
    [
    step
    file-type numStep file-type ", "
    file-type [observation] of pick-agent file-type ","
    file-type [explanation1] of pick-agent file-type ","
    file-type [explanation2] of pick-agent file-type ","
    file-type [explanation3] of pick-agent file-type ","
    file-type [conflict-narrative] of pick-agent file-type ","
    file-type [alternative-narrative] of pick-agent file-type ","
    file-type [gap] of pick-agent file-type ","
    file-type [sentiment] of pick-agent file-print ","
    if (numStep > maxSteps) [file-close stop]
    ]
  file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
222
10
517
306
-1
-1
7.0
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
ticks
30.0

MONITOR
83
50
220
95
Schelling setup: wait for 0
percent-unhappy
1
1
11

BUTTON
1
55
81
88
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
40
247
103
280
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

BUTTON
108
247
171
280
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

SWITCH
61
10
153
43
schelling?
schelling?
1
1
-1000

SLIDER
21
99
193
132
reduction-factor
reduction-factor
0
.20
0.2
.05
1
NIL
HORIZONTAL

SLIDER
21
137
193
170
conflict-narrative-lvl
conflict-narrative-lvl
5
95
15.0
5
1
NIL
HORIZONTAL

SLIDER
21
173
193
206
consider-alternative
consider-alternative
.05
1
0.16
.01
1
NIL
HORIZONTAL

PLOT
525
166
824
327
Average Narrative Levels
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
"avg-conf-narr" 1.0 0 -16777216 true "" ""
"avg-alt-lvl" 1.0 0 -13791810 true "" ""
"avg-red-conf-narr" 1.0 0 -2674135 true "" ""
"avg-green-conf-narr" 1.0 0 -10899396 true "" ""

PLOT
523
12
763
162
Average Sentiment
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
"all-red" 1.0 0 -2674135 true "" ""
"all-green" 1.0 0 -10899396 true "" ""

MONITOR
709
260
787
305
Average Gap
avg-gap
2
1
11

BUTTON
92
288
179
321
Run Tests
runTests
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
21
210
193
243
num-leaders
num-leaders
0
150
90.0
10
1
NIL
HORIZONTAL

BUTTON
92
325
212
358
Follow an Agent
followAgent
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
14
293
91
349
Export a .csv\nfor further\nanalysis with\nthese buttons:
11
0.0
1

TEXTBOX
21
277
206
295
------------------------------------------
11
0.0
1

MONITOR
525
331
659
376
Remaining Unblue Agents
remaining-red-conflict-narr + remaining-green-conflict-narr
0
1
11

@#$#@#$#@
## WHAT IS IT?

This NetLogo model illustrates a social science model from the field of conflict resolution that explores reconciliation between two populations through the replacement of the conflict narrative and the development of an alternative narrative.

The model uses the classic Schelling segregation model as a visual starting point.

## HOW TO USE IT

Adjust the switch and sliders, and click "setup." If you chose "on" using the Schelling switch, the agents will move around until each is happy -- meaning at least 75 percent of its Moore neighbors within a 2-patch radius are of its own color.  At that point, the "Schelling setup: wait for 0" monitor will say "0."

You now have border agents (circles), leaders (yellow), and other agents. There are equal numbers of red and green agents, and equal leaders of each color.

You can move one tick at a time using the "step" button, or "go" to proceed until 10,000 ticks or the conflict narrative is eliminated (whichever happens first).

As the model proceeds, the "average sentiment" plot will show a line graph of the red agents' average sentiment and the green agents' average sentiment. The "average narrative levels" plot will show a line graph of the average of border agents' alternative narrative level and conflict narrative level, and the conflict narrative level of the red and green border agents separately. The "remaining unblue agents" monitor will show the number of border agents whose conflict narrative has not yet dropped below its original level.

## EXPLANING THE COLORS

Color is the key thing to notice as the model runs. Ordinary red and green agents always stay some shade of red or green, but their brightness varies depending on their sentiment. An red agent with a sentiment of 0 -- the lowest possible sentiment -- will have the brightest possible shade of red, which will appear as white. As its sentiment improves, it will become progressively darker in shade, until it becomes a very dark red. Greens follow the same pattern. Leaders on both sides always appear in yellow, but the shade of yellow follows the same logic.

Border agents begin as ordinary red or green agents in terms of color, but as soon as one's conflict-narrative dips below its original level, it turns gray, shaded in the same way as above. Once its conflict-narrative is completely eliminated, it turns blue. That is why the monitor of agents still maintaining a conflict narrative is called "remaining unblue agents."

## THINGS TO NOTICE

Actions, observations, and calculations of border agents are not shown directly in the model space, but they can be observed for any specific agent via inspection, and the overall effects of slider values on those calculations can be seen in their effects on sentiment, visible in the model space.

For example, the higher the conflict-narrative slider (the worse the original agent sentiment), the more likely that observed actions will be explained through that framework, keeping sentiment levels low.

If the conflict narrative can't explain an observed action, this opens psychological space for positive interpretation, i.e. an alternative narrative. Agents consider this alternative narrative by comparing whether a random value is higher than a given threshold, which is set using the consider-alternative slider threshold. Therefore, the higher the consider-alternative threshold, the stronger the alternative-narrative has to be before the agent settles on it as an explanation for the observed action.

If the agent settles on the alternative narrative as an explanation, its conflict-narrative level drops by a proportion set by the reduction-factor slider. Therefore, the higher the reduction factor, the faster the conflict-narrative will drop.

A leader's sentiment has double the impact of an ordinary agent's sentiment and affects agents in twice the radius of an ordinary agent.

## EXTENDING THE MODEL

1. An extension could include a leader-power slider that varied the power of leaders, rather than having that power remain static.

2. Agents could have a lifespan, live, and die, displaying generational change.

3. Agents could have social networks, broadening the reach of their sentiment-polling beyond their neighbors.

## CREDITS AND REFERENCES

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.

Wilensky, U. (1997).  NetLogo Segregation model. http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT NOTICE

Optional self-segregation set-up: Copyright 1997 Uri Wilensky. All rights reserved.
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
<experiments>
  <experiment name="experiment" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="num-leaders">
      <value value="50"/>
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consider-alternative">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="conflict-narrative-lvl">
      <value value="20"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reduction-factor">
      <value value="0.2"/>
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
