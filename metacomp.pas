unit MetaComp;

{$mode objfpc}{$H+}

{$IF DEFINED(UNIX) OR DEFINED(LINUX)}
{$linklib c}
{$linklib stdc++}
{$ENDIF}

{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, RegExpr, COMMON, dynlibs, XPath;

Const rtContext = '*'; // Немодифицируемый, многократной унифиации
      rtUnique = '+'; // Модифицируемый, Однократная унификация в пределах макроса
      rtGlobalUnique = '%'; // Модифицируемый, Однократная унификация по всем макросам
      rtHelper = '-'; // Модифицируемый, с возможностью многократной унификации

      rmGlue = '+';
      rmNonGlue = '-';

Const rrInfinity = -1;

Const rsContext = 'context';
      rsUnique = 'unique';
      rsGlobalUnique = 'global_unique';
      rsNonUnique = 'nonunique';
      rsInfinity = 'infinity';
      rsGoal = 'goal';
      rsDone = 'done';
      rsGlue = 'glue';
      rsReplace = 'replace';
      rsAuto = 'auto';

Const defGoal = '!.';
      defDone = 'true';

Const ConsultFile = 'xpath.pl';
      ScriptFile = '_script.pl';

      aliveDB = '_alive.pl';
      phoenixDB = '_phoenix.pl';

      DBFile = '_db.pl';
      OutFile = '__db.pl';

      DBGIDFile = 'db_gid.csv';

      OrderFile = 'induct.ini';

      XPathModelFile = '__xpath.xml';

Type LockArray = Array Of Integer;

     IDArray = Array Of String;

     { ScanMacro }

     ScanMacro = Class // Макрос
     Private
       FRegExps: TStringList; // Все шаблоны (контексты, уникальные и справочные),
       // в порядке поиска
       FRepeats: TList; // Максимальные количества повторений шаблонов (-1 = полный перебор)
       // Модифицирующий доказуемый предикат
       FGoal: String;
       FDone: String;
       // Дополнительные предикаты
       FPredicates: TStringList;
       // Заменители
       FReplacers: TStringList;
       procedure SetDone(AValue: String);
       procedure SetGoal(AValue: String);
     Public
       Constructor Create;
       Destructor Destroy; override;

       Procedure AddRegExp(Tp: Char; Rep: Integer; Const ID: String; Const RegExp: WideString; Glue: Char = rmNonGlue);
       Procedure AddPredicate(Const P: WideString);
       Procedure AddReplacer(Const R, What: String);

       Procedure SetDB(db: TFastDB);

       function ExportPredicates(Const Source: String): String;
       function ExportPascal(Var out: TStringList; Const Offs, vMac, vDB: String): Boolean;
       procedure ExportAutoGEN(Const FName: String);

       Function Apply(ENV: TXPathEnvironment; XPathing: Boolean; Var T: WideString; Var Stp, Enp: LockArray; Var IDs: IDArray; Const Consult: String; Const MacroID: String; Var CPOS: Integer): Integer;

       Function UnifyRegExps(Var Pos: Integer; patNo: Integer; Var _Stp, _Enp: LockArray): Boolean;
       Function UnifyContRegExps(Var Pos: Integer): Boolean;

       Property Goal: String read FGoal write SetGoal;
       Property Done: String read FDone write SetDone;
     End;

     OnTaktHandler = Procedure(Percent: Real; Const MacroID: String = '') Of Object;

     { MetaCompiler }

     MetaCompiler = Class // Обработчик группы макросов
     Private
       FText: WideString; // Текст файла
       // Позиции начал и концов блокированных для анализа фрагментов
       FLockStarts: LockArray;
       FLockEnds: LockArray;
       FLockIDs: IDArray;

       FMacros : TStringList;
       function GetLockID(i: Integer): String;
       function GetNLocks: Integer;
     Public
       Constructor Create(Const S: WideString);
       Destructor Destroy; override;

       function AddMacro(Const ID: String): ScanMacro;
       procedure ExportAutoGEN;
       function ExportPascal(Var Out: TStringList; Const Offs, vComp, vMac, vDB: String): Boolean;
       procedure Run(ENV: TXPathEnvironment; XPathing: Boolean; P: OnTaktHandler);
       procedure RunContinuous(ENV: TXPathEnvironment; XPathing: Boolean; P: OnTaktHandler);

       property Text: WideString read FText;
       property NLocks: Integer read GetNLocks;
       property LockIDs[i: Integer]:String read GetLockID;
     End;

implementation

Uses Lexique, AutoConsts{$IF DEFINED(LCL) OR DEFINED(VCL)},Dialogs{$ENDIF};

(* *)
Type run_gprolog7 = Function(Dir, ConsultScript, OutFName, MainGoal, gprolog_console_out, DoneGoal, GID: PChar):Integer; cdecl;
    switch_gprolog7 = Function(gprolog_console_out: PChar): Integer; cdecl;

Var Prologer: TLibHandle = 0;

(* *)

function MetaCompiler.GetLockID(i: Integer): String;
begin
  Result := FLockIDs[i]
end;

function MetaCompiler.GetNLocks: Integer;
begin
  Result := Length(FLockIDs)
end;

constructor MetaCompiler.Create(const S: WideString);
Begin
  Inherited Create;
  FMacros := TStringList.Create;
  FText := S
End;

destructor MetaCompiler.Destroy;

Var I: Integer;
Begin
  With FMacros Do
    Begin
      For I := 0 To Count - 1 Do
          Objects[i].Free;
      Free
    End;
  Inherited Destroy
end;

function MetaCompiler.AddMacro(const ID: String): ScanMacro;
Begin
  Result := ScanMacro.Create;
  FMacros.AddObject(ID, Result)
End;

procedure MetaCompiler.ExportAutoGEN;

Var R: TextFile;
    Rule: String;
    i: Integer;
begin
  With FMacros Do
    Begin
      Rule := 'Order = ';
      For i := 0 To Count - 1 Do
          Begin
             AppendStr(Rule, Strings[i] + ',');
             ScanMacro(Objects[i]).ExportAutoGEN('induct.' + Strings[I]);
          End;
      If Count > 0 Then System.Delete(Rule, Length(Rule), 1)
    End;
  AssignFile(R, OrderFile);
  Rewrite(R);
  WriteLn(R, Rule);
  CloseFile(R)
end;

function MetaCompiler.ExportPascal(var out: TStringList; const Offs, vComp,
  vMac, vDB: String): Boolean;

Var I: Integer;
begin
  Result := True;
  With FMacros Do
      For I := 0 To Count - 1 Do
          Begin
            out.Add(Offs + vMac + ' := ' + vComp + '.AddMacro(''' + Strings[I] + ''');');
            out.Add(Offs + vDB + ' := TFastDB.Create;');
            Result := Result And ScanMacro(Objects[I]).ExportPascal(out, Offs, vMac, vDB)
          End
end;

procedure MetaCompiler.Run(ENV: TXPathEnvironment; XPathing: Boolean; P: OnTaktHandler);

Var I: Integer;
    S: TStringList;
    C: String;
    CPOS: Integer;
    doner: switch_gprolog7;
Begin
  S := TStringList.Create;
  S.LoadFromFile(ConsultFile);
  DeleteFile(XPathModelFile);
  C := S.Text;
  S.Free;
  DeleteFile(DBFile);
  Try
    With FMacros Do
      Begin
        CPOS := -1;
        For I := 0 To Count - 1 Do
            Begin
              ScanMacro(Objects[i]).Apply(ENV, XPathing, FText, FLockStarts, FLockEnds, FLockIDs, C, Strings[I], CPOS);
              If Assigned(P) Then
                 If Count > 1 Then
                    P(I/(Count-1), Strings[I])
                 Else
                    P(1.0, Strings[I])
            End;
      End
  Finally
    If (Prologer <> 0) And (Prologer <> DWORD(-1)) Then
       begin
         doner := switch_gprolog7(GetProcedureAddress(Prologer, 'done_gprolog7'));
         if Assigned(doner) Then
            doner('_.info');
         FreeLibrary(Prologer);
         Prologer := 0
       end
  end;
End;

procedure MetaCompiler.RunContinuous(ENV: TXPathEnvironment; XPathing: Boolean; P: OnTaktHandler);

Var S: TStringList;
    C: String;
    doner: switch_gprolog7;
    POS, PrevPos: Integer;
    PrevNumber: Integer;
    Success: Boolean;
    Code: Integer;
    LNG: Integer;
    I: Integer;
begin
  S := TStringList.Create;
  S.LoadFromFile(ConsultFile);
  DeleteFile(XPathModelFile);
  C := S.Text;
  S.Free;
  DeleteFile(DBFile);
  Try
    With FMacros Do
      Begin
        POS := 1;
        LNG := Length(FText);
        While POS <= LNG + 1 Do
          Begin
            Success := False;
            I := 0;
            PrevPOS := POS;
            While (I < Count) And Not Success Do
              If I = PrevNumber Then
                 Inc(I)
              Else
                begin
                  Code := ScanMacro(Objects[i]).Apply(ENV, XPathing, FText, FLockStarts, FLockEnds, FLockIDs, C, Strings[I], POS);
                  If Code > 0 Then
                     Success := True
                  Else If Code < 0 Then
                     Break
                  Else
                     Inc(I)
                end;
            LNG := Length(FText);
            If Success Then
               begin
                  If (PrevPOS = POS) And (POS = LNG + 1) Then Inc(POS);

                  If (PrevPOS = POS) And (Code = 1) Then
                     PrevNumber := I
                  Else
                     PrevNumber := -1;
                  If Assigned(P) Then
                     If LNG > 0 Then
                        P(POS/(LNG+1), '')
                     Else
                        P(1.0, '')
               end
            Else
               begin
                 {$IF DEFINED(LCL) OR DEFINED(VCL)}
                 MessageDlg('Unrecognized: [' + IntToStr(POS) + '/' + IntToStr(LNG) + ']: ' + Copy(FText, POS, 100),mtError,[mbOk],0);
                 {$ELSE}
                 WriteLn('Unrecognized: [' + IntToStr(POS) + '/' + IntToStr(LNG) + ']' + Copy(FText, POS, 100));
                 {$ENDIF}
                 Break;
               end
          End
      End
  Finally
    If (Prologer <> 0) And (Prologer <> DWORD(-1)) Then
       begin
         doner := switch_gprolog7(GetProcedureAddress(Prologer, 'done_gprolog7'));
         if Assigned(doner) Then
            doner('_.info');
         FreeLibrary(Prologer);
         Prologer := 0
       end
  end;
end;

procedure ScanMacro.SetDone(AValue: String);
begin
  if FDone = AValue then Exit;
  If (Length(AValue) > 0) And (AValue[Length(AValue)] = '.') Then
     FDone := Copy(AValue, 1, Length(AValue) - 1)
  Else
     FDone := AValue
end;

constructor ScanMacro.Create;
Begin
  Inherited Create;
  FRegExps := TStringList.Create;
  FRepeats := TList.Create;
  FGoal := defGoal;
  FDone := defDone;
  FPredicates := TStringList.Create;
  FReplacers := TStringList.Create;
End;

destructor ScanMacro.Destroy;

Var I: Integer;
Begin
  FRepeats.Free;
  With FRegExps Do
    Begin
      For I := 0 To Count - 1 Do
          Objects[i].Free;
      Free
    End;
  FPredicates.Free;
  With FReplacers Do
    begin
      For I := 0 To Count - 1 Do
          StrDispose(PChar(Objects[I]));
      Free
    end;
  Inherited Destroy
end;

procedure ScanMacro.AddRegExp(Tp: Char; Rep: Integer; const ID: String;
  const RegExp: WideString; Glue: Char = rmNonGlue);

Var R: TRegExpr;
    I: Integer;
Begin
  R := TRegExpr.Create(RegExp);
  With FRegExps Do
    For I := 0 To Count - 1 Do
        R.AddExtRegExpr(Copy(Strings[I], 3, 1024), TRegExpr(Objects[I]));
  R.Compile;
  FRegExps.AddObject(Tp + Glue + ID, R);
  FRepeats.Add(IntegerToTObject(Rep))
End;

procedure ScanMacro.AddPredicate(const P: WideString);
Begin
  FPredicates.Add(P)
End;

procedure ScanMacro.AddReplacer(const R, What: String);
begin
  FReplacers.AddObject(R, TObject(StrPCopy(StrAlloc(Length(What)+1),What)))
end;

procedure ScanMacro.SetDB(db: TFastDB);

Var F: Integer;
begin
  With FRegexps Do
     For F := 0 To Count - 1 Do
         TRegExpr(Objects[F]).SetDB(db);
end;

procedure ScanMacro.SetGoal(AValue: String);
Begin
  if FGoal = AValue then Exit;
  FGoal := AValue
End;

function ScanMacro.ExportPredicates(const Source: String): String;

Var Calls, Writes: String;
    I: Integer;
Begin
  Result := '';
  Calls := '';
  Writes := '';
  With FRegexps Do
    Begin
      For I := 0 To Count - 1 Do
          Begin
            AppendStr(Result, TRegExpr(Objects[I]).ExportPredicates(Copy(Strings[I], 3, 1024)) + #$0D#$0A);
            AppendStr(Calls, 'model(''' + Copy(Strings[I], 3, 1024) + '''),');
            AppendStr(Writes, 'write_log(''' + Copy(Strings[I], 3, 1024) + '''),')
          End
    End;
  With FPredicates Do
    For I := 0 To Count - 1 Do
        AppendStr(Result, Strings[I] + #$0D#$0A);
  AppendStr(Result, 'goal:-' + FGoal + #$0D#$0A);
  AppendStr(Result, 'saveLF :- current_predicate(P), ''$predicate_property_pi''(P,''dynamic''), listing(P), fail.' + #$0D#$0A);
  AppendStr(Result, 'saveLF :- true,!.' + #$0D#$0A);
  AppendStr(Result, 'execute:-consult('''+phoenixDB+'''),phoenix,init,' + Calls + 'goal,' + Writes + 'write(''#'').' + #$0D#$0A)
End;

function ScanMacro.ExportPascal(var out: TStringList; const Offs, vMac,
  vDB: String): Boolean;

Var I: Integer;
    S: String;
begin
  Result := True;

  With FRegExps Do
    For I := 0 To Count - 1 Do
        Begin
          S := Strings[I];
          out.Add(Offs + vMac + '.AddRegExp(''' + S[1] + ''', ' + IntToStr(TObjectToInteger(TObject(FRepeats[I]))) + ', ' +
                     '''' + Copy(S, 3, 1024) + ''', ''' + pEscapeString(TRegExpr(Objects[I]).Expression) + ''', ''' + S[2] + ''');');
        End;
  With FPredicates Do
    For I := 0 To Count - 1 Do
        out.Add(Offs + vMac + '.AddPredicate(''' + pEscapeString(Strings[I]) + ''');');
  With FReplacers Do
    For I := 0 To Count - 1 Do
        out.Add(Offs + vMac + '.AddReplacer(''' + pEscapeString(Strings[I]) + ''', ''' + pEscapeString(PChar(Objects[I])) + ''');');
  out.Add(Offs + vMac + '.Goal := ''' + pEscapeString(Goal) + ''';');
  out.Add(Offs + vMac + '.Done := ''' + pEscapeString(Done) + ''';');

  If FRegExps.Count > 0 Then
     Begin
       TRegExpr(FRegExps.Objects[0]).ExportPascalDB(out, Offs, vDB);
       out.Add(Offs + vMac + '.SetDB(' + vDB + ');')
     End
end;

procedure ScanMacro.ExportAutoGEN(const FName: String);

procedure WriteText(Var S:String; L: TStringList; Const T: String; Const Endc: Char = #0);

Var J: Integer;
Begin
  L.Text := T;
  With L Do
    For J := 0 To Count - 1 Do
        If (J <> Count - 1) Or (Endc = #0) Then
           AppendStr(S, Strings[J] + CRLF)
        Else
           AppendStr(S, Strings[J] + '.' + CRLF)
End;

Var L: TStringList;
    FS: String;
    R: TRegExpr;
    I: Integer;
begin
   L := TStringList.Create;
   FS := '';
   With FRegexps Do
     Begin
       For I := 0 To Count - 1 Do
           Begin
             R := TRegExpr(Objects[I]);
             AppendStr(FS, R.ExportDB());
             Case Strings[I][1] Of
               rtContext: AppendStr(FS, '@' + rsContext);
               rtUnique: AppendStr(FS, '@' + rsUnique);
               rtGlobalUnique: AppendStr(FS, '@' + rsGlobalUnique);
               rtHelper: AppendStr(FS, '@' + rsNonUnique)
             end;
             AppendStr(FS, '(' + Copy(Strings[I], 3, 1024) + ',');
             Case TObjectToInteger(TObject(FRepeats[I])) Of
               rrInfinity: AppendStr(FS, rsInfinity);
               Else AppendStr(FS, IntToStr(TObjectToInteger(TObject(FRepeats[I]))));
             End;
             AppendStr(FS, '):-' + CRLF);
             WriteText(FS, L, R.Expression, '.');
             If Strings[I][2] = rmGlue Then
                AppendStr(FS, rsGlue + ':-.' + CRLF)
           End
     End;
   With FPredicates Do
     For I := 0 To Count - 1 Do
         WriteText(FS, L, Strings[I]);
   With FReplacers Do
     For I := 0 To Count - 1 Do
         AppendStr(FS, '@' + rsReplace + '(' + Strings[I] + ')' + ':-' + PChar(Objects[I]) + '.' + CRLF);
   AppendStr(FS, '@' + rsGoal + ':-' + CRLF);
   WriteText(FS, L, FGoal);
   AppendStr(FS, '@' + rsDone + ':-' + CRLF);
   WriteText(FS, L, FDone, '.');
   L.Text := FS;
   L.SaveToFile(FName);
   L.Free
end;

function ScanMacro.Apply(ENV: TXPathEnvironment; XPathing: Boolean; var T: WideString; var Stp, Enp: LockArray;
  var IDs: IDArray; const Consult: String; const MacroID: String;
  var CPOS: Integer): Integer;

Type STR = Record
         First, Last: Integer
     End;

procedure InsertLock(Var Stp, Enp: LockArray; Beg, Last: Integer; Const ID: String = '');

Var J, K: Integer;
begin
  J := 0;
  While (J < Length(Enp)) And (Stp[J] <= Beg) Do
     Inc(J);
  SetLength(Stp, Length(Stp) + 1);
  SetLength(Enp, Length(Enp) + 1);
  If Length(ID) > 0 Then
     SetLength(IDs, Length(IDs) + 1);
  If J = High(Enp) Then
     Begin
       Stp[High(Stp)] := Beg;
       Enp[High(Enp)] := Last;
       If Length(ID) > 0 Then
          IDs[High(IDs)] := ID
     End
  Else
     Begin
       For K := High(Stp) Downto J + 1 Do
           Begin
             Stp[K] := Stp[K-1];
             Enp[K] := Enp[K-1];
             If Length(ID) > 0 Then
                IDs[K] := IDs[K-1]
           End;
       Stp[J] := Beg;
       Enp[J] := Last;
       If Length(ID) > 0 Then
          IDs[J] := ID
     End
end;

Var Beg, Last: Integer;
    lStp, lEnp: LockArray;
    (* *)runer: run_gprolog7; (* *)
    (* *)initer: switch_gprolog7; (* *)
    I, II, J, K, P, PP: Integer;
    DBGID: TextFile;
    Script: TextFile;
    FirstWordNum: Integer;
    Out: TextFile;
    DB: TextFile;
    Actions: TStringList;
    Strs: Array Of STR;
    newID: String;
    GIDs: String;
    GID: String;
    L: TStringList;
    A: TAnalyser;
    RG: TRegExpr;
    S, M: String;
    W, LL: String;
    TT, ST: WideString;
    D: STR;
    NODE: Real;
    VS: TVarStruct;
Begin
  Result := +1;
  If FRegExps.Count > 0 Then
     Begin
       If CPOS > 0 Then
          Begin
            I := 0;
            If (FregExps.Strings[I][1] in [rtContext,rtHelper]) Then
               Inc(I);
            While (I < FRegExps.Count) And (FregExps.Strings[I][1] in [rtUnique,rtGlobalUnique]) Do
                Inc(I);
            If (I < FRegExps.Count - 1) Or ((I = FRegExps.Count - 1) And Not (
                  (FregExps.Strings[I][1] in [rtContext,rtHelper]) And
                  (TObjectToInteger(TObject(FRepeats[I])) = 1)
               )) Then
               begin
                 {$IF DEFINED(LCL) OR DEFINED(VCL)}
                 MessageDlg('Macro(' + MacroID + '): must be: [context(inf)<glue>](unique/global_unique)+[<glue>context(1)]',mtError,[mbOk],0);
                 {$ELSE}
                 WriteLn('Macro(' + MacroID + '): must be: [context(inf)<glue>](unique/global_unique)+[<glue>context(1)]');
                 {$ENDIF}
                 Exit(-1)
               end
          End;

       For I := 0 To FRegExps.Count - 1 Do
           begin
             TRegExpr(FregExps.Objects[I]).InputString := T;
             TRegExpr(FregExps.Objects[I]).setENV(ENV);
           end;
       Actions := TStringList.Create;
       A := TAnalyser.Create(LettersSet, [Space, Tabulation]);
       PP := 1;
       lStp := Copy(Stp, 0, Length(Stp));
       lEnp := Copy(Enp, 0, Length(Enp));

       GIDs := '[';
       For I := 0 To High(IDs) Do
           AppendStr(GIDs, IDs[I] + ',');
       If Length(GIDs) = 1 Then
          GIDs := GIDs + ']'
       Else
          GIDs[Length(GIDs)] := ']';

       If FileExists(DBFile) Then
          Begin
             L := TStringList.Create;
             L.LoadFromFile(DBFile);
             If (L.Count > 0) And (Pos('global_trace', L.Strings[L.Count - 1]) > 0) Then
                Begin
                  L.Strings[L.Count - 1] := 'asserta(global_trace(' + GIDs + ')).';
                  L.SaveToFile(DBFile)
                End;
             L.Free
          End
       Else
          Begin
            AssignFile(DB, DBFile);
            Rewrite(DB);
            WriteLn(DB,'db:-');
            WriteLn(DB,'asserta(global_trace(' + GIDs + ')).');
            CloseFile(DB)
          End;

       While True Do
          Begin
            GID := '-1';
            With FRegExps Do
              For I := 0 To Count - 1 Do
                  If Strings[I][1] in [rtUnique, rtGlobalUnique] Then
                     If Strings[I][1] = rtGlobalUnique Then
                        If GID = '-1' Then
                           GID := IntToStr(Length(IDs));
            AssignFile(DBGID, DBGIDFile);
            Rewrite(DBGID);
            If Pos(',', GID) <> 0 Then
               WriteLn(DBGID, '"', GID, '"')
            Else
               WriteLn(DBGID, GID);
            CloseFile(DBGID);

            FirstWordNum := ENV.CollectedWords.Count;

            If ((CPOS < 0) And Not UnifyRegExps(PP, 0, lStp, lEnp)) Then Break;

            If ((CPOS > 0) And Not UnifyContRegExps(CPOS)) Then
               begin
                 Result := 0;
                 Break
               end;

            newID := '-1';
            With FRegExps Do
              For I := 0 To Count - 1 Do
                  If Strings[I][1] in [rtUnique, rtGlobalUnique] Then
                     Begin
                       Beg := TRegExpr(Objects[I]).MatchPos[0];
                       Last := Beg + TRegExpr(Objects[I]).MatchLen[0] - 1;
                       InsertLock(lStp, lEnp, Beg, Last);
                       If Strings[I][1] = rtGlobalUnique Then
                          Begin
                            If (Goal = defGoal) And (Done = defDone) Then
                               newID := 'gid(''' + MacroID + ''',' + IntToStr(Length(IDs)) + ')'
                            Else
                               newID := IntToStr(Length(IDs));
                            InsertLock(Stp, Enp, Beg, Last, newID)
                          End
                     End;
            If (Goal = defGoal) And (Done = defDone) Then
               begin
                 (*
                    Special Handling: No_Prolog_Call case? May be.
                 *)
                 If FReplacers.Count > 0 Then
                    For I := 0 To FReplacers.Count - 1 Do
                        begin
                          S := FReplacers.Strings[I];
                          W := PChar(FReplacers.Objects[I]);
                          If (Length(W) > 1) And (W[1] = '"') And (W[Length(W)] = '"') Then
                             W := Copy(W, 2, Length(W) - 2);
                          For J := 0 To FRegExps.Count - 1 Do
                              If Copy(FRegExps.Strings[J],3,1024) = S then
                              Begin
                                 If (FRegExps.Strings[J][1] = rtContext) Then
                                    A.MakeError('Macro ''' + MacroID + ''' : regexp(' + S + ') is not modifiable')
                                 Else
                                    Begin
                                       // Local Substitutions
                                       With TRegExpr(FRegExps.Objects[J]) Do
                                         For K := 0 To NSUBEXP - 1 Do
                                             If Assigned(VarNames[K]) Then
                                                begin
                                                  M := '${' + String(VarNames[K]) + '}';
                                                  W := StringReplace(W, M, UTF8Encode(Match[K]), [rfReplaceAll])
                                                end;
                                       For P := 0 To FRegExps.Count - 1 Do
                                           If P <> J Then
                                              With TRegExpr(FRegExps.Objects[P]) Do
                                                For K := 0 To NSUBEXP - 1 Do
                                                    If Assigned(VarNames[K]) Then
                                                       begin
                                                         M := '${' + FRegExps.Strings[P] + '.' + String(VarNames[K]) + '}';
                                                         W := StringReplace(W, M, UTF8Encode(Match[K]), [rfReplaceAll])
                                                       end;
                                       RG := TRegExpr.Create('\$\(([a-zA-Z_0-9\.\\\/\-\+]+)\)');
                                       L := TStringList.Create;
                                       While RG.Exec(W) Do
                                         Begin
                                           M := UTF8Encode(RG.Match[1]);
                                           L.LoadFromFile(M);
                                           W := StringReplace(W, '$('+M+')', EscapeString(L.Text), [])
                                         End;
                                       L.Free;
                                       RG.Free;
                                       Actions.Add('*' + W);
                                       If Actions.Count > Length(Strs) Then
                                          SetLength(Strs, Actions.Count + 20);
                                       Strs[Actions.Count - 1].First := TRegExpr(FRegExps.Objects[J]).MatchPos[0];
                                       Strs[Actions.Count - 1].Last := Strs[Actions.Count - 1].First + TRegExpr(FRegExps.Objects[J]).MatchLen[0] - 1
                                    End;
                                 Break
                              End
                        end
               end
            Else
               begin
                  AssignFile(Script, ScriptFile);
                  Rewrite(Script);
                  WriteLn(Script, Consult);
                  S := StringReplace(ExportPredicates(EscapeProlog(UTF8Encode(T))), '{*GID*}', newID, [rfReplaceAll]);
                  S := StringReplace(S, '{*WORDF*}', IntToStr(FirstWordNum), [rfReplaceAll]);
                  S := StringReplace(S, '{*WORDN*}', IntToStr(ENV.CollectedWords.Count), [rfReplaceAll]);
                  WriteLn(Script, S);
                  CloseFile(Script);
                  S:=StringReplace(ExcludeTrailingBackSlash(ExtractFilePath(ParamStr(0))),'\','/',[rfReplaceAll]);
                  (* *)
                  If Prologer = 0 Then
                     Begin
                       Prologer := LoadLibrary({$IF DEFINED(UNIX) OR DEFINED(LINUX)}'./lib' + {$ENDIF}'PrologIntrf.' + SharedSuffix);
                       If Prologer = NilHandle Then
                          Prologer := DWORD(-1)
                       Else
                          Begin
                            initer := switch_gprolog7(GetProcedureAddress(Prologer, 'init_gprolog7'));
                            if Assigned(initer) Then
                               initer('_.info')
                            Else
                               Begin
                                 FreeLibrary(Prologer);
                                 Prologer := DWORD(-1)
                               End
                          End
                     End;
                  If Prologer <> DWORD(-1) Then
                     runer := run_gprolog7(GetProcedureAddress(Prologer, 'run_gprolog7'))
                  Else
                     runer := Nil;
                  If Assigned(runer) Then
                     begin
                       I := runer(PChar(S), PChar(ScriptFile), '_.out', 'execute', '_.info', PChar(Done), PChar(GID));
                       If I <> 5 Then
                          begin
                            {$IF DEFINED(LCL) OR DEFINED(VCL)}
                            MessageDlg('Error executing gprolog library : "' + BinStr(I,16) + '"',mtWarning,[mbOk],0);
                            {$ELSE}
                            WriteLn('Error executing gprolog library : "' + BinStr(I,16) + '"');
                            {$ENDIF}
                            Exit
                          end
                     end
                  Else
                  (* *)
                     begin
                        {$IF DEFINED(LCL) OR DEFINED(VCL)}
                        RunExtCommand(
                           {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'./run_gprolog7.sh'{$ELSE}'run_gprolog7.bat'{$ENDIF},
                           S+' ' + ScriptFile + ' _.out execute _.info ' + Done + ' ' + GID,
                           '_.info');
                        {$ELSE}
                        WriteLn(RunExtCommand(
                           {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'./run_gprolog7.sh'{$ELSE}'run_gprolog7.bat'{$ENDIF},
                           S+' ' + ScriptFile + ' _.out execute _.info ' + Done + ' ' + GID,
                           '_.info'));
                        {$ENDIF}
                        With TStringList.Create Do
                          Begin
                            LoadFromFile(S + {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'/'{$ELSE}'\'{$ENDIF} + aliveDB);
                            Insert(0, 'phoenix:-');
                            For II := 1 To Count-1 Do
                                Begin
                                  LL := Trim(Strings[II]);
                                  if Length(LL) <> 0 Then
                                     If LL[1] <> '%' Then
                                        If LL[Length(LL)] = '.' Then
                                           Begin
                                             LL[Length(LL)] := ')';
                                             LL := 'assertz(' + LL + ','
                                           End;
                                  Strings[II] := LL;
                                End;
                            Add('true,!.');
                            SaveToFile(S + {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'/'{$ELSE}'\'{$ENDIF} + phoenixDB)
                          End
                     end;
                  AssignFile(DB, DBFile);
                  Rewrite(DB);
                  WriteLn(DB,'db:-');
                  If FileExists(OutFile) Then
                     Begin
                        AssignFile(Out, OutFile);
                        Reset(Out);
                        While Not Eof(Out) Do
                          Begin
                            ReadLn(Out, S);
                            If Length(S) > 0 Then
                               If S[1] = '%' Then
                                  Continue
                               Else If S[Length(S)] = '.' Then
                                  WriteLn(DB, 'assertz(' + Copy(S, 1, Length(S) - 1) + '),')
                               Else
                                  Break
                          End;
                        CloseFile(Out)
                     End;
                  WriteLn(DB,'asserta(global_trace(' + GIDs + ')).');
                  CloseFile(DB);
                  L := TStringList.Create;
                  L.LoadFromFile('_.out');
                  With L Do
                    Begin
                      While (Count > 0) And (Strings[Count - 1] = '') Do
                        Delete(Count - 1);
                      If (Count > 0) And (Strings[Count - 1] = '#') Then
                         Begin
                           Delete(Count - 1);
                           For I := 0 To Count - 1 Do
                               Begin
                                 A.Error := False;
                                 A.AnlzLine := Strings[I];
                                 A.DelSpaces;
                                 If A.Empty Or Not A.IsNextSet(['>','<','*']) Then Break;
                                 S := A.AnlzLine[1];
                                 A.DelFirst;
                                 M := A.GetBefore(True, [Comma]);
                                 If A.Empty Or A.Error Then Break;
                                 A.DelFirst;
                                 If Not A.GetCheckNumber(True, NODE) Then
                                    Break
                                 Else
                                    For J := 0 To FRegExps.Count - 1 Do
                                        If Copy(FRegExps.Strings[J],3,1024) = M then
                                        Begin
                                           If (FRegExps.Strings[J][1] = rtContext) Then
                                              A.MakeError('Macro ''' + MacroID + ''' : regexp(' + M + ') is not modifiable')
                                           Else
                                              Begin
                                                VS := TRegExpr(FregExps.Objects[J]).FindNode(Round(NODE));
                                                If Not Assigned(VS) Then
                                                   A.MakeError('Macro ''' + MacroID + ''' : regexp(' + M + ') : there is no node(' + IntToStr(Round(NODE)) + ')')
                                                Else
                                                   Begin
                                                     A.Check(Comma);
                                                     Actions.Add(S + A.AnlzLine);
                                                     If Actions.Count > Length(Strs) Then
                                                        SetLength(Strs, Actions.Count + 20);
                                                     Strs[Actions.Count - 1].First := VS._First;
                                                     Strs[Actions.Count - 1].Last := VS._Last
                                                   End
                                              End;
                                           Break
                                        End
                               End
                         End
                      Else
                         A.MakeError('Macro ''' + MacroID + ''' has false goal result!')
                    End;
                  L.Free
               End;
            If CPOS > 0 Then Break;
          End;
       With Actions Do
         Begin
           TT := T;
           For I := 0 To Count - 1 Do
               Begin
                 ST := Strings[I];
                 D := Strs[I];
                 Case ST[1] Of
                   '<': Begin
                          System.Insert(Copy(ST, 2, 16384), TT, D.First);
                          For J := I + 1 To Count - 1 Do
                              Begin
                                If Strs[J].First >= D.First Then Inc(Strs[J].First, Length(ST) - 1);
                                If Strs[J].Last >= D.First Then Inc(Strs[J].Last, Length(ST) - 1)
                              End;
                          For J := 0 To High(Stp) Do
                              Begin
                                If Stp[J] >= D.First Then Inc(Stp[J], Length(ST) - 1);
                                If Enp[J] >= D.First Then Inc(Enp[J], Length(ST) - 1)
                              End;
                          If (CPOS > 0) And (CPOS >= D.First) Then Inc(CPOS, Length(ST) - 1);
                          Result := 2
                        End;
                   '>': Begin
                          System.Insert(Copy(ST, 2, 16384), TT, D.Last + 1);
                          For J := I + 1 To Count - 1 Do
                              Begin
                                If Strs[J].First > D.Last Then Inc(Strs[J].First, Length(ST) - 1);
                                If Strs[J].Last >= D.First Then Inc(Strs[J].Last, Length(ST) - 1)
                              End;
                          For J := 0 To High(Stp) Do
                              Begin
                                If Stp[J] > D.Last Then Inc(Stp[J], Length(ST) - 1);
                                If Enp[J] >= D.First Then Inc(Enp[J], Length(ST) - 1)
                              End;
                          If (CPOS > 0) And (CPOS >= D.Last) Then Inc(CPOS, Length(ST) - 1);
                          Result := 2
                        End;
                   '*': Begin
                          System.Delete(TT, D.First, D.Last - D.First + 1);
                          System.Insert(Copy(ST, 2, 16384), TT, D.First);
                          K := (Length(ST) - 1) - (D.Last - D.First + 1);
                          For J := I + 1 To Count - 1 Do
                              Begin
                                If Strs[J].First > D.Last Then Inc(Strs[J].First, K);
                                If Strs[J].Last >= D.Last Then Inc(Strs[J].Last, K)
                              End;
                          For J := 0 To High(Stp) Do
                              Begin
                                If Stp[J] > D.Last Then Inc(Stp[J], K);
                                If Enp[J] >= D.Last Then Inc(Enp[J], K)
                              End;
                          If (CPOS > 0) And (CPOS >= D.Last) Then Inc(CPOS, K);
                          Result := 2
                        End
                   End
               End;
           Free;
           T := TT
         End;
       A.Free
     End
End;

function ScanMacro.UnifyRegExps(var Pos: Integer; patNo: Integer; var _Stp,
  _Enp: LockArray): Boolean;

Var Stp, Enp: LockArray;

Function IsLocked(cur: TRegExpr; Var Next: Integer): Boolean;

Var Beg, Last: Integer;
    A, B, M: Integer;
Begin
   Beg := cur.MatchPos[0];
   Last := Beg + cur.MatchLen[0] - 1;
   If (Beg < 1) Or (Length(Stp) = 0) Then
      Result := False
   Else
      Begin
        A := Low(Stp);
        B := High(Stp);
        If Beg < Stp[A] Then
           If Last < Stp[A] Then
              Exit(False)
           Else
              begin
                Next := Beg + 1;
                Exit(True)
              end
        Else If Beg >= Stp[B] Then
           If Beg > Enp[B] Then
              Exit(False)
           Else
              begin
                Next := Enp[B] + 1;
                Exit(True)
              end;
        While A < B - 1 Do
           Begin
             M := (A + B) Div 2;
             If Stp[M] <= Beg Then
                A := M
             Else
                B := M
           End;
        Result := (Beg <= Enp[A]) Or (Last >= Stp[B]);
        If Result Then
           Next := Enp[A] + 1
      End
End;

Var cur: TRegExpr;
    tp, glue: Char;
    I, J, nextPos: Integer;
    maxExecs: Integer;
    ExitFlag: Boolean;
    Started: Boolean;
    L: Boolean;
Begin
  SetLength(Stp, Length(_Stp));
  SetLength(Enp, Length(_Enp));
  J := 0;
  For I := Low(_Stp) To High(_Stp) Do
      If _Stp[I] <= _Enp[I] Then
         Begin
           Enp[J] := _Enp[I];
           Stp[J] := _Stp[I];
           Inc(J)
         End;
  SetLength(Stp, J);
  SetLength(Enp, J);

  If patNo >= FRegExps.Count Then
     Result := True
  Else If patNo = FRegExps.Count - 1 Then
     Begin
       cur := TRegExpr(FRegExps.Objects[patNo]);
       maxExecs := TObjectToInteger(TObject(FRepeats[patNo]));
       tp := FRegExps.Strings[patNo][1];
       glue := FRegExps.Strings[patNo][2];
       nextPos := Pos + 1;
       if maxExecs < 0 Then maxExecs := MaxInt;
       Repeat
         If cur.Execs >= maxExecs Then
            begin
              Result := False;
              Break
            end;
         cur.StartTransaction;
         If cur.MatchLen[0] < 0 Then
            Result := cur.Exec(Pos, glue = rmGlue)
         Else
            Result := cur.ExecNext(glue = rmGlue);
         L := Result;
         Result := Result And (cur.MatchLen[0] >= 0) And Not ((tp in [rtUnique, rtGlobalUnique]) And IsLocked(cur, nextPos));
         If glue = rmGlue Then
            Result := Result And (cur.MatchPos[0] = Pos);
         If L <> Result Then
            cur.RollBack
         Else
            cur.Commit;
         If glue = rmGlue Then
            Break;
         If Not Result Then
            cur.Execs := cur.Execs - 1;
       Until Result Or (cur.MatchLen[0] < 0);
       If Not Result Then
          cur.RewindAndClear // Сбрасываем поиск
     End
  Else
     Begin
       cur := TRegExpr(FRegExps.Objects[patNo]);
       maxExecs := TObjectToInteger(TObject(FRepeats[patNo]));
       tp := FRegExps.Strings[patNo][1];
       glue := FRegExps.Strings[patNo][2];
       if maxExecs < 0 Then maxExecs := MaxInt;
       Started := False;
       If cur.MatchLen[0] < 0 Then
          if cur.Execs < maxExecs Then
             begin
               cur.StartTransaction;
               cur.Exec(Pos, glue = rmGlue);
               Started := True
             end;
       if (cur.MatchLen[0] >= 0) And
          ((glue = rmNonGlue) Or (cur.MatchPos[0] = Pos))
       Then
          Repeat
             nextPos := cur.MatchPos[0]+cur.MatchLen[0];
             L := (tp in [rtUnique,rtGlobalUnique]) And IsLocked(cur, nextPos);
             I := nextPos;
             If (Not L) And UnifyRegExps(nextPos, patNo+1, Stp, Enp) Then
                begin
                  If Started Then cur.Commit;
                  Exit(True)
                end;
             If Started Then cur.RollBack;

             If glue = rmGlue Then Break;

             Pos := I;
             For I := patNo + 1 To FRegExps.Count - 1 Do
                 TRegExpr(FregExps.Objects[I]).RewindAndClear;
             ExitFlag := (cur.Execs >= maxExecs);
             If Not ExitFlag Then
                begin
                   If cur.MatchLen[0] <> 0 Then
                      ExitFlag := Not cur.Exec(Pos, glue = rmGlue)
                   Else
                      ExitFlag := Not cur.ExecNext(glue = rmGlue);
                   ExitFlag := ExitFlag Or (cur.MatchLen[0] < 0)
                end;
             If L Then
                cur.Execs := cur.Execs - 1
          Until ExitFlag
       Else If Started Then
          cur.RollBack;
       cur.RewindAndClear; // Сбрасываем поиск
       Result := False
    End
End;

function ScanMacro.UnifyContRegExps(var Pos: Integer): Boolean;

Var I: Integer;
    subPos: Integer;
    c1, c, c2: TRegExpr;
    Flag: Boolean;
begin
  Result := True;

  I := 0;
  c1 := Nil;
  If (FregExps.Strings[I][1] in [rtContext,rtHelper]) Then
     begin
       c1 := TRegExpr(FRegExps.Objects[I]);
       If Pos = 1 Then
          subPos := 1
       Else
          subPos := Pos - 1;
       Flag := False;
       Repeat
           c1.StartTransaction;
           If c1.Exec(subPos, True) And (subPos + c1.MatchLen[0] = Pos) Then
              begin
                Flag := True;
                Break
              end;
           c1.RollBack;
           Dec(subPos)
       Until (subPos < 1) Or (subPos < Pos - 127);
       if Not Flag Then
          Exit(False);
       Inc(I);
     end;
  subPos := Pos;
  While (I < FRegExps.Count) And (FregExps.Strings[I][1] in [rtUnique,rtGlobalUnique]) Do
    begin
      c := TRegExpr(FRegExps.Objects[I]);
      c.StartTransaction;
      If c.Exec(subPos, True) And (c.MatchPos[0] = subPos) Then
         begin
           Inc(subPos, c.MatchLen[0]);
           Inc(I)
         end
      Else
         begin
           While I >= 0 Do
             begin
               TRegExpr(FRegExps.Objects[I]).RollBack;
               Dec(I)
             end;
           Exit(False)
         end
    end;
  If (I = FRegExps.Count - 1) And (FregExps.Strings[I][1] in [rtContext,rtHelper]) Then
     begin
       c2 := TRegExpr(FRegExps.Objects[I]);
       c2.StartTransaction;
       If c2.Exec(subPos, True) And (c2.MatchPos[0] = subPos) Then
          Inc(I)
       Else
          begin
            While I >= 0 Do
              begin
                TRegExpr(FRegExps.Objects[I]).RollBack;
                Dec(I)
              end;
            Exit(False)
          end
     end;
  While I > 0 Do
    begin
      Dec(I);
      TRegExpr(FRegExps.Objects[I]).Commit
    end;
  Pos := subPos
end;

(* *)
Var doner: switch_gprolog7;
    ExePath: String;
(* *)

Initialization
  ExePath:=StringReplace(ExcludeTrailingBackSlash(ExtractFilePath(ParamStr(0))),'\','/',[rfReplaceAll]);
  With TStringList.Create Do
    Begin
      Add('phoenix:-!.');
      SaveToFile(ExePath + {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'/'{$ELSE}'\'{$ENDIF} + phoenixDB);
      Free
    End;

Finalization
  (* *)
  If (Prologer <> 0) And (Prologer <> DWORD(-1)) Then
     begin
       doner := switch_gprolog7(GetProcedureAddress(Prologer, 'done_gprolog7'));
       if Assigned(doner) Then
          doner('_.info');
       FreeLibrary(Prologer)
     end
  (* *)
end.

