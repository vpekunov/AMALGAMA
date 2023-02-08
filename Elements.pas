{ надо решить вопрос о типе -- со всеми размерностями или нет. Malloc или статически }
{ проверка соответствия размерностей, типов. Или один тип для всего ? }
{ создание и редактирование классов }
{ подключение языков }

unit Elements;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$CODEPAGE UTF8}

interface

Uses {$IF DEFINED(LCL) OR DEFINED(VCL)}Forms, Graphics, Controls, ComCtrls, ExtCtrls, Dialogs{$IFNDEF FPC}, Jpeg{$ENDIF},{$ENDIF}
     Variants, Classes, MetaComp, Regexpr, xpath, dom, xmlread, Common, AutoConsts;

Const Eps = 0.1;

Const ClassesDir   = SuperSlash+'Classes';
      IniFile      = SuperSlash+'Class.ini';
      InductFile   = SuperSlash+'induct.ini';
      XPathFile    = SuperSlash+'induct.im';
      LogFile      = SuperSlash+'induct.log';
      safeXPathFile = '''+SuperSlash+''induct.im';
      safeLogFile   = '''+SuperSlash+''induct.log';
      MacroFile    = SuperSlash+'induct.mac';
      ScrFile      = SuperSlash+'Script.php3';
      dInitFile    = SuperSlash+'Init.pl';
      dSolveFile   = SuperSlash+'Solve.pl';
      ImgFile      = SuperSlash+'Image.jpg';
      SectionDef   = 'Definition';
      SectionPrms  = 'Parameters';
      ScriptToLoad = '#';
      RefToLoad    = '@';

      mdfLock      = 'LOCK';
      mdfHide      = 'HIDE';
      mdfRequired  = 'REQUIRED';
      mdfUnique    = 'UNIQUE';

      prmList      = 'LIST';
      prmSelector  = 'SELECTOR';
      prmInput     = 'INPUT';
      prmText      = 'TEXT';

      xpfRandom    = 'random';
      xpfRandomID  = 'randomid';

      xpText       = 'InnerDoc';

      TempXML      = '__temp.xml';

Type
  TElementReg = class;

  TParameter = class
    Name, DefValue: String;
    Caption: String;
    Definer: TElementReg;
    Selector: TStringList;
    Conjunctor: String;
    Multiline: Boolean;
    Redefined: Boolean;
    Locked: Boolean;
    Hidden: Boolean;
    Unique: Boolean;
    Required: Boolean;

    destructor Destroy; override;
  End;

  ParamArray = Array Of TParameter;

  StringArray = Array Of String;

  TContactState = (cstNormal,cstFrom,cstTo);

  TDataTypes = (dtChar, dtInt, dtLongInt, dtLongLongInt, dtFloat, dtDouble, dtLongDouble);

  TContactType = (ctSingle,ctMany);

  TLine = Record
    X1,Y1,X2,Y2: Integer
  End;
  TLines  = Array Of TLine;
  TPoints = Array Of TPoint;

  TElement = class;

  TElementRegs = Array Of TElementReg;

  { TElementReg }

  TElementReg = class
  private
    procedure SetScript(AValue: String);
    procedure SetUsed(const Value: Boolean);
    function GetScript: String;
    {$IF DEFINED(LCL) OR DEFINED(VCL)}
    function GetImage: TImage;
    {$ENDIF}
    function GetiScript: String;
    function GetsScript: String;
    procedure OpenScript(Const DefaultName:String; var Result, pName: String);
  public
     Parent:       TElementReg;
     ClsID:        String; { Идентификатор типа элемента }
     Name:         String; { Отображаемое название типа }
     iPredicate:   String;
     sPredicate:   String;
     FScript:      String;
     FStoredPath:  String;
     FiScript:     String;
     FsScript:     String;
     FImgPath:     String;
     FStoredPrms:  StringArray;
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     FImage:       TImage;
     {$ENDIF}
     Inherit:      Boolean;
     Params:       ParamArray;
     Generated:    Boolean;
     FUsed:        Boolean;

     constructor Create(Const PCID, CID, Nm, Scrpt, iScrpt, sScrpt, Img:String; Inh:Boolean;
                        Const NewPrms:StringArray);

     function   ProducePrms(Prolog:Boolean; Var Code:String; _Dir:TIODirection;
                    Const Prepend:String; DummyPrologVars:Boolean = False):Boolean;

     function   GeneratePHP(Var Code:String):Boolean;
     function   GenerateProlog(Var Code:String):Boolean;
     procedure  CollectParams(Var Prms: ParamArray);

     function   AddMacro(XPathing: Boolean; m: MetaCompiler): ScanMacro;

     destructor Destroy; override;

     function GetInductSeq(Var Continuous: Boolean; ENV: TXPathEnvironment): TElementRegs;

     function GetBasePath: String;

     property   Used:Boolean read FUsed write SetUsed;
     property   Script:String read GetScript write SetScript;
     property   iScript:String read GetiScript write FiScript;
     property   sScript:String read GetsScript write FsScript;
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     property   Image:TImage read GetImage;
     {$ENDIF}
  End;

  TContactReg = class
     ClsID: String;
     CntID: String;
     Name:  String;
     Req:   Boolean;
     Dir:   TIODirection;
     CType: TContactType;

     constructor Create(Const _ClsID, _CntID, _Name:String;
                        _Req:Boolean; _Dir:TIODirection; _CType:TContactType);
  End;

  TLinkReg = class
     OutClsID:  String;
     OutContID: String;
     InClsID:   String;
     InContID:  String;
     constructor Create(Const _OutClsID, _OutContID, _InClsID, _InContID:String);
  End;

  TGraphicObject = class
  private
    R:   TRect;
  public
    Constructor Create(_R:TRect);

    procedure   SetPosition(_X,_Y,_EX,_EY:Integer);
    procedure   Move(_X,_Y:Integer);
    function    CheckPoint(X,Y,WX,WY:Integer):Boolean; virtual;
    procedure   Draw(WX,WY:Integer); virtual; abstract;
  End;

  TContact = class(TGraphicObject)
  public
    Name:  String; { Отображаемое имя }
    Owner: TElement;
    Links: TObjList;
    Ref:   TContactReg;
    State: TContactState;

    External:   Boolean;
    PublicID:   String;
    PublicName: String;

    MapFrom: TContact;
    MapTo:   TContact;

    constructor Create(Const NM:String; Own:TElement; _Ref:TContactReg);

    {$IF DEFINED(LCL) OR DEFINED(VCL)}
    procedure   Draw(WX,WY:Integer); override;
    {$ENDIF}
    function    CheckPoint(X,Y,WX,WY:Integer):Boolean; override;

    destructor  Destroy; override;
  End;

  TLink = class
    _From, _To: TContact;
    Points: TPoints;
    Inform: Boolean;
    {$IF DEFINED(LCL) OR DEFINED(VCL)}
    Color: TColor;
    {$ENDIF}

    constructor Create(__From, __To: TContact; _Inform:Boolean);

    procedure ReadData(Var S:File);
    procedure WriteData(Var S:File);

    procedure   GetLine(Var Line:TLines);
    function    CheckPoint(X,Y,WX,WY:Integer; Var InPoint, InSegm:Integer):Boolean;

    destructor  Destroy; override;
  private
    procedure ReadDataXML(Lnk: TDOMElement);
  End;

  TSystem = class;

  TElement = class(TGraphicObject)
  private
    function GetInputContact(ID: String): TContact;
    function GetOutputContact(ID: String): TContact;
  public
    Ident:       String; { Идентификатор в PHP-программе }
    IdPermanent: Boolean;
    Ref:         TElementReg;
    Inputs:      TObjStrList;
    Outputs:     TObjStrList;
    Parameters:  TStringList;

    SuperElement: TElement;
    SubElements:  TList;

    Flags:      Integer;

    constructor Create(_Ref:TElementReg; Const ID:String; Flgs:Integer);
    function    CheckPoint(X,Y,WX,WY:Integer):Boolean; override;

    function FindConnectedByType(Const ClsID:String; Dir:TIODirections):TList;

    procedure ReadData(Var S:File);
    procedure ReadDataXML(S: TDOMElement);
    procedure WriteData(Var S:File);
    procedure WriteDataXML(Var S:TextFile; Const Prefix:String);
    procedure WriteDataProlog(Var S:TextFile; Const Prefix:String);

    procedure ReadExtContactsXML(Dir:TIODirection; Ext:TObjStrList; S: TDOMElement);

    procedure HandleExtContact(Dir:TIODirection; Ext:TObjStrList; Const CntID,PubID,PubName:String);

    function  forw(C:TContact):TContact;
    function  CollectBackLinks(C:TContact):TList;

    function  LoadSubElements(Sys:TSystem):Boolean;
    procedure RemoveSubElements(Sys:TSystem);

    procedure ChangeSubIDs(Const OldID, NewID:String);

    procedure ClearFlags(ClearMask:Integer);
    procedure SetFlags(SetMask:Integer);
    function Check: TResultType;

    function AddContact(Const ID, Name:String; _Ref:TContactReg;
               Var ErrMsg:String):TContact;
    function GetPower: Integer;
    function GetInputPower: Integer;
    function GetOutputPower: Integer;

    function GeneratePredicates(Var Code, Init, Solve:String):Boolean;
    function GeneratePHPClasses(Var Code:String):Boolean;
    function GeneratePHPCalls(Var Code:String):Boolean;

    function  FindContact(X,Y,WX,WY:Integer):TContact;

    {$IF DEFINED(LCL) OR DEFINED(VCL)}
    procedure Draw(WX,WY:Integer); override;
    procedure DrawContacts(C:TObjStrList;WX,WY:Integer);
    {$ENDIF}
    procedure Deactivate(WX,WY:Integer);
    procedure ExcludeFromLine(Const L:TLines; Var L1:TLines);

    destructor Destroy; override;

    function ToString: String; override;

    property InputContact[ID:String]: TContact read GetInputContact;
    property OutputContact[ID:String]: TContact read GetOutputContact;

    property Area: TRect read R;
  End;

  { TSystem }

  TSystem = class
  private
    function GetElCounter: Integer;
    procedure BindMaps(Dir: TIODirection; C: TObjStrList;
      ObjByID: Boolean);
  protected
    FElCounter: Integer;
    FInitProlog: String;
    FSolveProlog: String;
  public
    Elements:  TObjList;
    SavedName: String;
    Success:   Boolean;
    Deductive: Boolean;

    constructor Create;
    constructor LoadFromFile(Var Lang:String; Const FName:String; ExtInps, ExtOuts:TObjStrList);
    function LoadFromModel(Var Lang:String; Const FName:String; ExtInps, ExtOuts:TObjStrList):Boolean;
    function LoadFromXML(Var Lang:String; Const FName:String; ExtInps, ExtOuts:TObjStrList):Boolean;

    procedure   SaveToFile(Const Lang, FName:String);
    procedure   SaveToModel(Const Lang, FName:String);
    procedure   SaveToXML(Const Lang, FName:String);
    procedure   SaveToProlog(Const Lang, FName:String);

    function  CheckPublicContactID(C:TContact; Const NewID:String):Boolean;

    function GetElement(const ID: String): TElement;

    function  AddElement(Const CID, ID:String; Flgs:Integer):TElement;
    function  AddLink(_From,_To: TContact; Var ErrMsg:String; Inf: Boolean = False):TLink;
    procedure AnalyzeLinkStatus(L: TLink);
    function  CheckID(El:TElement; Const ID:String):Boolean;
    function  CheckElementPrm(El:TElement; Prm:TParameter; Const Val:String):Boolean;
    procedure ClearFlags(ClearMask:Integer);
    procedure SetFlags(SetMask: Integer);
    function  Check: TResultType;
    function  GeneratePHP(Var Code:String):Boolean;
    function  GenerateProlog(Var Code:String):Boolean;
    function  MakeCascade(Flag:Integer; Var Parameter:String):TResultType;

    {$IF DEFINED(LCL) OR DEFINED(VCL)}
    procedure Draw(ExclLink:TLink; WX,WY:Integer);
    procedure DrawLink(DrawPoints:Boolean; L:TLink; WX,WY:Integer);
    {$ENDIF}
    function  FindElement(X,Y,WX,WY:Integer):TElement;
    function  FindLink(X,Y,WX,WY:Integer; Var InPoint,InSegm:Integer):TLink;
    procedure Activate(El:TElement; Cnt:TContact; WX,WY:Integer);
    procedure Deactivate(WX,WY:Integer);

    destructor Destroy; override;

    function ToString: String; override;

    property  ElCounter: Integer read GetElCounter;
    property  InitProlog: String read FInitProlog write FInitProlog;
    property  SolveProlog: String read FSolveProlog write FSolveProlog;
  End;

  procedure LoadClasses({$IF DEFINED(LCL) OR DEFINED(VCL)}V:TTreeView{$ENDIF});
  {$IF DEFINED(LCL) OR DEFINED(VCL)}
  procedure SetBufSize(W,H:Integer);
  {$ENDIF}

  function NodeNameTester(Const NodeName, NodeTestString: String): Boolean; cdecl;

  function CreateSysF:Pointer; cdecl;
  function ExistClassF(Const ClsID: PWideChar):Boolean; cdecl;
  function GetElementF(Sys: Pointer; ID: PWideChar):Pointer; cdecl;
  function CanReachF(Sys: Pointer; _From: Pointer; nTo: Integer; _To: PPointerList): Boolean; cdecl;
  procedure CreateContactsF(ClassID: PWideChar; _Dir: Integer; dom: Pointer; Parent: Pointer; Tag: PWideChar); cdecl;
  function AddElementF(Sys: Pointer; ClassName, ID : PWideChar; Flags: Integer):Pointer; cdecl;
  function AddLinkF(Sys, El: Pointer; ContID: PWideChar; PEl: Pointer; PContID: PWideChar; Var S: PWideChar; Info: Boolean):Pointer; cdecl;
  function AnalyzeLinkStatusIsInformF(sys, L: Pointer): Boolean; cdecl;
  procedure SetParameterIfExistsF(el: Pointer; PrmName, PrmValue: PWideChar); cdecl;
  procedure MoveF(el: Pointer; X, Y: Integer); cdecl;
  function CheckSysF(Sys: Pointer): Integer; cdecl;
  procedure ToStringF(Sys: Pointer; Ret: PWideChar); cdecl;
  procedure GenerateCodeF(Sys: Pointer; Ret: PWideChar); cdecl;
  procedure SaveToXMLF(Sys: Pointer; FName: PWideChar); cdecl;
  procedure _FreeF(Obj: Pointer); cdecl;

Var MainSys: TSystem;
    {$IF DEFINED(LCL) OR DEFINED(VCL)}Cnv: TCanvas;{$ENDIF}
    OutModelName: String;
    Versions: TStringList;

Const ProcessedObject:TObject = Nil;
      AllowCycles:Boolean = True;

Var ErrorMsg: Array[0..16384] Of Char = '';

implementation

Uses SysUtils, StrUtils, Math, IniFiles, AutoUtils, Lexique{$IFDEF FPC}, Types{$ENDIF},
     DateUtils, xpathingIntrf;

{$IF DEFINED(LCL) OR DEFINED(VCL)}
Var Buf: TBitmap;

procedure SetBufSize(W,H:Integer);
begin
     If W>Buf.Width Then Buf.Width:=W;
     If H>Buf.Height Then Buf.Height:=H
end;
{$ENDIF}

function CreateSysF:Pointer; cdecl;
Begin
   Result := TSystem.Create
end;

function ExistClassF(Const ClsID: PWideChar):Boolean; cdecl;
Begin
   Result := ExistClass(ClsID)
End;

function GetElementF(Sys: Pointer; ID: PWideChar):Pointer; cdecl;
Begin
   Result := TSystem(Sys).GetElement(ID)
End;

function CanReachF(Sys: Pointer; _From: Pointer; nTo: Integer; _To: PPointerList): Boolean; cdecl;
Begin
     Result := CanReach(TSystem(Sys), TElement(_From), nTo, _To)
End;

procedure CreateContactsF(ClassID: PWideChar; _Dir: Integer; dom: Pointer; Parent: Pointer; Tag: PWideChar); cdecl;
Begin
     CreateContacts(ClassID, TIODirection(_Dir), TXMLDocument(dom), TDOMElement(Parent), Tag)
End;

function AddElementF(Sys: Pointer; ClassName, ID : PWideChar; Flags: Integer):Pointer; cdecl;
Begin
     Result := TSystem(Sys).AddElement(ClassName, ID, Flags)
End;

function AddLinkF(Sys, El: Pointer; ContID: PWideChar; PEl: Pointer; PContID: PWideChar; Var S: PWideChar; Info: Boolean):Pointer; cdecl;

Const Str: PWideChar = 'Error!';

Var ErrMsg: String;
Begin
     Result := TSystem(Sys).AddLink(TElement(El).OutputContact[ContID], TElement(PEl).InputContact[PContID], ErrMsg, Info);
     If Length(ErrMsg) > 0 Then
        S := Str
     Else
        S := Nil
End;

function AnalyzeLinkStatusIsInformF(sys, L: Pointer): Boolean; cdecl;
Begin
     TSystem(sys).AnalyzeLinkStatus(TLink(L));
     Result := TLink(L).Inform
End;

procedure SetParameterIfExistsF(el: Pointer; PrmName, PrmValue: PWideChar); cdecl;

Var Obj: TElement Absolute el;
Begin
     If Obj.Parameters.IndexOfName(PrmName) >= 0 Then
        Obj.Parameters.Values[PrmName] := PrmValue;
End;

procedure MoveF(el: Pointer; X, Y: Integer); cdecl;
Begin
     TElement(el).Move(X, Y)
End;

function CheckSysF(Sys: Pointer): Integer; cdecl;
Begin
     Result := Integer(TSystem(Sys).Check)
End;

procedure ToStringF(Sys: Pointer; Ret: PWideChar); cdecl;
Begin
     StrPCopy(Ret, WideString(TSystem(Sys).ToString))
End;

procedure GenerateCodeF(Sys: Pointer; Ret: PWideChar); cdecl;

Var R: String;
Begin
     If TSystem(Sys).GeneratePHP(R) Then
        StrPCopy(Ret, WideString(R))
     Else
        StrPCopy(Ret, '')
End;

procedure SaveToXMLF(Sys: Pointer; FName: PWideChar); cdecl;
Begin
     TSystem(Sys).SaveToXML('', FName)
End;

procedure _FreeF(Obj: Pointer); cdecl;
Begin
     TObject(Obj).Free
end;

function getFirstChild(El: TDOMElement): TDOMElement;
begin
     If Not Assigned(El) Then
        Exit(Nil);

     Result := TDOMElement(El.FirstChild);
     While Assigned(Result) And (Result.NodeType <> ELEMENT_NODE) Do
       Result := TDOMElement(Result.NextSibling)
end;

function getNextChild(El: TDOMElement): TDOMElement;
begin
     If Not Assigned(El) Then
        Exit(Nil);

     Result := TDOMElement(El.NextSibling);
     While Assigned(Result) And (Result.NodeType <> ELEMENT_NODE) Do
        Result := TDOMElement(Result.NextSibling);
end;

function getFirst(Els: TDOMNodeList): TDOMElement;
begin
     If (Not Assigned(Els)) Or (Els.Count = 0) Then
        Exit(Nil);

     Result := TDOMElement(Els[0]);
end;

function NodeNameTester(Const NodeName, NodeTestString: String): Boolean; cdecl;

Var F: Integer;
    Found: Boolean;
Begin
     If (Copy(NodeTestString, 1, 3) = 'cls') And ExistClass(NodeTestString) Then
        Begin
          Found := False;
          For F := 0 To ElementRegList.Count - 1 Do
            If TElementReg(ElementRegList.Items[F]).ClsID = NodeName Then
              Begin
                Found := ElementIs(TElementReg(ElementRegList.Items[F]), NodeTestString);
                Break
              End;
          If Not Found Then Exit(False)
        End
     Else
        exit(False);
     Result := True
end;

function ReadStr(Var S:File):String;

Var L:Word;
begin
     BlockRead(S,L,SizeOf(L));
     SetLength(Result,L);
     If L>0 Then BlockRead(S,Result[1],L)
end;

procedure WriteStr(Var S:File; Const Str:String);

Var L:Word;
begin
     L:=Length(Str);
     BlockWrite(S,L,SizeOf(L));
     If L>0 Then BlockWrite(S,Str[1],L)
end;

function StringArrayOf(Strs: Array Of Const):StringArray;

Var F:Integer;
begin
     SetLength(Result,Length(Strs));
     For F:=Low(Strs) To High(Strs) Do
       With Strs[F] Do
         case VType of
           vtChar:       Result[F] := VChar;
           vtString:     Result[F] := VString^;
           vtPChar:      Result[F] := VPChar;
           vtAnsiString: Result[F] := string(VAnsiString);
           vtVariant:    Result[F] := string(VVariant^);
         end
end;

function ShiftRight(S:String; NShift:Word):String;

function Count(Var S:String; Const FindStr:String):Integer;

Var P:Integer;
begin
     Result:=0;
     Repeat
       P:=Pos(FindStr,S);
       If P>0 Then
          begin
            Inc(Result);
            Delete(S,P,Length(FindStr))
          end
     Until P=0
end;

Var PHPBal,PHPBalOld:Integer;
    Sh:String;
    Cur:String;
    P:Integer;
begin
     Result:='';
     Sh:=StringOfChar(' ',NShift);
     PHPBal:=1;
     While Length(S)>0 Do
       begin
         P:=Pos(CRLF,S);
         If P=0 Then P:=MaxInt-1;
         Cur:=Copy(S,1,P+1);
         PHPBalOld:=PHPBal;
         Inc(PHPBal,Count(Cur,tagPHPOpen)-Count(Cur,tagPHPClose));
         If (PHPBalOld=0) And (PHPBal>=0) Then
            Result:=Result+Copy(S,1,P+1)
         Else
            Result:=Result+Sh+Copy(S,1,P+1);
         Delete(S,1,P+1)
       end
end;

{ TContactReg }

constructor TContactReg.Create(Const _ClsID, _CntID, _Name: String;
  _Req: Boolean; _Dir: TIODirection; _CType: TContactType);
begin
     Inherited Create;
     ClsID:=_ClsID;
     CntID:=_CntID;
     Name:=_Name;
     Req:=_Req;
     Dir:=_Dir;
     CType:=_CType
end;

{ TLinkReg }

constructor TLinkReg.Create(Const _OutClsID, _OutContID, _InClsID, _InContID: String);
begin
     Inherited Create;
     OutClsID:=_OutClsID;
     OutContID:=_OutContID;
     InClsID:=_InClsID;
     InContID:=_InContID
end;

{ TElementReg }

procedure TElementReg.CollectParams(var Prms: ParamArray);

Var Shift, F:Integer;
begin
     If Not Assigned(Parent) Then
        SetLength(Prms,0)
     Else
        Parent.CollectParams(Prms);
     Shift:=Length(Prms);
     SetLength(Prms,Shift+Length(Params));
     For F:=0 To Length(Params)-1 Do
         Prms[Shift+F]:=Params[F]
end;

constructor TElementReg.Create(const PCID, CID, Nm, Scrpt, iScrpt, sScrpt,
  Img: String; Inh: Boolean; const NewPrms: StringArray);

procedure CreateParams(Prnt:TElementReg);

Var PrntParams:ParamArray;
    F,G:Integer;
    Keyword:String;
begin
     SetLength(Params,Length(NewPrms));
     If Assigned(Prnt) Then
        Prnt.CollectParams(PrntParams);
     With TAnalyser.Create(LettersSet+[Underscore],[Space,Tabulation]) Do
       begin
         For F:=0 To Length(NewPrms)-1 Do
           begin
             Params[F]:=TParameter.Create;
             Params[F].Caption:='';
             Params[F].Selector:=Nil;
             Params[F].Multiline:=False;
             Params[F].Locked:=False;
             Params[F].Hidden:=False;
             Params[F].Conjunctor:='';
             AnlzLine:=NewPrms[F];
             If IsNext(LeftFBracket) Then
                If Check(LeftFBracket) Then
                   begin
                     While Not (IsNextSet([RightFBracket,SemiColon]) Or Error) Do
                       begin
                         Keyword:=GetIdent(True);
                         If Keyword=mdfLock Then
                            Params[F].Locked:=True
                         Else If Keyword=mdfHide Then
                            Params[F].Hidden:=True
                         Else If Keyword=mdfRequired Then
                            Params[F].Required:=True
                         Else If Keyword=mdfUnique Then
                            begin
                              Params[F].Required:=True;
                              Params[F].Unique:=True
                            end
                         Else
                            MakeError('Unknown identifier "'+Keyword+
                              '" in parameter''s definition of item '+CID);
                         If IsNext(Plus) Then DelFirst
                       end;
                     If IsNext(SemiColon) And Not Error Then
                       begin
                         DelFirst;
                         Keyword:=GetIdent(True);
                         If Keyword=prmSelector Then
                            begin
                              Params[F].Selector:=TStringList.Create;
                              If Check(LeftBracket) Then
                                 begin
                                   Repeat
                                     Keyword:=GetString(Quote,Quote);
                                     If Not Error Then
                                        begin
                                          Params[F].Selector.Add(Keyword);
                                          If IsNext(Comma) Then DelFirst
                                        end
                                   Until IsNext(RightBracket) Or Error;
                                   Check(RightBracket)
                                 end
                            end
                         Else If Keyword=prmList Then
                            begin
                              Params[F].Selector:=TStringList.Create;
                              If Check(LeftBracket) Then
                                 begin
                                   Repeat
                                     Keyword:=GetBefore(True,[Comma,SemiColon]);
                                     If Not Error Then
                                        begin
                                          Params[F].Selector.Add(Keyword);
                                          If IsNext(Comma) Then DelFirst
                                        end
                                   Until IsNext(SemiColon) Or Error;
                                   Check(SemiColon);
                                   Params[F].Conjunctor:=GetString(Quote,Quote);
                                   If Length(Params[F].Conjunctor)=0 Then
                                      MakeError('Empty delimiter '+
                                         'in the List-definition of parameters of element '+CID);
                                   Check(RightBracket)
                                 end
                            end
                         Else If Keyword=prmText Then
                            Params[F].Multiline:=True
                         Else If (Length(Keyword)=0) Or (Keyword=prmInput) Then
                            Params[F].Selector:=Nil
                         Else
                            MakeError('Unknown type "'+Keyword+
                              '" in the definition of parameters of element '+CID);
                         If (Not Error) And IsNext(SemiColon) Then
                            begin
                              Check(SemiColon);
                              Params[F].Caption:=GetString(Quote,Quote)
                            end
                       end;
                     If Error Then GetBefore(True,[RightFBracket])
                     Else Check(RightFBracket)
                   end;
             DelSpaces;
             Params[F].Name:=GetBefore(True,[Equal]);
             If Empty Then
                Params[F].DefValue:=''
             Else
                begin
                  Check(Equal);
                  DelSpaces;
                  Params[F].DefValue:=GetAll
                end;
             Params[F].Definer:=Self;
             Params[F].Redefined:=False;
             For G:=0 To Length(PrntParams)-1 Do
                 If PrntParams[G].Name=Params[F].Name Then
                    begin
                      Params[F].Definer:=PrntParams[G].Definer;
                      If Length(Params[F].Caption)=0 Then
                         Params[F].Caption:=PrntParams[G].Caption;
                      Params[F].Redefined:=True;
                      Break
                    end
           end;
         Free
       end;
     If Assigned(Prnt) Then
        SetLength(PrntParams,0)
end;

Var F:Integer;
begin
     Inherited Create;
     ClsID:=CID;
     Name:=Nm;
     FScript:=Scrpt;
     FStoredPath:='';
     iScript:=iScrpt;
     sScript:=sScrpt;
     iPredicate:='';
     sPredicate:='';
     FImgPath:=Img;
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     FImage:=Nil;
     {$ENDIF}
     Parent:=Nil;
     Generated:=False;
     FUsed:=False;
     Inherit:=Inh;
     SetLength(FStoredPrms, Length(NewPrms));
     For F := Low(NewPrms) To High(NewPrms) Do
         FStoredPrms[F] := NewPrms[F];
     If Length(PCID)=0 Then
        CreateParams(Nil)
     Else
        If Assigned(ElementRegList) Then
           For F:=0 To ElementRegList.Count-1 Do
               If PCID=TElementReg(ElementRegList.Items[F]).ClsID Then
                  begin
                    Parent:=TElementReg(ElementRegList.Items[F]);
                    CreateParams(Parent);
                    Exit
                  end;
     Assert(Length(PCID)=0,'Base class '+PCID+' not found')
end;

destructor TElementReg.Destroy;

Var F:Integer;
begin
     For F:=0 To Length(Params)-1 Do
       Params[F].Free;
     SetLength(Params,0);
     Inherited
end;

function TElementReg.ProducePrms(Prolog: Boolean; var Code: String;
  _Dir: TIODirection; const Prepend: String; DummyPrologVars: Boolean): Boolean;

Var F:Integer;
begin
     Result:=False;
     For F:=0 To ContactRegList.Count-1 Do
         With TContactReg(ContactRegList.Items[F]) Do
           If ElementIs(Self,ClsID) And (Dir=_Dir) Then
              begin
                If Not Prolog Then
                   Code:=Code+'$pow'+CntID+',';
                If DummyPrologVars Then
                   If _Dir=dirInput Then
                      Code:=Code+Prepend+'_'+','
                   Else
                      Code:=Code+Prepend+'''null'''+','
                Else
                   Code:=Code+Prepend+CntID+',';
                Result:=True
              end
end;

function TElementReg.GeneratePHP(var Code: String): Boolean;

Var P:TElementReg;
    F:Integer;
    AllParams:ParamArray;
begin
     Result:=True;
     If Not Generated Then
        begin
          Generated:=True;
          If Assigned(Parent) Then
             Result:=Parent.GeneratePHP(Code);
          If Result Then
             begin
               Code:=Code+'class '+ClsID;
               If Assigned(Parent) Then
                  Code:=Code+' extends '+Parent.ClsID;
               Code:=Code+' {'+CRLF;
               Code:=Code+'  var $'+idfieldClassID+' = "'+ClsID+'";'+CRLF;
               If Not Assigned(Parent) Then
                  Code:=Code+'  var $'+idfieldID+';'+CRLF;
               If Length(Params)>0 Then
                  For F:=0 To Length(Params)-1 Do
                      If Not Params[F].Redefined Then
                         Code:=Code+'  var $'+Params[F].Name+';'+CRLF;
               CollectParams(AllParams);
               If Used Then
                  begin
                    Code:=Code+CRLF+'  function '+ClsID+'($_'+idfieldID+',';
                    For F:=0 To Length(AllParams)-1 Do
                        If Not AllParams[F].Redefined Then
                           Code:=Code+'$_'+AllParams[F].Name+',';
                    Code[Length(Code)]:=')';
                    Code:=Code+' {'+CRLF+
                          '    $this->'+idfieldID+' = $_'+idfieldID+';'+CRLF;
                    For F:=0 To Length(AllParams)-1 Do
                        If Not AllParams[F].Redefined Then
                           Code:=Code+'    $this->'+AllParams[F].Name+
                                 ' = $_'+AllParams[F].Name+';'+CRLF;
                    Code:=Code+'  }'+CRLF
                  end;
               SetLength(AllParams,0);
               If Used Or Not Assigned(Parent) Then
                  begin
                    Code:=Code+CRLF+'  function '+idfunGenerate+'($'+idprmStage+',';
                    If Assigned(ContactRegList) Then
                       begin
                         ProducePrms(False,Code,dirInput,'$');
                         ProducePrms(False,Code,dirOutput,'&$')
                       end;
                    Code[Length(Code)]:=')';
                    Code:=Code+CRLF+
                          '  {'+CRLF;
                    If Inherit Then
                       begin
                         P:=Parent;
                         While Assigned(P) And (Length(P.Script)=0) Do
                           P:=P.Parent;
                         If Assigned(P) Then
                            begin
                              Code:=Code+'   '+P.ClsID+'::'+idFunGenerate+'($'+idprmStage+',';
                              If Assigned(ContactRegList) Then
                                 begin
                                   P.ProducePrms(False,Code,dirInput,'$');
                                   P.ProducePrms(False,Code,dirOutput,'$')
                                 end;
                              Code[Length(Code)]:=')';
                              Code:=Code+';'+CRLF;
                            end
                       end;
                    Code:=Code+'   ob_start();'+CRLF;
                    Code:=Code+ShiftRight(Script,3)+CRLF;
                    Code:=Code+'   $output = ob_get_contents();'+CRLF+
                               '   ob_end_flush();'+CRLF+
                               '   StoreMapped("'+ClsID+'", $output);'+CRLF;
                    Code:=Code+'  }'+CRLF
                  end;
               Code:=Code+'}'+CRLF+CRLF
             end
        end
end;

function TElementReg.GetInductSeq(var Continuous: Boolean;
  ENV: TXPathEnvironment): TElementRegs;

Var AllowedVersions: TStringList;
    ExportedENV: Array[0..65536] Of WideChar;
    Path: String;
    L: TAnalyser;
    CID: String;
    S: String;
    F: Integer;
begin
     AllowedVersions := TStringList.Create;
     With Versions Do
       For F := 0 To Count - 1 Do
           If Assigned(Objects[F]) Then
              AllowedVersions.Add(Strings[F]);
     L := TAnalyser.Create(IdentSet, [Space, Tabulation]);
     Continuous := False;
     With TStringList.Create Do
       begin
         Result := Nil;
         If Length(FScript)>0 Then
            If FScript[1]=ScriptToLoad Then
               Path := ExtractFilePath(Copy(FScript, 2, 1024))
            Else
               Path := ExtractFilePath(FStoredPath)
         Else
             Path := ExtractFilePath(FStoredPath);
         Path := ExcludeTrailingBackSlash(Path);
         If FileExists(Path + XPathFile) Then
            begin
              ENV.Export(ExportedENV);
              If Not CompileXPathing(Messaging, PChar(AllowedVersions.Text),
                         PChar(Path + XPathFile), Nil, ExportedENV, ExportedENV, '') Then
                 Begin
                   ClearRestrictions;
                   MakeErrorCommon(String(WideString(GetMSG)))
                 End;
              ENV.Import(ExportedENV);
              SetDeduceLogFile(PChar(Path + LogFile))
            end;
         If FileExists(Path + SuperSlash + InductFile) Then
            begin
              LoadFromFile(Path + SuperSlash + InductFile);
              L.AnlzLine:=Values['Order'];
              S := Values['Result'];
              If Length(S) > 0 Then
                 OutModelName := S;
              S := Values['Transformer'];
              If Length(S) > 0 Then
                 set_default_transformer(S);
              S := Values['Continuous'];
              If (Length(S) > 0) And ((UpperCase(S) = 'TRUE') Or (S = '1')) Then
                 Continuous := True;
              S := Values['Versions'];
              If Length(S) > 0 Then
                 With TStringList.Create Do
                   begin
                     Delimiter := ',';
                     StrictDelimiter := True;
                     DelimitedText := S;
                     For F := 0 To Count-1 Do
                         If Versions.IndexOf(Strings[F]) < 0 Then
                            Versions.Add(Strings[F])
                   end;
              SetLength(Result, 0);
              While Not (L.Error Or L.Empty) Do
                Begin
                  CID := L.GetIdent(False);
                  For F:=0 To ElementRegList.Count-1 Do
                      With TElementReg(ElementRegList.Items[F]) Do
                        If CID=ClsID Then
                           begin
                             SetLength(Result, Length(Result) + 1);
                             Result[High(Result)] := TElementReg(ElementRegList.Items[F]);
                             Break
                           end;
                  If Not L.Empty Then
                     L.Check(Comma)
                End
            end;
         Free
       end;
     AllowedVersions.Free;
     L.Free
end;

function TElementReg.GetBasePath: String;
begin
     If Length(FScript)>0 Then
        If FScript[1]=ScriptToLoad Then
           Result := ExtractFilePath(Copy(FScript, 2, 1024))
        Else
           Result := FStoredPath
     Else
        Result := FStoredPath
end;

function TElementReg.AddMacro(XPathing: Boolean; m: MetaCompiler): ScanMacro;

function GetConstruct(Var Strs: TStringList; Var L: TAnalyser; Var I: Integer; DelPoint: Boolean; StoreCRLF: Boolean): String;

Var S: String;
    First: Boolean;
Begin
   Result := '';
   First := True;
   While (I < Strs.Count) And Not L.Error Do
     Begin
       If Not First Then L.AnlzLine := Strs.Strings[I];
       Inc(I);
       L.DelSpaces;
       If (Not L.Empty) And (Not L.IsNext(Percent)) And (L.AnlzLine[Length(L.AnlzLine)] = Lexique.Point) Then
          Begin
            S := L.AnlzLine;
            If DelPoint Then
               System.Delete(S, Length(S), 1);
            AppendStr(Result, S);
            If StoreCRLF Then
               AppendStr(Result, CRLF);
            Exit
          End;
       AppendStr(Result, L.AnlzLine);
       If StoreCRLF Then
          AppendStr(Result, CRLF);
       First := False
     End
End;

procedure RecognizeFastConstruct(Const S: String; L: TAnalyser; db: TFastDB);

Var ID: String;
    Q: Char;
    FName: String;
    Thr: Real;
begin
   L.Check(LeftBracket);
   ID := L.GetIdent(False);
   L.Check(Comma);
   If S = fpNearest Then
      begin
        If (Not L.Error) And L.GetCheckNumber(True, Thr) Then
           L.Check(Comma)
      end;
   If L.Error Then Exit;
   If L.IsNextSet([Quote, DblQuote]) Then
      begin
        Q := L.AnlzLine[1];
        L.DelFirst;
        FName := L.GetBefore(False, [Q]);
        L.Check(Q);
        L.Check(RightBracket);
        L.Check(Lexique.Point);
        If Not L.Error Then
           If S = fpFast Then
              db.AddObject(ID, TFastTable.Create(FName))
           Else If S = fpNearest Then
              db.AddObject(ID, TFastNearestTable.Create(Round(Thr), FName))
           Else If S = fpNeuro Then
              db.AddObject(ID, TFastNet.Create(FName, db))
           Else
              L.Expect('Construction identifier')
      end
   Else
      L.CheckSet([Quote, DblQuote])
end;

procedure GetAutoArg(Var S: String; L1: TAnalyser; Var J: Integer; Const Base: String);

Var S1, S2: String;
Begin
   If L1.IsNext(DblQuote) Then
      Begin
        S1 := L1.GetString(DblQuote, DblQuote);
        AppendStr(S, '=(' + Base + IntToStr(J) + ',''' + S1 + ''')')
      End
   Else If L1.IsNext(Quote) Then
      Begin
        S1 := L1.GetString(Quote, Quote);
        AppendStr(S, '=(' + Base + IntToStr(J) + ',''' + S1 + ''')')
      End
   Else Begin
        S2 := L1.GetIdent(False);
        If L1.IsNext(LeftBracket) Then
           Begin
             If CompareText(S2,xpfRandom) = 0 Then
                Begin
                  L1.Check(LeftBracket);
                  L1.Check(RightBracket);
                  If Not L1.Error Then
                     AppendStr(S, 'random(1,200000000,' + Base + IntToStr(J) + ')')
                End
             Else If CompareText(S2,xpfRandomID) = 0 Then
                Begin
                  L1.Check(LeftBracket);
                  L1.Check(RightBracket);
                  If Not L1.Error Then
                     AppendStr(S, 'randomid(8,' + Base + IntToStr(J) + ')')
                End
           End
        Else
           Begin
             L1.Check(Colon);
             If L1.IsNext(Quote) Then
                S1 := L1.GetString(Quote, Quote)
             Else
                S1 := L1.GetString(DblQuote, DblQuote);
             AppendStr(S, 'xpath(''' + S2 + ''',''' + S1 + ''',[' + Base + IntToStr(J) + '])')
           End
      End;
End;

Var Path: String;
    Strs: TStringList;
    curVers, selVers: Set Of Byte;
    glue: Char;
    Allowed: Boolean;
    XPathGoal: String;
    XPathCount: Integer;
    Mandatory: Boolean;
    C: TContactReg;
    db: TFastDB;
    L, L1: TAnalyser;
    Rep: Integer;
    dRep: Real;
    S, S1, S2: String;
    F, I, J, K: Integer;
begin
     L := TAnalyser.Create(IdentSet, [Space, Tabulation]);
     L1 := TAnalyser.Create(IdentSet, [Space, Tabulation]);
     Strs := TStringList.Create;
     db := TFastDB.Create;
     XPathGoal := '!,randomize';
     XPathCount := 0;
     glue := rmNonGlue;
     With Strs Do
       begin
         If Length(FScript)>0 Then
            If FScript[1]=ScriptToLoad Then
               Path := ExtractFilePath(Copy(FScript, 2, 1024))
            Else
               Path := ExtractFilePath(FStoredPath)
         Else
             Path := ExtractFilePath(FStoredPath);
         Path := ExcludeTrailingBackSlash(Path);
         Result := m.AddMacro(clsID);
         If FileExists(Path + SuperSlash + MacroFile) Then
            begin
              selVers := [];
              With Versions Do
                For F := 0 To Count - 1 Do
                    If Assigned(Objects[F]) Then
                       Include(selVers,F);
              curVers := selVers;
              LoadFromFile(Path + SuperSlash + MacroFile);
              I := 0;
              While Not (L.Error Or (I >= Count)) Do
                Begin
                  Allowed := (selVers = []) Or (curVers*selVers <> []);
                  L.AnlzLine := Strings[I];
                  If L.Empty Or L.IsNext(Percent) Then
                     Inc(I)
                  Else If L.IsNext(SpecSymbol) Then
                        Begin
                          L.Check(SpecSymbol);
                          S := L.GetIdent(False);
                          If (S = dirVersions) And L.Check(LeftBracket) Then
                             begin
                               curVers := [];
                               While Not (L.Error Or L.IsNext(RightBracket)) Do
                                 begin
                                   S := L.GetBalancedListItem(False, [RightBracket, Comma]);
                                   F := Versions.IndexOf(S);
                                   If F >= 0 Then
                                      Include(curVers, F);
                                   If L.Empty Then
                                      L.ExpectSet([RightBracket, Comma])
                                   Else If L.IsNext(Comma) Then
                                      L.Check(Comma);
                                 end;
                               L.Check(RightBracket);
                               If Not L.Error Then
                                  Inc(I)
                             end
                          Else If (S = rsGlue) And L.Check(Colon) And L.Check(Dash) And L.Check(Lexique.Point) Then
                             begin
                               If Allowed Then glue := rmGlue;
                               If Not L.Error Then
                                  Inc(I)
                             end
                          Else If S = rsReplace Then
                             begin
                              L.Check(LeftBracket);
                              S1 := L.GetIdent(False);
                              If L.Check(RightBracket) And L.Check(Colon) And L.Check(Dash) Then
                                 begin
                                   S := GetConstruct(Strs, L, I, True, False);
                                   If Allowed Then
                                      begin
                                        Result.AddReplacer(S1, S);
                                        Result.Goal := defGoal;
                                        Result.Done := defDone
                                      end
                                 end
                             end
                          Else If (S = rsAuto) And L.Check(Colon) And L.Check(Dash) Then
                             begin
                               S := GetConstruct(Strs, L, I, True, False);
                               If Allowed Then
                                  begin
                                     L1.AnlzLine := S;
                                     S := 'goal' + IntToStr(XPathCount) + ':-open(''' + XPathModelFile + ''',append,S),write(S,''<''),' +
                                                   'write(S,''' + ClsID + '''),write(S,'' WORDF="{*WORDF*}" WORDN="{*WORDN*}" GID="{*GID*}" '')';
                                     J := 0;
                                     While Not (L1.Error Or L1.Empty) Do
                                       begin
                                          AppendStr(S, ',');
                                          Mandatory := L1.IsNext(LeftSqrBracket) And L1.Check(LeftSqrBracket);
                                          If Mandatory Then
                                             AppendStr(S, '((');
                                          GetAutoArg(S, L1, J, 'R');
                                          While Not (L1.Error Or L1.IsNext(Equal)) Do
                                             begin
                                               L1.Check(Plus);
                                               Inc(J);
                                               AppendStr(S, ',');
                                               GetAutoArg(S, L1, J, 'Q');
                                               AppendStr(S, ',atom_concat(R' + IntToStr(J-1) + ',Q' + IntToStr(J) + ',R' + IntToStr(J) + ')')
                                             end;
                                          L1.Check(Equal);
                                          L1.Check(Greater);
                                          If L1.IsNext(Quote) Then
                                             S1 := L1.GetString(Quote,Quote)
                                          Else
                                             S1 := L1.GetString(DblQuote,DblQuote);
                                          If CompareText(S1, xpText) = 0 Then
                                             AppendStr(S, ',=(INNERXML,R' + IntToStr(J) + ')')
                                          Else
                                             AppendStr(S, ',write(S,''' + S1 + '''),write(S,''="''),write(S,R' + IntToStr(J) + '),write(S,''" '')');
                                          If Mandatory And L1.Check(RightSqrBracket) Then
                                             AppendStr(S, ');true)');
                                          If Not (L1.Empty Or L1.Error) Then
                                             L1.Check(Comma);
                                          Inc(J)
                                       end;
                                     If Not L1.Error Then
                                        If Not L1.Empty Then
                                           L1.Expect('@auto :- PAT:''XPATH''=>''PROP'',... .');
                                     AppendStr(S, ',write(S,''>''),nl(S)');
                                     For K:=0 To ContactRegList.Count-1 Do
                                         With TContactReg(ContactRegList.Items[K]) Do
                                           If ElementIs(Self,ClsID) And (Dir = dirInput) Then
                                              begin
                                                 AppendStr(S, ',write(S,''<I ID="' + CntID + '" Ref="''),random(1,200000000,RI' + IntToStr(K) + '),write(S,RI' + IntToStr(K) + '),write(S,''">''),nl(S)');
                                                 AppendStr(S, ',write(S,''</I>''),nl(S)');
                                              end;
                                     For K:=0 To ContactRegList.Count-1 Do
                                         With TContactReg(ContactRegList.Items[K]) Do
                                           If ElementIs(Self,ClsID) And (Dir = dirOutput) Then
                                              begin
                                                 AppendStr(S, ',write(S,''<O ID="' + CntID + '" Ref="''),random(1,200000000,RO' + IntToStr(K) + '),write(S,RO' + IntToStr(K) + '),write(S,''">''),nl(S)');
                                                 AppendStr(S, ',write(S,''</O>''),nl(S)');
                                              end;
                                     AppendStr(S, ',(nonvar(INNERXML)->write(S,INNERXML);true),write(S,''</''),write(S,''' + ClsID + '''),write(S,''>''),nl(S),close(S).');
                                     Result.AddPredicate(S);
                                     AppendStr(XPathGoal, ',goal' + IntToStr(XPathCount));
                                     Inc(XPathCount)
                                  end
                             end
                          Else If (S = rsGoal) And L.Check(Colon) And L.Check(Dash) Then
                             begin
                               S := GetConstruct(Strs, L, I, False, False);
                               If Allowed Then
                                  Result.Goal := S
                             end
                          Else If (S = rsDone) And L.Check(Colon) And L.Check(Dash)  Then
                             begin
                               S := GetConstruct(Strs, L, I, True, False);
                               If Allowed Then
                                  Result.Done := S
                             end
                          Else If (S = fpFast) Or (S = fpNearest) Or (S = fpNeuro) Then
                             begin
                               If Allowed Then
                                  RecognizeFastConstruct(S, L, db);
                               Inc(I)
                             end
                          Else If L.Check(LeftBracket) Then
                            Begin
                               S1 := L.GetIdent(False);
                               Rep := 1;
                               If L.IsNext(Comma) Then
                                  Begin
                                    L.Check(Comma);
                                    If L.FindIdent(False) = rsInfinity Then
                                       Begin
                                         L.GetIdent(False);
                                         Rep := rrInfinity
                                       End
                                    Else If L.GetCheckedNumber(True, dRep, 1, 1000000) Then
                                       Rep := Round(dRep)
                                  End;
                               L.Check(RightBracket);
                               L.Check(Colon);
                               L.Check(Dash);
                               If S = rsUnique Then
                                  begin
                                    S := GetConstruct(Strs, L, I, True, False);
                                    If Allowed Then
                                       Result.AddRegExp(rtUnique, Rep, S1, S, glue);
                                    glue := rmNonGlue
                                  end
                               Else If S = rsGlobalUnique Then
                                  begin
                                    S := GetConstruct(Strs, L, I, True, False);
                                    If Allowed Then
                                       Result.AddRegExp(rtGlobalUnique, Rep, S1, S, glue);
                                    glue := rmNonGlue
                                  end
                               Else If S = rsNonUnique Then
                                  begin
                                    S := GetConstruct(Strs, L, I, True, False);
                                    If Allowed Then
                                       Result.AddRegExp(rtHelper, Rep, S1, S, glue);
                                    glue := rmNonGlue
                                  end
                               Else If S = rsContext Then
                                  begin
                                    S := GetConstruct(Strs, L, I, True, False);
                                    If Allowed Then
                                       Result.AddRegExp(rtContext, Rep, S1, S, glue);
                                    glue := rmNonGlue
                                  end
                               Else
                                  L.Expect('@Construction')
                            End
                        End
                  Else
                    Begin
                      If L.FindIdent(False) = '' Then
                         L.Expect('Predicate or @construction')
                      Else
                         begin
                            S := GetConstruct(Strs, L, I, False, True);
                            If Allowed Then Result.AddPredicate(S);
                         end
                    End
                End
            end
       end;
     If XPathing Then
        Result.Goal := XPathGoal + ',!.';
     If Assigned(db) Then
        Result.SetDB(db);
     Strs.Free;
     L.Free;
     L1.Free
end;

procedure TElementReg.SetScript(AValue: String);

Var Path: String;
    VV: String;
begin
     If (Length(FScript)>0) And (FScript[1]=ScriptToLoad) Then
        Path := Copy(FScript,2,2048)
     Else
        Path := FStoredPath;
     FScript := AValue;
     If Length(Path) = 0 Then
        MakeErrorCommon('It is impossible to save a script of class '+ClsID)
     Else
        begin
           VV := AValue;
           AValue := Trim(AValue);
           With TStringList.Create Do
             begin
               If Copy(AValue, 1, Length(tagPHPOpen)) <> tagPHPOpen Then
                  VV := tagPHPOpen + CRLF + VV;
               If Copy(AValue, Length(AValue)-Length(tagPHPClose)+1, Length(tagPHPClose)) <> tagPHPClose Then
                  VV := VV + CRLF + tagPHPClose + CRLF;
               Text:=EncodeStr(VV);
               SaveToFile(Path);
               Free
             end
        end
end;

procedure TElementReg.SetUsed(const Value: Boolean);
begin
     FUsed:=Value;
     If Value And Inherit And Assigned(Parent) Then
        Parent.Used:=True
end;

function TElementReg.GetScript: String;
begin
     If Length(FScript)>0 Then
        If FScript[1]=ScriptToLoad Then
           begin
             Delete(FScript,1,1);
             FStoredPath := FScript;
             With TStringList.Create Do
               begin
                 If FileExists(FScript) Then
                    begin
                      LoadFromFile(FScript);
                      Text:=DecodeStr(Text);
                      If Strings[0]=tagPHPOpen Then Delete(0);
                      If Strings[Count-1]=tagPHPClose Then Delete(Count-1)
                    end;
                 FScript:=Text;
                 Result:=Text;
                 Free
               end
           end
        Else If FScript[1]=RefToLoad Then
           Result:=''
        Else
           Result:=FScript
     Else
        Result:=FScript
end;

{$IF DEFINED(LCL) OR DEFINED(VCL)}
function TElementReg.GetImage: TImage;
begin
     If Not Assigned(FImage) Then
        If Length(FImgPath)>0 Then
           If FileExists(FImgPath) Then
              begin
                FImage:=TImage.Create(Nil);
                {$IFDEF FPC}
                FImage.AutoSize:=True;
                FImage.Picture.LoadFromFile(FImgPath);
                FImage.Transparent:=True;
                FImage.Picture.Bitmap.TransparentMode:=tmAuto
                {$ELSE}
                FImage.Picture.LoadFromFile(FImgPath);
                FImage.AutoSize:=True;
                (FImage.Picture.Graphic As TJpegImage).DIBNeeded;
                FImage.Transparent:=True
                {$ENDIF}
              end
           Else
              FImgPath:='';
     Result:=FImage
end;
{$ENDIF}

procedure TElementReg.OpenScript(const DefaultName: String; var Result,
  pName: String);
begin
     If Length(Result)>0 Then
        If Result[1]=ScriptToLoad Then
           begin
             Delete(Result,1,1);
             With TStringList.Create Do
               begin
                 If FileExists(Result) Then
                    begin
                      LoadFromFile(Result);
                      Text:=DecodeStr(Text);
                      While (Count>0) And (Length(Strings[0])=0) Do
                         Delete(0);
                      If Count>0 Then
                         With TAnalyser.Create(IdentSet,[Space,Tabulation]) Do
                           begin
                             AnlzLine:=Strings[0];
                             DelSpaces;
                             pName:=LowerCase(GetIdent(True))+'_'+ClsID;
                             Delete(0);
                             Free
                           end
                    end
                 Else
                    pName:=LowerCase(DefaultName)+'_'+ClsID;
                 Result:=Text;
                 Free
               end
           end
end;

function TElementReg.GetiScript: String;
begin
     Result:=FiScript;
     OpenScript('init',Result,iPredicate)
end;

function TElementReg.GetsScript: String;
begin
     Result:=FsScript;
     OpenScript('solve',Result,sPredicate)
end;

function TElementReg.GenerateProlog(var Code: String): Boolean;

Var iScr,sScr:String;
begin
     Result:=False;
     If Not Generated Then
        begin
          Generated:=True;
          If Used Or Not Assigned(Parent) Then
             begin
               iScr:=iScript;
               Code:=Code+CRLF+iPredicate+'(';
               If Length(iScr)=0 Then
                  Code:=Code+'_'
               Else
                  Code:=Code+idFieldID;
               Code:=Code+',';
               If Assigned(ContactRegList) Then
                  begin
                    ProducePrms(True,Code,dirInput,'',Length(iScr)=0);
                    ProducePrms(True,Code,dirOutput,'',Length(iScr)=0)
                  end;
               Code[Length(Code)]:=')';
               If Length(iScr)=0 Then
                  Code:=Code+'.'+CRLF
               Else
                  Code:=Code+':-'+CRLF+
                        iScr+CRLF;
               sScr:=sScript;
               Code:=Code+CRLF+sPredicate+'(';
               If Length(sScr)=0 Then
                  Code:=Code+'_'
               Else
                  Code:=Code+idFieldID;
               Code:=Code+',';
               If Assigned(ContactRegList) Then
                  begin
                    ProducePrms(True,Code,dirInput,'',Length(sScr)=0);
                    ProducePrms(True,Code,dirOutput,'',Length(sScr)=0)
                  end;
               Code[Length(Code)]:=')';
               If Length(sScr)=0 Then
                  Code:=Code+'.'+CRLF
               Else
                  Code:=Code+':-'+CRLF+
                        sScr+CRLF;
               Result:=Length(sScr)>0
             end
        end
end;

{ TLink }

function TLink.CheckPoint(X, Y, WX, WY: Integer; Var InPoint, InSegm:Integer): Boolean;

Var _InPoint:Integer;

function CheckLine(Const L:TLine):Boolean;

Var KX,KY:Integer;
    S:Integer;
    T:Real;
begin
     _InPoint:=-1;
     With L Do
       begin
         KX:=X2-X1;
         KY:=Y2-Y1;
         If Abs(KX)>Eps Then
            begin
              T:=(X-X1)/KX;
              S:=Y1+Round(T*KY);
              Result:=(T>=0) And (T<=1) And (Abs(S-Y)<=3*Max(1.0,Abs(KY/KX)))
            end
         Else
            begin
              T:=(Y-Y1)/KY;
              S:=X1+Round(T*KX);
              Result:=(T>=0) And (T<=1) And (Abs(S-X)<=3*Max(1.0,Abs(KX/KY)))
            end;
         If Result Then
            If (Abs(X-X1)<=3) And (Abs(Y-Y1)<=3) Then _InPoint:=0
            Else If (Abs(X-X2)<=3) And (Abs(Y-Y2)<=3) Then _InPoint:=1
       end
end;

Var F:Integer;
    L:TLines;
begin
     If Assigned(_From.Owner.SuperElement) Or Assigned(_To.Owner.SuperElement) Then
        Result:=False
     Else
       begin
         InPoint:=-1;
         InSegm:=-1;
         GetLine(L);
         Inc(X,WX);
         Inc(Y,WY);
         For F:=0 To Length(L)-1 Do
             If CheckLine(L[F]) Then
                begin
                  InSegm:=F;
                  InPoint:=_InPoint
                end;
         Result:=(InSegm>=0)
       end
end;

constructor TLink.Create(__From, __To: TContact; _Inform:Boolean);
begin
     Inherited Create;
     _From:=__From;
     _To:=__To;
     Inform:=_Inform Or (_From.Owner=_To.Owner);
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     Color:=clBlack;
     {$ENDIF}
     SetLength(Points,0)
end;

destructor TLink.Destroy;
begin
     SetLength(Points,0);
     _From.Links.Remove(Self);
     _To.Links.Remove(Self);
     Inherited
end;

procedure TLink.GetLine(var Line: TLines);

Var F,L:Integer;
begin
     L:=Length(Points);
     SetLength(Line,L+1);
     With _From.R Do
       begin
         Line[0].X1:=Right-1;
         Line[0].Y1:=(Top+Bottom) Div 2
       end;
     For F:=0 To L-1 Do
       begin
         Line[F].X2:=Points[F].X;
         Line[F].Y2:=Points[F].Y;
         Line[F+1].X1:=Points[F].X;
         Line[F+1].Y1:=Points[F].Y
       end;
     With _To.R Do
       begin
         Line[L].X2:=Left+1;
         Line[L].Y2:=(Top+Bottom) Div 2
       end
end;

procedure TLink.ReadData(var S: File);

Var L:Word;
    Dummy: Array[0..3] Of Byte;
begin
     BlockRead(S,L,SizeOf(L));
     SetLength(Points,L);
     If L>0 Then
        BlockRead(S,Points[0],L*SizeOf(TPoint));
     BlockRead(S,Inform,SizeOf(Inform));
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     BlockRead(S,Color,SizeOf(Color))
     {$ELSE}
     BlockRead(S, Dummy, SizeOf(Dummy))
     {$ENDIF}
end;

procedure TLink.ReadDataXML(Lnk: TDOMElement);

Var S:String;
    Ps: TDOMElement;
    F:Integer;
    L:Word;
    Anlz:TAnalyser;
begin
     Inform:=CompareText(BoolVals[True],Lnk.AttribStrings['Informational'])=0;
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     S:=Lnk.AttribStrings['Color'];
     If Length(S)>0 Then
        begin
          If S[1]='#' Then S[1]:='$';
          Color:=StringToColor(S)
        end;
     {$ENDIF}
     Ps:=getFirst(Lnk.getElementsByTagName(xmlPoints));
     If Assigned(Ps) Then
        begin
          L:=StrToInt(Ps.AttribStrings['NumItems']);
          SetLength(Points,L);
          If L>0 Then
             begin
               Anlz:=TAnalyser.Create([Comma],[Space,Tabulation]);
               Anlz.AnlzLine:=Ps.TextContent;
               For F:=0 To L-1 Do
                 begin
                   Points[F].x := StrToInt(Anlz.GetListItem([Comma]));
                   Points[F].y := StrToInt(Anlz.GetListItem([Comma]))
                 end;
               Anlz.Free
             end
        end
     Else
        SetLength(Points,0)
end;

procedure TLink.WriteData(var S: File);

Const Dummy: Array[0..3] Of Byte = (0, 0, 0, 0);

Var L:Word;
begin
     L:=Length(Points);
     BlockWrite(S,L,SizeOf(L));
     If L>0 Then
        BlockWrite(S,Points[0],L*SizeOf(TPoint));
     BlockWrite(S,Inform,SizeOf(Inform));
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     BlockWrite(S,Color,SizeOf(Color))
     {$ELSE}
     BlockWrite(S, Dummy, SizeOf(Dummy))
     {$ENDIF}
end;

{ TContact }

function TContact.CheckPoint(X, Y, WX, WY: Integer): Boolean;
begin
     Result:=(Not Assigned(Owner.SuperElement)) And Inherited CheckPoint(X,Y,WX,WY)
end;

constructor TContact.Create(Const NM:String; Own:TElement; _Ref:TContactReg);
begin
     Inherited Create(Rect(0,0,0,0));
     MapFrom:=Nil;
     MapTo:=Nil;
     Name:=NM;
     Owner:=Own;
     Links:=TObjList.Create;
     Ref:=_Ref;
     External:=False;
     PublicID:='';
     PublicName:='';
     State:=cstNormal
end;

destructor TContact.Destroy;
begin
     With Links Do
       begin
         While Count>0 Do
           TLink(First).Free;
         Free
       end;
     Inherited
end;

{$IF DEFINED(LCL) OR DEFINED(VCL)}
procedure TContact.Draw(WX,WY:Integer);

Const SepWidth = 3;
      MarkOffs = ((3*SepWidth) Div 2)+2;
      BColors: Array[Boolean,TContactState] Of TColor = ((clBtnFace,clBlue,clRed),(clDkGray,clBlue,clRed));
      PColors: Array[TContactState] Of TColor = (clBlack,clWhite,clWhite);

Var Xb,Yc:Integer;
    SZ:TSIZE;
begin
     If Not Assigned(Owner.SuperElement) Then
        With Cnv Do
          begin
            OffsetRect(R,-WX,-WY);
            Brush.Color:=BColors[Owner.SubElements.Count>0,State];
            Font.Color:=PColors[State];
            FillRect(Rect(R.Left+2,R.Top+2,R.Right+1,R.Bottom));
            TextOut((R.Left+R.Right-TextWidth(Name)) Div 2,
                    (R.Top+R.Bottom-TextHeight(Name)) Div 2,
                    Name);
            If External Then
               begin
                 If Ref.Dir=dirInput Then
                    begin
                      Xb:=R.Left-1;
                      Brush.Color:=clLime
                    end
                 Else
                    begin
                      Xb:=R.Right-MarkOffs+2;
                      Brush.Color:=clRed
                    end;
                 Pen.Width:=1;
                 Pen.Color:=Brush.Color;
                 Yc:=(R.Top+R.Bottom) Div 2;
                 PolyLine([Classes.Point(Xb,R.Bottom), Classes.Point(Xb+MarkOffs,Yc), Classes.Point(Xb,R.Top), Classes.Point(Xb,R.Bottom)]);
                 FloodFill(Xb+SepWidth,Yc,Pen.Color,fsBorder);
                 Pen.Color:=clBlack;
                 PolyLine([Classes.Point(Xb,R.Bottom), Classes.Point(Xb+MarkOffs,Yc), Classes.Point(Xb,R.Top), Classes.Point(Xb,R.Bottom)])
               end;
            Brush.Color:=clBtnFace;
            Font.Color:=clBlack;
            Pen.Width:=SepWidth;
            MoveTo(R.Left+1,R.Bottom); LineTo(R.Right,R.Bottom);
            OffsetRect(R,WX,WY)
          end
end;
{$ENDIF}

{ TElement }

constructor TElement.Create(_Ref: TElementReg; const ID: String; Flgs: Integer);

Var Prms:ParamArray;
    CC:TContact;
    S:String;
    F:Integer;
begin
     Inherited Create(Rect(0,0,0,0));
     SuperElement:=Nil;
     SubElements:=TList.Create;
     Ref:=_Ref;
     Ident:=ID;
     IdPermanent:=False;
     Inputs:=TObjStrList.Create;
     Outputs:=TObjStrList.Create;
     Parameters:=TStringList.Create;
     Ref.CollectParams(Prms);
     For F:=0 To Length(Prms)-1 Do
         With Prms[F] Do
           If Redefined Then
              begin
                If Length(DefValue)>0 Then
                   Parameters.Values[Name]:=DefValue
                Else
                   Parameters[Parameters.IndexOfName(Name)]:=Name+'=';
                Parameters.Objects[Parameters.IndexOfName(Name)]:=Prms[F]
              end
           Else
              Parameters.AddObject(Name+'='+DefValue,Prms[F]);
     SetLength(Prms,0);
     For F:=0 To ContactRegList.Count-1 Do
         With TContactReg(ContactRegList.Items[F]) Do
           If ElementIs(Ref,ClsID) Then
              Begin // In two lines to prevent absence of AddContact call caused by FPC features...
                CC:=AddContact(CntID,Name,TContactReg(ContactRegList.Items[F]),S);
                Assert(Assigned(CC),S)
              End;
     Flags:=Flgs
end;

destructor TElement.Destroy;
begin
     Parameters.Free;
     Inputs.Free;
     Outputs.Free;
     SubElements.Free;
     Inherited
end;

function TElement.ToString: String;

Var L: TStringList;
    F, G: Integer;
begin
     Result := Ref.ClsID + ':' + Ident + ' is (';
     L := TStringList.Create;
     L.Assign(Parameters);
     L.Sorted := True;
     AppendStr(Result, L.Text + ') : [');
     L.Clear;
     L.Sorted := True;
     For F := 0 To Outputs.Count - 1 Do
         With TContact(Outputs.Objects[F]).Links Do
           For G := 0 To Count - 1 Do
               L.Add(TContact(Outputs.Objects[F]).Ref.CntID + '->' + TLink(Items[G])._To.Owner.Ident + ':' + TLink(Items[G])._To.Ref.CntID + ',');
     AppendStr(Result, L.Text + '];');
     L.Free
end;

function TElement.FindConnectedByType(const ClsID: String; Dir: TIODirections
  ): TList;

procedure Find(Contacts:TObjStrList; _Dir:TIODirection);

Var C:TContact;
    F,G:Integer;
begin
     For F:=0 To Contacts.Count-1 Do
       begin
         C:=TContact(Contacts.Objects[F]);
         Repeat
           With C.Links Do
             For G:=0 To Count-1 Do
               With TLink(Items[G]) Do
                 If Not Inform Then
                    If (_Dir=dirInput) And ((ClsID='') Or ElementIs(forw(_From).Owner.Ref,ClsID)) Then
                       Result.Add(forw(_From).Owner)
                    Else If (_Dir=dirOutput) And ((ClsID='') Or ElementIs(forw(_To).Owner.Ref,ClsID)) Then
                       Result.Add(forw(_To).Owner);
           C:=C.MapFrom
         Until Not Assigned(C)
       end
end;

begin
     Result:=TList.Create;
     If dirInput In Dir Then Find(Inputs,dirInput);
     If dirOutput In Dir Then Find(Outputs,dirOutput)
end;

procedure TElement.ClearFlags(ClearMask:Integer);
begin
     Flags:=Flags And Not ClearMask
end;

procedure TElement.SetFlags(SetMask:Integer);
begin
     Flags:=Flags Or SetMask
end;

function TElement.GetInputContact(ID: String): TContact;

Var Idx:Integer;
begin
     Idx:=Inputs.IndexOf(ID);
     If Idx>=0 Then
        Result:=Inputs.Objects[Idx] As TContact
     Else
        Result:=Nil
end;

function TElement.GetOutputContact(ID: String): TContact;

Var Idx:Integer;
begin
     Idx:=Outputs.IndexOf(ID);
     If Idx>=0 Then
        Result:=Outputs.Objects[Idx] As TContact
     Else
        Result:=Nil
end;

function TElement.AddContact(const ID, Name: String; _Ref: TContactReg;
  var ErrMsg: String): TContact;

Var Contacts:TObjStrList;
begin
     If _Ref.Dir=dirInput Then
        Contacts:=Inputs
     Else
        Contacts:=Outputs;
     If Contacts.IndexOf(ID)<0 Then
        begin
          Result:=TContact.Create(Name,Self,_Ref);
          Contacts.AddObject(ID,Result)
        end
     Else
        begin
          ErrMsg:='Such contact already exists';
          Result:=Nil
        end
end;

function TElement.GetPower: Integer;
begin
   Result := getInputPower + getOutputPower
end;

function TElement.GetInputPower: Integer;

Var F: Integer;
begin
   Result := 0;
   For F := 0 To Inputs.Count-1 Do
     With TContact(Inputs.Objects[F]) Do
       Inc(Result, Links.Count)
end;

function TElement.GetOutputPower: Integer;

Var F: Integer;
begin
   Result := 0;
   For F := 0 To Outputs.Count-1 Do
     With TContact(Outputs.Objects[F]) Do
       Inc(Result, Links.Count)
end;

function TElement.Check: TResultType;

{$WARNINGS OFF}
function _Check(Contacts:TObjStrList):TResultType;

Var C:TContact;
    L:TList;
    F:Integer;
begin
     Result:=rsOk;
     With Contacts Do
       For F:=0 To Count-1 Do
         begin
           C:=TContact(Contacts.Objects[F]);
           Try
             L:=CollectBackLinks(C);
             If (C.Ref.Req) And (L.Count=0) Then
                begin
                  If Messaging Then
                     begin
                       ErrorMsg:='Contact "'+Strings[F]+'" is not linked';
                       ProcessedObject:=Self
                     end;
                  Result := rsNonStrict
                end;
             If (C.Ref.CType=ctSingle) And (L.Count>1) Then
                begin
                  If Messaging Then
                     begin
                       ErrorMsg:='Contact "'+Strings[F]+'" allows only one link';
                       ProcessedObject:=Self
                     end;
                  Exit(rsStrict)
                end
           Finally
             L.Free
           End
         end
end;
{$WARNINGS ON}

Var F,G,H:Integer;
    C1, St: TResultType;
    OID,IID:String;
begin
     Flags:=Flags Or flChecked;
     If SubElements.Count=0 Then Ref.Used:=True;
     C1 := _Check(Inputs);
     If C1 = rsOk Then
        Result := _Check(Outputs)
     Else If C1 = rsStrict Then
        Result := rsStrict
     Else If _Check(Outputs) = rsStrict Then
        Result := rsStrict
     Else
        Result := rsNonStrict;
     F:=0;
     While (F<Outputs.Count) And (Result <> rsStrict) Do
       With TContact(Outputs.Objects[F]) Do
         begin
           G:=0;
           OID:=Outputs[F];
           While (G<Links.Count) And (Result <> rsStrict) Do
             With TLink(Links[G]) Do
               begin
                 With _To.Owner.Inputs Do
                   IID:=Strings[IndexOfObject(_To)];
                 H:=0;
                 St := Result;
                 Result:=rsStrict;
                 While H<LinkRegList.Count Do
                   With TLinkReg(LinkRegList.Items[H]) Do
                     If ElementIs(_From.Owner.Ref,OutClsID) And
                        ElementIs(_To.Owner.Ref,InClsID) And
                         ((IID=InContID) Or (InContID=cnidAny)) And
                         ((OID=OutContID) Or (OutContID=cnidAny)) Then
                         Begin
                           Result := St;
                           Break
                         End
                     Else
                        Inc(H);
                 If Result <> rsOk Then
                    If Messaging And Not Assigned(ProcessedObject) Then
                       begin
                         ProcessedObject:=TObject(Links[G]);
                         ErrorMsg := 'Incorrect link'
                       end;
                 Inc(G)
               end;
           Inc(F)
         end;
     If Result <> rsOk Then
        If Messaging And Not Assigned(ProcessedObject) Then
           ProcessedObject:=Self
end;

function TElement.GeneratePHPClasses(var Code: String): Boolean;

Const MetaSymbols = '\"$';

Var AllParams: ParamArray;
    F,G:Integer;
    C:TStringList;
    S:String;
begin
     If SubElements.Count>0 Then
        Result:=True
     Else
       begin
         Flags:=Flags Or flClassesGenerated;
         Result:=Ref.GeneratePHP(Code);
         If Result Then
            begin
              Code:=Code+'$'+Ident+' = new '+Ref.ClsID+'("'+Ident+'",';
              Ref.CollectParams(AllParams);
              C:=TStringList.Create;
              For F:=0 To Length(AllParams)-1 Do
                If Not AllParams[F].Redefined Then
                  begin
                    If AllParams[F].Multiline Then
                       begin
                         C.CommaText:=Parameters.Values[AllParams[F].Name];
                         S:=C.Text;
                         For G:=1 To Length(MetaSymbols) Do
                           S:=StringReplace(S,MetaSymbols[G],'\'+MetaSymbols[G],[rfReplaceAll]);
                         S:=StringReplace(S,#09,'\t',[rfReplaceAll]);
                         S:=StringReplace(S,CRLF,'\n',[rfReplaceAll])
                       end
                     Else
                       begin
                         S:=Parameters.Values[AllParams[F].Name];
                         For G:=1 To Length(MetaSymbols) Do
                           S:=StringReplace(S,MetaSymbols[G],'\'+MetaSymbols[G],[rfReplaceAll])
                       end;
                    Code:=Code+'"'+S+'",'
                  end;
              C.Free;
              Code[Length(Code)]:=')';
              Code:=Code+';'+CRLF+CRLF
            end
       end
end;

function TElement.GeneratePHPCalls(var Code: String): Boolean;

function GetOutDefinition(_Out:TContact):String;
begin
     Result:='array("_ClassID" => array("'+_Out.Owner.Ref.ClsID+'"), ';
     Result:=Result+'"_ID" => array("'+_Out.Owner.Ident+'"), ';
     With _Out.Owner Do
       Result:=Result+'"_LinkID" => array("'+Outputs[Outputs.IndexOfObject(_Out)]+'"))'
end;

Var F,G:Integer;
begin
     If SubElements.Count>0 Then
        Result:=True
     Else
       begin
         Flags:=Flags Or flCallsGenerated;
         With Outputs Do
           For F:=0 To Count-1 Do
             Code:=Code+'$'+Ident+'_'+Strings[F]+' = '+GetOutDefinition(TContact(Objects[F]))+';'+CRLF;
         Code:=Code+'$'+Ident+'->'+idfunGenerate+'($'+idvarStage+',';
         With Inputs Do
           For F:=0 To Count-1 Do
             With CollectBackLinks(TContact(Objects[F])) Do
               begin
                 Code:=Code+IntToStr(Count)+',';
                 If Count=0 Then
                    Code:=Code+'array(),'
                 Else
                   begin
                     If Count>1 Then
                        Code:=Code+'contact_merge(array(';
                     For G:=0 To Count-1 Do
                       If TLink(Items[G]).Inform Then
                          Code:=Code+GetOutDefinition(forw(TLink(Items[G])._From))+','
                       Else
                          With forw(TLink(Items[G])._From).Owner Do
                            Code:=Code+'$'+Ident+'_'+
                                  Outputs.Strings[Outputs.IndexOfObject(forw(TLink(Items[G])._From))]+
                                  ',';
                     If Count>1 Then
                        begin
                          Code[Length(Code)]:=')';
                          Code:=Code+'),'
                        end
                   end;
                 Free
               end;
         With Outputs Do
           For F:=0 To Count-1 Do
             Code:=Code+IntToStr(TContact(Objects[F]).Links.Count)+',$'+Ident+'_'+Strings[F]+',';
         Code[Length(Code)]:=')';
         Code:=Code+';'+CRLF+CRLF;
         Result:=True
       end
end;

{$IF DEFINED(LCL) OR DEFINED(VCL)}
procedure TElement.Draw(WX,WY:Integer);

Const LWidth  = 3;
      SemiGap = 2;
      HGap = LWidth+SemiGap;
      VGap = LWidth+SemiGap;

function MaxWidth(C:TObjStrList; Var H:Integer):Integer;

Var F,G:Integer;
begin
     Result:=0;
     H:=0;
     For F:=0 To C.Count-1 Do
         begin
           G:=Cnv.TextWidth(TContact(C.Objects[F]).Name);
           Inc(H,Cnv.TextHeight(TContact(C.Objects[F]).Name)+VGap);
           If G>Result Then Result:=G
         end;
     Inc(Result,2*HGap)
end;

procedure TextCenterX(X,Y:Integer; Const Txt:String);
begin
     Dec(X,Cnv.TextWidth(Txt) Div 2);
     Cnv.TextOut(X,Y,Txt)
end;

procedure ArrangeContacts(C:TObjStrList; X,Y,W,H:Integer);

Var F:Integer;
    Q:Real;
    YY:Real;
begin
     If C.Count>0 Then
        begin
          Q:=H/C.Count;
          YY:=Y;
          For F:=0 To C.Count-1 Do
            begin
              TContact(C.Objects[F]).SetPosition(X,Round(YY),X+W-1,Round(YY+Q));
              YY:=YY+Q
            end
        end
end;

Var SC,SN:Byte;
    LX,LY:Integer;
    LI,LO,LS:Integer;
    HI,HO,HC:Integer;
    HType,HID:Integer;
    Img:TImage;
    ImgW:Integer;
    Head:Integer;
begin
     If Assigned(Cnv) And Not Assigned(SuperElement) Then
        With Cnv Do
          begin
            SC:=Byte((Flags And flShowClass)<>0);
            SN:=Byte((Flags And flShowName)<>0);
            If (Flags And flShowImage)<>0 Then
               Img:=Ref.Image
            Else
               Img:=Nil;
            LI:=MaxWidth(Inputs,HI);
            LO:=MaxWidth(Outputs,HO);
            LS:=Max(LI,LO);
            HType:=SC*(Cnv.TextHeight(Ref.Name)+HGap);
            HID:=SN*Cnv.TextHeight(Ident);
            Head:=HType+HGap*SN+HID;
            If Assigned(Img) Then
               begin
                 Inc(Head,Img.Picture.Height+2*LWidth);
                 ImgW:=Img.Picture.Width
               end
            Else
               ImgW:=0;
            LX:=HGap+Max(2*LS,Max(ImgW,Max(SC*Cnv.TextWidth(Ref.Name),SN*Cnv.TextWidth(Ident))));
            LX:=LX+Byte(Not Odd(LX));
            LS:=LX Div 2;
            HC:=Max(HI,HO);
            LY:=Max(HC+Head,2*HGap);
            Pen.Width:=LWidth;
            R.Right:=R.Left+LX+1;
            R.Bottom:=R.Top+LY+1;
            OffsetRect(R,-WX,-WY);
            If SubElements.Count>0 Then
               Brush.Color:=clDkGray
            Else
               Brush.Color:=clBtnFace;
            Rectangle(R.Left,R.Top,R.Right,R.Bottom);
            Brush.Color:=$C0DFDF;
            Rectangle(R.Left,R.Top,R.Right,R.Top+HType+1);
            If SC<>0 Then TextCenterX(R.Left+LS,R.Top+SemiGap,Ref.Name);
            Brush.Color:=$DFDFC0;
            Rectangle(R.Left,R.Top+HType,R.Right,R.Top+Head+1);
            If SN<>0 Then TextCenterX(R.Left+LS,R.Top+HType+SemiGap,Ident);
            If Assigned(Img) Then
               begin
                 Brush.Color:=$E8E8E8;
                 Rectangle(R.Left,R.Top+HType+HGap*SN+HID,R.Right,R.Top+Head+1);
                 Draw(R.Left+(LX-ImgW) Div 2,R.Top+HType+HGap*SN+HID+LWidth,Img.Picture.{$IFDEF FPC}Bitmap{$ELSE}Graphic{$ENDIF})
               end;
            Brush.Color:=clBtnFace;
            MoveTo(R.Left,R.Top+HType);   LineTo(R.Left+LX,R.Top+HType);
            MoveTo(R.Left,R.Top+Head);    LineTo(R.Left+LX,R.Top+Head);
            MoveTo(R.Left+LS,R.Top+Head); LineTo(R.Left+LS,R.Top+LY);
            OffsetRect(R,WX,WY);
            ArrangeContacts(Inputs,R.Left,R.Top+Head,LS,HC);
            ArrangeContacts(Outputs,R.Left+LS,R.Top+Head,LS,HC);
            DrawContacts(Inputs,WX,WY);
            DrawContacts(Outputs,WX,WY)
          end
end;

procedure TElement.DrawContacts(C: TObjStrList;WX,WY:Integer);

Var F:Integer;
begin
     For F:=0 To C.Count-1 Do
         TContact(C.Objects[F]).Draw(WX,WY)
end;
{$ENDIF}

function TElement.FindContact(X, Y, WX, WY: Integer): TContact;

function FindInSet(C:TObjStrList):TContact;

Var F:Integer;
begin
     Result:=Nil;
     For F:=0 To C.Count-1 Do
         If TContact(C.Objects[F]).CheckPoint(X,Y,WX,WY) Then
            begin
              Result:=TContact(C.Objects[F]);
              Exit
            end
end;

begin
     If Assigned(SuperElement) Then
        Result:=Nil
     Else
        begin
          Result:=FindInSet(Inputs);
          If Not Assigned(Result) Then
             Result:=FindInSet(Outputs)
        end
end;

procedure TElement.Deactivate(WX, WY: Integer);

Var F:Integer;
begin
     For F:=0 To Inputs.Count-1 Do
       With TContact(Inputs.Objects[F]) Do
         If State<>cstNormal Then
            begin
              State:=cstNormal;
              Draw(WX,WY)
            end
end;

procedure TElement.ExcludeFromLine(const L: TLines; var L1: TLines);

Var KX,KY: Integer;
    Ts: Array[0..5] Of Real;
    TsCounter: Integer;

procedure InsT(T:Real);

Var F:Integer;
    Found:Boolean;
begin
     Found:=False;
     For F:=0 To TsCounter-1 Do
       If Ts[F]>T Then
          begin
            Found:=True;
            Break
          end;
     If Found Then
        begin
          System.Move(Ts[F],Ts[F+1],(TsCounter-F)*SizeOf(Real));
          Ts[F]:=T
        end
     Else
        Ts[TsCounter]:=T;
     Inc(TsCounter)
end;

procedure CheckX(S:Integer; X:Integer);

Var T:Real;
    Y:Real;
begin
     If Abs(KX)>Eps Then
        With L[S] Do
          begin
            T:=(X-X1)/KX;
            If (T>=0) And (T<=1.0) Then
               begin
                 Y:=Y1+T*KY;
                 If (R.Top-Y)*(R.Bottom-Y)<=0 Then
                    InsT(T)
               end
          end
end;

procedure CheckY(S:Integer; Y:Integer);

Var T:Real;
    X:Real;
begin
     If Abs(KY)>Eps Then
        With L[S] Do
          begin
            T:=(Y-Y1)/KY;
            If (T>=0) And (T<=1.0) Then
               begin
                 X:=X1+T*KX;
                 If (R.Left-X)*(R.Right-X)<=0 Then
                    InsT(T)
               end
          end
end;

procedure SetP(P1,P2:Integer; Var S1,S2:Integer);
begin
     If P1<P2 Then
        begin
          S1:=P1-1;
          S2:=P2+1
        end
     Else
        begin
          S1:=P2-1;
          S2:=P1+1
        end;
end;

{$WARNINGS OFF}
Var R1:TRect;
    F,G: Integer;
    PrevInside,Inside: Boolean;
    XQ,YQ: Integer;
    Buf: Array[0..99] Of TLine;
    Counter: Integer;
begin
     Counter:=0;
     For F:=0 To Length(L)-1 Do
       With L[F] Do
         begin
           SetP(X1,X2,R1.Left,R1.Right);
           SetP(Y1,Y2,R1.Top,R1.Bottom);
           If IntersectRect(R1,R,R1) Then
              begin
                KX:=X2-X1;
                KY:=Y2-Y1;
                Ts[0]:=0;
                TsCounter:=1;
                CheckX(F,R.Right);
                CheckX(F,R.Left);
                CheckY(F,R.Top);
                CheckY(F,R.Bottom);
                Ts[TsCounter]:=1.0;
                If TsCounter>0 Then
                   PrevInside:=(R.Left<=X1) And (X1<=R.Right) And (R.Top<=Y1) And (Y1<=R.Bottom);
                For G:=1 To TsCounter Do
                    begin
                      XQ:=X1+Round(KX*Ts[G]);
                      YQ:=Y1+Round(KY*Ts[G]);
                      Inside:=(R.Left<=XQ) And (XQ<=R.Right) And (R.Top<=YQ) And (YQ<=R.Bottom);
                      If Not (PrevInside And Inside) Then
                         begin
                           Buf[Counter].X1:=X1+Round(KX*Ts[G-1]);
                           Buf[Counter].Y1:=Y1+Round(KY*Ts[G-1]);
                           Buf[Counter].X2:=XQ;
                           Buf[Counter].Y2:=YQ;
                           Inc(Counter)
                         end;
                      PrevInside:=Inside
                    end
              end
           Else
              begin
                Buf[Counter]:=L[F];
                Inc(Counter)
              end
         end;
     SetLength(L1,Counter);
     System.Move(Buf[0],L1[0],Counter*SizeOf(TLine))
end;
{$WARNINGS ON}

procedure TElement.ReadData(var S: File);

Var F,G,H:Integer;
    X,Y:Integer;
    N:TStringList;
    Obj:TParameter;
    Str:String;
begin
     BlockRead(S,Flags,SizeOf(Flags));
     BlockRead(S,IdPermanent,SizeOf(IdPermanent));
     BlockRead(S,X,SizeOf(X));
     BlockRead(S,Y,SizeOf(Y));
     Move(X,Y);
     N:=TStringList.Create;
     Str:=ReadStr(S);
     N.Text:=Str;
     With N Do
       For F:=0 To Count-1 Do
         begin
           G:=Parameters.IndexOfName(Names[F]);
           If G>=0 Then
              begin
                Obj:=Parameters.Objects[G] As TParameter;
                Parameters.Values[Names[F]]:=Values[Names[F]];
                If Length(Values[Names[F]])=0 Then
                   If Parameters.IndexOf(Names[F]+'=') < 0 Then
                      Parameters.Strings[G] := Names[F]+'='
              end
         end;
     N.Free
end;

procedure TElement.ReadDataXML(S: TDOMElement);

Var El,_El: TDOMElement;
    F,G,H:Integer;
    X,Y:Integer;
    N:Integer;
    Obj:TParameter;
    Str,Indent:String;
    IndentN:Integer;
    Val:TStringList;
begin
     IdPermanent:=CompareText(BoolVals[True],S.AttribStrings['Permanent'])=0;
     El:=getFirst(S.getElementsByTagName(xmlShow));
     If CompareText(BoolVals[True],El.AttribStrings['Class'])=0 Then
        Flags:=Flags Or flShowClass;
     If CompareText(BoolVals[True],El.AttribStrings['Name'])=0 Then
        Flags:=Flags Or flShowName;
     If CompareText(BoolVals[True],El.AttribStrings['Image'])=0 Then
        Flags:=Flags Or flShowImage;
     El:=getFirst(S.getElementsByTagName(xmlPosition));
     X:=StrToInt(El.AttribStrings['Left']);
     Y:=StrToInt(El.AttribStrings['Top']);
     Move(X,Y);
     El:=getFirst(S.getElementsByTagName(xmlParameters));
     N:=StrToInt(El.AttribStrings['NumItems']);
     Val:=TStringList.Create;
     _El:=getFirstChild(El);
     For F:=0 To N-1 Do
       begin
         Str:=_El.AttribStrings['ID'];
         If _El.AttribStrings['Indent'] <> '' Then
            Begin
              Indent:=_El.AttribStrings['Indent'];
              If Length(Indent)>0 Then
                 IndentN:=StrToInt(Indent)
              Else
                 IndentN:=0
            End
         Else
            IndentN:=0;
         G:=Parameters.IndexOfName(Str);
         If G>=0 Then
            begin
              Obj:=Parameters.Objects[G] As TParameter;
              If Obj.MultiLine Then
                 begin
                   Val.Text:=StringOfChar(Space,IndentN)+_El.TextContent;
                   Parameters.Values[Str]:=GetCommaText(Val)
                 end
              Else
                 Parameters.Values[Str]:=StringOfChar(Space,IndentN)+_El.TextContent;
              If (Length(_El.TextContent)=0) And (IndentN=0) Then
                 If Parameters.IndexOf(Str+'=') < 0 Then
                    Parameters.Strings[G] := Str+'='
            end;
         _El:=getNextChild(_El)
       end;
     Val.Free
end;

procedure TElement.WriteData(var S: File);
begin
     BlockWrite(S,Flags,SizeOf(Flags));
     BlockWrite(S,IdPermanent,SizeOf(IdPermanent));
     BlockWrite(S,R.Left,SizeOf(R.Left));
     BlockWrite(S,R.Top,SizeOf(R.Top));
     WriteStr(S,Parameters.Text)
end;

function TElement.CheckPoint(X, Y, WX, WY: Integer): Boolean;
begin
     Result:=(Not Assigned(SuperElement)) And Inherited CheckPoint(X,Y,WX,WY)
end;

function TElement.LoadSubElements(Sys:TSystem):Boolean;

Var SubSys:TSystem;
    Obj:TElement;
    F:Integer;
    S:String;
begin
     Result:=True;
     If (Length(Ref.FScript)>0) And (Ref.FScript[1]=RefToLoad) Then
        begin
          SubSys:=TSystem.LoadFromFile(S,Copy(Ref.FScript,2,Length(Ref.FScript)-1),Inputs,Outputs);
          With SubSys Do
           If Success Then
            begin
              For F:=0 To Elements.Count-1 Do
                With TElement(Elements[F]) Do
                  If Not IdPermanent Then
                     Ident:=Self.Ident+'_'+Ident
                  Else
                     If Not Sys.CheckID(TElement(Elements[F]),Ident) Then
                        begin
                          MakeErrorCommon('Strict conflict of names. '+
                                     'Inserted block contains item with '+
                                     'static identifier "'+Ident+'", but '+
                                     'the system already contains the item with such identifier.');
                          SubSys.Free;
                          Result:=False;
                          Exit
                        end;
              While Elements.Count>0 Do
                begin
                  Obj:=TElement(Elements.First);
                  If Not Assigned(Obj.SuperElement) Then
                     begin
                       Obj.SuperElement:=Self;
                       SubElements.Add(Obj)
                     end;
                  Sys.Elements.Add(Obj);
                  Elements.Delete(0)
                end
            end;
          SubSys.Free
        end
end;

procedure TElement.RemoveSubElements(Sys:TSystem);

Var F:Integer;
    Obj:TElement;
begin
     For F:=0 To SubElements.Count-1 Do
       begin
         Obj:=TElement(SubElements[F]);
         Obj.RemoveSubElements(Sys);
         Sys.Elements.Remove(Obj);
         Obj.Free
       end;
     SubElements.Clear
end;

function TElement.forw(C: TContact): TContact;
begin
     While Assigned(C.MapTo) Do
       C:=C.MapTo;
     Result:=C
end;

function TElement.CollectBackLinks(C: TContact): TList;

Var F:Integer;
begin
     Result:=TList.Create;
     Repeat
       For F:=0 To C.Links.Count-1 Do
         Result.Add(C.Links[F]);
       C:=C.MapFrom
     Until Not Assigned(C)
end;


procedure TElement.ChangeSubIDs(const OldID, NewID: String);

Var F:Integer;
    SubNewID:String;
begin
     For F:=0 To SubElements.Count-1 Do
       With TElement(SubElements[F]) Do
         If Not IdPermanent Then
            If Copy(Ident,1,Length(OldID))=OldID Then
               begin
                 SubNewID:=NewID+Copy(Ident,Length(OldID)+1,1000);
                 ChangeSubIDs(Ident,SubNewID);
                 Ident:=SubNewID
               end
end;

procedure TElement.WriteDataXML(var S: TextFile; const Prefix: String);

Var F,Indent:Integer;
    C:TStringList;
    SS:String;
begin
     WriteLn(S,Format('%s<%s Class="%s" Name="%s" Image="%s"/>',
                      [Prefix,xmlShow,
                       BoolVals[(Flags And flShowClass)<>0],
                       BoolVals[(Flags And flShowName)<>0],
                       BoolVals[(Flags And flShowImage)<>0]]));
     WriteLn(S,Format('%s<%s Left="%d" Top="%d"/>',[Prefix,xmlPosition,R.Left,R.Top]));
     With Parameters Do
       If Count=0 Then
          WriteLn(S,Format('%s<%s NumItems="0"/>',[Prefix,xmlParameters]))
       Else
         begin
           WriteLn(S,Format('%s<%s NumItems="%d">',[Prefix,xmlParameters,Count]));
           C:=TStringList.Create;
           For F:=0 To Count-1 Do
             begin
               SS:=Values[Names[F]];
               If Length(SS)>0 Then
                  begin
                    C.CommaText:=SS;
                    If C.Count=0 Then
                       SS:=''
                    Else If SS[1]='"' Then
                       begin
                         SS:=C.Text;
                         If C.Count=1 Then
                            If Copy(SS,Length(SS)-1,2)=CRLF Then
                               SetLength(SS,Length(SS)-2)
                       end
                  end;
               SS:=EscapeText(EncodeStr(SS),Indent);
               Write(S,Format('%s <%s ID="%s" Indent="%u">%s',[Prefix,xmlParameter,Names[F],Indent,SS]));
               WriteLn(S,Format('</%s>',[xmlParameter]))
             end;
           C.Free;
           WriteLn(S,Format('%s</%s>',[Prefix,xmlParameters]))
         end
end;

procedure TElement.HandleExtContact(Dir:TIODirection; Ext:TObjStrList;
     const CntID, PubID, PubName: String);

Var C:TObjStrList;
    Idx,Idx1:Integer;
begin
     If Dir=dirInput Then C:=Inputs
     Else C:=Outputs;
     Idx:=C.IndexOf(CntID);
     If (Idx>=0) Then
        With TContact(C.Objects[Idx]) Do
          If Not Assigned(Ext) Then
             begin
               PublicID:=PubID;
               PublicName:=PubName;
               External:=True
             end
          Else
             begin
               Idx1:=Ext.IndexOf(PubID);
               If Idx1>=0 Then
                  begin
                    MapFrom:=TContact(Ext.Objects[Idx1]);
                    MapFrom.MapTo:=TContact(C.Objects[Idx])
                  end
             end
end;

procedure TElement.ReadExtContactsXML(Dir: TIODirection; Ext: TObjStrList;
  S: TDOMElement);

Var F:Integer;
    El: TDOMElement;
    L:Word;
begin
     L:=StrToInt(S.AttribStrings['NumItems']);
     If L>0 Then
        Begin
          El:=getFirstChild(S);
          For F:=0 To L-1 Do
            Begin
              HandleExtContact(Dir,Ext,El.AttribStrings['ID'],El.AttribStrings['PublicID'],El.AttribStrings['PublicName']);
              El:=getNextChild(El);
            End
        End
end;

procedure TElement.WriteDataProlog(var S: TextFile; const Prefix: String);

Var F,Indent:Integer;
    SS:String;
    C:TStringList;
begin
     WriteLn(S,Format('%sasserta(%s(''%s'',''%s'',''%s'',''%s'')),',
                      [Prefix,proShow,
                       Ident,
                       BoolVals[(Flags And flShowClass)<>0],
                       BoolVals[(Flags And flShowName)<>0],
                       BoolVals[(Flags And flShowImage)<>0]]));
     WriteLn(S,Format('%sasserta(%s(''%s'',%d,%d)),',[Prefix,proPosition,Ident,R.Left,R.Top]));
     With Parameters Do
       If Count=0 Then
          WriteLn(S,Format('%sasserta(%s(''%s'',0)),',[Prefix,proParameters,Ident]))
       Else
         begin
           WriteLn(S,Format('%sasserta(%s(''%s'',%d)),',[Prefix,proParameters,Ident,Count]));
           C:=TStringList.Create;
           For F:=0 To Count-1 Do
             begin
               SS:=Values[Names[F]];
               If Length(SS)>0 Then
                  begin
                    C.CommaText:=SS;
                    If C.Count=0 Then
                       SS:=''
                    Else If SS[1]='"' Then
                       begin
                         SS:=C.Text;
                         If C.Count=1 Then
                            If Copy(SS,Length(SS)-1,2)=CRLF Then
                               SetLength(SS,Length(SS)-2)
                       end
                  end;
               C.Text:=EscapeText(EncodeStr(SS),Indent);
               Write(S,Format('%sasserta(%s(''%s'',''%s'',%u,''',[Prefix,proParameter,Ident,Names[F],Indent]));
               Write(S,GetCommaText(C));
               WriteLn(S,''')),')
             end;
           C.Free
         end
end;

function TElement.GeneratePredicates(var Code, Init, Solve: String): Boolean;

function CreateCalls(Const Predicate:String):String;

Var F,G:Integer;
    Appends:String;
begin
     Result:=Predicate+'('''+Ident+''',';
     Appends:='';
     With Inputs Do
       For F:=0 To Count-1 Do
         With CollectBackLinks(TContact(Objects[F])) Do
           begin
             If Count=0 Then
                Result:=Result+'''null'','
             Else If Count=1 Then
                With forw(TLink(Items[0])._From) Do
                  Result:=Result+Owner.Ident+'_'+Ref.CntID+','
             Else
                begin
                  With TContact(Inputs.Objects[F]) Do
                    begin
                      Result:=Result+Owner.Ident+'_'+Ref.CntID+',';
                      Appends:=Appends+'=('+Owner.Ident+'_'+Ref.CntID+',['
                    end;
                  For G:=0 To Count-1 Do
                      With forw(TLink(Items[G])._From) Do
                        Appends:=Appends+Owner.Ident+'_'+Ref.CntID+',';
                  Appends[Length(Appends)]:=']';
                  Appends:=Appends+'),'
                end;
             Free
           end;
     With Outputs Do
       For F:=0 To Count-1 Do
         If TContact(Objects[F]).Links.Count=0 Then
            Result:=Result+'_,'
         Else
            Result:=Result+Ident+'_'+Strings[F]+',';
     Result[Length(Result)]:=')';
     Result:=' '+Appends+Result+','+CRLF
end;

begin
     If SubElements.Count>0 Then
        Result:=False
     Else
       begin
         Flags:=Flags Or flPredicatesGenerated;
         Result:=Ref.GenerateProlog(Code);
         Init:=Init+CreateCalls(Ref.iPredicate);
         Solve:=Solve+CreateCalls(Ref.sPredicate)
       end
end;

{ TSystem }

function TSystem.AddLink(_From, _To: TContact; var ErrMsg: String; Inf: Boolean = False): TLink;

Var Z:Integer;
begin
     Result:=Nil;
     If Not (Assigned(_From) And Assigned(_To)) Then
        ErrMsg:='One of contacts does not exist'
     Else
        If (Not AllowCycles) And (_From.Owner=_To.Owner) Then
           ErrMsg:='Loop links are not allowed'
        Else
          begin
            Result:=TLink.Create(_From,_To,Inf);
            _From.Links.Add(Result);
            _To.Links.Add(Result);
            With Result Do
              If _From.Owner=_To.Owner Then
                 begin
                   Z:=5*(_To.Owner.Inputs.IndexOfObject(_To)*_From.Owner.Outputs.Count+_From.Owner.Outputs.IndexOfObject(_From)+3);
                   SetLength(Points,4);
                   With _From.R Do
                     begin
                       Points[0].X:=Right+Z-1;
                       Points[0].Y:=(Top+Bottom) Div 2
                     end;
                   Points[1].X:=Points[0].X;
                   Points[1].Y:=_From.Owner.Area.Bottom+Z;
                   Points[2].X:=_To.R.Left-Z+1;
                   Points[2].Y:=Points[1].Y;
                   Points[3].X:=Points[2].X;
                   With _To.R Do Points[3].Y:=(Top+Bottom) Div 2
                 end
          end
end;

function TSystem.AddElement(const CID, ID: String; Flgs: Integer): TElement;

Var F:Integer;
begin
     Result:=Nil;
     If Messaging Then StrPCopy(ErrorMsg, CID+String(' - неизвестный класс'));
     For F:=0 To ElementRegList.Count-1 Do
         With TElementReg(ElementRegList.Items[F]) Do
           If CID=ClsID Then
              begin
                Result:=TElement.Create(TElementReg(ElementRegList.Items[F]),ID,Flgs);
                Elements.Add(Result)
              end
end;

procedure TSystem.ClearFlags(ClearMask:Integer);

Var F:Integer;
begin
     With Elements Do
       For F:=0 To Count-1 Do
           TElement(Items[F]).ClearFlags(ClearMask)
end;

procedure TSystem.SetFlags(SetMask:Integer);

Var F:Integer;
begin
     With Elements Do
       For F:=0 To Count-1 Do
           TElement(Items[F]).SetFlags(SetMask)
end;

constructor TSystem.Create;
begin
     Inherited Create;
     SavedName:='';
     Elements:=TObjList.Create;
     FElCounter:=0;
     Success:=True
end;

destructor TSystem.Destroy;
begin
     Elements.Free;
     Inherited
end;

function TSystem.ToString: String;

Var L: TStringList;
    F: Integer;
begin
     L := TStringList.Create;
     L.Sorted := True;
     For F := 0 To Elements.Count - 1 Do
         L.Add(TElement(Elements[F]).ToString);
     Result:=L.Text;
     L.Free
end;

function TSystem.MakeCascade(Flag: Integer; var Parameter: String): TResultType;

function Cascade(Obj:TElement):TResultType;

Var F:Integer;
    Found:Boolean;
begin
     Result:=rsOk;
     With Obj.FindConnectedByType('',[dirInput]) Do
       begin
         F:=0;
         Found:=False;
         While (F<Count) And Not Found Do
           If (TElement(Items[F]).Flags And Flag)=0 Then
              Found:=True
           Else
              Inc(F);
         Free
       end;
     If Not Found Then
        With Obj Do
          If (SubElements.Count=0) And ((Flags And Flag)=0) Then
             begin
               Case Flag Of
                 flChecked:             Result := Check;
                 flClassesGenerated:    If GeneratePHPClasses(Parameter) Then Result := rsOk Else Result := rsStrict;
                 flCallsGenerated:      If GeneratePHPCalls(Parameter) Then Result := rsOk Else Result := rsStrict;
                 flPredicatesGenerated:
                   begin
                     If GeneratePredicates(Parameter,FInitProlog,FSolveProlog) Then
                        Deductive:=True;
                     Result:=rsOk
                   end
               End;
               If Result <> rsStrict Then
                  With FindConnectedByType('',[dirOutput]) Do
                    begin
                      For F:=0 To Count-1 Do
                          begin
                            Case Cascade(TElement(Items[F])) Of
                              rsNonStrict: Result := rsNonStrict;
                              rsStrict:
                                Begin
                                  Free;
                                  Exit(rsStrict)
                                End
                            End
                          end;
                      Free
                    end
             end
end;

Var F:Integer;
begin
     Result:=rsOk;
     With Elements Do
       For F:=0 To Count-1 Do
         With TElement(Items[F]) Do
           If (SubElements.Count=0) And ((Flags And Flag)=0) Then
              With FindConnectedByType('',[dirInput]) Do
                begin
                  If (Count=0) Then
                     Begin
                       Case Cascade(TElement(Elements.Items[F])) Of
                         rsNonStrict: Result := rsNonStrict;
                         rsStrict:
                           Begin
                             Free;
                             Exit(rsStrict)
                           end
                       End;
                     End;
                  Free
                end
end;

function TSystem.GeneratePHP(var Code: String): Boolean;

Var F:Integer;
    CallsCode:String;
begin
     ClearFlags(flAllTemporary);
     If Assigned(ElementRegList) Then
        For F:=0 To ElementRegList.Count-1 Do
            With TElementReg(ElementRegList.Items[F]) Do
              begin
                Generated:=False;
                FUsed:=False
              end;
     Code:=ScriptPrepend+CRLF;
     Result:= (Check = rsOk) And (MakeCascade(flClassesGenerated,Code) = rsOk);
     If Result Then
        begin
          Code:=Code+GenerateText(
            'for ($$[0] = $$[1][0]; $$[2] > 0; $$[0] = $[3]())'+CRLF+
            '{'+CRLF,
            [idvarStage,idvarEvents,idvarNumEvents,idfunNextEvent]);
          CallsCode:='';
          Result := MakeCascade(flCallsGenerated,CallsCode) = rsOk;
          CallsCode := CallsCode +
             GenerateText(
               'if ($$[0] !== "")' + CRLF +
               '   eval($$[0]);' + CRLF,
               [idvarTape]
             );
          If Result Then
             Code:=Code+
                   ShiftRight(CallsCode,1)+
                   '}'+CRLF
        end;
     Code:=Code+ScriptPost+CRLF
end;

function TSystem.Check: TResultType;

Var Dummy:String;
begin
     ErrorMsg := '';
     ProcessedObject := Nil;
     Result:=MakeCascade(flChecked,Dummy)
end;

{$IF DEFINED(LCL) OR DEFINED(VCL)}
procedure TSystem.Draw(ExclLink:TLink; WX,WY:Integer);

Var F,G,H:Integer;
    CBuf:TCanvas;
begin
     CBuf:=Cnv;
     With Buf.Canvas Do
       begin
         Brush.Color:=clBtnFace;
         FillRect(Rect(0,0,Buf.Width,Buf.Height));
         Pen:=Cnv.Pen;
         Brush:=Cnv.Brush;
         Font:=Cnv.Font;
       end;
     Cnv:=Buf.Canvas;
     For F:=0 To Elements.Count-1 Do
         TElement(Elements[F]).Draw(WX,WY);
     For F:=0 To Elements.Count-1 Do
         With TElement(Elements[F]) Do
           For G:=0 To Outputs.Count-1 Do
             With TContact(Outputs.Objects[G]) Do
                For H:=0 To Links.Count-1 Do
                    If TLink(Links[H])<>ExclLink Then
                       DrawLink(True,TLink(Links[H]),WX,WY);
     Cnv:=CBuf;
     Cnv.Draw(0,0,Buf);
     Cnv.Pen:=Buf.Canvas.Pen;
     Cnv.Brush:=Buf.Canvas.Brush;
     Cnv.Font:=Buf.Canvas.Font
end;
{$ENDIF}

procedure LoadClasses({$IF DEFINED(LCL) OR DEFINED(VCL)}V:TTreeView{$ENDIF});

Var Sects:TStringList;
    Params:TStringList;
    Anlz:TAnalyser;

{$WARNINGS OFF}
Procedure ReadClasses(IsTop:Boolean; Const Base,Parent,This:String
  {$IF DEFINED(LCL) OR DEFINED(VCL)}; ParentNode: TTreeNode{$ENDIF});

Var {$IF DEFINED(LCL) OR DEFINED(VCL)}
    ThisNode:TTreeNode;
    {$ENDIF}
    Buf:TStringList;
    T:TSearchRec;
    Prms:StringArray;
    Nm:String;
    RefStr,iStr,sStr:String;
    Inh:Boolean;
    Prm:String;
    Req:Boolean;
    Dir:TIODirection;
    CType:TContactType;
    F:Integer;
begin
     If Not IsTop Then
        With TMemIniFile.Create(Base+IniFile) Do
          begin
            Buf:=TStringList.Create;
            GetStrings(Buf);
            Buf.Text:=DecodeStr(Buf.Text);
            SetStrings(Buf);
            Buf.Free;
            Sects.Clear;
            ReadSections(Sects);
            Nm:=ReadString(SectionDef,'Name','');
            RefStr:=ReadString(SectionDef,'Reference','');
            If Length(RefStr)>0 Then
               begin
                 If Pos('.',RefStr)=0 Then
                    RefStr:=RefToLoad+Base+SuperSlash+RefStr+'.'+DefaultExt
                 Else
                    RefStr:=RefToLoad+Base+SuperSlash+RefStr;
                 Inh:=False
               end
            Else
               begin
                 Inh:=Boolean(StrToInt(ReadString(SectionDef,'InheritScript','')));
                 RefStr:=ScriptToLoad+Base+ScrFile
               end;
            iStr:=ScriptToLoad+Base+dInitFile;
            sStr:=ScriptToLoad+Base+dSolveFile;
            Params.Clear;
            ReadSection(SectionPrms,Params);
            SetLength(Prms,Params.Count);
            With Params Do
              For F:=0 To Count-1 Do
                  begin
                    Prms[F]:=Strings[F];
                    Prm:=ReadString(SectionPrms,Strings[F],'');
                    If Length(Prm)>0 Then
                       Prms[F]:=Prms[F]+'='+Prm
                  end;
            {$IF DEFINED(LCL) OR DEFINED(VCL)}
            If Not Assigned(ParentNode) Then
               ThisNode:=V.Items.Add(Nil,This)
            Else
               ThisNode:=V.Items.AddChild(ParentNode,This);
            ThisNode.Data:=
            {$ENDIF}
            RegisterElement(Parent,This,Nm,
               RefStr,iStr,sStr,
               Base+ImgFile,
               Inh,Prms);
            SetLength(Prms,0);
            With Sects Do
              begin
                Delete(IndexOf(SectionDef));
                Delete(IndexOf(SectionPrms));
                For F:=0 To Count-1 Do
                    begin
                      Nm:=ReadString(Strings[F],'Name','');
                      If Length(Nm)>0 Then
                         begin
                           Req:=Boolean(StrToInt(ReadString(Strings[F],'Required','')));
                           Prm:=ReadString(Strings[F],'Direction','');
                           If CompareText(Prm,'Input')=0 Then Dir:=dirInput
                           Else If CompareText(Prm,'Output')=0 Then Dir:=dirOutput;
                           Prm:=ReadString(Strings[F],'Type','');
                           If CompareText(Prm,'Single')=0 Then CType:=ctSingle
                           Else If CompareText(Prm,'Many')=0 Then CType:=ctMany;
                           RegisterContact(This,Strings[F],Nm,Req,Dir,CType)
                         end;
                      Anlz.AnlzLine:=ReadString(Strings[F],'Links','');
                      With Anlz Do
                        While Not Empty Do
                          begin
                            Nm:=GetBefore(True,['\']);
                            DelFirst;
                            Prm:=GetBefore(True,[';']);
                            DelFirst;
                            RegisterLinkType(This,Strings[F],Nm,Prm)
                          end
                    end
              end;
            Free
          end
     {$IF DEFINED(LCL) OR DEFINED(VCL)}
     Else
        ThisNode:=Nil;
     {$ELSE}
     ;
     {$ENDIF}
     If FindFirst(Base+SuperSlash+'*.*',faDirectory,T)=0 Then
        begin
          Repeat
             If ((T.Attr And faDirectory)<>0) And
                (T.Name<>'.') And (T.Name<>'..') Then
                ReadClasses(False,Base+SuperSlash+T.Name,This,T.Name{$IF DEFINED(LCL) OR DEFINED(VCL)},ThisNode{$ENDIF})
          Until FindNext(T)<>0;
          FindClose(T)
        end
end;
{$WARNINGS ON}

procedure RegisterLinks(XML: TXMLDocument; Const _ClassID:String);

Const NamesOfTag: Array[TIODirection] Of PChar = (xmlPInputs,xmlPOutputs);

Var F,G,H:Integer;
    D,_El,Els,S,El: TDOMElement;
    _S: TDOMNodeList;
    Arg:String;
    _Dir:TIODirection;
    iClassID,iContID,_ContID,_ContName:String;
    ieReg:TElementReg;
    L,N:Word;
begin
     D:=XML.DocumentElement;
     Els := getFirstChild(D);
     _El := getFirstChild(Els);
     L:=StrToInt(Els.AttribStrings['NumItems']);
     For F:=0 To L-1 Do
       begin
         For _Dir:=dirInput To dirOutput Do
           Begin
             Arg:=NamesOfTag[_Dir];
             _S:=_El.GetElementsByTagName(Arg);
             If Assigned(_S) Then
               If _S.Count>0 Then
                  Begin
                    S:=getFirst(_S);
                    N:=StrToInt(S.AttribStrings['NumItems']);
                    If N>0 Then
                       Begin
                         iClassID:=_El.AttribStrings['ClassID'];
                         El:=getFirstChild(S);
                         For H:=0 To N-1 Do
                           Begin
                             iContID:=El.AttribStrings['ID'];
                             ieReg:=Nil;
                             G:=0;
                             While (G<ElementRegList.Count) And Not Assigned(ieReg) Do
                               If TElementReg(ElementRegList[G]).ClsID=iClassID Then
                                  ieReg:=TElementReg(ElementRegList[G])
                               Else
                                  Inc(G);
                             _ContID:=El.AttribStrings['PublicID'];
                             _ContName:=El.AttribStrings['PublicName'];
                             If Assigned(ieReg) Then
                                begin
                                  For G:=0 To ContactRegList.Count-1 Do
                                    With TContactReg(ContactRegList.Items[G]) Do
                                      If ElementIs(ieReg,ClsID) And (iContID=cntID) And (_Dir=Dir) Then
                                         RegisterContact(_ClassID,_ContID,_ContName,Req,Dir,CType);
                                  If _Dir=dirInput Then
                                     For G:=0 To LinkRegList.Count-1 Do
                                         With TLinkReg(LinkRegList[G]) Do
                                           begin
                                             If ElementIs(ieReg,InClsID) And (iContID=InContID) Then
                                                RegisterLinkType(OutClsID,OutContID,_ClassID,_ContID)
                                           end
                                  Else
                                     For G:=0 To LinkRegList.Count-1 Do
                                         With TLinkReg(LinkRegList[G]) Do
                                           begin
                                             If ElementIs(ieReg,OutClsID) And (iContID=OutContID) Then
                                                RegisterLinkType(_ClassID,_ContID,InClsID,InContID)
                                           end
                                end;
                             El:=getNextChild(El)
                           End
                       End
                  End
           end;
         _El:=getNextChild(_El);
       end
end;

Var FName0:String;
    F,L,C:Integer;
    parser: TDOMParser;
    src: TXMLInputSource;
    LL: TStringList;
    dom: TXMLDocument;
begin
     Sects:=TStringList.Create;
     Params:=TStringList.Create;
     Anlz:=TAnalyser.Create([],[Space,Tabulation]);
     ReadClasses(True,GetCurrentDir+ClassesDir,'',''{$IF DEFINED(LCL) OR DEFINED(VCL)},Nil{$ENDIF});
     Sects.Free;
     Params.Free;
     Anlz.Free;
     If Assigned(ElementRegList) Then
        For F:=0 To ElementRegList.Count-1 Do
          With TElementReg(ElementRegList[F]) Do
            If (Length(FScript)>0) And (FScript[1]=RefToLoad) Then
               begin
                 FName0:=Copy(FScript,2,Length(FScript)-1);
                 parser := TDOMParser.Create;
                 LL := TStringList.Create;
                 try
                   parser.Options.PreserveWhitespace := True;
                   parser.Options.Namespaces := True;
                   LL.LoadFromFile(FName0);
                   src := TXMLInputSource.Create(LL.Text);
                   try
                     parser.Parse(src, dom);
                     RegisterLinks(dom,ClsID);
                     dom.Free
                   except
                     MakeErrorCommon('XML Parsing error!');
                   end;
                 finally
                   src.Free;
                   parser.Free;
                   LL.Free
                 end;
               end
end;

function TSystem.FindElement(X, Y, WX, WY: Integer): TElement;

Var F:Integer;
begin
     Result:=Nil;
     For F:=0 To Elements.Count-1 Do
         If TElement(Elements[F]).CheckPoint(X,Y,WX,WY) Then
            Result:=TElement(Elements[F])
end;

procedure TSystem.Activate(El:TElement; Cnt: TContact; WX, WY: Integer);

Var F,G:Integer;
    Cnt1:TContact;
begin
     Cnt.State:=cstFrom;
     Cnt.Draw(WX,WY);
     For F:=0 To LinkRegList.Count-1 Do
         With TLinkReg(LinkRegList[F]) Do
           If ElementIs(El.Ref,OutClsID) And
              (Cnt.Ref.CntID=OutContID) Then
              For G:=0 To Elements.Count-1 Do
                With TElement(Elements[G]) Do
                  If ElementIs(Ref,InClsID) Then
                     begin
                       Cnt1:=InputContact[InContID];
                       Cnt1.State:=cstTo;
                       Cnt1.Draw(WX,WY)
                     end
end;

procedure TSystem.Deactivate(WX,WY:Integer);

Var G:Integer;
begin
     For G:=0 To Elements.Count-1 Do
         TElement(Elements[G]).Deactivate(WX,WY)
end;

{$IF DEFINED(LCL) OR DEFINED(VCL)}
procedure TSystem.DrawLink(DrawPoints:Boolean; L: TLink; WX, WY: Integer);

Var F:Integer;
    Line:TLines;
    PenWidth:Integer;
    PenColor:TColor;
    KX,KY,KL:Real;
begin
     If Not (Assigned(L._From.Owner.SuperElement) Or Assigned(L._To.Owner.SuperElement)) Then
        With L Do
          begin
            PenWidth:=Cnv.Pen.Width;
            PenColor:=Cnv.Pen.Color;
            If Inform Then
               Cnv.Pen.Width:=1
            Else
               Cnv.Pen.Width:=3;
            Cnv.Pen.Color:=L.Color;
            GetLine(Line);
            For F:=0 To Elements.Count-1 Do
                TElement(Elements[F]).ExcludeFromLine(Line,Line);
            For F:=0 To Length(Line)-1 Do
                With Line[F] Do
                  begin
                    Cnv.MoveTo(X1-WX,Y1-WY);
                    Cnv.LineTo(X2-WX,Y2-WY);
                    If F=Length(Line)-1 Then
                       begin
                         KX:=X2-X1;
                         KY:=Y2-Y1;
                         KL:=Norm([KX,KY]);
                         If KL>8 Then
                            begin
                              KX:=KX/KL;
                              KY:=KY/KL;
                              Cnv.LineTo(X2-WX-Round(11*KX-4*KY),Y2-WY-Round(11*KY+4*KX));
                              Cnv.MoveTo(X2-WX,Y2-WY);
                              Cnv.LineTo(X2-WX-Round(11*KX+4*KY),Y2-WY-Round(11*KY-4*KX))
                            end
                       end
                    Else
                      If DrawPoints Then
                         Cnv.Ellipse(X2-WX-2,Y2-WY-2,X2-WX+2,Y2-WY+2)
                  end;
            Cnv.Pen.Width:=PenWidth;
            Cnv.Pen.Color:=PenColor;
            SetLength(Line,0)
          end
end;
{$ENDIF}

function TSystem.FindLink(X, Y, WX, WY: Integer; var InPoint,
  InSegm: Integer): TLink;

Var F,G,H:Integer;
begin
     Result:=Nil;
     For F:=0 To Elements.Count-1 Do
       With TElement(Elements[F]) Do
         For G:=0 To Outputs.Count-1 Do
           With TContact(Outputs.Objects[G]) Do
             For H:=0 To Links.Count-1 Do
               If TLink(Links[H]).CheckPoint(X,Y,WX,WY,InPoint,InSegm) Then
                  begin
                    Result:=TLink(Links[H]);
                    Exit
                  end
end;

procedure TSystem.BindMaps(Dir:TIODirection; C:TObjStrList; ObjByID:Boolean);

Var F:Integer;
    Obj:TElement;
    CnID:String;
begin
     For F:=0 To C.Count-1 Do
       With TContact(C.Objects[F]) Do
         If Assigned(MapTo) Then
            begin
              If ObjByID Then
                 begin
                   Obj:=GetElement(PString(MapTo)^);
                   DisposeStr(PString(MapTo));
                   MapTo:=Nil
                 end
              Else
                 Obj:=TElement(Elements[Integer(MapTo)]);
              CnID:=PString(MapFrom)^;
              DisposeStr(PString(MapFrom));
              MapFrom:=Nil;
              If Dir=dirInput Then
                 MapTo:=TContact(Obj.Inputs.Objects[Obj.Inputs.IndexOf(CnID)])
              Else
                 MapTo:=TContact(Obj.Outputs.Objects[Obj.Outputs.IndexOf(CnID)]);
              MapTo.MapFrom:=TContact(C.Objects[F])
            end
end;

function TSystem.LoadFromModel(var Lang: String; const FName: String; ExtInps,
  ExtOuts: TObjStrList): Boolean;

Var S:File;

procedure ReadExtContacts(Dir:TIODirection; Ext:TObjStrList);

Var F:Integer;
    S0,S1,S2:String;
    L,N:Word;
begin
     BlockRead(S,L,SizeOf(L));
     For F:=0 To L-1 Do
       begin
         BlockRead(S,N,SizeOf(N));
         ReadStr(S); { Пропускаем ClassID }
         S0:=ReadStr(S); { CntID }
         S1:=ReadStr(S); { PublicID }
         S2:=ReadStr(S); { PublicName }
         TElement(Elements[N]).HandleExtContact(Dir,Ext,S0,S1,S2)
       end
end;

procedure ReadMaps(C:TObjStrList);

Var CID:String;
    CnID:String;
    Idx:Integer;
    N:Word;
    ContactNumber:Integer;
    ToContact:TContact Absolute ContactNumber;
begin
     Repeat
       CID:=ReadStr(S);
       If Length(CID)>0 Then
          begin
            BlockRead(S,N,SizeOf(N));
            Idx:=C.IndexOf(CID);
            CnID:=ReadStr(S);
            If Idx>=0 Then
               With TContact(C.Objects[Idx]) Do
                 begin
                   ContactNumber:=N;
                   MapTo:=ToContact;
                   MapFrom:=TContact(NewStr(CnID))
                 end
          end
     Until Length(CID)=0
end;

Var NumElems:Integer;
    NumLinks:Integer;
    E,E1:TElement;
    L:TLink;
    N:Word;
    CID,ID,ID1:String;
    F:Integer;
    ElementNumber:Integer;
    ToElement:TElement Absolute ElementNumber;
begin
     Result:=True;
     SavedName:=FName;
     Elements:=TObjList.Create;
     Assign(S,FName);
     Reset(S,1);
     Lang:=ReadStr(S);
     BlockRead(S,NumElems,SizeOf(NumElems));
     For F:=0 To NumElems-1 Do
         begin
           CID:=ReadStr(S);
           ID:=ReadStr(S);
           E:=AddElement(CID,ID,0);
           If Assigned(E) Then
              begin
                BlockRead(S,N,SizeOf(N));
                If N>0 Then
                   Begin
                     ElementNumber:=N;
                     E.SuperElement:=ToElement
                   End;
                ReadMaps(E.Inputs);
                ReadMaps(E.Outputs);
                E.ReadData(S)
              end
           Else
              begin
                MakeErrorCommon(ErrorMsg);
                Elements.Free;
                Close(S);
                Result:=False;
                Exit
              end
         end;
     For F:=0 To Elements.Count-1 Do
       begin
         E:=TElement(Elements[F]);
         If Assigned(E.SuperElement) Then
            begin
              E1:=TElement(Elements[Integer(E.SuperElement)-1]);
              E.SuperElement:=E1;
              E1.SubElements.Add(E)
            end;
         BindMaps(dirInput,E.Inputs,False);
         BindMaps(dirOutput,E.Outputs,False)
       end;
     FElCounter:=NumElems;
     BlockRead(S,NumLinks,SizeOf(NumLinks));
     For F:=0 To NumLinks-1 Do
       begin
         BlockRead(S,N,SizeOf(N));
         E:=TElement(Elements[N]);
         ID:=ReadStr(S);
         BlockRead(S,N,SizeOf(N));
         E1:=TElement(Elements[N]);
         ID1:=ReadStr(S);
         L:=AddLink(E.OutputContact[ID],E1.InputContact[ID1],CID);
         If Assigned(L) Then
            L.ReadData(S)
         Else
            begin
              MakeErrorCommon(CID);
              Elements.Free;
              Close(S);
              Result:=False;
              Exit
            end
       end;
     If Not EOF(S) Then
        begin
          ReadExtContacts(dirInput,ExtInps);
          ReadExtContacts(dirOutput,ExtOuts);
          BlockRead(S,F,SizeOf(F)); { Пропускаем длину блока внешних контактов }
        end;
     Close(S)
end;

procedure TSystem.SaveToModel(const Lang, FName: String);

Var S:File;

procedure WriteAndFreeExternals(Var C:TList);

Var F:Integer;
    L,N:Word;
begin
     L:=C.Count;
     BlockWrite(S,L,SizeOf(L));
     For F:=0 To L-1 Do
         With TContact(C.Items[F]) Do
           begin
             N:=Elements.IndexOf(Owner);
             BlockWrite(S,N,SizeOf(N));
             WriteStr(S,Ref.ClsID);
             WriteStr(S,Ref.CntID);
             WriteStr(S,PublicID);
             WriteStr(S,PublicName);
           end;
     FreeAndNil(C)
end;

procedure WriteMaps(C:TObjStrList);

Var F:Integer;
    N:Word;
begin
     For F:=0 To C.Count-1 Do
       With TContact(C.Objects[F]) Do
         If Assigned(MapTo) Then
            begin
              WriteStr(S,C.Strings[F]);
              N:=Elements.IndexOf(MapTo.Owner);
              BlockWrite(S,N,SizeOf(N));
              WriteStr(S,MapTo.Ref.CntID)
            end;
     WriteStr(S,'')
end;

Var NumElems:Integer;
    NumLinks:Integer;
    ExtInps,ExtOuts:TList;
    F,G,H:Integer;
    N:Word;
begin
     Inherited Create;
     SavedName:=FName;
     Assign(S,FName);
     Rewrite(S,1);
     NumElems:=Elements.Count;
     WriteStr(S,Lang);
     BlockWrite(S,NumElems,SizeOf(NumElems));
     NumLinks:=0;
     ExtInps:=TList.Create;
     ExtOuts:=TList.Create;
     For F:=0 To NumElems-1 Do
         With TElement(Elements[F]) Do
           begin
             WriteStr(S,Ref.ClsID);
             WriteStr(S,Ident);
             If Assigned(SuperElement) Then
                N:=Elements.IndexOf(SuperElement)+1
             Else
                N:=0;
             BlockWrite(S,N,SizeOf(N));
             WriteMaps(Inputs);
             WriteMaps(Outputs);
             WriteData(S);
             For G:=0 To Inputs.Count-1 Do
                 If TContact(Inputs.Objects[G]).External Then
                    ExtInps.Add(Inputs.Objects[G]);
             For G:=0 To Outputs.Count-1 Do
                 With TContact(Outputs.Objects[G]) Do
                   begin
                     If External Then
                        ExtOuts.Add(Outputs.Objects[G]);
                     Inc(NumLinks,Links.Count)
                   end
           end;
     BlockWrite(S,NumLinks,SizeOf(NumLinks));
     For F:=0 To NumElems-1 Do
       With TElement(Elements[F]) Do
         For G:=0 To Outputs.Count-1 Do
           With TContact(Outputs.Objects[G]) Do
             For H:=0 To Links.Count-1 Do
               With TLink(Links[H]) Do
                 begin
                   N:=Elements.IndexOf(_From.Owner);
                   BlockWrite(S,N,SizeOf(N));
                   WriteStr(S,_From.Ref.CntID);
                   N:=Elements.IndexOf(_To.Owner);
                   BlockWrite(S,N,SizeOf(N));
                   WriteStr(S,_To.Ref.CntID);
                   WriteData(S)
                 end;
     F:=FilePos(S);
     WriteAndFreeExternals(ExtInps);
     WriteAndFreeExternals(ExtOuts);
     F:=FilePos(S)-F;
     BlockWrite(S,F,SizeOf(F));
     Close(S)
end;

function TSystem.CheckID(El:TElement; const ID: String): Boolean;

Var F:Integer;
begin
     Result:=False;
     For F:=0 To Elements.Count-1 Do
       If TElement(Elements[F])<>El Then
          If TElement(Elements[F]).Ident=ID Then
             Exit;
     Result:=True
end;

function TSystem.GetElement(const ID: String): TElement;

Var F:Integer;
begin
     For F:=0 To Elements.Count-1 Do
       If TElement(Elements[F]).Ident=ID Then
          begin
            Result:=TElement(Elements[F]);
            Exit
          end;
     Result:=Nil
end;

function TSystem.CheckElementPrm(El: TElement; Prm: TParameter;
  const Val: String): Boolean;

Var F:Integer;
begin
     Result:=False;
     For F:=0 To Elements.Count-1 Do
       If (TElement(Elements[F])<>El) And
           ElementIs(TElement(Elements[F]).Ref,Prm.Definer.ClsID) Then
          With TElement(Elements[F]).Parameters Do
            If Values[Prm.Name]=Val Then
               Exit;
     Result:=True
end;

function TSystem.GetElCounter: Integer;
begin
     Inc(FElCounter);
     Result:=FElCounter
end;

procedure TSystem.AnalyzeLinkStatus(L: TLink);

Var ObjList:TList;
    LinkedObj: TElement;

function Cycled(Obj:TElement):Boolean;

Var F:Integer;
begin
     Result := Obj=LinkedObj;
     If Not (Result Or (ObjList.IndexOf(Obj)>=0)) Then
        With Obj.FindConnectedByType('',[dirOutput]) Do
          begin
            ObjList.Add(Obj);
            F:=0;
            While (F<Count) And Not Result Do
              If Cycled(TElement(Items[F])) Then
                 Result:=True
              Else
                 Inc(F);
            Free
          end
end;

begin
     ObjList:=TList.Create;
     LinkedObj:=L._From.Owner;
     If Not L.Inform Then
        L.Inform:=Cycled(L._To.Owner);
     ObjList.Free
end;

function TSystem.CheckPublicContactID(C: TContact; const NewID: String): Boolean;

Var C1:TContact;
    F,G:Integer;
begin
     Result:=False;
     For F:=0 To Elements.Count-1 Do
       With TElement(Elements[F]) Do
          begin
            For G:=0 To Inputs.Count-1 Do
              begin
                C1:=TContact(Inputs.Objects[G]);
                If (C<>C1) And C1.External And (C1.PublicID=NewID) Then
                   Exit
              end;
            For G:=0 To Outputs.Count-1 Do
              begin
                C1:=TContact(Outputs.Objects[G]);
                If (C<>C1) And C1.External And (C1.PublicID=NewID) Then
                   Exit
              end
          end;
     Result:=True
end;

procedure TSystem.SaveToXML(const Lang, FName: String);

Var S:TextFile;

procedure WriteMaps(Const Prefix,xmlName:String; C:TObjStrList);

Var F,N:Integer;
begin
     N:=0;
     For F:=0 To C.Count-1 Do
       With TContact(C.Objects[F]) Do
         If Assigned(MapTo) Then
            Inc(N);
     If N=0 Then
        WriteLn(S,Prefix,'<',xmlName,' NumItems="0"/>')
     Else
       begin
         WriteLn(S,Format('%s<%s NumItems="%d">',[Prefix,xmlName,N]));
         For F:=0 To C.Count-1 Do
           With TContact(C.Objects[F]) Do
             If Assigned(MapTo) Then
                WriteLn(S,Format('  %s<%s ID="%s" ElementID="%s" ContID="%s"/>',[Prefix,xmlIContact,C.Strings[F],MapTo.Owner.Ident,MapTo.Ref.CntID]));
         WriteLn(S,Prefix,'</',xmlName,'>');
       end
end;

procedure WritePublics(Const Prefix,xmlName:String; C:TObjStrList);

Var F,N:Integer;
begin
     N:=0;
     For F:=0 To C.Count-1 Do
       With TContact(C.Objects[F]) Do
         If External Then
            Inc(N);
     If N=0 Then
        WriteLn(S,Prefix,'<',xmlName,' NumItems="0"/>')
     Else
       begin
         WriteLn(S,Format('%s<%s NumItems="%d">',[Prefix,xmlName,N]));
         For F:=0 To C.Count-1 Do
           With TContact(C.Objects[F]) Do
             If External Then
                WriteLn(S,Format('  %s<%s ID="%s" PublicID="%s" PublicName="%s"/>',[Prefix,xmlPContact,Ref.CntID,PublicID,EncodeStr(PublicName)]));
         WriteLn(S,Prefix,'</',xmlName,'>');
       end
end;

procedure WriteLinks(Const Prefix,xmlName:String; C:TObjStrList);

Var G,H,L,K:Integer;
    RR:String;
    Flag:Boolean;
begin
     Flag:=False;
     G:=0;
     While (G<C.Count) And Not Flag Do
       If TContact(C.Objects[G]).Links.Count>0 Then
          Flag:=True
       Else
          Inc(G);
     If Not Flag Then
        WriteLn(S,Prefix,'<',xmlName,'/>')
     Else
       begin
         WriteLn(S,Prefix,'<',xmlName,'>');
         For G:=0 To C.Count-1 Do
           With TContact(C.Objects[G]) Do
             If Links.Count>0 Then
                begin
                  WriteLn(S,Format('%s <%s ID="%s">',[Prefix,xmlContact,Ref.CntID]));
                  For H:=0 To Links.Count-1 Do
                    With TLink(Links[H]) Do
                      If xmlName=xmlOLinks Then
                         begin
                           {$IF DEFINED(LCL) OR DEFINED(VCL)}
                           If Not ColorToIdent(ColorToRGB(Color),RR) Then
                              RR:='#'+IntToHex(Color,6);
                           WriteLn(S,Format('%s  <%s ElementID="%s" ContID="%s" Color="%s" Informational="%s">',[Prefix,xmlLink,_To.Owner.Ident,_To.Ref.CntID,RR,BoolVals[Inform]]));
                           {$ELSE}
                           WriteLn(S,Format('%s  <%s ElementID="%s" ContID="%s" Color="#000000" Informational="%s">',[Prefix,xmlLink,_To.Owner.Ident,_To.Ref.CntID,BoolVals[Inform]]));
                           {$ENDIF}
                           L:=Length(Points);
                           If L=0 Then
                              WriteLn(S,Format('%s   <%s NumItems="0"/>',[Prefix,xmlPoints]))
                           Else
                              begin
                                Write(S,Format('%s   <%s NumItems="%d">',[Prefix,xmlPoints,L]));
                                RR:='';
                                For K:=0 To L-1 Do
                                  RR:=RR+IntToStr(Points[K].X)+','+IntToStr(Points[K].Y)+',';
                                SetLength(RR,Length(RR)-1);
                                WriteLn(S,Format('%s</%s>',[RR,xmlPoints]))
                              end;
                           WriteLn(S,Format('%s  </%s>',[Prefix,xmlLink]))
                         end
                      Else
                         WriteLn(S,Format('%s  <%s ElementID="%s" ContID="%s" Informational="%s"/>',[Prefix,xmlLink,_From.Owner.Ident,_From.Ref.CntID,BoolVals[Inform]]));
                  WriteLn(S,Prefix,' </',xmlContact,'>')
                end;
         WriteLn(S,Prefix,'</',xmlName,'>')
       end
end;

Var NumElems:Integer;
    F:Integer;
    SS:String;
begin
     Inherited Create;
     Assign(S,FName);
     Rewrite(S);
     NumElems:=Elements.Count;
     WriteLn(S,xmlHeader);
     WriteLn(S,Format('<%s Lang="%s">',[xmlSystem,Lang]));
     If NumElems=0 Then
        WriteLn(S,Format(' <%s NumItems="0"/>',[xmlElements]))
     Else
       begin
        WriteLn(S,Format(' <%s NumItems="%d">',[xmlElements,NumElems]));
        For F:=0 To NumElems-1 Do
            With TElement(Elements[F]) Do
              begin
                If Assigned(SuperElement) Then
                   SS:=SuperElement.Ident
                Else
                   SS:='';
                WriteLn(S,Format('  <%s ClassID="%s" ParentID="%s" ID="%s" Permanent="%s">',[xmlElement,Ref.ClsID,SS,Ident,BoolVals[IdPermanent]]));
                WriteDataXML(S,'   ');
                WriteMaps('   ',xmlIInputs,Inputs);
                WriteMaps('   ',xmlIOutputs,Outputs);
                WritePublics('   ',xmlPInputs,Inputs);
                WritePublics('   ',xmlPOutputs,Outputs);
                WriteLinks('   ',xmlILinks,Inputs);
                WriteLinks('   ',xmlOLinks,Outputs);
                WriteLn(S,Format('  </%s>',[xmlElement]))
              end;
        WriteLn(S,Format(' </%s>',[xmlElements]))
       end;
     WriteLn(S,Format('</%s>',[xmlSystem]));
     Close(S)
end;

procedure TSystem.SaveToFile(const Lang, FName: String);

Var Ext:String;
begin
     Ext:=LowerCase(ExtractFileExt(FName));
     If Ext='.'+xmlExt Then
        SaveToXML(Lang,FName)
     Else If (Ext='.'+proExt) Or (Ext='.'+plExt) Then
        SaveToProlog(Lang,FName)
     Else
        SaveToModel(Lang,FName)
end;

constructor TSystem.LoadFromFile(var Lang: String; const FName: String;
  ExtInps, ExtOuts: TObjStrList);

Var Ext:String;
begin
     Inherited Create;
     Ext:=LowerCase(ExtractFileExt(FName));
     If Ext='.'+xmlExt Then
        Success:=LoadFromXML(Lang,FName,ExtInps,ExtOuts)
     Else
        Success:=LoadFromModel(Lang,FName,ExtInps,ExtOuts)
end;

function TSystem.LoadFromXML(var Lang: String; const FName: String;
  ExtInps, ExtOuts: TObjStrList): Boolean;

procedure ReadMaps(C:TObjStrList; El: TDOMElement);

Var CID:String;
    CnID:String;
    Num,F,Idx:Integer;
    _El: TDOMElement;
begin
     Num:=StrToInt(El.AttribStrings['NumItems']);
     _El:=getFirstChild(El);
     For F:=0 To Num-1 Do
       begin
         CID:=_El.AttribStrings['ID'];
         If Length(CID)>0 Then
            begin
              Idx:=C.IndexOf(CID);
              CnID:=_El.AttribStrings['ContID'];
              If Idx>=0 Then
                 With TContact(C.Objects[Idx]) Do
                   begin
                     MapTo:=TContact(NewStr(_El.AttribStrings['ElementID']));
                     MapFrom:=TContact(NewStr(CnID))
                   end
            end;
          _El:=getNextChild(_El)
       end
end;

Var parser: TDOMParser;
    src: TXMLInputSource;
    dom: TXMLDocument;
    D,_El,Els,Item,_Item,Lnk: TDOMElement;
    Lnks: TDOMNodeList;
    LN,C:Integer;
    FName0:String;
    NumElems, NumLinks:Integer;
    E,E1:TElement;
    L:TLink;
    LL: TStringList;
    S,CID,ID,ID1:String;
    F,G,H:Integer;
begin
     Result:=True;
     FName0:=FName;
     parser := TDOMParser.Create;
     LL := TStringList.Create;
     try
       parser.Options.PreserveWhitespace := True;
       parser.Options.Namespaces := True;
       LL.LoadFromFile(FName0);
       src := TXMLInputSource.Create(LL.Text);
       try
         parser.Parse(src, dom);

         SavedName:=FName;
         Elements:=TObjList.Create;
         D:=dom.documentElement;
         Lang:=D.AttribStrings['Lang'];
         Els:=getFirstChild(D);
         _El:=getFirstChild(Els);
         NumElems:=StrToInt(Els.AttribStrings['NumItems']);
         For F:=0 To NumElems-1 Do
             begin
               CID:=_El.AttribStrings['ClassID'];
               ID:=_El.AttribStrings['ID'];
               E:=AddElement(CID,ID,0);
               If Assigned(E) Then
                  begin
                    S:=_El.AttribStrings['ParentID'];
                    If Length(S)>0 Then E.SuperElement:=TElement(NewStr(S));
                    Item:=getFirst(_El.getElementsByTagName(xmlIInputs));
                    ReadMaps(E.Inputs,Item);
                    Item:=getFirst(_El.getElementsByTagName(xmlIOutputs));
                    ReadMaps(E.Outputs,Item);
                    E.ReadDataXML(_El)
                  end
               Else
                  begin
                    MakeErrorCommon(ErrorMsg);
                    Elements.Free;
                    dom.Free;
                    Result:=False;
                    Exit
                  end;
               _El:=getNextChild(_El)
             end;
         For F:=0 To Elements.Count-1 Do
           begin
             E:=TElement(Elements[F]);
             If Assigned(E.SuperElement) Then
                begin
                  E1:=GetElement(PString(E.SuperElement)^);
                  DisposeStr(PString(E.SuperElement));
                  E.SuperElement:=Nil;
                  E.SuperElement:=E1;
                  E1.SubElements.Add(E)
                end;
             BindMaps(dirInput,E.Inputs,True);
             BindMaps(dirOutput,E.Outputs,True)
           end;
         _El:=getFirstChild(Els);
         FElCounter:=NumElems;
         For F:=0 To NumElems-1 Do
           begin
             _Item:=getFirst(_El.getElementsByTagName(xmlOLinks));
             E:=TElement(Elements[F]);
             If _Item.HasChildNodes Then
                begin
                  Item:=getFirstChild(_Item);
                  While Assigned(Item) Do
                    begin
                      ID:=Item.AttribStrings['ID'];
                      Lnks:=Item.getElementsByTagName(xmlLink);
                      NumLinks:=Lnks.Count;
                      For H:=0 To NumLinks-1 Do
                        begin
                          Lnk:=TDOMElement(Lnks[H]);
                          E1:=GetElement(Lnk.AttribStrings['ElementID']);
                          ID1:=Lnk.AttribStrings['ContID'];
                          L:=AddLink(E.OutputContact[ID],E1.InputContact[ID1],CID);
                          If Assigned(L) Then
                             L.ReadDataXML(Lnk)
                          Else
                             begin
                               MakeErrorCommon(CID);
                               Elements.Free;
                               dom.Free;
                               Result:=False;
                               Exit
                             end
                        end;
                      Item:=getNextChild(Item)
                    end
                end;
             E.ReadExtContactsXML(dirInput,ExtInps,getFirst(_El.getElementsByTagName(xmlPInputs)));
             E.ReadExtContactsXML(dirOutput,ExtOuts,getFirst(_El.getElementsByTagName(xmlPOutputs)));
             _El:=getNextChild(_El)
           end;
         dom.Free
       except
         MakeErrorCommon('XML Parsing error!');
       end;
     finally
       src.Free;
       parser.Free;
       LL.Free
     end;
end;

procedure TSystem.SaveToProlog(const Lang, FName: String);

Var S:TextFile;

procedure WriteMaps(Const Ident,Prefix,proName,proContact:String; C:TObjStrList);

Var F,N:Integer;
begin
     N:=0;
     For F:=0 To C.Count-1 Do
       With TContact(C.Objects[F]) Do
         If Assigned(MapTo) Then
            Inc(N);
     If N=0 Then
        WriteLn(S,Prefix,'asserta(',proName,'(''',Ident,''',0)),')
     Else
       begin
         WriteLn(S,Format('%sasserta(%s(''%s'',%d)),',[Prefix,proName,Ident,N]));
         For F:=0 To C.Count-1 Do
           With TContact(C.Objects[F]) Do
             If Assigned(MapTo) Then
                WriteLn(S,Format('  %sasserta(%s(''%s'',''%s'',''%s'',''%s'')),',[Prefix,proContact,Ident,C.Strings[F],MapTo.Owner.Ident,MapTo.Ref.CntID]))
       end
end;

procedure WritePublics(Const Ident,Prefix,proName,proContact:String; C:TObjStrList);

Var F,N:Integer;
begin
     N:=0;
     For F:=0 To C.Count-1 Do
       With TContact(C.Objects[F]) Do
         If External Then
            Inc(N);
     If N=0 Then
        WriteLn(S,Prefix,'asserta(',proName,'(''',Ident,''',0)),')
     Else
       begin
         WriteLn(S,Format('%sasserta(%s(''%s'',%d)),',[Prefix,proName,Ident,N]));
         For F:=0 To C.Count-1 Do
           With TContact(C.Objects[F]) Do
             If External Then
                WriteLn(S,Format('  %sasserta(%s(''%s'',''%s'',''%s'',''%s'')),',[Prefix,proContact,Ident,Ref.CntID,PublicID,EncodeStr(PublicName)]))
       end
end;

procedure WriteLinks(Const Ident,Prefix,proContact,proLink:String; C:TObjStrList);

Var G,H,L,K:Integer;
    RR:String;
    Flag:Boolean;
begin
     Flag:=False;
     G:=0;
     While (G<C.Count) And Not Flag Do
       If TContact(C.Objects[G]).Links.Count>0 Then
          Flag:=True
       Else
          Inc(G);
     If Flag Then
        For G:=0 To C.Count-1 Do
          With TContact(C.Objects[G]) Do
            If Links.Count>0 Then
               begin
                 WriteLn(S,Format('%s asserta(%s(''%s'',''%s'')),',[Prefix,proContact,Ident,Ref.CntID]));
                 For H:=0 To Links.Count-1 Do
                   With TLink(Links[H]) Do
                     If proLink=proOLink Then
                        begin
                          {$IF DEFINED(LCL) OR DEFINED(VCL)}
                          If Not ColorToIdent(ColorToRGB(Color),RR) Then
                             RR:='#'+IntToHex(Color,6);
                          Write(S,Format('%s  asserta(%s(''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',',[Prefix,proLink,_From.Owner.Ident,_From.Ref.CntID,_To.Owner.Ident,_To.Ref.CntID,RR,BoolVals[Inform]]));
                          {$ELSE}
                          Write(S,Format('%s  asserta(%s(''%s'',''%s'',''%s'',''%s'',''%s'',''%s'',',[Prefix,proLink,_From.Owner.Ident,_From.Ref.CntID,_To.Owner.Ident,_To.Ref.CntID,'#000000',BoolVals[Inform]]));
                          {$ENDIF}
                          L:=Length(Points);
                          If L=0 Then
                             WriteLn(S,'0,'''')),')
                          Else
                             begin
                               Write(S,L,',''');
                               RR:='';
                               For K:=0 To L-1 Do
                                 RR:=RR+IntToStr(Points[K].X)+','+IntToStr(Points[K].Y)+',';
                               SetLength(RR,Length(RR)-1);
                               WriteLn(S,RR,''')),')
                             end
                        end
                     Else
                        WriteLn(S,Format('%s  asserta(%s(''%s'',''%s'',''%s'',''%s'',''%s'')),',[Prefix,proLink,_To.Owner.Ident,_To.Ref.CntID,_From.Owner.Ident,_From.Ref.CntID,BoolVals[Inform]]))
               end
end;

Var NumElems:Integer;
    F:Integer;
    SS:String;
begin
     Inherited Create;
     Assign(S,FName);
     Rewrite(S);
     NumElems:=Elements.Count;
     WriteLn(S,proHeader,Format('asserta(%s(''%s'')),',[proSystem,Lang]));
     If NumElems=0 Then
        WriteLn(S,Format(' asserta(%s(0)),',[proElements]))
     Else
       begin
        WriteLn(S,Format(' asserta(%s(%d)),',[proElements,NumElems]));
        For F:=0 To NumElems-1 Do
            With TElement(Elements[F]) Do
              begin
                If Assigned(SuperElement) Then
                   SS:=SuperElement.Ident
                Else
                   SS:='';
                WriteLn(S,Format('  asserta(%s(''%s'',''%s'',''%s'',''%s'')),',[proElement,Ident,Ref.ClsID,SS,BoolVals[IdPermanent]]));
                WriteDataProlog(S,'   ');
                WriteMaps(Ident,'   ',proIInputs,proIIContact,Inputs);
                WriteMaps(Ident,'   ',proIOutputs,proIOContact,Outputs);
                WritePublics(Ident,'   ',proPInputs,proPIContact,Inputs);
                WritePublics(Ident,'   ',proPOutputs,proPOContact,Outputs);
                WriteLinks(Ident,'   ',proIContact,proILink,Inputs);
                WriteLinks(Ident,'   ',proOContact,proOLink,Outputs)
              end
       end;
     WriteLn(S,' true.');
     Close(S)
end;

function TSystem.GenerateProlog(var Code: String): Boolean;

Var F:Integer;
begin
     ClearFlags(flAllTemporary);
     Deductive:=False;
     FInitProlog:='init_goal:-'+CRLF;
     FSolveProlog:='solve_goal:-'+CRLF;
     If Assigned(ElementRegList) Then
        For F:=0 To ElementRegList.Count-1 Do
            With TElementReg(ElementRegList.Items[F]) Do
              begin
                Generated:=False;
                FUsed:=False
              end;
     Result:=(Check = rsOk) And (MakeCascade(flPredicatesGenerated,Code) = rsOk);
     If Result Then
        If Length(Code)>0 Then
           Code:=PrologPrepend+Code+CRLF+
                 InitProlog+
                 ' true.'+CRLF+CRLF+
                 SolveProlog+
                 ' true.'+CRLF+CRLF+
                 'process(FName) :- '+CRLF+
                    'asserta(filename('''+StringReplace(SavedName,'\','/',[rfReplaceAll])+''')),'+CRLF+
                    '(file_exists(''_vars.php3'')->'+CRLF+
                         'unlink(''_vars.php3'');'+CRLF+
                         'true'+CRLF+
                    '),'+CRLF+
                    '(file_exists(''_base.pl'')->'+CRLF+
                         'consult(''_base.pl''),'+CRLF+
                         'rededuce,'+CRLF+
                         'unlink(''_base.pl'');'+CRLF+
                         'true'+CRLF+
                    '),'+CRLF+
                    '(file_exists(''_out.pl'')->'+CRLF+
                         'consult(''_out.pl''),'+CRLF+
                         'use_outs,'+CRLF+
                         'unlink(''_out.pl'');'+CRLF+
                         'true'+CRLF+
                    '),'+CRLF+
                    'create_model,init_goal,solve_goal,'+CRLF+
                    'tell(FName),write_xml,told,'+CRLF+
                    '(file_exists(''_base.pl'')->'+CRLF+
                        'telling(TELL),'+CRLF+
                        'append(''_base.pl''),'+CRLF+
                        'write(''true.''),'+CRLF+
                        'told,'+CRLF+
                        'tell(TELL);'+CRLF+
                        'true'+CRLF+
                    '),'+CRLF+
                    '!.'+CRLF
end;

{ TGraphicObject }

function TGraphicObject.CheckPoint(X, Y, WX, WY: Integer): Boolean;
begin
     OffsetRect(R,-WX,-WY);
     Result:=(R.Left<=X) And (X<=R.Right) And (R.Top<=Y) And (Y<=R.Bottom);
     OffsetRect(R,WX,WY)
end;

constructor TGraphicObject.Create(_R: TRect);
begin
     Inherited Create;
     R:=_R
end;

procedure TGraphicObject.Move(_X, _Y: Integer);
begin
     If (R.Left<>_X) Or (R.Top<>_Y) Then
        begin
          R.Left:=_X;
          R.Top:=_Y
        end
end;

procedure TGraphicObject.SetPosition(_X, _Y, _EX, _EY: Integer);
begin
     R:=Rect(_X,_Y,_EX,_EY)
end;

{ TParameter }

destructor TParameter.Destroy;
begin
     Selector.Free;
     Inherited
end;

Initialization
  {$IF DEFINED(LCL) OR DEFINED(VCL)}
  Buf:=TBitmap.Create;
  {$ENDIF}
  OutModelName := '';
  Versions:=TStringList.Create;
  Versions.Sorted := True;

Finalization
  {$IF DEFINED(LCL) OR DEFINED(VCL)}
  FreeAndNil(Buf);
  {$ENDIF}
  FreeAndNil(Versions);

end.

