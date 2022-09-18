use lazy_static::lazy_static;
use regex::Regex;
use serde::{de::Visitor, Deserialize};
#[derive(sqlx::Type)]
#[sqlx(transparent)]
pub struct Username(String);
pub struct Email(String);
pub struct PhoneNumber(String);
pub struct Bio(String);

// See https://serde.rs/impl-deserialize.html for more information
impl<'de> Deserialize<'de> for Username {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_str(UsernameVisitor)
    }
}

impl<'de> Deserialize<'de> for Email {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_str(EmailVisitor)
    }
}

impl<'de> Deserialize<'de> for PhoneNumber {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        deserializer.deserialize_str(PhoneNumberVisitor)
    }
}

struct UsernameVisitor;
struct EmailVisitor;
struct PhoneNumberVisitor;
struct BioVisitor;

impl<'de> Visitor<'de> for UsernameVisitor {
    type Value = Username;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a valid username 4-16 characters and consisting of lowercase letters, numbers, underscores, and periods")
    }

    fn visit_string<E>(self, v: String) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        lazy_static! {
            static ref RE: Regex = Regex::new(r"^[a-z0-9._]{4,16}").unwrap();
        }
        RE.captures(&v)
            .and_then(|cap| cap.name("login").map(|login| login.as_str()));

        Ok(Username(v))
    }
}

impl<'de> Visitor<'de> for EmailVisitor {
    type Value = Email;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a valid HTML5 email address")
    }

    fn visit_string<E>(self, v: String) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        lazy_static! {
            static ref RE: Regex = Regex::new(
                r"(?x)
            ^(?P<login>[^@\s]+)@
            ([[:word:]]+\.)*
            [[:word:]]+$
            "
            )
            .unwrap();
        }
        RE.captures(&v)
            .and_then(|cap| cap.name("login").map(|login| login.as_str()));

        Ok(Email(v))
    }
}

impl<'de> Visitor<'de> for PhoneNumberVisitor {
    type Value = PhoneNumber;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a valid 10 digit phone number with no country code")
    }

    fn visit_string<E>(self, v: String) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        lazy_static! {
            static ref RE: Regex = Regex::new(r"^\d{3}(-)?\d{3}(-)?\d{4}$").unwrap();
        }
        RE.captures(&v)
            .and_then(|cap| cap.name("login").map(|login| login.as_str()));

        Ok(PhoneNumber(v))
    }
}

impl<'de> Visitor<'de> for BioVisitor {
    type Value = Bio;

    fn expecting(&self, formatter: &mut std::fmt::Formatter) -> std::fmt::Result {
        formatter.write_str("a bio of anything")
    }

    fn visit_string<E>(self, v: String) -> Result<Self::Value, E>
    where
        E: serde::de::Error,
    {
        lazy_static! {
            static ref RE: Regex = Regex::new(r"^.{0,200}$").unwrap();
        }
        RE.captures(&v)
            .and_then(|cap| cap.name("login").map(|login| login.as_str()));

        Ok(Bio(v))
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn test_email() {
        assert_eq!(1, 1)
    }
}
