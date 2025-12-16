import { createLoadedTracker, observeAdditions, onReady, setupTrigger } from "./lib.js";

//#region js/loader/src/wc-loader.ts
/*! wc-loader v1 - Web Components Hydration Loader */
const d = document;
const w = window;
const { loaded, unload, clear } = createLoadedTracker();
const hydrate = async (el) => {
	const name = el.tagName.toLowerCase();
	if (loaded.has(name)) return;
	const url = el.dataset.wcUrl;
	if (!url) return;
	loaded.add(name);
	try {
		const mod = await import(url);
		const def = mod.default ?? mod[name];
		if (def && typeof def === "object") if (w.__WCSSR__?.registerComponent) w.__WCSSR__.registerComponent(def);
		else {
			const { registerComponent } = await import("@mizchi/wcssr/client");
			registerComponent(def);
		}
	} catch (err) {
		console.error(`[wc-loader] Failed to hydrate ${name}:`, err);
	}
};
const setup = (el) => {
	setupTrigger(el, el.dataset.trigger ?? "load", () => hydrate(el));
};
const scan = () => {
	d.querySelectorAll("[data-wc-url]").forEach(setup);
};
onReady(scan);
observeAdditions((el) => !!el.dataset?.wcUrl, (el) => setup(el));
w.__WC_SCAN__ = scan;
w.__WC_HYDRATE__ = hydrate;
w.__WC_UNLOAD__ = unload;
w.__WC_CLEAR_LOADED__ = clear;

//#endregion