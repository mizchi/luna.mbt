const Option$None$0$ = { $tag: 0 };
function Option$Some$0$(param0) {
  this._0 = param0;
}
Option$Some$0$.prototype.$tag = 1;
class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
function Result$Err$1$(param0) {
  this._0 = param0;
}
Result$Err$1$.prototype.$tag = 0;
function Result$Ok$1$(param0) {
  this._0 = param0;
}
Result$Ok$1$.prototype.$tag = 1;
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds = { $tag: 1 };
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex = { $tag: 0 };
const moonbitlang$core$builtin$$int_to_string_js = (x, radix) => {
  return x.toString(radix);
};
const moonbitlang$core$builtin$$JSArray$push = (arr, val) => { arr.push(val); };
const $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Continue$2$ = { $tag: 0 };
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Break$2$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$Break$2$.prototype.$tag = 1;
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Return$2$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$Return$2$.prototype.$tag = 2;
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Error$2$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$Error$2$.prototype.$tag = 3;
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$JumpOuter$2$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$JumpOuter$2$.prototype.$tag = 4;
const $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Continue$3$ = { $tag: 0 };
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Break$3$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$Break$3$.prototype.$tag = 1;
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Return$3$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$Return$3$.prototype.$tag = 2;
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Error$3$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$Error$3$.prototype.$tag = 3;
function $64$moonbitlang$47$core$47$builtin$46$ForeachResult$JumpOuter$3$(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$ForeachResult$JumpOuter$3$.prototype.$tag = 4;
const moonbitlang$core$builtin$$JSArray$copy = (arr) => arr.slice(0);
const moonbitlang$core$builtin$$JSArray$set_length = (arr, len) => { arr.length = len; };
const moonbitlang$core$builtin$$JSArray$pop = (arr) => arr.pop();
const mizchi$js$core$$Any$_call = (obj, key, args) => obj[key](...args);
const mizchi$js$core$$is_nullish = (v) => v == null;
const mizchi$js$core$$new_object = () => ({});
const mizchi$js$core$$Any$_set = (obj, key, value) => { obj[key] = value };
const Option$None$4$ = { $tag: 0 };
function Option$Some$4$(param0) {
  this._0 = param0;
}
Option$Some$4$.prototype.$tag = 1;
const mizchi$js$browser$dom$$document = () => document;
const mizchi$js$browser$dom$$Document$createElement = (self, tag) => self.createElement(tag);
const mizchi$js$browser$dom$$Document$createTextNode = (self, data) => self.createTextNode(data);
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$El(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$El.prototype.$tag = 0;
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Txt(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Txt.prototype.$tag = 1;
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Raw(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Raw.prototype.$tag = 2;
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Static(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Static.prototype.$tag = 3;
const mizchi$luna$luna$dom$element$$apply_event_handler = (elem, name, handler) => elem.addEventListener(name, handler);
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static.prototype.$tag = 0;
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic.prototype.$tag = 1;
function $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Handler(param0) {
  this._0 = param0;
}
$64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Handler.prototype.$tag = 2;
const mizchi$luna$luna$dom$element$$HandlerMap$click = (m, handler) => { m.click = handler; return m; };
const mizchi$luna$luna$dom$element$$HandlerMap$to_attrs = (m) => Object.entries(m).map(([k, v]) => ({ _0: k, _1: { $tag: 2, _0: v } }));
const Option$None$5$ = { $tag: 0 };
function Option$Some$5$(param0) {
  this._0 = param0;
}
Option$Some$5$.prototype.$tag = 1;
const mizchi$luna$luna$dom$router$$get_pathname = () => window.location.pathname;
const mizchi$luna$luna$dom$router$$get_search = () => window.location.search;
const mizchi$luna$luna$dom$router$$push_state = (path) => window.history.pushState(null, '', path);
const mizchi$luna$luna$dom$router$$add_popstate_listener = (callback) => window.addEventListener('popstate', () => callback());
function $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Page(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$luna$47$luna$47$routes$46$Routes$Page.prototype.$tag = 0;
function $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Layout(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$luna$47$luna$47$routes$46$Routes$Layout.prototype.$tag = 1;
function $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Get(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$luna$47$luna$47$routes$46$Routes$Get.prototype.$tag = 2;
function $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Post(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$luna$47$luna$47$routes$46$Routes$Post.prototype.$tag = 3;
const Option$None$6$ = { $tag: 0 };
function Option$Some$6$(param0) {
  this._0 = param0;
}
Option$Some$6$.prototype.$tag = 1;
const Option$None$7$ = { $tag: 0 };
function Option$Some$7$(param0) {
  this._0 = param0;
}
Option$Some$7$.prototype.$tag = 1;
const Option$None$8$ = { $tag: 0 };
function Option$Some$8$(param0) {
  this._0 = param0;
}
Option$Some$8$.prototype.$tag = 1;
const $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger = { method_0: moonbitlang$core$builtin$$Logger$write_string$0$, method_1: moonbitlang$core$builtin$$Logger$write_substring$1$, method_2: moonbitlang$core$builtin$$Logger$write_view$0$, method_3: moonbitlang$core$builtin$$Logger$write_char$0$ };
const moonbitlang$core$builtin$$parse$46$42$bind$124$5354 = ":";
const moonbitlang$core$builtin$$parse$46$42$bind$124$5393 = ":";
const moonbitlang$core$builtin$$parse$46$42$bind$124$5387 = "-";
const moonbitlang$core$builtin$$parse$46$42$bind$124$5374 = ":";
const moonbitlang$core$builtin$$parse$46$42$bind$124$5368 = ":";
const moonbitlang$core$builtin$$output$46$42$bind$124$8198 = "/";
const moonbitlang$core$builtin$$output$46$42$bind$124$8192 = "/";
const moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$42 = 0;
const moonbitlang$core$builtin$$brute_force_find$46$constr$47$56 = 0;
const mizchi$luna$luna$signal$$effect_id_counter = { val: 0 };
const mizchi$luna$luna$signal$$reactive_context = { current_subscriber: undefined, current_owner: undefined, current_cleanups: Option$None$0$, batch_depth: 0, pending_effects: [], pending_ids: [] };
const mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$160 = "[";
const mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$161 = "]";
const mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$162 = "[...";
const mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$163 = "[[...";
const mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$194 = ":";
const mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$198 = "[";
const mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$199 = "[...";
const mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$200 = "[[...";
const mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$201 = "]";
const mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$205 = "[[...";
const mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$206 = "]]";
const mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$210 = "[...";
const mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$211 = "]";
const mizchi$luna$examples$wiki$$hydrate$46$base$124$9 = "/wiki";
const mizchi$luna$examples$wiki$$_init$42$46$base$124$3 = "/wiki";
const mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$921 = { slug: "index", title: "Wiki Home", content: "Welcome to the wiki! Select a page from the sidebar." };
const mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$922 = { slug: "getting-started", title: "Getting Started", content: "Install dependencies with `pnpm install`, then run `pnpm dev`." };
const mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$923 = { slug: "configuration", title: "Configuration", content: "Edit luna.json to configure your project settings." };
const mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$924 = { slug: "api-reference", title: "API Reference", content: "See the API documentation for available endpoints." };
const mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$925 = { slug: "components", title: "Components", content: "Luna provides signal-based reactive components with SSR support." };
const mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$932 = "wiki-header-nav";
const mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$933 = "display: flex; flex-wrap: wrap; gap: 0.5rem; padding: 1rem 0; border-bottom: 1px solid var(--border-color, #e5e7eb); margin-bottom: 1.5rem;";
const mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$934 = "wiki-nav-link";
const mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$935 = "padding: 0.5rem 1rem; text-decoration: none; color: var(--text-color, #333); border-radius: 4px; transition: background 0.2s;";
const mizchi$luna$examples$wiki$$wiki_index_component$46$constr$47$945 = "wiki-page";
const mizchi$luna$examples$wiki$$wiki_page_component$46$constr$47$951 = "wiki-page";
const mizchi$luna$examples$wiki$$wiki_page_component$46$constr$47$952 = "wiki-page wiki-not-found";
const mizchi$luna$examples$wiki$$not_found_component$46$constr$47$959 = "wiki-page wiki-not-found";
const mizchi$luna$examples$wiki$$render_wiki$46$constr$47$966 = "wiki-container";
const mizchi$luna$examples$wiki$$render_wiki$46$constr$47$967 = "min-height: 300px; max-width: 100%; overflow: hidden;";
function moonbitlang$core$abort$$abort$2$(msg) {
  return $panic();
}
function moonbitlang$core$abort$$abort$3$(msg) {
  return $panic();
}
function moonbitlang$core$abort$$abort$4$(msg) {
  $panic();
}
function moonbitlang$core$abort$$abort$5$(msg) {
  return $panic();
}
function moonbitlang$core$builtin$$Eq$equal$6$(_x_5248, _x_5249) {
  if (_x_5248 === 0) {
    if (_x_5249 === 0) {
      return true;
    } else {
      return false;
    }
  } else {
    if (_x_5249 === 1) {
      return true;
    } else {
      return false;
    }
  }
}
function moonbitlang$core$builtin$$abort$2$(string, loc) {
  return moonbitlang$core$abort$$abort$2$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$7$(loc)}\n`);
}
function moonbitlang$core$builtin$$abort$3$(string, loc) {
  return moonbitlang$core$abort$$abort$3$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$7$(loc)}\n`);
}
function moonbitlang$core$builtin$$abort$4$(string, loc) {
  moonbitlang$core$abort$$abort$4$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$7$(loc)}\n`);
}
function moonbitlang$core$builtin$$abort$5$(string, loc) {
  return moonbitlang$core$abort$$abort$5$(`${string}\n  at ${moonbitlang$core$builtin$$Show$to_string$7$(loc)}\n`);
}
function moonbitlang$core$builtin$$StringBuilder$new$46$inner(size_hint) {
  return { val: "" };
}
function moonbitlang$core$builtin$$Logger$write_char$0$(self, ch) {
  const _bind = self;
  _bind.val = `${_bind.val}${String.fromCodePoint(ch)}`;
}
function moonbitlang$core$builtin$$code_point_of_surrogate_pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function moonbitlang$core$builtin$$op_notequal$6$(x, y) {
  return !moonbitlang$core$builtin$$Eq$equal$6$(x, y);
}
function moonbitlang$core$array$$Array$at$8$(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function moonbitlang$core$array$$Array$at$9$(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function moonbitlang$core$array$$Array$at$10$(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function moonbitlang$core$builtin$$boyer_moore_horspool_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      const _end4418 = needle_len - 1 | 0;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _end4418) {
          const _tmp$2 = needle.str;
          const _tmp$3 = needle.start + i | 0;
          const _tmp$4 = _tmp$2.charCodeAt(_tmp$3) & 255;
          $bound_check(skip_table, _tmp$4);
          skip_table[_tmp$4] = (needle_len - 1 | 0) - i | 0;
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$2 = 0;
      while (true) {
        const i = _tmp$2;
        if (i <= (haystack_len - needle_len | 0)) {
          const _end4424 = needle_len - 1 | 0;
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j <= _end4424) {
              const _p = i + j | 0;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p | 0;
              const _tmp$6 = _tmp$4.charCodeAt(_tmp$5);
              const _tmp$7 = needle.str;
              const _tmp$8 = needle.start + j | 0;
              if (_tmp$6 !== _tmp$7.charCodeAt(_tmp$8)) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _p = (i + needle_len | 0) - 1 | 0;
          const _tmp$4 = haystack.str;
          const _tmp$5 = haystack.start + _p | 0;
          const _tmp$6 = _tmp$4.charCodeAt(_tmp$5) & 255;
          $bound_check(skip_table, _tmp$6);
          _tmp$2 = i + skip_table[_tmp$6] | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return moonbitlang$core$builtin$$boyer_moore_horspool_find$46$constr$47$42;
  }
}
function moonbitlang$core$builtin$$brute_force_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const _p = 0;
      const _tmp = needle.str;
      const _tmp$2 = needle.start + _p | 0;
      const needle_first = _tmp.charCodeAt(_tmp$2);
      const forward_len = haystack_len - needle_len | 0;
      let i = 0;
      while (true) {
        if (i <= forward_len) {
          while (true) {
            let _tmp$3;
            if (i <= forward_len) {
              const _p$2 = i;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p$2 | 0;
              _tmp$3 = _tmp$4.charCodeAt(_tmp$5) !== needle_first;
            } else {
              _tmp$3 = false;
            }
            if (_tmp$3) {
              i = i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (i <= forward_len) {
            let _tmp$3 = 1;
            while (true) {
              const j = _tmp$3;
              if (j < needle_len) {
                const _p$2 = i + j | 0;
                const _tmp$4 = haystack.str;
                const _tmp$5 = haystack.start + _p$2 | 0;
                const _tmp$6 = _tmp$4.charCodeAt(_tmp$5);
                const _tmp$7 = needle.str;
                const _tmp$8 = needle.start + j | 0;
                if (_tmp$6 !== _tmp$7.charCodeAt(_tmp$8)) {
                  break;
                }
                _tmp$3 = j + 1 | 0;
                continue;
              } else {
                return i;
              }
            }
            i = i + 1 | 0;
          }
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return moonbitlang$core$builtin$$brute_force_find$46$constr$47$56;
  }
}
function moonbitlang$core$string$$StringView$find(self, str) {
  return (str.end - str.start | 0) <= 4 ? moonbitlang$core$builtin$$brute_force_find(self, str) : moonbitlang$core$builtin$$boyer_moore_horspool_find(self, str);
}
function moonbitlang$core$builtin$$boyer_moore_horspool_rev_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      let _tmp = needle_len - 1 | 0;
      while (true) {
        const i = _tmp;
        if (i > 0) {
          const _tmp$2 = needle.str;
          const _tmp$3 = needle.start + i | 0;
          const _tmp$4 = _tmp$2.charCodeAt(_tmp$3) & 255;
          $bound_check(skip_table, _tmp$4);
          skip_table[_tmp$4] = i;
          _tmp = i - 1 | 0;
          continue;
        } else {
          break;
        }
      }
      let _tmp$2 = haystack_len - needle_len | 0;
      while (true) {
        const i = _tmp$2;
        if (i >= 0) {
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j < needle_len) {
              const _p = i + j | 0;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p | 0;
              const _tmp$6 = _tmp$4.charCodeAt(_tmp$5);
              const _tmp$7 = needle.str;
              const _tmp$8 = needle.start + j | 0;
              if (_tmp$6 !== _tmp$7.charCodeAt(_tmp$8)) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _tmp$4 = haystack.str;
          const _tmp$5 = haystack.start + i | 0;
          const _tmp$6 = _tmp$4.charCodeAt(_tmp$5) & 255;
          $bound_check(skip_table, _tmp$6);
          _tmp$2 = i - skip_table[_tmp$6] | 0;
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return haystack_len;
  }
}
function moonbitlang$core$builtin$$brute_force_rev_find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const _p = 0;
      const _tmp = needle.str;
      const _tmp$2 = needle.start + _p | 0;
      const needle_first = _tmp.charCodeAt(_tmp$2);
      let i = haystack_len - needle_len | 0;
      while (true) {
        if (i >= 0) {
          while (true) {
            let _tmp$3;
            if (i >= 0) {
              const _p$2 = i;
              const _tmp$4 = haystack.str;
              const _tmp$5 = haystack.start + _p$2 | 0;
              _tmp$3 = _tmp$4.charCodeAt(_tmp$5) !== needle_first;
            } else {
              _tmp$3 = false;
            }
            if (_tmp$3) {
              i = i - 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (i >= 0) {
            let _tmp$3 = 1;
            while (true) {
              const j = _tmp$3;
              if (j < needle_len) {
                const _p$2 = i + j | 0;
                const _tmp$4 = haystack.str;
                const _tmp$5 = haystack.start + _p$2 | 0;
                const _tmp$6 = _tmp$4.charCodeAt(_tmp$5);
                const _tmp$7 = needle.str;
                const _tmp$8 = needle.start + j | 0;
                if (_tmp$6 !== _tmp$7.charCodeAt(_tmp$8)) {
                  break;
                }
                _tmp$3 = j + 1 | 0;
                continue;
              } else {
                return i;
              }
            }
            i = i - 1 | 0;
          }
          continue;
        } else {
          break;
        }
      }
      return undefined;
    } else {
      return undefined;
    }
  } else {
    return haystack_len;
  }
}
function moonbitlang$core$string$$StringView$rev_find(self, str) {
  return (str.end - str.start | 0) <= 4 ? moonbitlang$core$builtin$$brute_force_rev_find(self, str) : moonbitlang$core$builtin$$boyer_moore_horspool_rev_find(self, str);
}
function moonbitlang$core$string$$StringView$view$46$inner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.end - self.start | 0;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= (self.end - self.start | 0)) ? { str: self.str, start: self.start + start_offset | 0, end: self.start + end_offset$2 | 0 } : moonbitlang$core$builtin$$abort$3$("Invalid index for View", "@moonbitlang/core/builtin:stringview.mbt:111:5-111:36");
}
function moonbitlang$core$builtin$$parse$46$parse_loc$124$1093(view) {
  const _bind = moonbitlang$core$string$$StringView$find(view, { str: moonbitlang$core$builtin$$parse$46$42$bind$124$5354, start: 0, end: moonbitlang$core$builtin$$parse$46$42$bind$124$5354.length });
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i > 0 && (_i + 1 | 0) < (view.end - view.start | 0) ? { _0: moonbitlang$core$string$$StringView$view$46$inner(view, 0, _i), _1: moonbitlang$core$string$$StringView$view$46$inner(view, _i + 1 | 0, undefined) } : undefined;
  }
}
function moonbitlang$core$builtin$$SourceLocRepr$parse(repr) {
  _L: {
    if (moonbitlang$core$string$$String$char_length_ge$46$inner(repr, 1, 0, repr.length)) {
      const _x = repr.charCodeAt(0);
      if (_x === 64) {
        const _bind = moonbitlang$core$string$$String$offset_of_nth_char$46$inner(repr, 1, 0, repr.length);
        let _tmp;
        if (_bind === undefined) {
          _tmp = repr.length;
        } else {
          const _Some = _bind;
          _tmp = _Some;
        }
        const _x$2 = { str: repr, start: _tmp, end: repr.length };
        const _bind$2 = moonbitlang$core$string$$StringView$find(_x$2, { str: moonbitlang$core$builtin$$parse$46$42$bind$124$5393, start: 0, end: moonbitlang$core$builtin$$parse$46$42$bind$124$5393.length });
        if (_bind$2 === undefined) {
          return $panic();
        } else {
          const _Some = _bind$2;
          const _pkg_end = _Some;
          const pkg = moonbitlang$core$string$$StringView$view$46$inner(_x$2, 0, _pkg_end);
          const _bind$3 = moonbitlang$core$string$$StringView$rev_find(_x$2, { str: moonbitlang$core$builtin$$parse$46$42$bind$124$5387, start: 0, end: moonbitlang$core$builtin$$parse$46$42$bind$124$5387.length });
          if (_bind$3 === undefined) {
            return $panic();
          } else {
            const _Some$2 = _bind$3;
            const _start_loc_end = _Some$2;
            if ((_start_loc_end + 1 | 0) < (_x$2.end - _x$2.start | 0)) {
              const end_loc = moonbitlang$core$string$$StringView$view$46$inner(_x$2, _start_loc_end + 1 | 0, undefined);
              const _bind$4 = moonbitlang$core$builtin$$parse$46$parse_loc$124$1093(end_loc);
              if (_bind$4 === undefined) {
                return $panic();
              } else {
                const _Some$3 = _bind$4;
                const _x$3 = _Some$3;
                const _end_line = _x$3._0;
                const _end_column = _x$3._1;
                const rest = moonbitlang$core$string$$StringView$view$46$inner(_x$2, 0, _start_loc_end);
                _L$2: {
                  const _bind$5 = moonbitlang$core$string$$StringView$rev_find(rest, { str: moonbitlang$core$builtin$$parse$46$42$bind$124$5374, start: 0, end: moonbitlang$core$builtin$$parse$46$42$bind$124$5374.length });
                  if (_bind$5 === undefined) {
                    break _L$2;
                  } else {
                    const _Some$4 = _bind$5;
                    const _start_line_end = _Some$4;
                    const _bind$6 = moonbitlang$core$string$$StringView$rev_find(moonbitlang$core$string$$StringView$view$46$inner(rest, 0, _start_line_end), { str: moonbitlang$core$builtin$$parse$46$42$bind$124$5368, start: 0, end: moonbitlang$core$builtin$$parse$46$42$bind$124$5368.length });
                    if (_bind$6 === undefined) {
                      break _L$2;
                    } else {
                      const _Some$5 = _bind$6;
                      const _filename_end = _Some$5;
                      if ((_filename_end + 1 | 0) < (rest.end - rest.start | 0)) {
                        const start_loc = moonbitlang$core$string$$StringView$view$46$inner(rest, _filename_end + 1 | 0, undefined);
                        const _bind$7 = moonbitlang$core$builtin$$parse$46$parse_loc$124$1093(start_loc);
                        if (_bind$7 === undefined) {
                          return $panic();
                        } else {
                          const _Some$6 = _bind$7;
                          const _x$4 = _Some$6;
                          const _start_line = _x$4._0;
                          const _start_column = _x$4._1;
                          if (_filename_end > (_pkg_end + 1 | 0)) {
                            const filename = moonbitlang$core$string$$StringView$view$46$inner(rest, _pkg_end + 1 | 0, _filename_end);
                            return { pkg: pkg, filename: filename, start_line: _start_line, start_column: _start_column, end_line: _end_line, end_column: _end_column };
                          } else {
                            return $panic();
                          }
                        }
                      } else {
                        return $panic();
                      }
                    }
                  }
                }
                return $panic();
              }
            } else {
              return $panic();
            }
          }
        }
      } else {
        break _L;
      }
    } else {
      break _L;
    }
  }
  return $panic();
}
function moonbitlang$core$builtin$$Logger$write_string$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${str}`;
}
function moonbitlang$core$string$$String$sub$46$inner(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  if (start$2 >= 0 && (start$2 <= end$2 && end$2 <= len)) {
    let _tmp;
    if (start$2 < len) {
      const _p = self.charCodeAt(start$2);
      _tmp = 56320 <= _p && _p <= 57343;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      return new Result$Err$1$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    let _tmp$2;
    if (end$2 < len) {
      const _p = self.charCodeAt(end$2);
      _tmp$2 = 56320 <= _p && _p <= 57343;
    } else {
      _tmp$2 = false;
    }
    if (_tmp$2) {
      return new Result$Err$1$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    return new Result$Ok$1$({ str: self, start: start$2, end: end$2 });
  } else {
    return new Result$Err$1$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds);
  }
}
function moonbitlang$core$builtin$$Logger$write_substring$1$(self, value, start, len) {
  let _tmp;
  let _try_err;
  _L: {
    _L$2: {
      const _bind = moonbitlang$core$string$$String$sub$46$inner(value, start, start + len | 0);
      if (_bind.$tag === 1) {
        const _ok = _bind;
        _tmp = _ok._0;
      } else {
        const _err = _bind;
        const _tmp$2 = _err._0;
        _try_err = _tmp$2;
        break _L$2;
      }
      break _L;
    }
    _tmp = $panic();
  }
  moonbitlang$core$builtin$$Logger$write_view$0$(self, _tmp);
}
function moonbitlang$core$builtin$$Show$to_string$11$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$12$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$builtin$$Show$to_string$7$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  moonbitlang$core$builtin$$Show$output$13$(self, { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger });
  return logger.val;
}
function moonbitlang$core$builtin$$Show$to_string$14$(self) {
  const logger = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  const _p = { self: logger, method_table: $$$64$moonbitlang$47$core$47$builtin$46$StringBuilder$36$as$36$64$moonbitlang$47$core$47$builtin$46$Logger };
  if (self) {
    _p.method_table.method_0(_p.self, "true");
  } else {
    _p.method_table.method_0(_p.self, "false");
  }
  return logger.val;
}
function moonbitlang$core$int$$Int$to_string$46$inner(self, radix) {
  return moonbitlang$core$builtin$$int_to_string_js(self, radix);
}
function moonbitlang$core$builtin$$Show$to_string$3$(self) {
  return self.str.substring(self.start, self.end);
}
function moonbitlang$core$builtin$$Iterator$next$15$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$builtin$$Iterator$next$16$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$builtin$$Iterator$next$10$(self) {
  const _func = self;
  return _func();
}
function moonbitlang$core$builtin$$Iterator$iter$15$(self) {
  return (yield_) => {
    while (true) {
      const _bind = moonbitlang$core$builtin$$Iterator$next$15$(self);
      if (_bind === undefined) {
        return 1;
      } else {
        const _Some = _bind;
        const _x = _Some;
        const _bind$2 = yield_(_x);
        if (_bind$2 === 1) {
        } else {
          return 0;
        }
        continue;
      }
    }
  };
}
function moonbitlang$core$builtin$$Iterator$iter$16$(self) {
  return (yield_) => {
    while (true) {
      const _bind = moonbitlang$core$builtin$$Iterator$next$16$(self);
      if (_bind === undefined) {
        return 1;
      } else {
        const _Some = _bind;
        const _x = _Some;
        const _bind$2 = yield_(_x);
        if (_bind$2 === 1) {
        } else {
          return 0;
        }
        continue;
      }
    }
  };
}
function moonbitlang$core$builtin$$Iterator$iter$10$(self) {
  return (yield_) => {
    while (true) {
      const _bind = moonbitlang$core$builtin$$Iterator$next$10$(self);
      if (_bind === -1) {
        return 1;
      } else {
        const _Some = _bind;
        const _x = _Some;
        const _bind$2 = yield_(_x);
        if (_bind$2 === 1) {
        } else {
          return 0;
        }
        continue;
      }
    }
  };
}
function moonbitlang$core$string$$String$from_array(chars) {
  const buf = moonbitlang$core$builtin$$StringBuilder$new$46$inner(Math.imul(chars.end - chars.start | 0, 4) | 0);
  const _len = chars.end - chars.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars.buf[chars.start + _i | 0];
      moonbitlang$core$builtin$$Logger$write_char$0$(buf, c);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return buf.val;
}
function moonbitlang$core$string$$String$char_length_ge$46$inner(self, len, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  let _tmp = start_offset;
  let _tmp$2 = 0;
  while (true) {
    const index = _tmp;
    const count = _tmp$2;
    if (index < end_offset$2 && count < len) {
      const c1 = self.charCodeAt(index);
      if (55296 <= c1 && c1 <= 56319 && (index + 1 | 0) < end_offset$2) {
        const _tmp$3 = index + 1 | 0;
        const c2 = self.charCodeAt(_tmp$3);
        if (56320 <= c2 && c2 <= 57343) {
          _tmp = index + 2 | 0;
          _tmp$2 = count + 1 | 0;
          continue;
        } else {
          moonbitlang$core$builtin$$abort$4$("invalid surrogate pair", "@moonbitlang/core/builtin:string.mbt:491:9-491:40");
        }
      }
      _tmp = index + 1 | 0;
      _tmp$2 = count + 1 | 0;
      continue;
    } else {
      return count >= len;
    }
  }
}
function moonbitlang$core$string$$String$offset_of_nth_char_backward(self, n, start_offset, end_offset) {
  let char_count = 0;
  let utf16_offset = end_offset;
  while (true) {
    if ((utf16_offset - 1 | 0) >= start_offset && char_count < n) {
      const _tmp = utf16_offset - 1 | 0;
      const c = self.charCodeAt(_tmp);
      if (56320 <= c && c <= 57343) {
        utf16_offset = utf16_offset - 2 | 0;
      } else {
        utf16_offset = utf16_offset - 1 | 0;
      }
      char_count = char_count + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return char_count < n || utf16_offset < start_offset ? undefined : utf16_offset;
}
function moonbitlang$core$string$$String$offset_of_nth_char_forward(self, n, start_offset, end_offset) {
  if (start_offset >= 0 && start_offset <= end_offset) {
    let utf16_offset = start_offset;
    let char_count = 0;
    while (true) {
      if (utf16_offset < end_offset && char_count < n) {
        const _tmp = utf16_offset;
        const c = self.charCodeAt(_tmp);
        if (55296 <= c && c <= 56319) {
          utf16_offset = utf16_offset + 2 | 0;
        } else {
          utf16_offset = utf16_offset + 1 | 0;
        }
        char_count = char_count + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return char_count < n || utf16_offset >= end_offset ? undefined : utf16_offset;
  } else {
    return moonbitlang$core$builtin$$abort$5$("Invalid start index", "@moonbitlang/core/builtin:string.mbt:366:5-366:33");
  }
}
function moonbitlang$core$string$$String$offset_of_nth_char$46$inner(self, i, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return i >= 0 ? moonbitlang$core$string$$String$offset_of_nth_char_forward(self, i, start_offset, end_offset$2) : moonbitlang$core$string$$String$offset_of_nth_char_backward(self, -i | 0, start_offset, end_offset$2);
}
function moonbitlang$core$builtin$$Logger$write_view$0$(self, str) {
  const _bind = self;
  _bind.val = `${_bind.val}${moonbitlang$core$builtin$$Show$to_string$3$(str)}`;
}
function moonbitlang$core$string$$StringView$has_suffix(self, str) {
  const _bind = moonbitlang$core$string$$StringView$rev_find(self, str);
  if (_bind === undefined) {
    return false;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i === ((self.end - self.start | 0) - (str.end - str.start | 0) | 0);
  }
}
function moonbitlang$core$string$$String$has_suffix(self, str) {
  return moonbitlang$core$string$$StringView$has_suffix({ str: self, start: 0, end: self.length }, str);
}
function moonbitlang$core$string$$StringView$has_prefix(self, str) {
  const _bind = moonbitlang$core$string$$StringView$find(self, str);
  if (_bind === undefined) {
    return false;
  } else {
    const _Some = _bind;
    const _i = _Some;
    return _i === 0;
  }
}
function moonbitlang$core$string$$String$has_prefix(self, str) {
  return moonbitlang$core$string$$StringView$has_prefix({ str: self, start: 0, end: self.length }, str);
}
function moonbitlang$core$array$$Array$new$46$inner$10$(capacity) {
  return [];
}
function moonbitlang$core$array$$Array$push$15$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$17$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$18$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$8$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$19$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$9$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$20$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$10$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$array$$Array$push$21$(self, value) {
  moonbitlang$core$builtin$$JSArray$push(self, value);
}
function moonbitlang$core$string$$String$iterator(self) {
  const len = self.length;
  const index = { val: 0 };
  const _p = () => {
    if (index.val < len) {
      const _tmp = index.val;
      const c1 = self.charCodeAt(_tmp);
      if (55296 <= c1 && c1 <= 56319 && (index.val + 1 | 0) < len) {
        const _tmp$2 = index.val + 1 | 0;
        const c2 = self.charCodeAt(_tmp$2);
        if (56320 <= c2 && c2 <= 57343) {
          const c = moonbitlang$core$builtin$$code_point_of_surrogate_pair(c1, c2);
          index.val = index.val + 2 | 0;
          return c;
        }
      }
      index.val = index.val + 1 | 0;
      return c1;
    } else {
      return -1;
    }
  };
  return _p;
}
function moonbitlang$core$string$$String$iter(self) {
  return moonbitlang$core$builtin$$Iterator$iter$10$(moonbitlang$core$string$$String$iterator(self));
}
function moonbitlang$core$builtin$$Iter$run$15$(self, f) {
  const _func = self;
  return _func(f);
}
function moonbitlang$core$builtin$$Show$to_string$10$(self) {
  return String.fromCodePoint(self);
}
function moonbitlang$core$builtin$$Iter$each$22$(self, f) {
  const _foreach_result = { val: $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Continue$3$ };
  self((a) => {
    f(a);
    return 1;
  });
  const _tmp = _foreach_result.val;
  switch (_tmp.$tag) {
    case 0: {
      return;
    }
    case 1: {
      const _break = _tmp;
      _break._0;
      return;
    }
    case 2: {
      const _return = _tmp;
      return _return._0;
    }
    case 3: {
      $panic();
      return;
    }
    default: {
      $panic();
      return;
    }
  }
}
function moonbitlang$core$builtin$$Iter$collect$20$(self) {
  const result = [];
  moonbitlang$core$builtin$$Iter$each$22$(self, (e) => {
    moonbitlang$core$array$$Array$push$20$(result, e);
  });
  return result;
}
function moonbitlang$core$string$$String$to_array(self) {
  const _p = moonbitlang$core$string$$String$iter(self);
  const _p$2 = moonbitlang$core$array$$Array$new$46$inner$10$(self.length);
  const _p$3 = { val: _p$2 };
  const _p$4 = { val: $64$moonbitlang$47$core$47$builtin$46$ForeachResult$Continue$2$ };
  _p((_p$5) => {
    const _p$6 = _p$3.val;
    moonbitlang$core$array$$Array$push$10$(_p$6, _p$5);
    _p$3.val = _p$6;
    return 1;
  });
  const _tmp = _p$4.val;
  switch (_tmp.$tag) {
    case 0: {
      break;
    }
    case 1: {
      const _p$5 = _tmp;
      _p$5._0;
      break;
    }
    case 2: {
      const _p$6 = _tmp;
      return _p$6._0;
    }
    case 3: {
      $panic();
      break;
    }
    default: {
      $panic();
    }
  }
  return _p$3.val;
}
function moonbitlang$core$array$$ArrayView$iterator$15$(self) {
  const i = { val: 0 };
  const _p = () => {
    if (i.val < (self.end - self.start | 0)) {
      const elem = self.buf[self.start + i.val | 0];
      i.val = i.val + 1 | 0;
      return elem;
    } else {
      return undefined;
    }
  };
  return _p;
}
function moonbitlang$core$array$$ArrayView$iterator$16$(self) {
  const i = { val: 0 };
  const _p = () => {
    if (i.val < (self.end - self.start | 0)) {
      const elem = self.buf[self.start + i.val | 0];
      i.val = i.val + 1 | 0;
      return elem;
    } else {
      return undefined;
    }
  };
  return _p;
}
function moonbitlang$core$array$$Array$iterator$15$(self) {
  return moonbitlang$core$array$$ArrayView$iterator$15$({ buf: self, start: 0, end: self.length });
}
function moonbitlang$core$array$$Array$iterator$16$(self) {
  return moonbitlang$core$array$$ArrayView$iterator$16$({ buf: self, start: 0, end: self.length });
}
function moonbitlang$core$array$$Array$iter$15$(self) {
  return moonbitlang$core$builtin$$Iterator$iter$15$(moonbitlang$core$array$$Array$iterator$15$(self));
}
function moonbitlang$core$array$$Array$iter$16$(self) {
  return moonbitlang$core$builtin$$Iterator$iter$16$(moonbitlang$core$array$$Array$iterator$16$(self));
}
function moonbitlang$core$builtin$$Iter$any$15$(self, f) {
  return moonbitlang$core$builtin$$op_notequal$6$(moonbitlang$core$builtin$$Iter$run$15$(self, (k) => f(k) ? 0 : 1), 1);
}
function moonbitlang$core$builtin$$Show$output$23$(self, logger) {
  const pkg = self.pkg;
  const _bind = moonbitlang$core$string$$StringView$find(pkg, { str: moonbitlang$core$builtin$$output$46$42$bind$124$8198, start: 0, end: moonbitlang$core$builtin$$output$46$42$bind$124$8198.length });
  let _bind$2;
  if (_bind === undefined) {
    _bind$2 = { _0: pkg, _1: undefined };
  } else {
    const _Some = _bind;
    const _first_slash = _Some;
    const _bind$3 = moonbitlang$core$string$$StringView$find(moonbitlang$core$string$$StringView$view$46$inner(pkg, _first_slash + 1 | 0, undefined), { str: moonbitlang$core$builtin$$output$46$42$bind$124$8192, start: 0, end: moonbitlang$core$builtin$$output$46$42$bind$124$8192.length });
    if (_bind$3 === undefined) {
      _bind$2 = { _0: pkg, _1: undefined };
    } else {
      const _Some$2 = _bind$3;
      const _second_slash = _Some$2;
      const module_name_end = (_first_slash + 1 | 0) + _second_slash | 0;
      _bind$2 = { _0: moonbitlang$core$string$$StringView$view$46$inner(pkg, 0, module_name_end), _1: moonbitlang$core$string$$StringView$view$46$inner(pkg, module_name_end + 1 | 0, undefined) };
    }
  }
  const _module_name = _bind$2._0;
  const _package_name = _bind$2._1;
  if (_package_name === undefined) {
  } else {
    const _Some = _package_name;
    const _pkg_name = _Some;
    logger.method_table.method_2(logger.self, _pkg_name);
    logger.method_table.method_3(logger.self, 47);
  }
  logger.method_table.method_2(logger.self, self.filename);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.start_column);
  logger.method_table.method_3(logger.self, 45);
  logger.method_table.method_2(logger.self, self.end_line);
  logger.method_table.method_3(logger.self, 58);
  logger.method_table.method_2(logger.self, self.end_column);
  logger.method_table.method_3(logger.self, 64);
  logger.method_table.method_2(logger.self, _module_name);
}
function moonbitlang$core$builtin$$Show$output$13$(self, logger) {
  moonbitlang$core$builtin$$Show$output$23$(moonbitlang$core$builtin$$SourceLocRepr$parse(self), logger);
}
function moonbitlang$core$array$$Array$sub$46$inner$10$(self, start, end) {
  const len = self.length;
  let end$2;
  if (end === undefined) {
    end$2 = len;
  } else {
    const _Some = end;
    const _end = _Some;
    end$2 = _end < 0 ? len + _end | 0 : _end;
  }
  const start$2 = start < 0 ? len + start | 0 : start;
  return start$2 >= 0 && (start$2 <= end$2 && end$2 <= len) ? { buf: self, start: start$2, end: end$2 } : moonbitlang$core$builtin$$abort$2$("View index out of bounds", "@moonbitlang/core/builtin:arrayview.mbt:200:5-200:38");
}
function moonbitlang$core$array$$Array$unsafe_truncate_to_length$9$(self, new_len) {
  moonbitlang$core$builtin$$JSArray$set_length(self, new_len);
}
function moonbitlang$core$array$$Array$unsafe_truncate_to_length$10$(self, new_len) {
  moonbitlang$core$builtin$$JSArray$set_length(self, new_len);
}
function moonbitlang$core$array$$Array$unsafe_pop$10$(self) {
  return moonbitlang$core$builtin$$JSArray$pop(self);
}
function moonbitlang$core$array$$Array$pop$10$(self) {
  if (self.length === 0) {
    return -1;
  } else {
    const v = moonbitlang$core$array$$Array$unsafe_pop$10$(self);
    return v;
  }
}
function moonbitlang$core$array$$Array$copy$8$(self) {
  return moonbitlang$core$builtin$$JSArray$copy(self);
}
function moonbitlang$core$array$$Array$clear$9$(self) {
  moonbitlang$core$array$$Array$unsafe_truncate_to_length$9$(self, 0);
}
function moonbitlang$core$array$$Array$clear$10$(self) {
  moonbitlang$core$array$$Array$unsafe_truncate_to_length$10$(self, 0);
}
function mizchi$js$core$$identity_option$24$(v) {
  return mizchi$js$core$$is_nullish(v) ? Option$None$4$ : new Option$Some$4$(v);
}
function mizchi$js$browser$dom$$Node$appendChild(self, child) {
  return mizchi$js$core$$Any$_call(self, "appendChild", [child]);
}
function mizchi$js$browser$dom$$Node$setTextContent(self, content) {
  mizchi$js$core$$Any$_set(self, "textContent", content);
}
function mizchi$js$browser$dom$$MouseEvent$preventDefault(self) {
  mizchi$js$core$$Any$_call(self, "preventDefault", []);
}
function mizchi$js$browser$dom$$Element$setClassName(self, class_name) {
  mizchi$js$core$$Any$_set(self, "className", class_name);
}
function mizchi$js$browser$dom$$Element$setAttribute(self, name, value) {
  mizchi$js$core$$Any$_call(self, "setAttribute", [name, value]);
}
function mizchi$js$browser$dom$$Element$removeAttribute(self, name) {
  mizchi$js$core$$Any$_call(self, "removeAttribute", [name]);
}
function mizchi$js$browser$dom$$Document$getElementById(self, id) {
  const v = mizchi$js$core$$Any$_call(self, "getElementById", [id]);
  return mizchi$js$core$$identity_option$24$(v);
}
function mizchi$luna$luna$signal$$new_effect_id() {
  const id = mizchi$luna$luna$signal$$effect_id_counter.val;
  mizchi$luna$luna$signal$$effect_id_counter.val = id + 1 | 0;
  return id;
}
function mizchi$luna$luna$signal$$register_disposer(disposer) {
  const _bind = mizchi$luna$luna$signal$$reactive_context.current_owner;
  if (_bind === undefined) {
    return;
  } else {
    const _Some = _bind;
    const _owner = _Some;
    moonbitlang$core$array$$Array$push$9$(_owner.disposers, disposer);
    return;
  }
}
function mizchi$luna$luna$signal$$run_cleanups(cleanups) {
  let _tmp = cleanups.length - 1 | 0;
  while (true) {
    const i = _tmp;
    if (i >= 0) {
      const _func = moonbitlang$core$array$$Array$at$9$(cleanups, i);
      _func();
      _tmp = i - 1 | 0;
      continue;
    } else {
      break;
    }
  }
  moonbitlang$core$array$$Array$clear$9$(cleanups);
}
function mizchi$luna$luna$signal$$set_current_cleanups(cleanups) {
  const prev = mizchi$luna$luna$signal$$reactive_context.current_cleanups;
  mizchi$luna$luna$signal$$reactive_context.current_cleanups = cleanups;
  return prev;
}
function mizchi$luna$luna$signal$$run_with_cleanup_tracking$4$(cleanups, f) {
  const prev = mizchi$luna$luna$signal$$set_current_cleanups(new Option$Some$0$(cleanups));
  f();
  mizchi$luna$luna$signal$$reactive_context.current_cleanups = prev;
}
function mizchi$luna$luna$signal$$run_with_subscriber$4$(subscriber, f) {
  const prev = mizchi$luna$luna$signal$$reactive_context.current_subscriber;
  mizchi$luna$luna$signal$$reactive_context.current_subscriber = subscriber;
  f();
  mizchi$luna$luna$signal$$reactive_context.current_subscriber = prev;
}
function mizchi$luna$luna$signal$$effect(fn_) {
  const state = { active: true, cleanups: [] };
  const id = mizchi$luna$luna$signal$$new_effect_id();
  const runner_ref = { val: undefined };
  const run_effect = () => {
    if (!state.active) {
      return undefined;
    }
    mizchi$luna$luna$signal$$run_cleanups(state.cleanups);
    const _bind = runner_ref.val;
    if (_bind === undefined) {
      return;
    } else {
      const _Some = _bind;
      const _runner = _Some;
      mizchi$luna$luna$signal$$run_with_subscriber$4$(_runner, () => {
        mizchi$luna$luna$signal$$run_with_cleanup_tracking$4$(state.cleanups, fn_);
      });
      return;
    }
  };
  const runner = { id: id, run: run_effect };
  runner_ref.val = runner;
  run_effect();
  const dispose = () => {
    state.active = false;
    mizchi$luna$luna$signal$$run_cleanups(state.cleanups);
  };
  mizchi$luna$luna$signal$$register_disposer(dispose);
  return dispose;
}
function mizchi$luna$luna$signal$$Signal$get$25$(self) {
  const _bind = mizchi$luna$luna$signal$$reactive_context.current_subscriber;
  if (_bind === undefined) {
  } else {
    const _Some = _bind;
    const _subscriber = _Some;
    const already_subscribed = moonbitlang$core$builtin$$Iter$any$15$(moonbitlang$core$array$$Array$iter$15$(self.subscribers), (s) => s.id === _subscriber.id);
    if (!already_subscribed) {
      moonbitlang$core$array$$Array$push$15$(self.subscribers, _subscriber);
    }
  }
  return self.value;
}
function mizchi$luna$luna$signal$$Signal$get$8$(self) {
  const _bind = mizchi$luna$luna$signal$$reactive_context.current_subscriber;
  if (_bind === undefined) {
  } else {
    const _Some = _bind;
    const _subscriber = _Some;
    const already_subscribed = moonbitlang$core$builtin$$Iter$any$15$(moonbitlang$core$array$$Array$iter$15$(self.subscribers), (s) => s.id === _subscriber.id);
    if (!already_subscribed) {
      moonbitlang$core$array$$Array$push$15$(self.subscribers, _subscriber);
    }
  }
  return self.value;
}
function mizchi$luna$luna$signal$$Signal$new$8$(initial) {
  return { value: initial, subscribers: [] };
}
function mizchi$luna$luna$signal$$Signal$new$25$(initial) {
  return { value: initial, subscribers: [] };
}
function mizchi$luna$luna$signal$$signal$8$(initial) {
  return mizchi$luna$luna$signal$$Signal$new$8$(initial);
}
function mizchi$luna$luna$signal$$signal$25$(initial) {
  return mizchi$luna$luna$signal$$Signal$new$25$(initial);
}
function mizchi$luna$luna$signal$$is_pending(id) {
  const _arr = mizchi$luna$luna$signal$$reactive_context.pending_ids;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const pending_id = _arr[_i];
      if (pending_id === id) {
        return true;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return false;
}
function mizchi$luna$luna$signal$$schedule_effect(effect) {
  if (mizchi$luna$luna$signal$$reactive_context.batch_depth > 0) {
    if (!mizchi$luna$luna$signal$$is_pending(effect.id)) {
      moonbitlang$core$array$$Array$push$21$(mizchi$luna$luna$signal$$reactive_context.pending_ids, effect.id);
      moonbitlang$core$array$$Array$push$15$(mizchi$luna$luna$signal$$reactive_context.pending_effects, effect);
      return;
    } else {
      return;
    }
  } else {
    const _func = effect.run;
    _func();
    return;
  }
}
function mizchi$luna$luna$signal$$Signal$notify$8$(self) {
  const _arr = self.subscribers;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const subscriber = _arr[_i];
      mizchi$luna$luna$signal$$schedule_effect(subscriber);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function mizchi$luna$luna$signal$$Signal$notify$25$(self) {
  const _arr = self.subscribers;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const subscriber = _arr[_i];
      mizchi$luna$luna$signal$$schedule_effect(subscriber);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function mizchi$luna$luna$signal$$Signal$set$8$(self, new_value) {
  self.value = new_value;
  mizchi$luna$luna$signal$$Signal$notify$8$(self);
}
function mizchi$luna$luna$signal$$Signal$set$25$(self, new_value) {
  self.value = new_value;
  mizchi$luna$luna$signal$$Signal$notify$25$(self);
}
function mizchi$luna$luna$signal$$untracked$26$(f) {
  const prev = mizchi$luna$luna$signal$$reactive_context.current_subscriber;
  mizchi$luna$luna$signal$$reactive_context.current_subscriber = undefined;
  const result = f();
  mizchi$luna$luna$signal$$reactive_context.current_subscriber = prev;
  return result;
}
function mizchi$luna$luna$signal$$untracked$20$(f) {
  const prev = mizchi$luna$luna$signal$$reactive_context.current_subscriber;
  mizchi$luna$luna$signal$$reactive_context.current_subscriber = undefined;
  const result = f();
  mizchi$luna$luna$signal$$reactive_context.current_subscriber = prev;
  return result;
}
function mizchi$luna$luna$dom$element$$text_node(content) {
  const doc = mizchi$js$browser$dom$$document();
  const initial = content();
  const node = mizchi$js$browser$dom$$Document$createTextNode(doc, initial);
  mizchi$luna$luna$signal$$effect(() => {
    const new_content = content();
    mizchi$js$browser$dom$$Node$setTextContent(node, new_content);
  });
  return new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Txt(node);
}
function mizchi$luna$luna$dom$element$$apply_static_attr(elem, name, value) {
  if (name === "className") {
    mizchi$js$browser$dom$$Element$setClassName(elem, value);
    return;
  } else {
    if (name === "value") {
      mizchi$js$core$$Any$_set(elem, "value", value);
      return;
    } else {
      if (name === "checked") {
        mizchi$js$core$$Any$_set(elem, "checked", value === "true");
        return;
      } else {
        if (name === "disabled") {
          if (value === "true") {
            mizchi$js$browser$dom$$Element$setAttribute(elem, "disabled", "");
            return;
          } else {
            mizchi$js$browser$dom$$Element$removeAttribute(elem, "disabled");
            return;
          }
        } else {
          mizchi$js$browser$dom$$Element$setAttribute(elem, name, value);
          return;
        }
      }
    }
  }
}
function mizchi$luna$luna$dom$element$$apply_style_string(elem, style) {
  mizchi$js$browser$dom$$Element$setAttribute(elem, "style", style);
}
function mizchi$luna$luna$dom$element$$apply_attribute(elem, name, value) {
  switch (value.$tag) {
    case 0: {
      const _Static = value;
      const _s = _Static._0;
      if (name === "style") {
        mizchi$luna$luna$dom$element$$apply_style_string(elem, _s);
        return;
      } else {
        mizchi$luna$luna$dom$element$$apply_static_attr(elem, name, _s);
        return;
      }
    }
    case 1: {
      const _Dynamic = value;
      const _getter = _Dynamic._0;
      mizchi$luna$luna$signal$$effect(() => {
        const new_value = _getter();
        if (name === "style") {
          mizchi$luna$luna$dom$element$$apply_style_string(elem, new_value);
          return;
        } else {
          mizchi$luna$luna$dom$element$$apply_static_attr(elem, name, new_value);
          return;
        }
      });
      return;
    }
    default: {
      const _Handler = value;
      const _handler = _Handler._0;
      if (name === "__ref") {
        _handler(elem);
        return;
      } else {
        mizchi$luna$luna$dom$element$$apply_event_handler(elem, name, _handler);
        return;
      }
    }
  }
}
function mizchi$luna$luna$dom$element$$DomElement$from_dom(elem) {
  return { inner: elem };
}
function mizchi$luna$luna$dom$element$$DomNode$to_dom(self) {
  switch (self.$tag) {
    case 0: {
      const _El = self;
      const _elem = _El._0;
      return _elem.inner;
    }
    case 1: {
      const _Txt = self;
      const _text = _Txt._0;
      return _text;
    }
    case 2: {
      const _Raw = self;
      return _Raw._0;
    }
    default: {
      const _Static = self;
      return _Static._0;
    }
  }
}
function mizchi$luna$luna$dom$element$$create_element(tag, attrs, children) {
  const doc = mizchi$js$browser$dom$$document();
  const elem = mizchi$js$browser$dom$$Document$createElement(doc, tag);
  const _len = attrs.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const attr = attrs[_i];
      const _name = attr._0;
      const _value = attr._1;
      mizchi$luna$luna$dom$element$$apply_attribute(elem, _name, _value);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _len$2 = children.length;
  let _tmp$2 = 0;
  while (true) {
    const _i = _tmp$2;
    if (_i < _len$2) {
      const child = children[_i];
      mizchi$js$browser$dom$$Node$appendChild(elem, mizchi$luna$luna$dom$element$$DomNode$to_dom(child));
      _tmp$2 = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$El(mizchi$luna$luna$dom$element$$DomElement$from_dom(elem));
}
function mizchi$luna$luna$dom$element$$mount(container, n) {
  mizchi$js$browser$dom$$Node$appendChild(container.inner, mizchi$luna$luna$dom$element$$DomNode$to_dom(n));
}
function mizchi$luna$luna$dom$element$$clear(container) {
  mizchi$js$browser$dom$$Node$setTextContent(container.inner, "");
}
function mizchi$luna$luna$dom$element$$ToDomNode$to_dom_node$8$(self) {
  const doc = mizchi$js$browser$dom$$document();
  return new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$DomNode$Txt(mizchi$js$browser$dom$$Document$createTextNode(doc, self));
}
function mizchi$luna$luna$dom$element$$double_to_string(d) {
  const any = d;
  return mizchi$js$core$$Any$_call(any, "toString", []);
}
function moonbitlang$core$builtin$$Show$output$12$(self, logger) {
  switch (self.$tag) {
    case 0: {
      const _AttrString = self;
      const _s = _AttrString._0;
      logger.method_table.method_0(logger.self, _s);
      return;
    }
    case 1: {
      const _AttrNumber = self;
      const _d = _AttrNumber._0;
      logger.method_table.method_0(logger.self, mizchi$luna$luna$dom$element$$double_to_string(_d));
      return;
    }
    case 2: {
      const _AttrInt = self;
      const _i = _AttrInt._0;
      logger.method_table.method_0(logger.self, moonbitlang$core$int$$Int$to_string$46$inner(_i, 10));
      return;
    }
    default: {
      const _AttrBool = self;
      const _b = _AttrBool._0;
      logger.method_table.method_0(logger.self, moonbitlang$core$builtin$$Show$to_string$14$(_b));
      return;
    }
  }
}
function mizchi$luna$luna$dom$element$$Attr$to_attr_value(self) {
  return new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(moonbitlang$core$builtin$$Show$to_string$11$(self));
}
function mizchi$luna$luna$dom$element$$events() {
  return mizchi$js$core$$new_object();
}
function mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs) {
  const result = [];
  if (id === undefined) {
  } else {
    const _Some = id;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$17$(result, { _0: "id", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(_v) });
  }
  if (class_ === undefined) {
  } else {
    const _Some = class_;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$17$(result, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(_v) });
  }
  if (style === undefined) {
  } else {
    const _Some = style;
    const _s = _Some;
    moonbitlang$core$array$$Array$push$17$(result, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(_s) });
  }
  if (on.$tag === 1) {
    const _Some = on;
    const _handlers = _Some._0;
    const _arr = mizchi$luna$luna$dom$element$$HandlerMap$to_attrs(_handlers);
    const _len = _arr.length;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const attr = _arr[_i];
        moonbitlang$core$array$$Array$push$17$(result, attr);
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  if (ref_ === undefined) {
  } else {
    const _Some = ref_;
    const _cb = _Some;
    const handler = (el) => {
      _cb(el);
    };
    moonbitlang$core$array$$Array$push$17$(result, { _0: "__ref", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Handler(handler) });
  }
  if (attrs.$tag === 1) {
    const _Some = attrs;
    const _extra = _Some._0;
    const _len = _extra.length;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const pair = _extra[_i];
        moonbitlang$core$array$$Array$push$17$(result, { _0: pair._0, _1: mizchi$luna$luna$dom$element$$Attr$to_attr_value(pair._1) });
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  if (dyn_attrs.$tag === 1) {
    const _Some = dyn_attrs;
    const _extra = _Some._0;
    const _len = _extra.length;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const pair = _extra[_i];
        moonbitlang$core$array$$Array$push$17$(result, pair);
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  return result;
}
function mizchi$luna$luna$dom$element$$nav(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("nav", props, children);
}
function mizchi$luna$luna$dom$element$$article(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("article", props, children);
}
function mizchi$luna$luna$dom$element$$div(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("div", props, children);
}
function mizchi$luna$luna$dom$element$$p(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("p", props, children);
}
function mizchi$luna$luna$dom$element$$a(href, target, id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (href === undefined) {
  } else {
    const _Some = href;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "href", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(_v) });
  }
  if (target === undefined) {
  } else {
    const _Some = target;
    const _v = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "target", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Static(_v) });
  }
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("a", props, children);
}
function mizchi$luna$luna$dom$element$$h1(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("h1", props, children);
}
function mizchi$luna$luna$dom$element$$h2(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("h2", props, children);
}
function mizchi$luna$luna$dom$element$$ul(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("ul", props, children);
}
function mizchi$luna$luna$dom$element$$li(id, class_, style, dyn_class, dyn_style, on, ref_, attrs, dyn_attrs, children) {
  const props = mizchi$luna$luna$dom$element$$build_props$46$inner(id, class_, style, on, ref_, attrs, dyn_attrs);
  if (dyn_class === undefined) {
  } else {
    const _Some = dyn_class;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "className", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  if (dyn_style === undefined) {
  } else {
    const _Some = dyn_style;
    const _getter = _Some;
    moonbitlang$core$array$$Array$push$17$(props, { _0: "style", _1: new $64$mizchi$47$luna$47$luna$47$dom$47$element$46$AttrValue$Dynamic(_getter) });
  }
  return mizchi$luna$luna$dom$element$$create_element("li", props, children);
}
function mizchi$luna$luna$dom$element$$text(content) {
  return mizchi$luna$luna$dom$element$$ToDomNode$to_dom_node$8$(content);
}
function mizchi$luna$luna$dom$element$$text_dyn(content) {
  return mizchi$luna$luna$dom$element$$text_node(content);
}
function mizchi$luna$internal$utils$$split_by(s, sep) {
  const result = [];
  const chars = moonbitlang$core$string$$String$to_array(s);
  const current = [];
  const _len = chars.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars[_i];
      if (c === sep) {
        moonbitlang$core$array$$Array$push$8$(result, moonbitlang$core$string$$String$from_array({ buf: current, start: 0, end: current.length }));
        moonbitlang$core$array$$Array$clear$10$(current);
      } else {
        moonbitlang$core$array$$Array$push$10$(current, c);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  moonbitlang$core$array$$Array$push$8$(result, moonbitlang$core$string$$String$from_array({ buf: current, start: 0, end: current.length }));
  return result;
}
function mizchi$luna$luna$routes$$RoutesMatch$get_param(self, key) {
  const _arr = self.params;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const pair = _arr[_i];
      if (pair._0 === key) {
        return pair._1;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return undefined;
}
function mizchi$luna$luna$routes$$parse_query(query) {
  const _p = "";
  if (!(query === _p)) {
    const result = [];
    const _arr = mizchi$luna$internal$utils$$split_by(query, 38);
    const _len = _arr.length;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const pair = _arr[_i];
        const kv = mizchi$luna$internal$utils$$split_by(pair, 61);
        if (kv.length === 2) {
          moonbitlang$core$array$$Array$push$19$(result, { _0: moonbitlang$core$array$$Array$at$8$(kv, 0), _1: moonbitlang$core$array$$Array$at$8$(kv, 1) });
        } else {
          let _tmp$2;
          if (kv.length === 1) {
            const _p$2 = moonbitlang$core$array$$Array$at$8$(kv, 0);
            const _p$3 = "";
            _tmp$2 = !(_p$2 === _p$3);
          } else {
            _tmp$2 = false;
          }
          if (_tmp$2) {
            moonbitlang$core$array$$Array$push$19$(result, { _0: moonbitlang$core$array$$Array$at$8$(kv, 0), _1: "" });
          }
        }
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return result;
  } else {
    return [];
  }
}
function mizchi$luna$luna$routes$$parse_url_parts(url) {
  const chars = moonbitlang$core$string$$String$to_array(url);
  let query_start = -1;
  const _len = chars.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars[_i];
      if (c === 63) {
        query_start = _i;
        break;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (query_start === -1) {
    return { _0: url, _1: [] };
  }
  const path = moonbitlang$core$string$$String$from_array(moonbitlang$core$array$$Array$sub$46$inner$10$(chars, 0, query_start));
  const query_str = moonbitlang$core$string$$String$from_array(moonbitlang$core$array$$Array$sub$46$inner$10$(chars, query_start + 1 | 0, undefined));
  const query = mizchi$luna$luna$routes$$parse_query(query_str);
  return { _0: path, _1: query };
}
function mizchi$luna$luna$routes$$is_bracket_param(s) {
  return moonbitlang$core$string$$String$has_prefix(s, { str: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$160, start: 0, end: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$160.length }) && (moonbitlang$core$string$$String$has_suffix(s, { str: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$161, start: 0, end: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$161.length }) && (!moonbitlang$core$string$$String$has_prefix(s, { str: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$162, start: 0, end: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$162.length }) && !moonbitlang$core$string$$String$has_prefix(s, { str: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$163, start: 0, end: mizchi$luna$luna$routes$$is_bracket_param$46$42$bind$124$163.length })));
}
function mizchi$luna$luna$routes$$join_segments(segments) {
  if (segments.length === 0) {
    return "";
  }
  const result = moonbitlang$core$builtin$$StringBuilder$new$46$inner(0);
  const _len = segments.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const seg = segments[_i];
      if (_i > 0) {
        moonbitlang$core$builtin$$Logger$write_string$0$(result, "/");
      }
      moonbitlang$core$builtin$$Logger$write_string$0$(result, seg);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result.val;
}
function mizchi$luna$luna$routes$$split_path_segments(path) {
  const _p = mizchi$luna$internal$utils$$split_by(path, 47);
  const _p$2 = [];
  const _p$3 = _p.length;
  let _tmp = 0;
  while (true) {
    const _p$4 = _tmp;
    if (_p$4 < _p$3) {
      const _p$5 = _p[_p$4];
      const _p$6 = "";
      if (!(_p$5 === _p$6)) {
        moonbitlang$core$array$$Array$push$8$(_p$2, _p$5);
      }
      _tmp = _p$4 + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return _p$2;
}
function mizchi$luna$luna$routes$$starts_with_char(s, c) {
  const _bind = moonbitlang$core$builtin$$Show$to_string$10$(c);
  return moonbitlang$core$string$$String$has_prefix(s, { str: _bind, start: 0, end: _bind.length });
}
function mizchi$luna$luna$routes$$try_match_pattern(path, route) {
  const pattern_segments = mizchi$luna$luna$routes$$split_path_segments(route.pattern);
  const path_segments = mizchi$luna$luna$routes$$split_path_segments(path);
  const _bind = route.catch_all;
  if (_bind === undefined) {
    if (pattern_segments.length !== path_segments.length) {
      return Option$None$5$;
    }
    const params = [];
    let param_idx = 0;
    const _len = pattern_segments.length;
    let _tmp = 0;
    while (true) {
      const _i = _tmp;
      if (_i < _len) {
        const pattern_seg = pattern_segments[_i];
        const path_seg = moonbitlang$core$array$$Array$at$8$(path_segments, _i);
        if (mizchi$luna$luna$routes$$starts_with_char(pattern_seg, 58) || mizchi$luna$luna$routes$$is_bracket_param(pattern_seg)) {
          if (param_idx < route.param_names.length) {
            moonbitlang$core$array$$Array$push$19$(params, { _0: moonbitlang$core$array$$Array$at$8$(route.param_names, param_idx), _1: path_seg });
            param_idx = param_idx + 1 | 0;
          } else {
            return Option$None$5$;
          }
        } else {
          if (!(pattern_seg === path_seg)) {
            return Option$None$5$;
          }
        }
        _tmp = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return new Option$Some$5$(params);
  } else {
    const _Some = _bind;
    const _catch_all_info = _Some;
    const base_pattern_len = pattern_segments.length - 1 | 0;
    const path_len = path_segments.length;
    if (_catch_all_info.optional) {
      if (path_len < base_pattern_len) {
        return Option$None$5$;
      }
    } else {
      if (path_len <= base_pattern_len) {
        return Option$None$5$;
      }
    }
    const params = [];
    let param_idx = 0;
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < base_pattern_len) {
        const pattern_seg = moonbitlang$core$array$$Array$at$8$(pattern_segments, i);
        const path_seg = moonbitlang$core$array$$Array$at$8$(path_segments, i);
        if (mizchi$luna$luna$routes$$starts_with_char(pattern_seg, 58) || mizchi$luna$luna$routes$$is_bracket_param(pattern_seg)) {
          if (param_idx < route.param_names.length) {
            moonbitlang$core$array$$Array$push$19$(params, { _0: moonbitlang$core$array$$Array$at$8$(route.param_names, param_idx), _1: path_seg });
            param_idx = param_idx + 1 | 0;
          } else {
            return Option$None$5$;
          }
        } else {
          if (!(pattern_seg === path_seg)) {
            return Option$None$5$;
          }
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    const catch_all_segments = [];
    let _tmp$2 = base_pattern_len;
    while (true) {
      const i = _tmp$2;
      if (i < path_len) {
        moonbitlang$core$array$$Array$push$8$(catch_all_segments, moonbitlang$core$array$$Array$at$8$(path_segments, i));
        _tmp$2 = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    const catch_all_value = mizchi$luna$luna$routes$$join_segments(catch_all_segments);
    moonbitlang$core$array$$Array$push$19$(params, { _0: _catch_all_info.name, _1: catch_all_value });
    return new Option$Some$5$(params);
  }
}
function mizchi$luna$luna$routes$$match_url(url, routes) {
  const _bind = mizchi$luna$luna$routes$$parse_url_parts(url);
  const _path = _bind._0;
  const _query = _bind._1;
  const _len = routes.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const route = routes[_i];
      const _bind$2 = mizchi$luna$luna$routes$$try_match_pattern(_path, route);
      if (_bind$2.$tag === 1) {
        const _Some = _bind$2;
        const _params = _Some._0;
        return { route: route, params: _params, query: _query, path: _path };
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return undefined;
}
function mizchi$luna$luna$routes$$normalize_path(path) {
  if (path === "" || path === "/") {
    return "/";
  }
  const chars = moonbitlang$core$string$$String$to_array(path);
  const result = [];
  let prev_slash = false;
  const _len = chars.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars[_i];
      if (c === 47) {
        if (!prev_slash) {
          moonbitlang$core$array$$Array$push$10$(result, c);
        }
        prev_slash = true;
      } else {
        moonbitlang$core$array$$Array$push$10$(result, c);
        prev_slash = false;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const len = result.length;
  if (len > 1 && moonbitlang$core$array$$Array$at$10$(result, len - 1 | 0) === 47) {
    moonbitlang$core$array$$Array$pop$10$(result);
  }
  return moonbitlang$core$string$$String$from_array({ buf: result, start: 0, end: result.length });
}
function mizchi$luna$luna$routes$$extract_param_names(path) {
  const result = [];
  const segments = mizchi$luna$internal$utils$$split_by(path, 47);
  const _len = segments.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      _L: {
        const segment = segments[_i];
        if (moonbitlang$core$string$$String$has_prefix(segment, { str: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$194, start: 0, end: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$194.length }) && segment.length > 1) {
          let name;
          let _try_err;
          _L$2: {
            _L$3: {
              const _bind = moonbitlang$core$string$$String$sub$46$inner(segment, 1, undefined);
              let _tmp$2;
              if (_bind.$tag === 1) {
                const _ok = _bind;
                _tmp$2 = _ok._0;
              } else {
                const _err = _bind;
                const _tmp$3 = _err._0;
                _try_err = _tmp$3;
                break _L$3;
              }
              name = moonbitlang$core$builtin$$Show$to_string$3$(_tmp$2);
              break _L$2;
            }
            break _L;
          }
          moonbitlang$core$array$$Array$push$8$(result, name);
        } else {
          if (moonbitlang$core$string$$String$has_prefix(segment, { str: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$198, start: 0, end: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$198.length }) && (!moonbitlang$core$string$$String$has_prefix(segment, { str: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$199, start: 0, end: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$199.length }) && !moonbitlang$core$string$$String$has_prefix(segment, { str: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$200, start: 0, end: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$200.length }))) {
            if (moonbitlang$core$string$$String$has_suffix(segment, { str: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$201, start: 0, end: mizchi$luna$luna$routes$$extract_param_names$46$42$bind$124$201.length }) && segment.length > 2) {
              let name;
              let _try_err;
              _L$2: {
                _L$3: {
                  const _bind = moonbitlang$core$string$$String$sub$46$inner(segment, 1, segment.length - 1 | 0);
                  let _tmp$2;
                  if (_bind.$tag === 1) {
                    const _ok = _bind;
                    _tmp$2 = _ok._0;
                  } else {
                    const _err = _bind;
                    const _tmp$3 = _err._0;
                    _try_err = _tmp$3;
                    break _L$3;
                  }
                  name = moonbitlang$core$builtin$$Show$to_string$3$(_tmp$2);
                  break _L$2;
                }
                break _L;
              }
              moonbitlang$core$array$$Array$push$8$(result, name);
            }
          }
        }
        break _L;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function mizchi$luna$luna$routes$$extract_catch_all(path) {
  const segments = mizchi$luna$internal$utils$$split_by(path, 47);
  if (segments.length === 0) {
    return undefined;
  }
  const last = moonbitlang$core$array$$Array$at$8$(segments, segments.length - 1 | 0);
  if (moonbitlang$core$string$$String$has_prefix(last, { str: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$205, start: 0, end: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$205.length }) && (moonbitlang$core$string$$String$has_suffix(last, { str: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$206, start: 0, end: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$206.length }) && last.length > 7)) {
    let name;
    let _try_err;
    _L: {
      _L$2: {
        const _bind = moonbitlang$core$string$$String$sub$46$inner(last, 5, last.length - 2 | 0);
        let _tmp;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _tmp = _ok._0;
        } else {
          const _err = _bind;
          const _tmp$2 = _err._0;
          _try_err = _tmp$2;
          break _L$2;
        }
        name = moonbitlang$core$builtin$$Show$to_string$3$(_tmp);
        break _L;
      }
      return undefined;
    }
    return { name: name, optional: true };
  }
  if (moonbitlang$core$string$$String$has_prefix(last, { str: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$210, start: 0, end: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$210.length }) && (moonbitlang$core$string$$String$has_suffix(last, { str: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$211, start: 0, end: mizchi$luna$luna$routes$$extract_catch_all$46$42$bind$124$211.length }) && last.length > 5)) {
    let name;
    let _try_err;
    _L: {
      _L$2: {
        const _bind = moonbitlang$core$string$$String$sub$46$inner(last, 4, last.length - 1 | 0);
        let _tmp;
        if (_bind.$tag === 1) {
          const _ok = _bind;
          _tmp = _ok._0;
        } else {
          const _err = _bind;
          const _tmp$2 = _err._0;
          _try_err = _tmp$2;
          break _L$2;
        }
        name = moonbitlang$core$builtin$$Show$to_string$3$(_tmp);
        break _L;
      }
      return undefined;
    }
    return { name: name, optional: false };
  }
  return undefined;
}
function mizchi$luna$luna$routes$$compile_inner(routes, prefix, inherited_layouts, result) {
  const _len = routes.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const route = routes[_i];
      switch (route.$tag) {
        case 0: {
          const _Page = route;
          const _path = _Page._0;
          const _component = _Page._1;
          const _title = _Page._2;
          const _meta = _Page._3;
          const full_path = mizchi$luna$luna$routes$$normalize_path(`${prefix}${_path}`);
          const param_names = mizchi$luna$luna$routes$$extract_param_names(full_path);
          const catch_all = mizchi$luna$luna$routes$$extract_catch_all(full_path);
          moonbitlang$core$array$$Array$push$18$(result, { pattern: full_path, param_names: param_names, component: _component, layouts: moonbitlang$core$array$$Array$copy$8$(inherited_layouts), kind: 0, title: _title, meta: _meta, catch_all: catch_all });
          break;
        }
        case 2: {
          const _Get = route;
          const _path$2 = _Get._0;
          const _handler = _Get._1;
          const full_path$2 = mizchi$luna$luna$routes$$normalize_path(`${prefix}${_path$2}`);
          const param_names$2 = mizchi$luna$luna$routes$$extract_param_names(full_path$2);
          const catch_all$2 = mizchi$luna$luna$routes$$extract_catch_all(full_path$2);
          moonbitlang$core$array$$Array$push$18$(result, { pattern: full_path$2, param_names: param_names$2, component: _handler, layouts: [], kind: 1, title: "", meta: [], catch_all: catch_all$2 });
          break;
        }
        case 3: {
          const _Post = route;
          const _path$3 = _Post._0;
          const _handler$2 = _Post._1;
          const full_path$3 = mizchi$luna$luna$routes$$normalize_path(`${prefix}${_path$3}`);
          const param_names$3 = mizchi$luna$luna$routes$$extract_param_names(full_path$3);
          const catch_all$3 = mizchi$luna$luna$routes$$extract_catch_all(full_path$3);
          moonbitlang$core$array$$Array$push$18$(result, { pattern: full_path$3, param_names: param_names$3, component: _handler$2, layouts: [], kind: 2, title: "", meta: [], catch_all: catch_all$3 });
          break;
        }
        default: {
          const _Layout = route;
          const _segment = _Layout._0;
          const _children = _Layout._1;
          const _layout = _Layout._2;
          const new_prefix = mizchi$luna$luna$routes$$normalize_path(`${prefix}${_segment}`);
          const new_layouts = moonbitlang$core$array$$Array$copy$8$(inherited_layouts);
          moonbitlang$core$array$$Array$push$8$(new_layouts, _layout);
          mizchi$luna$luna$routes$$compile_inner(_children, new_prefix, new_layouts, result);
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function mizchi$luna$luna$routes$$compile$46$inner(routes, base) {
  const result = [];
  mizchi$luna$luna$routes$$compile_inner(routes, base, [], result);
  return result;
}
function mizchi$luna$luna$dom$router$$get_current_url() {
  const pathname = mizchi$luna$luna$dom$router$$get_pathname();
  const search = mizchi$luna$luna$dom$router$$get_search();
  return !(search === "") ? `${pathname}${search}` : pathname;
}
function mizchi$luna$luna$dom$router$$BrowserRouter$sync_from_url(self) {
  const path = mizchi$luna$luna$dom$router$$get_current_url();
  mizchi$luna$luna$signal$$Signal$set$8$(self.current_path, path);
  mizchi$luna$luna$signal$$Signal$set$25$(self.current_match, mizchi$luna$luna$routes$$match_url(path, self.routes));
}
function mizchi$luna$luna$dom$router$$BrowserRouter$new$46$inner(routes, base) {
  const compiled = mizchi$luna$luna$routes$$compile$46$inner(routes, base);
  const initial_path = mizchi$luna$luna$dom$router$$get_current_url();
  const initial_match = mizchi$luna$luna$routes$$match_url(initial_path, compiled);
  const router = { routes: compiled, base: base, current_path: mizchi$luna$luna$signal$$signal$8$(initial_path), current_match: mizchi$luna$luna$signal$$signal$25$(initial_match) };
  mizchi$luna$luna$dom$router$$add_popstate_listener(() => {
    mizchi$luna$luna$dom$router$$BrowserRouter$sync_from_url(router);
  });
  return router;
}
function mizchi$luna$luna$dom$router$$BrowserRouter$update_state(self, path) {
  mizchi$luna$luna$signal$$Signal$set$8$(self.current_path, path);
  mizchi$luna$luna$signal$$Signal$set$25$(self.current_match, mizchi$luna$luna$routes$$match_url(path, self.routes));
}
function mizchi$luna$luna$dom$router$$BrowserRouter$navigate(self, path) {
  mizchi$luna$luna$dom$router$$push_state(path);
  mizchi$luna$luna$dom$router$$BrowserRouter$update_state(self, path);
}
function mizchi$luna$luna$dom$router$$BrowserRouter$get_path(self) {
  return mizchi$luna$luna$signal$$Signal$get$8$(self.current_path);
}
function mizchi$luna$examples$wiki$$find_page(slug) {
  const pages = [mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$921, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$922, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$923, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$924, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$925];
  const _len = pages.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const page = pages[_i];
      if (page.slug === slug) {
        return page;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return undefined;
}
function mizchi$luna$examples$wiki$$header_nav_component(router) {
  const base = router.base;
  const pages = [mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$921, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$922, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$923, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$924, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$925];
  const _bind = moonbitlang$core$array$$Array$iter$16$(pages);
  return mizchi$luna$luna$dom$element$$nav(undefined, mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$932, mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$933, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, moonbitlang$core$builtin$$Iter$collect$20$((_p) => _bind((_p$2) => {
    const _p$3 = _p$2.slug;
    const _p$4 = "index";
    if (!(_p$3 === _p$4)) {
      const href = `${base}/${_p$2.slug}`;
      const label = _p$2.title;
      return _p(mizchi$luna$luna$dom$element$$a(href, undefined, undefined, mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$934, mizchi$luna$examples$wiki$$header_nav_component$46$constr$47$935, undefined, undefined, new Option$Some$6$(mizchi$luna$luna$dom$element$$HandlerMap$click(mizchi$luna$luna$dom$element$$events(), (e) => {
        mizchi$js$browser$dom$$MouseEvent$preventDefault(e);
        mizchi$luna$luna$dom$router$$BrowserRouter$navigate(router, href);
      })), undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text(label)]));
    } else {
      return 1;
    }
  })));
}
function mizchi$luna$examples$wiki$$wiki_index_component(_router) {
  const pages = [mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$921, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$922, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$923, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$924, mizchi$luna$examples$wiki$$get_wiki_pages$46$record$47$925];
  const _tmp = mizchi$luna$luna$dom$element$$h1(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("Wiki Home")]);
  const _tmp$2 = mizchi$luna$luna$dom$element$$p(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("Welcome to the wiki! Select a page from the navigation above.")]);
  const _tmp$3 = mizchi$luna$luna$dom$element$$h2(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("Available Pages")]);
  const _bind = moonbitlang$core$array$$Array$iter$16$(pages);
  return mizchi$luna$luna$dom$element$$article(undefined, mizchi$luna$examples$wiki$$wiki_index_component$46$constr$47$945, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [_tmp, _tmp$2, _tmp$3, mizchi$luna$luna$dom$element$$ul(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, moonbitlang$core$builtin$$Iter$collect$20$((_p) => _bind((_p$2) => {
    const _p$3 = _p$2.slug;
    const _p$4 = "index";
    if (!(_p$3 === _p$4)) {
      return _p(mizchi$luna$luna$dom$element$$li(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text(_p$2.title)]));
    } else {
      return 1;
    }
  })))]);
}
function mizchi$luna$examples$wiki$$wiki_page_component(_router, m) {
  const _p = mizchi$luna$luna$routes$$RoutesMatch$get_param(m, "slug");
  const _p$2 = "index";
  let slug;
  if (_p === undefined) {
    slug = _p$2;
  } else {
    const _p$3 = _p;
    slug = _p$3;
  }
  const _bind = mizchi$luna$examples$wiki$$find_page(slug);
  if (_bind === undefined) {
    return mizchi$luna$luna$dom$element$$article(undefined, mizchi$luna$examples$wiki$$wiki_page_component$46$constr$47$952, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$h1(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("Page Not Found")]), mizchi$luna$luna$dom$element$$p(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text(`The page '${slug}' does not exist.`)])]);
  } else {
    const _Some = _bind;
    const _page = _Some;
    return mizchi$luna$luna$dom$element$$article(undefined, mizchi$luna$examples$wiki$$wiki_page_component$46$constr$47$951, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$h1(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text(_page.title)]), mizchi$luna$luna$dom$element$$p(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text(_page.content)])]);
  }
}
function mizchi$luna$examples$wiki$$not_found_component(router) {
  const base = router.base;
  return mizchi$luna$luna$dom$element$$article(undefined, mizchi$luna$examples$wiki$$not_found_component$46$constr$47$959, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$h1(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("404 - Not Found")]), mizchi$luna$luna$dom$element$$p(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("Page not found: "), mizchi$luna$luna$dom$element$$text_dyn(() => mizchi$luna$luna$dom$router$$BrowserRouter$get_path(router))]), mizchi$luna$luna$dom$element$$p(undefined, undefined, undefined, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$a(base, undefined, undefined, undefined, undefined, undefined, undefined, new Option$Some$6$(mizchi$luna$luna$dom$element$$HandlerMap$click(mizchi$luna$luna$dom$element$$events(), (e) => {
    mizchi$js$browser$dom$$MouseEvent$preventDefault(e);
    mizchi$luna$luna$dom$router$$BrowserRouter$navigate(router, base);
  })), undefined, Option$None$7$, Option$None$8$, [mizchi$luna$luna$dom$element$$text("← Back to Wiki Home")])])]);
}
function mizchi$luna$examples$wiki$$resolve_component(router, m) {
  const component_id = m.route.component;
  switch (component_id) {
    case "wiki_index": {
      return mizchi$luna$examples$wiki$$wiki_index_component(router);
    }
    case "wiki_page": {
      return mizchi$luna$examples$wiki$$wiki_page_component(router, m);
    }
    default: {
      return mizchi$luna$examples$wiki$$not_found_component(router);
    }
  }
}
function mizchi$luna$examples$wiki$$render_wiki(router, container) {
  mizchi$luna$luna$signal$$effect(() => {
    const match_result = mizchi$luna$luna$signal$$Signal$get$25$(router.current_match);
    mizchi$luna$luna$dom$element$$clear(container);
    const _bind = mizchi$luna$luna$signal$$untracked$26$(() => {
      const header = mizchi$luna$examples$wiki$$header_nav_component(router);
      let content;
      if (match_result === undefined) {
        content = mizchi$luna$examples$wiki$$not_found_component(router);
      } else {
        const _Some = match_result;
        const _m = _Some;
        content = mizchi$luna$examples$wiki$$resolve_component(router, _m);
      }
      return { _0: header, _1: content };
    });
    const _header = _bind._0;
    const _content = _bind._1;
    const app = mizchi$luna$luna$signal$$untracked$20$(() => mizchi$luna$luna$dom$element$$div(undefined, mizchi$luna$examples$wiki$$render_wiki$46$constr$47$966, mizchi$luna$examples$wiki$$render_wiki$46$constr$47$967, undefined, undefined, Option$None$6$, undefined, Option$None$7$, Option$None$8$, [_header, _content]));
    mizchi$luna$luna$dom$element$$mount(container, app);
  });
}
function mizchi$luna$examples$wiki$$hydrate(el, _state) {
  const routes = [new $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Page("", "wiki_index", "Wiki Home", []), new $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Page("/:slug", "wiki_page", "Wiki Page", [])];
  const router = mizchi$luna$luna$dom$router$$BrowserRouter$new$46$inner(routes, mizchi$luna$examples$wiki$$hydrate$46$base$124$9);
  const dom_container = mizchi$luna$luna$dom$element$$DomElement$from_dom(el);
  mizchi$luna$examples$wiki$$render_wiki(router, dom_container);
  mizchi$js$browser$dom$$Element$removeAttribute(el, "data-spa-cloak");
  mizchi$js$browser$dom$$Element$setAttribute(el, "data-hydrated", "true");
}
(() => {
  const doc = mizchi$js$browser$dom$$document();
  const _bind = mizchi$js$browser$dom$$Document$getElementById(doc, "wiki-app");
  if (_bind.$tag === 1) {
    const _Some = _bind;
    const _el = _Some._0;
    const routes = [new $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Page("", "wiki_index", "Wiki Home", []), new $64$mizchi$47$luna$47$luna$47$routes$46$Routes$Page("/:slug", "wiki_page", "Wiki Page", [])];
    const router = mizchi$luna$luna$dom$router$$BrowserRouter$new$46$inner(routes, mizchi$luna$examples$wiki$$_init$42$46$base$124$3);
    const dom_container = mizchi$luna$luna$dom$element$$DomElement$from_dom(_el);
    mizchi$luna$examples$wiki$$render_wiki(router, dom_container);
    return;
  } else {
    return;
  }
})();
export { mizchi$luna$examples$wiki$$hydrate as hydrate }
