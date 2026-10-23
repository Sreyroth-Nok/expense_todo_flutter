// Phase 6 security review: profile document hardening.
// Run with `npm test` from this folder.

import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc, updateDoc } from 'firebase/firestore';

let env;
const db = (uid, email = `${uid}@example.com`) =>
  env.authenticatedContext(uid, { email }).firestore();

const profile = (o = {}) => ({
  displayName: 'Alice',
  email: 'alice@example.com',
  currency: 'USD',
  locale: 'en',
  timeZone: 'Asia/Phnom_Penh',
  notificationPreferences: { spendingLimits: true, reminders: true, tasks: true, events: true, savings: true },
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...o,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lifemate-p6',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

describe('profile document', () => {
  const ref = () => doc(db('alice'), 'users/alice');

  test('valid profile with Khmer locale and preferences is accepted', async () => {
    await assertSucceeds(setDoc(ref(), profile({ locale: 'km' })));
  });

  test('email must match the signed-in account', async () => {
    await assertFails(setDoc(ref(), profile({ email: 'someone@else.com' })));
  });

  test('email and createdAt cannot be changed later', async () => {
    await assertSucceeds(setDoc(ref(), profile()));
    await assertFails(updateDoc(ref(), { email: 'new@example.com', updatedAt: serverTimestamp() }));
  });

  test('language, currency and time zone settings can be updated', async () => {
    await assertSucceeds(setDoc(ref(), profile()));
    await assertSucceeds(updateDoc(ref(), { locale: 'km', currency: 'KHR', updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref(), { timeZone: 'Asia/Bangkok', updatedAt: serverTimestamp() }));
  });

  test('unsupported locale, empty time zone and bad preferences are rejected', async () => {
    await assertSucceeds(setDoc(ref(), profile()));
    await assertFails(updateDoc(ref(), { locale: 'fr', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref(), { timeZone: '', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref(), {
      notificationPreferences: { reminders: 'yes' }, updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(ref(), {
      notificationPreferences: { marketing: true }, updatedAt: serverTimestamp(),
    }));
  });

  test('preferences update with only some keys is accepted', async () => {
    await assertSucceeds(setDoc(ref(), profile()));
    await assertSucceeds(updateDoc(ref(), {
      notificationPreferences: { tasks: false }, updatedAt: serverTimestamp(),
    }));
  });

  test('another user cannot change alice\'s profile', async () => {
    await assertSucceeds(setDoc(ref(), profile()));
    await assertFails(
      updateDoc(doc(db('bob'), 'users/alice'), { displayName: 'Hacked', updatedAt: serverTimestamp() }),
    );
  });
});
