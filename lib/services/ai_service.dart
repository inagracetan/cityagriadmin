import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/activity.dart';
import '../core/constants.dart';

class AiService {
  final String _apiKey;
  late final GenerativeModel _model;
  ChatSession? _chatSession;

  AiService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
  }

  void startNewSession(List<Activity> activities) {
    final systemInstruction = _buildSystemInstruction(activities);
    _chatSession = _model.startChat(history: [
      Content.system(systemInstruction),
      Content.model([TextPart('I have loaded the data for ${activities.length} activities. I am ready to assist you with detailed analysis, budget tracking, and schedule management for the City Agriculture Office.')]),
    ]);
  }

  String _buildSystemInstruction(List<Activity> activities) {
    // Convert activities to a structured JSON-like list for better AI comprehension
    final activitiesJson = activities.map((a) => {
      'id': a.id,
      'name': a.activityName,
      'sector': a.sector,
      'subSector': a.subSector,
      'status': a.status,
      'responsible': a.responsiblePerson,
      'budget': {
        'total': a.totalBudget,
        'q1': a.q1Budget,
        'q2': a.q2Budget,
        'q3': a.q3Budget,
        'q4': a.q4Budget,
      },
      'financials': {
        'prAmount': a.prAmount,
        'prBalance': a.prBalance,
        'ppmpAmount': a.ppmpAmount,
        'actualExpenditure': a.actualExpenditure,
      },
      'timing': {
        'targetDate': a.targetDate,
        'quarter': a.quarter,
      }
    }).toList();

    return '''
You are the "AWFPS Intelligence Engine," a highly specialized AI assistant for the AgriWork & Financial Planning System.
Your knowledge is grounded in the City Agriculture Office's operational data.

CORE MISSION:
Provide accurate, data-driven insights to help administrators optimize agricultural programs, track fund utilization, and ensure timely activity execution.

DOMAIN KNOWLEDGE:
- SECTORS: ${AppConstants.sectors.join(', ')}.
- FUNDING SOURCES: ${AppConstants.fundingSources.join(', ')}. Includes specialized funds like 20% Development Fund (20% DF), Gender and Development (GAD), and CPOC.
- WORKFLOW: Activities move from "Planned" -> "PR Prepared" -> "Obre & Abstract Signature" -> "PO Prepared" -> "Obligated" -> "Completed".
- QUARTERS: Agricultural planning is quarterly (Q1-Q4).

LANGUAGE SUPPORT:
- You are fully multilingual. You must respond in the language used by the user.
- You have expert-level proficiency in **English**, **Filipino (Tagalog)**, and **Bisaya (Cebuano)**.
- If a user asks in Bisaya (e.g., "Pila ang nabilin nga budget sa Crop Section?"), you must answer in Bisaya.
- If a user asks in Filipino (e.g., "Ano ang status ng mga activities sa ASSU?"), you must answer in Filipino.

CURRENT DATASET:
$activitiesJson

ANALYTICAL CAPABILITIES:
1. BUDGET ANALYSIS: You can calculate total allocations, spent amounts, and remaining balances across sectors or funding sources.
2. STATUS TRACKING: Identify bottlenecks (e.g., "Which activities are stuck in 'PR Prepared' for too long?").
3. PERSONNEL OVERVIEW: Summarize workloads for responsible persons like ${AppConstants.staffList.join(', ')}.
4. QUARTERLY PLANNING: Suggest focus areas based on target dates.

RESPONSE GUIDELINES:
- Use MARKDOWN for clarity (tables, bold text, bullet points).
- If asked for a summary, always include a "Key Takeaway" or "Action Item" (translated to the user's language).
- Be precise with numbers. If a balance is zero, mention it.
- If data is missing for a specific query, suggest which fields the user should update in the app.
- Tone: Professional, analytical, and proactive.

EXAMPLE INTERACTION (BISAYA):
User: "Unsay status sa mga activities sa Crop Section?"
Assistant: "Ang **Crop Section** naay 12 ka aktibidad. Sa pagkakaron, 65% na ang nagamit nga budget. **Action Item:** Naay 3 ka aktibidad nga 'Planned' pa gihapon bisan og Q2 na ang target date."
''';
  }

  Future<String> sendMessage(String message) async {
    if (_chatSession == null) {
      return "Session not initialized. Please try again.";
    }

    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? "I'm sorry, I couldn't generate a response.";
    } catch (e) {
      return "Error: ${e.toString()}";
    }
  }
}
