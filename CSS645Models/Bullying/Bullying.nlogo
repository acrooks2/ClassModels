breed [children child]
breed [teachers teacher]
directed-link-breed [relationships relationship]  ;; The ongoing relationship between two children
directed-link-breed [PlayGroups PlayGroup]  ;; The temporary relationships formed between children playing together
directed-link-breed [arrests arrest]  ;; The link created by a teacher when taking a student to detention

turtles-own [vision hearing]

children-own [
  gender          ;; 1 for male and 2 for female
  victim          ;; Is the child a victim of a bully? (Boolean)
  bully           ;; Is the child a bully? (Boolean)  Note: can also be a victim
  aggression      ;; Level of aggression toward different people -- likelihood to bully
  tolerance       ;; Level of tolerance toward others -- threshold for bullying
  introversion    ;; Willingness to play alone
  play-status     ;; Whether the child is playing "alone", in a "group", able to go "either" way, or in "detention"
  status-end      ;; The tick when the child's play-status is eligible to change to another voluntary status (i.e. not detention), based on the Play-Status-Duration slider
  attributes      ;; A list of 1 or more attributes used to determine similarity (homophily)
  group-id        ;; The ID of the group the child is currently part of
  is-bullying     ;; Is the child currently bullying? (Boolean)
  bully-target    ;; The child this student has targeted to bully or is currently bullying
  playmates            ;; agentset of nearby turtles
]

teachers-own [
  awareness       ;; Likelihood of a teacher noticing a bullying incident from a distance
  teacher-status  ;; The current status of a teacher:
                      ;; patrolling (looking for bullies)
                      ;; pursuing (moving toward as specific bully)
                      ;; detaining (taking a bully to detention)
  target-bully    ;; The student they are currently believe is a bully and who they're pursuing
  corner-x        ;; The x coordinate of the corner the teacher is taking a bully to
  corner-y        ;; The y coordinate of the corner the teacher is taking a bully to
]


PlayGroups-own [
  start-tick      ;; The tick when the originating child decided to start playing with the other child
]

relationships-own [
  times-played-together  ;; The number of times the originating child played with the other child
  times-bullied          ;; The number of times the originating child bullied the other child
  times-bullied-by       ;; The number of times the originating child was bullied by the other child
  similarity-adjustment  ;; The adjustment to the perceived similarity between the originating child and the other child
  total-play-time        ;; The total amount of time (ticks) that the child played with the other
]

globals [
  ;; Globals created through Interface controls
    ;; Number-of-Students       ;; The number of students to create
    ;; Number-of-Teachers       ;; The number of teachers to create
    ;; Number-of-Attributes     ;; The number of individual attributes for each student, used to compare similarity to others
    ;; Attribute-Maximums       ;; The maximum value of each attribute.  A 1 indicates that the value should be decimal (i.e. ranging from 0.0 to 1.0)
    ;; Percent-Female-Students  ;; The percentage of the students who are female
    ;; Vision-Range             ;; How far students and teachers can see (in a cone)
    ;; Hearing-Range            ;; How far students and teachers can hear (360 degree circle)
    ;; Play-Status-Duration     ;; How long a student remains in the alone or group play states
    ;; Play-Status-Transition   ;; Minimum amount of time a student remains in the either play state (this should be long enough for them to move away from a group and find a new one)
    ;; Detention-Length         ;; The number of ticks a bully is in detention for once in a corner
    ;; Other-Gender-Bullying    ;; The relative likelihood of one gender bullying someone from the other gender -- 1 means they're equally likely to bully either gender, and 0.5 means they're half as likely to bully someone of the other gender
    ;; Tolerance-Adjustment     ;; An adjustment factor to divide each child's tolerance when comparing their similarity, since tolerance is generated from 0 to 1, and the similarity values between two children average out around 0.33, with few going over 0.5.  If this isn't done, very little grouping happens
    ;; Power-Differential       ;; The maximum aggression level of a victim expressed as a percentage of the bully's aggression
    ;; Show-Vision              ;; Whether or not to show cones indicating where the teacher is looking
    ;; Show-Networks            ;; Whether or not to show the links between people


  attribute-count     ;; Capture a snapshot of the Number-of-Attributes so it doesn't get changed by the user mid-run
  attribute-max-list  ;; Capture a snapshot of the Attribute-Maximums so it doesn't get changed by the user mid-run
  group-id-counter    ;; An incremental counter of group IDs
  vision-angle        ;; Angle that a person can see in a cone (out to vision range)
  peripheral-angle    ;; Angle of direct and peripheral vision
  ground-color        ;; The color of the ground patches

]

to setup
  ca
  set attribute-count Number-of-Attributes
  set attribute-max-list read-from-string Attribute-Maximums
  set group-id-counter 0
  set vision-angle 120
  set peripheral-angle 190
  set ground-color 67.5

  ask patches [ set pcolor ground-color ]

  setup-turtles
  reset-ticks
end

to setup-turtles
  set-default-shape children "person"
  set-default-shape teachers "person student"
  create-children Number-of-Students [
    setxy random-xcor random-ycor
    set gender 1
    set color blue
    set vision Vision-Range
    set hearing Hearing-Range
    set victim false
    set bully false
    set aggression random-float 1.0
    set tolerance random-float 1.0
    ;; Have the introversion mean be around 22 since Griffin et al found that
    ;;   children played alone about 20-25% of the time
    set introversion (get-int-random-normal 22 18.2689492137 1 100) / 100.0
    set play-status "either"
    set status-end 0
    set attributes get-individual-attributes
    set group-id -1
    set is-bullying false
    set bully-target self
    set size 2
  ]
  ;; Make a percentage of students female
  ask n-of ((Percent-Female-Students / 100) * Number-of-Students) children [
    set color pink
    set gender 2
  ]

  create-teachers Number-of-Teachers [
    setxy random-xcor random-ycor
    set vision Vision-Range
    set hearing Hearing-Range
    set awareness random-float 1.0
    set size 3
    set color orange
    set teacher-status "patrolling"
  ]

end

to go
  ;; No need to keep going if everyone's a bully
  if Number-of-Students = count children with [bully = true] [ stop ]

  ;; Have children move
  ask children [
    ;; First, figure out if the child is playing alone, in a group, or in-between
    update-play-status
    ;; Second, see if any bullying is going to happen
    check-bullying
    ;; Third, move the child based on their status and bullying behavior
    move-child
  ]

  ;; Move the teachers around
  ask teachers [
    move-teacher
  ]

  ;; At the end of a tick, hide the links so the model runs faster
  ifelse Show-Networks
    [ ask links [ show-link ] ]
    [ ask links [ hide-link ] ]

  check-colors

  tick
end

to move-teacher
  ;; If patrolling, look for any bullying going on
  if teacher-status = "patrolling" [

    ;; First, look for bullying going on
    if show-vision [
      ask patches in-cone vision peripheral-angle [ set pcolor grey ]  ;; Show peripheral vision
      ask patches in-cone (vision / 2) vision-angle [ set pcolor white ]  ;; Show primary vision
    ]

    let bully-found false

    ;; Check to see if there's any bullying going on within the teacher's vision or hearing ranges,
    ;;   with a 100% chance to notice things close by (half of hearing or vision distance) and a
    ;;   chance based on their personal awareness level of noticing things out to the range of their
    ;;   vision or hearing
    ifelse any? (children in-cone (vision / 2) vision-angle)  with [ is-bullying = true ] [
      ;; Sees bullying going on within the teacher's immediate vision
      ;; Select one of the bullies to stop
      set target-bully one-of (children in-cone (vision / 2) vision-angle)  with [ is-bullying = true ]
      set bully-found true
      ] [ ifelse any? (children in-radius (hearing / 2)) with [ is-bullying = true ] [
          ;; Hears bullying going on
          set target-bully one-of (children in-radius (hearing / 2)) with [ is-bullying = true ]
          set bully-found true
      ] [ ifelse (awareness >= random-float 1.0) and any? (children in-cone vision peripheral-angle)  with [ is-bullying = true ] [
            ;;Sees bullying going on futher out or in peripheral vision
            set target-bully one-of (children in-cone vision peripheral-angle)  with [ is-bullying = true ]
            set bully-found true
         ] [ if (awareness >= random-float 1.0) and any? (children in-radius hearing) with [ is-bullying = true ] [
               ;; Hears bullying going on further out (to the limit of hearing range)
               set target-bully one-of (children in-radius hearing) with [ is-bullying = true ]
               set bully-found true ]
           ]
        ]

      ]

    if show-vision [  ;; Return the patches to their original color
      ask patches in-cone vision peripheral-angle [ set pcolor ground-color ]
    ]

    ifelse bully-found [
      set teacher-status "pursuing"
      face target-bully
    ] [  ;; No bully found
      ;; If no bullying found, wander randomly
      rt random 360
    ]

  ]

  if teacher-status = "pursuing" [  ;; Pursuing a bully from a noticed bullying incident
    ;; Make sure the teacher is still facing toward the bully in case the bully has moved
    face target-bully

    if distance target-bully <= 2.0 [
      ;; If within 2 patches, stop and detain the bully, and disband the bully's group
      ;;   (to prevent immediate rebullying of the victims by the remaining members)

      ;; Remove the bully from his or her group
      let temp-bully-group -1
      ask target-bully [
        if bully-target != -1 [
          ask bully-target [
            reset-child-color
          ]]
        set bully-target self  ;; Stop bullying the target and set the target to self as a neutral value
        set is-bullying false
        reset-child-color
        set temp-bully-group group-id
        set play-status "detention"  ;; the status-end time will get set once the bully gets to the corner
        un-group self
      ]
      ;; Disband the bully's group
      ask children with [ group-id = temp-bully-group ] [
        un-group self
        set play-status "either"
      ]

      ;; For detention, move the bully to the nearest corner
      ;; Tie the bully to the teacher, for simplicity, because that way the bully should
      ;;   automatically follow the teacher to the corner
      create-arrest-to target-bully [ tie ]

      ;; Find nearest corner and face in that direction
      set corner-x max-pxcor
      set corner-y max-pycor
      let closest-corner distancexy corner-x corner-y
      if (distancexy max-pxcor min-pycor) < closest-corner [
        set corner-y min-pycor
        set closest-corner distancexy corner-x corner-y ]
      if (distancexy min-pxcor min-pycor) < closest-corner [
        set corner-x min-pxcor
        set corner-y min-pycor
        set closest-corner distancexy corner-x corner-y ]
      if (distancexy min-pxcor max-pycor) < closest-corner [
        set corner-x min-pxcor
        set corner-y max-pycor ]

      facexy corner-x corner-y

      set teacher-status "detaining"
    ]
  ]

  if teacher-status = "detaining" [  ;; detaining -- taking a bully to a corner
    ;; Continue heading in the current direction, which shouldn't change once the bully is caught
    ;; Check to see if next to the corner, and if so, untie the bully and change back to patrolling status
    facexy corner-x corner-y

    if distancexy corner-x corner-y <= 2.0 [  ;; At the corner or close enough
      facexy 0 0  ;; Turn around and face the center, which should move the bully into the corner

      ask out-arrest-to target-bully [
        untie
      ]

      ask target-bully [
        set status-end ticks + Detention-Length
        set color black
        set play-status "detention"
      ]

      ;; Reset the corner-x and -y values
      set corner-x 0
      set corner-y 0

      set teacher-status "patrolling"
    ]
  ]

  ;; Finally, move
  fd 1

end

to move-child
  ;; If child is in a group, determine whether the child is the leader or a follower
  if play-status = "group"  [
    ;; A group of children follows the child with the highest aggression
    let temp-gid group-id
    let group-aggro max [aggression] of children with [ group-id = temp-gid ]
    ifelse group-aggro = aggression [ ;; Then the child is the group leader
      ifelse bully-target = -1 [  ;; Not bullying at the moment
        wiggle
        fd 1 ]
      [ ;; Bullying, move toward the target
        ;; When a bullying target is seen, the group will head toward the target.
        ;; Only groups bully, even if only one kid is actually doing the bullying.
        face bully-target
        ifelse distance bully-target <= 2.0 [ ;; The target is in range to bully
          set is-bullying true
          set bully true
          set color red
          ask bully-target [
            set color white
            set victim true
          ]
        ][ ;; The target is too far way, head towards it
          fd 1
        ]
      ]
    ] [ ;; Not the group leader, head toward or play near the group leader
      let temp-leader one-of children with [ (group-id = temp-gid) and (aggression = group-aggro) ]
      face temp-leader
      ifelse distance temp-leader <= 2.0 [ ;; Move around randomly
        wiggle
        fd 1 ]
      [ ;; Head toward the leader
        face temp-leader
        fd 1 ]
      ]
  ]

  ;; If child is alone, move around randomly or possibly stay put or move away from others
  if play-status = "alone" [
    wiggle
    fd 1
  ]

  ;; If child is in either state, move around randomly
  if play-status = "either"  [
    wiggle
    fd 1
  ]

  ;; If in detention, make sure the bully is in a corner
  if play-status = "detention"  [
    ifelse ((max-pxcor - abs xcor) <= 2.0) and ((max-pycor - abs ycor) <= 2.0) [
      ;; Close enough to a corner, stay there
    ][
      ;; Find nearest corner and face in that direction
      let x max-pxcor
      let y max-pycor
      let closest-corner distancexy x y
      if (distancexy max-pxcor min-pycor) < closest-corner [
        set y min-pycor
        set closest-corner distancexy x y ]
      if (distancexy min-pxcor min-pycor) < closest-corner [
        set x min-pxcor
        set y min-pycor
        set closest-corner distancexy x y ]
      if (distancexy min-pxcor max-pycor) < closest-corner [
        set x min-pxcor
        set y max-pycor ]

      facexy x y
      fd 1
    ]
  ]

end

;; Check each child's play-status and revert them to "either" if past the status-end Tick
to update-play-status

  ;; If child is in a group, determine whether the child wants to play alone
  if play-status = "group" and status-end <= ticks [
    if introversion >= random-float 1.0 [
      ;; If the child wants to play alone, have them break ties with the group and head
      ;; away for some amount of time.  After that, they may look for others to play with.
      un-group self
      set play-status "alone"
      set status-end ticks + Play-Status-Transition
    ]
  ]

  ;; If child is alone, determine whether the child wants to play with others
  if play-status = "alone" and status-end <= ticks [
    if introversion < random-float 1.0 [
      set play-status "either"
      ;; Stay in the either state at least this long, unless a grouping offer comes along
      set status-end ticks + Play-Status-Transition

    ]
  ]

  ;; Check to see if a student is done with detention
  if play-status = "detention" and status-end <= ticks [
    set play-status "either"
    set status-end ticks + 0
  ]

  ;; Otherwise, look for the person within vision range who has the highest similarity,
  ;; as long as the similarity is within the person's tolerance, and move toward that
  ;; person.  If there's nobody within that range, move randomly until someone is found.
  if play-status = "either" and status-end <= ticks [
    ifelse introversion < random-float 1.0 [  ;; Look for other kids to play with
      set playmates other children in-cone vision vision-angle with [ play-status = "group" or play-status = "either" ]
      set playmates playmates with [(compare-students self myself) < tolerance / Tolerance-Adjustment] ;; Dividing tolerance by 4 here to make matches happen
      ;; Identify best candidate to play with
      let target min-one-of playmates [(compare-students self myself)]
      if is-agent? target
      [ face target
        set play-status "group"
        set status-end ticks + Play-Status-Duration
        group-with-other self target
        ] ]
    [ ;; Otherwise, play alone -- not sure about this - is the desire to play alone stronger than the opportunity to play in a group?
      set play-status "alone"
      set status-end ticks + 0  ;Play-Status-Duration
      ;; un-grouping with others should happen when a person leaves a group (only state transition option is alone), so no need to un-group here
    ]

  ]

end

;; A group of children follows the child with the highest aggression, and if this
;; child is the most aggressive in a group, look for a child to bully
to check-bullying

  ;; Check to see if this child is the most aggressive in the group (i.e., the leader)
  if group-id != -1 and bully-target = self [  ;; If in a group and not already targeting someone for bullying,
    ;; Check to see if most aggressive
    let temp-gid group-id
    let group-aggro max [aggression] of children with [ group-id = temp-gid ]
    if group-aggro = aggression [ ;; Then see if there's anyone to bully
      ;print word "Leader = "  who
      ;; Find children within sight
      let potential-targets other children in-cone vision vision-angle
      ;; Filter out any children in a group or in detention
      set potential-targets potential-targets with [play-status = "alone" or play-status = "either"]
      ;; Filter down students who are too close in power (aggression) to be bullied since bullying only happens in a power disparity
      set potential-targets potential-targets with [aggression < (group-aggro * Power-Differential) ]
      ;; Filter down to only those who are dissimilar enough
      set potential-targets potential-targets with [(compare-students-with-gender self myself) > (tolerance / Tolerance-Adjustment)]
      ;; Identify the least similar child to bully
      let target max-one-of potential-targets [(compare-students-with-gender self myself)]
      if is-agent? target
      [ set bully-target target
        face bully-target
        set color yellow  ;; Yellow indicates the agent is looking to bully someone specific
        ]
      ]
  ]

end

;; Form a connection with another child, and join or create a group, as appropriate
to group-with-other [student1 student2]
  ;; Make sure both students have the same group-id
  let temp-group -1
  ask student2 [ set temp-group group-id ]
  ifelse temp-group = -1  ;; Neither student is in a group, so set them to the next group-id-counter
  [ set group-id-counter group-id-counter + 1
    ask student1 [ set group-id group-id-counter ]
    ask student2 [ ;; Give the other student a group id, change status to group, set end, etc.
      set group-id group-id-counter
      set play-status "group"
      set status-end ticks + Play-Status-Duration
      create-PlayGroup-to student1
      ask PlayGroup ([who] of student2) ([who] of student1) [ set start-tick ticks ]
    ] ]
  [ ask student1 [ set group-id temp-group ] ]  ;; The other student is in a group, adopt their group-id

  ;; Build a directed link between the students for the play group
  ask student1 [ create-PlayGroup-to student2 ]
  ask PlayGroup ([who] of student1) ([who] of student2) [ set start-tick ticks ]

  ;; Create or update the relationship link between the students
  ask student1 [
    ifelse out-relationship-neighbor? student2
    [ ask relationship ([who] of student1) ([who] of student2) [
      set times-played-together times-played-together + 1
      ;; set similarity-adjustment similarity-adjustment + 0  ;; For possible use if I figure out a good way to do this
      ]
      ask relationship ([who] of student2) ([who] of student1) [
      set times-played-together times-played-together + 1
      ;; set similarity-adjustment similarity-adjustment + 0  ;; For possible use if I figure out a good way to do this
      ]
    ]
    [ ask student1 [ create-relationship-to student2 ]
      ask relationship ([who] of student1) ([who] of student2) [
        set times-played-together 1
        set similarity-adjustment 0  ;; Unused at the moment
        ]
      ask student2 [ create-relationship-to student1 ]
      ask relationship ([who] of student2) ([who] of student1) [
        set times-played-together 1
        set similarity-adjustment 0  ;; Unused at the moment
        ]
    ]
  ]

end

to un-group [student1]
  ;; let play-time 0  ;; If time, start tracking this
  let temp-group -1
  ask student1 [
    ;; Break from the group
    set temp-group group-id
    set group-id -1
    ask my-out-PlayGroups [ die ]  ;; Do I need to do anything else here? **************************************
    ask my-in-PlayGroups [ die ]
    ;; Anything for relationships?  **************************************
  ]

  ;; Check to see if there is only one other person in the group, and if so ungroup them as well
  let other-group other children with [ group-id = temp-group ]
  if count other-group = 1 [   ;; Only ungroup the other if there's only one person left in the group
    ask other-group [ un-group self ]
  ]

end

;; Check the colors for each of the children to make sure they're showing up correctly
  ;; Blue for males who are not in any other state
  ;; Pink for females who are not in any other state
  ;; Yellow for bullies heading toward a target to bully
  ;; Red for bullies in the act of bullying
  ;; Black for bullies in detention
  ;; White for children being bullied
to check-colors
  ask children [
   let reset-color false
   if color = black and play-status != "detention" [ set reset-color true ]
   if color = white [
     if (count other children with [ bully-target = myself]) = 0 [ set reset-color true ]
   ]

   if reset-color [ reset-child-color ]
  ]

end

;; Reset the child's color to match its gender
to reset-child-color
  ifelse gender = 1
    [ set color blue ]
    [ set color pink ]
end

to-report compare-students [student1 student2]
  let att1 []
  let att2 []
  let agg1 1.0
  let agg2 1.0
  ask student1 [
    set att1 attributes
    set agg1 aggression ]
  ask student2 [
    set att2 attributes
    set agg2 aggression ]

  ; Compare based on the attribute list
  let similarity compare-attributes att1 att2 attribute-max-list

  ; Add in a comparison for aggression, giving aggression the same relative weight as the rest of the attributes
  set similarity ((similarity * attribute-count) + (get-difference agg1 agg2 1.0)) / (attribute-count + 1)

  report similarity
end

; Compare the similarity of two students, including gender -- this value is used for selecting
;   another student to bully, as opposed to the basic comparison, which is gender neutral.
; A Other-Gender-Bullying value less than 1 means that the someone is less likely to bully a child
;   with the opposite gender.  Greater than one means they're more likely to bully another gender.
to-report compare-students-with-gender [student1 student2]
  let similarity compare-students student1 student2

  let gender1 1
  let gender2 1
  ask student1 [ set gender1 gender ]
  ask student2 [ set gender2 gender ]

  ; Compare on gender
  if gender1 != gender2 [
    set similarity similarity * Other-Gender-Bullying
  ]

  report similarity
end

;; Compare two lists of numbers and return the numerical difference,
;; potentially in comparison to a list of maximum values for the list items
to-report compare-attributes [att1 att2 max-vals]
  let comparison 0
  (foreach att1 att2 max-vals
    [ [?1 ?2 ?3] -> set comparison comparison + (get-difference ?1 ?2 ?3) ])
  report comparison / length att1
end

;; Return the percent difference between any two values given the maximum possible value
to-report get-difference [a b max-val]
  report abs ((a - b) / max-val)
end


to-report get-individual-attributes
  ;;set attribute-max-list read-from-string Attribute-Maximums  ;; SHOULDN'T BE NEEDED after setup
  let attribute-list []
  foreach attribute-max-list
  [ ?1 ->
    ifelse ?1 = 1
    [
      ;; Generate a random decimal number between 0 and 1
      set attribute-list lput (random-float 1.0) attribute-list
    ]
    [
      ;; Generate a random integer between 1 and the max value
      set attribute-list lput (get-int-random-range 1 ?1) attribute-list
    ]
  ]
  report attribute-list
end

to-report count-non-victims
  report count children with [bully = false and victim = false]
end

to-report count-bullying-incidents
  let bullying-count 0
  ask relationships [
    set bullying-count bullying-count + times-bullied
  ]
  report bullying-count
end

to-report get-group-list
  let group-list []
  ask children [
    if (group-id != -1) and not (member? group-id group-list) [
      set group-list lput group-id group-list
    ]
  ]
  report group-list
end

to-report get-average-group-size
  let group-list get-group-list
  ifelse length group-list = 0 [
    report 0 ]
  [ let total-in-groups 0
    foreach group-list [ ?1 ->
      set total-in-groups total-in-groups + (count children with [group-id = ?1]) ]
    report total-in-groups / ((length group-list) * 1.0)
  ]
end

to-report get-total-group-size
  let group-list get-group-list
  ifelse length group-list = 0 [
    report 0 ]
  [ let total-in-groups 0
    foreach group-list [ ?1 ->
      set total-in-groups total-in-groups + (count children with [group-id = ?1]) ]
    report total-in-groups
  ]
end

;;;;;;;;;; General Utility Functions (not specific to this model) ;;;;;;;;;;;;;;;;;;;

to-report get-int-random-normal [ norm-mean std-dev range-min range-max ]
  let x round random-normal norm-mean std-dev
  if x < range-min [ set x range-min ]
  if x > range-max [ set x range-max ]
  report x
end

to-report get-int-random-normal-100   ;; a normally distributed value from 1 to 100
  report get-int-random-normal 50 18.2689492137 1 100 ;; a normal distribution from 1 to 100
end

to-report get-int-random-range [ range-min range-max ]
  report round (random (range-max - range-min) + range-min)
end



;;;;;;;  Ants (Persepective Demo) Code  ;;;;;;;;;;;;;;;;;;;;;;;
; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.

to wiggle  ;; turtle procedure
  rt random 40
  lt random 40
  if not can-move? 1 [ rt 180 ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
626
427
-1
-1
8.0
1
10
1
1
1
0
0
0
1
-25
25
-25
25
0
0
1
Seconds
30.0

SLIDER
15
100
187
133
Number-of-Students
Number-of-Students
2
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
15
140
187
173
Number-of-Teachers
Number-of-Teachers
0
20
2.0
1
1
NIL
HORIZONTAL

SLIDER
15
180
187
213
Number-of-Attributes
Number-of-Attributes
1
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
15
290
188
323
Percent-Female-Students
Percent-Female-Students
0
100
75.0
1
1
%
HORIZONTAL

SLIDER
15
330
187
363
Vision-Range
Vision-Range
1
100
20.0
1
1
Patches
HORIZONTAL

SLIDER
15
370
187
403
Hearing-Range
Hearing-Range
1
100
10.0
1
1
Patches
HORIZONTAL

INPUTBOX
15
220
188
280
Attribute-Maximums
[100 7 100 1 20]
1
0
String

BUTTON
20
15
84
48
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
100
15
163
48
Go
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
640
319
943
469
Group Characteristics
NIL
NIL
0.0
1.0
0.0
10.0
true
true
"" ""
PENS
"# of Groups" 1.0 0 -7500403 true "" "plot length get-group-list"
"Avg Group Size" 1.0 0 -6459832 true "" "plot get-average-group-size"

PLOT
639
164
941
314
Victims and Bullies
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
"Non-Victims" 1.0 0 -16777216 true "" "plot count children with [victim = false and bully = false]"
"Bullies" 1.0 0 -2674135 true "" "plot count children with [bully = true and victim = false]"
"Victims" 1.0 0 -13345367 true "" "plot count children with [victim = true and bully = false]"
"Bully/Victims" 1.0 0 -8630108 true "" "plot count children with [victim = true and bully = true]"
"Targeting" 1.0 0 -7500403 true "" "plot count children with [color = \"yellow\"]"

SLIDER
435
480
635
513
Play-Status-Duration
Play-Status-Duration
1
600
60.0
1
1
Seconds
HORIZONTAL

SLIDER
435
520
635
553
Play-Status-Transition
Play-Status-Transition
0
100
25.0
1
1
Seconds
HORIZONTAL

SLIDER
225
480
400
513
Other-Gender-Bullying
Other-Gender-Bullying
0
2
1.0
0.05
1
NIL
HORIZONTAL

PLOT
639
10
940
160
Play Status Counts
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
"Alone" 1.0 0 -13840069 true "" "plot count children with [play-status = \"alone\"]"
"In a Group" 1.0 0 -13345367 true "" "plot count children with [play-status = \"group\"]"
"Either" 1.0 0 -2674135 true "" "plot count children with [play-status = \"either\"]"
"Detention" 1.0 0 -16777216 true "" "plot count children with [play-status = \"detention\"]"

SWITCH
30
480
175
513
Show-Vision
Show-Vision
0
1
-1000

SLIDER
435
560
635
593
Detention-Length
Detention-Length
-1
1000
120.0
1
1
Seconds
HORIZONTAL

SLIDER
225
520
400
553
Tolerance-Adjustment
Tolerance-Adjustment
0.1
10
0.5
0.1
1
NIL
HORIZONTAL

TEXTBOX
20
60
186
95
Setup Only Parameters (not changeable once Going)
12
0.0
1

TEXTBOX
440
455
590
473
Play Status Durations
12
0.0
1

TEXTBOX
230
455
380
473
Behavioral Modifiers
12
0.0
1

TEXTBOX
35
455
185
473
Display Options
12
0.0
1

SWITCH
30
520
175
553
Show-Networks
Show-Networks
1
1
-1000

SLIDER
225
560
400
593
Power-Differential
Power-Differential
0
1
0.5
.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model is designed to explore the dynamics of:
•	Bullying, on the basis of perceived differences and power imbalances
•	Friendship social network formation based on homophily and repeated interactions
•	Teacher presence as a preventative against bullying and disruptive effect on the act of bullying
•	The spatial interactions of students with each other on a playground and the limited ranges of hearing and vision on the ability of teachers to “police” the space and prevent bullying


## HOW IT WORKS

Setup creates the initial set of students and teachers based on the parameter values selected in the Setup Only Parameters section of the interface.  Go causes teh model to run.

## HOW TO USE IT

Here are explanations of the Globals created through Interface controls:

Number-of-Students: 	The number of students to create

Number-of-Teachers: 	The number of teachers to create

Number-of-Attributes: 	The number of individual attributes for each student, used to compare similarity to others

Attribute-Maximums: 	The maximum value of each attribute.  A 1 indicates that the value should be decimal (i.e. ranging from 0.0 to 1.0)

Percent-Female-Students: 	The percentage of the students who are female

Vision-Range: 	How far students and teachers can see (in a cone)

Hearing-Range: 	How far students and teachers can hear (360 degree circle)

Play-Status-Duration: 	How long a student remains in the alone or group play states

Play-Status-Transition: 	Minimum amount of time a student remains in the either play state (this should be long enough for them to move away from a group and find a new one)

Detention-Length: 	The number of ticks a bully is in detention for once in a corner

Other-Gender-Bullying: 	The relative likelihood of one gender bullying someone from the other gender -- 1 means they're equally likely to bully either gender, and 0.5 means they're half as likely to bully someone of the other gender

Tolerance-Adjustment: 	An adjustment factor to divide each child's tolerance when comparing their similarity, since tolerance is generated from 0 to 1, and the similarity values between two children average out around 0.33, with few going over 0.5.  If this isn't done, very little grouping happens 

Power-Differential: 	The maximum aggression level of a victim expressed as a percentage of the bully's aggression

Show-Vision: 	Whether or not to show cones indicating where the teacher is looking

Show-Networks: 	Whether or not to show the links between people


## THINGS TO NOTICE

An excessive number of bullies and bully-victims are created -- any thoughts on how to fix this?

## THINGS TO TRY

The slider that has the most effect on the model is the Tolerance-Adjustment.  Why does it have the effect that it does?  What happens besides the reduction in the number of bullies when you increase this value?

## EXTENDING THE MODEL

•	Making the playground environment contain structures and equipment, which act both as gathering points for children, and obstructions that can limit visibility, and possibly, hearing.

•	Making the social networks among children more impactful.  This can include having children be more likely to play with children they have played with before, or inversely, over time be less likely to play with children they haven’t played with before.  

•	Have behavioral actions change over time – bullies can be encouraged or discouraged by success or failure, students can get more withdrawn if they’re bullied, making them better targets for future bullying, and teachers can focus on particular trouble-makers, based on their past experiences with them, while missing others they’re not paying attention to.  

•	Have bystanders react to bullying in their immediate area Salmivalli et al. (1996) and Sutton & Smith (1999) talk about additional six roles beyond the bully: reinforcer, assistant, defender, outsider, and victim.  These could be incorporated into the model, or more simply, have nearby children check to see if they feel closer to the bully or the victim, and in the case of the latter, if within a threshold, defend the victim.

•	Build functionality to add new students to the model while it is running and allow for other students and bullies to be removed.  This would allow for the exploration of how changing the mix of students could affect the prevalence of bullying.


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
    <timeLimit steps="10000"/>
    <metric>count children with [play-status = "alone"]</metric>
    <metric>count children with [play-status = "group"]</metric>
    <metric>count children with [play-status = "either"]</metric>
    <metric>count children with [play-status = "detention"]</metric>
    <metric>count children with [victim = false and bully = false]</metric>
    <metric>count children with [victim = false and bully = true]</metric>
    <metric>count children with [victim = true and bully = false]</metric>
    <metric>count children with [victim = true and bully = true]</metric>
    <metric>count children with [color = "yellow"]</metric>
    <metric>get-group-list</metric>
    <metric>length get-group-list</metric>
    <metric>get-average-group-size</metric>
    <enumeratedValueSet variable="Show-Networks">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Teachers">
      <value value="2"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Attributes">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Play-Status-Duration">
      <value value="60"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Play-Status-Transition">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Show-Vision">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Female-Students">
      <value value="50"/>
      <value value="75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Vision-Range">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Power-Differential">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tolerance-Adjustment">
      <value value="0.5"/>
      <value value="1"/>
      <value value="2"/>
      <value value="4"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hearing-Range">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Students">
      <value value="25"/>
      <value value="50"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Attribute-Maximums">
      <value value="&quot;[100 7 100 1 20]&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Other-Gender-Bullying">
      <value value="0.5"/>
      <value value="0.75"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Detention-Length">
      <value value="120"/>
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
1
@#$#@#$#@
