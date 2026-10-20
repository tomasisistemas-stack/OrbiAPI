using System;
using System.IO;
using System.Text;
using System.Text.RegularExpressions;

class FixVendasLoopFlags
{
    static readonly Encoding Enc = Encoding.Default;

    static string R(string text, string pattern, string repl, string label)
    {
        var rx = new Regex(pattern, RegexOptions.Singleline);
        if (!rx.IsMatch(text)) throw new Exception("Nao encontrado: " + label);
        return rx.Replace(text, repl, 1);
    }

    static void Main()
    {
        string path = @"C:\Tomasi Sistemas\Orbi\Un_vendas_industria2.pas";
        string text = File.ReadAllText(path, Enc);

        text = R(text,
            @"localizar_acionado, carregando_item, cliente_alterado, cliente_bloqueado, cliente_com_pendencia, habilita_faturamento, cliente_isento_icms, cliente_consumidor_final, cliente_sem_ie, Mostra, produto_alterado, cliente_pre_cadastrado, representante_funcionario, GravarPedido, aviso_conta_boleto, promocao_desconto: boolean;",
            "localizar_acionado, carregando_item, cliente_alterado, cliente_bloqueado, cliente_com_pendencia, habilita_faturamento, cliente_isento_icms, cliente_consumidor_final, cliente_sem_ie, Mostra, produto_alterado, cliente_pre_cadastrado, representante_funcionario, GravarPedido, aviso_conta_boleto, promocao_desconto, validando_conta_boleto, validando_empresa_faturar, validando_cfoptroca: boolean;",
            "flags globais");

        text = R(text,
            @"begin\s*if mform = 'vendas_devolucoes' then\s*Exit;",
            "begin\r\n  if validando_cfoptroca then\r\n    Exit;\r\n  validando_cfoptroca := True;\r\n  try\r\n    if mform = 'vendas_devolucoes' then\r\n      Exit;",
            "inicio cfoptroca");

        text = R(text,
            @"  if alterar_itens then\s*begin\s*AtualizarCFOPItens\('Alterando CFOP dos Itens\.\.\.'\);\s*somaTotal;\s*end;\s*end;\s*function TFr_vendas_industria2\.ChecaCFOP",
            "  if alterar_itens then\r\n  begin\r\n    AtualizarCFOPItens('Alterando CFOP dos Itens...');\r\n    somaTotal;\r\n  end;\r\n  finally\r\n    validando_cfoptroca := False;\r\n  end;\r\nend;\r\n\r\nfunction TFr_vendas_industria2.ChecaCFOP",
            "fim cfoptroca");

        text = R(text,
            @"procedure TFr_vendas_industria2\.Prempresa_faturarExit\(Sender: TObject\);\s*var\s*bConsumidorFinal : Boolean;\s*begin",
            "procedure TFr_vendas_industria2.Prempresa_faturarExit(Sender: TObject);\r\nvar\r\n  bConsumidorFinal : Boolean;\r\nbegin\r\n  if validando_empresa_faturar then\r\n    Exit;\r\n  validando_empresa_faturar := True;\r\n  try",
            "inicio empresa");

        text = R(text,
            @"\s*end;\s*procedure TFr_vendas_industria2\.monta_sgpro;",
            "\r\n  finally\r\n    validando_empresa_faturar := False;\r\n  end;\r\nend;\r\n\r\nprocedure TFr_vendas_industria2.monta_sgpro;",
            "fim empresa");

        text = R(text,
            @"procedure TFr_vendas_industria2\.PrCONTA_BOLETOExit\(Sender: TObject\);\s*var\s*sql_boleto: string;\s*begin",
            "procedure TFr_vendas_industria2.PrCONTA_BOLETOExit(Sender: TObject);\r\nvar\r\n  sql_boleto: string;\r\nbegin\r\n  if validando_conta_boleto then\r\n    Exit;\r\n  validando_conta_boleto := True;\r\n  try",
            "inicio conta boleto");

        text = R(text,
            @"\s*end;\s*procedure TFr_vendas_industria2\.FormClose\(Sender: TObject; var Action: TCloseAction\);",
            "\r\n  finally\r\n    validando_conta_boleto := False;\r\n  end;\r\nend;\r\n\r\nprocedure TFr_vendas_industria2.FormClose(Sender: TObject; var Action: TCloseAction);",
            "fim conta boleto");

        File.WriteAllText(path, text, Enc);
        Console.WriteLine("OK");
    }
}
