import 'package:flutter/material.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/features/support/domain/support_faq.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens (matches HTML reference + DESIGN(20261117-025445).md)
// ─────────────────────────────────────────────────────────────────────────────
const Color _kBackground = Color(0xFFF5F7FA);
const Color _kNavy = Color(0xFF142B45);
const Color _kYellow = Color(0xFFFFC928);
const Color _kWhite = Color(0xFFFFFFFF);
const Color _kBorder = Color(0xFFE5EAF0);
const Color _kBorderSubtle = Color(0xFFE7EAF0);
const Color _kMuted = Color(0xFF8490A0);
const Color _kIconBg = Color(0xFFF5F7FA);

const String _kFontInter = 'Inter';
const String _kFontManrope = 'Manrope';

/// E-GO Help & Support screen.
/// Native Flutter implementation of the reference specification.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _faqSectionKey = GlobalKey();

  String _searchQuery = '';
  String? _expandedFaqId;
  FaqCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      // If user is searching text, clear category filter
      if (_searchQuery.isNotEmpty) {
        _selectedCategory = null;
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedCategory = null;
    });
  }

  void _filterByTopic(FaqCategory category, String searchKeyword) {
    setState(() {
      _selectedCategory = category;
      _searchController.text = searchKeyword;
      _searchQuery = searchKeyword;
    });
    // Smoothly scroll down to FAQ section
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _faqSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _toggleFaq(String id) {
    setState(() {
      if (_expandedFaqId == id) {
        _expandedFaqId = null;
      } else {
        _expandedFaqId = id;
      }
    });
  }

  List<SupportFaq> get _filteredFaqs {
    return kSupportFaqs.where((faq) {
      if (_selectedCategory != null && faq.category != _selectedCategory) {
        return false;
      }
      return faq.matches(_searchQuery);
    }).toList();
  }

  void _openContactModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ContactSupportBottomSheet(),
    );
  }

  void _openSafetyCenterModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _SafetyCenterBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _filteredFaqs;

    return Scaffold(
      backgroundColor: _kBackground,
      // ── 1. Top App Bar ────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: _kWhite,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _kNavy, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: 'Go back',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: _kFontManrope,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kNavy,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: _kNavy, size: 22),
            onPressed: _openContactModal,
            tooltip: 'Contact options',
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Divider(
            height: 1.0,
            thickness: 1.0,
            color: _kBorderSubtle,
          ),
        ),
      ),
      // ── Main Scrollable Content ───────────────────────────────────────────
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 2. Introduction ─────────────────────────────────────────────
            const Text(
              'How can we help?',
              style: TextStyle(
                fontFamily: _kFontManrope,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _kNavy,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Find answers, report trip issues, or contact local support in E-GO',
              style: TextStyle(
                fontFamily: _kFontInter,
                fontSize: 14,
                color: _kMuted,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),

            // ── 3. Search Bar ───────────────────────────────────────────────
            _buildSearchBar(),

            const SizedBox(height: 16),

            // ── 4. Browse by Topic ──────────────────────────────────────────
            const Text(
              'Browse by topic',
              style: TextStyle(
                fontFamily: _kFontManrope,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _kNavy,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 8),
            _buildBrowseByTopicCard(),

            const SizedBox(height: 20),

            // ── 5. Frequently Asked Questions ───────────────────────────────
            KeyedSubtree(
              key: _faqSectionKey,
              child: const Text(
                'Frequently asked questions',
                style: TextStyle(
                  fontFamily: _kFontManrope,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // FAQ List or Empty State
            if (filteredFaqs.isEmpty)
              _buildEmptySearchResults()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredFaqs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final faq = filteredFaqs[index];
                  final isExpanded = _expandedFaqId == faq.id;
                  return _FaqAccordionCard(
                    faq: faq,
                    isExpanded: isExpanded,
                    onTap: () => _toggleFaq(faq.id),
                  );
                },
              ),

            const SizedBox(height: 24),

            // ── 6. Still Need Help? Card ────────────────────────────────────
            _buildStillNeedHelpCard(),
          ],
        ),
      ),
    );
  }

  // ── Search Bar Widget ─────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05142B45),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: _kMuted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(
                fontFamily: _kFontInter,
                fontSize: 14,
                color: _kNavy,
              ),
              decoration: const InputDecoration(
                hintText: 'Search for help, topics, or FAQs...',
                hintStyle: TextStyle(
                  fontFamily: _kFontInter,
                  fontSize: 14,
                  color: _kMuted,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: _kMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Browse by Topic Grouped Card ──────────────────────────────────────────
  Widget _buildBrowseByTopicCard() {
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08142B45),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          children: [
            _TopicTile(
              icon: Icons.electric_rickshaw_outlined,
              title: 'Rides & Booking',
              onTap: () => _filterByTopic(FaqCategory.rides, 'book'),
            ),
            const Divider(height: 1, thickness: 1, indent: 64, color: _kBorderSubtle),
            _TopicTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Payments & Fare',
              onTap: () => _filterByTopic(FaqCategory.payments, 'payment'),
            ),
            const Divider(height: 1, thickness: 1, indent: 64, color: _kBorderSubtle),
            _TopicTile(
              icon: Icons.person_outline_rounded,
              title: 'Account & Profile',
              onTap: () => _filterByTopic(FaqCategory.account, 'account'),
            ),
            const Divider(height: 1, thickness: 1, indent: 64, color: _kBorderSubtle),
            _TopicTile(
              icon: Icons.shield_outlined,
              title: 'Safety & Emergency',
              onTap: _openSafetyCenterModal,
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty Search Results State ────────────────────────────────────────────
  Widget _buildEmptySearchResults() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.0),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: _kIconBg,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off,
              color: _kMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No matching topics found',
            style: TextStyle(
              fontFamily: _kFontManrope,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No topics matching "$_searchQuery". Try another keyword or contact desk.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: _kFontInter,
              fontSize: 12,
              color: _kMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _clearSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kIconBg,
              foregroundColor: _kNavy,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            child: const Text(
              'Reset search',
              style: TextStyle(
                fontFamily: _kFontInter,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Still Need Help? Card ─────────────────────────────────────────────────
  Widget _buildStillNeedHelpCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06142B45),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.headset_mic_outlined, color: _kNavy, size: 20),
              SizedBox(width: 8),
              Text(
                'Still need help?',
                style: TextStyle(
                  fontFamily: _kFontManrope,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Our local customer care team is available to assist you.',
            style: TextStyle(
              fontFamily: _kFontInter,
              fontSize: 13,
              color: _kMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _openContactModal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kYellow,
                foregroundColor: _kNavy,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.chat_bubble_outline_rounded, size: 18, color: _kNavy),
                  SizedBox(width: 8),
                  Text(
                    'Contact support',
                    style: TextStyle(
                      fontFamily: _kFontManrope,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Topic Tile Component
// ─────────────────────────────────────────────────────────────────────────────
class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _kIconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _kNavy, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: _kFontInter,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kNavy,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _kMuted,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ Accordion Card
// ─────────────────────────────────────────────────────────────────────────────
class _FaqAccordionCard extends StatelessWidget {
  const _FaqAccordionCard({
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  final SupportFaq faq;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04142B45),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: const TextStyle(
                            fontFamily: _kFontInter,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kNavy,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kMuted,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity, height: 0),
                    secondChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: _kBorderSubtle,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          faq.answer,
                          style: const TextStyle(
                            fontFamily: _kFontInter,
                            fontSize: 13,
                            color: _kMuted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Support Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _ContactSupportBottomSheet extends StatefulWidget {
  const _ContactSupportBottomSheet();

  @override
  State<_ContactSupportBottomSheet> createState() =>
      _ContactSupportBottomSheetState();
}

class _ContactSupportBottomSheetState
    extends State<_ContactSupportBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tripRefController = TextEditingController(
    text: 'Electric TOTO · Yesterday 5:40 PM (₹25)',
  );
  final TextEditingController _detailsController = TextEditingController();

  String _selectedCategory = 'fare';
  bool _isSubmitting = false;

  final List<Map<String, String>> _categories = const [
    {'value': 'fare', 'label': 'Fare & Payment Adjustment'},
    {'value': 'lost', 'label': 'Lost Item in Toto'},
    {'value': 'ride', 'label': 'Ride & Driver Behavior'},
    {'value': 'account', 'label': 'Account & Phone Number'},
    {'value': 'safety', 'label': 'Safety or Routing Concern'},
  ];

  @override
  void dispose() {
    _tripRefController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your request (Ref #EG-4203) has been logged with Jhargram Operations. An agent will reply shortly.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _kBorderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Customer Care',
                      style: TextStyle(
                        fontFamily: _kFontManrope,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _kNavy,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Jhargram Help Desk · 6 AM – 10 PM',
                      style: TextStyle(
                        fontFamily: _kFontInter,
                        fontSize: 12,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _kIconBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: _kMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _kBorderSubtle),
            const SizedBox(height: 16),

            // Quick Contact Channels
            Row(
              children: [
                Expanded(
                  child: _ContactChannelTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Live Chat',
                    subtitle: '< 2 min wait',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Connecting to live Jhargram support agent (Demo simulation)...',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ContactChannelTile(
                    icon: Icons.phone_outlined,
                    label: 'Call Desk',
                    subtitle: 'Toll-free voice',
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('E-GO Support Call Desk'),
                          content: const Text(
                            'Local Jhargram Toll-Free Support: 1800-EGO-CARE\n\n'
                            '(Voice dispatch simulation in demo environment)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Support Form
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Issue Category',
                    style: TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder, width: 1.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _kMuted,
                          size: 20,
                        ),
                        items: _categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c['value'],
                            child: Text(
                              c['label']!,
                              style: const TextStyle(
                                fontFamily: _kFontInter,
                                fontSize: 13,
                                color: _kNavy,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Trip Reference',
                    style: TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _kWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _kBorder, width: 1.0),
                    ),
                    alignment: Alignment.centerLeft,
                    child: TextField(
                      controller: _tripRefController,
                      style: const TextStyle(
                        fontFamily: _kFontInter,
                        fontSize: 13,
                        color: _kNavy,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: const [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontFamily: _kFontInter,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kNavy,
                        ),
                      ),
                      Text(
                        ' *',
                        style: TextStyle(
                          fontFamily: _kFontInter,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _detailsController,
                    maxLines: 3,
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please provide details about your issue';
                      }
                      return null;
                    },
                    style: const TextStyle(
                      fontFamily: _kFontInter,
                      fontSize: 13,
                      color: _kNavy,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Please describe what happened...',
                      hintStyle: const TextStyle(
                        fontFamily: _kFontInter,
                        fontSize: 13,
                        color: _kMuted,
                      ),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _kNavy, width: 1.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kIconBg,
                              foregroundColor: _kNavy,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontFamily: _kFontManrope,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kYellow,
                              foregroundColor: _kNavy,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _kNavy,
                                    ),
                                  )
                                : const Text(
                                    'Send request',
                                    style: TextStyle(
                                      fontFamily: _kFontManrope,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _kNavy,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactChannelTile extends StatelessWidget {
  const _ContactChannelTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kIconBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorderSubtle, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _kNavy, size: 22),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: _kFontInter,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: _kFontInter,
                  fontSize: 11,
                  color: _kMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Safety Center Information Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SafetyCenterBottomSheet extends StatelessWidget {
  const _SafetyCenterBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.shield_outlined, color: _kNavy, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'E-GO Safety Center',
                    style: TextStyle(
                      fontFamily: _kFontManrope,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _kNavy,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: _kIconBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18, color: _kMuted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kBorderSubtle),
          const SizedBox(height: 14),

          _SafetyPointRow(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF059669),
            title: '100% Verified Toto Drivers',
            desc:
                'Every driver is registered with Jhargram municipality identification and permit.',
          ),
          const SizedBox(height: 12),
          _SafetyPointRow(
            icon: Icons.share_location_outlined,
            iconColor: _kNavy,
            title: 'Live Route Sharing',
            desc:
                'Share active ride location with family with one tap from the active booking screen.',
          ),
          const SizedBox(height: 12),
          _SafetyPointRow(
            icon: Icons.emergency_outlined,
            iconColor: Colors.red,
            title: 'Jhargram Police Hotline',
            desc:
                'For any immediate roadside emergency, dial 112.',
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kIconBg,
                      foregroundColor: _kNavy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: _kFontManrope,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, EGoRouter.safety);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Open Safety Center',
                      style: TextStyle(
                        fontFamily: _kFontManrope,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetyPointRow extends StatelessWidget {
  const _SafetyPointRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final Color? iconColor;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor ?? _kNavy, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: const TextStyle(
                fontFamily: _kFontInter,
                fontSize: 13,
                color: _kMuted,
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kNavy,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
