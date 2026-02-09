"""
RAG (Retrieval Augmented Generation) Service for F-Buddy
Uses Pinecone for vector storage and Gemini for answer generation
Processes DOCX files uploaded by admin for financial advisory
"""

import os
import uuid
import re
import json
import sys
import io

# Force UTF-8 encoding for stdout/stderr to handle emojis on Windows
if sys.stdout.encoding != 'utf-8':
    sys.stdout.reconfigure(encoding='utf-8')
if sys.stderr.encoding != 'utf-8':
    sys.stderr.reconfigure(encoding='utf-8')

from datetime import datetime
from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
from pinecone import Pinecone, ServerlessSpec
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.document_loaders import Docx2txtLoader, PyPDFLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
import google.generativeai as genai
from werkzeug.utils import secure_filename

# Aggressively clear system-level Gemini/Google keys that might be stale
import os
for k in ['GEMINI_API_KEY', 'GOOGLE_API_KEY']:
    if k in os.environ:
        del os.environ[k]

# Load environment variables from .env
load_dotenv(override=True)

# Configuration
PINECONE_API_KEY = os.getenv("PINECONE_API_KEY")
PINECONE_INDEX_NAME = os.getenv("PINECONE_INDEX_NAME", "rag1")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
ALLOWED_EXTENSIONS = {'docx', 'doc', 'pdf'}
TOP_K = 7

# Create upload folder if not exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Initialize Flask app
app = Flask(__name__)
CORS(app, origins='*')
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB max file size

# Global clients (initialized on first request)
pc_client = None
index = None
embeddings = None
gemini_model = None

def sanitize_text(text: str) -> str:
    """Sanitize text to remove problematic characters"""
    if not text:
        return ""
    # Remove non-ASCII characters
    text = text.encode('ascii', 'ignore').decode('ascii')
    # Remove control characters except newlines
    text = re.sub(r'[\x00-\x08\x0b\x0c\x0e-\x1f\x7f-\x9f]', '', text)
    return text.strip()

def clean_response(text: str) -> str:
    """Clean up Gemini response to remove markdown and unwanted phrases"""
    if not text:
        return ""
    
    # Remove markdown symbols
    text = re.sub(r'\*\*([^*]+)\*\*', r'\1', text)  # Bold
    text = re.sub(r'\*([^*]+)\*', r'\1', text)      # Italic
    text = re.sub(r'#{1,6}\s*', '', text)           # Headers
    text = re.sub(r'`([^`]+)`', r'\1', text)        # Inline code
    text = re.sub(r'^\s*[-*+]\s+', '', text, flags=re.MULTILINE)  # Bullet points
    text = re.sub(r'^\s*\d+\.\s+', '', text, flags=re.MULTILINE)  # Numbered lists
    
    # Remove common unwanted phrases
    unwanted_starts = [
        r'^Based on (the|my|this|your).*?,\s*',
        r'^According to.*?,\s*',
        r'^From (the|my|this).*?,\s*',
        r'^The (context|document|information).*?,\s*',
        r'^In (conclusion|summary|short),?\s*',
        r'^To (summarize|conclude|sum up),?\s*',
        r'^Overall,?\s*',
        r'^Generally (speaking)?,?\s*',
    ]
    for pattern in unwanted_starts:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
    
    # Remove trailing phrases
    unwanted_ends = [
        r'\s*I hope this helps!?\s*$',
        r'\s*Let me know if.*$',
        r'\s*Feel free to.*$',
        r'\s*Is there anything else.*$',
    ]
    for pattern in unwanted_ends:
        text = re.sub(pattern, '', text, flags=re.IGNORECASE)
    
    # Clean up whitespace
    text = re.sub(r'\n{3,}', '\n\n', text)
    text = text.strip()
    
    return text

def init_clients():
    """Initialize Pinecone, Embeddings, and Gemini clients"""
    global pc_client, index, embeddings, gemini_model
    
    if pc_client is not None:
        return  # Already initialized
    
    try:
        print("🔧 Initializing RAG clients...")
        
        # Initialize Pinecone
        pc_client = Pinecone(api_key=PINECONE_API_KEY)
        
        # Check/Create index
        try:
            index = pc_client.Index(PINECONE_INDEX_NAME)
            print(f"✅ Connected to Pinecone index: {PINECONE_INDEX_NAME}")
        except Exception as e:
            print(f"⚠️ Index not found, creating: {PINECONE_INDEX_NAME}")
            pc_client.create_index(
                name=PINECONE_INDEX_NAME,
                dimension=384,
                metric="cosine",
                spec=ServerlessSpec(
                    cloud='aws',
                    region='us-east-1'
                )
            )
            import time
            time.sleep(3)
            index = pc_client.Index(PINECONE_INDEX_NAME)
            print(f"✅ Created Pinecone index: {PINECONE_INDEX_NAME}")
        
        # Initialize embeddings model
        embeddings = HuggingFaceEmbeddings(
            model_name="sentence-transformers/all-MiniLM-L6-v2",
            model_kwargs={"device": "cpu"},
            encode_kwargs={"normalize_embeddings": True}
        )
        print("✅ Loaded embedding model")
        
        # Initialize Gemini
        current_gemini_key = os.getenv("GEMINI_API_KEY")
        if not current_gemini_key:
            raise ValueError("GEMINI_API_KEY not found in environment")
            
        print(f"🔑 Initializing Gemini with Key Prefix: {current_gemini_key[:10]}...")
        genai.configure(api_key=current_gemini_key)
        # Re-initialize the global gemini_model to use a supported 2.x model
        gemini_model = genai.GenerativeModel("gemini-2.5-flash")
        print("✅ Initialized Gemini model (gemini-2.5-flash)")
        
    except Exception as e:
        print(f"❌ Error initializing clients: {str(e)}")
        raise

def allowed_file(filename):
    """Check if file extension is allowed"""
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'OK',
        'message': 'RAG Service is running',
        'timestamp': datetime.now().isoformat()
    })

@app.route('/upload-documents', methods=['POST'])
def upload_documents():
    """Upload and ingest DOCX documents into Pinecone"""
    try:
        # Initialize clients if not already done
        if pc_client is None:
            init_clients()
        
        # Check if files are present
        if 'files' not in request.files:
            return jsonify({'success': False, 'message': 'No files provided'}), 400
        
        files = request.files.getlist('files')
        if not files or files[0].filename == '':
            return jsonify({'success': False, 'message': 'No files selected'}), 400
        
        results = []
        total_chunks = 0
        
        for file in files:
            if file and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                filepath = os.path.join(UPLOAD_FOLDER, f"{uuid.uuid4()}_{filename}")
                file.save(filepath)
                
                try:
                    # Load document based on file type
                    print(f"📄 Loading document: {filename}")
                    if filename.lower().endswith('.pdf'):
                        loader = PyPDFLoader(filepath)
                    else:
                        loader = Docx2txtLoader(filepath)
                    docs = loader.load()
                    
                    # Split into chunks
                    print("✂️ Splitting into chunks...")
                    splitter = RecursiveCharacterTextSplitter(
                        chunk_size=500,
                        chunk_overlap=100
                    )
                    chunks = splitter.split_documents(docs)
                    
                    # Embed and upload to Pinecone
                    print(f"🚀 Uploading {len(chunks)} chunks to Pinecone...")
                    vectors_to_upsert = []
                    
                    for doc in chunks:
                        text = sanitize_text(doc.page_content)
                        if not text:
                            continue
                        
                        embedding = embeddings.embed_query(text)
                        point_id = str(uuid.uuid4())
                        
                        vectors_to_upsert.append({
                            "id": point_id,
                            "values": embedding,
                            "metadata": {
                                "text": text,
                                "source": filename,
                                "uploaded_at": datetime.now().isoformat()
                            }
                        })
                    
                    # Upsert in batches
                    batch_size = 100
                    for i in range(0, len(vectors_to_upsert), batch_size):
                        batch = vectors_to_upsert[i:i + batch_size]
                        index.upsert(vectors=batch)
                    
                    total_chunks += len(vectors_to_upsert)
                    results.append({
                        'filename': filename,
                        'chunks': len(vectors_to_upsert),
                        'success': True
                    })
                    
                    print(f"✅ Successfully ingested {filename}")
                    
                except Exception as e:
                    results.append({
                        'filename': filename,
                        'error': str(e),
                        'success': False
                    })
                    print(f"❌ Error processing {filename}: {str(e)}")
                
                finally:
                    # Cleanup file
                    if os.path.exists(filepath):
                        os.unlink(filepath)
            else:
                results.append({
                    'filename': file.filename,
                    'error': 'Invalid file type',
                    'success': False
                })
        
        return jsonify({
            'success': True,
            'message': f'Processed {len(files)} files, ingested {total_chunks} chunks',
            'results': results,
            'total_chunks': total_chunks
        })
        
    except Exception as e:
        print(f"❌ Upload error: {str(e)}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/chat', methods=['POST'])
def chat():
    """Handle chat queries using RAG pipeline"""
    try:
        # Initialize clients if not already done
        if pc_client is None:
            init_clients()
        
        data = request.get_json()
        if not data or 'query' not in data:
            return jsonify({'success': False, 'message': 'Query is required'}), 400
        
        query = data['query']
        
        # Ensure clients are initialized (this will now use the override/clearing logic)
        if pc_client is None:
            init_clients()
        
        # Retrieve relevant chunks from Pinecone with Hybrid User Filtering
        print(f"🔍 Searching for: {query}")
        query_vec = embeddings.embed_query(query)
        
        user_id = data.get('user_id')
        realtime_context = data.get('context') # e.g. {"balance": 1000, "portfolio": 5000}
        
        # Construct Filter: (user_id == current_user) OR (user_id is generic/public)
        # Note: Pinecone metadata filtering is precise.
        # Strategy: We search generally. Then we filter in Python if strict user isolation is needed.
        # But for RAG, getting "general" investing advice (no user_id) + "my" data (user_id=X) is ideal.
        # If we filter by user_id=X only, we lose general knowledge.
        
        filter_dict = {}
        if user_id:
             # Ideally we want: user_id == X OR user_id exists: false
             # Pinecone 'filter' doesn't support complex OR easily in free tier.
             # So we will fetch more results (TOP_K * 2) and filter in memory.
             top_k_fetch = TOP_K * 3
        else:
             top_k_fetch = TOP_K

        results = index.query(
            vector=query_vec,
            top_k=top_k_fetch,
            include_metadata=True
        )
        
        # Extract context
        context_chunks = []
        sources = []
        
        for match in results.get("matches", []):
            if match["score"] < 0.25:
                continue
                
            meta = match.get("metadata", {})
            doc_user_id = meta.get("user_id")
            
            # Hybrid Filtering Logic
            # 1. If doc has NO user_id -> It's global knowledge -> KEEP
            # 2. If doc has user_id == current_user -> It's my data -> KEEP
            # 3. If doc has user_id != current_user -> It's someone else's -> DISCARD
            
            is_global = doc_user_id is None
            is_mine = str(doc_user_id) == str(user_id) if user_id and doc_user_id else False
            
            if is_global or is_mine:
                context_chunks.append(meta.get("text", ""))
                source = meta.get("source", "Unknown")
                if source not in sources:
                    sources.append(source)
        
        # Limit context size to avoid token limits
        context_chunks = context_chunks[:7] # Top 7 relevant chunks
        
        # Determine if we have good context from documents
        has_document_context = len(context_chunks) > 0
        
        # Construct Prompt
        system_instruction = "You are F-Buddy AI, a friendly and helpful financial assistant."
        
        # Inject Real-Time Financial Context
        financial_context_str = ""
        if realtime_context:
            financial_context_str = "CURRENT FINANCIAL STATUS (Real-time):\n"
            for key, val in realtime_context.items():
                # Format key for readability ("total_balance" -> "Total Balance")
                nice_key = key.replace('_', ' ').title()
                financial_context_str += f"- {nice_key}: {val}\n"
            financial_context_str += "\nUse this real-time data to answer questions about affordability (e.g., 'Can I buy X?').\n"

        context_block = ""
        if has_document_context:
            context_block = f"CONTEXT FROM DOCUMENTS/HISTORY:\n{chr(10).join(context_chunks)}\n"
            
            prompt = f"""
{system_instruction}

{financial_context_str}
{context_block}

USER QUESTION:
{query}

IMPORTANT RESPONSE RULES:
1. Give a DIRECT, CONCISE answer in 2-4 sentences max.
2. If the user asks if they can buy something, COMPARE the cost to their 'Wallet Balance' or 'Net Worth' derived from the Financial Status above.
   - Example: "Yes, you have ₹50,000 balance." or "No, you only have ₹10,000."
3. NO asterisks (*), hashes (#), or markdown symbols.
4. NO phrases like "Based on the context" or "According to the documents".
5. NO "In conclusion" or summary statements.
6. Use simple, conversational language.
7. Only add a brief disclaimer for major financial decisions.

Answer directly:
"""
        else:
            # Fallback: No relevant documents found, use LLM's general finance knowledge
            # Inject Real-Time Financial Context even in fallback
            financial_context_str = ""
            if realtime_context:
                financial_context_str = "CURRENT FINANCIAL STATUS (Real-time):\n"
                for key, val in realtime_context.items():
                    nice_key = key.replace('_', ' ').title()
                    financial_context_str += f"- {nice_key}: {val}\n"
                financial_context_str += "\nUse this real-time data to answer questions about affordability.\n"

            prompt = f"""
You are F-Buddy AI, a friendly financial assistant.

{financial_context_str}

USER QUESTION:
{query}

IMPORTANT RESPONSE RULES:
1. Give a DIRECT, CONCISE answer in 2-4 sentences max
2. Compare costs to 'Wallet Balance' if asked about affordability.
3. NO asterisks (*), hashes (#), or markdown symbols
4. NO phrases like "Based on my knowledge" or "Generally speaking"
5. NO "In conclusion" or summary statements
6. Use simple, conversational language
7. Only add a brief disclaimer for major financial decisions
8. If not about finance, politely say you only help with money topics

Answer directly:
"""

        print(f"🤖 Generating answer with Gemini (document context: {has_document_context})...")
        response = gemini_model.generate_content(prompt)
        answer = response.text
        
        # Clean up the response
        answer = clean_response(answer)
        
        print(f"✅ Generated answer ({len(answer)} chars)")
        
        return jsonify({
            'success': True,
            'answer': answer,
            'sources': sources if has_document_context else ['General Knowledge'],
            'context_used': len(context_chunks),
            'used_document_context': has_document_context
        })
        
    except Exception as e:
        print(f"❌ Chat error: {str(e)}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

@app.route('/stats', methods=['GET'])
def get_stats():
    """Get statistics about indexed documents"""
    try:
        if pc_client is None:
            init_clients()
        
        stats = index.describe_index_stats()
        
        return jsonify({
            'success': True,
            'total_vectors': stats.get('total_vector_count', 0),
            'dimension': stats.get('dimension', 384),
            'index_name': PINECONE_INDEX_NAME
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500


class GeminiOCR:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")

    def extract_bill_info(self, image_bytes):
        """
        Extracts bill info using Gemini (Multimodal) with prompts/rules 
        ported from the Personal Finance feature (billController.js).
        """
        if not self.api_key:
            return {"merchant": "Demo Merchant", "amount": "0.00", "date": datetime.now().strftime("%Y-%m-%d"), "status": "demo_no_key"}

        try:
            genai.configure(api_key=self.api_key)
            model = genai.GenerativeModel('gemini-2.5-flash')
            
            prompt = """
            Extract bill info from this image. Return ONLY JSON, nothing else.

            RULES:
            - merchant: Store/restaurant name (MAX 25 chars, just the name, no address). Look for the largest, boldest text at the top.
            - amount: Final total (number only, after taxes, look for "Bill Total", "Grand Total", "Total Rs"). Do NOT include currency symbols.
            - category: One of: restaurants, food, drinks, transport, fuel, clothes, education, health, hotel, fun, personal, pets, others.
            - date: YYYY-MM-DD format or null.

            CATEGORY HINTS:
            - restaurants: dine-in, menu items, FSSAI, Table No, kitchen, cafe, dhaba
            - food: Zomato, Swiggy, grocery, supermarket
            - drinks: bar, pub, wine, beer, alcohol
            - transport: uber, ola, taxi, fuel, flight, train
            - fuel: petrol, diesel, cng, gas station
            - clothes: apparel, fashion, zudio, trends
            - education: school, college, books, stationery
            - health: hospital, pharmacy, medicine, gym
            - hotel: oyo, stay, room, resort
            - fun: movie, cinema, game, netflix
            - personal: salon, spa, grooming
            - pets: vet, pet food
            - others: shopping, electronics, recharge, bill

            RESPOND WITH ONLY JSON:
            {"merchant":"Name","amount":123.45,"category":"restaurants","date":"2025-12-31"}
            """

            content = [prompt, {"mime_type": "image/jpeg", "data": image_bytes}]
            
            response = model.generate_content(content)
            
            # Clean response text
            text = response.text.strip().replace('```json', '').replace('```', '')
            parsed = json.loads(text)
            
            return {
                "merchant": parsed.get("merchant", "Not Avl"),
                "amount": parsed.get("amount", "0.00"),
                "date": parsed.get("date", "Not Mentioned"),
                "category": parsed.get("category", "others"),
                "status": "success",
                "raw_data": parsed
            }

        except Exception as e:
            print(f"❌ Gemini extraction error: {e}")
            # Fallback for error
            return {"error": str(e), "status": "error"}

@app.route('/scan-bill', methods=['POST'])
def scan_bill():
    """Scan bill image using Gemini OCR (Personal Finance Logic)"""
    try:
        if 'file' not in request.files:
            return jsonify({'success': False, 'message': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'success': False, 'message': 'No file selected'}), 400

        # Read file bytes directly
        image_bytes = file.read()
        
        # Initialize OCR
        ocr = GeminiOCR()
        result = ocr.extract_bill_info(image_bytes)
        
        if result.get("status") == "error":
            return jsonify({
                'success': False, 
                'message': result.get("error", "Unknown error")
            }), 500
            
        return jsonify({
            'success': True,
            'data': result
        })

    except Exception as e:
        print(f"❌ Scan error: {str(e)}")
        return jsonify({
            'success': False,
            'message': str(e)
        }), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Starting F-Buddy RAG Service")
    print("=" * 60)
    
    # Initialize clients on startup
    try:
        init_clients()
        
        # Check if context.pdf in uploads needs to be ingested
        context_path = os.path.join(UPLOAD_FOLDER, 'context.pdf')
        if os.path.exists(context_path):
            print("\n🧐 Found context.pdf in uploads. Checking index...")
            stats = index.describe_index_stats()
            # If index is empty or very small, let's ingest the context.pdf
            if stats.get('total_vector_count', 0) < 50:
                print("🚀 Auto-ingesting context.pdf...")
                with open(context_path, 'rb') as f:
                    from flask import Request
                    # Simulate a file upload for the existing function
                    # Or just call the logic directly. Let's keep it simple.
                    pass 
                # Actually, let's just use the logic directly
                try:
                    loader = PyPDFLoader(context_path)
                    docs = loader.load()
                    splitter = RecursiveCharacterTextSplitter(chunk_size=500, chunk_overlap=100)
                    chunks = splitter.split_documents(docs)
                    vectors_to_upsert = []
                    for doc in chunks:
                        text = sanitize_text(doc.page_content)
                        if not text: continue
                        embedding = embeddings.embed_query(text)
                        vectors_to_upsert.append({
                            "id": str(uuid.uuid4()),
                            "values": embedding,
                            "metadata": {"text": text, "source": "context.pdf", "uploaded_at": datetime.now().isoformat()}
                        })
                    batch_size = 100
                    for i in range(0, len(vectors_to_upsert), batch_size):
                        index.upsert(vectors=vectors_to_upsert[i:i + batch_size])
                    print(f"✅ Auto-ingested {len(vectors_to_upsert)} chunks from context.pdf")
                except Exception as e:
                    print(f"❌ Auto-ingestion failed: {e}")
        
        print("\n✅ RAG Service ready!")
    except Exception as e:
        print(f"\n❌ Failed to initialize: {e}")
        print("Service will attempt to initialize on first request")
    
    print("\n📡 Starting Flask server on port 5002...")
    print("=" * 60)
    
    app.run(host='0.0.0.0', port=5002, debug=False)
