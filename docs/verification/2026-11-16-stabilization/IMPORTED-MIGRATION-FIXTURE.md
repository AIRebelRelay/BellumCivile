# Recovery migration fixture inventory — test-only stage

ROOT CAUSE: P014C requires ProtectedRealmLoadMigrationPatch to be absent, although
it is now a real imported native OnGameLoadFinished patch with a version-migration
guard and real recovery fixtures. TOUCH: that single obsolete exclusion assertion.
Require the actual core-assembly type lookup, both active/inactive fixture patches,
ordinary-load-no-rollback case and actual native patch target/version guard.
DO NOT TOUCH: game migration, saved recovery records, fixtures or other assertions.
MUST FIX: inventory actual imported migration coverage without accepting a dummy.
MUST NOT CHANGE: ordinary loads, real destroyed realms and unrelated successor
protection expectations. Whole source suite PASS; full diff audited. Native fixture
execution, old-save migrations and full net472 build remain pending.
