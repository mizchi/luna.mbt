export interface ExtractedStyleCall {
  base: Set<string>;
  pseudo: Array<{ pseudo: string; property: string; value: string }>;
  media: Array<{ condition: string; pseudo?: string; property: string; value: string }>;
  warnings: Array<{ func: string; position: number; code: string; reason: string }>;
}
export function extractStyleCalls(source: string): ExtractedStyleCall;
export interface StyleToken { text: string; value?: string; start: number; end: number }
export function tokenize(source: string): StyleToken[];
export function readArguments(tokens: StyleToken[], start: number): { args: StyleToken[][]; end: number } | null;
export function themePairs(tokens: StyleToken[]): Array<[string, string]> | null;
export function propertyName(tokens: StyleToken[]): string | undefined;
export function pseudoSelector(tokens: StyleToken[]): string | undefined;
export function className(key: string): string;
export function mediaKey(rule: ExtractedStyleCall["media"][number]): string;
export function compareConditions(a: string, b: string): number;
export function generateStyleCSS(styles: Pick<ExtractedStyleCall, "base" | "pseudo" | "media">, options?: { pretty?: boolean }): { css: string; mapping: Record<string, string> };
