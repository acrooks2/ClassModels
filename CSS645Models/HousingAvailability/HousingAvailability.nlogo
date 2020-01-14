globals [
  percent-similar  ;; on the average, what percent of a turtle's neighbors ;;;;;Copyright 1997 Uri Wilensky Segregation model
                   ;; are the same color as that turtle?
  num-homeowners
  average-student-loans
  percent-unhappy  ;; what percent of the turtles are unhappy?
  death-rate
  total-households
  number-of-buyers
  average-property-cost
  number-millenials
  number-genx
  number-babyboomer
  number-seniors
  color1 ;; color group 2 (25-34/25-44; Millenials)
  color2 ;; (45-54; GEN X)
  color3 ;; (55-64; Baby boomers)
  color4 ;; (65 and over; Seniors)
 ;;color5
  shape1;; shape group 1 (homeowner)
  shape2;; shape group 2 (renter)
  color1-age-list
  color2-age-list
  color3-age-list
  color4-age-list
  num-of-patches
]

turtles-own [
  happy?           ;; for each turtle, indicates whether at least %-similar-wanted percent of ;;;;;Copyright 1997 Uri Wilensky Segregation model
              ;; looking to buy and can buy if not "die"/move
  home-owner? ;; does household own a home?
  similar-nearby   ;; how many neighboring patches have a turtle with my color?
  other-nearby     ;; how many have a turtle of another color?
  total-nearby     ;; sum of previous two variables
  age ;; randomly chosen
  student_loans?
  student_loan_debt_amt ;; cost in dollars of student loan debts -- include interest? -- could just be zero
  annual_salary ;; household annual salary
  buying_power ;; household ability to purchase
  bought_home?
  notlooking? ;; is household looking to move
  looking_to_buy? ;;
  looking_to_rent? ;;
  qualified_loan? ;; initially random -- then evolve to base on Axtel Housing paper
  mortgage_rent_amt ;; annual cost of household's rent or mortgage NEED TO ACTUALLY MAKE THIS ANNUAL AND TOTAL AMOUNT
]

patches-own [
  cost ;; each patch represents property and its cost to live on whether it's a rental or for sale
  rental? ;; is it a rental property or for purchase
]

;;Setup modification
to setup
ca
set color1 red   ;; millenial
set color2 white   ;; genx
set color3 blue ;; babyboomer
set color4 yellow ;; babyboomer plus
;;set color5 yellow
set shape1 "person"
set shape2 "house" ;; homeowner
set color1-age-list [20 21 22 23 24 25 26 27 28 29 30 31 32 33 34]
set color2-age-list [35 36 37 38 39 40 41 42 43 44]
set color3-age-list [45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64]
set color4-age-list [65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 ]
  ;;88 89 90 91 92 93 94 95 96 97 98 99 100

let num-of-households (number-of-households) ;;;;;Copyright 1997 Uri Wilensky Segregation model
ask n-of num-of-households patches [
  sprout 1 ;;[
     ;;set color color2 ]
            ]
;;ask n-of int(num-of-households * perc-millenials / 100) turtles ;;creates sampling to represent a ratio of millenials vs. nonmillenials
ask n-of int(num-of-households) turtles ;;;;; babyboomers
  ;;ask n-of int(perc-millenials) turtles
     [set color color3]
     ask turtles [
       if color = color3
       [set age one-of color3-age-list]]

ask n-of int(num-of-households * perc-genx / 100) turtles ;;creates sampling to represent a ratio of millenials vs. nonmillenials
;;ask n-of int(num-of-households) turtles
     [set color color2]
     ask turtles [
       if color = color2
       [set age one-of color2-age-list]]

ask n-of int(num-of-households * perc-millenials / 100) turtles ;;creates sampling to represent a ratio of millenials vs. nonmillenials
;;ask n-of int(num-of-households) turtles
     [set color color1]
     ask turtles [
       if color = color1
       [set age one-of color1-age-list]]

ask n-of int(num-of-households * perc-seniors / 100) turtles ;;creates sampling to represent a ratio of millenials vs. nonmillenials
;;ask n-of int(num-of-households) turtles
    [set color color4]
     ask turtles [
       if color = color4
       [set age one-of color4-age-list]]

ask n-of int(num-of-households * perc-student-loans / 100) turtles;;creates rate of households with student loans
    [set student_loans? true]
ask turtles [
  if student_loans? != true
   [set student_loans? false]
]

ask n-of int(num-of-households * perc-not-looking / 100) turtles ;;creates ratio of households not looking for new housings ;;bug if set as looking value is 0 and not True/False
    [set notlooking? true]
ask turtles [
  if notlooking? != true
   [set notlooking? false]
]

  ;;Represents number of those not in forbearance on student loans or those with worthy credit scores
;;ask n-of int(num-of-households * perc-qualified-loan / 100) turtles ;;creates ratio of agents
   ;;[set qualified_loan? true] ;;2
   ;;[set not qualified_laan? false]
;;ask turtles [
  ;;if qualified_loan? != true
   ;;[set qualified_loan? false]
;;]

ask n-of int(num-of-households * perc-home-owners / 100) turtles  ;;creates ratio of agents who start off owning homes
    [set home-owner? true]

ask turtles [
  if home-owner? != true ;; true
   [set home-owner? false] ;; false
   ifelse home-owner? [ set shape "house" ] [ set shape "person" ] ;; change to home_owner?
]

;;ask patches [
      ;;set pcolor one-of [green black]]

ask patches [
  set cost random-normal 35160 1000;;set a more proper distribution
  set rental? one-of [ true false]
    ;;if rental? = true [set pcolor green]
]

ask turtles [
  set annual_salary random-normal 65000 10000
  set mortgage_rent_amt cost
  if student_loans? = true and age <= 45
  [set student_loan_debt_amt random-normal 30000 100] ;;30000 average virginia student loan
  ;;set annual_salary annual_salary - (student_loan_debt_amt * .05)
  ;;set buying_power annual_salary - student_loan_debt_amt - mortgage_rent_amt
  set buying_power annual_salary - student_loan_debt_amt
  if (student_loan_debt_amt + mortgage_rent_amt) / annual_salary <= .30 ;;;;;; DTI
  [set qualified_loan? true]
    if qualified_loan? = true [set notlooking? false]
    ;;set mortgage_rent_amt random-normal 20000 1000
  ;;if ((home-owner? = true) and (buying_power > cost)) [set bought_home? true]
  ;;if buying_power < cost [set home-owner? false]
  ;;if home-owner? = true [set bought_home? true]
  ;;ifelse bought_home? = true [set pcolor green][set pcolor black]
  if home-owner? = true [set pcolor green]
    if home-owner? = true [set notlooking? true]
]
;;update-turtles
reset-ticks
end
;;; set up end ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; run the model for one tick
to go ;;;;;Copyright 1997 Uri Wilensky Segregation model
  ;;if all? turtles [ notlooking? ]  [ stop ]
  update-variables
  ;;;;;move-looking-turtles
  tick
end


;; move until we find an unoccupied spot
to find-new-spot
  rt random-float 360 ;;;;;Copyright 1997 Uri Wilensky Segregation model
  fd random-float 10
  if any? other turtles-here [ find-new-spot ] ;; keep going until we find an unoccupied patch
 ;; ifelse patch cost >= 100 [ find-new-spot ] ;;.30annual_income
  ;;if looking_to_rent? = 0 and rental? = 0 [stop]
  ;;if cost >= annual_salary * .30 [ find-new-spot]
  ;;if buying_power * .30 <= .30 * cost [ find-new-spot ]
  ;;if cost + studen_loan_amt <=
  move-to patch-here  ;; move to center of patch
end

to update-variables ;;;;;Copyright 1997 Uri Wilensky Segregation model
  move-looking-turtles
  update-turtles
  buy-home
  update-globals

end

to update-turtles ;;;;;Copyright 1997 Uri Wilensky Segregation model
  ask turtles [
    set age age + 1 ;;households get older every tick
    set similar-nearby count (turtles-on neighbors)  with [ shape = [ shape ] of myself ]
    set other-nearby count (turtles-on neighbors) with [ shape != [ shape ] of myself ]
    set total-nearby similar-nearby + other-nearby
    ;;set happy? similar-nearby >= (total-nearby / 100) and notlooking? = false and home-owner? = true
    set happy? similar-nearby >= (.30 * total-nearby / 100)
    ;;ifelse notlooking? = false and home-owner? = true [set happy? true][set happy? false]
    set student_loan_debt_amt student_loan_debt_amt - (student_loan_debt_amt * .05)
    ;;set happy? similar-nearby >= (%-similar-wanted * total-nearby / 100) ;;deleted %-similar-wanted slider button

    ;;if age >= 87 [hatch 1]
    if age >= random-normal 79 1 [die]
    ;;if age = random 87 [hatch 1 [fd 3]
    ;;if age = random 87 [hatch 1 [find-new-spot];;;;;;;;;;;;;;;;;
    if age = random 87 [hatch 2 [find-new-spot]

    set buying_power annual_salary - student_loan_debt_amt - mortgage_rent_amt
    ;;set buying_power (mortgage_rent_amt + student_loan_debt_amt) / annual_salary ;;DTI
    ;;if buying_power >= cost and pcolor = green [set bought_home? true ] ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;;if dti/buying_power >= .30 and pcolor = green [ set bought_home? true ]
    ;;if buying_power * .30 >= cost

    ;;if bought_home? = true [set home-owner? true ]
    ;;if bought_home? = true [set notlooking? true]

    ;;if home-owner? = true [ set shape "house" ]
    ;;if home-owner? = false [ set shape "person" ]
    ;;if home-owner? = true [set pcolor green]
      ;;if ticks = 5 and happy? = false [die] ;;;;;;;;;;;;;;;;
      if ticks = 5 and notlooking? = false and home-owner? = true [die]
  ;;buy-home
    ;;hatch 1 ;;new households moving in
    ;if total-households < 1000 [hatch 1 ]
  ]
  ;;ask one-of patches [ sprout 1 ]
  ]


  ask patches [

    ;;ifelse total-households > 1000 [set cost cost + (cost * .025)] [set cost cost - (cost * .025)]
    if total-households > number-of-households [set cost cost + (cost * .025)]
    ;;if home-owner? = true [set pcolor green]
  ]
  end

;; looking turtles try a new spot
to move-looking-turtles ;;;;;Copyright 1997 Uri Wilensky Segregation model
 ;; ask turtles with [ notlooking? = 0]
   ;; [ find-new-spot ]
  ask turtles [
    if notlooking? = true or home-owner? = true or bought_home? = true [stop]
    ;;if home-owner? = true [stop]
    ;;if bought_home? = true [stop]
    ;;if notlooking? = false or cost >= annual_salary * .30 or (shape = "person" and pcolor = green)[ find-new-spot ]
    if cost >= annual_salary * .30 [ find-new-spot ]
    if (shape = "person" and pcolor = green)[ find-new-spot ]
    if rental? = false and qualified_loan? = false [ find-new-spot ]
    if qualified_loan? = true and rental? = true [ find-new-spot]
    ;;if shape = "person" and pcolor = green [ find-new-spot ]
    ;;if cost >= annual_salary * .30 [ find-new-spot]
  ]
end
;;;from rabbit weeds
;;to reproduce     ;; rabbit procedure
  ;; give birth to a new rabbit, but it takes lots of energy
 ;; if energy > birth-threshold
    ;;[ set energy energy / 2
     ;; hatch 1 [ fd 1 ] ]
;;end


to buy-home
  ask turtles [
  if buying_power >= cost and pcolor = green [set bought_home? true ]
  if bought_home? = true [set home-owner? true ]
    ;;if bought_home? = true [set notlooking? true]

  if home-owner? = true [ set shape "house" ]
  if home-owner? = false [ set shape "person" ]
  if home-owner? = true [set pcolor green]
  ]
end

to update-globals

  let similar-neighbors sum [ similar-nearby ] of turtles ;;;;;Copyright 1997 Uri Wilensky Segregation model
  let total-neighbors sum [ total-nearby ] of turtles ;;;;;Copyright 1997 Uri Wilensky Segregation model
  ;;set percent-similar (similar-neighbors / total-neighbors) * 100
  set average-property-cost sum [ cost ] of patches / (count patches)
  set average-student-loans sum [ student_loan_debt_amt ] of turtles / (count turtles with [student_loans? = true])
  set num-homeowners count turtles with [home-owner?]
  set percent-unhappy (count turtles with [ not happy? ]) / (count turtles) * 100
  set total-households (count turtles)
  set number-of-buyers (count turtles with [bought_home? = true ])
  set number-millenials (count turtles with [color = color1])
  set number-genx (count turtles with [color = color2])
  set number-babyboomer (count turtles with [color = color3])
  set number-seniors (count turtles with [color = color4])

end

@#$#@#$#@
GRAPHICS-WINDOW
228
10
746
529
-1
-1
10.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

MONITOR
643
536
728
581
% unhappy
percent-unhappy
1
1
11

BUTTON
29
38
109
71
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
67
81
147
114
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

BUTTON
112
38
202
72
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
551
536
639
581
num-unhappy
count turtles with [not happy?]
1
1
11

SLIDER
22
122
194
155
perc-millenials
perc-millenials
0
100
28.0
1
1
NIL
HORIZONTAL

SLIDER
17
352
189
385
perc-not-looking
perc-not-looking
0
100
46.0
1
1
NIL
HORIZONTAL

SLIDER
15
428
189
461
perc-qualified-loan
perc-qualified-loan
0
100
67.0
1
1
NIL
HORIZONTAL

SLIDER
19
311
220
344
number-of-households
number-of-households
1
1000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
18
273
192
306
perc-home-owners
perc-home-owners
0
100
67.0
1
1
NIL
HORIZONTAL

SLIDER
16
391
191
424
perc-student-loans
perc-student-loans
0
100
29.0
1
1
NIL
HORIZONTAL

PLOT
758
322
1047
472
Number of Homeowners
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
"All" 1.0 0 -16777216 true "" "plot count turtles with [home-owner?]"
"Millenials" 1.0 0 -2674135 true "" "plot count turtles with [home-owner? = true and color = color1]"
"Gen-x" 1.0 0 -7500403 true "" "plot count turtles with [home-owner? = true and color = color2]"
"Babyboomers" 1.0 0 -13345367 true "" "plot count turtles with [home-owner? = true and color = color3]"
"Seniors" 1.0 0 -1184463 true "" "plot count turtles with [home-owner? = true and color = color4]"

SLIDER
22
160
194
193
perc-genx
perc-genx
0
100
21.0
1
1
NIL
HORIZONTAL

SLIDER
21
197
193
230
perc-babyboomer
perc-babyboomer
0
100
39.0
1
1
NIL
HORIZONTAL

SLIDER
20
235
192
268
perc-seniors
perc-seniors
0
100
13.0
1
1
NIL
HORIZONTAL

MONITOR
1137
727
1257
772
NIL
total-households
17
1
11

PLOT
761
477
1048
627
Average Property Value
ticks
purchases
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot average-property-cost"

MONITOR
230
535
385
580
total number of buyers
number-of-buyers
17
1
11

MONITOR
390
536
546
581
NIL
average-property-cost
17
1
11

PLOT
758
12
1049
162
Generation Populations
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
"Millenials" 1.0 0 -2674135 true "" "plot (count turtles with [color = color1])"
"GEN X" 1.0 0 -7500403 true "" "plot (count turtles with [color = color2])"
"Baby boomers" 1.0 0 -13345367 true "" "plot (count turtles with [color = color3])"
"Seniors" 1.0 0 -1184463 true "" "plot (count turtles with [color = color4])"

PLOT
757
165
1048
315
Average Student Loan Amount 
Ticks
Dollars
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot sum [ student_loan_debt_amt ] of turtles / (count turtles with [student_loans? = true])"
"pen-1" 1.0 0 -7500403 true "" "plot sum [ student_loan_debt_amt ] of turtles"

@#$#@#$#@
## WHAT IS IT?


## HOW TO USE IT



## THINGS TO NOTICE



## THINGS TO TRY





## EXTENDING THE MODEL



## NETLOGO FEATURES





## CREDITS AND REFERENCES




## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (1997).  NetLogo Segregation model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
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

face-happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face-sad
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

person2
false
0
Circle -7500403 true true 105 0 90
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 285 180 255 210 165 105
Polygon -7500403 true true 105 90 15 180 60 195 135 105

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

square - happy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 75 195 105 240 180 240 210 195 75 195

square - unhappy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 60 225 105 180 195 180 240 225 75 225

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

square-small
false
0
Rectangle -7500403 true true 45 45 255 255

square-x
false
0
Rectangle -7500403 true true 30 30 270 270
Line -16777216 false 75 90 210 210
Line -16777216 false 210 90 75 210

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

triangle2
false
0
Polygon -7500403 true true 150 0 0 300 300 300

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
    <timeLimit steps="30"/>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="number-of-households">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-not-looking">
      <value value="46"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-seniors">
      <value value="13"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-student-loans">
      <value value="29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-genx">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-qualified-loan">
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-babyboomer">
      <value value="38"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-millenials">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-home-owners">
      <value value="0"/>
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
