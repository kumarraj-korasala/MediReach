import 'package:flutter/material.dart';
import 'package:miracle/core/theme/app_theme.dart';

class FamilyRecordsScreen extends StatelessWidget {
  const FamilyRecordsScreen({super.key});

  static const _members = [
    {'name': 'Ravi Kumar', 'relation': 'Husband', 'age': '38', 'status': 'healthy'},
    {'name': 'Anjali', 'relation': 'Daughter', 'age': '12', 'status': 'healthy'},
    {'name': 'Suresh', 'relation': 'Father-in-law', 'age': '68', 'status': 'followup'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        title: const Text('👨‍👩‍👧 Family Records',
            style: TextStyle(
                color: AppColors.textOnPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            onPressed: () {},
            tooltip: 'Add Member',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppDimens.paddingPage),
        itemCount: _members.length,
        itemBuilder: (_, i) => _FamilyCard(member: _members[i]),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  final Map<String, dynamic> member;
  const _FamilyCard({required this.member});

  @override
  Widget build(BuildContext context) {
    final isFollowup = member['status'] == 'followup';
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimens.gapMedium),
      padding: const EdgeInsets.all(AppDimens.paddingCard),
      decoration: appCardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primaryLight,
            child: const Icon(Icons.person, color: AppColors.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member['name']!, style: AppTextStyles.subheading),
                Text('${member['relation']} • Age ${member['age']}',
                    style: AppTextStyles.caption),
                const SizedBox(height: 2),
                Text(
                  isFollowup ? '🟡 Follow up Required' : '🟢 Health Stable',
                  style: AppTextStyles.caption.copyWith(
                    color: isFollowup
                        ? AppColors.statusAmber
                        : AppColors.statusGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text('View Records',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
