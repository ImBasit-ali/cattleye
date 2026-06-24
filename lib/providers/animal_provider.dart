/// AnimalProvider — thin shim kept for backward compatibility.
/// All logic has moved to CattleProvider. Screens that still reference
/// AnimalProvider can be migrated to CattleProvider incrementally.
library;

export 'cattle_provider.dart' show CattleProvider;
