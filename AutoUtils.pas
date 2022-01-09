unit AutoUtils;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

Uses Elements, Common{$IF DEFINED(LCL) OR DEFINED(VCL)}, Dialogs{$ENDIF}, Process;

function RunExtCommand(Const App,Prm,OutFName,SignalStr:String; Const WaitFile: String = ''):String;

Procedure CreateStrFile(Const FName,Content: String);

Function FindElementRegByID(Const ClassID: String): TElementReg;

function ElementIs(Ref:TElementReg; Const IsClsID:String): Boolean;

function ExistClass(Const ClsID:String):Boolean;

function  RegisterElement(Const PClsID, ClsID, Nm, Scrpt, iScrpt, sScrpt, Img:String;
     Inh:Boolean; Const Prms: StringArray):TElementReg;

procedure RegisterContact(Const ClsID:String; Const CntID, Name:String;
     Req:Boolean; Dir:TIODirection; CT:TContactType);

procedure RegisterLinkType(Const OutClsID, OutContID, InClsID, InContID:String);

function GenerateText(Const Pattern:String; Vals: Array Of Const): String;

function EncodeStr(Const S:String):String;
function DecodeStr(Const S:String):String;

procedure MakeErrorCommon(Const Msg: String);
procedure MakeInfoCommon(Const Msg: String);

Const ElementRegList: TObjList = Nil;
      ContactRegList: TObjList = Nil;
      LinkRegList: TObjList = Nil;

implementation

Uses SysUtils, Classes{$IF DEFINED(LCL) OR DEFINED(VCL)}{$IFDEF FPC}, LCLIntf{$ENDIF}{$ENDIF};

Function FindElementRegByID(Const ClassID: String): TElementReg;

Var F: Integer;
begin
  For F:=0 To ElementRegList.Count-1 Do
      If TElementReg(ElementRegList[F]).ClsID = ClassID Then
         Exit(TElementReg(ElementRegList[F]));
  Result := Nil
end;

{$IFDEF FPC}

function EncodeStr(Const S:String):String;
Begin
     Result:=S
End;

function DecodeStr(Const S:String):String;
Begin
     Result:=S
End;

{$ELSE}
{ The part of the following code is excluded (with gratitude) from FreePascal
  sources and slightly modified by VP. }

function UnicodeToUtf8(Dest: PChar; MaxDestBytes: Integer; Source: PWideChar; SourceChars: Integer): Integer;
  var
    i,j : Integer;
    w : word;
  begin
    result:=0;
    if source=nil then
      exit;
    i:=0;
    j:=0;
    if assigned(Dest) then
      begin
        while (i<SourceChars) and (j<MaxDestBytes) do
          begin
            w:=word(Source[i]);
            case w of
              0..$7f:
                begin
                  Dest[j]:=char(w);
                  inc(j);
                end;
              $80..$7ff:
                begin
                  if j+1>=MaxDestBytes then
                    break;
                  Dest[j]:=char($c0 or (w shr 6));
                  Dest[j+1]:=char($80 or (w and $3f));
                  inc(j,2);
                end;
              else
                begin
                    if j+2>=MaxDestBytes then
                      break;
                    Dest[j]:=char($e0 or (w shr 12));
                    Dest[j+1]:=char($80 or ((w shr 6)and $3f));
                    Dest[j+2]:=char($80 or (w and $3f));
                    inc(j,3);
                end;
            end;
            inc(i);
          end;

        if j>MaxDestBytes-1 then
          j:=MaxDestBytes-1;

        Dest[j]:=#0;
      end
    else
      begin
        while i<SourceChars do
          begin
            case word(Source[i]) of
              $0..$7f:
                inc(j);
              $80..$7ff:
                inc(j,2);
              else
                inc(j,3);
            end;
            inc(i);
          end;
      end;
    result:=j+1;
  end;

function Utf8ToUnicode(Dest: PWideChar; MaxDestChars: Integer; Source: PChar; SourceBytes: Integer): Integer;

var
  i,j,mask : Integer;
  w : Integer;
  b : byte;
begin
  if not assigned(Source) then
  begin
    result:=0;
    exit;
  end;
  result:=Integer(-1);
  i:=0;
  j:=0;
  if assigned(Dest) then
    begin
      while (j<MaxDestChars) and (i<SourceBytes) do
        begin
          b:=byte(Source[i]);
          w:=b;
          inc(i);
          if b>=$80 then
            begin
              w:=b and $3f;
              if i>=SourceBytes then
                exit;
              mask:=$C0;
              while (mask>1) and ((b and mask)=mask) do
                begin
                  if (byte(Source[i]) and $c0)<>$80 then
                     exit;
                  w:=(w shl 6) or (byte(Source[i]) and $3f);
                  mask:=mask shr 1;
                  inc(i)
                end
            end;
          Dest[j]:=WideChar(w);
          inc(j);
        end;
      if j>=MaxDestChars then
         j:=MaxDestChars-1;
      Dest[j]:=#0;
    end
  else
    begin
      while i<SourceBytes do
        begin
          b:=byte(Source[i]);
          inc(i);
          if b>=$80 then
            begin
              if i>=SourceBytes then
                exit;
              mask:=$c0;
              while (mask>1) and ((b and mask)=mask) do
                begin
                  if (byte(Source[i]) and $c0)<>$80 then
                     exit;
                  mask:=mask shr 1;
                  inc(i)
                end
            end;
          inc(j)
        end;
    end;
  result:=j+1;
end;

function EncodeStr(Const S:String):String;

Var Buf:PWideChar;
    Len:Integer;
Begin
     Buf:=AllocMem((Length(S)+1)*2);
     StringToWideChar(S,Buf,Length(S)+1);
     Len:=UnicodeToUtf8(Nil,0,Buf,Length(S));
     If Len<1 Then
        Result:=S
     Else
        Begin
          SetLength(Result,Len);
          UnicodeToUtf8(PChar(Result),Len,Buf,Length(S));
          Delete(Result,Length(Result),1)
        End;
     FreeMem(Buf)
End;

function DecodeStr(Const S:String):String;

Var Len:Integer;
    Buf:PWideChar;
Begin
     Len:=Utf8ToUnicode(Nil,0,PChar(S),Length(S));
     If Len<1 Then
        Result:=S
     Else
        Begin
          Buf:=AllocMem((Len+1)*2);
          Utf8ToUnicode(Buf,Len,PChar(S),Length(S));
          Result:=WideCharToString(Buf);
          FreeMem(Buf)
        End
End;

{$ENDIF}

function RunExtCommand(Const App,Prm,OutFName,SignalStr:String; Const WaitFile: String = ''):String;

Var AProcess: TProcess;
    P:Integer;
begin
     AProcess := TProcess.Create(nil);
     AProcess.CommandLine := App + ' ' + Prm;
     If Length(WaitFile) = 0 Then
       AProcess.Options := AProcess.Options + [poWaitOnExit]
     Else
       DeleteFile(WaitFile);
     AProcess.Execute;
     AProcess.Free;

     While (Length(WaitFile) > 0) And Not FileExists(WaitFile) Do
        Sleep(100);

     Result:='';
     If (Length(OutFName)>0) And FileExists(OutFName) Then
        With TStringList.Create Do
          begin
            LoadFromFile(OutFName);
            Result:=DecodeStr(Text);
            Free
          end
     Else
        Result:='';
     P:=Pos(SignalStr,Result);
     If P>0 Then Delete(Result,1,P+Length(SignalStr)-1)
end;

Procedure CreateStrFile(Const FName,Content: String);

Var F:TextFile;
begin
     AssignFile(F,FName);
     Rewrite(F);
     Write(F,Content);
     CloseFile(F)
end;

function ElementIs(Ref:TElementReg; Const IsClsID:String): Boolean;
begin
     Result:=False;
     While Assigned(Ref) And Not Result Do
       If Ref.ClsID=IsClsID Then
          Result:=True
       Else
          Ref:=Ref.Parent;
end;

function ExistClass(Const ClsID:String):Boolean;

Var F:Integer;
begin
     Result:=True;
     For F:=0 To ElementRegList.Count-1 Do
       If TElementReg(ElementRegList[F]).ClsID=ClsID Then
          Exit;
     Result:=False
end;

function RegisterElement(Const PClsID, ClsID, Nm, Scrpt, iScrpt, sScrpt, Img:String; Inh:Boolean;
   Const Prms:StringArray):TElementReg;
begin
     If Not Assigned(ElementRegList) Then
        ElementRegList:=TObjList.Create;
     Result:=TElementReg.Create(PClsID,ClsID,Nm,Scrpt,iScrpt,sScrpt,Img,Inh,Prms);
     ElementRegList.Add(Result)
end;

procedure RegisterContact(Const ClsID:String; Const CntID, Name:String;
     Req:Boolean; Dir:TIODirection; CT:TContactType);
begin
     If Not Assigned(ContactRegList) Then
        ContactRegList:=TObjList.Create;
     ContactRegList.Add(TContactReg.Create(ClsID,CntID,Name,Req,Dir,CT))
end;

procedure RegisterLinkType(Const OutClsID, OutContID, InClsID, InContID:String);
begin
     If Not Assigned(LinkRegList) Then
        LinkRegList:=TObjList.Create;
     LinkRegList.Add(TLinkReg.Create(OutClsID,OutContID,InClsID,InContID))
end;

function GenerateText(Const Pattern:String; Vals: Array Of Const): String;

Var F:Integer;
    S:String;
begin
     Result:=Pattern;
     For F:=Low(Vals) To High(Vals) Do
       begin
         with Vals[F] do
           case VType of
             vtInteger:    S := IntToStr(VInteger);
             vtChar:       S := VChar;
             vtExtended:   S := FloatToStr(VExtended^);

             vtString:     S := VString^;
             vtPChar:      S := VPChar;
             vtAnsiString: S := string(VAnsiString);
             vtVariant:    S := string(VVariant^);
             vtInt64:      S := IntToStr(VInt64^);
           end;
         Result:=StringReplace(Result,Format('$[%d]',[F]),S,[rfReplaceAll])
       end
end;

procedure MakeErrorCommon(const Msg: String);
begin
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     MessageDlg(Msg,mtError,[mbOk],0);
     {$ELSE}
     WriteLn(Msg);
     {$ENDIF}
end;


procedure MakeInfoCommon(const Msg: String);
begin
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     MessageDlg(Msg, mtInformation,[mbOk],0);
     {$ELSE}
     WriteLn(Msg);
     {$ENDIF}
end;

Initialization

Finalization
     ElementRegList.Free;
     ContactRegList.Free;
     LinkRegList.Free
end.
