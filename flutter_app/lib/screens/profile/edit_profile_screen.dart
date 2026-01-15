import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/theme.dart';
import '../../utils/image_picker_helper.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  String? _selectedIntent;
  List<String> _selectedInterests = [];
  bool _isUploading = false;

  final List<String> _relationshipIntents = [
    'Long-term relationship',
    'Short-term relationship',
    'Friendship',
    'Casual dating',
    'Not sure yet',
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.name);
    _ageController = TextEditingController(text: user?.age?.toString());
    _bioController = TextEditingController(text: user?.bio);
    _locationController = TextEditingController(text: user?.location);
    _selectedIntent = user?.relationshipIntent;
    _selectedInterests = List.from(user?.interests ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.token == null) return;

    final success = await userService.updateProfile(
      token: authService.token!,
      name: _nameController.text.trim(),
      age: int.tryParse(_ageController.text),
      bio: _bioController.text.trim(),
      location: _locationController.text.trim(),
      interests: _selectedInterests,
      relationshipIntent: _selectedIntent,
    );

    if (!mounted) return;

    if (success) {
      await authService.getCurrentUser();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully'), backgroundColor: AppTheme.successColor),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update profile'), backgroundColor: AppTheme.errorColor),
      );
    }
  }

  Future<void> _uploadImage() async {
    setState(() => _isUploading = true);
    
    ImagePickerHelper.showImageSourceDialog(context, (base64Image) async {
      if (base64Image != null) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userService = Provider.of<UserService>(context, listen: false);
        
        if (authService.token != null) {
          final success = await userService.uploadImage(authService.token!, base64Image);
          
          if (success && mounted) {
            await authService.getCurrentUser();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image uploaded successfully')),
            );
          }
        }
      }
      setState(() => _isUploading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildImageSection(),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person)),
                  validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age', prefixIcon: Icon(Icons.cake)),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter your age';
                    final age = int.tryParse(value!);
                    if (age == null || age < 18 || age > 100) return 'Age must be between 18 and 100';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.edit), hintText: 'Tell us about yourself...'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on)),
                ),
                const SizedBox(height: 24),
                Text('Relationship Intent', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _relationshipIntents.map((intent) {
                    final isSelected = _selectedIntent == intent;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedIntent = intent),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppTheme.primaryGradient : null,
                          color: isSelected ? null : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? Colors.transparent : AppTheme.primaryColor),
                        ),
                        child: Text(intent, style: TextStyle(color: isSelected ? Colors.white : AppTheme.primaryColor, fontSize: 12)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Interests', style: Theme.of(context).textTheme.titleLarge),
                    TextButton(
                      onPressed: () => _showInterestsDialog(),
                      child: const Text('Add', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selectedInterests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Text('No interests added', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary), textAlign: TextAlign.center),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _selectedInterests.map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(interest, style: const TextStyle(color: Colors.white, fontSize: 12)),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => setState(() => _selectedInterests.remove(interest)),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    final user = Provider.of<AuthService>(context).currentUser;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Text('Profile Photos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (user?.profileImages.length ?? 0) + 1,
              itemBuilder: (context, index) {
                if (index == (user?.profileImages.length ?? 0)) {
                  return GestureDetector(
                    onTap: _isUploading ? null : _uploadImage,
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primaryColor, width: 2, style: BorderStyle.solid),
                      ),
                      child: _isUploading
                          ? const Center(child: CircularProgressIndicator())
                          : const Icon(Icons.add_photo_alternate, color: AppTheme.primaryColor, size: 40),
                    ),
                  );
                }
                
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, color: AppTheme.primaryColor),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showInterestsDialog() {
    final availableInterests = ['Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking', 'Photography', 'Gaming', 'Fitness', 'Art', 'Dancing', 'Yoga', 'Hiking', 'Swimming', 'Coffee', 'Wine', 'Foodie', 'Netflix', 'Beach', 'Mountains', 'Dogs', 'Cats'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Interests'),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else if (_selectedInterests.length < 10) {
                      _selectedInterests.add(interest);
                    }
                  });
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(interest, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
        ],
      ),
    );
  }
}
