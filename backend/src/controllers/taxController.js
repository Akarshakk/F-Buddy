const TaxCalculation = require('../models/TaxCalculation');

// @desc    Save tax calculation
// @route   POST /api/tax/save
// @access  Private
exports.saveTaxCalculation = async (req, res) => {
    try {
        const { email } = req.body;

        // Check if email matches logged-in user
        if (email.toLowerCase() !== req.user.email.toLowerCase()) {
            return res.status(400).json({
                success: false,
                message: 'Email does not match logged-in user'
            });
        }

        const taxData = {
            user: req.user.id,
            ...req.body
        };

        const record = await TaxCalculation.create(taxData);

        res.status(201).json({
            success: true,
            message: 'Tax calculation saved successfully',
            data: { taxCalculation: record }
        });
    } catch (error) {
        console.error('[Tax] Error saving tax calculation:', error);
        res.status(500).json({
            success: false,
            message: 'Error saving tax calculation',
            error: error.message
        });
    }
};

// @desc    Get user's tax calculations
// @route   GET /api/tax
// @access  Private
exports.getTaxCalculations = async (req, res) => {
    try {
        const records = await TaxCalculation.findByUser(req.user.id);

        res.status(200).json({
            success: true,
            count: records.length,
            data: { taxCalculations: records }
        });
    } catch (error) {
        console.error('[Tax] Error fetching tax calculations:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching tax calculations',
            error: error.message
        });
    }
};

// @desc    Get latest tax calculation
// @route   GET /api/tax/latest
// @access  Private
exports.getLatestTaxCalculation = async (req, res) => {
    try {
        const record = await TaxCalculation.findLatestByUser(req.user.id);

        if (!record) {
            return res.status(404).json({
                success: false,
                message: 'No tax calculation found'
            });
        }

        res.status(200).json({
            success: true,
            data: { taxCalculation: record }
        });
    } catch (error) {
        console.error('[Tax] Error fetching latest tax calculation:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching tax calculation',
            error: error.message
        });
    }
};

// @desc    Delete tax calculation
// @route   DELETE /api/tax/:id
// @access  Private
exports.deleteTaxCalculation = async (req, res) => {
    try {
        await TaxCalculation.deleteById(req.params.id);

        res.status(200).json({
            success: true,
            message: 'Tax calculation deleted successfully'
        });
    } catch (error) {
        console.error('[Tax] Error deleting tax calculation:', error);
        res.status(500).json({
            success: false,
            message: 'Error deleting tax calculation',
            error: error.message
        });
    }
};
