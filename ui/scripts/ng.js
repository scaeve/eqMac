#!/usr/bin/env node
// Runs the Angular CLI on both old and current Node versions.
//
// Angular 12 bundles webpack 5.50, which hashes with md4. Node 17+ ships OpenSSL 3,
// where md4 lives in the "legacy" provider, so the build fails with
// ERR_OSSL_EVP_UNSUPPORTED unless --openssl-legacy-provider is passed. Node 16 and
// older reject that flag, so it is only added when needed.
const { spawnSync } = require('child_process')
const path = require('path')

const nodeMajor = Number(process.versions.node.split('.')[0])
const nodeFlags = nodeMajor >= 17 ? ['--openssl-legacy-provider'] : []
const ngCli = path.join(__dirname, '..', '..', 'node_modules', '@angular', 'cli', 'bin', 'ng')

const result = spawnSync(process.execPath, [...nodeFlags, ngCli, ...process.argv.slice(2)], {
  stdio: 'inherit'
})
process.exit(result.status ?? 1)
