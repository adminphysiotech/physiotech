from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from email.message import EmailMessage

import aiosmtplib
from twilio.rest import Client as TwilioClient

from ..core.config import settings
from .security import (
    build_otpauth_uri,
    decrypt_secret,
    encrypt_secret,
    generate_numeric_code,
    generate_totp_secret,
    hash_secret,
    verify_secret,
    verify_totp,
)


@dataclass(slots=True, frozen=True)
class VerificationArtifacts:
    email_code_plain: str
    email_code_hash: str
    totp_secret_plain: str
    totp_secret_enc: str
    totp_uri: str
    sms_verification_sid: str
    expires_at: datetime


_twilio_client = TwilioClient(settings.twilio_account_sid, settings.twilio_auth_token)


async def dispatch_email_code(recipient: str, code: str) -> None:
    message = EmailMessage()
    message['Subject'] = 'Physiotech dogrulama kodunuz'
    message['From'] = settings.smtp_sender
    message['To'] = recipient
    message.set_content(
        (
            'Merhaba,\n\n'
            'Kaydinizi tamamlamak icin dogrulama kodunuz: {code}\n\n'
            'Kod {ttl} dakika icinde gecerliligini yitirecek.\n\n'
            'Physiotech'
        ).format(code=code, ttl=settings.verification_timeout_minutes)
    )

    await aiosmtplib.send(
        message,
        hostname=settings.smtp_host,
        port=settings.smtp_port,
        username=settings.smtp_user,
        password=settings.smtp_pass,
        start_tls=True,
        timeout=20.0,
    )


def trigger_sms_verification(phone_number: str) -> str:
    verification = _twilio_client.verify.v2.services(settings.twilio_verify_sid).verifications.create(
        to=phone_number,
        channel='sms',
    )
    return verification.sid


def validate_sms_code(phone_number: str, code: str) -> bool:
    result = _twilio_client.verify.v2.services(settings.twilio_verify_sid).verification_checks.create(
        to=phone_number,
        code=code,
    )
    return result.status == 'approved'


def build_verification_artifacts(recipient_email: str, phone_number: str) -> VerificationArtifacts:
    email_code = generate_numeric_code(6)
    totp_secret = generate_totp_secret()
    totp_uri = build_otpauth_uri(totp_secret, recipient_email)
    sms_sid = trigger_sms_verification(phone_number)

    expires_at = datetime.now(timezone.utc) + timedelta(minutes=settings.verification_timeout_minutes)
    return VerificationArtifacts(
        email_code_plain=email_code,
        email_code_hash=hash_secret(email_code),
        totp_secret_plain=totp_secret,
        totp_secret_enc=encrypt_secret(totp_secret),
        totp_uri=totp_uri,
        sms_verification_sid=sms_sid,
        expires_at=expires_at,
    )


def verify_email_code(candidate: str, hashed_code: str) -> bool:
    return verify_secret(candidate, hashed_code)


def verify_totp_code(enc_secret: str, candidate: str) -> bool:
    return verify_totp(decrypt_secret(enc_secret), candidate)
