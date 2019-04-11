unit AddressBookForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.OleCtrls, TrueConf_CallXLib_TLB,
  Vcl.Menus, ConfigForm, UserCacheUnit, Vcl.ExtCtrls, Vcl.StdCtrls, CallX_Common,
  HardwareForm, System.Actions, Vcl.ActnList, System.ImageList, Vcl.ImgList,
  Vcl.ComCtrls;

const
  TITLE = 'Address Book Demo';

type
  TfrmAddressBook = class(TForm)
    MainMenu: TMainMenu;
    File1: TMenuItem;
    miExit: TMenuItem;
    ools1: TMenuItem;
    miConnectionSetting: TMenuItem;
    miHardwareSetting: TMenuItem;
    CallX: TTrueConfCallX;
    Splitter1: TSplitter;
    pmAddressBook: TPopupMenu;
    ActionList: TActionList;
    actCall: TAction;
    Call1: TMenuItem;
    ImageList: TImageList;
    Panel1: TPanel;
    lvAddressBook: TListView;
    pnlButtons: TPanel;
    Button1: TButton;
    Button2: TButton;
    actHangUp: TAction;
    procedure miExitClick(Sender: TObject);
    procedure miConnectionSettingClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure CallXAbookUpdate(ASender: TObject;
      const eventDetails: WideString);
    procedure CallXXAfterStart(Sender: TObject);
    procedure CallXXChangeState(ASender: TObject; prevState, newState: Integer);
    procedure CallXServerConnected(ASender: TObject;
      const eventDetails: WideString);
    procedure actCallUpdate(Sender: TObject);
    procedure actCallExecute(Sender: TObject);
    procedure CallXInviteReceived(ASender: TObject;
      const eventDetails: WideString);
    procedure lvAddressBookDblClick(Sender: TObject);
    procedure actHangUpExecute(Sender: TObject);
    procedure actHangUpUpdate(Sender: TObject);
    procedure CallXXError(ASender: TObject; errorCode: Integer;
      const errorMsg: WideString);
    procedure CallXXLoginError(ASender: TObject; errorCode: Integer);
    procedure CallXDetailInfo(ASender: TObject; const eventDetails: WideString);
    procedure miHardwareSettingClick(Sender: TObject);
    procedure CallXLogout(ASender: TObject; const eventDetails: WideString);
  private
    { Private declarations }
    FCallXSettings: TCallXSettings;
    FStarted: boolean;
    // Address book
    FUserStatusCache: TUserCache;
    FStatus: TMyStatus;
    FMyDetailInfo: string;
  protected
    procedure WriteLog(ALine: string);
    procedure ShowConfigurator;
    procedure UpdateAddressBook;
  public
    { Public declarations }
  end;

var
  frmAddressBook: TfrmAddressBook;

implementation

{$R *.dfm}

uses LogUnit;

//* -1      - невалидный пользователь
// 0       - пользователь оффлайн
// 1       - пользователь доступен
// 2       - пользователь занят
// 5       - пользователь находится в групповой конференции, которую создал он сам и в нее можно попроситься
// TTUserStatus = (usUnknown, usOffline, usAvialable, usBusy, usConferenceOwner);
function UserToRowText(AUserID, ADisplayName: string; AUserStatus: integer): string;
var status: TUserStatus;
begin
  Result := ADisplayName;
  status := IntToUserStatus(AUserStatus);
  case status of
    usUnknown:         Result := Format('[unknown]%s', [ADisplayName]);
    usOffline:         Result := Format('[offline]%s', [ADisplayName]);
    usAvialable:       Result := Format('[avialable]%s', [ADisplayName]);
    usBusy:            Result := Format('[busy]%s', [ADisplayName]);
    usConferenceOwner: Result := Format('[conference owner]%s', [ADisplayName]);
  end;
end;

function StatusToImageIndex(AStatus: integer): integer;
begin
  Result := 0;

  case IntToUserStatus(AStatus) of
    usOffline: Result := 1;
    usAvialable: Result := 2;
    usBusy: Result := 3;
    usConferenceOwner: Result := 4;
  end;
end;

procedure TfrmAddressBook.actCallExecute(Sender: TObject);
var sCallID: string;
begin
  if lvAddressBook.ItemIndex < 0 then
    Exit;

  sCallID := lvAddressBook.Items[lvAddressBook.ItemIndex].SubItems[0];
  CallX.call(sCallID);
end;

procedure TfrmAddressBook.actCallUpdate(Sender: TObject);
begin
  actCall.Enabled := (FStatus = csNormal) and (lvAddressBook.ItemIndex > -1);
end;

procedure TfrmAddressBook.actHangUpExecute(Sender: TObject);
begin
  CallX.hangUp;
end;

procedure TfrmAddressBook.actHangUpUpdate(Sender: TObject);
begin
  actHangUp.Enabled := FStatus in [csWait, csInConference];
end;

procedure TfrmAddressBook.CallXAbookUpdate(ASender: TObject;
  const eventDetails: WideString);
var s: string;
begin
  s := eventDetails;
  FUserStatusCache.Update(s);
  UpdateAddressBook;
end;

procedure TfrmAddressBook.CallXDetailInfo(ASender: TObject;
  const eventDetails: WideString);
begin
  FMyDetailInfo := eventDetails;
  MessageDlg('DetailInfo:'#13#10 + eventDetails, mtInformation, [mbOK], 0);
end;

procedure TfrmAddressBook.CallXInviteReceived(ASender: TObject;
  const eventDetails: WideString);
begin
  CallX.accept;
end;

procedure TfrmAddressBook.CallXLogout(ASender: TObject;
  const eventDetails: WideString);
begin
  FMyDetailInfo := '';
end;

procedure TfrmAddressBook.CallXServerConnected(ASender: TObject;
  const eventDetails: WideString);
begin
  WriteLog('OnServerConnected: ' + eventDetails);
  if (FCallXSettings.sUser <> '') and (FCallXSettings.sPassword <> '') then
  begin
    WriteLog('Try to login: ' + FCallXSettings.sUser);
    CallX.login(FCallXSettings.sUser, FCallXSettings.sPassword)
  end
  else
    WriteLog('Empty login info');
end;

procedure TfrmAddressBook.CallXXAfterStart(Sender: TObject);
begin
  WriteLog('OnXAfterStart: ==============================================');

  if (FCallXSettings.sServer <> '') or ((FCallXSettings.sUser <> '') and (FCallXSettings.sPassword <> '')) then
    CallX.connectToServer(FCallXSettings.sServer)
  else
    WriteLog('Empty connect & login info');

  if TfrmHardware.ApplySettings(self, TfrmConfigurator.GetRegKey, CallX) then
  begin

  end;

  FStarted := True;

  miConnectionSetting.Enabled := True;
  miHardwareSetting.Enabled := True;
end;

procedure TfrmAddressBook.CallXXChangeState(ASender: TObject; prevState,
  newState: Integer);
begin
  FStatus := IntToMyStatus(newState);
  Caption := Format('%s User: %s [%s]', [TITLE, FCallXSettings.sUser, IntToMyStringState(newState)]);
  if (FStatus = csNormal) and (FMyDetailInfo = '') then
    CallX.getContactDetails(FCallXSettings.sUser);
end;

procedure TfrmAddressBook.CallXXError(ASender: TObject; errorCode: Integer;
  const errorMsg: WideString);
begin
  MessageDlg(errorMsg, mtError, [mbOK], 0);
end;

procedure TfrmAddressBook.CallXXLoginError(ASender: TObject;
  errorCode: Integer);
begin
  MessageDlg(GetLoginErrorMsg(errorCode), mtError, [mbOK], 0);
end;

procedure TfrmAddressBook.FormCreate(Sender: TObject);
begin
  FStatus := csBeforeInit;
  Caption := TITLE + ' [connecting...]';

  TfrmConfigurator.LoadSettings(FCallXSettings);
  FUserStatusCache := TUserCache.Create;
  lvAddressBook.Clear;
  with lvAddressBook.Items.Add do
  begin
    Caption := 'Loading...';
    ImageIndex := -1;
  end;
end;

procedure TfrmAddressBook.FormDestroy(Sender: TObject);
begin
  CallX.shutdown;
  FreeAndNil(FUserStatusCache);
end;

procedure TfrmAddressBook.lvAddressBookDblClick(Sender: TObject);
begin
  if actCall.Enabled then
    actCall.Execute;
end;

procedure TfrmAddressBook.miConnectionSettingClick(Sender: TObject);
begin
  if FStarted then
    ShowConfigurator;
end;

procedure TfrmAddressBook.miExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmAddressBook.miHardwareSettingClick(Sender: TObject);
begin
  if TfrmHardware.ShowDialog(self, TfrmConfigurator.GetRegKey, CallX) then
  begin

  end;
end;

procedure TfrmAddressBook.ShowConfigurator;
var FullProgPath: PAnsiChar;
begin
  with TfrmConfigurator.Create(self) do
  begin
    CallX := self.CallX;
    if ShowModal = mrOk then
    begin

    end;
  end;
end;

procedure TfrmAddressBook.UpdateAddressBook;
var i, idx: integer;
  sSelectedUser: string;
  item: TListItem;
begin
  if lvAddressBook.ItemIndex > -1 then
    sSelectedUser := lvAddressBook.Items[lvAddressBook.ItemIndex].Caption;

  lvAddressBook.Items.BeginUpdate;
  try
    lvAddressBook.Items.Clear;
    for i := 0 to FUserStatusCache.Count - 1 do begin
      with lvAddressBook.Items.Add do begin
        Caption := FUserStatusCache[i].DisplayName;
        ImageIndex := StatusToImageIndex(FUserStatusCache[i].Status);
        SubItems.Add(FUserStatusCache[i].ID)
      end;
    end;
  finally
    lvAddressBook.Items.EndUpdate;
  end;

  item := lvAddressBook.FindCaption(0, sSelectedUser, False, False, False);
  if Assigned(item) then
    lvAddressBook.Selected := item;
end;

procedure TfrmAddressBook.WriteLog(ALine: string);
begin
  if not FCallXSettings.bWriteLog then
    Exit;

  { write to log file }
  Log(NowToString + ' ' + ALine);
end;

end.
