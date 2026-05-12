-- Project: Графовая база данных "Spotify-модель"
-- Узлы  (NODE): Listener, Artist, Genre
-- Рёбра (EDGE): Listens, Performs, Recommends

/*
Created: 12.05.2026
Modified: 12.05.2026
Model: Microsoft SQL Server 2022
Database: MS SQL Server 2022
*/

-- ============================================================
-- СОЗДАНИЕ БАЗЫ ДАННЫХ
-- ============================================================

Use master
go

if exists (select 1 from sys.databases where name = 'Spotify')
begin
    alter database Spotify set single_user with rollback immediate;
    drop database Spotify;
end;
go

create database Spotify;
go

use Spotify;
go

-- ============================================================
-- СОЗДАНИЕ ТАБЛИЦ УЗЛОВ (NODE TABLES)
-- ============================================================

-- ------------------------------------------------------------
-- Таблица узлов: Listener (Слушатели)
-- subscription: free | premium | family | student
-- country: страна проживания
-- ------------------------------------------------------------

CREATE TABLE [dbo].[Listener]
(
 [id]               Int            NOT NULL,
 [username]         Nvarchar(50)   COLLATE Cyrillic_General_CI_AS NOT NULL,
 [full_name]        Nvarchar(100)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 [age]              Int            NOT NULL,
 [country]          Nvarchar(50)   COLLATE Cyrillic_General_CI_AS NOT NULL,
 [subscription]     Nvarchar(10)   COLLATE Cyrillic_General_CI_AS DEFAULT (N'free') NOT NULL
                    CHECK ([subscription] = N'free'    OR [subscription] = N'premium'
                        OR [subscription] = N'family'  OR [subscription] = N'student'),
 [registered_date]  Date           NOT NULL
)
AS NODE
ON [PRIMARY]
go

ALTER TABLE [dbo].[Listener] ADD CONSTRAINT [PK_Listener] PRIMARY KEY ([id])
 ON [PRIMARY]
go

-- ------------------------------------------------------------
-- Таблица узлов: Artist (Исполнители)
-- artist_type: solo | band | duo | orchestra
-- status:      active | hiatus | disbanded
-- ------------------------------------------------------------

CREATE TABLE [dbo].[Artist]
(
 [id]           Int            NOT NULL,
 [name]         Nvarchar(100)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 [country]      Nvarchar(50)   COLLATE Cyrillic_General_CI_AS NOT NULL,
 [artist_type]  Nvarchar(15)   COLLATE Cyrillic_General_CI_AS NOT NULL
                CHECK ([artist_type] = N'solo'       OR [artist_type] = N'band'
                    OR [artist_type] = N'duo'        OR [artist_type] = N'orchestra'),
 [monthly_listeners] Bigint    NOT NULL,
 [debut_year]   Int            NOT NULL,
 [status]       Nvarchar(10)   COLLATE Cyrillic_General_CI_AS DEFAULT (N'active') NOT NULL
                CHECK ([status] = N'active' OR [status] = N'hiatus' OR [status] = N'disbanded')
)
AS NODE
ON [PRIMARY]
go

ALTER TABLE [dbo].[Artist] ADD CONSTRAINT [PK_Artist] PRIMARY KEY ([id])
 ON [PRIMARY]
go

-- ------------------------------------------------------------
-- Таблица узлов: Genre (Жанры)
-- mood: energetic | calm | melancholic | happy | aggressive | romantic
-- ------------------------------------------------------------

CREATE TABLE [dbo].[Genre]
(
 [id]          Int            NOT NULL,
 [name]        Nvarchar(50)   COLLATE Cyrillic_General_CI_AS NOT NULL,
 [description] Nvarchar(200)  COLLATE Cyrillic_General_CI_AS NOT NULL,
 [mood]        Nvarchar(15)   COLLATE Cyrillic_General_CI_AS NOT NULL
               CHECK ([mood] = N'energetic'   OR [mood] = N'calm'
                   OR [mood] = N'melancholic' OR [mood] = N'happy'
                   OR [mood] = N'aggressive'  OR [mood] = N'romantic'),
 [bpm_avg]     Int            NOT NULL
)
AS NODE
ON [PRIMARY]
go

ALTER TABLE [dbo].[Genre] ADD CONSTRAINT [PK_Genre] PRIMARY KEY ([id])
 ON [PRIMARY]
go

-- ============================================================
-- СОЗДАНИЕ ТАБЛИЦ РЁБЕР (EDGE TABLES)
-- ============================================================

-- ------------------------------------------------------------
-- Ребро: Listens (Listener -> Artist)
-- Слушатель слушает исполнителя.
-- Однонаправленное: слушатель -> исполнитель.
-- ------------------------------------------------------------

CREATE TABLE [dbo].[Listens]
(
 [total_plays]    Int            NOT NULL,
 [last_played]    Date           NOT NULL,
 [is_following]   Bit            DEFAULT ((0)) NOT NULL
)
AS EDGE
ON [PRIMARY]
go

ALTER TABLE [dbo].[Listens] ADD CONSTRAINT [EC_Listens] CONNECTION (
  [Listener] TO [Artist])
go

-- ------------------------------------------------------------
-- Ребро: Performs (Artist -> Genre)
-- Исполнитель работает в жанре.
-- Однонаправленное: исполнитель -> жанр.
-- ------------------------------------------------------------

CREATE TABLE [dbo].[Performs]
(
 [is_primary]     Bit            DEFAULT ((1)) NOT NULL,
 [since_year]     Int            NOT NULL,
 [influence_pct]  Decimal(5,2)   NOT NULL
                  CHECK ([influence_pct] >= 0 AND [influence_pct] <= 100)
)
AS EDGE
ON [PRIMARY]
go

ALTER TABLE [dbo].[Performs] ADD CONSTRAINT [EC_Performs] CONNECTION (
  [Artist] TO [Genre])
go

-- ------------------------------------------------------------
-- Ребро: Recommends (Listener -> Listener)
-- Слушатель рекомендует другому слушателю (друг другу).
-- Двусторонняя связь реализуется двумя записями.
-- Атрибут: дата рекомендации и рейтинг доверия.
-- ------------------------------------------------------------

CREATE TABLE [dbo].[Recommends]
(
 [rec_date]       Date           NOT NULL,
 [trust_score]    Tinyint        NOT NULL
                  CHECK ([trust_score] >= 1 AND [trust_score] <= 10),
 [message]        Nvarchar(200)  COLLATE Cyrillic_General_CI_AS NULL
)
AS EDGE
ON [PRIMARY]
go

ALTER TABLE [dbo].[Recommends] ADD CONSTRAINT [EC_Recommends] CONNECTION (
  [Listener] TO [Listener])
go

-- ============================================================
-- ЧАСТЬ 3: ЗАПОЛНЕНИЕ ТАБЛИЦ УЗЛОВ
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Данные: Listener (12 слушателей)
-- ------------------------------------------------------------
INSERT INTO Listener (id, username, full_name, age, country, subscription, registered_date)
VALUES
    (1,  N'alex_sounds',   N'Алексей Морозов',      24, N'Россия',    N'premium',  '2020-03-15'),
    (2,  N'marina_v',      N'Марина Волкова',        31, N'Россия',    N'family',   '2019-07-22'),
    (3,  N'dj_pete',       N'Пётр Зайцев',           19, N'Россия',    N'student',  '2023-01-10'),
    (4,  N'kate_music',    N'Екатерина Новикова',    27, N'Беларусь',  N'premium',  '2021-05-18'),
    (5,  N'ivan_bass',     N'Иван Кузнецов',         35, N'Россия',    N'free',     '2018-11-02'),
    (6,  N'olga_pop',      N'Ольга Сидорова',        22, N'Казахстан', N'student',  '2022-09-30'),
    (7,  N'dmitry_rock',   N'Дмитрий Павлов',        29, N'Россия',    N'premium',  '2020-12-05'),
    (8,  N'anna_jazz',     N'Анна Козлова',          44, N'Украина',   N'premium',  '2017-04-14'),
    (9,  N'sergey_beats',  N'Сергей Лебедев',        18, N'Россия',    N'free',     '2024-02-01'),
    (10, N'natasha_soul',  N'Наталья Орлова',        33, N'Россия',    N'family',   '2019-08-19'),
    (11, N'mike_edm',      N'Михаил Фёдоров',        26, N'Россия',    N'premium',  '2021-06-11'),
    (12, N'lena_indie',    N'Елена Белова',           21, N'Беларусь',  N'student',  '2023-03-27');
GO

-- ------------------------------------------------------------
-- 3.2 Данные: Artist (12 исполнителей)
-- ------------------------------------------------------------
INSERT INTO Artist (id, name, country, artist_type, monthly_listeners, debut_year, status)
VALUES
    (1,  N'The Weeknd',        N'Канада',       N'solo',       111000000, 2010, N'active'),
    (2,  N'Imagine Dragons',   N'США',          N'band',        63000000, 2008, N'active'),
    (3,  N'Billie Eilish',     N'США',          N'solo',        79000000, 2015, N'active'),
    (4,  N'Dua Lipa',          N'Великобритания', N'solo',      82000000, 2015, N'active'),
    (5,  N'Kendrick Lamar',    N'США',          N'solo',        53000000, 2003, N'active'),
    (6,  N'Arctic Monkeys',    N'Великобритания', N'band',      26000000, 2002, N'active'),
    (7,  N'Massive Attack',    N'Великобритания', N'band',       6500000, 1988, N'active'),
    (8,  N'Radiohead',         N'Великобритания', N'band',      16000000, 1985, N'hiatus'),
    (9,  N'Calvin Harris',     N'Великобритания', N'solo',      57000000, 2002, N'active'),
    (10, N'Stromae',           N'Бельгия',       N'solo',       11000000, 2009, N'active'),
    (11, N'Linkin Park',       N'США',           N'band',       41000000, 1996, N'active'),
    (12, N'Norah Jones',       N'США',           N'solo',       14000000, 2001, N'active');
GO

-- ------------------------------------------------------------
-- 3.3 Данные: Genre (10 жанров)
-- ------------------------------------------------------------
INSERT INTO Genre (id, name, description, mood, bpm_avg)
VALUES
    (1,  N'R&B',           N'Ритм-н-блюз: вокальные мелодии, современные биты',         N'romantic',    90),
    (2,  N'Alternative Rock', N'Альтернативный рок: экспериментальные гитарные звуки',  N'energetic',  130),
    (3,  N'Indie Pop',     N'Инди-поп: независимые лейблы, мечтательное звучание',       N'happy',      115),
    (4,  N'Pop',           N'Популярная музыка: запоминающиеся мелодии, широкая аудитория', N'happy',   120),
    (5,  N'Hip-Hop',       N'Хип-хоп: рэп, семплы, диджейство',                          N'energetic',  95),
    (6,  N'Rock',          N'Рок: гитары, ударные, живая энергетика',                     N'aggressive', 140),
    (7,  N'Trip-Hop',      N'Трип-хоп: медленный хип-хоп с электронными элементами',     N'melancholic', 80),
    (8,  N'Electronic',    N'Электронная: синтезаторы, семплеры, танцевальные ритмы',     N'energetic',  128),
    (9,  N'Jazz',          N'Джаз: импровизация, сложная гармония, живые инструменты',   N'calm',        70),
    (10, N'Indie Rock',    N'Инди-рок: независимые группы, DIY-эстетика',                N'melancholic', 125);
GO

-- ============================================================
-- ЧАСТЬ 4: ЗАПОЛНЕНИЕ ТАБЛИЦ РЁБЕР
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Listens: Слушатель → Исполнитель
-- ------------------------------------------------------------
-- alex(1):   The Weeknd(1), Dua Lipa(4), Calvin Harris(9)
-- marina(2): Norah Jones(12), Radiohead(8), Massive Attack(7)
-- dj_pete(3): Calvin Harris(9), The Weeknd(1), Linkin Park(11)
-- kate(4):   Billie Eilish(3), Dua Lipa(4), Stromae(10)
-- ivan(5):   Linkin Park(11), Arctic Monkeys(6), Radiohead(8)
-- olga(6):   Dua Lipa(4), The Weeknd(1), Billie Eilish(3)
-- dmitry(7): Arctic Monkeys(6), Radiohead(8), Linkin Park(11)
-- anna(8):   Norah Jones(12), Massive Attack(7), Stromae(10)
-- sergey(9): Kendrick Lamar(5), The Weeknd(1), Calvin Harris(9)
-- natasha(10): Imagine Dragons(2), The Weeknd(1), Dua Lipa(4)
-- mike(11):  Calvin Harris(9), Massive Attack(7), Stromae(10)
-- lena(12):  Arctic Monkeys(6), Billie Eilish(3), Radiohead(8)
-- ------------------------------------------------------------
INSERT INTO Listens ($from_id, $to_id, total_plays, last_played, is_following)
VALUES
    ((SELECT $node_id FROM Listener WHERE id = 1),
     (SELECT $node_id FROM Artist  WHERE id = 1),  1240, '2026-05-10', 1),
    ((SELECT $node_id FROM Listener WHERE id = 1),
     (SELECT $node_id FROM Artist  WHERE id = 4),   870, '2026-05-09', 1),
    ((SELECT $node_id FROM Listener WHERE id = 1),
     (SELECT $node_id FROM Artist  WHERE id = 9),   530, '2026-04-28', 0),

    ((SELECT $node_id FROM Listener WHERE id = 2),
     (SELECT $node_id FROM Artist  WHERE id = 12),  980, '2026-05-11', 1),
    ((SELECT $node_id FROM Listener WHERE id = 2),
     (SELECT $node_id FROM Artist  WHERE id = 8),   640, '2026-05-01', 1),
    ((SELECT $node_id FROM Listener WHERE id = 2),
     (SELECT $node_id FROM Artist  WHERE id = 7),   420, '2026-04-15', 0),

    ((SELECT $node_id FROM Listener WHERE id = 3),
     (SELECT $node_id FROM Artist  WHERE id = 9),  2100, '2026-05-12', 1),
    ((SELECT $node_id FROM Listener WHERE id = 3),
     (SELECT $node_id FROM Artist  WHERE id = 1),   750, '2026-05-08', 1),
    ((SELECT $node_id FROM Listener WHERE id = 3),
     (SELECT $node_id FROM Artist  WHERE id = 11),  310, '2026-04-20', 0),

    ((SELECT $node_id FROM Listener WHERE id = 4),
     (SELECT $node_id FROM Artist  WHERE id = 3),  1560, '2026-05-11', 1),
    ((SELECT $node_id FROM Listener WHERE id = 4),
     (SELECT $node_id FROM Artist  WHERE id = 4),   880, '2026-05-10', 1),
    ((SELECT $node_id FROM Listener WHERE id = 4),
     (SELECT $node_id FROM Artist  WHERE id = 10),  290, '2026-04-05', 0),

    ((SELECT $node_id FROM Listener WHERE id = 5),
     (SELECT $node_id FROM Artist  WHERE id = 11), 3200, '2026-05-12', 1),
    ((SELECT $node_id FROM Listener WHERE id = 5),
     (SELECT $node_id FROM Artist  WHERE id = 6),  1800, '2026-05-09', 1),
    ((SELECT $node_id FROM Listener WHERE id = 5),
     (SELECT $node_id FROM Artist  WHERE id = 8),   920, '2026-05-03', 0),

    ((SELECT $node_id FROM Listener WHERE id = 6),
     (SELECT $node_id FROM Artist  WHERE id = 4),  1100, '2026-05-12', 1),
    ((SELECT $node_id FROM Listener WHERE id = 6),
     (SELECT $node_id FROM Artist  WHERE id = 1),   670, '2026-05-07', 1),
    ((SELECT $node_id FROM Listener WHERE id = 6),
     (SELECT $node_id FROM Artist  WHERE id = 3),   480, '2026-04-30', 0),

    ((SELECT $node_id FROM Listener WHERE id = 7),
     (SELECT $node_id FROM Artist  WHERE id = 6),  2400, '2026-05-12', 1),
    ((SELECT $node_id FROM Listener WHERE id = 7),
     (SELECT $node_id FROM Artist  WHERE id = 8),  1350, '2026-05-10', 1),
    ((SELECT $node_id FROM Listener WHERE id = 7),
     (SELECT $node_id FROM Artist  WHERE id = 11),  760, '2026-05-01', 0),

    ((SELECT $node_id FROM Listener WHERE id = 8),
     (SELECT $node_id FROM Artist  WHERE id = 12), 2800, '2026-05-11', 1),
    ((SELECT $node_id FROM Listener WHERE id = 8),
     (SELECT $node_id FROM Artist  WHERE id = 7),   950, '2026-05-05', 1),
    ((SELECT $node_id FROM Listener WHERE id = 8),
     (SELECT $node_id FROM Artist  WHERE id = 10),  610, '2026-04-22', 1),

    ((SELECT $node_id FROM Listener WHERE id = 9),
     (SELECT $node_id FROM Artist  WHERE id = 5),  1750, '2026-05-12', 1),
    ((SELECT $node_id FROM Listener WHERE id = 9),
     (SELECT $node_id FROM Artist  WHERE id = 1),   990, '2026-05-11', 1),
    ((SELECT $node_id FROM Listener WHERE id = 9),
     (SELECT $node_id FROM Artist  WHERE id = 9),   440, '2026-05-02', 0),

    ((SELECT $node_id FROM Listener WHERE id = 10),
     (SELECT $node_id FROM Artist  WHERE id = 2),  1430, '2026-05-10', 1),
    ((SELECT $node_id FROM Listener WHERE id = 10),
     (SELECT $node_id FROM Artist  WHERE id = 1),   820, '2026-05-08', 1),
    ((SELECT $node_id FROM Listener WHERE id = 10),
     (SELECT $node_id FROM Artist  WHERE id = 4),   560, '2026-04-27', 0),

    ((SELECT $node_id FROM Listener WHERE id = 11),
     (SELECT $node_id FROM Artist  WHERE id = 9),  3500, '2026-05-12', 1),
    ((SELECT $node_id FROM Listener WHERE id = 11),
     (SELECT $node_id FROM Artist  WHERE id = 7),  1200, '2026-05-09', 1),
    ((SELECT $node_id FROM Listener WHERE id = 11),
     (SELECT $node_id FROM Artist  WHERE id = 10),  680, '2026-05-04', 0),

    ((SELECT $node_id FROM Listener WHERE id = 12),
     (SELECT $node_id FROM Artist  WHERE id = 6),  1680, '2026-05-11', 1),
    ((SELECT $node_id FROM Listener WHERE id = 12),
     (SELECT $node_id FROM Artist  WHERE id = 3),   940, '2026-05-07', 1),
    ((SELECT $node_id FROM Listener WHERE id = 12),
     (SELECT $node_id FROM Artist  WHERE id = 8),   510, '2026-04-18', 0);
GO

-- ------------------------------------------------------------
-- 4.2 Performs: Исполнитель → Жанр
-- Каждый исполнитель имеет первичный и (опционально) вторичный жанры.
-- ------------------------------------------------------------
-- The Weeknd(1):      R&B(1) primary, Pop(4) secondary
-- Imagine Dragons(2): Alternative Rock(2) primary, Pop(4) secondary
-- Billie Eilish(3):   Indie Pop(3) primary, Pop(4) secondary
-- Dua Lipa(4):        Pop(4) primary, Electronic(8) secondary
-- Kendrick Lamar(5):  Hip-Hop(5) primary
-- Arctic Monkeys(6):  Indie Rock(10) primary, Rock(6) secondary
-- Massive Attack(7):  Trip-Hop(7) primary
-- Radiohead(8):       Alternative Rock(2) primary, Indie Rock(10) secondary
-- Calvin Harris(9):   Electronic(8) primary
-- Stromae(10):        Electronic(8) primary, Pop(4) secondary
-- Linkin Park(11):    Rock(6) primary, Alternative Rock(2) secondary
-- Norah Jones(12):    Jazz(9) primary, Indie Pop(3) secondary
-- ------------------------------------------------------------
INSERT INTO Performs ($from_id, $to_id, is_primary, since_year, influence_pct)
VALUES
    -- The Weeknd
    ((SELECT $node_id FROM Artist WHERE id = 1),
     (SELECT $node_id FROM Genre  WHERE id = 1),  1, 2010, 70.00),
    ((SELECT $node_id FROM Artist WHERE id = 1),
     (SELECT $node_id FROM Genre  WHERE id = 4),  0, 2015, 30.00),
    -- Imagine Dragons
    ((SELECT $node_id FROM Artist WHERE id = 2),
     (SELECT $node_id FROM Genre  WHERE id = 2),  1, 2008, 65.00),
    ((SELECT $node_id FROM Artist WHERE id = 2),
     (SELECT $node_id FROM Genre  WHERE id = 4),  0, 2012, 35.00),
    -- Billie Eilish
    ((SELECT $node_id FROM Artist WHERE id = 3),
     (SELECT $node_id FROM Genre  WHERE id = 3),  1, 2015, 60.00),
    ((SELECT $node_id FROM Artist WHERE id = 3),
     (SELECT $node_id FROM Genre  WHERE id = 4),  0, 2019, 40.00),
    -- Dua Lipa
    ((SELECT $node_id FROM Artist WHERE id = 4),
     (SELECT $node_id FROM Genre  WHERE id = 4),  1, 2015, 75.00),
    ((SELECT $node_id FROM Artist WHERE id = 4),
     (SELECT $node_id FROM Genre  WHERE id = 8),  0, 2020, 25.00),
    -- Kendrick Lamar
    ((SELECT $node_id FROM Artist WHERE id = 5),
     (SELECT $node_id FROM Genre  WHERE id = 5),  1, 2003, 100.00),
    -- Arctic Monkeys
    ((SELECT $node_id FROM Artist WHERE id = 6),
     (SELECT $node_id FROM Genre  WHERE id = 10), 1, 2002, 65.00),
    ((SELECT $node_id FROM Artist WHERE id = 6),
     (SELECT $node_id FROM Genre  WHERE id = 6),  0, 2006, 35.00),
    -- Massive Attack
    ((SELECT $node_id FROM Artist WHERE id = 7),
     (SELECT $node_id FROM Genre  WHERE id = 7),  1, 1988, 100.00),
    -- Radiohead
    ((SELECT $node_id FROM Artist WHERE id = 8),
     (SELECT $node_id FROM Genre  WHERE id = 2),  1, 1985, 55.00),
    ((SELECT $node_id FROM Artist WHERE id = 8),
     (SELECT $node_id FROM Genre  WHERE id = 10), 0, 1992, 45.00),
    -- Calvin Harris
    ((SELECT $node_id FROM Artist WHERE id = 9),
     (SELECT $node_id FROM Genre  WHERE id = 8),  1, 2002, 100.00),
    -- Stromae
    ((SELECT $node_id FROM Artist WHERE id = 10),
     (SELECT $node_id FROM Genre  WHERE id = 8),  1, 2009, 60.00),
    ((SELECT $node_id FROM Artist WHERE id = 10),
     (SELECT $node_id FROM Genre  WHERE id = 4),  0, 2013, 40.00),
    -- Linkin Park
    ((SELECT $node_id FROM Artist WHERE id = 11),
     (SELECT $node_id FROM Genre  WHERE id = 6),  1, 1996, 60.00),
    ((SELECT $node_id FROM Artist WHERE id = 11),
     (SELECT $node_id FROM Genre  WHERE id = 2),  0, 2003, 40.00),
    -- Norah Jones
    ((SELECT $node_id FROM Artist WHERE id = 12),
     (SELECT $node_id FROM Genre  WHERE id = 9),  1, 2001, 70.00),
    ((SELECT $node_id FROM Artist WHERE id = 12),
     (SELECT $node_id FROM Genre  WHERE id = 3),  0, 2004, 30.00);
GO

-- ------------------------------------------------------------
-- 4.3 Recommends: Слушатель → Слушатель
-- Один слушатель рекомендует другому (направленная связь).
-- Для двусторонней дружбы — две записи.
-- ------------------------------------------------------------
INSERT INTO Recommends ($from_id, $to_id, rec_date, trust_score, message)
VALUES
    -- alex(1) → marina(2): двустороннее знакомство
    ((SELECT $node_id FROM Listener WHERE id = 1),
     (SELECT $node_id FROM Listener WHERE id = 2),
     '2024-06-15', 8, N'Послушай The Weeknd, не пожалеешь!'),
    ((SELECT $node_id FROM Listener WHERE id = 2),
     (SELECT $node_id FROM Listener WHERE id = 1),
     '2024-06-16', 7, N'Советую Radiohead, особенно OK Computer'),
    -- alex(1) → dj_pete(3)
    ((SELECT $node_id FROM Listener WHERE id = 1),
     (SELECT $node_id FROM Listener WHERE id = 3),
     '2025-01-10', 9, N'Зацени Calvin Harris для вечеринки'),
    -- dj_pete(3) → mike(11): оба любят электронику
    ((SELECT $node_id FROM Listener WHERE id = 3),
     (SELECT $node_id FROM Listener WHERE id = 11),
     '2025-03-22', 10, N'Тебе точно понравится Stromae, бомба!'),
    ((SELECT $node_id FROM Listener WHERE id = 11),
     (SELECT $node_id FROM Listener WHERE id = 3),
     '2025-03-25', 9, N'Calvin Harris — маст хэв'),
    -- kate(4) → olga(6)
    ((SELECT $node_id FROM Listener WHERE id = 4),
     (SELECT $node_id FROM Listener WHERE id = 6),
     '2025-02-14', 8, N'Billie Eilish — идеально для учёбы'),
    -- olga(6) → kate(4)
    ((SELECT $node_id FROM Listener WHERE id = 6),
     (SELECT $node_id FROM Listener WHERE id = 4),
     '2025-02-15', 7, N'Dua Lipa — для хорошего настроения'),
    -- ivan(5) → dmitry(7): оба рок-любители
    ((SELECT $node_id FROM Listener WHERE id = 5),
     (SELECT $node_id FROM Listener WHERE id = 7),
     '2024-09-01', 9, N'Линкин Парк лучшие, слушай всё подряд'),
    ((SELECT $node_id FROM Listener WHERE id = 7),
     (SELECT $node_id FROM Listener WHERE id = 5),
     '2024-09-03', 8, N'Arctic Monkeys — шедевр за шедевром'),
    -- anna(8) → marina(2): обе слушают спокойную музыку
    ((SELECT $node_id FROM Listener WHERE id = 8),
     (SELECT $node_id FROM Listener WHERE id = 2),
     '2025-04-05', 7, N'Norah Jones для вечернего чтения — супер'),
    -- natasha(10) → alex(1)
    ((SELECT $node_id FROM Listener WHERE id = 10),
     (SELECT $node_id FROM Listener WHERE id = 1),
     '2025-05-01', 6, N'Imagine Dragons — проверь новый альбом'),
    -- sergey(9) → dj_pete(3)
    ((SELECT $node_id FROM Listener WHERE id = 9),
     (SELECT $node_id FROM Listener WHERE id = 3),
     '2026-01-20', 8, N'Kendrick Lamar — просто послушай'),
    -- lena(12) → dmitry(7)
    ((SELECT $node_id FROM Listener WHERE id = 12),
     (SELECT $node_id FROM Listener WHERE id = 7),
     '2026-03-10', 7, N'Radiohead меняет мировоззрение'),
    -- mike(11) → anna(8)
    ((SELECT $node_id FROM Listener WHERE id = 11),
     (SELECT $node_id FROM Listener WHERE id = 8),
     '2026-04-18', 5, N'Попробуй Massive Attack, это не попса');
GO

-- ============================================================
-- ПРОВЕРКА: посмотрим содержимое всех таблиц
-- ============================================================
SELECT N'Listener'   AS [Таблица], COUNT(*) AS [Строк] FROM Listener
UNION ALL
SELECT N'Artist',                  COUNT(*) FROM Artist
UNION ALL
SELECT N'Genre',                   COUNT(*) FROM Genre
UNION ALL
SELECT N'Listens',                 COUNT(*) FROM Listens
UNION ALL
SELECT N'Performs',                COUNT(*) FROM Performs
UNION ALL
SELECT N'Recommends',              COUNT(*) FROM Recommends;
GO

-- ============================================================
-- ЧАСТЬ 5: ЗАПРОСЫ MATCH (не менее 5, с цепочками 3+ узлов)
-- ============================================================

-- ------------------------------------------------------------
-- Запрос 1: Какие жанры слушают конкретные пользователи
--           (через исполнителей, которых они слушают)?
-- Цепочка: Listener → (Listens) → Artist → (Performs) → Genre
-- ------------------------------------------------------------
PRINT N'=== Запрос 1: Жанры слушателей через исполнителей ===';
SELECT
    l.username        AS [Слушатель],
    l.subscription    AS [Подписка],
    a.name            AS [Исполнитель],
    p.is_primary      AS [Основной жанр],
    g.name            AS [Жанр],
    g.mood            AS [Настроение],
    li.total_plays    AS [Прослушиваний]
FROM Listener AS l
   , Listens  AS li
   , Artist   AS a
   , Performs AS p
   , Genre    AS g
WHERE MATCH(l-(li)->a-(p)->g)
ORDER BY l.username, li.total_plays DESC;
GO

-- ------------------------------------------------------------
-- Запрос 2: Кому слушатель порекомендовал исполнителей
--           и в каком жанре те работают?
-- Цепочка: Listener → (Recommends) → Listener → (Listens) → Artist → (Performs) → Genre
-- ------------------------------------------------------------
PRINT N'=== Запрос 2: Рекомендательные цепочки: кто кому что советует ===';
SELECT
    l1.username       AS [Рекомендует],
    r.trust_score     AS [Доверие],
    l2.username       AS [Получает рек.],
    a.name            AS [Исполнитель у получателя],
    g.name            AS [Жанр исполнителя],
    li.total_plays    AS [Прослушиваний]
FROM Listener AS l1
   , Recommends AS r
   , Listener AS l2
   , Listens  AS li
   , Artist   AS a
   , Performs AS p
   , Genre    AS g
WHERE MATCH(l1-(r)->l2-(li)->a-(p)->g)
  AND p.is_primary = 1
ORDER BY r.trust_score DESC, l1.username;
GO

-- ------------------------------------------------------------
-- Запрос 3: Найти всех слушателей, которые слушают
--           исполнителей, работающих в жанре "Electronic"
-- Цепочка: Listener → (Listens) → Artist → (Performs) → Genre
-- ------------------------------------------------------------
PRINT N'=== Запрос 3: Слушатели электронной музыки ===';
SELECT
    l.username        AS [Слушатель],
    l.country         AS [Страна],
    a.name            AS [Исполнитель],
    a.monthly_listeners AS [Слушатели/мес],
    li.total_plays    AS [Прослушиваний],
    li.is_following   AS [Подписан]
FROM Listener AS l
   , Listens  AS li
   , Artist   AS a
   , Performs AS p
   , Genre    AS g
WHERE MATCH(l-(li)->a-(p)->g)
  AND g.name = N'Electronic'
  AND p.is_primary = 1
ORDER BY li.total_plays DESC;
GO

-- ------------------------------------------------------------
-- Запрос 4: Найти слушателей с premium-подпиской,
--           которым кто-то рекомендовал музыку,
--           и показать на каких исполнителей они подписаны
-- Цепочка: Listener → (Recommends) → Listener → (Listens) → Artist
-- ------------------------------------------------------------
PRINT N'=== Запрос 4: Premium-слушатели с рекомендациями и их исполнители ===';
SELECT
    l1.username       AS [Советует],
    r.rec_date        AS [Дата рек.],
    r.trust_score     AS [Доверие],
    l2.username       AS [Получает (premium)],
    a.name            AS [Исполнитель],
    li.is_following   AS [Подписан]
FROM Listener   AS l1
   , Recommends AS r
   , Listener   AS l2
   , Listens    AS li
   , Artist     AS a
WHERE MATCH(l1-(r)->l2-(li)->a)
  AND l2.subscription = N'premium'
  AND li.is_following = 1
ORDER BY r.trust_score DESC, l2.username;
GO

-- ------------------------------------------------------------
-- Запрос 5: Найти исполнителей, которых слушают пользователи,
--           получившие рекомендации с trust_score >= 8,
--           и в каком настроении их жанры
-- Цепочка: Listener → (Recommends) → Listener → (Listens) → Artist → (Performs) → Genre
-- ------------------------------------------------------------
PRINT N'=== Запрос 5: Исполнители через высокодоверенные рекомендации ===';
SELECT
    l1.username       AS [Источник рек.],
    r.trust_score     AS [Уровень доверия],
    l2.username       AS [Получатель],
    a.name            AS [Исполнитель],
    a.artist_type     AS [Тип],
    g.name            AS [Жанр],
    g.mood            AS [Настроение жанра],
    g.bpm_avg         AS [Средний BPM]
FROM Listener   AS l1
   , Recommends AS r
   , Listener   AS l2
   , Listens    AS li
   , Artist     AS a
   , Performs   AS p
   , Genre      AS g
WHERE MATCH(l1-(r)->l2-(li)->a-(p)->g)
  AND r.trust_score >= 8
  AND p.is_primary = 1
ORDER BY r.trust_score DESC, a.name;
GO

-- ============================================================
-- ЧАСТЬ 6: ЗАПРОСЫ SHORTEST_PATH
-- ============================================================

-- ------------------------------------------------------------
-- SP-Запрос 1: Все цепочки рекомендаций, начиная с alex_sounds
-- Шаблон "+" — повторять 1 и более раз
-- Использует: STRING_AGG, LAST_VALUE
-- ------------------------------------------------------------
PRINT N'=== SP-Запрос 1: Все цепочки рекомендаций от alex_sounds (шаблон +) ===';
SELECT
    l1.username AS [Начало],
    STRING_AGG(l2.username, '->') WITHIN GROUP (GRAPH PATH) AS [Цепочка рекомендаций],
    COUNT(l2.username)             WITHIN GROUP (GRAPH PATH) AS [Длина пути],
    LAST_VALUE(l2.username)        WITHIN GROUP (GRAPH PATH) AS [Конечный слушатель]
FROM Listener AS l1
   , Recommends FOR PATH AS r
   , Listener   FOR PATH AS l2
WHERE MATCH(SHORTEST_PATH(l1(-(r)->l2)+))
  AND l1.username = N'alex_sounds'
ORDER BY [Длина пути];
GO

-- ------------------------------------------------------------
-- SP-Запрос 2: Кратчайший путь рекомендаций от dj_pete до anna_jazz
-- Шаблон "+" с фильтрацией по конечному узлу через CTE
-- ------------------------------------------------------------
PRINT N'=== SP-Запрос 2: Кратчайший путь от dj_pete до anna_jazz (шаблон +) ===';
WITH PathCTE AS
(
    SELECT
        l1.username AS [Начало],
        STRING_AGG(l2.username, '->') WITHIN GROUP (GRAPH PATH) AS [Путь],
        LAST_VALUE(l2.username)        WITHIN GROUP (GRAPH PATH) AS [Конец]
    FROM Listener AS l1
       , Recommends FOR PATH AS r
       , Listener   FOR PATH AS l2
    WHERE MATCH(SHORTEST_PATH(l1(-(r)->l2)+))
      AND l1.username = N'dj_pete'
)
SELECT [Начало], [Путь]
FROM PathCTE
WHERE [Конец] = N'anna_jazz';
GO

-- ------------------------------------------------------------
-- SP-Запрос 3: Все цепочки рекомендаций глубиной от 1 до 3 шагов
-- Шаблон "{1,3}" — ограниченная глубина обхода
-- Используем LAST_VALUE для вывода конечного узла
-- ------------------------------------------------------------
PRINT N'=== SP-Запрос 3: Цепочки рекомендаций глубиной 1-3 шага (шаблон {1,3}) ===';
SELECT
    l1.username AS [Исходный слушатель],
    STRING_AGG(l2.username, '->') WITHIN GROUP (GRAPH PATH) AS [Цепочка],
    COUNT(l2.username)             WITHIN GROUP (GRAPH PATH) AS [Длина пути],
    LAST_VALUE(l2.username)        WITHIN GROUP (GRAPH PATH) AS [Конечный узел]
FROM Listener AS l1
   , Recommends FOR PATH AS r
   , Listener   FOR PATH AS l2
WHERE MATCH(SHORTEST_PATH(l1(-(r)->l2){1,3}))
ORDER BY l1.username, [Длина пути];
GO


