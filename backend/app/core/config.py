from functools import cached_property
from pathlib import Path

from cryptography.fernet import Fernet
from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine.url import make_url

PROJECT_ROOT = Path(__file__).resolve().parents[3]
ENV_FILE = PROJECT_ROOT / ".env"

if not ENV_FILE.exists():
    raise FileNotFoundError(f".env not found at {ENV_FILE}")


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=str(ENV_FILE),
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # core infrastructure
    project_id: str = Field('long-indexer-472712-a9', alias="GCP_PROJECT_ID")
    control_db_dsn: str = Field(..., alias="CONTROL_DB_DSN")
    cloudsql_instance: str = Field(..., alias="CLOUDSQL_INSTANCE")
    cloudsql_region: str = Field('us-central1', alias="CLOUDSQL_REGION")
    jwt_secret: str = Field(..., alias="JWT_SECRET")

    # encryption / security
    db_credentials_key: str = Field('hklcTH_-UEOyvJ9X6929ijrbhqHmPGn2vyosFTzvZIQ=', alias="DB_CREDENTIALS_KEY")
    max_verification_attempts: int = Field(5, alias="MAX_VERIFICATION_ATTEMPTS")
    verification_timeout_minutes: int = Field(15, alias="VERIFICATION_TIMEOUT_MINUTES")

    # third-party integrations
    google_maps_api_key: str = Field(..., alias="GOOGLE_MAPS_API_KEY")
    google_maps_region_bias: str = Field('tr', alias="GOOGLE_MAPS_REGION_BIAS")
    twilio_account_sid: str = Field(..., alias="TWILIO_ACCOUNT_SID")
    twilio_auth_token: str = Field(..., alias="TWILIO_AUTH_TOKEN")
    twilio_verify_sid: str = Field(..., alias="TWILIO_VERIFY_SID")
    smtp_host: str = Field(..., alias="SMTP_HOST")
    smtp_port: int = Field(..., alias="SMTP_PORT")
    smtp_user: str = Field(..., alias="SMTP_USER")
    smtp_pass: str = Field(..., alias="SMTP_PASS")
    smtp_sender: str = Field('noreply@physiotech.app', alias="SMTP_SENDER")
    workspace_subject: str = Field(..., alias="WORKSPACE_SUBJECT")
    workspace_domain: str = Field(..., alias="WORKSPACE_DOMAIN")
    workspace_delegated_sa: str = Field(..., alias="WORKSPACE_DELEGATED_SA")
    send_verify_success_email: bool = Field(False, alias="SEND_VERIFY_SUCCESS_EMAIL")

    # control-plane defaults
    tenant_password_length: int = Field(24, alias="TENANT_PASSWORD_LENGTH")
    tenant_password_specials: str = Field("!@#$%^&*()-_", alias="TENANT_PASSWORD_SPECIALS")
    sqlalchemy_echo: bool = Field(False, alias="SQLALCHEMY_ECHO")

    # deployment targets
    cloud_run_service: str = Field("", alias="CLOUD_RUN_SERVICE", validation_alias="cloud_run_service")
    gke_cluster: str = Field("", alias="GKE_CLUSTER", validation_alias="gke_cluster")
    gke_location: str = Field("", alias="GKE_LOCATION", validation_alias="gke_location")

    @field_validator("db_credentials_key")
    @classmethod
    def validate_fernet_key(cls, value: str) -> str:
        try:
            Fernet(value)
        except Exception as exc:  # pragma: no cover - invalid keys fail fast
            raise ValueError("DB_CREDENTIALS_KEY must be a valid 32 byte base64 encoded key") from exc
        return value

    @cached_property
    def asyncpg_dsn(self) -> str:
        # asyncpg requires the postgresql drivername
        return str(make_url(self.control_db_dsn).set(drivername="postgresql"))

    @cached_property
    def fernet(self) -> Fernet:
        return Fernet(self.db_credentials_key)


settings = Settings()
