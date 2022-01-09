unit EditEl;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF} Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Elements, Math, Buttons, AutoConsts {$IFDEF FPC},LResources{$ENDIF};

type
  TEditProps = class(TForm)
    edtIdent: TEdit;
    IdentLabel: TLabel;
    OKBtn: TButton;
    CancelBtn: TButton;
    chkPermanent: TCheckBox;
    ItemsComboBox: TComboBox;
    ItemsLabel: TLabel;
    ItemEdit: TSpeedButton;
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure ItemEditClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    _El:TElement;
    _LockID:Boolean;
    PrmLists:TStringList;

    procedure EditTextClick(Sender: TObject);
    procedure EditListClick(Sender: TObject);
  public
    { Public declarations }
    procedure PutData(El:TElement; LockID:Boolean);
    function  Process(Get:Boolean; El:TElement):Boolean;
  end;

implementation

uses EditTxtDlg, Main, EditList, AutoUtils, LEXIQUE;


{ TEditProps }

function TEditProps.Process(Get:Boolean; El: TElement):Boolean;

Var C:TComponent;
    Txt:String;
    F:Integer;
begin
     If Get Then
        begin
          If El.Ident<>edtIdent.Text Then
             begin
               El.ChangeSubIDs(El.Ident,edtIdent.Text);
               El.Ident:=edtIdent.Text
             end;
          El.IdPermanent:=chkPermanent.Checked
        end;
     With El.Parameters Do
       For F:=0 To Count-1 Do
         If Not (Objects[F] As TParameter).Hidden Then
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
              If Get Then
                 If Length(Txt)=0 Then
                    Strings[F]:=Names[F]+'='
                 Else
                    Values[Names[F]]:=Txt;
              C.Free
            end;
     Result:=Get
end;

procedure TEditProps.PutData(El: TElement; LockID:Boolean);

Const NormWidth = 225;
      NormGap   = 11;
      NormGap2  = NormGap*2;

Var NY: Word;
    CurX: Word;
    H:Word;
    F,G:Integer;
    E:TWinControl;
    L:TLabel;
    Z:TSpeedButton;
    SubEl:TElement;
    SubName:String;
    NVisible:Integer;
    CObjs: TList;
    Widths: Array[0..19] Of Integer;
    SWidth: Integer;
    Prm:TParameter;
begin
     PrmLists.Clear;
     Width:=NormWidth+NormGap2;
     Caption:='Параметры "'+El.Ident+'"';
     _LockID:=LockID;
     _El:=El;
     edtIdent.Text:=El.Ident;
     chkPermanent.Checked:=El.IdPermanent;
     H:=IdentLabel.Height+Max(ItemsComboBox.Height,edtIdent.Height)+{$IFDEF FPC}4{$ELSE}2{$ENDIF};
     ActiveControl:=edtIdent;
     With El Do
       begin
         NVisible:=0;
         With Parameters Do
           For F:=0 To Count-1 Do
             With Objects[F] As TParameter Do
               If Not Hidden Then
                  Inc(NVisible);
         CObjs:=TList.Create;
         NY:=(Screen.Height-(Height-ClientHeight)-2*NormGap2-OKBtn.Height) Div H;
         ClientHeight:=OKBtn.Height+H*Min(NVisible+1,NY)+10;
         G:=0;
         Widths[0]:=NormWidth;
         CurX:=IdentLabel.Left;
         With Parameters Do
           For F:=0 To Count-1 Do
             begin
               Prm:=Objects[F] As TParameter;
               If Not Prm.Hidden Then
                  begin
                    L:=TLabel.Create(Self);
                    L.Visible:=False;
                    L.Name:='L'+IntToStr(F);
                    L.Parent:=Self;
                    L.Left:=CurX;
                    L.Top:=IdentLabel.Top+((G+1) Mod NY)*H;
                    If Length(Prm.Caption)=0 Then
                       L.Caption:=Names[F]
                    Else
                       L.Caption:=Prm.Caption+' ['+Names[F]+']';
                    {$IFDEF FPC}
                    L.AutoSize:=False;
                    L.Width:=Canvas.TextWidth(L.Caption);
                    {$ELSE}
                    L.AutoSize:=True;
                    {$ENDIF}
                    L.Visible:=True;
                    If L.Width>Widths[(G+1) Div NY] Then
                       Widths[(G+1) Div NY]:=L.Width;
                    If Prm.Multiline Or (Assigned(Prm.Selector) And (Length(Prm.Conjunctor)=0)) Then
                       E:=TComboBox.Create(Self)
                    Else
                       E:=TEdit.Create(Self);
                    If Length(Prm.Conjunctor)>0 Then
                       PrmLists.AddObject(IntToHex(Integer(E),8),Prm);
                    CObjs.Add(E);
                    E.Visible:=False;
                    E.Name:='E'+IntToStr(F);
                    E.Parent:=Self;
                    E.Left:=CurX;
                    E.Top:=edtIdent.Top+((G+1) Mod NY)*H;
                    E.Width:=edtIdent.Width;
                    E.TabOrder:=G+1;
                    If Prm.Multiline Then
                       With TComboBox(E) Do
                         begin
                           Style:=csDropDownList;
                           Items.CommaText:=Values[Names[F]];
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
                    Else If Length(Prm.Conjunctor)<>0 Then
                       With TEdit(E) Do
                         begin
                           Text:=Values[Names[F]];
                           Z:=TSpeedButton.Create(E);
                           Z.Parent:=Self;
                           Z.Caption:='...';
                           Z.Height:=Height;
                           Z.Width:=Height;
                           Z.Top:=Top;
                           Z.Tag:=Integer(E);
                           Z.OnClick:=EditListClick;
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
                                ItemIndex:=Prm.Selector.IndexOf(Values[Names[F]]);
                                If ItemIndex<0 Then
                                   Text:=Items[ItemIndex]
                              end
                         end
                    Else
                       TEdit(E).Text:=Values[Names[F]];
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
         edtIdent.Width:=Widths[0];
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
           end
       end;
     Position:=poDesigned;
     Width:=Max(Width,SWidth+NormGap2);
     With El Do
       If SubElements.Count>0 Then
          begin
            ItemsLabel.Show;
            With ItemsComboBox Do
              begin
                Items.Clear;
                Sorted:=True;
                For F:=0 To SubElements.Count-1 Do
                  begin
                    SubEl:=TElement(SubElements[F]);
                    If SubEl.IdPermanent Then
                       SubName:=SubEl.Ident
                    Else
                      If Copy(SubEl.Ident,1,Length(Ident))=Ident Then
                        SubName:=Copy(SubEl.Ident,Length(Ident)+2,1000)
                      Else
                        SubName:=SubEl.Ident;
                    Items.AddObject(SubName+' ['+SubEl.Ref.Name+']',TObject(SubEl))
                  end;
                ItemIndex:=0;
                Show
              end;
            ItemEdit.Show;
            ClientHeight:=112
          end;
     edtIdent.Enabled:=Not LockID;
     chkPermanent.Enabled:=Not LockID;
     Position:=poScreenCenter
end;

procedure TEditProps.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);

Var F:Integer;
    C:TComponent;
    Txt: String;
begin
     If ModalResult=mrOk Then
        If Not IsValidIdent(edtIdent.Text) Then
           begin
             CanClose:=False;
             MessageDlg('Недопустимый идентификатор',mtError,[mbOk],0)
           end
        Else If Not MainSys.CheckID(_El,edtIdent.Text) Then
           begin
             CanClose:=False;
             MessageDlg('Объект с таким идентификатором уже существует',mtError,[mbOk],0)
           end
        Else
           With _El.Parameters Do
             For F:=0 To Count-1 Do
               With Objects[F] As TParameter Do
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
                              CanClose:=False;
                              MessageDlg('Не заполнен обязательный параметр "'+
                                 (FindComponent('L'+IntToStr(F)) As TLabel).Caption+
                                 '"',mtError,[mbOk],0);
                              Exit
                            end;
                      If Unique Then
                         If Not MainSys.CheckElementPrm(_El,Objects[F] As TParameter,Txt) Then
                            begin
                              CanClose:=False;
                              MessageDlg('Уже существует элемент с таким значением параметра "'+
                                 (FindComponent('L'+IntToStr(F)) As TLabel).Caption+
                                 '"',mtError,[mbOk],0);
                              Exit
                            end
                    end
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

procedure TEditProps.ItemEditClick(Sender: TObject);

Var SubEl:TElement;
begin
     With ItemsComboBox Do
       SubEl:=TElement(Items.Objects[ItemIndex]);
     With TEditProps.Create(Self) Do
       begin
         PutData(SubEl,True);
         If Process(ShowModal=mrOk,SubEl) Then
            MainForm.Saved:=False;
         Free
       end
end;

procedure TEditProps.EditListClick(Sender: TObject);

Var F,G:Integer;
    C:TParameter;
    CC:TStringList;
    S:String;
begin
     With EditListDlg Do
       begin
         ActiveControl:=Objs;
         Objs.Clear;
         Selected.Clear;
         With PrmLists Do
           C:=Objects[IndexOf(IntToHex(TSpeedButton(Sender).Tag,8))] As TParameter;
         For F:=0 To C.Selector.Count-1 Do
           begin
             S:=C.Selector.Strings[F];
             With MainSys Do
               For G:=0 To Elements.Count-1 Do
                 With TElement(Elements[G]) Do
                   If ElementIs(Ref,S) Then
                      Objs.Items.Add(Ident)
           end;
         CC:=Explode(TEdit(TSpeedButton(Sender).Tag).Text,C.Conjunctor);
         Selected.Items.Assign(CC);
         With Selected.Items Do
           For F:=0 To Count-1 Do
             begin
               G:=Objs.Items.IndexOf(Strings[F]);
               If G>=0 Then Objs.Items.Delete(G)
             end;
         If ShowModal=mrOk Then
            TEdit(TSpeedButton(Sender).Tag).Text:=Implode(Selected.Items,C.Conjunctor)
       end
end;

procedure TEditProps.FormCreate(Sender: TObject);
begin
     PrmLists:=TStringList.Create
end;

procedure TEditProps.FormDestroy(Sender: TObject);
begin
     PrmLists.Free
end;

initialization
  {$IFDEF FPC}
  {$i EditEl.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
