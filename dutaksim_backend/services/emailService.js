const nodemailer = require('nodemailer');

/**
 * Email service for sending notifications
 * Uses SMTP configuration from environment variables
 */

class EmailService {
  constructor() {
    this.transporter = null;
    this.initializeTransporter();
  }

  initializeTransporter() {
    // Check if SMTP configuration is available
    if (!process.env.SMTP_HOST || !process.env.SMTP_USER || !process.env.SMTP_PASSWORD) {
      console.warn('SMTP configuration not found. Email notifications will be disabled.');
      return;
    }

    try {
      this.transporter = nodemailer.createTransporter({
        host: process.env.SMTP_HOST,
        port: parseInt(process.env.SMTP_PORT) || 587,
        secure: parseInt(process.env.SMTP_PORT) === 465, // true for 465, false for other ports
        auth: {
          user: process.env.SMTP_USER,
          pass: process.env.SMTP_PASSWORD,
        },
      });

      console.log('Email service initialized successfully');
    } catch (error) {
      console.error('Failed to initialize email service:', error);
    }
  }

  isConfigured() {
    return this.transporter !== null;
  }

  /**
   * Send session invitation email
   */
  async sendSessionInvitation(recipientEmail, inviterName, sessionName, sessionCode) {
    if (!this.isConfigured()) {
      console.warn('Email service not configured. Skipping email send.');
      return { success: false, reason: 'Email service not configured' };
    }

    try {
      const mailOptions = {
        from: process.env.SMTP_FROM || 'noreply@dutaksim.app',
        to: recipientEmail,
        subject: `${inviterName} invited you to join "${sessionName}" on DuTaksim`,
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
              body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
              .header h1 { color: white; margin: 0; font-size: 28px; }
              .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
              .code-box { background: white; padding: 20px; margin: 20px 0; border-radius: 8px; text-align: center; border: 2px dashed #667eea; }
              .code { font-size: 32px; font-weight: bold; color: #667eea; letter-spacing: 4px; font-family: 'Courier New', monospace; }
              .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 6px; margin: 20px 0; }
              .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🍽️ DuTaksim</h1>
              </div>
              <div class="content">
                <h2>You've been invited!</h2>
                <p><strong>${inviterName}</strong> has invited you to join a collaborative bill splitting session: <strong>"${sessionName}"</strong></p>

                <p>To join the session, use this code in the DuTaksim app:</p>

                <div class="code-box">
                  <div class="code">${sessionCode}</div>
                </div>

                <p>Or scan the QR code from the app to join automatically.</p>

                <p><strong>What is DuTaksim?</strong><br>
                DuTaksim (meaning "divide in half" in Tajik) is a smart bill-splitting app that makes group dining hassle-free. No more awkward calculations!</p>

                <p style="margin-top: 30px; color: #666; font-size: 14px;">
                  This invitation was sent by ${inviterName}. If you didn't expect this invitation, you can safely ignore this email.
                </p>
              </div>
              <div class="footer">
                <p>© 2025 DuTaksim - Bank Eskhata Competition Entry</p>
                <p>Made with ❤️ for easier bill splitting</p>
              </div>
            </div>
          </body>
          </html>
        `,
        text: `
${inviterName} invited you to join "${sessionName}" on DuTaksim!

Session Code: ${sessionCode}

To join, open the DuTaksim app and enter the code above, or scan the QR code.

What is DuTaksim?
DuTaksim (meaning "divide in half" in Tajik) is a smart bill-splitting app that makes group dining hassle-free.

This invitation was sent by ${inviterName}.
        `.trim(),
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Invitation email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('Error sending invitation email:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send debt reminder email
   */
  async sendDebtReminder(recipientEmail, recipientName, creditorName, amount, billTitle) {
    if (!this.isConfigured()) {
      console.warn('Email service not configured. Skipping email send.');
      return { success: false, reason: 'Email service not configured' };
    }

    try {
      const mailOptions = {
        from: process.env.SMTP_FROM || 'noreply@dutaksim.app',
        to: recipientEmail,
        subject: `Reminder: You owe ${amount} somoni to ${creditorName}`,
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; color: white; }
              .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
              .amount { font-size: 36px; font-weight: bold; color: #667eea; text-align: center; margin: 20px 0; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>💰 Payment Reminder</h1>
              </div>
              <div class="content">
                <p>Hi ${recipientName},</p>
                <p>This is a friendly reminder about your pending payment from <strong>"${billTitle}"</strong>.</p>

                <div class="amount">${amount} somoni</div>

                <p>You owe this amount to <strong>${creditorName}</strong>.</p>

                <p>Please settle this payment at your earliest convenience. Thank you!</p>

                <p style="margin-top: 30px; color: #666; font-size: 14px;">
                  This is an automated reminder from DuTaksim.
                </p>
              </div>
            </div>
          </body>
          </html>
        `,
        text: `
Hi ${recipientName},

This is a friendly reminder about your pending payment from "${billTitle}".

Amount: ${amount} somoni
To: ${creditorName}

Please settle this payment at your earliest convenience. Thank you!

This is an automated reminder from DuTaksim.
        `.trim(),
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Debt reminder email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('Error sending debt reminder email:', error);
      return { success: false, error: error.message };
    }
  }

  /**
   * Send welcome email
   */
  async sendWelcomeEmail(recipientEmail, userName) {
    if (!this.isConfigured()) {
      console.warn('Email service not configured. Skipping email send.');
      return { success: false, reason: 'Email service not configured' };
    }

    try {
      const mailOptions = {
        from: process.env.SMTP_FROM || 'noreply@dutaksim.app',
        to: recipientEmail,
        subject: 'Welcome to DuTaksim! 🎉',
        html: `
          <!DOCTYPE html>
          <html>
          <head>
            <meta charset="UTF-8">
            <style>
              body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
              .container { max-width: 600px; margin: 0 auto; padding: 20px; }
              .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; text-align: center; border-radius: 10px 10px 0 0; color: white; }
              .content { background: #f9fafb; padding: 30px; border-radius: 0 0 10px 10px; }
              .feature { margin: 15px 0; padding-left: 25px; position: relative; }
              .feature:before { content: '✓'; position: absolute; left: 0; color: #667eea; font-weight: bold; }
            </style>
          </head>
          <body>
            <div class="container">
              <div class="header">
                <h1>🍽️ Welcome to DuTaksim!</h1>
              </div>
              <div class="content">
                <p>Hi ${userName},</p>
                <p>Welcome to DuTaksim - your smart companion for hassle-free bill splitting!</p>

                <h3>What can you do with DuTaksim?</h3>
                <div class="feature">Split bills quickly with friends and family</div>
                <div class="feature">Scan receipts with OCR technology</div>
                <div class="feature">Create collaborative sessions for real-time bill sharing</div>
                <div class="feature">Track who owes what with smart debt calculation</div>
                <div class="feature">Find nearby active sessions with GPS</div>

                <p style="margin-top: 30px;">Ready to make bill splitting easier? Start by creating your first bill or joining a session!</p>

                <p style="margin-top: 20px; color: #666; font-size: 14px;">
                  DuTaksim means "divide in half" in Tajik - because sharing should be simple.
                </p>
              </div>
            </div>
          </body>
          </html>
        `,
        text: `
Hi ${userName},

Welcome to DuTaksim - your smart companion for hassle-free bill splitting!

What can you do with DuTaksim?
✓ Split bills quickly with friends and family
✓ Scan receipts with OCR technology
✓ Create collaborative sessions for real-time bill sharing
✓ Track who owes what with smart debt calculation
✓ Find nearby active sessions with GPS

Ready to make bill splitting easier? Start by creating your first bill or joining a session!

DuTaksim means "divide in half" in Tajik - because sharing should be simple.
        `.trim(),
      };

      const info = await this.transporter.sendMail(mailOptions);
      console.log('Welcome email sent:', info.messageId);
      return { success: true, messageId: info.messageId };
    } catch (error) {
      console.error('Error sending welcome email:', error);
      return { success: false, error: error.message };
    }
  }
}

// Export singleton instance
module.exports = new EmailService();
