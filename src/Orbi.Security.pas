unit Orbi.Security;

interface

uses
  Horse;

procedure OrbiHashAuthMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);

implementation

uses
  System.SysUtils,
  Orbi.Config;

function Normalize(const AValue: string): string;
begin
  Result := Trim(LowerCase(AValue));
end;

procedure OrbiHashAuthMiddleware(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LClientHash: string;
  LExpectedHash: string;
begin
  if SameText(Req.PathInfo, '/download/orbiupdate') then
  begin
    Next;
    Exit;
  end;

  LClientHash := Normalize(Req.Headers['X-API-HASH']);
  LExpectedHash := Normalize(TOrbiConfig.APIHash);

  if (LClientHash = '') or (LClientHash <> LExpectedHash) then
  begin
    Res.Status(401).Send('{"error":"Unauthorized"}');
    Exit;
  end;

  Next;
end;

end.
