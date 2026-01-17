const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/auth');
const {
    saveTaxCalculation,
    getTaxCalculations,
    getLatestTaxCalculation,
    deleteTaxCalculation
} = require('../controllers/taxController');

// All routes require authentication
router.use(protect);

router.route('/')
    .get(getTaxCalculations);

router.route('/save')
    .post(saveTaxCalculation);

router.route('/latest')
    .get(getLatestTaxCalculation);

router.route('/:id')
    .delete(deleteTaxCalculation);

module.exports = router;
