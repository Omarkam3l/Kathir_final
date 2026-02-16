// =====================================================
// SEND ORDER EMAILS - Supabase Edge Function (Zoho SMTP)
// =====================================================
// This Edge Function processes the email queue and sends
// order-related emails using Zoho Mail SMTP.
//
// Triggered by:
// - Cron job (every minute)
// - Manual invocation
//
// Email Types:
// 1. invoice - Order confirmation/invoice to user
// 2. new_order - New order notification to restaurant
// 3. ngo_pickup - Pickup notification to NGO
// 4. ngo_confirmation - Order confirmation to NGO
// =====================================================

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { SMTPClient } from 'https://deno.land/x/denomailer@1.6.0/mod.ts'

const ZOHO_EMAIL = Deno.env.get('ZOHO_EMAIL')!
const ZOHO_PASSWORD = Deno.env.get('ZOHO_PASSWORD')!
const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

interface EmailQueueItem {
  id: string
  order_id: string
  recipient_email: string
  recipient_type: 'user' | 'restaurant' | 'ngo'
  email_type: 'invoice' | 'new_order' | 'ngo_pickup' | 'ngo_confirmation'
  email_data: any
  attempts: number
}

serve(async (req) => {
  console.log('========================================')
  console.log('🚀 EMAIL FUNCTION INVOKED (Zoho SMTP)')
  console.log('Timestamp:', new Date().toISOString())
  console.log('========================================')
  
  try {
    // Check environment variables
    console.log('📋 Checking environment variables...')
    console.log('ZOHO_EMAIL exists:', !!ZOHO_EMAIL)
    console.log('ZOHO_PASSWORD exists:', !!ZOHO_PASSWORD)
    console.log('SUPABASE_URL exists:', !!SUPABASE_URL)
    console.log('SUPABASE_SERVICE_ROLE_KEY exists:', !!SUPABASE_SERVICE_ROLE_KEY)
    
    if (!ZOHO_EMAIL || !ZOHO_PASSWORD) {
      console.error('❌ Zoho credentials missing!')
      return new Response(JSON.stringify({ error: 'Zoho credentials not configured' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Initialize SMTP client
    console.log('🔌 Initializing Zoho SMTP client...')
    const smtpClient = new SMTPClient({
      connection: {
        hostname: 'smtp.zoho.com',
        port: 465,
        tls: true,
        auth: {
          username: ZOHO_EMAIL,
          password: ZOHO_PASSWORD,
        },
      },
    })

    // Initialize Supabase client
    console.log('🔌 Initializing Supabase client...')
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Get pending emails from queue
    console.log('📬 Fetching pending emails from queue...')
    const { data: emails, error } = await supabase
      .rpc('get_pending_emails', { p_limit: 10 })

    if (error) {
      console.error('❌ Error fetching emails:', error)
      console.error('Error details:', JSON.stringify(error, null, 2))
      return new Response(JSON.stringify({ error: error.message }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    console.log(`📊 Found ${emails?.length || 0} pending emails`)
    
    if (!emails || emails.length === 0) {
      console.log('✅ No pending emails to process')
      return new Response(JSON.stringify({ message: 'No pending emails' }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Log email details
    emails.forEach((email: EmailQueueItem, index: number) => {
      console.log(`\n📧 Email ${index + 1}/${emails.length}:`)
      console.log('  - ID:', email.id)
      console.log('  - Order ID:', email.order_id)
      console.log('  - Recipient:', email.recipient_email)
      console.log('  - Type:', email.email_type)
      console.log('  - Recipient Type:', email.recipient_type)
      console.log('  - Attempts:', email.attempts)
    })

    // Process each email sequentially with small delay
    console.log('\n🔄 Processing emails...')
    const results = []
    for (let i = 0; i < emails.length; i++) {
      try {
        await sendEmail(emails[i], supabase, smtpClient)
        results.push({ status: 'fulfilled' })
      } catch (error) {
        console.error(`Failed to send email:`, error)
        results.push({ status: 'rejected', reason: error })
      }
      
      // Small delay between emails (200ms)
      if (i < emails.length - 1) {
        console.log('   ⏳ Waiting 200ms before next email...')
        await new Promise(resolve => setTimeout(resolve, 200))
      }
    }

    const successCount = results.filter((r) => r.status === 'fulfilled').length
    const failureCount = results.filter((r) => r.status === 'rejected').length

    console.log('\n========================================')
    console.log('✅ EMAIL PROCESSING COMPLETE')
    console.log(`Total: ${emails.length}`)
    console.log(`Success: ${successCount}`)
    console.log(`Failed: ${failureCount}`)
    console.log('========================================')

    return new Response(
      JSON.stringify({
        message: 'Email processing complete',
        total: emails.length,
        success: successCount,
        failed: failureCount,
      }),
      {
        status: 200,
        headers: { 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('❌ FUNCTION ERROR:', error)
    console.error('Error stack:', error.stack)
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})

async function sendEmail(email: EmailQueueItem, supabase: any, smtpClient: SMTPClient) {
  console.log(`\n📤 Sending email to ${email.recipient_email}...`)
  console.log(`   Type: ${email.email_type}`)
  console.log(`   Order ID: ${email.order_id}`)
  
  try {
    console.log('   📝 Generating email content...')
    const { subject, html } = generateEmailContent(email)
    console.log(`   ✅ Subject: ${subject}`)

    console.log('   📮 Sending via Zoho SMTP...')
    console.log('   From:', ZOHO_EMAIL)
    console.log('   To:', email.recipient_email)
    
    // Send email via Zoho SMTP
    await smtpClient.send({
      from: `Kathir Orders<${ZOHO_EMAIL}>`,
      to: email.recipient_email,
      subject: subject,
      content: html,
      html: html,
    })

    console.log('   📬 Email sent successfully via Zoho')

    // Mark as sent
    console.log('   💾 Marking email as sent in database...')
    const { error: updateError } = await supabase.rpc('process_email_queue_item', {
      p_email_id: email.id,
      p_success: true,
    })
    
    if (updateError) {
      console.error('   ⚠️ Warning: Failed to update email status:', updateError)
    } else {
      console.log('   ✅ Email marked as sent')
    }

    console.log(`   ✅ Email sent successfully to ${email.recipient_email}`)
  } catch (error) {
    console.error(`   ❌ Failed to send email to ${email.recipient_email}`)
    console.error('   Error:', error.message)
    console.error('   Stack:', error.stack)

    // Mark as failed
    console.log('   💾 Marking email as failed in database...')
    const { error: updateError } = await supabase.rpc('process_email_queue_item', {
      p_email_id: email.id,
      p_success: false,
      p_error_message: error.message,
    })
    
    if (updateError) {
      console.error('   ⚠️ Warning: Failed to update email status:', updateError)
    }

    throw error
  }
}

function generateEmailContent(email: EmailQueueItem): {
  subject: string
  html: string
} {
  const data = email.email_data

  switch (email.email_type) {
    case 'invoice':
      return generateInvoiceEmail(data)
    case 'new_order':
      return generateNewOrderEmail(data)
    case 'ngo_pickup':
      return generateNgoPickupEmail(data)
    case 'ngo_confirmation':
      return generateNgoConfirmationEmail(data)
    default:
      throw new Error(`Unknown email type: ${email.email_type}`)
  }
}

function generateInvoiceEmail(data: any) {
  const itemsHtml = data.items
    .map(
      (item: any) => `
    <tr>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">${item.meal_title}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: center;">${item.quantity}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: right;">EGP ${item.unit_price.toFixed(2)}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: right; font-weight: 600;">EGP ${item.subtotal.toFixed(2)}</td>
    </tr>
  `
    )
    .join('')

  return {
    subject: `Order Confirmation - ${data.restaurant_name}`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #1f2937; margin: 0; padding: 0; background-color: #f9fafb;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 40px 20px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">Order Confirmed!</h1>
      <p style="color: #d1fae5; margin: 10px 0 0 0; font-size: 16px;">Thank you for your purchase</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 20px;">
      <p style="font-size: 16px; margin: 0 0 20px 0;">Hi ${data.buyer_name},</p>
      <p style="font-size: 16px; margin: 0 0 30px 0;">Your order from <strong>${data.restaurant_name}</strong> has been confirmed!</p>

      <!-- Order Details -->
      <div style="background-color: #f9fafb; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
        <h2 style="font-size: 18px; margin: 0 0 15px 0; color: #10b981;">Order Details</h2>
        <p style="margin: 5px 0;"><strong>Order ID:</strong> ${data.order_number.substring(0, 8)}</p>
        <p style="margin: 5px 0;"><strong>Date:</strong> ${new Date(data.created_at).toLocaleDateString()}</p>
        <p style="margin: 5px 0;"><strong>Delivery Method:</strong> ${data.delivery_type === 'delivery' ? 'Home Delivery' : data.delivery_type === 'pickup' ? 'Self Pickup' : 'Donated to NGO'}</p>
        ${data.delivery_type === 'delivery' ? `<p style="margin: 5px 0;"><strong>Address:</strong> ${data.delivery_address}</p>` : ''}
      </div>

      <!-- Items Table -->
      <table style="width: 100%; border-collapse: collapse; margin-bottom: 30px;">
        <thead>
          <tr style="background-color: #f3f4f6;">
            <th style="padding: 12px; text-align: left; font-weight: 600; color: #374151;">Item</th>
            <th style="padding: 12px; text-align: center; font-weight: 600; color: #374151;">Qty</th>
            <th style="padding: 12px; text-align: right; font-weight: 600; color: #374151;">Price</th>
            <th style="padding: 12px; text-align: right; font-weight: 600; color: #374151;">Total</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHtml}
        </tbody>
        <tfoot>
          <tr>
            <td colspan="3" style="padding: 12px; text-align: right; font-weight: 700; font-size: 18px; color: #10b981;">Total:</td>
            <td style="padding: 12px; text-align: right; font-weight: 700; font-size: 18px; color: #10b981;">EGP ${data.total_amount.toFixed(2)}</td>
          </tr>
        </tfoot>
      </table>

      <p style="font-size: 14px; color: #6b7280; margin: 30px 0 0 0;">If you have any questions, please contact us at ${ZOHO_EMAIL}</p>
    </div>

    <!-- Footer -->
    <div style="background-color: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
      <p style="margin: 0; font-size: 14px; color: #6b7280;">© 2026 Kathir. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `,
  }
}

function generateNewOrderEmail(data: any) {
  const itemsHtml = data.items
    .map(
      (item: any) => `
    <tr>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">${item.meal_title}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: center; font-weight: 600; font-size: 18px; color: #10b981;">${item.quantity}</td>
    </tr>
  `
    )
    .join('')

  return {
    subject: `🔔 New Order Received - ${data.buyer_name}`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #1f2937; margin: 0; padding: 0; background-color: #f9fafb;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #ef4444 0%, #dc2626 100%); padding: 40px 20px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">🔔 New Order!</h1>
      <p style="color: #fecaca; margin: 10px 0 0 0; font-size: 16px;">You have a new order to prepare</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 20px;">
      <p style="font-size: 16px; margin: 0 0 20px 0;">Hi ${data.restaurant_name},</p>
      <p style="font-size: 16px; margin: 0 0 30px 0;">You have received a new order from <strong>${data.buyer_name}</strong>!</p>

      <!-- Order Details -->
      <div style="background-color: #fef2f2; border-left: 4px solid #ef4444; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
        <h2 style="font-size: 18px; margin: 0 0 15px 0; color: #ef4444;">Order Information</h2>
        <p style="margin: 5px 0;"><strong>Order ID:</strong> ${data.order_number.substring(0, 8)}</p>
        <p style="margin: 5px 0;"><strong>Customer:</strong> ${data.buyer_name}</p>
        <p style="margin: 5px 0;"><strong>Delivery Method:</strong> ${data.delivery_type === 'delivery' ? 'Home Delivery' : data.delivery_type === 'pickup' ? 'Self Pickup' : 'Donated to NGO'}</p>
        <p style="margin: 5px 0;"><strong>Total Amount:</strong> EGP ${data.total_amount.toFixed(2)}</p>
      </div>

      <!-- Items to Prepare -->
      <h3 style="font-size: 16px; margin: 0 0 15px 0; color: #374151;">Items to Prepare:</h3>
      <table style="width: 100%; border-collapse: collapse; margin-bottom: 30px;">
        <thead>
          <tr style="background-color: #f3f4f6;">
            <th style="padding: 12px; text-align: left; font-weight: 600; color: #374151;">Meal</th>
            <th style="padding: 12px; text-align: center; font-weight: 600; color: #374151;">Quantity</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHtml}
        </tbody>
      </table>

      <p style="font-size: 14px; color: #6b7280; margin: 30px 0 0 0;">Please prepare this order as soon as possible. Update the order status in your dashboard.</p>
    </div>

    <!-- Footer -->
    <div style="background-color: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
      <p style="margin: 0; font-size: 14px; color: #6b7280;">© 2026 Kathir. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `,
  }
}

function generateNgoPickupEmail(data: any) {
  const itemsHtml = data.items
    .map(
      (item: any) => `
    <li style="margin: 8px 0; font-size: 16px;">${item.quantity}x ${item.meal_title}</li>
  `
    )
    .join('')

  return {
    subject: `🎁 Meal Donation Ready for Pickup - ${data.restaurant_name}`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #1f2937; margin: 0; padding: 0; background-color: #f9fafb;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%); padding: 40px 20px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">🎁 Meal Donation!</h1>
      <p style="color: #ede9fe; margin: 10px 0 0 0; font-size: 16px;">A generous donation awaits pickup</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 20px;">
      <p style="font-size: 16px; margin: 0 0 20px 0;">Hi ${data.ngo_name},</p>
      <p style="font-size: 16px; margin: 0 0 30px 0;"><strong>${data.buyer_name}</strong> has donated meals for you to pick up from <strong>${data.restaurant_name}</strong>!</p>

      <!-- Donation Details -->
      <div style="background-color: #faf5ff; border-left: 4px solid #8b5cf6; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
        <h2 style="font-size: 18px; margin: 0 0 15px 0; color: #8b5cf6;">Donation Details</h2>
        <p style="margin: 5px 0;"><strong>Donor:</strong> ${data.buyer_name}</p>
        <p style="margin: 5px 0;"><strong>Restaurant:</strong> ${data.restaurant_name}</p>
        <p style="margin: 5px 0;"><strong>Pickup Method:</strong> Please coordinate with restaurant</p>
      </div>

      <!-- Meals to Pickup -->
      <h3 style="font-size: 16px; margin: 0 0 15px 0; color: #374151;">Meals to Pickup:</h3>
      <ul style="list-style: none; padding: 0; margin: 0 0 30px 0;">
        ${itemsHtml}
      </ul>

      <p style="font-size: 14px; color: #6b7280; margin: 30px 0 0 0;">Please coordinate with the restaurant to arrange pickup. Thank you for your service to the community!</p>
    </div>

    <!-- Footer -->
    <div style="background-color: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
      <p style="margin: 0; font-size: 14px; color: #6b7280;">© 2026 Kathir. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `,
  }
}

function generateNgoConfirmationEmail(data: any) {
  const itemsHtml = data.items
    .map(
      (item: any) => `
    <tr>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb;">${item.meal_title}</td>
      <td style="padding: 12px; border-bottom: 1px solid #e5e7eb; text-align: center; font-weight: 600;">${item.quantity}</td>
    </tr>
  `
    )
    .join('')

  return {
    subject: `Order Confirmation - ${data.restaurant_name}`,
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif; line-height: 1.6; color: #1f2937; margin: 0; padding: 0; background-color: #f9fafb;">
  <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff;">
    <!-- Header -->
    <div style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); padding: 40px 20px; text-align: center;">
      <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700;">Order Confirmed!</h1>
      <p style="color: #d1fae5; margin: 10px 0 0 0; font-size: 16px;">Your meal order has been placed</p>
    </div>

    <!-- Content -->
    <div style="padding: 40px 20px;">
      <p style="font-size: 16px; margin: 0 0 20px 0;">Hi ${data.buyer_name},</p>
      <p style="font-size: 16px; margin: 0 0 30px 0;">Your order from <strong>${data.restaurant_name}</strong> has been confirmed!</p>

      <!-- Order Details -->
      <div style="background-color: #f0fdf4; border-left: 4px solid #10b981; border-radius: 8px; padding: 20px; margin-bottom: 30px;">
        <h2 style="font-size: 18px; margin: 0 0 15px 0; color: #10b981;">Order Information</h2>
        <p style="margin: 5px 0;"><strong>Order ID:</strong> ${data.order_number.substring(0, 8)}</p>
        <p style="margin: 5px 0;"><strong>Restaurant:</strong> ${data.restaurant_name}</p>
        <p style="margin: 5px 0;"><strong>Total Amount:</strong> EGP ${data.total_amount.toFixed(2)}</p>
      </div>

      <!-- Items -->
      <h3 style="font-size: 16px; margin: 0 0 15px 0; color: #374151;">Order Items:</h3>
      <table style="width: 100%; border-collapse: collapse; margin-bottom: 30px;">
        <thead>
          <tr style="background-color: #f3f4f6;">
            <th style="padding: 12px; text-align: left; font-weight: 600; color: #374151;">Meal</th>
            <th style="padding: 12px; text-align: center; font-weight: 600; color: #374151;">Quantity</th>
          </tr>
        </thead>
        <tbody>
          ${itemsHtml}
        </tbody>
      </table>

      <p style="font-size: 14px; color: #6b7280; margin: 30px 0 0 0;">The restaurant will prepare your order. You can track the status in your dashboard.</p>
    </div>

    <!-- Footer -->
    <div style="background-color: #f9fafb; padding: 20px; text-align: center; border-top: 1px solid #e5e7eb;">
      <p style="margin: 0; font-size: 14px; color: #6b7280;">© 2026 Kathir. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
    `,
  }
}
