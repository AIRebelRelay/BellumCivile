using System;
using TaleWorlds.Localization;

namespace BellumCivile.Behaviors
{
    public partial class FeudalTitleBehavior
    {
        internal RecordedNameSnapshot ReadExistingTitleName(string id, float day)
        {
            if (_titlesById == null)
                return new RecordedNameSnapshot(id, RecordedNameKind.Title, day, RecordedNameStatus.RecordsUnavailable);
            FeudalTitleRecord title;
            if (!_titlesById.TryGetValue(id, out title))
                return new RecordedNameSnapshot(id, RecordedNameKind.Title, day, RecordedNameStatus.NotRecorded);
            if (title == null || !string.Equals(id, title.TitleId, StringComparison.Ordinal))
                return new RecordedNameSnapshot(id, RecordedNameKind.Title, day, RecordedNameStatus.InvalidRecord);
            if (title.IsDeliberatelyDissolved)
                return new RecordedNameSnapshot(id, RecordedNameKind.Title, day, RecordedNameStatus.Dissolved);
            if (!title.IsActive)
                return new RecordedNameSnapshot(id, RecordedNameKind.Title, day, RecordedNameStatus.Inactive);
            try
            {
                string name = string.IsNullOrWhiteSpace(title.Name) ? null : new TextObject(title.Name).ToString();
                return new RecordedNameSnapshot(id, RecordedNameKind.Title, day,
                    string.IsNullOrWhiteSpace(name) ? RecordedNameStatus.EmptyName : RecordedNameStatus.Recorded, name);
            }
            catch { return new RecordedNameSnapshot(id, RecordedNameKind.Title, day, RecordedNameStatus.RenderingFailed); }
        }
    }
}
