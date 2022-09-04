create table "enterprise"
(
    enterprise_id     uuid primary key                                default uuid_generate_v1mc(),

    name              text                                   not null,

    website           text,

    -- Intended to be used exclusively by customers. For example, if a customer has a
    -- question about their membership, they can send an email to this address and expect a reply.
    support_email     text,
    support_phone     text,

    logo              text,

    -- If you want to be really pedantic you can add a trigger that enforces this column will never change,
    -- but that seems like overkill for something that's relatively easy to enforce in code-review.
    created_at        timestamptz                            not null default now(),

    updated_at        timestamptz
);

-- And applying our `updated_at` trigger is as easy as this.
SELECT trigger_updated_at('"enterprise"');
