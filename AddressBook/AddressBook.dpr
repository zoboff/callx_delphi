program AddressBook;

uses
  Vcl.Forms,
  AddressBookForm in 'AddressBookForm.pas' {frmAddressBook};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmAddressBook, frmAddressBook);
  Application.Run;
end.
