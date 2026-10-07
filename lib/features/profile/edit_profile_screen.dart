import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimensions.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _designationController;
  late TextEditingController _organizationController;
  late TextEditingController _departmentController;
  late TextEditingController _officeController;
  late TextEditingController _mobileController;

  late bool _requiresApproval;
  late String _selectedApproverId;
  late String _selectedApproverName;

  final List<Map<String, String>> _availableApprovers = [
    {
      'id': 'NONE',
      'name': 'No Approver (Self-Approver for Department Journeys)',
    },
    {
      'id': 'USR-003',
      'name': 'Anjali Sharma, IAS (Superintending Engineer)',
    },
    {
      'id': 'USR-004',
      'name': 'Vikram Singh (State Fleet Administrator)',
    },
    {
      'id': 'USR-001',
      'name': 'Dr. S. K. Verma (Executive Engineer)',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _designationController =
        TextEditingController(text: user?.designation ?? '');
    _organizationController =
        TextEditingController(text: user?.organizationName ?? 'Government of Uttar Pradesh');
    _departmentController =
        TextEditingController(text: user?.department ?? '');
    _officeController = TextEditingController(text: user?.office ?? '');
    _mobileController = TextEditingController(text: user?.mobile ?? '');

    _requiresApproval = user?.requiresApproval ?? true;
    _selectedApproverId = (user?.approvingOfficerId != null && user!.approvingOfficerId!.isNotEmpty)
        ? user.approvingOfficerId!
        : (_requiresApproval ? 'USR-003' : 'NONE');
    _selectedApproverName = user?.approvingOfficerName ??
        (_requiresApproval
            ? 'Anjali Sharma, IAS (Superintending Engineer)'
            : 'Self-Approver');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _designationController.dispose();
    _organizationController.dispose();
    _departmentController.dispose();
    _officeController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    if (_formKey.currentState?.validate() ?? false) {
      final isSelf = !_requiresApproval || _selectedApproverId == 'NONE';

      await ref.read(authProvider.notifier).updateProfile(
            name: _nameController.text.trim(),
            designation: _designationController.text.trim(),
            organizationName: _organizationController.text.trim(),
            department: _departmentController.text.trim(),
            office: _officeController.text.trim(),
            mobile: _mobileController.text.trim(),
            requiresApproval: !isSelf,
            approvingOfficerId: isSelf ? null : _selectedApproverId,
            approvingOfficerName: isSelf ? 'Self-Approver' : _selectedApproverName,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        title: const Text('Edit Official Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.marginMobile,
            vertical: 16,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                  label: 'Full Name',
                  controller: _nameController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Designation / Title',
                  controller: _designationController,
                  isRequired: true,
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Government / Organization / Company Name',
                  hint: 'e.g. Government of Uttar Pradesh, UPPTCL, Tata Motors',
                  controller: _organizationController,
                  isRequired: true,
                  prefixIcon:
                      const Icon(Icons.corporate_fare_outlined, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Department / Unit',
                  controller: _departmentController,
                  isRequired: true,
                  prefixIcon:
                      const Icon(Icons.account_balance_outlined, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Office / Division',
                  controller: _officeController,
                  isRequired: true,
                  prefixIcon:
                      const Icon(Icons.location_city_outlined, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                CustomTextField(
                  label: 'Official Mobile',
                  controller: _mobileController,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                // Approval Configuration Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.verified_user_outlined,
                                    size: 18, color: AppColors.primary),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Requires Journey Approver',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch.adaptive(
                            value: _requiresApproval,
                            activeColor: AppColors.primary,
                            onChanged: (val) {
                              setState(() {
                                _requiresApproval = val;
                                if (!val) {
                                  _selectedApproverId = 'NONE';
                                  _selectedApproverName =
                                      'No Approver (Self-Approver for Department Journeys)';
                                } else {
                                  _selectedApproverId = 'USR-003';
                                  _selectedApproverName =
                                      'Anjali Sharma, IAS (Superintending Engineer)';
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _requiresApproval
                            ? 'Your official journeys will require verification and sign-off by your designated Approving Officer.'
                            : '⚡ Self-Approver Mode: You are designated as self-approver. Journeys will be verified and approved automatically upon completion.',
                        style: TextStyle(
                          fontSize: 11,
                          color: _requiresApproval
                              ? AppColors.secondary
                              : AppColors.primary,
                          fontWeight: _requiresApproval
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                      if (_requiresApproval) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Designated Approving Officer *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _availableApprovers.any((a) => a['id'] == _selectedApproverId)
                              ? _selectedApproverId
                              : 'USR-003',
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusSm),
                            ),
                            prefixIcon: const Icon(Icons.person_pin_outlined,
                                size: 18, color: AppColors.primary),
                          ),
                          items: _availableApprovers.map((appr) {
                            final isNone = appr['id'] == 'NONE';
                            return DropdownMenuItem<String>(
                              value: appr['id'],
                              child: Text(
                                appr['name']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isNone
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isNone
                                      ? AppColors.primary
                                      : AppColors.onSurface,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedApproverId = val;
                                _selectedApproverName = _availableApprovers
                                    .firstWhere((a) => a['id'] == val)['name']!;
                                if (val == 'NONE') {
                                  _requiresApproval = false;
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Save Profile Changes',
                  onPressed: _handleSave,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
