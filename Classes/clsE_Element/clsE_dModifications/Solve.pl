solve(ID,Phase,Solver):-
  element(ID,'clsE_dModifications',_,_),
  !,
  show(ID,Class,Name,Image),
  position(ID,Left,Top),
  parameters(ID,1),
  parameter(ID,'Modificators',_,Params0),
  inet_to_str(Params0,Params),
  i_contact(ID,'Phase'),
  i_link(ID,'Phase',PhaseID,PhaseCID,_),
  o_link(PhaseID,PhaseCID,ID,'Phase',ColorI,_,_,_),
  o_contact(ID,'Solver'),
  o_link(ID,'Solver',SolverID,SolverCID,ColorO,_,_,_),
  i_link(SolverID,SolverCID,ID,'Solver',_),
  parse_string_list(Params,List),
  expand_modifications(ID,Class,Name,Image,Left,Top,List,PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO),
  delete_element(ID),
  =(Solver,'null').

expand_modificator(BaseID,Class,Name,Image,Left,Top,PrmL,PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO):-
  atom_chars(Prm,PrmL),
  atom_concat(SubstName,Rest0,Prm), atom_concat('(',Rest1,Rest0), atom_concat(InBraces,')',Rest1),
  !,
  atom_concat(BaseID,'_',Base1), atom_concat(Base1,SubstName,SName),
  atom_concat('Eq',SName,EqName),
  atom_concat('K_',SName,KName),
  insert_element(SName,'clsE_Substance',Class,Name,Image,Left,Top,['Substance'],[SubstName],['Phase'],['Calc']),
  LeftE is Left+100,
  insert_element(EqName,'clsE_Modification',Class,Name,Image,LeftE,Top,[],[],['K','Calc'],['Solver']),
  LeftK is Left-100,
  insert_element(KName,'clsE_Function',Class,Name,Image,LeftK,Top,['Expression'],[InBraces],[],['Val']),
  insert_link(SName,'Calc',EqName,'Calc','clBlack'),
  insert_link(KName,'Val',EqName,'K','clBlack'),
  insert_link(PhaseID,PhaseCID,SName,'Phase',ColorI),
  insert_link(EqName,'Solver',SolverID,SolverCID,ColorO),
  !.

expand_modifications(_,_,_,_,_,_,[],_,_,_,_,_,_):-
  !,
  fail.
expand_modifications(BaseID,Class,Name,Image,Left,Top,[HP],PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO):-
  expand_modificator(BaseID,Class,Name,Image,Left,Top,HP,PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO),
  !.
expand_modifications(BaseID,Class,Name,Image,Left,Top,[HP|TagP],PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO):-
  expand_modificator(BaseID,Class,Name,Image,Left,Top,HP,PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO),
  Left1 is Left+10, Top1 is Top+10,
  expand_modifications(BaseID,Class,Name,Image,Left1,Top1,TagP,PhaseID,PhaseCID,SolverID,SolverCID,ColorI,ColorO).
