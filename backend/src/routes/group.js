const express = require('express');
const router = express.Router();
const {
    createGroup,
    getGroups,
    getGroupById,
    joinGroup,
    addMember,
    deleteGroup,
    leaveGroup,
    transferOwnership,
    settleUp,
    addExpense,
    deleteGroupExpense,
    sendMessage,
    getMessages
} = require('../controllers/groupController');
const { protect } = require('../middleware/auth');

// All routes require authentication
router.use(protect);

// Group routes
router.post('/', createGroup);
router.get('/', getGroups);
router.post('/join', joinGroup);
router.get('/:id', getGroupById);
router.post('/:id/members', addMember);
router.post('/:id/transfer', transferOwnership);
router.post('/:id/settle', settleUp);
router.post('/:id/leave', leaveGroup);
router.delete('/:id', deleteGroup);

// Expense routes
router.post('/:id/expenses', addExpense);
router.delete('/:id/expenses/:expenseId', deleteGroupExpense);

// Chat routes
router.post('/:id/chat', sendMessage);
router.get('/:id/chat', getMessages);

module.exports = router;
