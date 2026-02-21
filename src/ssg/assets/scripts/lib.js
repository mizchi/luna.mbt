//#region js/loader/src/lib.ts
/**
* Shared utilities for Luna loaders
*/
/**
* Setup hydration trigger for an element
*/
function setupTrigger(el, trigger, hydrate) {
	if (trigger === "load") document.readyState === "loading" ? document.addEventListener("DOMContentLoaded", () => hydrate(), { once: true }) : hydrate();
	else if (trigger === "idle") requestIdleCallback(() => hydrate());
	else if (trigger[0] === "v") new IntersectionObserver((entries, obs) => {
		if (entries.some((e) => e.isIntersecting)) {
			obs.disconnect();
			hydrate();
		}
	}, { rootMargin: "50px" }).observe(el);
	else if (trigger[0] === "m") {
		const mq = matchMedia(trigger.slice(6));
		const handler = () => {
			if (mq.matches) {
				mq.removeEventListener("change", handler);
				hydrate();
			}
		};
		mq.matches ? hydrate() : mq.addEventListener("change", handler);
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
function observeAdditions(match, setup) {
	new MutationObserver((mutations) => mutations.forEach((m) => m.addedNodes.forEach((n) => {
		if (n.nodeType === 1 && match(n)) setup(n);
	}))).observe(document.body ?? document.documentElement, {
		childList: true,
		subtree: true
	});
}
/**
* Create a loaded tracker with unload utilities
*/
function createLoadedTracker() {
	const loaded = /* @__PURE__ */ new Set();
	return {
		loaded,
		unload: (id) => loaded.delete(id),
		clear: () => loaded.clear()
	};
}

//#endregion
export { createLoadedTracker, observeAdditions, onReady, setupTrigger };