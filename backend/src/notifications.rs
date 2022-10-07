use aws_config::SdkConfig;
use aws_sdk_sesv2::{
    model::{Body, Content, Destination, EmailContent, Message},
    output::SendEmailOutput,
};

/// An email notification.
pub struct Email {
    from_email_address: String,
    dest_email_address: String,
    subject: String,
    // TODO: is this HTML or text?
    body: String,
}

impl Email {
    /// Create a new email notification to be sent to a given email address.
    pub fn new(recipient_email_address: impl Into<String>) -> Self {
        Self {
            from_email_address: String::from("no-reply@mail.myace.ai"),
            dest_email_address: recipient_email_address.into(),
            subject: String::new(),
            body: String::new(),
        }
    }
    pub fn subject(self, subject: impl Into<String>) -> Self {
        Self {
            subject: subject.into(),
            ..self
        }
    }
    pub fn body(self, body: impl Into<String>) -> Self {
        Self {
            body: body.into(),
            ..self
        }
    }
    pub fn from_email_address(self, email: impl Into<String>) -> Self {
        Self {
            from_email_address: email.into(),
            ..self
        }
    }
    pub async fn send(self, aws_config: &SdkConfig) -> Result<SendEmailOutput, anyhow::Error> {
        // get user email
        let dest: Destination = Destination::builder()
            .to_addresses(self.dest_email_address)
            .build();

        // create email subject and body
        let subject_content = Content::builder()
            .data(self.subject)
            .charset("UTF-8")
            .build();
        let body_content = Content::builder().data(self.body).charset("UTF-8").build();
        let body = Body::builder().text(body_content).build();

        // build email content
        let msg: Message = Message::builder()
            .subject(subject_content)
            .body(body)
            .build();
        let content: EmailContent = EmailContent::builder().simple(msg).build();

        // send email
        let ses = aws_sdk_sesv2::Client::new(&aws_config);
        let response = ses
            .send_email()
            .from_email_address(self.from_email_address)
            .destination(dest)
            .content(content)
            .send()
            .await?;
        Ok(response)
    }
}

#[cfg(test)]
mod tests {
    use dotenvy::dotenv;

    use super::Email;

    /// test sending an email with SES
    #[tokio::test]
    async fn email_sends() -> Result<(), anyhow::Error> {
        // Load development environment variables from .env file.
        dotenv().ok();

        // create AWS config
        let aws_config = aws_config::from_env().region("us-east-2").load().await;

        let fut = Email::new("adlerweber8430@gmail.com")
            .from_email_address("rust-test@mail.myace.ai")
            .subject("Rust test")
            .body("This is the body for my test")
            .send(&aws_config);

        let res = fut.await?;
        println!(
            "Sent a test email with message ID: {}",
            res.message_id().unwrap_or_default()
        );
        Ok(())
    }
}
