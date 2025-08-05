NB. turtle (and extraTurtle) bindings

NB. load the api
" /apis/extraTurtle" 1 " os" " loadAPI" luacall [ " Failed to load extraTurtle API" . ] unless

NB. vanilla turtle bindings
: turtle.craft 0 " turtle" " craft" luacall ;
: turtle.ncraft 1 " turtle" " craft" luacall ;
: turtle.forward 0 " turtle" " forward" luacall ;
: turtle.back 0 " turtle" " back" luacall ;
: turtle.up 0 " turtle" " up" luacall ;
: turtle.down 0 " turtle" " down" luacall;
: turtle.turnLeft 0 " turtle" " turnLeft" luacall ;
: turtle.turnRight 0 " turtle" " turnRight" luacall ;
: turtle.select 1 " turtle" " select" luacall ;
: turtle.getSelectedSlot 0 " turtle" " getSelectedSlot" luacall ;
: turtle.getItemCount 0 " turtle" " getItemCount" luacall ;
: turtle.getItemCountSlot 1 " turtle" " getItemCount" luacall ;
: turtle.getItemSpace 0 " turtle" " getItemSpace" luacall ;
: turtle.getItemSpaceSlot 1 " turtle" " getItemSpace" luacall ;
: turtle.getItemDetail 0 " turtle" " getItemDetail" luacall ;
: turtle.getItemDetailSlot 1 " turtle" " getItemDetail" luacall ;
: turtle.equipLeft 0 " turtle" " equipLeft" luacall ;
: turtle.equipRight 0 " turtle" " equipRight" luacall ;
: turtle.attack 0 " turtle" " attack" luacall ;
: turtle.attackSide 1 " turtle" " attack" luacall ;
: turtle.attackUp 0 " turtle" " attackUp" luacall ;
: turtle.attackUpSide 1 " turtle" " attackUp" luacall ;
: turtle.attackDown 0 " turtle" " attackDown" luacall ;
: turtle.attackDownSide 1 " turtle" " attackDown" luacall ;
: turtle.dig 0 " turtle" " dig" luacall ;
: turtle.digSide 1 " turtle" " dig" luacall ;
: turtle.digUp 0 " turtle" " digUp" luacall ;
: turtle.digUpSide 1 " turtle" " digUp" luacall ;
: turtle.digDown 0 " turtle" " digDown" luacall ;
: turtle.digDownSide 1 " turtle" " digDown" luacall ;
: turtle.place 0 " turtle" " place" luacall ;
: turtle.placeSignText 1 " turtle" " place" luacall ;
: turtle.placeUp 0 " turtle" " placeUp" luacall ;
: turtle.placeDown 0 " turtle" " placeDown" luacall ;
: turtle.detect 0 " turtle" " detect" luacall ;
: turtle.detectUp 0 " turtle" " detectUp" luacall ;
: turtle.detectDown 0 " turtle" " detectDown" luacall ;
: turtle.inspect 0 " turtle" " inspect" luacall ;
: turtle.inspectUp 0 " turtle" " inspectUp" luacall ;
: turtle.inspectDown 0 " turtle" " inspectDown" luacall ;
: turtle.compare 0 " turtle" " compare" luacall ;
: turtle.compareUp 0 " turtle" " compareUp" luacall ;
: turtle.compareDown 0 " turtle" " compareDown" luacall ;
: turtle.dropAll 0 " turtle" " drop" luacall ;
: turtle.dropN 1 " turtle" " drop" luacall ;
: turtle.dropUpAll 0 " turtle" " dropUp" luacall ;
: turtle.dropUpN 1 " turtle" " dropUp" luacall ;
: turtle.dropDownAll 0 " turtle" " dropDown" luacall ;
: turtle.dropDownN 1 " turtle" " dropDown" luacall ;
: turtle.suckAll 0 " turtle" " suck" luacall ;
: turtle.suckN 1 " turtle" " suck" luacall ;
: turtle.suckUpAll 0 " turtle" " suckUp" luacall ;
: turtle.suckUpN 1 " turtle" " suckUp" luacall ;
: turtle.suckDownAll 0 " turtle" " suckDown" luacall ;
: turtle.suckDownN 1 " turtle" " suckDown" luacall ;
: turtle.refuel 0 " turtle" " refuel" luacall ;
: turtle.refuelN 1 " turtle" " refuel" luacall ;
: turtle.getFuelLevel 0 " turtle" " getFuelLevel" luacall ;
: turtle.getFuelLimit 0 " turtle" " getFuelLimit" luacall ;
: turtle.transferTo 1 " turtle" " transferTo" luacall ;
: turtle.transferNTo 2 " turtle" " transferTo" luacall ;

NB. extraTurtle bindings
: extraTurtle.refuelToMin 1 " extraTurtle" " refuelToMin" luacall ;
: extraTurtle.tolerantMove 1 " extraTurtle" " tolerantMove" luacall ;
: extraTurtle.tolerantMoveN 2 " extraTurtle" " tolerantMove" luacall ;
: extraTurtle.find 1 " extraTurtle" " find" luacall ;
