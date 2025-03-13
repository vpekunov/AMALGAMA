unit LocalIP;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF}
  {$IFDEF linux}Sockets, {$ELSE}Winsock, {$ENDIF}Process, Forms, Dialogs,
  SysUtils, Classes, Common;

function getLocalIP: string;

implementation

{$IFNDEF linux}
function getLocalIP: string;
Var HostName: Array[0..255] Of Char;
    Info:PHostEnt;
begin
     Result:='127.0.0.1';
     If gethostname(@HostName,256)<>0 Then
        MessageDlg('Невозможно определить имя машины. Socket Error = '+IntToStr(WSAGetLastError),mtError,[mbOk],0)
     Else
        begin
          Info:=gethostbyname(HostName);
          If Assigned(Info) Then
             begin
               With Info^ Do
                  Result:=IntToStr(Ord(h_addr^[0]))+'.'+
                          IntToStr(Ord(h_addr^[1]))+'.'+
                          IntToStr(Ord(h_addr^[2]))+'.'+
                          IntToStr(Ord(h_addr^[3]));
             end
          Else
             MessageDlg('Невозможно определить IP - адрес машины. Socket Error = '+IntToStr(WSAGetLastError),mtError,[mbOk],0);
        end
end;
{$ELSE}
function getLocalIP: string;
var re: TStringList;
    space: Integer;
begin
 RunExtCommand('hostname','-I >_host.txt','');
 try
   re := TStringList.Create;
   re.LoadFromFile('_host.txt');
   Result := re.Strings[0];
   space := Pos(' ', Result);
   if space > 0 Then
      Result := Copy(Result, 1, space - 1);
 finally
   re.Free;
 end;
end;
{$ENDIF}

end.

