const mongoose = require('mongoose');

const AttendanceSchema = new mongoose.Schema({
  course: {
    type: mongoose.Schema.ObjectId,
    ref: 'Course',
    required: [true, 'Por favor ingrese el ID del curso']
  },
  student: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: [true, 'Por favor ingrese el ID del estudiante']
  },
  date: {
    type: Date,
    required: [true, 'Por favor ingrese la fecha'],
    default: Date.now
  },
  status: {
    type: String,
    required: [true, 'Por favor ingrese el estado de asistencia'],
    enum: ['presente', 'ausente', 'excusa', 'retardo']
  },
  notes: {
    type: String,
    maxlength: [500, 'Las notas no pueden tener más de 500 caracteres']
  },
  createdBy: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

// Índice compuesto para evitar registros duplicados para el mismo estudiante, curso y fecha
AttendanceSchema.index({ course: 1, student: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', AttendanceSchema);