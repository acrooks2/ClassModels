;;;-------------------------------------------
;;;
;;;
;;;
;;;   Pirates and Patrols in the Malacca Straits
;;;
;;;---------------------------------------------------------

;;;    Globals
;
;  Three agentsets of turtles are defined via the "vessel_type" variable:
;
;    Type 1 = Patrol Boats
;    Type 2 = Cargo Ships
;    Type 3 = Pirates
;;;

turtles-own [ vessel_type nearest_police? direction distance_traveled under_attack? attack_location rescue_underway? rescue_status]
patches-own [in_patrol_area? in_the_strait?]
globals [total_cargo_ships successful_ship_transits number_attacks lost_ships number_police rescued_ships];.....counters for various hijacking stax


breed[police polices]
breed[pirate pirates]
breed[cargo cargos]

police-own[engaged?]
cargo-own [death_counter]

;;;;; setup of model environment, turtles, and patches
;
;  Setup imports __.gif file of patrol areas.  Patrol areas map was created in ArcGIS and
;   exported as a gif file.  Patrol areas are of color = 96.9 in the gif file
;;;;;


to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-turtles
  ask patches [set in_patrol_area? false]
  import-pcolors "5 patrol area.gif"

  ask patches [set in_the_strait? true]      ; establishes variable as Boolean

  ask patches with [pcolor = 96.9][set in_patrol_area?  true];  uses color of image to set bounds on patrol area (relates to patrol boats)

  ask patches with [pcolor = 88.2][set in_the_strait? false]; uses color to set bounds on limit of the straits (relates to pirate vessels)

  ask patches with [pcolor = 37.8][set in_the_strait? false]; uses color to set bounds on limit of the straits (relates to pirate vessels)

  set lost_ships 0

  setup-graphs

end



;;;;; Create all Vessels  (probably need to break this up into separate procedures for each vessel type)

to setup-turtles
  set-default-shape turtles "default"

  ;;;;; Create the Patrol Boat turtles

  create-police 5
  ask turtle 0 [setxy -90 129 set color black set size 10 set vessel_type 1]
  ask turtle 1 [setxy -25 31 set color black set size 10 set vessel_type 1]
  ask turtle 2 [setxy 38 -57 set color black set size 10 set vessel_type 1]
  ask turtle 3 [setxy 116 -129 set color black set size 10 set vessel_type 1]
  ask turtle 4 [setxy 221 -196 set color black set size 10 set vessel_type 1]



  ;;;;;;;;Create  Pirate Vessels

  create-pirate number_pirates [setxy 21 144 set color red set size 10 set vessel_type 3]



end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;----------------- Main "go" module--------------------------
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go
  tick

  if ticks >= 8640 [ stop ]

  every 5 [ask patch -145 200 [sprout-cargo 1 [setxy -145 200 set color yellow set size 15 set vessel_type 2 set heading 140 set death_counter 50]] set total_cargo_ships total_cargo_ships + 1]

  if count pirate < number_pirates
      [create_new_pirate]

  ask police [patrol]



  ask cargo

  [ifelse under_attack? = true
    [under_attack]
    [ifelse any? pirate in-radius 20
      [under_attack
        set number_attacks number_attacks + 1
      ]
      [transit]
    ]
  ]


  ask pirate [hijack]

  set rescued_ships number_attacks - lost_ships

  update-graphs

end

to setup-graphs
  set-current-plot "Events"

end

to update-graphs



  set-current-plot "Events"

  ;set Pirates number_pirates
  ;set-current-plot-pen "Pirates"
  ;plot number_pirates

  ;set Attacks number_attacks
  set-current-plot-pen "Attacks"
  plot number_attacks
  ;
  ;set Losses lost_ships
  set-current-plot-pen "Losses"
  plot lost_ships
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;       Movement rules...all turtle types
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;..........Patrol Boat Movement Rules............
;
;      Patrol boats operate within assigned patrol areas.  As they patrol, the "look ahead" three patches to see whether they are
;       approaching the bounds of their patrol area.  If so, they will turn around and continue their normal, straight-line patrol
;       movement.  The look-ahead also detects whether they are approaching a shoreline (which also causes them to come about.
;
;;;;;;;

to patrol  ;;;;; Basic patroling movements of police
           ;
  ifelse edge_of_patrol_area
      [turn-around]
  [fd 1
    ifelse edge_of_patrol_area
          [turn-around]
    [fd 1]]
end

to-report edge_of_patrol_area
  report not [in_patrol_area?] of patch-ahead 3
end

to turn-around
  lt 170
  fd 2
end


to rescue


  set heading towards myself
  fd 1
  set engaged? true
  ask other police [patrol]
  ifelse patch-here = attack_location
  [die]
  []



end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;...........Cargo Ship Movement Rules...........
;
;  Ships begin at north end of straits and travel in prescribed
;   shipping lane.  Ships navigate by tracking distance traveled
;   with a single course change after 455 patches traveled.  Upon
;   successful transit of the strait (after 632 total patches),
;   the ship updates the successful transit counter and then "dies".
;   This represents a ship arriving at Port of Singapore.
;
;;;;;;

to transit ; cargo ship movement

  ifelse distance_traveled = 455
    [set heading 119]
  [fd 1]
  set distance_traveled distance_traveled + 1
  ifelse distance_traveled = 632
    [set successful_ship_transits successful_ship_transits + 1
      ask patch-at -145 200 [sprout-cargo 1 [setxy -145 200 set color yellow set size 15 set vessel_type 2 set heading 140]set total_cargo_ships total_cargo_ships + 1] die ]
  []

end

to under_attack


  ask police with-min [distance myself] [rescue]

  set color red
  set under_attack? true
  set attack_location patch-here
  move-to attack_location
  set death_counter death_counter - 1
  if death_counter = 0 [set color gray set lost_ships lost_ships + 1]
  if any? police in-radius 1 [set rescue_status rescue_status + 1]
  if rescue_status >= 10 [set color blue set rescued_ships rescued_ships + 1]
  ask pirate in-radius 20 [die]

end






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;.........Pirates Movement Rules................
;
;   Pirate movement limited to within the straits.  Pirates
;    can cross patrol area boundaries at will.
;
;;;;;;


to hijack

  ifelse inside_straits
      [turn-around]
  [pirate-movement
    ifelse inside_straits
          [turn-around]
    [pirate-movement]
  ]
end

to-report inside_straits
  report not [in_the_strait?] of patch-ahead 3
end



to pirate-movement
  fd 1

end

to create_new_pirate
  ask patch 54 -144 [sprout-pirate 1 [setxy 54 -144 set color red set size 10 set vessel_type 3]]
end




@#$#@#$#@
GRAPHICS-WINDOW
12
64
1110
639
-1
-1
1.009
1
10
1
1
1
0
1
0
1
-540
540
-280
280
0
0
1
ticks
30.0

BUTTON
725
21
789
54
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
798
21
861
54
Go
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

MONITOR
962
364
1078
413
Successful Transits
successful_ship_transits
0
1
12

SLIDER
900
19
1072
52
number_pirates
number_pirates
1
10
10.0
1
1
NIL
HORIZONTAL

MONITOR
887
100
1078
149
Total Number of Attacks
number_attacks
17
1
12

MONITOR
974
202
1077
251
Rescued Ships
rescued_ships
17
1
12

MONITOR
973
151
1077
200
Lost to Hijacks
lost_ships
17
1
12

PLOT
77
470
479
616
Events
ticks
number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Attacks" 1.0 0 -2674135 true "" ""
"Losses" 1.0 0 -16777216 true "" ""

MONITOR
935
318
1078
363
Cargo Ships Entering Straits
total_cargo_ships
17
1
11

TEXTBOX
30
24
555
54
Piracy on Commercial Vessels in the Malacca Straits
20
125.0
1

@#$#@#$#@
## WHAT IS IT?

This project models maritime piracy activities in present-day, in the area of the Malacca Straits: a key maritime navigation corridor between Malaysia and Indonesia. The primary question this model addresses is the effect of increased piracy on a maritime security force�s ability to neutralize piracy against commercial cargo vessels.   Since this question involves differing behaviors of multiple actors, it makes it a candidate for Agent-based Modeling (ABM).  Additionally, the relative simplicity of the terrain (open water) means that a model can focus on agent behaviors with manageable agent/terrain interaction (movement limited by locations of landmasses).   Agent behaviors in this model will be simplified to movement factors, plus basic behaviors as pirates initiate attacks on cargo vessels.  The numbers of pirates are varied, but most behaviors kept constant

This is only an intitial model of piracy.  If you decide to modify the model (and I do recommend that), please let me know what changes you made and how the results turned out.

## HOW IT WORKS

The model begins by importing a single .gif file which depicts the major land masses around the Malacca Straits, plus "patrol areas" in the Straits which limit police boat movement.

The user then selects the number of pirate vesssels and hits the "go" button.

## HOW TO USE IT

Recommend that the model be run only at "normal speed".  This is because the commercial cargo vessel rate of entering the Straits is presently set via the real-world system clock.   If you slow the model rate, you will be able to inspect some of the ways that the agent interact, but the cargo vessel traffic volume will appear to grow unrealistically large.

This aspect of the model may be corrected in future versions.

## THINGS TO NOTICE

Note that when 2 or more attacks occur in the same patrol area, the single police boat assigned to that area will attempt to render assistance to all ships in distress.  This has the effect of the patrol boat oscillating back and forth between the several cargo vessels.   The patrol boats may be having some success in covering more than one distress call, but this has not been quantified as of this writing.

## EXTENDING THE MODEL

Future research and development efforts should focus on the following areas:

1.	Redesign of pre and post attack dynamics.  The time leading up to, during, and then following a hijack, is a complex flow of actual and potential events and should be examined more detail than was done here.  Agent rules can then be designed against these flows.  The work at the Agent Technology Center (Bosansky et al. 2011) is an excellent point to start this and also incorporates game theory which should increase the realism of the rules.  The pirate behaviors are recommended as the first agent for which rules need to be redesigned.

2.	North/South  shipping lanes need to be incorporated into the model.  Other navigation controls (approaches, mooring areas, restricted areas, etc.) should be added to increase the realism of the spatial aspects of the simulation.

3.	Effects of weather and daylight conditions.  These factors can have large effects on visibility of pirates and cargo vessels (though not as much on patrol vessels),  often determining whether an attack is detected by the cargo ship.   Weather and sea state also has large effects on the ability of smaller pirate vessels to detect, approach and then attack a ship.   These factors can easily be incorporated in a cell-based model such as the one used here, and then used to determine the behaviors of the agents.

4.	Quantify cargo ship losses in economic terms.   The commercial maritime community looks at the impact of piracy not only in terms of numbers of affected crews and ships, but also by the monetary impact on the loss of ships and cargo.  This model should be extended to compute piracy impacts in financial and cargo-tonnage terms.  This will increase the complexity of the model since several varieties of cargo vessels will be needed, each with different value and performance characteristics (speed, visibility,  etc.)
    Even more complex will be the variety of potential cargos for the various cargo vessels.   This will be important in quantifying the impacts of piracy, but also in determining pirate behaviors in the model (pirates do target certain vessels based upon their economic value).


## NETLOGO FEATURES

No special features or code (e.g., Python, JAVA interfaces, etc.)  were used in this model.  The original code was developed in NetLogo version 4.1.1 running under the Windows-7 operating system.

## RELATED MODELS

The Agent Technology Center at the Czech Technical University (Prague, Czech Republic) has some of the most recent and extensive agent-based models of piracy.  Their website may be accessed via the following URL:


http://agents.felk.cvut.cz/projects/

The other research center which has considerable ABM efforts for the maritime domain is the Lappeenranta University of Technology, Lapeenranta, Finland.  Much of their work is in the area of logistic planning, port facilities planning,  and commercial maring traffic throughput using agent-based techniques.  They have several websites, with the following URL being a good starting point for more information:

http://www.stoca-simulation.fi/fi/stocaproject/agentbasedsimulation

## CREDITS AND REFERENCES

The below references were used in the preparation of this model, and in the final report which accompanies the model.   These references provide excellent background on modern-day piracy, with a bias towards information needed for designing an ABM.  Several of the citations provide links to research centers where additional literature on the topic may be obtained.

....................

Branislav Bosansky, Viliam Lisy, Michal Jakob and Michal Pechoucek: Computing Time-Dependent Policies for Patrolling Games with Mobile Targets. In Proceedings of Tenth International Conference on Autonomous Agents and Multiagent Systems (to appear). 2011

Bradsher, Keith.  2003.  Attacks on Chemical Ships Seem to be Piracy, Not Terror.  New York Times, 27 Mar 2003. P11

Decraene, J., M. Anderson, and M. Y.H Low. 2010. Maritime counter-piracy study using agent-based simulations. In Proceedings of the 2010 Spring Simulation Multiconference, 165.

Henesey, L., Davidsson, P. and Persson, J. A. (2009), �Agent based simulation architecture for evaluating operational policies in transshipping containers�, Autonomous Agents and Multi-Agent Systems, Vol. 18 No. 2, pp. 220-238.

Ho, Joshua H. 2006
    The Security of Sea Lanes in Southeast Asia.   Asian Survey, Vol 46, No 4 (Jul � Aug 2006)  pp. 558-574

Jakob, M., O. Van?k, and M. P?chou?ek. 2011. �Using Agents to Improve International Maritime Transport Security.� IEEE Intelligent Systems: 90�96.

Malaysia Maritime Organization 2009.  Data are from the Malaysia Maritime Organization through 2007.  Ship volume traffic compiled on IWRAP wiki at http://www.ialathree.org/iwrap/index.php?title=Malacca_Strait_Volume_of_Traffic.

Mavrakis, D. and Kontinakis, N. (2008), �A queueing model of maritime traffic in Bosporus Straits�, Simulation Modelling Practice and Theory, Vol. 16 No. 3, pp. 315-328.

Merrick, J., van Dorp, J. R., Blackford, J. P., Shaw, G. L., Harrald, J. and Mazzuchi, T. A. (2003), �A traffic density analysis of proposed ferry service expansion in San Francisco Bay using a maritime simulation model�, Reliability Engineering and System Safety, Vol. 81 No. 2, pp. 119-132.

Raymond, Catherin Zara.  2009.  Piracy and Armed Robbery in the Malacca Strait. US Naval War College Review.  Summer 2009, Vol. 62, No. 3

Rosenberg, David. 2009.  The Political Economy Of Piracy In The South China Sea.  US Naval War College Review, Summer 2009.  Vol 62, No. 3.

Schuman, Michael. 2009.  How to Defeat Pirates:  Success in the Strait.  .  Time online  Magazine, April 22, 2009. www.time.com

Tharoor, Ishaan.  2009.  How Somalia�s Fisherman Became Pirates.  Time online  Magazine, April 18, 2009. www.time.com

Vanek, O. 2010. �Agent-based Simulation of the Maritime Domain.� Acta Polytechnica Vol 50 (4).
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
<experiments>
  <experiment name="Template Experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks = 8640</exitCondition>
    <metric>number_attacks</metric>
    <metric>lost_ships</metric>
    <metric>rescued_ships</metric>
    <metric>total_cargo_ships</metric>
    <metric>successful_ship_transits</metric>
    <enumeratedValueSet variable="number_pirates">
      <value value="5"/>
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
