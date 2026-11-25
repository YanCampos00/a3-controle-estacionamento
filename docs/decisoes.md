# Decisões de modelagem

Decisões tomadas onde as 15 regras de negócio eram omissas ou admitiam mais de uma leitura. Cada item traz a decisão e a justificativa.

## Estrutura geral

**D01. Uma única unidade de estacionamento.**
A tabela `estacionamento` tem uma só linha, garantida por `CHECK (cod_estacionamento = 1)`. As demais tabelas não têm FK para ela.
*Justificativa:* a RN03 pede os dados e a capacidade do estacionamento, e "várias unidades" está fora do escopo. Uma FK em cada tabela apontando para a única linha só acrescentaria redundância.

**D02. O endereço é um atributo composto.**
No conceitual, `endereço` tem os filhos logradouro, número, bairro, cidade, UF e CEP. No lógico, cada um vira uma coluna.
*Justificativa:* assim cada parte pode ser consultada separadamente (por exemplo, por cidade) e a 1FN é respeitada.

**D03. As datas ficam em TEXT no formato ISO.**
Datas usam `AAAA-MM-DD` e datas com hora usam `AAAA-MM-DD HH:MM:SS`. Um `CHECK (col = date(col))` ou `CHECK (col = datetime(col))` rejeita valores fora do formato.
*Justificativa:* o SQLite não tem tipo de data. Nesse formato, a ordenação alfabética é igual à cronológica e as funções `date`, `datetime` e `julianday` funcionam direto.

**D04. Os valores em dinheiro são REAL.**
*Justificativa:* os valores têm duas casas e servem a consultas simples. A alternativa seria guardar centavos em `INTEGER`, o que deixaria os dados de teste e as consultas menos legíveis para a avaliação.

## Clientes, veículos e funcionários

**D05. O cliente tem chave substituta, e o CPF é UNIQUE.**
*Justificativa:* a chave `cod_cliente` é estável e curta para as FKs. O CPF continua único e obrigatório. Nos dados de teste, os CPFs são sequências fictícias que não passam na validação de dígitos.

**D06. Os telefones do cliente formam um atributo multivalorado.**
No lógico, isso vira a tabela `telefone_cliente (cod_cliente, telefone)`, com PK composta.
*Justificativa:* um cliente pode ter mais de um telefone. Guardá-los numa só coluna violaria a 1FN.

**D07. O veículo é identificado pela placa, que é a PK natural.**
Um `CHECK` aceita o padrão antigo (AAA9999) e o Mercosul (AAA9A99).
*Justificativa:* a RN01 diz que o veículo é identificado pela placa. A regra "só há carros" já é garantida pela base fornecida, que contém apenas carros.

**D08. O vínculo entre veículo e cliente fica em `veiculo.cod_cliente`, que aceita nulo.**
Uma placa desconhecida entra com `cod_cliente` nulo (RN02). Quando o motorista se identifica como mensalista, a coluna é atualizada.
*Justificativa:* a RN02 descreve exatamente isso. Um veículo pertence a no máximo um cliente.

**D09. O titular do contrato fica no próprio contrato.**
`contrato.cod_cliente` registra o titular, separado de `veiculo.cod_cliente`.
*Justificativa:* a RN12 manda o contrato registrar o titular. Isso preserva o histórico se o veículo mudar de dono depois do contrato. Nos dados de teste, os dois valores coincidem.

**D10. O funcionário tem matrícula UNIQUE.**
Não há turnos nem outros controles.
*Justificativa:* é o "cadastro simples" pedido no enunciado. A matrícula é o identificador de negócio, e não é preciso guardar o CPF de funcionários.

## Estadias, tarifas e pagamentos

**D11. A tarifa guarda apenas o início da vigência.**
A tarifa vigente numa data D é a de maior `inicio_vigencia <= D`, que vale até a véspera do início da tarifa seguinte. `inicio_vigencia` é UNIQUE.
*Justificativa:* guardar só o início impede, por construção, lacunas e sobreposições entre tarifas, que seriam possíveis com colunas de início e fim. Atende à RN09.

**D12. O tipo da estadia (rotativa ou de mensalista) é derivado e não é armazenado.**
A estadia é de mensalista quando existe um contrato do mesmo veículo com `data_inicio <= date(entrada) <= data_fim` (consulta 15).
*Justificativa:* a RN07 define o tipo a partir do contrato. Guardá-lo seria redundante e poderia ficar inconsistente com os contratos. No conceitual, aparece como atributo derivado (círculo tracejado).

**D13. A vigência do contrato inclui as duas pontas.**
Os dias de início e de fim fazem parte do contrato. Para a RN07, conta a data (sem a hora) da entrada.
*Justificativa:* é a leitura mais natural de "vigente na data da entrada".

**D14. O valor devido é calculado, e o pagamento guarda o valor recebido.**
A consulta 14 calcula o devido assim: tarifa vigente na data da entrada × horas, com a fração arredondada para cima. A tabela `pagamento` registra o valor efetivamente recebido.
*Justificativa:* o devido depende da saída e da tarifa, e guardá-lo seria redundante. Nos dados de teste, todo pagamento é igual ao valor devido.

**D15. Como as horas são contadas (RN08).**
A permanência é medida em minutos (arredondados ao minuto). As horas cobradas são `(minutos + 59) / 60`, em divisão inteira. Qualquer minuto além de uma hora cheia gera mais uma hora (2h01 vira 3h), e a permanência mínima cobra 1 hora.
*Justificativa:* a RN08 diz que a fração conta como hora cheia, e tolerância está fora do escopo.

**D16. Cada estadia tem no máximo um pagamento (RN10).**
Isso é garantido por `UNIQUE (cod_estadia)` em `pagamento`. O banco não impede que uma estadia de mensalista receba pagamento, porque isso exigiria um trigger que consultasse contratos. Os dados de teste respeitam a regra, e a conferência pode ser feita combinando as consultas 14 e 15.
*Justificativa:* a regra "um único pagamento, com uma única forma" é estrutural. Já "mensalista não paga" depende de um dado derivado (D12).

**D17. As formas de pagamento são fixas, controladas por CHECK.**
Os valores aceitos são 'Dinheiro', 'Débito', 'Crédito' e 'PIX'.
*Justificativa:* a RN10 lista exatamente essas quatro e não fala em cadastrar outras.

**D18. Só o funcionário da entrada é registrado na estadia.**
*Justificativa:* a RN06 pede o funcionário que registrou a entrada. Na saída, quem importa é o funcionário que recebeu o pagamento, que já fica em `pagamento`.

**D19. A loja conveniada tem a coluna `ativa`, com DEFAULT 1.**
*Justificativa:* assim um convênio pode ser encerrado sem apagar a loja nem perder o histórico das estadias vinculadas.

**D20. "Agora" significa "estadias sem saída".**
As consultas 1 e 13 não usam o relógio do sistema. Um veículo está dentro do estacionamento enquanto a estadia não tem `data_hora_saida` (RN04).
*Justificativa:* o resultado fica reproduzível com os dados de teste, seja qual for o dia em que o professor executar.

## Mensalistas

**D21. A mensalidade é uma entidade fraca do contrato.**
A PK é `(cod_contrato, ano, mes)`. A competência é um atributo composto (mês, ano) e funciona como identificador parcial.
*Justificativa:* a mensalidade não existe sem o contrato, e cada contrato tem no máximo uma mensalidade por competência (RN13).

**D22. A mensalidade não tem coluna de valor.**
O valor cobrado é o `valor_mensal` do contrato. Um reajuste é feito com um novo contrato.
*Justificativa:* a RN13 não pede valor por mensalidade, e repetir o valor do contrato seria redundância (3FN).

## Ocorrências

**D23. O tipo de ocorrência fica numa tabela de domínio.**
A tabela é `tipo_ocorrencia (cod_tipo, nome UNIQUE)`.
*Justificativa:* a RN15 não define a lista de tipos. Com uma tabela, é possível criar tipos novos sem alterar o schema, e a grafia não varia, o que importa para a consulta 7.

## Garantias além do mínimo

**D24. A RN05 também é garantida pelo banco.**
Um índice único parcial, `ux_estadia_aberta_por_placa ON estadia(placa) WHERE data_hora_saida IS NULL`, impede duas estadias em aberto para a mesma placa.
*Justificativa:* custa uma linha e evita o erro na origem. A consulta 16 continua como auditoria e retorna vazio.

**D25. A RN14 também é garantida pelo banco.**
Os triggers `tg_contrato_sem_sobreposicao_ins` e `_upd` rejeitam contratos sobrepostos para o mesmo veículo. Os períodos [a,b] e [c,d] se sobrepõem quando a ≤ d e c ≤ b.
*Justificativa:* o SQLite não tem restrição de exclusão, e um trigger é a forma mais simples de bloquear a sobreposição. A consulta 17 continua como auditoria e retorna vazio.
