import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_localizations.dart';
import '../data/question_repository.dart';
import '../models/question.dart';
import '../models/country_profile.dart';
import '../services/app_settings_service.dart';
import '../widgets/tx_widgets.dart';
import 'question_session_screen.dart';

class QuestionSearchScreen extends StatefulWidget {
  const QuestionSearchScreen({super.key});
  @override
  State<QuestionSearchScreen> createState() => _QuestionSearchScreenState();
}

class _QuestionSearchScreenState extends State<QuestionSearchScreen> {
  final controller = TextEditingController();
  CountryProfile get profile => AppSettingsService.instance.country;
  List<Question> all = [];
  List<Question> results = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    all = await QuestionRepository().loadSeedQuestions(profile: profile);
    results = all;
    if (mounted) setState(() => loading = false);
  }

  void _search(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      results = query.isEmpty
          ? all
          : all.where((e) {
              final haystack = '${e.text} ${e.explanation} ${e.category}'.toLowerCase();
              return haystack.contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(TxText.pick('Soru Ara','Vragen zoeken','Fragen suchen','Search Questions'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                  child: TextField(
                    controller: controller,
                    onChanged: _search,
                    autofocus: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded),
                      hintText: TxText.pick('ABS, geçiş hakkı, kanama...','ABS, voorrang, bloeding...','ABS, Vorfahrt, Blutung...','ABS, right of way, bleeding...'),
                      filled: true,
                      fillColor: TxColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: results.isEmpty
                      ? Center(child: Text(TxText.pick('Eşleşen soru bulunamadı.','Geen passende vraag gevonden.','Keine passende Frage gefunden.','No matching question found.')))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          itemCount: results.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 9),
                          itemBuilder: (_, i) {
                            final q = results[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => QuestionSessionScreen(questionIds: [q.id])),
                              ),
                              child: TxCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: TxColors.blue.withValues(alpha: .15),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(Icons.quiz_rounded, color: TxColors.blue),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                                          const SizedBox(height: 5),
                                          Text(_pretty(q.category), style: const TextStyle(color: TxColors.muted, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: TxColors.muted),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  String _pretty(String v) => profile.localizedCategoryLabel(v, AppSettingsService.instance.locale);

}
