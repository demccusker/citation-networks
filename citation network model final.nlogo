breed [people person]
breed [pubs pub]
directed-link-breed [citations citation]
undirected-link-breed [authored author]
people-own [pubcount totcitcount grantcount intpubs newgrant?]
pubs-own [citcount age]
globals [avgcitswomen avgcitsmen avgpubswomen avgpubsmen avggrantswomen avggrantsmen  sdmc sdwc sdmp sdwp sdmg sdwg avgcits intpublist ]



to setup
  clear-all

  if grantrate <= 0 or grantrate >= 1
  [print "Please enter a decimal for the grant rate."
    stop]
   if avgcitsprop <= 0 or avgcitsprop >= 1
  [print "Please enter a decimal for the average proportion of papers cited."
    stop]
  set-default-shape people "person"
  set-default-shape pubs "book"
  set-default-shape citations "cits"
  createpeople
  createpubs
  setupauthors
  setupcits
  setcounts
  ;layout

  reset-ticks

end

to createpeople
  create-people comsize [  ;;makes the number of people in the community based on the input comsize
   ifelse who < (comsize * (percentwomen / 100))  ;;adjusts based on user input
  [set color pink]
    [set color blue]
  ]
  layout-circle people 15   ;;lays them out in a circle
end

to createpubs
  let totintpubs 0  ;;keeps track of how many pubs to make in total
  set intpublist []
  ask people [
    let x (ln avgpubs - .18)
    let y random-normal x .6
    let w exp y
    let z ((ceiling w) - 1)
    set intpubs z  ;;sets that as the initial number of pubs for a person, so that it will be possible to connect the person with the right number of pubs
    set totintpubs (totintpubs + z) ;;adds it to the counter of total pubs being made
    set intpublist lput z intpublist
  ]
  create-pubs totintpubs [set color green  ;;makes the right number of publications
  set age 0]  ;;keeps track of the age of pubs; it's not that important to do, but it's helpful for checking things
 end

to setupauthors
ask people [
    while [(count author-neighbors) < intpubs]  ;; the loop won't end until each person has the right number of pubs;
    [let pubwho one-of pubs      ;;finds a pub
      let i 0
      ask pubwho [ set i (count author-neighbors)]  ;;checks if the pub already has an author
      if  i < 1
      [create-author-with pubwho] ;;if not, makes the person the author. if yes, the loop repeats until the person has enough pubs

  ]


  ]

end


to setupcits
  let x count pubs
  set avgcits ceiling( x * avgcitsprop)
   ask pubs
 [ let m ln avgcits
    let n random-normal m 1
    let p exp n
    let i ceiling p
     while [ i > ((count pubs) - 1) ]   ;;checks that the number of outgoing citations is not greater than the total number of citable articles
    [ set m ln avgcits
    set n random-normal m 1
    set p exp n
    set i ceiling p]
    while [(count my-out-citations) < i]  ;;repeats until this turtle has the right number of outcitations
    [let newwho [who] of one-of pubs  ;;finds a random pub
     if who != newwho
        [create-citation-to pub newwho] ;;as long as it's not itself, it makes a citation to that paper. it also won't create a link if there already is one, but the loop won't end until the right number of out citations is created
    ]

  ]

end

to layout         ;;makes it look nice
ask people
  [let x xcor
    let y ycor
    ask author-neighbors
    [setxy (x +  random-normal 0 3) (y +  random-normal 0 3)]
  ]
end


to go

  ifelse grantfortopx?
  [getgranttopx]
  [getgrant]
  publish
  ifelse genderbias?
  [setnewcitesbiased]
  [setnewcites]
  setcounts
  ;layoutagain
  tick

end

to go-once
   ifelse grantfortopx?
  [getgranttopx]
  [getgrant]
  publish
 ifelse genderbias?
  [setnewcitesbiased]
    [setnewcites]
  setcounts
  ;layoutagain
  tick
end

to getgrant
  ask pubs [set color green
  set age (age + 1)]      ;;turns previously new pubs back to green
  ask people [
    set newgrant? 0               ;;overwrites previous value for having gotten a grant
      let i random-float 1
    if i < grantrate
    [ set grantcount (grantcount + 1)    ;;if the random number is greater than the grant rate, the person gets a grant
    set newgrant? 1
    ]

  ]
end


to getgranttopx  ;;this version gives grants to top performers
  ask pubs [set color green
  set age (age + 1)]
  ask people [set newgrant? 0]

 if grantrate = grantfortopx  ;;calls the right function, depending on the two inputs for grant rate and what top percent to consider
   [grandgftxequal]
  if grantrate > grantfortopx
   [grgreaterthangftx]
   if grantrate < grantfortopx
   [grlessthangftx]


ask people [if newgrant? = 1   ;;once the new grants are distributed, this just tracks how many total grants a person has
    [ set grantcount (grantcount + 1)]]

end

to grandgftxequal   ;;used when the two rates are equal; the effect is that only the top x% will get grants and no one else
  let a topzpeople (grantrate * 100)  ;;generates a list of top x%
  let i 0
      while [i < length a]   ;;goes through the list giving each member a grant
     [let b item i a
       let c item 1 b
      ask person c [set newgrant? 1]
    set i (i + 1)]
end

to grgreaterthangftx   ;;used when the grant rate is higher than the top x% value; the effect is that all of the top x% will receive a grant, plus grantrate - topx% additional people
  let a topzpeople (grantfortopx * 100)  ;;makes the list of top performers
  let i 0
      while [i < length a]  ;;goes through the list giving each member a grant
     [let b item i a
       let c item 1 b
      ask person c [set newgrant? 1
        ]
    set i (i + 1)]
      let grantsleft (grantrate - grantfortopx)  ;;sets the value for how many 'leftovers' there are
     ask people[ if newgrant? = 0     ;;makes sure only people who don't already have a grant can get one that's 'leftover'
          [let j random-float 1   ;;uses a random check like the version where everyone has an equal chance
          if j < grantsleft
             [set newgrant? 1]
          ]
    ]

end

to grlessthangftx  ;;used when the grant rate is lower than top x% percent input; the effect is that individuals from the top x% are choosen for the right number of total grants
  let m topzpeople (grantfortopx * 100)  ;;makes the list of top performers
    let n (grantrate * comsize)  ;;determines the number of grants to be given
   let p 0
      while [p < n]
      [let q length m
    let r random q  ;;picks a random element from the top performer list
    let s item r m
    let t item 1 s
        ask person t [set newgrant? 1]  ;;gives that person a grant
          set m remove s m  ;;removes them from the list
          set p (p + 1)
    ]
end

to-report countnewgrants    ;;checks if a person has a new grant to generate the correct number of new pubs
  let i 0
  ask people [set i (i + newgrant?)]
  report i

end


to publish
  let newpublist []
  create-pubs countnewgrants [set color red   ;;creates a new publication for each new grant and makes them red so they can be tracked more easily
    set age 0
     set newpublist lput who newpublist]
  ask people [
    if newgrant? = 1
    [let i first newpublist
    create-author-with pub i     ;;gives each person who received a new grant one of the newly created pubs
    set newpublist remove i newpublist]
    ]

end

to setnewcites
    let x count pubs
  set avgcits ceiling( x * avgcitsprop)
  let red-pubs pubs with [color = red]
  ask red-pubs [

        ;;only adds new citations to the new pubs
   let r ln avgcits
    let s random-normal r 1
    let t exp s
    let i ceiling t
   while[ i > ((count pubs) - 1) or i = 0]
      [set r ln avgcits
    set s random-normal r 1
    set t exp s
    set i ceiling t]
    while [(count my-out-citations) < i]  ;;repeats until this turtle has the right number of outcitations
    [let j one-of pubs    ;;picks a random pub
        let k 0
        ask j [set k one-of citations    ;;picks one if its citations
       ]
        let l [one-of both-ends] of k     ;;then picks one end. This does drive citations towards publications with more citations, but not as aggressively as picking a citation directly
     if l != self
        [create-citation-to l]

      ]


    ]

end

to setnewcitesbiased   ;;the biased version pays attention to what gender the author is
    let a count pubs
  set avgcits ceiling( a * avgcitsprop)
  let red-pubs pubs with [color = red]
  ask red-pubs [

   let r ln avgcits
    let s random-normal r 1
    let t exp s
    let i ceiling t
   while[ i > ((count pubs) - 1) or i = 0]
      [set r ln avgcits
    set s random-normal r 1
    set t exp s
    set i ceiling t]
   while [(count my-out-citations) < i]
   [let j one-of pubs ;;picks a random pub
        let k 0
        ask j [set k one-of citations]   ;;finds a citation of that pub
        let m [end1] of k
        let n [end2] of k
        let p author-gender m    ;;finds out the color of each end of the citation links
        let q author-gender n
        if p = q       ;;if they're the same, then the procedure is the same as the unbiased version
        [let x [one-of both-ends] of k
          if x != self
          [create-citation-to x]]
        if p < q     ;;if the values are different, there is a random check. if a random float between 0 and 1 returns above the threshold set with 'bias points', then the code will always pick the blue author.
        [ifelse random-float 1 < (1 - (biaspoints / 100))   ;;otherwise, the procedure is the same as the unbiased version
          [let x [one-of both-ends] of k
          if x != self
          [create-citation-to x]]
          [if m != self
            [create-citation-to m]]
        ]
        if p > q
        [ifelse random-float 1 < (1 - (biaspoints / 100))
          [let x [one-of both-ends] of k
          if x != self
          [create-citation-to x]]
          [if n != self
            [create-citation-to n]]
        ]
   ]

  ]
    end

to-report author-gender [x]  ;;gets the color of the author of a pub
  let i 0
  ask x [
    ask author-neighbors [set i color]
  ]
  report i
end


to layoutagain     ;;makes it look nice (again!) although it does occasionally give a point off the plot, so at some point, I should add offsets
  ask pubs [
    let x 0
    let y 0
    if color = red
    [ask author-neighbors
    [set x xcor
      set y ycor]
      setxy (x +  random-normal 0 3) (y +  random-normal 0 3)]
  ]
end

to-report topx%? [x]     ;;compiles info about the papers with the most citations
  let xlist []
 ask pubs[
     set xlist lput list citcount who xlist    ;;makes a list of lists for each pub, with its citcount and its who
  ]
set xlist sort-by [[i j] -> ( (item 0 i) > (item 0 j))] xlist  ;;thanks to substack for this code on sorting by the first item of the list
  let y length xlist
  let z (round((x / 100) * y))
  let topxlist []
  let i 0
  while [i < z]
  [let j item i xlist
    set topxlist lput j topxlist    ;;once sorted, a new list is made with just the top x % of turtles
  set i (i + 1)]
  report topx-gender topxlist x
  report topxlist

end

to-report topx-gender [x y]   ;;finds out the gender of the authors of the papers with the most citations
  let a length x
  let i 0
  let mencount 0
  let womencount 0
  while [i < a]
  [let j item i x
    let k item 1 j
    let l author-gender pub k
    if l = 105
    [set mencount (mencount + 1)]
    if l = 135
    [set womencount (womencount + 1)]
  set i (i + 1)]
  report (word "There are " womencount " papers written by women and " mencount " papers written by men in the top " y "% of citations")
end

to-report topzpeople [z]  ;; does the same as previous reporters, but for the total citation counts of individuals
  let peoplelist []
  ask people [
    set peoplelist lput list totcitcount who peoplelist
  ]
  set peoplelist sort-by [[i j] -> ( (item 0 i) > (item 0 j))] peoplelist
  let a length peoplelist
  let b (round((z / 100) * a))
  let c 0
  let topzlist []
  while [c < b]
  [let d item c peoplelist
    set topzlist lput d topzlist
    set c (c + 1)]
 ;report topz-gender topzlist z

  report topzlist
end


to-report topz-gender [x y]  ;;again, finds the gender of the most cited people
  let a length x
  let i 0
  let mencount 0
  let womencount 0
  while [i < a]
  [let j item i x
    let k item 1 j
    let l [color] of person k
    if l = 105
    [set mencount (mencount + 1)]
    if l = 135
    [set womencount (womencount + 1)]
  set i (i + 1)]
  report (word "There are " womencount " women and " mencount " men in the top " y "% of citations")
end

to-report allmentotcites
    let mtotcitlist []
  ask turtles
  [if color = blue
    [set mtotcitlist lput totcitcount mtotcitlist]]
  report mtotcitlist
end
to-report allwomentotcites
  let wtotcitlist []
  ask turtles
  [if color = pink
    [set wtotcitlist lput totcitcount wtotcitlist]]
  report wtotcitlist

end

to setcounts
  let mcitlist []
  let mgrantslist []
  let mpubslist []
  let wcitlist []
  let wpubslist []
  let wgrantslist []

  ask people [
    set pubcount (count author-neighbors)
    let j 0
    ask author-neighbors [
      let i (count in-citation-neighbors)
      set j (j + i)
    ]
    set totcitcount j
    ifelse color = blue
    [set mcitlist lput totcitcount mcitlist
     set mgrantslist lput grantcount mgrantslist
      set mpubslist lput pubcount mpubslist
    ]
    [set wcitlist lput totcitcount wcitlist
      set wgrantslist lput grantcount wgrantslist
   set wpubslist lput pubcount wpubslist
   ]
  ]
  set avgcitsmen mean mcitlist
  set avgcitswomen mean wcitlist
  set avgpubsmen mean mpubslist
  set avgpubswomen mean wpubslist
  set avggrantsmen mean mgrantslist
  set avggrantswomen mean wgrantslist
  set sdmc standard-deviation mcitlist
  set sdwc standard-deviation wcitlist
  set sdmp standard-deviation mpubslist
  set sdwp standard-deviation wpubslist
  set sdmg standard-deviation mgrantslist
  set sdwg standard-deviation wgrantslist

  ask pubs [set citcount (count in-citation-neighbors)]
end
@#$#@#$#@
GRAPHICS-WINDOW
305
25
976
697
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
-25
25
-25
25
1
1
1
ticks
30.0

BUTTON
30
73
93
106
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
98
73
175
106
NIL
go-once
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
180
73
243
106
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

INPUTBOX
30
115
269
175
comsize
100.0
1
0
Number

INPUTBOX
31
182
262
242
avgcitsprop
0.005
1
0
Number

INPUTBOX
31
251
186
311
grantrate
0.25
1
0
Number

INPUTBOX
31
316
186
376
avgpubs
4.0
1
0
Number

SWITCH
30
382
153
415
genderbias?
genderbias?
1
1
-1000

PLOT
1033
362
1233
512
Average citations by gender
Time
Average citations
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -13345367 true "" "plotxy ticks avgcitsmen"
"pen-1" 1.0 0 -2064490 true "" "plotxy ticks avgcitswomen"

PLOT
1036
199
1236
349
Average publications by gender
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
"default" 1.0 0 -13345367 true "" "plotxy ticks avgpubsmen"
"pen-1" 1.0 0 -2064490 true "" "plotxy ticks avgpubswomen"

PLOT
1037
36
1237
186
Average grants by gender
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
"default" 1.0 0 -13345367 true "" "plotxy ticks avggrantsmen"
"pen-1" 1.0 0 -2064490 true "" "plotxy ticks avggrantswomen"

SLIDER
30
419
202
452
biaspoints
biaspoints
1
10
0.0
1
1
NIL
HORIZONTAL

PLOT
1030
531
1571
680
citcounts
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
"default" 1.0 1 -16777216 true "" "histogram [citcount] of pubs"
"pen-1" 1.0 1 -2674135 true "" "histogram [totcitcount] of people"

INPUTBOX
29
459
280
519
grantfortopx
0.0
1
0
Number

SWITCH
160
382
293
415
grantfortopx?
grantfortopx?
1
1
-1000

SLIDER
36
545
208
578
percentwomen
percentwomen
0
100
67.0
1
1
NIL
HORIZONTAL

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

book
false
0
Polygon -7500403 true true 30 195 150 255 270 135 150 75
Polygon -7500403 true true 30 135 150 195 270 75 150 15
Polygon -7500403 true true 30 135 30 195 90 150
Polygon -1 true false 39 139 39 184 151 239 156 199
Polygon -1 true false 151 239 254 135 254 90 151 197
Line -7500403 true 150 196 150 247
Line -7500403 true 43 159 138 207
Line -7500403 true 43 174 138 222
Line -7500403 true 153 206 248 113
Line -7500403 true 153 221 248 128
Polygon -1 true false 159 52 144 67 204 97 219 82

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
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="testing" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="comsize" first="50" step="10" last="100"/>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="arealtest" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <steppedValueSet variable="avgpubs" first="1" step="1" last="10"/>
    <steppedValueSet variable="comsize" first="50" step="50" last="500"/>
    <steppedValueSet variable="avgcitsprop" first="0.01" step="0.01" last="0.1"/>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <steppedValueSet variable="grantrate" first="0.1" step="0.1" last="0.8"/>
    <steppedValueSet variable="grantfortopx" first="0.1" step="0.1" last="0.5"/>
  </experiment>
  <experiment name="smallertest" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
      <value value="100"/>
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="justone" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="testing2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="1"/>
    </enumeratedValueSet>
    <steppedValueSet variable="comsize" first="100" step="100" last="500"/>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep50" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep100" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.03"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep50pt1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep50pt2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="25"/>
      <value value="50"/>
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep50pt3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="50"/>
      <value value="25"/>
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep50pt4" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep100pt1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep100pt2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep100pt3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
      <value value="3"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep100pt4" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
      <value value="7"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt2" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
      <value value="3"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
      <value value="3"/>
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt4" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt5" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt7" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep250pt6" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt1" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="parametersweep50pt5" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="25"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.01"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.1"/>
      <value value="0.25"/>
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.25"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="6"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt3" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt4" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="6"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="newparametersweeppt1" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
      <value value="100"/>
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="newparametersweeppt3" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
      <value value="250"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="newparametersweeppt4" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
      <value value="250"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="newparametersweeppt2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="50"/>
      <value value="250"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.005"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt4take2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt1take2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt3take2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="6"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt2take2" repetitions="100" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="6"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt4take3" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt1take3" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt2take3" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="6"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx">
      <value value="0.1"/>
      <value value="0.2"/>
      <value value="0.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="astronomyexppt3take3" repetitions="1000" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>avgcitswomen</metric>
    <metric>avgcitsmen</metric>
    <metric>avgpubswomen</metric>
    <metric>avgpubsmen</metric>
    <metric>avggrantswomen</metric>
    <metric>avggrantsmen</metric>
    <metric>topzpeople 25</metric>
    <metric>topz-gender (topzpeople 25) 25</metric>
    <metric>sdmc</metric>
    <metric>sdwc</metric>
    <metric>sdmp</metric>
    <metric>sdwp</metric>
    <metric>sdmg</metric>
    <metric>sdwg</metric>
    <metric>allmentotcites</metric>
    <metric>allwomentotcites</metric>
    <enumeratedValueSet variable="biaspoints">
      <value value="1"/>
      <value value="6"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgpubs">
      <value value="35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="comsize">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="avgcitsprop">
      <value value="0.001"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantfortopx?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="genderbias?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="grantrate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="percentwomen">
      <value value="40"/>
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

cits
2.0
-0.2 0 0.0 1.0
0.0 1 2.0 2.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
