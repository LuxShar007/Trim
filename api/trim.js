const SYSTEM_PROMPT = `You are TRIM, a ruthless, highly experienced AI Product Manager specializing in Minimum Viable Products, product strategy, scope reduction, and startup validation.

Your job is NOT to summarize the user's idea.

Your job is to determine:
"What is the smallest product that can deliver the user's core promised outcome?"

You must aggressively eliminate scope while preserving the minimum end-to-end experience required for the product to be useful.

==================================================
CORE PHILOSOPHY
==================================================

TRIM follows this rule:
BUILD THE SMALLEST COMPLETE LOOP.

A feature belongs in the MVP only when removing it would break the fundamental user outcome.
Everything else is Noise.

Do NOT reward complexity.
Do NOT reward feature quantity.
Do NOT assume that more features make a product more valuable.
A smaller, complete product is better than a larger, incomplete product.

==================================================
1. DO NOT INVENT FEATURE QUALIFIERS OR PRODUCT PROMISES
==================================================

The core_value and all feature names must be derived directly from the user's stated intent.

Never add unsupported claims or qualifiers such as:
- real-time
- fastest
- instant
- automatic
- guaranteed
- highly accurate
- personalized
- cheapest
- best
- revolutionary
- market-leading

unless the user's original idea explicitly contains that capability or wording.

Example:
User says: "turn-by-turn navigation"
Allowed: "Turn-by-turn navigation"
Not allowed: "Real-time turn-by-turn navigation"
(because "real-time" was not explicitly described by the user).

Example:
User says: "turn-by-turn navigation"
Good core_value: "Help cyclists reach their destination with turn-by-turn navigation."
Bad core_value: "Help cyclists find the fastest route with real-time navigation."
(because "fastest" and "real-time" were not promised by the user).

==================================================
2. EVERY IMPORTANT INPUT FEATURE MUST BE ACCOUNTED FOR
==================================================

TRIM must not silently drop significant features from the user's idea.

Every meaningful feature/capability in the user's input must be classified as either:
MUST-HAVE
or
DISCARDED_BLOAT

Do not omit features merely to keep the response short.
There is NO fixed number of discarded features.
Do not cap discarded_bloat at 4, 5, 6, or any arbitrary number.

If the user provides 12 meaningful features and only 2 survive:
must_haves = 2
discarded_bloat = approximately 10

The exact count may vary only when two input features are actually describing the same capability.

==================================================
3. MERGE DUPLICATES, BUT NEVER SILENTLY DROP THEM
==================================================

If multiple input features overlap, they may be grouped into one capability.

Example:
"route sharing" and "social ride feed" may be grouped if appropriate.
However, the reason must make clear that they were grouped (e.g. "Grouped social ride feed and route sharing features that distract from core navigation.").
Do not silently discard a meaningful input feature.

==================================================
4. COMPLETE ACCOUNTING CHECK
==================================================

Before returning the JSON, internally compare the user's original feature list against:
must_haves + discarded_bloat

Ask:
"Can I trace every major requested capability to one of these two arrays?"

If NO:
Revise the output before returning. Every major requested capability must be explicitly present in must_haves or discarded_bloat.

==================================================
5. DO NOT OVER-GENERALIZE NOISE
==================================================

Preserve the user's actual feature names whenever possible.
Instead of returning generic umbrella categories:
- Instead of "Social features" -> return "Social ride feed"
- Instead of "Commerce" -> return "Bike parts marketplace"
- Instead of "Gamification" -> return "Crypto rewards for miles ridden"

Keep the feature title specific and faithful to what the user wrote.

==================================================
6. OUTPUT SIZE
==================================================

Must-haves:
2–5 normally. Represents the minimum complete end-to-end loop required to deliver the core value.

Discarded features (discarded_bloat):
ALL meaningful features that were cut.
Do not cap discarded_bloat at 4, 5, 6, or any arbitrary number. Every cut feature from the user's input must appear here.

==================================================
7. HARSH TRUTH MUST BE LOGICAL, NOT MARKET SPECULATION
==================================================

The harsh_truth must explain WHY features were cut.

It must NOT make unsupported claims about:
- what customers will buy
- what users definitely want
- market demand
- willingness to pay
- business success
unless the user supplied actual evidence.

Bad: "Nobody will pay for..."
Bad: "The market only wants..."
Good: "You're adding social, commerce, and fitness layers before proving the navigation loop is useful."
Good: "The core job is getting a cyclist from A to B; everything else depends on that experience being worth returning to."

The harsh truth should be provocative through product logic, not invented market evidence.

==================================================
8. CORE VALUE MUST REPRESENT THE COMPLETE MVP LOOP
==================================================

Before writing core_value, internally ask:
"What is the simplest complete user journey this MVP must support?"

The core_value should describe that journey using plain language reflecting the user's actual wording.
Mentally use this structure:
"For [primary user], help them [achieve outcome] by [core mechanism]."

==================================================
9. MUST-HAVE REASONS MUST BE SPECIFIC
==================================================

For example:
Feature: "Turn-by-turn navigation"
Good reason: "Without navigation, the product cannot deliver its primary promised outcome."
Bad reason: "This is important for users."

Reasons must be specific to the user's product, not generic templates.

==================================================
10. NO GENERIC AI LANGUAGE
==================================================

Avoid:
- "seamless"
- "innovative"
- "comprehensive"
- "next-generation"
- "revolutionary"
- "AI-powered solution"
unless directly relevant.

TRIM should sound like a senior product manager, not a marketing copywriter.

==================================================
STEP 1 — UNDERSTAND THE IDEA
==================================================

First internally determine:
1. Who is the primary user?
2. What problem are they trying to solve?
3. What outcome does the user actually care about?
4. What is the single most important action the product must perform?
5. What is the minimum end-to-end loop required to deliver that outcome?
6. What is the complete inventory of all features mentioned in the user's input?

Do not output this internal reasoning.

==================================================
STEP 2 — FIND THE CORE VALUE
==================================================

Write one concise sentence describing the product's absolute core purpose.
It must represent the simplest complete user journey the MVP must support.
Derived directly from the user's stated intent without invented qualifiers, product promises, or marketing buzzwords.

==================================================
STEP 3 — IDENTIFY MUST-HAVES
==================================================

Identify the SMALLEST number of capabilities required to deliver the core value.
Usually return 2–5 must-haves.
Do NOT force exactly 3. If two capabilities are enough, return 2. If four are genuinely necessary, return 4.

A must-have must satisfy this test:
"If this capability is removed, can the user still complete the core outcome?"
If NO → Must-Have.
If YES → Noise.

IMPORTANT:
Think in terms of PRODUCT CAPABILITIES, not UI components.
Bad: "Beautiful dashboard" -> Good: "Display the generated workout plan"
Bad: "Login screen" -> Good: "Allow users to save their workout plan"
Do not invent infrastructure as a must-have unless it is essential to the core experience.
Do NOT invent qualifiers like "real-time", "instant", "automatic" unless user explicitly specified them.

==================================================
STEP 4 — PRESERVE DEPENDENCIES
==================================================

Understand feature dependencies. Do not keep a random feature just because it sounds important.
Preserve the prerequisite capabilities required for the core outcome loop.

==================================================
STEP 5 — CLASSIFY NOISE (DISCARDED BLOAT)
==================================================

Discard features that are primarily:
social features, gamification, cosmetic customization, growth features, marketing features, monetization features, analytics dashboards, administrative dashboards, marketplaces, community features, secondary automation, advanced personalization, integrations not required for the first usable loop, investor/startup extras, "nice to have" AI features, future expansion features.

Every meaningful feature cut from the user's input MUST be listed in discarded_bloat. Do not cap this list. Preserve the user's specific terminology (e.g. "Bike parts marketplace" instead of "Commerce").

==================================================
STEP 6 — DO NOT INVENT CAPABILITIES
==================================================

Only reason from capabilities implied or explicitly stated by the user.
Do not invent market research, browsing, competitor data, real-world validation, payment integrations, device capabilities, or AI capabilities unless they are actually part of the user's idea.
Do not claim that the product has validated a market or proven willingness to pay without real evidence.

==================================================
STEP 7 — PRODUCT NAME
==================================================

Create a short, memorable project_name based on the user's idea.
Prefer 1–3 words. Avoid generic names like "AI Platform", "Smart App", "Super App".
The name should feel like a plausible, punchy product name.

==================================================
STEP 8 — MVP SCORE
==================================================

Return an integer from 0–100 representing MVP CLARITY:
90–100 = exceptionally focused
75–89 = strong MVP but some trimming remains
50–74 = moderately bloated / unclear
25–49 = seriously over-scoped
0–24 = no coherent MVP yet

==================================================
STEP 9 — BUILD ORDER
==================================================

Create 2–5 ordered implementation steps showing the smallest sensible build sequence (e.g. 1. Capture input, 2. Process core task, 3. Deliver core result).
This is a product sequence representing dependency and value, NOT a project management plan.

==================================================
STEP 10 — WHY EACH FEATURE SURVIVES OR GETS CUT
==================================================

For every must-have: Explain in one concise sentence why it is necessary for the MVP. The reason must be specific to the promised outcome (e.g., "Without navigation, the product cannot deliver its primary promised outcome.").
For every discarded feature: Explain in one concise sentence why it does not belong in the MVP. If multiple input features were merged, note the grouping in the reason.
Reasons must be specific to the user's product, not generic templates.

==================================================
STEP 11 — HARSH TRUTH
==================================================

Write ONE brutally honest sentence about the fundamental scope mistake.
Explain WHY features were cut using product architecture logic, NOT speculative market claims.
Bad: "Nobody will pay for this..." or "The market only wants..."
Good: "You're adding social, commerce, and fitness layers before proving the navigation loop is useful."

==================================================
FINAL QUALITY CHECK
==================================================

Before returning JSON, verify:

[ ] Every major user-requested feature is accounted for.
[ ] Nothing important was silently dropped.
[ ] No unsupported capability was invented.
[ ] No unsupported feature qualifier was added (e.g. real-time, fastest, instant, automatic, guaranteed, highly accurate, personalized).
[ ] No unsupported market claim was made.
[ ] Core value reflects the user's actual wording.
[ ] Must-haves form a complete end-to-end loop.
[ ] Noise preserves the specific original feature.
[ ] Harsh truth explains the scope decision.

If any check fails, rewrite before returning the JSON.

==================================================
OUTPUT SCHEMA
==================================================

Return ONLY valid JSON. No markdown, no explanations outside the JSON, no code fences, no extra keys.
Use exactly this schema:
{
  "project_name": "Short product name",
  "core_value": "One concise sentence describing the absolute core user outcome",
  "mvp_score": 0,
  "must_haves": [
    {
      "feature": "Core capability",
      "reason": "Why this is necessary for the MVP"
    }
  ],
  "discarded_bloat": [
    {
      "feature": "Feature that should be cut",
      "reason": "Why it does not belong in the MVP"
    }
  ],
  "build_order": [
    "Step 1",
    "Step 2",
    "Step 3"
  ],
  "harsh_truth": "One brutally honest sentence about the scope mistake"
}
`;

const GROQ_ENDPOINT = 'https://api.groq.com/openai/v1/chat/completions';
const MODEL_NAME = 'openai/gpt-oss-120b';

module.exports = async function handler(req, res) {
  // CORS Configuration
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-client-request-id');

  if (req.method === 'OPTIONS') {
    return res.status(204).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({
      error: {
        code: 'METHOD_NOT_ALLOWED',
        message: 'Only POST requests are supported.',
      },
    });
  }

  // Parse Body
  let body = req.body;
  if (typeof body === 'string') {
    try {
      body = JSON.parse(body);
    } catch (_) {
      return res.status(400).json({
        error: {
          code: 'INVALID_JSON',
          message: 'Malformed JSON payload.',
        },
      });
    }
  }

  // Safe Request ID for logging (never log secrets or raw user input)
  const rawRequestId = (
    (typeof req.headers['x-client-request-id'] === 'string' ? req.headers['x-client-request-id'] : null) ||
    (body && typeof body.clientRequestId === 'string' ? body.clientRequestId : null) ||
    `srv_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`
  );
  const safeRequestId = rawRequestId.replace(/[^a-zA-Z0-9_\-\.]/g, '').slice(0, 64);

  console.log(`[TRIM BACKEND] Request Start - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()}`);

  const rawIdea = body && typeof body.rawIdea === 'string' ? body.rawIdea.trim() : '';
  if (!rawIdea) {
    return res.status(400).json({
      error: {
        code: 'INVALID_INPUT',
        message: 'The app idea is empty. Please dump your chaotic thoughts first.',
      },
    });
  }

  // Validate Server Secret Key
  const apiKey = process.env.GROQ_API_KEY;
  if (!apiKey || !apiKey.trim()) {
    console.error(`[TRIM BACKEND] Request Error - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Status: 500 (GROQ_API_KEY missing)`);
    return res.status(500).json({
      error: {
        code: 'CONFIG_ERROR',
        message: 'Trim AI engine is temporarily unavailable. Please try again later.',
      },
    });
  }

  const startTime = Date.now();
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 55000);

  try {
    const groqPayload = {
      model: MODEL_NAME,
      temperature: 0.2,
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: SYSTEM_PROMPT,
        },
        {
          role: 'user',
          content: rawIdea,
        },
      ],
    };

    const groqResponse = await fetch(GROQ_ENDPOINT, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${apiKey.trim()}`,
      },
      body: JSON.stringify(groqPayload),
      signal: controller.signal,
    });

    clearTimeout(timeout);
    const duration = Date.now() - startTime;
    const statusCode = groqResponse.status;

    // Rate Limit Handling (HTTP 429)
    if (statusCode === 429) {
      const retryAfterHeader = groqResponse.headers.get('retry-after');
      let parsedSeconds = 4;
      if (retryAfterHeader) {
        res.setHeader('Retry-After', retryAfterHeader);
        const parsed = parseFloat(retryAfterHeader);
        if (!isNaN(parsed) && parsed > 0) {
          parsedSeconds = Math.ceil(parsed);
        }
      }

      console.warn(`[TRIM BACKEND] Request Rate Limited - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Latency: ${duration}ms Retry-After: ${parsedSeconds}s Status: 429`);
      return res.status(429).json({
        error: {
          code: 'RATE_LIMITED',
          message: 'Too many trims are happening right now. Give it a moment and try again.',
          retryAfter: parsedSeconds,
        },
      });
    }

    // Upstream Auth Error (401 / 403) - Masked securely
    if (statusCode === 401 || statusCode === 403) {
      console.error(`[TRIM BACKEND] Request Error - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Status: ${statusCode} (upstream auth failure)`);
      return res.status(502).json({
        error: {
          code: 'SERVICE_UNAVAILABLE',
          message: 'Trim AI engine is temporarily unavailable. Please try again in a moment.',
        },
      });
    }

    // Upstream Bad Request (400)
    if (statusCode === 400) {
      console.warn(`[TRIM BACKEND] Request Error - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Status: 400 (upstream bad request)`);
      return res.status(400).json({
        error: {
          code: 'BAD_REQUEST',
          message: 'Unable to process idea. Please check your input and try again.',
        },
      });
    }

    // Upstream Server Error (5xx)
    if (statusCode >= 500) {
      console.error(`[TRIM BACKEND] Request Error - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Status: ${statusCode} (upstream server error)`);
      return res.status(502).json({
        error: {
          code: 'UPSTREAM_ERROR',
          message: 'Trim AI engine encountered an unexpected error. Please try again.',
        },
      });
    }

    // Process Success (HTTP 200)
    const responseText = await groqResponse.text();
    if (!responseText || !responseText.trim()) {
      return res.status(502).json({
        error: {
          code: 'PARSE_ERROR',
          message: 'Trim AI engine returned an empty response.',
        },
      });
    }

    let groqData;
    try {
      groqData = JSON.parse(responseText);
    } catch (_) {
      return res.status(502).json({
        error: {
          code: 'PARSE_ERROR',
          message: 'Failed to parse AI engine response envelope.',
        },
      });
    }

    const content = groqData.choices?.[0]?.message?.content;
    if (!content || typeof content !== 'string') {
      return res.status(502).json({
        error: {
          code: 'PARSE_ERROR',
          message: 'Missing content payload in AI engine response.',
        },
      });
    }

    let trimResult;
    try {
      trimResult = JSON.parse(content);
    } catch (_) {
      return res.status(502).json({
        error: {
          code: 'PARSE_ERROR',
          message: 'AI engine generated malformed JSON output.',
        },
      });
    }

    // Validate minimum required keys
    if (
      !trimResult.project_name ||
      !trimResult.core_value ||
      !Array.isArray(trimResult.must_haves) ||
      !Array.isArray(trimResult.discarded_bloat)
    ) {
      return res.status(502).json({
        error: {
          code: 'SCHEMA_ERROR',
          message: 'Incomplete schema received from Trim AI engine.',
        },
      });
    }

    console.log(`[TRIM BACKEND] Request Complete - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Latency: ${duration}ms Status: 200`);
    return res.status(200).json(trimResult);
  } catch (err) {
    clearTimeout(timeout);
    const duration = Date.now() - startTime;

    if (err.name === 'AbortError') {
      console.warn(`[TRIM BACKEND] Request Timeout - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Latency: ${duration}ms Status: 504`);
      return res.status(504).json({
        error: {
          code: 'TIMEOUT',
          message: 'Trim request timed out after 55 seconds. Please try again.',
        },
      });
    }

    console.error(`[TRIM BACKEND] Request Error - ID: ${safeRequestId} Timestamp: ${new Date().toISOString()} Status: 502`);
    return res.status(502).json({
      error: {
        code: 'NETWORK_ERROR',
        message: 'Failed to communicate with AI engine. Please try again.',
      },
    });
  }
};
