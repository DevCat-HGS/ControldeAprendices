const mongoose = require('mongoose');

const gradeSchema = new mongoose.Schema({
  evaluation: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Evaluation',
    required: true
  },
  student: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  course: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Course',
    required: true
  },
  score: {
    type: Number,
    required: true,
    min: 0,
    max: 100
  },
  comments: {
    type: String
  },
  submittedDate: {
    type: Date,
    default: Date.now
  },
  lastModified: {
    type: Date,
    default: Date.now
  }
});

module.exports = mongoose.model('Grade', gradeSchema);