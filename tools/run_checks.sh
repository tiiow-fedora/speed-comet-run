#!/usr/bin/env bash
# Offline checks for the Luau source (no Roblox Studio needed). Needs rojo, selene, stylua on PATH and a Rust toolchain.
#   cargo install rojo selene --locked; cargo install stylua --locked --features luau
# Studio is still required for DevTest, UI layout and anything visual (see TESTING.md).
set -u
cd "$(dirname "$0")/.."
export PATH="$PATH:$HOME/.cargo/bin"
fail=0
step() { printf '\n== %s\n' "$1"; }
step "rojo build"; rojo build -o /tmp/comet_check.rbxl || fail=1
step "selene"; selene src || fail=1
step "stylua --check"; stylua --check src || fail=1
H=tools/luau_harness
if [ ! -x $H/target/release/luau_harness ]; then step "building harness (first run, ~1 min)"; (cd $H && cargo build --release) || fail=1; fi
step "luau compile check"; $H/target/release/luau_harness --check src/*/*.luau | grep -v '^OK' ; [ "${PIPESTATUS[0]}" = 0 ] || fail=1
step "server logic harness"; $H/target/release/luau_harness $H/test.lua "$PWD" | grep -v '^PASS' ; [ "${PIPESTATUS[0]}" = 0 ] || fail=1
step "client smoke harness"; $H/target/release/luau_harness $H/client_smoke.lua "$PWD" | grep -v '^PASS' ; [ "${PIPESTATUS[0]}" = 0 ] || fail=1
step "real DevTest inside the mock"; $H/target/release/luau_harness $H/devtest.lua "$PWD" | grep -v '^PASS' ; [ "${PIPESTATUS[0]}" = 0 ] || fail=1
echo; [ $fail = 0 ] && echo "ALL CHECKS PASSED" || echo "SOME CHECKS FAILED"
exit $fail
