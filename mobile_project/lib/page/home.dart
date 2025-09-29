import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'subjects/list.dart';
import 'subjects/subject_detail.dart';



// กำหนดสีเป็น global const
const Color emerald = Color(0xFF10B981);


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final pb = PocketBase('http://127.0.0.1:8090');
  late final RecordService _service;
  final ScrollController _scrollController = ScrollController();
  final List<RecordModel> _topSubjects = [];
  bool _isLoading = false;
  Timer? _refreshTimer;

  late AnimationController _sparkleAnimationController;
  late AnimationController _floatingAnimationController;
  late AnimationController _welcomeAnimationController;
  
  late Animation<double> _sparkleAnimation;
  late Animation<double> _floatingAnimation;
  late Animation<Offset> _welcomeSlideAnimation;
  late Animation<double> _welcomeFadeAnimation;

  @override
  void initState() {
    super.initState();
    _service = pb.collection('subject');
    
    // Initialize animations
    _sparkleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    )..repeat();
    
    _floatingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    
    _welcomeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleAnimationController,
      curve: Curves.easeInOut,
    ));

    _floatingAnimation = Tween<double>(
      begin: 0.0,
      end: 15.0,
    ).animate(CurvedAnimation(
      parent: _floatingAnimationController,
      curve: Curves.easeInOut,
    ));

    _welcomeSlideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOutBack,
    ));

    _welcomeFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _welcomeAnimationController,
      curve: Curves.easeOut,
    ));

    _fetchTopSubjects();
    _startRealtimeUpdates();
    _welcomeAnimationController.forward();
  }

  void _startRealtimeUpdates() {
    // อัปเดตข้อมูลทุก 2 วินาที
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchTopSubjectsQuietly();
    });
  }

  Future<void> _fetchTopSubjectsQuietly() async {
    // ดึงข้อมูลใหม่โดยไม่แสดง loading
    try {
      final result = await _service.getList(
        page: 1, 
        perPage: 10, 
        sort: "-created"
      );
      
      // เปรียบเทียบข้อมูลใหม่กับเก่า
      if (_hasDataChanged(result.items)) {
        setState(() {
          _topSubjects
            ..clear()
            ..addAll(result.items);
        });
        print("Home data updated: ${result.items.length} subjects");
      }
    } catch (e) {
      print('Silent refresh error: $e');
    }
  }

  bool _hasDataChanged(List<RecordModel> newData) {
    if (newData.length != _topSubjects.length) {
      return true;
    }
    
    for (int i = 0; i < newData.length; i++) {
      final newItem = newData[i];
      final existingItem = _topSubjects.length > i ? _topSubjects[i] : null;
      
      if (existingItem == null || 
          newItem.id != existingItem.id ||
          newItem.updated != existingItem.updated) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> _fetchTopSubjects() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final result = await _service.getList(
        page: 1, 
        perPage: 10, 
        sort: "-created"
      );
      setState(() {
        _topSubjects
          ..clear()
          ..addAll(result.items);
      });
    } catch (e) {
      print("Error fetching top subjects: $e");
    }
    
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _sparkleAnimationController.dispose();
    _floatingAnimationController.dispose();
    _welcomeAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + 200,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _navigateToSubjectDetail(RecordModel subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectDetailPage(subject: subject),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.5, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFFFFF0F5), // Lavender blush
              Color(0xFFFAF5FF), // Light purple
              Color(0xFFF8FAFC), // Very light gray
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                        Color(0xFF7C3AED),
                        Color(0xFFFF6B9D),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Sparkle animation background
                      ...List.generate(20, (index) {
                        return AnimatedBuilder(
                          animation: _sparkleAnimation,
                          builder: (context, child) {
                            final sparkleOffset = (_sparkleAnimation.value + index * 0.1) % 1.0;
                            return Positioned(
                              left: (index * 60 + 30) % width,
                              top: 20 + (sparkleOffset * 120),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white.withOpacity(0.5),
                                size: 8 + (index % 4) * 3,
                              ),
                            );
                          },
                        );
                      }),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              AnimatedBuilder(
                                animation: _floatingAnimation,
                                builder: (context, child) {
                                  return Transform.translate(
                                    offset: Offset(0, -_floatingAnimation.value / 3),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withOpacity(0.3),
                                            Colors.white.withOpacity(0.15),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.5),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.castle_rounded,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Princess Academy',
                                      style: GoogleFonts.prompt(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        fontSize: 24,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 15.0,
                                            color: Colors.black.withOpacity(0.4),
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'รายวิชาของเจ้าหญิง',
                                      style: GoogleFonts.prompt(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 8.0,
                                            color: Colors.black.withOpacity(0.3),
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Realtime indicator (รักษาไว้)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    emerald.withOpacity(0.9), // ✅ ใช้ emerald global
                                    Colors.green.withOpacity(0.7),
                                  ],
                                ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'LIVE',
                                      style: GoogleFonts.prompt(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white, Color(0xFFFAF5FF)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => SubjectListPage()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    label: Text(
                      'รายวิชาทั้งหมด',
                      style: GoogleFonts.prompt(
                        color: const Color(0xFF2D1B69),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : width * 0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      
                      // Welcome section
                      SlideTransition(
                        position: _welcomeSlideAnimation,
                        child: FadeTransition(
                          opacity: _welcomeFadeAnimation,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(25),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFFFFF),
                                  Color(0xFFFAF5FF),
                                  Color(0xFFF3E8FF),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: const Color(0xFFFF6B9D).withOpacity(0.3),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.8),
                                  blurRadius: 15,
                                  offset: const Offset(-8, -8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                AnimatedBuilder(
                                  animation: _floatingAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -_floatingAnimation.value / 2),
                                      child: Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                                          ),
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF7C3AED).withOpacity(0.4),
                                              blurRadius: 15,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.auto_stories_rounded,
                                          color: Colors.white,
                                          size: 35,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ยินดีต้อนรับสู่วิทยาลัยเจ้าหญิง! 👑',
                                        style: GoogleFonts.prompt(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF2D1B69),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'จัดการหลักสูตรและรายวิชาของท่านเจ้าหญิงได้อย่างสง่างาม',
                                        style: GoogleFonts.prompt(
                                          fontSize: 15,
                                          color: const Color(0xFF64748B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Top Subjects Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 35, 20, 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'รายวิชาเจ้าหญิง',
                                          style: GoogleFonts.prompt(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF2D1B69),
                                          ),
                                        ),

                                      

                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              emerald.withOpacity(0.2),
                                              Colors.green.withOpacity(0.1),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: emerald.withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 6,
                                              height: 6,
                                              decoration: const BoxDecoration(
                                                color: emerald,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'อัปเดตสด',
                                              style: GoogleFonts.prompt(
                                                color: Color(0xFF047857), // emerald shade700 (#047857)
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )

                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFFAF5FF)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_back_ios_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: _scrollLeft,
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(10),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      onPressed: _scrollRight,
                                      style: IconButton.styleFrom(
                                        padding: const EdgeInsets.all(10),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Subject Cards
                      SizedBox(
                        height: isMobile ? 260 : 280,
                        child: _isLoading
                            ? Center(
                                child: Container(
                                  padding: const EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.white, Color(0xFFFAF5FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Color(0xFF7C3AED),
                                        ),
                                        strokeWidth: 3,
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        'กำลังโหลดรายวิชา...',
                                        style: GoogleFonts.prompt(
                                          color: const Color(0xFF64748B),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _topSubjects.isEmpty
                                ? Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 20),
                                      padding: const EdgeInsets.all(30),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Colors.white, Color(0xFFFAF5FF)],
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: const Color(0xFFFF6B9D).withOpacity(0.3),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                                            blurRadius: 15,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(20),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.auto_stories_rounded,
                                              size: 40,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            'ยังไม่มีรายวิชา',
                                            style: GoogleFonts.prompt(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF2D1B69),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'กดปุ่ม "รายวิชาทั้งหมด" เพื่อเพิ่มรายวิชาใหม่',
                                            style: GoogleFonts.prompt(
                                              fontSize: 14,
                                              color: const Color(0xFF64748B),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: _scrollController,
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    itemCount: _topSubjects.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(width: 18),
                                    itemBuilder: (context, index) {
                                      final subject = _topSubjects[index];
                                      return Container(
                                        width: isMobile ? 160 : 180,
                                        child: GestureDetector(
                                          onTap: () => _navigateToSubjectDetail(subject),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [Colors.white, Color(0xFFFAF5FF)],
                                              ),
                                              borderRadius: BorderRadius.circular(22),
                                              border: Border.all(
                                                color: const Color(0xFFFF6B9D).withOpacity(0.2),
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF7C3AED).withOpacity(0.15),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 8),
                                                ),
                                                BoxShadow(
                                                  color: Colors.white.withOpacity(0.8),
                                                  blurRadius: 10,
                                                  offset: const Offset(-6, -6),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: isMobile ? 120 : 130,
                                                  decoration: const BoxDecoration(
                                                    borderRadius: BorderRadius.vertical(
                                                        top: Radius.circular(20)),
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                      colors: [
                                                        Color(0xFFF3E8FF),
                                                        Color(0xFFFFE4F2),
                                                      ],
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: const BorderRadius.vertical(
                                                            top: Radius.circular(20)),
                                                        child: subject.data['imageUrl'] != null && 
                                                               subject.data['imageUrl'].toString().isNotEmpty
                                                            ? Image.network(
                                                                subject.data['imageUrl'],
                                                                height: double.infinity,
                                                                width: double.infinity,
                                                                fit: BoxFit.cover,
                                                                errorBuilder: (context, error, stackTrace) {
                                                                  return Container(
                                                                    height: double.infinity,
                                                                    width: double.infinity,
                                                                    child: Icon(
                                                                      _getSubjectIcon(subject.data['name'] ?? ''),
                                                                      size: 45,
                                                                      color: const Color(0xFF7C3AED),
                                                                    ),
                                                                  );
                                                                },
                                                              )
                                                            : Container(
                                                                height: double.infinity,
                                                                width: double.infinity,
                                                                child: Icon(
                                                                  _getSubjectIcon(subject.data['name'] ?? ''),
                                                                  size: 45,
                                                                  color: const Color(0xFF7C3AED),
                                                                ),
                                                              ),
                                                      ),
                                                      Positioned(
                                                        top: 10,
                                                        right: 10,
                                                        child: Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            gradient: const LinearGradient(
                                                              colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                                                            ),
                                                            borderRadius: BorderRadius.circular(15),
                                                            boxShadow: [
                                                              BoxShadow(
                                                                color: const Color(0xFF7C3AED).withOpacity(0.4),
                                                                blurRadius: 8,
                                                                offset: const Offset(0, 3),
                                                              ),
                                                            ],
                                                          ),
                                                          child: const Icon(
                                                            Icons.touch_app_rounded,
                                                            color: Colors.white,
                                                            size: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        subject.data['name'] ?? '',
                                                        style: GoogleFonts.prompt(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: const Color(0xFF2D1B69),
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 6,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              const Color(0xFF7C3AED).withOpacity(0.2),
                                                              const Color(0xFFFF6B9D).withOpacity(0.1),
                                                            ],
                                                          ),
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(
                                                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          'รหัส: ${subject.data['code'] ?? 'N/A'}',
                                                          style: GoogleFonts.prompt(
                                                            color: const Color(0xFF2D1B69),
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                      ),
                      const SizedBox(height: 35),
                      
                      // Status section
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFAF5FF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFFFF6B9D).withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'ข้อมูลอัปเดตสดทุก 2 วินาที • วิชาทั้งหมด ${_topSubjects.length} วิชา',
                                style: GoogleFonts.prompt(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getSubjectIcon(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('คณิต') || name.contains('math')) {
      return Icons.calculate_rounded;
    } else if (name.contains('วิทย') || name.contains('science')) {
      return Icons.science_rounded;
    } else if (name.contains('ไทย') || name.contains('thai')) {
      return Icons.language_rounded;
    } else if (name.contains('อังกฤษ') || name.contains('english')) {
      return Icons.translate_rounded;
    } else if (name.contains('สังคม') || name.contains('social')) {
      return Icons.public_rounded;
    } else if (name.contains('ประวัติ') || name.contains('history')) {
      return Icons.history_edu_rounded;
    } else if (name.contains('ศิลป') || name.contains('art')) {
      return Icons.palette_rounded;
    } else if (name.contains('ดนตรี') || name.contains('music')) {
      return Icons.music_note_rounded;
    } else if (name.contains('กีฬา') || name.contains('sport')) {
      return Icons.sports_rounded;
    } else {
      return Icons.auto_stories_rounded;
    }
  }
}