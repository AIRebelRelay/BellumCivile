using System;
using System.Xml;
using BellumCivile;
using HarmonyLib;

internal static class EncyclopediaInheritanceLayoutTests
{
    internal static void Run(Action<bool, string> check)
    {
        var type = typeof(FeudalTitleRecord).Assembly.GetType(
            "BellumCivile.ViewModelMixin.EncyclopediaHeroFeudalTitlesPrefabExtension", true);
        var patch = Activator.CreateInstance(type, true);
        var document = (XmlDocument)AccessTools.Method(type, "GetPrefabExtension").Invoke(patch, null);
        var titles = (XmlElement)document.SelectSingleNode("//GridWidget[@DataSource='{BellumTitles}']");
        var inheritance = (XmlElement)document.SelectSingleNode("//GridWidget[@DataSource='{BellumInheritance}']");
        check(inheritance != null, "Inheritance uses a grid rather than a single-column list");
        check(inheritance.GetAttribute("ColumnCount") == "2"
            && inheritance.GetAttribute("ColumnCount") == titles.GetAttribute("ColumnCount"),
            "Inheritance matches the two-column Titles layout");
        check(inheritance.GetAttribute("DefaultCellWidth") == titles.GetAttribute("DefaultCellWidth")
            && inheritance.GetAttribute("WidthSizePolicy") == "StretchToParent",
            "Inheritance columns share the available page width like Titles");
        check(inheritance.GetAttribute("UseDynamicCellHeight") == "true"
            && inheritance.GetAttribute("HeightSizePolicy") == "CoverChildren",
            "Inheritance rows grow to accommodate wrapped names and provenance");

        var item = (XmlElement)inheritance.SelectSingleNode("ItemTemplate/ListPanel");
        check(item.GetAttribute("StackLayout.LayoutMethod") == "VerticalTopToBottom"
            && item.GetAttribute("HeightSizePolicy") == "CoverChildren",
            "Each title stays above its provenance within the same grid cell");
        check(item.GetAttribute("MarginRight") == "15" && item.GetAttribute("MarginBottom") == "12",
            "Inheritance entries retain column and row spacing");
        foreach (string binding in new[] { "@Definition", "@Value" })
        {
            var text = (XmlElement)item.SelectSingleNode("Children/TextWidget[@Text='" + binding + "']");
            check(text != null && text.GetAttribute("WidthSizePolicy") == "StretchToParent"
                && text.GetAttribute("HeightSizePolicy") == "CoverChildren",
                "Inheritance " + binding + " wraps within its column");
        }

        check(document.SelectSingleNode("//*[@Text='@BellumInheritanceCaveat']") == null,
            "Hero page no longer repeats the successor tooltip caveat");
        var divider = (XmlElement)document.SelectSingleNode("//*[@Id='BellumInheritanceDivider']");
        check(divider.GetAttribute("Parameter.ItemList") == "..\\BellumInheritanceParent"
            && inheritance.ParentNode.ParentNode.Attributes["Id"].Value == "BellumInheritanceParent",
            "Inheritance section collapse still targets the full list");
    }
}
