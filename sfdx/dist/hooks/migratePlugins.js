"use strict";
/*
 * Copyright (c) 2019, salesforce.com, inc.
 * All rights reserved.
 * Licensed under the BSD 3-Clause license.
 * For full license text, see LICENSE.txt file in the repo root or https://opensource.org/licenses/BSD-3-Clause
 */
Object.defineProperty(exports, "__esModule", { value: true });
const ts_types_1 = require("@salesforce/ts-types");
const chalk_1 = require("chalk");
const cli_ux_1 = require("cli-ux");
const Debug = require("debug");
const nodeFs = require("fs");
const path = require("path");
const util_1 = require("util");
const debug = Debug('sfdx:preupdate:migrate:plugins');
const hook = async function (options) {
    const fs = this.fs || nodeFs;
    try {
        const v6Dir = path.join(options.config.dataDir, 'plugins');
        const v6Path = path.join(v6Dir, 'package.json');
        if (!(await pathExists(fs, v6Path))) {
            debug('no plugins needing migration found');
            return;
        }
        const v7Dir = options.config.dataDir;
        const v7Path = path.join(v7Dir, 'package.json');
        if (await pathExists(fs, v7Path)) {
            debug('v7 config found, removing obsolete v6 config');
            await remove(fs, v6Path);
            return;
        }
        const v6PackageJson = await readJsonMap(fs, v6Path);
        debug('migrating v6 plugins: %j', v6PackageJson.dependencies);
        cli_ux_1.cli.action.start('Migrating plugins');
        const v7PackageJson = {
            private: 'true',
            oclif: {
                schema: 1,
                plugins: []
            },
            dependencies: {}
        };
        for (const [name, tag] of ts_types_1.definiteEntriesOf(v6PackageJson.dependencies)) {
            const pjsonPath = path.join(v6Dir, 'node_modules', name, 'package.json');
            try {
                if (!(await pathExists(fs, pjsonPath))) {
                    throw new Error(`Plugin ${name}@${tag} not found and could not be migrated`);
                }
                const pjson = await readJsonMap(fs, pjsonPath);
                if (!pjson.version) {
                    throw new Error(`Plugin ${name}@${tag} lacks a version and could not be migrated`);
                }
                if (!pjson.oclif) {
                    throw new Error(`Plugin ${name}@${tag} is incompatible and could not be migrated`);
                }
                v7PackageJson.oclif.plugins.push({ name, tag, type: 'user' });
                v7PackageJson.dependencies[name] = `^${pjson.version}`;
            }
            catch (err) {
                this.warn(chalk_1.default.yellow(err.message));
            }
        }
        await writeJson(fs, v7Path, v7PackageJson);
        debug('wrote v7 plugins: %j', v7PackageJson.dependencies);
        await moveIfPossible(fs, path.join(v6Dir, 'node_modules'), path.join(v7Dir, 'node_modules'));
        await moveIfPossible(fs, path.join(v6Dir, 'yarn.lock'), path.join(v7Dir, 'yarn.lock'));
        debug('moved installed plugins and lockfile');
        await remove(fs, v6Dir);
        cli_ux_1.cli.action.stop();
        debug('cleaned v6 plugin config');
    }
    catch (err) {
        if (err.code !== 'ENOENT')
            return this.warn(chalk_1.default.yellow(err.message));
        debug('file not found during migration: %s', err.message);
    }
};
// Since we don't plan to keep this hook in the CLI indefinitely, adding new dependencies for a few simple util
// functions seems like overkill.
async function pathExists(fs, p) {
    try {
        await util_1.promisify(fs.access)(p);
    }
    catch (_a) {
        return false;
    }
    return true;
}
async function readJsonMap(fs, p) {
    return JSON.parse((await util_1.promisify(fs.readFile)(p)).toString('utf8'));
}
async function writeJson(fs, p, json) {
    return await util_1.promisify(fs.writeFile)(p, JSON.stringify(json));
}
async function remove(fs, p) {
    const stat = await util_1.promisify(fs.lstat)(p);
    if (stat.isDirectory()) {
        const files = await util_1.promisify(fs.readdir)(p);
        await Promise.all(files.map(f => remove(fs, path.join(p, f))));
        await util_1.promisify(fs.rmdir)(p);
    }
    else {
        await util_1.promisify(fs.unlink)(p);
    }
}
async function moveIfPossible(fs, from, to) {
    if (await pathExists(fs, from) && !(await pathExists(fs, to))) {
        await util_1.promisify(fs.rename)(from, to);
    }
}
exports.default = hook;
//# sourceMappingURL=migratePlugins.js.map