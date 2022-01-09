init(ID,Phase,Solver):-
  element(ID,'clsE_dModifications',_,_),
  !,
  parameters(ID,1),
  parameter(ID,'Modificators',_,Params),
  parse_string_list(Params,List),
  register_modificators(ID,List),
  =(Solver,'null').

register_modificators(_,[]):-
  !,
  fail.
register_modificators(ID,[HPS]):-
  atom_chars(HP,HPS),
  atom_concat(SubstName,Rest0,HP), atom_concat('(',_,Rest0),
  !,
  atom_concat(ID,'_',Base1), atom_concat(Base1,SubstName,SName),
  atom_concat('Eq',SName,EqName),
  asserta(modification(SubstName,EqName)),
  !.
register_modificators(ID,[HP|TagP]):-
  register_modificators(ID,[HP]),
  register_modificators(ID,TagP).
