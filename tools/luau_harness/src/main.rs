//! Offline Luau checks (no Roblox Studio needed).
//!   luau_harness --check <files...>      compile every file with the real Luau compiler (syntax errors)
//!   luau_harness <script.lua> <repo>     run a Lua script that drives the real server modules against tools/luau_harness/mock.lua
use mlua::prelude::*;

fn main() -> LuaResult<()> {
    let lua = Lua::new();
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("usage: luau_harness --check <files...> | luau_harness <script.lua> <repo>");
        std::process::exit(2);
    }
    if args[1] == "--check" {
        let mut bad = 0;
        for f in &args[2..] {
            let src = std::fs::read_to_string(f).unwrap().replace("\r\n", "\n");
            match lua.load(&src).set_name(f.as_str()).into_function() {
                Ok(_) => println!("OK   {}", f),
                Err(e) => {
                    bad += 1;
                    println!("FAIL {}: {}", f, e);
                }
            }
        }
        if bad > 0 {
            std::process::exit(1);
        }
        return Ok(());
    }
    // __loadfile(path, env) -> function (CRLF-normalised, compiled with the given environment table)
    let lf = lua.create_function(|lua, (path, env): (String, LuaTable)| {
        let src = std::fs::read_to_string(&path).map_err(|e| LuaError::external(format!("{}: {}", path, e)))?.replace("\r\n", "\n");
        let f = lua.load(&src).set_name(format!("@{}", path)).set_environment(env).into_function()?;
        Ok(f)
    })?;
    lua.globals().set("__loadfile", lf)?;
    let ex = lua.create_function(|_, path: String| Ok(std::path::Path::new(&path).is_file()))?;
    lua.globals().set("__exists", ex)?;
    lua.globals().set("ARGS", args[2..].to_vec())?;
    let src = std::fs::read_to_string(&args[1]).unwrap();
    match lua.load(&src).set_name(format!("@{}", args[1])).exec() {
        Ok(_) => Ok(()),
        Err(e) => {
            eprintln!("HARNESS ERROR: {}", e);
            std::process::exit(1);
        }
    }
}
