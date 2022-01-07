unit SettngDlg;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses {$IFDEF FPC}LCLIntf,{$ENDIF} SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls{$IFDEF FPC}, LResources{$ENDIF};

type
  TSettingsDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    GroupBox: TGroupBox;
    cbShowClass: TCheckBox;
    cbShowName: TCheckBox;
    cbShowImage: TCheckBox;
    ApplyGroup: TRadioGroup;
    AutoGroupBox: TGroupBox;
    cbAutoStart: TCheckBox;
    cbAutoReDeduce: TCheckBox;
    cbAutoDeduce: TCheckBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  SettingsDlg: TSettingsDlg;

implementation


initialization
  {$IFDEF FPC}
  {$i SettngDlg.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
