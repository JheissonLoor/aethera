const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const projectId = 'demo-aethera';
const firestoreRules = fs.readFileSync(
  path.resolve(__dirname, '../../firestore.rules'),
  'utf8'
);

let testEnv;

async function seedFirestore(data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [docPath, value] of Object.entries(data)) {
      await db.doc(docPath).set(value);
    }
  });
}

function baseUser(uid) {
  return {
    email: `${uid}@mail.com`,
    displayName: uid.toUpperCase(),
    createdAt: 1,
  };
}

function openCouple(user1Id, inviteCode = 'ABC123') {
  return {
    user1Id,
    user2Id: '',
    inviteCode,
    createdAt: 1,
    connectionStrength: 0,
    universeState: { phase: 'night', level: 1, lastInteraction: 1 },
  };
}

function closedCouple(user1Id, user2Id, inviteCode = 'ABC123') {
  return {
    user1Id,
    user2Id,
    inviteCode,
    createdAt: 1,
    connectionStrength: 0,
    universeState: { phase: 'night', level: 1, lastInteraction: 1 },
  };
}

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: firestoreRules,
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.afterEach(async () => {
  await testEnv.clearFirestore();
});

test('users: cada usuario solo puede leer su propio documento', async () => {
  await seedFirestore({
    'users/u1': baseUser('u1'),
    'users/u2': baseUser('u2'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertSucceeds(dbU1.collection('users').doc('u1').get());
  await assertFails(dbU1.collection('users').doc('u2').get());
});

test('users: create rechaza coupleId arbitrario', async () => {
  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertFails(
    dbU1.collection('users').doc('u1').set({
      ...baseUser('u1'),
      coupleId: 'c1',
    })
  );
});

test('users: update de coupleId solo si el usuario es miembro real de la pareja', async () => {
  await seedFirestore({
    'users/u1': baseUser('u1'),
    'users/u2': baseUser('u2'),
    'couples/c1': openCouple('u1', 'ABC123'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  const dbU2 = testEnv.authenticatedContext('u2').firestore();

  await assertSucceeds(dbU1.collection('users').doc('u1').update({ coupleId: 'c1' }));
  await assertFails(dbU2.collection('users').doc('u2').update({ coupleId: 'c1' }));
});

test('couples: crear pareja y publicar invite_code activo', async () => {
  await seedFirestore({
    'users/u1': baseUser('u1'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertSucceeds(
    dbU1.collection('couples').doc('c1').set(openCouple('u1', 'ABC123'))
  );
  await assertSucceeds(
    dbU1.collection('invite_codes').doc('ABC123').set({
      coupleId: 'c1',
      createdBy: 'u1',
      createdAt: 1,
      active: true,
    })
  );
});

test('couples: list bloqueado para evitar enumeracion', async () => {
  await seedFirestore({
    'users/u2': baseUser('u2'),
    'couples/c1': openCouple('u1', 'ABC123'),
  });

  const dbU2 = testEnv.authenticatedContext('u2').firestore();
  await assertFails(dbU2.collection('couples').limit(1).get());
});

test('couples: join solo permitido con invite_code activo asociado', async () => {
  await seedFirestore({
    'users/u2': baseUser('u2'),
    'couples/c1': openCouple('u1', 'ABC123'),
    'invite_codes/ABC123': {
      coupleId: 'c1',
      createdBy: 'u1',
      createdAt: 1,
      active: true,
    },
    'couples/c2': openCouple('u1', 'DEF456'),
  });

  const dbU2 = testEnv.authenticatedContext('u2').firestore();
  await assertSucceeds(dbU2.collection('couples').doc('c1').update({ user2Id: 'u2' }));
  await assertSucceeds(dbU2.collection('invite_codes').doc('ABC123').update({ active: false }));
  await assertFails(dbU2.collection('couples').doc('c2').update({ user2Id: 'u2' }));
});

test('couples: no miembro no puede leer pareja cerrada', async () => {
  await seedFirestore({
    'users/u3': baseUser('u3'),
    'couples/c1': closedCouple('u1', 'u2', 'ABC123'),
  });

  const dbU3 = testEnv.authenticatedContext('u3').firestore();
  await assertFails(dbU3.collection('couples').doc('c1').get());
});

test('memories: coupleId forjado en users no concede acceso cross-couple', async () => {
  await seedFirestore({
    'users/u1': { ...baseUser('u1'), coupleId: 'c1' },
    'users/u3': { ...baseUser('u3'), coupleId: 'c1' },
    'couples/c1': closedCouple('u1', 'u2', 'ABC123'),
  });

  const dbU3 = testEnv.authenticatedContext('u3').firestore();
  await assertFails(
    dbU3.collection('memories').doc('m1').set({
      id: 'm1',
      coupleId: 'c1',
      title: 'Hack',
      description: 'Intento',
      createdByUserId: 'u3',
      createdAt: 1,
      posX: 0.5,
      posY: 0.5,
    })
  );
});

test('memories: miembro real puede crear', async () => {
  await seedFirestore({
    'users/u1': { ...baseUser('u1'), coupleId: 'c1' },
    'couples/c1': closedCouple('u1', 'u2', 'ABC123'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertSucceeds(
    dbU1.collection('memories').doc('m1').set({
      id: 'm1',
      coupleId: 'c1',
      title: 'Recuerdo',
      description: 'Texto',
      createdByUserId: 'u1',
      createdAt: 1,
      posX: 0.5,
      posY: 0.5,
    })
  );
});

test('couples.update: miembro puede tocar solo campos permitidos', async () => {
  await seedFirestore({
    'users/u1': { ...baseUser('u1'), coupleId: 'c1' },
    'couples/c1': closedCouple('u1', 'u2', 'ABC123'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertSucceeds(
    dbU1.collection('couples').doc('c1').update({
      connectionStrength: 12,
      user1Emotion: { mood: 'joy', intensity: 0.8, updatedAt: 2 },
      lastCheckinUser1: '2026-03-17',
      streakDays: 2,
      lastStreakDate: '2026-03-17',
    })
  );

  await assertFails(
    dbU1.collection('couples').doc('c1').update({
      inviteCode: 'HACK00',
    })
  );
});

test('rituals: permite claves dinamicas de la pareja y bloquea claves externas', async () => {
  await seedFirestore({
    'users/u1': { ...baseUser('u1'), coupleId: 'c1' },
    'users/u2': { ...baseUser('u2'), coupleId: 'c1' },
    'couples/c1': closedCouple('u1', 'u2', 'ABC123'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertSucceeds(
    dbU1.collection('rituals').doc('c1').collection('weekly').doc('2026-W11').set({
      question: 'Q',
      answer_u1: 'A',
      gratitude_u1: ['G1', 'G2'],
      completedBy: ['u1'],
      updatedAt: 1,
    })
  );

  await assertFails(
    dbU1.collection('rituals').doc('c1').collection('weekly').doc('2026-W11').update({
      answer_u3: 'hack',
    })
  );
  await assertFails(
    dbU1.collection('rituals').doc('c1').collection('weekly').doc('2026-W11').update({
      hacked: true,
    })
  );
});

test('sanity: reglas no quedan abiertas globalmente', async () => {
  await seedFirestore({
    'users/u1': baseUser('u1'),
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertFails(dbU1.collection('coleccion_inexistente').doc('x').get());
  assert.ok(true);
});
