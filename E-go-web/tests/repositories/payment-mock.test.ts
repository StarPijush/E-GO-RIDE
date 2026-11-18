import { beforeEach, describe, expect, it } from 'vitest';

import { resetDb } from '@/lib/mock/db';
import { createMockPaymentRepository } from '@/lib/mock/payment-mock';

function repository() {
  return createMockPaymentRepository({ latencyMs: 0 });
}

beforeEach(() => {
  window.localStorage.clear();
  resetDb();
});

describe('list', () => {
  it('creates exactly one default cash method', async () => {
    const repo = repository();

    const first = await repo.list('new-user');
    expect(first.ok).toBe(true);
    if (!first.ok) return;
    expect(first.data).toHaveLength(1);
    expect(first.data[0].type).toBe('cash');
    expect(first.data[0].isDefault).toBe(true);
    expect('userId' in first.data[0]).toBe(false);

    const second = await repo.list('new-user');
    expect(second.ok).toBe(true);
    if (!second.ok) return;
    expect(second.data).toHaveLength(1);
  });

  it('keeps the methods of the users apart', async () => {
    const repo = repository();

    await repo.list('user-a');
    await repo.list('user-b');

    const added = await repo.add('user-a', { type: 'upi', label: 'UPI', isDefault: false });
    expect(added.ok).toBe(true);

    const listA = await repo.list('user-a');
    expect(listA.ok).toBe(true);
    if (!listA.ok) return;
    expect(listA.data).toHaveLength(2);

    const listB = await repo.list('user-b');
    expect(listB.ok).toBe(true);
    if (!listB.ok) return;
    expect(listB.data).toHaveLength(1);
    expect(listB.data[0].type).toBe('cash');
  });
});

describe('add and setDefault', () => {
  it('adds a method and moves the default flag', async () => {
    const repo = repository();

    await repo.list('user-1');
    const added = await repo.add('user-1', { type: 'upi', label: 'UPI', isDefault: false });
    expect(added.ok).toBe(true);
    if (!added.ok) return;
    expect(added.data.isDefault).toBe(false);

    const listed = await repo.list('user-1');
    expect(listed.ok).toBe(true);
    if (!listed.ok) return;
    expect(listed.data).toHaveLength(2);
    expect(listed.data[0].type).toBe('cash');
    expect(listed.data[0].isDefault).toBe(true);

    const changed = await repo.setDefault('user-1', added.data.id);
    expect(changed.ok).toBe(true);
    if (!changed.ok) return;
    expect(changed.data.filter((method) => method.isDefault)).toHaveLength(1);
    expect(changed.data[0].id).toBe(added.data.id);
    expect(changed.data[0].isDefault).toBe(true);
  });

  it('fails for an unknown method', async () => {
    const repo = repository();
    await repo.list('user-1');

    const result = await repo.setDefault('user-1', 'does-not-exist');
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('not_found');
  });
});

describe('remove', () => {
  it('never removes the cash method', async () => {
    const repo = repository();

    const listed = await repo.list('user-1');
    expect(listed.ok).toBe(true);
    if (!listed.ok) return;

    const result = await repo.remove('user-1', listed.data[0].id);
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe('invalid_transition');
      expect(result.error.message).toBe(
        'Cash is the default demo payment method and cannot be removed.',
      );
    }
  });

  it('fails for an unknown method', async () => {
    const repo = repository();
    await repo.list('user-1');

    const result = await repo.remove('user-1', 'does-not-exist');
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('not_found');
  });

  it('promotes the cash method when the default is removed', async () => {
    const repo = repository();

    await repo.list('user-1');
    const added = await repo.add('user-1', { type: 'upi', label: 'UPI', isDefault: true });
    expect(added.ok).toBe(true);
    if (!added.ok) return;

    const removed = await repo.remove('user-1', added.data.id);
    expect(removed.ok).toBe(true);

    const list = await repo.list('user-1');
    expect(list.ok).toBe(true);
    if (!list.ok) return;
    expect(list.data).toHaveLength(1);
    expect(list.data[0].type).toBe('cash');
    expect(list.data[0].isDefault).toBe(true);
  });
});
