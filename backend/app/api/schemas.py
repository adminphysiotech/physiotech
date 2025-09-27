from datetime import datetime
from typing import Literal, Optional
from uuid import UUID

from pydantic import BaseModel, EmailStr, Field

SubscriptionPlan = Literal["basic", "standard", "pro"]
BillingCycle = Literal["monthly", "annual"]


class OrganizationSignup(BaseModel):
    organization_name: str = Field(..., min_length=2, max_length=255)
    legal_name: Optional[str] = Field(None, max_length=255)
    contact_email: EmailStr
    contact_phone: str = Field(..., min_length=8, max_length=32)
    address: str = Field(..., min_length=5, max_length=500)
    admin_first_name: str = Field(..., min_length=2, max_length=100)
    admin_last_name: str = Field(..., min_length=2, max_length=100)
    admin_personal_email: EmailStr
    admin_mobile_phone: str = Field(..., min_length=8, max_length=32)
    subscription_plan: SubscriptionPlan = "basic"
    billing_cycle: BillingCycle = "monthly"


class SignupInitiatedResponse(BaseModel):
    organization_id: int
    verification_id: UUID
    totp_secret: str
    totp_uri: str
    expires_at: datetime


class VerificationRequest(BaseModel):
    verification_id: UUID
    email_code: str
    sms_code: str
    totp_code: str


class VerificationResponse(BaseModel):
    organization_id: int
    workspace_email: str
    temp_workspace_password: str
    database_name: str
    database_user: str
    database_password: str


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
    totp_code: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    tenant_database: str
    tenant_user: str


class OrganizationSummary(BaseModel):
    id: int
    name: str
    email: str
    subscription_plan: str
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
