alter table enterprise_invite drop invite_code;

create table app_invite
(
    invite_id       uuid primary key                                          default uuid_generate_v1mc(),

    -- the new user's email
    user_email       text          collate "case_insensitive" unique not null,

    -- Used as a token to aid user registration
    invite_code      text          collate "case_insensitive" unique not null default uuid_generate_v1mc(),

    created_at       timestamptz                                     not null default now()
);
