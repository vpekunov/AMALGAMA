unit Main;

{$IFDEF FPC}
{$MODE Delphi}
{$ENDIF}

{$CODEPAGE UTF8}

interface

uses
  {$IFDEF FPC}LCLIntf,{$ENDIF} Messages, SysUtils, Classes
  {$IFDEF FPC}, LMessages{$ENDIF}, Forms, Graphics, Controls, Dialogs,
  StdCtrls, {$IFNDEF linux}ShellApi,{$ENDIF}Buttons, ExtCtrls, ComCtrls, Elements, Menus, IniFiles,
  AutoConsts{$IFDEF linux}, ctypes, UnixType, Sockets, Process, fileutil{$ELSE}, Winsock, Windows, Registry{$ENDIF},
  uSemaphore, LocalIP{$IFDEF FPC}, LResources{$ENDIF};

Const IniFName        = 'Automodeling.ini';
      SectLangs       = 'Languages';
      SectSettings    = 'Settings';
      prmShowClass    = 'ShowClass';
      prmShowName     = 'ShowName';
      prmShowImage    = 'ShowImage';
      prmApplyToAll   = 'ApplyToAll';
      prmAutoStart    = 'AutoStart';
      prmAutoDeduce   = 'AutoDeduce';
      prmAutoReDeduce = 'AutoReDeduce';

      BASE_USER = {$IFDEF FPC}LM_USER{$ELSE}WM_USER{$ENDIF};

      WM_PGEN_RUN = BASE_USER+$200;
      WM_PGEN_MSG = WM_PGEN_RUN+1;
      WM_EDIT_OBJ = WM_PGEN_MSG+1;

type
  TLanguage = Record
    FName: String;
    Item:  TMenuItem
  End;

  TControlThread = class;
  TQueryThread = class;

  { TMainForm }

  TMainForm = class(TForm)
    MainMenu: TMainMenu;
    NInductRules: TMenuItem;
    NInduct: TMenuItem;
    N6: TMenuItem;
    NFile: TMenuItem;
    NNew: TMenuItem;
    NOpen: TMenuItem;
    NSave: TMenuItem;
    N5: TMenuItem;
    NExit: TMenuItem;
    NView: TMenuItem;
    NClasses: TMenuItem;
    OpenModel: TOpenDialog;
    GraphicsPanel: TPanel;
    SaveModel: TSaveDialog;
    ElementPopup: TPopupMenu;
    LinkPopup: TPopupMenu;
    ElProps: TMenuItem;
    ElDel: TMenuItem;
    LinkDel: TMenuItem;
    NGenerate: TMenuItem;
    NTranslate: TMenuItem;
    NSep: TMenuItem;
    NLangs: TMenuItem;
    NSettings: TMenuItem;
    ElSettings: TMenuItem;
    NSaveAs: TMenuItem;
    N2: TMenuItem;
    MainStatusBar: TStatusBar;
    BigPanel: TPanel;
    ModelBox: TGroupBox;
    HScroller: TScrollBar;
    VScroller: TScrollBar;
    DockPanel: TPanel;
    MainSplitter: TSplitter;
    LinkType: TMenuItem;
    LinkColor: TMenuItem;
    LinkColorDialog: TColorDialog;
    CntPubl: TMenuItem;
    MessageListBox: TListBox;
    MainPaintBox: TPaintBox;
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure DockPanelDockDrop(Sender: TObject; Source: TDragDockObject;
      X, Y: Integer);
    procedure DockPanelUnDock(Sender: TObject; Client: TControl;
      NewTarget: TWinControl; var Allow: Boolean);
    procedure MainSplitterCanResize(Sender: TObject; var NewSize: Integer;
      var Accept: Boolean);
    procedure DockPanelDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure MainPaintBoxDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure MainPaintBoxDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure MainPaintBoxPaint(Sender: TObject);
    procedure HScrollerScroll(Sender: TObject; ScrollCode: TScrollCode;
      var ScrollPos: Integer);
    procedure MainPaintBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MainPaintBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure MainPaintBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure NClassesClick(Sender: TObject);
    procedure NInductClick(Sender: TObject);
    procedure NInductRulesClick(Sender: TObject);
    procedure NOpenClick(Sender: TObject);
    procedure NSaveClick(Sender: TObject);
    procedure NNewClick(Sender: TObject);
    procedure NExitClick(Sender: TObject);
    procedure ElPropsClick(Sender: TObject);
    procedure ElDelClick(Sender: TObject);
    procedure LinkDelClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure DockPanelResize(Sender: TObject);
    procedure NTranslateClick(Sender: TObject);
    procedure MainPaintBoxDblClick(Sender: TObject);
    procedure NSettingsClick(Sender: TObject);
    procedure ElSettingsClick(Sender: TObject);
    procedure NSaveAsClick(Sender: TObject);
    procedure LinkColorClick(Sender: TObject);
    procedure LinkTypeClick(Sender: TObject);
    procedure CntPublClick(Sender: TObject);
  private
    FSaved: Boolean;
    NoLang: TMenuItem;
    InSock, OutSock: TSocket;
    ControlThread: TControlThread;
    QueryThread: TQueryThread;
    { Private declarations }
    function  CBToFlags(_Classes,_Names,_Images:Boolean):Integer;
    procedure FlagsToCB(Flgs:Integer; Var _Classes,_Names,_Images:Boolean);
    procedure DrawSystem;
    Function GetWinHandle: Integer;

    procedure LanguageClick(Sender: TObject);
    procedure SetSaved(const Value: Boolean);
    function  GetConnected: Boolean;
    procedure EndNotifyMaster;
  public
    { Public declarations }
    ShowFlags:     Integer;
    AutoStart:     Boolean;
    AutoDeduce:    Boolean;
    AutoReDeduce:  Boolean;
    ApplyToAll:    Boolean;
    ActiveElement: TElement;
    ActiveContact: TContact;
    ActiveLink:    TLink;
    LinkPoint:     Integer;
    PopupEl:       TElement;
    PopupLink:     TLink;
    PopupCont:     TContact;
    MovedRect:     TRect;
    OldX, OldY:    Integer;
    Languages:     Array Of TLanguage;
    DblClicked:    Boolean;
    ControlSemaphore: TSemaphore;
    WorkSemaphore: TSemaphore;
    States:        Array Of Boolean;

    procedure AddTask(Const SessionID, TaskID: String; Files:TStringList; Lock:Boolean);

    function  CurLanguageIndex: Integer;
    function  CurLanguageName: String;
    procedure SelectLanguage(Const Lang: String);
    procedure RenewModel(SaveAs:Boolean; Const FileName:String);
    procedure InactiveSystem(Const State:Boolean);
    procedure PushStateAndRun;
    procedure PopState;
    procedure RunEvent(Var Message:TMessage); message WM_PGEN_RUN;
    procedure MsgEvent(Var Message:TMessage); message WM_PGEN_MSG;
    procedure EditEvent(Var Message:TMessage); message WM_EDIT_OBJ;

    property Saved: Boolean read FSaved write SetSaved;
    property Connected: Boolean read GetConnected;

    property WinHandle: Integer read GetWinHandle;
  end;

  TControlThread = class(TThread)
    InSocket, OutSocket: TSocket;
    WorkSemaphore, ControlSemaphore: TSemaphore;
    constructor Create(Parent: TMainForm; _In,_Out: TSocket);
    procedure   Execute; override;
    procedure   DoTerminate; override;
  End;

  TControlMsg = Array[0..255] Of Char;
  TMulticastMsg = Record
     Msg:  TControlMsg;
     IP:   Integer;
     Info: Integer
  end;

  TTask = class
    ID: String;
    Files: TStringList;
    constructor Create(Const _ID:String);
    destructor  Destroy; override;
  End;

  TQueryThread = class(TThread)
    OutSocket, ExchangeSocket: TSocket;
    WorkSemaphore, ControlSemaphore: TSemaphore;
    Threads:  TList;
    constructor Create(Parent: TMainForm; _Out: TSocket);
    procedure   Execute; override;
    procedure   DoTerminate; override;
  End;

  TTaskThread = class(TThread)
    ID:String;
    NewSock:TSocket;
    FList:TStringList;
    constructor Create(Const _ID:String; _NewSock: TSocket; _FList:TStringList);
    procedure   Execute; override;
    procedure   DoTerminate; override;
  End;

Const MasterFlag:Boolean = True;
      HostIP:String = '';
      Slaves:TStringList = Nil;
      FreeSlaves:TStringList = Nil;
      RequestingList:TStringList = Nil;
      Sessions:TStringList = Nil;
      FreeFlag:Boolean = True;
      ExternalForked:efType = efFree;
      ExternalFileName:String = '';
      ExternalOutputName:String = '';
      LockedFlag:Boolean = False;

var
  MainForm: TMainForm;

implementation


Uses Math, ClassWin, EditEl, Tran, SettngDlg, LinkTpDlg, InductModel,
  ContDlg, LEXIQUE, FileCtrl, AutoUtils, InductRules, Common,
  Types, StrUtils;

Type IP_MREQN = Record
        IMR_MultiAddr:IN_ADDR;
        IMR_Interface:IN_ADDR;
        INTRF:Integer;
     End;

{$IFDEF linux}
Type TSockAddrIn = TInetSockAddr;

function inet_addr (Const IP: String): cuint32;
begin
     Result := StrToNetAddr(Trim(IP)).s_addr;
end;

function inet_ntoa (Const IP: IN_ADDR): String;
begin
     Result := NetAddrToStr(IP)
end;

function  socket (domain:cint; xtype:cint; protocol: cint):cint;
begin
     Result := fpsocket(domain, xtype, protocol)
end;

function  recv (s:cint; buf: pointer; len: size_t; flags: cint):ssize_t;
begin
     Result := fprecv(s, buf, len, flags)
end;

function  send (s:cint; msg:pointer; len:size_t; flags:cint):ssize_t;
begin
     Result := fpsend(s, msg, len, flags)
end;

function  sendto      (s:cint; var msg; len:size_t; flags:cint; Var tox : TInetSockAddr; tolen: tsocklen):ssize_t;
begin
     Result := fpsendto(s, @msg, len, flags, @tox, tolen)
end;

function  recvfrom    (s:cint; var buf; len: size_t; flags: cint; Var from : TSockAddr; fromlen : tsocklen):ssize_t;
begin
     Result := fprecvfrom(s, @buf, len, flags, @from, @fromlen)
end;

function  setsockopt  (s:cint; level:cint; optname:cint; optval:pointer; optlen : tsocklen):cint;
begin
     Result := fpsetsockopt(s, level, optname, optval, optlen)
end;

function  getsockopt  (s:cint; level:cint; optname:cint; optval:pointer; Var optlen : tsocklen):cint;
begin
     Result := fpgetsockopt(s, level, optname, optval, @optlen)
end;

function  bind (s:cint; var addrx : TInetSockAddr; addrlen : tsocklen):cint;
begin
     Result := fpbind(s, @addrx, addrlen)
end;

function  connect     (s:cint; var name : TInetSockAddr; namelen : tsocklen):cint;
begin
     Result := fpconnect(s, @name, namelen)
end;

function  listen      (s:cint; backlog : cint):cint;
begin
     Result := fplisten(s, backlog)
end;

function  accept      (s:cint; addrx : psockaddr; var addrlen : tsocklen):cint;
begin
     Result := fpaccept(s, addrx, @addrlen)
end;

{$ENDIF}

function ReadString(Sock:TSocket):String;

Var Ptr,Len:Integer;
    LBuf:Array[0..SizeOf(Len)-1] Of Byte Absolute Len;
begin
     Ptr:=0;
     While Ptr<SizeOf(Len) Do
        Inc(Ptr,recv(Sock,@LBuf[Ptr],SizeOf(Len)-Ptr,0));
     SetLength(Result,Len);
     Ptr:=1;
     While Ptr<=Len Do
       Inc(Ptr,recv(Sock,@Result[Ptr],Len-Ptr+1,0))
end;

procedure WriteString(Sock:TSocket; Buf:String);

Var Ptr,Len:Integer;
    LBuf:Array[0..SizeOf(Len)-1] Of Byte Absolute Len;
begin
     Len:=Length(Buf);
     Ptr:=0;
     While Ptr<SizeOf(Len) Do
       Inc(Ptr,send(Sock,@LBuf[Ptr],SizeOf(Len)-Ptr,0));
     Ptr:=1;
     While Ptr<=Len Do
       Inc(Ptr,send(Sock,@Buf[Ptr],Len-Ptr+1,0))
end;

procedure ParsePipedStr(Const FName:String; Var ServerFName,SlaveFName:String);

Var F:Integer;
begin
     F:=Pos(Pipe,FName);
     If F>0 Then
        begin
          ServerFName:=Copy(FName,1,F-1);
          SlaveFName:=Copy(FName,F+1,Length(FName)-F)
        end
     Else
        begin
          ServerFName:=FName;
          SlaveFName:=FName
        end
end;

procedure CopyMoveStructure(Const FromDir,ToDir:String; Move:Boolean);

Var S:TSearchRec;
    Result:Integer;
begin
     Result:=FindFirst(FromDir+SuperSlash+'*',faAnyFile,S);
     While Result=0 Do
       Begin
          If (S.Name<>'.') And (S.Name<>'..') Then
             If (S.Attr And faDirectory)<>0 Then
                Begin
                  CreateDir(PChar(ToDir+SuperSlash+S.Name));
                  CopyMoveStructure(FromDir+SuperSlash+S.Name,ToDir+SuperSlash+S.Name,Move)
                End
             Else
                begin
                  If Move Then
                     begin
                       DeleteFile(PChar(ToDir+SuperSlash+S.Name));
                       RenameFile(PChar(FromDir+SuperSlash+S.Name),PChar(ToDir+SuperSlash+S.Name))
                     end
                  Else
                     CopyFile(PChar(FromDir+SuperSlash+S.Name),PChar(ToDir+SuperSlash+S.Name),False);
                  FileSetAttr(ToDir+SuperSlash+S.Name,
                    FileGetAttr(ToDir+SuperSlash+S.Name) And Not faReadOnly)
                end;
          Result:=FindNext(S)
       End;
     SysUtils.FindClose(S)
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
     DockPanel.Constraints.MaxWidth:=Width-100;
     With MainPaintBox Do
       SetBufSize(Width,Height)
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
     ClassesForm.Show;
     // To prevent dock bugs in Lazarus I turn off docking. Nothing terrible,
     // but docking process looks unesthetic...
     {$IFDEF FPC}
     ClassesForm.Top:=Top;
     ClassesForm.Left:=Max(0,Left-ClassesForm.Width-5);
     ClassesForm.Width:=Min(ClassesForm.Width,Left-5);
     ClassesForm.Height:=Height;
     ClassesForm.DragMode:=dmManual;
     MainSplitter.Hide;
     {$ELSE}
     ClassesForm.ManualDock(DockPanel)
     {$ENDIF}
end;

procedure TMainForm.DockPanelDockDrop(Sender: TObject;
  Source: TDragDockObject; X, Y: Integer);
begin
     If ClassesForm.Visible Then
        begin
          DockPanel.Width:=150;
          MainSplitter.Show;
          ClassesForm.Docked:=True
        end
end;

procedure TMainForm.DockPanelUnDock(Sender: TObject; Client: TControl;
  NewTarget: TWinControl; var Allow: Boolean);
begin
     MainSplitter.Hide;
     DockPanel.Width:=0;
     ClassesForm.Docked:=False
end;

procedure TMainForm.MainSplitterCanResize(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
     If NewSize>DockPanel.Constraints.MaxWidth Then
        NewSize:=DockPanel.Constraints.MaxWidth
end;

procedure TMainForm.DockPanelDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
     Accept:=ClassesForm.Dragging
end;

procedure TMainForm.MainPaintBoxDragOver(Sender, Source: TObject; X,
  Y: Integer; State: TDragState; var Accept: Boolean);
begin
     Accept:=(Source=ClassesForm.ClassesTree) And Not Assigned(ActiveElement)
end;

procedure TMainForm.MainPaintBoxDragDrop(Sender, Source: TObject; X,
  Y: Integer);

Var P:TTreeNode;
    Obj:TElement;
begin
     PushStateAndRun;
     P:=ClassesForm.ClassesTree.Selected;
     If (Source=ClassesForm.ClassesTree) And Assigned(P) Then
        begin
          Obj:=MainSys.AddElement(TElementReg(P.Data).ClsID,'NewItem'+IntToStr(MainSys.ElCounter),ShowFlags);
          If Obj.LoadSubElements(MainSys) Then
             begin
               Obj.Move(X+HScroller.Position,Y+VScroller.Position);
               Obj.Draw(HScroller.Position,VScroller.Position);
               Saved:=False;
               // To prevent Lazarus bugs (or features), who knows what's the matter...
               // I love Lazarus, but it looks strange sometimes :)
               Application.ProcessMessages;
               PostMessage(MainForm.WinHandle,WM_EDIT_OBJ,0,Int64(Obj));
               Exit
             end
          Else
             begin
               MainSys.Elements.Remove(Obj);
               Obj.RemoveSubElements(MainSys);
               Obj.Free;
               DrawSystem
             end
        end;
     PopState
end;

procedure TMainForm.FormCreate(Sender: TObject);

function ConnectNetwork(Var InSock,OutSock:TSocket):Boolean;

Type TTimeVal = packed record
   tv_sec : longint;//time_t
   tv_usec : longint;//suseconds_t
end;

Var Addr:Integer;
    Data:TSockAddrIn;
    One,TTL:DWORD;
    OneL: LongInt;
    MReq:IP_MREQN;
    TM: TTimeVal;
begin
     Result:=False;
     HostIP:=getLocalIP;
     {$IFDEF linux}
     RunExtCommand('route','add 224.0.0.0 gw '+HostIP,'','');
     RunExtCommand('route','add '+ConnectMask+' gw '+HostIP,'','');
     {$ELSE}
     RunExtCommand('route','add 224.0.0.0 '+HostIP,'','');
     RunExtCommand('route','add '+ConnectMask+' '+HostIP,'','');
     {$ENDIF}
     One:=1;
     TTL:=33;
     FillChar(Data,SizeOf(Data),0);
     {$IFDEF linux}
     Data.sin_family:=AF_INET;
     Data.sin_addr.s_addr:=inet_addr(PChar(ConnectMask));
     {$ELSE}
     Data.sa_family:=AF_INET;
     Data.sin_addr.s_addr:=inet_addr(PChar(HostIP));
     {$ENDIF}
     Data.sin_port:=ConnectPort;

     OutSock:=socket(AF_INET,SOCK_DGRAM,IPPROTO_IP);
     If (OutSock < 0) Or
        (setsockopt(OutSock,SOL_SOCKET,SO_REUSEADDR,@One,SizeOf(One))<>0) Or
        (setsockopt(OutSock,IPPROTO_IP,IP_MULTICAST_TTL,@TTL,SizeOf(TTL))<>0) Then Exit;

     InSock:=socket(AF_INET,SOCK_DGRAM,IPPROTO_IP);
     If (InSock < 0) Or
        (setsockopt(InSock,SOL_SOCKET,SO_REUSEADDR,@One,SizeOf(One))<>0) Or
        (bind(InSock,Data,SizeOf(Data))<>0) Then
        begin
          closesocket(OutSock);
          Exit
        end;

     If Length(HostIP)<>0 Then
        Addr:=inet_addr(PChar(HostIP))
     Else
        Addr:=INADDR_ANY;
     If (setsockopt(InSock,IPPROTO_IP,IP_MULTICAST_TTL,@TTL,SizeOf(TTL))=0) And
        (setsockopt(InSock,IPPROTO_IP,IP_MULTICAST_IF,@Addr,SizeOf(Addr))=0) Then
        begin
          MReq.IMR_MultiAddr.s_addr:=inet_addr(ConnectMask);
          If Length(HostIP)<>0 Then
             MReq.IMR_Interface.s_addr:=inet_addr(PChar(HostIP))
          Else
             MReq.IMR_Interface.s_addr:=INADDR_ANY;
          MReq.INTRF := 0;
          TM.tv_sec := 1;
          TM.tv_usec := 0;
          // fcntl(InSock, F_SetFl, O_NONBLOCK);
          OneL := 1;
          {$IFNDEF linux}
          ioctlsocket(InSock, FIONBIO, @OneL);
          {$ENDIF}
          Result:=
              (setsockopt(InSock,IPPROTO_IP,IP_ADD_MEMBERSHIP,@Mreq,SizeOf(MReq))=0)
              {$IFNDEF linux}And (setsockopt(InSock,SOL_SOCKET,SO_RCVTIMEO, @TM, sizeof(TM))=0){$ENDIF};
          If Not Result Then
             begin
               MessageDlg('Ошибка сети: ' + IntToStr({$IFDEF linux}SocketError{$ELSE}WSAGetLastError{$ENDIF}), mtInformation, [mbOk], 0);
               closesocket(InSock);
               closesocket(OutSock)
             end
        end
end;

Var {$IFNDEF linux}WSA:TWSAData;{$ENDIF}
    S:TStringList;
    F:Integer;
begin
     {$IFNDEF linux}
     If WSAStartup(MAKEWORD(2,0),WSA)<>0 Then
        MessageDlg('Невозможно вызвать Winsock',mtInformation,[mbOk],0);
     {$ENDIF}
     // To prevent Lazarus unesthetic docking
     {$IFDEF FPC}
     Width:=Width-DockPanel.Width;
     DockPanel.Width:=0;
     {$ENDIF}
     SetLength(States,0);
     MainSys:=TSystem.Create;
     ControlSemaphore:=TSemaphore.Create(1);
     WorkSemaphore:=TSemaphore.Create(1);
     If ConnectNetwork(InSock,OutSock) Then
        begin
          ControlThread:=TControlThread.Create(Self, InSock,OutSock);
          ControlThread.Resume;
          QueryThread:=TQueryThread.Create(Self, OutSock);
          QueryThread.Resume
        end
     Else
        begin
          ControlThread:=Nil;
          QueryThread:=Nil;
          MessageDlg('Работа в локальной версии',mtInformation,[mbOk],0)
        end;

     PopupEl:=Nil;
     PopupLink:=Nil;
     PopupCont:=Nil;
     ActiveElement:=Nil;
     ActiveContact:=Nil;
     ActiveLink:=Nil;
     With MainPaintBox Do Canvas.Font:=Font;
     Cnv:=MainPaintBox.Canvas;
     With MainPaintBox Do
       SetBufSize(Width,Height);
     With TIniFile.Create(GetCurrentDir+SuperSlash+IniFName) Do
       begin
         S:=TStringList.Create;
         ReadSectionValues(SectLangs,S);
         SetLength(Languages,S.Count);
         For F:=0 To S.Count-1 Do
           With Languages[F] Do
             begin
               Item:=TMenuItem.Create(Self);
               Item.Caption:=S.Names[F];
               Item.GroupIndex:=1;
               Item.RadioItem:=True;
               Item.OnClick:=LanguageClick;
               NLangs.Add(Item);
               Item.Visible:=True;
               FName:=S.Values[S.Names[F]]
             end;
         NoLang:=TMenuItem.Create(Self);
         NoLang.Caption:='Нет';
         NoLang.GroupIndex:=1;
         NoLang.RadioItem:=True;
         NoLang.Checked:=True;
         NoLang.OnClick:=LanguageClick;
         NLangs.Add(NoLang);
         NoLang.Visible:=True;
         S.Free;
         ShowFlags:=CBToFlags(ReadBool(SectSettings,prmShowClass,True),
                              ReadBool(SectSettings,prmShowName,True),
                              ReadBool(SectSettings,prmShowImage,True));
         ApplyToAll:=ReadBool(SectSettings,prmApplyToAll,True);
         AutoStart:=ReadBool(SectSettings,prmAutoStart,False);
         AutoDeduce:=ReadBool(SectSettings,prmAutoDeduce,False);
         AutoReDeduce:=ReadBool(SectSettings,prmAutoReDeduce,False);
         Free
       end;
     DblClicked:=False;
     Caption:='АвтоГЕН';
     Saved:=True
end;

procedure TMainForm.FormDestroy(Sender: TObject);
Var F,G,Rslt:Integer;
    C,N,I:Boolean;
    MCast:TSockAddrIn;
    First:TMulticastMsg;
    MReq:IP_MREQN;
begin
     SetLength(States,0);
     InactiveSystem(True);
     FreeAndNil(MainSys);
     If Assigned(ControlThread) And Not ControlThread.Terminated Then
        begin
          First.Msg:=Unregister;
          First.IP:=INADDR_ANY;
          FillChar(MCast,SizeOf(MCast),0);
          MCast.sin_family:=AF_INET;
          MCast.sin_addr.s_addr := inet_addr(ConnectMask);
          MCast.sin_port:=ConnectPort;
          ControlSemaphore.Wait;
          Rslt:=sendto(OutSock,First,SizeOf(First),0,MCast,SizeOf(MCast));
          ControlSemaphore.Post;
          If Rslt >= 0 Then
             ControlThread.WaitFor
        end;
     FreeAndNil(ControlThread);
     ControlSemaphore.Wait;
     If Assigned(Sessions) Then
        With Sessions Do
          begin
            For F:=0 To Count-1 Do
              With TStringList(Objects[F]) Do
                begin
                  For G:=0 To Count-1 Do
                    Objects[G].Free;
                  Free
                end;
            Free
          end;
     Sessions:=Nil;
     ControlSemaphore.Post;
     If Assigned(QueryThread) Then
        begin
          QueryThread.WaitFor;
          FreeAndNil(QueryThread)
        end;
     MReq.IMR_MultiAddr.S_addr := inet_addr(ConnectMask);
     If Length(HostIP)<>0 Then
        MReq.IMR_Interface.S_addr := inet_addr(PChar(HostIP))
     Else
        MReq.IMR_Interface.s_addr:=INADDR_ANY;
     MReq.INTRF := 0;
     setsockopt(InSock,IPPROTO_IP,IP_DROP_MEMBERSHIP,@Mreq,SizeOf(MReq));
     closesocket(InSock);
     closesocket(OutSock);
     RequestingList.Free;
     Slaves.Free;
     FreeSlaves.Free;
     ControlSemaphore.Free;
     WorkSemaphore.Free;
     SetLength(Languages,0);
     With TIniFile.Create(GetCurrentDir+SuperSlash+IniFName) Do
       begin
         FlagsToCB(ShowFlags,C,N,I);
         WriteBool(SectSettings,prmShowClass,C);
         WriteBool(SectSettings,prmShowName,N);
         WriteBool(SectSettings,prmShowImage,I);
         WriteBool(SectSettings,prmApplyToAll,ApplyToAll);
         WriteBool(SectSettings,prmAutoStart,AutoStart);
         WriteBool(SectSettings,prmAutoDeduce,AutoDeduce);
         WriteBool(SectSettings,prmAutoReDeduce,AutoReDeduce);
         Free
       end;
     {$IFNDEF linux}
     WSACleanup
     {$ENDIF}
end;

procedure TMainForm.MainPaintBoxPaint(Sender: TObject);
begin
     DrawSystem
end;

procedure TMainForm.HScrollerScroll(Sender: TObject;
  ScrollCode: TScrollCode; var ScrollPos: Integer);
begin
     DrawSystem
end;

procedure TMainForm.MainPaintBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

Var InEl:TElement;
    InCont:TContact;
    L:TLink;
    P:TPoint;
    S:String;
    LP,LS:Integer;
begin
     PushStateAndRun;
     Case Button Of
      mbLeft:
       begin
        If Not Assigned(ActiveLink) Then
           If Assigned(ActiveContact) Then
              begin
                InEl:=MainSys.FindElement(X,Y,HScroller.Position,VScroller.Position);
                If Assigned(InEl) Then
                   begin
                     InCont:=InEl.FindContact(X,Y,HScroller.Position,VScroller.Position);
                     If Assigned(InCont) And (InCont.State In [cstFrom,cstTo]) Then
                        begin
                          If InCont.State=cstTo Then
                             begin
                               L:=MainSys.AddLink(ActiveContact,InCont,S);
                               If Assigned(L) Then
                                  begin
                                    MainSys.AnalyzeLinkStatus(L);
                                    MainSys.DrawLink(True,L,HScroller.Position,VScroller.Position);
                                    Saved:=False
                                  end
                               Else
                                  MessageDlg(S,mtError,[mbOk],0)
                             end;
                          ActiveContact.State:=cstNormal;
                          ActiveContact.Draw(HScroller.Position,VScroller.Position);
                          MainSys.Deactivate(HScroller.Position,VScroller.Position);
                          ActiveElement:=Nil;
                          ActiveContact:=Nil
                        end
                   end
              end
           Else
              begin
                ActiveElement:=MainSys.FindElement(X,Y,HScroller.Position,VScroller.Position);
                If Assigned(ActiveElement) Then
                 If DblClicked Then
                   begin
                     PopupEl:=ActiveElement;
                     ActiveElement:=Nil;
                     ElPropsClick(Nil)
                   end
                 Else
                   begin
                     ActiveContact:=ActiveElement.FindContact(X,Y,HScroller.Position,VScroller.Position);
                     If Assigned(ActiveContact) And (ActiveContact.Ref.Dir=dirOutput) Then
                        MainSys.Activate(ActiveElement,ActiveContact,HScroller.Position,VScroller.Position)
                     Else
                        begin
                          ActiveContact:=Nil;
                          Saved:=False;
                          MovedRect:=ActiveElement.Area;
                          OffsetRect(MovedRect,-HScroller.Position,-VScroller.Position);
                          With MainPaintBox.Canvas Do
                            begin
                              Pen.Color:=clRed;
                              Pen.Mode:=pmNotXor;
                              Pen.Style:=psDashDot;
                              Pen.Width:=1;
                              Brush.Style:=bsClear;
                              Rectangle(MovedRect)
                            end;
                          OldX:=X;
                          OldY:=Y
                        end
                   end
                Else
                   begin
                     ActiveLink:=MainSys.FindLink(X,Y,HScroller.Position,VScroller.Position,LP,LS);
                     If Assigned(ActiveLink) Then
                        If (LS=0) And (LP=0) Or (LS=Length(ActiveLink.Points)) And (LP=1) Then
                           ActiveLink:=Nil
                        Else
                          With ActiveLink Do
                            begin
                              DrawSystem;
                              If LP>=0 Then
                                 LinkPoint:=LS+LP-1
                              Else
                                 begin
                                   SetLength(Points,Length(Points)+1);
                                   If LS<Length(Points)-1 Then
                                      Move(Points[LS],Points[LS+1],(Length(Points)-LS-1)*SizeOf(TPoint));
                                   LinkPoint:=LS
                                 end;
                              Points[LinkPoint].X:=X+HScroller.Position;
                              Points[LinkPoint].Y:=Y+VScroller.Position;
                              MainPaintBox.Canvas.Pen.Mode:=pmNotXor;
                              MainSys.DrawLink(False,ActiveLink,HScroller.Position,VScroller.Position);
                              Saved:=False
                            end
                   end
              end;
        If DblClicked Then
           DblClicked:=False
       end;
      mbRight:
        If Not (Assigned(ActiveElement) Or Assigned(ActiveContact) Or Assigned(ActiveLink)) Then
           begin
             PopupEl:=MainSys.FindElement(X,Y,HScroller.Position,VScroller.Position);
             P.X:=X; P.Y:=Y;
             P:=MainPaintBox.ClientToScreen(P);
             If Assigned(PopupEl) Then
                begin
                  PopupCont:=PopupEl.FindContact(X,Y,HScroller.Position,VScroller.Position);
                  CntPubl.Enabled:=Assigned(PopupCont) And (PopupEl.SubElements.Count=0);
                  ElementPopup.Popup(P.X,P.Y)
                end
             Else
                begin
                  PopupLink:=MainSys.FindLink(X,Y,HScroller.Position,VScroller.Position,LP,LS);
                  If Assigned(PopupLink) Then
                     LinkPopup.Popup(P.X,P.Y)
                end
           end
     End;
     PopState
end;

procedure TMainForm.MainPaintBoxMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);

Var L:TLines;
    KX1,KY1,KL1,KX2,KY2,KL2:Real;
begin
     PushStateAndRun;
     If Assigned(ActiveLink) Then
        begin
          MainPaintBox.Canvas.Pen.Mode:=pmCopy;
          ActiveLink.GetLine(L);
          With L[LinkPoint] Do
            begin
              KX1:=X2-X1;
              KY1:=Y2-Y1;
              KL1:=Norm([KX1,KY1])
            end;
          With L[LinkPoint+1] Do
            begin
              KX2:=X2-X1;
              KY2:=Y2-Y1;
              KL2:=Norm([KX2,KY2])
            end;
          If (Abs(KX1/KL1-KX2/KL2)<Eps) And (Abs(KY1/KL1-KY2/KL2)<Eps) Then
             With ActiveLink Do
               begin
                 Move(Points[LinkPoint+1],Points[LinkPoint],(Length(Points)-LinkPoint-1)*SizeOf(TPoint));
                 SetLength(Points,Length(Points)-1)
               end;
          SetLength(L,0);
          ActiveLink:=Nil;
          DrawSystem
        end
     Else If Assigned(ActiveElement) And Not Assigned(ActiveContact) Then
        begin
          OffsetRect(MovedRect,HScroller.Position,VScroller.Position);
          ActiveElement.Move(MovedRect.Left,MovedRect.Top);
          ActiveElement:=Nil;
          With MainPaintBox.Canvas Do
            begin
              Pen.Color:=clBlack;
              Pen.Mode:=pmCopy;
              Pen.Style:=psSolid;
              Brush.Style:=bsSolid
            end;
          DrawSystem
        end;
     PopState
end;

procedure TMainForm.MainPaintBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
     PushStateAndRun;
     If (X>=0) And (Y>=0) And (X<MainPaintBox.Width) And (Y<MainPaintBox.Height) Then
        begin
          If Assigned(ActiveLink) Then
             begin
               MainSys.DrawLink(False,ActiveLink,HScroller.Position,VScroller.Position);
               Inc(ActiveLink.Points[LinkPoint].X,X-OldX);
               Inc(ActiveLink.Points[LinkPoint].Y,Y-OldY);
               MainSys.DrawLink(False,ActiveLink,HScroller.Position,VScroller.Position)
             end
          Else If Assigned(ActiveElement) And Not Assigned(ActiveContact) Then
             begin
               MainPaintBox.Canvas.Rectangle(MovedRect);
               OffsetRect(MovedRect,X-OldX,Y-OldY);
               MainPaintBox.Canvas.Rectangle(MovedRect)
             end;
          OldX:=X;
          OldY:=Y
        end;
     PopState
end;

procedure TMainForm.NClassesClick(Sender: TObject);
begin
     With NClasses Do
       begin
         Checked:=Not Checked;
         If Checked<>ClassesForm.Visible Then
            ClassesForm.Visible:=Checked
       end
end;

procedure TMainForm.NInductClick(Sender: TObject);

Var F: Integer;
begin
   With TInductModelForm.Create(Nil) Do
     Begin
       With ClassesTree.Items Do
         Begin
           Assign(ClassesForm.ClassesTree.Items);
           For F := 0 To Count - 1 Do
               Item[F].Data := ClassesForm.ClassesTree.Items[F].Data;
         End;
       ShowModal;
       Free
     end;
end;

procedure TMainForm.NInductRulesClick(Sender: TObject);

var InductRulesForm: TInductRulesForm;
    F: Integer;
begin
   InductRulesForm := TInductRulesForm.Create(Self);
   With InductRulesForm Do
     Begin
       With tvClasses.Items Do
         Begin
           Assign(ClassesForm.ClassesTree.Items);
           For F := 0 To Count - 1 Do
               Item[F].Data := ClassesForm.ClassesTree.Items[F].Data;
         End;
       ShowModal;
       Free
     end
end;

procedure TMainForm.RenewModel(SaveAs:Boolean; Const FileName:String);

Var Lang:String;
begin
  If Not Saved Then
     If (ExternalForked<>efFree) Or (MessageDlg('Сохранить текущую модель?',mtConfirmation,[mbYes,mbNo],0)=mrYes) Then
        If SaveAs Then
           NSaveAsClick(Nil)
        Else
           NSaveClick(Nil);
  FreeAndNil(MainSys);
  MainSys:=TSystem.LoadFromFile(Lang,FileName,Nil,Nil);
  If Not MainSys.Success Then FreeAndNil(MainSys);
  SelectLanguage(Lang);
  If Not Assigned(MainSys) Then
     MainSys:=TSystem.Create;
  Self.Caption:='АвтоГЕН - ['+ExtractFileName(FileName)+']';
  Saved:=True;
  HScroller.Position:=0;
  VScroller.Position:=0;
  DrawSystem
end;

procedure TMainForm.NOpenClick(Sender: TObject);
begin
     PushStateAndRun;
     With OpenModel Do
       If Execute Then
          RenewModel(False,FileName);
     PopState
end;

procedure TMainForm.NSaveClick(Sender: TObject);
begin
     PushStateAndRun;
     If Length(MainSys.SavedName)=0 Then
        NSaveAsClick(Sender)
     Else
        begin
          MainSys.SaveToFile(CurLanguageName,MainSys.SavedName);
          Saved:=True
        end;
     PopState
end;

procedure TMainForm.NNewClick(Sender: TObject);
begin
     PushStateAndRun;
     If Not Saved Then
        If MessageDlg('Сохранить текущую модель?',mtConfirmation,[mbYes,mbNo],0)=mrYes Then
           NSaveClick(Nil);
     FreeAndNil(MainSys);
     MainSys:=TSystem.Create;
     Self.Caption:='АвтоГЕН';
     Saved:=True;
     HScroller.Position:=0;
     VScroller.Position:=0;
     DrawSystem;
     PopState
end;

procedure TMainForm.NExitClick(Sender: TObject);
begin
     InactiveSystem(False);
     Close
end;

procedure TMainForm.ElPropsClick(Sender: TObject);
begin
     PushStateAndRun;
     With TEditProps.Create(Self) Do
       begin
         PutData(PopupEl,False);
         If Process(ShowModal=mrOk,PopupEl) Then
            begin
              Saved:=False;
              DrawSystem
            end;
         Free
       end;
     PopState
end;

procedure TMainForm.ElDelClick(Sender: TObject);
begin
     PushStateAndRun;
     MainSys.Elements.Remove(PopupEl);
     PopupEl.RemoveSubElements(MainSys);
     FreeAndNil(PopupEl);
     Saved:=False;
     DrawSystem;
     PopState
end;

procedure TMainForm.LinkDelClick(Sender: TObject);
begin
     PushStateAndRun;
     FreeAndNil(PopupLink);
     Saved:=False;
     DrawSystem;
     PopState
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
     If Not Saved Then
        If MessageDlg('Сохранить текущую модель?',mtConfirmation,[mbYes,mbNo],0)=mrYes Then
           NSaveClick(Nil)
end;

procedure TMainForm.DockPanelResize(Sender: TObject);
begin
     With MainPaintBox Do
       SetBufSize(Width,Height)
end;

procedure TMainForm.DrawSystem;
begin
     PushStateAndRun;
     If Assigned(MainSys) Then
        MainSys.Draw(ActiveLink,HScroller.Position,VScroller.Position);
     PopState
end;

Function TMainForm.GetWinHandle: Integer;
Begin
     Result:={$IFDEF FPC}Handle{$ELSE}WindowHandle{$ENDIF}
end;

procedure TMainForm.LanguageClick(Sender: TObject);
begin
     (Sender As TMenuItem).Checked:=True;
     Saved:=False
end;

procedure TMainForm.EndNotifyMaster;

Var MCast:TSockAddrIn;
    First:TMulticastMsg;
begin
     If Not MasterFlag Then
        begin
          First.Msg:=FreeNode;
          First.IP := inet_addr(PChar(HostIP));
          FillChar(MCast,SizeOf(MCast),0);
          MCast.sin_family:=AF_INET;
          MCast.sin_addr.S_addr := inet_addr(ConnectMask);
          MCast.sin_port:=ConnectPort;
          ControlSemaphore.Wait;
          sendto(OutSock,First,SizeOf(First),0,MCast,SizeOf(MCast));
          LockedFlag:=False;
          ControlSemaphore.Post
        end
end;

procedure TMainForm.NTranslateClick(Sender: TObject);

Var LangIdx:Integer;
    RunFlag:Boolean;
    MCast:TSockAddrIn;
    First:TMulticastMsg;
begin
     If Not Saved Then
        NSaveAsClick(Nil);
     If Saved Then
        begin
          ControlSemaphore.Wait;
          RunFlag:=FreeFlag Or Not Assigned(Sender);
          ControlSemaphore.Post;
          If RunFlag Then
             With TTranslator.Create(Nil) Do
               begin
                 If Not MasterFlag Then
                    begin
                      First.Msg:=BusyNode;
                      First.IP := inet_addr(PChar(HostIP));
                      FillChar(MCast,SizeOf(MCast),0);
                      MCast.sin_family:=AF_INET;
                      MCast.sin_addr.S_addr := inet_addr(ConnectMask);
                      MCast.sin_port:=ConnectPort;
                      ControlSemaphore.Wait;
                      sendto(OutSock,First,SizeOf(First),0,MCast,SizeOf(MCast));
                      ControlSemaphore.Post
                    end;

                 InactiveSystem(False);
                 LangIdx:=CurLanguageIndex;
                 If LangIdx>=0 Then
                    TranName:=Languages[LangIdx].FName
                 Else
                    TranName:='';
                 Position:=poDesigned;
                 Width:=282;
                 Height:=115;
                 Position:=poScreenCenter;
                 ShowModal;
                 ExternalForked:=efFree;
                 InactiveSystem(True);

                 If Assigned(Sender) Then EndNotifyMaster;
                 Free
               end
        end
     Else
        MessageDlg('Перед работой ОБЯЗАТЕЛЬНО необходимо сохранить модель',mtInformation,[mbOk],0)
end;

procedure TMainForm.MainPaintBoxDblClick(Sender: TObject);
begin
     DblClicked:=True
end;

procedure TMainForm.NSettingsClick(Sender: TObject);
begin
     PushStateAndRun;
     With SettingsDlg Do
       begin
         cbShowClass.Checked:=(ShowFlags And flShowClass)<>0;
         cbShowName.Checked:=(ShowFlags And flShowName)<>0;
         cbShowImage.Checked:=(ShowFlags And flShowImage)<>0;
         ApplyGroup.ItemIndex:=Byte(ApplyToAll);
         cbAutoStart.Checked:=AutoStart;
         cbAutoDeduce.Checked:=AutoDeduce;
         cbAutoReDeduce.Checked:=AutoReDeduce;
         If ShowModal=mrOk Then
            begin
              ShowFlags:=CBToFlags(cbShowClass.Checked,cbShowName.Checked,cbShowImage.Checked);
              ApplyToAll:=Boolean(ApplyGroup.ItemIndex);
              AutoStart:=cbAutoStart.Checked;
              AutoDeduce:=cbAutoDeduce.Checked;
              AutoReDeduce:=cbAutoReDeduce.Checked;
              If ApplyToAll Then
                 begin
                   MainSys.ClearFlags((Not ShowFlags) And flAllShow);
                   MainSys.SetFlags(ShowFlags);
                   DrawSystem
                 end
            end
       end;
     PopState
end;

function TMainForm.CBToFlags(_Classes,_Names,_Images:Boolean):Integer;
begin
     Result:=0;
     If _Classes Then Result:=Result Or flShowClass;
     If _Names Then Result:=Result Or flShowName;
     If _Images Then Result:=Result Or flShowImage
end;

procedure TMainForm.FlagsToCB(Flgs: Integer; var _Classes, _Names,
  _Images: Boolean);
begin
     _Classes:=(Flgs And flShowClass)<>0;
     _Names:=(Flgs And flShowName)<>0;
     _Images:=(Flgs And flShowImage)<>0
end;

procedure TMainForm.ElSettingsClick(Sender: TObject);
begin
     PushStateAndRun;
     With SettingsDlg Do
       begin
         cbShowClass.Checked:=(PopupEl.Flags And flShowClass)<>0;
         cbShowName.Checked:=(PopupEl.Flags And flShowName)<>0;
         cbShowImage.Checked:=(PopupEl.Flags And flShowImage)<>0;
         ApplyGroup.Hide;
         AutoGroupBox.Hide;
         GroupBox.Height:=GroupBox.Height-ApplyGroup.Height-10;
         Height:=Height-ApplyGroup.Height-AutoGroupBox.Height-20;
         If ShowModal=mrOk Then
            begin
              PopupEl.Flags:=(PopupEl.Flags And Not flAllShow) Or
                  CBToFlags(cbShowClass.Checked,cbShowName.Checked,cbShowImage.Checked);
              Saved:=False;
              DrawSystem
            end;
         ApplyGroup.Show;
         AutoGroupBox.Show;
         GroupBox.Height:=GroupBox.Height+ApplyGroup.Height+10;
         Height:=Height+ApplyGroup.Height+AutoGroupBox.Height+20
       end;
     PopState
end;

procedure TMainForm.NSaveAsClick(Sender: TObject);
begin
     PushStateAndRun;
     With SaveModel Do
       begin
         FileName:=MainSys.SavedName;
         InitialDir:=ExtractFilePath(FileName);
         If Execute Then
            begin
                MainSys.SaveToFile(CurLanguageName,FileName);
                Self.Caption:='АвтоГЕН - ['+ExtractFileName(FileName)+']';
                Saved:=True
            end
       end;
     PopState
end;

procedure TMainForm.SetSaved(const Value: Boolean);
begin
     FSaved:=Value;
     If FSaved Then
        MainStatusBar.SimpleText:=''
     Else
        MainStatusBar.SimpleText:=' Изменен'
end;

procedure TMainForm.LinkColorClick(Sender: TObject);
begin
     PushStateAndRun;
     With LinkColorDialog Do
       begin
         Color:=PopupLink.Color;
         If Execute Then
            begin
              PopupLink.Color:=Color;
              Saved:=False;
              DrawSystem
            end
       end;
     PopState
end;

procedure TMainForm.LinkTypeClick(Sender: TObject);
begin
     PushStateAndRun;
     With LinkTypeDlg Do
       begin
         LinkTypeGroup.ItemIndex:=Byte(PopupLink.Inform);
         If ShowModal=mrOk Then
            begin
              PopupLink.Inform:=Boolean(LinkTypeGroup.ItemIndex);
              MainSys.AnalyzeLinkStatus(PopupLink);
              If Byte(PopupLink.Inform)<>LinkTypeGroup.ItemIndex Then
                 MessageDlg('Невозможно изменить тип связи',mtError,[mbOk],0);
              Saved:=False;
              DrawSystem
            end
       end;
     PopState
end;

function TMainForm.CurLanguageIndex: Integer;

Var Found:Boolean;
begin
     Found:=False;
     Result:=0;
     While (Result<Length(Languages)) And Not Found Do
       If Languages[Result].Item.Checked Then
          Found:=True
       Else
          Inc(Result);
     If Not Found Then
        Result:=-1
end;

function TMainForm.CurLanguageName: String;

Var LangIdx:Integer;
begin
     LangIdx:=CurLanguageIndex;
     If LangIdx>=0 Then
        Result:=(*StripHotKey(*)Languages[LangIdx].Item.Caption(*)*)
     Else
        Result:=''
end;

procedure TMainForm.SelectLanguage(const Lang: String);

Var Found:Boolean;
    F:Integer;
begin
     Found:=False;
     F:=0;
     While (F<Length(Languages)) And Not Found Do
       If (*StripHotKey(*)Languages[F].Item.Caption(*)*)=Lang Then
          Found:=True
       Else
          Inc(F);
     If Found Then
        Languages[F].Item.Checked:=True
     Else
        NoLang.Checked:=True
end;

procedure TMainForm.CntPublClick(Sender: TObject);
begin
     PushStateAndRun;
     With ContactDlg Do
       begin
         Caption:='Публикация контакта "'+PopupCont.Name+'"';
         chkPublic.Checked:=PopupCont.External;
         edID.Text:=PopupCont.PublicID;
         edName.Text:=PopupCont.PublicName;
         RefSys:=MainSys;
         RefC:=PopupCont;
         If ShowModal=mrOk Then
            begin
              PopupCont.External:=chkPublic.Checked;
              PopupCont.PublicID:=edID.Text;
              PopupCont.PublicName:=edName.Text;
              Saved:=False;
              DrawSystem
            end
       end;
     PopState
end;

function TMainForm.GetConnected: Boolean;
begin
     Result:=Assigned(ControlThread) And Not ControlThread.Terminated
end;

procedure TMainForm.AddTask(const SessionID, TaskID: String;
  Files: TStringList; Lock: Boolean);

Var H,Idx:Integer;
    Tasks:TStringList;
    S, ThisName, SlaveName:String;
begin
     If Lock Then ControlSemaphore.Wait;
     Idx:=Sessions.IndexOf(SessionID);
     With Sessions Do
       If Idx>=0 Then
          begin
            Strings[Idx]:=SessionID;
            TStringList(Objects[Idx]).AddObject(TaskID,Files)
          end
       Else
          begin
            Tasks:=TStringList.Create;
            Tasks.AddObject(TaskID,Files);
            AddObject(SessionID,Tasks)
          end;
     S:=TasksDir+SuperSlash+SessionID+'.'+TaskID;
     If Not DirectoryExists(TasksDir) Then
        CreateDir(TasksDir);
     CreateDir(S);
     With Files Do
       For H:=0 To Count-1 Do
         Case (Integer(Objects[H]) And tsKindMask) Of
           tsModelFile, tsInputFile:
             If (Integer(Objects[H]) And tsMoveFlag)<>0 Then
                Begin
                  ParsePipedStr(Strings[H],ThisName,SlaveName);
                  DeleteFile(PChar(S+SuperSlash+ThisName));
                  RenameFile(ThisName,S+SuperSlash+ThisName)
                End
             Else
                CopyFile(PChar(Strings[H]),PChar(S+SuperSlash+Strings[H]),False);
         end;
     If Lock Then ControlSemaphore.Post
end;

procedure TMainForm.InactiveSystem(const State: Boolean);
begin
     ControlSemaphore.Wait;
     FreeFlag:=State;
     ControlSemaphore.Post
end;

procedure TMainForm.PopState;
begin
     InactiveSystem(States[High(States)]);
     SetLength(States,Length(States)-1)
end;

procedure TMainForm.PushStateAndRun;
begin
     ControlSemaphore.Wait;
     SetLength(States,Length(States)+1);
     States[High(States)]:=FreeFlag;
     FreeFlag:=False;
     ControlSemaphore.Post
end;

procedure TMainForm.RunEvent(var Message: TMessage);

Var Sock:TSocket;
    F:File;
    ExtTask:Boolean;
    Addr:TSockAddrIn;
    Buf,FName:String;
    Len:Integer;
    ReportSended,ModelReceived:Boolean;
begin
     ExtTask:=ExternalForked=efNode;
     If ExtTask Then
        begin
          Sock:=socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
          FillChar(Addr,SizeOf(Addr),0);
          Addr.sin_family:=AF_INET;
          Addr.sin_port:=ControlPort;
          Addr.sin_addr.S_addr := inet_addr(PChar(ExternalFileName));
          While connect(Sock,Addr,SizeOf(Addr)) < 0 Do
            Sleep(1);
          ModelReceived:=False;
          Repeat
            FName:=ReadString(Sock);
            If FName<>Pound Then
               begin
                 If Not ModelReceived Then
                    begin
                      ExternalFileName:=FName;
                      ModelReceived:=True
                    end;
                 Buf:=ReadString(Sock);
                 AssignFile(F,FName);
                 Rewrite(F,1);
                 BlockWrite(F,Buf[1],Length(Buf));
                 CloseFile(F)
               end
          Until FName=Pound;
          ExternalOutputName:=ReadString(Sock);
        end;
     RenewModel(True,ExternalFileName);
     NTranslateClick(Nil);
     If ExtTask Then
        begin
          FName:=ChangeFileExt(ExternalOutputName,'._out.pl');
          If FileExists(FName) Then
             begin
               AssignFile(F,FName);
               Reset(F,1);
               Len:=FileSize(F);
               SetLength(Buf,Len);
               BlockRead(F,Buf[1],Len);
               CloseFile(F);
               WriteString(Sock,Buf)
             end
          Else
             WriteString(Sock,Pound);
          ReportSended:=False;
          Repeat
            If Not ReportSended Then
               begin
                 ReportSended:=True;
                 FName:=ExternalOutputName
               end
            Else
               FName:=ReadString(Sock);
            If Length(FName)>0 Then
               begin
                 AssignFile(F,FName);
                 Reset(F,1);
                 Len:=FileSize(F);
                 SetLength(Buf,Len);
                 BlockRead(F,Buf[1],Len);
                 CloseFile(F);
                 WriteString(Sock,Buf)
               end
          Until Length(FName)=0;
          closesocket(Sock)
        end;
     EndNotifyMaster
end;

procedure TMainForm.MsgEvent(Var Message:TMessage);
begin
     MessageListBox.Items.Add(PString(Message.LParam)^);
     DisposeStr(PString(Message.LParam))
end;

Procedure TMainForm.EditEvent(Var Message: TMessage);

Var Obj:TElement;
Begin
     Obj:=TElement(Message.lParam);
     With TEditProps.Create(Self) Do
       begin
         PutData(Obj,False);
         If Process(ShowModal=mrOk,Obj) Then
            begin
            end
         Else
            begin
              MainSys.Elements.Remove(Obj);
              Obj.RemoveSubElements(MainSys);
              Obj.Free;
              DrawSystem
            end;
         Free
       end;
     PopState
End;

{ TControlThread }

constructor TControlThread.Create(Parent: TMainForm; _In, _Out: TSocket);
begin
     Inherited Create(True);
     InSocket:=_In;
     OutSocket:=_Out;
     ControlSemaphore := Parent.ControlSemaphore;
     WorkSemaphore := Parent.WorkSemaphore;
     WorkSemaphore.Wait;
     ControlSemaphore.Wait;
     Slaves:=TStringList.Create;
     FreeSlaves:=TStringList.Create;
     ControlSemaphore.Post
end;

procedure TControlThread.DoTerminate;
begin
     inherited;
end;

procedure TControlThread.Execute;

Var MCast:TSockAddrIn;
    MasterAddr:Integer;
    Addr:TSockAddr;
    First:TMulticastMsg;
    SlaveIP:String;
    Idx,Rslt,Len:Integer;
    RES: LongInt;
begin
     MasterAddr:=0;
     First.Msg:=RegisterMaster;
     First.IP:=INADDR_ANY;
     FillChar(MCast,SizeOf(MCast),0);
     MCast.sin_family:=AF_INET;
     MCast.sin_addr.S_addr := inet_addr(ConnectMask);
     MCast.sin_port:=ConnectPort;
     ControlSemaphore.Wait;
     Rslt:=sendto(OutSocket,First,SizeOf(First),0,MCast,SizeOf(MCast));
     ControlSemaphore.Post;
     If Rslt < 0 Then
        Terminate
     Else
        While Not Terminated Do
          begin
            Addr.sin_family := MCast.sin_family;
            Addr.sin_addr := MCast.sin_addr;
            Addr.sin_port := MCast.sin_port;
            Len:=SizeOf(Addr);
            RES := recvfrom(InSocket,First,SizeOf(First),{$IFDEF linux}MSG_DONTWAIT{$ELSE}0{$ENDIF},Addr,Len);
            If (RES < 0) Then
               Begin
                 {$IFDEF linux}
                 If SocketError <> ESockEWOULDBLOCK Then
                 {$ELSE}
                 If WSAGetLastError <> WSAEWOULDBLOCK Then
                 {$ENDIF}
                    Terminate
                 Else
                    Sleep(10);
               end
            Else
               If First.Msg=Unregister Then
                  begin
                    If Addr.sin_addr.s_addr=MasterAddr Then
                        begin
                          PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Главный узел ['+inet_ntoa(Addr.sin_addr)+'] завершил работы. Работаем самостоятельно')));
                          Terminate
                        end
                    Else If (Addr.sin_addr.s_addr = inet_addr(PChar(HostIP))) Then
                        Terminate
                    Else If MasterFlag Then
                        begin
                          ControlSemaphore.Wait;
                          Idx:=Slaves.IndexOf(inet_ntoa(Addr.sin_addr));
                          If Idx>=0 Then
                             begin
                               Slaves.Delete(Idx);
                               PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Узел ['+inet_ntoa(Addr.sin_addr)+'] завершил работу.')))
                             end;
                          Idx:=FreeSlaves.IndexOf(inet_ntoa(Addr.sin_addr));
                          If Idx>=0 Then FreeSlaves.Delete(Idx);
                          ControlSemaphore.Post
                        end
                  end
               Else If (First.Msg=FreeNode) And MasterFlag Then
                  begin
                    ControlSemaphore.Wait;
                    Addr.sin_family:=AF_INET;
                    Addr.sin_addr.s_addr:=First.IP;
                    SlaveIP:=inet_ntoa(Addr.sin_addr);
                    If FreeSlaves.IndexOf(SlaveIP)>=0 Then
                       begin
                         ControlSemaphore.Post;
                         PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Коллизия: ['+SlaveIP+'] свободен, но один из узлов сообщает об его освобождении')))
                       end
                    Else
                       begin
                         FreeSlaves.Add(SlaveIP);
                         ControlSemaphore.Post;
                         PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Узел ['+SlaveIP+'] освободился')))
                       end
                  end
               Else If (First.Msg=BusyNode) And MasterFlag Then
                  begin
                    ControlSemaphore.Wait;
                    Addr.sin_family:=AF_INET;
                    Addr.sin_addr.s_addr:=First.IP;
                    SlaveIP:=inet_ntoa(Addr.sin_addr);
                    Idx:=FreeSlaves.IndexOf(SlaveIP);
                    If Idx>=0 Then
                       begin
                         FreeSlaves.Delete(Idx);
                         PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Узел ['+SlaveIP+'] занят')))
                       end;
                    ControlSemaphore.Post
                  end
               Else If (First.Msg=CanIWork) And MasterFlag Then
                  begin
                    ControlSemaphore.Wait;
                    Addr.sin_family:=AF_INET;
                    Addr.sin_addr.s_addr:=First.IP;
                    SlaveIP:=inet_ntoa(Addr.sin_addr);
                    Idx:=FreeSlaves.IndexOf(SlaveIP);
                    If Idx>=0 Then
                       begin
                         FreeSlaves.Delete(Idx);
                         PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Узел ['+SlaveIP+'] занят')));
                         First.Msg:=YouAreFree
                       end
                    Else
                       First.Msg:=YouAreLocked;
                    First.IP:=Addr.sin_addr.s_addr;
                    First.Info:=INADDR_ANY;
                    sendto(OutSocket,First,SizeOf(First),0,MCast,SizeOf(MCast));
                    ControlSemaphore.Post
                  end
               Else If (First.Msg=RequestNode) And MasterFlag Then
                  begin
                    ControlSemaphore.Wait;
                    Addr.sin_family:=AF_INET;
                    Addr.sin_addr.s_addr:=First.IP;
                    RequestingList.Add(inet_ntoa(Addr.sin_addr));
                    ControlSemaphore.Post
                  end
               Else If (First.Msg=ThisIsNode) And (First.IP=inet_addr(PChar(HostIP))) And Not MasterFlag Then
                  begin
                    ControlSemaphore.Wait;
                    Addr.sin_family:=AF_INET;
                    Addr.sin_addr.s_addr:=First.Info;
                    FreeSlaves.Add(inet_ntoa(Addr.sin_addr));
                    ControlSemaphore.Post;
                    PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Получил узел ['+inet_ntoa(Addr.sin_addr)+'] для задания')))
                  end
               Else If (First.Msg=YouAreFree) And (First.IP=inet_addr(PChar(HostIP))) And Not MasterFlag Then
                  begin
                    LockedFlag:=False;
                    WorkSemaphore.Post;
                    WorkSemaphore.Wait
                  end
               Else If (First.Msg=YouAreLocked) And (First.IP=inet_addr(PChar(HostIP))) And Not MasterFlag Then
                  begin
                    LockedFlag:=True;
                    WorkSemaphore.Post;
                    WorkSemaphore.Wait
                  end
               Else If (First.Msg=YouAreBusy) And (First.IP=inet_addr(PChar(HostIP))) And Not MasterFlag Then
                  begin
                    ControlSemaphore.Wait;
                    ExternalForked:=efNode;
                    Addr.sin_family:=AF_INET;
                    Addr.sin_addr.s_addr:=First.Info;
                    ExternalFileName:=inet_ntoa(Addr.sin_addr);
                    ControlSemaphore.Post;
                    PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Готов к получению задания от ['+inet_ntoa(Addr.sin_addr)+']')));
                    PostMessage(MainForm.WinHandle,WM_PGEN_RUN,0,0);
                  end
               Else If Addr.sin_addr.s_addr<>inet_addr(PChar(HostIP)) Then
                  If (First.Msg=RegisterSlave) And (First.IP=inet_addr(PChar(HostIP))) Then
                     begin
                       ControlSemaphore.Wait;
                       MasterFlag:=False;
                       MasterAddr:=Addr.sin_addr.s_addr;
                       ControlSemaphore.Post;
                       PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Узел зарегистрирован как вспомогательный. Главный узел = ['+inet_ntoa(Addr.sin_addr)+']')))
                     end
                  Else If First.Msg=RegisterMaster Then
                     If MasterFlag Then
                        begin
                          First.Msg:=RegisterSlave;
                          First.IP:=Addr.sin_addr.s_addr;
                          ControlSemaphore.Wait;
                          sendto(OutSocket,First,SizeOf(First),0,MCast,SizeOf(MCast));
                          Slaves.Add(inet_ntoa(Addr.sin_addr));
                          FreeSlaves.Add(inet_ntoa(Addr.sin_addr));
                          ControlSemaphore.Post;
                          PostMessage(MainForm.WinHandle,WM_PGEN_MSG,0,Integer(NewStr('Зарегистрирован дополнительный узел = ['+inet_ntoa(Addr.sin_addr)+']')))
                        end
          end
end;

{ TTask }

Constructor TTask.Create(const _ID: String);
begin
     Inherited Create;
     ID:=_ID;
     Files:=TStringList.Create
end;

Destructor TTask.Destroy;
begin
     Files.Free;
     Inherited
end;

{ TQueryThread }

constructor TQueryThread.Create(Parent: TMainForm; _Out: TSocket);
begin
     Inherited Create(True);
     OutSocket:=_Out;
     ControlSemaphore := Parent.ControlSemaphore;
     WorkSemaphore := Parent.WorkSemaphore;
     ControlSemaphore.Wait;
     Sessions:=TStringList.Create;
     Threads:=TList.Create;
     RequestingList:=TStringList.Create;
     ControlSemaphore.Post
end;

procedure TQueryThread.DoTerminate;

Var F:Integer;
begin
     inherited;
     With Threads Do
       begin
         For F:=0 To Count-1 Do
           With TTaskThread(Items[F]) Do
             begin
               Terminate;
               WaitFor;
               Free
             end;
         Free
       end;
     closesocket(ExchangeSocket)
end;

procedure TQueryThread.Execute;

Var ContinueFlag:Boolean;
    Requested:Boolean;
    NowName,SlaveName:String;
    MCast:TSockAddrIn;
    Msg:TMulticastMsg;
    F,G,H,K:Integer;
    Len:{$IFDEF linux}LongWord{$ELSE}LongInt{$ENDIF};
    Buf:String;
    _File:File;
    One:Integer;
    NewSock:TSocket;
    Addr:TSockAddrIn;
begin
     ExchangeSocket:=socket(AF_INET,SOCK_STREAM,IPPROTO_IP);
     One:=1;
     setsockopt(ExchangeSocket,SOL_SOCKET,SO_REUSEADDR,@One,SizeOf(One));
     FillChar(Addr,SizeOf(Addr),0);
     Addr.sin_family:=AF_INET;
     Addr.sin_port:=ControlPort;
     Addr.sin_addr.S_addr := inet_addr(PChar(HostIP));
     bind(ExchangeSocket,Addr,SizeOf(Addr));

     FillChar(MCast,SizeOf(MCast),0);
     MCast.sin_family:=AF_INET;
     MCast.sin_addr.S_addr := inet_addr(ConnectMask);
     MCast.sin_port:=ConnectPort;
     Repeat
        ControlSemaphore.Wait;
        ContinueFlag:=Assigned(Sessions);
        If ContinueFlag Then
           With Sessions Do
             begin
               F:=0;
               While F<Count Do
                 With TStringList(Objects[F]) Do
                   If Count=0 Then
                      begin
                        Free;
                        Sessions.Delete(F)
                      end
                   Else
                     begin
                       G:=0;
                       While G<Count Do
                         If FreeFlag And Not LockedFlag Then
                            begin
                              If Not MasterFlag Then
                                 begin
                                   Msg.Msg:=CanIWork;
                                   Msg.IP := inet_addr(PChar(HostIP));
                                   sendto(OutSocket,Msg,SizeOf(Msg),0,MCast,SizeOf(MCast));
                                   WorkSemaphore.Wait;
                                   WorkSemaphore.Post
                                 end;
                              If Not LockedFlag Then
                                 begin
                                   ExternalFileName:='';
                                   ExternalForked:=efSelf;
                                   With TStringList(Objects[G]) Do
                                     begin
                                       For H:=0 To Count-1 Do
                                         If (Integer(Objects[H]) And tsKindMask)=tsModelFile Then
                                            ExternalFileName:=Strings[H]
                                         Else If (Integer(Objects[H]) And tsKindMask)=tsReportFile Then
                                            ParsePipedStr(Strings[H],NowName,ExternalOutputName)
                                         Else If (Integer(Objects[H]) And tsKindMask)=tsInputFile Then
                                            begin
                                              ParsePipedStr(Strings[H],NowName,SlaveName);
                                              Buf:=ExtractFileName(NowName);
                                              If AnsiCompareFileName(Buf,SlaveName)<>0 Then
                                                 begin
                                                   Buf:=TasksDir+SuperSlash+Sessions.Strings[F]+'.'+TStringList(Sessions.Objects[F]).Strings[G];
                                                   DeleteFile(PChar(Buf+SuperSlash+SlaveName));
                                                   RenameFile(Buf+SuperSlash+NowName,Buf+SuperSlash+SlaveName)
                                                 end
                                            end;
                                       Free
                                     end;
                                   CopyMoveStructure(TasksDir+SuperSlash+Sessions.Strings[F]+'.'+Strings[G],'.',True);
                                   RemoveDir(TasksDir+SuperSlash+Sessions.Strings[F]+'.'+Strings[G]);
                                   Delete(G);
                                   FreeFlag:=False;
                                   PostMessage(MainForm.WinHandle,WM_PGEN_RUN,0,0)
                                 end
                              Else
                                 Inc(G)
                            end
                         Else
                            Inc(G);
                       If Not (FreeFlag Or LockedFlag) Then
                          begin
                            G:=0;
                            While G<Count Do
                              begin
                                Requested:=MasterFlag;
                                If Not Requested Then
                                   If Assigned(Objects[G]) Then
                                      With TStringList(Objects[G]) Do
                                        For H:=0 To Count-1 Do
                                          If (Integer(Objects[H]) And tsReqFlag)<>0 Then
                                             begin
                                               Requested:=True;
                                               Break
                                             end;
                                If Requested Then
                                   If FreeSlaves.Count>0 Then
                                      begin
                                        // spawn, send, set sockets
                                        // start wait to receive
                                        Msg.Msg:=YouAreBusy;
                                        Msg.IP := inet_addr(PChar(FreeSlaves.Strings[0]));
                                        Msg.Info := inet_addr(PChar(HostIP));
                                        sendto(OutSocket,Msg,SizeOf(Msg),0,MCast,SizeOf(MCast));
                                        CopyMoveStructure(TasksDir+SuperSlash+Sessions.Strings[F]+'.'+Strings[G],'.',True);
                                        RemoveDir(TasksDir+SuperSlash+Sessions.Strings[F]+'.'+Strings[G]);
                                        listen(ExchangeSocket,1);
                                        Len:=SizeOf(Addr);
                                        NewSock:=accept(ExchangeSocket,@Addr,Len);
                                        FreeSlaves.Delete(FreeSlaves.IndexOf(inet_ntoa(Addr.sin_addr)));
                                        With TStringList(Objects[G]) Do
                                          begin
                                            For H:=0 To Count-1 Do
                                              If (Integer(Objects[H]) And tsKindMask) In [tsModelFile,tsInputFile] Then
                                                 begin
                                                   ParsePipedStr(Strings[H],NowName,SlaveName);
                                                   WriteString(NewSock,SlaveName);
                                                   AssignFile(_File,NowName);
                                                   Reset(_File,1);
                                                   Len:=FileSize(_File);
                                                   SetLength(Buf,Len);
                                                   BlockRead(_File,Buf[1],Len);
                                                   CloseFile(_File);
                                                   DeleteFile(PChar(NowName));
                                                   WriteString(NewSock,Buf)
                                                 end;
                                            WriteString(NewSock,Pound);
                                            For H:=0 To Count-1 Do
                                              If (Integer(Objects[H]) And tsKindMask)=tsReportFile Then
                                                 begin
                                                   ParsePipedStr(Strings[H],NowName,SlaveName);
                                                   WriteString(NewSock,SlaveName);
                                                   Break
                                                 end
                                            end;
                                        // create thread waiting for data, closing socket, destroing list of files
                                        Threads.Add(TTaskThread.Create(Sessions.Strings[F]+'.'+Strings[G],NewSock,TStringList(Objects[G])));
                                        Delete(G)
                                      end
                                   Else
                                      Inc(G)
                                Else
                                   begin
                                     // send request
                                     Msg.Msg:=RequestNode;
                                     Msg.IP := inet_addr(PChar(HostIP));
                                     sendto(OutSocket,Msg,SizeOf(Msg),0,MCast,SizeOf(MCast));
                                     Sleep(100);
                                     With TStringList(Objects[G]) Do
                                       Objects[0]:=TObject(Integer(Objects[0]) Or tsReqFlag);
                                     Inc(G)
                                   end
                              end
                          end;
                       Inc(F)
                     end;
               If FreeSlaves.Count>0 Then
                  If MasterFlag Then
                     // if there are requests => handle them
                     With RequestingList Do
                       begin
                         H:=0;
                         While H<Count Do
                           begin
                             NowName:=Strings[H];
                             K:=FreeSlaves.IndexOf(NowName);
                             If K>=0 Then FreeSlaves.Delete(K);
                             If FreeSlaves.Count>0 Then
                                begin
                                  Msg.Msg:=ThisIsNode;
                                  Msg.IP := inet_addr(PChar(NowName));
                                  Msg.Info := inet_addr(PChar(FreeSlaves.Strings[0]));
                                  sendto(OutSocket,Msg,SizeOf(Msg),0,MCast,SizeOf(MCast));
                                  Msg.Msg:=YouAreBusy;
                                  Msg.IP := inet_addr(PChar(FreeSlaves.Strings[0]));
                                  Msg.Info := inet_addr(PChar(NowName));
                                  sendto(OutSocket,Msg,SizeOf(Msg),0,MCast,SizeOf(MCast));
                                  FreeSlaves.Delete(0);
                                  Delete(H)
                                end
                             Else
                                Inc(H);
                             If K>=0 Then FreeSlaves.Add(NowName);
                             Sleep(50)
                           end
                       end
                  Else
                    // if there is no tasks and free slaves exist => return them.
                    If Count>0 Then
                       With FreeSlaves Do
                         begin
                           For H:=0 To Count-1 Do
                             begin
                               Msg.Msg:=FreeNode;
                               Msg.IP := inet_addr(PChar(Strings[H]));
                               sendto(OutSocket,Msg,SizeOf(Msg),0,MCast,SizeOf(MCast));
                               Sleep(100)
                             end;
                           Clear
                         end
             end;
        ControlSemaphore.Post;
        Sleep(500)
     Until Not ContinueFlag;
     Terminate
end;

{ TTaskThread }

constructor TTaskThread.Create(Const _ID:String; _NewSock: TSocket;
  _FList: TStringList);
begin
     Inherited Create(False);
     ID:=_ID;
     NewSock:=_NewSock;
     FList:=_FList
end;

procedure TTaskThread.DoTerminate;
begin
     inherited;
     closesocket(NewSock);
     FList.Free
end;

procedure TTaskThread.Execute;

Var H: Integer;
    Buf: String;
    OutputName, ThisName, SlaveName: String;
begin
     With FList Do
       begin
         For H:=0 To Count-1 Do
           If (Integer(Objects[H]) And tsKindMask)=tsReportFile Then
              begin
                ParsePipedStr(Strings[H],OutputName,SlaveName);
                Buf:=ReadString(NewSock);
                If Buf<>Pound Then
                   CreateStrFile(ChangeFileExt(OutputName,'._out.pl'),Buf);
                CreateStrFile(OutputName,ReadString(NewSock));
                Break
              end;
         For H:=0 To Count-1 Do
           If (Integer(Objects[H]) And tsKindMask)=tsOutputFile Then
              begin
                ParsePipedStr(Strings[H],ThisName,SlaveName);
                WriteString(NewSock,SlaveName);
                CreateStrFile(ThisName,ReadString(NewSock))
              end
       end;
     WriteString(NewSock,'');
     CreateStrFile(ChangeFileExt(OutputName,'.ok'),'');
     Terminate
end;

initialization
  {$IFDEF FPC}
  {$i Main.lrs}
  {$ELSE}
  {$R *.dfm}
  {$ENDIF}

end.
