const User = require('../models/User');
const Course = require('../models/Course');

// @desc    Obtener todos los usuarios
// @route   GET /api/users
// @access  Private (Solo instructores)
exports.getUsers = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver todos los usuarios'
      });
    }

    const users = await User.find().select('-password');

    res.status(200).json({
      success: true,
      count: users.length,
      data: users
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener usuarios por rol
// @route   GET /api/users/role/:role
// @access  Private (Solo instructores)
exports.getUsersByRole = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para filtrar usuarios por rol'
      });
    }

    const { role } = req.params;

    // Validar que el rol sea válido
    if (!['instructor', 'aprendiz'].includes(role)) {
      return res.status(400).json({
        success: false,
        error: 'Rol inválido. Los roles válidos son: instructor, aprendiz'
      });
    }

    const users = await User.find({ role }).select('-password');

    res.status(200).json({
      success: true,
      count: users.length,
      data: users
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener un usuario específico
// @route   GET /api/users/:id
// @access  Private
exports.getUser = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id).select('-password');

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }

    // Si el usuario no es instructor y no es el mismo usuario que se está consultando
    if (req.user.role !== 'instructor' && req.user.id !== req.params.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver este usuario'
      });
    }

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Actualizar usuario
// @route   PUT /api/users/:id
// @access  Private
exports.updateUser = async (req, res, next) => {
  try {
    let user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }

    // Verificar permisos: solo el propio usuario o un instructor puede actualizar
    if (req.user.id !== req.params.id && req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para actualizar este usuario'
      });
    }

    // Si es un aprendiz intentando cambiar su rol, no permitirlo
    if (
      req.user.role === 'aprendiz' &&
      req.body.role &&
      req.body.role !== 'aprendiz'
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para cambiar su rol'
      });
    }

    // No permitir actualizar la contraseña a través de esta ruta
    if (req.body.password) {
      delete req.body.password;
    }

    // Actualizar usuario
    user = await User.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    }).select('-password');

    res.status(200).json({
      success: true,
      data: user
    });
  } catch (err) {
    if (err.name === 'ValidationError') {
      const messages = Object.values(err.errors).map(val => val.message);
      return res.status(400).json({
        success: false,
        error: messages
      });
    } else if (err.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'El email o número de documento ya está registrado'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar usuario
// @route   DELETE /api/users/:id
// @access  Private (Solo instructores o el propio usuario)
exports.deleteUser = async (req, res, next) => {
  try {
    const user = await User.findById(req.params.id);

    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'Usuario no encontrado'
      });
    }

    // Verificar permisos: solo el propio usuario o un instructor puede eliminar
    if (req.user.id !== req.params.id && req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar este usuario'
      });
    }

    // Verificar si el usuario está asociado a algún curso como instructor
    const instructorCourses = await Course.find({ instructor: req.params.id });
    
    if (instructorCourses.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'No se puede eliminar el usuario porque es instructor de uno o más cursos'
      });
    }

    // Eliminar al usuario de los cursos donde está inscrito como estudiante
    await Course.updateMany(
      { students: req.params.id },
      { $pull: { students: req.params.id } }
    );

    // Eliminar usuario
    await user.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};