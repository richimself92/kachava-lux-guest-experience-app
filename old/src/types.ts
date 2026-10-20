export type ScreenId =
  | 'home'
  | 'transport'
  | 'personalize'
  | 'included'
  | 'explore'
  | 'yacht'
  | 'dining'
  | 'stock-villa'
  | 'concierge'
  | 'midstay'
  | 'departure'
  | 'philosophy'
  | 'profile';

export type MainTab = 'home' | 'my-stay' | 'explore' | 'concierge';

export interface FlightDetails {
  arrivalAirport: string;
  airline: string;
  flightNumber: string;
  estimatedLanding: string;
  partySize: number;
  luggageChecked: number;
  luggageCarryOn: number;
  status: 'Confirmed' | 'Driver Assign' | 'En Route' | 'At Bay 4';
  assignedDriver: string;
}

export interface LarderItem {
  id: string;
  name: string;
  origin: string;
  description: string;
  price: number;
  category: 'fruit' | 'elixirs' | 'cellar' | 'bakery' | 'snacks' | 'recovery';
  quantity: number;
  image: string;
  tag?: string;
  dietary?: string;
  storageType?: string;
}

export interface ExperienceItem {
  id: string;
  title: string;
  subtitle: string;
  duration: string;
  location: string;
  vehicleOrDetail?: string;
  priceText: string;
  isIncluded: boolean;
  inclusionLabel?: string;
  image: string;
  category: string;
  description: string;
  amenities?: string[];
  actionLabel?: string;
  actionScreen?: ScreenId;
}

export type RequestProgressStatus = 'Requested' | 'Assigned' | 'In Progress' | 'Completed';

export interface ServiceRequest {
  id: string;
  title: string;
  category?: string;
  time: string;
  location?: string;
  status: RequestProgressStatus;
  currentStep: 1 | 2 | 3 | 4;
  assignedTo: string;
  details?: string;
  notes?: string;
  photoUrl?: string;
  isCompleted?: boolean;
}

export interface YachtCharterPackage {
  id: 'half-day' | 'extended' | 'full-day' | 'custom';
  title: string;
  tagline: string;
  durationHours: number;
  durationLabel: string;
  valuationUSD: number;
  isIncludedWithStay: boolean;
  priceLabel: string;
  description: string;
  highlights: string[];
  suggestedPaths: string;
  idealFor: string;
}

export interface NavigableDestination {
  id: 'isla-mujeres' | 'isla-contoy' | 'miami';
  title: string;
  region: string;
  badge: string;
  image: string;
  subtitle: string;
  description: string;
  highlights: string[];
  duration: string;
}

export interface YachtVesselSpecs {
  model: string;
  tagline: string;
  overallLength: string;
  beam: string;
  beachModeBeam: string;
  capacity: string;
  accommodations: string;
  engines: string;
  refinement: string;
  marinaHome: string;
}

