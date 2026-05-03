import { describe, it, expect, beforeEach } from 'vitest';
import {
  MemoryCacheAdapter,
  ISRCacheManager,
  type CacheEntry,
} from '../cache';

describe('MemoryCacheAdapter', () => {
  let adapter: MemoryCacheAdapter;

  beforeEach(() => {
    adapter = new MemoryCacheAdapter(10);
  });

  it('should store and retrieve values', async () => {
    await adapter.set('key1', '<html>test</html>');
    const entry = await adapter.get('key1');

    expect(entry).not.toBeNull();
    expect(entry!.value).toBe('<html>test</html>');
    expect(entry!.generatedAt).toBeLessThanOrEqual(Date.now());
  });

  it('should return null for missing keys', async () => {
    const entry = await adapter.get('nonexistent');
    expect(entry).toBeNull();
  });

  it('should delete entries', async () => {
    await adapter.set('key1', 'value1');
    await adapter.delete('key1');
    const entry = await adapter.get('key1');
    expect(entry).toBeNull();
  });

  it('should set revalidateAfter based on revalidate option', async () => {
    const before = Date.now();
    await adapter.set('key1', 'value1', { revalidate: 60 });
    const entry = await adapter.get('key1');

    expect(entry).not.toBeNull();
    expect(entry!.revalidateAfter).toBeGreaterThan(before + 59000);
    expect(entry!.revalidateAfter).toBeLessThanOrEqual(before + 61000);
  });

  it('should evict oldest entries when at capacity', async () => {
    // Fill cache to capacity
    for (let i = 0; i < 10; i++) {
      await adapter.set(`key${i}`, `value${i}`);
    }

    // All 10 entries should exist
    for (let i = 0; i < 10; i++) {
      expect(await adapter.get(`key${i}`)).not.toBeNull();
    }

    // Add one more - should evict key0 (oldest)
    await adapter.set('key10', 'value10');

    expect(await adapter.get('key0')).toBeNull();
    expect(await adapter.get('key10')).not.toBeNull();
  });

  it('should update LRU order on access', async () => {
    await adapter.set('key0', 'value0');
    await adapter.set('key1', 'value1');
    await adapter.set('key2', 'value2');

    // Access key0 to make it recent
    await adapter.get('key0');

    // Fill remaining capacity
    for (let i = 3; i < 10; i++) {
      await adapter.set(`key${i}`, `value${i}`);
    }

    // Add one more - should evict key1 (oldest after key0 was accessed)
    await adapter.set('key10', 'value10');

    expect(await adapter.get('key0')).not.toBeNull(); // Was accessed, so more recent
    expect(await adapter.get('key1')).toBeNull(); // Oldest, evicted
    expect(await adapter.get('key10')).not.toBeNull();
  });

  it('should clear all entries', () => {
    const freshAdapter = new MemoryCacheAdapter();
    freshAdapter.set('key1', 'value1');
    freshAdapter.set('key2', 'value2');

    freshAdapter.clear();
    expect(freshAdapter.stats().size).toBe(0);
  });

  it('should report stats', async () => {
    const stats = adapter.stats();
    expect(stats.size).toBe(0);
    expect(stats.maxSize).toBe(10);

    await adapter.set('key1', 'value1');
    expect(adapter.stats().size).toBe(1);
  });
});

describe('ISRCacheManager', () => {
  let adapter: MemoryCacheAdapter;
  let manager: ISRCacheManager;

  beforeEach(() => {
    adapter = new MemoryCacheAdapter();
    manager = new ISRCacheManager(adapter);
  });

  describe('get', () => {
    it('should return null for cache miss', async () => {
      const result = await manager.get('nonexistent');
      expect(result).toBeNull();
    });

    it('should return hit for fresh content', async () => {
      await manager.set('key1', '<html>content</html>', { revalidate: 3600 });
      const result = await manager.get('key1');

      expect(result).not.toBeNull();
      expect(result!.status).toBe('hit');
      expect(result!.html).toBe('<html>content</html>');
      expect(result!.age).toBeLessThan(1000);
    });

    it('should return stale for expired content', async () => {
      // Set with very short revalidate time
      await adapter.set('key1', '<html>stale</html>', { revalidate: 0 });

      // Manually adjust the entry to make it stale
      const entry = await adapter.get('key1');
      if (entry) {
        entry.revalidateAfter = Date.now() - 1000; // 1 second ago
        await adapter.set('key1', entry.value, { revalidate: -1 }); // Hack to set stale
      }

      // Wait a bit and re-set with past revalidateAfter
      await new Promise((resolve) => setTimeout(resolve, 10));

      // Create a fresh manager to test
      const staleAdapter = new MemoryCacheAdapter();
      const staleManager = new ISRCacheManager(staleAdapter);

      // Directly manipulate the internal cache entry
      const staleEntry: CacheEntry = {
        value: '<html>stale</html>',
        generatedAt: Date.now() - 10000, // 10 seconds ago
        revalidateAfter: Date.now() - 1000, // Already past
      };
      (staleAdapter as any).cache.set('key1', staleEntry);
      (staleAdapter as any).accessOrder.push('key1');

      const result = await staleManager.get('key1');
      expect(result).not.toBeNull();
      expect(result!.status).toBe('stale');
    });
  });

  describe('handleISR', () => {
    it('should return miss and generate on cache miss', async () => {
      let generateCalled = false;
      const result = await manager.handleISR(
        'key1',
        async () => {
          generateCalled = true;
          return '<html>generated</html>';
        },
        { revalidate: 3600 }
      );

      expect(generateCalled).toBe(true);
      expect(result.status).toBe('miss');
      expect(result.html).toBe('<html>generated</html>');
      expect(result.age).toBe(0);

      // Verify it was cached
      const cached = await manager.get('key1');
      expect(cached).not.toBeNull();
      expect(cached!.html).toBe('<html>generated</html>');
    });

    it('should return hit without regenerating on cache hit', async () => {
      await manager.set('key1', '<html>cached</html>', { revalidate: 3600 });

      let generateCalled = false;
      const result = await manager.handleISR(
        'key1',
        async () => {
          generateCalled = true;
          return '<html>new</html>';
        },
        { revalidate: 3600 }
      );

      expect(generateCalled).toBe(false);
      expect(result.status).toBe('hit');
      expect(result.html).toBe('<html>cached</html>');
    });

    it('should return stale and regenerate in background', async () => {
      // Set up stale entry
      const staleEntry: CacheEntry = {
        value: '<html>stale</html>',
        generatedAt: Date.now() - 10000,
        revalidateAfter: Date.now() - 1000,
      };
      (adapter as any).cache.set('key1', staleEntry);
      (adapter as any).accessOrder.push('key1');

      let regeneratePromise: Promise<unknown> | null = null;
      const waitUntil = (p: Promise<unknown>) => {
        regeneratePromise = p;
      };

      let generateCalled = false;
      const result = await manager.handleISR(
        'key1',
        async () => {
          generateCalled = true;
          return '<html>regenerated</html>';
        },
        { revalidate: 3600, waitUntil }
      );

      expect(result.status).toBe('stale');
      expect(result.html).toBe('<html>stale</html>');

      // Wait for background regeneration
      expect(regeneratePromise).not.toBeNull();
      await regeneratePromise;
      expect(generateCalled).toBe(true);

      // Verify cache was updated
      const cached = await manager.get('key1');
      expect(cached!.html).toBe('<html>regenerated</html>');
    });
  });

  describe('delete', () => {
    it('should delete cached entry', async () => {
      await manager.set('key1', '<html>content</html>');
      await manager.delete('key1');
      const result = await manager.get('key1');
      expect(result).toBeNull();
    });
  });
});
