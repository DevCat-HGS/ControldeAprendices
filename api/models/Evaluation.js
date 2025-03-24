const mongoose = require('mongoose');

const EvaluationSchema = new mongoose.Schema({
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
  title: {
    type: String,
    required: [true, 'Por favor ingrese el título de la evaluación'],
    trim: true,
    maxlength: [100, 'El título no puede tener más de 100 caracteres']
  },
  description: {
    type: String,
    required: [true, 'Por favor ingrese una descripción'],
    maxlength: [500, 'La descripción no puede tener más de 500 caracteres']
  },
  score: {
    type: Number,
    required: [true, 'Por favor ingrese la calificación'],
    min: [0, 'La calificación no puede ser menor a 0'],
    max: [5, 'La calificación no puede ser mayor a 5']
  },
  feedback: {
    type: String,
    maxlength: [1000, 'La retroalimentación no puede tener más de 1000 caracteres']
  },
  evaluationDate: {
    type: Date,
    required: [true, 'Por favor ingrese la fecha de evaluación'],
    default: Date.now
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

// Índice compuesto para facilitar búsquedas
EvaluationSchema.index({ course: 1, student: 1, evaluationDate: 1 });

module.exports = mongoose.model('Evaluation', EvaluationSchema);