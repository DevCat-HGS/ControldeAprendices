const Evaluation = require('../models/Evaluation');
const Course = require('../models/Course');
const User = require('../models/User');

// @desc    Obtener todas las evaluaciones de un curso
// @route   GET /api/evaluations/course/:courseId
// @access  Private (Solo instructores del curso)
exports.getCourseEvaluations = async (req, res, next) => {
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
        error: 'No tiene permiso para ver las evaluaciones de este curso'
      });
    }

    const evaluations = await Evaluation.find({ course: req.params.courseId })
      .populate({
        path: 'student',
        select: 'name email documentNumber'
      })
      .sort({ evaluationDate: -1 });

    res.status(200).json({
      success: true,
      count: evaluations.length,
      data: evaluations
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener evaluaciones de un estudiante en un curso
// @route   GET /api/evaluations/course/:courseId/student/:studentId
// @access  Private
exports.getStudentEvaluations = async (req, res, next) => {
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
        error: 'No tiene permiso para ver las evaluaciones de este curso'
      });
    }

    // Si es un aprendiz, solo puede ver sus propias evaluaciones
    if (
      req.user.role === 'aprendiz' &&
      req.user.id !== req.params.studentId
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver las evaluaciones de otro estudiante'
      });
    }

    const evaluations = await Evaluation.find({
      course: req.params.courseId,
      student: req.params.studentId
    }).sort({ evaluationDate: -1 });

    res.status(200).json({
      success: true,
      count: evaluations.length,
      data: evaluations
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Crear una evaluación
// @route   POST /api/evaluations
// @access  Private (Solo instructores)
exports.createEvaluation = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden crear evaluaciones'
      });
    }

    const { course, student, title, description, score, feedback, evaluationDate } = req.body;

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
        error: 'No tiene permiso para crear evaluaciones en este curso'
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

    // Crear la evaluación
    const evaluation = await Evaluation.create(req.body);

    res.status(201).json({
      success: true,
      data: evaluation
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

// @desc    Actualizar una evaluación
// @route   PUT /api/evaluations/:id
// @access  Private (Solo instructores)
exports.updateEvaluation = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden actualizar evaluaciones'
      });
    }

    let evaluation = await Evaluation.findById(req.params.id);

    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'Evaluación no encontrada'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(evaluation.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para actualizar evaluaciones en este curso'
      });
    }

    evaluation = await Evaluation.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true
    });

    res.status(200).json({
      success: true,
      data: evaluation
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

// @desc    Obtener una evaluación por ID
// @route   GET /api/evaluations/:id
// @access  Private
exports.getEvaluationById = async (req, res, next) => {
  try {
    const evaluation = await Evaluation.findById(req.params.id);

    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'Evaluación no encontrada'
      });
    }

    // Verificar si el usuario tiene acceso a la evaluación
    const course = await Course.findById(evaluation.course);

    // Si es instructor, verificar que sea el instructor del curso
    if (
      req.user.role === 'instructor' &&
      course.instructor.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta evaluación'
      });
    }

    // Si es aprendiz, verificar que sea su propia evaluación
    if (
      req.user.role === 'aprendiz' &&
      evaluation.student.toString() !== req.user.id
    ) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para ver esta evaluación'
      });
    }

    res.status(200).json({
      success: true,
      data: evaluation
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Eliminar una evaluación
// @route   DELETE /api/evaluations/:id
// @access  Private (Solo instructores)
exports.deleteEvaluation = async (req, res, next) => {
  try {
    // Verificar si el usuario es un instructor
    if (req.user.role !== 'instructor') {
      return res.status(403).json({
        success: false,
        error: 'Solo los instructores pueden eliminar evaluaciones'
      });
    }

    const evaluation = await Evaluation.findById(req.params.id);

    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'Evaluación no encontrada'
      });
    }

    // Verificar si el usuario es el instructor del curso
    const course = await Course.findById(evaluation.course);

    if (course.instructor.toString() !== req.user.id) {
      return res.status(403).json({
        success: false,
        error: 'No tiene permiso para eliminar evaluaciones en este curso'
      });
    }

    await evaluation.deleteOne();

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