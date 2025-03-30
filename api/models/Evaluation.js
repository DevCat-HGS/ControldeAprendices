const mongoose = require('mongoose');

const EvaluationSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'El nombre de la evaluación es obligatorio'],
    trim: true
  },
  course: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: [true, 'El curso es obligatorio']
  },
  description: {
    type: String,
    required: [true, 'La descripción de la evaluación es obligatoria']
  },
  maxScore: {
    type: Number,
    required: [true, 'El puntaje máximo es obligatorio'],
    min: [0, 'El puntaje máximo no puede ser negativo']
  },
  dueDate: {
    type: Date,
    required: [true, 'La fecha de entrega es obligatoria']
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: [true, 'El instructor que crea la evaluación es obligatorio']
  },
  grades: [{
    student: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'El estudiante es obligatorio']
    },
    score: {
      type: Number,
      default: 0
    },
    feedback: {
      type: String,
      default: ''
    },
    evidence: {
      type: String,
      default: ''
    },
    submittedAt: {
      type: Date,
      default: null
    },
    gradedAt: {
      type: Date,
      default: null
    }
  }],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Evaluation', EvaluationSchema);