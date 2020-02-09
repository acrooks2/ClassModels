globals [
  Searching-cars
  patches-parking-spot-list
  hunters_probability
  hybrids_probability
  satisfs_probability

  turtle-count
  turtle-count-list

  Day-count

  ; car parks lot_o_current
  lot_o_current
  lot_r_current
  lot_h_current
  lot_s_current
  lot_c_current
  lot_a_current
  lot_l_current
  lot_k_current
  lot_m_current
  lot_p_current

  lot_o_capacity
  lot_r_capacity
  lot_h_capacity
  lot_s_capacity
  lot_c_capacity
  lot_a_capacity
  lot_l_capacity
  lot_k_capacity
  lot_m_capacity
  lot_p_capacity

   ;----------------------WAY POINT LIST----------------------
  southeast-hunters-waypoints
  southeast-hybrids-waypoints
  southeast-satisfs-waypoints
  west-central-hunters-waypoints
  west-central-hybrids-waypoints
  west-central-satisfs-waypoints
  north-west-hunters-waypoints
  north-west-hybrids-waypoints
  north-west-satisfs-waypoints
  exit_o_lot
  exit_r_lot
  exit_h_lot
  exit_s_lot
  exit_c_lot
  exit_a_lot
  exit_l_lot
  exit_k_lot
  exit_m_lot
  exit_p_lot


  ;----------------------Tracking Variables----------------------
  hunters_parking_events
  hunters_total_parking_time
  hunters_total_walking_time
  hunters_waypoints_change
  hunters_abandon_drive_GMU
  hunters_parking_time_more_than_limit

  hybrids_parking_events
  hybrids_total_parking_time
  hybrids_total_walking_time
  hybrids_waypoints_change
  hybrids_abandon_drive_GMU
  hybrids_parking_time_more_than_limit

  satisfs_parking_events
  satisfs_total_parking_time
  satisfs_total_walking_time
  satisfs_waypoints_change
  satisfs_abandon_drive_GMU
  satisfs_parking_time_more_than_limit


  ;----------------------Control Variables-------------------------
  hybrids_lot_limit
  satis_lot_limit
  Max_trips_around_lot
  cooldown-reset
  base-speed
  random-speed
  traffic_factor
  Parking-and-walking-goal
  variability-in-lot-full-estimate
  walking-speed

  SE-X
  SE-Y
  WC-X
  WC-Y
  NW-X
  NW-Y



]


turtles-own [
  turtle-state            ;life_outside, route_to_lot, search_parking, parked, leave_lot, route_to_exit
  type-of-turtle          ;Breed and Destination
  speed                   ;Used to simulate traffic
  entrance-time           ;Determines when to enter

  Standard-parking-time   ;How long will stay
  parking-time-left       ;Counter for how much time left to park
  std-waypoint-list       ;Sets parking lots and waypoints to look for
  waypoint-list           ;waypoint list
  waypt-x                 ;Used for routing, going to an X Y position is faster to calculate than a named patch
  waypt-y                 ;Used for routing, going to an X Y position is faster to calculate than a named patch
  final-x                 ;place walked to X location
  final-y                 ;place walked to Y location

  search-type             ;The parking lots are effectively circular, so turtles are assigned the "inner loop" or the "outer loop"
  No-spots-counter        ;Used in searching for parking, to leave full lots
  cooldown-counter        ;Used to ensure that the no-spots-counter isn't triggered to early
  crazy-count             ;Used to divert the drivers to other methods of getting to GMU
]

breed [constructions construction]
breed [hunters hunter ]
breed [satisfs satisf]
breed [hybrids hybrid]


patches-own [
  Parking-spot? ;is this a parking spot?
  Name          ;Name of the patch, required for waypoint routing
  Status        ;see below
]

;---- Parking Status List---------
;  0 - Road
;  5 - Parking areas road
;  7 - Parking areas entrance
; 10 - Not driveable or parking
; 20 - Parking spot, currently used
; 40 - Parking spot, available


;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------
;-------------------------------------------SYSTEM SETUP--------------------------------------------------
;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------

to setup
  ;; (for this model to work with NetLogo's new plotting features,
  ;; __clear-all-and-reset-ticks should be replaced with clear-all at
  ;; the beginning of your setup procedure and reset-ticks at the end
  ;; of the procedure.)
  __clear-all-and-reset-ticks
  setup-variables
  ask patches [setup-landscape]
  setup-parking
  ask patches [setup-routing]
  setup-cars
  tick-advance 7750; starts sim @ 0745
end



;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------
;-------------------------------------------SYSTEM RUNNING------------------------------------------------
;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------


to go

  if (ticks > 24000) [stop]

  Patch_timestep
  Cars_timestep
  control-timestep
  tick
  plot-cars


end

;---------------------------------------------------------------------------------------------------------
;-------------------------------------------Patch Timestep--------------------------------------------------
;---------------------------------------------------------------------------------------------------------

to Patch_timestep

;  Pending need

end


;---------------------------------------------------------------------------------------------------------
;-------------------------------------------Turtles Timestep--------------------------------------------------
;---------------------------------------------------------------------------------------------------------

; Turtles have 6 mostly cyclical phases (shown below), and transition between each of them
; 10 - life_outside
; 15 - move to lot (required only for netlogo - see below)
; 15 - route_to_lot
; 30 - search_parking
; 40 - parked
; 50 - leave_lot
; 60 - route_to_exit


to Cars_timestep


  ;-------------------------------------------Off Map (waiting)--------------------------------------------------
  ask turtles with [turtle-state = 10][
    ask turtles with [entrance-time = ticks mod 24000] [
      set turtle-state 15
      show-turtle
    ]
  ]


  ;-------------------------------------------Move to entrance--------------------------------------------------
  ; This is done for the sake of NETLOGO, for some reason it goes through several dozens of iterations automatically.
  ; All of this code could be included in the previous procedure
  ask turtles with [turtle-state = 15][
    let curr-dest first std-waypoint-list
    move-to one-of patches with [name = curr-dest]
    set turtle-state 20
    set color black
    set Searching-cars (Searching-cars + 1)
    go-to-next-destination

  ]

  ;-------------------------------------------routing to lots--------------------------------------------------
  ask turtles with [turtle-state = 20][

    let curr-dest first waypoint-list

    ;did I reach a waypoint
    ifelse (waypt-x = [pxcor] of patch-here) and (waypt-y = [pycor] of patch-here)[
      if substring curr-dest 0 4 = "craz" [ back-to-normal]           ;Have you going crazy? Get a coffee and go back to normal
      ifelse substring curr-dest 0 4 = "star" [                       ;Is it a lot search point?
        if breed = hunters [transition-to-searching-for-a-space]       ;if you're a hunters go search, you always search
        if breed = hybrids [                                           ;if you're a hybrids
          ifelse (park_avail curr-dest hybrids_lot_limit = 1 or        ;If the lot isn't too full
            length waypoint-list < 5)                                 ;Or if this is the last place to look
            [ transition-to-searching-for-a-space ]                   ;Looks OK
            [ go-to-next-destination ]                                ;Too full move on
          ]
        if breed = satisfs [                                           ;if you're a satisfs
          ifelse (park_avail curr-dest satis_lot_limit = 1 or         ;If the lot isn't too full
            length waypoint-list < 5)                                 ;Or if this is the last place to look
            [ transition-to-searching-for-a-space ]                   ;Looks OK
            [ go-to-next-destination ]                                ;Too full move on
        ]
      ]
      [if substring curr-dest 0 4 != "crazy" [go-to-next-destination]] ;Not a lot search point (or gone crazy), choose and face next destination
    ]

    [ fd (speed * traffic_factor)]                                     ;default behaviour move forward at your speed
  ]


  ;-------------------------------------------routing and searching for parking in the lots--------------------------------------------------

  ask turtles with [turtle-state = 30][


    Let Open_spot max-one-of neighbors4 [Status]                      ;look around for parking

    ifelse [Status] of Open_spot > 35 [                               ;if I can park
      move-to Open_Spot                                               ;park
      set parking-time-left Standard-parking-time                     ;set my parking time
      set turtle-state 40                                             ;change my state variable
      ask patch-here [set status 20]                                  ;mark the space as taken
      update-waypoints-to-exit                                        ;set waypoints to leave GMU
      set Searching-cars (Searching-cars - 1)
      track-parking-events
    ]

    ;no parking nearby try to move ahead
    [ifelse ([status] of patch-ahead (speed * traffic_factor) = 5
          or [status] of patch-ahead (speed * traffic_factor) = 7)      ;is the patch ahead out of the parking lot
      [
        fd (speed * traffic_factor)                                   ;go forward
        set cooldown-counter (cooldown-counter - 1)                   ;reduce cooldown counter
      ]
      [
        if (search-type = "inner_loop")   [set heading heading + 90]  ;turn right
        if (search-type = "outer_loop")   [set heading heading - 90]  ;turn left
      ]
    ]

    ; short circuit to leave lots you can't find parking in the current lot
    if ([status] of patch-here = 7)[                      ; if you're back at the entrance
      if (cooldown-counter < 0 ) [                        ; and it's been at least 10 time-steps
        set No-spots-counter (No-spots-counter + 1)       ; Get angrier with this lot
        set cooldown-counter cooldown-reset
      ]
      if No-spots-counter > Max_trips_around_lot [        ; if this is too many times
        set-lot-count-down-one
        move-to patch-here
        let first-dest-text (item 0 waypoint-list)
        let first-destination one-of patches with [name = first-dest-text]
        set waypt-x [pxcor] of first-destination
        set waypt-y [pycor] of first-destination
        facexy waypt-x waypt-y
        set color black
        fd 1
        set turtle-state 20                   ; Route to a new lot
      ]
    ]
  ]


  ;-------------------------------------------parked cars--------------------------------------------------
  ask turtles with [turtle-state = 40][

    ;reduce time counter by one
    set parking-time-left parking-time-left - 1

    ;leave the lot
    if parking-time-left < 0 [
      ask patch-here [set status 40]                                  ;free the space
      set speed  base-speed + random-float random-speed
      Let Open_road min-one-of neighbors [Status]
      let temp_x [pxcor] of open_road
      let temp_y [pycor] of open_road
      setxy temp_x temp_y
      move-to Open_road
      set turtle-state 50
      set color 87
      set-lot-count-down-one
      set Searching-cars (Searching-cars + 1)
    ]
  ]



  ;-------------------------------------------leave the lot--------------------------------------------------
  ask turtles with [turtle-state = 50][

    ifelse ([status] of patch-ahead (speed * traffic_factor) = 7)     ;is the patch ahead the exit out of the parking lot
    [
      move-to patch-ahead (speed * traffic_factor)                    ;go to the center of the exit
      set turtle-state 60                                             ;change my state variable
      set color 47                                                    ;change color to indicate

      ;Route to next waypoint instead of named destination - its faster in the program
      let first-dest-text (item 0 waypoint-list)
      let first-destination one-of patches with [name = first-dest-text]
      set waypt-x [pxcor] of first-destination
      set waypt-y [pycor] of first-destination
      facexy waypt-x waypt-y
    ]
    [
      ifelse ([status] of patch-ahead (speed * traffic_factor) = 5)   ;is the patch ahead out of the parking lot
      [fd (speed * traffic_factor)]                                   ;go forward
      [
        if (search-type = "inner_loop")   [set heading heading + 90]  ;turn right
        if (search-type = "outer_loop")   [set heading heading - 90]  ;turn left
      ]
    ]

  ]


  ;-------------------------------------------move to the exit--------------------------------------------------
  ask turtles with [turtle-state = 60][

    let curr-dest first waypoint-list

    ;did I reach a waypoint
    ifelse (waypt-x = [pxcor] of patch-here) and (waypt-y = [pycor] of patch-here)
      [ifelse length waypoint-list > 1                             ;Did I reach my last waypoint?
        [ go-to-next-destination ]                                 ;No, go the the next wapoint
        [
          set Searching-cars (Searching-cars - 1)
          set-turtles-up-for-next-day                              ;Yes, reset for the next day
        ]
      ]
      [ fd (speed * traffic_factor) ]                              ;default behaviour move forward at your speed
  ]
end


;---------------------------------------------------------------------------------------------------------
;-------------------------------------------Control Timestep--------------------------------------------------
;---------------------------------------------------------------------------------------------------------

to control-timestep

  if (ticks mod 24000 = 23500) [
    tick-advance 8250               ; restarts the day sim @ 0745
    set Day-count (Day-count + 1)
    ask patches with [status = 10][set pcolor 62]
    set turtle-count-list lput turtle-count turtle-count-list

  ]


  if (ticks mod 24000 =  8000) [ask patches with [status = 10][set pcolor 64]]
  if (ticks mod 24000 =  9000) [ask patches with [status = 10][set pcolor 65]]
  if (ticks mod 24000 = 10000) [ask patches with [status = 10][set pcolor 66]]
  if (ticks mod 24000 = 11000) [ask patches with [status = 10][set pcolor 67]]
  if (ticks mod 24000 = 16000) [ask patches with [status = 10][set pcolor 66]]
  if (ticks mod 24000 = 17000) [ask patches with [status = 10][set pcolor 65]]
  if (ticks mod 24000 = 18000) [ask patches with [status = 10][set pcolor 64]]
  if (ticks mod 24000 = 19000) [ask patches with [status = 10][set pcolor 63]]
  if (ticks mod 24000 = 20000) [ask patches with [status = 10][set pcolor 62]]
  if (ticks mod 24000 = 21000) [ask patches with [status = 10][set pcolor 61]]
  if (ticks mod 24000 = 22000) [ask patches with [status = 10][set pcolor 60.5]]


  ;set traffic factor (default to 50% slower, adjust by 30
  set traffic_factor 0.5
  if Searching-cars < 150 [set traffic_factor 0.6]
  if Searching-cars < 120 [set traffic_factor 0.7]
  if Searching-cars < 90  [set traffic_factor 0.8]
  if Searching-cars < 60  [set traffic_factor 0.9]
  if Searching-cars < 30  [set traffic_factor 1]




end


;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------
;-------------------------------------------Utility Programs----------------------------------------------
;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------


to track-parking-events


  let entrace-day-time (day-count * 24000) + entrance-time

  let parking-time (ticks - entrace-day-time)

  ;calculate distance from parking spot to lot entrance
  let exit-text (item 0 waypoint-list)
  let exit-patch one-of patches with [name = exit-text]
  let temp-x [pxcor] of exit-patch
  let temp-y [pycor] of exit-patch
  let distance-to-lot-exit (distancexy temp-x temp-y)

  ;calculate distance from lot entrance to final destination
  set temp-x final-x
  set temp-y final-y
  let distance-from-lot-exit-to-destination [distancexy temp-x temp-y] of exit-patch

  ;total distance and calculate time to walk
  let walking-distance (distance-to-lot-exit + distance-from-lot-exit-to-destination)
  let walking-time (walking-distance / walking-speed)


  ;For each breed, add walking and parking time totals, track if people came on time
  if breed = hunters [
    set hunters_parking_events (hunters_parking_events + 1)
    set hunters_total_parking_time (hunters_total_parking_time + parking-time)
    set hunters_total_walking_time (hunters_total_walking_time + walking-time)
    if parking-time + walking-time > Parking-and-walking-goal [
      set hunters_parking_time_more_than_limit (hunters_parking_time_more_than_limit + 1)
    ]
  ]

  if breed = hybrids [
    set hybrids_parking_events (hybrids_parking_events + 1)
    set hybrids_total_parking_time (hybrids_total_parking_time + parking-time)
    set hybrids_total_walking_time (hybrids_total_walking_time + walking-time)
    if parking-time + walking-time > Parking-and-walking-goal [
      set hybrids_parking_time_more_than_limit (hybrids_parking_time_more_than_limit + 1)
    ]
  ]

  if breed = satisfs [
    set satisfs_parking_events (satisfs_parking_events + 1)
    set satisfs_total_parking_time (satisfs_total_parking_time + parking-time)
    set satisfs_total_walking_time (satisfs_total_walking_time + walking-time)
    if parking-time + walking-time > Parking-and-walking-goal [
      set satisfs_parking_time_more_than_limit (satisfs_parking_time_more_than_limit + 1)
    ]
  ]

end






;---------------------------------------------------------------------------------------------------------
;-------------------------------------------Graphics and plots--------------------------------------------
;---------------------------------------------------------------------------------------------------------

to plot-cars


  set-current-plot "Capacity and Current"
  set-current-plot-pen "O_capacity"
  plot lot_o_capacity + 1
  set-current-plot-pen "O_current"
  plot lot_o_current + 1

  set-current-plot-pen "Rap1_capacity"
  plot lot_r_capacity + 1
  set-current-plot-pen "Rap1_current"
  plot lot_r_current

  set-current-plot-pen "Rap2_capacity"
  plot lot_h_capacity + 1
  set-current-plot-pen "Rap2_current"
  plot lot_h_current

  set-current-plot-pen "Shan_capacity"
  plot lot_s_capacity
  set-current-plot-pen "Shan_current"
  plot lot_s_current

  set-current-plot-pen "C_capacity"
  plot lot_c_capacity
  set-current-plot-pen "C_current"
  plot lot_c_current

  set-current-plot-pen "A_capacity"
  plot lot_a_capacity
  set-current-plot-pen "A_current"
  plot lot_a_current

  set-current-plot-pen "L_capacity"
  plot lot_l_capacity + 1
  set-current-plot-pen "L_current"
  plot lot_l_current + 1

  set-current-plot-pen "K_capacity"
  plot lot_k_capacity
  set-current-plot-pen "K_current"
  plot lot_k_current

  set-current-plot-pen "M_capacity"
  plot lot_m_capacity
  set-current-plot-pen "M_current"
  plot lot_m_current

  set-current-plot-pen "P_capacity"
  plot lot_p_capacity - 1
  set-current-plot-pen "P_current"
  plot lot_p_current - 1

end


to setup-variables

  set hybrids_lot_limit 0.85
  set satis_lot_limit 0.75
  set Max_trips_around_lot 2
  set cooldown-reset 10
  set base-speed 0.7
  set random-speed 0.29
  set Parking-and-walking-goal 500
  set variability-in-lot-full-estimate 0.10
  set walking-speed   0.2
  set traffic_factor 1

  set SE-X 95
  set SE-Y 25
  set WC-X 50
  set WC-Y 45
  set NW-X 45
  set NW-Y 105


end


;---------------------------------------------------------------------------------------------------------
;-------------------------------------------SETUP PATCHES--------------------------------------------------
;---------------------------------------------------------------------------------------------------------

to setup-parking

  ;run clockwise starting from top left
  Create_Parking  8  118 3  ;O
  Create_Parking 51  128 5  ;R
  Create_Parking 83  128 6  ;H
  Create_Parking 79   47 6  ;S
  Create_Parking 93    6 3  ;C
  Create_Parking 60    6 5  ;A
  Create_Parking 45    6 2  ;L
  Create_Parking  1    6 5  ;K
  Create_Parking 35   66 2  ;M
  Create_Parking 19   86 2  ;P

  set lot_o_capacity 60
  set lot_r_capacity 100
  set lot_h_capacity 120
  set lot_s_capacity 120
  set lot_c_capacity 60
  set lot_a_capacity 100
  set lot_l_capacity 40
  set lot_k_capacity 100
  set lot_m_capacity 40
  set lot_p_capacity 40


  ;Create a subset of patches where you can actually park
  set patches-parking-spot-list patches with [Parking-spot? = true]


end


to setup-landscape

  ; default patches to not drivable, not parkable
  set Parking-spot? false
  set pcolor 63
  set status 10

  ; horizontal roads
  if (pycor = 120) and (pxcor <= 117) [set pcolor grey set Status 0]
  if (pycor = 58 ) and (pxcor <= 33 ) [set pcolor grey set Status 0]
  if (pycor = 58 ) and (pxcor >= 117) [set pcolor grey set Status 0]
  if (pycor = 8  ) and (pxcor >= 33 ) and ( pxcor <= 117 ) [set pcolor grey set Status 0]
  ; vertical roads
  if (pxcor = 33) [set pcolor grey set Status 0]
  if (pxcor = 49)  and (pycor >= 120) [set pcolor grey set Status 0]
  if (pxcor = 59)  and (pycor <= 8  ) [set pcolor grey set Status 0]
  if (pxcor = 91)  and (pycor <= 8  ) [set pcolor grey set Status 0]
  if (pxcor = 117) and (pycor <= 120) and ( pycor >= 8 ) [set pcolor grey set Status 0]

end


to Create_Parking [Top-left-X Top-left-Y Mult-of-20-prk]

  if ( Mult-of-20-prk > 0 )[

    let recur_variable Mult-of-20-prk - 1
    create-constructions 1 [
      set heading 90

      ;move to the top desired point, move to the right 1, then draw 5 parking spots (orange)
      setxy Top-left-X Top-left-Y
      fd 1 repeat 5 [ask patch-here [set pcolor orange set Parking-spot? true set Status 40] fd 1 ]

      ;move one line down, draw 6 parking roads (blue)
      setxy Top-left-X Top-left-Y - 1
      repeat 6 [ask patch-here [set pcolor blue set Status 5] fd 1]

      ;move one line down, move to the right 1, then draw 5 parking spots (orange)
      setxy Top-left-X Top-left-Y - 2
      fd 1 repeat 5 [ask patch-here [set pcolor orange set Parking-spot? true set Status 40] fd 1]

      ;move one line down, move to the right 1, then draw 5 parking spots (orange)
      setxy Top-left-X Top-left-Y - 3
      fd 1 repeat 5 [ask patch-here [set pcolor orange set Parking-spot? true set Status 40] fd 1 ]

      ;move one line down, draw 6 parking roads (blue)
      setxy Top-left-X Top-left-Y - 4
      repeat 6 [ask patch-here [set pcolor blue set Status 5] fd 1]

      ;move one line down, move to the right 1, then draw 5 parking spots (orange)
      setxy Top-left-X Top-left-Y - 5
      fd 1 repeat 5 [ask patch-here [set pcolor orange set Parking-spot? true set Status 40] fd 1]

      ;draw blue road ends
      set heading 180
      setxy Top-left-X Top-left-Y - 1
      repeat 4 [ask patch-here [set pcolor blue set Status 5] fd 1 ]
      setxy Top-left-X + 6 Top-left-Y - 1
      repeat 4 [ask patch-here [set pcolor blue set Status 5] fd 1 ]

    ]
    ask constructions [die]

    ;draw the next set of 20 parking spot
    Create_Parking Top-left-X + 6 Top-left-Y recur_variable

  ]

end

;---------------------------------------------------------------------------------------------------------
;-------------------------------------------SETUP WAY POINTS--------------------------------------------------
;---------------------------------------------------------------------------------------------------------


to setup-routing

  ;johnson center
  if (pxcor = 60 ) and (pycor = 65) [set pcolor cyan set status 15 set Name "crazy"]
  if (pxcor = 60 ) and (pycor = 64) [set pcolor cyan set status 15 ]
  if (pxcor = 60 ) and (pycor = 66) [set pcolor cyan set status 15 ]
  if (pxcor = 59 ) and (pycor = 64) [set pcolor cyan set status 15 ]
  if (pxcor = 59 ) and (pycor = 65) [set pcolor cyan set status 15 ]
  if (pxcor = 59 ) and (pycor = 66) [set pcolor cyan set status 15 ]
  if (pxcor = 61 ) and (pycor = 64) [set pcolor cyan set status 15 ]
  if (pxcor = 61 ) and (pycor = 65) [set pcolor cyan set status 15 ]
  if (pxcor = 61 ) and (pycor = 66) [set pcolor cyan set status 15 ]

  ;walking destinations
  if (pxcor = SE-X ) and (pycor = SE-Y ) [set pcolor red set status 15 set Name "SE_dest"]
  if (pxcor = WC-X ) and (pycor = WC-Y ) [set pcolor red set status 15 set Name "WC_dest"]
  if (pxcor = NW-X ) and (pycor = NW-Y ) [set pcolor red set status 15 set Name "NW_dest"]

  ;portal
  if (pxcor = 33 ) and (pycor = 130) [set pcolor red set Name "red_portal"]
  if (pxcor = 49 ) and (pycor = 130) [set pcolor red set Name "orange_portal"]
  if (pxcor = 120) and (pycor = 58 ) [set pcolor red set Name "yellow_portal"]
  if (pxcor = 91 ) and (pycor = 0  ) [set pcolor red set Name "blue_portal"]
  if (pxcor = 59 ) and (pycor = 0  ) [set pcolor red set Name "indigo_portal"]
  if (pxcor = 33 ) and (pycor = 0  ) [set pcolor red set Name "violet_portal"]
  if (pxcor = 0  ) and (pycor = 58 ) [set pcolor red set Name "rainbow_portal"]

  ;intersections
  if (pxcor = 33 ) and (pycor = 120) [set pcolor magenta set Name "int_1"]
  if (pxcor = 49 ) and (pycor = 120) [set pcolor magenta set Name "int_2"]
  if (pxcor = 117) and (pycor = 120) [set pcolor magenta set Name "int_3"]
  if (pxcor = 117) and (pycor = 58 ) [set pcolor magenta set Name "int_4"]
  if (pxcor = 117) and (pycor = 8  ) [set pcolor magenta set Name "int_5"]
  if (pxcor = 91 ) and (pycor = 8  ) [set pcolor magenta set Name "int_6"]
  if (pxcor = 59 ) and (pycor = 8  ) [set pcolor magenta set Name "int_7"]
  if (pxcor = 33 ) and (pycor = 8  ) [set pcolor magenta set Name "int_8"]
  if (pxcor = 33 ) and (pycor = 58 ) [set pcolor magenta set Name "int_9"]

  ; Lot entrances
  if (pxcor = 26 ) and (pycor = 120) [set pcolor white set Name "ent_lot_o"]
  if (pxcor = 49 ) and (pycor = 127) [set pcolor white set Name "ent_lot_r"]
  if (pxcor = 83 ) and (pycor = 120) [set pcolor white set Name "ent_lot_h"]
  if (pxcor = 117) and (pycor = 46 ) [set pcolor white set Name "ent_lot_s"]
  if (pxcor = 93 ) and (pycor = 8  ) [set pcolor white set Name "ent_lot_c"]
  if (pxcor = 60 ) and (pycor = 8  ) [set pcolor white set Name "ent_lot_a"]
  if (pxcor = 45 ) and (pycor = 8  ) [set pcolor white set Name "ent_lot_l"]
  if (pxcor = 33 ) and (pycor = 5  ) [set pcolor white set Name "ent_lot_k"]
  if (pxcor = 33 ) and (pycor = 65 ) [set pcolor white set Name "ent_lot_m"]
  if (pxcor = 33 ) and (pycor = 85 ) [set pcolor white set Name "ent_lot_p"]

  ; Places in lot to start looking for parking, note that except for those labelled right entrance numbers are same as those used to "create parking" procedureone
  if (pxcor = 26 ) and (pycor = 118 - 1) [set pcolor 138 set Name "start_lot_o" set status 7 ] ; right entrance
  if (pxcor = 51 ) and (pycor = 128 - 1) [set pcolor 138 set Name "start_lot_r" set status 7 ]
  if (pxcor = 83 ) and (pycor = 128 - 1) [set pcolor 138 set Name "start_lot_h" set status 7 ]
  if (pxcor = 115) and (pycor = 47  - 1) [set pcolor 138 set Name "start_lot_s" set status 7 ] ; right entrance
  if (pxcor = 93 ) and (pycor = 6   - 1) [set pcolor 138 set Name "start_lot_c" set status 7 ]
  if (pxcor = 60 ) and (pycor = 6   - 1) [set pcolor 138 set Name "start_lot_a" set status 7 ]
  if (pxcor = 45 ) and (pycor = 6   - 1) [set pcolor 138 set Name "start_lot_l" set status 7 ]
  if (pxcor = 31 ) and (pycor = 6   - 1) [set pcolor 138 set Name "start_lot_k" set status 7 ] ; right entrance
  if (pxcor = 35 ) and (pycor = 66  - 1) [set pcolor 138 set Name "start_lot_m" set status 7 ]
  if (pxcor = 31 ) and (pycor = 86  - 1) [set pcolor 138 set Name "start_lot_p" set status 7 ] ; right entrance


  set southeast-hunters-waypoints     [
    "blue_portal" "int_6"
    "ent_lot_c" "start_lot_c" "ent_lot_c" "int_6"
    "ent_lot_a" "start_lot_a" "ent_lot_a" "int_7"
    "ent_lot_l" "start_lot_l" "ent_lot_l" "int_8" "int_9"
    "ent_lot_m" "start_lot_m" "ent_lot_m"
    "crazy" "crazy"]
  set southeast-hybrids-waypoints     [
    "indigo_portal" "int_7"
    "ent_lot_a" "start_lot_a" "ent_lot_a" "int_6"
    "ent_lot_c" "start_lot_c" "ent_lot_c" "int_5"
    "ent_lot_s" "start_lot_s" "ent_lot_s" "int_4" "int_3"
    "ent_lot_h" "start_lot_h" "ent_lot_h"
    "crazy" "crazy"]
  set southeast-satisfs-waypoints     [
    "blue_portal" "int_6"
    "ent_lot_c" "start_lot_c" "ent_lot_c" "int_6"
    "ent_lot_a" "start_lot_a" "ent_lot_a" "int_7" "int_8"
    "ent_lot_k" "start_lot_k" "ent_lot_k" "int_8" "int_9" "int_1"
    "ent_lot_o" "start_lot_o" "ent_lot_o"
    "crazy" "crazy"]

  set west-central-hunters-waypoints  [
    "indigo_portal"  "int_7"
    "ent_lot_a" "start_lot_a" "ent_lot_a" "int_7"
    "ent_lot_l" "start_lot_l" "ent_lot_l" "int_8" "int_9"
    "ent_lot_p" "start_lot_p" "ent_lot_p"
    "ent_lot_m" "start_lot_m" "ent_lot_m"
    "crazy" "crazy"]
  set west-central-hybrids-waypoints  [
    "violet_portal"  "int_8"
    "ent_lot_l" "start_lot_l" "ent_lot_l" "int_8"
    "ent_lot_k" "start_lot_k" "ent_lot_k" "int_8" "int_9"
    "ent_lot_m" "start_lot_m" "ent_lot_m" "int_9" "int_8" "int_7" "int_6" "int_5"
    "ent_lot_s" "start_lot_s" "ent_lot_s"
    "crazy" "crazy"]
  set west-central-satisfs-waypoints  [
    "indigo_portal"  "int_7"
    "ent_lot_a" "start_lot_a" "ent_lot_a" "int_7"
    "ent_lot_l" "start_lot_l" "ent_lot_l" "int_8"
    "ent_lot_k" "start_lot_k" "ent_lot_k" "int_8" "int_9" "int_1"
    "ent_lot_o" "start_lot_o" "ent_lot_o"
    "crazy" "crazy"]

  set north-west-hunters-waypoints    [
    "rainbow_portal" "int_9"
    "ent_lot_p" "start_lot_p" "ent_lot_p" "int_1" "int_2"
    "ent_lot_r" "start_lot_r" "ent_lot_r" "int_2"
    "ent_lot_h" "start_lot_h" "ent_lot_h" "int_3" "int_4"
    "ent_lot_s" "start_lot_s" "ent_lot_s"
    "crazy" "crazy"]
  set north-west-hybrids-waypoints    [
    "rainbow_portal" "int_9"
    "ent_lot_p" "start_lot_p" "ent_lot_p" "int_1" "int_2"
    "ent_lot_r" "start_lot_r" "ent_lot_r" "int_2"
    "ent_lot_h" "start_lot_h" "ent_lot_h" "int_2" "int_1"
    "ent_lot_m" "start_lot_m" "ent_lot_m"
    "crazy" "crazy"]
  set north-west-satisfs-waypoints    [
    "orange_portal"
    "ent_lot_r" "start_lot_r" "ent_lot_r" "int_2" "int_1"
    "ent_lot_p" "start_lot_p" "ent_lot_p" "int_9" "int_8"
    "ent_lot_k" "start_lot_k" "ent_lot_k" "int_8" "int_9" "int_1"
    "ent_lot_o" "start_lot_o" "ent_lot_o"
    "crazy" "crazy"]

  set exit_o_lot  ["start_lot_o"  "ent_lot_o"  "int_1" "red_portal"]
  set exit_r_lot  ["start_lot_r"  "ent_lot_r"          "orange_portal"]
  set exit_h_lot  ["start_lot_h"  "ent_lot_h"  "int_2" "orange_portal"]
  set exit_s_lot  ["start_lot_s"  "ent_lot_s"  "int_4" "yellow_portal"]
  set exit_c_lot  ["start_lot_c"  "ent_lot_c"  "int_6" "blue_portal"]
  set exit_a_lot  ["start_lot_a"  "ent_lot_a"  "int_7" "indigo_portal"]
  set exit_l_lot  ["start_lot_l"  "ent_lot_l"  "int_8" "violet_portal"]
  set exit_k_lot  ["start_lot_k"  "ent_lot_k"          "violet_portal"]
  set exit_m_lot  ["start_lot_m"  "ent_lot_m"  "int_9" "rainbow_portal"]
  set exit_p_lot  ["start_lot_p"  "ent_lot_p"  "int_9" "rainbow_portal"]

end


;---------------------------------------------------------------------------------------------------------
;-------------------------------------------SETUP TURTLES (CARS)--------------------------------------------------
;---------------------------------------------------------------------------------------------------------

to setup-cars

  let total_workers (early_workers + standard_workers + late_workers)
  let total_students (morning_student + afternoon_student + early_evening_student + late_evening_student)
  let total_random (short_random + long_random)
  let total_cars  (total_workers + total_students + total_random)

  set turtle-count total_cars
  set turtle-count-list []
  set turtle-count-list lput turtle-count turtle-count-list

  set-default-shape hunters "x"
  set-default-shape satisfs "triangle"
  set-default-shape hybrids "circle"

  ;convert the population proportions to probabilities
  set hunters_probability (hunters_Proportion / (hunters_Proportion + hybrids_Proportion + satisfs_Proportion))
  set hybrids_probability (hybrids_Proportion / (hunters_Proportion + hybrids_Proportion + satisfs_Proportion))
  set satisfs_probability (satisfs_Proportion / (hunters_Proportion + hybrids_Proportion + satisfs_Proportion))

  ;WORKERS
  let temp_EW early_workers
  let temp_SW standard_workers
  let temp_LW late_workers

  Create_New_Cars temp_EW 8000  9000   ;8  to 4
  Create_New_Cars temp_SW 9000  9000   ;9  to 5
  Create_New_Cars temp_EW 10000 9000   ;10 to 6

  ;STUDENTS
  let temp_MS morning_student
  let temp_AS afternoon_student
  let temp_ES early_evening_student
  let temp_LS late_evening_student
  Create_New_Cars temp_MS 9000  3000   ;9    to 12
  Create_New_Cars temp_AS 13000 3500   ;1    to 4:30
  Create_New_Cars temp_ES 16500 2667   ;4:30 to 7:10
  Create_New_Cars temp_LS 19333 2667   ;7:20 to 10:00

  ;RANDOM
  let temp_SR short_random
  let temp_LR long_random

  while [temp_SR > 0] [
    Create_New_Cars 3 (8000 + (random 100 * 100)) (500  + (random 20 * 100 ))
    set temp_SR (temp_SR - 3 )
  ]
  while [temp_LR > 0] [
    Create_New_Cars 3 (8000 + (random 100 * 100)) (3000 + (random 20 * 100 ))
    set temp_LR (temp_LR - 3)
  ]

  ask turtles [
    set-turtles-up-for-next-day
    ifelse (who mod 2 = 1)
      [ set search-type "inner_loop" ]
      [ set search-type "outer_loop" ]
  ]

end

TO Create_New_Cars [Num ENT_TIME STD_PK_TIME]

  ;calculate the proportion of each type
  let num_hunters_create  round(hunters_probability * num)
  let num_hybrids_create  round(hybrids_probability * num)
  let num_satisfs_create  round(satisfs_probability * num)


  ;-------------------------------Create hunterss----------------------------------------
  ;Calculate proportion going to each destination area, (note systematic preference to northwest, can't be helped, but balanced by other breeds preferences)
  let temp_SE floor   (num_hunters_create / 3)
  let temp_WC floor   (num_hunters_create / 3)
  let temp_NW ceiling (num_hunters_create / 3)
  ;Actually create the breed, while assigning creation variables all at once
  create-hunters temp_SE [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "SE_HUNT" set std-waypoint-list southeast-hunters-waypoints set final-x SE-X set final-y SE-Y]
  create-hunters temp_WC [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "WC_HUNT" set std-waypoint-list west-central-hunters-waypoints set final-x WC-X set final-y WC-Y]
  create-hunters temp_NW [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "NW_HUNT" set std-waypoint-list north-west-hunters-waypoints set final-x NW-X set final-y NW-Y]

  ;-------------------------------Create hybridss----------------------------------------
  ;Calculate proportion going to each destination area, (note systematic preference to west-central, can't be helped, but balanced by other breeds preferences)
  set temp_SE floor   (num_hybrids_create / 3)
  set temp_WC ceiling (num_hybrids_create / 3)
  set temp_NW floor   (num_hybrids_create / 3)
  ;Actually create the breed, while assigning creation variables all at once
  create-hybrids temp_SE [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "SE_HYBR" set std-waypoint-list southeast-hybrids-waypoints set final-x SE-X set final-y SE-Y]
  create-hybrids temp_WC [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "WC_HYBR" set std-waypoint-list west-central-hybrids-waypoints set final-x WC-X set final-y WC-Y]
  create-hybrids temp_NW [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "NW_HYBR" set std-waypoint-list north-west-hybrids-waypoints set final-x NW-X set final-y NW-Y]

  ;-------------------------------Create satisfss----------------------------------------
  ;Calculate proportion going to each destination area, (note systematic preference to southeast, can't be helped, but balanced by other breeds preferences)
  set temp_SE ceiling (num_satisfs_create / 3)
  set temp_WC floor   (num_satisfs_create / 3)
  set temp_NW floor   (num_satisfs_create / 3)
  ;Actually create the breed, while assigning creation variables all at once
  create-satisfs temp_SE [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "SE_SATS" set std-waypoint-list southeast-satisfs-waypoints set final-x SE-X set final-y SE-Y]
  create-satisfs temp_WC [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "WC_SATS" set std-waypoint-list west-central-satisfs-waypoints set final-x WC-X set final-y WC-Y]
  create-satisfs temp_NW [set Standard-parking-time STD_PK_TIME + (random 1000) - 500 set entrance-time ENT_TIME + (random 500) - 250 set type-of-turtle "NW_SATS" set std-waypoint-list north-west-satisfs-waypoints set final-x NW-X set final-y NW-Y]

end


;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------
;-------------------------------------------Utility Programs----------------------------------------------
;---------------------------------------------------------------------------------------------------------
;---------------------------------------------------------------------------------------------------------



to set-turtles-up-for-next-day

  setxy 60 63
  set speed  base-speed + random-float random-speed
  set turtle-state 10
  hide-turtle
  set waypoint-list std-waypoint-list

end


;-------------------------------------------Routing to next destination----------------------------------

to go-to-next-destination

  set waypoint-list remove-item 0 waypoint-list

  ;This section is designed to speed things up
  let first-dest-text (item 0 waypoint-list)
  let first-destination one-of patches with [name = first-dest-text]
  set waypt-x [pxcor] of first-destination
  set waypt-y [pycor] of first-destination
  facexy waypt-x waypt-y

end

;-------------------------------------------Go from routing to searching----------------------------------


to transition-to-searching-for-a-space

  ;keep track of lot capacity
  let curr-dest first waypoint-list
  if last curr-dest = "o" [set lot_o_current (lot_o_current + 1)]
  if last curr-dest = "r" [set lot_r_current (lot_r_current + 1)]
  if last curr-dest = "h" [set lot_h_current (lot_h_current + 1)]
  if last curr-dest = "s" [set lot_s_current (lot_s_current + 1)]
  if last curr-dest = "c" [set lot_c_current (lot_c_current + 1)]
  if last curr-dest = "a" [set lot_a_current (lot_a_current + 1)]
  if last curr-dest = "l" [set lot_l_current (lot_l_current + 1)]
  if last curr-dest = "k" [set lot_k_current (lot_k_current + 1)]
  if last curr-dest = "m" [set lot_m_current (lot_m_current + 1)]
  if last curr-dest = "p" [set lot_p_current (lot_p_current + 1)]


  ;Establish new state variables
  set waypoint-list remove-item 0 waypoint-list
  set curr-dest first waypoint-list
  set turtle-state 30
  set color white
  setxy (round xcor) (round ycor)  ;move back to origin of patch
  set No-spots-counter 0
  set cooldown-counter 10

  ;left entrance, inner loop
  if (curr-dest = "ent_lot_r"  and search-type = "inner_loop")   [set heading 90]
  if (curr-dest = "ent_lot_h"  and search-type = "inner_loop")   [set heading 90]
  if (curr-dest = "ent_lot_c"  and search-type = "inner_loop")   [set heading 90]
  if (curr-dest = "ent_lot_a"  and search-type = "inner_loop")   [set heading 90]
  if (curr-dest = "ent_lot_l"  and search-type = "inner_loop")   [set heading 90]
  if (curr-dest = "ent_lot_m"  and search-type = "inner_loop")   [set heading 90]

  ;left entrance, outer loop
  if (curr-dest = "ent_lot_r"  and search-type = "outer_loop")   [set heading 180]
  if (curr-dest = "ent_lot_h"  and search-type = "outer_loop")   [set heading 180]
  if (curr-dest = "ent_lot_c"  and search-type = "outer_loop")   [set heading 180]
  if (curr-dest = "ent_lot_a"  and search-type = "outer_loop")   [set heading 180]
  if (curr-dest = "ent_lot_l"  and search-type = "outer_loop")   [set heading 180]
  if (curr-dest = "ent_lot_m"  and search-type = "outer_loop")   [set heading 180]

  ;right entrance, inner loop
  if (curr-dest = "ent_lot_o"  and search-type = "inner_loop")   [set heading 180]
  if (curr-dest = "ent_lot_s"  and search-type = "inner_loop")   [set heading 180]
  if (curr-dest = "ent_lot_k"  and search-type = "inner_loop")   [set heading 180]
  if (curr-dest = "ent_lot_p"  and search-type = "inner_loop")   [set heading 180]

  ;right entrance, outer loop
  if (curr-dest = "ent_lot_o"  and search-type = "outer_loop")   [set heading 270]
  if (curr-dest = "ent_lot_s"  and search-type = "outer_loop")   [set heading 270]
  if (curr-dest = "ent_lot_k"  and search-type = "outer_loop")   [set heading 270]
  if (curr-dest = "ent_lot_p"  and search-type = "outer_loop")   [set heading 270]

end


;-------------------------------------------Back to normal----------------------------------

to back-to-normal

  ;track changes
  if breed = hunters [set hunters_waypoints_change (hunters_waypoints_change + 1)]
  if breed = hybrids [set hybrids_waypoints_change (hybrids_waypoints_change + 1)]
  if breed = satisfs [set satisfs_waypoints_change (satisfs_waypoints_change + 1)]

  ;give them new parking directions
  let randomchoice random 9
  if (randomchoice = 0)   [set std-waypoint-list southeast-hunters-waypoints]
  if (randomchoice = 1)   [set std-waypoint-list southeast-hybrids-waypoints]
  if (randomchoice = 2)   [set std-waypoint-list southeast-satisfs-waypoints]
  if (randomchoice = 3)   [set std-waypoint-list west-central-hunters-waypoints]
  if (randomchoice = 4)   [set std-waypoint-list west-central-hybrids-waypoints]
  if (randomchoice = 5)   [set std-waypoint-list west-central-satisfs-waypoints]
  if (randomchoice = 6)   [set std-waypoint-list north-west-hunters-waypoints]
  if (randomchoice = 7)   [set std-waypoint-list north-west-hybrids-waypoints]
  if (randomchoice = 8)   [set std-waypoint-list north-west-satisfs-waypoints]

  set Searching-cars (Searching-cars - 1)

  ;arrive 10 minutes earlier
  if entrance-time > 7900 [set entrance-time (entrance-time - 167)]

  ;reboot
  set-turtles-up-for-next-day

  ;but if this has been happening too much - give up
  set crazy-count (crazy-count + 1)
  if crazy-count >= 3 [
    if breed = hunters [set hunters_abandon_drive_GMU (hunters_abandon_drive_GMU + 1)]
    if breed = hybrids [set hybrids_abandon_drive_GMU (hybrids_abandon_drive_GMU + 1)]
    if breed = satisfs [set satisfs_abandon_drive_GMU (satisfs_abandon_drive_GMU + 1)]
    set turtle-count turtle-count - 1
    die
  ]

end


;-------------------------------------------Reports if there is available parking----------------------------------

to-report park_avail [destination requirement]

  let current     1
  let capacity    1

  if last destination = "o" [set current lot_o_current     set capacity lot_o_capacity]
  if last destination = "r" [set current lot_r_current     set capacity lot_r_capacity]
  if last destination = "h" [set current lot_h_current     set capacity lot_h_capacity]
  if last destination = "s" [set current lot_s_current     set capacity lot_s_capacity]
  if last destination = "c" [set current lot_c_current     set capacity lot_c_capacity]
  if last destination = "a" [set current lot_a_current     set capacity lot_a_capacity]
  if last destination = "l" [set current lot_l_current     set capacity lot_l_capacity]
  if last destination = "k" [set current lot_k_current     set capacity lot_k_capacity]
  if last destination = "m" [set current lot_m_current     set capacity lot_m_capacity]
  if last destination = "p" [set current lot_p_current     set capacity lot_p_capacity]

  let fullness ((current / capacity) + random (2 * variability-in-lot-full-estimate) - variability-in-lot-full-estimate)

  ifelse fullness > requirement
    [report 0] ;too full
    [report 1] ;ok to park

end


;-------------------------------------------keep track of lot capacity----------------------------------

to set-lot-count-down-one

  let curr-dest first waypoint-list
  if last curr-dest = "o" [set lot_o_current (lot_o_current - 1)]
  if last curr-dest = "r" [set lot_r_current (lot_r_current - 1)]
  if last curr-dest = "h" [set lot_h_current (lot_h_current - 1)]
  if last curr-dest = "s" [set lot_s_current (lot_s_current - 1)]
  if last curr-dest = "c" [set lot_c_current (lot_c_current - 1)]
  if last curr-dest = "a" [set lot_a_current (lot_a_current - 1)]
  if last curr-dest = "l" [set lot_l_current (lot_l_current - 1)]
  if last curr-dest = "k" [set lot_k_current (lot_k_current - 1)]
  if last curr-dest = "m" [set lot_m_current (lot_m_current - 1)]
  if last curr-dest = "p" [set lot_p_current (lot_p_current - 1)]

end


;-------------------------------------------Change waypoints to exit GMU waypoints----------------------------------

to update-waypoints-to-exit

  let curr-dest first waypoint-list

  if last curr-dest = "o" [set waypoint-list exit_o_lot]
  if last curr-dest = "r" [set waypoint-list exit_r_lot]
  if last curr-dest = "h" [set waypoint-list exit_h_lot]
  if last curr-dest = "s" [set waypoint-list exit_s_lot]
  if last curr-dest = "c" [set waypoint-list exit_c_lot]
  if last curr-dest = "a" [set waypoint-list exit_a_lot]
  if last curr-dest = "l" [set waypoint-list exit_l_lot]
  if last curr-dest = "k" [set waypoint-list exit_k_lot]
  if last curr-dest = "m" [set waypoint-list exit_m_lot]
  if last curr-dest = "p" [set waypoint-list exit_p_lot]

end
@#$#@#$#@
GRAPHICS-WINDOW
9
10
622
674
-1
-1
5.0
1
10
1
1
1
0
0
0
1
0
120
0
130
1
1
1
ticks
30.0

BUTTON
631
12
686
53
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
693
12
748
52
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

PLOT
850
22
1398
709
Capacity and Current
time
Cars
0.0
300.0
-2.0
160.0
true
true
"" ""
PENS
"O_capacity" 1.0 0 -2674135 true "" ""
"O_current" 1.0 2 -2674135 true "" ""
"Rap1_capacity" 1.0 0 -955883 true "" ""
"Rap1_current" 1.0 2 -955883 true "" ""
"Rap2_capacity" 1.0 0 -1184463 true "" ""
"Rap2_current" 1.0 2 -1184463 true "" ""
"Shan_capacity" 1.0 0 -10899396 true "" ""
"Shan_current" 1.0 2 -10899396 true "" ""
"C_capacity" 1.0 0 -13840069 true "" ""
"C_current" 1.0 2 -13840069 true "" ""
"A_capacity" 1.0 0 -11221820 true "" ""
"A_current" 1.0 2 -11221820 true "" ""
"L_capacity" 1.0 0 -13345367 true "" ""
"L_current" 1.0 0 -13345367 true "" ""
"K_capacity" 1.0 0 -8630108 true "" ""
"K_current" 1.0 0 -8630108 true "" ""
"M_capacity" 1.0 0 -5825686 true "" ""
"M_current" 1.0 0 -5825686 true "" ""
"P_capacity" 1.0 0 -2064490 true "" ""
"P_current" 1.0 2 -2064490 true "" ""

BUTTON
762
12
841
52
go (once)
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
634
300
806
333
Standard_Workers
Standard_Workers
0
250
143.0
1
1
NIL
HORIZONTAL

SLIDER
635
337
807
370
Late_Workers
Late_Workers
0
250
64.0
1
1
NIL
HORIZONTAL

SLIDER
634
261
806
294
Early_Workers
Early_Workers
0
250
67.0
1
1
NIL
HORIZONTAL

SLIDER
635
377
807
410
Morning_Student
Morning_Student
0
250
173.0
1
1
NIL
HORIZONTAL

SLIDER
635
415
807
448
Afternoon_Student
Afternoon_Student
0
250
171.0
1
1
NIL
HORIZONTAL

SLIDER
635
452
807
485
Early_Evening_Student
Early_Evening_Student
0
250
61.0
1
1
NIL
HORIZONTAL

SLIDER
635
490
807
523
Late_Evening_Student
Late_Evening_Student
0
250
29.0
1
1
NIL
HORIZONTAL

SLIDER
636
551
808
584
Short_Random
Short_Random
0
250
32.0
1
1
NIL
HORIZONTAL

SLIDER
636
591
808
624
Long_Random
Long_Random
0
250
5.0
1
1
NIL
HORIZONTAL

SLIDER
634
62
667
212
Hunters_Proportion
Hunters_Proportion
0
10
3.0
1
1
NIL
VERTICAL

SLIDER
679
62
712
212
Satisfs_Proportion
Satisfs_Proportion
0
10
3.0
1
1
NIL
VERTICAL

SLIDER
726
61
759
211
Hybrids_Proportion
Hybrids_Proportion
0
10
3.0
1
1
NIL
VERTICAL

TEXTBOX
70
631
105
649
K-Lot
11
0.0
1

SWITCH
635
219
740
252
Graphing
Graphing
0
1
-1000

TEXTBOX
258
625
304
643
L-Lot
11
0.0
1

TEXTBOX
322
99
369
117
Rap-1
11
0.0
1

TEXTBOX
497
101
539
119
Rap-2
11
0.0
1

TEXTBOX
479
423
519
441
Shan
11
0.0
1

TEXTBOX
380
625
415
643
A-lot
11
0.0
1

TEXTBOX
512
625
548
643
C-Lot
11
0.0
1

TEXTBOX
123
232
157
250
P-lot
11
0.0
1

TEXTBOX
209
334
288
352
Mason
11
0.0
1

TEXTBOX
86
67
126
85
O-lot
11
0.0
1

@#$#@#$#@
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
setup
repeat 180 [ go ]
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
