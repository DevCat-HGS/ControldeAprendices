const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  getEvaluations,
  getEvaluationsByCourse,
  getEvaluation,
  createEvaluation,
  updateEvaluation,
  deleteEvaluation,
  addGrade,
  updateGrade,
  submitEvidence
} = require('../controllers/evaluationController');

// Rutas protegidas para todos los usuarios
router.get('/', protect, getEvaluations);

router.get('/course/:courseId', protect, getEvaluationsByCourse);

router.get('/:id', protect, getEvaluation);

// Rutas protegidas solo para instructores
router.post('/', protect, authorize('instructor'), createEvaluation);

router.put('/:id', protect, authorize('instructor'), updateEvaluation);

router.delete('/:id', protect, authorize('instructor'), deleteEvaluation);

// Rutas para calificaciones
router.post('/:id/grades', protect, authorize('instructor'), addGrade);

router.put('/:id/grades/:studentId', protect, authorize('instructor'), updateGrade);

// Ruta para que los estudiantes suban evidencias
router.post('/:id/evidence', protect, submitEvidence);

module.exports = router;