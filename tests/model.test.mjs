import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const sql = readFileSync(new URL('../supabase/migrations/0001_initial_schema.sql', import.meta.url), 'utf8');

test('session and assignment states remain separate', () => {
  assert.match(sql, /create type public\.session_state as enum \('draft','published','archived'\)/);
  assert.match(sql, /create type public\.assignment_state as enum \('planned','active','athlete_done','coach_verified'\)/);
});

test('private notes have an owner-only policy and public feedback is separate', () => {
  assert.match(sql, /create table public\.private_coach_notes/);
  assert.match(sql, /create table public\.session_feedback/);
  assert.match(sql, /private_note_owner_only/);
});

test('public audiences only read published sessions and approved reports', () => {
  assert.match(sql, /status='published'/);
  assert.match(sql, /state='approved'/);
});

test('active athlete access requires no revocation timestamp', () => {
  assert.match(sql, /aa\.revoked_at is null/);
});
