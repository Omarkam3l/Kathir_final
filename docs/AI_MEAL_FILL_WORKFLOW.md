# AI Meal Fill Feature - Workflow Documentation

## Overview
The AI Meal Fill feature uses Google's Gemini AI to automatically extract meal information from uploaded images and populate the meal creation form.

## Feature Flow

### 1. User Journey
```
Restaurant uploads meal image
    ↓
"Fill with AI" button appears
    ↓
User clicks button
    ↓
AI analyzes image
    ↓
Form auto-fills with:
    - Meal title (Arabic)
    - Description (Arabic, creative)
    - Category
    - Price suggestions
    ↓
User reviews and adjusts
    ↓
User publishes meal
```

### 2. Technical Flow

#### A. Image Upload
- User selects image via `ImageUploadWidget`
- Image stored as `File` (mobile) or `Uint8List` (web)
- "Fill with AI" button becomes visible

#### B. AI Processing
1. **Trigger**: User clicks "Fill with AI" button
2. **Service**: `AiMealService.extractMealInfoFromBytes()`
3. **AI Model**: Gemini 2.0 Flash Exp
4. **Input**: Image bytes + Arabic prompt
5. **Output**: JSON with meal data

#### C. Form Population
- Title field ← `meal_title`
- Description field ← `description`
- Category chips ← `category_slug` (mapped)
- Original price ← `original_price_egp`
- Discounted price ← `discounted_price_egp`

#### D. User Feedback
- Loading indicator during processing
- Success message with confidence scores
- Error message if AI fails

## Components

### 1. AiMealService (`lib/core/services/ai_meal_service.dart`)
**Purpose**: Handle AI communication and data extraction

**Key Methods**:
- `extractMealInfoFromBytes(List<int> imageBytes)` - Main extraction method
- `_buildPrompt()` - Generates Arabic prompt for AI

**Response Schema**:
```json
{
  "meal_title": "string (Arabic)",
  "description": "string (Arabic, creative)",
  "category_slug": "enum (meals|bakery|meat_poultry|seafood|vegetables|desserts|groceries)",
  "price_suggestions": {
    "original_price_egp": "number",
    "discounted_price_egp": "number (≤ 50% of original)",
    "price_range_egp": "[min, max]"
  },
  "confidence": {
    "meal_title": "0-1",
    "description": "0-1",
    "category_slug": "0-1",
    "prices": "0-1"
  }
}
```

### 2. ImageUploadWidget (Updated)
**New Props**:
- `showAiButton: bool` - Show/hide AI button
- `onFillWithAi: VoidCallback?` - AI button callback

**Behavior**:
- Button only appears when image is selected
- Button disabled during AI processing

### 3. AddMealScreen (Updated)
**New State**:
- `_aiService: AiMealService` - AI service instance
- `_isAiProcessing: bool` - Processing state

**New Methods**:
- `_fillWithAi()` - Handles AI extraction and form filling
- `_mapCategorySlugToDisplay()` - Maps AI categories to display names

## Configuration

### Environment Variables (.env)
```env
GEMINI_API_KEY=your_api_key_here
```

### Dependencies (pubspec.yaml)
```yaml
dependencies:
  google_generative_ai: ^0.4.6
  flutter_dotenv: ^6.0.0
```

## Category Mapping

| AI Response | Display Name | Database Value |
|------------|--------------|----------------|
| meals | Meals | Meals |
| bakery | Bakery | Bakery |
| meat_poultry | Meat & Poultry | Meat & Poultry |
| seafood | Seafood | Seafood |
| vegetables | Vegetables | Vegetables |
| desserts | Desserts | Desserts |
| groceries | Groceries | Groceries |

## AI Prompt Strategy

### Language: Arabic
The prompt is in Arabic to get Arabic responses for:
- Meal titles
- Descriptions

### Prompt Structure:
1. **Context**: "You're extracting meal info for Egyptian restaurant app"
2. **Rules**: 
   - Short, direct meal titles
   - Creative, appetizing descriptions
   - Valid category selection
   - Reasonable Egyptian prices
   - Discount ≤ 50% of original
3. **Example**: Shows creative vs. plain descriptions
4. **Schema**: JSON structure specification

### Temperature: 0.7
- Balanced between creativity (descriptions) and accuracy (categories, prices)

## Error Handling

### Scenarios:
1. **No image selected**: Show error snackbar
2. **AI API failure**: Show error with details
3. **Invalid JSON response**: Parsing error caught
4. **Network timeout**: Standard exception handling

### Logging:
All events logged via `AuthLogger`:
- `ai.fill.start`
- `ai.meal.extract.start`
- `ai.meal.extract.response`
- `ai.meal.extract.success`
- `ai.fill.success`
- `ai.fill.failed`

## User Experience

### Visual Feedback:
1. **Button State**: 
   - Enabled: Green with sparkle icon
   - Disabled: Grayed out during processing

2. **Processing Indicator**:
   - Loading spinner
   - "AI is analyzing your meal image..." message
   - Green-tinted container

3. **Success Message**:
   - "✨ Form filled with AI!"
   - Confidence scores displayed
   - Green background
   - 4-second duration

4. **Error Message**:
   - Error details shown
   - Red background
   - 5-second duration

## Testing Checklist

- [ ] Upload image on mobile
- [ ] Upload image on web
- [ ] Click "Fill with AI" button
- [ ] Verify form fields populate
- [ ] Check Arabic text displays correctly
- [ ] Verify category mapping
- [ ] Test price suggestions are reasonable
- [ ] Confirm discount ≤ 50% of original
- [ ] Test error handling (no API key)
- [ ] Test error handling (invalid image)
- [ ] Verify confidence scores display
- [ ] Check loading states
- [ ] Test form validation after AI fill
- [ ] Verify user can edit AI-filled data
- [ ] Test meal creation with AI-filled data

## Future Enhancements

1. **Multi-language Support**: Detect user language preference
2. **Image Quality Check**: Warn if image quality is poor
3. **Batch Processing**: Fill multiple meals at once
4. **Learning**: Improve suggestions based on restaurant history
5. **Allergen Detection**: Auto-detect and list allergens
6. **Nutritional Info**: Extract calorie/nutrition estimates
7. **Similar Meals**: Suggest similar existing meals
8. **Price History**: Compare with restaurant's pricing patterns

## Performance Considerations

- **Image Size**: Max 5MB enforced
- **API Latency**: ~2-5 seconds typical
- **Caching**: Consider caching AI results for same image
- **Rate Limiting**: Monitor API usage
- **Fallback**: Manual entry always available

## Security

- API key stored in `.env` (not committed)
- Image bytes sent directly to Gemini (no intermediate storage)
- No PII in AI requests
- Logging excludes sensitive data

## Cost Estimation

**Gemini 2.0 Flash Exp Pricing** (as of implementation):
- Free tier available
- Pay-as-you-go after limits
- ~$0.001-0.002 per request (estimate)

**Monthly Cost Example**:
- 1000 meals/month = ~$1-2
- 10,000 meals/month = ~$10-20

## Support & Troubleshooting

### Common Issues:

1. **"GEMINI_API_KEY not found"**
   - Check `.env` file exists
   - Verify key is set correctly
   - Restart app after adding key

2. **"AI extraction failed"**
   - Check internet connection
   - Verify API key is valid
   - Check Gemini API status

3. **Wrong category selected**
   - AI confidence may be low
   - User can manually adjust
   - Report patterns for prompt improvement

4. **Prices seem off**
   - AI uses general Egyptian market prices
   - User should adjust based on their restaurant
   - Consider adding restaurant-specific context

## Implementation Summary

### Files Created:
- `lib/core/services/ai_meal_service.dart` - AI service

### Files Modified:
- `lib/features/restaurant_dashboard/presentation/screens/add_meal_screen.dart` - Added AI integration
- `lib/features/restaurant_dashboard/presentation/widgets/image_upload_widget.dart` - Added AI button
- `pubspec.yaml` - Added google_generative_ai dependency
- `.env` - Contains GEMINI_API_KEY

### Total Lines Added: ~350
### Total Lines Modified: ~50

---

**Status**: ✅ Implemented and Ready for Testing
**Version**: 1.0.0
**Last Updated**: 2026-02-02
