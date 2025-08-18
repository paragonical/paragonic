//! Custom Vector type for pgvector integration with Diesel
//!
//! This module provides a custom Vector type that properly handles PostgreSQL's
//! pgvector extension types with Diesel ORM integration.

use crate::schema::sql_types::Vector as PgVector;
use diesel::deserialize::{self, FromSql};
use diesel::pg::Pg;
use diesel::serialize::{self, IsNull, Output, ToSql};
use diesel::sql_types::Binary;
use serde::{Deserialize, Serialize};
use std::io::Write;

/// Custom Vector type for pgvector integration
///
/// This type represents a vector of f32 values that can be stored in PostgreSQL
/// using the pgvector extension. It implements the necessary Diesel traits
/// for serialization and deserialization.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Vector {
    pub values: Vec<f32>,
}

impl Vector {
    /// Create a new Vector from a slice of f32 values
    pub fn new(values: Vec<f32>) -> Self {
        Self { values }
    }

    /// Create a new Vector from a slice of f32 values
    pub fn from_slice(values: &[f32]) -> Self {
        Self {
            values: values.to_vec(),
        }
    }

    /// Get the vector values as a slice
    pub fn as_slice(&self) -> &[f32] {
        &self.values
    }

    /// Get the vector values as a vector
    pub fn to_vec(&self) -> Vec<f32> {
        self.values.clone()
    }

    /// Get the dimension of the vector
    pub fn dimension(&self) -> usize {
        self.values.len()
    }

    /// Convert to bytes for storage
    pub fn to_bytes(&self) -> Vec<u8> {
        let mut bytes = Vec::with_capacity(self.values.len() * 4);
        for &value in &self.values {
            bytes.extend_from_slice(&value.to_le_bytes());
        }
        bytes
    }

    /// Create from bytes
    pub fn from_bytes(bytes: &[u8]) -> Result<Self, Box<dyn std::error::Error + Send + Sync>> {
        if bytes.len() % 4 != 0 {
            return Err("Invalid byte length for f32 vector".into());
        }

        let mut values = Vec::with_capacity(bytes.len() / 4);
        for chunk in bytes.chunks(4) {
            let value = f32::from_le_bytes([chunk[0], chunk[1], chunk[2], chunk[3]]);
            values.push(value);
        }

        Ok(Self { values })
    }
}

impl From<Vec<f32>> for Vector {
    fn from(values: Vec<f32>) -> Self {
        Self { values }
    }
}

impl From<&[f32]> for Vector {
    fn from(values: &[f32]) -> Self {
        Self::from_slice(values)
    }
}

impl From<Vector> for Vec<f32> {
    fn from(val: Vector) -> Self {
        val.values
    }
}

// Diesel integration for Vector type
impl ToSql<PgVector, Pg> for Vector {
    fn to_sql<'b>(&'b self, out: &mut Output<'b, '_, Pg>) -> serialize::Result {
        let bytes = self.to_bytes();
        out.write_all(&bytes)?;
        Ok(IsNull::No)
    }
}

impl FromSql<PgVector, Pg> for Vector {
    fn from_sql(bytes: diesel::pg::PgValue) -> deserialize::Result<Self> {
        let bytes = <Vec<u8> as FromSql<Binary, Pg>>::from_sql(bytes)?;
        Vector::from_bytes(&bytes)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_vector_creation() {
        let values = vec![1.0, 2.0, 3.0];
        let vector = Vector::new(values.clone());
        assert_eq!(vector.values, values);
        assert_eq!(vector.dimension(), 3);
    }

    #[test]
    fn test_vector_from_slice() {
        let values = [1.0, 2.0, 3.0];
        let vector = Vector::from_slice(&values);
        assert_eq!(vector.values, values);
    }

    #[test]
    fn test_vector_conversion() {
        let values = vec![1.0, 2.0, 3.0];
        let vector = Vector::from(values.clone());
        let converted: Vec<f32> = vector.into();
        assert_eq!(converted, values);
    }

    #[test]
    fn test_vector_bytes_conversion() {
        let values = vec![1.0, 2.0, 3.0];
        let vector = Vector::new(values.clone());

        let bytes = vector.to_bytes();
        let reconstructed = Vector::from_bytes(&bytes).unwrap();

        assert_eq!(reconstructed.values, values);
    }

    #[test]
    fn test_vector_from_invalid_bytes() {
        let invalid_bytes = vec![1, 2, 3]; // Not divisible by 4
        let result = Vector::from_bytes(&invalid_bytes);
        assert!(result.is_err());
    }

    #[test]
    fn test_vector_equality() {
        let vector1 = Vector::new(vec![1.0, 2.0, 3.0]);
        let vector2 = Vector::new(vec![1.0, 2.0, 3.0]);
        let vector3 = Vector::new(vec![1.0, 2.0, 4.0]);

        assert_eq!(vector1, vector2);
        assert_ne!(vector1, vector3);
    }
}
