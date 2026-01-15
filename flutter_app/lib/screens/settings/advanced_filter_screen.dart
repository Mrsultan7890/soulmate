import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../../utils/theme.dart';

class AdvancedFilterScreen extends StatefulWidget {
  const AdvancedFilterScreen({super.key});

  @override
  State<AdvancedFilterScreen> createState() => _AdvancedFilterScreenState();
}

class _AdvancedFilterScreenState extends State<AdvancedFilterScreen> {
  // Age range
  RangeValues _ageRange = const RangeValues(18, 35);
  
  // Distance
  double _maxDistance = 25.0;
  
  // Education
  List<String> _selectedEducation = [];
  
  // Height range
  RangeValues _heightRange = const RangeValues(150, 180);
  
  // Body types
  List<String> _selectedBodyTypes = [];
  
  // Lifestyle
  List<String> _selectedSmoking = [];
  List<String> _selectedDrinking = [];
  List<String> _selectedDiet = [];
  
  // Cultural
  List<String> _selectedReligions = [];
  
  // Relationship intent
  List<String> _selectedIntents = [];
  
  // Sort preference
  String _sortBy = 'recent';

  final Map<String, List<String>> _filterOptions = {
    'education': [
      'High School', 'Bachelor\'s Degree', 'Master\'s Degree', 
      'PhD', 'Diploma', 'Professional Course', 'Other'
    ],
    'bodyTypes': ['Slim', 'Average', 'Athletic', 'Curvy', 'Plus Size'],
    'smoking': ['Never', 'Occasionally', 'Regularly', 'Trying to quit'],
    'drinking': ['Never', 'Socially', 'Occasionally', 'Regularly'],
    'diet': ['Vegetarian', 'Non-Vegetarian', 'Vegan', 'Jain', 'Eggetarian'],
    'religions': [
      'Hindu', 'Muslim', 'Christian', 'Sikh', 'Buddhist', 
      'Jain', 'Other', 'Prefer not to say'
    ],
    'intents': [
      'Long-term relationship', 'Short-term relationship', 
      'Friendship', 'Casual dating', 'Not sure yet'
    ]
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Filters'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _applyFilters,
            child: const Text('Apply', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAgeSection(),
              const SizedBox(height: 24),
              _buildDistanceSection(),
              const SizedBox(height: 24),
              _buildEducationSection(),
              const SizedBox(height: 24),
              _buildHeightSection(),
              const SizedBox(height: 24),
              _buildBodyTypeSection(),
              const SizedBox(height: 24),
              _buildLifestyleSection(),
              const SizedBox(height: 24),
              _buildCulturalSection(),
              const SizedBox(height: 24),
              _buildRelationshipSection(),
              const SizedBox(height: 24),
              _buildSortSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgeSection() {
    return _buildFilterCard(
      'Age Range',
      Column(
        children: [
          Text('${_ageRange.start.round()} - ${_ageRange.end.round()} years'),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 60,
            divisions: 42,
            activeColor: AppTheme.primaryColor,
            onChanged: (values) => setState(() => _ageRange = values),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceSection() {
    return _buildFilterCard(
      'Maximum Distance',
      Column(
        children: [
          Text('${_maxDistance.round()} km'),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationSection() {
    return _buildFilterCard(
      'Education Level',
      _buildMultiSelectChips(_filterOptions['education']!, _selectedEducation),
    );
  }

  Widget _buildHeightSection() {
    return _buildFilterCard(
      'Height Range',
      Column(
        children: [
          Text('${_heightRange.start.round()} - ${_heightRange.end.round()} cm'),
          RangeSlider(
            values: _heightRange,
            min: 140,
            max: 200,
            divisions: 60,
            activeColor: AppTheme.primaryColor,
            onChanged: (values) => setState(() => _heightRange = values),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTypeSection() {
    return _buildFilterCard(
      'Body Type',
      _buildMultiSelectChips(_filterOptions['bodyTypes']!, _selectedBodyTypes),
    );
  }

  Widget _buildLifestyleSection() {
    return _buildFilterCard(
      'Lifestyle Preferences',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Smoking:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildMultiSelectChips(_filterOptions['smoking']!, _selectedSmoking),
          const SizedBox(height: 16),
          const Text('Drinking:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildMultiSelectChips(_filterOptions['drinking']!, _selectedDrinking),
          const SizedBox(height: 16),
          const Text('Diet:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildMultiSelectChips(_filterOptions['diet']!, _selectedDiet),
        ],
      ),
    );
  }

  Widget _buildCulturalSection() {
    return _buildFilterCard(
      'Cultural Preferences',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Religion:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildMultiSelectChips(_filterOptions['religions']!, _selectedReligions),
        ],
      ),
    );
  }

  Widget _buildRelationshipSection() {
    return _buildFilterCard(
      'Relationship Intent',
      _buildMultiSelectChips(_filterOptions['intents']!, _selectedIntents),
    );
  }

  Widget _buildSortSection() {
    return _buildFilterCard(
      'Sort By',
      Column(
        children: [
          RadioListTile<String>(
            title: const Text('Recently Active'),
            value: 'recent',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Distance'),
            value: 'distance',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Compatibility'),
            value: 'compatibility',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
          RadioListTile<String>(
            title: const Text('Most Active'),
            value: 'activity',
            groupValue: _sortBy,
            onChanged: (value) => setState(() => _sortBy = value!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(String title, Widget content) {
    return Container(
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
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildMultiSelectChips(List<String> options, List<String> selected) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                selected.remove(option);
              } else {
                selected.add(option);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected ? AppTheme.primaryGradient : null,
              color: isSelected ? null : Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              option,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimary,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearFilters,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
            child: const Text('Clear All'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply Filters'),
            ),
          ),
        ),
      ],
    );
  }

  void _clearFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 35);
      _maxDistance = 25.0;
      _selectedEducation.clear();
      _heightRange = const RangeValues(150, 180);
      _selectedBodyTypes.clear();
      _selectedSmoking.clear();
      _selectedDrinking.clear();
      _selectedDiet.clear();
      _selectedReligions.clear();
      _selectedIntents.clear();
      _sortBy = 'recent';
    });
  }

  void _applyFilters() {
    final filters = {
      'min_age': _ageRange.start.round(),
      'max_age': _ageRange.end.round(),
      'max_distance_km': _maxDistance,
      'education_levels': _selectedEducation,
      'min_height': _heightRange.start.round(),
      'max_height': _heightRange.end.round(),
      'body_types': _selectedBodyTypes,
      'smoking_preferences': _selectedSmoking,
      'drinking_preferences': _selectedDrinking,
      'diet_preferences': _selectedDiet,
      'religions': _selectedReligions,
      'relationship_intents': _selectedIntents,
      'sort_by': _sortBy,
    };

    Navigator.of(context).pop(filters);
  }
}