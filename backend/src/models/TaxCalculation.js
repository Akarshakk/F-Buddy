const { getDb } = require('../config/firebase');
const { serializeDoc } = require('../utils/firestore');

const COLLECTION_NAME = 'taxCalculations';

// Create a new tax calculation record
const create = async (taxData) => {
    const db = getDb();

    const record = {
        user: taxData.user,
        name: taxData.name,
        email: taxData.email,
        assessmentYear: taxData.assessmentYear,
        residentialStatus: taxData.residentialStatus,

        // Compliance
        panAadhaarLinked: taxData.panAadhaarLinked || false,
        bankPreValidated: taxData.bankPreValidated || false,
        multipleEmployers: taxData.multipleEmployers || false,
        multipleHouseProperties: taxData.multipleHouseProperties || false,
        soldAssetsCapitalGains: taxData.soldAssetsCapitalGains || false,
        hasDividendAgriIncome: taxData.hasDividendAgriIncome || false,
        hasFreelanceIncome: taxData.hasFreelanceIncome || false,

        // Income
        salaryIncome: taxData.salaryIncome || 0,
        interestIncome: taxData.interestIncome || 0,
        rentalIncome: taxData.rentalIncome || 0,
        capitalGains: taxData.capitalGains || 0,
        freelanceIncome: taxData.freelanceIncome || 0,
        otherIncome: taxData.otherIncome || 0,
        grossIncome: taxData.grossIncome || 0,

        // Deductions
        section80C: taxData.section80C || 0,
        section80D: taxData.section80D || 0,
        section80CCD1B: taxData.section80CCD1B || 0,
        section24b: taxData.section24b || 0,
        section80E: taxData.section80E || 0,
        section80G: taxData.section80G || 0,
        totalDeductions: taxData.totalDeductions || 0,

        // HRA
        livesInRentedHouse: taxData.livesInRentedHouse || false,
        isMetroCity: taxData.isMetroCity || false,
        basicSalary: taxData.basicSalary || 0,
        hraReceived: taxData.hraReceived || 0,
        rentPaid: taxData.rentPaid || 0,
        hraExemption: taxData.hraExemption || 0,

        // Results
        newRegimeTax: taxData.newRegimeTax || 0,
        oldRegimeTax: taxData.oldRegimeTax || 0,
        betterRegime: taxData.betterRegime || 'New Regime',
        savings: taxData.savings || 0,

        createdAt: new Date(),
        updatedAt: new Date()
    };

    const docRef = await db.collection(COLLECTION_NAME).add(record);
    return { id: docRef.id, ...record };
};

// Find tax calculations by user ID
const findByUser = async (userId) => {
    const db = getDb();
    const snapshot = await db.collection(COLLECTION_NAME)
        .where('user', '==', userId)
        .orderBy('createdAt', 'desc')
        .get();

    return snapshot.docs.map(doc => serializeDoc(doc));
};

// Find latest tax calculation for user
const findLatestByUser = async (userId) => {
    const db = getDb();
    const snapshot = await db.collection(COLLECTION_NAME)
        .where('user', '==', userId)
        .orderBy('createdAt', 'desc')
        .limit(1)
        .get();

    if (snapshot.empty) return null;
    return serializeDoc(snapshot.docs[0]);
};

// Delete tax calculation
const deleteById = async (id) => {
    const db = getDb();
    await db.collection(COLLECTION_NAME).doc(id).delete();
};

module.exports = {
    COLLECTION_NAME,
    create,
    findByUser,
    findLatestByUser,
    deleteById
};
