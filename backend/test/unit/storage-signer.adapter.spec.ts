import { HttpException, InternalServerErrorException, Logger } from '@nestjs/common';
import {
  FirebaseStorageSignerAdapter,
  SignableBucket,
} from '../../src/infrastructure/storage/storage-signer.adapter';

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

  it('test_generateSignedPutUrl_signingFails_throwsServerErrorInsteadOfFakeUrl', async () => {
    const { bucket } = bucketWith(jest.fn().mockRejectedValue(new Error('Permission iam.serviceAccounts.signBlob denied')));
    const signer = new FirebaseStorageSignerAdapter(bucket);

    const outcome = signer.generateSignedPutUrl(PUT_PARAMS);

    await expect(outcome).rejects.toBeInstanceOf(InternalServerErrorException);
    await expect(outcome).rejects.not.toThrow(/signBlob/);
    expect(logSpy).toHaveBeenCalled();
  });

  it('test_generateSignedGetUrl_signingFails_throwsServerErrorInsteadOfFakeUrl', async () => {
    const { bucket } = bucketWith(jest.fn().mockRejectedValue(new Error('signBlob denied')));
    const signer = new FirebaseStorageSignerAdapter(bucket);

    const outcome = signer.generateSignedGetUrl('private/stays/stay_1/a.jpg');

    await expect(outcome).rejects.toBeInstanceOf(HttpException);
    await expect(outcome).rejects.toMatchObject({ status: 500 });
  });

  it('test_generateSignedPutUrl_signingSucceeds_returnsBucketSignedUrl', async () => {
    const getSignedUrl = jest.fn().mockResolvedValue(['https://signed.example/put']);
    const { bucket, file } = bucketWith(getSignedUrl);
    const signer = new FirebaseStorageSignerAdapter(bucket);

    const result = await signer.generateSignedPutUrl(PUT_PARAMS);

    expect(result.uploadUrl).toBe('https://signed.example/put');
    expect(result.storagePath).toBe('/private/stays/stay_1/concierge/req_1/photo_one.jpg');
    expect(file).toHaveBeenCalledWith('private/stays/stay_1/concierge/req_1/photo_one.jpg');
    expect(getSignedUrl).toHaveBeenCalledWith(
      expect.objectContaining({ version: 'v4', action: 'write', contentType: 'image/jpeg' }),
    );
  });

  it('test_generateSignedGetUrl_signingSucceeds_returnsBucketSignedUrl', async () => {
    const { bucket } = bucketWith(jest.fn().mockResolvedValue(['https://signed.example/get']));
    const signer = new FirebaseStorageSignerAdapter(bucket);

    const result = await signer.generateSignedGetUrl('private/stays/stay_1/a.jpg');

    expect(result.downloadUrl).toBe('https://signed.example/get');
    expect(result.storagePath).toBe('/private/stays/stay_1/a.jpg');
  });
});
