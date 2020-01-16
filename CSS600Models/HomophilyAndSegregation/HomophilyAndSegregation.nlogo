;;; Defining globals in addition to the additional to be used by various functions

globals [

  percent-similar-d1  ;; on the average, what percent of a turtle's neighbors
                     ;; are the same color as that turtle?
  percent-similar-d2
  percent-similar-d3
  percent-similar

  percent-unhappy  ;; what percent of the turtles are unhappy?

  percent-happy

  happy-energy     ;; Defined a global variable for observer plots/view

  sad-energy       ;; Defined a global variable for observer plots/view

  tick-count
]

;;; We gave each turtle a number of variables including wealth, color and shape - all of them are initialized randomly. We substituted
;;; the similarity/homophily attribute with sad and happy points (think energy) in order to simulate a propinquity, and social similarity network effect.
;;; The sad or happy energy points are divided into d1, d2, and d3, where d stands for distance from original turtle
;;; We also created a new happiness variable (happiness instead of happy) which is calculated based on those energy points.
;;; d1 = neiighborhood
;;; d2 = all patches at distance = 2
;;; d3 all patches at distance = 3

turtles-own [
  happy?           ;; for each turtle, indicates whether at least %-similar-wanted percent of
                   ;;   that turtles' neighbors are the same color as the turtle
  similar-nearby-d1   ;; how many neighboring patches have a turtle with my color on neighborhood?
  similar-nearby-d2   ;; how many neighboring patches have a turtle with my color on d2
  similar-nearby-d3   ;; how many neighboring patches have a turtle with my color on d3
  similar-nearby

  other-nearby-d1
  other-nearby-d2
  other-nearby-d3
  other-nearby     ;; how many have a turtle of another color?

  total-nearby     ;; sum of previous two variables
  similar-nearby-test ;; Defined as a turtle property

  wealth
  d1-happy-points
  d1-sad-points
  d1-total-points

  d2-happy-points
  d2-sad-points
  d2-total-points
  d3-happy-points
  d3-sad-points
  d3-total-points


  total-points
  happiness?
  d2
  d3


]

;;cleaned up the setup function to be simpler than the original model behavior

to setup

  clear-all
  create
  update-variables
  reset-ticks
end

;; runs the model for one tick

to create    ;; create turtles on random patches.

  ask patches [
    if random 100 < density [   ;; set the occupancy density

      sprout 1 [ set color one-of [red white blue ] ;; two colors set randomly
      set shape one-of [  "circle" "triangle" ] ;; two shapes set randomly
      set size  0.75 ;; set the original size to be 0.75 as a default. In our model size will reflect whether a turtle is happy or not, but initially all wil be set at 0.75.
      set wealth one-of [ 0 1] ;; set wealth to be either great or low (1 or 0) also set randomly. This could've been any other variable but we wanted to add a third possible distinction.
    ]]]
end


to go ;; cleaned up go function

  if all? turtles [ happiness? ] [ stop ] ;;; using newly defined happiness variable instead of happy variable
  move-unhappy-turtles
  update-variables
  set tick-count tick-count + 1
  tick
end

;; unhappy turtles try a new spot. This method is unchanged but could be modified in the future to see the effects of different moving behaviors.

to move-unhappy-turtles
  ask turtles with [ not happiness? ]
    [ find-new-spot ]
end

;; Move until we find an unoccupied spot. Also, unmodified. We will modify for future projects.
to find-new-spot
  rt random-float 360
  fd random-float 10
  if any? other turtles-here [ find-new-spot ] ;; keep going until we find an unoccupied patch
  move-to patch-here  ;; move to center of patch
end

to update-variables ;; update all the variables. Used in the tick/update function.
  update-turtles
  update-globals
end


to visualize                                            ;; We used the visualize function very differently by using the square-x tag to set the size of the turtles to be very small (0.5) when they're unhappy
                                                        ;; and 1.0 when they are. This also made for a way to visually detect if our model was working correctly. We could not use the original method since we've expanded
    if visualization = "old" [ set shape "default" ]    ;; to the use of shapes, and we needed a method that could be expanded to more than 2 shapes and colors without difficulty (scalable)
    if visualization = "new" [
    ifelse happiness? [ set size 1 ] [ set size 0.5 ]]

end




;; the updating turtles function was completely re-written to reflect the proposed social selection, and propinquity effects. Instead of coding a network we simulated a networko effect using energy points (happy and sad)
;;; we aimed for a power law reflection of propinquity as found in literature through the use of a rule system. We also manually coded the d2 and d3 distances as it was not clear if there was a native function to implement this.
;;; for a better exlanation see paper, and psuedocode document
to update-turtles

  ask turtles [

    set d2 turtles-on patches at-points [ [2 0] [2 1] [2 2] [0 2] [ 1 2 ]  [-2 0] [-2 1] [-2 2] [0 -2] [-1 2] [-1 -2] [-2 -2] [-2 -1] [1 -2] [2 -2] [2 -1] ] ;;; coordinates for all patches at diatance=2 from a given turtle
    set d3 turtles-on patches at-points [ [ -3 3] [-2 3] [-1 3] [0 3] [1 3] [2 3] [ 3 3] [3 2] [3 1] [3 0] [ 3 -1] [3 -2] [3 -3] [2 -3] [1 -3] [0 -3] [-1 -3] [-2 -3] [-3 -3] [-3 -2] [-3 -1] [-3 0] [-3 1] [-3 2] ] ;;; coordinates for all patched at distance = 3 of turtle

    similarity-functions


    set d1-happy-points ((count (turtles-on neighbors)  with [ color = [ color ] of myself and shape = [ shape ] of myself and wealth = [ wealth ] of myself]) - 1 ) * 9

    ;; (for above line) Calculate thge total happy points experienced by central turtle from neighborhood, and since our turtle can see all 3 attributes at d=1 (neighborhood) and they have a stronger effect on it we multiplied by 9 ( 3 x 3)
    ;; the -1 is to control for turtles finding similarity with themselves

    set d1-happy-points (d1-happy-points + ((count (turtles-on neighbors)  with [ color = [ color ] of myself and shape = [ shape ] of myself and wealth != [ wealth ] of myself]) - 1) * 6)
    set d1-happy-points (d1-happy-points + ((count (turtles-on neighbors)  with [ color = [ color ] of myself and shape != [ shape ] of myself and wealth = [ wealth ] of myself]) - 1) * 6)
    set d1-happy-points (d1-happy-points + ((count (turtles-on neighbors)  with [ color != [ color ] of myself and shape = [ shape ] of myself and wealth = [ wealth ] of myself]) - 1) * 6)

    ;; (for above 3 lines) Also acting on neighborhood turtles but for when 2 attributes are the same and 1 is different.


    set d1-sad-points (count ((turtles-on neighbors) with [ color = [ color ] of myself and shape != [ shape ] of myself and wealth != [ wealth ] of myself]) - 1) * -6
    set d1-sad-points (d1-sad-points - (count ((turtles-on neighbors) with [ color != [ color ] of myself and shape != [ shape ] of myself and wealth = [ wealth ] of myself]) - 1) * -6)
    set d1-sad-points (d1-sad-points - (count ((turtles-on neighbors) with [ color = [ color ] of myself and shape != [ shape ] of myself and wealth != [ wealth ] of myself]) - 1) * -6)

    ;; (for above 3 lines) Also acting on neighborhood turtles but for when 2 attributes are not the same and 1 is the same.


    set d1-sad-points ( d1-sad-points - (count ((turtles-on neighbors) with [ color != [ color ] of myself and shape != [ shape ] of myself and wealth != [ wealth ] of myself]) - 1) * -9)

    ;; (for above 1 line) Also acting on neighborhood turtles but for when all attributes are different.


    set d2-happy-points (count (turtles-on d2) with [ color = [ color ] of myself and shape = [  shape ] of myself ] - 1) * 4
    ;;omitting (shape != shape and color == color AND shape == shape and color != color) because they will create a net zero energy
    set d2-sad-points (count (turtles-on d2) with [ color != [ color ] of myself and shape != [  shape ] of myself ] - 1) * -4

    ;; (for above 2 lines) This is set is when the positive and negative selection forces are acting on d=2 so they are less potent (hence the multiplier is lower) and at d=2 turtles can only see two attributes

    set d3-happy-points count (turtles-on d3) with [color = [ color ] of myself ] - 1
    set d3-sad-points (count (turtles-on d3) with [color != [ color ] of myself] - 1) * -1

    ;; (for above 2 lines) This is set is when the positive and negative selection forces are acting on d=3 which is the weakest acting forces on origin turtle. Also only 2 conditions since turtles can only "see" one attribute at this distance.


    set d1-total-points d1-happy-points + d1-sad-points
    set d2-total-points d2-happy-points + d2-sad-points
    set d3-total-points d3-happy-points + d3-sad-points

    set total-points d1-total-points + d2-total-points + d3-total-points

    set happy-energy d1-happy-points + d2-happy-points + d3-happy-points
    set sad-energy d1-sad-points + d2-sad-points + d3-sad-points

    ;;;Adding up all the negative and positve energy points

    set happiness? total-points >= (Hetero-Homo-scale * total-points / 100)

    ;;comparison to wanted homogeneity or heterogeneity

    visualize
  ]


end

to similarity-functions

    set d2 turtles-on patches at-points [ [2 0] [2 1] [2 2] [0 2] [ 1 2 ]  [-2 0] [-2 1] [-2 2] [0 -2] [-1 2] [-1 -2] [-2 -2] [-2 -1] [1 -2] [2 -2] [2 -1] ] ;;; coordinates for all patches at diatance=2 from a given turtle
    set d3 turtles-on patches at-points [ [ -3 3] [-2 3] [-1 3] [0 3] [1 3] [2 3] [ 3 3] [3 2] [3 1] [3 0] [ 3 -1] [3 -2] [3 -3] [2 -3] [1 -3] [0 -3] [-1 -3] [-2 -3] [-3 -3] [-3 -2] [-3 -1] [-3 0] [-3 1] [-3 2] ] ;;; coordinates for all patched at distance = 3 of turtle

    set similar-nearby-d1 (count (turtles-on neighbors)  with [ color = [ color ] of myself or shape = [ shape ] of myself or wealth = [ wealth ] of myself ] ) ;; old code left for comparison and testing changed to include new factors
    set similar-nearby-d2 (count (turtles-on d2)  with [ color = [ color ] of myself or shape = [ shape ] of myself ]) ;; old code left for comparison and testing changed to include new factors
    set similar-nearby-d3 (count (turtles-on d3)  with [ color = [ color ] of myself ]) ;; old code left for comparison and testing changed to include new factors

    set similar-nearby similar-nearby-d1 + similar-nearby-d2 + similar-nearby-d3


    set other-nearby-d1 (count (turtles-on neighbors) with [ color != [ color ] of myself or shape != [ shape ] of myself or wealth != [ wealth ] of myself ])     ;; old code left for comparison and testing changed to inlclude new factors
    set other-nearby-d2 (count (turtles-on d2) with [ color != [ color ] of myself or shape != [ shape ] of myself ])
    set other-nearby-d3 (count (turtles-on d3) with [ color != [ color] of myself ] )

    set other-nearby other-nearby-d1 + other-nearby-d2 + other-nearby-d3

    set total-nearby similar-nearby + other-nearby                                          ;; old code left for comparison and testing
    ;;set happy? similar-nearby >= (%-similar-wanted * total-nearby / 100)                    ;; old code left for comparison and testing
end

;;;Below function is for outputs.

to update-globals
  let similar-neighbors sum [ similar-nearby ] of turtles
  let total-neighbors sum [ total-nearby ] of turtles
  set percent-similar (similar-neighbors / total-neighbors) * 100
  set percent-happy ((count turtles with [ happiness? = True ]  / count turtles) * 100)
  set percent-unhappy ((count turtles with [ not happiness? ]) / (count turtles) * 100)
end
@#$#@#$#@
GRAPHICS-WINDOW
640
17
1396
774
-1
-1
14.67
1
10
1
1
1
0
1
1
1
-25
25
-25
25
1
1
1
ticks
30.0

MONITOR
466
10
541
55
% similar
percent-similar
1
1
11

PLOT
18
197
329
399
Percent Similar
time
%
0.0
5.0
0.0
100.0
true
false
"" ""
PENS
"percent" 1.0 0 -2674135 true "" "plot percent-similar"

SLIDER
11
45
271
78
Hetero-Homo-scale
Hetero-Homo-scale
-100
100
0.0
1
1
NIL
HORIZONTAL

BUTTON
12
10
92
43
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
191
10
271
43
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

BUTTON
96
11
186
45
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

CHOOSER
285
11
441
56
visualization
visualization
"old" "new"
1

SLIDER
14
82
271
115
density
density
5
99
75.0
1
1
NIL
HORIZONTAL

PLOT
19
398
327
616
Percent (Unhappy/Red - Happy/Green)
Time
Percentage (%)
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"pen-0" 1.0 0 -2674135 true "" "plot percent-unhappy"
"pen-1" 1.0 0 -11085214 true "" "plot percent-happy"

MONITOR
558
10
624
55
# agents
count turtles
1
1
11

MONITOR
313
131
394
176
Sad (Total) NM
count turtles with [not happiness?]
17
1
11

MONITOR
211
131
311
176
Happy (Total)  NM
count turtles with [happiness?]
17
1
11

MONITOR
110
132
208
177
 Unhappy (%) NM
percent-unhappy
0
1
11

MONITOR
15
132
108
177
Happy (%) NM
percent-happy
0
1
11

PLOT
329
195
625
397
Happy & Sad Energy (cumulative)
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
"default" 1.0 0 -16777216 true "" "plot sum [happy-energy] of turtles"
"pen-1" 1.0 0 -2674135 true "" "plot sum [sad-energy] of turtles"

MONITOR
287
63
374
108
Turns
tick-count
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model examines the pattern formation of urban housing structures based on the homophily mechanism of searching social similarity, proximity, and propinquity. In this model every agent has three characteristics, which are presented as color, shape, and wealth. The agents’ preferences of searching neighborhood and selecting houses are based on their tendencies to social similarities while simultaneously avoiding dissimilarities.These three characteristics are separate and distinctive preferences that affects the residential structure.

Agents get information about each other through interactions in time and space. Spatial distance is a factor that affects the knowledge of agents and consequently their selections. The distance of agents from each other are presented at three equal length spaces, which increases from d1 to d3.  From high distance (d3) agents just are able to see the color of other agents and selection is based on color similarity and dissimilarity. From a closer distance (d 2) they see both color and shape and from the least distance (d1) they can see color, shape, and wealth.Therefore, in a closer distance, the neighborhod status are formed based on a combinaiton of three preferences.

Here proximity plays the role of social constrain and changes the homophility from choice to induce.  In other words, proximity magnifies similarity and dissimilarity; therefore, the similar agents in closer distance gets more points than those are in the least distance because of their higher knowledge from each other. It is the same for the negative points that closer agents receive for their dissimilarity in compare to the dissimilar agents in the farther distance. Thus, by decreasing spatial distances the agents' local awareness increases and agents continue to search for higher social similarity and stronger avoidance of social dissimilarity.  It means that  propinquity affects more knowledge based housing selection and stronger segregation will occur in longer period of time.

## HOW TO USE IT

Click the SETUP button to set up the agents. There are approximately equal numbers of egents regarding their characteristics: color, shape, and wealth. The agents are set up so no patch has more than one agent.  Click GO to start the simulation. Agents enter the space randomly. Based on their distances from each other, they recieve inforamtion about their similarities and dissimilarities. Their decisions to select neighborhood is based on the Happiness points, which are calculated both happy and sad points.

The %similar-wanted slider controls the percentage of happiness based on three preferences within proximity. This percentage calculates a combinaiton of similarities (positive homophily as happy-points) and dissimilarities (negative homophily as sad-points) considering the distance-based knowledge that agents receive from each other.


The density slider controls the occupancy density of the neighborhood (and thus the total number of agents). (It takes effect the next time you click SETUP.)



## THINGS TO NOTICE

This housing selection model is based on Schelling's original model, which is designed just for one preferences and one distance.  This model takes into account three preferences, both positive and negative, in combination of proximity and propinquity.

## THINGS TO TRY

Try different values for %similar-wanted. How does the overall degree of segregation change?

If each agent wants at least 40% similatiry neighbors, what percentage (on average) do they end up with?

Try different values of density. How does the initial occupancy density affect the percentage of unhappy agents? How does it affect the time it takes for the model to finish?

Can you set sliders so that the model never finishes running, and agents keep looking for new locations?

## EXTENDING THE MODEL

This model was extended in two ways of conceptual and programing:
I. Conceptual:
	1) The agents have more than one preferences.
	2) The agents consider their preferences not only based on their similarities but 	also their dissimilarities.
	3) The knowledge of agents increas as their distances decrease.
	4) The happiness of agents is calculated based on both similarity (happy-points) 		and dissimilarity (sad-points)
	4) The propinquity affects the strength of the relationships and stablizes the 			housing structure

Programing:
	1) neighbors are assigned in three distance- based neighborhood: d1, d2, and d3
	2) calculation of total happiness of each agent considering the number of happy 		-points and sad- points that each agent receives according to her distance.  			Agents search for selecting neighborhood to satisfy their similarity within a 			combination of three preferences and avoid any dissimilarity. Therefore, the 			agents gets %100 happiness with a neighborhood where all agents meet three 			preferences together without any dissimilar agent in their three distance 			lengths.

	While, agents receive full happy points for seeing agents with their full 			similarity, they receive full sad points if they see agents without their full 			similarity. At the same time, when agents see agents with two similar 				characteristics it adds to their happy points but with different weight. It is 			the same for the sad points, meaning that if they see agents with two or one 			dissimilarities they receive sad points with different weight. The total and 			happy points for each agent are calculated as happy-points plus sad-points. These 	points are the distance-based calculations for each “d1”, “d2”, and “d3”, and 			final points for each agent are total points at d1+d2+d3.

	Each agent receives the happy and sad points based on her distance as follows:
	"d1": Total number of  agents with three preferences (minus the agent herself) 			multiplies 9 (happy points) + total number of agents without three preferences 			(minus the agent herself) multiplies – 9  (sad- points) + total number of agents 		with two specific preferences (minus the agent herself) multiplies 6 				(happy-points) + total number of agents without two specific preferences (minus 		the agent herself) multiplies -6(sad-points) + total number of agents with one 			specific preferences (minus the agent herself) multiplies 1 (happy-points) + 			total number of agents without one specific preferences (minus the agent herself) 	multiplies -1 (sad-points)
	“d2”: total number of agents with two specific preferences (minus the agent 			herself) multiplies 6(happy-points) + total number of agents without two specific 	preferences (minus the agent herself) multiplies -6(sad-points) + total number of 	agents with one specific preferences (minus the agent herself) multiplies 1 			(happy-points) + total number of agents without one specific preferences (minus 		the agent herself) multiplies -1 (sad-points)
	"d3": total number of agents with one specific preferences (minus the agent 			herself) multiplies 1 (happy-points) + total number of agents without one 			specific preferences (minus the agent herself) multiplies -1 (sad-points)


## NETLOGO FEATURES

`sprout` is used to create agents while ensuring no patch has more than one agent on it.

When an agent moves, `move-to` is used to move the agent to the center of the patch it eventually finds.

Note two different methods that can be used for find-new-spot, one of them (the one we use) is recursive.

## CREDITS AND REFERENCES

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.

See also a recent Atlantic article:   Rauch, J. (2002). Seeing Around Corners; The Atlantic Monthly; April 2002;Volume 289, No. 4; 35-48. http://www.theatlantic.com/issues/2002/04/rauch.htm

Borgatti, S. P., & Cross, R. (2003). A relational view of information seeking and learning in social networks. Management Science. doi:10.1287/mnsc.49.4.432.14428

Cross, R., & Borgatti, S. P. (2004). The ties that share: Relational characteristics that facilitate information seeking. Social Capital and Information Technology.

Ibarra, H., & Andrews, S. B. (1993). Power, social influence, and sense making: Effects of network centrality and proximity on employee perceptions. Administrative Science Quarterly, 38(2), 277. doi:10.2307/2393414

Kadushin, C. (2004). Introduction to Social Network Theory. Networks. doi:10.1007/978-1-4614-2254-9

McFarland, D. A., Jurafsky, D., & Rawlings, C. (2013). Making the Connection: Social Bonding in Courtship Situations. American Journal of Sociology, 118(6), 1596–1649. doi:10.1086/670240

McPherson, M., Smith-Lovin, L., & Cook, J. M. (2001). Birds of a Feather: Homophily in Social Networks. Annual Review of Sociology, 27(1), 415–444. doi:10.1146/annurev.soc.27.1.415

Reagans, R. (2011). Close Encounters: Analyzing How Social Similarity and Propinquity Contribute to Strong Network Connections. Organization Science, 22(4), 835–849. doi:10.1287/orsc.1100.0587



## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (1997).  NetLogo Segregation model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
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

face-happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face-sad
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

person2
false
0
Circle -7500403 true true 105 0 90
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 285 180 255 210 165 105
Polygon -7500403 true true 105 90 15 180 60 195 135 105

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

square - happy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 75 195 105 240 180 240 210 195 75 195

square - unhappy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 60 225 105 180 195 180 240 225 75 225

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

square-small
false
0
Rectangle -7500403 true true 45 45 255 255

square-x
false
0
Rectangle -7500403 true true 30 30 270 270
Line -16777216 false 75 90 210 210
Line -16777216 false 210 90 75 210

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

triangle2
false
0
Polygon -7500403 true true 150 0 0 300 300 300

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
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <metric>count turtles</metric>
    <metric>percent-unhappy</metric>
    <metric>percent-happy</metric>
    <metric>percent-similar</metric>
    <metric>happy-energy</metric>
    <metric>sad-energy</metric>
    <enumeratedValueSet variable="density">
      <value value="1"/>
      <value value="20"/>
      <value value="40"/>
      <value value="60"/>
      <value value="80"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Hetero-Homo-scale">
      <value value="-100"/>
      <value value="25"/>
      <value value="100"/>
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
