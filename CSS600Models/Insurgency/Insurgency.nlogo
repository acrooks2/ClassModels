breed [civilians civilian]  ;;a breed of civilians is set to represent the population of the country
breed [govs gov]     ;;government agents are a breed to represent security forces are enforcers of policy
breed [leaders leader]  ;;one leader is set up if conditions allow




civilians-own [
  perceived-historical-grievance?  ;;recent history of internal conflict that has left lingering grievances against the gov or hostility among groups
  perceived-government-corruption?  ;;  unfair political system or inept or corrup security forces leads to grievances
  perceived-human-rights-grievance? ;; gov policies that disadvantage a segment of the population on the basis of religion, tribe, ethnicity, region, or class
  perceived-societal-grievance? ;;  economic crisis, division of wealth, or extended period of poor economic conditions or period of vulnerabilitythat generate discontent wit the gov and provides a base of unemployed ripe for recruitment
  grievance-score
  similar-nearby
  civilian-group
  new-nearby
]



to setup                   ;;setup all civilians, leaders, and govs in the model
  clear-all
  setup-civilians
  setup-leaders
  setup-govs
  reset-ticks
end

to setup-civilians
  create-civilians population    ;;a population of civilians is set up based on the population slider and turned white
  [move-to one-of patches
    set size .7
    set color white
    set shape "person"
    ]

  set-initial-civilian-dissent-proportions

  ask civilians [
    set-initial-civilian-var
  ]
end

to setup-leaders     ; if gov corruption is high or there is a history of conflict or if there are human rights abuses, a leader will stand up to get his voice heard...shown in yellow
  set-default-shape turtles "person"
  if government-corruption = "High" or history-of-conflict = "Yes" or Human-rights-abuses = "Yes"
  [create-leaders 1
    [
      setxy random-xcor random-ycor
      set color yellow
    ]
  ]
end

;;;;;;;;;;;;;
;;Gov Setup;;
;;;;;;;;;;;;;

to setup-govs         ;set up of government agents, they will responds based on the three stages of insurgency
  if count civilians <= 500[      ;;set up 5 gov agents if civilians is less than or equal to 500....turn them blue
   create-govs 5
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0
    ]]
   if count civilians <= 1000 and count civilians > 500[   ;;set up 10 gov agents if civilians are btw 500-1000....randomly set and turn blue
   create-govs 10
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0

   ]]
   if count civilians <= 1500 and count civilians > 1000[     ;;set up 15 gov agents if civilians are btw 1000-1500....randomly set and turn blue
   create-govs 15
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0

   ]]
    if count civilians <= 2000 and count civilians > 1500[   ;;set up 20 gov agents if civilians are btw 1500-2000....randomly set and turn blue
   create-govs 20
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0
    ;set discuss? True
   ]]
   if count civilians <= 2500 and count civilians > 2000[      ;;set up 25 gov agents if civilians are btw 2000-2500....randomly set and turn blue
   create-govs 25
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0
    ;set discuss? True
   ]]
   if count civilians <= 3000 and count civilians > 2500[     ;;set up 30 gov agents if civilians are btw 2500-3000....randomly set and turn blue
   create-govs 30
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0
    ;set discuss? True
   ]]
   if count civilians <= 3500 and count civilians > 3000[    ;;set up 35 gov agents if civilians btw 3000-3500...randomly set and turn blue
   create-govs 35
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0
    ;set discuss? True
   ]]
   if count civilians > 3500[      ;;set up 40 gov agents if civilians over 3500....randomly set and turn blue
   create-govs 40
   [
    setxy random-xcor random-ycor
    set color blue
    set size 1.0
    ;set discuss? True
   ]]

end


to discuss-govs
 if Government-reaction = "Preinsurgency Stage" and count civilians with [color = red] > 50
  [
    ask govs           ;;if the gov reaction is preinsurgency stage, once the count of grieved civilians gets over 50 have them discuss
     [discuss]

    ]
 if Government-reaction = "Incipient Conflict Stage" and count civilians with [color = red] > 100
   [
     ask govs         ;;if the gov reaction is incipient conflict stage, once the count of grieved civilians gets over 100 have them move to the leader and fight
     [move-gov]
     ask govs
       [fight]
   ]
  if Government-reaction = "Open Insurgency Stage" and count civilians with [color = red] > 200
   [
     ask govs          ;;if the gov reaction is open insurgency stage, once the count of grieved civilians gets over 200 have them move to the leader and fight
     [move-gov]
     ask govs
           [fight]
   ]
end


to set-initial-civilian-dissent-proportions               ;; set all percieved grievances as false so no agent has a grievance to start

  ask civilians [
    set perceived-historical-grievance? false
    set perceived-human-rights-grievance? false
    set perceived-government-corruption? false
    set perceived-societal-grievance? false
  ]

  ;
  ; now adjust the population perceptions based on percentages from prior analysis
  ;

  if history-of-conflict = "Yes" ;;if there is a history of conflict then 47% of the population has a perceived historical grievance
                                 ;;[set perceived-historical-grievance? True]
  [ ask n-of (population * .47) civilians
    [set perceived-historical-grievance? True]]

  if human-rights-abuses = "Yes"  ;;if there are human rights abuses then 75% of the population has a perceived human rights grievance
  [ask n-of (population * .75) civilians
    [set perceived-human-rights-grievance? True]]

  if Government-corruption = "High"  ;;if gov corruption is high then 57% of the population has a perceived grievance with corruption
  [ask n-of (population * .57) civilians
    [set perceived-government-corruption? True]]

  if period-of-vulnerability = "Yes" or (unemployment-rate > .15 and youth-bulge = "Yes" and distribution-of-wealth-by-Gini-coefficient > 50)
  [ask n-of (population * .34) civilians      ;; if there is a period of vulnerability or (unemployment is greater than 15% and there is a youth bulge and there is a distribution of wealth over 50
    [set perceived-societal-grievance? True]]  ;;then 34% of the population has a perceived societal grievance
end


to set-initial-civilian-var
  ;
  ; set the default variable states first
  ;
   set grievance-score 0  ;;set initial grievance score to 0

  ; walk thru the logic of setting up grievance score
  ; based on several sets of possible conditions
  ; beginning with the most restrictive and working to the least restrictive
  ;
  let done? false   ;;if there is a percieved societal grievance and percieved human rights grievance and perceived gov corruption grievance and perceived historical grievance, then set grievance score to 5
  if (not done?) [
    if perceived-societal-grievance? and perceived-human-rights-grievance? and perceived-government-corruption? and perceived-historical-grievance?
    [
      set grievance-score 5
      set done? true
    ]
  ]

  if (not done?) [
    if (perceived-government-corruption? and perceived-human-rights-grievance?) or (perceived-government-corruption? and perceived-historical-grievance?)
    [              ;;if there is percieved gov corruption and perceieved human rights grievance OR percieved gov corruption and percieved historical grievance, then set grievance score to 4
      set grievance-score 4
      set done? true]
  ]

  if (not done?) [
    if (perceived-human-rights-grievance? and perceived-historical-grievance?)
    [         ;;if there is a percieved human rights grievance and a percieved historical grievance, set grievance score to 4
      set grievance-score 4
      set done? true
    ]
  ]

  if (not done?) [
    if (perceived-societal-grievance? and perceived-human-rights-grievance?) or (perceived-societal-grievance? and perceived-government-corruption?)
    [                           ;;if there is a percieved societal grievance and a percieved human rights grievance OR a percieved societal grianvance and a percieved gov corruption, set grievance score to 3
      set grievance-score 3
      set done? true
    ]
  ]

  if (not done?) [    ;;;if there is percieved historical grievance and percieved societal grievance, set grievance score to 2
    if (perceived-historical-grievance? and perceived-societal-grievance?)
    [
      set grievance-score 2
      set done? true
    ]
  ]

  if (not done?) [   ;; if there is percieved historical grievance only, set grievance score to 1
    if (perceived-historical-grievance?)
    [
      set grievance-score 1
      set done? true
    ]
  ]

  if (not done?) [   ;;if there is percieved societal grievance only, set grievance score to 1
    if perceived-societal-grievance?
    [set grievance-score 1
      set done? true
    ]
  ]

  if (not done?) [   ;;;if there is perceived human rights grievance only, set grievance score to 1
    if perceived-human-rights-grievance?
    [
      set grievance-score 1
      set done? true
    ]
  ]

  if (not done?) [  ;;if there is percieved gov corruption only, set grievance score to 1
    if perceived-government-corruption?
    [set grievance-score 1
      set done? true
    ]
  ]

end



to step             ;;to step and set up grieved civilians based on grievance score and neighbors
  let done? false
  ask civilians with [grievance-score >= 3] [     ;;if civilians with grievance score greater than or equal to 3 and more than 3 neighbors with grievance score equal to or greater than 3, turn red
    set similar-nearby count (civilians-on neighbors) with [grievance-score >= 3]
    if similar-nearby > 3
    [
      set color red
      set done? true
    ]
  ]

  ask civilians with [grievance-score >= 4] [    ;;if civilinas with grievance score equal to or greater than 4 and more than 3 neighbors with grievance score equal to or greater than 4, turn red
    set similar-nearby count (civilians-on neighbors) with [grievance-score >= 4]
    if similar-nearby > 3
    [set color red
      set done? true
    ]
  ]

  ask civilians with [grievance-score >= 2] [   ;;if civilians with grievance score equal to or greater than 2 and 1 neighbor that is a leader, turn red
    set similar-nearby count (leaders-on neighbors)
    if similar-nearby = 1
    [set color red
      set done? true
    ]
  ]

  ask civilians with [grievance-score = 1] [    ;;if civilians with grievance score equal to 1 and more than 5 neighbors with grievance score equal to 4, turn red
    set similar-nearby count (civilians-on neighbors) with [grievance-score = 4]
    if similar-nearby > 5
    [set color red
      set done? true
    ]
  ]

  ;;check each time for the gov count, and popup if it reaches 0 govs

  if ((count govs) = 0) [       ;;;if the count of govs gets down to 0 this means that the insurgency has won!
    user-message ("Insurgency Wins!")
  ]

end

;;;;;;;;;;;;;;;;
;;GOV Behavior;;
;;;;;;;;;;;;;;;;

to move-gov    ;;move the govs to a patch where the leader is

  ask govs
  [


    move-to one-of patches with [any? leaders-here]
  ]
end

;;in the pre-insurgency stage, diplomacy is best
;;if the greivance score is below a certain point, the civilian will turn back to red, if not, gov leaves to go to other red group
to discuss       ;;to discuss means to set policy in place to decrease grievances   ask civilians who are grieved to decrease their grievance score to 2 because the policy makes them happier
   ask civilians with [color = red]
  [set grievance-score 2]
  ask civilians with [grievance-score <= 2]   ;;ask all civilians who were just a little grieved before to now turned ungrieved
   [set color white]

 end

;;in the latter stages, violence is occuring
;;if the group of "red" civilians is larger than the govs, the civilians win the fight
to fight
  ask govs [    ;;if there is inhospitable terrain and the count of the red civilians within a radius of 6 of the govs is greater than the govs, the govs all die
    if Inhospitable-terrain = "Yes" and count (civilians in-radius 6 with [color = red])  > count govs

    [die]
    If Inhospitable-terrain = "No" and count (civilians in-radius 6 with [color = red])  > count govs
    [ask n-of (count govs / 2) govs    ;;if there is no inhospitable terrain and the count of the redcivilians within a radius of 6 of the givs is greater than the govs, half of the govs die
      [die]  ]
    if Inhospitable-terrain = "No" and count govs > count civilians in-radius 6 with[color = red]
    [ask n-of (count (civilians in-radius 6 with [color = red]) / 4) civilians in-radius 6 with [color = red]
     [die]    ;;if there is no inhospitable terrain the the count of the govs is greater than the count of the red civilians within a radius of 6, then 1/4 of the red civilians in that radius die
    ]
    if Inhospitable-terrain = "Yes" and count govs > count civilians in-radius 6 with[color = red]
    [ask n-of (count (civilians in-radius 6 with [color = red]) / 2) civilians in-radius 6 with [color = red]
      [die]  ;;if there is inhospitalbe terrain and the count fo the govs is greater than the count of the red civilians within a radius of 6, then half of the red civilians in that radius die
    ]
  ]
  if count govs = 0          ;; if the count of gov is 0 then the insurgency wins!
  [show "Insurgency Wins!"]
end


to go     ;;to go, first set up the percieved grievances, then move the civilians around and update grievance scores....then move leader and update grievance scores, then have the govs discuss (change policy or fight) if the grievance number is high enough...then update grievance scores
  step
  move-civilians
  update-civilians
  move-leader
  update-civilians
  discuss-govs
  update-civilians
  tick
end

to move-leader    ;;to move leader to the center patch of the largest group of grieved civilians


  ask patches [
    set pcolor black
  ]

  ;
  ; declare some vars
  ;
  let red-range 5   ;; this is the "vision" range in which to look for reds
  let max-red 0
  let max-red-patch nobody
  let my-red 0

  ;
  ; find the area that has the most reds
  ;
  foreach sort patches [ ?1 ->    ;;calculate the number of grieved civilians in the vision 5
    ask ?1 [
      let near-civilians civilians in-radius red-range
      let k 0
      ask near-civilians [
        if color = red [ set k (k + 1) ]
      ]
      set my-red  k
      if (my-red > max-red) [
        set max-red my-red
        set max-red-patch ?1
      ]
    ]
  ]

  ;
  ; if there is a cluster, move the leader to the closest vacant spot
  ; near the cluster center point
  ;
  if (max-red-patch != nobody) [
    let red-cluster nobody
    ask max-red-patch [
      set red-cluster patches in-radius red-range with [not any? turtles-here]
    ]

    if count red-cluster > 0 [
      let red-target nobody
      ask max-red-patch [
        set red-target min-one-of red-cluster [distance myself]
      ]

      if (red-target != nobody) [
        ask leaders [
          move-to red-target
          set size 2.0  ;; DEBUG: make the leader easier to see
        ]
      ]

    ]
  ]



  if (max-red-patch != nobody) [    ;;make it easier to see where the leader and large group of grieved civilians are by turning the patches around it green
    ask max-red-patch [
      ask patches in-radius red-range [
        set pcolor green - 1
      ]
      set pcolor orange + 3
    ]
  ]

end

to update-civilians  ;;updates the civilians to red or white after they have been moved......same logic as above using grievance score and neighbor grievance score
  let done? false
  ask civilians with [grievance-score >= 3] [
    set new-nearby count (civilians-on neighbors) with [grievance-score >= 3]
    if new-nearby > 3
    [
      set color red
      set done? true
    ]
  ]

  ask civilians with [grievance-score >= 4] [
    set new-nearby count (civilians-on neighbors) with [grievance-score >= 4]
    if new-nearby > 3
    [set color red
      set done? true
    ]
  ]

  ask civilians with [grievance-score >= 1] [
    set new-nearby count (leaders in-radius 2)
    if new-nearby = 1
    [set color red
      set done? true
    ]
  ]

  ask civilians with [grievance-score = 1] [
    set new-nearby count (civilians-on neighbors) with [grievance-score = 4]
    if new-nearby > 5
    [set color red
      set done? true
    ]
  ]

  tick
end

to move-civilians      ;; move civilians.....asks grieved civilians to look around them in a radius of 5 to see if they see other grieved civilians....if they do then they move to a patches with no turtles that is close to the grieved neighbor

  ask civilians with [color = red]
  [

    let close-civilians civilians in-radius 5 with [color = red]

    move-to one-of patches with [any? close-civilians and not any? turtles-here]]
end
@#$#@#$#@
GRAPHICS-WINDOW
215
13
1031
830
-1
-1
8.0
1
10
1
1
1
0
1
1
1
-50
50
-50
50
0
0
1
ticks
30.0

CHOOSER
4
387
111
432
Inhospitable-terrain
Inhospitable-terrain
"No" "Yes"
0

CHOOSER
2
98
144
143
Human-rights-abuses
Human-rights-abuses
"No" "Yes"
1

SLIDER
3
345
175
378
Unemployment-rate
Unemployment-rate
0
20
4.0
1
1
%
HORIZONTAL

CHOOSER
3
200
159
245
Period-of-vulnerability
Period-of-vulnerability
"No" "Yes"
1

BUTTON
8
493
72
526
Setup
Setup
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
82
493
145
526
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
8
534
71
567
Go
Go
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
2
13
174
46
Population
Population
0
5000
2700.0
100
1
NIL
HORIZONTAL

CHOOSER
2
249
94
294
Youth-bulge
Youth-bulge
"No" "Yes"
0

CHOOSER
3
437
183
482
Government-reaction
Government-reaction
"Preinsurgency Stage" "Incipient Conflict Stage" "Open Insurgency Stage"
1

SLIDER
2
302
204
335
Distribution-of-wealth-by-Gini-Coefficient
Distribution-of-wealth-by-Gini-Coefficient
0
100
60.0
1
1
NIL
HORIZONTAL

CHOOSER
2
149
156
194
Government-corruption
Government-corruption
"Low" "Medium" "High"
2

CHOOSER
2
49
140
94
History-of-conflict
History-of-conflict
"No" "Yes"
1

PLOT
1063
84
1263
234
Grieved Civilians
NIL
NIL
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"Grieved Civilians" 1.0 0 -2674135 true "" "plot count civilians with [color = red]"

MONITOR
1070
273
1174
318
Grieved Civilians
count civilians with [color = red]
0
1
11

MONITOR
1078
344
1136
389
Govs
count govs
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a model to replicate how an insurgency forms within a civilian population.  An insurgency is a protracted political-military struggle directed toward subverting or displacing the legitimacy of a constituted government or occupying power and completely or partially controlling the resources of a territory through the use of irregular military forces and illegal political organizations. The common denominator for most insurgent groups is their objective of gaining control of a population or a particular territory, including its resources.

Insurgent organizers can use historical, societal, political, or economic conditions that generate discontent among a segment of the population to rally support for their movement.

## HOW IT WORKS

This model contains three types of agents: Civilians, Insurgent Leaders and Govs.  

This model is based on how the civilians are feeling towards their government.  We have established 4 basic variables that contribute toward a "grievance score".  If the grievance score reaches a certain level, then the civilians turn from white to red and then seek out other red "grieved" civilians to form a group.  Red civilians can be convinced to change back to white through diplomacy and policy. 

The Leader is yellow and is extremist organizer.  He or she cannot change their thinking.  The leader gravitates toward the largest group of grieved civilians. 

Govs are blue and respond to groups of red civilians.  The Govs response depends on when they respond to evidence of an insurgency's formation.  If they respond before violence occurs, they can use policy and "discuss" grievances with red civilians to change them back to white.  In any other stage, govs and red civilians fight with the group with less fighters dying off either partially or fully depending on inhospitable terrain. 

The three stages of insurgency:
Preinsurgency Stage: Red Civilians and Govs discuss their grievances
Incipient Conflict Stage: Red Civilians and Govs fight
Open Insurgency Stage: Red Civilians and Govs fight

## HOW TO USE IT

Choose how large you want your population.  Typically insurgencies involve a small percentage of the total population and that is reflected in the model.

The 4 main variables that contribute to the grievance score are choosers that can be yes or no (except for the corruption variable, that has low, medium and high):
History of Conflict
Period of Vulnerability
Government Corruption
Human Rights Abuses

There are sliders to measure the distribution of wealth (as indicated by the Gini Coefficient) and the unemployment rate within the country.

Youth Bulge indicates whether there is a large percentage of the population between 18 - 34 years old.  

Inhospitable Terrain can be applied to urban or rural settings and is accounted for in the model by limiting the awareness of the govs by far they can see red groups forming.  If the Inhospitable Terrain chooser is Yes, then the distance of how far they can see red groups forming is much shorter versus if if the chooser is No.

Because governments react to insurgencies at different stages, we have incorporated a chooser than lets the user choose when the government reacts and this affects the outcome of the red civilians and govs interaction:
Preinsurgency Stage: No violence, just policy and diplomacy
Incipient Conflict Stage: violence is occuring, govs reaction is slow
Open Insurgency Stage: violence is occuring, both sides equally active

## THINGS TO NOTICE

How does the number of grieved civilians change based on how many grievance variables you choose?  Are the govs reacting by sending in more gov agents and how fast are they reacting?  

## THINGS TO TRY

Put all the grivance variables on yes and corruption on high.  Then allow for inhospitable terrain to be no.  Adjust the stages to see how fast the govs flock to the red groups. 

## EXTENDING THE MODEL

One feature we found in the case studies but did not incorporate in this model was a parameter for communication.  Insurgencies thrive and suffer based on their communications.  Case studies featured examples of very simple communication methods to more complex and the next iteration of this model would take that into account.  

## NETLOGO FEATURES

The highlight feature of Netlogo allows the user to see where the leader is at all times and how the red civilains and blue govs are reacting to the leader. 

## RELATED MODELS

Rebellion Model by Uri Wilensky
Scatter Model by Uri Wilensky
Zombieland Version 1.4 by Michael D. Ball

## CREDITS AND REFERENCES
Models:
Rebellion Model by Uri Wilensky in the Models Library
Scatter Model by Uri Wilensky in the Models Library
Zombieland Version 1.4 by Michael D. Ball
(http://www.personal.kent.edu/~mdball/zombies1_4.htm)

Publications:
Thompkins, Jr. Et al, “Casebook on Insurgency and Revolutionary Warfare, Volume II: 1962-2009” United States Army Special Command 2012
United States Government, “Guide to the Analysis of Insurgency 2012”, US Government 2012
Jones, Robert C. “Understanding Insurgency: The Condition behind the Conflict”, Small Wars Journal 2011
Pilate, Joseph F. “The Causes of Terrorism”, Los Alamos National Laboratory 2007
Epstein, Joshua M. “Modeling Civil Violence: An agent-based computational approach”, National Academy of Sciences 2002





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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="200"/>
    <exitCondition>count govs = 0 or
count civilians with [color = red] = 0</exitCondition>
    <metric>count civilians with [color = red]</metric>
    <metric>count govs</metric>
    <enumeratedValueSet variable="History-of-conflict">
      <value value="&quot;No&quot;"/>
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Period-of-vulnerability">
      <value value="&quot;No&quot;"/>
      <value value="&quot;Yes&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Government-reaction">
      <value value="&quot;Preinsurgency Stage&quot;"/>
      <value value="&quot;Incipient Conflict Stage&quot;"/>
      <value value="&quot;Open Conflict Stage&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Unemployment-rate">
      <value value="10"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Government-corruption">
      <value value="&quot;Low&quot;"/>
      <value value="&quot;Medium&quot;"/>
      <value value="&quot;High&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Youth-bulge">
      <value value="&quot;Yes&quot;"/>
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Human-rights-abuses">
      <value value="&quot;Yes&quot;"/>
      <value value="&quot;No&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Population" first="500" step="500" last="5000"/>
    <enumeratedValueSet variable="Distribution-of-wealth-by-Gini-Coefficient">
      <value value="20"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Inhospitable-terrain">
      <value value="&quot;No&quot;"/>
      <value value="&quot;Yes&quot;"/>
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
