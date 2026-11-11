import { BadRequestException } from '@nestjs/common';
import {
  SignedPhotoUpload,
  SignedUrlResult,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import { ObjectUrlSigner } from './object-url-signer';

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
export const MAX_CONCIERGE_UPLOAD_BYTES = 10 * 1024 * 1024; // 10 MB
const SIGNED_URL_TTL_MS = 15 * 60 * 1000;

/** Issues signed URLs for private concierge photos (`private/stays/{stayId}/concierge/...`). */
export class FirebaseStorageSignerAdapter implements StorageSignerPort {
  constructor(private readonly signer: ObjectUrlSigner) {}

  async generateSignedPutUrl(params: {
    stayId: string;
    requestId: string;
    fileName: string;
    contentType: string;
    fileSizeBytes: number;
  }): Promise<SignedPhotoUpload> {
    this.validateUploadConstraints(params.contentType, params.fileSizeBytes);
    const sanitizedName = params.fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const storagePath = `/private/stays/${params.stayId}/concierge/${params.requestId}/${sanitizedName}`;
    const expiresAt = new Date(Date.now() + SIGNED_URL_TTL_MS);
    const upload = await this.signer.signWrite(storagePath, params.contentType, expiresAt, MAX_CONCIERGE_UPLOAD_BYTES);
    return {
      uploadUrl: upload.url,
      method: upload.method,
      headers: upload.headers,
      storagePath,
      expiresAt: expiresAt.toISOString(),
      maxBytes: MAX_CONCIERGE_UPLOAD_BYTES,
    };
  }

  async generateSignedGetUrl(storagePath: string): Promise<SignedUrlResult> {
    const normalizedPath = storagePath.startsWith('/') ? storagePath : `/${storagePath}`;
    const expiresAt = new Date(Date.now() + SIGNED_URL_TTL_MS);
    const downloadUrl = await this.signer.signRead(normalizedPath, expiresAt);
    return {
      downloadUrl,
      storagePath: normalizedPath,
      expiresAt: expiresAt.toISOString(),
    };
  }

  private validateUploadConstraints(contentType: string, fileSizeBytes: number): void {
    if (!ALLOWED_MIME_TYPES.has(contentType)) {
      throw new BadRequestException(
        `Invalid MIME type "${contentType}". Allowed types: image/jpeg, image/png, image/webp.`,
      );
    }
    if (!Number.isFinite(fileSizeBytes) || fileSizeBytes <= 0 || fileSizeBytes > MAX_CONCIERGE_UPLOAD_BYTES) {
      throw new BadRequestException(
        `Invalid file size (${fileSizeBytes} bytes). File must be between 1 byte and 10MB.`,
      );
    }
  }
}
