;Modeling Appalachian Trail Recreation: Camping, Hiking & Overcrowding in our Natural parks (MARCH-ON)


globals [
 shelters
 centerline
 parking
 kilometer
 ;trail-elevation
; virginia
m-o-speed
m-s-speed
;m-t-speed
;m-d-speed
m-o-group
m-s-group
;m-t-group
;m-d-group
m-o-distance
m-s-distance
;m-t-distance
;m-d-distance
m-o-journey
m-s-journey
;m-t-journey
;m-d-journey
month
day
day-of-week
hour
minute
global-legal-camping
global-legal-camping-overnighthiker
global-legal-camping-sectionhiker
global-legal-camping-beginner
global-legal-camping-intermediate
global-legal-camping-skilled
global-legal-camping-advanced
global-legal-camping-expert
global-illegal-camping
global-illegal-camping-sb
global-illegal-camping-sb-distance
global-illegal-camping-sb-distance-from-previous
global-illegal-camping-nb
global-illegal-camping-nb-distance
global-illegal-camping-nb-distance-from-previous
global-illegal-camping-overnighthiker
global-illegal-camping-sectionhiker
global-illegal-camping-beginner
global-illegal-camping-intermediate
global-illegal-camping-skilled
global-illegal-camping-advanced
global-illegal-camping-expert

]
breed [OvernightHikers OvernightHiker]
breed [SectionHikers SectionHiker]
breed [ThruHikers Thruhiker]
breed [DayHikers Dayhiker]
breed [nodes node]
breed [initializers initializer]
patches-own [ patch-trail-number capacity-shelter capacity-camping patch-elevation shelter-here shelter-name shelter-number centerline-here parking-here distance-to-next-nb distance-to-next-sb illegal-camping-nb illegal-camping-sb] ;note: unused variables here from previous versions
turtles-own [ next-node demographic experience-level group time-on-trail journey-length speed direction energy distancecalculator at-camp distance-to-next-calculator trail-number-counter shelter-number-counter]
nodes-own [elevation trail-number node-shelter-here node-shelter-name node-distance-to-next-nb node-distance-to-next-sb slope-nb slope-sb]
extensions [ gis csv bitmap ]


to setup
  clear-all
  reset-ticks
  set shelters gis:load-dataset "data/VA_shelters_aug.shp" ;Campsite locations
  set centerline gis:load-dataset "data/VA_ele_pts4.shp"  ;Trail centerline
  set parking gis:load-dataset "data/VAs_at_parking.shp"  ;Parking locations

  ;envelope expansion code adapted from http://netlogo-users.18673.x6.nabble.com/Padding-A-GIS-World-Envelope-To-Prevent-Turtles-From-Extending-Over-Edge-td4861956.html
  ;slightly expands world to prevent an error with agent behavior at edges of world envelope
  let centerline-envelope gis:envelope-of centerline
  let x-expansion (item 1 centerline-envelope - item 0 centerline-envelope) * 0.0001
  let y-expansion (item 3 centerline-envelope - item 2 centerline-envelope) * 0.0001
  let expanded-envelope (list (item 0 centerline-envelope - x-expansion) (item 1 centerline-envelope + x-expansion) (item 2 centerline-envelope - y-expansion) (item 3 centerline-envelope + y-expansion))
  gis:set-world-envelope expanded-envelope


  set kilometer ( world-height / 430.931 ) ; calculates how big 1km is in patch units. Virginia study area is 430x430km. CHANGE THIS IF YOU CHANGE MAP EXTENT
  set day 1
  set day-of-week "Monday" ;Calendar non-functional; for cosmetic purposes only
  set month "January"

end


to draw
  clear-drawing
  reset-ticks
  ;ask patches [set pcolor green]
  import-pcolors "data/Virginia_background.png" ;sets pretty background image
  ask patches with [pxcor = 140] [set pcolor blue] ;sets "Area" visual border
  ask patches with [pxcor = -140] [set pcolor blue]
  ask patches with [pxcor = 0] [set pcolor blue]
  ask patches [if gis:intersects? parking self [set parking-here 1 set pcolor gray]] ;creates parking lots
  foreach gis:feature-list-of centerline ;creates trail centerline as a series of connected nodes in ascending ID number
  [ ?1 ->
    let centroid gis:location-of gis:centroid-of ?1
    if not empty? centroid
    [
      create-nodes 1
      [
        set xcor item 0 centroid
        set ycor item 1 centroid
        set centerline-here 1
        set color black
        set shape "circle"
        set size 0.1
        set elevation gis:property-value ?1 "Elevation"
        set trail-number gis:property-value ?1 "Id"
      ]
    ]
  ]
  let temp-max-trail max-one-of nodes [trail-number]
  let max-trail [trail-number] of temp-max-trail
  ask nodes with [trail-number < max-trail] ;creates northbound links between nodes to direct agent northbound movement. Adapted from Uri Wilensky's Link-Walking Turtles Example in the Netlogo model library.
  [
    let templink trail-number
    create-link-with one-of other nodes with [trail-number = templink + 1 ]
    set slope-nb (( [elevation] of node (templink + 1) - elevation ) / ( (distance node (templink + 1)) * 1000 / kilometer ) ) ;calculates slope northbound
  ]
    ask nodes with [trail-number > 0] ;creates souththbound links between nodes to direct agent southbound movement.Adapted from Uri Wilensky's Link-Walking Turtles Example in the Netlogo model library.
  [
    let templink trail-number
    create-link-with one-of other nodes with [trail-number = templink - 1 ]
    set slope-sb (( [elevation] of node (templink - 1) - elevation ) / ( (distance node (templink - 1)) * 1000 / kilometer ) ) ;calculates slope southbound
  ]
  ask links [ set thickness 0.3 set color black]
  foreach gis:feature-list-of shelters ;creates campsites
  [ ?1 ->
    let centroid2 gis:location-of gis:centroid-of ?1
    if not empty? centroid2
    [
      create-initializers 1
      [
        set xcor item 0 centroid2
        set ycor item 1 centroid2
      ]
      ask initializers
      [
        ask min-one-of nodes [ distance myself ] ;sets campsite location as at nearest node to GIS campsite location (shelters aren't always exctly on the centerline)
        [
          set node-shelter-here 1
          set color red
          set size 1
          set node-shelter-name gis:property-value ?1 "NAME" ;imports shelter "Name" field
        ]
        die
      ]
    ]
  ]
  if Labels?
    [
      ask nodes with [node-shelter-here = 1 ][ set label-color black set label node-shelter-name ] ;creates large, obnoxious unformatted campsite name labels
    ]
end


to initialize ;creates a pace-setting turtle that runs the whole trail, calculating the distance (northbound and southbound) between campsites
  create-SectionHikers 1
    [
      set distancecalculator 0
      set distance-to-next-calculator 0
      set speed 10
      set direction 1
      set next-node min-one-of nodes [trail-number]
    ]
  ask SectionHikers
  [
    move-to next-node
    let templink [trail-number] of next-node
    set next-node node (templink + direction)
  ]
  while [ count nodes with [node-distance-to-next-nb = 0] > 1 ]
  [
    ask SectionHikers
    [
      let speedcalc speed
      while [speedcalc > 0]
      [
        if distance next-node = 0
        [

            let temp-distance-to-next-calculator distance-to-next-calculator
            ifelse direction = 1
            [
              ask next-node
              [
                set node-distance-to-next-sb temp-distance-to-next-calculator
              ]
            ]
            [
              ask next-node
              [
                set node-distance-to-next-nb temp-distance-to-next-calculator
              ]
            ]
            if [node-shelter-here] of next-node = 1
            [
              set distance-to-next-calculator 0
            ]
          let templink [trail-number] of next-node
          ifelse (templink = [trail-number] of max-one-of nodes [trail-number] or templink = 0)
          [
            set direction (direction * -1)
            set next-node node (templink + direction)
          ]
          [
            set next-node node (templink + direction)
          ]
        ]
        face next-node
        ifelse distance next-node >= speedcalc
        [
          fd speedcalc
          set distance-to-next-calculator distance-to-next-calculator + speedcalc
          set speedcalc 0
        ]
        [
          set speedcalc (speedcalc - distance next-node)
          set distance-to-next-calculator distance-to-next-calculator + distance next-node
          move-to next-node
        ]
      ]
    ]
  ]
  ask SectionHikers
  [
    die
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to go ;continuous loop of adding hikers, hiking, removing hikers, camping, and updating global variables:

  add-hiker
  ask OvernightHikers [node-hike set energy energy - 1]
  ask SectionHikers [node-hike set energy energy - 1]
  endhike
  ask OvernightHikers [camp]
  ask SectionHikers [camp]
  set-mean-speeds
  set-mean-groups
  set-mean-distance
  set-mean-journey-length
  tick
  set-time
  ifelse Labels? ;toggles large, obnoxious unformatable campsite name labels
    [
      ask nodes with [node-shelter-here = 1 ][ set label-color black set label node-shelter-name ]
    ]
    [
      ask nodes with [node-shelter-here = 1 ][ set label "" ]
    ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to add-hiker ;every 10 minutes between 7 AM and 2 PM asks random parking locations on the trail to add a new hiker
 if (remainder minute 10 = 0 and hour > 7 and hour < 14)
 [
   ask n-of 2 patches with [parking-here = 1]
  [
let OvernighthikersCount count OvernightHikers ;hacky code to avoid dividing by zero in the next step
let SectionhikersCount count SectionHikers
if SectionhikersCount = 0 [set SectionhikersCount 1]
if OvernighthikersCount = 0 [set OvernighthikersCount 1]

    ifelse ( 100 * OvernighthikersCount / ( OvernighthikersCount + SectionhikersCount ) ) > Percent-Overnight-vs-Section-Hikers ;spawns hiker type based on slider input and ratio of hikers already in the system
    [
      sprout-SectionHikers 1 ;sets parameters for Section Hikers
      [
        set shape "person"
        set experience-level experience-levels ["SectionHiker"]
        set group group-size ["SectionHiker"]
        set speed ( 1.15 * ( random-normal experience-level  0.1 ) ) ;sets speed multiplier to 110% of a normal distribution with mean of the experience multiplier and standard deviation 0.1
        set color red
        set time-on-trail 0
        set journey-length (random-normal 24 5) ;sets journey length
        set distancecalculator 0
        set trail-number-counter 0
        set at-camp 0
        set energy daily-energy; * experience-level * 1.2) ;possibility to explore different levels of starting energy
        set next-node min-one-of nodes [distance myself]
        ifelse random 100 < Percent-Northbound ;sets direction of travel
        [
          set direction 1
        ]
        [
          set direction -1
        ]
        move-to next-node
      ]
    ]
    [
      sprout-OvernightHikers 1 ; sets parameters for Overnight Hikers
      [
        set shape "person"
        set experience-level experience-levels ["OvernightHiker"]
        set group group-size ["OvernightHiker"]
        set speed ( 0.8 * random-normal experience-level  0.1 ) ;sets speed multiplier to a normal distribution with mean of the experience multiplier and standard deviation 0.1
        set color blue
        set time-on-trail 0
        set journey-length (1 + (random-poisson 3)) ;sets journey length
        set distancecalculator 0
        set trail-number-counter 0
        set at-camp 0
        set energy daily-energy; * experience-level) ;possibility to explore different levels of starting energy
        set next-node min-one-of nodes [distance myself]
        ifelse random 100 < Percent-Northbound ;sets direction of travel
        [
          set direction 1
        ]
        [
          set direction -1
        ]
        move-to next-node
      ]
    ]
  ]
 ]
end


to-report experience-levels [ hiker-type ]
  ifelse experience?
  [
  let randexp random 100
  ifelse hiker-type = "SectionHiker";Sets Section hiker experience levels per Manning survey
    [
      ifelse randexp < 3
        [
          report 0.8 ;"Beginner"
        ]
        [
          ifelse (randexp >= 3) and (randexp < 6)
          [
          report 0.9 ;"Intermediate"
          ]
          [
            ifelse (randexp >= 6) and (randexp < 27)
            [
              report 1 ;"Skilled"
            ]
            [
              ifelse (randexp >= 27) and (randexp < 84)
              [
                report 1.1 ;"Advanced"
              ]
              [
                report 1.2 ;"Expert"
              ]
            ]
          ]
        ]
    ]
    [
      ifelse randexp < 8   ;Sets Overnight hiker experience levels per Manning survey
        [
          report 0.8 ;"Beginner"
        ]
        [
          ifelse (randexp >= 8) and (randexp < 18)
          [
          report 0.9 ;"Intermediate"
          ]
          [
            ifelse (randexp >= 18) and (randexp < 48)
            [
              report 1 ;"Skilled"
            ]
            [
              ifelse (randexp >= 48) and (randexp < 89)
              [
                report 1.1 ;"Advanced"
              ]
              [
                report 1.2 ;"Expert"
              ]
            ]
          ]
        ]
      ]
  ]
  [
    report 1
  ]
end

to-report group-size [ hiker-type ]
  ifelse groups?
  [
  let randexp random 100
  ifelse hiker-type = "SectionHiker";Sets Section hiker group size per Manning survey
    [
      ifelse randexp < 40
        [
          report 1
        ]
        [
          ifelse (randexp >= 40) and (randexp < 80)
          [
          report 2
          ]
          [
            ifelse (randexp >= 80) and (randexp < 90)
            [
              report 3
            ]
            [
              ifelse (randexp >= 90) and (randexp < 91)
              [
                report 4
              ]
              [
                ifelse (randexp >= 91) and (randexp < 92)
                [
                  report 5
                ]
                [
                  ifelse (randexp >= 92) and (randexp < 95)
                  [
                    report 6
                  ]
                  [
                    ifelse (randexp >= 95) and (randexp < 96)
                    [
                      report 7
                    ]
                    [
                      ifelse (randexp >= 96) and (randexp < 97)
                      [
                        report 8
                      ]
                      [
                        ifelse (randexp >= 98) and (randexp < 99)
                        [
                          report 9
                        ]
                        [
                          report 10
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
    ]
    [
      ifelse randexp < 17 ;Sets Overnight hiker group size per Manning survey
        [
          report 1
        ]
        [
          ifelse (randexp >= 17) and (randexp < 56)
          [
          report 2
          ]
          [
            ifelse (randexp >= 56) and (randexp < 70)
            [
              report 3
            ]
            [
              ifelse (randexp >= 70) and (randexp < 78)
              [
                report 4
              ]
              [
                ifelse (randexp >= 78) and (randexp < 82)
                [
                  report 5
                ]
                [
                  ifelse (randexp >= 82) and (randexp < 87)
                  [
                    report 6
                  ]
                  [
                    ifelse (randexp >= 87) and (randexp < 88)
                    [
                      report 7
                    ]
                    [
                      ifelse (randexp >= 88) and (randexp < 91)
                      [
                        report 8
                      ]
                      [
                        ifelse (randexp >= 91) and (randexp < 92)
                        [
                          report 9
                        ]
                        [
                          report 10
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
    ]
  ]
  [
    report 1
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to node-hike
  if at-camp = 0
  [
    let speedcalc ( speed * 5 / ( 60 * kilometer ) ) ;sets base speed to 5kph adjusted for minutes and for patch size, and multiplied by Speed Multiplier

;;;;;;;;;;;;;;;;;;;;;;;;TOBLER FUNCTION;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      if Tobler? ;uses northbound or southbound slope to calculate speed, adjusted for minutes and for patch size, and multiplied by Speed Multiplier
      [
        ifelse direction = 1
        [
          set speedcalc (speed * Tobler-value [slope-nb] of next-node / ( 60 * kilometer ))
        ]
        [
          set speedcalc (speed * Tobler-value [slope-sb] of next-node / ( 60 * kilometer ))
        ]
      ]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    while [speedcalc > 0]
    [
      if distance next-node = 0
      [
        if [node-shelter-here] of next-node = 1 ;if node is a campsite, hiker decides if they need to camp
        [
          decide-camp-or-continue
        ]
        let templink [trail-number] of next-node
        ifelse (templink = [trail-number] of max-one-of nodes [trail-number] or templink = 0) ;At edge of map, Section Hikers are removed and Overnight Hikers turn around
        [
          if breed = SectionHikers
          [
            die
          ]
          set direction (direction * -1)
          set next-node node (templink + direction) ;updates new destination node in direction of travel
        ]
        [
          set next-node node (templink + direction) ;updates new destination node in direction of travel
        ]
      ]
      face next-node
      ifelse distance next-node >= speedcalc ;move towards next node in direction of travel
      [
        fd speedcalc
        set trail-number-counter trail-number-counter + speedcalc
        set speedcalc 0
      ]
      [ ;if agent has a higher speed than the distance to the next node, continue to that node and loop to finish using rest of movement for the turn
        set speedcalc (speedcalc - distance next-node)
        set trail-number-counter trail-number-counter + distance next-node
        move-to next-node
      ]
    ]
  ]
end


to-report Tobler-value [ slope ] ;reports Tobler's hiking function
  report 6 * exp (-3.5 * abs ( slope + 0.05 ))
end


to endhike ;hikers removed at the end of their journey length (-1 because length is in "days" but system counts "nights"
  ask OvernightHikers [if time-on-trail >= (journey-length - 1) [die]]
  ;ask OvernightHikers [if time-on-trail >= (journey-length / 2)[set direction direction * -1]] ;possibility to experiment with Overnight Hikers turning around at the halfway point of their journey. Doesn't work properly.
  ask SectionHikers [if time-on-trail >= (journey-length - 1) [die]]
end



to decide-camp-or-continue ;whenever a hiker reaches a node, they decide whether to camp or continue...
    if (hour > 11) ;...but only after 11 AM. Otherwise they'll never leave if distance to the next campsite is farther than they can travel in a day
    [
      if (direction = 1) and ((energy *  (speed * 5 / ( 60 * kilometer ))) <= [node-distance-to-next-nb] of next-node) ;if distance to next campsite is further than remaining energy, camp at the present campsite
      [
        set at-camp 1
        set shape "campsite"
        set global-legal-camping global-legal-camping + 1
        ifelse breed = overnighthikers ;counts legal hiking by demographic categories
        [
          set global-legal-camping-overnighthiker global-legal-camping-overnighthiker + 1
        ]
        [
          set global-legal-camping-sectionhiker global-legal-camping-sectionhiker + 1
        ]
        if experience-level = 0.8
          [
            set global-legal-camping-beginner global-legal-camping-beginner + 1
          ]
        if experience-level = 0.9
          [
            set global-legal-camping-intermediate global-legal-camping-intermediate + 1
          ]
        if experience-level = 1
          [
            set global-legal-camping-skilled global-legal-camping-skilled + 1
          ]
        if experience-level = 1.1
          [
            set global-legal-camping-advanced global-legal-camping-advanced + 1
          ]
        if experience-level = 1.2
          [
            set global-legal-camping-expert global-legal-camping-expert + 1
          ]
      ]
      if (direction = -1) and ((energy *  (speed * 5 / ( 60 * kilometer ))) <= [node-distance-to-next-sb] of next-node) ;same as above but for southbound hikers
      [
        set at-camp 1
        set shape "campsite"
        set global-legal-camping global-legal-camping + 1
        ifelse breed = overnighthikers
        [
          set global-legal-camping-overnighthiker global-legal-camping-overnighthiker + 1
        ]
        [
          set global-legal-camping-sectionhiker global-legal-camping-sectionhiker + 1
        ]
        if experience-level = 0.8
          [
            set global-legal-camping-beginner global-legal-camping-beginner + 1
          ]
        if experience-level = 0.9
          [
            set global-legal-camping-intermediate global-legal-camping-intermediate + 1
          ]
        if experience-level = 1
          [
            set global-legal-camping-skilled global-legal-camping-skilled + 1
          ]
        if experience-level = 1.1
          [
            set global-legal-camping-advanced global-legal-camping-advanced + 1
          ]
        if experience-level = 1.2
          [
            set global-legal-camping-expert global-legal-camping-expert + 1
          ]
      ]
    ]
end



to camp
  if hour = 7 ;hikers wake up at 7 AM and energy level resets
  [
    set at-camp 0
    set shape "person"
    set energy daily-energy
    set trail-number-counter 0
  ]
  if at-camp = 0
    [
      if ((energy <= 0) or (hour >= 21)) ;hikers camp wherever they are if they run out of energy or time is 9PM...
      [
        if distance min-one-of nodes with [ node-shelter-here = 1 ] [distance myself] > 1.5 ;...unless they are within 1.5 patch lengths of the next campsite, in which case they continue
        [
          set at-camp 1
          set shape "campsite"
          ifelse direction = 1
          [
            ifelse group mod 2 = 0 [ set illegal-camping-nb illegal-camping-nb + (group / 2)][ set illegal-camping-nb illegal-camping-nb + (0.5 + group / 2) ] ;bigger groups cause bigger impact. Assumes 2 people per tent.
            set global-illegal-camping-nb global-illegal-camping-nb + 1
            set global-illegal-camping-nb-distance global-illegal-camping-nb-distance + [node-distance-to-next-nb] of next-node
            set global-illegal-camping-nb-distance-from-previous global-illegal-camping-nb-distance-from-previous + [node-distance-to-next-sb] of next-node
          ]
          [
            ifelse group mod 2 = 0 [ set illegal-camping-sb illegal-camping-sb + (group / 2)][ set illegal-camping-sb illegal-camping-sb + (0.5 + group / 2) ]
            set global-illegal-camping-sb global-illegal-camping-sb + 1
            set global-illegal-camping-sb-distance global-illegal-camping-sb-distance + [node-distance-to-next-sb] of next-node
            set global-illegal-camping-sb-distance-from-previous global-illegal-camping-sb-distance-from-previous + [node-distance-to-next-nb] of next-node
          ]
          ifelse breed = overnighthikers ;counts illegal hiking by demographic categories
          [
            set global-illegal-camping-overnighthiker global-illegal-camping-overnighthiker + 1
          ]
          [
            set global-illegal-camping-sectionhiker global-illegal-camping-sectionhiker + 1
          ]

          if experience-level = 0.8
          [
            set global-illegal-camping-beginner global-illegal-camping-beginner + 1
          ]
          if experience-level = 0.9
          [
            set global-illegal-camping-intermediate global-illegal-camping-intermediate + 1
          ]
          if experience-level = 1
          [
            set global-illegal-camping-skilled global-illegal-camping-skilled + 1
          ]
          if experience-level = 1.1
          [
            set global-illegal-camping-advanced global-illegal-camping-advanced + 1
          ]
          if experience-level = 1.2
          [
            set global-illegal-camping-expert global-illegal-camping-expert + 1
          ]
          set global-illegal-camping global-illegal-camping + 1
          if (illegal-camping-nb + illegal-camping-sb) >= 5
          [
            set pcolor scale-color yellow (illegal-camping-nb + illegal-camping-sb) 0 20 ;shades patches yellow when illegal camping takes place
          ]
        ]
      ]
    ]
end


to set-mean-speeds ;adapted from RBSim.X (NetLogo 5.0.3), RBSim (Gimblett, et al , 2002), replicated and re-implemented by Thomas Dover, March, 2015
if count OvernightHikers > 0 [set m-o-speed precision (mean [speed] of OvernightHikers) 1]
if count SectionHikers > 0 [set m-s-speed precision (mean [speed] of SectionHikers) 1]
;if count ThruHikers > 0 [set m-t-speed precision (mean [speed] of ThruHikers) 1]
;if count DayHikers > 0 [set m-d-speed precision (mean [speed] of DayHikers) 1]
end

to set-mean-groups ;adapted from RBSim.X (NetLogo 5.0.3), RBSim (Gimblett, et al , 2002), replicated and re-implemented by Thomas Dover, March, 2015
if count OvernightHikers > 0 [set m-o-group precision (mean [group] of OvernightHikers) 1]
if count SectionHikers > 0 [set m-s-group precision (mean [group] of SectionHikers) 1]
;if count ThruHikers > 0 [set m-t-group precision (mean [group] of ThruHikers) 1]
;if count DayHikers > 0 [set m-d-group precision (mean [group] of DayHikers) 1]
end

to set-mean-distance ;adapted from RBSim.X (NetLogo 5.0.3), RBSim (Gimblett, et al , 2002), replicated and re-implemented by Thomas Dover, March, 2015
if count OvernightHikers > 0 [set m-o-distance precision (mean [trail-number-counter] of OvernightHikers / kilometer) 1]
if count SectionHikers > 0 [set m-s-distance precision (mean [trail-number-counter] of SectionHikers / kilometer) 1]
;if count ThruHikers > 0 [set m-t-distance precision (mean [trail-number-counter] of ThruHikers / kilometer) 1]
;if count DayHikers > 0 [set m-d-distance precision (mean [trail-number-counter] of DayHikers / kilometer ) 1]
end

to set-mean-journey-length ;adapted from RBSim.X (NetLogo 5.0.3), RBSim (Gimblett, et al , 2002), replicated and re-implemented by Thomas Dover, March, 2015
if count OvernightHikers > 0 [set m-o-journey precision (mean [journey-length] of OvernightHikers) 1]
if count SectionHikers > 0 [set m-s-journey precision (mean [journey-length] of SectionHikers) 1]
;if count ThruHikers > 0 [set m-t-journey precision (mean [journey-length] of ThruHikers) 1]
;if count DayHikers > 0 [set m-d-journey precision (mean [journey-length] of DayHikers) 1]
end

to set-time ;updates the clock
  set minute minute + 1
  if minute = 60
  [
  set hour hour + 1
  set minute 0
  ]
    if hour = 24
  [
  set day day + 1
  if day-of-week = "Sunday"
  [
    set day-of-week "Monday"
  ]
    if day-of-week = "Saturday"
  [
    set day-of-week "Sunday"
  ]
    if day-of-week = "Friday"
  [
    set day-of-week "Saturday"
  ]
    if day-of-week = "Thursday"
  [
    set day-of-week "Friday"
  ]
    if day-of-week = "Wednesday"
  [
    set day-of-week "Thursday"
  ]
    if day-of-week = "Tuesday"
  [
    set day-of-week "Wednesday"
  ]
    if day-of-week = "Monday"
  [
    set day-of-week "Tuesday"
  ]
  set hour 0
  ask SectionHikers [set time-on-trail time-on-trail + 1]
  ask OvernightHikers [set time-on-trail time-on-trail + 1]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
215
10
861
657
-1
-1
1.11734
1
10
1
1
1
0
0
0
1
-285
285
-285
285
0
0
1
minutes
30.0

BUTTON
147
48
210
81
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
147
84
210
117
draw
draw
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
147
156
210
189
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

PLOT
869
128
1242
278
Hiker Types
NIL
agents
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total" 1.0 0 -16777216 true "" "plot count SectionHikers + count OvernightHikers"
"Section Hikers" 1.0 0 -2674135 true "" "plot count SectionHikers"
"Overnight Hikers" 1.0 0 -13345367 true "" "plot count OvernightHikers"

SLIDER
869
90
1263
123
Percent-Overnight-vs-Section-Hikers
Percent-Overnight-vs-Section-Hikers
0
100
68.0
1
1
Percent Overnight Hikers
HORIZONTAL

MONITOR
799
38
856
83
Day
day
0
1
11

MONITOR
571
38
628
83
Minute
Minute
0
1
11

MONITOR
514
38
571
83
Hour
Hour
0
1
11

MONITOR
716
38
797
83
Month
Month
0
1
11

MONITOR
629
38
714
83
Day of Week
Day-of-week
0
1
11

SLIDER
868
54
1040
87
Percent-Northbound
Percent-Northbound
0
100
50.0
1
1
NIL
HORIZONTAL

BUTTON
147
120
210
153
initialize
initialize
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
1044
54
1216
87
Daily-energy
Daily-energy
0
1000
500.0
20
1
NIL
HORIZONTAL

SWITCH
870
284
1022
317
experience?
experience?
0
1
-1000

PLOT
870
321
1243
471
Experience levels
NIL
agents
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Expert" 1.0 0 -5825686 true "" "plot count turtles with [experience-level = 1.2]"
"Advanced" 1.0 0 -955883 true "" "plot count turtles with [experience-level = 1.1]"
"Skilled" 1.0 0 -1184463 true "" "plot count turtles with [experience-level = 1]"
"Intermediate" 1.0 0 -10899396 true "" "plot count turtles with [experience-level = 0.9]"
"Beginner" 1.0 0 -6459832 true "" "plot count turtles with [experience-level = 0.8]"

SWITCH
1247
286
1350
319
groups?
groups?
0
1
-1000

PLOT
1247
320
1502
470
Mean Group Size
NIL
People
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Overnightl Hikers" 1.0 0 -13345367 true "" "plot m-o-group"
"Section Hikers" 1.0 0 -2674135 true "" "plot m-s-group"

SWITCH
868
18
971
51
Tobler?
Tobler?
0
1
-1000

PLOT
870
476
1242
626
Mean Daily Distance Traveled
NIL
KM
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Overnight Hiers" 1.0 0 -13345367 true "" "plot m-o-distance"
"Section Hikers" 1.0 0 -2674135 true "" "plot m-s-distance"

PLOT
539
470
851
671
% unregulated camping
NIL
NIL
0.0
10.0
0.0
30.0
true
true
"" ""
PENS
"All Hikers" 1.0 0 -16777216 true "" "if global-legal-camping > 0 [plot (global-illegal-camping * 100 / (global-legal-camping + global-illegal-camping))]"
"Section" 1.0 0 -2674135 true "" "if global-legal-camping-sectionhiker > 0 [plot (global-illegal-camping-sectionhiker * 100 / (global-legal-camping-sectionhiker + global-illegal-camping-sectionhiker))]"
"Overnight" 1.0 0 -13345367 true "" "if global-legal-camping-overnighthiker > 0 [plot (global-illegal-camping-overnighthiker * 100 / (global-legal-camping-overnighthiker + global-illegal-camping-overnighthiker))]"
"Expert" 1.0 0 -5825686 true "" "if global-legal-camping-expert > 0 [plot (global-illegal-camping-expert * 100 / (global-legal-camping-expert + global-illegal-camping-expert))]"
"Advanced" 1.0 0 -955883 true "" "if global-legal-camping-advanced > 0 [plot (global-illegal-camping-advanced * 100 / (global-legal-camping-advanced + global-illegal-camping-advanced))]"
"Skilled" 1.0 0 -1184463 true "" "if global-legal-camping-skilled > 0 [plot (global-illegal-camping-skilled * 100 / (global-legal-camping-skilled + global-illegal-camping-skilled))]"
"Intermediate" 1.0 0 -10899396 true "" "if global-legal-camping-intermediate > 0 [plot (global-illegal-camping-intermediate * 100 / (global-legal-camping-intermediate + global-illegal-camping-intermediate))]"
"Beginner" 1.0 0 -6459832 true "" "if global-legal-camping-beginner > 0 [plot (global-illegal-camping-beginner * 100 / (global-legal-camping-beginner + global-illegal-camping-beginner))]"

SWITCH
54
253
157
286
Labels?
Labels?
1
1
-1000

PLOT
1246
476
1503
626
Mean Journey Length
NIL
Days
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Overnight Hikers" 1.0 0 -13345367 true "" "plot m-o-journey"
"Section Hikers" 1.0 0 -2674135 true "" "plot m-s-journey"

MONITOR
24
330
104
375
Southbound
global-illegal-camping-sb-distance
0
1
11

MONITOR
114
331
193
376
Northbound
global-illegal-camping-nb-distance
0
1
11

PLOT
10
380
210
571
Avg distance between campsites
NIL
KM
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"SB to next" 1.0 0 -955883 true "" "if global-illegal-camping-sb-distance > 0 [plot ((global-illegal-camping-sb-distance / global-illegal-camping-sb) / kilometer )]"
"NB to next" 1.0 0 -14835848 true "" "if global-illegal-camping-nb-distance > 0 [plot ((global-illegal-camping-nb-distance / global-illegal-camping-nb) / kilometer )]"
"SB from previous" 1.0 0 -2674135 true "" "if global-illegal-camping-sb-distance-from-previous > 0 [plot ((global-illegal-camping-sb-distance-from-previous / global-illegal-camping-sb) / kilometer )]"
"NB from previous" 1.0 0 -13345367 true "" "if global-illegal-camping-nb-distance-from-previous > 0 [plot ((global-illegal-camping-nb-distance-from-previous / global-illegal-camping-nb) / kilometer )]"

TEXTBOX
286
116
436
134
Area 1
11
0.0
1

TEXTBOX
443
116
593
134
Area 2
11
0.0
1

TEXTBOX
604
115
754
133
Area 3
11
0.0
1

TEXTBOX
760
116
910
136
Area 4
11
0.0
1

TEXTBOX
29
312
196
342
Unregulated Camping analysis:
12
0.0
1

MONITOR
248
132
360
177
Bootleg campsites
count patches with [illegal-camping-nb + illegal-camping-sb >= 5 and pxcor < -140]
0
1
11

MONITOR
404
131
516
176
Bootleg campsites
count patches with [illegal-camping-nb + illegal-camping-sb >= 5 and pxcor < 0 and pxcor >= -140]
0
1
11

MONITOR
564
131
676
176
Bootleg campsites
count patches with [illegal-camping-nb + illegal-camping-sb >= 5 and pxcor >= 0 and pxcor < 140]
0
1
11

MONITOR
722
131
834
176
Bootleg campsites
count patches with [illegal-camping-nb + illegal-camping-sb >= 5 and pxcor >= 140]
0
1
11

TEXTBOX
48
16
198
43
MARCH-ON
22
0.0
1

TEXTBOX
236
49
251
83
↑ \nN
14
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

campsite
false
0
Polygon -7500403 true true 150 11 30 221 270 221
Polygon -16777216 true false 151 90 92 221 212 221
Line -7500403 true 150 30 150 225

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
  <experiment name="baseline" repetitions="10" runMetricsEveryStep="false">
    <setup>setup
draw
initialize</setup>
    <go>go</go>
    <timeLimit steps="20160"/>
    <metric>global-legal-camping</metric>
    <metric>global-legal-camping-overnighthiker</metric>
    <metric>global-legal-camping-sectionhiker</metric>
    <metric>global-illegal-camping</metric>
    <metric>global-illegal-camping-sb</metric>
    <metric>global-illegal-camping-sb-distance</metric>
    <metric>global-illegal-camping-nb</metric>
    <metric>global-illegal-camping-nb-distance</metric>
    <metric>global-illegal-camping-overnighthiker</metric>
    <metric>global-illegal-camping-sectionhiker</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 140]</metric>
    <enumeratedValueSet variable="Daily-energy">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Northbound">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tobler?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Overnight-vs-Section-Hikers">
      <value value="66"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experience?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="groups?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="revised baseline" repetitions="20" runMetricsEveryStep="false">
    <setup>setup
draw
initialize</setup>
    <go>go</go>
    <timeLimit steps="43829"/>
    <metric>global-legal-camping</metric>
    <metric>global-legal-camping-overnighthiker</metric>
    <metric>global-legal-camping-sectionhiker</metric>
    <metric>global-legal-camping-beginner</metric>
    <metric>global-legal-camping-intermediate</metric>
    <metric>global-legal-camping-skilled</metric>
    <metric>global-legal-camping-advanced</metric>
    <metric>global-legal-camping-expert</metric>
    <metric>global-illegal-camping</metric>
    <metric>global-illegal-camping-sb</metric>
    <metric>global-illegal-camping-sb-distance</metric>
    <metric>global-illegal-camping-sb-distance-from-previous</metric>
    <metric>global-illegal-camping-nb</metric>
    <metric>global-illegal-camping-nb-distance</metric>
    <metric>global-illegal-camping-nb-distance-from-previous</metric>
    <metric>global-illegal-camping-overnighthiker</metric>
    <metric>global-illegal-camping-sectionhiker</metric>
    <metric>global-illegal-camping-beginner</metric>
    <metric>global-illegal-camping-intermediate</metric>
    <metric>global-illegal-camping-skilled</metric>
    <metric>global-illegal-camping-advanced</metric>
    <metric>global-illegal-camping-expert</metric>
    <metric>(global-illegal-camping * 100 / (global-legal-camping + global-illegal-camping))</metric>
    <metric>(global-illegal-camping-sectionhiker * 100 / (global-legal-camping-sectionhiker + global-illegal-camping-sectionhiker))</metric>
    <metric>(global-illegal-camping-overnighthiker * 100 / (global-legal-camping-overnighthiker + global-illegal-camping-overnighthiker))</metric>
    <metric>(global-illegal-camping-expert * 100 / (global-legal-camping-expert + global-illegal-camping-expert))</metric>
    <metric>(global-illegal-camping-advanced * 100 / (global-legal-camping-advanced + global-illegal-camping-advanced))</metric>
    <metric>(global-illegal-camping-skilled * 100 / (global-legal-camping-skilled + global-illegal-camping-skilled))</metric>
    <metric>(global-illegal-camping-intermediate * 100 / (global-legal-camping-intermediate + global-illegal-camping-intermediate))</metric>
    <metric>(global-illegal-camping-beginner * 100 / (global-legal-camping-beginner + global-illegal-camping-beginner))</metric>
    <metric>((global-illegal-camping-nb-distance / global-illegal-camping-nb) / kilometer )</metric>
    <metric>((global-illegal-camping-sb-distance / global-illegal-camping-sb) / kilometer )</metric>
    <metric>((global-illegal-camping-nb-distance-from-previous / global-illegal-camping-nb) / kilometer )</metric>
    <metric>((global-illegal-camping-sb-distance-from-previous / global-illegal-camping-sb) / kilometer )</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &gt;= 140]</metric>
    <enumeratedValueSet variable="Daily-energy">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Northbound">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tobler?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Overnight-vs-Section-Hikers">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experience?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="groups?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="revised baseline Tobler sweep" repetitions="10" runMetricsEveryStep="false">
    <setup>setup
draw
initialize</setup>
    <go>go</go>
    <timeLimit steps="43829"/>
    <metric>global-legal-camping</metric>
    <metric>global-legal-camping-overnighthiker</metric>
    <metric>global-legal-camping-sectionhiker</metric>
    <metric>global-legal-camping-beginner</metric>
    <metric>global-legal-camping-intermediate</metric>
    <metric>global-legal-camping-skilled</metric>
    <metric>global-legal-camping-advanced</metric>
    <metric>global-legal-camping-expert</metric>
    <metric>global-illegal-camping</metric>
    <metric>global-illegal-camping-sb</metric>
    <metric>global-illegal-camping-sb-distance</metric>
    <metric>global-illegal-camping-sb-distance-from-previous</metric>
    <metric>global-illegal-camping-nb</metric>
    <metric>global-illegal-camping-nb-distance</metric>
    <metric>global-illegal-camping-nb-distance-from-previous</metric>
    <metric>global-illegal-camping-overnighthiker</metric>
    <metric>global-illegal-camping-sectionhiker</metric>
    <metric>global-illegal-camping-beginner</metric>
    <metric>global-illegal-camping-intermediate</metric>
    <metric>global-illegal-camping-skilled</metric>
    <metric>global-illegal-camping-advanced</metric>
    <metric>global-illegal-camping-expert</metric>
    <metric>(global-illegal-camping * 100 / (global-legal-camping + global-illegal-camping))</metric>
    <metric>(global-illegal-camping-sectionhiker * 100 / (global-legal-camping-sectionhiker + global-illegal-camping-sectionhiker))</metric>
    <metric>(global-illegal-camping-overnighthiker * 100 / (global-legal-camping-overnighthiker + global-illegal-camping-overnighthiker))</metric>
    <metric>(global-illegal-camping-expert * 100 / (global-legal-camping-expert + global-illegal-camping-expert))</metric>
    <metric>(global-illegal-camping-advanced * 100 / (global-legal-camping-advanced + global-illegal-camping-advanced))</metric>
    <metric>(global-illegal-camping-skilled * 100 / (global-legal-camping-skilled + global-illegal-camping-skilled))</metric>
    <metric>(global-illegal-camping-intermediate * 100 / (global-legal-camping-intermediate + global-illegal-camping-intermediate))</metric>
    <metric>(global-illegal-camping-beginner * 100 / (global-legal-camping-beginner + global-illegal-camping-beginner))</metric>
    <metric>((global-illegal-camping-nb-distance / global-illegal-camping-nb) / kilometer )</metric>
    <metric>((global-illegal-camping-sb-distance / global-illegal-camping-sb) / kilometer )</metric>
    <metric>((global-illegal-camping-nb-distance-from-previous / global-illegal-camping-nb) / kilometer )</metric>
    <metric>((global-illegal-camping-sb-distance-from-previous / global-illegal-camping-sb) / kilometer )</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &gt;= 140]</metric>
    <enumeratedValueSet variable="Daily-energy">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Northbound">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tobler?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Overnight-vs-Section-Hikers">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experience?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="groups?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="revised baseline energy sweeps" repetitions="5" runMetricsEveryStep="false">
    <setup>setup
draw
initialize</setup>
    <go>go</go>
    <timeLimit steps="43829"/>
    <metric>global-legal-camping</metric>
    <metric>global-legal-camping-overnighthiker</metric>
    <metric>global-legal-camping-sectionhiker</metric>
    <metric>global-legal-camping-beginner</metric>
    <metric>global-legal-camping-intermediate</metric>
    <metric>global-legal-camping-skilled</metric>
    <metric>global-legal-camping-advanced</metric>
    <metric>global-legal-camping-expert</metric>
    <metric>global-illegal-camping</metric>
    <metric>global-illegal-camping-sb</metric>
    <metric>global-illegal-camping-sb-distance</metric>
    <metric>global-illegal-camping-sb-distance-from-previous</metric>
    <metric>global-illegal-camping-nb</metric>
    <metric>global-illegal-camping-nb-distance</metric>
    <metric>global-illegal-camping-nb-distance-from-previous</metric>
    <metric>global-illegal-camping-overnighthiker</metric>
    <metric>global-illegal-camping-sectionhiker</metric>
    <metric>global-illegal-camping-beginner</metric>
    <metric>global-illegal-camping-intermediate</metric>
    <metric>global-illegal-camping-skilled</metric>
    <metric>global-illegal-camping-advanced</metric>
    <metric>global-illegal-camping-expert</metric>
    <metric>(global-illegal-camping * 100 / (global-legal-camping + global-illegal-camping))</metric>
    <metric>(global-illegal-camping-sectionhiker * 100 / (global-legal-camping-sectionhiker + global-illegal-camping-sectionhiker))</metric>
    <metric>(global-illegal-camping-overnighthiker * 100 / (global-legal-camping-overnighthiker + global-illegal-camping-overnighthiker))</metric>
    <metric>(global-illegal-camping-expert * 100 / (global-legal-camping-expert + global-illegal-camping-expert))</metric>
    <metric>(global-illegal-camping-advanced * 100 / (global-legal-camping-advanced + global-illegal-camping-advanced))</metric>
    <metric>(global-illegal-camping-skilled * 100 / (global-legal-camping-skilled + global-illegal-camping-skilled))</metric>
    <metric>(global-illegal-camping-intermediate * 100 / (global-legal-camping-intermediate + global-illegal-camping-intermediate))</metric>
    <metric>(global-illegal-camping-beginner * 100 / (global-legal-camping-beginner + global-illegal-camping-beginner))</metric>
    <metric>((global-illegal-camping-nb-distance / global-illegal-camping-nb) / kilometer )</metric>
    <metric>((global-illegal-camping-sb-distance / global-illegal-camping-sb) / kilometer )</metric>
    <metric>((global-illegal-camping-nb-distance-from-previous / global-illegal-camping-nb) / kilometer )</metric>
    <metric>((global-illegal-camping-sb-distance-from-previous / global-illegal-camping-sb) / kilometer )</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 5 and pxcor &gt;= 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &lt; -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &lt; 0 and pxcor &gt;= -140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &gt;= 0 and pxcor &lt; 140]</metric>
    <metric>count patches with [illegal-camping-nb + illegal-camping-sb &gt;= 10 and pxcor &gt;= 140]</metric>
    <enumeratedValueSet variable="Daily-energy">
      <value value="100"/>
      <value value="300"/>
      <value value="700"/>
      <value value="900"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Northbound">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Labels?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Tobler?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Percent-Overnight-vs-Section-Hikers">
      <value value="68"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="experience?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="groups?">
      <value value="false"/>
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
