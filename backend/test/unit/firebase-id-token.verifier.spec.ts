const mockVerifyIdToken = jest.fn();
const mockApps: unknown[] = [];

jest.mock('firebase-admin', () => ({
  get apps() {
    return mockApps;
  },
  auth: () => ({ verifyIdToken: mockVerifyIdToken }),
}));

import { FirebaseIdTokenVerifier } from '../../src/common/services/firebase-id-token.verifier';

describe('FirebaseIdTokenVerifier', () => {
  const originalFlag = process.env.USE_FIRESTORE;
  let verifier: FirebaseIdTokenVerifier;

  beforeEach(() => {
    mockVerifyIdToken.mockReset();
    mockApps.length = 0;
    mockApps.push({});
    process.env.USE_FIRESTORE = 'true';
    verifier = new FirebaseIdTokenVerifier();
  });

  afterEach(() => {
    if (originalFlag === undefined) delete process.env.USE_FIRESTORE;
    else process.env.USE_FIRESTORE = originalFlag;
  });

  it('test_verify_validIdTokenWithVerifiedEmail_returnsUidAndEmail', async () => {
    mockVerifyIdToken.mockResolvedValue({ uid: 'uid_1', email: 'staff@kachavalux.com', email_verified: true });

    await expect(verifier.verify('id-token')).resolves.toEqual({ uid: 'uid_1', email: 'staff@kachavalux.com' });
    expect(mockVerifyIdToken).toHaveBeenCalledWith('id-token');
  });

  it.each([false, undefined])(
    'test_verify_emailVerified%s_omitsEmailSoItCannotMatchAStaffMember',
    async (emailVerified) => {
      mockVerifyIdToken.mockResolvedValue({ uid: 'uid_2', email: 'staff@kachavalux.com', email_verified: emailVerified });

      await expect(verifier.verify('id-token')).resolves.toEqual({ uid: 'uid_2' });
    },
  );

  it('test_verify_firebaseAuthRejection_returnsNull', async () => {
    mockVerifyIdToken.mockRejectedValue(Object.assign(new Error('expired'), { code: 'auth/id-token-expired' }));

    await expect(verifier.verify('id-token')).resolves.toBeNull();
  });

  it('test_verify_nonAuthFailure_propagates', async () => {
    mockVerifyIdToken.mockRejectedValue(new Error('UNAVAILABLE: network'));

    await expect(verifier.verify('id-token')).rejects.toThrow('UNAVAILABLE: network');
  });

  it('test_verify_firebaseDisabled_returnsNullWithoutCallingFirebase', async () => {
    delete process.env.USE_FIRESTORE;

    await expect(verifier.verify('id-token')).resolves.toBeNull();
    expect(mockVerifyIdToken).not.toHaveBeenCalled();
  });
});

describe('FirebaseIdTokenVerifier production flag', () => {
  const saved = { firestore: process.env.USE_FIRESTORE, gcp: process.env.USE_FIRESTORE };

  afterEach(() => {
    for (const [key, value] of [['USE_FIRESTORE', saved.firestore], ['USE_FIRESTORE', saved.gcp]] as const) {
      if (value === undefined) delete process.env[key];
      else process.env[key] = value;
    }
  });

  it('test_verify_useFirestoreTrueOnly_verifiesWithFirebase', async () => {
    mockApps.length = 0;
    mockApps.push({});
    delete process.env.USE_FIRESTORE;
    process.env.USE_FIRESTORE = 'true';
    mockVerifyIdToken.mockReset();
    mockVerifyIdToken.mockResolvedValue({ uid: 'uid_prod', email: 'staff@kachavalux.com', email_verified: true });

    await expect(new FirebaseIdTokenVerifier().verify('id-token')).resolves.toEqual({
      uid: 'uid_prod',
      email: 'staff@kachavalux.com',
    });
  });
});
