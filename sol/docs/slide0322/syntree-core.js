function _M0TP36mizchi7syntree9highlight14HighlightTheme(param0, param1, param2, param3, param4, param5, param6, param7, param8, param9, param10, param11, param12, param13, param14, param15, param16, param17, param18, param19, param20, param21) {
  this.name = param0;
  this.background = param1;
  this.foreground = param2;
  this.keyword = param3;
  this.operator = param4;
  this.punctuation = param5;
  this.string = param6;
  this.number = param7;
  this.bool = param8;
  this.null = param9;
  this.property = param10;
  this.variable = param11;
  this.function_ = param12;
  this.type_ = param13;
  this.class_ = param14;
  this.comment = param15;
  this.doc_comment = param16;
  this.regexp = param17;
  this.meta = param18;
  this.bracket = param19;
  this.tag = param20;
  this.invalid = param21;
}
class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
function _M0TPB13StringBuilder(param0) {
  this.val = param0;
}
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function _M0TPC16string10StringView(param0, param1, param2) {
  this.str = param0;
  this.start = param1;
  this.end = param2;
}
function _M0TPB13SourceLocRepr(param0, param1, param2, param3, param4, param5) {
  this.pkg = param0;
  this.filename = param1;
  this.start_line = param2;
  this.start_column = param3;
  this.end_line = param4;
  this.end_column = param5;
}
function $compare_int(a, b) {
  return (a >= b) - (a <= b);
}
const _M0FPB12random__seed = () => {
  if (globalThis.crypto?.getRandomValues) {
    const array = new Uint32Array(1);
    globalThis.crypto.getRandomValues(array);
    return array[0] | 0; // Convert to signed 32
  } else {
    return Math.floor(Math.random() * 0x100000000) | 0; // Fallback to Math.random
  }
};
function _M0TPB6Hasher(param0) {
  this.acc = param0;
}
const _M0MPB7JSArray4push = (arr, val) => { arr.push(val); };
function _M0TPC13ref3RefGiE(param0) {
  this.val = param0;
}
function _M0TPB9ArrayViewGRP26mizchi7syntree4TreeE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
function _M0TPB3MapGsRP26mizchi7syntree12HighlightTagE(param0, param1, param2, param3, param4, param5, param6) {
  this.entries = param0;
  this.size = param1;
  this.capacity = param2;
  this.capacity_mask = param3;
  this.grow_at = param4;
  this.head = param5;
  this.tail = param6;
}
function _M0TPB5EntryGsRP26mizchi7syntree12HighlightTagE(param0, param1, param2, param3, param4, param5) {
  this.prev = param0;
  this.next = param1;
  this.psl = param2;
  this.hash = param3;
  this.key = param4;
  this.value = param5;
}
function _M0TPB9ArrayViewGcE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
const _M0MPB7JSArray3pop = (arr) => arr.pop();
function _M0TP26mizchi7syntree8NodeType(param0, param1, param2) {
  this.id = param0;
  this.name = param1;
  this.is_error = param2;
}
function _M0TP26mizchi7syntree14HighlightToken(param0, param1, param2) {
  this.from = param0;
  this.to = param1;
  this.tag = param2;
}
function _M0TP26mizchi7syntree11Highlighter(param0) {
  this.rules = param0;
}
function _M0TPB9ArrayViewGUsRP26mizchi7syntree12HighlightTagEE(param0, param1, param2) {
  this.buf = param0;
  this.start = param1;
  this.end = param2;
}
function _M0TP36mizchi7syntree4bash13BashTokenizer(param0, param1, param2, param3, param4, param5) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
  this.at_line_start = param4;
  this.after_command = param5;
}
function _M0TP36mizchi7syntree4bash9BashToken(param0, param1, param2) {
  this.token_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree3css12CssTokenizer(param0, param1, param2, param3, param4, param5) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
  this.in_block = param4;
  this.after_colon = param5;
}
function _M0TP36mizchi7syntree3css8CssToken(param0, param1, param2) {
  this.token_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree4html13HtmlTokenizer(param0, param1, param2, param3) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
}
function _M0TP36mizchi7syntree4html9HtmlToken(param0, param1, param2) {
  this.token_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree4json13JsonTokenizer(param0, param1, param2, param3) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
}
function _M0TP36mizchi7syntree4json9JsonToken(param0, param1, param2) {
  this.node_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree4json10JsonParser(param0, param1, param2) {
  this.input = param0;
  this.tokens = param1;
  this.pos = param2;
}
function _M0DTP26mizchi7syntree4Tree4Node(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
_M0DTP26mizchi7syntree4Tree4Node.prototype.$tag = 0;
function _M0DTP26mizchi7syntree4Tree4Leaf(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
_M0DTP26mizchi7syntree4Tree4Leaf.prototype.$tag = 1;
function _M0DTP26mizchi7syntree4Tree8Buffered(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
_M0DTP26mizchi7syntree4Tree8Buffered.prototype.$tag = 2;
function _M0TP36mizchi7syntree7moonbit12MbtTokenizer(param0, param1, param2, param3, param4) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
  this.context_stack = param4;
}
function _M0TP36mizchi7syntree7moonbit8MbtToken(param0, param1, param2) {
  this.token_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree4rust13RustTokenizer(param0, param1, param2, param3) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
}
function _M0TP36mizchi7syntree4rust9RustToken(param0, param1, param2) {
  this.token_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree10typescript11TsTokenizer(param0, param1, param2, param3, param4, param5) {
  this.input = param0;
  this.chars = param1;
  this.len = param2;
  this.pos = param3;
  this.context_stack = param4;
  this.last_token = param5;
}
function _M0TP36mizchi7syntree10typescript7TsToken(param0, param1, param2) {
  this.token_type = param0;
  this.from = param1;
  this.to = param2;
}
function _M0TP36mizchi7syntree9highlight12ColoredToken(param0, param1, param2) {
  this.from = param0;
  this.to = param1;
  this.color = param2;
}
const _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger = { method_0: _M0IPB13StringBuilderPB6Logger13write__string, method_1: _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE, method_2: _M0IPB13StringBuilderPB6Logger11write__view, method_3: _M0IPB13StringBuilderPB6Logger11write__char };
const _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232 = new _M0TP36mizchi7syntree9highlight14HighlightTheme("github-dark", "#0d1117", "#c9d1d9", "#ff7b72", "#ff7b72", "#c9d1d9", "#a5d6ff", "#79c0ff", "#79c0ff", "#79c0ff", "#7ee787", "#c9d1d9", "#d2a8ff", "#ffa657", "#ffa657", "#8b949e", "#8b949e", "#7ee787", "#d2a8ff", "#c9d1d9", "#7ee787", "#f85149");
const _M0FPB4seed = _M0FPB12random__seed();
const _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1179 = 31;
const _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1180 = 38;
const _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1181 = 32;
const _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1182 = 30;
const _M0FP36mizchi7syntree4html28tokenize__all_2econstr_2f703 = 47;
const _M0FP36mizchi7syntree4html28tokenize__all_2econstr_2f704 = 62;
const _M0FP36mizchi7syntree3css28tokenize__all_2econstr_2f602 = 42;
const _M0FP36mizchi7syntree3css28tokenize__all_2econstr_2f603 = 58;
const _M0FP36mizchi7syntree4bash28read__comment_2econstr_2f468 = 33;
const _M0FP36mizchi7syntree4bash29read__variable_2econstr_2f484 = 40;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f507 = 39;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f508 = 40;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f509 = 124;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f510 = 38;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f511 = 38;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f512 = 62;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f513 = 59;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f514 = 91;
const _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f515 = 93;
function _M0FPC15abort5abortGRPB9ArrayViewGcEE(msg) {
  return $panic();
}
function _M0MPB6Hasher8consume4(self, input) {
  const _p = (self.acc >>> 0) + ((Math.imul(input, -1028477379) | 0) >>> 0) | 0;
  const _p$2 = 17;
  self.acc = Math.imul(_p << _p$2 | (_p >>> (32 - _p$2 | 0) | 0), 668265263) | 0;
}
function _M0MPB6Hasher13combine__uint(self, value) {
  self.acc = (self.acc >>> 0) + (4 >>> 0) | 0;
  _M0MPB6Hasher8consume4(self, value);
}
function _M0FPB5abortGRPB9ArrayViewGcEE(string, loc) {
  return _M0FPC15abort5abortGRPB9ArrayViewGcEE(`${string}\n  at ${_M0IP016_24default__implPB4Show10to__stringGRPB9SourceLocE(loc)}\n`);
}
function _M0MPB13StringBuilder11new_2einner(size_hint) {
  return new _M0TPB13StringBuilder("");
}
function _M0IPB13StringBuilderPB6Logger11write__char(self, ch) {
  self.val = `${self.val}${String.fromCodePoint(ch)}`;
}
function _M0MPC16uint166UInt1622is__leading__surrogate(self) {
  return _M0IP016_24default__implPB7Compare6op__geGkE(self, 55296) && _M0IP016_24default__implPB7Compare6op__leGkE(self, 56319);
}
function _M0MPC16uint166UInt1623is__trailing__surrogate(self) {
  return _M0IP016_24default__implPB7Compare6op__geGkE(self, 56320) && _M0IP016_24default__implPB7Compare6op__leGkE(self, 57343);
}
function _M0FPB32code__point__of__surrogate__pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function _M0MPC15array5Array2atGcE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MPC15array5Array2atGRP36mizchi7syntree10typescript9TsContextE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MPC15array5Array2atGRP36mizchi7syntree7moonbit10MbtContextE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MPC15array5Array2atGRP36mizchi7syntree4json9JsonTokenE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MPB13SourceLocRepr5parse(repr) {
  const _bind = new _M0TPC16string10StringView(repr, 0, repr.length);
  const _data = _bind.str;
  const _start = _bind.start;
  const _end = _start + (_bind.end - _bind.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let match_tag_saver_1 = -1;
  let match_tag_saver_2 = -1;
  let match_tag_saver_3 = -1;
  let match_tag_saver_4 = -1;
  let tag_0 = -1;
  let tag_1 = -1;
  let tag_1_1 = -1;
  let tag_1_2 = -1;
  let tag_3 = -1;
  let tag_2 = -1;
  let tag_2_1 = -1;
  let tag_4 = -1;
  _L: {
    if (_cursor < _end) {
      const _p = _cursor;
      if (_data.charCodeAt(_p) === 64) {
        _cursor = _cursor + 1 | 0;
        _L$2: while (true) {
          tag_0 = _cursor;
          if (_cursor < _end) {
            const _p$2 = _cursor;
            const next_char = _data.charCodeAt(_p$2);
            _cursor = _cursor + 1 | 0;
            if (next_char === 58) {
              if (_cursor < _end) {
                _cursor = _cursor + 1 | 0;
                let _tmp = 0;
                _L$3: while (true) {
                  const dispatch_15 = _tmp;
                  _L$4: {
                    _L$5: {
                      switch (dispatch_15) {
                        case 3: {
                          tag_1_2 = tag_1_1;
                          tag_1_1 = tag_1;
                          tag_1 = _cursor;
                          if (_cursor < _end) {
                            _L$6: {
                              const _p$3 = _cursor;
                              const next_char$2 = _data.charCodeAt(_p$3);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$6;
                                } else {
                                  tag_1 = _cursor;
                                  tag_2_1 = tag_2;
                                  tag_2 = _cursor;
                                  tag_3 = _cursor;
                                  if (_cursor < _end) {
                                    _L$7: {
                                      const _p$4 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$4);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 48) {
                                        if (next_char$3 === 45) {
                                          break _L$4;
                                        } else {
                                          break _L$7;
                                        }
                                      } else {
                                        if (next_char$3 > 57) {
                                          if (next_char$3 < 59) {
                                            _tmp = 3;
                                            continue _L$3;
                                          } else {
                                            break _L$7;
                                          }
                                        } else {
                                          _tmp = 6;
                                          continue _L$3;
                                        }
                                      }
                                    }
                                    _tmp = 0;
                                    continue _L$3;
                                  } else {
                                    break _L;
                                  }
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$6;
                                } else {
                                  _tmp = 1;
                                  continue _L$3;
                                }
                              }
                            }
                            _tmp = 0;
                            continue _L$3;
                          } else {
                            break _L;
                          }
                        }
                        case 2: {
                          tag_1 = _cursor;
                          tag_2 = _cursor;
                          if (_cursor < _end) {
                            _L$6: {
                              const _p$3 = _cursor;
                              const next_char$2 = _data.charCodeAt(_p$3);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 2;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$6;
                                } else {
                                  _tmp = 3;
                                  continue _L$3;
                                }
                              }
                            }
                            _tmp = 0;
                            continue _L$3;
                          } else {
                            break _L;
                          }
                        }
                        case 0: {
                          tag_1 = _cursor;
                          if (_cursor < _end) {
                            const _p$3 = _cursor;
                            const next_char$2 = _data.charCodeAt(_p$3);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$2 === 58) {
                              _tmp = 1;
                              continue _L$3;
                            } else {
                              _tmp = 0;
                              continue _L$3;
                            }
                          } else {
                            break _L;
                          }
                        }
                        case 4: {
                          tag_1 = _cursor;
                          tag_4 = _cursor;
                          if (_cursor < _end) {
                            _L$6: {
                              const _p$3 = _cursor;
                              const next_char$2 = _data.charCodeAt(_p$3);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 4;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$6;
                                } else {
                                  tag_1_2 = tag_1_1;
                                  tag_1_1 = tag_1;
                                  tag_1 = _cursor;
                                  if (_cursor < _end) {
                                    _L$7: {
                                      const _p$4 = _cursor;
                                      const next_char$3 = _data.charCodeAt(_p$4);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$3 < 58) {
                                        if (next_char$3 < 48) {
                                          break _L$7;
                                        } else {
                                          tag_1 = _cursor;
                                          tag_2_1 = tag_2;
                                          tag_2 = _cursor;
                                          if (_cursor < _end) {
                                            _L$8: {
                                              const _p$5 = _cursor;
                                              const next_char$4 = _data.charCodeAt(_p$5);
                                              _cursor = _cursor + 1 | 0;
                                              if (next_char$4 < 58) {
                                                if (next_char$4 < 48) {
                                                  break _L$8;
                                                } else {
                                                  _tmp = 5;
                                                  continue _L$3;
                                                }
                                              } else {
                                                if (next_char$4 > 58) {
                                                  break _L$8;
                                                } else {
                                                  _tmp = 3;
                                                  continue _L$3;
                                                }
                                              }
                                            }
                                            _tmp = 0;
                                            continue _L$3;
                                          } else {
                                            break _L$5;
                                          }
                                        }
                                      } else {
                                        if (next_char$3 > 58) {
                                          break _L$7;
                                        } else {
                                          _tmp = 1;
                                          continue _L$3;
                                        }
                                      }
                                    }
                                    _tmp = 0;
                                    continue _L$3;
                                  } else {
                                    break _L;
                                  }
                                }
                              }
                            }
                            _tmp = 0;
                            continue _L$3;
                          } else {
                            break _L;
                          }
                        }
                        case 5: {
                          tag_1 = _cursor;
                          tag_2 = _cursor;
                          if (_cursor < _end) {
                            _L$6: {
                              const _p$3 = _cursor;
                              const next_char$2 = _data.charCodeAt(_p$3);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 5;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$6;
                                } else {
                                  _tmp = 3;
                                  continue _L$3;
                                }
                              }
                            }
                            _tmp = 0;
                            continue _L$3;
                          } else {
                            break _L$5;
                          }
                        }
                        case 6: {
                          tag_1 = _cursor;
                          tag_2 = _cursor;
                          tag_3 = _cursor;
                          if (_cursor < _end) {
                            _L$6: {
                              const _p$3 = _cursor;
                              const next_char$2 = _data.charCodeAt(_p$3);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$2 < 48) {
                                if (next_char$2 === 45) {
                                  break _L$4;
                                } else {
                                  break _L$6;
                                }
                              } else {
                                if (next_char$2 > 57) {
                                  if (next_char$2 < 59) {
                                    _tmp = 3;
                                    continue _L$3;
                                  } else {
                                    break _L$6;
                                  }
                                } else {
                                  _tmp = 6;
                                  continue _L$3;
                                }
                              }
                            }
                            _tmp = 0;
                            continue _L$3;
                          } else {
                            break _L;
                          }
                        }
                        case 1: {
                          tag_1_1 = tag_1;
                          tag_1 = _cursor;
                          if (_cursor < _end) {
                            _L$6: {
                              const _p$3 = _cursor;
                              const next_char$2 = _data.charCodeAt(_p$3);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$2 < 58) {
                                if (next_char$2 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 2;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$2 > 58) {
                                  break _L$6;
                                } else {
                                  _tmp = 1;
                                  continue _L$3;
                                }
                              }
                            }
                            _tmp = 0;
                            continue _L$3;
                          } else {
                            break _L;
                          }
                        }
                        default: {
                          break _L;
                        }
                      }
                    }
                    tag_1 = tag_1_2;
                    tag_2 = tag_2_1;
                    match_tag_saver_0 = tag_0;
                    match_tag_saver_1 = tag_1;
                    match_tag_saver_2 = tag_2;
                    match_tag_saver_3 = tag_3;
                    match_tag_saver_4 = tag_4;
                    accept_state = 0;
                    match_end = _cursor;
                    break _L;
                  }
                  tag_1_1 = tag_1_2;
                  tag_1 = _cursor;
                  tag_2 = tag_2_1;
                  if (_cursor < _end) {
                    _L$5: {
                      const _p$3 = _cursor;
                      const next_char$2 = _data.charCodeAt(_p$3);
                      _cursor = _cursor + 1 | 0;
                      if (next_char$2 < 58) {
                        if (next_char$2 < 48) {
                          break _L$5;
                        } else {
                          _tmp = 4;
                          continue;
                        }
                      } else {
                        if (next_char$2 > 58) {
                          break _L$5;
                        } else {
                          _tmp = 1;
                          continue;
                        }
                      }
                    }
                    _tmp = 0;
                    continue;
                  } else {
                    break _L;
                  }
                }
              } else {
                break _L;
              }
            } else {
              continue;
            }
          } else {
            break _L;
          }
        }
      } else {
        break _L;
      }
    } else {
      break _L;
    }
  }
  if (accept_state === 0) {
    const start_line = _M0MPC16string6String4view(_data, match_tag_saver_1 + 1 | 0, match_tag_saver_2);
    const start_column = _M0MPC16string6String4view(_data, match_tag_saver_2 + 1 | 0, match_tag_saver_3);
    const pkg = _M0MPC16string6String4view(_data, _start + 1 | 0, match_tag_saver_0);
    const filename = _M0MPC16string6String4view(_data, match_tag_saver_0 + 1 | 0, match_tag_saver_1);
    const end_line = _M0MPC16string6String4view(_data, match_tag_saver_3 + 1 | 0, match_tag_saver_4);
    const end_column = _M0MPC16string6String4view(_data, match_tag_saver_4 + 1 | 0, match_end);
    return new _M0TPB13SourceLocRepr(pkg, filename, start_line, start_column, end_line, end_column);
  } else {
    return $panic();
  }
}
function _M0IPB13StringBuilderPB6Logger13write__string(self, str) {
  self.val = `${self.val}${str}`;
}
function _M0MPB6Hasher7combineGsE(self, value) {
  _M0IPC16string6StringPB4Hash13hash__combine(value, self);
}
function _M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(x, y) {
  return !_M0IP26mizchi7syntree12HighlightTagPB2Eq5equal(x, y);
}
function _M0IP016_24default__implPB7Compare6op__leGkE(x, y) {
  return $compare_int(x, y) <= 0;
}
function _M0IP016_24default__implPB7Compare6op__geGkE(x, y) {
  return $compare_int(x, y) >= 0;
}
function _M0MPB6Hasher9avalanche(self) {
  let acc = self.acc;
  acc = acc ^ (acc >>> 15 | 0);
  acc = Math.imul(acc, -2048144777) | 0;
  acc = acc ^ (acc >>> 13 | 0);
  acc = Math.imul(acc, -1028477379) | 0;
  acc = acc ^ (acc >>> 16 | 0);
  return acc;
}
function _M0MPB6Hasher8finalize(self) {
  return _M0MPB6Hasher9avalanche(self);
}
function _M0MPB6Hasher11new_2einner(seed) {
  return new _M0TPB6Hasher((seed >>> 0) + (374761393 >>> 0) | 0);
}
function _M0MPB6Hasher3new(seed$46$opt) {
  let seed;
  if (seed$46$opt === undefined) {
    seed = _M0FPB4seed;
  } else {
    const _Some = seed$46$opt;
    seed = _Some;
  }
  return _M0MPB6Hasher11new_2einner(seed);
}
function _M0IP016_24default__implPB4Hash4hashGsE(self) {
  const h = _M0MPB6Hasher3new(undefined);
  _M0MPB6Hasher7combineGsE(h, self);
  return _M0MPB6Hasher8finalize(h);
}
function _M0MPC16string6String11sub_2einner(self, start, end) {
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
    if (start$2 < len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.charCodeAt(start$2))) {
      } else {
        $panic();
      }
    }
    if (end$2 < len) {
      if (!_M0MPC16uint166UInt1623is__trailing__surrogate(self.charCodeAt(end$2))) {
      } else {
        $panic();
      }
    }
    return new _M0TPC16string10StringView(self, start$2, end$2);
  } else {
    return $panic();
  }
}
function _M0IP016_24default__implPB6Logger16write__substringGRPB13StringBuilderE(self, value, start, len) {
  _M0IPB13StringBuilderPB6Logger11write__view(self, _M0MPC16string6String11sub_2einner(value, start, start + len | 0));
}
function _M0IP016_24default__implPB4Show10to__stringGRPB9SourceLocE(self) {
  const logger = _M0MPB13StringBuilder11new_2einner(0);
  _M0IPB9SourceLocPB4Show6output(self, { self: logger, method_table: _M0FP092moonbitlang_2fcore_2fbuiltin_2fStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return logger.val;
}
function _M0MPB4Iter4nextGRP26mizchi7syntree4TreeE(self) {
  const _func = self;
  return _func();
}
function _M0MPB4Iter4nextGcE(self) {
  const _func = self;
  return _func();
}
function _M0IPC16string10StringViewPB4Show10to__string(self) {
  return self.str.substring(self.start, self.end);
}
function _M0MPC16string6String12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= self.length) ? new _M0TPC16string10StringView(self, start_offset, end_offset$2) : _M0FPB5abortGRPB9ArrayViewGcEE("Invalid index for View", "@moonbitlang/core/builtin:stringview.mbt:399:5-399:36");
}
function _M0MPC16string6String4view(self, start_offset$46$opt, end_offset) {
  let start_offset;
  if (start_offset$46$opt === undefined) {
    start_offset = 0;
  } else {
    const _Some = start_offset$46$opt;
    start_offset = _Some;
  }
  return _M0MPC16string6String12view_2einner(self, start_offset, end_offset);
}
function _M0MPC16string6String11from__array(chars) {
  const buf = _M0MPB13StringBuilder11new_2einner(Math.imul(chars.end - chars.start | 0, 4) | 0);
  const _bind = chars.end - chars.start | 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const c = chars.buf[chars.start + _ | 0];
      _M0IPB13StringBuilderPB6Logger11write__char(buf, c);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return buf.val;
}
function _M0IPB13StringBuilderPB6Logger11write__view(self, str) {
  self.val = `${self.val}${_M0IPC16string10StringViewPB4Show10to__string(str)}`;
}
function _M0MPC15array5Array11new_2einnerGcE(capacity) {
  return [];
}
function _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC15array5Array4pushGcE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC15array5Array4pushGRP36mizchi7syntree10typescript9TsContextE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC15array5Array4pushGRP36mizchi7syntree7moonbit10MbtContextE(self, value) {
  _M0MPB7JSArray4push(self, value);
}
function _M0MPC16string6String4iter(self) {
  const len = self.length;
  const index = new _M0TPC13ref3RefGiE(0);
  const _p = () => {
    if (index.val < len) {
      const c1 = self.charCodeAt(index.val);
      if (_M0MPC16uint166UInt1622is__leading__surrogate(c1) && (index.val + 1 | 0) < len) {
        const c2 = self.charCodeAt(index.val + 1 | 0);
        if (_M0MPC16uint166UInt1623is__trailing__surrogate(c2)) {
          const c = _M0FPB32code__point__of__surrogate__pair(c1, c2);
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
function _M0MPC16string6String9to__array(self) {
  const _p = _M0MPC16string6String4iter(self);
  const _p$2 = _M0MPC15array5Array11new_2einnerGcE(self.length);
  let _p$3 = _p$2;
  while (true) {
    const _p$4 = _M0MPB4Iter4nextGcE(_p);
    if (_p$4 === -1) {
      break;
    } else {
      const _p$5 = _p$4;
      const _p$6 = _p$5;
      const _p$7 = _p$3;
      _M0MPC15array5Array4pushGcE(_p$7, _p$6);
      _p$3 = _p$7;
      continue;
    }
  }
  return _p$3;
}
function _M0MPC15array9ArrayView4iterGRP26mizchi7syntree4TreeE(self) {
  const i = new _M0TPC13ref3RefGiE(0);
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
function _M0MPC15array5Array4iterGRP26mizchi7syntree4TreeE(self) {
  return _M0MPC15array9ArrayView4iterGRP26mizchi7syntree4TreeE(new _M0TPB9ArrayViewGRP26mizchi7syntree4TreeE(self, 0, self.length));
}
function _M0IPC16option6OptionPB2Eq5equalGcE(self, other) {
  if (self === -1) {
    return other === -1;
  } else {
    const _Some = self;
    const _x = _Some;
    if (other === -1) {
      return false;
    } else {
      const _Some$2 = other;
      const _y = _Some$2;
      return _x === _y;
    }
  }
}
function _M0MPC16option6Option3mapGcbE(self, f) {
  if (self === -1) {
    return -1;
  } else {
    const _Some = self;
    const _t = _Some;
    return f(_t);
  }
}
function _M0MPC13int3Int20next__power__of__two(self) {
  if (self >= 0) {
    if (self <= 1) {
      return 1;
    }
    if (self > 1073741824) {
      return 1073741824;
    }
    return (2147483647 >> (Math.clz32(self - 1 | 0) - 1 | 0)) + 1 | 0;
  } else {
    return $panic();
  }
}
function _M0MPB3Map11new_2einnerGsRP26mizchi7syntree12HighlightTagE(capacity) {
  const capacity$2 = _M0MPC13int3Int20next__power__of__two(capacity);
  const _bind = capacity$2 - 1 | 0;
  const _bind$2 = (Math.imul(capacity$2, 13) | 0) / 16 | 0;
  const _bind$3 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$4 = undefined;
  return new _M0TPB3MapGsRP26mizchi7syntree12HighlightTagE(_bind$3, 0, capacity$2, _bind, _bind$2, _bind$4, -1);
}
function _M0MPB3Map20add__entry__to__tailGsRP26mizchi7syntree12HighlightTagE(self, idx, entry) {
  const _bind = self.tail;
  if (_bind === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind);
    const _p = _tmp[_bind];
    let _tmp$2;
    if (_p === undefined) {
      _tmp$2 = $panic();
    } else {
      const _p$2 = _p;
      _tmp$2 = _p$2;
    }
    _tmp$2.next = entry;
  }
  self.tail = idx;
  const _tmp = self.entries;
  $bound_check(_tmp, idx);
  _tmp[idx] = entry;
  self.size = self.size + 1 | 0;
}
function _M0MPB3Map10set__entryGsRP26mizchi7syntree12HighlightTagE(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind = entry.next;
  if (_bind === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function _M0MPB3Map10push__awayGsRP26mizchi7syntree12HighlightTagE(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = idx + 1 & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind = _tmp$4[idx$2];
    if (_bind === undefined) {
      entry$2.psl = psl;
      _M0MPB3Map10set__entryGsRP26mizchi7syntree12HighlightTagE(self, entry$2, idx$2);
      return;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        _M0MPB3Map10set__entryGsRP26mizchi7syntree12HighlightTagE(self, entry$2, idx$2);
        _tmp = _curr_entry.psl + 1 | 0;
        _tmp$2 = idx$2 + 1 & self.capacity_mask;
        _tmp$3 = _curr_entry;
        continue;
      } else {
        _tmp = psl + 1 | 0;
        _tmp$2 = idx$2 + 1 & self.capacity_mask;
        continue;
      }
    }
  }
}
function _M0MPB3Map15set__with__hashGsRP26mizchi7syntree12HighlightTagE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      if (self.size >= self.grow_at) {
        _M0MPB3Map4growGsRP26mizchi7syntree12HighlightTagE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$2 = self.tail;
      const _bind$3 = undefined;
      const entry = new _M0TPB5EntryGsRP26mizchi7syntree12HighlightTagE(_bind$2, _bind$3, psl, hash, key, value);
      _M0MPB3Map20add__entry__to__tailGsRP26mizchi7syntree12HighlightTagE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MPB3Map4growGsRP26mizchi7syntree12HighlightTagE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MPB3Map10push__awayGsRP26mizchi7syntree12HighlightTagE(self, idx, _curr_entry);
        const _bind$2 = self.tail;
        const _bind$3 = undefined;
        const entry = new _M0TPB5EntryGsRP26mizchi7syntree12HighlightTagE(_bind$2, _bind$3, psl, hash, key, value);
        _M0MPB3Map20add__entry__to__tailGsRP26mizchi7syntree12HighlightTagE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB3Map4growGsRP26mizchi7syntree12HighlightTagE(self) {
  const old_head = self.head;
  const new_capacity = self.capacity << 1;
  self.entries = $make_array_len_and_init(new_capacity, undefined);
  self.capacity = new_capacity;
  self.capacity_mask = new_capacity - 1 | 0;
  const _p = self.capacity;
  self.grow_at = (Math.imul(_p, 13) | 0) / 16 | 0;
  self.size = 0;
  self.head = undefined;
  self.tail = -1;
  let _tmp = old_head;
  while (true) {
    const _param = _tmp;
    if (_param === undefined) {
      return;
    } else {
      const _Some = _param;
      const _x = _Some;
      const _next = _x.next;
      const _key = _x.key;
      const _value = _x.value;
      const _hash = _x.hash;
      _M0MPB3Map15set__with__hashGsRP26mizchi7syntree12HighlightTagE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MPB3Map3setGsRP26mizchi7syntree12HighlightTagE(self, key, value) {
  _M0MPB3Map15set__with__hashGsRP26mizchi7syntree12HighlightTagE(self, key, value, _M0IP016_24default__implPB4Hash4hashGsE(key));
}
function _M0MPB3Map11from__arrayGsRP26mizchi7syntree12HighlightTagE(arr) {
  const length = arr.end - arr.start | 0;
  let capacity = _M0MPC13int3Int20next__power__of__two(length);
  const _p = capacity;
  if (length > ((Math.imul(_p, 13) | 0) / 16 | 0)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MPB3Map11new_2einnerGsRP26mizchi7syntree12HighlightTagE(capacity);
  const _bind = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const e = arr.buf[arr.start + _ | 0];
      _M0MPB3Map3setGsRP26mizchi7syntree12HighlightTagE(m, e._0, e._1);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MPB3Map3getGsRP26mizchi7syntree12HighlightTagE(self, key) {
  const hash = _M0IP016_24default__implPB4Hash4hashGsE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind = _tmp$3[idx];
    if (_bind === undefined) {
      return undefined;
    } else {
      const _Some = _bind;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        return _entry.value;
      }
      if (i > _entry.psl) {
        return undefined;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MPB6Hasher15combine__string(self, value) {
  const _bind = value.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _bind) {
      _M0MPB6Hasher13combine__uint(self, value.charCodeAt(i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0IPC16string6StringPB4Hash13hash__combine(self, hasher) {
  _M0MPB6Hasher15combine__string(hasher, self);
}
function _M0IPB13SourceLocReprPB4Show6output(self, logger) {
  const pkg = self.pkg;
  const _data = pkg.str;
  const _start = pkg.start;
  const _end = _start + (pkg.end - pkg.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let tag_0 = -1;
  let _bind;
  _L: {
    _L$2: {
      _L$3: while (true) {
        if (_cursor < _end) {
          const _p = _cursor;
          const next_char = _data.charCodeAt(_p);
          _cursor = _cursor + 1 | 0;
          if (next_char === 47) {
            _L$4: while (true) {
              tag_0 = _cursor;
              if (_cursor < _end) {
                const _p$2 = _cursor;
                const next_char$2 = _data.charCodeAt(_p$2);
                _cursor = _cursor + 1 | 0;
                if (next_char$2 === 47) {
                  while (true) {
                    if (_cursor < _end) {
                      _cursor = _cursor + 1 | 0;
                      continue;
                    } else {
                      match_tag_saver_0 = tag_0;
                      accept_state = 0;
                      match_end = _cursor;
                      break _L$2;
                    }
                  }
                } else {
                  continue;
                }
              } else {
                break _L$2;
              }
            }
          } else {
            continue;
          }
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    if (accept_state === 0) {
      const package_name = _M0MPC16string6String4view(_data, match_tag_saver_0 + 1 | 0, match_end);
      const module_name = _M0MPC16string6String4view(_data, _start, match_tag_saver_0);
      _bind = { _0: module_name, _1: package_name };
    } else {
      _bind = { _0: pkg, _1: undefined };
    }
  }
  const _module_name = _bind._0;
  const _package_name = _bind._1;
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
function _M0IPB9SourceLocPB4Show6output(self, logger) {
  _M0IPB13SourceLocReprPB4Show6output(_M0MPB13SourceLocRepr5parse(self), logger);
}
function _M0MPC15array5Array12view_2einnerGcE(self, start, end) {
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
    const _bind = self;
    const _bind$2 = end$2 - start$2 | 0;
    return new _M0TPB9ArrayViewGcE(_bind, start$2, start$2 + _bind$2 | 0);
  } else {
    return _M0FPB5abortGRPB9ArrayViewGcEE("View index out of bounds", "@moonbitlang/core/builtin:arrayview.mbt:263:5-263:38");
  }
}
function _M0MPC15array5Array11unsafe__popGRP36mizchi7syntree10typescript9TsContextE(self) {
  return _M0MPB7JSArray3pop(self);
}
function _M0MPC15array5Array11unsafe__popGRP36mizchi7syntree7moonbit10MbtContextE(self) {
  return _M0MPB7JSArray3pop(self);
}
function _M0MPC15array5Array3popGRP36mizchi7syntree10typescript9TsContextE(self) {
  if (self.length === 0) {
    return undefined;
  } else {
    const v = _M0MPC15array5Array11unsafe__popGRP36mizchi7syntree10typescript9TsContextE(self);
    return v;
  }
}
function _M0MPC15array5Array3popGRP36mizchi7syntree7moonbit10MbtContextE(self) {
  if (self.length === 0) {
    return undefined;
  } else {
    const v = _M0MPC15array5Array11unsafe__popGRP36mizchi7syntree7moonbit10MbtContextE(self);
    return v;
  }
}
function _M0IP26mizchi7syntree12HighlightTagPB2Eq5equal(_x_150, _x_151) {
  switch (_x_150) {
    case 0: {
      if (_x_151 === 0) {
        return true;
      } else {
        return false;
      }
    }
    case 1: {
      if (_x_151 === 1) {
        return true;
      } else {
        return false;
      }
    }
    case 2: {
      if (_x_151 === 2) {
        return true;
      } else {
        return false;
      }
    }
    case 3: {
      if (_x_151 === 3) {
        return true;
      } else {
        return false;
      }
    }
    case 4: {
      if (_x_151 === 4) {
        return true;
      } else {
        return false;
      }
    }
    case 5: {
      if (_x_151 === 5) {
        return true;
      } else {
        return false;
      }
    }
    case 6: {
      if (_x_151 === 6) {
        return true;
      } else {
        return false;
      }
    }
    case 7: {
      if (_x_151 === 7) {
        return true;
      } else {
        return false;
      }
    }
    case 8: {
      if (_x_151 === 8) {
        return true;
      } else {
        return false;
      }
    }
    case 9: {
      if (_x_151 === 9) {
        return true;
      } else {
        return false;
      }
    }
    case 10: {
      if (_x_151 === 10) {
        return true;
      } else {
        return false;
      }
    }
    case 11: {
      if (_x_151 === 11) {
        return true;
      } else {
        return false;
      }
    }
    case 12: {
      if (_x_151 === 12) {
        return true;
      } else {
        return false;
      }
    }
    case 13: {
      if (_x_151 === 13) {
        return true;
      } else {
        return false;
      }
    }
    case 14: {
      if (_x_151 === 14) {
        return true;
      } else {
        return false;
      }
    }
    case 15: {
      if (_x_151 === 15) {
        return true;
      } else {
        return false;
      }
    }
    case 16: {
      if (_x_151 === 16) {
        return true;
      } else {
        return false;
      }
    }
    case 17: {
      if (_x_151 === 17) {
        return true;
      } else {
        return false;
      }
    }
    case 18: {
      if (_x_151 === 18) {
        return true;
      } else {
        return false;
      }
    }
    case 19: {
      if (_x_151 === 19) {
        return true;
      } else {
        return false;
      }
    }
    case 20: {
      if (_x_151 === 20) {
        return true;
      } else {
        return false;
      }
    }
    case 21: {
      if (_x_151 === 21) {
        return true;
      } else {
        return false;
      }
    }
    case 22: {
      if (_x_151 === 22) {
        return true;
      } else {
        return false;
      }
    }
    default: {
      if (_x_151 === 23) {
        return true;
      } else {
        return false;
      }
    }
  }
}
function _M0MP26mizchi7syntree8NodeType3new(id, name) {
  return new _M0TP26mizchi7syntree8NodeType(id, name, false);
}
function _M0MP26mizchi7syntree4Tree4from(self) {
  switch (self.$tag) {
    case 0: {
      const _Node = self;
      return _Node._1;
    }
    case 1: {
      const _Leaf = self;
      return _Leaf._1;
    }
    default: {
      const _Buffered = self;
      return _Buffered._1;
    }
  }
}
function _M0MP26mizchi7syntree4Tree2to(self) {
  switch (self.$tag) {
    case 0: {
      const _Node = self;
      return _Node._2;
    }
    case 1: {
      const _Leaf = self;
      return _Leaf._2;
    }
    default: {
      const _Buffered = self;
      return _Buffered._2;
    }
  }
}
function _M0MP26mizchi7syntree4Tree10node__type(self) {
  switch (self.$tag) {
    case 0: {
      const _Node = self;
      const _node_type = _Node._0;
      return _node_type;
    }
    case 1: {
      const _Leaf = self;
      const _node_type$2 = _Leaf._0;
      return _node_type$2;
    }
    default: {
      return undefined;
    }
  }
}
function _M0MP26mizchi7syntree4Tree8children(self) {
  switch (self.$tag) {
    case 0: {
      const _Node = self;
      return _Node._3;
    }
    case 1: {
      return [];
    }
    default: {
      return [];
    }
  }
}
function _M0MP26mizchi7syntree4Tree14collect__nodes(self, nodes) {
  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(nodes, self);
  const _bind = _M0MP26mizchi7syntree4Tree8children(self);
  const _bind$2 = _bind.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind$2) {
      const child = _bind[_];
      _M0MP26mizchi7syntree4Tree14collect__nodes(child, nodes);
      _tmp = _ + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0MP26mizchi7syntree4Tree4iter(self) {
  const nodes = [];
  _M0MP26mizchi7syntree4Tree14collect__nodes(self, nodes);
  return _M0MPC15array5Array4iterGRP26mizchi7syntree4TreeE(nodes);
}
function _M0MP26mizchi7syntree14HighlightToken3new(from, to, tag) {
  return new _M0TP26mizchi7syntree14HighlightToken(from, to, tag);
}
function _M0MP26mizchi7syntree11Highlighter3new() {
  const _bind = [];
  return new _M0TP26mizchi7syntree11Highlighter(_M0MPB3Map11from__arrayGsRP26mizchi7syntree12HighlightTagE(new _M0TPB9ArrayViewGUsRP26mizchi7syntree12HighlightTagEE(_bind, 0, 0)));
}
function _M0MP26mizchi7syntree11Highlighter9add__rule(self, node_name, tag) {
  _M0MPB3Map3setGsRP26mizchi7syntree12HighlightTagE(self.rules, node_name, tag);
}
function _M0MP26mizchi7syntree11Highlighter8get__tag(self, node_name) {
  const _bind = _M0MPB3Map3getGsRP26mizchi7syntree12HighlightTagE(self.rules, node_name);
  if (_bind === undefined) {
    return 23;
  } else {
    const _Some = _bind;
    return _Some;
  }
}
function _M0MP26mizchi7syntree11Highlighter9highlight(self, tree) {
  const tokens = [];
  const _it = _M0MP26mizchi7syntree4Tree4iter(tree);
  while (true) {
    const _bind = _M0MPB4Iter4nextGRP26mizchi7syntree4TreeE(_it);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _node = _Some;
      const _bind$2 = _M0MP26mizchi7syntree4Tree10node__type(_node);
      if (_bind$2 === undefined) {
      } else {
        const _Some$2 = _bind$2;
        const _nt = _Some$2;
        const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(self, _nt.name);
        if (tag === 23) {
        } else {
          if (_node.$tag === 1) {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP26mizchi7syntree14HighlightToken3new(_M0MP26mizchi7syntree4Tree4from(_node), _M0MP26mizchi7syntree4Tree2to(_node), tag));
          }
        }
      }
      continue;
    }
  }
  return tokens;
}
function _M0FP26mizchi7syntree23escape__html__slice__to(chars, from, to, buf) {
  let _tmp = from;
  while (true) {
    const i = _tmp;
    if (i < to) {
      const _bind = _M0MPC15array5Array2atGcE(chars, i);
      switch (_bind) {
        case 60: {
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "&lt;");
          break;
        }
        case 62: {
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "&gt;");
          break;
        }
        case 38: {
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "&amp;");
          break;
        }
        case 34: {
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "&quot;");
          break;
        }
        default: {
          _M0IPB13StringBuilderPB6Logger11write__char(buf, _bind);
        }
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP36mizchi7syntree4bash17bash__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Keyword", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Command", 10);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Argument", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Option", 8);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Variable", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "SpecialVar", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "DoubleString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "SingleString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "RawString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "HereDoc", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Pipe", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PipeAnd", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "And", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Or", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Redirect", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Background", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Semicolon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "DoubleSemicolon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "CommandSub", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ProcessSub", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ArithmeticExp", 4);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenOpen", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenClose", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceOpen", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceClose", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketOpen", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketClose", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "DoubleBracket", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Shebang", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Glob", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Equals", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Number", 4);
  return h;
}
function _M0FP36mizchi7syntree4bash17token__type__name(t) {
  switch (t) {
    case 0: {
      return "Keyword";
    }
    case 1: {
      return "Command";
    }
    case 2: {
      return "Argument";
    }
    case 3: {
      return "Option";
    }
    case 4: {
      return "Variable";
    }
    case 5: {
      return "SpecialVar";
    }
    case 6: {
      return "DoubleString";
    }
    case 7: {
      return "SingleString";
    }
    case 8: {
      return "RawString";
    }
    case 9: {
      return "HereDoc";
    }
    case 10: {
      return "Pipe";
    }
    case 11: {
      return "PipeAnd";
    }
    case 12: {
      return "And";
    }
    case 13: {
      return "Or";
    }
    case 14: {
      return "Redirect";
    }
    case 15: {
      return "Background";
    }
    case 16: {
      return "Semicolon";
    }
    case 17: {
      return "DoubleSemicolon";
    }
    case 18: {
      return "CommandSub";
    }
    case 19: {
      return "ProcessSub";
    }
    case 20: {
      return "ArithmeticExp";
    }
    case 21: {
      return "ParenOpen";
    }
    case 22: {
      return "ParenClose";
    }
    case 23: {
      return "BraceOpen";
    }
    case 24: {
      return "BraceClose";
    }
    case 25: {
      return "BracketOpen";
    }
    case 26: {
      return "BracketClose";
    }
    case 27: {
      return "DoubleBracket";
    }
    case 28: {
      return "Comment";
    }
    case 29: {
      return "Shebang";
    }
    case 30: {
      return "Glob";
    }
    case 31: {
      return "Equals";
    }
    case 32: {
      return "Number";
    }
    default: {
      return "Error";
    }
  }
}
function _M0MP36mizchi7syntree4bash13BashTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree4bash13BashTokenizer(input, chars, chars.length, 0, true, false);
}
function _M0FP36mizchi7syntree4bash14is__word__char(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || (c >= 48 && c <= 57 || (c === 95 || (c === 45 || (c === 46 || (c === 47 || (c === 58 || (c === 64 || c === 126))))))));
}
function _M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, offset) {
  const idx = self.pos + offset | 0;
  return idx >= 0 && idx < self.len ? _M0MPC15array5Array2atGcE(self.chars, idx) : -1;
}
function _M0MP36mizchi7syntree4bash13BashTokenizer13read__comment(self) {
  const start = self.pos;
  if (start === 0 && _M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28read__comment_2econstr_2f468)) {
    while (true) {
      if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return new _M0TP36mizchi7syntree4bash9BashToken(29, start, self.pos);
  }
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4bash9BashToken(28, start, self.pos);
}
function _M0MP36mizchi7syntree4bash13BashTokenizer20read__double__string(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 34) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4bash9BashToken(6, start, self.pos);
}
function _M0MP36mizchi7syntree4bash13BashTokenizer17read__raw__string(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 39) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4bash9BashToken(8, start, self.pos);
}
function _M0MP36mizchi7syntree4bash13BashTokenizer20read__single__string(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 39) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len) {
    self.pos = self.pos + 1 | 0;
  }
  return new _M0TP36mizchi7syntree4bash9BashToken(7, start, self.pos);
}
function _M0MP36mizchi7syntree4bash13BashTokenizer14read__variable(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  if (self.pos >= self.len) {
    return new _M0TP36mizchi7syntree4bash9BashToken(4, start, self.pos);
  }
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  _L: {
    _L$2: {
      _L$3: {
        _L$4: {
          switch (c) {
            case 63: {
              break _L$4;
            }
            case 33: {
              break _L$4;
            }
            case 36: {
              break _L$4;
            }
            case 64: {
              break _L$4;
            }
            case 42: {
              break _L$4;
            }
            case 35: {
              break _L$4;
            }
            case 45: {
              break _L$4;
            }
            case 95: {
              break _L$4;
            }
            case 48: {
              break _L$2;
            }
            case 49: {
              break _L$2;
            }
            case 50: {
              break _L$2;
            }
            case 51: {
              break _L$2;
            }
            case 52: {
              break _L$2;
            }
            case 53: {
              break _L$2;
            }
            case 54: {
              break _L$2;
            }
            case 55: {
              break _L$2;
            }
            case 56: {
              break _L$2;
            }
            case 57: {
              break _L$2;
            }
          }
          break _L$3;
        }
        self.pos = self.pos + 1 | 0;
        return new _M0TP36mizchi7syntree4bash9BashToken(5, start, self.pos);
      }
      break _L;
    }
    self.pos = self.pos + 1 | 0;
    return new _M0TP36mizchi7syntree4bash9BashToken(5, start, self.pos);
  }
  if (c === 123) {
    self.pos = self.pos + 1 | 0;
    while (true) {
      if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 125) {
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    if (self.pos < self.len) {
      self.pos = self.pos + 1 | 0;
    }
    return new _M0TP36mizchi7syntree4bash9BashToken(4, start, self.pos);
  }
  if (c === 40) {
    if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash29read__variable_2econstr_2f484)) {
      self.pos = self.pos + 2 | 0;
      let depth = 2;
      while (true) {
        if (self.pos < self.len && depth > 0) {
          if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 40) {
            depth = depth + 1 | 0;
          } else {
            if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 41) {
              depth = depth - 1 | 0;
            }
          }
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return new _M0TP36mizchi7syntree4bash9BashToken(20, start, self.pos);
    }
    self.pos = self.pos + 1 | 0;
    let depth = 1;
    while (true) {
      if (self.pos < self.len && depth > 0) {
        const ch = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (ch === 40) {
          depth = depth + 1 | 0;
        } else {
          if (ch === 41) {
            depth = depth - 1 | 0;
          }
        }
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return new _M0TP36mizchi7syntree4bash9BashToken(18, start, self.pos);
  }
  while (true) {
    if (self.pos < self.len) {
      const ch = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (ch >= 97 && ch <= 122 || (ch >= 65 && ch <= 90 || (ch >= 48 && ch <= 57 || ch === 95))) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4bash9BashToken(4, start, self.pos);
}
function _M0FP36mizchi7syntree4bash11is__keyword(word) {
  switch (word) {
    case "if": {
      return true;
    }
    case "then": {
      return true;
    }
    case "else": {
      return true;
    }
    case "elif": {
      return true;
    }
    case "fi": {
      return true;
    }
    case "for": {
      return true;
    }
    case "while": {
      return true;
    }
    case "until": {
      return true;
    }
    case "do": {
      return true;
    }
    case "done": {
      return true;
    }
    case "case": {
      return true;
    }
    case "esac": {
      return true;
    }
    case "in": {
      return true;
    }
    case "function": {
      return true;
    }
    case "return": {
      return true;
    }
    case "exit": {
      return true;
    }
    case "local": {
      return true;
    }
    case "export": {
      return true;
    }
    case "readonly": {
      return true;
    }
    case "declare": {
      return true;
    }
    case "typeset": {
      return true;
    }
    case "source": {
      return true;
    }
    case "eval": {
      return true;
    }
    case "exec": {
      return true;
    }
    case "break": {
      return true;
    }
    case "continue": {
      return true;
    }
    case "select": {
      return true;
    }
    case "time": {
      return true;
    }
    case "coproc": {
      return true;
    }
    case "true": {
      return true;
    }
    case "false": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0MP36mizchi7syntree4bash13BashTokenizer10read__word(self) {
  const start = self.pos;
  if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 45) {
    self.pos = self.pos + 1 | 0;
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 45) {
      self.pos = self.pos + 1 | 0;
    }
    while (true) {
      if (self.pos < self.len && _M0FP36mizchi7syntree4bash14is__word__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return new _M0TP36mizchi7syntree4bash9BashToken(3, start, self.pos);
  }
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree4bash14is__word__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const word = _M0MPC16string6String11from__array(_M0MPC15array5Array12view_2einnerGcE(self.chars, start, self.pos));
  if (_M0FP36mizchi7syntree4bash11is__keyword(word)) {
    return new _M0TP36mizchi7syntree4bash9BashToken(0, start, self.pos);
  }
  if (self.at_line_start && !self.after_command) {
    self.after_command = true;
    return new _M0TP36mizchi7syntree4bash9BashToken(1, start, self.pos);
  }
  return new _M0TP36mizchi7syntree4bash9BashToken(2, start, self.pos);
}
function _M0MP36mizchi7syntree4bash13BashTokenizer16skip__whitespace(self) {
  while (true) {
    let _tmp;
    if (self.pos < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      _tmp = _p === 32 || _p === 9;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0MP36mizchi7syntree4bash13BashTokenizer13tokenize__all(self) {
  const tokens = [];
  while (true) {
    if (self.pos < self.len) {
      _M0MP36mizchi7syntree4bash13BashTokenizer16skip__whitespace(self);
      if (self.pos >= self.len) {
        break;
      }
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 10) {
        self.pos = self.pos + 1 | 0;
        self.at_line_start = true;
        self.after_command = false;
        continue;
      }
      if (c === 35) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4bash13BashTokenizer13read__comment(self));
        continue;
      }
      if (c === 34) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4bash13BashTokenizer20read__double__string(self));
        continue;
      }
      if (c === 39) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4bash13BashTokenizer20read__single__string(self));
        continue;
      }
      if (c === 36 && _M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f507)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4bash13BashTokenizer17read__raw__string(self));
        continue;
      }
      if (c === 36) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4bash13BashTokenizer14read__variable(self));
        continue;
      }
      if ((c === 60 || c === 62) && _M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f508)) {
        const start = self.pos;
        self.pos = self.pos + 2 | 0;
        let depth = 1;
        while (true) {
          if (self.pos < self.len && depth > 0) {
            if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 40) {
              depth = depth + 1 | 0;
            } else {
              if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 41) {
                depth = depth - 1 | 0;
              }
            }
            self.pos = self.pos + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(19, start, self.pos));
        continue;
      }
      _L: {
        _L$2: {
          switch (c) {
            case 124: {
              if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f509)) {
                const start = self.pos;
                self.pos = self.pos + 2 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(13, start, self.pos));
              } else {
                if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f510)) {
                  const start = self.pos;
                  self.pos = self.pos + 2 | 0;
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(11, start, self.pos));
                } else {
                  const start = self.pos;
                  self.pos = self.pos + 1 | 0;
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(10, start, self.pos));
                  self.at_line_start = true;
                  self.after_command = false;
                }
              }
              break;
            }
            case 38: {
              if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f511)) {
                const start = self.pos;
                self.pos = self.pos + 2 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(12, start, self.pos));
                self.at_line_start = true;
                self.after_command = false;
              } else {
                if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f512)) {
                  const start = self.pos;
                  self.pos = self.pos + 2 | 0;
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(14, start, self.pos));
                } else {
                  const start = self.pos;
                  self.pos = self.pos + 1 | 0;
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(15, start, self.pos));
                }
              }
              break;
            }
            case 59: {
              if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f513)) {
                const start = self.pos;
                self.pos = self.pos + 2 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(17, start, self.pos));
              } else {
                const start = self.pos;
                self.pos = self.pos + 1 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(16, start, self.pos));
                self.at_line_start = true;
                self.after_command = false;
              }
              break;
            }
            case 62: {
              const start = self.pos;
              self.pos = self.pos + 1 | 0;
              if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 62) {
                self.pos = self.pos + 1 | 0;
              }
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(14, start, self.pos));
              break;
            }
            case 60: {
              const start$2 = self.pos;
              self.pos = self.pos + 1 | 0;
              if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 60) {
                self.pos = self.pos + 1 | 0;
                if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 60) {
                  self.pos = self.pos + 1 | 0;
                }
              }
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(14, start$2, self.pos));
              break;
            }
            case 40: {
              const start$3 = self.pos;
              self.pos = self.pos + 1 | 0;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(21, start$3, self.pos));
              break;
            }
            case 41: {
              const start$4 = self.pos;
              self.pos = self.pos + 1 | 0;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(22, start$4, self.pos));
              break;
            }
            case 123: {
              const start$5 = self.pos;
              self.pos = self.pos + 1 | 0;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(23, start$5, self.pos));
              break;
            }
            case 125: {
              const start$6 = self.pos;
              self.pos = self.pos + 1 | 0;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(24, start$6, self.pos));
              break;
            }
            case 91: {
              if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f514)) {
                const start$7 = self.pos;
                self.pos = self.pos + 2 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(27, start$7, self.pos));
              } else {
                const start$7 = self.pos;
                self.pos = self.pos + 1 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(25, start$7, self.pos));
              }
              break;
            }
            case 93: {
              if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4bash13BashTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4bash28tokenize__all_2econstr_2f515)) {
                const start$7 = self.pos;
                self.pos = self.pos + 2 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(27, start$7, self.pos));
              } else {
                const start$7 = self.pos;
                self.pos = self.pos + 1 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(26, start$7, self.pos));
              }
              break;
            }
            case 61: {
              const start$7 = self.pos;
              self.pos = self.pos + 1 | 0;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(31, start$7, self.pos));
              break;
            }
            case 42: {
              break _L$2;
            }
            case 63: {
              break _L$2;
            }
            default: {
              if (c >= 48 && c <= 57) {
                const start$8 = self.pos;
                while (true) {
                  let _tmp;
                  if (self.pos < self.len) {
                    const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
                    _tmp = _p >= 48 && _p <= 57;
                  } else {
                    _tmp = false;
                  }
                  if (_tmp) {
                    self.pos = self.pos + 1 | 0;
                    continue;
                  } else {
                    break;
                  }
                }
                if (self.pos < self.len && (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 62 || _M0MPC15array5Array2atGcE(self.chars, self.pos) === 60)) {
                  if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 62) {
                    self.pos = self.pos + 1 | 0;
                    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 62) {
                      self.pos = self.pos + 1 | 0;
                    }
                  } else {
                    self.pos = self.pos + 1 | 0;
                  }
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(14, start$8, self.pos));
                } else {
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(32, start$8, self.pos));
                }
              } else {
                if (_M0FP36mizchi7syntree4bash14is__word__char(c) || c === 45) {
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4bash13BashTokenizer10read__word(self));
                  self.at_line_start = false;
                } else {
                  const start$8 = self.pos;
                  self.pos = self.pos + 1 | 0;
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(33, start$8, self.pos));
                }
              }
            }
          }
          break _L;
        }
        const start = self.pos;
        self.pos = self.pos + 1 | 0;
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4bash9BashToken(30, start, self.pos));
      }
      continue;
    } else {
      break;
    }
  }
  return tokens;
}
function _M0FP36mizchi7syntree4bash15highlight__bash(source) {
  const tokenizer = _M0MP36mizchi7syntree4bash13BashTokenizer3new(source);
  const tokens = _M0MP36mizchi7syntree4bash13BashTokenizer13tokenize__all(tokenizer);
  const highlighter = _M0FP36mizchi7syntree4bash17bash__highlighter();
  const result = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const name = _M0FP36mizchi7syntree4bash17token__type__name(token.token_type);
      const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(highlighter, name);
      if (_M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(tag, 23)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(result, _M0MP26mizchi7syntree14HighlightToken3new(token.from, token.to, tag));
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0FP36mizchi7syntree3css16css__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TagSelector", 20);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ClassSelector", 12);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "IdSelector", 12);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PseudoClass", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PseudoElement", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "AttrSelector", 8);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "UniversalSelector", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Combinator", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "AtKeyword", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PropertyName", 8);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PropertyValue", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Number", 4);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Unit", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Color", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "String", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Url", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Function", 10);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Important", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceOpen", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceClose", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenOpen", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenClose", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketOpen", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketClose", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Colon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Semicolon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comma", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comment", 18);
  return h;
}
function _M0FP36mizchi7syntree3css17token__type__name(t) {
  switch (t) {
    case 0: {
      return "TagSelector";
    }
    case 1: {
      return "ClassSelector";
    }
    case 2: {
      return "IdSelector";
    }
    case 3: {
      return "PseudoClass";
    }
    case 4: {
      return "PseudoElement";
    }
    case 5: {
      return "AttrSelector";
    }
    case 6: {
      return "UniversalSelector";
    }
    case 7: {
      return "Combinator";
    }
    case 8: {
      return "AtKeyword";
    }
    case 9: {
      return "PropertyName";
    }
    case 10: {
      return "PropertyValue";
    }
    case 11: {
      return "Number";
    }
    case 12: {
      return "Unit";
    }
    case 13: {
      return "Color";
    }
    case 14: {
      return "String";
    }
    case 15: {
      return "Url";
    }
    case 16: {
      return "Function";
    }
    case 17: {
      return "Important";
    }
    case 18: {
      return "BraceOpen";
    }
    case 19: {
      return "BraceClose";
    }
    case 20: {
      return "ParenOpen";
    }
    case 21: {
      return "ParenClose";
    }
    case 22: {
      return "BracketOpen";
    }
    case 23: {
      return "BracketClose";
    }
    case 24: {
      return "Colon";
    }
    case 25: {
      return "Semicolon";
    }
    case 26: {
      return "Comma";
    }
    case 27: {
      return "Comment";
    }
    default: {
      return "Error";
    }
  }
}
function _M0MP36mizchi7syntree3css12CssTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree3css12CssTokenizer(input, chars, chars.length, 0, false, false);
}
function _M0FP36mizchi7syntree3css9is__digit(c) {
  return c >= 48 && c <= 57;
}
function _M0FP36mizchi7syntree3css14is__hex__digit(c) {
  return c >= 48 && c <= 57 || (c >= 97 && c <= 102 || c >= 65 && c <= 70);
}
function _M0FP36mizchi7syntree3css16is__ident__start(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || (c === 95 || c === 45));
}
function _M0MP36mizchi7syntree3css12CssTokenizer7is__url(self) {
  if ((self.pos + 4 | 0) > self.len) {
    return false;
  }
  return _M0MPC15array5Array2atGcE(self.chars, self.pos) === 117 && (_M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 114 && (_M0MPC15array5Array2atGcE(self.chars, self.pos + 2 | 0) === 108 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 3 | 0) === 40));
}
function _M0MP36mizchi7syntree3css12CssTokenizer8peek__at(self, offset) {
  const idx = self.pos + offset | 0;
  return idx >= 0 && idx < self.len ? _M0MPC15array5Array2atGcE(self.chars, idx) : -1;
}
function _M0MP36mizchi7syntree3css12CssTokenizer11read__color(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree3css14is__hex__digit(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree3css8CssToken(13, start, self.pos);
}
function _M0MP36mizchi7syntree3css12CssTokenizer13read__comment(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  while (true) {
    if ((self.pos + 1 | 0) < self.len) {
      if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 42 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 47) {
        self.pos = self.pos + 2 | 0;
        break;
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree3css8CssToken(27, start, self.pos);
}
function _M0FP36mizchi7syntree3css15is__ident__char(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || (c >= 48 && c <= 57 || (c === 45 || c === 95)));
}
function _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree3css15is__ident__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return { _0: start, _1: self.pos };
}
function _M0MP36mizchi7syntree3css12CssTokenizer12read__number(self) {
  const start = self.pos;
  while (true) {
    let _tmp;
    if (self.pos < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      _tmp = _p >= 48 && _p <= 57;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 46) {
    let _tmp;
    if ((self.pos + 1 | 0) < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      _tmp = _p >= 48 && _p <= 57;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        let _tmp$2;
        if (self.pos < self.len) {
          const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          _tmp$2 = _p >= 48 && _p <= 57;
        } else {
          _tmp$2 = false;
        }
        if (_tmp$2) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  return new _M0TP36mizchi7syntree3css8CssToken(11, start, self.pos);
}
function _M0MP36mizchi7syntree3css12CssTokenizer12read__string(self) {
  const start = self.pos;
  const quote = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === quote) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree3css8CssToken(14, start, self.pos);
}
function _M0MP36mizchi7syntree3css12CssTokenizer10read__unit(self) {
  const start = self.pos;
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 37) {
    self.pos = self.pos + 1 | 0;
    return new _M0TP36mizchi7syntree3css8CssToken(12, start, self.pos);
  }
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree3css15is__ident__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree3css8CssToken(12, start, self.pos);
}
function _M0FP36mizchi7syntree3css14is__whitespace(c) {
  return c === 32 || (c === 9 || (c === 10 || c === 13));
}
function _M0MP36mizchi7syntree3css12CssTokenizer9read__url(self) {
  const start = self.pos;
  self.pos = self.pos + 4 | 0;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree3css14is__whitespace(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 34 || c === 39) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== c) {
          if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 92 && (self.pos + 1 | 0) < self.len) {
            self.pos = self.pos + 2 | 0;
          } else {
            self.pos = self.pos + 1 | 0;
          }
          continue;
        } else {
          break;
        }
      }
      if (self.pos < self.len) {
        self.pos = self.pos + 1 | 0;
      }
    } else {
      while (true) {
        if (self.pos < self.len) {
          const c$2 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (c$2 === 41 || _M0FP36mizchi7syntree3css14is__whitespace(c$2)) {
            break;
          }
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree3css14is__whitespace(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 41) {
    self.pos = self.pos + 1 | 0;
  }
  return new _M0TP36mizchi7syntree3css8CssToken(15, start, self.pos);
}
function _M0MP36mizchi7syntree3css12CssTokenizer16skip__whitespace(self) {
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree3css14is__whitespace(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0MP36mizchi7syntree3css12CssTokenizer13tokenize__all(self) {
  const tokens = [];
  _L: while (true) {
    if (self.pos < self.len) {
      _M0MP36mizchi7syntree3css12CssTokenizer16skip__whitespace(self);
      if (self.pos >= self.len) {
        break;
      }
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 47 && _M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree3css12CssTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree3css28tokenize__all_2econstr_2f602)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer13read__comment(self));
        continue;
      }
      switch (c) {
        case 123: {
          const start = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(18, start, self.pos));
          self.in_block = true;
          self.after_colon = false;
          continue _L;
        }
        case 125: {
          const start$2 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(19, start$2, self.pos));
          self.in_block = false;
          self.after_colon = false;
          continue _L;
        }
        case 40: {
          const start$3 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(20, start$3, self.pos));
          continue _L;
        }
        case 41: {
          const start$4 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(21, start$4, self.pos));
          continue _L;
        }
        case 91: {
          const start$5 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(22, start$5, self.pos));
          continue _L;
        }
        case 93: {
          const start$6 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(23, start$6, self.pos));
          continue _L;
        }
        case 58: {
          if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree3css12CssTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree3css28tokenize__all_2econstr_2f603)) {
            const start$7 = self.pos;
            self.pos = self.pos + 2 | 0;
            if (self.pos < self.len && _M0FP36mizchi7syntree3css16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
              const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
              const _end = _bind._1;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(4, start$7, _end));
            } else {
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(4, start$7, self.pos));
            }
          } else {
            if (self.in_block && !self.after_colon) {
              const start$7 = self.pos;
              self.pos = self.pos + 1 | 0;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(24, start$7, self.pos));
              self.after_colon = true;
            } else {
              const start$7 = self.pos;
              self.pos = self.pos + 1 | 0;
              if (self.pos < self.len && _M0FP36mizchi7syntree3css16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
                const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
                const _end = _bind._1;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(3, start$7, _end));
              } else {
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(24, start$7, self.pos));
              }
            }
          }
          continue _L;
        }
        case 59: {
          const start$7 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(25, start$7, self.pos));
          self.after_colon = false;
          continue _L;
        }
        case 44: {
          const start$8 = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(26, start$8, self.pos));
          continue _L;
        }
      }
      if (c === 62 || (c === 43 || c === 126)) {
        const start$9 = self.pos;
        self.pos = self.pos + 1 | 0;
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(7, start$9, self.pos));
        continue;
      }
      if (c === 64) {
        const start$9 = self.pos;
        self.pos = self.pos + 1 | 0;
        if (self.pos < self.len && _M0FP36mizchi7syntree3css16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
          const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
          const _end = _bind._1;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(8, start$9, _end));
        } else {
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(8, start$9, self.pos));
        }
        continue;
      }
      if (c === 46 && !self.after_colon) {
        const start$9 = self.pos;
        self.pos = self.pos + 1 | 0;
        if (self.pos < self.len && _M0FP36mizchi7syntree3css16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
          const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
          const _end = _bind._1;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(1, start$9, _end));
        }
        continue;
      }
      if (c === 35) {
        const start$9 = self.pos;
        self.pos = self.pos + 1 | 0;
        if (self.pos < self.len) {
          if (self.after_colon && _M0FP36mizchi7syntree3css14is__hex__digit(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
            self.pos = start$9;
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer11read__color(self));
          } else {
            if (_M0FP36mizchi7syntree3css16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
              const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
              const _end = _bind._1;
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(2, start$9, _end));
            } else {
              if (_M0FP36mizchi7syntree3css14is__hex__digit(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
                self.pos = start$9;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer11read__color(self));
              }
            }
          }
        }
        continue;
      }
      if (c === 42) {
        const start$9 = self.pos;
        self.pos = self.pos + 1 | 0;
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(6, start$9, self.pos));
        continue;
      }
      if (c === 34 || c === 39) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer12read__string(self));
        continue;
      }
      let _tmp;
      if (c >= 48 && c <= 57) {
        _tmp = true;
      } else {
        let _tmp$2;
        if (c === 46) {
          const _p = _M0MPC16option6Option3mapGcbE(_M0MP36mizchi7syntree3css12CssTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree3css9is__digit);
          const _p$2 = false;
          _tmp$2 = _p === -1 ? _p$2 : _p;
        } else {
          _tmp$2 = false;
        }
        _tmp = _tmp$2;
      }
      if (_tmp) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer12read__number(self));
        if (self.pos < self.len) {
          const next = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (next === 37 || _M0FP36mizchi7syntree3css16is__ident__start(next)) {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer10read__unit(self));
          }
        }
        continue;
      }
      if (c === 33) {
        const start$9 = self.pos;
        self.pos = self.pos + 1 | 0;
        _M0MP36mizchi7syntree3css12CssTokenizer16skip__whitespace(self);
        if ((self.pos + 9 | 0) <= self.len) {
          const word_start = self.pos;
          const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
          const _word_end = _bind._1;
          if ((_word_end - word_start | 0) === 9) {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(17, start$9, _word_end));
          } else {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(28, start$9, _word_end));
          }
        }
        continue;
      }
      if (_M0FP36mizchi7syntree3css16is__ident__start(c)) {
        if (_M0MP36mizchi7syntree3css12CssTokenizer7is__url(self)) {
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree3css12CssTokenizer9read__url(self));
          continue;
        }
        const _bind = _M0MP36mizchi7syntree3css12CssTokenizer11read__ident(self);
        const _start = _bind._0;
        const _end = _bind._1;
        if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 40) {
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(16, _start, _end));
          continue;
        }
        if (self.in_block) {
          if (self.after_colon) {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(10, _start, _end));
          } else {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(9, _start, _end));
          }
        } else {
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(0, _start, _end));
        }
        continue;
      }
      const start$9 = self.pos;
      self.pos = self.pos + 1 | 0;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree3css8CssToken(28, start$9, self.pos));
      continue;
    } else {
      break;
    }
  }
  return tokens;
}
function _M0FP36mizchi7syntree3css14highlight__css(source) {
  const tokenizer = _M0MP36mizchi7syntree3css12CssTokenizer3new(source);
  const tokens = _M0MP36mizchi7syntree3css12CssTokenizer13tokenize__all(tokenizer);
  const highlighter = _M0FP36mizchi7syntree3css16css__highlighter();
  const result = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const name = _M0FP36mizchi7syntree3css17token__type__name(token.token_type);
      const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(highlighter, name);
      if (_M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(tag, 23)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(result, _M0MP26mizchi7syntree14HighlightToken3new(token.from, token.to, tag));
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree4html13HtmlTokenizer(input, chars, chars.length, 0);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer8peek__at(self, offset) {
  const idx = self.pos + offset | 0;
  return idx >= 0 && idx < self.len ? _M0MPC15array5Array2atGcE(self.chars, idx) : -1;
}
function _M0FP36mizchi7syntree4html14is__name__char(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || (c >= 48 && c <= 57 || (c === 45 || (c === 95 || (c === 58 || c === 46)))));
}
function _M0FP36mizchi7syntree4html14is__whitespace(c) {
  return c === 32 || (c === 9 || (c === 10 || c === 13));
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer16skip__whitespace(self) {
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree4html14is__whitespace(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer7matches(self, s) {
  const s_chars = _M0MPC16string6String9to__array(s);
  const s_len = s_chars.length;
  if ((self.pos + s_len | 0) > self.len) {
    return false;
  }
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < s_len) {
      if (_M0MPC15array5Array2atGcE(self.chars, self.pos + i | 0) !== _M0MPC15array5Array2atGcE(s_chars, i)) {
        return false;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer21matches__ignore__case(self, s) {
  const s_chars = _M0MPC16string6String9to__array(s);
  const s_len = s_chars.length;
  if ((self.pos + s_len | 0) > self.len) {
    return false;
  }
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < s_len) {
      const c1 = _M0MPC15array5Array2atGcE(self.chars, self.pos + i | 0);
      const c2 = _M0MPC15array5Array2atGcE(s_chars, i);
      const c1_lower = c1 >= 65 && c1 <= 90 ? c1 + 32 | 0 : c1;
      const c2_lower = c2 >= 65 && c2 <= 90 ? c2 + 32 | 0 : c2;
      if (c1_lower !== c2_lower) {
        return false;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer13read__comment(self) {
  const start = self.pos;
  self.pos = self.pos + 4 | 0;
  while (true) {
    if (self.pos < self.len) {
      if (_M0MP36mizchi7syntree4html13HtmlTokenizer7matches(self, "-->")) {
        self.pos = self.pos + 3 | 0;
        break;
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(9, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer13read__doctype(self) {
  const start = self.pos;
  self.pos = self.pos + 9 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 62) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len) {
    self.pos = self.pos + 1 | 0;
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(10, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer11read__cdata(self) {
  const start = self.pos;
  self.pos = self.pos + 9 | 0;
  while (true) {
    if (self.pos < self.len) {
      if (_M0MP36mizchi7syntree4html13HtmlTokenizer7matches(self, "]]>")) {
        self.pos = self.pos + 3 | 0;
        break;
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(11, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer15read__tag__name(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree4html14is__name__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(4, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer16read__attr__name(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree4html14is__name__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(5, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer17read__attr__value(self) {
  const start = self.pos;
  if (self.pos < self.len) {
    const quote = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (quote === 34 || quote === 39) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== quote) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      if (self.pos < self.len) {
        self.pos = self.pos + 1 | 0;
      }
    } else {
      while (true) {
        if (self.pos < self.len) {
          const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (_M0FP36mizchi7syntree4html14is__whitespace(c) || (c === 62 || c === 47)) {
            break;
          }
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(7, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer10read__text(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 60) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4html9HtmlToken(8, start, self.pos);
}
function _M0MP36mizchi7syntree4html13HtmlTokenizer13tokenize__all(self) {
  const tokens = [];
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 60) {
        if (_M0MP36mizchi7syntree4html13HtmlTokenizer7matches(self, "<!--")) {
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer13read__comment(self));
        } else {
          if (_M0MP36mizchi7syntree4html13HtmlTokenizer21matches__ignore__case(self, "<!DOCTYPE")) {
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer13read__doctype(self));
          } else {
            if (_M0MP36mizchi7syntree4html13HtmlTokenizer7matches(self, "<![CDATA[")) {
              _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer11read__cdata(self));
            } else {
              if (_M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4html13HtmlTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4html28tokenize__all_2econstr_2f703)) {
                const start = self.pos;
                self.pos = self.pos + 2 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4html9HtmlToken(3, start, self.pos));
                _M0MP36mizchi7syntree4html13HtmlTokenizer16skip__whitespace(self);
                if (self.pos < self.len && _M0FP36mizchi7syntree4html14is__name__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer15read__tag__name(self));
                }
                _M0MP36mizchi7syntree4html13HtmlTokenizer16skip__whitespace(self);
                if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 62) {
                  const start$2 = self.pos;
                  self.pos = self.pos + 1 | 0;
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4html9HtmlToken(1, start$2, self.pos));
                }
              } else {
                const start = self.pos;
                self.pos = self.pos + 1 | 0;
                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4html9HtmlToken(0, start, self.pos));
                if (self.pos < self.len && _M0FP36mizchi7syntree4html14is__name__char(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
                  _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer15read__tag__name(self));
                }
                while (true) {
                  if (self.pos < self.len) {
                    _M0MP36mizchi7syntree4html13HtmlTokenizer16skip__whitespace(self);
                    if (self.pos >= self.len) {
                      break;
                    }
                    const c$2 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
                    if (c$2 === 62) {
                      const start$2 = self.pos;
                      self.pos = self.pos + 1 | 0;
                      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4html9HtmlToken(1, start$2, self.pos));
                      break;
                    } else {
                      if (c$2 === 47 && _M0IPC16option6OptionPB2Eq5equalGcE(_M0MP36mizchi7syntree4html13HtmlTokenizer8peek__at(self, 1), _M0FP36mizchi7syntree4html28tokenize__all_2econstr_2f704)) {
                        const start$2 = self.pos;
                        self.pos = self.pos + 2 | 0;
                        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4html9HtmlToken(2, start$2, self.pos));
                        break;
                      } else {
                        if (_M0FP36mizchi7syntree4html14is__name__char(c$2)) {
                          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer16read__attr__name(self));
                          _M0MP36mizchi7syntree4html13HtmlTokenizer16skip__whitespace(self);
                          if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 61) {
                            const start$2 = self.pos;
                            self.pos = self.pos + 1 | 0;
                            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, new _M0TP36mizchi7syntree4html9HtmlToken(6, start$2, self.pos));
                            _M0MP36mizchi7syntree4html13HtmlTokenizer16skip__whitespace(self);
                            if (self.pos < self.len) {
                              const c$3 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
                              if (c$3 !== 62 && c$3 !== 47) {
                                _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _M0MP36mizchi7syntree4html13HtmlTokenizer17read__attr__value(self));
                              }
                            }
                          }
                        } else {
                          self.pos = self.pos + 1 | 0;
                        }
                      }
                    }
                    continue;
                  } else {
                    break;
                  }
                }
              }
            }
          }
        }
      } else {
        const token = _M0MP36mizchi7syntree4html13HtmlTokenizer10read__text(self);
        if (token.to > token.from) {
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, token);
        }
      }
      continue;
    } else {
      break;
    }
  }
  return tokens;
}
function _M0FP36mizchi7syntree4html17html__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TagOpen", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TagClose", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TagSlashClose", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TagOpenEnd", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TagName", 20);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "AttrName", 8);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "AttrEquals", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "AttrValue", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Doctype", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "CData", 3);
  return h;
}
function _M0FP36mizchi7syntree4html17token__type__name(t) {
  switch (t) {
    case 0: {
      return "TagOpen";
    }
    case 1: {
      return "TagClose";
    }
    case 2: {
      return "TagSlashClose";
    }
    case 3: {
      return "TagOpenEnd";
    }
    case 4: {
      return "TagName";
    }
    case 5: {
      return "AttrName";
    }
    case 6: {
      return "AttrEquals";
    }
    case 7: {
      return "AttrValue";
    }
    case 8: {
      return "Text";
    }
    case 9: {
      return "Comment";
    }
    case 10: {
      return "Doctype";
    }
    case 11: {
      return "CData";
    }
    default: {
      return "Error";
    }
  }
}
function _M0FP36mizchi7syntree4html15highlight__html(source) {
  const tokenizer = _M0MP36mizchi7syntree4html13HtmlTokenizer3new(source);
  const tokens = _M0MP36mizchi7syntree4html13HtmlTokenizer13tokenize__all(tokenizer);
  const highlighter = _M0FP36mizchi7syntree4html17html__highlighter();
  const result = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const name = _M0FP36mizchi7syntree4html17token__type__name(token.token_type);
      const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(highlighter, name);
      if (_M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(tag, 23)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(result, _M0MP26mizchi7syntree14HighlightToken3new(token.from, token.to, tag));
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_x_207, _x_208) {
  switch (_x_207) {
    case 0: {
      if (_x_208 === 0) {
        return true;
      } else {
        return false;
      }
    }
    case 1: {
      if (_x_208 === 1) {
        return true;
      } else {
        return false;
      }
    }
    case 2: {
      if (_x_208 === 2) {
        return true;
      } else {
        return false;
      }
    }
    case 3: {
      if (_x_208 === 3) {
        return true;
      } else {
        return false;
      }
    }
    case 4: {
      if (_x_208 === 4) {
        return true;
      } else {
        return false;
      }
    }
    case 5: {
      if (_x_208 === 5) {
        return true;
      } else {
        return false;
      }
    }
    case 6: {
      if (_x_208 === 6) {
        return true;
      } else {
        return false;
      }
    }
    case 7: {
      if (_x_208 === 7) {
        return true;
      } else {
        return false;
      }
    }
    case 8: {
      if (_x_208 === 8) {
        return true;
      } else {
        return false;
      }
    }
    case 9: {
      if (_x_208 === 9) {
        return true;
      } else {
        return false;
      }
    }
    case 10: {
      if (_x_208 === 10) {
        return true;
      } else {
        return false;
      }
    }
    case 11: {
      if (_x_208 === 11) {
        return true;
      } else {
        return false;
      }
    }
    case 12: {
      if (_x_208 === 12) {
        return true;
      } else {
        return false;
      }
    }
    case 13: {
      if (_x_208 === 13) {
        return true;
      } else {
        return false;
      }
    }
    case 14: {
      if (_x_208 === 14) {
        return true;
      } else {
        return false;
      }
    }
    case 15: {
      if (_x_208 === 15) {
        return true;
      } else {
        return false;
      }
    }
    default: {
      if (_x_208 === 16) {
        return true;
      } else {
        return false;
      }
    }
  }
}
function _M0MP36mizchi7syntree4json10JsonNodeId7to__int(self) {
  switch (self) {
    case 0: {
      return 0;
    }
    case 1: {
      return 1;
    }
    case 2: {
      return 2;
    }
    case 3: {
      return 3;
    }
    case 4: {
      return 4;
    }
    case 5: {
      return 5;
    }
    case 6: {
      return 6;
    }
    case 7: {
      return 7;
    }
    case 8: {
      return 8;
    }
    case 9: {
      return 9;
    }
    case 10: {
      return 10;
    }
    case 11: {
      return 11;
    }
    case 12: {
      return 12;
    }
    case 13: {
      return 13;
    }
    case 14: {
      return 14;
    }
    case 15: {
      return 15;
    }
    default: {
      return 16;
    }
  }
}
function _M0FP36mizchi7syntree4json16json__node__type(id) {
  let name;
  switch (id) {
    case 0: {
      name = "JsonDocument";
      break;
    }
    case 1: {
      name = "Object";
      break;
    }
    case 2: {
      name = "Array";
      break;
    }
    case 3: {
      name = "Property";
      break;
    }
    case 4: {
      name = "String";
      break;
    }
    case 5: {
      name = "Number";
      break;
    }
    case 6: {
      name = "True";
      break;
    }
    case 7: {
      name = "False";
      break;
    }
    case 8: {
      name = "Null";
      break;
    }
    case 9: {
      name = "BraceOpen";
      break;
    }
    case 10: {
      name = "BraceClose";
      break;
    }
    case 11: {
      name = "BracketOpen";
      break;
    }
    case 12: {
      name = "BracketClose";
      break;
    }
    case 13: {
      name = "Colon";
      break;
    }
    case 14: {
      name = "Comma";
      break;
    }
    case 15: {
      name = "PropertyName";
      break;
    }
    default: {
      name = "Error";
    }
  }
  return _M0MP26mizchi7syntree8NodeType3new(_M0MP36mizchi7syntree4json10JsonNodeId7to__int(id), name);
}
function _M0MP36mizchi7syntree4json13JsonTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree4json13JsonTokenizer(input, chars, chars.length, 0);
}
function _M0MP36mizchi7syntree4json13JsonTokenizer16skip__whitespace(self) {
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 32 || (c === 9 || (c === 10 || c === 13))) {
        self.pos = self.pos + 1 | 0;
      } else {
        return;
      }
      continue;
    } else {
      return;
    }
  }
}
function _M0MP36mizchi7syntree4json13JsonTokenizer12read__string(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 34) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92) {
          self.pos = self.pos + 1 | 0;
          if (self.pos < self.len) {
            self.pos = self.pos + 1 | 0;
          }
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4json9JsonToken(4, start, self.pos);
}
function _M0MP36mizchi7syntree4json13JsonTokenizer12read__number(self) {
  const start = self.pos;
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 45) {
    self.pos = self.pos + 1 | 0;
  }
  while (true) {
    let _tmp;
    if (self.pos < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      _tmp = _p >= 48 && _p <= 57;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 46) {
    self.pos = self.pos + 1 | 0;
    while (true) {
      let _tmp;
      if (self.pos < self.len) {
        const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        _tmp = _p >= 48 && _p <= 57;
      } else {
        _tmp = false;
      }
      if (_tmp) {
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 101 || c === 69) {
      self.pos = self.pos + 1 | 0;
      if (self.pos < self.len) {
        const sign = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (sign === 43 || sign === 45) {
          self.pos = self.pos + 1 | 0;
        }
      }
      while (true) {
        let _tmp;
        if (self.pos < self.len) {
          const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          _tmp = _p >= 48 && _p <= 57;
        } else {
          _tmp = false;
        }
        if (_tmp) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  return new _M0TP36mizchi7syntree4json9JsonToken(5, start, self.pos);
}
function _M0FP36mizchi7syntree4json14match__keyword(chars, start, len) {
  const word_len = len - start | 0;
  if (word_len === 4) {
    if (_M0MPC15array5Array2atGcE(chars, start) === 116 && (_M0MPC15array5Array2atGcE(chars, start + 1 | 0) === 114 && (_M0MPC15array5Array2atGcE(chars, start + 2 | 0) === 117 && _M0MPC15array5Array2atGcE(chars, start + 3 | 0) === 101))) {
      return 6;
    }
    if (_M0MPC15array5Array2atGcE(chars, start) === 110 && (_M0MPC15array5Array2atGcE(chars, start + 1 | 0) === 117 && (_M0MPC15array5Array2atGcE(chars, start + 2 | 0) === 108 && _M0MPC15array5Array2atGcE(chars, start + 3 | 0) === 108))) {
      return 8;
    }
  } else {
    if (word_len === 5) {
      if (_M0MPC15array5Array2atGcE(chars, start) === 102 && (_M0MPC15array5Array2atGcE(chars, start + 1 | 0) === 97 && (_M0MPC15array5Array2atGcE(chars, start + 2 | 0) === 108 && (_M0MPC15array5Array2atGcE(chars, start + 3 | 0) === 115 && _M0MPC15array5Array2atGcE(chars, start + 4 | 0) === 101)))) {
        return 7;
      }
    }
  }
  return 16;
}
function _M0MP36mizchi7syntree4json13JsonTokenizer13read__keyword(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c >= 97 && c <= 122) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  const node_type = _M0FP36mizchi7syntree4json14match__keyword(self.chars, start, self.pos);
  return new _M0TP36mizchi7syntree4json9JsonToken(node_type, start, self.pos);
}
function _M0MP36mizchi7syntree4json13JsonTokenizer11next__token(self) {
  _M0MP36mizchi7syntree4json13JsonTokenizer16skip__whitespace(self);
  if (self.pos >= self.len) {
    return undefined;
  }
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  _L: {
    _L$2: {
      switch (c) {
        case 123: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(9, start, self.pos);
        }
        case 125: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(10, start, self.pos);
        }
        case 91: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(11, start, self.pos);
        }
        case 93: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(12, start, self.pos);
        }
        case 58: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(13, start, self.pos);
        }
        case 44: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(14, start, self.pos);
        }
        case 34: {
          return _M0MP36mizchi7syntree4json13JsonTokenizer12read__string(self);
        }
        case 45: {
          return _M0MP36mizchi7syntree4json13JsonTokenizer12read__number(self);
        }
        case 48: {
          break _L$2;
        }
        case 49: {
          break _L$2;
        }
        case 50: {
          break _L$2;
        }
        case 51: {
          break _L$2;
        }
        case 52: {
          break _L$2;
        }
        case 53: {
          break _L$2;
        }
        case 54: {
          break _L$2;
        }
        case 55: {
          break _L$2;
        }
        case 56: {
          break _L$2;
        }
        case 57: {
          break _L$2;
        }
        case 116: {
          break _L;
        }
        case 102: {
          break _L;
        }
        case 110: {
          break _L;
        }
        default: {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree4json9JsonToken(16, start, self.pos);
        }
      }
    }
    return _M0MP36mizchi7syntree4json13JsonTokenizer12read__number(self);
  }
  return _M0MP36mizchi7syntree4json13JsonTokenizer13read__keyword(self);
}
function _M0MP36mizchi7syntree4json13JsonTokenizer13tokenize__all(self) {
  const tokens = [];
  while (true) {
    const _bind = _M0MP36mizchi7syntree4json13JsonTokenizer11next__token(self);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _token = _Some;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _token);
    }
    continue;
  }
  return tokens;
}
function _M0MP36mizchi7syntree4json10JsonParser3new(input) {
  const tokenizer = _M0MP36mizchi7syntree4json13JsonTokenizer3new(input);
  const tokens = _M0MP36mizchi7syntree4json13JsonTokenizer13tokenize__all(tokenizer);
  return new _M0TP36mizchi7syntree4json10JsonParser(input, tokens, 0);
}
function _M0MP36mizchi7syntree4json10JsonParser4peek(self) {
  return self.pos < self.tokens.length ? _M0MPC15array5Array2atGRP36mizchi7syntree4json9JsonTokenE(self.tokens, self.pos) : undefined;
}
function _M0MP36mizchi7syntree4json10JsonParser7advance(self) {
  if (self.pos < self.tokens.length) {
    const token = _M0MPC15array5Array2atGRP36mizchi7syntree4json9JsonTokenE(self.tokens, self.pos);
    self.pos = self.pos + 1 | 0;
    return token;
  } else {
    return undefined;
  }
}
function _M0MP36mizchi7syntree4json10JsonParser6expect(self, expected) {
  _L: {
    const _bind = _M0MP36mizchi7syntree4json10JsonParser4peek(self);
    if (_bind === undefined) {
      break _L;
    } else {
      const _Some = _bind;
      const _token = _Some;
      if (_M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_token.node_type, expected)) {
        return _M0MP36mizchi7syntree4json10JsonParser7advance(self);
      } else {
        break _L;
      }
    }
  }
  return undefined;
}
function _M0MP36mizchi7syntree4json10JsonParser12parse__value(self) {
  const _bind = _M0MP36mizchi7syntree4json10JsonParser4peek(self);
  if (_bind === undefined) {
    return undefined;
  } else {
    const _Some = _bind;
    const _token = _Some;
    const _bind$2 = _token.node_type;
    switch (_bind$2) {
      case 9: {
        return _M0MP36mizchi7syntree4json10JsonParser13parse__object(self);
      }
      case 11: {
        return _M0MP36mizchi7syntree4json10JsonParser12parse__array(self);
      }
      case 4: {
        _M0MP36mizchi7syntree4json10JsonParser7advance(self);
        const _p = _M0FP36mizchi7syntree4json16json__node__type(4);
        const _p$2 = _token.from;
        const _p$3 = _token.to;
        return new _M0DTP26mizchi7syntree4Tree4Leaf(_p, _p$2, _p$3);
      }
      case 5: {
        _M0MP36mizchi7syntree4json10JsonParser7advance(self);
        const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(5);
        const _p$5 = _token.from;
        const _p$6 = _token.to;
        return new _M0DTP26mizchi7syntree4Tree4Leaf(_p$4, _p$5, _p$6);
      }
      case 6: {
        _M0MP36mizchi7syntree4json10JsonParser7advance(self);
        const _p$7 = _M0FP36mizchi7syntree4json16json__node__type(6);
        const _p$8 = _token.from;
        const _p$9 = _token.to;
        return new _M0DTP26mizchi7syntree4Tree4Leaf(_p$7, _p$8, _p$9);
      }
      case 7: {
        _M0MP36mizchi7syntree4json10JsonParser7advance(self);
        const _p$10 = _M0FP36mizchi7syntree4json16json__node__type(7);
        const _p$11 = _token.from;
        const _p$12 = _token.to;
        return new _M0DTP26mizchi7syntree4Tree4Leaf(_p$10, _p$11, _p$12);
      }
      case 8: {
        _M0MP36mizchi7syntree4json10JsonParser7advance(self);
        const _p$13 = _M0FP36mizchi7syntree4json16json__node__type(8);
        const _p$14 = _token.from;
        const _p$15 = _token.to;
        return new _M0DTP26mizchi7syntree4Tree4Leaf(_p$13, _p$14, _p$15);
      }
      default: {
        return undefined;
      }
    }
  }
}
function _M0MP36mizchi7syntree4json10JsonParser12parse__array(self) {
  const open_bracket = _M0MP36mizchi7syntree4json10JsonParser6expect(self, 11);
  if (open_bracket === undefined) {
    return undefined;
  } else {
    const _Some = open_bracket;
    const _open_token = _Some;
    const children = [];
    const start = _open_token.from;
    const _p = _M0FP36mizchi7syntree4json16json__node__type(11);
    const _p$2 = _open_token.from;
    const _p$3 = _open_token.to;
    _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p, _p$2, _p$3));
    while (true) {
      if (!(self.pos >= self.tokens.length)) {
        _L: {
          const _bind = _M0MP36mizchi7syntree4json10JsonParser4peek(self);
          if (_bind === undefined) {
            break _L;
          } else {
            const _Some$2 = _bind;
            const _token = _Some$2;
            if (_M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_token.node_type, 12)) {
              break;
            } else {
              break _L;
            }
          }
        }
        const _bind = _M0MP36mizchi7syntree4json10JsonParser12parse__value(self);
        if (_bind === undefined) {
          break;
        } else {
          const _Some$2 = _bind;
          const _value = _Some$2;
          _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, _value);
        }
        const _bind$2 = _M0MP36mizchi7syntree4json10JsonParser4peek(self);
        if (_bind$2 === undefined) {
        } else {
          const _Some$2 = _bind$2;
          const _comma_token = _Some$2;
          if (_M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_comma_token.node_type, 14)) {
            _M0MP36mizchi7syntree4json10JsonParser7advance(self);
            const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(14);
            const _p$5 = _comma_token.from;
            const _p$6 = _comma_token.to;
            _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p$4, _p$5, _p$6));
          }
        }
        continue;
      } else {
        break;
      }
    }
    const close_bracket = _M0MP36mizchi7syntree4json10JsonParser6expect(self, 12);
    let end;
    if (close_bracket === undefined) {
      end = children.length > 0 ? _M0MP26mizchi7syntree4Tree2to(_M0MPC15array5Array2atGRP36mizchi7syntree4json9JsonTokenE(children, children.length - 1 | 0)) : start + 1 | 0;
    } else {
      const _Some$2 = close_bracket;
      const _token = _Some$2;
      const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(12);
      const _p$5 = _token.from;
      const _p$6 = _token.to;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p$4, _p$5, _p$6));
      end = _token.to;
    }
    const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(2);
    return new _M0DTP26mizchi7syntree4Tree4Node(_p$4, start, end, children);
  }
}
function _M0MP36mizchi7syntree4json10JsonParser13parse__object(self) {
  const open_brace = _M0MP36mizchi7syntree4json10JsonParser6expect(self, 9);
  if (open_brace === undefined) {
    return undefined;
  } else {
    const _Some = open_brace;
    const _open_token = _Some;
    const children = [];
    const start = _open_token.from;
    const _p = _M0FP36mizchi7syntree4json16json__node__type(9);
    const _p$2 = _open_token.from;
    const _p$3 = _open_token.to;
    _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p, _p$2, _p$3));
    while (true) {
      if (!(self.pos >= self.tokens.length)) {
        _L: {
          _L$2: {
            const _bind = _M0MP36mizchi7syntree4json10JsonParser4peek(self);
            if (_bind === undefined) {
              break _L$2;
            } else {
              const _Some$2 = _bind;
              const _token = _Some$2;
              if (_M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_token.node_type, 10)) {
                break;
              } else {
                if (_M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_token.node_type, 4)) {
                  const _bind$2 = _M0MP36mizchi7syntree4json10JsonParser15parse__property(self);
                  if (_bind$2 === undefined) {
                    break;
                  } else {
                    const _Some$3 = _bind$2;
                    const _prop = _Some$3;
                    _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, _prop);
                  }
                  const _bind$3 = _M0MP36mizchi7syntree4json10JsonParser4peek(self);
                  if (_bind$3 === undefined) {
                  } else {
                    const _Some$3 = _bind$3;
                    const _comma_token = _Some$3;
                    if (_M0IP36mizchi7syntree4json10JsonNodeIdPB2Eq5equal(_comma_token.node_type, 14)) {
                      _M0MP36mizchi7syntree4json10JsonParser7advance(self);
                      const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(14);
                      const _p$5 = _comma_token.from;
                      const _p$6 = _comma_token.to;
                      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p$4, _p$5, _p$6));
                    }
                  }
                } else {
                  break _L$2;
                }
              }
            }
            break _L;
          }
          break;
        }
        continue;
      } else {
        break;
      }
    }
    const close_brace = _M0MP36mizchi7syntree4json10JsonParser6expect(self, 10);
    let end;
    if (close_brace === undefined) {
      end = children.length > 0 ? _M0MP26mizchi7syntree4Tree2to(_M0MPC15array5Array2atGRP36mizchi7syntree4json9JsonTokenE(children, children.length - 1 | 0)) : start + 1 | 0;
    } else {
      const _Some$2 = close_brace;
      const _token = _Some$2;
      const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(10);
      const _p$5 = _token.from;
      const _p$6 = _token.to;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p$4, _p$5, _p$6));
      end = _token.to;
    }
    const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(1);
    return new _M0DTP26mizchi7syntree4Tree4Node(_p$4, start, end, children);
  }
}
function _M0MP36mizchi7syntree4json10JsonParser15parse__property(self) {
  const key = _M0MP36mizchi7syntree4json10JsonParser6expect(self, 4);
  if (key === undefined) {
    return undefined;
  } else {
    const _Some = key;
    const _key_token = _Some;
    const start = _key_token.from;
    const children = [];
    const _p = _M0FP36mizchi7syntree4json16json__node__type(15);
    const _p$2 = _key_token.from;
    const _p$3 = _key_token.to;
    _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p, _p$2, _p$3));
    const colon = _M0MP36mizchi7syntree4json10JsonParser6expect(self, 13);
    if (colon === undefined) {
    } else {
      const _Some$2 = colon;
      const _colon_token = _Some$2;
      const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(13);
      const _p$5 = _colon_token.from;
      const _p$6 = _colon_token.to;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, new _M0DTP26mizchi7syntree4Tree4Leaf(_p$4, _p$5, _p$6));
    }
    const _bind = _M0MP36mizchi7syntree4json10JsonParser12parse__value(self);
    if (_bind === undefined) {
    } else {
      const _Some$2 = _bind;
      const _value = _Some$2;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(children, _value);
    }
    const end = children.length > 0 ? _M0MP26mizchi7syntree4Tree2to(_M0MPC15array5Array2atGRP36mizchi7syntree4json9JsonTokenE(children, children.length - 1 | 0)) : _key_token.to;
    const _p$4 = _M0FP36mizchi7syntree4json16json__node__type(3);
    return new _M0DTP26mizchi7syntree4Tree4Node(_p$4, start, end, children);
  }
}
function _M0MP36mizchi7syntree4json10JsonParser5parse(self) {
  const value = _M0MP36mizchi7syntree4json10JsonParser12parse__value(self);
  if (value === undefined) {
    return undefined;
  } else {
    const _Some = value;
    const _v = _Some;
    const _p = _M0FP36mizchi7syntree4json16json__node__type(0);
    const _p$2 = _M0MP26mizchi7syntree4Tree4from(_v);
    const _p$3 = _M0MP26mizchi7syntree4Tree2to(_v);
    const _p$4 = [_v];
    return new _M0DTP26mizchi7syntree4Tree4Node(_p, _p$2, _p$3, _p$4);
  }
}
function _M0FP36mizchi7syntree4json11parse__json(input) {
  const parser = _M0MP36mizchi7syntree4json10JsonParser3new(input);
  return _M0MP36mizchi7syntree4json10JsonParser5parse(parser);
}
function _M0FP36mizchi7syntree4json17json__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceOpen", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceClose", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketOpen", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketClose", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Colon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comma", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "String", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Number", 4);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "True", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "False", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Null", 7);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PropertyName", 8);
  return h;
}
function _M0FP36mizchi7syntree4json15highlight__json(source) {
  const _bind = _M0FP36mizchi7syntree4json11parse__json(source);
  if (_bind === undefined) {
    return [];
  } else {
    const _Some = _bind;
    const _tree = _Some;
    const highlighter = _M0FP36mizchi7syntree4json17json__highlighter();
    return _M0MP26mizchi7syntree11Highlighter9highlight(highlighter, _tree);
  }
}
function _M0IP36mizchi7syntree7moonbit10MbtContextPB2Eq5equal(_x_172, _x_173) {
  switch (_x_172) {
    case 0: {
      if (_x_173 === 0) {
        return true;
      } else {
        return false;
      }
    }
    case 1: {
      if (_x_173 === 1) {
        return true;
      } else {
        return false;
      }
    }
    default: {
      if (_x_173 === 2) {
        return true;
      } else {
        return false;
      }
    }
  }
}
function _M0FP36mizchi7syntree7moonbit11is__keyword(word) {
  switch (word) {
    case "if": {
      return true;
    }
    case "else": {
      return true;
    }
    case "match": {
      return true;
    }
    case "while": {
      return true;
    }
    case "loop": {
      return true;
    }
    case "for": {
      return true;
    }
    case "in": {
      return true;
    }
    case "break": {
      return true;
    }
    case "continue": {
      return true;
    }
    case "return": {
      return true;
    }
    case "fn": {
      return true;
    }
    case "let": {
      return true;
    }
    case "const": {
      return true;
    }
    case "type": {
      return true;
    }
    case "struct": {
      return true;
    }
    case "enum": {
      return true;
    }
    case "trait": {
      return true;
    }
    case "impl": {
      return true;
    }
    case "derive": {
      return true;
    }
    case "test": {
      return true;
    }
    case "init": {
      return true;
    }
    case "extern": {
      return true;
    }
    case "pub": {
      return true;
    }
    case "priv": {
      return true;
    }
    case "mut": {
      return true;
    }
    case "readonly": {
      return true;
    }
    case "async": {
      return true;
    }
    case "try": {
      return true;
    }
    case "catch": {
      return true;
    }
    case "throw": {
      return true;
    }
    case "raise": {
      return true;
    }
    case "guard": {
      return true;
    }
    case "as": {
      return true;
    }
    case "is": {
      return true;
    }
    case "with": {
      return true;
    }
    case "import": {
      return true;
    }
    case "and": {
      return true;
    }
    case "or": {
      return true;
    }
    case "not": {
      return true;
    }
    case "typealias": {
      return true;
    }
    case "traitalias": {
      return true;
    }
    case "fnalias": {
      return true;
    }
    case "using": {
      return true;
    }
    case "defer": {
      return true;
    }
    case "suberror": {
      return true;
    }
    case "noraise": {
      return true;
    }
    case "letrec": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0FP36mizchi7syntree7moonbit17is__builtin__type(word) {
  switch (word) {
    case "Int": {
      return true;
    }
    case "Int64": {
      return true;
    }
    case "UInt": {
      return true;
    }
    case "UInt64": {
      return true;
    }
    case "Double": {
      return true;
    }
    case "Float": {
      return true;
    }
    case "Bool": {
      return true;
    }
    case "String": {
      return true;
    }
    case "Char": {
      return true;
    }
    case "Byte": {
      return true;
    }
    case "Bytes": {
      return true;
    }
    case "Unit": {
      return true;
    }
    case "Array": {
      return true;
    }
    case "Map": {
      return true;
    }
    case "Set": {
      return true;
    }
    case "Option": {
      return true;
    }
    case "Result": {
      return true;
    }
    case "Iter": {
      return true;
    }
    case "FixedArray": {
      return true;
    }
    case "Self": {
      return true;
    }
    case "Error": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree7moonbit12MbtTokenizer(input, chars, chars.length, 0, [0]);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer7context(self) {
  return self.context_stack.length > 0 ? _M0MPC15array5Array2atGRP36mizchi7syntree7moonbit10MbtContextE(self.context_stack, self.context_stack.length - 1 | 0) : 0;
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer13push__context(self, ctx) {
  _M0MPC15array5Array4pushGRP36mizchi7syntree7moonbit10MbtContextE(self.context_stack, ctx);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer12pop__context(self) {
  if (self.context_stack.length > 1) {
    _M0MPC15array5Array3popGRP36mizchi7syntree7moonbit10MbtContextE(self.context_stack);
    return;
  } else {
    return;
  }
}
function _M0FP36mizchi7syntree7moonbit14is__whitespace(c) {
  return c === 32 || (c === 9 || (c === 10 || c === 13));
}
function _M0FP36mizchi7syntree7moonbit14is__hex__digit(c) {
  return c >= 48 && c <= 57 || (c >= 97 && c <= 102 || c >= 65 && c <= 70);
}
function _M0FP36mizchi7syntree7moonbit16is__ident__start(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || c === 95);
}
function _M0FP36mizchi7syntree7moonbit15is__ident__part(c) {
  return _M0FP36mizchi7syntree7moonbit16is__ident__start(c) || c >= 48 && c <= 57;
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer16skip__whitespace(self) {
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree7moonbit14is__whitespace(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer12read__string(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 34) {
        self.pos = self.pos + 1 | 0;
        return new _M0TP36mizchi7syntree7moonbit8MbtToken(1, start, self.pos);
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
          if (next === 123) {
            self.pos = self.pos + 2 | 0;
            _M0MP36mizchi7syntree7moonbit12MbtTokenizer13push__context(self, 1);
            return new _M0TP36mizchi7syntree7moonbit8MbtToken(2, start, self.pos);
          } else {
            self.pos = self.pos + 2 | 0;
          }
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(1, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer26read__string__continuation(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  _M0MP36mizchi7syntree7moonbit12MbtTokenizer12pop__context(self);
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 34) {
        self.pos = self.pos + 1 | 0;
        return new _M0TP36mizchi7syntree7moonbit8MbtToken(4, start, self.pos);
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
          if (next === 123) {
            self.pos = self.pos + 2 | 0;
            _M0MP36mizchi7syntree7moonbit12MbtTokenizer13push__context(self, 1);
            return new _M0TP36mizchi7syntree7moonbit8MbtToken(3, start, self.pos);
          } else {
            self.pos = self.pos + 2 | 0;
          }
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(4, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer10read__char(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 39) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(5, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer18read__byte__string(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 34) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(7, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer10read__byte(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 39) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(6, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer12read__number(self) {
  const start = self.pos;
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 48) {
    if ((self.pos + 1 | 0) < self.len) {
      const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      if (next === 120 || next === 88) {
        self.pos = self.pos + 2 | 0;
        while (true) {
          if (self.pos < self.len) {
            const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
            if (_M0FP36mizchi7syntree7moonbit14is__hex__digit(c) || c === 95) {
              self.pos = self.pos + 1 | 0;
            } else {
              break;
            }
            continue;
          } else {
            break;
          }
        }
        return new _M0TP36mizchi7syntree7moonbit8MbtToken(8, start, self.pos);
      } else {
        if (next === 98 || next === 66) {
          self.pos = self.pos + 2 | 0;
          while (true) {
            if (self.pos < self.len) {
              const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
              if (c === 48 || (c === 49 || c === 95)) {
                self.pos = self.pos + 1 | 0;
              } else {
                break;
              }
              continue;
            } else {
              break;
            }
          }
          return new _M0TP36mizchi7syntree7moonbit8MbtToken(8, start, self.pos);
        } else {
          if (next === 111 || next === 79) {
            self.pos = self.pos + 2 | 0;
            while (true) {
              if (self.pos < self.len) {
                const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
                if (c >= 48 && c <= 55 || c === 95) {
                  self.pos = self.pos + 1 | 0;
                } else {
                  break;
                }
                continue;
              } else {
                break;
              }
            }
            return new _M0TP36mizchi7syntree7moonbit8MbtToken(8, start, self.pos);
          }
        }
      }
    }
  }
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c >= 48 && c <= 57 || c === 95) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 46) {
    let _tmp;
    if ((self.pos + 1 | 0) < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      _tmp = _p >= 48 && _p <= 57;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        if (self.pos < self.len) {
          const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (c >= 48 && c <= 57 || c === 95) {
            self.pos = self.pos + 1 | 0;
          } else {
            break;
          }
          continue;
        } else {
          break;
        }
      }
    }
  }
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 101 || c === 69) {
      self.pos = self.pos + 1 | 0;
      if (self.pos < self.len) {
        const sign = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (sign === 43 || sign === 45) {
          self.pos = self.pos + 1 | 0;
        }
      }
      while (true) {
        if (self.pos < self.len) {
          const c$2 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (c$2 >= 48 && c$2 <= 57 || c$2 === 95) {
            self.pos = self.pos + 1 | 0;
          } else {
            break;
          }
          continue;
        } else {
          break;
        }
      }
    }
  }
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 76 || c === 85) {
      self.pos = self.pos + 1 | 0;
      if (self.pos < self.len) {
        const c2 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (c2 === 76 || c2 === 85) {
          self.pos = self.pos + 1 | 0;
        }
      }
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(8, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer16read__identifier(self) {
  const start = self.pos;
  const first_char = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree7moonbit15is__ident__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const word = self.input.substring(start, self.pos);
  let token_type;
  switch (word) {
    case "true": {
      token_type = 9;
      break;
    }
    case "false": {
      token_type = 10;
      break;
    }
    case "_": {
      token_type = 32;
      break;
    }
    default: {
      token_type = _M0FP36mizchi7syntree7moonbit11is__keyword(word) ? 0 : first_char >= 65 && first_char <= 90 && _M0FP36mizchi7syntree7moonbit17is__builtin__type(word) ? 12 : first_char >= 65 && first_char <= 90 ? 12 : 11;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(token_type, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer19read__line__comment(self) {
  const start = self.pos;
  if ((self.pos + 3 | 0) < self.len && (_M0MPC15array5Array2atGcE(self.chars, self.pos + 2 | 0) === 47 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 3 | 0) === 124)) {
    self.pos = self.pos + 4 | 0;
    while (true) {
      if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    return new _M0TP36mizchi7syntree7moonbit8MbtToken(34, start, self.pos);
  }
  self.pos = self.pos + 2 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(33, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer17read__raw__string(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(35, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer20read__interp__string(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 92 && ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 123)) {
        self.pos = self.pos + 2 | 0;
        _M0MP36mizchi7syntree7moonbit12MbtTokenizer13push__context(self, 2);
        return new _M0TP36mizchi7syntree7moonbit8MbtToken(37, start, self.pos);
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(36, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer34read__interp__string__continuation(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  _M0MP36mizchi7syntree7moonbit12MbtTokenizer12pop__context(self);
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 92 && ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 123)) {
        self.pos = self.pos + 2 | 0;
        _M0MP36mizchi7syntree7moonbit12MbtTokenizer13push__context(self, 2);
        return new _M0TP36mizchi7syntree7moonbit8MbtToken(38, start, self.pos);
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(39, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer14read__operator(self) {
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  if ((self.pos + 1 | 0) < self.len) {
    const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    _L: {
      _L$2: {
        _L$3: {
          _L$4: {
            switch (c) {
              case 45: {
                switch (next) {
                  case 62: {
                    break _L$4;
                  }
                  case 61: {
                    break _L$2;
                  }
                }
                break;
              }
              case 61: {
                switch (next) {
                  case 62: {
                    break _L$4;
                  }
                  case 61: {
                    break _L$2;
                  }
                }
                break;
              }
              case 46: {
                if (next === 46) {
                  self.pos = self.pos + 2 | 0;
                  return new _M0TP36mizchi7syntree7moonbit8MbtToken(16, start, self.pos);
                }
                break;
              }
              case 124: {
                switch (next) {
                  case 62: {
                    self.pos = self.pos + 2 | 0;
                    return new _M0TP36mizchi7syntree7moonbit8MbtToken(17, start, self.pos);
                  }
                  case 124: {
                    break _L$2;
                  }
                }
                break;
              }
              case 58: {
                if (next === 58) {
                  self.pos = self.pos + 2 | 0;
                  return new _M0TP36mizchi7syntree7moonbit8MbtToken(29, start, self.pos);
                }
                break;
              }
              case 33: {
                if (next === 61) {
                  break _L$2;
                }
                break;
              }
              case 60: {
                switch (next) {
                  case 61: {
                    break _L$2;
                  }
                  case 60: {
                    break _L$2;
                  }
                }
                break;
              }
              case 62: {
                switch (next) {
                  case 61: {
                    break _L$2;
                  }
                  case 62: {
                    break _L$2;
                  }
                }
                break;
              }
              case 38: {
                if (next === 38) {
                  break _L$2;
                }
                break;
              }
              case 43: {
                if (next === 61) {
                  break _L$2;
                }
                break;
              }
              case 42: {
                if (next === 61) {
                  break _L$2;
                }
                break;
              }
              case 47: {
                if (next === 61) {
                  break _L$2;
                }
                break;
              }
            }
            break _L$3;
          }
          self.pos = self.pos + 2 | 0;
          return new _M0TP36mizchi7syntree7moonbit8MbtToken(15, start, self.pos);
        }
        break _L;
      }
      self.pos = self.pos + 2 | 0;
      return new _M0TP36mizchi7syntree7moonbit8MbtToken(14, start, self.pos);
    }
  }
  self.pos = self.pos + 1 | 0;
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(14, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer11read__label(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree7moonbit15is__ident__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree7moonbit8MbtToken(13, start, self.pos);
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer11next__token(self) {
  _M0MP36mizchi7syntree7moonbit12MbtTokenizer16skip__whitespace(self);
  if (self.pos >= self.len) {
    return undefined;
  }
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  let token;
  _L: {
    _L$2: {
      _L$3: {
        _L$4: {
          switch (c) {
            case 34: {
              token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer12read__string(self);
              break;
            }
            case 39: {
              token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer10read__char(self);
              break;
            }
            case 98: {
              if ((self.pos + 1 | 0) < self.len) {
                const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
                token = next === 34 ? _M0MP36mizchi7syntree7moonbit12MbtTokenizer18read__byte__string(self) : next === 39 ? _M0MP36mizchi7syntree7moonbit12MbtTokenizer10read__byte(self) : _M0MP36mizchi7syntree7moonbit12MbtTokenizer16read__identifier(self);
              } else {
                token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer16read__identifier(self);
              }
              break;
            }
            case 47: {
              token = (self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 47 ? _M0MP36mizchi7syntree7moonbit12MbtTokenizer19read__line__comment(self) : _M0MP36mizchi7syntree7moonbit12MbtTokenizer14read__operator(self);
              break;
            }
            case 35: {
              if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 124) {
                token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer17read__raw__string(self);
              } else {
                self.pos = self.pos + 1 | 0;
                token = new _M0TP36mizchi7syntree7moonbit8MbtToken(14, start, self.pos);
              }
              break;
            }
            case 36: {
              if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 124) {
                token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer20read__interp__string(self);
              } else {
                self.pos = self.pos + 1 | 0;
                token = new _M0TP36mizchi7syntree7moonbit8MbtToken(14, start, self.pos);
              }
              break;
            }
            case 123: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(19, start, self.pos);
              break;
            }
            case 125: {
              const ctx = _M0MP36mizchi7syntree7moonbit12MbtTokenizer7context(self);
              if (_M0IP36mizchi7syntree7moonbit10MbtContextPB2Eq5equal(ctx, 1)) {
                token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer26read__string__continuation(self);
              } else {
                if (_M0IP36mizchi7syntree7moonbit10MbtContextPB2Eq5equal(ctx, 2)) {
                  token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer34read__interp__string__continuation(self);
                } else {
                  self.pos = self.pos + 1 | 0;
                  token = new _M0TP36mizchi7syntree7moonbit8MbtToken(20, start, self.pos);
                }
              }
              break;
            }
            case 91: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(21, start, self.pos);
              break;
            }
            case 93: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(22, start, self.pos);
              break;
            }
            case 40: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(23, start, self.pos);
              break;
            }
            case 41: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(24, start, self.pos);
              break;
            }
            case 59: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(25, start, self.pos);
              break;
            }
            case 44: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(26, start, self.pos);
              break;
            }
            case 58: {
              if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 58) {
                self.pos = self.pos + 2 | 0;
                token = new _M0TP36mizchi7syntree7moonbit8MbtToken(29, start, self.pos);
              } else {
                self.pos = self.pos + 1 | 0;
                token = new _M0TP36mizchi7syntree7moonbit8MbtToken(28, start, self.pos);
              }
              break;
            }
            case 64: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(30, start, self.pos);
              break;
            }
            case 63: {
              self.pos = self.pos + 1 | 0;
              token = new _M0TP36mizchi7syntree7moonbit8MbtToken(18, start, self.pos);
              break;
            }
            case 126: {
              if ((self.pos + 1 | 0) < self.len && _M0FP36mizchi7syntree7moonbit16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0))) {
                token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer11read__label(self);
              } else {
                self.pos = self.pos + 1 | 0;
                token = new _M0TP36mizchi7syntree7moonbit8MbtToken(31, start, self.pos);
              }
              break;
            }
            case 46: {
              if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 46) {
                self.pos = self.pos + 2 | 0;
                token = new _M0TP36mizchi7syntree7moonbit8MbtToken(16, start, self.pos);
              } else {
                let _tmp;
                if ((self.pos + 1 | 0) < self.len) {
                  const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
                  _tmp = _p >= 48 && _p <= 57;
                } else {
                  _tmp = false;
                }
                if (_tmp) {
                  token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer12read__number(self);
                } else {
                  self.pos = self.pos + 1 | 0;
                  token = new _M0TP36mizchi7syntree7moonbit8MbtToken(27, start, self.pos);
                }
              }
              break;
            }
            case 48: {
              break _L$4;
            }
            case 49: {
              break _L$4;
            }
            case 50: {
              break _L$4;
            }
            case 51: {
              break _L$4;
            }
            case 52: {
              break _L$4;
            }
            case 53: {
              break _L$4;
            }
            case 54: {
              break _L$4;
            }
            case 55: {
              break _L$4;
            }
            case 56: {
              break _L$4;
            }
            case 57: {
              break _L$4;
            }
            default: {
              if (_M0FP36mizchi7syntree7moonbit16is__ident__start(c)) {
                token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer16read__identifier(self);
              } else {
                switch (c) {
                  case 43: {
                    break _L$2;
                  }
                  case 45: {
                    break _L$2;
                  }
                  case 42: {
                    break _L$2;
                  }
                  case 37: {
                    break _L$2;
                  }
                  case 61: {
                    break _L$2;
                  }
                  case 33: {
                    break _L$2;
                  }
                  case 60: {
                    break _L$2;
                  }
                  case 62: {
                    break _L$2;
                  }
                  case 38: {
                    break _L$2;
                  }
                  case 124: {
                    break _L$2;
                  }
                  case 94: {
                    break _L$2;
                  }
                  default: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree7moonbit8MbtToken(40, start, self.pos);
                  }
                }
              }
            }
          }
          break _L$3;
        }
        token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer12read__number(self);
      }
      break _L;
    }
    token = _M0MP36mizchi7syntree7moonbit12MbtTokenizer14read__operator(self);
  }
  return token;
}
function _M0MP36mizchi7syntree7moonbit12MbtTokenizer13tokenize__all(self) {
  const tokens = [];
  while (true) {
    const _bind = _M0MP36mizchi7syntree7moonbit12MbtTokenizer11next__token(self);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _token = _Some;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _token);
    }
    continue;
  }
  return tokens;
}
function _M0FP36mizchi7syntree7moonbit16mbt__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Keyword", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "String", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "StringHead", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "StringMiddle", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "StringTail", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Char", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Byte", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ByteString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "RawString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "InterpString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "InterpStringHead", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "InterpStringMiddle", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "InterpStringTail", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Number", 4);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "True", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "False", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Identifier", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TypeName", 11);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Label", 8);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Operator", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Arrow", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Range", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Pipe", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Question", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceOpen", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceClose", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketOpen", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketClose", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenOpen", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenClose", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Semicolon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comma", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Dot", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Colon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "DoubleColon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "At", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Tilde", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Underscore", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "LineComment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "DocComment", 19);
  return h;
}
function _M0FP36mizchi7syntree7moonbit17token__type__name(t) {
  switch (t) {
    case 0: {
      return "Keyword";
    }
    case 1: {
      return "String";
    }
    case 2: {
      return "StringHead";
    }
    case 3: {
      return "StringMiddle";
    }
    case 4: {
      return "StringTail";
    }
    case 5: {
      return "Char";
    }
    case 6: {
      return "Byte";
    }
    case 7: {
      return "ByteString";
    }
    case 35: {
      return "RawString";
    }
    case 36: {
      return "InterpString";
    }
    case 37: {
      return "InterpStringHead";
    }
    case 38: {
      return "InterpStringMiddle";
    }
    case 39: {
      return "InterpStringTail";
    }
    case 8: {
      return "Number";
    }
    case 9: {
      return "True";
    }
    case 10: {
      return "False";
    }
    case 11: {
      return "Identifier";
    }
    case 12: {
      return "TypeName";
    }
    case 13: {
      return "Label";
    }
    case 14: {
      return "Operator";
    }
    case 15: {
      return "Arrow";
    }
    case 16: {
      return "Range";
    }
    case 17: {
      return "Pipe";
    }
    case 18: {
      return "Question";
    }
    case 19: {
      return "BraceOpen";
    }
    case 20: {
      return "BraceClose";
    }
    case 21: {
      return "BracketOpen";
    }
    case 22: {
      return "BracketClose";
    }
    case 23: {
      return "ParenOpen";
    }
    case 24: {
      return "ParenClose";
    }
    case 25: {
      return "Semicolon";
    }
    case 26: {
      return "Comma";
    }
    case 27: {
      return "Dot";
    }
    case 28: {
      return "Colon";
    }
    case 29: {
      return "DoubleColon";
    }
    case 30: {
      return "At";
    }
    case 31: {
      return "Tilde";
    }
    case 32: {
      return "Underscore";
    }
    case 33: {
      return "LineComment";
    }
    case 34: {
      return "DocComment";
    }
    default: {
      return "Error";
    }
  }
}
function _M0FP36mizchi7syntree7moonbit18highlight__moonbit(source) {
  const tokenizer = _M0MP36mizchi7syntree7moonbit12MbtTokenizer3new(source);
  const tokens = _M0MP36mizchi7syntree7moonbit12MbtTokenizer13tokenize__all(tokenizer);
  const highlighter = _M0FP36mizchi7syntree7moonbit16mbt__highlighter();
  const result = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const name = _M0FP36mizchi7syntree7moonbit17token__type__name(token.token_type);
      const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(highlighter, name);
      if (_M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(tag, 23)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(result, _M0MP26mizchi7syntree14HighlightToken3new(token.from, token.to, tag));
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0FP36mizchi7syntree4rust11is__keyword(word) {
  switch (word) {
    case "fn": {
      return true;
    }
    case "let": {
      return true;
    }
    case "const": {
      return true;
    }
    case "static": {
      return true;
    }
    case "type": {
      return true;
    }
    case "struct": {
      return true;
    }
    case "enum": {
      return true;
    }
    case "union": {
      return true;
    }
    case "trait": {
      return true;
    }
    case "impl": {
      return true;
    }
    case "mod": {
      return true;
    }
    case "use": {
      return true;
    }
    case "pub": {
      return true;
    }
    case "crate": {
      return true;
    }
    case "super": {
      return true;
    }
    case "self": {
      return true;
    }
    case "extern": {
      return true;
    }
    case "unsafe": {
      return true;
    }
    case "async": {
      return true;
    }
    case "await": {
      return true;
    }
    case "dyn": {
      return true;
    }
    case "move": {
      return true;
    }
    case "mut": {
      return true;
    }
    case "ref": {
      return true;
    }
    case "in": {
      return true;
    }
    case "where": {
      return true;
    }
    case "as": {
      return true;
    }
    case "Self": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0FP36mizchi7syntree4rust17is__control__flow(word) {
  switch (word) {
    case "if": {
      return true;
    }
    case "else": {
      return true;
    }
    case "match": {
      return true;
    }
    case "loop": {
      return true;
    }
    case "while": {
      return true;
    }
    case "for": {
      return true;
    }
    case "return": {
      return true;
    }
    case "break": {
      return true;
    }
    case "continue": {
      return true;
    }
    case "yield": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0FP36mizchi7syntree4rust17is__builtin__type(word) {
  switch (word) {
    case "bool": {
      return true;
    }
    case "char": {
      return true;
    }
    case "str": {
      return true;
    }
    case "u8": {
      return true;
    }
    case "u16": {
      return true;
    }
    case "u32": {
      return true;
    }
    case "u64": {
      return true;
    }
    case "u128": {
      return true;
    }
    case "usize": {
      return true;
    }
    case "i8": {
      return true;
    }
    case "i16": {
      return true;
    }
    case "i32": {
      return true;
    }
    case "i64": {
      return true;
    }
    case "i128": {
      return true;
    }
    case "isize": {
      return true;
    }
    case "f32": {
      return true;
    }
    case "f64": {
      return true;
    }
    case "String": {
      return true;
    }
    case "Vec": {
      return true;
    }
    case "Option": {
      return true;
    }
    case "Result": {
      return true;
    }
    case "Box": {
      return true;
    }
    case "Rc": {
      return true;
    }
    case "Arc": {
      return true;
    }
    case "Cell": {
      return true;
    }
    case "RefCell": {
      return true;
    }
    case "Mutex": {
      return true;
    }
    case "RwLock": {
      return true;
    }
    case "HashMap": {
      return true;
    }
    case "HashSet": {
      return true;
    }
    case "BTreeMap": {
      return true;
    }
    case "BTreeSet": {
      return true;
    }
    case "Cow": {
      return true;
    }
    case "Pin": {
      return true;
    }
    case "PhantomData": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0MP36mizchi7syntree4rust13RustTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree4rust13RustTokenizer(input, chars, chars.length, 0);
}
function _M0FP36mizchi7syntree4rust14is__hex__digit(c) {
  return c >= 48 && c <= 57 || (c >= 97 && c <= 102 || c >= 65 && c <= 70);
}
function _M0FP36mizchi7syntree4rust16is__ident__start(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || c === 95);
}
function _M0FP36mizchi7syntree4rust15is__ident__part(c) {
  return _M0FP36mizchi7syntree4rust16is__ident__start(c) || c >= 48 && c <= 57;
}
function _M0MP36mizchi7syntree4rust13RustTokenizer16skip__whitespace(self) {
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 32 || (c === 9 || (c === 10 || c === 13))) {
        self.pos = self.pos + 1 | 0;
      } else {
        return;
      }
      continue;
    } else {
      return;
    }
  }
}
function _M0MP36mizchi7syntree4rust13RustTokenizer12read__string(self) {
  const start = self.pos;
  if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 114) {
    self.pos = self.pos + 1 | 0;
    let hash_count = 0;
    while (true) {
      if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 35) {
        hash_count = hash_count + 1 | 0;
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 34) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        if (self.pos < self.len) {
          if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 34) {
            self.pos = self.pos + 1 | 0;
            let closing_hashes = 0;
            while (true) {
              if (self.pos < self.len && (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 35 && closing_hashes < hash_count)) {
                closing_hashes = closing_hashes + 1 | 0;
                self.pos = self.pos + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            if (closing_hashes === hash_count) {
              break;
            }
          } else {
            self.pos = self.pos + 1 | 0;
          }
          continue;
        } else {
          break;
        }
      }
      return new _M0TP36mizchi7syntree4rust9RustToken(2, start, self.pos);
    }
    self.pos = start;
  }
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 34) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          if (c === 10) {
            break;
          } else {
            self.pos = self.pos + 1 | 0;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4rust9RustToken(2, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer10read__char(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  if (self.pos < self.len && _M0FP36mizchi7syntree4rust16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
    while (true) {
      if (self.pos < self.len && _M0FP36mizchi7syntree4rust15is__ident__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 39) {
      self.pos = self.pos + 1 | 0;
      return new _M0TP36mizchi7syntree4rust9RustToken(3, start, self.pos);
    } else {
      return new _M0TP36mizchi7syntree4rust9RustToken(8, start, self.pos);
    }
  }
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 39) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          if (c === 10) {
            break;
          } else {
            self.pos = self.pos + 1 | 0;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4rust9RustToken(3, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer20read__number__suffix(self) {
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 117 || (c === 105 || c === 102)) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        let _tmp;
        if (self.pos < self.len) {
          const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          _tmp = _p >= 48 && _p <= 57;
        } else {
          _tmp = false;
        }
        if (_tmp) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          return;
        }
      }
    } else {
      return;
    }
  } else {
    return;
  }
}
function _M0MP36mizchi7syntree4rust13RustTokenizer12read__number(self) {
  const start = self.pos;
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 48) {
    if ((self.pos + 1 | 0) < self.len) {
      const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      if (next === 120 || next === 88) {
        self.pos = self.pos + 2 | 0;
        while (true) {
          if (self.pos < self.len) {
            const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
            if (_M0FP36mizchi7syntree4rust14is__hex__digit(c) || c === 95) {
              self.pos = self.pos + 1 | 0;
            } else {
              break;
            }
            continue;
          } else {
            break;
          }
        }
        _M0MP36mizchi7syntree4rust13RustTokenizer20read__number__suffix(self);
        return new _M0TP36mizchi7syntree4rust9RustToken(4, start, self.pos);
      } else {
        if (next === 98 || next === 66) {
          self.pos = self.pos + 2 | 0;
          while (true) {
            if (self.pos < self.len) {
              const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
              if (c === 48 || (c === 49 || c === 95)) {
                self.pos = self.pos + 1 | 0;
              } else {
                break;
              }
              continue;
            } else {
              break;
            }
          }
          _M0MP36mizchi7syntree4rust13RustTokenizer20read__number__suffix(self);
          return new _M0TP36mizchi7syntree4rust9RustToken(4, start, self.pos);
        } else {
          if (next === 111 || next === 79) {
            self.pos = self.pos + 2 | 0;
            while (true) {
              if (self.pos < self.len) {
                const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
                if (c >= 48 && c <= 55 || c === 95) {
                  self.pos = self.pos + 1 | 0;
                } else {
                  break;
                }
                continue;
              } else {
                break;
              }
            }
            _M0MP36mizchi7syntree4rust13RustTokenizer20read__number__suffix(self);
            return new _M0TP36mizchi7syntree4rust9RustToken(4, start, self.pos);
          }
        }
      }
    }
  }
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c >= 48 && c <= 57 || c === 95) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 46) {
    let _tmp;
    if ((self.pos + 1 | 0) < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      _tmp = _p >= 48 && _p <= 57;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        if (self.pos < self.len) {
          const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (c >= 48 && c <= 57 || c === 95) {
            self.pos = self.pos + 1 | 0;
          } else {
            break;
          }
          continue;
        } else {
          break;
        }
      }
    }
  }
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 101 || c === 69) {
      self.pos = self.pos + 1 | 0;
      if (self.pos < self.len) {
        const sign = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (sign === 43 || sign === 45) {
          self.pos = self.pos + 1 | 0;
        }
      }
      while (true) {
        if (self.pos < self.len) {
          const c$2 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
          if (c$2 >= 48 && c$2 <= 57 || c$2 === 95) {
            self.pos = self.pos + 1 | 0;
          } else {
            break;
          }
          continue;
        } else {
          break;
        }
      }
    }
  }
  _M0MP36mizchi7syntree4rust13RustTokenizer20read__number__suffix(self);
  return new _M0TP36mizchi7syntree4rust9RustToken(4, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer16read__identifier(self) {
  const start = self.pos;
  const first_char = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree4rust15is__ident__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 33) {
    self.pos = self.pos + 1 | 0;
    return new _M0TP36mizchi7syntree4rust9RustToken(9, start, self.pos);
  }
  const word = self.input.substring(start, self.pos);
  let token_type;
  _L: {
    _L$2: {
      switch (word) {
        case "true": {
          break _L$2;
        }
        case "false": {
          break _L$2;
        }
        default: {
          token_type = _M0FP36mizchi7syntree4rust17is__control__flow(word) ? 1 : _M0FP36mizchi7syntree4rust11is__keyword(word) ? 0 : _M0FP36mizchi7syntree4rust17is__builtin__type(word) ? 7 : first_char >= 65 && first_char <= 90 ? 7 : 6;
        }
      }
      break _L;
    }
    token_type = 5;
  }
  return new _M0TP36mizchi7syntree4rust9RustToken(token_type, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer19read__line__comment(self) {
  const start = self.pos;
  if ((self.pos + 2 | 0) < self.len) {
    const third = _M0MPC15array5Array2atGcE(self.chars, self.pos + 2 | 0);
    if (third === 47 || third === 33) {
      self.pos = self.pos + 3 | 0;
      while (true) {
        if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return new _M0TP36mizchi7syntree4rust9RustToken(26, start, self.pos);
    }
  }
  self.pos = self.pos + 2 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4rust9RustToken(24, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer20read__block__comment(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  let depth = 1;
  while (true) {
    if ((self.pos + 1 | 0) < self.len && depth > 0) {
      if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 47 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 42) {
        depth = depth + 1 | 0;
        self.pos = self.pos + 2 | 0;
      } else {
        if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 42 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 47) {
          depth = depth - 1 | 0;
          self.pos = self.pos + 2 | 0;
        } else {
          self.pos = self.pos + 1 | 0;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree4rust9RustToken(25, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer15read__attribute(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 33) {
    self.pos = self.pos + 1 | 0;
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 91) {
    self.pos = self.pos + 1 | 0;
    let depth = 1;
    while (true) {
      if (self.pos < self.len && depth > 0) {
        const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (c === 91) {
          depth = depth + 1 | 0;
        } else {
          if (c === 93) {
            depth = depth - 1 | 0;
          }
        }
        self.pos = self.pos + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  return new _M0TP36mizchi7syntree4rust9RustToken(10, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer14read__operator(self) {
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  if (c === 45 && ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 62)) {
    self.pos = self.pos + 2 | 0;
    return new _M0TP36mizchi7syntree4rust9RustToken(12, start, self.pos);
  }
  if (c === 61 && ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 62)) {
    self.pos = self.pos + 2 | 0;
    return new _M0TP36mizchi7syntree4rust9RustToken(12, start, self.pos);
  }
  if ((self.pos + 2 | 0) < self.len) {
    const c2 = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    const c3 = _M0MPC15array5Array2atGcE(self.chars, self.pos + 2 | 0);
    if (c === 60 && (c2 === 60 && c3 === 61) || (c === 62 && (c2 === 62 && c3 === 61) || (c === 46 && (c2 === 46 && c3 === 61) || c === 46 && (c2 === 46 && c3 === 46)))) {
      self.pos = self.pos + 3 | 0;
      return new _M0TP36mizchi7syntree4rust9RustToken(11, start, self.pos);
    }
  }
  if ((self.pos + 1 | 0) < self.len) {
    const c2 = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    if (c === 61 && c2 === 61 || (c === 33 && c2 === 61 || (c === 60 && c2 === 61 || (c === 62 && c2 === 61 || (c === 43 && c2 === 61 || (c === 45 && c2 === 61 || (c === 42 && c2 === 61 || (c === 47 && c2 === 61 || (c === 37 && c2 === 61 || (c === 38 && c2 === 38 || (c === 124 && c2 === 124 || (c === 38 && c2 === 61 || (c === 124 && c2 === 61 || (c === 94 && c2 === 61 || (c === 60 && c2 === 60 || (c === 62 && c2 === 62 || c === 46 && c2 === 46)))))))))))))))) {
      self.pos = self.pos + 2 | 0;
      return new _M0TP36mizchi7syntree4rust9RustToken(11, start, self.pos);
    }
  }
  self.pos = self.pos + 1 | 0;
  return new _M0TP36mizchi7syntree4rust9RustToken(11, start, self.pos);
}
function _M0MP36mizchi7syntree4rust13RustTokenizer11next__token(self) {
  _M0MP36mizchi7syntree4rust13RustTokenizer16skip__whitespace(self);
  if (self.pos >= self.len) {
    return undefined;
  }
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  if (c === 47 && (self.pos + 1 | 0) < self.len) {
    const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    if (next === 47) {
      return _M0MP36mizchi7syntree4rust13RustTokenizer19read__line__comment(self);
    } else {
      if (next === 42) {
        return _M0MP36mizchi7syntree4rust13RustTokenizer20read__block__comment(self);
      }
    }
  }
  if (c === 35) {
    return _M0MP36mizchi7syntree4rust13RustTokenizer15read__attribute(self);
  }
  if (c === 114 && (self.pos + 1 | 0) < self.len) {
    const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    if (next === 34 || next === 35) {
      return _M0MP36mizchi7syntree4rust13RustTokenizer12read__string(self);
    }
  }
  if (c === 98 && (self.pos + 1 | 0) < self.len) {
    const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    if (next === 34) {
      self.pos = self.pos + 1 | 0;
      return _M0MP36mizchi7syntree4rust13RustTokenizer12read__string(self);
    } else {
      if (next === 39) {
        self.pos = self.pos + 1 | 0;
        return _M0MP36mizchi7syntree4rust13RustTokenizer10read__char(self);
      }
    }
  }
  let token;
  _L: {
    _L$2: {
      _L$3: {
        _L$4: {
          switch (c) {
            case 34: {
              token = _M0MP36mizchi7syntree4rust13RustTokenizer12read__string(self);
              break;
            }
            case 39: {
              token = _M0MP36mizchi7syntree4rust13RustTokenizer10read__char(self);
              break;
            }
            case 48: {
              break _L$4;
            }
            case 49: {
              break _L$4;
            }
            case 50: {
              break _L$4;
            }
            case 51: {
              break _L$4;
            }
            case 52: {
              break _L$4;
            }
            case 53: {
              break _L$4;
            }
            case 54: {
              break _L$4;
            }
            case 55: {
              break _L$4;
            }
            case 56: {
              break _L$4;
            }
            case 57: {
              break _L$4;
            }
            default: {
              if (_M0FP36mizchi7syntree4rust16is__ident__start(c)) {
                token = _M0MP36mizchi7syntree4rust13RustTokenizer16read__identifier(self);
              } else {
                switch (c) {
                  case 123: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(13, start, self.pos);
                    break;
                  }
                  case 125: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(14, start, self.pos);
                    break;
                  }
                  case 91: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(15, start, self.pos);
                    break;
                  }
                  case 93: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(16, start, self.pos);
                    break;
                  }
                  case 40: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(17, start, self.pos);
                    break;
                  }
                  case 41: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(18, start, self.pos);
                    break;
                  }
                  case 59: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(19, start, self.pos);
                    break;
                  }
                  case 44: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(20, start, self.pos);
                    break;
                  }
                  case 58: {
                    if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 58) {
                      self.pos = self.pos + 2 | 0;
                      token = new _M0TP36mizchi7syntree4rust9RustToken(23, start, self.pos);
                    } else {
                      self.pos = self.pos + 1 | 0;
                      token = new _M0TP36mizchi7syntree4rust9RustToken(22, start, self.pos);
                    }
                    break;
                  }
                  case 46: {
                    if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 46) {
                      token = _M0MP36mizchi7syntree4rust13RustTokenizer14read__operator(self);
                    } else {
                      self.pos = self.pos + 1 | 0;
                      token = new _M0TP36mizchi7syntree4rust9RustToken(21, start, self.pos);
                    }
                    break;
                  }
                  case 43: {
                    break _L$2;
                  }
                  case 45: {
                    break _L$2;
                  }
                  case 42: {
                    break _L$2;
                  }
                  case 47: {
                    break _L$2;
                  }
                  case 37: {
                    break _L$2;
                  }
                  case 61: {
                    break _L$2;
                  }
                  case 33: {
                    break _L$2;
                  }
                  case 60: {
                    break _L$2;
                  }
                  case 62: {
                    break _L$2;
                  }
                  case 38: {
                    break _L$2;
                  }
                  case 124: {
                    break _L$2;
                  }
                  case 94: {
                    break _L$2;
                  }
                  case 126: {
                    break _L$2;
                  }
                  case 63: {
                    break _L$2;
                  }
                  case 64: {
                    break _L$2;
                  }
                  default: {
                    self.pos = self.pos + 1 | 0;
                    token = new _M0TP36mizchi7syntree4rust9RustToken(27, start, self.pos);
                  }
                }
              }
            }
          }
          break _L$3;
        }
        token = _M0MP36mizchi7syntree4rust13RustTokenizer12read__number(self);
      }
      break _L;
    }
    token = _M0MP36mizchi7syntree4rust13RustTokenizer14read__operator(self);
  }
  return token;
}
function _M0MP36mizchi7syntree4rust13RustTokenizer13tokenize__all(self) {
  const tokens = [];
  while (true) {
    const _bind = _M0MP36mizchi7syntree4rust13RustTokenizer11next__token(self);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _token = _Some;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _token);
    }
    continue;
  }
  return tokens;
}
function _M0FP36mizchi7syntree4rust17rust__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Keyword", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ControlFlow", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "String", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Char", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Number", 4);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Bool", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Identifier", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TypeName", 11);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Lifetime", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Macro", 10);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Attribute", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Operator", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Arrow", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceOpen", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceClose", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketOpen", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketClose", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenOpen", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenClose", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Semicolon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comma", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Dot", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Colon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ColonColon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "LineComment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BlockComment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "DocComment", 19);
  return h;
}
function _M0FP36mizchi7syntree4rust17token__type__name(t) {
  switch (t) {
    case 0: {
      return "Keyword";
    }
    case 1: {
      return "ControlFlow";
    }
    case 2: {
      return "String";
    }
    case 3: {
      return "Char";
    }
    case 4: {
      return "Number";
    }
    case 5: {
      return "Bool";
    }
    case 6: {
      return "Identifier";
    }
    case 7: {
      return "TypeName";
    }
    case 8: {
      return "Lifetime";
    }
    case 9: {
      return "Macro";
    }
    case 10: {
      return "Attribute";
    }
    case 11: {
      return "Operator";
    }
    case 12: {
      return "Arrow";
    }
    case 13: {
      return "BraceOpen";
    }
    case 14: {
      return "BraceClose";
    }
    case 15: {
      return "BracketOpen";
    }
    case 16: {
      return "BracketClose";
    }
    case 17: {
      return "ParenOpen";
    }
    case 18: {
      return "ParenClose";
    }
    case 19: {
      return "Semicolon";
    }
    case 20: {
      return "Comma";
    }
    case 21: {
      return "Dot";
    }
    case 22: {
      return "Colon";
    }
    case 23: {
      return "ColonColon";
    }
    case 24: {
      return "LineComment";
    }
    case 25: {
      return "BlockComment";
    }
    case 26: {
      return "DocComment";
    }
    default: {
      return "Error";
    }
  }
}
function _M0FP36mizchi7syntree4rust15highlight__rust(source) {
  const tokenizer = _M0MP36mizchi7syntree4rust13RustTokenizer3new(source);
  const tokens = _M0MP36mizchi7syntree4rust13RustTokenizer13tokenize__all(tokenizer);
  const highlighter = _M0FP36mizchi7syntree4rust17rust__highlighter();
  const result = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const name = _M0FP36mizchi7syntree4rust17token__type__name(token.token_type);
      const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(highlighter, name);
      if (_M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(tag, 23)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(result, _M0MP26mizchi7syntree14HighlightToken3new(token.from, token.to, tag));
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0IP36mizchi7syntree10typescript9TsContextPB2Eq5equal(_x_227, _x_228) {
  switch (_x_227) {
    case 0: {
      if (_x_228 === 0) {
        return true;
      } else {
        return false;
      }
    }
    case 1: {
      if (_x_228 === 1) {
        return true;
      } else {
        return false;
      }
    }
    case 2: {
      if (_x_228 === 2) {
        return true;
      } else {
        return false;
      }
    }
    case 3: {
      if (_x_228 === 3) {
        return true;
      } else {
        return false;
      }
    }
    case 4: {
      if (_x_228 === 4) {
        return true;
      } else {
        return false;
      }
    }
    case 5: {
      if (_x_228 === 5) {
        return true;
      } else {
        return false;
      }
    }
    default: {
      if (_x_228 === 6) {
        return true;
      } else {
        return false;
      }
    }
  }
}
function _M0FP36mizchi7syntree10typescript11is__keyword(word) {
  switch (word) {
    case "if": {
      return true;
    }
    case "else": {
      return true;
    }
    case "switch": {
      return true;
    }
    case "case": {
      return true;
    }
    case "for": {
      return true;
    }
    case "while": {
      return true;
    }
    case "do": {
      return true;
    }
    case "break": {
      return true;
    }
    case "continue": {
      return true;
    }
    case "return": {
      return true;
    }
    case "throw": {
      return true;
    }
    case "try": {
      return true;
    }
    case "catch": {
      return true;
    }
    case "finally": {
      return true;
    }
    case "function": {
      return true;
    }
    case "class": {
      return true;
    }
    case "const": {
      return true;
    }
    case "let": {
      return true;
    }
    case "var": {
      return true;
    }
    case "import": {
      return true;
    }
    case "export": {
      return true;
    }
    case "from": {
      return true;
    }
    case "as": {
      return true;
    }
    case "interface": {
      return true;
    }
    case "type": {
      return true;
    }
    case "enum": {
      return true;
    }
    case "namespace": {
      return true;
    }
    case "module": {
      return true;
    }
    case "declare": {
      return true;
    }
    case "abstract": {
      return true;
    }
    case "implements": {
      return true;
    }
    case "extends": {
      return true;
    }
    case "public": {
      return true;
    }
    case "private": {
      return true;
    }
    case "protected": {
      return true;
    }
    case "readonly": {
      return true;
    }
    case "static": {
      return true;
    }
    case "override": {
      return true;
    }
    case "keyof": {
      return true;
    }
    case "infer": {
      return true;
    }
    case "async": {
      return true;
    }
    case "await": {
      return true;
    }
    case "yield": {
      return true;
    }
    case "new": {
      return true;
    }
    case "this": {
      return true;
    }
    case "super": {
      return true;
    }
    case "typeof": {
      return true;
    }
    case "instanceof": {
      return true;
    }
    case "in": {
      return true;
    }
    case "of": {
      return true;
    }
    case "void": {
      return true;
    }
    case "delete": {
      return true;
    }
    case "with": {
      return true;
    }
    case "debugger": {
      return true;
    }
    case "default": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0FP36mizchi7syntree10typescript17is__builtin__type(word) {
  switch (word) {
    case "string": {
      return true;
    }
    case "number": {
      return true;
    }
    case "boolean": {
      return true;
    }
    case "bigint": {
      return true;
    }
    case "symbol": {
      return true;
    }
    case "any": {
      return true;
    }
    case "unknown": {
      return true;
    }
    case "never": {
      return true;
    }
    case "object": {
      return true;
    }
    case "Array": {
      return true;
    }
    case "Map": {
      return true;
    }
    case "Set": {
      return true;
    }
    case "WeakMap": {
      return true;
    }
    case "WeakSet": {
      return true;
    }
    case "Promise": {
      return true;
    }
    case "Record": {
      return true;
    }
    case "Partial": {
      return true;
    }
    case "Required": {
      return true;
    }
    case "Readonly": {
      return true;
    }
    case "Pick": {
      return true;
    }
    case "Omit": {
      return true;
    }
    case "Exclude": {
      return true;
    }
    case "Extract": {
      return true;
    }
    case "NonNullable": {
      return true;
    }
    case "ReturnType": {
      return true;
    }
    case "InstanceType": {
      return true;
    }
    case "Parameters": {
      return true;
    }
    case "ConstructorParameters": {
      return true;
    }
    case "ThisType": {
      return true;
    }
    case "Awaited": {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer3new(input) {
  const chars = _M0MPC16string6String9to__array(input);
  return new _M0TP36mizchi7syntree10typescript11TsTokenizer(input, chars, chars.length, 0, [0], undefined);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer7context(self) {
  return self.context_stack.length > 0 ? _M0MPC15array5Array2atGRP36mizchi7syntree10typescript9TsContextE(self.context_stack, self.context_stack.length - 1 | 0) : 0;
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, ctx) {
  _M0MPC15array5Array4pushGRP36mizchi7syntree10typescript9TsContextE(self.context_stack, ctx);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self) {
  if (self.context_stack.length > 1) {
    _M0MPC15array5Array3popGRP36mizchi7syntree10typescript9TsContextE(self.context_stack);
    return;
  } else {
    return;
  }
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self) {
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 32 || (c === 9 || (c === 10 || c === 13))) {
        self.pos = self.pos + 1 | 0;
      } else {
        return;
      }
      continue;
    } else {
      return;
    }
  }
}
function _M0FP36mizchi7syntree10typescript14is__hex__digit(c) {
  return c >= 48 && c <= 57 || (c >= 97 && c <= 102 || c >= 65 && c <= 70);
}
function _M0FP36mizchi7syntree10typescript16is__ident__start(c) {
  return c >= 97 && c <= 122 || (c >= 65 && c <= 90 || (c === 95 || c === 36));
}
function _M0FP36mizchi7syntree10typescript15is__ident__part(c) {
  return _M0FP36mizchi7syntree10typescript16is__ident__start(c) || c >= 48 && c <= 57;
}
function _M0FP36mizchi7syntree10typescript19is__jsx__name__part(c) {
  return _M0FP36mizchi7syntree10typescript15is__ident__part(c) || (c === 45 || c === 46);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer12read__string(self, quote) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === quote) {
        self.pos = self.pos + 1 | 0;
        break;
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          if (c === 10 && quote !== 96) {
            break;
          } else {
            self.pos = self.pos + 1 | 0;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(1, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer23read__template__literal(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 96) {
        self.pos = self.pos + 1 | 0;
        return new _M0TP36mizchi7syntree10typescript7TsToken(11, start, self.pos);
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          if (c === 36 && ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 123)) {
            self.pos = self.pos + 2 | 0;
            _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 6);
            return new _M0TP36mizchi7syntree10typescript7TsToken(8, start, self.pos);
          } else {
            self.pos = self.pos + 1 | 0;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(11, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer28read__template__continuation(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 96) {
        self.pos = self.pos + 1 | 0;
        return new _M0TP36mizchi7syntree10typescript7TsToken(10, start, self.pos);
      } else {
        if (c === 92 && (self.pos + 1 | 0) < self.len) {
          self.pos = self.pos + 2 | 0;
        } else {
          if (c === 36 && ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 123)) {
            self.pos = self.pos + 2 | 0;
            _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 6);
            return new _M0TP36mizchi7syntree10typescript7TsToken(9, start, self.pos);
          } else {
            self.pos = self.pos + 1 | 0;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(10, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer15read__decorator(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (_M0FP36mizchi7syntree10typescript15is__ident__part(c) || c === 46) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(15, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer20read__private__field(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree10typescript15is__ident__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(13, start, self.pos);
}
function _M0FP36mizchi7syntree10typescript18is__digit__or__sep(c) {
  return c >= 48 && c <= 57 || c === 95;
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer12read__number(self) {
  const start = self.pos;
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 48) {
    if ((self.pos + 1 | 0) < self.len) {
      const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      if (next === 120 || next === 88) {
        self.pos = self.pos + 2 | 0;
        while (true) {
          if (self.pos < self.len) {
            const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
            if (_M0FP36mizchi7syntree10typescript14is__hex__digit(c) || c === 95) {
              self.pos = self.pos + 1 | 0;
            } else {
              break;
            }
            continue;
          } else {
            break;
          }
        }
        return new _M0TP36mizchi7syntree10typescript7TsToken(2, start, self.pos);
      } else {
        if (next === 98 || next === 66) {
          self.pos = self.pos + 2 | 0;
          while (true) {
            if (self.pos < self.len) {
              const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
              if (c === 48 || (c === 49 || c === 95)) {
                self.pos = self.pos + 1 | 0;
              } else {
                break;
              }
              continue;
            } else {
              break;
            }
          }
          return new _M0TP36mizchi7syntree10typescript7TsToken(2, start, self.pos);
        } else {
          if (next === 111 || next === 79) {
            self.pos = self.pos + 2 | 0;
            while (true) {
              if (self.pos < self.len) {
                const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
                if (c >= 48 && c <= 55 || c === 95) {
                  self.pos = self.pos + 1 | 0;
                } else {
                  break;
                }
                continue;
              } else {
                break;
              }
            }
            return new _M0TP36mizchi7syntree10typescript7TsToken(2, start, self.pos);
          }
        }
      }
    }
  }
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree10typescript18is__digit__or__sep(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 46) {
    let _tmp;
    if ((self.pos + 1 | 0) < self.len) {
      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      _tmp = _p >= 48 && _p <= 57;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      self.pos = self.pos + 1 | 0;
      while (true) {
        if (self.pos < self.len && _M0FP36mizchi7syntree10typescript18is__digit__or__sep(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  if (self.pos < self.len) {
    const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
    if (c === 101 || c === 69) {
      self.pos = self.pos + 1 | 0;
      if (self.pos < self.len) {
        const sign = _M0MPC15array5Array2atGcE(self.chars, self.pos);
        if (sign === 43 || sign === 45) {
          self.pos = self.pos + 1 | 0;
        }
      }
      while (true) {
        if (self.pos < self.len && _M0FP36mizchi7syntree10typescript18is__digit__or__sep(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
          self.pos = self.pos + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    }
  }
  if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) === 110) {
    self.pos = self.pos + 1 | 0;
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(2, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer16read__identifier(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree10typescript15is__ident__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const word = self.input.substring(start, self.pos);
  let token_type;
  switch (word) {
    case "true": {
      token_type = 4;
      break;
    }
    case "false": {
      token_type = 5;
      break;
    }
    case "null": {
      token_type = 6;
      break;
    }
    case "undefined": {
      token_type = 7;
      break;
    }
    default: {
      token_type = _M0FP36mizchi7syntree10typescript11is__keyword(word) ? 0 : _M0FP36mizchi7syntree10typescript17is__builtin__type(word) ? 14 : 12;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(token_type, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer19read__line__comment(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  while (true) {
    if (self.pos < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos) !== 10) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(28, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer20read__block__comment(self) {
  const start = self.pos;
  self.pos = self.pos + 2 | 0;
  while (true) {
    if ((self.pos + 1 | 0) < self.len) {
      if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 42 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 47) {
        self.pos = self.pos + 2 | 0;
        break;
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(29, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer14expects__regex(self) {
  const _bind = self.last_token;
  if (_bind === undefined) {
    return true;
  } else {
    const _Some = _bind;
    const _t = _Some;
    switch (_t) {
      case 22: {
        return true;
      }
      case 20: {
        return true;
      }
      case 18: {
        return true;
      }
      case 25: {
        return true;
      }
      case 24: {
        return true;
      }
      case 27: {
        return true;
      }
      case 16: {
        return true;
      }
      case 0: {
        return true;
      }
      case 37: {
        return true;
      }
      case 12: {
        return false;
      }
      case 2: {
        return false;
      }
      case 1: {
        return false;
      }
      case 3: {
        return false;
      }
      case 23: {
        return false;
      }
      case 21: {
        return false;
      }
      case 4: {
        return false;
      }
      case 5: {
        return false;
      }
      case 6: {
        return false;
      }
      case 7: {
        return false;
      }
      default: {
        return true;
      }
    }
  }
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer11read__regex(self) {
  const start = self.pos;
  self.pos = self.pos + 1 | 0;
  let in_class = false;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 92 && (self.pos + 1 | 0) < self.len) {
        self.pos = self.pos + 2 | 0;
      } else {
        if (c === 91 && !in_class) {
          in_class = true;
          self.pos = self.pos + 1 | 0;
        } else {
          if (c === 93 && in_class) {
            in_class = false;
            self.pos = self.pos + 1 | 0;
          } else {
            if (c === 47 && !in_class) {
              self.pos = self.pos + 1 | 0;
              break;
            } else {
              if (c === 10) {
                break;
              } else {
                self.pos = self.pos + 1 | 0;
              }
            }
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 103 || (c === 105 || (c === 109 || (c === 115 || (c === 117 || (c === 121 || c === 100)))))) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(3, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer14read__operator(self) {
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  if ((self.pos + 2 | 0) < self.len) {
    const c2 = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    const c3 = _M0MPC15array5Array2atGcE(self.chars, self.pos + 2 | 0);
    if (c === 61 && (c2 === 61 && c3 === 61) || (c === 33 && (c2 === 61 && c3 === 61) || (c === 46 && (c2 === 46 && c3 === 46) || (c === 60 && (c2 === 60 && c3 === 61) || (c === 62 && (c2 === 62 && c3 === 61) || (c === 62 && (c2 === 62 && c3 === 62) || (c === 63 && (c2 === 63 && c3 === 61) || (c === 38 && (c2 === 38 && c3 === 61) || c === 124 && (c2 === 124 && c3 === 61))))))))) {
      self.pos = self.pos + 3 | 0;
      return new _M0TP36mizchi7syntree10typescript7TsToken(16, start, self.pos);
    }
  }
  if ((self.pos + 1 | 0) < self.len) {
    const c2 = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    if (c === 61 && c2 === 61 || (c === 33 && c2 === 61 || (c === 60 && c2 === 61 || (c === 62 && c2 === 61 || (c === 43 && c2 === 43 || (c === 45 && c2 === 45 || (c === 43 && c2 === 61 || (c === 45 && c2 === 61 || (c === 42 && c2 === 61 || (c === 47 && c2 === 61 || (c === 37 && c2 === 61 || (c === 38 && c2 === 38 || (c === 124 && c2 === 124 || (c === 63 && c2 === 63 || (c === 63 && c2 === 46 || (c === 61 && c2 === 62 || (c === 60 && c2 === 60 || (c === 62 && c2 === 62 || (c === 42 && c2 === 42 || (c === 38 && c2 === 61 || (c === 124 && c2 === 61 || c === 94 && c2 === 61))))))))))))))))))))) {
      self.pos = self.pos + 2 | 0;
      return new _M0TP36mizchi7syntree10typescript7TsToken(16, start, self.pos);
    }
  }
  self.pos = self.pos + 1 | 0;
  return new _M0TP36mizchi7syntree10typescript7TsToken(16, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer16is__jsx__context(self) {
  const _bind = self.last_token;
  if (_bind === undefined) {
    return true;
  } else {
    const _Some = _bind;
    const _x = _Some;
    switch (_x) {
      case 22: {
        return true;
      }
      case 18: {
        return true;
      }
      case 20: {
        return true;
      }
      case 25: {
        return true;
      }
      case 27: {
        return true;
      }
      case 24: {
        return true;
      }
      case 16: {
        return true;
      }
      case 0: {
        return true;
      }
      case 31: {
        return true;
      }
      case 38: {
        return true;
      }
      default: {
        return false;
      }
    }
  }
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer20read__jsx__tag__name(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree10typescript19is__jsx__name__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(33, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer20read__jsx__attribute(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len && _M0FP36mizchi7syntree10typescript19is__jsx__name__part(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(34, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer15read__jsx__text(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (c === 60 || c === 123) {
        break;
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new _M0TP36mizchi7syntree10typescript7TsToken(36, start, self.pos);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer25next__jsx__element__token(self) {
  _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self);
  if (self.pos >= self.len) {
    return undefined;
  }
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  _L: {
    switch (c) {
      case 47: {
        if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 62) {
          self.pos = self.pos + 2 | 0;
          _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
          return new _M0TP36mizchi7syntree10typescript7TsToken(31, start, self.pos);
        } else {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree10typescript7TsToken(16, start, self.pos);
        }
      }
      case 62: {
        self.pos = self.pos + 1 | 0;
        _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
        _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 3);
        return new _M0TP36mizchi7syntree10typescript7TsToken(31, start, self.pos);
      }
      case 61: {
        self.pos = self.pos + 1 | 0;
        return new _M0TP36mizchi7syntree10typescript7TsToken(35, start, self.pos);
      }
      case 34: {
        break _L;
      }
      case 39: {
        break _L;
      }
      case 123: {
        self.pos = self.pos + 1 | 0;
        _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 5);
        return new _M0TP36mizchi7syntree10typescript7TsToken(37, start, self.pos);
      }
      default: {
        if (_M0FP36mizchi7syntree10typescript16is__ident__start(c)) {
          return _M0MP36mizchi7syntree10typescript11TsTokenizer20read__jsx__attribute(self);
        } else {
          self.pos = self.pos + 1 | 0;
          return new _M0TP36mizchi7syntree10typescript7TsToken(39, start, self.pos);
        }
      }
    }
  }
  return _M0MP36mizchi7syntree10typescript11TsTokenizer12read__string(self, c);
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer26next__jsx__children__token(self) {
  if (self.pos >= self.len) {
    return undefined;
  }
  const start = self.pos;
  const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  switch (c) {
    case 60: {
      if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 47) {
        self.pos = self.pos + 2 | 0;
        _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
        _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 4);
        return new _M0TP36mizchi7syntree10typescript7TsToken(32, start, self.pos);
      } else {
        self.pos = self.pos + 1 | 0;
        _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 1);
        return new _M0TP36mizchi7syntree10typescript7TsToken(30, start, self.pos);
      }
    }
    case 123: {
      self.pos = self.pos + 1 | 0;
      _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 5);
      return new _M0TP36mizchi7syntree10typescript7TsToken(37, start, self.pos);
    }
    default: {
      return _M0MP36mizchi7syntree10typescript11TsTokenizer15read__jsx__text(self);
    }
  }
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer11next__token(self) {
  const _bind = _M0MP36mizchi7syntree10typescript11TsTokenizer7context(self);
  switch (_bind) {
    case 1: {
      _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self);
      if (self.pos >= self.len) {
        return undefined;
      }
      if (_M0FP36mizchi7syntree10typescript16is__ident__start(_M0MPC15array5Array2atGcE(self.chars, self.pos))) {
        const token = _M0MP36mizchi7syntree10typescript11TsTokenizer20read__jsx__tag__name(self);
        _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
        _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 2);
        self.last_token = token.token_type;
        return token;
      }
      _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
      break;
    }
    case 2: {
      const token = _M0MP36mizchi7syntree10typescript11TsTokenizer25next__jsx__element__token(self);
      if (token === undefined) {
      } else {
        const _Some = token;
        const _t = _Some;
        self.last_token = _t.token_type;
      }
      return token;
    }
    case 3: {
      const token$2 = _M0MP36mizchi7syntree10typescript11TsTokenizer26next__jsx__children__token(self);
      if (token$2 === undefined) {
      } else {
        const _Some = token$2;
        const _t = _Some;
        self.last_token = _t.token_type;
      }
      return token$2;
    }
    case 4: {
      _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self);
      if (self.pos >= self.len) {
        return undefined;
      }
      const c = _M0MPC15array5Array2atGcE(self.chars, self.pos);
      if (_M0FP36mizchi7syntree10typescript16is__ident__start(c)) {
        const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer20read__jsx__tag__name(self);
        self.last_token = token$3.token_type;
        return token$3;
      } else {
        if (c === 62) {
          const start = self.pos;
          self.pos = self.pos + 1 | 0;
          _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
          self.last_token = _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1179;
          return new _M0TP36mizchi7syntree10typescript7TsToken(31, start, self.pos);
        }
      }
      _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
      break;
    }
    case 5: {
      _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self);
      if (self.pos >= self.len) {
        return undefined;
      }
      if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 125) {
        const start = self.pos;
        self.pos = self.pos + 1 | 0;
        _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
        self.last_token = _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1180;
        return new _M0TP36mizchi7syntree10typescript7TsToken(38, start, self.pos);
      }
      break;
    }
    case 6: {
      _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self);
      if (self.pos >= self.len) {
        return undefined;
      }
      if (_M0MPC15array5Array2atGcE(self.chars, self.pos) === 125) {
        _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
        const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer28read__template__continuation(self);
        self.last_token = token$3.token_type;
        return token$3;
      }
      break;
    }
  }
  _M0MP36mizchi7syntree10typescript11TsTokenizer16skip__whitespace(self);
  if (self.pos >= self.len) {
    return undefined;
  }
  const start = self.pos;
  const c$2 = _M0MPC15array5Array2atGcE(self.chars, self.pos);
  if (c$2 === 47 && (self.pos + 1 | 0) < self.len) {
    const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
    if (next === 47) {
      const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer19read__line__comment(self);
      self.last_token = token$3.token_type;
      return token$3;
    } else {
      if (next === 42) {
        const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer20read__block__comment(self);
        self.last_token = token$3.token_type;
        return token$3;
      } else {
        if (_M0MP36mizchi7syntree10typescript11TsTokenizer14expects__regex(self)) {
          const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer11read__regex(self);
          self.last_token = token$3.token_type;
          return token$3;
        }
      }
    }
  } else {
    if (c$2 === 47 && _M0MP36mizchi7syntree10typescript11TsTokenizer14expects__regex(self)) {
      const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer11read__regex(self);
      self.last_token = token$3.token_type;
      return token$3;
    }
  }
  if (c$2 === 60) {
    if ((self.pos + 1 | 0) < self.len && _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 47) {
      self.pos = self.pos + 2 | 0;
      _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 4);
      self.last_token = _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1181;
      return new _M0TP36mizchi7syntree10typescript7TsToken(32, start, self.pos);
    }
    if (_M0MP36mizchi7syntree10typescript11TsTokenizer16is__jsx__context(self) && (self.pos + 1 | 0) < self.len) {
      const next = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
      if (_M0FP36mizchi7syntree10typescript16is__ident__start(next) || next === 62) {
        self.pos = self.pos + 1 | 0;
        _M0MP36mizchi7syntree10typescript11TsTokenizer13push__context(self, 1);
        self.last_token = _M0FP36mizchi7syntree10typescript27next__token_2econstr_2f1182;
        return new _M0TP36mizchi7syntree10typescript7TsToken(30, start, self.pos);
      }
    }
  }
  if (c$2 === 64) {
    const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer15read__decorator(self);
    self.last_token = token$3.token_type;
    return token$3;
  }
  if (c$2 === 35) {
    const token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer20read__private__field(self);
    self.last_token = token$3.token_type;
    return token$3;
  }
  let token$3;
  _L: {
    _L$2: {
      _L$3: {
        _L$4: {
          _L$5: {
            _L$6: {
              switch (c$2) {
                case 34: {
                  break _L$6;
                }
                case 39: {
                  break _L$6;
                }
                case 96: {
                  token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer23read__template__literal(self);
                  break;
                }
                case 123: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(18, start, self.pos);
                  break;
                }
                case 125: {
                  self.pos = self.pos + 1 | 0;
                  if (_M0IP36mizchi7syntree10typescript9TsContextPB2Eq5equal(_M0MP36mizchi7syntree10typescript11TsTokenizer7context(self), 5)) {
                    _M0MP36mizchi7syntree10typescript11TsTokenizer12pop__context(self);
                    token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(38, start, self.pos);
                  } else {
                    token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(19, start, self.pos);
                  }
                  break;
                }
                case 91: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(20, start, self.pos);
                  break;
                }
                case 93: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(21, start, self.pos);
                  break;
                }
                case 40: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(22, start, self.pos);
                  break;
                }
                case 41: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(23, start, self.pos);
                  break;
                }
                case 59: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(24, start, self.pos);
                  break;
                }
                case 44: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(25, start, self.pos);
                  break;
                }
                case 58: {
                  self.pos = self.pos + 1 | 0;
                  token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(27, start, self.pos);
                  break;
                }
                case 46: {
                  if ((self.pos + 2 | 0) < self.len && (_M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0) === 46 && _M0MPC15array5Array2atGcE(self.chars, self.pos + 2 | 0) === 46)) {
                    self.pos = self.pos + 3 | 0;
                    token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(17, start, self.pos);
                  } else {
                    let _tmp;
                    if ((self.pos + 1 | 0) < self.len) {
                      const _p = _M0MPC15array5Array2atGcE(self.chars, self.pos + 1 | 0);
                      _tmp = _p >= 48 && _p <= 57;
                    } else {
                      _tmp = false;
                    }
                    if (_tmp) {
                      token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer12read__number(self);
                    } else {
                      self.pos = self.pos + 1 | 0;
                      token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(26, start, self.pos);
                    }
                  }
                  break;
                }
                case 48: {
                  break _L$4;
                }
                case 49: {
                  break _L$4;
                }
                case 50: {
                  break _L$4;
                }
                case 51: {
                  break _L$4;
                }
                case 52: {
                  break _L$4;
                }
                case 53: {
                  break _L$4;
                }
                case 54: {
                  break _L$4;
                }
                case 55: {
                  break _L$4;
                }
                case 56: {
                  break _L$4;
                }
                case 57: {
                  break _L$4;
                }
                default: {
                  if (_M0FP36mizchi7syntree10typescript16is__ident__start(c$2)) {
                    token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer16read__identifier(self);
                  } else {
                    switch (c$2) {
                      case 43: {
                        break _L$2;
                      }
                      case 45: {
                        break _L$2;
                      }
                      case 42: {
                        break _L$2;
                      }
                      case 47: {
                        break _L$2;
                      }
                      case 37: {
                        break _L$2;
                      }
                      case 61: {
                        break _L$2;
                      }
                      case 33: {
                        break _L$2;
                      }
                      case 60: {
                        break _L$2;
                      }
                      case 62: {
                        break _L$2;
                      }
                      case 38: {
                        break _L$2;
                      }
                      case 124: {
                        break _L$2;
                      }
                      case 94: {
                        break _L$2;
                      }
                      case 126: {
                        break _L$2;
                      }
                      case 63: {
                        break _L$2;
                      }
                      default: {
                        self.pos = self.pos + 1 | 0;
                        token$3 = new _M0TP36mizchi7syntree10typescript7TsToken(39, start, self.pos);
                      }
                    }
                  }
                }
              }
              break _L$5;
            }
            token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer12read__string(self, c$2);
          }
          break _L$3;
        }
        token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer12read__number(self);
      }
      break _L;
    }
    token$3 = _M0MP36mizchi7syntree10typescript11TsTokenizer14read__operator(self);
  }
  self.last_token = token$3.token_type;
  return token$3;
}
function _M0MP36mizchi7syntree10typescript11TsTokenizer13tokenize__all(self) {
  const tokens = [];
  while (true) {
    const _bind = _M0MP36mizchi7syntree10typescript11TsTokenizer11next__token(self);
    if (_bind === undefined) {
      break;
    } else {
      const _Some = _bind;
      const _token = _Some;
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(tokens, _token);
    }
    continue;
  }
  return tokens;
}
function _M0FP36mizchi7syntree10typescript15ts__highlighter() {
  const h = _M0MP26mizchi7syntree11Highlighter3new();
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Keyword", 0);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "String", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Number", 4);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Regex", 5);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TemplateString", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TemplateHead", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TemplateMiddle", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TemplateTail", 3);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "True", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "False", 6);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Null", 7);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Undefined", 7);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Identifier", 9);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "PrivateId", 13);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "TypeName", 11);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Decorator", 14);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Operator", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Spread", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceOpen", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BraceClose", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketOpen", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BracketClose", 15);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenOpen", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "ParenClose", 17);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Semicolon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Comma", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Dot", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "Colon", 2);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "LineComment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "BlockComment", 18);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxTagOpen", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxTagClose", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxCloseTag", 21);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxTagName", 20);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxAttribute", 8);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxEquals", 1);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxText", 23);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxExprStart", 16);
  _M0MP26mizchi7syntree11Highlighter9add__rule(h, "JsxExprEnd", 16);
  return h;
}
function _M0FP36mizchi7syntree10typescript17token__type__name(t) {
  switch (t) {
    case 0: {
      return "Keyword";
    }
    case 1: {
      return "String";
    }
    case 2: {
      return "Number";
    }
    case 3: {
      return "Regex";
    }
    case 11: {
      return "TemplateString";
    }
    case 8: {
      return "TemplateHead";
    }
    case 9: {
      return "TemplateMiddle";
    }
    case 10: {
      return "TemplateTail";
    }
    case 4: {
      return "True";
    }
    case 5: {
      return "False";
    }
    case 6: {
      return "Null";
    }
    case 7: {
      return "Undefined";
    }
    case 12: {
      return "Identifier";
    }
    case 13: {
      return "PrivateId";
    }
    case 14: {
      return "TypeName";
    }
    case 15: {
      return "Decorator";
    }
    case 16: {
      return "Operator";
    }
    case 17: {
      return "Spread";
    }
    case 18: {
      return "BraceOpen";
    }
    case 19: {
      return "BraceClose";
    }
    case 20: {
      return "BracketOpen";
    }
    case 21: {
      return "BracketClose";
    }
    case 22: {
      return "ParenOpen";
    }
    case 23: {
      return "ParenClose";
    }
    case 24: {
      return "Semicolon";
    }
    case 25: {
      return "Comma";
    }
    case 26: {
      return "Dot";
    }
    case 27: {
      return "Colon";
    }
    case 28: {
      return "LineComment";
    }
    case 29: {
      return "BlockComment";
    }
    case 30: {
      return "JsxTagOpen";
    }
    case 31: {
      return "JsxTagClose";
    }
    case 32: {
      return "JsxCloseTag";
    }
    case 33: {
      return "JsxTagName";
    }
    case 34: {
      return "JsxAttribute";
    }
    case 35: {
      return "JsxEquals";
    }
    case 36: {
      return "JsxText";
    }
    case 37: {
      return "JsxExprStart";
    }
    case 38: {
      return "JsxExprEnd";
    }
    default: {
      return "Error";
    }
  }
}
function _M0FP36mizchi7syntree10typescript21highlight__typescript(source) {
  const tokenizer = _M0MP36mizchi7syntree10typescript11TsTokenizer3new(source);
  const tokens = _M0MP36mizchi7syntree10typescript11TsTokenizer13tokenize__all(tokenizer);
  const highlighter = _M0FP36mizchi7syntree10typescript15ts__highlighter();
  const result = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const name = _M0FP36mizchi7syntree10typescript17token__type__name(token.token_type);
      const tag = _M0MP26mizchi7syntree11Highlighter8get__tag(highlighter, name);
      if (_M0IP016_24default__implPB2Eq10not__equalGRP26mizchi7syntree12HighlightTagE(tag, 23)) {
        _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(result, _M0MP26mizchi7syntree14HighlightToken3new(token.from, token.to, tag));
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0MP36mizchi7syntree9highlight14HighlightTheme10get__color(self, tag) {
  switch (tag) {
    case 0: {
      return self.keyword;
    }
    case 1: {
      return self.operator;
    }
    case 2: {
      return self.punctuation;
    }
    case 3: {
      return self.string;
    }
    case 4: {
      return self.number;
    }
    case 6: {
      return self.bool;
    }
    case 7: {
      return self.null;
    }
    case 8: {
      return self.property;
    }
    case 9: {
      return self.variable;
    }
    case 10: {
      return self.function_;
    }
    case 11: {
      return self.type_;
    }
    case 12: {
      return self.class_;
    }
    case 13: {
      return self.variable;
    }
    case 18: {
      return self.comment;
    }
    case 19: {
      return self.doc_comment;
    }
    case 5: {
      return self.regexp;
    }
    case 14: {
      return self.meta;
    }
    case 15: {
      return self.bracket;
    }
    case 16: {
      return self.bracket;
    }
    case 17: {
      return self.bracket;
    }
    case 20: {
      return self.tag;
    }
    case 21: {
      return self.punctuation;
    }
    case 22: {
      return self.invalid;
    }
    default: {
      return self.foreground;
    }
  }
}
function _M0FP36mizchi7syntree9highlight20write__line__content(buf, chars, line_start, line_end, tokens, default_color) {
  let pos = line_start;
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      _L: {
        if (token.to <= line_start) {
          break _L;
        }
        if (token.from >= line_end) {
          break;
        }
        const token_start = token.from > line_start ? token.from : line_start;
        const token_end = token.to < line_end ? token.to : line_end;
        if (token_start > pos) {
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "<span style=\"color: ");
          _M0IPB13StringBuilderPB6Logger13write__string(buf, default_color);
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "\">");
          _M0FP26mizchi7syntree23escape__html__slice__to(chars, pos, token_start, buf);
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "</span>");
        }
        if (token_end > token_start) {
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "<span style=\"color: ");
          _M0IPB13StringBuilderPB6Logger13write__string(buf, token.color);
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "\">");
          _M0FP26mizchi7syntree23escape__html__slice__to(chars, token_start, token_end, buf);
          _M0IPB13StringBuilderPB6Logger13write__string(buf, "</span>");
        }
        pos = token_end;
        break _L;
      }
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (pos < line_end) {
    _M0IPB13StringBuilderPB6Logger13write__string(buf, "<span style=\"color: ");
    _M0IPB13StringBuilderPB6Logger13write__string(buf, default_color);
    _M0IPB13StringBuilderPB6Logger13write__string(buf, "\">");
    _M0FP26mizchi7syntree23escape__html__slice__to(chars, pos, line_end, buf);
    _M0IPB13StringBuilderPB6Logger13write__string(buf, "</span>");
    return;
  } else {
    return;
  }
}
function _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme) {
  const result = _M0MPB13StringBuilder11new_2einner(0);
  const chars = _M0MPC16string6String9to__array(source);
  const len = chars.length;
  _M0IPB13StringBuilderPB6Logger13write__string(result, "<pre class=\"highlight ");
  _M0IPB13StringBuilderPB6Logger13write__string(result, theme.name);
  _M0IPB13StringBuilderPB6Logger13write__string(result, "\" style=\"background-color: ");
  _M0IPB13StringBuilderPB6Logger13write__string(result, theme.background);
  _M0IPB13StringBuilderPB6Logger13write__string(result, "; color: ");
  _M0IPB13StringBuilderPB6Logger13write__string(result, theme.foreground);
  _M0IPB13StringBuilderPB6Logger13write__string(result, "\"><code>");
  const colored_tokens = [];
  const _bind = tokens.length;
  let _tmp = 0;
  while (true) {
    const _ = _tmp;
    if (_ < _bind) {
      const token = tokens[_];
      const color = _M0MP36mizchi7syntree9highlight14HighlightTheme10get__color(theme, token.tag);
      _M0MPC15array5Array4pushGRP26mizchi7syntree14HighlightTokenE(colored_tokens, new _M0TP36mizchi7syntree9highlight12ColoredToken(token.from, token.to, color));
      _tmp = _ + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let pos = 0;
  let line_start = 0;
  let in_line = false;
  while (true) {
    if (pos <= len) {
      const is_newline = pos < len && _M0MPC15array5Array2atGcE(chars, pos) === 10;
      const is_end = pos === len;
      if (!in_line) {
        _M0IPB13StringBuilderPB6Logger13write__string(result, "<span class=\"line\">");
        in_line = true;
        line_start = pos;
      }
      if (is_newline || is_end) {
        _M0FP36mizchi7syntree9highlight20write__line__content(result, chars, line_start, pos, colored_tokens, theme.foreground);
        _M0IPB13StringBuilderPB6Logger13write__string(result, "</span>");
        in_line = false;
        if (is_newline) {
          _M0IPB13StringBuilderPB6Logger13write__string(result, "\n");
        }
        pos = pos + 1 | 0;
      } else {
        pos = pos + 1 | 0;
      }
      continue;
    } else {
      break;
    }
  }
  _M0IPB13StringBuilderPB6Logger13write__string(result, "</code></pre>");
  return result.val;
}
function _M0FP36mizchi7syntree9highlight21highlight__typescript(source, theme) {
  const tokens = _M0FP36mizchi7syntree10typescript21highlight__typescript(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree9highlight18highlight__moonbit(source, theme) {
  const tokens = _M0FP36mizchi7syntree7moonbit18highlight__moonbit(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree9highlight15highlight__json(source, theme) {
  const tokens = _M0FP36mizchi7syntree4json15highlight__json(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree9highlight15highlight__html(source, theme) {
  const tokens = _M0FP36mizchi7syntree4html15highlight__html(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree9highlight14highlight__css(source, theme) {
  const tokens = _M0FP36mizchi7syntree3css14highlight__css(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree9highlight15highlight__bash(source, theme) {
  const tokens = _M0FP36mizchi7syntree4bash15highlight__bash(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree9highlight15highlight__rust(source, theme) {
  const tokens = _M0FP36mizchi7syntree4rust15highlight__rust(source);
  return _M0FP36mizchi7syntree9highlight16tokens__to__html(source, tokens, theme);
}
function _M0FP36mizchi7syntree12syntree__api21highlight__typescript(source) {
  return _M0FP36mizchi7syntree9highlight21highlight__typescript(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
function _M0FP36mizchi7syntree12syntree__api18highlight__moonbit(source) {
  return _M0FP36mizchi7syntree9highlight18highlight__moonbit(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
function _M0FP36mizchi7syntree12syntree__api15highlight__json(source) {
  return _M0FP36mizchi7syntree9highlight15highlight__json(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
function _M0FP36mizchi7syntree12syntree__api15highlight__html(source) {
  return _M0FP36mizchi7syntree9highlight15highlight__html(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
function _M0FP36mizchi7syntree12syntree__api14highlight__css(source) {
  return _M0FP36mizchi7syntree9highlight14highlight__css(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
function _M0FP36mizchi7syntree12syntree__api15highlight__bash(source) {
  return _M0FP36mizchi7syntree9highlight15highlight__bash(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
function _M0FP36mizchi7syntree12syntree__api15highlight__rust(source) {
  return _M0FP36mizchi7syntree9highlight15highlight__rust(source, _M0FP36mizchi7syntree9highlight28github__dark_2erecord_2f1232);
}
export { _M0FP36mizchi7syntree12syntree__api21highlight__typescript as highlight_typescript, _M0FP36mizchi7syntree12syntree__api18highlight__moonbit as highlight_moonbit, _M0FP36mizchi7syntree12syntree__api15highlight__json as highlight_json, _M0FP36mizchi7syntree12syntree__api15highlight__html as highlight_html, _M0FP36mizchi7syntree12syntree__api14highlight__css as highlight_css, _M0FP36mizchi7syntree12syntree__api15highlight__bash as highlight_bash, _M0FP36mizchi7syntree12syntree__api15highlight__rust as highlight_rust }
