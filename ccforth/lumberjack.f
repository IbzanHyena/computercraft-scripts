" /ccforth/prelude.f" require
" /ccforth/turtle.f" require

: rowCheckInterval 60 ;  NB. seconds
: length 4 ;

: item-detail turtle.getItemDetailSlot ;

: refuel extraTurtle.refuelToMin ;
: fwd " forward" extraTurtle.tolerantMove ;
: up " up" extraTurtle.tolerantMove ;
: down " down" extraTurtle.tolerantMove ;
: downN " down" swap extraTurtle.tolerantMoveN ;
: back " back" extraTurtle.tolerantMove ;

: .name " name" get ;
: .count " count" get ;

NB. ( block needle -- ? )
: name-is swap .name substr? ;

NB. ( block/item -- ? )
: log? " log" name-is ;
: sapling? " sapling" name-is ;

NB. ( pred ? block/err -- ? )
: inspect-is? swap [ execute ] [ drop false ] if ;
: neither-log-nor-sapling? [ log? ] [ sapling? ] bi or not ;

: chop-tree
    turtle.dig drop
    1 refuel fwd
    0                                          NB. height
    [ [ log? ] turtle.inspectUp inspect-is? ]  NB. pred
    [ 1 refuel turtle.digUp drop up +1 ]       NB. body
    while
    dup +1 refuel downN back ;

NB. ( a b -- max )
: max 2dup < [ swap ] when drop ;

: grab-saplings
    [ sapling? ] select-slot
    slot-not-empty?
    [ turtle.getItemDetail .count ] [ 0 ] if
    length 2 * swap - 0 max 
    turtle.suckN drop ;

: return-wood
    0  NB. wood returned
    [ [ log? ] select-slot slot-empty? ]
    [ turtle.getItemCount + turtle.dropAll drop ]
    until ;

