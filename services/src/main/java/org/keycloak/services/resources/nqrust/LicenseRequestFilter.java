package org.keycloak.services.resources.nqrust;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Cookie;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import org.jboss.logging.Logger;
import org.keycloak.common.util.Resteasy;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;

import java.net.URI;
import java.time.Instant;
import java.util.Map;

@Provider
public class LicenseRequestFilter implements ContainerRequestFilter {
    private static final Logger logger = Logger.getLogger(LicenseRequestFilter.class);

    public static final String NEEDS_COOKIE_REFRESH = "nqrust.needsCookieRefresh";

    @Override
    public void filter(ContainerRequestContext requestContext) {
        String path = requestContext.getUriInfo().getPath();

        // 1. Skip public/static paths
        if (isPublicPath(path)) return;

        // 2. Only intercept login and admin paths
        boolean isGuardedPath = path.contains("/protocol/openid-connect/auth") ||
                                path.startsWith("admin/") ||
                                path.equals("admin");
        if (!isGuardedPath) return;

        // 3. Check session cookie (short-lived access pass — no key inside)
        Map<String, Cookie> cookies = requestContext.getCookies();
        Cookie sessionCookie = cookies.get(LicenseResourceProvider.SESSION_COOKIE_NAME);

        if (sessionCookie != null && "ok".equals(sessionCookie.getValue())) {
            // Within session window: trust the cookie, no DB/API call needed
            return;
        }

        // 4. Session expired or missing: check DB (Realm Attributes)
        KeycloakSession keycloakSession = Resteasy.getContextData(KeycloakSession.class);
        if (keycloakSession == null) {
            logger.warn("Could not get KeycloakSession. Redirecting to activation.");
            redirectToActivation(requestContext);
            return;
        }

        RealmModel realm = keycloakSession.getContext().getRealm();
        String storedKey = realm.getAttribute(LicenseResourceProvider.ATTR_LICENSE_KEY);
        String verifiedAtStr = realm.getAttribute(LicenseResourceProvider.ATTR_VERIFIED_AT);

        if (storedKey == null || storedKey.isEmpty()) {
            logger.warn("No license key in DB. Redirecting to activation.");
            redirectToActivation(requestContext);
            return;
        }

        // 5. Check grace period
        long verifiedAt = 0;
        try {
            if (verifiedAtStr != null) verifiedAt = Long.parseLong(verifiedAtStr);
        } catch (NumberFormatException e) {
            logger.warn("Invalid verified_at in DB. Redirecting.");
            redirectToActivation(requestContext);
            return;
        }

        long now = Instant.now().getEpochSecond();
        long elapsed = now - verifiedAt;

        if (elapsed > LicenseResourceProvider.GRACE_PERIOD_SECONDS) {
            logger.warn("License verification expired beyond grace period. Redirecting.");
            LicenseResourceProvider.clearFromRealm(realm);
            redirectToActivation(requestContext);
            return;
        }

        // 6. Within grace period: re-validate with API
        logger.info("Session expired. Re-validating license with API (elapsed: " + elapsed + "s)...");
        LicenseResourceProvider.ApiResult result = LicenseResourceProvider.callApi(storedKey);

        if (result.valid) {
            logger.info("API re-validation succeeded. Refreshing DB and session cookie.");
            LicenseResourceProvider.saveToRealm(realm, storedKey, result);
            // Signal response filter to add refreshed session cookie
            requestContext.setProperty(NEEDS_COOKIE_REFRESH, true);
        } else {
            logger.warn("License revoked by API. Clearing DB and session. Redirecting.");
            LicenseResourceProvider.clearFromRealm(realm);
            redirectToActivation(requestContext, true);
        }
    }

    private boolean isPublicPath(String path) {
        return path.contains("/nqrust/activate") ||
               path.startsWith("resources/") ||
               path.contains("/health") ||
               path.contains("/metrics") ||
               path.contains("/js/") ||
               path.contains("/css/");
    }

    private void redirectToActivation(ContainerRequestContext requestContext) {
        redirectToActivation(requestContext, false);
    }

    private void redirectToActivation(ContainerRequestContext requestContext, boolean clearCookie) {
        String originalUri = requestContext.getUriInfo().getRequestUri().toString();
        String realm = extractRealm(requestContext.getUriInfo().getPath());

        URI redirectUri = requestContext.getUriInfo().getBaseUriBuilder()
                .path("realms").path(realm).path("nqrust").path("activate")
                .queryParam("redirect_uri", originalUri)
                .build();

        Response.ResponseBuilder builder = Response.seeOther(redirectUri);
        if (clearCookie) {
            builder.cookie(LicenseResourceProvider.deleteSessionCookie());
        }
        requestContext.abortWith(builder.build());
    }

    private String extractRealm(String path) {
        if (path.startsWith("realms/")) {
            String[] parts = path.split("/");
            if (parts.length > 1) return parts[1];
        }
        return "master";
    }
}
