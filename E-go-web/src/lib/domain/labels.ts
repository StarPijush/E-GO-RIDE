/**
 * Single source of truth for every user-facing string in E-GO Web.
 *
 * The copy is ported from the Flutter customer app (`E-go/lib/**`) and the
 * consolidated product research, so tests can assert the exact wording and
 * screens never re-invent a sentence.
 *
 * Rules:
 * - no React, no icon library and no UI imports here - this module is pure
 *   data that any layer may read;
 * - the status titles are frozen (they are a port of the Dart
 *   `bookingStatusLabel`), the longer bodies may be reworded;
 * - anything that claims a real driver, a real SMS, a real payment or a real
 *   GPS must say that it is simulated.
 */

import type {
  AppError,
  AppErrorCode,
  BookingStatus,
  CancellationReason,
  PaymentMethodType,
  VehicleType,
} from '@/lib/domain/types';

/** The status titles, ported verbatim from `booking-fsm.ts`. */
export { bookingStatusLabels } from '@/lib/domain/booking-fsm';

/** Visual tone of a status pill / banner. */
export type PillTone = 'neutral' | 'info' | 'success' | 'warning' | 'danger';

/** Icon key of a status (mapped to a real icon by the UI layer). */
export type StatusIcon =
  | 'ready'
  | 'pin'
  | 'flag'
  | 'car'
  | 'receipt'
  | 'check'
  | 'search'
  | 'driver'
  | 'arriving'
  | 'arrived'
  | 'trip'
  | 'done'
  | 'star'
  | 'rated'
  | 'cancelled'
  | 'failed';

/** Copy of one booking status: its frozen title plus a short explanation. */
export interface BookingStatusCopy {
  label: string;
  body: string;
  tone: PillTone;
  icon: StatusIcon;
}

/**
 * Screen copy of every booking status.
 *
 * The `label` values are identical to `bookingStatusLabels` - the titles are
 * a port of the Dart `bookingStatusLabel` and must not drift.
 */
export const bookingStatusCopy: Record<BookingStatus, BookingStatusCopy> = {
  idle: {
    label: 'Ready',
    body: 'Ready when you are. Set a pickup point to start a ride.',
    tone: 'neutral',
    icon: 'ready',
  },
  selectingPickup: {
    label: 'Select pickup',
    body: 'Choose where your ride starts.',
    tone: 'info',
    icon: 'pin',
  },
  selectingDestination: {
    label: 'Select destination',
    body: 'Choose where you want to go.',
    tone: 'info',
    icon: 'flag',
  },
  selectingVehicle: {
    label: 'Choose vehicle',
    body: 'Compare Bike and Toto fares for your route.',
    tone: 'info',
    icon: 'car',
  },
  reviewingFare: {
    label: 'Review fare',
    body: 'Check the fare breakdown before you confirm the ride.',
    tone: 'info',
    icon: 'receipt',
  },
  confirmingBooking: {
    label: 'Confirm booking',
    body: 'Confirm the ride to start looking for a driver.',
    tone: 'warning',
    icon: 'check',
  },
  searchingDriver: {
    label: 'Finding driver',
    body: 'Looking for a nearby driver. This is a demo simulation.',
    tone: 'info',
    icon: 'search',
  },
  driverAssigned: {
    label: 'Driver assigned',
    body: 'A demo driver is on the way to your pickup point.',
    tone: 'success',
    icon: 'driver',
  },
  driverArriving: {
    label: 'Driver arriving',
    body: 'Your demo driver is heading to the pickup point.',
    tone: 'info',
    icon: 'arriving',
  },
  driverArrived: {
    label: 'Driver arrived',
    body: 'Your demo driver is waiting at the pickup point.',
    tone: 'success',
    icon: 'arrived',
  },
  tripInProgress: {
    label: 'Trip in progress',
    body: 'Your demo ride is on the way to the destination.',
    tone: 'info',
    icon: 'trip',
  },
  tripCompleted: {
    label: 'Trip completed',
    body: 'Your trip is complete. Here is your fare summary.',
    tone: 'success',
    icon: 'done',
  },
  awaitingRating: {
    label: 'Rate your ride',
    body: 'Tell us how your ride went.',
    tone: 'info',
    icon: 'star',
  },
  rated: {
    label: 'Rated',
    body: 'Thanks for rating your ride.',
    tone: 'success',
    icon: 'rated',
  },
  cancelled: {
    label: 'Cancelled',
    body: 'This ride was cancelled. No cancellation fee applies.',
    tone: 'danger',
    icon: 'cancelled',
  },
  failed: {
    label: 'Search failed',
    body: 'No driver was found. You can retry the search.',
    tone: 'danger',
    icon: 'failed',
  },
};

/** Why a ride was cancelled. */
export const cancellationReasonLabels: Record<CancellationReason, string> = {
  driver_too_far: 'Driver too far away',
  waiting_too_long: 'Waiting too long',
  changed_plan: 'Changed my plan',
  other: 'Other reason',
};

/** The cancellation reasons in the order they are offered. */
export const cancellationReasonOptions: readonly {
  value: CancellationReason;
  label: string;
}[] = [
  { value: 'driver_too_far', label: cancellationReasonLabels.driver_too_far },
  { value: 'waiting_too_long', label: cancellationReasonLabels.waiting_too_long },
  { value: 'changed_plan', label: cancellationReasonLabels.changed_plan },
  { value: 'other', label: cancellationReasonLabels.other },
];

/** Name of a payment method. */
export const paymentMethodLabels: Record<PaymentMethodType, string> = {
  cash: 'Cash',
  upi: 'UPI',
  card: 'Card',
  wallet: 'Wallet',
};

/** One line explaining a payment method. */
export const paymentMethodHints: Record<PaymentMethodType, string> = {
  cash: 'Pay directly to your rider or toto driver',
  upi: 'Pay via UPI QR code upon arrival',
  card: 'Cards are not supported yet',
  wallet: 'The E-GO wallet is coming soon',
};

/** The rating chips of the ride rating screen. */
export const ratingTags: readonly string[] = [
  'Great driver',
  'Very clean',
  'On time',
  'Smooth ride',
  'Friendly',
  'Safe driving',
];

/**
 * Maximum number of rating tags a rating may carry.
 *
 * The domain schema (`ratingSchema`) allows five tags, so the UI must stop
 * the passenger at the fifth one.
 */
export const ratingTagLimit = 5;

/** Shown on every simulated screen. */
export const demoBannerText = 'Demo simulation - no real driver is assigned.';

/** Shown on the booking confirmation screen. */
export const demoBookingNotice =
  'Demo mode: no real driver is dispatched, no payment is taken and no GPS is used.';

/** Name and description of the two vehicle types. */
export const vehicleCopy: Record<VehicleType, { name: string; description: string; capacity: number }> =
  {
    bike: { name: 'Bike', description: 'Fast & affordable', capacity: 1 },
    toto: { name: 'Toto (E-Rickshaw)', description: 'E-Rickshaw - Up to 3 passengers', capacity: 3 },
  };

/** Copy of the auth flow (onboarding, login, registration, OTP, profile). */
export const authCopy = {
  appTagline: 'Move your way.',
  splashTitle: 'E-GO',
  onboarding: {
    slides: [
      {
        id: 'onboarding-1',
        title: 'Move your way,\nevery day',
        body: "Set your pickup, choose a vehicle, and ride - it's that simple.",
        cta: 'Get started',
      },
      {
        id: 'onboarding-2',
        title: 'Fast bike rides,\nanytime',
        body: 'Need to get somewhere quickly? A bike rider is just a tap away.',
        cta: 'Next',
      },
      {
        id: 'onboarding-3',
        title: 'Ride across\nJhargram',
        body: 'Book affordable Toto (E-Rickshaw) and Bike rides anywhere in Jhargram city.',
        cta: 'Next',
      },
    ],
    skip: 'Skip',
  },
  login: {
    title: 'Enter your\nphone number',
    subtitle: "We'll send a 6-digit verification code via SMS.",
    cta: 'Continue',
    registerPrompt: 'New to E-GO? Create account',
    legal: 'By continuing, you agree to the Terms of Service and Privacy Policy of E-GO.',
    phoneLabel: 'PHONE NUMBER',
    phoneHint: '98765 43210',
    passwordLabel: 'PASSWORD',
    passwordPlaceholder: 'Enter your password',
    securityNote: 'Your number is kept secure & encrypted',
    help: 'Help',
  },
  createAccount: {
    title: 'Create your account',
    subtitle: 'Sign up to start booking TOTO & fast bike rides across India in seconds.',
    cta: 'Create account',
    loginPrompt: 'Already have an account? Log in',
    legal: 'By continuing, you agree to our Terms of Service & Privacy Policy',
    fullNameLabel: 'FULL NAME',
    fullNamePlaceholder: 'Rahul Sen',
    phoneLabel: 'PHONE NUMBER',
    phonePlaceholder: '98765 43210',
    passwordLabel: 'PASSWORD',
    passwordPlaceholder: 'Enter your password',
    emailLabel: 'EMAIL ADDRESS',
    emailBadge: 'OPTIONAL',
    emailPlaceholder: 'rahul@example.com',
  },
  otp: {
    title: 'Verify your\nnumber',
    subtitle: 'Enter the 6-digit code sent to',
    sentTo: 'Enter the 6-digit code sent to',
    resend: 'Resend OTP',
    cooldown: 'Resend OTP in {seconds}s',
    verify: 'Verify',
    cta: 'Verify',
    demoHint: 'Demo OTP:',
    mockHint: 'Mock OTP (not sent by SMS):',
  },
  profileSetup: {
    title: 'Set up your profile',
    subtitle: 'Tell us your name so drivers can find you',
    cta: 'Start riding',
  },
  demoCard: {
    title: 'Demo account',
    description: 'Sign in with the demo account to explore E-GO without creating an account.',
    cta: 'Use demo account',
  },
  errors: {
    invalidPhone: 'Please enter a valid 10-digit mobile number.',
    invalidOtp: 'Invalid OTP. Please try again.',
    invalidPassword: 'Please enter your password.',
    invalidName: 'Please enter your full name.',
    invalidEmail: 'Please enter a valid email address.',
    invalidCredentials: 'Incorrect phone number or password. Please try again.',
    accountExists: 'An account with this phone number already exists. Please log in.',
    otpExpired: 'OTP expired. Please request a new code.',
    otpCooldown: 'Please wait before requesting another OTP.',
    weakPassword: 'Password must be at least 8 characters.',
    hashingUnavailable: 'Secure hashing is not available in this browser.',
  },
} as const;

/** The OTP resend countdown with the remaining seconds. */
export function otpCooldownCopy(seconds: number): string {
  return authCopy.otp.cooldown.replace('{seconds}', String(Math.max(0, Math.floor(seconds))));
}

/** Copy of an empty collection. */
export interface EmptyStateCopy {
  title: string;
  description: string;
  /** Optional call to action. */
  action?: string;
}

/** The empty states of the app. */
export const emptyStateCopy: Record<
  'rides' | 'notifications' | 'savedPlaces' | 'payments' | 'places',
  EmptyStateCopy
> = {
  rides: {
    title: 'No rides yet',
    description: 'Your completed and cancelled rides will appear here.',
    action: 'Book a Toto',
  },
  notifications: {
    title: 'No notifications',
    description: "We'll notify you about your rides and offers here.",
  },
  savedPlaces: {
    title: 'No saved places yet',
    description: 'Save Home, Work and frequent destinations for faster booking',
    action: 'Add place',
  },
  payments: {
    title: 'No payment methods yet',
    description: 'Cash is the only method available in this preview. UPI and cards are coming soon.',
  },
  places: {
    title: 'No places found',
    description: 'Try searching for Bazar, Palace, Station or Hospital',
  },
};

/** The frequently asked questions, ported from the Flutter app. */
export const faqItems: readonly { id: string; question: string; answer: string }[] = [
  {
    id: 'faq-book-a-ride',
    question: 'How do I book a ride?',
    answer:
      'Open the app, enter your destination, choose a vehicle (Bike or Toto), and confirm your booking. A driver will be matched to you.',
  },
  {
    id: 'faq-fare',
    question: 'How is the fare calculated?',
    answer:
      'Fares are based on distance and vehicle type. Bike rides start at ₹20 + ₹10/km. Toto rides start at ₹15 + ₹7/km. A small platform fee applies.',
  },
  {
    id: 'faq-cancel',
    question: 'Can I cancel a ride?',
    answer:
      'Yes, you can cancel before the driver arrives. Once the trip starts, cancellation is not available.',
  },
  {
    id: 'faq-payment',
    question: 'What payment methods are accepted?',
    answer: 'Currently cash is accepted. UPI and card payments will be available soon.',
  },
  {
    id: 'faq-driver-contact',
    question: 'How do I contact my driver?',
    answer: 'Once a driver is assigned, you can call them from the driver details screen.',
  },
  {
    id: 'faq-what-is-a-toto',
    question: 'What is a Toto?',
    answer:
      'A Toto is an electric rickshaw (E-Rickshaw) that can carry up to 3 passengers. It is a popular and affordable mode of transport in Jhargram.',
  },
];

/** Copy of the safety and support screens. */
export const safetyCopy = {
  shareTrip: {
    title: 'Share Live Ride Status',
    description:
      'Share your live route and estimated arrival time with friends and family with a single tap.',
    cta: 'Share live status',
  },
  emergencyContacts: {
    title: 'Emergency SOS',
    description: 'Instant alert to contacts & Jhargram Police',
    cta: 'TRIGGER EMERGENCY SOS',
    triggered: 'Emergency SOS triggered (Demo Simulation). Contacts notified.',
  },
  helplines: {
    title: '24/7 Local Assistance',
    description:
      'Our local Jhargram transit desk is always reachable for lost items, fare inquiries, and route questions.',
    cta: 'Contact support',
  },
  guidelinesTitle: 'Ride Safety Guidelines',
  verifiedDrivers: {
    title: 'Verified TOTO Drivers',
    description:
      'Every E-GO driver in Jhargram is registered and police-verified with visible registration badges.',
  },
  supportTitle: 'E-GO Support Team',
  supportDescription: 'We are here to assist with your rides, safety, and payments in Jhargram.',
  reportIssue: 'Report an issue',
  faqTitle: 'Frequently Asked Questions',
  demoDisclaimer:
    'Safety features are simulated in this demo. No real contact, police station or helpline is notified.',
} as const;

/** The fallback message of every error code. */
export const errorCopy: Record<AppErrorCode, string> = {
  invalid_phone: 'Please enter a valid 10-digit mobile number.',
  invalid_otp: 'Invalid OTP. Please try again.',
  otp_expired: 'OTP expired. Please request a new code.',
  otp_cooldown: 'Please wait before requesting another OTP.',
  invalid_credentials: 'Incorrect phone number or password. Please try again.',
  account_exists: 'An account with this phone number already exists. Please log in.',
  not_found: 'No account found. Please create an account first.',
  invalid_transition: 'That action is not possible right now.',
  storage_corrupt: 'Saved demo data could not be read and has been reset.',
  demo_disabled: 'Demo mode is disabled.',
  unknown: 'Something went wrong. Please try again.',
};

/** The message of an error: the shared copy first, the error text as fallback. */
export function errorMessage(error: AppError): string {
  return errorCopy[error.code] ?? error.message;
}

/**
 * The auth error copy, keyed by the names the auth repository uses.
 *
 * The mock repository re-exports it as `AUTH_ERROR_MESSAGES`.
 */
export const authErrorMessages = {
  invalidPhone: authCopy.errors.invalidPhone,
  accountNotFound: errorCopy.not_found,
  invalidCredentials: authCopy.errors.invalidCredentials,
  accountExists: authCopy.errors.accountExists,
  invalidOtp: authCopy.errors.invalidOtp,
  invalidName: authCopy.errors.invalidName,
  weakPassword: authCopy.errors.weakPassword,
  invalidEmail: authCopy.errors.invalidEmail,
  hashingUnavailable: authCopy.errors.hashingUnavailable,
  otpExpired: authCopy.errors.otpExpired,
} as const;
