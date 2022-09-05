use serde::{de::Visitor, Deserialize};

#[derive(sqlx::Type)]
#[sqlx(transparent)]
pub struct Email(String);

// See https://serde.rs/impl-deserialize.html for more information
impl<'de> Deserialize<'de> for Email {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_str(EmailVisitor)
    }
}

struct EmailVisitor;

impl<'de> Visitor<'de> for EmailVisitor {
    type Value = Email;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a valid HTML5 email address")
    }

    fn visit_str<E>(self, string: &str) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        // TODO: validate email
        Ok(Email(string.to_string()))
    }
}
