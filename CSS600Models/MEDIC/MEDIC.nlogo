;
; This model looks at how unique pieces of information
; necessary for the proper diagnosis of a patient (symptoms)
; are communicated between medical providers until
; they reach a single doctor, who upon noticing all
; symptoms together can correctly diagnose
; the patient.
;
; -------------------------------

breed [docs doc]
breed [students student]
breed [nurses nurse]
breed [patients patient]
breed [symptoms symptom] ;; used to store info needed to diagnose each patient.

patients-own [
  time ;; time since entered ED. Included in "go" procedure that this
       ;; should increase each tick. Seems to be set as 0 automatically, but
       ;; had to explicitly tell new patients to set at 0
]

nurses-own [
  assign;;which patients they are assigned to, left-assign or right-assign ;; how many ticks left until their shift changes
  shift-remain ;;counts down
  on-shift ;;how long have been on shift. Counts up. Necessary for the tired-factor.
]

docs-own [
  shift-remain
  on-shift
]

students-own [
  shift-remain
  on-shift
]

patches-own [
left-ED? ;; left side of ED, for one nurse shift
 right-ED?;; right side of ED, for one nurse shift
]

globals [

  diag-time ;; list of times at which patients were diagnosed
  patients-healed ;; total number of patients healed so far
  latest-link ;; iterated upon by every link formed in model, to enable the last learned piece of info to die
]

links-own [
  creation-order]



to setup
  clear-all ;clear any previous data

  ;; color each half of the ED to show different nurse coverage areas, if switch is selected

  ifelse nursesSplitED?
  [
  ask patches [
    set pcolor ifelse-value (pxcor > 0) [7] [6]
    set right-ED? ifelse-value (pxcor > 0) [TRUE] [FALSE]
    set left-ED? ifelse-value (pxcor < 0) [TRUE ] [FALSE]
  ]
  ][ask patches [set pcolor 7]] ;; if switch is off, let it all be the same

  setup-patients

  setup-providers
  set diag-time [] ; turns this global variable into a list
  reset-ticks

end

to setup-patients
  create-patients 8
  [set shape "patient"
    set size 3
    set color 89
  ]
  ask patient 0 [setxy -14 -13]
  ask patient 1 [setxy -14 -4]
  ask patient 2 [setxy -14 5]
  ask patient 3 [setxy -14 14]
  ask patient 4 [setxy 14 -13]
  ask patient 5 [setxy 14 -4]
  ask patient 6 [setxy 14 5]
  ask patient 7 [setxy 14 14]
  ask patients [setup-symptoms]
end

to setup-providers

  ;
  ; create the doctors
  create-docs num-docs
    [ set shape "person doctor"
    set size 3
    set color white
    set shift-remain (doc-shift * 180) ;; decreasing counter, considers each tick as 20 seconds
    setxy random-xcor random-ycor]

  ;; creating half the nurses on each side, and assigning them
  ;; to half the patients
  let nurse-half num-nurses / 2

  create-nurses nurse-half ;creating half the nurses for the left
  [ set shape "person doctor"
    set size 2.0
    set color blue
    set assign "left-assign"
    set shift-remain (nurse-shift * 180) ;; decreasing counter, considers each tick as 20 seconds
    ;; Would have liked to assign these to a random point on the left.
    ;; as a workaround, assigning them all to the same xcor and a random ycor
    setxy -4 random-ycor
  ]

  create-nurses nurse-half ;creating half the nurses for the right
  [ set shape "person doctor"
    set size 2.0
    set color blue
    set assign "right-assign"
    set shift-remain (nurse-shift * 180) ;; decreasing counter, considers each tick as 20 seconds
    setxy 4 random-ycor
  ]

  create-students num-students
  [ set shape "person doctor"
    set size 2.0
    set color 58
    set shift-remain (student-shift * 180) ;; decreasing counter, considers each tick as 20 seconds
    setxy random-xcor random-ycor]

end

; Create the patient symptoms and
; link them to the patient - called at setup, and
; can be called when patient is diagnosed and another takes its place.
to setup-symptoms
  let steps []
  set steps [ -1.5 -.5 .5 1.5 ] ; list with steps taken to spread symptoms out; created before loop so that isn't recreated as a full list each time each symptom moves
  let num-steps 0
  hatch-symptoms 4
  [set shape "warning"
    set size 1
    set color red
    set heading 180 ; move down to be below patient
    fd 2
    set heading 90 ; trying to get symptom icons to spread out horizontally

;; source for choosing number from list:
; https://stackoverflow.com/questions/51174561/how-can-i-sample-from-a-list-without-replacement-when-assigning-variables-to-age
; (couldn't use n-of, even though that pulls with no repeats, since that only works for pulling a few items at the same time with no repeats
    ; Randomly choose an index based on the
    ; length of steps
    let indx one-of range length steps

    ; Have the turtle choose from steps
    ; using that index

    set num-steps item indx steps
    fd num-steps

    ; Remove the indexed value from steps
    set steps remove-item indx steps
 ]

  ;;create links from each patient to their symptoms
  ask patients [set heading 180]
 ask patients [create-links-with symptoms in-cone 4 110]
end

to go
  move-providers
  share-info
  patient-turnover
  ask patients [set time  time + 1]
  shift-timer
  provider-turnover
  forget-oldest-info
  ask docs [output-print tired-factor ] ;; NOTE  - COMMENT THIS LINE OUT BEFORE RUNNING BEHAVIOR SPACE, IT TAKES A LOT OF RESOURCES
  ;ask docs [output-print "on-shift" output-print on-shift]
  ; TASK can have links also decay each tick here, if want to add forgetting
  ; would need to add a weight when they are created
  tick
end

to shift-timer
  ask docs [set shift-remain shift-remain - 1] ;;decreasing shift counter
  ask nurses [set shift-remain shift-remain - 1]
  ask students [set shift-remain shift-remain - 1]
  ask docs [set on-shift on-shift + 1 ]
  ask nurses [set on-shift on-shift + 1 ]
  ask students [set on-shift on-shift + 1 ]
end

to move-providers
  ; TASK a better way would be to have them pick a patient, move to that patient,
  ; and stay there for a few ticks before moving on.
  ask docs [
    set heading random 360
    fd 1]

  ask students [
    set heading  random 360
    fd 1]

  ;; respond to toggle of whether nurses should only
  ;; work with half the patients (left or right side of ED)
  ifelse nursesSplitED?
  [
  ask nurses with [ assign = "left-assign" ] [
    move-to one-of neighbors with [ pcolor = 6 ]
  ]

  ask nurses with [ assign = "right-assign" ] [
    move-to one-of neighbors with [ pcolor = 7 ]
  ]
  ]
  [ask nurses
    [set heading random 360
      fd 1]]

end

to share-info
  ;let all-providers turtles with [(breed = docs) OR (breed = nurses) OR (breed = students)]
  let other-providers turtles with [(breed = nurses) OR (breed = students)]

  ; patients share their symptoms with providers nearby
  ask patients [
    let my-symptoms link-neighbors
    ask other turtles-here with [(breed = nurses) OR (breed = students)]
      [ create-link-with one-of my-symptoms [set color 2.5 order-links]]  ;; learn of just one symptom from patient
    ask other turtles-here with [breed = docs]
      [ create-link-with one-of my-symptoms [set color green order-links]]
  ]

  ; providers share symptoms with each other.
  ; TASK Build this out - make the dyadic pair affect the rate of communication
;  ask all-providers [
;    let my-knowledge link-neighbors
;    ask other turtles-here with [(breed = nurses) OR (breed = students)]
;      [create-links-with up-to-n-of 3 my-knowledge [order-links]]
;    ask other turtles-here with [breed = docs]
;      [create-links-with up-to-n-of 3 my-knowledge [order-links set color green]]
;  ]

  ask docs [
    let my-knowledge link-neighbors
    let num-knowledge count my-knowledge
    ask other turtles-here with [(breed = nurses) OR (breed = students)]
      [create-links-with n-of (num-knowledge * ( (doc-other-comm / 100) * tired-factor)) my-knowledge [order-links]] ;rate of communication, less tired-factor
    ask other turtles-here with [breed = docs]
      [create-links-with n-of (num-knowledge * ((doc-doc-comm / 100) * tired-factor)) my-knowledge [order-links set color green]]
        ]

  ask other-providers [
     let my-knowledge link-neighbors
      let num-knowledge count my-knowledge
    ask other turtles-here with [(breed = nurses) OR (breed = students)]
    [create-links-with n-of (num-knowledge * ((other-other-comm / 100) * tired-factor)) my-knowledge [order-links]] ;rate of communication, less tired-factor
    ask other turtles-here with [breed = docs]
   [create-links-with n-of (num-knowledge * ((other-doc-comm / 100) * tired-factor)) my-knowledge [order-links set color green]]
        ]
end

to patient-turnover
  ask patients [
    let my-symptoms [] ; creating a few variables will need soon
    let patient-die? FALSE
    ;let this-patient-diag-time 0 ; temp variable to hold time when patient was diagnosed
    set my-symptoms sort link-neighbors ;; creating ordered list, for each patient, of their symptoms
      ask docs [
         let md-knowledge []
         set md-knowledge sort link-neighbors  ;; creating ordered list, for each doc, of the symptoms they know about
      if ( patient-status my-symptoms md-knowledge ) = 4 [set patient-die? TRUE] ; calls a reporter procedure that iteratively looks for each item
                                                                                 ; in the list of symptoms in each doc's list of knowledge. If there
                                                                                 ; are 4 matches, set temp variable patient-die to true so we can
                                                                                 ; tell that patient to die as soon as we exit the loop
                                                                                 ; (If we say die now, it's the doc that dies.)


   ;; Debugging output prints - ignore
   ;output-print "patient symptoms:" output-print my-symptoms
   ;output-print "md knowledge:" output-print md-knowledge

  ]
 ; output-print patient-die?
  if patient-die? = TRUE [
      ask link-neighbors [ die ] ;; tell symptoms that are linked to die
      set diag-time fput time diag-time ; add 'time' took to diagnosis to list 'diag-time' keeping track of these values
      set patients-healed patients-healed + 1 ; add self to count of how many patients diagnosed
      hatch-patients 1 [
        set time 0
        setup-symptoms] ;;put new patient in that bed, with patients-own 'time' set to 0, and call procedure to hatch its own symptoms
      die ;; tell patient to die off the model
  ]
  ]
end

to-report patient-status [list1 list2] ;; reporter called earlier to check each patient symptom in each doctor's list, and count ('count-die') whether all 4 symptoms are there
  let count-die 0
  foreach list1 [ [k] ->
    if (member? k list2) [ (set count-die count-die + 1) ]
  ]
report count-die
end

to provider-turnover ;;handoff procedure to new providers, triggered when shift-remain counter reaches 0

  ask docs with [shift-remain < 1 ] [
    let my-knowledge [] ;temp variable to hold knowledge
    set my-knowledge link-neighbors
    let num-knowledge 0
    set num-knowledge count my-knowledge ;  temp variable holding count of symptoms known
    hatch-docs 1  [ ;; new provider in their place
      create-links-with n-of ((doc-handoff-accuracy / 100) * num-knowledge) my-knowledge [order-links set color green];transfer percentage (set by user) of knowledge (held by num-knowledge) to new provider
  set shift-remain (doc-shift * 180)
  set on-shift 0
    ]
    die]

  ask nurses with [shift-remain < 1 ] [
    let my-knowledge [] ;temp variable to hold knowledge
    set my-knowledge link-neighbors
    let num-knowledge 0
    set num-knowledge count my-knowledge ;  temp variable holding count of symptoms known
    hatch-nurses 1  [ ;; new provider in their place
      create-links-with n-of ((nurse-handoff-accuracy / 100) * num-knowledge) my-knowledge [order-links] ;transfer percentage (set by user) of knowledge (held by num-knowledge) to new provider
  set shift-remain (nurse-shift * 180)
  set on-shift 0
    ]
    die]

  ask students with [shift-remain < 1 ] [
    let my-knowledge [] ;temp variable to hold knowledge
    set my-knowledge link-neighbors
    let num-knowledge 0
    set num-knowledge count my-knowledge ;  temp variable holding count of symptoms known
    hatch-students 1  [ ;; new provider in their place
      create-links-with n-of ((student-handoff-accuracy / 100) * num-knowledge) my-knowledge [order-links] ;transfer percentage (set by user) of knowledge (held by num-knowledge) to new provider
  set shift-remain (student-shift * 180)
  set on-shift 0
    ]
    die]

end

to forget-oldest-info
 ask docs [
    while [ (count link-neighbors) > (doc-memory * tired-factor) ] [
      ask my-links with-min [creation-order] [die]
  ]]

  ask nurses [
    while [ (count link-neighbors) > nurse-memory * tired-factor ] [
      ask my-links with-min [creation-order] [die]
  ]]

  ask students [
    while [ (count link-neighbors) > student-memory * tired-factor ] [
      ask my-links with-min [creation-order] [die]
  ]]
end

to order-links
  set creation-order latest-link
  set latest-link  latest-link + 1
end

to-report tired-factor  ;[number] ;; need to feed it on-shift, get-tired-at, and tired-decrease-rate
;- edit, no I don't, it's seeing the same values whether I feed them it or whether I leave it to find those values itself
  let onset 0
  let forget-rate 1
  set onset (get-tired-at * 180) ; set temp variable to hold at how many ticks the user-set onset of the effects of being tired should start
  if ( on-shift > onset) [set forget-rate ( 1 - ( (on-shift / 180 - get-tired-at) * tired-decrease-rate / 100) )
; set the decrease rate as the time on shift expressed in hours, minus when they started getted tired, so we have how long they've been tired at; multiplied
; by the rate they forget things per hour, expressed as a percentage
  ]
 ; output-print "onset" output-print onset
  ;output-print "on-shift" output-print on-shift
    report forget-rate
end

to-report mean-diag-time ;might be required for BehaviorSpace, not sure
  let temp 0
  set temp ( ( mean diag-time ) /  180)
  report temp
end
@#$#@#$#@
GRAPHICS-WINDOW
371
36
808
474
-1
-1
13.0
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
1
1
1
ticks
30.0

BUTTON
25
49
91
82
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

SLIDER
0
145
172
178
num-docs
num-docs
1
5
7.0
1
1
NIL
HORIZONTAL

SLIDER
0
178
172
211
num-nurses
num-nurses
2
8
7.0
2
1
NIL
HORIZONTAL

SLIDER
0
209
172
242
num-students
num-students
0
6
7.0
1
1
NIL
HORIZONTAL

TEXTBOX
37
368
345
489
Docs wear white\nNurses wear blue\nMed students wear green\n\nPatients are the ones with thermometers\n\nSymptoms learned firsthand from patients are colored darker than those learned secondhand from other providers.\n\nSymptoms known by doctors are colored green.
9
0.0
1

BUTTON
115
68
178
101
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

BUTTON
106
34
188
67
Go once
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

SWITCH
12
108
160
141
nursesSplitED?
nursesSplitED?
1
1
-1000

MONITOR
47
263
252
308
Avg. Diagnosis Time (in hours)
( mean diag-time ) /  180
2
1
11

MONITOR
73
313
215
358
# patients diagnosed
patients-healed
17
1
11

SLIDER
175
145
347
178
doc-shift
doc-shift
4
48
12.0
1
1
hours
HORIZONTAL

SLIDER
176
179
348
212
nurse-shift
nurse-shift
0
48
12.0
1
1
hours
HORIZONTAL

SLIDER
174
211
350
244
student-shift
student-shift
0
48
12.0
1
1
hours
HORIZONTAL

SLIDER
815
67
1042
100
doc-handoff-accuracy
doc-handoff-accuracy
1
100
90.0
1
1
%
HORIZONTAL

SLIDER
815
103
1044
136
nurse-handoff-accuracy
nurse-handoff-accuracy
0
100
55.0
1
1
%
HORIZONTAL

SLIDER
815
139
1045
172
student-handoff-accuracy
student-handoff-accuracy
0
100
98.0
1
1
%
HORIZONTAL

SLIDER
1042
66
1236
99
doc-memory
doc-memory
0
100
34.0
1
1
symptoms
HORIZONTAL

SLIDER
1043
101
1237
134
nurse-memory
nurse-memory
0
100
30.0
1
1
symptoms
HORIZONTAL

SLIDER
1044
137
1239
170
student-memory
student-memory
0
100
22.0
1
1
symtoms
HORIZONTAL

TEXTBOX
892
181
1161
225
Doctor handoff accuracy and memory should be presumed to be greater than that of other providers.
9
0.0
1

SLIDER
929
209
1101
242
Get-tired-at
Get-tired-at
6
14
6.0
1
1
hours
HORIZONTAL

SLIDER
894
243
1142
276
Tired-decrease-rate
Tired-decrease-rate
0
30
7.0
.5
1
% per hour
HORIZONTAL

TEXTBOX
841
284
1223
334
Don't set the tired-decrease-rate such that providers would be on shift for so long that the rate reaches over 100%; that would make no logical sense. The command center streams the output factor; if it falls below 0 or above 1, settings do not make logical sense. 
8
0.0
1

SLIDER
922
325
1094
358
doc-doc-comm
doc-doc-comm
0
100
65.0
1
1
%
HORIZONTAL

SLIDER
923
361
1096
394
doc-other-comm
doc-other-comm
0
100
70.0
1
1
%
HORIZONTAL

SLIDER
927
395
1100
428
other-doc-comm
other-doc-comm
0
100
80.0
1
1
%
HORIZONTAL

SLIDER
920
432
1104
465
other-other-comm
other-other-comm
0
100
60.0
1
1
%
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This simulation models a hospital environment, where medical providers learn about patient symptoms from a patient and share that information with each other. The outcome is time to patient diagnosis: patients are diagnosed when a doctor learns of all their symptoms. 

## HOW IT WORKS

Agents move about randomly throughout the environment, with the single exception of nurses who can be told to only move within the half of the environment they are assigned to. When medical providers (doctors, nurses, and medical students) encounter a patient, that patient chooses a random one of their 4 symptoms and shares that information. When providers meet each other, they share a percentage of the symptoms they know of. The percentage they share is determined by the rate of communication between that dyadic pair of agents, as set by the user, subtracted by a factor that reflects how tired they are.

Symptoms are modeled as triangles at the foot of a patient's bed, which the patient is linked to. When providers learn of those symptoms, they form a visual link to the symptom. Green links visually aid the user to see when a doctor, who has the ability to diagnose the patient, knows of their symptoms. 

When patients are diagnosed, they are moved out of the hospital and another patient, with a new set of symptoms, takes over their bed. All providers promptly forget about all the moved patient's symptoms.

A clock keeps track of each provider's shift, and has someone take them over when their shift ends - at a time set by the user. A second clock tracks how long they have been on shift, and when they reach a threshhold of time set by the user, they begin to feel the effects of exhaustion (on communication and memory, but not on handoff accuracy) which is added to each hour, at a rate set by the user.

Other influences in the model include:

- Memory of the agents, whereby the user sets limits on their memory (which are further reduced by the same factor of exhaustion that affected communication rates), such that old information is forgotten when an agent reaches their limit of memory. 

- Accuracy of the handoff from one shift to the next, where new providers taking over from other providers who have gone off shift and transfer a proportion of their knowledge to the provider taking over.

## HOW TO USE IT

Begin by chooseing a number of providers, whether nurses should divide the ED into two sections, and shift changes for the providers. When their shifts are over, other providers take over from them. How well should that handoff go? Adjust the efficiency of communication across that handoff with the accuracy sliders. Towards the end of their shifts providers might grow tired, which will hurt their communication and memory abilities. Adjust the onset and rate of exhaustion with sliders, but be sure that providers don't have negative memory (such as if they are on shift for 24 hours, grow tired at 8 hours, and grow tired at a rate of 10% each hour). Streaming output in the command center records the rate of their exhaustion, and should remain between the values of 0 and 1. You may also play with how many pieces of information each provider can remember, and the effectiveness of communication between each possible meeting of providers: doc->doc, doc->nurse/student, nurse/student-> doc, and nurse/student->nurse/student. 

## THINGS TO NOTICE

What seems to have the strongest effect on patient outcomes? Is there anything that can match raw numbers of patient providers? 


## EXTENDING THE MODEL

Memory is currently primitive, with old information being defined as the oldest thing an agent has learned, rather than the oldest thing they have reviewed, either by hearing it again from someone else or by sharing it with someone else. It also has no allowance for recognition of some information as being important, either to remember it better or to communicate it at a better rate. These limitations are important, as the current implementation seems to have no significant effect of memory. 

Exhaustion currently affects memory and communication, but not the accuracy of handoffs. Conceptually handoffs should be affected as well, particuarly as this model seeks to allow for exploring the balance of longer shifts versus more handoffs. 

## NETLOGO FEATURES

As a model of information exchange, where multiple pieces of information needed to be kept and where it would be visually helpful to have knowledge visible in the model, information here is modeled as a turtle breed, and relation to that knowledge is modeled as a link. Patients are linked to symptoms which live at the foot of their beds, and as providers learn of that information they are linked visually to it (slightly darker shades of grey link providers to patient information they have learned directly from patients, and green links are reserved for doctors who can diagnose the patient).
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

patient
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105
Circle -16777216 false false 145 61 10
Circle -16777216 true false 131 27 10
Circle -16777216 true false 157 27 10
Line -2674135 false 154 66 212 65
Circle -2674135 true false 211 61 8

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
15
Polygon -7500403 true false 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -13345367 true false 135 90 150 105 135 135 150 150 165 135 150 105 165 90
Polygon -7500403 true false 105 90 60 195 90 210 135 105
Polygon -7500403 true false 195 90 240 195 210 210 165 105
Circle -7500403 true false 110 5 80
Rectangle -7500403 true false 127 79 172 94
Polygon -1 true true 105 90 60 195 90 210 114 156 120 195 90 270 210 270 180 195 186 155 210 210 240 195 195 90 165 90 150 150 135 90
Line -16777216 false 150 148 150 270
Line -16777216 false 196 90 151 149
Line -16777216 false 104 90 149 149
Circle -1 true true 180 0 30
Line -16777216 false 180 15 120 15
Line -16777216 false 150 195 165 195
Line -16777216 false 150 240 165 240
Line -16777216 false 150 150 165 150

person student
false
0
Polygon -13791810 true false 135 90 150 105 135 165 150 180 165 165 150 105 165 90
Polygon -7500403 true true 195 90 240 195 210 210 165 105
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 100 210 130 225 145 165 85 135 63 189
Polygon -13791810 true false 90 210 120 225 135 165 67 130 53 189
Polygon -1 true false 120 224 131 225 124 210
Line -16777216 false 139 168 126 225
Line -16777216 false 140 167 76 136
Polygon -7500403 true true 105 90 60 195 90 210 135 105

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

warning
false
0
Polygon -7500403 true true 0 240 15 270 285 270 300 240 165 15 135 15
Polygon -16777216 true false 180 75 120 75 135 180 165 180
Circle -16777216 true false 129 204 42

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
  <experiment name="Validation" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>patients-healed &gt; 1000</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="32"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="28"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="shifts vs. tired" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30240"/>
    <exitCondition>patients-healed &gt; 1000</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="3"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="shifts vs. tired 2" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30240"/>
    <exitCondition>patients-healed &gt; 1000</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="3"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="74"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="20"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment long" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30240"/>
    <exitCondition>patients-healed &gt; 400</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="50"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
      <value value="27"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="50"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="2"/>
      <value value="5"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="16"/>
      <value value="19"/>
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="16"/>
      <value value="19"/>
      <value value="22"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_suspected_factors" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30240"/>
    <exitCondition>patients-healed &gt; 400</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="5"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="50"/>
      <value value="85"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="50"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="40"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="5"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="50"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="40"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="5"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="16"/>
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="16"/>
      <value value="21"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_accuracy" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="40"/>
      <value value="65"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="40"/>
      <value value="55"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="40"/>
      <value value="55"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="21"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_numbers" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="21"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_splitED" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="24"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="21"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="15"/>
      <value value="25"/>
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_memory" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="15"/>
      <value value="25"/>
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="15"/>
      <value value="25"/>
      <value value="35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_shifts" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="8"/>
      <value value="12"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="8"/>
      <value value="12"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="8"/>
      <value value="12"/>
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="22"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_exhaustion" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="2"/>
      <value value="5"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="22"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="explore_communication" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60480"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="30"/>
      <value value="50"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="50"/>
      <value value="70"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="22"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Full_model" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="30240"/>
    <exitCondition>patients-healed &gt; 500</exitCondition>
    <metric>mean-diag-time</metric>
    <metric>patients-healed</metric>
    <enumeratedValueSet variable="num-docs">
      <value value="4"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-handoff-accuracy">
      <value value="60"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-doc-comm">
      <value value="50"/>
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-handoff-accuracy">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nursesSplitED?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Get-tired-at">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-students">
      <value value="4"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-shift">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-shift">
      <value value="8"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-memory">
      <value value="34"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-other-comm">
      <value value="50"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-handoff-accuracy">
      <value value="55"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tired-decrease-rate">
      <value value="3"/>
      <value value="5"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="other-other-comm">
      <value value="40"/>
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nurses">
      <value value="4"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="doc-doc-comm">
      <value value="65"/>
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="student-memory">
      <value value="22"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nurse-memory">
      <value value="20"/>
      <value value="30"/>
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
