;; Attendees leaving venue can be pickpocketed due to inattentiveness
;; Officers try to protect inattentive attendees by heading in their direction
;; Pickpockets are looking for inattentive attendees to target, but will not attempt a pickpocket if an officer is nearby
;;========================================================================================


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Agents   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; define the three types of agents and also "vision cones" for two of those agents (i.e., officers, pickpockets)

breed [attendees attendee]
breed [officers officer]
breed [pickpockets pickpocket]
breed [officer-vision-cones officer-vision-cone]
breed [pickpocket-vision-cones pickpocket-vision-cone]

attendees-own [random-door heading-ycor gender distracted wealth attendee-speed pickpocketed? police-alerter police-alerter2 groupid group-members group-members2 group-members3 group-distance group-dist startX startY distance-traveled time-traveled flag1]
officers-own [officer-vision candidate-officer-attendees candidate-pickpocket pickpocket-suspect officer-see-pickpocket attendee-officer-target o-counter homeX homeY attendees-needing-assistance attendees-needing-assistance2 get-information]
pickpockets-own [pickpocket-vision candidate-pickpocket-attendees pickpocket-timer pickpocket-flag pickpocketer-speed heading-y officer-in-range p-counter p-timer dist]

globals [b groupid-list count-list summary-group-list groups-w-1 groups-w-2 groups-w-3 groups-w-4 groups-w-5 dist-1 dist-2 dist-3 dist-4 dist-5 time-1 time-2 time-3 time-4 time-5 attendee-pickpocket-target officer-help officer-help-flag see-pickpocket]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Default    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to default
  set numberOfAttendees 100
  set percent-male 59
  set attendee-distracted-speed 0.5
  set attendee-nonDistracted-male-speed 1.0  ;; Polus et al (1983) indicated that 1 to 1.25 pedestrians per square meter yielded a walking speed around 1.0 m/sec
  set attendee-nonDistracted-female-speed 0.9  ;; Polus et al (1983) had observed several sites where females walked about 0.89 times as fast a male
  set numberOfOfficers 10
  set width-of-officer-vision 10
  set officerFollow 10
  set officer-speed 0.5
  set numberOfPickpockets 5
  set width-of-pickpocket-vision 15
  set pickpocketFollow 20
  set pickpocket-speed 1.0
  set config-1 true
  set config-2 false
  set calculateAverageSpeed false
  set new_seed true
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  resize-world -50 50 -16 16
  setup-seed
  setup-doors
  setup-attendee-groupid
  identify-group-size
  setup-attendee-attributes
  setup-officers
  setup-pickpockets
  reset-ticks
end

to setup-seed
  if new_seed = true [ set seed (214783647 - random 2362267296)]  ;; the seed must be in the range of -2147483648 to 2147483647
  random-seed seed
end

to setup-doors
  ask patches [
    if (pycor <= 12) and (pycor >= 8) and (pxcor < -49) [ set pcolor grey ]  ;; door #1 (if random-door value in procedure below = 0)
    if (pycor <= 2) and (pycor >= -2) and (pxcor < -49) [ set pcolor grey ]  ;; door #2 (if random-door value in procedure below = 1)
    if (pycor <= -8) and (pycor >= -12) and (pxcor < -49) [ set pcolor grey ]  ;; door #3 (if random-door value in procedure below = 2)
  ]
end

;; assign attendees to groups of size no more than 5 (due to standard seating configurations in most passenger cars)
;; groups of attendees will exit from same gate

to setup-attendee-groupid
  set b 1  ;; b is the first group number
  let f 100
  while [f > 0]  ;; loop until attendees = numberOfAttendees
  [
    let a 1 + random 5  ;; a is the random number (1 to 5)
    if a > f [ set a f]
    let c random 3  ;; used to assign attendees to door #1, door #2, or door #3
    let d random-ycor  ;; y-coordinate of heading so entire group heads in same direction
    while [a > 0]  ;; a is a counter to determine when the group is complete
    [
      create-attendees 1 [
        set groupid b ;; assign the attendee to group number b
        set a a - 1  ;; redue the counter (a) by one to determine how many more need to be assigned, but once the attendees are close to the slider level, assign the last few agents to their own groups
        set random-door c  ;; as indicated above, the value corresponds to an attendees starting point (i.e., either door #1, door #2, or door #3)
        ifelse random-door = 0 [ setxy -50 8 + random-float 4 ]  ;; attendees exit from door #1
        [ ifelse random-door = 1 [ setxy -50 -2 + random-float 4 ]  ;; attendees exit from door #2
          [ setxy -50 -12 + random-float 4 ]]  ;; attendees exit from door #3
        set heading-ycor d
        facexy 50 heading-ycor  ;; attendees are headed from left to right on the screen towards their vehicles or public transportation
      ]
    ]
    set b b + 1  ;; once the initial number a attendees have been assigned to the group, define a new group
    set f numberOfAttendees - count attendees  ;; loop until attendees = numberOfAttendees
  ]
  set groupid-list sort-by < [groupid] of attendees
end

;; report summary-level statistics for number of groups with 1 attendee, 2 attendees, 3 attendees, 4 attendees, and 5 attendees

to identify-group-size
  set count-list []
  set summary-group-list []
  let i 1
  set b last groupid-list
  while [i <= b]  ;; b is equal to the last groupid assigned in the above procedure
  [
    let i-th-group-size count attendees with [groupid = i]  ;; count number of attendees assigned to each groupid
    set count-list lput i-th-group-size count-list  ;; make list containing counts for each groupid
    set i i + 1
  ]
  let j 1
  let summary-list []
  while [j <= 5]
  [
    let j-th-group-size filter [ ?1 -> ?1 = j ] count-list  ;; pulls out number of groups (and puts into list) with 1 attendee, ... , 5 attendees
    set summary-list length j-th-group-size  ;; counts items in list above for number of attendees from 1, ... , 5
    set summary-group-list lput summary-list summary-group-list  ;; aggregated list counting number of groupid's with 1 attendee, ... , 5 attendees
    set j j + 1
  ]
  let k 1
  let group-raw []
  set groups-w-1 []
  set groups-w-2 []
  set groups-w-3 []
  set groups-w-4 []
  set groups-w-5 []
  while [k <= b]  ;; recall that b is equal to the number of groupid's
  [
    ;; identify groupid's (in a list) that have 1, 2, ... , 5 attendees per groupid
    let k-th-group-size filter [ ?1 -> ?1 = k ] groupid-list
    ifelse length k-th-group-size = 1 [set group-raw first k-th-group-size set groups-w-1 lput group-raw groups-w-1]
    [ifelse length k-th-group-size = 2 [set group-raw first k-th-group-size set groups-w-2 lput group-raw groups-w-2]
    [ifelse length k-th-group-size = 3 [set group-raw first k-th-group-size set groups-w-3 lput group-raw groups-w-3]
    [ifelse length k-th-group-size = 4 [set group-raw first k-th-group-size set groups-w-4 lput group-raw groups-w-4]
    [set group-raw first k-th-group-size set groups-w-5 lput group-raw groups-w-5]]]]
    set k k + 1
  ]
end

to setup-attendee-attributes
  ask attendees [
    set shape "dot"
    set startX pxcor set startY pycor  ;; each attendee is assigned starting position to calculate distance traveled (to calculate average speed traveled)
    ifelse random 100 <= percent-male [ set color green set gender "male" ] [ set color yellow set gender "female" ]  ;; "Fan Demographics Among Major North American Sports Leagues" (June 2010) - 41% females (MLB), 40% females (NFL), 41% (NHL)
    set size 1
    set distracted random-normal 5 2  ;; attendees have varying levels of distractedness (e.g., walking while texting) that is normally distributed with standard deviation of two
    if distracted < 0 [ set distracted 0 ]  ;; even though it's a normal distribution, it doesn't make sense to have a negative value
    set wealth random-normal 5 2  ;; attendees have varying levels of outward appearances of wealth (e.g., designer purse) that is normally distributed with standard deviation of two
    if wealth < 0 [ set wealth 0 ]  ;; even though it's a normal distribution, it doesn't make sense to have a negative value
  ]
end

to setup-officers
  create-officers numberOfOfficers [
    ifelse config-1 = true [ all-in-a-line ] [ all-staggered ]
    set homeX pxcor set homeY pycor  ;; each officer is assigned a post that can be "called" during the simulation for him/her to return
    set color blue
    set shape "dot"
    set size 1
    ifelse random-float 1 < .5 [ set heading 270 + random-float 45 ] [ set heading 270 - random-float 45 ]  ;; officers begin simulation by looking direction of attendees exiting venue with some degree of randomness so as to observe more of the simulated world
    set officer-vision width-of-officer-vision  ;; "vision cone" code is based on Bug Hunt Coevolution model in NetLogo
    let o-vision officer-vision
    hatch 1 [
      set breed officer-vision-cones
      create-link-from myself [ tie ]  ;; movement of officer and officer's "vision cone" are tied together
      set shape "vision cone"  ;; created a new shape in the NetLogo in the Turtle Shapes Editor
      set color blue
      set size 1 * o-vision
    ]
  ]
end

to all-in-a-line
  if numberOfOfficers = 10 [
    let coordinates [ [-30 10] [0 10] [40 10] [-30 0] [-10 0] [15 0] [40 0] [-30 -10] [0 -10] [40 -10] ]
    (foreach (sort officers) coordinates [ [?1 ?2] ->
        ask ?1 [ setxy item 0 ?2 item 1 ?2 ]
    ])
  ]
  if numberOfOfficers = 15 [
    let coordinates [ [-30 10] [-15 10] [0 10] [20 10] [40 10] [-30 0] [-15 0] [0 0] [20 0] [40 0] [-30 -10] [-15 -10] [0 -10] [20 -10] [40 -10] ]
    (foreach (sort officers) coordinates [ [?1 ?2] ->
        ask ?1 [ setxy item 0 ?2 item 1 ?2 ]
    ])
  ]
  if numberOfOfficers = 20 [
    let coordinates [ [-30 10] [-10 10] [0 10] [10 10] [20 10] [40 10] [-30 0] [-20 0] [-10 0] [0 0] [10 0] [20 0] [30 0] [40 0] [-30 -10] [-10 -10] [0 -10] [10 -10] [20 -10] [40 -10] ]
    (foreach (sort officers) coordinates [ [?1 ?2] ->
        ask ?1 [ setxy item 0 ?2 item 1 ?2 ]
    ])
  ]
end

to all-staggered
  if numberOfOfficers = 10 [
    let coordinates [ [-30 7] [-25 -7] [-10 10] [0 -10] [1 4] [15 -8] [18 11] [26 0] [40 8] [45 -10] ]
    (foreach (sort officers) coordinates [ [?1 ?2] ->
        ask ?1 [ setxy item 0 ?2 item 1 ?2 ]
    ])
  ]
  if numberOfOfficers = 15 [
    let coordinates [ [-40 -12] [-35 7] [-25 -10] [-23 13] [-14 -3] [-13 6] [0 -10] [1 4] [8 -2] [18 11] [25 -9] [28 3] [40 8] [45 -10] [46 0] ]
    (foreach (sort officers) coordinates [ [?1 ?2] ->
        ask ?1 [ setxy item 0 ?2 item 1 ?2 ]
    ])
  ]
  if numberOfOfficers = 20 [
    let coordinates [ [-40 -12] [-36 -1] [-35 7] [-26 4] [-25 -7] [-23 12] [-14 -3] [-13 6] [0 -10] [1 4] [8 -2] [15 0] [18 11] [25 -9] [28 3] [33 -6] [40 8] [45 -10] [46 0] [47 13] ]
    (foreach (sort officers) coordinates [ [?1 ?2] ->
        ask ?1 [ setxy item 0 ?2 item 1 ?2 ]
    ])
  ]
end

to setup-pickpockets
  create-pickpockets numberOfPickpockets [
    setxy -40 + random-float 90 random-ycor  ;; would-be pickpockets are positioned randomly in world, but started them at least 10 units away from attendees exiting the venue
                                             ;; unlike officers, don't assign them a starting "heading" so that they don't appear to have (at least to the officers) malintent
    set color red
    set shape "dot"
    set size 1
    set heading-y random-ycor

    set pickpocket-vision width-of-pickpocket-vision  ;; "vision cone" code is based on Bug Hunt Coevolution model in NetLogo
    let p-vision pickpocket-vision
    hatch 1 [
      set breed pickpocket-vision-cones
      create-link-from myself [ tie ]  ;; movement of pickpocket and pickpocket's "vision cone" are tied together
      set shape "vision cone"  ;; created a new shape in the NetLogo in the Turtle Shapes Editor
      set color red
      set size 1 * p-vision
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Go    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to go
  move-attendees
  move-officers
  move-pickpockets
  if calculateAverageSpeed [ calculate-distance-traveled ]
  tick
  if count attendees = 0 or (ticks > 5 and (count attendees with [attendee-speed > 0] = 0)) [stop]  ;; simulation ends if all attendees have exited simulation or if all attendees (except for those who witnessed a pickpocket incident) have exited the simulation
end

;; attendees

to move-attendees
  ask attendees [
    if groupid >= ticks [ stop ]  ;; delay initial departure to give the effect of many people leaving an exit of the venue at various times (idea taken from NetLogo's Ant model)
    set group-members attendees with [groupid = [groupid] of myself]  ;; identify others in same group
    set group-members2 group-members with [police-alerter = true]  ;; identify groups with an attendee who has alerted the police to get the group to head back in that individual's direction
    ifelse count group-members2 > 1 [ set group-members3 n-of 1 group-members2 ] [ set group-members3 group-members2 ]  ;; if two attendees from same group witness pickpocket incident, randomly remove one of them

    if (member? self group-members2) and (not member? self group-members3) [ set flag1 1 ]
    ifelse flag1 = 1 [set police-alerter2 false ] [ set police-alerter2 police-alerter ]  ;; attendee removed from group-members3 (so that there's only one police-alerter per group)
    if police-alerter2 = true [ set attendee-speed 0 forward attendee-speed ]

    set group-distance max-one-of group-members [distance myself]  ;; identify attendee furthest away in same group
    set group-dist distance (group-distance)

    let done? false
    if (police-alerter2 = true) [
      set done? true
      set attendee-speed 0 forward attendee-speed
    ]
    if (done? = false) and (any? group-members3 and attendees != group-distance and gender = "male") [
      set done? true
      set heading towards group-distance
      ifelse (round [xcor] of self) = (round [xcor] of group-distance) [ set attendee-speed 0 forward attendee-speed ] [ set attendee-speed random-normal attendee-nonDistracted-male-speed 0.1 forward attendee-speed ]
    ]
    if (done? = false) and (any? group-members3 and attendees != group-distance and gender = "female") [
      set done? true
      set heading towards group-distance
      ifelse (round [xcor] of self) = (round [xcor] of group-distance) [ set attendee-speed 0 forward attendee-speed ] [ set attendee-speed random-normal attendee-nonDistracted-female-speed 0.1 forward attendee-speed ]
    ]
    if (done? = false) and (group-dist < 5 and (distracted > (5 + (1 * 2)))) [
      set done? true
      set attendee-speed random-normal attendee-distracted-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist < 5 and gender = "male") [
      set done? true
      set attendee-speed random-normal attendee-nonDistracted-male-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist < 5 and gender = "female") [
      set done? true
      set attendee-speed random-normal attendee-nonDistracted-female-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 5 and group-dist < 8 and ((distracted > (5 + (1 * 2)))) and [xcor] of self > [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal (.25 * attendee-distracted-speed) 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 5 and group-dist < 8 and ((distracted > (5 + (1 * 2)))) and [xcor] of self < [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal attendee-distracted-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 5 and group-dist < 8 and gender = "male" and [xcor] of self > [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal (.25 * attendee-nonDistracted-male-speed) 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 5 and group-dist < 8 and gender = "male" and [xcor] of self < [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal attendee-nonDistracted-male-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 5 and group-dist < 8 and gender = "female" and [xcor] of self > [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal (.25 * attendee-nonDistracted-female-speed) 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 5 and group-dist < 8 and gender = "female" and [xcor] of self < [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal attendee-nonDistracted-female-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 8 and [xcor] of self > [xcor] of group-distance) [
      set done? true
      set attendee-speed 0 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 8 and gender = "male" and [xcor] of self < [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal attendee-nonDistracted-male-speed 0.1 forward attendee-speed
    ]
    if (done? = false) and (group-dist >= 8 and gender = "female" and [xcor] of self < [xcor] of group-distance) [
      set done? true
      set attendee-speed random-normal attendee-nonDistracted-female-speed 0.1 forward attendee-speed
    ]

    ;; attendees move with varying speeds and those who are more than one standard deviation
    ;; above mean level of distractedness move more slowly

    if (round xcor = 50) or (xcor > 49 and ycor > 16) or (xcor > 49 and ycor < -16) [ die ]  ;; attendees who have reached the other side of the NetLogo world are removed from the simulation (i.e., world doesn't wrap horizontally or vertically)
  ]
end

to alert-police  ;; procedure is called at bottom of code under "to doPickpocket"
  ask attendees [
    if distracted < (5 - (1 * 2)) and ([xcor] of self < [xcor] of attendee-pickpocket-target) and (distance (attendee-pickpocket-target) < 3) [  ;; flags attendee who witnessed pickpocket incident
                                                                                                                                                 ;; attendee is very alert (i.e., 1 standard deviation to left of mean of distribution)
                                                                                                                                                 ;; must be behind pickpocket incident and within 3 meters
      set police-alerter true
      set color white
    ]
  ]
end

;; officers

to move-officers
  ask officers [
    set candidate-officer-attendees attendees in-cone (width-of-officer-vision / 2) 120 with [(distracted > (5 + (1 * 2)))] ;; since the "vision" shape is wider than long, I divide by 2 so that the officers don't spot
                                                                                                                            ;; attendees outside of that "vision" shape
                                                                                                                            ;; officers more closely monitor those attendees who are distracted for the
                                                                                                                            ;; protection of the attendees since they're not vigilant of their own surroundings
    set candidate-pickpocket pickpockets in-cone (width-of-officer-vision / 2) 120  with [pickpocket-flag = 1]  ;; witness pickpocket incident in "vision cone"
    set attendees-needing-assistance attendees in-radius 15 with [police-alerter = true]  ;; if officer hears cries for help (assumed to be 10 meters due to volume of people and associated noise), then he/she will race towards that cry for help
    set officer-help officers with [xcor > 30]

    let done? false
    if (any? candidate-pickpocket) or (pickpocket-suspect != 0) [
      set done? true
      set officer-see-pickpocket 1
      set see-pickpocket 1  ;; global variable to alert would-be pickpockets to exit simulation since police are on the move and they don't want to risk getting caught
      go-after-suspect-alone
    ]
    if (done? = false) and (any? attendees-needing-assistance) and (get-information <= 30) [
      set done? true
      respond-to-help
    ]
    if (done? = false) and (get-information > 30) [
      set done? true
      go-after-suspect
    ]
    if (done? = false) and (any? officer-help) and (officer-help-flag = true) [
      set done? true
      respond-to-backup
    ]
    if (done? = false) and (any? candidate-officer-attendees) [
      set done? true
      move-to-protectee
    ]
    if (done? = false) and ((round(xcor) != round(homeX)) or (round(ycor) != round(homeY))) [
      set done? true
      return-to-post
    ]
  ]
end

to go-after-suspect-alone
  set color white
  set pickpocket-suspect min-one-of candidate-pickpocket [distance myself]
  ifelse pickpocket-suspect != nobody [ set heading towards pickpocket-suspect ] [ facexy 50 0 ]  ;; officer chases after pickpocket suspect
  forward random-normal (4 * officer-speed) 0.1  ;; officer chases after pickpocket suspect
  if round xcor = 50 [
    hide-turtle  ;; hatched pickpocket remains (just hidden) to preserve the counts/monitors
    ask officer-vision-cones [
      ifelse round xcor >= 49 [ hide-turtle ] [ show-turtle ]]
  ]
end

to respond-to-help
  set attendees-needing-assistance2 min-one-of attendees-needing-assistance [distance myself]
  set color white
  set heading towards attendees-needing-assistance2  ;; officer orients himself towards attendee who cried out for help
  ifelse (round [xcor] of self) = (round [xcor] of attendees-needing-assistance2) [ forward 0 ] [ forward random-normal (1.5 * officer-speed) 0.1 ]  ;; move to attendee who cried out for help
  set get-information get-information + 1 ;; taking down suspect information from attendee for 30 seconds
  if get-information > 30 [ ask officer-help [
    set officer-help-flag true
  ]]
end

to go-after-suspect
  set attendees-needing-assistance 0
  facexy 50 0
  forward random-normal (4 * officer-speed) 0.1  ;; officer chases after pickpocket suspect
  if round xcor = 50 [
    hide-turtle  ;; hatched pickpocket remains (just hidden) to preserve the counts/monitors
    ask officer-vision-cones [
      ifelse round xcor >= 49 [ hide-turtle ] [ show-turtle ]]
  ]
end

to respond-to-backup
  ask officer-help [
    set color white
    facexy 50 0
    forward random-normal (2 * officer-speed) 0.1  ;; officers receive word to pursue pickpocket suspect
    if round xcor = 50 [
      hide-turtle  ;; hatched pickpocket remains (just hidden) to preserve the counts/monitors
      ask officer-vision-cones [
        ifelse round xcor >= 49 [ hide-turtle ] [ show-turtle ]]
    ]
  ]
end

to move-to-protectee
  set attendee-officer-target min-one-of candidate-officer-attendees [distance myself]  ;; reports minimum distance between officer and attendee
  set heading towards attendee-officer-target
  forward random-normal officer-speed 0.1
  set o-counter o-counter + 1  ;; number of ticks that officer follows a distracted individual
  if o-counter > officerFollow [ return-to-post ]  ;; behavior doesn't allow officers to continually follow an attendee (note: the intent is simply to look out for the attendee's own protection)
end

to return-to-post
  set o-counter 0
  facexy homeX homeY
  forward random-normal officer-speed 0.1
end

;; pickpockets

to move-pickpockets
  ask pickpockets [
      set candidate-pickpocket-attendees attendees in-cone (width-of-pickpocket-vision / 2) 120 with [(distracted > 5 + (1 * 2)) or (wealth > (5 + (2 * 2)))]  ;; pickpockets target those who are either distracted
                                                                                                                                                               ;; or exhibit outward wealth
                                                                                                                                                               ;; note: model assumes that the individual will only pickpocket one time
      let done? false
      if ((any? officer-help) and (officer-help-flag = true)) or (see-pickpocket = 1) [
        set done? true
        exit-simulation
      ]
      if (done? = false) and (color != white) and (any? candidate-pickpocket-attendees) [
        set done? true
        move-to-pickpocket
      ]
      if (done? = false) and (color != white) and (not any? candidate-pickpocket-attendees) [
        set done? true
        random-move
      ]
      if (done? = false) and (color = white) [
        set done? true
        pickpocket-exit
      ]
  ]
end

to exit-simulation  ;; pickpocket individuals are assumed to be risk averse in this simulation; thus, if they see police officers moving fast after a suspect, they will exit the simulation regardless of whether they were successful in pickpocketing
  ask pickpockets [
    facexy 50 heading-y
    set pickpocketer-speed random-normal (1 * pickpocket-speed) 0.1 forward pickpocketer-speed
    if round xcor = 50 [
      hide-turtle  ;; hatched pickpocket remains (just hidden) to preserve the counts/monitors
      ask pickpocket-vision-cones [
        ifelse round xcor >= 49 [ hide-turtle ] [ show-turtle ]]
    ]
  ]
end

to move-to-pickpocket
  set attendee-pickpocket-target min-one-of candidate-pickpocket-attendees [distance myself]  ;; reports minimum distance between pickpocket and attendee
  set heading towards attendee-pickpocket-target
  set dist distance (attendee-pickpocket-target)
  set pickpocketer-speed random-normal pickpocket-speed 0.1 forward pickpocketer-speed
  set officer-in-range officers in-cone (width-of-pickpocket-vision / 2) 120  ;; as the pickpockets are following unsuspecting victims, they will not pickpocket if officer is in pickpocket's "vision cone"
  ifelse any? officer-in-range [
    set p-counter p-counter + 1  ;; will not pickpocket if officer is seen in pickpocket's "vision cone"
    if p-counter > pickpocketFollow [  ;; if officer in vision for too long then the pickpocket will abandon activities for a period of time (i.e., abandon activities for 20 ticks)
      set p-timer p-timer + 1
      if p-timer >= 20 [
        set p-timer 0
        set p-counter 0
      ]
    ]
  ]
  [ doPickpocket ]  ;; if officer not in vision for too long then pickpocket will proceed with illicit behavior
end

to doPickpocket
  set p-counter 0
  set p-timer 0
  if dist < .3 [  ;; since 1 unit is equal to 1 meter, it seems reasonable for a pickpocket to occur at a distance .3 meters (approx. 1 foot) apart from attendee
    set color white
    set pickpocket-flag 1
    ask attendee-pickpocket-target [
      set pickpocketed? true  ;; flags attendee who just got pickpocketed
      set color white
    ]
    alert-police  ;; if somebody who is not distracted is within certain distance of pickpocket incident, he/she will alert police
  ]
end

to random-move  ;; if the would-be pickpocket agents don't have an attendee target, they will randomly move through the crowd
  set pickpocketer-speed random-normal (.5 * pickpocket-speed) 0.1 forward pickpocketer-speed
  if xcor < -40 [ set heading 90 + random-float 45 ]
  if xcor > 45 [ set heading 270 + random-float 45 ]
  if ycor > 14 [ set heading 180 + random-float 45 ]
  if ycor < -14 [ set heading 0 + random-float 45 ]
end

to pickpocket-exit
  set pickpocket-timer pickpocket-timer + 1
  if pickpocket-timer > 1 [ set pickpocket-flag 0 ]
  facexy 50 heading-y
  set pickpocketer-speed random-normal (2 * pickpocket-speed) 0.1 forward pickpocketer-speed  ;; those who pickpocketed don't want to risk getting caught so they can only perform, at most, one pickpocket per simulation
  if round xcor = 50 [
    hide-turtle  ;; hatched pickpocket remains (just hidden) to preserve the counts/monitors
    ask pickpocket-vision-cones [
      ifelse round xcor >= 49 [ hide-turtle ] [ show-turtle ]]
  ]
end

;; calculate average speeds by group size

to calculate-distance-traveled
  ask attendees [
    if xcor > -50 [
      set distance-traveled sqrt (((ycor - startY) ^ 2) + ((xcor - startX) ^ 2))  ;; use Pythagorean Theorem to calculate distance traveled for each agent
      set time-traveled time-traveled + 1
      foreach groups-w-1 [ ?1 ->
        set dist-1 sum [distance-traveled] of attendees with [groupid = ?1] ;; sums up distance traveled for groups of specific size
        set time-1 sum [time-traveled] of attendees with [groupid = ?1]  ;; sums up time for groups of specific size
      ]
      foreach groups-w-2 [ ?1 ->
        set dist-2 sum [distance-traveled] of attendees with [groupid = ?1] ;; sums up distance traveled for groups of specific size
        set time-2 sum [time-traveled] of attendees with [groupid = ?1]  ;; sums up time for groups of specific size
      ]
      foreach groups-w-3 [ ?1 ->
        set dist-3 sum [distance-traveled] of attendees with [groupid = ?1] ;; sums up distance traveled for groups of specific size
        set time-3 sum [time-traveled] of attendees with [groupid = ?1]  ;; sums up time for groups of specific size
      ]
      foreach groups-w-4 [ ?1 ->
        set dist-4 sum [distance-traveled] of attendees with [groupid = ?1] ;; sums up distance traveled for groups of specific size
        set time-4 sum [time-traveled] of attendees with [groupid = ?1]  ;; sums up time for groups of specific size
      ]
      foreach groups-w-5 [ ?1 ->
        set dist-5 sum [distance-traveled] of attendees with [groupid = ?1] ;; sums up distance traveled for groups of specific size
        set time-5 sum [time-traveled] of attendees with [groupid = ?1]  ;; sums up time for groups of specific size
      ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1531
448
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
-50
50
-16
16
1
1
1
ticks
30.0

BUTTON
106
29
173
62
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
109
76
172
109
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
15
498
200
531
numberOfAttendees
numberOfAttendees
100
1000
100.0
10
1
NIL
HORIZONTAL

SLIDER
357
497
529
530
numberOfOfficers
numberOfOfficers
10
20
10.0
5
1
NIL
HORIZONTAL

SLIDER
651
498
859
531
numberOfPickpockets
numberOfPickpockets
0
10
5.0
1
1
NIL
HORIZONTAL

SLIDER
15
539
187
572
percent-male
percent-male
0
100
59.0
1
1
NIL
HORIZONTAL

PLOT
1552
20
1876
252
Distribution of Distractedness
Level of Distractedness
Number of Attendees
0.0
20.0
0.0
30.0
true
false
"" "if ticks > 0 [ stop ]"
PENS
"default" 1.0 1 -16777216 true "" "histogram [distracted] of attendees"

MONITOR
1584
487
1709
540
Number of Males
count attendees with [ gender = \"male\"]
3
1
13

MONITOR
1721
486
1863
539
Number of Females
count attendees with [ gender = \"female\"]
3
1
13

SLIDER
356
534
548
567
width-of-officer-vision
width-of-officer-vision
0
50
10.0
5
1
NIL
HORIZONTAL

SLIDER
651
535
889
568
width-of-pickpocket-vision
width-of-pickpocket-vision
0
50
15.0
5
1
NIL
HORIZONTAL

SLIDER
13
579
279
612
attendee-distracted-speed
attendee-distracted-speed
0
1.5
0.5
.1
1
NIL
HORIZONTAL

SLIDER
12
619
298
652
attendee-nonDistracted-male-speed
attendee-nonDistracted-male-speed
0
1.5
1.0
.1
1
NIL
HORIZONTAL

BUTTON
15
29
92
62
NIL
default
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
357
572
529
605
officerFollow
officerFollow
0
100
10.0
5
1
NIL
HORIZONTAL

SLIDER
356
609
528
642
officer-speed
officer-speed
0
3
0.5
.1
1
NIL
HORIZONTAL

SLIDER
652
610
832
643
pickpocket-speed
pickpocket-speed
0
3
1.0
.1
1
NIL
HORIZONTAL

PLOT
1554
264
1877
475
Distribution of Outward Appearance of Wealth
Level of Wealth
Number of Attendees
0.0
20.0
0.0
30.0
true
false
"" "if ticks > 0 [ stop ]"
PENS
"default" 1.0 1 -16777216 true "" "histogram [wealth] of attendees"

SLIDER
651
572
829
605
pickpocketFollow
pickpocketFollow
0
100
20.0
5
1
NIL
HORIZONTAL

TEXTBOX
22
473
172
491
ATTENDEES
14
0.0
1

TEXTBOX
366
477
443
495
OFFICERS
14
0.0
1

TEXTBOX
653
478
742
497
PICKPOCKET
14
0.0
1

TEXTBOX
10
132
205
152
OFFICER STARTING POSITION
14
0.0
1

SWITCH
38
154
148
187
config-1
config-1
0
1
-1000

SWITCH
37
238
147
271
config-2
config-2
1
1
-1000

TEXTBOX
32
190
174
223
Config #1: Officers are all in line with the venue's doors
11
0.0
1

TEXTBOX
34
277
174
325
Config #2: Officers are positioned such that they're staggered
11
0.0
1

MONITOR
1584
553
1863
606
Number of Pickpockets (as a % of Total)
100 * (count pickpockets with [ color = white ]) / numberOfPickpockets
3
1
13

MONITOR
1584
614
1761
667
% Police Alerted
100 * (count officers with [color = white]) / numberOfOfficers
3
1
13

TEXTBOX
1586
690
1778
711
NUMBER OF GROUPS BY SIZE
14
0.0
1

MONITOR
1500
715
1569
768
Size = 1
item 0 summary-group-list
3
1
13

MONITOR
1574
715
1643
768
Size = 2
item 1 summary-group-list
3
1
13

MONITOR
1648
714
1717
767
Size = 3
item 2 summary-group-list
3
1
13

MONITOR
1724
713
1793
766
Size = 4
item 3 summary-group-list
3
1
13

MONITOR
1800
712
1869
765
Size = 5
item 4 summary-group-list
3
1
13

PLOT
909
479
1495
768
Average Speed by Group Size
Time
Average Speed (m / sec)
0.0
10.0
0.0
1.5
true
true
"" ""
PENS
"group-size-1" 1.0 0 -16777216 true "" "if time-1 > 0 [plot dist-1 / time-1]"
"group-size-2" 1.0 0 -2674135 true "" "if time-2 > 0 [plot dist-2 / time-2 ]"
"group-size-3" 1.0 0 -11085214 true "" "if time-3 > 0 [plot dist-3 / time-3]"
"group-size-4" 1.0 0 -13791810 true "" "if time-4 > 0 [plot dist-4 / time-4]"
"group-size-5" 1.0 0 -5825686 true "" "if time-5 > 0 [plot dist-5 / time-5]"

BUTTON
11
76
96
109
go-once
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
12
657
314
690
attendee-nonDistracted-female-speed
attendee-nonDistracted-female-speed
0
1.5
0.9
.1
1
NIL
HORIZONTAL

SWITCH
696
733
906
766
calculateAverageSpeed
calculateAverageSpeed
1
1
-1000

SWITCH
11
366
135
399
new_seed
new_seed
0
1
-1000

INPUTBOX
10
403
165
463
seed
-1.82282591E9
1
0
Number

TEXTBOX
12
341
119
359
RANDOM SEED
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

The Simple Exploration of Pickpocketing prototype model was created to explore how an individual’s level of distractedness and outward display of wealth may cause a would-be pickpocket to target that person.  The basic premise of the model is based off of routine activity theory, which was developed by Drs. Lawrence Cohen and Marcus Felson, and formalized in their 1979 paper.

## HOW IT WORKS

There are three different agents: attendees exiting one of three gates at a sports venue who are not prone to conduct any criminal activity, police officers, and those who attempt to pickpocket.  The attendees exiting the sports venue can be targets of pickpocketing due to their inattentiveness or outward appearance of wealth.  Police officers have one role, that of a capable guardian.  In this model, they never commit crimes and are never pickpocket targets.  Those who attempt to pickpocket (“motivated offender”) look for an opportunity to do so.  In other words, they target an inattentive or outwardly “wealthy” attendee (“suitable target”), but will not attempt a pickpocket if a police officer is in close proximity (functioning as a “capable guardian”).

Attendees are defined by the following variables:

Gender – either male (green) or female (yellow).  According to SportsBusiness Daily (2010), 41 percent of baseball and football fans are female.  The simulation assumes the same demographic split, but the percent-male parameter is adjustable.

Distracted – a value drawn from a normal distribution.  This variable is a proxy for whether an individual is not focused on his surroundings (e.g., texting while walking) while walking.  Those who are more distracted could be “suitable targets” for those looking to pickpocket.

Wealth – a value drawn from a normal distribution.  This variable is a proxy for whether an individual exhibits an outward appearance of wealth.  Those who display more exterior wealth (e.g., designer clothing or accessories) could be “suitable targets” for those looking to pickpocket.

Attendee-Distracted-Speed – attendees who are more than one standard deviation above the distracted mean will walk at a slower speed.

Attendee-NonDistracted-Male-Speed – male attendees who are less than one standard deviation above the dstracted mean will walk at a faster speed than those who are distracted.

Attendee-NonDistracted-Female-Speed – female attendees who are less than one standard deviation above the dstracted mean will walk at a faster speed than those who are distracted, but will walk slower than non-distracted, male attendees.

The police officers (blue) will start the simulation in one of two configurations ("config-1" or "config-2").  They will follow a distracted attendee for a period of time--i.e., serving as a "capable guardian"--if that attendee enters the police officer's field of vision, which is represented by a blue parabolic shape extending from the agent.

Like police officers, would-be pickpocket agents (red) also have a field of vision.  They seek out suitable targets who appear to be distracted or who appear to have a higher-than-average wealth.

There are a number of monitors and charts on the model's interface, including a graph that will capture the average walking speeds (of the attendees) by group size.

## HOW TO USE IT

To use the model, click ‘default’, ‘setup’, and then ‘go’. This will run the model using a set of default variables.  The user can also vary many parameters in the model by adjusting the sliders.  Note: To change the officer's starting configuration, turn one of the switches off, and the other one on.

For each run, a new random seed will be generated, unless the user switches the new_seed switch to off.

## EXAMPLE SEEDS

Example of an officer witnessing a pickpocket: -1780904410.

Notes: An attendee is pickpocketed at the top-center of screen (~105-110 ticks).  On the right side of screen (~190 ticks), another attendee is pickpocketed.  On the right side of the screen, another pickpocket occurs (~205 ticks) where the pickpocket's vision didn't overlap with the officer's (i.e., pickpocket agent didn't see the officer), but the officer saw the pickpocket and chases after that suspected agent.  The last pickpocket agent flees because of the police activity.

Other examples of an officer witnessing a pickpocket: -286121773 and -1418394178.

Example of officers being alerted to a pickpocket: -32533269.

Notes: The pickpocket agent cannot pickpocket an attendee (~60 ticks) because he sees an officer in his field of vision.  The pickpocket agent then spots another attendee and pickpockets (~85 ticks).  This pickpocket, however, is noticed by an observant attendee in close proximity who calls for an officer's help.  Four officers in the area respond and then go after the pickpocket suspect, which causes the other would-be pickpockets to flee.

Other exapmles of officers being alerted to a pickpocket: -506447046 and -1730440798.

## THINGS TO NOTICE

When using the default parameters, try and see how many times a police officer is alerted to a pickpocket incident by an observant attendee in close proximity, and how many times a police officer observes the criminal activity firsthand because it occurred in his field of vision.

## THINGS TO TRY

(1) Adjust the number of officers to see if the increased resources available impacts the default/baseline results.
(2) Vary the length of time that an officer will follow a distracted attendee (i.e., serving as a capable guardian) to see if this impacts the default/baseline results.
(3) Increase the officer's field of vision to see how this changes the default/baseline results.

## EXTENDING THE MODEL

There is certainly much future work that could evolve out of this prototype model, including (1) the integration of GIS to allow for obstacles which may obscure a would-be pickpocket's (or officer's) field of vision; (2) the addition of plain clothes officers so would-be pickpockets are unaware of all officers present in the vicinity; and (3) the incorporation of game theory so that criminals could work in small teams.

## NETLOGO FEATURES

Note the 'setup' section of the code where attendees are assigned to groups ranging in size from one to five individuals to be able to capture group dynamics--i.e., those walking in groups tend to walk together.  Thus, a faster-walking individual who gets out in front of the group will slow down or stop to allow the other group members to catch up.

## RELATED MODELS

The idea of the attendees' delayed initial departure is taken from the NetLogo's Ant model.

The idea of "vision cones" is based on the NetLogo Bug Hunt Coevolution model.

## CREDITS AND REFERENCES

Cohen, Lawrence E., and Marcus Felson.  “Social Change and Crime Rate Trends: A Routine Activity Approach,” American Sociological Review, Vol. 44 No. 4 (August 1979): 588-608.

Wilensky, U.  NetLogo.  http://ccl.northwestern.edu/netlogo/.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL, 1999.
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

vision cone
true
2
Polygon -955883 false true 150 150 285 75 255 45 210 15 150 0 90 15 45 45 15 75 150 150

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
  <experiment name="verification" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>dist-1</metric>
    <metric>time-1</metric>
    <metric>dist-2</metric>
    <metric>time-2</metric>
    <metric>dist-3</metric>
    <metric>time-3</metric>
    <metric>dist-4</metric>
    <metric>time-4</metric>
    <metric>dist-5</metric>
    <metric>time-5</metric>
    <enumeratedValueSet variable="width-of-pickpocket-vision">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-speed">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width-of-officer-vision">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new_seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-female-speed">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-male-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocket-speed">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calculateAverageSpeed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfPickpockets">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfOfficers">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-distracted-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAttendees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-male">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-1">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-2">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocketFollow">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officerFollow">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_config1" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>seed</metric>
    <metric>100 * (count pickpockets with [ color = white ]) / numberOfPickpockets</metric>
    <metric>100 * (count officers with [color = white]) / numberOfOfficers</metric>
    <enumeratedValueSet variable="width-of-pickpocket-vision">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width-of-officer-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new_seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-female-speed">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-male-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocket-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calculateAverageSpeed">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfPickpockets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfOfficers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-distracted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAttendees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-male">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-1">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-2">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocketFollow">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officerFollow">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_config2" repetitions="1000" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>seed</metric>
    <metric>100 * (count pickpockets with [ color = white ]) / numberOfPickpockets</metric>
    <metric>100 * (count officers with [color = white]) / numberOfOfficers</metric>
    <enumeratedValueSet variable="width-of-pickpocket-vision">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width-of-officer-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new_seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-female-speed">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-male-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocket-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calculateAverageSpeed">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfPickpockets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfOfficers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-distracted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAttendees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-male">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-1">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-2">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocketFollow">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officerFollow">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="numberOfficers" repetitions="250" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>seed</metric>
    <metric>100 * (count pickpockets with [ color = white ]) / numberOfPickpockets</metric>
    <metric>100 * (count officers with [color = white]) / numberOfOfficers</metric>
    <enumeratedValueSet variable="width-of-pickpocket-vision">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width-of-officer-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new_seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-female-speed">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-male-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocket-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calculateAverageSpeed">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfPickpockets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfOfficers">
      <value value="15"/>
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-distracted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAttendees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-male">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-1">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-2">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocketFollow">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officerFollow">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="officerFollow" repetitions="150" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>seed</metric>
    <metric>100 * (count pickpockets with [ color = white ]) / numberOfPickpockets</metric>
    <metric>100 * (count officers with [color = white]) / numberOfOfficers</metric>
    <enumeratedValueSet variable="width-of-pickpocket-vision">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width-of-officer-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="new_seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-female-speed">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-male-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocket-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calculateAverageSpeed">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfPickpockets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfOfficers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-distracted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAttendees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-male">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-1">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-2">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocketFollow">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="officerFollow" first="25" step="25" last="100"/>
  </experiment>
  <experiment name="officerVision" repetitions="150" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>seed</metric>
    <metric>100 * (count pickpockets with [ color = white ]) / numberOfPickpockets</metric>
    <metric>100 * (count officers with [color = white]) / numberOfOfficers</metric>
    <enumeratedValueSet variable="width-of-pickpocket-vision">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officer-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="width-of-officer-vision" first="20" step="10" last="50"/>
    <enumeratedValueSet variable="new_seed">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-female-speed">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-nonDistracted-male-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocket-speed">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="calculateAverageSpeed">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfPickpockets">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfOfficers">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="attendee-distracted-speed">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="numberOfAttendees">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percent-male">
      <value value="59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-1">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="config-2">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="pickpocketFollow">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="officerFollow">
      <value value="10"/>
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
