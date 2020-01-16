;Turtle variables indicating various attributes related to Maslow's Hierarchy.Many were used for testing and exploratory purposes

turtles-own [
  coupled?                ;; whether currently coupled
  partner                 ;; who the partner is
  divorced?               ;; whether currently divorced
  ;divorced-ever? ;
  couple-length           ;;how long the partners have been together
  divorce-num             ;; number of divorces an individual has gone through - used for testing
  commitment              ;;commitment length to the partner
  marriage-num            ;; number of marriages that an individual has gone through - used for testing
  married-ever?
  married?                ;; is currently married?
  random-assigner         ;; used to generate random number based on which highest-need-met is assigned
  ;time-since-1stmarriage
  highest-needmet         ;; highest need met on Maslow's hierarchy
  self-actual-met?        ;; the next five variables correspond to five needs on MH and take true/false value
  esteem-met?
  love-met?
  safety-met?
  physiological-met?
  self-actual-offer?      ;; the next five variables indicate whether or not individuals are able to offer support on the five domains of MH
  esteem-offer?
  love-offer?
  safety-offer?
  physiological-offer?
physiological-valence     ;; the next five variables indicate numeric values for the unmet needs of the individual
  safety-valence
  love-valence
  esteem-valence
  self-actual-valence
physiological-fulfild?    ;; the next five variables indicate whether or not the needs are fulfilled by the partner
  safety-fulfild?
  love-fulfild?
  esteem-fulfild?
  self-actual-fulfild?
  self-actual-fulfild-num  ;; the next five variables assign numeric value to the needs fulfilled by partner
  esteem-fulfild-num
  love-fulfild-num
  safety-fulfild-num
  physiological-fulfild-num
  totunmet
  totfulfild
  totunmet-remaining ]

;; link  to encompass a marriage entity.
links-own [
  created-at   ;; indicates the time/tick at which it was formed; used for testing purposes
  active?      ;; this indicates whether the link represents a divorced relationship or active one
  age          ;; represents time since the link was born
  married-status-tenyr?] ;; this variable indicates the the status of the link (active or not) after a specified period/age - in the current default state, it is set at 350 ticks

to setup
  clear-all
  setup-patches
  setup-men

  reset-ticks
end

to setup-patches
 ask patches [set pcolor white - 1]
end

to setup-link
  ask links [set age 0]

end
;; two types of turtle are created, Righties and Lefties they are color coded blue and pink
to setup-men
  create-turtles initial-number-people ;; the initial population size can affect how often an individual encounters a potential partner
  [setxy random-xcor random-ycor
    set shape "person"
    ifelse random 2 = 0
    [set shape "person righty" set color blue - 1]
    [set shape "person lefty" set color pink - 10]
    set coupled? false
    set divorced? false
    set couple-length 0
    set random-assigner (random 5)                  ;; random number used later to pick one of the MH needs as higest-need-met for the individual
    set partner nobody
    set divorce-num 0                               ;; number of divorces at setup
    set marriage-num 0                              ;; number of marriages at setup
    set married-ever? false
    set commitment 0
   assign-commitment                                ;; procedure to assign commitment to partner
  ]

  create-highest-needmet                           ;; procedure to identify highest need met by the individual
  create-mneeds-values                             ;; procedure to assign true/false value to the different MH needs
  if not growth-need-equally-imp?  [create-mneeds-values2] ;; different values are assigned if the growth-need is not important - growth variables are weighed less in this scenario
  create-mneeds-offers                             ;; procedure to assign attributes to indicate whether and individual can offer support on the each of the five MH domains
  create-valence-score                              ;; creates numeric score for unmet needs on MH

end

to go;
  ask turtles          ;; if the turtle are not copuled then they move around
    [ if not coupled?
        [ move ] ]
  ;;similar to HIV code,  Righties are  the ones to initiate coupling
  ask turtles
    [ if not coupled? and shape = "person righty" and (random 100 < coupling-tendency)  ;; effectively it results in upto 10% chance of coupling
        [ couple ] ]
  ask turtles [ uncouple ]
  ask turtles
  [ if coupled?
    [set couple-length couple-length + 1                        ;; to track how long the couples are married. this variable is useful later for uncoupling purposes
      create-need-fulfild-bypartnr                              ;; this procedure assigns needs fullfilled by partner
  create-marriage-fulfiling-index
      create-unmet-remaining                                    ;; it also includes commitment assignment
  ]]
  ask patches with [any? turtles-here with [coupled?]] [set pcolor gray + 1] ; this code prevents the patch from getting unhilighted when two pairs populates the same patches and only one uncouples
  ask links [set age age + 1]
  create-link-var

  tick
end

to move  ;; turtle procedure
  rt random-float 360
  fd 1
end
; code to initiate coupling in turtles

to couple  ;; turtle procedure -- blues only
  let potential-partner one-of (turtles-at -1 0) ;(turtles-on neighbors)
                          with [not coupled? and shape = "person lefty"]
  if potential-partner != nobody
  [ if random 100 < [coupling-tendency] of potential-partner
      [ set partner potential-partner
        set coupled? true
        ;set married-ever? true
        set married? true
      set divorced? false
      ask partner [ set coupled? true ]
      ask partner [ set partner myself ]
      ask partner [set divorced? false]
      ask partner [set married? true]
      ask partner [set married-ever? true]
        move-to patch-here ;; move to center of patch
        ask potential-partner [move-to patch-here] ;ask potential-partner [move-to patch-here] ;; partner moves to center of patch
        set pcolor gray + 1
      ask partner [ask patch-here [set pcolor gray + 1]]
        ask partner [set married-ever? true]
        ask partner [set marriage-num marriage-num + 1]
        create-link-with partner
        ask link-with partner [set created-at ticks set active? true  hide-link]

        set marriage-num marriage-num + 1

      ]
]
end
;; code to initiate uncoupling in turtles. Uncoupling takes place if the couple length is greater than the commitement of self or that of partner
;; and post-marriage unmet need remaining are greater than tolerance for unment needs
;; couple length is set to zero and the individual is marked divorced and married status is changed to false. Similar changes are initiated in the partner.

to uncouple  ;; turtle procedure
  if coupled? and (color = blue - 1)
    [ if ((couple-length > commitment) or ([couple-length] of partner) > ([commitment] of partner))
            and ((totunmet-remaining > unfulfiled-need-tolerance) or ([totunmet-remaining] of partner) > (unfulfiled-need-tolerance))
        [ask link-with partner [set active? false]  ; when uncoupled the link between the individual is flagged not active?
        set coupled? false
          set couple-length 0
          set divorced? true
          set married? false
          ask partner [ set couple-length 0 ]
          set pcolor white - 1
         ; ask (patch-at -1 0) [ set pcolor white - 1 ]
          ask partner [ask patch-here [set pcolor white - 1]]
          ask partner [ set partner nobody ]
          ask partner [ set coupled? false ]
          ask partner [ set divorced? true ]
          ask partner [set married? false]
          ask partner [set divorce-num divorce-num + 1] ;; number of divorces were maintained as a cumulative variable - it was useful var in the previous version not anymore
          set partner nobody
          set divorce-num divorce-num + 1

          ] ]

end

; this procedure creates a marriage cohort of all the marriages that were created at a certain point in time (350 weeks ago).
;; using this procedure links are tracked for their married satus (indicated by active?) at 350 ticks after they were born = cohort divorce rate.
;; choice of the number of ticks (or age of cohort) was initially based on logical relation between commitment, couple-length, coupling tendency etc.
;; having gone through multiple changes it is currently more or less an arbitrary pick - seems like a significant period of time.
to create-link-var
  ask links with [age = 350]

  [ifelse active? [set married-status-tenyr? true] [set married-status-tenyr? false]]

end

;; this procedure identifies the highest need met by the individuals
to create-highest-needmet
ask turtles
  [
         if (random-assigner = 4)
         [
           set highest-needmet "self-actualization"
         ]
         if (random-assigner = 3)
         [
           set highest-needmet "esteem"
         ]
    if (random-assigner = 2)
         [
           set highest-needmet "love"
         ]
    if (random-assigner = 1)
         [
           set highest-needmet "safety"
         ]
    if (random-assigner = 0)
         [
           set highest-needmet "physiological"
         ]
  ]
end

;assigning values for all turtles for each of the five needs based on the above identified highest-need-met
;the variable that corresponds to highest-need-met always gets a true value. All the needs above this level get false value.
;Also, the lower-level deficiency needs get a true value always - for the individuals to focus on psychological needs they need to fulfil the more basic needs.
;But the lower-level growth needs get a true value only 70% of the time

to create-mneeds-values
  ask turtles
  [
  if (highest-needmet = "self-actualization")
   [
      ifelse random 10 <= 9 [set self-actual-met? true] [set self-actual-met? false] ; used 9 to assign true value always
      ifelse random 10 <= 6 [set esteem-met? true] [set esteem-met? false]           ; 60% chance that the variable get a 'true' value
      ifelse random 10 <= 6 [set love-met? true] [set love-met? false]
      ifelse random 10 <= 9 [set safety-met? true] [set safety-met? false]
      ifelse random 10 <= 9 [set physiological-met? true] [set physiological-met? false]
    ]
    if (highest-needmet = "esteem")
   [
      ifelse random 10 <= -1 [set self-actual-met? true] [set self-actual-met? false] ;  used '-1' to assign false value. could have done without the ifelse statement but wanted to keep the format same in case needed to change the logic at some point
      ifelse random 10 <= 9 [set esteem-met? true] [set esteem-met? false]
      ifelse random 10 <= 6 [set love-met? true] [set love-met? false]
      ifelse random 10 <= 9 [set safety-met? true] [set safety-met? false]
      ifelse random 10 <= 9 [set physiological-met? true] [set physiological-met? false]
    ]

   if (highest-needmet = "love")
   [
      ifelse random 10 <= -1 [set self-actual-met? true] [set self-actual-met? false]
      ifelse random 10 <= -1 [set esteem-met? true] [set esteem-met? false]
      ifelse random 10 <= 9 [set love-met? true] [set love-met? false]
      ifelse random 10 <= 9 [set safety-met? true] [set safety-met? false]
      ifelse random 10 <= 9 [set physiological-met? true] [set physiological-met? false]
    ]
       if (highest-needmet = "safety")
   [
      ifelse random 10 <= -1 [set self-actual-met? true] [set self-actual-met? false]
      ifelse random 10 <= -1 [set esteem-met? true] [set esteem-met? false]
      ifelse random 10 <= -1 [set love-met? true] [set love-met? false]
      ifelse random 10 <= 9 [set safety-met? true] [set safety-met? false]
      ifelse random 10 <= 9 [set physiological-met? true] [set physiological-met? false]
    ]
       if (highest-needmet = "physiological")
   [
      ifelse random 10 <= -1 [set self-actual-met? true] [set self-actual-met? false]
      ifelse random 10 <= -1 [set esteem-met? true] [set esteem-met? false]
      ifelse random 10 <= -1 [set love-met? true] [set love-met? false]
      ifelse random 10 <= -1 [set safety-met? true] [set safety-met? false]
      ifelse random 10 <= 9 [set physiological-met? true] [set physiological-met? false]
    ]


;
  ]

end

;this  code is for depicting the scenario when women were home-makers and depended on men for the basic sustenance needs
; it takes effect when the growth-need-imp switch is turned off.
;The psycholgoical needs are set to true, so they are not considered as a gap to be fulfilled by the partner and not evaluated for marriage quality in the subsequent steps
to create-mneeds-values2
  ask turtles
  [
     ifelse color = (pink - 10)
    [set self-actual-met? true] [set self-actual-met? self-actual-met?]
     ifelse color = (pink - 10)
    [set esteem-met? true] [set esteem-met? esteem-met?]
     ifelse color = (pink - 10)
    [set love-met? true] [set love-met? love-met?]
    ifelse color = (pink - 10)
    [set physiological-met? false] [set physiological-met? physiological-met?]
   ifelse color = (pink - 10)
        [set safety-met? false] [set safety-met? safety-met?]
    ]
end

; this part assigns true/false value to attributes that identify whether the individual is capable of offereing support to their partner in the five MH domains
; assignment is done based on whether the individual has met the need himself. If yes, and if it is a lower-level domain then the value for offering support is set to true always
; if it is higher psychological domain then the value for offering support is set to true only 70% of the times. Else, the value for offering support is set to false.

to create-mneeds-offers
  ask turtles
  [

    ifelse (self-actual-met? = true)
    [ifelse random 10 <= 6 [set self-actual-offer? true] [set self-actual-offer? false]]
    [set self-actual-offer? false]

     ifelse (esteem-met? = true)
    [ifelse random 10 <= 6 [set esteem-offer? true] [set esteem-offer? false]]
    [set esteem-offer? false]

    ifelse (love-met? = true)
    [ifelse random 10 <= 6 [set love-offer? true] [set love-offer? false]]
    [set love-offer? false]


    ifelse (safety-met? = true)
    [ifelse random 10 <= 9 [set safety-offer? true] [set safety-offer? false]]
    [set safety-offer? false]

     ifelse (physiological-met? = true)
    [ifelse random 10 <= 9 [set physiological-offer? true] [set physiological-offer? false]]
    [set physiological-offer? false]
  ]
end

;; deciding whether the needs are fulfilled by the partner. Only if the needs are not already met and if the partner offers support in that domain, the need-fulfilled variable is marked true
;; if the need fulfilled variable is met by the individual herself then partner's offer is not even considered. the need-fulfilled is marked false.
;; these variables are assigned a true value only if the need is fulfilled by partner, it holds false when the need is self met
;; (its counterpart need-met variable stands for the individual's own accomplishment).

to create-need-fulfild-bypartnr

Ifelse not physiological-met?
    [ifelse [physiological-offer?] of partner = true  [set physiological-fulfild? true] [set physiological-fulfild? false]]
    [set physiological-fulfild? false]
Ifelse not safety-met?
    [ifelse [safety-offer?] of partner = true  [set safety-fulfild? true] [set safety-fulfild? false]]
    [set safety-fulfild? false]
Ifelse not love-met?
    [ifelse [love-offer?] of partner = true  [set love-fulfild? true] [set love-fulfild? false]]
    [set love-fulfild? false]
Ifelse not esteem-met?
    [ifelse [esteem-offer?] of partner = true  [set esteem-fulfild? true] [set esteem-fulfild? false]]
    [set esteem-fulfild? false]
Ifelse not self-actual-met?
    [ifelse [self-actual-offer?] of partner = true  [set self-actual-fulfild? true] [set self-actual-fulfild? false]]
    [set self-actual-fulfild? false]

 ; ]
end
;; creating numeric values for the five needs-met. If growth needs are important to the population then the psychological needs are weighed 50% more;
;; when growth needs are not important then the psychological needs are weighed 50% less than the basic deficiency needs.

to create-valence-score
  ask turtles
  [if self-actual-met? = false  [ifelse growth-need-equally-imp? [set self-actual-valence 3] [set self-actual-valence 1]]
    if esteem-met? = false [ifelse growth-need-equally-imp? [set esteem-valence 3] [set esteem-valence 1]]
    if love-met? = false [set love-valence 2]
    if safety-met? = false [set safety-valence 2]
    if physiological-met? = false [set physiological-valence 2]
  ]

end


;; assigning numeric values for needs fullfilled by partner using similar weigthing as the for the needs-valence code above

to create-marriage-fulfiling-index
;  ask turtles
;  [
  if self-actual-fulfild? = true [ifelse growth-need-equally-imp? [set self-actual-fulfild-num 3] [set self-actual-fulfild-num 1]]
  if esteem-fulfild? = true [ifelse growth-need-equally-imp? [set esteem-fulfild-num 3] [set esteem-fulfild-num 1]]
  if love-fulfild? = true  [set love-fulfild-num 2]
  if safety-fulfild? = true [set safety-fulfild-num 2]
  if physiological-fulfild? = true [set physiological-fulfild-num 2]
 ; ]
end
; creating a score of post-marriage unfulfilled needs.

to create-unmet-remaining

  ;ask turtles   [
  set totunmet  (self-actual-valence + esteem-valence + love-valence + safety-valence + physiological-valence)                        ; total unmet needs before marriage
  set totfulfild (self-actual-fulfild-num + esteem-fulfild-num + love-fulfild-num + safety-fulfild-num + physiological-fulfild-num)   ; total fulfilled by partner
  ifelse totunmet != 0 [set totunmet-remaining ((totunmet - totfulfild) * 100 /(totunmet))] [set totunmet-remaining 0]                ; total unfulfilled remaining after marriage
  ;set commitment (100 - totvalence)
  ;  ]

end

;assigning commitment by factoring in the total unmeet needs remaining

to assign-commitment  ;; turtle procedure
  ;set commitment random-near (1000 - 15 * totvalence)
set commitment random (1000 - 5 * totunmet-remaining) ;random 200
end

;calculating divorce rate to be used in behavior space
to-report divorce-rate2

if any? links with [married-status-tenyr? != 0]
  [report (count links with [married-status-tenyr? = false]) * 100 / (count links with [married-status-tenyr? != 0])]
end


to-report coupled
  report (count turtles with [coupled?])
end
to-report divorced
  report (count turtles with [divorced?])
end

to-report single
  ;report (count turtles with [married-ever? = false])
  report (count turtles with [coupled? = false and divorced? = false])
end



@#$#@#$#@
GRAPHICS-WINDOW
280
14
717
452
-1
-1
13.0
1
10
1
1
1
0
1
1
1
-16
16
-16
16
1
1
1
weeks
30.0

BUTTON
55
78
118
111
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

SLIDER
52
25
224
58
initial-number-people
initial-number-people
0
300
150.0
1
1
NIL
HORIZONTAL

BUTTON
144
80
207
113
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

MONITOR
3
299
135
344
# Coupled - currently
coupled
1
1
11

MONITOR
83
356
201
401
#Single - Currently
Single
1
1
11

MONITOR
146
299
275
344
# Divorced - currently
divorced
1
1
11

SLIDER
41
175
230
208
unfulfiled-need-tolerance
unfulfiled-need-tolerance
0
100
80.0
1
1
NIL
HORIZONTAL

SWITCH
35
229
235
262
growth-need-equally-imp?
growth-need-equally-imp?
0
1
-1000

PLOT
742
10
1008
160
Post Marriage Unmet Needs distribution
Remaining Unmet Need
#  People
0.0
100.0
0.0
50.0
true
false
"" ""
PENS
"default" 10.0 1 -16777216 true "histogram [totunmet-remaining] of turtles" "histogram [totunmet-remaining] of turtles"

SLIDER
51
129
223
162
Coupling-Tendency
Coupling-Tendency
0
10
5.0
1
1
NIL
HORIZONTAL

PLOT
748
364
1013
523
# Divorced vs. Married
Weeks
# of People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Married" 1.0 0 -12087248 true "" "plot count turtles with [coupled?]"
"Divorced" 1.0 0 -5298144 true "" "plot count turtles with [divorced?]"

PLOT
1048
178
1272
330
Average-num-of-Divorces
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
"default" 1.0 0 -16777216 true "" "if any? turtles with [married? = true] [plot sum [divorce-num] of turtles / count turtles with [married-ever? = true]]"

PLOT
743
184
1010
341
Divorce Rate
Weeks
% Divorced
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if any? links with [married-status-tenyr? != 0] [plot (count links with [married-status-tenyr? = false]) * 100 / (count links with [married-status-tenyr? != 0])] "

@#$#@#$#@
## WHAT IS IT?

The model explores divorce rates by varying various system parameters. It is specifically depicting divorce rates for three different eras:
Self-expressive Era: characterised by focus on growth needs. Implemented in the model by turning the growth-need-imp switch on. This divorce rate should be around 50%.

Companionate Era - characterised by focus on lower-level needs. Implemented in the model by turning of the growth-needs-imp switch.

Institutional Era - similar to companionate era, but divorce was associated with stigma, so people rarely got divorced. It is depicted in the model by turning off the growth-need-imp switch and also setting the tolerance for unfulfilled needs to a high value like 75% or 80%

## HOW IT WORKS

It has a set of agents in the space endowed with five needs, some fulfilled some not. They also are endowed with an ability to offer support to their partners in the five domains based on their own accomplishments in those domains. The individuals interact and couple based on their coupling tendencies and marital status. They uncouple based on their commitment, length of marriage and post-marriage unfullfilled needs remaining. 

## HOW TO USE IT

there are four items (three sliders and a switch) on the interface to change the parameters of the system. The default setting is
a) Initial-number-people = 150
b) Coupling-Tendency = 5 (five percent chance of coupling)
c) Unfulfilled-need-tolerance = 50% (the individual will be happy with marriage as long as at least 50% of their unmet needs are fulfilled through marriage)
d) Growth-need-imp (switch) = On

These sliders can be changed to observe the behavior of the system. Two plots are of most interest - Divorce-Rate plot and the histogram that depicts the post-marriage unmet needs remaining.


## THINGS TO NOTICE

The model can be run first at default setting. This depicts the current era where higher-level psyhological needs are important (growth-need-imp swtich on). One will notice around 50% divorce rate with this setting. Also the histogram will show that only one third people have all or most of their needs met through marriage. A big portion of the populatoin has more than 50% of their needs unfulfilled.

When the switch for growth-need-imp is turned off, the divorce rate drops to about 15% consitent with the divorce rate for companionate era. And the histogram shows that around two-thirds of the people have all or most of their needs fulfilled through marriage.

Now, if the unfulfilled-need-tolerance slider is set to high,the divorce rate will drop further down. Consistent with very low divorce rates in Institutional era when divorce was not prevalent possibly owing to stigma associated with it.

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

Parameters in the model can be grounded more in empirical data than intuitive reasoning. The model can use empirical data on dynamics of marriage e.g., gap between divorce and remarrriage, average number of marriages per person, age based variations in divorce rates etc. to improve and extend the model. Also, noise can be added to the model to sporadically change individuals standing on Maslow's hierarchy.

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS


## CREDITS AND REFERENCES

HIV model was consulted and code and logic was adopted from the model for various things.
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

person lefty
false
0
Circle -7500403 true true 170 5 80
Polygon -7500403 true true 165 90 180 195 150 285 165 300 195 300 210 225 225 300 255 300 270 285 240 195 255 90
Rectangle -7500403 true true 187 79 232 94
Polygon -7500403 true true 255 90 300 150 285 180 225 105
Polygon -7500403 true true 165 90 120 150 135 180 195 105

person righty
false
0
Circle -7500403 true true 50 5 80
Polygon -7500403 true true 45 90 60 195 30 285 45 300 75 300 90 225 105 300 135 300 150 285 120 195 135 90
Rectangle -7500403 true true 67 79 112 94
Polygon -7500403 true true 135 90 180 150 165 180 105 105
Polygon -7500403 true true 45 90 0 150 15 180 75 105

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
  <experiment name="experiment1" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>count turtles with [divorced?] / count turtles with [married-ever?]</metric>
    <enumeratedValueSet variable="growth-need-equally-imp?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-couple">
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Valence-tolerance" first="0" step="25" last="100"/>
  </experiment>
  <experiment name="experiment1" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="1000"/>
    <metric>count turtles with [divorced?] / count turtles with [married-ever?]</metric>
    <enumeratedValueSet variable="growth-need-equally-imp?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-number-couple">
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
    </enumeratedValueSet>
    <steppedValueSet variable="Valence-tolerance" first="0" step="25" last="100"/>
  </experiment>
  <experiment name="experiment4-institutional era-coupling tend" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <metric>divorce-rate2</metric>
    <enumeratedValueSet variable="initial-number-people">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="coupling-tendency">
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-need-equally-imp?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unfulfiled-need-tolerance">
      <value value="80"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment4-growthneed" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <metric>divorce-rate2</metric>
    <enumeratedValueSet variable="initial-number-people">
      <value value="150"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="coupling-tendency">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="growth-need-equally-imp?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unfulfiled-need-tolerance">
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
0
@#$#@#$#@
