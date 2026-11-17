import { changeForMutation, routeTopic } from '../../src/modules/realtime/realtime-routes';

const GUEST = '/api/v1/stays/:guestUuid';
const ADMIN = '/api/v1/admin';

describe('realtime route mapping (ADR-012)', () => {
  describe('routeTopic', () => {
    it.each([
      [`${GUEST}/concierge-requests/:requestId/messages`, 'messages'],
      [`${GUEST}/concierge-requests`, 'requests'],
      [`${GUEST}/bookings`, 'bookings'],
      [`${GUEST}/bookings/:bookingId/cancel`, 'bookings'],
      [`${GUEST}/bookings/:bookingId`, 'bookings'],
      [`${GUEST}/orders/:serviceId`, 'orders'],
      [`${GUEST}/trips`, 'trips'],
      [`${GUEST}/trips/:tripId/cancel`, 'trips'],
      [`${GUEST}/journey`, 'stay'],
      [`${GUEST}/personalization`, 'stay'],
      [`${GUEST}/midstay-checkin`, 'stay'],
      [`${ADMIN}/conversations/:stayId/messages`, 'messages'],
      [`${ADMIN}/conversations/:stayId/read`, 'messages'],
      [`${ADMIN}/notifications/read-all`, 'notifications'],
      [`${ADMIN}/notifications/:id/read`, 'notifications'],
      [`${ADMIN}/requests/:requestId/transition`, 'requests'],
      [`${ADMIN}/tasks`, 'tasks'],
      [`${ADMIN}/tasks/:taskId/transition`, 'tasks'],
      [`${ADMIN}/trips/:tripId`, 'trips'],
      [`${ADMIN}/stays`, 'stay'],
      [`${ADMIN}/stays/:stayId`, 'stay'],
      [`${ADMIN}/services/:serviceId/items/:itemId`, 'catalog'],
      [`${ADMIN}/settings`, 'settings'],
      [`${ADMIN}/villas/:villaId`, 'villas'],
      [`${ADMIN}/staff/:staffId`, 'staff'],
      [`${ADMIN}/transport-providers/:providerId`, 'providers'],
    ])('test_routeTopic_%s_is_%s', (path, topic) => {
      expect(routeTopic(path)).toBe(topic);
    });

    it.each([
      `${ADMIN}/auth/login`,
      `${ADMIN}/uploads/sign`,
      `${GUEST}/concierge-requests/upload-url`,
    ])('test_routeTopic_%s_isSilent', (path) => {
      expect(routeTopic(path)).toBeNull();
    });

    it('test_routeTopic_unknownRoute_isUndefined', () => {
      expect(routeTopic('/api/v1/unknown/thing')).toBeUndefined();
      expect(routeTopic(`${ADMIN}/brand-new`)).toBeUndefined();
    });
  });

  describe('changeForMutation', () => {
    it('test_guestRoute_usesTheGuestStay', () => {
      const change = changeForMutation({
        routePath: `${GUEST}/concierge-requests/:requestId/messages`,
        params: { guestUuid: 'token', requestId: 'r1' },
        guestStayId: 'stay-1',
        responseData: { stayId: 'ignored' },
      });

      expect(change).toEqual({ scope: 'stay', stayId: 'stay-1', topic: 'messages' });
    });

    it('test_adminRoute_stayIdFromRouteParams', () => {
      const change = changeForMutation({
        routePath: `${ADMIN}/conversations/:stayId/messages`,
        params: { stayId: 'stay-2' },
        responseData: { text: 'hi' },
      });

      expect(change).toEqual({ scope: 'stay', stayId: 'stay-2', topic: 'messages' });
    });

    it('test_adminRoute_stayIdFromResponseData', () => {
      const change = changeForMutation({
        routePath: `${ADMIN}/tasks/:taskId/transition`,
        params: { taskId: 't1' },
        responseData: { taskId: 't1', stayId: 'stay-3' },
      });

      expect(change).toEqual({ scope: 'stay', stayId: 'stay-3', topic: 'tasks' });
    });

    it('test_adminCreateStay_stayIdFromNestedStay', () => {
      const change = changeForMutation({
        routePath: `${ADMIN}/stays`,
        params: {},
        responseData: { stay: { stayId: 'stay-4' } },
      });

      expect(change).toEqual({ scope: 'stay', stayId: 'stay-4', topic: 'stay' });
    });

    it('test_adminRoute_withoutStay_isAdminOnly', () => {
      const change = changeForMutation({
        routePath: `${ADMIN}/notifications/read-all`,
        params: {},
        responseData: { updated: 3 },
      });

      expect(change).toEqual({ scope: 'admin-only', topic: 'notifications' });
    });

    it('test_adminTaskWithNullStay_isAdminOnly', () => {
      const change = changeForMutation({
        routePath: `${ADMIN}/tasks`,
        params: {},
        responseData: { taskId: 't2', stayId: null },
      });

      expect(change).toEqual({ scope: 'admin-only', topic: 'tasks' });
    });

    it.each([
      ['catalog', `${ADMIN}/services`],
      ['settings', `${ADMIN}/settings`],
      ['villas', `${ADMIN}/villas/:villaId`],
    ])('test_globalTopic_%s_isGlobal', (topic, routePath) => {
      const change = changeForMutation({ routePath, params: {}, responseData: { stayId: 'x' } });

      expect(change).toEqual({ scope: 'global', topic });
    });

    it.each([
      ['staff', `${ADMIN}/staff/:staffId`],
      ['providers', `${ADMIN}/transport-providers`],
    ])('test_staffOnlyConfig_%s_isAdminOnly', (topic, routePath) => {
      const change = changeForMutation({ routePath, params: {}, responseData: { staffId: 'x' } });

      expect(change).toEqual({ scope: 'admin-only', topic });
    });

    it('test_silentOrUnknownRoute_isNull', () => {
      expect(changeForMutation({ routePath: `${ADMIN}/auth/login`, params: {}, responseData: {} })).toBeNull();
      expect(changeForMutation({ routePath: '/api/v1/nope', params: {}, responseData: {} })).toBeNull();
    });
  });
});
