const express = require('express');
const router = express.Router();
const { protect, authorize } = require('../middleware/auth');
const {
  getAttendances,
  getAttendancesByCourse,
  getAttendance,
  createAttendance,
  updateAttendance,
  deleteAttendance
} = require('../controllers/attendanceController');

// Rutas protegidas para todos los usuarios
router.get('/', protect, getAttendances);

router.get('/course/:courseId', protect, getAttendancesByCourse);

router.get('/:id', protect, getAttendance);

// Rutas protegidas solo para instructores
router.post('/', protect, authorize('instructor'), createAttendance);

router.put('/:id', protect, authorize('instructor'), updateAttendance);

router.delete('/:id', protect, authorize('instructor'), deleteAttendance);

module.exports = router;