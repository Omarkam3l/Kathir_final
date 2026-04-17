# Meta WhatsApp Business Templates - Kathir App

## Overview
You need to create these 4 templates in your Meta Business Manager for WhatsApp Business API.

**Important Notes:**
- All templates must be approved by Meta before use
- Templates cannot be edited after approval (must create new version)
- Use exact template names as specified
- Category should be "TRANSACTIONAL" for all
- Language: English (US) or Arabic based on your preference

---

## Template 1: Order Confirmation (User)

**Template Name:** `order_confirmation_user`

**Category:** Transactional

**Language:** English (US)

**Template Content:**
```
🎉 Order Confirmed!

Hi {{1}},

Your order #{{2}} has been confirmed!

📦 Order Details:
{{3}}

💰 Total: {{4}} EGP

📍 Delivery Address:
{{5}}

⏰ Estimated Ready Time: {{6}}

Thank you for choosing Kathir! 🌱

Track your order: {{7}}
```

**Variables:**
1. `{{1}}` - Customer Name
2. `{{2}}` - Order ID
3. `{{3}}` - Order Items (formatted list)
4. `{{4}}` - Total Amount
5. `{{5}}` - Delivery Address
6. `{{6}}` - Estimated Ready Time
7. `{{7}}` - Tracking URL

**Buttons (Optional):**
- Quick Reply: "Track Order"
- URL Button: "View Order Details" → `https://kathir.app/orders/{{order_id}}`

---

## Template 2: New Order Alert (Restaurant)

**Template Name:** `new_order_restaurant`

**Category:** Transactional

**Language:** English (US)

**Template Content:**
```
🔔 New Order Received!

Order #{{1}}

👤 Customer: {{2}}
📞 Phone: {{3}}

📦 Order Items:
{{4}}

💰 Total: {{5}} EGP

📍 Delivery Type: {{6}}
{{7}}

⏰ Requested Time: {{8}}

Please prepare the order promptly!

View Details: {{9}}
```

**Variables:**
1. `{{1}}` - Order ID
2. `{{2}}` - Customer Name
3. `{{3}}` - Customer Phone
4. `{{4}}` - Order Items (formatted list)
5. `{{5}}` - Total Amount
6. `{{6}}` - Delivery Type (Delivery/Pickup/Donation)
7. `{{7}}` - Address or Pickup Instructions
8. `{{8}}` - Requested Time
9. `{{9}}` - Restaurant Dashboard URL

**Buttons (Optional):**
- Quick Reply: "Accept Order"
- Quick Reply: "View Details"
- URL Button: "Open Dashboard" → `https://kathir.app/restaurant/orders/{{order_id}}`

---

## Template 3: Donation Pickup Alert (NGO)

**Template Name:** `donation_pickup_ngo`

**Category:** Transactional

**Language:** English (US)

**Template Content:**
```
🎁 New Donation Available!

Donation Order #{{1}}

🏪 Restaurant: {{2}}
📞 Contact: {{3}}

📦 Donated Items:
{{4}}

📍 Pickup Location:
{{5}}

⏰ Ready for Pickup: {{6}}

Please coordinate pickup with the restaurant.

Thank you for helping fight food waste! 🌱

View Details: {{7}}
```

**Variables:**
1. `{{1}}` - Order ID
2. `{{2}}` - Restaurant Name
3. `{{3}}` - Restaurant Phone
4. `{{4}}` - Donated Items (formatted list)
5. `{{5}}` - Pickup Address
6. `{{6}}` - Ready Time
7. `{{7}}` - NGO Dashboard URL

**Buttons (Optional):**
- Quick Reply: "Confirm Pickup"
- URL Button: "View Details" → `https://kathir.app/ngo/donations/{{order_id}}`
- Phone Button: "Call Restaurant" → `{{restaurant_phone}}`

---

## Template 4: Order Status Update

**Template Name:** `order_status_update`

**Category:** Transactional

**Language:** English (US)

**Template Content:**
```
📦 Order Status Update

Hi {{1}},

Your order #{{2}} status has been updated:

Status: {{3}}

{{4}}

{{5}}

Track your order: {{6}}
```

**Variables:**
1. `{{1}}` - Customer Name
2. `{{2}}` - Order ID
3. `{{3}}` - New Status (Preparing/Ready/Out for Delivery/Completed)
4. `{{4}}` - Status Message (custom message based on status)
5. `{{5}}` - Additional Info (ETA, pickup code, etc.)
6. `{{6}}` - Tracking URL

**Buttons (Optional):**
- URL Button: "Track Order" → `https://kathir.app/orders/{{order_id}}`
- Quick Reply: "Contact Support"

---

## How to Create Templates in Meta Business Manager

### Step 1: Access WhatsApp Manager
1. Go to https://business.facebook.com
2. Select your Business Account
3. Click on "WhatsApp Accounts" in the left menu
4. Select your WhatsApp Business Account
5. Click on "Message Templates"

### Step 2: Create New Template
1. Click "Create Template" button
2. Fill in the template details:
   - **Name:** Use exact name from above (e.g., `order_confirmation_user`)
   - **Category:** Select "TRANSACTIONAL"
   - **Language:** Select "English (US)" or your preferred language

### Step 3: Add Template Content
1. **Header (Optional):** You can add an emoji or text header
2. **Body:** Copy the template content from above
3. **Variables:** Click "Add Variable" for each `{{1}}`, `{{2}}`, etc.
4. **Footer (Optional):** Add footer text like "Kathir - Fighting Food Waste"
5. **Buttons (Optional):** Add buttons as specified

### Step 4: Add Sample Content
Meta requires sample content for approval:

**Example for order_confirmation_user:**
- `{{1}}` = "Ahmed Hassan"
- `{{2}}` = "ORD-12345"
- `{{3}}` = "1x Koshary (Large)\n1x Fresh Juice"
- `{{4}}` = "85.00"
- `{{5}}` = "123 Tahrir St, Cairo"
- `{{6}}` = "30 minutes"
- `{{7}}` = "https://kathir.app/orders/ORD-12345"

### Step 5: Submit for Review
1. Review your template
2. Click "Submit"
3. Wait for Meta approval (usually 1-3 business days)
4. Check approval status in Message Templates section

---

## Template Usage in Code

Once approved, use templates in your Edge Function:

```typescript
// Example: Send order confirmation to user
const response = await fetch(
  `https://graph.facebook.com/v22.0/${PHONE_NUMBER_ID}/messages`,
  {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${ACCESS_TOKEN}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      messaging_product: 'whatsapp',
      to: userPhone,
      type: 'template',
      template: {
        name: 'order_confirmation_user',
        language: { code: 'en_US' },
        components: [
          {
            type: 'body',
            parameters: [
              { type: 'text', text: customerName },      // {{1}}
              { type: 'text', text: orderId },           // {{2}}
              { type: 'text', text: orderItems },        // {{3}}
              { type: 'text', text: totalAmount },       // {{4}}
              { type: 'text', text: deliveryAddress },   // {{5}}
              { type: 'text', text: estimatedTime },     // {{6}}
              { type: 'text', text: trackingUrl },       // {{7}}
            ],
          },
        ],
      },
    }),
  }
);
```

---

## Testing Templates

### Before Approval (Test Mode):
- You can only send to verified test numbers
- Add test numbers in WhatsApp Manager → Settings → Test Numbers
- Use `hello_world` template for initial testing

### After Approval (Production):
- Can send to any valid WhatsApp number
- Must follow Meta's messaging policies
- Rate limits apply based on your tier

---

## Important Meta Policies

### Template Guidelines:
- ✅ Must be transactional (order updates, confirmations)
- ✅ Must include opt-out language if promotional
- ✅ Variables must be clearly indicated
- ✅ No misleading or spam content
- ❌ Cannot include promotional content in transactional templates
- ❌ Cannot use templates for marketing without proper category

### Messaging Limits:
- **Tier 1:** 1,000 conversations/day (default for new accounts)
- **Tier 2:** 10,000 conversations/day
- **Tier 3:** 100,000 conversations/day
- **Tier 4:** Unlimited (requires verification)

### Quality Rating:
- Maintain high quality rating to avoid restrictions
- Monitor user blocks and reports
- Respond to user messages within 24 hours
- Don't send spam or irrelevant messages

---

## Troubleshooting

### Template Rejected?
Common reasons:
1. **Variables not clear:** Make sure `{{1}}`, `{{2}}` are properly formatted
2. **Promotional content:** Transactional templates can't have marketing
3. **Missing information:** Add clear sample content
4. **Policy violation:** Review Meta's WhatsApp Business Policy

### Template Not Sending?
1. Check template is approved (green checkmark)
2. Verify phone number format (+20XXXXXXXXXX)
3. Check access token is valid
4. Verify phone number ID is correct
5. Check API response for error details

### Messages Not Delivered?
1. **Account not published:** Publish your WhatsApp Business Account
2. **Business verification pending:** Complete business verification
3. **Quality rating low:** Improve message quality
4. **Rate limit reached:** Wait or upgrade tier

---

## Next Steps

1. ✅ Create all 4 templates in Meta Business Manager
2. ✅ Submit for approval
3. ✅ Wait for approval (1-3 business days)
4. ✅ Test with verified numbers
5. ✅ Deploy to production
6. ✅ Monitor delivery and quality metrics

---

## Support Resources

- **Meta Business Help Center:** https://business.facebook.com/business/help
- **WhatsApp Business API Docs:** https://developers.facebook.com/docs/whatsapp
- **Template Guidelines:** https://developers.facebook.com/docs/whatsapp/message-templates/guidelines
- **Meta Business Support:** https://business.facebook.com/business/help/support

---

**Last Updated:** April 16, 2026
**Status:** Ready for Implementation
