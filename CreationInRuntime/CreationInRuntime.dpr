program CreationInRuntime;

uses
  Vcl.Forms,
  CreationInRuntimeForm in 'CreationInRuntimeForm.pas' {frmCreationInRuntime};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmCreationInRuntime, frmCreationInRuntime);
  Application.Run;
end.
