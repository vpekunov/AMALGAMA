unit LinkTpDlg;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses {$IFDEF FPC}LCLIntf,{$ENDIF} SysUtils, Classes, Graphics, Forms, Controls, StdCtrls,
  Buttons, ExtCtrls{$IFDEF FPC}, LResources{$ENDIF};

type
  TLinkTypeDlg = class(TForm)
    OKBtn: TButton;
    CancelBtn: TButton;
    LinkTypeGroup: TRadioGroup;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  LinkTypeDlg: TLinkTypeDlg;

implementation


initialization
  {$IFDEF FPC}
  {$i LinkTpDlg.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
