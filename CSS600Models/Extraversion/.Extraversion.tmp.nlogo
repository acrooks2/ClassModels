globals [
  MAX-BASIC-NEEDS
  MIN-BASIC-NEEDS
  total-resource-level
  avg-high-resources
  avg-med-resources
  avg-low-resources
  high-links
  med-links
  low-links
  avg-high-links
  avg-med-links
  avg-low-links
]

turtles-own [
  age                      ; how old a turtle is
  life-expectancy          ; maximum age that a turtle can reach
  resource-level           ; level of resources on the patch: (min-0 max 80) also the resources a turtle is born with
  extraversion-level       ; Low, Med, High levels of extraction - agents with higher extraversion level have greater chance of exchanging resources
  matches                  ; list of the id of turtles that each turtle has encountered
  matched?                 ; has the turtle already matched
  move-likelihood          ; probability of an agent to move based on resource level
  exchange-likelihood      ; probability of an agent making an exchange of resources based on extraversion-level
  num-links                ; the number of links an individual turtle has
]

patches-own [
  basic-needs-surface      ;amount of resources on this patch
  max-basic-needs-surface  ;maximum amount of resources on this patch
  gain-value               ;amount of resources that moving turtles can gain
]

;Setup Procedures

to setup
  clear-all
  setup-globals
  setup-patches
  setup-turtles
  reset-ticks
end

to setup-globals
  set MAX-BASIC-NEEDS 80   ;the maximum resource level available on the patch
  set MIN-BASIC-NEEDS 0    ;the minimum resource level available on a patch
end


to setup-patches                    ;changes the depth of the patches in a manner that reflects the distribution of resources
  let satisfied-range               ;initialize the resource level on each patch randomly
  MAX-BASIC-NEEDS - MIN-BASIC-NEEDS ;ranges between 0 to 80.
  ask patches [
    set basic-needs-surface
    (MIN-BASIC-NEEDS + random ( satisfied-range ) )
  ]
  ; now smooth the values for a gradient of the distribution
  repeat 2 [
    ask patches [
      set basic-needs-surface mean
      [basic-needs-surface] of neighbors
      ]
    ]
  colorize-patches
  ask patches [set gain-value basic-needs-surface / 10] ;every turtle gains one tenth of resource level the patch
end

to colorize-patches
ask patches [
  set pcolor scale-color
  gray basic-needs-surface         ;darker patches have greater level resources compared to lighter patches
  MAX-BASIC-NEEDS MIN-BASIC-NEEDS
]
end

to setup-turtles ;;turtle procedure
   create-turtles number [ setxy random-xcor random-ycor
   set resource-level random-normal basic-needs-surface 5 ;patches are given a layer of agents with the same level of resource that the patch holds given to the new turtle
   set extraversion-level one-of ["Low" "Med" "High"]
    if extraversion-level = "High" [set color 12 set exchange-likelihood random-normal  Exchange_Likelihood 5]          ;the higher extraverted agents will have an Exchange_Likelihood parameter give or take 5, which is the maximimum possible value
    if extraversion-level = "Med"  [set color 15 set exchange-likelihood random-normal (Exchange_Likelihood * 0.75) 5]  ;the medium range extraverted agents will have an 75% of Exchange_Likelihood parameter give or take 5
    if extraversion-level = "Low"  [set color 18 set exchange-likelihood random-normal (Exchange_Likelihood * 0.5) 5]   ;;the lower range extraverted agents will have an 50% of Exchange_Likelihood parameter give or take 5, which is the minumum possible value
   set age 0
   set life-expectancy random-normal Life_Expectancy 10   ;agents will have a life span of the parameter Life_expectancy give or take 10
   set matches []
   set matched? false
   set num-links 0
   face one-of neighbors4] ;each turtle turns towards neighbouring four patches
end

;;Runtime Procedures

to go
  if ticks >= 40 [stop]
  ask turtles [move]
  find-match
  gain-resources
  kill-turtles
  update-globals
  tick

end

to move              ;consider moving to unoccupied patches towards nearest neighbours
  move-to one-of neighbors
end

to find-match        ;consider matching with another turtle
  ask turtles [ifelse matched? = false and any? turtles in-radius 3 with [matched? = false] [Match] [move]] ;if it has not been matched, it looks around to find turtles not matched in radius 3. If they're all matched, the turtle moves.
  ask turtles [ask my-links [ifelse [resource-level] of other-end <= 50 [die] [set color blue]]] ;
  ask turtles [set num-links count my-links]
end

to Match              ;match with neighbouring turtle
  if any? other turtles in-radius 3 [create-link-to one-of other turtles in-radius 3] ;[move]; with [not matched?]
  set matches lput [who] of link-neighbors matches
  ask link-neighbors [set matched? true]
  exchange-resources
  ask turtles with [matched? = true] [set matched? false]
end

to exchange-resources ;exchange resources with matched turtle
    if random 100 < Exchange_Likelihood [
      if matched? = true [if resource-level > 50 and [resource-level] of link-neighbors < 50 [
        set resource-level resource-level - 5]]
      if matched? = true [if resource-level < 50 and [resource-level] of link-neighbors > 50 [
        set resource-level resource-level + 5]]]
end

to kill-turtles
  if ticks mod 4 = 0 [
    ask turtles [set age age + 1]
  ]
  ask turtles with [age = 100] [hatch 1 set age 0 ask my-links [die]] ;give "birth" to child inheriting resources
  ask turtles with [age > 100] [die]          ;consider dying if age is above maximum
  ask turtles [if resource-level <= 0 [die]]  ;consider dying if resource level is below minimum
end

to gain-resources
  if ticks mod 4 = 0 [
  if random 100 < Gain_Likelihood [ ;the turtle is allowed to gain the resource on the patch
    ask turtles [set resource-level resource-level + [gain-value] of patch-here]]
  ask turtles [if resource-level >= 100 [set resource-level 100]] ;maximum resources that can be accumulated is set at 100
  ]
end

;;Visualization Procedures

to update-globals
  ;average of resource level
  set avg-high-resources mean [resource-level] of turtles with [extraversion-level = "High"]
  set avg-med-resources  mean [resource-level] of turtles with [extraversion-level = "Med"]
  set avg-low-resources  mean [resource-level] of turtles with [extraversion-level = "Low"]

  ;sum total number of links
  set high-links sum [num-links] of turtles with [extraversion-level = "High"]
  set med-links sum [num-links] of turtles with [extraversion-level = "Med"]
  set low-links sum [num-links] of turtles with [extraversion-level = "Low"]

  ;average number of links
  set avg-high-links mean  [num-links] of turtles with  [extraversion-level = "High"]
  set avg-med-links  mean  [num-links] of turtles with  [extraversion-level = "Med"]
  set avg-low-links  mean  [num-links] of turtles with  [extraversion-level = "Low"]
end


;See Info tab for full details
@#$#@#$#@
GRAPHICS-WINDOW
65
120
563
619
-1
-1
14.0
1
10
1
1
1
0
1
1
1
-17
17
-17
17
1
1
1
ticks
30.0

BUTTON
70
15
130
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

SLIDER
280
15
560
48
number
number
1
1000
84.0
1
1
NIL
HORIZONTAL

PLOT
575
430
960
620
Average Resource Levels
Time 
Mean Resource Level
0.0
100.0
0.0
100.0
true
true
"" ""
PENS
"High Extraversion" 1.0 0 -10873583 true "" "plot avg-high-resources"
"Med Extraversion" 1.0 0 -2674135 true "" "plot avg-med-resources"
"Low Extraversion" 1.0 0 -1069655 true "" "plot avg-low-resources"

BUTTON
200
15
263
48
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

BUTTON
130
15
212
48
Go Once 
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
65
70
235
103
Exchange_Likelihood
Exchange_Likelihood
0
100
75.0
1
1
NIL
HORIZONTAL

SLIDER
410
70
560
103
Life_Expectancy
Life_Expectancy
1
100
76.0
1
1
NIL
HORIZONTAL

PLOT
575
215
960
425
Average Links Per Extraversion Level
Number_of_Links
Time
0.0
0.0
0.0
5.0
true
true
"" ""
PENS
"High Extroversion" 1.0 0 -10873583 true "" "plot avg-high-links"
"Med Extroversion" 1.0 0 -2674135 true "" "plot avg-med-links"
"Low Extroversion" 1.0 0 -1069655 true "" "plot avg-low-links"

PLOT
575
10
960
210
Total Links Per Extraversion Level
Time
Number of Links 
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"High Extraversion" 1.0 0 -10873583 true "" "plot high-links"
"Med Extraversion" 1.0 0 -2674135 true "" "plot med-links"
"Low Extraversion" 1.0 0 -1069655 true "" "plot low-links"

SLIDER
245
70
400
103
Gain_Likelihood
Gain_Likelihood
0
100
25.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is a model simulation of agents of varying levels of extraversion, interacting with each other, and their environment thereby exhibiting emergence.

The gradient indicates the resource level available. The darker the color, the higher the number of resources on the patch.The dark red coloured agents are the agents with high extraversion levels, the red coloured agents are agents with medium extraversion levels, while the pink agents are the agents with low extraversion levels. They pick up the resource level from patches they are initially visible on; they are “born” on, so to speak. On matching, agents exchange resources. O matching more than once, agents form a link. They can also gain resources from patches as they move. They die and their children take their place. 

## HOW IT WORKS
In order to investigate the relation between extraversion and positive incentive motivation, a sample size of agents is simulated against a backdrop of a gradient patch environment. The turtles represent people of three different levels of extraversion – Low extraversion level, Mid extraversion level, and High extraversion level. They pick up the resource level from patches they are initially visible on, as if they were born on that given patch. All the agents can move, exchange resources, and die. 

As the agents move, they gain resources from the patches to simulate real-world behavior of resource distribution. Agents start with the age of zero that increases every 4 ticks, where every tick is indicative of 3 calendar months. They are also assigned a life expectancy and if agent exceed that life expectancy, then the agent dies. The surface itself contains a distribution in the quantity of resources available and each agent is born with the amount of resources corresponding to the patch where they generated. Each step doesn’t cost the agent resources, but agents will die if their resources run out. Resources possessed by agents are restricted to values between 0 and 100, where 100 is the maximum any agent can possess at a given time. 

Furthermore, agents can match with their neighbors, if their neighbors have not matched already. The extraverted agents also exchange resources based on their position as a result of movement, extraversion levels, and inherent resource levels. Depending on the parameter settings, the exchange likelihood of each of the turtles is higher for agents of higher extraversion levels (random-normal  Exchange_Likelihood 5), slightly lesser for agents for medium extraversion (random-normal (Exchange_Likelihood * 0.75) 5), and significantly lesser (random-normal (Exchange_Likelihood * 0.5) 5) for agents with lower range of extraversion. 

For intelligibility, the agents “exchange” resources of the value 5. Based on the number of times the exchange occurs between two specific extraverted agents, a link is formed. This acts as a bond between the agents which acts as a proxy for positive incentive motivation. 

## HOW TO USE IT

The setup button creates a gradient patch environment and individual agents with particular behavioral tendencies for extraversion. The board accepts the values from the sliders (described below). Once the simulation has been setup, you are now ready to run it, by pushing the go button. go starts the simulation and runs it continuously until 40 ticks pass or go is pushed again. During a simulation initiated by go, adjustments in sliders can affect the behavioral tendencies of the population.

In this model each time-step is considered three months.

Here is a summary of the sliders in the model.

- number: The count of people simulation begins with.
- Exchange_Likelihood: The probability of resources being exchanged between the turtles.
- Gain_Likelihood: The probability of turtles accumulating resources as they move across the environment.
- Life_expectancy: The average of normal distribution of the turtles’ life span.

The slider "number" ranges between 0 and 1000 and increments by 1.
The slider "Exchange_likelihood" ranges 0 and 1000 and increments by 1.
The slider "Gain_likelihood" ranges 0 and 1000 and increments by 1.
The slider "Life_expectancy" ranges 0 and 100 and increments by 1.

The model's plot shows the average resource level per extraversaion level, total number of links per extraversaion level, and average number of links per extraversaion level.


## THINGS TO TRY

Run a number of experiments with the GO button to find out the effects of different variables on the spread of HIV.  Try using good controls in your experiment.  Good controls are when only one variable is changed between trials.  For instance, to find out what effect the average duration of a relationship has, run four experiments with the AVERAGE-COMMITMENT slider set at 1 the first time, 2 the second time, 10 the third time, and 50 the last.  How much does the prevalence of HIV increase in each case?  Does this match your expectations?

Are the effects of some slider variables mediated by the effects of others? For example, decreasing Exchange_Likelihood should reduce the number of links formed and vice versa. Increasing Life_Expectancy should increase the duration of the links present in the model and vice versa. Increasing the Gain_Likelihood reduces the number of links, and vice versa.

## EXTENDING THE MODEL

Like all computer simulations of human behaviors, this model has necessarily simplified its subject area substantially. The model therefore provides numerous opportunities for extension:

*Show effects of extraversion by making extravert agents react separately in a society of agents.
*Links give us who exchanges with whom with end1 and end2 function.
*Exchange resources based on the difference of resource level between extravert and agent. 

## NETLOGO FEATURES

Notice that the patches generate many small random numbers as the resource level they hold. Similarly, the agents each gain resources with some small seemingly random numbers. This produces a normal distribution of tendency values. 

Notice the smoothly varying color gradients, indicating variation in resource level.

Notice the Extraversion_level of various extraversion level agents. 

Notice that the links are directed giving the direction of the agent end1 giving the resources to end2 agent.

## CREDITS AND REFERENCES

We greatly thank Drs. Andrew Crooks, Bill Kennedy, and Jim Thompson for their encouragement and helpful comments and Mr. Dwayne Smith for his technical assistance with NetLogo.

* Kornhauser, D., Wilensky, U., & Rand, W. (2009). Design guidelines for agent based model visualization. Journal of Artificial Societies and Social Simulation (JASSS), 12(2), 1. http://ccl.northwestern.edu/papers/2009/Kornhauser,Wilensky&Rand_DesignGuidelinesABMViz.pdf.

* Li J, Wilensky U. NetLogo Sugarscape 3 Wealth Distribution model. Center for Connected Learning und Computer-Based Modeling, Northwestern University, Evanston, IL. http://ccl.northwestern.edu/netlogo/models/Sugarscape3WealthDistribution. 2009.

* Stonedahl, F., Wilensky, U., Rand, W. NetLogo Heroes and Cowards model.
Center for Connected Learning and Computer-Based Modeling, Northwestern Institute on Complex Systems, Northwestern University, Evanston, IL. http://ccl.northwestern.edu/netlogo/models/HeroesandCowards. 2014.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.

<!-- 1997 2001 -->
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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gain_Likelihood">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Exchange_Likelihood">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>ask turtles with [extraversion-level = "High"] [show count link-neighbors with [extraversion-level = "High"]</metric>
    <metric>ask turtles with [extraversion-level = "High"] [show count link-neighbors with [extraversion-level = "High"]</metric>
    <enumeratedValueSet variable="Life_Expectancy">
      <value value="76"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Gain_Likelihood">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Exchange_Likelihood">
      <value value="100"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="FinalExpt" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>sum [num-links] of turtles with  [extroversion-level = "High"]</metric>
    <metric>sum [num-links] of turtles with  [extroversion-level = "Med"]</metric>
    <metric>sum [num-links] of turtles with  [extroversion-level = "Low"]</metric>
    <steppedValueSet variable="number" first="100" step="100" last="500"/>
    <steppedValueSet variable="Gain_Likelihood" first="25" step="25" last="100"/>
    <steppedValueSet variable="Exchange_Likelihood" first="25" step="25" last="100"/>
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
