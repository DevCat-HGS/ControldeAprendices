const express = require('express');
const router = express.Router();
const gradeController = require('../controllers/gradeController');
const { protect, authorize } = require('../middleware/auth');

// Obtener calificaciones de un estudiante
router.get('/student/:studentId', protect, gradeController.getStudentGrades);

// Obtener calificaciones de un curso
router.get('/course/:courseId', protect, gradeController.getCourseGrades);

// Actualizar una calificación (solo instructores)
router.put('/:gradeId', protect, authorize('instructor'), gradeController.updateGrade);

// Obtener resumen del estudiante
router.get('/summary/:userId', protect, gradeController.getStudentSummary);

module.exports = router;