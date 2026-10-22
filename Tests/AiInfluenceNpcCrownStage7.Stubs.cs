// Isolated regression fixtures only; never part of the Bellum release assembly.
using System;
using System.Collections.Generic;
using BellumCivile;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    public enum CourtAgendaState { NotProposed, Announced, Deliberating, Voting, Passed, Defeated, Cancelled }
    public sealed class CourtObjectiveRecord
    {
        public string Kind;
        public string TargetId;
        public string ActionId;
    }
    public sealed class CourtAgendaRecord
    {
        public Kingdom Realm;
        public Clan Sponsor;
        public object Faction;
        public CourtAgendaState State;
        public bool ResultApplied;
        public string IntegrationId = Guid.NewGuid().ToString("N");
        public CourtObjectiveRecord ObjectiveData;
    }
    public static class CourtExecutiveRules { public const string Treason = "treason"; }
    public sealed class CourtTermContext
    {
        public Kingdom Realm;
        public CourtTermContext(Kingdom realm) { Realm = realm; }
    }
    public sealed class CourtObjectiveOwner
    {
        public object Faction;
        public Clan Sponsor;
        public CourtObjectiveOwner(object faction, Clan sponsor) { Faction = faction; Sponsor = sponsor; }
    }
    public sealed class CourtObjectiveCandidate
    {
        public string TargetId;
        public string ActionId;
        public CourtObjectiveCandidate(string target, string action) { TargetId = target; ActionId = action; }
    }
    public sealed class CourtObjectiveEvaluation
    {
        public bool Selectable;
        public bool Viable;
    }
    public sealed class CourtObjectiveChoice
    {
        public string Kind;
        public CourtObjectiveCandidate Candidate;
        public CourtObjectiveEvaluation Evaluation;
        public CourtObjectiveChoice(string kind, CourtObjectiveCandidate candidate, CourtObjectiveEvaluation eval)
        { Kind = kind; Candidate = candidate; Evaluation = eval; }
    }
    public sealed class CourtExecutiveObjectiveSource
    {
        public string Kind { get { return CourtExecutiveRules.Treason; } }
        public static bool CanSelect = true;
        public static bool IsViable = true;
        public CourtObjectiveEvaluation EvaluateCandidate(CourtTermContext ctx, CourtObjectiveOwner owner, CourtObjectiveCandidate candidate)
        {
            return new CourtObjectiveEvaluation { Selectable = CanSelect, Viable = IsViable };
        }
        public void ApplySelection(CourtAgendaRecord agenda, CourtObjectiveChoice choice)
        {
            agenda.ObjectiveData = new CourtObjectiveRecord {
                Kind = choice.Kind, TargetId = choice.Candidate.TargetId,
                ActionId = choice.Candidate.ActionId
            };
        }
    }
    public sealed class CourtObjectiveSelector
    {
        public object FindSource(string kind) { return new CourtExecutiveObjectiveSource(); }
    }
}
namespace BellumCivile.Behaviors
{
    public sealed partial class CourtAgendaBehavior
    {
        private readonly CourtObjectiveSelector _objectiveSelector = new CourtObjectiveSelector();
        private readonly List<CourtAgendaRecord> _agendas = new List<CourtAgendaRecord>();
        public int NotificationCount;
        private IEnumerable<CourtAgendaRecord> IntegrationRecords() { return _agendas; }
        private void NotifyAgenda(CourtAgendaRecord agenda) { NotificationCount++; }
        public NpcCrownTreasonIntentSnapshot LastNoticeToken;
        public NpcCrownTreasonIntentSnapshot WrongRealmNoticeToken;
        public bool ThrowDuringNpcCrownNotice;
        private void NotifyNpcCrownAgenda(CourtAgendaRecord agenda)
        {
            NotificationCount++;
            LastNoticeToken = BellumIntegration.GetActiveNpcCrownAnnouncement(agenda.Realm);
            WrongRealmNoticeToken = BellumIntegration.GetActiveNpcCrownAnnouncement(new Kingdom { StringId = agenda.Realm.StringId });
            if (ThrowDuringNpcCrownNotice)
                throw new InvalidOperationException("simulated_native_notice_error");
        }
        public void AddAgendaForTest(CourtAgendaRecord agenda) { _agendas.Add(agenda); }
    }
}
