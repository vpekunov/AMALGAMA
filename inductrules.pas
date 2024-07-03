unit InductRules;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$CODEPAGE UTF8}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF}
  Classes, SysUtils, FileUtil,
  {$IFDEF FPC}LResources,{$ENDIF}
  Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls, Buttons;

type

  { TInductRulesForm }

  TInductRulesForm = class(TForm)
    btLoadModel: TButton;
    btSaveIm: TButton;
    btUnloadModel: TButton;
    btGenerate: TButton;
    btLoadProject: TButton;
    btSaveProject: TButton;
    btViewObj: TButton;
    btSaveScript: TButton;
    btAutoFill: TButton;
    edConstsName: TEdit;
    edTablesName: TEdit;
    edPhrase: TEdit;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    lbModels: TListBox;
    lbObjs: TListBox;
    lbBound: TListBox;
    LogMemo: TMemo;
    memInducer: TMemo;
    memIm: TMemo;
    memIni: TMemo;
    OpenTxtDialog: TOpenDialog;
    OpenProjectDialog: TOpenDialog;
    OpenModelDialog: TOpenDialog;
    btAddPhrasedObj: TSpeedButton;
    btDelPhrasedObj: TSpeedButton;
    SaveImDialog: TSaveDialog;
    SaveProjectDialog: TSaveDialog;
    tvClasses: TTreeView;
    procedure btAddPhrasedObjClick(Sender: TObject);
    procedure btAutoFillClick(Sender: TObject);
    procedure btDelPhrasedObjClick(Sender: TObject);
    procedure btGenerateClick(Sender: TObject);
    procedure btLoadModelClick(Sender: TObject);
    procedure btLoadProjectClick(Sender: TObject);
    procedure btSaveImClick(Sender: TObject);
    procedure btSaveProjectClick(Sender: TObject);
    procedure btSaveScriptClick(Sender: TObject);
    procedure btUnloadModelClick(Sender: TObject);
    procedure btViewObjClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure lbModelsSelectionChange(Sender: TObject; User: boolean);
    procedure memImChange(Sender: TObject);
    procedure memInducerChange(Sender: TObject);
    procedure tvClassesSelectionChanged(Sender: TObject);
  private
    { private declarations }
    BoundSentences: TStringList;
    PathToIm: String;

    function BuildRules(const BoundSentences: TStringList): TStringList;
    procedure StoreWithBackup(L: TStrings; Const FName: String);
    Function BuildRegExps(Const BoundSentences: TStringList; Const dbconsts, dbtables: String;
      Var SortedClasses: TStringList; Var DBases: TList; Var StartDualBases: Integer; Var Funcs: TStringList;
      Var Error: Boolean): TStringList;
    Function StringReplaceMask(Var Mask: String; Where: String; Const What, Become: String): String;
  public
    { public declarations }
  end;

implementation

{ TInductRulesForm }

Uses Elements, Common, AutoUtils, Lexique, XPath, dom, xmlread,
  RegExpr, dynlibs, AutoConsts, EditEl, StrUtils;

procedure TInductRulesForm.StoreWithBackup(L: TStrings; const FName: String);
begin
  If FileExists(FName) Then
     begin
       DeleteFile(FName+'.bak');
       RenameFile(FName, FName+'.bak')
     end;
  L.SaveToFile(FName)
end;

function TInductRulesForm.BuildRules(const BoundSentences: TStringList
  ): TStringList;

Type TSimpleLink = Record
        _From, _To: TContactReg;
        _Links: Array Of TLink
     End;

Function DeduceParamsMap(Reverse: Boolean; Const L: TSimpleLink;
  Var FromBase: String; Var ToBase: TStringList; Var DepCoeff: Real): TStringList;

Var MappedParams: Array Of TStringList;
    GoodFrom: TElementReg;
    LL: TStringList;
    _FROM, _TO: TElement;
    Mask: String;
    S1, S2: String;
    F, G, K: Integer;
Begin
  SetLength(MappedParams, Length(L._Links));

  LL := TStringList.Create;
  LL.CaseSensitive := True;
  ToBase:= TStringList.Create;
  ToBase.CaseSensitive := True;

  DepCoeff := 0.0;
  GoodFrom := Nil;
  For F := 0 To High(L._Links) Do
      Begin
        MappedParams[F] := TStringList.Create;
        If Reverse Then
           begin
             _FROM := L._Links[F]._To.Owner;
             _TO := L._Links[F]._From.Owner
           end
        Else
           begin
             _FROM := L._Links[F]._From.Owner;
             _TO := L._Links[F]._To.Owner
           end;
        DepCoeff := DepCoeff + 0.1*(_TO.GetPower-_FROM.GetPower);
        MappedParams[F].Assign(_TO.Parameters);
        MappedParams[F].CaseSensitive := True;
        If MappedParams[F].IndexOfName('ID') < 0 Then
           MappedParams[F].Add('ID=' + _TO.Ident);
        LL.Clear;
        LL.AddStrings(_FROM.Parameters);
        If LL.IndexOfName('ID') < 0 Then
           LL.Add('ID=' + _FROM.Ident);
        If Not Assigned(GoodFrom) Then
           GoodFrom := _FROM.Ref
        Else
           While Assigned(GoodFrom) And Not ElementIs(_FROM.Ref, GoodFrom.ClsID) Do
             GoodFrom := GoodFrom.Parent;
        If ToBase.IndexOf(_TO.Ref.ClsID) < 0 Then
           ToBase.Add(_TO.Ref.ClsID);
        For G := 0 To MappedParams[F].Count - 1 Do
          If MappedParams[F][G] <> '' Then
            begin
              S1 := MappedParams[F].ValueFromIndex[G];
              Mask := StringOfChar(' ', Length(S1));
              For K := LL.Count-1 DownTo 0 Do
                  begin
                    S2 := S1;
                    S1 := StringReplaceMask(Mask, S1, LL.ValueFromIndex[K], '$('+LL.Names[K]+')');
                    If S1 <> S2 Then
                       DepCoeff := DepCoeff + 10.0
                  end;
              MappedParams[F].ValueFromIndex[G] := S1
            end;
      End;
  Result := TStringList.Create;
  Result.Assign(MappedParams[0]);
  For F := 1 To High(MappedParams) Do
    begin
      G := 0;
      While G < Result.Count Do
         If MappedParams[F].IndexOf(Result[G]) < 0 then
            Result.Delete(G)
         Else
            Inc(G)
    end;
  For F := 0 To High(MappedParams) Do
      MappedParams[F].Free;
  LL.Free;
  If Assigned(GoodFrom) Then
     FromBase := GoodFrom.ClsID
  Else
     FromBase := ''
End;

Function GenerateRule(Weight: Real; Reverse: Boolean; _From, _To: TContactReg; Create: Boolean;
  Const Base: String; Const Second: TStringList; LL: TStringList): TStringList;

  Function GetFirst(Sym: Char; C: TContactReg; Base: String; LL: TStringList): String;
  Begin
    If Base = '' Then Base := C.ClsID;
    Result := '[/OBJS/'+Base+'[@ID != ""]/'+Sym+'[@ID="'+C.CntID+'"]]'
  End;

  Function GetSecond(Sym: Char; C: TContactReg; Second: String; Create: Boolean; LL: TStringList): String;

  Var Cond: String;
      S,PostS: String;
      Tokens: TStringList;
      F, G, K: Integer;
  Begin
    Cond := '@ID != #/@ID';
    If Create Then
       For F := 0 To LL.Count-1 Do
         begin
           If (LL[F] <> '') And (LL.ValueFromIndex[F] <> '') then
               begin
                 If Cond <> '' Then AppendStr(Cond, ' and ');
                 If Assigned(LL.Objects[F]) Then
                    AppendStr(Cond, '@'+TParameter(LL.Objects[F]).Name+' = ')
                 Else
                    AppendStr(Cond, '@ID = ');
                 Tokens := TStringList.Create;
                 S := LL.ValueFromIndex[F];
                 While S <> '' Do
                    begin
                      G := Pos('$(', S);
                      If G = 0 Then
                         begin
                           Tokens.Add(S);
                           S := ''
                         end
                      Else If G = 1 Then
                         begin
                           Inc(G, 2);
                           K := Pos(')', S);
                           Tokens.AddObject(Copy(S, G, K-G), IntegerToTObject(1));
                           S := Copy(S, K+1, 16384)
                         end
                      Else
                         begin
                           Tokens.Add(Copy(S, 1, G-1));
                           S := Copy(S, G, 16384)
                         end
                    end;
                 PostS := StringOfChar(')', Tokens.Count-1);
                 For G := 0 To Tokens.Count-1 Do
                    begin
                      If G < Tokens.Count - 1 Then
                         AppendStr(Cond, 'concat(');
                      If Assigned(Tokens.Objects[G]) Then
                         AppendStr(Cond, '#/@'+Tokens[G])
                      Else
                         AppendStr(Cond, '"'+Tokens[G]+'"');
                      If G < Tokens.Count - 1 Then
                         AppendStr(Cond, ',')
                    end;
                 Tokens.Free;
                 AppendStr(Cond, S+PostS)
               end
         end
    Else
       For F := 0 To LL.Count-1 Do
         If (LL[F] <> '') And (LL.ValueFromIndex[F] <> '') Then
            begin
              If Cond <> '' Then AppendStr(Cond, ' and ');
              If Assigned(LL.Objects[F]) Then
                 AppendStr(Cond, '@'+TParameter(LL.Objects[F]).Name+' != ""')
              Else
                 AppendStr(Cond, '@ID != ""')
            end;
    If Second = '' Then Second := C.ClsID;
    Result := '[/OBJS/'+Second+'['+Cond+']/'+Sym+'[@ID="'+C.CntID+'"]/Link[@Code = ##/@Ref]]'
  End;

Var W: String;
    F: Integer;
Begin
  Result := TStringList.Create;
  Str(Weight:4:2, W);
  For F := 0 To Second.Count-1 Do
    If Reverse Then
       Result.Add('+{'+W+'} ' + GetSecond('O', _From, Second[F], Create, LL) + '=>' + GetFirst('I', _To, Base, LL) + '.')
    Else
       Result.Add('+{'+W+'} ' + GetFirst('O', _From, Base, LL) + '=>' + GetSecond('I', _To, Second[F], Create, LL) + '.')
End;

Var NContacts: Integer;
    Contacts: Array Of TContactReg;
    NLinks: Integer;
    Links: Array Of TSimpleLink;
    LL, LL2: TStringList;
    Sec, Sec2, R: TStringList;
    Base, Base2: String;
    DepCoeff, DepCoeff2: Real;
    C: TContact;
    Found: Boolean;
    F, G, K, H, H1: Integer;
Begin
   Result := TStringList.Create;

   SetLength(Links, 20);
   NLinks := 0;
   For F := 0 To BoundSentences.Count-1 Do
     With TElement(BoundSentences.Objects[F]) Do
       begin
         For G := 0 To Outputs.Count-1 Do
           begin
             C := TContact(Outputs.Objects[G]);
             For K := 0 To C.Links.Count-1 Do
               begin
                 If Length(Links) = NLinks Then
                    SetLength(Links, Length(Links)+20);
                 Links[NLinks]._From := C.Ref;
                 Links[NLinks]._To := TLink(C.Links[K])._To.Ref;

                 Found := False;
                 For H := 0 To NLinks-1 Do
                     If (Links[H]._From = Links[NLinks]._From) And (Links[H]._To = Links[NLinks]._To) Then
                        begin
                          Found := True;
                          H1 := Length(Links[H]._Links);
                          SetLength(Links[H]._Links, H1+1);
                          Links[H]._Links[H1] := TLink(C.Links[K]);
                          Break
                        end;
                 If Not Found Then
                    begin
                     SetLength(Links[NLinks]._Links, 1);
                     Links[NLinks]._Links[0] := TLink(C.Links[K]);
                     Inc(NLinks)
                    end
               end
           end
       end;
   SetLength(Links, NLinks);

   SetLength(Contacts, 20);
   NContacts := 0;
   For F := 0 To NLinks-1 Do
     begin
       Found := False;
       For H := 0 To NContacts-1 Do
           If Links[F]._From = Contacts[H] Then
              begin
                Found := True;
                Break
              end;
       If Not Found Then
          begin
            If Length(Contacts) = NContacts Then
               SetLength(Contacts, NContacts+20);
            Contacts[NContacts] := Links[F]._From;
            Inc(NContacts)
          end;
       Found := False;
       For H := 0 To NContacts-1 Do
           If Links[F]._To = Contacts[H] Then
              begin
                Found := True;
                Break
              end;
       If Not Found Then
          begin
            If Length(Contacts) = NContacts Then
               SetLength(Contacts, NContacts+20);
            Contacts[NContacts] := Links[F]._To;
            Inc(NContacts)
          end
     end;
   SetLength(Contacts, NContacts);

   For F := 0 To NLinks-1 Do
     begin
       LL := DeduceParamsMap(False, Links[F], Base, Sec, DepCoeff);
       LL2 := DeduceParamsMap(True, Links[F], Base2, Sec2, DepCoeff2);
       If DepCoeff < DepCoeff2 Then
          begin
            If Assigned(LL) Then
               begin
                 R := GenerateRule(0.75*Length(Links[F]._Links), False, Links[F]._From, Links[F]._To,
                         LL.Count>=Links[F]._Links[0]._To.Owner.Parameters.Count,
                         Base, Sec, LL);
                 Result.AddStrings(R);
                 R.Free
               end
            Else
               MessageDlg('Ошибка!', 'Не могу найти общее правило '+
                  Links[F]._From.ClsID+'\'+Links[F]._From.CntID+' => '+
                  Links[F]._To.ClsID+'\'+Links[F]._To.CntID, mtError, [mbOk], 0)
          end
       Else
          If Assigned(LL2) Then
             begin
               R := GenerateRule(0.75*Length(Links[F]._Links), True, Links[F]._From, Links[F]._To,
                        LL2.Count>=Links[F]._Links[0]._From.Owner.Parameters.Count,
                        Base2, Sec2, LL2);
               Result.AddStrings(R);
               R.Free
             end
          Else
             MessageDlg('Ошибка!', 'Не могу найти общее правило '+
                Links[F]._From.ClsID+'\'+Links[F]._From.CntID+' => '+
                Links[F]._To.ClsID+'\'+Links[F]._To.CntID, mtError, [mbOk], 0);
       Sec.Free;
       Sec2.Free;
       LL.Free;
       LL2.Free
     end
end;

function TInductRulesForm.BuildRegExps(const BoundSentences: TStringList;
  const dbconsts, dbtables: String; var SortedClasses: TStringList;
  var DBases: TList; var StartDualBases: Integer; var Funcs: TStringList;
  var Error: Boolean): TStringList;

Const lib = 'Grammar';
      fn = 'ru';

Type Transformer = function(Const text: PWideChar): PWideChar; cdecl;

Function TokenSetToString(Const L: TStringList): String;

Var F: Integer;
Begin
   Result := '';
   For F := 0 To L.Count-1 Do
       AppendStr(Result, L.Strings[F]+'['+TStringList(L.Objects[F]).DelimitedText+']')
End;

Type TStringListArray = Array Of TStringList;
     TObjInfo = Record
        SpecificWords: TStringList;
        ParamsMap: TStringList;
        TableNums: Set Of Byte;
        RawTableNums: Set Of Byte
     End;
     TGrammarLink = Record
        Name: String;
        Left: WideString;
        Right: WideString
     end;

function GetNodeValue(P: TDOMNode): String;
begin
   If Not Assigned(P) Then
      Result := ''
   Else
      Result := P.NodeValue
end;

Var GrammarLinks: Array Of Array Of TGrammarLink;

function MakePath(Const Start: String; Const W: TStringList; Const ObjNums: TList; Dest: TList): String;

  function GetPathsList(ObjNum: Integer; D: TStringList): TStringList;

    procedure FindAllWays(ID: Integer; Const Path: String; Visited: TStringList; Const _From, _To: String);

    Var F: Integer;
    begin
      If Visited.IndexOf(_From) < 0 Then
         If _From = _To Then
            Result.AddObject(Path, IntegerToTObject(ID))
         Else
           begin
             Visited.Add(_From);
             For F := 0 To High(GrammarLinks[ObjNum]) Do
                 If GrammarLinks[ObjNum][F].Left = _From Then
                    FindAllWays(ID, Path + GrammarLinks[ObjNum][F].Name + '[1]', Visited, GrammarLinks[ObjNum][F].Right, _To)
                 Else If GrammarLinks[ObjNum][F].Right = _From Then
                    FindAllWays(ID, Path + GrammarLinks[ObjNum][F].Name + '[0]', Visited, GrammarLinks[ObjNum][F].Left, _To);
             Visited.Delete(Visited.IndexOf(_From));
           end;
    end;

  Var F, G: Integer;
      Visited: TStringList;
  begin
     Result := TStringList.Create;
     Result.Sorted := True;
     Result.Duplicates := dupIgnore;

     Visited := TStringList.Create;
     Visited.Sorted := True;
     For F := 0 To W.Count-1 Do
         For G := 0 To D.Count-1 Do
             begin
               Visited.Clear;
               If W[F] = D[G] Then
                  Result.AddObject('', IntegerToTObject(G))
               Else
                  FindAllWays(G, '', Visited, W[F], D[G])
             end;
     Visited.Free
  end;

Var ObjNum: Integer;
    SelectedPaths: TList;
    V: TStringList;
    S: String;
    F, G, K: Integer;
Begin
   SelectedPaths := TList.Create;
   For F := 0 To Dest.Count-1 Do
       SelectedPaths.Add(TStringList.Create);

   For F := 0 To ObjNums.Count-1 Do
       begin
         ObjNum := TObjectToInteger(ObjNums[F]);
         For G := 0 To Dest.Count-1 Do
             begin
               V := GetPathsList(ObjNum, TStringList(Dest[G]));
               For K := 0 To V.Count-1 Do
                 With TStringList(SelectedPaths[G]) Do
                   begin
                     If Count = 0 Then
                        begin
                          Sorted := True;
                          Duplicates := dupIgnore
                        end;
                     AddStrings(V)
                   end;
               V.Free
             end
       end;

   V := TStringList.Create;
   V.Assign(TStringList(SelectedPaths[0]));
   For F := 1 To SelectedPaths.Count-1 Do
     With TStringList(SelectedPaths[F]) Do
       begin
         G := 0;
         While G < V.Count Do
           If IndexOf(V[G]) < 0 Then
              V.Delete(G)
           Else
              Inc(G)
       end;

   // Выбираем кратчайший вариант
   If V.Count = 0 Then
      begin
        S := '';
        For G := 0 To Dest.Count-1 Do
            AppendStr(S, '<'+TStringList(Dest[G]).DelimitedText+'>');
        MessageDlg('Ошибка!','Неудача поиска общей серии грамматических связей из ['+W.DelimitedText+'] в ['+S+']', mtError, [mbOk], 0);
        Error := True;
        Result := StringOfChar('#', 1024)
      end
   Else
      begin
        G := 0;
        For F := 1 To V.Count-1 Do
          If Length(V[F]) < Length(V[G]) Then
             G := F;
        For F := 0 To SelectedPaths.Count-1 Do
          With TStringList(SelectedPaths[F]) Do
            For K := 0 To Count-1 Do
              If Strings[K] = V[G] Then
                 begin
                   S := TStringList(Dest[F]).Strings[TObjectToInteger(Objects[K])];
                   TStringList(Dest[F]).Clear;
                   TStringList(Dest[F]).Add(S);
                   Break
                 end;
        Result := Start+V[G]
      end;
   V.Free;
   For F := 0 To SelectedPaths.Count-1 Do
       TStringList(SelectedPaths[F]).Free;
   SelectedPaths.Free
end;

function GetDB(Var DBases: TList; Const Vals: TStringList): Integer;
begin
   Result := 0;
   While (Result < DBases.Count) And Not Vals.Equals(TStringList(DBases[Result])) Do
     Inc(Result);
   If Result = DBases.Count Then
      begin
        DBases.Add(TStringList.Create);
        With TStringList(DBases[Result]) Do
          begin
            Sorted := True;
            Duplicates := dupIgnore;
            AddStrings(Vals)
          end
      end
end;

function RemoveSqrBrackets(Const S: String): String;

Var F: Integer;
Begin
   Result := '';
   For F := 1 To Length(S) Do
     If (S[F] <> '[') And (S[F] <> ']') Then
        AppendStr(Result, S[F])
end;

Function LengthNoQuotes(Const S: String): Integer;
Begin
   Result := Length(S);
   If (Result > 1) And (S[1] = '"') And (S[Result] = '"') Then
      Dec(Result, 2)
end;

Function Dequote(Const S: String): String;

Var R: Integer;
Begin
   R := Length(S);
   If (R > 1) And (S[1] = '"') And (S[R] = '"') Then
      Result := Copy(S, 2, R-2)
   Else
      Result := S
end;

Var Script: String;
    Words: TStringListArray;
    NonWords: TStringListArray;
    MappedParams: TStringListArray;
    CommonWords: TStringListArray;
    UniqueCommonWords: TStringListArray;
    IsSubSetOf: Array Of TList;
    ObjTypes: Array Of TElementReg;
    ObjInfo: Array Of TObjInfo;
    NObjTypes: Word;
    RawDBases: TList;
    Found, Good: Boolean;
    CurWord: WideString;
    Tokens, TokenSet: TStringList;
    SignificantWords: TStringList;
    Templates, TemplateNums: TList;
    Backup: TList;
    parser: TDOMParser;
    src: TXMLInputSource;
    res: TXPathVariable;
    dom: TXMLDocument;
    LST: TDOMNodeList;
    HH: TLibHandle;
    T: Transformer;
    txt: WideString;
    ptxt: PWideChar;
    Mask: String;
    Used: Set Of Byte;
    PP: TStringList;
    DB, DBR: Integer;
    LL, BestLL: TList;
    P: TElementReg;
    PF: TObjInfo;
    Paths: TStringList;
    PathDBNums: TList;
    C: Char;
    S: WideString;
    MAINF: String;
    Link, TAG1, TAG2: String;
    LinkNum: Word;
    V1, V2: String;
    Goal, Asserter: String;
    S1, S2, S3, S4, S5: String;
    F, G, K, H, H1, Z, M: Integer;
Begin
  Result := Nil;
  SortedClasses := Nil;
  DBases := Nil;

  Error := False;

  LogMemo.Lines.Clear;

  G := Transformers.IndexOf(lib);
  If G < 0 Then
     begin
       HH := LoadLibrary({$IF DEFINED(UNIX) OR DEFINED(LINUX)}'./lib' + {$ENDIF}lib + '.' + SharedSuffix);
       If HH = NilHandle Then
          begin
            {$IF DEFINED(LCL) OR DEFINED(VCL)}
            MessageDlg('Can''t load library "' + lib + '"',mtWarning,[mbOk],0);
            {$ELSE}
            WriteLn('Can''t load library "' + lib + '"');
            {$ENDIF}
            Error := True
          end
       Else
          Transformers.AddObject(lib, IntegerToTObject(HH))
     end
  Else
     HH := TLibHandle(TObjectToInteger(Transformers.Objects[G]));

  SetLength(Words, BoundSentences.Count);
  SetLength(NonWords, BoundSentences.Count);
  SetLength(GrammarLinks, BoundSentences.Count);
  NObjTypes := 0;
  parser := TDOMParser.Create;
  parser.Options.PreserveWhitespace := True;
  parser.Options.Namespaces := True;
  For F := 0 To BoundSentences.Count-1 Do
      begin
        Words[F] := TStringList.Create;
        NonWords[F] := TStringList.Create;

        If BoundSentences[F] = '$' Then
           begin
              SetLength(GrammarLinks[F], 0);
              NonWords[F].Add('@')
           end
        Else
           begin
              If HH <> NilHandle Then
                 begin
                    T := GetProcedureAddress(HH, fn);
                    If TLibHandle(@T) = NilHandle Then
                       begin
                         {$IF DEFINED(LCL) OR DEFINED(VCL)}
                         MessageDlg('Can''t load transformer "' + fn + '"',mtWarning,[mbOk],0);
                         {$ELSE}
                         WriteLn('Can''t load transformer "' + fn + '"');
                         {$ENDIF}
                         txt := '';
                         Error := True
                       end
                    else
                       begin
                         txt := utf8encode(WideString('#MVv;MVIv#' + BoundSentences[F])); {!!!}
                         ptxt := T(PWideChar(txt));
                         txt := ptxt
                       end
                 end
              Else
                 txt := 'Error';

              src := TXMLInputSource.Create('<root>' + txt + '</root>');
              try
                try
                   parser.Parse(src, dom);
                   try
                      res := EvaluateXPathExpression('/*/Link[Right/Value and Left/Value]', dom.DocumentElement, Nil, []);
                      If res is TXPathNodeSetVariable Then
                         begin
                           SetLength(GrammarLinks[F], res.AsNodeSet.Count);
                           For G := 0 To res.AsNodeSet.Count - 1 Do
                            Begin
                             LST := TDOMNode(res.AsNodeSet[G]).ChildNodes;
                             For K := 0 To LST.Count - 1 Do
                                 If TDOMNode(LST[K]).NodeName = 'Name' Then
                                    GrammarLinks[F][G].Name := TDOMNode(LST[K]).FirstChild.NodeValue
                                 Else If TDOMNode(LST[K]).NodeName = 'Right' Then
                                    GrammarLinks[F][G].Right := GetNodeValue(TDOMNode(LST[K]).FirstChild.FirstChild)
                                 Else If TDOMNode(LST[K]).NodeName = 'Left' Then
                                    GrammarLinks[F][G].Left := GetNodeValue(TDOMNode(LST[K]).FirstChild.FirstChild);
                             LST.Free
                            end
                         end
                      Else
                         SetLength(GrammarLinks[F], 0);
                      res.Free
                   finally
                      dom.Free
                   end;
                finally
                   src.Free
                end
              except
                SetLength(GrammarLinks[F], 0);
                Error := True
              end;
              LogMemo.Lines.Add(BoundSentences[F]);
              For G := 0 To High(GrammarLinks[F]) Do
                  LogMemo.Lines.Add(GrammarLinks[F][G].Name+' '+GrammarLinks[F][G].Left+' '+GrammarLinks[F][G].Right);
              S := BoundSentences[F] + ' ';
              CurWord := '';
              G := 1;
              While G <= Length(S) Do
                  If (S[G] = '''') Or (S[G] = '"') Then
                     Begin
                       C := S[G];
                       If _TrimRight(CurWord) <> '' Then
                          If IsValidIdent(CurWord) Or TryStrToInt(CurWord, K) Then
                             NonWords[F].Add(CurWord)
                          Else
                             Words[F].Add(CurWord);
                       Inc(G);
                       CurWord := '';
                       While (G <= Length(S)) And (S[G] <> C) Do
                         Begin
                           CurWord := CurWord + S[G];
                           Inc(G)
                         End;
                       CurWord := C + Trim(CurWord) + C;
                       If G <= Length(S) Then
                          Inc(G);
                       NonWords[F].Add(CurWord);
                       CurWord := ''
                     End
                  Else
                     Begin
                       If Pos(S[G],' .,?!:;()+-/\*=') > 0 Then
                          Begin
                            If TrimRight(CurWord) <> '' Then
                               If IsValidIdent(CurWord) Or TryStrToInt(CurWord, K) Then
                                  NonWords[F].Add(CurWord)
                               Else
                                  Words[F].Add(CurWord);
                            CurWord := ''
                          end
                       Else
                          CurWord := CurWord + S[G];
                       Inc(G)
                     End
           End;
        Found := False;
        For G := 0 To NObjTypes-1 Do
            If ObjTypes[G] = TElement(BoundSentences.Objects[F]).Ref Then
               begin
                 Found := True;
                 Break
               end;
        If Not Found Then
           begin
             If NObjTypes = Length(ObjTypes) Then
                begin
                  SetLength(ObjTypes, NObjTypes + 20);
                  SetLength(ObjInfo, NObjTypes + 20)
                end;
             ObjTypes[NObjTypes] := (BoundSentences.Objects[F] As TElement).Ref;
             Inc(NobjTypes)
           end;
        For G := 0 To NonWords[F].Count - 1 Do
            NonWords[F].Objects[G] := IntegerToTObject(G);
        For G := 0 To NonWords[F].Count - 2 Do
            begin
              H := G;
              For K := G+1 To NonWords[F].Count-1 Do
                begin
                  H1 := LengthNoQuotes(NonWords[F][K]);
                  M := LengthNoQuotes(NonWords[F][H]);
                  If (H1 > M) Or ((H1 = M) And (TObjectToInteger(NonWords[F].Objects[K]) < TObjectToInteger(NonWords[F].Objects[H]))) Then
                     H := K
                end;
              If G <> H Then
                 NonWords[F].Exchange(G, H)
            end;
//        NonWords[F].Sort
      end;
  parser.Free;

  SetLength(CommonWords, NObjTypes);
  For F := 0 To High(CommonWords) Do
      begin
        CommonWords[F] := TStringList.Create;
        CommonWords[F].Sorted := True;
        CommonWords[F].Duplicates := dupIgnore;
        Found := False;
        For G := 0 To High(Words) Do
            If TElement(BoundSentences.Objects[G]).Ref = ObjTypes[F] Then
               If Not Found Then
                  begin
                    CommonWords[F].Assign(Words[G]);
                    Found := True
                  end
               Else
                  begin
                    K := 0;
                    While K < CommonWords[F].Count Do
                      If Words[G].IndexOf(CommonWords[F][K]) < 0 Then
                         CommonWords[F].Delete(K)
                      Else
                         Inc(K)
                  end
      end;
  SetLength(IsSubSetOf, NObjTypes);
  LL := TList.Create;
  For F := 0 To NObjTypes-1 Do
      begin
        IsSubSetOf[F] := Nil;
        LL.Clear;
        If CommonWords[F].Count > 0 Then
           For G := 0 To NObjTypes-1 Do
               If (F <> G) And (CommonWords[F].Count < CommonWords[G].Count) Then
                  begin
                    Found := True;
                    For K := 0 To CommonWords[F].Count-1 Do
                        If CommonWords[G].IndexOf(CommonWords[F][K]) < 0 Then
                           begin
                             Found := False;
                             Break
                           end;
                    If Found Then
                       LL.Add(IntegerToTObject(G))
                  end;
        If LL.Count > 0 Then
           begin
             IsSubSetOf[F] := TList.Create;
             IsSubSetOf[F].Assign(LL)
           end
      end;
  LL.Free;
  For F := 0 To NObjTypes-2 Do
      begin
        K := F;
        G := F+1;
        While G < NObjTypes Do
            If Assigned(IsSubSetOf[K]) And (IsSubSetOf[K].IndexOf(IntegerToTObject(G)) >= 0) Then
               begin
                 K := G;
                 G := F+1
               end
            Else
               Inc(G);
        If K <> F Then
           begin
             P := ObjTypes[K];
             ObjTypes[K] := ObjTypes[F];
             ObjTypes[F] := P;
             PF := ObjInfo[K];
             ObjInfo[K] := ObjInfo[F];
             ObjInfo[F] := PF;
             PP := CommonWords[K];
             CommonWords[K] := CommonWords[F];
             CommonWords[F] := PP;
             LL := IsSubSetOf[K];
             IsSubSetOf[K] := IsSubSetOf[F];
             IsSubSetOf[F] := LL
           end
      end;
  SetLength(UniqueCommonWords, NObjTypes);
  For F := 0 To High(UniqueCommonWords) Do
      begin
        UniqueCommonWords[F] := TStringList.Create;
        UniqueCommonWords[F].Sorted := True;
        UniqueCommonWords[F].Duplicates := dupIgnore;
        UniqueCommonWords[F].Assign(CommonWords[F]);
        For G := 0 To High(Words) Do
            If ObjTypes[F] <> TElement(BoundSentences.Objects[G]).Ref Then
               For K := 0 To Words[G].Count-1 Do
                   If UniqueCommonWords[F].Find(Words[G][K], H) Then
                      UniqueCommonWords[F].Delete(H);
        ObjInfo[F].SpecificWords := UniqueCommonWords[F];
        ObjInfo[F].RawTableNums := [];
        ObjInfo[F].TableNums := [];
        LogMemo.Lines.Add(ObjTypes[F].ClsID + ' ' + UniqueCommonWords[F].DelimitedText)
      end;

  SetLength(MappedParams, BoundSentences.Count);
  Backup := TList.Create;
  For F := 0 To BoundSentences.Count - 1 Do
      Begin
        MappedParams[F] := TStringList.Create;
        MappedParams[F].Assign(TElement(BoundSentences.Objects[F]).Parameters);
        For G := 0 To MappedParams[F].Count - 1 Do
           If MappedParams[F][G] <> '' Then
              With TStringList.Create Do
                begin
                   S1:=MappedParams[F].ValueFromIndex[G];;
                   If Length(S1)>0 Then
                      begin
                        CommaText:=S1;
                        If Count=0 Then
                           S1:=''
                        Else If S1[1]='"' Then
                           S1:=Text;
                        MappedParams[F].ValueFromIndex[G] := UnifyStrings(Trim(S1))
                      end;
                   Free
                end;
        MappedParams[F].CaseSensitive := True;
        If MappedParams[F].IndexOfName('ID') < 0 Then
           MappedParams[F].Add('ID=' + TElement(BoundSentences.Objects[F]).Ident);
        Backup.Add(TStringList.Create);
        TStringList(Backup[Backup.Count-1]).Assign(MappedParams[F]);
        TStringList(Backup[Backup.Count-1]).CaseSensitive := True;
        Used := [];
        For G := 0 To MappedParams[F].Count - 1 Do
          If MappedParams[F][G] <> '' Then
            begin
              S1 := MappedParams[F].ValueFromIndex[G];
              If Length(S1) = 0 Then Continue;
              Mask := StringOfChar(' ', Length(S1));
              For K := 0 To NonWords[F].Count-1 Do
                begin
                  S2 := NonWords[F][K];
                  If K in Used Then
                     begin
                       Found := False;
                       S3 := Dequote(S2);
                       For H := K+1 To NonWords[F].Count-1 Do
                           If S3 = Dequote(NonWords[F][H]) Then
                              begin
                                Found := True;
                                Break
                              end;
                       If Found Then Continue
                     end;
                  If (S2[1] = '''') Or (S2[1] = '"') Then
                     begin
                       S3 := S2[1];
                       S2 := Copy(S2, 2, Length(S2)-2)
                     end
                  Else
                     S3 := '';
                  S4 := StringReplaceMask(Mask, S1, S2, '$('+S3+IntToStr(TObjectToInteger(NonWords[F].Objects[K]))+')');
                  If S4 <> S1 Then
                     Include(Used, K);
                  S1 := S4
                end;
              MappedParams[F].ValueFromIndex[G] := S1
            end;
      End;

  LogMemo.Lines.Add('Mapping has been finished');

  Templates := TList.Create;
  TemplateNums := TList.Create;
  Tokens := TStringList.Create;
  TokenSet := TStringList.Create;
  TokenSet.Sorted := True;
  TokenSet.Duplicates := dupIgnore;
  DBases := TList.Create;
  RawDBases := TList.Create;
  SignificantWords := TStringList.Create;
  SignificantWords.Sorted := True;
  SignificantWords.Duplicates := dupIgnore;
  For F := 0 To NObjTypes-1 Do
      begin
        Templates.Clear;
        TemplateNums.Clear;
        For G := 0 To BoundSentences.Count-1 Do
            If TElement(BoundSentences.Objects[G]).Ref = ObjTypes[F] Then
               begin
                 Templates.Add(MappedParams[G]);
                 TemplateNums.Add(IntegerToTObject(G))
               end;
        For G := 0 To TStringList(Templates[0]).Count-1 Do
            begin
              S1 := TStringList(Templates[0]).Names[G];
              H := -1;
              For K := 0 To Templates.Count-1 Do
                  begin // K-th template
                    S2 := TStringList(Templates[K]).Values[S1];
                    H1 := Length(S2);
                    Dec(H1, Length(StringReplace(S2, '$(', '#', [rfReplaceAll])));
                    If H < 0 Then
                       H := H1
                    Else If H <> H1 Then // Fail templating, restore...
                       begin
                         For H := 0 To Templates.Count-1 Do
                             TStringList(Templates[H]).Strings[G] := TStringList(Backup[TObjectToInteger(TemplateNums[H])]).Strings[G];
                         Break
                       end
                  end;
              H := 1;
              While H <= Length(TStringList(Templates[0]).Values[S1]) Do
                 begin
                    Tokens.Clear;
                    TokenSet.Clear;
                    // G-th parameter
                    For K := 0 To Templates.Count-1 Do
                        begin // K-th template
                          S2 := TStringList(Templates[K]).Values[S1];
                          H1 := H;
                          If H1 > Length(S2) Then
                             begin
                               MessageDlg('Ошибка!','Проблема #1 поиска правила для параметра '+S1+' в объекте класса ' + ObjTypes[F].ClsId, mtError, [mbOk], 0);
                               Error := True;
                               Break
                             end;
                          If S2[H1] = Dollar Then
                             begin
                               H1 := H-1 + Pos(')', Copy(S2, H, 16384));
                               If H1 = H-1 Then
                                  begin
                                    MessageDlg('Ошибка!','Проблема #2 поиска правила для параметра '+S1+' в объекте класса ' + ObjTypes[F].ClsId, mtError, [mbOk], 0);
                                    Error := True;
                                    Break
                                  end;
                               Inc(H1)
                             end
                          Else
                             While (H1 <= Length(S2)) And (S2[H1] <> Dollar) Do
                                Inc(H1);
                          Tokens.Add(Copy(S2, H, H1-H));
                          TokenSet.Add(Copy(S2, H, H1-H));
                          TStringList(Templates[K]).Values[S1] := Copy(S2, 1, H-1) + '#!#' + Copy(S2, H1, 16384)
                        end;
                   If TokenSet.Count = 1 Then
                       begin
                         For K := 0 To Templates.Count-1 Do
                           begin // K-th template
                             S2 := TStringList(Templates[K]).Values[S1];
                             TStringList(Templates[K]).Values[S1] := StringReplace(S2, '#!#', TokenSet[0], [rfReplaceAll])
                           end;
                         Inc(H, Length(TokenSet[0]))
                       end
                    Else
                       begin
                         For K := 0 To TokenSet.Count-1 Do
                           If (Length(TokenSet[K]) > 0) And (TokenSet[K][1] = Dollar) Then
                              begin
                                MessageDlg('Ошибка!','Проблема #3 поиска правила для параметра '+S1+' в объекте класса ' + ObjTypes[F].ClsId, mtError, [mbOk], 0);
                                Error := True;
                                Break
                              end;
                         For K := 0 To TokenSet.Count-1 Do
                           begin
                             SignificantWords.Clear;
                             For H1 := 0 To TemplateNums.Count-1 Do
                                 If Tokens[H1] = TokenSet[K] Then
                                    If SignificantWords.Count = 0 Then
                                       SignificantWords.AddStrings(Words[TObjectToInteger(TemplateNums[H1])])
                                    Else
                                       begin
                                         PP := Words[TObjectToInteger(TemplateNums[H1])];
                                         Z := 0;
                                         While Z < SignificantWords.Count Do
                                            If PP.IndexOf(SignificantWords[Z]) < 0 Then
                                               SignificantWords.Delete(Z)
                                            Else
                                               Inc(Z)
                                       end;
                             TokenSet.Objects[K] := TStringList.Create;
                             TStringList(TokenSet.Objects[K]).Assign(SignificantWords)
                           end;
                         PP := TStringList.Create; // Хотя бы раз повторяющиеся слова
                         PP.Sorted := True;
                         PP.Duplicates := dupIgnore;
                         For K := 0 To TokenSet.Count-2 Do
                             For H1 := K+1 To TokenSet.Count-1 Do
                                 For Z := 0 To TStringList(TokenSet.Objects[H1]).Count-1 Do
                                     If TStringList(TokenSet.Objects[K]).IndexOf(TStringList(TokenSet.Objects[H1]).Strings[Z]) >= 0 Then
                                        PP.Add(TStringList(TokenSet.Objects[H1]).Strings[Z]);
                         For K := 0 To TokenSet.Count-1 Do
                           begin
                             Z := 0;
                             While Z < TStringList(TokenSet.Objects[K]).Count Do
                                 If PP.IndexOf(TStringList(TokenSet.Objects[K]).Strings[Z]) >= 0 Then
                                    TStringList(TokenSet.Objects[K]).Delete(Z)
                                 Else
                                    Inc(Z)
                           end;
                         PP.Free;

                         Good := True;
                         For K := 0 To TokenSet.Count-1 Do
                             Good := Good And (TStringList(TokenSet.Objects[K]).Count > 0);

                         If Not Good Then
                            begin
                              For K := 0 To Templates.Count-1 Do
                                  begin // K-th template
                                     S2 := TStringList(Templates[K]).Values[S1];
                                     TStringList(Templates[K]).Values[S1] := 'randomid()'
                                  end;
                              For K := 0 To TokenSet.Count-1 Do
                                  TStringList(TokenSet.Objects[K]).Free;
                              H := Length(TStringList(Templates[0]).Values[S1]) + 1;
                            end
                         Else
                            begin
                               S2 := TokenSetToString(TokenSet);

                               DBR := 0;
                               While (DBR < RawDBases.Count) And (TokenSetToString(TStringList(RawDBases[DBR])) <> S2) Do
                                  Inc(DBR);

                               Include(ObjInfo[F].RawTableNums, DBR);

                               For K := 0 To Templates.Count-1 Do
                                 begin // K-th template
                                   S2 := TStringList(Templates[K]).Values[S1];
                                   TStringList(Templates[K]).Values[S1] := StringReplace(S2, '#!#', '#('+IntToStr(DBR)+')', [rfReplaceAll])
                                 end;
                               Inc(H, Length('#('+IntToStr(DBR)+')'));
                               // TokenSet -- [значение_для_параметра] => список вариантов русских слов
                               If DBR = RawDBases.Count Then
                                  begin
                                    RawDBases.Add(TokenSet);
                                    TokenSet := TStringList.Create;
                                    TokenSet.Sorted := True;
                                    TokenSet.Duplicates := dupIgnore
                                  end
                               Else
                                  For K := 0 To TokenSet.Count-1 Do
                                      TStringList(TokenSet.Objects[K]).Free
                            end;
                       end
                 end;
              For K := 0 To Templates.Count-1 Do
                  If H <> Length(TStringList(Templates[K]).Values[S1])+1 Then
                     begin
                       MessageDlg('Ошибка!','Проблема #4 поиска правила для параметра '+S1+' в объекте класса ' + ObjTypes[F].ClsId, mtError, [mbOk], 0);
                       Error := True;
                       Break
                     end
            end;
        ObjInfo[F].ParamsMap := TStringList(Templates[0]);
        LogMemo.Lines.Add(ObjTypes[F].ClsID + ':' + TStringList(Templates[0]).DelimitedText)
      end;
  SignificantWords.Free;
  Tokens.Free;
  TokenSet.Free;
  TemplateNums.Free;
  For F := 0 To Backup.Count-1 Do
    TObject(Backup[F]).Free;
  Backup.Free;

  Result := TStringList.Create;
  Funcs := TStringList.Create;
  Funcs.Sorted := True;
  Funcs.Duplicates := dupIgnore;
  // Ищем грамматические связи - идентифицирующие соединители
  For F := 0 To NObjTypes-1 Do
    begin
      Script := '';
      Paths := TStringList.Create;
      PathDBNums := TList.Create; // N+1 = DB[N]; 0 = const; -(N+1) = RAWDB[N]
      Templates.Clear;
      For G := 0 To BoundSentences.Count-1 Do
        If TElement(BoundSentences.Objects[G]).Ref = ObjTypes[F] Then
           Templates.Add(IntegerToTObject(G));

      S1 := '';
      For G := 0 To High(GrammarLinks[TObjectToInteger(Templates[0])]) Do
        If GrammarLinks[TObjectToInteger(Templates[0])][G].Name = 'MVv' Then
           begin
             S1 := 'MVv';
             Break
           end
        Else If GrammarLinks[TObjectToInteger(Templates[0])][G].Name = 'MVIv' Then
           begin
             S1 := 'MVIv';
             Break
           end;
      If S1 = '' Then
        For G := 0 To High(GrammarLinks[TObjectToInteger(Templates[0])]) Do
          If GrammarLinks[TObjectToInteger(Templates[0])][G].Name = 'Wd' Then
             begin
               S1 := 'Wd';
               Break
             end;
      MAINF := S1;
      If MainF = '' Then
         begin
           If BoundSentences[TObjectToInteger(Templates[0])] <> '$' Then
              begin
                MessageDlg('Проблема!', 'Не могу обнаружить ведущую MVv/MVIv/Wd-связь', mtError, [mbOk], 0);
                Error := True
              end
         end
      Else
         begin
          Paths.AddObject(S1+'[0]', TStringList.Create);
          With TStringList(Paths.Objects[0]) Do
            begin
              Sorted := True;
              Duplicates := dupIgnore
            end;
          LogMemo.Lines.Add(ObjTypes[F].ClsID + ': LINK: ' + S1 + '[0]');
          Paths.AddObject(S1+'[1]', TStringList.Create);
          With TStringList(Paths.Objects[1]) Do
            begin
              Sorted := True;
              Duplicates := dupIgnore
            end;
          LogMemo.Lines.Add(ObjTypes[F].ClsID + ': LINK: ' + S1 + '[1]');
          For K := 0 To Templates.Count-1 Do
            begin
              H := TObjectToInteger(Templates[K]);
              For G := 0 To High(GrammarLinks[H]) Do
                If GrammarLinks[H][G].Name = S1 Then
                   begin
                     TStringList(Paths.Objects[0]).Add(GrammarLinks[H][G].Left);
                     TStringList(Paths.Objects[1]).Add(GrammarLinks[H][G].Right)
                   end
            end;
          If TStringList(Paths.Objects[0]).Count = 1 Then
             PathDBNums.Add(Nil)
          Else
             begin
               H := GetDB(DBases, TStringList(Paths.Objects[0]));
               Include(ObjInfo[F].TableNums, H);
               PathDBNums.Add(IntegerToTObject(1+H))
             end;
          If TStringList(Paths.Objects[1]).Count = 1 Then
             PathDBNums.Add(Nil)
          Else
             begin
               H := GetDB(DBases, TStringList(Paths.Objects[1]));
               Include(ObjInfo[F].TableNums, H);
               PathDBNums.Add(IntegerToTObject(1+H));
             end
         end;
      If UniqueCommonWords[F].Count > 0 Then
         begin
           S1 := ''; // Лучшее уникальное слово
           S2 := StringOfChar('*', 1024); // и путь к нему
           LL := TList.Create;
           For K := 0 To Paths.Count-1 Do
             begin
               LL.Clear;
               PP := TStringList.Create;
               PP.Assign(UniqueCommonWords[F]);
               LL.Add(PP);
               S3 := MakePath(Paths[K], TStringList(Paths.Objects[K]), Templates, LL);
               If Length(S3) < Length(S2) Then
                  begin
                    S1 := PP[0];
                    S2 := S3;
                  end;
               PP.Free
             end;
           If S1 <> '' Then
              begin
                 UniqueCommonWords[F].Clear;
                 UniqueCommonWords[F].Add(S1);
                 Paths.AddObject(S2, TStringList.Create);
                 With TStringList(Paths.Objects[2]) Do
                   begin
                     Sorted := True;
                     Duplicates := dupIgnore;
                     Add(S1)
                   end;
                 PathDBNums.Add(IntegerToTObject(0));
                 LogMemo.Lines.Add(ObjTypes[F].ClsID + ': UNIQUE: ' + S1 + '[' + S2 + ']')
              end;
           LL.Free
         end;
      For G := 0 To 255 Do
        If G in ObjInfo[F].RawTableNums Then
          begin
            S2 := StringOfChar('*', 1024); // путь
            BestLL := TList.Create;
            LL := TList.Create;
            PP := RawDBases[G];
            For K := 0 To Paths.Count-1 Do
              begin
                LL.Clear;
                For H := 0 To PP.Count-1 Do
                  begin
                    LL.Add(TStringList.Create);
                    TStringList(LL[LL.Count-1]).Assign(TStringList(PP.Objects[H]))
                  end;
                S3 := MakePath(Paths[K], TStringList(Paths.Objects[K]), Templates, LL);
                If Length(S3) < Length(S2) Then
                   begin
                     S2 := S3;
                     BestLL.Assign(LL)
                   end
                Else
                   For H := 0 To LL.Count-1 Do
                     TStringList(LL[H]).Free
              end;
            Paths.AddObject(S2, TStringList.Create);
            PathDBNums.Add(IntegerToTObject(-(1+G)));
            With TStringList(Paths.Objects[Paths.Count-1]) Do
              begin
                Sorted := True;
                Duplicates := dupIgnore
              end;
            For K := 0 To PP.Count-1 Do
              begin
                TStringList(PP.Objects[K]).Clear;
                If TStringList(BestLL[K]).Count > 0 Then
                   begin
                     S3 := TStringList(BestLL[K]).Strings[0];
                     TStringList(PP.Objects[K]).Add(S3);
                     TStringList(Paths.Objects[Paths.Count-1]).Add(S3)
                   end
              end;
            LogMemo.Lines.Add(ObjTypes[F].ClsID + ': RAWDB['+IntToStr(G)+']: [' + S2 + ']');
            For K := 0 To BestLL.Count-1 Do
                TStringList(BestLL[K]).Free;
            BestLL.Free;
            LL.Free
          end;

      AppendStr(Script, '@versions(Auto)' + CRLF);
      For G := 0 To 255 Do
        If G in ObjInfo[F].TableNums Then
           AppendStr(Script, '@fast('+dbconsts+IntToStr(G)+',"'+dbconsts+IntToStr(G)+'.csv").' + CRLF);
      For G := 0 To 255 Do
        If G in ObjInfo[F].RawTableNums Then
           AppendStr(Script, '@fast('+dbtables+IntToStr(G)+',"'+dbtables+IntToStr(G)+'.csv").' + CRLF);
      If BoundSentences[TObjectToInteger(Templates[0])] = '$' Then
         begin
           AppendStr(Script, '@global_unique(PROCESS,1):-' + CRLF);
           AppendStr(Script, '  ($)->{END}.' + CRLF)
         end
      Else
         begin
            AppendStr(Script, '@context(PREV,infinity):-' + CRLF);
            AppendStr(Script, '  (((^)|(\.)+)(\s*\\n)*)\s*.' + CRLF);
            AppendStr(Script, '@glue:-.' + CRLF);
            AppendStr(Script, '@global_unique(MAIN,1):-' + CRLF);
            Found := False;
            For G := 0 To PathDBNums.Count-1 Do
              If TObjectToInteger(PathDBNums[G]) <> 0 Then
                 begin
                   Found := True;
                   Break
                 end;
            If Found Then
               begin
                 AppendStr(Script, '   ');
                 For G := 0 To PathDBNums.Count-1 Do
                   If TObjectToInteger(PathDBNums[G]) <> 0 Then
                      begin
                        AppendStr(Script, '()->{V'+IntToStr(G)+'}');
                        If TObjectToInteger(PathDBNums[G]) < 0 Then
                           AppendStr(Script, '()->{VRES'+IntToStr(-TObjectToInteger(PathDBNums[G])-1)+'}');
                      end;
                 AppendStr(Script, CRLF);
               end;
            If NonWords[F].Count > 0 Then
               begin
                 AppendStr(Script, '   ((');
                 K := TObjectToInteger(Templates[0]);
                 For G := 0 To NonWords[K].Count-1 Do
                   begin
                     H := NonWords[K].IndexOfObject(IntegerToTObject(G));
                     If (NonWords[K][H][1] = '''') Or (NonWords[K][H][1] = '"') Then
                        AppendStr(Script, '[^\x22\x27\.]+[\x22\x27]([^\x22\x27]+)->{P' + IntToStr(G) + '}[\x22\x27]')
                     Else
                        AppendStr(Script, '[^\w\.]+(\w+)->{P' + IntToStr(G) + '}')
                   end;
                 AppendStr(Script, '[^\.]*\.)->{Grammar.ru{SENTENCE}}(*PRUNE))?=>{' + CRLF)
               end
            Else
               AppendStr(Script, '   (([^\.]+\.)->{Grammar.ru{SENTENCE}}(*PRUNE))?=>{' + CRLF);
            If MAINF <> '' Then
               begin
                S2 := MAINF + '1';
                S3 := '';
                S4 := '';
                If TObjectToInteger(PathDBNums[0]) = 0 Then
                   begin
                     AppendStr(S2,'i');
                     AppendStr(S3, ''''+TStringList(Paths.Objects[0]).Strings[0]+''',')
                   end
                Else
                   begin
                     AppendStr(S2,'o');
                     AppendStr(S3, '$V0,');
                     AppendStr(S4, ','+dbconsts+IntToStr(TObjectToInteger(PathDBNums[0])-1)+'(V0)')
                   end;
                If TObjectToInteger(PathDBNums[1]) = 0 Then
                   begin
                     AppendStr(S2,'i');
                     AppendStr(S3, ''''+TStringList(Paths.Objects[1]).Strings[0]+''',')
                   end
                Else
                   begin
                     AppendStr(S2,'o');
                     AppendStr(S3, '$V1,');
                     AppendStr(S4, ','+dbconsts+IntToStr(TObjectToInteger(PathDBNums[1])-1)+'(V1)')
                   end;
                Funcs.Add(S2);
                AppendStr(Script,'      xpathf(SENTENCE,'''+S2+''','+S3+'''true'')'+S4)
               end;
            For G := 2 To Paths.Count-1 Do
              begin
                For K := 0 To G-1 Do
                  If Copy(Paths[G],1,Length(Paths[K])) = Paths[K] Then
                     begin
                        S2 := RemoveSqrBrackets(Copy(Paths[G],Length(Paths[K])+1, 2048));
                        If Length(S2) > 0 Then
                           begin
                              AppendStr(S2,'i');
                              S3 := '';
                              S4 := '';
                              If TObjectToInteger(PathDBNums[K]) = 0 Then
                                 AppendStr(S3, ''''+TStringList(Paths.Objects[K]).Strings[0]+''',')
                              Else
                                 AppendStr(S3, 'V'+IntToStr(K)+',')
                           end
                        Else If TObjectToInteger(PathDBNums[K]) <> 0 Then
                           S3 := 'V'+IntToStr(K)+',';
                        Break
                     end;
                If Length(S2) > 0 Then
                   begin
                      If TObjectToInteger(PathDBNums[G]) = 0 Then
                         begin
                           AppendStr(S2,'i');
                           AppendStr(S3, ''''+TStringList(Paths.Objects[G]).Strings[0]+''',')
                         end
                      Else
                         begin
                           AppendStr(S2,'o');
                           AppendStr(S3, '$V'+IntToStr(G)+',');
                           AppendStr(S4, ','+dbtables+IntToStr(-TObjectToInteger(PathDBNums[G])-1)+'(V'+IntToStr(G)+',$VRES'+IntToStr(-TObjectToInteger(PathDBNums[G])-1)+')')
                         end;
                      Funcs.Add(S2);
                      AppendStr(Script, ',' + CRLF + '      ');
                      AppendStr(Script,'xpathf(SENTENCE,'''+S2+''','+S3+'''true'')'+S4)
                   end
                Else If TObjectToInteger(PathDBNums[G]) <> 0 Then
                   begin
                      AppendStr(Script, ',' + CRLF + '      ');
                      AppendStr(Script,dbtables+IntToStr(-TObjectToInteger(PathDBNums[G])-1)+'('+S3+'$VRES'+IntToStr(-TObjectToInteger(PathDBNums[G])-1)+')')
                   end
              end;
            AppendStr(Script, CRLF + '   }.' + CRLF)
         end;

      Goal := ' @goal:-';
      Asserter := '';
      If ObjInfo[F].ParamsMap.Count > 0 Then
         begin
            AppendStr(Script, ' @auto:-');
            For G := 0 To ObjInfo[F].ParamsMap.Count-1 Do
                begin
                  If G > 0 Then
                     AppendStr(Script, ',');
                  S1 := ObjInfo[F].ParamsMap.Names[G];
                  S2 := ObjInfo[F].ParamsMap.Values[S1];
                  If S2 = 'randomid()' Then
                     begin
                       AppendStr(Script, S2 + ' => "' + S1 + '"');
                       If Length(Asserter) = 0 Then
                          Asserter := '''randomid'''
                       Else
                          AppendStr(Asserter, ',''randomid''')
                     end
                  Else
                     begin
                        S4 := '';
                        S3 := '';
                        S5 := '';
                        H := 1;
                        While H <= Length(S2) Do
                           begin
                              If (S2[H] = Dollar) Or (S2[H] = Pound) Then
                                 begin
                                   H1 := H - 1 + Pos(')', Copy(S2, H, 16384));
                                   If (S2[H+2] = '''') Or (S2[H+2] = '"') Then
                                      K := StrToInt(Copy(S2, H+3, H1-H-3))
                                   Else
                                      K := StrToInt(Copy(S2, H+2, H1-H-2));
                                   If S2[H] = Pound Then
                                      begin
                                        AppendStr(S3, S4 + 'MAIN:"//VRES'+IntToStr(K)+'/text()"');
                                        AppendStr(Goal, 'xpath(''MAIN'',''//VRES'+IntToStr(K)+'/text()'',[V'+S1+'Text'+IntToStr(H)+']),')
                                      end
                                   Else
                                      begin
                                        AppendStr(S3, S4 + 'MAIN:"//P'+IntToStr(K)+'/text()"');
                                        AppendStr(Goal, 'xpath(''MAIN'',''//P'+IntToStr(K)+'/text()'',[V'+S1+'Text'+IntToStr(H)+']),')
                                      end;
                                   If Length(S5) = 0 Then
                                      S5 := 'V'+S1+'Text'+IntToStr(H)
                                   Else
                                      AppendStr(S5, '#@#V'+S1+'Text'+IntToStr(H));
                                   H := H1+1
                                 end
                              Else
                                 begin
                                   If Length(S5) <> 0 Then
                                      AppendStr(S5, '#@#');
                                   AppendStr(S5, '''');
                                   AppendStr(S3, S4+'"');
                                   While (H <= Length(S2)) And (S2[H] <> Dollar) And (S2[H] <> Pound) Do
                                     begin
                                       AppendStr(S3, S2[H]);
                                       AppendStr(S5, S2[H]);
                                       Inc(H)
                                     end;
                                   AppendStr(S5, '''');
                                   AppendStr(S3, '"')
                                 end;
                              S4 := '+'
                           end;
                        If Length(S5) > 0 Then
                           If Pos('#@#', S5) = 0 Then
                              If Length(Asserter) = 0 Then
                                 Asserter := S5
                              Else
                                 AppendStr(Asserter, ','+S5)
                           Else
                              begin
                                H := Pos('#@#', S5);
                                V1 := Copy(S5, 1, H-1);
                                S5 := Copy(S5, H+3, 32768);
                                While Length(S5) > 0 Do
                                  begin
                                    H := Pos('#@#', S5);
                                    if H = 0 Then
                                       begin
                                          V2 := S5;
                                          S5 := ''
                                       end
                                    Else
                                       begin
                                         V2 := Copy(S5, 1, H-1);
                                         S5 := Copy(S5, H+3, 32768)
                                       end;
                                    AppendStr(Goal, 'atom_concat('+V1+','+V2+',');
                                    V1 := UpperCase(RandomName());
                                    AppendStr(Goal, V1+'),')
                                  end;
                                If Length(Asserter) = 0 Then
                                   Asserter := V1
                                Else
                                   AppendStr(Asserter, ','+V1)
                              end;
                        AppendStr(Script, S3 + ' => "' + S1 + '"')
                     end
                end;
            AppendStr(Script, '.' + CRLF)
         end;
      If Length(Asserter) > 0 Then
         AppendStr(Goal, 'assertz('+LowerCase(Copy(ObjTypes[F].ClsID, 4, 8192))+'('+Asserter+')),');
      AppendStr(Script, Goal+'!.' + CRLF);
      AppendStr(Script, ' @done:-clear_db.' + CRLF);

      For G := 0 To Paths.Count-1 Do
          With TStringList(Paths.Objects[G]) Do
            If (Count = 0) Or ((Count > 0) And Not Assigned(Objects[0])) Then
               Free;
      PathDBNums.Free;
      Paths.Free;

      LogMemo.Lines.Add(ObjTypes[F].ClsID + '!' + CRLF + Script);
      Result.Add(Script)
    end;
  Templates.Free;

  For F := 0 To Funcs.Count-1 Do
    begin
      MAINF := Funcs[F];
      V1 := '$' + MAINF[Length(MAINF)-1] + '0';
      V2 := '$' + MAINF[Length(MAINF)] + '1';
      S2 := '* ' + MAINF;
      MAINF := Copy(MAINF, 1, Length(MAINF)-2);
      Funcs.Objects[F] := TStringList.Create;
      With TStringList(Funcs.Objects[F]) Do
        begin
          AppendStr(S2,'(');
          If V1[2] = 'o' Then AppendStr(S2,'&');
          AppendStr(S2, V1 + ',');
          If V2[2] = 'o' Then AppendStr(S2,'&');
          AppendStr(S2, V2 + '): ');
          G := 1;
          LinkNum := 0;
          While G <= Length(MAINF) Do
            begin
              Link := '';
              While (MAINF[G] <> '0') And (MAINF[G] <> '1') Do
                begin
                  AppendStr(Link, MAINF[G]);
                  Inc(G)
                end;
              If MAINF[G] = '1' Then
                 begin
                   TAG1 := 'Left';
                   TAG2 := 'Right'
                 end
              Else
                 begin
                   TAG1 := 'Right';
                   TAG2 := 'Left'
                 end;
              Inc(G);
              AppendStr(S2, '(count(/*/Link[Name/text()="' + Link + '" and ');
              If LinkNum = 0 Then
                 If V1[2] = 'i' Then
                    AppendStr(S2, TAG1+'/Value/text()='+V1)
                 Else
                    AppendStr(S2, 'set('+V1+','+TAG1+'/Value/text())')
              Else
                 AppendStr(S2, TAG1+'/Value/text()=$j'+IntToStr(LinkNum-1));
              AppendStr(S2, ' and ');
              If G > Length(MAINF) Then
                 If V2[2] = 'i' Then
                    AppendStr(S2, TAG2+'/Value/text()='+V2)
                 Else
                    AppendStr(S2, 'set('+V2+','+TAG2+'/Value/text())')
              Else
                 AppendStr(S2, 'set($j'+IntToStr(LinkNum)+','+TAG2+'/Value/text())');
              AppendStr(S2, ']) > 0)');
              If G <= Length(MAINF) Then
                 AppendStr(S2, ' and ');
              Inc(LinkNum)
            end;
          AppendStr(S2, '.' + CRLF);
          Add(S2)
        end
    end;

  For F := 0 To DBases.Count-1 Do
    With TStringList(DBases[F]) Do
      LogMemo.Lines.Add('['+IntToStr(F)+'] = '+DelimitedText);

  For F := 0 To NObjTypes-1 Do
      IsSubSetOf[F].Free;
  For F := 0 To High(UniqueCommonWords) Do
      UniqueCommonWords[F].Free;
  For F := 0 To High(CommonWords) Do
      CommonWords[F].Free;
  For F := 0 To High(Words) Do
      begin
        Words[F].Free;
        NonWords[F].Free;
        SetLength(GrammarLinks[F], 0);
        MappedParams[F].Free
      end;

  For F := 0 To RawDBases.Count-1 Do
      With TStringList(RawDBases[F]) Do
        begin
           S3 := '';
           For K := 0 To Count-1 Do
               AppendStr(S3, Strings[K]+'=['+TStringList(Objects[K]).DelimitedText+'] ');
           LogMemo.Lines.Add('*['+IntToStr(F)+'] is <'+S3+'>')
        end;

  StartDualBases := DBases.Count;

  For F := 0 To RawDBases.Count-1 Do
      With TStringList(RawDBases[F]) Do
        begin
          DBases.Add(TStringList.Create);
          For G := 0 To Count-1 Do
            begin
              S2 := TStringList(Objects[G]).Strings[0] + ',' + Strings[G];
              TStringList(DBases[DBases.Count-1]).Add(S2);
              TStringList(Objects[G]).Free
            end;
          Free
        end;
  RawDBases.Free;

  SortedClasses := TStringList.Create;
  For F := 0 To NObjTypes-1 Do
      SortedClasses.Add(ObjTypes[F].ClsID)
end;

function TInductRulesForm.StringReplaceMask(var Mask: String; Where: String;
  const What, Become: String): String;

Var S: String;
    F, G, K: Integer;
begin
   F := Pos(' ', Mask);
   If F > 0 Then
     Repeat
       G := F+1;
       While (G <= Length(Mask)) And (Mask[G] = ' ') Do
         Inc(G);
       If G-F >= Length(What) Then
          begin
            S := Copy(Where, F, G-F);
            K := Pos(What, S);
            If K = 0 Then
               F := G
            Else
               begin
                 Where := Copy(Where, 1, F-1+K-1) + Become + Copy(Where, F-1+K+Length(What), 16384);
                 Mask := Copy(Mask, 1, F-1+K-1) + StringOfChar('*', Length(Become)) + Copy(Mask, F-1+K+Length(What), 16384);
                 F := F-1+K+Length(Become)
               end
          end
       Else
          F := G;
       G := Pos(' ', Copy(Where, F, 16384));
       If G = 0 Then Break;
       F := F-1 + G
     Until False;
   Result := Where
end;

procedure TInductRulesForm.FormCreate(Sender: TObject);
begin
  BoundSentences := TStringList.Create;
  PathToIm := ''
end;

procedure TInductRulesForm.FormDestroy(Sender: TObject);

Var F: Integer;
begin
  With lbModels Do
    For F := 0 To Count-1 Do
      Items.Objects[F].Free;
  BoundSentences.Free
end;

procedure TInductRulesForm.lbModelsSelectionChange(Sender: TObject;
  User: boolean);
begin
  tvClasses.Selected := Nil;
  lbObjs.Clear;
  edPhrase.Text := '';
  memInducer.Clear;
  btSaveScript.Enabled := False
end;

procedure TInductRulesForm.memImChange(Sender: TObject);
begin
  btSaveIm.Enabled := True
end;

procedure TInductRulesForm.memInducerChange(Sender: TObject);
begin
  btSaveScript.Enabled := True
end;

procedure TInductRulesForm.tvClassesSelectionChanged(Sender: TObject);

Var S: TSystem;
    Path: String;
    F: Integer;
begin
   lbObjs.Clear;
   If (lbModels.ItemIndex >= 0) And Assigned(tvClasses.Selected) Then
      begin
        S := TSystem(lbModels.Items.Objects[lbModels.ItemIndex]);
        For F := 0 To S.Elements.Count-1 Do
          If TElement(S.Elements[F]).Ref = TElementReg(tvClasses.Selected.Data) Then
             lbObjs.Items.AddObject(TElement(S.Elements[F]).Ident, S.Elements[F])
      end;
   memInducer.Clear;
   btSaveScript.Enabled := False;
   If Assigned(tvClasses.Selected) Then
      begin
        Path := ExcludeTrailingBackSlash(TElementReg(tvClasses.Selected.Data).GetBasePath);
        If FileExists(Path + MacroFile) Then
           memInducer.Lines.LoadFromFile(Path + MacroFile);
        btSaveScript.Enabled := False
      end
end;

procedure TInductRulesForm.btGenerateClick(Sender: TObject);

Var SortedClasses: TStringList;
    Scripts: TStringList;
    DBases: TList;
    Funcs, Rules: TStringList;
    StartDualBases: Integer;
    Content: TStringList;
    Henealogy: Array Of Array Of TElementReg;
    Root: TElementReg;
    S, S1: String;
    Error: Boolean;
(*
    L1, L2: String;
    S1, S2: TSystem;
*)
    F, G: Integer;
begin
  If (edConstsName.Text = '') Or (edTablesName.Text = '') Then
     begin
       MessageDlg('Ошибка', 'Заполните базовые имена таблиц и констант!', mtError, [mbOk], 0);
       Exit
     end;
  If edConstsName.Text = edTablesName.Text Then
     begin
       MessageDlg('Ошибка', 'Базовые имена таблиц и констант не должны совпадать!', mtError, [mbOk], 0);
       Exit
     end;
(*
  S1 := TSystem.LoadFromFile(L1, '_S1.xml', Nil, Nil);
  S2 := TSystem.LoadFromFile(L2, '_S2.xml', Nil, Nil);
*)
(*
  BoundSentences.AddObject('Составить программу.',S1.FindElement('PROG'));
  BoundSentences.AddObject('Ввести скаляр max.',S1.FindElement('max'));
  BoundSentences.AddObject('Введем вектор V из 10 элементов.',S1.FindElement('V'));
  BoundSentences.AddObject('Введем вектор V с клавиатуры.',S1.FindElement('inV'));
  BoundSentences.AddObject('Найдем также максимум вектора V и поместим результат в скаляр max.',S1.FindElement('MaxVmax'));
  BoundSentences.AddObject('Вывести скаляр max на экран.',S1.FindElement('outmax'));
  BoundSentences.AddObject('Тест "1 2 3 4 5 6 7 8 9 10" дает "V[0] = V[1] = V[2] = V[3] = V[4] = V[5] = V[6] = V[7] = V[8] = V[9] = max = 10.000000".', S1.FindElement('iolzcf'));

  BoundSentences.AddObject('Написать программу.',S2.FindElement('PROG'));
  BoundSentences.AddObject('Определить скаляр max.',S2.FindElement('max'));
  BoundSentences.AddObject('Ввести скаляр min.',S2.FindElement('min'));
  BoundSentences.AddObject('Введем вектор V из 10 элементов.',S2.FindElement('V'));
  BoundSentences.AddObject('Зададим вектор V с клавиатуры.',S2.FindElement('inV'));
  BoundSentences.AddObject('Найдем минимум вектора V и поместим результат в скаляр min.',S2.FindElement('MinVmin'));
  BoundSentences.AddObject('Определим также максимум вектора V и поместим результат в скаляр max.',S2.FindElement('MaxVmax'));
  BoundSentences.AddObject('Вывести скаляр min на экран.',S2.FindElement('outmin'));
  BoundSentences.AddObject('Вывести скаляр max на экран.',S2.FindElement('outmax'));
  BoundSentences.AddObject('Вывести вектор V на экран.',S2.FindElement('outV'));
*)
  memIm.Clear;
  memIni.Clear;

  Rules := BuildRules(BoundSentences);
  memIm.Lines.Add('@versions(Auto)');
  memIm.Lines.AddStrings(Rules);
  memIm.Lines.Add('');
  Rules.Free;

  Scripts := BuildRegExps(BoundSentences, edConstsName.Text, edTablesName.Text,
     SortedClasses, DBases, StartDualBases, Funcs, Error);

  LogMemo.Lines.Add(SortedClasses.DelimitedText);

  With DBases Do
    begin
      For F := 0 To Count-1 Do
        begin
          If F < StartDualBases Then
             LogMemo.Lines.Add('-- '+edConstsName.Text+IntToStr(F)+' --')
          Else
             LogMemo.Lines.Add('-- '+edTablesName.Text+IntToStr(F-StartDualBases)+' --');
          LogMemo.Lines.AddStrings(TStringList(Items[F]))
        end
    end;
  With Funcs Do
     For F := 0 To Count-1 Do
       LogMemo.Lines.AddStrings(TStringList(Objects[F]));

  If Error Then
     MessageDlg('Ошибка!', 'Индукция завершилась неуспешно!', mtError, [mbOk], 0)
  Else If MessageDlg('Информация', 'Mac/Im-скрипты+CSV-файлы успешно сгенерированы. Сохранить их?', mtConfirmation, [mbYes, mbNo], 0) = mrYes Then
    begin
      For F := 0 To Scripts.Count-1 Do
        begin
          S := ExcludeTrailingBackSlash(FindElementRegByID(SortedClasses[F]).GetBasePath) + MacroFile;
          Content := TStringList.Create;
          If FileExists(S) Then
             begin
               Content.LoadFromFile(S);
               If (Content.Count > 0) And (Content[0] = '@versions(Auto)') Then
                  begin
                    Content.Delete(0);
                    While (Content.Count > 0) And (Copy(Content[0],1,Length('@versions')) <> '@versions') Do
                      Content.Delete(0)
                  end
             end;
          Content.Insert(0, Scripts[F]);
          Content.SaveToFile(S);
          Content.Free
        end;
      If Assigned(tvClasses.Selected) Then
         begin
           S := ExcludeTrailingBackSlash(TElementReg(tvClasses.Selected.Data).GetBasePath);
           If FileExists(S + MacroFile) Then
              memInducer.Lines.LoadFromFile(S + MacroFile);
           btSaveScript.Enabled := False
         end;
      With Funcs Do
        For F := 0 To Count-1 Do
            memIm.Lines.AddStrings(TStringList(Objects[F]));

      SetLength(Henealogy, SortedClasses.Count);
      For F := 0 To SortedClasses.Count-1 Do
        begin
          SetLength(Henealogy[F], 100);
          G := 1;
          Henealogy[F][0] := FindElementRegByID(SortedClasses[F]);
          While Assigned(Henealogy[F][G-1]) Do
            begin
              Henealogy[F][G] := Henealogy[F][G-1].Parent;
              Inc(G)
            end;
          SetLength(Henealogy[F], G-1);
        end;
      G := 0;
      Repeat
         Root := Henealogy[0][High(Henealogy[0])-G];
         For F := 1 To SortedClasses.Count-1 Do
            If Henealogy[F][High(Henealogy[F])-G] <> Root Then
               begin
                 Root := Nil;
                 Break
               end;
         If Assigned(Root) Then
            begin
              Inc(G);
              For F := 0 To SortedClasses.Count-1 Do
                If G > High(Henealogy[F]) Then
                   begin
                     Root := Nil;
                     Break
                   end;
              If Not Assigned(Root) Then
                 begin
                   Root := Henealogy[0][High(Henealogy[0])-G+1];
                   Break
                 end
            end
         Else
            begin
              If G > 0 Then
                 Root := Henealogy[0][High(Henealogy[0])-G+1];
              Break
            end
      Until False;
      While Assigned(Root) Do
        begin
          S := ExcludeTrailingBackSlash(Root.GetBasePath) + XPathFile;
          S1 := ExcludeTrailingBackSlash(Root.GetBasePath) + LogFile;
          If FileExists(S) Then Break;
          Root := Root.Parent
        end;
      If Assigned(Root) Then
         begin
            Content := TStringList.Create;
            If FileExists(S) Then
               begin
                 Content.LoadFromFile(S);
                 If (Content.Count > 0) And (Content[0] = '@versions(Auto)') Then
                    begin
                      Content.Delete(0);
                      While (Content.Count > 0) And (Copy(Content[0],1,Length('@versions')) <> '@versions') Do
                        Content.Delete(0)
                    end
               end;
            If FileExists(S1) Then
               If MessageDlg('Внимание!', 'Обнаружен старый файл БД индукций (лог-файл)! Рекомендуется его удалить (во избежание проблем). Удалить?', mtConfirmation, [mbYes, mbNo], 0) = mrYes Then
                  DeleteFile(S1);
            Content.Insert(0, memIm.Lines.Text);
            memIm.Clear;
            memIm.Lines.Assign(Content);
            Content.SaveToFile(S);
            btSaveIm.Enabled := False;
            PathToIm := S;
            Content.Free
         end
      Else
         MessageDlg('Ошибка!', 'Не обнаружен базовый im-файл! Сохраните его вручную!', mtError, [mbOk], 0);

      With DBases Do
        For F := 0 To Count-1 Do
          begin
            If F < StartDualBases Then
               S := edConstsName.Text+IntToStr(F)+'.csv'
            Else
               S := edTablesName.Text+IntToStr(F-StartDualBases)+'.csv';
            StoreWithBackup(TStringList(Items[F]), S)
          end;
      memIni.Lines.Add('Versions=Auto');
      memIni.Lines.Add('Order='+SortedClasses.DelimitedText)
    end;

  If Not Error Then
     MessageDlg('Информация', 'ini-файл не сохранен. Просмотрите предложенные исправления и сохраните его вручную', mtInformation, [mbOk], 0);

  With DBases Do
    begin
      For F := 0 To Count-1 Do
          TStringList(Items[F]).Free;
      Free
    end;
  With Funcs Do
    begin
      For F := 0 To Count-1 Do
          TStringList(Objects[F]).Free;
      Free
    end;
  SortedClasses.Free;
  Scripts.Free;
//  S1.Free;
//  S2.Free;
end;

procedure TInductRulesForm.btAddPhrasedObjClick(Sender: TObject);
begin
  If (edPhrase.Text <> '') And (lbObjs.ItemIndex >= 0) And
     (BoundSentences.IndexOfObject(lbObjs.Items.Objects[lbObjs.ItemIndex]) < 0) Then
     begin
       BoundSentences.AddObject(UnifyStrings(edPhrase.Text), lbObjs.Items.Objects[lbObjs.ItemIndex]);
       lbBound.Items.AddObject(
          TElementReg(tvClasses.Selected.Data).ClsId +
          '\' +
          lbModels.Items[lbModels.ItemIndex] +
          '\' +
          TElement(lbObjs.Items.Objects[lbObjs.ItemIndex]).Ident +
          ' : ' +
          edPhrase.Text,
          lbObjs.Items.Objects[lbObjs.ItemIndex]
       );
     end;
end;

procedure TInductRulesForm.btAutoFillClick(Sender: TObject);

Var L: TStringList;
    Buf, Sent: String;
    QuoteMode: Boolean;
    F, G, K: Integer;
begin
  If lbModels.ItemIndex >= 0 Then
     If OpenTxtDialog.Execute Then
        begin
          L := TStringList.Create;
          L.LoadFromFile(OpenTxtDialog.FileName);
          F := 0;
          Buf := '';
          Sent := '';
          With TSystem(lbModels.Items.Objects[lbModels.ItemIndex]) Do
            For G := 0 To Elements.Count - 1 Do
              begin
                If (F = L.Count) And (Length(Buf) = 0) Then
                   begin
                     MessageDlg('Ошибка', 'В текстовом файле меньше объектов, чем в модели!', mtError, [mbOk], 0);
                     Break
                   end;
                Sent := '';
                QuoteMode := False;
                Repeat
                  While (F < L.Count) And (Length(Buf) = 0) Do
                     begin
                       Buf := L[F];
                       If Length(Buf) = 0 Then
                          AppendStr(Sent, CRLF);
                       Inc(F)
                     end;
                  K := 1;
                  While (K <= Length(Buf)) And (QuoteMode Or (Buf[K] <> '.')) Do
                    begin
                      If Buf[K] = '"' Then
                         QuoteMode := Not QuoteMode;
                      Inc(K)
                    end;
                  AppendStr(Sent, Copy(Buf, 1, K));
                  If K <= Length(Buf) Then
                     begin
                       Buf := Copy(Buf, K+1, 16*65536);
                       Break
                     end;
                  AppendStr(Sent, CRLF);
                  Buf := '';
                  If F = L.Count Then
                     Sent := '#ERROR#'
                Until Sent = '#ERROR#';
                If Sent = '#ERROR#' Then
                   begin
                     MessageDlg('Ошибка', 'В текстовом файле меньше объектов, чем в модели!', mtError, [mbOk], 0);
                     Break
                   end;
                BoundSentences.AddObject(Trim(UnifyStrings(Sent)), Elements[G]);
                lbBound.Items.AddObject(
                   TElement(Elements[G]).Ref.ClsId +
                   '\' +
                   lbModels.Items[lbModels.ItemIndex] +
                   '\' +
                   TElement(Elements[G]).Ident +
                   ' : ' +
                   Trim(Sent),
                   Elements[G]
                );
              end;
          L.Free;
          tvClassesSelectionChanged(Nil)
        end
end;

procedure TInductRulesForm.btDelPhrasedObjClick(Sender: TObject);

Var F: Integer;
begin
  If lbBound.ItemIndex >= 0 Then
     begin
        F := 0;
        While F < BoundSentences.Count Do
          If BoundSentences.Objects[F] = lbBound.Items.Objects[lbBound.ItemIndex] Then
             BoundSentences.Delete(F)
          Else
             Inc(F);
        lbBound.Items.Delete(lbBound.ItemIndex)
     end
end;

procedure TInductRulesForm.btLoadModelClick(Sender: TObject);

Var L: String;
    Name: String;
    K: Word;
    S: TSystem;
begin
  If OpenModelDialog.Execute Then
     begin
       S := TSystem.LoadFromFile(L, OpenModelDialog.FileName, Nil, Nil);
       Name := ExtractFileName(OpenModelDialog.FileName);
       If lbModels.Items.IndexOf(Name) >= 0 Then
          begin
            K := 1;
            While lbModels.Items.IndexOf(Name+'('+IntToStr(K)+')') >= 0 Do
              Inc(K);
            AppendStr(Name, '('+IntToStr(K)+')')
          end;
       lbModels.Items.AddObject(Name, S);
       tvClasses.Selected := Nil;
       lbObjs.Clear;
       MemInducer.Clear;
       btSaveScript.Enabled := False;
       edPhrase.Text := '';
     end;
end;

procedure TInductRulesForm.btLoadProjectClick(Sender: TObject);

Var Mem, Mem2: String;
    L, L1: String;
    T: TStringList;
    S: TSystem;
    E: TElement;
    F, G, K, N: Integer;
begin
  If OpenProjectDialog.Execute Then
     begin
       lbObjs.Clear;
       PathToIm := '';
       edPhrase.Text := '';
       BoundSentences.Clear;
       lbBound.Clear;
       tvClasses.Selected := Nil;
       memInducer.Clear;
       btSaveScript.Enabled := False;
       For F := 0 To lbModels.Count-1 Do
         lbModels.Items.Objects[F].Free;
       memIm.Clear;
       btSaveIm.Enabled := False;
       memIni.Clear;
       lbModels.Clear;
       With TStringList.Create Do
         begin
           LoadFromFile(OpenProjectDialog.FileName);
           edConstsName.Text := Strings[0];
           edTablesName.Text := Strings[1];
           N := StrToInt(Strings[2]);
           K := 3;
           For F := 0 To N-1 Do
             begin
               Inc(K);
               Mem := Strings[K];
               Mem2 := '';
               For G := 0 To (Length(Mem) Div 4)-1 Do
                   AppendStr(Mem2, WideChar(Hex2Dec(Copy(Mem, 1+G*4, 4))));
               Inc(K);
               T := TStringList.Create;
               T.Text := Mem2;
               T.SaveToFile(TempXML);
               T.Free;
               lbModels.Items.AddObject(Strings[K-2], TSystem.LoadFromFile(L, TempXML, Nil, Nil))
             end;
           N := StrToInt(Strings[K]);
           Inc(K);
           For F := 0 To N-1 Do
             begin
               G := StrToInt(Strings[K]);
               Inc(K);
               L := Strings[K];
               Inc(K);
               S := TSystem(lbModels.Items.Objects[G]);
               E := S.GetElement(PChar(L));
               L1 := UnEscapeString(Strings[K]);
               BoundSentences.AddObject(UnifyStrings(L1), E);
               lbBound.Items.AddObject(
                  E.Ref.ClsId +
                  '\' +
                  lbModels.Items[G] +
                  '\' +
                  L +
                  ' : ' +
                  L1,
                  E
               );
               Inc(K)
             end;
           Free
         end;
     end;
end;

procedure TInductRulesForm.btSaveImClick(Sender: TObject);
begin
  If Length(PathToIm) > 0 Then
     begin
       StoreWithBackup(memIm.Lines, PathToIm);
       btSaveIm.Enabled := False
     end
  Else
     begin
       MessageDlg('Ошибка', 'Непонятно, в какой каталог сохранять скрипт. Укажите путь к файлу', mtError, [mbOk], 0);
       If SaveImDialog.Execute Then
         begin
           PathToIm := SaveImDialog.FileName;
           btSaveImClick(Nil)
         end;
     end;
end;

procedure TInductRulesForm.btSaveProjectClick(Sender: TObject);

Var T: TStringList;
    E: TElement;
    Mem, Mem2: String;
    F, G: Integer;
begin
  If SaveProjectDialog.Execute Then
     With TStringList.Create Do
       begin
         Add(edConstsName.Text);
         Add(edTablesName.Text);
         Add(IntToStr(lbModels.Items.Count));
         For F := 0 To lbModels.Items.Count-1 Do
           begin
             TSystem(lbModels.Items.Objects[F]).SaveToXML('', TempXML);
             T := TStringList.Create;
             T.LoadFromFile(TempXML);
             Mem := T.Text;
             Mem2 := '';
             For G := 1 To Length(Mem) Do
                 AppendStr(Mem2, IntToHex(Word(Mem[G]), 4));
             Add(lbModels.Items[F]);
             Add(Mem2);
             T.Free
           end;
         Add(IntToStr(BoundSentences.Count));
         For F := 0 To BoundSentences.Count-1 Do
           begin
             E := TElement(BoundSentences.Objects[F]);
             For G := 0 To lbModels.Count-1 Do
               If TSystem(lbModels.Items.Objects[G]).Elements.IndexOf(E) >= 0 Then
                  begin
                    Add(IntToStr(G));
                    Break
                  end;
             Add(E.Ident);
             Add(EscapeString(BoundSentences[F]))
           end;
         SaveToFile(SaveProjectDialog.FileName);
         Free
       end;
end;

procedure TInductRulesForm.btSaveScriptClick(Sender: TObject);

Var Path: String;
begin
  If Assigned(tvClasses.Selected) Then
     begin
       Path := ExcludeTrailingBackSlash(TElementReg(tvClasses.Selected.Data).GetBasePath);
       StoreWithBackup(memInducer.Lines, Path + MacroFile);
       btSaveScript.Enabled := False
     end
end;

procedure TInductRulesForm.btUnloadModelClick(Sender: TObject);

Var F: Integer;
begin
  If lbModels.ItemIndex >= 0 Then
     begin
       With TSystem(lbModels.Items.Objects[lbModels.ItemIndex]) Do
         begin
           F := 0;
           While F < BoundSentences.Count Do
             If Elements.IndexOf(BoundSentences.Objects[F]) >= 0 Then
                BoundSentences.Delete(F)
             Else
                Inc(F);
           F := 0;
           While F < lbBound.Items.Count Do
             If Elements.IndexOf(lbBound.Items.Objects[F]) >= 0 Then
                lbBound.Items.Delete(F)
             Else
                Inc(F);
         end;
       lbModels.Items.Objects[lbModels.ItemIndex].Free;
       lbModels.Items.Delete(lbModels.ItemIndex);
       tvClasses.Selected := Nil;
       lbObjs.Clear;
       MemInducer.Clear;
       btSaveScript.Enabled := False;
       edPhrase.Text := '';
     end;
end;

procedure TInductRulesForm.btViewObjClick(Sender: TObject);

Var Obj: TElement;
begin
  If lbObjs.ItemIndex >= 0 Then
     begin
      Obj:=TElement(lbObjs.Items.Objects[lbObjs.ItemIndex]);
      With TEditProps.Create(Self) Do
        begin
          PutData(Obj, True);
          Process(ShowModal=mrOk, Obj);
          Free
        end
     end
end;

initialization
  {$I InductRules.lrs}

end.

