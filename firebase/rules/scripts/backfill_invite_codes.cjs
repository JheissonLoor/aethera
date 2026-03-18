#!/usr/bin/env node
/* eslint-disable no-console */
const { randomInt } = require('node:crypto');
const admin = require('firebase-admin');

const INVITE_CODE_LEN = 6;
const INVITE_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

function parseArgs(argv) {
  const options = {
    dryRun: true,
    batchSize: 500,
    maxGenerateAttempts: 64,
    help: false,
    projectId: '',
  };

  for (const arg of argv.slice(2)) {
    if (arg === '--help' || arg === '-h') {
      options.help = true;
    } else if (arg === '--apply') {
      options.dryRun = false;
    } else if (arg === '--dry-run') {
      options.dryRun = true;
    } else if (arg.startsWith('--project=')) {
      options.projectId = arg.slice('--project='.length).trim();
    } else if (arg.startsWith('--batch-size=')) {
      options.batchSize = Number.parseInt(arg.slice('--batch-size='.length), 10);
    } else if (arg.startsWith('--max-generate-attempts=')) {
      options.maxGenerateAttempts = Number.parseInt(
        arg.slice('--max-generate-attempts='.length),
        10
      );
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }

  if (!Number.isInteger(options.batchSize) || options.batchSize <= 0) {
    throw new Error('--batch-size must be a positive integer');
  }
  if (
    !Number.isInteger(options.maxGenerateAttempts) ||
    options.maxGenerateAttempts <= 0
  ) {
    throw new Error('--max-generate-attempts must be a positive integer');
  }

  return options;
}

function printHelp() {
  console.log(`
Backfill invite_codes for open couples.

Usage:
  node scripts/backfill_invite_codes.cjs [--dry-run] [--apply] [--project=<id>] [--batch-size=500]

Options:
  --dry-run                 Default mode. Prints planned changes only.
  --apply                   Writes changes to Firestore.
  --project=<id>            Firebase project id. Fallbacks: FIREBASE_PROJECT_ID, GCLOUD_PROJECT, GOOGLE_CLOUD_PROJECT.
  --batch-size=<n>          Pagination size for couples query. Default: 500.
  --max-generate-attempts   Max retries for unique invite generation. Default: 64.
  --help, -h                Show this help.

Credentials:
  - For production, use GOOGLE_APPLICATION_CREDENTIALS or FIREBASE_SERVICE_ACCOUNT_JSON.
  - For emulator usage, set FIRESTORE_EMULATOR_HOST and a project id.
`);
}

function resolveProjectId(explicitProjectId) {
  return (
    explicitProjectId ||
    process.env.FIREBASE_PROJECT_ID ||
    process.env.GCLOUD_PROJECT ||
    process.env.GOOGLE_CLOUD_PROJECT ||
    ''
  );
}

function initAdmin(projectId) {
  const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (serviceAccountJson) {
    const credentials = admin.credential.cert(JSON.parse(serviceAccountJson));
    admin.initializeApp({ credential: credentials, projectId });
    return;
  }

  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
      projectId,
    });
    return;
  }

  admin.initializeApp({ projectId });
}

function normalizeInviteCode(value) {
  if (typeof value !== 'string') {
    return '';
  }
  return value.trim().toUpperCase();
}

function isInviteCodeValid(code) {
  return /^[A-Z0-9]{6}$/.test(code);
}

function generateInviteCode() {
  let code = '';
  for (let i = 0; i < INVITE_CODE_LEN; i += 1) {
    code += INVITE_CHARS[randomInt(INVITE_CHARS.length)];
  }
  return code;
}

async function listOpenCouples(db, batchSize) {
  const couples = [];
  const fieldPath = admin.firestore.FieldPath.documentId();
  let lastDoc = null;

  while (true) {
    let query = db
      .collection('couples')
      .where('user2Id', '==', '')
      .orderBy(fieldPath)
      .limit(batchSize);
    if (lastDoc) {
      query = query.startAfter(lastDoc.id);
    }
    const snapshot = await query.get();
    if (snapshot.empty) {
      break;
    }

    couples.push(...snapshot.docs);
    lastDoc = snapshot.docs[snapshot.docs.length - 1];
  }

  return couples;
}

async function pickUniqueInviteCode(tx, db, maxGenerateAttempts) {
  for (let attempt = 0; attempt < maxGenerateAttempts; attempt += 1) {
    const candidate = generateInviteCode();
    const candidateRef = db.collection('invite_codes').doc(candidate);
    const candidateSnap = await tx.get(candidateRef);
    if (!candidateSnap.exists) {
      return candidate;
    }
  }
  throw new Error(
    `Failed to generate a unique invite code after ${maxGenerateAttempts} attempts`
  );
}

function classifyCouple(coupleId, coupleData, inviteSnap) {
  const inviteCode = normalizeInviteCode(coupleData.inviteCode);
  const user1Id = typeof coupleData.user1Id === 'string' ? coupleData.user1Id : '';
  const createdAt =
    Number.isInteger(coupleData.createdAt) && coupleData.createdAt > 0
      ? coupleData.createdAt
      : Date.now();

  if (!user1Id) {
    return { action: 'skip_invalid_owner', reason: 'missing_user1Id' };
  }

  if (!isInviteCodeValid(inviteCode)) {
    return {
      action: 'regenerate_code',
      reason: 'invalid_couple_invite_code',
      user1Id,
      createdAt,
    };
  }

  if (!inviteSnap.exists) {
    return {
      action: 'create_invite_doc',
      code: inviteCode,
      reason: 'missing_invite_doc',
      user1Id,
      createdAt,
    };
  }

  const inviteData = inviteSnap.data() || {};
  const inviteCoupleId =
    typeof inviteData.coupleId === 'string' ? inviteData.coupleId : '';
  const isActive = inviteData.active === true;
  if (inviteCoupleId !== coupleId) {
    return {
      action: 'regenerate_code',
      reason: `code_conflict_with_${inviteCoupleId || 'unknown'}`,
      user1Id,
      createdAt,
    };
  }
  if (!isActive) {
    return {
      action: 'reactivate_invite_doc',
      code: inviteCode,
      reason: 'inactive_invite_doc',
      user1Id,
      createdAt,
    };
  }

  return { action: 'noop', code: inviteCode, reason: 'already_ok' };
}

async function applyCreateOrReactivate(db, coupleRef, code, user1Id, createdAt) {
  const inviteRef = db.collection('invite_codes').doc(code);
  await db.runTransaction(async (tx) => {
    const liveCoupleSnap = await tx.get(coupleRef);
    if (!liveCoupleSnap.exists) {
      throw new Error(`couple ${coupleRef.id} no longer exists`);
    }
    const liveData = liveCoupleSnap.data() || {};
    if ((liveData.user2Id || '') !== '') {
      return;
    }
    if (normalizeInviteCode(liveData.inviteCode) !== code) {
      throw new Error(
        `couple ${coupleRef.id} changed inviteCode while processing (${code})`
      );
    }
    tx.set(
      inviteRef,
      {
        coupleId: coupleRef.id,
        createdBy:
          typeof liveData.user1Id === 'string' && liveData.user1Id
            ? liveData.user1Id
            : user1Id,
        createdAt:
          Number.isInteger(liveData.createdAt) && liveData.createdAt > 0
            ? liveData.createdAt
            : createdAt,
        active: true,
      },
      { merge: true }
    );
  });
}

async function applyRegenerate(db, coupleRef, user1Id, createdAt, maxGenerateAttempts) {
  let appliedCode = '';
  await db.runTransaction(async (tx) => {
    const liveCoupleSnap = await tx.get(coupleRef);
    if (!liveCoupleSnap.exists) {
      throw new Error(`couple ${coupleRef.id} no longer exists`);
    }
    const liveData = liveCoupleSnap.data() || {};
    if ((liveData.user2Id || '') !== '') {
      return;
    }

    const newCode = await pickUniqueInviteCode(tx, db, maxGenerateAttempts);
    const inviteRef = db.collection('invite_codes').doc(newCode);
    const ownerId =
      typeof liveData.user1Id === 'string' && liveData.user1Id
        ? liveData.user1Id
        : user1Id;
    const createdAtMs =
      Number.isInteger(liveData.createdAt) && liveData.createdAt > 0
        ? liveData.createdAt
        : createdAt;

    tx.update(coupleRef, { inviteCode: newCode });
    tx.set(inviteRef, {
      coupleId: coupleRef.id,
      createdBy: ownerId,
      createdAt: createdAtMs,
      active: true,
    });
    appliedCode = newCode;
  });
  return appliedCode;
}

async function main() {
  let options;
  try {
    options = parseArgs(process.argv);
  } catch (error) {
    console.error(`Argument error: ${error.message}`);
    process.exit(2);
  }

  if (options.help) {
    printHelp();
    return;
  }

  const projectId = resolveProjectId(options.projectId);
  if (!projectId) {
    console.error(
      'Missing project id. Use --project=<id> or set FIREBASE_PROJECT_ID.'
    );
    process.exit(2);
  }

  initAdmin(projectId);
  const db = admin.firestore();

  console.log(
    `[invite-backfill] project=${projectId} mode=${
      options.dryRun ? 'dry-run' : 'apply'
    }`
  );

  const couples = await listOpenCouples(db, options.batchSize);
  console.log(`[invite-backfill] open couples found: ${couples.length}`);

  const stats = {
    noop: 0,
    create_invite_doc: 0,
    reactivate_invite_doc: 0,
    regenerate_code: 0,
    skip_invalid_owner: 0,
    applied_create_or_reactivate: 0,
    applied_regenerate: 0,
    errors: 0,
  };

  for (const coupleDoc of couples) {
    const coupleId = coupleDoc.id;
    const coupleData = coupleDoc.data() || {};
    const currentInviteCode = normalizeInviteCode(coupleData.inviteCode);
    const inviteSnap = isInviteCodeValid(currentInviteCode)
      ? await db.collection('invite_codes').doc(currentInviteCode).get()
      : null;

    const classification = classifyCouple(
      coupleId,
      coupleData,
      inviteSnap || { exists: false, data: () => null }
    );
    stats[classification.action] += 1;

    const prefix = `[invite-backfill][${coupleId}]`;
    if (classification.action === 'noop') {
      continue;
    }

    if (classification.action === 'skip_invalid_owner') {
      console.warn(`${prefix} skip: ${classification.reason}`);
      continue;
    }

    if (options.dryRun) {
      if (classification.action === 'create_invite_doc') {
        console.log(
          `${prefix} plan: create invite_codes/${classification.code} (${classification.reason})`
        );
      } else if (classification.action === 'reactivate_invite_doc') {
        console.log(
          `${prefix} plan: reactivate invite_codes/${classification.code} (${classification.reason})`
        );
      } else if (classification.action === 'regenerate_code') {
        console.log(
          `${prefix} plan: regenerate inviteCode (${classification.reason})`
        );
      }
      continue;
    }

    try {
      if (
        classification.action === 'create_invite_doc' ||
        classification.action === 'reactivate_invite_doc'
      ) {
        await applyCreateOrReactivate(
          db,
          coupleDoc.ref,
          classification.code,
          classification.user1Id,
          classification.createdAt
        );
        stats.applied_create_or_reactivate += 1;
        console.log(
          `${prefix} applied: invite_codes/${classification.code} active=true`
        );
      } else if (classification.action === 'regenerate_code') {
        const newCode = await applyRegenerate(
          db,
          coupleDoc.ref,
          classification.user1Id,
          classification.createdAt,
          options.maxGenerateAttempts
        );
        stats.applied_regenerate += 1;
        console.log(`${prefix} applied: inviteCode regenerated -> ${newCode}`);
      }
    } catch (error) {
      stats.errors += 1;
      console.error(`${prefix} error: ${error.message}`);
    }
  }

  console.log('[invite-backfill] summary:', JSON.stringify(stats, null, 2));
  if (!options.dryRun && stats.errors > 0) {
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(`[invite-backfill] fatal: ${error.stack || error.message}`);
  process.exit(1);
});
