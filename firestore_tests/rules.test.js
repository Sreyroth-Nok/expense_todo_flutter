// Security-rule tests for LifeMate (Phases 1–3). Phases 4–5: rules_phase45.test.js
//
// Run from this folder:   npm install   then   npm test
// `npm test` starts the Firestore emulator, runs these tests, and stops it.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  deleteDoc,
  doc,
  getDoc,
  serverTimestamp,
  setDoc,
  Timestamp,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';

let env;

const ALICE = 'alice';
const BOB = 'bob';

// Signed-in users carry an email claim, like real Firebase Auth tokens.
const db = (uid) =>
  env.authenticatedContext(uid, { email: `${uid}@example.com` }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

const validTx = () => ({
  type: 'expense',
  amountMinorUnits: 450,
  currency: 'USD',
  categoryId: 'food',
  categoryName: 'Food & Drinks',
  description: 'Lunch',
  date: Timestamp.now(),
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const validLimit = (period = 'daily') => ({
  period,
  amountMinorUnits: 500,
  currency: 'USD',
  alertsEnabled: true,
  warningThresholdPercent: 80,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

const validProfile = () => ({
  displayName: 'Alice',
  email: 'alice@example.com',
  currency: 'USD',
  locale: 'en',
  timeZone: 'UTC',
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lifemate',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});

beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

describe('ownership', () => {
  test('owner can create and read own transaction', async () => {
    const ref = doc(db(ALICE), 'users/alice/transactions/t1');
    await assertSucceeds(setDoc(ref, validTx()));
    await assertSucceeds(getDoc(ref));
  });

  test("another user cannot read or write alice's data", async () => {
    await assertSucceeds(setDoc(doc(db(ALICE), 'users/alice/transactions/t1'), validTx()));
    await assertFails(getDoc(doc(db(BOB), 'users/alice/transactions/t1')));
    await assertFails(setDoc(doc(db(BOB), 'users/alice/transactions/t2'), validTx()));
    await assertFails(deleteDoc(doc(db(BOB), 'users/alice/transactions/t1')));
  });

  test('signed-out users are denied', async () => {
    await assertFails(getDoc(doc(anon(), 'users/alice/transactions/t1')));
    await assertFails(setDoc(doc(anon(), 'users/alice/transactions/t1'), validTx()));
  });

  test('unknown collections are denied', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'users/alice/secrets/s1'), { name: 'x' }));
    await assertFails(setDoc(doc(db(ALICE), 'anything/else'), { a: 1 }));
  });
});

describe('user profile', () => {
  test('valid profile can be created and createdAt cannot change', async () => {
    const ref = doc(db(ALICE), 'users/alice');
    await assertSucceeds(setDoc(ref, validProfile()));
    await assertSucceeds(
      setDoc(ref, { categoriesSeeded: true, updatedAt: serverTimestamp() }, { merge: true }),
    );
    await assertFails(updateDoc(ref, { createdAt: Timestamp.fromMillis(0), updatedAt: serverTimestamp() }));
  });

  test('unknown profile fields are rejected', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'users/alice'), { ...validProfile(), isAdmin: true }));
  });
});

describe('transaction validation', () => {
  const ref = () => doc(db(ALICE), 'users/alice/transactions/t1');

  test('rejects zero, negative and decimal amounts', async () => {
    await assertFails(setDoc(ref(), { ...validTx(), amountMinorUnits: 0 }));
    await assertFails(setDoc(ref(), { ...validTx(), amountMinorUnits: -5 }));
    await assertFails(setDoc(ref(), { ...validTx(), amountMinorUnits: 4.5 }));
  });

  test('rejects bad type, currency, extra fields and missing fields', async () => {
    await assertFails(setDoc(ref(), { ...validTx(), type: 'transfer' }));
    await assertFails(setDoc(ref(), { ...validTx(), currency: 'usd' }));
    await assertFails(setDoc(ref(), { ...validTx(), userId: 'bob' }));
    const { categoryId, ...missing } = validTx();
    await assertFails(setDoc(ref(), missing));
  });

  test('rejects descriptions over 200 characters', async () => {
    await assertFails(setDoc(ref(), { ...validTx(), description: 'x'.repeat(201) }));
  });

  test('rejects client-chosen timestamps', async () => {
    await assertFails(setDoc(ref(), { ...validTx(), createdAt: Timestamp.fromMillis(0) }));
  });

  test('update keeps createdAt and requires server updatedAt', async () => {
    await assertSucceeds(setDoc(ref(), validTx()));
    await assertSucceeds(updateDoc(ref(), { amountMinorUnits: 200, updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref(), { amountMinorUnits: 300 })); // stale updatedAt
    await assertFails(
      updateDoc(ref(), { createdAt: serverTimestamp(), updatedAt: serverTimestamp() }),
    );
  });

  test('owner can delete', async () => {
    await assertSucceeds(setDoc(ref(), validTx()));
    await assertSucceeds(deleteDoc(ref()));
  });
});

describe('categories', () => {
  const cat = () => ({
    name: 'Food',
    type: 'expense',
    iconKey: 'food',
    colorValue: 4292311040,
    isDefault: true,
    createdAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  });

  test('seeding batch (categories + profile flag) succeeds', async () => {
    const alice = db(ALICE);
    await assertSucceeds(setDoc(doc(alice, 'users/alice'), validProfile()));
    const batch = writeBatch(alice);
    batch.set(doc(alice, 'users/alice/categories/food'), cat());
    batch.set(doc(alice, 'users/alice'), { categoriesSeeded: true, updatedAt: serverTimestamp() }, { merge: true });
    await assertSucceeds(batch.commit());
  });

  test('name length and type are validated; type is immutable', async () => {
    const ref = doc(db(ALICE), 'users/alice/categories/c1');
    await assertFails(setDoc(ref, { ...cat(), name: '' }));
    await assertFails(setDoc(ref, { ...cat(), name: 'x'.repeat(31) }));
    await assertSucceeds(setDoc(ref, cat()));
    await assertFails(updateDoc(ref, { type: 'income', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref, { name: 'Meals', updatedAt: serverTimestamp() }));
  });
});

describe('spending limits', () => {
  test('daily and monthly limits can be created', async () => {
    await assertSucceeds(setDoc(doc(db(ALICE), 'users/alice/spendingLimits/daily'), validLimit('daily')));
    await assertSucceeds(setDoc(doc(db(ALICE), 'users/alice/spendingLimits/monthly'), validLimit('monthly')));
  });

  test('doc id must match period and be daily/monthly', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'users/alice/spendingLimits/daily'), validLimit('monthly')));
    await assertFails(setDoc(doc(db(ALICE), 'users/alice/spendingLimits/weekly'), validLimit('weekly')));
  });

  test('threshold must be null or 1–99, amount positive int', async () => {
    const ref = doc(db(ALICE), 'users/alice/spendingLimits/daily');
    await assertSucceeds(setDoc(ref, { ...validLimit(), warningThresholdPercent: null }));
    await assertFails(setDoc(ref, { ...validLimit(), warningThresholdPercent: 100 }));
    await assertFails(setDoc(ref, { ...validLimit(), warningThresholdPercent: 0 }));
    await assertFails(setDoc(ref, { ...validLimit(), amountMinorUnits: 0 }));
  });
});

describe('notification events', () => {
  const event = (overrides = {}) => ({
    kind: 'spendingLimit',
    period: 'daily',
    periodKey: '2026-10-23',
    level: 'warning',
    updatedAt: serverTimestamp(),
    ...overrides,
  });

  test('valid alert state can be written and updated', async () => {
    const ref = doc(db(ALICE), 'users/alice/notificationEvents/limit_daily_2026-10-23');
    await assertSucceeds(setDoc(ref, event()));
    await assertSucceeds(setDoc(ref, event({ level: 'exceeded' })));
  });

  test('id must match period and key; level must be known', async () => {
    await assertFails(setDoc(doc(db(ALICE), 'users/alice/notificationEvents/random'), event()));
    await assertFails(
      setDoc(doc(db(ALICE), 'users/alice/notificationEvents/limit_daily_2026-10-23'), event({ level: 'panic' })),
    );
  });
});
