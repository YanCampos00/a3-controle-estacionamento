# Modelo físico (SQLite)

O modelo físico é o script [`sql/01-schema.sql`](../../sql/01-schema.sql). Ele implementa exatamente as tabelas e chaves do [modelo lógico](../02-logico/README.md).

## Ordem de criação

O script começa com `PRAGMA foreign_keys = ON;` e cria as tabelas na ordem das dependências. As tabelas `marca` e `modelo` já existem, criadas pelo `00-base-fornecida.sql`.

1. estacionamento
2. funcionario
3. cliente
4. telefone_cliente
5. veiculo
6. tarifa
7. loja_conveniada
8. contrato
9. mensalidade
10. estadia
11. pagamento
12. tipo_ocorrencia
13. ocorrencia

No início, o script também apaga as tabelas do grupo com `DROP TABLE IF EXISTS`, na ordem inversa. Por isso ele pode ser executado de novo sem erro.

## Tipos de dados

| Uso | Tipo SQLite | Exemplo |
|---|---|---|
| Chaves substitutas | `INTEGER PRIMARY KEY` (alias do rowid) | `cod_estadia` |
| Textos | `TEXT` | `nome`, `placa`, `cpf` |
| Datas | `TEXT` `AAAA-MM-DD` | `data_inicio` |
| Data e hora | `TEXT` `AAAA-MM-DD HH:MM:SS` | `data_hora_entrada` |
| Valores em R$ | `REAL` | `valor_hora`, `valor` |
| Inteiros de domínio | `INTEGER` | `capacidade`, `ano`, `mes`, `ativa` (0/1) |

A justificativa para datas em TEXT e valores em REAL está nas [decisões D03 e D04](../decisoes.md).

## Restrições

O enunciado pede um mínimo de restrições. Todas as exigências foram atendidas:

| Exigência | Atendimento |
|---|---|
| PRIMARY KEY em todas as tabelas | Sim, nas 13 tabelas do grupo |
| FOREIGN KEY em todos os relacionamentos | Sim, 15 FKs (incluindo `modelo → marca` da base) |
| NOT NULL no que é obrigatório | Sim. Só aceitam nulo `cliente.email`, `veiculo.cod_cliente`, `mensalidade.data_pagamento`, `estadia.data_hora_saida` e `estadia.cod_loja` |
| ≥ 3 CHECK com sentido de negócio | Ver a tabela de CHECKs abaixo |
| ≥ 2 UNIQUE | Ver a tabela de UNIQUEs abaixo (7, além do índice único parcial da RN05) |
| ≥ 1 DEFAULT | `loja_conveniada.ativa DEFAULT 1`, `estadia.data_hora_entrada DEFAULT (datetime('now','localtime'))`, `pagamento.data_hora DEFAULT (datetime('now','localtime'))` |

**CHECKs com sentido de negócio:**

| Tabela | Restrição |
|---|---|
| pagamento | `forma IN ('Dinheiro','Débito','Crédito','PIX')` |
| pagamento | `valor > 0` |
| estadia | `data_hora_saida > data_hora_entrada` |
| contrato | `data_fim > data_inicio` |
| contrato | `valor_mensal > 0` |
| tarifa | `valor_hora > 0` |
| estacionamento | `capacidade > 0` |
| estacionamento | `cod_estacionamento = 1` (unidade única) |
| mensalidade | `mes BETWEEN 1 AND 12` |
| veiculo | formato da placa |
| cliente | formato do CPF |
| várias | formato das datas |

**UNIQUEs:**

| Tabela | Coluna(s) |
|---|---|
| cliente | `cpf` |
| cliente | `email` |
| funcionario | `matricula` |
| tarifa | `inicio_vigencia` |
| loja_conveniada | `nome` |
| tipo_ocorrencia | `nome` |
| pagamento | `cod_estadia` (garante um pagamento por estadia, RN10) |

## Índices

| Índice | Finalidade |
|---|---|
| `ux_estadia_aberta_por_placa` (UNIQUE parcial, `WHERE data_hora_saida IS NULL`) | Garante a RN05: no máximo uma estadia em aberto por veículo |
| `ix_estadia_placa_entrada (placa, data_hora_entrada)` | Histórico de estadias por veículo, junções com veiculo |
| `ix_estadia_loja (cod_loja)` | Consulta 11 (estadias por loja) |
| `ix_contrato_placa_inicio (placa, data_inicio)` | Busca do contrato vigente (consultas 14 e 15), auditoria da RN14 |
| `ix_veiculo_cliente (cod_cliente)` | Veículos de um cliente, consulta 2 |
| `ix_ocorrencia_estadia (cod_estadia)` | Junção da consulta 12 |

O SQLite já cria índices automaticamente para as PRIMARY KEY e UNIQUE.

## Triggers

| Trigger | Finalidade |
|---|---|
| `tg_contrato_sem_sobreposicao_ins` | Rejeita, no INSERT em `contrato`, um período que se sobreponha a outro contrato do mesmo veículo (RN14) |
| `tg_contrato_sem_sobreposicao_upd` | Faz a mesma verificação no UPDATE |

## Testes negativos realizados

As instruções abaixo foram executadas sobre o banco populado, e todas foram **rejeitadas**, como esperado:

| Tentativa | Erro |
|---|---|
| Segunda estadia em aberto para `EST1B02` | `UNIQUE constraint failed: estadia.placa` (RN05) |
| Contrato de `EST1B02` de 2026-12-01 a 2027-06-30 | `RN14: contrato sobreposto para o mesmo veiculo` |
| Pagamento com forma 'Cheque' | `CHECK constraint failed` |
| Segundo pagamento para a estadia 1 | `UNIQUE constraint failed: pagamento.cod_estadia` |
| Estadia com saída anterior à entrada | `CHECK constraint failed` |
| Veículo com `cod_modelo = 999` | `FOREIGN KEY constraint failed` |
| Segundo estacionamento | `CHECK constraint failed: cod_estacionamento = 1` |
