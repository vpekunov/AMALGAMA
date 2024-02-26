init(ID,Group):-
  =(Group,ID),
  parameter(ID,'Val',_,Val00),
  parse_string_list(Val00, [Val01]), atom_chars(Val0, Val01),
  inet_to_str(Val0,Val),
  val_list(Val,ThisVal),
  (predicate_property(prm_values(_),'dynamic'),prm_values(A)->
    retract(prm_values(A));
    =(A,nil)
  ),
  write_term_to_atom(IDA,ID,[quoted(true)]),
  asserta(prm_values(list(IDA,1,ThisVal,A))),
  !.

val_list(Val,List):-
  atom_concat('"',Rest,Val),
  atom_concat(Inside,'"',Rest),
  !,
  val_get_list(Inside,List),
  !.
val_list(Val,List):-
  val_get_list(Val,List).

val_get_list(Val,[H|Tag]):-
  atom_concat(H,Rest,Val),
  atom_concat(',',Rest1,Rest),
  !,
  val_get_list(Rest1,Tag).
val_get_list(Val,[Val]):-
  !.
