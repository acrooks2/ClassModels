;; THEME: "Cronuts to distract you", as an example of Impulse Purchase edutainment. They give time to shoppers to want to shop more...
;; Impulse purchases differ for young adults versus shopper with child
;; Think of cronuts and Coca-Cola as the product sources of the meme epidemics that bring in customers. (Coca-cola for young adults, cronuts for children "of all ages?")

breed [employees employee]
breed [shoppers shopper]

globals [ goal? done q number-impulse-buy percent-similar percent-happy]
patches-own [groceries? elevation]
shoppers-own [
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HAPPINESS METRICS    ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
  happiness happy? met-clover entertainment
;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; PURCHASING METRICS   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
  bought? my-list my-groceries bought-milk bought-bread bought-hamburger
;;;;;;;;;;;;;;;;;;;;;;;;
;; IMPULSE METRICS   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
  tried-cronuts coca-cola-offer total-impulse-buy num-impulse-buy had-coffee
;;;;;;;;;;;;;;;;;;;;;;;;
;; MOVEMENT METRICS   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;
  start-tick end-tick turn?
;;;;;;;;;;;;;;;;;;;;;;;;;
;; SOCIAL METRICS V2  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;
  similar-nearby other-nearby total-nearby]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; CREATE DYNAMIC ENVIRONMENT ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to loadMap
   let s1 random 2 + 201 ;; these are random location modifiers, for the colored patches below
   let s2 random 50 + 101
   let s3 random 2 + 151
   let s4 random 2 + 50
   let s5 random 2 + 55
   let s6 random 2 + 250
   let s7 random 2 + 275
    ask patches with [pxcor >=  200 and pxcor < s1 and pycor >= 10 and pycor < 27 ] [ set pcolor blue ] ;; display of food prep
    ask patches with [pxcor >= s2 and pxcor < s3 and pycor >= 12 and pycor < 19 ] [ set pcolor red ] ;; coca-cola
    ask patches with [pxcor >= 265 and pxcor < 278 and pycor >= 22 and pycor < 25 ] [ set pcolor yellow ] ;; cronuts
    ask patches with [pxcor >= s6 and pxcor < s7 and pycor >= 16 and pycor < 20 ] [ set pcolor violet ] ;; hamburgers
    ask patches with [pxcor >= 20 and pxcor < 25 and pycor >= 18 and pycor < 22 ] [ set pcolor gray ] ;; customer rock
    ask patches with [pxcor >= 50 and pxcor < 55 and pycor >= 3 and pycor < 22 ] [ set pcolor brown ] ;; coffee
    ask patches with [pxcor >= s4 and pxcor < s5 and pycor >= 28 and pycor < 32 ] [ set pcolor orange ] ;; bethy's bakery (bread)
    ask patches with [pxcor >= 120 and pxcor < 132 and pycor >= 18 and pycor < 22 ] [ set pcolor pink ] ;; milk
    ask patches with [count neighbors != 8] [ set pcolor blue ] ;; border
end


to set-elevation
    ask patches [
    let elev1 100 - distancexy 400 22
    let elev2 100 - distancexy 400 18
    ifelse elev1 > elev2 [set elevation elev1] [set elevation elev2]
  ]
end

;;;;;;;;;;;;;;;;;;;;;
;; CREATE AGENTS  ;;;
;;;;;;;;;;;;;;;;;;;;;

to creation-of-shoppers
  set-default-shape shoppers "circle"
   if random 2700 < 51 [ask one-of patches with [ pcolor = gray ][sprout-shoppers 1 [set size 2 set color pink set turn? false set entertainment 1 plan-groceries-on-list]] ]
   if random 2700 < 69 [ask one-of patches with [ pcolor = gray ][sprout-shoppers 1 [set size 2 set color cyan set turn? false set entertainment 2 plan-groceries-on-list]] ]
end


to creation-of-employees
  set-default-shape employees "cow"
   create-employees 1
   ask employees
    [set size 4
    set color white
    set xcor 50 set ycor 22
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AGENTS PLANNING FOR SHOPPING  ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to plan-groceries-on-list
    set my-list (list random 3 random 3 random 3)
end

;;;;;;;;;;;;;;;;
;; SET UP    ;;;
;;;;;;;;;;;;;;;;

to setup
  clear-all
  loadMap
  set-elevation
  creation-of-employees
  ;;ask shoppers [set-shopping-goal] V2
  ;;plan-groceries-on-list
  first-shopper-arrival
  set q 0.67 ;; parameterize for testing
  reset-ticks
end

;;;;;;;;;;;;;;;;
;; TESTING   ;;;
;;;;;;;;;;;;;;;;

to test-list

end

;;;;;;;;;;;;;;;;;;;;;;;
;; AGENTS SHOPPING  ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to first-shopper-arrival
  ask shoppers [
    set happiness 0
    set my-list fput 0 my-list
    shoppers-move]
end


to shoppers-move
ask shoppers [
    ifelse [pcolor] of patch-ahead 1 = blue [ walk ] [climb]
    if xcor >= 300  [ fd 0.05 ]
    if xcor >= 390  [ die ]
    ]
end

to climb
      let stepp (one-of neighbors with [pcolor = 0.0])
          ifelse random-float 1 < q [uphill elevation]  [lt 180 move-to one-of neighbors]
end

to walk  ;; shopper procedure
  if not wall? (90 * 1) and wall? (135 * 1) [ rt 90 * 1 ] ;; direction = 1
  while [wall? 0] [ lt 180 * 1 ] ;; turn left if necessary (sometimes more than once)
  fd 1
end

to-report wall? [angle]  ;; shopper procedure, note that angle may be + or -.  if angle is +, the turtle looks right.  if angle is -, the turtle looks left.
  report blue = [pcolor] of patch-right-and-ahead angle 1
end

;;;;;;;;;;;;;;;;
;; MAIN LOOP ;;;
;;;;;;;;;;;;;;;;

to go
  shoppers-move
  ask shoppers [if xcor >= 49 and xcor < 55 and entertainment = 1 [meet-clover]]
  ask shoppers [if xcor >= 49 and xcor < 55  and entertainment = 2 [ buy-cup-of-coffee ]]
  ask shoppers [if xcor >= 49 and xcor < 55 and entertainment = 1 [buy-milk]]
  ask shoppers [if xcor >= 120 and xcor < 130 and entertainment = 2 [buy-milk]]
  ask shoppers [if xcor >= 49 and xcor < 55 and entertainment = 1 [buy-bread]]
  ask shoppers [if pcolor = red and entertainment = 2 [ visit-coca-cola-demo ]]
  ask shoppers [if xcor >= 265 and xcor < 269  [ visit-cronuts-demo ]]
  ask shoppers [if xcor >= 250 and xcor < 260  [ buy-hamburger ]]
  tick
  creation-of-shoppers
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AGENTS IMPULSE BUYING   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to make-impulse-purchase
  update-social-shoppers
  set happiness happiness + 1
  set num-impulse-buy num-impulse-buy + 1
end

to meet-clover  ;; should be entertaiment = 1 (with child)
  ask employees [ ask shoppers in-radius 10 [ if entertainment = 1 [set happiness happiness + 1]]]
  if happiness >= 1 [(set my-list fput "milk" my-list) (wait 0.5)]
  set met-clover true
end

to buy-bread ;; bethy's bakery
  if met-clover = true  [set my-list fput "bread" my-list]
  set bought-bread true
  ask patches in-cone 3 60 ;; radius then angle
    [set pcolor green]
  ;;wait 0.2
end

to buy-milk ;; cronuts demo, entertaiment = 1 (with child)
  if met-clover = true  [set my-list fput "milk" my-list]
  set bought-milk true
  ask patches in-cone 3 60 ;; radius then angle
    [set pcolor green]
  ;;wait 0.2
end

to buy-hamburger ;; purchase hamburgers, entertaiment = 2 (young adult)
  if met-clover = true  [set my-list fput "hamburger" my-list]
  set bought-hamburger true
  ask patches in-cone 3 60 ;;
    [set pcolor green]
  ;;wait 0.2
end

to visit-cronuts-demo ;; cronuts demo, entertaiment = 1 (with child)
  if happiness >= 1  [set my-list fput "cronuts" my-list]
  set tried-cronuts true
  make-impulse-shoppers ;;
  ask patches in-cone 3 60 ;;
    [set pcolor white]
  wait 0.2
end

to buy-cup-of-coffee ;; adds happiness somewhat but does not add impulse purchases
  set happiness happiness + 0.5
  if happiness >= 1  [set my-list fput "coffee" my-list]
  set had-coffee true
  ask patches in-cone 3 60 ;;
    [set pcolor white ]
  wait 0.2
end

to visit-coca-cola-demo ;; coca-cola offer display, entertaiment = 2 (young adult)
  if happiness >= 1 [set my-list fput "coca-cola" my-list]
  set coca-cola-offer true
  make-impulse-shoppers
  ask patches in-cone 3 60 ;; radius then angle
    [set pcolor white]
  wait 0.2
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; AGENTS HAPPINESS METRICS ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to-report total-shopper-happiness
  report sum [happiness] of shoppers
end

to-report total-impulse-purchases
  report sum [num-impulse-buy] of shoppers
end

to-report total-planned-purchases
  report sum [num-impulse-buy] of shoppers
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SOCIAL BEHAVIOR for V2   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to make-impulse-shoppers ;; more involved with social factors in V2: Filene's Basement variant
    make-impulse-purchase
end


to update-variables ;; more involved with social factors in V2; Filene's Basement variant
  update-social-globals
end

to buy-groceries-on-list ;; not implemented, use in V2
  ;;ifelse [bought?] of my-groceries
    ;;[set my-purchase item 1 my-grocery-list]
    ;;[set my-purchase item 0 my-grocery-list]
end

to update-social-shoppers ;; borrowed from model of Schelling, not critical to V1 program (For Filene's Basement variant)
  ask shoppers [
    ;; in next two lines, use "neighbors" to test the eight patches surrounding the current patch
    set similar-nearby count (shoppers-on neighbors)
      with [color = [color] of myself]
    set other-nearby count (shoppers-on neighbors)
      with [color != [color] of myself]
    set total-nearby similar-nearby + other-nearby
    set happy? similar-nearby >= ( 50 * total-nearby / 100 ) ;; parameter %-similar-wanted locked down
  ]
end

to update-social-globals ;; borrowed from model of Schelling, not critical to V1 program (For Filene's Basement variant)
  let similar-neighbors sum [similar-nearby] of shoppers
  let total-neighbors sum [total-nearby] of shoppers
  if similar-neighbors >= 1 and total-neighbors >= 1 [set percent-similar (similar-neighbors / total-neighbors) * 100
  set percent-happy (count turtles with [ happy?]) / (count turtles) * 100]
end
@#$#@#$#@
GRAPHICS-WINDOW
97
11
1308
143
-1
-1
3.0
1
10
1
1
1
0
0
0
1
0
400
0
40
0
0
1
ticks
30.0

BUTTON
11
13
77
46
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
12
51
67
84
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

BUTTON
13
90
68
123
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
152
204
421
404
Happiness as f(Edutainment)
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
"default" 1.0 0 -16777216 true "" "plot total-shopper-happiness"

PLOT
425
204
679
404
Planned vs Impulse Interest
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
"planned" 1.0 0 -13840069 true "" "plot count patches with [pcolor = green]"
"impulse" 1.0 0 -7500403 true "" "plot count patches with [pcolor = white]"

PLOT
682
204
934
403
Impulse Purchases
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
"default" 1.0 0 -16777216 true "" "plot total-impulse-purchases"

PLOT
938
203
1211
402
shoppers in store
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
"total" 1.0 0 -16777216 true "" "plot count shoppers"
"with children" 1.0 0 -2064490 true "" "plot count shoppers with [entertainment = 1]"
"no children" 1.0 0 -11221820 true "" "plot count shoppers with [entertainment = 2]"

@#$#@#$#@
## OBJECTIVE

This model protrays a stylized shopping environment, one very simple and displayed as a single one-way flow, without aisles and a check out stand. In this model, increased in-store shopper engagement allows consumer freedom that could result in higher numbers of purchases, including the willingness for customers to make unplanned purchases for so-called impulse items.

## DESIGN

The store design used as a prototype for this model, Stew Leonard's of Norwalk, CT includes environmental features considered revolutionary at the time of its construction: one-way traffic flow, entertainment for children, free samples given away at demonstration areas, few choices among brands or sizes of a given item, and friendly, knowledgeable staff.

There are seven shopper parameters in the model that control the actions of individual shoppers. The model creates two classes of shoppers, those with children (pink dots: attention originally on providing staples such as bread and milk) and those without (blue dots: young adults with interest in an upcoming barbeque). These shopper parameters include: 
•	Preferred walking rate when transiting store layout
•	Vision (distance and radius) when walking
•	Changes to walking speed and vision when browsing
•	Number and variation of planned purchases (restricted list)
•	Degree of attraction to unplanned purchases
•	Degree of interest in entertainment and educational displays 
•	Degree of interest in products under consideration for purchase.
 
The shopping layout has a fixed number of entertainment locales, with one being a fixed white ‘cow’ for entertaining children. Shoppers arrive at the store on the left margin based on a stochastic process and leave on the right margin (Check out process not shown).

The baseline parameters used by the shopper population includes:
•	approximately 1 item purchased per minute
•	$5.00 per item purchased
•	2000 feet per shopper transit through store
•	5 feet / patch
•	4-5 seconds / tick (time step)


## WHAT TO DO

The control interfaces have been removed from this version of the model, beyond the Setup button to configure the store layout environment and the Step and Go buttons to start the agents shopping in the simulation. Step moves the agents one time step and Go runs the model continuously.

## WHAT YOU WILL SEE

The model design includes a grocery layout model, with classes of mobile agents (“turtles”) being consumer objects shopping alone or consumers with a child, each with their own individual walking speed. Fixed classes (“patches”) in the store layout include travel lanes, locations of items for sale and entertainment locations. The model allows different product displays to be tested, each new setup modifies the store configuration. Agents in the model simulate shoppers transiting the store, choosing items for consideration and making purchases.

The interface shows five displays: the horizontal caricature of the store layout, from left to right (turns in store layout omitted; green clouds indicate intended purchases and white clouds indicate intention to purchase impulse items) and four plots, happiness of agents as function of entertainment and education displays, comparison of cumulative intent of agent population for planned and impulse purchases, total number of impulse purchases and numbers of shoppers in the store. 

The model produces shopping patterns of behavior that indicate punctuated episodes of impulse purchases from a set of shoppers who arrive at the store at independent arrival times, each with their own shopping plan.  


## CREDITS AND REFERENCES

NetLogo Copyright 1997 Uri Wilensky.
 
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License. To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.
Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

Thanks to Stew Leonard's and Uri Wilensky for the NetLogo modeling environment. The pedestrian movement algorithm was borrowed by a number of studies including Pluchino et al. (2014).  
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
