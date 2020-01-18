globals [

 value-threshold
]

turtles-own [
  aware-of-cause?    ;; If true, the person is aware of the issue.
  contributed?       ;; If true, the person has contributed to the cause.
  my-social-pressure-adjusted? ;;If true, the agent has been peer pressured to participate more than initially.
  participated?
  altruistic?
  my-small-budget?
  myaction
  my-dollar-donation
  my-number-donations
  my-number-linkshares
  my-number-participations
  my-number-friends
  ;; the next three values are controlled by sliders
  my-perceived-value-of-cause     ;; the perceived social value of the cause on average.
  my-contribution-budget          ;; the amount that a person is willing to give in time and money.
  my-social-pressure-threshold    ;; the number of friends who have to participate in order to increase contribution budget.
  ;; the following is a calculated variable based on double the contribution budget for agents with small contribution budgets
  my-max-contribution-budget      ;; the max amount that a person is willing to give in time and money including potential for social pressure
]

;;;
;;; SETUP PROCEDURES
;; Begin by clearing the domain and reseting all ticks.
;; Set up the preferential attachment network with setup-pa
;;;

to setup
   clear-all
   setup-pa
   reset-ticks
end



;;This code is borrowed heavily from the 'Preferential Attachment' (PA) model in the model library.
;; We use the preferential attachment network because it models real life social networks, where
;; a few people are very popular and a lot are not as popular.

;; This sets up the PA model.
to setup-pa
  set-default-shape turtles "person"
  make-node nobody
  make-node turtle 0
  repeat number-of-people [go-pa]
  ask turtles [set color white]
  ask links [set color grey]
  setup-personal-attributes
;; Turn a random turtle green, this person is the originator of the charitable cause.
       ask turtle random number-of-people [
         set color green
         set aware-of-cause? true
         set altruistic? true
         ]
end


;; This code finds partners for each person created and creates new nodes.
to go-pa
  ask links [set color gray]
  make-node find-partner
  if layout? [layout]
end

;; This creates new people and connects with old people. Nodes are people in our model.
to make-node [old-node]
  crt 1
  [
    set color red
    if old-node != nobody
    [create-link-with old-node [set color green]
      move-to old-node
      fd 8
    ]
  ]
end

;; This code is borrowed from the Lottery Example in the netlogo Models library.
to-report find-partner
  let total random-float sum[count link-neighbors] of turtles
  let partner nobody
  ask turtles
  [
    let nc count link-neighbors
    if partner = nobody
    [
      ifelse nc > total
      [set partner self]
      [set total total - nc ]
    ]
  ]
  report partner
end

;; The following code is only initiated if the layout button is switched to 'On.'
;; This code resizes the domain so that the entirety of the network can fit in the viewable range.
;; This code is borrowed heavily from the diffusion model, seen at http://ccl.northwestern.edu/netlogo/models/community/diffusion
to resize-nodes
  ifelse all? turtles [size <= 1]
  [
    ask turtles [set size sqrt count link-neighbors]
  ]
  [
    ask turtles [set size 1]
  ]
end

to layout
  repeat 3 [
    let factor sqrt count turtles
    layout-spring turtles links (1 / factor) (7 / factor) (1 / factor)
    display
  ]
  let x-offset max [xcor] of turtles + min [xcor] of turtles
  let y-offset max [ycor] of turtles + min [ycor] of turtles
  set x-offset limit-magnitude x-offset 0.1
  set y-offset limit-magnitude y-offset 0.1
  ask turtles [setxy (xcor - x-offset / 2 ) (ycor - y-offset / 2 ) ]
end

to-report limit-magnitude [number limit]
    if number > limit [report limit]
  if number < (- limit) [report (- limit)]
  report number
end

to setup-personal-attributes  ;; initialize core turtle variables
ask turtles [
      assign-perceived-value
      assign-contribution-budget
      assign-social-pressure-threshold
      set aware-of-cause? false
      set my-social-pressure-adjusted? false
      set contributed? false
      set participated? false
      set my-dollar-donation 0
      set my-number-donations 0
      set my-number-friends count link-neighbors
;; only altruistic people contribute
      set altruistic? (who < number-of-people * (altruistic / 100))
      assign-color ]
end



;; The following three procedures assign core turtle variables.
;; The following code assigns each turtle a "perceived value of cause", which is normal distributed around the user input.
to assign-perceived-value  ;; turtle procedure
  set my-perceived-value-of-cause random-normal average-value-of-cause 1 ; slider between 1 and 10
end

;; Allows the model user to determine whether the relationship between the
;; average value of the cause and the contribution budget is linear (constant
;; increase) or exponential (rapid increase).
to assign-contribution-budget  ;; turtle procedure
  ifelse (how-cause-affects-contribution = "linear")
  [set my-contribution-budget 2 * my-perceived-value-of-cause]
  [set my-contribution-budget exp(my-perceived-value-of-cause)]
;;  if my-contribution-budget < 20 [set my-small-budget? true]
    ifelse my-contribution-budget < 20 [  ;; the contribution budget potentially could be doubled for small contributions
      set my-small-budget? true
      set my-max-contribution-budget 2 * my-contribution-budget]
      [set my-max-contribution-budget my-contribution-budget]
end

;;The following code assigns each turtle a social pressure threshold, which, if reached, causes the turtle to contribute more to the cause.
to assign-social-pressure-threshold  ;; turtle procedure
  set my-social-pressure-threshold random-normal resistance-to-social-pressure 1
end


;; Different people are displayed in 3 different colors depending on activity
;; green is aware and acting
;; blue is not aware
;; red is aware but not contributing

to assign-color  ;; turtle procedure
  ifelse not aware-of-cause?
    [ set color blue ]
    [ ifelse contributed?
      [ set color green ]
      [ set color red ] ]
end

;;;
;;; GO PROCEDURES
;;;

to go
;  if ticks >= 1000 [stop]
  if not any? turtles with [altruistic? and aware-of-cause? and my-contribution-budget > min (list cost-donate-money cost-participation cost-share-link)][ stop ]
  ask turtles with [altruistic? and aware-of-cause?]
  [
    ;; adjust my-contribution-budget based on social pressure
    if (my-small-budget? = true) and not my-social-pressure-adjusted?[
      if(count link-neighbors with [participated?] / count link-neighbors) > (my-social-pressure-threshold / 50)[
      set my-contribution-budget (2 * my-contribution-budget)
      set my-social-pressure-adjusted? true
    ]
    if (count link-neighbors with [contributed?] / count link-neighbors) > (my-social-pressure-threshold / 10) [
      set my-contribution-budget (2 * my-contribution-budget)
      set my-social-pressure-adjusted? true
    ]
    ]

    let mycontributionlist []
    if   cost-share-link < my-contribution-budget [set mycontributionlist fput "sharelink" mycontributionlist]
    if   cost-donate-money  < my-contribution-budget [set mycontributionlist fput "donatemoney" mycontributionlist]
    if   cost-participation < my-contribution-budget [set mycontributionlist fput "participate" mycontributionlist]
    if not empty? mycontributionlist ;; decide what action to take
    [
    set myaction one-of mycontributionlist
    set contributed? true
    set color green
    take-action
    ] ;; end decide action
     ] ;; end ask turtles
      tick
 end

to take-action  ;; turtle procedure
    If myaction = "sharelink" [
     share-link
    ]
    If myaction = "donatemoney" [
     donate-money
    ]
    If myaction = "participate" [
     participate
    ]
end


to share-link
    set my-contribution-budget my-contribution-budget - cost-share-link
     set my-number-linkshares my-number-linkshares + 1
     ask link-neighbors with [aware-of-cause? = false] [
        set aware-of-cause? true
        set color red
        ]
end

to donate-money
    set my-contribution-budget my-contribution-budget - cost-donate-money
    set my-dollar-donation my-dollar-donation + cost-donate-money
    set my-number-donations my-number-donations + 1
end

to participate
    set my-contribution-budget my-contribution-budget - cost-participation
    set participated? true
    set my-number-participations my-number-participations + 1
end


;;;
;;; MONITOR PROCEDURES
;;;

to-report %aware
  report (count turtles with [aware-of-cause?] / count turtles) * 100
end

to-report %donated
  report (count turtles with [my-number-donations > 0] / count turtles) * 100
end

to-report %social-pressure
  report (count turtles with [my-social-pressure-adjusted?] / count turtles) * 100
end

to-report $donated
    report sum [my-dollar-donation] of turtles
end

to-report #donations
    report sum [my-number-donations] of turtles
end
to-report #link-sharing
    report sum [my-number-linkshares] of turtles
end
to-report #participations
    report sum [my-number-participations] of turtles
end
to-report ave-contribution-budget
 report sum [my-contribution-budget] of turtles with [altruistic? and aware-of-cause?] / count turtles with [altruistic? and aware-of-cause?]
end
to-report max-contribution-budget
 report sum [my-max-contribution-budget] of turtles with [altruistic? and aware-of-cause?]
end
to-report %participated
  report (count turtles with [participated?] / count turtles) * 100
end
@#$#@#$#@
GRAPHICS-WINDOW
329
12
762
446
-1
-1
17.0
1
10
1
1
1
0
1
1
1
-12
12
-12
12
1
1
1
weeks
30.0

BUTTON
5
57
88
90
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
89
57
172
90
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

MONITOR
13
377
96
422
% aware
%aware
2
1
11

SLIDER
0
13
269
46
number-of-people
number-of-people
50
1000
500.0
1
1
NIL
HORIZONTAL

SLIDER
7
134
276
167
average-value-of-cause
average-value-of-cause
1
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
6
223
277
256
resistance-to-social-pressure
resistance-to-social-pressure
0
10
4.0
1
1
NIL
HORIZONTAL

PLOT
768
61
1215
260
Populations
NIL
people
0.0
40.0
0.0
350.0
false
true
"set-plot-y-range 0 (number-of-people + 50)" ""
PENS
"contributed" 1.0 0 -10899396 true "" "plot count turtles with [contributed?]"
"aware but did not contribute " 1.0 0 -2674135 true "" "plot (count turtles with [aware-of-cause?] - count turtles with [contributed?])"
"not aware" 1.0 0 -13345367 true "" "plot count turtles with [not aware-of-cause?]"

SLIDER
8
259
180
292
cost-share-link
cost-share-link
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
11
300
183
333
cost-donate-money
cost-donate-money
0
10
4.0
1
1
NIL
HORIZONTAL

SLIDER
12
338
184
371
cost-participation
cost-participation
0
10
4.0
1
1
NIL
HORIZONTAL

BUTTON
179
57
242
90
Once
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
102
377
177
422
% donated
%donated
2
1
11

PLOT
770
275
970
425
actions
NIL
NIL
0.0
40.0
0.0
7000.0
true
true
"" ""
PENS
"# donations" 1.0 0 -16777216 true "" "plot #donations"
"# linkshares" 1.0 0 -10899396 true "" "plot #link-sharing"
"ave budget" 1.0 0 -2674135 true "" "plot ave-contribution-budget"

MONITOR
331
483
471
528
$ ave budget of aware
ave-contribution-budget
1
1
11

MONITOR
12
428
89
473
#donations
#donations
0
1
11

MONITOR
116
429
190
474
$donations
$donated
0
1
11

MONITOR
233
483
313
528
#linksharing
#link-sharing
1
1
11

MONITOR
12
484
108
529
#participations
#participations
0
1
11

PLOT
1016
273
1216
423
donations
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
"$ donated" 1.0 0 -16777216 true "" "plot $donated"

SWITCH
769
13
872
46
layout?
layout?
1
1
-1000

CHOOSER
7
173
205
218
how-cause-affects-contribution
how-cause-affects-contribution
"linear" "exponential"
1

MONITOR
214
426
313
471
% social pressure
%social-pressure
1
1
11

SLIDER
7
96
179
129
altruistic
altruistic
0
100
70.0
1
1
%
HORIZONTAL

PLOT
772
436
972
586
Number of friends
# Friends
turtles
0.0
20.0
0.0
20.0
false
false
"set-plot-x-range 0 (max [my-number-friends] of turtles) / 2\nset-plot-y-range 0 count turtles" ""
PENS
"turtles" 1.0 1 -16777216 true "" "histogram [my-number-friends] of turtles"

MONITOR
125
484
220
529
% participated
%participated
2
1
11

MONITOR
180
378
313
423
$Total funds Possible
max-contribution-budget
2
1
11

@#$#@#$#@
## WHAT IS IT?


This model is built on a scale-free social network topology to provide an integrated framework for the exploration of charitable giving and to investigate resource mobilization theories.


## HOW IT WORKS

This model begins by intializing a social network based on the 'Preferential Attachment' (PA) model in the NetLogo model library. We use the preferential attachment network because it models real life social networks, where a few people are very popular and a lot are not as popular.

Each agent may be considered either a person or household. To start the simulation, one agent is set to be aware and altruistic so that the social mobilization of the cause may begin. Each time step is notionally considered to be one day, however, the net result of the contributions is that the agent contributes the sum of all their participations and the sum of all their donations, and the time step is merely a mechanism to allow the spread of information by the social network.

Agents initialize their attributes based on slider values. they each assign a perceived value of the cause "Vi" based on a pseudo-random normal distribution function. Then each agents calculates their "contribution budget" (Bi) based on whether a linear or exponential relationship is used.
Bi = 2 * Vi				or
Bi = e raisded to Vi

In each time-step, an agent that is aware and altruistic checks to see if they they have a large enough budget to take one of the three actions.  If no agents can take action, then the simulation stops.  Next they check to see if their friends are participating or contributing to the cause and update their social pressure.  If they have a small budget (< $20) and if social pressure exceeds a threshold, then they double their contribution budget.

Next they determine which of the three actions are possible given their contribution budget and randomly select one of the three actions. if the action was "share link" then their friends to whom they shared the links are made "aware" of the cause.  Finally their contribution budget is decremented by the cost of the action taken



## HOW TO USE IT

1.	Set the Layout? switch to ON to view the social network being set up.
2.	Adjust the slider parameters (see below), or use the default settings.
3.	Press the SETUP button.
4.	Press the GO button to begin the simulation.
5.	Look at the monitors to see the current % aware and $ donated.
6.	Look at the POPULATIONS plot to watch how the populations or AWARE and contributing are changing with the social mobilization.

Parameters:
Number of People (Inital sixe of population) default: 500
Altruistic (% of people willing to contribute) defaults: 70%
Average Value of Cause	(external variable of worthiness of cause) default :4
How Cause affects Contribution default Exponential
Resistance to Social Pressure	thresholds needed to induce higher contribution. default. 4
Cost to share Link	default: 2
Cost to donate money	default: 5
Cost of participation	default: 7

Notes:
social pressure threshold is differnt for friends who are participating vs contributing in another ways (just donating or sharing links)

SPCi = #friends who have contributed / # friends

SPPi = #friends who have participated / # friends




## THINGS TO NOTICE

Watch how the blue line (not aware) in the populations plot starts off slow and then dramatically drops as awareness grows.


## THINGS TO TRY

adjust the sliders to a lower value of cause and watch how many causes fizzle out.
for a run that fizzles out, check the attributes of a "hub" agent and see if that agent is not altruisitc. If critical hubs in thesocial network are not altruistic, then the mobilization will not extend beyond that agent.



## EXTENDING THE MODEL

We envision a number of future directions on this topic and this model, including adjustment of model structure and further analysis. First, the current model exhibits a uniform decision process for agents between sharing a link, giving money and participating. Given further research into the decision rules humans might use to decide between these three, an adjustment of the model process, perhaps based upon demographics, could yield insightful results. Second, more analysis is needed to identify patterns which cause a campaign to be sustainable (i.e. it doesn’t die out). Third, in order to make this model more comparable with the real world, we propose to adjust the cost values to more closely align with US dollars and a metric of utility for participation. Fourth, we would like to investigate the use of the percent altruistic parameter as an output instead of an input. Is there a way to model the human decision heuristics so that we can run simulations to determine the percent of people who are inherently altruistic? And finally, we observed a diffusion cliff in the spread of the charity awareness (at a certain point, the campaign takes off quickly). This is directly linked to the preferential attachment model, but would this phenomenon exist if we built this model on another topology, such as a geographic or even financial network?

## NETLOGO FEATURES

 Note the use "link-neighbors" for determining which friends are aware and participating. Note the use of "random-normal" for prividing heterogenous attributes to agents around an externally controlled variable.


## CREDITS AND REFERENCES

The social network initialization is based on the 'Preferential Attachment' (PA) model in the NetLogo model library.
It also bases some code on the the Lottery Example in the netlogo Models library.
It is described in the Netlogo User Manual.

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
  <experiment name="experiment" repetitions="40" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>$donated</metric>
    <enumeratedValueSet variable="cost-share-link">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-value-of-cause">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="altruistic">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="how-cause-affects-contribution">
      <value value="&quot;exponential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-donate-money">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-participation">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="resistance-to-social-pressure">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment 6" repetitions="40" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>$donated</metric>
    <enumeratedValueSet variable="resistance-to-social-pressure">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="altruistic">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-value-of-cause">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-share-link">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-participation">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="how-cause-affects-contribution">
      <value value="&quot;exponential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-donate-money">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment komen" repetitions="40" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>$donated</metric>
    <enumeratedValueSet variable="resistance-to-social-pressure">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="altruistic">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-value-of-cause">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-share-link">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-people">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-participation">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="how-cause-affects-contribution">
      <value value="&quot;exponential&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="cost-donate-money">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="layout?">
      <value value="false"/>
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
