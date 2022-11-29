program lparams;

{$IF (NOT DEFINED(UNIX)) AND (NOT DEFINED(LINUX))}
{$APPTYPE CONSOLE}
{$ENDIF}
{$H+}
{$CODEPAGE UTF8}

{$MODE Objfpc}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Classes, StrUtils, SysUtils;

Var FIN, FOUT: TStringList;
    ID, DESC, DEF, S: String;
    F, P: Integer;
begin
  SetMultiByteConversionCodePage(CP_UTF8);
  SetMultiByteRTLFileSystemCodePage(CP_UTF8);
  If ParamCount < 2 Then
     WriteLn('Usage: lparams <cfg_file> <out_file>')
  Else
     Begin
       FIN := TStringList.Create;
       FIN.LoadFromFile(ParamStr(1));
       FOUT := TStringList.Create;
       F := 0;
       While F < FIN.Count Do
         Begin
           ID := FIN.Strings[F];
           DESC := FIN.Strings[F+1];
           DEF := FIN.Strings[F+2];
           Write(ID, ' ');
           If (Length(DESC) > 0) And (DESC[Length(DESC)] = '''') Then
              Begin
                Delete(DESC, Length(DESC), 1);
                P := RPos('''', DESC);
                If P > 0 Then
                   Write('(', Copy(DESC, P+1, 1024), ') ')
              End;
           Write('[', DEF, '] = ');
           ReadLn(S);
           If Length(S) = 0 Then
              FOUT.Add(DEF)
           Else
              FOUT.Add(S);
           Inc(F, 3)
         End;
       FIN.Free;
       FOUT.SaveToFile(ParamStr(2));
       FOUT.Free
     End
end.

