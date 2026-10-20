unit Orbi.Database;

interface

uses
  FireDAC.Comp.Client;

function NewConnection: TFDConnection;

implementation

uses
  Orbi.Config,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.DApt,
  FireDAC.Phys,
  FireDAC.Phys.PG,
  FireDAC.Phys.PGDef,
  FireDAC.Stan.Error;

function NewConnection: TFDConnection;
begin
  Result := TFDConnection.Create(nil);
  Result.LoginPrompt := False;
  Result.Params.Clear;
  Result.Params.Add('DriverID=PG');
  Result.Params.Add('Server=' + TOrbiConfig.DBHost);
  Result.Params.Add('Database=' + TOrbiConfig.DBName);
  Result.Params.Add('User_Name=' + TOrbiConfig.DBUser);
  Result.Params.Add('Password=' + TOrbiConfig.DBPassword);
  Result.Params.Add('Port=5432');
  Result.Params.Add('CharacterSet=UTF8');
  Result.Connected := True;
end;

end.
