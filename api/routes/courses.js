const express = require('express');
const { 
  getCourses, 
  getCourse, 
  createCourse, 
  updateCourse, 
  deleteCourse,
  addStudents,
  removeStudent
} = require('../controllers/courses');

const router = express.Router();

// Middleware de autenticación
const { protect } = require('../middleware/auth');

router.route('/')
  .get(protect, getCourses)
  .post(protect, createCourse);

router.route('/:id')
  .get(protect, getCourse)
  .put(protect, updateCourse)
  .delete(protect, deleteCourse);

router.route('/:id/enroll')
  .post(protect, addStudents);

router.route('/:id/students/:studentId')
  .delete(protect, removeStudent);

module.exports = router;