# AI Meal Fill - Quick Start Guide

## Setup (One-time)

1. **Verify API Key in .env**
   ```env
   GEMINI_API_KEY=AIzaSyAgJjiGzxZIogI1WZY3apcQxmvdr7KuzNw
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the App**
   ```bash
   flutter run
   ```

## How to Use

### For Restaurant Users:

1. **Navigate to Add Meal Screen**
   - Login as restaurant
   - Go to Meals tab
   - Click "+" button

2. **Upload Meal Image**
   - Tap the image upload area
   - Select a meal photo from gallery
   - Wait for image to load

3. **Click "Fill with AI" Button**
   - Green button appears below image
   - Has sparkle icon (✨)
   - Click to start AI analysis

4. **Wait for AI Processing**
   - Loading indicator shows
   - Takes 2-5 seconds typically
   - "AI is analyzing..." message displays

5. **Review AI Results**
   - Form auto-fills with:
     - Meal title (Arabic)
     - Description (Arabic)
     - Category
     - Original price
     - Discounted price
   - Success message shows confidence scores

6. **Adjust if Needed**
   - Edit any field manually
   - Change category if incorrect
   - Adjust prices as needed

7. **Complete & Publish**
   - Add quantity
   - Set expiry date
   - Set pickup deadline (optional)
   - Click "Publish Meal"

## What the AI Provides

### ✅ Auto-filled Fields:
- **Title**: Short, descriptive name in Arabic
- **Description**: Creative, appetizing description in Arabic
- **Category**: Best matching category from 7 options
- **Original Price**: Suggested market price in EGP
- **Discounted Price**: 50% or less of original

### ⚠️ Still Need Manual Input:
- **Quantity Available**: Number of portions
- **Expiry Date**: When meal expires
- **Pickup Deadline**: When customer must pickup (optional)

## Example Flow

```
1. Upload image of "Shawarma"
   ↓
2. Click "Fill with AI"
   ↓
3. AI fills:
   - Title: "شاورما دجاج"
   - Description: "شاورما دجاج طازجة مع الخضار والصوص الخاص..."
   - Category: "Meals"
   - Original: 80.00 EGP
   - Discounted: 40.00 EGP
   ↓
4. You adjust:
   - Quantity: 10
   - Expiry: Tomorrow 8 PM
   ↓
5. Publish ✅
```

## Confidence Scores

After AI fills the form, you'll see confidence scores:
- **Title**: How confident AI is about the meal name
- **Category**: How confident about the category
- **High (>80%)**: Very reliable
- **Medium (50-80%)**: Review recommended
- **Low (<50%)**: Definitely review and adjust

## Troubleshooting

### "Please select an image first"
- You need to upload an image before clicking AI button

### "AI extraction failed"
- Check internet connection
- Try again with a clearer image
- Manually fill the form if issue persists

### Wrong category selected
- AI might misidentify complex dishes
- Simply select the correct category manually

### Prices seem off
- AI uses general market prices
- Adjust based on your restaurant's pricing
- Consider your location and quality

## Tips for Best Results

### 📸 Image Quality:
- Use clear, well-lit photos
- Show the full dish
- Avoid blurry or dark images
- Close-up works better than far away

### 🎯 Supported Dishes:
- Works best with common Egyptian dishes
- Recognizes international cuisine
- May struggle with very unique/rare items

### ⚡ Speed:
- First use might be slower
- Subsequent uses are faster
- Web version may be slower than mobile

## Categories Available

1. **Meals** - Main dishes, rice, pasta
2. **Bakery** - Bread, pastries, baked goods
3. **Meat & Poultry** - Raw/cooked meat, chicken
4. **Seafood** - Fish, shrimp, seafood dishes
5. **Vegetables** - Fresh produce, salads
6. **Desserts** - Sweets, cakes, desserts
7. **Groceries** - Packaged goods, misc items

## Privacy & Data

- Images sent to Google Gemini AI
- No images stored on our servers
- Only used for meal info extraction
- Complies with Google's privacy policy

## Cost

- Free for restaurant users
- Powered by Gemini AI
- No per-use charges
- Included in your subscription

## Support

If you encounter issues:
1. Check your internet connection
2. Verify image is clear and < 5MB
3. Try a different image
4. Contact support if problem persists

---

**Ready to try?** Upload a meal image and click "Fill with AI"! ✨
