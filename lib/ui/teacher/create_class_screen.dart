import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/class_provider.dart';
import '../../core/constants/app_colors.dart';
import 'package:animate_do/animate_do.dart';

class CreateClassScreen extends ConsumerStatefulWidget {
  const CreateClassScreen({super.key});

  @override
  ConsumerState<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _ModuleControllers {
  final TextEditingController name = TextEditingController();
  final TextEditingController code = TextEditingController();

  void dispose() {
    name.dispose();
    code.dispose();
  }
}

class _CreateClassScreenState extends ConsumerState<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<_ModuleControllers> _moduleControllers = [_ModuleControllers()];
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (var controllers in _moduleControllers) {
      controllers.dispose();
    }
    super.dispose();
  }

  void _addModuleField() {
    setState(() {
      _moduleControllers.add(_ModuleControllers());
    });
  }

  void _removeModuleField(int index) {
    if (_moduleControllers.length > 1) {
      setState(() {
        _moduleControllers[index].dispose();
        _moduleControllers.removeAt(index);
      });
    }
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(currentUserProvider);
      final supabase = ref.read(supabaseServiceProvider);

      final modules = _moduleControllers.map((c) {
        return {'name': c.name.text.trim(), 'code': c.code.text.trim()};
      }).toList();

      await supabase.createClassWithModules(
        teacherId: user!.id,
        className: _nameController.text.trim(),
        description: _descController.text.trim(),
        modules: modules,
      );

      // Refresh classes list
      ref.invalidate(classListProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Class created successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Create New Class'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: const Text(
                  'General Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Class Name',
                  hintText: 'e.g. Computer Science 2024',
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'e.g. Year 2, Semester 1',
                ),
              ),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeInLeft(
                    duration: const Duration(milliseconds: 400),
                    child: const Text(
                      'Modules / Subjects',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _addModuleField,
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _moduleControllers.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return FadeInRight(
                    duration: const Duration(milliseconds: 300),
                    delay: Duration(milliseconds: 100 * index),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Module ${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            if (_moduleControllers.length > 1)
                              IconButton(
                                onPressed: () => _removeModuleField(index),
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _moduleControllers[index].name,
                                decoration: const InputDecoration(
                                  labelText: 'Name',
                                  hintText: 'e.g. Data Structures',
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _moduleControllers[index].code,
                                decoration: const InputDecoration(
                                  labelText: 'Code',
                                  hintText: 'CS101',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreate,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Class'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
