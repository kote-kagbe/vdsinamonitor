create table [options] ( -- кастомные опции с уникальными именами
    [id] integer not null primary key,
    [key] text not null, -- уникальный ключ опции
    [value] blob -- значение опции
) strict;

create unique index [ui_options_key] on [options]([key]);

create table [accounts] ( -- список аккаунтов
    [id] integer not null primary key,
    [remote_id] integer, -- удалённый ключ
    [created] integer, -- дата создания
    [name] text not null, -- название
    [login] text, -- логин
    [password] text, -- пароль
    [token] text, -- токен аутентификации
    [expires] integer, -- предполагаемая дата окончания баланса
    [server_limit] integer, -- ограничение по количеству серверов
    [server_current] integer, -- текущее количество серверов
    [active] integer check([deleted] in (0,1) or [deleted] is null), -- признак активности аккаунта
    [deleted] integer not null default 0 check([deleted] in (0,1)) -- признак локальной удалённости аккаунта
) strict;

create unique index [ui_accounts_remote_id] on [accounts]([remote_id]);

create table [account_balances] ( -- список балансов аккаунта
    [id] integer not null primary key,
    [account] integer not null references [accounts]([id]) on update cascade on delete cascade

) strict;

create table [tariff_groups] ( -- список групп тарифов
    [id] integer not null primary key,
    [remote_id] integer not null -- удалённый ключ

) strict;

create unique index [ui_tariff_groups_remote_id] on [tariff_groups]([remote_id]);

create table [tariffs] ( -- список тарифных планов
    [id] integer not null primary key,
    [remote_id] integer not null, -- удалённый ключ
    [name] text, -- название
    [description] text, -- описание
    [cost] real, -- стоимость периода оплаты
    [cost_period] text, -- текстовый ключ периода оплаты
    [cost_period_name] text, -- название периода оплаты
    [tariff_group] integer not null references [tariff_groups]([id]) on update cascade on delete cascade
) strict;

create unique index [ui_tariffs_remote_id] on [tariffs]([remote_id]);

create table [data_centers] ( -- список дата-центров
    [id] integer not null primary key,
    [remote_id] integer not null, -- удалённый ключ
    [name] text not null, -- название
    [country] text not null, -- регион
    [active] integer check([active] in (0,1) or [active] is null) -- доступность
) strict;

create unique index [ui_data_centers_remote_id] on [data_centers]([remote_id]);

create table [os_templates] ( -- список шаблонов ОС
    [id] integer not null primary key,
    [remote_id] integer not null, -- удалённый ключ
    [name] text not null, -- название
    [image] text, -- url на картинку
    [active] integer check([active] in (0,1) or [active] is null), -- признак активности
    -- ограничения
    [limit_cpu_min] integer,
    [limit_cpu_max] integer,
    [limit_ram_min] integer,
    [limit_ram_max] integer,
    [limit_disk_min] real,
    [limit_disk_max] real
) strict;

create unique index [ui_os_templates_remote_id] on [os_templates]([remote_id]);

create table [template2tariff] ( -- связи шаблона с тарифами
    [id] integer not null primary key,
    [tariff] integer not null references [tariffs]([id]) on update cascade on delete cascade
) strict;

create table [servers] ( -- список серверов
    [id] integer not null primary key,
    [remote_id] integer not null, -- удалённый ключ
    [account] integer not null references [accounts]([id]) on update cascade on delete cascade, -- связь с аккаунтом
    [name] text not null, -- название
    [data_center] integer not null references [data_centers]([id]) on update cascade on delete cascade, -- связь с дата-центром
    [tariff] integer not null references [tariffs]([id]) on update cascade on delete cascade, -- связь с тарифом
    [tariff_group] integer not null references [tariff_groups]([id]) on update cascade on delete cascade, -- связь с группой тарифов
    [os_template] integer references [os_templates]([id]) on update cascade on delete cascade, -- связь с шаблоном ОС
    [host] text, -- внешнее имя хоста
    [cpu] integer, -- количество ядер процессора
    [ram] real, -- размер ОЗУ
    [ram_unit] text, -- единицы измерения ОЗУ
    [disk] real, -- размер диска
    [disk_unit] text, -- единицы измерения диска
    [status] text not null, -- состояние
    /*
        new – сервер заказан, но не ещё не создан
        active – сервер активен и работает
        block – сервер заблокирован администрацией
        notpaid – сервер остановлен за неуплату
        deleted – сервер удалён
    */
    [created] integer -- дата создания
) strict;

create unique index [ui_servers_remote_id] on [servers]([remote_id]);

create table [server_stats] ( -- статистика сервера
    [id] integer not null primary key,
    [server] integer not null references [servers]([id]) on update cascade on delete cascade,
    [datetime] integer,
    [cpu] real,
    [disk_reads] integer,
    [disk_writes] integer,
    [wan_rx] integer,
    [wan_tx] integer
) strict;

create index [i_server_stats_datetime] on [server_stats]([datetime] desc);

create table [balance_stats] ( -- статистика баланса
    [id] integer not null primary key,
    [remote_id] integer not null,
    [purse] text not null,
    [type] integer check([type] in (-1,1) or [type] is null),
    [status] integer check([status] in (0,1) or [status] is null),
    [summ] real,
    [created] integer,
    [updated] integer,
    [comment] text,
    [service] integer, -- references
    [payment_type] text,
    [payment_name] text
) strict;

create unique index [ui_balance_stats_remote_id] on [balance_stats]([remote_id]);

create index [i_balance_stats_created] on [balance_stats]([created] desc);

create index [i_balance_stats_updated] on [balance_stats]([updated] desc);