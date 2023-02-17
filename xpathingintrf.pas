unit xpathingIntrf;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$CODEPAGE UTF8}

interface

uses
  Classes, SysUtils, xpath, dynlibs;

Type CreateSysFun = function:Pointer; cdecl;
     ExistClassFun = function(Const ClsID: PChar):Boolean; cdecl;
     GetElementFun = function(Sys: Pointer; ID: PChar):Pointer; cdecl;
     CanReachFun = function(Sys: Pointer; _From: Pointer; nTo: Integer; _To: PPointerList): Boolean; cdecl;
     CreateContactsFun = procedure(ClassID: PChar; _Dir: Integer; dom: Pointer; Parent: Pointer; Tag: PChar); cdecl;
     AddElementFun = function(Sys: Pointer; ClassName, ID : PChar; Flags: Integer):Pointer; cdecl;
     AddLinkFun = function(Sys, El: Pointer; ContID: PChar; PEl: Pointer; PContID: PChar; Var S: PChar; Info: Boolean):Pointer; cdecl;
     AnalyzeLinkStatusIsInformFun = function(sys, L: Pointer): Boolean; cdecl;
     SetParameterIfExistsFun = procedure(el: Pointer; PrmName, PrmValue: PChar); cdecl;
     MoveFun = procedure(el: Pointer; X, Y: Integer); cdecl;
     CheckSysFun = function(Sys: Pointer): Integer; cdecl;
     ToStringFun = procedure(Sys: Pointer; Ret: PChar); cdecl;
     GenerateCodeFun = procedure(Sys: Pointer; Ret: PChar); cdecl;
     SaveToXMLFun = procedure(Sys: Pointer; FName: PChar); cdecl;
     _FreeFun = procedure(Obj: Pointer); cdecl;

Var XPathInduct: function(
   _Messaging: Boolean;
   CreateSysF: CreateSysFun;
   ExistClassF: ExistClassFun;
   GetElementF: GetElementFun;
   CanReachF: CanReachFun;
   CreateContactsF: CreateContactsFun;
   AddElementF: AddElementFun;
   AddLinkF: AddLinkFun;
   AnalyzeLinkStatusIsInformF: AnalyzeLinkStatusIsInformFun;
   SetParameterIfExistsF: SetParameterIfExistsFun;
   MoveF: MoveFun;
   CheckSysF: CheckSysFun;
   ToStringF: ToStringFun;
   GenerateCodeF: GenerateCodeFun;
   SaveToXMLF: SaveToXMLFun;
   _FreeF: _FreeFun;
   NodeNameTesterF: TXPathNodeNameTester;
   SelectedMode: PChar;
   UseNNet: Boolean; MainLineAllowed: Boolean;
   _ENV: Pointer;
   inENV, outENV: PChar;
   InXML, OutXML: PChar;
   MaxCPUs: Integer;
   _IDs: PChar;
   OnlyInduceModel: Boolean): Boolean; cdecl;

Var CompileXPathing: function(_Messaging: Boolean;
   _AllowedVersions: PChar;
   FName: PChar; _ENV: Pointer; inENV, outENV: PChar;
   _WorkText: PChar): Boolean; cdecl;

Var SetInterval: procedure(_Interval: Cardinal); cdecl;

Var ClearRestrictions: procedure; cdecl;

Var ClearRuler: procedure; cdecl;

Var SetDeduceLogFile: procedure(LF: PChar); cdecl;

Var CreateDOMContact: procedure(dom: Pointer; Parent: Pointer; Tag: PChar; CntID: PChar); cdecl;

Var GetMSG: function: PChar;

implementation

Var Handle: TLibHandle;

Initialization
  Handle := LoadLibrary({$IF DEFINED(UNIX) OR DEFINED(LINUX)}'./libxpathInduct.'{$ELSE}'xpathInduct.'{$ENDIF} + SharedSuffix);
  If Handle <> NilHandle Then
     Begin
       XPathInduct := GetProcedureAddress(Handle, 'XPathInduct');
       CompileXPathing := GetProcedureAddress(Handle, 'CompileXPathing');
       SetInterval := GetProcedureAddress(Handle, 'SetInterval');
       ClearRestrictions := GetProcedureAddress(Handle, 'ClearRestrictions');
       ClearRuler := GetProcedureAddress(Handle, 'ClearRuler');
       SetDeduceLogFile := GetProcedureAddress(Handle, 'SetDeduceLogFile');
       CreateDOMContact := GetProcedureAddress(Handle, 'CreateDOMContact');
       GetMSG := GetProcedureAddress(Handle, 'GetMSG')
     End
  Else
     Exit;

Finalization
  If Handle <> NilHandle Then
     FreeLibrary(Handle);

end.

