const express = require('express');
const router = express.Router();
const { register, login, getProfile, updateProfile } = require('../controllers/authController');
const { protect, authorize } = require('../middleware/auth');

// Rutas públicas
router.post('/register', register);
router.post('/login', login);

// Rutas protegidas
router.get('/profile', protect, getProfile);
router.put('/profile', protect, updateProfile);

// Ruta protegida solo para instructores
router.get('/instructors-only', protect, authorize('instructor'), (req, res) => {
  res.json({
    success: true,
    data: 'Esta ruta solo es accesible para instructores'
  });
});

module.exports = router;