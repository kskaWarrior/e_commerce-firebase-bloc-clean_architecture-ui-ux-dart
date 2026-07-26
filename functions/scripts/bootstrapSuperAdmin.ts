/**
 * One-off bootstrap: grants the platform-owner claim {role: 'super'} to a
 * Firebase Auth user. Run this once for your own account; afterwards all
 * owner assignments go through the setStoreOwner callable.
 *
 * Usage (from functions/):
 *   npx ts-node scripts/bootstrapSuperAdmin.ts <uid-or-email>
 *
 * Credentials: set GOOGLE_APPLICATION_CREDENTIALS to a service-account key
 * for the Firebase project, or run inside `firebase emulators:exec` with
 * FIREBASE_AUTH_EMULATOR_HOST set to target the emulator.
 */
import * as admin from "firebase-admin";

async function main(): Promise<void> {
  const target = process.argv[2];
  if (!target) {
    console.error("Usage: npx ts-node scripts/bootstrapSuperAdmin.ts <uid-or-email>");
    process.exit(64);
  }

  admin.initializeApp();

  const auth = admin.auth();
  const user = target.includes("@") ?
    await auth.getUserByEmail(target) :
    await auth.getUser(target);

  await auth.setCustomUserClaims(user.uid, {role: "super"});

  console.log(`Granted {role: 'super'} to ${user.uid} (${user.email ?? "no email"}).`);
  console.log("The user must sign out/in (or refresh the ID token) to pick up the claim.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
