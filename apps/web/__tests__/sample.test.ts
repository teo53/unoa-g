import { describe, it, expect } from 'vitest';

describe('Sample test suite', () => {
  it('basic arithmetic works', () => {
    expect(1 + 1).toBe(2);
  });

  it('string concatenation works', () => {
    expect('hello' + ' ' + 'world').toBe('hello world');
  });

  it('array operations work', () => {
    const arr = [1, 2, 3];
    expect(arr.length).toBe(3);
    expect(arr.includes(2)).toBe(true);
  });
});
