dequote(S,C):-
  atom_concat('''',C1,S),
  atom_concat(C,'''',C1),
  !.

unique([],[]):-!.
unique([A|T],[A|T1]):-
  delete(T,A,L),
  unique(L,T1).

condition(Cond,ind(N)):-
  read_token_from_atom(Cond,N),
  number(N),
  number_atom(N,AN),
  =(Cond,AN),
  !.
condition(Cond,ceq('text()',Op)):-
  atom_concat('text()=',Op1,Cond),
  dequote(Op1,Op),
  !.
condition(Cond,ceq('text()',Op)):-
  atom_concat(Op1,'=text()',Cond),
  dequote(Op1,Op),
  !.
condition(Cond,cneq('text()',Op)):-
  atom_concat('text()!=',Op1,Cond),
  dequote(Op1,Op),
  !.
condition(Cond,cneq('text()',Op)):-
  atom_concat(Op1,'!=text()',Cond),
  dequote(Op1,Op),
  !.

parse_condition(XPath,C,Rest):-
  atom_concat('[',Cond,XPath),
  atom_concat(CL,CR,Cond),
  atom_concat(']',Rest,CR),
  condition(CL,C),
  !.
parse_condition(XPath,none,XPath):-!.
  
get_condition('..','..',none,''):-!.
get_condition('*','*',none,''):-!.
get_condition(XPath,'..',none,T):-
  atom_concat('..',T,XPath),
  atom_concat('/',_,T),
  !.
get_condition(XPath,'..',error,T):-
  atom_concat('..',T,XPath),
  !,
  fail.
get_condition(XPath,'*',C,T):-
  atom_concat('*',Rest,XPath),
  parse_condition(Rest,C,T),
  !.
get_condition(XPath,A,C,T):-
  read_token_from_atom(XPath,var(A)),
  atom_concat(A,Rest,XPath),
  parse_condition(Rest,C,T),
  !.
get_condition(XPath,_,_,_):-
  read_token_from_atom(XPath,punct(_)),
  !,
  fail.
get_condition(XPath,A,C,T):-
  read_token_from_atom(XPath,A),
  atom_concat(A,Rest,XPath),
  parse_condition(Rest,C,T),
  !.
get_condition(_,_,_,_):-
  !,
  fail.

parse('',[]):-!.
parse('/text()',[]):-!.
parse(XPath, [absp(A,C)|T]):-
  atom_concat('//',Rest,XPath),
  !,
  get_condition(Rest,A,C,Rest2),
  parse(Rest2,T),
  !.
parse(XPath, [relp(A,C)|T]):-
  atom_concat('/',Rest,XPath),
  get_condition(Rest,A,C,Rest2),
  parse(Rest2,T),
  !.

test_condition(M,ID,ceq('text()',B)):-
  var(M,ID,_,B,_),
  !.
test_condition(M,ID,cneq('text()',B)):-
  var(M,ID,_,A,_),
  \=(A,B),
  !.

filter_by_cond(_,L,none,L):-!.
filter_by_cond(_,[],_,[]):-!.
filter_by_cond(_,L,ind(N),[A]):-
  nth(N,L,A),
  !.
filter_by_cond(M,[H|T],C,[H|T1]):-
  test_condition(M,H,C),
  !,
  filter_by_cond(M,T,C,T1).
filter_by_cond(M,[_|T],C,L):-
  !,
  filter_by_cond(M,T,C,L).

ids_by_name_curs(_,[],_,[]):-!.
ids_by_name_curs(M,[ID|T],'*',[ID|T1]):-
  var(M,ID,_,_,_),
  !,
  ids_by_name_curs(M,T,'*',T1).
ids_by_name_curs(M,[ID|T],A,[ID|T1]):-
  var(M,ID,A,_,_),
  !,
  ids_by_name_curs(M,T,A,T1).
ids_by_name_curs(M,[_|T],A,T1):-
  !,
  ids_by_name_curs(M,T,A,T1).

recurse_ids(M,ID,'*',[ID|T]):-
  var(M,ID,_,_,Childs),
  !,
  ids_by_name_in_deep(M,Childs,'*',T).
recurse_ids(M,ID,A,[ID|T]):-
  var(M,ID,A,_,Childs),
  !,
  ids_by_name_in_deep(M,Childs,A,T).
recurse_ids(M,ID,A,T):-
  var(M,ID,_,_,Childs),
  !,
  ids_by_name_in_deep(M,Childs,A,T).

ids_by_name_in_deep(_,[],_,[]):-!.
ids_by_name_in_deep(M,[ID|T],A,IDs):-
  recurse_ids(M,ID,A,IDs1),
  ids_by_name_in_deep(M,T,A,IDs2),
  append(IDs1,IDs2,IDs).

irun(_,[],Cur,Cur):-!.
irun(M,[absp(A,C)|T],Cur,IDs):-
  var(M,Cur,_,_,Childs),
  ids_by_name_in_deep(M,Childs,A,Childs1),
  !,
  filter_by_cond(M,Childs1,C,Selected),
  run(M,T,Selected,IDs),
  !.
irun(M,[relp('..',none)|T],Cur,IDs):-
  var(M,Parent,_,_,Childs),
  member(Cur,Childs),
  !,
  run(M,T,[Parent],IDs),
  !.
irun(M,[relp(A,C)|T],Cur,IDs):-
  var(M,Cur,_,_,Childs),
  ids_by_name_curs(M,Childs,A,Childs1),
  !,
  filter_by_cond(M,Childs1,C,Selected),
  run(M,T,Selected,IDs),
  !.

run(_,_,[],[]):-!.
run(_,[],L,L):-!.
run(M,P,[Cur|CT],IDs):-
  irun(M,P,Cur,IDs1),
  run(M,P,CT,IDs2),
  append(IDs1,IDs2,IDs3),
  unique(IDs3,IDs),
  !.
run(M,P,[_|CT],IDs):-
  run(M,P,CT,IDs),
  !.

texts(_,[],[]):-!.
texts(M,[ID|T],[Text|T1]):-
  var(M,ID,_,Text,_),
  texts(M,T,T1).

gen_chars(0, []):-
  !.

gen_chars(N, [C|T]):-
  N1 is N-1,
  random(97, 123, R),
  char_code(C, R),
  gen_chars(N1, T),
  !.

randomid(N, S):-
  gen_chars(N, LS),
  atom_chars(S, LS),
  !.

xpath(M,XPath,Texts):-
  atom_concat(RXPath,'/text()',XPath),
  parse(RXPath,XP),
  var(M,Root,'root',_,_),
  !,
  run(M,XP,[Root],IDs),
  texts(M,IDs,Texts),
  !.

xpath(M,XPath,IDs):-
  parse(XPath,XP),
  var(M,Root,'root',_,_),
  !,
  run(M,XP,[Root],IDs),
  !.

init:-
  unlink('__db.pl'),
  asserta(ibf(_,-1,'')),
  asserta(iaf(_,-1,'')),
  asserta(chg(_,-1,'')),
  (file_exists('_db.pl'),
   consult('_db.pl'),db,!;
   true,!),
  asserta(db_predicates([])).

clear_db:-
  retractall(global_id(_)),
  retractall(global_trace(_)),
  retractall(db_predicates(_)),
  retractall(chg(_,_,_)),
  retractall(iaf(_,_,_)),
  retractall(ibf(_,_,_)),
  retractall(var(_,_,_,_,_)),
  !.

saveL([]):-!.
saveL([H|T]):-
  listing(H),
  saveL(T).

save(L):-
  retractall(db_predicates(_)),
  asserta(db_predicates(L)).

insert_before(M,ID,S):-
  assertz(ibf(M,ID,S)),
  !.

insert_after(M,ID,S):-
  asserta(iaf(M,ID,S)),
  !.

change(M,ID,S):-
  retractall(chg(M,ID,_)),
  asserta(chg(M,ID,S)),
  !.

write_log_tree(M,Cur):-
  ibf(M,Cur,S),
  write('<'),
  write(M),
  write(','),
  write(Cur),
  write(','),
  write(S),
  nl,
  fail.
write_log_tree(M,Cur):-
  chg(M,Cur,S),
  write('*'),
  write(M),
  write(','),
  write(Cur),
  write(','),
  write(S),
  nl,
  fail.
write_log_tree(M,Cur):-
  \+ chg(M,Cur,_),
  var(M,Cur,_,_,Childs),
  member(C,Childs),
  write_log_tree(M,C),
  fail.
write_log_tree(M,Cur):-
  iaf(M,Cur,S),
  write('>'),
  write(M),
  write(','),
  write(Cur),
  write(','),
  write(S),
  nl,
  fail.
write_log_tree(_,_):-!.

write_log(M):-
  var(M,Root,'root',_,_),
  write_log_tree(M,Root),
  !.
