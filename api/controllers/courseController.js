const Course = require('../models/Course');
const User = require('../models/User');

// @desc    Crear un nuevo curso
// @route   POST /api/courses
// @access  Private (Solo instructores)
exports.createCourse = async (req, res) => {
  try {
    const { name, code, description, startDate, endDate, students } = req.body;

    // Verificar si ya existe un curso con el mismo código
    const existingCourse = await Course.findOne({ code });
    if (existingCourse) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe un curso con este código'
      });
    }

    // Crear el curso con el instructor actual
    const course = await Course.create({
      name,
      code,
      description,
      instructor: req.user.id,
      students: students || [],
      startDate,
      endDate
    });

    res.status(201).json({
      success: true,
      data: course
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// @desc    Obtener todos los cursos
// @route   GET /api/courses
// @access  Private
exports.getCourses = async (req, res) => {
  try {
    let query;

    // Si el usuario es instructor, mostrar solo sus cursos
    if (req.user.role === 'instructor') {
      query = Course.find({ instructor: req.user.id });
    } 
    // Si el usuario es aprendiz, mostrar los cursos en los que está inscrito
    else if (req.user.role === 'aprendiz') {
      query = Course.find({ students: req.user.id });
    }

    // Populate para obtener datos del instructor
    query = query.populate('instructor', 'name lastName email');

    const courses = await query;

    res.status(200).json({
      success: true,
      count: courses.length,
      data: courses
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// @desc    Obtener un curso por ID
// @route   GET /api/courses/:id
// @access  Private
exports.getCourse = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id)
      .populate('instructor', 'name lastName email')
      .populate('students', 'name lastName email');

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
        error: 'No tienes permiso para ver este curso'
      });
    }

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// @desc    Actualizar un curso
// @route   PUT /api/courses/:id
// @access  Private (Solo instructor del curso)
exports.updateCourse = async (req, res) => {
  try {
    let course = await Course.findById(req.params.id);

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para actualizar este curso'
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
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// @desc    Eliminar un curso
// @route   DELETE /api/courses/:id
// @access  Private (Solo instructor del curso)
exports.deleteCourse = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para eliminar este curso'
      });
    }

    await course.deleteOne();

    res.status(200).json({
      success: true,
      data: {}
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// @desc    Agregar estudiantes a un curso
// @route   PUT /api/courses/:id/students
// @access  Private (Solo instructor del curso)
exports.addStudents = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para modificar este curso'
      });
    }

    const { studentIds } = req.body;

    // Verificar que los estudiantes existan y sean aprendices
    for (const studentId of studentIds) {
      const student = await User.findById(studentId);
      
      if (!student) {
        return res.status(404).json({
          success: false,
          error: `Estudiante con ID ${studentId} no encontrado`
        });
      }

      if (student.role !== 'aprendiz') {
        return res.status(400).json({
          success: false,
          error: `El usuario con ID ${studentId} no es un aprendiz`
        });
      }

      // Agregar estudiante si no está ya en el curso
      if (!course.students.includes(studentId)) {
        course.students.push(studentId);
      }
    }

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};

// @desc    Eliminar estudiantes de un curso
// @route   DELETE /api/courses/:id/students
// @access  Private (Solo instructor del curso)
exports.removeStudents = async (req, res) => {
  try {
    const course = await Course.findById(req.params.id);

    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }

    // Verificar si el usuario es el instructor del curso
    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para modificar este curso'
      });
    }

    const { studentIds } = req.body;

    // Eliminar estudiantes del curso
    course.students = course.students.filter(
      student => !studentIds.includes(student.toString())
    );

    await course.save();

    res.status(200).json({
      success: true,
      data: course
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
};