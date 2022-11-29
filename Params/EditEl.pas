unit EditEl;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF} Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Math, Buttons {$IFDEF FPC},LResources{$ENDIF}, types;

Const
  mdfLock      = 'LOCK';
  mdfHide      = 'HIDE';
  mdfRequired  = 'REQUIRED';

  prmSelector  = 'SELECTOR';
  prmInput     = 'INPUT';
  prmText      = 'TEXT';

type
  TParameter = class
    Name, DefValue: String;
    Caption: String;
    Selector: TStringList;
    Multiline: Boolean;
    Locked: Boolean;
    Hidden: Boolean;
    Required: Boolean;

    destructor Destroy; override;
  End;

  ParamArray = Array Of TParameter;

  { TEditProps }

  TEditProps = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    procedure CancelBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
  private
    { Private declarations }
    _El:ParamArray;

    procedure EditTextClick(Sender: TObject);
  public
    { Public declarations }
    procedure PutData(Const DefsFName: String);
    procedure Process(Const OutFName: String);
  end;

Var EditProps: TEditProps;

implementation

uses EditTxtDlg, LEXIQUE;

{ TEditProps }

destructor TParameter.Destroy;
begin
     Selector.Free;
     Inherited
end;

function CreateParam(Const ItemID, _S: String): TParameter;

Var Keyword:String;
begin
     Result := TParameter.Create;
     With TAnalyser.Create(LettersSet+[Underscore],[Space,Tabulation]) Do
       begin
         Result.Caption:='';
         Result.Selector:=Nil;
         Result.Multiline:=False;
         Result.Locked:=False;
         Result.Hidden:=False;
         AnlzLine:=_S;
         If IsNext(LeftFBracket) Then
            If Check(LeftFBracket) Then
               begin
                 While Not (IsNextSet([RightFBracket,SemiColon]) Or Error) Do
                   begin
                     Keyword:=GetIdent;
                     If Keyword=mdfLock Then
                        Result.Locked:=True
                     Else If Keyword=mdfHide Then
                        Result.Hidden:=True
                     Else If Keyword=mdfRequired Then
                        Result.Required:=True
                     Else
                        MakeError('Неизвестный модификатор "'+Keyword+
                          '" в определении параметров элемента '+ItemID);
                     If IsNext(Plus) Then DelFirst
                   end;
                 If IsNext(SemiColon) And Not Error Then
                   begin
                     DelFirst;
                     Keyword:=GetIdent;
                     If Keyword=prmSelector Then
                        begin
                          Result.Selector:=TStringList.Create;
                          If Check(LeftBracket) Then
                             begin
                               Repeat
                                 Keyword:=GetString(Quote,Quote);
                                 If Not Error Then
                                    begin
                                      Result.Selector.Add(Keyword);
                                      If IsNext(Comma) Then DelFirst
                                    end
                               Until IsNext(RightBracket) Or Error;
                               Check(RightBracket)
                             end
                        end
                     Else If Keyword=prmText Then
                        Result.Multiline:=True
                     Else If (Length(Keyword)=0) Or (Keyword=prmInput) Then
                        Result.Selector:=Nil
                     Else
                        MakeError('Неизвестный тип "'+Keyword+
                          '" в определении параметров элемента '+ItemID);
                     If (Not Error) And IsNext(SemiColon) Then
                        begin
                          Check(SemiColon);
                          Result.Caption:=GetString(Quote,Quote)
                        end
                   end;
                 If Error Then GetBefore(True,[RightFBracket])
                 Else Check(RightFBracket)
               end;
         DelSpaces;
         Result.Name:=GetBefore(True,[Equal]);
         If Empty Then
            Result.DefValue:=''
         Else
            begin
              Check(Equal);
              DelSpaces;
              Result.DefValue:=GetAll
            end;
         Free
       end
end;

Function GetCommaText(Const S: TStrings): String;

Var F:Integer;
begin
     Result:='';
     With S Do
       For F:=0 To Count-1 Do
         Begin
           If F>0 Then Result:=Result+',';
           Result:=Result+AnsiQuotedStr(Strings[F],'"')
         End
end;

procedure TEditProps.Process(Const OutFName: String);

Var C:TComponent;
    FF: TextFile;
    Txt:String;
    F:Integer;
begin
     AssignFile(FF, OutFName);
     Rewrite(FF);
     For F:=0 To Length(_El)-1 Do
       With _El[F] Do
         If Not Hidden Then
            begin
              FindComponent('L'+IntToStr(F)).Free;
              C:=FindComponent('E'+IntToStr(F));
              If C Is TEdit Then
                 Txt:=(C As TEdit).Text
              Else If C Is TComboBox Then
                 With TComboBox(C) Do
                   If Tag=0 Then
                      Txt:=Text
                   Else
                      Txt:=GetCommaText(Items)
              Else
                 Txt:='';
              WriteLn(FF, Txt);
              C.Free
            end;
     CloseFile(FF)
end;

procedure TEditProps.PutData(Const DefsFName: String);

Const NormWidth = 225;
      NormGap   = 11;
      NormGap2  = NormGap*2;

Var FD: TextFile;
    NY: Word;
    CurX: Word;
    H:Word;
    F,G:Integer;
    E:TWinControl;
    L:TLabel;
    Z:TSpeedButton;
    NVisible:Integer;
    CObjs: TList;
    Widths: Array[0..19] Of Integer;
    SWidth: Integer;
    Prm:TParameter;
    ID, S, S1: String;
begin
     AssignFile(FD, DefsFName);
     Reset(FD);
     H := 0;
     While Not Eof(FD) Do
        begin
          ReadLn(FD, S);
          ReadLn(FD, S);
          ReadLn(FD, S);
          Inc(H)
        end;

     Reset(FD);
     SetLength(_El, H);
     For F := 0 To H-1 Do
       begin
         ReadLn(FD, ID); // ID
         ReadLn(FD, S); // Descriptor without {}
         S1 := LeftFBracket + S + RightFBracket + Space + ID + '=';
         ReadLn(FD, S); // Default value
         _El[F] := CreateParam(ID, S1 + S)
       end;
     CloseFile(FD);

     Width:=NormWidth+NormGap2;
     Caption:='Параметры эксперимента';
     H:=13(*LABEL*)+Max(21(*COMBOBOX HEIGHT*),21(*EDIT CONTROL*))+{$IFDEF FPC}4{$ELSE}2{$ENDIF};

     NVisible := 0;
     For F:=0 To Length(_El)-1 Do
       With _El[F] Do
         If Not Hidden Then
            Inc(NVisible);
     CObjs:=TList.Create;
     NY:=(Screen.Height-(Height-ClientHeight)-2*NormGap2-OKBtn.Height) Div H;
     ClientHeight:=OKBtn.Height+H*Min(NVisible,NY)+10;
     G:=-1;
     Widths[0]:=NormWidth;
     CurX:=8;
     For F:=0 To Length(_El)-1 Do
       begin
         Prm:=_El[F];
         If Not Prm.Hidden Then
            begin
              L:=TLabel.Create(Self);
              L.Visible:=False;
              L.Name:='L'+IntToStr(F);
              L.Parent:=Self;
              L.Left:=CurX;
              L.Top:=2+((G+1) Mod NY)*H;
              If Length(Prm.Caption)=0 Then
                 L.Caption:=Prm.Name
              Else
                 L.Caption:=Prm.Caption+' ['+Prm.Name+']';
              {$IFDEF FPC}
              L.AutoSize:=False;
              L.Width:=Canvas.TextWidth(L.Caption);
              {$ELSE}
              L.AutoSize:=True;
              {$ENDIF}
              L.Visible:=True;
              If L.Width>Widths[(G+1) Div NY] Then
                 Widths[(G+1) Div NY]:=L.Width;
              If Prm.Multiline Or Assigned(Prm.Selector) Then
                 E:=TComboBox.Create(Self)
              Else
                 E:=TEdit.Create(Self);
              CObjs.Add(E);
              E.Visible:=False;
              E.Name:='E'+IntToStr(F);
              E.Parent:=Self;
              E.Left:=CurX;
              E.Top:=16+((G+1) Mod NY)*H;
              E.Width:=225;
              E.TabOrder:=G+1;
              If Prm.Multiline Then
                 With TComboBox(E) Do
                   begin
                     Style:=csDropDownList;
                     Items.CommaText:=Prm.DefValue;
                     If Items.Count>0 Then ItemIndex:=0;
                     Z:=TSpeedButton.Create(E);
                     Z.Parent:=Self;
                     Z.Caption:='...';
                     Z.Height:=Height;
                     Z.Width:=Height;
                     Z.Top:=Top;
                     Z.Tag:=Integer(E);
                     Z.OnClick:=EditTextClick;
                     Tag:=Integer(Z);
                     Z.Enabled:=Not Prm.Locked;
                     Z.Visible:=True
                   end
              Else If Assigned(Prm.Selector) Then
                 With TComboBox(E) Do
                   begin
                     Style:=csDropDownList;
                     Items.Assign(Prm.Selector);
                     If Prm.Selector.Count>0 Then
                        begin
                          ItemIndex:=Prm.Selector.IndexOf(Prm.DefValue);
                          If ItemIndex<0 Then
                             Text:=Items[ItemIndex]
                        end
                   end
              Else
                 TEdit(E).Text:=Prm.DefValue;
              E.Enabled:=Not Prm.Locked;
              E.Visible:=True;
              Inc(G);
              If ((G+1) Mod NY)=0 Then
                 begin
                   Inc(CurX,Widths[G Div NY]+NormGap);
                   Widths[(G+1) Div NY]:=NormWidth
                 end
            end
       end;
     With CObjs Do
       For F:=0 To Count-1 Do
         If TComboBox(Items[F]).Tag<>0 Then
            With TComboBox(Items[F]) Do
              begin
                Width:=Widths[(F+1) Div NY]-TSpeedButton(Tag).Width;
                TSpeedButton(Tag).Left:=Left+Width
              end
         Else
            TControl(Items[F]).Width:=Widths[(F+1) Div NY];
     With CObjs Do
       begin
         If Count=0 Then
            SWidth:=NormWidth
         Else
            begin
              SWidth:=TControl(Items[Count-1]).Left+TControl(Items[Count-1]).Width-TControl(Items[0]).Left;
              If TControl(Items[Count-1]).Tag<>0 Then
                 Inc(SWidth,TSpeedButton(TControl(Items[Count-1]).Tag).Width)
            end;
         Free
       end;
     Position:=poDesigned;
     Width:=Max(Width,SWidth+NormGap2);
     Position:=poScreenCenter
end;

procedure TEditProps.CancelBtnClick(Sender: TObject);
begin
     ModalResult := mrCancel;
     Close
end;

procedure TEditProps.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
     if ModalResult <> mrOk Then
        DeleteFile(ParamStr(2))
end;

procedure TEditProps.EditTextClick(Sender: TObject);
begin
     With EditTextDlg, TComboBox(TSpeedButton(Sender).Tag) Do
       begin
         ActiveControl:=TextMemo;
         TextMemo.Text:=Items.Text;
         If ShowModal=mrOk Then
            begin
              Items.Text:=TextMemo.Text;
              If Items.Count>0 Then ItemIndex:=0
            end
       end
end;

procedure TEditProps.FormCreate(Sender: TObject);
begin
     PutData(ParamStr(1))
end;

procedure TEditProps.FormDestroy(Sender: TObject);
begin
     SetLength(_El, 0)
end;

procedure TEditProps.OKBtnClick(Sender: TObject);

Var F:Integer;
    C:TComponent;
    Txt: String;
begin
     For F:=0 To Length(_El)-1 Do
       With _El[F] Do
         If Not Hidden Then
            begin
              C:=FindComponent('E'+IntToStr(F));
              If C Is TEdit Then
                 Txt:=(C As TEdit).Text
              Else If C Is TComboBox Then
                 Txt:=(C As TComboBox).Text
              Else
                 Txt:='';
              If Required Then
                 If Length(Txt)=0 Then
                    begin
                      MessageDlg('Не заполнен обязательный параметр "'+
                         (FindComponent('L'+IntToStr(F)) As TLabel).Caption+
                         '"',mtError,[mbOk],0);
                      Exit
                    end
            end;
     Process(ParamStr(2));
     ModalResult := mrOk;
     Close
end;

initialization
  {$IFDEF FPC}
  {$i EditEl.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
