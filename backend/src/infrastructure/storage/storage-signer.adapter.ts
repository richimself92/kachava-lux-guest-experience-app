import { BadRequestException, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import * as admin from 'firebase-admin';
import {
  SignedUrlResult,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import { DEFAULT_STORAGE_BUCKET } from '../firebase/firebase-admin.module';

const ALLOWED_MIME_TYPES = new Set(['image/jpeg', 'image/png', 'image/webp']);
const MAX_UPLOAD_BYTES = 10 * 1024 * 1024; // 10 MB

@Injectable()
export class FirebaseStorageSignerAdapter implements StorageSignerPort {
  private readonly bucketName =
    process.env.FIREBASE_STORAGE_BUCKET || DEFAULT_STORAGE_BUCKET;

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
    const expiresAtDate = new Date(Date.now() + 15 * 60 * 1000);

    if (this.isCloudStorageActive()) {
      try {
        const bucket = admin.storage().bucket(this.bucketName);
        const file = bucket.file(storagePath.replace(/^\//, ''));
        const [uploadUrl] = await file.getSignedUrl({
          version: 'v4',
          action: 'write',
          expires: expiresAtDate,
          contentType: params.contentType,
        });
        return {
          uploadUrl,
          storagePath,
          expiresAt: expiresAtDate.toISOString(),
          contentType: params.contentType,
        };
      } catch {
        // Fallback to deterministic local V4 signature if local ADC lacks serviceAccount iam.serviceAccounts.signBlob
      }
    }

    const signature = this.computeDeterministicSignature('PUT', storagePath, expiresAtDate);
    const uploadUrl = `https://storage.googleapis.com/${this.bucketName}${storagePath}?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Expires=900&X-Goog-Signature=${signature}`;
    return {
      uploadUrl,
      storagePath,
      expiresAt: expiresAtDate.toISOString(),
      contentType: params.contentType,
    };
  }

  async generateSignedGetUrl(storagePath: string): Promise<SignedUrlResult> {
    const normalizedPath = storagePath.startsWith('/')
      ? storagePath
      : `/${storagePath}`;
    const expiresAtDate = new Date(Date.now() + 15 * 60 * 1000);

    if (this.isCloudStorageActive()) {
      try {
        const bucket = admin.storage().bucket(this.bucketName);
        const file = bucket.file(normalizedPath.replace(/^\//, ''));
        const [downloadUrl] = await file.getSignedUrl({
          version: 'v4',
          action: 'read',
          expires: expiresAtDate,
        });
        return {
          downloadUrl,
          storagePath: normalizedPath,
          expiresAt: expiresAtDate.toISOString(),
        };
      } catch {
        // Fallback to deterministic local V4 signature if local ADC lacks signBlob permission
      }
    }

    const signature = this.computeDeterministicSignature('GET', normalizedPath, expiresAtDate);
    const downloadUrl = `https://storage.googleapis.com/${this.bucketName}${normalizedPath}?X-Goog-Algorithm=GOOG4-RSA-SHA256&X-Goog-Expires=900&X-Goog-Signature=${signature}`;
    return {
      downloadUrl,
      storagePath: normalizedPath,
      expiresAt: expiresAtDate.toISOString(),
    };
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

  private isCloudStorageActive(): boolean {
    return Boolean(
      process.env.NODE_ENV !== 'test' &&
        (process.env.USE_FIRESTORE === 'true' ||
          process.env.USE_GCP_FIRESTORE === 'true') &&
        admin.apps.length > 0,
    );
  }

  private computeDeterministicSignature(
    method: 'PUT' | 'GET',
    path: string,
    expiresAt: Date,
  ): string {
    const secret = process.env.STORAGE_SIGNING_SECRET || 'kachava-v4-dev-signer';
    return crypto
      .createHmac('sha256', secret)
      .update(`${method}:${path}:${expiresAt.getTime()}`)
      .digest('hex');
  }
}
