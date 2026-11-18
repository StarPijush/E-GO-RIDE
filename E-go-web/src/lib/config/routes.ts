/**
 * The route map of E-GO Web.
 *
 * One place knows every path of the app: the navigation, the guards, the
 * booking flow and the `returnTo` allowlist. No React import here - this
 * module is plain data that any layer may read.
 *
 * The route list is the approved one (31 routes + the `/register` alias).
 */

export const ROUTES = {
  splash: '/',
  onboarding: '/onboarding',
  onboarding2: '/onboarding-2',
  onboarding3: '/onboarding-3',
  login: '/login',
  createAccount: '/create-account',
  register: '/register',
  otp: '/otp',
  profileSetup: '/profile-setup',
  home: '/home',
  pickupSelection: '/pickup-selection',
  destinationSelection: '/destination-selection',
  savedPlaces: '/saved-places',
  vehicleSelection: '/vehicle-selection',
  fareDetails: '/fare-details',
  bookingConfirmation: '/booking-confirmation',
  searchingDriver: '/searching-driver',
  driverAssigned: '/driver-assigned',
  rideTracking: '/ride-tracking',
  tripCompleted: '/trip-completed',
  rideRating: '/ride-rating',
  myRides: '/my-rides',
  rideDetails: '/ride-details',
  profile: '/profile',
  editProfile: '/edit-profile',
  paymentMethods: '/payment-methods',
  notifications: '/notifications',
  helpSupport: '/help-support',
  settings: '/settings',
  about: '/about',
  safety: '/safety',
} as const;

/** A route of the app (the key of {@link ROUTES}). */
export type AppRoute = keyof typeof ROUTES;

/** A path of the app. */
export type RoutePath = (typeof ROUTES)[AppRoute];

/** The routes a visitor may reach without a session. */
export const PUBLIC_ROUTES: readonly AppRoute[] = [
  'splash',
  'onboarding',
  'onboarding2',
  'onboarding3',
  'login',
  'createAccount',
  'register',
  'otp',
];

/** The routes that need a session. */
export const PROTECTED_ROUTES: readonly AppRoute[] = [
  'home',
  'pickupSelection',
  'destinationSelection',
  'savedPlaces',
  'vehicleSelection',
  'fareDetails',
  'bookingConfirmation',
  'searchingDriver',
  'driverAssigned',
  'rideTracking',
  'tripCompleted',
  'rideRating',
  'myRides',
  'rideDetails',
  'profile',
  'editProfile',
  'paymentMethods',
  'notifications',
  'helpSupport',
  'settings',
  'about',
  'safety',
];

/** Every route that belongs to the booking flow. */
export const BOOKING_ROUTES: readonly AppRoute[] = [
  'savedPlaces',
  'pickupSelection',
  'destinationSelection',
  'vehicleSelection',
  'fareDetails',
  'bookingConfirmation',
  'searchingDriver',
  'driverAssigned',
  'rideTracking',
  'tripCompleted',
  'rideRating',
];

/** The booking flow in the order the passenger walks through it. */
export const BOOKING_FLOW_ROUTES: readonly AppRoute[] = [
  'pickupSelection',
  'destinationSelection',
  'vehicleSelection',
  'fareDetails',
  'bookingConfirmation',
  'searchingDriver',
  'driverAssigned',
  'rideTracking',
  'tripCompleted',
  'rideRating',
];

/** The routes that show a ride that is still on its way. */
export const LIVE_RIDE_ROUTES: readonly AppRoute[] = [
  'searchingDriver',
  'driverAssigned',
  'rideTracking',
  'tripCompleted',
  'rideRating',
];

/** The paths of the booking routes. */
export const BOOKING_ROUTE_PATHS: readonly RoutePath[] = BOOKING_ROUTES.map((route) => ROUTES[route]);

/**
 * The first path segments a `returnTo` may point to.
 *
 * Only the protected routes are allowed, so a login redirect can never send
 * the passenger to an unknown or external page.
 */
export const ALLOWED_RETURN_TO_SEGMENTS: readonly string[] = PROTECTED_ROUTES.map(
  (route) => ROUTES[route].split('/')[1],
).filter((segment): segment is string => segment.length > 0);

/** The title of every route. */
export const ROUTE_TITLES: Record<AppRoute, string> = {
  splash: 'E-GO',
  onboarding: 'Welcome to E-GO',
  onboarding2: 'Fast bike rides',
  onboarding3: 'Ride across Jhargram',
  login: 'Log in',
  createAccount: 'Create your account',
  register: 'Create your account',
  otp: 'Verify your number',
  profileSetup: 'Set up your profile',
  home: 'Where to?',
  pickupSelection: 'Set pickup point',
  destinationSelection: 'Where are you going?',
  savedPlaces: 'Saved places',
  vehicleSelection: 'Choose vehicle',
  fareDetails: 'Fare details',
  bookingConfirmation: 'Confirm booking',
  searchingDriver: 'Finding your driver',
  driverAssigned: 'Driver assigned',
  rideTracking: 'Ride tracking',
  tripCompleted: "You've arrived!",
  rideRating: 'Rate your ride',
  myRides: 'Your rides',
  rideDetails: 'Ride details',
  profile: 'Account',
  editProfile: 'Edit profile',
  paymentMethods: 'Payment methods',
  notifications: 'Notifications',
  helpSupport: 'Help & Support',
  settings: 'Settings',
  about: 'About E-GO',
  safety: 'Safety',
};

/** Title and short description of every route. */
export const ROUTE_METADATA: Record<AppRoute, { title: string; description?: string }> = {
  splash: { title: 'E-GO', description: 'Move your way.' },
  onboarding: {
    title: 'Welcome to E-GO',
    description: "Set your pickup, choose a vehicle, and ride - it's that simple.",
  },
  onboarding2: {
    title: 'Fast bike rides',
    description: 'Need to get somewhere quickly? A bike rider is just a tap away.',
  },
  onboarding3: {
    title: 'Ride across Jhargram',
    description: 'Book affordable Toto (E-Rickshaw) and Bike rides anywhere in Jhargram city.',
  },
  login: { title: 'Log in', description: 'Enter your phone number to continue.' },
  createAccount: {
    title: 'Create your account',
    description: 'Sign up to start booking TOTO & fast bike rides across India in seconds.',
  },
  register: {
    title: 'Create your account',
    description: 'Sign up to start booking TOTO & fast bike rides across India in seconds.',
  },
  otp: { title: 'Verify your number', description: 'Enter the 6-digit code sent to you.' },
  profileSetup: {
    title: 'Set up your profile',
    description: 'Tell us your name so drivers can find you.',
  },
  home: { title: 'Where to?', description: 'Set a pickup and choose your destination.' },
  pickupSelection: { title: 'Set pickup point', description: 'Choose where your ride starts.' },
  destinationSelection: {
    title: 'Where are you going?',
    description: 'Search a destination in Jhargram.',
  },
  savedPlaces: {
    title: 'Saved places',
    description: 'Save Home, Work and frequent destinations for faster booking.',
  },
  vehicleSelection: { title: 'Choose vehicle', description: 'Compare Bike and Toto fares.' },
  fareDetails: { title: 'Fare details', description: 'Your fare estimate for this route.' },
  bookingConfirmation: { title: 'Confirm booking', description: 'Check the ride before you confirm.' },
  searchingDriver: { title: 'Finding your driver', description: 'Looking for a nearby driver.' },
  driverAssigned: { title: 'Driver assigned', description: 'Your driver is on the way.' },
  rideTracking: { title: 'Ride tracking', description: 'Follow your ride on the map.' },
  tripCompleted: { title: "You've arrived!", description: 'Your trip is complete.' },
  rideRating: { title: 'Rate your ride', description: 'Tell us how your ride went.' },
  myRides: { title: 'Your rides', description: 'Your completed and cancelled rides.' },
  rideDetails: { title: 'Ride details', description: 'Fare, timeline and driver of this ride.' },
  profile: { title: 'Account', description: 'Your profile and everything around it.' },
  editProfile: { title: 'Edit profile', description: 'Update your name and email.' },
  paymentMethods: { title: 'Payment methods', description: 'Cash is the default demo method.' },
  notifications: { title: 'Notifications', description: 'Ride, payment and system updates.' },
  helpSupport: { title: 'Help & Support', description: 'Answers, safety and the local desk.' },
  settings: { title: 'Settings', description: 'Preferences, notifications and privacy.' },
  about: { title: 'About E-GO', description: 'Move your way - Jhargram.' },
  safety: { title: 'Safety', description: 'Emergency help and ride safety guidelines.' },
};

/** One group of the account navigation. */
export interface NavGroup {
  id: string;
  label: string;
  /** Icon key (mapped to a real icon by the UI layer). */
  icon: string;
  href: RoutePath;
}

/** The navigation groups of the account hub. */
export const NAV_GROUPS: readonly NavGroup[] = [
  { id: 'rides', label: 'Rides', icon: 'route', href: ROUTES.myRides },
  { id: 'activity', label: 'Activity', icon: 'bell', href: ROUTES.notifications },
  { id: 'account', label: 'Account', icon: 'user-round', href: ROUTES.profile },
  { id: 'support', label: 'Support', icon: 'life-buoy', href: ROUTES.helpSupport },
];

/** One entry of the bottom navigation. */
export interface BottomNavItem {
  id: string;
  label: string;
  /** Icon key (mapped to a real icon by the UI layer). */
  icon: string;
  href: RoutePath;
}

/** The bottom navigation of the mobile shell. */
export const BOTTOM_NAV: readonly BottomNavItem[] = [
  { id: 'home', label: 'Home', icon: 'home', href: ROUTES.home },
  { id: 'my-rides', label: 'My rides', icon: 'route', href: ROUTES.myRides },
  { id: 'book', label: 'Book', icon: 'plus', href: ROUTES.destinationSelection },
  { id: 'notifications', label: 'Notifications', icon: 'bell', href: ROUTES.notifications },
  { id: 'profile', label: 'Profile', icon: 'user-round', href: ROUTES.profile },
];

/**
 * True when a link points at the current page.
 *
 * A parent path stays active for its children (`/ride-details` for
 * `/ride-details/abc`), the root path does not (it is never "current").
 */
export function isActiveRoute(pathname: string, href: string): boolean {
  if (pathname === href) return true;
  if (href === '/') return false;
  return pathname.startsWith(`${href}/`);
}

/** True when a path belongs to the booking flow. */
export function isBookingRoute(pathname: string): boolean {
  return BOOKING_ROUTE_PATHS.some((path) => isActiveRoute(pathname, path));
}
