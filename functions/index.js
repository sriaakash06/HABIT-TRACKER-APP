const functions = require("firebase-functions");
const admin = require("firebase-admin");
const axios = require("axios");

admin.initializeApp();

exports.getZaraResponse = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }

  const userMessage = data.message;
  const chatHistory = data.history || [];
  const habitContext = data.habitContext || "";

  // Get API Key from environment configuration
  // Using functions.config() as requested by user
  // Set this using: firebase functions:config:set groq.key="YOUR_KEY"
  const apiKey = functions.config().groq ? functions.config().groq.key : null;

  if (!apiKey) {
    console.error("GROQ_API_KEY is missing in functions.config()");
    throw new functions.https.HttpsError(
      "failed-precondition",
      "The GROQ API key is not configured in the backend."
    );
  }

  try {
    const response = await axios.post(
      "https://api.groq.com/openai/v1/chat/completions",
      {
        model: "llama-3.3-70b-versatile",
        messages: [
          {
            role: "system",
            content: `You are 'Zara', a high-energy, futuristic, and friendly AI habit companion. You speak English with casual Tamil slang like 'da', 'ko', 'machan', 'nanba'. Your goal is to be a motivational coach. Analyze the user's current habits and streaks if provided. Be concise, punchy, and helpful. Don't be too repetitive with the slang. Context:\n${habitContext}`,
          },
          ...chatHistory.map((m) => ({
            role: m.isUser ? "user" : "assistant",
            content: m.text,
          })),
          {
            role: "user",
            content: userMessage,
          },
        ],
        temperature: 0.7,
        max_tokens: 1024,
      },
      {
        headers: {
          Authorization: `Bearer ${apiKey}`,
          "Content-Type": "application/json",
        },
      }
    );

    return {
      response: response.data.choices[0].message.content,
    };
  } catch (error) {
    console.error("GROQ API Error:", error.response ? error.response.data : error.message);
    throw new functions.https.HttpsError(
      "internal",
      "Error communicating with GROQ API"
    );
  }
});
