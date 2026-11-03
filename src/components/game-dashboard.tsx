import Link from "next/link";
import {
  activityAction,
  cancelListingAction,
  chatAction,
  createFactionAction,
  joinFactionAction,
  leaveFactionAction,
  listItemAction,
  moderateChatAction,
  moveAction,
  purchaseListingAction,
  pvpAction,
  reportChatAction,
  requestPvpChallengeAction,
  respondPvpChallengeAction,
  transferFactionLeadershipAction,
  useItemAction,
} from "@/app/actions";
import { signOutAction } from "@/app/auth/actions";
import { ChatLiveRefresh } from "@/components/chat-live-refresh";
import { CommandForm } from "@/components/command-form";
import { LanguageToggle } from "@/components/language-toggle";
import { UserNotifications } from "@/components/user-notifications";
import type { Locale, Messages } from "@/lib/i18n";
import { localizedText } from "@/lib/i18n";
import type {
  Activity,
  ChatMessage,
  ChatReport,
  CombatSession,
  Faction,
  FactionMember,
  GameState,
  Listing,
  Location,
  PublicCharacter,
} from "@/lib/game/types";

type Props = {
  locale: Locale;
  messages: Messages;
  userId: string;
  displayName: string;
  state: GameState;
  activities: Activity[];
  locations: Location[];
  factions: Faction[];
  isModerator: boolean;
  moderationReports: ChatReport[];
  moderationMessages: ChatMessage[];
  listings: Listing[];
  characters: PublicCharacter[];
  combatSessions: CombatSession[];
  factionMembers: FactionMember[];
  chatChannelId: string;
  messagesInChat: ChatMessage[];
  characterNames: Record<string, string>;
  itemNames: Record<string, string>;
};

function formatNumber(value: number, locale: Locale) {
  return new Intl.NumberFormat(locale === "hi" ? "hi-IN" : "en-IN").format(value);
}

function StatBar({
  label,
  value,
  capacity,
  kind,
}: {
  label: string;
  value: number;
  capacity: number;
  kind: string;
}) {
  const percent = capacity > 0 ? Math.min(100, Math.round((value / capacity) * 100)) : 0;
  return (
    <div className="stat">
      <div className="stat-head"><span>{label}</span><span>{value} / {capacity}</span></div>
      <div className="progress-track" role="progressbar" aria-valuenow={value} aria-valuemin={0} aria-valuemax={capacity} aria-label={label}>
        <div className={`progress-fill ${kind}`} style={{ width: `${percent}%` }} />
      </div>
    </div>
  );
}

export function GameDashboard(props: Props) {
  const {
    locale, messages, state, activities, locations, factions, listings,
    characters, combatSessions, factionMembers, chatChannelId, messagesInChat, characterNames, itemNames,
    moderationReports, moderationMessages,
  } = props;
  const currentLocationName = localizedText(locale, state.location, "name");
  const currentLocationDescription = localizedText(locale, state.location, "description");
  const currentFactions = factions.filter((faction) => faction.id === state.character.faction_id);
  const availableActivities = activities.filter((activity) => activity.location_id === state.character.location_id);
  const otherCharacters = characters.filter((character) => character.id !== state.character.id);
  const availableFactions = factions.filter((faction) => faction.id !== state.character.faction_id);

  return (
    <>
      <UserNotifications userId={props.userId} />
      <header className="topbar">
        <Link className="brand" href="/" aria-label={messages.name}>
          <span className="brand-mark">म</span>
          <span className="brand-name">{messages.name}</span>
        </Link>
        <div className="top-actions">
          <LanguageToggle locale={locale} label={messages.language} />
          <details className="profile-menu">
            <summary className="profile-trigger" aria-label={locale === "hi" ? "मुसाफ़िर का मेनू" : "Traveller profile menu"}>
              <span className="profile-avatar" aria-hidden="true">{props.displayName.trim().slice(0, 1).toLocaleUpperCase(locale === "hi" ? "hi-IN" : "en-IN")}</span>
              <span className="profile-trigger-name">{props.displayName}</span>
              <span className="profile-chevron" aria-hidden="true">⌄</span>
            </summary>
            <div className="profile-dropdown">
              <div className="profile-summary">
                <strong>{props.displayName}</strong>
                <span>{state.character.name} · {messages.level} {formatNumber(state.character.level, locale)}</span>
                <span>{currentLocationName}</span>
              </div>
              <a className="profile-link" href="#traveller">{locale === "hi" ? "मुसाफ़िर का परिचय" : "View traveller profile"}</a>
              <form action={signOutAction}>
                <button className="profile-sign-out" type="submit">{messages.signOut}</button>
              </form>
            </div>
          </details>
        </div>
      </header>

      <div className="dashboard-grid">
        <aside className="dashboard-sidebar">
          <section className="card sidebar-status" aria-label={locale === "hi" ? "मुसाफ़िर के आँकड़े" : "Traveller stats"}>
            <div className="eyebrow">{messages.character}</div>
            <h2>{state.character.name}</h2>
            <div className="sidebar-stats">
              <StatBar label={messages.energy} value={state.stats.energy} capacity={state.stats.energy_capacity} kind="energy" />
              <StatBar label={messages.nerve} value={state.stats.nerve} capacity={state.stats.nerve_capacity} kind="nerve" />
              <StatBar label={messages.health} value={state.stats.health} capacity={state.stats.health_capacity} kind="health" />
            </div>
            <dl className="sidebar-wallet">
              <div><dt>{messages.level}</dt><dd>{formatNumber(state.character.level, locale)}</dd></div>
              <div><dt>{messages.experience}</dt><dd>{formatNumber(state.character.experience, locale)}</dd></div>
              <div><dt>{messages.rupees}</dt><dd>{messages.rupeeSymbol}{formatNumber(state.wallet.balance, locale)}</dd></div>
            </dl>
          </section>

          <nav className="game-nav" aria-label={locale === "hi" ? "खेल के हिस्से" : "Game sections"}>
            <span className="sidebar-heading">{locale === "hi" ? "शहर में जाएँ" : "Explore the city"}</span>
            <a href="#traveller"><span aria-hidden="true">◉</span>{messages.character}</a>
            <a href="#neighbourhoods"><span aria-hidden="true">⌖</span>{messages.map}</a>
            <a href="#activities"><span aria-hidden="true">✦</span>{messages.activities}</a>
            <a href="#inventory"><span aria-hidden="true">▣</span>{messages.inventory}</a>
            <a href="#guilds"><span aria-hidden="true">⌂</span>{messages.factions}</a>
            <a href="#bazaar"><span aria-hidden="true">₹</span>{messages.market}</a>
            <a href="#square"><span aria-hidden="true">◌</span>{messages.chat}</a>
            <a href="#challenge"><span aria-hidden="true">⚔</span>{messages.pvp}</a>
            {props.isModerator && <a href="#moderation"><span aria-hidden="true">◇</span>{locale === "hi" ? "संचालन" : "Moderation"}</a>}
          </nav>
        </aside>


        <div className="main-column">
          <section className="dashboard-hero">
            <span className="eyebrow">{messages.location} · {currentLocationName}</span>
            <h1>{messages.welcome}, {props.displayName}</h1>
            <p>{messages.cityLore}</p>
          </section>
          <section className="card" id="traveller">
            <div className="overview-heading">
              <div>
                <div className="eyebrow">{locale === "hi" ? "यात्री की जानकारी" : "Traveller overview"}</div>
                <h2>{state.character.name}</h2>
              </div>
              <span className="overview-level">{messages.level} {formatNumber(state.character.level, locale)}</span>
            </div>
            <p className="card-intro">{currentLocationDescription}</p>
            <dl className="overview-table">
              <div><dt>{locale === "hi" ? "नाम" : "Name"}</dt><dd>{state.character.name}</dd></div>
              <div><dt>{messages.location}</dt><dd>{currentLocationName}</dd></div>
              <div><dt>{messages.rupees}</dt><dd>{messages.rupeeSymbol}{formatNumber(state.wallet.balance, locale)}</dd></div>
              <div><dt>{messages.experience}</dt><dd>{formatNumber(state.character.experience, locale)}</dd></div>
              <div>
                <dt>{messages.factions}</dt>
                <dd>{currentFactions.length > 0
                  ? (locale === "hi" ? currentFactions[0].name_hi : currentFactions[0].name)
                  : (locale === "hi" ? "अभी किसी मंडली में नहीं" : "Not in a guild hall yet")}</dd>
              </div>
            </dl>
          </section>

          <section className="card" id="neighbourhoods">
            <div className="eyebrow">{messages.map}</div>
            <h2>{messages.city}</h2>
            <p className="card-intro">{messages.cityIntro}</p>
            <div className="list-grid">
              {locations.map((location) => (
                <article className="list-card" key={location.id}>
                  <h3>{localizedText(locale, location, "name")}</h3>
                  <p>{localizedText(locale, location, "description")}</p>
                  {location.id !== state.character.location_id && (
                    <CommandForm action={moveAction} locale={locale} submitLabel={messages.move} needsCommandKey>
                      <input type="hidden" name="location_id" value={location.id} />
                    </CommandForm>
                  )}
                  {location.id === state.character.location_id && <span className="meta">{locale === "hi" ? "आप यहाँ हैं" : "You are here"}</span>}
                </article>
              ))}
            </div>
          </section>

          <section className="card" id="activities">
            <div className="eyebrow">{messages.activities}</div>
            <h2>{locale === "hi" ? "मोहल्ले की रौनक़" : "A day in the neighbourhood"}</h2>
            <p className="card-intro">{locale === "hi" ? "छोटे काम, नई पहचान और लोगों से मिलने के मौके।" : "Small errands, new skills, and chances to meet your neighbours."}</p>
            {availableActivities.length === 0 ? <p className="empty">{messages.noActivities}</p> : (
              <div className="list-grid">
                {availableActivities.map((activity) => (
                  <article className="list-card" key={activity.id}>
                    <h3>{localizedText(locale, activity, "name")}</h3>
                    <p>{localizedText(locale, activity, "description")}</p>
                    <div className="meta">
                      <span>{messages.energy} −{activity.energy_cost}</span>
                      {activity.nerve_cost > 0 && <span>{messages.nerve} −{activity.nerve_cost}</span>}
                      <span>+{activity.experience_reward} {messages.experience.toLowerCase()}</span>
                      <span>+{messages.rupeeSymbol}{activity.rupee_reward}</span>
                    </div>
                    <CommandForm action={activityAction} locale={locale} submitLabel={messages.act} needsCommandKey>
                      <input type="hidden" name="activity_id" value={activity.id} />
                    </CommandForm>
                  </article>
                ))}
              </div>
            )}
          </section>

          <section className="card" id="square">
            <div className="eyebrow">{messages.chat}</div>
            <h2>{messages.channelName}</h2>
            <p className="card-intro">{locale === "hi" ? "मोहल्ले की बातें साझा करें। सम्मानजनक भाषा रखें; संदेशों की शिकायत की जा सकती है।" : "Share a neighbourhood note. Keep it kind; messages can be reported to moderators."}</p>
            <ChatLiveRefresh channelId={chatChannelId} />
            <div className="chat-list" aria-live="polite">
              {messagesInChat.length === 0 && <p className="empty">{locale === "hi" ? "चौक पर अभी ख़ामोशी है। पहली बात आप कहें।" : "The square is quiet for now. Start the conversation."}</p>}
              {messagesInChat.map((message) => (
                <article className="chat-bubble" key={message.id}>
                  <header>
                    <strong>{characterNames[message.character_id] ?? (locale === "hi" ? "मुसाफ़िर" : "Traveller")}</strong>
                    <time dateTime={message.created_at}>
                      {new Intl.DateTimeFormat(locale === "hi" ? "hi-IN" : "en-IN", {
                        hour: "2-digit", minute: "2-digit", timeZone: "Asia/Kolkata",
                      }).format(new Date(message.created_at))}
                    </time>
                  </header>
                  <p>{message.body}</p>
                  {message.character_id !== state.character.id && (
                    <details className="report-details">
                      <summary>{messages.report}</summary>
                      <CommandForm action={reportChatAction} locale={locale} submitLabel={messages.report}>
                        <input type="hidden" name="message_id" value={message.id} />
                        <label className="field">
                          {locale === "hi" ? "कारण" : "Reason"}
                          <input name="reason" minLength={3} maxLength={300} required />
                        </label>
                      </CommandForm>
                    </details>
                  )}
                </article>
              ))}
            </div>
            <CommandForm action={chatAction} locale={locale} submitLabel={messages.send} className="chat-form">
              <input type="hidden" name="channel_id" value={chatChannelId} />
              <label className="sr-only" htmlFor="chat-body">{messages.chat}</label>
              <textarea className="chat-input" id="chat-body" name="body" maxLength={500} required placeholder={locale === "hi" ? "अपनी बात लिखें..." : "Write a neighbourly note..."} />
            </CommandForm>
          </section>

          {props.isModerator && (
            <section className="card" id="moderation">
              <div className="eyebrow">{locale === "hi" ? "संचालन" : "Moderation"}</div>
              <h2>{locale === "hi" ? "समीक्षा की प्रतीक्षा" : "Open chat reports"}</h2>
              {moderationReports.length === 0 && (
                <p className="empty">{locale === "hi" ? "अभी कोई शिकायत लंबित नहीं है।" : "No reports are waiting for review."}</p>
              )}
              {moderationReports.map((report) => {
                const reportedMessage = moderationMessages.find((message) => message.id === report.message_id);
                return (
                  <article className="list-card" key={report.id}>
                    <p><strong>{locale === "hi" ? "संदेश" : "Message"}:</strong> {reportedMessage?.body ?? (locale === "hi" ? "संदेश हटाया जा चुका है।" : "Message is no longer available.")}</p>
                    <p><strong>{locale === "hi" ? "कारण" : "Reason"}:</strong> {report.reason}</p>
                    <CommandForm action={moderateChatAction} locale={locale} submitLabel={locale === "hi" ? "संदेश हटाएँ" : "Remove message"}>
                      <input type="hidden" name="message_id" value={report.message_id} />
                      <input type="hidden" name="moderation_action" value="delete" />
                    </CommandForm>
                  </article>
                );
              })}
            </section>
          )}
        </div>

        <aside className="side-column">
          <section className="card neighbourhood-card" id="current-location">
            <div className="eyebrow">{locale === "hi" ? "आपका मोहल्ला" : "Your neighbourhood"}</div>
            <h2>{currentLocationName}</h2>
            <div className="neighbourhood-art" aria-hidden="true">
              <svg viewBox="0 0 480 190" fill="none" xmlns="http://www.w3.org/2000/svg" role="img" aria-label={locale === "hi" ? "मायानगरी के मोहल्ले का दृश्य" : "Illustration of a Mayanagari neighbourhood"}>
                <circle cx="370" cy="47" r="28" fill="#E8BB64" />
                <path d="M0 151C73 125 111 143 174 130C247 115 320 147 480 114V190H0V151Z" fill="#B8D3B6" />
                <path d="M39 152V82H116V152M49 82V64H106V82M59 64Q78 33 97 64" fill="#E9C681" stroke="#285D56" strokeWidth="4" />
                <path d="M139 151V55H233V151M150 55V37H221V55M164 37Q186 2 207 37" fill="#D68A54" stroke="#285D56" strokeWidth="4" />
                <path d="M252 151V91H319V151M261 91V75H310V91M272 75Q285 53 299 75" fill="#C7D9BE" stroke="#285D56" strokeWidth="4" />
                <path d="M337 151V70H442V151M348 70V50H431V70M366 50Q389 19 413 50" fill="#E9C681" stroke="#285D56" strokeWidth="4" />
                <path d="M0 153H480" stroke="#285D56" strokeWidth="5" strokeLinecap="round" />
                <path d="M15 174C94 160 161 182 245 167C324 153 393 175 470 158" stroke="#C55D30" strokeWidth="4" strokeDasharray="3 12" strokeLinecap="round" />
                <circle cx="72" cy="108" r="4" fill="#C55D30" /><circle cx="91" cy="108" r="4" fill="#C55D30" />
                <circle cx="176" cy="83" r="4" fill="#285D56" /><circle cx="201" cy="83" r="4" fill="#285D56" />
                <circle cx="377" cy="97" r="4" fill="#C55D30" /><circle cx="402" cy="97" r="4" fill="#C55D30" />
              </svg>
            </div>
            <p className="card-intro">{currentLocationDescription}</p>
            <a className="text-link" href="#neighbourhoods">{locale === "hi" ? "शहर के मोहल्ले देखें" : "Explore neighbourhoods"} <span aria-hidden="true">→</span></a>
          </section>

          <section className="card latest-messages">
            <div className="widget-heading">
              <div>
                <div className="eyebrow">{messages.chat}</div>
                <h2>{locale === "hi" ? "चौक की ताज़ा बातें" : "Latest from the square"}</h2>
              </div>
              <a className="widget-more" href="#square" aria-label={locale === "hi" ? "सारी बातचीत देखें" : "View all conversations"}>→</a>
            </div>
            {messagesInChat.length === 0
              ? <p className="empty">{locale === "hi" ? "चौक पर अभी ख़ामोशी है।" : "The square is quiet for now."}</p>
              : messagesInChat.slice(-3).reverse().map((message) => (
                <article className="message-preview" key={message.id}>
                  <div className="message-preview-meta">
                    <strong>{characterNames[message.character_id] ?? (locale === "hi" ? "मुसाफ़िर" : "Traveller")}</strong>
                    <time dateTime={message.created_at}>
                      {new Intl.DateTimeFormat(locale === "hi" ? "hi-IN" : "en-IN", {
                        hour: "2-digit", minute: "2-digit", timeZone: "Asia/Kolkata",
                      }).format(new Date(message.created_at))}
                    </time>
                  </div>
                  <p>{message.body}</p>
                </article>
              ))}
          </section>

          <section className="card" id="inventory">
            <div className="eyebrow">{messages.inventory}</div>
            <h2>{messages.inventory}</h2>
            {state.inventory.length === 0 && <p className="empty">{messages.itemsEmpty}</p>}
            {state.inventory.map((item) => (
              <div className="inventory-row" key={item.item_id}>
                <div className="row-copy">
                  <strong>{localizedText(locale, item, "name")} ×{item.quantity}</strong>
                  <span>{localizedText(locale, item, "description")}</span>
                </div>
                {item.item_id === "cutting-chai" && (
                  <CommandForm action={useItemAction} locale={locale} submitLabel={locale === "hi" ? "पीएँ" : "Drink"} needsCommandKey>
                    <input type="hidden" name="item_id" value={item.item_id} />
                  </CommandForm>
                )}
              </div>
            ))}
            <div className="subsection">
              <h3>{messages.listItem}</h3>
              {state.inventory.length === 0 ? <p className="empty">{messages.itemsEmpty}</p> : state.inventory.map((item) => (
                <CommandForm action={listItemAction} locale={locale} submitLabel={messages.listItem} className="inline-form" needsCommandKey key={item.item_id}>
                  <input type="hidden" name="item_id" value={item.item_id} />
                  <label className="field">{locale === "hi" ? "गिनती" : "Quantity"}
                    <input type="number" name="quantity" min={1} max={item.quantity} defaultValue={1} required />
                  </label>
                  <label className="field">{locale === "hi" ? "हर सामान का दाम (₹)" : "Price each (₹)"}
                    <input type="number" name="unit_price" min={1} max={1_000_000_000} defaultValue={20} required />
                  </label>
                </CommandForm>
              ))}
            </div>
          </section>

          <section className="card" id="guilds">
            <div className="eyebrow">{messages.factions}</div>
            <h2>{messages.factions}</h2>
            {currentFactions.length === 0 ? (
              <>
                <p className="card-intro">{messages.noFactions}</p>
                <CommandForm action={createFactionAction} locale={locale} submitLabel={messages.createFaction} needsCommandKey>
                  <label className="field">{locale === "hi" ? "मंडली का नाम" : "Guild hall name"}
                    <input name="name" minLength={3} maxLength={32} required />
                  </label>
                  <label className="field">{locale === "hi" ? "हिन्दी नाम" : "Hindi name"}
                    <input name="name_hi" minLength={2} maxLength={40} required />
                  </label>
                  <label className="field">{locale === "hi" ? "परिचय" : "A short introduction"}
                    <textarea name="description" maxLength={500} />
                  </label>
                </CommandForm>
                {availableFactions.map((faction) => (
                  <div className="person-row" key={faction.id}>
                    <div className="row-copy"><strong>{locale === "hi" ? faction.name_hi : faction.name}</strong><span>{faction.description}</span></div>
                    <CommandForm action={joinFactionAction} locale={locale} submitLabel={messages.joinFaction}>
                      <input type="hidden" name="faction_id" value={faction.id} />
                    </CommandForm>
                  </div>
                ))}
              </>
            ) : (
              <div className="callout">
                <strong>{locale === "hi" ? currentFactions[0].name_hi : currentFactions[0].name}</strong>
                <p>{locale === "hi" ? "आपकी मंडली, आपकी मोहल्ले की टोली।" : "Your neighbourhood crew, built around shared projects and good company."}</p>
                {factionMembers.some((member) => member.character_id === state.character.id && member.role === "leader")
                  && factionMembers.some((member) => member.character_id !== state.character.id) && (
                    <CommandForm action={transferFactionLeadershipAction} locale={locale} submitLabel={locale === "hi" ? "नेतृत्व सौंपें" : "Transfer leadership"}>
                      <label className="field">{locale === "hi" ? "नया नेता" : "New leader"}
                        <select name="target_character_id" required defaultValue="">
                          <option value="" disabled>{locale === "hi" ? "सदस्य चुनें" : "Choose a member"}</option>
                          {factionMembers.filter((member) => member.character_id !== state.character.id).map((member) => (
                            <option key={member.character_id} value={member.character_id}>
                              {characterNames[member.character_id] ?? (locale === "hi" ? "मुसाफ़िर" : "Traveller")} · {member.role}
                            </option>
                          ))}
                        </select>
                      </label>
                    </CommandForm>
                  )}
                <CommandForm action={leaveFactionAction} locale={locale} submitLabel={locale === "hi" ? "मंडली छोड़ें" : "Leave guild hall"} />
              </div>
            )}
          </section>

          <section className="card" id="bazaar">
            <div className="eyebrow">{messages.market}</div>
            <h2>{locale === "hi" ? "रौनक़ बाज़ार" : "Ronaq Bazaar"}</h2>
            <p className="card-intro">{locale === "hi" ? "खिलाड़ियों के बीच सामान के सौदे।" : "Player-to-player goods, with every rupee accounted for."}</p>
            {listings.length === 0 && <p className="empty">{locale === "hi" ? "अभी कोई सामान बिक्री पर नहीं है।" : "Nothing is listed just yet."}</p>}
            {listings.map((listing) => {
              const isOwnListing = listing.seller_character_id === state.character.id;
              return (
                <div className="listing-row" key={listing.id}>
                  <div className="row-copy">
                    <strong>{itemNames[listing.item_id] ?? listing.item_id} ×{listing.quantity}</strong>
                    <span>{locale === "hi" ? "विक्रेता" : "By"} {characterNames[listing.seller_character_id] ?? (locale === "hi" ? "मुसाफ़िर" : "Traveller")}</span>
                  </div>
                  <div className="row-action">
                    <span className="price">{messages.rupeeSymbol}{formatNumber(listing.unit_price * listing.quantity, locale)}</span>
                    {isOwnListing ? (
                      <CommandForm action={cancelListingAction} locale={locale} submitLabel={locale === "hi" ? "हटाएँ" : "Cancel"}>
                        <input type="hidden" name="listing_id" value={listing.id} />
                      </CommandForm>
                    ) : (
                      <CommandForm action={purchaseListingAction} locale={locale} submitLabel={messages.buy} needsCommandKey>
                        <input type="hidden" name="listing_id" value={listing.id} />
                      </CommandForm>
                    )}
                  </div>
                </div>
              );
            })}
          </section>

          <section className="card" id="challenge">
            <div className="eyebrow">{messages.pvp}</div>
            <h2>{messages.pvp}</h2>
            <p className="card-intro">{locale === "hi" ? "सिर्फ़ उसी मोहल्ले के मुसाफ़िरों को दोस्ताना चुनौती दें।" : "Invite a neighbour in the same area to a friendly, server-resolved spar."}</p>
            {combatSessions.map((session) => {
              const isChallenger = session.attacker_character_id === state.character.id;
              const opponentId = isChallenger ? session.defender_character_id : session.attacker_character_id;
              const opponentName = characterNames[opponentId] ?? (locale === "hi" ? "मुसाफ़िर" : "Traveller");
              return (
                <div className="callout subsection" key={session.id}>
                  <strong>{opponentName}</strong>
                  {session.status === "pending" && isChallenger && (
                    <p>{locale === "hi" ? "चुनौती का जवाब आने का इंतज़ार है।" : "Waiting for your neighbour to accept the challenge."}</p>
                  )}
                  {session.status === "pending" && !isChallenger && (
                    <>
                      <p>{locale === "hi" ? "इस दोस्ताना मुक़ाबले की चुनौती पाँच मिनट में ख़त्म होगी।" : "This friendly challenge expires in five minutes."}</p>
                      <div className="row-action">
                        <CommandForm action={respondPvpChallengeAction} locale={locale} submitLabel={locale === "hi" ? "स्वीकारें" : "Accept"}>
                          <input type="hidden" name="session_id" value={session.id} />
                          <input type="hidden" name="accept" value="true" />
                        </CommandForm>
                        <CommandForm action={respondPvpChallengeAction} locale={locale} submitLabel={locale === "hi" ? "मना करें" : "Decline"}>
                          <input type="hidden" name="session_id" value={session.id} />
                          <input type="hidden" name="accept" value="false" />
                        </CommandForm>
                      </div>
                    </>
                  )}
                  {session.status === "active" && (
                    <>
                      <p>{locale === "hi" ? "दोनों मुसाफ़िर बारी-बारी से दाँव खेलें।" : "Take turns; each strike is validated and resolved by the server."}</p>
                      <CommandForm action={pvpAction} locale={locale} submitLabel={messages.attack} needsCommandKey>
                        <input type="hidden" name="target_character_id" value={opponentId} />
                        <input type="hidden" name="session_id" value={session.id} />
                      </CommandForm>
                    </>
                  )}
                </div>
              );
            })}
            {otherCharacters.length === 0 && <p className="empty">{locale === "hi" ? "अभी यहाँ कोई दूसरा मुसाफ़िर नहीं है।" : "No other travellers are around yet."}</p>}
            {otherCharacters.map((character) => (
              <div className="person-row" key={character.id}>
                <div className="row-copy"><strong>{character.name}</strong><span>{messages.level} {formatNumber(character.level, locale)}</span></div>
                <CommandForm action={requestPvpChallengeAction} locale={locale} submitLabel={locale === "hi" ? "चुनौती दें" : "Challenge"} needsCommandKey>
                  <input type="hidden" name="target_character_id" value={character.id} />
                </CommandForm>
              </div>
            ))}
          </section>
        </aside>
      </div>
      <footer className="footer">
        <div className="footer-row">
          <span>{messages.cityName} · {locale === "hi" ? "एक काल्पनिक, अनेक-आवाज़ों वाला शहर" : "An original, many-voiced fictional city"}</span>
          <span>{locale === "hi" ? "समय: भारतीय मानक समय · सर्वर समय: UTC" : "Times shown in India Standard Time · Game timestamps stored in UTC"}</span>
        </div>
      </footer>
    </>
  );
}
