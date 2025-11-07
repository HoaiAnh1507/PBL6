"""
Google Gemini AI Integration for Mood-based Caption Refinement
Optional: Refine generated captions based on user mood
"""

import os
import requests
import time
from typing import Optional

# Configuration
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")  # Set this in environment
GEMINI_MODEL = "gemini-2.0-flash"  # Updated to match API URL
GEMINI_API_URL = f"https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent"


def refine_caption_with_gemini(original_caption: str, mood: str) -> Optional[str]:
    """
    Refine caption using Google Gemini based on user mood

    Args:
        original_caption: Raw caption from video captioning model
        mood: User selected mood (happy, sad, excited, etc.)

    Returns:
        Refined caption or None if API call fails
    """

    if not GEMINI_API_KEY:
        print("⚠️ GEMINI_API_KEY not set, skipping refinement")
        return original_caption

    if not original_caption or not mood or mood == "neutral":
        return original_caption

    try:
        # Create prompt for mood-based refinement
        prompt = f"""You are a social media caption writer. Transform the following video caption to match the specified mood.

RULES:
- Return ONLY ONE SHORT CAPTION (maximum 15 words)
- No explanations, options, or formatting
- No emojis unless essential
- Keep the core meaning of the original caption
- Match the {mood} mood perfectly
- Write in a natural, conversational tone

Original: "{original_caption}"
Mood: {mood}

Caption:"""

        payload = {
            "contents": [{"parts": [{"text": prompt}]}],
            "generationConfig": {
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 30,  # Reduced to ensure short caption
            },
        }

        headers = {"Content-Type": "application/json"}

        # Add API key to URL
        url = f"{GEMINI_API_URL}?key={GEMINI_API_KEY}"

        print(f"🤖 Refining caption with Gemini (mood: {mood})...")

        response = requests.post(url, json=payload, headers=headers, timeout=10)

        if response.status_code == 200:
            result = response.json()

            # Extract generated text
            candidates = result.get("candidates", [])
            if candidates and "content" in candidates[0]:
                content = candidates[0]["content"]
                parts = content.get("parts", [])
                if parts and "text" in parts[0]:
                    refined_caption = parts[0]["text"].strip()

                    print(f"✅ Caption refined successfully")
                    print(f"   Original: {original_caption}")
                    print(f"   Refined:  {refined_caption}")

                    return refined_caption

        print(f"⚠️ Gemini API returned unexpected response: {response.status_code}")
        print(f"   Response: {response.text[:200]}...")

    except requests.RequestException as e:
        print(f"❌ Gemini API request failed: {e}")
    except Exception as e:
        print(f"💥 Unexpected error in Gemini integration: {e}")

    # Fallback to original caption
    print("🔄 Falling back to original caption")
    return original_caption


def apply_simple_mood_modification(caption: str, mood: str) -> str:
    """
    Simple fallback mood modification without external API
    Used when Gemini is not available
    """

    if not mood or mood == "neutral":
        return caption

    mood_modifiers = {
        "happy": {
            "prefix": "",
            "suffix": " What a wonderful moment!",
            "replacements": {
                "walking": "strolling joyfully",
                "sitting": "relaxing happily",
                "eating": "enjoying delicious food",
            },
        },
        "sad": {
            "prefix": "With a heavy heart, ",
            "suffix": "",
            "replacements": {"beautiful": "bittersweet", "amazing": "touching"},
        },
        "excited": {
            "prefix": "",
            "suffix": " This is so exciting!",
            "replacements": {
                "walking": "rushing with excitement",
                "looking": "eagerly watching",
            },
        },
        "grateful": {
            "prefix": "Feeling grateful for ",
            "suffix": " Blessed to experience this.",
            "replacements": {},
        },
        "nostalgic": {
            "prefix": "Remembering when ",
            "suffix": " Those were the days...",
            "replacements": {},
        },
        "romantic": {
            "prefix": "",
            "suffix": " Love is in the air ❤️",
            "replacements": {"two people": "two hearts", "together": "in love"},
        },
    }

    modifier = mood_modifiers.get(mood.lower())
    if not modifier:
        return caption

    # Apply simple modifications
    modified_caption = caption

    # Apply word replacements
    for old_word, new_word in modifier["replacements"].items():
        modified_caption = modified_caption.replace(old_word, new_word)

    # Add prefix and suffix
    modified_caption = f"{modifier['prefix']}{modified_caption}{modifier['suffix']}"

    return modified_caption.strip()


# Example usage and testing
if __name__ == "__main__":
    test_caption = "A person walking in the park with a dog"
    test_mood = "happy"

    print("🧪 Testing caption refinement...")
    print(f"Original: {test_caption}")
    print(f"Mood: {test_mood}")

    # Test Gemini (if API key available)
    refined = refine_caption_with_gemini(test_caption, test_mood)
    print(f"Gemini refined: {refined}")

    # Test simple modification
    simple = apply_simple_mood_modification(test_caption, test_mood)
    print(f"Simple modified: {simple}")
