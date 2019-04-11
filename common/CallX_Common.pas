unit CallX_Common;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes;

const
  iUSER_LOGGEDIN_OK      = 0;// (login successful, otherwise error code)
  iUSER_ALREADY_LOGGEDIN = 1;// (answer on CheckUserLoginStatus_Method, if current CID is already authorized at TransportRouter)
  iNO_USER_LOGGEDIN      = 2;// (answer on CheckUserLoginStatus_Method, if current CID is not authorized at TransportRouter - can try to login)
  iACCESS_DENIED         = 3;// (incorrect password or other problems with DB)
  iSILENT_REJECT_LOGIN   = 4;// (client shouldn't show error to user (example: incorrect AutoLoginKey))
  iLICENSE_USER_LIMIT    = 5;// (license restriction of online users reached, server cannot login you)
  iUSER_DISABLED         = 6;// (user exist, but he is disabled to use this server)
  iRETRY_LOGIN           = 7;// (client should retry login after timeout (value in container or default), due to server busy or other server problems)
  iINVALID_CLIENT_TYPE   = 8;// (user cannot login using this client app (should use other type of client app))

type
  TMyStatus = (csBeforeInit, csNone, csConnect, csLogin, csNormal, csWait, csInConference, csClose);

//* -1      - невалидный пользователь
// 0       - пользователь оффлайн
// 1       - пользователь доступен
// 2       - пользователь занят
// 5       - пользователь находится в групповой конференции, которую создал он сам и в нее можно попроситься
TUserStatus = (usUnknown, usOffline, usAvialable, usBusy, usConferenceOwner);

function GetShiftDown : Boolean;
function IntToMyStatus(AState: integer): TMyStatus;
function IntToUserStatus(AState: integer): TUserStatus;
function IntToMyStringState(AState: integer): string;
function GetLoginErrorMsg(AErrorCode: integer): string;

implementation

uses rcstrings;

function GetShiftDown : Boolean;
begin
  Result := HiWord(GetKeyState(VK_SHIFT)) <> 0;
end;

function IntToMyStatus(AState: integer): TMyStatus;
begin
  Result := csNone;

  case AState of
    0: Result := csNone;
    1: Result := csConnect;
    2: Result := csLogin;
    3: Result := csNormal;
    4: Result := csWait;
    5: Result := csInConference;
    6: Result := csClose;
    else
      Result := csNone;
  end;
end;

function IntToUserStatus(AState: integer): TUserStatus;
begin
  Result := usUnknown;

  case AState of
    0: Result := usOffline;
    1: Result := usAvialable;
    2: Result := usBusy;
    5: Result := usConferenceOwner;
  end;
end;

function IntToMyStringState(AState: integer): string;
begin
  Result := 'None';

  case AState of
    0: Result := 'None';
    1: Result := 'Connecting...';
    2: Result := 'Authorization...';
    3: Result := 'Normal';
    4: Result := 'Wait';
    5: Result := 'In Conference';
    6: Result := 'Close';
    else
      Result := 'Unknown';
  end;
end;

function GetLoginErrorMsg(AErrorCode: integer): string;
begin
  if AErrorCode = 0 then
    Result := sUSER_LOGGEDIN_OK
  else if AErrorCode = 1 then
    Result := sUSER_ALREADY_LOGGEDIN
  else if AErrorCode = 2 then
    Result := sNO_USER_LOGGEDIN
  else if AErrorCode = 3 then
    Result := sACCESS_DENIED
  else if AErrorCode = 4 then
    Result := sSILENT_REJECT_LOGIN
  else if AErrorCode = 5 then
    Result := sLICENSE_USER_LIMIT
  else if AErrorCode = 6 then
    Result := sUSER_DISABLED
  else if AErrorCode = 7 then
    Result := sRETRY_LOGIN
  else if AErrorCode = 8 then
    Result := sINVALID_CLIENT_TYPE;
end;

end.
