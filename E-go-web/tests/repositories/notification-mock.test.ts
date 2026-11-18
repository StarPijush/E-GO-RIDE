import { beforeEach, describe, expect, it } from 'vitest';

import { createEmptyDb, resetDb, saveDb } from '@/lib/mock/db';
import { createMockNotificationRepository } from '@/lib/mock/notification-mock';
import { ensureDemoSeedData } from '@/lib/mock/seeds';

const DEMO_USER_ID = 'demo-ego-001';

function repository() {
  return createMockNotificationRepository({ latencyMs: 0 });
}

beforeEach(() => {
  window.localStorage.clear();
  resetDb();
});

describe('list', () => {
  it('returns the notifications of the user, newest first', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const list = await repo.list(DEMO_USER_ID);

    expect(list.ok).toBe(true);
    if (!list.ok) return;
    expect(list.data).toHaveLength(4);
    expect(list.data.map((notification) => notification.id)).toEqual([
      'notif-demo-001',
      'notif-demo-002',
      'notif-demo-003',
      'notif-demo-004',
    ]);
    expect(list.data.filter((notification) => !notification.read)).toHaveLength(2);
    for (const notification of list.data) {
      expect('userId' in notification).toBe(false);
    }
  });

  it('returns nothing for an unknown user', async () => {
    const repo = repository();

    const list = await repo.list('other-user');

    expect(list.ok).toBe(true);
    if (!list.ok) return;
    expect(list.data).toHaveLength(0);
  });
});

describe('markRead', () => {
  it('marks a single notification as read', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const result = await repo.markRead(DEMO_USER_ID, 'notif-demo-001');

    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.find((n) => n.id === 'notif-demo-001')?.read).toBe(true);
    expect(result.data.filter((notification) => !notification.read)).toHaveLength(1);
  });

  it('fails for another user and for an unknown id', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();

    const foreign = await repo.markRead('other-user', 'notif-demo-001');
    expect(foreign.ok).toBe(false);
    if (!foreign.ok) expect(foreign.error.code).toBe('not_found');

    const unknown = await repo.markRead(DEMO_USER_ID, 'does-not-exist');
    expect(unknown.ok).toBe(false);
    if (!unknown.ok) expect(unknown.error.code).toBe('not_found');
  });
});

describe('markAllRead', () => {
  it('marks every notification of the user as read', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const result = await repo.markAllRead(DEMO_USER_ID);

    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data).toHaveLength(4);
    expect(result.data.filter((notification) => !notification.read)).toHaveLength(0);
  });
});
