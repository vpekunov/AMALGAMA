unit AutoUtils;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

Uses Classes, Elements, Common, dom;

Type TElements = Array[0..10000] Of TElement;
     PElements = ^TElements;

Function FindElementRegByID(Const ClassID: String): TElementReg;

function ElementIs(Ref:TElementReg; Const IsClsID:String): Boolean;

function ExistClass(Const ClsID:String):Boolean;

procedure CreateContacts(Const ClassID: String; _Dir: TIODirection; dom: TXMLDocument; Parent: TDOMElement; Tag: PChar);

Function CanReach(Sys: TSystem; _From: TElement; nTo: Integer; _To: PPointerList): Boolean;

function  RegisterElement(Const PClsID, ClsID, Nm, Scrpt, iScrpt, sScrpt, Img:String;
     Inh:Boolean; Const Prms: StringArray):TElementReg;

procedure RegisterContact(Const ClsID:String; Const CntID, Name:String;
     Req:Boolean; Dir:TIODirection; CT:TContactType);

procedure RegisterLinkType(Const OutClsID, OutContID, InClsID, InContID:String);

function GenerateText(Const Pattern:String; Vals: Array Of Const): String;

Const ElementRegList: TObjList = Nil;
      ContactRegList: TObjList = Nil;
      LinkRegList: TObjList = Nil;

implementation

Uses SysUtils{$IF DEFINED(LCL) OR DEFINED(VCL)}{$IFDEF FPC}, LCLIntf{$ENDIF}{$ENDIF}, xpathingIntrf, AutoConsts;

procedure CreateContacts(Const ClassID: String; _Dir: TIODirection; dom: TXMLDocument; Parent: TDOMElement; Tag: PChar);

Var F: Integer;
    Ref: TElementReg;
Begin
   Ref := Nil;
   For F:=0 To ElementRegList.Count-1 Do
       If ClassID = TElementReg(ElementRegList.Items[F]).ClsID Then
          Begin
             Ref := TElementReg(ElementRegList.Items[F]);
             Break
          End;

   If Not Assigned(Ref) Then Exit;

   For F:=0 To ContactRegList.Count-1 Do
       With TContactReg(ContactRegList.Items[F]) Do
         If ElementIs(Ref,ClsID) And (_Dir = Dir) Then
            CreateDOMContact(dom, Parent, Tag, PChar(CntID))
End;

Function CanReach(Sys: TSystem; _From: TElement; nTo: Integer; _To: PPointerList): Boolean;

  function Reach(Obj: TElement):Boolean;

  Var F:Integer;
  begin
       obj.SetFlags(flChecked);
       F := 0;
       Result := False;
       While (F < nTo) And Not Result Do
         If _To^[F] = Obj Then
            Result := True
         Else
            Inc(F);
       If Not Result Then
          With Obj.FindConnectedByType('',[dirOutput]) Do
            begin
              F:=0;
              While (F<Count) And Not Result Do
                If (TElement(Items[F]).Flags And flChecked) = 0 Then
                   If Reach(TElement(Items[F])) Then
                      Result:=True
                   Else
                      Inc(F)
                Else
                   Inc(F);
              Free
            end
  end;

Begin
     Sys.ClearFlags(flChecked);
     Result := Reach(_From);
     Sys.ClearFlags(flChecked)
end;

Function FindElementRegByID(Const ClassID: String): TElementReg;

Var F: Integer;
begin
  For F:=0 To ElementRegList.Count-1 Do
      If TElementReg(ElementRegList[F]).ClsID = ClassID Then
         Exit(TElementReg(ElementRegList[F]));
  Result := Nil
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

Initialization

Finalization
     ElementRegList.Free;
     ContactRegList.Free;
     LinkRegList.Free
end.
