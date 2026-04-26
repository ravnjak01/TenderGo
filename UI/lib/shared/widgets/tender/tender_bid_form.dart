import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo/shared/core/error/bid_error_handler.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/services/bid_service.dart';
import 'package:tendergo/shared/widgets/tender/tender_section_label.dart';

/// Self-contained bid form. Manages its own controllers and submission state.
///
/// [onBidSuccess] is called after a successful submission so the parent screen
/// can reload the tender.
class TenderBidForm extends StatefulWidget {
  const TenderBidForm({
    super.key,
    required this.tender,
    required this.bidService,
    required this.onBidSuccess,
  });

  final TenderDto tender;
  final BidService bidService;
  final VoidCallback onBidSuccess;

  @override
  State<TenderBidForm> createState() => _TenderBidFormState();
}

class _TenderBidFormState extends State<TenderBidForm> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _proposalController = TextEditingController();
  final _deliveryDaysController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _priceController.dispose();
    _proposalController.dispose();
    _deliveryDaysController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final offeredPrice = double.parse(
      _priceController.text.replaceAll(',', '.').trim(),
    );
    final proposalText = _proposalController.text.trim();

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    var submitted = false;

    try {
      await widget.bidService.create(
        BidInsertRequest(
          tenderId: widget.tender.id,
          price: offeredPrice,
          note: proposalText.isEmpty ? null : proposalText,
        ),
      );
      submitted = true;
    } on BidAlreadyExistsException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } on BidServiceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not submit bid. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
    }

    if (!submitted || !mounted) return;

    _priceController.clear();
    _proposalController.clear();
    _deliveryDaysController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bid sent successfully.')),
    );

    // Parent refresh failures should not turn a successful submit into an error.
    try {
      widget.onBidSuccess();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF2),
        border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TenderSectionLabel(
              icon: Icons.gavel_rounded,
              label: 'Your Bid',
            ),
            const SizedBox(height: 12),
            const Text(
              'Send a Bid',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submit your offer for "${widget.tender.title}".',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Offered price (KM)',
                hintText: 'e.g. 12500.00',
              ),
              validator: (value) {
                final normalized = (value ?? '').replaceAll(',', '.').trim();
                if (normalized.isEmpty) return 'Offered price is required.';
                final parsed = double.tryParse(normalized);
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid price greater than 0.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deliveryDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Delivery days (optional)',
                hintText: 'e.g. 30',
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return null;
                final parsed = int.tryParse(text);
                if (parsed == null || parsed <= 0) {
                  return 'Delivery days must be a positive number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _proposalController,
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Proposal (optional)',
                hintText: 'Describe your delivery plan, scope, and terms.',
                alignLabelWithHint: true,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Submit bid'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
