import { Inject, Injectable } from '@nestjs/common';
import { guestPhotoPaths, PhotoUrlResolver } from '../../domain/guest-stay-view';
import { ConciergeRequest } from '../../domain/models/domain.models';
import { STORAGE_SIGNER_PORT, StorageSignerPort } from '../../domain/ports/repository.ports';

/**
 * Signs short-lived read URLs for the private chat photos a guest view shows. A signing failure
 * is surfaced (500), never replaced by a made-up URL.
 */
@Injectable()
export class GuestPhotoLinks {
  constructor(@Inject(STORAGE_SIGNER_PORT) private readonly signer: StorageSignerPort) {}

  async resolverFor(requests: ConciergeRequest[]): Promise<PhotoUrlResolver> {
    const entries = await Promise.all(
      guestPhotoPaths(requests).map(async (path) => {
        const signed = await this.signer.generateSignedGetUrl(path);
        return [path, signed.downloadUrl ?? null] as const;
      }),
    );
    const urls = new Map(entries);
    return (path) => urls.get(path) ?? null;
  }
}
