/* eslint-disable */
// functions/index.js

/**
 * QubiQAI – ChatGPT Cloud Function
 *
 * HTTPS endpoint:
 *   exports.chatWithAi = onRequest(...)
 *
 * Flutter sends a POST JSON body:
 *   { userId: "...", messages: [ { role: "user", content: "hi" }, ... ] }
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const OpenAI = require("openai");

// Prevent accidental infinite scaling (cost control)
setGlobalOptions({maxInstances: 5});

// 🔐 OpenAI client – key comes from Firebase environment variable
const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

// -------------------- MAIN CHAT ENDPOINT --------------------
exports.chatWithAi = onRequest({cors: true}, async (req, res) => {
  // Only allow POST requests
  if (req.method !== "POST") {
    return res.status(405).json({error: "Only POST allowed"});
  }

  try {
    const {userId, messages} = req.body || {};

    if (!userId || !Array.isArray(messages)) {
      return res
        .status(400)
        .json({error: "userId and messages (array) are required"});
    }

    logger.info("chatWithAi request", {
      userId,
      messageCount: messages.length,
    });

    // -------------------- CALL OPENAI --------------------
    const completion = await client.chat.completions.create({
      model: "gpt-4.1-mini", // You can change to gpt-4o-mini etc.
      messages: messages.map((m) => ({
        role: m.role === "assistant" ? "assistant" : "user",
        content: m.content,
      })),
    });

    // -------------------- SAFE REPLY EXTRACTION --------------------
    const choices = completion && completion.choices ? completion.choices : [];
    const firstChoice = choices.length > 0 ? choices[0] : null;

    let reply = "Sorry, I couldn't generate a reply.";

    if (
      firstChoice &&
      firstChoice.message &&
      typeof firstChoice.message.content === "string"
    ) {
      reply = firstChoice.message.content.trim();
    }

    // TODO (later): Save conversation to Firestore for each student

    // -------------------- SEND RESPONSE --------------------
    return res.json({reply});
  } catch (err) {
    logger.error("chatWithAi error", err);
    return res.status(500).json({error: "Internal server error"});
  }
});
