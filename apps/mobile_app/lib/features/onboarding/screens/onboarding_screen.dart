import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController(viewportFraction: 1.0);
  double _pageOffset = 0.0;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'icon': Icons.shield_outlined,
      'isImage': true,
      'title': 'Welcome to ISUFST GSO',
      'body':
          'Your professional portal for the General Services Office at ISUFST Dingle Campus.',
    },
    {
      'icon': Icons.inventory_2_outlined,
      'isImage': false,
      'title': 'Smart Inventory',
      'body':
          'Track and manage campus assets in real-time with our streamlined inventory system.',
    },
    {
      'icon': Icons.build_circle_outlined,
      'isImage': false,
      'title': 'Maintenance Made Easy',
      'body':
          'Report facility issues and track repair progress right from your pocket.',
    },
    {
      'icon': Icons.assignment_return_outlined,
      'isImage': false,
      'title': 'Borrow with Ease',
      'body':
          'Request equipment for school activities and manage returns with just a few taps.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF001A33), // Deep Navy background
      body: Stack(
        children: [
          // Parallax Background Orbs
          Positioned(
            top: -100 + (_pageOffset * 50),
            right: -50 - (_pageOffset * 30),
            child: _buildGlowOrb(const Color(0xFF003D62), 300),
          ),
          Positioned(
            bottom: -50 - (_pageOffset * 40),
            left: -100 + (_pageOffset * 60),
            child: _buildGlowOrb(const Color(0xFF2A80AF).withOpacity(0.5), 250),
          ),

          // Main PageView
          SafeArea(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return _OnboardingPage(
                  pageData: _pages[index],
                  pageIndex: index,
                  pageOffset: _pageOffset - index,
                  isActive: index == _currentPage,
                );
              },
            ),
          ),

          // Top Right Controls
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: _completeOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    const Color(0xFF001A33),
                    const Color(0xFF001A33).withOpacity(0.0),
                  ],
                ),
              ),
              child: _currentPage == _pages.length - 1
                  ? _buildGetStartedButton()
                  : _buildNavigationControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back Button
        AnimatedOpacity(
          opacity: _currentPage > 0 ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IconButton(
            onPressed: _currentPage > 0 ? _prevPage : null,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ),

        // Dots Indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            _pages.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF4DB6FF)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),

        // Next Button
        IconButton(
          onPressed: _nextPage,
          icon: const Icon(Icons.arrow_forward, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF4DB6FF).withOpacity(0.2),
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildGetStartedButton() {
    return AnimatedOpacity(
      opacity: _currentPage == _pages.length - 1 ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A80AF), Color(0xFF0061A3)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4DB6FF).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _completeOnboarding,
            borderRadius: BorderRadius.circular(16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  'Get Started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatefulWidget {
  final Map<String, dynamic> pageData;
  final int pageIndex;
  final double pageOffset;
  final bool isActive;

  const _OnboardingPage({
    required this.pageData,
    required this.pageIndex,
    required this.pageOffset,
    required this.isActive,
  });

  @override
  State<_OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<_OnboardingPage>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _floatController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _entranceController, curve: Curves.easeOutCubic),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    if (widget.isActive) {
      _entranceController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _OnboardingPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _entranceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double textOffset = widget.pageOffset * 50;
    final double cardOffset = widget.pageOffset * 30;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 3D Card
          Transform.translate(
            offset: Offset(cardOffset, 0),
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, child) {
                final floatY = math.sin(_floatController.value * math.pi) * 8;
                return Transform.translate(
                  offset: Offset(0, floatY),
                  child: _build3DCard(),
                );
              },
            ),
          ),
          const SizedBox(height: 64),

          // Title
          Transform.translate(
            offset: Offset(textOffset, 0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.pageData['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Body Text
          Transform.translate(
            offset: Offset(textOffset * 1.2, 0),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  widget.pageData['body'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 80), // Space for bottom controls
        ],
      ),
    );
  }

  Widget _build3DCard() {
    // 3D Perspective Transform Matrix
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.001) // perspective
      ..rotateX(widget.pageOffset * 0.2)
      ..rotateY(-widget.pageOffset * 0.4);

    return Transform(
      transform: matrix,
      alignment: FractionalOffset.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shadow/Glow layer
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4DB6FF).withOpacity(0.3),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Glass Card Layer
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0A4D7A).withOpacity(0.8),
                      const Color(0xFF002D4D).withOpacity(0.6),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: widget.pageData['isImage']
                      ? Image.asset(
                          'assets/images/logo.png',
                          width: 100,
                          height: 100,
                        )
                      : Icon(
                          widget.pageData['icon'],
                          size: 72,
                          color: Colors.white,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
