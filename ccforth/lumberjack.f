" /ccforth/prelude.f" require
" /ccforth/turtle.f" require

variable: length 4 length !
variable: check-interval 60 check-interval !
variable: iteration-start
variable: wood-harvested 0 wood-harvested !
variable: trees-chopped 0 trees-chopped !

: now 0 " os" " clock" luacall ;
variable: start-time now start-time !
variable: last-report-time start-time @ last-report-time !
variable: report-interval 300 report-interval !
variable: report-separator? false report-separator? !

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
: lava-crystal? " lavaCrystal" name-is ;

NB. ( i -- )
: refuel [ lava-crystal? ] extraTurtle.refuelToMinWith ;

NB. ( pred ? block/err -- ? )
: inspect-is? swap [ swap execute ] [ 2 ndrop false ] if ;
: neither-log-nor-sapling? [ log? ] [ sapling? ] bi or not ;

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
        [ [ true ] [ turtle.getItemDetail log? not ] ] dip if
    ]
    [ turtle.getItemCount + turtle.dropAll drop ]
    until
    wood-harvested incn ;

NB. ( -- )
: plant-sapling
    [ sapling? ] select-slot
    turtle.place drop ;

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
            fwd right try-chop-tree left
        ] repeat
        NB. order swaps in the opposite direction
        length @ dup refuel
        [
            right try-chop-tree left
            1 refuel fwd
        ] repeat
        right right service
        print-report
        now iteration-start @ - row-check-interval @ swap - 0 max sleep
    ] forever ;
