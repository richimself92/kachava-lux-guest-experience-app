import { HttpException, InternalServerErrorException, Logger } from '@nestjs/common';
import { CatalogImageStorageAdapter } from '../../src/infrastructure/storage/catalog-image-storage.adapter';
import {
  EmulatorObjectUrlSigner,
  GcsObjectUrlSigner,
  SignableBucket,
} from '../../src/infrastructure/storage/object-url-signer';
import { FirebaseStorageSignerAdapter } from '../../src/infrastructure/storage/storage-signer.adapter';

function bucketWith(getSignedUrl: jest.Mock): { bucket: SignableBucket; file: jest.Mock } {
  const file = jest.fn().mockReturnValue({ getSignedUrl });
  return { bucket: { file }, file };
}

const PUT_PARAMS = {
  stayId: 'stay_1',
  requestId: 'req_1',
  fileName: 'photo one.jpg',
  contentType: 'image/jpeg',
  fileSizeBytes: 2048,
};

describe('FirebaseStorageSignerAdapter with a Cloud Storage bucket', () => {
  let logSpy: jest.SpyInstance;

  beforeEach(() => {
    logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => logSpy.mockRestore());

  const adapterOver = (bucket: SignableBucket) =>
    new FirebaseStorageSignerAdapter(new GcsObjectUrlSigner(bucket, 'test-bucket'));

  it('test_generateSignedPutUrl_signingFails_throwsServerErrorInsteadOfFakeUrl', async () => {
    const { bucket } = bucketWith(jest.fn().mockRejectedValue(new Error('Permission iam.serviceAccounts.signBlob denied')));

    const outcome = adapterOver(bucket).generateSignedPutUrl(PUT_PARAMS);

    await expect(outcome).rejects.toBeInstanceOf(InternalServerErrorException);
    await expect(outcome).rejects.not.toThrow(/signBlob/);
    expect(logSpy).toHaveBeenCalled();
  });

  it('test_generateSignedGetUrl_signingFails_throwsServerErrorInsteadOfFakeUrl', async () => {
    const { bucket } = bucketWith(jest.fn().mockRejectedValue(new Error('signBlob denied')));

    const outcome = adapterOver(bucket).generateSignedGetUrl('private/stays/stay_1/a.jpg');

    await expect(outcome).rejects.toBeInstanceOf(HttpException);
    await expect(outcome).rejects.toMatchObject({ status: 500 });
  });

  it('test_generateSignedPutUrl_signingSucceeds_returnsBucketSignedUrl', async () => {
    const getSignedUrl = jest.fn().mockResolvedValue(['https://signed.example/put']);
    const { bucket, file } = bucketWith(getSignedUrl);

    const result = await adapterOver(bucket).generateSignedPutUrl(PUT_PARAMS);

    expect(result.uploadUrl).toBe('https://signed.example/put');
    expect(result.storagePath).toBe('/private/stays/stay_1/concierge/req_1/photo_one.jpg');
    expect(file).toHaveBeenCalledWith('private/stays/stay_1/concierge/req_1/photo_one.jpg');
    expect(getSignedUrl).toHaveBeenCalledWith(
      expect.objectContaining({ version: 'v4', action: 'write', contentType: 'image/jpeg' }),
    );
  });

  it('test_generateSignedPutUrl_returnsMethodHeadersAndSizeLimitLikeTheAdminSigner', async () => {
    const getSignedUrl = jest.fn().mockResolvedValue(['https://signed.example/put']);
    const { bucket } = bucketWith(getSignedUrl);

    const result = await adapterOver(bucket).generateSignedPutUrl(PUT_PARAMS);

    expect(result).toEqual({
      uploadUrl: 'https://signed.example/put',
      method: 'PUT',
      headers: { 'Content-Type': 'image/jpeg', 'x-goog-content-length-range': `0,${10 * 1024 * 1024}` },
      storagePath: '/private/stays/stay_1/concierge/req_1/photo_one.jpg',
      expiresAt: expect.any(String),
      maxBytes: 10 * 1024 * 1024,
    });
    expect(getSignedUrl).toHaveBeenCalledWith(
      expect.objectContaining({ extensionHeaders: { 'x-goog-content-length-range': `0,${10 * 1024 * 1024}` } }),
    );
  });

  it('test_generateSignedGetUrl_signingSucceeds_returnsBucketSignedUrl', async () => {
    const { bucket } = bucketWith(jest.fn().mockResolvedValue(['https://signed.example/get']));

    const result = await adapterOver(bucket).generateSignedGetUrl('private/stays/stay_1/a.jpg');

    expect(result.downloadUrl).toBe('https://signed.example/get');
    expect(result.storagePath).toBe('/private/stays/stay_1/a.jpg');
  });
});

describe('CatalogImageStorageAdapter', () => {
  it('test_signUpload_gcs_bindsContentTypeAndSizeLimit', async () => {
    const getSignedUrl = jest.fn().mockResolvedValue(['https://signed.example/catalog']);
    const { bucket, file } = bucketWith(getSignedUrl);
    const storage = new CatalogImageStorageAdapter(new GcsObjectUrlSigner(bucket, 'prod-bucket'));

    const upload = await storage.signUpload({ path: 'catalog/s1/a.png', contentType: 'image/png', maxBytes: 5242880 });

    expect(file).toHaveBeenCalledWith('catalog/s1/a.png');
    expect(getSignedUrl).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'write',
        contentType: 'image/png',
        extensionHeaders: { 'x-goog-content-length-range': '0,5242880' },
      }),
    );
    expect(upload).toMatchObject({
      uploadUrl: 'https://signed.example/catalog',
      method: 'PUT',
      headers: { 'Content-Type': 'image/png', 'x-goog-content-length-range': '0,5242880' },
    });
  });

  it('test_publicUrl_gcs_usesFirebaseDownloadEndpoint', () => {
    const storage = new CatalogImageStorageAdapter(new GcsObjectUrlSigner(bucketWith(jest.fn()).bucket, 'prod-bucket'));

    expect(storage.publicUrl('catalog/s1/a b.png')).toBe(
      'https://firebasestorage.googleapis.com/v0/b/prod-bucket/o/catalog%2Fs1%2Fa%20b.png?alt=media',
    );
  });

  it('test_signUpload_emulator_usesMediaUploadEndpoint', async () => {
    const storage = new CatalogImageStorageAdapter(new EmulatorObjectUrlSigner('127.0.0.1:9199', 'demo-bucket'));

    const upload = await storage.signUpload({ path: 'catalog/s1/a.jpg', contentType: 'image/jpeg', maxBytes: 10 });

    expect(upload.method).toBe('POST');
    expect(upload.uploadUrl).toBe(
      'http://127.0.0.1:9199/upload/storage/v1/b/demo-bucket/o?uploadType=media&name=catalog%2Fs1%2Fa.jpg',
    );
    expect(storage.publicUrl('catalog/s1/a.jpg')).toBe(
      'http://127.0.0.1:9199/v0/b/demo-bucket/o/catalog%2Fs1%2Fa.jpg?alt=media',
    );
  });
});
