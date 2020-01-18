;; GLOBALS
breed [tribal-elders tribal-elder]
breed [tribal-members tribal-member]
breed [local-jihadists local-jihadist]
breed [int-jihadists int-jihadist]
breed [aircrafts aircraft]
globals [casualties memory-list previous-pol-motive  target-list effect a b y z]

turtles-own [
  clan ;; five separate clans that make up the tribe
  religious-motive ;; not religiosity per se but the quantification of their religious motivation to affiliate with the overall organization
  political-motive
  predisp-political
  predisp-religious
  home-patch
  ]

aircrafts-own [
  bombs]
patches-own [
  pclan
  residents]

to go
  ask turtles [
    if breed = int-jihadists [ ;; simulate the flow of int'l jihadists from an initial movement into the area, then to behavior that is similar to locals.
      ifelse ticks <= 6 [set heading (90 + random 90)]
      [right random 360 ask local-jihadists [set color black]]
      forward random 11]
    if breed = aircrafts [
      forward 5]
    if breed != int-jihadists and breed != aircrafts [
      right random 360
      forward random 6]]


  population-adjustment
  event-generator
  update-motives
  tick
end

to setup
  clear-all
  setup-tribe
  setup-jihadists
  setup-patches
  setup-predisp
  set target-list []
  set memory-list []
  set previous-pol-motive (median [political-motive] of turtles with [breed != aircrafts]) ;; used to calculate change in median political-motive determine momentum in event-generator below
  reset-ticks

end


to setup-tribe ;; creates tribal element of broader organization
  create-tribal-elders 1 [set color red - 1 set clan 1 set size 1.5]
  create-tribal-members 199 [set color red set clan 1 ]
  create-tribal-elders 1 [set color red - 1 set clan 2 set size 1.5]
  create-tribal-members 149 [set color red set clan 2]
  create-tribal-elders 1 [set color red - 1 set clan 3 set size 1.5]
  create-tribal-members 124 [set color red - 1 set clan 3]
  create-tribal-elders 1 [set color red - 1 set clan 4 set size 1.5]
  create-tribal-members 124 [set color red set clan 4]
  create-tribal-elders 1 [set color red - 1 set clan 5 set size 1.5]
  create-tribal-members 99 [set color red set clan 5]
  ask turtles [
    set shape "person"
    if clan = 1 [move-to patch random -40 random 22]
    if clan = 2 [move-to patch random 40 random -22]
    if clan = 3 [move-to patch random -40 random -22]
    if clan = 4 [move-to patch random 40 random 22]
    if clan = 5 [move-to patch (random 40 - random 40) (random 22 - random 22)]
  ]

  ask tribal-members [
    let x clan
    set religious-motive random-normal tribal-religion-slider 15
    set political-motive random-normal tribal-political-slider 15
    if religious-motive > 100 [set religious-motive 100] ;; the max anyone can have at the begining is 100
    if political-motive > 100 [set political-motive 100] ;;
    set home-patch patch-here]
  ask tribal-elders [
    set religious-motive random-normal tribal-religion-slider 3
    set political-motive random-normal tribal-political-slider 3
    if political-motive > 100 [set political-motive 100]
    if religious-motive > 100 [set religious-motive 100]
    set home-patch patch-here]

end

to setup-jihadists
  create-local-jihadists 65
  create-int-jihadists 65
  ask local-jihadists [
    set shape "person"
    set color green
    setxy random-xcor random-ycor
    set religious-motive (100 - random 5)
    set political-motive (100 - random 5) ;; while relig and political motives are closely related in jihadi ideology, locals may have a slightly more nuanced perspective.  Set independenatly but within same range.
    set home-patch patch-here]
  ask int-jihadists [
    set shape "person"
    set color black
    set xcor -40 set ycor 22
    set religious-motive (100 - random 5)
    set political-motive religious-motive ;; jihadi ideology is as political as it is religious, esp for those who travel abroad.  Initial values set equal.
  ]
end

to setup-patches
  ask patches [set pcolor white - 1 set residents (2 * count turtles-here with [clan > 0])]
  ask tribal-members [ ;; only tribals set patches attributes because they are tied more directly to geogrpahy and kinship.  Jihadists, as extremists, less often share views of general population
    set pclan clan
    set pclan clan]
  ask tribal-elders [
     set pclan clan
    set pclan clan]
end

to setup-predisp
  ask local-jihadists [
    set predisp-political (((political-motive - mean [political-motive] of turtles) / mean [political-motive] of turtles) + 1) ;; set affinities at setup so that they remian constant.  This represents the basal affinity an individual has,
    set predisp-religious (((religious-motive - mean [religious-motive] of turtles) / mean [religious-motive] of turtles) + 1)
  ]
  ask int-jihadists [
    set predisp-political (((political-motive - mean [political-motive] of turtles) / mean [political-motive] of turtles) + 1) ;; set affinities at setup so that they remian constant.  This represents the basal affinity an individual has,
    set predisp-religious (((religious-motive - mean [religious-motive] of turtles) / mean [religious-motive] of turtles) + 1)
  ]
  ask tribal-members [
    set predisp-political (((political-motive - mean [political-motive] of turtles) / mean [political-motive] of turtles) + 1) ;; set affinities at setup so that they remian constant.  This represents the basal affinity an individual has,
    set predisp-religious (((religious-motive - mean [religious-motive] of turtles) / mean [religious-motive] of turtles) + 1) ;; and will be used to calculate how later events affect an individual's perception of said event.
  ]
  ask tribal-elders [
    set predisp-political (((political-motive - mean [political-motive] of turtles) / mean [political-motive] of turtles) + 1)
    set predisp-religious (((religious-motive - mean [religious-motive] of turtles) / mean [religious-motive] of turtles) + 1)
  ]
end

to event-generator ;; simulate an event that has effect on all turtles.
  if event-generator? [
    let trend 0
    let event random 20 ;; randomly selects one of the events below at a rate commensurate with the number of possibilities
    if ticks <= 60 [
      set a 2
      set b 3 ;; this and the following lines simulates a learning coalition. The possibliliy of the coalition offsetting terrorist benefit increases with time.
      set y -2
      set z 2]
    if ticks > 60 and ticks <= 90[
      set a 3
      set b 4
      set y -2
      set z 1]
    if ticks > 90 and ticks <= 180[
      set a 4
      set b 4
      set y -3
      set z 2]
    if ticks > 180 and ticks <= 210[ ;; Effect peaks positive.  June when ISIS overruns Mosul etc. U.S. intervention begins
      set a 5
      set b 4
      set y -4
      set z 3]
    if ticks > 210 and ticks <= 270[ ;; Maliki steps down. U.S. assistance and intervention kicks in.  Reclaims Mosul dam etc.
      set a 5
      set b 3
      set y 3
      set z 5]
    if ticks > 270 and ticks <= 330[
      set a 6
      set b 6
      set y 4
      set z 6]
    if ticks > 330 and ticks <= 365 [
      set a 6
      set b 7
      set y 8
      set z 10]
    if ticks = 365 [
      set previous-pol-motive (median [political-motive] of turtles with [breed != aircrafts])]
    if ticks > 365 [
      set memory-list fput ((median [political-motive] of turtles with [breed != aircrafts]) - previous-pol-motive) memory-list
      set previous-pol-motive (median [political-motive] of turtles with [breed != aircrafts]) ;; updates previous previosu-pol-motive for use in eth next iteration before the median political-motive is updated in this tick.
      set trend (length (filter [ ?1 -> ?1 > 0 ] memory-list)) ;; determines the frequency of positive effects in a memory of seven events
      if length memory-list > 7[
        set memory-list remove-item 7 memory-list]
      if length memory-list >= 7 and (event = 1 or event = 2)[ ;; assess and change tactics every 10 days on average
        if sum memory-list > 0 and trend >= 4 [;; if total effect over seven events favors terrorists, their range of effectiveness increases and std dev decreases (narrower std dev within higher range) and opposite for coalition.  Vice versa..
          set a a + 0.5
          ifelse b >= 0.26
          [set b b - 0.25]
          [set a a + 0.5 set b 1]
          set y y - 0.5
          set z z + 0.5
]]
      if length memory-list >= 7 and (event = 3 )[ ;; coalition calibrates approach at a slower rate than people on the ground.
        if sum memory-list < 0 and (7 - trend) >= 4[
          set a a - 0.25
          set b b + 0.25
          set y y + 0.25
          ifelse z >= 0.26
            [set z z - 0.25]
            [set y y + 0.25 set z 1]]
      ]
    ]
    set effect (random-normal a b - random-normal y z) ;;The effect is the difference between two randomly generated numbers.  The random on the left in this case is the terrorist org and the left the coalition.

    ask turtles [
      if breed = int-jihadists
        [set religious-motive religious-motive + (predisp-religious * effect)
          set political-motive religious-motive]
      if breed != int-jihadists and breed != aircrafts [
        ifelse predisp-religious < 0 and effect < 0
          [set religious-motive religious-motive + ((abs predisp-religious) * effect)] ;; ensure that a turtle with negative perception of effect does not update in an opposite direction than is logical
          [set religious-motive religious-motive + (predisp-religious * effect)]
        ifelse predisp-political < 0 and effect < 0
          [set political-motive political-motive + ((abs predisp-political) * effect)]
          [set political-motive political-motive + (predisp-political * effect)] ;; each individual will multiply the effect by their affinity numbers, ensuring that each turtle views it differently.
      ]
    ]
    if airstrikes [
      ask patches [set pcolor white - 1]
      if (event = 1) and ticks > 240 [
        create-aircrafts 1 [
          set shape "airplane"
          set size 3
          set color black + 3
          set bombs 2 ;; allows two attacks per plane per sortie
          set xcor random-xcor
          set ycor -20
          set heading 0
        ]]
      ask aircrafts [
        if abs ycor > 19 and bombs = 0 [die]
        if abs xcor > 39 and bombs = 0 [die]
        if (abs ycor > 19 or abs xcor > 39) and bombs < 2 [die]
        if religious-max[
          if ([who] of one-of turtles with [breed != aircrafts] with [religious-motive = max [religious-motive] of turtles]) != nobody [
            carefully [set target-list fput [who] of one-of turtles with [breed != aircrafts] with [religious-motive = max [religious-motive] of turtles] target-list]
            [set religious-max false print "NO RELIGIOUS MAX TARGETING!!!"]]]
        if political-max[
          if ([who] of one-of turtles with [breed != aircrafts] with [political-motive = max [political-motive] of turtles]) != nobody [
            carefully [set target-list fput [who] of one-of turtles with [breed != aircrafts] with [political-motive = max [political-motive] of turtles] target-list]
            [set political-max false print "NO POLITICAL MAX TARGETING!!!"]]]
        if jihadists[
          set target-list fput [who] of one-of turtles with [color = black] target-list
          if count turtles with [color = black] = 0 [stop]]
        set target-list remove-duplicates target-list
        if bombs > 0 and length target-list > 0[
          let target one-of target-list
          set target-list remove target target-list
          ifelse turtle target != nobody
          [move-to turtle target]
          [set target one-of target-list
            move-to turtle target
            set target-list remove target target-list]
          ask turtle target [
            set pcolor red
            ask patches in-radius 2 [set pcolor red + 1]
            ask turtles-here with [breed != aircrafts][set casualties casualties + 1 die] ;; non-aircraft die
            ask turtles in-radius 2 [
              if breed != aircrafts [
                let death-rate random 2
                if death-rate = 1 [set casualties casualties + 1 die]]
              set political-motive political-motive + ((political-motive / 100) * 2)] ;; 50 percent of dying if within radius of attack.
            die]
          set bombs bombs - 1]];; aircraft expend bomb
      ask patches [
        if pcolor = red + 1 or pcolor = red [
          let death-rate (residents * .5)
          set residents residents - (round death-rate) ;; 5% change of resident population on affected patches simulates "collateral damage
          set casualties casualties + (round death-rate)
          ask turtles with [home-patch = patch-here][
            set political-motive political-motive + ((political-motive / 100) * death-rate)]
          ask neighbors [
            ask turtles with [home-patch = patch-here][
              set political-motive political-motive + ((political-motive / 100) * death-rate)]]
        ]
      ]

    ]
  ]
end

to update-motives ;; create dynamic process by which members of population influence the motivation of each other.
  ask tribal-members [ ;; Simulates "balanced opposition."
    let x clan
    set political-motive (((10 * political-motive) + (5 * mean [political-motive] of tribal-members with [clan = x]) + (2 * mean [political-motive] of tribal-elders with [clan = x]) + (mean [political-motive] of turtles in-radius 2 with [breed != aircrafts] )) / 18) ;; tribal members are influenced by each other.
    set religious-motive (((10 * religious-motive) + (5 * mean [religious-motive] of tribal-members with [clan = x]) + (2 * mean [religious-motive] of tribal-elders with [clan = x]) + (mean [religious-motive] of turtles in-radius 2 with [breed != aircrafts])) / 18)] ;; tribal members are influenced by each other.
  ask tribal-elders [  ;;elder's own political motivation is responsive to that of the member community.  Weighted edler's own motivation by a 2 to 1 ratio when compared to both clan and peers.respectively.
    let x clan
    set political-motive (((10 * political-motive) + (5 * mean [political-motive] of tribal-members with [clan = x]) + (2 * mean [political-motive] of tribal-elders) + (mean [political-motive] of turtles in-radius 2 with [breed != aircrafts])) / 18)
    set religious-motive (((10 * religious-motive) + (5 * mean [religious-motive] of tribal-members with [clan = x]) + (2 * mean [religious-motive] of tribal-elders) + (mean [religious-motive] of turtles in-radius 2 with [breed != aircrafts])) / 18)]
  ask int-jihadists [
    set religious-motive (((10 * religious-motive) + (5 * mean [religious-motive] of int-jihadists) + (2 * mean [religious-motive] of local-jihadists)) / 17)
    set political-motive religious-motive]
  ask local-jihadists [
    set religious-motive (((10 * religious-motive) + (5 * mean [religious-motive] of local-jihadists) + (5 * mean [religious-motive] of int-jihadists) + (mean [religious-motive] of turtles in-radius 2 with [breed != aircrafts])) / 21)
    set political-motive  (((10 * political-motive) + (10 * religious-motive) + (5 * mean [political-motive] of local-jihadists) + (5 * mean [political-motive] of int-jihadists) + (mean [political-motive] of turtles in-radius 2 with [breed != aircrafts])) / 31)
  ]

end

to population-adjustment ;; update population according to birth rates, the flow of int'l jihadists, defection, recruitment, etc.
  if ticks > 0 and remainder ticks 15 = 0 [
    create-int-jihadists 4 [ ;; reports suggest ~1000 foreign fighters on behalf of ISIS each month.  8/month to Iraq
      set shape "person"
      set color black
      set xcor -40 set ycor 22 ;; coming in from the Iraq-Syria border in the northwest.
      set religious-motive median [religious-motive] of int-jihadists ;; set at median of breed so introduction doesn't skew population numbers.
      set political-motive religious-motive ;; those that travel abroad have less distinction between politics and religion
      let whox [who] of one-of int-jihadists ;; chooses existing int-jihadist at random so that new int-jihadist can mirror predispositions below.
      set predisp-political [predisp-political] of int-jihadist whox;; set predisposition to one of a fellow int-jihadist to assure it falls in range of breed.
      set predisp-religious [predisp-religious] of int-jihadist whox]];; Since this turtle is coming into the game late, other calculations skew population numbers
  if ticks > 0 and remainder ticks 17 = 0 [ ;;birth rates in Iraq in 2000 was roughly 35 per 1000 and 2014 death rate is ~ 5 per 1,000.  Assuming half are male, they are coming of fighting age.  ~8 tribal members for 365 ticks (year)
    ask one-of tribal-members [hatch 1]
    ask one-of patches with [residents > 0][set residents residents + 1]] ;; Current birth rates are 22/1000 which equals ~45 residents per year, or 2 bimonthly (1:125 ratio).  Subtract the resident that becomes tribal member agent = 1
  let elder-list [1 2 3 4 5]
  ask tribal-elders [set elder-list remove clan elder-list]
  if length elder-list > 0 [ ;; if elder dies, tribal members are listed according to those who meet the most of the criteria below (nearest political-motive mean and religious-motive mean) and one that meets most is selected as the new elder.
    let new-elder []
    ask tribal-members with [clan = one-of elder-list] [
      if political-motive <= ceiling mean [political-motive] of turtles with [clan = [clan] of self] [
        set new-elder fput who new-elder]
      if political-motive >= floor mean [political-motive] of turtles with [clan = [clan] of self][
        set new-elder fput who new-elder]
      if religious-motive <= ceiling mean [religious-motive] of turtles with [clan = [clan] of self][
        set new-elder fput who new-elder]
      if religious-motive >= floor mean [religious-motive] of turtles with [clan = [clan] of self][
        set new-elder fput who new-elder]]
    set new-elder sort new-elder
    ask turtle first new-elder [ set breed tribal-elders]]

end
@#$#@#$#@
GRAPHICS-WINDOW
395
10
1211
468
-1
-1
9.98
1
10
1
1
1
0
0
0
1
-40
40
-22
22
0
0
1
ticks
30.0

BUTTON
3
10
67
43
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
73
10
136
43
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
1643
10
2021
312
All Political Motive
Ticks (Days)
Political Motive
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Median" 1.0 0 -4079321 true "" "plot median [political-motive] of turtles with [breed != aircrafts]"
"Mean" 1.0 0 -13840069 true "" "plot mean [political-motive] of turtles with [breed != aircrafts]"
"Max" 1.0 0 -2674135 true "" "plot max [political-motive] of turtles with [breed != aircrafts]"
"Min" 1.0 0 -13345367 true "" "plot min [political-motive] of turtles with [breed != aircrafts]"

SLIDER
-2
89
170
122
tribal-religion-slider
tribal-religion-slider
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
-2
51
170
84
tribal-political-slider
tribal-political-slider
0
100
80.0
1
1
NIL
HORIZONTAL

PLOT
2024
10
2405
311
Tribal Political Motive
Ticks (Days)
Political Motive
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Median" 1.0 0 -4079321 true "" "plot median [political-motive] of tribal-members"
"Max" 1.0 0 -2674135 true "" "plot max [political-motive] of tribal-members"
"Min" 1.0 0 -13345367 true "" "plot min [political-motive] of tribal-members"
"Mean" 1.0 0 -13840069 true "" "plot mean [political-motive] of tribal-members"

PLOT
1216
10
1640
313
Jihadist Political Motive
Ticks (Days)
Political Motive
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Median" 1.0 0 -4079321 true "" "plot median [political-motive] of turtles with [color = black or color = green]"
"Max" 1.0 0 -2674135 true "" "plot max [political-motive] of turtles with [color = black or color = green]"
"Min" 1.0 0 -13345367 true "" "plot min [political-motive] of turtles with [color = black or color = green]"
"Mean" 1.0 0 -13840069 true "" "plot mean [political-motive] of turtles with [color = black or color = green]"

SWITCH
246
47
387
80
airstrikes
airstrikes
0
1
-1000

SWITCH
234
16
388
49
event-generator?
event-generator?
0
1
-1000

SWITCH
253
114
388
147
religious-max
religious-max
1
1
-1000

SWITCH
254
81
388
114
political-max
political-max
1
1
-1000

MONITOR
2
198
67
243
Total Pop
count turtles with [breed != aircrafts] + sum [residents] of patches
17
1
11

MONITOR
72
198
141
243
Jihadi Pop
count turtles with [breed = int-jihadists or breed = local-jihadists]
17
1
11

MONITOR
144
200
227
245
Tribe Agents
count turtles with [clan > 0]
17
1
11

MONITOR
214
200
312
245
Residents
sum [residents] of patches
17
1
11

MONITOR
316
200
386
245
Casualties
casualties
17
1
11

PLOT
2024
313
2405
582
Tribal Religious Motive
Ticks (Days)
Religious Motive
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Median" 1.0 0 -4079321 true "" "plot median [religious-motive] of tribal-members"
"Mean" 1.0 0 -13840069 true "" "plot mean [religious-motive] of tribal-members"
"Max" 1.0 0 -2674135 true "" "plot max [religious-motive] of tribal-members"
"Min" 1.0 0 -13345367 true "" "plot min [religious-motive] of tribal-members"

PLOT
1643
314
2022
583
All Religious Motive
Ticks (Days)
Religious Motive
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Median" 1.0 0 -4079321 true "" "plot median [religious-motive] of turtles with [breed != aircrafts]"
"Mean" 1.0 0 -13840069 true "" "plot mean [religious-motive] of turtles with [breed != aircrafts]"
"Max" 1.0 0 -2674135 true "" "plot max [religious-motive] of turtles with [breed != aircrafts]"
"Min" 1.0 0 -13345367 true "" "plot min [religious-motive] of turtles with [breed != aircrafts]"

PLOT
1222
316
1640
583
Jihadist Religious Motive
Ticks (Days)
Religious Motive
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Median" 1.0 0 -4079321 true "" "plot median [religious-motive] of turtles with [color = black or color = green]"
"Mean" 1.0 0 -13840069 true "" "plot mean [religious-motive] of turtles with [color = black or color = green]"
"Max" 1.0 0 -2674135 true "" "plot max [religious-motive] of turtles with [color = black or color = green]"
"Min" 1.0 0 -13345367 true "" "plot min [religious-motive] of turtles with [color = black or color = green]"

MONITOR
184
242
249
287
Tribe Pop
(count turtles with [clan > 0] + sum [residents] of patches)
17
1
11

PLOT
20
306
370
572
Clans' Median Political Motive
Ticks (Days)
Motive
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Clan 1" 10.0 0 -2674135 true "" "plot median [political-motive] of turtles with [clan = 1]"
"Clan 2" 10.0 0 -13840069 true "" "plot median [political-motive] of turtles with [clan = 2]"
"Clan 3" 10.0 0 -13345367 true "" "plot median [political-motive] of turtles with [clan = 3]"
"Clan 4" 10.0 0 -16777216 true "" "plot median [political-motive] of turtles with [clan = 4]"
"Clan 5" 10.0 0 -5825686 true "" "plot median [political-motive] of turtles with [clan = 5]"

SWITCH
253
148
388
181
Jihadists
Jihadists
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

Can U.S.-led airstrikes degrade the Islamic State’s standing with supportive tribes in the Anbar province?  This model focuses on politically sympathetic tribes in Iraq's Anbar province.  It seeks to simulate the events of December 2013 to December 2014 and beyond in order to assess the effectiveness of airtsrikes.



## HOW IT WORKS

Agents have the following attributes:

Clan:  Five of various population sizes; blank for jihadists

Home Patch: Agent’s initial position at setup where family/kin reside

Religious and Political Predisposition:  Static numeric value that represents the importance of a motive to the individual 

Religious and Political Motives:  Dynamic numeric value that determines individual’s support of ISIS.  No inherent meaning to the value; relative to other agents

All breeds have religious and political predispositions: The filter or lens through which they experience the world.  Enables all agents to be affected by the same event in different ways. Abstraction of histories, social circles, priorities, etc.

Event effects are run through each agent's predispositions and then their motivations are updated according to weights applied.

Airstrikes can start at tick 240, at which point a target list is maintained by aircraft based on the targeting parameters selected on the interface.

As airstrikes occur, collateral damage and death of those around each agent has an impact on the agents.  Also, the removal of individuals from the simulation changes the overall dynamic of aggregate motivations.

If a tribal leader is killed, he is replaced with the agent within the same clan with the motivations most similar to the clan medians (both religious and political). 

## HOW TO USE IT

Set the religious and political motives for the tribe using the sliders on the interface. For the tribe, these will be set for agents along a normal distribution with a standard deviation of 15.  

Turn on "event generator" so that actions are simulated and an impact on the population occurs.  Airstrikes will not work if both airstrikes and event generator are turned off.

Choose whether you'd like to simulate airstrikes.  If so, switch tem on (be sure to switch the Event Generator on, as well).  THen choose the target set(s) you wish to pursue using the remaining switches.

## THINGS TO NOTICE

There appears to be a correlation between the number of casualties and the level of support ISIS received from the tribe.

## THINGS TO TRY

Try reversing the motivations by making the tribe more religiously motivated than political, and set the targets to focus on religious agents. 

Change the code to broaden the standard deviation of tribal member motives.  Determine if looser social norms have any impact on how the tribe is motivated to support or reject the Islamic State.

## EXTENDING THE MODEL

This model is highly stochastic due to its reliance on random number generators in many of its procedures.  This is likely due to the stochasticity built in to the Event Generator.  As time moves on and data becomes available, more work should be done to calibrate the effects code with actual events.  

One can start building other elements of the environment, such as economic motives, and minimize the dominance of the obscure Event Generator.

Change agent movement to simulate actual battle and town seizure so that airstrikes have more defined and clearer target sets.

After a certain number of ticks, aircraft run out of targets.  Targeting must be calibrated to ensure more consistent and realistic implementation.
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
  <experiment name="No Airstrikes 240" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="240"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 365" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 450" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="450"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 550" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 650" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="650"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 730" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="730"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 800" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="800"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 900" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="900"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 1000 Full" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 240" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="240"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 365" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 450" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="450"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 550" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="550"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 730" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="730"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 1000 Political Sweepl" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="tribal-political-slider" first="0" step="20" last="100"/>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="No Airstrikes 1000 Full" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="tribal-religion-slider" first="0" step="25" last="100"/>
    <enumeratedValueSet variable="airstrikes">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 800" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="800"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 900" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="900"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Jihadist Airstrikes 1000" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="Jihadists">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Pol Max Airstrikes 1000  80 20" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>mean [political-motive] of turtles with [color = red]</metric>
    <metric>mean [religious-motive] of turtles with [color = red]</metric>
    <metric>median [political-motive] of turtles with [color = red]</metric>
    <metric>median [religious-motive] of turtles with [color = red]</metric>
    <metric>count turtles</metric>
    <metric>casualties</metric>
    <enumeratedValueSet variable="&gt;-religious-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="&gt;-political-median">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Jihadists">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="religious-max">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-political-slider">
      <value value="80"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tribal-religion-slider">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="airstrikes">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="political-max">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="event-generator?">
      <value value="true"/>
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
