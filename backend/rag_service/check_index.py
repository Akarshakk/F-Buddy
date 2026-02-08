import os
from dotenv import load_dotenv
from pinecone import Pinecone

load_dotenv(override=True)
api_key = os.getenv("PINECONE_API_KEY")
index_name = os.getenv("PINECONE_INDEX_NAME", "rag1")

pc = Pinecone(api_key=api_key)
index = pc.Index(index_name)

print(f"Checking for 'context.pdf' in {index_name}...")

# Query specifically for source: context.pdf
results = index.query(
    vector=[0.1]*384, # Small non-zero vector to avoid potential issues with all-zeros
    filter={"source": {"$eq": "context.pdf"}},
    top_k=5,
    include_metadata=True
)

if results.get('matches'):
    print(f"✅ Found {len(results['matches'])} chunks from 'context.pdf'")
    for m in results['matches']:
        print(f"  - Chunk ID: {m['id']}, Preview: {m['metadata'].get('text', '')[:50]}...")
else:
    print("❌ 'context.pdf' is NOT in the index.")

stats = index.describe_index_stats()
print(f"Total Vectors in Index: {stats.get('total_vector_count', 0)}")
