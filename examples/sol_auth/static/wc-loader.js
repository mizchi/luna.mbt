import { createLoadedTracker, observeAdditions, onReady, setupTrigger } from "./lib.js";

//#region js/loader/src/wc-loader.ts
/*! wc-loader v1 - Web Components Hydration Loader for Luna */
const d = document;
const w = window;
const S = {};
const { loaded, unload, clear } = createLoadedTracker();
const parseState = async (el) => {
	const s = el.getAttribute("luna:wc-state");
	if (!s) return {};
	if (s.startsWith("#")) {
		const scriptEl = d.getElementById(s.slice(1));
		if (scriptEl?.textContent) try {
			return JSON.parse(scriptEl.textContent);
		} catch {
			return {};
		}
		return {};
	}
	try {
		const unescaped = s.replace(/\\u003c/g, "<").replace(/\\u003e/g, ">").replace(/\\u0026/g, "&");
		return JSON.parse(unescaped);
	} catch {
		return {};
	}
};
const hydrate = async (el) => {
	const name = el.tagName.toLowerCase();
	if (loaded.has(name)) return;
	const url = el.getAttribute("luna:wc-url");
	if (!url) return;
	loaded.add(name);
	S[name] = await parseState(el);
	try {
		const mod = await import(url);
		const hydrateFn = mod.hydrate ?? mod.default;
		if (typeof hydrateFn === "function") hydrateFn(el, S[name], name);
		else console.warn(`[wc-loader] No hydrate function found in ${url}`);
	} catch (err) {
		console.error(`[wc-loader] Failed to hydrate ${name}:`, err);
	}
};
const setup = (el) => {
	setupTrigger(el, el.getAttribute("luna:wc-trigger") ?? "load", () => hydrate(el));
};
const scan = () => {
	d.querySelectorAll("[luna\\:wc-url]").forEach(setup);
};
onReady(scan);
observeAdditions((el) => el.hasAttribute("luna:wc-url"), setup);
w.__LUNA_WC_STATE__ = S;
w.__LUNA_WC_SCAN__ = scan;
w.__LUNA_WC_HYDRATE__ = hydrate;
w.__LUNA_WC_UNLOAD__ = unload;
w.__LUNA_WC_CLEAR_LOADED__ = clear;

//#endregion