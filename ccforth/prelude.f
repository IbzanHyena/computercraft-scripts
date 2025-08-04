NB. arithemtic
: +1 1 + ;
: 1+ +1 ;
: 1- 1 swap - ;
: neg 0 swap - ;
: 0= 0 = ;

NB. stack manipulation
: 2dip swap [ dip ] dip ;
: 3dip swap [ 2dip ] dip ;
: 4dip swap [ 3dip ] dip ;
: keep over [ execute ] dip ;
: 2keep [ 2dup ] dip 2dip ;
: 3keep [ 3dup ] dip 3dip ;

NB. conditional flow
: 1check keep swap ;
: 1if [ 1check ] 2dip if ;

NB. looping constructs
: positive? 0 > ;
: negative? 0 < ;
: negate [ not ] compose ;
: do dup 2dip ;
: when [ ] if ;
: unless [ ] swap if ;
: loop [ execute ] keep [ recurse ] curry when ;
: while swap do compose [ loop ] curry when ;
: until [ negate ] dip while ;
: repeat [ 1 - ] compose [ dup positive? ] swap while drop ;

: ndrop [ [ drop ] dip ] repeat ;

NB. variable and current pointer stuff
: ? @ . ;
: here cp @ ;
: allot cp @ + cp ! ;
: , here ! allot ;

NB. maths
: fac [ positive? ] [ dup 1 - recurse * ] [ drop 1 ] 1if ;
: fmod 2 " math" " fmod" luacall ;
: fib 0 1 rot [ dup 0 > ] [ [ over + swap ] dip 1 - ] while drop drop ;
: even? 2 fmod 0 = ;
: odd? even? not ;

NB. dataflow combinators
NB. spread--apply multiple quotations to a single value
NB. two quotations:
: bi [ keep ] dip execute ;
: 2bi [ 2keep ] dip execute ;
: 3bi [ 3keep ] dip execute ;

NB. three quotations:
: tri [ [ keep ] dip keep ] dip execute ;
: 2tri [ [ 2keep ] dip 2keep ] dip execute ;
: 3tri [ [ 3keep ] dip 3keep ] dip execute ;

NB. cleave--apply multiple quotations to multiple values
NB. two quotations:
: bi* [ dip ] dip execute ;
: 2bi* [ 2dip ] dip execute ;

NB. three quotations:
: tri* [ [ 2dip ] dip dip ] dip execute ;
: 2tri* [ 4dip ] 2dip 2bi* ;

NB. apply--apply a single quotation to multiple values
NB. two values:
: bi@ dup bi* ;
: 2bi@ dup 2bi* ;

NB. three values:
: tri@ dup dup tri* ;
: 2tri@ dup dup 2tri* ;

NB. logic
: both? bi@ and ;
: either? bi@ or ;
