from dataclasses import dataclass

import httpx

from ..core.config import settings

_GOOGLE_GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/json"


class GeocodingError(RuntimeError):
    pass


@dataclass(slots=True, frozen=True)
class GeocodeResult:
    formatted_address: str
    latitude: float
    longitude: float
    place_id: str


async def geocode_address(address: str) -> GeocodeResult:
    params = {
        "address": address,
        "key": settings.google_maps_api_key,
    }
    if settings.google_maps_region_bias:
        params["region"] = settings.google_maps_region_bias

    async with httpx.AsyncClient(timeout=httpx.Timeout(10.0)) as client:
        response = await client.get(_GOOGLE_GEOCODE_URL, params=params)
        response.raise_for_status()
        payload = response.json()

    status = payload.get("status")
    if status != "OK" or not payload.get("results"):
        raise GeocodingError(f"Adres dogrulanamadi (status={status})")

    first = payload["results"][0]
    geometry = first["geometry"]["location"]
    return GeocodeResult(
        formatted_address=first.get("formatted_address", address),
        latitude=float(geometry["lat"]),
        longitude=float(geometry["lng"]),
        place_id=first.get("place_id", ""),
    )
