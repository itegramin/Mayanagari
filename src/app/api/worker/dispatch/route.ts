import { timingSafeEqual } from "node:crypto";
import { NextResponse, type NextRequest } from "next/server";
import { getWorkerSecret } from "@/lib/env";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
export const maxDuration = 60;

async function dispatch(request: NextRequest) {
  const expected = `Bearer ${getWorkerSecret()}`;
  const provided = request.headers.get("authorization") ?? "";
  const expectedBytes = Buffer.from(expected);
  const providedBytes = Buffer.from(provided);
  if (expectedBytes.length !== providedBytes.length || !timingSafeEqual(expectedBytes, providedBytes)) {
    return NextResponse.json({ error: "unauthorized" }, { status: 401 });
  }

  const supabase = createSupabaseAdminClient();
  const { data: expiredCount, error: expirationError } = await supabase.rpc("expire_market_listings", { p_limit: 100 });
  if (expirationError) {
    console.error("market listing expiry failed", { message: expirationError.message });
    return NextResponse.json({ error: "market_expiry_failed" }, { status: 500 });
  }
  const { data: expiredChallenges, error: challengeExpiryError } = await supabase.rpc("expire_pvp_challenges", { p_limit: 100 });
  if (challengeExpiryError) {
    console.error("challenge expiry failed", { message: challengeExpiryError.message });
    return NextResponse.json({ error: "challenge_expiry_failed" }, { status: 500 });
  }

  const { data: jobs, error: jobClaimError } = await supabase.rpc("claim_due_jobs", { p_limit: 50 });
  if (jobClaimError) {
    console.error("game job claim failed", { message: jobClaimError.message });
    return NextResponse.json({ error: "job_claim_failed" }, { status: 500 });
  }

  let completedJobs = 0;
  let failedJobs = 0;
  for (const job of jobs ?? []) {
    let jobError: string | null = null;
    if (job.kind === "market_expiry" || job.kind === "outbox_dispatch") {
      if (job.kind === "market_expiry") {
        const { error } = await supabase.rpc("expire_market_listings", { p_limit: 100 });
        if (error) jobError = error.message;
      }
    } else {
      jobError = `unsupported_job_kind:${job.kind}`;
    }

    if (jobError) {
      const { error } = await supabase.rpc("fail_game_job", { p_job_id: job.id, p_error: jobError });
      if (error) console.error("game job retry state update failed", { jobId: job.id, message: error.message });
      failedJobs += 1;
      continue;
    }

    const { error } = await supabase.rpc("complete_game_job", { p_job_id: job.id });
    if (error) {
      console.error("game job completion failed", { jobId: job.id, message: error.message });
      return NextResponse.json({ error: "job_completion_failed" }, { status: 500 });
    }
    completedJobs += 1;
  }

  const { data: events, error: claimError } = await supabase.rpc("claim_outbox_events", { p_limit: 25 });
  if (claimError) {
    console.error("outbox claim failed", { message: claimError.message });
    return NextResponse.json({ error: "outbox_claim_failed" }, { status: 500 });
  }

  let delivered = 0;
  let failed = 0;
  for (const event of events ?? []) {
    const channel = supabase.channel(`user:${event.owner_id}`, { config: { private: true } });
    const sendResult = await channel.send({
      type: "broadcast",
      event: event.topic,
      payload: { event_id: event.id, data: event.payload },
    });
    await supabase.removeChannel(channel);

    if (sendResult !== "ok") {
      const { error } = await supabase.rpc("fail_outbox_event", {
        p_event_id: event.id,
        p_error: sendResult,
      });
      if (error) console.error("outbox retry state update failed", { eventId: event.id, message: error.message });
      failed += 1;
      continue;
    }

    const { error: completionError } = await supabase.rpc("complete_outbox_event", { p_event_id: event.id });
    if (completionError) {
      console.error("outbox completion failed", { eventId: event.id, message: completionError.message });
      return NextResponse.json({ error: "outbox_completion_failed" }, { status: 500 });
    }
    delivered += 1;
  }

  return NextResponse.json({
    expiredListings: expiredCount ?? 0,
    expiredChallenges: expiredChallenges ?? 0,
    completedJobs,
    failedJobs,
    deliveredEvents: delivered,
    failedEvents: failed,
  });
}

export async function GET(request: NextRequest) {
  return dispatch(request);
}

export async function POST(request: NextRequest) {
  return dispatch(request);
}
