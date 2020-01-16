extensions [gis]

breed [nurses nurse]
breed [patients patient]
breed [cleaners cleaner]

nurses-own [
  clean ;; determines how many nurses are practicing proper hygiene
]

globals[
  upper  ;; Crooks (2018) (see full citations at bottom)
  lower  ;; Crooks (2018)
  ;; move-speed ;;may be used in model expansion ;; Crooks (2018)
  ;; alist  ;; may be used in model expansion ;; Crooks (2018)
  ;; the-row ;; may be used in model expansion ;; Crooks (2018)

  elevation-dataset ;; Crooks (2018)
  death-rate ;; chance of death once infected
  patch-patch-spread ;; chance of transmission from infected patch to neighboring patch
  carrier-patch-spread ;; chance of transmission from agent to patch
  dead-patients ;; count of dead patients
  recovered-patients ;; count of recovered patients

]

turtles-own[
  t-infected?    ;; has the person been infected with the disease? ;; Rand and Wilensky (2008)
  energy ;; patients lose energy once infected ;; Rand and Wilensky (2008)
]

patches-own[
  exit  ;;1 if it is an exit, 0 if it is not ;; Crooks (2018)
  ;; elelist may be used in model expansion ;; Crooks (2018)
  elevation  ;;elevation at this point is equal to shortest distance to exits Crooks (2018)
  ;; path  ;; may be used in model expansion Crooks (2018)
  p-infected?  ;; in the environmental variant, has the patch been infected?
  p-infect-time  ;; how long until the end of the patch infection?
]


to setup
 ca ;; Wilensky (2018)
 constants ;; Wilensky (2018)
 file-close ;; Crooks (2018)
 set elevation-dataset gis:load-dataset "data/mincosf1.asc" ;; Crooks (2018)
 gis:set-world-envelope gis:envelope-of elevation-dataset ;; Crooks (2018)
 gis:apply-raster elevation-dataset elevation ;; Crooks (2018)
 ask patches [set p-infected? false ] ;; Rand and Wilensky (2008)
 ask patches with [elevation = 0 ][set exit 1] ;; Crooks (2018)
 ask patches [ifelse (elevation <= 0) or (elevation >= 0)[][set elevation 9999999]] ;; Crooks (2018)
 show_elevation ;; Crooks (2018)


 ;; create people
 ask n-of num-patients patches with [ ;; create patients ;; Rand and Wilensky (2008)
    elevation < 9999999 and exit != 1 ;; Crooks (2018)
    and (pycor = one-of (range -64 -53) ;; confine patients to patient rooms
      or (pycor = one-of (range -45 -34)))
  ][
    sprout 1 [
      set color gray
      set breed patients
      set size 2
      set shape "person"
      set energy 2419200 ;; patients die (or recover) within 28 days aka 2419200 seconds!
      set dead-patients 0 ;; count dead-patients
      set recovered-patients 0 ;; count patients who recover
    ]
  ]
  ifelse ICU-Isolation [ ;; if ICU-Isolation is on, nurses stay in ICU ward (those assigned to the ICU stay in that ward)
    ask n-of num-nurses patches with [ ;; create nurses
    elevation < 9999999 and exit != 1 ;; Crooks (2018)
      and pycor = one-of (range -51 -46)][
      sprout 1 [
        set color blue - 2
        set breed nurses
        set size 2
        set shape "person doctor"
        ]
    ]
    ask n-of num-cleaners patches with [ ;; create cleaners
    elevation < 9999999 and exit != 1 ;; Crooks (2018)
      and pycor = one-of (range -51 -46)][
       sprout 1 [
         set color blue - 2
         set breed cleaners
         set size 2
         set shape "person service"
      ]
    ]
  ]
  [
    ask n-of num-nurses patches with [ ;; nurses move all over hospital
    elevation < 9999999 and exit != 1][ ;; Crooks (2018)
      sprout 1 [
        set color blue - 2
        set breed nurses
        set size 2
        set shape "person doctor"
      ]
    ]
    ask n-of num-cleaners patches with [ ;; cleaners move all over hospital
    elevation < 9999999 and exit != 1][ ;; Crooks (2018)
      sprout 1 [
        set color blue - 2
        set breed cleaners
        set size 2
        set shape "person service"
      ]
    ]
  ]
 ask turtles [set t-infected? false] ;; modified from Rand and Wilensky (2008)
 infect ;; modified from Rand and Wilensky (2008)
 recolor ;; modified from Rand and Wilensky (2008)
 reset-ticks ;; modified from Rand and Wilensky (2008)
end

to infect ;; Rand and Wilensky (2008)
  ask n-of num-infected-patients patients [
    set t-infected? true ;; Rand and Wilensky (2008)
    ;; initial patients infected
    set p-infected? true ;; Rand and Wilensky (2008)
    ] ;; infected their patches
  ask n-of num-infected-nurses nurses [ ;; initial nurses infected
     set t-infected? true ;; modified from Rand and Wilensky (2008)
     set p-infected? true ;; modified from Rand and Wilensky (2008)
  ]
end

to recolor
  let min-e min [elevation] of patches with [elevation < 9999999] ;; Crooks (2018)
  let max-e max [elevation] of patches with [elevation < 9999999] ;; Crooks (2018)
  ask nurses [ ;; modified from Rand and Wilensky (2008)
    set color ifelse-value t-infected? [ green ] [ blue - 2 ]
  ] ;; carrier nurses turn green
  ask patients [
    set color ifelse-value t-infected? [ red ] [ gray ]
  ] ;; infected patients turn red
  ask cleaners [
    set color ifelse-value t-infected? [ green ] [ orange ]
  ] ;; carrier cleaners turn green
  ask patches [ if elevation < 9999999 and pycor < -33 [
    ;; infected patches turn yellow
    set pcolor ifelse-value p-infected? [ yellow ] [ blue + 4]]
  ]
end

to constants ;; Wilensky (1998)
  set death-rate .56 ;; infected patients have a 56% chance of death after a long period of infection
  set patch-patch-spread .025 ;; patches infect neighboring patches .025% of the time
  set carrier-patch-spread Environmental-spread ;; users can choose how easily the fungus spreads from carrier to environment (patch)-recommend default at lowest setting
end

to spread-infection ;; Rand and Wilensky (2008)
  ask patches with [ p-infected? ] [ ;; Rand and Wilensky (2008) ;; infects patches
    ask neighbors with [p-infected? = false] [ ;; Rand and Wilensky (2008) ;; spread of infection to neighboring patches
      if (random-float 100.0 < patch-patch-spread) and pcolor != gray ;; first part modified from fsondahl (2009);; second part ensures that patches outside of the hospital do not get infected
      [set p-infected? true] ;; infects patch Rand and Wilensky (2008)
    ]
  ]

  ask patients with [ t-infected? ] [ ;; set probability of infection ;; modiified from Rand and Wilensky (2008)
      ask turtles-here [ set t-infected? true ] ;; modiified from Rand and Wilensky (2008)
    if random-float 100 < Environmental-spread [set p-infected? true] ;; patients spread infection to patch they are on (Environmental-spread) % of the time ;; modified from fsondahl (2009)
  ]

  ask cleaners with [ t-infected? ] [ ;; set probability of infection ;; cleaners spread infection to other cleaners and nurses, not patients (they don't touch them!) ;; modified from Rand and Wilensky (2008)
    ask turtles-here with [breed != patients] [ set t-infected? true ]
    if random-float 100 < Environmental-spread [set p-infected? true] ;; cleaners spread infection to patch they are on Environmental-spread% of the time ;; modified from fsondahl (2009)
  ]


  ask nurses with [ t-infected? ] [ ;; set probability of infection ;; nurses spread infection to patients, and make other nurses/cleaners carriers ;; modified from Rand and Wilensky (2008)
    ask turtles-here [ set t-infected? true ] ;; Rand and Wilensky (2008)
    if random-float 100 < Environmental-spread [set p-infected? true] ;; nurses spread infection to patch they are on Environmental-spread% of the time ;; modified from fsondahl (2009)
  ]

  ask turtles with [ p-infected? ] [ ;; any patient on an infected patch becomes infected and any cleaner/nurse becomes carrier ;; Rand and Wilensky (2008)
      set t-infected? true ;; ; Rand and Wilensky (2008)
    ]

  ask patients with [ t-infected? ] [ ;; infected patients lose energy over time (see death) ;; Rand and Wilensky (2008)
    set energy energy - 1 ;; Rand and Wilensky (2008)
  ]

  if Enhanced-cleaning [ ;; if a cleaner is in an infected patch, it disinfects the patch and the cleaner itself ;; modified from Rand and Wilensky (2008)
    ask cleaners with [ p-infected? ] [ ;; Rand and Wilensky (2008)
      set p-infected? false ;; Rand and Wilensky (2008)
      set t-infected? false ;; Rand and Wilensky (2008)
    ]
  ]
end

to go
  if all? patients [t-infected?] [stop] ;; Rand and Wilensky (2008)
  if all? patches [p-infected?] [stop] ;; modified from Rand and Wilensky (2008)
  spread-infection ;; Rand and Wilensky (2008)
  recolor ;; Rand and Wilensky (2008)
  death ;; Rand and Wilensky (2008)
  move ;; Rand and Wilensky (2008)
  tick ;; Rand and Wilensky (2008)
end



to death ;; Rand and Wilensky (2008)
  ask patients with [ t-infected? ] [ ;; if patients are infected, they lose energy;; Rand and Wilensky (2008);
    if energy < 0 [ ;; Rand and Wilensky (2008)
      ifelse random-float 100 > death-rate
        [ set recovered-patients recovered-patients + 1 set t-infected? false
         ] ;;
        [ set dead-patients dead-patients + 1 die ] ;; Based on code (no author) retrieved from https://www.howtobuildsoftware.com/index.php/how-do/bD8i/netlogo-how-can-i-count-dead-turtles-in-netlogo
    ]
  ]
end


to move
  ask nurses [set clean n-of ((clean-nurses * num-nurses) / 100) nurses] ;; modified from Rand and Wilensky (2008)
  ask nurses [
    ifelse
    not any? turtles-on patch-ahead 1
    and [pcolor] of patch-ahead 1 != gray
    [ fd 1 ][ rt random 180 ]
    if ICU-Isolation and [pycor] of patch-ahead 1 = -33 [ rt 180] ;; if Quarantine setting is on, nurses cannot leave ICU (they are assigned only to ICU)
    if clean = true and [pycor] of patch-ahead 1 = one-of (range -33 -45 -53) [set t-infected? false set p-infected? false] ;; nurses disinfect whenever they leave a patient room
    if not can-move? 1 [rt random 180]
    if t-infected? and any? turtles-on patch-ahead 1 [ask turtles-on patch-ahead 1 [set t-infected? true]]
    if not can-move? 1 and t-infected? = true and p-infected? = false [set p-infected? true]
  ]
  ask cleaners [ ;; Rand and Wilensky (2008)
    left random 90 ;; Rand and Wilensky (2008)
    right random 90 ;; Rand and Wilensky (2008)
    ifelse [pcolor] of patch-ahead 1 != gray
    [fd 1 ] [ rt random 180 ] ;; Rand and Wilensky (2008)
    if ICU-Isolation and [pycor] of patch-ahead 1 = -33 [ rt 180] ;; if Quarantine setting is on, cleaners cannot leave ICU (they are assigned only to ICU)
    if not can-move? 1 [rt random 180] ;; Rand and Wilensky (2008)
    if not can-move? 1 and t-infected? = true and p-infected? = false [set p-infected? true]
  ]
  ask patients [ ;; Rand and Wilensky (2008)
    if not t-infected? [ ;; move slightly to show life
     fd .25
     left 90
    ]
    ]
end



to show_elevation
  let min-e min [elevation] of patches with [elevation < 9999999] ;; Crooks (2018)
  let max-e max [elevation] of patches with [elevation < 9999999] ;; Crooks (2018)

  ask patches [
    ifelse elevation < 9999999 [ifelse pycor < -33 [set pcolor blue + 4][set pcolor pink + 3]] ;; setting up ICU (light blue) and non-ICU (light pink) wards ;; partially Crooks (2018)
    [set pcolor gray]
  ]
end
;; Code cited
;; Crooks, A. T. (2018). Pedestrians Exiting Building [NetLogo code]. Retrieved from 	https://github.com/abmgis/abmgis/tree/master/Chapter06-	IntegratingABMandGIS/Models/Pedestrians_Exiting_Building.
;; fsondahl (2009). NetLogo code. Retrieved from http://netlogo-users.18673.x6.nabble.com/Percentage-of-turtles-td4869337.html
;; How can I count dead turtles in Netlogo [NetLogo code]. Retrieved from https://www.howtobuildsoftware.com/index.php/how-do/bD8i/netlogo-how-can-i-count-dead-turtles-in-netlogo
;; Rand, W., Wilensky, U. (2008). NetLogo Spread of Disease model. 	http://ccl.northwestern.edu/netlogo/models/SpreadofDisease. Center for 	Connected Learning and Computer-Based Modeling, Northwestern Institute 	on Complex Systems, Northwestern University, Evanston, IL.
;; Wilensky, U. (1998). NetLogo Virus model. http://ccl.northwestern.edu/netlogo/models/Virus. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
@#$#@#$#@
GRAPHICS-WINDOW
258
10
1035
503
-1
-1
3.752
1
10
1
1
1
0
0
0
1
-102
102
-64
64
0
0
1
seconds
1.0

BUTTON
7
10
70
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
76
10
139
43
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

SLIDER
8
165
246
198
num-patients
num-patients
0
100
20.0
2
1
NIL
HORIZONTAL

PLOT
1039
37
1239
187
Patients
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
"Dead" 1.0 0 -16777216 true "" "plot dead-patients"
"Recovered" 1.0 0 -7500403 true "" "plot recovered-patients"
"Infected" 1.0 0 -2674135 true "" "plot count patients with [ t-infected? ]"

PLOT
1039
189
1239
350
Infected/Carriers
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Patients" 1.0 0 -16777216 true "" "plot count patients with [t-infected?]"
"Cleaners" 1.0 0 -7500403 true "" "plot count cleaners with [t-infected?]"
"Nurses" 1.0 0 -2674135 true "" "plot count nurses with [t-infected?]"

SLIDER
8
201
245
234
num-nurses
num-nurses
(num-patients) * .5
num-patients
20.0
1
1
NIL
HORIZONTAL

SLIDER
7
286
201
319
num-infected-patients
num-infected-patients
0
num-patients
1.0
1
1
NIL
HORIZONTAL

SLIDER
7
321
201
354
num-infected-nurses
num-infected-nurses
0
num-nurses
0.0
1
1
NIL
HORIZONTAL

SLIDER
7
372
207
405
Environmental-spread
Environmental-spread
0
100
0.0
1
1
NIL
HORIZONTAL

SWITCH
8
93
183
126
Enhanced-cleaning
Enhanced-cleaning
1
1
-1000

SLIDER
8
237
244
270
num-cleaners
num-cleaners
0
100
15.0
1
1
NIL
HORIZONTAL

TEXTBOX
13
417
163
473
* This refers to how often the fungus spreads to surfaces when workers and cleaners move 
11
0.0
1

PLOT
1039
352
1239
502
Infected Patches
Time
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Patches" 1.0 0 -16777216 true "" "plot count patches with [p-infected?]"

SWITCH
7
57
146
90
ICU-Isolation
ICU-Isolation
1
1
-1000

SLIDER
7
129
245
162
clean-nurses
clean-nurses
0
100
100.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This is a model of the spread of multi-drug resistant C. auris in a hospital setting. 


## HOW IT WORKS

Patients, nurses, and cleaners exist in the hospital. Patients may become infected by the fungus through interaction with nurses or the environment. 

Nurses and cleaners may become carriers by coming into contact with infected patients or other carriers. 

Patches can become infected through agent contact (based on Environmental-spread setting) or neighboring patches (0.025% chance of infection).

Blue patches represent the ICU and pink patches represent other hospital wards. 

When ICU-Isolation is turned OFF, nurses and cleaners can move freely around the hospital. When this is turned ON, nurses and cleaners are restricted to the ICU (blue patches)


## HOW TO USE IT

Use the following switches:
Enhanced-cleaning to explore effects of cleaners properly disinfecting the hospital
ICU-Isolation to explore quarantine effects on the ICU environment

Change the number of patients, nurses, and cleaners in the hospital
Nurse-patient ratios must stay within 1:1-1:4 

Change the initial number of patients and nurses infected

Adjust the Environmental-spread slider to increase or decrease carrier spread of infection

Adjust $%-clean-nurses to adjust the proportion of nurses practicing proper hygiene protocols when entering/exiting patient rooms



## EXTENDING THE MODEL

Assigning cleaners and workers shifts. For example, set a shift length of 8 hours. Nurses and cleaners will die and be replaced by new, uninfected nurses and cleaners. Vary the shifts to increase external validity. Replace patients who die with new patients.

Add a A* algorithm to turtles’ routes so that cleaners and workers move to assigned locations (e.g. patient rooms).

Add a nursing station, supplies closet, and other locations of interest.
Changing the design of the hospital to a radial or double-corridor layout.

Add behavior changes to the agents as the fungus spreads. For instance, if multiple patients get sick, make the nurses or cleaners adjust their hygiene and disinfectant habits.


## NETLOGO FEATURES

Nurses and cleaners are limited to the hospital space determined by the GIS extension files added to the code. 

## RELATED MODELS

To explore disease spread, refer to the Spread of Disease model in the NetLogo Models Library:

Rand, W., Wilensky, U. (2008). NetLogo Spread of Disease model. 	http://ccl.northwestern.edu/netlogo/models/SpreadofDisease. Center for 	Connected Learning and Computer-Based Modeling, Northwestern Institute 	on Complex Systems, Northwestern University, Evanston, IL. 


To see more information on the GIS extension, refer to:
Crooks, A. T. (2018). Pedestrians Exiting Building [NetLogo code]. Retrieved from 		https://github.com/abmgis/abmgis/tree/master/Chapter06-	IntegratingABMandGIS/Models/Pedestrians_Exiting_Building. 
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

person doctor
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true true 105 90 60 195 90 210 135 105
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1 true false 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true false 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person service
false
0
Polygon -7500403 true true 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -1 true false 120 90 105 90 60 195 90 210 120 150 120 195 180 195 180 150 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Polygon -1 true false 123 90 149 141 177 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Rectangle -16777216 true false 179 164 183 186
Polygon -2674135 true false 180 90 195 90 183 160 180 195 150 195 150 135 180 90
Polygon -2674135 true false 120 90 105 90 114 161 120 195 150 195 150 135 120 90
Polygon -2674135 true false 155 91 128 77 128 101
Rectangle -16777216 true false 118 129 141 140
Polygon -2674135 true false 145 91 172 77 172 101

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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count patients with [ t-infected? ]</metric>
    <metric>dead-patients</metric>
    <metric>recovered-patients</metric>
    <metric>count patches with [ p-infected? ]</metric>
    <metric>count workers with [ t-infected? ]</metric>
    <metric>count cleaners with [ t-infected? ]</metric>
    <enumeratedValueSet variable="disease-decay">
      <value value="1000"/>
      <value value="1000"/>
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected-patients">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Enhanced-cleaning">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-workers" first="1" step="20" last="101"/>
    <enumeratedValueSet variable="Show_path?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-patients" first="1" step="20" last="101"/>
    <steppedValueSet variable="num-infected-workers" first="0" step="1" last="1"/>
    <enumeratedValueSet variable="Number_of_exits">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-cleaners" first="0" step="20" last="100"/>
  </experiment>
  <experiment name="TEST" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>count patients with [ t-infected? ]</metric>
    <metric>dead-patients</metric>
    <metric>recovered-patients</metric>
    <metric>count patches with [ p-infected? ]</metric>
    <metric>count workers with [ t-infected? ]</metric>
    <metric>count cleaners with [ t-infected? ]</metric>
    <enumeratedValueSet variable="num-infected-patients">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Enhanced-cleaning">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-workers" first="10" step="10" last="50"/>
    <enumeratedValueSet variable="Show_path?">
      <value value="true"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-patients" first="10" step="10" last="50"/>
    <steppedValueSet variable="num-infected-workers" first="0" step="1" last="1"/>
    <enumeratedValueSet variable="Number_of_exits">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="num-cleaners" first="0" step="25" last="50"/>
  </experiment>
  <experiment name="Presentation" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="25000"/>
    <metric>count patients with [ t-infected? ]</metric>
    <metric>dead-patients</metric>
    <metric>recovered-patients</metric>
    <metric>count patches with [ p-infected? ]</metric>
    <metric>count workers with [ t-infected? ]</metric>
    <metric>count cleaners with [ t-infected? ]</metric>
    <enumeratedValueSet variable="num-infected-patients">
      <value value="1"/>
      <value value="2"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Environmental-spread">
      <value value="0"/>
      <value value="20"/>
      <value value="50"/>
      <value value="75"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Enhanced-cleaning">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-workers">
      <value value="5"/>
      <value value="10"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Show_path?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-patients">
      <value value="5"/>
      <value value="20"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-infected-workers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number_of_exits">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-cleaners">
      <value value="1"/>
      <value value="5"/>
      <value value="15"/>
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
