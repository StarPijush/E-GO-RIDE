"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useEffect, useRef, useState, type FormEvent } from "react";
import { ArrowLeft } from "lucide-react";

import { AuthShell } from "@/components/layout/auth-shell";
import { Badge, Button, Card, OtpInput, useToast } from "@/components/ui";
import { isDemoAuthEnabled } from "@/lib/config/env";
import { ROUTES } from "@/lib/config/routes";
import { authCopy, errorMessage, otpCooldownCopy } from "@/lib/domain/labels";
import { getDemoOtp } from "@/lib/repositories";
import { formatPhoneDisplay } from "@/lib/utils/phone";
import { useAuthStore } from "@/stores/auth-store";

export interface OtpFormProps {
  /** The normalized phone number. */
  phone: string;
  /** `register` after a registration, `login` otherwise. */
  mode: "register" | "login";
  /** A code was already requested (the login screen asked for one). */
  sent: boolean;
  /** Where the passenger goes after the verification. */
  returnTo: string;
}

const backLinkClass =
  'inline-flex size-11 items-center justify-center rounded-full text-navy transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function OtpForm({ phone, mode, sent, returnTo }: OtpFormProps) {
  const router = useRouter();
  const { show } = useToast();

  const requestOtp = useAuthStore((state) => state.requestOtp);
  const verifyOtp = useAuthStore((state) => state.verifyOtp);
  const pending = useAuthStore((state) => state.pending);

  const [code, setCode] = useState("");
  const [localError, setLocalError] = useState<string | null>(null);
  const [remaining, setRemaining] = useState(0);
  const [devOtp, setDevOtp] = useState<string | null>(null);

  /** The code is requested exactly once, even in StrictMode. */
  const requested = useRef(false);

  const verifying = pending === "verifyOtp";
  const requesting = pending === "requestOtp";
  const busy = verifying || requesting;

  // The countdown runs in one timeout chain.
  useEffect(() => {
    if (remaining <= 0) return;

    const timer = setTimeout(() => {
      setRemaining((current) => (current > 0 ? current - 1 : 0));
    }, 1000);

    return () => clearTimeout(timer);
  }, [remaining]);

  // Ask for a code once - unless the login screen already did.
  useEffect(() => {
    if (sent || requested.current) return;
    requested.current = true;

    void (async () => {
      const result = await requestOtp(phone);
      if (!result.ok) {
        setLocalError(errorMessage(result.error));
        return;
      }
      setRemaining(result.data.cooldownSeconds);
      if (result.data.devOtp && isDemoAuthEnabled) setDevOtp(result.data.devOtp);
    })();
  }, [phone, requestOtp, sent]);

  const handleVerify = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLocalError(null);

    if (code.length !== 6) {
      setLocalError(authCopy.errors.invalidOtp);
      return;
    }

    const result = await verifyOtp(phone, code);
    if (!result.ok) {
      setLocalError(result.error.message);
      return;
    }

    show({ message: 'Number verified.', tone: 'success' });
    router.replace(result.data.isNewUser ? ROUTES.profileSetup : returnTo);
  };

  const handleResend = async () => {
    setLocalError(null);

    const result = await requestOtp(phone);
    if (!result.ok) {
      setLocalError(errorMessage(result.error));
      return;
    }

    setRemaining(result.data.cooldownSeconds);
    show({ message: 'A new code is on its way.', tone: 'success' });
  };

  const backHref = mode === "register" ? ROUTES.createAccount : ROUTES.login;
  const titleSegments = authCopy.otp.title.split("\n");

  return (
    <AuthShell
      title={titleSegments.map((segment, index) => (
        <span key={`${segment}-${index}`}>
          {index > 0 ? <br /> : null}
          {segment}
        </span>
      ))}
      description={`Enter the 6-digit code sent to ${formatPhoneDisplay(phone)}`}
    >
      <div className="flex flex-col gap-4">
        {mode === "register" ? (
          <div className="flex justify-center">
            <Badge tone="neutral">Step 2 of 2</Badge>
          </div>
        ) : null}

        <form noValidate onSubmit={handleVerify} className="flex flex-col gap-4">
          <OtpInput
            value={code}
            onChange={(next) => {
              setCode(next);
              setLocalError(null);
            }}
            autoFocus
            disabled={busy}
            error={localError ?? undefined}
          />

          <Button type="submit" fullWidth loading={verifying} disabled={busy}>
            {authCopy.otp.verify}
          </Button>
        </form>

        <Button
          type="button"
          variant="secondary"
          fullWidth
          disabled={remaining > 0 || busy}
          onClick={handleResend}
        >
          {remaining > 0 ? otpCooldownCopy(remaining) : authCopy.otp.resend}
        </Button>

        {isDemoAuthEnabled ? (
          <Card className="border-dashed border-brand" padding="md">
            <div className="flex flex-col gap-3">
              <p className="text-xs font-medium text-navy">
                {authCopy.otp.demoHint}
                {devOtp ? <span className="text-muted"> ({devOtp})</span> : null}
              </p>
              <Button
                type="button"
                variant="secondary"
                fullWidth
                disabled={busy}
                onClick={() => {
                  setCode(getDemoOtp() ?? "123456");
                  setLocalError(null);
                }}
              >
                Fill demo code
              </Button>
            </div>
          </Card>
        ) : null}

        <div className="flex justify-center">
          <Link href={backHref} aria-label="Go back" className={backLinkClass}>
            <ArrowLeft aria-hidden="true" className="size-5" />
          </Link>
        </div>
      </div>
    </AuthShell>
  );
}
