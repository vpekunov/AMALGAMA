unit Tran;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF} Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ShellApi, Buttons, ExtCtrls, ComCtrls, Windows{$IFDEF FPC}, LResources{$ENDIF};

type

  { TTranslator }

  TTranslator = class(TForm)
    LearnBtn: TBitBtn;
    TranTimer: TTimer;
    CloseBtn: TBitBtn;
    ErrProgText: TListBox;
    ProgressBar: TProgressBar;
    InfoPanel: TPanel;
    ProgText: TMemo;
    SaveBtn: TBitBtn;
    ExecuteBtn: TBitBtn;
    CopyBtn: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure LearnBtnClick(Sender: TObject);
    procedure TranTimerTimer(Sender: TObject);
    procedure ErrProgTextDrawItem(Control: TWinControl; Index: LongInt;
      Rect: TRect; State: TOwnerDrawState);
    procedure CopyBtnClick(Sender: TObject);
    procedure ExecuteBtnClick(Sender: TObject);
  private
    { Private declarations }
    StartLanguage:String;
  public
    { Public declarations }
  end;

Const TranName:String = '';

implementation


Uses Main, Elements, AutoConsts, Clipbrd, LEXIQUE, Common, AutoUtils, LearnTrouble;

function IsWindowsNT:Boolean;

Var OSV:OSVERSIONINFO;
begin
     OSV.dwOSVersionInfoSize:=SizeOf(OSV);
     GetVersionEx(OSV);
     Result:=OSV.dwPlatformId=VER_PLATFORM_WIN32_NT
end;

procedure TTranslator.FormShow(Sender: TObject);
begin
     TranTimer.Enabled:=True;
     ProgressBar.Position:=0;
     InfoPanel.Color:=clBtnFace;
     InfoPanel.Caption:='Генерация порождающей программы';
     ProgText.Hide;
     ErrProgText.Hide;
     CopyBtn.Enabled:=False;
     CloseBtn.Enabled:=False;
     SaveBtn.Enabled:=False;
     ExecuteBtn.Enabled:=False;
     LearnBtn.Enabled:=False;
     ProgressBar.Max:=200+Byte(Length(TranName)>0)*100
end;

procedure TTranslator.LearnBtnClick(Sender: TObject);

function GetElementReg(Const ClsID: String): TElementReg;

Var F: Integer;
begin
   If Assigned(ElementRegList) Then
      For F:=0 To ElementRegList.Count-1 Do
          If ClsID=TElementReg(ElementRegList.Items[F]).ClsID Then
             begin
               Result := TElementReg(ElementRegList.Items[F]);
               Exit
             end;
   Result := Nil;
end;

Var CurrentClass: String;
    Idx: Integer;

procedure SkipLine(Var Map: TStringList; Var MapIdx: Integer; N: Integer; Const IncreaseIdx: Boolean = True);

procedure SkipMarkup;

Var P: Integer;
begin
   P := Pos('>>>>>', Map[MapIdx]);
   While (MapIdx < Map.Count) And (Copy(Map[MapIdx], 1, 5) = '<<<<<') And (P > 0) Do
     begin
       If Map[MapIdx][6] = '/' Then
          CurrentClass := ''
       Else
          CurrentClass := Copy(Map[MapIdx], 6, P-6);
       Inc(MapIdx);
       If MapIdx < Map.Count Then
          P := Pos('>>>>>', Map[MapIdx]);
     end
end;

begin
  SkipMarkup;
  While N > 0 Do
    begin
      Dec(N);
      Inc(MapIdx);
      If IncreaseIdx Then Inc(Idx);
      SkipMarkup
    end
end;

function HandleChanges(AddDelMode: Boolean): Boolean;

Var Map: TStringList;
    Map1: TStringList;
    MapIdx: Integer;
    Map1Idx: Integer;
    Report: String;
    S: TStringList;
    Anlz: TAnalyser;
    M1, M2: Real;
    MM1, MM2: Real;
    Deleted: String;
    Changed: String;
    ChangedTo: String;
    ToAppend: String;
    AppendAfter: String;
    ElReg: TElementReg;
    VV: String;
    F, G, K, M: Integer;
    ErrorSignaled: Boolean;
begin
     Map := TStringList.Create;
     Map.LoadFromFile('_.map');
     Map1 := TStringList.Create;
     Map1.Assign(Map);
     CurrentClass := '';
     MapIdx := 0;
     Map1Idx := 0;
     Idx := 1;
     SkipLine(Map, MapIdx, 0);
     SkipLine(Map1, Map1Idx, 0, False);
     ProgText.Lines.SaveToFile('_.mod');
     Report := RunExtCommand('run_diff.bat','_.out _.mod _.diff','_.diff','');
     S := TStringList.Create;
     S.Text := Report;
     Anlz := TAnalyser.Create(IntNumberSet, [Space, Tabulation]);
     ErrorSignaled := False;
     F := 0;
     While (F < S.Count) And Not ErrorSignaled Do
       begin
         Anlz.AnlzLine := S.Strings[F];
         Inc(F);
         If Not (Anlz.Empty Or Anlz.IsNextSet(['<', Dash, '>'])) Then
            begin
              Anlz.GetNumber(True, M1);
              If Anlz.IsNext(Comma) Then
                 begin
                   Anlz.Check(Comma);
                   Anlz.GetNumber(True, M2);
                 end
              Else
                 M2 := M1;
              If AddDelMode And Anlz.IsNextSet(['d', 'D']) Then
                 begin
                   While Idx < M1 Do
                     begin
                       SkipLine(Map, MapIdx, 1);
                       SkipLine(Map1, Map1Idx, 1, False)
                     end;
                   For G := Round(M1) To Round(M2) Do
                     begin
                       Deleted := Map.Strings[MapIdx];
                       ElReg := GetElementReg(CurrentClass);
                       VV := StringReplace(CRLF + ElReg.Script, CRLF + Deleted + CRLF, #0, [rfReplaceAll]);
                       M := 0;
                       For K:= 1 To Length(VV) Do
                         If VV[K] = #0 Then
                            Inc(M);
                       If M = 1 Then
                          begin
                            VV := StringReplace(VV, #0, CRLF, []);
                            ElReg.Script := Copy(VV, 3, 16*65536)
                          end
                       Else
                          begin
                            MessageDlg('Строка "'+Deleted+'", возможно, встречается более одного раза или возникла иная проблема', mtInformation, [mbOk], 0);
                            VV := ElReg.Script;
                            If EditTroubles(CurrentClass, VV, Deleted) Then
                               ElReg.Script := VV;
                            ErrorSignaled := True
                          end;
                       Map1.Delete(Map1Idx);
                       SkipLine(Map1, Map1Idx, 0, False);
                       SkipLine(Map, MapIdx, 1)
                     end
                 end
              Else If Anlz.IsNextSet(['c', 'C']) And Not AddDelMode Then
                 begin
                   Anlz.DelFirst;
                   Anlz.GetNumber(True, MM1);
                   If Anlz.IsNext(Comma) Then
                      begin
                        Anlz.Check(Comma);
                        Anlz.GetNumber(True, MM2);
                      end
                   Else
                      MM2 := MM1;
                   While Idx < M1 Do
                     begin
                       SkipLine(Map, MapIdx, 1);
                       SkipLine(Map1, Map1Idx, 1, False)
                     end;
                   For G := Round(M1) To Round(M2) Do
                     begin
                       Changed := Map.Strings[MapIdx];
                       If Round(MM1) > Round(MM2) Then
                          begin // N1,N2cN : Deleting
                            ElReg := GetElementReg(CurrentClass);
                            VV := StringReplace(CRLF + ElReg.Script, CRLF + Changed + CRLF, #0, [rfReplaceAll]);
                            M := 0;
                            For K:= 1 To Length(VV) Do
                              If VV[K] = #0 Then
                                 Inc(M);
                            If M = 1 Then
                               begin
                                 VV := StringReplace(VV, #0, CRLF, []);
                                 ElReg.Script := Copy(VV, 3, 16*65536)
                               end
                            Else
                               begin
                                 MessageDlg('Строка "'+Changed+'", возможно, встречается более одного раза или возникла иная проблема', mtInformation, [mbOk], 0);
                                 VV := ElReg.Script;
                                 If EditTroubles(CurrentClass, VV, Changed) Then
                                    ElReg.Script := VV;
                                 ErrorSignaled := True
                               end;
                            Map1.Delete(Map1Idx);
                            SkipLine(Map1, Map1Idx, 0, False);
                            SkipLine(Map, MapIdx, 1)
                          end
                       Else
                          begin
                             ChangedTo := ProgText.Lines[Round(MM1)-1];
                             Map1.Strings[Map1Idx] := ChangedTo;
                             ElReg := GetElementReg(CurrentClass);
                             VV := StringReplace(CRLF + ElReg.Script, CRLF + Changed + CRLF, #0, [rfReplaceAll]);
                             M := 0;
                             For K:= 1 To Length(VV) Do
                               If VV[K] = #0 Then
                                  Inc(M);
                             If M = 1 Then
                                begin
                                  VV := StringReplace(VV, #0, CRLF + ChangedTo + CRLF, []);
                                  ElReg.Script := Copy(VV, 3, 16*65536)
                                end
                             Else
                                begin
                                  MessageDlg('Строка "'+Changed+'", возможно, встречается более одного раза или возникла иная проблема', mtInformation, [mbOk], 0);
                                  VV := ElReg.Script;
                                  If EditTroubles(CurrentClass, VV, Changed) Then
                                     ElReg.Script := VV;
                                  ErrorSignaled := True
                                end;
                             SkipLine(Map, MapIdx, 1);
                             SkipLine(Map1, Map1Idx, 1, False);
                             MM1 := MM1 + 1.0
                          end
                     end;
                   If Round(MM2-MM1) >= 0 Then
                      begin // NcN1,N2 : Append
                        AppendAfter := ChangedTo + CRLF;
                        ToAppend := '';
                        For G := Round(MM1) To Round(MM2) Do
                            begin
                              ToAppend := ToAppend + ProgText.Lines[Round(G)-1] + CRLF;
                              Map1.Insert(Map1Idx+G-Round(MM1)+1, ProgText.Lines[Round(G)-1])
                            end;
                        ElReg := GetElementReg(CurrentClass);
                        VV := StringReplace(CRLF + ElReg.Script, CRLF + AppendAfter, #0, [rfReplaceAll]);
                        SkipLine(Map, MapIdx, 1);
                        SkipLine(Map1, Map1Idx, (Round(MM2)-Round(MM1)+1)+1, False);
                        M := 0;
                        For K:= 1 To Length(VV) Do
                          If VV[K] = #0 Then
                             Inc(M);
                        If M = 1 Then
                           begin
                             VV := StringReplace(VV, #0, CRLF + AppendAfter + ToAppend, []);
                             ElReg.Script := Copy(VV, 3, 16*65536)
                           end
                        Else
                           begin
                             MessageDlg('Строка "'+Copy(AppendAfter, 1, Length(AppendAfter)-2)+'", возможно, встречается более одного раза или возникла иная проблема', mtInformation, [mbOk], 0);
                             VV := ElReg.Script;
                             If EditTroubles(CurrentClass, VV, Copy(AppendAfter, 1, Length(AppendAfter)-2)) Then
                                ElReg.Script := VV;
                             ErrorSignaled := True
                           end
                      end
                 end
              Else If AddDelMode And Anlz.IsNextSet(['a', 'A']) Then
                 begin
                   Anlz.DelFirst;
                   Anlz.GetNumber(True, MM1);
                   If Anlz.IsNext(Comma) Then
                      begin
                        Anlz.Check(Comma);
                        Anlz.GetNumber(True, MM2);
                      end
                   Else
                      MM2 := MM1;
                   While Idx < M1 Do
                     begin
                       SkipLine(Map, MapIdx, 1);
                       SkipLine(Map1, Map1Idx, 1, False)
                     end;
                   AppendAfter := Map.Strings[MapIdx] + CRLF;
                   ToAppend := '';
                   For G := Round(MM1) To Round(MM2) Do
                       begin
                         ToAppend := ToAppend + ProgText.Lines[Round(G)-1] + CRLF;
                         Map1.Insert(Map1Idx+G-Round(MM1)+1, ProgText.Lines[Round(G)-1])
                       end;
                   SkipLine(Map, MapIdx, 1);
                   SkipLine(Map1, Map1Idx, (Round(MM2)-Round(MM1)+1)+1, False);
                   ElReg := GetElementReg(CurrentClass);
                   VV := StringReplace(CRLF + ElReg.Script, CRLF + AppendAfter, #0, [rfReplaceAll]);
                   M := 0;
                   For K:= 1 To Length(VV) Do
                     If VV[K] = #0 Then
                        Inc(M);
                   If M = 1 Then
                      begin
                        VV := StringReplace(VV, #0, CRLF + AppendAfter + ToAppend, []);
                        ElReg.Script := Copy(VV, 3, 16*65536)
                      end
                   Else
                      begin
                        MessageDlg('Строка "'+Copy(AppendAfter, 1, Length(AppendAfter)-2)+'", возможно, встречается более одного раза или возникла иная проблема', mtInformation, [mbOk], 0);
                        VV := ElReg.Script;
                        If EditTroubles(CurrentClass, VV, Copy(AppendAfter, 1, Length(AppendAfter)-2)) Then
                           ElReg.Script := VV;
                        ErrorSignaled := True
                      end
                 end
            end
       end;
     Anlz.Free;
     S.Free;
     Map.Free;
     If Not ErrorSignaled Then
        begin
          Map1.SaveToFile('_.map');
          F := 0;
          While F < Map1.Count Do
            begin
              If (Copy(Map1[F], 1, 5) = '<<<<<') And (Pos('>>>>>', Map1[F]) > 0) Then
                 Map1.Delete(F)
              Else
                 Inc(F)
            end;
          Map1.SaveToFile('_.out')
        end;
     Map1.Free;
     Result := Not ErrorSignaled
end;

begin
  LearnBtn.Enabled := HandleChanges(True) And HandleChanges(False);
end;

procedure TTranslator.TranTimerTimer(Sender: TObject);

Const SignalStr = 'No errors'+CRLF+CRLF;

function ExtractBetween(Var Gen: String; Const Before,After: String):String;

Var A,B: Integer;
begin
     A:=Pos(Before,Gen);
     Delete(Gen,1,A+Length(Before)-1);
     B:=Pos(After,Gen);
     Result:=Copy(Gen,1,B-1);
     Delete(Gen,1,B+Length(After)-1)
end;

procedure OpenText(Error:Boolean);
begin
     Width:=540;
     Height:=510;
     Top:=(Screen.Height-Height) Div 2;
     Left:=(Screen.Width-Width) Div 2;
     If Error Then
        ErrProgText.Show
     Else
        ProgText.Show
end;

Function PopState(Var FName,Prm:String):Boolean;

Var F,G,BaseFile:TextFile;
    S:String;
    Anlz:TAnalyser;
begin
     Result:=FileExists('_.stack');
     If Result Then
        begin
          AssignFile(G,'_.newstack');
          Rewrite(G);
          AssignFile(F,'_.stack');
          Reset(F);
          S:='';
          While Not Eof(F) Do
            begin
              ReadLn(F,S);
              If Not Eof(F) Then
                 WriteLn(G,S)
            end;
          CloseFile(F);
          CloseFile(G);
          DeleteFile('_.stack');
          RenameFile('_.newstack','_.stack');
          Result:=Length(S)>0;
          If Result Then
             begin
               Anlz:=TAnalyser.Create(IdentSet,[Space,Tabulation]);
               Anlz.AnlzLine:=S;
               FName:=Anlz.GetString(Quote,Quote);
               Prm:=Anlz.GetAll;
               MainForm.RenewModel(False,StringReplace(FName,'/','\',[rfReplaceAll]));
               Anlz.Free;
               AssignFile(BaseFile,'_base.pl');
               Rewrite(BaseFile);
               WriteLn(BaseFile,'rededuce:-asserta(external_pop(',Prm,')).');
               CloseFile(BaseFile)
             end
        end
end;

Function RestoreState:Boolean;

Var F:TextFile;
    Lang,S:String;
    Anlz:TAnalyser;
begin
     Result:=FileExists('_.stack');
     If Result Then
        begin
          AssignFile(F,'_.stack');
          Reset(F);
          While Not Eof(F) Do
            ReadLn(F,S);
          CloseFile(F);
          Anlz:=TAnalyser.Create(IdentSet,[Space,Tabulation]);
          Anlz.AnlzLine:=S;
          MainSys.LoadFromFile(Lang,StringReplace(Anlz.GetString(Quote,Quote),'/','\',[rfReplaceAll]),Nil,Nil);
          Anlz.Free
        end
end;

procedure AddTaskFile(TaskFiles:TStringList; Const SessionID,TaskID,FileName:String);
begin
  CopyFile(PChar(FileName),PChar('_'+SessionID+'.'+TaskID+'.'+FileName),False);
  TaskFiles.AddObject('_'+SessionID+'.'+TaskID+'.'+FileName+'|'+FileName,TObject(tsInputFile+tsMoveFlag))
end;

Var Prog,Gen,Work: String;
    AllFlag: Boolean;
    Queued, Rededuce: Boolean;
    Rslt: Word;
    TempFileName: String;
    Forked: Boolean;
    SessionID,TaskID: String;
    TaskFiles: TStringList;
    Error, Flag: Boolean;
    S, S1, S2, BaseName, NewName, Lang: String;
    ForkParams: String;
    Offs: Integer;
    N, Npop, Nrededuce, Nforked, Ndeduce, ErrIdx: Integer;
    F: Integer;
    TaskFile: TextFile;
begin
     TranTimer.Enabled:=False;
     If Length(MainSys.SavedName)=0 Then
        BaseName:='_translated'
     Else
        BaseName:=ChangeFileExt(ExtractFileName(MainSys.SavedName),'');
     DeleteFile('_base.pl');
     DeleteFile('_.stack');
     AllFlag:=MainForm.AutoDeduce;
     Npop:=1;
     Repeat
       Nrededuce:=1;
       Repeat
         ChDir(ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName)));
         Nforked:=1;
         Repeat
           ProgressBar.Position:=0;
           Ndeduce:=1;
           Repeat
             Prog:='';
             Flag:=MainSys.GenerateProlog(Prog);
             Flag:=Flag And MainSys.Deductive And (Length(Prog)>0);
             If Flag Then
                begin
                  If AllFlag Or (ExternalForked=efNode) Then
                     Rslt:=mrYes
                  Else
                     Rslt:=MessageDlg('Система содержит дедуктивные блоки. Вывести новую модель?',mtConfirmation,[mbYes,mbNo,mbAll],0);
                  If Rslt=mrNo Then
                     begin
                       ModalResult:=mrOk;
                       Exit
                     end
                  Else
                     begin
                       If Rslt=mrAll Then
                          AllFlag:=True;
                       MainSys.SaveToProlog(MainForm.CurLanguageName,'_.pl');
                       With TStringList.Create Do
                         begin
                           LoadFromFile('_.pl');
                           Prog:=DecodeStr(Text)+CRLF+Prog+CRLF;
                           Free
                         end;
                       CreateStrFile('_.pl',Prog);
                       S:=StringReplace(ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName)),'\','/',[rfReplaceAll]);
                       NewName:=Format('%s.pop%u.reded%u.fork%u.ded%u.xml',[BaseName,Npop,Nrededuce,Nforked,Ndeduce]);
                       RunExtCommand('run_gprolog.bat',S+' _.pl process('''+NewName+''')',NewName,'');
                       MainForm.RenewModel(False,NewName);
                       Inc(Ndeduce)
                     end
                end
           Until Not Flag;
           ProgressBar.Position:=50;
           S:=ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName));
           Queued:=False;
           Rededuce:=FileExists(S+'\_base.pl');
           Forked:=FileExists(S+'\_.fork');
           If Forked Then
              begin
                AssignFile(TaskFile,S+'\_.fork');
                Reset(TaskFile);
                ReadLn(TaskFile,SessionID);
                ReadLn(TaskFile,TaskID);
                CloseFile(TaskFile);
                DeleteFile(PChar(S+'\_.fork'));
                With MainForm Do
                  begin
                    WaitForSingleObject(ControlMutex,INFINITE);
                    If Connected Then
                       If (Not MasterFlag) Or (Slaves.Count>0) Then
                          begin
                            TempFileName:='_'+SessionID+'.'+TaskID+'.xml';
                            MainSys.SaveToFile(MainForm.CurLanguageName,TempFileName);
                            Queued:=True;
                            TaskFiles:=TStringList.Create;
                            TaskFiles.AddObject(TempFileName,TObject(tsModelFile+tsMoveFlag));
                            TaskFiles.AddObject('_'+SessionID+'.'+TaskID+'.out',TObject(tsReportFile));
                            If FileExists(S+'\_vars.php3') Then
                               AddTaskFile(TaskFiles,SessionID,TaskID,'_vars.php3');
                            AddTask(SessionID,TaskID,TaskFiles,False)
                          end;
                    ReleaseMutex(ControlMutex)
                  end
              end;
           If Queued And Not Rededuce Then
              If PopState(S1,S2) Then
                 Rededuce:=True
              Else
                 begin
                   ModalResult:=mrOk;
                   Exit
                 end
           Else If Rededuce And (Queued Or Not Forked) Then
              If Not RestoreState Then
                 begin
//                   DeleteFile(S+'\_base.pl');
                   ModalResult:=mrOk;
                   Exit
                 end;
           Inc(Nforked);
         Until (Forked And Not Queued) Or Not Rededuce;
         Prog:='';
         If MainSys.GeneratePHP(Prog) Then
            begin
              MainSys.SaveToXML(MainForm.CurLanguageName,'_.xml');
              ProgressBar.Position:=100;
              InfoPanel.Caption:='Порождение программы';
              Application.ProcessMessages;
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
              ProgressBar.Position:=200;
              InfoPanel.Caption:='Конкретизация программы';
              Application.ProcessMessages;
              CreateStrFile('_.gen',Gen);
              Error:=Pos(errPHP,Gen)<>0;
              If Error Then
                 With ErrProgText.Items Do
                   begin
                     InfoPanel.Color:=clRed;
                     Text:=Prog;
                     Offs:=0;
                     ErrIdx:=-1;
                     Repeat
                       F:=Pos(errPHP,Gen);
                       If F>0 Then
                          begin
                            System.Delete(Gen,1,F-1);
                            S:=errMain+ExtractBetween(Gen,'<b>','</b>');
                            Gen:='</b>'+Gen;
                            S:=S+ExtractBetween(Gen,'</b>',' in <b>');
                            N:=StrToInt(ExtractBetween(Gen,' on line <b>','</b>'))+Offs-1;
                            If ErrIdx<0 Then ErrIdx:=N;
                            Insert(N,S);
                            Inc(Offs)
                          end
                     Until F=0;
                     If ErrIdx>1 Then
                        ErrProgText.TopIndex:=ErrIdx-1
                   end
              Else
                 If Length(TranName)>0 Then
                    begin
                      Work:=RunExtCommand('run_snob.bat','auto.sno '+TranName,'_.out',SignalStr);
                      ProgressBar.Position:=300;
                      ProgressBar.Repaint;
                      Error:=Pos(errMAIN,Work)<>0;
                      If Error Then
                         With ErrProgText.Items Do
                           begin
                             InfoPanel.Color:=clRed;
                             Text:=Work;
                             For F:=0 To Count-1 Do
                               If Copy(Strings[F],1,Length(errMAIN))=errMAIN Then
                                  If F>1 Then
                                     begin
                                       ErrProgText.TopIndex:=F-1;
                                       Break
                                     end
                           end
                      Else
                         begin
                           InfoPanel.Caption:='OK';
                           ProgText.Lines.Text:=Work
                         end
                    end
                 Else
                    begin
                      Work:=Gen;
                      CreateStrFile('_.out',Work);
                      InfoPanel.Caption:='OK';
                      ProgText.Lines.Text:=Work
                    end;
              Application.ProcessMessages
            end
         Else
            begin
              InfoPanel.Color:=clRed;
              If Assigned(ProcessedObject) Then
                 If ProcessedObject Is TElement Then
                    MessageDlg('Элемент "'+TElement(ProcessedObject).Ident+'" : '+
                               ErrorMsg,mtError,[mbOk],0)
                 Else If ProcessedObject Is TLink Then
                    With TLink(ProcessedObject) Do
                      MessageDlg('Связь "'+_From.Owner.Ident+'" -> "'+
                                 _To.Owner.Ident+'" : '+ErrorMsg,mtError,[mbOk],0)
                 Else
                    MessageDlg(ErrorMsg,mtError,[mbOk],0)
              Else
                 MessageDlg(ErrorMsg,mtError,[mbOk],0);
              Error:=True
            end;
         If Not Error Then
            begin
              S:=ExcludeTrailingBackSlash(ExtractFilePath(Application.ExeName));
              If FileExists(S+'\_.start') Then
                 begin
                   AssignFile(TaskFile,S+'\_.start');
                   Reset(TaskFile);
                   ReadLn(TaskFile,StartLanguage);
                   CloseFile(TaskFile);
                   DeleteFile(PChar(S+'\_.start'));
                   If MainForm.AutoStart Or (ExternalForked=efNode) Or (MessageDlg('Сгенерированная программа требует запуска (язык "'+StartLanguage+'"). Запустить?',mtConfirmation,[mbYes,mbNo],0)=mrYes) Then
                      ExecuteBtnClick(Nil)
                   Else
                      ExecuteBtn.Enabled:=True
                 end;
              If Forked And Not Queued Then
                 begin
                   ProgText.Lines.SaveToFile('_'+SessionID+'.'+TaskID+'.out');
                   CreateStrFile('_'+SessionID+'.'+TaskID+'.ok','')
                 end;
              If Rededuce Then
                 If Not RestoreState Then
                    begin
//                      DeleteFile(S+'\_base.pl');
                      ModalResult:=mrOk;
                      Exit
                    end
            end;
         Inc(Nrededuce)
       Until Error Or Not Rededuce;
       If Not Error Then
          Flag:=Not PopState(S,S1);
       Inc(Npop)
     Until Error Or Flag;
     OpenText(Error);
     CloseBtn.Enabled:=True;
     CopyBtn.Enabled:=Not Error;
     LearnBtn.Enabled:=(Length(TranName)=0) And Not Error;
     If ExternalForked<>efFree Then
        begin
          ProgText.Lines.SaveToFile(ExternalOutputName);
          CreateStrFile(ChangeFileExt(ExternalOutputName,'.ok'),'');
          If FileExists('_out.pl') And Not Error Then
             Begin
               S:=ChangeFileExt(ExternalOutputName,'._out.pl');
               DeleteFile(PChar(S));
               RenameFile('_out.pl',S)
             End;
          ModalResult:=mrOk
        end
     // ToSpawn -- del TempFileName, [SessionID, TaskID] -- register to delete
end;

procedure TTranslator.CopyBtnClick(Sender: TObject);
begin
     Clipboard.SetTextBuf(PChar(ProgText.Lines.Text))
end;

procedure TTranslator.ExecuteBtnClick(Sender: TObject);
begin
     ExecuteBtn.Enabled:=False;
     Enabled:=False;
     ProgText.Lines.Text:='Компиляция и запуск...';
     Application.ProcessMessages;
     ProgText.Lines.Text:=RunExtCommand('start_'+StartLanguage+'.bat','_.out _.res','_.res',CRLF+CRLF);
     Enabled:=True
end;

procedure TTranslator.ErrProgTextDrawItem(Control: TWinControl;
  Index: LongInt; Rect: TRect; State: TOwnerDrawState);
begin
     With ErrProgText, ErrProgText.Canvas Do
       begin
         If odSelected In State Then
            begin
              Brush.Color:=clNavy;
              Font.Color:=clWhite
            end
         Else
            If (Index>=0) And (Copy(Items[Index],1,Length(errMAIN))=errMAIN) Then
              begin
                Brush.Color:=clRed;
                Font.Color:=clWhite
              end
            Else
              begin
                Brush.Color:=Color;
                Font.Color:=clBlack
              end;
         FillRect(Rect);
         TextRect(Rect,Rect.Left,Rect.Top,Items[Index])
       end
end;

initialization
  {$IFDEF FPC}
  {$i Tran.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.

