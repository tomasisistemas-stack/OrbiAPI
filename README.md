# Orbi API (Horse + PostgreSQL)

API Delphi com Horse para consultar produtos no PostgreSQL.

## Endpoint

- `GET /produtos`
- `GET /ProdutosId/:cod_produto`
- `POST /pedidos`
- No `POST /pedidos`, os campos `nfeentradasaida`, `orcamento` e `faturado` sao fixados como `0` pela API.
- No `POST /pedidos`, o `numdoc` nao deve ser enviado no body; ele e gerado pela trigger no insert de `vendas1` e reutilizado nos itens de `vendas2`.
- No `POST /pedidos`, o item pode enviar `preco_venda`, `preco`, `sub_total_bruto` e `sub_total` para manter o contrato do app. A API busca o valor oficial em `produto.preco_venda`, grava em `vendas2.preco_bruto` e recalcula `preco`, `sub_total_bruto`, `desconto_valor` e `sub_total` usando `qtd` e `desconto`.
- No `POST /pedidos`, se `cod_empresa` nao for enviado em `vendas1`, a API usa `1`.
- No `POST /pedidos`, `vendas1` aceita `cod_fop`, `cod_prazo_pgto` e `observacoes_pedido`.
- `GET /vendas/detalhadas/faturadas`
- `GET /vendas/detalhadas/abertas`
- `GET /vendas/detalhadas/faturadas?codrep=1`
- `GET /vendas/detalhadas/abertas?codrep=1`
- `GET /vendas/detalhadas/faturadas?cod_cliente=1`
- `GET /vendas/detalhadas/abertas?cod_cliente=1`
- `GET /vendas/detalhadas/faturadas?numdoc=123`
- `GET /vendas/detalhadas/abertas?numdoc=123`
- `GET /vendas/detalhadas/faturadas?data_inicial=2026-01-01&data_final=2026-01-31`
- `GET /vendas/detalhadas/abertas?data_inicial=2026-01-01&data_final=2026-01-31`
- `GET /vendas/detalhadas/faturadas?filtro=cliente`
- `GET /vendas/detalhadas/abertas?filtro=cliente`
- O retorno de vendas detalhadas inclui os itens da venda no array `itens`.
- O filtro de periodo das vendas abertas usa `dtadoc`; o das faturadas usa `dta_emissao`.
- `GET /vendas/detalhadas` permanece como compatibilidade para vendas faturadas (`faturado = 1`).
- `GET /clientes`
- `POST /clientes`
- `GET /clientes?codrep=1`
- `GET /clientes?cod_cliente=1`
- `GET /clientes?nome=cliente`
- `GET /clientes?data_ultima_venda=2026-01-31`
- `GET /clientes?data_ultima_venda_inicial=2026-01-01&data_ultima_venda_final=2026-01-31`
- `GET /representantes`
- `GET /formas-pagamento`
- `GET /prazos`
- `GET /cidades`
- `GET /cidades?uf=SP`
- `GET /cidades?nome=sao`
- `GET /cidades?cod_cidade=1`
- `GET /cidades?cod_representante=1`
- `POST /api/dashboard/meta`

Exemplo de body para `POST /clientes`:

```json
{
  "cliente": {
    "nom_cliente": "Cliente Teste API",
    "nom_fantasia": "Cliente API",
    "endereco": "Rua Teste",
    "nr_endereco": "123",
    "complemento": "Sala 1",
    "bairro": "Centro",
    "cep": "00000000",
    "cod_cidade": 1,
    "tip_pessoa": "F",
    "telefone": "",
    "email": "",
    "cpf": "",
    "rg": "",
    "cnpj": "",
    "ie": "",
    "im": "",
    "contato": "",
    "fone_contato": "",
    "whastapp": "",
    "id_representante": 1,
    "cod_empresa": 1
  }
}
```
- SQL executado:

```sql
select p.cod_produto, p.nom_produto, p.codigo_barra, p.qtd_estoque, p.custo, p.preco_venda, p.desconto_maximo
from produto p
where p.status <> 'S'
```

## Seguranca por hash

Os endpoints exigem o header:

- `X-API-HASH: <hash_sha256>`

Hash padrao configurado:

- `ccc5915dd321d8446aecf4dce952adc827ba7833307c0d004dba55c83e0e191f`

Voce pode trocar no arquivo `orbiapi.ini` na secao `[Security]`.

## Arquivo de configuracao (`orbiapi.ini`)

O arquivo deve ficar na mesma pasta do executavel da API.

Exemplo:

```ini
[Server]
Port=9002

[Database]
Host=26.236.165.177
Name=orbi
User=postgres
Password=postgres

[Security]
ApiHash=ccc5915dd321d8446aecf4dce952adc827ba7833307c0d004dba55c83e0e191f
```

## Collection Postman

Arquivo:

- `postman/OrbiAPI.postman_collection.json`

Inclui:

- `GET /` (health)
- `POST /pedidos` (com `X-API-HASH`)
- `GET /produtos` (com `X-API-HASH`)
- `GET /ProdutosId/:cod_produto` (com `X-API-HASH`)
- `GET /vendas/detalhadas/faturadas` (com `X-API-HASH`)
- `GET /vendas/detalhadas/abertas` (com `X-API-HASH`)
- `GET /clientes` (com `X-API-HASH`)
- `POST /clientes` (com `X-API-HASH`)
- `GET /representantes` (com `X-API-HASH`)
- `GET /formas-pagamento` (com `X-API-HASH`)
- `GET /prazos` (com `X-API-HASH`)
- `GET /cidades` (com `X-API-HASH`)
- `POST /api/dashboard/meta` (com `X-API-HASH`)

## Dependencias Delphi

Instale no projeto:

- Horse
- FireDAC PostgreSQL driver

Unidades usadas:

- `Horse`
- `FireDAC.Comp.Client`, `FireDAC.Phys.PG` e relacionadas
