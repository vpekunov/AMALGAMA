unit LearnTrouble;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF} Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ShellApi, Buttons, ExtCtrls, ComCtrls, Windows{$IFDEF FPC}, LResources{$ENDIF}, types;

type

  { TLearnTroubleForm }

  TLearnTroubleForm = class(TForm)
    EditMemo: TMemo;
    OKBtn: TBitBtn;
    CancelBtn: TBitBtn;
    ListBox: TListBox;
    ModeBtn: TSpeedButton;
    procedure EditMemoChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ModeBtnClick(Sender: TObject);
  private
    { private declarations }
    FProblemLine: String;
  public
    { public declarations }
    property ProblemLine: String read FProblemLine write FProblemLine;
  end;

var
  LearnTroubleForm: TLearnTroubleForm;

function EditTroubles(Const ClsID:String; Var Txt: String; Const TroubleLine: String): Boolean;

implementation

function EditTroubles(Const ClsID:String; var Txt: String; const TroubleLine: String): Boolean;
begin
  LearnTroubleForm := TLearnTroubleForm.Create(Nil);
  With LearnTroubleForm Do
    begin
      Caption := ClsID + ': ' + Caption;
      ListBox.Items.Text := Txt;
      ProblemLine := TroubleLine;
      Result := ShowModal = mrOk;
      If Result Then
        If ModeBtn.Down Then
           Txt := EditMemo.Text
        Else
           Txt := ListBox.Items.Text;
      Free
    end;
end;

{ TLearnTroubleForm }

procedure TLearnTroubleForm.ListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
begin
  With ListBox, ListBox.Canvas Do
    begin
      If odSelected In State Then
         begin
           Brush.Color:=clNavy;
           Font.Color:=clWhite
         end
      Else
         If (Index>=0) And (Items[Index]=ProblemLine) Then
           begin
             Brush.Color:=clRed;
             Font.Color:=clWhite
           end
         Else
           begin
             Brush.Color:=Color;
             Font.Color:=clBlack
           end;
      FillRect(ARect);
      TextRect(ARect,ARect.Left,ARect.Top,Items[Index])
    end
end;

procedure TLearnTroubleForm.ModeBtnClick(Sender: TObject);
begin
  If ModeBtn.Down Then
     EditMemo.Text := ListBox.Items.Text
  Else
     ListBox.Items.Text := EditMemo.Text;
  EditMemo.Visible := ModeBtn.Down;
  ListBox.Visible := Not ModeBtn.Down
end;

procedure TLearnTroubleForm.FormCreate(Sender: TObject);
begin
  FProblemLine := ''
end;

procedure TLearnTroubleForm.EditMemoChange(Sender: TObject);
begin

end;

initialization
  {$IFDEF FPC}
  {$i LearnTrouble.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}


end.

