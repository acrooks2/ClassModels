globals
[
  normal
  mean-blue
  mean-yellow
  mean-orange
  mean-year-blue
  mean-year-yellow
  mean-year-orange
]

turtles-own
[
  Firm1                 ;; If true, the person is blue
  Firm2                  ;; If true, the person is yellow or orange
  value               ;; Every agent starts with $0 and gets random amount based on month
  friends             ;; an agent set of all your friends
  groupID             ;; pairs of agents in Firm2
  sales
  income
  income0             ;;last years income
  yearly-income
  points              ;;learning rate

]


to setup
  clear-all

  setup-Firm2
  setup-Firm1
  ask turtles [set shape "person" set sales 0 set income 0]
  move-turtles
  reset-ticks
end

to go
  ask turtles [set income0 income]
  interact
  earn
  get-average
  tick
end

to move-turtles
  ask turtles [
    ifelse color = blue [setxy random 17 (-16 + random 32)][setxy (-1 * random 17) (-16 + random 32)]
  ]
end


to setup-patches
  ask patches [ set pcolor black ]
end

to setup-Firm1
  let num count turtles with [color = yellow or color = orange]
  crt num [set color blue fd random 5 ]
end

to setup-Firm2
  let i 1
  crt 50 [set color yellow ]



  ask turtles with[color = yellow] [
          set i i + 1

          ask patch-here [sprout 1 [    ;;refer 1 person
            set color orange fd random 10
            set groupID i]]

          set friends turtles with [groupID = i]

          fd random 10
              ]




end

to interact

  ask turtles with [color = yellow][
    let interactions random number-of-interactions
    set income income + interactions * 635
    ask friends [set points points + random 9]
  ]

  ask turtles with [color = orange][
    if points >= 8 [set income income + 635 set points points - 9]]
end

to earn
  ask turtles [
   ifelse GoodYear? [set sales random-normal (14177 * num-of-sales-GoodYear) 5000][set sales random-normal (14177 * num-of-sales-BadYear)  5000]]

  ask turtles with [color = blue][
    ifelse sales > 18000
    [set income income + ((sales - 18000) * 0.9 + 18000 * 0.5 )]
  [set income income + 0.5 * sales]]

  ask turtles with [color = yellow or color = orange][set income income + 0.64 * sales]


end



to get-average
  let list-blue []
  let list-yellow []
  let list-orange []

  ask turtles with [color = blue][set list-blue lput income list-blue]
  ask turtles with [color = yellow][set list-yellow lput income list-yellow]
  ask turtles with [color = orange][set list-orange lput income list-orange]

  set mean-blue mean list-blue
  set mean-yellow mean list-yellow
  set mean-orange mean list-orange

  ask turtles [set yearly-income income - income0]

  set list-blue []
  set list-yellow []
  set list-orange []

  ask turtles with [color = blue][set list-blue lput yearly-income list-blue]
  ask turtles with [color = yellow][set list-yellow lput yearly-income list-yellow]
  ask turtles with [color = orange][set list-orange lput yearly-income list-orange]

  set mean-year-blue mean list-blue
  set mean-year-yellow mean list-yellow
  set mean-year-orange mean list-orange




end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
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
-16
16
-16
16
0
0
1
years
30.0

BUTTON
16
19
80
52
Setup
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
102
18
165
51
Go
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
16
131
73
176
Firm1
count turtles with [color = blue]
17
1
11

MONITOR
93
130
150
175
KW
count turtles with [color = yellow or color = orange]
17
1
11

PLOT
675
18
875
168
Average Income
Years
Income
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plot mean-blue"
"pen-1" 1.0 0 -1184463 true "" "plot mean-yellow"
"pen-2" 1.0 0 -955883 true "" "plot mean-orange"

MONITOR
674
345
813
390
Firm2-OLD-INCOME
mean-yellow
0
1
11

BUTTON
104
69
167
102
NIL
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
795
345
934
390
Firm2-NEW-INCOME
mean-orange
0
1
11

MONITOR
673
407
780
452
L&F
mean-blue
0
1
11

PLOT
677
178
877
328
Average Income this Year
Years
Income
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -14070903 true "" "plot mean-year-blue"
"pen-1" 1.0 0 -1184463 true "" "plot mean-year-yellow"
"pen-2" 1.0 0 -955883 true "" "plot mean-year-orange"

SLIDER
6
215
183
248
number-of-interactions
number-of-interactions
0
50
25.0
1
1
NIL
HORIZONTAL

SWITCH
15
383
131
416
GoodYear?
GoodYear?
0
1
-1000

SLIDER
6
269
186
302
num-of-sales-GoodYear
num-of-sales-GoodYear
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
9
323
181
356
num-of-sales-BadYear
num-of-sales-BadYear
0
10
1.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This agent-based model intends to compare two real estate commission policies by examining the motivation of agents in two companies. The motivation of agents is set based on their income. Both firms follow the 3% break down of the settlement price of property. The difference is observed in the intercompany commission split. Firm 1 rewards its realtors by changing the 50%-50% split into 90%-10% when the agents reach $18,000 in commission. Firm 2 rewards its realtors by setting a higher share of 64%-46% for them and applying a ‘profit sharing’ method. The significance of this model is that it compares two strategies in a competitive field, allowing for a clearer and fact based decision making for realtors and an understanding of realtors’ financial incentive for clients.

## HOW IT WORKS

This model, includes two types of agents: firm 1 (blue) and firm 2 (yellow and orange). Firm 1 has 100 agents and firm 2 has two sets of 50 agents that are paired and interact with one another. As mentioned in the assumptions, firm 2 has endorsers and endorsees whose interactions effect their income. All agents are setup to begin with $0 income and no sales. Then an amount of commission earning is randomly distributed among them based on the average commission data. This distribution range is different in good and bad years. All agents have sales, income, earn and yearly income as their variables. In addition to these, firm 2 also has friends, group ID and points as its defining variables. The friend variable determines the random pairing of firm 2 agents to interact in groups. Every group has an ID and consists of one endorser (yellow) and one endorsee (orange). The model allocates a random number of interactions between 0 and 9 and counts every time the agents with the same group ID interact. Every interaction adds two points to the endorsee and every 8 interaction adds $635 to the endorsee’s income. Every time the endorsee makes a transaction, the endorser is compensated $200 by the company.
The implementation of our assumptions, variables, rules and interactions can be observed in the model through the behavior of agents. All the commands coded in the model are ultimately calculated by the ‘get-average’ function. This function gets the average cumulative income and the average income this year of all agents in both firms. The get-average functions through the global variables calculating the mean and mean per year of all agents in each firm.


## HOW TO USE IT

the setup button does the following commands in order: clear-all, setup-KW, setup-L&F, ask turtles [set shape "person" set sales 0 set income 0], move-turtles, reset-ticks.
The Go button does the following commands in order: ask turtles [set income0 income], interact, earn, get-average, tick.
The number-of-interaction slider sets the number of interactions between yellow and orange agents.
The sliders num-of-sales-GoodYear and num-of-sales-BadYear set the number of sales in good and bad years for all the 200 agents.
The GoodYear? switch determines the range of commissions to be distributed based on a good or bad year.
The plots show the average cumulative income and average income for this year for all the agents of every firm.
The monitors KW-OLD-INCOME, KW-NEW-INCOME and L&F demonstrate the exact amount earned by every agent set.

## THINGS TO NOTICE

The model is partially build based on real world data and partially (profit sharing details) created.

## THINGS TO TRY

Play with the parameters to see the different outcomes. Change the commission splits to see the effect of the change.

## EXTENDING THE MODEL

Although this model demonstrates a targeted comparison between two real estate commission policies, it can be extended to resonate the reality much more. By adding new interactions, parameters and defining the environment to the code, the model can expand to produce even more realistic data. If we introduce ability, effort, work hours and personality types to the model as new parameters, we can systematically measure motivation, productivity and satisfaction. Performance can be defined as a product of agent ability, effort and work hours. By gathering data on the definition of average performance in firms, we can calculate the overall productivity of agents. The agent productivity can act as the indicator of motivation and satisfaction. Personality types of agents can be introduced in groups of hard working and lazy and randomly distributed. Personality types will affect the performance of agents and therefore change the income results. Creating a social network model will help us understand the agent relationships, interactions and influences more specifically.

## NETLOGO FEATURES
The pairing of yellow and orange agents after breeding the orange agents is an interesting feature.

## RELATED MODELS

Not determined!

## CREDITS AND REFERENCES

Housing Statistics. (n.d.). Retrieved 2015, from http://www.mdrealtor.org/ResearchStats/HousingStatistics.aspx

Keller Williams Realty: The Commission Structure - Real Estate Careers at Keller Williams Realty. (n.d.). Retrieved 2015, from http://moving-careers.com/keller-williams-realty-the-commission-structure/

Montgomery County Home Sales Statistics. (n.d.). Retrieved December 18, 2015, from https://gcaar.com/toolkit_ektid2030.aspx

Real Estate Sales Agents. (n.d.). Retrieved December 18, 2015, from http://www.rileyguide.com/careers/real-estate-agents.shtml

Wise, C. (1997, March 1). Unbundling Services for Salespeople. Retrieved December 18, 2015, from http://realtormag.realtor.org/for-brokers/feature/article/1997/03/unbundling-services-for-salespeople
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
  <experiment name="experiment" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1"/>
    <metric>mean-year-blue</metric>
    <metric>mean-year-yellow</metric>
    <metric>mean-year-orange</metric>
    <enumeratedValueSet variable="number-of-interactions">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="GoodYear?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-sales-BadYear">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-sales-GoodYear">
      <value value="2"/>
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
