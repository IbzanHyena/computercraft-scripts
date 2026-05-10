variable: max-value
variable: results-start
NB. ( i -- addr )
: results results-start @ + ;

NB. ( -- )
: initialise-results
  here results-start !
  max-value @ 1+ allot
  max-value @
  1 [ 2dup >= ] [ dup 1+ swap results t swap ! ] while drop drop
  f 1 results !
  ;

NB. ( n -- )
: prime-found
  dup
  [ 2dup + max-value @ <= ] [ over + dup f swap results ! ] while
  drop drop ;

NB. ( n -- ? )
: prime? results @ ;

NB. ( -- )
: find-all-primes
  2
  [ dup max-value @ <= ] [ dup prime? [ dup prime-found ] when 1+ ] while
  drop ;

NB. ( -- )
: print-results
  1
  [ dup max-value @ <= ] [ dup prime? [ dup . ] when 1+ ] while
  drop ;

NB. ( n -- )
: find-all-primes-up-to
  max-value !
  initialise-results
  find-all-primes ;

NB. ( n -- )
: print-primes-up-to
  find-all-primes-up-to
  print-results ;
