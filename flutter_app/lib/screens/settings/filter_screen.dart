import 'package:flutter/material.dart';
import '../../utils/theme.dart';

class FilterScreen extends StatefulWidget {
  final Map<String, dynamic> currentFilters;

  const FilterScreen({super.key, required this.currentFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  late RangeValues _ageRange;
  late double _distance;
  String? _relationshipIntent;

  final List<String> _intents = ['Long-term relationship', 'Short-term relationship', 'Friendship', 'Casual dating', 'Not sure yet'];

  @override
  void initState() {
    super.initState();
    _ageRange = RangeValues(
      widget.currentFilters['min_age']?.toDouble() ?? 18,
      widget.currentFilters['max_age']?.toDouble() ?? 50,
    );
    _distance = widget.currentFilters['max_distance_km']?.toDouble() ?? 25;
    _relationshipIntent = widget.currentFilters['relationship_intent'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Filters'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _ageRange = const RangeValues(18, 50);
                _distance = 25;
                _relationshipIntent = null;
              });
            },
            child: const Text('Reset', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAgeFilter(),
            const SizedBox(height: 16),
            _buildDistanceFilter(),
            const SizedBox(height: 16),
            _buildRelationshipIntentFilter(),
            const SizedBox(height: 32),
            _buildApplyButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Age Range', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} years', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            activeColor: AppTheme.primaryColor,
            onChanged: (values) => setState(() => _ageRange = values),
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Maximum Distance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('${_distance.toInt()} km', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 16, fontWeight: FontWeight.w600)),
          Slider(
            value: _distance,
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: AppTheme.primaryColor,
            onChanged: (value) => setState(() => _distance = value),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationshipIntentFilter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Looking For', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _intents.map((intent) {
              final isSelected = _relationshipIntent == intent;
              return GestureDetector(
                onTap: () => setState(() => _relationshipIntent = isSelected ? null : intent),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    color: isSelected ? null : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(intent, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
      child: ElevatedButton(
        onPressed: () {
          final filters = {
            'min_age': _ageRange.start.toInt(),
            'max_age': _ageRange.end.toInt(),
            'max_distance_km': _distance,
            if (_relationshipIntent != null) 'relationship_intent': _relationshipIntent,
          };
          Navigator.pop(context, filters);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, padding: const EdgeInsets.symmetric(vertical: 16)),
        child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
