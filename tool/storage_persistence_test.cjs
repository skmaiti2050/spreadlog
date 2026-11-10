const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { runInNewContext } = require('node:vm');

const html = readFileSync(require('node:path').join(__dirname, '../web/index.html'), 'utf8');
const script = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)]
  .map(match => match[1]).find(text => text.includes('navigator.storage'));

test('requests persistence once when not already granted', async () => {
  let calls = 0;
  await runInNewContext(script, { navigator: { storage: {
    persisted: async () => false, persist: async () => { calls++; return true; },
  } }, console });
  assert.equal(calls, 1);
});

test('does not request again when already persistent', async () => {
  let calls = 0;
  await runInNewContext(script, { navigator: { storage: {
    persisted: async () => true, persist: async () => { calls++; },
  } }, console });
  assert.equal(calls, 0);
});

test('unsupported storage, refusal and errors do not block startup', async () => {
  const quiet = { debug() {} };
  for (const navigator of [{}, { storage: {
    persisted: async () => false, persist: async () => false,
  } }, { storage: {
    persisted: async () => false, persist: async () => { throw new Error('Denied'); },
  } }]) {
    await assert.doesNotReject(runInNewContext(script, { navigator, console: quiet }));
  }
});
