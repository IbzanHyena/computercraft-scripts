" /ccforth/prelude.f" require
" /ccforth/turtle.f" require

4 variable!: length
60 variable!: check-interval 60
variable: iteration-start
0 variable!: wood-harvested 0
0 variable!: trees-chopped

: now 0 " os" " clock" luacall ;
now variable!: start-time
start-time @ variable!: last-report-time 
300 variable!: report-interval
false variable!: report-separator?

: item-detail turtle.getItemDetailSlot ;

: fwd " forward" extraTurtle.tolerantMove ;
: up " up" extraTurtle.tolerantMove ;
: down " down" extraTurtle.tolerantMove ;
: downN " down" swap extraTurtle.tolerantMoveN ;
: back " back" extraTurtle.tolerantMove ;
: left turtle.turnLeft drop ;
: right turtle.turnRight drop ;

: .name " name" get ;
: .count " count" get ;

NB. ( block needle -- ? )
: name-is swap .name substr? ;

NB. ( block/item -- ? )
: log? " log" name-is ;
: sapling? " sapling" name-is ;

NB. ( pred ? block/err -- ? )
: inspect-is? swap [ swap execute ] [ 2 ndrop false ] if ;
: neither-log-nor-sapling? [ log? ] [ sapling? ] bi or not ;

NB. ( i -- )
: refuel [ neither-log-nor-sapling? ] extraTurtle.refuelToMinWith ;

NB. ( val var -- )
: incn dup [ @ + ] dip ! ;
NB. ( var -- )
: inc 1 swap incn ;

NB. ( -- )
: chop-tree
    trees-chopped inc
    turtle.dig drop
    1 refuel fwd
    0                                          NB. height
    [ [ log? ] turtle.inspectUp inspect-is? ]  NB. pred
    [ 1 refuel turtle.digUp drop up +1 ]       NB. body
    while
    dup +1 refuel downN back ;

NB. ( a b -- max )
: max 2dup < [ swap ] when drop ;

NB. ( -- )
: grab-saplings
    [ sapling? ] select-slot
    slot-not-empty?
    [ turtle.getItemDetail .count ] [ 0 ] if
    length @ 2 * swap - 0 max 
    turtle.suckN drop ;

NB. ( -- )
: return-wood
    0  NB. wood returned
    [
        [ log? ] select-slot slot-empty?
        NB. now check that the slot which is selected
        NB. does contain a log before continuing
        [ true ] [ turtle.getItemDetail log? not ] if
    ]
    [
        turtle.getItemCount +
        turtle.dropAll
        dup type " string" = [ drop ] when drop
    ]
    until
    wood-harvested incn ;

NB. ( -- )
: plant-sapling
    [ sapling? ] select-slot
    turtle.detect [ turtle.place drop ] unless ;

NB. ( -- )
: service
    left return-wood
    left grab-saplings
    left left ;

NB. ( -- )
: print-report
    report-separator? @
    [ " ----------" . ] [ true report-separator? ! ] if

    now dup dup
    last-report-time !

    " Now harvested "  wood-harvested @ ..
    "  wood (" ..
    trees-chopped @ ..
    "  trees)" ..
    .

    start-time @ -
    " Time taken: " swap  ..
    "  s" ..
    .

    start-time @ - wood-harvested @ swap /
    " Rate: " swap ..
    "  wood/s" ..
    . ;

NB. ( -- )
: try-chop-tree
    [ log? ]
    turtle.inspect
    over
    [ inspect-is? [ chop-tree ] when true ]
    [ plant-sapling 3 ndrop false ]
    if ;

NB. ( -- )
NB. doesn't terminate
: harvest-one
    [
        [ print-report ] now last-report-time @ - report-interval @ >= when
        try-chop-tree
        [ 5 sleep ] [ service ] if
    ] forever ;

NB. ( -- )
: harvest-row
    [
        now iteration-start !
        service
        length @ dup refuel
        [
            1 refuel
            fwd right
            try-chop-tree [ plant-sapling ] when
            left
        ] repeat
        NB. turn around
        left left
        NB. order swaps in the opposite direction
        length @ dup refuel
        [
            right
            try-chop-tree [ plant-sapling ] when
            left 1 refuel fwd
        ] repeat
        right right service
        print-report
        now iteration-start @ - check-interval @ swap - 0 max sleep
    ] forever ;
