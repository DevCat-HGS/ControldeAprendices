const mongoose = require('mongoose');

const AttendanceSchema = new mongoose.Schema({
  course: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'El curso es obligatorio']
  },
  date: {
    type: Date,
    required: [true, 'La fecha es obligatoria'],
    default: Date.now
  },
  records: [{
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'El estudiante es obligatorio']
    },
    present: {
      type: Boolean,
      default: false
    },
    justification: {
      type: String,
      default: ''
    }
  }],
  registeredBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'El instructor que registra la asistencia es obligatorio']
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Attendance', AttendanceSchema);