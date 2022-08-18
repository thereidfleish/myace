-- The role of a user within the MyAce team
create type myace_team_role as enum ('backend', 'frontend', 'business');

create table myace_team
(
    team_id          uuid primary key                                          default uuid_generate_v1mc(),
    user_id          uuid                                     unique not null references "user"       (user_id)       on delete cascade,
    role             myace_team_role                                 not null,
    created_at       timestamptz                                     not null default now()
);
