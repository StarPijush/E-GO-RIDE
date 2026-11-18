import type { ReactNode } from 'react';

import { cn } from '@/lib/utils/cn';

/** The width of the content. */
export type ContainerSize = 'narrow' | 'default' | 'wide';

export interface ContainerProps {
  size?: ContainerSize;
  className?: string;
  children: ReactNode;
}

const SIZE_CLASSES: Record<ContainerSize, string> = {
  narrow: 'max-w-lg',
  default: 'max-w-[1200px]',
  wide: 'max-w-[1320px]',
};

/** The horizontal frame of every screen. */
export function Container({ size = 'default', className, children }: ContainerProps) {
  return (
    <div
      className={cn('mx-auto w-full px-4 sm:px-6 lg:px-8', SIZE_CLASSES[size], className)}
    >
      {children}
    </div>
  );
}
