const express = require('express');
const router = express.Router();
const { 
  createCourse, 
  getCourses, 
  getCourse, 
  updateCourse, 
  deleteCourse, 
  addStudents, 
  removeStudents,
  enrollCourse,
  unenrollCourse,
  getAvailableCourses
} = require('../controllers/courseController');
const { protect, authorize } = require('../middleware/auth');

// Rutas públicas - ninguna

// Rutas protegidas para todos los usuarios
router.get('/', protect, getCourses);
router.get('/:id', protect, getCourse);

// Rutas para aprendices
router.get('/available/list', protect, authorize('aprendiz'), getAvailableCourses);
router.post('/:id/enroll', protect, authorize('aprendiz'), enrollCourse);
router.delete('/:id/enroll', protect, authorize('aprendiz'), unenrollCourse);

// Rutas protegidas solo para instructores
router.post('/', protect, authorize('instructor'), createCourse);
router.put('/:id', protect, authorize('instructor'), updateCourse);
router.delete('/:id', protect, authorize('instructor'), deleteCourse);
router.post('/:id/students', protect, authorize('instructor'), addStudents);
router.delete('/:id/students', protect, authorize('instructor'), removeStudents);

module.exports = router;