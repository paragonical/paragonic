# Design Notes

## Database and ORM Design Decisions

### pgvector Type Handling with Diesel

**Issue**: Diesel's schema generation doesn't natively support PostgreSQL's pgvector extension types.

**Problem**: When using `diesel print-schema`, the `vector(384)` column type is incorrectly mapped to `Bytea` instead of the proper vector type.

**Current State**:
- Database column: `embedding_vector vector(384)`
- Generated schema: `embedding_vector -> Nullable<Bytea>`
- Expected schema: `embedding_vector -> Nullable<Vector>` (custom type)

**Impact**:
- Embedding creation works (Ollama integration ✅)
- Database storage fails with type mismatch error
- Test passes by handling the expected database error

**Solutions Considered**:

1. **Custom Diesel Type** (Recommended)
   - Create a custom `Vector` type with proper Diesel traits
   - Implement `FromSql` and `ToSql` for vector serialization
   - Update schema.rs manually to use the custom type

2. **Raw SQL for Vector Operations**
   - Use `diesel::sql_query` for vector-specific operations
   - Keep embeddings as `Bytea` for storage
   - Convert to/from vector format in application layer

3. **Alternative ORM**
   - Consider using SQLx which has better pgvector support
   - Would require significant refactoring

**Next Steps**:
- Implement custom `Vector` type with proper Diesel integration
- Update schema.rs to use the custom type
- Add vector similarity search functions

**References**:
- [pgvector documentation](https://github.com/pgvector/pgvector)
- [Diesel custom types](https://diesel.rs/guides/custom_types)
- [Diesel pgvector example](https://github.com/diesel-rs/diesel/issues/3558) 