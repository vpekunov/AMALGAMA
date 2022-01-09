init(ID,Phase,Solver):-
  element(ID,'clsE_dIrradiance',_,_),
  !,
  parameters(ID,1),
  parameter(ID,'Descriptors',_,Params),
  parse_string_list(Params,List),
  register_irradiances(ID,List),
  =(Solver,'null').

register_irradiances(_,[]):-
  !,
  fail.
register_irradiances(ID,[HPS]):-
  atom_chars(HP,HPS),
  atom_concat(RangeName,Rest0,HP), atom_concat('(',AfterBr,Rest0),
  !,
  atom_concat(Kind,Rest1,AfterBr),
  atom_concat(',',Rest2,Rest1), atom_concat(Prefix,')',Rest2),
  !,
  asserta(irradiance(ID,Prefix,RangeName)),
  !,
  (=('thermal',Kind) ->
    asserta(thermal(ID,RangeName));
    true
  ),
  !.
register_irradiances(ID,[HP|TagP]):-
  register_irradiances(ID,[HP]),
  register_irradiances(ID,TagP).
