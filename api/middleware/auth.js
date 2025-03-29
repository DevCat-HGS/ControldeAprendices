const jwt = require('jsonwebtoken');
const User = require('../models/User');

// Middleware para proteger rutas
exports.protect = async (req, res, next) => {
  let token;

  // Verificar si existe el token en los headers
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  // Verificar si el token existe
  if (!token) {
    return res.status(401).json({
      success: false,
      error: 'No está autorizado para acceder a esta ruta'
    });
  }

  try {
    // Verificar el token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Buscar el usuario por id
    req.user = await User.findById(decoded.id);

    if (!req.user) {
      return res.status(401).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }

    next();
  } catch (err) {
    return res.status(401).json({
      success: false,
      error: 'No está autorizado para acceder a esta ruta'
    });
  }
};

// Middleware para verificar roles
exports.authorize = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para realizar esta acción'
      });
    }
    next();
  };
};