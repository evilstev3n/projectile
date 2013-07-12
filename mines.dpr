program mines;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {Form1},
  UnitSoundThread in 'UnitSoundThread.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
