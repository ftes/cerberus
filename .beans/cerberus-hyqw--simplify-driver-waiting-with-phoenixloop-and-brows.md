---
# cerberus-hyqw
title: Simplify driver waiting with PhoenixLoop and BrowserLoop
status: in-progress
type: task
priority: normal
created_at: 2026-03-07T07:29:50Z
updated_at: 2026-03-07T08:16:33Z
---

-

# Simplify Driver Waiting Around PhoenixLoop, BrowserLoop, and Driver-Native Waiting

## Bean Metadata

- Title: Simplify driver waiting with PhoenixLoop and BrowserLoop
- Type: task
- Status: in-progress

## Todo

- [x] Add PhoenixLoop and BrowserLoop outside driver/
- [ ] Remove LiveViewTimeout and LiveViewWatcher
- [x] Extend LiveViewClient and proxy with progress and navigation primitives
- [x] Make Static one-shot and remove timeout loop call sites
- [ ] Keep driver-native waiting first in Live and Browser for actions and assertions
- [ ] Split Live into helper modules
- [ ] Split Browser into helper modules
- [ ] Update tests and docs

## Summary

Refactor Cerberus so waiting and retries have one clear ownership model:

Cerberus.Driver.Static, Cerberus.Driver.Live, and Cerberus.Driver.Browser stay as the internal driver/state modules.
Cerberus.PhoenixLoop governs overall timeout and cross-state retries for Phoenix mode.
Cerberus.BrowserLoop governs overall timeout and cross-attempt recovery for browser mode.
Drivers remain the primary owners of efficient native waiting for both actions and assertions.
Static stays one-shot.
LiveViewTimeout and LiveViewWatcher are removed.
Static/live transitions are handled as one Phoenix-mode session concern, not as separate outer loops.

This keeps the efficient native wait strategies that exist in Live and browser, while removing the accidental complexity of nested retry owners and a shared semantic timeout engine.

## Core Design

### Keep existing driver module names

Do not rename:

Cerberus.Driver.Static
Cerberus.Driver.Live
Cerberus.Driver.Browser

These names are acceptable.

### Remove Session aliases

Do not use aliases like:

StaticSession
LiveSession
BrowserSession

Use direct aliases and structs:

alias Cerberus.Driver.Static
alias Cerberus.Driver.Live
alias Cerberus.Driver.Browser

Pattern match with:

%Static{}
%Live{}
%Browser{}

Update implementation, tests, helper code, and specs accordingly.

### Add loop modules outside driver/

Add:

/Users/ftes/src/cerberus/lib/cerberus/phoenix_loop.ex
/Users/ftes/src/cerberus/lib/cerberus/browser_loop.ex

Optional:

/Users/ftes/src/cerberus/lib/cerberus/deadline.ex

The optional Deadline helper may only handle:

deadline creation
remaining time
timeout exhaustion checks

It must not encode driver semantics.

## Ownership Model

### Drivers own native waiting first

This applies to both actions and assertions.

#### Live

Live should remain the primary owner of:

waiting for render/progress after actions
waiting for render/progress during assertions
resolving patch/redirect outcomes from native LiveView signals

#### Browser

Browser should remain the primary owner of:

in-browser actionability/mutation waiting
native browser assertion waiting
readiness within a driver attempt
browser-specific recovery signals

#### Static

Static remains one-shot and has no waiting loop.

### Loops own global deadline and cross-attempt control

#### PhoenixLoop

Owns:

overall timeout budget for Phoenix-mode eventual operations
retry/re-entry across %Static{} and %Live{}
cross-state transitions:
%Static{} -> %Live{}
%Live{} -> %Static{}
final timeout diagnostics

It does not replace native waiting inside Live.

#### BrowserLoop

Owns:

overall timeout budget for browser eventual operations
re-entry after browser-level interruption or recoverable cross-attempt failure
final timeout diagnostics

It does not replace native waiting inside Browser.

## Operation Ownership

### Actions

Actions remain driver-native first.

This includes:

click
fill_in
select
choose
check
uncheck
submit
upload

#### Phoenix actions

Live handles:

waiting for actionable targets via LiveView progress
applying patch/redirect results
updating %Live{} or returning %Static{} when redirect crosses mode

Static remains one-shot.

PhoenixLoop should not become the primary action wait engine.

#### Browser actions

Browser handles:

in-browser actionability wait
in-attempt mutation/settle wait
single-attempt readiness where appropriate

BrowserLoop only re-enters when the browser attempt was interrupted or needs higher-level recovery.

### Assertions

Assertions are also driver-native first.

This is the critical correction.

#### Phoenix assertions

Live should perform native assertion waiting using LiveView progress/version signals.
Static remains one-shot.

PhoenixLoop should only re-enter when:

the state changes between static/live
the driver explicitly reports a higher-level retry boundary
a redirect or equivalent session-shape change occurred
the attempt ended without success and there is still an outer retry boundary to honor

#### Browser assertions

Browser should keep efficient native assertion waiting first.
BrowserLoop should re-enter only on browser-level interruption/recovery boundaries, not to replace efficient in-driver wait-for-mutation logic.

## Phoenix Session Model

### Phoenix mode is one conceptual session

Phoenix mode may move between:

%Static{}
%Live{}

So retry/deadline control cannot live purely in Static or purely in Live.

### Important transition rules

Real state changes:

%Static{} -> %Live{}
%Live{} -> %Static{}

Not a state change:

live patch within the same LiveView remains %Live{}

For live patch, the system only needs to treat it as progress/navigation within %Live{}, not a driver/mode switch.

## PhoenixLoop Design

### Responsibilities

PhoenixLoop should govern eventual Phoenix-mode operations:

assert_has
refute_has
assert_value
refute_value
assert_path
refute_path
assert_download when waiting for a live redirect to static
any future explicit Phoenix wait operations

### Loop contract

Each iteration:

Compute remaining_ms
Dispatch to current state module:
%Static{}
%Live{}
Driver performs native waiting bounded by remaining_ms
Driver returns one of:
success
terminal failure
retryable outer-loop failure
transitioned state
If transitioned, continue loop with new state
If timeout expires, collect final diagnostics and fail

### No static loop

Static should never poll or wait.

Static just:

inspects the fixed document
inspects current_path
returns immediately

The only timeout-related static behavior retained is the internal traversal deadline guard in /Users/ftes/src/cerberus/lib/cerberus/html/html.ex.

## LiveViewClient Refactor

### New helpers

Extend /Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_client.ex with:

view_alive?(view) :: boolean()
render_version(view) :: non_neg_integer()
await_progress(view, version, timeout_ms) :: {:ok, progress_kind} | :timeout
receive_navigation(view, timeout_ms \\ 0) :: {:redirect, opts} | {:live_redirect, opts} | {:patch, opts} | nil

progress_kind can stay simple:

diff
patch
redirect
live_redirect
terminated

### Required client proxy changes

Modify the inlined LiveView client/proxy to maintain a monotonically increasing version.

Increment version on:

diff merge
live patch
redirect
live redirect
child add/remove that changes rendered state
any proxy update that changes html / render

Expose:

current version
waiter registration for version changed after baseline without lost wakeups

### Remove tracing and watcher model

Delete the need for:

LiveViewWatcher
proxy tracing
separate watcher process state

## Live Simplification

### Keep Live as the main entry module

Do not replace Live with a loop module.
Keep Cerberus.Driver.Live as the central driver/state module.

### Extract helper submodules

Create helper modules under /Users/ftes/src/cerberus/lib/cerberus/driver/live/:

actions.ex
assertions.ex
navigation.ex
progress.ex
scope.ex

Responsibilities:

actions.ex: actionability and action execution
assertions.ex: assertion primitives and observed-data building
navigation.ex: redirect, patch, and follow_redirect logic
progress.ex: render-version and await-progress helpers
scope.ex: within and live-child scope handling

Cerberus.Driver.Live becomes a thinner composition module.

### Remove active polling design

Do not retain fixed 25ms active polling as the primary wait mechanism.

Live should wait on progress and version changes through LiveViewClient.

## Browser Model

### Keep browser topology unchanged

Preserve:

UserContextProcess
BrowsingContextProcess
dialog, download, and popup event waiter ownership
readiness execution in browsing-context process

Topology is not the target of this refactor.

## BrowserLoop Design

### Responsibilities

BrowserLoop should govern eventual browser operations:

assert_has
refute_has
assert_value
refute_value
assert_path
refute_path
future explicit browser wait-style ops if needed

### Loop contract

Each iteration:

Compute remaining_ms
Ask Browser to perform an assertion attempt with native waiting bounded by remaining_ms
If success, return
If terminal failure, return
If recoverable cross-attempt interruption or recovery boundary exists, re-enter
If timeout expires, collect diagnostics and fail

### Keep browser-native waiting first

Do not force assertions into pure one-shot outer polling.
Do not force actions into pure one-shot outer polling.

Instead:

Browser keeps native efficient waiting first
BrowserLoop governs only higher-level retries and timeout policy

### Browser driver simplification

Refactor /Users/ftes/src/cerberus/lib/cerberus/driver/browser.ex into clearer helpers under /Users/ftes/src/cerberus/lib/cerberus/driver/browser/:

actions.ex
assertions.ex
navigation.ex
readiness.ex
scope.ex

Responsibilities:

actions.ex: action attempts and result normalization
assertions.ex: assertion, value, and path attempt primitives
navigation.ex: visit, current-path, and navigation result handling
readiness.ex: readiness attempt and readiness diagnostics
scope.ex: within and scope helpers

Keep Extensions, but make it call into these driver primitives instead of owning unrelated retry behavior.

### Browser JS helper simplification

Refine browser JS helpers so they do not duplicate outer retry ownership.

They may still:

wait within one native attempt for actionability and mutation-based settle
report retryable and interrupted outcomes
report readiness-needed flags
return structured candidate and debug data

They should not implement independent outer retry policy that conflicts with BrowserLoop.

## Delete Old Shared Timeout Machinery

Delete:

/Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_timeout.ex
/Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_watcher.ex

Replace all call sites with:

native driver waiting
PhoenixLoop
BrowserLoop

## Cerberus.Assertions Refactor

Update /Users/ftes/src/cerberus/lib/cerberus/assertions.ex so it:

normalizes inputs
validates opts
computes timeout once
dispatches by current state:
%Static{} and %Live{} -> PhoenixLoop
%Browser{} -> BrowserLoop

It must no longer:

call LiveViewTimeout
branch inline between browser and non-browser timeout engines
own retry policy itself

## Driver Timeout Contract

### Outer loop owns policy

The loops own:

total timeout budget
remaining time passed to drivers
timeout exhaustion
final timeout diagnostics

### Drivers are still mechanically timeout-aware

Drivers should accept remaining_ms for each native attempt and wait.

They should not invent independent timeout policy or separate retry budgets.

This applies to:

browser readiness and evaluate waits
live progress waits
any driver-native assertion or action waits

## Final Diagnostics on Timeout

### Principle

When timeout expires:

loop requests one bounded final diagnostic snapshot from the driver
enriched failure is returned
do not kill first and inspect later

### Phoenix diagnostics

Include when relevant:

current path
current rendered document or candidate values
latest navigation signal if any
current scope
possible candidates

### Browser diagnostics

Include when relevant:

current path
last readiness payload
candidate values
scope
recent relevant event or debug state
possible candidates

## Files to Add

/Users/ftes/src/cerberus/lib/cerberus/phoenix_loop.ex
/Users/ftes/src/cerberus/lib/cerberus/browser_loop.ex
optionally /Users/ftes/src/cerberus/lib/cerberus/deadline.ex

New helper modules:

/Users/ftes/src/cerberus/lib/cerberus/driver/live/actions.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/live/assertions.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/live/navigation.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/live/progress.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/live/scope.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/browser/actions.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/browser/assertions.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/browser/navigation.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/browser/readiness.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/browser/scope.ex

## Files to Delete

/Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_timeout.ex
/Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_watcher.ex

## Files to Update Heavily

/Users/ftes/src/cerberus/lib/cerberus/assertions.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/live.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/browser.ex
/Users/ftes/src/cerberus/lib/cerberus/driver/static.ex
/Users/ftes/src/cerberus/lib/cerberus/phoenix/live_view_client.ex
/Users/ftes/src/cerberus/lib/cerberus/session/impl.ex
/Users/ftes/src/cerberus/lib/cerberus/driver.ex
/Users/ftes/src/cerberus/lib/cerberus/html/html.ex

## Implementation Sequence

### Slice 1: Alias and style cleanup

remove Session aliases
switch code and tests to %Static{}, %Live{}, %Browser{}

### Slice 2: Add PhoenixLoop

move Phoenix assertion, path, and download timeout orchestration there
keep Static one-shot
stop calling LiveViewTimeout

### Slice 3: Extend LiveViewClient

add version, progress, and navigation helpers
add proxy version tracking
enable native event-driven live waiting

### Slice 4: Simplify Live

extract helper submodules
move action, assertion, navigation, and progress responsibilities out of the monolith
remove watcher-based and active-polling assumptions

### Slice 5: Delete LiveViewTimeout and LiveViewWatcher

remove modules
replace tests with PhoenixLoop and LiveViewClient behavior coverage

### Slice 6: Add BrowserLoop

move browser eventual assertion and path timeout orchestration there
keep action and assertion waiting native-first in Browser

### Slice 7: Simplify Browser

extract helper submodules
reduce monolithic orchestration in browser.ex
align JS helper behavior with loop and native ownership split

### Slice 8: Docs and cleanup

update architecture, docs, and comments
remove obsolete timeout-engine references

## Tests and Scenarios

### Phoenix tests

static assertions remain one-shot
static path assertions remain one-shot
live assertions wait on progress and version changes without active polling
%Static{} -> %Live{} transition works under PhoenixLoop
%Live{} -> %Static{} redirect works under PhoenixLoop
live patch stays within %Live{}
live process death follows queued redirect when available
live process death without redirect fails deterministically
live assert_download waits correctly for redirect to static

### Live driver tests

actions wait natively on progress, not outer polling
redirect and patch results are resolved in-driver
candidate and debug data remains available on failure

### Browser tests

browser assertions and path waits are governed by BrowserLoop
browser assertions still use native waiting first
browser actions still use native waiting first
interrupted navigation and context recovery remains deterministic
dialog, download, and popup tests remain green with current topology

### Timeout diagnostic tests

on timeout, loops request final bounded diagnostics
failure messages still include candidate and debug information

### Removed and replaced tests

direct LiveViewTimeout tests removed
direct LiveViewWatcher tests removed
tests updated to target loop behavior and driver-native waiting instead

## Documentation Updates

Update:

/Users/ftes/src/cerberus/docs/architecture.md
any docs and ADRs describing shared timeout and event-loop behavior
comments and moduledocs referring to watcher-based retry logic
comments and docs using old Session alias language

## Acceptance Criteria

Cerberus.Driver.Static, Live, and Browser remain the internal driver module names
Session aliases are no longer used
PhoenixLoop and BrowserLoop exist outside driver/
LiveViewTimeout and LiveViewWatcher are removed
static remains one-shot
live uses event-driven native waiting
browser uses native waiting first
loops own total timeout policy and cross-attempt and cross-state coordination
public API behavior remains stable

## Assumptions and Defaults

Public session remains the user-facing abstraction
Driver modules keep their current names
Assertions and actions should both remain driver-native first
Outer loops govern timeouts, transitions, and final timeout handling
Static has no loop
Live patch is progress within %Live{}, not a mode or state switch
Browser topology is unchanged
Simplicity and stability are prioritized over speed
