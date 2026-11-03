"use client";

import { useActionState, useRef, type ReactNode } from "react";
import type { ActionState } from "@/app/actions";
import type { Locale } from "@/lib/i18n";

const translations = {
  en: {
    success: "Done — your story has moved forward.",
    tryAgain: "The action could not be completed. Please try again.",
    commandKey: "This action key was already used. Refresh and retry.",
    authentication: "Please sign in again.",
    character: "Your traveller could not be found.",
    activity: "That activity is not available.",
    location: "Travel to that neighbourhood before starting this activity.",
    resources: "You need more energy or nerve for that action.",
    items: "You do not have enough of that item.",
    funds: "You do not have enough rupees.",
    listing: "That listing is no longer available.",
    ownListing: "You cannot buy your own listing.",
    faction: "You are already part of a guild hall.",
    factionFull: "That guild hall has reached its member limit.",
    factionMissing: "That guild hall could not be found.",
    noFaction: "You are not in a guild hall.",
    leaveFaction: "A guild leader must transfer leadership before leaving.",
    chatLimit: "Please wait a moment before sending another message.",
    chatAccess: "You do not have access to that chat channel.",
    pvpCooldown: "Take a short breather before another challenge.",
    targetBusy: "That traveller is already catching their breath.",
    factionMate: "Friendly guild members cannot challenge each other.",
    defeated: "That traveller needs time to recover.",
    invalid_input: "Check the details and try again.",
    item_not_usable: "That item cannot be used this way.",
    stat_already_full: "That stat is already full.",
    combat_already_in_progress: "There is already a challenge between these travellers.",
    challenge_expired: "That challenge has expired.",
    challenge_not_found: "That challenge could not be found.",
    combat_not_active: "That spar is no longer active.",
    wrong_location: "Both travellers must be in the same neighbourhood.",
    faction_leader_required: "Only the guild leader can transfer leadership.",
    faction_member_not_found: "Choose an active member of your guild hall.",
    moderator_required: "Moderator access is required.",
    message_not_found: "That message is no longer available.",
    invalid_moderation_action: "Choose a valid moderation action.",
  },
  hi: {
    success: "हो गया — आपकी कहानी आगे बढ़ी।",
    tryAgain: "यह काम पूरा नहीं हो सका। कृपया फिर कोशिश करें।",
    commandKey: "इस कोशिश की कुंजी पहले इस्तेमाल हो चुकी है। पन्ना ताज़ा करके फिर करें।",
    authentication: "कृपया दोबारा प्रवेश करें।",
    character: "आपका मुसाफ़िर नहीं मिला।",
    activity: "यह काम अभी उपलब्ध नहीं है।",
    location: "यह काम शुरू करने से पहले उस मोहल्ले में जाएँ।",
    resources: "इसके लिए और ऊर्जा या हौसले की ज़रूरत है।",
    items: "आपके पास यह सामान पर्याप्त नहीं है।",
    funds: "आपके पास पर्याप्त रुपये नहीं हैं।",
    listing: "यह सौदा अब उपलब्ध नहीं है।",
    ownListing: "आप अपना ही सौदा नहीं ख़रीद सकते।",
    faction: "आप पहले से एक मंडली में हैं।",
    factionFull: "इस मंडली में और जगह नहीं है।",
    factionMissing: "यह मंडली नहीं मिली।",
    noFaction: "आप किसी मंडली में नहीं हैं।",
    leaveFaction: "मंडली छोड़ने से पहले नेता को नेतृत्व सौंपना होगा।",
    chatLimit: "दूसरा संदेश भेजने से पहले थोड़ा इंतज़ार करें।",
    chatAccess: "आपको इस बातचीत में शामिल होने की अनुमति नहीं है।",
    pvpCooldown: "अगली चुनौती से पहले थोड़ा दम ले लें।",
    targetBusy: "वह मुसाफ़िर अभी आराम कर रहा है।",
    factionMate: "अपनी मंडली के साथी आपस में चुनौती नहीं देते।",
    defeated: "उस मुसाफ़िर को सँभलने के लिए थोड़ा समय चाहिए।",
    invalid_input: "जानकारी जाँचकर फिर कोशिश करें।",
    item_not_usable: "यह सामान इस तरह इस्तेमाल नहीं हो सकता।",
    stat_already_full: "यह आँकड़ा पहले से पूरा है।",
    combat_already_in_progress: "इन दोनों मुसाफ़िरों के बीच एक चुनौती पहले से है।",
    challenge_expired: "इस चुनौती का समय पूरा हो गया।",
    challenge_not_found: "यह चुनौती नहीं मिली।",
    combat_not_active: "यह मुक़ाबला अब जारी नहीं है।",
    wrong_location: "दोनों मुसाफ़िर एक ही मोहल्ले में होने चाहिए।",
    faction_leader_required: "मंडली का नेतृत्व सिर्फ़ नेता ही सौंप सकता है।",
    faction_member_not_found: "अपनी मंडली का सक्रिय सदस्य चुनें।",
    moderator_required: "इसके लिए संचालक की अनुमति चाहिए।",
    message_not_found: "यह संदेश अब उपलब्ध नहीं है।",
    invalid_moderation_action: "मान्य संचालन विकल्प चुनें।",
  },
} as const;

const errorTranslation: Record<string, keyof (typeof translations)["en"]> = {
  idempotency_key_reused: "commandKey",
  authentication_required: "authentication",
  character_not_found: "character",
  activity_unavailable: "activity",
  insufficient_resources: "resources",
  insufficient_items: "items",
  insufficient_funds: "funds",
  listing_unavailable: "listing",
  cannot_buy_own_listing: "ownListing",
  already_in_faction: "faction",
  faction_full: "factionFull",
  faction_not_found: "factionMissing",
  not_in_faction: "noFaction",
  leader_must_transfer_or_disband: "leaveFaction",
  chat_rate_limited: "chatLimit",
  channel_forbidden: "chatAccess",
  pvp_cooldown: "pvpCooldown",
  target_recently_in_combat: "targetBusy",
  cannot_attack_faction_mate: "factionMate",
  target_defeated: "defeated",
  invalid_input: "invalid_input",
  item_not_usable: "item_not_usable",
  stat_already_full: "stat_already_full",
  combat_already_in_progress: "combat_already_in_progress",
  challenge_expired: "challenge_expired",
  challenge_not_found: "challenge_not_found",
  combat_not_active: "combat_not_active",
  wrong_location: "wrong_location",
  faction_leader_required: "faction_leader_required",
  faction_member_not_found: "faction_member_not_found",
  moderator_required: "moderator_required",
  message_not_found: "message_not_found",
  invalid_moderation_action: "invalid_moderation_action",
};

function localizedActionMessage(locale: Locale, state: ActionState) {
  if (!state) return "";
  if (state.ok) return translations[locale].success;
  const key = errorTranslation[state.message];
  return key ? translations[locale][key] : translations[locale].tryAgain;
}

type Props = {
  action: (previousState: ActionState, formData: FormData) => Promise<ActionState>;
  locale: Locale;
  children?: ReactNode;
  className?: string;
  submitLabel: string;
  needsCommandKey?: boolean;
};

export function CommandForm({
  action,
  locale,
  children,
  className,
  submitLabel,
  needsCommandKey = false,
}: Props) {
  const [state, formAction, pending] = useActionState(action, null);
  const commandKey = useRef<HTMLInputElement>(null);

  function prepareCommand() {
    if (needsCommandKey && commandKey.current) {
      commandKey.current.value = crypto.randomUUID();
    }
  }

  return (
    <form action={formAction} onSubmit={prepareCommand} className={className}>
      {needsCommandKey && <input type="hidden" name="command_key" ref={commandKey} />}
      {children}
      <button className="button button-primary" type="submit" disabled={pending}>
        {pending ? (locale === "hi" ? "रुकिए..." : "Working...") : submitLabel}
      </button>
      {state && (
        <p className={state.ok ? "form-result form-success" : "form-result form-error"} role="status">
          {localizedActionMessage(locale, state)}
        </p>
      )}
    </form>
  );
}
