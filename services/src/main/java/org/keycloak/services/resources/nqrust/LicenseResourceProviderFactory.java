package org.keycloak.services.resources.nqrust;

import org.jboss.logging.Logger;
import org.keycloak.Config;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.services.resource.RealmResourceProvider;
import org.keycloak.services.resource.RealmResourceProviderFactory;

public class LicenseResourceProviderFactory implements RealmResourceProviderFactory {
    public static final String ID = "nqrust";
    private static final Logger logger = Logger.getLogger(LicenseResourceProviderFactory.class);

    @Override
    public RealmResourceProvider create(KeycloakSession session) {
        return new LicenseResourceProvider(session);
    }

    @Override
    public void init(Config.Scope config) {
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
    }

    @Override
    public void close() {
    }

    @Override
    public String getId() {
        return ID;
    }
}
