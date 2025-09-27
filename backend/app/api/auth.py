from __future__ import annotations

import secrets
from datetime import datetime, timezone
from http import HTTPStatus

import anyio
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import settings
from ..core.database import get_db
from ..models.auth import Organization, OrganizationStatus, VerificationSession
from ..services.database import build_tenant_metadata, create_tenant_database
from ..services.maps import GeocodingError, geocode_address
from ..services.security import encrypt_secret
from ..services.verification import (
    VerificationArtifacts,
    build_verification_artifacts,
    dispatch_email_code,
    validate_sms_code,
    verify_email_code,
    verify_totp_code,
)
from ..services.workspace import WorkspaceProvisioningError, provision_workspace_account
from .schemas import (
    LoginRequest,
    LoginResponse,
    OrganizationSignup,
    SignupInitiatedResponse,
    VerificationRequest,
    VerificationResponse,
)

router = APIRouter(prefix="/auth", tags=["authentication"])

@router.post("/signup/init", response_model=SignupInitiatedResponse, status_code=HTTPStatus.CREATED)
async def signup_init(payload: OrganizationSignup, db: AsyncSession = Depends(get_db)):
    duplicate = await db.execute(
        select(Organization).where(Organization.email == payload.contact_email)
    )
    if duplicate.scalar_one_or_none():
        raise HTTPException(status_code=HTTPStatus.CONFLICT, detail="Bu e-posta ile bir kayit zaten mevcut.")
    try:
        geocode = await geocode_address(payload.address)
    except GeocodingError as exc:
        raise HTTPException(status_code=HTTPStatus.BAD_REQUEST, detail=str(exc)) from exc

    organization = Organization(
        name=payload.organization_name,
        email=payload.contact_email,
        phone=payload.contact_phone,
        address=payload.address,
        formatted_address=geocode.formatted_address,
        latitude=geocode.latitude,
        longitude=geocode.longitude,
        place_id=geocode.place_id,
        subscription_plan=payload.subscription_plan,
        billing_cycle=payload.billing_cycle,
        admin_first_name=payload.admin_first_name,
        admin_last_name=payload.admin_last_name,
        admin_personal_email=payload.admin_personal_email,
        admin_mobile_phone=payload.admin_mobile_phone,
        status=OrganizationStatus.pending_verification,
        is_active=False,
        is_verified=False,
    )
    db.add(organization)
    try:
        await db.flush()
    except IntegrityError as exc:
        raise HTTPException(status_code=HTTPStatus.CONFLICT, detail="Kayit olusturulamadi, benzersiz alan ihlali.") from exc

    try:
        artifacts: VerificationArtifacts = await anyio.to_thread.run_sync(
            build_verification_artifacts,
            payload.admin_personal_email,
            payload.admin_mobile_phone,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=HTTPStatus.BAD_GATEWAY,
            detail="SMS dogrulama baslatilamadi. Lutfen daha sonra tekrar deneyin.",
        ) from exc
    verification = VerificationSession(
        organization_id=organization.id,
        email_code_hash=artifacts.email_code_hash,
        totp_secret_enc=artifacts.totp_secret_enc,
        totp_uri=artifacts.totp_uri,
        sms_verification_sid=artifacts.sms_verification_sid,
        expires_at=artifacts.expires_at,
    )
    db.add(verification)

    await dispatch_email_code(payload.admin_personal_email, artifacts.email_code_plain)

    return SignupInitiatedResponse(
        organization_id=organization.id,
        verification_id=verification.id,
        totp_secret=artifacts.totp_secret_plain,
        totp_uri=artifacts.totp_uri,
        expires_at=artifacts.expires_at,
    )

async def _increment_attempt(field: str, record: VerificationSession, db: AsyncSession) -> None:
    setattr(record, field, getattr(record, field) + 1)
    await db.flush()

    if getattr(record, field) >= settings.max_verification_attempts:
        raise HTTPException(
            status_code=HTTPStatus.TOO_MANY_REQUESTS,
            detail="Dogrulama icin cok fazla basarisiz deneme yapildi. Lutfen destek ile iletisime gecin.",
        )

@router.post("/signup/verify", response_model=VerificationResponse)
async def signup_verify(payload: VerificationRequest, db: AsyncSession = Depends(get_db)):
    verification: VerificationSession | None = await db.get(VerificationSession, payload.verification_id)
    if not verification:
        raise HTTPException(status_code=HTTPStatus.NOT_FOUND, detail="Dogrulama oturumu bulunamadi.")

    if verification.is_expired:
        raise HTTPException(status_code=HTTPStatus.GONE, detail="Dogrulama suresi sona erdi.")

    organization: Organization | None = await db.get(Organization, verification.organization_id)
    if not organization:
        raise HTTPException(status_code=HTTPStatus.NOT_FOUND, detail="Organizasyon kaydi bulunamadi.")

    if not verify_email_code(payload.email_code, verification.email_code_hash):
        await _increment_attempt("email_attempts", verification, db)
        raise HTTPException(status_code=HTTPStatus.BAD_REQUEST, detail="E-posta dogrulama kodu hatali.")
    verification.email_verified_at = datetime.now(timezone.utc)
    sms_valid = await anyio.to_thread.run_sync(
        validate_sms_code,
        organization.admin_mobile_phone,
        payload.sms_code,
    )
    if not sms_valid:
        await _increment_attempt("sms_attempts", verification, db)
        raise HTTPException(status_code=HTTPStatus.BAD_REQUEST, detail="SMS dogrulama kodu hatali.")
    verification.sms_verified_at = datetime.now(timezone.utc)

    if not verify_totp_code(verification.totp_secret_enc, payload.totp_code):
        await _increment_attempt("totp_attempts", verification, db)
        raise HTTPException(status_code=HTTPStatus.BAD_REQUEST, detail="Authenticator kodu hatali.")
    verification.totp_verified_at = datetime.now(timezone.utc)
    tenant_meta = build_tenant_metadata(organization.name)
    organization.status = OrganizationStatus.provisioning

    try:
        await create_tenant_database(tenant_meta)
    except Exception as exc:
        raise HTTPException(
            status_code=HTTPStatus.INTERNAL_SERVER_ERROR,
            detail=f"Tenant veritabani olusturulamadi: {exc}",
        ) from exc

    workspace_temp_password = secrets.token_urlsafe(12)
    try:
        workspace_email = await anyio.to_thread.run_sync(
            provision_workspace_account,
            organization.admin_first_name,
            organization.admin_last_name,
            workspace_temp_password,
        )
    except WorkspaceProvisioningError as exc:
        raise HTTPException(
            status_code=HTTPStatus.BAD_GATEWAY,
            detail="Workspace hesabi olusturulamadi. Lutfen daha sonra tekrar deneyin.",
        ) from exc
    organization.database_name = tenant_meta.name
    organization.database_user = tenant_meta.user
    organization.database_password_enc = encrypt_secret(tenant_meta.password)
    organization.workspace_email = workspace_email
    organization.workspace_password_enc = encrypt_secret(workspace_temp_password)
    organization.is_active = True
    organization.is_verified = True
    organization.status = OrganizationStatus.active

    await db.delete(verification)
    await db.flush()

    return VerificationResponse(
        organization_id=organization.id,
        workspace_email=workspace_email,
        temp_workspace_password=workspace_temp_password,
        database_name=tenant_meta.name,
        database_user=tenant_meta.user,
        database_password=tenant_meta.password,
    )

@router.post("/login", response_model=LoginResponse)
async def login(_: LoginRequest):
    raise HTTPException(status_code=HTTPStatus.NOT_IMPLEMENTED, detail="Giris akis henuz uygulanmadi.")
