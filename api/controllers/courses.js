const Course = require('../models/Course');
const User = require('../models/User');

// @desc    Obtener todos los cursos
// @route   GET /api/courses
// @access  Private
exports.getCourses = async (req, res, next) => {
  try {
    let query;
    
    // Si el usuario es un instructor, mostrar solo sus cursos
    if (req.user.role === 'instructor') {
      query = Course.find({ instructor: req.user.id });
    } else {
      // Si es un aprendiz, mostrar los cursos en los que está inscrito
      query = Course.find({ students: req.user.id });
    }

    // Ejecutar la consulta
    const courses = await query;

    res.status(200).json({
      success: true,
      count: courses.length,
      data: courses
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};


// @desc    Obtener un curso específico
// @route   GET /api/courses/:id
// @access  Private
exports.getCourse = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate({
        path: 'instructor',
        select: 'name email'
      })
      .populate({
        path: 'students',
        select: 'name email'
      });

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario tiene acceso al curso
    if (
      req.user.role === 'aprendiz' &&
      !course.students.some(student => student._id.toString() === req.user.id)
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para acceder a este curso'
      });
    }

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar un estudiante específico de un curso
// @route   DELETE /api/courses/:id/students/:studentId
// @access  Private (Solo instructores del curso)
exports.removeStudent = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si el estudiante existe en el curso
    if (!course.students.includes(req.params.studentId)) {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado en este curso'
      });
    }

    // Eliminar el estudiante del curso
    course.students = course.students.filter(
      student => student.toString() !== req.params.studentId
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Crear un nuevo curso
// @route   POST /api/courses
// @access  Private (Solo instructores)
exports.createCourse = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden crear cursos'
      });
    }

    // Agregar el instructor al curso
    req.body.instructor = req.user.id;

    const course = await Course.create(req.body);

    res.status(201).json({
      success: true,
      data: course
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
        error: 'Ya existe un curso con ese código de ficha'
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar un estudiante específico de un curso
// @route   DELETE /api/courses/:id/students/:studentId
// @access  Private (Solo instructores del curso)
exports.removeStudent = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si el estudiante existe en el curso
    if (!course.students.includes(req.params.studentId)) {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado en este curso'
      });
    }

    // Eliminar el estudiante del curso
    course.students = course.students.filter(
      student => student.toString() !== req.params.studentId
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Actualizar un curso
// @route   PUT /api/courses/:id
// @access  Private (Solo instructores del curso)
exports.updateCourse = async (req, res, next) => {
  try {
    let course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para actualizar este curso'
      });
    }

    course = await Course.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    if (err.name === 'ValidationError') {
      const messages = Object.values(err.errors).map(val => val.message);
      return res.status(400).json({
        success: false,
        error: messages
      });
    } else {
      res.status(500).json({
        success: false,
        error: 'Error del servidor'
      });
    }
  }
};

// @desc    Eliminar un estudiante específico de un curso
// @route   DELETE /api/courses/:id/students/:studentId
// @access  Private (Solo instructores del curso)
exports.removeStudent = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si el estudiante existe en el curso
    if (!course.students.includes(req.params.studentId)) {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado en este curso'
      });
    }

    // Eliminar el estudiante del curso
    course.students = course.students.filter(
      student => student.toString() !== req.params.studentId
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar un curso
// @route   DELETE /api/courses/:id
// @access  Private (Solo instructores del curso)
exports.deleteCourse = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar este curso'
      });
    }

    await course.deleteOne();

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

// @desc    Eliminar un estudiante específico de un curso
// @route   DELETE /api/courses/:id/students/:studentId
// @access  Private (Solo instructores del curso)
exports.removeStudent = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si el estudiante existe en el curso
    if (!course.students.includes(req.params.studentId)) {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado en este curso'
      });
    }

    // Eliminar el estudiante del curso
    course.students = course.students.filter(
      student => student.toString() !== req.params.studentId
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Agregar estudiantes a un curso
// @route   PUT /api/courses/:id/students
// @access  Private (Solo instructores del curso)
exports.addStudents = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para agregar estudiantes a este curso'
      });
    }

    // Verificar si se proporcionaron IDs de estudiantes
    if (!req.body.students || !Array.isArray(req.body.students) || req.body.students.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Por favor proporcione un array de IDs de estudiantes'
      });
    }

    // Verificar si los estudiantes existen y son aprendices
    const students = await User.find({
      _id: { $in: req.body.students },
      role: 'aprendiz'
    });

    if (students.length !== req.body.students.length) {
      return res.status(400).json({
        success: false,
        error: 'Uno o más estudiantes no existen o no son aprendices'
      });
    }

    // Agregar estudiantes al curso
    for (const student of students) {
      // Verificar si el estudiante ya está en el curso
      if (!course.students.includes(student._id)) {
        course.students.push(student._id);
      }
    }

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar un estudiante específico de un curso
// @route   DELETE /api/courses/:id/students/:studentId
// @access  Private (Solo instructores del curso)
exports.removeStudent = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si el estudiante existe en el curso
    if (!course.students.includes(req.params.studentId)) {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado en este curso'
      });
    }

    // Eliminar el estudiante del curso
    course.students = course.students.filter(
      student => student.toString() !== req.params.studentId
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar estudiantes de un curso
// @route   DELETE /api/courses/:id/students
// @access  Private (Solo instructores del curso)
exports.removeStudents = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si se proporcionaron IDs de estudiantes
    if (!req.body.students || !Array.isArray(req.body.students) || req.body.students.length === 0) {
      return res.status(400).json({
        success: false,
        error: 'Por favor proporcione un array de IDs de estudiantes'
      });
    }

    // Eliminar estudiantes del curso
    course.students = course.students.filter(
      student => !req.body.students.includes(student.toString())
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar un estudiante específico de un curso
// @route   DELETE /api/courses/:id/students/:studentId
// @access  Private (Solo instructores del curso)
exports.removeStudent = async (req, res, next) => {
  try {
    const course = await Course.findById(req.params.id);

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
        error: 'No tiene permiso para eliminar estudiantes de este curso'
      });
    }

    // Verificar si el estudiante existe en el curso
    if (!course.students.includes(req.params.studentId)) {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado en este curso'
      });
    }

    // Eliminar el estudiante del curso
    course.students = course.students.filter(
      student => student.toString() !== req.params.studentId
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};