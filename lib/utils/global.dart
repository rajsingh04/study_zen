String uri = "http://localhost:8000";

// In-memory JWT tokens for API calls (useful on web where
// secure storage is not available). These are set on login
// and read by services when building Authorization headers.
String? accessToken;
String? refreshToken;