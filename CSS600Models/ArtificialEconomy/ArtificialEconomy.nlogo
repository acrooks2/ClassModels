extensions [profiler]
globals [farm-patches city-patches trade-patches]
patches-own [yield prod]
turtles-own [produce widget money age ptrade wtrade ptrade-t-1 ptrade-t-2 ptrade-t-3
  ptrade-t-4 ptrade-t-5 ptrade-t-6 ptrade-t-7   wtrade-t-1 wtrade-t-2 wtrade-t-3
  wtrade-t-4 wtrade-t-5 wtrade-t-6  wtrade-t-7 deposit pexchange wexchange mexchange
  savings capital pdebt fdebt securities productivity pprice wprice
  farmer-interest-rate professional-interest-rate withdraw
  reserve-ratio produce-purchaseprice produce-saleprice widget-purchaseprice
  widget-saleprice fbusiness pbusiness wealth savings_propensity bankrupt]
breed [farmers farmer]
breed [professionals professional]
breed [stores store]
breed [farmerBanks farmerBank]
breed [professionalBanks professionalBank]

to step
  go
end

; msg
;
; debug method to print a message to the console
;
to msg [ txt ]
  let time-tag ticks
  type "debug: ticks = " type time-tag type " " type txt print " "
end


to go
  msg "set-interest-rate..." set-interest-rate msg "set-interest-rate finished OK"
  msg "repay starting..." repay msg "repay finished OK"
  msg "disasterstarting..." disaster msg "disaster finished OK"
  ifelse random 100 < 50 [                        ; flip order randomly, or else store is biased toward one breed
    msg "move-farmers starting..." move-farmers msg "move-farmers finished OK"
    msg "move-professionals starting..." move-professionals msg "move-professionals finished OK"]
  [
    msg "move-professionals starting..." move-professionals msg "move-professionals finished OK"
    msg "move-farmers starting..." move-farmers msg "move-farmers finished OK"]
  ;  reproduce-farmers
  ;  reproduce-professionals
  msg "renew-fuel starting..." renew-fuel msg "renew-fuel finshed OK"
  msg "store-deposit..." store-deposit msg "store-deposit finished OK"
  msg "bankruptcy starting..." bankruptcy msg "bankruptcy finished OK"
  msg "compound-interest starting..." compound-interest msg "compound-interest finished OK"
 msg "borrow-emergency-funds starting..." borrow-emergency-funds msg "borrow-emergency-funds finished OK"
 ; msg "farmer-professional-switch starting..." farmer-professional-switch msg "farmer-professional-switch finished OK" ; for labor mobility
  msg "update-macro-stats starting..." update-macro-stats msg "update-macro-stats finished OK"
  msg "trades-last-period starting..." trades-last-period msg "trades-last-period finished OK"

  updateplots
  tick
end

to setup
  clear-all
  setup-landscape
  setup-population
  setup-infrastructure
  setup-prices
  setup-interest-rates
  update-macro-stats
  reset-ticks
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-landscape

  set farm-patches patches with [pxcor < 20]  ; define patches
  ask farm-patches [ set pcolor green ]
  ask farm-patches [ set yield 1 ]

  set city-patches patches with [pxcor > 20 ]
  ask city-patches [set pcolor red]
  ask city-patches [set yield 1]

  set trade-patches patches with [pxcor = 20 ]
  ask trade-patches [set pcolor blue]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-population
  create-farmers population [
    set shape "person farmer"
    set productivity 1
 ;   set productivity random-normal 1 .5
 ;   if productivity < .1 [
 ;     set productivity .1]

    move-to-empty-one-of farm-patches
    set color white
    set size 1
    set age 1
  ;  set farmers-reproduce 50
    set money random-normal 50 20

    set savings_propensity random-normal 5 2
    if savings_propensity < 1 [
      set savings_propensity 1]
    set bankrupt 0
  ]

  create-professionals population [
    set shape "person business"
    set productivity 1
;    set productivity random-normal 1 .5
;    if productivity < .1 [
;      set productivity .1]
    move-to-empty-one-of city-patches
    set color white
    set size 1
    set age 1
  ;  set professionals-reproduce 30
    set money random-normal 50 20
    set savings_propensity random-normal 5 2    if savings_propensity < 1 [
      set savings_propensity 1]
    set bankrupt 0
  ]
end

to move-to-empty-one-of [locations]  ;; turtle procedure
  move-to one-of locations
  while [any? other turtles-here] [
    move-to one-of locations
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-infrastructure
  create-stores 1
  [                    ; starting money stock determined with respect to total population
    set shape "store"
    setxy 20 20
    set color white
    set size 1
    set produce 0
   ; set trade 0
    set money 500 * (count professionals + count farmers)
  ]

  create-farmerBanks 1
  [
    set shape "bank"
    setxy 10 10
    set color yellow
    set size 1
  ]

  create-professionalBanks 1
  [
    set shape "bank"
    setxy 30 10
    set color white
    set size 1
  ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to set-productivity
  ask farmers [
    set productivity 1 + (widget) ^ (1 / 2) ;;Farmers use widget too get produce
  ]                                       ; ; Like Cobb Douglass, L = 1
  ask professionals
  [ set productivity 1 + (produce) ^ (1 / 2)] ;; pros use produce to make widget
end


to setup-prices ; starting prices
  ask stores[
    set pprice 100
    set wprice 100
  ]
end

to setup-interest-rates ; starting interest rates
  ask farmerBanks [
    set farmer-interest-rate .002]
  ask professionalBanks [
    set professional-interest-rate .002]
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



to move-farmers
  ask farmers [
    set age age + 1
    set-productivity
    ifelse produce < random-normal 50 15 [ ; farmers follow a rule of thumb, action
      find-new-farmerLocation]            ; is subject to minor fluctuations. Same
    [next-stepf]                          ; for professionals.

    ;if random 100 < 1 [
    ;]
    ;set produce produce
    set widget widget * (1 - depreciation)   ;; widgets  get used while farmer gathers produce
  ]
end



to find-new-farmerLocation

  ;Farmers search for green patch

   let nearest-farm-patch one-of (patches with [pcolor = green] in-cone 1 360)
   ifelse is-patch? nearest-farm-patch[
   face nearest-farm-patch
   fd 1
   ask patch-here [
     if pcolor = green [
     set pcolor black]  ]
   set produce produce + (yield * productivity)
;   set productivity productivity - depreciation
   ]
   [
     ;; move to black patch if they cannot find a green patch
       let nearest-black-patch one-of (patches with [pcolor = black] in-cone 1 360)
       ifelse is-patch? nearest-black-patch [

         face nearest-black-patch
         fd 1
;         set productivity productivity - depreciation
   ]
       [
         ;; Walk to farmerbank if they get lost...
         face one-of farmerBanks
         fd 1]

   ]
 end

to next-stepf

  getMoney-farmer
                ; farmer checks if wealthy enough to purchase widget
  ifelse money  + savings + produce * [pprice] of one-of stores + widget * [wprice] of one-of stores - fdebt > (1 + markup) * [wprice] of one-of stores
  [getWidget-farmer]
  [find-new-farmerLocation]
 if random 10 < 1 [deposit-farmer-savings]   ; visit bank every now and again
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to move-professionals
  ask professionals [
    set age age + 1
    set-productivity
    ifelse widget < random-normal 50 15  ;; see "move-farmers"
    [find-new-professionalLocation]

    [next-stepp]

    set produce produce * (1 - depreciation) ; produce used while making widgets


  ]
end


 to find-new-professionalLocation
   ;; works like with the farmer, but with the red (yellow) patches

   let nearest-city-patch one-of (patches with [pcolor = red] in-cone 1 360)
   ifelse is-patch? nearest-city-patch [
   fd 1
   ask patch-here [
     if pcolor = red [
     set pcolor yellow]]

   set widget widget + (yield * productivity)     ;; - cost
;   set productivity productivity - depreciation
   ]
   [
     let nearest-yellow-patch one-of (patches with [pcolor = yellow] in-cone 1 360)
     ifelse is-patch? nearest-yellow-patch [
       face nearest-yellow-patch
       fd 1]
     [face one-of professionalBanks ; if professional gets lost, walk toward proBank
       fd 1]

   ]


 end

to next-stepp
    getMoney-professional

    ;professional checks to see if wealthy enough to buy produce
   ifelse money + savings + produce * [pprice] of one-of stores + widget * [wprice] of one-of stores - pdebt > (1 + markup * [pprice]  of one-of stores)
   [ getProduce-professional]
   [find-new-professionalLocation]
   ; Out of habit, professionals visit bank every now and then
    if random 10 < 1 [deposit-professional-savings]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to getMoney-farmer
  ask stores [
    set-prices
    ; store checks if enough money to buy farmer's produce if not, withdraw savings and/or borrow
    if money < pprice * [produce] of myself[
      set fbusiness true
      store-withdraw]
    if money < pprice * [produce] of myself [
      set fbusiness true
      borrow-store]]
 ; Purchase produce until either produce is gone or store's money has run low
  if produce >= 1 and ([money] of one-of stores ) >=  [pprice] of one-of stores[
    while [produce >= 1 and ([money] of one-of stores ) >= [pprice] of one-of stores]
      [
        set money money + [pprice] of one-of stores
        set produce produce - 1
        ask one-of stores [
          set produce produce + 1
          set money money - pprice
          ;set trade trade + 1
          set produce-purchaseprice pprice
                      ] ;; store puchased produce
      ]
    ]

end

to getWidget-Farmer
  set-prices
  ;; check if enough money to buy widget, if not withdraw savings / borrow
  if money + savings > ( 1 + markup) *  [wprice] of one-of stores and money < ( 1 + markup) * [wprice] of one-of stores and [widget] of one-of stores >= 1 [
    withdraw-farmer-savings]
  if money < [wprice] of one-of stores [
    borrow-farmer]
  ;Purchase widgets until no more widgets or insufficient funds.
  if money >= ( 1 + markup) * [wprice] of one-of stores and ([widget] of one-of stores) >= 1 [
    while [money >= ( 1 + markup) * savings_propensity * [wprice] of one-of stores and ([widget] of one-of stores) >= 1] [


        set widget widget + 1
        set money money - ( 1 + markup) * [wprice] of one-of stores ; store charges markeup
        ask one-of stores [
          set money money + ( 1 + markup) * wprice
          set widget widget - 1
          set wtrade wtrade + 1
          set widget-saleprice ( 1 + markup) * [wprice] of one-of stores ;; store sold widget
                 ]
      ]
    ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to getMoney-professional  ;See getMoney-farmer
  set-prices
  if [money] of one-of stores < wprice * widget [
   ask stores [
     set pbusiness true
     store-withdraw]]
  if [money] of one-of stores < wprice * widget[
    ask stores [
      set pbusiness true
      borrow-store]]
 if widget >= 1 and ([money] of one-of stores) >= wprice [
    while [widget >= 1 and ([money] of one-of stores) >= wprice]

      [
        set money money + wprice
        set widget widget - 1
        ask one-of stores [
          set money money - wprice
          set widget widget + 1
          ;    set trade trade + 1
          set widget-purchaseprice  wprice] ;; price that store bought widget
      ]
    ]


end

to getProduce-professional ; see getWidget-farmer
  set-prices
  if money < (1 + markup) * [pprice] of one-of stores and money + savings > (1 + markup) * [pprice] of one-of stores [
    withdraw-professional-savings]
  if money < (1 + markup) * [pprice] of one-of stores [

    borrow-professional]
  if money >= ( 1 + markup) * [pprice] of one-of stores and ([produce] of one-of stores) >= 1 [
    while [money >= ( 1 + markup) * savings_propensity * [pprice] of one-of stores and ([produce] of one-of stores) >= 1]

      [
        set money money - ( 1 + markup) * [pprice] of one-of stores ; store charges markup on consumer purchases
        set produce produce + 1
        ask one-of stores [
          set money money + ( 1 + markup) * pprice
          set produce produce - 1
          set ptrade ptrade + 1
          set produce-saleprice ( 1 + markup) * pprice   ;; price that store sold produce
          ]
      ]
    ]

end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to set-prices
  ; Prices are set according to the stores stock of goods. If stocks fall too low,
  ; prices rise. If they get too high, prices fall.
  ask stores [
    if wealth > 0 [
   if widget > 0 and widget < 1 * widget-supply-level * (count farmers) [
     set wprice wprice * 1.0001]
   if widget < 2 * widget-supply-level * (count farmers)[
     set wprice wprice * 1.00005]
   if widget < 3 * widget-supply-level * (count farmers) [
     set wprice wprice * 1.00005]]

    if widget > 7 * widget-supply-level * (count farmers) [
      set wprice wprice * .9999]
    if widget > 8 * widget-supply-level * (count farmers) [
      set wprice wprice * .9999]
    if widget > 9 * widget-supply-level * (count farmers) [
      set wprice wprice * .9995]

    ; this line necessary because of netlogo has bug when wprice < .1, so price rises an infinitesimal amount

    if wprice < .1 [
      set wprice wprice * 1.000000000001]

    if wealth > 0 [

    if produce > 0 and produce < 1  * produce-supply-level * (count professionals)[
      set pprice pprice * 1.0001]
    if produce < 2 * produce-supply-level * (count professionals)[
      set pprice pprice * 1.00005]
    if produce < 3 * produce-supply-level * (count professionals)[
      set pprice pprice * 1.00005]  ]
    if produce > 7 * produce-supply-level * (count professionals)[
      set pprice pprice * .9999]
    if produce > 8 * produce-supply-level * (count professionals)[
      set pprice pprice * .9999]
    if produce > 9 * produce-supply-level * (count professionals)[
      set pprice pprice * .9995]

    ; this line necessary because of netlogo has bug when pprice < .1

    if pprice < .1 [set pprice pprice * 1.000000000001]

; If store is illiquid, lower price goods to accumulate funds

if money + savings - pdebt - fdebt < 0 [
  set pprice pprice * .9995
  set wprice wprice * .9995]
]



  ask farmers[
    set pprice [pprice] of one-of stores
    set wprice [wprice] of one-of stores]
  ask professionals[
    set pprice [pprice] of one-of stores
    set wprice [wprice] of one-of stores]
  ask farmerBanks [
    set pprice [pprice] of one-of stores
    set wprice [wprice] of one-of stores]
  ask professionalBanks [
    set pprice [pprice] of one-of stores
    set wprice [wprice] of one-of stores]



end



to trades-last-period
  ; if nothing sold last period, lower price. After 7 periods, 5 percent drop
  ask stores [
    if ticks > 20 [

;      if wprice > 1[
    if wtrade = wtrade-t-7[; and widget  > 3 * widget-supply-level * (count farmers)[
      set wprice wprice * .95]
    if wtrade = wtrade-t-6[; and widget  > 3 * widget-supply-level * (count farmers)[
      set wprice wprice * .98]
    if wtrade = wtrade-t-5[; and widget  > 3 * widget-supply-level *  (count farmers)[
      set wprice wprice * .98]
;    if wtrade = wtrade-t-4[; and widget  > 3 * widget-supply-level * (count farmers)[
;      set wprice wprice * .999]
;    if wtrade = wtrade-t-3[; and widget  > 3 * widget-supply-level * (count farmers)[
;      set wprice wprice * .99]
;    if wtrade = wtrade-t-2[; and widget  > 3 * widget-supply-level * (count farmers)[
;      set wprice wprice * .99]
;    if wtrade = wtrade-t-1[; and widget  > 3 * widget-supply-level * (count farmers)[
;      set wprice wprice * .99] ]
 ;     ]
  ;  if pprice > 1 [
    if ptrade = ptrade-t-7[; and produce > 3 * produce-supply-level * (count professionals) [
      set pprice pprice * .95]
    if ptrade = ptrade-t-6[; and produce > 3 * produce-supply-level * (count professionals)[
      set pprice pprice * .98]
    if ptrade = ptrade-t-5[; and produce > 3 * produce-supply-level * (count professionals)[
      set pprice pprice * .98]
;    if ptrade = ptrade-t-4[; and produce > 3 * produce-supply-level * (count professionals)[
;      set pprice pprice * .999]
;    if ptrade = ptrade-t-3[; and produce > 3 * produce-supply-level * (count professionals)[
;      set pprice pprice * .99]
;    if ptrade = ptrade-t-2[; and produce > 3 * produce-supply-level * (count professionals)[
;      set pprice pprice * .99]
;      if ptrade = ptrade-t-1[; and produce  > 3 * produce-supply-level * (count professionals)[
;        set pprice pprice * .99] ]

   ;store reandomly checks to see if it can bump up prices
    if random 20 < 1 [set wprice wprice * 1.05]
    if random 20 < 1 [set pprice pprice * 1.05]
   set ptrade-t-7 ptrade-t-6
   set wtrade-t-7 wtrade-t-6

   set ptrade-t-6 ptrade-t-5
   set wtrade-t-6 wtrade-t-5


   set ptrade-t-5 ptrade-t-4
   set wtrade-t-5 wtrade-t-4

   set ptrade-t-4 ptrade-t-3
   set wtrade-t-4 wtrade-t-3

   set ptrade-t-3 ptrade-t-2
   set wtrade-t-3 wtrade-t-2

   set ptrade-t-2 ptrade-t-1
   set wtrade-t-2 wtrade-t-1

   set ptrade-t-1 ptrade
   set wtrade-t-1 wtrade

    ]
  ]
end
to borrow-emergency-funds
  ask farmerBanks
  [
    ; borrow in units of 100
    if [money] of one-of professionalBanks / ([securities] of one-of professionalBanks  + .000000001) > .01  [ ;sum [savings] of farmers <  20 * [wprice] of one-of stores [ ; add decimal to avoid divde by zero
      set pdebt pdebt + 100
      set money money + 100
      ask one-of professionalBanks [
        set money money - 100
        set securities securities + 100]
    ]
    ; repay some of debt  if funds available
    if money > .1 * pdebt [
      set deposit pdebt * .1
      set money money - deposit
      set pdebt pdebt - deposit
    ask one-of professionalBanks
      [
        set money money + [deposit] of myself
        set securities securities - [deposit] of myself
      ]
    ]
  ]

  ask professionalBanks [
; see above
   if [money] of one-of farmerBanks / ([securities] of  one-of farmerBanks + .000000001) > .01 [ ;sum [savings] of professionals <  20 * [pprice] of one-of stores and [money] of one-of farmerBanks / ([securities] of  one-of farmerBanks + .000000001) > .01 [ ; add decimal to avoid divde by zero
    set fdebt fdebt + 100
    set money money + 100
   ask one-of farmerBanks [
     set money money - 100
     set securities securities + 100]
   ]
   if money > .1 * pdebt [
   set deposit fdebt * .1
   set money money - deposit
   set fdebt fdebt - deposit
   ask one-of farmerBanks [
     set money money + [deposit] of myself
     set securities securities - [deposit] of myself]
   ]
    ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Allows for labor mobility when turned on. Farmer's become professionals or vice versa when prices diverge.

to farmer-professional-switch
  ask farmers[
    if random 10 < 1 and (count farmers) / (count professionals) > .1 and [pprice] of one-of stores > 0[
      let price-ratio ( [wprice] of one-of stores / [pprice] of one-of stores)
      if ( price-ratio ) > 2 [
        set deposit 50 * price-ratio
        if money > deposit [
          set money money - deposit
          ask one-of stores [
            set money money + [deposit] of myself ]
          hatch-professionals 1 [
            set money money
            set produce produce
            set fdebt fdebt
            set widget widget              ;;;; you'll have to communicate through the patches
             ]
          die
      ]
    ]
  ]
  ]
  ask professionals[
    if random 10 < 1 and (count professionals) / (count farmers) > .1 and [wprice] of one-of stores > 0 [
      let price-ratio ( [pprice] of one-of stores / [wprice] of one-of stores)
      if (price-ratio) > 2 [
        set deposit 50 * price-ratio
        if money > deposit [
          set money money - deposit
          ask one-of stores[
            set money money + [deposit] of myself]
          hatch-farmers 1[
            set money money
            set produce produce
            set widget widget
            set pdebt pdebt   ]
          die
      ]
    ]
  ]
  ]
end

;;;;;;;];;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to borrow-store
    ;; store is low on money and bank can afford to lend
    ifelse random 100 < 50 [ ; decision for borrowing from one bank or the other is random
      if fbusiness = true [
         while [money < 1.1 * pprice * [produce] of myself  and  [money] of one-of farmerBanks / ([securities] of one-of farmerBanks + .00000000001) > .1 ; denominator cannot equal zero
           and fdebt + pdebt < .9 * (produce * pprice + widget * wprice + money + savings)][

      ask one-of farmerBanks [
       set securities securities + [pprice] of one-of stores
        set money money - [pprice] of one-of stores]
      set fdebt fdebt + pprice
      set money money + pprice]]]


   [ if pbusiness = true [
      while [money < 1.1 * wprice * [widget] of one-of stores  and [money] of one-of professionalBanks / ([securities] of one-of professionalBanks + .0000000000001) > .1 and ; see above
         fdebt + pdebt < .9 * (produce * pprice + widget * wprice + money + savings)][
      ask one-of professionalBanks [
        set securities securities + [wprice] of one-of stores
        set money money - [wprice] of one-of stores]

      set pdebt pdebt + wprice
      set money money + wprice
    ]]]

end

to borrow-farmer
  while[  money <  (1 + markup) * wprice * [widget] of one-of stores and [money] of one-of farmerBanks > (1 + markup) * wprice and
     fdebt < .99 * pprice * (produce + wprice * widget + money + savings)] [
     ;; farmers and pros borrow up to 90% of wealth
    set fdebt fdebt + (1 + markup) * wprice
    set money money + (1 + markup) * wprice

    ask one-of farmerBanks [
      set securities securities + (1 + markup) *  wprice
      set money money - (1 + markup) * wprice]
  ]

end
to borrow-professional
    ;see above
  while [money < (1 + markup) *  pprice * [produce] of one-of stores  and [money] of one-of professionalbanks > (1 + markup) *  pprice and
  pdebt < .99 * (pprice * produce + wprice * widget + money + savings - pdebt)][
    set pdebt pdebt + (1 + markup) * pprice
    set money money + (1 + markup) * pprice



    ask one-of professionalBanks [
      set securities securities + (1 + markup) * pprice
      set money money - (1 + markup) * pprice]
  ]

set-interest-rate
end

to repay
ask stores [
  if money >  (pprice) and fdebt > 0 and money > .1 * fdebt[
    set deposit fdebt * .1
    set fdebt fdebt - deposit
    set money money - deposit

    ask one-of farmerBanks [
      set securities securities - [deposit] of myself
      set money money + [deposit] of myself]
]
  if fdebt > 0 and savings > .1 * fdebt[
    set deposit fdebt * .1
    set fdebt fdebt - deposit
    set savings savings - deposit
    ask one-of farmerBanks[
      set securities securities -[deposit] of myself]
    ]

if pdebt > 0 and money > .1 * pdebt[
    set deposit pdebt * .1
    set pdebt pdebt - deposit
    set money money - deposit

    ask one-of professionalBanks [
      set securities securities - [deposit] of myself
      set money money + [deposit] of myself
    ]
]
if pdebt > 0 and savings > .1 * pdebt [
  set deposit pdebt * .1
  set pdebt pdebt - deposit
  set savings savings - deposit
  ask one-of professionalBanks[
    set securities securities - [deposit] of myself]
]
  ]
ask farmers [
  ;pay debt with money
  set mexchange fdebt * .05
if money > wprice and money > mexchange [
  set fdebt fdebt - mexchange
  set money money - mexchange
  ask one-of farmerBanks [
    set securities securities - [mexchange] of myself
    set money money + [mexchange] of myself
  ]
]
; pay debt with savings
if savings > [wprice] of one-of stores and savings > mexchange[
  set fdebt fdebt - mexchange
  set savings savings - mexchange
  ask one-of farmerbanks[
    set securities securities - mexchange]
]
]
; pay debt with money
ask professionals[
  set mexchange pdebt * .05
  if money > pprice and money > mexchange [
    set pdebt pdebt - mexchange
    set money money - mexchange
    ask one-of professionalBanks [
      set securities securities - [mexchange] of myself
      set money money + [mexchange] of myself
    ]
  ]
  ; pay debt with savings
  if savings > [pprice] of one-of stores and savings > mexchange[
    set pdebt pdebt - mexchange
    set savings savings - mexchange
    ask one-of farmerbanks[
      set securities securities - mexchange]
  ]
]
end

to bankruptcy
  ;if agents insolvent, declare bankruptcy and liquidate assets
ask farmers [
  if money + savings - fdebt + produce * [pprice] of one-of stores + widget * [wprice] of one-of stores < 0 [
    ask one-of farmerBanks [
      set money money + [money] of myself
      set securities securities - [fdebt] of myself
     ; set produce produce + [produce] of myself
     ; set widget widget + [widget] of myself]
    ];    ask farmers [;      set savings savings + ([savings] of myself / ((count farmers) - 1 ))  ;      set produce produce + ([produce] of myself / ((count farmers) - 1 ));      set widget widget + ([widget] of myself / ((count farmers) - 1 )) ;]

    set money 0
    set savings 0
    set fdebt 0
    set produce 0
    set widget 0
    set bankrupt bankrupt + 1]

  ]
;]
ask professionals [


  if money + savings - pdebt + produce * [pprice] of one-of stores + widget * [wprice] of one-of stores < 0 * wealth [
    ask one-of professionalBanks [
      set money money + [money] of myself
      set securities securities - [pdebt] of myself]
 ;;     set produce produce + [produce] of myself
;;      set widget widget + [widget] of myself;;

    ask professionals [
      set savings savings + ([savings] of myself / ((count professionals) - 1 ))
      set produce produce + ([produce] of myself / ((count professionals) - 1 ))
      set widget widget + ([widget] of myself / ((count professionals) - 1 )) ]
    set money 0
    set savings 0
    set pdebt 0
    set produce 0
    set widget 0
    set bankrupt bankrupt + 1
  ]
]
end

to set-interest-rate
  ; banks want to hold some proportion of the stock of available base money
  ask farmerBanks [
    if farmer-interest-rate > .00002 and ([securities] of one-of farmerBanks) > 0 [

      if money  < .5 * sum [money] of farmers [
        set farmer-interest-rate farmer-interest-rate * 1.0000005]
      if money < .4 * sum [money] of farmers [
        set farmer-interest-rate farmer-interest-rate * 1.000001]
      if money < .2 * sum [money] of farmers [
        set farmer-interest-rate farmer-interest-rate * 1.000002]
      if money > .6 * sum [money] of farmers [
        set farmer-interest-rate farmer-interest-rate * .999995]
      if money > .65 * sum [money] of farmers [
        set farmer-interest-rate farmer-interest-rate * .999999]
      if money > .7 * sum [money] of farmers [
        set farmer-interest-rate farmer-interest-rate * .999998]


;    if (money / securities) < .1  [
;      set farmer-interest-rate farmer-interest-rate + .000001]
;    if (money / securities) < .2  [
;      set farmer-interest-rate farmer-interest-rate + .000001]
;    if (money / securities) > .5  [
;      set farmer-interest-rate farmer-interest-rate - .000001]
;    if (money / securities) < .6 [
;      set farmer-interest-rate farmer-interest-rate - .000001]
;    if (money / securities) < .7 [
;      set farmer-interest-rate farmer-interest-rate - .0001]
;    if (money / securities) < .8 [
;      set farmer-interest-rate farmer-interest-rate - .0001]

    ]
    ; rate cannot equal zero or rise above 1 percent per day
    if farmer-interest-rate = 0 [ set farmer-interest-rate .00001]
    if farmer-interest-rate > .01 [ set farmer-interest-rate .01]
  ]
  ask professionalBanks [

      if money  < .05 * sum [money] of professionals [
        set professional-interest-rate professional-interest-rate * 1.000005]
      if money < .1 * sum [money] of professionals [
        set professional-interest-rate professional-interest-rate * 1.000001]
      if money < .2 * sum [money] of professionals [
        set professional-interest-rate professional-interest-rate * 1.000002]
      if money > .5 * sum [money] of farmers [
        set professional-interest-rate professional-interest-rate * .999995]
      if money > .6 * sum [money] of farmers [
        set professional-interest-rate professional-interest-rate * .999999]
      if money > .7 * sum [money] of farmers [
        set professional-interest-rate professional-interest-rate * .999998]

;    if professional-interest-rate > .0002 and ([securities] of one-of professionalBanks) > 0 [
;    if (money / securities) < .1  [
;      set professional-interest-rate professional-interest-rate + .000001]
;    if (money / securities) < .2 [
;      set professional-interest-rate professional-interest-rate + .000001]
;   if (money / securities) > .3 [
;     set professional-interest-rate professional-interest-rate - .000001]
;    if (money / securities) < .4 [
;      set professional-interest-rate professional-interest-rate - .000001]
;    if (money / securities) < .7 [
;      set professional-interest-rate professional-interest-rate - .0001]
;    if (money / securities) < .8 [
;      set professional-interest-rate professional-interest-rate - .0001]
;    ]
    if professional-interest-rate < .0002 [ set professional-interest-rate professional-interest-rate * .00001]
    if professional-interest-rate = 0 [ set professional-interest-rate .00001]
    if professional-interest-rate > .01 [ set professional-interest-rate .01]
  ]
;

end



to compound-interest
  ask stores [
    set savings savings * (1 + professional-interest-rate )
    set pdebt pdebt * (1 + professional-interest-rate)
    set fdebt fdebt * (1 + farmer-interest-rate)
    set securities securities * (1 + professional-interest-rate) ]

  ask farmerBanks [
    set savings savings * (1 + professional-interest-rate); / 40000000)
    set pdebt pdebt * ( 1 + professional-interest-rate); / 20000000)
    set securities securities * (1 + farmer-interest-rate)]; / 20000000)]

  ask professionalBanks[
    set savings savings * (1 + farmer-interest-rate); / 40000000)
    set fdebt fdebt * (1 + (farmer-interest-rate)); / 20000000))
    set securities securities * (1 + professional-interest-rate)]; / 20000000]

  ask farmers [

      set savings savings * (1 + farmer-interest-rate); / 40000000)
      set fdebt fdebt * (1  + farmer-interest-rate); / 20000000)
    ]


    ask professionals [

        set pdebt pdebt * (1 + professional-interest-rate); / 20000000)
        set savings savings * (1 + professional-interest-rate)

    ]

end

to store-deposit

  ;;store deposits when it holds above a minimum level fo real balances

  ask stores [

;   if random 200 < 1 [
;      set withdraw savings * .2
;      set savings savings - withdraw
;      set money money + withdraw
;      ask myfarmbank [
;        set money money - .5 *[withdraw] of myself
;      ]
;      ask myprobank [
;        set money money - .5 * [withdraw] of myself
;      ]
;    ]


    ifelse random 100 < 50 and money > 5 * pprice [ ; and fdebt <= 0[
      set deposit .05 * (money - 5 * pprice)
      set money money - deposit
      set savings savings + deposit
     ask one-of farmerBanks [
        set money money + [deposit] of myself
      ]]

    [if money > 5 * wprice [; and pdebt <= 0[
      set deposit .05 * (money - 5 * wprice)
      set money money - deposit
      set savings savings + deposit
      ask one-of professionalBanks [
        set money money + [deposit] of myself
      ]]]]
end

to store-withdraw

  ; withdraw when not enough funds to by available goods

    if fbusiness = true [
    while [money < pprice * [produce] of myself  and savings >= pprice and [money] of one-of farmerBanks > pprice] [
      set withdraw pprice
      set money money + withdraw
      set savings savings - withdraw
      ask one-of farmerBanks [
        set money money - [withdraw] of myself
      ]]]

    if pbusiness = true[
     while [money < wprice * [widget] of myself and savings >= wprice and [money] of one-of professionalBanks > wprice ][
      set withdraw wprice
      set money money + withdraw
      set savings savings - withdraw
     ask one-of professionalBanks [
        set money money - [withdraw] of myself
      ]]]

      set-interest-rate
end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to withdraw-farmer-savings
  ; farmer withdraws savings when short on funds for purchase of widgets

  while [ money < ( 1 + markup) * [wprice] of one-of stores * [widget] of one-of stores and savings > ( 1 + markup) * [wprice] of one-of stores and
    [money] of one-of farmerBanks > ( 1 + markup) * [wprice] of one-of stores] [

      set withdraw ( 1 + markup) * [wprice] of one-of stores
      set money money + withdraw
      set savings savings - withdraw
      ask one-of farmerBanks[
        set money money - (1 + markup) * [wprice] of one-of stores
      ]
      ]
end
to deposit-farmer-savings
  ;deposit excess balances

  if money > [wprice] of one-of stores [            ; agents prefer to save money in bank

    set deposit (money - [wprice] of one-of stores) * .1
    set money money - deposit
    set savings savings + deposit
    ask one-of farmerBanks[
      set money money + [deposit] of myself]
  ]


  set-interest-rate
    end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to withdraw-professional-savings
    ; professional withdraws savings when short on funds for purchase of produce

  while[ money < ( 1 + markup) * [pprice] of one-of stores * [produce] of one-of stores and savings > ( 1 + markup) * [pprice] of one-of stores and
    [money] of one-of professionalBanks > ( 1 + markup) * [pprice] of one-of stores] [

      set withdraw ( 1 + markup) *  [pprice] of one-of stores
      set money money + withdraw
      set savings savings - withdraw
      ask one-of professionalBanks[
        set money money -  ( 1 + markup) * [pprice] of one-of stores
      ]
      ]
end

to deposit-professional-savings
  ;deposit excess balances
  if money > [pprice] of one-of stores [            ; agents prefer to save money in bank

    set deposit (money - [pprice] of one-of stores) * .1
    set money money - deposit
    set savings savings + deposit
    ask one-of professionalBanks[
      set money money + [deposit] of myself]
  ]


  set-interest-rate
    end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to renew-fuel
  ask farm-patches [
    if pcolor = black [
      if random-float 100 < fuel-grow-rate
        [ set pcolor green ]
    ]
  ]


  ask city-patches [
    if pcolor = yellow [
      if random-float 100 < fuel-grow-rate
        [ set pcolor red ]
    ]
  ]
end

to disaster

  ; when disaster turned on, each society faces supply shocks at some average rate
  if random 100.0 < .5 [
    ask patches [
      if pcolor = green [
        set pcolor black]
    ]
  ]


  if random 100.0 < .5 [
    ask  patches [
      if pcolor = red [
        set pcolor yellow]
    ]
  ]

;  if random 100.0 < .1 [
;  ask stores [
;    set produce produce * .1
;  ]
;  ]
;  if random 100.0 < .1 [
;    ask stores[
;      set widget widget * .1
;  ]
;  ]
;
 ; if random 100.0 < .5 [
 ;   ask farmers [
 ;     set money money + random 200]
 ;   ask professionals [
 ;     set money money + random 200]
 ; ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-macro-stats
  ask turtles [
   ; set money-multiplier (sum [money] of turtles / sum [deposit] of turtles)
    if sum [pdebt] of turtles + sum [fdebt] of turtles > 0 [
      set reserve-ratio (sum [money] of turtles) / ( sum [pdebt] of turtles + sum [fdebt] of turtles  + sum [money] of turtles)]
  ]
end

to-report average-productivity1
  ifelse count farmers > 0
    [ report mean [ productivity ] of farmers ]
    [ report 0 ]
end

to-report average-productivity2
  ifelse count professionals > 0
    [ report mean [ productivity ] of professionals ]
    [ report 0 ]
end


to updateplots
  ask turtles [
    set wealth money + savings + produce * [pprice] of one-of stores + widget * [wprice] of one-of stores - fdebt - pdebt]
  set-current-plot "professional_wealth"
  histogram [wealth] of professionals

  ;set-current-plot "farmer_wealth"
  ;histogram [wealth] of farmers

end
@#$#@#$#@
GRAPHICS-WINDOW
412
13
775
377
-1
-1
8.88
1
12
1
1
1
0
0
0
1
0
39
0
39
1
1
1
ticks
30.0

BUTTON
24
16
90
49
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
102
15
165
48
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
0

BUTTON
184
16
247
49
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

SLIDER
26
74
198
107
fuel-grow-rate
fuel-grow-rate
1
20
5.0
1
1
NIL
HORIZONTAL

SLIDER
199
140
370
173
productivity-cityworld
productivity-cityworld
.01
10
5.0
0.01
1
NIL
HORIZONTAL

SLIDER
198
107
370
140
depreciation
depreciation
0
1
0.1
.001
1
NIL
HORIZONTAL

PLOT
395
462
595
612
Farmer Wealth
NIL
NIL
0.0
10000.0
0.0
10.0
true
false
"" "set-plot-x-range 0 (max [wealth] of farmers + .0001)\nset-histogram-num-bars 10\nset-plot-pen-interval ((max [wealth] of farmers) / 10 + .0001)"
PENS
"default" 100.0 1 -16777216 true "" "histogram ([wealth] of farmers)"

PLOT
601
461
801
611
professional_wealth
NIL
NIL
-5.0
10000.0
0.0
10.0
true
false
"" "set-histogram-num-bars 10\nset-plot-x-range 0 (max [wealth] of professionals + .0001)\nset-plot-pen-interval ((max [wealth] of professionals) / 10 + .0001)"
PENS
"default" 250.0 1 -16777216 true "" ""

INPUTBOX
260
10
342
70
population
100.0
1
0
Number

MONITOR
78
341
169
386
Money at Store
sum [money] of stores
1
1
11

MONITOR
198
342
288
387
Produce at Store
sum [produce] of stores
1
1
11

PLOT
821
13
1145
175
Money
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"farmer money" 1.0 0 -16777216 true "" "plotxy ticks sum [money] of farmers"
"proMoney" 1.0 0 -7500403 true "" "plotxy ticks sum [money] of professionals"
"fBank" 1.0 0 -2674135 true "" "plotxy ticks sum [money] of farmerBanks"
"pBank" 1.0 0 -955883 true "" "plotxy ticks sum [money] of professionalBanks"
"Store" 1.0 0 -6459832 true "" "plotxy ticks sum [money] of Stores"

MONITOR
75
390
181
435
Money_Supply
sum [money] of stores +\nsum [money] of farmers +\nsum [money] of professionals +\nsum [money] of farmerBanks +\nsum [money] of professionalBanks
1
1
11

MONITOR
192
391
290
436
Total Produce
sum [produce] of stores +\nsum [produce] of farmers +\nsum [produce] of professionals
1
1
11

MONITOR
13
215
121
260
Money Farmers
sum [money] of farmers
1
1
11

MONITOR
9
271
142
316
Money Professional
sum [money] of professionals
1
1
11

MONITOR
209
436
342
481
Wealth Professional
sum [money] of professionals +\nsum [produce] of professionals * [pprice] of one-of stores +\nsum [widget] of professionals * [wprice] of one-of stores  +\nsum [savings] of professionals -\nsum [pdebt] of professionals
1
1
11

MONITOR
289
342
384
387
Widgets at Store
sum [widget] of stores
1
1
11

MONITOR
68
435
206
480
Wealth Farmer
sum [money] of farmers +\nsum [produce] of farmers * [pprice] of one-of stores +\nsum [widget] of farmers * [wprice] of one-of stores +\nsum [savings] of farmers -\nsum [fdebt] of farmers
1
1
11

MONITOR
286
390
383
435
Total Widget
sum [widget] of stores +\nsum [widget] of farmers +\nsum [widget] of professionals
1
1
11

PLOT
820
339
1144
489
Store Inventory
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"produce" 1.0 0 -16777216 true "" "plotxy ticks sum [produce] of stores"
"widget" 1.0 0 -7500403 true "" "plotxy ticks sum [widget] of stores"
"money" 1.0 0 -2674135 true "" "plotxy ticks sum [money] of stores"
"debt" 1.0 0 -955883 true "" "plotxy ticks (sum [pdebt] of stores + sum [fdebt] of stores)"
"savings" 1.0 0 -6459832 true "" "plotxy ticks sum [savings] of stores"

SLIDER
26
142
199
175
productivity-farmerworld
productivity-farmerworld
0.01
10
5.0
.01
1
NIL
HORIZONTAL

MONITOR
123
215
223
260
Bank Deposits
sum [savings] of turtles
1
1
11

PLOT
-6
523
395
673
Prices
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"produce" 1.0 0 -16777216 true "" "plotxy ticks median [pprice] of stores"
"widgets" 1.0 0 -7500403 true "" "plotxy ticks  median [wprice] of stores"

MONITOR
226
216
380
261
Loans
sum [fdebt] of turtles + sum [pdebt] of turtles
2
1
11

PLOT
829
667
1230
817
Interest Rates
NIL
NIL
0.0
1.0
0.0
5.0E-4
true
true
"" ""
PENS
"professional rate" 1.0 0 -7500403 true "" "plotxy ticks [professional-interest-rate] of one-of professionalBanks"
"farmer rate" 1.0 0 -2674135 true "" "plotxy ticks [farmer-interest-rate] of one-of farmerBanks"

PLOT
2
678
393
828
Debt
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Farmer" 1.0 0 -16777216 true "" "plotxy ticks sum  [fdebt] of farmers"
"Professional" 1.0 0 -7500403 true "" "plotxy ticks sum [pdebt] of professionals"
"Stores" 1.0 0 -2674135 true "" "plotxy ticks [fdebt] of one-of stores + [pdebt] of one-of stores"
"Farmer Bank" 1.0 0 -955883 true "" "plotxy ticks sum [pdebt] of farmerBanks"
"Professional Bank" 1.0 0 -6459832 true "" "plotxy ticks sum [fdebt] of professionalBanks"

PLOT
11
838
333
988
Savings
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Farmers" 1.0 0 -16777216 true "" "plot (sum [savings] of farmers)"
"Professionals" 1.0 0 -7500403 true "" "plot (sum [savings] of professionals)"

PLOT
394
767
808
917
M1
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
"default" 1.0 0 -16777216 true "" "plot (sum [money] of turtles + sum [fdebt] of turtles + sum [pdebt] of turtles)"

PLOT
828
826
1238
984
Relative Price of Produce
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
"default" 1.0 0 -16777216 true "" "plot ([pprice] of one-of stores) / ([wprice] of one-of stores)"

PLOT
1144
17
1517
181
Farmer and Professional Stocks
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"farmer produce" 1.0 0 -16777216 true "" "plot sum [produce] of farmers"
"farmer widgets" 1.0 0 -7500403 true "" "plot sum [widget] of farmers"
"professional produce" 1.0 0 -2674135 true "" "plot sum [produce] of professionals"
"professional widgets" 1.0 0 -955883 true "" "plot sum [widget] of professionals"

PLOT
814
986
1240
1163
Sale and Purchase Prices (store)
NIL
NIL
0.0
10.0
0.0
1.0
true
true
"" ""
PENS
"Produce Purchase" 1.0 0 -16777216 true "" "plotxy ticks median [produce-purchaseprice] of  stores"
"Produce Sale" 1.0 0 -7500403 true "" "plotxy ticks median [produce-saleprice] of  stores"
"Widget Purchase" 1.0 0 -2674135 true "" "plotxy ticks median [widget-purchaseprice] of  stores"
"Widget Sale" 1.0 0 -955883 true "" "plotxy ticks median [widget-saleprice] of  stores"

MONITOR
387
407
515
452
Produce Price
[pprice] of stores
1
1
11

MONITOR
516
408
648
453
Widget Price
[wprice] of stores
3
1
11

PLOT
1156
194
1518
344
Total Widgets and Produce
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Produce" 1.0 0 -16777216 true "" "plot  sum [produce] of turtles"
"Widgets" 1.0 0 -7500403 true "" "plot  sum [widget] of turtles"

MONITOR
649
409
819
454
Relative Produce Price (in widgets)
[pprice] of one-of stores / [wprice] of one-of stores
17
1
11

PLOT
8
1002
332
1152
Base Money
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
"default" 1.0 0 -16777216 true "" "plot sum [money] of turtles"

MONITOR
1127
720
1277
765
Farmer Rate
[farmer-interest-rate] of one-of farmerBanks
17
1
11

MONITOR
1128
767
1282
812
NIL
[professional-interest-rate] of one-of professionalBanks
17
1
11

PLOT
1160
353
1520
503
Store Supplies
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Produce" 1.0 0 -16777216 true "" "plotxy ticks sum [produce] of stores"
"Widgets" 1.0 0 -7500403 true "" "plotxy ticks sum [widget] of stores"

SLIDER
24
175
196
208
produce-supply-level
produce-supply-level
0
30
20.0
1
1
NIL
HORIZONTAL

SLIDER
202
177
374
210
widget-supply-level
widget-supply-level
0
30
20.0
1
1
NIL
HORIZONTAL

SLIDER
200
76
372
109
markup
markup
0
1
1.0
.01
1
NIL
HORIZONTAL

PLOT
820
491
1144
641
Store Wealth
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
"default" 1.0 0 -16777216 true "" "plotxy ticks [wealth] of one-of stores"

PLOT
395
613
807
763
Nominal Income
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
"default" 1.0 0 -16777216 true "" "plotxy ticks (sum [widget] of turtles * [wprice] of one-of stores + sum [produce] of turtles * [pprice] of one-of stores)"

PLOT
392
925
806
1075
Real Income
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
"default" 1.0 0 -16777216 true "" "plotxy ticks (sum [produce] of turtles + sum [widget] of turtles)"

MONITOR
811
179
937
224
Farmer Bankruptcies
sum [bankrupt] of farmers
17
1
11

MONITOR
941
179
1095
224
Professinoal Bankruptcies
sum [bankrupt] of professionals
17
1
11

PLOT
390
1087
803
1237
Worker Income
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
"default" 1.0 0 -16777216 true "" "plotxy ticks (sum [wealth] of farmers + sum [wealth] of professionals)"

@#$#@#$#@
## WHAT IS IT?

The netLogo model Artificial Economy simulate a simple economy. Agents are one of two breed, farmers or professionals. Farmers produce produe and professionals produce widgets.

## HOW IT WORKS

Farmers and professionals are given an initial productivity of one. Productivity is augmented as farmers collect widgets and as professionals collect produce. Productivity levels are determined by a Cobb-Douglas production function:

TP = L^(1/2)K^(1/2) where L = 1

Each agent has one labor which is aided by labor augmenting technology - widgets for farmers and produce for professionals.

When an agent produces a sufficient amount of their indigenous good, he sells his goods to the store. The store then resells the item at a markup.

Agents may run low on funds. If the agent has other assets, he can leverage the assets in order to borrow money. If the agent becomes insolvent, his money is given to the bank and resources are returned to the community. The store can also borrow. When the store becomes insolvent, this tends to slow the entire economy.

## HOW TO USE IT

The user can change some parameters by using the interface.

fuel-growth-rate: This sets the average period of time required for patches to replenish. If the rate is high, regrow time is short. If it is low, regrow time takes longer.

markup: The percent that the store marksup the price of a good over the store's purchase price.

depreciation: Sets the rate at which productive capital depreciates.

productivity-farmer-world: Sets base productivity of farmers.

productivity-professional-world: Sets base productivity for professionals.

produce-supply-level: Sets the store's inventory level for produce.

widget-supply-level: Sets the store's inventory level for widgets.

## THINGS TO NOTICE

The model exhibits some basica economic principles. Prices change to reflect scarcity. As goods become more expensive, budget constrained agents must purchase less goods. When agents run low on money, they can borrow from the local bank if they have collateral.

The wealth distribution in this model tends to follow a power-law distribution, with only a small few holding a large portion of society's wealth.

Relative prices usually, though not always, stay within a tight range between 1 and 10.

## THINGS TO TRY

The model has a vast behavior space. Try changiing the markup at a some level of productivity. Then adjust the productivity level once you've gotten a feel for the effects of the price markup.

## EXTENDING THE MODEL

Further work might include implementing labor mobility (already coded). Allowing labor to move as prices change help stabilize the system.

Allowing for trade between individual agents may also help stabilize the system, particular during times when credit is dear. 

The interest rate moves, but does not appear to be very functional in allocation credit. This might be improved.


## RELATED MODELS

While this model was built from the ground up, it resembles sugarscape in some respects.
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

bank
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

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

computer
false
0
Rectangle -7500403 true true 60 45 240 180
Polygon -7500403 true true 90 180 105 195 135 195 135 210 165 210 165 195 195 195 210 180
Rectangle -16777216 true false 75 60 225 165
Rectangle -7500403 true true 45 210 255 255
Rectangle -10899396 true false 249 223 237 217
Line -16777216 false 60 225 120 225

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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

person business
false
0
Rectangle -1 true false 120 90 180 180
Polygon -13345367 true false 135 90 150 105 135 180 150 195 165 180 150 105 165 90
Polygon -7500403 true true 120 90 105 90 60 195 90 210 116 154 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 183 153 210 210 240 195 195 90 180 90 150 165
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 76 172 91
Line -16777216 false 172 90 161 94
Line -16777216 false 128 90 139 94
Polygon -13345367 true false 195 225 195 300 270 270 270 195
Rectangle -13791810 true false 180 225 195 300
Polygon -14835848 true false 180 226 195 226 270 196 255 196
Polygon -13345367 true false 209 202 209 216 244 202 243 188
Line -16777216 false 180 90 150 165
Line -16777216 false 120 90 150 165

person farmer
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -13345367 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -6459832 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -6459832 true false 240 90 255 300

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

store
false
0
Rectangle -7500403 true true 30 45 45 240
Rectangle -16777216 false false 30 45 45 165
Rectangle -7500403 true true 15 165 285 255
Rectangle -16777216 true false 120 195 180 255
Line -7500403 true 150 195 150 255
Rectangle -16777216 true false 30 180 105 240
Rectangle -16777216 true false 195 180 270 240
Line -16777216 false 0 165 300 165
Polygon -7500403 true true 0 165 45 135 60 90 240 90 255 135 300 165
Rectangle -7500403 true true 0 0 75 45
Rectangle -16777216 false false 0 0 75 45

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
  <experiment name="Array 1" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <metric>[pprice] of one-of stores</metric>
    <metric>[wprice] of one-of stores</metric>
    <metric>sum [wealth] of farmers</metric>
    <metric>sum [wealth] of professionals</metric>
    <metric>sum [produce] of farmers</metric>
    <metric>sum [widget] of farmers</metric>
    <metric>sum [produce] of professionals</metric>
    <metric>sum [widget] of professionals</metric>
    <metric>sum [produce] of turtles</metric>
    <metric>sum [widget] of turtles</metric>
    <metric>sum [bankrupt] of farmers</metric>
    <metric>sum [bankrupt] of professionals</metric>
    <metric>sum [money] of turtles</metric>
    <metric>sum [savings] of turtles</metric>
    <metric>sum [pdebt] of turtles</metric>
    <metric>sum [fdebt] of turtles</metric>
    <metric>sum [fdebt + pdebt] of turtles</metric>
    <metric>[fdebt] of one-of stores</metric>
    <metric>[pdebt] of one-of stores</metric>
    <metric>sum [fdebt] of farmers</metric>
    <metric>sum [pdebt] of professionals</metric>
    <metric>sum [securities] of farmerbanks</metric>
    <metric>sum [securities] of professionalbanks</metric>
    <metric>sum [securities] of turtles</metric>
    <metric>[farmer-interest-rate] of one-of farmerbanks</metric>
    <metric>[professional-interest-rate] of one-of professionalbanks</metric>
    <enumeratedValueSet variable="markup">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productivity-farmerworld">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="widget-price-control?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="productivity-cityworld">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="depreciation">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="produce-supply-level">
      <value value="15"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="population">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="widget-supply-level">
      <value value="15"/>
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="produce-price-control?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fuel-grow-rate">
      <value value="5"/>
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
