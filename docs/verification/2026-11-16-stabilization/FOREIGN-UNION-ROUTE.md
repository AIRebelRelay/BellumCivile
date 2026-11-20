Foreign accession union source contract

Root cause: the source test still expected a placeholder rejection although realm union is implemented.
Touch: Tests/ForeignAccession.Tests.ps1 only. No accession, diplomacy, journal, or authority production changes.
Regression contract: foreign sovereign accession requires successful journal publication and advancement; either failure defers abdication, and the branch returns before ordinary joining. All other suite checks retained.
Validation: complete ForeignAccession suite PASS. Runtime union recovery remains a native/game gate.
