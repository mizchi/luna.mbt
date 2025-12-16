import { createLoadedTracker, observeAdditions, onReady, setupTrigger } from "./lib.js";

//#region js/loader/src/loader.ts
/*! luna loader v1 */
const d = document;
const w = window;
const S = {};
const { loaded, unload, clear } = createLoadedTracker();
const parseState = async (el) => {
	const a = el.getAttribute("ln:state");
	if (!a) return;
	if (a[0] === "#") return JSON.parse(d.getElementById(a.slice(1))?.textContent ?? "null");
	try {
		return JSON.parse(a);
	} catch {}
};
const hydrate = async (el) => {
	const id = el.getAttribute("ln:id");
	if (!id || loaded.has(id)) return;
	loaded.add(id);
	const url = el.getAttribute("ln:url");
	if (!url) return;
	S[id] = await parseState(el);
	const mod = await import(url);
	const ex = el.getAttribute("ln:export");
	(ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
};
const setup = (el) => {
	setupTrigger(el, el.getAttribute("ln:trigger") ?? "load", () => hydrate(el));
};
const scan = () => {
	d.querySelectorAll("[ln\\:id]").forEach(setup);
};
d.querySelectorAll("script[type=\"ln/json\"]").forEach((s) => {
	if (s.id) S[s.id] = JSON.parse(s.textContent ?? "{}");
});
onReady(scan);
observeAdditions((el) => el.hasAttribute("ln:id"), setup);
const unloadAll = (root = d.body) => {
	root.querySelectorAll("[ln\\:id]").forEach((el) => {
		const id = el.getAttribute("ln:id");
		if (id) loaded.delete(id);
	});
};
w.__LN_STATE__ = S;
w.__LN_HYDRATE__ = hydrate;
w.__LN_SCAN__ = scan;
w.__LN_UNLOAD__ = unload;
w.__LN_UNLOAD_ALL__ = unloadAll;
w.__LN_CLEAR_LOADED__ = clear;

//#endregion