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
import '../../../core/services_data.dart';

class AddSubscriptionScreen extends ConsumerStatefulWidget {
  const AddSubscriptionScreen({super.key});

  @override
  ConsumerState<AddSubscriptionScreen> createState() =>
      _AddSubscriptionScreenState();
}

class _AddSubscriptionScreenState
    extends ConsumerState<AddSubscriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedCycle = AppConstants.billingCycles.first;
  String _selectedCategory = AppConstants.defaultCategories.first;
  DateTime _nextBillingDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

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
      final sub = Subscription(
        userId: Supabase.instance.client.auth.currentUser!.id,
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        billingCycle: _selectedCycle,
        nextBillingDate: _nextBillingDate,
        category: _selectedCategory,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        status:
            _nextBillingDate.isBefore(DateTime.now()) ? 'overdue' : 'active',
      );
      await ref.read(subscriptionRepositoryProvider).addSubscription(sub);
      ref.invalidate(subscriptionsProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Subscription added!'),
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

  void _showAllServices() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40,
              spreadRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: AppTheme.textMutedDark.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Choose Service',
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppTheme.textLight,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Select from our popular supported services',
                      style: TextStyle(color: AppTheme.textMutedDark, fontSize: 13)),
                  ],
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.surfaceDark : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.85,
                ),
                itemCount: popularServices.length,
                itemBuilder: (context, index) {
                  final service = popularServices[index];
                  return _ServiceGridItem(
                    service: service,
                    onTap: () {
                      setState(() {
                        _nameCtrl.text = service.name;
                        _selectedCategory = service.category;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('New Subscription'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionLabel(label: 'Popular Services'),
                  GestureDetector(
                    onTap: _showAllServices,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.secondaryAccent.withOpacity(0.2),
                            AppTheme.secondaryAccent.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppTheme.secondaryAccent.withOpacity(0.3), width: 1.2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.grid_view_rounded,
                              size: 16, color: AppTheme.secondaryAccent),
                          SizedBox(width: 6),
                          Text('BROWSE ALL',
                              style: TextStyle(
                                  color: AppTheme.secondaryAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildServiceQuickSelect(),
              const SizedBox(height: 24),
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
              _buildCycleSelector(),
              const SizedBox(height: 20),
              _SectionLabel(label: 'Category'),
              const SizedBox(height: 8),
              _buildCategorySelector(isDark),
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
                    color: isDark
                        ? AppTheme.surfaceDark
                        : Colors.white,
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
                          color: isDark ? Colors.white : AppTheme.textLight,
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
              _buildGradientButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceQuickSelect() {
    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: popularServices.length,
        itemBuilder: (context, index) {
          final service = popularServices[index];
          return GestureDetector(
            onTap: () {
              setState(() {
                _nameCtrl.text = service.name;
                _selectedCategory = service.category;
              });
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: service.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _nameCtrl.text == service.name 
                      ? service.color 
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(service.icon, color: service.color, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      service.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: service.color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCycleSelector() {
    return Row(
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
                  color: selected ? Colors.white : AppTheme.textMutedDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.defaultCategories.map((cat) {
        final selected = _selectedCategory == cat;
        final icon = _categoryIcons[cat] ?? Icons.category_outlined;
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                Text(
                  cat,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : (isDark
                            ? AppTheme.textMutedDark
                            : AppTheme.textLight),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGradientButton() {
    return Container(
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
                      Icon(Icons.add_circle_outline, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Add Subscription',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
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
class _ServiceGridItem extends StatelessWidget {
  final ServiceData service;
  final VoidCallback onTap;

  const _ServiceGridItem({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: service.color.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: service.color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    service.color.withOpacity(0.2),
                    service.color.withOpacity(0.05),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: service.color.withOpacity(0.2)),
              ),
              child: Icon(service.icon, color: service.color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              service.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white.withOpacity(0.9) : AppTheme.textLight,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
