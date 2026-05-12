import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import '../theme/app_theme.dart';
import '../models/item_model.dart';
import '../services/realtime_service.dart';
import '../services/auth_service.dart';

class PostItemPage extends StatefulWidget {
  const PostItemPage({super.key});

  @override
  State<PostItemPage> createState() => _PostItemPageState();
}

class _PostItemPageState extends State<PostItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  
  String _category = 'Book';
  String _condition = 'New';
  String _priceType = 'Free';
  String _postedBy = 'Senior';
  bool _loading = false;
  String? _base64Image;
  String? _imageName;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        Uint8List? bytes;
        
        if (file.bytes != null) {
          // For web, use bytes directly
          bytes = file.bytes;
        } else if (file.path != null) {
          // For desktop/mobile, read from file path
          final fileObj = File(file.path!);
          bytes = await fileObj.readAsBytes();
        }

        if (bytes != null) {
          final base64String = base64Encode(bytes);
          
          setState(() {
            _base64Image = base64String;
            _imageName = file.name;
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _postItem() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate price if not free
    if (_priceType != 'Free' && _priceController.text.trim().isEmpty) {
      _showError('Please enter a price amount');
      return;
    }

    setState(() => _loading = true);

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        _showError('User not logged in');
        return;
      }

      // Create image URL from base64 or use placeholder
      String imageUrl;
      if (_base64Image != null) {
        imageUrl = 'data:image/jpeg;base64,$_base64Image';
      } else {
        imageUrl = 'https://via.placeholder.com/300x200/CCCCCC/FFFFFF?text=No+Image';
      }

      // Format price type
      String formattedPriceType;
      if (_priceType == 'Free') {
        formattedPriceType = 'Free';
      } else {
        final price = double.tryParse(_priceController.text.trim());
        if (price == null || price <= 0) {
          _showError('Please enter a valid price amount');
          return;
        }
        formattedPriceType = '₹${price.toStringAsFixed(0)}';
      }

      final item = ItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        category: _category,
        condition: _condition,
        priceType: formattedPriceType,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        postedBy: _postedBy,
        ownerEmail: currentUser.email!,
        postedDate: DateTime.now(),
      );

      String itemId = await RealtimeService.addItem(item);
      
      _showSuccess('Item posted successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showError('Failed to post item: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E1E1E) 
            : const Color(0xFF212121),
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        title: const Text('Post Item'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: const ['Book', 'Stationery'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _category = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                ),
                items: const ['New', 'Used'].map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _condition = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Price Type
              const Text(
                'Price Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Free'),
                      value: 'Free',
                      groupValue: _priceType,
                      onChanged: (value) {
                        setState(() {
                          _priceType = value!;
                          _priceController.clear();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Paid'),
                      value: 'Paid',
                      groupValue: _priceType,
                      onChanged: (value) {
                        setState(() {
                          _priceType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (_priceType == 'Paid') ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price Amount (₹)',
                    hintText: 'Enter amount',
                    prefixText: '₹',
                  ),
                  validator: _priceType == 'Paid' ? (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter price amount';
                    }
                    final price = double.tryParse(value.trim());
                    if (price == null || price <= 0) {
                      return 'Please enter valid amount';
                    }
                    return null;
                  } : null,
                ),
              ],
              const SizedBox(height: 16),

              // Posted By
              DropdownButtonFormField<String>(
                initialValue: _postedBy,
                decoration: const InputDecoration(
                  labelText: 'Posted By',
                ),
                items: const ['Senior', 'Junior', 'Staff'].map((postedBy) {
                  return DropdownMenuItem(
                    value: postedBy,
                    child: Text(postedBy),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _postedBy = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Image Upload Section
              const Text(
                'Upload Image',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _base64Image != null
                      ? Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(_base64Image!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload image',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            if (_imageName != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _imageName!,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Post Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _postItem,
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Post Item'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
