"use client";

import { useState } from "react";
import { saveLocaleAction } from "@/app/auth/actions";
import type { Locale, Messages } from "@/lib/i18n";

export function LanguageToggle({ locale, label }: { locale: Locale; label: Messages["language"] }) {
  const [failed, setFailed] = useState(false);

  async function toggleLanguage() {
    const nextLocale = locale === "en" ? "hi" : "en";
    const saved = await saveLocaleAction(nextLocale);
    if (!saved) {
      setFailed(true);
      return;
    }
    window.location.reload();
  }

  return <>
    <button className="language-toggle" onClick={toggleLanguage} type="button" aria-label="Change language">{label}</button>
    {failed && <span className="form-error" role="status">{locale === "hi" ? "भाषा सहेजी नहीं जा सकी।" : "Could not save your language preference."}</span>}
  </>;
}
