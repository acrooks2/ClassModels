globals
[
  infobitcount          ;; count of infobits currently being generated per tick on the network
  badinfobitcount
  infobitsfiltered      ;; count of infobits filtered
  badinfobitsfiltered
  totalinfobits         ;; count of total infobit over the course of the model run
  totalbadinfobits
  addlusers             ;; count of additional users to be added to the network
]

breed [users user]              ;; these are generic users using social media
breed [hubs hub]                ;; these are information hubs that contain user-generated information
breed [infobits infobit]        ;; these are the packets of good information ready for user consumption
breed [badinfobits badinfobit]  ;; these are packets of bad information that can deceive a user

infobits-own [location]         ;; infobits reside at a user or a hub
badinfobits-own [location]      ;; bad infobits also reside at a user or a hub

hubs-own [ hubcount ]           ;; count pieces of data sent transferred per hub

users-own
[
  deceived?          ;; user status: whether or not users are deceived after using bad data
  usercount          ;; count of pieces of data used per user
  deceived-length    ;; how many ticks user has been deceived
  recovery-length    ;; how long it takes before user recovers
  memoryretention    ;; deceived users retain information (education) as to not be deceived again.
  memorystrength     ;; Uses Ubbinghaus Forgetting Curve where memoryretention = e^(-time/memorystrength)
  consumptioncount   ;; a count of how many infobits the user has consumed per tick. Used to set a consumer limit
  ticker             ;; a count of how many ticks have gone by without the user being deceived
  connected?         ;; a state of whether or not user is connected to a hub.
]


;; The following procedure resets this model and sets up an initial network.
to setup
  clear-all
  reset-ticks
  setupnetwork
end


;; The following procedure sets up the initial network according to the selected variables.
to setupnetwork
  set-default-shape users "circle"
  set-default-shape hubs "square"

  set infobitcount Number-of-Infobits                 ;; this initializes the count for infobits
  set badinfobitcount Number-of-BadInfobits

  create-hubs Number-of-Hubs [ set color red ]        ;; set up number of hubs

  if Number-of-Hubs > 1                               ;; allows for a one hub model to be created.
  [
    ask hubs [ create-link-with one-of other hubs ]   ;; create network of hubs
  ]

  create-users Number-of-Users [ set color blue ]     ;; set up number of users

  ask users
  [
    create-link-with one-of other hubs                ;; create network of users attached to hubs

    set connected? true

    ;; following block sets user parameters for the initial setup
    set deceived-length 0
    set ticker 0
    set recovery-length random-float Max-user-recovery-time
    set memorystrength random-float Max-initial-memory-strength
  ]

  repeat 200 [ layout ]  ;; this lays out the network so users and hubs are not overlapping

  ask users ;; this following bit of code prevents any user to share a same patch with a hub.
            ;; This is due to how infobits "die" at the user when consumed, and is very common
            ;; where there are multiple hubs with a lot of users on the screen
  [
    while [any? other hubs-here]
    [
      die
      hatch 1
      create-link-with one-of other hubs
      set connected? true
    ]
  ]

end


;; This procedure creates additional new users on the network after the network has been set up
to addl-user-creation

  set addlusers (addlusers + addl-users-per-tick)

  create-users Addl-users-per-tick [
    set connected? false
    set color blue ] ;; set up number of new users

  ask users
  [
    set deceived-length 0 ;; initialize user parameters similar to other users
    set ticker 0
    set recovery-length random-float Max-user-recovery-time
    set memorystrength random-float Max-initial-memory-strength

    if (connected? = false) ;; this separates new users from ones already on the network. Prevents multiple connections.
    [
      create-link-with one-of other hubs ;; create network of users attached to hubs
      set connected? true ;; set condition to true, now users cannot be connected again.
    ]

    layout2  ;; set layout for new users

  ]
end


;; This procedure creates a pre-determined amount of "infobit" turtles on the network.
to infobit-creation
  create-infobits infobitcount ;; create whatever the infobitcount is during this tick.
  [
    set color green
    set location one-of hubs   ;; locate infobits at a hub for transfer to users.
    move-to location
  ]

  set totalinfobits (totalinfobits + infobitcount)
end

;; This procedure puts a selected amount of "badinfobit" turtles on the network.
to badinfobit-creation
  create-badinfobits badinfobitcount ;; create whatever the badinfobitcount is during this tick.
  [
    set color brown
    set location one-of hubs  ;; locate infobits at a hub for transfer to users.
    move-to location
  ]
  set totalbadinfobits (totalbadinfobits + badinfobitcount)
end

;; The following procedure defines the links used between hubs and between users.
to layout
  layout-spring users links 0.06 2 0.5 ;; set link spring parameters
  layout-spring hubs links 0.2 2 1

  ask users [set size 0.7]
  ask hubs [set size 1.2]
end

;; The following procedure defines links between hubs and users,
;; and is only used when a new user is added or existing user needs to be moved
to layout2
  layout-spring users links 0.06 2 0.5
  ask users [set size 0.7]
end


;; Following updates infobits behavior. Infobits travel from hubs to users, then back to the hub - simulating the transfer
;; of information.
to update-infobits
  ask infobits
  [
    let new-location one-of [link-neighbors] of location
    ask [link-with new-location] of location [ set color blue ]
    ask [link-with new-location] of location [ set thickness 0.2 ] ;; change the thickness of the link the info packet just crossed over
    face new-location
    move-to new-location
    set location new-location
  ]
end

;; Following updates badinfobits behavior. Badinfobits, like regular infobits, travel from hubs to users,
;; then back to the hub - simulating the transfer of information.
to update-badinfobits
  ask badinfobits
  [
    let new-location one-of [link-neighbors] of location
    ask [link-with new-location] of location [ set color 18 ] ;; change the thickness of the link the info packet just crossed over
    ask [link-with new-location] of location [ set thickness 0.2 ]
    face new-location
    move-to new-location
    set location new-location
  ]
end

to update-users
  ;; Following updates users behavior. Users are stationary, and there is a count for how much information they have consumed.
  ;; A user has a chance of becoming "deceived" once an bad infobit is consumed by them. The user eventually becomes
  ;; normal again after some time.

ask users
  [
    set ticker (ticker + 1) ;; Advance the ticker or -t for the retention formula

    if any? infobits-here
    [ set usercount usercount + (count infobits-here) ] ;; sets usercount plus however many infobits are there.
                                                        ;; Users can consume more than one bit of info at a time.
    if any? badinfobits-here
    [
      set usercount usercount + (count badinfobits-here) ;; bad infobits count too!

      while [any? badinfobits-here] ;; for all badinfobits, there is a chance of deception
      [
        if random-float 100 > (memoryretention * 100) ;; deception rate based memory retention
        [
          set deceived? true
          set color red
        ]
       ask one-of badinfobits-here [die] ;; kill badinfobits off one-by-one after they have had their chance deceiving the user
      ]
      ask infobits-here [die] ;; kill infobits after user has consumed them. New infobits will be generated in the next cycle.
    ]


    if education-rate = 0 ;; if there is no education, then user forget curve is nominal.
    [
      set memoryretention (2.71828 ^ ((-1 * ticker) / memorystrength)) ;; Ubbinghaus Forgetting Curve - users start forgetting what deceives them.
    ]

    if education-rate > 0 ;; if users can become educated, then they will become deceived less and recover faster.
    [
      set memoryretention (2.71828 ^ ((-1 * (ticker / education-rate)) / memorystrength)) ;; education reduces time to memory retention decay.
    ]

    if recovery-length > 0 ;; sets condition that recovery is possible, if recovery-length is at 0, then no users will recover.
    [
      if (deceived? = true) ;; only deceived users can recover.
      [
        set deceived-length (deceived-length + 1)
        if (deceived-length > (recovery-length)) ;; set users to recover.
        [
          set deceived? false
          set color 73
          set memorystrength memorystrength + Mem-str-incr-after-recovery ;; users become "smarter" after they recover.
          set deceived-length 0 ;; reset deceived-length
          set ticker 0 ;; reset timer
        ]
      ]
    ]
  ]
end


;; Following updates behavior of hubs. Hubs count how many infobits leave through it to users and other hubs.
to update-hubs
  ask hubs
  [
    if user-Consumption-Limit > 0 ;; set user consumption limit
    [
      while [((count infobits-here) + (count badinfobits-here)) > (User-Consumption-Limit * (number-of-users / number-of-hubs))] ;; hub-level consumption limit for users
      [
        if any? infobits-here
        [
          ask n-of (random-float 3) infobits-here [ die ] ;; this is a quick and dirty way of trimming down the number of available infobits to impose a consumption limit
        ]

        if any? badinfobits-here
        [
          ask n-of (random-float 3) badinfobits-here [ die ]
        ]
      ]
    ]

    if any? infobits-here
    [ set hubcount hubcount + (count infobits-here) ] ;; sets usercount plus however many infobits are there. Users can consume more than one bit of info at a time.

    if any? badinfobits-here
    [ set hubcount hubcount + (count badinfobits-here) ] ;; bad info counts too!

    set badinfobitsfiltered (badinfobitsfiltered + ((Hub-filter-rate / 100) * count (badinfobits-here)))
    ask n-of ((Hub-filter-rate / 100) * count (badinfobits-here)) badinfobits-here [ die ] ;; this filters out a percentage of the badinfobits at the hub.

    set infobitsfiltered (infobitsfiltered + ((Hub-filter-error-rate / 100) * count (infobits-here)))
    ask n-of ((Hub-filter-error-rate / 100) * count (infobits-here)) infobits-here [ die ] ;; this filters out a percentage of the infobits at the hub.                                                                                          ;; this is common with automated content filter
  ]
end

to show-labels ;; this procedure creates number labels for the users and hubs, as well as either shows or hides infobits

  ask hubs ;; ask hubs to show relevant information
  [
    ifelse ShowDataUse?
      [ set label hubcount ]
      [ set label "" ]

    if SeeBits? = false
      [
        ask infobits [set hidden? true]
        ask badinfobits [set hidden? true]
      ]
  ]

  ask users ;; ask users to show relevant information
  [
    if (ShowDataUse? = false) and (SeeMemoryRetention? = false)  [ set label "" ]

    if ShowDataUse? = true [ set label usercount ]

    if (SeeMemoryRetention? = true) [ set label (precision memoryretention 3)] ;; set decimals

    if SeeBits? = false
      [
        ask infobits [set hidden? true]
        ask badinfobits [set hidden? true]
      ]
  ]
end

;; Run the program
to go

  ask links [ set thickness 0 ] ;; Set all link thickness to standard, until a turtle travels over it.

  badinfobit-creation
  infobit-creation

  if addl-users-per-tick > 0 [ addl-user-creation ] ;; This introduces the idea of increasing the user base. Very slow.

  update-hubs
  update-users

  update-infobits
  update-badinfobits

  show-labels

  set infobitcount (infobitcount + (infobitcount * ((%-Infobits-Increase-Per-Tick / 100))))          ;; calculates geometric growth for infobits
  set badinfobitcount (badinfobitcount + (badinfobitcount * ((%-Infobits-Increase-Per-Tick / 100)))) ;; based on growth per tick

  if all? users [color = red] [ stop ] ;; terminate model when all users are deceived
  if ticks >= max-ticks [ stop ]       ;; terminate model when simulation time limit is reached
  tick

end

;; Following are Demos for Presentation Purposes

to Demo1

  set seememoryretention? false
  set ShowDataUse? true
  set %-Infobits-Increase-Per-Tick 1.5
  set max-ticks 150
  set user-consumption-limit 0
  set number-of-hubs 1
  set number-of-users 100
  set number-of-infobits 140
  set number-of-badinfobits 260
  set education-rate 12
  set hub-filter-rate 0
  set max-user-recovery-time 10
  set hub-filter-error-rate 0
  set max-initial-memory-strength 200
  set mem-str-incr-after-recovery 100
  set addl-users-per-tick 1

  setup

  repeat max-ticks [go]

end


to Demo2

  set seememoryretention? true
  set ShowDataUse? false
  set %-Infobits-Increase-Per-Tick 0.16
  set max-ticks 365
  set user-consumption-limit 0
  set number-of-hubs 8
  set number-of-users 400
  set number-of-infobits 140
  set number-of-badinfobits 260
  set education-rate 12
  set hub-filter-rate 50
  set max-user-recovery-time 10
  set hub-filter-error-rate 5
  set max-initial-memory-strength 200
  set mem-str-incr-after-recovery 100
  set addl-users-per-tick 0

  setup

  repeat max-ticks [go]

end
@#$#@#$#@
GRAPHICS-WINDOW
395
10
1341
733
-1
-1
14.0
1
11
1
1
1
0
0
0
1
-33
33
-25
25
1
1
1
ticks
30.0

BUTTON
10
90
65
123
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
70
90
125
123
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
130
90
185
123
go once
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
165
10
285
43
ShowDataUse?
ShowDataUse?
1
1
-1000

SLIDER
10
130
182
163
Number-of-Hubs
Number-of-Hubs
1
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
205
130
375
163
Number-of-Users
Number-of-Users
20
500
400.0
10
1
NIL
HORIZONTAL

SLIDER
10
170
182
203
Number-of-Infobits
Number-of-Infobits
0
500
140.0
10
1
NIL
HORIZONTAL

SLIDER
195
50
380
83
Max-ticks
Max-ticks
2
1000
365.0
1
1
NIL
HORIZONTAL

SLIDER
205
170
375
203
Number-of-BadInfobits
Number-of-BadInfobits
0
500
260.0
10
1
NIL
HORIZONTAL

MONITOR
195
370
280
415
Infobits per tick
infobitcount
0
1
11

MONITOR
285
370
370
415
Badbits per tick
badinfobitcount
0
1
11

PLOT
10
520
370
640
User States
Time
Percent
0.0
1.0
0.0
1.0
true
true
"" ""
PENS
"Deceived" 1.0 0 -2674135 true "" "plot ((count users with [color = red]) / (number-of-users + addlusers)) * 100"
"Recovered" 1.0 0 -15637942 true "" "plot ((count users with [color = 73]) / (number-of-users + addlusers)) * 100"
"Original" 1.0 0 -13345367 true "" "plot ((count users with [color = blue]) / (number-of-users + addlusers)) * 100"

SLIDER
5
50
190
83
%-Infobits-Increase-Per-Tick
%-Infobits-Increase-Per-Tick
0
2
0.16
0.01
1
NIL
HORIZONTAL

SLIDER
205
210
375
243
Hub-Filter-Rate
Hub-Filter-Rate
0
100
50.0
1
1
NIL
HORIZONTAL

SWITCH
290
10
380
43
SeeBits?
SeeBits?
1
1
-1000

SLIDER
10
210
180
243
Education-rate
Education-rate
0
365
12.0
1
1
NIL
HORIZONTAL

SLIDER
10
250
180
283
Max-user-recovery-time
Max-user-recovery-time
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
105
420
190
465
Deceived Users
count users with [deceived? = true]
0
1
11

MONITOR
10
420
100
465
Original Users
count (users with [color = blue])
17
1
11

MONITOR
10
470
100
515
Recovered Users
count users with [color = 73]
17
1
11

SLIDER
205
250
375
283
Hub-Filter-Error-Rate
Hub-Filter-Error-Rate
0
100
5.0
1
1
NIL
HORIZONTAL

MONITOR
285
420
370
465
Filtered bits
infobitsfiltered
0
1
11

MONITOR
195
420
280
465
Filtered badbits
badinfobitsfiltered
0
1
11

MONITOR
10
370
100
415
Total InfoBits
totalinfobits
0
1
11

MONITOR
105
370
190
415
Total Badbits
totalbadinfobits
0
1
11

SLIDER
10
290
180
323
Max-initial-memory-strength
Max-initial-memory-strength
1
200
200.0
1
1
NIL
HORIZONTAL

PLOT
10
650
175
770
All infobits
Time
All Infobits
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (totalinfobits + totalbadinfobits)"
"pen-1" 1.0 0 -13345367 true "" "plot totalinfobits"
"pen-2" 1.0 0 -2674135 true "" "plot totalbadinfobits"

SLIDER
205
90
375
123
User-Consumption-Limit
User-Consumption-Limit
0
50
0.0
1
1
NIL
HORIZONTAL

SWITCH
5
10
160
43
SeeMemoryRetention?
SeeMemoryRetention?
0
1
-1000

MONITOR
195
470
280
515
%-Normal
((count users with [color = 73]) + (count users with [color = blue])) / (number-of-users + addlusers) * 100
1
1
11

MONITOR
285
470
370
515
%-Deceived
(count users with [color = red]) / (number-of-users + addlusers) * 100
1
1
11

SLIDER
205
290
375
323
Mem-str-incr-after-recovery
Mem-str-incr-after-recovery
0
200
100.0
1
1
NIL
HORIZONTAL

PLOT
185
650
370
770
Hub Filtered Bits
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
"default" 1.0 0 -2674135 true "" "plot badinfobitsfiltered"
"pen-1" 1.0 0 -13345367 true "" "plot infobitsfiltered"

SLIDER
10
330
180
363
Addl-users-per-tick
Addl-users-per-tick
0
10
0.0
1
1
NIL
HORIZONTAL

MONITOR
105
470
190
515
Total Users
count users
17
1
11

TEXTBOX
200
335
380
376
<- This is experimental and will severely slow down the model.
11
15.0
1

@#$#@#$#@
## WHAT IS IT?
Most user-generated content (UGC) do not take responsibility for the accuracy of the information submitted by the lay user. Since everyone consumes copious amounts of information online, it’s only a matter of time before someone is deceived by bad information. This model simulates user consumption of data, and whether or not the user becomes deceived when consuming a piece of bad information. The deceivability of the users is based on Ebbinghaus’ Forgetting Curve.
 
## HOW IT WORKS
We will describe how the model works in 3 parts: Components, parameters (Forgetting Curve), and process flow. Further model description information can be found in the final project report. 

### How the model components work
Information hubs (red squares) represent any centralized system that distributes information to its users and to other hubs. The purpose of the hub is to route “infobits” and filter information based on parameters.  A hub can connect to one more hub to exchange infobits.

Users come in three flavors: Blue (never deceived), Red (deceived), and Teal/Green (recovered). A user represents any individual that that consumes information on a regular basis. In this model, the users only connect to one hub for information - this is purely for visual and computational reasons. Users go through a “fast-and-frugal” selection tree to simulate user behavior. See report for more information. 

Infobits (green or red turtle) is any piece of consumable information a user may find online - news article, facebook post, tweet, blog post, etc. Infobits get assigned to a hub at the beginning of each cycle. The amount of infobits that reside at the hub does not represent the overall information available, but rather the information that will be consumed. You have to switch the “seebits?” switch to ON to see these turtles.

### How the Ebbinghaus’ Forgetting Curve works
Ebbinghaus’ Forgetting Curve is R=e^(-t/M). R being memory retention, -t being time in days, and M being memory strength. In the model, you can select a user’s initial memory strength, it’s memory strength after recovering from a deceived state, and education rate, r, which modifies -t to (-t/r). 

### How the process flow works: 

Very simply, the process is as follows: 

1) Hubs/users get created and linked
2) Infobits get created and assigned to hubs
3) Hubs decide filters
4) Users decide whether or not to consume
5) Forgetting Curve formula calculated for user
6) User gets state change: Gets deceived? User already deceived? User recovers? 
7) Consume infobit - infobits die when consumed. Data transfer is one-way from Hub -> User. 
8) Start next tick with step #2. 

Fully detailed Process Flow Diagrams and explanations are found in the report.

## HOW TO USE IT
Start by selecting what you want to display. Since turtles can only show one label, you have to choose either SeeMemoryRetention? Or ShowDataUse? As the label. Set the percent increase for infobits, maximum run time in days, and the rest of the parameters. Then hit setup and go. A thorough description of parameters can be found in the report. 

## THINGS TO NOTICE
Add-users-per-tick slows down the model tremendously. Also, if %-infobits-increase-per-tick is increased past 1%, the model eventually becomes VERY slow as infobits increase exponentially. Additionally, users only connect to one hub, and hubs only connect to one other hub - for aesthetic and computational reasons. It takes too much computing power to connect users to more than one hub. 

## RELATED MODELS
Networks -> Preferential Attachment
Networks -> Virus on a Network

## CREDITS AND REFERENCES
All code in this model was written by me. 

## COPYRIGHT AND LICENSE
© 2013 Hengyi Hu. All rights reserved. Not sure if this means anything. 
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
random-seed 2
setup
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="1 Baseline 1" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1 Education-rate" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Education-rate" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1 Hub-filter-rate" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="99"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1 Consumption-limit" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>ticks</metric>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="User-Consumption-Limit" first="1" step="1" last="10"/>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="1000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="2 Max-initial-mem-str" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>((count users with [color = 73]) + (count users with [color = blue])) / number-of-users * 100</metric>
    <metric>(count users with [color = red]) / number-of-users * 100</metric>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Max-initial-memory-strength" first="50" step="10" last="140"/>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="2 Max-recover-length" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>((count users with [color = 73]) + (count users with [color = blue])) / number-of-users * 100</metric>
    <metric>(count users with [color = red]) / number-of-users * 100</metric>
    <steppedValueSet variable="Max-user-recovery-time" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="2 mem-incr-after-recov" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>((count users with [color = 73]) + (count users with [color = blue])) / number-of-users * 100</metric>
    <metric>(count users with [color = red]) / number-of-users * 100</metric>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="0"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Mem-str-incr-after-recovery" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="3 - all internet recovery rate" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>((count users with [color = 73]) + (count users with [color = blue])) / (number-of-users + addlusers) * 100</metric>
    <metric>(count users with [color = red]) / (number-of-users + addlusers) * 100</metric>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="30"/>
      <value value="25"/>
      <value value="20"/>
      <value value="15"/>
      <value value="10"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="260"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="3 - all internet baseline" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>((count users with [color = 73]) + (count users with [color = blue])) / (number-of-users + addlusers) * 100</metric>
    <metric>(count users with [color = red]) / (number-of-users + addlusers) * 100</metric>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="260"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="3 - all internet education rate" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>((count users with [color = 73]) + (count users with [color = blue])) / (number-of-users + addlusers) * 100</metric>
    <metric>(count users with [color = red]) / (number-of-users + addlusers) * 100</metric>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="365"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="365"/>
      <value value="180"/>
      <value value="96"/>
      <value value="48"/>
      <value value="24"/>
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="0.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="260"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="200"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="DEMO1" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="Mem-str-incr-after-recovery">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="User-Consumption-Limit">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Addl-users-per-tick">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-ticks">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ShowDataUse?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-Infobits-Increase-Per-Tick">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Education-rate">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeBits?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Hubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-BadInfobits">
      <value value="260"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Infobits">
      <value value="140"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SeeMemoryRetention?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hub-Filter-Error-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Number-of-Users">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-initial-memory-strength">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Max-user-recovery-time">
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
1
@#$#@#$#@
