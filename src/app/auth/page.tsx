import Link from "next/link";
import { redirect } from "next/navigation";
import { LanguageToggle } from "@/components/language-toggle";
import { getLocale, getMessages } from "@/lib/i18n";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { signInAction, signUpAction } from "./actions";

type Props = {
  searchParams: Promise<{ error?: string; mode?: string }>;
};

const errorCopy = {
  en: {
    invalid: "Check your email, password, and display name. Passwords must be at least 8 characters.",
    signin: "We could not sign you in. Check your details and try again.",
    signup: "We could not create your account. The email may already be registered.",
    callback: "Your sign-in link could not be verified. Please try again.",
    signout: "We could not end your session. Please try again.",
  },
  hi: {
    invalid: "ईमेल, पासवर्ड और नाम जाँचें। पासवर्ड कम से कम 8 अक्षरों का होना चाहिए।",
    signin: "प्रवेश नहीं हो सका। जानकारी जाँचकर फिर कोशिश करें।",
    signup: "खाता नहीं बन सका। यह ईमेल पहले से दर्ज हो सकता है।",
    callback: "आपके प्रवेश लिंक की पुष्टि नहीं हो सकी। कृपया फिर कोशिश करें।",
    signout: "आपका सत्र समाप्त नहीं हो सका। कृपया फिर कोशिश करें।",
  },
} as const;

export default async function AuthPage({ searchParams }: Props) {
  const [{ error, mode }, locale] = await Promise.all([searchParams, getLocale()]);
  const messages = getMessages(locale);
  const supabase = await createSupabaseServerClient();
  const { data } = await supabase.auth.getUser();
  if (data.user) redirect("/");

  const isSignup = mode === "signup";
  const errorMessage = error && error in errorCopy[locale]
    ? errorCopy[locale][error as keyof (typeof errorCopy)["en"]]
    : null;

  return (
    <main className="shell">
      <header className="topbar">
        <Link className="brand" href="/">
          <span className="brand-mark">म</span>
          <span className="brand-name">{messages.name}</span>
        </Link>
        <LanguageToggle locale={locale} label={messages.language} />
      </header>
      <div className="auth-wrap">
        <section className="card auth-card">
          <div className="eyebrow">{messages.name}</div>
          <h1>{isSignup ? messages.welcomeNew : messages.welcome}</h1>
          <p className="card-intro">{messages.createAccountHint}</p>
          {errorMessage && <p className="auth-error" role="alert">{errorMessage}</p>}
          <form action={isSignup ? signUpAction : signInAction} className="auth-form">
            {isSignup && <label>{messages.displayName}<input name="display_name" minLength={2} maxLength={40} autoComplete="nickname" required /></label>}
            <label>{messages.email}<input name="email" type="email" autoComplete="email" required /></label>
            <label>{messages.password}<input name="password" type="password" minLength={8} maxLength={128} autoComplete={isSignup ? "new-password" : "current-password"} required /></label>
            <button className="button button-primary" type="submit">{isSignup ? messages.signUp : messages.signIn}</button>
          </form>
          <p className="card-intro subsection">
            {isSignup
              ? (locale === "hi" ? "पहले से खाता है? " : "Already have an account? ")
              : (locale === "hi" ? "नए हैं? " : "New to Mayanagari? ")}
            <Link className="price" href={isSignup ? "/auth" : "/auth?mode=signup"}>
              {isSignup ? messages.signIn : messages.join}
            </Link>
          </p>
        </section>
      </div>
    </main>
  );
}
