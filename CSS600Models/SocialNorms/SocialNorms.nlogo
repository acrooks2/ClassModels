globals
[
  year
  giniindexreserve
  lorenzpoints
  total                        ;;; sum [endowment] of turtles
  id
  my-neighbours                ;;; number of neighbors in my sight
  topone
  topfive
  topten
  botforty
  singleone
  singlefive
  singleten
  singlebottwenty
]

turtles-own
[
  endowment                    ;;; wealth of individual
  wage                         ;;; real wage, normalized to 1 and normally distributed
  consumption                  ;;; saving a portion of wage
  productivity                 ;;; individual's productivity level
  labor-hour                   ;;; Total available time, normalized to 1
  labor-supply
  income                       ;;; wage * productivity * labor supply
  married?                     ;;; no same-sex marriage
  potential-partner
  potential-fiance
  propose?
  proposed?
  partner                      ;;; spouse
  mar-yr                       ;;; how long you have been married
  generation                   ;;; generation of a family
  age
  inheritance                  ;;; amount of wealth parents give to their children
  familyid                     ;;; siblings have the same id
  gdp
]

breed [ people person ]


;;;
;;; SETUP PROCEDURES
;;;

to setup
  clear-all
  set year 0
  set id 0
  set-default-shape people "person"
    create-people initial-population [
      setxy random-xcor random-ycor
      set generation 0
      ifelse a-few-smarter? [
      set productivity random-gamma 2 2 ]                             ;;; if ON, a few will be much more productive than the rest
      [ set productivity random-normal 1 0.1 ]                        ;;; if OFF, individual will be most likely as productive as others, normalized to 1
      set endowment random-normal 1 0.3
      set age random-normal 25 1
      set-initial-var                                                 ;;; assign initial values to agents
      set familyid id
      set id id + 1
    ]
  gini-lorenz-plots
  reset-ticks
end

to set-initial-var
  set age random-normal 25 1
  set mar-yr 0
  set wage random-normal 1 0.1
  set labor-hour 1                                            ;;; leisure + labor supply = 1, here leisure = 0
  set labor-supply labor-hour * productivity
  set income wage * labor-supply
  set gdp endowment
  set consumption ((random-normal consumption-rate 0.2 ) * income)
  set married? false
  set potential-partner nobody
  set potential-fiance nobody
  set partner nobody
  set propose? false
  set proposed? false
  set color blue
  ifelse random 2 = 0
  [ set color blue ]
  [ set color pink ]
end

to go
  set year year + 0.25
  ask turtles [
    set age age + 0.25
    death
  ]
  ask turtles [
    ifelse not married? [
      search ]
     [ set mar-yr mar-yr + 0.25 ]
    ]
  ask turtles [
    if proposed? [
      acceptance
      ]
  ]
  earning
  produce
  average-wealth-plots
  gini-lorenz-plots
  tick
end

;;; you can't live forever
to death
  if not married? and age > 80 [       ;;  average in america
    die ]
end

;;; looking for a mate
to search
  setup-neighbours
  rt random-float 360
  fd 1
  set endowment (endowment - (income * 0.1))                          ;;; why 0.1?
  if color = blue [
     propose
   ]
end

;;; making money
to earning
  ask turtles [
    set endowment endowment + (income - consumption)
    set gdp gdp + income
  ]
end

;;; I see you
to setup-neighbours
  ifelse circle-or-rectangle-view? [
    set my-neighbours (patch-set patches in-radius i-can-see-you) ]
  [ set my-neighbours (patch-set patches with [
      (pycor <= [ycor] of myself + i-can-see-you)
      and
      (pycor >= [ycor] of myself - i-can-see-you)
      and
      (pxcor <= [xcor] of myself + i-can-see-you)
      and
      (pxcor >= [xcor] of myself - i-can-see-you) ] )
  ]
end

;;; would you marry me
to propose
  let potential-partners turtles-on my-neighbours
  ifelse age <= 35 [
    ifelse i-care-her-wealth? [
      set potential-partner one-of potential-partners with [
        not married? and color = pink and familyid != [familyid] of myself
        and (age > [age] of myself - i-do-not-care-spouse's-age)
        and (age < [age] of myself + i-do-not-care-spouse's-age)
        and (endowment >= [endowment] of myself * (1 - (1 * (i-care-but-little-less / 100 ))))                                                  ;;; marry to one who is richest among ladies around me
      ]
    ]
    [ set potential-partner one-of potential-partners with [
      not married? and color = pink and familyid != [familyid] of myself
      and (age > [age] of myself - i-do-not-care-spouse's-age)
      and (age < [age] of myself + i-do-not-care-spouse's-age)
    ]
   ]
  ]
  [ set potential-partner one-of potential-partners with [
    not married? and color = pink and familyid != [familyid] of myself
  ]
  ]
  if potential-partner != nobody [
    set propose? true
  ask potential-partner [
    set proposed? true
  ]
  ]
end

;;; I will
to acceptance
  let potential-fiances turtles with [ potential-partner = myself ]
  ifelse potential-fiances != nobody [
    let one max [endowment] of potential-fiances
    ifelse i-love-rich-guy? [
      set potential-fiance one-of potential-fiances with [
        not married? and color = blue and familyid != [familyid] of myself and endowment >= one ]
    ]
    [ set potential-fiance one-of potential-fiances with [
      not married? and color = blue and familyid != [familyid] of myself ]
    ]
    if potential-fiance != nobody [
      set partner potential-fiance
      set married? true
      ask partner [ set married? true ]
      ask partner [ set partner myself ]
      ask partner [ move-to myself]
      move-to patch-here                                                                                 ;;; move to center of patch
      move-to patch-here                                                                                 ;;; partner moves to center of patch
      set pcolor gray - 3
      ask patch-here
      [ set pcolor gray - 3
      ]
    ]
  ]
  [ search ]
end

;;; I want babies
to produce
  ask turtles with [ color = pink ] [ if mar-yr > 35
    [ offspring
      die ]
    ]
  ask turtles with [color = blue ] [if mar-yr > 35 [
    die ]
  ]
end

;;;bequest
to offspring
  set generation generation + 1
  set inheritance ((endowment + [endowment] of partner) / 2)
  set endowment inheritance
  ifelse inherit-productivity? [
    let old-productivity ((productivity + [productivity] of partner) / 2)
    set productivity random-normal old-productivity 1]
  [ set productivity random-gamma 2 2 ]
  ifelse random-reproduction? [
  hatch random-normal how-many-children-you-want 0.3 [
    rt random-float 360
    fd 1
    set-initial-var
    set familyid id
    set id id + 1
      ] ]
  [ hatch how-many-children-you-want [
      rt random-float 360
      fd 1
      set-initial-var
      set familyid id
      set id id + 1 ]
  ]
  set pcolor black
end

;;; income share
to-report top-1%
  let one sum [endowment] of max-n-of ((count turtles) * 0.01) turtles [endowment]
  set total sum [endowment] of turtles
  report (one / total) * 100
end

to-report top-5%
  let five (sum [endowment] of max-n-of ((count turtles) * 0.05) turtles [endowment])
  report (five / total) * 100
end

to-report top-10%
  let ten (sum [endowment] of max-n-of ((count turtles) * 0.1) turtles [endowment])
  report (ten / total) * 100
end

to-report bottom-40%
  let twenty sum [endowment] of min-n-of ((count turtles) * 0.4) turtles [endowment]
  report (twenty / total) * 100
end

;;; average wealth
to average-wealth-plots
  let sortedwealth sort-by > [endowment] of turtles
  let top-one item (count turtles * 0.01) sortedwealth
  let top-five item (count turtles * 0.05) sortedwealth
  let top-ten item (count turtles * 0.10) sortedwealth
  let bot-forty item (count turtles * 0.60) sortedwealth
  let one sum [endowment] of max-n-of ((count turtles) * 0.01) turtles [endowment]
  let five (sum [endowment] of max-n-of ((count turtles) * 0.05) turtles [endowment])
  let ten (sum [endowment] of max-n-of ((count turtles) * 0.10) turtles [endowment])
  let forty sum [endowment] of min-n-of ((count turtles) * 0.4) turtles [endowment]
  let num-one count turtles with [endowment >= top-one ]
  let num-five count turtles with [endowment >= top-five]
  let num-ten count turtles with [endowment >= top-ten]
  let num-botforty count turtles with [endowment <= bot-forty ]
  if num-one != 0 [
    if num-five != 0 [
      if num-ten != 0 [
        if num-botforty != 0 [
          set topone (one / num-one)
          set topfive (five / num-five)
          set topten (ten / num-ten)
          set botforty (forty / num-botforty)
        ]
      ]
    ]
  ]
end

;;; plotting the Lorenz curve
to gini-lorenz-plots ;; borrowed from Wealth Distribution model
  let sorted-endowment sort [endowment] of turtles
  let total-endowment sum sorted-endowment
  let endowmentsumsofar 0
  let index 0
  set giniindexreserve 0
  set lorenzpoints []

  ;; now actually plot the Lorenz curve -- along the way, we also
  ;; calculate the Gini index.
  ;; (see the Info tab for a description of the curve and measure)
  repeat count turtles [
    set endowmentsumsofar (endowmentsumsofar + item index sorted-endowment)
    set lorenzpoints lput ((endowmentsumsofar / total-endowment) * 100) lorenzpoints
    set index (index + 1)
    set giniindexreserve
    giniindexreserve +
    (index / count turtles) -
    (endowmentsumsofar / total-endowment)
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
753
25
1141
414
-1
-1
11.52
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

SLIDER
9
25
209
58
initial-population
initial-population
1000
10000
1000.0
1000
1
NIL
HORIZONTAL

BUTTON
9
195
72
228
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
75
195
138
228
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

PLOT
482
25
751
171
wealth distribution
wealth
frequency
-1000.0
5000.0
0.0
15.0
false
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [endowment] of turtles"
"x0" 1.0 0 -2674135 true "plot 0\nplot 100" ""

PLOT
482
173
751
320
average wealth
top1%   top5%   top10%   bot40%    total
saving
0.0
5.0
0.0
10.0
true
false
"" ""
PENS
"average" 1.0 1 -16777216 true "" "plot-pen-reset\nset-plot-pen-color blue\nplot topone\nset-plot-pen-color green\nplot topfive\nset-plot-pen-color violet\nplot topten\nset-plot-pen-color red\nplot botforty\nset-plot-pen-color black\nplot (sum [endowment] of turtles) / count turtles"

MONITOR
1145
213
1245
258
average wealth
sum [endowment] of people / count people
3
1
11

SLIDER
9
59
209
92
consumption-rate
consumption-rate
0.5
0.95
0.7
0.05
1
NIL
HORIZONTAL

PLOT
211
173
480
320
Lorenz Curve
population %
wealth %
0.0
100.0
0.0
100.0
false
false
"" ""
PENS
"equal" 100.0 0 -16777216 true "plot 0\nplot 100" ""
"Lorenz" 1.0 0 -2674135 true "" "plot-pen-reset\nset-plot-pen-interval 100 / count turtles\nplot 0\nforeach lorenzpoints plot"

PLOT
211
322
480
466
GINI coefficient
quarter
gini index
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -10899396 true "" "plot (giniindexreserve / count turtles) / 0.5"

PLOT
482
322
751
466
Income share
top1%        top5%       top10%   bot 40%
share %
0.0
4.0
0.0
10.0
true
false
"" ""
PENS
"pen-1" 1.0 1 -7500403 true "" "plot-pen-reset\nset-plot-pen-color blue\nplot top-1%\nset-plot-pen-color green\nplot top-5%\nset-plot-pen-color violet\nplot top-10%\nset-plot-pen-color red\nplot bottom-40%"

MONITOR
1145
72
1245
117
population
count turtles
3
1
11

PLOT
211
25
480
171
age distribution
age
frequency
20.0
100.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [age] of turtles"

TEXTBOX
11
10
161
28
initial setup
11
0.0
1

SLIDER
9
331
209
364
i-do-not-care-spouse's-age
i-do-not-care-spouse's-age
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
9
433
209
466
how-many-children-you-want
how-many-children-you-want
1
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
9
161
209
194
i-can-see-you
i-can-see-you
1
32
32.0
1
1
patch-far
HORIZONTAL

BUTTON
141
195
209
228
go once
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
1145
166
1245
211
aggregate wealth
sum [endowment] of people
3
1
11

SWITCH
9
93
209
126
a-few-smarter?
a-few-smarter?
0
1
-1000

SWITCH
9
229
209
262
i-love-rich-guy?
i-love-rich-guy?
0
1
-1000

SWITCH
9
263
209
296
i-care-her-wealth?
i-care-her-wealth?
0
1
-1000

SLIDER
9
297
209
330
i-care-but-little-less
i-care-but-little-less
0
100
0.0
10
1
NIL
HORIZONTAL

MONITOR
1145
119
1245
164
gini index
(giniindexreserve / count turtles) / 0.5
3
1
11

MONITOR
1145
25
1245
70
year of
year
3
1
11

SWITCH
9
365
209
398
inherit-productivity?
inherit-productivity?
0
1
-1000

SWITCH
9
127
209
160
circle-or-rectangle-view?
circle-or-rectangle-view?
0
1
-1000

SWITCH
9
399
209
432
random-reproduction?
random-reproduction?
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This model simulates the accumulation of wealth over generations.  In this simulation, we see if individual will accumulate more wealth if one marries to someone whose social rank measured by one's relative wealth level than if one marries to whoever individual wants to.

## HOW IT WORKS

This model is adapted from Cole, Mailath, and Postlewaite's marriage model.  Each individual earn, spend, and save according to their respectively-assigned amount of money.  The saving will be her accumulated wealth.

Initially, individual is almost identical to each other but has skewed-to-the-right productivity level.  It means a few will be more productive than the rest.  Then, they wander around to find one's suitable fiancé. If one finds the mate, they will stay where bride is and form a family.  They no longer move around but still earn, spend, and save money. Once they live together up to a certain amount of time, they will have children who are 25-year-old on average for simplicity.  Parents will split the wealth equally and give it to thier children and die.  The next generation will do the same thing over.  At this time not only respective productivity varies, but also respective wealth will be different.

There are various graphical tools to observe the accumulation and distribution of wealth.  For example, GINI index and Lorenz curve represent the inequality in this society.  Lower GINI index and closed-to-the-diagonal Lorenz curve exhibit higher equality.

## HOW TO USE IT

The A-FEW-SMARTER? switch determines the distribution of individual's productivity level. If it is OFF, it means people will have similar level of productivity. If ON, a few will have really higher productivity level than others.

The I-LOVE-RICH-GUY? switch shows whether ladies are interested in her mate's accumulated wealth. Once they are proposed, they will choose the richest guy if it is ON and anyone if it is OFF.  The I-CARE-HER-WEALTH? does the same thing for gentlemen.  If ON, he will look for a girl whose wealth is higher than his criteria level and who is around him. If OFF, literally, he doesn't care about it.  I-CARE-BUT-LITTLE-LESS will choose how much male does not care about his wife's wealth in a range of 0 to 100.


I-DO-NOT-CARE-SPOUSE'S-AGE creates the band of age limit when one is looking for his mate.  I-CAN-SEE-YOU means that how far individual can see other agents around me. For instance, if it is 4, then I can see any agents in 4-by-4 square box which center is my location.  INHERIT? switch determines if children's productivity is in the range of normal distribution with s.d of 1 and mean of the average productivity of parents.

The INITIAL-POPULATION will generates the initial number of people.
The CONSUMPTION-RATE shows how much portion of income individual will spend.  HOW-MANY-CHILDREN-YOU-WANT determines how many children a couple will have.  If RANDOM-REPRODUCTION switch is on, agents will produce a normally distributed number of children with mean of the number you have chosen previously.

Once you set up the model as you want to, hit GO button and see what happen.  Income share plot shows top 1%, top 5%, top 10%, and bottom 40%'s income shares.  Average wealth plot displays their respective average wealth.  Lorenz curve and GINI index shows the inequality of wealth in this society and are updated every tick.


## THINGS TO NOTICE

See if individuals have more average wealth if they care about spouse's wealth.
See how the inequality changes once individual's preference on marriage changes.

Go to U.S. Government Census Bureau and find U.S.'s GINI coefficient and income share.
Is what you see in the model comparable to the real data?

## THINGS TO TRY

Change the consumption rate; does it affect the outcome?
Try to make individual's productivity similar to each other by turning off A-FEW-SMARTER switch. Does it matter?
Try to increase I-CARE-BUT-LITTLE-LESS. Will it increase the aggregate and average wealth?
Try to vary individual's vision range.  What would be reasonable?

## EXTENDING THE MODEL

In this model, individual's only cares about wealth; u(i) = level of wealth.  However, this is not realistic.  Individual, in reality, cares about her wealth and leisure.  Therefore, individual must spend a portion of her available time to take a break and work on the rest of her available hours.  As we impleemnt leisure in this model, we could find out individual's labor supply over time and over wealth as well and confirm the economic labor supply theory.

## NETLOGO FEATURES

TBA

## RELATED MODELS

Go to Library, under Social Science, try Wealth Distribution, or under Sugarscape, try Sugarscape 3 Wealth Distribution.

## CREDITS AND REFERENCES

This model is based on the model described in Cole, Harold L., George J. Mailath, and Andrew Postlewaite. "Social Norms, Savings Behavior, and Growth." Journal of Political Economy 100.6 (1992): 1092. Print.

## HOW TO CITE

TBA
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
  <experiment name="experiment" repetitions="50" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>count turtles</metric>
    <metric>sum [endowment] of turtles / count turtles</metric>
    <metric>sum [endowment] of turtles</metric>
    <metric>sum [gdp] of turtles / count turtles</metric>
    <metric>sum [gdp] of turtles</metric>
    <metric>sum [income] of turtles / count turtles</metric>
    <metric>sum [income] of turtles</metric>
    <metric>sum [consumption] of turtles</metric>
    <metric>sum [consumption] of turtles / count turtles</metric>
    <enumeratedValueSet variable="i-care-but-little-less">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="i-care-her-wealth?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="random-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="a-few-smarter?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="how-many-children-you-want">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="inherit-productivity?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="consumption-rate">
      <value value="0.7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-population">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="i-love-rich-guy?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="i-can-see-you">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="i-do-not-care-spouse's-age">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="circle-or-rectangle-view?">
      <value value="true"/>
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
