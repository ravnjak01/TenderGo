import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/services/user_service.dart';
import 'package:tendergo/shared/widgets/feedback/snackbar_helper.dart';

class RateUserScreen extends StatefulWidget {
  final UserService userService;
  final String tenderId;
  final String ratedUserId;
  final String? ratedUserName;

  const RateUserScreen({
    super.key,
    required this.userService,
    required this.tenderId,
    required this.ratedUserId,
    this.ratedUserName,
  });

  @override
  State<RateUserScreen> createState() => _RateUserScreenState();
}

class _RateUserScreenState extends State<RateUserScreen> {
  final TextEditingController _commentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int _score = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final tenderId = widget.tenderId.trim();
    final ratedUserId = widget.ratedUserId.trim();

    if (tenderId.isEmpty || ratedUserId.isEmpty) {
      SnackbarHelper.show(
        context,
        'Missing tender or user information for rating.',
        isError: true,
      );
      return;
    }

    if (_score < 1 || _score > 5) {
      SnackbarHelper.show(
        context,
        'Please choose a rating between 1 and 5.',
        isError: true,
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? true)) return;

    final comment = _commentController.text.trim();
    final request = RateUserRequest(
      tenderId: tenderId,
      ratedUserId: ratedUserId,
      score: _score,
      comment: comment.isEmpty ? null : comment,
    );

    setState(() => _submitting = true);

    try {
      await widget.userService.rateUser(request);
      if (!mounted) return;

      SnackbarHelper.show(context, 'Rating submitted successfully.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.show(context, 'Failed to submit rating.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

//sljedece promjeniti da pise za koji je tender vezano
  @override
  Widget build(BuildContext context) {
    final ratedName = (widget.ratedUserName ?? '').trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Rate User')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ratedName.isEmpty ? 'Leave a rating' : 'Rate $ratedName',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your rating helps build trust in the marketplace.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 6,
                      children: List.generate(5, (index) {
                        final value = index + 1;
                        final selected = value <= _score;
                        return IconButton(
                          onPressed: _submitting
                              ? null
                              : () => setState(() => _score = value),
                          iconSize: 34,
                          icon: Icon(
                            selected ? Icons.star_rounded : Icons.star_border_rounded,
                            color: selected ? Colors.amber.shade700 : AppColors.outline,
                          ),
                          tooltip: '$value star${value > 1 ? 's' : ''}',
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 500,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Comment (optional)',
                        hintText: 'Share your experience...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Submit rating'),
                      ),
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
