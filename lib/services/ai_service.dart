import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/activity.dart';
import '../core/constants.dart';
import 'package:intl/intl.dart';

class AiService {
  final String _apiKey;
  GenerativeModel? _model;
  ChatSession? _chatSession;
  List<Activity> _cachedActivities = [];
  Map<String, dynamic> _stats = {};
  final _currencyFormatter = NumberFormat.simpleCurrency(name: 'PHP ');

  AiService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      systemInstruction: Content.system(_buildBaseSystemInstruction()),
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  void startNewSession(List<Activity> activities) {
    _cachedActivities = activities;
    _calculateStats(activities);

    _chatSession = _model!.startChat(
      history: [
        Content.model([
          TextPart(
            'I have access to the agricultural activity database with ${activities.length} records. '
            'Total Budget: ${_currencyFormatter.format(_stats['totalBudget'] ?? 0)}. '
            'I am ready to assist you with analysis and planning.',
          ),
        ]),
      ],
    );
  }

  /// Updates the cached activities used for RAG without resetting the chat session.
  void updateActivities(List<Activity> activities) {
    _cachedActivities = activities;
    _calculateStats(activities);
  }

  void _calculateStats(List<Activity> activities) {
    double totalBudget = 0;
    double totalSpent = 0;
    Map<String, int> sectorCounts = {};
    Map<String, int> statusCounts = {};

    for (var a in activities) {
      totalBudget += a.totalBudget;
      totalSpent += a.actualExpenditure;
      sectorCounts[a.sector] = (sectorCounts[a.sector] ?? 0) + 1;
      statusCounts[a.status] = (statusCounts[a.status] ?? 0) + 1;
    }

    _stats = {
      'totalBudget': totalBudget,
      'totalSpent': totalSpent,
      'sectorCounts': sectorCounts,
      'statusCounts': statusCounts,
      'activityCount': activities.length,
    };
  }

  String _buildBaseSystemInstruction() {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM dd, YYYY').format(now);
    
    return '''
You are the "AWFPS Intelligence Engine," a premium AI administrative consultant for the City Agriculture Office.
Today's Date: $dateStr

PERSONALITY:
- Professional, analytical, and highly proactive.
- You speak as a trusted technical advisor who understands the complexities of agricultural budgeting.
- You are helpful and encouraging, but strict about data accuracy.

RESPONSE STRUCTURE:
1. 📌 **Quick Summary**: A 1-2 sentence overview of the answer.
2. 📊 **Analysis**: The core data presented clearly (use tables for multiple figures).
3. 💡 **Insights & Recommendations**: Strategic advice based on the data (e.g., "Consider expediting PR for Sector X").
4. 🕒 **Data Recency**: Remind the user that this is live Firestore data.

CRITICAL RULES:
1. DATA SOURCE: All analysis must be based ONLY on the provided context. If unsure, ask for clarification.
2. FINANCIAL PRECISION: Always use exact figures (PHP) formatted with thousands separators. Use 💰 for budget and 📉 for expenses.
3. BOTTLENECK DETECTION: Proactively flag activities where 'PR Balance' or 'PPMP Balance' is critically low (less than 10% of budget).
4. MULTILINGUAL: Seamlessly switch between English, Filipino, and Bisaya based on the user's input.
5. VISUAL HIERARCHY: Use Markdown headers (###), bold text, and bullet points. Use Emojis (🌾, 📦, 🚜, ✅, ⚠️) to categorize information.
6. NO HALLUCINATION: Never make up PR numbers or budget figures.

DOMAIN KNOWLEDGE:
- SECTORS: ${AppConstants.sectors.join(', ')}.
- FUNDING SOURCES: ${AppConstants.fundingSources.join(', ')}.
- WORKFLOW: Planned ➔ PR Prepared ➔ Obre & Abstract ➔ PO Prepared ➔ Obligated ➔ Completed.
- QUARTERS: Current focus should align with the current date ($dateStr).
''';
  }

  List<Activity> _retrieveRelevantActivities(
    String query,
    List<Activity> allActivities,
  ) {
    if (query.length < 3) return allActivities.take(10).toList();

    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toList();
    if (terms.isEmpty) return allActivities.take(10).toList();

    final scored = allActivities
        .map((a) {
          int score = 0;
          final text =
              '${a.activityName} ${a.sector} ${a.subSector} ${a.status} ${a.responsiblePerson} ${a.prNumber}'
                  .toLowerCase();

          for (final term in terms) {
            if (text.contains(term)) {
              score += 10;
              if (a.activityName.toLowerCase().contains(term)) score += 20;
              if (a.sector.toLowerCase().contains(term)) score += 15;
            }
          }
          return MapEntry(a, score);
        })
        .where((e) => e.value > 0)
        .toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).take(20).toList();
  }

  String _formatActivitiesForContext(List<Activity> activities) {
    if (activities.isEmpty) {
      return "NO_MATCHING_DATA: No specific activities found in the Firestore database for this query.";
    }

    final buffer = StringBuffer();
    buffer.writeln("### RETRIEVED FIRESTORE DATA (${activities.length} records)");
    buffer.writeln("Note: These are the most relevant records based on the user's query.");
    buffer.writeln("");

    for (var a in activities) {
      final dynamic breakdown = a.breakdown;
      final dynamic prNum = a.prNumber;

      String breakdownStr = "";
      try {
        if (breakdown != null && breakdown is List && breakdown.isNotEmpty) {
          breakdownStr = "\n    Breakdown: [${breakdown.map((b) => "${b.name}: ${b.amount}").join(", ")}]";
        }
      } catch (_) {}

      String appropStr = "";
      try {
        if (prNum != null && prNum is String && prNum.isNotEmpty) {
          appropStr = "\n    Procurement: PR#$prNum | Supplier: ${a.supplierApprop} | Status: ${a.statusApprop} (${a.statusAppropDate ?? 'N/A'})";
        }
      } catch (_) {}

      buffer.writeln("#### ${a.activityName} (ID: ${a.id})");
      buffer.writeln("- Sector: ${a.sector} > ${a.subSector}");
      buffer.writeln("- Status: ${a.status} (Owner: ${a.responsiblePerson})");
      buffer.writeln("- Financials: Budget ${_currencyFormatter.format(a.totalBudget)} | Spent ${_currencyFormatter.format(a.actualExpenditure)} | PR Bal: ${_currencyFormatter.format(a.prBalance)} | PPMP Bal: ${_currencyFormatter.format(a.ppmpBalance)}");
      buffer.writeln("- Quarterly Allocation: Q1:${a.q1Budget}, Q2:${a.q2Budget}, Q3:${a.q3Budget}, Q4:${a.q4Budget}$breakdownStr$appropStr");
      buffer.writeln("");
    }

    return buffer.toString();
  }

  Stream<String> sendMessageStream(String message) async* {
    if (_chatSession == null) {
      yield "Session not initialized. Please try refreshing the chat.";
      return;
    }

    try {
      // Step 1: Retrieval
      final relevantActivities = _retrieveRelevantActivities(
        message,
        _cachedActivities,
      );
      final contextString = _formatActivitiesForContext(relevantActivities);

      // Step 2: Augment the prompt
      final augmentedPrompt = '''
[SYSTEM CONTEXT - LIVE FIRESTORE DATA]
$contextString

[USER QUERY]
$message

INSTRUCTION:
Provide a premium, structured response following the "AWFPS Intelligence Engine" guidelines. 
Ensure you highlight any financial bottlenecks or low balances found in the retrieved data.
''';

      final responseStream = _chatSession!.sendMessageStream(
        Content.text(augmentedPrompt),
      );

      String fullResponse = "";
      await for (final chunk in responseStream) {
        if (chunk.text != null) {
          fullResponse += chunk.text!;
          yield fullResponse;
        }
      }
    } on GenerativeAIException catch (e) {
      final errorMsg = e.toString().toLowerCase();

      if (errorMsg.contains('api key not found') ||
          errorMsg.contains('invalid api key')) {
        yield "⚠️ **API Key Error:** The Gemini API key provided appears to be invalid or expired. Please check your settings.";
        return;
      }

      if (errorMsg.contains('quota') || errorMsg.contains('429')) {
        yield "⚠️ **Rate Limit Exceeded:** You've reached the free tier limit for Gemini. Please wait a minute and try again.";
        return;
      }

      if (_cachedActivities.isNotEmpty) {
        yield _localFallbackSearch(message, _cachedActivities);
        return;
      }
      yield "The AI engine is currently busy (Error: ${e.message}). Please try again in a moment.";
    } catch (e) {
      if (_cachedActivities.isNotEmpty) {
        yield _localFallbackSearch(message, _cachedActivities);
        return;
      }
      yield "Communication Error: ${e.toString()}";
    }
  }

  Future<String> sendMessage(String message, {int retryCount = 0}) async {
    if (_chatSession == null) {
      return "Session not initialized. Please try refreshing the chat.";
    }

    try {
      // Step 1: Retrieval
      final relevantActivities = _retrieveRelevantActivities(
        message,
        _cachedActivities,
      );
      final contextString = _formatActivitiesForContext(relevantActivities);

      // Step 2: Augment the prompt
      final augmentedPrompt = '''
[SYSTEM CONTEXT - LIVE FIRESTORE DATA]
$contextString

[USER QUERY]
$message

INSTRUCTION:
Provide a premium, structured response following the "AWFPS Intelligence Engine" guidelines. 
Ensure you highlight any financial bottlenecks or low balances found in the retrieved data.
''';

      final response = await _chatSession!.sendMessage(
        Content.text(augmentedPrompt),
      );
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } on GenerativeAIException catch (e) {
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('503') && retryCount < 2) {
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return sendMessage(message, retryCount: retryCount + 1);
      }

      if (errorMsg.contains('api key not found') ||
          errorMsg.contains('invalid api key')) {
        return "⚠️ **API Key Error:** The Gemini API key provided appears to be invalid or expired. Please check your settings.";
      }

      if (errorMsg.contains('quota') || errorMsg.contains('429')) {
        return "⚠️ **Rate Limit Exceeded:** You've reached the free tier limit for Gemini. Please wait a minute and try again.";
      }

      if (errorMsg.contains('invalid') ||
          errorMsg.contains('not found') ||
          errorMsg.contains('key')) {
        return "⚠️ **API Configuration Error:** The AI engine couldn't be authorized. Please check your Gemini API key in settings.";
      }

      if (_cachedActivities.isNotEmpty) {
        return _localFallbackSearch(message, _cachedActivities);
      }
      return "The AI engine is currently busy (Error: ${e.message}). Please try again in a moment.";
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('safety')) {
        return "I cannot answer this query due to safety filters. Please rephrase your question.";
      }

      if (errorStr.contains('socket') ||
          errorStr.contains('connection') ||
          errorStr.contains('failed to host lookup')) {
        if (_cachedActivities.isNotEmpty) {
          return _localFallbackSearch(message, _cachedActivities);
        }
        return "⚠️ **Network Error:** Please check your internet connection and try again.";
      }

      if (_cachedActivities.isNotEmpty) {
        return _localFallbackSearch(message, _cachedActivities);
      }
      return "Communication Error: ${e.toString()}";
    }
  }

  String _localFallbackSearch(String query, List<Activity> activities) {
    final searchInput = query.toLowerCase();
    final terms = searchInput
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 2)
        .toList();

    // Attempt specific search
    List<Activity> results = [];
    if (terms.isNotEmpty) {
      results = activities.where((a) {
        final text =
            '${a.activityName} ${a.sector} ${a.subSector} ${a.status} ${a.responsiblePerson}'
                .toLowerCase();
        return terms.any((term) => text.contains(term));
      }).toList();
    }

    final buffer = StringBuffer();

    if (results.isEmpty) {
      // Last resort: show general overview instead of failure message
      buffer.writeln(
        "I couldn't find specific activities for \"$query\" in my local cache. However, here is a general overview of the database:\n",
      );
      buffer.writeln("- **Total Activities:** ${activities.length}");
      buffer.writeln(
        "- **Sectors Covered:** ${activities.map((a) => a.sector).toSet().length}",
      );

      double totalBudget = activities.fold(0, (sum, a) => sum + a.totalBudget);
      buffer.writeln(
        "- **Global Budget:** ${_currencyFormatter.format(totalBudget)}",
      );

      buffer.writeln(
        "\nTry searching for specific terms like a sector name (e.g., 'Livestock') or a status.",
      );
      return buffer.toString();
    }

    buffer.writeln(
      "I found ${results.length} related activities in my local cache:\n",
    );

    results.sort((a, b) => b.totalBudget.compareTo(a.totalBudget));

    for (var i = 0; i < (results.length > 8 ? 8 : results.length); i++) {
      final a = results[i];
      buffer.writeln("- **${a.activityName}**");
      buffer.writeln("  - Sector: ${a.sector} | Status: ${a.status}");
      buffer.writeln(
        "  - Budget: ${_currencyFormatter.format(a.totalBudget)}",
      );
    }

    if (results.length > 8) {
      buffer.writeln(
        "\n*...and ${results.length - 8} more. Please use the dashboard filters for more details.*",
      );
    }

    return buffer.toString();
  }
}
