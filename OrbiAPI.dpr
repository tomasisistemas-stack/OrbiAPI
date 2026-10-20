program OrbiAPI;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Horse,
  Orbi.Config in 'src\Orbi.Config.pas',
  Orbi.Database in 'src\Orbi.Database.pas',
  Orbi.Security in 'src\Orbi.Security.pas',
  Orbi.Routes in 'src\Orbi.Routes.pas';

begin
  try
    THorse.Use(OrbiHashAuthMiddleware);

    RegisterRoutes;

    Writeln('Orbi API running on port ' + TOrbiConfig.ServerPort.ToString);
    THorse.Listen(TOrbiConfig.ServerPort);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName + ': ' + E.Message);
      Halt(1);
    end;
  end;
end.
