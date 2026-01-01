const Category = require('../models/Category');
const { EXPENSE_CATEGORIES } = require('../models/Expense');

// Category configuration with icons and colors
const CATEGORY_CONFIG = {
  clothes: { displayName: 'Clothes', icon: '👕', color: '#9C27B0' },
  drinks: { displayName: 'Drinks', icon: '🍺', color: '#FF9800' },
  education: { displayName: 'Education', icon: '📚', color: '#2196F3' },
  food: { displayName: 'Food', icon: '🍔', color: '#4CAF50' },
  fuel: { displayName: 'Fuel', icon: '⛽', color: '#795548' },
  fun: { displayName: 'Fun', icon: '🎮', color: '#E91E63' },
  health: { displayName: 'Health', icon: '💊', color: '#00BCD4' },
  hotel: { displayName: 'Hotel', icon: '🏨', color: '#3F51B5' },
  personal: { displayName: 'Personal', icon: '👤', color: '#607D8B' },
  pets: { displayName: 'Pets', icon: '🐾', color: '#8BC34A' },
  restaurants: { displayName: 'Restaurants', icon: '🍽️', color: '#FF5722' },
  tips: { displayName: 'Tips', icon: '💰', color: '#FFC107' },
  transport: { displayName: 'Transport', icon: '🚗', color: '#009688' },
  others: { displayName: 'Others', icon: '📦', color: '#9E9E9E' }
};

// @desc    Get all categories
// @route   GET /api/categories
// @access  Public
exports.getCategories = async (req, res) => {
  try {
    // Return predefined categories with config
    const categories = EXPENSE_CATEGORIES.map(cat => ({
      name: cat,
      ...CATEGORY_CONFIG[cat]
    }));

    res.status(200).json({
      success: true,
      count: categories.length,
      data: { categories }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error fetching categories',
      error: error.message
    });
  }
};

// @desc    Seed categories to database (for future customization)
// @route   POST /api/categories/seed
// @access  Private (Admin only - for now just protected)
exports.seedCategories = async (req, res) => {
  try {
    // Clear existing categories
    await Category.deleteMany({});

    // Create categories
    const categories = EXPENSE_CATEGORIES.map(cat => ({
      name: cat,
      ...CATEGORY_CONFIG[cat]
    }));

    await Category.insertMany(categories);

    res.status(201).json({
      success: true,
      message: 'Categories seeded successfully',
      count: categories.length,
      data: { categories }
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error seeding categories',
      error: error.message
    });
  }
};
