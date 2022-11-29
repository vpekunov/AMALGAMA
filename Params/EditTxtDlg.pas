unit EditTxtDlg;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses {$IFDEF FPC}LCLIntf,{$ENDIF} SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls{$IFDEF FPC}, LResources{$ENDIF};

type

  { TEditTextDlg }

  TEditTextDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    TextMemo: TMemo;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditTextDlg: TEditTextDlg;

implementation


{ TEditTextDlg }

initialization
  {$IFDEF FPC}
  {$i EditTxtDlg.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
