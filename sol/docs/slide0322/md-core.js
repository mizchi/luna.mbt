function $64$mizchi$47$markdown$46$ListMarkerKind$Bullet(param0) {
  this._0 = param0;
}
$64$mizchi$47$markdown$46$ListMarkerKind$Bullet.prototype.$tag = 0;
function $64$mizchi$47$markdown$46$ListMarkerKind$Ordered(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$ListMarkerKind$Ordered.prototype.$tag = 1;
class $PanicError extends Error {}
function $panic() {
  throw new $PanicError();
}
const $64$moonbitlang$47$core$47$builtin$46$Json$Null = { $tag: 0 };
const $64$moonbitlang$47$core$47$builtin$46$Json$True = { $tag: 1 };
const $64$moonbitlang$47$core$47$builtin$46$Json$False = { $tag: 2 };
function $64$moonbitlang$47$core$47$builtin$46$Json$Number(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$moonbitlang$47$core$47$builtin$46$Json$Number.prototype.$tag = 3;
function $64$moonbitlang$47$core$47$builtin$46$Json$String(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$Json$String.prototype.$tag = 4;
function $64$moonbitlang$47$core$47$builtin$46$Json$Array(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$Json$Array.prototype.$tag = 5;
function $64$moonbitlang$47$core$47$builtin$46$Json$Object(param0) {
  this._0 = param0;
}
$64$moonbitlang$47$core$47$builtin$46$Json$Object.prototype.$tag = 6;
function $bound_check(arr, index) {
  if (index < 0 || index >= arr.length) throw new Error("Index out of bounds");
}
function $compare_int(a, b) {
  return (a >= b) - (a <= b);
}
const _M0FP311moonbitlang4core7builtin12random__seed = () => {
  if (globalThis.crypto?.getRandomValues) {
    const array = new Uint32Array(1);
    globalThis.crypto.getRandomValues(array);
    return array[0] | 0; // Convert to signed 32
  } else {
    return Math.floor(Math.random() * 0x100000000) | 0; // Fallback to Math.random
  }
};
function Result$Err$0$(param0) {
  this._0 = param0;
}
Result$Err$0$.prototype.$tag = 0;
function Result$Ok$0$(param0) {
  this._0 = param0;
}
Result$Ok$0$.prototype.$tag = 1;
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds = { $tag: 1 };
const Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex = { $tag: 0 };
const _M0FP311moonbitlang4core7builtin19int__to__string__js = (x, radix) => {
  return x.toString(radix);
};
function $unsafe_make_string(a, b) {
  return String.fromCodePoint(b).repeat(a);
}
function $make_array_len_and_init(a, b) {
  const arr = new Array(a);
  arr.fill(b);
  return arr;
}
const _M0MP311moonbitlang4core7builtin7JSArray4push = (arr, val) => { arr.push(val); };
const _M0MP311moonbitlang4core7builtin7JSArray4copy = (arr) => arr.slice(0);
const _M0FP311moonbitlang4core7builtin15ryu__to__string = (number) => number.toString();
const _M0MP311moonbitlang4core7builtin7JSArray3pop = (arr) => arr.pop();
const _M0MP311moonbitlang4core7builtin7JSArray6splice = (arr, idx, cnt) => arr.splice(idx, cnt);
function $64$moonbitlang$47$core$47$json$46$WriteFrame$Array(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$moonbitlang$47$core$47$json$46$WriteFrame$Array.prototype.$tag = 0;
function $64$moonbitlang$47$core$47$json$46$WriteFrame$Object(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$moonbitlang$47$core$47$json$46$WriteFrame$Object.prototype.$tag = 1;
const $0L = { hi: 0, lo: 0 };
const $1L = { hi: 0, lo: 1 };
const Option$None$1$ = { $tag: 0 };
function Option$Some$1$(param0) {
  this._0 = param0;
}
Option$Some$1$.prototype.$tag = 1;
function $64$mizchi$47$markdown$46$Inline$Text(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$Inline$Text.prototype.$tag = 0;
function $64$mizchi$47$markdown$46$Inline$SoftBreak(param0) {
  this._0 = param0;
}
$64$mizchi$47$markdown$46$Inline$SoftBreak.prototype.$tag = 1;
function $64$mizchi$47$markdown$46$Inline$HardBreak(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$Inline$HardBreak.prototype.$tag = 2;
function $64$mizchi$47$markdown$46$Inline$Emphasis(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$markdown$46$Inline$Emphasis.prototype.$tag = 3;
function $64$mizchi$47$markdown$46$Inline$Strong(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$markdown$46$Inline$Strong.prototype.$tag = 4;
function $64$mizchi$47$markdown$46$Inline$Strikethrough(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$Inline$Strikethrough.prototype.$tag = 5;
function $64$mizchi$47$markdown$46$Inline$Code(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$markdown$46$Inline$Code.prototype.$tag = 6;
function $64$mizchi$47$markdown$46$Inline$Link(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$markdown$46$Inline$Link.prototype.$tag = 7;
function $64$mizchi$47$markdown$46$Inline$RefLink(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$markdown$46$Inline$RefLink.prototype.$tag = 8;
function $64$mizchi$47$markdown$46$Inline$Autolink(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$markdown$46$Inline$Autolink.prototype.$tag = 9;
function $64$mizchi$47$markdown$46$Inline$Image(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$markdown$46$Inline$Image.prototype.$tag = 10;
function $64$mizchi$47$markdown$46$Inline$RefImage(param0, param1, param2) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
}
$64$mizchi$47$markdown$46$Inline$RefImage.prototype.$tag = 11;
function $64$mizchi$47$markdown$46$Inline$HtmlInline(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$Inline$HtmlInline.prototype.$tag = 12;
function $64$mizchi$47$markdown$46$Inline$FootnoteReference(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$Inline$FootnoteReference.prototype.$tag = 13;
function $64$mizchi$47$markdown$46$Block$ThematicBreak(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
$64$mizchi$47$markdown$46$Block$ThematicBreak.prototype.$tag = 0;
function $64$mizchi$47$markdown$46$Block$Heading(param0, param1, param2, param3, param4, param5, param6) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
  this._6 = param6;
}
$64$mizchi$47$markdown$46$Block$Heading.prototype.$tag = 1;
function $64$mizchi$47$markdown$46$Block$Paragraph(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$markdown$46$Block$Paragraph.prototype.$tag = 2;
function $64$mizchi$47$markdown$46$Block$FencedCode(param0, param1, param2, param3, param4, param5, param6, param7) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
  this._6 = param6;
  this._7 = param7;
}
$64$mizchi$47$markdown$46$Block$FencedCode.prototype.$tag = 3;
function $64$mizchi$47$markdown$46$Block$IndentedCode(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$markdown$46$Block$IndentedCode.prototype.$tag = 4;
function $64$mizchi$47$markdown$46$Block$Blockquote(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$markdown$46$Block$Blockquote.prototype.$tag = 5;
function $64$mizchi$47$markdown$46$Block$BulletList(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$64$mizchi$47$markdown$46$Block$BulletList.prototype.$tag = 6;
function $64$mizchi$47$markdown$46$Block$OrderedList(param0, param1, param2, param3, param4, param5, param6) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
  this._6 = param6;
}
$64$mizchi$47$markdown$46$Block$OrderedList.prototype.$tag = 7;
function $64$mizchi$47$markdown$46$Block$HtmlBlock(param0, param1, param2, param3) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
}
$64$mizchi$47$markdown$46$Block$HtmlBlock.prototype.$tag = 8;
function $64$mizchi$47$markdown$46$Block$Table(param0, param1, param2, param3, param4, param5) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
  this._5 = param5;
}
$64$mizchi$47$markdown$46$Block$Table.prototype.$tag = 9;
function $64$mizchi$47$markdown$46$Block$BlankLines(param0, param1) {
  this._0 = param0;
  this._1 = param1;
}
$64$mizchi$47$markdown$46$Block$BlankLines.prototype.$tag = 10;
function $64$mizchi$47$markdown$46$Block$FootnoteDefinition(param0, param1, param2, param3, param4) {
  this._0 = param0;
  this._1 = param1;
  this._2 = param2;
  this._3 = param3;
  this._4 = param4;
}
$64$mizchi$47$markdown$46$Block$FootnoteDefinition.prototype.$tag = 11;
const _M0FP095_40moonbitlang_2fcore_2fbuiltin_2eStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger = { method_0: _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string, method_1: _M0IP016_24default__implP311moonbitlang4core7builtin6Logger16write__substringGRP311moonbitlang4core7builtin13StringBuilderE, method_2: _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__view, method_3: _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char };
const _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1974 = "\n";
const _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1975 = "\n";
const _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1985 = "\n";
const _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1986 = "\n";
const _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c2003 = "\n";
const _M0FP26mizchi8markdown39serialize__frontmatter_2e_2abind_7c2088 = "\n";
const _M0FP26mizchi8markdown36render__block__html_2e_2abind_7c2209 = " ";
const _M0FP26mizchi8markdown36render__block__html_2e_2abind_7c2222 = "\n";
const _M0FP26mizchi8markdown37try__parse__autolink_2e_2abind_7c2300 = "@";
const _M0FP26mizchi8markdown37try__parse__autolink_2e_2abind_7c2301 = "http";
const _M0FP26mizchi8markdown39parse__segment__simple_2e_2abind_7c2649 = " ";
const _M0FP26mizchi8markdown33parse__paragraph_2e_2abind_7c2739 = " \t\n\r";
const _M0FP26mizchi8markdown40parse__heading__content_2e_2abind_7c2752 = " \t";
const _M0FP26mizchi8markdown40parse__heading__content_2e_2abind_7c2751 = " \t";
const _M0FP26mizchi8markdown41try__parse__fenced__code_2e_2abind_7c2771 = " \t";
const _M0FP26mizchi8markdown17html__block__tags = ["address", "article", "aside", "base", "basefont", "blockquote", "body", "caption", "center", "col", "colgroup", "dd", "details", "dialog", "dir", "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form", "frame", "frameset", "h1", "h2", "h3", "h4", "h5", "h6", "head", "header", "hr", "html", "iframe", "legend", "li", "link", "main", "menu", "menuitem", "nav", "noframes", "ol", "optgroup", "option", "p", "param", "search", "section", "summary", "svg", "table", "tbody", "td", "tfoot", "th", "thead", "title", "tr", "track", "ul"];
const _M0FP26mizchi8markdown40try__parse__html__block_2e_2abind_7c2788 = "/>";
const _M0FP26mizchi8markdown43try__parse__indented__code_2e_2abind_7c2794 = "\n";
const _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2837 = "[ ] ";
const _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2838 = "[x] ";
const _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2839 = "[X] ";
const _M0FP26mizchi8markdown44try__parse__setext__heading_2e_2abind_7c2913 = " \t\n\r";
const _M0FP26mizchi8markdown44try__parse__setext__heading_2e_2abind_7c2914 = " \t\n\r";
const _M0FP26mizchi8markdown36split__table__cells_2e_2abind_7c2929 = " \t\n\r";
const _M0FP26mizchi8markdown36split__table__cells_2e_2abind_7c2930 = " \t\n\r";
const _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2946 = " \t\n\r";
const _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2945 = ":";
const _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2944 = ":";
const _M0FP26mizchi8markdown34parse__table__row_2e_2abind_7c2949 = " \t\n\r";
const _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2951 = "|";
const _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2952 = "|";
const _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2953 = "-";
const _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2956 = " \t\n\r";
const _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2955 = "|";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2978 = "\n";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2972 = " \t\n\r";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2959 = "#";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2966 = ":";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2965 = " \t\n\r";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2964 = " \t\n\r";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2960 = "\"";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2961 = "\"";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2962 = "'";
const _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2963 = "'";
const _M0FP26mizchi8markdown21empty_2erecord_2f1179 = { content: "" };
const _M0FP311moonbitlang4core7builtin4seed = _M0FP311moonbitlang4core7builtin12random__seed();
const _bind = [];
const _M0FP36mizchi8markdown3api14ast__documents = _M0MP311moonbitlang4core7builtin3Map11from__arrayGiRP26mizchi8markdown8DocumentE({ buf: _bind, start: 0, end: 0 });
const _M0FP311moonbitlang4core7builtin33brute__force__find_2econstr_2f355 = 0;
const _M0FP311moonbitlang4core7builtin43boyer__moore__horspool__find_2econstr_2f341 = 0;
const _M0FP26mizchi8markdown38try__parse__code__span_2econstr_2f1654 = 32;
const _M0FP26mizchi8markdown38try__parse__code__span_2econstr_2f1655 = 32;
const _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2042 = new $64$mizchi$47$markdown$46$ListMarkerKind$Bullet(0);
const _M0FP26mizchi8markdown35detect__list__marker_2etuple_2f2043 = { _0: _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2042, _1: 2 };
const _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2044 = _M0FP26mizchi8markdown35detect__list__marker_2etuple_2f2043;
const _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2045 = new $64$mizchi$47$markdown$46$ListMarkerKind$Bullet(1);
const _M0FP26mizchi8markdown35detect__list__marker_2etuple_2f2046 = { _0: _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2045, _1: 2 };
const _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2047 = _M0FP26mizchi8markdown35detect__list__marker_2etuple_2f2046;
const _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2048 = new $64$mizchi$47$markdown$46$ListMarkerKind$Bullet(2);
const _M0FP26mizchi8markdown35detect__list__marker_2etuple_2f2049 = { _0: _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2048, _1: 2 };
const _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2050 = _M0FP26mizchi8markdown35detect__list__marker_2etuple_2f2049;
const _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2105 = 96;
const _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2106 = 96;
const _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2107 = 126;
const _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2108 = 126;
const _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2271 = false;
const _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2272 = true;
const _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2273 = false;
const _M0FP26mizchi8markdown36parse__task__checkbox_2etuple_2f2274 = { _0: _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2273, _1: "" };
const _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2275 = true;
const _M0FP26mizchi8markdown36parse__task__checkbox_2etuple_2f2276 = { _0: _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2275, _1: "" };
const _M0FP26mizchi8markdown43parse__nested__bullet__list_2econstr_2f2290 = 0;
const _M0FP26mizchi8markdown43parse__nested__bullet__list_2econstr_2f2291 = 1;
const _M0FP26mizchi8markdown43parse__nested__bullet__list_2econstr_2f2292 = 2;
const _M0FP26mizchi8markdown35parse__bullet__list_2econstr_2f2339 = 0;
const _M0FP26mizchi8markdown35parse__bullet__list_2econstr_2f2340 = 1;
const _M0FP26mizchi8markdown35parse__bullet__list_2econstr_2f2341 = 2;
const _M0FP36mizchi8markdown3api17ast__next__handle = _M0MP311moonbitlang4core3ref3Ref3newGiE(1);
const _M0FP26mizchi8markdown33serialize__inline_2econstr_2f1210 = 96;
const _M0FP26mizchi8markdown33serialize__inline_2econstr_2f1211 = 96;
const _bind$2 = [];
const _M0FP36mizchi8markdown3api12ast__sources = _M0MP311moonbitlang4core7builtin3Map11from__arrayGisE({ buf: _bind$2, start: 0, end: 0 });
function _M0FP311moonbitlang4core5abort5abortGRP311moonbitlang4core6string10StringViewE(msg) {
  return $panic();
}
function _M0FP311moonbitlang4core5abort5abortGuE(msg) {
  $panic();
}
function _M0FP311moonbitlang4core5abort5abortGiE(msg) {
  return $panic();
}
function _M0FP311moonbitlang4core5abort5abortGOiE(msg) {
  return $panic();
}
function _M0FP311moonbitlang4core5abort5abortGsE(msg) {
  return $panic();
}
function _M0FP311moonbitlang4core5abort5abortGRP311moonbitlang4core7builtin12MutArrayViewGUiicbEEE(msg) {
  return $panic();
}
function _M0FP311moonbitlang4core5abort5abortGUiicbEE(msg) {
  return $panic();
}
function _M0MP311moonbitlang4core7builtin6Hasher8consume4(self, input) {
  const _p = (self.acc >>> 0) + ((Math.imul(input, -1028477379) | 0) >>> 0) | 0;
  const _p$2 = 17;
  self.acc = Math.imul(_p << _p$2 | (_p >>> (32 - _p$2 | 0) | 0), 668265263) | 0;
}
function _M0MP311moonbitlang4core7builtin6Hasher13combine__uint(self, value) {
  self.acc = (self.acc >>> 0) + (4 >>> 0) | 0;
  _M0MP311moonbitlang4core7builtin6Hasher8consume4(self, value);
}
function _M0FP311moonbitlang4core7builtin5abortGRP311moonbitlang4core6string10StringViewE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGRP311moonbitlang4core6string10StringViewE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0FP311moonbitlang4core7builtin5abortGuE(string, loc) {
  _M0FP311moonbitlang4core5abort5abortGuE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0FP311moonbitlang4core7builtin5abortGiE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGiE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0FP311moonbitlang4core7builtin5abortGOiE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGOiE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0FP311moonbitlang4core7builtin5abortGsE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGsE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0FP311moonbitlang4core7builtin5abortGRP311moonbitlang4core7builtin12MutArrayViewGUiicbEEE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGRP311moonbitlang4core7builtin12MutArrayViewGUiicbEEE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0FP311moonbitlang4core7builtin5abortGUiicbEE(string, loc) {
  return _M0FP311moonbitlang4core5abort5abortGUiicbEE(`${string}\n  at ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(loc)}\n`);
}
function _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(size_hint) {
  return { val: "" };
}
function _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(self, ch) {
  const _bind$3 = self;
  _bind$3.val = `${_bind$3.val}${String.fromCodePoint(ch)}`;
}
function _M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(self) {
  return _M0IP016_24default__implP311moonbitlang4core7builtin7Compare6op__geGkE(self, 55296) && _M0IP016_24default__implP311moonbitlang4core7builtin7Compare6op__leGkE(self, 56319);
}
function _M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(self) {
  return _M0IP016_24default__implP311moonbitlang4core7builtin7Compare6op__geGkE(self, 56320) && _M0IP016_24default__implP311moonbitlang4core7builtin7Compare6op__leGkE(self, 57343);
}
function _M0MP311moonbitlang4core6string6String20char__length_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  if (start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= self.length)) {
    let _tmp = start_offset;
    let _tmp$2 = 0;
    while (true) {
      const utf16_index = _tmp;
      const char_count = _tmp$2;
      if (utf16_index < end_offset$2) {
        const c1 = self.charCodeAt(utf16_index);
        if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c1) && (utf16_index + 1 | 0) < end_offset$2) {
          const c2 = self.charCodeAt(utf16_index + 1 | 0);
          if (_M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c2)) {
            _tmp = utf16_index + 2 | 0;
            _tmp$2 = char_count + 1 | 0;
            continue;
          } else {
            _M0FP311moonbitlang4core7builtin5abortGuE("invalid surrogate pair", "@moonbitlang/core/builtin:string.mbt:81:9-81:40");
          }
        }
        _tmp = utf16_index + 1 | 0;
        _tmp$2 = char_count + 1 | 0;
        continue;
      } else {
        return char_count;
      }
    }
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGiE("invalid start or end index for String::codepoint_length", "@moonbitlang/core/builtin:string.mbt:70:5-70:69");
  }
}
function _M0FP311moonbitlang4core7builtin32code__point__of__surrogate__pair(leading, trailing) {
  return (((Math.imul(leading - 55296 | 0, 1024) | 0) + trailing | 0) - 56320 | 0) + 65536 | 0;
}
function _M0MP311moonbitlang4core6string6String16unsafe__char__at(self, index) {
  const c1 = self.charCodeAt(index);
  if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c1)) {
    const c2 = self.charCodeAt(index + 1 | 0);
    return _M0FP311moonbitlang4core7builtin32code__point__of__surrogate__pair(c1, c2);
  } else {
    return c1;
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown5BlockE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGcE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP311moonbitlang4core7builtin4JsonE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP311moonbitlang4core6string10StringViewE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown10TableAlignE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGiE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGsE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown9DelimiterE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown8ListItemE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGUiicbEE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown6InlineE(self, index) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    return self[index];
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core7builtin13SourceLocRepr5parse(repr) {
  const _bind$3 = { str: repr, start: 0, end: repr.length };
  const _data = _bind$3.str;
  const _start = _bind$3.start;
  const _end = _start + (_bind$3.end - _bind$3.start | 0) | 0;
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
      const next_char = _data.charCodeAt(_p);
      _cursor = _cursor + 1 | 0;
      if (next_char === 64) {
        _L$2: while (true) {
          tag_0 = _cursor;
          if (_cursor < _end) {
            const _p$2 = _cursor;
            const next_char$2 = _data.charCodeAt(_p$2);
            _cursor = _cursor + 1 | 0;
            if (next_char$2 === 58) {
              if (_cursor < _end) {
                const _p$3 = _cursor;
                _data.charCodeAt(_p$3);
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
                              const _p$4 = _cursor;
                              const next_char$3 = _data.charCodeAt(_p$4);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$3 < 58) {
                                if (next_char$3 < 48) {
                                  break _L$6;
                                } else {
                                  tag_1 = _cursor;
                                  tag_2_1 = tag_2;
                                  tag_2 = _cursor;
                                  tag_3 = _cursor;
                                  if (_cursor < _end) {
                                    _L$7: {
                                      const _p$5 = _cursor;
                                      const next_char$4 = _data.charCodeAt(_p$5);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$4 < 48) {
                                        if (next_char$4 === 45) {
                                          break _L$4;
                                        } else {
                                          break _L$7;
                                        }
                                      } else {
                                        if (next_char$4 > 57) {
                                          if (next_char$4 < 59) {
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
                                if (next_char$3 > 58) {
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
                              const _p$4 = _cursor;
                              const next_char$3 = _data.charCodeAt(_p$4);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$3 < 58) {
                                if (next_char$3 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 2;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$3 > 58) {
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
                            const _p$4 = _cursor;
                            const next_char$3 = _data.charCodeAt(_p$4);
                            _cursor = _cursor + 1 | 0;
                            if (next_char$3 === 58) {
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
                              const _p$4 = _cursor;
                              const next_char$3 = _data.charCodeAt(_p$4);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$3 < 58) {
                                if (next_char$3 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 4;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$3 > 58) {
                                  break _L$6;
                                } else {
                                  tag_1_2 = tag_1_1;
                                  tag_1_1 = tag_1;
                                  tag_1 = _cursor;
                                  if (_cursor < _end) {
                                    _L$7: {
                                      const _p$5 = _cursor;
                                      const next_char$4 = _data.charCodeAt(_p$5);
                                      _cursor = _cursor + 1 | 0;
                                      if (next_char$4 < 58) {
                                        if (next_char$4 < 48) {
                                          break _L$7;
                                        } else {
                                          tag_1 = _cursor;
                                          tag_2_1 = tag_2;
                                          tag_2 = _cursor;
                                          if (_cursor < _end) {
                                            _L$8: {
                                              const _p$6 = _cursor;
                                              const next_char$5 = _data.charCodeAt(_p$6);
                                              _cursor = _cursor + 1 | 0;
                                              if (next_char$5 < 58) {
                                                if (next_char$5 < 48) {
                                                  break _L$8;
                                                } else {
                                                  _tmp = 5;
                                                  continue _L$3;
                                                }
                                              } else {
                                                if (next_char$5 > 58) {
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
                                        if (next_char$4 > 58) {
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
                              const _p$4 = _cursor;
                              const next_char$3 = _data.charCodeAt(_p$4);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$3 < 58) {
                                if (next_char$3 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 5;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$3 > 58) {
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
                              const _p$4 = _cursor;
                              const next_char$3 = _data.charCodeAt(_p$4);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$3 < 48) {
                                if (next_char$3 === 45) {
                                  break _L$4;
                                } else {
                                  break _L$6;
                                }
                              } else {
                                if (next_char$3 > 57) {
                                  if (next_char$3 < 59) {
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
                              const _p$4 = _cursor;
                              const next_char$3 = _data.charCodeAt(_p$4);
                              _cursor = _cursor + 1 | 0;
                              if (next_char$3 < 58) {
                                if (next_char$3 < 48) {
                                  break _L$6;
                                } else {
                                  _tmp = 2;
                                  continue _L$3;
                                }
                              } else {
                                if (next_char$3 > 58) {
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
                      const _p$4 = _cursor;
                      const next_char$3 = _data.charCodeAt(_p$4);
                      _cursor = _cursor + 1 | 0;
                      if (next_char$3 < 58) {
                        if (next_char$3 < 48) {
                          break _L$5;
                        } else {
                          _tmp = 4;
                          continue;
                        }
                      } else {
                        if (next_char$3 > 58) {
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
    const start_line = _M0MP311moonbitlang4core6string6String4view(_data, match_tag_saver_1 + 1 | 0, match_tag_saver_2);
    const start_column = _M0MP311moonbitlang4core6string6String4view(_data, match_tag_saver_2 + 1 | 0, match_tag_saver_3);
    const pkg = _M0MP311moonbitlang4core6string6String4view(_data, _start + 1 | 0, match_tag_saver_0);
    const filename = _M0MP311moonbitlang4core6string6String4view(_data, match_tag_saver_0 + 1 | 0, match_tag_saver_1);
    const end_line = _M0MP311moonbitlang4core6string6String4view(_data, match_tag_saver_3 + 1 | 0, match_tag_saver_4);
    const end_column = _M0MP311moonbitlang4core6string6String4view(_data, match_tag_saver_4 + 1 | 0, match_end);
    return { pkg: pkg, filename: filename, start_line: start_line, start_column: start_column, end_line: end_line, end_column: end_column };
  } else {
    return $panic();
  }
}
function _M0MP311moonbitlang4core7builtin13StringBuilder13write__objectGdE(self, obj) {
  _M0IP311moonbitlang4core6double6DoubleP311moonbitlang4core7builtin4Show6output(obj, { self: self, method_table: _M0FP095_40moonbitlang_2fcore_2fbuiltin_2eStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
}
function _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(self, str) {
  const _bind$3 = self;
  _bind$3.val = `${_bind$3.val}${str}`;
}
function _M0MP311moonbitlang4core7builtin6Hasher12combine__int(self, value) {
  _M0MP311moonbitlang4core7builtin6Hasher13combine__uint(self, value);
}
function _M0MP311moonbitlang4core7builtin6Hasher7combineGiE(self, value) {
  _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin4Hash13hash__combine(value, self);
}
function _M0MP311moonbitlang4core7builtin6Hasher7combineGsE(self, value) {
  _M0IP311moonbitlang4core6string6StringP311moonbitlang4core7builtin4Hash13hash__combine(value, self);
}
function _M0IP016_24default__implP311moonbitlang4core7builtin2Eq10not__equalGmE(x, y) {
  return !_M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin2Eq5equal(x, y);
}
function _M0IP016_24default__implP311moonbitlang4core7builtin2Eq10not__equalGORP26mizchi8markdown12BulletMarkerE(x, y) {
  return !_M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGRP26mizchi8markdown12BulletMarkerE(x, y);
}
function _M0IP016_24default__implP311moonbitlang4core7builtin7Compare6op__leGkE(x, y) {
  return $compare_int(x, y) <= 0;
}
function _M0IP016_24default__implP311moonbitlang4core7builtin7Compare6op__geGkE(x, y) {
  return $compare_int(x, y) >= 0;
}
function _M0MP311moonbitlang4core7builtin6Hasher9avalanche(self) {
  let acc = self.acc;
  acc = acc ^ (acc >>> 15 | 0);
  acc = Math.imul(acc, -2048144777) | 0;
  acc = acc ^ (acc >>> 13 | 0);
  acc = Math.imul(acc, -1028477379) | 0;
  acc = acc ^ (acc >>> 16 | 0);
  return acc;
}
function _M0MP311moonbitlang4core7builtin6Hasher8finalize(self) {
  return _M0MP311moonbitlang4core7builtin6Hasher9avalanche(self);
}
function _M0MP311moonbitlang4core7builtin6Hasher11new_2einner(seed) {
  return { acc: (seed >>> 0) + (374761393 >>> 0) | 0 };
}
function _M0MP311moonbitlang4core7builtin6Hasher3new(seed$46$opt) {
  let seed;
  if (seed$46$opt === undefined) {
    seed = _M0FP311moonbitlang4core7builtin4seed;
  } else {
    const _Some = seed$46$opt;
    seed = _Some;
  }
  return _M0MP311moonbitlang4core7builtin6Hasher11new_2einner(seed);
}
function _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(self) {
  const h = _M0MP311moonbitlang4core7builtin6Hasher3new(undefined);
  _M0MP311moonbitlang4core7builtin6Hasher7combineGiE(h, self);
  return _M0MP311moonbitlang4core7builtin6Hasher8finalize(h);
}
function _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGsE(self) {
  const h = _M0MP311moonbitlang4core7builtin6Hasher3new(undefined);
  _M0MP311moonbitlang4core7builtin6Hasher7combineGsE(h, self);
  return _M0MP311moonbitlang4core7builtin6Hasher8finalize(h);
}
function _M0MP311moonbitlang4core6string6String11sub_2einner(self, start, end) {
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
    if (start$2 < len && _M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(self.charCodeAt(start$2))) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    if (end$2 < len && _M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(self.charCodeAt(end$2))) {
      return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$InvalidIndex);
    }
    return new Result$Ok$0$({ str: self, start: start$2, end: end$2 });
  } else {
    return new Result$Err$0$(Error$moonbitlang$47$core$47$builtin$46$CreatingViewError$46$IndexOutOfBounds);
  }
}
function _M0IP016_24default__implP311moonbitlang4core7builtin6Logger16write__substringGRP311moonbitlang4core7builtin13StringBuilderE(self, value, start, len) {
  let _tmp;
  let _try_err;
  _L: {
    _L$2: {
      const _bind$3 = _M0MP311moonbitlang4core6string6String11sub_2einner(value, start, start + len | 0);
      if (_bind$3.$tag === 1) {
        const _ok = _bind$3;
        _tmp = _ok._0;
      } else {
        const _err = _bind$3;
        _try_err = _err._0;
        break _L$2;
      }
      break _L;
    }
    _tmp = $panic();
  }
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__view(self, _tmp);
}
function _M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGRP311moonbitlang4core7builtin9SourceLocE(self) {
  const logger = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  _M0IP311moonbitlang4core7builtin9SourceLocP311moonbitlang4core7builtin4Show6output(self, { self: logger, method_table: _M0FP095_40moonbitlang_2fcore_2fbuiltin_2eStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return logger.val;
}
function _M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(self) {
  const logger = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin4Show6output(self, { self: logger, method_table: _M0FP095_40moonbitlang_2fcore_2fbuiltin_2eStringBuilder_24as_24_40moonbitlang_2fcore_2fbuiltin_2eLogger });
  return logger.val;
}
function _M0MP311moonbitlang4core7builtin4Iter4nextGUsRP311moonbitlang4core7builtin4JsonEE(self) {
  const _func = self;
  return _func();
}
function _M0MP311moonbitlang4core7builtin4Iter4nextGRP311moonbitlang4core6string10StringViewE(self) {
  const _func = self;
  return _func();
}
function _M0MP311moonbitlang4core7builtin4Iter4nextGcE(self) {
  const _func = self;
  return _func();
}
function _M0MP311moonbitlang4core7builtin4Iter4nextGRP26mizchi8markdown8ListItemE(self) {
  const _func = self;
  return _func();
}
function _M0MP311moonbitlang4core7builtin4Iter4nextGUicEE(self) {
  const _func = self;
  return _func();
}
function _M0MP311moonbitlang4core3int3Int18to__string_2einner(self, radix) {
  return _M0FP311moonbitlang4core7builtin19int__to__string__js(self, radix);
}
function _M0MP311moonbitlang4core6string10StringView12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.end - self.start | 0;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= (self.end - self.start | 0)) ? { str: self.str, start: self.start + start_offset | 0, end: self.start + end_offset$2 | 0 } : _M0FP311moonbitlang4core7builtin5abortGRP311moonbitlang4core6string10StringViewE("Invalid index for View", "@moonbitlang/core/builtin:stringview.mbt:113:5-113:36");
}
function _M0FP311moonbitlang4core7builtin31to__hex_2eto__hex__digit_7c3855(i) {
  if (i < 10) {
    const _p = 48;
    const _p$2 = (i + _p | 0) & 255;
    return _p$2;
  } else {
    const _p = 97;
    const _p$2 = (i + _p | 0) & 255;
    const _p$3 = 10;
    const _p$4 = (_p$2 - _p$3 | 0) & 255;
    return _p$4;
  }
}
function _M0MP311moonbitlang4core4byte4Byte7to__hex(b) {
  const _self = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const _p = 16;
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(_self, _M0FP311moonbitlang4core7builtin31to__hex_2eto__hex__digit_7c3855((b / _p | 0) & 255));
  const _p$2 = 16;
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(_self, _M0FP311moonbitlang4core7builtin31to__hex_2eto__hex__digit_7c3855((b % _p$2 | 0) & 255));
  const _p$3 = _self;
  return _p$3.val;
}
function _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(self) {
  return self.str.substring(self.start, self.end);
}
function _M0MP311moonbitlang4core6string10StringView4iter(self) {
  const start = self.start;
  const end = self.end;
  const index = { val: start };
  const _p = () => {
    if (index.val < end) {
      const c1 = self.str.charCodeAt(index.val);
      if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c1) && (index.val + 1 | 0) < self.end) {
        const c2 = self.str.charCodeAt(index.val + 1 | 0);
        if (_M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c2)) {
          index.val = index.val + 2 | 0;
          return _M0FP311moonbitlang4core7builtin32code__point__of__surrogate__pair(c1, c2);
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
function _M0MP311moonbitlang4core7builtin5Iter23newGicE(f) {
  return f;
}
function _M0MP311moonbitlang4core6string10StringView5iter2(self) {
  const start = self.start;
  const end = self.end;
  const index = { val: start };
  const char_index = { val: 0 };
  return _M0MP311moonbitlang4core7builtin5Iter23newGicE(() => {
    if (index.val < end) {
      const c1 = self.str.charCodeAt(index.val);
      if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c1) && (index.val + 1 | 0) < self.end) {
        const c2 = self.str.charCodeAt(index.val + 1 | 0);
        if (_M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c2)) {
          const result = { _0: char_index.val, _1: _M0FP311moonbitlang4core7builtin32code__point__of__surrogate__pair(c1, c2) };
          index.val = index.val + 2 | 0;
          char_index.val = char_index.val + 1 | 0;
          return result;
        }
      }
      const result = { _0: char_index.val, _1: c1 };
      index.val = index.val + 1 | 0;
      char_index.val = char_index.val + 1 | 0;
      return result;
    } else {
      return undefined;
    }
  });
}
function _M0MP311moonbitlang4core6string6String12view_2einner(self, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return start_offset >= 0 && (start_offset <= end_offset$2 && end_offset$2 <= self.length) ? { str: self, start: start_offset, end: end_offset$2 } : _M0FP311moonbitlang4core7builtin5abortGRP311moonbitlang4core6string10StringViewE("Invalid index for View", "@moonbitlang/core/builtin:stringview.mbt:399:5-399:36");
}
function _M0MP311moonbitlang4core6string6String4view(self, start_offset$46$opt, end_offset) {
  let start_offset;
  if (start_offset$46$opt === undefined) {
    start_offset = 0;
  } else {
    const _Some = start_offset$46$opt;
    start_offset = _Some;
  }
  return _M0MP311moonbitlang4core6string6String12view_2einner(self, start_offset, end_offset);
}
function _M0MP311moonbitlang4core6string6String24char__length__eq_2einner(self, len, start_offset, end_offset) {
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
      if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c1) && (index + 1 | 0) < end_offset$2) {
        const c2 = self.charCodeAt(index + 1 | 0);
        if (_M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c2)) {
          _tmp = index + 2 | 0;
          _tmp$2 = count + 1 | 0;
          continue;
        } else {
          _M0FP311moonbitlang4core7builtin5abortGuE("invalid surrogate pair", "@moonbitlang/core/builtin:string.mbt:424:9-424:40");
        }
      }
      _tmp = index + 1 | 0;
      _tmp$2 = count + 1 | 0;
      continue;
    } else {
      return count === len && index === end_offset$2;
    }
  }
}
function _M0MP311moonbitlang4core6string6String31offset__of__nth__char__backward(self, n, start_offset, end_offset) {
  let char_count = 0;
  let utf16_offset = end_offset;
  while (true) {
    if ((utf16_offset - 1 | 0) >= start_offset && char_count < n) {
      const c = self.charCodeAt(utf16_offset - 1 | 0);
      if (_M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c)) {
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
function _M0MP311moonbitlang4core6string6String30offset__of__nth__char__forward(self, n, start_offset, end_offset) {
  if (start_offset >= 0 && start_offset <= end_offset) {
    let utf16_offset = start_offset;
    let char_count = 0;
    while (true) {
      if (utf16_offset < end_offset && char_count < n) {
        const c = self.charCodeAt(utf16_offset);
        if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c)) {
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
    return _M0FP311moonbitlang4core7builtin5abortGOiE("Invalid start index", "@moonbitlang/core/builtin:string.mbt:327:5-327:33");
  }
}
function _M0MP311moonbitlang4core6string6String29offset__of__nth__char_2einner(self, i, start_offset, end_offset) {
  let end_offset$2;
  if (end_offset === undefined) {
    end_offset$2 = self.length;
  } else {
    const _Some = end_offset;
    end_offset$2 = _Some;
  }
  return i >= 0 ? _M0MP311moonbitlang4core6string6String30offset__of__nth__char__forward(self, i, start_offset, end_offset$2) : _M0MP311moonbitlang4core6string6String31offset__of__nth__char__backward(self, -i | 0, start_offset, end_offset$2);
}
function _M0FP311moonbitlang4core7builtin20unsafe__make__string(_tmp, _tmp$2) {
  return $unsafe_make_string(_tmp, _tmp$2);
}
function _M0MP311moonbitlang4core6string6String4make(length, value) {
  if (length >= 0) {
    if (value <= 65535) {
      return _M0FP311moonbitlang4core7builtin20unsafe__make__string(length, value);
    } else {
      const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(Math.imul(2, length) | 0);
      let _tmp = 0;
      while (true) {
        const _ = _tmp;
        if (_ < length) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, value);
          _tmp = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return buf.val;
    }
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGsE("invalid length", "@moonbitlang/core/builtin:string.mbt:27:28-27:51");
  }
}
function _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__view(self, str) {
  const _bind$3 = self;
  _bind$3.val = `${_bind$3.val}${_M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(str)}`;
}
function _M0MP311moonbitlang4core7builtin13StringBuilder5reset(self) {
  self.val = "";
}
function _M0FP311moonbitlang4core7builtin28boyer__moore__horspool__find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      const _end4308 = needle_len - 1 | 0;
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < _end4308) {
          const _tmp$2 = needle.str.charCodeAt(needle.start + i | 0) & 255;
          $bound_check(skip_table, _tmp$2);
          skip_table[_tmp$2] = (needle_len - 1 | 0) - i | 0;
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
          const _end4314 = needle_len - 1 | 0;
          let _tmp$3 = 0;
          while (true) {
            const j = _tmp$3;
            if (j <= _end4314) {
              const _p = i + j | 0;
              const _p$2 = haystack.str.charCodeAt(haystack.start + _p | 0);
              const _p$3 = needle.str.charCodeAt(needle.start + j | 0);
              if (_p$2 !== _p$3) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _p = (i + needle_len | 0) - 1 | 0;
          const _tmp$4 = haystack.str.charCodeAt(haystack.start + _p | 0) & 255;
          $bound_check(skip_table, _tmp$4);
          _tmp$2 = i + skip_table[_tmp$4] | 0;
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
    return _M0FP311moonbitlang4core7builtin43boyer__moore__horspool__find_2econstr_2f341;
  }
}
function _M0FP311moonbitlang4core7builtin18brute__force__find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const _p = 0;
      const needle_first = needle.str.charCodeAt(needle.start + _p | 0);
      const forward_len = haystack_len - needle_len | 0;
      let i = 0;
      while (true) {
        if (i <= forward_len) {
          while (true) {
            let _tmp;
            if (i <= forward_len) {
              const _p$2 = i;
              const _p$3 = haystack.str.charCodeAt(haystack.start + _p$2 | 0);
              _tmp = _p$3 !== needle_first;
            } else {
              _tmp = false;
            }
            if (_tmp) {
              i = i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (i <= forward_len) {
            let _tmp = 1;
            while (true) {
              const j = _tmp;
              if (j < needle_len) {
                const _p$2 = i + j | 0;
                const _p$3 = haystack.str.charCodeAt(haystack.start + _p$2 | 0);
                const _p$4 = needle.str.charCodeAt(needle.start + j | 0);
                if (_p$3 !== _p$4) {
                  break;
                }
                _tmp = j + 1 | 0;
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
    return _M0FP311moonbitlang4core7builtin33brute__force__find_2econstr_2f355;
  }
}
function _M0MP311moonbitlang4core6string10StringView4find(self, str) {
  return (str.end - str.start | 0) <= 4 ? _M0FP311moonbitlang4core7builtin18brute__force__find(self, str) : _M0FP311moonbitlang4core7builtin28boyer__moore__horspool__find(self, str);
}
function _M0FP311moonbitlang4core7builtin33boyer__moore__horspool__rev__find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const skip_table = $make_array_len_and_init(256, needle_len);
      let _tmp = needle_len - 1 | 0;
      while (true) {
        const i = _tmp;
        if (i > 0) {
          const _tmp$2 = needle.str.charCodeAt(needle.start + i | 0) & 255;
          $bound_check(skip_table, _tmp$2);
          skip_table[_tmp$2] = i;
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
              const _p$2 = haystack.str.charCodeAt(haystack.start + _p | 0);
              const _p$3 = needle.str.charCodeAt(needle.start + j | 0);
              if (_p$2 !== _p$3) {
                break;
              }
              _tmp$3 = j + 1 | 0;
              continue;
            } else {
              return i;
            }
          }
          const _tmp$4 = haystack.str.charCodeAt(haystack.start + i | 0) & 255;
          $bound_check(skip_table, _tmp$4);
          _tmp$2 = i - skip_table[_tmp$4] | 0;
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
function _M0MP311moonbitlang4core6string6String6repeat(self, n) {
  if (n <= 0) {
    return "";
  } else {
    if (n === 1) {
      return self;
    } else {
      const len = self.length;
      const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(Math.imul(len, n) | 0);
      const str = self;
      let _tmp = 0;
      while (true) {
        const _ = _tmp;
        if (_ < n) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, str);
          _tmp = _ + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      return buf.val;
    }
  }
}
function _M0MP311moonbitlang4core6string10StringView8find__by(self, pred) {
  const _it = _M0MP311moonbitlang4core6string10StringView5iter2(self);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin5Iter24nextGicE(_it);
    if (_bind$3 === undefined) {
      break;
    } else {
      const _Some = _bind$3;
      const _x = _Some;
      const _i = _x._0;
      const _c = _x._1;
      if (pred(_c)) {
        return _i;
      }
      continue;
    }
  }
  return undefined;
}
function _M0MP311moonbitlang4core6string6String8find__by(self, pred) {
  return _M0MP311moonbitlang4core6string10StringView8find__by({ str: self, start: 0, end: self.length }, pred);
}
function _M0FP311moonbitlang4core7builtin23brute__force__rev__find(haystack, needle) {
  const haystack_len = haystack.end - haystack.start | 0;
  const needle_len = needle.end - needle.start | 0;
  if (needle_len > 0) {
    if (haystack_len >= needle_len) {
      const _p = 0;
      const needle_first = needle.str.charCodeAt(needle.start + _p | 0);
      let i = haystack_len - needle_len | 0;
      while (true) {
        if (i >= 0) {
          while (true) {
            let _tmp;
            if (i >= 0) {
              const _p$2 = i;
              const _p$3 = haystack.str.charCodeAt(haystack.start + _p$2 | 0);
              _tmp = _p$3 !== needle_first;
            } else {
              _tmp = false;
            }
            if (_tmp) {
              i = i - 1 | 0;
              continue;
            } else {
              break;
            }
          }
          if (i >= 0) {
            let _tmp = 1;
            while (true) {
              const j = _tmp;
              if (j < needle_len) {
                const _p$2 = i + j | 0;
                const _p$3 = haystack.str.charCodeAt(haystack.start + _p$2 | 0);
                const _p$4 = needle.str.charCodeAt(needle.start + j | 0);
                if (_p$3 !== _p$4) {
                  break;
                }
                _tmp = j + 1 | 0;
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
function _M0MP311moonbitlang4core6string10StringView9rev__find(self, str) {
  return (str.end - str.start | 0) <= 4 ? _M0FP311moonbitlang4core7builtin23brute__force__rev__find(self, str) : _M0FP311moonbitlang4core7builtin33boyer__moore__horspool__rev__find(self, str);
}
function _M0MP311moonbitlang4core6string10StringView11has__suffix(self, str) {
  const _bind$3 = _M0MP311moonbitlang4core6string10StringView9rev__find(self, str);
  if (_bind$3 === undefined) {
    return false;
  } else {
    const _Some = _bind$3;
    const _i = _Some;
    return _i === ((self.end - self.start | 0) - (str.end - str.start | 0) | 0);
  }
}
function _M0MP311moonbitlang4core6string6String11has__suffix(self, str) {
  return _M0MP311moonbitlang4core6string10StringView11has__suffix({ str: self, start: 0, end: self.length }, str);
}
function _M0MP311moonbitlang4core6string10StringView11has__prefix(self, str) {
  const _bind$3 = _M0MP311moonbitlang4core6string10StringView4find(self, str);
  if (_bind$3 === undefined) {
    return false;
  } else {
    const _Some = _bind$3;
    const _i = _Some;
    return _i === 0;
  }
}
function _M0MP311moonbitlang4core6string6String11has__prefix(self, str) {
  return _M0MP311moonbitlang4core6string10StringView11has__prefix({ str: self, start: 0, end: self.length }, str);
}
function _M0MP311moonbitlang4core5array5Array11new_2einnerGcE(capacity) {
  return [];
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core4json10WriteFrameE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGcE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core6string10StringViewE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGUssEE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown14LinkDefinitionE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin5ArrayGRP26mizchi8markdown9TableCellEE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown8ListItemE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown10TableAlignE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGsE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown9TableCellE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown9DelimiterE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGUiicbEE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(self, value) {
  _M0MP311moonbitlang4core7builtin7JSArray4push(self, value);
}
function _M0MP311moonbitlang4core6string10StringView8contains(self, str) {
  const _bind$3 = _M0MP311moonbitlang4core6string10StringView4find(self, str);
  return !(_bind$3 === undefined);
}
function _M0MP311moonbitlang4core6string6String8contains(self, str) {
  return _M0MP311moonbitlang4core6string10StringView8contains({ str: self, start: 0, end: self.length }, str);
}
function _M0MP311moonbitlang4core6string10StringView14contains__char(self, c) {
  const len = self.end - self.start | 0;
  if (len > 0) {
    const c$2 = c;
    if (c$2 <= 65535) {
      let _tmp = 0;
      while (true) {
        const i = _tmp;
        if (i < len) {
          if (self.str.charCodeAt(self.start + i | 0) === c$2) {
            return true;
          }
          _tmp = i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
    } else {
      if (len >= 2) {
        const adj = c$2 - 65536 | 0;
        const high = 55296 + (adj >> 10) | 0;
        const low = 56320 + (adj & 1023) | 0;
        let i = 0;
        while (true) {
          if (i < (len - 1 | 0)) {
            const _p = i;
            if (self.str.charCodeAt(self.start + _p | 0) === high) {
              i = i + 1 | 0;
              const _p$2 = i;
              if (self.str.charCodeAt(self.start + _p$2 | 0) === low) {
                return true;
              }
            }
            i = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
      } else {
        return false;
      }
    }
    return false;
  } else {
    return false;
  }
}
function _M0MP311moonbitlang4core6string10StringView19trim__start_2einner(self, chars) {
  let _tmp = self;
  while (true) {
    const _param = _tmp;
    if (_M0MP311moonbitlang4core6string6String24char__length__eq_2einner(_param.str, 0, _param.start, _param.end)) {
      return _param;
    } else {
      const _c = _M0MP311moonbitlang4core6string6String16unsafe__char__at(_param.str, _M0MP311moonbitlang4core6string6String29offset__of__nth__char_2einner(_param.str, 0, _param.start, _param.end));
      const _tmp$2 = _param.str;
      const _bind$3 = _M0MP311moonbitlang4core6string6String29offset__of__nth__char_2einner(_param.str, 1, _param.start, _param.end);
      let _tmp$3;
      if (_bind$3 === undefined) {
        _tmp$3 = _param.end;
      } else {
        const _Some = _bind$3;
        _tmp$3 = _Some;
      }
      const _x = { str: _tmp$2, start: _tmp$3, end: _param.end };
      if (_M0MP311moonbitlang4core6string10StringView14contains__char(chars, _c)) {
        _tmp = _x;
        continue;
      } else {
        return _param;
      }
    }
  }
}
function _M0MP311moonbitlang4core6string10StringView17trim__end_2einner(self, chars) {
  let _tmp = self;
  while (true) {
    const _param = _tmp;
    if (_M0MP311moonbitlang4core6string6String24char__length__eq_2einner(_param.str, 0, _param.start, _param.end)) {
      return _param;
    } else {
      const _c = _M0MP311moonbitlang4core6string6String16unsafe__char__at(_param.str, _M0MP311moonbitlang4core6string6String29offset__of__nth__char_2einner(_param.str, -1, _param.start, _param.end));
      const _x = { str: _param.str, start: _param.start, end: _M0MP311moonbitlang4core6string6String29offset__of__nth__char_2einner(_param.str, -1, _param.start, _param.end) };
      if (_M0MP311moonbitlang4core6string10StringView14contains__char(chars, _c)) {
        _tmp = _x;
        continue;
      } else {
        return _param;
      }
    }
  }
}
function _M0MP311moonbitlang4core6string6String17trim__end_2einner(self, chars) {
  return _M0MP311moonbitlang4core6string10StringView17trim__end_2einner({ str: self, start: 0, end: self.length }, chars);
}
function _M0MP311moonbitlang4core6string10StringView12trim_2einner(self, chars) {
  return _M0MP311moonbitlang4core6string10StringView17trim__end_2einner(_M0MP311moonbitlang4core6string10StringView19trim__start_2einner(self, chars), chars);
}
function _M0MP311moonbitlang4core6string6String12trim_2einner(self, chars) {
  return _M0MP311moonbitlang4core6string10StringView12trim_2einner({ str: self, start: 0, end: self.length }, chars);
}
function _M0MP311moonbitlang4core6string10StringView9is__empty(self) {
  return (self.end - self.start | 0) === 0;
}
function _M0MP311moonbitlang4core6string6String4iter(self) {
  const len = self.length;
  const index = { val: 0 };
  const _p = () => {
    if (index.val < len) {
      const c1 = self.charCodeAt(index.val);
      if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c1) && (index.val + 1 | 0) < len) {
        const c2 = self.charCodeAt(index.val + 1 | 0);
        if (_M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c2)) {
          const c = _M0FP311moonbitlang4core7builtin32code__point__of__surrogate__pair(c1, c2);
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
function _M0MP311moonbitlang4core7builtin4Iter3mapGcRP311moonbitlang4core6string10StringViewE(self, f) {
  return () => {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(self);
    if (_bind$3 === -1) {
      return undefined;
    } else {
      const _Some = _bind$3;
      const _x = _Some;
      return f(_x);
    }
  };
}
function _M0IP311moonbitlang4core4char4CharP311moonbitlang4core7builtin4Show10to__string(self) {
  return String.fromCodePoint(self);
}
function _M0MP311moonbitlang4core6string10StringView5split(self, sep) {
  const sep_len = sep.end - sep.start | 0;
  if (sep_len === 0) {
    return _M0MP311moonbitlang4core7builtin4Iter3mapGcRP311moonbitlang4core6string10StringViewE(_M0MP311moonbitlang4core6string10StringView4iter(self), (c) => _M0MP311moonbitlang4core6string6String12view_2einner(_M0IP311moonbitlang4core4char4CharP311moonbitlang4core7builtin4Show10to__string(c), 0, undefined));
  }
  const remaining = { val: self };
  const _p = () => {
    const _bind$3 = remaining.val;
    if (_bind$3 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$3;
      const _view = _Some;
      const _bind$4 = _M0MP311moonbitlang4core6string10StringView4find(_view, sep);
      if (_bind$4 === undefined) {
        remaining.val = undefined;
        return _view;
      } else {
        const _Some$2 = _bind$4;
        const _end = _Some$2;
        remaining.val = _M0MP311moonbitlang4core6string10StringView12view_2einner(_view, _end + sep_len | 0, undefined);
        return _M0MP311moonbitlang4core6string10StringView12view_2einner(_view, 0, _end);
      }
    }
  };
  return _p;
}
function _M0MP311moonbitlang4core6string6String5split(self, sep) {
  return _M0MP311moonbitlang4core6string10StringView5split({ str: self, start: 0, end: self.length }, sep);
}
function _M0MP311moonbitlang4core7builtin4Iter9to__arrayGRP311moonbitlang4core6string10StringViewE(self) {
  const result = [];
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGRP311moonbitlang4core6string10StringViewE(self);
    if (_bind$3 === undefined) {
      break;
    } else {
      const _Some = _bind$3;
      const _x = _Some;
      _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core6string10StringViewE(result, _x);
      continue;
    }
  }
  return result;
}
function _M0MP311moonbitlang4core4char4Char20is__ascii__uppercase(self) {
  return self >= 65 && self <= 90;
}
function _M0MP311moonbitlang4core6string6String9to__lower(self) {
  const _bind$3 = _M0MP311moonbitlang4core6string6String8find__by(self, (x) => _M0MP311moonbitlang4core4char4Char20is__ascii__uppercase(x));
  if (_bind$3 === undefined) {
    return self;
  } else {
    const _Some = _bind$3;
    const _idx = _Some;
    const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(self.length);
    const head = _M0MP311moonbitlang4core6string6String12view_2einner(self, 0, _idx);
    _M0IP016_24default__implP311moonbitlang4core7builtin6Logger16write__substringGRP311moonbitlang4core7builtin13StringBuilderE(buf, head.str, head.start, head.end - head.start | 0);
    const _it = _M0MP311moonbitlang4core6string10StringView4iter(_M0MP311moonbitlang4core6string6String12view_2einner(self, _idx, undefined));
    while (true) {
      const _bind$4 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
      if (_bind$4 === -1) {
        break;
      } else {
        const _Some$2 = _bind$4;
        const _c = _Some$2;
        if (_M0MP311moonbitlang4core4char4Char20is__ascii__uppercase(_c)) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c + 32 | 0);
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
        }
        continue;
      }
    }
    return buf.val;
  }
}
function _M0MP311moonbitlang4core6string6String9get__char(self, idx) {
  if (idx >= 0 && idx < self.length) {
    const c = self.charCodeAt(idx);
    if (_M0MP311moonbitlang4core6uint166UInt1622is__leading__surrogate(c)) {
      if ((idx + 1 | 0) < self.length) {
        const next = self.charCodeAt(idx + 1 | 0);
        return _M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(next) ? _M0FP311moonbitlang4core7builtin32code__point__of__surrogate__pair(c, next) : -1;
      } else {
        return -1;
      }
    } else {
      return _M0MP311moonbitlang4core6uint166UInt1623is__trailing__surrogate(c) ? -1 : c;
    }
  } else {
    return -1;
  }
}
function _M0MP311moonbitlang4core6string6String9to__array(self) {
  const _p = _M0MP311moonbitlang4core6string6String4iter(self);
  const _p$2 = _M0MP311moonbitlang4core5array5Array11new_2einnerGcE(self.length);
  let _p$3 = _p$2;
  while (true) {
    const _p$4 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_p);
    if (_p$4 === -1) {
      break;
    } else {
      const _p$5 = _p$4;
      const _p$6 = _p$5;
      const _p$7 = _p$3;
      _M0MP311moonbitlang4core5array5Array4pushGcE(_p$7, _p$6);
      _p$3 = _p$7;
      continue;
    }
  }
  return _p$3;
}
function _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin4Show6output(self, logger) {
  logger.method_table.method_0(logger.self, _M0MP311moonbitlang4core3int3Int18to__string_2einner(self, 10));
}
function _M0MP311moonbitlang4core5array9ArrayView4iterGRP26mizchi8markdown8ListItemE(self) {
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
function _M0MP311moonbitlang4core5array5Array4iterGRP26mizchi8markdown8ListItemE(self) {
  return _M0MP311moonbitlang4core5array9ArrayView4iterGRP26mizchi8markdown8ListItemE({ buf: self, start: 0, end: self.length });
}
function _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(self, other) {
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
function _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGRP26mizchi8markdown12BulletMarkerE(self, other) {
  if (self === undefined) {
    return other === undefined;
  } else {
    const _Some = self;
    const _x = _Some;
    if (other === undefined) {
      return false;
    } else {
      const _Some$2 = other;
      const _y = _Some$2;
      return _M0IP26mizchi8markdown12BulletMarkerP311moonbitlang4core7builtin2Eq5equal(_x, _y);
    }
  }
}
function _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(self, index) {
  if (index >= 0 && index < (self.end - self.start | 0)) {
    const _tmp = self.buf;
    const _tmp$2 = self.start + index | 0;
    $bound_check(_tmp, _tmp$2);
    return _tmp[_tmp$2];
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGUiicbEE(`index out of bounds: the len is from 0 to ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(self.end - self.start | 0)} but the index is ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(index)}`, "@moonbitlang/core/builtin:mutarrayview.mbt:118:5-120:6");
  }
}
function _M0MP311moonbitlang4core5array12MutArrayView3setGUiicbEE(self, index, value) {
  if (index >= 0 && index < (self.end - self.start | 0)) {
    const _tmp = self.buf;
    const _tmp$2 = self.start + index | 0;
    $bound_check(_tmp, _tmp$2);
    _tmp[_tmp$2] = value;
    return;
  } else {
    _M0FP311moonbitlang4core7builtin5abortGuE(`index out of bounds: the len is from 0 to ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(self.end - self.start | 0)} but the index is ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(index)}`, "@moonbitlang/core/builtin:mutarrayview.mbt:182:5-184:6");
    return;
  }
}
function _M0MP311moonbitlang4core5array5Array17mut__view_2einnerGUiicbEE(self, start, end) {
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
    const _bind$3 = self;
    const _bind$4 = end$2 - start$2 | 0;
    return { buf: _bind$3, start: start$2, end: start$2 + _bind$4 | 0 };
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGRP311moonbitlang4core7builtin12MutArrayViewGUiicbEEE("View index out of bounds", "@moonbitlang/core/builtin:mutarrayview.mbt:258:5-258:38");
  }
}
function _M0MP311moonbitlang4core5array12MutArrayView17mut__view_2einnerGUiicbEE(self, start, end) {
  const len = self.end - self.start | 0;
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
    const _bind$3 = self.buf;
    const _bind$4 = self.start + start$2 | 0;
    const _bind$5 = end$2 - start$2 | 0;
    return { buf: _bind$3, start: _bind$4, end: _bind$4 + _bind$5 | 0 };
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGRP311moonbitlang4core7builtin12MutArrayViewGUiicbEEE("View index out of bounds", "@moonbitlang/core/builtin:mutarrayview.mbt:307:5-307:38");
  }
}
function _M0MP311moonbitlang4core5array5Array4makeGiE(len, elem) {
  const arr = new Array(len);
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < len) {
      arr[i] = elem;
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return arr;
}
function _M0MP311moonbitlang4core5array5Array3setGiE(self, index, value) {
  const len = self.length;
  if (index >= 0 && index < len) {
    $bound_check(self, index);
    self[index] = value;
    return;
  } else {
    $panic();
    return;
  }
}
function _M0MP311moonbitlang4core3int3Int20next__power__of__two(self) {
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
function _M0MP311moonbitlang4core7builtin3Map11new_2einnerGiRP26mizchi8markdown8DocumentE(capacity) {
  const capacity$2 = _M0MP311moonbitlang4core3int3Int20next__power__of__two(capacity);
  const _bind$3 = capacity$2 - 1 | 0;
  const _bind$4 = (Math.imul(capacity$2, 13) | 0) / 16 | 0;
  const _bind$5 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$6 = undefined;
  return { entries: _bind$5, size: 0, capacity: capacity$2, capacity_mask: _bind$3, grow_at: _bind$4, head: _bind$6, tail: -1 };
}
function _M0MP311moonbitlang4core7builtin3Map11new_2einnerGisE(capacity) {
  const capacity$2 = _M0MP311moonbitlang4core3int3Int20next__power__of__two(capacity);
  const _bind$3 = capacity$2 - 1 | 0;
  const _bind$4 = (Math.imul(capacity$2, 13) | 0) / 16 | 0;
  const _bind$5 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$6 = undefined;
  return { entries: _bind$5, size: 0, capacity: capacity$2, capacity_mask: _bind$3, grow_at: _bind$4, head: _bind$6, tail: -1 };
}
function _M0MP311moonbitlang4core7builtin3Map11new_2einnerGsRP311moonbitlang4core7builtin4JsonE(capacity) {
  const capacity$2 = _M0MP311moonbitlang4core3int3Int20next__power__of__two(capacity);
  const _bind$3 = capacity$2 - 1 | 0;
  const _bind$4 = (Math.imul(capacity$2, 13) | 0) / 16 | 0;
  const _bind$5 = $make_array_len_and_init(capacity$2, undefined);
  const _bind$6 = undefined;
  return { entries: _bind$5, size: 0, capacity: capacity$2, capacity_mask: _bind$3, grow_at: _bind$4, head: _bind$6, tail: -1 };
}
function _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGiRP26mizchi8markdown8DocumentE(self, idx, entry) {
  const _bind$3 = self.tail;
  if (_bind$3 === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind$3);
    const _p = _tmp[_bind$3];
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
function _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGisE(self, idx, entry) {
  const _bind$3 = self.tail;
  if (_bind$3 === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind$3);
    const _p = _tmp[_bind$3];
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
function _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGsRP311moonbitlang4core7builtin4JsonE(self, idx, entry) {
  const _bind$3 = self.tail;
  if (_bind$3 === -1) {
    self.head = entry;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind$3);
    const _p = _tmp[_bind$3];
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
function _M0MP311moonbitlang4core7builtin3Map10set__entryGiRP26mizchi8markdown8DocumentE(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind$3 = entry.next;
  if (_bind$3 === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind$3;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map10set__entryGisE(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind$3 = entry.next;
  if (_bind$3 === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind$3;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map10set__entryGsRP311moonbitlang4core7builtin4JsonE(self, entry, new_idx) {
  const _tmp = self.entries;
  $bound_check(_tmp, new_idx);
  _tmp[new_idx] = entry;
  const _bind$3 = entry.next;
  if (_bind$3 === undefined) {
    self.tail = new_idx;
    return;
  } else {
    const _Some = _bind$3;
    const _next = _Some;
    _next.prev = new_idx;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map10push__awayGiRP26mizchi8markdown8DocumentE(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = idx + 1 & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind$3 = _tmp$4[idx$2];
    if (_bind$3 === undefined) {
      entry$2.psl = psl;
      _M0MP311moonbitlang4core7builtin3Map10set__entryGiRP26mizchi8markdown8DocumentE(self, entry$2, idx$2);
      break;
    } else {
      const _Some = _bind$3;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        _M0MP311moonbitlang4core7builtin3Map10set__entryGiRP26mizchi8markdown8DocumentE(self, entry$2, idx$2);
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
function _M0MP311moonbitlang4core7builtin3Map10push__awayGisE(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = idx + 1 & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind$3 = _tmp$4[idx$2];
    if (_bind$3 === undefined) {
      entry$2.psl = psl;
      _M0MP311moonbitlang4core7builtin3Map10set__entryGisE(self, entry$2, idx$2);
      break;
    } else {
      const _Some = _bind$3;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        _M0MP311moonbitlang4core7builtin3Map10set__entryGisE(self, entry$2, idx$2);
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
function _M0MP311moonbitlang4core7builtin3Map10push__awayGsRP311moonbitlang4core7builtin4JsonE(self, idx, entry) {
  let _tmp = entry.psl + 1 | 0;
  let _tmp$2 = idx + 1 & self.capacity_mask;
  let _tmp$3 = entry;
  while (true) {
    const psl = _tmp;
    const idx$2 = _tmp$2;
    const entry$2 = _tmp$3;
    const _tmp$4 = self.entries;
    $bound_check(_tmp$4, idx$2);
    const _bind$3 = _tmp$4[idx$2];
    if (_bind$3 === undefined) {
      entry$2.psl = psl;
      _M0MP311moonbitlang4core7builtin3Map10set__entryGsRP311moonbitlang4core7builtin4JsonE(self, entry$2, idx$2);
      break;
    } else {
      const _Some = _bind$3;
      const _curr_entry = _Some;
      if (psl > _curr_entry.psl) {
        entry$2.psl = psl;
        _M0MP311moonbitlang4core7builtin3Map10set__entryGsRP311moonbitlang4core7builtin4JsonE(self, entry$2, idx$2);
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
function _M0MP311moonbitlang4core7builtin3Map15set__with__hashGiRP26mizchi8markdown8DocumentE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      if (self.size >= self.grow_at) {
        _M0MP311moonbitlang4core7builtin3Map4growGiRP26mizchi8markdown8DocumentE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$4 = self.tail;
      const _bind$5 = undefined;
      const entry = { prev: _bind$4, next: _bind$5, psl: psl, hash: hash, key: key, value: value };
      _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGiRP26mizchi8markdown8DocumentE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind$3;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MP311moonbitlang4core7builtin3Map4growGiRP26mizchi8markdown8DocumentE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MP311moonbitlang4core7builtin3Map10push__awayGiRP26mizchi8markdown8DocumentE(self, idx, _curr_entry);
        const _bind$4 = self.tail;
        const _bind$5 = undefined;
        const entry = { prev: _bind$4, next: _bind$5, psl: psl, hash: hash, key: key, value: value };
        _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGiRP26mizchi8markdown8DocumentE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map15set__with__hashGisE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      if (self.size >= self.grow_at) {
        _M0MP311moonbitlang4core7builtin3Map4growGisE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$4 = self.tail;
      const _bind$5 = undefined;
      const entry = { prev: _bind$4, next: _bind$5, psl: psl, hash: hash, key: key, value: value };
      _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGisE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind$3;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MP311moonbitlang4core7builtin3Map4growGisE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MP311moonbitlang4core7builtin3Map10push__awayGisE(self, idx, _curr_entry);
        const _bind$4 = self.tail;
        const _bind$5 = undefined;
        const entry = { prev: _bind$4, next: _bind$5, psl: psl, hash: hash, key: key, value: value };
        _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGisE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map15set__with__hashGsRP311moonbitlang4core7builtin4JsonE(self, key, value, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const psl = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      if (self.size >= self.grow_at) {
        _M0MP311moonbitlang4core7builtin3Map4growGsRP311moonbitlang4core7builtin4JsonE(self);
        _tmp = 0;
        _tmp$2 = hash & self.capacity_mask;
        continue;
      }
      const _bind$4 = self.tail;
      const _bind$5 = undefined;
      const entry = { prev: _bind$4, next: _bind$5, psl: psl, hash: hash, key: key, value: value };
      _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGsRP311moonbitlang4core7builtin4JsonE(self, idx, entry);
      return undefined;
    } else {
      const _Some = _bind$3;
      const _curr_entry = _Some;
      if (_curr_entry.hash === hash && _curr_entry.key === key) {
        _curr_entry.value = value;
        return undefined;
      }
      if (psl > _curr_entry.psl) {
        if (self.size >= self.grow_at) {
          _M0MP311moonbitlang4core7builtin3Map4growGsRP311moonbitlang4core7builtin4JsonE(self);
          _tmp = 0;
          _tmp$2 = hash & self.capacity_mask;
          continue;
        }
        _M0MP311moonbitlang4core7builtin3Map10push__awayGsRP311moonbitlang4core7builtin4JsonE(self, idx, _curr_entry);
        const _bind$4 = self.tail;
        const _bind$5 = undefined;
        const entry = { prev: _bind$4, next: _bind$5, psl: psl, hash: hash, key: key, value: value };
        _M0MP311moonbitlang4core7builtin3Map20add__entry__to__tailGsRP311moonbitlang4core7builtin4JsonE(self, idx, entry);
        return undefined;
      }
      _tmp = psl + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map4growGiRP26mizchi8markdown8DocumentE(self) {
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
      _M0MP311moonbitlang4core7builtin3Map15set__with__hashGiRP26mizchi8markdown8DocumentE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map4growGisE(self) {
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
      _M0MP311moonbitlang4core7builtin3Map15set__with__hashGisE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map4growGsRP311moonbitlang4core7builtin4JsonE(self) {
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
      _M0MP311moonbitlang4core7builtin3Map15set__with__hashGsRP311moonbitlang4core7builtin4JsonE(self, _key, _value, _hash);
      _tmp = _next;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map3setGiRP26mizchi8markdown8DocumentE(self, key, value) {
  _M0MP311moonbitlang4core7builtin3Map15set__with__hashGiRP26mizchi8markdown8DocumentE(self, key, value, _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(key));
}
function _M0MP311moonbitlang4core7builtin3Map3setGisE(self, key, value) {
  _M0MP311moonbitlang4core7builtin3Map15set__with__hashGisE(self, key, value, _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(key));
}
function _M0MP311moonbitlang4core7builtin3Map3setGsRP311moonbitlang4core7builtin4JsonE(self, key, value) {
  _M0MP311moonbitlang4core7builtin3Map15set__with__hashGsRP311moonbitlang4core7builtin4JsonE(self, key, value, _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGsE(key));
}
function _M0MP311moonbitlang4core7builtin3Map11from__arrayGiRP26mizchi8markdown8DocumentE(arr) {
  const length = arr.end - arr.start | 0;
  let capacity = _M0MP311moonbitlang4core3int3Int20next__power__of__two(length);
  const _p = capacity;
  if (length > ((Math.imul(_p, 13) | 0) / 16 | 0)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MP311moonbitlang4core7builtin3Map11new_2einnerGiRP26mizchi8markdown8DocumentE(capacity);
  const _len = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const e = arr.buf[arr.start + _i | 0];
      _M0MP311moonbitlang4core7builtin3Map3setGiRP26mizchi8markdown8DocumentE(m, e._0, e._1);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MP311moonbitlang4core7builtin3Map11from__arrayGisE(arr) {
  const length = arr.end - arr.start | 0;
  let capacity = _M0MP311moonbitlang4core3int3Int20next__power__of__two(length);
  const _p = capacity;
  if (length > ((Math.imul(_p, 13) | 0) / 16 | 0)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MP311moonbitlang4core7builtin3Map11new_2einnerGisE(capacity);
  const _len = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const e = arr.buf[arr.start + _i | 0];
      _M0MP311moonbitlang4core7builtin3Map3setGisE(m, e._0, e._1);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE(arr) {
  const length = arr.end - arr.start | 0;
  let capacity = _M0MP311moonbitlang4core3int3Int20next__power__of__two(length);
  const _p = capacity;
  if (length > ((Math.imul(_p, 13) | 0) / 16 | 0)) {
    capacity = Math.imul(capacity, 2) | 0;
  }
  const m = _M0MP311moonbitlang4core7builtin3Map11new_2einnerGsRP311moonbitlang4core7builtin4JsonE(capacity);
  const _len = arr.end - arr.start | 0;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const e = arr.buf[arr.start + _i | 0];
      _M0MP311moonbitlang4core7builtin3Map3setGsRP311moonbitlang4core7builtin4JsonE(m, e._0, e._1);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return m;
}
function _M0MP311moonbitlang4core7builtin3Map3getGiRP26mizchi8markdown8DocumentE(self, key) {
  const hash = _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$3;
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
function _M0MP311moonbitlang4core7builtin3Map3getGisE(self, key) {
  const hash = _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(key);
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$3;
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
function _M0MP311moonbitlang4core7builtin3Map13remove__entryGiRP26mizchi8markdown8DocumentE(self, entry) {
  const _bind$3 = entry.prev;
  if (_bind$3 === -1) {
    self.head = entry.next;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind$3);
    const _p = _tmp[_bind$3];
    let _tmp$2;
    if (_p === undefined) {
      _tmp$2 = $panic();
    } else {
      const _p$2 = _p;
      _tmp$2 = _p$2;
    }
    _tmp$2.next = entry.next;
  }
  const _bind$4 = entry.next;
  if (_bind$4 === undefined) {
    self.tail = entry.prev;
    return;
  } else {
    const _Some = _bind$4;
    const _next = _Some;
    _next.prev = entry.prev;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map13remove__entryGisE(self, entry) {
  const _bind$3 = entry.prev;
  if (_bind$3 === -1) {
    self.head = entry.next;
  } else {
    const _tmp = self.entries;
    $bound_check(_tmp, _bind$3);
    const _p = _tmp[_bind$3];
    let _tmp$2;
    if (_p === undefined) {
      _tmp$2 = $panic();
    } else {
      const _p$2 = _p;
      _tmp$2 = _p$2;
    }
    _tmp$2.next = entry.next;
  }
  const _bind$4 = entry.next;
  if (_bind$4 === undefined) {
    self.tail = entry.prev;
    return;
  } else {
    const _Some = _bind$4;
    const _next = _Some;
    _next.prev = entry.prev;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map11shift__backGiRP26mizchi8markdown8DocumentE(self, idx) {
  let _tmp = idx;
  while (true) {
    const idx$2 = _tmp;
    const next = idx$2 + 1 & self.capacity_mask;
    _L: {
      const _tmp$2 = self.entries;
      $bound_check(_tmp$2, next);
      const _bind$3 = _tmp$2[next];
      if (_bind$3 === undefined) {
        break _L;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        const _x$2 = _x.psl;
        if (_x$2 === 0) {
          break _L;
        } else {
          _x.psl = _x.psl - 1 | 0;
          _M0MP311moonbitlang4core7builtin3Map10set__entryGiRP26mizchi8markdown8DocumentE(self, _x, idx$2);
          _tmp = next;
          continue;
        }
      }
    }
    const _tmp$2 = self.entries;
    $bound_check(_tmp$2, idx$2);
    _tmp$2[idx$2] = undefined;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map11shift__backGisE(self, idx) {
  let _tmp = idx;
  while (true) {
    const idx$2 = _tmp;
    const next = idx$2 + 1 & self.capacity_mask;
    _L: {
      const _tmp$2 = self.entries;
      $bound_check(_tmp$2, next);
      const _bind$3 = _tmp$2[next];
      if (_bind$3 === undefined) {
        break _L;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        const _x$2 = _x.psl;
        if (_x$2 === 0) {
          break _L;
        } else {
          _x.psl = _x.psl - 1 | 0;
          _M0MP311moonbitlang4core7builtin3Map10set__entryGisE(self, _x, idx$2);
          _tmp = next;
          continue;
        }
      }
    }
    const _tmp$2 = self.entries;
    $bound_check(_tmp$2, idx$2);
    _tmp$2[idx$2] = undefined;
    return;
  }
}
function _M0MP311moonbitlang4core7builtin3Map18remove__with__hashGiRP26mizchi8markdown8DocumentE(self, key, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      break;
    } else {
      const _Some = _bind$3;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        _M0MP311moonbitlang4core7builtin3Map13remove__entryGiRP26mizchi8markdown8DocumentE(self, _entry);
        _M0MP311moonbitlang4core7builtin3Map11shift__backGiRP26mizchi8markdown8DocumentE(self, idx);
        self.size = self.size - 1 | 0;
        break;
      }
      if (i > _entry.psl) {
        break;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map18remove__with__hashGisE(self, key, hash) {
  let _tmp = 0;
  let _tmp$2 = hash & self.capacity_mask;
  while (true) {
    const i = _tmp;
    const idx = _tmp$2;
    const _tmp$3 = self.entries;
    $bound_check(_tmp$3, idx);
    const _bind$3 = _tmp$3[idx];
    if (_bind$3 === undefined) {
      break;
    } else {
      const _Some = _bind$3;
      const _entry = _Some;
      if (_entry.hash === hash && _entry.key === key) {
        _M0MP311moonbitlang4core7builtin3Map13remove__entryGisE(self, _entry);
        _M0MP311moonbitlang4core7builtin3Map11shift__backGisE(self, idx);
        self.size = self.size - 1 | 0;
        break;
      }
      if (i > _entry.psl) {
        break;
      }
      _tmp = i + 1 | 0;
      _tmp$2 = idx + 1 & self.capacity_mask;
      continue;
    }
  }
}
function _M0MP311moonbitlang4core7builtin3Map6removeGiRP26mizchi8markdown8DocumentE(self, key) {
  _M0MP311moonbitlang4core7builtin3Map18remove__with__hashGiRP26mizchi8markdown8DocumentE(self, key, _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(key));
}
function _M0MP311moonbitlang4core7builtin3Map6removeGisE(self, key) {
  _M0MP311moonbitlang4core7builtin3Map18remove__with__hashGisE(self, key, _M0IP016_24default__implP311moonbitlang4core7builtin4Hash4hashGiE(key));
}
function _M0MP311moonbitlang4core7builtin3Map4iterGsRP311moonbitlang4core7builtin4JsonE(self) {
  const curr_entry = { val: self.head };
  const _p = () => {
    const _bind$3 = curr_entry.val;
    if (_bind$3 === undefined) {
      return undefined;
    } else {
      const _Some = _bind$3;
      const _x = _Some;
      const _key = _x.key;
      const _value = _x.value;
      const _next = _x.next;
      curr_entry.val = _next;
      return { _0: _key, _1: _value };
    }
  };
  return _p;
}
function _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(self) {
  if (self) {
    const _p = true;
    return _p ? $64$moonbitlang$47$core$47$builtin$46$Json$True : $64$moonbitlang$47$core$47$builtin$46$Json$False;
  } else {
    const _p = false;
    return _p ? $64$moonbitlang$47$core$47$builtin$46$Json$True : $64$moonbitlang$47$core$47$builtin$46$Json$False;
  }
}
function _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin6ToJson8to__json(self) {
  const _p = self + 0;
  const _p$2 = undefined;
  return new $64$moonbitlang$47$core$47$builtin$46$Json$Number(_p, _p$2);
}
function _M0MP311moonbitlang4core7builtin5Iter24nextGicE(self) {
  return _M0MP311moonbitlang4core7builtin4Iter4nextGUicEE(self);
}
function _M0MP311moonbitlang4core7builtin7MyInt644land(self, other) {
  return { hi: self.hi & other.hi, lo: self.lo & other.lo };
}
function _M0MP311moonbitlang4core7builtin7MyInt643lor(self, other) {
  return { hi: self.hi | other.hi, lo: self.lo | other.lo };
}
function _M0MP311moonbitlang4core7builtin7MyInt643lsl(self, shift) {
  const shift$2 = shift & 63;
  if (shift$2 === 0) {
    return self;
  } else {
    if (shift$2 < 32) {
      const _hi = self.hi;
      const _lo = self.lo;
      const hi = _hi;
      const lo = _lo;
      const hi$2 = hi << shift$2 | (lo >>> (32 - shift$2 | 0) | 0);
      const lo$2 = lo << shift$2;
      return { hi: hi$2, lo: lo$2 };
    } else {
      return { hi: self.lo << (shift$2 - 32 | 0), lo: 0 };
    }
  }
}
function _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin2Eq5equal(self, other) {
  const _p = self;
  const _p$2 = other;
  return _p.hi === _p$2.hi && _p.lo === _p$2.lo;
}
function _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin6BitAnd4land(self, other) {
  return _M0MP311moonbitlang4core7builtin7MyInt644land(self, other);
}
function _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin5BitOr3lor(self, other) {
  return _M0MP311moonbitlang4core7builtin7MyInt643lor(self, other);
}
function _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin3Shl3shl(self, shift) {
  return _M0MP311moonbitlang4core7builtin7MyInt643lsl(self, shift);
}
function _M0MP311moonbitlang4core7builtin6Hasher15combine__string(self, value) {
  const _end2501 = value.length;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _end2501) {
      _M0MP311moonbitlang4core7builtin6Hasher13combine__uint(self, value.charCodeAt(i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0IP311moonbitlang4core6string6StringP311moonbitlang4core7builtin4Hash13hash__combine(self, hasher) {
  _M0MP311moonbitlang4core7builtin6Hasher15combine__string(hasher, self);
}
function _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin4Hash13hash__combine(self, hasher) {
  _M0MP311moonbitlang4core7builtin6Hasher12combine__int(hasher, self);
}
function _M0MP311moonbitlang4core6double6Double10to__string(self) {
  return _M0FP311moonbitlang4core7builtin15ryu__to__string(self);
}
function _M0IP311moonbitlang4core6double6DoubleP311moonbitlang4core7builtin4Show6output(self, logger) {
  logger.method_table.method_0(logger.self, _M0MP311moonbitlang4core6double6Double10to__string(self));
}
function _M0IP311moonbitlang4core7builtin13SourceLocReprP311moonbitlang4core7builtin4Show6output(self, logger) {
  const pkg = self.pkg;
  const _data = pkg.str;
  const _start = pkg.start;
  const _end = _start + (pkg.end - pkg.start | 0) | 0;
  let _cursor = _start;
  let accept_state = -1;
  let match_end = -1;
  let match_tag_saver_0 = -1;
  let tag_0 = -1;
  let _bind$3;
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
                      const _p$3 = _cursor;
                      _data.charCodeAt(_p$3);
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
      const package_name = _M0MP311moonbitlang4core6string6String4view(_data, match_tag_saver_0 + 1 | 0, match_end);
      const module_name = _M0MP311moonbitlang4core6string6String4view(_data, _start, match_tag_saver_0);
      _bind$3 = { _0: module_name, _1: package_name };
    } else {
      _bind$3 = { _0: pkg, _1: undefined };
    }
  }
  const _module_name = _bind$3._0;
  const _package_name = _bind$3._1;
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
function _M0IP311moonbitlang4core7builtin9SourceLocP311moonbitlang4core7builtin4Show6output(self, logger) {
  _M0IP311moonbitlang4core7builtin13SourceLocReprP311moonbitlang4core7builtin4Show6output(_M0MP311moonbitlang4core7builtin13SourceLocRepr5parse(self), logger);
}
function _M0MP311moonbitlang4core5array5Array11unsafe__popGRP311moonbitlang4core4json10WriteFrameE(self) {
  return _M0MP311moonbitlang4core7builtin7JSArray3pop(self);
}
function _M0MP311moonbitlang4core5array5Array11unsafe__popGRP26mizchi8markdown6InlineE(self) {
  return _M0MP311moonbitlang4core7builtin7JSArray3pop(self);
}
function _M0MP311moonbitlang4core5array5Array3popGRP311moonbitlang4core4json10WriteFrameE(self) {
  if (self.length === 0) {
    return undefined;
  } else {
    const v = _M0MP311moonbitlang4core5array5Array11unsafe__popGRP311moonbitlang4core4json10WriteFrameE(self);
    return v;
  }
}
function _M0MP311moonbitlang4core5array5Array3popGRP26mizchi8markdown6InlineE(self) {
  if (self.length === 0) {
    return undefined;
  } else {
    const v = _M0MP311moonbitlang4core5array5Array11unsafe__popGRP26mizchi8markdown6InlineE(self);
    return v;
  }
}
function _M0MP311moonbitlang4core5array5Array6removeGsE(self, index) {
  if (index >= 0 && index < self.length) {
    $bound_check(self, index);
    const value = self[index];
    _M0MP311moonbitlang4core7builtin7JSArray6splice(self, index, 1);
    return value;
  } else {
    return _M0FP311moonbitlang4core7builtin5abortGsE(`index out of bounds: the len is from 0 to ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(self.length)} but the index is ${_M0IP016_24default__implP311moonbitlang4core7builtin4Show10to__stringGiE(index)}`, "@moonbitlang/core/builtin:arraycore_js.mbt:251:5-253:6");
  }
}
function _M0MP311moonbitlang4core5array5Array4copyGUiicbEE(self) {
  return _M0MP311moonbitlang4core7builtin7JSArray4copy(self);
}
function _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, i, j) {
  const temp = _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, i);
  _M0MP311moonbitlang4core5array12MutArrayView3setGUiicbEE(arr, i, _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j));
  _M0MP311moonbitlang4core5array12MutArrayView3setGUiicbEE(arr, j, temp);
}
function _M0MP311moonbitlang4core5array12MutArrayView5sliceGUiicbEE(arr, start, end) {
  return _M0MP311moonbitlang4core5array12MutArrayView17mut__view_2einnerGUiicbEE(arr, start, end);
}
function _M0MP311moonbitlang4core5array12MutArrayView14rev__in__placeGUiicbEE(arr) {
  const len = arr.end - arr.start | 0;
  const mid_len = len / 2 | 0;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < mid_len) {
      const j = (len - i | 0) - 1 | 0;
      const temp = _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, i);
      _M0MP311moonbitlang4core5array12MutArrayView3setGUiicbEE(arr, i, _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j));
      _M0MP311moonbitlang4core5array12MutArrayView3setGUiicbEE(arr, j, temp);
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP311moonbitlang4core7builtin17fixed__get__limit(len) {
  let len$2 = len;
  let limit = 0;
  while (true) {
    if (len$2 > 0) {
      len$2 = len$2 / 2 | 0;
      limit = limit + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return limit;
}
function _M0FP311moonbitlang4core7builtin23fixed__bubble__sort__byGUiicbEE(arr, cmp) {
  const _end540 = arr.end - arr.start | 0;
  let _tmp = 1;
  while (true) {
    const i = _tmp;
    if (i < _end540) {
      let _tmp$2 = i;
      while (true) {
        const j = _tmp$2;
        if (j > 0 && cmp(_M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j - 1 | 0), _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j)) > 0) {
          _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, j, j - 1 | 0);
          _tmp$2 = j - 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__2_2f1023(_env, a, b) {
  const cmp = _env._2;
  const swaps = _env._1;
  const arr = _env._0;
  if (cmp(_M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, a), _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, b)) > 0) {
    _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, a, b);
    swaps.val = swaps.val + 1 | 0;
    return;
  } else {
    return;
  }
}
function _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__3_2f1024(_env, a, b, c) {
  _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__2_2f1023(_env, a, b);
  _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__2_2f1023(_env, b, c);
  _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__2_2f1023(_env, a, b);
}
function _M0FP311moonbitlang4core7builtin24fixed__choose__pivot__byGUiicbEE(arr, cmp) {
  const len = arr.end - arr.start | 0;
  const swaps = { val: 0 };
  const b = Math.imul(len / 4 | 0, 2) | 0;
  if (len >= 8) {
    const a = Math.imul(len / 4 | 0, 1) | 0;
    const c = Math.imul(len / 4 | 0, 3) | 0;
    const _env = { _0: arr, _1: swaps, _2: cmp };
    if (len > 50) {
      _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__3_2f1024(_env, a - 1 | 0, a, a + 1 | 0);
      _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__3_2f1024(_env, b - 1 | 0, b, b + 1 | 0);
      _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__3_2f1024(_env, c - 1 | 0, c, c + 1 | 0);
    }
    _M0FP311moonbitlang4core7builtin41fixed__choose__pivot__by_2esort__3_2f1024(_env, a, b, c);
  }
  if (swaps.val === 12) {
    _M0MP311moonbitlang4core5array12MutArrayView14rev__in__placeGUiicbEE(arr);
    return { _0: (len - b | 0) - 1 | 0, _1: true };
  } else {
    return { _0: b, _1: swaps.val === 0 };
  }
}
function _M0FP311moonbitlang4core7builtin21fixed__sift__down__byGUiicbEE(arr, index, cmp) {
  let index$2 = index;
  const len = arr.end - arr.start | 0;
  let child = (Math.imul(index$2, 2) | 0) + 1 | 0;
  while (true) {
    if (child < len) {
      if ((child + 1 | 0) < len && cmp(_M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, child), _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, child + 1 | 0)) < 0) {
        child = child + 1 | 0;
      }
      if (cmp(_M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, index$2), _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, child)) >= 0) {
        return undefined;
      }
      _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, index$2, child);
      index$2 = child;
      child = (Math.imul(index$2, 2) | 0) + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP311moonbitlang4core7builtin21fixed__heap__sort__byGUiicbEE(arr, cmp) {
  const len = arr.end - arr.start | 0;
  let _tmp = (len / 2 | 0) - 1 | 0;
  while (true) {
    const i = _tmp;
    if (i >= 0) {
      _M0FP311moonbitlang4core7builtin21fixed__sift__down__byGUiicbEE(arr, i, cmp);
      _tmp = i - 1 | 0;
      continue;
    } else {
      break;
    }
  }
  let _tmp$2 = len - 1 | 0;
  while (true) {
    const i = _tmp$2;
    if (i > 0) {
      _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, 0, i);
      _M0FP311moonbitlang4core7builtin21fixed__sift__down__byGUiicbEE(_M0MP311moonbitlang4core5array12MutArrayView5sliceGUiicbEE(arr, 0, i), 0, cmp);
      _tmp$2 = i - 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP311moonbitlang4core7builtin20fixed__partition__byGUiicbEE(arr, cmp, pivot_index) {
  _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, pivot_index, (arr.end - arr.start | 0) - 1 | 0);
  const pivot = _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, (arr.end - arr.start | 0) - 1 | 0);
  let i = 0;
  let partitioned = true;
  const _end529 = (arr.end - arr.start | 0) - 1 | 0;
  let _tmp = 0;
  while (true) {
    const j = _tmp;
    if (j < _end529) {
      if (cmp(_M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j), pivot) < 0) {
        if (i !== j) {
          _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, i, j);
          partitioned = false;
        }
        i = i + 1 | 0;
      }
      _tmp = j + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, i, (arr.end - arr.start | 0) - 1 | 0);
  return { _0: i, _1: partitioned };
}
function _M0FP311moonbitlang4core7builtin28fixed__try__bubble__sort__byGUiicbEE(arr, cmp) {
  let tries = 0;
  const _end550 = arr.end - arr.start | 0;
  let _tmp = 1;
  while (true) {
    const i = _tmp;
    if (i < _end550) {
      let sorted = true;
      let _tmp$2 = i;
      while (true) {
        const j = _tmp$2;
        if (j > 0 && cmp(_M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j - 1 | 0), _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr, j)) > 0) {
          sorted = false;
          _M0MP311moonbitlang4core5array12MutArrayView4swapGUiicbEE(arr, j, j - 1 | 0);
          _tmp$2 = j - 1 | 0;
          continue;
        } else {
          break;
        }
      }
      if (!sorted) {
        tries = tries + 1 | 0;
        if (tries > 8) {
          return false;
        }
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0FP311moonbitlang4core7builtin22fixed__quick__sort__byGUiicbEE(arr, cmp, pred, limit) {
  let limit$2 = limit;
  let arr$2 = arr;
  let pred$2 = pred;
  let was_partitioned = true;
  let balanced = true;
  while (true) {
    const _p = arr$2;
    const len = _p.end - _p.start | 0;
    if (len <= 16) {
      if (len >= 2) {
        _M0FP311moonbitlang4core7builtin23fixed__bubble__sort__byGUiicbEE(arr$2, cmp);
      }
      return undefined;
    }
    if (limit$2 === 0) {
      _M0FP311moonbitlang4core7builtin21fixed__heap__sort__byGUiicbEE(arr$2, cmp);
      return undefined;
    }
    const _bind$3 = _M0FP311moonbitlang4core7builtin24fixed__choose__pivot__byGUiicbEE(arr$2, cmp);
    const _pivot_index = _bind$3._0;
    const _likely_sorted = _bind$3._1;
    if (was_partitioned && (balanced && _likely_sorted)) {
      if (_M0FP311moonbitlang4core7builtin28fixed__try__bubble__sort__byGUiicbEE(arr$2, cmp)) {
        return undefined;
      }
    }
    const _bind$4 = _M0FP311moonbitlang4core7builtin20fixed__partition__byGUiicbEE(arr$2, cmp, _pivot_index);
    const _pivot = _bind$4._0;
    const _partitioned = _bind$4._1;
    was_partitioned = _partitioned;
    const _p$2 = len - _pivot | 0;
    balanced = (_pivot > _p$2 ? _p$2 : _pivot) >= (len / 8 | 0);
    if (!balanced) {
      limit$2 = limit$2 - 1 | 0;
    }
    const _bind$5 = pred$2;
    if (_bind$5 === undefined) {
    } else {
      const _Some = _bind$5;
      const _pred = _Some;
      if (cmp(_pred, _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr$2, _pivot)) === 0) {
        let i = _pivot;
        while (true) {
          if (i < len && cmp(_pred, _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr$2, i)) === 0) {
            i = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        arr$2 = _M0MP311moonbitlang4core5array12MutArrayView5sliceGUiicbEE(arr$2, i, len);
        continue;
      }
    }
    const left = _M0MP311moonbitlang4core5array12MutArrayView5sliceGUiicbEE(arr$2, 0, _pivot);
    const right = _M0MP311moonbitlang4core5array12MutArrayView5sliceGUiicbEE(arr$2, _pivot + 1 | 0, len);
    if ((left.end - left.start | 0) < (right.end - right.start | 0)) {
      _M0FP311moonbitlang4core7builtin22fixed__quick__sort__byGUiicbEE(left, cmp, pred$2, limit$2);
      pred$2 = _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr$2, _pivot);
      arr$2 = right;
    } else {
      _M0FP311moonbitlang4core7builtin22fixed__quick__sort__byGUiicbEE(right, cmp, _M0MP311moonbitlang4core5array12MutArrayView2atGUiicbEE(arr$2, _pivot), limit$2);
      arr$2 = left;
    }
    continue;
  }
}
function _M0MP311moonbitlang4core5array12MutArrayView8sort__byGUiicbEE(self, cmp) {
  _M0FP311moonbitlang4core7builtin22fixed__quick__sort__byGUiicbEE(self, cmp, undefined, _M0FP311moonbitlang4core7builtin17fixed__get__limit(self.end - self.start | 0));
}
function _M0MP311moonbitlang4core5array5Array8sort__byGUiicbEE(self, cmp) {
  _M0MP311moonbitlang4core5array12MutArrayView8sort__byGUiicbEE(_M0MP311moonbitlang4core5array5Array17mut__view_2einnerGUiicbEE(self, 0, undefined), cmp);
}
function _M0MP311moonbitlang4core5array5Array4lastGRP26mizchi8markdown6InlineE(self) {
  if (self.length === 0) {
    return undefined;
  } else {
    const _last = self[self.length - 1 | 0];
    return _last;
  }
}
function _M0FP311moonbitlang4core4json6escape(str, escape_slash) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(str.length);
  const _it = _M0MP311moonbitlang4core6string6String4iter(str);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      switch (_c) {
        case 34: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\\"");
          break;
        }
        case 92: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\\\");
          break;
        }
        case 47: {
          if (escape_slash) {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\/");
          } else {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
          }
          break;
        }
        case 10: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\n");
          break;
        }
        case 13: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\r");
          break;
        }
        case 8: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\b");
          break;
        }
        case 9: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\t");
          break;
        }
        default: {
          const code = _c;
          if (code === 12) {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\f");
          } else {
            if (code < 32) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\u00");
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0MP311moonbitlang4core4byte4Byte7to__hex(code & 255));
            } else {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
            }
          }
        }
      }
      continue;
    }
  }
  return buf.val;
}
function _M0FP311moonbitlang4core4json11indent__str(level, indent) {
  if (indent === 0) {
    return "";
  } else {
    const spaces = Math.imul(indent, level) | 0;
    switch (spaces) {
      case 0: {
        return "\n";
      }
      case 1: {
        return "\n ";
      }
      case 2: {
        return "\n  ";
      }
      case 3: {
        return "\n   ";
      }
      case 4: {
        return "\n    ";
      }
      case 5: {
        return "\n     ";
      }
      case 6: {
        return "\n      ";
      }
      case 7: {
        return "\n       ";
      }
      case 8: {
        return "\n        ";
      }
      default: {
        return `\n${_M0MP311moonbitlang4core6string6String6repeat(" ", spaces)}`;
      }
    }
  }
}
function _M0MP311moonbitlang4core4json4Json17stringify_2einner(self, escape_slash, indent, replacer) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const stack = [];
  let depth = 0;
  let _tmp = self;
  while (true) {
    const _param = _tmp;
    if (_param === undefined) {
      if (stack.length === 0) {
        break;
      } else {
        const _x = stack[stack.length - 1 | 0];
        if (_x.$tag === 0) {
          const _Array = _x;
          const _arr = _Array._0;
          const _i = _Array._1;
          if (_i < _arr.length) {
            const element = _M0MP311moonbitlang4core5array5Array2atGRP311moonbitlang4core7builtin4JsonE(_arr, _i);
            _Array._1 = _i + 1 | 0;
            if (_i > 0) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 44);
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json11indent__str(depth, indent));
            }
            _tmp = element;
            continue;
          } else {
            depth = depth - 1 | 0;
            _M0MP311moonbitlang4core5array5Array3popGRP311moonbitlang4core4json10WriteFrameE(stack);
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json11indent__str(depth, indent));
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 93);
            _tmp = undefined;
            continue;
          }
        } else {
          const _Object = _x;
          const _iterator = _Object._0;
          const _first = _Object._1;
          const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGUsRP311moonbitlang4core7builtin4JsonEE(_iterator);
          if (_bind$3 === undefined) {
            depth = depth - 1 | 0;
            _M0MP311moonbitlang4core5array5Array3popGRP311moonbitlang4core4json10WriteFrameE(stack);
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json11indent__str(depth, indent));
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 125);
            _tmp = undefined;
            continue;
          } else {
            const _Some = _bind$3;
            const _x$2 = _Some;
            const _k = _x$2._0;
            const _v = _x$2._1;
            let v2 = _v;
            if (replacer === undefined) {
            } else {
              const _Some$2 = replacer;
              const _replacer = _Some$2;
              const _func = _replacer;
              const _bind$4 = _func(_k, _v);
              if (_bind$4 === undefined) {
                _tmp = undefined;
                continue;
              } else {
                const _Some$3 = _bind$4;
                const _v$2 = _Some$3;
                v2 = _v$2;
              }
            }
            if (!_first) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 44);
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json11indent__str(depth, indent));
            }
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json6escape(_k, escape_slash));
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 58);
            if (indent > 0) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 32);
            }
            _Object._1 = false;
            _tmp = v2;
            continue;
          }
        }
      }
    } else {
      const _Some = _param;
      const _value = _Some;
      switch (_value.$tag) {
        case 6: {
          const _Object = _value;
          const _members = _Object._0;
          if (_members.size === 0) {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "{}");
          } else {
            depth = depth + 1 | 0;
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 123);
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json11indent__str(depth, indent));
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core4json10WriteFrameE(stack, new $64$moonbitlang$47$core$47$json$46$WriteFrame$Object(_M0MP311moonbitlang4core7builtin3Map4iterGsRP311moonbitlang4core7builtin4JsonE(_members), true));
          }
          break;
        }
        case 5: {
          const _Array = _value;
          const _arr = _Array._0;
          if (_arr.length === 0) {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[]");
          } else {
            depth = depth + 1 | 0;
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 91);
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json11indent__str(depth, indent));
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core4json10WriteFrameE(stack, new $64$moonbitlang$47$core$47$json$46$WriteFrame$Array(_arr, 0));
          }
          break;
        }
        case 4: {
          const _String = _value;
          const _s = _String._0;
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP311moonbitlang4core4json6escape(_s, escape_slash));
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
          break;
        }
        case 3: {
          const _Number = _value;
          const _n = _Number._0;
          const _repr = _Number._1;
          if (_repr === undefined) {
            _M0MP311moonbitlang4core7builtin13StringBuilder13write__objectGdE(buf, _n);
          } else {
            const _Some$2 = _repr;
            const _r = _Some$2;
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _r);
          }
          break;
        }
        case 1: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "true");
          break;
        }
        case 2: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "false");
          break;
        }
        default: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "null");
        }
      }
      _tmp = undefined;
      continue;
    }
  }
  return buf.val;
}
function _M0MP311moonbitlang4core3ref3Ref3newGiE(x) {
  return { val: x };
}
function _M0IP26mizchi8markdown16OrderedDelimiterP311moonbitlang4core7builtin2Eq5equal(_x_1806, _x_1807) {
  if (_x_1806 === 0) {
    if (_x_1807 === 0) {
      return true;
    } else {
      return false;
    }
  } else {
    if (_x_1807 === 1) {
      return true;
    } else {
      return false;
    }
  }
}
function _M0IP26mizchi8markdown12BulletMarkerP311moonbitlang4core7builtin2Eq5equal(_x_1766, _x_1767) {
  switch (_x_1766) {
    case 0: {
      if (_x_1767 === 0) {
        return true;
      } else {
        return false;
      }
    }
    case 1: {
      if (_x_1767 === 1) {
        return true;
      } else {
        return false;
      }
    }
    default: {
      if (_x_1767 === 2) {
        return true;
      } else {
        return false;
      }
    }
  }
}
function _M0MP26mizchi8markdown4Span3new(from, to) {
  return { from: from, to: to };
}
function _M0MP26mizchi8markdown6Trivia3new(content) {
  return { content: content };
}
function _M0FP26mizchi8markdown19calc__fence__length(code) {
  let fence_len = 3;
  let count = 0;
  const _it = _M0MP311moonbitlang4core6string6String4iter(code);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      if (_c === 96) {
        count = count + 1 | 0;
      } else {
        if (count >= fence_len) {
          fence_len = count + 1 | 0;
        }
        count = 0;
      }
      continue;
    }
  }
  if (count >= fence_len) {
    fence_len = count + 1 | 0;
  }
  return fence_len;
}
function _M0FP26mizchi8markdown27calc__code__span__backticks(content) {
  let run_mask = $0L;
  let max_run = 0;
  let current_run = 0;
  const _it = _M0MP311moonbitlang4core6string6String4iter(content);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      if (_c === 96) {
        current_run = current_run + 1 | 0;
      } else {
        if (current_run > 0) {
          if (current_run <= 63) {
            run_mask = _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin5BitOr3lor(run_mask, _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin3Shl3shl($1L, current_run));
          }
          if (current_run > max_run) {
            max_run = current_run;
          }
          current_run = 0;
        }
      }
      continue;
    }
  }
  if (current_run > 0) {
    if (current_run <= 63) {
      run_mask = _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin5BitOr3lor(run_mask, _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin3Shl3shl($1L, current_run));
    }
    if (current_run > max_run) {
      max_run = current_run;
    }
  }
  let n = 1;
  while (true) {
    if (n <= 63 && _M0IP016_24default__implP311moonbitlang4core7builtin2Eq10not__equalGmE(_M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin6BitAnd4land(run_mask, _M0IP311moonbitlang4core6uint646UInt64P311moonbitlang4core7builtin3Shl3shl($1L, n)), $0L)) {
      n = n + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return n > 63 ? max_run + 1 | 0 : n;
}
function _M0FP26mizchi8markdown12write__chars(buf, c, n) {
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < n) {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, c);
      _tmp = i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP26mizchi8markdown18serialize__inlines(inlines, buf) {
  const _len = inlines.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const inline = inlines[_i];
      _M0FP26mizchi8markdown17serialize__inline(inline, buf);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP26mizchi8markdown17serialize__inline(inline, buf) {
  switch (inline.$tag) {
    case 0: {
      const _Text = inline;
      const _content = _Text._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _content);
      return;
    }
    case 1: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      return;
    }
    case 2: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\\n");
      return;
    }
    case 3: {
      const _Emphasis = inline;
      const _children = _Emphasis._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 42);
      _M0FP26mizchi8markdown18serialize__inlines(_children, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 42);
      return;
    }
    case 4: {
      const _Strong = inline;
      const _children$2 = _Strong._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "**");
      _M0FP26mizchi8markdown18serialize__inlines(_children$2, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "**");
      return;
    }
    case 5: {
      const _Strikethrough = inline;
      const _children$3 = _Strikethrough._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "~~");
      _M0FP26mizchi8markdown18serialize__inlines(_children$3, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "~~");
      return;
    }
    case 6: {
      const _Code = inline;
      const _content$2 = _Code._0;
      const backticks = _M0FP26mizchi8markdown27calc__code__span__backticks(_content$2);
      _M0FP26mizchi8markdown12write__chars(buf, 96, backticks);
      let needs_padding;
      if (_content$2.length > 0) {
        const first = _M0MP311moonbitlang4core6string6String9get__char(_content$2, 0);
        const last = _M0MP311moonbitlang4core6string6String9get__char(_content$2, _content$2.length - 1 | 0);
        needs_padding = _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(first, _M0FP26mizchi8markdown33serialize__inline_2econstr_2f1210) || _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(last, _M0FP26mizchi8markdown33serialize__inline_2econstr_2f1211);
      } else {
        needs_padding = false;
      }
      if (needs_padding) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 32);
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _content$2);
      if (needs_padding) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 32);
      }
      _M0FP26mizchi8markdown12write__chars(buf, 96, backticks);
      return;
    }
    case 7: {
      const _Link = inline;
      const _children$4 = _Link._0;
      const _url = _Link._1;
      const _title = _Link._2;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 91);
      _M0FP26mizchi8markdown18serialize__inlines(_children$4, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "](");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _url);
      if (!(_title === "")) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " \"");
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _title);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 41);
      return;
    }
    case 8: {
      const _RefLink = inline;
      const _children$5 = _RefLink._0;
      const _label = _RefLink._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 91);
      _M0FP26mizchi8markdown18serialize__inlines(_children$5, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "][");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _label);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 93);
      return;
    }
    case 9: {
      const _Autolink = inline;
      const _url$2 = _Autolink._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 60);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _url$2);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 62);
      return;
    }
    case 10: {
      const _Image = inline;
      const _alt = _Image._0;
      const _url$3 = _Image._1;
      const _title$2 = _Image._2;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "![");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _alt);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "](");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _url$3);
      if (!(_title$2 === "")) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " \"");
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _title$2);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 41);
      return;
    }
    case 11: {
      const _RefImage = inline;
      const _alt$2 = _RefImage._0;
      const _label$2 = _RefImage._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "![");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _alt$2);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "][");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _label$2);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 93);
      return;
    }
    case 12: {
      const _HtmlInline = inline;
      const _html = _HtmlInline._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _html);
      return;
    }
    default: {
      const _FootnoteReference = inline;
      const _label$3 = _FootnoteReference._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[^");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _label$3);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 93);
      return;
    }
  }
}
function _M0FP26mizchi8markdown30serialize__table__cell__inline(inline, buf) {
  if (inline.$tag === 0) {
    const _Text = inline;
    const _content = _Text._0;
    const _it = _M0MP311moonbitlang4core6string6String4iter(_content);
    while (true) {
      const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
      if (_bind$3 === -1) {
        return;
      } else {
        const _Some = _bind$3;
        const _c = _Some;
        if (_c === 124) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\\|");
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
        }
        continue;
      }
    }
  } else {
    _M0FP26mizchi8markdown17serialize__inline(inline, buf);
    return;
  }
}
function _M0FP26mizchi8markdown31serialize__table__cell__inlines(inlines, buf) {
  const _len = inlines.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const inline = inlines[_i];
      _M0FP26mizchi8markdown30serialize__table__cell__inline(inline, buf);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP26mizchi8markdown16serialize__block(block, buf) {
  switch (block.$tag) {
    case 0: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "***\n");
      return;
    }
    case 1: {
      const _Heading = block;
      const _level = _Heading._0;
      const _style = _Heading._1;
      const _children = _Heading._2;
      if (_style === 0) {
        _M0FP26mizchi8markdown12write__chars(buf, 35, _level);
        if (!(_children.length === 0)) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 32);
          _M0FP26mizchi8markdown18serialize__inlines(_children, buf);
        }
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
        return;
      } else {
        _M0FP26mizchi8markdown18serialize__inlines(_children, buf);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
        const underline_char = _level === 1 ? 61 : 45;
        _M0FP26mizchi8markdown12write__chars(buf, underline_char, 3);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
        return;
      }
    }
    case 2: {
      const _Paragraph = block;
      const _children$2 = _Paragraph._0;
      _M0FP26mizchi8markdown18serialize__inlines(_children$2, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      return;
    }
    case 3: {
      const _FencedCode = block;
      const _info = _FencedCode._2;
      const _code = _FencedCode._3;
      const fence_len = _M0FP26mizchi8markdown19calc__fence__length(_code);
      _M0FP26mizchi8markdown12write__chars(buf, 96, fence_len);
      if (!(_info === "")) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _info);
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _code);
      if (!(_code === "") && !_M0MP311moonbitlang4core6string6String11has__suffix(_code, { str: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1974, start: 0, end: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1974.length })) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      }
      _M0FP26mizchi8markdown12write__chars(buf, 96, fence_len);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      return;
    }
    case 4: {
      const _IndentedCode = block;
      const _code$2 = _IndentedCode._0;
      const fence_len$2 = _M0FP26mizchi8markdown19calc__fence__length(_code$2);
      _M0FP26mizchi8markdown12write__chars(buf, 96, fence_len$2);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _code$2);
      if (!(_code$2 === "") && !_M0MP311moonbitlang4core6string6String11has__suffix(_code$2, { str: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1975, start: 0, end: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1975.length })) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      }
      _M0FP26mizchi8markdown12write__chars(buf, 96, fence_len$2);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      return;
    }
    case 5: {
      const _Blockquote = block;
      const _children$3 = _Blockquote._0;
      const _len = _children$3.length;
      let _tmp = 0;
      while (true) {
        const _i = _tmp;
        if (_i < _len) {
          const child = _children$3[_i];
          const child_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
          _M0FP26mizchi8markdown16serialize__block(child, child_buf);
          const child_str = child_buf.val;
          const _it = _M0MP311moonbitlang4core6string6String5split(child_str, { str: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1985, start: 0, end: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1985.length });
          while (true) {
            const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGRP311moonbitlang4core6string10StringViewE(_it);
            if (_bind$3 === undefined) {
              break;
            } else {
              const _Some = _bind$3;
              const _line = _Some;
              const line_str = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_line);
              if (!(line_str === "")) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "> ");
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, line_str);
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
              }
              continue;
            }
          }
          _tmp = _i + 1 | 0;
          continue;
        } else {
          return;
        }
      }
    }
    case 6: {
      const _BulletList = block;
      const _items = _BulletList._2;
      _M0FP26mizchi8markdown30serialize__bullet__list__items(_items, buf, 0);
      return;
    }
    case 7: {
      const _OrderedList = block;
      const _start = _OrderedList._0;
      const _items$2 = _OrderedList._3;
      _M0FP26mizchi8markdown31serialize__ordered__list__items(_items$2, buf, 0, _start);
      return;
    }
    case 8: {
      const _HtmlBlock = block;
      const _html = _HtmlBlock._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _html);
      if (!_M0MP311moonbitlang4core6string6String11has__suffix(_html, { str: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1986, start: 0, end: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c1986.length })) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
        return;
      } else {
        return;
      }
    }
    case 9: {
      const _Table = block;
      const _header = _Table._0;
      const _alignments = _Table._1;
      const _rows = _Table._2;
      const _leading_trivia = _Table._4;
      const _trailing_trivia = _Table._5;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _leading_trivia.content);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 124);
      const _len$2 = _header.length;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const cell = _header[_i];
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 32);
          _M0FP26mizchi8markdown31serialize__table__cell__inlines(cell.children, buf);
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " |");
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 124);
      const _len$3 = _alignments.length;
      let _tmp$3 = 0;
      while (true) {
        const _i = _tmp$3;
        if (_i < _len$3) {
          const align = _alignments[_i];
          switch (align) {
            case 0: {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " :-- |");
              break;
            }
            case 1: {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " :-: |");
              break;
            }
            case 2: {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " --: |");
              break;
            }
            default: {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " --- |");
            }
          }
          _tmp$3 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      const _len$4 = _rows.length;
      let _tmp$4 = 0;
      while (true) {
        const _i = _tmp$4;
        if (_i < _len$4) {
          const row = _rows[_i];
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 124);
          const _len$5 = row.length;
          let _tmp$5 = 0;
          while (true) {
            const _i$2 = _tmp$5;
            if (_i$2 < _len$5) {
              const cell = row[_i$2];
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 32);
              _M0FP26mizchi8markdown31serialize__table__cell__inlines(cell.children, buf);
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " |");
              _tmp$5 = _i$2 + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
          _tmp$4 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _trailing_trivia.content);
      return;
    }
    case 10: {
      const _BlankLines = block;
      const _count = _BlankLines._0;
      let _tmp$5 = 0;
      while (true) {
        const i = _tmp$5;
        if (i < _count) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
          _tmp$5 = i + 1 | 0;
          continue;
        } else {
          return;
        }
      }
    }
    default: {
      const _FootnoteDefinition = block;
      const _label = _FootnoteDefinition._0;
      const _children$4 = _FootnoteDefinition._1;
      const _leading_trivia$2 = _FootnoteDefinition._3;
      const _trailing_trivia$2 = _FootnoteDefinition._4;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _leading_trivia$2.content);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[^");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _label);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "]: ");
      let first = true;
      const _len$5 = _children$4.length;
      let _tmp$6 = 0;
      while (true) {
        const _i = _tmp$6;
        if (_i < _len$5) {
          const child = _children$4[_i];
          if (!first) {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\n    ");
          }
          const child_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
          _M0FP26mizchi8markdown16serialize__block(child, child_buf);
          const child_str = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String17trim__end_2einner(child_buf.val, { str: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c2003, start: 0, end: _M0FP26mizchi8markdown33serialize__block_2e_2abind_7c2003.length }));
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, child_str);
          first = false;
          _tmp$6 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _trailing_trivia$2.content);
      return;
    }
  }
}
function _M0FP26mizchi8markdown30serialize__bullet__list__items(items, buf, indent) {
  const _len = items.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const item = items[_i];
      _M0FP26mizchi8markdown12write__chars(buf, 32, indent);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "* ");
      const _bind$3 = item.checked;
      if (_bind$3 === -1) {
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        if (_x === true) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[x] ");
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[ ] ");
        }
      }
      let first_block = true;
      const _arr = item.children;
      const _len$2 = _arr.length;
      let _tmp$2 = 0;
      while (true) {
        const _i$2 = _tmp$2;
        if (_i$2 < _len$2) {
          const child = _arr[_i$2];
          switch (child.$tag) {
            case 2: {
              const _Paragraph = child;
              const _para_children = _Paragraph._0;
              _M0FP26mizchi8markdown18serialize__inlines(_para_children, buf);
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
              first_block = false;
              break;
            }
            case 6: {
              const _BulletList = child;
              const _nested_items = _BulletList._2;
              if (first_block) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
              }
              _M0FP26mizchi8markdown30serialize__bullet__list__items(_nested_items, buf, indent + 2 | 0);
              break;
            }
            default: {
              _M0FP26mizchi8markdown16serialize__block(child, buf);
              first_block = false;
            }
          }
          _tmp$2 = _i$2 + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      if (first_block) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP26mizchi8markdown31serialize__ordered__list__items(items, buf, indent, start) {
  let num = start;
  const _len = items.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const item = items[_i];
      _M0FP26mizchi8markdown12write__chars(buf, 32, indent);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0MP311moonbitlang4core3int3Int18to__string_2einner(num, 10));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, ". ");
      const _bind$3 = item.checked;
      if (_bind$3 === -1) {
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        if (_x === true) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[x] ");
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "[ ] ");
        }
      }
      let first_block = true;
      const _arr = item.children;
      const _len$2 = _arr.length;
      let _tmp$2 = 0;
      while (true) {
        const _i$2 = _tmp$2;
        if (_i$2 < _len$2) {
          const child = _arr[_i$2];
          switch (child.$tag) {
            case 2: {
              const _Paragraph = child;
              const _para_children = _Paragraph._0;
              _M0FP26mizchi8markdown18serialize__inlines(_para_children, buf);
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
              first_block = false;
              break;
            }
            case 6: {
              const _BulletList = child;
              const _nested_items = _BulletList._2;
              if (first_block) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
              }
              _M0FP26mizchi8markdown30serialize__bullet__list__items(_nested_items, buf, indent + 3 | 0);
              break;
            }
            case 7: {
              const _OrderedList = child;
              const _nested_items$2 = _OrderedList._3;
              const _nested_start = _OrderedList._0;
              if (first_block) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
              }
              _M0FP26mizchi8markdown31serialize__ordered__list__items(_nested_items$2, buf, indent + 3 | 0, _nested_start);
              break;
            }
            default: {
              _M0FP26mizchi8markdown16serialize__block(child, buf);
              first_block = false;
            }
          }
          _tmp$2 = _i$2 + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      if (first_block) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      }
      num = num + 1 | 0;
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP26mizchi8markdown22serialize__frontmatter(fm, buf) {
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "---\n");
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, fm.raw);
  if (!_M0MP311moonbitlang4core6string6String11has__suffix(fm.raw, { str: _M0FP26mizchi8markdown39serialize__frontmatter_2e_2abind_7c2088, start: 0, end: _M0FP26mizchi8markdown39serialize__frontmatter_2e_2abind_7c2088.length })) {
    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
  }
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "---\n");
}
function _M0FP26mizchi8markdown9serialize(doc) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const _bind$3 = doc.frontmatter;
  if (_bind$3 === undefined) {
  } else {
    const _Some = _bind$3;
    const _fm = _Some;
    _M0FP26mizchi8markdown22serialize__frontmatter(_fm, buf);
  }
  let first = true;
  const _arr = doc.children;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      _L: {
        const block = _arr[_i];
        if (block.$tag === 10) {
          break _L;
        }
        if (!first) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
        }
        first = false;
        _M0FP26mizchi8markdown16serialize__block(block, buf);
        break _L;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return buf.val;
}
function _M0MP26mizchi8markdown7Scanner3new(source) {
  const chars = _M0MP311moonbitlang4core6string6String9to__array(source);
  const len = chars.length;
  const has_non_bmp = source.length !== len;
  let utf16_offsets;
  if (has_non_bmp) {
    const offsets = _M0MP311moonbitlang4core5array5Array4makeGiE(len + 1 | 0, 0);
    let utf16_pos = 0;
    let _tmp = 0;
    while (true) {
      const i = _tmp;
      if (i < len) {
        _M0MP311moonbitlang4core5array5Array3setGiE(offsets, i, utf16_pos);
        const _p = _M0MP311moonbitlang4core5array5Array2atGcE(chars, i);
        if (_p > 65535) {
          utf16_pos = utf16_pos + 2 | 0;
        } else {
          utf16_pos = utf16_pos + 1 | 0;
        }
        _tmp = i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
    _M0MP311moonbitlang4core5array5Array3setGiE(offsets, len, utf16_pos);
    utf16_offsets = new Option$Some$1$(offsets);
  } else {
    utf16_offsets = Option$None$1$;
  }
  return { source: source, chars: chars, pos: 0, len: len, utf16_offsets: utf16_offsets };
}
function _M0MP26mizchi8markdown7Scanner16to__utf16__index(self, cp_index) {
  const _bind$3 = self.utf16_offsets;
  if (_bind$3.$tag === 1) {
    const _Some = _bind$3;
    const _offsets = _Some._0;
    return _M0MP311moonbitlang4core5array5Array2atGiE(_offsets, cp_index);
  } else {
    return cp_index;
  }
}
function _M0MP26mizchi8markdown7Scanner4peek(self) {
  return self.pos >= self.len ? -1 : _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, self.pos);
}
function _M0MP26mizchi8markdown7Scanner8peek__at(self, offset) {
  const idx = self.pos + offset | 0;
  return idx >= self.len || idx < 0 ? -1 : _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, idx);
}
function _M0MP26mizchi8markdown7Scanner7advance(self, n) {
  self.pos = self.pos + n | 0;
  if (self.pos > self.len) {
    self.pos = self.len;
    return;
  } else {
    return;
  }
}
function _M0MP26mizchi8markdown7Scanner7consume(self) {
  if (self.pos >= self.len) {
    return -1;
  } else {
    const c = _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, self.pos);
    self.pos = self.pos + 1 | 0;
    return c;
  }
}
function _M0MP26mizchi8markdown7Scanner9substring(self, start, end) {
  const clamped_start = start < 0 ? 0 : start > self.len ? self.len : start;
  const clamped_end = end < 0 ? 0 : end > self.len ? self.len : end;
  if (clamped_start >= clamped_end) {
    return "";
  } else {
    const utf16_start = _M0MP26mizchi8markdown7Scanner16to__utf16__index(self, clamped_start);
    const utf16_end = _M0MP26mizchi8markdown7Scanner16to__utf16__index(self, clamped_end);
    return self.source.substring(utf16_start, utf16_end);
  }
}
function _M0MP26mizchi8markdown7Scanner12skip__spaces(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, self.pos);
      if (c === 32 || c === 9) {
        self.pos = self.pos + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return self.pos - start | 0;
}
function _M0MP26mizchi8markdown7Scanner22count__leading__spaces(self) {
  let count = 0;
  let idx = self.pos;
  while (true) {
    if (idx < self.len) {
      const c = _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, idx);
      if (c === 32) {
        count = count + 1 | 0;
        idx = idx + 1 | 0;
      } else {
        if (c === 9) {
          count = Math.imul((count / 4 | 0) + 1 | 0, 4) | 0;
          idx = idx + 1 | 0;
        } else {
          break;
        }
      }
      continue;
    } else {
      break;
    }
  }
  return count;
}
function _M0MP26mizchi8markdown7Scanner10read__line(self) {
  const start = self.pos;
  while (true) {
    if (self.pos < self.len) {
      if (_M0MP311moonbitlang4core5array5Array2atGcE(self.chars, self.pos) === 10) {
        break;
      }
      self.pos = self.pos + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const utf16_start = _M0MP26mizchi8markdown7Scanner16to__utf16__index(self, start);
  const utf16_end = _M0MP26mizchi8markdown7Scanner16to__utf16__index(self, self.pos);
  return self.source.substring(utf16_start, utf16_end);
}
function _M0MP26mizchi8markdown7Scanner10skip__line(self) {
  while (true) {
    if (self.pos < self.len) {
      const c = _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, self.pos);
      self.pos = self.pos + 1 | 0;
      if (c === 10) {
        break;
      }
      continue;
    } else {
      return;
    }
  }
}
function _M0MP26mizchi8markdown7Scanner15is__blank__line(self) {
  let idx = self.pos;
  while (true) {
    if (idx < self.len) {
      const c = _M0MP311moonbitlang4core5array5Array2atGcE(self.chars, idx);
      if (c === 10) {
        return true;
      }
      if (c !== 32 && c !== 9) {
        return false;
      }
      idx = idx + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return true;
}
function _M0MP26mizchi8markdown7Scanner7matches(self, s) {
  const s_len = s.length;
  if ((self.pos + s_len | 0) > self.len) {
    return false;
  }
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < s_len) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP311moonbitlang4core6string6String9get__char(s, i);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _b = _Some;
            if (_M0MP311moonbitlang4core5array5Array2atGcE(self.chars, self.pos + i | 0) === _b) {
              break _L;
            } else {
              break _L$2;
            }
          }
        }
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
function _M0MP26mizchi8markdown7Scanner11count__char(self, c) {
  let count = 0;
  let idx = self.pos;
  while (true) {
    if (idx < self.len) {
      if (_M0MP311moonbitlang4core5array5Array2atGcE(self.chars, idx) === c) {
        count = count + 1 | 0;
        idx = idx + 1 | 0;
      } else {
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return count;
}
function _M0MP26mizchi8markdown7Scanner7restore(self, pos) {
  self.pos = pos;
}
function _M0FP26mizchi8markdown15is__punctuation(c) {
  switch (c) {
    case 33: {
      return true;
    }
    case 34: {
      return true;
    }
    case 35: {
      return true;
    }
    case 36: {
      return true;
    }
    case 37: {
      return true;
    }
    case 38: {
      return true;
    }
    case 39: {
      return true;
    }
    case 40: {
      return true;
    }
    case 41: {
      return true;
    }
    case 42: {
      return true;
    }
    case 43: {
      return true;
    }
    case 44: {
      return true;
    }
    case 45: {
      return true;
    }
    case 46: {
      return true;
    }
    case 47: {
      return true;
    }
    case 58: {
      return true;
    }
    case 59: {
      return true;
    }
    case 60: {
      return true;
    }
    case 61: {
      return true;
    }
    case 62: {
      return true;
    }
    case 63: {
      return true;
    }
    case 64: {
      return true;
    }
    case 91: {
      return true;
    }
    case 92: {
      return true;
    }
    case 93: {
      return true;
    }
    case 94: {
      return true;
    }
    case 95: {
      return true;
    }
    case 96: {
      return true;
    }
    case 123: {
      return true;
    }
    case 124: {
      return true;
    }
    case 125: {
      return true;
    }
    case 126: {
      return true;
    }
    default: {
      return false;
    }
  }
}
function _M0FP26mizchi8markdown15char__is__digit(opt) {
  if (opt === -1) {
    return false;
  } else {
    const _Some = opt;
    const _c = _Some;
    return _c >= 48 && _c <= 57;
  }
}
function _M0FP26mizchi8markdown12escape__html(s) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const _it = _M0MP311moonbitlang4core6string6String4iter(s);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      switch (_c) {
        case 38: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&amp;");
          break;
        }
        case 60: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&lt;");
          break;
        }
        case 62: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&gt;");
          break;
        }
        case 34: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&quot;");
          break;
        }
        default: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
        }
      }
      continue;
    }
  }
  return buf.val;
}
function _M0FP26mizchi8markdown18escape__html__attr(s) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const _it = _M0MP311moonbitlang4core6string6String4iter(s);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      switch (_c) {
        case 38: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&amp;");
          break;
        }
        case 60: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&lt;");
          break;
        }
        case 62: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&gt;");
          break;
        }
        case 34: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&quot;");
          break;
        }
        case 39: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "&#39;");
          break;
        }
        default: {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
        }
      }
      continue;
    }
  }
  return buf.val;
}
function _M0FP26mizchi8markdown21render__inlines__html(inlines, buf) {
  const _len = inlines.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const inline = inlines[_i];
      _M0FP26mizchi8markdown20render__inline__html(inline, buf);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      return;
    }
  }
}
function _M0FP26mizchi8markdown20render__inline__html(inline, buf) {
  switch (inline.$tag) {
    case 0: {
      const _Text = inline;
      const _content = _Text._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_content));
      return;
    }
    case 6: {
      const _Code = inline;
      const _content$2 = _Code._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<code>");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_content$2));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</code>");
      return;
    }
    case 3: {
      const _Emphasis = inline;
      const _children = _Emphasis._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<em>");
      _M0FP26mizchi8markdown21render__inlines__html(_children, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</em>");
      return;
    }
    case 4: {
      const _Strong = inline;
      const _children$2 = _Strong._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<strong>");
      _M0FP26mizchi8markdown21render__inlines__html(_children$2, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</strong>");
      return;
    }
    case 5: {
      const _Strikethrough = inline;
      const _children$3 = _Strikethrough._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<del>");
      _M0FP26mizchi8markdown21render__inlines__html(_children$3, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</del>");
      return;
    }
    case 7: {
      const _Link = inline;
      const _children$4 = _Link._0;
      const _url = _Link._1;
      const _title = _Link._2;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<a href=\"");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_url));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
      if (!(_title === "")) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " title=\"");
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_title));
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 62);
      _M0FP26mizchi8markdown21render__inlines__html(_children$4, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</a>");
      return;
    }
    case 8: {
      const _RefLink = inline;
      const _children$5 = _RefLink._0;
      const _label = _RefLink._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 91);
      _M0FP26mizchi8markdown21render__inlines__html(_children$5, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "][");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_label));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 93);
      return;
    }
    case 9: {
      const _Autolink = inline;
      const _url$2 = _Autolink._0;
      const _is_email = _Autolink._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<a href=\"");
      if (_is_email) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "mailto:");
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_url$2));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\">");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_url$2));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</a>");
      return;
    }
    case 10: {
      const _Image = inline;
      const _alt = _Image._0;
      const _url$3 = _Image._1;
      const _title$2 = _Image._2;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<img src=\"");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_url$3));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\" alt=\"");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_alt));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
      if (!(_title$2 === "")) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " title=\"");
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_title$2));
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 34);
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, ">");
      return;
    }
    case 11: {
      const _RefImage = inline;
      const _alt$2 = _RefImage._0;
      const _label$2 = _RefImage._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "![");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_alt$2));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "][");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_label$2));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 93);
      return;
    }
    case 12: {
      const _HtmlInline = inline;
      const _html = _HtmlInline._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _html);
      return;
    }
    case 1: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
      return;
    }
    case 2: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<br>\n");
      return;
    }
    default: {
      const _FootnoteReference = inline;
      const _label$3 = _FootnoteReference._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<sup><a href=\"#fn-");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_label$3));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\" id=\"fnref-");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown18escape__html__attr(_label$3));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\">");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_label$3));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</a></sup>");
      return;
    }
  }
}
function _M0FP26mizchi8markdown25render__table__cell__html(cell, buf, tag, align) {
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 60);
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, tag);
  switch (align) {
    case 0: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " align=\"left\"");
      break;
    }
    case 1: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " align=\"center\"");
      break;
    }
    case 2: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, " align=\"right\"");
      break;
    }
  }
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 62);
  _M0FP26mizchi8markdown21render__inlines__html(cell.children, buf);
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</");
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, tag);
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, ">\n");
}
function _M0FP26mizchi8markdown19render__block__html(block, buf) {
  switch (block.$tag) {
    case 2: {
      const _Paragraph = block;
      const _children = _Paragraph._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<p>");
      _M0FP26mizchi8markdown21render__inlines__html(_children, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</p>\n");
      return;
    }
    case 1: {
      const _Heading = block;
      const _level = _Heading._0;
      const _children$2 = _Heading._2;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<h");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0MP311moonbitlang4core3int3Int18to__string_2einner(_level, 10));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 62);
      _M0FP26mizchi8markdown21render__inlines__html(_children$2, buf);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</h");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0MP311moonbitlang4core3int3Int18to__string_2einner(_level, 10));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, ">\n");
      return;
    }
    case 0: {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<hr>\n");
      return;
    }
    case 3: {
      const _FencedCode = block;
      const _info = _FencedCode._2;
      const _code = _FencedCode._3;
      if (_info === "") {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<pre><code>");
      } else {
        const parts = _M0MP311moonbitlang4core7builtin4Iter9to__arrayGRP311moonbitlang4core6string10StringViewE(_M0MP311moonbitlang4core6string6String5split(_info, { str: _M0FP26mizchi8markdown36render__block__html_2e_2abind_7c2209, start: 0, end: _M0FP26mizchi8markdown36render__block__html_2e_2abind_7c2209.length }));
        const lang = parts.length > 0 ? _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core5array5Array2atGRP311moonbitlang4core6string10StringViewE(parts, 0)) : _info;
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<pre><code class=\"language-");
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(lang));
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\">");
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_code));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</code></pre>\n");
      return;
    }
    case 4: {
      const _IndentedCode = block;
      const _code$2 = _IndentedCode._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<pre><code>");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_code$2));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</code></pre>\n");
      return;
    }
    case 5: {
      const _Blockquote = block;
      const _children$3 = _Blockquote._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<blockquote>\n");
      const _len = _children$3.length;
      let _tmp = 0;
      while (true) {
        const _i = _tmp;
        if (_i < _len) {
          const child = _children$3[_i];
          _M0FP26mizchi8markdown19render__block__html(child, buf);
          _tmp = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</blockquote>\n");
      return;
    }
    case 6: {
      const _BulletList = block;
      const _items = _BulletList._2;
      const _tight = _BulletList._1;
      const _p = _M0MP311moonbitlang4core5array5Array4iterGRP26mizchi8markdown8ListItemE(_items);
      let has_task;
      while (true) {
        const _p$2 = _M0MP311moonbitlang4core7builtin4Iter4nextGRP26mizchi8markdown8ListItemE(_p);
        if (_p$2 === undefined) {
          has_task = false;
          break;
        } else {
          const _p$3 = _p$2;
          const _p$4 = _p$3;
          const _p$5 = _p$4.checked;
          if (!(_p$5 === -1)) {
            has_task = true;
            break;
          }
          continue;
        }
      }
      if (has_task) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<ul class=\"contains-task-list\">\n");
      } else {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<ul>\n");
      }
      const _len$2 = _items.length;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const item = _items[_i];
          _M0FP26mizchi8markdown24render__list__item__html(item, buf, _tight, has_task);
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</ul>\n");
      return;
    }
    case 7: {
      const _OrderedList = block;
      const _items$2 = _OrderedList._3;
      const _start = _OrderedList._0;
      const _tight$2 = _OrderedList._2;
      const _p$2 = _M0MP311moonbitlang4core5array5Array4iterGRP26mizchi8markdown8ListItemE(_items$2);
      let has_task$2;
      while (true) {
        const _p$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGRP26mizchi8markdown8ListItemE(_p$2);
        if (_p$3 === undefined) {
          has_task$2 = false;
          break;
        } else {
          const _p$4 = _p$3;
          const _p$5 = _p$4;
          const _p$6 = _p$5.checked;
          if (!(_p$6 === -1)) {
            has_task$2 = true;
            break;
          }
          continue;
        }
      }
      if (_start === 1) {
        if (has_task$2) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<ol class=\"contains-task-list\">\n");
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<ol>\n");
        }
      } else {
        if (has_task$2) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<ol class=\"contains-task-list\" start=\"");
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<ol start=\"");
        }
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0MP311moonbitlang4core3int3Int18to__string_2einner(_start, 10));
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\">\n");
      }
      const _len$3 = _items$2.length;
      let _tmp$3 = 0;
      while (true) {
        const _i = _tmp$3;
        if (_i < _len$3) {
          const item = _items$2[_i];
          _M0FP26mizchi8markdown24render__list__item__html(item, buf, _tight$2, has_task$2);
          _tmp$3 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</ol>\n");
      return;
    }
    case 8: {
      const _HtmlBlock = block;
      const _html = _HtmlBlock._0;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _html);
      if (!_M0MP311moonbitlang4core6string6String11has__suffix(_html, { str: _M0FP26mizchi8markdown36render__block__html_2e_2abind_7c2222, start: 0, end: _M0FP26mizchi8markdown36render__block__html_2e_2abind_7c2222.length })) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
        return;
      } else {
        return;
      }
    }
    case 9: {
      const _Table = block;
      const _header = _Table._0;
      const _alignments = _Table._1;
      const _rows = _Table._2;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<table>\n<thead>\n<tr>\n");
      const _len$4 = _header.length;
      let _tmp$4 = 0;
      while (true) {
        const _i = _tmp$4;
        if (_i < _len$4) {
          const cell = _header[_i];
          const align = _i < _alignments.length ? _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown10TableAlignE(_alignments, _i) : 3;
          _M0FP26mizchi8markdown25render__table__cell__html(cell, buf, "th", align);
          _tmp$4 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</tr>\n</thead>\n");
      if (_rows.length > 0) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<tbody>\n");
        const _len$5 = _rows.length;
        let _tmp$5 = 0;
        while (true) {
          const _i = _tmp$5;
          if (_i < _len$5) {
            const row = _rows[_i];
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<tr>\n");
            const _len$6 = row.length;
            let _tmp$6 = 0;
            while (true) {
              const _i$2 = _tmp$6;
              if (_i$2 < _len$6) {
                const cell = row[_i$2];
                const align = _i$2 < _alignments.length ? _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown10TableAlignE(_alignments, _i$2) : 3;
                _M0FP26mizchi8markdown25render__table__cell__html(cell, buf, "td", align);
                _tmp$6 = _i$2 + 1 | 0;
                continue;
              } else {
                break;
              }
            }
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</tr>\n");
            _tmp$5 = _i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</tbody>\n");
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</table>\n");
      return;
    }
    case 10: {
      return;
    }
    default: {
      const _FootnoteDefinition = block;
      const _label = _FootnoteDefinition._0;
      const _children$4 = _FootnoteDefinition._1;
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<div class=\"footnote\" id=\"fn-");
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, _M0FP26mizchi8markdown12escape__html(_label));
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "\">\n");
      const _len$5 = _children$4.length;
      let _tmp$5 = 0;
      while (true) {
        const _i = _tmp$5;
        if (_i < _len$5) {
          const child = _children$4[_i];
          _M0FP26mizchi8markdown19render__block__html(child, buf);
          _tmp$5 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</div>\n");
      return;
    }
  }
}
function _M0FP26mizchi8markdown24render__list__item__html(item, buf, tight, is_task_list) {
  let _tmp;
  if (is_task_list) {
    const _bind$3 = item.checked;
    _tmp = !(_bind$3 === -1);
  } else {
    _tmp = false;
  }
  if (_tmp) {
    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<li class=\"task-list-item\">");
  } else {
    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<li>");
  }
  const _bind$3 = item.checked;
  if (_bind$3 === -1) {
  } else {
    const _Some = _bind$3;
    const _x = _Some;
    if (_x === true) {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<input type=\"checkbox\" checked disabled> ");
    } else {
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "<input type=\"checkbox\" disabled> ");
    }
  }
  if (tight) {
    const _arr = item.children;
    const _len = _arr.length;
    let _tmp$2 = 0;
    while (true) {
      const _i = _tmp$2;
      if (_i < _len) {
        const child = _arr[_i];
        if (child.$tag === 2) {
          const _Paragraph = child;
          const _children = _Paragraph._0;
          _M0FP26mizchi8markdown21render__inlines__html(_children, buf);
        } else {
          _M0FP26mizchi8markdown19render__block__html(child, buf);
        }
        _tmp$2 = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  } else {
    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 10);
    const _arr = item.children;
    const _len = _arr.length;
    let _tmp$2 = 0;
    while (true) {
      const _i = _tmp$2;
      if (_i < _len) {
        const child = _arr[_i];
        _M0FP26mizchi8markdown19render__block__html(child, buf);
        _tmp$2 = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(buf, "</li>\n");
}
function _M0FP26mizchi8markdown12render__html(doc) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const _arr = doc.children;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const block = _arr[_i];
      _M0FP26mizchi8markdown19render__block__html(block, buf);
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return buf.val;
}
function _M0MP26mizchi8markdown11BlockParser3new(scanner, strict) {
  return { scanner: scanner, definitions: [], strict: strict };
}
function _M0MP26mizchi8markdown12InlineParser3new(scanner) {
  return { scanner: scanner };
}
function _M0FP26mizchi8markdown39trim__trailing__space__from__last__text(inlines) {
  if (inlines.length > 0) {
    const _bind$3 = _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown6InlineE(inlines, inlines.length - 1 | 0);
    if (_bind$3.$tag === 0) {
      const _Text = _bind$3;
      const _content = _Text._0;
      const _span = _Text._1;
      const len = _content.length;
      if (len > 0) {
        const _p = _content.charCodeAt(len - 1 | 0);
        const _p$2 = 32;
        if (_p === _p$2) {
          let end = len - 1 | 0;
          while (true) {
            let _tmp;
            if (end > 0) {
              const _p$3 = _content.charCodeAt(end - 1 | 0);
              const _p$4 = 32;
              _tmp = _p$3 === _p$4;
            } else {
              _tmp = false;
            }
            if (_tmp) {
              end = end - 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _M0MP311moonbitlang4core5array5Array3popGRP26mizchi8markdown6InlineE(inlines);
          if (end > 0) {
            _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(inlines, new $64$mizchi$47$markdown$46$Inline$Text(_content.substring(0, end), _span));
            return;
          } else {
            return;
          }
        } else {
          return;
        }
      } else {
        return;
      }
    } else {
      return;
    }
  } else {
    return;
  }
}
function _M0MP26mizchi8markdown12InlineParser20try__parse__autolink(self, start) {
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const url_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let is_email = false;
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 62: {
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                const url = url_buf.val;
                if (_M0MP311moonbitlang4core6string6String8contains(url, { str: _M0FP26mizchi8markdown37try__parse__autolink_2e_2abind_7c2300, start: 0, end: _M0FP26mizchi8markdown37try__parse__autolink_2e_2abind_7c2300.length }) && !_M0MP311moonbitlang4core6string6String11has__prefix(url, { str: _M0FP26mizchi8markdown37try__parse__autolink_2e_2abind_7c2301, start: 0, end: _M0FP26mizchi8markdown37try__parse__autolink_2e_2abind_7c2301.length })) {
                  is_email = true;
                }
                return new $64$mizchi$47$markdown$46$Inline$Autolink(url, is_email, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
              }
              case 32: {
                break _L$2;
              }
              case 9: {
                break _L$2;
              }
              case 10: {
                break _L$2;
              }
              default: {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _x);
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              }
            }
          }
          break _L;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
        return undefined;
      }
      continue;
    } else {
      break;
    }
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  return undefined;
}
function _M0FP26mizchi8markdown15is__all__spaces(s) {
  const _it = _M0MP311moonbitlang4core6string6String4iter(s);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      if (_c !== 32) {
        return false;
      }
      continue;
    }
  }
  return true;
}
function _M0MP26mizchi8markdown12InlineParser22try__parse__code__span(self, start) {
  const backtick_count = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, 96);
  if (backtick_count === 0) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, backtick_count);
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const closing_count = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, 96);
      if (closing_count === backtick_count) {
        const content = content_buf.val;
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, closing_count);
        let trimmed;
        if (content.length >= 2) {
          const first = _M0MP311moonbitlang4core6string6String9get__char(content, 0);
          const last = _M0MP311moonbitlang4core6string6String9get__char(content, content.length - 1 | 0);
          trimmed = _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(first, _M0FP26mizchi8markdown38try__parse__code__span_2econstr_2f1654) && (_M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(last, _M0FP26mizchi8markdown38try__parse__code__span_2econstr_2f1655) && !_M0FP26mizchi8markdown15is__all__spaces(content)) ? content.substring(1, content.length - 1 | 0) : content;
        } else {
          trimmed = content;
        }
        return new $64$mizchi$47$markdown$46$Inline$Code(trimmed, backtick_count, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
      } else {
        if (closing_count > 0) {
          let _tmp = 0;
          while (true) {
            const i = _tmp;
            if (i < closing_count) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 96);
              _tmp = i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, closing_count);
        } else {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
          if (_bind$3 === -1) {
            break;
          } else {
            const _Some = _bind$3;
            const _c = _Some;
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, _c);
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  return undefined;
}
function _M0FP26mizchi8markdown14contains__link(inlines) {
  const _len = inlines.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const inline = inlines[_i];
      let children;
      _L: {
        _L$2: {
          _L$3: {
            _L$4: {
              switch (inline.$tag) {
                case 7: {
                  break _L$4;
                }
                case 8: {
                  break _L$4;
                }
                case 3: {
                  const _Emphasis = inline;
                  const _children = _Emphasis._1;
                  children = _children;
                  break _L$2;
                }
                case 4: {
                  const _Strong = inline;
                  const _children$2 = _Strong._1;
                  children = _children$2;
                  break _L$2;
                }
                case 5: {
                  const _Strikethrough = inline;
                  const _children$3 = _Strikethrough._0;
                  children = _children$3;
                  break _L$2;
                }
              }
              break _L$3;
            }
            return true;
          }
          break _L;
        }
        if (_M0FP26mizchi8markdown14contains__link(children)) {
          return true;
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return false;
}
function _M0MP26mizchi8markdown12InlineParser18try__parse__escape(self, start) {
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  _L: {
    const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    if (_bind$3 === -1) {
      break _L;
    } else {
      const _Some = _bind$3;
      const _x = _Some;
      if (_x === 10) {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        while (true) {
          const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          const _p$2 = 32;
          let _tmp;
          if (_p === -1) {
            _tmp = false;
          } else {
            const _p$3 = _p;
            const _p$4 = _p$3;
            _tmp = _p$4 === _p$2;
          }
          if (_tmp) {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            continue;
          } else {
            break;
          }
        }
        return new $64$mizchi$47$markdown$46$Inline$HardBreak(1, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
      } else {
        if (_M0FP26mizchi8markdown15is__punctuation(_x)) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          return new $64$mizchi$47$markdown$46$Inline$Text(_M0MP311moonbitlang4core6string6String4make(1, _x), _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
        } else {
          break _L;
        }
      }
    }
  }
  return new $64$mizchi$47$markdown$46$Inline$Text("\\", _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
}
function _M0MP26mizchi8markdown12InlineParser31try__parse__footnote__reference(self, start) {
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 94;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (!_tmp) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const label_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  while (true) {
    const _p$3 = self.scanner;
    if (!(_p$3.pos >= _p$3.len)) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            if (_x === 93) {
              break;
            } else {
              if (_x >= 97 && _x <= 122 || (_x >= 65 && _x <= 90 || (_x >= 48 && _x <= 57 || (_x === 45 || _x === 95)))) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(label_buf, _x);
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              } else {
                break _L$2;
              }
            }
          }
          break _L;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
        return undefined;
      }
      continue;
    } else {
      break;
    }
  }
  const label = label_buf.val;
  if (label === "") {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 93;
  let _tmp$2;
  if (_p$3 === -1) {
    _tmp$2 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$2 = _p$6 === _p$4;
  }
  if (!_tmp$2) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  return new $64$mizchi$47$markdown$46$Inline$FootnoteReference(label, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
}
function _M0MP26mizchi8markdown12InlineParser23try__parse__hard__break(self, start) {
  const space_count = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, 32);
  if (space_count < 2) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, space_count);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    while (true) {
      const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      const _p$4 = 32;
      let _tmp$2;
      if (_p$3 === -1) {
        _tmp$2 = false;
      } else {
        const _p$5 = _p$3;
        const _p$6 = _p$5;
        _tmp$2 = _p$6 === _p$4;
      }
      if (_tmp$2) {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        continue;
      } else {
        break;
      }
    }
    return new $64$mizchi$47$markdown$46$Inline$HardBreak(0, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  return undefined;
}
function _M0MP26mizchi8markdown12InlineParser17try__parse__image(self, start) {
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 91;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (!_tmp) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const alt_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  _L: while (true) {
    const _p$3 = self.scanner;
    if (!(_p$3.pos >= _p$3.len)) {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        break;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        switch (_x) {
          case 93: {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            break _L;
          }
          case 92: {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            const _bind$4 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
            if (_bind$4 === -1) {
              break _L;
            } else {
              const _Some$2 = _bind$4;
              const _c = _Some$2;
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(alt_buf, _c);
            }
            break;
          }
          default: {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(alt_buf, _x);
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  const alt = alt_buf.val;
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 40;
  let _tmp$2;
  if (_p$3 === -1) {
    _tmp$2 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$2 = _p$6 === _p$4;
  }
  if (_tmp$2) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    const url_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
    const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    const _p$6 = 60;
    let _tmp$3;
    if (_p$5 === -1) {
      _tmp$3 = false;
    } else {
      const _p$7 = _p$5;
      const _p$8 = _p$7;
      _tmp$3 = _p$8 === _p$6;
    }
    if (_tmp$3) {
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      while (true) {
        const _p$7 = self.scanner;
        if (!(_p$7.pos >= _p$7.len)) {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            if (_x === 62) {
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              break;
            } else {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _x);
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            }
          }
          continue;
        } else {
          break;
        }
      }
    } else {
      while (true) {
        const _p$7 = self.scanner;
        if (!(_p$7.pos >= _p$7.len)) {
          _L$2: {
            _L$3: {
              const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
              if (_bind$3 === -1) {
                break;
              } else {
                const _Some = _bind$3;
                const _x = _Some;
                switch (_x) {
                  case 41: {
                    break _L$3;
                  }
                  case 32: {
                    break _L$3;
                  }
                  case 9: {
                    break _L$3;
                  }
                  default: {
                    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _x);
                    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                  }
                }
              }
              break _L$2;
            }
            break;
          }
          continue;
        } else {
          break;
        }
      }
    }
    const url = url_buf.val;
    _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
    let title;
    _L$2: {
      _L$3: {
        const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        if (_bind$3 === -1) {
          title = "";
        } else {
          const _Some = _bind$3;
          const _x = _Some;
          switch (_x) {
            case 34: {
              break _L$3;
            }
            case 39: {
              break _L$3;
            }
            default: {
              title = "";
            }
          }
        }
        break _L$2;
      }
      const _bind$3 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
      const quote = _bind$3 === -1 ? 34 : _bind$3;
      const title_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
      while (true) {
        const _p$7 = self.scanner;
        if (!(_p$7.pos >= _p$7.len)) {
          const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$4 === -1) {
            break;
          } else {
            const _Some = _bind$4;
            const _c = _Some;
            if (_c === quote) {
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              break;
            } else {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, _c);
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            }
          }
          continue;
        } else {
          break;
        }
      }
      title = title_buf.val;
    }
    _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
    const _p$7 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    const _p$8 = 41;
    let _tmp$4;
    if (_p$7 === -1) {
      _tmp$4 = false;
    } else {
      const _p$9 = _p$7;
      const _p$10 = _p$9;
      _tmp$4 = _p$10 === _p$8;
    }
    if (_tmp$4) {
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      return new $64$mizchi$47$markdown$46$Inline$Image(alt, url, title, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
    }
  }
  const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$6 = 91;
  let _tmp$3;
  if (_p$5 === -1) {
    _tmp$3 = false;
  } else {
    const _p$7 = _p$5;
    const _p$8 = _p$7;
    _tmp$3 = _p$8 === _p$6;
  }
  if (_tmp$3) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    const label_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    while (true) {
      const _p$7 = self.scanner;
      if (!(_p$7.pos >= _p$7.len)) {
        const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        if (_bind$3 === -1) {
          break;
        } else {
          const _Some = _bind$3;
          const _x = _Some;
          if (_x === 93) {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            break;
          } else {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(label_buf, _x);
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          }
        }
        continue;
      } else {
        break;
      }
    }
    return new $64$mizchi$47$markdown$46$Inline$RefImage(alt, label_buf.val, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  return undefined;
}
function _M0MP26mizchi8markdown12InlineParser25try__parse__strikethrough(self, start) {
  if (_M0MP26mizchi8markdown7Scanner11count__char(self.scanner, 126) < 2) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 2);
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const content_start = self.scanner.pos;
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      if (_M0MP26mizchi8markdown7Scanner11count__char(self.scanner, 126) >= 2) {
        const content = content_buf.val;
        if (content === "") {
          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
          return undefined;
        }
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 2);
        const children = [new $64$mizchi$47$markdown$46$Inline$Text(content, _M0MP26mizchi8markdown4Span3new(content_start, self.scanner.pos - 2 | 0))];
        return new $64$mizchi$47$markdown$46$Inline$Strikethrough(children, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
      }
      const _bind$3 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
      if (_bind$3 === -1) {
        break;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        if (_x === 10) {
          break;
        } else {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, _x);
        }
      }
      continue;
    } else {
      break;
    }
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  return undefined;
}
function _M0FP26mizchi8markdown24is__unicode__punctuation(c) {
  const code = c;
  return code >= 33 && code <= 47 || (code >= 58 && code <= 64 || (code >= 91 && code <= 96 || code >= 123 && code <= 126));
}
function _M0FP26mizchi8markdown23is__unicode__whitespace(c) {
  return c === 32 || (c === 9 || (c === 10 || (c === 13 || c === 12)));
}
function _M0FP26mizchi8markdown22parse__inlines_2einner(text, strict) {
  return strict ? _M0FP26mizchi8markdown38parse__inlines__with__delimiter__stack(text) : _M0FP26mizchi8markdown20parse__inlines__fast(text);
}
function _M0FP26mizchi8markdown20parse__inlines__fast(text) {
  const scanner = _M0MP26mizchi8markdown7Scanner3new(text);
  const parser = _M0MP26mizchi8markdown12InlineParser3new(scanner);
  return _M0MP26mizchi8markdown12InlineParser5parse(parser);
}
function _M0MP26mizchi8markdown12InlineParser5parse(self) {
  const inlines = [];
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const _bind$3 = _M0MP26mizchi8markdown12InlineParser13parse__inline(self);
      if (_bind$3 === undefined) {
        const start = self.scanner.pos;
        const _bind$4 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
        if (_bind$4 === -1) {
          break;
        } else {
          const _Some = _bind$4;
          const _c = _Some;
          const text = _M0MP311moonbitlang4core6string6String4make(1, _c);
          _L: {
            _L$2: {
              const _bind$5 = _M0MP311moonbitlang4core5array5Array4lastGRP26mizchi8markdown6InlineE(inlines);
              if (_bind$5 === undefined) {
                break _L$2;
              } else {
                const _Some$2 = _bind$5;
                const _x = _Some$2;
                if (_x.$tag === 0) {
                  const _Text = _x;
                  const _content = _Text._0;
                  const _span = _Text._1;
                  _M0MP311moonbitlang4core5array5Array3popGRP26mizchi8markdown6InlineE(inlines);
                  _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(inlines, new $64$mizchi$47$markdown$46$Inline$Text(`${_content}${text}`, _M0MP26mizchi8markdown4Span3new(_span.from, self.scanner.pos)));
                } else {
                  break _L$2;
                }
              }
              break _L;
            }
            _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(inlines, new $64$mizchi$47$markdown$46$Inline$Text(text, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos)));
          }
        }
      } else {
        const _Some = _bind$3;
        const _inline = _Some;
        _L: {
          _L$2: {
            switch (_inline.$tag) {
              case 1: {
                break _L$2;
              }
              case 2: {
                break _L$2;
              }
            }
            break _L;
          }
          _M0FP26mizchi8markdown39trim__trailing__space__from__last__text(inlines);
        }
        _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(inlines, _inline);
      }
      continue;
    } else {
      break;
    }
  }
  return inlines;
}
function _M0MP26mizchi8markdown12InlineParser13parse__inline(self) {
  const start = self.scanner.pos;
  _L: {
    const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    if (_bind$3 === -1) {
      break _L;
    } else {
      const _Some = _bind$3;
      const _x = _Some;
      switch (_x) {
        case 92: {
          return _M0MP26mizchi8markdown12InlineParser18try__parse__escape(self, start);
        }
        case 96: {
          return _M0MP26mizchi8markdown12InlineParser22try__parse__code__span(self, start);
        }
        case 42: {
          return _M0MP26mizchi8markdown12InlineParser20try__parse__emphasis(self, start, 42);
        }
        case 95: {
          return _M0MP26mizchi8markdown12InlineParser20try__parse__emphasis(self, start, 95);
        }
        case 126: {
          return _M0MP26mizchi8markdown12InlineParser25try__parse__strikethrough(self, start);
        }
        case 91: {
          const _p = _M0MP26mizchi8markdown7Scanner8peek__at(self.scanner, 1);
          const _p$2 = 94;
          let _tmp;
          if (_p === -1) {
            _tmp = false;
          } else {
            const _p$3 = _p;
            const _p$4 = _p$3;
            _tmp = _p$4 === _p$2;
          }
          if (_tmp) {
            const _bind$4 = _M0MP26mizchi8markdown12InlineParser31try__parse__footnote__reference(self, start);
            if (_bind$4 === undefined) {
              return _M0MP26mizchi8markdown12InlineParser16try__parse__link(self, start);
            } else {
              const _Some$2 = _bind$4;
              const _fn_ref = _Some$2;
              return _fn_ref;
            }
          } else {
            return _M0MP26mizchi8markdown12InlineParser16try__parse__link(self, start);
          }
        }
        case 33: {
          return _M0MP26mizchi8markdown12InlineParser17try__parse__image(self, start);
        }
        case 60: {
          return _M0MP26mizchi8markdown12InlineParser20try__parse__autolink(self, start);
        }
        case 32: {
          return _M0MP26mizchi8markdown12InlineParser23try__parse__hard__break(self, start);
        }
        case 10: {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          while (true) {
            const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            const _p$4 = 32;
            let _tmp$2;
            if (_p$3 === -1) {
              _tmp$2 = false;
            } else {
              const _p$5 = _p$3;
              const _p$6 = _p$5;
              _tmp$2 = _p$6 === _p$4;
            }
            if (_tmp$2) {
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              continue;
            } else {
              break;
            }
          }
          return new $64$mizchi$47$markdown$46$Inline$SoftBreak(_M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
        }
        default: {
          break _L;
        }
      }
    }
  }
  return undefined;
}
function _M0MP26mizchi8markdown12InlineParser20try__parse__emphasis(self, start, marker_char) {
  const marker_count = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, marker_char);
  if (marker_count === 0) {
    return undefined;
  }
  const is_strong = marker_count >= 2;
  const consume_count = is_strong ? 2 : 1;
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, consume_count);
  _L: {
    _L$2: {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        break _L$2;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        switch (_x) {
          case 32: {
            break _L$2;
          }
          case 9: {
            break _L$2;
          }
          case 10: {
            break _L$2;
          }
        }
      }
      break _L;
    }
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  const children = _M0MP26mizchi8markdown12InlineParser29parse__until__closing__marker(self, marker_char, consume_count);
  if (children.length === 0) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  const marker = marker_char === 42 ? 0 : 1;
  return is_strong ? new $64$mizchi$47$markdown$46$Inline$Strong(marker, children, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos)) : new $64$mizchi$47$markdown$46$Inline$Emphasis(marker, children, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
}
function _M0MP26mizchi8markdown12InlineParser29parse__until__closing__marker(self, marker_char, marker_count) {
  const children = [];
  const text_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const text_start = self.scanner.pos;
  _L: while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const closing_count = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, marker_char);
      if (closing_count >= marker_count) {
        const prev_char = _M0MP26mizchi8markdown7Scanner8peek__at(self.scanner, -1);
        _L$2: {
          _L$3: {
            if (prev_char === -1) {
              break _L$3;
            } else {
              const _Some = prev_char;
              const _x = _Some;
              switch (_x) {
                case 32: {
                  break;
                }
                case 9: {
                  break;
                }
                case 10: {
                  break;
                }
                default: {
                  break _L$3;
                }
              }
            }
            break _L$2;
          }
          if (!(text_buf.val === "")) {
            _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(children, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(text_start, self.scanner.pos)));
          }
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, marker_count);
          return children;
        }
      }
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        switch (_x) {
          case 96: {
            if (!(text_buf.val === "")) {
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(children, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(text_start, self.scanner.pos)));
            }
            const nested_start = self.scanner.pos;
            const _bind$4 = _M0MP26mizchi8markdown12InlineParser22try__parse__code__span(self, nested_start);
            if (_bind$4 === undefined) {
            } else {
              const _Some$2 = _bind$4;
              const _code = _Some$2;
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(children, _code);
              continue _L;
            }
            break;
          }
          case 91: {
            if (!(text_buf.val === "")) {
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(children, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(text_start, self.scanner.pos)));
            }
            const nested_start$2 = self.scanner.pos;
            const _bind$5 = _M0MP26mizchi8markdown12InlineParser16try__parse__link(self, nested_start$2);
            if (_bind$5 === undefined) {
            } else {
              const _Some$2 = _bind$5;
              const _link = _Some$2;
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(children, _link);
              continue _L;
            }
            break;
          }
          case 10: {
            break _L;
          }
        }
      }
      const _bind$4 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
      if (_bind$4 === -1) {
        break;
      } else {
        const _Some = _bind$4;
        const _c = _Some;
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, _c);
      }
      continue;
    } else {
      break;
    }
  }
  return [];
}
function _M0MP26mizchi8markdown12InlineParser16try__parse__link(self, start) {
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const text_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let bracket_depth = 1;
  _L: while (true) {
    let _tmp;
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      _tmp = bracket_depth > 0;
    } else {
      _tmp = false;
    }
    if (_tmp) {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        break;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        switch (_x) {
          case 91: {
            bracket_depth = bracket_depth + 1 | 0;
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 91);
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            break;
          }
          case 93: {
            bracket_depth = bracket_depth - 1 | 0;
            if (bracket_depth > 0) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 93);
            }
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            break;
          }
          case 92: {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            const _bind$4 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
            if (_bind$4 === -1) {
              break _L;
            } else {
              const _Some$2 = _bind$4;
              const _c = _Some$2;
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, _c);
            }
            break;
          }
          default: {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, _x);
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  const link_text = text_buf.val;
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 40;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    const url_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    let paren_depth = 1;
    _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
    const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    const _p$4 = 60;
    let _tmp$2;
    if (_p$3 === -1) {
      _tmp$2 = false;
    } else {
      const _p$5 = _p$3;
      const _p$6 = _p$5;
      _tmp$2 = _p$6 === _p$4;
    }
    if (_tmp$2) {
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      let angle_url_has_newline = false;
      _L$2: while (true) {
        const _p$5 = self.scanner;
        if (!(_p$5.pos >= _p$5.len)) {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 62: {
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                break _L$2;
              }
              case 10: {
                angle_url_has_newline = true;
                break _L$2;
              }
              default: {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _x);
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              }
            }
          }
          continue;
        } else {
          break;
        }
      }
      if (angle_url_has_newline) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
        return undefined;
      }
    } else {
      let url_has_newline = false;
      _L$2: while (true) {
        const _p$5 = self.scanner;
        if (!(_p$5.pos >= _p$5.len)) {
          _L$3: {
            _L$4: {
              const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
              if (_bind$3 === -1) {
                break;
              } else {
                const _Some = _bind$3;
                const _x = _Some;
                switch (_x) {
                  case 40: {
                    paren_depth = paren_depth + 1 | 0;
                    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, 40);
                    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                    break;
                  }
                  case 41: {
                    paren_depth = paren_depth - 1 | 0;
                    if (paren_depth === 0) {
                      break _L$2;
                    }
                    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, 41);
                    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                    break;
                  }
                  case 32: {
                    break _L$4;
                  }
                  case 9: {
                    break _L$4;
                  }
                  case 10: {
                    url_has_newline = true;
                    break _L$2;
                  }
                  default: {
                    _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _x);
                    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                  }
                }
              }
              break _L$3;
            }
            break;
          }
          continue;
        } else {
          break;
        }
      }
      if (url_has_newline) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
        return undefined;
      }
    }
    const url = url_buf.val;
    while (true) {
      const _p$5 = self.scanner;
      if (!(_p$5.pos >= _p$5.len)) {
        _L$2: {
          _L$3: {
            _L$4: {
              const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
              if (_bind$3 === -1) {
                break _L$3;
              } else {
                const _Some = _bind$3;
                const _x = _Some;
                switch (_x) {
                  case 32: {
                    break _L$4;
                  }
                  case 9: {
                    break _L$4;
                  }
                  case 10: {
                    break _L$4;
                  }
                  default: {
                    break _L$3;
                  }
                }
              }
            }
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            break _L$2;
          }
          break;
        }
        continue;
      } else {
        break;
      }
    }
    let title;
    _L$2: {
      _L$3: {
        const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        if (_bind$3 === -1) {
          title = "";
        } else {
          const _Some = _bind$3;
          const _x = _Some;
          switch (_x) {
            case 34: {
              break _L$3;
            }
            case 39: {
              break _L$3;
            }
            case 40: {
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              const title_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
              let paren_depth$2 = 1;
              _L$4: while (true) {
                let _tmp$3;
                const _p$5 = self.scanner;
                if (!(_p$5.pos >= _p$5.len)) {
                  _tmp$3 = paren_depth$2 > 0;
                } else {
                  _tmp$3 = false;
                }
                if (_tmp$3) {
                  const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
                  if (_bind$4 === -1) {
                    break;
                  } else {
                    const _Some$2 = _bind$4;
                    const _x$2 = _Some$2;
                    switch (_x$2) {
                      case 41: {
                        paren_depth$2 = paren_depth$2 - 1 | 0;
                        if (paren_depth$2 === 0) {
                          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                          break _L$4;
                        }
                        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, 41);
                        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                        break;
                      }
                      case 40: {
                        paren_depth$2 = paren_depth$2 + 1 | 0;
                        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, 40);
                        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                        break;
                      }
                      case 92: {
                        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                        const _bind$5 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
                        if (_bind$5 === -1) {
                          break _L$4;
                        } else {
                          const _Some$3 = _bind$5;
                          const _c = _Some$3;
                          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, _c);
                        }
                        break;
                      }
                      default: {
                        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, _x$2);
                        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                      }
                    }
                  }
                  continue;
                } else {
                  break;
                }
              }
              title = title_buf.val;
              break;
            }
            default: {
              title = "";
            }
          }
        }
        break _L$2;
      }
      const _bind$3 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
      const quote = _bind$3 === -1 ? 34 : _bind$3;
      const title_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
      while (true) {
        const _p$5 = self.scanner;
        if (!(_p$5.pos >= _p$5.len)) {
          const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$4 === -1) {
            break;
          } else {
            const _Some = _bind$4;
            const _c = _Some;
            if (_c === quote) {
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              break;
            } else {
              if (_c === 92) {
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                const _bind$5 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
                if (_bind$5 === -1) {
                  break;
                } else {
                  const _Some$2 = _bind$5;
                  const _c$2 = _Some$2;
                  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, _c$2);
                }
              } else {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, _c);
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              }
            }
          }
          continue;
        } else {
          break;
        }
      }
      title = title_buf.val;
    }
    _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
    const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    const _p$6 = 41;
    let _tmp$3;
    if (_p$5 === -1) {
      _tmp$3 = false;
    } else {
      const _p$7 = _p$5;
      const _p$8 = _p$7;
      _tmp$3 = _p$8 === _p$6;
    }
    if (_tmp$3) {
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      const children = _M0FP26mizchi8markdown22parse__inlines_2einner(link_text, false);
      if (_M0FP26mizchi8markdown14contains__link(children)) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
        return undefined;
      }
      return new $64$mizchi$47$markdown$46$Inline$Link(children, url, title, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
    }
  }
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 91;
  let _tmp$2;
  if (_p$3 === -1) {
    _tmp$2 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$2 = _p$6 === _p$4;
  }
  if (_tmp$2) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    const label_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    while (true) {
      const _p$5 = self.scanner;
      if (!(_p$5.pos >= _p$5.len)) {
        const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        if (_bind$3 === -1) {
          break;
        } else {
          const _Some = _bind$3;
          const _x = _Some;
          if (_x === 93) {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            break;
          } else {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(label_buf, _x);
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          }
        }
        continue;
      } else {
        break;
      }
    }
    const label = label_buf.val;
    const children = _M0FP26mizchi8markdown22parse__inlines_2einner(link_text, false);
    if (_M0FP26mizchi8markdown14contains__link(children)) {
      _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
      return undefined;
    }
    return new $64$mizchi$47$markdown$46$Inline$RefLink(children, label, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos));
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  return undefined;
}
function _M0FP26mizchi8markdown38parse__inlines__with__delimiter__stack(text) {
  const chars = _M0MP311moonbitlang4core6string6String9to__array(text);
  const len = chars.length;
  const delimiters = [];
  let i = 0;
  while (true) {
    if (i < len) {
      const c = _M0MP311moonbitlang4core5array5Array2atGcE(chars, i);
      if (c === 42 || c === 95) {
        const start = i;
        let count = 0;
        while (true) {
          if (i < len && _M0MP311moonbitlang4core5array5Array2atGcE(chars, i) === c) {
            count = count + 1 | 0;
            i = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        const before = start > 0 ? _M0MP311moonbitlang4core5array5Array2atGcE(chars, start - 1 | 0) : -1;
        const after = i < len ? _M0MP311moonbitlang4core5array5Array2atGcE(chars, i) : -1;
        let before_is_whitespace;
        if (before === -1) {
          before_is_whitespace = true;
        } else {
          const _Some = before;
          const _ch = _Some;
          before_is_whitespace = _M0FP26mizchi8markdown23is__unicode__whitespace(_ch);
        }
        let before_is_punctuation;
        if (before === -1) {
          before_is_punctuation = false;
        } else {
          const _Some = before;
          const _ch = _Some;
          before_is_punctuation = _M0FP26mizchi8markdown24is__unicode__punctuation(_ch);
        }
        let after_is_whitespace;
        if (after === -1) {
          after_is_whitespace = true;
        } else {
          const _Some = after;
          const _ch = _Some;
          after_is_whitespace = _M0FP26mizchi8markdown23is__unicode__whitespace(_ch);
        }
        let after_is_punctuation;
        if (after === -1) {
          after_is_punctuation = false;
        } else {
          const _Some = after;
          const _ch = _Some;
          after_is_punctuation = _M0FP26mizchi8markdown24is__unicode__punctuation(_ch);
        }
        const left_flanking = !after_is_whitespace && (!after_is_punctuation || (before_is_whitespace || before_is_punctuation));
        const right_flanking = !before_is_whitespace && (!before_is_punctuation || (after_is_whitespace || after_is_punctuation));
        let can_open;
        let can_close;
        _L: {
          if (c === 95) {
            can_open = left_flanking && (!right_flanking || before_is_punctuation);
            can_close = right_flanking && (!left_flanking || after_is_punctuation);
            break _L;
          } else {
            can_open = left_flanking;
            can_close = right_flanking;
            break _L;
          }
        }
        if (can_open || can_close) {
          _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown9DelimiterE(delimiters, { pos: start, marker: c, length: count, remaining: count, can_open: can_open, can_close: can_close, active: true });
        }
      } else {
        i = i + 1 | 0;
      }
      continue;
    } else {
      break;
    }
  }
  const matches = [];
  let _tmp = 0;
  while (true) {
    const closer_idx = _tmp;
    if (closer_idx < delimiters.length) {
      _L: {
        const closer = _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown9DelimiterE(delimiters, closer_idx);
        if (!closer.can_close || closer.remaining === 0) {
          break _L;
        }
        let _tmp$2 = closer_idx - 1 | 0;
        while (true) {
          const opener_idx = _tmp$2;
          if (opener_idx >= 0) {
            _L$2: {
              const opener = _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown9DelimiterE(delimiters, opener_idx);
              if (!opener.can_open || (opener.remaining === 0 || !opener.active)) {
                break _L$2;
              }
              if (opener.marker !== closer.marker) {
                break _L$2;
              }
              if (opener.can_open && opener.can_close || closer.can_open && closer.can_close) {
                if (((opener.length + closer.length | 0) % 3 | 0) === 0) {
                  if ((opener.length % 3 | 0) !== 0 || (closer.length % 3 | 0) !== 0) {
                    break _L$2;
                  }
                }
              }
              const use_count = opener.remaining >= 2 && closer.remaining >= 2 ? 2 : 1;
              const is_strong = use_count === 2;
              const opener_end = ((opener.pos + opener.length | 0) - opener.remaining | 0) + use_count | 0;
              const closer_start = closer.pos + (closer.length - closer.remaining | 0) | 0;
              _M0MP311moonbitlang4core5array5Array4pushGUiicbEE(matches, { _0: opener_end - use_count | 0, _1: closer_start, _2: opener.marker, _3: is_strong });
              _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown9DelimiterE(delimiters, opener_idx).remaining = opener.remaining - use_count | 0;
              _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown9DelimiterE(delimiters, closer_idx).remaining = closer.remaining - use_count | 0;
              let _tmp$3 = opener_idx + 1 | 0;
              while (true) {
                const j = _tmp$3;
                if (j < closer_idx) {
                  _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown9DelimiterE(delimiters, j).active = false;
                  _tmp$3 = j + 1 | 0;
                  continue;
                } else {
                  break;
                }
              }
              if (closer.remaining > 0) {
              }
              break;
            }
            _tmp$2 = opener_idx - 1 | 0;
            continue;
          } else {
            break;
          }
        }
        break _L;
      }
      _tmp = closer_idx + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const result = [];
  if (matches.length === 0) {
    const segment_inlines = _M0FP26mizchi8markdown22parse__segment__simple(text, 0);
    const _len = segment_inlines.length;
    let _tmp$2 = 0;
    while (true) {
      const _i = _tmp$2;
      if (_i < _len) {
        const inline = segment_inlines[_i];
        _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, inline);
        _tmp$2 = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  } else {
    _M0FP26mizchi8markdown29build__inlines__from__matches(text, chars, matches, result);
  }
  return result;
}
function _M0FP26mizchi8markdown29build__inlines__from__matches(text, chars, matches, result) {
  const sorted = _M0MP311moonbitlang4core5array5Array4copyGUiicbEE(matches);
  _M0MP311moonbitlang4core5array5Array8sort__byGUiicbEE(sorted, (a, b) => $compare_int(a._0, b._0));
  const len = chars.length;
  _M0FP26mizchi8markdown25build__inlines__recursive(text, chars, 0, len, sorted, 0, sorted.length, result);
}
function _M0FP26mizchi8markdown25build__inlines__recursive(text, chars, start, end, matches, match_start, match_end, result) {
  let pos = start;
  let _tmp = match_start;
  while (true) {
    const i = _tmp;
    if (i < match_end) {
      _L: {
        const _bind$3 = _M0MP311moonbitlang4core5array5Array2atGUiicbEE(matches, i);
        const _opener_pos = _bind$3._0;
        const _closer_pos = _bind$3._1;
        const _marker = _bind$3._2;
        const _is_strong = _bind$3._3;
        if (_opener_pos < start || (_closer_pos > end || _opener_pos < pos)) {
          break _L;
        }
        const marker_len = _is_strong ? 2 : 1;
        if (_opener_pos > pos) {
          const segment = text.substring(pos, _opener_pos);
          const segment_inlines = _M0FP26mizchi8markdown22parse__segment__simple(segment, pos);
          const _len = segment_inlines.length;
          let _tmp$2 = 0;
          while (true) {
            const _i = _tmp$2;
            if (_i < _len) {
              const inline = segment_inlines[_i];
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, inline);
              _tmp$2 = _i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
        }
        const children = [];
        const content_start = _opener_pos + marker_len | 0;
        const nested_start = i + 1 | 0;
        let nested_end = i + 1 | 0;
        while (true) {
          if (nested_end < match_end) {
            const _bind$4 = _M0MP311moonbitlang4core5array5Array2atGUiicbEE(matches, nested_end);
            const _np = _bind$4._0;
            const _nc = _bind$4._1;
            if (_np >= content_start && _nc <= _closer_pos) {
              nested_end = nested_end + 1 | 0;
            } else {
              break;
            }
            continue;
          } else {
            break;
          }
        }
        if (nested_start < nested_end) {
          _M0FP26mizchi8markdown25build__inlines__recursive(text, chars, content_start, _closer_pos, matches, nested_start, nested_end, children);
        } else {
          const content = text.substring(content_start, _closer_pos);
          const content_inlines = _M0FP26mizchi8markdown22parse__segment__simple(content, content_start);
          const _len = content_inlines.length;
          let _tmp$2 = 0;
          while (true) {
            const _i = _tmp$2;
            if (_i < _len) {
              const inline = content_inlines[_i];
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(children, inline);
              _tmp$2 = _i + 1 | 0;
              continue;
            } else {
              break;
            }
          }
        }
        const em_marker = _marker === 42 ? 0 : 1;
        const span = _M0MP26mizchi8markdown4Span3new(_opener_pos, _closer_pos + marker_len | 0);
        if (_is_strong) {
          _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Strong(em_marker, children, span));
        } else {
          _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Emphasis(em_marker, children, span));
        }
        pos = _closer_pos + marker_len | 0;
        break _L;
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (pos < end) {
    const segment = text.substring(pos, end);
    const segment_inlines = _M0FP26mizchi8markdown22parse__segment__simple(segment, pos);
    const _len = segment_inlines.length;
    let _tmp$2 = 0;
    while (true) {
      const _i = _tmp$2;
      if (_i < _len) {
        const inline = segment_inlines[_i];
        _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, inline);
        _tmp$2 = _i + 1 | 0;
        continue;
      } else {
        return;
      }
    }
  } else {
    return;
  }
}
function _M0FP26mizchi8markdown22parse__segment__simple(text, offset) {
  const scanner = _M0MP26mizchi8markdown7Scanner3new(text);
  const result = [];
  const text_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let text_start = 0;
  while (true) {
    if (!(scanner.pos >= scanner.len)) {
      const pos = scanner.pos;
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(scanner);
      if (_bind$3 === -1) {
        break;
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        switch (_x) {
          case 96: {
            const backtick_count = _M0MP26mizchi8markdown7Scanner11count__char(scanner, 96);
            _M0MP26mizchi8markdown7Scanner7advance(scanner, backtick_count);
            const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
            let found_closing = false;
            while (true) {
              if (!(scanner.pos >= scanner.len)) {
                const closing_count = _M0MP26mizchi8markdown7Scanner11count__char(scanner, 96);
                if (closing_count === backtick_count) {
                  found_closing = true;
                  const content = content_buf.val;
                  _M0MP26mizchi8markdown7Scanner7advance(scanner, closing_count);
                  if (!(text_buf.val === "")) {
                    _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(offset + text_start | 0, offset + pos | 0)));
                    _M0MP311moonbitlang4core7builtin13StringBuilder5reset(text_buf);
                  }
                  let trimmed;
                  if (content.length >= 2) {
                    const chars = _M0MP311moonbitlang4core6string6String9to__array(content);
                    trimmed = _M0MP311moonbitlang4core5array5Array2atGcE(chars, 0) === 32 && (_M0MP311moonbitlang4core5array5Array2atGcE(chars, chars.length - 1 | 0) === 32 && !_M0FP26mizchi8markdown15is__all__spaces(content)) ? content.substring(1, content.length - 1 | 0) : content;
                  } else {
                    trimmed = content;
                  }
                  _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Code(trimmed, backtick_count, _M0MP26mizchi8markdown4Span3new(offset + pos | 0, offset + scanner.pos | 0)));
                  text_start = scanner.pos;
                  break;
                } else {
                  if (closing_count > 0) {
                    let _tmp = 0;
                    while (true) {
                      const j = _tmp;
                      if (j < closing_count) {
                        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 96);
                        _tmp = j + 1 | 0;
                        continue;
                      } else {
                        break;
                      }
                    }
                    _M0MP26mizchi8markdown7Scanner7advance(scanner, closing_count);
                  } else {
                    const _bind$4 = _M0MP26mizchi8markdown7Scanner7consume(scanner);
                    if (_bind$4 === -1) {
                      break;
                    } else {
                      const _Some$2 = _bind$4;
                      const _c = _Some$2;
                      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, _c);
                    }
                  }
                }
                continue;
              } else {
                break;
              }
            }
            if (!found_closing) {
              let _tmp = 0;
              while (true) {
                const j = _tmp;
                if (j < backtick_count) {
                  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 96);
                  _tmp = j + 1 | 0;
                  continue;
                } else {
                  break;
                }
              }
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(text_buf, content_buf.val);
            }
            break;
          }
          case 91: {
            const link_parser = _M0MP26mizchi8markdown12InlineParser3new(scanner);
            const _bind$4 = _M0MP26mizchi8markdown12InlineParser16try__parse__link(link_parser, pos);
            if (_bind$4 === undefined) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 91);
              _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
            } else {
              const _Some$2 = _bind$4;
              const _link = _Some$2;
              if (!(text_buf.val === "")) {
                _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(offset + text_start | 0, offset + pos | 0)));
                _M0MP311moonbitlang4core7builtin13StringBuilder5reset(text_buf);
              }
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, _link);
              text_start = scanner.pos;
            }
            break;
          }
          case 33: {
            const _p = _M0MP26mizchi8markdown7Scanner8peek__at(scanner, 1);
            const _p$2 = 91;
            let _tmp;
            if (_p === -1) {
              _tmp = false;
            } else {
              const _p$3 = _p;
              const _p$4 = _p$3;
              _tmp = _p$4 === _p$2;
            }
            if (_tmp) {
              const img_parser = _M0MP26mizchi8markdown12InlineParser3new(scanner);
              const _bind$5 = _M0MP26mizchi8markdown12InlineParser17try__parse__image(img_parser, pos);
              if (_bind$5 === undefined) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 33);
                _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
              } else {
                const _Some$2 = _bind$5;
                const _img = _Some$2;
                if (!(text_buf.val === "")) {
                  _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(offset + text_start | 0, offset + pos | 0)));
                  _M0MP311moonbitlang4core7builtin13StringBuilder5reset(text_buf);
                }
                _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, _img);
                text_start = scanner.pos;
              }
            } else {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 33);
              _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
            }
            break;
          }
          case 60: {
            const auto_parser = _M0MP26mizchi8markdown12InlineParser3new(scanner);
            const _bind$5 = _M0MP26mizchi8markdown12InlineParser20try__parse__autolink(auto_parser, pos);
            if (_bind$5 === undefined) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, 60);
              _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
            } else {
              const _Some$2 = _bind$5;
              const _autolink = _Some$2;
              if (!(text_buf.val === "")) {
                _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(offset + text_start | 0, offset + pos | 0)));
                _M0MP311moonbitlang4core7builtin13StringBuilder5reset(text_buf);
              }
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, _autolink);
              text_start = scanner.pos;
            }
            break;
          }
          case 10: {
            const content = text_buf.val;
            const trimmed = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String17trim__end_2einner(content, { str: _M0FP26mizchi8markdown39parse__segment__simple_2e_2abind_7c2649, start: 0, end: _M0FP26mizchi8markdown39parse__segment__simple_2e_2abind_7c2649.length }));
            const trailing_spaces = content.length - trimmed.length | 0;
            const is_hard_break = trailing_spaces >= 2;
            if (!(trimmed === "")) {
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Text(trimmed, _M0MP26mizchi8markdown4Span3new(offset + text_start | 0, (offset + pos | 0) - trailing_spaces | 0)));
            }
            _M0MP311moonbitlang4core7builtin13StringBuilder5reset(text_buf);
            _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
            while (true) {
              const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(scanner);
              const _p$4 = 32;
              let _tmp$2;
              if (_p$3 === -1) {
                _tmp$2 = false;
              } else {
                const _p$5 = _p$3;
                const _p$6 = _p$5;
                _tmp$2 = _p$6 === _p$4;
              }
              if (_tmp$2) {
                _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
                continue;
              } else {
                break;
              }
            }
            if (is_hard_break) {
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$HardBreak(0, _M0MP26mizchi8markdown4Span3new((offset + pos | 0) - trailing_spaces | 0, offset + scanner.pos | 0)));
            } else {
              _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$SoftBreak(_M0MP26mizchi8markdown4Span3new(offset + pos | 0, offset + scanner.pos | 0)));
            }
            text_start = scanner.pos;
            break;
          }
          default: {
            _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(text_buf, _x);
            _M0MP26mizchi8markdown7Scanner7advance(scanner, 1);
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  if (!(text_buf.val === "")) {
    _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown6InlineE(result, new $64$mizchi$47$markdown$46$Inline$Text(text_buf.val, _M0MP26mizchi8markdown4Span3new(offset + text_start | 0, offset + scanner.pos | 0)));
  }
  return result;
}
function _M0MP26mizchi8markdown11BlockParser20detect__list__marker(self) {
  const saved = self.scanner.pos;
  const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  if (_bind$3 === -1) {
  } else {
    const _Some = _bind$3;
    const _x = _Some;
    switch (_x) {
      case 45: {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        _L: {
          _L$2: {
            const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            if (_bind$4 === -1) {
            } else {
              const _Some$2 = _bind$4;
              const _x$2 = _Some$2;
              switch (_x$2) {
                case 32: {
                  break _L$2;
                }
                case 9: {
                  break _L$2;
                }
              }
            }
            break _L;
          }
          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
          return _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2044;
        }
        break;
      }
      case 42: {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        _L$2: {
          _L$3: {
            const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            if (_bind$4 === -1) {
            } else {
              const _Some$2 = _bind$4;
              const _x$2 = _Some$2;
              switch (_x$2) {
                case 32: {
                  break _L$3;
                }
                case 9: {
                  break _L$3;
                }
              }
            }
            break _L$2;
          }
          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
          return _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2047;
        }
        break;
      }
      case 43: {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        _L$3: {
          _L$4: {
            const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            if (_bind$4 === -1) {
            } else {
              const _Some$2 = _bind$4;
              const _x$2 = _Some$2;
              switch (_x$2) {
                case 32: {
                  break _L$4;
                }
                case 9: {
                  break _L$4;
                }
              }
            }
            break _L$3;
          }
          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
          return _M0FP26mizchi8markdown36detect__list__marker_2econstr_2f2050;
        }
        break;
      }
    }
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
  if (_M0FP26mizchi8markdown15char__is__digit(_M0MP26mizchi8markdown7Scanner4peek(self.scanner))) {
    let num = 0;
    let digits = 0;
    while (true) {
      if (_M0FP26mizchi8markdown15char__is__digit(_M0MP26mizchi8markdown7Scanner4peek(self.scanner))) {
        const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        if (_bind$4 === -1) {
          break;
        } else {
          const _Some = _bind$4;
          const _c = _Some;
          num = (Math.imul(num, 10) | 0) + (_c - 48 | 0) | 0;
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          digits = digits + 1 | 0;
          if (digits > 9) {
            _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
            return undefined;
          }
        }
        continue;
      } else {
        break;
      }
    }
    const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    if (_bind$4 === -1) {
    } else {
      const _Some = _bind$4;
      const _x = _Some;
      switch (_x) {
        case 46: {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          _L: {
            _L$2: {
              const _bind$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
              if (_bind$5 === -1) {
              } else {
                const _Some$2 = _bind$5;
                const _x$2 = _Some$2;
                switch (_x$2) {
                  case 32: {
                    break _L$2;
                  }
                  case 9: {
                    break _L$2;
                  }
                }
              }
              break _L;
            }
            _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
            return { _0: new $64$mizchi$47$markdown$46$ListMarkerKind$Ordered(num, 0), _1: digits + 2 | 0 };
          }
          break;
        }
        case 41: {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          _L$2: {
            _L$3: {
              const _bind$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
              if (_bind$5 === -1) {
              } else {
                const _Some$2 = _bind$5;
                const _x$2 = _Some$2;
                switch (_x$2) {
                  case 32: {
                    break _L$3;
                  }
                  case 9: {
                    break _L$3;
                  }
                }
              }
              break _L$2;
            }
            _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
            return { _0: new $64$mizchi$47$markdown$46$ListMarkerKind$Ordered(num, 1), _1: digits + 2 | 0 };
          }
          break;
        }
      }
    }
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
  return undefined;
}
function _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self) {
  const start = self.scanner.pos;
  const count = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  return count > 0 ? _M0MP26mizchi8markdown6Trivia3new(_M0MP26mizchi8markdown7Scanner9substring(self.scanner, start, start + count | 0)) : _M0FP26mizchi8markdown21empty_2erecord_2f1179;
}
function _M0MP26mizchi8markdown11BlockParser22read__trailing__trivia(self) {
  const start = self.scanner.pos;
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  return self.scanner.pos > start ? _M0MP26mizchi8markdown6Trivia3new(_M0MP26mizchi8markdown7Scanner9substring(self.scanner, start, self.scanner.pos)) : _M0FP26mizchi8markdown21empty_2erecord_2f1179;
}
function _M0MP26mizchi8markdown11BlockParser27try__parse__thematic__break(self, start) {
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  let marker;
  _L: {
    _L$2: {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        break _L$2;
      } else {
        const _Some = _bind$3;
        const _c = _Some;
        if (_c === 45 || (_c === 42 || _c === 95)) {
          marker = _c;
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  let count = 0;
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      _L$2: {
        _L$3: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$3;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            if (_x === 10) {
              break;
            } else {
              if (_x === marker) {
                count = count + 1 | 0;
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              } else {
                if (_x === 32 || _x === 9) {
                  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                } else {
                  break _L$3;
                }
              }
            }
          }
          break _L$2;
        }
        return undefined;
      }
      continue;
    } else {
      break;
    }
  }
  if (count < 3) {
    return undefined;
  }
  const trailing = _M0MP26mizchi8markdown11BlockParser22read__trailing__trivia(self);
  return new $64$mizchi$47$markdown$46$Block$ThematicBreak(marker, count, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, trailing);
}
function _M0MP26mizchi8markdown11BlockParser16parse__paragraph(self, start) {
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let first = true;
  _L: while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      if (_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner)) {
        break;
      }
      const saved = self.scanner.pos;
      _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      let c;
      _L$2: {
        _L$3: {
          _L$4: {
            _L$5: {
              _L$6: {
                _L$7: {
                  const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
                  if (_bind$3 === -1) {
                  } else {
                    const _Some = _bind$3;
                    const _x = _Some;
                    switch (_x) {
                      case 35: {
                        break _L$7;
                      }
                      case 62: {
                        break _L$7;
                      }
                      case 96: {
                        if (_M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(_M0MP26mizchi8markdown7Scanner8peek__at(self.scanner, 1), _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2105) && _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(_M0MP26mizchi8markdown7Scanner8peek__at(self.scanner, 2), _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2106)) {
                          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
                          break _L;
                        } else {
                          if (_x >= 48 && _x <= 57) {
                            c = _x;
                            break _L$3;
                          }
                        }
                        break;
                      }
                      case 126: {
                        if (_M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(_M0MP26mizchi8markdown7Scanner8peek__at(self.scanner, 1), _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2107) && _M0IP311moonbitlang4core6option6OptionP311moonbitlang4core7builtin2Eq5equalGcE(_M0MP26mizchi8markdown7Scanner8peek__at(self.scanner, 2), _M0FP26mizchi8markdown32parse__paragraph_2econstr_2f2108)) {
                          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
                          break _L;
                        } else {
                          if (_x >= 48 && _x <= 57) {
                            c = _x;
                            break _L$3;
                          }
                        }
                        break;
                      }
                      case 45: {
                        break _L$5;
                      }
                      case 42: {
                        break _L$5;
                      }
                      case 95: {
                        break _L$5;
                      }
                      default: {
                        if (_x >= 48 && _x <= 57) {
                          c = _x;
                          break _L$3;
                        }
                      }
                    }
                  }
                  break _L$6;
                }
                _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
                break;
              }
              break _L$4;
            }
            const _bind$3 = _M0MP26mizchi8markdown11BlockParser27try__parse__thematic__break(self, saved);
            if (_bind$3 === undefined) {
            } else {
              _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
              break;
            }
            _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
            const _bind$4 = _M0MP26mizchi8markdown11BlockParser20detect__list__marker(self);
            if (_bind$4 === undefined) {
            } else {
              break;
            }
          }
          break _L$2;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
        const _bind$3 = _M0MP26mizchi8markdown11BlockParser20detect__list__marker(self);
        if (_bind$3 === undefined) {
        } else {
          break;
        }
      }
      _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
      if (!first) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 10);
      }
      const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, line);
      first = false;
      const _p$2 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      const _p$3 = 10;
      let _tmp;
      if (_p$2 === -1) {
        _tmp = false;
      } else {
        const _p$4 = _p$2;
        const _p$5 = _p$4;
        _tmp = _p$5 === _p$3;
      }
      if (_tmp) {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      }
      continue;
    } else {
      break;
    }
  }
  const content = content_buf.val;
  if (_M0MP311moonbitlang4core6string10StringView9is__empty(_M0MP311moonbitlang4core6string6String12trim_2einner(content, { str: _M0FP26mizchi8markdown33parse__paragraph_2e_2abind_7c2739, start: 0, end: _M0FP26mizchi8markdown33parse__paragraph_2e_2abind_7c2739.length }))) {
    return undefined;
  }
  const children = _M0FP26mizchi8markdown22parse__inlines_2einner(content, self.strict);
  return new $64$mizchi$47$markdown$46$Block$Paragraph(children, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0FP26mizchi8markdown23parse__heading__content(line) {
  const trimmed = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String17trim__end_2einner(line, { str: _M0FP26mizchi8markdown40parse__heading__content_2e_2abind_7c2752, start: 0, end: _M0FP26mizchi8markdown40parse__heading__content_2e_2abind_7c2752.length }));
  let hash_count = 0;
  let idx = trimmed.length - 1 | 0;
  while (true) {
    if (idx >= 0) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP311moonbitlang4core6string6String9get__char(trimmed, idx);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            if (_x === 35) {
              hash_count = hash_count + 1 | 0;
              idx = idx - 1 | 0;
            } else {
              break _L$2;
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
  if (hash_count > 0 && idx >= 0) {
    _L: {
      _L$2: {
        const _bind$3 = _M0MP311moonbitlang4core6string6String9get__char(trimmed, idx);
        if (_bind$3 === -1) {
          break _L$2;
        } else {
          const _Some = _bind$3;
          const _x = _Some;
          switch (_x) {
            case 32: {
              break;
            }
            case 9: {
              break;
            }
            default: {
              break _L$2;
            }
          }
        }
        break _L;
      }
      return { _0: trimmed, _1: 0 };
    }
  }
  if (hash_count > 0) {
    const content = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String17trim__end_2einner(trimmed.substring(0, idx + 1 | 0), { str: _M0FP26mizchi8markdown40parse__heading__content_2e_2abind_7c2751, start: 0, end: _M0FP26mizchi8markdown40parse__heading__content_2e_2abind_7c2751.length }));
    return { _0: content, _1: hash_count };
  } else {
    return { _0: trimmed, _1: 0 };
  }
}
function _M0MP26mizchi8markdown11BlockParser24try__parse__atx__heading(self, start) {
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const level = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, 35);
  if (level < 1 || level > 6) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, level);
  const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  if (_bind$3 === -1) {
  } else {
    const _Some = _bind$3;
    const _x = _Some;
    switch (_x) {
      case 32: {
        break;
      }
      case 9: {
        break;
      }
      case 10: {
        break;
      }
      default: {
        return undefined;
      }
    }
  }
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  const _bind$4 = _M0FP26mizchi8markdown23parse__heading__content(line);
  const _content = _bind$4._0;
  const _closing_hashes = _bind$4._1;
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const trailing = _M0FP26mizchi8markdown21empty_2erecord_2f1179;
  const children = _M0FP26mizchi8markdown22parse__inlines_2einner(_content, self.strict);
  return new $64$mizchi$47$markdown$46$Block$Heading(level, 0, children, _closing_hashes, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, trailing);
}
function _M0FP26mizchi8markdown13strip__indent(line, n) {
  let stripped = 0;
  let idx = 0;
  while (true) {
    if (idx < line.length && stripped < n) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP311moonbitlang4core6string6String9get__char(line, idx);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 32: {
                stripped = stripped + 1 | 0;
                idx = idx + 1 | 0;
                break;
              }
              case 9: {
                stripped = stripped + 4 | 0;
                idx = idx + 1 | 0;
                break;
              }
              default: {
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
  return line.substring(idx, line.length);
}
function _M0MP26mizchi8markdown11BlockParser24try__parse__fenced__code(self, start, indent) {
  if (indent > 3) {
    return undefined;
  }
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  let fence_char;
  _L: {
    _L$2: {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        break _L$2;
      } else {
        const _Some = _bind$3;
        const _c = _Some;
        if (_c === 96 || _c === 126) {
          fence_char = _c;
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  const fence_marker = fence_char === 96 ? 0 : 1;
  const fence_length = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, fence_char);
  if (fence_length < 3) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, fence_length);
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  const info = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String17trim__end_2einner(_M0MP26mizchi8markdown7Scanner10read__line(self.scanner), { str: _M0FP26mizchi8markdown41try__parse__fenced__code_2e_2abind_7c2771, start: 0, end: _M0FP26mizchi8markdown41try__parse__fenced__code_2e_2abind_7c2771.length }));
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const code_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  while (true) {
    const _p$3 = self.scanner;
    if (!(_p$3.pos >= _p$3.len)) {
      const line_indent = _M0MP26mizchi8markdown7Scanner22count__leading__spaces(self.scanner);
      if (line_indent <= 3) {
        const saved = self.scanner.pos;
        _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
        if (_M0MP26mizchi8markdown7Scanner11count__char(self.scanner, fence_char) >= fence_length) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, fence_char));
          _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
          let _tmp$2;
          const _p$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          const _p$5 = 10;
          let _tmp$3;
          if (_p$4 === -1) {
            _tmp$3 = false;
          } else {
            const _p$6 = _p$4;
            const _p$7 = _p$6;
            _tmp$3 = _p$7 === _p$5;
          }
          if (_tmp$3) {
            _tmp$2 = true;
          } else {
            const _p$6 = self.scanner;
            _tmp$2 = _p$6.pos >= _p$6.len;
          }
          if (_tmp$2) {
            const _p$6 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            const _p$7 = 10;
            let _tmp$4;
            if (_p$6 === -1) {
              _tmp$4 = false;
            } else {
              const _p$8 = _p$6;
              const _p$9 = _p$8;
              _tmp$4 = _p$9 === _p$7;
            }
            if (_tmp$4) {
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            }
            break;
          }
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
      }
      const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
      const stripped = _M0FP26mizchi8markdown13strip__indent(line, indent);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(code_buf, stripped);
      const _p$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      const _p$5 = 10;
      let _tmp$2;
      if (_p$4 === -1) {
        _tmp$2 = false;
      } else {
        const _p$6 = _p$4;
        const _p$7 = _p$6;
        _tmp$2 = _p$7 === _p$5;
      }
      if (_tmp$2) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(code_buf, 10);
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      }
      continue;
    } else {
      break;
    }
  }
  const trailing = _M0FP26mizchi8markdown21empty_2erecord_2f1179;
  return new $64$mizchi$47$markdown$46$Block$FencedCode(fence_marker, fence_length, info, code_buf.val, indent, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, trailing);
}
function _M0FP26mizchi8markdown24is__custom__element__tag(tag) {
  if (tag === "") {
    return false;
  }
  const chars = _M0MP311moonbitlang4core6string6String9to__array(tag);
  const first = _M0MP311moonbitlang4core5array5Array2atGcE(chars, 0);
  if (!(first >= 97 && first <= 122 || first >= 65 && first <= 90)) {
    return false;
  }
  const _len = chars.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const c = chars[_i];
      if (c === 45) {
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
function _M0FP26mizchi8markdown20is__html__block__tag(tag) {
  if (_M0FP26mizchi8markdown24is__custom__element__tag(tag)) {
    return true;
  }
  const lower = _M0MP311moonbitlang4core6string6String9to__lower(tag);
  const _len = _M0FP26mizchi8markdown17html__block__tags.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const t = _M0FP26mizchi8markdown17html__block__tags[_i];
      if (lower === t) {
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
function _M0MP26mizchi8markdown11BlockParser23try__parse__html__block(self, start) {
  const saved = self.scanner.pos;
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 60;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (!_tmp) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const peek_pos = self.scanner.pos;
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 47;
  let is_closing;
  if (_p$3 === -1) {
    is_closing = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    is_closing = _p$6 === _p$4;
  }
  if (is_closing) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const tag_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  while (true) {
    const _p$5 = self.scanner;
    if (!(_p$5.pos >= _p$5.len)) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _c = _Some;
            if (_c >= 97 && _c <= 122 || (_c >= 65 && _c <= 90 || (_c >= 48 && _c <= 57 || _c === 45))) {
              _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(tag_buf, _c);
              _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
            } else {
              break _L$2;
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
  const tag_name = tag_buf.val;
  if (tag_name === "") {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const is_custom = _M0FP26mizchi8markdown24is__custom__element__tag(tag_name);
  if (!_M0FP26mizchi8markdown20is__html__block__tag(tag_name) && !is_custom) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7restore(self.scanner, peek_pos);
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const closing_tag = is_custom && !is_closing ? `</${tag_name}>` : undefined;
  while (true) {
    const _p$5 = self.scanner;
    if (!(_p$5.pos >= _p$5.len)) {
      const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
      _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, line);
      const _p$6 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      const _p$7 = 10;
      let _tmp$2;
      if (_p$6 === -1) {
        _tmp$2 = false;
      } else {
        const _p$8 = _p$6;
        const _p$9 = _p$8;
        _tmp$2 = _p$9 === _p$7;
      }
      if (_tmp$2) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 10);
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      }
      if (closing_tag === undefined) {
        if (_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner)) {
          break;
        }
      } else {
        const _Some = closing_tag;
        const _close = _Some;
        if (_M0MP311moonbitlang4core6string6String8contains(line, { str: _close, start: 0, end: _close.length })) {
          break;
        }
        if (_M0MP311moonbitlang4core6string6String20char__length_2einner(content_buf.val, 0, undefined) === (_M0MP311moonbitlang4core6string6String20char__length_2einner(line, 0, undefined) + 1 | 0)) {
          if (_M0MP311moonbitlang4core6string6String8contains(line, { str: _M0FP26mizchi8markdown40try__parse__html__block_2e_2abind_7c2788, start: 0, end: _M0FP26mizchi8markdown40try__parse__html__block_2e_2abind_7c2788.length })) {
            break;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  const html = content_buf.val;
  return new $64$mizchi$47$markdown$46$Block$HtmlBlock(html, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0MP26mizchi8markdown11BlockParser26try__parse__indented__code(self, start) {
  const leading = _M0FP26mizchi8markdown21empty_2erecord_2f1179;
  const code_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const line_start = self.scanner.pos;
      const indent = _M0MP26mizchi8markdown7Scanner22count__leading__spaces(self.scanner);
      if (indent < 4 && !_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner)) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, line_start);
        break;
      }
      if (_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner)) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(code_buf, 10);
        _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
      } else {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 4);
        const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(code_buf, line);
        const _p$2 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$3 = 10;
        let _tmp;
        if (_p$2 === -1) {
          _tmp = false;
        } else {
          const _p$4 = _p$2;
          const _p$5 = _p$4;
          _tmp = _p$5 === _p$3;
        }
        if (_tmp) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(code_buf, 10);
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        }
      }
      continue;
    } else {
      break;
    }
  }
  const code = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String17trim__end_2einner(code_buf.val, { str: _M0FP26mizchi8markdown43try__parse__indented__code_2e_2abind_7c2794, start: 0, end: _M0FP26mizchi8markdown43try__parse__indented__code_2e_2abind_7c2794.length }));
  if (code === "") {
    return undefined;
  }
  return new $64$mizchi$47$markdown$46$Block$IndentedCode(code, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0MP26mizchi8markdown11BlockParser28try__parse__link__definition(self, start) {
  const saved = self.scanner.pos;
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 91;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (!_tmp) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const label_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  _L: while (true) {
    const _p$3 = self.scanner;
    if (!(_p$3.pos >= _p$3.len)) {
      _L$2: {
        _L$3: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$3;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 93: {
                break _L;
              }
              case 10: {
                break _L$3;
              }
              default: {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(label_buf, _x);
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              }
            }
          }
          break _L$2;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
        return undefined;
      }
      continue;
    } else {
      break;
    }
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 58;
  let _tmp$2;
  if (_p$3 === -1) {
    _tmp$2 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$2 = _p$6 === _p$4;
  }
  if (!_tmp$2) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$6 = 10;
  let _tmp$3;
  if (_p$5 === -1) {
    _tmp$3 = false;
  } else {
    const _p$7 = _p$5;
    const _p$8 = _p$7;
    _tmp$3 = _p$8 === _p$6;
  }
  if (_tmp$3) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  }
  let url;
  const _p$7 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$8 = 60;
  let _tmp$4;
  if (_p$7 === -1) {
    _tmp$4 = false;
  } else {
    const _p$9 = _p$7;
    const _p$10 = _p$9;
    _tmp$4 = _p$10 === _p$8;
  }
  if (_tmp$4) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    const url_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    while (true) {
      let _tmp$5;
      const _p$9 = self.scanner;
      if (!(_p$9.pos >= _p$9.len)) {
        const _p$10 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$11 = 62;
        let _tmp$6;
        if (_p$10 === -1) {
          _tmp$6 = false;
        } else {
          const _p$12 = _p$10;
          const _p$13 = _p$12;
          _tmp$6 = _p$13 === _p$11;
        }
        _tmp$5 = !_tmp$6;
      } else {
        _tmp$5 = false;
      }
      if (_tmp$5) {
        const _bind$3 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
        if (_bind$3 === -1) {
          break;
        } else {
          const _Some = _bind$3;
          const _c = _Some;
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _c);
        }
        continue;
      } else {
        break;
      }
    }
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    url = url_buf.val;
  } else {
    const url_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    while (true) {
      const _p$9 = self.scanner;
      if (!(_p$9.pos >= _p$9.len)) {
        _L$2: {
          _L$3: {
            const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            if (_bind$3 === -1) {
              break _L$3;
            } else {
              const _Some = _bind$3;
              const _x = _Some;
              switch (_x) {
                case 32: {
                  break _L$3;
                }
                case 9: {
                  break _L$3;
                }
                case 10: {
                  break _L$3;
                }
                default: {
                  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(url_buf, _x);
                  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
                }
              }
            }
            break _L$2;
          }
          break;
        }
        continue;
      } else {
        break;
      }
    }
    url = url_buf.val;
  }
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  let title;
  _L$2: {
    _L$3: {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        title = "";
      } else {
        const _Some = _bind$3;
        const _x = _Some;
        switch (_x) {
          case 34: {
            break _L$3;
          }
          case 39: {
            break _L$3;
          }
          default: {
            title = "";
          }
        }
      }
      break _L$2;
    }
    const _bind$3 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
    const quote = _bind$3 === -1 ? 34 : _bind$3;
    const title_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
    while (true) {
      let _tmp$5;
      const _p$9 = self.scanner;
      if (!(_p$9.pos >= _p$9.len)) {
        const _p$10 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        let _tmp$6;
        if (_p$10 === -1) {
          _tmp$6 = false;
        } else {
          const _p$11 = _p$10;
          const _p$12 = _p$11;
          _tmp$6 = _p$12 === quote;
        }
        _tmp$5 = !_tmp$6;
      } else {
        _tmp$5 = false;
      }
      if (_tmp$5) {
        const _bind$4 = _M0MP26mizchi8markdown7Scanner7consume(self.scanner);
        if (_bind$4 === -1) {
          break;
        } else {
          const _Some = _bind$4;
          const _c = _Some;
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(title_buf, _c);
        }
        continue;
      } else {
        break;
      }
    }
    const _p$9 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
    let _tmp$5;
    if (_p$9 === -1) {
      _tmp$5 = false;
    } else {
      const _p$10 = _p$9;
      const _p$11 = _p$10;
      _tmp$5 = _p$11 === quote;
    }
    if (_tmp$5) {
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
    }
    title = title_buf.val;
  }
  _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
  const def = { label: _M0MP311moonbitlang4core6string6String9to__lower(label_buf.val), url: url, title: title, span: _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos) };
  _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown14LinkDefinitionE(self.definitions, def);
  return def;
}
function _M0FP26mizchi8markdown14skip__n__chars(s, n) {
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let i = 0;
  const _it = _M0MP311moonbitlang4core6string6String4iter(s);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      if (i >= n) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, _c);
      }
      i = i + 1 | 0;
      continue;
    }
  }
  return buf.val;
}
function _M0FP26mizchi8markdown21parse__task__checkbox(content) {
  if (content.length >= 4) {
    if (_M0MP311moonbitlang4core6string6String11has__prefix(content, { str: _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2837, start: 0, end: _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2837.length })) {
      return { _0: _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2271, _1: _M0FP26mizchi8markdown14skip__n__chars(content, 4) };
    }
    if (_M0MP311moonbitlang4core6string6String11has__prefix(content, { str: _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2838, start: 0, end: _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2838.length }) || _M0MP311moonbitlang4core6string6String11has__prefix(content, { str: _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2839, start: 0, end: _M0FP26mizchi8markdown38parse__task__checkbox_2e_2abind_7c2839.length })) {
      return { _0: _M0FP26mizchi8markdown37parse__task__checkbox_2econstr_2f2272, _1: _M0FP26mizchi8markdown14skip__n__chars(content, 4) };
    }
  }
  if (content === "[ ]") {
    return _M0FP26mizchi8markdown36parse__task__checkbox_2etuple_2f2274;
  }
  if (content === "[x]" || content === "[X]") {
    return _M0FP26mizchi8markdown36parse__task__checkbox_2etuple_2f2276;
  }
  return { _0: -1, _1: content };
}
function _M0MP26mizchi8markdown11BlockParser25parse__nested__list__item(self, start, marker_offset, content_offset) {
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, line);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const content = content_buf.val;
  const children = [];
  const _bind$3 = _M0FP26mizchi8markdown21parse__task__checkbox(content);
  const _checked = _bind$3._0;
  const _actual_content = _bind$3._1;
  if (!(_actual_content === "")) {
    const inline_content = _M0FP26mizchi8markdown22parse__inlines_2einner(_actual_content, self.strict);
    _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(children, new $64$mizchi$47$markdown$46$Block$Paragraph(inline_content, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), _M0FP26mizchi8markdown21empty_2erecord_2f1179, _M0FP26mizchi8markdown21empty_2erecord_2f1179));
  }
  return { children: children, checked: _checked, marker_offset: marker_offset, content_offset: content_offset, span: _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos) };
}
function _M0MP26mizchi8markdown11BlockParser27parse__nested__bullet__list(self, marker, min_indent) {
  const items = [];
  let tight = true;
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const item_start = self.scanner.pos;
      const marker_offset = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      if (marker_offset < min_indent) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, item_start);
        break;
      }
      let current_marker;
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 45: {
                current_marker = _M0FP26mizchi8markdown43parse__nested__bullet__list_2econstr_2f2290;
                break;
              }
              case 42: {
                current_marker = _M0FP26mizchi8markdown43parse__nested__bullet__list_2econstr_2f2291;
                break;
              }
              case 43: {
                current_marker = _M0FP26mizchi8markdown43parse__nested__bullet__list_2econstr_2f2292;
                break;
              }
              default: {
                break _L$2;
              }
            }
          }
          break _L;
        }
        current_marker = undefined;
      }
      if (_M0IP016_24default__implP311moonbitlang4core7builtin2Eq10not__equalGORP26mizchi8markdown12BulletMarkerE(current_marker, marker)) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, item_start);
        break;
      }
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      const content_offset = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      const actual_offset = content_offset === 0 ? 1 : content_offset;
      const item = _M0MP26mizchi8markdown11BlockParser25parse__nested__list__item(self, item_start, marker_offset, actual_offset);
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown8ListItemE(items, item);
      let _tmp;
      const _p$2 = self.scanner;
      if (!(_p$2.pos >= _p$2.len)) {
        _tmp = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
      } else {
        _tmp = false;
      }
      if (_tmp) {
        tight = false;
        while (true) {
          let _tmp$2;
          const _p$3 = self.scanner;
          if (!(_p$3.pos >= _p$3.len)) {
            _tmp$2 = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
          } else {
            _tmp$2 = false;
          }
          if (_tmp$2) {
            _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
            continue;
          } else {
            break;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  if (items.length === 0) {
    return undefined;
  }
  return new $64$mizchi$47$markdown$46$Block$BulletList(marker, tight, items, _M0MP26mizchi8markdown4Span3new(_M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown8ListItemE(items, 0).span.from, self.scanner.pos), _M0FP26mizchi8markdown21empty_2erecord_2f1179, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0MP26mizchi8markdown11BlockParser17parse__list__item(self, start, marker_offset, content_offset) {
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, line);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const content = content_buf.val;
  const children = [];
  const _bind$3 = _M0FP26mizchi8markdown21parse__task__checkbox(content);
  const _checked = _bind$3._0;
  const _actual_content = _bind$3._1;
  if (!(_actual_content === "")) {
    const inline_content = _M0FP26mizchi8markdown22parse__inlines_2einner(_actual_content, self.strict);
    _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(children, new $64$mizchi$47$markdown$46$Block$Paragraph(inline_content, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), _M0FP26mizchi8markdown21empty_2erecord_2f1179, _M0FP26mizchi8markdown21empty_2erecord_2f1179));
  }
  const min_indent = (marker_offset + 1 | 0) + content_offset | 0;
  while (true) {
    let _tmp$2;
    const _p$3 = self.scanner;
    if (!(_p$3.pos >= _p$3.len)) {
      _tmp$2 = !_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
    } else {
      _tmp$2 = false;
    }
    if (_tmp$2) {
      const saved = self.scanner.pos;
      const indent = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      if (indent < min_indent) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
        break;
      }
      _L: {
        _L$2: {
          _L$3: {
            const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
            if (_bind$4 === -1) {
              break _L$2;
            } else {
              const _Some = _bind$4;
              const _x = _Some;
              switch (_x) {
                case 45: {
                  break _L$3;
                }
                case 42: {
                  break _L$3;
                }
                case 43: {
                  break _L$3;
                }
                default: {
                  break _L$2;
                }
              }
            }
          }
          let nested_marker;
          _L$4: {
            _L$5: {
              const _bind$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
              if (_bind$4 === -1) {
                break _L$5;
              } else {
                const _Some = _bind$4;
                const _x = _Some;
                switch (_x) {
                  case 45: {
                    nested_marker = 0;
                    break;
                  }
                  case 42: {
                    nested_marker = 1;
                    break;
                  }
                  case 43: {
                    nested_marker = 2;
                    break;
                  }
                  default: {
                    break _L$5;
                  }
                }
              }
              break _L$4;
            }
            nested_marker = $panic();
          }
          _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
          const _bind$4 = _M0MP26mizchi8markdown11BlockParser27parse__nested__bullet__list(self, nested_marker, min_indent);
          if (_bind$4 === undefined) {
            break;
          } else {
            const _Some = _bind$4;
            const _nested_list = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(children, _nested_list);
          }
          break _L;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
        break;
      }
      continue;
    } else {
      break;
    }
  }
  return { children: children, checked: _checked, marker_offset: marker_offset, content_offset: content_offset, span: _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos) };
}
function _M0MP26mizchi8markdown11BlockParser19parse__bullet__list(self, start, leading, marker, _marker_width) {
  const items = [];
  let tight = true;
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const item_start = self.scanner.pos;
      const marker_offset = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      let current_marker;
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 45: {
                current_marker = _M0FP26mizchi8markdown35parse__bullet__list_2econstr_2f2339;
                break;
              }
              case 42: {
                current_marker = _M0FP26mizchi8markdown35parse__bullet__list_2econstr_2f2340;
                break;
              }
              case 43: {
                current_marker = _M0FP26mizchi8markdown35parse__bullet__list_2econstr_2f2341;
                break;
              }
              default: {
                break _L$2;
              }
            }
          }
          break _L;
        }
        current_marker = undefined;
      }
      if (_M0IP016_24default__implP311moonbitlang4core7builtin2Eq10not__equalGORP26mizchi8markdown12BulletMarkerE(current_marker, marker)) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, item_start);
        break;
      }
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      const content_offset = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      const actual_offset = content_offset === 0 ? 1 : content_offset;
      const item = _M0MP26mizchi8markdown11BlockParser17parse__list__item(self, item_start, marker_offset, actual_offset);
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown8ListItemE(items, item);
      let _tmp;
      const _p$2 = self.scanner;
      if (!(_p$2.pos >= _p$2.len)) {
        _tmp = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
      } else {
        _tmp = false;
      }
      if (_tmp) {
        tight = false;
        while (true) {
          let _tmp$2;
          const _p$3 = self.scanner;
          if (!(_p$3.pos >= _p$3.len)) {
            _tmp$2 = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
          } else {
            _tmp$2 = false;
          }
          if (_tmp$2) {
            _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
            continue;
          } else {
            break;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  if (items.length === 0) {
    return undefined;
  }
  return new $64$mizchi$47$markdown$46$Block$BulletList(marker, tight, items, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0MP26mizchi8markdown11BlockParser20parse__ordered__list(self, start, leading, start_num, delimiter, _marker_width) {
  const items = [];
  let tight = true;
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const item_start = self.scanner.pos;
      const marker_offset = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown11BlockParser20detect__list__marker(self);
          if (_bind$3 === undefined) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            const _x$2 = _x._0;
            if (_x$2.$tag === 1) {
              const _Ordered = _x$2;
              const _d = _Ordered._1;
              if (_M0IP26mizchi8markdown16OrderedDelimiterP311moonbitlang4core7builtin2Eq5equal(_d, delimiter)) {
              } else {
                break _L$2;
              }
            } else {
              break _L$2;
            }
          }
          break _L;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, item_start);
        break;
      }
      while (true) {
        if (_M0FP26mizchi8markdown15char__is__digit(_M0MP26mizchi8markdown7Scanner4peek(self.scanner))) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          continue;
        } else {
          break;
        }
      }
      _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      const content_offset = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      const actual_offset = content_offset === 0 ? 1 : content_offset;
      const item = _M0MP26mizchi8markdown11BlockParser17parse__list__item(self, item_start, marker_offset, actual_offset);
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown8ListItemE(items, item);
      let _tmp;
      const _p$2 = self.scanner;
      if (!(_p$2.pos >= _p$2.len)) {
        _tmp = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
      } else {
        _tmp = false;
      }
      if (_tmp) {
        tight = false;
        while (true) {
          let _tmp$2;
          const _p$3 = self.scanner;
          if (!(_p$3.pos >= _p$3.len)) {
            _tmp$2 = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
          } else {
            _tmp$2 = false;
          }
          if (_tmp$2) {
            _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
            continue;
          } else {
            break;
          }
        }
      }
      continue;
    } else {
      break;
    }
  }
  if (items.length === 0) {
    return undefined;
  }
  return new $64$mizchi$47$markdown$46$Block$OrderedList(start_num, delimiter, tight, items, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0MP26mizchi8markdown11BlockParser16try__parse__list(self, start) {
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const _bind$3 = _M0MP26mizchi8markdown11BlockParser20detect__list__marker(self);
  if (_bind$3 === undefined) {
    return undefined;
  } else {
    const _Some = _bind$3;
    const _x = _Some;
    const _marker_kind = _x._0;
    const _marker_width = _x._1;
    if (_marker_kind.$tag === 0) {
      const _Bullet = _marker_kind;
      const _marker = _Bullet._0;
      return _M0MP26mizchi8markdown11BlockParser19parse__bullet__list(self, start, leading, _marker, _marker_width);
    } else {
      const _Ordered = _marker_kind;
      const _start_num = _Ordered._0;
      const _delim = _Ordered._1;
      return _M0MP26mizchi8markdown11BlockParser20parse__ordered__list(self, start, leading, _start_num, _delim, _marker_width);
    }
  }
}
function _M0MP26mizchi8markdown11BlockParser27try__parse__setext__heading(self, start) {
  const saved = self.scanner.pos;
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const content = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  if (_M0MP311moonbitlang4core6string10StringView9is__empty(_M0MP311moonbitlang4core6string6String12trim_2einner(content, { str: _M0FP26mizchi8markdown44try__parse__setext__heading_2e_2abind_7c2913, start: 0, end: _M0FP26mizchi8markdown44try__parse__setext__heading_2e_2abind_7c2913.length }))) {
    return undefined;
  }
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  } else {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  let underline_char;
  _L: {
    _L$2: {
      const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      if (_bind$3 === -1) {
        break _L$2;
      } else {
        const _Some = _bind$3;
        const _c = _Some;
        if (_c === 61 || _c === 45) {
          underline_char = _c;
        } else {
          break _L$2;
        }
      }
      break _L;
    }
    return undefined;
  }
  const level = underline_char === 61 ? 1 : 2;
  const underline_count = _M0MP26mizchi8markdown7Scanner11count__char(self.scanner, underline_char);
  if (underline_count < 1) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, underline_count);
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  let _tmp$2;
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 10;
  let _tmp$3;
  if (_p$3 === -1) {
    _tmp$3 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$3 = _p$6 === _p$4;
  }
  if (!_tmp$3) {
    const _p$5 = self.scanner;
    _tmp$2 = !(_p$5.pos >= _p$5.len);
  } else {
    _tmp$2 = false;
  }
  if (_tmp$2) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$6 = 10;
  let _tmp$4;
  if (_p$5 === -1) {
    _tmp$4 = false;
  } else {
    const _p$7 = _p$5;
    const _p$8 = _p$7;
    _tmp$4 = _p$8 === _p$6;
  }
  if (_tmp$4) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const content_str = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String12trim_2einner(content, { str: _M0FP26mizchi8markdown44try__parse__setext__heading_2e_2abind_7c2914, start: 0, end: _M0FP26mizchi8markdown44try__parse__setext__heading_2e_2abind_7c2914.length }));
  const children = _M0FP26mizchi8markdown22parse__inlines_2einner(content_str, self.strict);
  return new $64$mizchi$47$markdown$46$Block$Heading(level, 1, children, 0, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0FP26mizchi8markdown19split__table__cells(line) {
  const cells = [];
  const buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let in_escape = false;
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < line.length) {
      let c;
      _L: {
        _L$2: {
          const _bind$3 = _M0MP311moonbitlang4core6string6String9get__char(line, i);
          if (_bind$3 === -1) {
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            switch (_x) {
              case 92: {
                if (!in_escape) {
                  in_escape = true;
                  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, 92);
                } else {
                  c = _x;
                  break _L$2;
                }
                break;
              }
              case 124: {
                if (!in_escape) {
                  _M0MP311moonbitlang4core5array5Array4pushGsE(cells, buf.val);
                  _M0MP311moonbitlang4core7builtin13StringBuilder5reset(buf);
                } else {
                  c = _x;
                  break _L$2;
                }
                break;
              }
              default: {
                c = _x;
                break _L$2;
              }
            }
          }
          break _L;
        }
        in_escape = false;
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(buf, c);
      }
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const last = buf.val;
  if (!_M0MP311moonbitlang4core6string10StringView9is__empty(_M0MP311moonbitlang4core6string6String12trim_2einner(last, { str: _M0FP26mizchi8markdown36split__table__cells_2e_2abind_7c2929, start: 0, end: _M0FP26mizchi8markdown36split__table__cells_2e_2abind_7c2929.length }))) {
    _M0MP311moonbitlang4core5array5Array4pushGsE(cells, last);
  }
  if (cells.length > 0) {
    const _bind$3 = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String12trim_2einner(_M0MP311moonbitlang4core5array5Array2atGsE(cells, 0), { str: _M0FP26mizchi8markdown36split__table__cells_2e_2abind_7c2930, start: 0, end: _M0FP26mizchi8markdown36split__table__cells_2e_2abind_7c2930.length }));
    if (_bind$3 === "") {
      _M0MP311moonbitlang4core5array5Array6removeGsE(cells, 0);
    }
  }
  return cells;
}
function _M0FP26mizchi8markdown24parse__table__alignments(line) {
  const alignments = [];
  const cells = _M0FP26mizchi8markdown19split__table__cells(line);
  const _len = cells.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      _L: {
        const cell = cells[_i];
        const trimmed = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String12trim_2einner(cell, { str: _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2946, start: 0, end: _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2946.length }));
        if (trimmed === "") {
          break _L;
        }
        const has_left_colon = _M0MP311moonbitlang4core6string6String11has__prefix(trimmed, { str: _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2945, start: 0, end: _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2945.length });
        const has_right_colon = _M0MP311moonbitlang4core6string6String11has__suffix(trimmed, { str: _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2944, start: 0, end: _M0FP26mizchi8markdown41parse__table__alignments_2e_2abind_7c2944.length });
        let has_dash = false;
        let _tmp$2 = 0;
        while (true) {
          const i = _tmp$2;
          if (i < trimmed.length) {
            _L$2: {
              _L$3: {
                const _bind$3 = _M0MP311moonbitlang4core6string6String9get__char(trimmed, i);
                if (_bind$3 === -1) {
                  break _L$3;
                } else {
                  const _Some = _bind$3;
                  const _x = _Some;
                  switch (_x) {
                    case 45: {
                      has_dash = true;
                      break;
                    }
                    case 58: {
                      break;
                    }
                    default: {
                      break _L$3;
                    }
                  }
                }
                break _L$2;
              }
              return [];
            }
            _tmp$2 = i + 1 | 0;
            continue;
          } else {
            break;
          }
        }
        if (!has_dash) {
          return [];
        }
        const align = has_left_colon && has_right_colon ? 1 : has_left_colon ? 0 : has_right_colon ? 2 : 3;
        _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown10TableAlignE(alignments, align);
        break _L;
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return alignments;
}
function _M0FP26mizchi8markdown17parse__table__row(line, expected_cols, strict) {
  const cells = [];
  const raw_cells = _M0FP26mizchi8markdown19split__table__cells(line);
  const _len = raw_cells.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const cell = raw_cells[_i];
      if (_i >= expected_cols) {
        break;
      }
      const content = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String12trim_2einner(cell, { str: _M0FP26mizchi8markdown34parse__table__row_2e_2abind_7c2949, start: 0, end: _M0FP26mizchi8markdown34parse__table__row_2e_2abind_7c2949.length }));
      const children = _M0FP26mizchi8markdown22parse__inlines_2einner(content, strict);
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown9TableCellE(cells, { children: children, span: _M0MP26mizchi8markdown4Span3new(0, content.length) });
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  while (true) {
    if (cells.length < expected_cols) {
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown9TableCellE(cells, { children: [], span: _M0MP26mizchi8markdown4Span3new(0, 0) });
      continue;
    } else {
      break;
    }
  }
  return cells;
}
function _M0MP26mizchi8markdown11BlockParser17try__parse__table(self, start) {
  const saved = self.scanner.pos;
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const header_line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  if (!_M0MP311moonbitlang4core6string6String8contains(header_line, { str: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2951, start: 0, end: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2951.length })) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const separator_line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  if (!_M0MP311moonbitlang4core6string6String8contains(separator_line, { str: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2952, start: 0, end: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2952.length }) || !_M0MP311moonbitlang4core6string6String8contains(separator_line, { str: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2953, start: 0, end: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2953.length })) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const alignments = _M0FP26mizchi8markdown24parse__table__alignments(separator_line);
  if (alignments.length === 0) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const header_cells = _M0FP26mizchi8markdown19split__table__cells(header_line);
  const _p$3 = [];
  const _p$4 = header_cells.length;
  let _tmp$2 = 0;
  while (true) {
    const _p$5 = _tmp$2;
    if (_p$5 < _p$4) {
      const _p$6 = header_cells[_p$5];
      if (!_M0MP311moonbitlang4core6string10StringView9is__empty(_M0MP311moonbitlang4core6string6String12trim_2einner(_p$6, { str: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2956, start: 0, end: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2956.length }))) {
        _M0MP311moonbitlang4core5array5Array4pushGsE(_p$3, _p$6);
      }
      _tmp$2 = _p$5 + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const header_col_count = _p$3.length;
  if (header_col_count !== alignments.length) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$6 = 10;
  let _tmp$3;
  if (_p$5 === -1) {
    _tmp$3 = false;
  } else {
    const _p$7 = _p$5;
    const _p$8 = _p$7;
    _tmp$3 = _p$8 === _p$6;
  }
  if (_tmp$3) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const header = _M0FP26mizchi8markdown17parse__table__row(header_line, alignments.length, self.strict);
  const rows = [];
  while (true) {
    let _tmp$4;
    const _p$7 = self.scanner;
    if (!(_p$7.pos >= _p$7.len)) {
      _tmp$4 = !_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
    } else {
      _tmp$4 = false;
    }
    if (_tmp$4) {
      const row_start = self.scanner.pos;
      const row_line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
      if (!_M0MP311moonbitlang4core6string6String8contains(row_line, { str: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2955, start: 0, end: _M0FP26mizchi8markdown34try__parse__table_2e_2abind_7c2955.length })) {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, row_start);
        break;
      }
      _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin5ArrayGRP26mizchi8markdown9TableCellEE(rows, _M0FP26mizchi8markdown17parse__table__row(row_line, alignments.length, self.strict));
      const _p$8 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      const _p$9 = 10;
      let _tmp$5;
      if (_p$8 === -1) {
        _tmp$5 = false;
      } else {
        const _p$10 = _p$8;
        const _p$11 = _p$10;
        _tmp$5 = _p$11 === _p$9;
      }
      if (_tmp$5) {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
      }
      continue;
    } else {
      break;
    }
  }
  return new $64$mizchi$47$markdown$46$Block$Table(header, alignments, rows, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0FP26mizchi8markdown19parse__simple__yaml(yaml) {
  const entries = [];
  const lines = _M0MP311moonbitlang4core6string6String5split(yaml, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2978, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2978.length });
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGRP311moonbitlang4core6string10StringViewE(lines);
    if (_bind$3 === undefined) {
      break;
    } else {
      const _Some = _bind$3;
      const _line = _Some;
      const trimmed = _M0MP311moonbitlang4core6string6String12trim_2einner(_M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_line), { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2972, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2972.length });
      if (_M0MP311moonbitlang4core6string10StringView9is__empty(trimmed) || _M0MP311moonbitlang4core6string10StringView11has__prefix(trimmed, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2959, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2959.length })) {
        continue;
      }
      const _bind$4 = _M0MP311moonbitlang4core6string10StringView4find(trimmed, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2966, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2966.length });
      if (_bind$4 === undefined) {
      } else {
        const _Some$2 = _bind$4;
        const _colon_idx = _Some$2;
        const key = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String12trim_2einner(_M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string10StringView12view_2einner(trimmed, 0, _colon_idx)), { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2965, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2965.length }));
        const value = _M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string6String12trim_2einner(_M0IP311moonbitlang4core6string10StringViewP311moonbitlang4core7builtin4Show10to__string(_M0MP311moonbitlang4core6string10StringView12view_2einner(trimmed, _colon_idx + 1 | 0, undefined)), { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2964, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2964.length }));
        const clean_value = _M0MP311moonbitlang4core6string6String11has__prefix(value, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2960, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2960.length }) && _M0MP311moonbitlang4core6string6String11has__suffix(value, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2961, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2961.length }) ? value.substring(1, value.length - 1 | 0) : _M0MP311moonbitlang4core6string6String11has__prefix(value, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2962, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2962.length }) && _M0MP311moonbitlang4core6string6String11has__suffix(value, { str: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2963, start: 0, end: _M0FP26mizchi8markdown36parse__simple__yaml_2e_2abind_7c2963.length }) ? value.substring(1, value.length - 1 | 0) : value;
        _M0MP311moonbitlang4core5array5Array4pushGUssEE(entries, { _0: key, _1: clean_value });
      }
      continue;
    }
  }
  return entries;
}
function _M0MP26mizchi8markdown11BlockParser23try__parse__frontmatter(self) {
  const start = self.scanner.pos;
  if (start !== 0) {
    return undefined;
  }
  if (!_M0MP26mizchi8markdown7Scanner7matches(self.scanner, "---")) {
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 3);
  _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
  let _tmp;
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 10;
  let _tmp$2;
  if (_p === -1) {
    _tmp$2 = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp$2 = _p$4 === _p$2;
  }
  if (!_tmp$2) {
    const _p$3 = self.scanner;
    _tmp = !(_p$3.pos >= _p$3.len);
  } else {
    _tmp = false;
  }
  if (_tmp) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 10;
  let _tmp$3;
  if (_p$3 === -1) {
    _tmp$3 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$3 = _p$6 === _p$4;
  }
  if (_tmp$3) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const yaml_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let found_closing = false;
  while (true) {
    const _p$5 = self.scanner;
    if (!(_p$5.pos >= _p$5.len)) {
      if (_M0MP26mizchi8markdown7Scanner7matches(self.scanner, "---")) {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 3);
        _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
        let _tmp$4;
        const _p$6 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$7 = 10;
        let _tmp$5;
        if (_p$6 === -1) {
          _tmp$5 = false;
        } else {
          const _p$8 = _p$6;
          const _p$9 = _p$8;
          _tmp$5 = _p$9 === _p$7;
        }
        if (_tmp$5) {
          _tmp$4 = true;
        } else {
          const _p$8 = self.scanner;
          _tmp$4 = _p$8.pos >= _p$8.len;
        }
        if (_tmp$4) {
          const _p$8 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          const _p$9 = 10;
          let _tmp$6;
          if (_p$8 === -1) {
            _tmp$6 = false;
          } else {
            const _p$10 = _p$8;
            const _p$11 = _p$10;
            _tmp$6 = _p$11 === _p$9;
          }
          if (_tmp$6) {
            _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
          }
          found_closing = true;
          break;
        }
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(yaml_buf, "---");
      } else {
        const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(yaml_buf, line);
        const _p$6 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$7 = 10;
        let _tmp$4;
        if (_p$6 === -1) {
          _tmp$4 = false;
        } else {
          const _p$8 = _p$6;
          const _p$9 = _p$8;
          _tmp$4 = _p$9 === _p$7;
        }
        if (_tmp$4) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(yaml_buf, 10);
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        }
      }
      continue;
    } else {
      break;
    }
  }
  if (!found_closing) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    return undefined;
  }
  const raw = yaml_buf.val;
  const entries = _M0FP26mizchi8markdown19parse__simple__yaml(raw);
  return { raw: raw, entries: entries, span: _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos) };
}
function _M0MP26mizchi8markdown11BlockParser15parse__document(self) {
  const start = self.scanner.pos;
  const frontmatter = _M0MP26mizchi8markdown11BlockParser23try__parse__frontmatter(self);
  const children = _M0MP26mizchi8markdown11BlockParser13parse__blocks(self);
  const document = { frontmatter: frontmatter, children: children, span: _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos) };
  return { document: document, definitions: self.definitions };
}
function _M0MP26mizchi8markdown11BlockParser13parse__blocks(self) {
  const blocks = [];
  while (true) {
    const _p = self.scanner;
    if (!(_p.pos >= _p.len)) {
      const blank_start = self.scanner.pos;
      let blank_count = 0;
      while (true) {
        let _tmp;
        const _p$2 = self.scanner;
        if (!(_p$2.pos >= _p$2.len)) {
          _tmp = _M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner);
        } else {
          _tmp = false;
        }
        if (_tmp) {
          blank_count = blank_count + 1 | 0;
          _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
          continue;
        } else {
          break;
        }
      }
      if (blank_count > 0) {
        _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(blocks, new $64$mizchi$47$markdown$46$Block$BlankLines(blank_count, _M0MP26mizchi8markdown4Span3new(blank_start, self.scanner.pos)));
      }
      const _p$2 = self.scanner;
      if (_p$2.pos >= _p$2.len) {
        break;
      }
      const _bind$3 = _M0MP26mizchi8markdown11BlockParser12parse__block(self);
      if (_bind$3 === undefined) {
        _M0MP26mizchi8markdown7Scanner10skip__line(self.scanner);
      } else {
        const _Some = _bind$3;
        const _block = _Some;
        _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(blocks, _block);
      }
      continue;
    } else {
      break;
    }
  }
  return blocks;
}
function _M0MP26mizchi8markdown11BlockParser12parse__block(self) {
  const start = self.scanner.pos;
  const indent = _M0MP26mizchi8markdown7Scanner22count__leading__spaces(self.scanner);
  const _bind$3 = _M0MP26mizchi8markdown11BlockParser27try__parse__thematic__break(self, start);
  if (_bind$3 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$3;
    const _block = _Some;
    return _block;
  }
  const _bind$4 = _M0MP26mizchi8markdown11BlockParser24try__parse__atx__heading(self, start);
  if (_bind$4 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$4;
    const _block = _Some;
    return _block;
  }
  const _bind$5 = _M0MP26mizchi8markdown11BlockParser24try__parse__fenced__code(self, start, indent);
  if (_bind$5 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$5;
    const _block = _Some;
    return _block;
  }
  const _bind$6 = _M0MP26mizchi8markdown11BlockParser22try__parse__blockquote(self, start);
  if (_bind$6 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$6;
    const _block = _Some;
    return _block;
  }
  const _bind$7 = _M0MP26mizchi8markdown11BlockParser16try__parse__list(self, start);
  if (_bind$7 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$7;
    const _block = _Some;
    return _block;
  }
  if (indent >= 4) {
    const _bind$8 = _M0MP26mizchi8markdown11BlockParser26try__parse__indented__code(self, start);
    if (_bind$8 === undefined) {
      _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
    } else {
      const _Some = _bind$8;
      const _block = _Some;
      return _block;
    }
  }
  const _bind$8 = _M0MP26mizchi8markdown11BlockParser27try__parse__setext__heading(self, start);
  if (_bind$8 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$8;
    const _block = _Some;
    return _block;
  }
  const _bind$9 = _M0MP26mizchi8markdown11BlockParser23try__parse__html__block(self, start);
  if (_bind$9 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$9;
    const _block = _Some;
    return _block;
  }
  const _bind$10 = _M0MP26mizchi8markdown11BlockParser17try__parse__table(self, start);
  if (_bind$10 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$10;
    const _block = _Some;
    return _block;
  }
  const _bind$11 = _M0MP26mizchi8markdown11BlockParser32try__parse__footnote__definition(self, start);
  if (_bind$11 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    const _Some = _bind$11;
    const _block = _Some;
    return _block;
  }
  const _bind$12 = _M0MP26mizchi8markdown11BlockParser28try__parse__link__definition(self, start);
  if (_bind$12 === undefined) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, start);
  } else {
    return undefined;
  }
  return _M0MP26mizchi8markdown11BlockParser16parse__paragraph(self, start);
}
function _M0MP26mizchi8markdown11BlockParser22try__parse__blockquote(self, start) {
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 62;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (!_tmp) {
    return undefined;
  }
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  let first = true;
  while (true) {
    const _p$3 = self.scanner;
    if (!(_p$3.pos >= _p$3.len)) {
      const line_start = self.scanner.pos;
      _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      const _p$4 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
      const _p$5 = 62;
      let _tmp$2;
      if (_p$4 === -1) {
        _tmp$2 = false;
      } else {
        const _p$6 = _p$4;
        const _p$7 = _p$6;
        _tmp$2 = _p$7 === _p$5;
      }
      if (_tmp$2) {
        _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        const _p$6 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$7 = 32;
        let _tmp$3;
        if (_p$6 === -1) {
          _tmp$3 = false;
        } else {
          const _p$8 = _p$6;
          const _p$9 = _p$8;
          _tmp$3 = _p$9 === _p$7;
        }
        if (_tmp$3) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        }
        const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
        if (!first) {
          _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 10);
        }
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, line);
        first = false;
        const _p$8 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$9 = 10;
        let _tmp$4;
        if (_p$8 === -1) {
          _tmp$4 = false;
        } else {
          const _p$10 = _p$8;
          const _p$11 = _p$10;
          _tmp$4 = _p$11 === _p$9;
        }
        if (_tmp$4) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        }
      } else {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, line_start);
        break;
      }
      continue;
    } else {
      break;
    }
  }
  const content = content_buf.val;
  const inner_scanner = _M0MP26mizchi8markdown7Scanner3new(content);
  const inner_parser = _M0MP26mizchi8markdown11BlockParser3new(inner_scanner, self.strict);
  const inner_result = _M0MP26mizchi8markdown11BlockParser15parse__document(inner_parser);
  const _arr = inner_result.definitions;
  const _len = _arr.length;
  let _tmp$2 = 0;
  while (true) {
    const _i = _tmp$2;
    if (_i < _len) {
      const def = _arr[_i];
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown14LinkDefinitionE(self.definitions, def);
      _tmp$2 = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return new $64$mizchi$47$markdown$46$Block$Blockquote(inner_result.document.children, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0MP26mizchi8markdown11BlockParser32try__parse__footnote__definition(self, start) {
  const saved = self.scanner.pos;
  const leading = _M0MP26mizchi8markdown11BlockParser21read__leading__trivia(self);
  const _p = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$2 = 91;
  let _tmp;
  if (_p === -1) {
    _tmp = false;
  } else {
    const _p$3 = _p;
    const _p$4 = _p$3;
    _tmp = _p$4 === _p$2;
  }
  if (!_tmp) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$4 = 94;
  let _tmp$2;
  if (_p$3 === -1) {
    _tmp$2 = false;
  } else {
    const _p$5 = _p$3;
    const _p$6 = _p$5;
    _tmp$2 = _p$6 === _p$4;
  }
  if (!_tmp$2) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const label_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  while (true) {
    const _p$5 = self.scanner;
    if (!(_p$5.pos >= _p$5.len)) {
      _L: {
        _L$2: {
          const _bind$3 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
          if (_bind$3 === -1) {
            break _L$2;
          } else {
            const _Some = _bind$3;
            const _x = _Some;
            if (_x === 93) {
              break;
            } else {
              if (_x >= 97 && _x <= 122 || (_x >= 65 && _x <= 90 || (_x >= 48 && _x <= 57 || (_x === 45 || _x === 95)))) {
                _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(label_buf, _x);
                _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
              } else {
                break _L$2;
              }
            }
          }
          break _L;
        }
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
        return undefined;
      }
      continue;
    } else {
      break;
    }
  }
  const label = label_buf.val;
  if (label === "") {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p$5 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$6 = 58;
  let _tmp$3;
  if (_p$5 === -1) {
    _tmp$3 = false;
  } else {
    const _p$7 = _p$5;
    const _p$8 = _p$7;
    _tmp$3 = _p$8 === _p$6;
  }
  if (!_tmp$3) {
    _M0MP26mizchi8markdown7Scanner7restore(self.scanner, saved);
    return undefined;
  }
  _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  const _p$7 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$8 = 32;
  let _tmp$4;
  if (_p$7 === -1) {
    _tmp$4 = false;
  } else {
    const _p$9 = _p$7;
    const _p$10 = _p$9;
    _tmp$4 = _p$10 === _p$8;
  }
  if (_tmp$4) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  const content_buf = _M0MP311moonbitlang4core7builtin13StringBuilder11new_2einner(0);
  const first_line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
  _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, first_line);
  const _p$9 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
  const _p$10 = 10;
  let _tmp$5;
  if (_p$9 === -1) {
    _tmp$5 = false;
  } else {
    const _p$11 = _p$9;
    const _p$12 = _p$11;
    _tmp$5 = _p$12 === _p$10;
  }
  if (_tmp$5) {
    _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
  }
  while (true) {
    const _p$11 = self.scanner;
    if (!(_p$11.pos >= _p$11.len)) {
      const line_start = self.scanner.pos;
      const indent = _M0MP26mizchi8markdown7Scanner12skip__spaces(self.scanner);
      if (_M0MP26mizchi8markdown7Scanner15is__blank__line(self.scanner)) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 10);
        const _p$12 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$13 = 10;
        let _tmp$6;
        if (_p$12 === -1) {
          _tmp$6 = false;
        } else {
          const _p$14 = _p$12;
          const _p$15 = _p$14;
          _tmp$6 = _p$15 === _p$13;
        }
        if (_tmp$6) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        }
        continue;
      }
      if (indent >= 2) {
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger11write__char(content_buf, 10);
        const line = _M0MP26mizchi8markdown7Scanner10read__line(self.scanner);
        _M0IP311moonbitlang4core7builtin13StringBuilderP311moonbitlang4core7builtin6Logger13write__string(content_buf, line);
        const _p$12 = _M0MP26mizchi8markdown7Scanner4peek(self.scanner);
        const _p$13 = 10;
        let _tmp$6;
        if (_p$12 === -1) {
          _tmp$6 = false;
        } else {
          const _p$14 = _p$12;
          const _p$15 = _p$14;
          _tmp$6 = _p$15 === _p$13;
        }
        if (_tmp$6) {
          _M0MP26mizchi8markdown7Scanner7advance(self.scanner, 1);
        }
      } else {
        _M0MP26mizchi8markdown7Scanner7restore(self.scanner, line_start);
        break;
      }
      continue;
    } else {
      break;
    }
  }
  const content = content_buf.val;
  const inner_scanner = _M0MP26mizchi8markdown7Scanner3new(content);
  const inner_parser = _M0MP26mizchi8markdown11BlockParser3new(inner_scanner, self.strict);
  const inner_result = _M0MP26mizchi8markdown11BlockParser15parse__document(inner_parser);
  return new $64$mizchi$47$markdown$46$Block$FootnoteDefinition(label, inner_result.document.children, _M0MP26mizchi8markdown4Span3new(start, self.scanner.pos), leading, _M0FP26mizchi8markdown21empty_2erecord_2f1179);
}
function _M0FP26mizchi8markdown13parse_2einner(source, strict) {
  const scanner = _M0MP26mizchi8markdown7Scanner3new(source);
  const parser = _M0MP26mizchi8markdown11BlockParser3new(scanner, strict);
  return _M0MP26mizchi8markdown11BlockParser15parse__document(parser);
}
function _M0FP26mizchi8markdown12md__to__html(source) {
  const result = _M0FP26mizchi8markdown13parse_2einner(source, false);
  return _M0FP26mizchi8markdown12render__html(result.document);
}
function _M0MP26mizchi8markdown8EditInfo7replace(offset, old_len, new_len) {
  return { offset: offset, old_len: old_len, new_len: new_len };
}
function _M0FP26mizchi8markdown13adjust__spans(blocks, offset) {
  const result = [];
  const _len = blocks.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const block = blocks[_i];
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(result, _M0FP26mizchi8markdown18shift__block__span(block, offset));
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  return result;
}
function _M0FP26mizchi8markdown18shift__block__span(block, delta) {
  switch (block.$tag) {
    case 0: {
      const _ThematicBreak = block;
      const _marker = _ThematicBreak._0;
      const _count = _ThematicBreak._1;
      const _span = _ThematicBreak._2;
      const _leading_trivia = _ThematicBreak._3;
      const _trailing_trivia = _ThematicBreak._4;
      return new $64$mizchi$47$markdown$46$Block$ThematicBreak(_marker, _count, _M0MP26mizchi8markdown4Span3new(_span.from + delta | 0, _span.to + delta | 0), _leading_trivia, _trailing_trivia);
    }
    case 1: {
      const _Heading = block;
      const _level = _Heading._0;
      const _style = _Heading._1;
      const _children = _Heading._2;
      const _closing_hashes = _Heading._3;
      const _span$2 = _Heading._4;
      const _leading_trivia$2 = _Heading._5;
      const _trailing_trivia$2 = _Heading._6;
      return new $64$mizchi$47$markdown$46$Block$Heading(_level, _style, _children, _closing_hashes, _M0MP26mizchi8markdown4Span3new(_span$2.from + delta | 0, _span$2.to + delta | 0), _leading_trivia$2, _trailing_trivia$2);
    }
    case 2: {
      const _Paragraph = block;
      const _children$2 = _Paragraph._0;
      const _span$3 = _Paragraph._1;
      const _leading_trivia$3 = _Paragraph._2;
      const _trailing_trivia$3 = _Paragraph._3;
      return new $64$mizchi$47$markdown$46$Block$Paragraph(_children$2, _M0MP26mizchi8markdown4Span3new(_span$3.from + delta | 0, _span$3.to + delta | 0), _leading_trivia$3, _trailing_trivia$3);
    }
    case 3: {
      const _FencedCode = block;
      const _fence_marker = _FencedCode._0;
      const _fence_length = _FencedCode._1;
      const _info = _FencedCode._2;
      const _code = _FencedCode._3;
      const _indent = _FencedCode._4;
      const _span$4 = _FencedCode._5;
      const _leading_trivia$4 = _FencedCode._6;
      const _trailing_trivia$4 = _FencedCode._7;
      return new $64$mizchi$47$markdown$46$Block$FencedCode(_fence_marker, _fence_length, _info, _code, _indent, _M0MP26mizchi8markdown4Span3new(_span$4.from + delta | 0, _span$4.to + delta | 0), _leading_trivia$4, _trailing_trivia$4);
    }
    case 4: {
      const _IndentedCode = block;
      const _code$2 = _IndentedCode._0;
      const _span$5 = _IndentedCode._1;
      const _leading_trivia$5 = _IndentedCode._2;
      const _trailing_trivia$5 = _IndentedCode._3;
      return new $64$mizchi$47$markdown$46$Block$IndentedCode(_code$2, _M0MP26mizchi8markdown4Span3new(_span$5.from + delta | 0, _span$5.to + delta | 0), _leading_trivia$5, _trailing_trivia$5);
    }
    case 5: {
      const _Blockquote = block;
      const _children$3 = _Blockquote._0;
      const _span$6 = _Blockquote._1;
      const _leading_trivia$6 = _Blockquote._2;
      const _trailing_trivia$6 = _Blockquote._3;
      return new $64$mizchi$47$markdown$46$Block$Blockquote(_M0FP26mizchi8markdown13adjust__spans(_children$3, delta), _M0MP26mizchi8markdown4Span3new(_span$6.from + delta | 0, _span$6.to + delta | 0), _leading_trivia$6, _trailing_trivia$6);
    }
    case 6: {
      const _BulletList = block;
      const _marker$2 = _BulletList._0;
      const _tight = _BulletList._1;
      const _items = _BulletList._2;
      const _span$7 = _BulletList._3;
      const _leading_trivia$7 = _BulletList._4;
      const _trailing_trivia$7 = _BulletList._5;
      return new $64$mizchi$47$markdown$46$Block$BulletList(_marker$2, _tight, _items, _M0MP26mizchi8markdown4Span3new(_span$7.from + delta | 0, _span$7.to + delta | 0), _leading_trivia$7, _trailing_trivia$7);
    }
    case 7: {
      const _OrderedList = block;
      const _start = _OrderedList._0;
      const _delimiter = _OrderedList._1;
      const _tight$2 = _OrderedList._2;
      const _items$2 = _OrderedList._3;
      const _span$8 = _OrderedList._4;
      const _leading_trivia$8 = _OrderedList._5;
      const _trailing_trivia$8 = _OrderedList._6;
      return new $64$mizchi$47$markdown$46$Block$OrderedList(_start, _delimiter, _tight$2, _items$2, _M0MP26mizchi8markdown4Span3new(_span$8.from + delta | 0, _span$8.to + delta | 0), _leading_trivia$8, _trailing_trivia$8);
    }
    case 9: {
      const _Table = block;
      const _header = _Table._0;
      const _alignments = _Table._1;
      const _rows = _Table._2;
      const _span$9 = _Table._3;
      const _leading_trivia$9 = _Table._4;
      const _trailing_trivia$9 = _Table._5;
      return new $64$mizchi$47$markdown$46$Block$Table(_header, _alignments, _rows, _M0MP26mizchi8markdown4Span3new(_span$9.from + delta | 0, _span$9.to + delta | 0), _leading_trivia$9, _trailing_trivia$9);
    }
    case 8: {
      const _HtmlBlock = block;
      const _html = _HtmlBlock._0;
      const _span$10 = _HtmlBlock._1;
      const _leading_trivia$10 = _HtmlBlock._2;
      const _trailing_trivia$10 = _HtmlBlock._3;
      return new $64$mizchi$47$markdown$46$Block$HtmlBlock(_html, _M0MP26mizchi8markdown4Span3new(_span$10.from + delta | 0, _span$10.to + delta | 0), _leading_trivia$10, _trailing_trivia$10);
    }
    case 10: {
      const _BlankLines = block;
      const _count$2 = _BlankLines._0;
      const _span$11 = _BlankLines._1;
      return new $64$mizchi$47$markdown$46$Block$BlankLines(_count$2, _M0MP26mizchi8markdown4Span3new(_span$11.from + delta | 0, _span$11.to + delta | 0));
    }
    default: {
      const _FootnoteDefinition = block;
      const _label = _FootnoteDefinition._0;
      const _children$4 = _FootnoteDefinition._1;
      const _span$12 = _FootnoteDefinition._2;
      const _leading_trivia$11 = _FootnoteDefinition._3;
      const _trailing_trivia$11 = _FootnoteDefinition._4;
      return new $64$mizchi$47$markdown$46$Block$FootnoteDefinition(_label, _children$4, _M0MP26mizchi8markdown4Span3new(_span$12.from + delta | 0, _span$12.to + delta | 0), _leading_trivia$11, _trailing_trivia$11);
    }
  }
}
function _M0MP26mizchi8markdown5Block9get__span(self) {
  switch (self.$tag) {
    case 0: {
      const _ThematicBreak = self;
      return _ThematicBreak._2;
    }
    case 1: {
      const _Heading = self;
      return _Heading._4;
    }
    case 2: {
      const _Paragraph = self;
      return _Paragraph._1;
    }
    case 3: {
      const _FencedCode = self;
      return _FencedCode._5;
    }
    case 4: {
      const _IndentedCode = self;
      return _IndentedCode._1;
    }
    case 5: {
      const _Blockquote = self;
      return _Blockquote._1;
    }
    case 6: {
      const _BulletList = self;
      return _BulletList._3;
    }
    case 7: {
      const _OrderedList = self;
      return _OrderedList._4;
    }
    case 9: {
      const _Table = self;
      return _Table._3;
    }
    case 8: {
      const _HtmlBlock = self;
      return _HtmlBlock._1;
    }
    case 10: {
      const _BlankLines = self;
      return _BlankLines._1;
    }
    default: {
      const _FootnoteDefinition = self;
      return _FootnoteDefinition._2;
    }
  }
}
function _M0FP26mizchi8markdown21find__affected__range(blocks, edit) {
  const edit_start = edit.offset;
  const edit_end = edit.offset + edit.old_len | 0;
  let first_affected = blocks.length;
  let first_unaffected = blocks.length;
  const _len = blocks.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const block = blocks[_i];
      const span = _M0MP26mizchi8markdown5Block9get__span(block);
      if (span.to > edit_start && span.from < edit_end) {
        if (first_affected === blocks.length) {
          first_affected = _i;
        }
        first_unaffected = _i + 1 | 0;
      } else {
        if (span.from >= edit_end) {
          if (first_unaffected === blocks.length || first_unaffected <= _i) {
            first_unaffected = _i;
          }
          break;
        }
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  if (first_affected === blocks.length) {
    const _len$2 = blocks.length;
    let _tmp$2 = 0;
    while (true) {
      const _i = _tmp$2;
      if (_i < _len$2) {
        const block = blocks[_i];
        const span = _M0MP26mizchi8markdown5Block9get__span(block);
        if (span.from > edit_start) {
          first_affected = _i;
          first_unaffected = _i;
          break;
        }
        if (span.to >= edit_start) {
          first_affected = _i;
          first_unaffected = _i + 1 | 0;
          break;
        }
        _tmp$2 = _i + 1 | 0;
        continue;
      } else {
        break;
      }
    }
  }
  return { _0: first_affected, _1: first_unaffected };
}
function _M0FP26mizchi8markdown18parse__incremental(old_doc, old_source, new_source, edit) {
  const old_blocks = old_doc.children;
  const _bind$3 = _M0FP26mizchi8markdown21find__affected__range(old_blocks, edit);
  const _before_idx = _bind$3._0;
  const _after_idx = _bind$3._1;
  let reparse_start;
  if (_before_idx > 0) {
    reparse_start = _M0MP26mizchi8markdown5Block9get__span(_M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown5BlockE(old_blocks, _before_idx - 1 | 0)).to;
  } else {
    const _bind$4 = old_doc.frontmatter;
    if (_bind$4 === undefined) {
      reparse_start = 0;
    } else {
      const _Some = _bind$4;
      const _fm = _Some;
      reparse_start = _fm.span.to;
    }
  }
  const reparse_end_old = _after_idx < old_blocks.length ? _M0MP26mizchi8markdown5Block9get__span(_M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown5BlockE(old_blocks, _after_idx)).from : old_source.length;
  const delta = edit.new_len - edit.old_len | 0;
  const reparse_end_new = reparse_end_old + delta | 0;
  const _p = new_source.length;
  const reparse_region = new_source.substring(reparse_start, reparse_end_new < reparse_start ? reparse_start : reparse_end_new > _p ? _p : reparse_end_new);
  const region_result = _M0FP26mizchi8markdown13parse_2einner(reparse_region, false);
  const new_blocks_raw = region_result.document.children;
  const new_blocks = _M0FP26mizchi8markdown13adjust__spans(new_blocks_raw, reparse_start);
  const final_blocks = [];
  let _tmp = 0;
  while (true) {
    const i = _tmp;
    if (i < _before_idx) {
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(final_blocks, _M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown5BlockE(old_blocks, i));
      _tmp = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _len = new_blocks.length;
  let _tmp$2 = 0;
  while (true) {
    const _i = _tmp$2;
    if (_i < _len) {
      const block = new_blocks[_i];
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(final_blocks, block);
      _tmp$2 = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const reparsed = new_blocks.length;
  const reused_after_count = old_blocks.length - _after_idx | 0;
  let _tmp$3 = _after_idx;
  while (true) {
    const i = _tmp$3;
    if (i < old_blocks.length) {
      _M0MP311moonbitlang4core5array5Array4pushGRP26mizchi8markdown5BlockE(final_blocks, _M0FP26mizchi8markdown18shift__block__span(_M0MP311moonbitlang4core5array5Array2atGRP26mizchi8markdown5BlockE(old_blocks, i), delta));
      _tmp$3 = i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const new_doc = { frontmatter: old_doc.frontmatter, children: final_blocks, span: _M0MP26mizchi8markdown4Span3new(0, new_source.length) };
  return { document: new_doc, reused_before: _before_idx, reparsed: reparsed, reused_after: reused_after_count };
}
function _M0FP36mizchi8markdown3api18position__to__json(span) {
  const _bind$3 = [{ _0: "offset", _1: _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin6ToJson8to__json(span.from) }];
  const _p = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$3, start: 0, end: 1 });
  const _tmp = { _0: "start", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p) };
  const _bind$4 = [{ _0: "offset", _1: _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin6ToJson8to__json(span.to) }];
  const _p$2 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$4, start: 0, end: 1 });
  const _bind$5 = [_tmp, { _0: "end", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$2) }];
  const _p$3 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$5, start: 0, end: 2 });
  return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$3);
}
function _M0FP36mizchi8markdown3api16inline__to__json(inline) {
  switch (inline.$tag) {
    case 0: {
      const _Text = inline;
      const _content = _Text._0;
      const _span = _Text._1;
      const _p = "text";
      const _bind$3 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p) }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_content) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span) }];
      const _p$2 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$3, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$2);
    }
    case 1: {
      const _SoftBreak = inline;
      const _span$2 = _SoftBreak._0;
      const _p$3 = "text";
      const _tmp = { _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$3) };
      const _p$4 = "\n";
      const _bind$4 = [_tmp, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$4) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$2) }];
      const _p$5 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$4, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$5);
    }
    case 2: {
      const _HardBreak = inline;
      const _span$3 = _HardBreak._1;
      const _p$6 = "break";
      const _bind$5 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$6) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$3) }];
      const _p$7 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$5, start: 0, end: 2 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$7);
    }
    case 3: {
      const _Emphasis = inline;
      const _children = _Emphasis._1;
      const _span$4 = _Emphasis._2;
      const inlines = [];
      const _len = _children.length;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len) {
          const child = _children[_i];
          const _bind$6 = _M0FP36mizchi8markdown3api16inline__to__json(child);
          if (_bind$6 === undefined) {
          } else {
            const _Some = _bind$6;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines, _json);
          }
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$8 = "emphasis";
      const _bind$6 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$8) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$4) }];
      const _p$9 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$6, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$9);
    }
    case 4: {
      const _Strong = inline;
      const _children$2 = _Strong._1;
      const _span$5 = _Strong._2;
      const inlines$2 = [];
      const _len$2 = _children$2.length;
      let _tmp$3 = 0;
      while (true) {
        const _i = _tmp$3;
        if (_i < _len$2) {
          const child = _children$2[_i];
          const _bind$7 = _M0FP36mizchi8markdown3api16inline__to__json(child);
          if (_bind$7 === undefined) {
          } else {
            const _Some = _bind$7;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines$2, _json);
          }
          _tmp$3 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$10 = "strong";
      const _bind$7 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$10) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$5) }];
      const _p$11 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$7, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$11);
    }
    case 5: {
      const _Strikethrough = inline;
      const _children$3 = _Strikethrough._0;
      const _span$6 = _Strikethrough._1;
      const inlines$3 = [];
      const _len$3 = _children$3.length;
      let _tmp$4 = 0;
      while (true) {
        const _i = _tmp$4;
        if (_i < _len$3) {
          const child = _children$3[_i];
          const _bind$8 = _M0FP36mizchi8markdown3api16inline__to__json(child);
          if (_bind$8 === undefined) {
          } else {
            const _Some = _bind$8;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines$3, _json);
          }
          _tmp$4 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$12 = "delete";
      const _bind$8 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$12) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines$3) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$6) }];
      const _p$13 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$8, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$13);
    }
    case 6: {
      const _Code = inline;
      const _content$2 = _Code._0;
      const _span$7 = _Code._2;
      const _p$14 = "inlineCode";
      const _bind$9 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$14) }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_content$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$7) }];
      const _p$15 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$9, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$15);
    }
    case 7: {
      const _Link = inline;
      const _children$4 = _Link._0;
      const _url = _Link._1;
      const _title = _Link._2;
      const _span$8 = _Link._3;
      const inlines$4 = [];
      const _len$4 = _children$4.length;
      let _tmp$5 = 0;
      while (true) {
        const _i = _tmp$5;
        if (_i < _len$4) {
          const child = _children$4[_i];
          const _bind$10 = _M0FP36mizchi8markdown3api16inline__to__json(child);
          if (_bind$10 === undefined) {
          } else {
            const _Some = _bind$10;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines$4, _json);
          }
          _tmp$5 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$16 = "link";
      const _bind$10 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$16) }, { _0: "url", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_url) }, { _0: "title", _1: _title === "" ? $64$moonbitlang$47$core$47$builtin$46$Json$Null : new $64$moonbitlang$47$core$47$builtin$46$Json$String(_title) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines$4) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$8) }];
      const _p$17 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$10, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$17);
    }
    case 8: {
      const _RefLink = inline;
      const _children$5 = _RefLink._0;
      const _label = _RefLink._1;
      const _span$9 = _RefLink._2;
      const inlines$5 = [];
      const _len$5 = _children$5.length;
      let _tmp$6 = 0;
      while (true) {
        const _i = _tmp$6;
        if (_i < _len$5) {
          const child = _children$5[_i];
          const _bind$11 = _M0FP36mizchi8markdown3api16inline__to__json(child);
          if (_bind$11 === undefined) {
          } else {
            const _Some = _bind$11;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines$5, _json);
          }
          _tmp$6 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$18 = "linkReference";
      const _tmp$7 = { _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$18) };
      const _tmp$8 = { _0: "identifier", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label) };
      const _tmp$9 = { _0: "label", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label) };
      const _p$19 = "full";
      const _bind$11 = [_tmp$7, _tmp$8, _tmp$9, { _0: "referenceType", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$19) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines$5) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$9) }];
      const _p$20 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$11, start: 0, end: 6 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$20);
    }
    case 9: {
      const _Autolink = inline;
      const _url$2 = _Autolink._0;
      const _is_email = _Autolink._1;
      const _span$10 = _Autolink._2;
      const href = _is_email ? `mailto:${_url$2}` : _url$2;
      const _p$21 = "link";
      const _tmp$10 = { _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$21) };
      const _tmp$11 = { _0: "url", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(href) };
      const _tmp$12 = { _0: "title", _1: $64$moonbitlang$47$core$47$builtin$46$Json$Null };
      const _p$22 = "text";
      const _bind$12 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$22) }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_url$2) }];
      const _p$23 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$12, start: 0, end: 2 });
      const _p$24 = [new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$23)];
      const _bind$13 = [_tmp$10, _tmp$11, _tmp$12, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(_p$24) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$10) }];
      const _p$25 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$13, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$25);
    }
    case 10: {
      const _Image = inline;
      const _alt = _Image._0;
      const _url$3 = _Image._1;
      const _title$2 = _Image._2;
      const _span$11 = _Image._3;
      const _p$26 = "image";
      const _bind$14 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$26) }, { _0: "url", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_url$3) }, { _0: "title", _1: _title$2 === "" ? $64$moonbitlang$47$core$47$builtin$46$Json$Null : new $64$moonbitlang$47$core$47$builtin$46$Json$String(_title$2) }, { _0: "alt", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_alt) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$11) }];
      const _p$27 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$14, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$27);
    }
    case 11: {
      const _RefImage = inline;
      const _alt$2 = _RefImage._0;
      const _label$2 = _RefImage._1;
      const _span$12 = _RefImage._2;
      const _p$28 = "imageReference";
      const _tmp$13 = { _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$28) };
      const _tmp$14 = { _0: "identifier", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label$2) };
      const _tmp$15 = { _0: "label", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label$2) };
      const _p$29 = "full";
      const _bind$15 = [_tmp$13, _tmp$14, _tmp$15, { _0: "referenceType", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$29) }, { _0: "alt", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_alt$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$12) }];
      const _p$30 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$15, start: 0, end: 6 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$30);
    }
    case 12: {
      const _HtmlInline = inline;
      const _html = _HtmlInline._0;
      const _span$13 = _HtmlInline._1;
      const _p$31 = "html";
      const _bind$16 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$31) }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_html) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$13) }];
      const _p$32 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$16, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$32);
    }
    default: {
      const _FootnoteReference = inline;
      const _label$3 = _FootnoteReference._0;
      const _span$14 = _FootnoteReference._1;
      const _p$33 = "footnoteReference";
      const _bind$17 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$33) }, { _0: "identifier", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label$3) }, { _0: "label", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label$3) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$14) }];
      const _p$34 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$17, start: 0, end: 4 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$34);
    }
  }
}
function _M0FP36mizchi8markdown3api17parse__code__info(info) {
  if (info === "") {
    return { _0: $64$moonbitlang$47$core$47$builtin$46$Json$Null, _1: $64$moonbitlang$47$core$47$builtin$46$Json$Null };
  }
  let space_idx = -1;
  let idx = 0;
  const _it = _M0MP311moonbitlang4core6string6String4iter(info);
  while (true) {
    const _bind$3 = _M0MP311moonbitlang4core7builtin4Iter4nextGcE(_it);
    if (_bind$3 === -1) {
      break;
    } else {
      const _Some = _bind$3;
      const _c = _Some;
      if (_c === 32) {
        space_idx = idx;
        break;
      }
      idx = idx + 1 | 0;
      continue;
    }
  }
  if (space_idx < 0) {
    return { _0: new $64$moonbitlang$47$core$47$builtin$46$Json$String(info), _1: $64$moonbitlang$47$core$47$builtin$46$Json$Null };
  } else {
    const lang = info.substring(0, space_idx);
    const meta = info.substring(space_idx + 1 | 0, info.length);
    return { _0: new $64$moonbitlang$47$core$47$builtin$46$Json$String(lang), _1: meta === "" ? $64$moonbitlang$47$core$47$builtin$46$Json$Null : new $64$moonbitlang$47$core$47$builtin$46$Json$String(meta) };
  }
}
function _M0FP36mizchi8markdown3api22table__align__to__json(align) {
  switch (align) {
    case 0: {
      const _p = "left";
      return new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p);
    }
    case 1: {
      const _p$2 = "center";
      return new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$2);
    }
    case 2: {
      const _p$3 = "right";
      return new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$3);
    }
    default: {
      return $64$moonbitlang$47$core$47$builtin$46$Json$Null;
    }
  }
}
function _M0FP36mizchi8markdown3api21table__cell__to__json(cell) {
  const inlines = [];
  const _arr = cell.children;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const inline = _arr[_i];
      const _bind$3 = _M0FP36mizchi8markdown3api16inline__to__json(inline);
      if (_bind$3 === undefined) {
      } else {
        const _Some = _bind$3;
        const _json = _Some;
        _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines, _json);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _p = "tableCell";
  const _bind$3 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(cell.span) }];
  const _p$2 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$3, start: 0, end: 3 });
  return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$2);
}
function _M0FP36mizchi8markdown3api15block__to__json(block) {
  switch (block.$tag) {
    case 2: {
      const _Paragraph = block;
      const _children = _Paragraph._0;
      const _span = _Paragraph._1;
      const inlines = [];
      const _len = _children.length;
      let _tmp = 0;
      while (true) {
        const _i = _tmp;
        if (_i < _len) {
          const inline = _children[_i];
          const _bind$3 = _M0FP36mizchi8markdown3api16inline__to__json(inline);
          if (_bind$3 === undefined) {
          } else {
            const _Some = _bind$3;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines, _json);
          }
          _tmp = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p = "paragraph";
      const _bind$3 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span) }];
      const _p$2 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$3, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$2);
    }
    case 1: {
      const _Heading = block;
      const _level = _Heading._0;
      const _children$2 = _Heading._2;
      const _span$2 = _Heading._4;
      const inlines$2 = [];
      const _len$2 = _children$2.length;
      let _tmp$2 = 0;
      while (true) {
        const _i = _tmp$2;
        if (_i < _len$2) {
          const inline = _children$2[_i];
          const _bind$4 = _M0FP36mizchi8markdown3api16inline__to__json(inline);
          if (_bind$4 === undefined) {
          } else {
            const _Some = _bind$4;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(inlines$2, _json);
          }
          _tmp$2 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$3 = "heading";
      const _bind$4 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$3) }, { _0: "depth", _1: _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin6ToJson8to__json(_level) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(inlines$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$2) }];
      const _p$4 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$4, start: 0, end: 4 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$4);
    }
    case 3: {
      const _FencedCode = block;
      const _info = _FencedCode._2;
      const _code = _FencedCode._3;
      const _span$3 = _FencedCode._5;
      const _bind$5 = _M0FP36mizchi8markdown3api17parse__code__info(_info);
      const _lang = _bind$5._0;
      const _meta = _bind$5._1;
      const _p$5 = "code";
      const _bind$6 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$5) }, { _0: "lang", _1: _lang }, { _0: "meta", _1: _meta }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_code) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$3) }];
      const _p$6 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$6, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$6);
    }
    case 4: {
      const _IndentedCode = block;
      const _code$2 = _IndentedCode._0;
      const _span$4 = _IndentedCode._1;
      const _p$7 = "code";
      const _bind$7 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$7) }, { _0: "lang", _1: $64$moonbitlang$47$core$47$builtin$46$Json$Null }, { _0: "meta", _1: $64$moonbitlang$47$core$47$builtin$46$Json$Null }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_code$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$4) }];
      const _p$8 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$7, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$8);
    }
    case 5: {
      const _Blockquote = block;
      const _children$3 = _Blockquote._0;
      const _span$5 = _Blockquote._1;
      const blocks = [];
      const _len$3 = _children$3.length;
      let _tmp$3 = 0;
      while (true) {
        const _i = _tmp$3;
        if (_i < _len$3) {
          const child = _children$3[_i];
          const _bind$8 = _M0FP36mizchi8markdown3api15block__to__json(child);
          if (_bind$8 === undefined) {
          } else {
            const _Some = _bind$8;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(blocks, _json);
          }
          _tmp$3 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$9 = "blockquote";
      const _bind$8 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$9) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(blocks) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$5) }];
      const _p$10 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$8, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$10);
    }
    case 6: {
      const _BulletList = block;
      const _items = _BulletList._2;
      const _tight = _BulletList._1;
      const _span$6 = _BulletList._3;
      const list_items = [];
      const _len$4 = _items.length;
      let _tmp$4 = 0;
      while (true) {
        const _i = _tmp$4;
        if (_i < _len$4) {
          const item = _items[_i];
          _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(list_items, _M0FP36mizchi8markdown3api20list__item__to__json(item, _tight));
          _tmp$4 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$11 = "list";
      const _bind$9 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$11) }, { _0: "ordered", _1: _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(false) }, { _0: "spread", _1: _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(!_tight) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(list_items) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$6) }];
      const _p$12 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$9, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$12);
    }
    case 7: {
      const _OrderedList = block;
      const _start = _OrderedList._0;
      const _items$2 = _OrderedList._3;
      const _tight$2 = _OrderedList._2;
      const _span$7 = _OrderedList._4;
      const list_items$2 = [];
      const _len$5 = _items$2.length;
      let _tmp$5 = 0;
      while (true) {
        const _i = _tmp$5;
        if (_i < _len$5) {
          const item = _items$2[_i];
          _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(list_items$2, _M0FP36mizchi8markdown3api20list__item__to__json(item, _tight$2));
          _tmp$5 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$13 = "list";
      const _bind$10 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$13) }, { _0: "ordered", _1: _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(true) }, { _0: "start", _1: _M0IP311moonbitlang4core3int3IntP311moonbitlang4core7builtin6ToJson8to__json(_start) }, { _0: "spread", _1: _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(!_tight$2) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(list_items$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$7) }];
      const _p$14 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$10, start: 0, end: 6 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$14);
    }
    case 0: {
      const _ThematicBreak = block;
      const _span$8 = _ThematicBreak._2;
      const _p$15 = "thematicBreak";
      const _bind$11 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$15) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$8) }];
      const _p$16 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$11, start: 0, end: 2 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$16);
    }
    case 8: {
      const _HtmlBlock = block;
      const _html = _HtmlBlock._0;
      const _span$9 = _HtmlBlock._1;
      const _p$17 = "html";
      const _bind$12 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$17) }, { _0: "value", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_html) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$9) }];
      const _p$18 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$12, start: 0, end: 3 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$18);
    }
    case 9: {
      const _Table = block;
      const _header = _Table._0;
      const _alignments = _Table._1;
      const _rows = _Table._2;
      const _span$10 = _Table._3;
      const table_rows = [];
      const header_cells = [];
      const _len$6 = _header.length;
      let _tmp$6 = 0;
      while (true) {
        const _i = _tmp$6;
        if (_i < _len$6) {
          const cell = _header[_i];
          _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(header_cells, _M0FP36mizchi8markdown3api21table__cell__to__json(cell));
          _tmp$6 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$19 = "tableRow";
      const _bind$13 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$19) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(header_cells) }];
      const _p$20 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$13, start: 0, end: 2 });
      _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(table_rows, new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$20));
      const _len$7 = _rows.length;
      let _tmp$7 = 0;
      while (true) {
        const _i = _tmp$7;
        if (_i < _len$7) {
          const row = _rows[_i];
          const cells = [];
          const _len$8 = row.length;
          let _tmp$8 = 0;
          while (true) {
            const _i$2 = _tmp$8;
            if (_i$2 < _len$8) {
              const cell = row[_i$2];
              _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(cells, _M0FP36mizchi8markdown3api21table__cell__to__json(cell));
              _tmp$8 = _i$2 + 1 | 0;
              continue;
            } else {
              break;
            }
          }
          const _p$21 = "tableRow";
          const _bind$14 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$21) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(cells) }];
          const _p$22 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$14, start: 0, end: 2 });
          _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(table_rows, new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$22));
          _tmp$7 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const align_array = [];
      const _len$8 = _alignments.length;
      let _tmp$8 = 0;
      while (true) {
        const _i = _tmp$8;
        if (_i < _len$8) {
          const align = _alignments[_i];
          _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(align_array, _M0FP36mizchi8markdown3api22table__align__to__json(align));
          _tmp$8 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$21 = "table";
      const _bind$14 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$21) }, { _0: "align", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(align_array) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(table_rows) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$10) }];
      const _p$22 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$14, start: 0, end: 4 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$22);
    }
    case 10: {
      return undefined;
    }
    default: {
      const _FootnoteDefinition = block;
      const _label = _FootnoteDefinition._0;
      const _children$4 = _FootnoteDefinition._1;
      const _span$11 = _FootnoteDefinition._2;
      const blocks$2 = [];
      const _len$9 = _children$4.length;
      let _tmp$9 = 0;
      while (true) {
        const _i = _tmp$9;
        if (_i < _len$9) {
          const child = _children$4[_i];
          const _bind$15 = _M0FP36mizchi8markdown3api15block__to__json(child);
          if (_bind$15 === undefined) {
          } else {
            const _Some = _bind$15;
            const _json = _Some;
            _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(blocks$2, _json);
          }
          _tmp$9 = _i + 1 | 0;
          continue;
        } else {
          break;
        }
      }
      const _p$23 = "footnoteDefinition";
      const _bind$15 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p$23) }, { _0: "identifier", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label) }, { _0: "label", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_label) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(blocks$2) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(_span$11) }];
      const _p$24 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$15, start: 0, end: 5 });
      return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$24);
    }
  }
}
function _M0FP36mizchi8markdown3api20list__item__to__json(item, tight) {
  const blocks = [];
  const _arr = item.children;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const child = _arr[_i];
      const _bind$3 = _M0FP36mizchi8markdown3api15block__to__json(child);
      if (_bind$3 === undefined) {
      } else {
        const _Some = _bind$3;
        const _json = _Some;
        _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(blocks, _json);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _bind$3 = item.checked;
  let checked;
  if (_bind$3 === -1) {
    checked = $64$moonbitlang$47$core$47$builtin$46$Json$Null;
  } else {
    const _Some = _bind$3;
    const _v = _Some;
    checked = _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(_v);
  }
  const _p = "listItem";
  const _bind$4 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p) }, { _0: "spread", _1: _M0IP311moonbitlang4core4bool4BoolP311moonbitlang4core7builtin6ToJson8to__json(!tight) }, { _0: "checked", _1: checked }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(blocks) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(item.span) }];
  const _p$2 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$4, start: 0, end: 5 });
  return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$2);
}
function _M0FP36mizchi8markdown3api25document__to__json__value(doc) {
  const children = [];
  const _arr = doc.children;
  const _len = _arr.length;
  let _tmp = 0;
  while (true) {
    const _i = _tmp;
    if (_i < _len) {
      const block = _arr[_i];
      const _bind$3 = _M0FP36mizchi8markdown3api15block__to__json(block);
      if (_bind$3 === undefined) {
      } else {
        const _Some = _bind$3;
        const _json = _Some;
        _M0MP311moonbitlang4core5array5Array4pushGRP311moonbitlang4core7builtin4JsonE(children, _json);
      }
      _tmp = _i + 1 | 0;
      continue;
    } else {
      break;
    }
  }
  const _p = "root";
  const _bind$3 = [{ _0: "type", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$String(_p) }, { _0: "children", _1: new $64$moonbitlang$47$core$47$builtin$46$Json$Array(children) }, { _0: "position", _1: _M0FP36mizchi8markdown3api18position__to__json(doc.span) }];
  const _p$2 = _M0MP311moonbitlang4core7builtin3Map11from__arrayGsRP311moonbitlang4core7builtin4JsonE({ buf: _bind$3, start: 0, end: 3 });
  return new $64$moonbitlang$47$core$47$builtin$46$Json$Object(_p$2);
}
function _M0FP36mizchi8markdown3api18document__to__json(doc) {
  const json = _M0FP36mizchi8markdown3api25document__to__json__value(doc);
  return _M0MP311moonbitlang4core4json4Json17stringify_2einner(json, false, 0, undefined);
}
function _M0FP36mizchi8markdown3api18md__parse__to__ast(source) {
  const result = _M0FP26mizchi8markdown13parse_2einner(source, false);
  const handle = _M0FP36mizchi8markdown3api17ast__next__handle.val;
  _M0FP36mizchi8markdown3api17ast__next__handle.val = handle + 1 | 0;
  _M0MP311moonbitlang4core7builtin3Map3setGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle, result.document);
  return handle;
}
function _M0FP36mizchi8markdown3api12md__get__ast(handle) {
  const _bind$3 = _M0MP311moonbitlang4core7builtin3Map3getGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle);
  if (_bind$3 === undefined) {
    return "";
  } else {
    const _Some = _bind$3;
    const _doc = _Some;
    return _M0FP36mizchi8markdown3api18document__to__json(_doc);
  }
}
function _M0FP36mizchi8markdown3api13md__free__ast(handle) {
  _M0MP311moonbitlang4core7builtin3Map6removeGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle);
}
function _M0FP36mizchi8markdown3api12md__to__html(source) {
  return _M0FP26mizchi8markdown12md__to__html(source);
}
function _M0FP36mizchi8markdown3api16md__to__markdown(source) {
  const result = _M0FP26mizchi8markdown13parse_2einner(source, false);
  return _M0FP26mizchi8markdown9serialize(result.document);
}
function _M0FP36mizchi8markdown3api17md__to__ast__json(source) {
  const result = _M0FP26mizchi8markdown13parse_2einner(source, false);
  return _M0FP36mizchi8markdown3api18document__to__json(result.document);
}
function _M0FP36mizchi8markdown3api16md__render__html(handle) {
  const _bind$3 = _M0MP311moonbitlang4core7builtin3Map3getGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle);
  if (_bind$3 === undefined) {
    return "";
  } else {
    const _Some = _bind$3;
    const _doc = _Some;
    return _M0FP26mizchi8markdown12render__html(_doc);
  }
}
function _M0FP36mizchi8markdown3api13md__serialize(handle) {
  const _bind$3 = _M0MP311moonbitlang4core7builtin3Map3getGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle);
  if (_bind$3 === undefined) {
    return "";
  } else {
    const _Some = _bind$3;
    const _doc = _Some;
    return _M0FP26mizchi8markdown9serialize(_doc);
  }
}
function _M0FP36mizchi8markdown3api23md__parse__with__source(source) {
  const result = _M0FP26mizchi8markdown13parse_2einner(source, false);
  const handle = _M0FP36mizchi8markdown3api17ast__next__handle.val;
  _M0FP36mizchi8markdown3api17ast__next__handle.val = handle + 1 | 0;
  _M0MP311moonbitlang4core7builtin3Map3setGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle, result.document);
  _M0MP311moonbitlang4core7builtin3Map3setGisE(_M0FP36mizchi8markdown3api12ast__sources, handle, source);
  return handle;
}
function _M0FP36mizchi8markdown3api22md__parse__incremental(handle, new_source, change_start, old_end, new_end) {
  const _bind$3 = _M0MP311moonbitlang4core7builtin3Map3getGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle);
  const _bind$4 = _M0MP311moonbitlang4core7builtin3Map3getGisE(_M0FP36mizchi8markdown3api12ast__sources, handle);
  if (_bind$3 === undefined) {
    return 0;
  } else {
    const _Some = _bind$3;
    const _doc = _Some;
    if (_bind$4 === undefined) {
      return 0;
    } else {
      const _Some$2 = _bind$4;
      const _old_source = _Some$2;
      const edit = _M0MP26mizchi8markdown8EditInfo7replace(change_start, old_end - change_start | 0, new_end - change_start | 0);
      const inc_result = _M0FP26mizchi8markdown18parse__incremental(_doc, _old_source, new_source, edit);
      const new_handle = _M0FP36mizchi8markdown3api17ast__next__handle.val;
      _M0FP36mizchi8markdown3api17ast__next__handle.val = new_handle + 1 | 0;
      _M0MP311moonbitlang4core7builtin3Map3setGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, new_handle, inc_result.document);
      _M0MP311moonbitlang4core7builtin3Map3setGisE(_M0FP36mizchi8markdown3api12ast__sources, new_handle, new_source);
      return new_handle;
    }
  }
}
function _M0FP36mizchi8markdown3api8md__free(handle) {
  _M0MP311moonbitlang4core7builtin3Map6removeGiRP26mizchi8markdown8DocumentE(_M0FP36mizchi8markdown3api14ast__documents, handle);
  _M0MP311moonbitlang4core7builtin3Map6removeGisE(_M0FP36mizchi8markdown3api12ast__sources, handle);
}
export { _M0FP36mizchi8markdown3api18md__parse__to__ast as md_parse_to_ast, _M0FP36mizchi8markdown3api12md__get__ast as md_get_ast, _M0FP36mizchi8markdown3api13md__free__ast as md_free_ast, _M0FP36mizchi8markdown3api12md__to__html as md_to_html, _M0FP36mizchi8markdown3api16md__to__markdown as md_to_markdown, _M0FP36mizchi8markdown3api17md__to__ast__json as md_to_ast_json, _M0FP36mizchi8markdown3api16md__render__html as md_render_html, _M0FP36mizchi8markdown3api13md__serialize as md_serialize, _M0FP36mizchi8markdown3api23md__parse__with__source as md_parse_with_source, _M0FP36mizchi8markdown3api22md__parse__incremental as md_parse_incremental, _M0FP36mizchi8markdown3api8md__free as md_free }
