import { createLoadedTracker, observeAdditions, onReady, setupTrigger } from "./lib.js";

//#region js/loader/src/loader.ts
/*! luna loader v1 */
const d = document;
const w = window;
const S = {};
const { loaded, unload, clear } = createLoadedTracker();
const parseState = async (el) => {
	const a = el.getAttribute("luna:state");
	if (!a) return;
	if (a[0] === "#") return JSON.parse(d.getElementById(a.slice(1))?.textContent ?? "null");
	try {
		return JSON.parse(a);
	} catch {}
};
const hydrate = async (el) => {
	const id = el.getAttribute("luna:id");
	if (!id || loaded.has(id)) return;
	loaded.add(id);
	const url = el.getAttribute("luna:url");
	if (!url) return;
	S[id] = await parseState(el);
	const mod = await import(url);
	const ex = el.getAttribute("luna:export");
	(ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
};
const setup = (el) => {
	setupTrigger(el, el.getAttribute("luna:client-trigger") ?? "load", () => hydrate(el));
};
const scan = () => {
	d.querySelectorAll("[luna\\:id]").forEach(setup);
};
d.querySelectorAll("script[type=\"luna/json\"]").forEach((s) => {
	if (s.id) S[s.id] = JSON.parse(s.textContent ?? "{}");
});
onReady(scan);
observeAdditions((el) => el.hasAttribute("luna:id"), setup);
const unloadAll = (root = d.body) => {
	root.querySelectorAll("[luna\\:id]").forEach((el) => {
		const id = el.getAttribute("luna:id");
		if (id) loaded.delete(id);
	});
};
w.__LUNA_STATE__ = S;
w.__LUNA_HYDRATE__ = hydrate;
w.__LUNA_SCAN__ = scan;
w.__LUNA_UNLOAD__ = unload;
w.__LUNA_UNLOAD_ALL__ = unloadAll;
w.__LUNA_CLEAR_LOADED__ = clear;

//#endregion