; UAV Task Allocation Model

; define events and workers breeds
breed [ events event ]
breed [ workers worker ]


workers-own
[
  worker-type
  previous-event-processed-type
  switch-cost-assigned?
  skills
  my-current-event
  available?
  busy-time
  running-total-busy-time
  running-period-busy-time
  proportion-time-processing
  proportion-period-busy
  SA-error?
]


events-own[
  overload-error?
  being-processed?
  fulfilled?
  my-current-worker
  expert-processing-time
  waiting
  event-type
  event-time
]

globals [
  periodtime ; keeps sim-time in ten minute chunks
  overload-error-count
  total-events-fulfilled
  SA-error-count
  manage ; mc task
  navigate ; avo task
  different-tasks
  periodcounter ; keeps track of how many 10 minute chunks of time have occured so periodtime can be updated correctly
  CumulativeSwitchCost

; discrete event simulation management variables
  current-time
  event-queue
  event-waiting-queue
  sim-time
  sim-end
  MeanWaiting
  MeanBusyAVO
  MeanBusyMC
]


;initialize global variables
;
to init-globals

  set manage "MC-task"
  set navigate "AVO-task"
  set sim-end -1
  set sim-time 0
  set total-events-fulfilled 0
  set event-queue []
  set event-waiting-queue []
  set different-tasks 0
  set SA-error-count 0
  set overload-error-count 0
  set periodtime 0
  set periodcounter 0
  set CumulativeSwitchCost 0
  set MeanWaiting 0
  set MeanBusyAVO 0
  set MeanBusyMC 0
end


to setup

  clear-all
  init-globals
  set current-time 0

  ask patches [set pcolor 3]

  ; create initial set of events
  create-events NumberInitialEvents + 1 [  set event-time (1 + random (ApproximateMissionLength * 3600 )) ] ; mission length is converted from user-input hours to seconds

  set-default-shape events "box"

  ask events [
    let chance random-float 1.0

    ifelse (chance < %EventsMC) ; ifelse establishes approximate portion of MC and AVO tasks

    [ ;begin if portion of ifelse and set ~ half the events to MC tasks
      set event-type manage
      set expert-processing-time (random-normal Expert_MC_TaskTime (Expert_MC_TaskTime / 10) + 1)

      set color scale-color pink expert-processing-time (Expert_MC_TaskTime - 10) (Expert_MC_TaskTime + 10)
      set size 1.3

      set waiting 0
      set being-processed? false
      set fulfilled? false
      set my-current-worker nobody
      set overload-error? false

    ]

    ; begin else portion and set ~ half the events to AVO tasks
    [ set event-type navigate
      set expert-processing-time (random-normal Expert_AVO_TaskTime (Expert_AVO_TaskTime / 10 ) + 1)

      set color scale-color blue expert-processing-time (Expert_AVO_TaskTime - 10) (Expert_AVO_TaskTime + 10)
      set size 1.3

      set waiting 0
      set being-processed? false
      set fulfilled? false
      set my-current-worker nobody
      set overload-error? false
    ]
  ] ; end of intializing event parameters

  ; visualize MC-task events on the patches
  let x 0 - count events with [event-type = "MC-task"] / 2
  ask events[
    if event-type = "MC-task"
    [setxy x 7
      set x x + 1]
  ]

  ; visualize AVO-task events on the patches
  let x2 0 - count events with [event-type = "AVO-task"] / 2
  ask events[
    if event-type = "AVO-task"
    [setxy x2 -7
      set x2 x2 + 1]
  ]


  ; set the last event on the queue to be the sim-end event
  ;
  let last-event-time max [event-time] of events
  ask one-of events with [event-time = last-event-time]
  [
    set event-time 36000000000
    set event-type sim-end
    set hidden? true ; don't visualize the last event
  ]


  ; initialize event queue
  set event-queue sort-on [event-time] events


  ; set up the traits of the workers and visualize on the patch

  set-default-shape turtles "person"

  create-workers NumberOfWorkers
  let x-cord  0 - (NumberOfWorkers / 1.1)
  ask workers [
    setxy x-cord 0
    set x-cord x-cord + 2
    set color 116
    set size 3

    set available? true
    set my-current-event nobody
    set busy-time 0
    set running-total-busy-time 0
    set running-period-busy-time 0
    set previous-event-processed-type 0
    set proportion-time-processing 0
    set switch-cost-assigned? false
    set SA-error? false
  ]

  ;; set up different skill levels depending on whether generalists or specialized,
  ;; specialized need to divide number workers by proportion of user-defined % and assign different skills
  ifelse specialized?
    [ ; if the user says the workers are specialized and have MC and AVO only skills
      let numberEach (NumberOfWorkers * %WorkersMC)

      ask workers
      [ set worker-type "MC"
        set skills ( list (randomMC) (0) )
        set color pink
        set label worker-type
      ]
      ask n-of numberEach workers with [worker-type = "MC"]
        [ set worker-type "AVO"
          set skills ( list (0) (randomAVO) )
          set color blue
          set label worker-type]
    ]
  ;end of if, begin else for generalist skill assignment

    [ask workers
      [set worker-type "Generalist"
        set skills ( list (randomGeneral) (randomGeneral) )
      set label "G"]
    ] ; end of ifelse

  reset-ticks
end


; each of the below three reports a skill level between 0-1
to-report randomMC
  if TeamExperienceLevel = "Novice"
  [ let num1 0.2
    let num2 0.8
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

  if TeamExperienceLevel = "Journeyman"
  [ let num1 0.6
    let num2 0.4
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

  if TeamExperienceLevel = "Expert"
  [ let num1 0.9
    let num2 0.1
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]


end

to-report randomAVO
  if TeamExperienceLevel = "Novice"
  [ let num1 0.2
    let num2 0.8
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

  if TeamExperienceLevel = "Journeyman"
  [ let num1 0.6
    let num2 0.4
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

  if TeamExperienceLevel = "Expert"
  [ let num1 0.9
    let num2 0.1
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

end

to-report randomGeneral
  if TeamExperienceLevel = "Novice"
  [ let num1 0.1
    let num2 0.9
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

  if TeamExperienceLevel = "Journeyman"
  [ let num1 0.5
    let num2 0.5
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

  if TeamExperienceLevel = "Expert"
  [ let num1 0.8
    let num2 0.2
    let randomNum precision (num1 + random-float num2) 2
    report randomNum]

end






to step
  ifelse length event-queue > 0 ; if there are 2 or more events on the queue, do the following
  [ if length event-queue > 1 [set periodtime periodtime + 1]
    process-next-event ; call process-next-event method
    task-switching-cost ; check if switching between event types and assign a cost if so
    ;process-concurrent-events  ; will add in later version

    if errorsPossible? = true [update-busyness] ;; if user sets to true, go to update-busyness procedure

    ask workers [
      if my-current-event != nobody [ ; makes sure every worker is assigned to an event before checking about error possibilities and updating busy-time
        if (busy-time > 0 and ([overload-error?] of my-current-event = true))
        [set busy-time  precision (OverloadTimeProcessingPenalty * busy-time) 2
          ask my-current-event [set overload-error? false]

    ]
      ]
    ]

    ask workers[
      ifelse busy-time > 0
      [set available? false
        print "Busybefore"  print busy-time
        set busy-time precision (busy-time - 1) 2

        print "Busyafter" print busy-time]
      [set available? true
        set switch-cost-assigned? false
        ]
    ]

    ask events[
      if my-current-worker != nobody[
      if ([busy-time] of my-current-worker < 1) ; if the worker busy-time is less than 1
      [
        set fulfilled? true
        set total-events-fulfilled total-events-fulfilled + 1

        let event-now event-type
        ask my-current-worker [ set previous-event-processed-type event-now]


        die ; kill the event
        ask my-current-worker[
          set available? true
          set switch-cost-assigned? false
          ] ]; make the current worker available again

    ]]
  ] ; end of if portion of ifelse, so there are 1 or fewer items on the event-queue

  [
    print "doneso!"
    stop ; else portion of ifelse
  ]

  if length event-queue >  1 [set sim-time sim-time + 1]
  if length event-queue >  1 [tick]

set MeanWaiting (mean [waiting] of events with [being-processed? = false])

ask workers [if worker-type != "Generalist"[
set MeanBusyAVO (mean ([proportion-time-processing] of workers with [worker-type = "AVO"]))
set MeanBusyMC (mean ([proportion-time-processing] of workers with [worker-type = "MC"]))
]]


end

;; calculate and reset proportion time processing every 10 minutes

to update-busyness

  ask workers [
    if sim-time > 0 [set proportion-time-processing (running-total-busy-time / sim-time)]
    if sim-time > 0 [set proportion-period-busy (running-period-busy-time / periodtime)]
;    print "total" print running-total-busy-time
;    print "proportion" print proportion-time-processing ; for error checking
  ]

  if ( sim-time > 0 and (remainder sim-time 600 = 0 )) ; check every 600 seconds only every ten minutes, will check for possibility of error
  [
    ask workers [
      if proportion-time-processing > 0.7 and my-current-event != nobody[ ; check if total busy % is too high
        let chance random 1
        if chance < 0.8
        [let num [who] of my-current-event
          ask events [ if who = num [set overload-error? true]]]
      ]
      if proportion-period-busy > 0.7 and my-current-event != nobody[ ; check if ten minute period busy % is too high
        let chance2 random 1
        if chance2 < 0.8
       [let num2 [who] of my-current-event
          ask events [ if who = num2 [set overload-error? true]]]
      ]
    ]
    ask events [ if overload-error? = true [
        set overload-error-count overload-error-count + 1]]

    ask workers [ if sim-time > 0 [
      if proportion-time-processing < 0.3 ; check if total busy % is too low and trigger SA possible error
       [set SA-error? true]

      if proportion-period-busy < 0.3 ; check if ten minute period busy % is too low
       [set SA-error? true]

    ]]

    ask workers [
      if SA-error? = true
      [set SA-error-count SA-error-count + 1
        set SA-error? false]
    ] set periodcounter periodcounter + 1
   ]

  if ( remainder sim-time 601 = 1 ) ; reset the running busy-time at the beginning of each new 10 minute chunk of time ; May want to think of a better way to do this in case of issues with the time increment....
  [ set periodtime 2 + periodcounter
    ask workers [ set running-period-busy-time 0

    set SA-error? false] ; reset the possiblity for an SA error every 10 minutes
    ask events [set overload-error? false]
    ]
end



to go

  set current-time current-time + 1
  if length event-queue <  2
  [print "Woohoo! All done!" ]

 if current-time > 10 [
   if length event-queue < 2
   [stop]]

  step
end


; simulation management method
to process-next-event

  set event-queue sort-on [event-time] events   ; sort event queue in increasing order by event-time

  if (length event-queue > 0)  ; check if there are events on the queue, if so do the following
    [let i 0
      while [(i < length event-queue) and (([event-time] of item i event-queue) <= sim-time) ] ; do the following while there are still events on the queue and there are events with
      [                                                                                        ; an event-time equal to or less than the current sim-time, i.e. that should be processed if they can be
        let current-event item i event-queue ; process event i, which will have an event-time less than or equal to sim-time
        ask current-event [

;; Tasking for Specialists (MCs and AVOs, not Generalists)


          if event-type = "MC-task" [ ; do the following if the event is an MC-task

            if (count (workers with [worker-type = "MC" and available?]) > 0)  or (my-current-worker != nobody) ; if there are available MC workers or the event already has a worker assigned

              [ ask current-event [set being-processed? true] ;beginning of if portion
                if (my-current-worker = nobody)
                [set my-current-worker one-of workers with [worker-type = "MC" and available?]] ; make sure only one worker can be assigned to one task - only available workers can be assigned to an event

                ask my-current-worker[
                  create-link-to current-event
                  ask links [set color white]

                  set available? false
                  set my-current-event current-event

                  if (busy-time < 1 and ([overload-error?] of current-event = false))
                  [set busy-time  precision ([expert-processing-time] of current-event * (1 + (1 - item 0 skills))) 2]
                ]
              ]
          ]

          if event-type = "AVO-task" [ ; do if the task is an AVO task

            if (count (workers with [worker-type = "AVO" and available?]) > 0) or (my-current-worker != nobody)

            ;if portion
            [ ask current-event [set being-processed? true]
              if my-current-worker = nobody
              [set my-current-worker one-of workers with [worker-type = "AVO" and available?]] ; make sure only one worker can be assigned to one task

              ask my-current-worker[
                create-link-to current-event
                ask links [set color white]

                set available? false
                set my-current-event current-event

                if (busy-time < 1 and ([overload-error?] of current-event = false)) ; check to make sure the worker isn't already working on something
                [set busy-time precision ([expert-processing-time] of current-event * (1 + (1 - item 1 skills))) 2]
              ]
            ]

          ]
;;
;; Tasking for Generalists
;;

          if event-type = "AVO-task" [

            if (count (workers with [worker-type = "Generalist" and available?]) > 0)  or (my-current-worker != nobody)

            ;if portion
            [ ask current-event [set being-processed? true]
              if my-current-worker = nobody [set my-current-worker one-of workers with [worker-type = "Generalist" and available?]] ; make sure only one worker can be assigned to one task

              ask my-current-worker[
                create-link-to current-event
                ask links [set color white]


                set available? false
                set my-current-event current-event

                if (busy-time < 1 and ([overload-error?] of current-event = false))
                [set busy-time  precision ([expert-processing-time] of current-event * (1 + (1 - item 1 skills))) 2]
              ]
            ]


          ]

          if event-type = "MC-task" [

            if (count (workers with [worker-type = "Generalist" and available?]) > 0)  or (my-current-worker != nobody)

            ;if portion
            [ ask current-event [set being-processed? true]
              if my-current-worker = nobody [set my-current-worker one-of workers with [worker-type = "Generalist" and available?]] ; make sure only one worker can be assigned to one task

              ask my-current-worker[
                create-link-to current-event
                ask links [set color white]


                set available? false

                set my-current-event current-event

                if (busy-time < 1 and ([overload-error?] of current-event = false))
                [set busy-time precision ([expert-processing-time] of current-event * (1 + (1 - item 0 skills))) 2]


              ]
            ]


          ]

        ]

      set i i + 1   ;; increases i by 1 for the while loop to ensure that all current event-time events are checked
    ]

    ask workers[
      if available? = false
        [
          set running-total-busy-time running-total-busy-time + 1
          set running-period-busy-time running-period-busy-time + 1
         ; print "total" print running-total-busy-time ; debugging
         ; print "period" print running-period-busy-time ; debugging
        ]
    ]

    if (length event-queue > 1)
    [
      ask events [
        if ((my-current-worker = nobody) and event-time <= sim-time)
        [ set waiting waiting + 1
          set being-processed? false]
      ]
    ]
  ]
end

to task-switching-cost
ask workers [
  if my-current-event != nobody[

  ifelse ((previous-event-processed-type = ([event-type] of my-current-event)) or (previous-event-processed-type = 0 ))
    [print "same"]
    [ if switch-cost-assigned? = false[
      print "different"

      if ([event-type] of my-current-event = "AVO-task")
      [ let Cost1 (ExpertTaskSwitchCost * (1 + (1 - item 1 skills)))
        set busy-time precision (busy-time + (ExpertTaskSwitchCost * (1 + (1 - item 1 skills)))) 2
        set CumulativeSwitchCost CumulativeSwitchCost + Cost1
        print "SWITCHED!"]

      if ([event-type] of my-current-event = "MC-task")
      [ let Cost2 (ExpertTaskSwitchCost * (1 + (1 - item 0 skills)))
        set busy-time precision (busy-time + (ExpertTaskSwitchCost * (1 + (1 - item 0 skills)))) 2
        set CumulativeSwitchCost CumulativeSwitchCost + Cost2
        print "SWITCHED!"]

      set switch-cost-assigned? true
      set different-tasks different-tasks + 1]
  ]
    ]
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
247
10
1178
299
-1
-1
13.38
1
10
1
1
1
0
0
0
1
-34
34
-10
10
0
0
1
ticks
30.0

BUTTON
8
10
71
43
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
75
11
138
44
step
step
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
141
11
204
44
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

MONITOR
1202
57
1305
102
sim-time in Minutes
sim-time / 60
0
1
11

MONITOR
1199
150
1311
195
# events on queue
length event-queue - 1
0
1
11

SLIDER
114
99
244
132
NumberInitialEvents
NumberInitialEvents
1
65
65.0
1
1
NIL
HORIZONTAL

SLIDER
3
54
125
87
NumberOfWorkers
NumberOfWorkers
1
10
6.0
1
1
NIL
HORIZONTAL

SWITCH
4
98
108
131
specialized?
specialized?
0
1
-1000

MONITOR
1255
242
1331
287
# AVO Events
count events with [event-type = \"AVO-task\"]
17
1
11

SLIDER
3
168
175
201
%EventsMC
%EventsMC
0.1
0.9
0.5
.1
1
NIL
HORIZONTAL

SLIDER
1
469
219
502
Expert_MC_TaskTime
Expert_MC_TaskTime
30
300
150.0
30
1
Seconds
HORIZONTAL

SLIDER
2
504
219
537
Expert_AVO_TaskTime
Expert_AVO_TaskTime
30
300
150.0
30
1
Seconds
HORIZONTAL

MONITOR
1185
242
1255
287
# MC Events
count events with [event-type = \"MC-task\"]
17
1
11

TEXTBOX
449
25
984
51
Pink people = Mission Commanders (MCs) &  Pink Boxes = MC Tasks\n
15
135.0
1

TEXTBOX
481
269
995
290
Blue people = Air Vehicle Operators (AVOs) &  Blue Boxes = AVO Tasks
15
106.0
1

SLIDER
3
204
203
237
ApproximateMissionLength
ApproximateMissionLength
0.5
2
2.0
.5
1
Hours
HORIZONTAL

MONITOR
1186
288
1321
333
Mean Waiting Time Events
mean [waiting] of events with [being-processed? = false]
2
1
11

TEXTBOX
6
436
220
478
Mean number of seconds it would take an expert MC or AVO to complete their tasking\n
11
0.0
1

TEXTBOX
282
139
414
231
Darker events indicate less time needed to process, compared to lighter events\n
12
139.9
1

SLIDER
4
134
176
167
%WorkersMC
%WorkersMC
0
1
0.5
.10
1
NIL
HORIZONTAL

SWITCH
3
241
142
274
errorsPossible?
errorsPossible?
0
1
-1000

MONITOR
237
376
356
421
# SA Vulnerabilities
SA-error-count
17
1
11

MONITOR
1201
196
1312
241
# events fulfilled
total-events-fulfilled
17
1
11

SLIDER
3
316
203
349
OverloadTimeProcessingPenalty
OverloadTimeProcessingPenalty
1.1
1.3
1.1
.1
1
NIL
HORIZONTAL

MONITOR
1202
104
1305
149
Sim-time in Hours
sim-time / 3600
2
1
11

MONITOR
1203
10
1304
55
sim-time in seconds
sim-time
17
1
11

SLIDER
3
397
197
430
ExpertTaskSwitchCost
ExpertTaskSwitchCost
.5
10
2.0
.5
1
seconds
HORIZONTAL

MONITOR
251
517
338
562
# Task Switches
different-tasks
17
1
11

CHOOSER
128
51
244
96
TeamExperienceLevel
TeamExperienceLevel
"Novice" "Journeyman" "Expert"
2

MONITOR
527
515
622
560
% Busy Generalist
mean [proportion-time-processing] of workers
2
1
11

MONITOR
848
515
976
560
% Period Busy Generalist
mean ([proportion-period-busy] of workers)
2
1
11

MONITOR
649
515
750
560
% Period Busy AVO
mean ([proportion-period-busy] of workers with [worker-type = \"AVO\"])
2
1
11

MONITOR
751
515
847
560
% Period Busy MC
mean ([proportion-period-busy] of workers with [worker-type = \"MC\"])
2
1
11

MONITOR
458
515
525
560
% Busy MCs
mean ([proportion-time-processing] of workers with [worker-type = \"MC\"])
2
1
11

MONITOR
382
515
456
560
% Busy AVOs
mean ([proportion-time-processing] of workers with [worker-type = \"AVO\"])
2
1
11

TEXTBOX
229
434
373
462
SA and Overload Errors are checked every 10 minutes
11
0.0
1

MONITOR
248
326
347
371
# Overload Errors
overload-error-count
17
1
11

MONITOR
953
387
1045
432
Period Time (sec)
periodtime
17
1
11

TEXTBOX
7
353
203
395
Mean # seconds it would take an Expert to switch between an AVO and MC Task (i.e. scaled to experience level)
11
0.0
1

TEXTBOX
7
276
199
318
Time penalty assigned to process event, if worker is overloaded (over 10 minute time period)
11
0.0
1

PLOT
1046
333
1368
519
# Events on Queue &  Waiting Time
sim-time (seconds)
seconds
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"# events on Q" 1.0 0 -16777216 true "" "plot count events"
"waiting time" 1.0 0 -2674135 true "" "plot mean ([waiting] of events with [being-processed? = false])"

MONITOR
223
464
367
509
Total Task Switch Cost (Sec)
CumulativeSwitchCost
2
1
11

PLOT
660
325
951
513
% Time Busy Over 10 min Period
Mission Time (seconds)
% of Time Busy
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"General/All" 1.0 0 -5204280 true "" "if specialized? = false [plot mean [proportion-period-busy] of workers]"
"AVO" 1.0 0 -13345367 true "" "if specialized? = true [plot mean [proportion-period-busy] of workers with [worker-type = \"AVO\"]]"
"MC" 1.0 0 -2064490 true "" "if specialized? = true [plot mean [proportion-period-busy] of workers with [worker-type = \"MC\"]]"
"Overload" 1.0 2 -1318182 true "" "plot 0.7"
"Underload" 1.0 2 -1318182 true "" "plot 0.5"

PLOT
370
324
657
513
% Time Busy Throughout Mission
Mission Time (seconds)
% of Time Busy
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Generalist" 1.0 0 -5204280 true "" "if specialized? = false [plot mean ([proportion-time-processing] of workers)]"
"AVO" 1.0 0 -13345367 true "" "if specialized? = true [plot mean ([proportion-time-processing] of workers with [worker-type = \"AVO\"])]"
"MC" 1.0 0 -2064490 true "" "if specialized? = true [plot mean ([proportion-time-processing] of workers with [worker-type = \"MC\"])]"
"Underload" 1.0 2 -1318182 true "" "plot 0.5"
"Overload" 1.0 2 -1318182 true "" "plot 0.7"

@#$#@#$#@
## WHAT IS IT?

This model simulates a team of individuals conducting two different kinds of tasks over a period of time. In particular, this model was designed to mimic an Unmanned Aerial Vehicle (UAV) operator team engaged in a mission that involves two types of tasking events: Mission Command (MC) events and Air Vehicle Operator (AVO) events. The main purpose of this model is to perform what-if analysis of the impact of team structure and worker skill level on mission performance, efficiency, and safety.

Current UAV missions are conducted by operators who are specialized and only trained to perform either MC tasks or AVO tasks. However, increases in automation has led to significant operator downtime and dramatic fluctuations in workload, resulting in debate about whether cross-training operators to perform both tasks might be more efficient and yield better mission performance. In particular, questions exist about the implications of frequent task switching and increases in user workload. 

To help address some of these questions, this simulation allows the exploration of performance of specialized teams (with workers who can only perform one type of task) compared to cross-trained teams (with workers who can perform both tasks). Additionally, this model examines how skill level contributes to the performance of different team structures, since training will be one of the largest expenses if a cross-trained team structure is implemented.  

Specialized and cross-trained team structures can be compared by observing how errors, time to complete mission, and task wait times are impacted. Regarding errors, if an individual worker's workload exceeds 70% (measured by % of time busy processing an event) they may trigger an overload error. Conversely, if workload falls below 30%, the worker will trigger a possible SA error. These are explained in detail below. 


## HOW IT WORKS

This model has two sets of agents: workers and events. 

Workers:
 
Workers are either 1) specialized and can only process events that are the same specialty as they are (e.g. AVOs are blue and can only process AVO events which are blue) or 2) generalists and can process either type of event (e.g. Generalists are purple and can process either MC/pink or AVO/blue events). 

Workers also have a skill level which impacts the amount of time it takes for them to process an event. Generalist workers have a separate skill level for MC tasks and AVO tasks (e.g. a Generalist worker may have a 0.8/1.0 skill level for AVO tasks and a 0.6/1.0 skill level for MC tasks). Generalists also have a slightly reduced chance of being as skilled as specialists are, since Generalists are not solely focusing on one kind of task, like Specialists are.  This can be seen by comparing the randomGeneral and randomAVO procedures, which increase the range of the chance random variable by 0.1 for each experience level. For example compare the Specialist code below for the Novice skill level to the Generalist code: 

Specialist Novice code: 
  [ let num1 0.2 
    let num2 0.8 
    let randomNum precision (num1 + random-float num2) 2]
 
Generalist Novice code: 
  [ let num1 0.1 
    let num2 0.9 
    let randomNum precision (num1 + random-float num2) 2]
  
Events: 
Events are either 1) AVO events/blue or 2) MC events/pink. Each event has an event onset time for when it becomes available to be processed by a worker. The event onset time is randomly set to a number between 1 and the user-defined length of the mission (ApproximateMissionLength * 3600, this is multiplied by 3600 to convert event onset to seconds since MissionLength is set in hours). 

Events also have a processing time associated with them, that correspond with how long it would take for an expert to process them (experts have a skill level of 1.0). The amount of time that each event takes to process is normally distributed around the user-defined mean (Expert_MC_TaskTime) with a standard deviation of (Expert_AVO_TaskTime / 10 ). In the interface, the blue and pink events vary in shade to depict that the lighter events take more time to process than the darker events.

Once Go is Pressed: 
Mission time increases by one second every tick and when an event becomes available it will check to see if any workers are also available to work on that event. 
A worker can only process one event at a time, so if all workers are currently assigned to another task, the event will wait in a queue until a worker becomes available. Events also keep track of how long they are waiting in queue to be processed. 

Each worker's busy-time is calculated over the entire mission duration and recalculated every 10 minutes. Busy time is defined as the amount of seconds a worker is processing an event (and unavailable) compared to waiting for a new event to process. During each time-check (every 10 minutes), if a worker's busy-time percentage is above 70%, the worker has an 80% chance of having an overload error. If the worker does have an overload error, then a processing penalty is applied and it takes the worker longer to process an event. This is explained in detail below. 

If the worker's busy-time percentage is below 30% they trigger a situation awareness (SA) vulnerability alert. SA errors do not cause a penalty in time processing, but they do count up over the mission to make the user aware of a possible issue. 


## HOW TO USE IT

Pressing Setup on the interface tab will initiate your session, based upon the values input in the sliders, switches and chooser (each of which is described below). When the simulation is setup, workers and events will populate on the screen. Workers will appear in the middle of the screen as people and events will appear in a line above and below the workers. As noted above, the color of each of the MC and AVO events varies based upon the amount of time that event takes to process. The events are also sorted in the event-queue by increasing event onset time. 

After setup is initiated, the simulation is ready to run. The user can either step through each tick by pressing the "step" button, or press "go" to process all the events until there are no more events on the queue to process. Once "go" is pressed and the first event onset time is reached, that event is triggered as available and workers can begin processing them. When a worker begins processing an event, a link forms between the worker and the event and a white line is visualized between the two until the event is done being processed. 

The following is a list of parameters that the user can define through the sliders, chooser, and switches: 


- NumberOfWorkers: The number of workers visualized on the interface who can process events (1 -- 10 workers). 

- TeamExperienceLevel: The average skill level of the workers, which are individually set for each worker using a constant + a random number (e.g. Specialist Journeyman formula is: 0.5 + random 0.5) that will produce a number between 0 and 1.0. (Novice, Journeyman, Expert).

- Specialized?: If specialized, the workers are either AVOs or MCs and can only process AVO and MC events, repectively. If the workers are not specialized, all workers can process both AVO and MC events. 

- NumberInitialEvents: The intial number of events on the event queue (5 -- 65 events). 

- %WorkersMC: Percentage of the number of workers who, if specialized, are MCs (as opposed to AVOs) (0.0 -- 1.0). 
 
- %EventsMC: Percentage of events on the event queue that are MC events (0.1 -- 0.9).  

- ApproximateMissionLength: Approximate length of the UAV mission. This user-defined value is only an approximate length, bcause this value defines the event onset times. For example, if the user selects 4 hours, the final event could begin at 3 hours, 59 minutes and 59 seconds into the mission and the mission would extend beyong 4 hours until that final event is done being processed (0.5 - 2 hours).

- errorsPossible? : If errorsPossible is set to true, workers' "overload error" count will increment and workers will be penalized when their workload (percent time busy/unavailable) is too high. Additionally, if workload is too low, the number of possible SA errors will increment. 

- OverloadTimeProcessingPenality: If errorsPossible? is set to true and a worker triggers an overload error, that worker will face a time penalty that takes that worker's current time left to process the event (busy-time) and multiplies it by the user-input OverloadTimeProcessingPenality. For example, if an overload error is triggered on worker 3 whose current busy-time is 12 and OverloadTimeProcessingPenality is set to 1.3, Worker 3's busy-time is updated to 15.6 (12 * 1.3). (1.1 -- 1.3)

- ExpertTaskSwitchCost: If specialized? is set to false (the team structure is Generalist) then any time a Generalist worker switches between processing an event of one type (e.g. MC event) to a different event type (e.g. AVO type), they incur a task switch cost that is added to the worker's new event processing time. (0.5 -- 10 seconds).

- Expert_MC_TaskTime: This slider establishes approximately how long it would take for an expert to process an MC event. This is explained in greater detail below. 

- Expert_AVO_TaskTime: This slider establishes approximately how long it would take for an expert to process an AVO event. This is explained in greater detail below. 


Once "go" is pressed and the model is running available workers can begin to process events. A worker can be in one of two states - available or not available. When a worker is processing an event, they are not available. When they are not processing any events, they are available. Again, a worker can only process one event at a time in this simulation. If a worker is available and the next event on the event queue has an "event-time" that is the same (or less than) the current simulation time in seconds (or ticks), the available worker will be assigned to that event. Once the worker is assigned to a new event, their status changes to not available and they are assigned a "busy-time" that equates to the number of seconds that it will take for them to process the event. The busy-time of each worker is determined by the following equation: 

[set busy-time  ([expert-processing-time] of current-event * (1 + (1 - item 0 skills)))] 

which mutliplies the current event's "expert-processing-time" by a factor of the worker's skill level associated with that event type. For example, if an MC event with an expert-processing-time of 100 were up and worker 54 with an MC skill level of .5 were available, worker 54's status would be updated to not available and its busy-time would be assigned to (100 * ( 1 + (1 - .75))) = 125. Worker 54 would then be busy/not available for at least the next 125 seconds. 

To continue the example, as each second ticks by/increments, worker 54's busy-time is updated and decremented by 1 each second. The simulation is also keeping track of the proportion of time that each worker is busy throughout both the entire mission time and every 10 minute increment. If worker 54 was busy for more than 70% of the last 10 minute chunk of time (and the simulation is set to errorsPossible? being true) and worker 54 is still processing an event, then a possible error is triggered, where there is a 80% chance that worker 54 will incur an overload error. If an error does occur, worker 54 will receive a time penalty defined by the OverloadTimeProcessingPenalty slider. 

For example, if 30 minutes just hit in the simulation, worker 54's 10-minute period and total missision proportion busy time will be assessed. If either are above 70%, worker 54 has an 80% chance of being penalized. If the penalty does occur and the user set the penalty (OverloadTimeProcessing slider) to 1.5, then worker 54's current busy-time will be multiplied by 1.5 and the Overload Error monitor will count up by 1. 

The simulation will also count the number of possible Situation Awareness (SA) Errors that could happen every ten minutes. If a worker's proportion of busy time over the last 10 minutes, or the entire mission thus far, is less than 30% a possible SA error is counted. Unlike the overload error, the worker does not have to be currently busy with/ processing an event in order to receive an SA error. These are intended to help notify the user of vulnerabilities in the mission which could lead to the worker missing an important alert or change in the system and ultimately cause a large error (i.e. damage to or loss of the UAV). 

While the events are waiting in queue to be processed, the time from when they were ready to begin being processed (event-time) to when a worker starts processing it is incremented. This is the event "waiting" time. The mean event waiting time is shown on the interface monitor and reflects the efficiency in the system. If the mean waiting time for events is high, there is a possible mismatch between the number or types of workers and events that could indicate more workers are required. On the other hand, a very low mean waiting time for events could indicate that there are too many workers who are idely awaiting tasking. The plots on the interface show both the average event waiting time and the average worker busy-time, both throughout the entire mission and calculated over a ten minute block of time. 

The other two plots "% Time Busy Throughout Mission" and "% Time Busy Over 10 Min Period" show the average time that each type of worker (MC, AVO, Generalist) is busy processing events either throughout the mission or every ten minute period of time. Markers are also shown on the plots at the 30 and 70 percent points to show the thresholds for SA errors and Overload errors. 


## THINGS TO NOTICE

Set the NumberOfWorkers to 6, TeamExperience to Novice, Specialized to Off, NumberInitialEvents to 65, %WorkersMC to 0.5, %Events to 0.5, ApproximateMissionLength to 1.0, errorsPossible to On, OverloadTimeProcessingPenalty to 1.2, ExpertTaskSwitchCost to 0.6, and both TaskTimes to 150 seconds. 

Look at the % Time Busy Throughout Mission and you should see that the average % time busy is generally under 70%, yet the count of OverloadErrors is high. The mission time plot is deceiving and makes the user think that performance should be optimal, which is why it is important to consider the period of time over which the workers are busy. The % Busy over 10 Min Period plot helps to expose periods when the average workload was high within the team, which the running % mission plot does not.

Now run the simulation again, but change the TeamExperience level to Expert. You should see that surprisingly, the number of overload errors is almost as high, and the number of possible SA errors is significantly higher than when the expertise was set to Novice. This demonstrates that the workload was not high enough for several of the team members since they were able to process the events so quickly and then were forced to wait.

Now run the simulation again, and change the switch to Specialized on. Note the difference in the SA errors and OverloadErrors. Then compare this to when the Experience level is switched back to Novice. 


## THINGS TO TRY

Shift the setting on the OverloadTimeProcessingPenalty slider and see how much a difference shifting the penalty from 1.2 to 1.5 to 2.0 makes on total mission time, average event  waiting time and the error counts. Note how this is impacted even more when you combine Experience level and shift from Expert to Novice. 

Shift the setting on the ExpertTaskSwitchCost slider to see how sensitive the model is to different levels of penalties for Generalist workers switching between tasks. 

Set the Specialized switch to true and shift the sliders for %WorkersMC and %EventsMC to see how different event and worker proportions impact the efficiency of the model. Then change the Specialized switch to false and see how much more efficient the model is when proportions are extreme. Does this have any implications for the real world? 


## EXTENDING THE MODEL

Extend the model to allow workers to process multiple events if an event has been waiting in the event queue for a certain length of time. Then impose a processing time penalty for concurrently processing two tasks. 

Calibrate the model to real-world tasking by distributing AVO tasking primarily in the first and last 25% of the mission time, and distribute MC tasking evenly throughout the mission. See how this impacts the different team structure performance. 

Add the occurance of low-frequency emergency situations that require a number of workers to pause what they are currently doing and focus all their attention dealing with the emergency. If an emergency occurs when all workers are busy processing high priority tasks, then add the possibility for the UAV to be destroyed/lost. 

Add dependencies that exist among events, where one event cannot be processed until another event is finished being processed. 

Add a cost for training operators to a certain level of skill and a cost for each error, to be able to do a quantitative cost/benefit comparison of different team structures and training. 


## RELATED MODELS

I was unable to find related models, since Discrete Event Simulations do not appear to be traditionally done within Netlogo.
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

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

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
    <metric>sim-time</metric>
    <metric>overload-error-count</metric>
    <metric>SA-error-count</metric>
    <metric>CumulativeSwitchCost</metric>
    <metric>different-tasks</metric>
    <metric>mean ([proportion-time-processing] of workers with [worker-type = "AVO"])</metric>
    <metric>mean ([proportion-time-processing] of workers with [worker-type = "MC"])</metric>
    <metric>mean [proportion-time-processing] of workers</metric>
    <metric>mean [waiting] of events with [being-processed? = false]</metric>
    <enumeratedValueSet variable="NumberInitialEvents">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TeamExperienceLevel">
      <value value="&quot;Novice&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ApproximateMissionLength">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%WorkersMC">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="errorsPossible?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialized?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OverloadTimeProcessingPenalty">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ExpertTaskSwitchCost">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_MC_TaskTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_AVO_TaskTime">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%EventsMC">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfWorkers">
      <value value="9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Sweep" repetitions="3" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>sim-time</metric>
    <metric>overload-error-count</metric>
    <metric>SA-error-count</metric>
    <metric>CumulativeSwitchCost</metric>
    <metric>different-tasks</metric>
    <metric>MeanBusyAVO</metric>
    <metric>MeanBusyMC</metric>
    <metric>mean [proportion-time-processing] of workers</metric>
    <metric>MeanWaiting</metric>
    <enumeratedValueSet variable="errorsPossible?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%EventsMC">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%WorkersMC">
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialized?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberInitialEvents">
      <value value="10"/>
      <value value="30"/>
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ApproximateMissionLength">
      <value value="0.5"/>
      <value value="1.5"/>
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OverloadTimeProcessingPenalty">
      <value value="1.1"/>
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfWorkers">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_MC_TaskTime">
      <value value="30"/>
      <value value="150"/>
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TeamExperienceLevel">
      <value value="&quot;Novice&quot;"/>
      <value value="&quot;Expert&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ExpertTaskSwitchCost">
      <value value="0.1"/>
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_AVO_TaskTime">
      <value value="30"/>
      <value value="150"/>
      <value value="300"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="errorsPossible?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%EventsMC">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TeamExperienceLevel">
      <value value="&quot;Expert&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%WorkersMC">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberInitialEvents">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfWorkers">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ExpertTaskSwitchCost">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ApproximateMissionLength">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialized?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OverloadTimeProcessingPenalty">
      <value value="1.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_MC_TaskTime">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_AVO_TaskTime">
      <value value="150"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Specialist-Same-Sweep" repetitions="30" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="28800"/>
    <metric>sim-time</metric>
    <metric>overload-error-count</metric>
    <metric>SA-error-count</metric>
    <metric>mean [waiting] of events with [being-processed? = false]</metric>
    <metric>mean ([proportion-period-busy] of workers)</metric>
    <metric>mean [proportion-time-processing] of workers</metric>
    <metric>mean ([proportion-period-busy] of workers with [worker-type = "MC"])</metric>
    <metric>mean ([proportion-period-busy] of workers with [worker-type = "AVO"])</metric>
    <metric>mean ([proportion-time-processing] of workers with [worker-type = "MC"])</metric>
    <metric>mean ([proportion-time-processing] of workers with [worker-type = "AVO"])</metric>
    <enumeratedValueSet variable="errorsPossible?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%EventsMC">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="TeamExperienceLevel">
      <value value="&quot;Novice&quot;"/>
      <value value="&quot;Journeyman&quot;"/>
      <value value="&quot;Expert&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%WorkersMC">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberInitialEvents">
      <value value="65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NumberOfWorkers">
      <value value="4"/>
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ExpertTaskSwitchCost">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ApproximateMissionLength">
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialized?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="OverloadTimeProcessingPenalty">
      <value value="1.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_MC_TaskTime">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Expert_AVO_TaskTime">
      <value value="150"/>
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
