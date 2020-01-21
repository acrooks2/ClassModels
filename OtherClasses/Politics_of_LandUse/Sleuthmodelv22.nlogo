extensions [ gis ]

globals [capxcor ;; x coordinate of capital
         capycor ;; y coordinate of capital
         newspreadcount ;; counts the number of patches which have obtained growth from a new urban center
         newspreadx ;; x coordinate for potential new urban center
         newspready ;; y coordinate for potential new urban center
         urbancenter;; checks to see if a new urban center has already been formed
         rgvalue;; road gravity value
         roadgrowthx;; x coordinate for source of road-influenced growth
         roadgrowthy;; y coordinate for source of road-influenced growth

         maxsearchindex ;; threshold distance between newly urbanized cell and nearest road
         roadaheadx ;; starting point for road growth x coordinate
         roadaheady ;; starting point for road growth y coordinate
         roadaheaddist ;; distance from starting point along road
         roadgrowthtaken;; indicates that a road influenced growth center has been created
         moveuproad;; indicates that a turtle can move ahead
         roadmoves;; the number of additional moves the agent has to move along the road
         newspreadcountroad



         urbantotal ;; total urban patches in DC
         ruraltotal ;; sum rural patches in DC
         purbantotal;; fraction of total land in DC which is urban
         concentration ;; measure of concentration of urban land across jurisdictions
         taxglobal;; mean taxes of patches
         urban1 ;; total urban land for Frederick
         nurban1 ;; total non-urban land for Frederick
         purban1 ;; urban land as a fraction of total urban and non urban land
         tax1;; development tax for frederick
         urban2 ;; Falls Church
         nurban2
         purban2
         tax2
         urban10 ;; Manassas City
         nurban10
         purban10
         tax10
         urban12 ;; Alexandria
         nurban12
         purban12
         tax12
         urban14 ;; Prince William
         nurban14
         purban14
         tax14
         urban18 ;; Fairfax
         nurban18
         purban18
         tax18
         urban20 ;; Prince Georges
         nurban20
         purban20
         tax20
         urban24 ;; Fredericksburg
         nurban24
         purban24
         tax24
         urban26 ;; Arlington
         nurban26
         purban26
         tax26
         urban28 ;; Manassas Park
         nurban28
         purban28
         tax28
         urban29 ;; Spotsylvania
         nurban29
         purban29
         tax29
         urban32 ;; Fauquier
         nurban32
         purban32
         tax32
         urban35 ;; Frederick
         nurban35
         purban35
         tax35
         urban36 ;; Loudoun
         nurban36
         purban36
         tax36
         urban37 ;; Calvert
         nurban37
         purban37
         tax37
         urban40 ;; Warren
         nurban40
         purban40
         tax40
         urban41 ;; Jefferson
         nurban41
         purban41
         tax41
         urban42 ;; Montgomery
         nurban42
         purban42
         tax42
         urban43 ;; Washington
         nurban43
         purban43
         tax43
         urban44 ;; Charles
         nurban44
         purban44
         tax44
         urban46 ;; Clarke
         nurban46
         purban46
         tax46
         urban49 ;; Fairfax City
         nurban49
         purban49
         tax49
         urban56 ;; Stafford
         nurban56
         purban56
         tax56
]

turtles-own [roadahead]
patches-own [urban urbancount ruralcount county capital excluded available capdist isolated newcenter newcentergrowth tax DC potential road hasroad  distancetoroad roadadjgrowth roadgrowthcenter ]

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  gis:apply-raster gis:load-dataset "urbandclr3.asc" urban
  gis:apply-raster gis:load-dataset "countyls.asc" county
  gis:apply-raster gis:load-dataset "excludedlr.asc" excluded
  gis:apply-raster gis:load-dataset "rasterroad.asc" road
  calculate-capdist
  setroad
  draw-map
  determine-availability
  set-tax
  calculateglobals
  displayplots

end

to go
  if ticks >= rounds [ stop ]
  spontaneous
  edge

  tick
  draw-map
  determine-availability
  set-tax
  calculateglobals
  displayplots
end

to setroad

  ask patches [
    set hasroad 0
    if road = 1 [
      set hasroad 1]]

end


to calculate-capdist ;; calculates distance from DC
  set capxcor mean [pxcor] of patches with [county = 43]
  set capycor mean [pycor] of patches with [county = 43]
  ask patches [
    set capdist ((pxcor - capxcor) ^ 2 + (pycor - capycor) ^ 2) ^ .5]
end

to determine-availability ;; determines if land is available for development

  ask patches [
    if county > 0 and county < 57 [
      set DC 1]
    if county > 0 and county < 57 and urban = 1 [
      set available  1]
    if excluded = 1 [
      set available  0]
    if urban = 2 [
      set available  0]
  ]
  end


to draw-map
  ask patches [
    if urban = 1 [
      set pcolor green]
    if urban = 2 [
      set pcolor red]
  ]

end


to set-tax
  ask patches with [DC = 1] [
   set urbancount 0
   set potential 1
   if urban = 2 [
     set urbancount 1]]

  ask patches [
    set ruralcount 0
    set potential 1
    if urban = 1 and available = 1[
      set ruralcount 1]]

  set urban1 sum [urbancount] of patches with [county = 1] ;; counts total number of urban patches in county
  set nurban1 sum [ruralcount] of patches with [county = 1] ;; counts total number of nonurban patches in county
  set purban1 (urban1 / (urban1 + nurban1)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 1] [ ;; sets development tax on patches
    set tax ( (purban1) * Lobby * 100)]
  set tax1 ((purban1) * Lobby * 100)

  set urban2 sum [urbancount] of patches with [county = 2] ;; counts total number of urban patches in county
  set nurban2 sum [ruralcount] of patches with [county = 2] ;; counts total number of nonurban patches in county
  set purban2 (urban2 / (urban2 + nurban2)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 2] [ ;; sets development tax on patches
    set tax ( (purban2) * Lobby * 100)]
  set tax2 ((purban2) * Lobby * 100)

  set urban10 sum [urbancount] of patches with [county = 10] ;; counts total number of urban patches in county
  set nurban10 sum [ruralcount] of patches with [county = 10] ;; counts total number of nonurban patches in county
  set purban10 (urban10 / (urban10 + nurban10)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 10] [ ;; sets development tax on patches
   set tax ( (purban10) * Lobby * 100)]
  set tax10 ((purban10) * Lobby * 100)

  set urban12 sum [urbancount] of patches with [county = 12] ;; counts total number of urban patches in county
  set nurban12 sum [ruralcount] of patches with [county = 12] ;; counts total number of nonurban patches in county
  set purban12 (urban12 / (urban12 + nurban12)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 12] [ ;; sets development tax on patches
   set tax12 ( (purban12) * Lobby * 100)]
  set tax12 ((purban12) * Lobby * 100)

  set urban14 sum [urbancount] of patches with [county = 14] ;; counts total number of urban patches in county
  set nurban14 sum [ruralcount] of patches with [county = 14] ;; counts total number of nonurban patches in county
  set purban14 (urban14 / (urban14 + nurban14)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 14] [ ;; sets development tax on patches
   set tax ( (purban14) * Lobby * 100)]
  set tax14 ((purban14) * Lobby * 100)

  set urban18 sum [urbancount] of patches with [county = 18] ;; counts total number of urban patches in county
  set nurban18 sum [ruralcount] of patches with [county = 18] ;; counts total number of nonurban patches in county
  set purban18 (urban18 / (urban18 + nurban18)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 18] [ ;; sets development tax on patches
   set tax ( (purban18) * Lobby * 100)]
  set tax18 ((purban18) * Lobby * 100)

  set urban20 sum [urbancount] of patches with [county = 20] ;; counts total number of urban patches in county
  set nurban20 sum [ruralcount] of patches with [county = 20] ;; counts total number of nonurban patches in county
  set purban20 (urban20 / (urban20 + nurban20)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 20] [ ;; sets development tax on patches
    set tax ( (purban20) * Lobby * 100)]
  set tax20 ((purban20) * Lobby * 100)

  set urban24 sum [urbancount] of patches with [county = 24] ;; counts total number of urban patches in county
  set nurban24 sum [ruralcount] of patches with [county = 24] ;; counts total number of nonurban patches in county
  set purban24 (urban24 / (urban24 + nurban24)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 24] [ ;; sets development tax on patches
    set tax ( (purban24) * Lobby * 100)]
  set tax24 ((purban24) * Lobby * 100)

  set urban26 sum [urbancount] of patches with [county = 26] ;; counts total number of urban patches in county
  set nurban26 sum [ruralcount] of patches with [county = 26] ;; counts total number of nonurban patches in county
  set purban26 (urban26 / (urban26 + nurban26)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 26] [ ;; sets development tax on patches
    set tax ( (purban26) * Lobby * 100)]
  set tax26 ((purban26) * Lobby * 100)

  set urban28 sum [urbancount] of patches with [county = 28] ;; counts total number of urban patches in county
  set nurban28 sum [ruralcount] of patches with [county = 28] ;; counts total number of nonurban patches in county
  set purban28 (urban28 / (urban28 + nurban28)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 28] [ ;; sets development tax on patches
   set tax ( (purban28) * Lobby * 100)]
  set tax28 ((purban28) * Lobby * 100)

  set urban29 sum [urbancount] of patches with [county = 29] ;; counts total number of urban patches in county
  set nurban29 sum [ruralcount] of patches with [county = 29] ;; counts total number of nonurban patches in county
  set purban29 (urban29 / (urban29 + nurban29)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 29] [ ;; sets development tax on patches
    set tax ( (purban29) * Lobby * 100)]
  set tax29 ((purban29) * Lobby * 100)

  set urban32 sum [urbancount] of patches with [county = 32] ;; counts total number of urban patches in county
  set nurban32 sum [ruralcount] of patches with [county = 32] ;; counts total number of nonurban patches in county
  set purban32 (urban32 / (urban32 + nurban32)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 32] [ ;; sets development tax on patches
    set tax ( (purban32) * Lobby * 100)]
  set tax32 ((purban32) * Lobby * 100)

  set urban35 sum [urbancount] of patches with [county = 35] ;; counts total number of urban patches in county
  set nurban35 sum [ruralcount] of patches with [county = 35] ;; counts total number of nonurban patches in county
  set purban35 (urban35 / (urban35 + nurban35)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 35] [ ;; sets development tax on patches
    set tax ( (purban35) * Lobby * 100)]
  set tax35 ((purban35) * Lobby * 100)

  set urban36 sum [urbancount] of patches with [county = 36] ;; counts total number of urban patches in county
  set nurban36 sum [ruralcount] of patches with [county = 36] ;; counts total number of nonurban patches in county
  set purban36 (urban36 / (urban36 + nurban36)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 36] [ ;; sets development tax on patches
    set tax ( (purban36) * Lobby * 100)]
  set tax36 ((purban36) * Lobby * 100)

  set urban37 sum [urbancount] of patches with [county = 37] ;; counts total number of urban patches in county
  set nurban37 sum [ruralcount] of patches with [county = 37] ;; counts total number of nonurban patches in county
  set purban37 (urban37 / (urban37 + nurban37)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 37] [ ;; sets development tax on patches
   set tax ( (purban37) * Lobby * 100)]
  set tax37 ((purban37) * Lobby * 100)

  set urban40 sum [urbancount] of patches with [county = 40] ;; counts total number of urban patches in county
  set nurban40 sum [ruralcount] of patches with [county = 40] ;; counts total number of nonurban patches in county
  set purban40 (urban40 / (urban40 + nurban40)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 40] [ ;; sets development tax on patches
    set tax ( (purban40) * Lobby * 100)]
  set tax40 ((purban40) * Lobby * 100)

  set urban41 sum [urbancount] of patches with [county = 41] ;; counts total number of urban patches in county
  set nurban41 sum [ruralcount] of patches with [county = 41] ;; counts total number of nonurban patches in county
  set purban41 (urban41 / (urban41 + nurban41)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 41] [ ;; sets development tax on patches
    set tax ( (purban41) * Lobby * 100)]
  set tax41 ((purban41) * Lobby * 100)

  set urban42 sum [urbancount] of patches with [county = 42] ;; counts total number of urban patches in county
  set nurban42 sum [ruralcount] of patches with [county = 42] ;; counts total number of nonurban patches in county
  set purban42 (urban42 / (urban42 + nurban42)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 42] [ ;; sets development tax on patches
   set tax ( (purban42) * Lobby * 100)]
  set tax42 ((purban42) * Lobby * 100)

  set urban43 sum [urbancount] of patches with [county = 43] ;; counts total number of urban patches in county
  set nurban43 sum [ruralcount] of patches with [county = 43] ;; counts total number of nonurban patches in county
  set purban43 (urban43 / (urban43 + nurban43)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 43] [ ;; sets development tax on patches
    set tax ( (purban43) * Lobby * 100)]
  set tax43 ((purban43) * Lobby * 100)

  set urban44 sum [urbancount] of patches with [county = 44] ;; counts total number of urban patches in county
  set nurban44 sum [ruralcount] of patches with [county = 44] ;; counts total number of nonurban patches in county
  set purban44 (urban44 / (urban44 + nurban44)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 44] [ ;; sets development tax on patches
    set tax ( (purban44) * Lobby * 100)]
  set tax44 ((purban44) * Lobby * 100)

  set urban46 sum [urbancount] of patches with [county = 46] ;; counts total number of urban patches in county
  set nurban46 sum [ruralcount] of patches with [county = 46] ;; counts total number of nonurban patches in county
  set purban46 (urban46 / (urban46 + nurban46)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 46] [ ;; sets development tax on patches
    set tax ( (purban46) * Lobby * 100)]
  set tax46 ((purban46) * Lobby * 100)

  set urban49 sum [urbancount] of patches with [county = 49] ;; counts total number of urban patches in county
  set nurban49 sum [ruralcount] of patches with [county = 49] ;; counts total number of nonurban patches in county
  set purban49 (urban49 / (urban49 + nurban49)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 49] [ ;; sets development tax on patches
    set tax ( (purban49) * Lobby * 100)]
  set tax49 ((purban49) * Lobby * 100)

  set urban56 sum [urbancount] of patches with [county = 56] ;; counts total number of urban patches in county
  set nurban56 sum [ruralcount] of patches with [county = 56] ;; counts total number of nonurban patches in county
  set purban56 (urban56 / (urban56 + nurban56)) ;; sets fraction of available land that is urbanized
  ask patches with [county = 56] [ ;; sets development tax on patches
    set tax ( (purban56) * Lobby * 100)]
  set tax56 ((purban56) * Lobby * 100)





end

to spontaneous
  set urbancenter 0
  set newspreadx random-pxcor
  set newspready random-pycor

  ask patches [
    set newcenter 0]

  ask patches with [available = 1] [ ;; determines if a new urban center arises
    if urbancenter = 0 [
    set newspreadcount 0



    if pxcor = newspreadx and pycor = newspready [
      set urbancenter 1
      if random 100 < ((Dispersion  * 5.3) * ((100 - tax) / 100)) [
        set newcenter 1
        set urban 2
        set available 0
        ]]

      if newcenter = 1 [ ;; determines whether growth spreads from a new urban center
      ask neighbors with [available = 1] [
        if random 100 < (newspread * ((100 - tax) / 100)) and newspreadcount < 2 [
          set urban 2
          set available 0
          set newspreadcount (newspreadcount + 1)
          set newcenter 1]]


  ]


  ]
  ]



end

to spreading
  ask patches with [available = 1] [
    if sum [isolated] of neighbors > 0 [
      if random 100 < (newspread * (1 - tax)) [
        set urban 2
        set available 0]]
  ]
end

to edge ;; edge growth
  ask patches with [available = 1] [
    if sum [urbancount] of neighbors >= 3 [
      set isolated 0
      if random 100 < (spread * ((100 - tax) / 100)) [
        set urban 2
        set available 0
        set newcenter 1]]
  ]
end


to roadgrowth ;; road-influenced growth
  ask patches [
    set roadgrowthcenter 0]
  set rgvalue (roadgravity / 100 * 47)
  set maxsearchindex 4 * rgvalue * (1 + rgvalue)
  ask patches with [newcenter = 1] [
     set roadgrowthtaken 0
     set newspreadcountroad 0
     set roadgrowthx pxcor
     set roadgrowthy pycor
     if random 100 < (newspread - tax) [
       ask patches with [hasroad = 1] [
        set distancetoroad ((pxcor - roadgrowthx) ^ 2 + (pycor - roadgrowthy) ^ 2) ^ .5
        ask patches with-min [distancetoroad] [
          if distancetoroad < maxsearchindex [
            sprout 1 [
             set roadmoves (dispersion - tax)
             loop [
               right random 360
               ask patch-ahead 1 [
                 if hasroad = 1 [
                   set moveuproad 1]]
               if moveuproad = 1 [
                 forward 1
                 set roadmoves (roadmoves - 1)
                 set moveuproad 0]
               if roadmoves <= 0 [stop]

             ]
             set roadgrowthcenter 1
             die]


             ]
          ]
        ]
        ask patches with [available = 1] [
          if sum [roadgrowthcenter] of neighbors > 0 [
            if roadgrowthtaken = 0 [
              set urban 2
              set available 0
              set roadadjgrowth 1
              set roadgrowthtaken 1]]
        ask patches with [roadadjgrowth = 1] [
          if newspreadcountroad < 2 [
            set urban 2
            set available 0
            set newspreadcountroad (newspreadcountroad + 1)]
        ]



        ]
      ]
    ]

end

to roadgrowth2
  ask patches [
    set roadgrowthcenter 0]
  set rgvalue (roadgravity / 100 * 47)
  set maxsearchindex 4 * rgvalue * (1 + rgvalue)
  ask patches with [newcenter = 1] [
     set roadgrowthtaken 0
     set newspreadcountroad 0
     set roadgrowthx pxcor
     set roadgrowthy pycor
     if random 100 < (newspread - tax) [
       ask patches with [hasroad = 1] [
        set distancetoroad ((pxcor - roadgrowthx) ^ 2 + (pycor - roadgrowthy) ^ 2) ^ .5]
       ask patches with-min [distancetoroad] [
          if distancetoroad < maxsearchindex [
            set roadaheadx pxcor
            set roadaheady pycor
            set roadmoves (dispersion - tax)]]
       ask patches with [hasroad = 1] [
         set roadaheaddist ((pxcor - roadaheadx) ^ 2 + (pycor - roadaheady) ^ 2) ^ .5
         if roadgrowthtaken = 0 [
           if roadaheaddist <= roadmoves [
             set roadgrowthcenter 1]]]
         ask patches with [available = 1] [
           if sum [roadgrowthcenter] of neighbors > 0 [
            if roadgrowthtaken = 0 [
              set urban 2
              set available 0
              set roadadjgrowth 1
              set roadgrowthtaken 1]]]
            ask patches with [roadadjgrowth = 1] [
          if newspreadcountroad < 2 [
            set urban 2
            set available 0
            set newspreadcountroad (newspreadcountroad + 1)]
            ]
         ]
         ]




end



to calculateglobals
  set urbantotal sum [urbancount] of patches with [DC = 1]
  set ruraltotal sum [ruralcount] of patches with [DC = 1]
  set purbantotal (urbantotal / (urbantotal + ruraltotal))
  set concentration ( (urban1 / urbantotal) ^ 2 + (urban2 / urbantotal) ^ 2 + (urban10 / urbantotal) ^ 2 + (urban12 / urbantotal) ^ 2 + (urban14 / urbantotal) ^ 2 + (urban18 / urbantotal) ^ 2 + (urban20 / urbantotal) ^ 2 +  (urban24 / urbantotal) ^ 2 + (urban26 / urbantotal) ^ 2 + (urban28 / urbantotal) ^ 2 + (urban29 / urbantotal) ^ 2 + (urban32 / urbantotal)  + (urban35 / urbantotal) ^ 2 + (urban36 / urbantotal) ^ 2 + (urban37 / urbantotal) ^ 2 + (urban40 / urbantotal) ^ 2 + (urban41 / urbantotal) ^ 2 + (urban42 / urbantotal) ^ 2 + (urban43 / urbantotal) ^ 2 + (urban44 / urbantotal) ^ 2 + (urban46 / urbantotal) ^ 2 + (urban49 / urbantotal) ^ 2 + (urban56 / urbantotal) ^ 2)
  set taxglobal mean [tax] of patches with [potential = 1]
end


to displayplots
  set-current-plot "Urban/Rural"
    set-current-plot-pen "Urban Plots"
    plotxy ticks urbantotal
    set-current-plot-pen "Rural Plots"
    plotxy ticks ruraltotal

  set-current-plot "% of Developed Land"
    set-current-plot-pen "%urban"
    plotxy ticks purbantotal

  set-current-plot "Urban Concentration"
    set-current-plot-pen "index"
    plotxy ticks concentration

  set-current-plot "Mean Tax Rate"
    set-current-plot-pen "globaltax"
    plotxy ticks taxglobal

end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
971
772
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-376
376
-376
376
0
0
1
ticks
30.0

BUTTON
48
63
111
96
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

BUTTON
47
13
110
46
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
17
137
189
170
Lobby
Lobby
0
1
1.0
.01
1
NIL
HORIZONTAL

SLIDER
18
200
190
233
Dispersion
Dispersion
0
100
52.0
1
1
NIL
HORIZONTAL

SLIDER
16
270
188
303
newspread
newspread
0
100
55.0
1
1
NIL
HORIZONTAL

SLIDER
19
334
191
367
spread
spread
0
100
26.0
1
1
NIL
HORIZONTAL

SLIDER
20
404
192
437
rounds
rounds
0
100
50.0
1
1
NIL
HORIZONTAL

PLOT
10
463
210
613
Urban/Rural
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"Urban Plots" 1.0 0 -16777216 true "" ""
"Rural Plots" 1.0 0 -16777216 true "" ""

PLOT
12
616
212
766
% of Developed Land
NIL
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"%urban" 1.0 0 -16777216 true "" ""

PLOT
1042
99
1242
249
Urban Concentration
NIL
NIL
0.0
100.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"index" 1.0 0 -16777216 true "" ""

PLOT
1050
310
1250
460
Mean Tax Rate
NIL
NIL
0.0
100.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""
"globaltax" 1.0 0 -16777216 true "" ""

MONITOR
1019
24
1076
69
Ticks
ticks
17
1
11

SLIDER
1015
495
1187
528
roadgravity
roadgravity
0
100
19.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This section could give a general understanding of what the model is trying to show or explain.

## HOW IT WORKS

This section could explain what rules the agents use to create the overall behavior of the model.

## HOW TO USE IT

This section could explain how to use the model, including a description of each of the items in the interface tab.

## THINGS TO NOTICE

This section could give some ideas of things for the user to notice while running the model.

## THINGS TO TRY

This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.

## EXTENDING THE MODEL

This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.

## NETLOGO FEATURES

This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.

## RELATED MODELS

This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.

## CREDITS AND REFERENCES

This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
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
