breed [stationery-vendors stationery-vendor]
breed [mobile-vendors mobile-vendor]
breed [customers customer]
breed [storeowners storeowner]
breed [police-officers police-officer]
breed [trees tree]

customers-own [goal destination dwell-time time-spent is-vendor-shopping vendor-shopping-time]
stationery-vendors-own [product-type]
mobile-vendors-own [product-type is-serving serve-time sales-count happiness]
storeowners-own [ frustration]
police-officers-own [ patrol-points current-target]

globals [ mobile-threshold-counter vendors-switched avg-vendor-happiness avg-storeowner-frustration]

;================================================= SET UP PROCEDURES =================================================

to setup
  clear-all
  setup-market
  setup-custom-roads
  setup-sidewalks
  setup-grocery
  setup-clothing
  setup-storeowners
  setup-customers
  setup-stationery-vendors
  setup-mobile-vendors
  setup-police-officers
  setup-homes
  setup-trees
  reset-ticks
end

to setup-market
  ;; Orange market in bottom-left corner
  ask patches with [
    pxcor >= min-pxcor and pxcor < min-pxcor + 10 and
    pycor >= min-pycor and pycor < min-pycor + 10
  ] [
    set pcolor orange
  ]

  ;; Adding a 3-patch widr road above market
  ask patches with [
    pxcor >= min-pxcor and pxcor < min-pxcor + 10 and
    pycor >= min-pycor + 10 and pycor <= min-pycor + 12
  ] [
    set pcolor gray
  ]
end

to setup-grocery
  ;; green grocery market in top-right corner
  ask patches with [
    pxcor >= max-pxcor - 9 and pxcor < max-pxcor + 1 and
    pycor >= max-pycor - 13 and pycor < max-pycor - 2
  ] [
    set pcolor green
  ]
end

to setup-clothing
  ;; turquoise grocery market in bottom-right corner
  ask patches with [
    pxcor >= max-pxcor - 9 and pxcor < max-pxcor + 1 and
    pycor >= min-pycor and pycor < min-pycor + 14
  ] [
    set pcolor turquoise
  ]
end

to setup-storeowners
  ;; Grocery storeowner (green patch)
  let grocery-patch one-of patches with [pcolor = green]
  if grocery-patch != nobody [
    ask grocery-patch [
      sprout-storeowners 1 [
        set shape "person"
        set color green + 2  ;; different shade to differentiate from patches
        set frustration 0
        set label "Grocery Owner"
      ]
    ]
  ]

  ;; Clothing storeowner (turquoise patch)
  let clothing-patch one-of patches with [pcolor = turquoise]
  if clothing-patch != nobody [
    ask clothing-patch [
      sprout-storeowners 1 [
        set shape "person"
        set color turquoise + 2  ;; same thing as above :)
        set frustration 0
        set label "Clothing Owner"
      ]
    ]
  ]
end

to setup-custom-roads
  ;; 1. Main wide horizontal road
  ask patches with [abs pycor <= 1] [
    set pcolor gray
  ]

  ;; 2. Two-patch-wide vertical road to market, adjacent to market's right side
  let market-road-x (min-pxcor + 10)
  ask patches with [
    (pxcor = market-road-x or pxcor = market-road-x + 1) and
    pycor <= 0 and pycor >= min-pycor
  ] [
    set pcolor gray
  ]

  ;; 3. L-shaped road in top-right which enters right edge 2 patches lower than the top edge
  let vertical-x 5
  let turn-y max-pycor - 1  ;; L-shaped turn point 2 rows below max
  ask patches with [pxcor = vertical-x and pycor >= 0 and pycor <= turn-y] [
    set pcolor gray
  ]
  ask patches with [pycor = turn-y and pxcor >= vertical-x] [
    set pcolor gray
  ]

  ;; 4. Additional vertical road going down from main horizontal road
  ask patches with [
    pxcor = 5 and pycor <= 1 and pycor >= min-pycor
  ] [
    set pcolor gray
  ]

  ;; 5. New vertical roads branching from main road to top edge
  ask patches with [pxcor = -10 and pycor >= 0] [
    set pcolor gray
  ]

  ;; 6. Horizontal road starting 5 patches away from the left edge
  let upper-road-y max-pycor - 5
  ask patches with [
    pycor >= upper-road-y - 6 and pycor <= upper-road-y + 2 and
    pxcor >= min-pxcor + 6 and pxcor <= 5
  ] [
    set pcolor gray
  ]

  ;; 7. Horizontal road connecting bottom vertical roads, 5-patch wide, 3 patches above bottom
  let road-bottom-start (min-pycor + 3)
  let left-x (min-pxcor + 10)
  let right-x 5
  ask patches with [
    pycor >= road-bottom-start and pycor < road-bottom-start + 9 and
    pxcor >= left-x and pxcor <= right-x
  ] [
  set pcolor gray
  ]
end

to setup-sidewalks
  ask patches with [
    pcolor != gray and
    pcolor != orange and
    pxcor > min-pxcor - 1 and pxcor < max-pxcor + 1 and
    pycor > min-pycor - 1 and pycor < max-pycor + 1
  ] [
    if any? neighbors4 with [pcolor = gray] [
      set pcolor brown
    ]
  ]
end

to setup-homes
  ;; Pink patch in top-left corner
  ask patches with [
    pxcor >= min-pxcor and pxcor < (min-pxcor + 5) and
    pycor >= (max-pycor - 13) and pycor <= max-pycor
  ] [
    set pcolor pink
  ]
end

to setup-customers
  create-customers num-of-customers [
    set color blue
    set shape "person"
    set dwell-time 0
    set time-spent 0
    set is-vendor-shopping false
    set vendor-shopping-time 0
    move-to one-of patches with [pcolor = brown]
    setxy round xcor round ycor

    ;; Assign goal
    let choice random 4  ;; randomly 0, 1, 2, 3
    if choice = 0 [
      set goal "market"
      set destination one-of patches with [pcolor = orange]
    ] if choice = 1 [
      set goal "grocery"
      set destination one-of patches with [pcolor = green]
    ] if choice = 2 [
      set goal "clothing"
      set destination one-of patches with [pcolor = turquoise]
    ] if choice = 3 [
      set goal "home"
      set destination one-of patches with [pcolor = pink]
    ]
  ]
end

to setup-stationery-vendors
  ;; Stationary vendors in the market
  create-stationery-vendors num-of-stationery-vendors [
    set color pink
    set shape "person"
    move-to one-of patches with [pcolor = orange]
    setxy round xcor round ycor
    set product-type one-of ["grocery" "clothing"]
  ]
end

to setup-mobile-vendors
  ;; Mobile vendors on sidewalks
  create-mobile-vendors num-of-mobile-vendors [
    set color red
    set shape "person"
    set is-serving false
    move-to one-of patches with [pcolor = brown]
    setxy round xcor round ycor
    set product-type one-of ["grocery" "clothing"]
  ]
end

to setup-police-officers
  create-police-officers num-of-police-officers [
    set color black
    set shape "person"
    set size 1.2

    ;; Starting position
    let start-patch one-of patches with [pcolor = gray or pcolor = brown]
    move-to start-patch

    ;; Create patrol points from valid walkable patches
    let p1 one-of patches with [pcolor = gray or pcolor = brown]
    let p2 one-of patches with [pcolor = gray or pcolor = brown]
    let p3 one-of patches with [pcolor = gray or pcolor = brown]

    ;; Store patrol points and initial target
    set patrol-points (list p1 p2 p3)
    set current-target p1
  ]
end

to setup-trees
  ask patches with [pcolor = black] [
    if random-float 1 < 0.5 [
      sprout-trees 1 [
        set shape "tree"
        set color green + one-of [-3 -2 -1 1]
        set size 1.5
      ]
    ]
  ]
  ask patches with [pcolor = black] [
  set pcolor brown - 2  ;; Darker shade of brown for soil
]
end

;============================================= REPORTING PROCEDURES =========================================

to-report repeat-string [char n]
  let result ""
  repeat n [
    set result (word result char)
  ]
  report result
end

to plot-emotions
  set-current-plot "Emotional Trends"

  set-current-plot-pen "Average Frustration"
  if any? storeowners [
    plot mean [frustration] of storeowners
  ]

  set-current-plot-pen "Average Happiness"
  if any? mobile-vendors [
    plot mean [happiness] of mobile-vendors
  ]
end

to update-metrics
  set avg-vendor-happiness mean [happiness] of mobile-vendors
  set avg-storeowner-frustration mean [frustration] of storeowners
end


;========================================= MOVEMENT PROCEDURES ================================================

to move-customers
  ask customers [

    ;; If customer is shopping from vendor, count down vendor-shopping-time
    if is-vendor-shopping [
      set vendor-shopping-time vendor-shopping-time - 1
         let progress floor ((1 - vendor-shopping-time / 14) * 10)
         set color cyan  ;; turn customers cyan to signal they are vendor shopping
         set label repeat-string "▪" progress

       if vendor-shopping-time <= 0 [
         set is-vendor-shopping false
         set label ""
         set color blue  ;; turn customers back to blue to indicate they are dont shopping
         reassign-goals
      ]
      stop
    ]

    ;; Shopping time when customers arrive at the store
    if destination = nobody and dwell-time > 0 and is-vendor-shopping = false [
      set time-spent time-spent + 1

      let progress floor ((time-spent / dwell-time) * 10)
      set label repeat-string "▪" progress
      set color violet ;; customers turn violet when shopping at stores

      if time-spent >= dwell-time [
        set dwell-time 0
        set time-spent 0
        set label ""        ;; Clear label when done waiting
        set color blue      ;; Reset to blue
        stop                ;; Stop to avoid moving this tick
      ]
      stop                  ;; Stop to avoid movement while shopping
    ]

    ;; Reassign goal if shopping has concluded
    if destination = nobody and dwell-time = 0 [
      reassign-goals
      stop  ;; Don't move in the same tick as goal assignment
    ]

    ;; MOVEMENTS OF CUSTOMERS IN VALID SPACES
    ;; Step 1: Move toward the destination
    if destination != nobody and is-agent? destination [
      let my-destination destination
      let walkable-neighbors neighbors with [pcolor = brown or pcolor = orange or pcolor = gray or pcolor = turquoise or pcolor = green or pcolor = pink]

      ;; Find patch that is closer to goal than current position
      let next-step min-one-of walkable-neighbors [
        distance my-destination
      ]

      if next-step != nobody [
        face next-step
        fd 1
      ]

      ;; Step 2: Check 1 patch radius for a vendor with desired product
      let nearby-vendor one-of mobile-vendors in-radius 1 with [product-type = [goal] of myself and not is-serving]

      ifelse nearby-vendor != nobody and is-vendor-shopping = false [
        ;; Found a vendor with what the customer wants
        ;; Increase corresponding storeowner's frustration
        if goal = "grocery" [
          ask storeowners with [label = "Grocery Owner"] [
            set frustration frustration + 1
          ]
        ]

        if goal = "clothing" [
          ask storeowners with [label = "Clothing Owner"] [
            set frustration frustration + 1
          ]
        ]

        ;; Start shopping from vendor
        set is-vendor-shopping true
        set vendor-shopping-time 5 + random 10  ;; shopping lasts 5–14 ticks
        set destination nobody
        ;; set color yellow
        set label repeat-string "▪" 1

        ask nearby-vendor [
        set is-serving true
        set serve-time [vendor-shopping-time] of myself
        set sales-count sales-count + 1
        set happiness happiness + random 5 + 1
        ]
        stop
      ] [
        ;; Step 3: If reached destination and didn't find vendor or were headed home, wait again
        if distance my-destination < 1 [
          ifelse goal = "home" [
            set destination nobody
            set dwell-time random 50 + 100  ;; stay home 10–29 ticks
            set time-spent 0
            stop
          ] [
            ;; At store: wait
            set destination nobody
            set dwell-time random 10 + 5
            set time-spent 0
            stop
          ]
        ]

        ]
      ]
    ]
end

to reassign-goals
  ask customers with [destination = nobody] [
    let choice random 4  ;; now includes 0 to 3
    if choice = 0 [
      set goal "market"
      set destination one-of patches with [pcolor = orange]
    ]
    if choice = 1 [
      set goal "grocery"
      set destination one-of patches with [pcolor = green]
    ]
    if choice = 2 [
      set goal "clothing"
      set destination one-of patches with [pcolor = turquoise]
    ]
    if choice = 3 [
      set goal "home"
      set destination one-of patches with [pcolor = pink]
    ]
    set label ""
    set color blue
  ]
end


to move-mobile-vendors
  ask mobile-vendors [

    ;; BLOCKED by police?
    if any? police-officers in-radius enforcement-radius [
      ;; Decrease vendor happiness randomly (1–3), but not below 0
      set happiness max list 0 (happiness - (1 + random 4))

      ;; Decrease relevant storeowner's frustration (1–2), but not below 0
      if product-type = "grocery" [
        ask storeowners with [label = "Grocery Owner"] [
          set frustration max list 0 (frustration - (1 + random 2))
        ]
      ]
      if product-type = "clothing" [
        ask storeowners with [label = "Clothing Owner"] [
          set frustration max list 0 (frustration - (1 + random 2))
        ]
      ]

  set color white  ;; restricted vendors turn white
  stop
]

    ;; Reset color of vendors back to red if previously blocked but now active
    set color red

    if is-serving [
      set serve-time serve-time - 1
      if serve-time <= 0 [
        set is-serving false
      ]
      stop  ;; don't move while serving
    ]

    let walkable-patches neighbors with [pcolor = brown or (pcolor = gray and random-float 1 < 0.1) and not (pcolor = orange or pcolor = turquoise or pcolor = green)]

    ;; Exclude patches within enforcement radius of any police officer
    set walkable-patches walkable-patches with [
      not any? police-officers in-radius enforcement-radius
    ]

    ;; Look for customer hotspots within radius 5 - how vendors follow customers
    let customer-patches patches in-radius 5 with [any? customers-here]

    (ifelse any? customer-patches and any? walkable-patches [
      let target max-one-of customer-patches [count customers-here]
      let step-patch min-one-of walkable-patches [distance target]
      if step-patch != nobody [
        face step-patch
        fd 1
      ]
    ] any? walkable-patches [
      ;; Randomly move to a walkable neighbor
      face one-of walkable-patches
      fd 1
    ])

    ;; Keep snapped to grid
    setxy round xcor round ycor
  ]
end

to move-police
  ask police-officers [
    ;; Ensure the target is valid
    if not (is-patch? current-target) [ stop ]

    let walkable-neighbors neighbors with [pcolor = gray or pcolor = brown]

    let my-target current-target
    let next-step min-one-of walkable-neighbors [
      distance my-target
    ]


    if next-step != nobody [
      face next-step
      fd 1
    ]

    if distance current-target < 1 [
      let index position current-target patrol-points
      let next-index (index + 1) mod length patrol-points
      set current-target item next-index patrol-points
    ]

    setxy round xcor round ycor
  ]
end

;========================================= DECAY EMOTIONS =================================================

to decay-frustration
  ask storeowners [
    set frustration max list 0 (frustration - 0.1)
  ]
end

to decay-happiness
  ask mobile-vendors [
    set happiness max list 0 (happiness - 0.05)
  ]
end

;=================================AGENT CONVERSIONS ===========================================================
to stationery-conversions
  let avg-happiness mean [happiness] of mobile-vendors
  let min-stationery floor (0.3 * num-of-stationery-vendors)  ;; minimum 30% of stationey vendors should remain in market
  if avg-happiness > mobile-threshold [
    set mobile-threshold-counter mobile-threshold-counter + 1
  ]

  if mobile-threshold-counter mod 500 = 0 and mobile-threshold-counter > 0 [
    if count stationery-vendors > min-stationery [
      ;; Convert a random stationery vendor to mobile vendor
      let candidate one-of stationery-vendors
      if candidate != nobody [
        ask candidate [
          hatch-mobile-vendors 1 [
            set color red
            set shape "person"
            set is-serving false
            move-to one-of patches with [pcolor = brown]
            setxy round xcor round ycor
            set product-type one-of ["grocery" "clothing"]
          ]
          die
        ]
        set vendors-switched vendors-switched + 1  ;; Increment counter
      ]
    ]
  ]

  if avg-happiness <= mobile-threshold [
    set mobile-threshold-counter 0
  ]
end

;===========================================================================================================

to go
  move-customers
  move-mobile-vendors
  move-police
  decay-frustration
  decay-happiness
  plot-emotions
  stationery-conversions
  update-metrics
  if ticks >= 2000 [ stop ]
  tick
end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
647
448
-1
-1
13.0
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
30.0

SLIDER
4
252
176
285
num-of-customers
num-of-customers
0
400
250.0
10
1
NIL
HORIZONTAL

BUTTON
57
34
120
67
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
59
102
122
135
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

SLIDER
7
295
208
328
num-of-stationery-vendors
num-of-stationery-vendors
0
100
50.0
5
1
NIL
HORIZONTAL

SLIDER
7
338
188
371
num-of-mobile-vendors
num-of-mobile-vendors
0
100
10.0
5
1
NIL
HORIZONTAL

PLOT
823
55
1023
205
Emotional Trends
Time
Emotional Level
0.0
100.0
0.0
100.0
true
false
"" ""
PENS
"Average Frustration" 1.0 0 -2674135 true "" "if any? storeowners [ plot mean [frustration] of storeowners ]"
"Average Happiness" 1.0 0 -13840069 true "" "if any? mobile-vendors  [\n  plot mean [happiness] of mobile-vendors\n]"

SLIDER
14
386
186
419
num-of-police-officers
num-of-police-officers
0
50
7.0
1
1
NIL
HORIZONTAL

SLIDER
24
431
196
464
enforcement-radius
enforcement-radius
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
26
472
198
505
mobile-threshold
mobile-threshold
0
500
50.0
50
1
NIL
HORIZONTAL

MONITOR
772
285
953
330
Stationery Vendors Converted
vendors-switched
17
1
11

@#$#@#$#@
## WHAT IS IT?

This model simulates the dynamics of informal and formal commerce in a city-like environment. It was inspired by the street vending problem that is a major area of concern in Zambia. Many Zambians rely on illegal street vending to make an income. Implementing a strict ban would leave thousands unemployed. Having zero regulations results in decreased quality of life for many citizens. For example, environments get littered because of unregulated trading zones, and storeowners’ businesses will underperform resulting in their employees losing jobs.

This model features interactions between customers, mobile vendors, stationery vendors, storeowners, and police officers, with agents moving across different zones like markets, homes, and shops. The model explores how mobile vendors affect storeowners’ frustration, how customers choosing to purchase from mobile vendors affects the merchants’ quality of life (happiness levels), how regulation enforcement can affect market dynamics, and how agent behaviours evolve overall in a shared urban space.

## WHY IS IT INTERESTING?

This model is useful for studying the tensions and coexistence between informal vendors and formal shop owners in urban settings. It captures how customer choices and vendor mobility impact shop owner emotions and market dynamics. The inclusion of police officers allows us to test enforcement levels. Using this model, we can explore the trade-off between police enforcement – which restricts mobile vendor trading and thus decreases their quality of life – and storeowner frustration – which decreases with increased enforcement.

## HOW IT WORKS

•	Customers choose a destination (market, grocery store, clothing store, or home) and move toward it using the sidewalks and roads.
•	If customers encounter a nearby mobile vendor selling their desired product, they may shop from them instead of going to the store.
•	Shopping at mobile vendors increases the frustration of the corresponding storeowner. For example, if a customer decides to purchase from a mobile vendor selling clothes, the clothing storeowner’s frustration increases. Their frustration is modelled to decay over time, since people do not remain in the same state of emotion forever.
•	Mobile vendors gain happiness from sales, which also decays over time. They have a sales-count and can only serve one customer at a time.
•	Police officers patrol the environment along predefined waypoints. There is an enforcement radius variable that can be adjusted to determine the officer’s sphere of influence. For example, if the enforcement radius is set to 2, that means all mobile vendors within a 2-patch radius will be unable to trade (they become idle). 
•	Stationery vendors are in the market and do not move. However, when the happiness levels of the mobile vendors exceeds a threshold, one randomly chosen stationery vendor will be converted to a mobile vendor. This simulates the real-life influence of successful mobile vending – vendors in the market slowly start to leave the designated trading spaces for the more lucrative street vending.
•	Trees are placed randomly for aesthetic and spatial effects.
•	The environment includes coloured patches: orange (market), green (grocery), turquoise (clothing), pink (homes), grey (roads), and brown (sidewalks).

## HOW TO USE IT

1.	Set the number of customers, mobile vendors, stationery vendors, and police officers using the sliders.
2.	Set the enforcement radius of the police using the slider. The larger the value, the more restricted street vendors will be.
3.	Set the mobile threshold (minimum happiness of mobile vendors that will convince a stationery vendor to convert into a mobile street vendor) using the slider.
4.	Press Setup to initialise the environment.
5.	Press Go to run the simulation.
6.	Watch how customers navigate and interact with vendors or stores.
7.	Use the Emotional Trends plot to monitor the average frustration of storeowners (red line) and happiness of mobile vendors over time (green line).


## THINGS TO NOTICE

•	Customers change colour to violet while shopping at the grocery store, clothing store, or market. A label progress bar (represented by white dots) will appear to show how much time has passed while the customer is busy shopping.
•	Customers change colour to cyan while shopping from mobile street vendors. A label progress bar (represented by white dots) will appear to show how much time has passed while the customer is busy shopping. The street vendor does not move or attend to other customers while this is happening, to simulate trading.
•	When made idle by the police, the mobile street vendors turn white to represent that they are unable to trade because of the presence of police.
•	Storeowners become increasingly frustrated when customers shop from mobile vendors instead of their stores. When a police officer makes a mobile vendor idle, the storeowner’s frustration decreases.
•	Mobile vendors become happier with sales. However, when they are idle (due to the presence of police) their happiness decreases.
•	Emotional trends plotted over time reveal patterns in vendor success and storeowner dissatisfaction.


## THINGS TO TRY

•	Increase the number of mobile vendors and observe how it affects storeowner frustration (shown as the red line in the plot).
•	Increase the number of police and/or the enforcement radius and observe how it affects mobile vendors’ happiness (shown as a green line in the plot).
•	Decrease the number of police and/or the enforcement radius and observe how it affects storeowner frustration (shown in plot) as well as stationery vendor conversions (shown in monitor).


## EXTENDING THE MODEL

•	Enable vendors to be more strategic. For example, observing the police officer’s patrol routes and avoiding them, and occasionally roaming around the city to see if there are higher foot traffic areas than the one they are used to.
•	Allow storeowners to reduce their prices or take actions to compete with mobile vendors.
•	Introduce time-of-day dynamics where customer flow and police patrolling changes. This was partially introduced by enabling customers to go home but can be improved.
•	Add a weather system that affects where vendors or customers move.
•	Simulate how street vending has negative effects on the environment e.g., littering, which can actually affect customer preferences when it comes to where they want to shop.
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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="1 to 5 police enforcement tradeoff" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>avg-vendor-happiness</metric>
    <metric>avg-storeowner-frustration</metric>
    <enumeratedValueSet variable="num-of-stationery-vendors">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforcement-radius">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-customers">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-mobile-vendors">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-police-officers">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mobile-threshold">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1 to 1 police enforcement tradeoff" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>avg-vendor-happiness</metric>
    <metric>avg-storeowner-frustration</metric>
    <enumeratedValueSet variable="num-of-stationery-vendors">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforcement-radius">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-customers">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-mobile-vendors">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-police-officers">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mobile-threshold">
      <value value="50"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="1 to 3 police enforcement tradeoff" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>avg-vendor-happiness</metric>
    <metric>avg-storeowner-frustration</metric>
    <enumeratedValueSet variable="num-of-stationery-vendors">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="enforcement-radius">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-customers">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-mobile-vendors">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-of-police-officers">
      <value value="0"/>
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mobile-threshold">
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
