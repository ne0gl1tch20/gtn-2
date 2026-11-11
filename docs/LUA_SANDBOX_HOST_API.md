# GTN2 Lua Sandbox Host API v1

**Status:** Runtime foundation in review; gameplay entry-point integration remains pending.
**Source:** GTN1 pinned source at `fe9cf567169e19059e0330d08769fe454336ef94`.

## Runtime boundary

Lua is a data/intent selector, not a second game engine. A script may inspect the bounded input snapshot supplied by Dart, return a data table and write bounded diagnostic log lines. Dart validates the result and performs all state changes, reward calculations, purchases, save writes and progression transactions.

Each execution runs in a disposable Dart isolate. A timeout kills the isolate. Scripts do not share Lua globals or state between runs.

## Host API v1

| API | Type | Contract |
|---|---|---|
| `gtn.input` | table of strings | Read-only-by-contract snapshot supplied by the caller; only present fields are visible |
| `gtn.log(message)` | function | Bounded diagnostic output; no filesystem or network sink |
| `print(...)` | function | Alias to bounded diagnostic output |

Capabilities:
- `read_snapshot`: pass the caller-provided input map to `gtn.input`.
- `log`: expose `gtn.log` and `print`.

No other capability is accepted in v1. In particular, scripts cannot request filesystem, network, process, platform-channel, save, economy or arbitrary host-function access.

## Removed Lua globals

The runtime removes `os`, `io`, `package`, `debug`, `dofile`, `loadfile`, `load`, `require`, `collectgarbage`, `getmetatable`, `setmetatable`, `rawset` and `rawget` after opening the standard libraries.

The supported standard library surface is for local computation only. It does not grant access to host resources.

## Current execution limits

| Limit | Value |
|---|---:|
| Source length | 32,768 characters |
| Input fields | 64 |
| Input key length | 48 characters |
| Input value length | 256 characters |
| Execution time | 500 ms by default |
| Log lines | 32 |
| Log line length | 500 characters |
| Returned nodes | 512 |
| Returned table depth | 8 |
| Returned table key length | 128 characters |

Callers may choose a shorter execution budget for a particular script. The default must not be raised to accommodate an inefficient script; optimize the script or split the task instead.

## GTN1 script contracts to wire

| Script | Expected return | Dart-side responsibility |
|---|---|---|
| `events/random_event.lua` | `{ trigger: bool, type: string }` | Validate against the approved event ID set, then calculate and apply event rewards in Dart |
| `events/seasonal_events.lua` | Versioned event manifest | Validate schema, dates, claim caps and eligibility; persist claims and rewards in Dart |
| `minigames/number_rush.lua` | Number Rush presentation model | Validate title, prompt, options and 1-based correct option; Dart owns answer submission and round state |
| `traits/invisible_traits.lua` | Helper and bonus ID arrays | Validate every ID and eligibility against `InvisibleTraitEngine`; Dart owns helper consumption and reward transactions |

A script's return value is never trusted just because it parsed successfully. Unknown keys, IDs, malformed types, invalid array lengths and out-of-range values must be rejected by the calling Dart adapter.

## Integration sequence

1. Add a typed activity payload validator and load the manifest through Flutter assets.
2. Add the Number Rush activity as a real screen with Dart-owned answer validation.
3. Wire the seasonal manifest through the existing event/claim transaction model.
4. Wire random-event selection through an allowlisted event selector.
5. Run the invisible-trait script as a selector and compare/validate its intents against the Dart adaptive-trait engine.
6. Add Android and Windows tests proving the same bundled scripts produce the same validated data contracts.

Until each adapter is complete, the corresponding script remains bundled but is not treated as an active gameplay feature.
