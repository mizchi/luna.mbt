(function() {


//#region js/loader/src/lib.ts
/**
	* Shared utilities for Luna loaders
	*/
	/**
	* Setup hydration trigger for an element
	*/
	function setupTrigger(el, trigger, hydrate$1) {
		if (trigger === "load") document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", () => hydrate$1(), { once: true }) : hydrate$1();
		else if (trigger === "idle") requestIdleCallback(() => hydrate$1());
		else if (trigger[0] === "v") new IntersectionObserver((entries, obs) => {
			if (entries.some((e) => e.isIntersecting)) {
				obs.disconnect();
				hydrate$1();
			}
		}, { rootMargin: "50px" }).observe(el);
		else if (trigger[0] === "m") {
			const mq = matchMedia(trigger.slice(6));
			const handler = () => {
				if (mq.matches) {
					mq.removeEventListener("change", handler);
					hydrate$1();
				}
			};
			mq.matches ? hydrate$1() : mq.addEventListener("change", handler);
		}
	}
	/**
	* Run function when DOM is ready
	*/
	function onReady(fn) {
		document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", fn, { once: true }) : fn();
	}
	/**
	* Watch for dynamically added elements matching a predicate
	*/
	function observeAdditions(match, setup$1) {
		new MutationObserver((mutations) => mutations.forEach((m) => m.addedNodes.forEach((n) => {
			if (n.nodeType === 1 && match(n)) setup$1(n);
		}))).observe(document.body ?? document.documentElement, {
			childList: true,
			subtree: true
		});
	}
	/**
	* Create a loaded tracker with unload utilities
	*/
	function createLoadedTracker() {
		const loaded$1 = /* @__PURE__ */ new Set();
		return {
			loaded: loaded$1,
			unload: (id) => loaded$1.delete(id),
			clear: () => loaded$1.clear()
		};
	}

//#endregion
//#region js/loader/src/loader.ts
/*! luna loader v4 - minimal dispatcher */
	const d = document;
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
		const id = el.getAttribute("luna:id") ?? el.tagName.toLowerCase();
		if (loaded.has(id)) return;
		loaded.add(id);
		S[id] = await parseState(el);
		const url = el.getAttribute("luna:url");
		if (!url) return;
		try {
			const mod = await import(url);
			const ex = el.getAttribute("luna:export");
			(ex ? mod[ex] : mod.hydrate ?? mod.default)?.(el, S[id], id);
		} catch (e) {
			console.warn(`[luna] Failed to load ${url}:`, e);
		}
	};
	const setup = (el) => {
		setupTrigger(el, el.getAttribute("luna:trigger") ?? "load", () => hydrate(el));
	};
	const scan = () => {
		d.querySelectorAll("[luna\\:url]").forEach(setup);
	};
	d.querySelectorAll("script[type=\"luna/json\"]").forEach((s) => {
		if (s.id) S[s.id] = JSON.parse(s.textContent ?? "{}");
	});
	onReady(scan);
	observeAdditions((el) => el.hasAttribute("luna:url"), setup);
	const w = window;
	w.__LUNA_STATE__ = S;
	w.__LUNA_HYDRATE__ = hydrate;
	w.__LUNA_SCAN__ = scan;
	w.__LUNA_UNLOAD__ = unload;
	w.__LUNA_CLEAR_LOADED__ = clear;

//#endregion
})();