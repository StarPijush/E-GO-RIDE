"use client";

import { useRouter } from "next/navigation";
import { useEffect, useState, type FormEvent } from "react";

import { AuthShell } from "@/components/layout/auth-shell";
import { Avatar, Badge, Button, Input, Spinner, useToast } from "@/components/ui";
import { ROUTES } from "@/lib/config/routes";
import { authCopy } from "@/lib/domain/labels";
import type { User } from "@/lib/domain/types";
import { formatPhoneDisplay } from "@/lib/utils/phone";
import { useAuthStore } from "@/stores/auth-store";

/** The pattern of a valid email address. */
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** The fields of the profile (mounted once the user is known). */
function ProfileFields({ user }: { user: User }) {
  const router = useRouter();
  const { show } = useToast();

  const updateProfile = useAuthStore((state) => state.updateProfile);
  const pending = useAuthStore((state) => state.pending);

  const [fullName, setFullName] = useState(user.fullName);
  const [email, setEmail] = useState(user.email ?? "");
  const [localError, setLocalError] = useState<string | null>(null);

  const submitting = pending === "profile";

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLocalError(null);

    const name = fullName.trim();
    if (name.length < 2) {
      setLocalError(authCopy.errors.invalidName);
      return;
    }

    const trimmedEmail = email.trim();
    if (trimmedEmail.length > 0 && !EMAIL_PATTERN.test(trimmedEmail)) {
      setLocalError(authCopy.errors.invalidEmail);
      return;
    }

    const result = await updateProfile({ fullName: name, email: trimmedEmail });
    if (!result.ok) {
      setLocalError(result.error.message);
      return;
    }

    show({ message: "You're all set.", tone: 'success' });
    router.replace(ROUTES.home);
  };

  return (
    <form noValidate onSubmit={handleSubmit} className="flex flex-col gap-4">
      <div className="flex items-center gap-3 rounded-card border border-line bg-white p-3">
        <Avatar name={user.fullName || 'E-GO user'} size="md" />

        <div className="flex min-w-0 flex-1 flex-col">
          <span className="truncate text-sm font-medium text-navy">
            {formatPhoneDisplay(user.phone)}
          </span>
          <span className="text-xs text-muted">Phone number</span>
        </div>

        <Badge tone="success">Verified</Badge>
      </div>

      <Input
        label="Full name"
        autoComplete="name"
        autoFocus
        placeholder={authCopy.createAccount.fullNamePlaceholder}
        value={fullName}
        disabled={submitting}
        onChange={(event) => {
          setFullName(event.target.value);
          setLocalError(null);
        }}
      />

      <Input
        label={
          <span className="inline-flex items-center gap-2">
            Email address
            <Badge tone="neutral">Optional</Badge>
          </span>
        }
        type="email"
        autoComplete="email"
        placeholder={authCopy.createAccount.emailPlaceholder}
        value={email}
        disabled={submitting}
        onChange={(event) => {
          setEmail(event.target.value);
          setLocalError(null);
        }}
      />

      {localError ? (
        <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
          {localError}
        </p>
      ) : null}

      <Button type="submit" fullWidth loading={submitting} disabled={submitting}>
        {authCopy.profileSetup.cta}
      </Button>
    </form>
  );
}

/** The last step of the registration: the profile of the passenger. */
export function ProfileSetupForm() {
  const router = useRouter();

  const user = useAuthStore((state) => state.user);
  const session = useAuthStore((state) => state.session);
  const hasHydrated = useAuthStore((state) => state.hasHydrated);

  useEffect(() => {
    if (!hasHydrated) return;

    if (!session) {
      router.replace(ROUTES.login);
      return;
    }
    if (user?.profileComplete) {
      router.replace(ROUTES.home);
    }
  }, [hasHydrated, router, session, user]);

  return (
    <AuthShell title={authCopy.profileSetup.title} description={authCopy.profileSetup.subtitle}>
      <div className="flex flex-col gap-4">
        <div className="flex justify-center">
          <Badge tone="neutral">Last step</Badge>
        </div>

        {hasHydrated && session && user ? (
          <ProfileFields key={user.id} user={user} />
        ) : (
          <div className="flex justify-center py-6">
            <Spinner label="Loading your profile" />
          </div>
        )}
      </div>
    </AuthShell>
  );
}
