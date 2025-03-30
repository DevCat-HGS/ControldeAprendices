const Attendance = require('../models/Attendance');
const Course = require('../models/Course');
const User = require('../models/User');

// @desc    Obtener todas las asistencias
// @route   GET /api/attendance
// @access  Private
exports.getAttendances = async (req, res) => {
  try {
    let query = {};
    
    // Filtrar por curso si se proporciona
    if (req.query.course) {
      query.course = req.query.course;
    }
    
    // Filtrar por estudiante si se proporciona
    if (req.query.student) {
      query['records.student'] = req.query.student;
    }
    
    // Filtrar por fecha si se proporciona
    if (req.query.date) {
      const date = new Date(req.query.date);
      const nextDay = new Date(date);
      nextDay.setDate(date.getDate() + 1);
      
      query.date = {
        $gte: date,
        $lt: nextDay
      };
    }
    
    // Si el usuario es un estudiante, solo mostrar sus asistencias
    if (req.user.role === 'student') {
      query['records.student'] = req.user.id;
    }
    
    const attendances = await Attendance.find(query)
      .populate('course', 'name')
      .populate('records.student', 'name email')
      .populate('registeredBy', 'name')
      .sort({ date: -1 });
    
    res.status(200).json({
      success: true,
      count: attendances.length,
      data: attendances
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener asistencias por curso
// @route   GET /api/attendance/course/:courseId
// @access  Private
exports.getAttendancesByCourse = async (req, res) => {
  try {
    const attendances = await Attendance.find({ course: req.params.courseId })
      .populate('records.student', 'name email')
      .populate('registeredBy', 'name')
      .sort({ date: -1 });
    
    res.status(200).json({
      success: true,
      count: attendances.length,
      data: attendances
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener una asistencia específica
// @route   GET /api/attendance/:id
// @access  Private
exports.getAttendance = async (req, res) => {
  try {
    const attendance = await Attendance.findById(req.params.id)
      .populate('course', 'name')
      .populate('records.student', 'name email')
      .populate('registeredBy', 'name');
    
    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró el registro de asistencia'
      });
    }
    
    // Verificar si el usuario es un estudiante y si tiene acceso a esta asistencia
    if (req.user.role === 'student') {
      const studentRecord = attendance.records.find(
        record => record.student._id.toString() === req.user.id
      );
      
      if (!studentRecord) {
        return res.status(403).json({
          success: false,
          error: 'No tienes permiso para ver este registro de asistencia'
        });
      }
    }
    
    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Crear un nuevo registro de asistencia
// @route   POST /api/attendance
// @access  Private (Solo instructores)
exports.createAttendance = async (req, res) => {
  try {
    // Verificar si el curso existe
    const course = await Course.findById(req.body.course);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }
    
    // Verificar si ya existe un registro para este curso y fecha
    const existingAttendance = await Attendance.findOne({
      course: req.body.course,
      date: new Date(req.body.date)
    });
    
    if (existingAttendance) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe un registro de asistencia para este curso y fecha'
      });
    }
    
    // Crear el nuevo registro de asistencia
    const attendance = await Attendance.create({
      ...req.body,
      registeredBy: req.user.id
    });
    
    res.status(201).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    console.error(err);
    if (err.name === 'ValidationError') {
      const messages = Object.values(err.errors).map(val => val.message);
      return res.status(400).json({
        success: false,
        error: messages.join(', ')
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Actualizar un registro de asistencia
// @route   PUT /api/attendance/:id
// @access  Private (Solo instructores)
exports.updateAttendance = async (req, res) => {
  try {
    let attendance = await Attendance.findById(req.params.id);
    
    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró el registro de asistencia'
      });
    }
    
    // Verificar si el instructor que actualiza es el mismo que lo registró
    if (attendance.registeredBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para actualizar este registro de asistencia'
      });
    }
    
    attendance = await Attendance.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });
    
    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    console.error(err);
    if (err.name === 'ValidationError') {
      const messages = Object.values(err.errors).map(val => val.message);
      return res.status(400).json({
        success: false,
        error: messages.join(', ')
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar un registro de asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res) => {
  try {
    const attendance = await Attendance.findById(req.params.id);
    
    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró el registro de asistencia'
      });
    }
    
    // Verificar si el instructor que elimina es el mismo que lo registró
    if (attendance.registeredBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para eliminar este registro de asistencia'
      });
    }
    
    await attendance.deleteOne();
    
    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};