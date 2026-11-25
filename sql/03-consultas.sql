-- ============================================================
-- 03-CONSULTAS: as 17 consultas obrigatórias
-- Executar após 00, 01 e 02. Abaixo de cada consulta está o resultado
-- obtido com os dados de teste de 02-dados.sql.
--
-- Definições usadas em várias consultas:
--   * estadia em aberto: data_hora_saida IS NULL;
--   * estadia de mensalista (RN07): existe contrato do mesmo veículo com
--     data_inicio <= date(entrada) <= data_fim; as demais são rotativas;
--   * tarifa vigente numa data (RN09): a de maior inicio_vigencia <= data;
--   * horas cobradas (RN08): minutos de permanência arredondados para
--     cima em horas cheias: (minutos + 59) / 60, em divisão inteira.
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- Consulta 01 (RN06) - Quais veículos estão no estacionamento agora
-- (entrada sem saída)? Placa e horário de entrada, do mais antigo ao
-- mais recente.
-- ------------------------------------------------------------
SELECT e.placa,
       e.data_hora_entrada
FROM estadia e
WHERE e.data_hora_saida IS NULL
ORDER BY e.data_hora_entrada;
-- Resultado (4 linhas):
-- +---------+---------------------+
-- |  placa  |  data_hora_entrada  |
-- +---------+---------------------+
-- | EST1B02 | 2026-11-24 08:05:00 |
-- | EST1C03 | 2026-11-24 08:30:00 |
-- | EST2G15 | 2026-11-24 10:15:00 |
-- | EST1D04 | 2026-11-24 11:00:00 |
-- +---------+---------------------+

-- ------------------------------------------------------------
-- Consulta 02 (RN02) - Quais veículos cadastrados não têm cliente
-- associado?
-- ------------------------------------------------------------
SELECT v.placa,
       ma.nome AS marca,
       mo.nome AS modelo
FROM veiculo v
JOIN modelo mo ON mo.cod_modelo = v.cod_modelo
JOIN marca  ma ON ma.cod_marca  = mo.cod_marca
WHERE v.cod_cliente IS NULL
ORDER BY v.placa;
-- Resultado (7 linhas):
-- +---------+------------+---------+
-- |  placa  |   marca    | modelo  |
-- +---------+------------+---------+
-- | EST2A09 | Nissan     | Kicks   |
-- | EST2B10 | Fiat       | Strada  |
-- | EST2C11 | Volkswagen | T-Cross |
-- | EST2D12 | Chevrolet  | Tracker |
-- | EST2E13 | Peugeot    | 208     |
-- | EST2F14 | BMW        | X1      |
-- | EST2G15 | Hyundai    | Creta   |
-- +---------+------------+---------+

-- ------------------------------------------------------------
-- Consulta 03 (RN13) - Quais mensalidades ainda não foram pagas?
-- Contrato, competência e vencimento.
-- ------------------------------------------------------------
SELECT m.cod_contrato,
       printf('%02d/%04d', m.mes, m.ano) AS competencia,
       m.data_vencimento
FROM mensalidade m
WHERE m.data_pagamento IS NULL
ORDER BY m.data_vencimento, m.cod_contrato;
-- Resultado (3 linhas):
-- +--------------+-------------+-----------------+
-- | cod_contrato | competencia | data_vencimento |
-- +--------------+-------------+-----------------+
-- |            3 | 11/2026     | 2026-11-05      |
-- |            2 | 11/2026     | 2026-11-10      |
-- |            4 | 11/2026     | 2026-11-15      |
-- +--------------+-------------+-----------------+

-- ------------------------------------------------------------
-- Consulta 04 (RN09) - Qual era a tarifa por hora vigente em 05/03/2024?
-- ------------------------------------------------------------
SELECT t.cod_tarifa,
       t.inicio_vigencia,
       t.valor_hora
FROM tarifa t
WHERE t.inicio_vigencia <= '2024-03-05'
ORDER BY t.inicio_vigencia DESC
LIMIT 1;
-- Resultado (1 linha):
-- +------------+-----------------+------------+
-- | cod_tarifa | inicio_vigencia | valor_hora |
-- +------------+-----------------+------------+
-- |          1 | 2024-01-01      |       10.0 |
-- +------------+-----------------+------------+

-- ------------------------------------------------------------
-- Consulta 05 (RN06) - Quantas estadias começaram em cada dia?
-- ------------------------------------------------------------
SELECT date(e.data_hora_entrada) AS dia,
       COUNT(*)                  AS qtd_estadias
FROM estadia e
GROUP BY date(e.data_hora_entrada)
ORDER BY dia;
-- Resultado (4 linhas):
-- +------------+--------------+
-- |    dia     | qtd_estadias |
-- +------------+--------------+
-- | 2024-03-05 |            5 |
-- | 2026-11-20 |            9 |
-- | 2026-11-23 |            9 |
-- | 2026-11-24 |            8 |
-- +------------+--------------+

-- ------------------------------------------------------------
-- Consulta 06 (RN10) - Quanto foi recebido em cada forma de pagamento?
-- ------------------------------------------------------------
SELECT p.forma,
       COUNT(*)               AS qtd_pagamentos,
       ROUND(SUM(p.valor), 2) AS total_recebido
FROM pagamento p
GROUP BY p.forma
ORDER BY total_recebido DESC, p.forma;
-- Resultado (4 linhas):
-- +----------+----------------+----------------+
-- |  forma   | qtd_pagamentos | total_recebido |
-- +----------+----------------+----------------+
-- | Débito   |              5 |          250.0 |
-- | Dinheiro |              6 |          180.0 |
-- | PIX      |              5 |          175.0 |
-- | Crédito  |              5 |          150.0 |
-- +----------+----------------+----------------+

-- ------------------------------------------------------------
-- Consulta 07 (RN15) - Quantas ocorrências houve de cada tipo?
-- (LEFT JOIN: tipos sem ocorrência aparecem com 0)
-- ------------------------------------------------------------
SELECT t.nome                  AS tipo,
       COUNT(o.cod_ocorrencia) AS qtd_ocorrencias
FROM tipo_ocorrencia t
LEFT JOIN ocorrencia o ON o.cod_tipo = t.cod_tipo
GROUP BY t.cod_tipo, t.nome
ORDER BY qtd_ocorrencias DESC, t.nome;
-- Resultado (4 linhas):
-- +--------------------------+-----------------+
-- |           tipo           | qtd_ocorrencias |
-- +--------------------------+-----------------+
-- | Perda de ticket          |               2 |
-- | Estacionamento irregular |               1 |
-- | Objeto esquecido         |               1 |
-- | Reclamação               |               1 |
-- +--------------------------+-----------------+

-- ------------------------------------------------------------
-- Consulta 08 (RN06) - Qual a permanência média, em minutos, das
-- estadias encerradas?
-- ------------------------------------------------------------
SELECT COUNT(*) AS qtd_estadias_encerradas,
       ROUND(AVG((julianday(e.data_hora_saida)
                - julianday(e.data_hora_entrada)) * 1440), 2) AS media_minutos
FROM estadia e
WHERE e.data_hora_saida IS NOT NULL;
-- Resultado (1 linha):
-- +-------------------------+---------------+
-- | qtd_estadias_encerradas | media_minutos |
-- +-------------------------+---------------+
-- |                      27 |        231.48 |
-- +-------------------------+---------------+

-- ------------------------------------------------------------
-- Consulta 09 (RN01) - Para cada estadia, mostrar a placa, a marca e o
-- modelo do veículo.
-- ------------------------------------------------------------
SELECT e.cod_estadia,
       e.placa,
       ma.nome AS marca,
       mo.nome AS modelo
FROM estadia e
JOIN veiculo v ON v.placa      = e.placa
JOIN modelo mo ON mo.cod_modelo = v.cod_modelo
JOIN marca  ma ON ma.cod_marca  = mo.cod_marca
ORDER BY e.cod_estadia;
-- Resultado (31 linhas):
-- +-------------+---------+------------+---------+
-- | cod_estadia |  placa  |   marca    | modelo  |
-- +-------------+---------+------------+---------+
-- |           1 | EST2A09 | Nissan     | Kicks   |
-- |           2 | EST2B10 | Fiat       | Strada  |
-- |           3 | EST1A01 | Volkswagen | Gol     |
-- |           4 | EST1D04 | Hyundai    | HB20    |
-- |           5 | EST2C11 | Volkswagen | T-Cross |
-- |           6 | EST1A01 | Volkswagen | Gol     |
-- |           7 | EST1B02 | Chevrolet  | Onix    |
-- |           8 | EST2D12 | Chevrolet  | Tracker |
-- |           9 | EST2E13 | Peugeot    | 208     |
-- |          10 | EST1F06 | Fiat       | Argo    |
-- |          11 | EST2F14 | BMW        | X1      |
-- |          12 | EST2G15 | Hyundai    | Creta   |
-- |          13 | EST1G07 | Honda      | Civic   |
-- |          14 | EST2A09 | Nissan     | Kicks   |
-- |          15 | EST1B02 | Chevrolet  | Onix    |
-- |          16 | EST1C03 | Toyota     | Corolla |
-- |          17 | EST1D04 | Hyundai    | HB20    |
-- |          18 | EST1H08 | Renault    | Sandero |
-- |          19 | EST2B10 | Fiat       | Strada  |
-- |          20 | EST2C11 | Volkswagen | T-Cross |
-- |          21 | EST1E05 | Jeep       | Compass |
-- |          22 | EST2D12 | Chevrolet  | Tracker |
-- |          23 | EST1F06 | Fiat       | Argo    |
-- |          24 | EST1A01 | Volkswagen | Gol     |
-- |          25 | EST2E13 | Peugeot    | 208     |
-- |          26 | EST1G07 | Honda      | Civic   |
-- |          27 | EST2F14 | BMW        | X1      |
-- |          28 | EST1B02 | Chevrolet  | Onix    |
-- |          29 | EST1C03 | Toyota     | Corolla |
-- |          30 | EST2G15 | Hyundai    | Creta   |
-- |          31 | EST1D04 | Hyundai    | HB20    |
-- +-------------+---------+------------+---------+

-- ------------------------------------------------------------
-- Consulta 10 (RN12) - Listar os contratos com o nome do cliente, a placa
-- e o modelo do veículo.
-- ------------------------------------------------------------
SELECT c.cod_contrato,
       cl.nome AS cliente,
       c.placa,
       mo.nome AS modelo,
       ma.nome AS marca,
       c.data_inicio,
       c.data_fim,
       c.valor_mensal
FROM contrato c
JOIN cliente cl ON cl.cod_cliente = c.cod_cliente
JOIN veiculo v  ON v.placa        = c.placa
JOIN modelo mo  ON mo.cod_modelo  = v.cod_modelo
JOIN marca  ma  ON ma.cod_marca   = mo.cod_marca
ORDER BY c.cod_contrato;
-- Resultado (4 linhas):
-- +--------------+---------------------+---------+---------+------------+-------------+------------+--------------+
-- | cod_contrato |       cliente       |  placa  | modelo  |   marca    | data_inicio |  data_fim  | valor_mensal |
-- +--------------+---------------------+---------+---------+------------+-------------+------------+--------------+
-- |            1 | Ana Lúcia Ferraz    | EST1A01 | Gol     | Volkswagen | 2024-01-01  | 2024-12-31 |        250.0 |
-- |            2 | Bruno César Tavares | EST1B02 | Onix    | Chevrolet  | 2026-01-01  | 2026-12-31 |        320.0 |
-- |            3 | Camila Duarte Rocha | EST1C03 | Corolla | Toyota     | 2026-06-01  | 2027-05-31 |        350.0 |
-- |            4 | Ana Lúcia Ferraz    | EST1A01 | Gol     | Volkswagen | 2026-03-01  | 2027-02-28 |        340.0 |
-- +--------------+---------------------+---------+---------+------------+-------------+------------+--------------+

-- ------------------------------------------------------------
-- Consulta 11 (RN11) - Quantas estadias cada loja conveniada vinculou,
-- incluindo as lojas sem nenhuma?
-- ------------------------------------------------------------
SELECT l.cod_loja,
       l.nome               AS loja,
       COUNT(e.cod_estadia) AS qtd_estadias
FROM loja_conveniada l
LEFT JOIN estadia e ON e.cod_loja = l.cod_loja
GROUP BY l.cod_loja, l.nome
ORDER BY qtd_estadias DESC, l.nome;
-- Resultado (3 linhas):
-- +----------+----------------------+--------------+
-- | cod_loja |         loja         | qtd_estadias |
-- +----------+----------------------+--------------+
-- |        1 | Farmácia Bem-Estar   |            5 |
-- |        2 | Padaria Pão Dourado  |            5 |
-- |        3 | Livraria Página Nova |            0 |
-- +----------+----------------------+--------------+

-- ------------------------------------------------------------
-- Consulta 12 (RN15) - Listar as ocorrências com data e hora, tipo, placa
-- do veículo e nome do funcionário que registrou.
-- ------------------------------------------------------------
SELECT o.data_hora,
       t.nome AS tipo,
       e.placa,
       f.nome AS funcionario
FROM ocorrencia o
JOIN tipo_ocorrencia t ON t.cod_tipo        = o.cod_tipo
JOIN estadia e         ON e.cod_estadia     = o.cod_estadia
JOIN funcionario f     ON f.cod_funcionario = o.cod_funcionario
ORDER BY o.data_hora;
-- Resultado (5 linhas):
-- +---------------------+--------------------------+---------+-----------------------+
-- |      data_hora      |           tipo           |  placa  |      funcionario      |
-- +---------------------+--------------------------+---------+-----------------------+
-- | 2024-03-05 10:25:00 | Perda de ticket          | EST2A09 | Carlos Henrique Prado |
-- | 2026-11-20 12:15:00 | Objeto esquecido         | EST2E13 | Juliana Matos Ribeiro |
-- | 2026-11-20 19:25:00 | Reclamação               | EST1G07 | Juliana Matos Ribeiro |
-- | 2026-11-23 11:50:00 | Perda de ticket          | EST1H08 | Juliana Matos Ribeiro |
-- | 2026-11-24 10:30:00 | Estacionamento irregular | EST2G15 | Rafael Nogueira Lima  |
-- +---------------------+--------------------------+---------+-----------------------+

-- ------------------------------------------------------------
-- Consulta 13 (RN03, RN04) - Quantas vagas estão livres agora?
-- Capacidade menos estadias sem saída (rotativos e mensalistas juntos).
-- ------------------------------------------------------------
SELECT s.capacidade,
       (SELECT COUNT(*) FROM estadia e WHERE e.data_hora_saida IS NULL) AS vagas_ocupadas,
       s.capacidade
         - (SELECT COUNT(*) FROM estadia e WHERE e.data_hora_saida IS NULL) AS vagas_livres
FROM estacionamento s;
-- Resultado (1 linha):
-- +------------+----------------+--------------+
-- | capacidade | vagas_ocupadas | vagas_livres |
-- +------------+----------------+--------------+
-- |         80 |              4 |           76 |
-- +------------+----------------+--------------+

-- ------------------------------------------------------------
-- Consulta 14 (RN08, RN09) - Qual o valor devido em cada estadia rotativa
-- encerrada, pela tarifa vigente na data da entrada, com fração contando
-- como hora cheia?
-- ------------------------------------------------------------
WITH rotativa_encerrada AS (
  SELECT e.cod_estadia,
         e.placa,
         e.data_hora_entrada,
         e.data_hora_saida,
         CAST(ROUND((julianday(e.data_hora_saida)
                   - julianday(e.data_hora_entrada)) * 1440) AS INTEGER) AS minutos,
         (SELECT t.valor_hora
            FROM tarifa t
           WHERE t.inicio_vigencia <= date(e.data_hora_entrada)
           ORDER BY t.inicio_vigencia DESC
           LIMIT 1) AS valor_hora
  FROM estadia e
  WHERE e.data_hora_saida IS NOT NULL
    AND NOT EXISTS (SELECT 1
                      FROM contrato c
                     WHERE c.placa = e.placa
                       AND date(e.data_hora_entrada) BETWEEN c.data_inicio AND c.data_fim)
)
SELECT cod_estadia,
       placa,
       data_hora_entrada,
       data_hora_saida,
       minutos,
       (minutos + 59) / 60                         AS horas_cobradas,
       valor_hora,
       ROUND(valor_hora * ((minutos + 59) / 60), 2) AS valor_devido
FROM rotativa_encerrada
ORDER BY cod_estadia;
-- Resultado (21 linhas):
-- +-------------+---------+---------------------+---------------------+---------+----------------+------------+--------------+
-- | cod_estadia |  placa  |  data_hora_entrada  |   data_hora_saida   | minutos | horas_cobradas | valor_hora | valor_devido |
-- +-------------+---------+---------------------+---------------------+---------+----------------+------------+--------------+
-- |           1 | EST2A09 | 2024-03-05 08:00:00 | 2024-03-05 10:30:00 |     150 |              3 |       10.0 |         30.0 |
-- |           2 | EST2B10 | 2024-03-05 08:15:00 | 2024-03-05 09:15:00 |      60 |              1 |       10.0 |         10.0 |
-- |           4 | EST1D04 | 2024-03-05 09:00:00 | 2024-03-05 11:45:00 |     165 |              3 |       10.0 |         30.0 |
-- |           5 | EST2C11 | 2024-03-05 13:00:00 | 2024-03-05 13:20:00 |      20 |              1 |       10.0 |         10.0 |
-- |           8 | EST2D12 | 2026-11-20 08:30:00 | 2026-11-20 10:00:00 |      90 |              2 |       15.0 |         30.0 |
-- |           9 | EST2E13 | 2026-11-20 09:10:00 | 2026-11-20 12:10:00 |     180 |              3 |       15.0 |         45.0 |
-- |          10 | EST1F06 | 2026-11-20 10:00:00 | 2026-11-20 11:40:00 |     100 |              2 |       15.0 |         30.0 |
-- |          11 | EST2F14 | 2026-11-20 12:00:00 | 2026-11-20 16:45:00 |     285 |              5 |       15.0 |         75.0 |
-- |          12 | EST2G15 | 2026-11-20 14:00:00 | 2026-11-20 14:50:00 |      50 |              1 |       15.0 |         15.0 |
-- |          13 | EST1G07 | 2026-11-20 15:00:00 | 2026-11-20 19:30:00 |     270 |              5 |       15.0 |         75.0 |
-- |          14 | EST2A09 | 2026-11-20 18:00:00 | 2026-11-20 20:05:00 |     125 |              3 |       15.0 |         45.0 |
-- |          17 | EST1D04 | 2026-11-23 08:20:00 | 2026-11-23 09:00:00 |      40 |              1 |       15.0 |         15.0 |
-- |          18 | EST1H08 | 2026-11-23 09:30:00 | 2026-11-23 12:00:00 |     150 |              3 |       15.0 |         45.0 |
-- |          19 | EST2B10 | 2026-11-23 10:00:00 | 2026-11-23 13:15:00 |     195 |              4 |       15.0 |         60.0 |
-- |          20 | EST2C11 | 2026-11-23 11:00:00 | 2026-11-23 12:00:00 |      60 |              1 |       15.0 |         15.0 |
-- |          21 | EST1E05 | 2026-11-23 13:00:00 | 2026-11-23 15:30:00 |     150 |              3 |       15.0 |         45.0 |
-- |          22 | EST2D12 | 2026-11-23 16:00:00 | 2026-11-23 17:10:00 |      70 |              2 |       15.0 |         30.0 |
-- |          23 | EST1F06 | 2026-11-23 18:00:00 | 2026-11-23 22:00:00 |     240 |              4 |       15.0 |         60.0 |
-- |          25 | EST2E13 | 2026-11-24 08:00:00 | 2026-11-24 09:30:00 |      90 |              2 |       15.0 |         30.0 |
-- |          26 | EST1G07 | 2026-11-24 08:45:00 | 2026-11-24 10:00:00 |      75 |              2 |       15.0 |         30.0 |
-- |          27 | EST2F14 | 2026-11-24 09:00:00 | 2026-11-24 11:00:00 |     120 |              2 |       15.0 |         30.0 |
-- +-------------+---------+---------------------+---------------------+---------+----------------+------------+--------------+

-- ------------------------------------------------------------
-- Consulta 15 (RN07) - Classificar cada estadia como rotativa ou de
-- mensalista (veículo com contrato vigente na data da entrada).
-- ------------------------------------------------------------
SELECT e.cod_estadia,
       e.placa,
       e.data_hora_entrada,
       CASE WHEN EXISTS (SELECT 1
                           FROM contrato c
                          WHERE c.placa = e.placa
                            AND date(e.data_hora_entrada) BETWEEN c.data_inicio AND c.data_fim)
            THEN 'Mensalista'
            ELSE 'Rotativa'
       END AS tipo_estadia
FROM estadia e
ORDER BY e.cod_estadia;
-- Resultado (31 linhas):
-- +-------------+---------+---------------------+--------------+
-- | cod_estadia |  placa  |  data_hora_entrada  | tipo_estadia |
-- +-------------+---------+---------------------+--------------+
-- |           1 | EST2A09 | 2024-03-05 08:00:00 | Rotativa     |
-- |           2 | EST2B10 | 2024-03-05 08:15:00 | Rotativa     |
-- |           3 | EST1A01 | 2024-03-05 08:30:00 | Mensalista   |
-- |           4 | EST1D04 | 2024-03-05 09:00:00 | Rotativa     |
-- |           5 | EST2C11 | 2024-03-05 13:00:00 | Rotativa     |
-- |           6 | EST1A01 | 2026-11-20 07:50:00 | Mensalista   |
-- |           7 | EST1B02 | 2026-11-20 08:00:00 | Mensalista   |
-- |           8 | EST2D12 | 2026-11-20 08:30:00 | Rotativa     |
-- |           9 | EST2E13 | 2026-11-20 09:10:00 | Rotativa     |
-- |          10 | EST1F06 | 2026-11-20 10:00:00 | Rotativa     |
-- |          11 | EST2F14 | 2026-11-20 12:00:00 | Rotativa     |
-- |          12 | EST2G15 | 2026-11-20 14:00:00 | Rotativa     |
-- |          13 | EST1G07 | 2026-11-20 15:00:00 | Rotativa     |
-- |          14 | EST2A09 | 2026-11-20 18:00:00 | Rotativa     |
-- |          15 | EST1B02 | 2026-11-23 07:45:00 | Mensalista   |
-- |          16 | EST1C03 | 2026-11-23 08:10:00 | Mensalista   |
-- |          17 | EST1D04 | 2026-11-23 08:20:00 | Rotativa     |
-- |          18 | EST1H08 | 2026-11-23 09:30:00 | Rotativa     |
-- |          19 | EST2B10 | 2026-11-23 10:00:00 | Rotativa     |
-- |          20 | EST2C11 | 2026-11-23 11:00:00 | Rotativa     |
-- |          21 | EST1E05 | 2026-11-23 13:00:00 | Rotativa     |
-- |          22 | EST2D12 | 2026-11-23 16:00:00 | Rotativa     |
-- |          23 | EST1F06 | 2026-11-23 18:00:00 | Rotativa     |
-- |          24 | EST1A01 | 2026-11-24 07:40:00 | Mensalista   |
-- |          25 | EST2E13 | 2026-11-24 08:00:00 | Rotativa     |
-- |          26 | EST1G07 | 2026-11-24 08:45:00 | Rotativa     |
-- |          27 | EST2F14 | 2026-11-24 09:00:00 | Rotativa     |
-- |          28 | EST1B02 | 2026-11-24 08:05:00 | Mensalista   |
-- |          29 | EST1C03 | 2026-11-24 08:30:00 | Mensalista   |
-- |          30 | EST2G15 | 2026-11-24 10:15:00 | Rotativa     |
-- |          31 | EST1D04 | 2026-11-24 11:00:00 | Rotativa     |
-- +-------------+---------+---------------------+--------------+

-- ------------------------------------------------------------
-- Consulta 16 (RN05) - Auditoria: quais placas têm mais de uma estadia
-- em aberto? (deve retornar vazio)
-- ------------------------------------------------------------
SELECT e.placa,
       COUNT(*) AS estadias_em_aberto
FROM estadia e
WHERE e.data_hora_saida IS NULL
GROUP BY e.placa
HAVING COUNT(*) > 1;
-- Resultado: nenhuma linha (vazio, como esperado).

-- ------------------------------------------------------------
-- Consulta 17 (RN14) - Auditoria: quais contratos do mesmo veículo têm
-- períodos sobrepostos? (deve retornar vazio)
-- [a,b] e [c,d] se sobrepõem quando a <= d e c <= b.
-- ------------------------------------------------------------
SELECT c1.placa,
       c1.cod_contrato AS contrato_a,
       c1.data_inicio  AS inicio_a,
       c1.data_fim     AS fim_a,
       c2.cod_contrato AS contrato_b,
       c2.data_inicio  AS inicio_b,
       c2.data_fim     AS fim_b
FROM contrato c1
JOIN contrato c2
  ON  c2.placa        = c1.placa
  AND c2.cod_contrato > c1.cod_contrato
  AND c1.data_inicio <= c2.data_fim
  AND c2.data_inicio <= c1.data_fim
ORDER BY c1.placa, c1.cod_contrato;
-- Resultado: nenhuma linha (vazio, como esperado).
