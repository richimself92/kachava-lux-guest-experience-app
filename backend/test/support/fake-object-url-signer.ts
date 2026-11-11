import { ObjectUrlSigner, SignedWrite } from '../../src/infrastructure/storage/object-url-signer';

/** Test-only signer: deterministic URLs, records every write it signed. */
export class FakeObjectUrlSigner implements ObjectUrlSigner {
  readonly signedWrites: Array<{ path: string; contentType: string; maxBytes?: number }> = [];

  async signWrite(path: string, contentType: string, _expiresAt: Date, maxBytes?: number): Promise<SignedWrite> {
    this.signedWrites.push({ path, contentType, maxBytes });
    return {
      url: `https://signed.test/${path.replace(/^\//, '')}`,
      method: 'PUT',
      headers: { 'Content-Type': contentType },
    };
  }

  async signRead(path: string): Promise<string> {
    return `https://signed.test/read/${path.replace(/^\//, '')}`;
  }

  publicUrl(path: string): string {
    return `https://public.test/${path}`;
  }
}
