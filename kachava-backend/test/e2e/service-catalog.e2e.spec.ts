import request from 'supertest';
import { createTestApp, TestApp } from '../support/test-app';

const API = '/api/v1/admin';

const minimalService = (overrides: Record<string, unknown> = {}) => ({
  kind: 'EXPERIENCE',
  section: 'EXPERIENCES',
  usageType: 'BOOKING',
  name: { en: 'Cenote swim', es: 'Nado en cenote' },
  pricing: { mode: 'PER_PERSON', amount: 80, chargeToFolio: true },
  ...overrides,
});

describe('Service catalog admin API', () => {
  let t: TestApp;
  let admin: Record<string, string>;

  beforeEach(async () => {
    t = await createTestApp();
    admin = await t.adminHeaders();
  });

  afterEach(() => t.close());

  async function createService(overrides: Record<string, unknown> = {}) {
    const res = await request(t.server()).post(`${API}/services`).set(admin).send(minimalService(overrides));
    expect(res.status).toBe(201);
    return res.body.data;
  }

  async function activate(serviceId: string, extra: Record<string, unknown> = {}) {
    return request(t.server())
      .patch(`${API}/services/${serviceId}`)
      .set(admin)
      .send({
        shortDescription: { en: 'Short', es: 'Corta' },
        cover: { storagePath: `catalog/services/${serviceId}.jpg`, alt: { en: 'Cover', es: 'Portada' }, usageRightsConfirmed: true },
        status: 'ACTIVE',
        ...extra,
      });
  }

  describe('create and defaults', () => {
    it('test_listServices_emptyDatabase_returnsEmptyPage', async () => {
      const res = await request(t.server()).get(`${API}/services`).set(admin);

      expect(res.status).toBe(200);
      expect(res.body).toMatchObject({ success: true, data: [], meta: { page: 1, pageSize: 25, total: 0 } });
    });

    it('test_createService_minimal_isDisabledWithEmptyTemplateAndAudit', async () => {
      const service = await createService();

      expect(service).toMatchObject({
        serviceId: expect.any(String),
        kind: 'EXPERIENCE',
        status: 'DISABLED',
        name: { en: 'Cenote swim', es: 'Nado en cenote' },
        shortDescription: { en: '', es: '' },
        pricing: { mode: 'PER_PERSON', amount: 80, currency: 'USD', chargeToFolio: true, note: { en: '', es: '' } },
        availability: { weekdays: [], timeSlots: [], minGuests: null, offeredWhen: null },
        cover: null,
        gallery: [],
        experience: { itinerary: [], languages: [], minAge: null },
        bar: null,
        transport: null,
        createdBy: 'admin-service@test.local',
      });
    });

    it('test_createService_fullTypeSpecificModel_isPersisted', async () => {
      const service = await createService({
        kind: 'BAR',
        section: 'DINING',
        usageType: 'ORDER',
        category: 'Bar',
        tags: ['cocktails'],
        featured: true,
        order: 3,
        bar: { ageConfirmationRequired: true },
        availability: { weekdays: ['FRI', 'SAT'], timeSlots: [{ start: '17:00', end: '23:00' }], blockedDates: ['2026-12-24'] },
        guestForm: { notes: true },
        guestInfo: { location: { en: 'Pool deck', es: 'Terraza' } },
        operation: { responsibleDepartment: 'CULINARY', requiresConfirmation: true, internalInstructions: 'Check ID' },
        pricing: { mode: 'PER_UNIT', chargeToFolio: true, note: { en: 'Per drink', es: 'Por bebida' } },
      });

      const stored = await request(t.server()).get(`${API}/services/${service.serviceId}`).set(admin);

      expect(stored.body.data).toEqual(service);
      expect(service).toMatchObject({
        bar: { ageConfirmationRequired: true },
        experience: null,
        availability: { weekdays: ['FRI', 'SAT'], blockedDates: ['2026-12-24'] },
        guestForm: { notes: true, date: false },
        operation: { responsibleDepartment: 'CULINARY', internalInstructions: 'Check ID' },
      });
    });

    it.each([
      [{ kind: 'YACHT' }],
      [{ section: 'SPA' }],
      [{ usageType: 'BUY' }],
      [{ pricing: { mode: 'FREE' } }],
      [{ pricing: { mode: 'FIXED', amount: -1 } }],
      [{ availability: { weekdays: ['MONDAY'] } }],
      [{ availability: { timeSlots: [{ start: '9am', end: '10:00' }] } }],
      [{ gallery: Array.from({ length: 9 }, (_, i) => ({ storagePath: `catalog/x/${i}.jpg` })) }],
      [{ name: undefined }],
    ])('test_createService_invalidShape_%j_is400', async (overrides) => {
      const res = await request(t.server()).post(`${API}/services`).set(admin).send(minimalService(overrides));

      expect(res.status).toBe(400);
    });

    it.each([
      [{ bar: { ageConfirmationRequired: true } }],
      [{ pricing: { mode: 'INCLUDED', amount: 10 } }],
      [{ availability: { minGuests: 6, maxGuests: 2 } }],
      [{ name: { en: '', es: '' } }],
      [{ status: 'ACTIVE' }],
      [{ operation: { providerId: 'missing-provider' } }],
    ])('test_createService_businessRule_%j_is422', async (overrides) => {
      const res = await request(t.server()).post(`${API}/services`).set(admin).send(minimalService(overrides));

      expect(res.status).toBe(422);
    });

    it('test_createTransportService_airportsMustComeFromSettings', async () => {
      const transport = { kind: 'TRANSPORT', section: 'TRANSPORTATION', usageType: 'TRIP' };
      const unknown = await request(t.server())
        .post(`${API}/services`)
        .set(admin)
        .send(minimalService({ ...transport, transport: { airportCodes: ['CUN'] } }));
      await request(t.server())
        .patch(`${API}/settings`)
        .set(admin)
        .send({ airports: [{ code: 'CUN', name: 'Cancun', departureBufferHours: 3 }] });
      const known = await request(t.server())
        .post(`${API}/services`)
        .set(admin)
        .send(minimalService({ ...transport, transport: { airportCodes: ['CUN'], priceBasis: 'PER_VEHICLE' } }));

      expect(unknown.status).toBe(422);
      expect(known.status).toBe(201);
      expect(known.body.data.transport).toEqual({ airportCodes: ['CUN'], priceBasis: 'PER_VEHICLE', flightDetailsRequired: true });
    });

    it('test_createService_existingProvider_isLinked', async () => {
      const provider = await request(t.server()).post(`${API}/transport-providers`).set(admin).send({ name: 'Guides Co' });

      const service = await createService({ operation: { providerId: provider.body.data.providerId } });

      expect(service.operation.providerId).toBe(provider.body.data.providerId);
    });
  });

  describe('activation rule and updates', () => {
    it('test_activate_withoutCoverOrSpanishText_is422WithReasons', async () => {
      const service = await createService({ name: { en: 'Only English' } });

      const res = await request(t.server()).patch(`${API}/services/${service.serviceId}`).set(admin).send({ status: 'ACTIVE' });

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('cover image is required');
      expect(res.body.message).toContain('name.es is required');
      expect(res.body.message).toContain('shortDescription.en is required');
    });

    it('test_activate_withOwnCoverAndBilingualText_succeeds', async () => {
      const service = await createService();

      const res = await activate(service.serviceId);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('ACTIVE');
      expect(res.body.data.id).toBe(service.serviceId);
      expect(res.body.data.cover).toEqual({
        storagePath: `catalog/services/${service.serviceId}.jpg`,
        usageRightsConfirmed: true,
        alt: { en: 'Cover', es: 'Portada' },
        url: `https://public.test/catalog/services/${service.serviceId}.jpg`,
      });
    });

    it('test_activeService_removingCover_is422', async () => {
      const service = await createService();
      await activate(service.serviceId);

      const res = await request(t.server())
        .patch(`${API}/services/${service.serviceId}`)
        .set(admin)
        .send({ cover: null });

      expect(res.status).toBe(422);
    });

    it('test_patch_imageOutsideCatalogUploads_is422', async () => {
      const service = await createService();

      const res = await request(t.server())
        .patch(`${API}/services/${service.serviceId}`)
        .set(admin)
        .send({ cover: { storagePath: 'private/stays/s1/cover.jpg' } });

      expect(res.status).toBe(422);
    });

    it('test_patch_mergesNestedTextAndKeepsOtherFields', async () => {
      const service = await createService();

      const res = await request(t.server())
        .patch(`${API}/services/${service.serviceId}`)
        .set(admin)
        .send({ name: { es: 'Cenote' }, pricing: { amount: 95 }, experience: { minAge: 12, languages: ['en', 'es'] } });

      expect(res.status).toBe(200);
      expect(res.body.data).toMatchObject({
        name: { en: 'Cenote swim', es: 'Cenote' },
        pricing: { mode: 'PER_PERSON', amount: 95, chargeToFolio: true },
        experience: { minAge: 12, languages: ['en', 'es'], itinerary: [] },
      });
    });

    it('test_patch_changingKind_is422', async () => {
      const service = await createService();

      const res = await request(t.server()).patch(`${API}/services/${service.serviceId}`).set(admin).send({ kind: 'BAR' });

      expect(res.status).toBe(422);
    });

    it('test_patch_unknownService_is404', async () => {
      const res = await request(t.server()).patch(`${API}/services/missing`).set(admin).send({ order: 1 });

      expect(res.status).toBe(404);
    });
  });

  describe('list filters, search, sort and pagination', () => {
    beforeEach(async () => {
      const a = await createService({ name: { en: 'Breakfast', es: 'Desayuno' }, kind: 'BREAKFAST', section: 'DINING', order: 2 });
      await activate(a.serviceId);
      await createService({ name: { en: 'Aromatherapy', es: 'Aromaterapia' }, kind: 'WELLNESS', section: 'WELLNESS', order: 1 });
      await createService({ name: { en: 'Villa stocking', es: 'Abastecimiento' }, kind: 'VILLA_STOCKING', section: 'IN_VILLA', usageType: 'ORDER', order: 3 });
    });

    const names = (res: request.Response) => res.body.data.map((s: { name: { en: string } }) => s.name.en);

    it('test_list_defaultSortIsOrderAscending', async () => {
      const res = await request(t.server()).get(`${API}/services`).set(admin);

      expect(names(res)).toEqual(['Aromatherapy', 'Breakfast', 'Villa stocking']);
      expect(res.body.meta).toMatchObject({ page: 1, pageSize: 25, total: 3 });
    });

    it('test_list_filtersBySectionStatusAndUsageType', async () => {
      const dining = await request(t.server()).get(`${API}/services?section=DINING`).set(admin);
      const active = await request(t.server()).get(`${API}/services?status=ACTIVE`).set(admin);
      const orders = await request(t.server()).get(`${API}/services?usageType=ORDER`).set(admin);

      expect(names(dining)).toEqual(['Breakfast']);
      expect(names(active)).toEqual(['Breakfast']);
      expect(names(orders)).toEqual(['Villa stocking']);
    });

    it('test_list_searchesBothLanguagesIgnoringAccents', async () => {
      const res = await request(t.server()).get(`${API}/services?q=DESAYUNO`).set(admin);

      expect(names(res)).toEqual(['Breakfast']);
    });

    it('test_list_sortsByNameAndPaginates', async () => {
      const page2 = await request(t.server()).get(`${API}/services?sort=name:desc&pageSize=2&page=2`).set(admin);

      expect(names(page2)).toEqual(['Aromatherapy']);
      expect(page2.body.meta).toMatchObject({ page: 2, pageSize: 2, total: 3 });
    });

    it.each([['sort=price:asc'], ['pageSize=500'], ['status=DRAFT']])('test_list_invalid_%s_is400', async (qs) => {
      expect((await request(t.server()).get(`${API}/services?${qs}`).set(admin)).status).toBe(400);
    });
  });

  describe('items', () => {
    it('test_items_createListFilterSortAndPatch', async () => {
      const service = await createService({ kind: 'BAR', section: 'DINING', usageType: 'ORDER', pricing: { mode: 'PER_UNIT' } });
      const base = `${API}/services/${service.serviceId}/items`;
      const mojito = await request(t.server())
        .post(base)
        .set(admin)
        .send({ name: { en: 'Mojito', es: 'Mojito' }, priceUSD: 14, category: 'Cocktails', allergens: ['mint'], status: 'ACTIVE', order: 2 });
      await request(t.server()).post(base).set(admin).send({ name: { en: 'Lemonade', es: 'Limonada' }, priceUSD: 6, category: 'Soft', order: 1 });

      const all = await request(t.server()).get(base).set(admin);
      const byPrice = await request(t.server()).get(`${base}?sort=priceUSD:desc`).set(admin);
      const active = await request(t.server()).get(`${base}?status=ACTIVE`).set(admin);
      const soft = await request(t.server()).get(`${base}?category=Soft`).set(admin);
      const search = await request(t.server()).get(`${base}?q=limon`).set(admin);
      const patched = await request(t.server())
        .patch(`${base}/${mojito.body.data.itemId}`)
        .set(admin)
        .send({ priceUSD: 15, dietaryTags: ['vegan'] });

      expect(mojito.status).toBe(201);
      expect(mojito.body.data).toMatchObject({ id: mojito.body.data.itemId, serviceId: service.serviceId, allergens: ['mint'], status: 'ACTIVE' });
      expect(all.body.data.map((i: { name: { en: string } }) => i.name.en)).toEqual(['Lemonade', 'Mojito']);
      expect(all.body.meta).toMatchObject({ page: 1, pageSize: 25, total: 2 });
      expect(byPrice.body.data[0].priceUSD).toBe(14);
      expect(active.body.meta.total).toBe(1);
      expect(soft.body.meta.total).toBe(1);
      expect(search.body.data[0].name.es).toBe('Limonada');
      expect(patched.body.data).toMatchObject({ priceUSD: 15, dietaryTags: ['vegan'], allergens: ['mint'] });
    });

    it('test_items_vehicleCapacityAndOwnImage', async () => {
      const service = await createService({ kind: 'TRANSPORT', section: 'TRANSPORTATION', usageType: 'TRIP' });

      const res = await request(t.server())
        .post(`${API}/services/${service.serviceId}/items`)
        .set(admin)
        .send({
          name: { en: 'Suburban', es: 'Suburban' },
          capacity: { passengers: 6, luggage: 6 },
          image: { storagePath: 'catalog/services/items/a.webp', alt: { en: 'Van' } },
        });

      expect(res.status).toBe(201);
      expect(res.body.data.capacity).toEqual({ passengers: 6, luggage: 6 });
      expect(res.body.data.image).toMatchObject({ alt: { en: 'Van', es: '' }, url: expect.stringContaining('a.webp') });
    });

    it('test_items_activeWithoutSpanishName_is422', async () => {
      const service = await createService();

      const res = await request(t.server())
        .post(`${API}/services/${service.serviceId}/items`)
        .set(admin)
        .send({ name: { en: 'Only English' }, status: 'ACTIVE' });

      expect(res.status).toBe(422);
    });

    it('test_items_imageOutsideCatalogUploads_is422', async () => {
      const service = await createService();

      const res = await request(t.server())
        .post(`${API}/services/${service.serviceId}/items`)
        .set(admin)
        .send({ name: { en: 'A', es: 'A' }, image: { storagePath: 'https://evil.test/a.jpg' } });

      expect(res.status).toBe(422);
    });

    it('test_items_unknownServiceOrItem_is404', async () => {
      const service = await createService();

      const unknownService = await request(t.server()).post(`${API}/services/missing/items`).set(admin).send({ name: { en: 'A' } });
      const listUnknown = await request(t.server()).get(`${API}/services/missing/items`).set(admin);
      const unknownItem = await request(t.server()).patch(`${API}/services/${service.serviceId}/items/missing`).set(admin).send({ order: 1 });

      expect([unknownService.status, listUnknown.status, unknownItem.status]).toEqual([404, 404, 404]);
    });
  });

  describe('roles', () => {
    it('test_catalogWrites_nonAdmin_are403_readsAllowed', async () => {
      const service = await createService();
      const concierge = await t.staffHeaders('CONCIERGE_STAFF');

      const statuses = [
        (await request(t.server()).post(`${API}/services`).set(concierge).send(minimalService())).status,
        (await request(t.server()).patch(`${API}/services/${service.serviceId}`).set(concierge).send({ order: 1 })).status,
        (await request(t.server()).post(`${API}/services/${service.serviceId}/items`).set(concierge).send({ name: { en: 'A' } })).status,
        (await request(t.server()).post(`${API}/uploads/sign`).set(concierge).send({ folder: 'services', contentType: 'image/png', sizeBytes: 10 })).status,
        (await request(t.server()).get(`${API}/services`).set(concierge)).status,
        (await request(t.server()).get(`${API}/services/${service.serviceId}/items`).set(concierge)).status,
      ];

      expect(statuses).toEqual([403, 403, 403, 403, 200, 200]);
    });

    it('test_catalog_withoutToken_is401', async () => {
      expect((await request(t.server()).get(`${API}/services`)).status).toBe(401);
    });
  });

  describe('image upload signing (POST /admin/uploads/sign)', () => {
    const sign = (body: Record<string, unknown>) => request(t.server()).post(`${API}/uploads/sign`).set(admin).send(body);

    it('test_sign_returnsSignedUrlUnderCatalogFolder', async () => {
      const res = await sign({ fileName: 'pool.webp', folder: 'services', contentType: 'image/webp', sizeBytes: 1024 });

      expect(res.status).toBe(201);
      expect(res.body.data).toMatchObject({
        method: 'PUT',
        headers: { 'Content-Type': 'image/webp' },
        maxBytes: 5242880,
        expiresAt: expect.any(String),
      });
      expect(res.body.data.storagePath).toMatch(/^catalog\/services\/[0-9a-f-]{36}\.webp$/);
      expect(res.body.data.uploadUrl).toBe(`https://signed.test/${res.body.data.storagePath}`);
      expect(res.body.data.publicUrl).toBe(`https://public.test/${res.body.data.storagePath}`);
      expect(t.signer.signedWrites).toEqual([
        { path: res.body.data.storagePath, contentType: 'image/webp', maxBytes: 5242880 },
      ]);
    });

    it('test_sign_thenSaveOnItemAndAsServiceCover', async () => {
      const service = await createService();
      const item = await request(t.server()).post(`${API}/services/${service.serviceId}/items`).set(admin).send({ name: { en: 'A', es: 'A' } });

      const signed = await sign({ fileName: 'a.jpg', folder: 'services/items', contentType: 'image/jpeg', sizeBytes: 5242880 });
      const path = signed.body.data.storagePath;
      const savedItem = await request(t.server())
        .patch(`${API}/services/${service.serviceId}/items/${item.body.data.itemId}`)
        .set(admin)
        .send({ image: { storagePath: path, alt: { en: 'A', es: 'A' }, usageRightsConfirmed: true } });
      const savedService = await request(t.server())
        .patch(`${API}/services/${service.serviceId}`)
        .set(admin)
        .send({ cover: { storagePath: path }, gallery: [{ storagePath: path, alt: { es: 'Galería' } }] });

      expect(path).toMatch(/^catalog\/services\/items\/.+\.jpg$/);
      expect(savedItem.status).toBe(200);
      expect(savedItem.body.data.image).toEqual({
        storagePath: path, alt: { en: 'A', es: 'A' }, usageRightsConfirmed: true, url: `https://public.test/${path}`,
      });
      expect(savedService.body.data.cover).toMatchObject({ storagePath: path, usageRightsConfirmed: false });
      expect(savedService.body.data.gallery).toEqual([
        { storagePath: path, alt: { en: '', es: 'Galería' }, usageRightsConfirmed: false, url: `https://public.test/${path}` },
      ]);
    });

    it.each([
      [{ folder: 'services', contentType: 'image/gif', sizeBytes: 10 }],
      [{ folder: 'services', contentType: 'application/pdf', sizeBytes: 10 }],
      [{ folder: 'services', contentType: 'image/png', sizeBytes: 5242881 }],
      [{ folder: 'services', contentType: 'image/png', sizeBytes: 0 }],
      [{ folder: 'services', contentType: 'image/png' }],
      [{ contentType: 'image/png', sizeBytes: 10 }],
      [{ folder: '../private', contentType: 'image/png', sizeBytes: 10 }],
      [{ folder: 'a/b/c/d', contentType: 'image/png', sizeBytes: 10 }],
    ])('test_sign_invalidRequest_%j_is400', async (body) => {
      const res = await sign(body);

      expect(res.status).toBe(400);
      expect(t.signer.signedWrites).toEqual([]);
    });
  });

  describe('guest catalog (GET /catalog/services)', () => {
    it('test_guestCatalog_returnsOnlyActiveServicesWithActiveItems_guestSafe', async () => {
      const active = await createService();
      await activate(active.serviceId, { operation: { internalInstructions: 'staff secret' } });
      await createService({ name: { en: 'Hidden', es: 'Oculto' } });
      const items = `${API}/services/${active.serviceId}/items`;
      await request(t.server()).post(items).set(admin).send({ name: { en: 'Visible', es: 'Visible' }, status: 'ACTIVE' });
      await request(t.server()).post(items).set(admin).send({ name: { en: 'Off', es: 'Apagado' } });

      const res = await request(t.server()).get('/api/v1/catalog/services');

      expect(res.status).toBe(200);
      expect(res.body.meta).toMatchObject({ page: 1, pageSize: 25, total: 1 });
      const [service] = res.body.data;
      expect(service.serviceId).toBe(active.serviceId);
      expect(service.items.map((i: { name: { en: string } }) => i.name.en)).toEqual(['Visible']);
      expect(service).not.toHaveProperty('operation');
      expect(service).not.toHaveProperty('createdBy');
      expect(service.id).toBe(active.serviceId);
      expect(service.cover.url).toBe(`https://public.test/catalog/services/${active.serviceId}.jpg`);
      expect(JSON.stringify(res.body)).not.toContain('staff secret');
    });

    it('test_guestCatalog_filtersBySection', async () => {
      const dining = await createService({ kind: 'BREAKFAST', section: 'DINING' });
      await activate(dining.serviceId);
      const experience = await createService();
      await activate(experience.serviceId);

      const res = await request(t.server()).get('/api/v1/catalog/services?section=DINING');
      const invalid = await request(t.server()).get('/api/v1/catalog/services?section=YACHT');

      expect(res.body.data.map((s: { serviceId: string }) => s.serviceId)).toEqual([dining.serviceId]);
      expect(invalid.status).toBe(400);
    });

    it.each(['/api/v1/catalog/experiences', '/api/v1/catalog/larder', '/api/v1/catalog/yacht', `${API}/catalog/larder`, `${API}/catalog/experiences`])(
      'test_legacyCatalogRoute_%s_isGone',
      async (path) => {
        expect((await request(t.server()).get(path).set(admin)).status).toBe(404);
      },
    );
  });
});
