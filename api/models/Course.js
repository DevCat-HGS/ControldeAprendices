const mongoose = require('mongoose');

const CourseSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'El nombre del curso es obligatorio'],
    trim: true
  },
  code: {
    type: String,
    required: [true, 'El código del curso es obligatorio'],
    unique: true,
    trim: true
  },
  description: {
    type: String,
    required: [true, 'La descripción del curso es obligatoria']
  },
  instructor: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'El instructor es obligatorio']
  },
  students: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  startDate: {
    type: Date,
    required: [true, 'La fecha de inicio es obligatoria']
  },
  endDate: {
    type: Date,
    required: [true, 'La fecha de finalización es obligatoria']
  },
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Course', CourseSchema);