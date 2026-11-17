import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import {
  CATALOG_IMAGE_STORAGE_PORT,
  CatalogImageStoragePort,
  SignedUpload,
} from '../../domain/ports/repository.ports';
import { CATALOG_IMAGE_MAX_BYTES, CATALOG_IMAGE_TYPES, SignCatalogUploadDto } from './dto/upload.dto';

export interface CatalogUploadTicket extends SignedUpload {
  /** Save this path as `storagePath` of a service `cover`/`gallery[]` image or an item `image`. */
  storagePath: string;
  publicUrl: string;
  maxBytes: number;
}

/**
 * Signs direct-to-Storage uploads to `catalog/{folder}/{uuid}.{ext}`. The client sends the bytes
 * with `method` and `headers` (PUT on Cloud Storage, POST on the local emulator).
 */
@Injectable()
export class CatalogUploadsService {
  constructor(@Inject(CATALOG_IMAGE_STORAGE_PORT) private readonly storage: CatalogImageStoragePort) {}

  async sign(dto: SignCatalogUploadDto): Promise<CatalogUploadTicket> {
    const storagePath = `catalog/${dto.folder}/${crypto.randomUUID()}.${CATALOG_IMAGE_TYPES[dto.contentType]}`;
    const upload = await this.storage.signUpload({
      path: storagePath,
      contentType: dto.contentType,
      maxBytes: CATALOG_IMAGE_MAX_BYTES,
    });
    return {
      ...upload,
      storagePath,
      publicUrl: this.storage.publicUrl(storagePath),
      maxBytes: CATALOG_IMAGE_MAX_BYTES,
    };
  }
}
