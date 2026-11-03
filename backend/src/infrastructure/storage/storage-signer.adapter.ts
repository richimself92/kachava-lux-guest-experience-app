import {
  BadRequestException,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { resolveSecret } from '../../common/config/runtime-secrets';
import {
  SignedUrlResult,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import { DEFAULT_STORAGE_BUCKET } from '../firebase/firebase-admin.module';

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX_UPLOAD_BYTES = 10 * 1024 * 1024; // 10 MB
const SIGNED_URL_TTL_MS = 15 * 60 * 1000;

type SignedUrlAction = 'read' | 'write';

export interface SignedUrlRequest {
  version: 'v4';
  action: SignedUrlAction;
  expires: Date;
  contentType?: string;
}

/** The slice of a Cloud Storage bucket the signer needs (satisfied by `@google-cloud/storage` Bucket). */
export interface SignableBucket {
  file(path: string): {
    getSignedUrl(config: SignedUrlRequest): Promise<[string]>;
  };
}

/**
 * Issues V4 signed URLs for concierge photos.
 * - With a Cloud Storage bucket (Firestore mode) every URL is signed by Google; a signing failure
 *   is a 500 and never degrades to a locally forged URL.
 * - Without a bucket (in-memory local/test mode) it issues deterministic local-development URLs.
 */
export class FirebaseStorageSignerAdapter implements StorageSignerPort {
  private readonly logger = new Logger(FirebaseStorageSignerAdapter.name);
  private readonly bucketName =
    process.env.FIREBASE_STORAGE_BUCKET || DEFAULT_STORAGE_BUCKET;

  constructor(private readonly bucket: SignableBucket | null = null) {}

  async generateSignedPutUrl(params: {
    stayId: string;
    requestId: string;
    fileName: string;
    contentType: string;
    fileSizeBytes: number;
  }): Promise<SignedUrlResult> {
    this.validateUploadConstraints(params.contentType, params.fileSizeBytes);
    const sanitizedName = params.fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `/private/stays/${params.stayId}/concierge/${params.requestId}/${sanitizedName}`;
    const expiresAt = new Date(Date.now() + SIGNED_URL_TTL_MS);
    const uploadUrl = await this.signUrl(storagePath, 'write', expiresAt, params.contentType);
    return {
      uploadUrl,
      storagePath,
      expiresAt: expiresAt.toISOString(),
      contentType: params.contentType,
    };
  }

  async generateSignedGetUrl(storagePath: string): Promise<SignedUrlResult> {
    const normalizedPath = storagePath.startsWith('/')
      ? storagePath
      : `/${storagePath}`;
    const expiresAt = new Date(Date.now() + SIGNED_URL_TTL_MS);
    const downloadUrl = await this.signUrl(normalizedPath, 'read', expiresAt);
    return {
      downloadUrl,
      storagePath: normalizedPath,
      expiresAt: expiresAt.toISOString(),
    };
  }

  private async signUrl(
    path: string,
    action: SignedUrlAction,
    expiresAt: Date,
    contentType?: string,
  ): Promise<string> {
    if (!this.bucket) return this.localDevelopmentUrl(path, action, expiresAt);
    try {
      const [url] = await this.bucket
        .file(path.replace(/^\//, ''))
        .getSignedUrl({ version: 'v4', action, expires: expiresAt, ...(contentType ? { contentType } : {}) });
      return url;
    } catch (error) {
      this.logger.error(
        `Cloud Storage ${action} URL signing failed for ${path}`,
        error instanceof Error ? error.stack : String(error),
      );
      throw new InternalServerErrorException('Storage URL signing failed.');
    }
  }

  private validateUploadConstraints(contentType: string, fileSizeBytes: number): void {
    if (!ALLOWED_MIME_TYPES.has(contentType)) {
      throw new BadRequestException(
        `Invalid MIME type "${contentType}". Allowed types: image/jpeg, image/png, image/webp.`,
      );
    }
    if (!Number.isFinite(fileSizeBytes) || fileSizeBytes <= 0 || fileSizeBytes > MAX_UPLOAD_BYTES) {
      throw new BadRequestException(
        `Invalid file size (${fileSizeBytes} bytes). File must be between 1 byte and 10MB.`,
      );
    }
  }

  private localDevelopmentUrl(path: string, action: SignedUrlAction, expiresAt: Date): string {
    const method = action === 'write' ? 'PUT' : 'GET';
    const secret = resolveSecret('STORAGE_SIGNING_SECRET');
    const signature = crypto
      .createHmac('sha256', secret)
      .update(`${method}:${path}:${expiresAt.getTime()}`)
      .digest('hex');
    return `https://storage.googleapis.com/${this.bucketName}${path}?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Expires=900&X-Goog-Signature=${signature}`;
  }
}
