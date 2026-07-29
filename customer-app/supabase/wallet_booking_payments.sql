create table if not exists public.customer_sessions(
  token_hash text primary key,
  mobile text not null references public.customer_accounts(mobile) on delete cascade,
  expires_at timestamptz not null default(now()+interval '30 days'),
  created_at timestamptz not null default now()
);
alter table public.customer_sessions enable row level security;

create or replace function public.new_customer_session(p_mobile text) returns text
language plpgsql security definer set search_path=public,extensions as $$
declare raw_token text:=encode(gen_random_bytes(32),'hex');
begin
  delete from public.customer_sessions where expires_at<=now();
  insert into public.customer_sessions(token_hash,mobile)
  values(encode(digest(raw_token,'sha256'),'hex'),p_mobile);
  return raw_token;
end $$;

create or replace function public.register_customer_account(
  p_mobile text,p_password text,p_name text default ''
) returns jsonb language plpgsql security definer set search_path=public,extensions as $$
declare clean_mobile text:=regexp_replace(coalesce(p_mobile,''),'\D','','g');
clean_name text:=trim(coalesce(p_name,'')); session_token text;
begin
 if length(clean_mobile)<>10 then raise exception 'INVALID_MOBILE'; end if;
 if length(coalesce(p_password,''))<6 then raise exception 'WEAK_PASSWORD'; end if;
 if exists(select 1 from public.customer_accounts where mobile=clean_mobile) then raise exception 'ACCOUNT_EXISTS'; end if;
 insert into public.customer_accounts(mobile,password_hash) values(clean_mobile,crypt(p_password,gen_salt('bf')));
 insert into public.customers(mobile,name,updated_at) values(clean_mobile,clean_name,now())
 on conflict(mobile) do update set name=case when excluded.name='' then customers.name else excluded.name end,updated_at=now();
 session_token:=public.new_customer_session(clean_mobile);
 return jsonb_build_object('mobile',clean_mobile,'name',clean_name,'session_token',session_token);
end $$;

create or replace function public.login_customer_account(
  p_mobile text,p_password text
) returns jsonb language plpgsql security definer set search_path=public,extensions as $$
declare clean_mobile text:=regexp_replace(coalesce(p_mobile,''),'\D','','g');
profile public.customers%rowtype; session_token text;
begin
 if not exists(select 1 from public.customer_accounts where mobile=clean_mobile and password_hash=crypt(p_password,password_hash)) then raise exception 'INVALID_LOGIN'; end if;
 select * into profile from public.customers where mobile=clean_mobile;
 session_token:=public.new_customer_session(clean_mobile);
 return jsonb_build_object('mobile',clean_mobile,'name',coalesce(profile.name,''),'village',coalesce(profile.village,''),'address',coalesce(profile.address,''),'avatar_url',coalesce(profile.avatar_url,''),'session_token',session_token);
end $$;
revoke all on function public.new_customer_session(text) from public,anon,authenticated;

alter table public.wallet_transactions add column if not exists booking_id uuid references public.bookings(id);
create unique index if not exists wallet_transactions_booking_unique on public.wallet_transactions(booking_id) where booking_id is not null;
create table if not exists public.wallet_booking_requests(
 request_id text primary key,mobile text not null,booking_id uuid references public.bookings(id),
 amount int not null,status text not null default 'completed',created_at timestamptz not null default now()
);
alter table public.wallet_booking_requests enable row level security;
drop policy if exists wallet_booking_requests_admin_read on public.wallet_booking_requests;
create policy wallet_booking_requests_admin_read on public.wallet_booking_requests for select to authenticated using(true);

create or replace function public.pay_booking_from_wallet(
 p_mobile text,p_token_hash text,p_request_id text,p_payload jsonb
) returns jsonb language plpgsql security definer set search_path=public as $$
declare current_balance int; amount_due int:=(p_payload->>'advance')::int;
new_balance int; new_booking_id uuid; code text;
begin
 if not exists(select 1 from customer_sessions where mobile=p_mobile and token_hash=p_token_hash and expires_at>now()) then raise exception 'INVALID_SESSION'; end if;
 select booking_id into new_booking_id from wallet_booking_requests where request_id=p_request_id and mobile=p_mobile;
 if new_booking_id is not null then select booking_code into code from bookings where id=new_booking_id; return jsonb_build_object('booking_id',new_booking_id,'booking_code',code,'already_paid',true); end if;
 select wallet_balance into current_balance from customers where mobile=p_mobile for update;
 if current_balance is null then raise exception 'CUSTOMER_NOT_FOUND'; end if;
 if current_balance<amount_due then raise exception 'INSUFFICIENT_BALANCE'; end if;
 insert into bookings(booking_code,customer_name,event_type,cans,per_can_rate,subtotal,delivery_charge,grand_total,advance,balance,village,mobile,address,event_date,event_time,payment_method,offer_code,offer_discount_percent,discount_amount,status)
 values(p_payload->>'booking_code',p_payload->>'customer_name',p_payload->>'event_type',(p_payload->>'cans')::int,(p_payload->>'per_can_rate')::int,(p_payload->>'subtotal')::int,(p_payload->>'delivery_charge')::int,(p_payload->>'grand_total')::int,amount_due,(p_payload->>'balance')::int,p_payload->>'village',p_mobile,p_payload->>'address',(p_payload->>'event_date')::date,p_payload->>'event_time','wallet',nullif(p_payload->>'offer_code',''),(p_payload->>'offer_discount_percent')::int,(p_payload->>'discount_amount')::int,'confirmed')
 returning id,booking_code into new_booking_id,code;
 update customers set wallet_balance=wallet_balance-amount_due,updated_at=now() where mobile=p_mobile returning wallet_balance into new_balance;
 insert into wallet_transactions(mobile,type,amount,balance_after,description,booking_id) values(p_mobile,'debit',amount_due,new_balance,'Booking advance paid from wallet',new_booking_id);
 insert into wallet_booking_requests(request_id,mobile,booking_id,amount) values(p_request_id,p_mobile,new_booking_id,amount_due);
 return jsonb_build_object('booking_id',new_booking_id,'booking_code',code,'balance',new_balance,'already_paid',false);
end $$;
revoke all on function public.pay_booking_from_wallet(text,text,text,jsonb) from public,anon,authenticated;
grant execute on function public.pay_booking_from_wallet(text,text,text,jsonb) to service_role;
