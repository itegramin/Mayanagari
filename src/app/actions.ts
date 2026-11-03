"use server";

import { revalidatePath } from "next/cache";
import { z } from "zod";
import { createSupabaseActionClient } from "@/lib/supabase/action-client";

export type ActionState = {
  ok: boolean;
  message: string;
} | null;

const commandKeySchema = z.string().uuid();
const unicodeName = /^[\p{L}\p{M}\d][\p{L}\p{M}\d _'’-]*$/u;

function field(formData: FormData, key: string) {
  const value = formData.get(key);
  return typeof value === "string" ? value.trim() : "";
}

function domainError(message: string) {
  const code = message.match(/^[a-z_]+/)?.[0] ?? "request_failed";
  return code;
}

async function rpcAction(
  name: string,
  args: Record<string, string | number | boolean | null>,
): Promise<ActionState> {
  const supabase = await createSupabaseActionClient();
  const { error } = await supabase.rpc(name, args);
  if (error) return { ok: false, message: domainError(error.message) };
  revalidatePath("/");
  return { ok: true, message: "Done — your story has moved forward." };
}

export async function activityAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    activity: z.string().min(1).max(64),
    key: commandKeySchema,
  }).safeParse({ activity: field(formData, "activity_id"), key: field(formData, "command_key") });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("perform_activity", {
    p_activity_id: input.data.activity,
    p_command_key: input.data.key,
  });
}

export async function useItemAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    item: z.string().min(1).max(64),
    key: commandKeySchema,
  }).safeParse({ item: field(formData, "item_id"), key: field(formData, "command_key") });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("use_item", {
    p_item_id: input.data.item,
    p_command_key: input.data.key,
  });
}

export async function moveAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    location: z.string().min(1).max(64),
    key: commandKeySchema,
  }).safeParse({ location: field(formData, "location_id"), key: field(formData, "command_key") });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("move_character", {
    p_location_id: input.data.location,
    p_command_key: input.data.key,
  });
}

export async function createFactionAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    name: z.string().min(3).max(32).regex(unicodeName),
    nameHi: z.string().min(2).max(40),
    description: z.string().max(500),
    key: commandKeySchema,
  }).safeParse({
    name: field(formData, "name"),
    nameHi: field(formData, "name_hi"),
    description: field(formData, "description"),
    key: field(formData, "command_key"),
  });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("create_faction", {
    p_name: input.data.name,
    p_name_hi: input.data.nameHi,
    p_description: input.data.description,
    p_command_key: input.data.key,
  });
}

export async function joinFactionAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const factionId = z.string().uuid().safeParse(field(formData, "faction_id"));
  if (!factionId.success) return { ok: false, message: "invalid_input" };
  return rpcAction("join_faction", { p_faction_id: factionId.data });
}

export async function leaveFactionAction(_previous: ActionState, _formData: FormData): Promise<ActionState> {
  void _previous;
  void _formData;
  return rpcAction("leave_faction", {});
}

export async function transferFactionLeadershipAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const memberId = z.string().uuid().safeParse(field(formData, "target_character_id"));
  if (!memberId.success) return { ok: false, message: "invalid_input" };
  return rpcAction("transfer_faction_leadership", {
    p_target_character_id: memberId.data,
  });
}

export async function chatAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    channel: z.string().uuid(),
    body: z.string().trim().min(1).max(500),
  }).safeParse({ channel: field(formData, "channel_id"), body: field(formData, "body") });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("send_chat_message", {
    p_channel_id: input.data.channel,
    p_body: input.data.body,
  });
}

export async function reportChatAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    id: z.coerce.number().int().positive(),
    reason: z.string().trim().min(3).max(300),
  }).safeParse({ id: field(formData, "message_id"), reason: field(formData, "reason") });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("report_chat_message", {
    p_message_id: input.data.id,
    p_reason: input.data.reason,
  });
}

export async function moderateChatAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    id: z.coerce.number().int().positive(),
    action: z.enum(["delete", "restore"]),
  }).safeParse({
    id: field(formData, "message_id"),
    action: field(formData, "moderation_action"),
  });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("moderate_chat_message", {
    p_message_id: input.data.id,
    p_action: input.data.action,
  });
}

export async function listItemAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    item: z.string().min(1).max(64),
    quantity: z.coerce.number().int().positive().max(999),
    price: z.coerce.number().int().positive().max(1_000_000_000),
    key: commandKeySchema,
  }).safeParse({
    item: field(formData, "item_id"),
    quantity: field(formData, "quantity"),
    price: field(formData, "unit_price"),
    key: field(formData, "command_key"),
  });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("create_market_listing", {
    p_item_id: input.data.item,
    p_quantity: input.data.quantity,
    p_unit_price: input.data.price,
    p_command_key: input.data.key,
  });
}

export async function cancelListingAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const id = z.string().uuid().safeParse(field(formData, "listing_id"));
  if (!id.success) return { ok: false, message: "invalid_input" };
  return rpcAction("cancel_market_listing", { p_listing_id: id.data });
}

export async function purchaseListingAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    id: z.string().uuid(),
    key: commandKeySchema,
  }).safeParse({ id: field(formData, "listing_id"), key: field(formData, "command_key") });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("purchase_market_listing", {
    p_listing_id: input.data.id,
    p_command_key: input.data.key,
  });
}

export async function pvpAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    target: z.string().uuid(),
    session: z.string().uuid(),
    key: commandKeySchema,
  }).safeParse({
    target: field(formData, "target_character_id"),
    session: field(formData, "session_id"),
    key: field(formData, "command_key"),
  });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("pvp_attack", {
    p_target_character_id: input.data.target,
    p_session_id: input.data.session,
    p_command_key: input.data.key,
  });
}

export async function requestPvpChallengeAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    target: z.string().uuid(),
    key: commandKeySchema,
  }).safeParse({
    target: field(formData, "target_character_id"),
    key: field(formData, "command_key"),
  });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("request_pvp_challenge", {
    p_target_character_id: input.data.target,
    p_command_key: input.data.key,
  });
}

export async function respondPvpChallengeAction(_previous: ActionState, formData: FormData): Promise<ActionState> {
  const input = z.object({
    session: z.string().uuid(),
    accept: z.enum(["true", "false"]),
  }).safeParse({
    session: field(formData, "session_id"),
    accept: field(formData, "accept"),
  });
  if (!input.success) return { ok: false, message: "invalid_input" };
  return rpcAction("respond_pvp_challenge", {
    p_session_id: input.data.session,
    p_accept: input.data.accept === "true",
  });
}
