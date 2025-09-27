import datetime as dt
import enum
import uuid

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
)
from sqlalchemy.dialects.postgresql import UUID

from ..core.database import Base


def _utcnow() -> dt.datetime:
    return dt.datetime.now(dt.timezone.utc)


class OrganizationStatus(str, enum.Enum):
    pending_verification = "pending_verification"
    provisioning = "provisioning"
    active = "active"
    suspended = "suspended"


class Organization(Base):
    __tablename__ = "organizations"
    __table_args__ = (
        UniqueConstraint("email"),
        UniqueConstraint("database_name"),
        UniqueConstraint("database_user"),
        UniqueConstraint("workspace_email"),
    )

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False, unique=True, index=True)
    phone = Column(String(50))
    address = Column(Text)
    formatted_address = Column(Text)
    latitude = Column(Numeric(10, 8))
    longitude = Column(Numeric(11, 8))
    place_id = Column(String(128))
    subscription_plan = Column(String(50), nullable=False)
    billing_cycle = Column(String(20), nullable=False)
    admin_first_name = Column(String(100), nullable=False)
    admin_last_name = Column(String(100), nullable=False)
    admin_personal_email = Column(String(255), nullable=False)
    admin_mobile_phone = Column(String(50), nullable=False)
    database_name = Column(String(100), nullable=True)
    database_user = Column(String(100), nullable=True)
    database_password_enc = Column(String(500), nullable=True)
    workspace_email = Column(String(255), nullable=True)
    workspace_password_enc = Column(String(500), nullable=True)
    status = Column(Enum(OrganizationStatus), nullable=False, default=OrganizationStatus.pending_verification)
    created_at = Column(DateTime(timezone=True), default=_utcnow)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)
    is_active = Column(Boolean, default=False)
    is_verified = Column(Boolean, default=False)


class VerificationSession(Base):
    __tablename__ = "verification_sessions"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    organization_id = Column(Integer, ForeignKey("organizations.id", ondelete="CASCADE"), unique=True, nullable=False)
    email_code_hash = Column(String(255), nullable=False)
    totp_secret_enc = Column(String(255), nullable=False)
    totp_uri = Column(Text, nullable=False)
    sms_verification_sid = Column(String(128), nullable=False)
    email_attempts = Column(Integer, default=0)
    sms_attempts = Column(Integer, default=0)
    totp_attempts = Column(Integer, default=0)
    email_verified_at = Column(DateTime(timezone=True))
    sms_verified_at = Column(DateTime(timezone=True))
    totp_verified_at = Column(DateTime(timezone=True))
    expires_at = Column(DateTime(timezone=True), nullable=False)
    created_at = Column(DateTime(timezone=True), default=_utcnow)
    updated_at = Column(DateTime(timezone=True), default=_utcnow, onupdate=_utcnow)

    @property
    def is_expired(self) -> bool:
        if self.expires_at is None:
            return False
        return self.expires_at <= _utcnow()
