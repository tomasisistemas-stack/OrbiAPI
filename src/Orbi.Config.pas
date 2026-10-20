unit Orbi.Config;

interface

uses
  System.SysUtils;

type
  TOrbiConfig = class
  public
    class function ServerPort: Integer;
    class function DBHost: string;
    class function DBName: string;
    class function DBUser: string;
    class function DBPassword: string;
    class function APIHash: string;
  end;

implementation

uses
  System.IniFiles;

function IniPath: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'orbiapi.ini';
end;

function ReadIniString(const ASection, AKey, ADefault: string): string;
var
  LIni: TIniFile;
begin
  LIni := TIniFile.Create(IniPath);
  try
    Result := LIni.ReadString(ASection, AKey, ADefault);
  finally
    LIni.Free;
  end;
end;

function ReadIniInteger(const ASection, AKey: string; ADefault: Integer): Integer;
var
  LIni: TIniFile;
begin
  LIni := TIniFile.Create(IniPath);
  try
    Result := LIni.ReadInteger(ASection, AKey, ADefault);
  finally
    LIni.Free;
  end;
end;

class function TOrbiConfig.ServerPort: Integer;
begin
  Result := ReadIniInteger('Server', 'Port', 9000);
end;

class function TOrbiConfig.DBHost: string;
begin
  Result := ReadIniString('Database', 'Host', '26.236.165.177');
end;

class function TOrbiConfig.DBName: string;
begin
  Result := ReadIniString('Database', 'Name', 'orbi');
end;

class function TOrbiConfig.DBUser: string;
begin
  Result := ReadIniString('Database', 'User', 'postgres');
end;

class function TOrbiConfig.DBPassword: string;
begin
  Result := ReadIniString('Database', 'Password', 'postgres');
end;

class function TOrbiConfig.APIHash: string;
begin
  Result := LowerCase(ReadIniString('Security', 'ApiHash', 'ccc5915dd321d8446aecf4dce952adc827ba7833307c0d004dba55c83e0e191f'));
end;

end.
