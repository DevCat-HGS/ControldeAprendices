const Grade = require('../models/Grade');
const User = require('../models/User');
const Course = require('../models/Course');
const Evaluation = require('../models/Evaluation');

exports.getStudentGrades = async (req, res) => {
  try {
    const { studentId } = req.params;

    const grades = await Grade.find({ student: studentId })
      .populate('evaluation', 'name maxScore')
      .populate('course', 'name code')
      .populate('student', 'name lastName');

    const formattedGrades = grades.map(grade => ({
      _id: grade._id,
      evaluationName: grade.evaluation.name,
      courseName: grade.course.name,
      courseCode: grade.course.code,
      studentName: `${grade.student.name} ${grade.student.lastName}`,
      score: grade.score,
      maxScore: grade.evaluation.maxScore,
      comments: grade.comments,
      submittedDate: grade.submittedDate
    }));

    res.json({ success: true, grades: formattedGrades });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error al obtener las calificaciones' });
  }
};

exports.getCourseGrades = async (req, res) => {
  try {
    const { courseId } = req.params;

    const grades = await Grade.find({ course: courseId })
      .populate('evaluation', 'name maxScore')
      .populate('student', 'name lastName')
      .populate('course', 'name code');

    const formattedGrades = grades.map(grade => ({
      _id: grade._id,
      evaluationName: grade.evaluation.name,
      studentName: `${grade.student.name} ${grade.student.lastName}`,
      score: grade.score,
      maxScore: grade.evaluation.maxScore,
      comments: grade.comments,
      submittedDate: grade.submittedDate
    }));

    res.json({ success: true, grades: formattedGrades });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error al obtener las calificaciones del curso' });
  }
};

exports.updateGrade = async (req, res) => {
  try {
    const { gradeId } = req.params;
    const { score, comments } = req.body;

    const grade = await Grade.findById(gradeId);
    if (!grade) {
      return res.status(404).json({ success: false, message: 'Calificación no encontrada' });
    }

    grade.score = score;
    grade.comments = comments;
    grade.lastModified = Date.now();
    await grade.save();

    res.json({ success: true, message: 'Calificación actualizada con éxito', grade });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error al actualizar la calificación' });
  }
};

exports.getStudentSummary = async (req, res) => {
  try {
    const { userId } = req.params;

    // Obtener todas las calificaciones del estudiante
    const grades = await Grade.find({ student: userId });
    
    // Calcular promedio de calificaciones
    const totalGrades = grades.length;
    const averageGrade = totalGrades > 0
      ? grades.reduce((acc, grade) => acc + grade.score, 0) / totalGrades
      : 0;

    // Obtener asistencia del estudiante
    const attendances = await Attendance.find({ student: userId });
    const totalClasses = await Course.countDocuments();
    const attendancePercentage = totalClasses > 0
      ? (attendances.length / totalClasses) * 100
      : 0;

    res.json({
      success: true,
      summary: {
        averageGrade: averageGrade.toFixed(2),
        attendancePercentage: attendancePercentage.toFixed(2),
        completedEvaluations: totalGrades
      }
    });
  } catch (error) {
    res.status(500).json({ success: false, message: 'Error al obtener el resumen del estudiante' });
  }
};