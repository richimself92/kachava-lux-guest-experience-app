import {
  CatalogImageStoragePort,
  SignedUpload,
} from '../../domain/ports/repository.ports';
import { ObjectUrlSigner } from './object-url-signer';

const UPLOAD_URL_TTL_MS = 15 * 60 * 1000;

/** Catalog photography: signed uploads under `catalog/**`, publicly readable per storage.rules. */
export class CatalogImageStorageAdapter implements CatalogImageStoragePort {
  constructor(private readonly signer: ObjectUrlSigner) {}

  async signUpload(params: { path: string; contentType: string; maxBytes: number }): Promise<SignedUpload> {
    const expiresAt = new Date(Date.now() + UPLOAD_URL_TTL_MS);
    const upload = await this.signer.signWrite(params.path, params.contentType, expiresAt, params.maxBytes);
    return {
      uploadUrl: upload.url,
      method: upload.method,
      headers: upload.headers,
      expiresAt: expiresAt.toISOString(),
    };
  }

  publicUrl(path: string): string {
    return this.signer.publicUrl(path);
  }
}
