// import 'dart:convert';
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:pocketbase/pocketbase.dart';
// import 'subject_detail.dart';

// class SubjectListPage extends StatefulWidget {
//   const SubjectListPage({super.key});

//   @override
//   State<SubjectListPage> createState() => _SubjectListPageState();
// }

// class _SubjectListPageState extends State<SubjectListPage> {
//   final pb = PocketBase('http://127.0.0.1:8090');
//   late final RecordService _service;
//   final List<RecordModel> _subjects = [];
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _codeController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _creditsController = TextEditingController();
//   final TextEditingController _teacherController = TextEditingController();
//   final TextEditingController _imageUrlController = TextEditingController();
  
//   bool _isLoading = false;
//   String _searchQuery = '';
//   String? _editingId;
//   Timer? _refreshTimer;

//   @override
//   void initState() {
//     super.initState();
//     _service = pb.collection('subject');
//     _fetchSubjects();
    
//     // เริ่มการอัปเดตแบบ realtime
//     _startRealtimeUpdates();

//     _searchController.addListener(() {
//       setState(() {
//         _searchQuery = _searchController.text.toLowerCase();
//       });
//     });
//   }

//   void _startRealtimeUpdates() {
//     // ใช้ Timer เพื่ออัปเดตข้อมูลทุก 2 วินาที
//     _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
//       _fetchSubjectsQuietly();
//     });
//   }

//   Future<void> _fetchSubjectsQuietly() async {
//     // ดึงข้อมูลใหม่โดยไม่แสดง loading indicator
//     try {
//       final result = await _service.getList(
//         page: 1, 
//         perPage: 100, 
//         sort: "-created"
//       );
      
//       // เปรียบเทียบข้อมูลใหม่กับเก่า
//       if (_hasDataChanged(result.items)) {
//         setState(() {
//           _subjects
//             ..clear()
//             ..addAll(result.items);
//         });
//         print("Data updated: ${result.items.length} subjects");
//       }
//     } catch (e) {
//       // ไม่แสดง error message ใน silent refresh
//       print('Silent refresh error: $e');
//     }
//   }

//   bool _hasDataChanged(List<RecordModel> newData) {
//     if (newData.length != _subjects.length) {
//       return true;
//     }
    
//     for (int i = 0; i < newData.length; i++) {
//       final newItem = newData[i];
//       final existingItem = _subjects.length > i ? _subjects[i] : null;
      
//       if (existingItem == null || 
//           newItem.id != existingItem.id ||
//           newItem.updated != existingItem.updated) {
//         return true;
//       }
//     }
    
//     return false;
//   }

//   @override
//   void dispose() {
//     _refreshTimer?.cancel();
//     _searchController.dispose();
//     _nameController.dispose();
//     _codeController.dispose();
//     _descriptionController.dispose();
//     _creditsController.dispose();
//     _teacherController.dispose();
//     _imageUrlController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchSubjects() async {
//     if (_isLoading) return;
//     setState(() => _isLoading = true);
    
//     try {
//       final result = await _service.getList(
//         page: 1, 
//         perPage: 100, 
//         sort: "-created"
//       );
//       setState(() {
//         _subjects
//           ..clear()
//           ..addAll(result.items);
//       });
//     } catch (e) {
//       _showSnackBar('Error fetching subjects: $e', isError: true);
//     }
    
//     setState(() => _isLoading = false);
//   }

//   List<RecordModel> get _filteredSubjects {
//     if (_searchQuery.isEmpty) return _subjects;
//     return _subjects.where((subject) {
//       final name = subject.data['name']?.toString().toLowerCase() ?? '';
//       final code = subject.data['code']?.toString().toLowerCase() ?? '';
//       final teacher = subject.data['teacher']?.toString().toLowerCase() ?? '';
//       return name.contains(_searchQuery) || 
//              code.contains(_searchQuery) || 
//              teacher.contains(_searchQuery);
//     }).toList();
//   }

//   void _clearForm() {
//     _nameController.clear();
//     _codeController.clear();
//     _descriptionController.clear();
//     _creditsController.clear();
//     _teacherController.clear();
//     _imageUrlController.clear();
//     _editingId = null;
//   }

//   void _fillForm(RecordModel subject) {
//     _nameController.text = subject.data['name'] ?? '';
//     _codeController.text = subject.data['code'] ?? '';
//     _descriptionController.text = subject.data['description'] ?? '';
//     _creditsController.text = subject.data['credits']?.toString() ?? '';
//     _teacherController.text = subject.data['teacher'] ?? '';
//     _imageUrlController.text = subject.data['imageUrl'] ?? '';
//     _editingId = subject.id;
//   }

//   void _navigateToSubjectDetail(RecordModel subject) {
//     Navigator.of(context).push(
//       MaterialPageRoute(
//         builder: (context) => SubjectDetailPage(subject: subject),
//       ),
//     );
//   }

//   Future<void> _saveSubject() async {
//     if (_nameController.text.trim().isEmpty || _codeController.text.trim().isEmpty) {
//       _showSnackBar('กรุณากรอกชื่อวิชาและรหัสวิชา', isError: true);
//       return;
//     }

//     try {
//       final data = {
//         'name': _nameController.text.trim(),
//         'code': _codeController.text.trim(),
//         'description': _descriptionController.text.trim(),
//         'credits': int.tryParse(_creditsController.text.trim()) ?? 3,
//         'teacher': _teacherController.text.trim(),
//         'imageUrl': _imageUrlController.text.trim(),
//       };

//       if (_editingId == null) {
//         await _service.create(body: data);
//         _showSnackBar('เพิ่มวิชาเรียนสำเร็จ');
//         // รีเฟรชทันทีหลังจากเพิ่มข้อมูล
//         await _fetchSubjectsQuietly();
//       } else {
//         await _service.update(_editingId!, body: data);
//         _showSnackBar('อัปเดตวิชาเรียนสำเร็จ');
//         // รีเฟรชทันทีหลังจากอัปเดตข้อมูล
//         await _fetchSubjectsQuietly();
//       }

//       _clearForm();
//       Navigator.pop(context);
//     } catch (e) {
//       _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
//     }
//   }

//   Future<void> _deleteSubject(String id, String name) async {
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(8),
//               decoration: BoxDecoration(
//                 color: Colors.red.withOpacity(0.1),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(Icons.warning, color: Colors.red),
//             ),
//             const SizedBox(width: 12),
//             Text(
//               'ยืนยันการลบ',
//               style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         content: Text(
//           'คุณต้องการลบวิชา "$name" หรือไม่?',
//           style: GoogleFonts.prompt(),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: Text(
//               'ยกเลิก',
//               style: GoogleFonts.prompt(color: Colors.grey[600]),
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.red,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//             ),
//             child: Text('ลบ', style: GoogleFonts.prompt()),
//           ),
//         ],
//       ),
//     );

//     if (confirmed == true) {
//       try {
//         await _service.delete(id);
//         _showSnackBar('ลบวิชาเรียนสำเร็จ');
//         // รีเฟรชทันทีหลังจากลบข้อมูล
//         await _fetchSubjectsQuietly();
//       } catch (e) {
//         _showSnackBar('เกิดข้อผิดพลาดในการลบ: $e', isError: true);
//       }
//     }
//   }

//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error : Icons.check_circle,
//               color: Colors.white,
//               size: 20,
//             ),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 message,
//                 style: GoogleFonts.prompt(color: Colors.white),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         behavior: SnackBarBehavior.floating,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _showSubjectForm({RecordModel? subject}) {
//     if (subject != null) {
//       _fillForm(subject);
//     } else {
//       _clearForm();
//     }

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         height: MediaQuery.of(context).size.height * 0.85,
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//         ),
//         child: Column(
//           children: [
//             // Handle bar
//             Container(
//               margin: const EdgeInsets.only(top: 12),
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey[300],
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
            
//             // Header
//             Container(
//               padding: const EdgeInsets.all(20),
//               child: Row(
//                 children: [
//                   Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFF3B82F6).withOpacity(0.1),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Icon(
//                       subject == null ? Icons.add : Icons.edit,
//                       color: const Color(0xFF1E3A8A),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Text(
//                     subject == null ? 'เพิ่มวิชาเรียนใหม่' : 'แก้ไขวิชาเรียน',
//                     style: GoogleFonts.prompt(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: const Color(0xFF1E3A8A),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             // Form
//             Expanded(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.symmetric(horizontal: 20),
//                 child: Column(
//                   children: [
//                     _buildTextField(
//                       controller: _nameController,
//                       label: 'ชื่อวิชา',
//                       icon: Icons.book,
//                       required: true,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _codeController,
//                       label: 'รหัสวิชา',
//                       icon: Icons.numbers,
//                       required: true,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _descriptionController,
//                       label: 'คำอธิบาย',
//                       icon: Icons.description,
//                       maxLines: 3,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _creditsController,
//                       label: 'หน่วยกิต',
//                       icon: Icons.star,
//                       keyboardType: TextInputType.number,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _teacherController,
//                       label: 'อาจารย์ผู้สอน',
//                       icon: Icons.person,
//                     ),
//                     const SizedBox(height: 16),
//                     _buildTextField(
//                       controller: _imageUrlController,
//                       label: 'URL รูปภาพ',
//                       icon: Icons.image,
//                     ),
//                     const SizedBox(height: 32),
                    
//                     // Save Button
//                     SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         onPressed: _saveSubject,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: const Color(0xFF3B82F6),
//                           foregroundColor: Colors.white,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           elevation: 4,
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(subject == null ? Icons.add : Icons.save),
//                             const SizedBox(width: 8),
//                             Text(
//                               subject == null ? 'เพิ่มวิชาเรียน' : 'บันทึกการแก้ไข',
//                               style: GoogleFonts.prompt(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     bool required = false,
//     int maxLines = 1,
//     TextInputType? keyboardType,
//   }) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       keyboardType: keyboardType,
//       style: GoogleFonts.prompt(),
//       decoration: InputDecoration(
//         labelText: label + (required ? ' *' : ''),
//         labelStyle: GoogleFonts.prompt(color: const Color(0xFF475569)),
//         prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
//         ),
//         filled: true,
//         fillColor: const Color(0xFFF8FAFC),
//       ),
//     );
//   }

//   IconData _getSubjectIcon(String subjectName) {
//     final name = subjectName.toLowerCase();
//     if (name.contains('คณิต') || name.contains('math')) {
//       return Icons.calculate;
//     } else if (name.contains('วิทย') || name.contains('science')) {
//       return Icons.science;
//     } else if (name.contains('ไทย') || name.contains('thai')) {
//       return Icons.language;
//     } else if (name.contains('อังกฤษ') || name.contains('english')) {
//       return Icons.translate;
//     } else if (name.contains('สังคม') || name.contains('social')) {
//       return Icons.public;
//     } else if (name.contains('ประวัติ') || name.contains('history')) {
//       return Icons.history_edu;
//     } else if (name.contains('ศิลป') || name.contains('art')) {
//       return Icons.palette;
//     } else if (name.contains('ดนตรี') || name.contains('music')) {
//       return Icons.music_note;
//     } else if (name.contains('กีฬา') || name.contains('sport')) {
//       return Icons.sports;
//     } else {
//       return Icons.book;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final isMobile = width < 600;

//     return Scaffold(
//       backgroundColor: const Color(0xFFF0F8FF),
//       appBar: AppBar(
//         title: Row(
//           children: [
//             Container(
//               padding: const EdgeInsets.all(6),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: const Icon(Icons.class_, color: Colors.white, size: 20),
//             ),
//             const SizedBox(width: 8),
//             Text(
//               'จัดการวิชาเรียน',
//               style: GoogleFonts.prompt(
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//               ),
//             ),
//             const Spacer(),
//             // Realtime indicator
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: Colors.green.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Container(
//                     width: 8,
//                     height: 8,
//                     decoration: const BoxDecoration(
//                       color: Colors.green,
//                       shape: BoxShape.circle,
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                   Text(
//                     'LIVE',
//                     style: GoogleFonts.prompt(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: const Color(0xFF4169E1),
//         elevation: 0,
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [
//                 Color(0xFF1E3A8A),
//                 Color(0xFF3B82F6),
//                 Color(0xFF60A5FA),
//               ],
//             ),
//           ),
//         ),
//         shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//         ),
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Color(0xFFF0F8FF),
//               Color(0xFFE6F3FF),
//               Color(0xFFDCECFF),
//             ],
//           ),
//         ),
//         child: Column(
//           children: [
//             // Search Bar
//             Container(
//               margin: EdgeInsets.symmetric(
//                 horizontal: isMobile ? 16 : width * 0.1,
//                 vertical: 20,
//               ),
//               child: TextField(
//                 controller: _searchController,
//                 style: GoogleFonts.prompt(),
//                 decoration: InputDecoration(
//                   hintText: 'ค้นหาวิชาเรียน...',
//                   hintStyle: GoogleFonts.prompt(color: Colors.grey[500]),
//                   prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
//                   suffixIcon: _searchQuery.isNotEmpty
//                       ? IconButton(
//                           icon: const Icon(Icons.clear, color: Colors.grey),
//                           onPressed: () => _searchController.clear(),
//                         )
//                       : null,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(25),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.white,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 16,
//                   ),
//                 ),
//               ),
//             ),

//             // Subject List
//             Expanded(
//               child: _isLoading
//                   ? const Center(
//                       child: CircularProgressIndicator(
//                         valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
//                       ),
//                     )
//                   : _filteredSubjects.isEmpty
//                       ? Center(
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Container(
//                                 padding: const EdgeInsets.all(20),
//                                 decoration: BoxDecoration(
//                                   color: Colors.white,
//                                   borderRadius: BorderRadius.circular(20),
//                                   boxShadow: [
//                                     BoxShadow(
//                                       color: Colors.blue.withOpacity(0.1),
//                                       blurRadius: 10,
//                                       offset: const Offset(0, 5),
//                                     ),
//                                   ],
//                                 ),
//                                 child: Column(
//                                   children: [
//                                     const Icon(
//                                       Icons.school_outlined,
//                                       size: 60,
//                                       color: Color(0xFF3B82F6),
//                                     ),
//                                     const SizedBox(height: 16),
//                                     Text(
//                                       _searchQuery.isEmpty 
//                                           ? 'ยังไม่มีวิชาเรียน' 
//                                           : 'ไม่พบวิชาที่ค้นหา',
//                                       style: GoogleFonts.prompt(
//                                         fontSize: 18,
//                                         fontWeight: FontWeight.bold,
//                                         color: const Color(0xFF1E3A8A),
//                                       ),
//                                     ),
//                                     const SizedBox(height: 8),
//                                     Text(
//                                       _searchQuery.isEmpty
//                                           ? 'กดปุ่ม + เพื่อเพิ่มวิชาเรียนใหม่'
//                                           : 'ลองค้นหาด้วยคำอื่น',
//                                       style: GoogleFonts.prompt(
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         )
//                       : ListView.separated(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: isMobile ? 16 : width * 0.1,
//                             vertical: 8,
//                           ),
//                           itemCount: _filteredSubjects.length,
//                           separatorBuilder: (context, index) => const SizedBox(height: 12),
//                           itemBuilder: (context, index) {
//                             final subject = _filteredSubjects[index];
//                             return Card(
//                               elevation: 4,
//                               shadowColor: Colors.blue.withOpacity(0.2),
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(16),
//                               ),
//                               child: InkWell(
//                                 onTap: () => _navigateToSubjectDetail(subject),
//                                 borderRadius: BorderRadius.circular(16),
//                                 child: Container(
//                                   decoration: BoxDecoration(
//                                     borderRadius: BorderRadius.circular(16),
//                                     gradient: const LinearGradient(
//                                       begin: Alignment.topLeft,
//                                       end: Alignment.bottomRight,
//                                       colors: [Colors.white, Color(0xFFF8FAFC)],
//                                     ),
//                                   ),
//                                   child: Padding(
//                                     padding: const EdgeInsets.all(16),
//                                     child: Row(
//                                       children: [
//                                         // Subject Icon
//                                         Container(
//                                           width: 60,
//                                           height: 60,
//                                           decoration: BoxDecoration(
//                                             color: const Color(0xFF3B82F6).withOpacity(0.1),
//                                             borderRadius: BorderRadius.circular(15),
//                                           ),
//                                           child: Icon(
//                                             _getSubjectIcon(subject.data['name'] ?? ''),
//                                             color: const Color(0xFF3B82F6),
//                                             size: 28,
//                                           ),
//                                         ),
//                                         const SizedBox(width: 16),
                                        
//                                         // Subject Info
//                                         Expanded(
//                                           child: Column(
//                                             crossAxisAlignment: CrossAxisAlignment.start,
//                                             children: [
//                                               Row(
//                                                 children: [
//                                                   Expanded(
//                                                     child: Text(
//                                                       subject.data['name'] ?? 'N/A',
//                                                       style: GoogleFonts.prompt(
//                                                         fontSize: 16,
//                                                         fontWeight: FontWeight.bold,
//                                                         color: const Color(0xFF1E293B),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   const Icon(
//                                                     Icons.touch_app,
//                                                     size: 16,
//                                                     color: Color(0xFF3B82F6),
//                                                   ),
//                                                 ],
//                                               ),
//                                               const SizedBox(height: 4),
//                                               Row(
//                                                 children: [
//                                                   Container(
//                                                     padding: const EdgeInsets.symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 2,
//                                                     ),
//                                                     decoration: BoxDecoration(
//                                                       color: const Color(0xFF3B82F6).withOpacity(0.1),
//                                                       borderRadius: BorderRadius.circular(8),
//                                                     ),
//                                                     child: Text(
//                                                       subject.data['code'] ?? 'N/A',
//                                                       style: GoogleFonts.prompt(
//                                                         fontSize: 12,
//                                                         fontWeight: FontWeight.w600,
//                                                         color: const Color(0xFF1E3A8A),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   const SizedBox(width: 8),
//                                                   Text(
//                                                     '${subject.data['credits'] ?? 3} หน่วยกิต',
//                                                     style: GoogleFonts.prompt(
//                                                       fontSize: 12,
//                                                       color: Colors.grey[600],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                               if (subject.data['teacher']?.toString().isNotEmpty == true)
//                                                 Padding(
//                                                   padding: const EdgeInsets.only(top: 4),
//                                                   child: Row(
//                                                     children: [
//                                                       const Icon(
//                                                         Icons.person,
//                                                         size: 14,
//                                                         color: Colors.grey,
//                                                       ),
//                                                       const SizedBox(width: 4),
//                                                       Text(
//                                                         subject.data['teacher'],
//                                                         style: GoogleFonts.prompt(
//                                                           fontSize: 12,
//                                                           color: Colors.grey[600],
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
                                        
//                                         // Action Buttons
//                                         Column(
//                                           children: [
//                                             IconButton(
//                                               onPressed: () => _showSubjectForm(subject: subject),
//                                               icon: const Icon(Icons.edit),
//                                               color: const Color(0xFF3B82F6),
//                                               style: IconButton.styleFrom(
//                                                 backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius: BorderRadius.circular(10),
//                                                 ),
//                                               ),
//                                             ),
//                                             const SizedBox(height: 8),
//                                             IconButton(
//                                               onPressed: () => _deleteSubject(
//                                                 subject.id,
//                                                 subject.data['name'] ?? 'N/A',
//                                               ),
//                                               icon: const Icon(Icons.delete),
//                                               color: Colors.red,
//                                               style: IconButton.styleFrom(
//                                                 backgroundColor: Colors.red.withOpacity(0.1),
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius: BorderRadius.circular(10),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => _showSubjectForm(),
//         backgroundColor: const Color(0xFF3B82F6),
//         foregroundColor: Colors.white,
//         elevation: 6,
//         icon: const Icon(Icons.add),
//         label: Text(
//           'เพิ่มวิชาเรียน',
//           style: GoogleFonts.prompt(fontWeight: FontWeight.bold),
//         ),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketbase/pocketbase.dart';
import 'subject_detail.dart';

class SubjectListPage extends StatefulWidget {
  const SubjectListPage({super.key});

  @override
  State<SubjectListPage> createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage>
    with TickerProviderStateMixin {
  final pb = PocketBase('http://127.0.0.1:8090');
  late final RecordService _service;
  final List<RecordModel> _subjects = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _teacherController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  
  bool _isLoading = false;
  String _searchQuery = '';
  String? _editingId;
  Timer? _refreshTimer;
  
  late AnimationController _fabAnimationController;
  late AnimationController _sparkleAnimationController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _service = pb.collection('subject');
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _sparkleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleAnimationController,
      curve: Curves.easeInOut,
    ));

    _fetchSubjects();
    _startRealtimeUpdates();
    _fabAnimationController.forward();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  void _startRealtimeUpdates() {
    // ใช้ Timer เพื่ออัปเดตข้อมูลทุก 2 วินาที
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchSubjectsQuietly();
    });
  }

  Future<void> _fetchSubjectsQuietly() async {
    // ดึงข้อมูลใหม่โดยไม่แสดง loading indicator
    try {
      final result = await _service.getList(
        page: 1, 
        perPage: 100, 
        sort: "-created"
      );
      
      // เปรียบเทียบข้อมูลใหม่กับเก่า
      if (_hasDataChanged(result.items)) {
        setState(() {
          _subjects
            ..clear()
            ..addAll(result.items);
        });
        print("Data updated: ${result.items.length} subjects");
      }
    } catch (e) {
      // ไม่แสดง error message ใน silent refresh
      print('Silent refresh error: $e');
    }
  }

  bool _hasDataChanged(List<RecordModel> newData) {
    if (newData.length != _subjects.length) {
      return true;
    }
    
    for (int i = 0; i < newData.length; i++) {
      final newItem = newData[i];
      final existingItem = _subjects.length > i ? _subjects[i] : null;
      
      if (existingItem == null || 
          newItem.id != existingItem.id ||
          newItem.updated != existingItem.updated) {
        return true;
      }
    }
    
    return false;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fabAnimationController.dispose();
    _sparkleAnimationController.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    _descriptionController.dispose();
    _creditsController.dispose();
    _teacherController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final result = await _service.getList(
        page: 1, 
        perPage: 100, 
        sort: "-created"
      );
      setState(() {
        _subjects
          ..clear()
          ..addAll(result.items);
      });
    } catch (e) {
      _showSnackBar('Error fetching subjects: $e', isError: true);
    }
    
    setState(() => _isLoading = false);
  }

  List<RecordModel> get _filteredSubjects {
    if (_searchQuery.isEmpty) return _subjects;
    return _subjects.where((subject) {
      final name = subject.data['name']?.toString().toLowerCase() ?? '';
      final code = subject.data['code']?.toString().toLowerCase() ?? '';
      final teacher = subject.data['teacher']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery) || 
             code.contains(_searchQuery) || 
             teacher.contains(_searchQuery);
    }).toList();
  }

  void _clearForm() {
    _nameController.clear();
    _codeController.clear();
    _descriptionController.clear();
    _creditsController.clear();
    _teacherController.clear();
    _imageUrlController.clear();
    _editingId = null;
  }

  void _fillForm(RecordModel subject) {
    _nameController.text = subject.data['name'] ?? '';
    _codeController.text = subject.data['code'] ?? '';
    _descriptionController.text = subject.data['description'] ?? '';
    _creditsController.text = subject.data['credits']?.toString() ?? '';
    _teacherController.text = subject.data['teacher'] ?? '';
    _imageUrlController.text = subject.data['imageUrl'] ?? '';
    _editingId = subject.id;
  }

  void _navigateToSubjectDetail(RecordModel subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SubjectDetailPage(subject: subject),
      ),
    );
  }

  Future<void> _saveSubject() async {
    if (_nameController.text.trim().isEmpty || _codeController.text.trim().isEmpty) {
      _showSnackBar('กรุณากรอกชื่อวิชาและรหัสวิชา', isError: true);
      return;
    }

    try {
      final data = {
        'name': _nameController.text.trim(),
        'code': _codeController.text.trim(),
        'description': _descriptionController.text.trim(),
        'credits': int.tryParse(_creditsController.text.trim()) ?? 3,
        'teacher': _teacherController.text.trim(),
        'imageUrl': _imageUrlController.text.trim(),
      };

      if (_editingId == null) {
        await _service.create(body: data);
        _showSnackBar('เพิ่มวิชาเรียนสำเร็จ');
        // รีเฟรชทันทีหลังจากเพิ่มข้อมูล
        await _fetchSubjectsQuietly();
      } else {
        await _service.update(_editingId!, body: data);
        _showSnackBar('อัปเดตวิชาเรียนสำเร็จ');
        // รีเฟรชทันทีหลังจากอัปเดตข้อมูล
        await _fetchSubjectsQuietly();
      }

      _clearForm();
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e', isError: true);
    }
  }

  Future<void> _deleteSubject(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFE4E6), Color(0xFFFFE4F2)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFFF6B9D).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B9D).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'ยืนยันการลบ',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF2D1B69),
                  ),
                ),
              ),
            ],
          ),
        ),
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            'คุณต้องการลบวิชา "$name" หรือไม่?\nการดำเนินการนี้ไม่สามารถย้อนกลับได้',
            style: GoogleFonts.prompt(
              fontSize: 16,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'ยกเลิก',
                        style: GoogleFonts.prompt(
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B9D).withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'ลบ',
                        style: GoogleFonts.prompt(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _service.delete(id);
        _showSnackBar('ลบวิชาเรียนสำเร็จ');
        // รีเฟรชทันทีหลังจากลบข้อมูล
        await _fetchSubjectsQuietly();
      } catch (e) {
        _showSnackBar('เกิดข้อผิดพลาดในการลบ: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isError ? Icons.error_rounded : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.prompt(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isError ? const Color(0xFFFF6B9D) : const Color(0xFF7C3AED),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void _showSubjectForm({RecordModel? subject}) {
    if (subject != null) {
      _fillForm(subject);
    } else {
      _clearForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFFAF5FF),
              Color(0xFFF3E8FF),
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF7C3AED),
              blurRadius: 20,
              offset: Offset(0, -5),
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 15),
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      subject == null ? Icons.auto_stories_rounded : Icons.edit_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      subject == null ? 'เพิ่มวิชาเรียนใหม่' : 'แก้ไขวิชาเรียน',
                      style: GoogleFonts.prompt(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D1B69),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildPrincessTextField(
                      controller: _nameController,
                      label: 'ชื่อวิชา',
                      icon: Icons.auto_stories_rounded,
                      required: true,
                      color: const Color(0xFFFF6B9D),
                    ),
                    const SizedBox(height: 20),
                    _buildPrincessTextField(
                      controller: _codeController,
                      label: 'รหัสวิชา',
                      icon: Icons.numbers_rounded,
                      required: true,
                      color: const Color(0xFF7C3AED),
                    ),
                    const SizedBox(height: 20),
                    _buildPrincessTextField(
                      controller: _descriptionController,
                      label: 'คำอธิบาย',
                      icon: Icons.description_rounded,
                      maxLines: 3,
                      color: const Color(0xFFFF8C42),
                    ),
                    const SizedBox(height: 20),
                    _buildPrincessTextField(
                      controller: _creditsController,
                      label: 'หน่วยกิต',
                      icon: Icons.star_rounded,
                      keyboardType: TextInputType.number,
                      color: const Color(0xFF06B6D4),
                    ),
                    const SizedBox(height: 20),
                    _buildPrincessTextField(
                      controller: _teacherController,
                      label: 'อาจารย์ผู้สอน',
                      icon: Icons.person_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    const SizedBox(height: 20),
                    _buildPrincessTextField(
                      controller: _imageUrlController,
                      label: 'URL รูปภาพ',
                      icon: Icons.image_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    const SizedBox(height: 35),
                    
                    // Save Button
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _saveSubject,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              subject == null ? Icons.add_rounded : Icons.save_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              subject == null ? 'เพิ่มวิชาเรียน' : 'บันทึกการแก้ไข',
                              style: GoogleFonts.prompt(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrincessTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.prompt(
          color: const Color(0xFF2D1B69),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          labelStyle: GoogleFonts.prompt(
            color: color,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
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
              expandedHeight: 120,
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
                      // Sparkle animation
                      ...List.generate(15, (index) {
                        return AnimatedBuilder(
                          animation: _sparkleAnimation,
                          builder: (context, child) {
                            final sparkleOffset = (_sparkleAnimation.value + index * 0.1) % 1.0;
                            return Positioned(
                              left: (index * 50 + 20) % width,
                              top: 20 + (sparkleOffset * 100),
                              child: Icon(
                                Icons.auto_awesome_rounded,
                                color: Colors.white.withOpacity(0.6),
                                size: 12 + (index % 3) * 4,
                              ),
                            );
                          },
                        );
                      }),
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.3),
                                      Colors.white.withOpacity(0.1),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_stories_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Princess Academy',
                                  style: GoogleFonts.prompt(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 22,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 10.0,
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Realtime indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.withOpacity(0.9),
                                    const Color(0xFF10B981).withOpacity(0.7), // emerald
                                  ],
                                ),

                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1,
                                  ),
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
            ),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  // Search Bar
                  Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isMobile ? 20 : width * 0.1,
                      vertical: 25,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.white, Color(0xFFFAF5FF)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 10,
                          offset: const Offset(-5, -5),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.prompt(
                        color: const Color(0xFF2D1B69),
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาวิชาเรียนของเจ้าหญิง...',
                        hintStyle: GoogleFonts.prompt(
                          color: const Color(0xFF7C3AED).withOpacity(0.6),
                          fontStyle: FontStyle.italic,
                        ),
                        prefixIcon: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.search_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF6B9D).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.clear_rounded,
                                    color: Color(0xFFFF6B9D),
                                    size: 16,
                                  ),
                                ),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                    ),
                  ),

                  // Subject List
                  _isLoading
                      ? Container(
                          height: 300,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                              strokeWidth: 3,
                            ),
                          ),
                        )
                      : _filteredSubjects.isEmpty
                          ? Container(
                              margin: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : width * 0.1,
                              ),
                              padding: const EdgeInsets.all(30),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.white, Color(0xFFFAF5FF)],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF7C3AED).withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                                border: Border.all(
                                  color: const Color(0xFFFF6B9D).withOpacity(0.2),
                                  width: 2,
                                ),
                              ),
                              child: Column(
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
                                  const SizedBox(height: 20),
                                  Text(
                                    _searchQuery.isEmpty 
                                        ? 'ยังไม่มีวิชาเรียน' 
                                        : 'ไม่พบวิชาที่ค้นหา',
                                    style: GoogleFonts.prompt(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF2D1B69),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'เริ่มต้นสร้างหลักสูตรของเจ้าหญิงกันเถอะ!'
                                        : 'ลองค้นหาด้วยคำอื่นดูนะคะ',
                                    style: GoogleFonts.prompt(
                                      color: const Color(0xFF64748B),
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : width * 0.1,
                                vertical: 10,
                              ),
                              itemCount: _filteredSubjects.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final subject = _filteredSubjects[index];
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [Colors.white, Color(0xFFFAF5FF)],
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                                        blurRadius: 15,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.7),
                                        blurRadius: 10,
                                        offset: const Offset(-5, -5),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: const Color(0xFFFF6B9D).withOpacity(0.2),
                                      width: 2,
                                    ),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _navigateToSubjectDetail(subject),
                                      borderRadius: BorderRadius.circular(20),
                                      child: Padding(
                                        padding: const EdgeInsets.all(20),
                                        child: Row(
                                          children: [
                                            // Subject Icon
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    const Color(0xFF7C3AED).withOpacity(0.2),
                                                    const Color(0xFFFF6B9D).withOpacity(0.1),
                                                  ],
                                                ),
                                                borderRadius: BorderRadius.circular(18),
                                                border: Border.all(
                                                  color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                _getSubjectIcon(subject.data['name'] ?? ''),
                                                color: const Color(0xFF7C3AED),
                                                size: 32,
                                              ),
                                            ),
                                            const SizedBox(width: 18),
                                            
                                            // Subject Info
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: Text(
                                                          subject.data['name'] ?? 'N/A',
                                                          style: GoogleFonts.prompt(
                                                            fontSize: 18,
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xFF2D1B69),
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.all(6),
                                                        decoration: BoxDecoration(
                                                          gradient: const LinearGradient(
                                                            colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                                                          ),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: const Icon(
                                                          Icons.touch_app_rounded,
                                                          size: 16,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              const Color(0xFF7C3AED).withOpacity(0.2),
                                                              const Color(0xFFFF6B9D).withOpacity(0.1),
                                                            ],
                                                          ),
                                                          borderRadius: BorderRadius.circular(10),
                                                          border: Border.all(
                                                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                                                          ),
                                                        ),
                                                        child: Text(
                                                          subject.data['code'] ?? 'N/A',
                                                          style: GoogleFonts.prompt(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: const Color(0xFF2D1B69),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 10),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(0xFFFF8C42).withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          '${subject.data['credits'] ?? 3} หน่วยกิต',
                                                          style: GoogleFonts.prompt(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.w600,
                                                            color: const Color(0xFFFF8C42),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (subject.data['teacher']?.toString().isNotEmpty == true)
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            padding: const EdgeInsets.all(4),
                                                            decoration: BoxDecoration(
                                                              color: const Color(0xFF10B981).withOpacity(0.2),
                                                              borderRadius: BorderRadius.circular(6),
                                                            ),
                                                            child: const Icon(
                                                              Icons.person_rounded,
                                                              size: 14,
                                                              color: Color(0xFF10B981),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              subject.data['teacher'],
                                                              style: GoogleFonts.prompt(
                                                                fontSize: 13,
                                                                color: const Color(0xFF10B981),
                                                                fontWeight: FontWeight.w600,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            
                                            // Action Buttons
                                            Column(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFF06B6D4).withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    onPressed: () => _showSubjectForm(subject: subject),
                                                    icon: const Icon(Icons.edit_rounded),
                                                    color: Colors.white,
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.transparent,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 12),
                                                Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [Color(0xFFFF6B9D), Color(0xFFE91E63)],
                                                    ),
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: const Color(0xFFFF6B9D).withOpacity(0.3),
                                                        blurRadius: 8,
                                                        offset: const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: IconButton(
                                                    onPressed: () => _deleteSubject(
                                                      subject.id,
                                                      subject.data['name'] ?? 'N/A',
                                                    ),
                                                    icon: const Icon(Icons.delete_rounded),
                                                    color: Colors.white,
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.transparent,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFFFF6B9D)],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: FloatingActionButton.extended(
                onPressed: () => _showSubjectForm(),
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                icon: const Icon(Icons.add_rounded, size: 24),
                label: Text(
                  'เพิ่มวิชาเรียน',
                  style: GoogleFonts.prompt(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}