/**
 * The UI primitives of E-GO Web.
 *
 * Every primitive is built from the design tokens of `globals.css`, has a
 * visible focus state and a correct disabled style - no screen has to
 * re-implement them.
 */

export { Avatar } from '@/components/ui/avatar';
export type { AvatarProps, AvatarSize } from '@/components/ui/avatar';

export { Badge } from '@/components/ui/badge';
export type { BadgeProps, BadgeTone } from '@/components/ui/badge';

export { Button } from '@/components/ui/button';
export type { ButtonProps, ButtonSize, ButtonVariant } from '@/components/ui/button';

export { Card } from '@/components/ui/card';
export type { CardElement, CardPadding, CardProps } from '@/components/ui/card';

export { Dialog } from '@/components/ui/dialog';
export type { DialogProps, DialogSize } from '@/components/ui/dialog';

export { EmptyState } from '@/components/ui/empty-state';
export type { EmptyStateProps } from '@/components/ui/empty-state';

export { ErrorState } from '@/components/ui/error-state';
export type { ErrorStateProps } from '@/components/ui/error-state';

export { Field } from '@/components/ui/field';
export type { FieldProps } from '@/components/ui/field';

export { IconButton } from '@/components/ui/icon-button';
export type { IconButtonProps, IconButtonSize, IconButtonVariant } from '@/components/ui/icon-button';

export { Input } from '@/components/ui/input';
export type { InputProps } from '@/components/ui/input';

export { OtpInput } from '@/components/ui/otp-input';
export type { OtpInputProps } from '@/components/ui/otp-input';

export { SegmentedTabs } from '@/components/ui/segmented-tabs';
export type { SegmentedTab, SegmentedTabsProps } from '@/components/ui/segmented-tabs';

export { Sheet } from '@/components/ui/sheet';
export type { SheetProps, SheetSide } from '@/components/ui/sheet';

export { Skeleton } from '@/components/ui/skeleton';
export type { SkeletonProps, SkeletonRounded } from '@/components/ui/skeleton';

export { Spinner } from '@/components/ui/spinner';
export type { SpinnerProps, SpinnerSize } from '@/components/ui/spinner';

export { Stepper } from '@/components/ui/stepper';
export type { StepperProps } from '@/components/ui/stepper';

export { Textarea } from '@/components/ui/textarea';
export type { TextareaProps } from '@/components/ui/textarea';

export { ToastHost, ToastProvider, useToast } from '@/components/ui/toast';
export type {
  Toast,
  ToastContextValue,
  ToastInput,
  ToastProviderProps,
  ToastTone,
} from '@/components/ui/toast';
