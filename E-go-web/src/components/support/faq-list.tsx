import { ChevronDown } from 'lucide-react';

import { faqItems } from '@/lib/domain/labels';
import { cn } from '@/lib/utils/cn';

export interface FaqListProps {
  /** The heading above the questions. */
  title?: string;
  className?: string;
}

/**
 * The frequently asked questions.
 *
 * A native `<details>` accordion: the browser owns the open/close behaviour,
 * so this component ships no JavaScript and stays server-renderable.
 */
export function FaqList({ title = 'Frequently Asked Questions', className }: FaqListProps) {
  return (
    <section className={cn('rounded-card border border-line bg-white', className)}>
      {title ? (
        <h2 className="border-b border-line px-4 py-3 text-xs font-semibold uppercase tracking-wider text-muted">
          {title}
        </h2>
      ) : null}

      <div>
        {faqItems.map((item) => (
          <details key={item.id} className="group border-b border-line last:border-b-0">
            <summary className="flex min-h-[56px] cursor-pointer list-none items-center justify-between gap-3 px-4 py-3 text-sm font-semibold text-navy focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2 [&::-webkit-details-marker]:hidden">
              <span>{item.question}</span>
              <ChevronDown
                aria-hidden="true"
                className="size-4 shrink-0 text-muted transition-transform group-open:rotate-180"
              />
            </summary>

            <p className="px-4 pb-4 text-sm leading-relaxed text-muted">{item.answer}</p>
          </details>
        ))}
      </div>
    </section>
  );
}
