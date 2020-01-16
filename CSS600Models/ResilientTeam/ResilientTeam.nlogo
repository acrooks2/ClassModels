;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Description: Build Agent-Based Model to research small group resilience
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [rnd]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Declare variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; declare global variables (including group/team metrics to be calculated)
globals
[
  a
  b
  G_belief
  G_belongsafe
  G_contribute
  G_engagement
  G_gratitude
  G_resilience
  G_stress
  EG_stress_new
  zipfdist
]

; Declare agent attributes
turtles-own
[
  belief
  belongsafe
  contribute
  hope
  resilience
  strength
  stress
  trusted
  blame_rate
  gratitude_rate
  hope_rate
  listen_rate
  spend_rate
  recovery_rate
  seekhelp_rate
  trust_rate
]

; Declare directed link "relations", and its attributes
directed-link-breed [relations relation]
relations-own
[
  N_blame
  N_feedback
  N_gratitude
  N_interact_rate
  N_recrimination
  N_seekhelp
  N_spend
  N_stress
  N_trust
  D_belief
  D_blame
  D_gratitude
  D_hope
  D_listen
  D_seekhelp
  D_spend
]

; Declare environment (patch) attributes
patches-own
[
  EI_stress
  EG_stress
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; setup procedures
; + declare zipf distribution for event probabilities
; + setup environment (patches)
;; setup agents (turtles)
; + create agents
; + assign agent location (patch coordinates in circle), color, shape
; + initialize default agent attritbute values (in lieu of actual input data, to be done in a future model)
;; setup links
; + create directed links between all agents with attribute --> I am using a breed link... when might I need a breedless link?
;; setup model defaults
; + set default environment values
; + set default link values
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  clear-all ; reset model
  setup-patches
  setup-turtles
  setup-links
  initialize-globals
  reset-ticks ; reset tick counter
end

; setup-patches procedure
to setup-patches
  ask patches [set pcolor black] ; set patch color
  ask patches [initialize_env] ; asigns initial values for environment
end

; setup-turtles procedure
to setup-turtles
  create-turtles numberagents ; create agents based on slider "number-agents" value
  layout-circle sort turtles 10 ; assign agents random location --> show [list xcor ycor] of turtle 0
  ask turtles [set color white] ; assigning agent color
  ask turtles [set shape "face happy"] ; assigning agent shape
  ask turtles [initialize_agents] ; asigns initial values for agent attributes
end

; setup-links procedure
to setup-links
  ; ask links [set family false] ; initiating turtles without links/family members
  ; create directed links (directed link breed = "relations") to all other turtles
  ask turtles [create-relations-to other turtles]
  ask relations [set thickness 0.1]
  ask relations [set color (blue + 2)]
  ask relations [initialize_relations] ; asigns initial values for link (breed = relations) attributes
end

; reset model to default parameters
to restore-defaults
  set numberagents 5
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Inititalization procedures
; + initialize agents
; + initialize environment
; + initialize links
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to  initialize-globals
  ; variable calculations are scaled (variable x into a range [a,b]) as follows:
  ; x_normalized = ((x - min(x)) / (max(x) - min(x))) * (b - a) + a
  set a 1
  set b 7
  ; declare approximate zipf distribution
  set zipfdist [[1 0.818] [2 0.143] [3 0.020] [4 0.010] [5 0.005] [6 0.003] [7 0.001]]
end

; Setup agents with initial values
to initialize_agents
  ; agent attribute and decision variables set on a likert scale: Very Low (1) to Very High (7)
  ; agent rate variables set as percents between 0 (0%) and 1 (100%)
  set belief 4
  set belongsafe 4
  set contribute 4
  set hope 4
  set resilience 4
  set strength 4
  set stress 4
  set trusted 4
  set blame_rate .5
  set gratitude_rate .5
  set hope_rate .5
  set listen_rate .5
  set recovery_rate .5
  set seekhelp_rate .5
  set spend_rate .5
  set trust_rate .5
end

; Setup environment (patches) with initial values
to initialize_env
  ; environment variables set on a likert scale: Very Low (1) to Very High (7)
  ; environment rate_variables set as percents between 0 (0%) and 1 (100%)
  set EI_stress 1
  set EG_stress 1
end

; Setup agent relationships (links) with initial values
to initialize_relations
  ; relations link variables set on a likert scale: Very Low (1) to Very High (7)
  ; relations link rate_variables set as percents between 0 (0%) and 1 (100%)
  ; D_ represent decisions
  ; N_ represent actions
  set D_belief 1
  set D_blame 1
  set D_gratitude 1
  set D_hope 1
  set D_listen 1
  set D_seekhelp 1
  set D_spend 1
  set N_blame 1
  set N_feedback 1
  set N_gratitude 1
  set N_seekhelp 1
  set N_spend 1
  set N_stress 1
  set N_trust 1
  set N_recrimination 1
  set N_interact_rate .5
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; model-go procedures
;; + Update environment with new events
;; + AGENT PERCEIVE ENVIRONMENT
;; + AGENT DECISION MAKING
; Agent goes through several decision procedures and stores decisions into variables
; AGENT decision influenced by interpret of events and neighbors --> positively/negatively/threat/help/etc ?????
; Decision variables are prioritized/deconflicted into specific changes to the agent's internal state
;; - AGENT OUTPUT: INTERNAL STATE
; Agent's attribute values are updated
;; - AGENT OUTPUT: EXTERNAL
; Agent internal attritbutes & decision values processed to determine external actions
; environment attritbute values are updated
;; - TEAM METRICS CALCLUATION
; calculate global values --> team aggregate variables are updated based on agents' end states
; report global values in monitors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; go procedures
to go
  if ticks >= 500 [stop]
  gotick
end

to gotick
  print "===================================="
  type "VALUES @ tick " type (ticks) print ":"
  update_env ; procedure to generate environmental events
  agent_perceive ; procedure for agents to read environment events and update themselves
  agent_decisions ; procedure for agents to input environment and neighbor actions
  agent_change ; procedure for agents to change their own values
  agent_act ; procedure for agents to output actions/behaviors
  tick ; increment tick counter
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; model procedures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Update environment with new events
to update_env
  ; assign environment stress events for individual agent --> Using
  ; Rnd extension with approximate Zipf power law distribution of
  ; stress event intensity
  ask patches [set EI_stress (first rnd:weighted-one-of-list zipfdist [[p] -> last p])]
  ; assign an environment stress event for the group (applied to all agents)
  set EG_stress_new (first rnd:weighted-one-of-list zipfdist [[p] -> last p])
  ask patches [set EG_stress EG_stress_new]
  ;; Variable calculations are scaled (variable x into a range [a,b]).
  ;; Range = [1,7] to match the likert scale.
  ;; Formula: x_normalized = ((x - min(x)) / (max(x) - min(x))) * (b - a) + a
  ; Color patch based on [EI_stress + EG_stress] (value range [2,14]) to color
  ; range [white to red] (color value range [19.9, 15])
  ask patches [set pcolor ((((EI_stress + EG_stress)
    - 2) / (14 - 2)) * (15 - 19.9) + 19.9)]
  type "EG_stress: " type ([precision EG_stress 2] of turtles)
  type ". EI_stress: " type ([precision EI_stress 2] of turtles)
  type ". pcolor = " type ([EI_stress + EG_stress] of patches)
  print "."
end

;; + AGENT PERCEIVE ENVIRONMENT
to agent_perceive
  ;; Variable calculations are scaled (variable x into a range [a,b]).
  ; Range = [1,7] to match the likert scale.
  ;; Formula: x_normalized = ((x - min(x)) / (max(x) - min(x))) * (b - a) + a
  ask turtles [set stress stress + (((([EI_stress] of patch-here + [EG_stress] of patch-here) - 2) / (14 - 2)) * (b - a) + a)]
  ask turtles [set stress (stress / (((resilience - 1) / (7 - 1)) * (2 - 1) + 1))]
  ask turtles [IF (stress > 7) [set stress 7]]
  ask turtles [IF (stress < 1) [set stress 1]]
  ask turtles [set color resilience
    set size stress]

  type "stress: " type ([precision stress 2] of turtles) print "."
end


;; + AGENT DECISION MAKING
; - Agent goes through several decision procedures and stores decisions into variables
; - AGENT decision influenced by interpret of events and neighbors --> positively/negatively/threat/help/etc ?????
; - Decision variables are prioritized/deconflicted into specific changes to the agent's internal state
to agent_decisions
  ;; Variable calculations are scaled (variable x into a range [a,b]). Range = [1,7] to match the likert scale.
  ;; Formula: x_normalized = ((x - min(x)) / (max(x) - min(x))) * (b - a) + a
  ; set D_listen: Agents decide to what degree they will listen to their neighbors: Check if neighbor has feedback, calculate listening based on turtle attributes --> ; OLD: ask turtles [ask my-in-relations [set D_listen (([listen_rate] of myself * (([resilience] of myself + [belongsafe] of myself - [stress] of myself ) / 2))]]
  ask turtles
  [ask my-in-relations
    [set D_listen (((([listen_rate] of myself * (([resilience] of myself + [belongsafe] of myself - [stress] of myself ) / 2)) - 0) / (13 - 0)) * (b - a) + a)]
  ]
  ; set D_seekhelp: Agents decide if they need help, and their willingness to ask a neighbor for help: Check if they will consider asking for help, then update the inward link attribute "D_seekhelp" based on agent and link values
  ask relations
  [IFELSE (([belief] of end2 > 1) and ([belongsafe] of end2 >= N_trust) and ([stress] of end2 > 1))
    [set D_seekhelp (((([seekhelp_rate] of end2 * ((N_trust + [belongsafe] of end2 + [stress] of end2))) - 0) / (21 - 0)) * (b - a) + a)]
    [set D_seekhelp 1]
  ]
  ; set D_blame: Agents sed D_blame (probability to blame another agent) based on their stress and respective trusted levels.
  ; Note: the commented out code for adjusting blame_rate, which caused undesirable behavior
  ask relations [IFELSE (([stress] of end1 > 2) and ([trusted] of end1 >= [trusted] of end2))
    [set D_blame (((([blame_rate] of end1 * ((8 - [belongsafe] of end1) + ([stress] of end1) + (8 - N_trust ))) - 0) / (21 - 0)) * (b - a) + a)
      ;IFELSE (N_trust >= 2)
      ;[set N_trust (N_trust - 1)]
      ;[set N_trust 1]
      ;ask end1 [IF (blame_rate <= 0.99) [set blame_rate (blame_rate + 0.01)]]
    ]
    [set D_blame 1
      ;ask end1 [IF (blame_rate >= 0.01) [set blame_rate (blame_rate - 0.01)]]
    ]
  ]
  ; set D_spend
  ask relations [set D_spend ((([spend_rate] of end1 * (N_seekhelp + [resilience] of end1 + [belongsafe] of end1) - 0) / (21 - 0)) * (b - a) + a)]

  type "spend_rate: " type ([precision spend_rate 2] of turtles) print "."
  type "strength: " type ([precision strength 2] of turtles) print "."
  type "resilience: " type ([precision resilience 2] of turtles) print "."
  type "D_listen: " type ([precision D_listen 2] of relations) print "."
  type "D_seekhelp: " type ([precision D_seekhelp 2] of relations) print "."
  type "D_blame: " type ([precision D_blame 2] of relations) print "."
  type "D_spend: " type ([precision D_spend 2] of relations) print "."
  type "blame_rate: " type ([precision blame_rate 2] of turtles) print "."
  type "N_trust: " type ([precision N_trust 2] of relations) print "."

  ;ask relations [set thickness (D_blame)]

end

;; - AGENT OUTPUT: INTERNAL STATE
to agent_change ; procedure for agents to change their own values
  ;; Variable calculations are scaled (variable x into a range [a,b]). Range = [1,7] to match the likert scale.
  ;; Formula: x_normalized = ((x - min(x)) / (max(x) - min(x))) * (b - a) + a
  ask turtles [set trusted (mean [N_trust] of my-in-relations)]
  ask turtles [set belongsafe (((((mean [D_seekhelp] of my-in-relations) + ((8 - (mean [D_blame] of my-in-relations)) * 3)) - 4) / (28 - 4)) * (b - a) + a)]
  ;ask turtles [set resilience (resilience + ((mean [D_spend] of my-relations) - ([EI_stress] of patch-here)))]
  ;ask turtles [IF (resilience > 7) [set resilience 7]]
  ;ask turtles [IF (resilience < 1) [set resilience 1]]

  type "trusted: " type ([precision trusted 2] of turtles) print "."
  type "belongsafe: " type ([precision belongsafe 2] of turtles) print "."
  type "resilience: " type ([precision resilience 2] of turtles) print "."

end

;; - AGENT OUTPUT: EXTERNAL
to agent_act ; procedure for agents to output actions/behaviors
  ask relations [set N_seekhelp 1]
  ask turtles [ask (max-one-of my-out-relations [D_seekhelp]) [set N_seekhelp 7] ]

  type "N_seekhelp: " type ([precision N_seekhelp 2] of relations) print "."
  type "N_blame: " type ([precision N_blame 2] of relations) print "."
  type "N_spend: " type ([precision N_spend 2] of relations) print "."
  type "N_feedback: " type ([precision N_feedback 2] of relations) print "."
end
@#$#@#$#@
GRAPHICS-WINDOW
24
93
461
531
-1
-1
13.0
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
87
30
154
63
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
160
30
223
63
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
0

SLIDER
325
33
499
66
numberagents
numberagents
3
10
5.0
1
1
NIL
HORIZONTAL

BUTTON
18
30
83
63
reset
restore-defaults
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
231
30
309
63
go 1 tick
gotick
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
475
94
739
244
Stressors
time
value
0.0
10.0
1.0
7.0
true
true
"" ""
PENS
"Avg EG_stress" 1.0 0 -2674135 true "" "plot (mean [eg_stress] of patches)"
"Avg EI_stress" 1.0 0 -11033397 true "" "plot (mean [ei_stress] of patches)"

PLOT
475
246
733
396
D_listen
time
value
0.0
10.0
1.0
7.0
true
true
"" ""
PENS
"Avg D_listen" 1.0 0 -16777216 true "" "plot (mean [D_listen] of relations)"
"Min D_listen" 1.0 0 -7500403 true "" "plot (min [D_listen] of relations)"
"Max D_listen" 1.0 0 -2674135 true "" "plot (max [D_listen] of relations)"
"Avg Stress" 1.0 0 -1184463 true "" "plot (mean [stress] of turtles)"
"Avg D_blame" 1.0 0 -955883 true "" "plot (mean [D_blame] of relations)"

PLOT
475
398
748
548
D_seekhelp
time
value
0.0
10.0
1.0
7.0
true
true
"" ""
PENS
"Avg D_seekhelp" 1.0 0 -16777216 true "" "plot mean [D_seekhelp] of relations"
"Avg N_trust" 1.0 0 -7500403 true "" "plot mean [N_trust] of relations"
"Avg belongsafe" 1.0 0 -2674135 true "" "plot mean [belongsafe] of turtles"
"Avg N_seekhelp" 1.0 0 -955883 true "" "plot mean [N_seekhelp] of relations"

@#$#@#$#@
## WHAT IS IT?

This agent-based simulation models resilience of small teams. This model emphasizes the individual attributes and behaviors in generating small team interactions that promote resilience.  

## HOW IT WORKS

Stress events are generated in the environment. Individuals perceive their environment, update their attributes, go through a series of decisions, and take actions to update themselves and their relationships.

## HOW TO USE IT

1. Adjust the slider parameters (seel below), or use the default settings.
2. Press the SETUP button.
3. Press the GO button to begin the simulation.  The simulation will run for 500 ticks.
4. Look at the monitors and console output to see information about the agents (individuals, relationships, and environment). 

Parameters: 
numberagents: The team size . 

Monitors and console output show various agent values each tick. 

The model will continue running until 500 ticks pass.

## THINGS TO NOTICE

Notice how the icon size changes to reflect the total stress value in the patch under the individual.

## THINGS TO TRY

The model experimentation studies the formulas used to model individual decisions, interactions, and changes to attributes.  

Try adjusting the parameters to see how attribute values change.


## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)
Try adjusting the formulas in the model for a given attribute, and see how it impacts the other attritbutes. 

## NETLOGO FEATURES

Patches are used to model the environment

## RELATED MODELS

Look at Giannoccaro for a different approach to modeling team resilience.

## CREDITS AND REFERENCES

Giannoccaro, I., Massari, G. F., and Carbone, G., “Team Resilience in Complex and Turbulent Environments: The Effect of Size and Density of Social Interactions,” Complexity, vol. 2018, Article ID 1923216, 11 pages, 2018. https://doi.org/10.1155/2018/1923216
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
<experiments>
  <experiment name="experiment-test" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles</metric>
    <metric>([precision EG_stress 2] of turtles)</metric>
    <metric>([precision EI_stress 2] of turtles)</metric>
    <metric>([EI_stress + EG_stress] of patches)</metric>
    <metric>([precision stress 2] of turtles)</metric>
    <metric>([precision spend_rate 2] of turtles)</metric>
    <metric>([precision strength 2] of turtles)</metric>
    <metric>([precision resilience 2] of turtles)</metric>
    <metric>([precision D_listen 2] of relations)</metric>
    <metric>([precision D_seekhelp 2] of relations)</metric>
    <metric>([precision D_blame 2] of relations)</metric>
    <metric>([precision D_spend 2] of relations)</metric>
    <metric>([precision blame_rate 2] of turtles)</metric>
    <metric>([precision N_trust 2] of relations)</metric>
    <steppedValueSet variable="numberagents" first="3" step="1" last="10"/>
  </experiment>
  <experiment name="experiment_v2" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>min([precision EG_stress 2] of turtles)</metric>
    <metric>mean([precision EG_stress 2] of turtles)</metric>
    <metric>max([precision EG_stress 2] of turtles)</metric>
    <metric>min([precision EI_stress 2] of turtles)</metric>
    <metric>mean([precision EI_stress 2] of turtles)</metric>
    <metric>max([precision EI_stress 2] of turtles)</metric>
    <metric>min([EI_stress + EG_stress] of patches)</metric>
    <metric>mean([EI_stress + EG_stress] of patches)</metric>
    <metric>max([EI_stress + EG_stress] of patches)</metric>
    <metric>min([precision stress 2] of turtles)</metric>
    <metric>mean([precision stress 2] of turtles)</metric>
    <metric>max([precision stress 2] of turtles)</metric>
    <metric>min([precision spend_rate 2] of turtles)</metric>
    <metric>mean([precision spend_rate 2] of turtles)</metric>
    <metric>max([precision spend_rate 2] of turtles)</metric>
    <metric>min([precision strength 2] of turtles)</metric>
    <metric>mean([precision strength 2] of turtles)</metric>
    <metric>max([precision strength 2] of turtles)</metric>
    <metric>min([precision resilience 2] of turtles)</metric>
    <metric>mean([precision resilience 2] of turtles)</metric>
    <metric>max([precision resilience 2] of turtles)</metric>
    <metric>min([precision D_listen 2] of relations)</metric>
    <metric>mean([precision D_listen 2] of relations)</metric>
    <metric>max([precision D_listen 2] of relations)</metric>
    <metric>min([precision D_seekhelp 2] of relations)</metric>
    <metric>mean([precision D_seekhelp 2] of relations)</metric>
    <metric>max([precision D_seekhelp 2] of relations)</metric>
    <metric>min([precision D_blame 2] of relations)</metric>
    <metric>mean([precision D_blame 2] of relations)</metric>
    <metric>max([precision D_blame 2] of relations)</metric>
    <metric>min([precision D_spend 2] of relations)</metric>
    <metric>mean([precision D_spend 2] of relations)</metric>
    <metric>max([precision D_spend 2] of relations)</metric>
    <metric>min([precision blame_rate 2] of turtles)</metric>
    <metric>mean([precision blame_rate 2] of turtles)</metric>
    <metric>max([precision blame_rate 2] of turtles)</metric>
    <metric>min([precision N_trust 2] of relations)</metric>
    <metric>mean([precision N_trust 2] of relations)</metric>
    <metric>max([precision N_trust 2] of relations)</metric>
    <steppedValueSet variable="numberagents" first="3" step="1" last="10"/>
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
