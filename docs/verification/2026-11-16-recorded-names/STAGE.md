# S12 — existing recorded title/realm names (Native source candidate)

Repository AIRebelRelay/BellumCivile, verified base PR #51 / feature/cr-existing-political-pressure-2026-11-16 at 68f42416548861fd50130a0bfb550474e7503d6d. Bridge consumer candidate remains PR #118 / 714ec182dfc381d7e6211cac530f6c8268930af6 and is not modified. This stage supplies the passive Native name door required before a separate Bridge lookup binding can be built. All earlier Native/host/Bridge live gates remain pending.

## Root cause, call chain and change boundary

ROOT CAUSE: FeudalTitleBehavior.GetTitle/GetAllTitles call EnsureCollectionsInitialized. Kingdom.Name is patched by DynamicKingdomTitleNamePatch -> ResolveNameRead -> ResolveNativeText/TryResolveDisplayText, which may seed NativeNameRegistry, observe settings/language and clear/populate caches or consult materializing title getters. GetNativeName/GetNativeNameText can also fall back through Kingdom.Name. These are existing working presentation paths, not a passive integration contract.

The new path reads saved title rows or the existing NativeNameRegistry only. It does not regenerate dynamic realm display titles, capture/load Native names, read XML, recover invalid labels or synthesize a name from an ID. Realm labels explicitly mean recorded NATIVE names, not the current generated UI royal style.

TOUCH (production):
- New RecordedNameSnapshot.cs: immutable scalar DTO, kind and statuses, ApiVersion=1.
- New BellumIntegrationRecordedNames.cs: GetExistingName(kind,id), campaign-thread exact-ID facade.
- New Behaviors/FeudalRecordedNameState.cs: direct saved-title projection in partial behavior.
- DynamicKingdomTitleNameHelper.cs: exactly one 11-line insertion, TryReadExistingNativeName. Removing those bytes restores the base helper blob. No other existing file changes.

DO NOT TOUCH: existing title/name getters, ResolveNameRead/TryResolveDisplayText, ObserveSettingState, GetNativeName/Text, native/XML registries/caches/init/invalidation/rename/save hooks, shared Copy semantics, title grant/rename/style/ownership, Native save schema, Bridge/CR/SDK/provider/templates/actions.

MUST FIX: exact existing identity -> detached rendered source label or explicit status. Missing/null storage, inactive/dissolved titles, invalid row identity, empty/render-failed labels and duplicate realm identities do not yield names or trigger repair. A name is not ownership, actor knowledge or action authority. No raw ID fallback or name/prefix/fuzzy lookup.

MUST NOT CHANGE: no Ensure, cache seeding, settings observation, XML loading, dynamic style calculation, source TextObject rendering or source mutation. Existing Copy fallback remains for its existing callers; this new strict API uses CopyTextObject directly and returns RenderingFailed on copy failure instead of losing source variables.

Regression contract before code: exact IDs, missing/null stores, nonactive/dissolved data, duplicate realm identity, different entities with identical names, renamed subsequent reads vs detached old snapshot, guarded thread, no materializing getters and no source/registry mutation. Copy/render failure and unchanged legacy Copy behavior are additionally checked inside the stated boundary.

## Implementation and consumers

GetExistingName(RecordedNameKind.Title,id) -> unchanged RequireCampaignThread -> direct campaign FeudalTitleBehavior -> ReadExistingTitleName -> _titlesById.TryGetValue -> validate actual title ID/flags -> render a NEW TextObject from stored Name -> immutable string snapshot. Title labels reflect current stored records, including completed TryRenameTitle, whose existing path calls title.SetName; no configuration/style overrides are recomputed here.

GetExistingName(RecordedNameKind.Realm,id) -> guarded exact ordinal lookup in Kingdom.All, at most two matches -> reject missing/ambiguous/eliminated -> TryReadExistingNativeName -> existing private ResolveRecordedNativeText (CacheLock + dictionary TryGetValue only) -> CopyTextObject -> render copy -> immutable string. No Kingdom.Name/InformalName/FormalName getter is touched. Realm cache absence stays NotRecorded. The new internal peek has one production caller, the new public facade; it does not widen or change the semantics of existing helpers.

Existing name consumers inspected: DynamicKingdomTitleNamePatch getters, rename/init/save-boundary hooks, FeudalTitleDisplayHelper's realm/title formatting, native root/name helpers, and existing realm-name API source contracts. Their code and behavior remain untouched. ResolveRecordedNativeText and Copy implementations are byte-identical; new code does not use Copy's lossy fallback.

Request: exact kind (Title/Realm), nonblank ID <=256 with no control characters; no trimming/case folding. Capture uses current Native float day. Unknown/invalid kind, ID or time => InvalidRequest. Title service/store absence => BehaviorUnavailable/RecordsUnavailable; missing rows => NotRecorded; malformed keyed row => InvalidRecord; nonactive/dissolved => respective status. Realm list absence => RecordsUnavailable, duplicate exact IDs => AmbiguousIdentity. Unrelated null list entries are not identities. Empty label => EmptyName; render/copy failure => RenderingFailed.

Snapshot fields: EntityId, Kind, CapturedDay, Status, Name. Only Recorded can carry Name. No mutable Native/TextObject/record, holder/rights, persona, claim provenance or private pressure data escapes. Same display names on distinct IDs stay distinct; names must never become reverse entity/action resolution. API is technical and not actor-authorized by itself; future Bridge must query only IDs from its fresh permitted context.

## Evidence

- 36 named cases PASS, C# 7.3 Add-Type. Actual new DTO/facade/partial reader, actual saved FeudalTitleRecord/type, extracted new peek and unchanged ResolveRecordedNativeText/Copy bodies and thread guard. Campaign/Kingdom/TextObject/localization and storage boundaries are doubles. Full DynamicKingdomTitleNameHelper, Harmony patches/game assembly and real localization are NOT compiled/executed by this harness.
- Existing 45 claim-state, 49 pressure, 35 war-state and 20 council-state named cases PASS.
- Bellum157RealmNamesApi source contract PASS; its explicit compile_and_gameplay=NOT_RUN is retained. This is not live rename/save proof.
- Full audit of 1,573 base blobs: 1,572 byte-identical, one exact 11-line insertion. Three production additions; no other existing edits/deletions, project/default/schema/workflow/debug changes. .cs.txt fixtures do not enter Native compile glob. Scratch bin/obj excluded from package.
- Windows/net472 full Native build, engine TextObject copy/localization ABI and live rename/save-load validation PENDING. No automatic API caller/log, Actions run, merge or release is added.

Offline script: Tests/ExistingRecordedName.Tests.ps1 (PowerShell 7.2+). The factory creates technical snapshots only, not prompts or installed DLLs.

## Remaining gates

S12A: actual Windows/net472 Native compilation with real game/Workshop dependencies; identify exact source and DLL versions. Offline extraction is not the build gate.

S12B: after Native name capture, inspect title and realm results for known IDs, missing registry, inactive/dissolved entities, player title rename and Native realm rename/save-reload. Compare realm output to recorded Native name (not generated UI royal style), and title output to current stored title root. A missing cache must not be initialized by reading.

S12C: repeated reads leave source title fields, Native name registry/count, dynamic caches/settings, game-name fields and save behavior unchanged. TextObject variables/localization render on copies; no copy failure falls back to variable-less text or ID. Existing UI dynamic names and save/rename boundaries continue working.

S12D: separate Bridge binding must verify v1 metadata, current campaign/thread, snapshot identity/kind/day/status, request only permitted claim/pressure target IDs, and pass detached exact-ID names into formatter. Missing names remain omitted. No such Bridge binding, lifecycle/provider/template or live prompt activation is implemented here. Preserve all prior host privacy/reader/adapter gates.
