import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme.dart';
import '../data/subscription_repository.dart';
import '../models/subscription_model.dart';
import '../../../core/constants.dart';
import '../../../core/currency_provider.dart';

class EditSubscriptionScreen extends ConsumerStatefulWidget {
  final Subscription subscription;
  const EditSubscriptionScreen({super.key, required this.subscription});

  @override
  ConsumerState<EditSubscriptionScreen> createState() =>
      _EditSubscriptionScreenState();
}

class _EditSubscriptionScreenState
    extends ConsumerState<EditSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _notesCtrl;
  late String _selectedCycle;
  late String _selectedCategory;
  late DateTime _nextBillingDate;
  bool _isLoading = false;
  bool _isDeleting = false;

  final Map<String, IconData> _categoryIcons = {
    'Entertainment': Icons.movie_outlined,
    'Productivity': Icons.work_outline_rounded,
    'Music': Icons.music_note_outlined,
    'Gaming': Icons.sports_esports_outlined,
    'Health&Fitness': Icons.fitness_center_rounded,
    'Education': Icons.school_outlined,
    'Shopping': Icons.shopping_bag_outlined,
    'Utilities': Icons.bolt_outlined,
    'Others': Icons.category_outlined,
  };

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    _nameCtrl = TextEditingController(text: s.name);
    _priceCtrl = TextEditingController(text: s.price.toString());
    _notesCtrl = TextEditingController(text: s.notes ?? '');
    _selectedCycle = s.billingCycle;
    _selectedCategory = s.category;
    _nextBillingDate = s.nextBillingDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _nextBillingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryAccent,
            onPrimary: Colors.white,
            surface: AppTheme.surfaceDark,
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _nextBillingDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updated = widget.subscription.copyWith(
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        billingCycle: _selectedCycle,
        nextBillingDate: _nextBillingDate,
        category: _selectedCategory,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status:
            _nextBillingDate.isBefore(DateTime.now()) ? 'overdue' : 'active',
      );
      await ref.read(subscriptionRepositoryProvider).updateSubscription(updated);
      ref.invalidate(subscriptionsProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Subscription updated!'),
              backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _delete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.surfaceDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Delete Subscription',
            style: TextStyle(
                color: isDark ? Colors.white : AppTheme.textLight,
                fontWeight: FontWeight.bold)),
        content: Text(
            'Are you sure you want to delete "${widget.subscription.name}"? This action cannot be undone.',
            style: const TextStyle(color: AppTheme.textMutedDark)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textMutedDark))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Delete')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      final notifier = ref.read(subscriptionsProvider.notifier);
      await notifier.removeSubscription(widget.subscription.id);
      
      if (mounted) {
        context.pop(); // Go back to dashboard
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ Subscription deleted'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Delete failed: $e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Edit Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: _isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: AppTheme.error, strokeWidth: 2))
                : const Icon(Icons.delete_outline, color: AppTheme.error),
            onPressed: _isDeleting ? null : _delete,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SectionLabel(label: 'Service Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textLight),
                decoration: const InputDecoration(
                  hintText: 'e.g. Netflix, Spotify...',
                  prefixIcon: Icon(Icons.label_outline,
                      color: AppTheme.textMutedDark),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Price'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textLight),
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(ref.watch(currencyProvider.notifier).symbol,
                      style: const TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Billing Cycle'),
              const SizedBox(height: 8),
              Row(
                children: AppConstants.billingCycles.map((cycle) {
                  final selected = _selectedCycle == cycle;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCycle = cycle),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryAccent
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: selected
                                ? AppTheme.primaryAccent
                                : AppTheme.surfaceDarkLighter,
                          ),
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.primaryAccent.withOpacity(0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          cycle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: selected
                                ? Colors.white
                                : AppTheme.textMutedDark,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Category'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: AppConstants.defaultCategories.map((cat) {
                  final selected = _selectedCategory == cat;
                  final icon = _categoryIcons[cat] ?? Icons.category_outlined;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.primaryAccent
                            : (isDark ? AppTheme.surfaceDark : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppTheme.primaryAccent
                              : (isDark
                                  ? AppTheme.surfaceDarkLighter
                                  : Colors.grey.shade300),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: AppTheme.primaryAccent.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : [],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon,
                              size: 16,
                              color: selected
                                  ? Colors.white
                                  : AppTheme.textMutedDark),
                          const SizedBox(width: 6),
                          Text(cat,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : (isDark
                                        ? AppTheme.textMutedDark
                                        : AppTheme.textLight),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Next Billing Date'),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppTheme.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark
                            ? AppTheme.surfaceDarkLighter
                            : Colors.grey.shade300,
                        width: 1.5),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          color: AppTheme.textMutedDark, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMMM dd, yyyy').format(_nextBillingDate),
                        style: TextStyle(
                          color:
                              isDark ? Colors.white : AppTheme.textLight,
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.chevron_right,
                          color: AppTheme.textMutedDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Notes (Optional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.textLight),
                decoration: const InputDecoration(
                  hintText: 'Anything to remember...',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_outlined,
                        color: AppTheme.textMutedDark),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryAccent, Color(0xFF6A1DD4)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryAccent.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _isLoading ? null : _save,
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline,
                                    color: Colors.white),
                                SizedBox(width: 8),
                                Text('Save Changes',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textMutedDark,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}
