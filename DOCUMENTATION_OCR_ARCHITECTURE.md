# OCR Architecture: Visual LLM Approach

The application uses a modern **Visual Large Language Model (Visual LLM)** approach for Optical Character Recognition (OCR), specifically leveraging **Google Gemini 2.5 Flash**. This differs significantly from traditional OCR pipelines.

## 1. Traditional vs. Modern Approach

### Traditional OCR (Old Way)
- **Step 1 (Image Processing)**: Convert image to black & white, de-skew, detecting text blocks.
- **Step 2 (Character Recognition)**: Use Tesseract/AWS Textract/Google Vision to extract raw text (e.g., "T0tal Rs 25O.00").
- **Step 3 (Natural Language Processing)**: Use Regex or basic NLP to find patterns in the messy text (e.g., find "Total" near a number).
- **Pros**: Cheap, fast for clean documents.
- **Cons**: Brittle. Confuses "0" and "O", "1" and "l". Fails on complex layouts, handwritten notes, or poor lighting.

### Visual LLM (Our Approach)
- **Step 1 (Direct Analysis)**: The entire image (pixels) is sent directly to the AI model (Gemini 2.5 Flash).
- **Step 2 (Cognitive Extraction)**: The model "looks" at the image like a human. It understands layout, font hierarchy (bold = important), and context.
- **Step 3 (Structured Output)**: The model extracts specific fields (Merchant, Amount, Date, Category) and returns clean JSON directly.
- **Pros**: Extremely robust. Can read handwriting, receipts in odd orientations, and infers context (e.g., knows "Starbucks" is "Food/Drink" without explicit rules).
- **Cons**: Slightly higher latency/cost (though Flash models are very fast/cheap).

## 2. Technical Implementation Flow

The flow is implemented in `mobile/lib/services/bill_scan_service.dart` and `backend/rag_service/rag_server.py`.

### A. Client Side (Mobile App)
1.  **Capture**: User takes a photo or selects an image.
2.  **Encryption**: Image is converted to `Uint8List` (bytes).
3.  **Transport**:
    - The app constructs a `MultipartRequest` (POST) to the Python RAG Service.
    - URL: `http://<host>:5002/scan-bill` (bypassing the Node.js backend for this operation).
    - Authorization: Bearer token is attached.

### B. Server Side (Python RAG Service)
1.  **Reception**: The `rag_server.py` receives the multipart file.
2.  **AI Processing (`GeminiOCR` Class)**:
    - Initialises `genai.GenerativeModel('gemini-2.5-flash')`.
    - Constructs a prompt:
        > "Extract bill info from this image. Return ONLY JSON... RULES: merchant (largest text), amount (final total), category, date..."
    - Calls `model.generate_content([prompt, image_bytes])`.
3.  **Parsing**:
    - The model returns a raw string containing a JSON block.
    - Examples: `{"merchant": "Uber", "amount": 450.00, ...}`.
    - The server cleans markdown via regex (`r'```json'`) and parses it into a Python dictionary.
4.  **Response**:
    - Returns standard JSON response: `{ success: true, data: { ... } }`.

## 3. Key Advantages in This Codebase
- **Zero Regex**: We removed complex regex rules for date formats (e.g., `dd/mm/yyyy` vs `mm-dd-yy`). The model handles it natively.
- **Smart Categorization**: The model categorizes expenses (e.g., "Shell Station" -> "Fuel") using its vast world knowledge, reducing the need for hardcoded keyword lists.
- **Resilience**: Even if the receipt is crumpled or low-light, the Visual LLM can often infer the correct values where Tesseract fails.
