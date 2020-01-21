;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OFFENDER INTERACTION NETLOGO MODEL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
globals                             ;; this is for global variable declaration
[
  vicNum                            ;; the number of potential victims in the original setup
  preferenceColorOffend             ;; the offender's average victim color preference
  preferenceSizeOffend              ;; the offender's average victim size preference
  totalOffenderAffect               ;; accumulated total offender affect (emotional excitation)
  targets                           ;; agent set of victim turtles that have been linked to offender in targeting phase
  interactions                      ;; agent set of victim turtles that have been linked to offender in interaction phase
  target                            ;; single agent in set of victim turtles that have been linked to offender in targeting phase
  anchors                           ;; patchset of anchor point patches
  numberviolentAffectCrossed        ;; the number of times the violentAffect has been crossed
  numberInteractionsCrossed         ;; the number of interaction thresholds that have been crossed
  numberViolentInteractionsCrossed  ;; the number of times the interaction and violentAffect have been crossed -- indicates violent interaction
  interactScored?                   ;; has the fact that the interaction envelope was crossed been noted
  violentAffectScored?              ;; has the fact that the violent Affect envelope was crossed been noted
  violentInteractionScored?         ;; has the fact that the violent interaction envelope was crossed been noted
  violentAffect+                    ;; top of the violent affect envelope...violentAffect slider + vaDev slider
  violentAffect-                    ;; bottom of the violent affect envelope...violentAffect slider - vaDev slider
  interact+                         ;; top of the interact envelope...interact slider + intdev slider
  interact-                         ;; bottom of the interact envelope...interact slider - intdev slider
  skillset                          ;; displays acquired offender skillset on interface through "skill-set" counter
  meanVSkillset                     ;; displays average acquired victim skillset on interface through "avg V Skillset" counter
  stdevVSkillset                    ;; used to plot (in conjunction with meanVSkillset) acquired victim skillset range on "Skillsets" plot
  offenderSkillset                  ;; a variable used to report offender skillset and calculate gainControl?
  VictimSkillset                    ;; a variable used to report victim skillset and calculate gainControl?
  px                                ;; x coordinate for setting up patches
  py                                ;; y coordinate for setting up patches
  abductionCount                    ;; number of abductions (offender gained control of victim)
  killCount                         ;; number of kills
  failAbduct                        ;; number of failed abductions (offender did not gain control of victim)
  comfortPlot                       ;; observer comfort measure for plotting
  ID                                ;; used to create a unique identifier for behavior space
  abductionSiteDistance             ;; sum of abduction site distances
  abductClusterCoefficient          ;; measure of abduction site clustering
  killSiteDistance                  ;; sum of kill site distances
  killClusterCoefficient            ;; measure of kill site clustering
  anchorSiteDistance                ;; sum of anchor point distances
  anchorClusterCoefficient          ;; measure of anchor point clustering
  siteDistance                      ;; sum of all site (abduction, kill, and anchor) distances
  clusterCoefficient                ;; measure of all site (abduction, kill, and anchor) clustering
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [offender offenders]          ;; declares a breed of turtle named offender
offender-own                        ;; declaring variables that belong to offenders
[
  imperativeX                       ;; used in the setAffect function to temprarily generate and hold a random number between 0 and 100
  violentAffectMode?                ;; used to determine if the offender affect has placed the offender across the violent affect envelope
  interactMode?                     ;; used to determine if the offender affect has placed the offender across the interaction envelop
  violentInteractionMode?           ;; used to determine if the offender affect has placed the offender across the violent interaction (violent affect and interaction) envelope
  pViolentInteractionMode?          ;; violent interaction state from previous tick
  OacquiredSkillset                 ;; running total of acquired offender skillset
  anchorGoal?                       ;; used to determine if the offender has selected an anchor goal?
  targetAnchorX                     ;; identifies the target/anchor patch x coordinate
  targetAnchorY                     ;; identifies the target/anchor patch y coordinate
  abduct?                           ;; determines if the target victim has been abducted
  kill?                             ;; determines if the target victim has been killed
  gainControl?                      ;; determines if the offender has gained control over the target victim
  targetSelected?                   ;; determines if a target victim has been selected
  abductMarked?                     ;; determines if the abduction site has been marked
  newAnchor?                        ;; determines if it is necessary to select a new target/anchor based on a change in offender affect
  comfort                           ;; holds offender comfort as a calculation of ... (comfortZone * (1-(0.001 * comfortDecay))
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [victim victims]              ;; declares a breed of turtle named victim
Victim-own                          ;; declaring variables that belong to victim turtles
[
  VacquiredSkillset                 ;; running total of acquired victim skillset
  vMove?                            ;; determines whether or not a victim has moved
  abducted?                         ;; determines if the victim is currently in an abducted state
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [anchorSite anchorSites]      ;; declares a breed of turtle named anchorSite
anchorSite-own                      ;; declaring variables that belong to anchorSite turtles
[
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [abductionSite abductionSites];; declares a breed of turtle named abductionSite
abductionSite-own                   ;; declaring variables that belong to abductionSite turtles
[
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [killSite killSites]          ;; declares a breed of turtle named killSite
killSite-own                   ;; declaring variables that belong to killSite turtles
[
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
patches-own                         ;; declaring variables that belong to patches
[
  AnchorX                           ;; identifies the target anchor x coordinate
  AnchorY                           ;; identifies the target anchor y coordinate
]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;
;; SETUP ;;
;;;;;;;;;;;

;; The setup1 procedure is activated using the "Population Varied" button.  This procedure creates a space to test a predefined configuration of population density.
;; This procedure will create two zones. One of the zones allows victims to be created at initial configuration from a random subset of patches (high population zone),
;; and the other zone will not create any victims on initial configuration (low population zone).  Victims can move freely about the highPopulation zone, however,
;; victim movements are restricted in the low population zone (see the victimMove procedure).  The setup1 procedure will clear the view, setup a predefined low population
;; zone, create initial populations, and create three predefined anchorpoints. This procedure starts by checking to see if the interface specifies a random-seed value in the
;; seedValue drop-list
to setup1
  if seedValue != "none"
  [
    random-seed seedvalue
  ]
  clearDrawing
  setupLowPop
  setup-Pop
  setupAnchors
  ask offender
  [
    move-to patch 4 -23    ;; The offender is moved to one of the three anchorpoints
  ]
end

;; The setup2 procedure is activated using the "Population Constant" button.  This procedure will clear the view, create initial populations, and create three predefined
;; anchorpoints.  It will NOT setup any predefined population density zones.
to setup2
  if seedValue != "none"
  [
    random-seed seedvalue
  ]
  clearDrawing
  setup-Pop
  setupAnchors
  ask offender
  [
    move-to patch 4 -23    ;; The offender is moved to one of the three anchorpoints
  ]
end

;; The clearDrawing procedure will clear all agents and patches, set all agents to a specific color, and reset abduction, kill, ad failed abduction counts.
to clearDrawing
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  ask patches
  [
    set pcolor green + 2
  ]
  set abductionCount 0
  set killCount 0
  set failAbduct 0
end

;; The setupLowPop procedure is used to create a predefined low population zone.
to setupLowPop
    set px min-pxcor + 3
    set py max-pycor - 3
    while [px < max-pxcor - 1]
    [
      paintPop
      diffuse pcolor .8
    ]
    set px min-pxcor + 3
    set py max-pycor - 6
    while [px < max-pxcor - 1]
    [
      paintPop
      diffuse pcolor .8
    ]
    set px min-pxcor + 3
    set py max-pycor - 9
    while [px < max-pxcor - 1]
    [
      paintPop
      diffuse pcolor .8
    ]
    set px min-pxcor + 3
    set py max-pycor - 12
    while [px < max-pxcor - 1]
    [
      paintPop
      diffuse pcolor .8
    ]
    set px min-pxcor + 3
    set py max-pycor - 15
    while [px < max-pxcor - 1]
    [
      paintPop
      diffuse pcolor .8
    ]
    set px min-pxcor + 3
    set py max-pycor - 18
    while [px < max-pxcor - 1]
    [
      paintPop
      diffuse pcolor .8
    ]
    display
end

;; The paintPop procedure creates nine patches (3 X 3) for the setupLowPop procedure
to paintPop
  ask patch (px) (py)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px + 1) (py + 1)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px + 1) (py)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px + 1) (py - 1)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px) (py - 1)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px) (py + 1)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px - 1) (py - 1)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px - 1) (py)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  ask patch (px - 1) (py + 1)
    [if pcolor > 52 [ set pcolor 53.25 ]]
  set px px + 1
end

;; The setup-pop procedure creates a frame around the finite space to keep agents from attempting complex spatial procedures on an edge
;; It will then set up initial offender and victim populations and reset all plots.
to setup-pop
  ct                              ;; clears all turtles
  reset-ticks
  addFrame
  setup-Offender
  setup-Victims
  newPlots
end

;; The addFrame procedure is used to create a black frame and dark green frame around the finite space.
to addFrame
  let x max-pxcor                 ;; identifies the maximum patch coordinate
  while [x > min-pxcor - 1]       ;; a while loop is run until is >= minimum coordinate
  [
    ask patch (x) (max-pycor)
    [set pcolor 50]               ;; colors the patch black
    set x x - 1
  ]
  let y max-pycor
  while [y > min-pycor - 1]
  [
    ask patch (max-pxcor) (y)
    [set pcolor 50]
    set y y - 1
  ]
  set x max-pxcor
  while [x > min-pxcor - 1]
  [
    ask patch (x) (min-pycor)
    [set pcolor 50]
    set x x - 1
  ]
  set y max-pycor
  while [y > min-pycor - 1]
  [
    ask patch (min-pxcor) (y)
    [set pcolor 50]
    set y y - 1
  ]
  set x max-pxcor - 1             ;; identifies the maximum - 1 patch coordinate
  while [x > min-pxcor]           ;; a while loop is run until is > minimum coordinate
  [
    ask patch (x) (max-pycor - 1) ;; colors the patch dark green
    [set pcolor 53]
    set x x - 1
  ]
  set y max-pycor - 1
  while [y > min-pycor]
  [
    ask patch (max-pxcor - 1) (y)
    [set pcolor 53]
    set y y - 1
  ]
  set x max-pxcor - 1
  while [x > min-pxcor]
  [
    ask patch (x) (min-pycor + 1)
    [set pcolor 53]
    set x x - 1
  ]
  set y max-pycor - 1
  while [y > min-pycor]
  [
    ask patch (min-pxcor + 1) (y)
    [set pcolor 53]
    set y y - 1
  ]
end

;; The setup-Offender procedure sets up the offender's initial color, size, skillset value, and size and color of target/victim preference.
;; This procedure will also setup default shapes for abduction, kill and anchor site agents and initial values for a number of offender variables.
to setup-Offender
set-default-shape abductionSite "square 2"            ;; the abduction site will be shaped like handcuffs
set-default-shape killSite "skull"                    ;; the kill site will be shaped like a skull
set-default-shape anchorSite "circle"                 ;; the anchor site will be shaped like a circle
set-default-shape offender "person"                   ;; the offender will be shaped like a person
  create-offender 1                                   ;; create the initial offender
  [
    set color red                                     ;; set offender color as red
    set size 2                                        ;; set offender size to 2
    set preferenceColorOffend 100 + (random-float 10) ;; sets the offender's color preference to Offend against
    set preferenceSizeOffend 1.5 - (random-float 0.5) ;; sets the offender's size preference to Offend against
    set totalOffenderAffect 1 + random-float 0.05     ;; sets initial starting value for offender affect
    setxy random-xcor random-ycor                     ;; randomly drops the offender in the simulation space
    set violentAffectMode? False                      ;; These commands set the initial values for a number of offender variables
    set interactMode? False
    set violentInteractionMode? False
    set pViolentInteractionMode? False
    set targetSelected? False
    set numberviolentAffectCrossed 0
    set numberInteractionsCrossed 0
    set numberviolentInteractionsCrossed 0
    set violentAffectScored? False
    set interactScored? False
    set anchorGoal? False
    set violentInteractionScored? False
    set OacquiredSkillset skillsetOffender
    set gainControl? False
    set kill? False
    set abduct? False
    set abductMarked? False
    set newAnchor? True
    set comfort comfortZone
  ]
end

;; The setup-Victims procedure determines which patches will sprout victims and the initial color, size, skillset and abduction state (false) of each victim
to setup-Victims
  set-default-shape victim "person"                              ;; the victims will be shaped like a person
  ask n-of setVictimPop patches with [pcolor > 55]               ;; randomly select patches (of a certain color) to sprout victims (based on setVictimPop slider)
    [sprout-victim 1                                             ;; for each victim sprouted...
      [
        set color 100 + (random-float 10)                        ;; set the color to a random shade of blue
        set size 1.5 - (random-float 0.5)                        ;; set the size to a random size between 1 and 1.5
        set VacquiredSkillset random-normal skillsetVictims 3.4  ;; set the victim's initial skillset as a normal distribution around the mean (skillsetVictims slider) and a stdev of 3.4
        set abducted? false
      ]
    ]
end

;; The newPlots procedure clears all plots ("offenderPreference, totalAffect, currentAffect, and comfort)
to newPlots
  set-current-plot "offenderPreference"
  clear-plot
  set-current-plot-pen "midOffendPreference"
  ask offender [plotxy preferenceColorOffend 0]
  ask offender [plotxy preferenceColorOffend preferenceSizeOffend]
  ask offender [plotxy 0 preferenceSizeOffend]
  set-current-plot-pen "maxOffendPreference"
  ask offender [plotxy (preferenceColorOffend + offenderFocus) 0]
  ask offender [plotxy (preferenceColorOffend + offenderFocus) (preferenceSizeOffend + (offenderfocus * 0.05))]
  ask offender [plotxy 0 (preferenceSizeOffend + (offenderfocus * 0.05))]
  set-current-plot-pen "minOffendPreference"
  ask offender [plotxy (preferenceColorOffend - offenderFocus) 0]
  ask offender [plotxy (preferenceColorOffend - offenderFocus) (preferenceSizeOffend - (offenderfocus * 0.05))]
  ask offender [plotxy 0 (preferenceSizeOffend - (offenderfocus * 0.05))]
  set-current-plot-pen "victimDistribute"
  ask victim [plotxy color size]
  set-plot-x-range 100 110
  set-plot-y-range 1 1.5
  set-current-plot "totalAffect"
  clear-plot
  set-current-plot "currentAffect"
  clear-plot
  set-current-plot "comfort"
  clear-plot
end

;; The setupAnchors procedure creates three predefined anchors.  The achors are defined by a brown patch. For offender navigation purposes, brown patch is considered the anchor.
;; When the anchor is created, an agent called anchorSite is sprouted from the patch.  This agent is used for visualization and distances measures at the conclusion of the simulation.
to setupAnchors
  ask patch -20 24                      ;; identifies anchor point patch
    [
      set pcolor brown                  ;; colors anchor point patch brown
    ]
  display
  ask patch 12 15
    [
      set pcolor brown
    ]
  display
  ask patch 4 -23
    [
      set pcolor brown
    ]
  display
  ask patches with [pcolor = brown]   ;; identifies anchor patches
    [
      sprout-anchorSite 1             ;; creates an anchorSite agent
      [
        set color black
        set size 2
      ]
    ]
end

;; The go procedure initiates the simulation by moving the offender, moving the victim, updating plots, and determining the simulation end.
;; Once the simulation ends, all agent movements stop, the victims and offender are cleared and a random ID (for the simulation run)
;; is generated.  The anchorSites are increased in size and then the average distance between all three anchorSites is calculated by creating and measuring links.
;; The average distance between abduction sites, kill sites and all sites (abduction, kill and anchor) are calculated the same way.  Next the procedure
;; recolors the view to black and white and, if appropriate designates the low population zone with a light grey color.
to go
  offenderMove
  victimMove
  updatePlots
  tick
  ;if (killcount = 5) or (ticks > 14999)                                              ;; sets the simulation to end if the offender kills five times or the tick counter reaches 15000
  if (ticks > 1999)                                                                   ;; sets the simulation to end if 2000
  [
    clearVictims                                                                      ;; clears all victims (for display purposes)
    ask offender [die]                                                                ;; clears the offender (for display purposes)
    set ID precision (random-float 10 * 1000000000) 0                                   ;; creates a random number ID
    ask anchorSite
    [
      set size 2.0                                                                    ;; sets the anchor sites size to 2.0 ((for display purposes)
    ]
    ask anchorSite
    [
      create-links-with other anchorSite                                              ;; asks anchor points to create links among themselves
      let linkAnchorC count links                                                     ;; determines if there were any anchor site points created
      ifelse linkAnchorC = 0
      [
        set anchorClusterCoefficient 0                                                ;; if no links were made, then the procedure assumes the average to be zero
      ]
      [
        ask links                                                                     ;; if there are anchor point links...
        [
          set anchorSiteDistance sum [link-length] of links                           ;; add all of the anchor point link lengths together...
        ]
        set anchorClusterCoefficient precision (anchorSiteDistance / linkAnchorC) 2   ;; divide the total of all anchor point link lengths by the number of anchor point links
      ]
    ]
    clear-links                                                                       ;; clear the anchor point links
    display
    ask abductionSite
    [
      create-links-with other abductionSite                                           ;; asks abduction sites to create links among themselves
      let linkAbC count links                                                         ;; determines if there were any abduction site links created
      ifelse linkAbC = 0
      [
        set abductClusterCoefficient 0                                                ;; if no links were made, then the procedure assumes the average to be zero
      ]
      [
        ask links                                                                     ;; if there are abduction site links...
        [
          set abductionSiteDistance sum [link-length] of links                        ;; add all of the abduction site link lengths together...
        ]
        set abductClusterCoefficient precision (abductionSiteDistance / linkAbC) 2    ;; divide the total of all abduction site link lengths by the number of abduction site links
      ]
    ]
    clear-links                                                                       ;; clear the abduction site links
    display
    ask killSite
    [
      create-links-with other killSite                                                ;; asks kill sites to create links among themselves
      let linkKC count links                                                          ;; determines if there were any kill site links created
      ifelse linkKC = 0
      [
        set killClusterCoefficient 0                                                  ;; if no links were made, then the procedure assumes the average to be zero
      ]
      [
        ask links                                                                     ;; if there are kill site links...
        [
          set killSiteDistance sum [link-length] of links                             ;; add all of the kill site link lengths together...
        ]
        set killClusterCoefficient precision (killSiteDistance / linkKC) 2            ;; divide the total of all kill site link lengths by the number of kill site links
      ]
    ]
    clear-links                                                                       ;; clear the kill site links
    display
    ask turtles
    [
      create-links-with other turtles                                                 ;; asks all sites to create links among themselves
      let linkAllC count links                                                        ;; determines if there were any site links created
      ifelse linkAllC = 0
      [
        set clusterCoefficient 0                                                      ;; if no links were made, then the procedure assumes the average to be zero
      ]
      [
        ask links                                                                     ;; if there are site links...
        [
          set siteDistance sum [link-length] of links                                 ;; add all of the site link lengths together...
        ]
        set clusterCoefficient precision (siteDistance / linkAllC) 2                  ;; divide the total of all site link lengths by the number of site links
      ]
    ]
    clear-links                                                                       ;; clear all site links
    display
    if exportB&W?                                                                     ;; determines if the view is exported as black and white
    [
      ask patches with [(pcolor > 50 and pcolor < 55)]                                ;; sets areas designated as low population zones...
      [
        set pcolor 8                                                                  ;; ...to a light grey color
      ]
      ask patches with [pcolor = 50]                                                  ;; sets areas designated as NO population zones (frame)...
      [
        set pcolor 0                                                                  ;; ...to black
      ]
      ask patches with [pcolor > 10]                                                  ;; sets areas designated as high population zones...
      [
        set pcolor white                                                              ;; ...to white
      ]
    ]
    display
;    if fileBehaviorSpace = "generic"                                                  ;; if the fileBehaviorSpace variable is set, then use the following address for export
;    [
;;      export-view (word "C:/Users/Tom-Laptop/Documents/CSS 600/project/views/" behaviorspace-run-number "_view.png")
;;      export-interface (word "C:/Users/Tom-Laptop/Documents/CSS 600/project/views/" behaviorspace-run-number "_interface.png")
;      export-view (word "C:/Users/Tom-Laptop/Documents/CSS 600/project/views/" seedValue "-" ID "_view.png")
;;      export-interface (word "C:/Users/Tom-Laptop/Documents/CSS 600/project/views/" seedValue "-" ID "_interface.png")
;    ]
;    if fileBehaviorSpace = "comfortZone-comfortDecay"                                 ;; if the fileBehaviorSpace variable is set, then use the following address for export
;    [
;      export-view (word "C:/Users/Tom-Laptop/Documents/CSS 600/project/views/CZ_" ComfortZone "_D_" comfortDecay "_" behaviorspace-run-number ".png")
;    ]
;    if fileBehaviorSpace = "interaction-violentAffect deviation"                      ;; if the fileBehaviorSpace variable is set, then use the following address for export
;    [
;      export-view (word "C:/Users/Tom-Laptop/Documents/CSS 600/project/views/ID_" intDev "_TD_" vaDev "_" behaviorspace-run-number ".png")
;    ]
;    if fileBehaviorSpace = "Spatial_Sweep"                                             ;; if the fileBehaviorSpace variable is set, then use the following address for export
;    [
;      ;export-view (word "C:/Documents and Settings/wes/Desktop/GMU/CSS_600_intro/zz_final/Final_runs/w_pop" setVictimPop "_cz" comfortZone "_iRad" interactRadius "_tRad" targetRadius "_" behaviorspace-run-number ".png")
;      export-interface (word "C:/Documents and Settings/wes/Desktop/GMU/CSS_600_intro/zz_final/Final_runs/i_" setVictimPop "_cz" comfortZone "_iRad" interactRadius "_tRad" targetRadius "_" behaviorspace-run-number "_k5" ".png")
;    ]
;    if fileBehaviorSpace = "Spatial_Sweep2"                                            ;; if the fileBehaviorSpace variable is set, then use the following address for export
;    [
;      ;export-view (word "C:/Documents and Settings/wes/Desktop/GMU/CSS_600_intro/zz_final/Final_runs/w_pop2" setVictimPop "_cz" comfortZone "_iRad" interactRadius "_tRad" targetRadius "_" behaviorspace-run-number ".png")
;      export-interface (word "C:/Documents and Settings/wes/Desktop/GMU/CSS_600_intro/zz_final/Final_runs/i2_" setVictimPop "_cz" comfortZone "_iRad" interactRadius "_tRad" targetRadius "_" behaviorspace-run-number "_k5" ".png")
;    ]
    stop
    ]
end

;;;;;;;;;;;;;;;;;;;;;
;; AGENT BEHAVIORS ;;
;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;
;; OFFENDER BEHAVIORS ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; The offenderMove procedure defines the offender's movement.  Initially, all links are cleared.  First the offender's affect is set through the setAffect procedure.
;; The randomly generated affect increases or decreases as time goes by.  Initially the offender affect starts within the interaction envelope and violent affect envelope,
;; meaning the offender is neither interacting nor experiencing violent affect.  If the offender affect breaches either envelope, then his state changes to either interaction
;; mode or violent affect mode.  If both envelopes are breached, then the offender enters the violent interaction mode.  If either or both of the envelopes are breached
;; then the offender's skillset increases dramatically.

;; if the offender is not in the violent interaction mode, then his movement is generally toward a randomly selected anchor point with slight randomly gereated variations
;; in direction and speed.

;; if the offender is in the interact mode (but not violent affect), then during his movementshe looks for other agents within his interact radius to interact with (as defined
;; by blue link lines)

;; if the offender is in the violent interact mode, then he will create red links within his target radius to target/victims within his color and size preference.  Once he has
;; identified a target/victims and determined which is most accessible (as defined by distance), then he will attempt to gain control over the target victim.  If the offender's skill set
;; value is higher than a random-float between zero and the sum of the offender and victim skillsets, then the offender gains control of the victim/target.  If he is unsuccessful
;; in gaining control, then the failure is recorded and reported and the offender's affect is adjusted.  If he is successful in gaining control, then the offender will check his comfortzone
;; (based on the comfortzone slider). If there are no other victims within the comfortzone, then the offender will kill the victim, report the kill in the kill number, and mark the location
;; with a red patch (and killsite agent), and reset his goal appropriately.  If, however, there are too many other victims around, the offender will mark the spot with a magenta patch (and
;; abductionsite agent), report the abduction in the abduction number, and reset his goal.

;; once the offender has entered the violent interaction mode, his comfortzone will begin to decay (based on a calculation using comfortDecay slider) to mimic a sense of desperation:
;; (comfortzone * (1 - (0.001 * comfortDecay)))

;; If the offender has reached his spatial goal (anchorGoal?) or his violent interaction status (true or false) has changed since his last move, then a new spatial goal is set.  If the
;; offender is not breaching the violent interaction envelope, then his spatial goal will be set to one of his anchor points.  If he is in violent interaction mode, then
;; he will determine if he has abducted (and currently has control of) a target/victim.  If he does not currently have a target/victim under his control, then 90% of the
;; time he will set a spatial goal of a former abduction site.  the other 10% of the time (or if he does not have a former abduction site) he will set his new goal as an
;; anchor point.  If the offender does have a victim/target under his control, then 90% of the time he will set a spatial goal of a former kill site.  The other 10%
;; of the time (or if he does not have a former kill site) he will set his new goal as an anchor point. If the offender changes his violent interaction mode from true to false
;; (or false to true) prior to reaching his current goal, then he will re-evaluate his spatial goal and readjust to an appropriate goal.  Thus, if he goes from violent
;; interaction to nonviolent interaction, he will adjust from an abduction or kill site goal to an achor point goal.  Ifhe goes from nonviolent interaction to violent
;; interaction, he will adjust from a kill site or abduction site goal to a anchor point goal.
to offenderMove
  clear-links
  ask offender
  [
      if offenderPen? and ticks > 0                                                ;; if the offenderPen? switch is on...
    [
      pen-down                                                                     ;; a track of the offender's movement around the view will be drawn
    ]

    setAffect                                                                      ;; calls a procedure used to set the offender's affect
    if patch-here = patch targetAnchorX targetAnchorY                              ;; if the offender has reached his current spatial goal....
    [
      set anchorGoal? False                                                        ;; ... indicate he does not have a spatial goal...
      set newAnchor? True                                                          ;; ... and he needs a new spatial goal
    ]
    if violentInteractionMode? != pViolentInteractionMode?                         ;; if the current violent interaction mode does not match the prior violent interaction mode ...
    [
      set anchorGoal? False                                                        ;; ... indicate he does not have a spatial goal...
      set newAnchor? True                                                          ;; ... and he needs a new spatial goal
    ]
    set pViolentInteractionMode? violentInteractionMode?                           ;; set the prior violent interaction mode to the current interaction mode (in prep for next tick)

    if anchorGoal? = False and newAnchor? = True                                   ;; if he doesn't have a current spatial goal and he needs a new spatial goal...
    [
      ifelse violentInteractionMode? = False                                       ;; ... and he is not currently in violent interaction mode...
      [
        set anchors patches with [pcolor = brown]                                  ;; then set his new goal to a randomly selected anchor point
        let anchor (one-of anchors)
        set targetAnchorX [pxcor] of anchor
        set targetAnchorY [pycor] of anchor
        set anchorGoal? True                                                       ;; indicate that he has a spatial goal...
        set newAnchor? False                                                       ;; ...and he does not need a new one.
      ]
      [
        ifelse count patches with [pcolor = magenta] > 0 and abduct? = false       ;; however, if he is currently in violent interaction mode, there is at least one abduction site and he doesn't have an abductee...
        [
          ifelse random 10 < 9                                                     ;; then 9 times out of 10...
          [
            set anchors patches with [pcolor = magenta]                            ;; select a former abduction site as a new spatial goal
          ]
          [
            set anchors patches with [pcolor = brown]                              ;; or 1 time out of ten select an anchor point as the new spatial goal
          ]
        ]
        [                                                                          ;; if there are no former abduction sites or the offender currently has an abductee
          ifelse count patches with [pcolor = red - 1] > 0 and random 10 < 9       ;; ...and there are former kill sites and 9 times out of ten
          [
            set anchors patches with [pcolor = red - 1]                            ;; set the new spatial goal as a former kill site
          ]
          [
            set anchors patches with [pcolor = brown]                              ;; or 1 time out of ten or if there are no former kill sites, then set a anchor point as the new spatial goal
          ]
        ]
        let anchor (one-of anchors)
        set targetAnchorX [pxcor] of anchor
        set targetAnchorY [pycor] of anchor
        set anchorGoal? True                                                       ;; indicate that he has a spatial goal...
        set newAnchor? False                                                       ;; ...and he does not need a new one
      ]
    ]
    setOffenderSkillset                                                            ;; call the procedure used to set the offender's skillset
    if (violentInteractionMode? = false)                                           ;; if the offender is not currently in violent interaction mode...
      [
        set abduct? false                                                          ;; he does not have an abductee
        face patch targetAnchorX targetAnchorY                                     ;; so he will face his current goal...
        rt random 40                                                               ;; turn right (randomly...up to 39 degrees)
        lt random 40                                                               ;; then turn left (randomly...up to 39 degrees)
        fd random-float 0.5                                                        ;; and move forward between zero and 0.5
        if interactMode?                                                           ;; if the offender is only in interact mode...
        [
          findInteract                                                             ;; then call the procedure to allow him to identify agents to interact with
        ]
      ]
    if violentInteractionMode?                                                     ;; if the offender is in the violent interaction mode...
      [
        if targetSelected? = false                                                 ;; ...but he hasn't selected a target yet...
        [
          findTarget                                                               ;; then he will call the procedure allowing him to identify and approach a target
          evaluateTargets                                                          ;; and then evaluate the target
        ]
        ifelse targetSelected?                                                     ;; if he already has a target selected...
        [
          ifelse gainControl?                                                      ;; ...and he has control of the target/victim...
          [
            face patch targetAnchorX targetAnchorY                                 ;; then face his current goal
            rt random 40                                                           ;; turn right (randomly...up to 39 degrees)
            lt random 40                                                           ;; then turn left (randomly...up to 39 degrees)
            fd 0.5                                                                 ;; and move forward 0.5
            determineFate                                                          ;; and determine the victim's fate (abduct or kill) by calling the determine fate procedure
          ]
          [
            moveToTarget                                                           ;; if the offender does not have control of the target/victim yet, then move to the target/victim
          ]
        ]
        [                                                                          ;; if the offender does not have a trarget selected yet...
          face patch targetAnchorX targetAnchorY                                   ;; then face his current goal
          rt random 40                                                             ;; turn right (randomly...up to 39 degrees)
          lt random 40                                                             ;; then turn left (randomly...up to 39 degrees)
          fd random-float 0.5                                                      ;; and move forward between zero and 0.5
        ]
      ]
  ]
end

;; The setAffect procedure defines how the offender's affect changes over time and keeps a running affect value in the totalOffenderAffect variable.  Initially, the interaction and
;; violent affect envelopes are established based on their respective slider values and deviation values (intDev and vaDev).  Next a random number between 0 and 99 is generated and
;; assigned to a variable called imperativeX.  the increase and decrease of the offender affect total is dependent on the imperativeX.  Once the current offender affect is determined,
;; it is compared to the interation and violent affect envelopes.  This comparison determines whether the offender is in interaction, violent affect, or violent interaction mode.
;; If the offender is in the interaction mode, but not the violent affect mode, then he is interacting with target/victims nonviolently.  If the offender is in the vilent affect mode,
;; but not interaction mode, then he is not interacting with anyone, but he is experiencing violent ideation.  If the offender is in the violent affect and interaction modes then he is
;; by default in the violent interaction mode and actively seeking interactions to commit violence (murder).
to setAffect
  set violentAffect+ (random-normal violentAffect vaDev)                                       ;; set the upper limit of the violent affect envelope
  set violentAffect- (random-normal violentAffect vaDev) * -1                                  ;; set the lower limit of the violent affect envelope
  set interact+ (random-normal interact intDev)                                                 ;; set the upper limit of the interaction envelope
  set interact- (random-normal interact intDev) * -1                                            ;; set the lower limit of the interaction envelope
  set imperativeX random 100                                                                    ;; generate a random number between 0 and 99 and call it imperativeX
  if(imperativeX = 99)                                                                          ;; If imperative X is equal to 99...
  [
    set totalOffenderAffect totalOffenderAffect + (offenderAffect * 10)                         ;; ...add ten times the offender affect value slider to the total offender affect
  ]
  if(imperativeX > 49)                                                                          ;; If imperative X is between 50 and 99 ...
  [
    set totalOffenderAffect totalOffenderAffect + offenderAffect                                ;; ...add the offender affect value slider to the total offender affect
  ]
  if(imperativeX < 50)                                                                          ;; If imperative X is between 0 and 49 ...
  [
    set totalOffenderAffect totalOffenderAffect - offenderAffect                                ;; ...subtract the offender affect value slider to the total offender affect
  ]
  if(imperativeX = 0)                                                                           ;; If imperative X is equal to 0...
  [
    set totalOffenderAffect totalOffenderAffect - (offenderAffect * 10)                         ;; ...subtract ten times the offender affect value slider to the total offender affect
  ]

  ifelse (totalOffenderAffect >= interact+) or (totalOffenderAffect <= interact-)               ;; if the total offender affect is outside of the interaction envelope...
  [
    set interactMode? True                                                                      ;; ...place the offender in interaction mode
  ]
  [
    set interactMode? False                                                                     ;; ...if not take the offender out of interation mode
  ]

  ifelse (totalOffenderAffect >= violentAffect+) or (totalOffenderAffect <= violentAffect-)     ;; if the total offender affect is outside of the violent affect envelope...
  [
    set violentAffectMode? True                                                                 ;; ...place the offender in violent affect mode
  ]
  [
    set violentAffectMode? False                                                                ;; ...if not take the offender out of violent affect mode
  ]

  ifelse violentAffectMode? and interactMode?                                                   ;; if the offender is in the violent affect and interaction modes
  [
    set violentInteractionMode? True                                                            ;; ...place the offender in violent interation mode
    set comfort (comfort * (1 - (0.001 * comfortDecay)))                                        ;; ...and start reducing the offender's comfortzone based on the comfortDecay function
  ]
  [                                                                                             ;; if the offender is NOT in the violent affect and interaction modes
    set violentInteractionMode? False                                                           ;; ...take the offender out of violent interaction mode
    set targetSelected? False                                                                   ;; ...he does not have a target/victim selected
    set gainControl? False                                                                      ;; ...he does not have control over any target/victims
    set abductMarked? False                                                                     ;; ...he does not have any target/victims in abduction
    set comfort comfortZone                                                                     ;; ...revert the comfortzone back to the slider value
  ]

  set comfortPlot comfort                                                                       ;; ...set comfortzone to a variable that is plotted on the interface
end

;; The setOffenderSkillSet procedure updates the offender's acquired skillset value.  If the offender is in an interaction or violent affect mode, then the acquired skillset is increased by
;; a random number between zero and the skillsetOffender slider value.  If the offender is not in a violent affect or interaction mode,  then the acquired skillset will be increased by 0.1.
to setOffenderSkillset
  ifelse interactMode? or violentAffectMode?
  [
    set OacquiredSkillset precision (OacquiredSkillset + random skillsetOffender) 1
  ]
  [
    set OacquiredSkillset precision (OacquiredSkillset + 0.1) 1
  ]
  set skillset OacquiredSkillset
end

;; The findInteract procedure is called if the offender has breached the interaction envelope and is in the interaction mode (or violent interaction mode).  The offender uses the interaction
;; radius slider to identify agents (victims) to interact with (non-violently) and creates a blue link line.
to findInteract
  ask offender
    [
      set interactions victim in-radius interactRadius
      create-links-with interactions
    ]
  ask links
    [
      set color blue
      set thickness 0.15
    ]
end

;; The findtarget procedure is called if the offender is in the  violent interaction mode.  The offender uses the target radius slider to identify potential target/victims within his color and
;; size preference and creates a red link line.
to findTarget
  ask offender
    [
      set targets victim in-radius targetRadius
      create-links-with targets with
      [
        ((size < preferenceSizeOffend + (offenderfocus * 0.05)) and (size > preferenceSizeOffend - (offenderfocus * 0.05)))
        and
        ((color < preferenceColorOffend + offenderFocus) and (color > preferenceColorOffend - offenderFocus))
      ]
    ]
  ask links
    [
      set color red
      set thickness 0.15
    ]
end

;; The evaluateTargets procedure is used to determine which of the potential target/victims identified by the offender in a violent interaction mode will become the target/victim.
to evaluateTargets
  if linkNumber > 0                                             ;; if there are any links to target/victims
  [
    ask min-one-of links [link-length]                          ;; select the shortes link from the offender to a target/victim
      [
        set target end2                                         ;; set the new spatial goal as the target/victim
      ]
    set targetSelected? true                                    ;; indicate that a target has been selected
  ]
end

;; The linknumber reporter counts the number of links
to-report linkNumber
  report count links
end

;; The moveToTarget procedure is used to direct the offender how to acquire the target/victim
to moveToTarget
  ask offender
    [
      ifelse distance target <= 0.5                             ;; if the distance between the offender and his intended target/victim is less than or equal to 0.5...
      [
        move-to target                                          ;; ...then move to the target/victim
        determineControl                                        ;; ...and use the determineControl procedure to test wether the offender gains control over the target/victim
      ]
      [
       face target                                              ;; if the distance between the offender and his intended target/victim is more than 0.5, then face the target/victim...
       fd 0.5                                                   ;; ...and move toward the target/victim 0.5
      ]
    ]
end

;; The determineControl procedure is used to test whether or not the offender gains control over the target/victim.  Control is determined by comparing the offender's acquired skillset
;; with the target/victim's acquired skillset.  if the offender's skillset is great than a random number generated between zero and the sum of the acquired offender and victim skillsets,
;; then the offender gains control over the target/victim. If not, then the victim has successfullydeflected the offender and the FAIL monitor is increased by 1.
to determineControl
  ask target
    [
      set victimSkillset VacquiredSkillset
    ]
  ifelse OacquiredSkillset > random-float (victimSkillset + OacquiredSkillset)  ;; if the offender's acquired skillset value is greater than a random number between zero and the sum of the offender and victim skillsets...
    [
      set gainControl? True                                                     ;; ...the offender has successfully gained control over the target/victim
      ask target
        [
          set abducted? True                                                    ;; ...and the target/victim enters an abducted state
        ]
      ask offender
        [
          ifelse count patches with [pcolor = red - 1] > 0                      ;; if there are any prior kill sites...
            [
              set anchors patches with [pcolor = red - 1]                       ;; ...the offender sets his new spatial goal as one of the kill sites
            ]
            [
              set anchors patches with [pcolor = brown]                         ;; ...if not, the offender sets his new spatial goal as one of the anchor points
            ]
          let anchor (one-of anchors)
          set targetAnchorX [pxcor] of anchor
          set targetAnchorY [pycor] of anchor
          set anchorGoal? True
        ]
      set abductionCount abductionCount + 1                                     ;; ...and the ABDUCT monitor is increased by one
      determineFate                                                             ;; ...and the determineFate procedure is called to determine if this is an abduction or kill
    ]
    [
      set failAbduct failAbduct + 1                                             ;; if the offender is not successful in gaining control, then the FAIL monitor is increased by one
      if totalOffenderAffect < 0                                                ;; if the violent interaction envelope was breached below zero...
        [
          set totalOffenderAffect totalOffenderAffect + (offenderAffect * 10)   ;; ...increase the total offender affect by 10 times the offender affect slider value
        ]
      if totalOffenderAffect > 0                                                ;; if the violent interaction envelope was breached above zero...
        [
          set totalOffenderAffect totalOffenderAffect - (offenderAffect * 10)   ;; ...decrease the total offender affect by 10 times the offender affect slider value
        ]
      ifelse linkNumber > 1                                                     ;; if there was more then one potential target/vicitm...
      [
        ask one-of links                                                        ;; ...randomly select another link
        [
          set target end2                                                       ;; ...focus on the new linked target/victim
        ]
        ask offender
        [
          set targetSelected? true                                              ;; ...indicate that the offender has selected a new target/victim
        ]
      ]
      [
        set targetSelected? false                                               ;; if there are no available links, then indicate a target/victim has not been selected
      ]
      set gainControl? False                                                    ;; indicate that the offender does not have control over any target/victims
      ask target
      [
        set abducted? false
      ]
    ]
end

;; The determineFate procedure determines whether the offender who has successfully controlled the target/victim will abduct the victim or kill the victim on the spot.  The offender
;; starts by determining if the offender's comfort zone has been breeched by other victims.  If so, then the offender is not "comfortable" in killing, and so the location is marked as
;; an abduction site, the ABDUCT monitor is increased by one, the offender indicates he has abducted, and he sets a new spatial goal.  If the offender's comfort zone is not breached,
;; the offender will kill the target/victim on the spot, the offender will mark the spot as a kill site, and adjust his affect accordingly
to determineFate
  checkComfortZone                                                             ;; use the checkComfortZone procedure to determine if any other victims have breached the offender's comfort zone
  if abduct? = true and abductMarked? = false and kill? = false                ;; if the offender has abducted but not killed...
    [
      abductionAnchor                                                          ;; ...use the abductionAnchor to mark the location as an abduction site
      set abductMarked? true                                                   ;; ...and indicate that the abduction has been marked
    ]
  if abduct? = false and kill? = true                                          ;; if the offender comfortzone has not been breeched...
    [
      killAnchor                                                               ;; ...use the killAnchor procedure to mark the location as a kill site
      ask target
        [
          die                                                                  ;; ...and remove the target/victim
        ]
      if totalOffenderAffect < 0                                               ;; if the violent interaction envelope was breached below zero...
        [
          set totalOffenderAffect totalOffenderAffect + (offenderAffect * 10)  ;; ...increase the total offender affect by 10 times the offender affect slider value
        ]
      if totalOffenderAffect > 0                                               ;; if the violent interaction envelope was breached above zero...
        [
          set totalOffenderAffect totalOffenderAffect - (offenderAffect * 10)  ;; ...decrease the total offender affect by 10 times the offender affect slider value
        ]
      set abduct? false                                                        ;; reset the abduction indicator
      set kill? false                                                          ;; reset the kill indicator
      set abductMarked? false                                                  ;; reset the abduction marked indicator
      set gainControl? False                                                   ;; reset the control indicator
      set targetSelected? False                                                ;; reset the target selected indicator
    ]
end

;; The abductionAnchor procedure is used in the event that the violent interaction results in an abduction.  The patch at the location of the abduction is turned magenta
;; and the patch sprouts a abductionSite agent.  Th offender then sets a new spatial goal.
to abductionAnchor
  ask patch-here
  [
    set pcolor magenta
    sprout-abductionSite 1                 ;; create a new abduction site agent (the shape is determined in the setup-Offender procedure)
    [
      set color white
      set size 1
    ]
  ]
  display
  ask offender
  [
    set anchorGoal? false
  ]

end

;; The killAnchor procedure is used in the event that the violent interaction results in a murder.  The patch at the location of the kill is turned red
;; and the patch sprouts a killSite agent.  Th offender then sets a new spatial goal and increases the KILL monitr by one.
to killAnchor
  ask patch-here
  [
    set pcolor red - 1
    sprout-killSite 1                             ;; create a new kill site agent (the shape is determined in the setup-Offender procedure)
    [
      set color white
      set size 1.5
    ]
  ]
  display
  ask offender
  [
    set anchorGoal? false
  ]
  set killCount killCount + 1                     ;; add one to the killCount (as reported in the KILL monitor)
end

;; The checkComfortZone procedure determines if any victims are within the offender's comfort zone (as reported by the comfortZone slider and updated after decay by the comfort variable)
to checkComfortZone
  ask offender
  [
    ifelse count victim in-radius comfort = 1     ;; if there are not any victims (other than the target/victim) within the offender's comfort zone...
    [
      set abduct? false                           ;; ...the offender does not abduct
      set kill? true                              ;; ...the offender will kill
    ]
    [                                             ;; if not
      set abduct? true                            ;; ...the offender will abduct
      set kill? false                             ;; ...the offender will not kill yet.
    ]
  ]
end

;;;;;;;;;;;;;;;;;;;;;;
;; VICTIM BEHAVIORS ;;
;;;;;;;;;;;;;;;;;;;;;;

;; the victimMove procedure governs how the victim will move on each tick.  The victim's movements are dependent on whether or not the victim has been abducted and whether or not the victim
;; is moving into a low population zone.
to victimMove
  ask offender
  [
    if abduct? = false                            ;; if the offender has abducted the victim...
    [
      ask victim
      [
        set abducted? false                       ;; ...set the victim as abducted
      ]
    ]
  ]
  ask Victim
  [
    ifelse abducted?                              ;; if the victim has been abducted...
    [
      move-to offenders 0                         ;; always move the victim to the same place as the offender
    ]
    [
      set vMove? false
      ;      setVictimSkillset                           ;; update the victim's skillset
      while [vMove? = false]                      ;; use a while loop to find a direction that allows the victim to move
      [
        vDirection                                ;; call the vDirection procedure to determine where the victim can move
      ]
    ]
    setVictimSkillset                             ;; update the victim's skillset
  ]
end

;; The vDirection procedure is used to determine if the victim is able to move.  If the victim encounters a patch color that is greater than 55 or less than 50, he can move to the patch
;; all the time.  if the victim encounters a patch that is between 55 and 54, he can move to the patch 1 out of 100 times.  The procedure continues to feed the result to the victimMove procedure
;; loop until the victim is able to move to a patch.
to vDirection
  let i? false                                            ;; a temporary variable (i?) is created
  rt random 50
  lt random 50
  ask patch-ahead 0.5                                     ;; the victim randomly selects a patch 0.5 ahead
    [
      if pcolor > 55 or pcolor < 50                       ;; if the patch color is greater than 55 or less than 50...
      [
        set i? true
      ]
      if pcolor <= 55 and pcolor > 54 and random 100 < 1  ;; or 1 out of 100 times if the patch is equal to or less than 50 and greater than 54 (accounting for decimals)
      [
        set i? true
      ]
    ]
  set vMove? i?                                           ;; the victim is set to have a moving direction
  if (vMove? = true)                                      ;; if the victim has a moving direction...
    [
      fd random-float 0.5                                 ;; move the victim forward between 0 and 0.5
    ]
end

;; The setVictimSkillset procedure increases the victim's acquired skillset.  It then calculates the mean and standard deviation of all victim skillsets.
to setVictimSkillset
  ifelse random 100 < 10                                                                 ;; if a random number between 0 and 99 is less than 10...
  [
    set VacquiredSkillset precision (VacquiredSkillset + random skillsetVictims) 1       ;; increase the victim's acquired skillset by a random number between 0 and the skillsetVictims slider
  ]
  [
    set vacquiredSkillset precision (VacquiredSkillset + 0.1) 1                          ;; if a random number between 0 and 99 is greater than 9...increase the victim's acquired skillset by 0.1
  ]
  set meanVSkillset precision (mean [VacquiredSkillset] of victim) 1                     ;; calculate the mean of all victim skillsets
  set stdevVSkillset precision ( standard-deviation [VacquiredSkillset] of victim) 1     ;; calculate the standard deviation of all victim skillsets
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; MONITOR CALCULATIONS ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; The numviolentAffect reports the number of times the offender breaches the violent affect envelope
;to numviolentAffect
;  set numberviolentAffectCrossed numberviolentAffectCrossed + 1
;  set violentAffectScored? true
;end

;;; The numInteractions reports the number of times the offender breaches the interaction envelope
;to numInteractions
;  set numberInteractionsCrossed numberInteractionsCrossed + 1
;  set interactScored? true
;end

;;; The numviolentInteractions reports the number of times the offender breaches the violent interaction envelope
;to numviolentInteractions
;  set numberviolentInteractionsCrossed numberviolentInteractionsCrossed + 1
;  set violentInteractionScored? true
;end

;;;;;;;;;;;
;; PLOTS ;;
;;;;;;;;;;;

;; The updatePlots procedure is used to update three of the plots on the interface.
to updatePlots
  set-current-plot "totalAffect"
  set-current-plot-pen "affect"
  plot totalOffenderAffect
  set-current-plot-pen "violentAffect+"
  plot violentAffect+
  set-current-plot-pen "violentAffect-"
  plot violentAffect-
  set-current-plot-pen "interact+"
  plot interact+
  set-current-plot-pen "interact-"
  plot interact-
  set-current-plot-pen "0"
  plot 0
  plotYRange                                              ;; uses the plotYRange procedure to set the Y axis values on the plot
  set-plot-x-range 0 (ticks + 30)                         ;; maintains the plot with a thirty tick margin on the right

  set-current-plot "currentAffect"
  set-current-plot-pen "affect"
  plot totalOffenderAffect
  set-current-plot-pen "violentAffect+"
  plot violentAffect+
  set-current-plot-pen "violentAffect-"
  plot violentAffect-
  set-current-plot-pen "interact+"
  plot interact+
  set-current-plot-pen "interact-"
  plot interact-
  set-current-plot-pen "0"
  plot 0
  plotYRange                                             ;; uses the plotYRange procedure to set the Y axis values on the plot
  set-plot-x-range (ticks - 15) (ticks + 5)              ;; maintains the plot showing a 30 tick window of current activity

  set-current-plot "comfort"
  set-current-plot-pen "comfortzone"
  plot comfortPlot

end

;; The plotYRange procedure is used to set the y axis to values that are appropriate for the violentAffect and interact values and standard deviations
to plotYRange
  ifelse violentAffect > interact
  [set-plot-y-range ((violentAffect * -1) - (2 * vaDev) - 10) (violentAffect + (2 * vaDev) + 10)]
  [set-plot-y-range ((interact * -1) - (2 * intDev) - 10) (interact + (2 * intDev) + 10)]
end

;;;;;;;;;;;;;;;;;;;;;
;; DRAWING BUTTONS ;;
;;;;;;;;;;;;;;;;;;;;;

;; The drawAnchors procedure is used to manually add new anchor points to the simulation either before running or during the simulation.
to drawAnchors
  while [mouse-down?]                                                                                                                     ;; while the mouse is down
  [
    ask patch mouse-xcor mouse-ycor
    [
      if (mouse-xcor > min-pxcor + 2) and (mouse-xcor < max-pxcor - 2) and (mouse-ycor > min-pycor + 2) and (mouse-ycor < max-pycor - 2)  ;; if the mouse x & Y coordinates are inside the frame...
      [
        set pcolor brown - 1                                                                                                              ;; set the patch color to brown -1
      ]
    ]
  ]
  ask patches with [pcolor = brown - 1]                                                                                                   ;; ask the new anchor patch...
    [
      sprout-anchorSite 1                                                                                                                 ;; ...to sprout one anchorSite agent
      [
        set color black                                                                                                                   ;; ...and set the anchorSite agent color to black
        set size 2                                                                                                                        ;; ...and set the anchorSite agent size to 2
      ]
      set pcolor brown                                                                                                                    ;; ...and set the new patch color from brown - 1 to brown
    ]
  display
end

;; the drawLowPop procedure gives the user manual ability to draw low population zones.  The diffuseLP slider controls the level of diffuse while drawing the low population zones.
to drawLowPop
  while [mouse-down?]                                                                                                                     ;; while the mouse is down
    [if (mouse-xcor > min-pxcor + 1) and (mouse-xcor < max-pxcor - 1) and (mouse-ycor > min-pycor + 1) and (mouse-ycor < max-pycor - 1)   ;; if the mouse x & Y coordinates are inside the black frame...
      [
      ask patch mouse-xcor mouse-ycor
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]                                                                                          ;; set the patch color to decrease by 1 if it is above 52
      ask patch (mouse-xcor + 1) mouse-ycor                                                                                               ;; proceed to repeat the process for the patches neighbors
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor - 1) mouse-ycor
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor + 1) (mouse-ycor - 1)
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor + 1) (mouse-ycor + 1)
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor - 1) (mouse-ycor - 1)
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor - 1) (mouse-ycor + 1)
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor) (mouse-ycor - 1)
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      ask patch (mouse-xcor) (mouse-ycor + 1)
      [if pcolor > 52 [ set pcolor pcolor - 1 ]]
      diffuse pcolor diffuseLP                                                                                                            ;; set the world diffuse based on the diffuseLP slider
      display
      ]
    ]
end

;; The clearVictims procedure is used to manually "clean-up" the view by removing all victim agents to better display anchor, abduction, and kill sites.
to clearVictims
  ask victim
  [die]
end

;;; The drawBuilding procedure can be attached to a button on the interface giving a user the ability to draw 3 X 3 squares that the victims are unable to pass through
;to drawBuilding
;  while [mouse-down?]
;  [
;    dropBuilding
;  ]
;end

;;; The dropBuilding procedure can be used in conjunction with the darwBulding procedure to create "buildings" in the view
;to dropBuilding
;  if (mouse-xcor > min-pxcor + 2) and (mouse-xcor < max-pxcor - 2) and (mouse-ycor > min-pycor + 2) and (mouse-ycor < max-pycor - 2)
;    [
;      ask patch mouse-xcor mouse-ycor
;      [
;      set pcolor 53
;      ask neighbors
;      [
;        set pcolor 53
;      ]
;    ]
;      display
;    ]
;end
@#$#@#$#@
GRAPHICS-WINDOW
644
52
1156
565
-1
-1
7.754
1
10
1
1
1
0
0
0
1
-32
32
-32
32
0
0
1
ticks
30.0

BUTTON
849
13
972
48
Go!
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

SLIDER
1165
13
1324
46
setVictimPop
setVictimPop
0
500
0.0
1
1
NIL
HORIZONTAL

PLOT
37
96
225
318
offenderPreference
Color
Size
100.0
110.0
1.0
1.5
true
false
"" ""
PENS
"midOffendPreference" 3.0 0 -10873583 true "" ""
"maxOffendPreference" 1.0 0 -2674135 true "" ""
"minOffendPreference" 1.0 0 -2674135 true "" ""
"victimDistribute" 1.0 2 -13345367 true "" ""

SLIDER
1165
54
1325
87
targetRadius
targetRadius
0
10
0.0
.5
1
NIL
HORIZONTAL

SLIDER
37
61
225
94
offenderFocus
offenderFocus
0
5
0.0
.5
1
NIL
HORIZONTAL

PLOT
7
431
641
633
totalAffect
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
"violentAffect+" 1.0 0 -1069655 true "" ""
"0" 1.0 0 -5325092 true "" ""
"violentAffect-" 1.0 0 -1069655 true "" ""
"interact+" 1.0 0 -4399183 true "" ""
"interact-" 1.0 0 -4399183 true "" ""
"affect" 1.0 0 -16777216 true "" ""

BUTTON
1167
572
1329
607
step
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

SLIDER
232
61
421
94
offenderAffect
offenderAffect
0
5
0.0
.1
1
NIL
HORIZONTAL

SLIDER
37
394
225
427
violentAffect
violentAffect
1
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
430
360
637
393
comfortZone
comfortZone
0
10
0.0
1
1
NIL
HORIZONTAL

PLOT
233
96
421
428
currentAffect
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
"violentAffect+" 1.0 0 -1069655 true "" ""
"0" 1.0 0 -5325092 true "" ""
"violentAffect-" 1.0 0 -1069655 true "" ""
"interact+" 1.0 0 -4399183 true "" ""
"interact-" 1.0 0 -4399183 true "" ""
"affect" 1.0 0 -16777216 true "" ""

SLIDER
37
322
226
355
interact
interact
0
100
0.0
1
1
NIL
HORIZONTAL

SLIDER
1165
90
1325
123
interactRadius
interactRadius
0
10
0.0
0.5
1
NIL
HORIZONTAL

SLIDER
430
61
527
94
skillsetOffender
skillsetOffender
0
10
0.0
1
1
NIL
HORIZONTAL

MONITOR
430
96
527
141
skill-set
skillset
2
1
11

SLIDER
37
358
129
391
intDev
intDev
0
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
132
358
224
391
vaDev
vaDev
0
10
0.0
1
1
NIL
HORIZONTAL

SLIDER
528
61
638
94
skillsetVictims
skillsetVictims
0
20
0.0
1
1
NIL
HORIZONTAL

MONITOR
528
96
638
141
avg V Skillset
meanVSkillset
2
1
11

BUTTON
1168
535
1328
571
4) drawAnchors
drawAnchors
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
1168
427
1328
463
2) drawLowPop
drawLowPop
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
1168
392
1328
426
1) clearDrawing
clearDrawing
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
1168
464
1328
497
diffuseLP
diffuseLP
0
1
0.0
.1
1
NIL
HORIZONTAL

BUTTON
1168
498
1328
533
3) setupPop
setup-pop
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
996
14
1160
49
Setup Varied Population
setup1
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
1166
248
1326
281
offenderPen?
offenderPen?
0
1
-1000

MONITOR
738
588
827
633
ABDUCT
abductionCount
0
1
11

MONITOR
828
588
912
633
KILL
killCount
17
1
11

TEXTBOX
1178
377
1278
395
Manual Controls
11
0.0
1

SLIDER
430
394
637
427
comfortDecay
comfortDecay
0
3
0.0
.1
1
NIL
HORIZONTAL

MONITOR
645
588
736
633
FAIL
failAbduct
17
1
11

PLOT
430
147
638
357
comfort
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
"comfortzone" 1.0 0 -16777216 true "" ""

BUTTON
644
14
824
48
Setup Constant Population
setup2
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
1166
321
1326
366
fileBehaviorSpace
fileBehaviorSpace
"none" "generic" "comfortZone-comfortDecay" "interaction-violentaffect deviation" "Spatial_Sweep" "Spatial_Sweep2"
0

MONITOR
1166
148
1245
193
abduct cluster
abductClusterCoefficient
17
1
11

MONITOR
1248
149
1327
194
kill cluster
killClusterCoefficient
17
1
11

MONITOR
1166
194
1245
239
site cluster
clusterCoefficient
17
1
11

MONITOR
1248
195
1328
240
anchor cluster
anchorClusterCoefficient
17
1
11

SWITCH
1166
284
1326
317
exportB&W?
exportB&W?
1
1
-1000

TEXTBOX
1172
133
1325
152
Spatial Dispersion (ADBNNs)
11
0.0
1

TEXTBOX
55
14
416
51
OFFENDER INTERACTION PROCESS MODEL
16
55.0
1

TEXTBOX
17
206
34
396
I\nN\nT\nE\nR\nN\nA\nL
16
104.0
1

TEXTBOX
1338
194
1355
491
E\nX\nT\nE\nR\nN\nA\nL
16
13.0
1

MONITOR
1080
589
1159
634
Run#
behaviorspace-run-number
0
1
11

CHOOSER
431
10
637
55
seedValue
seedValue
"none" -8167074 -58817058 70547504 22801870 89604752 -11275084 26470296 19045029 -14927281 86098775
0

MONITOR
914
588
971
633
Kill Rate
killCount / abductionCount
2
1
11

@#$#@#$#@
## OFFENDER INTERACTION NETLOGO MODEL (2011)


## WHAT IS IT?

The Offender Interaction NetLogo Model has been developed to explore the bridge between an offender's internal goal setting and his externalized interactions with potential victims in a spatial context.  This NetLogo model utilizes two types of models:  1) a system dynamic approach to represent internalized affective (stimulus driven) state by the offender and resulting breach of need-based �envelopes� defining his proclivity to interact and the nature of the interaction,  and 2) an agent-based model that  explores the offender�s interaction with his environment (to include potential victims) in a spatial context.

Murder research traditionally addresses offender-victim interaction in terms of victim-precipitated homicide (Wolfgang, 1957), situated transaction (Luckenbill, 1977), and situational criminal violence ( Felson & Steadman, 1983).  Some researchers have looked to cognitive scripting (Schank & Abelson, 1977) and crime scripts (Beauregard et al., 2007) to describe how offenders form action plans based on circumstance and geography.  Others have defined offender choice of action based on socially defined action systems (Shye, 1985) or internalized narrative action systems (Canter & Youngs, 2009).

However, homicide research tends to focus on a top-down approach that relies heavily on generalizations derived from aggregated macro-behaviors.  This empirical research into the (relatively) rare phenomenon of murder often involves small populations and models that have been under-conceptualized or that use inadequate proxy-measures for complex concepts.  Criminological research into homicide currently lacks a mainstream and universal understanding of offender-victim interaction as it pertains to a cognitive architecture of the offender�s internalized goal setting and externalized translation in a spatial context.  To understand offending behaviors, it is essential to identify a theoretical framework that will provide a means to synthesize current understanding of violence and conceptualize murder as one-of many potential outcomes of a complex system that is dynamic, iterative and cumulative.

One such potential cognitive architecture is the Offender Interaction Process Model (OIPM) (Dover, 2010).  The OIPM proposes structuring offender-victim interaction as a task-oriented process that does not describe the specific emotional or cognitive states of the offender, but rather the steps that he must go through to achieve the (intended or unintended) outcome of murder.  The current NetLogo model is the first attempt to create a simulation that is informed by the OIPM as a cognitive architecture.

## OFFENDER INTERACTION PROCESS MODEL (OIPM)

The OIPM is constructed of four primary phases: STRATEGIC, TACTICAL, EXECUTION, and EVALUATION.  The OIPM begins with an offender�s current state (or foundation) as the initial STRATEGIC PHASE in which the offender builds, constructs, or discovers the need to achieve a certain goal.  This goal setting is based on prior experience, skillsets, general affect, and reaction to externalized stimuli.  This strategic goal is then externalized (resulting in a potential for interaction with the environment).

The offender must derive a means by which he believes, or his foundation of experience and skillsets (cognitive schema) tells him, will adequately satisfy his goal.  This means the offender must identify someone or something with which he finds utility in interacting with.  Within an offending context, the offender identifies a suitable target that will allow him to achieve his externalized strategic goal.  This initiates the TACTICAL PHASE of the OIPM which necessitates the offender develop, at least, a basic understanding of how to achieve his strategic goal via the target.  Thus, the offender begins to tactically plan how to approach, control, and act upon the target.  In addition, the tactical phase involves the offender's beliefs of what will transpire during the actual interaction.  In this way, the offender develops a set of expectations.

Ultimately, the offender enters the EXECUTION PHASE of the OIPM when he has settled on a tactic and attempts to interact with the target to achieve his strategic goal.  This phase is dynamic, involves the offender's expectations, and is dependent on the offender�s ability to adapt to unanticipated events.

The EVALUATION PHASE of the OIPM is the assessment of whether or not the offender's strategic goal was satisfied sufficiently to cease the interaction, and whether or not new strategic goals have been developed during the interaction.

The OIPM is a cycle that continues to build throughout the offender-victim interaction.  The current NetLogo model incorporates the OIPM, but simplifies the four phases; STRATEGIC, TACTICAL, EXECUTION, and EVALUATION into the interplay of an interaction �envelope� and a violent affect �envelope� within the offender's internalized structure.  The sequence of the offender's interaction with the two dynamic envelopes creates an environment that can place motivational origins (Dover, 2010) of the offender's externalized interface into �interaction- based� (dynamic or execution) or �violent affect-based� (strategic or tactical).  Thus, in the NetLogo Model the offender's violent affect either precedes or follows the offender's need to interact which will ultimately define the trajectory of the offender's violent interaction.

## HOW IT WORKS

The NetLogo model represents a simplified application of the OIPM.  It begins with an initial setup that defines a population of potential victims, the offender, and a geographic context.  Victims are created with an inherent color (shades of blue ranging from dark blue to light blue) and a size.  The victim color and size represents variation in the victim pool.  The offender is assigned a victim preference which defines the size and color range of potential victims of interest to the offender.  This range is established using the �offenderFocus� slider on the interface.

The offender�s internal cognitive architecture is defined by his current state of �affect� (not emotion but reaction to stimuli which is stochastically generated for purposes of the model) and the two �affect� envelopes: "interaction" and "violent affect."  These two envelopes are set at the initial setup through the �interaction� slider and the �violent affect� slider on the interface.  Additionally, perturbations in the �interaction� and �violent affect� envelopes (to simulate variations in context) are generated via the �intDev� and �vaDev� sliders respectively.  The level of change in affect (i.e. the offender�s sensitivity to contextual changes) is set using the �offenderAffect� slider.  The offender�s goal in the model is to satisfy the imperative set by his current state and its relation to the �interaction� and� violent affect� envelopes.

Initially the offender affect starts within the interaction envelope and violent affect envelope, meaning the offender is neither interacting nor experiencing violent affect.  If the offender affect breaches either envelope, then his state changes to either interaction mode or violent affect mode.  In the interaction mode, the offender�s goal is to interact (non-violently) with the victim population.  In the violent affect mode the offender�s goal is to generate violent fantasy (but not interact or victimize).  However, if both envelopes are breached, then the offender enters the violent interaction mode.  In the violent interaction mode, the offender�s goal is to identify a target, control the target and kill the target.

At each tick of the model, the offender increases his skillset (his ability to successfully interact and control a victim).  If he has not breached either envelope, then he will increase his skillset by a small increment (0.1).  However, any time either the interaction envelope or violent affect envelop are breached, then the offender's skillset increases dramatically based on a random number between 0 and the value of the �skillsetOffender� slider.  Additionally, at each tick of the model, individual victim skillsets increase incrementaly (90% of the time) at 0.1, and occasionally (10% of the time) based on a random number between zero and the value of the �skillsetVictims� slider.

The offender�s movement about the view space is governed by the following three rules:

	1) If the offender is not in the violent interaction mode, then his movement is toward a randomly selected anchor point with slight randomly generated variations in direction and speed.

	2) If the offender is in the interact mode (but not violent affect), then during his movements he looks for other agents within his interact radius (as defined by the �interactRadius� button) to interact with (defined by blue link lines)

	3) If the offender is in the violent interaction mode, then he will create red links within his target radius (as defined by the �targetRadius� button) to target/victims within his color and size preference.

Once the offender has identified a target/victims and determined which is most accessible (as defined by distance), then he will attempt to gain control over the target victim.  If the offender's skill set value is higher than a random-float between zero and the sum of the offender and victim skillsets, then the offender gains control of the victim/target.  If he is unsuccessful in gaining control, then the failure is recorded and reported and the offender's affect is adjusted.

If he is successful in gaining control, then the offender will check his comfort zone (based on the comfortzone slider). If there are no other victims within the comfort zone, then the offender will kill the victim, report the kill in the kill number, and mark the location with a red patch (and kill site agent), and reset his goal appropriately.  If, however, there are too many other victims around, the offender willmark the spot with a magenta patch (and abduction site agent), report the abduction in the abduction number, and reset his goal.

Once the offender has entered the violent interaction mode, his comfort zone will begin to decay (based on a calculation using comfortDecay slider) to mimic a sense of desperation: (comfortZone * (1 - (0.001 * comfortDecay)))

If the offender has reached his spatial goal (anchorGoal?) or his violent interaction status (true or false) has changed since his last move, then a new spatial goal is set.  If the offender is not breaching the violent interaction envelope, then his spatial goal will be set to one of his anchor points.  If he is in violent interaction mode, then he will determine if he has abducted (and currently has control of) a target/victim.  If he does not currently have a target/victim under his control, then 90% of the time he will set a spatial goal of a former abduction site.  The other 10% of the time (or if he does not have a former abduction site) he will set his new goal as an anchor point.  If the offender does have a victim/target under his control, then 90% of the time he will set a spatial goal of a former kill site.  The other 10% of the time (or if he does not have a former kill site) he will set his new goal as an anchor point. If the offender changes his violent interaction mode from true to false (or false to true) prior to reaching his current goal, then he will re-evaluate his spatial goal and readjust to an appropriate goal.  Thus, if he goes from violent interaction to nonviolent interaction, he will adjust from an abduction or a kill site goal to an anchor point goal.  If he goes from non-violent interaction to violent interaction, he will adjust from an anchor point goal to an abduction site goal.

When the model is initially setup a spatial context is established in which the offender interacts with the victim population.  There are three ways to establish the initial setup.  The user can use the �Setup Constant Population� button, the �Setup Varied Population� button, or use the manual setup controls.  The �Setup Constant Population� button will set the space to a random distribution of the victims across the entire view.  The �Setup Varied Population� button will create two zones. One of the zones allows victims to be created at initial configuration from a random subset of patches (high population zone), and the other zone will not create any victims on initial configuration (low population zone).  Victims can move freely about the high population zone, however, victim movements are restricted in the low population zone.  Both of the setup buttons will also create a single offender (red person agent) and establish three anchor points to establish the offender�s activity space.

The manual setup buttons are found in the lower right corner of the interface and consist of four buttons that must be activated in sequence.  The first button, �1) clearDrawing� will clear the space.  The second button, �2) drawLowPop� will give the user the opportunity to create low population zones in the space.  The diffuse associated with this button is controlled through the �diffuseLP� slider.  The third button, �3) setupPop� should only be activated once the �2) dawLowPop" button has been deactivated.  The �3) setupPop� button will setup the victim population, the offender, and a frame that bounds movement in the view.   The �4) drawAnchors� button allows the user to create the offender�s activity space by creating anchor points.  THE USER MUST HAVE AT LEAST TWO ANCHOR POINTS DEFINED FOR THE MODEL TO OPPERATE CORRECTLY.

The �go� button initiates the simulation by moving the offender, moving the victim, updating plots, and determining the simulation end. Once the simulation has ended (controlled in the �go� procedure) all agent movements stop, the victims and offender are cleared and a random ID (for the simulation run) is generated.  The average distance between all anchor sites is calculated by creating and measuring links.  The average distance between abduction sites, kill sites and all sites (abduction, kill and anchor) are calculated the same way.  Next, if the �exportB&W?� switch is on, the view is recolored to black and white.

## CAVEATS

The model must be setup initially  by either clicking the "Setup Constant Population" button, "Setup Varied Population" button, or using (in sequence) the manual controls on the interface.  For the model to work correctly, THE USER MUST HAVE AT LEAST TWO ANCHOR POINTS defined.  The "Setup Constant Population" button and the "Setup Varied Population" button will automatically create three anchor points.  However, manual setup requires the user to place anchor points in the view.

If the user wishes to export views when the simulation is run, the user must set the export location referenced by the "fileBehaviorSpace" Chooser at the end of the "go" procedure (in the procedures tab) to an address appropriate to the user's machine.  If the "fileBehaviorSpace" Chooser is set to "none", the simulation will not export a view of the final results.  The default is for the entire statement that refers to the "fileBehaviorSpace" chooser to be commented out until the user determines whether or not there is a need to export the view.  The statement that refers to the "fileBehaviorSpace" chooser is in the "go" procedure just prior to the "stop" command.

The model currently has two different statements in the "go" procedure that will stop the simulation.  One statement will stop the simulation after the offender has killed five times or when the simulation reaches 15,000 ticks.  The other statement will stop the simulation after 2,000 ticks.  Both of these statements are in the "go" procedure (line 5 and 6 respectively).  For the model to function correctly, only one of the statements can be active at a time, the other must be commented out.

## TO USE THE MODEL

The following defines the function of each element on the interface:

seedValue Chooser:
...lists ten seed values for the random number generator used in the simulation.  If these seed values are conceptualized as a unique pre-existing condition (i.e. a unique offender at time=0 prior to the simulation), then the simulation run at different slider values for the same seed number offers a researcher the opportunity to see have changes in the model's settings will effect a unique individual.  It is the perfect control group.  If a user, however, does not wish to use the sees values, "none" should be selected

offenderFocus Slider:
...defines the size of the range around the offender's randomly generated victim preference.

offenderPreference Chart:
...graphically displays the distribution of the victim size and color in a scatterplot and overlays the offender's color and size preference range.

interact Slider:
...defines the size of the interact envelope

intDev Slider:
...defines the amount of perturbation in the interact envelope

violentAffect Slider:
...defines the size of the violent affect envelope

vaDev Slider:
...defines the amount of perturbation in the violent affect envelope

offenderAffect Slider:
...defines the increments of the rise and fall of the offender's affect state

currentAffect Chart:
...graphically displays the current offender affect in relation to the interact and violent affect envelopes

totalAffect Chart
...graphically displays the the overall offender affect in relation to the interact and violent affect envelopes during the entire simulation

skillsetOffender Slider:
...defines the upper limit of the possible random numbers generated to define the offender's skillset increase during interaction with victims

skillsetVictims Slider:
...defines the upper limit of the possible random numbers generated to define the victim's skillset increase during approximately 10% of the victim's moves

skill-set Monitor:
...displays the offender's current skillset value

avg V Skillset Monitor:
...displays the current average of all victim skillset values

comfort Chart:
...graphically displays the offender's level of comfort (and amount of decay) over time when in a violent interaction mode

comfortZone Slider:
...defines the radius (in patches) from the offender and the abducted victim that must be void of other victims before the offender will kill

comfortDecay slider:
...defines the rate of decay in the offender's comfort.  As time goes by, the offender is more likely to kill even if there are other victims around

Setup Constant Population Button:
...creates a simulation in which the population of victims can move about without any difference in population zones

Go! Button:
...initiates the simulation

Setup Varied Population Button:
...creates a simulation in which the population of victims is effected by differences in population zones

View:
...the area in which the spatial context of the model can be viewed

Fail Monitor:
...calculates the number of times the offender attempted to abduct a victim but failed to gain control.

Abduct Monitor:
...calculates the number of times the offender successfully gained control over a victim

Kill Monitor:
...calculates the number of times the offender successfully killed a victim.  This number will always be less than or equal to the number of abductions because in order to kill, the offender must first establish control over the victim.  However, if the victim has been controlled, it does not mean that the offender will kill the victim.  The offender may not be successful in killing a victim he abducted if the offender dips back into the interaction or violent affect envelopes and loses the imperative for violent interaction.

Kill Rate Monitor:
...calculates the rate of kills to abductions

Run# Monitor:
...displays the behavior space run number

setVictimPop Slider:
...defines the initial number of victims

targetRadius Slider:
...defines the radius (in patches) that that the offender will seach for and identify potential victims

interactRadius Slider
...defines the radius (in patches) that that the offender will seach for and identify victims to have non-violent interations with

Spatial Dispersion Measures - Average Distance Between Nearest Neighbors(ADBNN)

abduct Cluster Monitor:
...displays the ADBNN of abduction sites

kill Cluster Monitor:
...displays the ADBNN of kill sites

site Cluster Monitor:
...displays the ADBNN of all abduction sites, kill sites & anchor points

anchor Cluster Monitor:
...displays the ADBNN of anchor points

offenderPen? Switch:
...if true, then the pen for the offender isactivated and his movements through the view are tracked.  If false, the offender pen is not activated.

exportB&W? Switch:
...if true, the view is converted to a black and white color scheme at the end of the simulation (for export and use in black and white publication).  if false, the original color scheme is used.

fileBehaviorSpace Chooser:
...lists export file locations and naming structures for behavior space view exports.  This file structure is specific to the user's machine and if used should be appropriately configured in the procedures tab. This chooser is relevant to code within the "go" procedure.  This code is, by default commented out until the user goes to the "go" procedure and uncomments the portions that are appropriate for his or her needs and edits the export locations to an address appropriate to his or her machine.

Manual Controls - for manual setup

1) clearDrawing:
...initiates a new view by clearing the old view and setting up inital patches

2) drawLowPop:
...initiates the ability to draw a low population zone (dark green) in the view

3) setupPop:
...creates a new distributed victim population and offender

4) drawAnchors:
...initiates the ability to draw anchor points in the view.  Ther must be AT LEAST TWO ANCHOR POINTS FOR THE SIMULATION TO WORK CORRECTLY

diffuseLP Slider:
...defines the level of diffuse when drawing low population zones

Step Button:
...initiates the simulation one tick at a time

## THINGS TO NOTICE

The Offender Interaction NetLogo Model is an exploratory application of the OIPM.  As such, there are a number of interesting things to notice when the simulation is run.

Use the "Setup Varied Population" button to initialize the model.  This setup configuration creates two zones: One zone has patches that will sprout victims during the setup; the other zone is void of victims.  These two zones simulate high and low population areas.  For instance, the high population zone may mimic a neighborhood or target rich environment and the low population zone could represent a forest or park where victims rarely travel.

The view is surrounded by a dark frame.  This frame acts as an area that agents (Victims and the offender) cannot enter.  The world space in this model does not wrap vertically or horizontally.  This dark frame keeps victims from piling up along the edges of the view.

Now locate the red offender.  If you cannot find him, don�t worry.  He is under the black circle (anchor point) at the bottom of the view.  When you hit the �go� button, he should emerge and start heading toward one of the other anchor points.  Set the offenderPen? switch to on.  As the offender moves about the view, you will see his path represented by a red line.  Occasionally, the offender will change trajectory, and wander off of the heading.  Take a moment to look at the �currentAffect� graph.  Is there any correlation between the offender changing trajectories in the view and the black offender affect line�s relationship to the interaction(green)  and violent affect (red) envelopes in the graph?  Either slow the model down or use the �step� button to view the interaction on the graph and the offender�s interaction on the view.

Are there any points when the red offender connects to blue victims with blue lines?  This represents the offender interacting with the victim population non-violently.  Do the blue lines correspond to events in the currentAffect graph?  Are there any points when the red offender connects to blue victims with red lines?  This represents the offender targeting victims but not yet interacting with them.  Do the red lines correspond to events in the currentAffect graph?  What happens if the offender crosses both envelopes and has identified a target?

The interaction envelope and the violent affect envelope can be manipulated prior to setup or during the simulation.  Set the interaction envelope to 20 and the violent affect envelope to 40.  The perturbation in the envelopes is manipulated though the envelopes standard deviations.  The intDev slider affects the interaction envelope and the vaDev slider affects the violent affect envelope.  To start with set both the intDev and vaDev to 0.  Use the "Setup Varied Population" button to initialize the model.  Set the offenderPen? switch to on.  Hit the �go� button and make a note of the offender�s path.  What happens when the values for the interaction and violent affect envelopes are reversed?

Now use the same settings as above, but this time change the intDev and vaDev sliders to 10 and run the model.  How do the offender�s affect graphs change?  What happens to the interaction and violent affect envelopes?  What does manipulating the deviations on the envelopes do to the offender�s trajectory between anchor points?

When the offender gains control of a victim, an abduction site agent marks the location and the victim will be killed (and marked with a kill site agent) or the offender moves toward a previous kill site or established anchor point with the abducted victim.  Occasionally, the victim will escape the offender.  Can you correlate a victim�s escape to the offender�s affect graph?  What happens if the offender has control of the victim and dips back into either the interaction or violent affect envelope?

## THINGS TO TRY

During the course of the offender�s pattern of offending he travels within his activity space.  This activity space is defined by his anchor points and any new abduction sites and kill sites.  Each of these new locations can become significant when, and if, the offender transitions between the interaction mode, violent affect mode, and the violent interaction mode.  The anchor points represent areas of activity for the offender.  These areas are traditionally defined as home, work , and leisure (i.e. a bar).  Yet what happens if the offender changes jobs, moves in with his girlfriend, or begins to frequent a new bar?  The old activity space still exists, but he has expanded his activity space to include the new anchor point.

In the Offender Interaction NetLogo Model you can add a new anchor point during the simulation.  Use the "Setup Varied Population" button to initialize the model.  Set the offenderPen? switch to on.  Hit the �go� button and make a note of the offender�s path.  When the simulation reaches 750 ticks, pause the simulation by clicking the �go� button.  Activate the �4) draw anchors� button under the manual controls area of the interface.  Click somewhere on the view.  You have just added a new anchor point (the offender got a new job?).  De-activate the �4) draw anchors� button and click the �go� button again to continue running the simulation.  How does the new anchor point affect the offender�s movements about the view?  You can add more anchor points without pausing the model.  What happens if you add more during the simulation (maybe the offender has a hard time holding down a job)?

Random seed value can be used in a very interesting way in this model.  The model starts with the offender�s internal processes and explores how these processes manifest in external interactions.  If you choose to, you can establish a seed value to represent an individual offender at a set point in time (the initial setup).  If you run the model with the same settings for the same random seed value, you will get the same results each time.  However, if you run the same seed value with variations in the model settings, you can achieve very different and interesting results.  In effect, the Random seed value creates the same individual in parallel universes in which the internal and external contexts of the simulation have been mildly or dramatically changed (see Ray Bradbury�s �A Sound of Thunder�).

The Offender Interaction NetLogo Model  has ten random seed values that can be used to explore how the model settings will affect specific beginning states (different individuals).   Select one of the random seed numbers from the �seedValue� chooser.  Try various manipulations of the sliders to see how the values change the results.  The behavior space has several experiments set up that run parameter sweeps across the ten random seed values (these experiments have titles that start with �seedvalue�).

## EXTENDING THE MODEL

The Offender Interaction NetLogo Model can be extended in a number of different ways.  The model represents a simplified version of the OIPM and could be made to more adequately represent an internal cognitive architecture by identifying an incorporating more affect envelopes to account for alternative goal setting.  For instance, a sexual envelope may account for sexual offenses when used in conjunction with the interaction and violent affect envelopes.

Additional envelopes would also allow a user to establish more complex goals for the offender.  As the model exists, the offender pursues a rather over-simplified goal of killing the victim when in the violent interaction mode.  However, a more accurate model would allow the offender to abduct and hold a victim for purposes other than immediately killing the victim (i.e. ransom or sexual assault).

In addition to adding more envelopes, the spatial component of the model would benefit from the addition of more site types.  For instance, the abduction site may be preceded by the initial contact site.  Following the abduction, the offender may take the victim to a holding site, and there may be multiple assault sites.  Following the victim�s death, the offender may dump the victim at one location and the victim�s body may be recovered in another location (especially if the dump site involves water).
    In an investigation all of these sites can be spatially significant.

Another interesting extension for the Offender Interaction NetLogo Model would be to create other setup configurations.  Including a base map or different neighborhood configurations could provide some interesting results.

## NETLOGO FEATURES

The Offender Interaction NetLogo Model utilizes a number of NetLogo features.  Notably:

�the linking functions allow the model to visually establish interactions and targets for the offender.  Additionally, the linking feature is used to establish the average distances between nearest neighbors among abduction sites, kill sites, and anchor points.

�the pen-down feature of NetLogo is invaluable in watching nuances in the offender�s travel between sites and anchor points.

�the NetLogo behavior space tool offers a fast and efficient means to generate parameter sweeps, and when used in conjunction with a set group of random seed values provides a means to test parallel trajectories for the same beginning state (with different parameter settings).

�the NetLogo export-view feature allows the user to export spatial results to a .png file as an automatic function.  This function also enhanced the output of the behavior space tool and was easily configured using the �fileBehaviorSpace� chooser.
�manual controls that allow the user to draw low population zones and anchor points were very easy to setup using the family of NetLogo mouse functions.

## CREDITS AND REFERENCES

References:

Axelrod, R. (1997), 'Advancing the Art of Simulation in the Social Sciences', in Conte,

     R., Hegselmann, R. and Terno, P. (eds.), Simulating Social Phenomena, Springer,
     Berlin, Germany, pp. 21-40.

Bateman, A., &Salfati, G. (2007).  An Examination of Behavioral Consistency Using

     Individual Behaviors or Groups of Behaviors in Serial Homicide. Behavioral Sciences
     and the Law, 25: 527-544.

Beauregard, E., Proulx, J., Rossmo, K., Leclerc, B. & Allaire, J. (2007). Script

     Analysis of the Hunting Process of Serial Sex Offenders. Criminal Justice and
     Behavior, 34: 1069-1084.

Canter, D. and Youngs, D. (2009) Investigative Psychology: Offender Profiling and the

     Analysis of Criminal Action. U.K.: Wiley.

Clarke, P. and Evans, F. (1954). Distance to Nearest Neighbor as a Measure of Spatial

     Relationships in Populations. Ecology, 35(4): 445-453.

Crooks, A.T. and Castle, C. (2011), 'The Integration of Agent-Based Modeling and

     Geographical Information for Geospatial Simulation', in Heppenstall, A.J., Crooks,
     A.T., See, L.M. and Batty, M. (eds.), Agent-based Models of Geographical Systems,
     Springer.

Dover, T. (2010). The Offender Interaction Process Model. The Forensic Examiner, 19(3):

     28-40.

Epstein, J.M. and Axtell, R. (1996), Growing Artificial Societies: Social Science from

     the Bottom Up, MIT Press, Cambridge, MA.

Felson, R. B. & Steadman, H. J. (1983).Situational Factors in Disputes Leading to

     Criminal Violence. Criminology, 21(1): 59-74.

Gilbert, N. and Troitzsch, K.G. (2005), Simulation for the Social Scientist (2nd

     Edition), Open University Press, Milton Keynes, UK.

Kent, J. &Leitner, M. (2007).Efficacy of Standard Deviational Ellipses in the

     Application of Criminal Geographic Profiling. Journal of Investigative Psychology
     and Offender Profiling, 4: 147-165.

Luckenbill, D. (1977) Criminal Homicide as a Situated Transaction. Social Problems,

     December, 176-186.

Miller, J.H. and Page, S.E. (2007), Complex Adaptive Systems, Princeton University

     Press, Princeton, NJ.

Salfati, G. & Bateman, A. (2005).  Serial Homicide: An Investigation of Behavioral

     Consistency.  Journal of Investigative Psychology and Offender Profiling, 2:
     121-144.

Salfati, G. & Taylor, P. (2006).Differentiating Sexual Violence: A Comparison of Sexual

     Homicide and Rape. Psychology, Crime & Law, 12(2): 107-125.

Schank, R. & Ableson, R. (1977) Scripts, Plans, Goals and Understanding: An Inquiry into

     Human Knowledge Structures. Hillsdale, N.J.: Erlbaum.

Shye, S. (1985) Non-metric Multivariate Models for Behavioural Action Systems, in Facet

     Theory: Approaches to Social Research, (ed. D. Canter). New York: Springer Verlag.

Simon, H.A. (1996), The Sciences of the Artificial (3rd Edition), MIT Press, Cambridge,

     M. A.

Sun, R. (2009). Motivational Representations within a Computational Cognitive

     Architecture. Cognitive Computation, 1(1): 91-103.

Wolfgang, M. E. (1957). Victim precipitated criminal homicide. The Journal of Criminal

     Law, Criminology, and Police Science, 48(1): 1-11.

Woodhams, J., Grant, T. & Price, A. (2007) From Marine Ecology to Crime Analysis:

     Improving the Detection of Serial Sexual Offences Using a Taxonomic Similarity
     Measure.  Journal of Investigative Psychology and Offender Profiling, 4: 17-27.

Woodhams, J., Hollin, C., & Bull, R. (2008) Incorporating Context in Linking Crimes: An

     Exploratory Study of Situational Similarity and If-Then Contingencies.  Journal of
     Investigative Psychology and Offender Profiling, 5: 1-23
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

anchor
false
0
Circle -7500403 true true 2 2 295
Circle -16777216 true false 30 45 240
Circle -7500403 true true 60 75 180
Rectangle -7500403 true true 45 60 255 150
Rectangle -7500403 true true 75 30 225 75
Rectangle -16777216 true false 135 60 165 270
Polygon -16777216 true false 15 150 75 150 45 105
Polygon -16777216 true false 225 150 285 150 255 105
Circle -16777216 true false 120 15 60
Circle -7500403 true true 135 30 30
Rectangle -16777216 true false 90 90 210 120

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

handcuffs
false
0
Rectangle -16777216 true false 0 0 315 315
Circle -7500403 true true 0 90 180
Circle -16777216 true false 45 135 90
Circle -7500403 true true 120 90 180
Circle -16777216 true false 165 135 90
Circle -7500403 true true 84 39 42
Circle -7500403 true true 114 9 42
Circle -7500403 true true 144 9 42
Circle -7500403 true true 174 39 42
Rectangle -7500403 true true 30 75 135 120
Rectangle -7500403 true true 165 75 255 120
Polygon -16777216 true false 75 90 90 90 90 105 75 105
Polygon -16777216 true false 195 90 210 90 210 105 195 105

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

skull
false
0
Rectangle -16777216 true false 0 0 300 300
Circle -7500403 true true 29 -1 242
Rectangle -7500403 true true 90 210 210 285
Circle -16777216 true false 45 60 88
Circle -16777216 true false 165 60 88
Polygon -16777216 true false 150 135 120 180 180 180
Line -16777216 false 150 285 150 225
Line -16777216 false 120 285 120 225
Line -16777216 false 180 285 180 225

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
  <experiment name="ComfortZone x Decay" repetitions="1" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>seedValue</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="thrDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="3"/>
      <value value="5"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="0"/>
      <value value="1"/>
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="137"/>
      <value value="238"/>
      <value value="457"/>
      <value value="340"/>
      <value value="620"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Interact (StDev) x Violent (StDev)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>count Ticks</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="thrDev">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Spatial_Sweep" repetitions="10" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>go</go>
    <timeLimit steps="15000"/>
    <metric>Ticks</metric>
    <metric>anchorClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="25"/>
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="0"/>
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="0"/>
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="0"/>
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Spatial_Sweep2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup2</setup>
    <go>go</go>
    <timeLimit steps="20000"/>
    <metric>Ticks</metric>
    <metric>anchorClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="25"/>
      <value value="100"/>
      <value value="200"/>
      <value value="300"/>
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="0"/>
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="0"/>
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="0"/>
      <value value="2"/>
      <value value="5"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Varied Pop" repetitions="1" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>seedValue</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="thrDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="-8167074"/>
      <value value="-58817058"/>
      <value value="70547504"/>
      <value value="22801870"/>
      <value value="89604752"/>
      <value value="-11275084"/>
      <value value="26470296"/>
      <value value="19045029"/>
      <value value="-14927281"/>
      <value value="86098775"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Constant Pop" repetitions="1" runMetricsEveryStep="false">
    <setup>setup2</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>seedValue</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="thrDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="-8167074"/>
      <value value="-58817058"/>
      <value value="70547504"/>
      <value value="22801870"/>
      <value value="89604752"/>
      <value value="-11275084"/>
      <value value="26470296"/>
      <value value="19045029"/>
      <value value="-14927281"/>
      <value value="86098775"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="seedValue sweeps" repetitions="1" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>seedValue</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="1.5"/>
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="20"/>
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="thrDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="-8167074"/>
      <value value="-58817058"/>
      <value value="70547504"/>
      <value value="22801870"/>
      <value value="89604752"/>
      <value value="-11275084"/>
      <value value="26470296"/>
      <value value="19045029"/>
      <value value="-14927281"/>
      <value value="86098775"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="seedValue sweeps offenderFocus" repetitions="1" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>seedValue</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <steppedValueSet variable="offenderFocus" first="0.5" step="0.5" last="4"/>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="thrDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="-8167074"/>
      <value value="-58817058"/>
      <value value="70547504"/>
      <value value="22801870"/>
      <value value="89604752"/>
      <value value="-11275084"/>
      <value value="26470296"/>
      <value value="19045029"/>
      <value value="-14927281"/>
      <value value="86098775"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="seedValue sweeps violentAffect interaction" repetitions="1" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>seedValue</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <steppedValueSet variable="violentAffect" first="10" step="10" last="60"/>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <steppedValueSet variable="interact" first="10" step="10" last="60"/>
    <enumeratedValueSet variable="thrDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="-8167074"/>
      <value value="-58817058"/>
      <value value="70547504"/>
      <value value="22801870"/>
      <value value="89604752"/>
      <value value="-11275084"/>
      <value value="26470296"/>
      <value value="19045029"/>
      <value value="-14927281"/>
      <value value="86098775"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="seedValue sweeps interaction X intDev X violent X vaDev" repetitions="1" runMetricsEveryStep="false">
    <setup>setup1</setup>
    <go>Go</go>
    <metric>ID</metric>
    <metric>Skillset</metric>
    <metric>failAbduct</metric>
    <metric>abductionCount</metric>
    <metric>killCount</metric>
    <metric>abductClusterCoefficient</metric>
    <metric>killClusterCoefficient</metric>
    <metric>clusterCoefficient</metric>
    <metric>anchorclusterCoefficient</metric>
    <enumeratedValueSet variable="offenderFocus">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interact">
      <value value="10"/>
      <value value="40"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intDev">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="violentAffect">
      <value value="10"/>
      <value value="40"/>
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vaDev">
      <value value="0"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderAffect">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetOffender">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="skillsetVictims">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortZone">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comfortDecay">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="setVictimPop">
      <value value="205"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="targetRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interactRadius">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="offenderPen?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="exportB&amp;W?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fileBehaviorSpace">
      <value value="&quot;generic&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="diffuseLP">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="seedValue">
      <value value="-8167074"/>
      <value value="-58817058"/>
      <value value="70547504"/>
      <value value="22801870"/>
      <value value="89604752"/>
      <value value="-11275084"/>
      <value value="26470296"/>
      <value value="19045029"/>
      <value value="-14927281"/>
      <value value="86098775"/>
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
