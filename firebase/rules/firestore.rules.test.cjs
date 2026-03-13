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
    'users/u1': { email: 'u1@mail.com', displayName: 'U1', createdAt: 1 },
    'users/u2': { email: 'u2@mail.com', displayName: 'U2', createdAt: 1 },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  const own = dbU1.collection('users').doc('u1').get();
  const foreign = dbU1.collection('users').doc('u2').get();

  await assertSucceeds(own);
  await assertFails(foreign);
});

test('users: no permite registrar pareja inexistente', async () => {
  await seedFirestore({
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
    },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertFails(
    dbU1.collection('users').doc('u1').update({ coupleId: 'no-existe' })
  );
});

test('couples: permite crear universo nuevo al user1 autenticado', async () => {
  await seedFirestore({
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
    },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();

  await assertSucceeds(
    dbU1.collection('couples').doc('c1').set({
      user1Id: 'u1',
      user2Id: '',
      inviteCode: 'ABC123',
      createdAt: 1,
      connectionStrength: 0,
      universeState: {
        phase: 'night',
        level: 1,
        lastInteraction: 1,
      },
    })
  );
});

test('couples: no miembro no puede leer pareja cerrada', async () => {
  await seedFirestore({
    'users/u3': { email: 'u3@mail.com', displayName: 'U3', createdAt: 1 },
    'couples/c1': {
      user1Id: 'u1',
      user2Id: 'u2',
      inviteCode: 'ABC123',
      createdAt: 1,
      connectionStrength: 0,
      universeState: { phase: 'night', level: 1, lastInteraction: 1 },
    },
  });

  const dbU3 = testEnv.authenticatedContext('u3').firestore();
  await assertFails(dbU3.collection('couples').doc('c1').get());
});

test('couples: consulta de codigo de invitacion para pareja abierta', async () => {
  await seedFirestore({
    'users/u2': { email: 'u2@mail.com', displayName: 'U2', createdAt: 1 },
    'couples/c1': {
      user1Id: 'u1',
      user2Id: '',
      inviteCode: 'ABC123',
      createdAt: 1,
      connectionStrength: 0,
      universeState: { phase: 'night', level: 1, lastInteraction: 1 },
    },
  });

  const dbU2 = testEnv.authenticatedContext('u2').firestore();

  await assertSucceeds(
    dbU2
      .collection('couples')
      .where('inviteCode', '==', 'ABC123')
      .limit(1)
      .get()
  );

  await assertFails(
    dbU2.collection('couples').where('inviteCode', '==', 'ABC123').get()
  );
});

test('couples: join permitido solo cambiando user2Id', async () => {
  await seedFirestore({
    'users/u2': { email: 'u2@mail.com', displayName: 'U2', createdAt: 1 },
    'couples/c1': {
      user1Id: 'u1',
      user2Id: '',
      inviteCode: 'ABC123',
      createdAt: 1,
      connectionStrength: 0,
      universeState: { phase: 'night', level: 1, lastInteraction: 1 },
    },
  });

  const dbU2 = testEnv.authenticatedContext('u2').firestore();

  await assertSucceeds(
    dbU2.collection('couples').doc('c1').update({ user2Id: 'u2' })
  );

  await assertFails(
    dbU2.collection('couples').doc('c1').update({
      user2Id: 'u2',
      inviteCode: 'HACK00',
    })
  );
});

test('memories: solo miembros de la pareja pueden crear', async () => {
  await seedFirestore({
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
      coupleId: 'c1',
    },
    'users/u3': {
      email: 'u3@mail.com',
      displayName: 'U3',
      createdAt: 1,
      coupleId: 'c9',
    },
  });

  const goodDb = testEnv.authenticatedContext('u1').firestore();
  const badDb = testEnv.authenticatedContext('u3').firestore();

  const payload = {
    coupleId: 'c1',
    type: 'constellation',
    title: 'Recuerdo',
    description: 'Texto',
    createdByUserId: 'u1',
    createdAt: 1,
    posX: 0.3,
    posY: 0.7,
  };

  await assertSucceeds(goodDb.collection('memories').doc('m1').set(payload));
  await assertFails(badDb.collection('memories').doc('m2').set(payload));
});

test('goals: miembro puede actualizar progreso, no campos estructurales', async () => {
  await seedFirestore({
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
      coupleId: 'c1',
    },
    'goals/g1': {
      coupleId: 'c1',
      title: 'Meta',
      description: 'Desc',
      targetDate: 100,
      progress: 0.2,
      symbol: 'lighthouse',
      createdAt: 1,
      completedAt: null,
    },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();

  await assertSucceeds(
    dbU1.collection('goals').doc('g1').update({ progress: 0.8, completedAt: 200 })
  );

  await assertFails(dbU1.collection('goals').doc('g1').update({ title: 'Hack' }));
});

test('daily_questions: solo se puede modificar la propia respuesta', async () => {
  await seedFirestore({
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
      coupleId: 'c1',
    },
    'daily_questions/c1_2026-03-13': {
      coupleId: 'c1',
      dayKey: '2026-03-13',
      question: 'Q',
      answers: { u2: 'Hola' },
      createdAt: 1,
      revealedAt: null,
    },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();

  await assertSucceeds(
    dbU1.collection('daily_questions').doc('c1_2026-03-13').update({
      answers: { u1: 'Mi respuesta', u2: 'Hola' },
      revealedAt: 2,
    })
  );

  await assertFails(
    dbU1.collection('daily_questions').doc('c1_2026-03-13').update({
      answers: { u1: 'Mi respuesta', u2: 'Alterada' },
      revealedAt: 2,
    })
  );
});

test('wishes: solo la pareja receptora puede marcar visto', async () => {
  await seedFirestore({
    'users/u2': {
      email: 'u2@mail.com',
      displayName: 'U2',
      createdAt: 1,
      coupleId: 'c1',
    },
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
      coupleId: 'c1',
    },
    'wishes/w1': {
      id: 'w1',
      coupleId: 'c1',
      message: 'Hola',
      fromUserId: 'u1',
      createdAt: 1,
      seen: false,
    },
  });

  const dbSender = testEnv.authenticatedContext('u1').firestore();
  const dbPartner = testEnv.authenticatedContext('u2').firestore();

  await assertSucceeds(dbPartner.collection('wishes').doc('w1').update({ seen: true }));
  await assertFails(dbSender.collection('wishes').doc('w1').update({ seen: true }));
});

test('rituals: solo miembros de la pareja pueden leer y escribir', async () => {
  await seedFirestore({
    'users/u1': {
      email: 'u1@mail.com',
      displayName: 'U1',
      createdAt: 1,
      coupleId: 'c1',
    },
    'users/u3': {
      email: 'u3@mail.com',
      displayName: 'U3',
      createdAt: 1,
      coupleId: 'c9',
    },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  const dbU3 = testEnv.authenticatedContext('u3').firestore();

  await assertSucceeds(
    dbU1.collection('rituals').doc('c1').collection('weekly').doc('2026-W11').set({
      question: 'Q',
      answer_u1: 'A',
      completedBy: ['u1'],
      updatedAt: 1,
    })
  );

  await assertFails(
    dbU3.collection('rituals').doc('c1').collection('weekly').doc('2026-W11').get()
  );
});

test('sanity: reglas no quedan abiertas globalmente', async () => {
  await seedFirestore({
    'users/u1': { email: 'u1@mail.com', displayName: 'U1', createdAt: 1, coupleId: 'c1' },
  });

  const dbU1 = testEnv.authenticatedContext('u1').firestore();
  await assertFails(dbU1.collection('coleccion_inexistente').doc('x').get());
  assert.ok(true);
});
