import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile_app/features/maintenance/providers/maintenance_provider.dart';

class MaintenanceNewScreen extends ConsumerStatefulWidget {
  const MaintenanceNewScreen({super.key});

  @override
  ConsumerState<MaintenanceNewScreen> createState() => _MaintenanceNewScreenState();
}

class _MaintenanceNewScreenState extends ConsumerState<MaintenanceNewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedBuildingId;
  String? _selectedRoomId;
  String _selectedPriority = 'Medium';
  
  List<dynamic> _categories = [];
  List<dynamic> _buildings = [];
  List<dynamic> _rooms = [];
  List<File> _images = [];
  
  bool _isLoading = false;
  bool _isFetchingInitial = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    final supabase = Supabase.instance.client;
    final results = await Future.wait([
      supabase.from('maintenance_categories').select('*').eq('is_active', true).order('name'),
      supabase.from('buildings').select('*').order('name'),
    ]);

    if (mounted) {
      setState(() {
        _categories = results[0] as List;
        _buildings = results[1] as List;
        _isFetchingInitial = false;
      });
    }
  }

  Future<void> _fetchRooms(String buildingId) async {
    final supabase = Supabase.instance.client;
    final results = await supabase
        .from('rooms')
        .select('*')
        .eq('building_id', buildingId)
        .order('name');
    
    if (mounted) {
      setState(() {
        _rooms = results as List;
        _selectedRoomId = null;
      });
    }
  }

  Future<void> _pickImage() async {
    if (_images.length >= 3) return;
    
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _images.add(File(image.path));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedBuildingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and building')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;

      // 1. Insert request
      final request = await supabase.from('maintenance_requests').insert({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'category_id': _selectedCategoryId,
        'building_id': _selectedBuildingId,
        'room_id': _selectedRoomId,
        'location_detail': _locationController.text,
        'priority_level': _selectedPriority,
        'requester_id': userId,
        'status': 'Submitted',
      }).select().single();

      // 2. Upload images
      if (_images.isNotEmpty) {
        for (var i = 0; i < _images.length; i++) {
          final file = _images[i];
          final ext = file.path.split('.').last;
          final fileName = '${request['id']}/$i.$ext';
          
          await supabase.storage.from('maintenance-photos').upload(
            fileName, 
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

          final publicUrl = supabase.storage.from('maintenance-photos').getPublicUrl(fileName);

          await supabase.from('maintenance_attachments').insert({
            'request_id': request['id'],
            'uploaded_by': userId,
            'file_url': publicUrl,
            'attachment_type': 'issue',
          });
        }
      }

      if (mounted) {
        ref.refresh(maintenanceListProvider);
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFetchingInitial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Request'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Broken Light Fixture',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat['id'],
                    child: Text(cat['name']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedBuildingId,
                      decoration: const InputDecoration(
                        labelText: 'Building',
                        border: OutlineInputBorder(),
                      ),
                      items: _buildings.map((b) {
                        return DropdownMenuItem<String>(
                          value: b['id'],
                          child: Text(b['name']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedBuildingId = val);
                        if (val != null) _fetchRooms(val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedRoomId,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        border: OutlineInputBorder(),
                      ),
                      disabledHint: const Text('Select building'),
                      items: _rooms.map((r) {
                        return DropdownMenuItem<String>(
                          value: r['id'],
                          child: Text(r['name']),
                        );
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedRoomId = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location Details',
                  hintText: 'e.g. Near the back door',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: ['Low', 'Medium', 'High', 'Urgent'].map((p) {
                  return DropdownMenuItem<String>(
                    value: p,
                    child: Text(p),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedPriority = val!),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue in detail...',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Photos (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._images.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 16,
                            child: GestureDetector(
                              onTap: () => setState(() => _images.removeAt(entry.key)),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 12, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    if (_images.length < 3)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF142D55),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('Submit Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
