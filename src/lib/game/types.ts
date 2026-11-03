import { z } from "zod";

export const gameStateSchema = z.object({
  character: z.object({
    id: z.string().uuid(),
    name: z.string(),
    level: z.number(),
    experience: z.number(),
    location_id: z.string(),
    faction_id: z.string().uuid().nullable(),
    version: z.number(),
  }),
  stats: z.object({
    energy: z.number(),
    energy_capacity: z.number(),
    nerve: z.number(),
    nerve_capacity: z.number(),
    health: z.number(),
    health_capacity: z.number(),
    version: z.number(),
  }),
  wallet: z.object({ balance: z.number() }),
  location: z.object({
    id: z.string(),
    name_en: z.string(),
    name_hi: z.string(),
    description_en: z.string(),
    description_hi: z.string(),
  }),
  inventory: z.array(z.object({
    item_id: z.string(),
    quantity: z.number(),
    name_en: z.string(),
    name_hi: z.string(),
    description_en: z.string(),
    description_hi: z.string(),
  })),
  faction: z.object({
    id: z.string().uuid(),
    name: z.string(),
    name_hi: z.string(),
  }).nullable(),
});

export type GameState = z.infer<typeof gameStateSchema>;

export const locationSchema = z.object({
  id: z.string(),
  name_en: z.string(),
  name_hi: z.string(),
  description_en: z.string(),
  description_hi: z.string(),
});
export type Location = z.infer<typeof locationSchema>;

export const activitySchema = z.object({
  id: z.string(),
  location_id: z.string(),
  name_en: z.string(),
  name_hi: z.string(),
  description_en: z.string(),
  description_hi: z.string(),
  energy_cost: z.number(),
  nerve_cost: z.number(),
  experience_reward: z.number(),
  rupee_reward: z.number(),
});
export type Activity = z.infer<typeof activitySchema>;

export const factionSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  name_hi: z.string(),
  description: z.string(),
  member_limit: z.number(),
});
export type Faction = z.infer<typeof factionSchema>;

export const factionMemberSchema = z.object({
  character_id: z.string().uuid(),
  role: z.enum(["leader", "officer", "member"]),
});
export type FactionMember = z.infer<typeof factionMemberSchema>;

export const listingSchema = z.object({
  id: z.string().uuid(),
  seller_character_id: z.string().uuid(),
  item_id: z.string(),
  quantity: z.number(),
  unit_price: z.number(),
});
export type Listing = z.infer<typeof listingSchema>;

export const publicCharacterSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  level: z.number(),
  location_id: z.string(),
});
export type PublicCharacter = z.infer<typeof publicCharacterSchema>;

export const chatMessageSchema = z.object({
  id: z.number(),
  character_id: z.string().uuid(),
  body: z.string(),
  created_at: z.string(),
});
export type ChatMessage = z.infer<typeof chatMessageSchema>;

export const chatReportSchema = z.object({
  id: z.number(),
  message_id: z.number(),
  reason: z.string(),
  status: z.enum(["open", "reviewed", "actioned", "dismissed"]),
  created_at: z.string(),
});
export type ChatReport = z.infer<typeof chatReportSchema>;

export const combatSessionSchema = z.object({
  id: z.string().uuid(),
  attacker_character_id: z.string().uuid(),
  defender_character_id: z.string().uuid(),
  winner_character_id: z.string().uuid().nullable(),
  status: z.enum(["pending", "active", "finished", "declined", "expired"]),
  expires_at: z.string(),
});
export type CombatSession = z.infer<typeof combatSessionSchema>;
