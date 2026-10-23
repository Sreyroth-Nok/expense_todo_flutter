// Security-rule tests for Phases 4–5 (budgets, savings, tasks, calendar,
// reminders, shopping). Run with `npm test` from this folder.

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
const db = (uid) => env.authenticatedContext(uid).firestore();
const ts = (iso) => Timestamp.fromDate(new Date(iso));
const stamps = () => ({ createdAt: serverTimestamp(), updatedAt: serverTimestamp() });

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-lifemate-p45',
    firestore: { rules: readFileSync('../firestore.rules', 'utf8') },
  });
});
beforeEach(async () => env.clearFirestore());
after(async () => env.cleanup());

const budget = (o = {}) => ({
  name: 'October',
  startDate: ts('2026-10-01T00:00:00'),
  endDate: ts('2026-10-31T00:00:00'),
  currency: 'USD',
  totalAmountMinorUnits: 50000,
  allocations: { food: 20000 },
  warningThresholdPercent: 80,
  ...stamps(),
  ...o,
});

describe('budgets', () => {
  const ref = () => doc(db('alice'), 'users/alice/budgets/b1');

  test('valid budget can be created, updated and deleted by owner', async () => {
    await assertSucceeds(setDoc(ref(), budget()));
    await assertSucceeds(updateDoc(ref(), { name: 'Oct', updatedAt: serverTimestamp() }));
    await assertSucceeds(deleteDoc(ref()));
  });

  test('other users cannot read it', async () => {
    await assertSucceeds(setDoc(ref(), budget()));
    await assertFails(getDoc(doc(db('bob'), 'users/alice/budgets/b1')));
  });

  test('end before start, > 1 year, bad total and bad threshold are rejected', async () => {
    await assertFails(setDoc(ref(), budget({ endDate: ts('2026-09-01T00:00:00') })));
    await assertFails(setDoc(ref(), budget({ endDate: ts('2028-01-01T00:00:00') })));
    await assertFails(setDoc(ref(), budget({ totalAmountMinorUnits: 0 })));
    await assertFails(setDoc(ref(), budget({ warningThresholdPercent: 150 })));
    await assertFails(setDoc(ref(), budget({ allocations: 'food' })));
  });
});

const goal = (o = {}) => ({
  name: 'Laptop',
  currency: 'USD',
  targetAmountMinorUnits: 80000,
  savedAmountMinorUnits: 0,
  targetDate: null,
  isCompleted: false,
  reminderDayOfMonth: null,
  ...stamps(),
  ...o,
});

describe('savings goals', () => {
  test('goal + starting contribution in one batch succeeds', async () => {
    const alice = db('alice');
    const batch = writeBatch(alice);
    batch.set(doc(alice, 'users/alice/savingsGoals/g1'), goal({ savedAmountMinorUnits: 1000 }));
    batch.set(doc(alice, 'users/alice/savingsGoals/g1/contributions/c1'), {
      amountMinorUnits: 1000,
      note: 'Starting amount',
      date: Timestamp.now(),
      createdAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  test('contribution without a parent goal is rejected', async () => {
    await assertFails(
      setDoc(doc(db('alice'), 'users/alice/savingsGoals/missing/contributions/c1'), {
        amountMinorUnits: 500, note: '', date: Timestamp.now(), createdAt: serverTimestamp(),
      }),
    );
  });

  test('negative saved amount, zero contribution and contribution edits are rejected', async () => {
    const ref = doc(db('alice'), 'users/alice/savingsGoals/g1');
    await assertFails(setDoc(ref, goal({ savedAmountMinorUnits: -1 })));
    await assertSucceeds(setDoc(ref, goal()));
    const c = doc(db('alice'), 'users/alice/savingsGoals/g1/contributions/c1');
    await assertFails(setDoc(c, { amountMinorUnits: 0, note: '', date: Timestamp.now(), createdAt: serverTimestamp() }));
    await assertSucceeds(setDoc(c, { amountMinorUnits: 500, note: '', date: Timestamp.now(), createdAt: serverTimestamp() }));
    await assertFails(updateDoc(c, { amountMinorUnits: 9999 }));
  });

  test('goal currency cannot change; reminder day must be 1–28', async () => {
    const ref = doc(db('alice'), 'users/alice/savingsGoals/g1');
    await assertSucceeds(setDoc(ref, goal()));
    await assertFails(updateDoc(ref, { currency: 'KHR', updatedAt: serverTimestamp() }));
    await assertFails(updateDoc(ref, { reminderDayOfMonth: 31, updatedAt: serverTimestamp() }));
    await assertSucceeds(updateDoc(ref, { reminderDayOfMonth: 15, updatedAt: serverTimestamp() }));
  });
});

describe('tasks', () => {
  const task = (o = {}) => ({
    title: 'Pay rent',
    notes: '',
    dueAt: null,
    hasDueTime: false,
    priority: 'high',
    status: 'todo',
    reminderEnabled: false,
    completedAt: null,
    ...stamps(),
    ...o,
  });
  const ref = () => doc(db('alice'), 'users/alice/tasks/t1');

  test('valid task lifecycle', async () => {
    await assertSucceeds(setDoc(ref(), task()));
    await assertSucceeds(
      updateDoc(ref(), { status: 'done', completedAt: serverTimestamp(), updatedAt: serverTimestamp() }),
    );
  });

  test('bad priority / status / empty title rejected; bob denied', async () => {
    await assertFails(setDoc(ref(), task({ priority: 'urgent' })));
    await assertFails(setDoc(ref(), task({ status: 'archived' })));
    await assertFails(setDoc(ref(), task({ title: '' })));
    await assertFails(setDoc(doc(db('bob'), 'users/alice/tasks/t1'), task()));
  });
});

describe('calendar events', () => {
  const event = (o = {}) => ({
    title: 'Dentist',
    startAt: ts('2026-10-24T09:00:00'),
    endAt: ts('2026-10-24T10:00:00'),
    allDay: false,
    location: '',
    notes: '',
    reminderMinutesBefore: 15,
    ...stamps(),
    ...o,
  });
  const ref = () => doc(db('alice'), 'users/alice/calendarEvents/e1');

  test('valid event accepted', async () => {
    await assertSucceeds(setDoc(ref(), event()));
  });

  test('end before start, > 31 days and bad reminder rejected', async () => {
    await assertFails(setDoc(ref(), event({ endAt: ts('2026-10-24T08:00:00') })));
    await assertFails(setDoc(ref(), event({ endAt: ts('2026-12-30T08:00:00') })));
    await assertFails(setDoc(ref(), event({ reminderMinutesBefore: -5 })));
  });
});

describe('reminders', () => {
  const reminder = (o = {}) => ({
    title: 'Internet bill',
    notes: '',
    kind: 'bill',
    remindAt: ts('2026-11-05T09:00:00'),
    repeat: 'monthly',
    amountMinorUnits: 2500,
    currency: 'USD',
    status: 'pending',
    ...stamps(),
    ...o,
  });
  const ref = () => doc(db('alice'), 'users/alice/reminders/r1');

  test('bill reminder with amount accepted; general without amount accepted', async () => {
    await assertSucceeds(setDoc(ref(), reminder()));
    await assertSucceeds(
      setDoc(doc(db('alice'), 'users/alice/reminders/r2'),
        reminder({ kind: 'general', amountMinorUnits: null, currency: null })),
    );
  });

  test('amount on a general reminder, bad repeat and bad status rejected', async () => {
    await assertFails(setDoc(ref(), reminder({ kind: 'general' })));
    await assertFails(setDoc(ref(), reminder({ repeat: 'yearly' })));
    await assertFails(setDoc(ref(), reminder({ status: 'snoozed' })));
  });
});

describe('shopping lists', () => {
  const item = (o = {}) => ({
    name: 'Rice', quantity: 2, unit: 'kg', isPurchased: false, ...stamps(), ...o,
  });

  test('items require an existing parent list', async () => {
    const alice = db('alice');
    await assertFails(setDoc(doc(alice, 'users/alice/shoppingLists/l1/items/i1'), item()));
    await assertSucceeds(setDoc(doc(alice, 'users/alice/shoppingLists/l1'), { name: 'Market', ...stamps() }));
    await assertSucceeds(setDoc(doc(alice, 'users/alice/shoppingLists/l1/items/i1'), item()));
  });

  test('quantity, name and unit are validated', async () => {
    const alice = db('alice');
    await assertSucceeds(setDoc(doc(alice, 'users/alice/shoppingLists/l1'), { name: 'Market', ...stamps() }));
    const i = doc(alice, 'users/alice/shoppingLists/l1/items/i1');
    await assertFails(setDoc(i, item({ quantity: 0 })));
    await assertFails(setDoc(i, item({ quantity: 1.5 })));
    await assertFails(setDoc(i, item({ name: '' })));
    await assertFails(setDoc(i, item({ unit: 'x'.repeat(13) })));
  });

  test('deleting a list together with its items in one batch works', async () => {
    const alice = db('alice');
    await setDoc(doc(alice, 'users/alice/shoppingLists/l1'), { name: 'Market', ...stamps() });
    await setDoc(doc(alice, 'users/alice/shoppingLists/l1/items/i1'), item());
    const batch = writeBatch(alice);
    batch.delete(doc(alice, 'users/alice/shoppingLists/l1/items/i1'));
    batch.delete(doc(alice, 'users/alice/shoppingLists/l1'));
    await assertSucceeds(batch.commit());
  });

  test('bob cannot add items to alice\'s list', async () => {
    await setDoc(doc(db('alice'), 'users/alice/shoppingLists/l1'), { name: 'Market', ...stamps() });
    await assertFails(setDoc(doc(db('bob'), 'users/alice/shoppingLists/l1/items/i1'), item()));
  });
});
