package org.keycloak.authentication.authenticators.browser;

import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.core.Response;
import org.jboss.logging.Logger;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.AuthenticationFlowError;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.sessions.AuthenticationSessionModel;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class LicenseAuthenticator implements Authenticator {
    private static final Logger logger = Logger.getLogger(LicenseAuthenticator.class);
    private static final String LICENSE_SESSION_NOTE = "LICENSE_VALIDATED";
    
    // Simple static cache: LicenseKey -> Timestamp of last validation
    private static final Map<String, Long> LICENSE_CACHE = new ConcurrentHashMap<>();
    private static final long CACHE_TTL_MS = 10 * 60 * 1000; // 10 minutes

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // 1. Check if the realm already has a stored license key (Persistence)
        String storedKey = context.getRealm().getAttribute("nqrust_license_key");
        
        if (storedKey != null && !storedKey.trim().isEmpty()) {
            if (validateLicense(storedKey) || validateLocalLicense(storedKey)) {
                logger.info("License already activated for realm: " + context.getRealm().getName());
                context.success();
                return;
            } else {
                logger.warn("Stored license key is no longer valid, requiring re-activation.");
            }
        }

        // 2. Fallback to auth note for current session
        AuthenticationSessionModel authSession = context.getAuthenticationSession();
        String isValidated = authSession.getAuthNote(LICENSE_SESSION_NOTE);

        if ("true".equals(isValidated)) {
            context.success();
            return;
        }

        // 3. Show Activation Page
        Response challenge = context.form()
                .createForm("license-activation.ftl");
        context.challenge(challenge);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        String licenseKey = formData.getFirst("licenseKey");
        
        if (licenseKey == null || licenseKey.trim().isEmpty()) {
            context.challenge(context.form()
                    .setError("License Key is required")
                    .createForm("license-activation.ftl"));
            return;
        }

        if (validateLicense(licenseKey) || validateLocalLicense(licenseKey)) {
            logger.info("License activated successfully. Saving to Realm Attributes.");
            // Store it permanently in the database
            context.getRealm().setAttribute("nqrust_license_key", licenseKey.trim());
            
            context.getAuthenticationSession().setAuthNote(LICENSE_SESSION_NOTE, "true");
            context.success();
        } else {
            context.challenge(context.form()
                    .setError("Invalid or Expired License Key. For offline activation, ensure the .lic content is correct.")
                    .createForm("license-activation.ftl"));
        }
    }

    private boolean validateLocalLicense(String content) {
        String publicKeyPem = System.getenv("LICENSE_PUBLIC_KEY");
        if (publicKeyPem == null || publicKeyPem.isEmpty()) {
            logger.warn("LICENSE_PUBLIC_KEY not configured, skipping local validation");
            return false;
        }

        try {
            // Logic: Intranet/Air-gapped mode
            // The user uploads a .lic file (or pastes the content).
            // We verify the signature using the Public Key.
            // Simplified for this implementation: We check if the content 
            // is a valid signed token that matches our public key.
            logger.info("Attempting local license validation for air-gapped environment");
            
            // TODO: Implement actual Ed25519/RSA signature check here 
            // using the LICENSE_PUBLIC_KEY from .env
            
            return false; // Defaulting to false until full signature logic is added
        } catch (Exception e) {
            logger.error("Local validation failed", e);
            return false;
        }
    }

    private boolean validateLicense(String key) {
        // 1. Check Cache
        Long lastCheck = LICENSE_CACHE.get(key);
        if (lastCheck != null && (System.currentTimeMillis() - lastCheck) < CACHE_TTL_MS) {
            return true;
        }

        // 2. Call Billing API
        String apiUrl = System.getenv("LICENSE_SERVER_URL");
        String apiKey = System.getenv("LICENSE_API_KEY");

        if (apiUrl == null || apiKey == null || apiUrl.contains("localhost")) {
            logger.warn("Online validation skipped: API not configured or in local dev");
            return false;
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

            logger.info("Sending license verification request to: " + apiUrl + "/api/v1/licenses/verify");
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

            if (response.statusCode() == 200 && (response.body().contains("\"valid\":true") || response.body().contains("\"valid\": true"))) {
                logger.info("License validated successfully via online API");
                LICENSE_CACHE.put(key, System.currentTimeMillis());
                return true;
            } else {
                logger.warn("Online validation failed. Status: " + response.statusCode() + ", Body: " + response.body());
            }
        } catch (Exception e) {
            logger.error("Error validating license with Billing API", e);
        }

        return false;
    }

    @Override
    public boolean requiresUser() { return false; }

    @Override
    public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) { return true; }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {}

    @Override
    public void close() {}
}
