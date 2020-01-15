;;code from the virus model and HIV model was borrowed/adapted for this project
patches-own [ patch-length ]
turtles-own
  [ sick?                ;; if true, the turtle is infectious ;;virus
    sick-time            ;; time in weeks turtle is infectious ;;virus
    antivax?             ;; if true, the turtle is anti-vaccination
    provax?              ;; if true, the turtle is pro-vaccination
    hesitant?            ;; if true, the turtle only vaccinated one time
    immune?              ;; if true the turtle cannot be infected
    infected?            ;; if true turtle is infected with measles
    infection-length     ;; length of infection ;;virus
    initiate-infection   ;; this creates the sick based on slider
    anti-vax-medical-exemption  ;; antivax agent who is medically exempt.  controlled by slider
    anti-vax-personal-exemption ;; antivax agent who is exempt for personal reasons.  controlled by slider
    anti-vax-religious          ;;antivax agent who is religiously exempt.  controlled by slider
    non-compliance       ;; antivax agent who did not comply with vaccination requirements
 ]

globals
  [ %infected            ;; what % of the population is infectious ;;virus
    %immune              ;; what % of the population is immune ;;virus
    %anti                ;; what % of the population is antivax
    %pro                 ;; what % of the population is provax
    %hesitant            ;; what % of the population is vaccine hesitant
    %sickanti            ;; what % of population is sick and antivax
    %sickpro             ;; what % of population is sick and pro
    %sickhesitant        ;; what % of population is sick and hesitant
    #anti-infected       ;; # of infected antivax
    #pro-infected        ;; # of infected provax
    #hesitant-infected   ;; # of infected hesitant
  carrying-capacity    ;; carrying capacity ;;virus model
]
breed [ antivaxs antivax ]
breed [ provaxs provax ]
breed [ hesitants hesitant ]


to setup
  clear-all

;; setting up the kindergarten classroom
ask patches[
    set pcolor black]

  ask patches [
    if pycor = 2 and pxcor = -8 [set pcolor green]
    if pycor = 4 and pxcor = -8 [set pcolor green]
    if pycor = 6 and pxcor = -8 [set pcolor green]
    if pycor = 8 and pxcor = -8 [set pcolor green]
    if pycor = 2 and pxcor = -6 [set pcolor green]
    if pycor = 4 and pxcor = -6 [set pcolor green]
    if pycor = 6 and pxcor = -6 [set pcolor green]
    if pycor = 8 and pxcor = -6 [set pcolor green]
    if pycor = 2 and pxcor = -4 [set pcolor green]
  if pycor = 4 and pxcor = -4 [set pcolor green]
  if pycor = 6 and pxcor = -4 [set pcolor green]
  if pycor = 8 and pxcor = -4 [set pcolor green]
  if pycor = 2 and pxcor = -2 [set pcolor green]
  if pycor = 4 and pxcor = -2 [set pcolor green]
  if pycor = 6 and pxcor = -2 [set pcolor green]
  if pycor = 8 and pxcor = -2 [set pcolor green]
  if pycor = 2 and pxcor = 0 [set pcolor green]
  if pycor = 4 and pxcor = 0 [set pcolor green]
  if pycor = 6 and pxcor = 0 [set pcolor green]
  if pycor = 8 and pxcor = 0 [set pcolor green]
  if pycor = -4 and pxcor = -5 [set pcolor green]
    if pycor = -3 and pxcor = -5 [set pcolor green]
    if pycor = -2 and pxcor = -5 [set pcolor green]
  if pycor = 5 and pxcor = 4 [set pcolor green]
  if pycor = 5 and pxcor = 3 [set pcolor green]
  if pycor = -1 and pxcor = 5 [set pcolor green]
  if pycor = 1 and pxcor = 5 [set pcolor green]
  if pycor = 0 and pxcor = 5 [set pcolor green]]
  ask patches with [count neighbors != 8]
  [ set pcolor green ]

; create the antivax, and then initialize variable
  create-antivaxs (average-anti-vax-medical-exemption + average-anti-vax-personal-exemption + average-anti-vax-religious + average-non-compliance)
  [ask n-of 1 patches with [pcolor = black]
   [sprout 0 ;creates the children of the antivax population
   [set color blue
    set shape  "face neutral"
        set size 1]]
  ;; make population based on exemption sliders
    ask antivaxs [
    assign-anti-vax-medical-exemption
    assign-anti-vax-personal-exemption ;;new
    assign-anti-vax-religious ;;new
    assign-non-compliance
    set immune? false
    set antivax? true
;; creates the initially sick population
    set infected? (who < initiate-infected)
    if infected?
            [set color pink
             set infection-length infection-length + 25]]]

; create the provax, and then initialize variable
create-provaxs random-near initial-number-provax [
ask n-of 1 patches with [pcolor = black] [sprout 0 ; creates the children of the provax population
  [set shape "face neutral"
   set color yellow
   set size 1 ]];

 ask provaxs [
    set infected? false
    set sick? false
    set provax? true
    set immune? true
      initiate-immunity]] ;; for future model to allow for unvaccinated provaxxers

; create the hesitants, and then initialize variable
  create-hesitants random-near initial-number-hesitant [
   ask n-of 1 patches with [pcolor = black] [sprout 0  ; creates the children of the vaccine hesitant
  [
    set shape "face neutral"
    set color grey
        set size 1]

   ask hesitants [

    set sick? false
    set infected? false
    set immune? true
    set hesitant? true
    initiate-hesitant-immunity  ;; for future model to allow for unvaccinated hesitants

  ]]]

  reset-ticks
end
;population sick at the start
to assign-initiate-infection
  set initiate-infection random-near initiate-infected

end
;; for future model to allow for unvaccinated hesitants
to initiate-hesitant-immunity
  ask n-of  .5 hesitants [set immune? false]
end
;; for future model to allow for unvaccinated provaxxers
to initiate-immunity
  ask n-of  .5 provaxs [set immune? false]

end

;;code to assign turtles a value random-near average-[tendency] slider value

;     ;;assign medical exemptions
     to assign-anti-vax-medical-exemption
       set anti-vax-medical-exemption random-near average-anti-vax-medical-exemption
     end
;
;     ;;assign personal exemptions
     to assign-anti-vax-personal-exemption
       set anti-vax-personal-exemption random-near average-anti-vax-personal-exemption
     end
;
;     ; assign religious exemption
     to assign-anti-vax-religious ;;new code, inspired by HIV model
       set anti-vax-religious random-near anti-vax-religious
     end
;
;     ;;assign non-compliance
     to  assign-non-compliance ;;new code, inspired by HIV model
       set  non-compliance random-near  non-compliance
     end

     ;;procedure for random-near, so tendencies are assigned a random value near slider values
     to-report random-near [center]  ;; borrowed from HIV model
       let result 0
       repeat 40
         [ set result (result + random-float center) ]
       report result / 20
     end

     to get-sick ;; turtle procedure ;;virus model
       set sick? true ;;virus
       set immune? false
       set color red
     end

     to get-immune ;; turtle procedure ;;adapted from virus model
       set sick? false ;;virus model
       set sick-time 0 ;;virus model
       set immune? true
end

to get-infected ;; turtle procedure ;;virus model
       set infected? true ;;virus
       set color pink  ;;virus
       set immune? false
     end
to setup-constants ;;virus
    set carrying-capacity 300 ;;virus
end

to go

 ask turtles [
    move-to one-of patches with [pcolor != green]] ;; this keeps turtles from walking on green
 ask antivaxs [
     ;;adapted from virus ;;
    if infected? and infection-length > 25  [infect] ; this limits infection capabilities to those indiviudals who were sick at the start
    if infected? [set infection-length infection-length + 1] ;;adapted from HIV model ;;infection-length is increased by 1 each tick
    if infected? and infection-length > 25 [set pcolor orange] ; this creates an infectious orange square that will remain for an amount of time established by a slider
    if not infected? and pcolor = orange and not immune? [get-infected] ; infected by orange patch not agent to agent contact

  update-global-variables
  update-display

   ]
  tick
  if ticks >=  24 [stop] ;;simulates an 8 hour day


ask provaxs [

     ;; code is same as the antivax agent
    if infected? and infection-length > 25  [infect]
    if infected? [set infection-length infection-length + 1]
    if infected? and infection-length > 25 [set pcolor orange]
    if not infected? and pcolor = orange and not immune? [get-infected]

  update-global-variables
  update-display

   ]

 ask hesitants [;; code is same as the antivax agent
    if infected? and infection-length > 25  [infect]
    if infected? [set infection-length infection-length + 1] ;;adapted from HIV model ;;infection-length is increased by 1 each tick
    if infected? and infection-length > 25 [set pcolor orange] ;skipped ahead 4 days for immediate contagion for measles
    if not infected? and pcolor = orange and not immune? [get-infected]

  update-global-variables
  update-display
   ]
  ; this sets the length of time the patches are infectious
  ask patches
    [ if pcolor = orange [set patch-length patch-length + 1]
      if patch-length > 2
      [set pcolor black
       ]
  ]
end

to update-global-variables ;;virus model
  if count turtles > 0
      [set %immune ((count provaxs with [immune?] + count antivaxs with [immune?] + count hesitants with [immune?])/(count provaxs + count antivaxs + count hesitants)* 100)
      set %infected ((count provaxs with [infected?] + count antivaxs with [infected?] + count hesitants with [infected?])/(count provaxs + count antivaxs + count hesitants)* 100 )
      set %anti (count antivaxs / (count provaxs + count antivaxs + count hesitants))* 100
      set %sickanti (count antivaxs with [infected?]/ count antivaxs) * 100  ;;gives count for both sick and antivax
      set %pro ((count provaxs) / (count provaxs + count antivaxs + count hesitants)) * 100 ;;new, adapted from virus
      set %sickpro (count provaxs with [sick?] / count provaxs) * 100
      set %hesitant ((count hesitants) / (count provaxs + count antivaxs + count hesitants))* 100
      set #anti-infected (count antivaxs with [infected?]) ;
       set #pro-infected (count provaxs with [infected?])
        set #hesitant-infected ((count hesitants with [infected?]))
  ]

end

to update-display
  ask antivaxs
    [ if shape != turtle-shape [ set shape turtle-shape ] ;;adapted from virus model
      set shape ifelse-value infected? [ "face sad" ] [ ifelse-value immune? [ "face happy" ] [ "face neutral" ] ] ;;adapted from virus model ;;if sick, sad face, if immune happy face, if netiher, neutral face
      set color ifelse-value infected? [pink] [ifelse-value antivax?  [blue] [grey]]
      if infected? and infection-length > 25 [set color red]] ;;adapted from virus model

  ask provaxs
    [ if shape != turtle-shape [ set shape turtle-shape ] ;;adapted from virus model
      set shape ifelse-value infected? [ "face sad" ] [ ifelse-value immune? [ "face happy" ] [ "face neutral" ] ] ;;adapted from virus model ;;if sick, sad face, if immune happy face, if netiher, neutral face
      set color ifelse-value infected? [pink] [ifelse-value provax?  [yellow] [grey]]] ;;adapted from virus model


      ask hesitants
    [ if shape != turtle-shape [ set shape turtle-shape ] ;;adapted from virus model
      set shape ifelse-value infected? [ "face sad" ] [ ifelse-value immune? [ "face happy" ] [ "face neutral" ] ] ;;adapted from virus model ;;if sick, sad face, if immune happy face, if netiher, neutral face
      set color ifelse-value infected? [pink] [ifelse-value hesitant?  [grey] [grey]]] ;;adapted from virus model

end

to infect ;; turtle procedure adapted from virus model
  ask other turtles-here with [ not infected? and not immune? ] ;;adapted from virus model
    [ if random-float 50 < infectiousness ;;if randomly chosen number 0-100 is less than infectiousness value from slider, then get other turtles-here sick
      [ get-infected ] ]
end

to startup ;;virus model
  setup-constants ;; so that carrying-capacity can be used as upper bound of number-people slider
end
@#$#@#$#@
GRAPHICS-WINDOW
259
22
615
379
-1
-1
26.81
1
10
1
1
1
0
0
0
1
-6
6
-6
6
1
1
1
hours
30.0

SLIDER
14
345
186
378
infectiousness
infectiousness
0
100
90.0
1
1
%
HORIZONTAL

BUTTON
50
32
113
65
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
120
33
183
66
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
628
224
915
399
Anti Vax Disease Report
weeks
people
0.0
30.0
0.0
50.0
true
true
"" ""
PENS
"Sick" 1.0 0 -5298144 true "" "plot count antivaxs with [infected?]"
"Susceptible" 1.0 0 -7500403 true "" "plot count antivaxs with [not infected? and not immune?]"

SLIDER
15
188
244
221
average-anti-vax-medical-exemption
average-anti-vax-medical-exemption
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
15
227
247
260
average-anti-vax-personal-exemption
average-anti-vax-personal-exemption
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
15
266
247
299
average-anti-vax-religious
average-anti-vax-religious
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
628
174
699
219
NIL
%infected
1
1
11

MONITOR
704
175
771
220
NIL
%immune
1
1
11

MONITOR
628
24
700
69
%anti-vax
%anti
1
1
11

MONITOR
710
24
780
69
%pro-vax
%pro
1
1
11

SLIDER
13
517
185
550
chance-recover
chance-recover
0
5
0.0
.1
1
NIL
HORIZONTAL

MONITOR
793
26
864
71
NIL
%hesitant
1
1
11

SLIDER
19
77
237
110
initial-number-provax
initial-number-provax
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
17
117
240
150
initial-number-hesitant
initial-number-hesitant
0
100
4.0
1
1
NIL
HORIZONTAL

MONITOR
704
74
768
119
NIL
%sickpro
17
1
11

SLIDER
13
385
185
418
chance-infection
chance-infection
0
100
90.0
1
1
NIL
HORIZONTAL

MONITOR
630
73
696
118
NIL
%sickanti
1
1
11

SLIDER
16
306
188
339
initiate-infected
initiate-infected
1
20
1.0
1
1
NIL
HORIZONTAL

PLOT
628
404
915
574
Pro Vax Disease Report
Days
People
0.0
30.0
0.0
10.0
true
true
"" ""
PENS
"Sick" 1.0 0 -2674135 true "" "plot count provaxs with [infected?]"
"Immune" 1.0 0 -10899396 true "" "plot count provaxs with [immune?]"
"Susceptible" 1.0 0 -7500403 true "" "plot count provaxs with [not immune? and not infected?] "

PLOT
339
394
616
574
Hesitant Disease Report
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
"Sick" 1.0 0 -2674135 true "" "plot count hesitants with [sick?]"
"Immune" 1.0 0 -10899396 true "" "plot count hesitants with [immune?]"
"Susceptible" 1.0 0 -7500403 true "" "plot count hesitants with [not immune? and not sick?]"

SLIDER
15
152
242
185
average-non-compliance
average-non-compliance
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
13
430
189
463
contageon-length
contageon-length
0
100
6.0
1
1
NIL
HORIZONTAL

CHOOSER
190
506
328
551
turtle-shape
turtle-shape
"person" "circle" "face happy" "face neutral" "face sad"
2

SLIDER
9
474
181
507
duration
duration
0
99.0
16.0
1
1
NIL
HORIZONTAL

MONITOR
628
124
721
169
NIL
#anti-infected
17
1
11

MONITOR
730
123
820
168
NIL
#pro-infected
17
1
11

MONITOR
824
124
941
169
NIL
#hesitant-infected
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model, SODDA, simulates the spread of disease based on a population of children who have antivax parents, vax hesitant parents or provax parents.  The antivax population is derived from the sum of vaccination exemption sliders.  This model also demonstrates how patches can spread disease after the infectious agent departs.


By playing with the sliders within this model, the user can see what a diseased population looks like when you have an abundance of antivaccination exemptions or they can try to create herd immunity by increasing the immune populations. 

## HOW IT WORKS

Upon initiation of the model, agents are sprouted based on the population sliders. The sliders are preset for real-world data, but are not restricted to allow for expansion of the model. At start a number of sick agents are introduced based on the initiate sick slider. Agents move at random throughout the model space if they do not hit a green patch. When agents move forward one they may come into contact with provax, hesitant, and antivax agents.  If the agent is sick and is in their contagious period then they will infect other individuals they come into contact who are not immune. If infected, the agent does not become contagious. The only individuals who are contagious throughout the model are those who were sick from initiation. This is due to the measles vaccine not becoming contagious until four days prior to the rash appearing. The rash does not appear until about 7 days after infection (CDC, 2018b). Agents immunity will be based the vaccination beliefs of their parents. If immune, the agent just walks around the model at random.

## HOW TO USE IT


### Parameters

Initial-number-provax	Individuals have complete vaccination record. This slider can be 
                        set from 1-100

Initial-number-hesitant	Individuals who have received some vaccines but do not have a 	
                        complete records. This slider can be set from 1-100

Average-Non-Compliant	Individuals who have no shots on record. They have been counted  
                        as an Antivax attribute; Can be set from 1-100

Average-Personal-Exemption	Exemption covering personal reasons not to vaccinate;  child				slider can be set from 1-100

Average-Medical-Exemption	Exemption covering medical reasons not to vaccinate child
				slider can be set from 1-100

Average-Religious-Exemption	Exemption covering religious reasons not to vaccinate child				slider can be set from 1-100

Infectious			This is a slider that can be changed depending on the 
				vaccine that is being depicted. Can be set from 1-100

Chance Infected			This is a slider set to determine if interaction occurs 
				how likely is the other agent to get infected.

Length of Contagiousness	This is a slider that can be changed depending on the 
				vaccine that is being depicted and pertains to the model 	                                patches. 

Initiated-Infected	This is the number of individuals who are sick and now contagious 			at the start of the model. This number can be set from 1-100.  


### Monitors

    %infected            ;; what % of the population is infectious ;;virus
    %immune              ;; what % of the population is immune ;;virus
    %anti                ;; what % of the population is antivax
    %pro                 ;; what % of the population is provax
    %hesitant            ;; what % of the population is vaccine hesitant
    %sickanti            ;; what % of population is sick and antivax
    %sickpro             ;; what % of population is sick and pro
    %sickhesitant        ;; what % of population is sick and hesitant
    #anti-infected       ;; # of infected antivax
    #pro-infected        ;; # of infected provax
    #hesitant-infected   ;; # of infected hesitant

### Plots

Antivax disease report: Plots susceptibility, sickness, and immunity

Hesitant disease report: Plots susceptibility, sickness, and immunity

Provax disease report: Plots susceptibility, sickness, and immunity



## THINGS TO NOTICE

Choose values for each of the sliders (described below) and chooser buttons (also described below). Run the simulation and make a note of how the population changes over time, and the ending values in each monitor. 


## THINGS TO TRY

Choose different parameter values, and then see how the results differ between runs. See how changing disease and exemption parameters impact the spread of disease.  There is also code in this model that allows for the provaccination and hesitant populations to have immunity issues. Play with that and see how long it takes you to impact that population.


## EXTENDING THE MODEL

This model can be expanded to explore many things.  The main expansion of the model would be to account for a real-world daily schedule of a kindergartener.  This would allow a more realistic depiction of disease spread.  The model would account for children going home at the end of the day and staying home if diagnosed with the measles. Days would pass allowing for the model to reach a point in which the child recovers from the measles and returns to school.   
	Another expansion of the model would be to create a full elementary school.  This would pass the disease beyond the kindergartners and could show how fast measles would spread through a school with a bigger population than 23. The challenge of this expansion would be getting vaccination data for the entire school.  Generalization may need to be made depending on the grades within the building.
	The final aspect to look at when expanding the model is having unvaccinated children whose parents are hesitant or provax in their beliefs.  The disease outbreak in Washington affected three individuals who had the MMR vaccine (You and your family, 2019).  The expansion of the model would allow individuals to explore how the decisions of antivax parents are impacting the children of the pro-vaccination population. The model would account for items such as age constraints and illness preventing a parent form vaccinating their child.

## RELATED MODELS

HIV and Virus models are related, and were used in creation of this model. Code borrowed or adapted from these models is noted as "HIV" or "virus" in the code tab.


## CREDITS AND REFERENCES

Wilensky, U. (1997). NetLogo HIV model. http://ccl.northwestern.edu/netlogo/models/HIV. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Wilensky, U. (1998). NetLogo Virus model. http://ccl.northwestern.edu/netlogo/models/Virus. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
 
Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.
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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="School 2" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>%sickanti</metric>
    <metric>#anti-infected</metric>
    <metric>%sickpro</metric>
    <metric>#pro-infected</metric>
    <enumeratedValueSet variable="average-non-compliance">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-anti-vax-personal-exemption">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="turtle-shape">
      <value value="&quot;face happy&quot;"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initiate-infected" first="1" step="1" last="9"/>
    <enumeratedValueSet variable="average-anti-vax-religious">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-anti-vax-medical-exemption">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-infection">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-provax">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectiousness">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="chance-recover">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-hesitant">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contageon-length">
      <value value="6"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="School 1" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>#anti-infected</metric>
    <metric>#pro-infected</metric>
    <metric>#hesitant-infected</metric>
    <enumeratedValueSet variable="initial-number-provax">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-hesitant">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-non-compliance">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-anti-vax-religious">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-anti-vax-medical-exemption">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="average-anti-vax-personal-exemption">
      <value value="3"/>
    </enumeratedValueSet>
    <steppedValueSet variable="initiate-infected" first="1" step="1" last="9"/>
    <enumeratedValueSet variable="chance-infection">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="infectiousness">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contageon-length">
      <value value="6"/>
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
