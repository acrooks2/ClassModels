;; NOTES TO READER:
;;
;; 1) I used 2007-2011, 5-yr, American Community Survey data to contextualize model with real world statistics, except where otherwise stated.
;;    (additional data is primariy from CIA World FactBook, Census Bureau, and a few numbers are lightly invented)
;;
;; 2) ALL plotting commands, except histograms, are in the plots themselves (I decided it's less cluttered there)
;;    I use the word "socialize" loosely in comments... I think of it as social/work/school/some other interaction/etc all rolled into one
;;
;; 3) Lastly, thanks to Uri Wilensky for inspiring some of the critical components of this model.
;;    The functions called "be-social", "acquire-english", and "marry" borrow a socializing function from Wilensky's AIDS model, available in the
;;    NetLogo libary, part of the standard installation at the time of this code's writing.
;;
;; Thanks for looking at my model. Hope you enjoy.
;;

;;************************;;
;;INITIAL SETUP PROCEDURES;;
;;************************;;

breed [natives native]
breed [foreigns foreign]  ;; this should be divided into more specific groups in a future model

globals [

  ;;----------------------------------------------;;
  ;;CUSTOMIZE THESE VALUES IN FUNCTION: "TO SETUP";;
  ;;       (or use sliders when available)        ;;
  ;;----------------------------------------------;;

  population  ;; total population size
  proportion-native  ;; proportion native to the stage under observation at init
  proportion-foreign  ;; this + proprortion = 1

  pop-init-native  ;; this lets the model output the starting native population size
  pop-init-foreign  ;; same, but for foreign breed

  birth-rate  ;; a constant based on annual birth rate, converted for the model
  death-rate  ;; a constant based on annual death rate, converted for the model
  mig-arrive-rate  ;; a constant based on annual in-migration rate, converted for the model
  mig-depart-rate  ;; a constant based on annual out-migration rate, converted for the model

  ;;---------------------------------------------;;
  ;;THESE ARE COUNTERS, NOTHING HERE TO CUSTOMIZE;;
  ;;---------------------------------------------;;

  birth-growth ;; a value-holder that increases at the rate above each tick; when it reaches 1, a new agent is "born" and this counter is reduced by 1.
  death-growth  ;; a value-holder that increases at the rate above each tick; when it reaches 1, an agent is set to "dead." If deaths from old age are common, this value will be negative
  mig-arrive-growth ;; a value-holder that increases at the rate above; when it reaches 1, a new agent is "arrives"
  mig-depart-growth ;; a value-holder that increases at the rate above; when it reaches 1, a new agent "departs"

  births ;; just a counter for population increase via births (informational purposes only)
  deaths ;; just a counter for population decrease via deaths (informational purposes only)
  in-mig  ;; just a counter for population increase via migration (informational purposes only)
  out-mig  ;; just a counter for population decrease via migration (informational purposes only)

  ]

turtles-own [

  ;;-----------------------------------------------------;;
  ;; MEASURE THESE TO CHECK FOR ASSIMILATED INDIVIDUALS  ;;
  ;;(SES, english, intermarriage?, spatial-concentration);;
  ;;-----------------------------------------------------;;

  SES ;; A proxy for class. Uses six options derived from custom ACS variable: 1, 2, 3, 4, 5, 6 (Poverty, Working, Lower, Middle, Upper-Mid, Upper)
  english ;; proportional fluency (0 to 1) to native group of same status--unrealistic 1 IS attainable over time, but won't occur for all foreigns
  intermarriage? ;; married to other group? (only intermarried foreigns count for assimilation)
  spatial-concentration ;; Proxy: defined for each agent as the calculation of (number of other same-breed in proximity / number of other breed in proximity) <- excludes self from calculation

  assimilated?  ;; foreign-use only! (Natives always set this to 0 rather than T/F). Returns True if 3/4 conditions are met.

  ;; these variables are checked and updated every tick. They influence what actions are available and the probability of certain functions triggering a pass/fail
  social?
  age

  ;; these variables are set, permitted to update once, then remain static ("intermarriage?" follows this rule, too!)
  married?
  marriage-partner  ;; will report nobody if partner dies, but remarrying is not currently an option

  ]

to setup
  clear-all

  set population set-population-size  ;; estimated 307M population in 2011 (ACS data)
  set proportion-native (set-percent-native / 100) * population
  set proportion-foreign (1 - (set-percent-native / 100)) * population

  ;; These rates calculated by the following:
  ;; (rate per 1000 population) * 307000 / 1000000 / 52 ;; In English: (constant rate from data) * (307000 to reach estimated 3.7M population in 2011) / (1000000 to scale back to my model's size) / (52 weeks in year) = rate of growth per week (tick)
  ;;
  ;; The default values are based on rates provided by CIA WorldFactBook 2011 data as follows:
  ;; birth-rate: 13.83
  ;; death-rate: 8.38
  ;; Net-migration: 4.18 (I split it as follows to allow people to leave and arrive: ...)
  ;; In-migration: 5.18
  ;; Out-migration: 1.00

  set birth-rate .08
  set death-rate .05
  set mig-arrive-rate 0.03
  set mig-depart-rate 0.006

  set-default-shape turtles "person"

  population-init

  updateHistogram ;; these are SES histograms

  reset-ticks   ;; set ticks to 0. Each tick = 1 week in this model
end

  ;;--------------------------------------------------------------------------------------------------------------------------------------------------;;
  ;;                INITIAL POPULATION DATA IS BASED ON NORMAL DISTRIBUTION FROM SURVEY CALCULATIONS OR OFFICIAL NATIONAL DATA                        ;;
  ;;(the "native" breed distributions also apply to newborns if the born_as_native_always? is set to true. Otherwise, newborns inherit parent's data) ;;
  ;;--------------------------------------------------------------------------------------------------------------------------------------------------;;

to population-init
    ask n-of proportion-native patches[
    sprout-natives 1
    [
      setxy random-xcor random-ycor
      set color blue  ;; distinguishes one breed from another
      set social? False ;; not born socializing
      set SES round abs random-normal 2.72 1.67  ;; set economic/class status
      set age random-normal 36.47 23.19  ;; initial populations aren't born simultaneously
      set english 1  ;; I don't see a point in setting this below 1 for natives (see actual data on the lines immediately below this)
      ;set english random-normal 0.974 0.086  ;; In 2011 (ACS dataset) values are Mean:  4.87 Std Dev: .43 on 1-5 scale. Here, converted to 0-1 scale.

      set married? False ;; by default set everyone unmarried at init. Probably of marriage increases with age starting at 18
      set intermarriage? False  ;; not born intermarried -- might change once marriage partner is found

      ;;after everything is set for an agent, check the agent's normally-distributed values for realism and re-try until corrected
      while [SES < 1 or SES = 0 or SES < 0 or SES > 6]
      [
        set SES round abs random-normal 2.72 1.67
      ]

      while [age < 0]  ;; in most tests, this check is unnecessary--added for safety
      [
        set age random-normal 36.47 23.19
      ]

      ;;set spatial-concentration 0 ;; actually, this is calculated at every tick--no need to set a default

      ;; no "assimilated?" parameter needed for native-born... will report as "0" for natives, but is never used
      ]
    ]

    ask n-of proportion-foreign patches[
    sprout-foreigns 1
    [
      setxy random-xcor random-ycor
      set color red  ;; distinguishes one breed from another
      set social? False  ;; not born socializing
      set SES round random-normal 2.27 1.44  ;; set economic/class status
      set age random-normal 42.04 17.99  ;; initial populations aren't born simultaneously
      set english random-normal 0.646 0.246  ;; In 2011 (ACS dataset) values are Mean:  3.23 Std Dev: 1.23 on 1-5 scale. Here, converted to 0-1 scale.
      if english < 0
      [
        set english 0
      ]
      set married? False ;; by default set everyone unmarried at init. Probably of marriage increases with age starting at 18
      set intermarriage? False  ;; not born intermarried -- might change once marriage partner is found

                                ;;set spatial-concentration 0 ;; actually, this is calculated at every tick--no need to set a default

      set assimilated? False  ;; This is set to True by another function. Once "True" it won't revert to "False"


      ;;after everything is set for an agent, check the agent's normally-distributed values for realism and re-try until corrected
      while [SES < 1 or SES = 0 or SES < 0 or SES > 6]  ;; in most tests, this check is unnecessary--added for safety
      [
        set SES round random-normal 2.27 1.44
      ]

      while [age < 0]  ;; in most tests, this check is unnecessary--added for safety
      [
        set age random-normal 42.04 17.99
      ]

    ]
    ]

    set pop-init-native count natives
    set pop-init-foreign count foreigns

end

;;************************;;
;;  POST-SETUP ACTIVITIES ;;
;; (finally some action!) ;;
;;************************;;

to go

  ;;--------------------;;
  ;;MAKE AGENTS DO STUFF;;
  ;;--------------------;;

  ask turtles
  [
    agify  ;; make the turtles get older (and show it!)
    move   ;; Can't be social if nobody gets together
    be-social   ;; Initiate a check that the conditions to socialize are met--and adjust status accordingly
    un-social   ;; un-social check is initiated immediately before other social-dependent functions... Therefore, if socializing fails or ends, nothing else can happen.
    acquire-english    ;; While socializing, English ability improves
    marry   ;; sets probability for marriage, but only occurs while socializing
    spatial-concentration-check  ;; Checks who neighbors are, regardless of "social?" status
    assimilation-check  ;; every round, see if assimilation conditions are met for each agent and report
  ]

  ;;---------------------;;
  ;;POP CHANGE FUNCTIONS ;;
  ;;(world-level changes);;
  ;;---------------------;;

  birth-check       ;; controls birth rate (breed is loosely controlled by "born_as_native_always?" variable)
  migrant-arrive    ;; controls arrival

  death-check       ;; controls death rates--well, tries to. People also die at age 115, so if the model runs long enough then this check only prevents people UNDER age 115 from dieing
  migrant-depart    ;; controls departure rate (anyone can be selected to leave)

  updateHistogram

  tick  ;; 1 tick = 1 week.
end

  ;;---------------------------------------------;;
  ;;              UPDATE HISTOGRAMS              ;;
  ;;(other plots have codes inside, on interface);;
  ;;---------------------------------------------;;


to updateHistogram
  set-current-plot "plot-immigrant-SES"
  set-plot-pen-mode 1
  histogram [SES] of foreigns

  set-current-plot "plot-native-SES"
  set-plot-pen-mode 1
  histogram [SES] of natives

  set-current-plot "plot-age"
  set-plot-pen-mode 1
  histogram [age] of turtles

end

  ;;-------------------------------------------------------------------------------------;;
  ;;    THIS IS THE BEGINNING OF THE FLOW-CHART ACTIVITY SHOWN/DESCRIBED IN THE PAPER    ;;
  ;;(ALL agents do the following; "social?" state is checked within the actual functions);;
  ;;-------------------------------------------------------------------------------------;;

to agify ;; I like to make up new words
  ifelse breed = natives [
    set color scale-color blue age 200 -100   ;; This range scales colors from light to dark based on agent's age. The large range prevents white and black extremes by extending well beyond the possible values of "age."
    set age age + 1 / 52
  ]
  [
    set color scale-color red age 200 -100
    set age age + 1 / 52
  ]

  if age >= 78[ ;; This will be checked every week after the agent turns 78.0 years of age
    if random-float 1 < age / 156 / 52 ;; this sub-function gives my agents approximately 1% chance to die at its 78.0th year of age. This value increases slightly each week.
      [
        if death-growth > 0 [
          set death-growth death-growth - 1 ;; helps mitigate excessive death of population
          set deaths deaths + 1
          ask (patch-here) [set pcolor black]  ;; reset patch
          die ;; kill turtle -- last thing to do because the turtle is ASKED to do the other things!
        ]
      ]
  ]

  if age >= 115
    [
      set death-growth death-growth - 1 ;; helps mitigate excessive death of population
      set deaths deaths + 1  ;; must be adjusted before turtle actually dies, because the turtle is "asked" to do this!
      ask (patch-here) [set pcolor black]  ;; reset patch
      die ;; kill turtle -- last thing to do because the turtle is ASKED to do other things!
    ]
end


to move
  if social? = false[
    let nearest-similar min-one-of (other turtles with [((breed = [breed] of myself) or (assimilated? = [assimilated?] of myself)) and ((SES = [SES] of myself) or (SES = [SES] of myself + 1)) and ((age - [age] of myself < 5) or ([age] of myself - age < 5))]) [ distance myself ]  ;; locate the person MOST like myself and move that direction (can stop to socialize with others along the way)
    if nearest-similar = nobody  ;; in place for safety... has crashed with this condition left unchecked
    [
      set nearest-similar min-one-of (other turtles with [(SES = [SES] of myself or SES = [SES] of myself + 1 or breed = [breed] of myself) and ((age - [age] of myself < 5) or ([age] of myself - age < 5))]) [ distance myself ]  ;; if all conditions aren't met, settle for basics and choose one of major categories within age range
      face nearest-similar   ;; face that similar other so you can move towards him/her
    ]
    forward 3   ;;  get closer and maybe say "hi!" to someone along the way! (find out in the next function "be-social")
  ]
end

to be-social ;; This function adapted and modified from the AIDS model by Uri Wilensky, copyright 1997, available in NetLogo's model library. I use this type of function (the "potential-partner" evaluation/social? status change) multiple times, but I swear they're all copied equally from the same source...
  let potential-partner one-of other (turtles in-radius 2) with [((SES = [SES] of myself) or (breed = [breed] of myself) or (assimilated? = [assimilated?] of myself)) and ((age - [age] of myself < 5) or ([age] of myself - age < 5)) and ((breed = [breed] of myself) or (english > [english] of myself - .1 and english < [english] of myself + .1)) ] ;; make sure we have SOMETHING in common and communicate reasonably well
  if potential-partner != nobody;; make sure I am capable of interacting as well
    [
      set social? True   ;; "I can be social with multiple turtles... if they come to me (I don't move while social)"
      move-to patch-here ;; move to center of patch
      ask patch-here [ set pcolor [color] of myself - 3 ]
      ask potential-partner [  ;; do all the same stuff I do
        set social? True
        move-to patch-here
        ask patch-here [ set pcolor [color] of myself - 3 ]
      ]
    ]
end

to un-social
  if social?
    [ if random-float 1 < age / 115 [  ;; Agent becomes less tolerant of interaction as with age. 115 is the the maximum an agent can live, so there's always at least a small chance of being social
      set social? False          ;; Quit being social
      ask patch-here [ set pcolor black ] ;; reset patch so it doesn't draw observer's attention
    ]

    let potential-partner one-of other (turtles in-radius 1) with [SES = [SES] of myself and english > 0] ;; check again... if nobody around, stop talking to yourself!
    if potential-partner = nobody[  ;; friends all left
      set social? False             ;; You're not talking to anyone... don't lie about it
      ask patch-here [ set pcolor black ]  ;; reset patch so it doesn't draw observer's attention
    ]
    ]
end

to acquire-english ;; based on the "be-social" function above. See comments there for more info including additional citation info.
  let potential-speaker one-of other (turtles in-radius 2) with [social?]  ;; this just ensures that at least one person is nearby and talking
  if social? and potential-speaker != nobody;;  only increase English proficiency while near English speakers
  [
    ifelse english < 1  ;; if I'm not fluent in English
    [ let potential-speaker-fluency ((sum [english] of other (turtles in-radius 2) with [social?]) / count other (turtles in-radius 2) with [social?]) ;; then figure out the rate at which English is being used (it's not actually used... this is an assumption)
      if potential-speaker-fluency != 0 ;; if I can hear some english...
      [
        ifelse age > 13  ;; and I'm either above the critical threshhold for becoming a native speaker or I'm not...
        [ let english-rate ((0.00526 * 1 * potential-speaker-fluency) / (age - 13) + .001)  ;; if not, I'll probably learn English at a maximum rate of .001. This means I'd take close to 20 yrs to approach nativity without any knowledge of English already
           set english english + english-rate ]
        [ let english-rate (0.00526 * 1 * potential-speaker-fluency) ;; if I'm 13 or younger, I can learn much faster
           set english english + english-rate ]
      ]
    ] ;; rate = 1/190.06 = 1/3.655*52 = 1 / (average time for children to reach native proficiency * 52 weeks/yr) = 0.00526
    [set english 1]  ;; a check to make sure English never exceeds 1
  ]
end

to marry ;; based on the "be-social" function above. See comments there for more info including additional citation info.
  if social? and not married? and age >= 18
  [
    let potential-partner one-of other (turtles in-radius 2) with [social? and not married? and ((SES = [SES] of myself) or (SES = [SES] of myself + 1) or (SES = [SES] of myself - 1)) and ((english < [english] of myself + 0.1 and english > [english] of myself - 0.1) or breed = [breed] of myself) and age >= 18]
    if potential-partner != nobody[
      if random-float 1 < age / 52  ;; probability for marriage remains above 0 and increases with age
      [
        if random-float 1 < [age] of potential-partner / 52
        [
          set married? True
          set marriage-partner potential-partner
          ask potential-partner
          [
            set married? True
            set marriage-partner myself
          ]
          if breed != [breed] of marriage-partner
          [
            set intermarriage? True
            ask marriage-partner
            [
              set intermarriage? True
            ]
          ]
          if SES != [SES] of marriage-partner  ;;  partner with lowest SES inherits the status of the larger SES
          [
            if SES > [SES] of marriage-partner
            [
              ask marriage-partner
              [
                set SES [SES] of myself
              ]
            ]
            if SES < [SES] of marriage-partner
            [
              set SES [SES] of marriage-partner
            ]
          ]
        ]
      ]
    ]
  ]
end

to spatial-concentration-check   ;; constantly changes--this is the wildcard of the model; because assimilation is perceived, perception can be somewhat altered
  let spatial-concentration-diff count (other turtles in-radius 1) with [breed != [breed] of myself]
  let spatial-concentration-same count (other turtles in-radius 1) with [breed = [breed] of myself]
  if spatial-concentration-same != 0 or spatial-concentration-diff != 0
  [
    set spatial-concentration spatial-concentration-same / (spatial-concentration-diff + spatial-concentration-same)  ;; calculate 0-1 concentration. Assimlation condition is met if <= 0.5
  ]
end

to assimilation-check ;; this check goes in one direction. Once someone earns assimilation status, it can't be unearned (not too realistic, if we're honest)
  if assimilated? = false[
    let assimilation-value 0
    if SES >= mean [SES] of natives [
      set assimilation-value assimilation-value + 1
    ]
    if english = 1[
      set assimilation-value assimilation-value + 1
    ]
    if intermarriage?[
      set assimilation-value assimilation-value + 1
    ]
    if spatial-concentration < 0.5[
      set assimilation-value assimilation-value + 1
    ]
    set assimilation-value assimilation-value / 4

    if assimilation-value >= .75
    [set assimilated? True]
  ]
end

  ;;-------------------------------------------------------------------------------------;;
  ;;   THESE FUNCTIONS CONTROL THE POPULATION CHANGES THAT RECUR AT REGULAR INTERVALS    ;;
  ;; (if you like the normally distribtued values, none of this should require changing) ;;  <--- NO! Udate these values to variables in a future version. One-stop place for value updates. Maybe add sliders?
  ;;-------------------------------------------------------------------------------------;;

to birth-check
  set birth-growth birth-growth + birth-rate

  ifelse born_as_native_always? = True
  [;; born_as_native_always? = True
    if birth-growth >= 1  ;; if the variable increases to a whole value, let's make that whole born--because the growth per tick is a decimal, 1 is a sufficiently large whole value
    [
      ask one-of turtles
      [
        hatch-natives 1
        [
          set color blue
          set social? False ;; not born socializing
          set SES round random-normal 2.72 1.67  ;; set economic/class status
          set age 0  ;; can't be born with an age > 0!
          set english 1  ;; I don't see a point in setting this below 1 (see actual data on the line below this)
                         ;set english random-normal 0.974 0.086  ;; In 2011 (ACS dataset) values are Mean:  4.87 Std Dev: .43 on 1-5 scale. Here, converted to 0-1 scale.
          set married? False ;; by default set everyone unmarried at init. Probably of marriage increases with age starting at 18
          set intermarriage? False  ;; not born intermarried -- might change once marriage partner is found
          set marriage-partner nobody
          while [SES < 1 or SES > 6]  ;; in most tests, this check is unnecessary--added for safety
          [
            set SES round random-normal 2.72 1.67
          ]
        ]
      ]
      set birth-growth birth-growth - 1 ;; subtract the one that was born from the variable
      set births births + 1
    ]
  ]
  [;; born_as_native_always? = False
    if birth-growth >= 1  ;; if the variable increases to a whole value, let's make that whole born--because the growth per tick is a decimal, 1 is a sufficiently large whole value
    [
      ask one-of turtles
      [
        hatch 1
          [
            set social? False ;; not born socializing
            ;set SES ;; should be inherited
            set age 0  ;; can't be born with an age > 0!
            set english 1  ;; I don't see a point in setting this below 1 for anyone born in the U.S.
            set married? False ;; by default set everyone unmarried at init. Probably of marriage increases with age starting at 18
            set intermarriage? False  ;; not born intermarried -- might change once marriage partner is found
            set marriage-partner nobody
          ]
      ]
      set birth-growth birth-growth - 1 ;; subtract the one that was born from the variable
      set births births + 1
    ]
  ]
end

to migrant-arrive
  set mig-arrive-growth mig-arrive-growth + mig-arrive-rate

  if mig-arrive-growth >= 1  ;; if the variable increases to a whole value, let's make that whole born--because the growth per tick is a decimal, 1 is a sufficiently large whole value
  [
    ask one-of patches
    [
      sprout-foreigns 1
      [
        set color red
        set social? False  ;; doesn't arrive socializing
        set SES round random-normal 2.27 1.44  ;; set economic/class status
        set age random-normal 42.04 17.99  ;; maintain normal distribution of age for foreigns
        set english random-normal 0.646 0.246  ;; In 2011 (ACS dataset) values are Mean:  3.23 Std Dev: 1.23 on 1-5 scale. Here, converted to 0-1 scale.
        if english < 0
        [
          set english 0
        ]
        set married? False ;; by default set everyone unmarried at init. Probably of marriage increases with age starting at 18
        set intermarriage? False  ;; not born intermarried -- might change once marriage partner is found

                                  ;;set spatial-concentration 0 ;; actually, this is calculated at every tick--no need to set a default

        set assimilated? False  ;; by default -- has to be earned
        while [SES < 1 or SES > 6]  ;; in most tests, this check is unnecessary--added for safety
        [
          set SES round random-normal 2.27 1.44
        ]
        while [age < 0]
        [
          set age random-normal 42.04 17.99
        ]
      ]
     set in-mig in-mig + 1
     set mig-arrive-growth mig-arrive-growth - 1
    ]
  ]
end


to death-check
  set death-growth death-growth + death-rate

  if death-growth >= 1  ;; if the variable increases to a whole value, let's make that whole born--because the growth per tick is a decimal, 1 is a sufficiently large whole value
  [
    ask one-of turtles
    [
      ask (patch-here) [set pcolor black] ;; reset patch
      die ;; kill turtle - last thing to do because agent is ASKED to do the other things!
      ]
    set death-growth death-growth - 1 ;; subtract the one that was born from the variable
    set deaths deaths + 1
  ]
end

to migrant-depart
  set mig-depart-growth mig-depart-growth + mig-depart-rate

  if mig-depart-growth >= 1  ;; if the variable increases to a whole value, let's make that whole born--because the growth per tick is a decimal, 1 is a sufficiently large whole value
  [
    ask one-of turtles
    [
      ask (patch-here) [set pcolor black] ;; reset patch
      die
    ]
    set out-mig out-mig + 1
    set mig-depart-growth mig-depart-growth - 1
  ]
end


;;*******************************************************************;;
;;                      GIVE ME SOME RESULTS!                        ;;
;;(modify this at your discretion to output some results, as desired);;
;;*******************************************************************;;

to sweep ;; borrowed from code provided by Steve Scott
  let num-replicates 10  ;; 30 runs of the model should be enough to get an idea
  let num-ticks 4056  ;;  run for 78 simulated years. This is roughly the median lifespan for an American... how much will change in one lifetime?
  let i 0
  let results-list []



  ; Case 1:
  ; born_as_always? True
  ;
  ; print CSV headers
  file-open "case_1.csv"
  ;file-print ("run_num, born_as_native_always?, Initial_Native_Pop, Initial_Foreign_Pop, Prop_Init_Foreign, Final_Native_Pop, Final_Foreign_Pop, Prop_Final_Foreign, births_tot, deaths_tot, in-mig_tot, english?_prop, ses?_prop, intermarriage?_prop, spatial?_prop, assimilated?_prop")
  file-close

  set i 0
  set born_as_native_always? True
  set results-list []
  while [ i < num-replicates ]
  [
    setup
    repeat num-ticks [ go ]
    ;set results-list (fput (count foreigns with [assimilated?]) results-list)
    set i (i + 1)
    file-open "case_1.csv"
    file-print (list i "," born_as_native_always? "," pop-init-native "," pop-init-foreign "," (pop-init-foreign / (pop-init-foreign + pop-init-native)) "," count natives "," count foreigns "," (count foreigns / count turtles) "," births "," deaths "," in-mig "," (count foreigns with [english >= .75] / count foreigns) "," (count foreigns with [SES >= mean [SES] of natives] / count foreigns) "," (count foreigns with [intermarriage? = true] / count foreigns) "," (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns) "," (count foreigns with [assimilated? = True] / count foreigns))
    file-close
  ]

  ; Case 2:
  ; born_as_always? False
  ;
  file-open "case_2.csv"
  file-print ("run_num, born_as_native_always?, Initial_Native_Pop, Initial_Foreign_Pop, Prop_Init_Foreign, Final_Native_Pop, Final_Foreign_Pop, Prop_Final_Foreign, births_tot, deaths_tot, in-mig_tot, english?_prop, ses?_prop, intermarriage?_prop, spatial?_prop, assimilated?_prop")
  file-close

  set i 0
  set born_as_native_always? False
  set results-list []
  while [ i < num-replicates ]
  [
    setup
    repeat num-ticks [ go ]
    ;set results-list (fput (count foreigns with [assimilated?]) results-list)
    set i (i + 1)
    file-open "case_2.csv"
    file-print (list i "," born_as_native_always? "," pop-init-native "," pop-init-foreign "," (pop-init-foreign / (pop-init-foreign + pop-init-native)) "," count natives "," count foreigns "," (count foreigns / count turtles) "," births "," deaths "," in-mig "," (count foreigns with [english >= .75] / count foreigns) "," (count foreigns with [SES >= mean [SES] of natives] / count foreigns) "," (count foreigns with [intermarriage? = true] / count foreigns) "," (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns) "," (count foreigns with [assimilated? = True] / count foreigns))
    file-close
  ]

  ;----------------------------------------------------------;
  ;       Sweeps always use born_as_native_always? True      ;
  ;(less noise and better understanding of parameter impacts);  <-- you could change it, though, if you REALLY want to...
  ;----------------------------------------------------------;

  ; Sweep 1:
  ; Maximum Population
  ;
  file-open "sweep_maxpop.csv"
  file-print ("run_num, born_as_native_always?, Initial_Native_Pop, Initial_Foreign_Pop, Prop_Init_Foreign, Final_Native_Pop, Final_Foreign_Pop, Prop_Final_Foreign, births_tot, deaths_tot, in-mig_tot, english?_prop, ses?_prop, intermarriage?_prop, spatial?_prop, assimilated?_prop")
  file-close

  set i 0
  set born_as_native_always? False
  while [ i < num-replicates ]
  [
    set born_as_native_always? True
    set set-population-size 400
    set set-percent-native 87

    setup
    repeat num-ticks [ go ]
    set i (i + 1)
    print "Max Pop" print i
    file-open "sweep_maxpop.csv"
    file-print (list i "," born_as_native_always? "," pop-init-native "," pop-init-foreign "," (pop-init-foreign / (pop-init-foreign + pop-init-native)) "," count natives "," count foreigns "," (count foreigns / count turtles) "," births "," deaths "," in-mig "," (count foreigns with [english >= .75] / count foreigns) "," (count foreigns with [SES >= mean [SES] of natives] / count foreigns) "," (count foreigns with [intermarriage? = true] / count foreigns) "," (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns) "," (count foreigns with [assimilated? = True] / count foreigns))
    file-close
  ]
  ; Sweep 2:
  ; Minimum Population
  ;
  file-open "sweep_minpop.csv"
  file-print ("run_num, born_as_native_always?, Initial_Native_Pop, Initial_Foreign_Pop, Prop_Init_Foreign, Final_Native_Pop, Final_Foreign_Pop, Prop_Final_Foreign, births_tot, deaths_tot, in-mig_tot, english?_prop, ses?_prop, intermarriage?_prop, spatial?_prop, assimilated?_prop")
  file-close

  set i 0
  set born_as_native_always? True
  set set-population-size 100
  set set-percent-native 87
  while [ i < num-replicates ]
  [
    setup
    repeat num-ticks [ go ]
    set i (i + 1)
    print "Min Pop" print i
    file-open "sweep_minpop.csv"
    file-print (list i "," born_as_native_always? "," pop-init-native "," pop-init-foreign "," (pop-init-foreign / (pop-init-foreign + pop-init-native)) "," count natives "," count foreigns "," (count foreigns / count turtles) "," births "," deaths "," in-mig "," (count foreigns with [english >= .75] / count foreigns) "," (count foreigns with [SES >= mean [SES] of natives] / count foreigns) "," (count foreigns with [intermarriage? = true] / count foreigns) "," (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns) "," (count foreigns with [assimilated? = True] / count foreigns))
    file-close
  ]

  ; Sweep 3:
  ; Maximum Natives (Percent)
  ;
  file-open "sweep_maxnat.csv"
  file-print ("run_num, born_as_native_always?, Initial_Native_Pop, Initial_Foreign_Pop, Prop_Init_Foreign, Final_Native_Pop, Final_Foreign_Pop, Prop_Final_Foreign, births_tot, deaths_tot, in-mig_tot, english?_prop, ses?_prop, intermarriage?_prop, spatial?_prop, assimilated?_prop")
  file-close

  set i 0
  set born_as_native_always? True
  set set-population-size 306.7
  set set-percent-native 98
  while [ i < num-replicates ]
  [
    setup
    repeat num-ticks [ go ]
    set i (i + 1)
    print "Max Nat" print i
    file-open "sweep_maxnat.csv"
    file-print (list i "," born_as_native_always? "," pop-init-native "," pop-init-foreign "," (pop-init-foreign / (pop-init-foreign + pop-init-native)) "," count natives "," count foreigns "," (count foreigns / count turtles) "," births "," deaths "," in-mig "," (count foreigns with [english >= .75] / count foreigns) "," (count foreigns with [SES >= mean [SES] of natives] / count foreigns) "," (count foreigns with [intermarriage? = true] / count foreigns) "," (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns) "," (count foreigns with [assimilated? = True] / count foreigns))
    file-close
  ]

  ; Sweep 4:
  ; Minimum Natives (Percent)
  ;
  file-open "sweep_minnat.csv"
  file-print ("run_num, born_as_native_always?, Initial_Native_Pop, Initial_Foreign_Pop, Prop_Init_Foreign, Final_Native_Pop, Final_Foreign_Pop, Prop_Final_Foreign, births_tot, deaths_tot, in-mig_tot, english?_prop, ses?_prop, intermarriage?_prop, spatial?_prop, assimilated?_prop")
  file-close

  set i 0
  set born_as_native_always? True
  set set-population-size 306.7
  set set-percent-native 2
  while [ i < num-replicates ]
  [
    setup
    repeat num-ticks [ go ]
    set i (i + 1)
    print "Min Nat" print i
    file-open "sweep_minnat.csv"
    file-print (list i "," born_as_native_always? "," pop-init-native "," pop-init-foreign "," (pop-init-foreign / (pop-init-foreign + pop-init-native)) "," count natives "," count foreigns "," (count foreigns / count turtles) "," births "," deaths "," in-mig "," (count foreigns with [english >= .75] / count foreigns) "," (count foreigns with [SES >= mean [SES] of natives] / count foreigns) "," (count foreigns with [intermarriage? = true] / count foreigns) "," (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns) "," (count foreigns with [assimilated? = True] / count foreigns))
    file-close
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
342
15
680
354
-1
-1
10.0
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
0
0
1
ticks
1.0

BUTTON
277
71
340
104
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
277
106
340
139
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
144
144
344
294
How many social?
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count turtles with [social?] / count turtles)"

PLOT
684
168
884
318
english = 1.0
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"immigrants" 1.0 0 -2674135 true "" "plot (count foreigns with [english >= 1] / count foreigns)"

MONITOR
247
14
337
59
Years Elapsed
ticks / 52
2
1
11

PLOT
683
19
883
169
intermarried immigrant?
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"yes" 1.0 0 -2674135 true "" "plot (count foreigns with [married? = True and intermarriage? = True] / count foreigns)"

PLOT
883
18
1083
168
spatial concentration < 0.5
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"foreigns" 1.0 0 -2674135 true "" "plot (count foreigns with [spatial-concentration > 0 and spatial-concentration <= 0.5] / count foreigns)"

MONITOR
412
377
470
422
foreigns
count foreigns
17
1
11

MONITOR
472
377
529
422
natives
count natives
17
1
11

MONITOR
529
377
600
422
population
count turtles
17
1
11

PLOT
783
318
983
468
Assimilated?
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -13840069 true "" "plot (count foreigns with [(assimilated? = True)] / count foreigns)"

PLOT
884
168
1084
318
immigrants with SES >= avg native SES
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"immigrants" 1.0 0 -2674135 true "" "plot (count foreigns with [SES >= mean [SES] of natives] / count foreigns)"

MONITOR
8
170
65
215
SES = 1
count natives with [SES = 1]
17
1
11

MONITOR
8
219
65
264
SES = 2
count natives with [SES = 2]
17
1
11

MONITOR
8
263
65
308
SES = 3
count natives with [SES = 3]
17
1
11

MONITOR
7
307
64
352
SES = 4
count natives with [SES = 4]
17
1
11

MONITOR
7
352
64
397
SES = 5
count natives with [SES = 5]
17
1
11

MONITOR
7
396
64
441
SES = 6
count natives with [SES = 6]
17
1
11

MONITOR
80
173
137
218
SES = 1
count foreigns with [SES = 1]
17
1
11

MONITOR
82
218
139
263
SES = 2
count foreigns with [SES = 2]
17
1
11

MONITOR
82
262
139
307
SES = 3
count foreigns with [SES = 3]
17
1
11

MONITOR
81
307
138
352
SES = 4
count foreigns with [SES = 4]
17
1
11

MONITOR
81
350
138
395
SES = 5
count foreigns with [SES = 5]
17
1
11

MONITOR
81
394
138
439
SES = 6
count foreigns with [SES = 6]
17
1
11

MONITOR
1086
20
1212
65
mean SES of natives
mean [SES] of natives
17
1
11

MONITOR
1086
69
1217
114
mean SES of foreigns
mean [SES] of foreigns
17
1
11

MONITOR
387
422
444
467
births
births
17
1
11

MONITOR
445
422
502
467
NIL
deaths
17
1
11

MONITOR
501
422
558
467
NIL
in-mig
17
1
11

SWITCH
49
108
242
141
born_as_native_always?
born_as_native_always?
0
1
-1000

PLOT
1084
117
1284
267
plot-immigrant-SES
NIL
NIL
1.0
7.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -2674135 true "" ""

PLOT
1085
270
1285
420
plot-native-SES
NIL
NIL
1.0
7.0
0.0
10.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -13345367 true "" ""

TEXTBOX
13
158
60
176
natives
11
105.0
1

TEXTBOX
76
158
142
176
immigrants
11
15.0
1

PLOT
144
298
344
448
plot-age
NIL
NIL
0.0
116.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" ""

MONITOR
557
422
621
467
NIL
out-mig
17
1
11

SLIDER
48
10
225
43
set-population-size
set-population-size
100
400
306.7
1
1
NIL
HORIZONTAL

SLIDER
50
43
222
76
set-percent-native
set-percent-native
2
98
2.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model explores the interaction of the 4 generally-agreed (among social scientist academics) upon measures of assimilation: socioeconomic status, residential settlement patterns, language use, and intermarriage.

## HOW IT WORKS

This abstract model tries to capture assimilation processes by applying 4 distinct but interrelated measures to individual agents and aggregating the proportion of assimilated immigrants into a single reported value. Each measure of assimilation is calculated independently per agent.

## HOW TO USE IT

At setup, the population is initiated with random coordinates. The population size and its percentage of natives and foreigns is set by a slider (set-population-size and set-percent-native, respectively) before setup is called. Rates of population changes are fixed constants. Interaction patterns are based on probabilities that scale with age (e.g. probability of marriage starting at age 18, probability of death after age 78, and probability of breaking a social interaction at any given tick all increase with age.

At every tick, agents who are not socializing may (1) move towards the closest agent most like itself (same SES, similar age, ability to communicate) and then (2) check around itself and attempt to enter social status; in either case, the agent's week is concluded at that point.

Agents who are socializing may (1) exit social status, or, failing to do that, (2) attempt to marry and (3) acquire english ability. In either case, the agent's week is concluded at that point.

## THINGS TO NOTICE

COSMETICS:

Agents have brighter color swatches when they are young and darken as they age.
Agents have boxes around them while they socialize.

POPULATIONS:
Births, deaths, in-migration, and out-migration are all fixed at independent constant rates. However...

*born_as_native_always?: If set to true, each born agent is automatically assigned to "natives" breed. The values assigned to its variables are randomly distributed according to the standard normal distribution of "natives." If set to false, a random agent gives birth to a new agent who then inherits all values from its parent.

*Birth: the breed (and therefore life-chances) at each birth is affected by the slider born_as_native_always?;

*In-migrants: are always of the "foreigns" breed;

*Out-migrants always selects a random agent when called;

*Deaths caused by the constant rate apply to a random agent. Agents also die automatically if they reach age 115 (as anything above 115 is somewhat unrealistic).

## THINGS TO TRY

Options are limited. Feel free to change the population size and percentage of natives at startup, and how newborns are treated throughout the model's duration.

## EXTENDING THE MODEL

-Increase the number of immigrant groups.
-Apply cohort effects (e.g. ability to change SES over time independent of marriage)
-Ability to divorce/re-marry

## CREDITS AND REFERENCES

The ability to enter a social status and check for other possibilities of action based on that status is adapted from Uri Wilensky's 1997 AIDS model. The rest is coded from scratch.
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
