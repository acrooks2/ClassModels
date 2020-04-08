;; Pedestrian Modeling in Netlogo: Simulating the 2013 Boston Marathon Bombing
;;***************************************************************************************************************
;; This model was built to study impacts of several variables (crowd density, blast size, number of terrorists) *
;; on the impact of egress of bystanders and ingress of first responders.
;; The model employs the GIS package to ingest a map of the area and resize the world to the map, making each   *
;; pixel equal to a patch in the world.
;;
;;

globals [
    north-exeter-exit-counter
    south-exeter-exit-counter
    north-dartmouth-exit-counter
    south-dartmouth-exit-counter
    number-dead

  ] ;; this is for global variable declaration
turtles-own[
  fear
  myEscapePoint

  ] ;; this is for declaring variables that belong to turtles
patches-own[
   ptype ;; (type of patch: outside, structure, escape)
   elevation ;; (a property for determining how the turtles will leave the scene, an integer from 0 to 100)
   pre_blast_elevation;;
  ] ;; this is for declaring variables that belong to patches

breed [ bystanders bystander ]
breed [ runners runner ]
breed [ responders responder ]
breed [ terrorists terrorist ]
breed [dead-bystanders dead-bystander ]
breed [ emergency-vehicles emergency-vehicle ]


extensions [ gis ]

to load
  clear-all

  ;; I ended up taking a screenshot of a google maps image and making it my backdrop
  ;; The image is 2557 x 1206 so I have assigned 2 pixels per patch to make it 1278 x 603

  ;; I experimented with various sizes for the window to make it easy to be zoomed into
  ;; the area of most interest, the actual finish line of the race.
  ;; resize-world min-pxcor max-pxcor min-pycor max-pycor to center at 517 169
  ;; resize-world min-pxcor max-pxcor min-pycor max-pycor to center at 350 260

  resize-world -350 928 -275 328
  ;;resize-world 0 1278 0 603
  set-patch-size 2

  ;; **************************************************************************
  ;; THIS IS THE PATH YOU MUST CHANGE TO INCORPORATE THE IMAGE AS THE BACKDROP
  ;; **************************************************************************
  import-pcolors-rgb "Data/Boston_finish_rotated.png"

  ;; Set all patches to the same elevation and make them all 'walkable', later we
  ;; will turn various patches into buildings, so the agents cannot walk on them
  ask patches [
    set ptype "outside"
    set elevation 1500
  ]


  ;; Here we buld the actual structures, or set the elevations really high, and give the
  ;; patches that represent building, the type "structure"

  ;;
  ;; Build the North side of Boylston Street
  ;;
  ;; Build CVS building
  ask patches with [ pxcor >= 264 and pxcor <= 658 and pycor <= 197 and pycor >= 58 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation
  ]

  ;; Build AT&T and Old South Church
  ask patches with [ pxcor >= -174 and pxcor <= 204 and pycor <= 111 and pycor >= 54 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation
  ]
  ;; Build Nike building
  ask patches with [ pxcor >= -349 and pxcor <= -203 and pycor <= 185 and pycor >= 40 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation
  ]

  ;;
  ;; Build the South side of Boylston Street
  ;;
  ;; build the Boston Public Library
  ask patches with [ pxcor >= -156 and pxcor <= 181 and pycor <= -42 and pycor >= -202 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation

  ]

  ;; build the Medical tent on Dartmouth between Copley Square and the Boston Public LIbrary
  ask patches with [ pxcor >= 183 and pxcor <= 243 and pycor <= -42 and pycor >= -202 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation
    set pcolor red

  ]
  ;; label the Medical tent
  ask patch 230 -96
  [
    set plabel-color white
    set plabel "Medical Tent A"
  ]
  ;; draw the red cross symbol
  ask patches with [ pxcor >= 210 and pxcor <= 220 and pycor <= -100 and pycor >= -130 ]
  [
    set pcolor white
  ]
    ask patches with [ pxcor >= 200 and pxcor <= 230 and pycor <= -110 and pycor >= -120 ]
  [
    set pcolor white
  ]

  ;; Build the Lenox
   ask patches with [ pxcor >= -349 and pxcor <= -206 and pycor <= -20 and pycor >= -123 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation
  ]
   ask patches with [ pxcor >= -349 and pxcor <= -221 and pycor <= -215 and pycor >= -142 ]
  [
    set ptype "structure"
    set elevation 2000
    set pre_blast_elevation elevation
  ]


  ;;
  ;; define escape points
  ;;
  ;;ask patches with [pxcor = 294 and pycor = -220]
  ask patch 294 -220
  [
    set ptype "south-escape-point"
    set plabel-color black
    set plabel "south-escape-point"
    set pcolor orange
  ]
  ;;let south-escape-point patches with [ pxcor = 216 and pycor = -225 ]

  ;;let sw-escape-point one-of patches with ptype = "escape"
  ;;ask patches with [pxcor = -183 and pycor = -225]
  ask patch -183 -225
  [
    set ptype "southwest-escape-point"
    set plabel-color black
    set plabel "southwest-escape-point"
    set pcolor orange
  ]
 ;; let southwest-escape-point patches with [ pxcor = -183 and pycor = -225 ]

  ;;ask patches wit [pxcor = 716 and pycor = -225]
  ask patch 716 -225
  [
    set ptype "southeast-escape-point"
    set plabel-color black
    set plabel "southeast-escape-point"
    set pcolor orange
  ]
 ;; let southeast-escape-point patches with [ pxcor = 716 and pycor = -225 ]

 ;; ask patches with [pxcor = 716 and pycor = 210]
  ask patch 716 -225
  [
    set ptype "northeast-escape-point"
    set plabel-color black
    set plabel "northeast-escape-point"
    set pcolor orange
  ]
 ;; let northeast-escape-point patches with [ pxcor = 716 and pycor = 210 ]

   ;; ask patches with [pxcor = -183 and pycor = 210]
    ask patch -183 210
  [
    set ptype "northwest-escape-point"
    set plabel-color black
    set plabel "northwest-escape-point"
    set pcolor orange
  ]
 ;; let northwest-escape-point patches with [ pxcor = -183 and pycor = 210 ]

   ;;ask patches with [pxcor = 216 and pycor = 210]
   ask patch 216 210
  [
    set ptype "north-escape-point"
    set plabel-color black
    set plabel "north-escape-point"
    set pcolor orange
  ]
  ;;let north-escape-point patches with [ pxcor = 216 and pycor = 210 ]

  ;
  ; establish elevations between the buildings for the turtles to follow
  ;
  ;
  ; set elevations along Boylston street
    ; set elevations along Boylston street at the finish line west of the camera icon  -202 < pxcor < 20 , -41 < pycor < 53
    ;
     let counter5 20
    let temp-elevation5 1490

    while [ counter5 != -202 ]

    [ ask patches with [ pxcor <= counter5 and pxcor > -203 and pycor < 53 and pycor > -41]
     [
        set elevation (temp-elevation5 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation5 (temp-elevation5 - 1)
     set counter5 (counter5 - 1)
     ;;show counter
     ;;if counter5 = -38 [ stop ]

    ]

   ; set elevations along Boylston street at the finish line east of the camera icon 20 < pxcor < 500 , -41 < pycor < 53
    ;
     let counter6 20
    let temp-elevation6 1490

    while [ counter6 != 500 ]

    [ ask patches with [ pxcor >= counter6 and pxcor <= 500 and pycor < 53 and pycor > -41 ]
     [
        set elevation (temp-elevation6 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation6 (temp-elevation6 - 1)
     set counter6 (counter6 + 1)
     ;;show counter6
     ;;if counter6 = -38 [ stop ]

    ]


    ; set elevations along Boylston street between the middle of the CVS building and middle of Dartmouth street 247 < pxcor < 460 , -41 < pycor < 53
    ;
     let counter7 460
    let temp-elevation7 1490

    while [ counter7 != 247 ]

    [ ask patches with [ pxcor >= 247 and pxcor <= counter7 and pycor < 53 and pycor > -41 ]
     [
        set elevation (temp-elevation7 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation7 (temp-elevation7 - 1)
     set counter7 (counter7 - 1)
     ;;show counter7
     ;;if counter7 = -38 [ stop ]

    ]


    ; set elevations along Boylston street between the middle of the CVS building and Clarendon street 461 < pxcor < 713 , -41 < pycor < 53
    ;
     let counter8 461
    let temp-elevation8 1490

    while [ counter8 != 713 ]

    [ ask patches with [ pxcor >= counter8 and pxcor <= 713 and pycor < 53 and pycor > -41 ]
     [
        set elevation (temp-elevation8 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation8 (temp-elevation8 - 1)
     set counter8 (counter8 + 1)
     ;;show counter8
     ;;if counter8 = -38 [ stop ]

    ]

  ; set elevations along North Exeter street
  ;
    let counter 0
    let temp-elevation 1000

    while [counter != 233 ]

    [ ask patches with [ pxcor > -203 and pxcor < -174 and pycor > counter ]
     [
        set elevation (temp-elevation - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation (temp-elevation - 1)
     set counter (counter + 1)
     ;;show counter
     ;;if counter = 185 [ stop ]

    ]

  ; set elevations along South Exeter street
  ;
    let counter3 -1
    let temp-elevation3 1000

    while [ counter3 != -260 ]

    [ ask patches with [ pxcor > -206 and pxcor < -156 and pycor < counter3 ]
     [
        set elevation (temp-elevation3 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation3 (temp-elevation3 - 1)
     set counter3 (counter3 - 1)
     ;;show counter3
     ;;if counter3 = 40 [ stop ]

    ]


  ; set elevations along North Dartmouth street
  ;
    let counter2 0
    let temp-elevation2 1000

    while [ counter2 != 233 ]

     [ ask patches with [ pxcor > 204 and pxcor < 264 and pycor > counter2 ]
     [
        set elevation (temp-elevation2 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation2 (temp-elevation2 - 1)
     set counter2 (counter2 + 1)
     ;;show counter2
     ;;if counter2 = 185 [ stop ]

    ]

  ; set elevations along South Dartmouth street
  ;
    let counter4 -1
    let temp-elevation4 1000

    while [ counter4 != -260 ]

    [ ask patches with [ pxcor > 244 and pxcor < 501 and pycor < counter4 ]
     [
        set elevation (temp-elevation4 - 1)
        set pre_blast_elevation elevation
        ;;set pcolor red
     ]
     set temp-elevation4 (temp-elevation4 - 1)
     set counter4 (counter4 - 1)
     ;;show counter4
     ;;if counter4 = -38 [ stop ]

    ]



end

;; added to support only modifying the terrain where the bystanders initially get distributed
;; since the terrorist explosion modifys the elevation around the blast radius
;; this makes resetting the model for statistical collection much faster
to update-terrain

  ; set elevations along Boylston street
    ; set elevations along Boylston street at the finish line west of the camera icon  -202 < pxcor < 20 , -41 < pycor < 53
    ;

    ask patches with [ pxcor <= 40 and pxcor > -203 and pycor < 53 and pycor > -41]
     [
        set elevation pre_blast_elevation
        ;;set pcolor red
     ]


   ; set elevations along Boylston street at the finish line east of the camera icon 20 < pxcor < 500 , -41 < pycor < 53
    ;

    ask patches with [ pxcor >= 20 and pxcor <= 500 and pycor < 53 and pycor > -41 ]
     [
        set elevation pre_blast_elevation
        ;;set pcolor red
     ]


    ; set elevations along Boylston street between the middle of the CVS building and middle of Dartmouth street 247 < pxcor < 460 , -41 < pycor < 53
    ;
     ask patches with [ pxcor >= 247 and pxcor <= 460 and pycor < 53 and pycor > -41 ]
     [
        set elevation pre_blast_elevation
        ;;set pcolor red
     ]



    ; set elevations along Boylston street between the middle of the CVS building and Clarendon street 461 < pxcor < 713 , -41 < pycor < 53
    ;

     ask patches with [ pxcor >= 461 and pxcor <= 713 and pycor < 53 and pycor > -41 ]
     [
        set elevation pre_blast_elevation
        ;;set pcolor red
     ]



end


to setup ;; this is where you stick initialization code
  ;;ca;; ca is short for 'clear all' that clears everything out so you have a blank slate on which to start
  ;;let NUM-TURTLES 100
  ask turtles [die]

  setup-counters
  setup-agents
  ;;create-turtles pop-size [
  ;;  set color green
  ;;  set size 5.0
  ;;  set shape "person"
  ;;  set heading 0
    ;; setxy 467 + random (528 - 467) 139 + random (150 - 139)

    ;;setxy -127 + random (-3 - -127) -9 + random (-1 - -9)  ]

  ;;  setxy -175 + random (241 - -175) -20 + random (10 - -20)  ]
  ;; watch patch 517 169
  reset-ticks
end

to setup-agents
  let pop-size NUM-TURTLES / 2
  let runner-pop-size NUM-TURTLES * 0.01
  let num-vehicles 5

  ;
  ; create the bystanders
  ;
  create-bystanders pop-size [
    set size 5
    set color green
    set shape "person"
    set heading 180
    setxy -175 + random (500 - -175) 22 + random (41 - 22) ;; previously 500 was 230 which extends the range of the bystanders x position
  ]

  ;
  ; create the bystanders
  ;
  create-bystanders pop-size [
    set size 5
    set fear FALSE
    set color green
    set shape "person"
    set heading 0
    setxy -175 + random (500 - -175) -32 + random (-11 - -32) ;; previously 500 was 230 which extends the range of the bystanders x position
  ]

  ;
  ; create the terrorists
  ;
  create-terrorists NUM-TERRORISTS [


    let temp-val NUM-TERRORISTS
    while [ temp-val != 0 ]
    [
     let temp-side  random-float 1
     set size 5
     set color black
     set shape "person"
     set heading 180

     ifelse temp-side >= 0.5
     [ setxy -175 + random (500 - -175) 22 + random (41 - 22) ] ;; places the terrorist on the north side of Boylston
     [ setxy -175 + random (500 - -175) -32 + random (-11 - -32)  ] ;; places the terrorist on the south side of Boylston
     ;; [ setxy -175 + random (500 - -175) 22 + random (41 - 22) ]
     set temp-val temp-val - 1
    ]

    ;;setxy -175 + random (500 - -175) 22 + random (41 - 22) ;; previously 500 was 230 which extends the range of the bystanders x position
  ]
  ;
  ; create the runners
  ;
  create-runners runner-pop-size [
    set size 5
    set fear FALSE
    set color red
    set shape "person"
    set heading 270
    setxy 12 + random (814 - 12) 15 + random (21 - 15)
  ]

  ;
  ; create the responders
  ;
  create-responders runner-pop-size * 0.5 [
    set size 5
    set fear FALSE
    set color blue
    set shape "person police"
    set heading 0
    setxy -175 + random (660 - -175) -1 + random (3 - -1)
  ]

 ;
  ; create the emergency vehicles
  ;
  create-emergency-vehicles num-vehicles [
    set size 15
    set fear FALSE
    set color red
    set shape "ambulance"
    set heading 90
    setxy 183 + random (264 - 183) -211
  ]


  ;
  ; determine escape points
  ;
  ask bystanders with [ pxcor <= 47 and pycor >= 0 ]

    [set myEscapePoint "northwest-escape-point"
      face patch -350 210
      ;;face patch -183 210
      ]

  ask bystanders with [ pxcor <= 47 and pycor <= 0 ]

    [set myEscapePoint "southwest-escape-point"
      face patch -350 -225
      ;;face patch -183 -225
      ]

   ask bystanders with [ pxcor > 47 and pycor > 0 ]

    [set myEscapePoint "north-escape-point"
      face patch 350 210
      ;;face patch 216 210
      ]

   ask bystanders with [ pxcor > 47 and pycor < 0 ]

    [set myEscapePoint "south-escape-point"
      face patch 350 -225
      ;;face patch 216 -225
      ]

end

;
; step through
;

to step
  ;; update-sea-surface-temperature
  runners-move
  responders-move
  bystanders-move
  update-counters
  if ticks = 10
    [
      bomb-blast
    ]
  ;;update-explosion
  tick
end

to runners-move
  ask runners [

    ifelse not any? runners with [ fear = TRUE ]
    [ uphill elevation ] ;; was previously forward 2
    [ downhill elevation]     ;; was previously forward 1
  ]

  end

  to responders-move
  ask responders [

     ifelse any? responders with [ fear = TRUE ]
    [ forward 2 ]
      [ forward 0]

  ]

  end

  to bystanders-move
  ask bystanders [
      ifelse any? bystanders with [ fear = FALSE ]
          [ forward 0]


    ;; new movement code from Steve Scott's pedestrian egress model

    [
    ;;  let spot patch-ahead 1
    ;;  ;; move through an open space
    ;;if spot != nobody and not any? bystanders-on spot and [ptype] of spot = "outside"
    ;;  [
    ;;    move-to spot
    ;;    ]
    ;;  ;; what if you are facing a structure
    ;; if [ptype] of patch-here = "outside" and [ptype] of spot = "structure" [
    ;;      set spot one-of neighbors with [ not any? turtles-here and ptype = "outside" ]
    ;;      if spot != nobody [
    ;;        move-to spot
    ;;     ]
    ;;  ]
      ;; end new movement code

    downhill elevation


      ]
    ]



  end

to setup-counters
  set north-exeter-exit-counter 0
    set south-exeter-exit-counter 0
    set north-dartmouth-exit-counter 0
    set south-dartmouth-exit-counter 0
    set number-dead 0
    clear-all-plots

end

to update-counters


  ;; update counters on north Exeter street
  ask patches with [ pxcor <= -174 and pxcor >= -202 and pycor = 56 ]
    [if any? turtles-here
  [set north-exeter-exit-counter north-exeter-exit-counter + 1]
    ]
  ;; update counters on south Exeter street
  ask patches with [ pxcor <= -155 and pxcor >= -204 and pycor = -48 ]
    [if any? turtles-here
  [set south-exeter-exit-counter south-exeter-exit-counter + 1]
    ]

  ; update counters on North Dartmouth street
ask patches with [ pxcor <= 264 and pxcor >= 205 and pycor = 58 ]
    [if any? turtles-here
  [set north-dartmouth-exit-counter north-dartmouth-exit-counter + 1]
    ]

  ; update counters on south Dartmouth street
  ask patches with [ pxcor <= 706 and pxcor >= 182 and pycor = -41 ]
    [if any? turtles-here
  [set south-dartmouth-exit-counter south-dartmouth-exit-counter + 1]
    ]

end


to go

  ;;let number-dead 0
    step
    ;;if ticks = 10
    ;;[
    ;;  bomb-blast
    ;;]

    if ticks > 220 [stop]

end

to bomb-blast
      ask bystanders [set fear TRUE]
      ask runners [set fear TRUE]

      ;; set off the bomb at the terrorist position
      let terrorist-x-position  ( [xcor] of turtles with [ color = black ] )
      show terrorist-x-position

      let terrorist-y-position ( [ycor] of turtles with [ color = black ] )
      show terrorist-y-position

      set number-dead sum [count bystanders in-radius BLAST-RADIUS] of turtles with [ color = black ] ;; this value, 5, could be a variable called blast-radius or kill-zone

      ;;show number-dead
      ask terrorists [
        ask bystanders in-radius BLAST-RADIUS ;; this value is a turtle relative range
        [
          hatch-dead-bystanders 1 [set color black set shape "person" set fear false ]
          ;set color black
          ;set shape "turtle"
          ;set fear FALSE
          die
        ]

        let temp-counter (1 * BLAST-RADIUS ) ;; this procedure changes the elevation of the blast site, which will keep the escaping bystanders from walking over the dead
        while [ temp-counter != 0 ]
        [ ask patches in-radius temp-counter
          [
            ;;hatch-terrorists 1 [set color black set fear FALSE ]

            set elevation elevation + 100
          ]
          set temp-counter temp-counter - 1
         ]
      ]
end




;; I used this code to sweep manually through a variety of parameters
;; you must perform 'load' once before running the sweeper

to sweep-parameters
  let max-ticks 220

  ;; *********************************************
  ;; THESE ARE THE VALUES YOU WANT TO MANIPULATE
  let outer-loop-vals [1 4 8 10] ;; HERE THE OUTER LOOP IS BLAST RADIUS
  ;; *******************************************

  let outer-loop first outer-loop-vals
  let max-outer-loop last outer-loop-vals
  let outer-loop-index 0

  ;; *********************************************
  ;; THESE ARE THE VALUES YOU WANT TO MANIPULATE
  let inner-loop-vals [1 2 3]  ;; HERE THE INNER LOOP IS NUMBER OF TERRORISTS
  ;; *******************************************

  let inner-loop first inner-loop-vals
  let max-inner-loop last outer-loop-vals
  let inner-loop-index 0


  ;; initialize data values for collection
  let list-north-exeter-exit [ ]
  let list-south-exeter-exit [ ]
  let list-north-dartmouth-exit [ ]
  let list-south-dartmouth-exit [ ]
  let list-num-terrorists [ ]
  let list-blast-radius [ ]

 ;; first turn off the display to accelerate the simulation
  no-display

  while [ outer-loop-index < length outer-loop-vals ][

    while [ inner-loop-index < length inner-loop-vals ][

      ask turtles [die]
      update-terrain

      set NUM-TURTLES 1000
      set NUM-TERRORISTS item inner-loop-index inner-loop-vals
      set BLAST-RADIUS item outer-loop-index outer-loop-vals

      setup

      repeat max-ticks [step]

      ;;set inner-loop (inner-loop + )

      ;; collect data values as a list as the loops execute
        set list-north-exeter-exit lput north-exeter-exit-counter list-north-exeter-exit
        set list-south-exeter-exit lput south-exeter-exit-counter list-south-exeter-exit
        set list-north-dartmouth-exit lput north-dartmouth-exit-counter list-north-dartmouth-exit
        set list-south-dartmouth-exit lput south-dartmouth-exit-counter list-south-dartmouth-exit
        set list-num-terrorists lput NUM-TERRORISTS list-num-terrorists
        set list-blast-radius lput BLAST-RADIUS list-blast-radius


      set inner-loop-index (inner-loop-index + 1)

    ]

    ;;print (list "DEBUG: inner = " inner-loop-index ", outer = " outer-loop-index ", north-exeter-exit-counter = " north-exeter-exit-counter)

   ;;set outer-loop (outer-loop + 1)

   set outer-loop-index (outer-loop-index + 1)
   set inner-loop-index 0

  ]

  display
  ;; For debugging purposes, just print out the values
  print (list "inner index:" inner-loop-index ", outer index:" outer-loop-index)
  print (list "debug: south dartmouth exit values are " list-south-dartmouth-exit)
  print (list "debug: number of terrorists tested are " list-num-terrorists)
  print (list "debug: number of blast radii tested are " list-blast-radius)

  ;; here you want to write the values you collected to a CSV file by calling the CSV-logger function below

  ;; CSV-logger[ "/Users/kham/Desktop/" "MyBostonBombingAnalysis.csv"  list-north-exeter-exit ]


end


 ;; CSV-logger is code that was provided by Steve Scott in an excellent course at George Mason University
 ;; This code enables one to write the contents of a list as a line into a csv file

to CSV-logger[directory-name file-name dataList]
    ;open the file
    set-current-directory directory-name
    file-open file-name

    ;; iterate over the list, writing each element
    let val 0
    let j 1
    let n (length dataList)
    foreach dataList
    [ ?1 ->
      set val ?1
      file-type val
      ifelse (j < n)
      [ file-type "," ]
      [ file-print " " ]
      set j (j + 1)
    ]
    file-flush
    file-close
end
@#$#@#$#@
GRAPHICS-WINDOW
263
46
2829
1263
-1
-1
2.0
1
10
1
1
1
0
0
0
1
-350
928
-275
328
0
0
1
ticks
30.0

BUTTON
61
463
127
496
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
136
503
246
536
Load Terrain
ca\nload
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
65
268
237
301
NUM-TURTLES
NUM-TURTLES
100
10000
3700.0
100
1
NIL
HORIZONTAL

BUTTON
112
420
175
453
Step
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
179
420
242
453
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

MONITOR
196
681
253
726
Tick
ticks
17
1
11

BUTTON
133
461
244
494
Clear Agents
ask turtles [die]
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
68
318
240
351
NUM-TERRORISTS
NUM-TERRORISTS
0
5
0.0
1
1
NIL
HORIZONTAL

SLIDER
65
365
237
398
BLAST-RADIUS
BLAST-RADIUS
0
10
3.0
1
1
NIL
HORIZONTAL

MONITOR
26
686
172
731
North Exeter Counter
north-exeter-exit-counter
17
1
11

MONITOR
23
741
169
786
South Exeter Counter
south-exeter-exit-counter
17
1
11

MONITOR
23
803
196
848
North Dartmouth Counter
north-dartmouth-exit-counter
17
1
11

MONITOR
23
861
196
906
South Dartmouth Counter
south-dartmouth-exit-counter
17
1
11

MONITOR
191
746
248
791
Dead
number-dead
17
1
11

TEXTBOX
13
169
254
252
Pedestrian Modeling in Netlogo 6.1: Simulating the 2013 Boston Marathon Bombing
13
0.0
0

PLOT
31
926
231
1076
plot 1
Time (sec)
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"dead" 1.0 0 -16777216 true "" "plot number-dead"
"north-exeter" 1.0 0 -13840069 true "" "plot north-exeter-exit-counter"
"south-exeter" 1.0 0 -5825686 true "" "plot south-exeter-exit-counter"
"north-dartmouth" 1.0 0 -13345367 true "" "plot north-dartmouth-exit-counter"
"south-dartmouth" 1.0 0 -955883 true "" "plot south-dartmouth-exit-counter"

BUTTON
0
503
124
536
Update Terrain
update-terrain
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
95
552
165
585
Sweep
sweep-parameters
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is a simulation of the finish line of the Boston Marathon during the April 15th bombing in 2013. The simulation includes crowd behavior for escape after the terrorist bombs are ignited. The objectives for the model are to estimate impacts to crowd egress under a variety of settings including crowd density, blast size, and number of terrorists in the crowd. The crowd uses a social attachment form of behavior as opposed to the entrapment (fight or flight) model or the social identity model.

The research questions that were proposed for the model are:
Do crowd behaviors in restricted spaces under stressful conditions suggest improvements for egress or medical response transport?
Do spatial distributions of fatalities suggest improvements for sensor deployments or first responder staging?
How does explosive charge intensity impact bystander egress?


## HOW IT WORKS

Once you 'load' the initial terrain, you need to run 'setup' to establish the agents and their initial positions. Selecting 'go' will run the model, which will complete at 220 ticks. Step also works and progresses the model a tick at a time. At about 10 ticks into the simulation, the terrorists (black color) unleash their explosives and the fear generated causes the bystanders (green color) and runners (red color) to seek safety at their pre-assigned escape points. These escape points are labeled in the north and south parts of the world. First responders (blue color) do not do anything in this version. To re-run the simulation, just 'update terrain' which re-establishes the terrain environment to its pre-blast configuration. This helps quickly establish an original terrain representation for the agents without having to reload the initial world model (which can take up to 3 minutes). Then press 'clear agents', 'setup', and 'go'.

The monitors display the number of bystanders that escape to their exit points using that escape route (1 of 4 main cross streets of Boylston Street: North Exeter, South Exeter, North Dartmouth, and South Dartmouth). Monitors also show the number of bystanders that die from the terrorist blast. A plot window graphs all of these quantities as well to show the relative magnitude of the changes as they progress in the simulation.

The 'sweep' button enables running the simulation through multiple parameters of the variable controls (NUM-TURTLES, NUM-TERRORISTS, BLAST-RADIUS), but does so by turning off the display. This lets the simulations run much more quickly through these paramaters. To modify the parameters for the sweep, you have to do so manually in the last procedure of the code.

## HOW TO USE IT

Use the 'Load Terrain' button only once at your initial start of the model. This can take 3 minutes to complete. Ensure you have the background image or the world will not represent anything meaningful. After a run you can reset the terrain by pressing the 'update terrain' button. The Model lets you decide the crowd density (500 up to 10,000) which divides this number in half and places each half on either side of Boylston Street (green). From this number a small percentage is made for runners (red) and first responders (blue). The blast size can be adjusted from 1 (which generally only kills the terrorist, but occasionally gets one or two other bystanders standing right next to the terrorist) or 10 (which can kill bystanders in a 10 turtle range). Number of terrorists can be adjusted from 1 to 5, which are randomly placed in either side of Boylston in the crowd.)

## THINGS TO NOTICE

When the number of turtles is set above 3,000, the simulation gets very slow. At 10,000 it really takes too long to watch the simulation. This could be a good use of the sweep function since it turns off all display functions, but still captures the main metrics (dead turtles and counts at the escape ponits). 2,000 turtles appears to be a comfortable setting for watching the simulation and getting quick results using the fastest speed.
When the terrorists set off their explosives near a building, nothing happens to the building. Adding structure damages to the world could be a good extension of the model.

If using Behavior Space to run simulations, you should only run 1 parallel instance, or you might run into memory limitation issues.
The following commands should be in the setup command section:
no-display
update-terrain
setup

The following commands should be in the go command section:
go

I used the following variables in the measure runs using these reporters section:
count bystanders
count runners
count terrorists
count responders
count emergency-vehicles
ticks
number-dead
north-exeter-exit-counter
south-exeter-exit-counter
south-dartmouth-exit-counter
north-dartmouth-exit-counter


## THINGS TO TRY


Try using the same number of bystanders and number of terrorists, but only change the blast radius and see how the numbers at each exit vary.
Try using the same number of bystanders and the same blast radius, but change the number of terrorists and see how the numbers at each exit vary.

## EXTENDING THE MODEL

 There are several things that could be done to extend this model. One of the research questions was centered around spatial distribution of explosions and the impact to egress. This could be achieved by linking the terrorists in some fashion and determining the distance between them. This size of the geometries could be compared against the egress counts. Another was about suggestions for sensor deployments to support first responders. This might be done by establishing a new breed of turtle, say a camera, which could be pointed from various buildings toward the crowd. Over several simulations you could link the sensor and explosion to determine how frequently the explosion was not in view of a camera. These are just a few examples, I am sure there are many others, like making the dead bystanders turn into fire, or adding damage to the structures in the map.

## NETLOGO FEATURES

One of the better NetLogo features is the ease at which turtles can move in the world you establish for them. By employing a gradient of elevations within the patches, the turtles will move along the gradient toward whatever point you give them with the simple 'downhill' command. This does require you give the patches an elevation property, and then set the value of the propoerty appropriately for all patches that are part of the escape path. One of the more tedious and time consuming pieces of the model is establishing the gradient for the escape path. This required careful calculation of starting and ending points, relative to the background image, and use of 'for' loops to set the appropriate elevations for the turtles to follow. If there is a faster way to do this, that could also be a valuable extension.

## RELATED MODELS

Alex Fink and Sai Emry's Zombie Infection Model 2,  (Submitted: 09/15/2009)
http://ccl.northwestern.edu/netlogo/models/community/Zombie Infection 2

Kevan Davis' original Zombie Infection Simulation, version 2.3:
http://kevan.org/proce55ing/zombies/

Asymptote Zombie Model
http://ccl.northwestern.edu/netlogo/models/community/Zombie_Infection_2



## CREDITS AND REFERENCES


The Boston Athletic Association. (2016). Course map. Retrieved November 15, 2016, from http://www.baa.org/races/boston-marathon/event-information/course-map.aspx

Cullen, K. (2013, April 28). Boston marathon bombings. Retrieved November 5, 2016, from http://www.bostonglobe.com/metro/specials/boston-marathon-explosions

Drury, J., & Cocking, C. (2007). The mass psychology of disasters   and emergency evacuations:   A research report and implications for practice. Retrieved from http://www.sussex.ac.uk/affiliates/panic/Disasters and emergency evacuations (2007).pdf

Executive Office of Public Safety and Security, Commonwealth of Massachusetts. (2014). After action report for the response to the 2013 Boston marathon bombings. Retrieved from http://www.mass.gov/eopss/docs/mema/after-action-report-for-the-response-to-the-2013-boston-marathon-bombings.pdf

Fink, A., & Emrys, S. NetLogo user community models: Zombie infection 2. Retrieved November 2, 2016, from Netlogo, http://ccl.northwestern.edu/netlogo/models/community/Zombie Infection 2

GIS Agents.org, & Crooks, A. (2016, June 7). Pedestrian modeling examples. Retrieved November 3, 2016, from GIS Agents.org, http://www.gisagents.org/2016/02/pedestrian-modeling-examples.html

Martin, E. T., Morrison, M., & McNiff, C. (2000, April 12). The Boston marathon fact sheet. Retrieved November 15, 2016, from http://www.infoplease.com/spot/marathon.html

Mawson, A. R. (2005). Understanding mass panic and other collective responses to threat and disaster. Psychiatry: Interpersonal and Biological Processes, 68(2), 95–113. doi:10.1521/psyc.2005.68.2.95

New York Times (2013). Site of the explosions at the Boston marathon Interactive Media. U.S. Retrieved from http://www.nytimes.com/interactive/2013/04/15/us/site-of-the-boston-marathon-explosion.html?ref=us

O’Leary, M., & Heide, E. A. der (2004). The First 72 Hours: A Community Approach to Disaster Preparedness. CH 27, Common Misconceptions about  Disasters: Panic,  the “Disaster Syndrome,” and  Looting. Retrieved from https://www.atsdr.cdc.gov/emergency_response/common_misconceptions.pdf

Partners, B. G. M. (2013, April 16). How the Boston marathon bombings unfolded - the Boston globe. Retrieved November 5, 2016, from http://www.bostonglobe.com/2013/04/15/explosionreports/0gpSHeDd0JDbSw6P4irqXM/story.html
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ambulance
false
0
Rectangle -7500403 true true 30 90 210 195
Polygon -7500403 true true 296 190 296 150 259 134 244 104 210 105 210 190
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Circle -16777216 true false 69 174 42
Rectangle -1 true false 288 158 297 173
Rectangle -1184463 true false 289 180 298 172
Rectangle -2674135 true false 29 151 298 158
Line -16777216 false 210 90 210 195
Rectangle -16777216 true false 83 116 128 133
Rectangle -16777216 true false 153 111 176 134
Line -7500403 true 165 105 165 135
Rectangle -7500403 true true 14 186 33 195
Line -13345367 false 45 135 75 120
Line -13345367 false 75 135 45 120
Line -13345367 false 60 112 60 142

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

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

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
  <experiment name="Boston_bombing_updated_sweep_sheet" repetitions="10" runMetricsEveryStep="false">
    <setup>no-display
update-terrain
setup</setup>
    <go>go</go>
    <timeLimit steps="220"/>
    <metric>count bystanders</metric>
    <metric>count runners</metric>
    <metric>count terrorists</metric>
    <metric>count responders</metric>
    <metric>count emergency-vehicles</metric>
    <metric>ticks</metric>
    <metric>number-dead</metric>
    <metric>north-exeter-exit-counter</metric>
    <metric>south-exeter-exit-counter</metric>
    <metric>south-dartmouth-exit-counter</metric>
    <metric>north-dartmouth-exit-counter</metric>
    <steppedValueSet variable="BLAST-RADIUS" first="1" step="2" last="10"/>
    <enumeratedValueSet variable="NUM-TURTLES">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NUM-TERRORISTS">
      <value value="2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Boston_bombing_updated_sweep_sheet_4_terrorists" repetitions="10" runMetricsEveryStep="false">
    <setup>no-display
update-terrain
setup</setup>
    <go>go</go>
    <timeLimit steps="220"/>
    <metric>count bystanders</metric>
    <metric>count runners</metric>
    <metric>count terrorists</metric>
    <metric>count responders</metric>
    <metric>count emergency-vehicles</metric>
    <metric>ticks</metric>
    <metric>number-dead</metric>
    <metric>north-exeter-exit-counter</metric>
    <metric>south-exeter-exit-counter</metric>
    <metric>south-dartmouth-exit-counter</metric>
    <metric>north-dartmouth-exit-counter</metric>
    <enumeratedValueSet variable="NUM-TURTLES">
      <value value="2000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="BLAST-RADIUS" first="1" step="2" last="10"/>
    <enumeratedValueSet variable="NUM-TERRORISTS">
      <value value="4"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Boston_bombing_updated_sweep_density_approximation" repetitions="100" runMetricsEveryStep="false">
    <setup>no-display
update-terrain
setup</setup>
    <go>go</go>
    <timeLimit steps="220"/>
    <metric>count bystanders</metric>
    <metric>count runners</metric>
    <metric>count terrorists</metric>
    <metric>count responders</metric>
    <metric>count emergency-vehicles</metric>
    <metric>ticks</metric>
    <metric>number-dead</metric>
    <metric>north-exeter-exit-counter</metric>
    <metric>south-exeter-exit-counter</metric>
    <metric>south-dartmouth-exit-counter</metric>
    <metric>north-dartmouth-exit-counter</metric>
    <enumeratedValueSet variable="NUM-TURTLES">
      <value value="2000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="BLAST-RADIUS">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="NUM-TERRORISTS">
      <value value="4"/>
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
