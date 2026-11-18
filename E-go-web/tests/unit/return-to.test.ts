import { describe, expect, it } from 'vitest';

import { sanitizeReturnTo } from '@/lib/utils/return-to';

describe('sanitizeReturnTo', () => {
  it('keeps an internal path', () => {
    expect(sanitizeReturnTo('/home')).toBe('/home');
    expect(sanitizeReturnTo('/ride-details/abc')).toBe('/ride-details/abc');
  });

  it('keeps the query string', () => {
    expect(sanitizeReturnTo('/my-rides?tab=completed')).toBe('/my-rides?tab=completed');
  });

  it('rejects everything that could leave the app', () => {
    expect(sanitizeReturnTo('//evil.com')).toBe('/home');
    expect(sanitizeReturnTo('https://evil')).toBe('/home');
    expect(sanitizeReturnTo('/\\evil')).toBe('/home');
    expect(sanitizeReturnTo('/%2F%2Fevil')).toBe('/home');
    expect(sanitizeReturnTo('javascript:alert(1)')).toBe('/home');
    expect(sanitizeReturnTo('#x')).toBe('/home');
  });

  it('rejects an unknown route', () => {
    expect(sanitizeReturnTo('/unknown')).toBe('/home');
  });

  it('rejects an empty or oversized path', () => {
    expect(sanitizeReturnTo('')).toBe('/home');
    expect(sanitizeReturnTo('/unknown', '/my-rides')).toBe('/my-rides');
    expect(sanitizeReturnTo(`/${'a'.repeat(300)}`)).toBe('/home');
  });

  it('never throws', () => {
    expect(() => sanitizeReturnTo('/%')).not.toThrow();
    expect(sanitizeReturnTo('/%')).toBe('/home');
    expect(sanitizeReturnTo(null)).toBe('/home');
    expect(sanitizeReturnTo(undefined)).toBe('/home');
  });
});
