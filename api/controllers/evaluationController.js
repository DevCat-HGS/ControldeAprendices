const Evaluation = require('../models/Evaluation');
const Course = require('../models/Course');
const User = require('../models/User');

// @desc    Obtener todas las evaluaciones
// @route   GET /api/evaluations
// @access  Private
exports.getEvaluations = async (req, res) => {
  try {
    let query = {};
    
    // Filtrar por curso si se proporciona
    if (req.query.course) {
      query.course = req.query.course;
    }
    
    // Si el usuario es un estudiante, solo mostrar sus evaluaciones
    if (req.user.role === 'student') {
      query['grades.student'] = req.user.id;
    }
    
    const evaluations = await Evaluation.find(query)
      .populate('course', 'name')
      .populate('grades.student', 'name email')
      .populate('createdBy', 'name')
      .sort({ dueDate: 1 });
    
    res.status(200).json({
      success: true,
      count: evaluations.length,
      data: evaluations
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener evaluaciones por curso
// @route   GET /api/evaluations/course/:courseId
// @access  Private
exports.getEvaluationsByCourse = async (req, res) => {
  try {
    const evaluations = await Evaluation.find({ course: req.params.courseId })
      .populate('grades.student', 'name email')
      .populate('createdBy', 'name')
      .sort({ dueDate: 1 });
    
    res.status(200).json({
      success: true,
      count: evaluations.length,
      data: evaluations
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Obtener una evaluación específica
// @route   GET /api/evaluations/:id
// @access  Private
exports.getEvaluation = async (req, res) => {
  try {
    const evaluation = await Evaluation.findById(req.params.id)
      .populate('course', 'name')
      .populate('grades.student', 'name email')
      .populate('createdBy', 'name');
    
    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la evaluación'
      });
    }
    
    // Verificar si el usuario es un estudiante y si tiene acceso a esta evaluación
    if (req.user.role === 'student') {
      const studentGrade = evaluation.grades.find(
        grade => grade.student._id.toString() === req.user.id
      );
      
      if (!studentGrade && !evaluation.course.students.includes(req.user.id)) {
        return res.status(403).json({
          success: false,
          error: 'No tienes permiso para ver esta evaluación'
        });
      }
    }
    
    res.status(200).json({
      success: true,
      data: evaluation
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Crear una nueva evaluación
// @route   POST /api/evaluations
// @access  Private (Solo instructores)
exports.createEvaluation = async (req, res) => {
  try {
    // Verificar si el curso existe
    const course = await Course.findById(req.body.course);
    if (!course) {
      return res.status(404).json({
        success: false,
        error: 'Curso no encontrado'
      });
    }
    
    // Crear la nueva evaluación
    const evaluation = await Evaluation.create({
      ...req.body,
      createdBy: req.user.id
    });
    
    res.status(201).json({
      success: true,
      data: evaluation
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

// @desc    Actualizar una evaluación
// @route   PUT /api/evaluations/:id
// @access  Private (Solo instructores)
exports.updateEvaluation = async (req, res) => {
  try {
    let evaluation = await Evaluation.findById(req.params.id);
    
    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la evaluación'
      });
    }
    
    // Verificar si el instructor que actualiza es el mismo que la creó
    if (evaluation.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para actualizar esta evaluación'
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

// @desc    Eliminar una evaluación
// @route   DELETE /api/evaluations/:id
// @access  Private (Solo instructores)
exports.deleteEvaluation = async (req, res) => {
  try {
    const evaluation = await Evaluation.findById(req.params.id);
    
    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la evaluación'
      });
    }
    
    // Verificar si el instructor que elimina es el mismo que la creó
    if (evaluation.createdBy.toString() !== req.user.id && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        error: 'No tienes permiso para eliminar esta evaluación'
      });
    }
    
    await evaluation.deleteOne();
    
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

// @desc    Agregar una calificación a una evaluación
// @route   POST /api/evaluations/:id/grades
// @access  Private (Solo instructores)
exports.addGrade = async (req, res) => {
  try {
    const evaluation = await Evaluation.findById(req.params.id);
    
    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la evaluación'
      });
    }
    
    // Verificar si el estudiante existe
    const student = await User.findById(req.body.student);
    if (!student || student.role !== 'student') {
      return res.status(404).json({
        success: false,
        error: 'Estudiante no encontrado'
      });
    }
    
    // Verificar si ya existe una calificación para este estudiante
    const existingGrade = evaluation.grades.find(
      grade => grade.student.toString() === req.body.student
    );
    
    if (existingGrade) {
      return res.status(400).json({
        success: false,
        error: 'Ya existe una calificación para este estudiante'
      });
    }
    
    // Agregar la calificación
    evaluation.grades.push({
      student: req.body.student,
      score: req.body.score || 0,
      feedback: req.body.feedback || '',
      gradedAt: new Date()
    });
    
    await evaluation.save();
    
    res.status(200).json({
      success: true,
      data: evaluation
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Actualizar una calificación existente
// @route   PUT /api/evaluations/:id/grades/:studentId
// @access  Private (Solo instructores)
exports.updateGrade = async (req, res) => {
  try {
    const evaluation = await Evaluation.findById(req.params.id);
    
    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la evaluación'
      });
    }
    
    // Encontrar la calificación del estudiante
    const gradeIndex = evaluation.grades.findIndex(
      grade => grade.student.toString() === req.params.studentId
    );
    
    if (gradeIndex === -1) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la calificación para este estudiante'
      });
    }
    
    // Actualizar la calificación
    if (req.body.score !== undefined) {
      evaluation.grades[gradeIndex].score = req.body.score;
    }
    
    if (req.body.feedback !== undefined) {
      evaluation.grades[gradeIndex].feedback = req.body.feedback;
    }
    
    evaluation.grades[gradeIndex].gradedAt = new Date();
    
    await evaluation.save();
    
    res.status(200).json({
      success: true,
      data: evaluation
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};

// @desc    Subir evidencia para una evaluación
// @route   POST /api/evaluations/:id/evidence
// @access  Private
exports.submitEvidence = async (req, res) => {
  try {
    const evaluation = await Evaluation.findById(req.params.id);
    
    if (!evaluation) {
      return res.status(404).json({
        success: false,
        error: 'No se encontró la evaluación'
      });
    }
    
    // Verificar si el estudiante está en el curso
    const course = await Course.findById(evaluation.course);
    if (!course.students.includes(req.user.id)) {
      return res.status(403).json({
        success: false,
        error: 'No estás inscrito en este curso'
      });
    }
    
    // Encontrar o crear la calificación del estudiante
    let gradeIndex = evaluation.grades.findIndex(
      grade => grade.student.toString() === req.user.id
    );
    
    if (gradeIndex === -1) {
      // Crear una nueva entrada para el estudiante
      evaluation.grades.push({
        student: req.user.id,
        score: 0,
        feedback: '',
        evidence: req.body.evidence,
        submittedAt: new Date()
      });
    } else {
      // Actualizar la evidencia existente
      evaluation.grades[gradeIndex].evidence = req.body.evidence;
      evaluation.grades[gradeIndex].submittedAt = new Date();
    }
    
    await evaluation.save();
    
    res.status(200).json({
      success: true,
      data: evaluation
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      success: false,
      error: 'Error del servidor'
    });
  }
};