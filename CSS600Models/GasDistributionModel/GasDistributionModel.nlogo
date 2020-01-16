;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Agents   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; define the two types of agents

breed [buyers buyer]
breed [stations station]


;; define the variables local to each type of agent

buyers-own [AmountOfGas
            lowGas?
            Container
            HomeX
            HomeY
            buyerCount
            TimeWOGas
            WaitTime
            DailyFill?]

stations-own [GasAtStation
              HasGas?
              isOpen?
              StationX
              StationY]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Globals  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

globals [TimeCounter
         HourCount        ;; number of times simulation has run/ Hours since sim started
         GasPerHour
         numberOfStations
         AvgContainerSize
         TimeToDie
         MeanWaitTime
         GasLeft
         BuyersNeedingGas]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  reset-ticks
  set TimeCounter 1
  set GasPerHour (GasNeededPerDay / 24) ;;Equates to amount of gas needed per day = 15 gal
  set numberOfStations 1
  set AvgContainerSize 5
  set TimeToDie (Max_HoursW/OGas * 60)
  ask n-of numberOfStations patches [sprout-stations 1 [init-station]]
  ask n-of numberOfBuyers patches [sprout-buyers 1 [init-buyer]]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Initializing Agents  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to init-buyer
  if xcor = 0 and ycor = 0 [set xcor xcor + 1 set ycor ycor + 1]
  set HomeX xcor
  set HomeY ycor
  set pcolor 9.9
  set buyerCount 0
  set TimeWOGas 0
  set AmountOfGas random (GasPerHour * 24)     ;; gives turtle some amount of gas to start the simulation with
  ifelse Quantity_Control [set Container GasQuantity]
  [set Container random-near AvgContainerSize]
  ifelse AmountOfGas < 4 [set lowGas? true  set color red set shape "person"] [set lowGas? false  set color green set shape "house"]
  set DailyFill? false
end


to init-station
  set color blue set size 3
  setxy 0 0
  set StationX xcor
  set StationY ycor
  ask stations [set shape "box"]
  set GasAtStation Amount_Of_Gas_At_Station
  ifelse GasAtStation > 0 [set HasGas? true] [set HasGas? false]
end


to-report random-near [center]     ;; Taken from Aids model to make a normal distribution of container volume
  let result 0
  repeat 40
  [set result (result + random-float center)]
  report round (result / 20)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set Debugging Mode ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to restore-defaults-debugging
   set numberOfBuyers 2
   set GasNeededPerDay 15
   set HoursOpenPerDay 16      ;; Amount of gas a person can take with them
   set PumpTime 5              ;; Amount of time needed to pump gas
   set Max_HoursW/OGas 4
   set Amount_Of_Gas_At_Station 50
   set Quantity_Control False
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set Defaults ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to restore-defaults
   set numberOfBuyers 100
   set GasNeededPerDay 15
   set HoursOpenPerDay 16      ;; Amount of gas a person can take with them
   set PumpTime 5              ;; Amount of time needed to pump gas
   set Max_HoursW/OGas 12
   set Amount_Of_Gas_At_Station 5000
   set Quantity_Control False
   set GasQuantity 15
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; Go Procedures ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to Go
   set GasLeft (mean [GasAtStation] of stations)
   buyersMove                                                         ;; Moves buyers into line for the station
   MakePlots                                                          ;; Goes to the MakePlots command
   if count buyers with [lowGas? = true] > 0
   [set MeanWaitTime (mean [WaitTime] of buyers with [lowGas? = true])]  ;; Determines the average wait time for that tick
   set BuyersNeedingGas (count buyers with [lowGas? = true])          ;; Counts the number of buyers that need gas
   if count buyers = 0 [stop]                                         ;; Stop the simulation if there are no agents left
end


to buyersMove
  ask stations [ifelse TimeCounter >= 1 and TimeCounter <= (HoursOpenPerDay * 60) [set isOpen? True] [set isOpen? False ask buyers [set WaitTime 0 set MeanWaitTime 0]]]   ;; Open at 6am = 360 and close at 10 pm = 1320
  ask stations [ifelse HasGas?
    [ifelse isOpen? [ask buyers
       [ifelse Quantity_Control [if lowGas? = true and DailyFill? = false [GoToStation]]
         [if lowGas? = true [GoToStation] ] ] ]
       [stop]
     ]
    [stop]

  ]

  ask buyers [AdjustGas]

  ifelse TimeCounter = 1440 [set TimeCounter 1
    ask buyers [set DailyFill? False]]  ;; resets DailyFill? for the new day
  [set TimeCounter TimeCounter + 1]   ;; 1440 mins/day

  set HourCount floor(TimeCounter / 60)


  tick ;; = 1 min
  ;;print TimeCounter
end


to GoToStation

  ifelse xcor = 0 and ycor = 0

  [GetGas]

  [MoveToStation]

end

to GetGas
 let tempGas 0
  ifelse Quantity_Control [set tempGas min (list GasLeft GasQuantity)] [set tempGas min (list GasLeft container)]

 ifelse buyerCount = PumpTime [set AmountOfGas AmountOfGas + tempGas        ;; If the buyer is at the pump they can get gas but PumpTime defines how long it will take them
    set buyerCount 0                                                          ;; Reset buyercount
    set WaitTime 0                                                            ;; Reset Wait Time since buyer goes home with gas
    setxy HomeX HomeY                                                         ;; Return to home location
    if Quantity_Control = true  [set DailyFill? true]
    ask Stations [set GasAtStation GasAtStation - tempGas
      ifelse GasAtStation > 0 [set HasGas? true] [set HasGas? false]]] [set buyerCount buyerCount + 1]
end

to MoveToStation
  facexy 0 0                                                         ;; Turn towards the station and begin trek to get gas
    set WaitTime WaitTime + 1
    ifelse ([pcolor] of patch-ahead 1 != 9.9)
    [if (not any? other buyers-on patch-ahead 1) [fd 1 setxy (round(xcor)) (round(ycor))]] ;;[rt random-float 360 fd 1]]
    [while[[pcolor] of patch-ahead 1 = 9.9] [rt random-float 360]
      if (not any? other buyers-on patch-ahead 1) [fd 1 setxy (round(xcor)) (round(ycor))] ]
end



to AdjustGas
  ifelse (AmountOfGas - (GasPerHour / 2)) <= 0 [set AmountOfGas 0] [set AmountOfGas AmountOfGas - (GasPerHour / 60)]
  ifelse AmountOfGas < 4 [set lowGas? true set color red set shape "person"] [set lowGas? false  set color green set shape "house"]
  ifelse AmountOfGas = 0 [set TimeWOGas TimeWOGas + 1] [set TimeWOGas 0]
  if TimeWOGas = TimeToDie [die]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; To Plot     ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to MakePlots                                             ;; Used ZITrading model for plot commands
  ask Stations [set-current-plot "Gas At Station"
     set-current-plot-pen "Gas-At-Station"
     plot GasAtStation]
end
@#$#@#$#@
GRAPHICS-WINDOW
236
22
725
512
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-18
18
-18
18
1
1
1
ticks
30.0

BUTTON
22
16
86
49
NIL
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

SLIDER
17
140
189
173
NumberOfBuyers
NumberOfBuyers
0
250
100.0
1
1
NIL
HORIZONTAL

BUTTON
51
460
152
493
Debug Mode
restore-defaults-debugging
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
179
190
212
GasNeededPerDay
GasNeededPerDay
0
30
15.0
1
1
NIL
HORIZONTAL

SLIDER
18
219
190
252
PumpTime
PumpTime
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
18
257
190
290
HoursOpenPerDay
HoursOpenPerDay
8
24
16.0
1
1
NIL
HORIZONTAL

SLIDER
18
295
190
328
Max_HoursW/OGas
Max_HoursW/OGas
0
24
12.0
1
1
NIL
HORIZONTAL

PLOT
776
18
976
168
Number of Homes With Gas
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
"default" 1.0 0 -16777216 true "" "plot count buyers"

SLIDER
17
335
200
368
Amount_Of_Gas_At_Station
Amount_Of_Gas_At_Station
0
20000
5000.0
100
1
NIL
HORIZONTAL

PLOT
775
175
975
325
Gas At Station
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
"Gas-At-Station" 1.0 0 -16777216 true "" ""

MONITOR
742
492
799
537
Hour
HourCount
0
1
11

SWITCH
16
376
167
409
Quantity_Control
Quantity_Control
1
1
-1000

SLIDER
16
416
188
449
GasQuantity
GasQuantity
0
30
15.0
1
1
NIL
HORIZONTAL

BUTTON
22
53
85
86
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
0

PLOT
775
332
975
482
Mean Wait Time
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
"default" 1.0 0 -16777216 true "" "plot MeanWaitTime"

MONITOR
811
492
953
537
No Buyers Needing Gas
BuyersNeedingGas
17
1
11

BUTTON
22
91
94
124
Default
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

@#$#@#$#@
## WHAT IS IT?

This model demonstrates households retrieving gas from a station in order to keep their home generator running. The idea behind this model was to demonstrate the lines that build up following a disaster at gas stations in order to get gas for home generators. The simulation not only demonstrates the behavior of the simulated community, but allows the user to experiment with how often the station is open and controling the amount of fuel each home gets.


## HOW IT WORKS

The program works by generating a random neighborhooh filled with agents who have generators that need gasoline to function. The agents are initiated with some quantity of gas.  Once the agent reaches a critically low point he can decide to go to the gas station. For this simulation, there is only one gas station with a limited amount of gas. The agents have to move through the neighborhood to get to the station and wait in line to get fuel. If the agent's home is without for too long the home becomes unlivable and the agent leaves the simulation.  This is representative of the home experiencing issues such as flooding, pipes bursting, or over heating, like one would experience with a long term loss of power. Below is a brief definition of each of the variables used in the program:

Number of Buyers:  this is the number of homes that are in the world that will utilize the gas station.

Gas Needed Per Day: this is the average amount of gas that the house holds needs to run the generator for the entire day.  This is variable, but the default setting of 15 is based on how much an average portable generator needs to run for an entire day.

Pump Time: for this model the time required to fill up at the gas station can be varied but once chosen is the same for all agents.  This was measured based on the regulation that the maximum flow rate regulated by the US is 10 gallons per min.

Hours Open Per Day:  How many hours a day the gas station is open.  The hour count starts at 0 but is offset such that the day begins when the station opens.

MaxHoursWOGas: This is the maximum number of hours an agent can be without gas before the house cannot be saved and the agent leaves the simulation.

Quantity Control:  Quantity Control is either on or off.  If it is ‘off’ the agents are only capable of filling up as much gas as their containers allow.  However, if Quantity Control is ‘on’ the user can control how much gas the agents get using the Gas Quantity slider.

Gas Quantity: This controls how much gas each of the agents get.  This would simulate the gas being rationed in some manor and each of the agents gets the defined amount of gas per day.  This variable assumes that each agent has the means to get that quantity of gas and that they are not limited by container size.

The buyers are defined by a number of variables.  They include:

AmountOfGas:  This shows the amount of gas each agent has.  When the program begins each agent is given some initial amount of gas.  This was based on the fact that some home will have a small supply of gas in their position before a storm.  Things such as lawn tractors/lawn equipment will require homes to keep some small supply of gas giving the agent an initial amount.  Once the simulation starts with each tick the appropriate amount of gas is used by the agent and subtracted from the total amount held by the agent.  Gas is removed until the agent has zero gas at which point the variable TimeWOGas is activated.

lowGas?: When the agent has more than 4 gallons of gas this variable is False. Once the AmountOfGas drops below 4 gallons, this variable is switched to True and the agent tries to go get gas from the station.

Container:  This is the size of the container(s) the agent has available to collect gas in.  Typical gas containers range between 1 and 5 gallons of which people typically only have 1 or 2 of any container type.  Therefore, the container size assigned to each agent was a normal distribution around 5 gallons, some agents have more container space, others less.

HomeX and HomeY:  This is the location of the agents home, they use these variables to return home after getting gas at the station.

buyerCount: This is the amount of time each buyer spends at the pump, it is defined by the user as (PumpTime) and can range between 1 and 10 mins but remains consistent for each agent regardless of the amount of gas they are receiving.  The buyerCount variable keeps the agent at the pump for the specified amount of time and prevents other agents from walking up to the pump.

TimeWOGas:  This is the time without gas.  This variable is only activated once the agent reaches zero gallons of gas.  This variable is related to the user defined variable Max_HoursW/OGas.  TimeWOGas keeps track of the amount of time the agent does not have gas, if the Max_HoursW/OGas is reached the agent leaves the simulation.  If the agent is able to get gas before the max value is reached TimeWOGas is reset at zero.

WaitTime: This tracks how long the agent is waiting to get gas.  This variable is used to get an average wait time for the agents.

The stations have their own variables.  They are:

GasAtStation:  This is the amount of gas that the station has available. It decreases every time someone fills up at the station.

HasGas?:  This variable checks to see if the station has gas for the buyers to get.

isOpen?:  This is determines if the gas station is open or not.  The amount of time the station is open per day is defined by the user using HoursOpenPerDay.

StationX and StationY:  This is the location of the station, for this simulation it is always 0, 0.  However, if the code is expanded and multiple stations are run StationX, StationY will define the direction the agent needs to move.

The global variables that the model uses are:

TimeCounter:  This keeps track of the time in a 24 hour period, mostly used to determine if the gas station is open or not.

HourCount:  The simulation is run in minutes this turns the minutes into hours which are displayed on the user interface.

GasPerHour: This takes the amount of gas needed per day and breaks it down into the amount of gas is needed per hour.

numberOfStations: This variable is a place holder for the number of stations in the simulation.  The current model uses only one station, but this variable will be used if more than one station is wanted in the model.  The set up would populate the stations randomly in the world.

AvgContainerSize: The average container size for the agent.  The agents are then assigned a container based on a normal distribution around this value.

TimeToDie: Checks if the Buyer has exceeded the Max_HoursW/OGas value, if so the Buyer leaves the simulation.

AvgWaitTime: Used to calculate the average wait time.
BuyersNeedingGas: Keeps track of the number of buyers needing gas.


## HOW TO USE IT

To use the model click ‘Default’, then ‘Setup’ and then ‘Go’.  This will run the model using a set of default variables.  The user can also vary many parameters in the model by adjusting the sliders. Additionally, there is a On/Off switch on Quality_Control.  This must be turned on in order to activate the GasQuantity Slider.  As explained above, this variable replaces container size when used.  Once the parameters are adjusted, click ‘Setup’; the world will repopulate according to the new parameters and the simulation can be run!


## THINGS TO NOTICE

When using the default parameters, notice how after an initial loss in homes, the waiting time reaches a steady state with the remaining population. Also notice the number of homes that remain in the steady state.


## THINGS TO TRY

(1) Try adjusting the hours of operation of the Gas Station.  Does this help with the wait times?
(2) Try adjusting the amount of gas each agent gets.  Is there an amount that will allow all agents to remain in the simulation for longer? How does this affect the long run?


## EXTENDING THE MODEL

There are several ways to extend this model. Here are a couple:
(1) Add a variable that will allow the Gas Station to be refueled.  This could be at a set interval (such as every 10 days) or it could be user defined.
(2) Allow the world to have multiple stations.  Increasing the number of stations could allow the agents a choice of stations based on proximity to their home, or maybe depending on wait times.
(3) Change the number of working pumps at the station.  This could be implemented in many ways.  What has been seen after major storms there is often one or two pumps dedicated to ‘walk-up’ buyers.  The current simulation only looks at using one pump at the station.  The model could be extended to add a second pump for walk up buyers as well as adding the vehicle pumps and vehicles to the simulation.
(4) Try mapping a real neighborhood. Use Netlogo to import a map of a neighborhood, this should help when the agents are moving to the gas station, having predefined streets can help avoid agents getting ‘stuck’ in clusters of houses.


## NETLOGO FEATURES

Note the section of code used to determine the container size for each of the agents.  This was used to simulate a normal distribution around the average container size.  The average container size was hard coded into the model, but could be made a variable if desired.


## CREDITS AND REFERENCES

The following references and tools were used to create this model:
•	Wilensky, U. (1997). NetLogo AIDS model. http://ccl.northwestern.edu/netlogo/models/AIDS. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
•	McBride, Mark E. (2008). ZITrading-V504. http://mcbridme.sba.muohio.edu/ . Department of Economics, Miami University, Oxford, OH.
•	Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
