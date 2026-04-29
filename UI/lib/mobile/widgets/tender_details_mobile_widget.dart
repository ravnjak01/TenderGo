import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const TenderApp());
}

class TenderApp extends StatelessWidget {
  const TenderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D0F14),
        cardColor: const Color(0xFF161920),
        dividerColor: const Color(0xFF2A2F3F),
      ),
      home: const TenderDetailsScreen(),
    );
  }
}

class TenderDetailsScreen extends StatefulWidget {
  const TenderDetailsScreen({super.key});

  @override
  State<TenderDetailsScreen> createState() => _TenderDetailsScreenState();
}

class _TenderDetailsScreenState extends State<TenderDetailsScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitted = false;

  final Color _accent = const Color(0xFF5B7FFF);
  final Color _gold = const Color(0xFFF5C542);
  final Color _green = const Color(0xFF3ECF8E);
  final Color _red = const Color(0xFFFF5F5F);
  final Color _muted = const Color(0xFF737891);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // TOP BAR
              SliverAppBar(
                pinned: true,
                backgroundColor: const Color(0xFF0D0F14).withOpacity(0.88),
                elevation: 0,
                leading: _buildHeaderIcon(Icons.chevron_left),
                title: Text(
                  'Tender Details',
                  style: GoogleFonts.syne(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                actions: [
                  _buildHeaderIcon(Icons.share_outlined),
                  const SizedBox(width: 18),
                ],
              ),

              // GALLERY
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 220,
                  child: Stack(
                    children: [
                      PageView(
                        controller: _pageController,
                        onPageChanged: (idx) => setState(() => _currentPage = idx),
                        children: [
                          _buildSlide("🏗️", [const Color(0xFF1A2346), const Color(0xFF2A3A7A)]),
                          _buildSlide("📐", [const Color(0xFF1A3A2A), const Color(0xFF2A7A5A)]),
                          _buildSlide("🏢", [const Color(0xFF3A1A1A), const Color(0xFF7A2A2A)]),
                        ],
                      ),
                      Positioned(
                        top: 14, left: 14,
                        child: _buildBadge("● Open", _green.withOpacity(0.15), _green),
                      ),
                      Positioned(
                        top: 14, right: 14,
                        child: _buildBadge("${_currentPage + 1} / 3", Colors.black45, _muted),
                      ),
                      Positioned(
                        bottom: 10, left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(3, (i) => _buildDot(i == _currentPage)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // CONTENT
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // HEADER
                    Text("#TDR-2024-0048", style: GoogleFonts.syne(color: _accent, fontWeight: FontWeight.w600, letterSpacing: 1.5, fontSize: 11)),
                    const SizedBox(height: 7),
                    Text("City Center Mixed-Use Development Complex", style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800, height: 1.25)),
                    const SizedBox(height: 20),

                    // STATS
                    Row(
                      children: [
                        _buildStatCard("\$480K", "Max Budget", _gold),
                        const SizedBox(width: 10),
                        _buildStatCard("12d", "Deadline", _red),
                        const SizedBox(width: 10),
                        _buildStatCard("27", "Total Bids", _accent),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // DESCRIPTION
                    _buildSectionCard("Description", 
                      child: Text(
                        "Seeking qualified contractors for a mixed-use development in the Sarajevo city centre — comprising 12 residential floors, 3 commercial levels, and underground parking for 280 vehicles.",
                        style: GoogleFonts.dmSans(color: const Color(0xFF9DA3B8), fontSize: 14, height: 1.7),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // TENDER INFO
                    _buildSectionCard("Tender Info", 
                      child: Column(
                        children: [
                          _buildDetailRow(Icons.location_on_outlined, "Location", "Sarajevo, Bosnia"),
                          _buildDetailRow(Icons.work_outline, "Category", "Infrastructure"),
                          _buildDetailRow(Icons.access_time, "Posted", "3 days ago"),
                          _buildDetailRow(Icons.calendar_today_outlined, "Deadline", "May 11, 2025"),
                          _buildDetailRow(Icons.analytics_outlined, "Status", "Open", valColor: _green),
                          const Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Divider(color: Color(0xFF2A2F3F)),
                          ),
                          _buildPosterRow(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // DIVIDER
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text("PLACE YOUR BID", style: GoogleFonts.syne(color: _muted, fontSize: 11, letterSpacing: 1)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // BID FORM
                    _buildSectionCard("Your Proposal", 
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel("Offered Price"),
                          _buildTextField(prefix: "\$", suffix: "USD", hint: "0.00"),
                          const SizedBox(height: 20),
                          _buildFieldLabel("Delivery Days", optional: true),
                          _buildTextField(suffix: "days", hint: "e.g. 90"),
                          const SizedBox(height: 20),
                          _buildFieldLabel("Proposal", optional: true),
                          _buildTextField(hint: "Describe your approach...", maxLines: 4),
                          const SizedBox(height: 24),
                          _buildSubmitButton(),
                          const SizedBox(height: 12),
                          Center(child: Text("By submitting, you agree to the platform's terms.", style: TextStyle(color: _muted, fontSize: 11))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // HELPER WIDGETS
  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2230),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2F3F)),
      ),
      child: Icon(icon, size: 18, color: Colors.white),
    );
  }

  Widget _buildSlide(String emoji, List<Color> colors) {
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: colors)),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 48))),
    );
  }

  Widget _buildDot(bool active) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 2.5),
      height: 6, width: active ? 18 : 6,
      decoration: BoxDecoration(color: active ? Colors.white : Colors.white38, borderRadius: BorderRadius.circular(3)),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Text(text, style: GoogleFonts.syne(color: textCol, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(String val, String lbl, Color col) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF161920),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF2A2F3F)),
        ),
        child: Column(
          children: [
            Container(height: 2, color: col.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text(val, style: GoogleFonts.syne(color: col, fontWeight: FontWeight.w800, fontSize: 17)),
            Text(lbl, style: GoogleFonts.syne(color: _muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String label, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF161920),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2F3F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.syne(color: _muted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String key, String val, {Color? valColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 8),
          Text(key, style: TextStyle(color: _muted, fontSize: 12)),
          const Spacer(),
          Text(val, style: TextStyle(color: valColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPosterRow() {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: _accent,
          child: const Text("AK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Amir Kovačević", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text("Client since 2021", style: TextStyle(color: _muted, fontSize: 11)),
          ],
        )
      ],
    );
  }

  Widget _buildFieldLabel(String label, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label.toUpperCase(), style: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF9DA3B8))),
          if (optional) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(color: const Color(0xFF1E2230), borderRadius: BorderRadius.circular(4)),
              child: Text("Optional", style: TextStyle(color: _muted, fontSize: 9)),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildTextField({String? prefix, String? suffix, String? hint, int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefix != null ? Padding(padding: const EdgeInsets.all(15), child: Text(prefix, style: TextStyle(color: _gold, fontWeight: FontWeight.bold))) : null,
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.all(15), child: Text(suffix, style: TextStyle(color: _muted, fontSize: 12))) : null,
        fillColor: const Color(0xFF1E2230),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2F3F))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2F3F))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accent)),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: () => setState(() => _isSubmitted = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isSubmitted ? [_green, const Color(0xFF2BAE75)] : [_accent, const Color(0xFF7C5BFF)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: (_isSubmitted ? _green : _accent).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_isSubmitted ? Icons.check : Icons.send, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(_isSubmitted ? "Bid Submitted!" : "Submit Bid", style: GoogleFonts.syne(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}