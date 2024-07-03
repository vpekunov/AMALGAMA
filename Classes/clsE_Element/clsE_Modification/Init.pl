init(ID,Calc,K,S,Bound,Solver):-
  element(ID,'clsE_Modification',_,_),
  !,
  i_contact(ID,'Calc'),
  i_link(ID,'Calc',SubstID,_,_),
  parameter(SubstID,'Substance',_,SubstName),
  asserta(modification(SubstName,ID)).
