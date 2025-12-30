import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../models/class_model.dart';
import '../../core/constants/app_colors.dart';
import 'package:animate_do/animate_do.dart';

class JoinClassScreen extends ConsumerStatefulWidget {
  const JoinClassScreen({super.key});

  @override
  ConsumerState<JoinClassScreen> createState() => _JoinClassScreenState();
}

class _JoinClassScreenState extends ConsumerState<JoinClassScreen> {
  final _searchController = TextEditingController();
  List<ClassModel> _allClasses = [];
  List<ClassModel> _filteredClasses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClasses();
  }

  Future<void> _loadClasses() async {
    try {
      final response = await Supabase.instance.client
          .from('classes')
          .select()
          .order('name');

      final List<ClassModel> classes = (response as List)
          .map((json) => ClassModel.fromJson(json))
          .toList();

      setState(() {
        _allClasses = classes;
        _filteredClasses = classes;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading classes: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading classes: $e')));
      }
      setState(() => _isLoading = false);
    }
  }

  void _filterClasses(String query) {
    setState(() {
      _filteredClasses = _allClasses
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _enroll(ClassModel cls) async {
    final user = ref.read(currentUserProvider);
    final supabase = ref.read(supabaseServiceProvider);

    try {
      await supabase.enrollInClass(user!.id, cls.id);
      ref.invalidate(classListProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Enrolled in ${cls.name}')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Already enrolled or error occurred')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Join a Class')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by class name...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onChanged: _filterClasses,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClasses.isEmpty
                ? const Center(child: Text('No classes found.'))
                : ListView.builder(
                    itemCount: _filteredClasses.length,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemBuilder: (context, index) {
                      final cls = _filteredClasses[index];
                      return FadeInUp(
                        duration: const Duration(milliseconds: 400),
                        delay: Duration(milliseconds: 50 * index),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.secondary,
                              child: Icon(
                                Icons.class_outlined,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              cls.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(cls.description ?? 'No description'),
                            trailing: SizedBox(
                              width: 80,
                              height: 36,
                              child: ElevatedButton(
                                onPressed: () => _enroll(cls),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.secondary,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Join',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
