import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndCompressImage({bool fromCamera = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      final compressedBytes = await FlutterImageCompress.compressWithFile(
        image.path,
        minWidth: 800,
        minHeight: 800,
        quality: 80,
      );

      if (compressedBytes == null) return null;

      return base64Encode(compressedBytes);
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  static Future<List<String>> pickMultipleImages({int maxImages = 6}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isEmpty) return [];

      List<String> base64Images = [];
      for (var image in images.take(maxImages)) {
        final compressedBytes = await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 800,
          minHeight: 800,
          quality: 80,
        );

        if (compressedBytes != null) {
          base64Images.add(base64Encode(compressedBytes));
        }
      }

      return base64Images;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  static void showImageSourceDialog(context, Function(String?) onImagePicked) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final image = await pickAndCompressImage(fromCamera: true);
                onImagePicked(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final image = await pickAndCompressImage(fromCamera: false);
                onImagePicked(image);
              },
            ),
          ],
        ),
      ),
    );
  }
}
