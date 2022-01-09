unit EditList;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses {$IFDEF FPC}LCLIntf,{$ENDIF} SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls, ActnList{$IFDEF FPC}, LResources{$ENDIF};

type
  TEditListDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    Bevel: TBevel;
    ObjsGroup: TGroupBox;
    Objs: TListBox;
    SelectedGroup: TGroupBox;
    Selected: TListBox;
    SelectAll: TSpeedButton;
    SelectOne: TSpeedButton;
    DeselectOne: TSpeedButton;
    DeselectAll: TSpeedButton;
    ActionList: TActionList;
    actSelectAll: TAction;
    actSelectOne: TAction;
    actDeselectOne: TAction;
    actDeselectAll: TAction;
    procedure actSelectAllUpdate(Sender: TObject);
    procedure actDeselectAllUpdate(Sender: TObject);
    procedure actSelectOneUpdate(Sender: TObject);
    procedure actDeselectOneUpdate(Sender: TObject);
    procedure actSelectAllExecute(Sender: TObject);
    procedure actSelectOneExecute(Sender: TObject);
    procedure actDeselectOneExecute(Sender: TObject);
    procedure actDeselectAllExecute(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditListDlg: TEditListDlg;

implementation


procedure MoveSelected(Src,Dst:TListBox);

Var F:Integer;
begin
     F:=0;
     While F<Src.Items.Count Do
       If Src.Selected[F] Then
          begin
            Dst.Items.Add(Src.Items.Strings[F]);
            Src.Items.Delete(F)
          end
       Else
          Inc(F)
end;

procedure TEditListDlg.actSelectAllUpdate(Sender: TObject);
begin
     actSelectAll.Enabled:=Objs.Items.Count>0
end;

procedure TEditListDlg.actDeselectAllUpdate(Sender: TObject);
begin
     actDeselectAll.Enabled:=Selected.Items.Count>0
end;

procedure TEditListDlg.actSelectOneUpdate(Sender: TObject);
begin
     actSelectOne.Enabled:=Objs.SelCount>0
end;

procedure TEditListDlg.actDeselectOneUpdate(Sender: TObject);
begin
     actDeselectOne.Enabled:=Selected.SelCount>0
end;

procedure TEditListDlg.actSelectAllExecute(Sender: TObject);
begin
     Selected.Items.AddStrings(Objs.Items);
     Objs.Clear
end;

procedure TEditListDlg.actSelectOneExecute(Sender: TObject);
begin
     MoveSelected(Objs,Selected)
end;

procedure TEditListDlg.actDeselectOneExecute(Sender: TObject);
begin
     MoveSelected(Selected,Objs)
end;

procedure TEditListDlg.actDeselectAllExecute(Sender: TObject);
begin
     Objs.Items.AddStrings(Selected.Items);
     Selected.Clear
end;

initialization
  {$IFDEF FPC}
  {$i EditList.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
