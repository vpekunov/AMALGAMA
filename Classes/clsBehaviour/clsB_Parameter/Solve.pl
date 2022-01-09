solve(ID,Group):-
  atom_concat(ID,'handled',IDHandled),
  !,
  (
   element(ID,'clsB_Parameter',_,_)->
     (
      predicate_property(external_pop(_),'dynamic'),external_pop(IDHandled)->
        position(ID,Left,Top),
        findall(_,delete_element(_),_),
        insert_element('JoinFromParams','clsB_Join','True','True','False',Left,Top,['Session'],['ByParams'],[],[]);
        (
         =(Group,ID),
         (predicate_property(prm_values(_),'dynamic'),prm_values(A)->
           write_to_atom(Values,A),
           calcNumTasks(A,NumTasks),
           number_atom(NumTasks,ANTasks),
           position(ID,Left,Top),
           insert_element('ForkByParams','clsB_Fork','True','True','False',Left,Top,['NumTasks','Session'],[ANTasks,'ByParams'],[],[]),
           atom_concat('fork_params(',Values,V),
           atom_concat(V,')',V1),
           !,
           plan_asserta(V1),
           retract(prm_values(A)),
           push_model_to_rededuce(IDHandled);
           true
         ),
         !,
         delete_element(ID)
        )
     );
     true
  ),
  !.

calcNumTasks(nil,1).
calcNumTasks(list(_,_,List,Next),Nall):-
  calcNumTasks(Next,N),
  length(List,N1),
  Nall is N*N1.
