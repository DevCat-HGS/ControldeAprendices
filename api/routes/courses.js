const express = require('express');
const router = express.Router();
const { 
  createCourse, 
  getCourses, 
  getCourse, 
  updateCourse, 
  deleteCourse, 
  addStudentToCourse, 
  removeStudentFromCourse 
} = require('../controllers/courseController');
const { protect, authorize } = require('../middleware/auth');

// Rutas públicas - ninguna

// Rutas protegidas para todos los usuarios
router.get('/', protect, getCourses);
router.get('/:id', protect, getCourse);

// Rutas protegidas solo para instructores
router.post('/', protect, authorize('instructor'), createCourse);
router.put('/:id', protect, authorize('instructor'), updateCourse);
router.delete('/:id', protect, authorize('instructor'), deleteCourse);
router.post('/:id/students', protect, authorize('instructor'), addStudentToCourse);
router.delete('/:id/students/:studentId', protect, authorize('instructor'), removeStudentFromCourse);

module.exports = router;