unit InductModel;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$CODEPAGE UTF8}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF}Classes, SysUtils, FileUtil,
  {$IFDEF FPC}LResources,{$ENDIF}Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Buttons, CheckLst, Spin, ExtCtrls, Elements, MetaComp, xpath;

type

  { TInductModelForm }

  TInductModelForm = class(TForm)
    UseMainLine: TCheckBox;
    Label4: TLabel;
    Timeout: TSpinEdit;
    UseNNet: TCheckBox;
    Label3: TLabel;
    nCPUs: TSpinEdit;
    UseXPathing: TCheckBox;
    CompileBtn: TBitBtn;
    btnLoadProgram: TBitBtn;
    btnCancel: TBitBtn;
    btnOk: TBitBtn;
    clbVersions: TCheckListBox;
    ClassesTree: TTreeView;
    Label1: TLabel;
    Label2: TLabel;
    memResult: TMemo;
    memProgram: TMemo;
    OpenDialog: TOpenDialog;
    Progress: TProgressBar;
    SaveDialog: TSaveDialog;
    SelectedClassesTree: TTreeView;
    gbClasses: TGroupBox;
    gbSelectedClasses: TGroupBox;
    btnAdd: TSpeedButton;
    btnDel: TSpeedButton;
    procedure btnAddClick(Sender: TObject);
    procedure btnDelClick(Sender: TObject);
    procedure btnLoadProgramClick(Sender: TObject);
    procedure btnOkClick(Sender: TObject);
    procedure ClassesTreeDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure ClassesTreeDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure clbVersionsClickCheck(Sender: TObject);
    procedure CompileBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure SelectedClassesTreeDragDrop(Sender, Source: TObject; X, Y: Integer
      );
    procedure SelectedClassesTreeDragOver(Sender, Source: TObject; X,
      Y: Integer; State: TDragState; var Accept: Boolean);
    procedure UseXPathingClick(Sender: TObject);
  private
    { private declarations }
    InductSeq, ExInductSeq: TElementRegs;
    InductRoot: TElementReg;
    Continuous: Boolean;
    ENV: TXPathEnvironment;

    procedure OnStage(Percent: Real; Const MacroID: String = '');
    procedure UpdateInductSeq(ReReadVersions: Boolean);
  public
    { public declarations }
  end;

implementation

Uses Common, Regexpr, Main, AutoUtils, AutoConsts, Math,
  dom, xmlread, xmlwrite, Windows, Lexique, DateUtils,
  xpathingIntrf;

{ TInductModelForm }

procedure TInductModelForm.btnAddClick(Sender: TObject);

procedure addNodes(This: TTreeNode; IntoParent: TTreeNode);

Var F: Integer;
Begin
   With SelectedClassesTree.Items Do
     Begin
       For F := 0 To Count - 1 Do
           If TElementReg(Item[F].Data) = This.Data Then
              Exit;
       If Assigned(IntoParent) Then
          IntoParent := AddChildObject(IntoParent, This.Text, This.Data)
       Else
          IntoParent := AddObject(Nil, This.Text, This.Data);
       For F := 0 To This.Count - 1 Do
           addNodes(This.Items[F], IntoParent)
     End
End;

begin
  If Assigned(ClassesTree.Selected) Then
     begin
       addNodes(ClassesTree.Selected, Nil);
       UpdateInductSeq(True)
     end;
end;

procedure TInductModelForm.btnDelClick(Sender: TObject);
begin
  If Assigned (SelectedClassesTree.Selected) Then
     begin
       SelectedClassesTree.Selected.Delete;
       UpdateInductSeq(True)
     end;
end;

procedure TInductModelForm.btnLoadProgramClick(Sender: TObject);
begin
   OpenDialog.InitialDir := GetCurrentDir();
   If OpenDialog.Execute Then
      memProgram.Lines.LoadFromFile(OpenDialog.FileName);
end;

Procedure TInductModelForm.OnStage(Percent: Real; Const MacroID: String = '');
Begin
  Progress.Position := Round(Percent*Progress.Max);
  If Length(MacroID) > 0 Then
     memResult.Lines.Add(MacroID + ' - макрос завершен');
  Application.ProcessMessages
End;

procedure TInductModelForm.btnOkClick(Sender: TObject);

Var F: Integer;
    M: MetaCompiler;
    SelectedVersion: String;
    E: String;
    IDs: IDArray;
    ExportedENV: Array[0..65536] Of Char;
    _IDs: String;
begin
  If btnOk.ModalResult = mrNone Then
     Begin
       btnOk.Caption := 'Закрыть';
       btnOk.ModalResult := mrOk;
       If Length(InductSeq) > 0 Then
          Begin
            SelectedVersion := '';
            With clbVersions.Items Do
              For F := 0 To Count - 1 Do
                  if clbVersions.Checked[F] Then
                     begin
                       Versions.Objects[F] := IntegerToTObject(1);
                       SelectedVersion := Strings[F]
                     end
                  else
                     Versions.Objects[F] := Nil;
            M := MetaCompiler.Create(UTF8Decode(EscapeString(memProgram.Lines.Text)));
            For F := Low(InductSeq) To High(InductSeq) Do
                If InductSeq[F].AddMacro(UseXPathing.Checked, M) = Nil Then
                   Begin
                     MessageDlg('Error', 'Induct Macro Error : ' + InductSeq[F].ClsID, mtError, [mbOk], 0);
                     Break
                   End;
            memResult.Lines.Clear;
            ChDir(ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName)));
            Try
               Progress.Position := 0;
               If Continuous Then
                  M.RunContinuous(ENV, UseXPathing.Checked, OnStage)
               Else
                  M.Run(ENV, UseXPathing.Checked, OnStage);

               If UseXPathing.Checked Then
                  If FileExists(XPathModelFile) Then
                     Begin
                       memResult.Color := clWhite;
                       memResult.Lines.LoadFromFile(XPathModelFile);
                       memResult.Lines.Insert(0, '<OBJS>');
                       memResult.Lines.Add('</OBJS>');
                       If Length(OutModelName) > 0 Then
                          Begin
                            SetLength(IDs, M.NLocks);
                            For F := 0 To M.NLocks - 1 Do
                                IDs[F] := M.LockIDs[F];
                            SetInterval(1000*Timeout.Value);
                            With TStringList.Create Do
                              Begin
                                For F := 0 To Length(IDs)-1 Do
                                    Add(IDs[F]);
                                _IDs := String(Text);
                                Free
                              end;
                            ENV.commitUndo(0);
                            ENV.Export(ExportedENV);
                            XPathInduct(
                               Messaging,
                               @CreateSysF, @ExistClassF, @GetElementF,
                               @CanReachF, @CreateContactsF, @AddElementF,
                               @AddLinkF, @AnalyzeLinkStatusIsInformF, @SetParameterIfExistsF,
                               @MoveF, @CheckSysF, @ToStringF,
                               @GenerateCodeF, @SaveToXMLF, @_FreeF,
                               @NodeNameTester,
                               PChar(SelectedVersion), UseNNet.Checked, UseMainLine.Checked, Nil, ExportedENV, ExportedENV, PChar(String(XPathModelFile)), PChar(OutModelName), nCPUs.Value, PChar(_IDs),
                               False
                            );
                            MakeInfoCommon(String(GetMSG));
                            ENV.Import(ExportedENV)
                          end;
                     End
                  Else
                     MessageDlg('Error', 'No preliminary XML-Model file created!', mtError, [mbOk], 0)
               Else
                  Begin
                    memResult.Color := clWhite;
                    memResult.Lines.Text := UnescapeString(M.Text)
                  End;
            Finally
               M.Free;
            End;

            If Length(OutModelName) > 0 Then
               Begin
                 E := LowerCase(ExtractFileExt(OutModelName));
                 ChDir(ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName)));
                 If (E = '.xml') Or (E = '.amd') Then
                    MainForm.RenewModel(False, OutModelName)
                 Else
                    memResult.Lines.LoadFromFile(OutModelName)
               end
            Else
               MessageDlg('Информация', 'В файле настроек индукции ''' + InductFile + ''' нет сведений об имени выходного файла модели', mtInformation, [mbOk], 0)
          End
     End
end;

procedure TInductModelForm.ClassesTreeDragDrop(Sender, Source: TObject; X,
  Y: Integer);
begin
   If (Source = SelectedClassesTree) And Assigned(SelectedClassesTree.Selected) Then
      btnDelClick(Nil)
end;

procedure TInductModelForm.ClassesTreeDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
   Accept := (Source = SelectedClassesTree)
end;

procedure TInductModelForm.clbVersionsClickCheck(Sender: TObject);

Var F, G: Integer;
begin
  With Versions Do
    For F := 0 To Count-1 Do
        If clbVersions.Checked[F] And Not Assigned(Objects[F]) Then
           Begin
             For G := 0 To Count-1 Do
                 If F <> G Then
                    Begin
                      clbVersions.Checked[G] := False;
                      Objects[G] := Nil
                    end;
             Objects[F] := IntegerToTObject(1);
             Break
           end;
  UpdateInductSeq(False)
end;

procedure TInductModelForm.CompileBtnClick(Sender: TObject);

Var S: TStringList;
    M: MetaCompiler;
    Z: ScanMacro;
    Name: String;
    Path: String;
    SelectedVersion: String;
    F, G, K: Integer;
    Q: String;
begin
    If (Length(InductSeq) > 0) And SaveDialog.Execute Then
       Begin
          Name := ExtractFileName(SaveDialog.FileName);

          S := TStringList.Create;

          S.Add('Program Induct;');
          S.Add('{$IF (NOT DEFINED(UNIX)) AND (NOT DEFINED(LINUX))}');
          S.Add('{$APPTYPE CONSOLE}');
          S.Add('{$ENDIF}');

          S.Add('{$IFDEF FPC}');
          S.Add('{$MODE ObjFPC}');
          S.Add('{$ENDIF}');
          S.Add('{$H+}');

          S.Add('{$CODEPAGE UTF8}');

          S.Add('Uses {$IF DEFINED(UNIX) OR DEFINED(LINUX)}cthreads{$ELSE}Windows{$ENDIF}, xpathingIntrf, AutoConsts, RegExpr, MetaComp, DateUtils, SysUtils, Classes, xpath, Elements, AutoUtils, Common;');
          S.Add('Type Stager = class');
          S.Add('        Procedure OnStage(Percent: Real; Const MacroID: AnsiString = '''');');
          S.Add('     End;');
          S.Add('Procedure Stager.OnStage(Percent: Real; Const MacroID: AnsiString);');
          S.Add('Begin');
          S.Add('   Write(#$0D, Round(Percent*100), ''%   '');');
          S.Add('End;');
          S.Add('Var M: MetaCompiler;');
          S.Add('    F: TextFile;');
          S.Add('    L: TStringList;');
          S.Add('    DB: TFastDB;');
          S.Add('    Z: ScanMacro;');
          S.Add('    ENV: TXPathEnvironment;');
          S.Add('    Strs: StringArray;');
          S.Add('    IDs: IDArray;');
          S.Add('    ExportedENV: Array[0..65536] Of Char;');
          S.Add('    _IDs: String;');
          S.Add('    Timeout: Integer;');
          S.Add('    nCPUs: Integer;');
          S.Add('    ST: Stager;');
          S.Add('    G: Integer;');
          S.Add('Begin');

          S.Add('  DefaultTextLineBreakStyle := tlbsCRLF;');

          S.Add('  SetMultiByteConversionCodePage(CP_UTF8);');
          S.Add('  SetMultiByteRTLFileSystemCodePage(CP_UTF8);');

          S.Add('  If ParamCount < 2 Then');
          S.Add('     Begin');
          If UseXPathing.Checked Then
             S.Add('       WriteLn(''Usage: ' + Name + ' <inFile> <outFile> [Timeout_in_sec] [Num_of_CPU]'');')
          Else
             S.Add('       WriteLn(''Usage: ' + Name + ' <inFile> <outFile>'');');
          S.Add('       Exit');
          S.Add('     End;');

          S.Add('  Timeout := 60;');
          S.Add('  nCPUs := 1;');

          If UseXPathing.Checked Then
             begin
               S.Add('  If ParamCount > 2 Then');
               S.Add('     Begin');
               S.Add('       Timeout := StrToInt(ParamStr(3));');
               S.Add('       If ParamCount > 3 Then');
               S.Add('          nCPUs := StrToInt(ParamStr(4));');
               S.Add('     End;');
             end;

          S.Add('  ENV := TXPathEnvironment.Create;');

          If UseXPathing.Checked Then
             begin
               InductRoot.Script;
               Path := ExcludeTrailingBackSlash(ExtractFilePath(InductRoot.FStoredPath));
               If FileExists(Path + XPathFile) Then
                  With TStringList.Create Do
                    begin
                      LoadFromFile(Path + XPathFile);
                      S.Add('  ENV.Export(ExportedENV);');
                      S.Add('  If Not CompileXPathing(Messaging, PChar('''+SelectedVersion+'''), ''' + safeXPathFile + ''', Nil, ExportedENV, ExportedENV, ''' + pEscapeString(Text) + ''') Then');
                      S.Add('     ClearRestrictions;');
                      S.Add('  ENV.Import(ExportedENV);');
                      Free
                    end;
             end;

          S.Add('  ST := Stager.Create;');
          S.Add('  L := TStringList.Create;');
          S.Add('  L.LoadFromFile(ParamStr(1));');
          S.Add('  M := MetaCompiler.Create(UTF8Decode(EscapeString(L.Text)));');
          S.Add('  Try');

          S.Add('     set_default_transformer(''' + get_default_transformer() + ''');');

          SelectedVersion := '';
          With clbVersions.Items Do
            For F := 0 To Count - 1 Do
                if clbVersions.Checked[F] Then
                   begin
                     Versions.Objects[F] := IntegerToTObject(1);
                     SelectedVersion := Strings[F]
                   end
                else
                   Versions.Objects[F] := Nil;
          M := MetaCompiler.Create(UTF8Decode(EscapeString(memProgram.Lines.Text)));
          For F := Low(InductSeq) To High(InductSeq) Do
            Begin
              Z := InductSeq[F].AddMacro(UseXPathing.Checked, M);
              If Not Assigned(Z) Then
                 Begin
                   MessageDlg('Error', 'Induct Macro Error : ' + InductSeq[F].ClsID, mtError, [mbOk], 0);
                   Break
                 End
            End;
          memResult.Lines.Clear;
          ChDir(ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName)));

          If Not M.ExportPascal(S, '     ', 'M', 'Z', 'DB') Then
             MessageDlg('Error', 'Translation Error', mtError, [mbOk], 0);

          If Continuous Then
             S.Add('     M.RunContinuous(ENV, ' + BoolVals[UseXPathing.Checked] + ', @ST.OnStage);')
          Else
             S.Add('     M.Run(ENV, ' + BoolVals[UseXPathing.Checked] + ', @ST.OnStage);');
          If UseXPathing.Checked Then
             Begin
               S.Add('     If FileExists(XPathModelFile) And (Length(''' + OutModelName + ''') > 0) Then'); (* !!! *)
               S.Add('        Begin');
               S.Add('          L.LoadFromFile(XPathModelFile);');
               S.Add('          L.Insert(0, ''<OBJS>'');');
               S.Add('          L.Add(''</OBJS>'');');
               S.Add('          L.SaveToFile(''' + OutModelName + ''');');
               S.Add('          SetLength(IDs, M.NLocks);');
               S.Add('          For G := 0 To M.NLocks - 1 Do');
               S.Add('              IDs[G] := M.LockIDs[G];');
               S.Add('          With TStringList.Create Do');
               S.Add('            Begin');
               S.Add('              For G := 0 To Length(IDs)-1 Do');
               S.Add('                  Add(IDs[G]);');
               S.Add('              _IDs := String(Text);');
               S.Add('              Free');
               S.Add('            end;');
               S.Add('          SetInterval(1000*Timeout);');
               S.Add('          SetDeduceLogFile(''.' + safeLogFile + ''');');
               S.Add('          ENV.commitUndo(0);');

               If Assigned(ElementRegList) Then
                  For G := 0 To ElementRegList.Count - 1 Do
                      For F := Low(ExInductSeq) To High(ExInductSeq) Do
                          If (TElementReg(ElementRegList[G]) = ExInductSeq[F]) Then
                             With TElementReg(ElementRegList[G]) Do
                               begin
                                 If Assigned(Parent) Then
                                    Q := Parent.ClsID
                                 Else
                                    Q := '';
                                 S.Add('          SetLength(Strs,' + IntToStr(Length(FStoredPrms)) + ');');
                                 For K := 0 To High(FStoredPrms) Do
                                     S.Add('          Strs[' + IntToStr(K) + '] := ''' + pEscapeString(FStoredPrms[K]) + ''';');
                                 S.Add('          RegisterElement(''' + Q + ''',''' + ClsID + ''', ''' + Name + ''', ''' +
                                       pEscapeString(Script) + ''', ''' + pEscapeString(iScript) + ''', ''' + pEscapeString(sScript) + ''', '''', ' +
                                       BoolVals[Inherit] + ', Strs);');
                                 Break
                               end;

               If Assigned(ContactRegList) Then
                  For G := 0 To ContactRegList.Count - 1 Do
                      For F := Low(ExInductSeq) To High(ExInductSeq) Do
                          If TContactReg(ContactRegList[G]).ClsID = ExInductSeq[F].ClsID Then
                             With TContactReg(ContactRegList[G]) Do
                               begin
                                 Q := '          RegisterContact(''' + ClsID + ''', ''' + CntID + ''', ''' + Name + ''', ' + BoolVals[Req] + ', ';
                                 If Dir = dirInput Then
                                    AppendStr(Q, 'dirInput, ')
                                 Else
                                    AppendStr(Q, 'dirOutput, ');
                                 If CType = ctSingle Then
                                    AppendStr(Q, 'ctSingle);')
                                 Else
                                    AppendStr(Q, 'ctMany);');
                                 S.Add(Q);
                                 Break
                               end;

               If Assigned(LinkRegList) Then
                  For G := 0 To LinkRegList.Count - 1 Do
                      For F := Low(ExInductSeq) To High(ExInductSeq) Do
                          If (TLinkReg(LinkRegList[G]).InClsID = ExInductSeq[F].ClsID) Or
                             (TLinkReg(LinkRegList[G]).OutClsID = ExInductSeq[F].ClsID) Then
                             With TLinkReg(LinkRegList[G]) Do
                               begin
                                 S.Add('          RegisterLinkType(''' + OutClsID + ''', ''' + OutContID + ''', ''' + InClsID + ''', ''' + InContID + ''');');
                                 Break
                               end;

               S.Add('          ENV.Export(ExportedENV);');
               S.Add('          XPathInduct(');
               S.Add('              Messaging,');
               S.Add('              @CreateSysF, @ExistClassF, @GetElementF,');
               S.Add('              @CanReachF, @CreateContactsF, @AddElementF,');
               S.Add('              @AddLinkF, @AnalyzeLinkStatusIsInformF, @SetParameterIfExistsF,');
               S.Add('              @MoveF, @CheckSysF, @ToStringF,');
               S.Add('              @GenerateCodeF, @SaveToXMLF, @_FreeF,');
               S.Add('              @NodeNameTester,');
               S.Add('              PChar('''+SelectedVersion+'''), ' +
                                    BoolVals[UseNNet.Checked] + ', ' + BoolVals[UseMainLine.Checked] + ', Nil, ExportedENV, ExportedENV, PChar(String(XPathModelFile)), PChar(String(''' + OutModelName + ''')), nCPUs, PChar(_IDs), False);');
               S.Add('          MakeInfoCommon(String(GetMSG));');
               S.Add('          ENV.Import(ExportedENV);');
               S.Add('        End');
               S.Add('     Else');
               S.Add('        WriteLn(''No preliminary XML-Model file created!'');');
             End;
          S.Add('     AssignFile(F,ParamStr(2));');
          S.Add('     Rewrite(F);');
          If Length(OutModelName) > 0 Then
             Begin
               S.Add('     L.LoadFromFile(''' + OutModelName + ''');');
               S.Add('     WriteLn(F, L.Text);')
             End
          Else
             S.Add('     WriteLn(F, UnEscapeString(M.Text));');
          S.Add('     CloseFile(F);');

          M.Free;

          S.Add('  Finally');
          S.Add('     M.Free');
          S.Add('  End;');
          S.Add('  ST.Free;');
          S.Add('  L.Free;');
          S.Add('  ENV.Free;');

          S.Add('End.');

          S.SaveToFile('_.pas');

          S.Free;

          memResult.Lines.Text := RunExtCommand('run_fpc.bat','_ _.pout','_.pout','');

          If CompareText(ExtractFileName(SaveDialog.FileName), '_.exe') <> 0 Then
             Begin
               SysUtils.DeleteFile(SaveDialog.FileName);
               RenameFile(ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName)) + SuperSlash + '_.exe', SaveDialog.FileName)
             End
       End
end;

procedure TInductModelForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  ENV.Free
end;

procedure TInductModelForm.FormCreate(Sender: TObject);
begin
  InductSeq := Nil;
  InductRoot := Nil;
  ENV := TXPathEnvironment.Create;
  Continuous := False;

  nCPUs.MaxValue := Round(1.5*GetCPUCount);
  nCPUs.Value := nCPUs.MaxValue
end;

procedure TInductModelForm.SelectedClassesTreeDragDrop(Sender, Source: TObject;
  X, Y: Integer);
begin
   If (Source = ClassesTree) And Assigned(ClassesTree.Selected) Then
      btnAddClick(Nil)
end;

procedure TInductModelForm.SelectedClassesTreeDragOver(Sender, Source: TObject;
  X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
   Accept := (Source = ClassesTree)
end;

procedure TInductModelForm.UseXPathingClick(Sender: TObject);
begin
   nCPUs.Enabled := Not nCPUs.Enabled;
   Timeout.Enabled := Not Timeout.Enabled;
   UseNNet.Enabled := Not UseNNet.Enabled;
   UseMainLine.Enabled := Not UseMainLine.Enabled;
end;

procedure TInductModelForm.UpdateInductSeq(ReReadVersions: Boolean);

procedure getElements(Var ExInductSeq: TElementRegs; Const P: ComCtrls.TTreeNode);

Var F: Integer;
begin
   SetLength(ExInductSeq, Length(ExInductSeq)+1);
   ExInductSeq[High(ExInductSeq)] := TElementReg(P.Data);
   For F := 0 To P.Count - 1 Do
       getElements(ExInductSeq, P.Items[F])
end;

Var ITemp: TElementRegs;
    ICont: Boolean;
    P: ComCtrls.TTreeNode;
    F: Integer;
begin
   If ReReadVersions Then Versions.Clear;
   OutModelName := '';
   SetDeduceLogFile('');
   ClearRestrictions;
   ClearRuler;
   With SelectedClassesTree.Items Do
     Begin
       InductRoot := Nil;
       InductSeq := Nil;
       ExInductSeq := Nil;
       Continuous := False;
       ENV.Free;
       ENV := TXPathEnvironment.Create;
       For F := 0 To Count - 1 Do
           Begin
             ITemp := TElementReg(Item[F].Data).GetInductSeq(ICont, ENV);
             If (Not Assigned(InductSeq)) Or (Length(InductSeq) < Length(ITemp)) Then
                Begin
                  InductRoot := TElementReg(Item[F].Data);
                  SetLength(ExInductSeq, 0);
                  P := Item[F].Parent;
                  While Assigned(P) Do
                    begin
                      SetLength(ExInductSeq, Length(ExInductSeq)+1);
                      ExInductSeq[High(ExInductSeq)] := TElementReg(P.Data);
                      P := P.Parent
                    end;
                  getElements(ExInductSeq, Item[F]);
                  InductSeq := ITemp;
                  Continuous := ICont
                End
           end;
     End;
   If ReReadVersions Then clbVersions.Items.Assign(Versions)
end;

initialization
{$IFDEF FPC}
{$i InductModel.lrs}
{$ELSE}
{$R *.dfm}
{$ENDIF}

end.

