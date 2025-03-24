const express = require('express');
const { 
  getCourseEvaluations,
  getStudentEvaluations,
  createEvaluation,
  updateEvaluation,
  deleteEvaluation,
  getEvaluationById
} = require('../controllers/evaluations');

const router = express.Router();

// Middleware de autenticación
const { protect } = require('../middleware/auth');

// Rutas para evaluaciones por curso
router.route('/course/:courseId')
  .get(protect, getCourseEvaluations);

// Rutas para evaluaciones por estudiante
router.route('/student/:studentId/course/:courseId')
  .get(protect, getStudentEvaluations);

// Rutas para crear, actualizar y eliminar evaluaciones
router.route('/')
  .post(protect, createEvaluation);

router.route('/:id')
  .get(protect, getEvaluationById)
  .put(protect, updateEvaluation)
  .delete(protect, deleteEvaluation);

module.exports = router;