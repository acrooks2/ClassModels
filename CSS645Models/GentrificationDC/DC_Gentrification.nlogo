;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Using Agent-Based Modeling to Show Gentrification in a Southeast area of the District of Columbia
;;
;; This program is
;; written in NetLogo 5.0.3 utilizing the GIS extensions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; Load NetLogo extension to handle GIS functionality
extensions [gis]

; Set global variables for shapefiles, school graduation rates and agent lists
globals [
  DCblockdemo
  DCblockdemo07
  ;; the following are graduation rates for 5 public schools in the area.
  Anacostiagrad
  Easterngrad
  Dunbargrad
  Spingarngrad
  Wilsongrad

  maxHUperpatch
  metropatches   ; agent set of patches which are the locations of metro rail stations
  publicpatches  ; agent set of patches which are the locations of public housing properties
  myblocks
  DCmeanincome
  housingcostsincrease
  demandinflation
  incomeincrease
  newrents
  metropref
  nummoveout
  maxHUpersqmi
  yearlyhouseholdincrease
  percenthouseholdsmove
  q

  ;; the following are needed for the file input routines
  mypath
  myfolder
  myfile
  csvheaders
  csvdata
]

breed [hs-labels hs-label]       ; breed used to dispaly labels for GIS
breed [blocks block]             ; dummy agent used to hold initiation data for each block group
breed [households household]     ; turtle breed representing households
; patch (housing unit) variables
patches-own [ HS pPOP2000 pPOP2010 POPchange ptract pBLKGRP phouseholds10 pMetro pPublic
  pdistancetometro pdistancetopublic pdistancetoCBD ptractblockgrp pnumHU pnum_occ pnum_vac pnum_pub prent developed? pactual_incomeincr rank
  ppropcrime psimulation_incomeincr psimulation_meanincomeincr
  ]
; block (aggregate variables)
blocks-own [tractblkgrp  tract  block_Group   num_HU currentnum_HU new_HU %incr_per_yr_HU  %incr_HU num_occ  num_vac  calc_vac_rate
  num_historic  calc_historic_rate  %moves  median_monthly_costs  median_monthly_budget  median_income %incr_median_income median_to_mean
  median_home_value  num_public_housing  %public_housing  violentcrime_rate  propertycrime_rate crimelist startmedianincome endmedianincome
  startmeanincome endmeanincome simulated%increasemeanincome simulated%increasemedianincome rentinflation]
; Household variables
households-own [income householdblock budget happy? looking?]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    setup routine          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  ;ca
  clear-all
  reset-ticks
  ; Load the projection system for the shapefiles
  gis:load-coordinate-system "data/tractdata/WGS_84_Geographic.prj"
  set DCblockdemo gis:load-dataset "data/tractdata/blkgrp_DConly_Concentrated/blkgrp_DConly_Concentrated.shp"
  set DCblockdemo07 gis:load-dataset "data/tractdata/blkgrp07_DConly_Concentrated/blkgrp07_DConly_Concentrated.shp"
  gis:set-world-envelope gis:envelope-of DCblockdemo
  ; set global economic and spatial variables
  set maxHUpersqmi 17000
  set DCmeanincome 70401
  set incomeincrease 5            ; 5% based on 3% average for US (US labor dept) and 2% more for DC than US average
  set housingcostsincrease 6.26   ; average annualized home cost increases for neighborhoods in question from zillow.com
  set maxHUperpatch int (maxHUpersqmi / 5000) + 1
  ; type "maxHUperpatch " print maxHUperpatch
  set newrents 2000                ; based on average housing costs of $4000 in 2013 for recent construction and assuming 6% increase per year.
  set metropref (1 - lowcrimepref - publichousingpref)
  type "metropref " print metropref
  set nummoveout 0
  set q 0

  set yearlyhouseholdincrease 0.015    ; based on census data
  set percenthouseholdsmove 15         ; based on census data

  ; initialize the model with census data and metro and public housing locations
  input2000data
  setupblockprofiles
  setHSgradrates
  loadDCblockgroupdemographics
  loadDCSchools
  viewDCmetrostations
  viewpublichousing


  ask patch -120 53                     ;; set the location of the central business district
  [ set pcolor red set plabel "CBD"]
  ask patch -100 53
  [set plabel "CBD"]
   ask blocks
   [
    set %incr_HU (read-from-string %incr_per_yr_HU)       ; convert string to numeric
    if %incr_HU < 0 [ set %incr_HU 0]
    set currentnum_HU (read-from-string num_HU)
   ]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;set crime rates exogenously for ten years and then stay the same
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ask blocks with [tract = "6400"] [set crimelist [ 57  52  57  42  39  47  47  53  40  21  40  36] ]
ask blocks with [tract = "6700"] [set crimelist [ 50  70  52  48  37  45  29  36  51  61  38  41] ]
ask blocks with [tract = "6801"] [set crimelist [ 21  39  36  39  41  36  35  44  43  44  33  33] ]
ask blocks with [tract = "6802"] [set crimelist [ 32  61  36  44  33  32  31  27  44  27  24  31] ]
ask blocks with [tract = "6900"] [set crimelist [ 93  150  94  69  80  76  60  81  96  81  73  57] ]
ask blocks with [tract = "7000"] [set crimelist [ 90  105  97  69  78  52  47  63  57  70  59  50] ]
ask blocks with [tract = "7100"] [set crimelist [ 47  47  51  41  44  33  23  42  50  66  57  60] ]
ask blocks with [tract = "7200"] [set crimelist [ 267  295  207  137  109  92  116  76  53  44  44  47]]
ask blocks with [tract = "7901"] [set crimelist [ 28  41  35  45  43  34  34  21  31  30  26  27] ]
ask blocks with [tract = "7903"] [set crimelist [ 29  35  48  61  57  43  48  45  36  42  34  36] ]
ask blocks with [tract = "8001"] [set crimelist [ 30  56  51  54  51  66  52  45  50  51  52  56] ]
ask blocks with [tract = "8002"] [set crimelist [ 59  67  63  82  61  77  52  41  46  41  48  40] ]
ask blocks with [tract = "8100"] [set crimelist [ 46  104  80  80  84  95  42  40  42  35  30  39] ]

  setuphousing  ;; call subroutine to initialize housing and households based on census data
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       go routine          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
   if q > 100 [
     print "not enough affordable vacancies "
     let temp count patches with [developed? = true and pnum_vac > 0]
     type "vacant patches " print temp
     if temp > 0 [ print median [prent] of patches with [developed? = true and pnum_vac > 0]]
     stop]
  ; type "households " print count households
  ; type "developed patches " print count patches with [developed? = true]
  ; type "housing units " print sum [pnumHU] of patches with [developed? = true]
  ; type "public housing " print sum [pnum_pub] of patches with [developed? = true]
  ; type "vacant " print sum [pnum_vac] of patches with [developed? = true]
  ; type "average income " type mean [income] of households type "median income " print median [income] of households
  ; type "average rent " type mean [prent] of patches with [developed? = true] type "median rent " print median [prent] of patches with [developed? = true]
  ; type "rent<0 " print count patches with [developed? = true and prent < 0]
  ; type "unhappy? " print count households with [happy? = false]
  ; type "aver rent pubHU " type mean [prent] of patches with [developed? = true and pnum_pub > 0]


  createincominghousingunits       ; add new construction
  identifyunhappyhouseholds        ; identify households who want to move
  movehouseholds                   ; move households
  calculateglobalincreases         ; calculate global increases
  createincominghouseholds         ; create newcomers to DC

  calculateincomeincrease          ; calcualte aggregate increases in income for each block group
  tick                             ; increase time step
  if ticks = (Years_Simulated + 1) [stop]
end

to setHSgradrates                        ;; set HS Graduation Rates
  set Easterngrad 0.70
  set Dunbargrad 0.60
  set Spingarngrad 0.48
  set Wilsongrad 0.74
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       globalincreases     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to calculateglobalincreases
  set DCmeanincome (1 + ((1 + incomeincrease) / 100)) * DCmeanincome ; increase the average income of newcomers
  type "dcmeanincome " print DCmeanincome
  set newrents (1 + (housingcostsincrease / 100)) * newrents   ; increase the average housing costs of new construction
  ask households
   [
     set income (1 + (incomeincrease / 100)) * income          ; increase income and monthly budget of household agents
     set budget (1 + (incomeincrease / 100)) * income
   ]
   foreach myblocks [
    x -> ask x
    [
     let blockID [tractblkgrp] of x
     let blockcrimerate item 10 [crimelist] of x
     ; type "block " type blockID type " " type "% incr " print [%incr_HU] of ?
     if ticks < 11
     [

     set blockcrimerate item ticks [crimelist] of x           ; update the property crime per 1000 to the next item in the list
     ;type blockID type " block crimerate " print blockcrimerate
       ]

   ask patches with [developed? = true and ptractblockgrp = blockID]

   [

     set ppropcrime blockcrimerate                            ; update each patch (housing unit) with the crime rate
     ifelse pnum_pub > 0
     [
       set prent (1 + (housingcostsincrease / 100)) * prent   ; update housing costs (rents)
        ;set prent (1 + ((housingcostsincrease / 2) / 100)) * prent
       ]
     [set prent (1 + (housingcostsincrease / 100) ) * prent]
     ;  [set prent (1 + (housingcostsincrease / 100) + [rentinflation] of ?) * prent]
   ;   [

     ;   set prent ((1 + (housingcostsincrease / 100) + (10 * [%incr_HU] of ?)) * prent)
        ;]
   ]]
  ]

   ask blocks                                         ; calculate number of new housing units coming in next year.
   [
     let blockID tractblkgrp
    set new_HU  (%incr_HU * currentnum_HU)            ; new_HU increases each year based upon exogenous percentages for a 10 yr period evenly distributed per year.
    set currentnum_HU (currentnum_HU + new_HU)

   ]
   rankpatches                                        ; re-rank the patches based up updated crime information
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  hold block group data    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 to setupblockprofiles                    ;; set up dummy agents to store the Census block group data read in from the file
   create-blocks 29
   [
     hide-turtle]
   set myblocks sort blocks
   let j 0
   foreach myblocks [
    x ->
       ask x
       [
         set tractblkgrp (word "00" item j (item 0 csvdata))
         set tract item j (item 1 csvdata)
         set num_HU item j (item 3 csvdata)
         set %incr_per_yr_HU item j (item 4 csvdata)
         set num_occ item j (item 5 csvdata)
         set num_vac item j (item 6 csvdata)
         set calc_vac_rate  item j (item 7 csvdata)
         set num_historic item j (item 8 csvdata)
         set calc_historic_rate item j (item 9 csvdata)
         set %moves item j (item 10 csvdata)
         set median_monthly_costs item j (item 11 csvdata)
         set median_monthly_budget item j (item 12 csvdata)
         set median_income  item j (item 13 csvdata)
         set median_to_mean item j (item 14 csvdata)
         set median_home_value item j (item 15 csvdata)
         set num_public_housing item j (item 16 csvdata)
         set %public_housing item j (item 17 csvdata)
         set violentcrime_rate item j (item 18 csvdata)
         set propertycrime_rate  item j (item 19 csvdata)
         set %incr_median_income (read-from-string item j (item 20 csvdata))
         ;show %incr_median_income
       ]
       set j (j + 1)
     ]
;   ask blocks [              ;; verify block group agents are intialized correctly
;     ;type who type " " type tractblkgrp type " " print propertycrime_rate
;   ]
 end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;        Set-up Housing     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setuphousing                ;; set up the patches to hold housing data and household agents
  set myblocks sort blocks
  ;;;;;;
  ;the next few lines makes some corrections to the shapefiles to match with census or metro maps
  ;;;;;;
  ;  rename tract 7000 block groups 1 and 2 to be 2 and 3 to match Census
  ask patches with [ptractblockgrp = "0070002"]
    [ set ptractblockgrp "0070003"]
  ask patches with [ptractblockgrp = "0070001"]
    [ set ptractblockgrp "0070002"]
  ;  rename tract 8002 block group 2 to be 3 to match Census
  ask patches with [ptractblockgrp = "0080022"]
    [ set ptractblockgrp "0080023"]
  ;  rename tract 7200 block groups 1 and 2 to be all block group 1 to match Census
  ask patches with [ptractblockgrp = "0072002"]
    [ set ptractblockgrp "0072001"]


  foreach myblocks [
    x ->
      ;; For each of the 29 Census tract-blockgroups
      let blockID [tractblkgrp] of x
      let blockIDpatches patches with [ptractblockgrp = blockID]
      let blockincrease [%incr_median_income] of x
      ;type blockID type "count patches " print count blockIDpatches
      let number_HU (read-from-string [num_HU] of x)                    ;; keep this as a permanent value since it gets incremented each year.
      let num_pub (read-from-string [num_public_housing] of x )          ;; use read-from-string to convert string to numeric
                                                                         ;show num_pub
      let medianrent (read-from-string [median_monthly_costs] of x )
      let medianmean (read-from-string [median_to_mean] of x )
      ;show medianmean
      let vacancyrate (read-from-string [calc_vac_rate] of x )
      let num_patches count patches with [ptractblockgrp = blockID ]
      let developedrate (number_HU / (maxHUperpatch * num_patches))
      let patchesdeveloped (number_HU / maxHUperpatch)             ;number of patches with housing units

      let blockcrimerate item 10 [crimelist] of x
      if ticks < 11                                          ; after 10 years, keep the last crime rate
      [set blockcrimerate item ticks [crimelist] of x
      ]
      ;type blockID type "year " type ticks type "crime " print blockcrimerate

      ;type "patchesdevelope " print patchesdeveloped
      ask blockIDpatches
      [
      set developed? false
      set pactual_incomeincr blockincrease                        ; record the actual increase in income to campare with simulation
      ]

      let averageHU  number_HU / patchesdeveloped
      ;type blockID type " " type "numpatches " print num_patches

    ask n-of patchesdeveloped patches with [ptractblockgrp = blockID]         ;; first, evenly distribute housing among the patches in that block-group
    [
      set developed? true
      ; NUMBER OF HOUSING UNITS ALGORITHM - USE INTEGER PART TO ASSIGN NUMBER TO EACH PATCH, THEN USE FRACTION
      ;; e.g. if average number of HU per patch is 2.33, then set all patches = 2, and for
      ;; 33% of patches, set num_HU = 3
      set pnumHU int averageHU
      if random-float 1 < (averageHU - pnumHU)
        [set pnumHU pnumHU + 1]           ;; for a fraction of patches, set increment numHU in order fulfill total number of housing units
      if random-float 1 < vacancyrate
        [set pnum_vac pnumHU]             ;; for a fraction of patches set all housing units in patch as vacant
                                          ;; second, calculate distances to metro and CBD
      set ppropcrime blockcrimerate
      set pdistancetometro distance (min-one-of metropatches [distance myself])
      set pdistancetopublic distance (min-one-of publicpatches [distance myself])
      set pdistancetoCBD distancexy -120 53    ;; patch -120, 53 is chosen as CBD for this map)

      ;; if there are housing units on this patch
      ;   if random-float 1 < (read-from-string [calc_vac_rate] of ? )
      ;   [ set

      set prent random-normal medianrent medianrent        ;; third, rent based on random normal distribution

      while [prent < 0] [set prent random-normal medianrent medianrent]
      sprout-households (pnumHU - pnum_vac)                ;; fourth, set up households
      [
        ;hide-turtle
        set budget (medianmean * random-poisson prent)
        set income 3 * budget * 12
        set happy? true
        set looking? false
        ;type income type " "
        set householdblock blockID ;of patch-here
      ]
    ]
      ;; fifth, set up public housing units
      ;; the following code sets all the units in the lowest rent patches to be public housing
      ;; up to number of public housing units in the block
      let n 0
      let incpubHU 0
      foreach sort-on [prent] patches with [ptractblockgrp = blockID]
      [
        y ->
        if n < num_pub [
          ask y [set pnum_pub pnumHU
            set incpubHU pnumHU
          ]
          set n  (n + incpubHU)
      ]]
      ; verify initialization is correct
      ; type blockID type " " type "sum of HU" print sum [pnumHU] of patches with [ptractblockgrp = blockID]
      ; type blockID type " " type "sum of pubHU" print sum [pnum_pub] of patches with [ptractblockgrp = blockID]
      ;type blockID type " " type "sum of vacant" print sum [pnum_vac] of patches with [ptractblockgrp = blockID]
      ; type blockID type " " type "median rent" type median [prent] of patches with [ptractblockgrp = blockID]
      ;type blockID type " " type "num households" print (sum [pnumHU] of patches with [ptractblockgrp = blockID] - sum [pnum_vac] of patches with [ptractblockgrp = blockID] )
      ;type blockID type " " type "median income" print median [income] of households with [householdblock = blockID]

      ask x   ; in loop foreach myblocks)
        [
          set startmeanincome mean [income] of households with [ householdblock = blockID]                 ;    record the starting mean and median income for change comparisons
          set startmedianincome  median [income] of households with [ householdblock = blockID]
      ]
  ]
  rankpatches                                                                  ; rank patches based on preferences

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Identify Movers
;; set up household data for those moving in. identify unhappy households, mark those locations as vacant -
;; add unhappy to those moving in - Move to vacant spots.  if don't find a suitable house - leave area
;; add additional agents to fill spots for those who left area
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to  identifyunhappyhouseholds                                                   ; identify the households that will move this year
  ; show count households

   ;type "movers " print ((percenthouseholdsmove / 100 ) * count households)
  ask n-of ((percenthouseholdsmove / 100 ) * count households) households
  [set happy? false
   set pnum_vac pnum_vac + 1
   ]
  ask households
  [
  if (prent > budget and happy? = true )                                        ; those whose rent is greater than their budget with also move
  [
  set happy? false
  set pnum_vac pnum_vac + 1
  if random 2 = 0 [die]
  ]]
 ;type "movers " print count households with [happy? = false]  ; verify starting number of households who want to move.
 ;type "close to metro " print count households with [happy? = false and pdistancetometro < 20]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;  Create New Construction  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to createincominghousingunits
  foreach myblocks [                        ;; For each of the 29 Census tract-blockgroups
    x -> ask x
    [
      let blockID [tractblkgrp] of x
      let newunits [new_HU] of x
      let blockcrimerate item 10 [crimelist] of x
      if ticks < 11
      [set blockcrimerate item ticks [crimelist] of x

      ]
      let k count patches with [ptractblockgrp = blockID and developed? = false]
      ifelse k < (newunits / maxHUperpatch)
      [ask x [set %incr_HU 0]]
      [
        ask n-of (newunits / maxHUperpatch) patches with [ptractblockgrp = blockID and developed? = false] ;; randomly select available patches for new units
        [
          set pnumHU maxHUperpatch
          set pnum_vac maxHUperpatch
          set pnum_pub 0                   ; existing public housing units maintained but no new units added.
          set developed? true
          set prent random-normal newrents newrents
          while [prent < 0] [set prent random-normal newrents newrents]
          set ppropcrime blockcrimerate
          set pdistancetometro distance (min-one-of metropatches [distance myself])
          set pdistancetopublic distance (min-one-of publicpatches [distance myself])
          set pdistancetoCBD distancexy -120 53    ;; patch -120, 53 is chosen as CBD for this map)
        ]
      ]
     ]
    ]
    rankpatches              ; rank the new contruction units
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   create new residents    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to createincominghouseholds
  let incomingHU (yearlyhouseholdincrease  * count households) + nummoveout       ;; how many incoming residents
         ;type "nummoveout " type nummoveout type " " print yearlyhouseholdincrease
         ;print incomingHU
         let p 0
         set q 0
         while [p < incomingHU and q <= 100] [              ; keep creating agents until total new households for the year have been created


        create-households 1
        [
              ;hide-turtle

              set income random-normal DCmeanincome DCmeanincome                        ; set income
              while [income < 0] [set income random-normal DCmeanincome DCmeanincome]
              set budget (income / 12 ) / 3                                             ; set budget
              set happy? false
              set looking? true
              ;set householdblock blockID
                  ;  type "original " type xcor type " " print ycor type " " type "num vac " print pnum_vac
              let tempbudget budget
              let affordablevacancies patches with [pnum_vac > 0 and prent <= tempbudget ]        ; identify affordable vacancies
              let k count affordablevacancies
              ;if affordablevacancies < ( incomingHU - p + 1) [stop]
              ;type "vacancies " print count affordablevacancies
             ;ifelse any? affordablevacancies
               let target 0
             ifelse any? affordablevacancies
               [

              ;let target one-of affordablevacancies
             ; let target min-one-of affordablevacancies [rank]
            ; let target 0
             ifelse High_Value_Preference?
             [
               ifelse k >= 3  [set target max-one-of (min-n-of (k / 3) affordablevacancies [rank]) [prent]]       ; satisficing finds top third of ranked patches - choose best (highest value) of these
                [set target min-one-of affordablevacancies [rank]]
             ]
             [set target min-one-of affordablevacancies [rank]
               ;print target
               ]
               move-to target                                          ; move to new home and set patch variables to know that you are here
              set pnum_vac pnum_vac - 1
              set happy? true
              set householdblock ptractblockgrp
              show-turtle
              set p (p + 1)
              ]
               [; print "no affordable vacancies"
                set q (q + 1)
                if q > 100 [
                 ; print "sampled 100 incoming "
                 ; type "total added " print p
                stop
                  ]]
        ]
         ] ; end while


   ask households with [happy? = false] [die]                              ; if you don't find affordable housing then leave area
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       ranking routine     ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to rankpatches                                                                             ; rank patches according to crime and distance preferences
  let maxdistancetometro (max [pdistancetometro] of patches with [developed? = true] + 1)  ; add 1 so you don't have any distances of 0 which would make the rank 0
  let maxdistancetopublic (max [pdistancetopublic] of patches with [developed? = true] + 1)
  let maxproprate max [ppropcrime] of patches with [developed? = true]

  ask patches
  ; set rank according to crime and distance to metro and public housing
    [
     ifelse Public_Housing = "Proximity_to"
      [
      set rank ((ppropcrime / maxproprate) ^ lowcrimepref) * ((pdistancetometro / maxdistancetometro) ^ metropref ) * ((pdistancetopublic / maxdistancetopublic) ^ publichousingpref )]
  ; else public housing preference is "Distance_from"
    [set rank ((ppropcrime / maxproprate) ^ lowcrimepref) * ((pdistancetometro / maxdistancetometro) ^ metropref ) * ((1 - (pdistancetopublic / maxdistancetopublic)) ^ publichousingpref )]
    ]
    end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;       move routine        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to movehouseholds    ; move existing households
   ask households with [happy? = false] [
     let tempbudget budget
     let affordablevacancies patches with [pnum_vac > 0 and prent <= tempbudget ]
     let k count affordablevacancies
     let target 0
     if any? affordablevacancies
      [
             ifelse High_Value_Preference?                          ; choose best (highest value) among set of properties that satisfy budget and preference needs
             [
               ifelse k >= 3  [set target max-one-of (min-n-of (k / 3) affordablevacancies [rank]) [prent]]
                [set target min-one-of affordablevacancies [rank]]
             ]
             [set target min-one-of affordablevacancies [rank]  ]
          move-to target
          set pnum_vac pnum_vac - 1
          set happy? true
          show-turtle
      ]
     ]
   set nummoveout count households with [happy? = false]  ; the rest move out
   ask households with [happy? = false] [die]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;   calculate income increase routine   ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to calculateincomeincrease
  ask blocks
  [
    let temptrak tractblkgrp
    let currentmeanincome  mean [income] of households with [ householdblock = temptrak]
    let currentmedianincome median [income] of households with [ householdblock = temptrak]

    set simulated%increasemeanincome (currentmeanincome - startmeanincome) / startmeanincome
    set simulated%increasemedianincome (currentmedianincome - startmedianincome) / startmedianincome

    ; type temptrak type " sum vacancies " print sum [pnum_vac] of patches with [ptractblockgrp = temptrak]
  ]

  foreach myblocks
  [
    x ->

    if ticks = 10 [ print [simulated%increasemeanincome] of x]  ; collect output data for run validation
    let blockID [tractblkgrp] of x
    ask patches with [ptractblockgrp = blockID]
    [
      set psimulation_incomeincr  [simulated%increasemeanincome] of x                      ; update patches with income increase to display
      set psimulation_meanincomeincr  [simulated%increasemedianincome] of x
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    display actual income increase ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to showactualincomeincrease                                          ; called from user interface button
  ask patches with [pactual_incomeincr > 0]
   [
     ;set pcolor scale-color pink (.25 + ln pactual_incomeincr) 0 1.5
     ifelse pactual_incomeincr < 0.5 [set pcolor pink - 5]
     [ifelse pactual_incomeincr < 1.0 [set pcolor pink - 3.5]
     [ifelse pactual_incomeincr < 1.5 [set pcolor pink - .5]
     [ifelse pactual_incomeincr < 2.0 [set pcolor pink + 2 ]
       [set pcolor pink + 4.5 ]]]]
  ]
  ; pink and cyan are good choices
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;    display simulation income increase ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to showsimulationincomeincrease                                      ; called from user interface button
  ask patches with [psimulation_incomeincr > 0]
   [
     ;set pcolor scale-color pink (.25 + ln psimulation_incomeincr) 0 1.5
     ifelse psimulation_incomeincr < 0.5 [set pcolor pink - 5]
     [ifelse psimulation_incomeincr < 1.0 [set pcolor pink - 3.5]
     [ifelse psimulation_incomeincr < 1.5 [set pcolor pink - .5]
     [ifelse psimulation_incomeincr < 2.0 [set pcolor pink + 2 ]
       [set pcolor pink + 4.5 ]]]]
  ]
  ; pink and cyan are good choices
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                        ;;
;;  Load GIS Shapefiles   ;;
;;                        ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to viewDCmetrostations
  let DCmetro gis:load-dataset "data/MetroStn_Concentrated/MetroStn_Concentrated.shp"
  ;gis:set-drawing-color white
  ;gis:draw DCmetro 0.5
  foreach gis:feature-list-of DCmetro[
    feature ->
    gis:set-drawing-color blue
    gis:draw feature 5.0
  ]

  ask patches gis:intersecting DCmetro ; identify the patches with metro station
  [ set pMetro true ]
  ;   ask patch -120 -28     ;; add a waterfront metro rail station so that coordinates show up on map.
  ;   [ set pMetro true
  ;     set pcolor blue ]
  set metropatches patches with [pMetro = true]
end

to viewDCSchools
  let DC gis:load-dataset "data/DCschools/SHSBNDYPLY_WGS84.shp"
  foreach gis:feature-list-of DC
  [
    feature ->
    gis:set-drawing-color white
    gis:draw feature 2.0

  ]
  ; gis:apply-coverage DC "SCHOOLNAME" HS  ; color map according to school district

 ;ask patches
 ; [if (HS = "Anacostia") [set pcolor blue + 3]
 ;  if (HS = "Coolidge") [set pcolor green + 3]
 ;  if (HS = "Eastern") [set pcolor yellow + 3]
 ;  if (HS = "Roosevelt") [set pcolor grey + 3]
 ;  if (HS = "Spingarn") [set pcolor orange + 3]
 ;  if (HS = "Woodson, H.D.") [set pcolor violet + 3]
 ;  if (HS = "Wilson, W.") [set pcolor red + 3]
 ;  if (HS = "Ballou") [set pcolor brown + 3]
 ;  if (HS = "Cardozo") [set pcolor pink + 3]
 ;  if (HS = "Dunbar") [set pcolor cyan + 3]]

  ; gis:set-drawing-color blue
  foreach gis:feature-list-of DC             ; label the school district
  [
    feature ->

      let centroid gis:location-of gis:centroid-of feature
      if not empty? centroid
      [ create-hs-labels 1
        [ set xcor item 0 centroid + 2
          set ycor item 1 centroid
          set size 0
          set label-color Cyan
          set label gis:property-value feature "SCHOOLNAME" ]]
  ]

end

to loadDCSchools
  let DC gis:load-dataset "data/DCschools/SHSBNDYPLY_WGS84.shp"
  gis:apply-coverage DC "SCHOOLNAME" HS
end

 to loadDCblockgroupshapefile
 gis:load-coordinate-system "data/tractdata/WGS_84_Geographic.prj"
  set DCblockdemo gis:load-dataset "data/tractdata/blkgrp_DConly_Concentrated/blkgrp_DConly_Concentrated.shp"
  gis:set-world-envelope gis:envelope-of DCblockdemo
  foreach gis:feature-list-of DCblockdemo
  [
    feature ->
    gis:set-drawing-color violet
    gis:draw feature 1.5
  ]
   gis:apply-coverage DCblockdemo "TRACT" ptract
   gis:apply-coverage DCblockdemo "BLKGRP" pBLKGRP
    ask patches with [ptract > 0]
     [
       set ptractblockgrp word ptract pBLKGRP
     ]
 end

to loadDCblockgroupdemographics
  foreach gis:feature-list-of DCblockdemo
  [
    feature ->
    gis:set-drawing-color violet + 3
    gis:draw feature 2
  ]

; Using gis:apply-coverage to copy values from a polygon dataset
; to a patch variable

 gis:apply-coverage DCblockdemo "POP2000" pPOP2000
 gis:apply-coverage DCblockdemo "POP2010" pPOP2010
 gis:apply-coverage DCblockdemo "TRACT" ptract
 gis:apply-coverage DCblockdemo "HOUSEHOLDS" phouseholds10
 gis:apply-coverage DCblockdemo "BLKGRP" pBLKGRP

  ask patches with [pPOP2000 > 0]
     [
       set ptractblockgrp word ptract pBLKGRP
     ]
end


to viewpublichousing
  let DCpublichouse gis:load-dataset "data/tractdata/Public_Housing_Pointfinala/Public_Housing_Pointfinala.shp"
  foreach gis:feature-list-of DCpublichouse
  [
    feature ->
    gis:set-drawing-color lime + 1
    gis:draw feature 5.0
  ]
  ask patches gis:intersecting DCpublichouse ; identify the patches with metro station
[ set pPUblic true ]

  set publicpatches patches with [pPublic = true]
end


to clearCanvas
  ca
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                       ;;
;;  File Input Routines adapted from     ;;
;;  suggestions of Steve Scott, CSS PhD  ;;
;;  candidate                            ;;
;;                                       ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to input2000data
  setup-globals
  read-csv
  ;print-results
end

; setup globals
to setup-globals
  set myfile "data/inputdata/DC Data 2000.csv"
  set csvheaders []
  set csvdata []
end

;
; helper function to parse a comma-separated line
;
to-report parse-line [ aline ]
  let parsed-list []
  let separator ","
  let i 0
  let ch ""
  let token ""
  while [ i < length aline ] [
    set ch item i aline
    ifelse (ch = separator) [
      set parsed-list (lput token parsed-list)
      set token ""
    ]
    [
      set token (word token ch)
    ]
    set i (i + 1)
  ]
  set parsed-list (lput token parsed-list)
  report parsed-list
end

;
; read the CSV
; first line is comma-separated headers
; 2nd thru Nth lines are comma-separated values
;
; does not strip out blank spaces, so ", foo" gets parsed as " foo".
;
to read-csv
  ;let csvfile myfile
  print (word "DEBUG: processing file " myfile)
  ; open the file
  ifelse file-exists? myfile [
    file-open myfile
    ; read first line with headers
    let headers file-read-line
    let tokens parse-line headers
    ; for each column, put column header in csvheaders, put empty list in csvdata.
    foreach tokens [
      x ->
      set csvheaders (lput x csvheaders)
      set csvdata (lput [] csvdata)
    ]
    ; read rest of file
    let i 0
    while [ not file-at-end? ] [
      let line file-read-line
      ;;print (word "DEBUG: just read line # " i ", = " line)

      set tokens parse-line line  ; list containing items in line
      let k 0
      ; for each item in the line, place in next column list
      foreach tokens [
        x ->
        let datalist item k csvdata
        set datalist (lput x datalist)
        set csvdata replace-item k csvdata datalist
        set k (k + 1)
      ]
      set i (i + 1)
    ]
    file-close-all
  ]
  [
    print (word "error: unable to open file " myfile)
  ]

end

to print-results
  ; print out the list of CSV headers
  foreach csvheaders [
    x ->
    type x type " "
  ]
  print " "
  ; loop thru and print out each row of data
  let numcols length csvheaders
  let numitems length item 0 csvdata
  type "numitems" print numitems
  let i 0
  while [ i < numitems ] [
    let j 0
    while [ j < numcols ] [
      let value item i (item j csvdata)

      type value type ", "
      set j (j + 1)
    ]
    set i (i + 1)
    print ""
  ]
  ; print out each tract
  set i 0
  while [ i < numitems ] [
    let j 0
      let value item i (item j csvdata)
      type value type ", "
    set i (i + 1)
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
@#$#@#$#@
GRAPHICS-WINDOW
209
13
785
496
-1
-1
2.36
1
10
1
1
1
0
0
0
1
-120
120
-100
100
1
1
1
ticks
30.0

BUTTON
8
13
103
71
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
903
484
1001
517
View Metro
viewDCmetrostations
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
787
484
903
517
View Public Housing
viewpublichousing
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
800
555
1028
600
DC_Map
DC_Map
"data/Ward6.png" "data/Ward6-transparent.png"
0

BUTTON
8
135
198
168
NIL
import-drawing DC_Map
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
669
528
786
561
NIL
clear-all
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
788
126
997
159
Show Actual Income Increase
showactualincomeincrease
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
113
76
198
134
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
112
13
197
72
Go Once
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

PLOT
791
206
999
326
Household Income
income
# of households
0.0
300000.0
0.0
10.0
true
false
"" ""
PENS
"default" 50.0 1 -16777216 true "" "histogram [income] of households"

PLOT
788
326
1001
452
monthly housing costs
costs
# housing units
0.0
5000.0
0.0
25.0
true
false
"" ""
PENS
"default" 50.0 1 -16777216 true "" "histogram [prent] of households"

BUTTON
893
451
1001
484
Hide Households
ask turtles\n[hide-turtle]\n
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
788
451
894
484
Show Households
ask households\n[show-turtle]\n
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
7
203
203
236
lowcrimepref
lowcrimepref
0
1
0.0
.01
1
NIL
HORIZONTAL

MONITOR
8
372
203
417
metropreference
1 - lowcrimepref - publichousingpref
2
1
11

BUTTON
791
167
894
201
Simulation Result
showsimulationincomeincrease
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
894
160
999
205
Median Income
median [income] of households
0
1
11

SWITCH
7
425
202
458
High_Value_Preference?
High_Value_Preference?
0
1
-1000

TEXTBOX
11
466
202
518
If on, the household chooses the most expensive house that meets the crime and metro preferences.
11
0.0
1

SLIDER
7
243
203
276
publichousingpref
publichousingpref
0
1 - lowcrimepref
0.0
.01
1
NIL
HORIZONTAL

INPUTBOX
8
74
103
134
Years_Simulated
0.0
1
0
Number

TEXTBOX
11
169
196
209
Location Preferences
16
0.0
1

TEXTBOX
15
289
209
319
Do agents prefer close proximity to\nor distance from public housing?
11
0.0
1

CHOOSER
7
321
202
366
Public_Housing
Public_Housing
"Proximity_to" "Distance_from"
1

TEXTBOX
791
16
990
117
           LEGEND\nWhite:   over 200%\nLt Pink: 150% to 200%\nPink:     100% to 150%\nBrown:   50% to 100%\nBlack:    0% to 50%
14
0.0
1

@#$#@#$#@
## WHAT IS IT?
This NetLogo model simulates the movement of people in and out of tract groups within DC. It is an agent-based model of gentrification of an area in Southeast D.C. and uses methodology similar to that used in LUCC models to categorize the amount of gentrification based on land conversion from low-income to high-income residents. The model is instantiated with empirical data from the study area and provides a test-bed for different hypothesis of residential mobility during gentrification.


## HOW IT WORKS

The model imports year 2000 data describing 29 Census block groups within thirteen tracts in Washington DC. The model imports shapefiles describing the block groups, metro rail stations, school districts and public housing within those block groups. Patches within each block group are initialized with the appropriate number of housing units and public housing units. The patches are assigned a heterogeneous housing cost (rent) using the random-normal function.
Crime rates per 1000, for the years from 2000 to 2010 is downloaded from the Neighborhood Info DC website (NeighborhoodInfoDC, 2014), a project of The Urban Institute and Washington DC Local Initiatives Support Corporation (LISC).
The demand side of housing is represented by household agents.

Agents are created and located within the patches in block groups. Existing agents search for a new place to live that meets their preferences.  New agents are introduced to the model based on known new households between 2000 and 2010.

Much research asserts that movement of different socioeconomic groups is also affected by the supply side of housing.  Investments made in different block groups is known by Census data on the number of housing units in 2000 and the growth to 2010.

## HOW TO USE IT

1) set the sliders to indicate the relative preferences of Low crime, proximity to metro and proximity to / distance from public housing.

2) click on the setup to clear the screen and re-initialize the parameters.

3) Click on go to run the simulation for the 10 years from 2000 to 2010.

4) click on "import-drawing DC_Map" to show the gentrified area in context of the street map. clicking multiple times will make the transparency darker.

5) click on view public housing and view metro to make public housing and metro locations show up better.


## THINGS TO NOTICE

Notice how the interface enforces the restriction on the sliders so that they sum to 1. This is not always immediate. If they don't sum correctly, try clicking on the sliders to get them to reset.

## THINGS TO TRY

Try hiding the turtles (select "Hide Households" button in lower right) after set up so that only moves and new incoming resident turtles show up.  This will make the preferences more visually explicit.

## EXTENDING THE MODEL

Look at the housing lifecycle, single, married, with kids, empty nesters. The neighborhood will go thorugh cycles of decline and reinvestment / rejuvenation depending on the distribution of differing lifecylce states of the inhabitants the neighborhood.

## NETLOGO FEATURES


The model calculates the distance from a patch to the closest metro:
       set pdistancetometro distance (min-one-of metropatches [distance myself])

Notice how school names and tract and block names found in the shapefiles are applied to the patch varaiables HS ptract and pBLKGRP using "apply-coverage".

Notice how the locations of metro stations are applied from the shapefile to the patch using "intersecting".

Notice how the "import-drawing" is used to display a map of DC. Since the map was edited to have a transparency of 75% it allowed the shapefiles to show up through the map.  The street map was cropped and its size adjusted to correspond precisely with the block groups.

## CREDITS AND REFERENCES


Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

U.S. Census Bureau; Selected Tables generated by Elaine Reed; using American FactFinder; <http://factfinder2.census.gov>; (April 2014).
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
