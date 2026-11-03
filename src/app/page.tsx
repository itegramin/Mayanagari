import Link from "next/link";
import { z } from "zod";
import { GameDashboard } from "@/components/game-dashboard";
import { LanguageToggle } from "@/components/language-toggle";
import { getLocale, getMessages } from "@/lib/i18n";
import {
  activitySchema,
  chatMessageSchema,
  chatReportSchema,
  combatSessionSchema,
  factionMemberSchema,
  factionSchema,
  gameStateSchema,
  listingSchema,
  locationSchema,
  publicCharacterSchema,
  type ChatMessage,
  type ChatReport,
  type FactionMember,
} from "@/lib/game/types";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export default async function HomePage() {
  const locale = await getLocale();
  const messages = getMessages(locale);
  const supabase = await createSupabaseServerClient();
  const { data: authData } = await supabase.auth.getUser();

  if (!authData.user) {
    return (
      <main className="shell">
        <header className="topbar">
          <Link className="brand" href="/">
            <span className="brand-mark">म</span>
            <span className="brand-name">{messages.name}</span>
          </Link>
          <div className="top-actions">
            <LanguageToggle locale={locale} label={messages.language} />
            <Link className="button button-secondary" href="/auth">{messages.signIn}</Link>
          </div>
        </header>
        <section className="hero">
          <div>
            <span className="eyebrow">{locale === "hi" ? "एक मौलिक, काल्पनिक भारत-प्रेरित दुनिया" : "An original India-inspired fictional world"}</span>
            <h1>{messages.tagline}</h1>
            <p className="hero-copy">{messages.cityIntro} {messages.cityLore}</p>
            <div className="hero-actions">
              <Link className="button button-primary" href="/auth?mode=signup">{messages.join}</Link>
              <Link className="button button-secondary" href="/auth">{messages.signIn}</Link>
            </div>
          </div>
          <div className="hero-art" aria-hidden="true">
            <div className="sun" />
            <svg className="city-illustration" viewBox="0 0 480 300" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label={locale === "hi" ? "मायानगरी की काल्पनिक इमारतें" : "Illustration of Mayanagari's fictional neighbourhood buildings"}>
              <path d="M25 260h430" stroke="#285D56" strokeWidth="7" strokeLinecap="round" />
              <path d="M53 260v-94h69v94M62 166v-22h51v22M68 144v-15h39v15" fill="#D9A44C" stroke="#285D56" strokeWidth="4" />
              <path d="M135 260v-131h88v131M146 129v-25h66v25M157 104V80h44v24" fill="#E9C681" stroke="#285D56" strokeWidth="4" />
              <path d="M160 80q19-39 39 0" fill="#C55D30" stroke="#285D56" strokeWidth="4" />
              <path d="M236 260v-87h70v87M245 173v-21h52v21M254 152v-19h34v19" fill="#D68A54" stroke="#285D56" strokeWidth="4" />
              <path d="M320 260v-120h94v120M330 140v-26h74v26M342 114V91h50v23" fill="#C7D9BE" stroke="#285D56" strokeWidth="4" />
              <path d="M346 91q21-41 42 0" fill="#C55D30" stroke="#285D56" strokeWidth="4" />
              <path d="M80 260v-45q17-25 34 0v45M161 260v-55q20-29 40 0v55M347 260v-46q21-27 42 0v46" fill="#F7F3E8" stroke="#285D56" strokeWidth="4" />
              <path d="M27 259h426" stroke="#C55D30" strokeWidth="4" strokeDasharray="3 12" />
              <circle cx="87" cy="197" r="4" fill="#C55D30" /><circle cx="105" cy="197" r="4" fill="#C55D30" />
              <circle cx="170" cy="159" r="4" fill="#C55D30" /><circle cx="193" cy="159" r="4" fill="#C55D30" />
              <circle cx="357" cy="166" r="4" fill="#285D56" /><circle cx="382" cy="166" r="4" fill="#285D56" />
              <path d="M30 90q16-14 32 0m-21 11q12-11 24 0m329-40q13-12 26 0m-18 10q10-9 20 0" stroke="#285D56" strokeWidth="3" strokeLinecap="round" opacity=".55" />
            </svg>
          </div>
        </section>
        <section className="intro-ribbon" aria-label="Game principles">
          <div><strong>{locale === "hi" ? "मोहल्ले की कहानियाँ" : "Neighbourhood stories"}</strong><span>{locale === "hi" ? "कला, काम और रोज़मर्रा के छोटे रोमांच।" : "Art, errands, and small everyday adventures."}</span></div>
          <div><strong>{locale === "hi" ? "साथ मिलकर" : "Made together"}</strong><span>{locale === "hi" ? "मंडली, दोस्ती और खिलाड़ियों का बाज़ार।" : "Guild halls, conversation, and a player-run bazaar."}</span></div>
          <div><strong>{locale === "hi" ? "दो भाषाओं में" : "Two languages"}</strong><span>{locale === "hi" ? "हिन्दी और English, अपनी पसंद से।" : "Play in Hindi or English, and switch any time."}</span></div>
        </section>
        <footer className="footer">
          <div className="footer-row">
            <span>{messages.cityName} · {locale === "hi" ? "कई संस्कृतियों और आवाज़ों को आदर से गढ़ी गई कल्पना" : "Fiction shaped with respect for many cultures and voices"}</span>
            <span>{locale === "hi" ? "भाषा आपकी पसंद, शहर सबका" : "Your language, your pace, a shared city"}</span>
          </div>
        </footer>
      </main>
    );
  }

  const [
    stateResult, profileResult, locationsResult, activitiesResult, factionsResult,
    listingsResult, charactersResult, channelResult,
  ] = await Promise.all([
    supabase.rpc("my_game_state"),
    supabase.from("profiles").select("display_name,is_moderator").eq("id", authData.user.id).single(),
    supabase.from("locations").select("id,name_en,name_hi,description_en,description_hi").order("id"),
    supabase.from("activities").select("id,location_id,name_en,name_hi,description_en,description_hi,energy_cost,nerve_cost,experience_reward,rupee_reward").eq("enabled", true).order("id"),
    supabase.from("factions").select("id,name,name_hi,description,member_limit").order("name").limit(50),
    supabase.from("market_listings").select("id,seller_character_id,item_id,quantity,unit_price").eq("status", "active").gt("expires_at", new Date().toISOString()).order("created_at", { ascending: false }).limit(30),
    supabase.from("characters").select("id,name,level,location_id"),
    supabase.from("chat_channels").select("id").eq("slug", "city-square").single(),
  ]);
  const errors = [stateResult.error, profileResult.error, locationsResult.error, activitiesResult.error, factionsResult.error, listingsResult.error, charactersResult.error, channelResult.error];
  const failedQuery = errors.find((error) => error !== null);
  if (failedQuery) throw new Error(`Unable to load Mayanagari game state: ${failedQuery.message}`);
  if (!profileResult.data || !channelResult.data) {
    throw new Error("The current profile or seeded city chat channel is missing.");
  }

  const state = gameStateSchema.parse(stateResult.data);
  const locations = locationSchema.array().parse(locationsResult.data);
  const activities = activitySchema.array().parse(activitiesResult.data);
  const factions = factionSchema.array().parse(factionsResult.data);
  const listings = listingSchema.array().parse(listingsResult.data);
  const characters = publicCharacterSchema.array().parse(charactersResult.data);
  const chatChannelId = z.string().uuid().parse(channelResult.data.id);
  const { data: rawCombatSessions, error: combatError } = await supabase
    .from("combat_sessions")
    .select("id,attacker_character_id,defender_character_id,winner_character_id,status,expires_at")
    .or(`attacker_character_id.eq.${state.character.id},defender_character_id.eq.${state.character.id}`)
    .in("status", ["pending", "active"])
    .order("created_at", { ascending: false });
  if (combatError) throw new Error(`Unable to load current sparring sessions: ${combatError.message}`);
  const combatSessions = combatSessionSchema.array().parse(rawCombatSessions);
  let factionMembers: FactionMember[] = [];
  if (state.character.faction_id) {
    const { data: rawMembers, error: membersError } = await supabase
      .from("faction_memberships")
      .select("character_id,role")
      .eq("faction_id", state.character.faction_id);
    if (membersError) throw new Error(`Unable to load guild hall members: ${membersError.message}`);
    factionMembers = factionMemberSchema.array().parse(rawMembers);
  }
  const { data: rawMessages, error: chatError } = await supabase
    .from("chat_messages")
    .select("id,character_id,body,created_at")
    .eq("channel_id", chatChannelId)
    .is("deleted_at", null)
    .order("created_at", { ascending: false })
    .limit(30);
  if (chatError) throw new Error(`Unable to load neighbourhood chat: ${chatError.message}`);
  const messagesInChat = chatMessageSchema.array().parse(rawMessages).reverse();
  let moderationReports: ChatReport[] = [];
  let moderationMessages: ChatMessage[] = [];
  if (profileResult.data.is_moderator) {
    const { data: rawReports, error: reportsError } = await supabase
      .from("chat_reports")
      .select("id,message_id,reason,status,created_at")
      .eq("status", "open")
      .order("created_at", { ascending: true })
      .limit(50);
    if (reportsError) throw new Error(`Unable to load moderation reports: ${reportsError.message}`);
    moderationReports = chatReportSchema.array().parse(rawReports);
    const reportMessageIds = moderationReports.map((report) => report.message_id);
    if (reportMessageIds.length > 0) {
      const { data: rawModerationMessages, error: moderationError } = await supabase
        .from("chat_messages")
        .select("id,character_id,body,created_at")
        .in("id", reportMessageIds);
      if (moderationError) throw new Error(`Unable to load reported messages: ${moderationError.message}`);
      moderationMessages = chatMessageSchema.array().parse(rawModerationMessages);
    }
  }
  const { data: allItemDefinitions, error: itemError } = await supabase
    .from("item_definitions")
    .select("id,name_en,name_hi");
  if (itemError) throw new Error(`Unable to load item names: ${itemError.message}`);

  const characterIds = new Set([
    ...characters.map((character) => character.id),
    ...messagesInChat.map((message) => message.character_id),
    ...listings.map((listing) => listing.seller_character_id),
  ]);
  const { data: namedCharacters, error: namesError } = characterIds.size
    ? await supabase.from("characters").select("id,name").in("id", [...characterIds])
    : { data: [], error: null };
  if (namesError) throw new Error(`Unable to load traveller names: ${namesError.message}`);
  const characterNames = Object.fromEntries((namedCharacters ?? []).map((character) => [character.id, character.name]));
  const itemNames = Object.fromEntries(
    (allItemDefinitions ?? []).map((item) => [item.id, locale === "hi" ? item.name_hi : item.name_en]),
  );
  const profileName = profileResult.data.display_name;

  return (
    <main className="shell">
      <GameDashboard
        locale={locale}
        messages={messages}
        userId={authData.user.id}
        displayName={profileName}
        state={state}
        activities={activities}
        locations={locations}
        factions={factions}
        isModerator={profileResult.data.is_moderator}
        moderationReports={moderationReports}
        moderationMessages={moderationMessages}
        listings={listings}
        characters={characters}
        combatSessions={combatSessions}
        factionMembers={factionMembers}
        chatChannelId={chatChannelId}
        messagesInChat={messagesInChat}
        characterNames={characterNames}
        itemNames={itemNames}
      />
    </main>
  );
}
