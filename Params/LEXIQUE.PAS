{     Lexical Analyser      }
{ (C) 1997-2001 V.V.Pekunov }

{$B-}
Unit Lexique;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

Interface

Uses SysUtils, Graphics, Dialogs, Classes;

Const Space      = ' ';
      Tabulation = #9;
      HardSpace  = #160;

Const LeftBracket     = '(';
      RightBracket    = ')';
      LeftSqrBracket  = '[';
      RightSqrBracket = ']';
      LeftFBracket    = '{';
      RightFBracket   = '}';
      Comma           = ',';
      Colon           = ':';
      SemiColon       = ';';
      Equal           = '=';
      NonEqual        = '#';
      Pound           = '#';
      Point           = '.';
      Quote           = '''';
      Plus            = '+';
      Ampersand       = '&';
      SpecSymbol      = '@';
      Percent         = '%';
      QuestSymbol     = '?';
      Dollar          = '$';
      Slash           = '/';
      Dash            = '-';
      Underscore      = '_';
      Pipe            = '|';
      AvrDash         = #150;
      LongDash        = #151;

Const CapitalSet    = ['A'..'Z'];
      NonCapitalSet = ['a'..'z'];
      LettersSet    = CapitalSet+NonCapitalSet;
      IntNumberSet  = ['0'..'9'];
      IdentSet      = LettersSet+IntNumberSet+['_'];
      NumberSet     = IntNumberSet+['.','E','e'];
      ChrOfList     = IntNumberSet+['.'];
      Dashes        = [Dash,AvrDash,LongDash];

Const RGBFunction:String[32] = 'RGB';

Const MaxLevel = 20;

Type TermSet    = Set Of Char;
     LevelIndex = Array[0..MaxLevel-1] Of Byte;
     TAnalyser = class(TObject)
                 S:String;
                 NumLine:Word;
                 Error:Boolean;
                 NonTerminals:TermSet;
                 Spaces:TermSet;
                 Constructor Create(Const NTrm,Spc:TermSet);
                 Procedure   SetParams(Const S1:String;NL:Word); Virtual;
                 Procedure   MakeError(Ss:String); virtual;
                 Procedure   MakeWarning(Ss:String); virtual;
                 Procedure   Expect(Const C:String);
                 Procedure   ExpectSet(Const C:TermSet);
                 Procedure   DelFirst;
                 Function    ContainsOnly(C:TermSet):Boolean;
                 Function    IsNext(C:Char):Boolean;
                 Function    IsNextIdent(C:String):Boolean;
                 Function    IsNextSet(C:TermSet):Boolean;
                 Function    DelChar(C:Char):Boolean;
                 Function    FindIdent:String;
                 Function    FindSequence(Const NTrm:TermSet):String;
                 Function    FindNumber:String;
                 Function    Check(C:Char):Boolean;
                 Function    CheckSet(Const C:TermSet):Boolean;
                 Function    CheckIdent(Const C:String):Boolean;
                 Function    Empty:Boolean;
                 Function    GetAll:String;
                 Function    GetSequence(Const NTrm:TermSet):String;
                 Function    GetIdent:String;
                 Function    GetBefore(DelSpc:Boolean;Term:TermSet):String;
                 Function    GetListItem(Term:TermSet):String;
                 Function    GetString(TermL,TermR:Char):String;
                 Function    GetColor(Var Clr:LongInt):Boolean;
                 Function    GetRGBPart(Var Clr:LongInt):Boolean;
                 Function    GetNumber(IntMode:Boolean; Var M:Real):Boolean;
                 Function    GetCheckNumber(IntMode:Boolean; Var M:Real):Boolean;
                 Function    GetCheckedNumber(IntMode:Boolean; Var M:Real;Min,Max:Real):Boolean;
                 Function    GetLevelIndex(Var Index:LevelIndex; Var Level:Byte):Boolean;
                 Procedure   DelSpaces;

                 Property    AnlzLine:String read S write S;
     End;

Function    UpStr(Const S:String):String;
Procedure   DeleteLeadingSymbols(Var S:String;Const Spaces:TermSet);
Procedure   StripSymbols(Var S:String;Const Spaces:TermSet);
Function    GetSymbolsBefore(Var S:String;Term:TermSet):String;
Function    TrimLastSymbol(Const S:String; Sym:Char):String;
Function    Explode(S:String; Const Delimiter:String):TStringList;
Function    Implode(S:TStrings; Const Delimiter:String):String;

Implementation

Function UpRuss(S:Char):Char;

Const Rus :String[33] ='АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
      Rus1:String[33] ='абвгдеёжзийклмнопрстуфхцчшщъыьэюя';

Var K:Byte;
Begin
     K:=Pos(S,Rus1);
     If K=0 Then UpRuss:=S
     Else UpRuss:=Rus[K]
End;

Function UpStr(Const S:String):String;

Var F:Integer;
begin
     SetLength(Result,Length(S));
     For F:=1 To Length(S) Do
         Result[F]:=UpRuss(UpCase(S[F]))
end;

Procedure DeleteLeadingSymbols(Var S:String;Const Spaces:TermSet);
Var K:Integer;
Begin
     K:=1;
     While (K<=Length(S)) And (S[K] In Spaces) Do Inc(K);
     If K>1 Then Delete(S,1,K-1)
End;

Procedure StripSymbols(Var S:String;Const Spaces:TermSet);

Var K:Integer;
Begin
     K:=1;
     While K<=Length(S) Do
       If S[K] In Spaces Then
          Delete(S,K,1)
       Else
          Inc(K)
End;

Function  GetSymbolsBefore(Var S:String;Term:TermSet):String;
Var Count:Integer;
    K:Integer;
    Flag:Boolean;
Begin
     Count:=1;
     K:=Length(S);
     Flag:=False;
     While (Count<=K) And Not Flag Do
       Begin
         Flag := S[Count] In Term;
         If Not Flag Then Inc(Count)
       End;
     GetSymbolsBefore:=Copy(S,1,Count-1);
     Delete(S,1,Count-1)
End;

Function    TrimLastSymbol(Const S:String; Sym:Char):String;
begin
     Result:=TrimRight(S);
     If Length(S)>0 Then
        If S[Length(S)]=Sym Then
           Delete(Result,Length(S),1)
end;

Function    Explode(S:String; Const Delimiter:String):TStringList;

Var S1:Integer;
begin
     Result:=TStringList.Create;
     With Result Do
       While Length(S)>0 Do
         begin
           S1:=Pos(Delimiter,S);
           If S1>0 Then
              begin
                Add(Copy(S,1,S1-1));
                System.Delete(S,1,Length(Delimiter)+S1-1)
              end
           Else
              begin
                Add(S);
                S:=''
              end
         end
end;

Function    Implode(S:TStrings; Const Delimiter:String):String;

Var F:Integer;
begin
     If S.Count=0 Then
        Result:=''
     Else
       begin
         Result:=S.Strings[0];
         For F:=1 To S.Count-1 Do
           Result:=Result+Delimiter+S.Strings[F]
       end
end;

Constructor TAnalyser.Create(Const NTrm,Spc:TermSet);
Begin
     Inherited Create;
     S:='';
     NumLine:=0;
     Error:=False;
     NonTerminals:=NTrm;
     Spaces:=Spc
End;

Procedure TAnalyser.SetParams(Const S1:String;NL:Word);
Begin
     S:=S1;
     NumLine:=NL;
     Error:=False;
     DelSpaces
End;

Procedure TAnalyser.MakeError(Ss:String);
Begin
     If NumLine>0 Then Ss:=Ss+' в строке '+IntToStr(NumLine);
     MessageDlg(Ss,mtError,[mbOk],0);
     Error:=True
End;

Procedure TAnalyser.MakeWarning(Ss:String);
Begin
     If NumLine>0 Then Ss:=Ss+' в строке '+IntToStr(NumLine);
     MessageDlg(Ss,mtWarning,[mbOk],0)
End;

Function  TAnalyser.GetAll:String;
Begin
     GetAll:=S;
     S:=''
End;

Function  TAnalyser.Empty:Boolean;
Begin
     DelSpaces;
     Empty:=S=''
End;

Procedure TAnalyser.Expect(Const C:String);
Begin
     MakeError('"'+C+'" ожидается')
End;

Procedure TAnalyser.ExpectSet(Const C:TermSet);

Var F:Char;
    Msg:Char;
Begin
     Msg:=' ';
     For F:=Low(Char) To High(Char) Do
         If F In C Then
            Begin
              Msg:=F;
              Break
            End;
     MakeError('"'+Msg+'" ожидается')
End;

Procedure TAnalyser.DelFirst;
Begin
     Delete(S,1,1);
     DelSpaces
End;

Function  TAnalyser.ContainsOnly(C:TermSet):Boolean;
Var F:Integer;
Begin
     Result:=False;
     For F:=1 To Length(S) Do
         If Not (S[F] In C) Then
            Exit;
     Result:=True
End;

Function  TAnalyser.IsNext(C:Char):Boolean;
Begin
     DelSpaces;
     IsNext:=(Length(S)>0) And (S[1]=C)
End;

Function  TAnalyser.IsNextIdent(C:String):Boolean;
Begin
     IsNextIdent:=(Length(S)>0) And (FindIdent=C)
End;

Function  TAnalyser.IsNextSet(C:TermSet):Boolean;
Begin
     DelSpaces;
     IsNextSet:=(Length(S)>0) And (S[1] In C)
End;

Function  TAnalyser.DelChar(C:Char):Boolean;
Begin
     Result:=(Length(S)>0) And (S[1]=C);
     If Result Then
        Delete(S,1,1)
End;

Function  TAnalyser.FindIdent:String;
Begin
     FindIdent:=FindSequence(NonTerminals)
End;

Function  TAnalyser.FindNumber:String;
begin
     FindNumber:=FindSequence(NumberSet)
end;

Function  TAnalyser.FindSequence(Const NTrm:TermSet):String;
Var Count,K:Integer;
    Flag:Boolean;
    T:Char;
Begin
     DelSpaces;
     Count:=1;
     K:=Length(S);
     Flag:=True;
     While (Count<=K) And Flag Do
       Begin
         T:=S[Count];
         Flag:=T In NTrm;
         If Flag Then
            Begin
              S[Count]:=UpRuss(UpCase(T));
              Inc(Count)
            End
       End;
     FindSequence:=Copy(S,1,Count-1)
End;

Function  TAnalyser.Check(C:Char):Boolean;
Begin
     If Not Error Then
        Begin
          DelSpaces;
          If Empty Or (S[1]<>C) Then Expect(C);
          Delete(S,1,1)
        End;
     Check:=Not Error
End;

Function  TAnalyser.CheckSet(Const C:TermSet):Boolean;
Begin
     If Not Error Then
        Begin
          DelSpaces;
          If Empty Or Not (S[1] In C) Then ExpectSet(C);
          Delete(S,1,1)
        End;
     CheckSet:=Not Error
End;

Function  TAnalyser.CheckIdent(Const C:String):Boolean;
begin
     If GetIdent<>C Then
        Expect(C);
     CheckIdent:=Not Error
end;

Procedure TAnalyser.DelSpaces;
Begin
     DeleteLeadingSymbols(S,Spaces)
End;

Function  TAnalyser.GetSequence(Const NTrm:TermSet):String;
begin
     GetSequence:=FindSequence(NTrm);
     Delete(S,1,Length(Result))
end;

Function  TAnalyser.GetIdent:String;
Begin
     Result:=FindIdent;
     Delete(S,1,Length(Result))
End;

Function  TAnalyser.GetBefore(DelSpc:Boolean;Term:TermSet):String;
Begin
     If DelSpc Then DelSpaces;
     GetBefore:=GetSymbolsBefore(S,Term)
End;

Function  TAnalyser.GetListItem(Term:TermSet):String;
Begin
     GetListItem:=GetBefore(True,Term);
     If Not Empty Then CheckSet(Term)
End;

Function  TAnalyser.GetString(TermL,TermR:Char):String;
Begin
     Check(TermL);
     If Error Then GetString:=''
     Else
       Begin
         GetString:=GetBefore(False,[TermR]);
         Check(TermR)
       End
End;

Function  TAnalyser.GetNumber(IntMode:Boolean; Var M:Real):Boolean;
Var R:String;
    K:Integer;
Begin
     If IntMode Then
        R:=GetSequence(IntNumberSet)
     Else
        R:=GetSequence(NumberSet);
     Val(R,M,K);
     If K<>0 Then S:=R+S;
     GetNumber:=K=0
End;

Function TAnalyser.GetColor(Var Clr:LongInt):Boolean;

Var ID:String;
Begin
     ID:=GetIdent;
     If ID=RGBFunction Then GetColor:=GetRGBPart(Clr)
     Else
       Begin
         Result:=IdentToColor(ID,Clr);
         If Not Result Then
            MakeError('Некорректный идентификатор цвета "'+ID+'"')
       End
End;

Function TAnalyser.GetRGBPart(Var Clr:LongInt):Boolean;

Var R,G,B:Real;
Begin
     If Check(LeftBracket) And
        GetCheckedNumber(True,R,0.0,255.0) And
        Check(Comma) And
        GetCheckedNumber(True,G,0.0,255.0) And
        Check(Comma) And
        GetCheckedNumber(True,B,0.0,255.0) And
        Check(RightBracket) Then
        Begin
          Clr:=$02000000 Or (Round(B) Shl 16) Or (Round(G) Shl 8) Or (Round(R))
        End;
     Result:=Not Error
End;

Function TAnalyser.GetCheckNumber(IntMode:Boolean; Var M:Real):Boolean;
Begin
     Result:=GetNumber(IntMode,M);
     If Not Result Then
        MakeError('Некорректная запись числа')
End;

Function TAnalyser.GetCheckedNumber(IntMode:Boolean; Var M:Real;Min,Max:Real):Boolean;
begin
     If GetCheckNumber(IntMode,M) Then
        begin
          If (M<Min) Or (M>Max) Then
             MakeError('Число вне диапазона ['+
                       FloatToStrF(Min,ffGeneral,5,4)+';'+
                       FloatToStrF(Max,ffGeneral,5,4)+']')
        end;
     Result:=Not Error
end;

Function TAnalyser.GetLevelIndex(Var Index:LevelIndex; Var Level:Byte):Boolean;

Var PointFlag: Boolean;
    ContinueFlag: Boolean;
    M:Real;
begin
     Result:=True;

     DelSpaces;
     Level:=0;
     Repeat
       ContinueFlag:=True;
       If GetCheckNumber(True,M) Then
          If (M<1.0) Or (M>High(Byte)) Then
             begin
               MakeError('Индекс уровня вне диапазона [1..'+IntToStr(High(Byte))+']');
               Result:=False
             end
          Else
             begin
               Index[Level]:=Round(M);
               Inc(Level);
               PointFlag:=DelChar(Point);
               If (Length(S)=0) Or Not (S[1] In ChrOfList) Then
                  ContinueFlag:=False
               Else
                  If Not PointFlag Then
                     begin
                       Expect(Point);
                       Result:=False
                     end
             end
       Else
          ContinueFlag:=False
     Until Not (Result And ContinueFlag);
     If Level=0 Then
        begin
          Expect('Индекс');
          Result:=False
        end
end;

End.

