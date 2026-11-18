/// FAQ model and data for E-GO Help & Support.
enum FaqCategory {
  rides('Rides & Booking'),
  payments('Payments & Fare'),
  account('Account & Profile'),
  safety('Safety & Emergency');

  const FaqCategory(this.label);
  final String label;
}

class SupportFaq {
  const SupportFaq({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.keywords,
  });

  final String id;
  final String question;
  final String answer;
  final FaqCategory category;
  final List<String> keywords;

  bool matches(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    if (question.toLowerCase().contains(q)) return true;
    if (answer.toLowerCase().contains(q)) return true;
    if (category.label.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}

/// Official 7 FAQs matching the E-GO specification and HTML reference.
const List<SupportFaq> kSupportFaqs = [
  SupportFaq(
    id: 'faq_1',
    question: 'How do I book a ride?',
    answer:
        'Open the app, enter your destination, choose a vehicle (Bike or Toto), and confirm your booking. A nearby verified Jhargram driver will be matched to you instantly.',
    category: FaqCategory.rides,
    keywords: [
      'how',
      'do',
      'i',
      'book',
      'a',
      'ride',
      'toto',
      'bike',
      'request',
      'destination',
      'booking',
    ],
  ),
  SupportFaq(
    id: 'faq_2',
    question: 'How is the fare calculated?',
    answer:
        'Fares are based on distance and vehicle type. Bike rides start at ₹20 + ₹10/km. Toto rides start at ₹15 + ₹7/km. Transparent meter pricing with no hidden surcharges.',
    category: FaqCategory.payments,
    keywords: [
      'how',
      'is',
      'fare',
      'calculated',
      'toto',
      'bike',
      'price',
      'rates',
      'charges',
      'km',
      'distance',
      'payment',
    ],
  ),
  SupportFaq(
    id: 'faq_3',
    question: 'Can I cancel a ride?',
    answer:
        'Yes, you can cancel freely before the driver arrives at your pickup point. Once the trip starts, cancellation is disabled to ensure community driver fairness.',
    category: FaqCategory.rides,
    keywords: [
      'can',
      'i',
      'cancel',
      'a',
      'ride',
      'cancellation',
      'policy',
      'fee',
      'charges',
    ],
  ),
  SupportFaq(
    id: 'faq_4',
    question: 'What payment methods are accepted?',
    answer:
        'Currently cash is accepted directly to the driver upon destination arrival. UPI and QR code payments are being piloted across Jhargram and rolling out soon.',
    category: FaqCategory.payments,
    keywords: [
      'what',
      'payment',
      'methods',
      'are',
      'accepted',
      'cash',
      'upi',
      'phonepe',
      'gpay',
      'payment',
      'fare',
    ],
  ),
  SupportFaq(
    id: 'faq_5',
    question: 'How do I contact my driver?',
    answer:
        'Once a driver is matched, tap the phone or chat icon on your active ride screen to coordinate pickup instructions securely without sharing private numbers.',
    category: FaqCategory.rides,
    keywords: [
      'how',
      'do',
      'i',
      'contact',
      'my',
      'driver',
      'phone',
      'call',
      'chat',
      'number',
      'safety',
    ],
  ),
  SupportFaq(
    id: 'faq_6',
    question: 'What is a Toto?',
    answer:
        'A Toto is an eco-friendly electric rickshaw (E-Rickshaw) seating up to 3 passengers. It is Jhargram\'s most loved, silent, and affordable local commute option.',
    category: FaqCategory.rides,
    keywords: [
      'what',
      'is',
      'a',
      'toto',
      'e-rickshaw',
      'electric',
      'three',
      'wheeler',
      'capacity',
      'passengers',
      'jhargram',
    ],
  ),
  SupportFaq(
    id: 'faq_7',
    question: 'Is E-GO available 24/7?',
    answer:
        'E-GO operates daily from 6:00 AM to 10:00 PM throughout Jhargram municipal areas. Operating hours will expand as nighttime driver availability increases.',
    category: FaqCategory.rides,
    keywords: [
      'is',
      'e-go',
      'available',
      '24/7',
      'hours',
      'operation',
      'timing',
      'schedule',
      'jhargram',
      'night',
      'timing',
    ],
  ),
];
