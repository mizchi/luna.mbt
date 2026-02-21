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

//#endregion
//#region js/loader/src/wc-loader.ts
/*! wc-loader v3 - Web Components Hydration Loader */
	const d = document;
	const S = {};
	const hydrateFns = /* @__PURE__ */ new Map();
	const pending = /* @__PURE__ */ new Map();
	const parseState = async (el) => {
		const s = el.getAttribute("luna:wc-state");
		if (!s) return {};
		if (s[0] === "#") try {
			return JSON.parse(d.getElementById(s.slice(1))?.textContent ?? "{}");
		} catch {
			return {};
		}
		try {
			return JSON.parse(s.replace(/\\u003c/g, "<").replace(/\\u003e/g, ">").replace(/\\u0026/g, "&"));
		} catch {
			return {};
		}
	};
	const loadHydrateFn = async (name, url) => {
		if (hydrateFns.has(name)) return hydrateFns.get(name);
		if (pending.has(name)) return pending.get(name);
		const promise = import(url).then((mod) => {
			const fn = mod.hydrate ?? mod.default;
			if (typeof fn === "function") {
				hydrateFns.set(name, fn);
				return fn;
			}
			console.warn(`[wc-loader] No hydrate in ${url}`);
		}).catch((e) => {
			console.error(`[wc-loader] Failed ${name}:`, e);
		}).finally(() => pending.delete(name));
		pending.set(name, promise);
		return promise;
	};
	const hydrate = async (el) => {
		const name = el.tagName.toLowerCase();
		const state = await parseState(el);
		S[name] = state;
		const url = el.getAttribute("luna:wc-url");
		if (!url) return;
		(await loadHydrateFn(name, url))?.(el, state, name);
	};
	const setup = (el) => {
		setupTrigger(el, el.getAttribute("luna:wc-trigger") ?? el.getAttribute("luna:trigger") ?? "load", () => hydrate(el));
	};
	const scan = () => d.querySelectorAll("[luna\\:wc-url]").forEach(setup);
	onReady(scan);
	observeAdditions((el) => el.hasAttribute("luna:wc-url"), setup);
	const w = window;
	w.__LUNA_WC_STATE__ = S;
	w.__LUNA_WC_SCAN__ = scan;
	w.__LUNA_WC_HYDRATE__ = hydrate;
	w.__LUNA_WC_UNLOAD__ = (n) => hydrateFns.delete(n);
	w.__LUNA_WC_CLEAR_LOADED__ = () => hydrateFns.clear();

//#endregion
})();