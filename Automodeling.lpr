program Automodeling;

{$MODE Delphi}

uses
  Interfaces, // this includes the LCL widgetset
  Forms,
  xpathingIntrf,
  Main in 'Main.pas' {MainForm},
  AutoConsts in 'AutoConsts.pas',
  AutoUtils in 'AutoUtils.pas',
  Elements in 'Elements.pas',
  Lexique in 'LEXIQUE.PAS',
  XPath in 'xpath.pas',
  ClassWin in 'ClassWin.pas' {ClassesForm},
  EditEl in 'EditEl.pas' {EditProps},
  Tran in 'Tran.pas' {Translator},
  SettngDlg in 'SettngDlg.pas' {SettingsDlg},
  LinkTpDlg in 'LinkTpDlg.pas' {LinkTypeDlg},
  EditTxtDlg in 'EditTxtDlg.pas' {EditTextDlg},
  ContDlg in 'ContDlg.pas' {ContactDlg},
  EditList, LearnTrouble, InductModel, InductRules;

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TClassesForm, ClassesForm);
  Application.CreateForm(TSettingsDlg, SettingsDlg);
  Application.CreateForm(TLinkTypeDlg, LinkTypeDlg);
  Application.CreateForm(TEditTextDlg, EditTextDlg);
  Application.CreateForm(TContactDlg, ContactDlg);
  Application.CreateForm(TEditListDlg, EditListDlg);
  Application.Run;
end.
