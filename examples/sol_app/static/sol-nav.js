//#region js/loader/src/sol-nav.ts
((d, w) => {
	let isNavigating = false;
	const cache = /* @__PURE__ */ new Map();
	const setHTML = (target, html) => {
		if (target.setHTMLUnsafe) target.setHTMLUnsafe(html);
		else target.innerHTML = html;
	};
	const navigate = async (url, replace = false) => {
		if (isNavigating) return;
		isNavigating = true;
		try {
			let html = cache.get(url);
			if (!html) {
				const res = await fetch(url, { headers: { "X-Sol-Fragment": "true" } });
				html = await res.text();
				if (res.headers.get("X-Sol-Fragment-Response")) {
					cache.set(url, html);
					setTimeout(() => cache.delete(url), 300 * 1e3);
				}
			}
			const doc = new DOMParser().parseFromString(html, "text/html");
			const templates = doc.querySelectorAll("template[data-sol-outlet]");
			if (templates.length > 0) {
				templates.forEach((tpl) => {
					const name = tpl.dataset.solOutlet;
					const target = d.querySelector(`[data-sol-outlet="${name}"]`);
					if (target) {
						w.__LN_UNLOAD_ALL__?.(target);
						setHTML(target, tpl.innerHTML);
					}
				});
				const titleTpl = doc.querySelector("template[data-sol-title]");
				if (titleTpl) d.title = titleTpl.textContent ?? "";
			} else {
				const app = doc.querySelector("#app");
				const target = d.querySelector("#app");
				if (app && target) {
					w.__LN_UNLOAD_ALL__?.(target);
					setHTML(target, app.innerHTML);
				}
				const title = doc.querySelector("title");
				if (title) d.title = title.textContent ?? "";
			}
			if (replace) w.history.replaceState({ sol: true }, "", url);
			else w.history.pushState({ sol: true }, "", url);
			w.scrollTo(0, 0);
			w.__LN_SCAN__?.();
			w.__WC_SCAN__?.();
		} catch (e) {
			console.error("Sol navigation failed:", e);
			w.location.href = url;
		} finally {
			isNavigating = false;
		}
	};
	const prefetch = (url) => {
		if (cache.has(url)) return;
		fetch(url, { headers: { "X-Sol-Fragment": "true" } }).then((res) => res.text()).then((html) => {
			cache.set(url, html);
			setTimeout(() => cache.delete(url), 300 * 1e3);
		}).catch(() => {});
	};
	d.addEventListener("click", (e) => {
		const link = e.target?.closest("[data-sol-link]");
		if (!link) return;
		const href = link.getAttribute("href");
		if (!href) return;
		if (href.startsWith("http") || href.startsWith("//")) return;
		if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
		e.preventDefault();
		navigate(href, link.hasAttribute("data-sol-replace"));
	});
	d.addEventListener("mouseenter", (e) => {
		const target = e.target;
		if (!target?.closest) return;
		const link = target.closest("[data-sol-link][data-sol-prefetch]");
		if (link) {
			const href = link.getAttribute("href");
			if (href && !href.startsWith("http") && !href.startsWith("//")) prefetch(href);
		}
	}, { capture: true });
	w.addEventListener("popstate", (e) => {
		if (e.state?.sol || !e.state) navigate(w.location.href, true);
	});
	w.__SOL_NAVIGATE__ = navigate;
	w.__SOL_PREFETCH__ = prefetch;
	w.__SOL_CACHE__ = cache;
})(document, window);

//#endregion