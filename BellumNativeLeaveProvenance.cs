using System;
using TaleWorlds.CampaignSystem;

namespace BellumCivile
{
    /// <summary>
    /// Exact native Bellum ownership for synchronous Clan exits.
    /// The public API is observation-only; only this assembly can open a scope.
    /// It does NOT identify an AI Influence intent or attest a Court ticket.
    /// </summary>
    public static class BellumNativeLeaveProvenance
    {
        [ThreadStatic]
        private static Clan _target;
        [ThreadStatic]
        private static string _owner;

        public static string ReadOwnerFor(Clan targetClan)
        {
            return targetClan != null && ReferenceEquals(_target, targetClan)
                ? _owner ?? string.Empty
                : string.Empty;
        }

        internal static IDisposable Enter(Clan targetClan, string owner)
        {
            if (targetClan == null) throw new ArgumentNullException(nameof(targetClan));
            if (string.IsNullOrWhiteSpace(owner)) throw new ArgumentException("Owner is required.", nameof(owner));

            Clan previousTarget = _target;
            string previousOwner = _owner;
            _target = targetClan;
            _owner = owner;
            return new RestoreScope(previousTarget, previousOwner);
        }

        private sealed class RestoreScope : IDisposable
        {
            private readonly Clan _previousTarget;
            private readonly string _previousOwner;
            private bool _disposed;

            internal RestoreScope(Clan previousTarget, string previousOwner)
            {
                _previousTarget = previousTarget;
                _previousOwner = previousOwner;
            }

            public void Dispose()
            {
                if (_disposed) return;
                _disposed = true;
                _target = _previousTarget;
                _owner = _previousOwner;
            }
        }
    }
}
