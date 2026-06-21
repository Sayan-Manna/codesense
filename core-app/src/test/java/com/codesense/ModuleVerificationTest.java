package com.codesense;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;

class ModuleVerificationTest {

    @Test
    void verifyModules() {
        ApplicationModules modules = ApplicationModules.of(CodeSenseApplication.class);
        modules.verify();
    }

}
