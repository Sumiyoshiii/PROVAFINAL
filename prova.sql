
CREATE TABLE jogadores (
    id_jogador SERIAL PRIMARY KEY,
    nickname VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    status VARCHAR(15) NOT NULL CHECK (status IN ('ATIVO', 'INATIVO', 'BANIDO')),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE modalidades (
    id_modalidade SERIAL PRIMARY KEY,
    nome VARCHAR(80) NOT NULL UNIQUE,
    categoria VARCHAR(50) NOT NULL,
    descricao TEXT
);

CREATE TABLE torneios (
    id_torneio SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    id_modalidade INT NOT NULL REFERENCES modalidades(id_modalidade),
    data_inicio DATE NOT NULL,
    data_fim DATE NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('INSCRICOES', 'EM_ANDAMENTO', 'FINALIZADO')),
    CHECK (data_fim >= data_inicio)
);

CREATE TABLE partidas (
    id_partida SERIAL PRIMARY KEY,
    titulo VARCHAR(100) NOT NULL,
    id_jogador INT NOT NULL REFERENCES jogadores(id_jogador),
    id_torneio INT NOT NULL REFERENCES torneios(id_torneio),
    data_agendamento TIMESTAMP NOT NULL,
    data_criacao TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('AGENDADA', 'EM_ANDAMENTO', 'FINALIZADA', 'CANCELADA'))
);

CREATE TABLE historico_partidas (
    id_historico SERIAL PRIMARY KEY,
    id_partida INT NOT NULL REFERENCES partidas(id_partida),
    id_jogador INT NOT NULL REFERENCES jogadores(id_jogador),
    acao VARCHAR(100) NOT NULL,
    data_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE inscricoes (
    id_inscricao SERIAL PRIMARY KEY,
    id_jogador INT NOT NULL REFERENCES jogadores(id_jogador),
    id_torneio INT NOT NULL REFERENCES torneios(id_torneio),
    data_inscricao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL CHECK (status IN ('CONFIRMADA', 'PENDENTE', 'CANCELADA')),
    UNIQUE (id_jogador, id_torneio)
);


INSERT INTO jogadores (nickname, email, senha, status) VALUES
('ShadowPeludo', 'shado@gmail.com', 'pel0s', 'ATIVO'),
('NinjaTilaskavara', 'tilaskavare@gmail.com', 'v4r1nha', 'ATIVO'),
('DarkWolfart', 'wolfart@gmail.com', 'woofw00f', 'ATIVO'),
('opositevanilla', 'onilla@gmail.com', 'hatenilla', 'BANIDO');


INSERT INTO modalidades (nome, categoria, descricao) VALUES
('League of Legends', 'MOBA', 'Jogo competitivo em equipes'),
('Counter-Strike 2', 'FPS', 'Jogo de tiro em primeira pessoa'),
('Valorant', 'FPS', 'Jogo tático competitivo');


INSERT INTO torneios (nome, id_modalidade, data_inicio, data_fim, status) VALUES
('Campeonato LOL', 1, '2026-12-01', '2026-12-10', 'INSCRICOES'),
('Copa CS', 2, '2026-12-05', '2026-12-15', 'INSCRICOES'),
('Torneio Vavazinho', 3, '2026-12-10', '2026-12-20', 'INSCRICOES');


INSERT INTO inscricoes (id_jogador, id_torneio, status) VALUES
(1, 1, 'CONFIRMADA'),
(2, 2, 'CONFIRMADA'),
(3, 3, 'CONFIRMADA');


CREATE OR REPLACE FUNCTION validar_partida()
RETURNS TRIGGER AS $$
BEGIN
    IF (SELECT status FROM jogadores
        WHERE id_jogador = NEW.id_jogador) <> 'ATIVO' THEN

        RAISE EXCEPTION 'Jogador não está ativo!';
    END IF;

    NEW.data_criacao = CURRENT_TIMESTAMP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_partida
BEFORE INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION validar_partida();


CREATE OR REPLACE FUNCTION registrar_historico()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historico_partidas
    (id_partida, id_jogador, acao)
    VALUES
    (NEW.id_partida, NEW.id_jogador, 'Partida criada');

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_historico_partida
AFTER INSERT ON partidas
FOR EACH ROW
EXECUTE FUNCTION registrar_historico();


INSERT INTO partidas (titulo, id_jogador, id_torneio, data_agendamento, status) VALUES
('ShadowX vs onilla', 1, 1, '2026-12-02 14:00:00', 'AGENDADA'),
('NinjaPro vs samucagames', 2, 2, '2026-12-06 16:00:00', 'AGENDADA'),
('DarkWolf vs lobopidao', 3, 3, '2026-12-11 18:00:00', 'AGENDADA');


CREATE OR REPLACE FUNCTION fn_buscar_jogadores(termo TEXT)
RETURNS TABLE (
    id_jogador INT,
    nickname VARCHAR(50),
    email VARCHAR(100),
    status VARCHAR(15)
) AS $$
BEGIN
    RETURN QUERY
    SELECT j.id_jogador, j.nickname, j.email, j.status
    FROM jogadores j
    WHERE j.nickname ILIKE '%' || termo || '%'
    OR j.email ILIKE '%' || termo || '%';
END;
$$ LANGUAGE plpgsql;


CREATE VIEW vw_painel_principal AS
SELECT
    jogadores.nickname,
    partidas.titulo AS confronto,
    modalidades.categoria,
    partidas.data_agendamento,
    partidas.status
FROM partidas
INNER JOIN jogadores
ON partidas.id_jogador = jogadores.id_jogador
INNER JOIN torneios
ON partidas.id_torneio = torneios.id_torneio
INNER JOIN modalidades
ON torneios.id_modalidade = modalidades.id_modalidade;


CREATE VIEW vw_cronograma_partidas AS
SELECT
    partidas.titulo AS confronto,
    jogadores.nickname,
    modalidades.nome AS modalidade,
    partidas.data_agendamento,
    partidas.status,
    partidas.data_agendamento::DATE - CURRENT_DATE AS dias_restantes
FROM partidas
INNER JOIN jogadores
ON partidas.id_jogador = jogadores.id_jogador
INNER JOIN torneios
ON partidas.id_torneio = torneios.id_torneio
INNER JOIN modalidades
ON torneios.id_modalidade = modalidades.id_modalidade
ORDER BY partidas.data_agendamento ASC;

SELECT * FROM jogadores;

SELECT * FROM modalidades;

SELECT * FROM torneios;

SELECT * FROM inscricoes;

SELECT * FROM partidas;

SELECT * FROM historico_partidas;

SELECT * FROM vw_painel_principal;

SELECT * FROM vw_cronograma_partidas;

SELECT * FROM fn_buscar_jogadores('ShadowPeludo');
