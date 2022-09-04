-- The role of a user within an enterprise
create type enterprise_role as enum ('admin', 'instructor', 'player', 'parent');

-- The existence of a row signifies that a user has a pending invitation to join this enterprise
-- As soon as the user accepts/declines, the row is deleted and an enterprise_membership row is inserted
create table enterprise_invite
(
    invite_id       uuid primary key                                          default uuid_generate_v1mc(),
    -- By default, "references" (foreign key) relationships will throw errors if the row in the referenced table
    -- is deleted before this one. The `on delete cascade` clause causes this to be automatically deleted if the
    -- corresponding user row is deleted.
    --
    -- Before applying `on delete cascade` to a foreign key clause, though, you should consider the actual semantics
    -- of that table. Does it, for example, contain purchase records that are linked to a payment processor? You may not
    -- want to delete those records for auditing purposes, even if you want to delete the user record itself.
    --
    -- In cases like that, I usually just forego the foreign-key clause and treat the user ID as a plain data column
    -- so the row sticks around even if the user is deleted. There's also `on delete set null` but then that
    -- requires the column to be nullable which makes it unwieldy in queries when it should not be null 99% of the time.
    enterprise_id    uuid                                            not null references "enterprise" (enterprise_id) on delete cascade,

    -- the new user's email
    user_email       text          collate "case_insensitive"        not null,

    -- Users may be invited to multiple enterprises, but cannot be invited to the same enterprise twice
    unique (enterprise_id, user_email),

    role             enterprise_role                                 not null,

    -- Used as a token to aid user registration
    invite_code      text          collate "case_insensitive" unique not null,

    created_at       timestamptz                                     not null default now()
);

-- A row signifies a user who accepted their invitation into an enterprise
create table enterprise_membership
(
    membership_id    uuid primary key                                          default uuid_generate_v1mc(),
    enterprise_id    uuid                                            not null references "enterprise" (enterprise_id) on delete cascade,
    user_id          uuid                                            not null references "user"       (user_id)       on delete cascade,
    -- Users may belong to multiple enterprises
    unique (enterprise_id, user_id),

    role             enterprise_role                                 not null,

    created_at       timestamptz                                     not null default now(),
    updated_at       timestamptz
);
SELECT trigger_updated_at('enterprise_membership');

-- TODO: test what happens when an invite is nonexistent
create function accept_invitation (invite_id uuid) returns integer
language plpgsql
as $$
begin
    -- delete the pending invite
        with cte_deleted_invite as (
            delete from "enterprise_invite"
            where invite_id = invite_id
            returning *
        )
    -- create a new membership row
        insert into "enterprise_membership"
        (enterprise_id, role, user_id)
        values ((select enterprise_id from cte_deleted_invite), (select role from cte_deleted_invite), (select user_id from cte_deleted_user))
        returning membership_id;
end;
$$;
