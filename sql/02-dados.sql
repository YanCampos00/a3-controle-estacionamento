-- ============================================================
-- 02-DADOS: dados de teste (todos fictícios)
-- Executar logo após 00-base-fornecida.sql e 01-schema.sql.
--
-- Datas usadas nas estadias: 05/03/2024, 20/11/2026, 23/11/2026 e
-- 24/11/2026. As estadias em aberto entraram em 24/11/2026.
-- Os valores dos pagamentos seguem a RN08 (tarifa vigente na data da
-- entrada x horas, fração conta como hora cheia) e batem com a consulta 14.
-- ============================================================

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------------
-- Estacionamento (1 registro, capacidade 80)
-- ------------------------------------------------------------
INSERT INTO estacionamento
  (cod_estacionamento, nome, logradouro, numero, bairro, cidade, uf, cep, capacidade)
VALUES
  (1, 'Estacionamento Vaga Certa', 'Rua das Garagens Fictícias', '100',
   'Butantã', 'São Paulo', 'SP', '05500-000', 80);

-- ------------------------------------------------------------
-- Funcionários (3)
-- ------------------------------------------------------------
INSERT INTO funcionario (cod_funcionario, nome, matricula) VALUES
  (1, 'Carlos Henrique Prado',  'F001'),
  (2, 'Juliana Matos Ribeiro',  'F002'),
  (3, 'Rafael Nogueira Lima',   'F003');

-- ------------------------------------------------------------
-- Clientes (5) e telefones (multivalorado)
-- ------------------------------------------------------------
INSERT INTO cliente (cod_cliente, nome, cpf, email) VALUES
  (1, 'Ana Lúcia Ferraz',      '00000000101', 'ana.ferraz@exemplo.com'),
  (2, 'Bruno César Tavares',   '00000000202', 'bruno.tavares@exemplo.com'),
  (3, 'Camila Duarte Rocha',   '00000000303', 'camila.rocha@exemplo.com'),
  (4, 'Diego Fontes Barreto',  '00000000404', NULL),
  (5, 'Elisa Moreira Campos',  '00000000505', 'elisa.campos@exemplo.com');

INSERT INTO telefone_cliente (cod_cliente, telefone) VALUES
  (1, '(11) 90000-0101'),
  (1, '(11) 3000-0101'),
  (2, '(11) 90000-0202'),
  (3, '(11) 90000-0303'),
  (4, '(11) 90000-0404'),
  (4, '(11) 3000-0404'),
  (5, '(11) 90000-0505');

-- ------------------------------------------------------------
-- Veículos (15): 15 modelos de 11 marcas; 7 sem cliente
-- ------------------------------------------------------------
INSERT INTO veiculo (placa, cod_modelo, cod_cliente) VALUES
  ('EST1A01',  1, 1),     -- Gol (Volkswagen)        mensalista
  ('EST1B02', 15, 2),     -- Onix (Chevrolet)        mensalista
  ('EST1C03', 35, 3),     -- Corolla (Toyota)        mensalista
  ('EST1D04', 44, 4),     -- HB20 (Hyundai)          cliente sem contrato
  ('EST1E05', 54, 5),     -- Compass (Jeep)          cliente sem contrato
  ('EST1F06',  9, 1),     -- Argo (Fiat)             2º carro da cliente 1, sem contrato
  ('EST1G07', 41, 3),     -- Civic (Honda)           2º carro da cliente 3, sem contrato
  ('EST1H08', 28, 4),     -- Sandero (Renault)       2º carro do cliente 4
  ('EST2A09', 51, NULL),  -- Kicks (Nissan)          avulso
  ('EST2B10', 13, NULL),  -- Strada (Fiat)           avulso
  ('EST2C11',  4, NULL),  -- T-Cross (Volkswagen)    avulso
  ('EST2D12', 18, NULL),  -- Tracker (Chevrolet)     avulso
  ('EST2E13', 56, NULL),  -- 208 (Peugeot)           avulso
  ('EST2F14', 70, NULL),  -- X1 (BMW)                avulso
  ('EST2G15', 46, NULL);  -- Creta (Hyundai)         avulso

-- ------------------------------------------------------------
-- Tarifas (3 vigências; a de 01/01/2024 vale em 05/03/2024)
-- ------------------------------------------------------------
INSERT INTO tarifa (cod_tarifa, inicio_vigencia, valor_hora) VALUES
  (1, '2024-01-01', 10.00),
  (2, '2025-01-01', 12.00),
  (3, '2026-01-01', 15.00);

-- ------------------------------------------------------------
-- Lojas conveniadas (3; a loja 3 não tem estadias)
-- ------------------------------------------------------------
INSERT INTO loja_conveniada (cod_loja, nome) VALUES
  (1, 'Farmácia Bem-Estar'),
  (2, 'Padaria Pão Dourado'),
  (3, 'Livraria Página Nova');

-- ------------------------------------------------------------
-- Contratos (4, de 3 clientes diferentes; o contrato 1 já terminou)
-- Contratos 1 e 4 são do mesmo veículo, sem sobreposição (RN14).
-- ------------------------------------------------------------
INSERT INTO contrato (cod_contrato, cod_cliente, placa, data_inicio, data_fim, valor_mensal) VALUES
  (1, 1, 'EST1A01', '2024-01-01', '2024-12-31', 250.00),
  (2, 2, 'EST1B02', '2026-01-01', '2026-12-31', 320.00),
  (3, 3, 'EST1C03', '2026-06-01', '2027-05-31', 350.00),
  (4, 1, 'EST1A01', '2026-03-01', '2027-02-28', 340.00);

-- ------------------------------------------------------------
-- Mensalidades (8: 5 pagas, 3 pendentes)
-- ------------------------------------------------------------
INSERT INTO mensalidade (cod_contrato, ano, mes, data_vencimento, data_pagamento) VALUES
  (1, 2024,  3, '2024-03-10', '2024-03-08'),
  (2, 2026,  9, '2026-09-10', '2026-09-09'),
  (2, 2026, 10, '2026-10-10', '2026-10-10'),
  (2, 2026, 11, '2026-11-10', NULL),
  (3, 2026, 10, '2026-10-05', '2026-10-03'),
  (3, 2026, 11, '2026-11-05', NULL),
  (4, 2026, 10, '2026-10-15', '2026-10-14'),
  (4, 2026, 11, '2026-11-15', NULL);

-- ------------------------------------------------------------
-- Estadias (31) em 4 dias
--   mensalistas: 3, 6, 7, 15, 16, 24, 28, 29
--   em aberto:   28, 29, 30, 31
--   com loja:    1, 4, 8, 10, 12, 17, 18, 21, 25, 30
-- ------------------------------------------------------------
INSERT INTO estadia (cod_estadia, placa, cod_funcionario, data_hora_entrada, data_hora_saida, cod_loja) VALUES
  -- 05/03/2024
  ( 1, 'EST2A09', 1, '2024-03-05 08:00:00', '2024-03-05 10:30:00', 1),     -- 2h30
  ( 2, 'EST2B10', 1, '2024-03-05 08:15:00', '2024-03-05 09:15:00', NULL),  -- 1h
  ( 3, 'EST1A01', 2, '2024-03-05 08:30:00', '2024-03-05 18:00:00', NULL),  -- mensalista (contrato 1)
  ( 4, 'EST1D04', 2, '2024-03-05 09:00:00', '2024-03-05 11:45:00', 2),     -- 2h45
  ( 5, 'EST2C11', 1, '2024-03-05 13:00:00', '2024-03-05 13:20:00', NULL),  -- 20min
  -- 20/11/2026
  ( 6, 'EST1A01', 1, '2026-11-20 07:50:00', '2026-11-20 17:30:00', NULL),  -- mensalista (contrato 4)
  ( 7, 'EST1B02', 1, '2026-11-20 08:00:00', '2026-11-20 18:10:00', NULL),  -- mensalista (contrato 2)
  ( 8, 'EST2D12', 2, '2026-11-20 08:30:00', '2026-11-20 10:00:00', 1),     -- 1h30
  ( 9, 'EST2E13', 2, '2026-11-20 09:10:00', '2026-11-20 12:10:00', NULL),  -- 3h
  (10, 'EST1F06', 3, '2026-11-20 10:00:00', '2026-11-20 11:40:00', 2),     -- 1h40
  (11, 'EST2F14', 3, '2026-11-20 12:00:00', '2026-11-20 16:45:00', NULL),  -- 4h45
  (12, 'EST2G15', 1, '2026-11-20 14:00:00', '2026-11-20 14:50:00', 1),     -- 50min
  (13, 'EST1G07', 2, '2026-11-20 15:00:00', '2026-11-20 19:30:00', NULL),  -- 4h30
  (14, 'EST2A09', 3, '2026-11-20 18:00:00', '2026-11-20 20:05:00', NULL),  -- 2h05
  -- 23/11/2026
  (15, 'EST1B02', 1, '2026-11-23 07:45:00', '2026-11-23 17:50:00', NULL),  -- mensalista (contrato 2)
  (16, 'EST1C03', 1, '2026-11-23 08:10:00', '2026-11-23 18:30:00', NULL),  -- mensalista (contrato 3)
  (17, 'EST1D04', 2, '2026-11-23 08:20:00', '2026-11-23 09:00:00', 2),     -- 40min
  (18, 'EST1H08', 2, '2026-11-23 09:30:00', '2026-11-23 12:00:00', 1),     -- 2h30
  (19, 'EST2B10', 3, '2026-11-23 10:00:00', '2026-11-23 13:15:00', NULL),  -- 3h15
  (20, 'EST2C11', 3, '2026-11-23 11:00:00', '2026-11-23 12:00:00', NULL),  -- 1h
  (21, 'EST1E05', 1, '2026-11-23 13:00:00', '2026-11-23 15:30:00', 2),     -- 2h30
  (22, 'EST2D12', 2, '2026-11-23 16:00:00', '2026-11-23 17:10:00', NULL),  -- 1h10
  (23, 'EST1F06', 2, '2026-11-23 18:00:00', '2026-11-23 22:00:00', NULL),  -- 4h
  -- 24/11/2026
  (24, 'EST1A01', 1, '2026-11-24 07:40:00', '2026-11-24 17:20:00', NULL),  -- mensalista (contrato 4)
  (25, 'EST2E13', 1, '2026-11-24 08:00:00', '2026-11-24 09:30:00', 1),     -- 1h30
  (26, 'EST1G07', 2, '2026-11-24 08:45:00', '2026-11-24 10:00:00', NULL),  -- 1h15
  (27, 'EST2F14', 2, '2026-11-24 09:00:00', '2026-11-24 11:00:00', NULL),  -- 2h
  (28, 'EST1B02', 1, '2026-11-24 08:05:00', NULL, NULL),                   -- aberta, mensalista
  (29, 'EST1C03', 3, '2026-11-24 08:30:00', NULL, NULL),                   -- aberta, mensalista
  (30, 'EST2G15', 3, '2026-11-24 10:15:00', NULL, 2),                      -- aberta, rotativa
  (31, 'EST1D04', 1, '2026-11-24 11:00:00', NULL, NULL);                   -- aberta, rotativa

-- ------------------------------------------------------------
-- Pagamentos (21 = uma por estadia rotativa encerrada; 4 formas)
-- valor = tarifa vigente na entrada x horas arredondadas para cima
-- ------------------------------------------------------------
INSERT INTO pagamento (cod_pagamento, cod_estadia, cod_funcionario, forma, valor, data_hora) VALUES
  ( 1,  1, 1, 'Dinheiro', 30.00, '2024-03-05 10:30:00'),  -- 3h x 10
  ( 2,  2, 1, 'Débito',   10.00, '2024-03-05 09:15:00'),  -- 1h x 10
  ( 3,  4, 2, 'Crédito',  30.00, '2024-03-05 11:45:00'),  -- 3h x 10
  ( 4,  5, 1, 'PIX',      10.00, '2024-03-05 13:20:00'),  -- 1h x 10
  ( 5,  8, 2, 'Dinheiro', 30.00, '2026-11-20 10:00:00'),  -- 2h x 15
  ( 6,  9, 2, 'Débito',   45.00, '2026-11-20 12:10:00'),  -- 3h x 15
  ( 7, 10, 3, 'Crédito',  30.00, '2026-11-20 11:40:00'),  -- 2h x 15
  ( 8, 11, 3, 'PIX',      75.00, '2026-11-20 16:45:00'),  -- 5h x 15
  ( 9, 12, 1, 'Dinheiro', 15.00, '2026-11-20 14:50:00'),  -- 1h x 15
  (10, 13, 2, 'Débito',   75.00, '2026-11-20 19:30:00'),  -- 5h x 15
  (11, 14, 3, 'Crédito',  45.00, '2026-11-20 20:05:00'),  -- 3h x 15
  (12, 17, 2, 'PIX',      15.00, '2026-11-23 09:00:00'),  -- 1h x 15
  (13, 18, 2, 'Dinheiro', 45.00, '2026-11-23 12:00:00'),  -- 3h x 15
  (14, 19, 3, 'Débito',   60.00, '2026-11-23 13:15:00'),  -- 4h x 15
  (15, 20, 3, 'Crédito',  15.00, '2026-11-23 12:00:00'),  -- 1h x 15
  (16, 21, 1, 'PIX',      45.00, '2026-11-23 15:30:00'),  -- 3h x 15
  (17, 22, 2, 'Dinheiro', 30.00, '2026-11-23 17:10:00'),  -- 2h x 15
  (18, 23, 2, 'Débito',   60.00, '2026-11-23 22:00:00'),  -- 4h x 15
  (19, 25, 1, 'Crédito',  30.00, '2026-11-24 09:30:00'),  -- 2h x 15
  (20, 26, 2, 'PIX',      30.00, '2026-11-24 10:00:00'),  -- 2h x 15
  (21, 27, 2, 'Dinheiro', 30.00, '2026-11-24 11:00:00');  -- 2h x 15

-- ------------------------------------------------------------
-- Tipos de ocorrência (4) e ocorrências (5, de 4 tipos)
-- ------------------------------------------------------------
INSERT INTO tipo_ocorrencia (cod_tipo, nome) VALUES
  (1, 'Perda de ticket'),
  (2, 'Reclamação'),
  (3, 'Objeto esquecido'),
  (4, 'Estacionamento irregular');

INSERT INTO ocorrencia (cod_ocorrencia, data_hora, cod_tipo, descricao, cod_estadia, cod_funcionario) VALUES
  (1, '2024-03-05 10:25:00', 1, 'Motorista perdeu o ticket; saída liberada após conferência da placa.', 1, 1),
  (2, '2026-11-20 12:15:00', 3, 'Guarda-chuva deixado no balcão; devolvido ao motorista.', 9, 2),
  (3, '2026-11-20 19:25:00', 2, 'Motorista reclamou da fila na saída.', 13, 2),
  (4, '2026-11-23 11:50:00', 1, 'Ticket ilegível; saída liberada após conferência da placa.', 18, 2),
  (5, '2026-11-24 10:30:00', 4, 'Veículo estacionado ocupando duas vagas; motorista orientado.', 30, 3);
