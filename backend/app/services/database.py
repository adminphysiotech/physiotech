import re
import secrets
import string
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Final

import asyncpg
from sqlalchemy.engine.url import make_url

from ..core.config import settings

_MAX_IDENTIFIER: Final[int] = 63


@dataclass(slots=True, frozen=True)
class TenantDatabaseMeta:
    name: str
    user: str
    password: str


def _quote_identifier(value: str) -> str:
    escaped = value.replace('"', '""')
    return f'"{escaped}"'


def _slugify(value: str) -> str:
    slug = re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")
    return slug or secrets.token_hex(4)


def _generate_password() -> str:
    specials = settings.tenant_password_specials
    alphabet = string.ascii_letters + string.digits + specials
    length = settings.tenant_password_length

    while True:
        candidate = ''.join(secrets.choice(alphabet) for _ in range(length))
        if (
            any(c.islower() for c in candidate)
            and any(c.isupper() for c in candidate)
            and any(c.isdigit() for c in candidate)
            and any(c in specials for c in candidate)
        ):
            return candidate


def build_tenant_metadata(org_name: str) -> TenantDatabaseMeta:
    slug = _slugify(org_name)
    timestamp = datetime.now(timezone.utc).strftime('%Y%m%d%H%M%S')
    db_name = f"tenant_{slug}_{timestamp}"[:_MAX_IDENTIFIER]
    db_user = f"usr_{secrets.token_hex(6)}"[:_MAX_IDENTIFIER]
    return TenantDatabaseMeta(name=db_name, user=db_user, password=_generate_password())


async def _execute(conn: asyncpg.Connection, query: str, *args) -> None:
    await conn.execute(query, *args)


async def create_tenant_database(meta: TenantDatabaseMeta) -> None:
    """Provision an isolated database and owner role for a tenant.

    The provisioning is broken into discrete steps to allow explicit rollback
    should any command fail. The resulting role owns its database but has no
    privileges outside of it.
    """

    admin_url = make_url(settings.asyncpg_dsn)
    async with asyncpg.connect(str(admin_url)) as conn:
        await _execute(
            conn,
            f"CREATE ROLE {_quote_identifier(meta.user)} WITH LOGIN PASSWORD $1 NOCREATEDB NOCREATEROLE NOINHERIT",
            meta.password,
        )

        try:
            await _execute(
                conn,
                f"CREATE DATABASE {_quote_identifier(meta.name)} "
                f"OWNER {_quote_identifier(meta.user)} "
                "ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' LC_CTYPE 'en_US.UTF-8' TEMPLATE template0",
            )
        except Exception:
            await _execute(conn, f"DROP ROLE IF EXISTS {_quote_identifier(meta.user)}")
            raise

        await _execute(
            conn,
            f"REVOKE CONNECT ON DATABASE {_quote_identifier(meta.name)} FROM PUBLIC",
        )
        await _execute(
            conn,
            f"GRANT CONNECT ON DATABASE {_quote_identifier(meta.name)} TO {_quote_identifier(meta.user)}",
        )

    tenant_url = admin_url.set(database=meta.name)
    async with asyncpg.connect(str(tenant_url)) as tenant_conn:
        await _execute(tenant_conn, "REVOKE ALL ON SCHEMA public FROM PUBLIC")
        await _execute(
            tenant_conn,
            f"GRANT ALL ON SCHEMA public TO {_quote_identifier(meta.user)}",
        )
