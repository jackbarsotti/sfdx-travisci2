"use strict";
/*
 * Copyright (c) 2018, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
Object.defineProperty(exports, "__esModule", { value: true });
const versions_1 = require("../versions");
const FORCE_PLUGINS = [
    'salesforcedx',
    'salesforce-alm',
    'force-language-services'
];
const MIN_VERSION = '45.8.0';
/**
 * A CLI plugin preinstall hook that checks that the plugin's version is v7-compatible,
 * if it is recognized as a force namespace plugin.
 */
const hook = async function (options) {
    if (options.plugin && options.plugin.type === 'npm') {
        const plugin = options.plugin;
        if (FORCE_PLUGINS.includes(plugin.name) && versions_1.isVersion(plugin.tag) && versions_1.compareVersions(plugin.tag, MIN_VERSION) < 0) {
            this.error(`The ${plugin.name} plugin can only be installed using a specific version when ` +
                `the version is greater than or equal to ${MIN_VERSION}.`);
        }
    }
};
exports.default = hook;
//# sourceMappingURL=verifyPluginVersion.js.map