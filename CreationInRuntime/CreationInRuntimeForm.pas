unit CreationInRuntimeForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.OleCtrls,
  TrueConf_CallXLib_TLB, Vcl.StdCtrls;

type
  TfrmCreationInRuntime = class(TForm)
    ScrollBox1: TScrollBox;
    Splitter1: TSplitter;
    FlowPanel: TFlowPanel;
    CallX: TTrueConfCallX;
    GroupBox1: TGroupBox;
    memoCameras: TMemo;
    procedure CallXXAfterStart(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    procedure RuntimeCallXXAfterStart(Sender: TObject);
  public
    { Public declarations }
  end;

var
  frmCreationInRuntime: TfrmCreationInRuntime;

implementation

{$R *.dfm}

procedure TfrmCreationInRuntime.CallXXAfterStart(Sender: TObject);
var i: integer;
begin
  memoCameras.Lines.Text := CallX.XGetCameraList;
  if memoCameras.Lines.Count > 0 then
  begin
    CallX.XSelectCamera(memoCameras.Lines[0]);
    for i := 1 to memoCameras.Lines.Count - 1 do
    begin
      // runtime created
      with TTrueConfCallX.Create(Self) do
      begin
        Name := 'CallX' + IntToStr(i);
        Parent := FlowPanel;
        Width := 360;
        Height := 240;
        Tag := i;
        // for set a web camera
        OnXAfterStart := RuntimeCallXXAfterStart;
      end;

    end;
  end
  else begin
    memoCameras.Lines.Text := 'Empty';
    MessageDlg('You have no one camera', mtInformation, [mbOk], 0);
  end;
end;

procedure TfrmCreationInRuntime.FormClose(Sender: TObject;
  var Action: TCloseAction);
var i: integer;
begin
  if Action = caFree then
    // Must shouting down each CallX
    for I := 0 to ComponentCount - 1 do
      if (Components[i] <> CallX) and (Components[i] is TTrueConfCallX) then
        TTrueConfCallX(Components[i]).shutdown;
end;

procedure TfrmCreationInRuntime.RuntimeCallXXAfterStart(Sender: TObject);
var iCameraIndex: integer;
  sCameraName: string;
begin
  iCameraIndex := TTrueConfCallX(Sender).Tag;
  sCameraName := memoCameras.Lines[iCameraIndex];
  // set a camera by name
  TTrueConfCallX(Sender).XSelectCamera(sCameraName);
end;

end.
