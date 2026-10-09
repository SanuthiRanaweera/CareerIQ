import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/career.dart';
import '../../../models/saved_career.dart';
import '../../../services/api_service.dart';
import '../../../services/saved_career_service.dart';
import '../widgets/career_state_views.dart';

/// Identifies the horizontal priority chip row.
const Key savedPriorityChipsKey = Key('saved-career-priority-chips');

/// My shortlist - the careers a student has bookmarked.
///
/// Each entry carries the student's own note and priority. They can filter by
/// priority, edit the note and priority, remove an entry (after confirming),
/// or open the career itself.
class SavedCareersPage extends StatefulWidget {
  const SavedCareersPage({
    super.key,
    required this.token,
    this.onCareerSelected,
    this.savedCareerService,
  });

  final String token;

  /// Opens a career's details. The list reloads when the returned Future
  /// completes, because the student may have removed the career there.
  final FutureOr<void> Function(Career career)? onCareerSelected;

  /// Injectable API client so the screen can be tested without a backend.
  final SavedCareerService? savedCareerService;

  @override
  State<SavedCareersPage> createState() => _SavedCareersPageState();
}

class _SavedCareersPageState extends State<SavedCareersPage> {
  static const String _all = 'All';

  late final SavedCareerService _service =
      widget.savedCareerService ?? SavedCareerService();

  List<SavedCareer> _saved = const [];
  String _selectedPriority = _all;
  bool _initialLoading = true;
  String? _error;

  /// Id of the entry being deleted, so its controls can be disabled.
  String? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final saved = await _service.getSavedCareers(
        widget.token,
        priority: _selectedPriority == _all ? '' : _selectedPriority,
      );
      if (!mounted) return;
      setState(() {
        _saved = saved;
        _initialLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _initialLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'Could not reach the server. Check your connection and try again.';
        _initialLoading = false;
      });
    }
  }

  void _selectPriority(String priority) {
    if (priority == _selectedPriority) return;
    setState(() => _selectedPriority = priority);
    _load();
  }

  Future<void> _open(SavedCareer saved) async {
    await widget.onCareerSelected?.call(saved.career);
    if (mounted) await _load();
  }

  Future<void> _edit(SavedCareer saved) async {
    final result = await showModalBottomSheet<_ShortlistEdit>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _EditShortlistSheet(saved: saved),
    );
    if (result == null || !mounted) return;

    try {
      await _service.updateSavedCareer(
        widget.token,
        saved.id,
        note: result.note,
        priority: result.priority,
      );
      if (!mounted) return;
      showCareerMessage(context, 'Shortlist entry updated', success: true);
      await _load();
    } on ApiException catch (error) {
      if (mounted) showCareerMessage(context, error.message);
    } catch (_) {
      if (mounted) {
        showCareerMessage(
          context,
          'Could not reach the server. Check your connection and try again.',
        );
      }
    }
  }

  Future<void> _confirmAndDelete(SavedCareer saved) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove from shortlist?'),
        content: Text('Remove "${saved.career.title}" from your shortlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deletingId = saved.id);
    try {
      await _service.deleteSavedCareer(widget.token, saved.id);
      if (!mounted) return;
      setState(() => _deletingId = null);
      showCareerMessage(
        context,
        '${saved.career.title} removed from your shortlist',
        success: true,
      );
      await _load();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      showCareerMessage(context, error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deletingId = null);
      showCareerMessage(
        context,
        'Could not reach the server. Check your connection and try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My shortlist')),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final options = [_all, ...savedCareerPriorities];
    return SizedBox(
      height: 56,
      child: ListView.separated(
        key: savedPriorityChipsKey,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return ChoiceChip(
            label: Text(option == _all ? 'All' : '$option priority'),
            selected: option == _selectedPriority,
            onSelected: (_) => _selectPriority(option),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const CareerLoadingView(message: 'Loading your shortlist...');
    }

    return RefreshIndicator(onRefresh: _load, child: _buildContent());
  }

  Widget _buildContent() {
    if (_error != null) {
      return CareerErrorView(message: _error!, onRetry: _load);
    }
    if (_saved.isEmpty) {
      return _selectedPriority == _all
          ? CareerEmptyView(
              icon: Icons.bookmark_border_rounded,
              title: 'No saved careers yet',
              message:
                  'Tap the bookmark on any career to add it to your shortlist.',
              onRetry: _load,
            )
          : CareerEmptyView(
              icon: Icons.filter_list_off_rounded,
              title: 'Nothing at this priority',
              message: 'No saved career has $_selectedPriority priority.',
              onRetry: () => _selectPriority(_all),
              actionLabel: 'Show all',
            );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      children: _saved
          .map(
            (saved) => _SavedCareerCard(
              saved: saved,
              deleting: _deletingId == saved.id,
              onOpen: () => _open(saved),
              onEdit: () => _edit(saved),
              onDelete: () => _confirmAndDelete(saved),
            ),
          )
          .toList(),
    );
  }
}

/// Badge colours per priority; the level is always written out as well.
const Map<String, (Color, Color)> _priorityColours = {
  'High': (Color(0xFFFEE2E2), Color(0xFFB91C1C)),
  'Medium': (Color(0xFFFEF3C7), Color(0xFFB45309)),
  'Low': (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
};

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final colours =
        _priorityColours[priority] ??
        const (Color(0xFFF1F5F9), Color(0xFF475569));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colours.$1,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$priority priority',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colours.$2,
        ),
      ),
    );
  }
}

class _SavedCareerCard extends StatelessWidget {
  const _SavedCareerCard({
    required this.saved,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    this.deleting = false,
  });

  final SavedCareer saved;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final career = saved.career;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: deleting ? null : onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      career.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _PriorityBadge(priority: saved.priority),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                career.category,
                style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 10),
              Text(
                career.salaryLabel,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              if (saved.note.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    saved.note,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14),
                  ),
                ),
              ],
              Align(
                alignment: Alignment.centerRight,
                child: deleting
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip:
                                'Edit note and priority for ${career.title}',
                            onPressed: onEdit,
                            icon: const Icon(Icons.edit_outlined),
                            color: const Color(0xFF3B82F6),
                          ),
                          IconButton(
                            tooltip: 'Remove ${career.title} from shortlist',
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: const Color(0xFFDC2626),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the edit sheet hands back when the student taps Save.
class _ShortlistEdit {
  const _ShortlistEdit({required this.note, required this.priority});

  final String note;
  final String priority;
}

class _EditShortlistSheet extends StatefulWidget {
  const _EditShortlistSheet({required this.saved});

  final SavedCareer saved;

  @override
  State<_EditShortlistSheet> createState() => _EditShortlistSheetState();
}

class _EditShortlistSheetState extends State<_EditShortlistSheet> {
  static const int _maxNoteLength = 300;

  late final TextEditingController _note = TextEditingController(
    text: widget.saved.note,
  );
  late String _priority = widget.saved.priority;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Lifts the sheet above the keyboard.
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.saved.career.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Text('Priority', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: savedCareerPriorities
                .map(
                  (priority) => ChoiceChip(
                    label: Text(priority),
                    selected: priority == _priority,
                    onSelected: (_) => setState(() => _priority = priority),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            maxLength: _maxNoteLength,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Your note',
              hintText: 'Why does this career interest you?',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                _ShortlistEdit(note: _note.text.trim(), priority: _priority),
              ),
              child: const Text('Save changes'),
            ),
          ),
        ],
      ),
    );
  }
}
