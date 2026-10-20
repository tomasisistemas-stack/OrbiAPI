unit Orbi.Routes;

interface

procedure RegisterRoutes;

implementation

uses
  Horse,
  System.SysUtils,
  System.Classes,
  System.DateUtils,
  System.JSON,
  Data.DB,
  FireDAC.Comp.Client,
  Orbi.Database;

const
  CProdutosSQL =
    'select p.cod_produto, p.nom_produto, p.codigo_barra, case when p.qtd_estoque < 0 then 0 else p.qtd_estoque end as qtd_estoque, p.custo, ' +
    'p.preco_venda, p.desconto_maximo ' +
    'from produto p ' +
    'where p.status <> ''S''';
  CProdutosIdSQL =
    'select p.cod_produto, p.nom_produto, p.codigo_barra, case when p.qtd_estoque < 0 then 0 else p.qtd_estoque end as qtd_estoque, p.custo, ' +
    'p.preco_venda, p.desconto_maximo ' +
    'from produto p ' +
    'where p.status <> ''S'' and p.cod_produto = :cod_produto';
  CVendasDetalhadasBaseSQL =
    'select ' +
    '  v1.numdoc, ' +
    '  coalesce(v1.numdoc_destino, v1.numdoc) as numdoc_destino, ' +
    '  v1.dtadoc, ' +
    '  v1.dta_emissao, ' +
    '  v1.dta_emissao as data_filtro, ' +
    '  c.cod_cliente, ' +
    '  c.nom_cliente, ' +
    '  r.id as codrep, ' +
    '  r.nom_representante, ' +
    '  coalesce(v1.perc_comissao, 0) as perc_comissao, ' +
    '  coalesce(v1.vlr_comissao, 0) as vlr_comissao, ' +
    '  coalesce(v1.tot_bruto, 0) as tot_bruto, ' +
    '  coalesce(v1.tot_liquido, 0) as tot_liquido, ' +
    '  coalesce(v1.desconto, 0) as desconto, ' +
    '  v1.faturado, ' +
    '  pr.cod_produto, '+
    '  pr.nom_produto, '+
    '  v2.qtd as item_qtd, '+
    '  v2.desconto as item_desconto, '+
    '  v2.preco_bruto as item_preco_bruto, '+
    '  v2.sub_total_bruto as item_sub_total_bruto, '+
    '  v2.desconto_valor as item_desconto_valor, '+
    '  v2.preco as item_preco, '+
    '  v2.sub_total as item_sub_total '+
    'from vendas1 v1 ' +
    'inner join vendas2 v2 on v1.numdoc = v2.numdoc '+
    'inner join produto pr on pr.cod_produto = v2.cod_produto '+
    'left join cliente c on c.cod_cliente = v1.cod_cliente ' +
    'left join cidades cd on cd.cod_cidade = c.cod_cidade ' +
    'inner join representante r on r.id = v1.cod_representante ' +
    'where ' +
    '  (v1.cod_fiscal not in (''6152'', ''6409'') or v1.cod_fiscal is null) ' +
    '  and v1.nfeentradasaida = ''0'' ' +
    '  and ( ' +
    '     v1.numdoc not in ( ' +
    '      select numdoc_ref_ent ' +
    '      from vendas1 ' +
    '      where numdoc_ref_ent is not null ' +
    '        and faturado <> 2 ' +
    '        and nfeentradasaida = ''1'' ' +
    '    ) ' +
    '  ) ' +
    '  and (v1.nfe_dev is null or v1.status_nfe_dev = 135) ' +
    '  and coalesce(v1.consignacao, 0) <> 1 ' +
    '  and coalesce(v1.cod_fop, 0) not in (7, 9, 22, 23, 24, 26, 32, 46, 47, 51, 52, 53, 54, 57, 58) ' +
    '  and v1.orcamento = ''0'' ';
  CClientesBaseSQL =
    'select ' +
    '  cl.cod_cliente, ' +
    '  cl.dta_cad, ' +
    '  cl.pri_compra, ' +
    '  uv.data_ultima_venda, ' +
    '  cl.nom_cliente, ' +
    '  cl.nom_fantasia, ' +
    '  cl.endereco, ' +
    '  cl.complemento, ' +
    '  cl.proximo, ' +
    '  cl.bairro, ' +
    '  cl.cep, ' +
    '  cl.cod_cidade, ' +
    '  cd.nom_cidade, ' +
    '  cd.uf, ' +
    '  cl.tip_pessoa, ' +
    '  cl.telefone, ' +
    '  cl.email, ' +
    '  cl.aviso, ' +
    '  cl.cnpj, ' +
    '  cl.ie, ' +
    '  cl.im, ' +
    '  cl.prod_rural, ' +
    '  cl.contato, ' +
    '  cl.fone_contato, ' +
    '  cl.limite, ' +
    '  cl.cpf, ' +
    '  cl.rg, ' +
    '  cl.naturalidade, ' +
    '  cl.est_civil, ' +
    '  cl.pai, ' +
    '  cl.mae, ' +
    '  cl.tip_residencia, ' +
    '  cl.aluguel, ' +
    '  cl.empresa, ' +
    '  cl.end_tracli, ' +
    '  cl.bairro_trabalho, ' +
    '  cl.cid_trabalho, ' +
    '  cl.fone_trabalho, ' +
    '  cl.cargo, ' +
    '  cl.nom_conjugue, ' +
    '  cl.emp_conj, ' +
    '  cl.end_emp_conj, ' +
    '  cl.cid_emp_conj, ' +
    '  cl.fone_emp_conj, ' +
    '  cl.cargo_conj, ' +
    '  cl.nom_ref1, ' +
    '  cl.fone_ref1, ' +
    '  cl.obs_ref1, ' +
    '  cl.nom_ref2, ' +
    '  cl.fone_ref2, ' +
    '  cl.obs_ref2, ' +
    '  cl.cad_spc, ' +
    '  cl.dta_cad_spc, ' +
    '  cl.dta_aniversario, ' +
    '  cl.observacoes, ' +
    '  cl.fax, ' +
    '  cl.contato_fone, ' +
    '  cl.contato_email, ' +
    '  cl.id_representante, ' +
    '  re.nom_representante, ' +
    '  cl.cod_empresa, ' +
    '  cl.nr_endereco, ' +
    '  cl.whastapp, ' +
    '  cl.latitude, ' +
    '  cl.longitude ' +
    'from cliente cl ' +
    'inner join cidades cd on cl.cod_cidade = cd.cod_cidade ' +
    'left outer join representante re on re.id = cl.id_representante ' +
    'left join ( ' +
    '  select cod_cliente, max(dta_emissao) as data_ultima_venda ' +
    '  from vendas1 ' +
    '  where nfeentradasaida = ''0'' ' +
    '    and orcamento = ''0'' ' +
    '    and faturado = ''1'' ' +
    '  group by cod_cliente ' +
    ') uv on uv.cod_cliente = cl.cod_cliente ' +
    'where cl.cliente_bloqueado = ''N'' ' +
    '  and cl.nom_cliente not like ''%DESATIVADO%'''+
    '  and cl.nom_cliente not like ''%CANCELADO%''';
  CRepresentantesSQL =
    'select ' +
    '  id, ' +
    '  nom_representante, ' +
    '  funcionario, ' +
    '  ativo ' +
    'from public.representante r ' +
    'where r.funcionario in (''0'', ''1'', ''4'') ' +
    '  and r.ativo = ''S'' ' +
    'order by r.nom_representante';
  CFormasPagamentoSQL =
    'select ' +
    '  cod_fop, ' +
    '  nom_fop ' +
    'from public.fop ' +
    'where ativo = ''S'' ' +
    '  and inativo_palm = ''N'' ' +
    'order by nom_fop';
  CPrazosSQL =
    'select ' +
    '  id, ' +
    '  prazo ' +
    'from prazo p ' +
    'where p.ativo = ''S'' ' +
    '  and p.inativo_palm = ''N'' ' +
    'order by p.prazo';
  CCidadesBaseSQL =
    'select ' +
    '  cod_cidade, ' +
    '  cod_ibge, ' +
    '  nom_cidade, ' +
    '  uf, ' +
    '  cod_representante, ' +
    '  mesocod, ' +
    '  microcod, ' +
    '  populacao, ' +
    '  cod_supervisor ' +
    'from public.cidades ' +
    'where 1 = 1';

function TryParseISODate(const AValue: string; out ADate: TDateTime): Boolean;
var
  LYear: Integer;
  LMonth: Integer;
  LDay: Integer;
begin
  Result := False;

  if Length(AValue) <> 10 then
    Exit;
  if (AValue[5] <> '-') or (AValue[8] <> '-') then
    Exit;
  if not TryStrToInt(Copy(AValue, 1, 4), LYear) then
    Exit;
  if not TryStrToInt(Copy(AValue, 6, 2), LMonth) then
    Exit;
  if not TryStrToInt(Copy(AValue, 9, 2), LDay) then
    Exit;

  Result := TryEncodeDate(LYear, LMonth, LDay, ADate);
end;

function FieldDateToISO(AField: TField): string;
var
  LDate: TDateTime;
  LText: string;
  LFS: TFormatSettings;
begin
  Result := '';

  if AField.IsNull then
    Exit;

  LText := Trim(AField.AsString);
  if (LText = '') or (LText = '/') or (LText = '//') then
    Exit;

  try
    LDate := AField.AsDateTime;
    Result := FormatDateTime('yyyy-mm-dd', LDate);
    Exit;
  except
  end;

  if TryParseISODate(Copy(LText, 1, 10), LDate) then
  begin
    Result := FormatDateTime('yyyy-mm-dd', LDate);
    Exit;
  end;

  LFS := TFormatSettings.Create;
  LFS.DateSeparator := '/';
  LFS.ShortDateFormat := 'dd/mm/yyyy';

  if TryStrToDate(Copy(LText, 1, 10), LDate, LFS) then
    Result := FormatDateTime('yyyy-mm-dd', LDate);
end;

function QueryValue(Req: THorseRequest; const AName: string): string;
begin
  if not Req.Query.TryGetValue(AName, Result) then
    Result := '';
end;

function JSONStringValue(AObject: TJSONObject; const AName: string): string;
var
  LValue: TJSONValue;
begin
  Result := '';
  LValue := AObject.GetValue(AName);
  if Assigned(LValue) and not (LValue is TJSONNull) then
    Result := LValue.Value;
end;

function JoinStrings(AStrings: TStrings; const ASeparator: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to AStrings.Count - 1 do
  begin
    if Result <> '' then
      Result := Result + ASeparator;
    Result := Result + AStrings[I];
  end;
end;

procedure SetJSONObjectString(AObject: TJSONObject; const AName, AValue: string);
var
  LPair: TJSONPair;
begin
  LPair := AObject.RemovePair(AName);
  LPair.Free;
  AObject.AddPair(AName, AValue);
end;

procedure SetJSONObjectInteger(AObject: TJSONObject; const AName: string; AValue: Integer);
var
  LPair: TJSONPair;
begin
  LPair := AObject.RemovePair(AName);
  LPair.Free;
  AObject.AddPair(AName, TJSONNumber.Create(AValue));
end;

procedure SetJSONObjectFloat(AObject: TJSONObject; const AName: string; AValue: Double);
var
  LPair: TJSONPair;
begin
  LPair := AObject.RemovePair(AName);
  LPair.Free;
  AObject.AddPair(AName, TJSONNumber.Create(AValue));
end;

function JSONObjectFloatValue(AObject: TJSONObject; const AName: string; ADefault: Double): Double;
var
  LValue: TJSONValue;
  LText: string;
  LFS: TFormatSettings;
begin
  Result := ADefault;
  LValue := AObject.GetValue(AName);
  if not Assigned(LValue) or (LValue is TJSONNull) then
    Exit;

  if LValue is TJSONNumber then
  begin
    Result := TJSONNumber(LValue).AsDouble;
    Exit;
  end;

  LText := StringReplace(Trim(LValue.Value), ',', '.', [rfReplaceAll]);
  LFS := TFormatSettings.Create;
  LFS.DecimalSeparator := '.';
  TryStrToFloat(LText, Result, LFS);
end;

function IsIntegerParam(const AName: string): Boolean;
begin
  Result :=
    SameText(AName, 'orcamento') or
    SameText(AName, 'faturado') or
    SameText(AName, 'numdoc') or
    SameText(AName, 'cod_cliente') or
    SameText(AName, 'cod_representante') or
    SameText(AName, 'cod_produto') or
    SameText(AName, 'cod_cidade') or
    SameText(AName, 'id_representante') or
    SameText(AName, 'cod_empresa') or
    SameText(AName, 'cod_fop') or
    SameText(AName, 'cod_prazo_pgto');
end;

function IsFloatParam(const AName: string): Boolean;
begin
  Result :=
    SameText(AName, 'preco_venda') or
    SameText(AName, 'preco') or
    SameText(AName, 'preco_bruto') or
    SameText(AName, 'qtd') or
    SameText(AName, 'sub_total') or
    SameText(AName, 'sub_total_bruto') or
    SameText(AName, 'desconto') or
    SameText(AName, 'desconto_valor') or
    SameText(AName, 'tot_bruto') or
    SameText(AName, 'tot_liquido');
end;

function IsSimpleJSONValue(AValue: TJSONValue): Boolean;
begin
  Result := (AValue = nil) or
    (AValue is TJSONNull) or
    (AValue is TJSONString) or
    (AValue is TJSONNumber) or
    (AValue is TJSONBool);
end;

procedure SetJSONParam(AQuery: TFDQuery; const AName: string; AValue: TJSONValue);
var
  LDate: TDateTime;
  LText: string;
begin
  if (AValue = nil) or (AValue is TJSONNull) then
  begin
    AQuery.ParamByName(AName).Clear;
    Exit;
  end;

  LText := Trim(AValue.Value);

  if IsIntegerParam(AName) then
  begin
    if LText = '' then
      AQuery.ParamByName(AName).Clear
    else
      AQuery.ParamByName(AName).AsInteger := StrToIntDef(LText, 0);
  end
  else if IsFloatParam(AName) then
  begin
    if LText = '' then
      AQuery.ParamByName(AName).Clear
    else if AValue is TJSONNumber then
      AQuery.ParamByName(AName).AsFloat := TJSONNumber(AValue).AsDouble
    else
      AQuery.ParamByName(AName).AsFloat := StrToFloatDef(StringReplace(LText, ',', '.', [rfReplaceAll]), 0);
  end
  else if SameText(AName, 'dta_cad') or
     SameText(AName, 'pri_compra') or
     SameText(AName, 'dta_cad_spc') or
     SameText(AName, 'dta_aniversario') or
     SameText(AName, 'dta_emissao') or
     SameText(AName, 'dtadoc') then
  begin
    if LText = '' then
      AQuery.ParamByName(AName).Clear
    else if TryParseISODate(Copy(LText, 1, 10), LDate) then
      AQuery.ParamByName(AName).AsDate := LDate
    else
      AQuery.ParamByName(AName).AsString := LText;
  end
  else if AValue is TJSONNumber then
    AQuery.ParamByName(AName).AsFloat := TJSONNumber(AValue).AsDouble
  else
    AQuery.ParamByName(AName).AsString := LText;
end;

procedure ExecuteInsertFromJSON(AConn: TFDConnection; const ATableName: string; AObject: TJSONObject);
var
  LQuery: TFDQuery;
  LColumns: TStringList;
  LParams: TStringList;
  I: Integer;
  LPair: TJSONPair;
  LColumn: string;
begin
  LColumns := TStringList.Create;
  LParams := TStringList.Create;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConn;

    for I := 0 to AObject.Count - 1 do
    begin
      LPair := AObject.Pairs[I];
      if not IsSimpleJSONValue(LPair.JsonValue) then
        Continue;

      LColumn := LPair.JsonString.Value;
      LColumns.Add(LColumn);
      LParams.Add(':' + LColumn);
    end;

    if LColumns.Count = 0 then
      raise Exception.Create('JSON sem campos para inserir em ' + ATableName);

    LQuery.SQL.Text := 'insert into ' + ATableName + ' (' +
      JoinStrings(LColumns, ', ') +
      ') values (' +
      JoinStrings(LParams, ', ') +
      ')';

    for I := 0 to AObject.Count - 1 do
    begin
      LPair := AObject.Pairs[I];
      if not IsSimpleJSONValue(LPair.JsonValue) then
        Continue;

      SetJSONParam(LQuery, LPair.JsonString.Value, LPair.JsonValue);
    end;

    LQuery.ExecSQL;
  finally
    LQuery.Free;
    LParams.Free;
    LColumns.Free;
  end;
end;

function ExecuteInsertFromJSONReturning(AConn: TFDConnection; const ATableName: string; AObject: TJSONObject;
  const AReturningColumn: string): string;
var
  LQuery: TFDQuery;
  LColumns: TStringList;
  LParams: TStringList;
  I: Integer;
  LPair: TJSONPair;
  LColumn: string;
begin
  Result := '';
  LColumns := TStringList.Create;
  LParams := TStringList.Create;
  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConn;

    for I := 0 to AObject.Count - 1 do
    begin
      LPair := AObject.Pairs[I];
      if not IsSimpleJSONValue(LPair.JsonValue) then
        Continue;

      LColumn := LPair.JsonString.Value;
      LColumns.Add(LColumn);
      LParams.Add(':' + LColumn);
    end;

    if LColumns.Count = 0 then
      raise Exception.Create('JSON sem campos para inserir em ' + ATableName);

    LQuery.SQL.Text := 'insert into ' + ATableName + ' (' +
      JoinStrings(LColumns, ', ') +
      ') values (' +
      JoinStrings(LParams, ', ') +
      ') returning ' + AReturningColumn;

    for I := 0 to AObject.Count - 1 do
    begin
      LPair := AObject.Pairs[I];
      if not IsSimpleJSONValue(LPair.JsonValue) then
        Continue;

      SetJSONParam(LQuery, LPair.JsonString.Value, LPair.JsonValue);
    end;

    LQuery.Open;
    if not LQuery.Eof then
      Result := LQuery.FieldByName(AReturningColumn).AsString;
  finally
    LQuery.Free;
    LParams.Free;
    LColumns.Free;
  end;
end;

procedure ApplyProdutoDataToVendas2Item(AConn: TFDConnection; AItem: TJSONObject);
var
  LQuery: TFDQuery;
  LCodProdutoValue: TJSONValue;
  LPair: TJSONPair;
  LCodProduto: Integer;
  LQtd: Double;
  LDesconto: Double;
  LPrecoVenda: Double;
  LPreco: Double;
  LSubTotalBruto: Double;
  LDescontoValor: Double;
  LSubTotal: Double;
begin
  LCodProdutoValue := AItem.GetValue('cod_produto');
  if not Assigned(LCodProdutoValue) then
    raise Exception.Create('cod_produto obrigatorio no item de vendas2');

  LCodProduto := StrToIntDef(Trim(LCodProdutoValue.Value), 0);
  if LCodProduto <= 0 then
    raise Exception.Create('cod_produto invalido no item de vendas2');

  LQuery := TFDQuery.Create(nil);
  try
    LQuery.Connection := AConn;
    LQuery.SQL.Text :=
      'select preco_venda, ncm ' +
      'from produto ' +
      'where cod_produto = :cod_produto';
    LQuery.ParamByName('cod_produto').AsInteger := LCodProduto;
    LQuery.Open;

    if LQuery.Eof then
      raise Exception.Create('produto nao encontrado: ' + LCodProduto.ToString);

    LQtd := JSONObjectFloatValue(AItem, 'qtd', 0);
    if LQtd <= 0 then
      raise Exception.Create('qtd deve ser maior que zero no produto ' + LCodProduto.ToString);

    LDesconto := JSONObjectFloatValue(AItem, 'desconto', 0);
    if (LDesconto < 0) or (LDesconto > 100) then
      raise Exception.Create('desconto deve estar entre 0 e 100 no produto ' + LCodProduto.ToString);

    LPrecoVenda := LQuery.FieldByName('preco_venda').AsFloat;
    LPreco := LPrecoVenda * (1 - (LDesconto / 100));
    LSubTotalBruto := LPrecoVenda * LQtd;
    LDescontoValor := (LPrecoVenda - LPreco) * LQtd;
    LSubTotal := LPreco * LQtd;

    LPair := AItem.RemovePair('preco_venda');
    LPair.Free;
    SetJSONObjectFloat(AItem, 'qtd', LQtd);
    SetJSONObjectFloat(AItem, 'desconto', LDesconto);
    SetJSONObjectFloat(AItem, 'preco_bruto', LPrecoVenda);
    SetJSONObjectFloat(AItem, 'preco', LPreco);
    SetJSONObjectFloat(AItem, 'sub_total_bruto', LSubTotalBruto);
    SetJSONObjectFloat(AItem, 'desconto_valor', LDescontoValor);
    SetJSONObjectFloat(AItem, 'sub_total', LSubTotal);
    SetJSONObjectString(AItem, 'ncm', LQuery.FieldByName('ncm').AsString);
  finally
    LQuery.Free;
  end;
end;

procedure AddJSONNumber(AObject: TJSONObject; const AName: string; AField: TField);
begin
  if AField.IsNull then
    AObject.AddPair(AName, TJSONNull.Create)
  else
    AObject.AddPair(AName, TJSONNumber.Create(AField.AsFloat));
end;

procedure AddJSONString(AObject: TJSONObject; const AName: string; AField: TField);
begin
  if AField.IsNull then
    AObject.AddPair(AName, '')
  else
    AObject.AddPair(AName, AField.AsString);
end;

procedure AddJSONDate(AObject: TJSONObject; const AName: string; AField: TField);
begin
  if AField.IsNull then
    AObject.AddPair(AName, '')
  else
    AObject.AddPair(AName, FieldDateToISO(AField));
end;

function QueryToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LItem: TJSONObject;
  LQtdEstoque: Double;
  LText: string;
  LFS: TFormatSettings;
begin
  Result := TJSONArray.Create;
  LFS := TFormatSettings.Create;
  LFS.DecimalSeparator := '.';

  AQuery.First;
  while not AQuery.Eof do
  begin
    LText := Trim(AQuery.FieldByName('qtd_estoque').AsString);
    LText := StringReplace(LText, ',', '.', [rfReplaceAll]);
    if not TryStrToFloat(LText, LQtdEstoque, LFS) then
      LQtdEstoque := 0;
    if LQtdEstoque < 0 then
      LQtdEstoque := 0;

    LItem := TJSONObject.Create;
    LItem.AddPair('cod_produto', TJSONNumber.Create(AQuery.FieldByName('cod_produto').AsInteger));
    LItem.AddPair('nom_produto', AQuery.FieldByName('nom_produto').AsString);
    LItem.AddPair('codigo_barra', AQuery.FieldByName('codigo_barra').AsString);
    LItem.AddPair('qtd_estoque', TJSONNumber.Create(LQtdEstoque));
    LItem.AddPair('custo', TJSONNumber.Create(AQuery.FieldByName('custo').AsFloat));
    LItem.AddPair('preco_venda', TJSONNumber.Create(AQuery.FieldByName('preco_venda').AsFloat));
    LItem.AddPair('desconto_maximo', TJSONNumber.Create(AQuery.FieldByName('desconto_maximo').AsFloat));
    Result.AddElement(LItem);
    AQuery.Next;
  end;
end;

function VendasDetalhadasToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LVenda: TJSONObject;
  LItem: TJSONObject;
  LItens: TJSONArray;
  LNumDoc: string;
  LCurrentNumDoc: string;
begin
  Result := TJSONArray.Create;
  LVenda := nil;
  LItens := nil;
  LCurrentNumDoc := '';

  AQuery.First;
  while not AQuery.Eof do
  begin
    LNumDoc := AQuery.FieldByName('numdoc').AsString;

    if (LVenda = nil) or (LNumDoc <> LCurrentNumDoc) then
    begin
      LCurrentNumDoc := LNumDoc;

      LVenda := TJSONObject.Create;
      LVenda.AddPair('numdoc', AQuery.FieldByName('numdoc').AsString);
      LVenda.AddPair('numdoc_destino', AQuery.FieldByName('numdoc_destino').AsString);
      LVenda.AddPair('dtadoc', FieldDateToISO(AQuery.FieldByName('dtadoc')));
      LVenda.AddPair('dta_emissao', FieldDateToISO(AQuery.FieldByName('dta_emissao')));
      LVenda.AddPair('data_filtro', FieldDateToISO(AQuery.FieldByName('data_filtro')));
      LVenda.AddPair('cod_cliente', TJSONNumber.Create(AQuery.FieldByName('cod_cliente').AsInteger));
      LVenda.AddPair('nom_cliente', AQuery.FieldByName('nom_cliente').AsString);
      LVenda.AddPair('codrep', TJSONNumber.Create(AQuery.FieldByName('codrep').AsInteger));
      LVenda.AddPair('nom_representante', AQuery.FieldByName('nom_representante').AsString);
      LVenda.AddPair('perc_comissao', TJSONNumber.Create(AQuery.FieldByName('perc_comissao').AsFloat));
      LVenda.AddPair('vlr_comissao', TJSONNumber.Create(AQuery.FieldByName('vlr_comissao').AsFloat));
      LVenda.AddPair('tot_bruto', TJSONNumber.Create(AQuery.FieldByName('tot_bruto').AsFloat));
      LVenda.AddPair('tot_liquido', TJSONNumber.Create(AQuery.FieldByName('tot_liquido').AsFloat));
      LVenda.AddPair('desconto', TJSONNumber.Create(AQuery.FieldByName('desconto').AsFloat));
      LVenda.AddPair('faturado', AQuery.FieldByName('faturado').AsString);

      LItens := TJSONArray.Create;
      LVenda.AddPair('itens', LItens);
      Result.AddElement(LVenda);
    end;

    LItem := TJSONObject.Create;
    LItem.AddPair('cod_produto', TJSONNumber.Create(AQuery.FieldByName('cod_produto').AsInteger));
    LItem.AddPair('nom_produto', AQuery.FieldByName('nom_produto').AsString);
    LItem.AddPair('qtd', TJSONNumber.Create(AQuery.FieldByName('item_qtd').AsFloat));
    LItem.AddPair('desconto', TJSONNumber.Create(AQuery.FieldByName('item_desconto').AsFloat));
    LItem.AddPair('preco_bruto', TJSONNumber.Create(AQuery.FieldByName('item_preco_bruto').AsFloat));
    LItem.AddPair('sub_total_bruto', TJSONNumber.Create(AQuery.FieldByName('item_sub_total_bruto').AsFloat));
    LItem.AddPair('desconto_valor', TJSONNumber.Create(AQuery.FieldByName('item_desconto_valor').AsFloat));
    LItem.AddPair('preco', TJSONNumber.Create(AQuery.FieldByName('item_preco').AsFloat));
    LItem.AddPair('sub_total', TJSONNumber.Create(AQuery.FieldByName('item_sub_total').AsFloat));
    LItens.AddElement(LItem);

    AQuery.Next;
  end;
end;

function ClientesToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;

  AQuery.First;
  while not AQuery.Eof do
  begin
    LItem := TJSONObject.Create;
    AddJSONNumber(LItem, 'cod_cliente', AQuery.FieldByName('cod_cliente'));
    AddJSONDate(LItem, 'dta_cad', AQuery.FieldByName('dta_cad'));
    AddJSONDate(LItem, 'pri_compra', AQuery.FieldByName('pri_compra'));
    AddJSONDate(LItem, 'data_ultima_venda', AQuery.FieldByName('data_ultima_venda'));
    AddJSONString(LItem, 'nom_cliente', AQuery.FieldByName('nom_cliente'));
    AddJSONString(LItem, 'nom_fantasia', AQuery.FieldByName('nom_fantasia'));
    AddJSONString(LItem, 'endereco', AQuery.FieldByName('endereco'));
    AddJSONString(LItem, 'complemento', AQuery.FieldByName('complemento'));
    AddJSONString(LItem, 'proximo', AQuery.FieldByName('proximo'));
    AddJSONString(LItem, 'bairro', AQuery.FieldByName('bairro'));
    AddJSONString(LItem, 'cep', AQuery.FieldByName('cep'));
    AddJSONNumber(LItem, 'cod_cidade', AQuery.FieldByName('cod_cidade'));
    AddJSONString(LItem, 'nom_cidade', AQuery.FieldByName('nom_cidade'));
    AddJSONString(LItem, 'uf', AQuery.FieldByName('uf'));
    AddJSONString(LItem, 'tip_pessoa', AQuery.FieldByName('tip_pessoa'));
    AddJSONString(LItem, 'telefone', AQuery.FieldByName('telefone'));
    AddJSONString(LItem, 'email', AQuery.FieldByName('email'));
    AddJSONString(LItem, 'aviso', AQuery.FieldByName('aviso'));
    AddJSONString(LItem, 'cnpj', AQuery.FieldByName('cnpj'));
    AddJSONString(LItem, 'ie', AQuery.FieldByName('ie'));
    AddJSONString(LItem, 'im', AQuery.FieldByName('im'));
    AddJSONString(LItem, 'prod_rural', AQuery.FieldByName('prod_rural'));
    AddJSONString(LItem, 'contato', AQuery.FieldByName('contato'));
    AddJSONString(LItem, 'fone_contato', AQuery.FieldByName('fone_contato'));
    AddJSONNumber(LItem, 'limite', AQuery.FieldByName('limite'));
    AddJSONString(LItem, 'cpf', AQuery.FieldByName('cpf'));
    AddJSONString(LItem, 'rg', AQuery.FieldByName('rg'));
    AddJSONString(LItem, 'naturalidade', AQuery.FieldByName('naturalidade'));
    AddJSONString(LItem, 'est_civil', AQuery.FieldByName('est_civil'));
    AddJSONString(LItem, 'pai', AQuery.FieldByName('pai'));
    AddJSONString(LItem, 'mae', AQuery.FieldByName('mae'));
    AddJSONString(LItem, 'tip_residencia', AQuery.FieldByName('tip_residencia'));
    AddJSONNumber(LItem, 'aluguel', AQuery.FieldByName('aluguel'));
    AddJSONString(LItem, 'empresa', AQuery.FieldByName('empresa'));
    AddJSONString(LItem, 'end_tracli', AQuery.FieldByName('end_tracli'));
    AddJSONString(LItem, 'bairro_trabalho', AQuery.FieldByName('bairro_trabalho'));
    AddJSONString(LItem, 'cid_trabalho', AQuery.FieldByName('cid_trabalho'));
    AddJSONString(LItem, 'fone_trabalho', AQuery.FieldByName('fone_trabalho'));
    AddJSONString(LItem, 'cargo', AQuery.FieldByName('cargo'));
    AddJSONString(LItem, 'nom_conjugue', AQuery.FieldByName('nom_conjugue'));
    AddJSONString(LItem, 'emp_conj', AQuery.FieldByName('emp_conj'));
    AddJSONString(LItem, 'end_emp_conj', AQuery.FieldByName('end_emp_conj'));
    AddJSONString(LItem, 'cid_emp_conj', AQuery.FieldByName('cid_emp_conj'));
    AddJSONString(LItem, 'fone_emp_conj', AQuery.FieldByName('fone_emp_conj'));
    AddJSONString(LItem, 'cargo_conj', AQuery.FieldByName('cargo_conj'));
    AddJSONString(LItem, 'nom_ref1', AQuery.FieldByName('nom_ref1'));
    AddJSONString(LItem, 'fone_ref1', AQuery.FieldByName('fone_ref1'));
    AddJSONString(LItem, 'obs_ref1', AQuery.FieldByName('obs_ref1'));
    AddJSONString(LItem, 'nom_ref2', AQuery.FieldByName('nom_ref2'));
    AddJSONString(LItem, 'fone_ref2', AQuery.FieldByName('fone_ref2'));
    AddJSONString(LItem, 'obs_ref2', AQuery.FieldByName('obs_ref2'));
    AddJSONString(LItem, 'cad_spc', AQuery.FieldByName('cad_spc'));
    AddJSONDate(LItem, 'dta_cad_spc', AQuery.FieldByName('dta_cad_spc'));
    AddJSONDate(LItem, 'dta_aniversario', AQuery.FieldByName('dta_aniversario'));
    AddJSONString(LItem, 'observacoes', AQuery.FieldByName('observacoes'));
    AddJSONString(LItem, 'fax', AQuery.FieldByName('fax'));
    AddJSONString(LItem, 'contato_fone', AQuery.FieldByName('contato_fone'));
    AddJSONString(LItem, 'contato_email', AQuery.FieldByName('contato_email'));
    AddJSONNumber(LItem, 'id_representante', AQuery.FieldByName('id_representante'));
    AddJSONString(LItem, 'nom_representante', AQuery.FieldByName('nom_representante'));
    AddJSONNumber(LItem, 'cod_empresa', AQuery.FieldByName('cod_empresa'));
    AddJSONString(LItem, 'nr_endereco', AQuery.FieldByName('nr_endereco'));
    AddJSONString(LItem, 'whastapp', AQuery.FieldByName('whastapp'));
    AddJSONNumber(LItem, 'latitude', AQuery.FieldByName('latitude'));
    AddJSONNumber(LItem, 'longitude', AQuery.FieldByName('longitude'));
    Result.AddElement(LItem);
    AQuery.Next;
  end;
end;

function RepresentantesToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;

  AQuery.First;
  while not AQuery.Eof do
  begin
    LItem := TJSONObject.Create;
    AddJSONNumber(LItem, 'id', AQuery.FieldByName('id'));
    AddJSONString(LItem, 'nom_representante', AQuery.FieldByName('nom_representante'));
    AddJSONString(LItem, 'funcionario', AQuery.FieldByName('funcionario'));
    AddJSONString(LItem, 'ativo', AQuery.FieldByName('ativo'));
    Result.AddElement(LItem);
    AQuery.Next;
  end;
end;

function FormasPagamentoToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;

  AQuery.First;
  while not AQuery.Eof do
  begin
    LItem := TJSONObject.Create;
    AddJSONNumber(LItem, 'cod_fop', AQuery.FieldByName('cod_fop'));
    AddJSONString(LItem, 'nom_fop', AQuery.FieldByName('nom_fop'));
    Result.AddElement(LItem);
    AQuery.Next;
  end;
end;

function PrazosToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;

  AQuery.First;
  while not AQuery.Eof do
  begin
    LItem := TJSONObject.Create;
    AddJSONNumber(LItem, 'id', AQuery.FieldByName('id'));
    AddJSONString(LItem, 'prazo', AQuery.FieldByName('prazo'));
    Result.AddElement(LItem);
    AQuery.Next;
  end;
end;

function CidadesToJSONArray(AQuery: TFDQuery): TJSONArray;
var
  LItem: TJSONObject;
begin
  Result := TJSONArray.Create;

  AQuery.First;
  while not AQuery.Eof do
  begin
    LItem := TJSONObject.Create;
    AddJSONNumber(LItem, 'cod_cidade', AQuery.FieldByName('cod_cidade'));
    AddJSONNumber(LItem, 'cod_ibge', AQuery.FieldByName('cod_ibge'));
    AddJSONString(LItem, 'nom_cidade', AQuery.FieldByName('nom_cidade'));
    AddJSONString(LItem, 'uf', AQuery.FieldByName('uf'));
    AddJSONNumber(LItem, 'cod_representante', AQuery.FieldByName('cod_representante'));
    AddJSONString(LItem, 'mesocod', AQuery.FieldByName('mesocod'));
    AddJSONString(LItem, 'microcod', AQuery.FieldByName('microcod'));
    AddJSONNumber(LItem, 'populacao', AQuery.FieldByName('populacao'));
    AddJSONNumber(LItem, 'cod_supervisor', AQuery.FieldByName('cod_supervisor'));
    Result.AddElement(LItem);
    AQuery.Next;
  end;
end;

function GetMetaRepresentanteJSON(ACodRepresentante: Integer; const AMes: string): TJSONObject;
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LInfoQuery: TFDQuery;
  LRepField: string;
  LMesDataType: string;
  LMesNum: Integer;
  LAnoNum: Integer;
  LInicio: TDateTime;
  LFim: TDateTime;
  LSQL: string;

  function ColumnExists(const AColumnName: string): Boolean;
  begin
    LInfoQuery.Close;
    LInfoQuery.SQL.Text :=
      'select 1 from information_schema.columns ' +
      'where table_schema = ''public'' and table_name = ''metas_representante'' and column_name = :p0';
    LInfoQuery.ParamByName('p0').AsString := AColumnName;
    LInfoQuery.Open;
    Result := not LInfoQuery.Eof;
  end;

begin
  if (Length(Trim(AMes)) <> 7) or (AMes[3] <> '/') then
    raise Exception.Create('Mes invalido. Use MM/AAAA.');

  LMesNum := StrToIntDef(Copy(AMes, 1, 2), 0);
  LAnoNum := StrToIntDef(Copy(AMes, 4, 4), 0);
  if (LMesNum < 1) or (LMesNum > 12) or (LAnoNum <= 0) then
    raise Exception.Create('Mes invalido. Use MM/AAAA.');

  LInicio := EncodeDate(LAnoNum, LMesNum, 1);
  LFim := IncMonth(LInicio, 1);
  LRepField := 'cod_representante';
  LMesDataType := '';

  LConn := NewConnection;
  LInfoQuery := TFDQuery.Create(nil);
  LQuery := TFDQuery.Create(nil);
  try
    LInfoQuery.Connection := LConn;
    LQuery.Connection := LConn;

    if not ColumnExists(LRepField) then
      LRepField := 'id_representante';

    LInfoQuery.Close;
    LInfoQuery.SQL.Text :=
      'select data_type from information_schema.columns ' +
      'where table_schema = ''public'' and table_name = ''metas_representante'' and column_name = ''mes''';
    LInfoQuery.Open;
    if not LInfoQuery.Eof then
      LMesDataType := LowerCase(LInfoQuery.Fields[0].AsString);

    LSQL :=
      'select ' +
      '  id, ' +
      '  mes, ' +
      '  ' + LRepField + ' as id_representante, ' +
      '  vl_meta, ' +
      '  vl_realizado, ' +
      '  perc_realizado, ' +
      '  qtd_clientes_atendidos, ' +
      '  qtd_clientes_base, ' +
      '  perc_positivacao, ' +
      '  ticket_medio, ' +
      '  perc_desconto ' +
      'from metas_representante ' +
      'where ' + LRepField + ' = :p0 ';

    if (Pos('date', LMesDataType) > 0) or (Pos('timestamp', LMesDataType) > 0) then
    begin
      LQuery.SQL.Text := LSQL + ' and mes >= :p1 and mes < :p2';
      LQuery.ParamByName('p0').AsInteger := ACodRepresentante;
      LQuery.ParamByName('p1').AsDate := LInicio;
      LQuery.ParamByName('p2').AsDate := LFim;
    end
    else
    begin
      LQuery.SQL.Text := LSQL + ' and (trim(mes::varchar) = :p1 or trim(mes::varchar) = :p2)';
      LQuery.ParamByName('p0').AsInteger := ACodRepresentante;
      LQuery.ParamByName('p1').AsString := AMes;
      LQuery.ParamByName('p2').AsString := FormatDateTime('yyyymm', LInicio);
    end;

    LQuery.Open;
    if LQuery.Eof then
    begin
      Result := TJSONObject.Create;
      Result.AddPair('found', 'false');
    end
    else
    begin
      Result := TJSONObject.Create;
      AddJSONNumber(Result, 'id', LQuery.FieldByName('id'));
      if (Pos('date', LMesDataType) > 0) or (Pos('timestamp', LMesDataType) > 0) then
        AddJSONDate(Result, 'mes', LQuery.FieldByName('mes'))
      else
        AddJSONString(Result, 'mes', LQuery.FieldByName('mes'));
      AddJSONNumber(Result, 'id_representante', LQuery.FieldByName('id_representante'));
      AddJSONNumber(Result, 'vl_meta', LQuery.FieldByName('vl_meta'));
      AddJSONNumber(Result, 'vl_realizado', LQuery.FieldByName('vl_realizado'));
      AddJSONNumber(Result, 'perc_realizado', LQuery.FieldByName('perc_realizado'));
      AddJSONNumber(Result, 'qtd_clientes_atendidos', LQuery.FieldByName('qtd_clientes_atendidos'));
      AddJSONNumber(Result, 'qtd_clientes_base', LQuery.FieldByName('qtd_clientes_base'));
      AddJSONNumber(Result, 'perc_positivacao', LQuery.FieldByName('perc_positivacao'));
      AddJSONNumber(Result, 'ticket_medio', LQuery.FieldByName('ticket_medio'));
      AddJSONNumber(Result, 'perc_desconto', LQuery.FieldByName('perc_desconto'));
      Result.AddPair('found', 'true');
    end;
  finally
    LQuery.Free;
    LInfoQuery.Free;
    LConn.Free;
  end;
end;

procedure ProdutosHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := CProdutosSQL;
    LQuery.Open;

    LArray := QueryToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure ProdutosIdHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LCodProduto: Integer;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;

  if not TryStrToInt(Req.Params['cod_produto'], LCodProduto) then
  begin
    Res.Status(400).ContentType('application/json').Send('{"error":"cod_produto invalido"}');
    Exit;
  end;

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := CProdutosIdSQL;
    LQuery.ParamByName('cod_produto').AsInteger := LCodProduto;
    LQuery.Open;

    LArray := QueryToJSONArray(LQuery);
    if LArray.Count = 0 then
      Res.Status(404).ContentType('application/json').Send('{"error":"produto nao encontrado"}')
    else
      Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure PostPedidoHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LJSON: TJSONValue;
  LBody: TJSONObject;
  LVendas1: TJSONObject;
  LVendas2: TJSONArray;
  LVendas1Value: TJSONValue;
  LVendas2Value: TJSONValue;
  LItem: TJSONObject;
  LPair: TJSONPair;
  LResult: TJSONObject;
  LNumDoc: string;
  I: Integer;
begin
  LConn := nil;
  LJSON := nil;
  LResult := nil;

  try
    LJSON := TJSONObject.ParseJSONValue(Req.Body);
    if not (LJSON is TJSONObject) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"JSON invalido"}');
      Exit;
    end;

    LBody := TJSONObject(LJSON);
    LVendas1Value := LBody.GetValue('vendas1');
    LVendas2Value := LBody.GetValue('vendas2');

    if not (LVendas1Value is TJSONObject) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"Objeto vendas1 obrigatorio"}');
      Exit;
    end;

    if not (LVendas2Value is TJSONArray) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"Array vendas2 obrigatorio"}');
      Exit;
    end;

    LVendas1 := TJSONObject(LVendas1Value);
    LVendas2 := TJSONArray(LVendas2Value);

    SetJSONObjectString(LVendas1, 'nfeentradasaida', '0');
    SetJSONObjectInteger(LVendas1, 'orcamento', 0);
    SetJSONObjectInteger(LVendas1, 'faturado', 0);
    SetJSONObjectInteger(LVendas1, 'cod_empresa', 1);
    LPair := LVendas1.RemovePair('numdoc');
    LPair.Free;

    LConn := NewConnection;
    LConn.StartTransaction;
    try
      LNumDoc := ExecuteInsertFromJSONReturning(LConn, 'vendas1', LVendas1, 'numdoc');
      if Trim(LNumDoc) = '' then
        raise Exception.Create('Trigger de vendas1 nao retornou numdoc');

      for I := 0 to LVendas2.Count - 1 do
      begin
        if not (LVendas2.Items[I] is TJSONObject) then
          raise Exception.Create('Item de vendas2 invalido na posicao ' + I.ToString);

        LItem := TJSONObject(LVendas2.Items[I]);
        SetJSONObjectInteger(LItem, 'numdoc', StrToIntDef(LNumDoc, 0));
        ApplyProdutoDataToVendas2Item(LConn, LItem);

        ExecuteInsertFromJSON(LConn, 'vendas2', LItem);
      end;

      LConn.Commit;
    except
      if Assigned(LConn) and LConn.InTransaction then
        LConn.Rollback;
      raise;
    end;

    LResult := TJSONObject.Create;
    LResult.AddPair('success', TJSONBool.Create(True));
    LResult.AddPair('numdoc', LNumDoc);
    LResult.AddPair('itens_inseridos', TJSONNumber.Create(LVendas2.Count));
    Res.Status(201).ContentType('application/json').Send(LResult.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LResult.Free;
  LJSON.Free;
  LConn.Free;
end;

procedure SendVendasDetalhadas(Req: THorseRequest; Res: THorseResponse; AFaturado: Integer);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LSQL: string;
  LCodRep: Integer;
  LCodCliente: Integer;
  LDataInicial: TDateTime;
  LDataFinal: TDateTime;
  LFiltro: string;
  LNumDoc: string;
  LDataField: string;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;
  LSQL := CVendasDetalhadasBaseSQL;
  LSQL := LSQL + ' and v1.faturado = :faturado';
  if AFaturado = 0 then
    LDataField := 'v1.dtadoc'
  else
    LDataField := 'v1.dta_emissao';
  LFiltro := Trim(QueryValue(Req, 'filtro'));
  LNumDoc := Trim(QueryValue(Req, 'numdoc'));

  if QueryValue(Req, 'codrep') <> '' then
  begin
    if not TryStrToInt(QueryValue(Req, 'codrep'), LCodRep) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"codrep invalido"}');
      Exit;
    end;
    LSQL := LSQL + ' and v1.cod_representante = :codrep';
  end;

  if QueryValue(Req, 'cod_cliente') <> '' then
  begin
    if not TryStrToInt(QueryValue(Req, 'cod_cliente'), LCodCliente) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"cod_cliente invalido"}');
      Exit;
    end;
    LSQL := LSQL + ' and v1.cod_cliente = :cod_cliente';
  end;

  if QueryValue(Req, 'data_inicial') <> '' then
  begin
    if not TryParseISODate(QueryValue(Req, 'data_inicial'), LDataInicial) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"data_inicial invalida. Use yyyy-mm-dd"}');
      Exit;
    end;
    LSQL := LSQL + ' and ' + LDataField + ' >= :data_inicial';
  end;

  if QueryValue(Req, 'data_final') <> '' then
  begin
    if not TryParseISODate(QueryValue(Req, 'data_final'), LDataFinal) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"data_final invalida. Use yyyy-mm-dd"}');
      Exit;
    end;
    LSQL := LSQL + ' and ' + LDataField + ' <= :data_final';
  end;

  if LNumDoc <> '' then
    LSQL := LSQL + ' and cast(v1.numdoc as varchar) ilike :numdoc';

  if LFiltro <> '' then
    LSQL := LSQL + ' and (cast(v1.numdoc as varchar) ilike :filtro or coalesce(c.nom_cliente, '''') ilike :filtro)';

  LSQL := LSQL + ' order by ' + LDataField + ' desc, v1.numdoc desc';

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := LSQL;

    LQuery.ParamByName('faturado').AsInteger := AFaturado;
    if QueryValue(Req, 'codrep') <> '' then
      LQuery.ParamByName('codrep').AsInteger := LCodRep;
    if QueryValue(Req, 'cod_cliente') <> '' then
      LQuery.ParamByName('cod_cliente').AsInteger := LCodCliente;
    if QueryValue(Req, 'data_inicial') <> '' then
      LQuery.ParamByName('data_inicial').AsDate := LDataInicial;
    if QueryValue(Req, 'data_final') <> '' then
      LQuery.ParamByName('data_final').AsDate := LDataFinal;
    if LNumDoc <> '' then
      LQuery.ParamByName('numdoc').AsString := '%' + LNumDoc + '%';
    if LFiltro <> '' then
      LQuery.ParamByName('filtro').AsString := '%' + LFiltro + '%';

    LQuery.Open;

    LArray := VendasDetalhadasToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure VendasDetalhadasHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  SendVendasDetalhadas(Req, Res, 1);
end;

procedure VendasDetalhadasFaturadasHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  SendVendasDetalhadas(Req, Res, 1);
end;

procedure VendasDetalhadasAbertasHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  SendVendasDetalhadas(Req, Res, 0);
end;

procedure ClientesHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LSQL: string;
  LCodRep: Integer;
  LCodCliente: Integer;
  LDataUltimaVenda: TDateTime;
  LDataUltimaVendaInicial: TDateTime;
  LDataUltimaVendaFinal: TDateTime;
  LNome: string;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;
  LSQL := CClientesBaseSQL;
  LNome := Trim(QueryValue(Req, 'nome'));

  if QueryValue(Req, 'codrep') <> '' then
  begin
    if not TryStrToInt(QueryValue(Req, 'codrep'), LCodRep) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"codrep invalido"}');
      Exit;
    end;
    LSQL := LSQL + ' and cl.id_representante = :codrep';
  end;

  if QueryValue(Req, 'cod_cliente') <> '' then
  begin
    if not TryStrToInt(QueryValue(Req, 'cod_cliente'), LCodCliente) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"cod_cliente invalido"}');
      Exit;
    end;
    LSQL := LSQL + ' and cl.cod_cliente = :cod_cliente';
  end;

  if LNome <> '' then
    LSQL := LSQL + ' and cl.nom_cliente ilike :nome';

  if QueryValue(Req, 'data_ultima_venda') <> '' then
  begin
    if not TryParseISODate(QueryValue(Req, 'data_ultima_venda'), LDataUltimaVenda) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"data_ultima_venda invalida. Use yyyy-mm-dd"}');
      Exit;
    end;
    LSQL := LSQL + ' and cast(uv.data_ultima_venda as date) = :data_ultima_venda';
  end;

  if QueryValue(Req, 'data_ultima_venda_inicial') <> '' then
  begin
    if not TryParseISODate(QueryValue(Req, 'data_ultima_venda_inicial'), LDataUltimaVendaInicial) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"data_ultima_venda_inicial invalida. Use yyyy-mm-dd"}');
      Exit;
    end;
    LSQL := LSQL + ' and cast(uv.data_ultima_venda as date) >= :data_ultima_venda_inicial';
  end;

  if QueryValue(Req, 'data_ultima_venda_final') <> '' then
  begin
    if not TryParseISODate(QueryValue(Req, 'data_ultima_venda_final'), LDataUltimaVendaFinal) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"data_ultima_venda_final invalida. Use yyyy-mm-dd"}');
      Exit;
    end;
    LSQL := LSQL + ' and cast(uv.data_ultima_venda as date) <= :data_ultima_venda_final';
  end;

  LSQL := LSQL + ' order by cl.nom_cliente';

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := LSQL;

    if QueryValue(Req, 'codrep') <> '' then
      LQuery.ParamByName('codrep').AsInteger := LCodRep;
    if QueryValue(Req, 'cod_cliente') <> '' then
      LQuery.ParamByName('cod_cliente').AsInteger := LCodCliente;
    if LNome <> '' then
      LQuery.ParamByName('nome').AsString := '%' + LNome + '%';
    if QueryValue(Req, 'data_ultima_venda') <> '' then
      LQuery.ParamByName('data_ultima_venda').AsDate := LDataUltimaVenda;
    if QueryValue(Req, 'data_ultima_venda_inicial') <> '' then
      LQuery.ParamByName('data_ultima_venda_inicial').AsDate := LDataUltimaVendaInicial;
    if QueryValue(Req, 'data_ultima_venda_final') <> '' then
      LQuery.ParamByName('data_ultima_venda_final').AsDate := LDataUltimaVendaFinal;

    LQuery.Open;

    LArray := ClientesToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure PostClienteHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LJSON: TJSONValue;
  LBody: TJSONObject;
  LCliente: TJSONObject;
  LClienteValue: TJSONValue;
  LResult: TJSONObject;
  LCodCliente: string;
begin
  LConn := nil;
  LJSON := nil;
  LResult := nil;

  try
    LJSON := TJSONObject.ParseJSONValue(Req.Body);
    if not (LJSON is TJSONObject) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"JSON invalido"}');
      Exit;
    end;

    LBody := TJSONObject(LJSON);
    LClienteValue := LBody.GetValue('cliente');

    if Assigned(LClienteValue) then
    begin
      if not (LClienteValue is TJSONObject) then
      begin
        Res.Status(400).ContentType('application/json').Send('{"error":"Objeto cliente invalido"}');
        Exit;
      end;
      LCliente := TJSONObject(LClienteValue);
    end
    else
      LCliente := LBody;

    if not Assigned(LCliente.GetValue('nom_cliente')) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"nom_cliente obrigatorio"}');
      Exit;
    end;

    if not Assigned(LCliente.GetValue('cliente_bloqueado')) then
      SetJSONObjectString(LCliente, 'cliente_bloqueado', 'N');
    if not Assigned(LCliente.GetValue('dta_cad')) then
      SetJSONObjectString(LCliente, 'dta_cad', FormatDateTime('yyyy-mm-dd', Date));

    LConn := NewConnection;
    LConn.StartTransaction;
    try
      LCodCliente := ExecuteInsertFromJSONReturning(LConn, 'cliente', LCliente, 'cod_cliente');
      LConn.Commit;
    except
      if Assigned(LConn) and LConn.InTransaction then
        LConn.Rollback;
      raise;
    end;

    LResult := TJSONObject.Create;
    LResult.AddPair('success', TJSONBool.Create(True));
    LResult.AddPair('cod_cliente', LCodCliente);
    Res.Status(201).ContentType('application/json').Send(LResult.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LResult.Free;
  LJSON.Free;
  LConn.Free;
end;

procedure DashboardMetaHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LJSON: TJSONValue;
  LBody: TJSONObject;
  LCodRepresentante: Integer;
  LMes: string;
  LResult: TJSONObject;
begin
  LJSON := nil;
  LResult := nil;

  try
    LJSON := TJSONObject.ParseJSONValue(Req.Body);
    if not (LJSON is TJSONObject) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"Body JSON invalido"}');
      Exit;
    end;

    LBody := TJSONObject(LJSON);
    LCodRepresentante := LBody.GetValue<Integer>('codRepresentante', 0);
    if LCodRepresentante <= 0 then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"Campo codRepresentante e obrigatorio"}');
      Exit;
    end;

    LMes := Trim(LBody.GetValue<string>('mes', ''));
    if LMes = '' then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"Campo mes e obrigatorio"}');
      Exit;
    end;

    LResult := GetMetaRepresentanteJSON(LCodRepresentante, LMes);
    Res.Status(200).ContentType('application/json').Send(LResult.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LResult.Free;
  LJSON.Free;
end;

procedure RepresentantesHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := CRepresentantesSQL;
    LQuery.Open;

    LArray := RepresentantesToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure FormasPagamentoHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := CFormasPagamentoSQL;
    LQuery.Open;

    LArray := FormasPagamentoToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure PrazosHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := CPrazosSQL;
    LQuery.Open;

    LArray := PrazosToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure CidadesHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LConn: TFDConnection;
  LQuery: TFDQuery;
  LArray: TJSONArray;
  LSQL: string;
  LCodCidade: Integer;
  LCodRepresentante: Integer;
  LUF: string;
  LNome: string;
begin
  LConn := nil;
  LQuery := nil;
  LArray := nil;
  LSQL := CCidadesBaseSQL;
  LUF := Trim(QueryValue(Req, 'uf'));
  LNome := Trim(QueryValue(Req, 'nome'));

  if QueryValue(Req, 'cod_cidade') <> '' then
  begin
    if not TryStrToInt(QueryValue(Req, 'cod_cidade'), LCodCidade) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"cod_cidade invalido"}');
      Exit;
    end;
    LSQL := LSQL + ' and cod_cidade = :cod_cidade';
  end;

  if QueryValue(Req, 'cod_representante') <> '' then
  begin
    if not TryStrToInt(QueryValue(Req, 'cod_representante'), LCodRepresentante) then
    begin
      Res.Status(400).ContentType('application/json').Send('{"error":"cod_representante invalido"}');
      Exit;
    end;
    LSQL := LSQL + ' and cod_representante = :cod_representante';
  end;

  if LUF <> '' then
    LSQL := LSQL + ' and uf = :uf';

  if LNome <> '' then
    LSQL := LSQL + ' and nom_cidade ilike :nome';

  LSQL := LSQL + ' order by uf, nom_cidade';

  try
    LConn := NewConnection;

    LQuery := TFDQuery.Create(nil);
    LQuery.Connection := LConn;
    LQuery.SQL.Text := LSQL;

    if QueryValue(Req, 'cod_cidade') <> '' then
      LQuery.ParamByName('cod_cidade').AsInteger := LCodCidade;
    if QueryValue(Req, 'cod_representante') <> '' then
      LQuery.ParamByName('cod_representante').AsInteger := LCodRepresentante;
    if LUF <> '' then
      LQuery.ParamByName('uf').AsString := UpperCase(LUF);
    if LNome <> '' then
      LQuery.ParamByName('nome').AsString := '%' + LNome + '%';

    LQuery.Open;

    LArray := CidadesToJSONArray(LQuery);
    Res.Status(200).ContentType('application/json').Send(LArray.ToJSON);
  except
    on E: Exception do
      Res.Status(500).ContentType('application/json').Send('{"error":"' + StringReplace(E.Message, '"', '\\"', [rfReplaceAll]) + '"}');
  end;

  LArray.Free;
  LQuery.Free;
  LConn.Free;
end;

procedure DownloadOrbiUpdateHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
var
  LArquivo: string;
begin
  LArquivo := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'OrbiUpdate.exe';

  if FileExists(LArquivo) then
    Res.Download(LArquivo, 'application/octet-stream')
  else
    Res.Status(404).ContentType('application/json').Send('{"error":"OrbiUpdate.exe nao encontrado"}');
end;

procedure HealthHandler(Req: THorseRequest; Res: THorseResponse; Next: TNextProc);
begin
  Res.Send('Orbi API online');
end;

procedure RegisterRoutes;
begin
  THorse.Get('/', HealthHandler);
  THorse.Get('/download/orbiupdate', DownloadOrbiUpdateHandler);
  THorse.Get('/produtos', ProdutosHandler);
  THorse.Get('/ProdutosId/:cod_produto', ProdutosIdHandler);
  THorse.Post('/pedidos', PostPedidoHandler);
  THorse.Get('/vendas/detalhadas', VendasDetalhadasHandler);
  THorse.Get('/vendas/detalhadas/faturadas', VendasDetalhadasFaturadasHandler);
  THorse.Get('/vendas/detalhadas/abertas', VendasDetalhadasAbertasHandler);
  THorse.Get('/clientes', ClientesHandler);
  THorse.Post('/clientes', PostClienteHandler);
  THorse.Get('/representantes', RepresentantesHandler);
  THorse.Get('/formas-pagamento', FormasPagamentoHandler);
  THorse.Get('/prazos', PrazosHandler);
  THorse.Get('/cidades', CidadesHandler);
  THorse.Post('/api/dashboard/meta', DashboardMetaHandler);
end;

end.
