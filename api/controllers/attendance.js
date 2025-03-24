const Attendance = require('../models/Attendance');
const Course = require('../models/Course');
const User = require('../models/User');

// @desc    Obtener todas las asistencias de un curso
// @route   GET /api/attendance/course/:courseId
// @access  Private (Solo instructores del curso)
exports.getCourseAttendance = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    if (
      req.user.role !== 'instructor' ||
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver las asistencias de este curso'
      });
    }

    const attendance = await Attendance.find({ course: req.params.courseId })
      .populate({
        path: 'student',
        select: 'name email documentNumber'
      })
      .sort({ date: -1 });

    res.status(200).json({
      success: true,
      count: attendance.length,
      data: attendance
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe un registro de asistencia para este estudiante en esta fecha y curso'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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

// @desc    Obtener una asistencia por ID
// @route   GET /api/attendance/:id
// @access  Private
exports.getAttendanceById = async (req, res, next) => {
  try {
    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario tiene acceso a la asistencia
    const course = await Course.findById(attendance.course);

    // Si es instructor, verificar que sea el instructor del curso
    if (
      req.user.role === 'instructor' &&
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    // Si es aprendiz, verificar que sea su propia asistencia
    if (
      req.user.role === 'aprendiz' &&
      attendance.student.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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

// @desc    Obtener asistencias de un estudiante en un curso
// @route   GET /api/attendance/course/:courseId/student/:studentId
// @access  Private
exports.getStudentAttendance = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.courseId);

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario tiene acceso al curso
    if (
      req.user.role === 'instructor' &&
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver las asistencias de este curso'
      });
    }

    // Si es un aprendiz, solo puede ver sus propias asistencias
    if (
      req.user.role === 'aprendiz' &&
      req.user.id !== req.params.studentId
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver las asistencias de otro estudiante'
      });
    }

    const attendance = await Attendance.find({
      course: req.params.courseId,
      student: req.params.studentId
    }).sort({ date: -1 });

    res.status(200).json({
      success: true,
      count: attendance.length,
      data: attendance
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe un registro de asistencia para este estudiante en esta fecha y curso'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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

// @desc    Obtener una asistencia por ID
// @route   GET /api/attendance/:id
// @access  Private
exports.getAttendanceById = async (req, res, next) => {
  try {
    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario tiene acceso a la asistencia
    const course = await Course.findById(attendance.course);

    // Si es instructor, verificar que sea el instructor del curso
    if (
      req.user.role === 'instructor' &&
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    // Si es aprendiz, verificar que sea su propia asistencia
    if (
      req.user.role === 'aprendiz' &&
      attendance.student.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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

// @desc    Registrar asistencia
// @route   POST /api/attendance
// @access  Private (Solo instructores)
exports.createAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden registrar asistencias'
      });
    }

    const { course, student, date, status, notes } = req.body;

    // Verificar si el curso existe y el usuario es el instructor
    const courseDoc = await Course.findById(course);

    if (!courseDoc) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    if (courseDoc.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para registrar asistencias en este curso'
      });
    }

    // Verificar si el estudiante está inscrito en el curso
    if (!courseDoc.students.includes(student)) {
      return res.status(400).json({
        success: false,
        error: 'El estudiante no está inscrito en este curso'
      });
    }

    // Agregar el instructor como creador
    req.body.createdBy = req.user.id;

    // Crear la asistencia
    const attendance = await Attendance.create(req.body);

    res.status(201).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe un registro de asistencia para este estudiante en esta fecha y curso'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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

// @desc    Obtener una asistencia por ID
// @route   GET /api/attendance/:id
// @access  Private
exports.getAttendanceById = async (req, res, next) => {
  try {
    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario tiene acceso a la asistencia
    const course = await Course.findById(attendance.course);

    // Si es instructor, verificar que sea el instructor del curso
    if (
      req.user.role === 'instructor' &&
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    // Si es aprendiz, verificar que sea su propia asistencia
    if (
      req.user.role === 'aprendiz' &&
      attendance.student.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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




// @desc    Actualizar asistencia
// @route   PUT /api/attendance/:id
// @access  Private (Solo instructores)
exports.updateAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden actualizar asistencias'
      });
    }

    let attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para actualizar asistencias en este curso'
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
    if (err.code === 11000) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe un registro de asistencia para este estudiante en esta fecha y curso'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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

// @desc    Obtener una asistencia por ID
// @route   GET /api/attendance/:id
// @access  Private
exports.getAttendanceById = async (req, res, next) => {
  try {
    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario tiene acceso a la asistencia
    const course = await Course.findById(attendance.course);

    // Si es instructor, verificar que sea el instructor del curso
    if (
      req.user.role === 'instructor' &&
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    // Si es aprendiz, verificar que sea su propia asistencia
    if (
      req.user.role === 'aprendiz' &&
      attendance.student.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta asistencia'
      });
    }

    res.status(200).json({
      success: true,
      data: attendance
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar asistencia
// @route   DELETE /api/attendance/:id
// @access  Private (Solo instructores)
exports.deleteAttendance = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar asistencias'
      });
    }

    const attendance = await Attendance.findById(req.params.id);

    if (!attendance) {
      return res.status(404).json({
        success: false,
        error: 'Registro de asistencia no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(attendance.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar asistencias en este curso'
      });
    }

    await attendance.deleteOne();

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