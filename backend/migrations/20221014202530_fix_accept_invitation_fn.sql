create or replace function accept_invitation (user_id uuid, inv_id uuid)
  returns uuid
  language plpgsql
  as
$$
declare
  memship_id uuid;
begin
    -- delete the pending invite
    with cte_deleted_invite as (
        delete from "enterprise_invite"
        where enterprise_invite.invite_id = inv_id
        returning *
    )
    -- create a new membership row
    insert into "enterprise_membership"
    (enterprise_id, role, user_id)
    values ((select enterprise_id from cte_deleted_invite), (select role from cte_deleted_invite), user_id)
    returning membership_id
    into memship_id;

    return memship_id;
end;
$$;
