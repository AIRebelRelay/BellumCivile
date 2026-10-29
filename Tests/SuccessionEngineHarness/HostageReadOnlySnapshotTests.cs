using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Runtime.Serialization;
using BellumCivile;
using BellumCivile.Behaviors;
using HarmonyLib;
using TaleWorlds.CampaignSystem;

// Stage30C regression contract (test-first): immutable, owner-restricted
// observations; NEVER a hostage-release or treaty execution capability.
internal static class HostageReadOnlySnapshotTests
{
    private static T Empty<T>() => (T)FormatterServices.GetUninitializedObject(typeof(T));

    internal static void Run(Action<bool, string> check)
    {
        Type behavior = typeof(HostagePactBehavior);
        MethodInfo api = AccessTools.Method(behavior, "GetReadOnlyPactObservations");
        MethodInfo project = AccessTools.Method(behavior, "ProjectReadOnlyPacts");
        check(api != null && api.IsPublic && api.GetParameters().Length == 1
            && api.GetParameters()[0].ParameterType == typeof(Kingdom),
            "Native exposes an exact single-realm read-only observation API");
        check(project != null && project.IsStatic,
            "Native has an isolated projection seam independent of gameplay callbacks");
        if (project == null) return;

        var first = Empty<Kingdom>();
        var second = Empty<Kingdom>();
        var stranger = Empty<Kingdom>();
        var pact = new HostagePactRecord {
            Id = "pact30c", FirstRealm = first, SecondRealm = second,
            Phase = HostagePactPhase.Active, EndReason = HostagePactEndReason.None,
            AgreedDurationDays = 80, DurationRecorded = true, SignedDay = 20, EndDay = 100,
            TreatyProposalId = "source-treaty"
        };
        var ended = new HostagePactRecord {
            Id = "ended", FirstRealm = first, SecondRealm = second,
            Phase = HostagePactPhase.Ended
        };
        var malformed = new HostagePactRecord {
            Id = "", FirstRealm = first, SecondRealm = second,
            Phase = HostagePactPhase.Active
        };
        var source = new[] { pact, ended, malformed };
        IReadOnlyList<HostagePactReadOnlyObservation> Query(Kingdom realm, bool enabled, bool listed)
            => (IReadOnlyList<HostagePactReadOnlyObservation>)project.Invoke(
                null, new object[] { source, realm, enabled,
                    new Func<HostagePactRecord, bool>(item => listed) });
        var disabled = Query(first, false, false);
        check(disabled.Count == 1 && disabled[0].PactId == "pact30c",
            "Owner sees only non-ended valid saved pact in source projection");
        check(Query(second, false, false).Count == 1
            && Query(stranger, false, false).Count == 0
            && Query(null, false, false).Count == 0,
            "Other party sees the pact; stranger/null realm sees nothing");
        check(disabled[0].SavedPhase == HostagePactPhase.Active
            && disabled[0].Status == "active_revamp_off_pending_termination"
            && !disabled[0].MechanicallyActive
            && !disabled[0].RevampEnabled,
            "Revamp OFF saved Active phase is NOT reported as a lawful current pledge");
        var enabled = Query(first, true, true);
        check(enabled.Count == 1 && enabled[0].Status == "active_confirmed"
            && enabled[0].MechanicallyActive && enabled[0].RevampEnabled,
            "Only the Native-listed current agreement may be described as confirmed");
        check(Query(first, true, false)[0].Status == "active_unverified",
            "Even with Revamp ON, an unlisted saved Active phase is not proof of a valid pact");
        check(enabled[0].TreatyProposalId == "source-treaty"
            && enabled[0].AgreedDurationDays == 80 && enabled[0].EndDay == 100,
            "Projection preserves existing saved source, fixed duration and expiry");
        check(enabled[0].FirstHostage == null && enabled[0].SecondHostage == null,
            "Missing hostage slot never synthesizes a detained hero");
        check(pact.Phase == HostagePactPhase.Active
            && pact.EndReason == HostagePactEndReason.None
            && pact.EndDay == 100,
            "Observation never transitions phase, changes custody, or adjusts saved duration");

        var pending = new HostagePactRecord {
            Id = "pending", FirstRealm = first, SecondRealm = second,
            Phase = HostagePactPhase.Preparing
        };
        var resolving = new HostagePactRecord {
            Id = "resolving", FirstRealm = first, SecondRealm = second,
            Phase = HostagePactPhase.Resolving, EndReason = HostagePactEndReason.War
        };
        var more = new[] { pending, resolving };
        var states = (IReadOnlyList<HostagePactReadOnlyObservation>)project.Invoke(
            null, new object[] { more, first, true,
                new Func<HostagePactRecord, bool>(_ => false) });
        check(states.Count == 2 && states[0].Status == "preparing_not_effective"
            && states[1].Status == "resolving" && states[1].EndReason == HostagePactEndReason.War,
            "Preparation and in-flight war disposition remain distinct from effective pledge");

        check(typeof(HostagePactReadOnlyObservation).GetProperties()
            .All(property => property.SetMethod == null || !property.SetMethod.IsPublic)
            && typeof(HostageCustodyReadOnlyObservation).GetProperties()
                .All(property => property.SetMethod == null || !property.SetMethod.IsPublic),
            "Export DTOs are immutable to Bridge consumers");
        check(new[] { typeof(HostagePactReadOnlyObservation), typeof(HostageCustodyReadOnlyObservation) }
            .SelectMany(type => type.GetFields(BindingFlags.Public | BindingFlags.Instance | BindingFlags.NonPublic))
            .All(field => !field.IsDefined(typeof(TaleWorlds.SaveSystem.SaveableFieldAttribute), false)),
            "Observations do not add fields to the Native save schema");
        check(AccessTools.Method(behavior, "GetActivePacts") != null
            && AccessTools.Method(behavior, "IsProtectedHostage") != null
            && behavior.GetMethods(BindingFlags.Instance | BindingFlags.NonPublic)
                .Any(method => method.Name == "MaintainCustody"),
            "Original Native custody, active-pact and maintenance APIs remain intact");
        check(disabled is IList<HostagePactReadOnlyObservation>
            && ((IList<HostagePactReadOnlyObservation>)disabled).IsReadOnly,
            "Snapshot collection cannot be modified or cast to a writable IList");

        HostagePactRecordTests.Run(check);
        HostagePactDurationTests.Run(check);
    }
}
