/// Barrel library exposing every cube-solving algorithm behind a single
/// import, mirroring `pages/library.dart`. A page that needs to run a
/// solver should `import '../algorithms/algorithms.dart';` instead of
/// importing each algorithm file individually.
library;

export 'rubik_cube.dart';
export 'cfop/cfop.dart';
export 'kociemba/kociemba.dart';
export 'thistlethwaite/thistlethwaite.dart' hide KociembaConstants;
