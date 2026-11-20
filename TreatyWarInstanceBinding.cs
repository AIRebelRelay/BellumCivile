using System;

namespace BellumCivile
{
    // Exact-record binding only; this does NOT prove a unique Native war epoch.
    internal static class TreatyWarInstanceBinding
    {
        internal static bool Matches(string proposalId, string recordId, string proposalKey, string recordKey,
            bool active, bool foreign, bool nativeDeclarationAmbiguous)
        {
            Guid parsed;
            return IsCanonical(proposalId, out parsed)
                && IsCanonical(recordId, out Guid other) && parsed == other
                && !string.IsNullOrWhiteSpace(proposalKey)
                && string.Equals(proposalKey, recordKey, StringComparison.Ordinal)
                && active && foreign && !nativeDeclarationAmbiguous;
        }

        private static bool IsCanonical(string value, out Guid parsed)
        {
            return Guid.TryParseExact(value, "N", out parsed)
                && parsed != Guid.Empty
                && string.Equals(value, parsed.ToString("N"), StringComparison.Ordinal);
        }
    }
}
