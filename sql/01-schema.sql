-- ============================================================
-- 01-SCHEMA: modelo físico do Controle de Estacionamento (SQLite)
--
-- Pré-requisito: executar antes o 00-base-fornecida.sql (marca, modelo).
-- Execute num banco NOVO (vazio): o 00 apaga e recria marca/modelo,
-- o que falharia se as tabelas deste script já referenciassem modelo.
--
-- Tabelas criadas na ordem das dependências:
--   estacionamento, funcionario, cliente, telefone_cliente, veiculo,
--   tarifa, loja_conveniada, contrato, mensalidade, estadia,
--   pagamento, tipo_ocorrencia, ocorrencia
--
-- Convenções:
--   * datas: TEXT 'AAAA-MM-DD'; data e hora: TEXT 'AAAA-MM-DD HH:MM:SS'
--     (formato aceito pelas funções date/datetime/julianday do SQLite);
--   * valores em reais: REAL com 2 casas decimais.
-- ============================================================

PRAGMA foreign_keys = ON;

-- Permite reexecutar o script apagando antes as tabelas do grupo
-- (ordem inversa das dependências). marca e modelo não são tocadas.
DROP TABLE IF EXISTS ocorrencia;
DROP TABLE IF EXISTS tipo_ocorrencia;
DROP TABLE IF EXISTS pagamento;
DROP TABLE IF EXISTS estadia;
DROP TABLE IF EXISTS mensalidade;
DROP TABLE IF EXISTS contrato;
DROP TABLE IF EXISTS loja_conveniada;
DROP TABLE IF EXISTS tarifa;
DROP TABLE IF EXISTS veiculo;
DROP TABLE IF EXISTS telefone_cliente;
DROP TABLE IF EXISTS cliente;
DROP TABLE IF EXISTS funcionario;
DROP TABLE IF EXISTS estacionamento;

-- ------------------------------------------------------------
-- RN03: dados do estacionamento e capacidade máxima.
-- Uma única unidade (várias unidades estão fora do escopo):
-- o CHECK na chave impede uma segunda linha.
-- O atributo composto "endereço" do conceitual vira 6 colunas.
-- ------------------------------------------------------------
CREATE TABLE estacionamento (
  cod_estacionamento INTEGER PRIMARY KEY CHECK (cod_estacionamento = 1),
  nome        TEXT    NOT NULL,
  logradouro  TEXT    NOT NULL,
  numero      TEXT    NOT NULL,
  bairro      TEXT    NOT NULL,
  cidade      TEXT    NOT NULL,
  uf          TEXT    NOT NULL CHECK (length(uf) = 2 AND uf = upper(uf)),
  cep         TEXT    NOT NULL CHECK (cep GLOB '[0-9][0-9][0-9][0-9][0-9]-[0-9][0-9][0-9]'),
  capacidade  INTEGER NOT NULL CHECK (capacidade > 0)
);

-- ------------------------------------------------------------
-- Funcionários: cadastro simples, sem turnos.
-- ------------------------------------------------------------
CREATE TABLE funcionario (
  cod_funcionario INTEGER PRIMARY KEY,
  nome            TEXT NOT NULL,
  matricula       TEXT NOT NULL UNIQUE
);

-- ------------------------------------------------------------
-- Clientes (mensalistas ou não). CPF só com dígitos.
-- ------------------------------------------------------------
CREATE TABLE cliente (
  cod_cliente INTEGER PRIMARY KEY,
  nome        TEXT NOT NULL,
  cpf         TEXT NOT NULL UNIQUE
                CHECK (length(cpf) = 11 AND cpf NOT GLOB '*[^0-9]*'),
  email       TEXT UNIQUE CHECK (email IS NULL OR email LIKE '%_@_%._%')
);

-- Atributo multivalorado "telefones" do conceitual.
CREATE TABLE telefone_cliente (
  cod_cliente INTEGER NOT NULL,
  telefone    TEXT    NOT NULL,
  PRIMARY KEY (cod_cliente, telefone),
  FOREIGN KEY (cod_cliente) REFERENCES cliente (cod_cliente) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- RN01/RN02: veículo identificado pela placa, com modelo da base
-- fornecida; cliente opcional (NULL = veículo avulso).
-- Placa no padrão antigo (AAA9999) ou Mercosul (AAA9A99).
-- ------------------------------------------------------------
CREATE TABLE veiculo (
  placa       TEXT    PRIMARY KEY
                CHECK (placa GLOB '[A-Z][A-Z][A-Z][0-9][A-Z0-9][0-9][0-9]'),
  cod_modelo  INTEGER NOT NULL,
  cod_cliente INTEGER,
  FOREIGN KEY (cod_modelo)  REFERENCES modelo (cod_modelo),
  FOREIGN KEY (cod_cliente) REFERENCES cliente (cod_cliente)
);

-- ------------------------------------------------------------
-- RN08/RN09: tarifa única por hora, com histórico.
-- Cada tarifa vale a partir de inicio_vigencia até a véspera do início
-- da tarifa seguinte (ver docs/decisoes.md, D05).
-- ------------------------------------------------------------
CREATE TABLE tarifa (
  cod_tarifa      INTEGER PRIMARY KEY,
  inicio_vigencia TEXT NOT NULL UNIQUE
                    CHECK (inicio_vigencia = date(inicio_vigencia)),
  valor_hora      REAL NOT NULL CHECK (valor_hora > 0)
);

-- ------------------------------------------------------------
-- RN11: lojas conveniadas.
-- ------------------------------------------------------------
CREATE TABLE loja_conveniada (
  cod_loja INTEGER PRIMARY KEY,
  nome     TEXT    NOT NULL UNIQUE,
  ativa    INTEGER NOT NULL DEFAULT 1 CHECK (ativa IN (0, 1))
);

-- ------------------------------------------------------------
-- RN12: contrato de mensalista (titular, um veículo, vigência, valor).
-- ------------------------------------------------------------
CREATE TABLE contrato (
  cod_contrato INTEGER PRIMARY KEY,
  cod_cliente  INTEGER NOT NULL,
  placa        TEXT    NOT NULL,
  data_inicio  TEXT    NOT NULL CHECK (data_inicio = date(data_inicio)),
  data_fim     TEXT    NOT NULL CHECK (data_fim = date(data_fim)),
  valor_mensal REAL    NOT NULL CHECK (valor_mensal > 0),
  CHECK (data_fim > data_inicio),
  FOREIGN KEY (cod_cliente) REFERENCES cliente (cod_cliente),
  FOREIGN KEY (placa)       REFERENCES veiculo (placa)
);

-- ------------------------------------------------------------
-- RN13: mensalidade por competência (entidade fraca de contrato).
-- O atributo composto "competência" vira (ano, mes).
-- data_pagamento NULL = mensalidade pendente.
-- ------------------------------------------------------------
CREATE TABLE mensalidade (
  cod_contrato    INTEGER NOT NULL,
  ano             INTEGER NOT NULL CHECK (ano BETWEEN 2000 AND 2100),
  mes             INTEGER NOT NULL CHECK (mes BETWEEN 1 AND 12),
  data_vencimento TEXT    NOT NULL CHECK (data_vencimento = date(data_vencimento)),
  data_pagamento  TEXT    CHECK (data_pagamento IS NULL
                                 OR data_pagamento = date(data_pagamento)),
  PRIMARY KEY (cod_contrato, ano, mes),
  FOREIGN KEY (cod_contrato) REFERENCES contrato (cod_contrato) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- RN06/RN11: estadia (entrada, saída posterior, loja opcional).
-- O tipo (rotativa/mensalista, RN07) é derivado por consulta.
-- ------------------------------------------------------------
CREATE TABLE estadia (
  cod_estadia       INTEGER PRIMARY KEY,
  placa             TEXT    NOT NULL,
  cod_funcionario   INTEGER NOT NULL,
  data_hora_entrada TEXT    NOT NULL DEFAULT (datetime('now', 'localtime')),
  data_hora_saida   TEXT,
  cod_loja          INTEGER,
  CHECK (data_hora_entrada = datetime(data_hora_entrada)),
  CHECK (data_hora_saida IS NULL
         OR (data_hora_saida = datetime(data_hora_saida)
             AND data_hora_saida > data_hora_entrada)),
  FOREIGN KEY (placa)           REFERENCES veiculo (placa),
  FOREIGN KEY (cod_funcionario) REFERENCES funcionario (cod_funcionario),
  FOREIGN KEY (cod_loja)        REFERENCES loja_conveniada (cod_loja)
);

-- ------------------------------------------------------------
-- RN10: um único pagamento por estadia rotativa (UNIQUE em cod_estadia),
-- com uma única forma.
-- ------------------------------------------------------------
CREATE TABLE pagamento (
  cod_pagamento   INTEGER PRIMARY KEY,
  cod_estadia     INTEGER NOT NULL UNIQUE,
  cod_funcionario INTEGER NOT NULL,
  forma           TEXT    NOT NULL
                    CHECK (forma IN ('Dinheiro', 'Débito', 'Crédito', 'PIX')),
  valor           REAL    NOT NULL CHECK (valor > 0),
  data_hora       TEXT    NOT NULL DEFAULT (datetime('now', 'localtime'))
                    CHECK (data_hora = datetime(data_hora)),
  FOREIGN KEY (cod_estadia)     REFERENCES estadia (cod_estadia),
  FOREIGN KEY (cod_funcionario) REFERENCES funcionario (cod_funcionario)
);

-- ------------------------------------------------------------
-- RN15: ocorrências, com tipo em tabela de domínio.
-- ------------------------------------------------------------
CREATE TABLE tipo_ocorrencia (
  cod_tipo INTEGER PRIMARY KEY,
  nome     TEXT NOT NULL UNIQUE
);

CREATE TABLE ocorrencia (
  cod_ocorrencia  INTEGER PRIMARY KEY,
  data_hora       TEXT    NOT NULL CHECK (data_hora = datetime(data_hora)),
  cod_tipo        INTEGER NOT NULL,
  descricao       TEXT    NOT NULL CHECK (length(trim(descricao)) > 0),
  cod_estadia     INTEGER NOT NULL,
  cod_funcionario INTEGER NOT NULL,
  FOREIGN KEY (cod_tipo)        REFERENCES tipo_ocorrencia (cod_tipo),
  FOREIGN KEY (cod_estadia)     REFERENCES estadia (cod_estadia),
  FOREIGN KEY (cod_funcionario) REFERENCES funcionario (cod_funcionario)
);

-- ------------------------------------------------------------
-- Índices
-- ------------------------------------------------------------
-- RN05 garantida pelo banco: no máximo uma estadia em aberto por placa
-- (índice único parcial). A consulta 16 continua auditando a regra.
CREATE UNIQUE INDEX ux_estadia_aberta_por_placa
  ON estadia (placa) WHERE data_hora_saida IS NULL;

CREATE INDEX ix_estadia_placa_entrada ON estadia (placa, data_hora_entrada);
CREATE INDEX ix_estadia_loja          ON estadia (cod_loja);
CREATE INDEX ix_contrato_placa_inicio ON contrato (placa, data_inicio);
CREATE INDEX ix_veiculo_cliente       ON veiculo (cod_cliente);
CREATE INDEX ix_ocorrencia_estadia    ON ocorrencia (cod_estadia);

-- ------------------------------------------------------------
-- RN14 garantida pelo banco: um veículo não pode ter dois contratos
-- com períodos sobrepostos. A consulta 17 continua auditando a regra.
-- Dois intervalos [a,b] e [c,d] se sobrepõem quando a <= d e c <= b.
-- ------------------------------------------------------------
CREATE TRIGGER tg_contrato_sem_sobreposicao_ins
BEFORE INSERT ON contrato
WHEN EXISTS (
  SELECT 1 FROM contrato c
  WHERE c.placa = NEW.placa
    AND NEW.data_inicio <= c.data_fim
    AND c.data_inicio <= NEW.data_fim
)
BEGIN
  SELECT RAISE(ABORT, 'RN14: contrato sobreposto para o mesmo veiculo');
END;

CREATE TRIGGER tg_contrato_sem_sobreposicao_upd
BEFORE UPDATE OF placa, data_inicio, data_fim ON contrato
WHEN EXISTS (
  SELECT 1 FROM contrato c
  WHERE c.placa = NEW.placa
    AND c.cod_contrato <> NEW.cod_contrato
    AND NEW.data_inicio <= c.data_fim
    AND c.data_inicio <= NEW.data_fim
)
BEGIN
  SELECT RAISE(ABORT, 'RN14: contrato sobreposto para o mesmo veiculo');
END;
