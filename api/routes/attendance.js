const express = require('express');
const { 
  getCourseAttendance,
  getStudentAttendance,
  createAttendance,
  updateAttendance,
  deleteAttendance,
  getAttendanceById
} = require('../controllers/attendance');

const router = express.Router();

// Middleware de autenticación
const { protect } = require('../middleware/auth');

// Rutas para asistencias por curso
router.route('/course/:courseId')
  .get(protect, getCourseAttendance);

// Rutas para asistencias por estudiante
router.route('/student/:studentId/course/:courseId')
  .get(protect, getStudentAttendance);

// Rutas para crear, actualizar y eliminar asistencias
router.route('/')
  .post(protect, createAttendance);

router.route('/:id')
  .get(protect, getAttendanceById)
  .put(protect, updateAttendance)
  .delete(protect, deleteAttendance);

module.exports = router;