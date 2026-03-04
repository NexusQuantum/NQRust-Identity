package org.keycloak.services.resources.nqrust;

import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import org.jboss.logging.Logger;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.services.resource.RealmResourceProvider;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.time.Instant;

public class LicenseResourceProvider implements RealmResourceProvider {
    private static final Logger logger = Logger.getLogger(LicenseResourceProvider.class);

    // Cookie name used for short-lived session token (no key inside)
    public static final String SESSION_COOKIE_NAME = "nqrust_license_session";

    // Realm Attribute keys (stored in Keycloak DB)
    public static final String ATTR_LICENSE_KEY       = "nqrust_license_key";
    public static final String ATTR_STATUS            = "nqrust_license_status";
    public static final String ATTR_VERIFIED_AT       = "nqrust_license_verified_at";
    public static final String ATTR_EXPIRES_AT        = "nqrust_license_expires_at";
    public static final String ATTR_CUSTOMER          = "nqrust_license_customer";

    // 5 minutes for testing. Change to 30 * 60 for production.
    public static final int SESSION_TTL_SECONDS = 5 * 60;

    // Grace period: allow access even if API is unreachable (7 days)
    public static final long GRACE_PERIOD_SECONDS = 7L * 24 * 60 * 60;

    private final KeycloakSession session;

    public LicenseResourceProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public Object getResource() {
        return this;
    }

    // ── GET /license/info ──────────────────────────────────────────────────────
    @GET
    @Path("license/info")
    @Produces(MediaType.APPLICATION_JSON)
    public Response getLicenseInfo() {
        RealmModel realm = session.getContext().getRealm();
        String rawKey        = realm.getAttribute(ATTR_LICENSE_KEY);
        String status        = realm.getAttribute(ATTR_STATUS);
        String customer      = realm.getAttribute(ATTR_CUSTOMER);
        String expiresAt     = realm.getAttribute(ATTR_EXPIRES_AT);
        String verifiedAtStr = realm.getAttribute(ATTR_VERIFIED_AT);

        // Mask license key – show only last 4 characters
        String maskedKey = "";
        if (rawKey != null && !rawKey.isEmpty()) {
            maskedKey = rawKey.length() > 4
                    ? "****-****-****-" + rawKey.substring(rawKey.length() - 4)
                    : "****";
        }

        long verifiedAt = 0;
        if (verifiedAtStr != null && !verifiedAtStr.isEmpty()) {
            try { verifiedAt = Long.parseLong(verifiedAtStr); } catch (NumberFormatException ignored) {}
        }

        String json = String.format(
            "{\"status\":\"%s\",\"licenseKey\":\"%s\",\"customer\":\"%s\"," +
            "\"product\":\"NQRust Identity\",\"expiresAt\":\"%s\",\"verifiedAt\":%d}",
            status    != null ? status    : "inactive",
            maskedKey,
            customer  != null ? customer  : "",
            expiresAt != null ? expiresAt : "",
            verifiedAt
        );

        return Response.ok(json, MediaType.APPLICATION_JSON).build();
    }

    // ── POST /license/activate (JSON response, for Admin Console modal) ────────
    @POST
    @Path("license/activate")
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    @Produces(MediaType.APPLICATION_JSON)
    public Response activateLicenseApi(@FormParam("licenseKey") String licenseKey) {
        if (licenseKey == null || licenseKey.trim().isEmpty()) {
            return Response.status(400)
                    .entity("{\"error\":\"licenseKey is required\"}")
                    .type(MediaType.APPLICATION_JSON).build();
        }
        String key = licenseKey.trim();
        ApiResult result = callApi(key);
        if (result.valid) {
            saveToRealm(session.getContext().getRealm(), key, result);
            return Response.ok("{\"status\":\"activated\"}", MediaType.APPLICATION_JSON).build();
        }
        return Response.status(400)
                .entity("{\"error\":\"Invalid or expired license key\"}")
                .type(MediaType.APPLICATION_JSON).build();
    }


    @GET
    @Path("activate")
    @Produces(MediaType.TEXT_HTML)
    public Response getActivationPage(@QueryParam("redirect_uri") String redirectUri) {
        return session.getProvider(LoginFormsProvider.class)
                .setAttribute("redirect_uri", redirectUri != null ? redirectUri : "")
                .createForm("license-activation.ftl");
    }

    @POST
    @Path("activate")
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    public Response processActivation(
            @FormParam("licenseKey") String licenseKey,
            @QueryParam("redirect_uri") String redirectUri) {

        if (licenseKey == null || licenseKey.trim().isEmpty()) {
            return session.getProvider(LoginFormsProvider.class)
                    .setError("License Key is required")
                    .createForm("license-activation.ftl");
        }

        String key = licenseKey.trim();
        ApiResult result = callApi(key);

        if (result.valid) {
            logger.info("License activated. Saving to Realm Attributes (DB).");
            RealmModel realm = session.getContext().getRealm();
            saveToRealm(realm, key, result);

            NewCookie sessionCookie = buildSessionCookie();

            URI destination = (redirectUri != null && !redirectUri.isEmpty())
                    ? URI.create(redirectUri)
                    : session.getContext().getUri().getBaseUri();

            return Response.seeOther(destination)
                    .cookie(sessionCookie)
                    .build();
        } else {
            return session.getProvider(LoginFormsProvider.class)
                    .setError("Invalid or Expired License Key")
                    .createForm("license-activation.ftl");
        }
    }

    // --- Shared utilities ---

    public static ApiResult callApi(String key) {
        Logger log = Logger.getLogger(LicenseResourceProvider.class);
        String apiUrl = System.getenv("LICENSE_SERVER_URL");
        String apiKey = System.getenv("LICENSE_API_KEY");

        if (apiUrl == null || apiKey == null) {
            log.warn("License API not configured. Allowing access for development.");
            return new ApiResult(true, "dev", null, null);
        }

        try {
            HttpClient client = HttpClient.newBuilder()
                    .connectTimeout(Duration.ofSeconds(5))
                    .build();

            String jsonPayload = String.format("{\"licenseKey\": \"%s\"}", key);
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(apiUrl + "/api/v1/licenses/verify"))
                    .header("Authorization", "Bearer " + apiKey)
                    .header("Content-Type", "application/json")
                    .POST(HttpRequest.BodyPublishers.ofString(jsonPayload))
                    .build();

            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            String body = response.body();
            log.info("License API status: " + response.statusCode() + " | body: " + body);

            // Must be HTTP 200 AND contain "valid":true
            boolean hasValidTrue = body.contains("\"valid\":true") || body.contains("\"valid\": true");
            // Explicitly reject if status/active indicates revoked/inactive
            boolean isRevoked = body.contains("\"revoked\":true") || body.contains("\"revoked\": true")
                             || body.contains("\"status\":\"revoked\"") || body.contains("\"status\": \"revoked\"")
                             || body.contains("\"status\":\"inactive\"") || body.contains("\"status\": \"inactive\"")
                             || body.contains("\"active\":false") || body.contains("\"active\": false");

            boolean valid = response.statusCode() == 200 && hasValidTrue && !isRevoked;
            log.info("License valid determination: hasValidTrue=" + hasValidTrue
                   + " isRevoked=" + isRevoked + " -> valid=" + valid);

            if (valid) {
                String customer = extractJsonField(body, "customer");
                String expiresAt = extractJsonField(body, "expiresAt");
                return new ApiResult(true, customer, expiresAt, body);
            } else {
                return new ApiResult(false, null, null, body);
            }
        } catch (Exception e) {
            log.error("License API call failed: " + e.getMessage());
            return new ApiResult(false, null, null, null);
        }
    }

    public static void saveToRealm(RealmModel realm, String key, ApiResult result) {
        realm.setAttribute(ATTR_LICENSE_KEY, key);
        realm.setAttribute(ATTR_STATUS, "active");
        realm.setAttribute(ATTR_VERIFIED_AT, String.valueOf(Instant.now().getEpochSecond()));
        if (result.customer != null) realm.setAttribute(ATTR_CUSTOMER, result.customer);
        if (result.expiresAt != null) realm.setAttribute(ATTR_EXPIRES_AT, result.expiresAt);
    }

    public static void clearFromRealm(RealmModel realm) {
        realm.removeAttribute(ATTR_LICENSE_KEY);
        realm.removeAttribute(ATTR_STATUS);
        realm.removeAttribute(ATTR_VERIFIED_AT);
        realm.removeAttribute(ATTR_EXPIRES_AT);
        realm.removeAttribute(ATTR_CUSTOMER);
    }

    public static NewCookie buildSessionCookie() {
        return new NewCookie.Builder(SESSION_COOKIE_NAME)
                .value("ok")
                .path("/")
                .maxAge(SESSION_TTL_SECONDS)
                .httpOnly(true)
                .build();
    }

    public static NewCookie deleteSessionCookie() {
        return new NewCookie.Builder(SESSION_COOKIE_NAME)
                .value("")
                .path("/")
                .maxAge(0)
                .httpOnly(true)
                .build();
    }

    private static String extractJsonField(String json, String fieldName) {
        String search = "\"" + fieldName + "\":\"";
        int start = json.indexOf(search);
        if (start < 0) return null;
        start += search.length();
        int end = json.indexOf("\"", start);
        return end < 0 ? null : json.substring(start, end);
    }

    @Override
    public void close() {}

    // --- Data class ---
    public static class ApiResult {
        public final boolean valid;
        public final String customer;
        public final String expiresAt;
        public final String rawBody;

        public ApiResult(boolean valid, String customer, String expiresAt, String rawBody) {
            this.valid = valid;
            this.customer = customer;
            this.expiresAt = expiresAt;
            this.rawBody = rawBody;
        }
    }
}
