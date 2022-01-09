unit ContDlg;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses {$IFDEF FPC}LCLIntf,{$ENDIF} SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ActnList, Dialogs, Elements{$IFDEF FPC}, LResources{$ENDIF};

type

  { TContactDlg }

  TContactDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    chkPublic: TCheckBox;
    ActionList: TActionList;
    OKAction: TAction;
    GroupBox: TGroupBox;
    Label1: TLabel;
    edID: TEdit;
    Label2: TLabel;
    edName: TEdit;
    procedure OKActionUpdate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
  private
    { Private declarations }
  public
    { Public declarations }
    RefSys: TSystem;
    RefC: TContact;
  end;

var
  ContactDlg: TContactDlg;

implementation


procedure TContactDlg.OKActionUpdate(Sender: TObject);
begin
     edID.Enabled:=chkPublic.Checked;
     edName.Enabled:=chkPublic.Checked;
     OKAction.Enabled:=((Length(edID.Text)>0) And
                        (Length(edName.Text)>0) And
                        IsValidIdent(edID.Text)
                       ) Or Not chkPublic.Checked
end;

procedure TContactDlg.FormCreate(Sender: TObject);
begin
     RefSys:=Nil;
     RefC:=Nil
end;

procedure TContactDlg.FormCloseQuery(Sender: TObject;
  var CanClose: Boolean);
begin
     If ModalResult=mrOk Then
        If Assigned(RefSys) And Assigned(RefC) And chkPublic.Checked Then
           If Not RefSys.CheckPublicContactID(RefC,edID.Text) Then
              begin
                MessageDlg('В системе уже опубликован контакт с таким именем',mtError,[mbOk],0);
                CanClose:=False
              end
end;

initialization
  {$IFDEF FPC}
  {$i ContDlg.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
