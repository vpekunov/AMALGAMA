unit XPathing;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, MetaComp, xpath;

Var Interval: Cardinal;

function XPathInduct(Const SelectedMode, CurLanguageName: String; UseNNet: Boolean; MainLineAllowed: Boolean; ENV: TXPathEnvironment; Const InXML, OutXML: String; MaxCPUs: Integer; Const IDs: IDArray): Boolean;

implementation

Uses {$IF DEFINED(UNIX) OR DEFINED(LINUX)}cthreads{$ELSE}Windows{$ENDIF}, Elements, Math, dom, xmlread, xmlwrite, Lexique, RegExpr, Common, AutoUtils, AutoConsts,
     DateUtils, uSemaphore
     {$IF DEFINED(VCL) OR DEFINED(LCL)}, Forms{$ENDIF};

{$OPTIMIZATION OFF}

Const NumThreads: Integer = 8;

Var NumThrSemaphore: TSemaphore = Nil;

Var VariantsCS: TRTLCriticalSection;

Var Start: TDateTime;

Type VectorType = Array Of Real;
     MatrixType = Array Of VectorType;
     PMatrixType = ^MatrixType;

Type TTrace = Array Of Integer;
     PTrace = ^TTrace;

Type

{ TStat }

 TStat = class
        lSeq: TList;
        lWords: TStringList;
        lRels: TStringList;
        INP: TStringList;
        R: Real;
        OUT0, OUT1: MatrixType;
        Trace: TTrace;
        Time: Real;

        Constructor Create(lS, lW, lR: TStringList; Const P0, P1: MatrixType; T: Real; lT: TTrace);
        Destructor Destroy;
     End;

Var Probabilities: MatrixType;
    Variants: TStringList;
    Words: TStringList;
    Stat: TObjList;

Var MetaResult: TSystem = Nil;
    MetaTrace: TTrace;

{ TStat }

constructor TStat.Create(lS, lW, lR: TStringList; const P0, P1: MatrixType; T: Real; lT: TTrace);

Var F, G: Integer;
begin
  lSeq := TList.Create;
  For F := 0 To lS.Count - 1 Do
      lSeq.Add(IntegerToTObject(StrToInt(lS[F])));
  lWords := TStringList.Create;
  lWords.Assign(lW);
  lRels := TStringList.Create;
  lRels.Assign(lR);
  INP := TStringList.Create;
  R := 0.0;
  SetLength(OUT0, _Restrictions.Count, _Restrictions.Count);
  For F := 0 To _Restrictions.Count - 1 Do
      For G := 0 To _Restrictions.Count - 1 Do
          OUT0[F, G] := P0[F, G];
  SetLength(OUT1, _Restrictions.Count, _Restrictions.Count);
  For F := 0 To _Restrictions.Count - 1 Do
      For G := 0 To _Restrictions.Count - 1 Do
          OUT1[F, G] := P1[F, G];
  SetLength(Trace, Length(lT));
  For F := Low(lT) To High(lT) Do
      Trace[F] := lT[F];
  Time := T
end;

destructor TStat.Destroy;

Var F: Integer;
begin
   For F := 0 To INP.Count-1 Do
       If Assigned(INP.Objects[F]) Then
          Dispose(PMatrixType(INP.Objects[F]));
   INP.Free;
   lSeq.Free;
   lWords.Free;
   lRels.Free
end;

function ExtractSystemFromDOM(dom: TXMLDocument; Var res: TXPathVariable; ENV: TXPathEnvironment): TSystem;

  function CreateLinks(sys: TSystem; obj: TDOMElement; Cont: TDOMElement; Const PartnerTag: String): Boolean;

  Var F, G: Integer;
      ID, ContID: DOMString;
      El, PEl: TElement;
      PID, PContID: DOMString;
      res: TXPathVariable;
      L: TLink;
      Ref: DOMString;
      Info: Boolean;
      S: String;
  Begin
     Result := False;
     ID := obj.AttribStrings['ID'];
     ContID := Cont.AttribStrings['ID'];
     El := sys.GetElement(ID);
     With Cont.ChildNodes Do
       begin
         For F := 0 To Length - 1 Do
             If TDOMElement(Item[F]).TagName = 'Link' Then
                Begin
                  Ref := TDOMElement(Item[F]).AttribStrings['Code'];
                  S := TDOMElement(Item[F]).AttribStrings['Informational'];
                  Info := (CompareText(S, 'true') = 0) Or (CompareText(S, '1') = 0);
                  res := EvaluateXPathExpression('/OBJS/*/' + PartnerTag + '[@Ref=' + Ref + ']', dom.DocumentElement, Nil, [], Nil, Nil, ENV);
                  ENV.commitUndo(0);
                  If res Is TXPathNodeSetVariable Then
                     With res.AsNodeSet Do
                       If Count > 0 then
                          Begin
                            PID := TDOMElement(TDOMElement(Items[0]).ParentNode).AttribStrings['ID'];
                            PContID := TDOMElement(Items[0]).AttribStrings['ID'];
                            PEl := sys.GetElement(PID);
                            If PartnerTag = 'I' Then
                               L := sys.AddLink(El.OutputContact[ContID], PEl.InputContact[PContID], S, Info)
                            Else
                               L := sys.AddLink(PEl.OutputContact[PContID], El.InputContact[ContID], S, Info);
                            If Not Info Then
                               Begin
                                 sys.AnalyzeLinkStatus(L);
                                 If L.Inform Then
                                    FreeAndNil(L)
                               End;
                            If Not Assigned(L) Then
                               Begin
                                 res.Free;
                                 Exit(False)
                               End
                          End;
                  res.Free
                end;
         Free
       end;
     Result := True
  End;

Var objs: TNodeSet;
    obj: TDOMElement;
    el: TElement;
    ID: String;
    C: TNodeSet;
    F, G: Integer;
    X: Integer;
Begin
   Result := Nil;
   res := EvaluateXPathExpression('/OBJS/*', dom.DocumentElement, Nil, [], Nil, Nil, ENV);
   ENV.commitUndo(0);
   If res is TXPathNodeSetVariable Then
      Begin
        Result := TSystem.Create;
        objs := res.AsNodeSet;
        X := 50;
        For F := 0 To objs.Count - 1 Do
            If TObject(objs[F]) is TDOMElement then
               Begin
                 obj := TObject(objs[F]) as TDOMElement;
                 If ExistClass(obj.TagName) Then
                    Begin
                      ID := obj.AttribStrings['ID'];
                      If (Length(ID) = 0) Or Assigned(Result.FindElement(ID)) Then
                         Begin
                           Result.Free;
                           Exit(Nil)
                         End;
                      el := Result.AddElement(obj.TagName, ID, flShowClass + flShowName);
                      For G := 0 To obj.Attributes.Length - 1 Do
                          If el.Parameters.IndexOfName(obj.Attributes[G].NodeName) >= 0 Then
                             el.Parameters.Values[obj.Attributes[G].NodeName] := obj.Attributes[G].NodeValue;
                      el.Move(X, 50);
                      Inc(X, 120)
                    End;
               End;
        For F := 0 To objs.Count - 1 Do
            If TObject(objs[F]) is TDOMElement then
               Begin
                 obj := TObject(objs[F]) as TDOMElement;
                 With obj.ChildNodes Do
                   begin
                     For G := 0 To Length - 1 Do
                      If TDOMElement(Item[G]).TagName = 'I' Then
                        Begin
                          If Not CreateLinks(Result, obj, TDOMElement(Item[G]), 'O') Then
                             Begin
                               Result.Free;
                               Free;
                               Exit(Nil)
                             end
                        End
                      Else If TDOMElement(Item[G]).TagName = 'O' Then
                        Begin
                          If Not CreateLinks(Result, obj, TDOMElement(Item[G]), 'I') Then
                             Begin
                               Result.Free;
                               Free;
                               Exit(Nil)
                             end
                        End;
                     Free
                   End
               End
      End
end;

Type

{ TDeducer }

 TDeducer = class(TThread)
        Result: TSystem;
        CurLanguageName: String;
        dom: TXMLDocument;
        semaphored: Boolean;
        in_stage: Integer;
        in_tr: TTrace;
        parent: Integer;
        trace: TTrace;
        out_tr: TTrace;
        ENV: TXPathEnvironment;

        constructor Create(Const Lang: String; _ENV: TXPathEnvironment; _dom: TXMLDocument; _semaphored: Boolean; _parent: Integer; Const tr: TTrace; _in_stage: Integer; Const _in_tr: TTrace);
        destructor Destroy; override;
        procedure Execute; override;

        procedure Process;
     End;

function Deduce(Const CurLanguageName: String;
  ENV: TXPathEnvironment; var dom: TXMLDocument; semaphored: Boolean; T: TDeducer;
  parent: Integer; Var tr: TTrace; Var outtr: TTrace;
  _in_stage: Integer; Const _in_tr: TTrace): TSystem;

Var res: TXPathVariable;
    CRes: TResultType;
    hash: String;
    vars: TWeakResult;
    nums: Array Of Integer;
    threads: Array Of TDeducer;
    started: Array Of Boolean;
    vv: TWeakResult;
    ttrs: TTrace;
    rres: Array Of TResultType;
    P, TotalP, q: Real;
    NonStricts: Array Of Integer;
    rnds: Array Of Real;
    pp, pp1: Real;
    ones: Integer;
    AllOk: Boolean;
    Prog, Gen: String;
    TaskFile: TextFile;
    StartLanguage: String;
    Compiled: Boolean;
    S: String;
    F, G, K: Integer;
Begin
   if semaphored then
      NumThrSemaphore.Wait;

   SetLength(tr, Length(tr) + 1);
   tr[High(tr)] := parent;

   Try
     Result := ExtractSystemFromDOM(dom, res, ENV);
     res.Free;

     If Assigned(T) Then T.Synchronize(T.Process);
     If Assigned(Result) Then
        Begin
          CRes := Result.Check;

          If CRes = rsStrict Then
             Begin
               FreeAndNil(Result);
               Exit
             End;

          hash := Result.ToString;

          EnterCriticalSection(VariantsCS);
          If Variants.IndexOf(hash) >= 0 Then
             Begin
               LeaveCriticalSection(VariantsCS);
               FreeAndNil(Result);
               Exit
             End;
          Variants.Add(hash);
          SetLength(rnds, _Restrictions.Count);
          For F := Low(rnds) To High(rnds) Do
              rnds[F] := Random; // In critical section!
          LeaveCriticalSection(VariantsCS);

          If CRes = rsOk Then
             Begin
               Prog:='';
               If Assigned(T) Then T.Synchronize(T.Process);
               EnterCriticalSection(VariantsCS);
               If Result.GeneratePHP(Prog) Then
                  begin
                    Result.SaveToXML(CurLanguageName,'_.xml');
                    CreateStrFile('_.php3',Prog);
                    {$IF DEFINED(LCL) OR DEFINED(VCL)}
                    Gen := RunExtCommand(
                       {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'run_php.sh'{$ELSE}'run_php.bat'{$ENDIF},
                       '_.php3 _.gen','_.gen',CRLF+CRLF);
                    {$ELSE}
                    Gen := RunExtCommand(
                       {$IF DEFINED(UNIX) OR DEFINED(LINUX)}'run_php.sh'{$ELSE}'run_php.bat'{$ENDIF},
                       '_.php3 _.gen','_.gen',CRLF+CRLF);
                    {$ENDIF}
                    CreateStrFile('_.gen',Gen);
                    If Pos(errPHP,Gen) <> 0 Then
                       Begin
                         FreeAndNil(Result);
                         LeaveCriticalSection(VariantsCS);
                         If Assigned(T) Then T.Synchronize(T.Process);
                         Exit
                       End;
                    // Here must be a possible Snobol retranslation
                    S:=ExcludeTrailingBackSlash(ExtractFilePath(
                    {$IF DEFINED(VCL) OR DEFINED(LCL)}
                    Application.ExeName
                    {$ELSE}
                    ParamStr(0)
                    {$ENDIF}
                    ));
                    StartLanguage := '';
                    If FileExists(S+SuperSlash+'_.start') Then
                       begin
                         AssignFile(TaskFile,S+SuperSlash+'_.start');
                         Reset(TaskFile);
                         ReadLn(TaskFile,StartLanguage);
                         CloseFile(TaskFile);
                         DeleteFile(PChar(S+SuperSlash+'_.start'));
                       end
                    Else
                       Begin
                         FreeAndNil(Result);
                         LeaveCriticalSection(VariantsCS);
                         If Assigned(T) Then T.Synchronize(T.Process);
                         Exit
                       End;
                    DeleteFile(PChar(S+SuperSlash+'_.exe'));
                    Compiled := False;
                    For F := 0 To _Restrictions.Count - 1 Do
                        If TObject(_Restrictions[F]) is TWeakTest Then
                           If Not TWeakTest(_Restrictions[F]).Test(ENV, dom, Result, Compiled, StartLanguage) Then
                              Begin
                                FreeAndNil(Result);
                                LeaveCriticalSection(VariantsCS);
                                If Assigned(T) Then T.Synchronize(T.Process);
                                Exit
                              End;
                    If Assigned(MetaResult) Then
                       FreeAndNil(Result);
                    LeaveCriticalSection(VariantsCS);
                    If Assigned(T) Then T.Synchronize(T.Process);
                    SetLength(outtr, Length(tr));
                    If Length(tr) > 0 Then
                       Move(tr[0], outtr[0], Length(tr)*SizeOf(Integer));
                    Exit
                  end
               Else
                  Begin
                    FreeAndNil(Result);
                    LeaveCriticalSection(VariantsCS);
                    Exit
                  End
             End
          Else
             Begin
               if (Length(_in_tr) > 0) And (_in_stage >= Length(_in_tr)) Then
                  begin
                    FreeAndNil(Result);
                    Exit
                  end;

               SetLength(vars, 0);
               SetLength(rres, _Restrictions.Count);
               AllOk := True;
               EnterCriticalSection(VariantsCS);
               If Assigned(MetaResult) Then
                  begin
                    LeaveCriticalSection(VariantsCS);
                    FreeAndNil(Result);
                    Exit
                  end;
               LeaveCriticalSection(VariantsCS);

               If Assigned(T) Then T.Synchronize(T.Process);
               TotalP := 0.0;
               ones := 0;
               SetLength(NonStricts, 0);
               For F := 0 To _Restrictions.Count - 1 Do
                   If (Length(_in_tr) = 0) Or (_in_tr[_in_stage] = F) Then
                      begin
                        rres[F] := TWeakRestriction(_Restrictions[F]).Check(ENV, dom, Result);
                        If rres[F] = rsStrict Then
                           Begin
                             FreeAndNil(Result);
                             Exit
                           End
                        Else If rres[F] = rsNonStrict Then
                           Begin
                             pp := TWeakRestriction(_Restrictions[F]).AprP;
                             if parent >= 0 Then
                                pp := pp * Probabilities[parent][F];
                             TotalP := TotalP + pp;
                             If ones = 0 Then
                                Inc(ones)
                             Else
                                If Abs(pp - pp1) < 1E-7 Then
                                   Inc(ones);
                             SetLength(NonStricts, Length(NonStricts) + 1);
                             NonStricts[High(NonStricts)] := F;
                             pp1 := pp;
                             AllOk := False
                           End
                      end
                   Else
                      rres[F] := rsOk;
               FreeAndNil(Result);
               If AllOk Then // No non-strict weak violations but the strong violations present
                  Exit;
               If Assigned(T) Then T.Synchronize(T.Process);
               EnterCriticalSection(VariantsCS);
               If Assigned(MetaResult) Then
                  begin
                    LeaveCriticalSection(VariantsCS);
                    Exit
                  end;
               LeaveCriticalSection(VariantsCS);
               If ones <> Length(NonStricts) Then
                  For F := Low(NonStricts) To High(NonStricts) Do
                      Begin
                        G := F;
                        P := 0.0;
                        If G < High(NonStricts) Then
                           Begin
                             if parent >= 0 Then
                                q := Probabilities[parent][NonStricts[G]]
                             Else
                                q := 1.0;
                             q := q * TWeakRestriction(_Restrictions[NonStricts[G]]).AprP/TotalP
                           End;
                        While (G < High(NonStricts)) And (P + q < rnds[F]) Do
                          Begin
                            P := P + q;
                            Inc(G);
                            If G < High(NonStricts) Then
                               Begin
                                 if parent >= 0 Then
                                    q := Probabilities[parent][NonStricts[G]]
                                 Else
                                    q := 1.0;
                                 q := q * TWeakRestriction(_Restrictions[NonStricts[G]]).AprP/TotalP
                               End;
                          End;
                        If G <> F Then
                           Begin
                             K := NonStricts[F];
                             NonStricts[F] := NonStricts[G];
                             NonStricts[G] := K
                           End;
                        pp := TWeakRestriction(_Restrictions[NonStricts[F]]).AprP;
                        if parent >= 0 Then
                           pp := pp * Probabilities[parent][NonStricts[F]];
                        TotalP := TotalP - pp;
                        If TotalP < 0.0 Then
                           TotalP := 0.0
                      End;
               SetLength(nums, 0);
               For K := Low(NonStricts) To High(NonStricts) Do
                   Begin
                     F := NonStricts[K];
                     vv := TWeakRestriction(_Restrictions[F]).Construct(ENV, dom);
                     If Assigned(vv) And (Length(vv) > 0) Then
                        Begin
                          SetLength(vars, Length(vars) + Length(vv));
                          SetLength(nums, Length(nums) + Length(vv));
                          For G := Low(vv) To High(vv) Do
                              Begin
                                vars[High(vars) - High(vv) + G] := vv[G];
                                nums[High(nums) - High(vv) + G] := F;
                              End
                        End
                   End;
                If Assigned(T) Then T.Synchronize(T.Process);
                EnterCriticalSection(VariantsCS);
                If Assigned(MetaResult) Then
                   begin
                     LeaveCriticalSection(VariantsCS);
                     Exit
                   end;
                LeaveCriticalSection(VariantsCS);
                SetLength(threads, Length(vars));
                SetLength(started, Length(vars));
                If Length(vars) > 0 Then
                   FillChar(started[0], Length(vars)*SizeOf(Boolean), 0);
                For F := Low(vars) To High(vars) Do
                    Begin
                      started[F] := NumThrSemaphore.AttemptWait;
                      if started[F] Then
                         begin
                           threads[F] := TDeducer.Create(CurLanguageName, ENV, vars[F], true, nums[F], tr, _in_stage+1, _in_tr);
                           threads[F].Resume;
                           NumThrSemaphore.Post;
                         end
                      else
                         begin
                           SetLength(ttrs, Length(tr));
                           If Length(ttrs) > 0 Then
                              Move(tr[0], ttrs[0], Length(tr)*SizeOf(Integer));
                           Result := Deduce(CurLanguageName, ENV, vars[F], false, T, nums[F], ttrs, outtr, _in_stage+1, _in_tr);
                           FreeAndNil(vars[F]);

                           If Assigned(T) Then T.Synchronize(T.Process);
                           EnterCriticalSection(VariantsCS);
                           If Assigned(MetaResult) Or Assigned(Result) Then
                              Begin
                                If Assigned(Result) Then
                                   If Not Assigned(MetaResult) Then
                                      Begin
                                        SetLength(MetaTrace, Length(outtr));
                                        If Length(outtr) > 0 Then
                                           Move(outtr[0], MetaTrace[0], Length(outtr)*SizeOf(Integer));
                                        MetaResult := Result
                                      End
                                   Else
                                      If Result <> MetaResult Then
                                         FreeAndNil(Result);
                                LeaveCriticalSection(VariantsCS);
                                Break
                              End;
                           LeaveCriticalSection(VariantsCS);
                         end
                    End;
                For F := Low(vars) To High(vars) Do
                  If started[F] then
                    Begin
                      threads[F].WaitFor;
                      Result := threads[F].Result;
                      vars[F] := threads[F].dom;
                      FreeAndNil(vars[F]);
                      If Assigned(Result) Then
                         Begin
                           EnterCriticalSection(VariantsCS);
                           If Not Assigned(MetaResult) Then
                              Begin
                                SetLength(MetaTrace, Length(threads[F].out_tr));
                                If Length(threads[F].out_tr) > 0 Then
                                   Move(threads[F].out_tr[0], MetaTrace[0], Length(threads[F].out_tr)*SizeOf(Integer));
                                MetaResult := Result
                              End
                           Else
                              If Result <> MetaResult Then
                                 FreeAndNil(Result);
                           LeaveCriticalSection(VariantsCS);
                           If Assigned(T) Then T.Synchronize(T.Process);
                         End;
                      FreeAndNil(threads[F]);
                    End
                  Else If Assigned(vars[F]) Then
                    FreeAndNil(vars[F])
             End
        End
   Finally
     if semaphored then
        NumThrSemaphore.Post;
   End
End;

{ Deducer }

constructor TDeducer.Create(Const Lang: String; _ENV: TXPathEnvironment; _dom: TXMLDocument;
  _semaphored: Boolean; _parent: Integer; const tr: TTrace;
  _in_stage: Integer; Const _in_tr: TTrace);
begin
   Inherited Create(True);
   dom := _dom;

   CurLanguageName := Lang;

   semaphored := _semaphored;
   SetLength(trace, Length(tr));
   If Length(tr) > 0 Then
      Move(tr[0], trace[0], Length(tr)*SizeOf(Integer));
   in_stage := _in_stage;
   SetLength(in_tr, Length(_in_tr));
   If Length(_in_tr) > 0 Then
      Move(_in_tr[0], in_tr[0], Length(_in_tr)*SizeOf(Integer));
   parent := _parent;
   SetLength(out_tr, 0);
   ENV := _ENV.Clone
end;

destructor TDeducer.Destroy;
begin
   ENV.Free;
   inherited Destroy;
end;

procedure TDeducer.Execute;
begin
  Result := Deduce(CurLanguageName, ENV, dom, semaphored, Self, parent, trace, out_tr, in_stage, in_tr)
end;

procedure TDeducer.Process;
begin
  If Interval > 0 Then
     begin
       If MilliSecondsBetween(XPathing.Start, Now) >= Interval Then
          begin
            EnterCriticalSection(VariantsCS);
            If Not Assigned(MetaResult) Then
               MetaResult := TSystem($0FFFFFFFF);
            LeaveCriticalSection(VariantsCS);
            XPathing.Start := Now
          end
     end
end;

function XPathInduct(Const SelectedMode, CurLanguageName: String; UseNNet: Boolean; MainLineAllowed: Boolean; ENV: TXPathEnvironment;
                     const InXML, OutXML: String; MaxCPUs: Integer; Const IDs: IDArray): Boolean;

Const MaxBaumWelch = 5;

// Y[T+1], A[N*N], B[L*N], _pi[N], delta[T*L]
procedure BaumWelch(L, T, N: Integer; Const Y: TTrace; Var A, B: MatrixType; Var _pi: VectorType; Const delta: MatrixType);

Const maxIters = 200;
      eps = 1E-2;

Var alpha, betta, gamma: MatrixType;
    epsilon: Array Of MatrixType;
    sum, old, disb: Real;
    i, j, k, tt: Integer;
    iters: Integer;
begin
   SetLength(alpha, N, T);
   SetLength(betta, N, T);
   SetLength(gamma, N, T);
   SetLength(epsilon, N, N, T);
   iters := 0;
   Repeat
      For i := 0 To N-1 Do
        alpha[i][0] := _pi[i]*B[Y[1]][i];
      For tt := 1 To T-1 Do
        For j := 0 To N-1 Do
          begin
            alpha[j][tt] := 0.0;
            For i := 0 To N-1 Do
              alpha[j][tt] := alpha[j][tt] + alpha[i][tt-1]*A[i][j];
            alpha[j][tt] := alpha[j][tt]*B[Y[tt+1]][j]
          end;
      For i := 0 To N-1 Do
        betta[i][T-1] := 1.0;
      For tt := T-2 DownTo 0 Do
        For i := 0 To N-1 Do
          begin
            betta[i][tt] := 0.0;
            For j := 0 To N-1 Do
              betta[i][tt] := betta[i][tt] + betta[j][tt+1]*A[i][j]*B[Y[tt+2]][j]
          end;
      For tt := 0 To T-1 Do
        begin
          sum := 0.0;
          For i := 0 To N-1 Do
            begin
              gamma[i][tt] := alpha[i][tt]*betta[i][tt];
              sum := sum + gamma[i][tt]
            end;
          If sum <> 0.0 Then
             For i := 0 To N-1 Do
                 gamma[i][tt] := gamma[i][tt]/sum;
        end;
      For tt := 0 To T-2 Do
        begin
          sum := 0.0;
          For i := 0 To N-1 Do
            For j := 0 To N-1 Do
              begin
                epsilon[i][j][tt] := alpha[i][tt]*A[i][j]*betta[j][tt+1]*B[Y[tt+2]][j];
                sum := sum + epsilon[i][j][tt]
              end;
          If sum <> 0.0 Then
             For i := 0 To N-1 Do
               For j := 0 To N-1 Do
                 epsilon[i][j][tt] := epsilon[i][j][tt]/sum;
        end;
      For i := 0 To N-1 Do
        _pi[i] := gamma[i][0];
      disb := 0.0;
      For i := 0 To N-1 Do
        begin
          sum := 0.0;
          For tt := 0 To T-2 Do
            sum := sum + gamma[i][tt];
          For j := 0 To N-1 Do
            begin
              old := A[i][j];
              A[i][j] := 0.0;
              For tt := 0 To T-2 Do
                A[i][j] := A[i][j] + epsilon[i][j][tt];
              If Abs(sum) > 0.001*eps Then A[i][j] := A[i][j] / sum;
              disb := disb + Abs(A[i][j] - old)
            end;
          sum := sum + gamma[i][T-1];
          For k := 0 To L-1 Do
            begin
              old := B[k][i];
              B[k][i] := 0.0;
              For tt := 0 To T-1 Do
                B[k][i] := B[k][i] + delta[tt][k]*gamma[i][tt];
              If Abs(sum) > 0.001*eps Then B[k][i] := B[k][i] / sum;
              disb := disb + Abs(B[k][i] - old)
            end
        end;
      Inc(iters);
      If iters = maxIters Then
         Raise Exception.Create('Too many iterations')
   until disb < eps;
end;

function ReadStr(Var Log: TextFile): String;

Var F: Integer;
    C: Char;
begin
   Read(Log, F); // Читаем количество символов
   Result := '';
   While F > 0 Do
     begin
       Read(Log, C);
       If Not (C in [' ', #9, #$0D, #$0A]) Then
          begin
            AppendStr(Result, C);
            Dec(F)
          end
     end
end;

procedure AddWords(locWords: TStringList);

Var S: String;
    Found: Boolean;
    F, G: Integer;
begin
   With locWords Do
     For F := 0 To Count - 1 Do
       begin
         S := locWords[F];
         Found := False;
         For G := 0 To Words.Count - 1 Do
           If Levenshtein(S, Words[G]) <= 2 Then
              begin
                Found := True;
                Break
              end;
         If Not Found Then
            Words.Add(S)
       end
end;

procedure AddRels(LL: TAnalyser; RelsMap: TStringList; lRels: TStringList);

Var S: String;
    G, K: Integer;
begin
   For G := 0 To lRels.Count -1 Do
     begin
       LL.AnlzLine := lRels[G];
       S := LL.GetIdent(False);
       If Not RelsMap.Find(S, K) Then
          RelsMap.Add(S)
     end;
end;

procedure NormalizeProbabilities(MIN: Real; Const N: Integer; Var P: MatrixType);

Var max: Real;
    F, G: Integer;
begin
   max := 0.0;
   For F := 0 To N - 1 Do
       For G := 0 To N - 1 Do
           If P[F][G] > max Then
              max := P[F][G];
   If max > 0.0 Then
      For F := 0 To N - 1 Do
          For G := 0 To N - 1 Do
              P[F][G] := MIN + (1.0 - MIN) * P[F][G] / max;
end;

function LevenshteinWords(const s1, s2: TStringList): Integer;

Var diff: integer;
    m: Array Of Array Of Integer;
    i, j: Integer;
Begin
 SetLength(m, s1.Count + 1, s2.Count + 1);

 for i := 0 To s1.Count do
     m[i][0] := i;
 for j := 0 To s2.Count do
     m[0][j] := j;

 for i := 1 to s1.Count do
   begin
     for j := 1 to s2.Count do
       begin
         if Levenshtein(s1[i-1],s2[j-1]) <= 2 then diff := 0 else diff := 1;

         m[i][j] := Min(Min(m[i - 1, j] + 1,
                                  m[i, j - 1] + 1),
                                  m[i - 1, j - 1] + diff);
       end
   end;
   Result := m[s1.Count][s2.Count]
end;

procedure SetProbabilities(LL: TAnalyser; INP: TStringList; lSeq: TList; lWords, lRels, templateWords: TStringList; TT: Real);

Var S: String;
    PP: PMatrixType;
    KP, KS, KT: Integer;
    G, K, M, P: Integer;
begin
   KP := INP.IndexOf('PRESENT');
   KS := INP.IndexOf('SEQ');
   KT := INP.IndexOf('TIME');
   For G := 0 To INP.Count -1 Do
     begin
       New(PP);
       If G = KP Then
          SetLength(PP^, 1, Words.Count)
       Else If G = KS Then
          SetLength(PP^, 1, 1)
       Else If G = KT Then
          SetLength(PP^, 1, 1)
       Else
          SetLength(PP^, Words.Count, Words.Count);
       For K := 0 To Length(PP^) - 1 Do
         For P := 0 To Length(PP^[K]) - 1 Do
           PP^[K][P] := 0.0;
       INP.Objects[G] := TObject(PP)
     end;
   PP := PMatrixType(INP.Objects[KP]);
   For G := 0 To lWords.Count - 1 Do
     begin
       S := lWords.Strings[G];
       For P := 0 To Words.Count - 1 Do
         If Levenshtein(S, Words[P]) <= 2 Then
            begin
              PP^[0][P] := PP^[0][P] + 0.1;
              Break
            end
     end;
   PP := PMatrixType(INP.Objects[KS]);
   P := LevenshteinWords(lWords, templateWords);
   PP^[0][0] := 1.0*P/(2*Words.Count);
   PP := PMatrixType(INP.Objects[KT]);
   PP^[0][0] := TT/600.0;
   For G := 0 To lRels.Count - 1 Do
     begin
       LL.AnlzLine := lRels.Strings[G];
       S := LL.GetIdent(False);
       K := INP.IndexOf(S);
       If K < 0 Then
          MakeErrorCommon('Unknown relation "'+S+'"')
       Else
          begin
            LL.Check(LeftBracket);
            If Not LL.Error Then
               begin
                 S := LL.GetBefore(True, [Colon]);
                 LL.Check(Colon);
                 For P := 0 To Words.Count - 1 Do
                   If Levenshtein(S, Words[P]) <= 2 Then
                      begin
                        S := LL.GetBefore(True, [RightBracket]);
                        LL.Check(RightBracket);
                        If Not LL.Error Then
                           begin
                             For M := 0 To Words.Count - 1 Do
                               If Levenshtein(S, Words[M]) <= 2 Then
                                  begin
                                    PP := PMatrixType(INP.Objects[K]);
                                    PP^[P][M] := PP^[P][M] + 0.1;
                                    Break
                                  end
                           end;
                        Break
                      end
               end
          end
     end
end;

function CalcDist(P1, P2: TStringList; Const IgnoreTime: Boolean = False): Real;

Var F, G, H: Integer;
    D: Real;
begin
   Result := 0.0;
   For F := 0 To P1.Count - 1 Do
     If (Not IgnoreTime) Or (P1.Strings[F] <> 'TIME') Then
      For G := 0 To Length(PMatrixType(P1.Objects[F])^) - 1 Do
         For H := 0 To Length(PMatrixType(P1.Objects[F])^[G]) - 1 Do
           begin
             D := PMatrixType(P1.Objects[F])^[G][H] - PMatrixType(P2.Objects[F])^[G][H];
             Result := Result + D*D
           end;
   // Result := Sqrt(Result)
end;

var
  parser: TDOMParser;
  L: TStringList;
  src: TXMLInputSource;
  deducer: TDeducer;
  dom, init_dom: TXMLDocument;
  tr: TTrace;
  Log: TextFile;
  prev, this: Integer;
  Time: TDateTime;
  S: String;
  lProbabilities0, lProbabilities1: MatrixType;
  lTrace: TTrace;
  MainLine: TTrace;
  Mode: String;
  C: Char;
  TT: Real;
  LL: TAnalyser;
  RelsMap: TStringList;
  Found: Boolean;
  locSeq, locWords, locRels, locP: TStringList;
  RulerClasses: TStringList;
  Seq: TList;
  Dists: Array Of Real;
  W, W1, WT: Real;
  Buf: Real;
  F, G, K, M, P, H: Integer;
  _pi: VectorType;
  res: TXPathVariable;
  (* C: TNodeSet; *)
begin
   Result := False;

   For F := 0 To Ruler.Count - 1 Do
     DisposeStr(PString(Ruler.Objects[F]));
   Ruler.Clear;

   FreeAndNil(Words);

   parser := TDOMParser.Create;
   L := TStringList.Create;
   try
     parser.Options.PreserveWhitespace := True;
     parser.Options.Namespaces := True;
     L.LoadFromFile(InXML);
     L.Insert(0, '<OBJS>');
     L.Add('</OBJS>');
     src := TXMLInputSource.Create(L.Text); // '<a><b><list data="1"><list data="2"></list></list></b><c><list data="3"><list data="4"></list></list></c></a>'
     try
       parser.Parse(src, dom);
(*       C := TNodeSet.Create; *)
(**)
//       ENV.AddFunction('loop', Nil, true, ['$I','$max','$body'], '($I <= $max and set($I, $I+1) and eval($body) and loop($I,$max,$body)) or true()');
//       ENV.AddFunction('depth', Nil, true, ['&$OUT1'], 'set($OUT1,0) and (self::*[set($OUT1,1) and *[depth($OUT0) and set($OUT1,max($OUT0+1,$OUT1))]] or true())');
//       res := EvaluateXPathExpression('loop(0,3,"true()") and depth($A)', dom.DocumentElement, Nil, [Nil,Nil,dom.DocumentElement], Nil, Nil, ENV);
//       ENV.AddFunction('make_loop', Nil, true, [], 'self::*[@counter <= @max and create(loop[@counter = ###/@counter+1 and @max = ###/@max]) and loop[make_loop()] or true()] or true()');
//       res := EvaluateXPathExpression('create(loop[@counter = 0 and @max = 3]) and loop[make_loop()] and delete(loop)', dom.DocumentElement, Nil, [Nil,Nil,dom.DocumentElement], Nil, Nil, ENV);
//       res := EvaluateXPathExpression('transaction(create(/OBJS/saccura) and delete(/OBJS/*) and false())', dom.DocumentElement, Nil, [Nil,Nil,dom.DocumentElement], Nil, Nil, ENV);
//       res := EvaluateXPathExpression('transaction(create(/OBJS/clsSimpleTerminator[@ID="END" and I[@ID="End"]]))', dom.DocumentElement, Nil, [Nil,Nil,dom.DocumentElement], Nil, Nil, ENV);
//         ENV.AddFunction('depth_list', Nil, true, ['$#','&$OUT1'], 'set($OUT1,0) and (#/list[set($OUT1,1) and depth_list(#/list,$OUT0) and set($OUT1,max($OUT0+1,$OUT1))]) or true()');
//         ENV.AddFunction('concat_list', Nil, true, ['$#', '$##'], 'add_list(#/self::*) and add_list(##/self::*)');
//         ENV.AddFunction('add_list', Nil, true, ['$#'], 'count(list) = 0 and copy_list(#/self::*) or list[add_list(#/self::*)] or true()');
//         ENV.AddFunction('copy_list', Nil, true, ['$#'], 'count(#/list) = 0 or create(list[@data = #/list/@data]) and (list[copy_list(#/list)] or true())');
//         res := EvaluateXPathExpression('transaction(concat_list(/a/b,/a/c) and depth_list(/a,$A) or true())', dom.DocumentElement, Nil, [Nil,Nil,dom.DocumentElement], Nil, Nil, ENV);
//         F := Round(ENV.VariablesByName['A'].AsNumber);
(**)
//       res := EvaluateXPathExpression('/doc/av/v/x/p[(@ID = 1 or @ID = 2) and @ID < 2]/node/@ID', dom.DocumentElement, [dom.DocumentElement,dom.DocumentElement], C);
       res := EvaluateXPathExpression('/OBJS/*[@ID != ""]', dom.DocumentElement, Nil, [], Nil, Nil, ENV);
       ENV.commitUndo(0);
       Seq := TList.Create;
       RulerClasses := TStringList.Create;
       If res is TXPathNodeSetVariable Then
          For F := 0 To res.AsNodeSet.Count - 1 Do
            Begin
              S := TDOMElement(res.AsNodeSet[F]).AttribStrings['GID'];
              If Length(S) > 0 Then
                 Begin
                   G := StrToInt(S);
                   If G >= 0 Then
                      Begin
                        For K := Low(IDs) To High(IDs) Do
                            If IDs[K] = S Then
                               Begin
                                 G := K;
                                 Break
                               End;
                        Ruler.AddObject(TDOMElement(res.AsNodeSet[F]).AttribStrings['ID'], IntegerToTObject(G));
                        RulerClasses.Add(TDOMElement(res.AsNodeSet[F]).TagName);
                        Seq.Add(TStringList.Create);
                        With TStringList(Seq[Seq.Count - 1]) Do
                          For G := StrToInt(TDOMElement(res.AsNodeSet[F]).AttribStrings['WORDF']) To StrToInt(TDOMElement(res.AsNodeSet[F]).AttribStrings['WORDN'])-1 Do
                              Add(ENV.CollectedWords.Strings[G])
                      End
                 end
            end;
       res.Free;
       ENV.CollectedWords.Clear;
       For F := 0 To Ruler.Count - 2 Do
         Begin
           K := TObjectToInteger(Ruler.Objects[F]);
           P := F;
           For G := F + 1 To Ruler.Count - 1 Do
             Begin
               M := TObjectToInteger(Ruler.Objects[G]);
               If M < K Then
                  Begin
                    K := M;
                    P := G
                  End
             End;
           If P <> F Then
              begin
                Ruler.Exchange(P, F);
                Seq.Exchange(P, F);
                RulerClasses.Exchange(P, F)
              end
         End;
       For F := 0 To Ruler.Count - 1 Do
         begin
           Ruler.Objects[F] := TObject(NewStr(RulerClasses.Strings[F]));
           Seq.Add(IntegerToTObject(ENV.CollectedWords.Count));
           ENV.CollectedWords.AddStrings(TStringList(Seq[F]));
           Seq.Add(IntegerToTObject(ENV.CollectedWords.Count))
         end;
       For F := 0 To Ruler.Count - 1 Do
         Seq.Delete(0);
       RulerClasses.Free;
       Variants := TStringList.Create;
       Variants.Sorted := True;

       Stat := TObjList.Create;

       NumThreads := MaxCPUs;
       MetaResult := Nil;

       SetLength(MetaTrace, 0);
       SetLength(Probabilities, _Restrictions.Count, _Restrictions.Count);
       SetLength(lProbabilities0, _Restrictions.Count, _Restrictions.Count);
       SetLength(lProbabilities1, _Restrictions.Count, _Restrictions.Count);
       For F := 0 To _Restrictions.Count - 1 Do
           For G := 0 To _Restrictions.Count - 1 Do
               Probabilities[F][G] := 1.0;
       If Length(DeduceLogFile) > 0 Then
          If FileExists(DeduceLogFile) Then
             Begin
               AssignFile(Log, DeduceLogFile);
               Reset(Log);
               If Not Eof(Log) Then
                 begin
                   Words := TStringList.Create;
                   Words.CaseSensitive := False;
                   Words.Sorted := True;

                   AddWords(ENV.CollectedWords);

                   locWords := TStringList.Create;
                   locWords.Delimiter := SemiColon;
                   locRels := TStringList.Create;
                   locRels.Delimiter := SemiColon;
                   locSeq := TStringList.Create;
                   locSeq.Delimiter := Colon;
                   prev := -1;
                   While Not Eof(Log) Do
                     begin
                       Read(Log, this);
                       If this = -11 Then
                          begin
                            Mode := '';
                            Repeat
                               Read(Log, C);
                               If C = '*' Then
                                  Break
                               Else
                                  AppendStr(Mode, C)
                            Until Eof(Log);
                            Mode := Trim(Mode);
                            If Mode = SelectedMode Then
                               this := -10
                          end;
                       If this = -10 Then
                          begin
                            If UseNNet Then
                               begin
                                 locWords.DelimitedText := ReadStr(Log);
                                 locRels.DelimitedText := ReadStr(Log);
                                 locSeq.DelimitedText := ReadStr(Log);
                                 AddWords(locWords)
                               end
                            Else
                               begin
                                 ReadStr(Log);
                                 ReadStr(Log);
                                 ReadStr(Log)
                               end;
                            locP := TStringList.Create;
                            locP.Delimiter := ';';
                            locP.DelimitedText := ReadStr(Log);
                            K := 0;
                            For F := 0 To _Restrictions.Count - 1 Do
                                For G := 0 To _Restrictions.Count - 1 Do
                                    begin
                                      Val(locP.Strings[K], lProbabilities0[F][G], P);
                                      Inc(K)
                                    end;
                            locP.DelimitedText := ReadStr(Log);
                            K := 0;
                            For F := 0 To _Restrictions.Count - 1 Do
                                For G := 0 To _Restrictions.Count - 1 Do
                                    begin
                                      Val(locP.Strings[K], lProbabilities1[F][G], P);
                                      Inc(K)
                                    end;
                            locP.Free;
                            Read(Log, TT);
                            If UseNNet Then
                               begin
                                 If TT < 0.0 Then
                                    begin
                                      Read(Log, G);
                                      SetLength(lTrace, G);
                                      For F := 0 To G-1 Do
                                          Read(Log, lTrace[F]);
                                      Read(Log, TT)
                                    end
                                 Else
                                    SetLength(lTrace, 0);
                                 Stat.Add(TStat.Create(locSeq, locWords, locRels, lProbabilities0, lProbabilities1, TT, lTrace))
                               end
                            Else
                               For F := 0 To _Restrictions.Count - 1 Do
                                   For G := 0 To _Restrictions.Count - 1 Do
                                       Probabilities[F][G] := Probabilities[F][G] + (lProbabilities1[F][G] - 0.7)
                          end
                       Else
                          ReadLn(Log, S);
                       if (prev >= 0) And (this >= 0) Then
                          Probabilities[prev][this] := Probabilities[prev][this] + 0.3;
                       prev := this
                     end;
                   NormalizeProbabilities(0.25, _Restrictions.Count, Probabilities);
                   locRels.Free;
                   locWords.Free;
                   locSeq.Free
                 end;
               CloseFile(Log)
             end;

       SetLength(MainLine, 0);

       If Stat.Count > 0 Then // Some magic...
          begin
            RelsMap := TStringList.Create;
            RelsMap.Sorted := True;

            // Add PRESENT Type - frequences of local words;
            RelsMap.Add('PRESENT');
            // Add SEQ Type - Levenshtein task difference;
            RelsMap.Add('SEQ');
            // Add TIME Type
            RelsMap.Add('TIME');

            LL := TAnalyser.Create(LettersSet, [Space, Tabulation]);

            AddRels(LL, RelsMap, ENV.CollectedRels);

            For F := 0 To Stat.Count - 1 Do
                With TStat(Stat[F]) Do
                  AddRels(LL, RelsMap, lRels);
            // In each Stat[F] create RelsMap copy with local matrices
            For F := 0 To Stat.Count - 1 Do
                With TStat(Stat[F]) Do
                  begin
                    INP.Assign(RelsMap);
                    SetProbabilities(LL, INP, lSeq, lWords, lRels, ENV.CollectedWords, Time)
                  end;
            // Calculate Radiuses
            SetLength(Dists, Stat.Count - 1);
            For F := 0 To Stat.Count - 1 Do
                With TStat(Stat[F]) Do
                  begin
                    K := 0;
                    For G := 0 To Stat.Count - 1 Do
                      If F <> G Then
                         begin
                           Dists[K] := CalcDist(INP, TStat(Stat[G]).INP);
                           If Dists[K] > 0.0 Then Inc(K)
                         end;
                    // Find First 5 minimal dists
                    M := Min(K, 5);
                    R := 0.0;
                    For G := 0 To M-1 Do
                      begin
                        P := G;
                        For H := G+1 To K - 1 Do
                          If Dists[P] > Dists[H] Then
                             P := H;
                        R := R + Dists[P];
                        If P <> G Then
                           begin
                             Buf := Dists[P];
                             Dists[P] := Dists[G];
                             Dists[G] := Buf
                           end
                      end;
                    If R > 0 Then R := 2.0*M/R;
                    R := Math.Max(0.1, Math.Min(2.0, R))
                  end;
            SetProbabilities(LL, RelsMap, Seq, ENV.CollectedWords, ENV.CollectedRels, ENV.CollectedWords, 0.0);
            // Calc Probabilities based on RelsMap.OBJS x Stat[F].Objs[INP=>Probabilities]
            For F := 0 To _Restrictions.Count - 1 Do
                For G := 0 To _Restrictions.Count - 1 Do
                    Probabilities[F][G] := 0.0;

            W := 0.0;
            For K := 0 To Stat.Count - 1 Do
                With TStat(Stat[K]) Do
                  begin
                    W1 := Exp(-R*CalcDist(INP, RelsMap, False));
                    If MainLineAllowed And (Length(Trace) > Length(MainLine)) And (CalcDist(INP, RelsMap, True) = 0.0) Then
                       begin
                         SetLength(MainLine, Length(Trace));
                         If Length(Trace) > 0 Then
                            Move(Trace[0], MainLine[0], Length(Trace)*SizeOf(Integer))
                       end;
                    WT := 0.5 + 0.25*Math.Min(1.0, Time/100.0);
                    For F := 0 To _Restrictions.Count - 1 Do
                        For G := 0 To _Restrictions.Count - 1 Do
                            Probabilities[F][G] := Probabilities[F][G] +
                               W1*((1-WT)(*0.3*)*OUT0[F][G]+WT*(*0.7*)OUT1[F][G]);
                    W := W+W1
                  end;
            If W > 0.0 Then
               For F := 0 To _Restrictions.Count - 1 Do
                   For G := 0 To _Restrictions.Count - 1 Do
                       Probabilities[F][G] := Probabilities[F][G]/W;
            NormalizeProbabilities(0.0, _Restrictions.Count, Probabilities);

            LL.Free;
            With RelsMap Do
              begin
                For F := 0 To Count - 1 Do
                  If Assigned(Objects[F]) Then
                     Dispose(PMatrixType(Objects[F]));
                Free
              end
          end;

       NumThrSemaphore := TSemaphore.Create(NumThreads - 1);
       InitCriticalSection(VariantsCS);

       Messaging := False;
       Randomize;

       Time := Now;
       init_dom := dom.CloneNode(True) As TXMLDocument;
       Repeat
          MetaResult := Nil;

          SetLength(tr, 0);
          Start := Now;
          deducer := TDeducer.Create(CurLanguageName, ENV, dom, false, -1, tr, 0, MainLine);
          deducer.Resume;
          deducer.WaitFor;
          dom := deducer.dom;
          deducer.Free;
          If MetaResult = TSystem($0FFFFFFFF) Then
             begin
               dom.Free;
               dom := init_dom.CloneNode(True) As TXMLDocument;
               Variants.Clear;
               {$IF DEFINED(VCL) OR DEFINED(LCL)}
               Application.ProcessMessages
               {$ELSE}
               Sleep(0)
               {$ENDIF}
             end
          Else
             init_dom.Free;
       Until MetaResult <> TSystem($0FFFFFFFF);
       Time := 0.001*MilliSecondsBetween(Time, Now);

       FreeAndNil(NumThrSemaphore);
       DoneCriticalSection(VariantsCS);

       Variants.Free;
       FreeAndNil(Stat);
       FreeAndNil(Words);
       If Assigned(MetaResult) Then
          Begin
            If (Length(DeduceLogFile) > 0) And (Length(MainLine) = 0) Then
               Begin
                 AssignFile(Log, DeduceLogFile);
                 If FileExists(DeduceLogFile) Then
                    Append(Log)
                 Else
                    Rewrite(Log);
                 Write(Log, -11, ' ', SelectedMode, '* ');
                 S := ENV.CollectedWords.DelimitedText;
                 Write(Log, ' ', Length(S), ' ', S, ' ');
                 S := ENV.CollectedRels.DelimitedText;
                 Write(Log, ' ', Length(S), ' ', S, ' ');
                 S := '';
                 For F := 0 To Seq.Count-1 Do
                   begin
                     AppendStr(S, IntToStr(TObjectToInteger(Seq[F])));
                     If F < Seq.Count-1 Then
                        AppendStr(S, ':')
                   end;
                 Write(Log, ' ', Length(S), ' ', S, ' ');
                 locP := TStringList.Create;
                 locP.Delimiter := ';';
                 For F := 0 To _Restrictions.Count - 1 Do
                     For G := 0 To _Restrictions.Count - 1 Do
                         begin
                           Str(Probabilities[F][G]:5:3, S);
                           locP.Add(Trim(S))
                         end;
                 S := locP.DelimitedText;
                 Write(Log, Length(S), ' ', S, ' ');

                 For F := 0 To _Restrictions.Count - 1 Do
                     For G := 0 To _Restrictions.Count - 1 Do
                         Probabilities[F][G] := Random;

                 { Baum-Welch }
                 // BaumWelch(L, T, N, Y[T+1], A[N*N], B[L*N], _pi[N], delta[T*L]);
                 SetLength(lProbabilities0, _Restrictions.Count, _Restrictions.Count);
                 For F := 0 To _Restrictions.Count - 1 Do
                     For G := 0 To _Restrictions.Count - 1 Do
                         lProbabilities0[F][G] := Random;
                 SetLength(_pi, _Restrictions.Count);
                 For F := 0 To _Restrictions.Count - 1 Do
                     _pi[F] := Random;
                 SetLength(lProbabilities1, High(MetaTrace), _Restrictions.Count);
                 For F := 0 To High(MetaTrace) - 1 Do
                     For G := 0 To _Restrictions.Count - 1 Do
                         If MetaTrace[F+1] = G Then
                            lProbabilities1[F][G] := 1.0
                         Else
                            lProbabilities1[F][G] := 0.0;

                 BaumWelch(_Restrictions.Count, High(MetaTrace), _Restrictions.Count,
                     MetaTrace,
                     Probabilities, lProbabilities0, _pi, lProbabilities1);

                 SetLength(lProbabilities1, _Restrictions.Count, _Restrictions.Count);
                 { Переходим от наблюдений к вероятностям состояний, применяем матрицу переходов между состояниями,
                   переходим от состояний к наблюдениям, в-общем P = B*A*transp(B) }
                 For F := 0 To _Restrictions.Count - 1 Do
                   For G := 0 To _Restrictions.Count - 1 Do
                     begin
                       lProbabilities1[F][G] := 0.0;
                       For K := 0 To _Restrictions.Count - 1 Do
                           lProbabilities1[F][G] := lProbabilities1[F][G] +
                              lProbabilities0[F][K]*Probabilities[K][G]
                     end;
                 For F := 0 To _Restrictions.Count - 1 Do
                   For G := 0 To _Restrictions.Count - 1 Do
                     begin
                       Probabilities[F][G] := 0.0;
                       For K := 0 To _Restrictions.Count - 1 Do
                           Probabilities[F][G] := Probabilities[F][G] +
                              lProbabilities1[F][K]*lProbabilities0[G][K]
                     end;

                 For F := 0 To _Restrictions.Count - 1 Do
                   begin
                     W := 0.0;
                     For G := 0 To _Restrictions.Count - 1 Do
                       If Probabilities[F][G] > W Then
                          W := Probabilities[F][G];
                     If W > 0.0 Then
                        For G := 0 To _Restrictions.Count - 1 Do
                            Probabilities[F][G] := Probabilities[F][G]/W;
                     For G := 0 To _Restrictions.Count - 1 Do
                         Probabilities[F][G] := 0.7 + 0.3*Probabilities[F][G];
                   end;

                 locP.Clear;
                 For F := 0 To _Restrictions.Count - 1 Do
                     For G := 0 To _Restrictions.Count - 1 Do
                         begin
                           Str(Probabilities[F][G]:5:3, S);
                           locP.Add(Trim(S))
                         end;

                 S := locP.DelimitedText;
                 locP.Free;
                 Write(Log, Length(S), ' ', S, ' ', -20, ' ');
                 Write(Log, Length(MetaTrace)-1, ' ');
                 For F := 1 To High(MetaTrace) Do
                     Write(Log, MetaTrace[F], ' ');
                 WriteLn(Log, Time:5:2);
                 CloseFile(Log)
               End;
            MetaResult.SaveToXML('', OutXML);
            MetaResult.Free;
            MakeInfoCommon('Deduced successfully in ' + FloatToStrF(Time, ffGeneral, 3, 6) + ' sec!')
          End
       Else
          MakeErrorCommon('Unsuccessfull XPath Deducing in ' + FloatToStrF(Time, ffGeneral, 3, 6) + ' sec...');
       Seq.Free;
       dom.Free;
     finally
       src.Free;
       Messaging := True
     end;
   finally
     parser.Free;
     L.Free
   end;

   Result := True
end;

end.

