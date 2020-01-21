;;DECLARE VARIABLES
;******************
globals [
  max-rent ;initial maximum rent
  min-rent ;initial lowest rent
  highestrent;highest rent in the town during the simulation (most prime property)
  lowestrent ;lowerst rent in the town during the simulation (most inappropriate property)
  max-rent-ability ;max-rent-ability of the rich turtles at the time of initialization of model
  min-rent-ability ;min-rent-ability of the poor turtles at the time of initialization of model
  highestrent-ability ;highest the rich most person is capable to pay for rent during the simulation
  lowestrent-ability ;lowest the poor most person is capable to pay for rent during the simulation
  red-count; to keep track of number of poor people
  blue-count; to keep track of number of middle-class people
  green-count; to keep track of number of rich people
  red-density; monitor poor people's housing density (most important output variable)
  blue-density; monitor middle-class people's hosuing density (most important output variable)
  green-density; monitor rich people's housing density (most important output variable)
  red-averagerent; to keep track of average rents of poor people in the town
  green-averagerent; to keep track of average rents of rich people in the town
  blue-averagerent; to keep track of average rents of middle-class peopel in the town
  averagerent-ability; average rent-ability is calculated at the end of every time-period. This number is used to determine new migrants rent-ability.
  num-searching ;to keep track of how many people are searching house during simulation
  time ;to keep track of time lapsed
  income ;total income of the entire economy. updated every iteration.
  income-red ;share of income that goes to poorest people
  income-blue ;share of income that goes to middle-class people
  income-green ;share of income that goes to rich people
  population ;total population of the town
  slumpop ;total slum population of the town
  num-developers ;number of developers in the town

  ward1pop ;ward 1 population
  ward2pop ;ward 2 population
  ward3pop ;ward 3 population
  ward4pop ;ward 4 population
  ward5pop ;ward 5 population
  ward6pop ;ward 6 population
  ward7pop ;ward 7 population
  ward8pop ;ward 8 population
  ward9pop ;ward 9 population

  ward1slumpop ;ward 1 slum population
  ward2slumpop ;ward 2 slum population
  ward3slumpop ;ward 3 slum population
  ward4slumpop ;ward 4 slum population
  ward5slumpop ;ward 5 slum population
  ward6slumpop ;ward 6 slum population
  ward7slumpop ;ward 7 slum population
  ward8slumpop ;ward 8 slum population
  ward9slumpop ;ward 9 slum population
]

citizens-own [
  rent-ability ; fraction of income available for housing (rent or mortage payment - ownership is not introduced here)
  searching? ; if migrant is searching for new house - set to true when migrant arrives first time or dissatisfied with the place and set to false once found the place
  willing? ; if resident is willing to share the house in face of rising rents
  shared? ; if resident is sharing a facility
  class-updated? ;temporary variable to make sure that each person's class is updated at the end of each iteration
  old ; to record how long resident has been in this city? ;for further analysis on migration and housing relationship
]

patches-own [
  occupied? ; occupancy status of a property
  num-occupants ;number of occupants on a particular property
  num-units ; number of possible units if a developer holds the property
  slum-occupants ;number of poor occupants on a particular property
  rent ; economic rent of the property
  political-rent ; political rent of the property
  rentpercapita ; if people start sharing the house, this variable shows the rent that each person is paying on that property (used for people making decision on housing - they are not worreid about the complete rent, they are worried how much they would pay in a shared accomodation)
  rent-payable ;rent payable is lower for poor people if they live in slums (in proportion with how many poor people live there)
  squatted? ; if house is squatted set to true otherwise false (shared facilities are shown as squatted - however, sharing also means apartment building on a land-parcel, not differentiated in this model yet)
  resicat ;to record residential category. category 3 if occupied by poor, 2 if by middle-class and 1 if rich (useful to calculate density)
  squatresicat; to record squatted properties in each category (useful to calculate density)
  ward ;to record political ward number of town
]

breed [developers developer] ; developers hold a property till it is fully occupied by citizens
breed [citizens citizen] ; citizens that occupy a place


;; INITIALIZATION
;*****************
to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  set max-rent 1000 ; to set maximum rent of a land-parcel at the start of simulation
  set min-rent 100 ; to set minimum rent of a land-parcel at the start of simulation
  set max-rent-ability max-rent ; to set maximum that a turtle can pay for rent based on his/her income and it is kept same as highest rented house in the market for simplicity
  set min-rent-ability min-rent ; to set minimum that a turtle can pay for rent based on his/her income and it is kept same as lowest rented house in the market for simplicity
  set highestrent-ability max-rent-ability ;to set highestrent-ability variable for  use in other calculations related to income-class of turtles etc.
  set lowestrent-ability min-rent-ability ;to set lowestrent-ability variable for  use in other calculations related to income-class of turtles etc.
  set highestrent max-rent
  set lowestrent min-rent
  ask patches [set squatted? false] ;to set initial conditions of squatting? binary to false which changes later as simulation progresses

  ;;INITIAL POPULATION CREATION
  ask n-of ((percent-prime-land * count patches with [abs pxcor < 11 and abs pycor < 11] / 100) + (percent-inappropriate-land * count patches with [abs pxcor < 11 and abs pycor < 11] / 100)) patches with [abs pxcor < 11 and abs pycor < 11]
    [ifelse random-float 1 < (percent-prime-land / (percent-prime-land + percent-inappropriate-land)) ;to declare randomly selected patches in the city-center as prime or inadequate land (proportion is user-specified)
      [set rent max-rent set resicat 1 sprout 1 [set breed citizens set color green set rent-ability rent + random-float 1 * max-rent set rent-payable rent-ability set searching? false set willing? false set class-updated? true set shared? false set old 0]] ;create initial population of rich people with highest rent-ability on land parcels with highest-rent
      [set rent min-rent set resicat 3 sprout 1 [set breed citizens set color red set rent-ability rent + random-float 1 * min-rent set rent-payable rent-ability set searching? false set willing? false set class-updated? true set shared? false set old 0]]] ;create initial population of poor people with lowest rent-ability on land parcels with lowest-rent

  ask patches with [rent = 0 and abs pxcor < 11 and abs pycor < 11]
  [set rent random-float 1 * (max-rent - min-rent) set resicat 2 sprout 1 [set breed citizens set color blue set rent-ability rent + random-float 1 * (max-rent - min-rent) set rent-payable rent-ability set searching? false set willing? false set class-updated? true set shared? false set old 0]] ;create middle-class population on patches with rent varying (normally distributed) between highest-rent and lowest-rent
  ask patches [set rentpercapita rent]

  ;;CREATE POLITICAL WARDS
  ask patches with [pxcor > -26 and pxcor < -8 and pycor > -26 and pycor < -8] [set ward 1 set pcolor 71]
  ask patches with [pxcor > -9 and pxcor < 9 and pycor > -26 and pycor < -8] [set ward 2 set pcolor 72]
  ask patches with [pxcor > 8 and pxcor < 26 and pycor > -26 and pycor < -8] [set ward 3 set pcolor 73]

  ask patches with [pxcor > -26 and pxcor < -8 and pycor > -9 and pycor < 9] [set ward 4 set pcolor 74]
  ask patches with [pxcor > -9 and pxcor < 9 and pycor > -9 and pycor < 9] [set ward 5 set pcolor 75]
  ask patches with [pxcor > 8 and pxcor < 26 and pycor > -9 and pycor < 9] [set ward 6 set pcolor 76]

  ask patches with [pxcor > -26 and pxcor < -8 and pycor > 8 and pycor < 26] [set ward 7 set pcolor 77]
  ask patches with [pxcor > -9 and pxcor < 9 and pycor > 8 and pycor < 26] [set ward 8 set pcolor 78]
  ask patches with [pxcor > 8 and pxcor < 26 and pycor > 8 and pycor < 26] [set ward 9 set pcolor 79]
  ;END OF POLITICAL WARD DECLARATION


  set red-count count citizens with [color = red] ;keep track of number of poor people
  set blue-count count citizens with [color = blue] ;keep track of number of middle-class people
  set green-count count citizens with [color = green]  ;keep track of number of rich people
  set income 0.1 * sum [rent-ability] of citizens
  set income-red 0.1 * sum [rent-ability] of citizens with [color = red]
  set income-blue 0.1 * sum [rent-ability] of citizens with [color = blue]
  set income-green 0.1 * sum [rent-ability] of citizens with [color = green]
end


;;SIMULATION
;***********
to go
  crt (popgrowthrate * population) / 100 [set breed citizens set rent-ability random-exponential averagerent-ability set class-updated? false
    set searching? true
    set willing? false
    set shared? false
    set old 0] ; new arrival of a migrant on a random place in the city center. set to start searching a house and initially not willing to share. migration rate set by the user.
  settle-citizens ;to get homes for people who are searching home
  update-citizens ;update all citizens at the end of the iteration
  update-developers ;update all developers at the end of the iteration
  update-patches  ;update all patches at the end of the iteration
  update-variables ;update all variables at the end of the iteration
  tick
  if (time > 3)
  [do-plots]
  if (time = SimulationRuntime)
  [stop]
end

;;procedures related to turtles start here
;******************************************
to settle-citizens
  ask citizens with [ searching? ]
  [ find-house ] ;to get people roam around for a place to live
end

to find-house
  rt random-float 360 ;all directions
  fd random-float 1 ;one step at a time
  if (any? other citizens-here with [not willing? or color != [color] of myself]) or (rent-payable > rent-ability) ;;
  [find-house] ;if rent is higher than a person can pay, move to next property. if occupants are not willing to share than also move to next property (in essence it is not available)
  move-to patch-here ;or move here
  set searching? false ;and stop searching!
end


to update-citizens
  ask citizens [update-rent-ability update-willingnesstoshare update-searching set class-updated? false update-class update-shared update-old]
end

to update-rent-ability
  set rent-ability rent-ability + (economicgrowthrate / 100) * rent-ability
  ;; procedure below takes unusually high amount time between ticks. will try sometime later
  ;if (color = red)[set rent-ability (rent-ability + ((income-red / red-count) * (rent-ability / (income-red / red-count))))]
  ;if (color = blue)[set rent-ability (rent-ability + ((income-blue / blue-count) * (rent-ability / (income-blue / blue-count))))]
  ;if (color = green)[set rent-ability (rent-ability + ((income-green / green-count) * (rent-ability / (income-green / green-count))))]
end

to update-willingnesstoshare
  if rent-ability < (1 + price-sensitivity) * rentpercapita [set willing? true]
end

to update-searching
  if rent-ability < (1 - staying-power) * rent-payable [set searching? true if count developers-here < 1 and count citizens-here < 2 [hatch 1 [set breed developers set num-units int random-float 8]]]
end

to update-shared
  ifelse any? other citizens-here [set shared? true] [set shared? false]
end

to update-class
  if rent-ability > (mean [rent-ability] of citizens + 1.1 * standard-deviation [rent-ability] of citizens) [set color green set class-updated? true]
  if rent-ability < (mean [rent-ability] of citizens - 0.1 * standard-deviation [rent-ability] of citizens) [set color red set class-updated? true]
  if not class-updated? [set color blue set class-updated? true]
end

to update-old
  set old (old + 1)
end

to recolor-patch  ; patch procedure -use color to indicate rent level
  set pcolor scale-color yellow rent lowestrent highestrent
end

to update-developers
  ask developers [exit];set shape "square" set color cyan

end

to exit
  if count citizens-here > num-units [die]
end
;;***************end of turtles update

to update-patches
  diffuse rent diffusion-rate ;neighborhood effect of property prices.
  ask patches [
    set num-occupants count citizens-here ;number of occupants sharing the property
    if (any? developers-here) [set rentpercapita rent / num-units] ;number of occupants for which the unit is designed by developer
    set rent (rent + (rent * economicgrowthrate / 100) + (0.02 * sum [rent-ability] of citizens-here))
    ifelse num-occupants > 0
    [set occupied? true set rentpercapita rent / num-occupants
      if (any? citizens-here with [color = red]) [set resicat 3]
      if (any? citizens-here with [color = blue])[set resicat 2]
      if (any? citizens-here with [color = green])[set resicat 1]
    ] ; to declare a land parcel as occupied (and hence not available for people searching home)
    [set occupied? false set resicat 0] ;otherwise show property as available

    ifelse num-occupants > 1
    [set squatted? true
      if (any? citizens-here with [color = red])[set squatresicat 3 set slum-occupants count citizens-here with [color = red]] ;count citizens with color red and occupancy higher then 1 as slum-dwellers. declare residential category, further used in density calculation
      if (any? citizens-here with [color = blue])[set squatresicat 2] ;declare residential category, further used in density calculation
      if (any? citizens-here with [color = green])[set squatresicat 1] ;declare residential category, further used in density calculation

      if (any? citizens-here with [color = red] and (ward = 1)) [set rent-payable rent-payable - ward1slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 2)) [set rent-payable rent-payable - ward2slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 3)) [set rent-payable rent-payable - ward3slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 4)) [set rent-payable rent-payable - ward4slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 5)) [set rent-payable rent-payable - ward5slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 6)) [set rent-payable rent-payable - ward6slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 7)) [set rent-payable rent-payable - ward7slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 8)) [set rent-payable rent-payable - ward8slumpop * rent-payable]
      if (any? citizens-here with [color = red] and (ward = 9)) [set rent-payable rent-payable - ward9slumpop * rent-payable]
    ];to identify parcels where density is higher
    [set rent-payable rentpercapita]
    recolor-patch ;create a choropleth of rents in the town
  ]
end

to update-variables
  set red-count count citizens with [color = red]
  set green-count count citizens with [color = green]
  set blue-count count citizens with [color = blue]
  set red-density red-count / (count patches with [resicat = 3])
  set blue-density blue-count / (count patches with [resicat = 2])
  set green-density green-count / (count patches with [resicat = 1])
  set red-averagerent mean [rent-ability] of citizens with [color = red] ;to keep track of rents during simulation in this developing stage. no analytical interest.
  set green-averagerent mean [rent-ability] of citizens with [color = green] ;to keep track of rents during simulation in this developing stage. no analytical interest.
  set blue-averagerent mean [rent-ability] of citizens with [color = blue] ;to keep track of rents during simulation in this developing stage. no analytical interest.
  set highestrent max [rent] of patches ;to calculate highest rent in the town
  set lowestrent min [rent] of patches ;to calculate lowerst rent in the town
  set highestrent-ability max [rent-ability] of citizens ;to calculate highest rent-ability
  set lowestrent-ability min [rent-ability] of citizens
  set averagerent-ability mean [rent-ability] of citizens
  set num-searching (count citizens with [searching?])
  set income income + (economicgrowthrate * income / 100)
  set income-red 0.1 * income * informal-formal-economy ; one way of having unequal distribution. nonetheless, I would come up with something better.
  set income-blue  0.4 * income
  set income-green 0.5 * income

  set population (count citizens) ;total population of the town
  set slumpop sum [slum-occupants] of patches ;total slum  population of the town
  set time time + 1 ;to keep track of time lapsed after simulation started
  set num-developers (count developers) ;keep track of properties held by developers

  set ward1pop sum [num-occupants] of patches with [ward = 1] ;ward-wise population
  set ward2pop sum [num-occupants] of patches with [ward = 2]
  set ward3pop sum [num-occupants] of patches with [ward = 3]
  set ward4pop sum [num-occupants] of patches with [ward = 4]
  set ward5pop sum [num-occupants] of patches with [ward = 5]
  set ward6pop sum [num-occupants] of patches with [ward = 6]
  set ward7pop sum [num-occupants] of patches with [ward = 7]
  set ward8pop sum [num-occupants] of patches with [ward = 8]
  set ward9pop sum [num-occupants] of patches with [ward = 9] ;ward-wise poulation ends

  set ward1slumpop (sum [slum-occupants] of patches with [ward = 1]) / (ward1pop + 1) ;ward-wise slum population in percentage (0 to 1)
  set ward2slumpop (sum [slum-occupants] of patches with [ward = 2]) / (ward2pop + 1)
  set ward3slumpop (sum [slum-occupants] of patches with [ward = 3]) / (ward3pop + 1)
  set ward4slumpop (sum [slum-occupants] of patches with [ward = 4]) / (ward4pop + 1)
  set ward5slumpop (sum [slum-occupants] of patches with [ward = 5]) / (ward5pop + 1)
  set ward6slumpop (sum [slum-occupants] of patches with [ward = 6]) / (ward6pop + 1)
  set ward7slumpop (sum [slum-occupants] of patches with [ward = 7])/ (ward7pop + 1)
  set ward8slumpop (sum [slum-occupants] of patches with [ward = 8]) / (ward8pop + 1)
  set ward9slumpop (sum [slum-occupants] of patches with [ward = 9]) / (ward9pop + 1) ;ward-wise slum poulation ends
end

to do-plots
  set-current-plot "Housing Density"
  set-current-plot-pen "Lower Income Group"
  plot red-density
  set-current-plot-pen "Middle Income Group"
  plot blue-density
  set-current-plot-pen "Higher Income Group"
  plot green-density
end
@#$#@#$#@
GRAPHICS-WINDOW
382
10
900
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

BUTTON
14
10
85
43
Initiate
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
175
10
264
43
Slumulate!
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
910
339
1006
384
LIG Population
red-count
3
1
11

MONITOR
1107
339
1196
384
HIG Population
green-count
3
1
11

SLIDER
9
117
242
150
percent-prime-land
percent-prime-land
0
40
0.0
1
1
percent
HORIZONTAL

SLIDER
9
151
242
184
percent-inappropriate-land
percent-inappropriate-land
0
40
0.0
1
1
percent
HORIZONTAL

MONITOR
168
335
243
380
Highest
Highestrent-ability
0
1
11

MONITOR
7
334
88
379
Lowest
Lowestrent-ability
0
1
11

MONITOR
1010
339
1104
384
MIG Population
blue-count
0
1
11

MONITOR
8
432
126
477
Average Rents
mean [rent] of patches
0
1
11

MONITOR
130
432
287
477
Standard Deviation of Rents
standard-deviation [rent] of patches
0
1
11

MONITOR
909
241
1005
286
LIG Density
red-density
2
1
11

MONITOR
1106
241
1194
286
HIG Density
green-density\n
2
1
11

MONITOR
1008
242
1103
287
MIG Density
blue-density
2
1
11

MONITOR
909
290
1007
335
LIG Avg Rent
red-averagerent\n
0
1
11

MONITOR
1106
290
1195
335
HIG Avg Rent
green-averagerent\n
0
1
11

MONITOR
1010
290
1103
335
MIG Avg Rent
blue-averagerent\n
0
1
11

PLOT
908
30
1224
239
Housing Density
Time
Density
0.0
5.0
0.0
5.0
true
true
"" ""
PENS
"Lower Income Group" 1.0 0 -2674135 true "" ""
"Middle Income Group" 1.0 0 -13345367 true "" ""
"Higher Income Group" 1.0 0 -10899396 true "" ""

SLIDER
8
189
139
222
diffusion-rate
diffusion-rate
0
0.25
0.0
0.01
1
NIL
HORIZONTAL

SLIDER
9
228
127
261
price-sensitivity
price-sensitivity
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
130
229
243
262
staying-power
staying-power
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
8
264
242
297
informal-formal-economy
informal-formal-economy
0
1
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
10
46
242
79
popgrowthrate
popgrowthrate
0
5
0.0
0.01
1
Percent
HORIZONTAL

MONITOR
91
334
164
379
Average
mean [rent-ability] of citizens
0
1
11

MONITOR
245
335
327
380
Std Deviation
standard-deviation [rent-ability] of citizens\n
0
1
11

SLIDER
10
80
242
113
economicgrowthrate
economicgrowthrate
0
5
0.0
0.1
1
Percent
HORIZONTAL

MONITOR
910
455
1006
500
Population
population
0
1
11

MONITOR
910
407
1204
452
GDP
income
0
1
11

MONITOR
1009
455
1103
500
Slum Population
slumpop
0
1
11

BUTTON
90
10
171
43
RentMap
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
911
504
1205
549
Properties held by Developers
num-developers
0
1
11

MONITOR
1106
455
1205
500
% Slum Population
slumpop / population * 100
1
1
11

INPUTBOX
268
10
377
70
SimulationRuntime
0.0
1
0
Number

TEXTBOX
9
314
229
348
Summary of Rent-abilities:
14
0.0
1

TEXTBOX
10
413
160
431
Summary of Rents:
14
0.0
1

TEXTBOX
911
387
1061
405
City level statistics:
14
0.0
1

MONITOR
8
488
126
533
Average Rent-payable
mean [rent-payable] of patches
0
1
11

MONITOR
130
488
286
533
Std Deviation of Rent-payable
standard-deviation [rent-payable] of patches
0
1
11

TEXTBOX
910
10
1101
44
Income-group Statistics:
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

Preface from Slumulation 1.0: This is a model to understand slum formation in cities. Income-inequalities coupled with market prices driven by a few high-income group drives majority of new migrants to either occupy an inappropriate land for habitat or illegally share the housing. Hihger density in slums on the face of rising land prices is explained.

Slumulation 2.0: This version of Slumulation adds additional dimensions to the original model. Politics of slums is added. Two primary actors, developers and local politicians are added. Spatial scale at which politicans operate is an electorate ward. Model explains how voting power adds to political cost of eviction and hence makes certain sites unavailable for formal development despite being prime locations.

## HOW TO USE IT

Each pass through the GO function represents a month in the time scale of this model.

The POPGROWTHRATE slider sets the monthly population growth rate.

The PERCENT-PRIME-LAND slider sets the percentage prime land in the city core.  The model is initialized to have a total number of rich households equal to number of prime land parcels.

The PERCENT-INAPPROPRIATE-LAND slider sets the percentage inadequate land in the city core. The model is initialized to have a total number of poor households equal to number of inappropriate land parcels.

The DIFFUSION-RATE slider sets how fast the price diffusion occurs in the landscape. Higher the diffusion-rate, faster the price diffuses.

The PRICE-SENSITIVITY slider determines how early a turtle 'senses' approaching prices that it can not afford whereas STAYING-POWER slider determines how long a turtle can stay before it actively starts searching for a new location that it can afford. Together they provide shorter or longer 'window of period' to find partners to share the facility.

The INFORMAL-FORMAL-ECONOMY slider determines if informal sector is growing or formal sector is growing. if informal sector is growing, it increases income of low-income households proportionately more compared to high-income families. Conversely when formal economy is growing, it makes rich households rich faster than it increases income of poor households. When formal economy is growing, housing prices also rise more than when informal economy is growing.

The LIG POPULATION, MIG POPULATION and HIG POPULATION  monitors display the number of lower-income households ,middle-income households and higher-income households respectively.

The LIG-DENSITY MIG-DENSITY and HIG-DENSITY monitors dispay the density of housing for LIG, MIG and HIG respectively.

The LIG-AVERAGERENT, MIG-AVERAGERENT, HIG-AVERAGERENT monitors display the average of rents paid by LIG, MIG and HIG respectively.

The AVERAGE RENTS and STANDARD DEVIATION OF RENTS monitors display the average rents and standard deviation of the rents of land parcels in the entire city.

The SLUMULATE! button runs the model.  A running plot is also displayed of the red-density, blue-density and green-density over time.

The SIMULATIONRUNTIME stops the simulation at the specified number of ticks in that box (user-specified).

## THINGS TO NOTICE

How does different percent of prime land affects density for poor (reds)?

Does the formalgrowth rate give rise to higher densities of reds  (less affordable hosuing for poor)?

Does the reds always end up with high densities?

## THINGS TO TRY

Try running different experiments with different settings on sliders and see if reds remain lower in density (less slums)?

## EXTENDING THE MODEL

Extension with introduction of political-price as discussed in the associated paper is the next extension. Political price gives poor chance to counteract against rising economic prices of land and eviction. Density is currently helping them to divide the rents and stay on prime lands but after a while they can't sustain if political cost was not associated with eviction of slums. This concept would be brought in next extension.
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
