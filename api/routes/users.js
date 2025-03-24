const express = require('express');
const { 
  getUsers, 
  getUser, 
  updateUser, 
  deleteUser,
  getUsersByRole
} = require('../controllers/users');

const router = express.Router();

// Middleware de autenticación
const { protect } = require('../middleware/auth');

router.route('/').get(protect, getUsers);
router.route('/role/:role').get(protect, getUsersByRole);
router.route('/:id').get(protect, getUser).put(protect, updateUser).delete(protect, deleteUser);

module.exports = router;