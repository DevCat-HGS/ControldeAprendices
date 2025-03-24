const mongoose = require('mongoose');

const CourseSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Por favor ingrese el nombre del curso'],
    trim: true,
    maxlength: [100, 'El nombre no puede tener más de 100 caracteres']
  },
  code: {
    type: String,
    required: [true, 'Por favor ingrese el código de la ficha'],
    unique: true,
    trim: true,
    maxlength: [20, 'El código no puede tener más de 20 caracteres']
  },
  description: {
    type: String,
    required: [true, 'Por favor ingrese una descripción'],
    maxlength: [500, 'La descripción no puede tener más de 500 caracteres']
  },
  program: {
    type: String,
    required: [true, 'Por favor ingrese el programa de formación'],
    trim: true
  },
  startDate: {
    type: Date,
    required: [true, 'Por favor ingrese la fecha de inicio']
  },
  endDate: {
    type: Date,
    required: [true, 'Por favor ingrese la fecha de finalización']
  },
  instructor: {
    type: mongoose.Schema.ObjectId,
    ref: 'User',
    required: true
  },
  students: [
    {
      type: mongoose.Schema.ObjectId,
      ref: 'User'
    }
  ],
  createdAt: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Course', CourseSchema);