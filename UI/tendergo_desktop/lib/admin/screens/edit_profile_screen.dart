import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/update_address_request.dart';
import 'package:tendergo/shared/models/requests/update_profile_request.dart';
import 'package:tendergo/shared/services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserDto user;
  final UserService userService;
  final VoidCallback onSave;

  const EditProfileScreen({
    super.key,
    required this.user,
    required this.userService,
    required this.onSave,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;

  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  String? _error;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  String? get _existingImageUrl {
    final url = widget.user.profileImageUrl?.trim();
    if (url == null || url.isEmpty) {
      return null;
    }
    return url;
  }

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);

    _streetController = TextEditingController(
      text: widget.user.address?.street ?? '',
    );
    _cityController = TextEditingController(
      text: widget.user.address?.city ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.user.address?.postalCode ?? '',
    );
    _countryController = TextEditingController(
      text: widget.user.address?.country ?? '',
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

Future<void> _pickImage() async {
    try {
      // ISPRAVLJENO: Korištenje FilePicker.platform.pickFiles
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      setState(() {
        _selectedImageBytes = file.bytes;
        _selectedImageName = file.name;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final request = UpdateProfileRequest(
        firstName: _firstNameController.text.trim().isNotEmpty
            ? _firstNameController.text.trim()
            : null,
        lastName: _lastNameController.text.trim().isNotEmpty
            ? _lastNameController.text.trim()
            : null,
     
        address:
            (_streetController.text.isNotEmpty ||
                _cityController.text.isNotEmpty ||
                _postalCodeController.text.isNotEmpty ||
                _countryController.text.isNotEmpty)
            ? UpdateAddressDto(
                street: _streetController.text.trim().isNotEmpty
                    ? _streetController.text.trim()
                    : null,
                city: _cityController.text.trim().isNotEmpty
                    ? _cityController.text.trim()
                    : null,
                postalCode: _postalCodeController.text.trim().isNotEmpty
                    ? _postalCodeController.text.trim()
                    : null,
                country: _countryController.text.trim().isNotEmpty
                    ? _countryController.text.trim()
                    : null,
              )
            : null,
        imageBytes: _selectedImageBytes,
      );

      await widget.userService.updateProfile(request);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      widget.onSave();

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $_error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const CustomBackButton(),
        title: const Text('Edit Profile'),
        centerTitle: true,
      ),
      body: Center( // Centrirano za desktop ekrane
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600), // Ograničava širinu forme na desktopu
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: AppColors.outline,
                              width: 1,
                            ),
                          ),
                          child: _selectedImageBytes != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _existingImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Icon(
                                      Icons.person_rounded,
                                      size: 60,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person_rounded,
                                  size: 60,
                                  color: AppColors.textSecondary,
                                ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _isSubmitting ? null : _pickImage,
                          icon: const Icon(Icons.image_rounded),
                          label: const Text('Change Photo'),
                        ),
                        if (_selectedImageName != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Selected: $_selectedImageName',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Personal Information Section
                  Text(
                    'Personal Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row( // Na desktopu ime i prezime stoje jedno pored drugog
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name',
                            hintText: 'Enter your first name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'First name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            hintText: 'Enter your last name',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Last name is required';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
               
                  const SizedBox(height: 24),
                  
                  // Address Section
                  Text(
                    'Address',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street',
                      hintText: 'Enter your street address (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row( // Grad i poštanski broj idu paralelno na desktopu
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            hintText: 'Enter your city (optional)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Postal Code',
                            hintText: 'Enter your postal code (optional)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _countryController,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      hintText: 'Enter your country (optional)',
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Error Message
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end, // Poravnato udesno, prirodnije za desktop
                    children: [
                      SizedBox(
                        width: 120,
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}