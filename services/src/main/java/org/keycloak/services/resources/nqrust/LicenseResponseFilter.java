package org.keycloak.services.resources.nqrust;

import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.ext.Provider;
import org.jboss.logging.Logger;

import java.io.IOException;

/**
 * Runs AFTER the request is processed.
 * If LicenseRequestFilter signals a re-validation occurred, this filter
 * injects a fresh session cookie into the response.
 */
@Provider
public class LicenseResponseFilter implements ContainerResponseFilter {
    private static final Logger logger = Logger.getLogger(LicenseResponseFilter.class);

    @Override
    public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) throws IOException {
        Boolean needsRefresh = (Boolean) requestContext.getProperty(LicenseRequestFilter.NEEDS_COOKIE_REFRESH);
        if (needsRefresh == null || !needsRefresh) return;

        logger.info("Injecting refreshed session cookie into response.");
        responseContext.getHeaders().add("Set-Cookie", LicenseResourceProvider.buildSessionCookie().toString());
    }
}
