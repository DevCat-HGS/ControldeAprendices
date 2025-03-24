const express = require('express');
const { register, login, getMe } = require('../controllers/auth');

const router = express.Router();

// Middleware de autenticación
const { protect } = require('../middleware/auth');

// Rutas públicas
router.post('/register', register);
router.post('/login', login);

// Rutas privadas
router.get('/me', protect, getMe);

module.exports = router;