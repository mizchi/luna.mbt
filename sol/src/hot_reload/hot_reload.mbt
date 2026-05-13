///|
/// Default application port when PORT is missing or invalid
pub let default_app_port : Int = 7777

///|
/// Default HMR port offset from application port
pub let default_hmr_offset : Int = 100

///|
/// Resolve default HMR port from application port
pub fn default_hmr_port(
  app_port : Int,
  offset? : Int = default_hmr_offset,
) -> Int {
  app_port + offset
}

///|
/// Resolve application port from raw env-like value
pub fn resolve_app_port(
  app_port~ : String?,
  default_port? : Int = default_app_port,
) -> Int {
  parse_port_or(app_port, default_port)
}

///|
/// Resolve HMR port from raw env-like values
/// Priority: hmr_port -> app_port + offset -> default_app_port + offset
pub fn resolve_hmr_port(
  hmr_port~ : String?,
  app_port~ : String?,
  default_port? : Int = default_app_port,
  offset? : Int = default_hmr_offset,
) -> Int {
  match hmr_port {
    Some(raw_hmr) =>
      @strconv.parse_int(raw_hmr) catch {
        _ => {
          let app = resolve_app_port(app_port~, default_port~)
          default_hmr_port(app, offset~)
        }
      }
    None => {
      let app = resolve_app_port(app_port~, default_port~)
      default_hmr_port(app, offset~)
    }
  }
}

///|
/// Build HMR client script with custom JavaScript host expression
/// Example host_expr: "location.hostname", "'localhost'"
pub fn client_script_with_host_expr(port : Int, host_expr : String) -> String {
  let port_str = port.to_string()
  let script =
    #|(function(){
    #|  var ws=new WebSocket('ws://'+(__HOST__)+':__PORT__');
    #|  ws.onmessage=function(e){
    #|    var m=JSON.parse(e.data);
    #|    if(m.type==='full-reload'||m.type==='reload'){
    #|      location.reload();
    #|    }else if(m.type==='update'){
    #|      var islands=m.islands||[];
    #|      if(islands.length===1&&islands[0]==='*'){
    #|        location.reload();
    #|      }else if(typeof window.__LUNA_HYDRATE__==='function'){
    #|        islands.forEach(function(name){
    #|          var el=document.querySelector('[luna\\:url$="/'+name+'.js"]');
    #|          if(el){
    #|            console.log('[HMR] Re-hydrating island:',name);
    #|            window.__LUNA_HYDRATE__(el);
    #|          }else{
    #|            location.reload();
    #|          }
    #|        });
    #|      }else{
    #|        location.reload();
    #|      }
    #|    }else if(m.type==='error'){
    #|      console.error('[HMR]',m.error||m.message);
    #|    }
    #|  };
    #|  ws.onclose=function(){setTimeout(function(){location.reload()},1000)};
    #|})()
  "<script>" +
  script.replace(old="__HOST__", new=host_expr).replace(
    old="__PORT__",
    new=port_str,
  ) +
  "</script>"
}

///|
/// Build HMR client script for browser hostname (recommended for app runtime)
pub fn client_script_hostname(port : Int) -> String {
  client_script_with_host_expr(port, "location.hostname")
}

///|
/// Build HMR client script for localhost (useful for local static serving)
pub fn client_script_localhost(port : Int) -> String {
  client_script_with_host_expr(port, "'localhost'")
}

///|
/// Read environment variable (Node.js)
extern "js" fn env_var(name : String) -> String? =
  #| (name) => {
  #|   const processObj = globalThis.process;
  #|   const value = processObj?.env?.[name];
  #|   return typeof value === 'string' ? value : undefined;
  #| }

///|
/// Check dev mode using environment variables
pub fn is_dev_mode(
  flag_env? : String = "SOL_DEV",
  expected? : String = "1",
) -> Bool {
  match env_var(flag_env) {
    Some(v) => v == expected
    None => false
  }
}

///|
/// Resolve application port from environment variables
pub fn app_port_from_env(
  app_port_env? : String = "PORT",
  default_port? : Int = default_app_port,
) -> Int {
  resolve_app_port(app_port=env_var(app_port_env), default_port~)
}

///|
/// Resolve HMR port from environment variables
pub fn hmr_port_from_env(
  hmr_port_env? : String = "HMR_PORT",
  app_port_env? : String = "PORT",
  default_port? : Int = default_app_port,
  offset? : Int = default_hmr_offset,
) -> Int {
  resolve_hmr_port(
    hmr_port=env_var(hmr_port_env),
    app_port=env_var(app_port_env),
    default_port~,
    offset~,
  )
}

///|
/// Build HMR client script from environment variables
pub fn client_script_from_env(
  hmr_port_env? : String = "HMR_PORT",
  app_port_env? : String = "PORT",
  default_port? : Int = default_app_port,
  offset? : Int = default_hmr_offset,
) -> String {
  let port = hmr_port_from_env(
    hmr_port_env~,
    app_port_env~,
    default_port~,
    offset~,
  )
  client_script_hostname(port)
}

///|
/// Append HMR client script to head only in dev mode
pub fn with_dev_head_script(
  head : String,
  dev_mode? : Bool = is_dev_mode(),
) -> String {
  if dev_mode {
    head + client_script_from_env()
  } else {
    head
  }
}

///|
/// Inject script tag into HTML before </body> (fallback: append to end)
pub fn inject_script(html : String, script : String) -> String {
  if html.contains("</body>") {
    html.replace(old="</body>", new=script + "</body>")
  } else {
    html + script
  }
}

///|
fn parse_port_or(raw : String?, fallback : Int) -> Int {
  match raw {
    Some(v) => @strconv.parse_int(v) catch { _ => fallback }
    None => fallback
  }
}
