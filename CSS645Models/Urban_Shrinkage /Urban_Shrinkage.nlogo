extensions [ gis csv ]
globals
[
  tract         ;;saptial boundary
  nhhold-n1     ;;household amount in neighborhood 1
  nhhold-n2     ;;household amount in neighborhood 2
  nhhold-n3     ;;household amount in neighborhood 3
  avg-n1         ;;average price in neighborhood 1
  avg-n2         ;;average price in neighborhood 2
  avg-n3         ;;average price in neighborhood 3
  n-buyers       ;;number of buyer
  n-sellers      ;;number of seller
]

patches-own
[
  PID    ;;Polygon ID number
  OID    ;;Object ID
  ntype  ;;neighborhood type, displyaed as different colors in the model
  price  ;;house price
  qv     ;;lower quatile price for houses

  ;;number of household with income info to generate households' income
  ni50    ;;below 50k
  ni75    ;;50-75k
  ni150   ;;75-150k
  nim150  ;;more 150k
  centroid? ;;if it is the centroid of a polygon
  occupied? ;;if it is occupied by a turtle
  une       ;;unemployment
]

breed [households household]
;breed [developers develor]

households-own
[
  hID        ;;household ID
  hNT        ;;household neighborhood type
  hPoly      ;;household polygonID
  hIncome    ;;household income
  hPrice     ;;house price of current living house
  hBudget    ;;Add an atrribute to check affordable or not, bid price based on budget
  employed?

  ;Roles
  buyer?
  seller?

  ;buyerl
  ;sellerl
  askprice   ;;ask price
  bidprice   ;;bid price

  ;Status of trade
  trade?
  ;flags
  flag
  move?
]

;;************************;;
;;****1 Initialization****;;
;;************************;;
;1.1 Set up
to setup
  clear-all
  reset-ticks
  ;Load Vector Census Tract Data
  set tract gis:load-dataset "Data/DMA_v5.shp"
end

;1.2 Draw the Doundary and Assign each Polygon ID
;;Reference this part from Yang's model, which is provided by the book of Agent-Based Modeling & Geograohic Information System
to draw
  clear-drawing
  reset-ticks
  gis:set-world-envelope gis:envelope-of (tract)

  ;apply the vetor data attributes to patches
  gis:apply-coverage tract "LINK" OID
  gis:apply-coverage tract "NT" ntype
  ;number of hhousehold with income info
  gis:apply-coverage tract "HU_I_50K" ni50
  gis:apply-coverage tract "HU_I75_K" ni75
  gis:apply-coverage tract "HU_I150_K" ni150
  gis:apply-coverage tract "HU_IM150_K" nim150
  ;medain house price
  gis:apply-coverage tract "HU_V_K" price
  ;lower quartile value
  gis:apply-coverage tract "HU_VQ_K" qv
  ;unemployment status
  gis:apply-coverage tract "H_EM_R" une

  ;Fill the Ploygon with color
  foreach gis:feature-list-of tract
  [
    feature ->
    if gis:property-value feature "NT" = 1 [ gis:set-drawing-color red    gis:fill feature 2.0]
    if gis:property-value feature "NT" = 2 [ gis:set-drawing-color blue   gis:fill feature 2.0]
    if gis:property-value feature "NT" = 3 [ gis:set-drawing-color green  gis:fill feature 2.0]
  ]
  ;Draw Boundary
  ;gis:set-drawing-color white
  ;gis:draw tract 0.5

  ;Identify Polygon wit ID number
  let x 1
  foreach gis:feature-list-of tract
  [
    feature ->
    let center-point gis:location-of gis:centroid-of feature
    let x-coordinate item 0 center-point
    let y-coordinate item 1 center-point

    ask patch x-coordinate y-coordinate[
      set PID x
      set centroid? true
    ]
    set x x + 1
  ]

  ;3.1, Create Households
  create-household
  ;update-global
  ;3.2, Set up housdeholds with price and budget
  initialize-hprice
  ;3.3
  set-hBudget
  ;3.4, Add Buyers to the model
  add-buyers
  ;Update Variables
  ;update-global
  ;3.5, Add Sellers based on the demand and supply
  add-sellers
  ;update again to let the monitor display the number of the sellers
  update-global
  do-plot
end

;;************************;;
;;****2 Model Dynamic ****;;
;;************************;;
;2.1 Main Funtion
to go
  do-plot
  ;;move households
  move
  ;;Main function of trade is in 3.7 of the following section
  trade
  ;;Update and add new traders
  update-household
  add-buyers
  ;update-global
  add-sellers
  update-global
  ;; Do Plot
  do-plot
  tick
end

;;************************;;
;;****3, Functions    ****;;
;;************************;;
;3.1 Create Households For Initilazation
to create-household
  ask patches with [PID > 0] [set occupied? false ]
  let y 1
  while [y <= 136] [
    ;number of households
    let ni501   [ni50] of patches with [centroid? = true and PID = y]
    let ni751   [ni75] of patches with [centroid? = true and PID = y]
    let ni1501  [ni150] of patches with [centroid? = true and PID = y]
    let nim1501 [nim150] of patches with [centroid? = true and PID = y]
    ;neighborhood type
    let ntype1  [ntype] of patches with  [centroid? = true and PID = y]
    let une1    [une] of patches with  [centroid? = true and PID = y]

    if ntype1 = [1][
      ask patches with [PID = y and occupied? = false][
        let z 1
        let i item 0 ni501
        let j item 0 ni751
        let p item 0 ni1501
        let q item 0 nim1501
        let t item 0 une1

        while [z <= i][sprout 1[
          set breed households
          set hID z
          set hNT 1
          set hPoly y
          set shape "dot"
          set hIncome 0 + random int 50
          set color white
          set size 1
          ifelse random-float 100 < t
          [set employed?  false]
          [set employed?  true]
          ask patch-here[set occupied? true]
          set z z + 1
          ]

          while [z <= i + j][sprout 1[
            set breed households
            set hID z
            set hNT 1
            set hPoly y
            set shape "dot"
            set hIncome 50 + random int 25
            set color white
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= i + j + p][sprout 1[
            set breed households
            set hID z
            set hNT 1
            set hPoly y
            set shape "dot"
            set hIncome 75 + random int 75
            set color white
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= i + j + p + q][sprout 1[
            set breed households
            set hID z
            set hNT 1
            set hPoly y
            set shape "dot"
            set hIncome 150 + random int 50
            set color white
            set size 1
            ;emoplyed
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ;houseprice

            ask patch-here[set occupied? true]
            set z z + 1
          ]]
        ]
    ]]

    if ntype1 = [2][
      ask patches with [PID = y and occupied? = false][
        let z 1
        let i item 0 ni501
        let j item 0 ni751
        let p item 0 ni1501
        let q item 0 nim1501
        let t item 0 une1

        while [z <= i][sprout 1[
          set breed households
          set hID z
          set hNT 2
          set hPoly y
          set shape "dot"
          set hIncome 0 + random int 50
          set color pink
          set size 1
          ifelse random-float 100 < t
          [set employed?  false]
          [set employed?  true]
          ask patch-here[set occupied? true]
          set z z + 1
          ]

          while [z <= i + j][sprout 1[
            set breed households
            set hID z
            set hNT 2
            set hPoly y
            set shape "dot"
            set hIncome 50 + random int 25
            set color pink
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= i + j + p][sprout 1[
            set breed households
            set hID z
            set hNT 2
            set hPoly y
            set shape "dot"
            set hIncome 75 + random int 75
            set color pink
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= i + j + p + q][sprout 1[
            set breed households
            set hID z
            set hNT 2
            set hPoly y
            set shape "dot"
            set hIncome 150 + random int 50
            set color pink
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]
        ]
    ]]

    if ntype1 = [3][
      ask patches with [PID = y and occupied? = false][
        let z 1
        let i item 0 ni501
        let j item 0 ni751
        let p item 0 ni1501
        let q item 0 nim1501
        let t item 0 une1

        while [z <= i][sprout 1[
          set breed households
          set hID z
          set hNT 3
          set hPoly y
          set shape "dot"
          set hIncome 0 + random int 50
          set color yellow
          set size 1
          ifelse random-float 100 < t
          [set employed?  false]
          [set employed?  true]
          ask patch-here[set occupied? true]
          set z z + 1
          ]

          while [z <= i + j][sprout 1[
            set breed households
            set hID z
            set hNT 3
            set hPoly y
            set shape "dot"
            set hIncome 50 + random int 25
            set color yellow
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= i + j + p][sprout 1[
            set breed households
            set hID z
            set hNT 3
            set hPoly y
            set shape "dot"
            set hIncome 75 + random int 75
            set color yellow
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]

          while [z <= i + j + p + q][sprout 1[
            set breed households
            set hID z
            set hNT 3
            set hPoly y
            set shape "dot"
            set hIncome 150 + random int 50
            set color yellow
            set size 1
            ifelse random-float 100 < t
            [set employed?  false]
            [set employed?  true]
            ask patch-here[set occupied? true]
            set z z + 1
          ]]
        ]
    ]]
    set y y + 1
  ]
end

;3.2 Set up househols for every agents in the model
to initialize-hprice
  ask n-of (count households * (balance / 100)) households
  [set flag 1]
  ask households[
    ifelse (flag = 1)
    [set hPrice [price] of patch-here + random int [qv] of patch-here]
    [set hPrice [price] of patch-here - random int [qv] of patch-here]
  ]
end

;3.3 Set the budget for all households
;set budgets
to set-hBudget
  ask households[set hBudget 0.3 * hIncome]
end

;3.4 Setup buyers
;By checking households' affordabilities to define the buyer
to add-buyers
  ;ask households-on patches [
  ask households[
    if hBudget < 0.1 * hPrice;Cannot afford current then find new house, 10% of the house price
    [
      set buyer? true          ;become buyer
      set bidprice hBudget / 0.1 ;set up the max price that the household can afford
      set trade? false
    ]
  ]
end

;3.5 Add sellers into the model
to add-sellers
  ask n-of (count households with [buyer? = true] * D-S) households with [buyer? != true] ;D-S is the slider in Inrerface
    [
      set seller? true      ;become sellers
      set shape "star"
      set askprice 0.8 * hPrice + random-float 0.3 * hPrice ;set the max askprice for each seller
      set trade? false
  ]
end

;3.6 Move
;Let the buyers move around
to move
  ;Move households that can not afford current houses
  ask households with [(buyer? = true) and (trade? = false)][
      ifelse random-float defusion-rate + 1 > 1
      [
        let z patches with [(PID > 0) and (ntype != 1) and (centroid? = true) ]
        move-to one-of z
        set shape "square"
        ;after moving, set the household Neigborhood type
        set hNT [ntype] of patch-here
        ;set polygon ID
        set hPoly [PID] of patch-here
      ]
      [
        let x patches with [(PID > 0) and (ntype = 1) and (centroid? = true)]
        move-to one-of x ;patches with [ntype = [hNT] of myself]
      ]
    ]
end

;3.7 Trade
to trade
  potiential-buyers
  bid
end

;3.7.1 get potiential buyers
to potiential-buyers
  ;if in, get sellers' askprice and check own bidprices
  ask households with [buyer? = true]
  [
    ;let ptrade? false
    let nearseller households with [(seller? = true) and (hPoly = [hPoly] of myself)]
    let askpricelist sort-by < [askprice] of nearseller
    ifelse any? nearseller
    [
      if bidprice > mean askpricelist
      [
        set trade? true
      ]
    ]
    [move]
  ]
end

;3.7.2 bid price
;if buyer's bidprice bid price is grater than 0.9 of seller's askprice and less than 1.5 of seller's askprice
;then trade
to bid
  let c 0
  if c = 2
  [stop]

  ask households with [seller? = true]
  [
    let ptrade false
    let nearbuyer households with [(shape = "x") and (hpoly = [hpoly] of myself) and (buyer? = true) and (trade? = true)]

    ask nearbuyer [
      ;if ((bidprice < 1.5 * [askprice] of myself) and (bidprice > 0.8 * [askprice] of myself) and (hBudget > 0.1 * [hprice] of myself))
      if ((bidprice > 0.5 * [askprice] of myself) and (hBudget > 0.1 * [hprice] of myself))
      ;if ((bidprice > [askprice] of myself) and (hBudget > 0.1 * [hprice] of myself))
      [
        set ptrade true
        set trade? 1
        set buyer? false
        ;set hPrice [askprice] of myself
        set hPrice bidprice
        set hNT [ntype] of patch-here
      ]
    ]


    ifelse (ptrade = true)
    [
      move-in
      set seller? false
      set c c + 1
    ]
    [move]
  ]

  show c
end

;3.8 Move in
to move-in
  update-color
  ;set-hprice
  set-hBudget
end

;;**************************;;
;;****4,UPDATA VARIABLES****;;
;;**************************;;
;4.1, UPDATE GLOBAL & Visual
;4.1.1 UPDATE GLOBAL
to update-global
  update-num-hhold
  update-avg-price

  set n-buyers  count households with [buyer?  = true]
  set n-sellers count households with [seller? = true]
end

to update-num-hhold
  set nhhold-n1 count households with [hNT = 1]
  set nhhold-n2 count households with [hNT = 2]
  set nhhold-n3 count households with [hNT = 3]
end

to update-avg-price
  set avg-n1 sum[hPrice] of households with [hNT = 1] / count households with [hNT = 1]
  set avg-n2 sum[hPrice] of households with [hNT = 2] / count households with [hNT = 2]
  set avg-n3 sum[hPrice] of households with [hNT = 3] / count households with [hNT = 3]
end

;;4.1.2 UPDATE COLOR
to update-color
  ask households with [hNT = 1][set color white]
  ask households with [hNT = 2][set color pink]
  ask households with [hNT = 3][set color yellow]
end

;4.2 UPDATE Households based on economic
to update-household
  update-income
  update-houseprice
  update-bid
  update-ask
end

;4.2.1
to update-income
  ask households
  [
    if (employed? = true)
    [set hIncome hIncome + (0.5 * ln abs economicgrowthrate / 100) * hIncome]
    if (employed? = false)
    [set hIncome hIncome + (economicgrowthrate / 100) * 0.1 * hIncome]
  ]
end
;4. Update Houseprice Not Used
to update-houseprice
ask households
  [
    ;houseprice change
    ;downtwom
    if (ntype = 1)
    [set hPrice hPrice - ((0.5 * economicgrowthrate) / 100) * hPrice]
    ;city sub
    if (ntype = 2)
    [set hPrice hPrice + (0.75 * economicgrowthrate / 100) * hPrice]
    ;far sub
    if (ntype = 3)
    [set hPrice hPrice - (0.25 * economicgrowthrate / 100) * hPrice]
  ]
end

;4. Update Bid
to update-bid
  ask households with [buyer? = true and (trade? = true)]
  [set bidprice hBudget / 0.05]
end

;4. Update Ask
to update-ask
  ask households with [(seller? = true) and (trade? = true)]
  [set askprice 0.8 * hPrice + random-float 0.3 * hPrice]
end

;4.x Do Plot
to do-plot
  set-current-plot "Households Amount in Different Neighborhood"
  set-current-plot-pen "Downtown"
  plot nhhold-n1
  set-current-plot-pen "City-Sub"
  plot nhhold-n2
  set-current-plot-pen "Far-Sub"
  plot nhhold-n3

  set-current-plot "AVG Price in Different Market"
  set-current-plot-pen "Downtown"
  plot avg-n1
  set-current-plot-pen "City-Sub"
  plot avg-n2
  set-current-plot-pen "Far-Sub"
  plot avg-n3
end
@#$#@#$#@
GRAPHICS-WINDOW
205
10
718
524
-1
-1
15.303030303030303
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
ticks
30.0

BUTTON
1
10
59
43
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
62
10
125
43
NIL
draw\n
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
3
255
108
300
Tract Amount
count patches with [PID > 0]
17
1
11

MONITOR
735
324
840
369
Neighborhood 1
nhhold-n1
17
1
11

MONITOR
843
325
948
370
Neighborhood 2
nhhold-n2
17
1
11

MONITOR
950
325
1055
370
Neighborhood 3
nhhold-n3
17
1
11

MONITOR
2
304
107
349
Total households
count households
17
1
11

BUTTON
133
10
196
43
go
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
3
97
197
130
balance
balance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
4
135
198
168
defusion-rate
defusion-rate
0
1
1.0
1
1
NIL
HORIZONTAL

PLOT
733
169
1044
319
AVG Price in Different Market
Time
AVG. Price
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Downtown" 1.0 0 -2674135 true "" "plot avg-n1"
"City-Sub" 1.0 0 -13345367 true "" "plot avg-n2"
"Far-Sub" 1.0 0 -13840069 true "" "plot avg-n3"

PLOT
733
12
1122
162
Households Amount in Different Neighborhood
Time
Amount
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Downtown" 1.0 0 -2674135 true "" "plot nhhold-n1"
"City-Sub" 1.0 0 -13345367 true "" "plot nhhold-n2"
"Far-Sub" 1.0 0 -13840069 true "" "plot nhhold-n3"

BUTTON
4
52
196
85
NIL
go\n
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
122
255
197
300
No. Buyer
n-buyers
17
1
11

MONITOR
122
304
197
349
No. Seller
n-sellers
17
1
11

SLIDER
4
174
198
207
D-S
D-S
0
2
0.5
0.1
1
NIL
HORIZONTAL

MONITOR
3
352
113
397
Going to Trade
count households with [trade? = true]
17
1
11

MONITOR
121
353
198
398
stop trade
count households with [trade? = false]
17
1
11

SLIDER
4
211
197
244
economicgrowthrate
economicgrowthrate
-10
10
-4.0
1
1
%
HORIZONTAL

PLOT
735
375
1049
525
Verification
Time
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Unemployed" 1.0 0 -16777216 true "" "plot sum[hIncome] of households with [employed? = false]"
"Employed" 1.0 0 -7500403 true "" "plot sum[hIncome] of households with [employed? = true]"

PLOT
1049
169
1322
319
Distribution of Houseprice (k)
Price
Number
0.0
10.0
0.0
10.0
true
false
"set-histogram-num-bars 5\nset-plot-x-range 0 300\n\n" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram [hPrice] of households"

MONITOR
4
403
137
448
AVG Houseprice (k)
sum [hPrice] of households / count households
2
1
11

@#$#@#$#@
## WHAT IS IT?

CSS645 Final Project
Spatial ABM

The objective of this model is to simulate the trades between buyers and seller within the three different sub-housing markets in Detroit Tri-County area including downtown (red), city suburban (blue) and far suburban (green) housing markets in the model.

## HOW IT WORKS

### 1.	Load the shapefile into the Net Logo
	Using “DMA_v5.shp”
### 2.	Generate heterogeneous household agents based on the shapefile attributes for the model.
### 3.	Set up all the buyer households and seller households
### 4.	Let the buyers move around the environment
### 5.  Trade function (Key Function of this Model)
Within the same polygon, two lists will be generated, one is sellers’ askprice 	list, the other one is the buyers bidprice list. List will use the turtle ID as the index to locate the price information. Then go through the sellers list, each seller will pick the buyer to trade. 
 5.1.	Find potential buyers
	a.Find the potential buyers within on polygon
	b.If buyer’s bid price is greater than the smallest ask price in the seller list, then put this buyer in the buyers list
	c.If not, move to another polygon
 5.2.	Bid price
	a.Go through the seller list
	b.If stratify the following condition, trade.
		If buyer’s bidprice in range [seller’s askprice, 1.15 * seller’askprice] 
	c.If not, don’t trade.

## CREDITS AND REFERENCES

Crooks, A., Malleson, N., Manley, E., & Heppenstall, A. (2018). Agent-Based Modelling and Geographical Information Systems: A Practical Primer. SAGE.

Filatova, T., Parker, D., & Van der Veen, A. (2009). Agent-based urban land markets: agent’s pricing behavior, land prices and urban land use change. Journal of Artificial Societies and Social Simulation, 12(1), 3.
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
  <experiment name="Different DS" repetitions="10" runMetricsEveryStep="true">
    <setup>setup
draw</setup>
    <go>go</go>
    <timeLimit steps="5"/>
    <metric>count households with [hNT = 1]</metric>
    <metric>count households with [hNT = 2]</metric>
    <metric>count households with [hNT = 3]</metric>
    <metric>avg-n1</metric>
    <metric>avg-n2</metric>
    <metric>avg-n3</metric>
    <enumeratedValueSet variable="D-S">
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="balance">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="defusion-rate">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="economicgrowthrate">
      <value value="-4"/>
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
