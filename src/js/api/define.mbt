// WebComponents - Custom Elements integration with Signal reactivity
//
// Provides lightweight WebComponents support using jsdom's customElements API.
// Each component gets its own reactive root for automatic cleanup.
//

///|
/// Register a custom element with a render function
/// The render function receives the host element and returns a VNode tree
pub fn register(
  name : String,
  render : (@js_dom.Element) -> @luna.Node[@js.Any, String],
) -> Unit {
  js_define_element(name, fn(host) {
    // Create reactive root for this component instance
    let (dom_node, dispose) = @resource.create_root_with_dispose(fn() {
      let vnode = render(host)
      @client.render_vnode_to_dom(vnode)
    })
    host.appendChild(dom_node) |> ignore
    dispose
  })
}

///|
/// Register a custom element with Shadow DOM
pub fn register_shadow(
  name : String,
  mode? : String = "open",
  render : (@js_dom.Element) -> @luna.Node[@js.Any, String],
) -> Unit {
  js_define_element_shadow(name, mode, fn(host, shadow_root) {
    let (dom_node, dispose) = @resource.create_root_with_dispose(fn() {
      let vnode = render(host)
      @client.render_vnode_to_dom(vnode)
    })
    shadow_root.appendChild(dom_node) |> ignore
    dispose
  })
}

///|
/// Register a custom element with observed attributes as Signals
pub fn register_with_attrs(
  name : String,
  observed_attrs : Array[String],
  render : (@js_dom.Element, Map[String, @resource.Signal[String]]) -> @luna.Node[
    @js.Any,
    String,
  ],
) -> Unit {
  js_define_element_with_attrs(name, observed_attrs, fn(
    host,
    get_attr,
    on_attr_change,
  ) {
    let (dom_node, dispose) = @resource.create_root_with_dispose(fn() {
      // Create signals for each observed attribute
      let attr_signals : Map[String, @resource.Signal[String]] = {}
      for attr in observed_attrs {
        let initial = get_attr(attr)
        attr_signals[attr] = @resource.signal(initial)
      }

      // Set up attribute change callback
      on_attr_change(fn(attr_name, _old_val, new_val) {
        match attr_signals.get(attr_name) {
          Some(sig) => sig.set(new_val)
          None => ()
        }
      })
      let vnode = render(host, attr_signals)
      @client.render_vnode_to_dom(vnode)
    })
    host.appendChild(dom_node) |> ignore
    dispose
  })
}

///|
extern "js" fn js_define_element(
  name : String,
  connected_callback : (@js_dom.Element) -> () -> Unit,
) -> Unit =
  #| (name, connectedCallback) => {
  #|   customElements.define(name, class extends HTMLElement {
  #|     constructor() {
  #|       super();
  #|       this._lunaDispose = null;
  #|     }
  #|     connectedCallback() {
  #|       if (this._lunaDispose) {
  #|         try { this._lunaDispose(); } catch (_) {}
  #|       }
  #|       this.textContent = '';
  #|       const dispose = connectedCallback(this);
  #|       this._lunaDispose = typeof dispose === 'function' ? dispose : null;
  #|     }
  #|     disconnectedCallback() {
  #|       if (this._lunaDispose) {
  #|         try { this._lunaDispose(); } catch (_) {}
  #|         this._lunaDispose = null;
  #|       }
  #|     }
  #|   });
  #| }

///|
extern "js" fn js_define_element_shadow(
  name : String,
  mode : String,
  connected_callback : (@js_dom.Element, @js_dom.Node) -> () -> Unit,
) -> Unit =
  #| (name, mode, connectedCallback) => {
  #|   customElements.define(name, class extends HTMLElement {
  #|     constructor() {
  #|       super();
  #|       this._shadowRoot = this.attachShadow({ mode });
  #|       this._lunaDispose = null;
  #|     }
  #|     connectedCallback() {
  #|       if (this._lunaDispose) {
  #|         try { this._lunaDispose(); } catch (_) {}
  #|       }
  #|       this._shadowRoot.textContent = '';
  #|       const dispose = connectedCallback(this, this._shadowRoot);
  #|       this._lunaDispose = typeof dispose === 'function' ? dispose : null;
  #|     }
  #|     disconnectedCallback() {
  #|       if (this._lunaDispose) {
  #|         try { this._lunaDispose(); } catch (_) {}
  #|         this._lunaDispose = null;
  #|       }
  #|     }
  #|   });
  #| }

///|
extern "js" fn js_define_element_with_attrs(
  name : String,
  observed_attrs : Array[String],
  connected_callback : (
    @js_dom.Element,
    (String) -> String,
    ((String, String, String) -> Unit) -> Unit,
  ) -> () -> Unit,
) -> Unit =
  #| (name, observedAttrs, connectedCallback) => {
  #|   customElements.define(name, class extends HTMLElement {
  #|     static get observedAttributes() { return observedAttrs; }
  #|     constructor() {
  #|       super();
  #|       this._attrChangeCallbacks = [];
  #|       this._lunaDispose = null;
  #|     }
  #|     connectedCallback() {
  #|       if (this._lunaDispose) {
  #|         try { this._lunaDispose(); } catch (_) {}
  #|       }
  #|       this._attrChangeCallbacks = [];
  #|       this.textContent = '';
  #|       const getAttr = (name) => this.getAttribute(name) || '';
  #|       const onAttrChange = (cb) => this._attrChangeCallbacks.push(cb);
  #|       const dispose = connectedCallback(this, getAttr, onAttrChange);
  #|       this._lunaDispose = typeof dispose === 'function' ? dispose : null;
  #|     }
  #|     attributeChangedCallback(name, oldValue, newValue) {
  #|       for (const cb of this._attrChangeCallbacks) {
  #|         cb(name, oldValue || '', newValue || '');
  #|       }
  #|     }
  #|     disconnectedCallback() {
  #|       if (this._lunaDispose) {
  #|         try { this._lunaDispose(); } catch (_) {}
  #|         this._lunaDispose = null;
  #|       }
  #|       this._attrChangeCallbacks = [];
  #|     }
  #|   });
  #| }
