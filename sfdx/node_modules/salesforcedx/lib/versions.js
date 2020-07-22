
/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */

/**
 * Don't allow the GA version or later of the plugin to be installed in a v6 or earlier CLI
 */
module.exports.ensureVersionCompatibility = function() {
    // The cli-engine version is only set in a v6 CLI
    if (process.env.CLI_ENGINE_VERSION) {
        console.error('Plugin "salesforcedx" v45.8 or later may only be used in a v7.0.0 or later CLI.');
        process.exit(1);
    } 
};
