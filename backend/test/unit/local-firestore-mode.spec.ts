import { spawnSync } from 'child_process';
import * as path from 'path';

const HELPER = path.resolve(__dirname, '../../scripts/local-firestore-mode.sh');

/** Sources the helper in a clean bash (no network, no services) and reports the decision. */
function resolveMode(env: Record<string, string>) {
  const script = `source "${HELPER}" && resolve_local_firestore_mode && echo "USE_FIRESTORE=\${USE_FIRESTORE} USE_GCP_FIRESTORE=\${USE_GCP_FIRESTORE:-}"`;
  const result = spawnSync('bash', ['-c', script], {
    env: { PATH: process.env.PATH ?? '', ...env },
    encoding: 'utf8',
  });
  return { status: result.status, stdout: result.stdout, stderr: result.stderr };
}

describe('run-local.sh Firestore safety gate (resolve_local_firestore_mode)', () => {
  it('test_resolveMode_noVariables_defaultsToInMemory', () => {
    const outcome = resolveMode({});

    expect(outcome.status).toBe(0);
    expect(outcome.stdout).toContain('IN-MEMORY');
    expect(outcome.stdout).toContain('USE_FIRESTORE=false USE_GCP_FIRESTORE=false');
  });

  it('test_resolveMode_useFirestoreWithoutEmulatorOrOptIn_refusesToStart', () => {
    const outcome = resolveMode({ USE_FIRESTORE: 'true' });

    expect(outcome.status).not.toBe(0);
    expect(outcome.stderr).toContain('KACHAVA_ALLOW_LIVE_FIRESTORE=1');
  });

  it('test_resolveMode_legacyGcpToggleWithoutOptIn_refusesToStart', () => {
    expect(resolveMode({ USE_GCP_FIRESTORE: 'true' }).status).not.toBe(0);
  });

  it('test_resolveMode_useFirestoreWithEmulatorHost_selectsEmulator', () => {
    const outcome = resolveMode({ USE_FIRESTORE: 'true', FIRESTORE_EMULATOR_HOST: '127.0.0.1:8085' });

    expect(outcome.status).toBe(0);
    expect(outcome.stdout).toContain('EMULATOR (127.0.0.1:8085)');
    expect(outcome.stdout).toContain('USE_FIRESTORE=true');
  });

  it('test_resolveMode_explicitLiveOptIn_selectsLiveFirestoreWithWarning', () => {
    const outcome = resolveMode({ USE_FIRESTORE: 'true', KACHAVA_ALLOW_LIVE_FIRESTORE: '1' });

    expect(outcome.status).toBe(0);
    expect(outcome.stdout).toContain('LIVE FIRESTORE');
    expect(outcome.stdout).toContain('USE_FIRESTORE=true');
  });
});
