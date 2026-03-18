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

async function seedDatabase(data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.database();
    await set(ref(db), data);
  });
}

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

test('RTDB presence: no autenticado no puede leer ni escribir', async () => {
  const anonDb = testEnv.unauthenticatedContext().database();
  await assertFails(get(ref(anonDb, 'presence/c1/pulse')));
  await assertFails(set(ref(anonDb, 'presence/c1/user1Id'), 'u1'));
});

test('RTDB presence: el miembro registra su slot y puede escribir su online', async () => {
  const dbU1 = testEnv.authenticatedContext('u1').database();

  await assertSucceeds(set(ref(dbU1, 'presence/c1/user1Id'), 'u1'));
  await assertSucceeds(set(ref(dbU1, 'presence/c1/user1Online'), true));
  await assertFails(set(ref(dbU1, 'presence/c1/user2Online'), true));
});

test('RTDB presence: no-miembro no puede leer presencia de otra pareja', async () => {
  await seedDatabase({
    presence: {
      c1: {
        user1Id: 'u1',
        user2Id: 'u2',
        user1Online: true,
        user2Online: false,
      },
    },
  });

  const dbU3 = testEnv.authenticatedContext('u3').database();
  await assertFails(get(ref(dbU3, 'presence/c1/user1Online')));
});

test('RTDB pulse: solo miembro puede enviar y from debe coincidir con auth.uid', async () => {
  await seedDatabase({
    presence: {
      c1: {
        user1Id: 'u1',
        user2Id: 'u2',
      },
    },
  });

  const dbU1 = testEnv.authenticatedContext('u1').database();
  const dbU3 = testEnv.authenticatedContext('u3').database();

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
  await assertFails(
    set(ref(dbU3, 'presence/c1/pulse'), {
      from: 'u3',
      at: 123,
    })
  );
});
