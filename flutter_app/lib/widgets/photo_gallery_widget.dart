import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../utils/theme.dart';
import '../utils/image_picker_helper.dart';

class PhotoGalleryWidget extends StatefulWidget {
  const PhotoGalleryWidget({super.key});

  @override
  State<PhotoGalleryWidget> createState() => _PhotoGalleryWidgetState();
}

class _PhotoGalleryWidgetState extends State<PhotoGalleryWidget> {
  bool _isUploading = false;

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
              const SnackBar(content: Text('Image uploaded'), backgroundColor: AppTheme.successColor),
            );
          }
        }
      }
      setState(() => _isUploading = false);
    });
  }

  Future<void> _deleteImage(int index) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);
    
    if (authService.token != null) {
      final success = await userService.deleteImage(authService.token!, index);
      
      if (success && mounted) {
        await authService.getCurrentUser();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        final imageCount = user?.profileImages.length ?? 0;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Photos ($imageCount/6)', style: Theme.of(context).textTheme.titleLarge),
                  if (imageCount < 6)
                    TextButton.icon(
                      onPressed: _isUploading ? null : _uploadImage,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (imageCount == 0)
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.primaryColor, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: AppTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 8),
                        Text('Add your first photo', style: TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: imageCount,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(child: Icon(Icons.image, color: AppTheme.primaryColor, size: 40)),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _showDeleteDialog(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.errorColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              if (_isUploading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteImage(index);
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
