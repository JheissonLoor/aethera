const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');
const { ref, uploadString } = require('firebase/storage');

const projectId = 'demo-aethera';
const storageRules = fs.readFileSync(
  path.resolve(__dirname, '../../storage.rules'),
  'utf8'
);

let testEnv;

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    storage: {
      host: '127.0.0.1',
      port: 9199,
      rules: storageRules,
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.afterEach(async () => {
  await testEnv.clearStorage();
});

test('Storage: owner puede subir contenido permitido en su namespace', async () => {
  const storageU1 = testEnv.authenticatedContext('u1').storage();
  await assertSucceeds(
    uploadString(
      ref(storageU1, 'users/u1/photo.png'),
      'a'.repeat(256),
      'raw',
      { contentType: 'image/png' }
    )
  );
});

test('Storage: no-owner no puede escribir en namespace ajeno', async () => {
  const storageU1 = testEnv.authenticatedContext('u1').storage();
  await assertFails(
    uploadString(
      ref(storageU1, 'users/u2/photo.png'),
      'a'.repeat(128),
      'raw',
      { contentType: 'image/png' }
    )
  );
});

test('Storage: tipo de contenido no permitido es rechazado', async () => {
  const storageU1 = testEnv.authenticatedContext('u1').storage();
  await assertFails(
    uploadString(
      ref(storageU1, 'users/u1/file.txt'),
      'hello',
      'raw',
      { contentType: 'text/plain' }
    )
  );
});
