;
;================================
;
; Global variables on interface
; tax-rate             - the rate at which agents are taxed on their actual income
; penalty-rate         - the rate at which agents are penalized based on their actual income
; audit-prob           - the objective probability of audit
; apprehension-rate    - the objective rate of apprehension
; dishonest            - the number of agents who are dishonest
; honest               - the number of agents who are honest
; audit-max            - ???
; apprehension?        - a boolean to turn on the apprehension method adapted from the Korobow model
; edges                - in the Erdos-Renyi networks, how many links connect agents to each other
; small-worlds-random  - in the Small Worlds networks, the probability of an edge being rewired to another node
; typeNetwork          - the types of networks tested: von Neumann, Moore, Erdos-Renyi, Ringworld, Power Law,
;                        Small Worlds, and no network.
;
;-----------


globals [
  audit-random     ;; a random float, used to determine if a tax evader is being audited
  VMTR             ;; the primary metric of the simulation, Voluntary Mean Tax Rate
  i                ;; an increment marker, used in developing networks
  j                ;; an increment marker, used in developing the Power Law networks
  y                ;; an increment marker, used in developing the Power Law networks
  delta            ;; a parameter in the Power Law
  gamma            ;; a parameter in the Power Law
  bins             ;; the maximum number of links stemming from one node in the Power Law networks
  scale            ;; a parameter in the Power Law
  sigma            ;; a parameter in the Log Normal
  mu               ;; a parameter in the Log Normal
  exponent         ;; a transitory variable in the Log Normal Network
  ]
turtles-own [
  class            ;; a variable which separates agents into honest, dishonest, and imitating
  declared         ;; the amount of income an agent declares
  actual           ;; the amount of income an agent actually has
  ps               ;; subjective audit probability
  risk             ;; risk aversion of each agent
  audit-count      ;; sets ticks since the last audit to 0
  lower-bound      ;; lowest number an agent's subjective probability of auditing would need to
                    ; be in order to declare any income at all
  myApprehension?  ;; a flag to determine if the agent has been apprehended or not
  ]

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches [sprout 1] ;; Set up one turtle on each patch
  ask turtles
  [
    set class 2          ;; The default "class" of turtle is the imitator
    set color blue
  ]
  ask n-of dishonest turtles
  [
    set class 1          ;; there will be 'dishonest' number of income maximizing agents
    set color red
  ]
  ask n-of honest turtles
  [
    set class 3          ;; there will also be 'honest' number of honest agents
    set color green
  ]

  ask turtles [
    set ps random-float 1       ;; define the initial subjective probability of an audit
    set actual random 100 + 1   ;; defines each agents actual income
    set risk random-float 1     ;; defines the risk aversion for each agent
    set audit-count 0           ;; sets the ticks since the last audit to zero
  ]


  ;; types of networks to use when running BehaviorSpace
  if typeNetwork = "Moore" [setupMoore]
  if typeNetwork = "vonNeumann" [setupVonNeumann]
  if typeNetwork = "Ringworld" [setupRingworld]
  if typeNetwork = "Small-Worlds" [setupSmallWorlds]
  if typeNetwork = "Erdos-Renyi" [setupErdosRenyi]
  if typeNetwork = "NoNetwork" [setupNoNetwork]
  if typeNetwork = "Power Law" [setupPowerLaw]
end

to setupRingworld
  ;; This function sets up a network of ring world, where turtle i is connected
  ;; to turtles {1-2, i-1, i+1, i+2}
  clear-links
  set i 0
  while [i < count turtles]
  [
    ask turtle i
    [
      ifelse i = (count turtles - 1)
      [
        create-link-with turtle 1
        create-link-with turtle 0
      ]
      [
        ifelse i = (count turtles - 2)
        [
          create-link-with turtle 0
          create-link-with turtle (i + 1)
        ]
        [
          create-link-with turtle (i + 1)
          create-link-with turtle (i + 2)
        ]
      ]
      ;; Order the turtles, to clean up the link network
      setxy (i mod world-width) (i / world-width)
    ]
    set i (i + 1)
  ]
end

to setupNoNetwork
  ;; This "network" is created by killing all the links. All networks begin by clearing the previous network
  clear-links
end

to setupVonNeumann
  ;; This function sets up a network where each agent is connected to their Von Neumann neighbors (8)
  clear-links
  ask turtles
  [
    create-links-with turtles-on neighbors4
  ]
end

to setupMoore
  ;; This function sets up a network where each agent is connected to their Moore neighbors (4)
  clear-links
  ask turtles
  [
    create-links-with turtles-on neighbors
  ]
end

to setupErdosRenyi
  ;; This function sets up an approximate Erdos-Renyi network, where agents are selected at random
  ;; and create links with other randomly selected agents, until all edges have been created
  clear-links
  set i 0
  while [i < edges]
  [
    ask one-of turtles
    [
      create-link-with one-of other turtles
    ]
    set i ( i + 1 )
  ]
end

to setupSmallWorlds
  ;; This function is very similar to Ringworld. However, the function will first randomly assign
  ;; a certain percentage (small-worlds-random) of agents to create random links, via the Erdos-Renyi method
  clear-links
  set i 0
  while [i < count turtles]
  [
    ask turtle i
    [
      ifelse (random 100 <= small-worlds-random)
      [
        create-links-with n-of 2 other turtles
      ]
      [
      ifelse i = (count turtles - 1)
      [
        create-link-with turtle 1
        create-link-with turtle 0
      ]
      [
        ifelse i = (count turtles - 2)
        [
          create-link-with turtle 0
          create-link-with turtle (i + 1)
        ]
        [
          create-link-with turtle (i + 1)
          create-link-with turtle (i + 2)
        ]
      ]
    ]
      ;; Order the turtles, to clean up the link network
      setxy (i mod world-width) (i / world-width)
    set i (i + 1)
  ]
  ]
end

to setupPowerLaw
  ;; This function sets up a power law, scale-free network.
  clear-links
  set bins 16.0       ;; The number of bins. No node will have more than 16 links.
  set gamma -2.1      ;; The gamma, usually set between -2 and -3
  set i 1.0
  set delta ( 1.4 / bins )
  set scale 1.0
  while [i < bins]    ;; incrementing i shows the number of links that certain nodes will get
  [
    set y ( scale * i * delta ) ^ gamma  ;; Sets the number of nodes: y nodes will have i links
    set j 0
    while [j <= y]
    [
      ask one-of turtles with [count my-links = 0][
        create-links-with n-of i other turtles  ;; links y nodes to i other nodes
      ]
      set j (j + 1)
    ]
    set i (i + 1)
  ]
end


;; Lognormal network will be tested in another model.

;to setupLogNormal
;  ;; This function sets up a log normal network.
;  clear-links
;  set sigma -2.1      ;; The sigma, usually set between -2 and -3
;  set i 1.0
;  set exponent 0.0
;  while [any? turtles with [count my-links = 0] ]    ;; incrementing i shows the number of links that certain nodes will get
;  [
;    set exponent ( - ( ( ln ( i ) ^ 2.0) / ( 2.0 * sigma ^ 2.0 ) ) )
;    set y (exp exponent) / (1 * sqrt (2.0 * pi * (sigma ^ 2.0)))  ;; Sets the number of nodes: y nodes will have i links
;    set j 0
;    while [j <= y]
;    [
;      ask one-of turtles with [count my-links = 0][
;        create-links-with n-of i other turtles  ;; links y nodes to i other nodes
;      ]
;      set j (j + 1)
;    ]
;    show y
;    set i (i + 1)
;  ]
;end


to declare
  ask turtles [
    if class = 1 [
      ;; If an agent is income maximizing, they will do their best to avoid paying taxes whenever possible
      ;; The lower-bound is the lowest number their subjective probability of auditing would need to be in order to declare any income at all
      set lower-bound ( tax-rate / ( tax-rate + ( penalty-rate - tax-rate ) * exp ( risk * penalty-rate * actual ) ) )
      ifelse ps < lower-bound [ set declared 0 ]      ;; If the subjective probability is lower than the lower-bound, their declared income becomes 0
      [
        ifelse penalty-rate * ps > tax-rate [ set declared actual ] ;; If their subjective probability is high enough, their will not risk audit and declare their full amount
        [
          ;; If it is in a medium ground, however, they will declare some fraction of their actual income
          set declared actual - ( ln ( abs ( ( (1.0 - ps) * tax-rate ) / ( ps * ( -1 * tax-rate + penalty-rate ) ) ) / ( risk * penalty-rate ) ) )
        ]
      ]
    ]
    if class = 2 [
      ;; If the node has no links, the agent will act honestly and declare his full income
      ifelse (count my-links = 0)
      [ set declared actual ]
      [
        ;; The agent will set their declared as an average ratio of what other agents are doing around him
        ;; If the average ratio is half of their actual becomes declared, then this agent will declare half of his income
        set declared ( 1.0 / count my-links ) * (sum [declared / actual] of link-neighbors) * actual
        ;; If this agent was audited in recent memory, they will have an audit-count that prohibits them from being dishonest for a specific amount of ticks
        if audit-count > 0 [ set declared actual ]
      ]
    ]
    if class = 3 [
      ;; Class 3 are honest taxpayers, whose declared income is always their actual income
      set declared actual
    ]
    ;; if class = 4 [
      ;; Class 4 are confused taxpayers, whose declared income are normally distributed around the actual income
      ;; Note that this is NOT a class that is currently implemented in the current model
      ;; set declared random-normal actual ( tax-complexity * actual )
      ;; if audit-count > 0 [ set declared actual ]
    ;;]
  ]
end

to audit
  ask turtles [
    ;; If the agent was audited in recent memory, continue to reduce their audit-count until it returns to 0
    if audit-count > 0 [
      set audit-count audit-count - 1
    ]
    ;; As an agent continues to avoid audit, they will reduce their subjective probability of an audit
    if ps > audit-prob [ set ps ps - 0.2 ]
    if ps < audit-prob [ set ps audit-prob ]
    ;; Korobow model heuristic. If agents are apprehended and their declared income and actual income are
    ;; not equal, their subjective probability of audit increases and they are fined.
    ifelse apprehension? = true [
      if random-float 1 < apprehension-rate [
        ifelse declared < actual [
          set myApprehension? true
          set declared (tax-rate * (actual - declared) * ( 1.0 + penalty-rate * actual ) )
          set ps 1.0]
        [set myApprehension? false]
      ]
    ]
    ;; Hokamp penalty equation. If agents are audited, they are subjected to a penalty
    [
      if declared < actual [
        set audit-random random-float 1
        if audit-random <= audit-prob [
          set declared (actual + declared * penalty-rate / tax-rate)
          ;; The agent's audit-count goes to the maximum possible value
          set audit-count audit-max
          ;; The agent's subjective probability of an audit, naturally, goes to 1.0
          set ps 1.0
        ]
      ]
    ]
  ]
end

to go
  declare
  audit
  update-plot
  if ticks = 40 [stop]
  tick
end

to update-plot
  set-current-plot "Voluntary Mean Tax Rate"
  ;; Plots the Voluntary Mean Tax Rate, or VMTR, as a ratio of declared over actual, times the tax rate
  set VMTR ( ( sum [declared] of turtles ) / ( sum [actual] of turtles ) ) * tax-rate
  set-current-plot-pen "VMTR"
  plot VMTR

  set-current-plot "Subjective Audit Probability of Agents"
  ;; This graph plots the subjective probability of audit across agents
  set-current-plot-pen "ps"
  histogram [ps] of turtles

  set-current-plot "Audit and Declared"
  ;; This graph plots how much income an agent declares in relation to its subjective audit probability
  clear-plot
  set-current-plot-pen "default"
  ask turtles [plotxy ps declared]

  set-current-plot "Declared and Actual"
  ;; This plots the position of an agent with respect to its actual and declared income. Agents who are
  ;; reporting all of their income should be points on the line y = x. Agents to the left of this line
  ;; are underreporting or not reporting any of these taxes. Agents to the right of this line are reporting
  ;; more than their actual income.
  clear-plot
  set-current-plot-pen "default"
  ask turtles [plotxy declared actual]


end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
20.43
1
10
1
1
1
0
1
1
1
-10
10
-10
10
0
0
1
ticks
30.0

SLIDER
20
160
192
193
dishonest
dishonest
0
50
50.0
1
1
NIL
HORIZONTAL

SLIDER
20
90
192
123
audit-prob
audit-prob
0
0.10
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
20
20
192
53
tax-rate
tax-rate
0
0.40
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
20
55
192
88
penalty-rate
penalty-rate
0
0.50
0.5
0.05
1
NIL
HORIZONTAL

PLOT
5
260
205
410
Voluntary Mean Tax Rate
Years
Voluntary Mean Tax Rate
0.0
40.0
0.0
0.5
true
false
"" ""
PENS
"VMTR" 1.0 0 -16777216 true "" ""

BUTTON
660
15
723
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
660
50
723
83
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
65
415
205
448
audit-max
audit-max
0
10
10.0
1
1
years
HORIZONTAL

PLOT
655
320
855
470
Subjective Audit Probability of Agents
Subjective Prob of Audit
# of Agents
0.0
1.0
0.0
1.0
true
false
"" ""
PENS
"ps" 0.05 1 -16777216 true "" ""

BUTTON
660
85
723
118
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

PLOT
655
165
855
315
Audit and Declared
Subjective Prob of Audit
Declared Income
0.0
1.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

SLIDER
20
125
190
158
apprehension-rate
apprehension-rate
0
1
0.02
0.02
1
NIL
HORIZONTAL

SWITCH
660
120
792
153
apprehension?
apprehension?
0
1
-1000

PLOT
860
165
1060
315
Declared and Actual
Declared Income
Actual Income
0.0
200.0
0.0
200.0
false
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

SLIDER
20
195
192
228
honest
honest
0
50
50.0
1
1
NIL
HORIZONTAL

BUTTON
740
15
822
48
Ringworld
setupRingworld
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
740
50
847
83
Von Neumann
setupVonNeumann
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
740
85
802
118
Moore
setupMoore
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
795
120
915
153
edges
edges
100
1000
400.0
100
1
NIL
HORIZONTAL

BUTTON
855
15
952
48
Erdos-Renyi
setupErdosRenyi
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
917
120
1057
153
small-worlds-random
small-worlds-random
0
100
10.0
1
1
%
HORIZONTAL

BUTTON
855
50
952
83
Small Worlds
setupSmallWorlds
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
860
320
998
365
typeNetwork
typeNetwork
"Ringworld" "vonNeumann" "Moore" "Erdos-Renyi" "Small-Worlds" "NoNetwork" "Power Law"
2

MONITOR
860
425
957
470
# Apprehended
count turtles with [myApprehension? = true]
17
1
11

MONITOR
5
415
62
460
VMTR
VMTR
4
1
11

BUTTON
855
85
947
118
Power Law
setupPowerLaw
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model depicts the dispersion and effects of tax evasion across a variety of networks. While there are a few agents who are always honest or dishonest, a majority of the agents imitate the evasion behavior of those agents they are connected to. This model looks at the effects of these networks to determine any similarities or differences in the evasion metrics.

## HOW IT WORKS

There are three types of agents in this model. An honest agent will always declare his or her actual income, so declared = actual. A dishonest agent will, whenever possible, declare the lowest income they believe they can get away with, as determined by their risk aversion and their subjective probability of audit (which is different from the objective probability of audit).

The third type of agent is the imitating agent, which is the default type. These agents will imitate the behavior of those agents they are connected to. Therefore, if agents next to them are being dishonest, they will also try to be dishonest. These agents will take the average ratio of declared / actual income from all of the agents they are connected to, and apply it to their own declared income. This also means that they can be audited if they are not declaring their full income.

The agents are connected by a type of network, defined in the initialization. The networks are as follows:

Ringworld: each agent is connected to the two agents on either side (four total)
Moore: each agent is connected to the eight agents in each direction
Von Neumann: similar to the Von Neumann, but only four directions
Erdos-Renyi: agents make connections randomly, up to a certain number of edges
Small Worlds: similar to Ringworld, but reconnecting with a certain probability a certain number of links randomly
Power Law: agents create a power-law distributed scale-free network

The default network is "no network" meaning all the agents are in isolation. This network was also tested for effects on tax compliance.

The environment that the agents operate in is depicted on the left side of the display panel. The parameters are defined as follows:

tax-rate: the basic tax-rate over all agents
penalty-rate: how much of their actual income an agent must pay if they are audited
audit-rate: the objective rate of audit (if apprehension? is off)
apprehension-rate: the objective rate of apprehension (if apprehension? is on)
dishonest: the number of dishonest agents (from above)
honest: the number of honest agents (from above)

Each agent owns a subjective probability of audit, ps, which eventually converges with the objective probability of audit. However, if they get audited in one period, their subjective probability rises to 100%, and they are much more likely to declare their actual income as a result. As they go more periods without being audited, however, their subjective probability eventually reduces to the objective probability.

## HOW TO USE IT

First, set the parameters of the environment (tax-rate, penalty-rate, etc). Then, press setup, and multiple agents will appear on the screen. For reference, red agents are dishonest, green agents are honest, and blue agents are imitating their neighbors.

Then, click the button for the network you would like to try. As each is selected, the links appear in grey between the different agents. When you would like to run the simulation, select Go, and the simulation will run through 40 ticks.

## THINGS TO NOTICE

As the first few ticks proceed, notice that the Voluntary Mean Tax Rate (VMTR) is significantly different than the actual tax-rate, depending on the apprehension/audit rate you defined. As this "initialization" ends, the VMTR begins to level out, as a steady state emerges across the population.

Notice also that the declared vs. actual incomes tend to converge into a line with a slope of 1. This is agents acting honest and declaring their full income. Those that are above the line are evading taxes, while those below this line are apprehended agents that are now paying a penalty.

## THINGS TO TRY

Try experimenting with different networks. The only difference between any other the networks is which agents each agent looks at -- the behaviors of the agents are exactly the same in all networks. You will see that the metrics that arise from the different networks show a significant difference, showing how important the network structure is to the overall simulation behavior.

Also try experimenting with the apprehension rate. Real rates in the IRS are around 2%. What would happen if law authorities increased their levels of enforcement?

## EXTENDING THE MODEL

One aspect of the Hokamp and Pickhardt original model that was not developed in this model was the aspect of a time lapse. When they are audited, agents pay penalties not only on the period they were audited in, but on the ten years previous. This influences the behaviors of the agents considerably in the Hokamp & Pickhardt model, and it would be interesting to see if we arrive at the same results in this model.

One, more cosmetic, extension of the model would be to make the agents change color from red to green as they choose to engage in tax evasion.

## NETLOGO FEATURES

This model clearly uses networks fairly heavily, and the developers required a number of "work arounds" in order to properly implement the networks. The code would have been much simpler if some template networks were available within NetLogo, instead of manually creating links.

## CREDITS AND REFERENCES

Andreoni, J., Erard, B., Feinstein, J. (1998). Tax compliance. Journal of Economic Literature, 36(2), pp. 818-860.

Andriani, P. & McKelvey, B. (2007). Beyond Gaussian averages: Redirecting organization science toward extreme events and power laws. Journal of International Business Studies, 38, pp. 1212-1230.

Bloomquist, K. M. (2006). A comparison of agent-based models of income tax evasion, Social Science Computer Review, 24 (4), pp. 411-425.

Boccaletti, S., Latora, V., Moreno, Y., et al. (2006). Complex networks: Structure and dynamics. Physics Reports, 424. Pp. 175-308.

Hokamp, S. & Pickhardt, M. (2010). Income tax evasion in a society of heterogeneous agents � Evidence from an agent-based model. International Economic Journal, 24 (4), pp. 541-553.

Korobow, A., Johnson, C. & Axtell, R. (2007). An agent-based model of tax compliance with social networks. National Tax Journal, 60 (3), pp. 589-610.

Newman, M.E.J. (2003). The structure and function of complex networks. SIAM Review, 45, pp. 167-256.

Watts, D. J. (1999). Networks, Dynamics, and the Small-World Phenomenon. American Journal of Sociology, 105(2), pp. 493-527.

Watts, D.J. and Strogatz. "Collective Dynamics of 'Small-Worlds' Networks". Nature, 1998.

Weisstein, E.W. Moore Neighborhood. From MathWorld�A Wolfram Web Resource. http://mathworld.wolfram.com/MooreNeighborhood.html

Weisstein, Eric W. "von Neumann Neighborhood." From MathWorld--A Wolfram Web Resource. http://mathworld.wolfram.com/vonNeumannNeighborhood.html
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
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles with [myApprehension? = true]</metric>
    <metric>VMTR</metric>
    <steppedValueSet variable="tax-rate" first="0.1" step="0.05" last="0.3"/>
    <enumeratedValueSet variable="honest">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="audit-prob">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="edges">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="audit-max">
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="penalty-rate" first="0.3" step="0.05" last="0.5"/>
    <steppedValueSet variable="apprehension-rate" first="0" step="0.02" last="0.1"/>
    <enumeratedValueSet variable="apprehension?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="small-worlds-random">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="typeNetwork">
      <value value="&quot;NoNetwork&quot;"/>
      <value value="&quot;Ringworld&quot;"/>
      <value value="&quot;vonNeumann&quot;"/>
      <value value="&quot;Moore&quot;"/>
      <value value="&quot;Erdos-Renyi&quot;"/>
      <value value="&quot;Small-World&quot;"/>
      <value value="&quot;PowerLaw&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dishonest">
      <value value="50"/>
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
1
@#$#@#$#@
