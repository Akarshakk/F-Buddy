import streamlit as st
import pytesseract
import cv2
import re
import numpy as np
from PIL import Image
from pathlib import Path

# -------------------------------------------------
# SET TESSERACT PATH (IMPORTANT)
# -------------------------------------------------
TESSERACT_PATH = r"C:\Program Files\Tesseract-OCR\tesseract.exe"

if Path(TESSERACT_PATH).exists():
    pytesseract.pytesseract.tesseract_cmd = TESSERACT_PATH
else:
    st.error("❌ Tesseract not found. Please install it correctly.")
    st.stop()

# -------------------------------------------------
# OCR FUNCTION
# -------------------------------------------------
def extract_text(image):
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(gray, (5, 5), 0)
    thresh = cv2.threshold(blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)[1]
    return pytesseract.image_to_string(thresh)


# -------------------------------------------------
# DATA EXTRACTION
# -------------------------------------------------
def extract_amount(text):
    text = text.lower()

    # Priority 1: TOTAL
    total_match = re.search(r'total[:\s]*([\d,.]+)', text)
    if total_match:
        return total_match.group(1)

    # Priority 2: Subtotal
    subtotal_match = re.search(r'subtotal[:\s]*([\d,.]+)', text)
    if subtotal_match:
        return subtotal_match.group(1)

    # Fallback: any amount
    amounts = re.findall(r'\d+\.\d{2}', text)
    return amounts[-1] if amounts else "Not found"



def extract_date(text):
    match = re.findall(r'\d{2}/\d{2}/\d{4}', text)
    return match[0] if match else "Not found"


# -------------------------------------------------
# CATEGORY
# -------------------------------------------------
def categorize(text):
    text = text.lower()
    if "zomato" in text or "swiggy" in text:
        return "Food"
    elif "uber" in text or "ola" in text:
        return "Transport"
    elif "amazon" in text or "flipkart" in text:
        return "Shopping"
    return "Other"


# -------------------------------------------------
# FRAUD CHECK
# -------------------------------------------------
def fraud_check(amount):
    try:
        amt = float(amount.replace("₹", "").replace("Rs.", ""))
        return "⚠️ Suspicious Transaction" if amt > 3000 else "✅ Normal Transaction"
    except:
        return "Unknown"


# -------------------------------------------------
# STREAMLIT UI
# -------------------------------------------------
st.title("🧾 Smart Bill OCR & Fraud Detector")

uploaded = st.file_uploader("Upload Bill Image", type=["jpg", "jpeg", "png"])

if uploaded:
    image = Image.open(uploaded)
    st.image(image, caption="Uploaded Bill", use_column_width=True)

    img_cv = cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)

    try:
        text = extract_text(img_cv)
    except Exception as e:
        st.error(f"OCR Failed: {e}")
        st.stop()

    amount = extract_amount(text)
    date = extract_date(text)
    category = categorize(text)
    fraud = fraud_check(amount)

    st.subheader("📄 Extracted Info")
    st.write("**Date:**", date)
    st.write("**Amount:**", amount)
    st.write("**Category:**", category)
    st.write("**Fraud Status:**", fraud)

    with st.expander("🔍 Raw OCR Text"):
        st.text(text)
