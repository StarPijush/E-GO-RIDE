import Image from 'next/image';

import {
  OnboardingBack,
  OnboardingNext,
  OnboardingSkip,
} from '@/components/auth/onboarding-actions';
import { Logo } from '@/components/shared/logo';
import { ROUTES } from '@/lib/config/routes';
import { authCopy } from '@/lib/domain/labels';
import { cn } from '@/lib/utils/cn';

export interface OnboardingSlideProps {
  /** The slide of the onboarding (0, 1 or 2). */
  index: 0 | 1 | 2;
}

/** The previous onboarding page of every slide. */
const PREVIOUS_PATHS = [ROUTES.onboarding, ROUTES.onboarding2];

/** Where the action of a slide leads to. */
const NEXT_PATHS = [ROUTES.onboarding2, ROUTES.onboarding3];

/**
 * One slide of the onboarding.
 *
 * The copy comes from `authCopy.onboarding.slides` - the titles carry a
 * line break, which is rendered as a `<br />` (never as raw HTML).
 */
export function OnboardingSlide({ index }: OnboardingSlideProps) {
  const slide = authCopy.onboarding.slides[index];
  const isLast = index === 2;
  const titleSegments = slide.title.split('\n');

  return (
    <main id="main" className="min-h-dvh bg-surface">
      <header className="flex items-center justify-between gap-3 px-4 py-4 sm:px-6">
        <div className="flex items-center gap-2">
          <OnboardingBack
            href={PREVIOUS_PATHS[index - 1] ?? ROUTES.onboarding}
            show={index > 0}
          />
          <Logo href={null} size="sm" />
        </div>

        <OnboardingSkip />
      </header>

      <div className="mx-auto w-full max-w-lg px-4 pb-10 sm:px-6">
        <div className="relative min-h-[280px] overflow-hidden rounded-card sm:min-h-[340px]">
          <Image
            src="/branding/ego_brand_background.jpg"
            alt=""
            fill
            priority={index === 0}
            sizes="(min-width: 640px) 32rem, 100vw"
            className="object-cover"
          />
          <div aria-hidden="true" className="absolute inset-0 bg-navy/55" />
          <div
            aria-hidden="true"
            className="absolute -right-12 -top-12 size-44 rounded-full bg-white/10 blur-2xl"
          />

          <div className="relative flex h-full flex-col items-center justify-center gap-4 p-6 text-center">
            <div className="flex size-24 items-center justify-center rounded-card bg-white/95">
              <Image
                src="/branding/ego_logo_icon.png"
                alt=""
                width={96}
                height={96}
                className="size-24 object-contain"
              />
            </div>

            <h1 className="font-display text-3xl font-bold text-white">
              {titleSegments.map((segment, segmentIndex) => (
                <span key={`${segment}-${segmentIndex}`}>
                  {segmentIndex > 0 ? <br /> : null}
                  {segment}
                </span>
              ))}
            </h1>

            <p className="text-sm text-white/80">{slide.body}</p>
          </div>
        </div>

        <div className="mt-6 flex items-center justify-center gap-2">
          {authCopy.onboarding.slides.map((entry, dotIndex) => (
            <span
              key={entry.id}
              aria-hidden="true"
              className={cn(
                'h-2 rounded-full',
                dotIndex === index ? 'w-6 bg-brand' : 'w-2 bg-navy-soft',
              )}
            />
          ))}
        </div>

        <div className="mt-6">
          <OnboardingNext
            href={NEXT_PATHS[index] ?? ROUTES.login}
            label={isLast ? 'Get started' : slide.cta}
            final={isLast}
          />
        </div>

        <p className="mt-4 text-center text-xs text-muted">
          By continuing you agree to the E-GO Terms &amp; Service.
        </p>
      </div>
    </main>
  );
}
