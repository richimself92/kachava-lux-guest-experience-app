export * from './stay.models';
export * from './operations.models';

export interface CatalogVilla {
  villaId: string;
  villaName: string;
  suiteType?: string;
  maxGuests?: string;
  wifiSsid?: string;
  wifiPasscode?: string;
}
