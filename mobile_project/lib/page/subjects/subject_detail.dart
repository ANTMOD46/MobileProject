import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';

class SubjectDetailPage extends StatefulWidget {
  final RecordModel subject;

  const SubjectDetailPage({super.key, required this.subject});

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late AnimationController _sparkleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2200),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimations = List.generate(5, (index) {
      return Tween<Offset>(
        begin: const Offset(0.0, 0.6),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardAnimationController,
        curve: Interval(
          index * 0.08,
          0.4 + index * 0.12,
          curve: Curves.easeOutBack,
        ),
      ));
    });

    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFCE4EC), // Light pink
              Color(0xFFF8BBD0), // Pink
              Color(0xFFFFCDD2), // Rose pink
              Color(0xFFFFE0E8), // Blush pink
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      const Color(0xFFFFF0F5).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFF69B4).withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFD81B60), size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        widget.subject.data['name'] ?? 'Unknown Subject',
                        style: GoogleFonts.prompt(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 18,
                          shadows: [
                            Shadow(
                              blurRadius: 15.0,
                              color: const Color(0xFFFF69B4).withOpacity(0.8),
                              offset: const Offset(0, 2),
                            ),
                            const Shadow(
                              blurRadius: 8.0,
                              color: Color(0xFFD81B60),
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Princess gradient background
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFF69B4), // Hot pink
                            Color(0xFFFF85C0), // Light hot pink
                            Color(0xFFFFB3D9), // Baby pink
                            Color(0xFFFFC0DB), // Cotton candy pink
                          ],
                        ),
                      ),
                    ),
                    // Sparkle overlay
                    AnimatedBuilder(
                      animation: _sparkleController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SparklePainter(_sparkleController.value),
                          child: Container(),
                        );
                      },
                    ),
                    // Floating hearts
                    ...List.generate(20, (index) {
                      return AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          final double animationValue = (_animationController.value + index * 0.1) % 1.0;
                          final double size = 15 + (index % 3) * 8.0;
                          return Positioned(
                            left: (index * 50 + 30) % MediaQuery.of(context).size.width,
                            top: animationValue * MediaQuery.of(context).size.height * 0.45,
                            child: Opacity(
                              opacity: 0.6,
                              child: Icon(
                                index % 2 == 0 ? Icons.favorite : Icons.stars_rounded,
                                color: Colors.white,
                                size: size,
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFFFF69B4).withOpacity(0.6),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }),
                    // Crown icon with subject image
                    Center(
                      child: AnimatedBuilder(
                        animation: _scaleAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer glow
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.white.withOpacity(0.3),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                // Main circle
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        const Color(0xFFFFF0F5),
                                        Colors.white,
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF69B4).withOpacity(0.5),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.8),
                                        blurRadius: 20,
                                        spreadRadius: -5,
                                      ),
                                    ],
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(35),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFFE0F0),
                                          Color(0xFFFFF0F8),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFFF69B4).withOpacity(0.3),
                                        width: 3,
                                      ),
                                    ),
                                    child: widget.subject.data['imageUrl'] != null && 
                                            widget.subject.data['imageUrl'].toString().isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              widget.subject.data['imageUrl'],
                                              width: 110,
                                              height: 110,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : Icon(
                                            _getSubjectIcon(widget.subject.data['name'] ?? ''),
                                            size: 110,
                                            color: const Color(0xFFFF69B4),
                                          ),
                                  ),
                                ),
                                // Crown on top
                                Positioned(
                                  top: -10,
                                  child: Icon(
                                    Icons.workspace_premium_rounded,
                                    size: 60,
                                    color: const Color(0xFFFFD700),
                                    shadows: [
                                      Shadow(
                                        color: const Color(0xFFFF69B4).withOpacity(0.5),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom gradient overlay
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: 100,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              const Color(0xFFFCE4EC).withOpacity(0.5),
                              const Color(0xFFFCE4EC),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFCE4EC),
                      Color(0xFFFFF0F5),
                      Color(0xFFFFFAFC),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject Code Card
                      SlideTransition(
                        position: _slideAnimations[0],
                        child: _buildPrincessCard(
                          icon: Icons.auto_awesome_rounded,
                          iconColor: const Color(0xFFFF69B4),
                          title: 'รหัสวิชา',
                          subtitle: widget.subject.data['code'] ?? 'N/A',
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Description Card
                      if (widget.subject.data['description'] != null &&
                          widget.subject.data['description'].toString().isNotEmpty)
                        SlideTransition(
                          position: _slideAnimations[1],
                          child: _buildDescriptionCard(),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Credits Card
                      if (widget.subject.data['credits'] != null)
                        SlideTransition(
                          position: _slideAnimations[2],
                          child: _buildPrincessCard(
                            icon: Icons.star_rounded,
                            iconColor: const Color(0xFFFFB74D),
                            title: 'หน่วยกิต',
                            subtitle: '${widget.subject.data['credits']} หน่วยกิต',
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Teacher Card
                      if (widget.subject.data['teacher'] != null &&
                          widget.subject.data['teacher'].toString().isNotEmpty)
                        SlideTransition(
                          position: _slideAnimations[3],
                          child: _buildPrincessCard(
                            icon: Icons.face_rounded,
                            iconColor: const Color(0xFFFF85C0),
                            title: 'ผู้สอน',
                            subtitle: widget.subject.data['teacher'],
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      
                      // Date Information Card
                      SlideTransition(
                        position: _slideAnimations[4],
                        child: _buildDateCard(),
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

  Widget _buildPrincessCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFFF0F5).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF69B4).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFFFFAFC),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(0.15),
                    iconColor.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: iconColor.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.prompt(
                      fontSize: 15,
                      color: const Color(0xFFFF69B4),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.prompt(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFD81B60),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFFF0F5).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF69B4).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFFFFAFC),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF69B4).withOpacity(0.15),
                        const Color(0xFFFF69B4).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF69B4).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFFFF69B4),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'รายละเอียดวิชา',
                  style: GoogleFonts.prompt(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD81B60),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFFF0F5).withOpacity(0.5),
                    Colors.white.withOpacity(0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFFF69B4).withOpacity(0.2),
                  width: 1.5,
                ),
              ),
              child: Text(
                widget.subject.data['description'],
                style: GoogleFonts.prompt(
                  fontSize: 15,
                  color: const Color(0xFF880E4F),
                  height: 1.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            const Color(0xFFFFF0F5).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF69B4).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 10,
            offset: const Offset(-5, -5),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFFF69B4).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFFFFAFC),
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFF69B4).withOpacity(0.15),
                        const Color(0xFFFF69B4).withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFFF69B4).withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF69B4).withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.schedule_rounded,
                    color: Color(0xFFFF69B4),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'ข้อมูลระบบ',
                  style: GoogleFonts.prompt(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFD81B60),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFF0F5).withOpacity(0.5),
                          Colors.white.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFF69B4).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'วันที่สร้าง',
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            color: const Color(0xFFFF69B4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate(widget.subject.created.toString()),
                          style: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF880E4F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFFFF0F5).withOpacity(0.5),
                          Colors.white.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFF69B4).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'อัปเดตล่าสุด',
                          style: GoogleFonts.prompt(
                            fontSize: 13,
                            color: const Color(0xFFFF69B4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatDate((widget.subject.updated ?? widget.subject.created).toString()),
                          style: GoogleFonts.prompt(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF880E4F),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
      return Icons.menu_book_rounded;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน', 'พฤษภาคม', 'มิถุนายน',
        'กรกฎาคม', 'สิงหาคม', 'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
      ];
      
      return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
    } catch (e) {
      return 'ไม่ทราบ';
    }
  }
}

// Custom painter for sparkle effect
class SparklePainter extends CustomPainter {
  final double animationValue;

  SparklePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 15; i++) {
      final double offset = (animationValue + i * 0.15) % 1.0;
      final double x = (i * 80.0 + 40) % size.width;
      final double y = offset * size.height;
      final double sparkleSize = 8 + (i % 3) * 4.0;

      // Draw sparkle star
      _drawSparkle(canvas, Offset(x, y), sparkleSize, paint);
    }
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Paint paint) {
    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      paint,
    );
    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      paint,
    );
    // Diagonal lines
    canvas.drawLine(
      Offset(center.dx - size * 0.7, center.dy - size * 0.7),
      Offset(center.dx + size * 0.7, center.dy + size * 0.7),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size * 0.7, center.dy + size * 0.7),
      Offset(center.dx + size * 0.7, center.dy - size * 0.7),
      paint,
    );
  }

  @override
  bool shouldRepaint(SparklePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}