unit ClassWin;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF} Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ComCtrls{$IFDEF FPC}, LResources{$ENDIF}, StdCtrls;

type

  { TClassesForm }

  TClassesForm = class(TForm)
    ClassesTree: TTreeView;
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    Docked: Boolean;
  end;

var
  ClassesForm: TClassesForm;

implementation

uses Main, Elements;


procedure TClassesForm.FormResize(Sender: TObject);
begin
     If (Width<5) And MainForm.MainSplitter.Visible Then Close
end;

procedure TClassesForm.FormCreate(Sender: TObject);
begin
     LoadClasses(ClassesTree)
end;

procedure TClassesForm.FormHide(Sender: TObject);
begin
     If Docked Then
        With MainForm Do
          begin
            MainSplitter.Hide;
            DockPanel.Width:=0
          end;
     MainForm.NClasses.Checked:=False
end;

procedure TClassesForm.FormShow(Sender: TObject);
begin
     If Docked Then
        With MainForm Do
          begin
            DockPanel.Width:=150;
            MainSplitter.Show
          end
end;

initialization
  {$IFDEF FPC}
  {$i ClassWin.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
