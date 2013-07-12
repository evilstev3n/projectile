{
usage:
procedure TForm1.Button3Click(Sender: TObject);
begin
  with TTTSThread.Create(true) do begin
    SetFileName(Memo1.Text);
    FreeOnTerminate := true;
    Resume;
  end;
end;
}

unit UnitSoundThread;

interface

uses
  Windows
  , SysUtils
  , Classes
  , MMSystem ;

type
  TSoundThread = class(TThread)
  private
    { Private declarations }
    filename: string;
  protected
    procedure Execute; override;
  public
    procedure SetFileName(const text: string);
  end;

implementation

procedure TSoundThread.Execute;
begin
  //PlaySound(PChar(snd), hInstance, SND_ASYNC or SND_MEMORY or SND_RESOURCE);
  if FileExists(filename) then
  begin
    sndPlaySound(PChar(filename),
      SND_ASYNC
      //SND_NODEFAULT or SND_ASYNC or SND_LOOP
      );
  end;
end;

// imposto variabili della classe
procedure TSoundThread.SetFileName(const text: string);
begin
  filename := text;
end;

initialization

finalization

end.

