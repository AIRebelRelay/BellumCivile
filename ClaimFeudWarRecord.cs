using System;
using System.Linq;
using TaleWorlds.SaveSystem;

namespace BellumCivile
{
    public class ClaimFeudWarRecord
    {
        [SaveableField(1)] private string _warId;
        [SaveableField(2)] private string _feudRecordId;
        [SaveableField(3)] private string _parentKingdomId;
        [SaveableField(4)] private string _claimantKingdomId;
        [SaveableField(5)] private string _holderKingdomId;
        [SaveableField(6)] private string _targetTitleId;
        [SaveableField(7)] private string _claimantLeaderClanId;
        [SaveableField(8)] private string _holderLeaderClanId;
        [SaveableField(9)] private string _claimantClanIds;
        [SaveableField(10)] private string _holderClanIds;
        [SaveableField(11)] private string _influenceSnapshot;
        [SaveableField(12)] private string _fiefSnapshot;
        [SaveableField(13)] private float _startedDay;
        [SaveableField(14)] private bool _isActive;
        [SaveableField(15)] private string _pendingCaptureWinnerClanId;
        [SaveableField(16)] private bool _claimantControlsObjective;
        [SaveableField(17)] private bool _claimantHasControlledObjective;
        [SaveableField(18)] private int _pendingResolutionOutcome;
        [SaveableField(19)] private string _pendingResolutionReason;
        // Optional on historical saves; zero/absent means no authoritative final result.
        [SaveableField(20)] private int _finalOutcome;
        [SaveableField(21)] private string _finalResultKind;
        [SaveableField(22)] private bool _finalTitleAwardApplied;
        [SaveableField(23)] private string _finalTitleDeJureHolderClanId;
        [SaveableField(24)] private string _finalTitleDeFactoHolderClanId;
        [SaveableField(25)] private string _finalReturnKingdomId;
        [SaveableField(26)] private string _finalDestinationKind;

        public string WarId => _warId;
        public string FeudRecordId => _feudRecordId;
        public string ParentKingdomId => _parentKingdomId;
        public string ClaimantKingdomId => _claimantKingdomId;
        public string HolderKingdomId => _holderKingdomId;
        public string TargetTitleId => _targetTitleId;
        public string ClaimantLeaderClanId => _claimantLeaderClanId;
        public string HolderLeaderClanId => _holderLeaderClanId;
        public string ClaimantClanIds => _claimantClanIds;
        public string HolderClanIds => _holderClanIds;
        public string InfluenceSnapshot => _influenceSnapshot;
        public string FiefSnapshot => _fiefSnapshot;
        public float StartedDay => _startedDay;
        public bool IsActive => _isActive;
        public string PendingCaptureWinnerClanId => _pendingCaptureWinnerClanId;
        public bool ClaimantControlsObjective => _claimantControlsObjective;
        public bool ClaimantHasControlledObjective => _claimantHasControlledObjective;
        public ClaimFeudWarOutcome PendingResolutionOutcome => (ClaimFeudWarOutcome)_pendingResolutionOutcome;
        public string PendingResolutionReason => _pendingResolutionReason;
        public bool HasFinalOutcome => !_isActive
            && _finalOutcome != (int)ClaimFeudWarOutcome.None
            && !string.IsNullOrWhiteSpace(_finalResultKind);
        public ClaimFeudWarOutcome FinalOutcome => HasFinalOutcome
            ? (ClaimFeudWarOutcome)_finalOutcome : ClaimFeudWarOutcome.None;
        public string FinalResultKind => HasFinalOutcome ? _finalResultKind : string.Empty;
        public bool FinalTitleAwardApplied => HasFinalOutcome && _finalTitleAwardApplied;
        public string FinalTitleDeJureHolderClanId => HasFinalOutcome
            ? _finalTitleDeJureHolderClanId ?? string.Empty : string.Empty;
        public string FinalTitleDeFactoHolderClanId => HasFinalOutcome
            ? _finalTitleDeFactoHolderClanId ?? string.Empty : string.Empty;
        public string FinalReturnKingdomId => HasFinalOutcome
            ? _finalReturnKingdomId ?? string.Empty : string.Empty;
        public string FinalDestinationKind => HasFinalOutcome
            ? _finalDestinationKind ?? string.Empty : string.Empty;

        public ClaimFeudWarRecord(
            string warId,
            string feudRecordId,
            string parentKingdomId,
            string claimantKingdomId,
            string holderKingdomId,
            string targetTitleId,
            string claimantLeaderClanId,
            string holderLeaderClanId,
            string claimantClanIds,
            string holderClanIds,
            string influenceSnapshot,
            string fiefSnapshot,
            float startedDay)
        {
            _warId = warId ?? string.Empty;
            _feudRecordId = feudRecordId ?? string.Empty;
            _parentKingdomId = parentKingdomId ?? string.Empty;
            _claimantKingdomId = claimantKingdomId ?? string.Empty;
            _holderKingdomId = holderKingdomId ?? string.Empty;
            _targetTitleId = targetTitleId ?? string.Empty;
            _claimantLeaderClanId = claimantLeaderClanId ?? string.Empty;
            _holderLeaderClanId = holderLeaderClanId ?? string.Empty;
            _claimantClanIds = claimantClanIds ?? string.Empty;
            _holderClanIds = holderClanIds ?? string.Empty;
            _influenceSnapshot = influenceSnapshot ?? string.Empty;
            _fiefSnapshot = fiefSnapshot ?? string.Empty;
            _startedDay = startedDay;
            _isActive = true;
            _pendingCaptureWinnerClanId = string.Empty;
            _claimantControlsObjective = false;
            _claimantHasControlledObjective = false;
            _pendingResolutionOutcome = (int)ClaimFeudWarOutcome.None;
            _pendingResolutionReason = string.Empty;
        }

        // The single authoritative result is recorded only after title settlement and
        // temporary-kingdom cleanup. Unlike PendingResolutionOutcome it survives reload.
        // Old saves leave the optional result fields unset and are never backfilled.
        public bool RecordFinalOutcome(
            ClaimFeudWarOutcome outcome,
            string resultKind,
            bool titleAwardApplied,
            string deJureHolderClanId,
            string deFactoHolderClanId,
            string returnKingdomId,
            string destinationKind)
        {
            if (_isActive || _finalOutcome != (int)ClaimFeudWarOutcome.None
                || outcome == ClaimFeudWarOutcome.None || string.IsNullOrWhiteSpace(resultKind))
                return false;

            _finalResultKind = resultKind;
            _finalTitleAwardApplied = titleAwardApplied;
            _finalTitleDeJureHolderClanId = deJureHolderClanId ?? string.Empty;
            _finalTitleDeFactoHolderClanId = deFactoHolderClanId ?? string.Empty;
            _finalReturnKingdomId = returnKingdomId ?? string.Empty;
            _finalDestinationKind = destinationKind ?? string.Empty;
            _finalOutcome = (int)outcome;
            return true;
        }

        public void SetActive(bool active)
        {
            _isActive = active;
            if (!active)
                ClearPendingResolution();
        }

        internal void RemoveWithdrawnHouse(string clanId)
        {
            _claimantClanIds = ClaimFeudRecord.Without(_claimantClanIds, clanId);
            _holderClanIds = ClaimFeudRecord.Without(_holderClanIds, clanId);
            _influenceSnapshot = string.Join(";", (_influenceSnapshot ?? "").Split(';')
                .Where(entry => !entry.StartsWith(clanId + ":", StringComparison.Ordinal)));
            // Enemy estates stay tracked: they may be captured again by the remaining participants.
            _fiefSnapshot = string.Join(";", (_fiefSnapshot ?? "").Split(';')
                .Where(entry => !entry.EndsWith(":" + clanId, StringComparison.Ordinal)));
            if (_pendingCaptureWinnerClanId == clanId) ClearCaptureWinner();
        }

        public void QueueResolution(ClaimFeudWarOutcome outcome, string reason)
        {
            if (!_isActive || outcome == ClaimFeudWarOutcome.None)
                return;

            _pendingResolutionOutcome = (int)outcome;
            _pendingResolutionReason = reason ?? string.Empty;
        }

        public void ClearPendingResolution()
        {
            _pendingResolutionOutcome = (int)ClaimFeudWarOutcome.None;
            _pendingResolutionReason = string.Empty;
        }

        public void QueueCaptureWinner(string clanId)
        {
            _pendingCaptureWinnerClanId = clanId ?? string.Empty;
        }

        public void ClearCaptureWinner()
        {
            _pendingCaptureWinnerClanId = string.Empty;
        }

        public void InitializeObjectiveControl(bool claimantControlsObjective)
        {
            _claimantControlsObjective = claimantControlsObjective;
            _claimantHasControlledObjective = claimantControlsObjective;
        }

        public void SetObjectiveControl(bool claimantControlsObjective)
        {
            _claimantControlsObjective = claimantControlsObjective;
            if (claimantControlsObjective)
                _claimantHasControlledObjective = true;
        }
    }
}
