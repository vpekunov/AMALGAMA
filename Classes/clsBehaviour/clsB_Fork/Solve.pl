solve(ID):-
  parameter(ID,'Session',_,SessionID0),
  parse_string_list(SessionID0, [SessionID1]), atom_chars(SessionID, SessionID1),
  parameter(ID,'NumTasks',_,NumTasks_0),
  parse_string_list(NumTasks_0, [NumTasks_1]), atom_chars(NumTasks_, NumTasks_1),
  number_atom(NumTasks,NumTasks_),
  (predicate_property(spawned(_,_),'dynamic'),spawned(SessionID,TaskID)->
    true;
    =(TaskID,0),
    open_session(SessionID,NumTasks),
    push_model_to_rededuce(nil)
  ),
  mark_forked(SessionID,TaskID),
  NewTaskID is TaskID+1,
  !,
  (<(NewTaskID,NumTasks)->
    atom_concat('spawned(''',SessionID,A1),
    atom_concat(A1,''',',A2),
    number_atom(NewTaskID,NewTaskID_),
    atom_concat(A2,NewTaskID_,A3),
    atom_concat(A3,')',NewFact),
    plan_asserta(NewFact),
    (predicate_property(fork_params(_),'dynamic'),fork_params(Params)->
      (get_inc_params(true,Params,NewParams)->
         atom_concat('fork_params(',NewParams,V), atom_concat(V,')',V1),
         plan_asserta(V1);
         true
      );
      true
    );
    pop_model_from_rededuce(nil)
  ),
  !,
  delete_element(ID).

get_inc_params(true,nil,_):-
  !,
  fail.
get_inc_params(false,nil,'nil'):-
  !.
get_inc_params(Inc,list(ID,Num,List,Next),OutParams):-
  atom_concat('list(''',ID,V1), atom_concat(V1,''',',V2),
  NumNext is Num+1,
  !,
  (
   =(Inc,true)->
     (
      nth(NumNext,List,_)->
       =(Num1,NumNext), =(NextInc,false);
       =(Num1,1), =(NextInc,true)
     );
     =(NextInc,false),
     =(Num1,Num)
  ),
  number_atom(Num1,NumA), atom_concat(V2,NumA,V3), atom_concat(V3,',',V4),
  write_term_to_atom(ListA,List,[quoted(true)]), atom_concat(V4,ListA,V5), atom_concat(V5,',',V6),
  !,
  get_inc_params(NextInc,Next,OutNext),
  !,
  atom_concat(V6,OutNext,V7), atom_concat(V7,')',OutParams),
  !.
