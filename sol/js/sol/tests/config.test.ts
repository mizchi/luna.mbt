import { describe, it, expect } from 'vitest';
import { defineConfig, type SolConfig } from '../config';

describe('config', () => {
  describe('defineConfig()', () => {
    it('returns the config as-is', () => {
      const config: SolConfig = {
        islands: ['app/client'],
        routes: 'app/server',
      };

      const result = defineConfig(config);
      expect(result).toBe(config);
    });

    it('accepts minimal config', () => {
      const config = defineConfig({});
      expect(config).toEqual({});
    });

    it('accepts full config', () => {
      const config = defineConfig({
        islands: ['app/client', 'app/components'],
        routes: 'app/server',
        output: 'app/__gen__',
        runtime: 'cloudflare',
        client_auto_exports: false,
        staticDirs: [
          {
            path_prefix: '/docs',
            source_dir: 'docs',
            title: 'Documentation',
          },
        ],
      });

      expect(config.islands).toHaveLength(2);
      expect(config.runtime).toBe('cloudflare');
      expect(config.staticDirs).toHaveLength(1);
    });

    it('accepts SSG-specific fields', () => {
      const config = defineConfig({
        docs: 'docs',
        out_dir: 'dist',
        title: 'My Docs',
        base_url: 'https://example.com',
        trailing_slash: true,
        deploy: 'github',
        sidebar: 'auto',
        theme: {
          primaryColor: '#007bff',
          footer: {
            message: 'Built with Sol',
            copyright: '2024',
          },
        },
      });

      expect(config.docs).toBe('docs');
      expect(config.deploy).toBe('github');
      expect(config.theme?.primaryColor).toBe('#007bff');
    });

    it('accepts staticDirs with all options', () => {
      const config = defineConfig({
        staticDirs: [
          {
            path_prefix: '/guide',
            source_dir: 'guide',
            title: 'Guide',
            nav: [
              { text: 'Home', link: '/' },
              {
                text: 'Docs',
                items: [
                  { text: 'Getting Started', link: '/getting-started' },
                ],
              },
            ],
            sidebar: 'auto',
            i18n: {
              defaultLocale: 'en',
              locales: [
                { code: 'en', label: 'English' },
                { code: 'ja', label: '日本語', path: '/ja' },
              ],
            },
            navigation: {
              spa: true,
              viewTransitions: true,
              keyboard: true,
            },
            exclude: ['*.draft.md'],
            trailing_slash: false,
            theme: {
              primaryColor: '#4CAF50',
            },
          },
        ],
      });

      const staticDir = config.staticDirs?.[0];
      expect(staticDir?.nav).toHaveLength(2);
      expect(staticDir?.i18n?.locales).toHaveLength(2);
      expect(staticDir?.navigation?.spa).toBe(true);
    });
  });

  describe('type safety', () => {
    it('runtime only accepts valid values', () => {
      const nodeConfig = defineConfig({ runtime: 'node' });
      const cfConfig = defineConfig({ runtime: 'cloudflare' });
      const denoConfig = defineConfig({ runtime: 'deno' });
      const bunConfig = defineConfig({ runtime: 'bun' });

      expect(nodeConfig.runtime).toBe('node');
      expect(cfConfig.runtime).toBe('cloudflare');
      expect(denoConfig.runtime).toBe('deno');
      expect(bunConfig.runtime).toBe('bun');
    });

    it('deploy only accepts valid values', () => {
      const ghConfig = defineConfig({ deploy: 'github' });
      const cfConfig = defineConfig({ deploy: 'cloudflare' });
      const vercelConfig = defineConfig({ deploy: 'vercel' });
      const netlifyConfig = defineConfig({ deploy: 'netlify' });

      expect(ghConfig.deploy).toBe('github');
      expect(cfConfig.deploy).toBe('cloudflare');
      expect(vercelConfig.deploy).toBe('vercel');
      expect(netlifyConfig.deploy).toBe('netlify');
    });
  });
});
