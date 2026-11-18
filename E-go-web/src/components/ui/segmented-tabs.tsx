'use client';

import { useRef, type KeyboardEvent } from 'react';

import { cn } from '@/lib/utils/cn';

/** One tab of the segmented control. */
export interface SegmentedTab {
  value: string;
  label: string;
  /** An optional number behind the label (a count of rides, for example). */
  count?: number;
}

export interface SegmentedTabsProps {
  tabs: readonly SegmentedTab[];
  /** The value of the selected tab. */
  value: string;
  onChange: (value: string) => void;
  /** The accessible name of the tab list. */
  ariaLabel: string;
}

/**
 * A segmented control (the filter of "My Rides", for example).
 *
 * The arrow keys, Home and End move the focus and the selection, like every
 * other tab list.
 */
export function SegmentedTabs({ tabs, value, onChange, ariaLabel }: SegmentedTabsProps) {
  const buttons = useRef<Array<HTMLButtonElement | null>>([]);

  const focusTab = (index: number) => {
    if (tabs.length === 0) return;
    const clamped = Math.min(Math.max(index, 0), tabs.length - 1);
    buttons.current[clamped]?.focus();
    const tab = tabs[clamped];
    if (tab) onChange(tab.value);
  };

  const handleKeyDown = (index: number, event: KeyboardEvent<HTMLButtonElement>) => {
    switch (event.key) {
      case 'ArrowLeft':
        event.preventDefault();
        focusTab(index - 1);
        break;
      case 'ArrowRight':
        event.preventDefault();
        focusTab(index + 1);
        break;
      case 'Home':
        event.preventDefault();
        focusTab(0);
        break;
      case 'End':
        event.preventDefault();
        focusTab(tabs.length - 1);
        break;
      default:
        break;
    }
  };

  return (
    <div
      role="tablist"
      aria-label={ariaLabel}
      className="inline-flex w-full rounded-pill bg-navy-soft p-1"
    >
      {tabs.map((tab, index) => {
        const active = tab.value === value;

        return (
          <button
            key={tab.value}
            ref={(element) => {
              buttons.current[index] = element;
            }}
            type="button"
            role="tab"
            aria-selected={active}
            tabIndex={active ? 0 : -1}
            onClick={() => onChange(tab.value)}
            onKeyDown={(event) => handleKeyDown(index, event)}
            className={cn(
              'inline-flex flex-1 items-center justify-center gap-1.5 rounded-pill px-3 py-1.5 text-sm',
              'transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
              active ? 'bg-white font-semibold text-navy shadow-sm' : 'text-muted',
            )}
          >
            {tab.label}
            {tab.count !== undefined ? (
              <span
                className={cn(
                  'inline-flex min-w-5 items-center justify-center rounded-full px-1.5 text-xs font-semibold',
                  active ? 'bg-navy-soft text-navy' : 'bg-white/70 text-muted',
                )}
              >
                {tab.count}
              </span>
            ) : null}
          </button>
        );
      })}
    </div>
  );
}
