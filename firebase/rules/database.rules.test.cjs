const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { ref, set, get } = require('firebase/database');

const projectId = 'demo-aethera';
const databaseRules = fs.readFileSync(
  path.resolve(__dirname, '../../database.rules.json'),
  'utf8'
);

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    database: {
      host: '127.0.0.1',
      port: 9000,
      rules: databaseRules,
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.afterEach(async () => {
  await testEnv.clearDatabase();
});

test('RTDB presence: lectura y escritura requieren autenticacion', async () => {
  const anonDb = testEnv.unauthenticatedContext().database();
  const authDb = testEnv.authenticatedContext('u1').database();

  await assertFails(get(ref(anonDb, 'presence/c1/pulse')));
  await assertSucceeds(set(ref(authDb, 'presence/c1/user1Online'), true));
});

test('RTDB presence: user1Online y user2Online solo aceptan boolean', async () => {
  const db = testEnv.authenticatedContext('u1').database();

  await assertSucceeds(set(ref(db, 'presence/c1/user1Online'), false));
  await assertSucceeds(set(ref(db, 'presence/c1/user2Online'), true));
  await assertFails(set(ref(db, 'presence/c1/user1Online'), 'si'));
});

test('RTDB pulse: el campo from debe coincidir con auth.uid', async () => {
  const dbU1 = testEnv.authenticatedContext('u1').database();

  await assertSucceeds(
    set(ref(dbU1, 'presence/c1/pulse'), {
      from: 'u1',
      at: 123,
    })
  );

  await assertFails(
    set(ref(dbU1, 'presence/c1/pulse'), {
      from: 'u2',
      at: 123,
    })
  );
});

test('RTDB pulse: requiere estructura minima valida', async () => {
  const db = testEnv.authenticatedContext('u1').database();

  await assertFails(set(ref(db, 'presence/c1/pulse'), { from: 'u1' }));
  await assertFails(set(ref(db, 'presence/c1/pulse'), { at: 123 }));
});
