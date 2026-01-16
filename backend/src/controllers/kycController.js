const KYC = require('../models/KYC');
const User = require('../models/User');
const ocrService = require('../services/ocrService');
const faceService = require('../services/faceService');
const mfaService = require('../services/mfaService');
const fs = require('fs');
const path = require('path');

// @desc    Get current KYC status
// @route   GET /api/kyc/status
// @access  Private
exports.getKycStatus = async (req, res) => {
    try {
        const kyc = await KYC.findByUser(req.user.id);

        // If no KYC record exists
        if (!kyc) {
            return res.status(200).json({
                success: true,
                data: {
                    status: req.user.kycStatus,
                    step: req.user.kycStep,
                    details: null
                }
            });
        }

        res.status(200).json({
            success: true,
            data: {
                status: req.user.kycStatus,
                step: req.user.kycStep,
                details: {
                    documentType: kyc.documentType,
                    documentUploaded: !!kyc.documentImage,
                    selfieUploaded: !!kyc.selfieImage,
                    verificationHistory: kyc.verificationHistory
                }
            }
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error fetching KYC status',
            error: error.message
        });
    }
};

// @desc    Upload ID Document
// @route   POST /api/kyc/upload-document
// @access  Private
exports.uploadDocument = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Please upload a document image' });
        }

        const { documentType } = req.body;

        // Validate document type
        if (!['aadhaar', 'pan', 'passport', 'driving_license'].includes(documentType)) {
            fs.unlinkSync(req.file.path);
            return res.status(400).json({ success: false, message: 'Invalid document type' });
        }

        console.log(`[KYC] Processing document: ${req.file.path}`);

        // Perform OCR
        const ocrResult = await ocrService.extractText(req.file.path);
        const isValid = ocrService.validateDocument(documentType, ocrResult.text);

        // Create or get KYC record
        let kyc = await KYC.findByUser(req.user.id);
        if (!kyc) {
            kyc = await KYC.createOrGet(req.user.id);
        }

        // Update document info
        await KYC.updateDocument(req.user.id, documentType, req.file.path, {
            rawText: ocrResult.text.substring(0, 500),
            confidence: ocrResult.confidence
        });

        // Add verification history
        await KYC.addVerificationHistory(
            req.user.id,
            'document_upload',
            isValid ? 'success' : 'failed',
            `OCR Confidence: ${ocrResult.confidence.toFixed(2)}%`
        );

        // Update User step
        if (isValid) {
            await User.updateUser(req.user.id, {
                kycStep: 1,
                kycStatus: 'PENDING'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Document processed successfully',
            data: {
                extractedText: ocrResult.text.substring(0, 100) + '...',
                isValid
            }
        });

    } catch (error) {
        if (req.file) fs.unlinkSync(req.file.path);

        res.status(500).json({
            success: false,
            message: 'Error processing document',
            error: error.message
        });
    }
};

// @desc    Upload Selfie and Verify
// @route   POST /api/kyc/upload-selfie
// @access  Private
exports.uploadSelfie = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ success: false, message: 'Please upload a selfie' });
        }

        const kyc = await KYC.findByUser(req.user.id);
        if (!kyc || !kyc.documentImage) {
            fs.unlinkSync(req.file.path);
            return res.status(400).json({ success: false, message: 'Please upload ID document first' });
        }

        console.log(`[KYC] Processing selfie: ${req.file.path}`);

        // Perform Face Matching
        const score = await faceService.compareFaces(kyc.documentImage, req.file.path);
        const isMatch = score > 80;

        // Update selfie info
        await KYC.updateSelfie(req.user.id, req.file.path, score);

        // Add verification history
        await KYC.addVerificationHistory(
            req.user.id,
            'selfie_verification',
            isMatch ? 'success' : 'failed',
            `Match Score: ${score}`
        );

        if (isMatch) {
            await User.updateUser(req.user.id, { kycStep: 2 });

            res.status(200).json({
                success: true,
                message: 'Selfie verified successfully',
                data: { matchScore: score }
            });
        } else {
            res.status(200).json({
                success: false,
                message: 'Face verification failed. Please try again.',
                data: { matchScore: score }
            });
        }

    } catch (error) {
        if (req.file) fs.unlinkSync(req.file.path);
        res.status(500).json({
            success: false,
            message: 'Error processing selfie',
            error: error.message
        });
    }
};

// @desc    Initiate MFA
// @route   POST /api/kyc/mfa/request
// @access  Private
exports.requestMfa = async (req, res) => {
    try {
        await mfaService.sendOTP(req.user.id, req.user.email);

        res.status(200).json({
            success: true,
            message: 'OTP sent to your email'
        });
    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error sending OTP',
            error: error.message
        });
    }
};

// @desc    Verify MFA and Complete KYC
// @route   POST /api/kyc/mfa/verify
// @access  Private
exports.verifyMfa = async (req, res) => {
    try {
        const { otp } = req.body;

        if (!otp) {
            return res.status(400).json({ success: false, message: 'Please provide OTP' });
        }

        const isValid = mfaService.verifyOTP(req.user.id, otp);

        if (!isValid) {
            return res.status(400).json({ success: false, message: 'Invalid or expired OTP' });
        }

        // Add verification history
        await KYC.addVerificationHistory(
            req.user.id,
            'mfa_verification',
            'success',
            'OTP Verified'
        );

        // Complete KYC
        await User.updateUser(req.user.id, {
            kycStep: 3,
            kycStatus: 'VERIFIED'
        });

        res.status(200).json({
            success: true,
            message: 'KYC Verification Completed Successfully! Access Granted.',
            data: {
                kycStatus: 'VERIFIED'
            }
        });

    } catch (error) {
        res.status(500).json({
            success: false,
            message: 'Error verifying OTP',
            error: error.message
        });
    }
};
