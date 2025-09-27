import re
from typing import Final

import google.auth
from googleapiclient.discovery import build
from googleapiclient.errors import HttpError

from ..core.config import settings

_SCOPES: Final[list[str]] = ["https://www.googleapis.com/auth/admin.directory.user"]


class WorkspaceProvisioningError(RuntimeError):
    pass


def _slugify(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", ".", value.lower()).strip('.') or "user"


def _directory_service():
    credentials, _ = google.auth.default(scopes=_SCOPES)
    delegated = credentials.with_subject(settings.workspace_subject)
    return build("admin", "directory_v1", credentials=delegated, cache_discovery=False)


def provision_workspace_account(first_name: str, last_name: str, password: str) -> str:
    """Create or reuse a Google Workspace user for the tenant administrator."""

    service = _directory_service()
    base_username = f"{_slugify(first_name)}.{_slugify(last_name)}"
    candidate = base_username
    attempt = 1

    while True:
        email = f"{candidate}@{settings.workspace_domain}"
        try:
            service.users().get(userKey=email).execute()
        except HttpError as err:
            if err.resp.status == 404:
                break
            raise WorkspaceProvisioningError(f"Workspace kullanicisi kontrol edilemedi: {err}") from err
        candidate = f"{base_username}{attempt}"
        attempt += 1

    body = {
        "primaryEmail": email,
        "name": {
            "givenName": first_name,
            "familyName": last_name,
        },
        "password": password,
        "changePasswordAtNextLogin": True,
    }

    try:
        service.users().insert(body=body).execute()
    except HttpError as err:  # pragma: no cover - depends on external API
        raise WorkspaceProvisioningError(f"Workspace kullanicisi olusturulamadi: {err}") from err

    return email
