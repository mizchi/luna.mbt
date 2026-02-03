/// CSS Static Analyzer - AST Visitor
///
/// Traverses MoonBit AST to find class_= arguments and extract CSS classes.

///|
/// Context for tracking variable bindings
priv struct AnalyzerContext {
  /// Map from variable name to its css() result (if known)
  bindings : Map[String, Array[String]]
  /// Current file being analyzed
  file : String
  /// Collected co-occurrences
  cooccurrences : Array[ClassCooccurrence]
  /// Collected warnings
  warnings : Array[AnalyzerWarning]
}

///|
fn AnalyzerContext::new(file : String) -> AnalyzerContext {
  { bindings: {}, file, cooccurrences: [], warnings: [] }
}

///|
/// Get name from LongIdent
fn get_ident_name(id : @syntax.LongIdent) -> String {
  match id {
    Ident(name~) => name
    Dot(id~, ..) => id
  }
}

///|
/// Check if an expression is a css() call and extract the declaration
fn extract_css_call(expr : @syntax.Expr) -> String? {
  match expr {
    Apply(func~, args~, ..) =>
      match func {
        Ident(id~, ..) =>
          if get_ident_name(id.name) == "css" && args.length() >= 2 {
            let first_arg = args.head()
            let second_arg = args.unsafe_tail().head()
            match (first_arg, second_arg) {
              (Some(a1), Some(a2)) => {
                let prop = extract_string_literal(a1.value)
                let value = extract_string_literal(a2.value)
                match (prop, value) {
                  (Some(p), Some(v)) => Some(p + ":" + v)
                  _ => None
                }
              }
              _ => None
            }
          } else {
            None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// Extract string literal from expression
fn extract_string_literal(expr : @syntax.Expr) -> String? {
  match expr {
    Constant(c~, ..) =>
      match c {
        String(s) => Some(s)
        _ => None
      }
    _ => None
  }
}

///|
/// Check if an expression is a styles() call and extract declarations
fn extract_styles_call(expr : @syntax.Expr) -> Array[String]? {
  match expr {
    Apply(func~, args~, ..) =>
      match func {
        Ident(id~, ..) =>
          if get_ident_name(id.name) == "styles" && args.length() >= 1 {
            match args.head() {
              Some(arg) => extract_styles_array(arg.value)
              None => None
            }
          } else {
            None
          }
        _ => None
      }
    _ => None
  }
}

///|
/// Extract declarations from styles([(...), ...]) array
fn extract_styles_array(expr : @syntax.Expr) -> Array[String]? {
  match expr {
    Array(exprs~, ..) => {
      let declarations : Array[String] = []
      for e in exprs {
        match extract_tuple_pair(e) {
          Some((prop, value)) => declarations.push(prop + ":" + value)
          None => return None
        }
      }
      Some(declarations)
    }
    _ => None
  }
}

///|
/// Extract (prop, value) from a tuple expression
fn extract_tuple_pair(expr : @syntax.Expr) -> (String, String)? {
  match expr {
    Tuple(exprs~, ..) =>
      if exprs.length() == 2 {
        let first = exprs.head().bind(extract_string_literal)
        let second = exprs.unsafe_tail().head().bind(extract_string_literal)
        match (first, second) {
          (Some(p), Some(v)) => Some((p, v))
          _ => None
        }
      } else {
        None
      }
    _ => None
  }
}

///|
/// Get location line number from AST
fn get_line(loc : @basic.Location) -> Int {
  loc.start.lnum
}

///|
/// Analyze a class_= argument array
fn analyze_class_array(
  ctx : AnalyzerContext,
  exprs : @list.List[@syntax.Expr],
  loc : @basic.Location,
) -> Unit {
  let classes : Array[String] = []
  let mut is_static = true
  for expr in exprs {
    match extract_css_call(expr) {
      Some(decl) => classes.push(decl)
      None =>
        match extract_styles_call(expr) {
          Some(decls) =>
            for d in decls {
              classes.push(d)
            }
          None =>
            match expr {
              Ident(id~, ..) =>
                match ctx.bindings.get(get_ident_name(id.name)) {
                  Some(decls) =>
                    for d in decls {
                      classes.push(d)
                    }
                  None => {
                    is_static = false
                    ctx.warnings.push({
                      kind: UntraceableVariable,
                      file: ctx.file,
                      line: get_line(loc),
                      message: "Cannot trace variable: " +
                      get_ident_name(id.name),
                    })
                  }
                }
              If(..) | Match(..) => {
                is_static = false
                ctx.warnings.push({
                  kind: DynamicConditional,
                  file: ctx.file,
                  line: get_line(loc),
                  message: "Conditional expression in class array",
                })
              }
              Apply(..) =>
                match extract_css_call(expr) {
                  Some(_) => ()
                  None =>
                    match extract_styles_call(expr) {
                      Some(_) => ()
                      None => {
                        is_static = false
                        ctx.warnings.push({
                          kind: DynamicFunctionCall,
                          file: ctx.file,
                          line: get_line(loc),
                          message: "Function call result in class array",
                        })
                      }
                    }
                }
              _ => is_static = false
            }
        }
    }
  }
  if classes.length() >= 2 {
    ctx.cooccurrences.push({
      classes,
      file: ctx.file,
      line: get_line(loc),
      is_static,
    })
  }
}

///|
/// Find class_= in function arguments
fn find_class_arg(args : @list.List[@syntax.Argument]) -> @syntax.Expr? {
  for arg in args {
    match arg.kind {
      Labelled(label) | LabelledPun(label) =>
        if label.name == "class_" {
          return Some(arg.value)
        }
      _ => ()
    }
  }
  None
}

///|
/// Visit an expression and collect class co-occurrences
fn visit_expr(ctx : AnalyzerContext, expr : @syntax.Expr) -> Unit {
  match expr {
    Apply(args~, loc~, ..) =>
      match find_class_arg(args) {
        Some(class_expr) =>
          match class_expr {
            Array(exprs~, ..) => analyze_class_array(ctx, exprs, loc)
            ArraySpread(..) =>
              ctx.warnings.push({
                kind: DynamicArrayConstruction,
                file: ctx.file,
                line: get_line(loc),
                message: "Spread operator in class array",
              })
            _ => ()
          }
        None => ()
      }
    Let(pattern~, expr=init, ..) => {
      match pattern {
        Var(binder) =>
          match extract_css_call(init) {
            Some(decl) => ctx.bindings[binder.name] = [decl]
            None =>
              match extract_styles_call(init) {
                Some(decls) => ctx.bindings[binder.name] = decls
                None => ()
              }
          }
        _ => ()
      }
      visit_expr(ctx, init)
    }
    _ => ()
  }
  visit_expr_children(ctx, expr)
}

///|
/// Visit children of an expression
fn visit_expr_children(ctx : AnalyzerContext, expr : @syntax.Expr) -> Unit {
  match expr {
    Apply(func~, args~, ..) => {
      visit_expr(ctx, func)
      for arg in args {
        visit_expr(ctx, arg.value)
      }
    }
    Infix(lhs~, rhs~, ..) => {
      visit_expr(ctx, lhs)
      visit_expr(ctx, rhs)
    }
    Unary(expr~, ..) => visit_expr(ctx, expr)
    Array(exprs~, ..) =>
      for e in exprs {
        visit_expr(ctx, e)
      }
    Sequence(exprs~, last_expr~, ..) => {
      for e in exprs {
        visit_expr(ctx, e)
      }
      visit_expr(ctx, last_expr)
    }
    If(cond~, ifso~, ifnot~, ..) => {
      visit_expr(ctx, cond)
      visit_expr(ctx, ifso)
      match ifnot {
        Some(e) => visit_expr(ctx, e)
        None => ()
      }
    }
    Tuple(exprs~, ..) =>
      for e in exprs {
        visit_expr(ctx, e)
      }
    Let(expr=init, body~, ..) => {
      visit_expr(ctx, init)
      visit_expr(ctx, body)
    }
    Match(expr~, cases~, ..) => {
      visit_expr(ctx, expr)
      for case in cases {
        visit_expr(ctx, case.body)
      }
    }
    Function(func~, ..) => visit_expr(ctx, func.body)
    _ => ()
  }
}

///|
/// Analyze a source file
pub fn analyze_source(source : String, file : String) -> FileAnalysisResult {
  let (impls, _errors) = @parser.parse_string(source, name=file)
  let ctx = AnalyzerContext::new(file)
  for impl_ in impls {
    visit_impl(ctx, impl_)
  }
  { cooccurrences: ctx.cooccurrences, warnings: ctx.warnings }
}

///|
/// Visit a top-level implementation
fn visit_impl(ctx : AnalyzerContext, impl_ : @syntax.Impl) -> Unit {
  match impl_ {
    TopFuncDef(decl_body~, ..) => visit_decl_body(ctx, decl_body)
    TopLetDef(expr~, ..) => visit_expr(ctx, expr)
    _ => ()
  }
}

///|
/// Visit function body
fn visit_decl_body(ctx : AnalyzerContext, body : @syntax.DeclBody) -> Unit {
  match body {
    DeclBody(expr~, ..) => visit_expr(ctx, expr)
    DeclStubs(_) => () // External function stubs
    DeclNone => ()
  }
}
