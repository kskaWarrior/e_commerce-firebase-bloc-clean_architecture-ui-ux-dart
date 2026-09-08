import 'package:cloud_functions/cloud_functions.dart';

/// Every callable is deployed to this region, so the client has to resolve the
/// same regional instance — the default `us-central1` one would not find them.
const String functionsRegion = 'southamerica-east1';

/// The regional [FirebaseFunctions] instance every callable in the app uses.
FirebaseFunctions get appFunctions =>
    FirebaseFunctions.instanceFor(region: functionsRegion);

/// Redirect the callables at the local Functions emulator.
///
/// This has to be applied to the *same regional instance* the app resolves;
/// configuring the default instance would silently leave calls hitting
/// production.
void useFunctionsEmulator(String host, [int port = 5001]) {
  appFunctions.useFunctionsEmulator(host, port);
}
