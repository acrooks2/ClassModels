; Emotially-rational cognitive agents learn and evolve while playing an evolutionary iterated prisoners dilemma game

extensions [table]            ;; load hash table extension for quick access and input

;; ENDEMIC VARIABLES: set each simulation by user, most of these are set in the interface

globals[
  ;num-of-initial-people      ;; the number of people who will be born on the first round
  ;energy-cost-per-neuron     ;; the amount of energy a neuron consumes in one tick
  ;energy-cost-per-person     ;; the base amount of energy required for a person (patch) to live
  ;relative-getetic-variation ;; the amount of relative variation between parents and offspring. The std-dev of normal distribution
  ;max-brain-size             ;; an artificially imposed limit on brain size to prevent the simulation from
  ;resource-competition       ;; can be between 0 and 1 and represents how competitive resources are, 0 is no competition
  ;best-competition           ;; the percentage of players with lowest energy who die on each round
  ;tell-story?                ;; toggles on or off the story segments that follow a randomly chosen patch
  ;people-birth-energy        ;; the initial amount of energy that a person (patch) begins with
  ;people-birth-threshold     ;; the threshold above which successful people (patches) will reproduce
  ;emo-DD,emo-DC,emo-CD,emo-CC;; user set variables to initialize the emotion matrix on startup
  ;forgetfulness              ;; the decay rate of a neuron's imprint-utility
  people-death-threshold      ;; threshold below which unsuccessful people (patches) will die, usually 0
  neuron-death-threshold      ;; the threshold below which a neuron will die, usualy 0
  neuron-recombination-threshold  ;; threshold above which novel neuron wirings are tried
  energy-matrix               ;; energy gains or losses resulting from events, set to typical prisoner's dilemma payoffs
  protagonist                 ;; the patch which the story will follow
]

breed [neurons neuron]        ;; the agents in this model are all neurons used for pattern matching

;; variables set by the person (patch) as the simulation runs

patches-own [
  alive?                      ;; is this patch a living agent
  energy                      ;; the amount of energy that the patch has sequestered
  current-event               ;; the most current event witnessed (ie. [0 1])
  my-move                     ;; the last move made by the current patch
  partner                     ;; an agent that is an alive patch not already playing that is also a neighbor
  match-event                 ;; tells the person which gate-neuron to fire for a given event key (ie [0 1])
  decision-buffer             ;; stores all the sums of the imprints for a given gate neuron (ie. [0 0])
  counter                     ;; the number of turns left before a new partner is chosen
  played?                     ;; tells if the player has played a game this round or not
  score                       ;; a variable used only for the sake of plotting the agents progress
  adjusted-score              ;; another variable for the sake of plotting after competition is considered

  ;; GENETIC VARIABLES: set each time a person (patch) is born and varied acording to relative-genetic-variation (std-dev)

  ;forgetfulness               ;; the number that gets multiplied by an event that hasn't occured in a round
  reward-punishment-multiplier;; the number multiplied by an emotional response before a decision is made
  emotion-matrix              ;; the perceived imprint caused by a given event
]

;; MEMETIC VARIABLES: set by neurons of a person (patch), which self organize, each time a round of the prisoner's dilemma is played

neurons-own [
  imprint-utility             ;; a list representing the utility of the neuron's output given a number of inputs equal to its index
  events-pattern              ;; the list of events that match the whole neuron eg. [[0 1] [0 1] [1 1]]
  parent-neurons              ;; a table of parent neurons, can be empty or contain many neurons. Keys correspond to order of attachment
  signal?                     ;; a boolean value that tells whether a neuron has received a matching signal
  buffer                      ;; a changing list of lists containing matched patterns (maximum number of elements is (N+1)N/2

]

;; procedure that is run to initialize the model

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks                                      ;; clear all variables
  set-default-shape neurons "circle"             ;; set default shape of neurons to circles
  set people-death-threshold 0                   ;; energy threshold below which people die
  set neuron-death-threshold 0.001               ;; imprint threshold below which a neuron will die, unless it is 1 of 4 gate neurons
  set energy-matrix [[1 5] [0 3]]                ;; set the energy matrix for all people, can be negative or positve
  ask patches [
    set alive? false                             ;; set all patches to dead
  ]
  ask n-of num-of-initial-people patches [       ;; select initial number of people to start simulation with
    initialize-people                            ;; set some of the patch variables
    initialize-random-variables                  ;; set the genetic variables that can mutate throughout simulation
    mutate-random-variables                      ;; inserts variation each person's genetic variables
    initialize-neurons                           ;; set up the initial set of four event (or gate) neurons
  ]
  ifelse tell-story? [                                    ;; if true one of the patches is chosen to "tell" its story, mainly for debugging
    new-protagonist
  ][
    set protagonist nobody                                  ;; if no story is to be told set protagonist to nobody
  ]
  draw                                                    ;; draw the patches and initialize plots
end

;; procedure executed each tick of the model

to go
  if not any? patches with [alive?] [stop]                ;; stop simulation if all the patches die
  ask patches with [alive?] [
    set played? false                                     ;; resets the patches for a new round of game play
    find-partner                                          ;; find partner or reset partner
  ]
  ask patches with [alive? and partner != nobody] [
    play-round                                            ;; play a round of the game
  ]
  ask patches with [alive?] [
    receive-expend-energy                                 ;; spend energy, get spoils from game, and die if below energy threshold
    reproduce                                             ;; produce offspring in neighborhood if there is room and energy
  ]
  death-race                                              ;; kill all agents with enrergies that are the lowest
  draw                                                    ;; redraw plots and patches
  tick                                                    ;; advance the tick counter
end

to new-protagonist
  set protagonist one-of patches with [alive? = true]   ;; select a random patch
  tell protagonist "Once upon a time..."                ;; print to command center
  tell protagonist (word "I was born with this emotion-matrix, " [emotion-matrix] of protagonist ",")
  tell protagonist (word "and this reward-punishment-multiplier, " [reward-punishment-multiplier] of protagonist ",")
  tell protagonist (word "and this forgetfulness multiplier, " [forgetfulness] of protagonist)
end

;; procedure looks for a partner in the immediate Moore neighborhood that is alive and not playing already

to find-partner
  if partner != nobody and counter = 0[                   ;; find partner if counter is 0 and one is needed
    tell self (word "I finished my game with " partner)   ;; print to command center
  ask partner [reset-living-player]                       ;; resets patch's partner
  reset-living-player                                     ;; resets patch
  ]
  if partner = nobody [                                   ;; find partner if patch has none
    set partner one-of neighbors with [partner = nobody and alive? = true]    ;; set partner if available
    if partner != nobody [                                                    ;; if partner search returns nobody
      tell self (word "I started a new game with " partner)                   ;; print to command center
      ask partner[set partner myself]                     ;; ask new partner to set current patch to its partner
    ]
  ]
end

;; procedure for prisoner's dilemma game play

to play-round
  if not played? [                                           ;; execute if player hasn't played yet
    make-decision                                            ;; current patch makes its move
    ask partner [make-decision]                              ;; ask partner to make its move
    set current-event list (my-move) ([my-move] of partner)  ;; gets the current-event from players' last moves
    tell self (word "I felt " (get-element current-event emotion-matrix) " when " current-event " happened")
    color-neurons                                            ;; set neuron colors based on this round's outcome
    set counter counter - 1      ;; update counter used to determine the number of rounds to play with each partner
  ]
end

;; procedure that collects and rationally weighs neuron output and makes decision

to make-decision
  fire-neurons                                        ;; fires neurons which collect and process historical info
  let defect (table:get decision-buffer [0 0]) + (table:get decision-buffer [0 1])     ;; collect impressions for defection
  let cooperate (table:get decision-buffer [1 0]) + (table:get decision-buffer [1 1])  ;; collect impressions for cooperation
  let intensity cooperate - defect                                                     ;; intensity is used in final decision
  tell self (word "I imagined feeling this way, " intensity ", before I made a decision")   ;; print to command center
  ifelse intensity > 0 [                              ;; if intensity is greater than zero emotions support cooperation
    set my-move 1                                     ;; set my move to cooperate
    tell self "I chose to cooperate"                  ;; print to command center
  ][
    set my-move 0                                     ;; if intensity is negative then emotions support defection
    tell self "I chose to defect"                     ;; print to command center
  ]
  set played? true                                    ;; prevent player from playing twice in a round
  table:put decision-buffer [0 0] 0                   ;; reset the player's decision buffer in preperation for next round
  table:put decision-buffer [0 1] 0
  table:put decision-buffer [1 0] 0
  table:put decision-buffer [1 1] 0
end

;; procedure receives an event, allows neurons to interact, and then sends impressions to decision buffer for processing

to fire-neurons

  ;; code in this block is executed only if a current-event or history is available
  if not empty? current-event [
    let fired-gate table:get match-event current-event              ;; gets the gate neuron that has received a match signal
    ;ask fired-gate [set signal? true]                               ;; activates the gate neuron
    cascade fired-gate
  ]

  ;; code in this block is executed every round regardless whether an event has occured or a buffered short term memory exists
  ask neurons-here [                                            ;; neurons on this patch are asked to...

    ;;;;;;;;;;;;;;;;; send output of all neurons to decision buffer regardless of signal match ;;;;;;;;;;;;;;;;;;;;;;;;;
    let key item 0 events-pattern                               ;; get the event that activates this neuron
    tell myself (word self " with " key " matching event starts with buffer " (table:get decision-buffer key))
    let imprint item 0 imprint-utility                          ;; get the imprint that this neuron has recorded so far
    let emotion get-element key emotion-matrix                  ;; get the emotion that this neuron has associated with it
    let new-output (imprint * emotion)                            ;; get the output for this neuron for use in decision-buffer
    let old-value table:get decision-buffer key                 ;; get the value accumulated in the buffer matching this event
    table:put decision-buffer key (old-value + new-output)      ;; add the output from this neuron to the appropriate buffer
    tell myself (word self " fired to the " key " buffer, which is now " (table:get decision-buffer key))

    ;;;;;;;;;;;;;;;; apply match reward when appropriate ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    let match-update 0                                          ;; initialize match update to 0 in case it gets no match
    if signal? [                                                ;; if there is a signal run the following routines
      ;set imprint-utility (list (imprint + new-output * reward-punishment-multiplier))      ;; set matching imprints
      ;set imprint-utility (list (emotion / imprint))           ;; set matching imprints
      set match-update (abs emotion) / (imprint + 1)            ;; set matching imprint under a not less than zero constraint
      ;set imprint-utility (replace-item 0 imprint-utility match update)

      ;; send predicted outputs to decision buffers based on number of matching inputs in neuron buffer

      set signal? false                                         ;; reset matching signals to false
    ]

    ;;;;;;;;;;;;;;; apply forgetting to neuron imprints ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    let forget-update imprint * forgetfulness                   ;; set the forgetting amount for this tick

    ;;;;;;;;;;;;;;; set imprint-utility after updates ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    let new-imprint imprint + match-update - forget-update      ;; the new-imprint value if the follwoing test passes
    ifelse new-imprint < neuron-death-threshold and length imprint-utility = 1 [  ;; make sure gate neuron doesn't die
      set imprint-utility (list (neuron-death-threshold))             ;; give the gate neurons the lowest living imprint
    ][
      set imprint-utility (replace-item 0 imprint-utility new-imprint) ;; give the regular imprint if not a gate neuron near death
    ]
    tell myself (word self " with " events-pattern " event pattern has " imprint-utility " imprint-utility")
  ]

  ;; recombinate old successful neurons to create novel neurons

   ;; randomly combine neurons if their imprints are above a certain neuron-recombination-threshold

   ;; neuron apoptosis, kill neurons if their imprints fall below a certain neuron-death-threshold

end

;; procedure to run recursion of gate firings

to cascade [ fired-neuron ]
  ;; use avalanche(fired-gate) procedure that sets the given neuron's signal to true and
  ask fired-neuron [
    set signal? true
    ;; places the parent gates inside of a new avalanch(parent-gates) procedure
    if parent-neurons != nobody [
      foreach parent-neurons [ ?1 ->
        cascade ?1
      ]
    ]
  ]
end

;; procedure initializes the random genetic variables for each patch

to initialize-random-variables
  set emotion-matrix (list (list emo-DD emo-DC) (list emo-CD emo-CC))  ;; set the average of the emotional matrix
  set reward-punishment-multiplier .1                     ;; set the average of the reward-punishment-multiplier
  ;set forgetfulness .1                                    ;; set the average of the forgetfulness multipler
end

;; procedure initializes people

to initialize-people
  set alive? true
  set energy people-birth-energy
  set score -1                                            ;; set to -1 so that it doesn't get categorized as the last move of a player
  reset-living-player
end

;; procedure to instantiate new gate neurons, connecting current events to the neurons

to initialize-neurons                                     ;; set the four event (or gate) neurons
  sprout-neurons 4 [                                      ;; give each living patch four neurons
    set color magenta                                     ;; set the color of all newborn neurons to magenta
    set imprint-utility [1]                               ;; initialize all the imprints to 1 (anything but zero should produce the same effect)
    ;set parent-neurons table:make                         ;; the neurons have no connections to other neurons yet
    set parent-neurons nobody                             ;; the neurons have no connections to other neurons yet
    set signal? false                                     ;; the neurons have not yet received any signals from mathes
    set buffer []                                         ;; the neurons short-term memory have recorded nothing yet
  ]

  let gates sort neurons-here                             ;; sort the gate neurons by who number

  ;; set the neuron's events pattern, which indicates the event that matches the gate neuron
  ask item 0 gates [set events-pattern [[0 0]] ]          ;; lists of lists were chosen because indexing and concatenation will be used
  ask item 1 gates [set events-pattern [[0 1]] ]
  ask item 2 gates [set events-pattern [[1 0]] ]
  ask item 3 gates [set events-pattern [[1 1]] ]

  ;; assign an uplink from each of the four possible current-event keys to the appropriate neuron
  set match-event table:make
  table:put match-event [0 0] item 0 gates                ;; hash tables were used because of quick access
  table:put match-event [0 1] item 1 gates
  table:put match-event [1 0] item 2 gates
  table:put match-event [1 1] item 3 gates

  ;; assign a downlink from each of the four gate keys to the appropriate decision buffer
  set decision-buffer table:make
  table:put decision-buffer [0 0] 0                       ;; hash tables wer used because of quick access
  table:put decision-buffer [0 1] 0
  table:put decision-buffer [1 0] 0
  table:put decision-buffer [1 1] 0
end

;; procedure for energy accounting

to receive-expend-energy

  ;; receive energy
  if not empty? current-event [         ;; current event will not be set if player did not play last round
    set score get-element current-event energy-matrix    ;; get score from energy matrix
    set adjusted-score score * ( 1 - resource-competition / 100 * (count neighbors with [alive?]) / 8 )  ;; adjust score according to resource-competition function
    set energy energy + adjusted-score                   ;; add energy to existing energy
    tell self (word "I got " score " units of energy, and now have " energy " units of energy")  ;; print to command center
  ]

  ;; expend energy
  let loss energy-cost-per-person + energy-cost-per-neuron * (count neurons-here)         ;; determine energy loss
  set energy energy - loss                                                                   ;; subtract loss
  tell self (word "I lost " loss " units of energy, and now have " energy " units of energy")    ;; print to command center

  ;; die if below threshold
  if energy < people-death-threshold [
    kill-self
  ]

end

;; procedure that kills the agents that are lower than best-competition level

to death-race
  let race-order sort-by [ [?1 ?2] -> [energy] of ?1 < [energy] of ?2 ] patches with [alive?]
  let n count patches with [alive?]
  let threshold n * best-competition / 100
  let diers sublist race-order 0 threshold
  foreach diers [ ?1 -> ask ?1 [kill-self] ]
end

;; procedure that cleanly kills an agent resetting variables and cleaning up space

to kill-self
   if partner != nobody [
      ask partner [
        reset-living-player                 ;; reset the partner of dead agent
      ]
    ]
    set alive? false                        ;; dump the values of dead agent to save space
    set partner  nobody
    set match-event []
    set current-event []
    set decision-buffer []
    set emotion-matrix []
    ask neurons-here [die]
    tell self "I died"
end

;; procedure to reset player info, particularly after partner is lost

to reset-living-player
  set partner nobody
  set counter 20
  set current-event []
  set my-move []
  ask neurons-here [set buffer []]
end

;; procedure to reproduce a somewhat similar copy, genetic variables are similar

to reproduce
  if energy > people-birth-threshold and energy > people-birth-energy [  ;; make sure agents don't die in childbirth
    let embryo one-of neighbors with [alive? = false]                    ;; get a potential new nest patch
    if embryo != nobody [
      set energy energy - people-birth-energy
      tell self (word "I gave birth. Lost " people-birth-energy " units of energy, and now have  " energy " units of energy")
      ask embryo [                                                       ;; tell new patch to initialize all its variables
        initialize-people                                                ;; initialize people variables
        ;; get parent's random variables

        set emotion-matrix [emotion-matrix] of myself
        set reward-punishment-multiplier [reward-punishment-multiplier] of myself
        set forgetfulness [forgetfulness] of myself

        mutate-random-variables                              ;; set genetic variables to be similar but slightly different
        initialize-neurons          ;; set up the initial set of four events (or gate) neurons, can be negative or positvie
        tell self (word "I was reborn with this emotion-matrix, " emotion-matrix ",")
        tell self (word "this reward-punishment-multiplier, " reward-punishment-multiplier ",")
        tell self (word "and this forgetfulness multiplier, " forgetfulness)
      ]
      tell embryo (word "My parent had this emotion-matrix, " emotion-matrix ",")
      tell embryo (word "this reward-punishment-multiplier, "  reward-punishment-multiplier ",")
      tell embryo (word "and this forgetfulness multiplier, " forgetfulness)
    ]
  ]
end

;; procedure takes the genetic variables and adjusts them according to the relative-genetic-variation parameter

to mutate-random-variables ;; insert random variables from a normal distribution

  ;; mutate the emotion matrix
  let r0c0 get-element [0 0] emotion-matrix
  let r0c1 get-element [0 1] emotion-matrix
  let r1c0 get-element [1 0] emotion-matrix
  let r1c1 get-element [1 1] emotion-matrix
  let ave mean (list r0c0 r0c1 r1c0 r1c1)   ;; use mean of elements in emotion-matrix so that a zero element can have relative variation
  set r0c0 r0c0 + random-normal 0 (ave * relative-genetic-variation / 100)   ;; random-normal <mean> <standard-deviation>
  set r0c1 r0c1 + random-normal 0 (ave * relative-genetic-variation / 100)
  set r1c0 r1c0 + random-normal 0 (ave * relative-genetic-variation / 100)
  set r1c1 r1c1 + random-normal 0 (ave * relative-genetic-variation / 100)
  set emotion-matrix list (list r0c0 r0c1) (list r1c0 r1c1)

  ;; mutate the reward punishment multiplier
;  let change random-normal 0 (reward-punishment-multiplier * relative-genetic-variation / 100)
;  set reward-punishment-multiplier reward-punishment-multiplier + change

  ;; mutate the forgetfulness multiplier
;  let max-forgetfulness 1
;  let min-forgetfulness 1 / 2000
;  set change random-normal 0 (forgetfulness * relative-genetic-variation / 100)
;  set forgetfulness forgetfulness + change
;  while [forgetfulness >= max-forgetfulness or forgetfulness < min-forgetfulness] [
;    set change random-normal 0 (forgetfulness * relative-genetic-variation / 100)
;    set forgetfulness forgetfulness + change
;  ]

end

;; procedure sets color of neurons according to the outcome of their last game

to color-neurons
  ask neurons-here [
    set score get-element current-event energy-matrix
    if score = 5 [
      set color violet         ;; represents (D,C)
    ]
    if score = 3 [
      set color blue           ;; represents (C,C)
    ]
    if score = 1 [
      set color sky            ;; represents (D,D)
    ]
    if score = 0 [
      set color cyan           ;; represents (C,D)
    ]
  ]
end

;; procedure draws the patches and the plots every tick

to draw

  ;; draw the people using patch characteristics
  ask patches [
    ifelse alive? [
      set pcolor blue
      if partner != nobody [
        set pcolor yellow
      ]
    ][
    set pcolor black
    ]
  ]

  ;; draw protagonist of story a different color so it stands out
  if protagonist != nobody and tell-story? [
    ask protagonist [
      ask neurons-here [set color orange]
    ]
  ]

  ;; draw the total number of people in the simulation
  set-current-plot "Number of People"
  set-current-plot-pen "people"
  plot count patches with [alive?]

  ;; draw the average score of all the players
  set-current-plot "Average Score"
  set-current-plot-pen "score"
  if any? patches with [alive?] [
  plot mean [adjusted-score] of patches with [alive?]
  ]

  ;; draw the energy distribution histogram
  set-current-plot "Energy Distribution"
  set-current-plot-pen "energy-distribution"
  if any? patches with [alive?] [
    let alive-energy [energy] of patches with [alive?]
    set-histogram-num-bars 100
    histogram alive-energy
    set-plot-x-range 0 (plot-x-max + 1)
    ;set-plot-y-range 0 (plot-y-max + 1)
  ]

end

;; procedure that tell the story of only one patch if tell-story? is set to true

to tell [me str]         ;; prints to command center if appropriate patch and string are entered as inputs
  if tell-story? = true [
    if me = protagonist [
      type protagonist type " says " type str type " on tick " print ticks
    ]
  ]
end

;; procedure reports the element of list matrix that results given the current event

to-report get-element [event mat]
  let r item 0 event
  let c item 1 event
  report item c (item r mat)
end
@#$#@#$#@
GRAPHICS-WINDOW
8
10
477
480
-1
-1
9.04
1
10
1
1
1
0
1
1
1
0
50
0
50
0
0
1
ticks
30.0

BUTTON
495
10
560
43
NIL
Setup
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
495
90
745
123
num-of-initial-people
num-of-initial-people
10
2500
2000.0
10
1
people
HORIZONTAL

SLIDER
495
170
745
203
energy-cost-per-neuron
energy-cost-per-neuron
0
1
0.0
0.01
1
energy
HORIZONTAL

SLIDER
495
205
720
238
people-birth-energy
people-birth-energy
1
100
12.0
1
1
energy
HORIZONTAL

PLOT
220
510
420
660
Number of People
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
"default" 1.0 0 -16777216 true "" ""
"people" 1.0 0 -13345367 true "" ""

BUTTON
495
50
560
83
NIL
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

SLIDER
495
130
745
163
energy-cost-per-person
energy-cost-per-person
0
5
0.6
0.05
1
energy
HORIZONTAL

SLIDER
495
240
720
273
people-birth-threshold
people-birth-threshold
people-birth-energy
100
36.0
1
1
energy
HORIZONTAL

SLIDER
495
275
720
308
relative-genetic-variation
relative-genetic-variation
0
100
50.0
1
1
%
HORIZONTAL

SLIDER
495
310
720
343
max-brain-size
max-brain-size
4
400
4.0
4
1
neurons
HORIZONTAL

SWITCH
755
50
860
83
tell-story?
tell-story?
1
1
-1000

PLOT
430
510
630
660
Average Score
NIL
NIL
0.0
10.0
0.0
5.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"score" 1.0 0 -16777216 true "" ""

SLIDER
570
50
745
83
resource-competition
resource-competition
0
100
0.0
1
1
%
HORIZONTAL

MONITOR
495
455
630
508
Average Score
mean [adjusted-score] of patches with [alive? and partner != nobody]
2
1
13

MONITOR
495
400
630
453
Reward Multiplier
mean [reward-punishment-multiplier] of patches with [alive?]
2
1
13

MONITOR
670
380
735
433
ave (D,D)
mean map [ ?1 -> get-element  (list 0 0) ?1 ] ([emotion-matrix] of patches with [alive?])
1
1
13

MONITOR
740
380
805
433
ave (D,C)
mean map [ ?1 -> get-element  (list 0 1) ?1 ] ([emotion-matrix] of patches with [alive?])
1
1
13

MONITOR
670
435
735
488
ave (C,D)
mean map [ ?1 -> get-element  (list 1 0) ?1 ] ([emotion-matrix] of patches with [alive?])
1
1
13

MONITOR
740
435
805
488
ave (C,C)
mean map [ ?1 -> get-element  (list 1 1) ?1 ] ([emotion-matrix] of patches with [alive?])
1
1
13

MONITOR
670
530
736
583
% (D,D)
count patches with [score = 1 and alive? and partner != nobody] / count patches with [alive? and partner != nobody]
3
1
13

MONITOR
740
530
806
583
% (D,C)
count patches with [score = 5 and alive? and partner != nobody] / count patches with [alive? and partner != nobody]
3
1
13

MONITOR
670
586
736
639
% (C,D)
count patches with [score = 0 and alive? and partner != nobody] / count patches with [alive? and partner != nobody]
3
1
13

MONITOR
740
586
806
639
% (C,C)
count patches with [score = 3 and alive? and partner != nobody] / count patches with [alive? and partner != nobody]
3
1
13

TEXTBOX
760
90
910
181
Magenta is new born\nViolet is (D,C)\nBlue is (C,C)\nSky is (D,D)\nCyan is (C,D)\nOrange is protagonist\nBlack is dead\n
10
0.0
1

SLIDER
570
10
745
43
best-competition
best-competition
0
5
2.0
0.05
1
%
HORIZONTAL

BUTTON
755
10
860
43
new protagonist
new-protagonist
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
10
510
210
660
Energy Distribution
energy
NIL
0.0
10.0
0.0
50.0
false
false
"" ""
PENS
"default" 1.0 1 -10899396 true "" ""
"energy-distribution" 1.0 1 -13345367 true "" ""

INPUTBOX
756
218
806
278
emo-DD
1.0
1
0
Number

INPUTBOX
811
218
861
278
emo-DC
5.0
1
0
Number

INPUTBOX
756
283
806
343
emo-CD
0.0
1
0
Number

INPUTBOX
811
283
861
343
emo-CC
3.0
1
0
Number

TEXTBOX
757
205
907
223
Initial Emotion Matrix
11
0.0
1

SLIDER
495
345
667
378
forgetfulness
forgetfulness
1 / 100
99 / 100
0.25
1 / 100
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model is an evolutionary iterated spatial prisoner's dilemma.
Agents can evolve emotional responses to events. They memorize something
akin to the relative frequency or moving weighted average of their emotional
responses to an event, but cannot yet determine temporal patterns or sequences of events.

## HOW IT WORKS

Agents are awarded energy according to the payoff matrix of the typical spatial
prisoners' dilemma problem: 0 if you cooperate when your partner defects,
1 if you both defect, 3 if you both cooperate, and 5 if you defect while your
partner cooperates.  Agents play the prisoners' dilemma game with their Moore
neighbors.  If their energy rises above a user defined threshold it will reproduce.
All the living patches have round dots on them.  They are colored differently
based on the four different possible outcomes of their last game.  Magenta colored
circles represent newborns.  Black patches are dead. Yellow patches have a partner and are playing the game.  Blue patches have no partner but are alive.

## HOW TO USE IT

All of the sliders set endemic variables that relate the the agents' environment
or condition that cannot be changed by adaptation.  The setup button initializes
the model.  The go button runs the model.  There is also a toggle switch that
allows the user to follow the life of a randomly selected patch.  The protagonist
of the followed patch has a bright orange dot on it if it is alive.

## THINGS TO NOTICE

Notice that if you increase competition the average score of the agents decreases from the optimal.  Notice also that mutual cooperation is the dominant strategy, unlike
most other examples of the prisoners dilemma problem.

## THINGS TO TRY

Try getting the reporters on the bottom of the interface to move by changing the
conditions of the experiment.  Can you get the agents to adapt to a situation that they were unprepared for in the beginning of the experiment?

## EXTENDING THE MODEL

This model will eventually contain agents that can learn temporal patterns of events
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
  <experiment name="Habitable Zone" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <exitCondition>not any? patches with [alive?]</exitCondition>
    <metric>count patches with [alive?]</metric>
    <metric>mean [energy] of patches with [alive?]</metric>
    <metric>mean [score] of patches with [alive?]</metric>
    <metric>ticks</metric>
    <metric>mean map [ ?1 -&gt; get-element  (list 0 0) ?1 ] ([emotion-matrix] of patches with [alive?])</metric>
    <metric>mean map [ ?1 -&gt; get-element  (list 0 1) ?1 ] ([emotion-matrix] of patches with [alive?])</metric>
    <metric>mean map [ ?1 -&gt; get-element  (list 1 0) ?1 ] ([emotion-matrix] of patches with [alive?])</metric>
    <metric>mean map [ ?1 -&gt; get-element  (list 1 1) ?1 ] ([emotion-matrix] of patches with [alive?])</metric>
    <enumeratedValueSet variable="emo-DC">
      <value value="2.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-brain-size">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="people-birth-threshold">
      <value value="36"/>
    </enumeratedValueSet>
    <steppedValueSet variable="best-competition" first="0" step="1" last="5"/>
    <enumeratedValueSet variable="emo-DD">
      <value value="-2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emo-CC">
      <value value="3.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="energy-cost-per-neuron">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tell-story?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="forgetfulness">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emo-CD">
      <value value="-0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="people-birth-energy">
      <value value="12"/>
    </enumeratedValueSet>
    <steppedValueSet variable="energy-cost-per-person" first="0" step="0.6" last="3"/>
    <enumeratedValueSet variable="num-of-initial-people">
      <value value="2000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="resource-competition" first="0" step="5" last="25"/>
    <enumeratedValueSet variable="relative-genetic-variation">
      <value value="50"/>
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
