import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/theme.dart';

class RichProfileScreen extends StatefulWidget {
  const RichProfileScreen({super.key});

  @override
  State<RichProfileScreen> createState() => _RichProfileScreenState();
}

class _RichProfileScreenState extends State<RichProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _jobTitleController;
  late TextEditingController _companyController;
  late TextEditingController _educationDetailsController;
  late TextEditingController _heightController;
  
  // Dropdowns
  String? _selectedEducationLevel;
  String? _selectedBodyType;
  String? _selectedSmoking;
  String? _selectedDrinking;
  String? _selectedDiet;
  String? _selectedReligion;
  String? _selectedCaste;
  String? _selectedMotherTongue;
  String? _selectedGymFrequency;
  String? _selectedTravelFrequency;
  
  // Profile prompts
  final Map<String, TextEditingController> _promptControllers = {
    'ideal_date': TextEditingController(),
    'fun_fact': TextEditingController(),
    'life_goal': TextEditingController(),
    'perfect_weekend': TextEditingController(),
  };

  final Map<String, List<String>> _options = {
    'education_levels': [
      'High School', 'Bachelor\'s Degree', 'Master\'s Degree', 
      'PhD', 'Diploma', 'Professional Course', 'Other'
    ],
    'body_types': ['Slim', 'Average', 'Athletic', 'Curvy', 'Plus Size'],
    'smoking': ['Never', 'Occasionally', 'Regularly', 'Trying to quit'],
    'drinking': ['Never', 'Socially', 'Occasionally', 'Regularly'],
    'diet': ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Jain', 'Eggetarian'],
    'religions': [
      'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 
      'Jain', 'Other', 'Prefer not to say'
    ],
    'gym_frequency': ['Never', 'Rarely', 'Sometimes', 'Often', 'Daily'],
    'travel_frequency': ['Never', 'Rarely', 'Sometimes', 'Often', 'Love to travel'],
  };

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    
    _jobTitleController = TextEditingController(text: user?.jobTitle ?? '');
    _companyController = TextEditingController(text: user?.company ?? '');
    _educationDetailsController = TextEditingController(text: user?.educationDetails ?? '');
    _heightController = TextEditingController(text: user?.height?.toString() ?? '');
    
    // Set dropdown values from user data
    _selectedEducationLevel = user?.educationLevel;
    _selectedBodyType = user?.bodyType;
    _selectedSmoking = user?.smoking;
    _selectedDrinking = user?.drinking;
    _selectedDiet = user?.dietPreference;
    _selectedReligion = user?.religion;
    _selectedCaste = user?.caste;
    _selectedMotherTongue = user?.motherTongue;
    _selectedGymFrequency = user?.gymFrequency;
    _selectedTravelFrequency = user?.travelFrequency;
    
    // Load profile prompts if available
    if (user?.profilePrompts != null) {
      _promptControllers.forEach((key, controller) {
        controller.text = user!.profilePrompts![key] ?? '';
      });
    }
  }

  @override
  void dispose() {
    _jobTitleController.dispose();
    _companyController.dispose();
    _educationDetailsController.dispose();
    _heightController.dispose();
    _promptControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveRichProfile,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Professional Info', [
                  _buildTextField('Job Title', _jobTitleController, Icons.work),
                  _buildTextField('Company', _companyController, Icons.business),
                ]),
                
                _buildSection('Education', [
                  _buildDropdown('Education Level', _selectedEducationLevel, _options['education_levels']!, (value) {
                    setState(() => _selectedEducationLevel = value);
                  }),
                  _buildTextField('Education Details', _educationDetailsController, Icons.school),
                ]),
                
                _buildSection('Physical Attributes', [
                  _buildTextField('Height (cm)', _heightController, Icons.height, keyboardType: TextInputType.number),
                  _buildDropdown('Body Type', _selectedBodyType, _options['body_types']!, (value) {
                    setState(() => _selectedBodyType = value);
                  }),
                ]),
                
                _buildSection('Lifestyle', [
                  _buildDropdown('Smoking', _selectedSmoking, _options['smoking']!, (value) {
                    setState(() => _selectedSmoking = value);
                  }),
                  _buildDropdown('Drinking', _selectedDrinking, _options['drinking']!, (value) {
                    setState(() => _selectedDrinking = value);
                  }),
                  _buildDropdown('Diet Preference', _selectedDiet, _options['diet']!, (value) {
                    setState(() => _selectedDiet = value);
                  }),
                ]),
                
                _buildSection('Cultural Background', [
                  _buildDropdown('Religion', _selectedReligion, _options['religions']!, (value) {
                    setState(() => _selectedReligion = value);
                  }),
                  _buildTextField('Caste (Optional)', TextEditingController(text: _selectedCaste), Icons.family_restroom),
                  _buildTextField('Mother Tongue', TextEditingController(text: _selectedMotherTongue), Icons.language),
                ]),
                
                _buildSection('Activity Level', [
                  _buildDropdown('Gym Frequency', _selectedGymFrequency, _options['gym_frequency']!, (value) {
                    setState(() => _selectedGymFrequency = value);
                  }),
                  _buildDropdown('Travel Frequency', _selectedTravelFrequency, _options['travel_frequency']!, (value) {
                    setState(() => _selectedTravelFrequency = value);
                  }),
                ]),
                
                _buildSection('About You', [
                  _buildPromptField('My ideal date is...', _promptControllers['ideal_date']!),
                  _buildPromptField('A fun fact about me...', _promptControllers['fun_fact']!),
                  _buildPromptField('My life goal is...', _promptControllers['life_goal']!),
                  _buildPromptField('Perfect weekend for me...', _promptControllers['perfect_weekend']!),
                ]),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, List<String> options, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPromptField(String prompt, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: prompt,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          alignLabelWithHint: true,
        ),
      ),
    );
  }

  Future<void> _saveRichProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final userService = Provider.of<UserService>(context, listen: false);

    if (authService.token == null) return;

    final profileData = {
      'job_title': _jobTitleController.text.trim(),
      'company': _companyController.text.trim(),
      'education_level': _selectedEducationLevel,
      'education_details': _educationDetailsController.text.trim(),
      'height': int.tryParse(_heightController.text),
      'body_type': _selectedBodyType,
      'smoking': _selectedSmoking,
      'drinking': _selectedDrinking,
      'diet_preference': _selectedDiet,
      'religion': _selectedReligion,
      'caste': _selectedCaste,
      'mother_tongue': _selectedMotherTongue,
      'gym_frequency': _selectedGymFrequency,
      'travel_frequency': _selectedTravelFrequency,
      'profile_prompts': {
        for (var entry in _promptControllers.entries)
          entry.key: entry.value.text.trim()
      },
    };

    final success = await userService.updateRichProfile(authService.token!, profileData);

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
}