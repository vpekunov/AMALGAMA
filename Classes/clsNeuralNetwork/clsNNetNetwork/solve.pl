solve(ID):-
  element(ID,'clsNNetNetwork',_,_),
  !,
  show(ID,Class,Name,Image),
  position(ID,Left,Top),
  parameter(ID, 'File', _, File0),
  parse_string_list(File0, [File1]), atom_chars(File, File1),
  parameter(ID, 'Inps', _, Inps0),
  parse_string_list(Inps0, [Inps1]), atom_chars(Inps, Inps1),
  parameter(ID, 'Out', _, Out0),
  parse_string_list(Out0, [Out1]), atom_chars(Out, Out1),
  parse_list(Inps, NInps, LInps),
  parameter(ID, 'nEpochs', _, NEpochs0),
  parse_string_list(NEpochs0, [NEpochs1]), atom_chars(NEpochs, NEpochs1),
  parameter(ID, 'alpha', _, Alpha0),
  parse_string_list(Alpha0, [Alpha1]), atom_chars(Alpha, Alpha1),
  parameter(ID, 'nu', _, Nu0),
  parse_string_list(Nu0, [Nu1]), atom_chars(Nu, Nu1),
  N0 is NInps + 1,
  parameter(ID, 'Neurons', _, Neurons0),
  parse_string_list(Neurons0, [Neurons1]), atom_chars(Neurons, Neurons1),
  parse_list(Neurons, NLayers, LNeurons),
  append([N0], LNeurons, L1),
  max_list(L1, NN),
  H is NN * 80,
  W is (NLayers + 3)*150,
  atom_concat(ID, '_DAT', DatID),
  atom_concat(ID, '_X', XBase),
  atom_concat(ID, '_Y', YID),
  atom_concat(ID, '_N', NBase),
  atom_concat(ID, '_Teacher', TID),
  DTop is Top + round((H-80)/2),
  insert_element(DatID,'clsNNetData',Class,Name,Image,Left,DTop,['File'],[File],[],['Inp','Out']),
  XLeft is Left + 150,
  XTop is Top + round((NN-(NInps+1))*80/2),
  insert_inputs(XBase, LInps, Class, Name, Image, XLeft, XTop, 80, DatID),
  YTop is XTop + NInps*80,
  insert_element(YID,'clsNNetOutput',Class,Name,Image,XLeft,YTop,['Num','NNum','Normalize'],[Out,'0','Yes'],['Data'],['Out']),
  insert_link(DatID, 'Out', YID, 'Data', 'clBlue'),
  LLeft is XLeft + 150,
  insert_layers(NBase, NN, NLayers, LNeurons, Class, Name, Image, LLeft, Top, 80),
  insert_nlinks(XBase, NInps, NBase, NLayers, LNeurons),
  TLeft is LLeft + NLayers*150,
  insert_element(TID,'clsNNetTeacher',Class,Name,Image,TLeft,YTop,['nEpochs','alpha','nu','TapeF','TapeB'],[NEpochs,Alpha,Nu,'',''],['Inp','Out'],[]),
  last(LNeurons, NLast),
  LLast is NLayers - 1,
  number_atom(LLast, LL),
  atom_concat(NBase, LL, LLL),
  make_tlinks(NLast, LLL, TID),
  insert_link(YID, 'Out', TID, 'Out', 'clYellow'),
  delete_element(ID),
  !.

insert_inputs(XBase, LInps, Class, Name, Image, XLeft, XTop, H, DatID):-
  asserta(counter(0)),
  member(NC,LInps),
  counter(C),
  retractall(counter(_)),
  XTop1 is XTop + C*H,
  number_atom(C, AC),
  atom_concat(XBase, AC, XID),
  number_atom(C, CC),
  number_atom(NC, NCC),
  insert_element(XID,'clsNNetInput',Class,Name,Image,XLeft,XTop1,['Num','NNum','Normalize'],[NCC,CC,'Yes'],['Data'],['Out']),
  insert_link(DatID, 'Inp', XID, 'Data', 'clRed'),
  C1 is C+1,
  asserta(counter(C1)),
  fail.
insert_inputs(_, _, _, _, _, _, _, _, _):-
  !,
  retractall(counter(_)).

insert_layers(NBase, NN, NLayers, LNeurons, Class, Name, Image, LLeft, Top, H):-
  asserta(layer(0)),
  member(NNeurons, LNeurons),
  layer(L),
  retractall(layer(_)),
  number_atom(L, LL),
  atom_concat(NBase, LL, NBase1),
  NLeft is LLeft + L*150,
  NTop is Top + round((NN-NNeurons)*80/2),
  insert_neurons(NBase1, NNeurons, Class, Name, Image, NLeft, NTop, H),
  L1 is L+1,
  asserta(layer(L1)),
  fail.
insert_layers(_, _, _, _, _, _, _, _, _, _):-
  retractall(layer(_)),
  !.

insert_neurons(NBase1, NNeurons, Class, Name, Image, NLeft, NTop, H):-
  NNeurons1 is NNeurons-1,
  for(N, 0, NNeurons1),
    number_atom(N, NN),
    atom_concat(NBase1, NN, NID),
    NTop1 is NTop + N*H,
    insert_element(NID,'clsNNetNeuron',Class,Name,Image,NLeft,NTop1,['Num'],[NN],['Inp'],['Out']),
  fail.
insert_neurons(_, _, _, _, _, _, _, _):-
  !.

insert_nlinks(XBase, NInps, NBase, NLayers, [N0|T]):-
  atom_concat(NBase, '0', NBase0),
  make_links(NInps, XBase, N0, NBase0),
  asserta(counter(0)),
  append(_, [N,N1|_], [N0|T]),
    counter(C),
    retractall(counter(_)),
    C1 is C+1,
    number_atom(C, NN),
    atom_concat(NBase, NN, NBase1),
    number_atom(C1, NN1),
    atom_concat(NBase, NN1, NBase2),
    make_links(N, NBase1, N1, NBase2),
    asserta(counter(C1)),
  fail.
insert_nlinks(_, _, _, _, _):-
  retractall(counter(_)),
  !.

make_links(N1, Pref1, N2, Pref2):-
  N1p is N1-1,
  for(A1, 0, N1p),
    N2p is N2-1,
    for(A2, 0, N2p),
      number_atom(A1, NA1),
      number_atom(A2, NA2),
      atom_concat(Pref1, NA1, ID1),
      atom_concat(Pref2, NA2, ID2),
      element(ID1,_,_,_),
      element(ID2,_,_,_),
      insert_link(ID1, 'Out', ID2, 'Inp', 'clLime'),
  fail.
make_links(_, _, _, _):-
  !.

make_tlinks(NLast, LLL, TID):-
  NLast1 is NLast-1,
  for(A, 0, NLast1),
    number_atom(A, NA),
    atom_concat(LLL, NA, ID1),
    element(ID1,_,_,_),
    insert_link(ID1, 'Out', TID, 'Inp', 'clBlack'),
  fail.
make_tlinks(_, _, _):-
  !.

parse_list('', 0, []):-!.
parse_list(S, 1, [NS]):-
  atom_chars(S, L),
  \+ member(' ', L),
  number_atom(NS, S),
  !.
parse_list(S, N, [NA|T]):-
  atom_concat(A, B, S),
  atom_concat(' ', Rest, B),
  number_atom(NA, A),
  ltrim(Rest, Rest1),
  !,
  parse_list(Rest1, N1, T),
  N is N1+1,
  !.

ltrim(A, B):-
  atom_chars(A, S1),
  ltrim_chars(S1, S2),
  atom_chars(B, S2).

ltrim_chars([], ''):-!.
ltrim_chars([' '|T], T1):-
  ltrim_chars(T, T1).
ltrim_chars([H|T], [H|T]):-
  \+ =(H, ' ').
