init(ID,Model,SourceK,SourceS,Ro,Nu,T,U,Define):-
  element(ID,'clsE_Phase',_,_),
  !,
  (
   o_contact(ID,'T'),o_link(ID,'T',TID,_,_,_,_,_)->
   asserta(temperature(TID));
   true
  ).
