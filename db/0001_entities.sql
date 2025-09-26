-- Графа 28
CREATE TABLE IF NOT EXISTS banks
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived

    okpo       VARCHAR                  NOT NULL,
    inn        VARCHAR                  NOT NULL,
    mfo        VARCHAR                  NOT NULL,
    name       VARCHAR                  NOT NULL,
    address    VARCHAR                  NOT NULL
);

-- Comments: banks
COMMENT ON TABLE banks IS 'Справочник банков (Графа 28: банковские реквизиты плательщика/брокера/декларанта)';
COMMENT ON COLUMN banks.id IS 'Первичный ключ';
COMMENT ON COLUMN banks.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN banks.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN banks.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN banks.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN banks.okpo IS 'ОКПО банка';
COMMENT ON COLUMN banks.inn IS 'ИНН банка';
COMMENT ON COLUMN banks.mfo IS 'МФО банка (обязательно для графы 28)';
COMMENT ON COLUMN banks.name IS 'Наименование банка';
COMMENT ON COLUMN banks.address IS 'Адрес банка';

CREATE TABLE IF NOT EXISTS organizations
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived

    name       VARCHAR                  NOT NULL,
    domain     VARCHAR                  NOT NULL,
    verified   BOOLEAN                  NOT NULL
);

-- Comments: organizations
COMMENT ON TABLE organizations IS 'Организации (тенантность/учетная сущность платформы). Не является полем ГТД напрямую, но используется для сегментации пользователей и биллинга';
COMMENT ON COLUMN organizations.id IS 'Первичный ключ';
COMMENT ON COLUMN organizations.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN organizations.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN organizations.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN organizations.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN organizations.name IS 'Наименование организации в системе';
COMMENT ON COLUMN organizations.domain IS 'Домен/namespace организации';
COMMENT ON COLUMN organizations.verified IS 'Признак верификации организации';

CREATE TABLE IF NOT EXISTS roles
(
    id         INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE,
    deleted_at TIMESTAMP WITH TIME ZONE,
    status     VARCHAR(255), -- active | deleted | archived

    name       VARCHAR                  NOT NULL
);

-- Comments: roles
COMMENT ON TABLE roles IS 'Роли доступа пользователей (RBAC). Не относится к графам ГТД';
COMMENT ON COLUMN roles.id IS 'Первичный ключ';
COMMENT ON COLUMN roles.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN roles.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN roles.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN roles.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN roles.name IS 'Имя роли';

CREATE TABLE IF NOT EXISTS users
(
    id              INT                                    NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at      TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at      TIMESTAMP WITH TIME ZONE,
    deleted_at      TIMESTAMP WITH TIME ZONE,
    status          VARCHAR(255), -- active | deleted | archived

    role_id         INT REFERENCES roles (id),
    organization_id INT REFERENCES organizations (id),

    first_name      VARCHAR                                NOT NULL,
    last_name       VARCHAR                                NOT NULL,
    middle_name     VARCHAR                                NOT NULL,

    email           VARCHAR                                NOT NULL,
    phone_number    VARCHAR                                NOT NULL,

    agreement       BOOLEAN                  DEFAULT FALSE
);

-- Comments: users
COMMENT ON TABLE users IS 'Пользователи платформы. Используются как авторы деклараций, подписанты (Графа 54), загрузчики файлов (Графа 44)';
COMMENT ON COLUMN users.id IS 'Первичный ключ';
COMMENT ON COLUMN users.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN users.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN users.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN users.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN users.role_id IS 'FK на roles (роль пользователя)';
COMMENT ON COLUMN users.organization_id IS 'FK на organizations (принадлежность пользователя)';
COMMENT ON COLUMN users.first_name IS 'Имя';
COMMENT ON COLUMN users.last_name IS 'Фамилия';
COMMENT ON COLUMN users.middle_name IS 'Отчество';
COMMENT ON COLUMN users.email IS 'Электронная почта';
COMMENT ON COLUMN users.phone_number IS 'Номер телефона';
COMMENT ON COLUMN users.agreement IS 'Согласие с условиями/офертой';

CREATE TABLE IF NOT EXISTS legal_users
(
    id                                 INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at                         TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at                         TIMESTAMP WITH TIME ZONE,
    deleted_at                         TIMESTAMP WITH TIME ZONE,
    status                             VARCHAR(255),                      -- active | deleted | archived

    user_id                            INT UNIQUE REFERENCES users (id),

    inn                                VARCHAR                  NOT NULL,
    oked                               VARCHAR                  NOT NULL,
    address                            VARCHAR                  NOT NULL,

    vat_status                         VARCHAR                  NOT NULL, --payer, non-payer
    vat_registration_number            VARCHAR                  NOT NULL,
    vat_registration_date              DATE                     NOT NULL,

    bank_mfo                           VARCHAR                  NOT NULL,
    bank_current_account               VARCHAR                  NOT NULL,

    customs_broker_registration_number VARCHAR                  NOT NULL,
    customs_broker_registration_date   DATE                     NOT NULL
);

-- Comments: legal_users
COMMENT ON TABLE legal_users IS 'Реквизиты юр.лица для пользователя (декларант/брокер). Источник автозаполнения граф 14 и 54';
COMMENT ON COLUMN legal_users.id IS 'Первичный ключ';
COMMENT ON COLUMN legal_users.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN legal_users.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN legal_users.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN legal_users.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN legal_users.user_id IS 'Уникальная связь с users (1:1)';
COMMENT ON COLUMN legal_users.inn IS 'ИНН юр.лица (графы 14/54)';
COMMENT ON COLUMN legal_users.oked IS 'ОКЭД';
COMMENT ON COLUMN legal_users.address IS 'Юридический адрес';
COMMENT ON COLUMN legal_users.vat_status IS 'Статус плательщика НДС';
COMMENT ON COLUMN legal_users.vat_registration_number IS 'Регистрационный номер НДС';
COMMENT ON COLUMN legal_users.vat_registration_date IS 'Дата регистрации НДС';
COMMENT ON COLUMN legal_users.bank_mfo IS 'МФО обслуживающего банка (для графы 28)';
COMMENT ON COLUMN legal_users.bank_current_account IS 'Расчетный счет (для графы 28)';
COMMENT ON COLUMN legal_users.customs_broker_registration_number IS 'Рег. номер таможенного брокера (для графы 14 при брокере)';
COMMENT ON COLUMN legal_users.customs_broker_registration_date IS 'Дата регистрации брокера';

CREATE TABLE IF NOT EXISTS individual_users
(
    id                     INT                      NOT NULL PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at             TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at             TIMESTAMP WITH TIME ZONE,
    deleted_at             TIMESTAMP WITH TIME ZONE,
    status                 VARCHAR(255), -- active | deleted | archived

    user_id                INT UNIQUE REFERENCES users (id),

    birthday               DATE                     NOT NULL,
    citizenship            VARCHAR                  NOT NULL,
    address                VARCHAR                  NOT NULL,

    pinfl                  VARCHAR                  NOT NULL,
    document_serial_number VARCHAR                  NOT NULL,
    document_issued_date   DATE                     NOT NULL,
    document_issued_by     VARCHAR                  NOT NULL
);

-- Comments: individual_users
COMMENT ON TABLE individual_users IS 'Профиль физ.лица-пользователя (декларант/получатель/отправитель). Источник автозаполнения граф 2/8/14/54';
COMMENT ON COLUMN individual_users.id IS 'Первичный ключ';
COMMENT ON COLUMN individual_users.created_at IS 'Дата/время создания записи';
COMMENT ON COLUMN individual_users.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN individual_users.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN individual_users.status IS 'Статус записи: active | deleted | archived';
COMMENT ON COLUMN individual_users.user_id IS 'Уникальная связь с users (1:1)';
COMMENT ON COLUMN individual_users.birthday IS 'Дата рождения';
COMMENT ON COLUMN individual_users.citizenship IS 'Гражданство';
COMMENT ON COLUMN individual_users.address IS 'Адрес проживания';
COMMENT ON COLUMN individual_users.pinfl IS 'ПИНФЛ (графы 2/8/14/50/54)';
COMMENT ON COLUMN individual_users.document_serial_number IS 'Серия/номер документа';
COMMENT ON COLUMN individual_users.document_issued_date IS 'Дата выдачи документа';
COMMENT ON COLUMN individual_users.document_issued_by IS 'Кем выдан документ';

CREATE TABLE IF NOT EXISTS files
(
    id                  INT PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    created_at          timestamptz NOT NULL DEFAULT NOW(),
    updated_at          timestamptz,
    deleted_at          timestamptz,
    status              TEXT        NOT NULL DEFAULT 'active', -- 'active' | 'deleted' | 'archived'

    storage             TEXT        NOT NULL DEFAULT 's3',     -- 's3' | 'minio' | 'local' (по коду)
    bucket              TEXT        NOT NULL,
    object_key          TEXT        NOT NULL,                  -- s3 key (например: uploads/2025/09/abc.pdf)

    original_name       TEXT,                                  -- имя файла у пользователя
    mime_type           TEXT        NOT NULL,
    extension           TEXT,                                  -- можно null (вычисляется из имени/мimetype)
    size_bytes          BIGINT      NOT NULL,

    etag                TEXT,                                  -- S3/MinIO ETag (проверка целостности)
    content_disposition TEXT,                                  -- при выдаче (inline/attachment; filename=...)
    metadata            jsonb       NOT NULL DEFAULT '{}',     -- любые доп. поля провайдера

    uploaded_by         INT REFERENCES users (id),             -- кто загрузил (если нужно)
    organization_id     INT REFERENCES organizations (id)      -- чей файл (если нужно)
);

-- Comments: files
COMMENT ON TABLE files IS 'Файлы (S3/MinIO/local). Используются для вложений по графе 44 и первичных документов (счета-фактуры) для позиций';
COMMENT ON COLUMN files.id IS 'Первичный ключ';
COMMENT ON COLUMN files.created_at IS 'Дата/время загрузки файла';
COMMENT ON COLUMN files.updated_at IS 'Дата/время изменения записи';
COMMENT ON COLUMN files.deleted_at IS 'Дата/время удаления (soft delete)';
COMMENT ON COLUMN files.status IS 'Статус файла: active | deleted | archived';
COMMENT ON COLUMN files.storage IS 'Тип хранилища: s3 | minio | local';
COMMENT ON COLUMN files.bucket IS 'Имя бакета';
COMMENT ON COLUMN files.object_key IS 'Ключ объекта в бакете';
COMMENT ON COLUMN files.original_name IS 'Оригинальное имя файла';
COMMENT ON COLUMN files.mime_type IS 'MIME-тип файла';
COMMENT ON COLUMN files.extension IS 'Расширение (если известно)';
COMMENT ON COLUMN files.size_bytes IS 'Размер файла в байтах';
COMMENT ON COLUMN files.etag IS 'ETag/хеш объекта для проверки целостности';
COMMENT ON COLUMN files.content_disposition IS 'Режим отдачи (inline/attachment; filename=...)';
COMMENT ON COLUMN files.metadata IS 'Произвольные метаданные провайдера';
COMMENT ON COLUMN files.uploaded_by IS 'FK на users (кто загрузил)';
COMMENT ON COLUMN files.organization_id IS 'FK на organizations (чья сущность файла)';

-- Один объект в бакете по ключу должен быть уникален
CREATE UNIQUE INDEX IF NOT EXISTS uq_files_bucket_key ON files (bucket, object_key);

-- Частые фильтры
CREATE INDEX IF NOT EXISTS idx_files_uploaded_by ON files (uploaded_by);
CREATE INDEX IF NOT EXISTS idx_files_created_at ON files (created_at);
CREATE INDEX IF NOT EXISTS idx_files_status ON files (status);
