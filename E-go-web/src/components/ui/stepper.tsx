import { cn } from '@/lib/utils/cn';

export interface StepperProps {
  /** The labels of the steps. */
  steps: readonly string[];
  /** The index of the current step (0 based). */
  current: number;
  /** The accessible name of the stepper. */
  label?: string;
}

/**
 * The progress of a multi step flow (the booking, for example).
 *
 * The desktop shows the dots with their labels, the mobile a progress bar
 * with the current step.
 */
export function Stepper({ steps, current, label = 'Booking progress' }: StepperProps) {
  const lastIndex = Math.max(steps.length - 1, 0);
  const activeIndex = Math.min(Math.max(current, 0), lastIndex);
  const progress = steps.length > 1 ? (activeIndex / lastIndex) * 100 : 0;

  return (
    <div role="group" aria-label={label} className="w-full">
      <ol className="hidden items-start md:flex">
        {steps.map((step, index) => {
          const state = index < activeIndex ? 'completed' : index === activeIndex ? 'current' : 'future';

          return (
            <li
              key={step}
              aria-current={state === 'current' ? 'step' : undefined}
              className="flex flex-1 flex-col items-center gap-1.5"
            >
              <span
                aria-hidden="true"
                className={cn(
                  'size-3 rounded-full',
                  state === 'completed'
                    ? 'bg-success'
                    : state === 'current'
                      ? 'bg-brand'
                      : 'bg-navy-soft',
                )}
              />
              <span
                className={cn(
                  'text-center text-xs',
                  state === 'future' ? 'text-muted' : 'font-medium text-navy',
                )}
              >
                {step}
              </span>
            </li>
          );
        })}
      </ol>

      <div className="md:hidden">
        <div className="h-1 w-full overflow-hidden rounded-full bg-navy-soft">
          <div
            className="h-full rounded-full bg-brand"
            style={{ width: `${progress}%` }}
          />
        </div>
        {steps[activeIndex] ? (
          <p className="mt-2 text-center text-xs font-medium text-navy">{steps[activeIndex]}</p>
        ) : null}
      </div>
    </div>
  );
}
