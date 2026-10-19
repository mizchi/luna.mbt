/** An adapter owns its page-data protocol and invalidation strategy. */
export interface NavigationPort {
  navigate(url: string): void | Promise<void>;
  refresh(): void | Promise<void>;
}
