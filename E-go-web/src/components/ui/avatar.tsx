import Image from 'next/image';

import { cn } from '@/lib/utils/cn';
import { selectInitials } from '@/stores/selectors';

/** The size of an avatar. */
export type AvatarSize = 'sm' | 'md' | 'lg';

export interface AvatarProps {
  /** The full name of the person (the initials and the background come from it). */
  name: string;
  /** The picture of the person. Without it the initials are shown. */
  src?: string;
  size?: AvatarSize;
  className?: string;
}

const SIZE_CLASSES: Record<AvatarSize, string> = {
  sm: 'size-8 text-xs',
  md: 'size-10 text-sm',
  lg: 'size-14 text-lg',
};

/** The pixel size of the avatar (for `next/image`). */
const PIXEL_SIZES: Record<AvatarSize, number> = {
  sm: 32,
  md: 40,
  lg: 56,
};

/**
 * The backgrounds of the avatar.
 *
 * Every entry keeps a readable contrast: the yellow background carries navy
 * text, the dark ones white text.
 */
const PALETTE = [
  { background: 'bg-brand', text: 'text-navy' },
  { background: 'bg-navy', text: 'text-white' },
  { background: 'bg-info', text: 'text-white' },
  { background: 'bg-success', text: 'text-white' },
] as const;

/** A stable hash of a name, so the same person always gets the same color. */
function nameHash(name: string): number {
  let hash = 0;
  for (let index = 0; index < name.length; index += 1) {
    hash = (hash * 31 + name.charCodeAt(index)) >>> 0;
  }
  return hash;
}

/** The picture or the initials of a person. */
export function Avatar({ name, src, size = 'md', className }: AvatarProps) {
  const sizeClass = SIZE_CLASSES[size];

  if (src) {
    const pixels = PIXEL_SIZES[size];
    return (
      <span
        className={cn(
          'inline-flex shrink-0 overflow-hidden rounded-full bg-navy-soft',
          sizeClass,
          className,
        )}
      >
        <Image
          src={src}
          alt={name}
          width={pixels}
          height={pixels}
          className="h-full w-full object-cover"
        />
      </span>
    );
  }

  const palette = PALETTE[nameHash(name) % PALETTE.length];

  return (
    <span
      role="img"
      aria-label={name}
      className={cn(
        'inline-flex shrink-0 items-center justify-center rounded-full font-semibold',
        sizeClass,
        palette.background,
        palette.text,
        className,
      )}
    >
      <span aria-hidden="true">{selectInitials(name)}</span>
    </span>
  );
}
