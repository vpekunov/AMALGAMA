write_xml_header:-
  write('<?xml version="1.0" encoding="utf-8"?>'),nl,
  write('<!DOCTYPE System ['),nl,
  write('<!ELEMENT System (Elements)>'),nl,
  write('<!ATTLIST System'),nl,
  write('Lang CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Elements (Element*)>'),nl,
  write('<!ATTLIST Elements'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Element (Show,Position,Parameters,InternalInputs,InternalOutputs,PublishedInputs,PublishedOutputs,InputLinks,OutputLinks)>'),nl,
  write('<!ATTLIST Element'),nl,
  write('ClassID CDATA #REQUIRED'),nl,
  write('ParentID CDATA #REQUIRED'),nl,
  write('ID ID #REQUIRED'),nl,
  write('Permanent (True | False) #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Show EMPTY>'),nl,
  write('<!ATTLIST Show'),nl,
  write('Class (True | False) #REQUIRED'),nl,
  write('Name (True | False) #REQUIRED'),nl,
  write('Image (True | False) #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Position EMPTY>'),nl,
  write('<!ATTLIST Position'),nl,
  write('Left CDATA #REQUIRED'),nl,
  write('Top CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Parameters (Parameter*)>'),nl,
  write('<!ATTLIST Parameters'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Parameter (#PCDATA | EMPTY)*>'),nl,
  write('<!ATTLIST Parameter'),nl,
  write('ID CDATA #REQUIRED'),nl,
  write('Indent CDATA #IMPLIED'),nl,
  write('>'),nl,
  write('<!ELEMENT InternalInputs (iContact*)>'),nl,
  write('<!ATTLIST InternalInputs'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT InternalOutputs (iContact*)>'),nl,
  write('<!ATTLIST InternalOutputs'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT iContact EMPTY>'),nl,
  write('<!ATTLIST iContact'),nl,
  write('ID CDATA #REQUIRED'),nl,
  write('ElementID IDREF #REQUIRED'),nl,
  write('ContID CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT PublishedInputs (pContact*)>'),nl,
  write('<!ATTLIST PublishedInputs'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT PublishedOutputs (pContact*)>'),nl,
  write('<!ATTLIST PublishedOutputs'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT pContact EMPTY>'),nl,
  write('<!ATTLIST pContact'),nl,
  write('ID CDATA #REQUIRED'),nl,
  write('PublicID CDATA #REQUIRED'),nl,
  write('PublicName CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT InputLinks (Contact*)>'),nl,
  write('<!ELEMENT OutputLinks (Contact*)>'),nl,
  write('<!ELEMENT Contact (Link*)>'),nl,
  write('<!ATTLIST Contact'),nl,
  write('ID CDATA #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Link (Points?)>'),nl,
  write('<!ATTLIST Link'),nl,
  write('ElementID IDREF #REQUIRED'),nl,
  write('ContID CDATA #REQUIRED'),nl,
  write('Color CDATA #IMPLIED'),nl,
  write('Informational (True | False) #REQUIRED'),nl,
  write('>'),nl,
  write('<!ELEMENT Points (#PCDATA | EMPTY)*>'),nl,
  write('<!ATTLIST Points'),nl,
  write('NumItems CDATA #REQUIRED'),nl,
  write('>'),nl,
  write(']>'), nl.

open_session(SessionID,NumTasks):-
  telling(TELL),
  told,
  atom_concat('_',SessionID,A1),
  atom_concat(A1,'.session',File),
  tell(File),
  write(NumTasks),nl,
  told,
  tell(TELL).

write_fork_params(nil):-
  !.
write_fork_params(list(PrmID,N,List,Next)):-
  nth(N,List,Val),
  write('$'),write(PrmID),write('='),write('"'),write(Val),write('";'),nl,
  write_fork_params(Next).

mark_forked(SessionID,TaskID):-
  telling(TELL),
  told,
  tell('_.fork'),
  write(SessionID),nl,
  write(TaskID),nl,
  told,
  (
   predicate_property(fork_params(_),'dynamic'),fork_params(Params)->
     tell('_vars.php3'),
     write('<?php'),nl,
     write_fork_params(Params),
     write('?>'),nl,
     told;
     true
  ),
  tell(TELL).

push_model_to_rededuce(Prm):-
  telling(TELL),
  told,
  append('_.stack'),
  filename(FName),
  write_term(FName,[quoted(true)]),write(' '),write_term(Prm,[quoted(true)]),nl,
  told,
  tell(TELL).

read_token_s(T):-
  read_token(T1),
  (
   =(T1, string(T0))->
    =(T, T0);
    =(T, T1)
  ).

rewrite_except_last(CurName,CurPrm,Prm):-
  (read_token_s(Next)->
   (
    =(Next,punct(end_of_file))->
     =(Prm,end_of_file);
     read_token_s(Prm1),
     (
      =(CurName,'')->
        true;
        write_term(CurName,[quoted(true)]),write(' '),write_term(CurPrm,[quoted(true)]),nl
     ),
     rewrite_except_last(Next,Prm1,Prm2),
     (
      =(Prm2,end_of_file)->
       =(Prm,Prm1);
       =(Prm,Prm2)
     )
   )
  ),
  !.

get_model_last(FName,Prm):-
  (read_token_s(FNameThis)->
   (
    =(FNameThis,punct(end_of_file))->
     =(Prm,end_of_file);
     read_token_s(Prm1),
     get_model_last(FName_,Prm2),
     (
      =(Prm2,end_of_file)->
       =(Prm,Prm1),=(FName,FNameThis);
       =(Prm,Prm2),=(FName,FName_)
     )
   )
  ),
  !.

pop_model_from_rededuce(Prm):-
  file_exists('_.stack')->
    seeing(SEE),
    seen,
    see('_.stack'),
    telling(TELL),
    told,
    tell('_.newstack'),
    rewrite_except_last('','',Prm),
    told,
    tell(TELL),
    seen,
    see(SEE),
    unlink('_.stack'),
    (
     \=(Prm,end_of_file)->
       rename_file('_.newstack','_.stack')
    );
    =(Prm,end_of_file).

top_model_rededuce(FName,Prm):-
  seeing(SEE),
  seen,
  file_exists('_.stack'),
  see('_.stack'),
  get_model_last(FName,Prm),
  seen,
  see(SEE).

plan_asserta(Pred):-
  (
   file_exists('_base.pl')->
     =(Prefix,'');
     =(Prefix,'rededuce:-')
  ),
  telling(TELL),
  told,
  append('_base.pl'),
  write(Prefix),write('asserta('),write(Pred),write('),'),nl,
  told,
  tell(TELL).
  
write_attrs([],[]).
write_attrs([H|Tag],[H1|Tag1]):-
  write(' '), write(H), write('="'), write(H1), write('"'),
  write_attrs(Tag,Tag1).

write_end_tag(true):-
  write('/>').

write_end_tag(false):-
  write('>').

write_tag(Shift,Name,Attrs,Vals,Closed):-
  write(Shift), write('<'), write(Name),
  write_attrs(Attrs,Vals),
  write_end_tag(Closed).

begin_tag(Shift,Name,Attrs,Vals):-
  write_tag(Shift,Name,Attrs,Vals,false).

end_tag(Shift,Name):-
  write(Shift), write('</'), write(Name), write('>').

count_elements(N):-
  predicate_property(element(_,_,_,_),dynamic),
  findall(id,element(_,_,_,_),L),
  length(L,N),
  !.
count_elements(0):-
  predicate_property(element(_,_,_,_),dynamic)->(fail,!) ; !.

count_parameters(ID,N):-
  predicate_property(parameter(_,_,_,_),dynamic),
  findall(id,parameter(ID,_,_,_),L),
  length(L,N),
  !.
count_parameters(_,0):-
  predicate_property(parameter(_,_,_,_),dynamic)->(fail,!) ; !.

count_i_links(ID,CID,N):-
  predicate_property(i_link(_,_,_,_,_),dynamic),
  findall(id,i_link(ID,CID,_,_,_),L),
  length(L,N),
  !.
count_i_links(_,_,0):-
  predicate_property(i_link(_,_,_,_,_),dynamic)->(fail,!) ; !.

count_o_links(ID,CID,N):-
  predicate_property(o_link(_,_,_,_,_,_,_,_),dynamic),
  findall(id,o_link(ID,CID,_,_,_,_,_,_),L),
  length(L,N),
  !.
count_o_links(_,_,0):-
  predicate_property(o_link(_,_,_,_,_,_,_,_),dynamic)->(fail,!) ; !.

count_items_4(ID,Predicat,N):-
  =..(PP,[Predicat,ID,_,_,_]),
  functor(P,Predicat,4),
  predicate_property(P,dynamic),
  findall(cid,PP,L),
  length(L,N),
  !.
count_items_4(_,Predicat,0):-
  functor(P,Predicat,4),
  predicate_property(P,dynamic)->(fail,!) ; !.

count_io_contacts(ID,Predicat,N):-
  functor(P,Predicat,2),
  predicate_property(P,dynamic),
  =..(PP,[Predicat,ID,_]),
  findall(cid,PP,L),
  length(L,N),
  !.
count_io_contacts(_,Predicat,0):-
  functor(P,Predicat,2),
  predicate_property(P,dynamic)->(fail,!) ; !.

replace_one_str(S,H,N,Result):-
  number_atom(N,NC), atom_concat('$',NC,Item),
  (
   (atom_concat(Part1,After,S),atom_concat(Before,Item,Part1)) ->
    (
     replace_one_str(After,H,N,Last),
     atom_concat(Before,H,Part11),
     atom_concat(Part11,Last,Result),
     !
    );
    =(Result,S)
  ).

replace_all_str(S,[],_,S):-
  !.
replace_all_str(S,[H|Tag],N,Result):-
  replace_one_str(S,H,N,AfterReplace),
  N1 is N+1,
  replace_all_str(AfterReplace,Tag,N1,Result).

str_replace(S,L,Result):-
  replace_all_str(S,L,1,Result).

string_replace(S,From,To,Out):-
  atom_concat(Part1,Rest,S),
  atom_concat(X,From,Part1),
  !,
  atom_concat(X,To,NewStr),
  !,
  string_replace(Rest,From,To,S1),
  atom_concat(NewStr,S1,Out),
  !.
string_replace(S,_,_,S):-
  !.

inet_to_str(In,Out):-
  string_replace(In,'&apos;','''',Out0),
  string_replace(Out0,'&quot;','"',Out1),
  string_replace(Out1,'&lt;','<',Out2),
  string_replace(Out2,'&gt;','>',Out3),
  string_replace(Out3,'&amp;','&',Out).

parse_before(_,[],[],[]):-!.
parse_before(Sign,[Sign|Rest],Rest,[]):-!.
parse_before(Sign,[A|Tag],Rest,Str):-
  parse_before(Sign,Tag,Rest,S1),
  append([A],S1,Str).

parse_next_line([],[]):-
  !.
parse_next_line([','|Tag],L):-
  !,
  parse_char_list(Tag,L).

parse_char_list([],[]):-
  !.
parse_char_list(['"'|Tag],[H|T]):-
  !,
  parse_before('"',Tag,Rest,H),
  parse_next_line(Rest,T).
parse_char_list(L,[H|Tag]):-
  !,
  parse_before(',',L,Rest,H),
  parse_char_list(Rest,Tag).

% "xxxxxxxxxxx"
parse_char_list_any(['"'|Tag],[List]):-
  append(L0,['"'|L1],Tag),
  append(L0,L1,List),
  \+ member('"', List),
  !.
% "xxxx","yyyy"...
parse_char_list_any(['"'|Tag],List):-
  !,
  parse_char_list(['"'|Tag],List).
% xxxxxxxxx
parse_char_list_any(L,[L]):-
  !.

parse_string_list('',[]):-!.
parse_string_list(Val,List):-
  atom_chars(Val,L),
  parse_char_list_any(L,List).

convert_string_list(L, L1):-
  parse_string_list(L, LL),
  concat_string_list(LL, '\n', L1).

concat_string_list([], _, ''):-
  !.
concat_string_list([H|Tag], Delim, A):-
  atom_chars(HH, H),
  atom_concat(HH, Delim, A1),
  concat_string_list(Tag, Delim, A2),
  !,
  atom_concat(A1, A2, A),
  !.

write_list([]):-
  !.
write_list([H|Tag]):-
  write(H),
  write_list(Tag),
  !.

write_strings1([]):-
  !.
write_strings1([H|Tag]):-
  write_list(H), nl,
  write_strings1(Tag).

write_strings([H]):-
  write_list(H),
  !.
write_strings(L):-
  write_strings1(L),
  !.

write_string_list(L,N):-
  parse_string_list(L,List),
  length(List,N),
  write_strings(List),
  !.

write_points(Prefix,0,_):-
  write_tag(Prefix,'Points',['NumItems'],[0],true), nl,
  !.
write_points(Prefix,N,Points):-
  begin_tag(Prefix,'Points',['NumItems'],[N]),
   write(Points),
  end_tag('','Points'), nl,
  !.

write_o_link(Prefix,ID1,CID1,Color,Info,N,Points):-
  begin_tag(Prefix,'Link',['ElementID','ContID','Color','Informational'],[ID1,CID1,Color,Info]), nl,
   atom_concat(Prefix,' ',Prefix1),
   write_points(Prefix1,N,Points),
  end_tag(Prefix,'Link'), nl,
  !.

write_o_links_enum(Prefix,ID,CID):-
  o_link(ID,CID,ID1,CID1,Color,Info,NP,Points),
  write_o_link(Prefix,ID1,CID1,Color,Info,NP,Points),
  fail.
write_o_links_enum(_,_,_):-
  !.

write_o_contact(Prefix,ID,CID):-
  count_o_links(ID,CID,0),
  !,
  write_tag(Prefix,'Contact',['ID'],[CID],true), nl.
write_o_contact(Prefix,ID,CID):-
  count_o_links(ID,CID,_),
  begin_tag(Prefix,'Contact',['ID'],[CID]), nl,
   atom_concat(Prefix,' ',Prefix1),
   write_o_links_enum(Prefix1,ID,CID),
  end_tag(Prefix,'Contact'), nl.

write_o_contacts_enum(Prefix,ID):-
  o_contact(ID,CID),
  write_o_contact(Prefix,ID,CID),
  fail.
write_o_contacts_enum(_,_):-
  !.

write_o_links(Prefix,ID):-
  count_io_contacts(ID,'o_contact',0),
  !,
  write_tag(Prefix,'OutputLinks',[],[],true), nl.
write_o_links(Prefix,ID):-
  count_io_contacts(ID,'o_contact',_),
  begin_tag(Prefix,'OutputLinks',[],[]), nl,
   atom_concat(Prefix,' ',Prefix1),
   write_o_contacts_enum(Prefix1,ID),
  end_tag(Prefix,'OutputLinks'), nl.

write_i_links_enum(Prefix,ID,CID):-
  i_link(ID,CID,ID1,CID1,Info),
  write_tag(Prefix,'Link',['ElementID','ContID','Informational'],[ID1,CID1,Info],true), nl,
  fail.
write_i_links_enum(_,_,_):-
  !.

write_i_contact(Prefix,ID,CID):-
  count_i_links(ID,CID,0),
  !,
  write_tag(Prefix,'Contact',['ID'],[CID],true), nl.
write_i_contact(Prefix,ID,CID):-
  count_i_links(ID,CID,_),
  begin_tag(Prefix,'Contact',['ID'],[CID]), nl,
   atom_concat(Prefix,' ',Prefix1),
   write_i_links_enum(Prefix1,ID,CID),
  end_tag(Prefix,'Contact'), nl.

write_i_contacts_enum(Prefix,ID):-
  i_contact(ID,CID),
  write_i_contact(Prefix,ID,CID),
  fail.
write_i_contacts_enum(_,_):-
  !.

write_i_links(Prefix,ID):-
  count_io_contacts(ID,'i_contact',0),
  !,
  write_tag(Prefix,'InputLinks',[],[],true), nl.
write_i_links(Prefix,ID):-
  count_io_contacts(ID,'i_contact',_),
  begin_tag(Prefix,'InputLinks',[],[]), nl,
   atom_concat(Prefix,' ',Prefix1),
   write_i_contacts_enum(Prefix1,ID),
  end_tag(Prefix,'InputLinks'), nl.

write_contacts_enum(Prefix,ID,Predicat,Tag,Attr1,Attr2):-
  =..(PP,[Predicat,ID,CID,Val1,Val2]),
  PP,
  write_tag(Prefix,Tag,['ID',Attr1,Attr2],[CID,Val1,Val2],true), nl,
  fail.
write_contacts_enum(_,_,_,_,_,_):-
  !.

write_contacts(Prefix,ID,Tag,Predicat,_,_,_):-
  count_items_4(ID,Predicat,0),
  !,
  write_tag(Prefix,Tag,['NumItems'],[0],true), nl.
write_contacts(Prefix,ID,Tag,Predicat,CTag,Attr1,Attr2):-
  count_items_4(ID,Predicat,N),
  begin_tag(Prefix,Tag,['NumItems'],[N]), nl,
   atom_concat(Prefix,' ',Prefix1),
   write_contacts_enum(Prefix1,ID,Predicat,CTag,Attr1,Attr2),
  end_tag(Prefix,Tag), nl.

write_parameter(Prefix,ID,Indent,Val):-
  begin_tag(Prefix,'Parameter',['ID','Indent'],[ID,Indent]),
  write_string_list(Val,N),
  (
   \+ =(N,1)->
    =(PREF,'');
    (
     (atom_chars(Val,L),member('\n',L))->
       =(PREF,'\n');
       =(PREF,'')
    )
  ),
  end_tag(PREF,'Parameter'), nl.

write_parameters_enum(Prefix,ID):-
  parameter(ID,Name,Indent,Val),
  write_parameter(Prefix,Name,Indent,Val),
  fail.
write_parameters_enum(_,_):-
  !.

write_parameters_all(Prefix,_,0):-
  write_tag(Prefix,'Parameters',['NumItems'],[0],true), nl,
  !.

write_parameters_all(Prefix,ID,N):-
  begin_tag(Prefix,'Parameters',['NumItems'],[N]), nl,
  atom_concat(Prefix,' ',Prefix1),
  write_parameters_enum(Prefix1,ID),
  end_tag(Prefix,'Parameters'), nl,
  !.

write_parameters(Prefix,ID):-
  count_parameters(ID,N),
  write_parameters_all(Prefix,ID,N).

write_position(Prefix,ID):-
  position(ID,Left,Top),
  write_tag(Prefix,'Position',['Left','Top'],[Left,Top],true), nl.

write_show(Prefix,ID):-
  show(ID,Class,Name,Image),
  write_tag(Prefix,'Show',['Class','Name','Image'],[Class,Name,Image],true), nl.

write_element(Prefix,ID,ClsID,PrntID,Perm):-
  begin_tag(Prefix,'Element',['ID','ClassID','ParentID','Permanent'],[ID,ClsID,PrntID,Perm]),nl,
   atom_concat(Prefix,' ',Prefix1),
   write_show(Prefix1,ID),
   write_position(Prefix1,ID),
   write_parameters(Prefix1,ID),
   write_contacts(Prefix1,ID,'InternalInputs','ii_contact','iContact','ElementID','ContID'),
   write_contacts(Prefix1,ID,'InternalOutputs','io_contact','iContact','ElementID','ContID'),
   write_contacts(Prefix1,ID,'PublishedInputs','pi_contact','pContact','PublicID','PublicName'),
   write_contacts(Prefix1,ID,'PublishedOutputs','po_contact','pContact','PublicID','PublicName'),
   write_i_links(Prefix1,ID),
   write_o_links(Prefix1,ID),
  end_tag(Prefix,'Element'), nl.

write_elements(Prefix):-
  element(ID,ClsID,PrntID,Perm),
  write_element(Prefix,ID,ClsID,PrntID,Perm),
  fail.
write_elements(_):-
  !.

write_xml:-
  write_xml_header,
  pgen_system(Lang),
  begin_tag('','System',['Lang'],[Lang]),nl,
   count_elements(N),
   begin_tag(' ','Elements',['NumItems'],[N]),nl,
    write_elements('  '),
   end_tag(' ','Elements'),nl,
  end_tag('','System'),nl.

process_html(['&'|T], ['&','a','m','p',';'|T1]):-
  process_html(T,T1),
  !.

process_html(['<'|T], ['&','l','t',';'|T1]):-
  process_html(T,T1),
  !.

process_html(['>'|T], ['&','g','t',';'|T1]):-
  process_html(T,T1),
  !.

process_html([''''|T], ['&','a','p','o','s',';'|T1]):-
  process_html(T,T1),
  !.

process_html(['"'|T], ['&','q','u','o','t',';'|T1]):-
  process_html(T,T1),
  !.

process_html(T, T1):-
  append(F,[C|FT],T), member(C,['&','<','>','''','"']), !,
  process_html([C|FT],TT1),
  append(F,TT1,T1),
  !.

process_html(T, T):-
  !.

escape_html(S,S1):-
  atom_chars(S,LS),
  process_html(LS,LS1),
  atom_chars(S1,LS1),
  !.

insert_inputs(_,[]):-
  !.
insert_inputs(ID,[H|Tag]):-
  asserta(i_contact(ID,H)),
  insert_inputs(ID,Tag).

insert_outputs(_,[]):-
  !.
insert_outputs(ID,[H|Tag]):-
  asserta(o_contact(ID,H)),
  insert_outputs(ID,Tag).

insert_parameters(_,[],[]):-
  !.
insert_parameters(ID,[N|TagN],[V0|TagV]):-
  escape_html(V0,V),
  asserta(parameter(ID,N,0,V)),
  insert_parameters(ID,TagN,TagV).

insert_link(ID,CID,ToID,ToCID,Color):-
  asserta(o_link(ID,CID,ToID,ToCID,Color,'False',0,'')),
  asserta(i_link(ToID,ToCID,ID,CID,'False')).

delete_element(ID):-
  retractall(element(ID,_,_,_)),
  retractall(show(ID,_,_,_)),
  retractall(position(ID,_,_)),
  retractall(parameters(ID,_)),
  retractall(parameter(ID,_,_,_)),
  retractall(i_link(ID,_,_,_,_)),
  retractall(i_link(_,_,ID,_,_)),
  retractall(o_link(ID,_,_,_,_,_,_,_)),
  retractall(o_link(_,_,ID,_,_,_,_,_)),
  retractall(internal_inputs(ID,_)),
  retractall(internal_outputs(ID,_)),
  retractall(published_inputs(ID,_)),
  retractall(published_outputs(ID,_)),
  retractall(i_contact(ID,_)),
  retractall(o_contact(ID,_)),
  retractall(ii_contact(ID,_,_,_)),
  retractall(io_contact(ID,_,_,_)),
  retractall(pi_contact(ID,_,_,_)),
  retractall(po_contact(ID,_,_,_)).

insert_element(ID,ClassID,ShowClass,ShowName,ShowImage,Left,Top,Prms,PrmVals,Inps,Outs):-
  asserta(element(ID,ClassID,'','False')),
   asserta(show(ID,ShowClass,ShowName,ShowImage)),
   asserta(position(ID,Left,Top)),
   length(Prms,NPrms),
   length(PrmVals,NPrms),
   asserta(parameters(ID,NPrms)),
    insert_parameters(ID,Prms,PrmVals),
   asserta(internal_inputs(ID,0)),
   asserta(internal_outputs(ID,0)),
   asserta(published_inputs(ID,0)),
   asserta(published_outputs(ID,0)),
   insert_inputs(ID,Inps),
   insert_outputs(ID,Outs).

unescape_list(['\\', 'n' | T], ['\n' | T1]):-
   unescape_list(T, T1),
   !.

unescape_list(['\\', 't' | T], ['\t' | T1]):-
   unescape_list(T, T1),
   !.

unescape_list(['\\', '"' | T], ['"' | T1]):-
   unescape_list(T, T1),
   !.

unescape_list(['\\', '''' | T], ['''' | T1]):-
   unescape_list(T, T1),
   !.

unescape_list(T, T1):-
   append(F, ['\\'|FT], T),
   unescape_list(['\\'|FT], FT1),
   append(F, FT1, T1),
   !.

unescape_list(T, T):-
   !.

unescape_specs(S,S1):-
   atom_chars(S,LS),
   unescape_list(LS,LS1),
   atom_chars(S1,LS1),
   !.
