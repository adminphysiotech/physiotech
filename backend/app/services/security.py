import secrets
import string
from typing import Final

import pyotp
from passlib.context import CryptContext

from ..core.config import settings

_OTP_ISSUER: Final[str] = "Physiotech"
_pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_secret(value: str) -> str:
    return _pwd_context.hash(value)


def verify_secret(value: str, hashed: str) -> bool:
    return _pwd_context.verify(value, hashed)


def encrypt_secret(value: str) -> str:
    return settings.fernet.encrypt(value.encode("utf-8")).decode("utf-8")


def decrypt_secret(value: str) -> str:
    return settings.fernet.decrypt(value.encode("utf-8")).decode("utf-8")


def generate_numeric_code(length: int = 6) -> str:
    if length < 4:
        raise ValueError("Verification codes must be at least 4 digits long")
    return ''.join(secrets.choice(string.digits) for _ in range(length))


def generate_totp_secret() -> str:
    return pyotp.random_base32()


def build_otpauth_uri(secret: str, account: str) -> str:
    totp = pyotp.TOTP(secret)
    return totp.provisioning_uri(name=account, issuer_name=_OTP_ISSUER)


def verify_totp(secret: str, code: str, window: int = 1) -> bool:
    totp = pyotp.TOTP(secret)
    return totp.verify(code, valid_window=window)
