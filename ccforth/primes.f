variable: max-value
variable: results

NB. ( -- )
: initialise-results
  max-value @
  1 {} [ [ 2dup >= ] dip swap ] [ [ dup 1+ swap ] dip t swap assoc ] while swap drop
  [ 1 f ] dip assoc
  results ! drop
  ;

NB. ( n -- )
: prime-found
  dup
  [ 2dup + max-value @ <= ] [ over + dup f results @ assoc drop ] while
  drop drop ;

NB. ( n -- ? )
: test-prime
  results @ swap get ;

NB. ( -- )
: find-all-primes
  2
  [ dup max-value @ <= ] [ dup test-prime [ dup prime-found ] when 1+ ] while
  drop ;

NB. ( -- )
: print-results
  1
  [ dup max-value @ <= ] [ dup results @ swap get [ dup . ] when 1+ ] while
  drop ;

NB. ( n -- )
: print-primes-up-to
  max-value !
  initialise-results
  find-all-primes
  print-results ;
