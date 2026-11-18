'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import { CircleCheck, CircleX, Info, TriangleAlert, X, type LucideIcon } from 'lucide-react';

import { IconButton } from '@/components/ui/icon-button';
import { cn } from '@/lib/utils/cn';
import { newId } from '@/lib/utils/id';

/** The tone of a toast. */
export type ToastTone = 'neutral' | 'success' | 'danger' | 'warning';

/** A toast the app wants to show. */
export interface ToastInput {
  message: string;
  tone?: ToastTone;
  /** How long the toast stays. `0` keeps it until it is dismissed. */
  durationMs?: number;
  /** A fixed id (the same id replaces the same toast). */
  id?: string;
}

/** A toast that is on the screen. */
export interface Toast extends ToastInput {
  id: string;
  tone: ToastTone;
  durationMs: number;
}

/** What the provider offers. */
export interface ToastContextValue {
  /** Shows a toast and returns its id. */
  show: (input: ToastInput) => string;
  /** Removes a toast. */
  dismiss: (id: string) => void;
  /** The toasts that are on the screen (newest last). */
  toasts: readonly Toast[];
}

const ToastContext = createContext<ToastContextValue | null>(null);

/** The most toasts that are on the screen at the same time. */
const MAX_TOASTS = 3;

/** The default lifetime of a toast. */
const DEFAULT_DURATION_MS = 4000;

const TONE_CLASSES: Record<ToastTone, { circle: string; icon: LucideIcon }> = {
  neutral: { circle: 'bg-navy-soft text-navy', icon: Info },
  success: { circle: 'bg-success-soft text-success', icon: CircleCheck },
  danger: { circle: 'bg-danger-soft text-danger', icon: CircleX },
  warning: { circle: 'bg-warning-soft text-warning', icon: TriangleAlert },
};

export interface ToastProviderProps {
  children: ReactNode;
}

/**
 * The provider of the toasts.
 *
 * At most three toasts are on the screen; the oldest one is dropped when a
 * fourth arrives.
 */
export function ToastProvider({ children }: ToastProviderProps) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const timers = useRef<Map<string, ReturnType<typeof setTimeout>>>(new Map());

  const dismiss = useCallback((id: string) => {
    const timer = timers.current.get(id);
    if (timer) {
      clearTimeout(timer);
      timers.current.delete(id);
    }
    setToasts((current) => current.filter((toast) => toast.id !== id));
  }, []);

  const show = useCallback(
    (input: ToastInput): string => {
      const id = input.id ?? newId('toast');
      const toast: Toast = {
        id,
        message: input.message,
        tone: input.tone ?? 'neutral',
        durationMs: input.durationMs ?? DEFAULT_DURATION_MS,
      };

      const running = timers.current.get(id);
      if (running) {
        clearTimeout(running);
        timers.current.delete(id);
      }

      setToasts((current) => {
        const withoutDuplicate = current.filter((entry) => entry.id !== id);
        const next = [...withoutDuplicate, toast];
        return next.length > MAX_TOASTS ? next.slice(next.length - MAX_TOASTS) : next;
      });

      if (toast.durationMs > 0) {
        const timer = setTimeout(() => {
          dismiss(id);
        }, toast.durationMs);
        timers.current.set(id, timer);
      }

      return id;
    },
    [dismiss],
  );

  // No timer may outlive the provider.
  useEffect(() => {
    const pending = timers.current;
    return () => {
      for (const timer of pending.values()) clearTimeout(timer);
      pending.clear();
    };
  }, []);

  const value = useMemo(() => ({ show, dismiss, toasts }), [show, dismiss, toasts]);

  return <ToastContext.Provider value={value}>{children}</ToastContext.Provider>;
}

/** The toasts of the app. Throws outside of a {@link ToastProvider}. */
export function useToast(): ToastContextValue {
  const context = useContext(ToastContext);
  if (!context) {
    throw new Error('useToast must be used inside a ToastProvider.');
  }
  return context;
}

/** The detail of the `ego:storage-error` event. */
interface StorageErrorDetail {
  message?: string;
}

/**
 * The place where the toasts appear.
 *
 * The host sits above the bottom navigation of the mobile shell and listens
 * to the `ego:storage-error` event of the persistence layer.
 */
export function ToastHost() {
  const { show, dismiss, toasts } = useToast();

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const handleStorageError = (event: Event) => {
      const detail = (event as CustomEvent<StorageErrorDetail>).detail;
      show({
        message: detail?.message ?? 'Demo data could not be saved.',
        tone: 'danger',
      });
    };

    window.addEventListener('ego:storage-error', handleStorageError);
    return () => window.removeEventListener('ego:storage-error', handleStorageError);
  }, [show]);

  return (
    <div
      aria-live="polite"
      aria-atomic="false"
      className="pointer-events-none fixed inset-x-4 bottom-24 z-50 flex flex-col items-center gap-2 lg:bottom-6"
    >
      {toasts.map((toast) => {
        const tone = TONE_CLASSES[toast.tone];
        const Icon = tone.icon;

        return (
          <div
            key={toast.id}
            role="status"
            className="pointer-events-auto flex w-full max-w-sm items-start gap-3 rounded-card border border-line bg-white p-3 shadow-float"
          >
            <span
              className={cn(
                'mt-0.5 flex size-8 shrink-0 items-center justify-center rounded-full',
                tone.circle,
              )}
            >
              <Icon aria-hidden="true" className="size-4" />
            </span>

            <p className="flex-1 text-sm text-navy">{toast.message}</p>

            <IconButton label="Dismiss notification" size="sm" onClick={() => dismiss(toast.id)}>
              <X aria-hidden="true" className="size-4" />
            </IconButton>
          </div>
        );
      })}
    </div>
  );
}
