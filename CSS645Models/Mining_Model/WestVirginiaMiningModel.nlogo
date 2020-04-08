globals [size-of-mine
         time_months
         time_years
         miners
         max-miners
         leave-health
         leave-job
         leave-environment
         leave-F&F
         phealth
         penvironment
         pF&F
         pjobless
         avg-unemployment]

patches-own [coal-value
             current?
             mined?
             peak?
             town-lots]

turtles-own [job?
             jobless
             health
             max-health
             max-environment
             max-F&F
             noise?
             F&F-gone
             F&F
             cancer?]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; Setup  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup
  clear-all
  create-mountains
  create-mine
  create-town
  set size-of-mine 1
  set max-miners round(.54 * number-of-homes)
  set miners 0
  assign-miners
  reset-ticks
end

to create-town
  set-default-shape turtles "house"
  crt number-of-homes [
    set color blue
    setxy (1 + random 15) random-pycor
    ifelse random 2 = 1 [set job? 0] [set job? 1]
    set max-health random-normal Health-Concern 2
    set max-environment random-normal Environment-Concern 2
    set max-F&F random-normal F&F-Concern 2

    ]
  ask turtles [set F&F (count turtles in-cone 5 360)]
  while [count turtles with [cancer? = 1] < (number-of-homes * 0.14)]
    [ask one-of turtles [set cancer? 1]]

end

to create-mountains
  ask (patch-set
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch (-1 + random -15) random-pycor
    patch random 16 random-pycor
    patch random 16 random-pycor
    patch random 16 random-pycor) [set pcolor 0
                                   set coal-value (1 / (.1 + pcolor))
                                   set current? 0
                                   set mined? 0
                                   set peak? 1]

   ask patches with [coal-value = 0] [ifelse (distance (min-one-of patches with [peak? = 1] [distance myself])) > 9.9
       [set pcolor 0 + 9.9] [set pcolor 0 + (distance (min-one-of patches with [peak? = 1] [distance myself])) + random 0.7]
        set coal-value (1 / (.1 + pcolor))
        set current? 0
        set mined? 0]
  ask patches [if pxcor >= 0 [set coal-value 0
                              set mined? 1
                              set town-lots 1
                              set peak? 0]
               ]
end

to create-mine
  ask one-of patches with-max [coal-value] [set pcolor green set current? 1 set mined? 1 set peak? 0]
end

to assign-miners
  while [max-miners != miners and (count turtles with [job? = 0]) > 0] [ask turtle (round (random number-of-homes))
    [if job? = 0 [set job? 1 set miners miners + 1]]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; RESET  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to reset
  set number-of-homes 200
  set Health-Concern 50
  set Environment-Concern 50
  set F&F-Concern 50
  set Job-Leave true
  set Health-Leave false
  set Environment-Leave false
  set F&F-Leave false
  set years-wo-job 2
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;  GO  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to go
  expand-mine
  mine-size
  calculate-time
  update-town
  tick
  if count patches with [current? = 1] = 0 [stop]
end

to expand-mine
  ask patches with [current? = 1] [
      ifelse (count neighbors with [mined? = 1]) != (count neighbors)
      [ask one-of neighbors with [mined? != 1]
        [set pcolor red set mined? 1 (if peak? = 1 [set peak? 0])]
        ]

    [set pcolor red
     set coal-value 0
     set current? 0
     set mined? 1
     set peak? 0

     ask one-of neighbors with-max [coal-value] [ifelse coal-value < (1 / 7)
        [ifelse (count patches with [peak? = 1]) >= 1
          [ask patch-at-heading-and-distance (towards (min-one-of patches with [peak? = 1] [distance myself])) 1
            [ifelse town-lots = 0 [set pcolor green set current? 1 set mined? 1]
              [ask min-one-of patches with [town-lots = 0] [distance myself]
                [set pcolor green set current? 1 set mined? 1]]]]
          [stop] ]
        [ifelse town-lots = 0 [set pcolor green set current? 1 set mined? 1]
          [ask min-one-of patches with [town-lots = 0] [distance myself]
                [set pcolor green set current? 1 set mined? 1]]]

        ]

     ask neighbors [set coal-value 0]
        ]
      ]
end


to mine-size
  set size-of-mine (count patches with [mined? = 1 and town-lots = 0])
end


to calculate-time
  set time_months ticks
  set time_years ticks / 12
end


to update-town
  if remainder time_years 1 = 0 [
    set-miners
    have-job
    healthy?
    environment?
    F&F?

    ;;update-plots
    update-concernes

    ifelse Job-Leave = true [job-die] [if count turtles > 0 [set avg-unemployment (sum [jobless] of turtles)/(count turtles)] ]

    if Health-Leave = true [health-die]

    if Environment-Leave = true [environment-die]

    if F&F-Leave = true [F&F-die]

  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Subfunctions  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to set-miners
  ifelse random 2 >= 1
    [set max-miners (max-miners + round(random 10))]
    [set max-miners (max-miners - round (random 10))]
  while [max-miners != miners and count turtles > 0]
   [ifelse max-miners < miners
     [ifelse count turtles with [job? = 1] > 0 [ask one-of turtles [if job? = 1 [set job? 0 set miners miners - 1]]]
       [stop]
      ]
     [ifelse count turtles with [job? = 0] > 0
       [ask one-of turtles [if job? = 0 [set job? 1 set jobless 0 set miners miners + 1]]]
       [stop]
      ]
   ]
end

to have-job
  ask turtles [if job? = 0 [
      set jobless jobless + 1
      if jobless > years-wo-job [set color cyan]]
    ]
end

to F&F?
  ask turtles [
    if F&F-gone < max-F&F
     [set F&F-gone (F&F - (count turtles in-cone 5 360)) * 100 / F&F]
    if F&F-gone >= max-F&F [set color gray]
    ]
end

to environment?
    ask turtles [
      if noise? < max-environment
        [if count patches with [current? = 1] > 0
          [set noise? 100 * (distance (min-one-of patches with [mined? = 1 and town-lots = 0] [distance myself])) ^ (-1)]
        ]
      if noise? >= max-environment [set color green]
    ]
end

to healthy?
 ask turtles [
   if health < max-health
     [ifelse cancer? = 1
      [set health 0.62 * e ^ (0.015 * size-of-mine)] ;; sick people
      [set health 0.50 * e ^ (0.012 * size-of-mine)] ;; not sick people
     ]
   if health >= max-health [set color red]
  ]
end

to update-concernes
  set pF&F count turtles with [F&F-gone >= max-F&F]
  set phealth count turtles with [health >= max-health]
  set penvironment count turtles with [noise? >= max-environment]
  set pjobless count turtles with [jobless > years-wo-job]
end


to job-die
  ask turtles [if jobless > years-wo-job [set leave-job leave-job + 1 die]
      ]
  show count turtles
end

to health-die
  ask turtles [
    if health > max-health [set leave-health leave-health + 1 die]
  ]
end

to environment-die
  ask turtles [
    if noise? > max-environment [set leave-environment leave-environment + 1 die]
  ]
end

to F&F-die
  ask turtles [
    if F&F-gone > max-F&F [set leave-F&F leave-F&F + 1 die]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
781
582
-1
-1
17.061
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
0
0
1
ticks
30.0

BUTTON
30
12
93
45
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
18
98
190
131
number-of-homes
number-of-homes
0
200
200.0
1
1
NIL
HORIZONTAL

BUTTON
31
55
94
88
NIL
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

BUTTON
112
54
175
87
NIL
Go
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
656
22
920
172
Size of Mine / Number  of Employees
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
"default" 1.0 0 -16777216 true "" "plot count patches with [pcolor = red]"
"pen-1" 1.0 0 -7500403 true "" "plot miners"

PLOT
658
181
923
331
Number of Homes
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
"# Homes" 1.0 0 -16777216 true "" "plot count turtles"
"Health" 1.0 0 -2674135 true "" "plot leave-health"
"Jobless" 1.0 0 -11221820 true "" "plot leave-job"
"Environment" 1.0 0 -14439633 true "" "plot leave-environment"
"F&F" 1.0 0 -7500403 true "" "plot leave-F&F"

PLOT
929
22
1237
225
Number of Homes with Concern
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
"Environment" 1.0 0 -13840069 true "" "plot penvironment"
"Health" 1.0 0 -5298144 true "" "plot phealth"
"F&F" 1.0 0 -7500403 true "" "plot pF&F"
"Jobless" 1.0 0 -11221820 true "" "plot pjobless"

SLIDER
17
220
189
253
Health-Concern
Health-Concern
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
17
301
189
334
Environment-Concern
Environment-Concern
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
18
391
190
424
F&F-Concern
F&F-Concern
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
112
12
176
45
NIL
Reset
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
36
260
165
293
Health-Leave
Health-Leave
1
1
-1000

SWITCH
26
344
173
377
Environment-Leave
Environment-Leave
1
1
-1000

SWITCH
42
430
158
463
F&F-Leave
F&F-Leave
1
1
-1000

SWITCH
47
180
160
213
Job-Leave
Job-Leave
0
1
-1000

SLIDER
18
141
190
174
years-wo-job
years-wo-job
0
10
2.0
1
1
NIL
HORIZONTAL

MONITOR
935
239
1096
284
Average Time Unemployed
avg-unemployment
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model provides a basic look at parameters that may effect a resident's decision to leave there home or not.  More specifically, this model looks at how the presence and growth of a surface mine in a region affects the local residents.

This model is based on population statistics collected on Danville, West Virginia and the Hobet 21 mine.   

## HOW IT WORKS

This program has two parts, one is the mine expansion and the other is the town agents. The mine expands on a monthly basis, starting at a mountain peak and moving "down" (outward) the mountain and then across to other peaks. The mine continues to expand until all the peaks have been harvested. 

The adjacent town has agents that track their job status, health, environmental, and friends & family concerns that may be affected by the mine.  While the mine does provide employment to residents, it also brings a number of concerns.  This model looks at some of these concerns and allows the user to observe how those concerns may influence the decreasing population seen in many coal towns in West Virginia.


## HOW TO USE IT

To run the program select 'setup' and then 'go'.  There are two 'go' buttons, one will automatically run the program until it reaches the end, the other only moves forward by one time step.  

The reset button returns all the global variables to the baseline case where only job-leave is turned on and the other parameters are turned off.  Each of the globals are explained in more detail below: 

Globals
size-of-mine: Provides the overall size of the mine 

time_years: The mine expands by the month, but the agents make a decision yearly, so this parameter tracks time to indicate to the agents when it is time to make a decision.

miners: How many agents are employed at the mine.

max-miners: On a yearly basis, the number of employees of the mine changes at random by 10 employees, the number of agents at mine is able to employ is defined using this variable. The number of miners has to adjust to the max-miners by hiring or firing agents. 

leave-health/environment/F&F/job: these variables count the number of agents that leave the town due to a particular concern.  Health indicates leaving for health concerns, environment is for environmental concerns, F&F is for loss of friends and family and job is for unemployment.  

Health/Environmental/F&F-Concern: are a set of variables that allow the user to adjust the threshold value the agents use to determine staying or leaving the community.  Each agent is assigned a value from a normal distribution around the chosen value.

Health/Environment/F&F/Job-Leave: these variables are switches that allow the user to turn on and off the agent’s ability to leave based on health, environment, friends and family (F&F) and job.  When the variables are turned on, the agent will leave if its value for that particular parameter is greater than the threshold set by the -concern variable.  If the –leave variable is turned off; the agent will not exit the simulation even if the threshold value is crossed.  

years-wo-job: Like the other –Concern variables, this variable is used to set the threshold for the number of years unemployed an agent will accept experiencing before moving (leaving the simulation).  This value is uniform value across all agents.  

phealth/penvironment/pF&F/pjob: these variables are just counters that track the number of agents who cross the maximum threshold. This allows the user to see the number of ‘unhappy’ agents (agents who are experience concern above their acceptable level) without removing the agents from the simulation.

avg-unemployment: this tracks the average unemployment time across the town, it is mainly used when Job-Leave is turned off and agents can remain in the simulation for the duration. 

number-of-homes: changes the number of homes in the simulation 

Patch Variables 
coal-value: gives the patch a random coal value that is determined by its shade. 

current?: indicates the active mine location 

mined?: areas that have previously been mined. 

peak?: indicate the mountain tops, typically the starting locations for surface mining.

town-lots: delineates the town versus the minable mountain range.

Turtles Variables
job?: indicates if the agent has a job.

Jobless: keeps count of the duration the agent is without a job. Used to determine when 
the threshold value is crossed.

Health: indicates the agent’s current ‘health’ concern level. This is updated on a yearly basis.  The size of the mine is the major factor in determining the agents concern with health.  The size of the mine can affect the air quality and water quality. 

Cancer?: Cancer is distributed to approximately 14% of residents.  These residents have follow a different health concern curve and are likely to reach their maximum acceptable health level more quickly than those without cancer. 

max-health: this is the maximum health concern level accepted by the agent (before leaving if Health-Leave is turned on).

noise?: this calculates how each of the agents perceive the mine’s damage to the environment.  It is mainly looking at how close the mine gets to the agent’s home, which would cause increase noise from blasting and the risk of flying debris. 

max-environment: this is the maximum environmental concern level accepted by the agent (before leaving if Environment-Leave is turned on).

F&F: this is the baseline number of friends and family the agent has when the simulation starts. 

F&F-gone: this is the value associated with the concern of losing friends and family.  Each agent as a cone of vision, as other agents move out (regardless the reason), the concern with losing friends and family grows. 

max-F&F: this denotes the max acceptable concern value associated with loosing friends and family for that agent.  This value is selected at random from a normal distribution around the F&F-Concern value. 


## THINGS TO NOTICE

When looking at the agents with environmental concern, you will notice that they seem to be mainly be along the mine border. This is becaue the main environmental concerns that were looked at as part of this model with the blasting noise and the debris, so the agents were calculating their concern based on the distance they were from the active mine. Therefore, agents on the oppisite side of the town did not have the necessary proximity to exceed their maximum acceptable threshold. This could be changed by looking at other environmental effects and adding other parameters the agents can use to judge their concern. 



## THINGS TO TRY

Try adjusting the F&F-Concern slider.  When the slider is at its default value few agents exceed the maximum F&F concern value.  This is due to only a small number of people leaving the simulation when using the defualt values.  Not enough people leave from the agents proximity to justify concern.  However, when you adjust the slider to a lower value, the agents become much more sensitive to the people leaving.


## EXTENDING THE MODEL

As always, a good extension would be using actual street maps for the town (homes).  Also more accurate landscape would be of use if the goal is to model a specific town or mine. However, when trying to collect elevation data in an area that has already been mined can be a challenge.  This model used the Hobet 21 mine as a starting point, but since the mine has been active since the early 1980's finding the original landcover data is challenging. 


## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

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
