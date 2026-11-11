import { InternalServerErrorException, Logger } from '@nestjs/common';

export interface SignedWrite {
  url: string;
  method: 'PUT' | 'POST';
  headers: Record<string, string>;
}

/** Issues time-limited URLs for objects in one bucket. */
export interface ObjectUrlSigner {
  signWrite(path: string, contentType: string, expiresAt: Date, maxBytes?: number): Promise<SignedWrite>;
  signRead(path: string, expiresAt: Date): Promise<string>;
  /** Download URL for objects whose storage rules allow public read (`catalog/**`). */
  publicUrl(path: string): string;
}

export interface SignedUrlRequest {
  version: 'v4';
  action: 'read' | 'write';
  expires: Date;
  contentType?: string;
  extensionHeaders?: Record<string, string>;
}

/** The slice of a Cloud Storage bucket the signer needs (satisfied by `@google-cloud/storage` Bucket). */
export interface SignableBucket {
  file(path: string): {
    getSignedUrl(config: SignedUrlRequest): Promise<[string]>;
  };
}

const CONTENT_LENGTH_RANGE_HEADER = 'x-goog-content-length-range';

function objectName(path: string): string {
  return path.replace(/^\//, '');
}

/** Production: V4 signed URLs from Cloud Storage. A signing failure is a 500, never a forged URL. */
export class GcsObjectUrlSigner implements ObjectUrlSigner {
  private readonly logger = new Logger(GcsObjectUrlSigner.name);

  constructor(
    private readonly bucket: SignableBucket,
    private readonly bucketName: string,
  ) {}

  async signWrite(path: string, contentType: string, expiresAt: Date, maxBytes?: number): Promise<SignedWrite> {
    const extensionHeaders = maxBytes ? { [CONTENT_LENGTH_RANGE_HEADER]: `0,${maxBytes}` } : undefined;
    const url = await this.sign(path, {
      version: 'v4',
      action: 'write',
      expires: expiresAt,
      contentType,
      ...(extensionHeaders ? { extensionHeaders } : {}),
    });
    return { url, method: 'PUT', headers: { 'Content-Type': contentType, ...(extensionHeaders ?? {}) } };
  }

  signRead(path: string, expiresAt: Date): Promise<string> {
    return this.sign(path, { version: 'v4', action: 'read', expires: expiresAt });
  }

  publicUrl(path: string): string {
    return `https://firebasestorage.googleapis.com/v0/b/${this.bucketName}/o/${encodeURIComponent(objectName(path))}?alt=media`;
  }

  private async sign(path: string, request: SignedUrlRequest): Promise<string> {
    try {
      const [url] = await this.bucket.file(objectName(path)).getSignedUrl(request);
      return url;
    } catch (error) {
      this.logger.error(
        `Cloud Storage ${request.action} URL signing failed for ${path}`,
        error instanceof Error ? error.stack : String(error),
      );
      throw new InternalServerErrorException('Storage URL signing failed.');
    }
  }
}

/**
 * Local development against the Firebase Storage emulator, which cannot verify V4 signatures:
 * uploads use its JSON media endpoint (POST) and reads its download endpoints.
 */
export class EmulatorObjectUrlSigner implements ObjectUrlSigner {
  constructor(
    private readonly emulatorHost: string,
    private readonly bucketName: string,
  ) {}

  async signWrite(path: string, contentType: string): Promise<SignedWrite> {
    const name = encodeURIComponent(objectName(path));
    return {
      url: `${this.origin()}/upload/storage/v1/b/${this.bucketName}/o?uploadType=media&name=${name}`,
      method: 'POST',
      headers: { 'Content-Type': contentType },
    };
  }

  async signRead(path: string): Promise<string> {
    return `${this.origin()}/storage/v1/b/${this.bucketName}/o/${encodeURIComponent(objectName(path))}?alt=media`;
  }

  publicUrl(path: string): string {
    return `${this.origin()}/v0/b/${this.bucketName}/o/${encodeURIComponent(objectName(path))}?alt=media`;
  }

  private origin(): string {
    return /^https?:\/\//.test(this.emulatorHost) ? this.emulatorHost : `http://${this.emulatorHost}`;
  }
}
