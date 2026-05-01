import { describe, it, expect } from 'vitest';
import {
  SolRoutes,
  DEFAULT_ROOT_TEMPLATE,
  type PageProps,
  type SolRoute,
} from '../routes';

describe('SolRoutes DSL', () => {
  describe('Page()', () => {
    it('creates a page route', () => {
      const handler = async (props: PageProps) => '<div>Hello</div>';
      const route = SolRoutes.Page({
        path: '/',
        handler,
        title: 'Home',
      });

      expect(route.type).toBe('page');
      expect(route.path).toBe('/');
      expect(route.title).toBe('Home');
      expect(route.handler).toBe(handler);
    });

    it('includes optional meta', () => {
      const route = SolRoutes.Page({
        path: '/about',
        handler: async () => '',
        title: 'About',
        meta: [['description', 'About page']],
      });

      expect(route.meta).toEqual([['description', 'About page']]);
    });

    it('includes optional revalidate', () => {
      const route = SolRoutes.Page({
        path: '/data',
        handler: async () => '',
        title: 'Data',
        revalidate: 60,
      });

      expect(route.revalidate).toBe(60);
    });

    it('includes optional cache strategy', () => {
      const route = SolRoutes.Page({
        path: '/cached',
        handler: async () => '',
        title: 'Cached',
        cache: 'stale-while-revalidate',
      });

      expect(route.cache).toBe('stale-while-revalidate');
    });
  });

  describe('Layout()', () => {
    it('creates a layout route', () => {
      const layout = async (props: PageProps, children: string) =>
        `<main>${children}</main>`;
      const route = SolRoutes.Layout({
        segment: '',
        layout,
        children: [],
      });

      expect(route.type).toBe('layout');
      expect(route.segment).toBe('');
      expect(route.layout).toBe(layout);
      expect(route.children).toEqual([]);
    });

    it('accepts nested routes as children', () => {
      const page = SolRoutes.Page({
        path: '/',
        handler: async () => '',
        title: 'Home',
      });

      const route = SolRoutes.Layout({
        segment: '/admin',
        layout: async (_, c) => c,
        children: [page],
      });

      expect(route.children).toHaveLength(1);
      expect(route.children[0]).toBe(page);
    });
  });

  describe('Get()', () => {
    it('creates a GET API route', () => {
      const handler = async () => ({ status: 'ok' });
      const route = SolRoutes.Get({
        path: '/api/health',
        handler,
      });

      expect(route.type).toBe('get');
      expect(route.path).toBe('/api/health');
      expect(route.handler).toBe(handler);
    });
  });

  describe('Post()', () => {
    it('creates a POST API route', () => {
      const handler = async () => ({ created: true });
      const route = SolRoutes.Post({
        path: '/api/users',
        handler,
      });

      expect(route.type).toBe('post');
      expect(route.path).toBe('/api/users');
      expect(route.handler).toBe(handler);
    });
  });

  describe('WithMiddleware()', () => {
    it('creates a middleware wrapper route', () => {
      const middleware = async (ctx: any, next: () => Promise<Response>) =>
        next();
      const page = SolRoutes.Page({
        path: '/',
        handler: async () => '',
        title: 'Home',
      });

      const route = SolRoutes.WithMiddleware({
        middleware: [middleware],
        children: [page],
      });

      expect(route.type).toBe('withMiddleware');
      expect(route.middleware).toHaveLength(1);
      expect(route.children).toHaveLength(1);
    });

    it('supports multiple middleware', () => {
      const mw1 = async (_: any, next: () => Promise<Response>) => next();
      const mw2 = async (_: any, next: () => Promise<Response>) => next();

      const route = SolRoutes.WithMiddleware({
        middleware: [mw1, mw2],
        children: [],
      });

      expect(route.middleware).toHaveLength(2);
    });
  });

  describe('Route composition', () => {
    it('builds a complex route tree', () => {
      const routes: SolRoute[] = [
        SolRoutes.Layout({
          segment: '',
          layout: async (_, children) => `<html>${children}</html>`,
          children: [
            SolRoutes.Page({
              path: '/',
              handler: async () => '<h1>Home</h1>',
              title: 'Home',
            }),
            SolRoutes.Layout({
              segment: '/admin',
              layout: async (_, children) => `<div class="admin">${children}</div>`,
              children: [
                SolRoutes.Page({
                  path: '/',
                  handler: async () => '<h1>Admin</h1>',
                  title: 'Admin',
                }),
              ],
            }),
          ],
        }),
        SolRoutes.WithMiddleware({
          middleware: [],
          children: [
            SolRoutes.Get({
              path: '/api/data',
              handler: async () => ({ data: [] }),
            }),
          ],
        }),
      ];

      expect(routes).toHaveLength(2);
      expect(routes[0].type).toBe('layout');
      expect(routes[1].type).toBe('withMiddleware');
    });
  });
});

describe('DEFAULT_ROOT_TEMPLATE', () => {
  it('contains required placeholders', () => {
    expect(DEFAULT_ROOT_TEMPLATE).toContain('__LUNA_TITLE__');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('__LUNA_PRELOAD__');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('__LUNA_HEAD__');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('__LUNA_MAIN__');
  });

  it('has proper HTML structure', () => {
    expect(DEFAULT_ROOT_TEMPLATE).toContain('<!DOCTYPE html>');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('<html>');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('</html>');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('<head>');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('<body>');
    expect(DEFAULT_ROOT_TEMPLATE).toContain('id="__sol__"');
  });
});
