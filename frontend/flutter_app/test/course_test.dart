import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/course.dart';

void main() {
  test('decodes a complete course record', () {
    final course = Course.fromJson({
      '_id': 'course-1',
      'title': 'BSc Computer Science',
      'university': 'University of Example',
      'stream': 'Mathematics',
      'degreeType': "Bachelor's Degree",
      'description': 'Study computing and software systems.',
      'durationYears': 4,
      'minZScore': 1.85,
      'subjects': ['Combined Mathematics', 'Physics'],
      'careerPaths': ['Software Engineer', 'Data Analyst'],
      'website': 'example.edu',
      'applicationUrl': 'https://example.edu/apply',
    });

    expect(course.id, 'course-1');
    expect(course.durationYears, 4);
    expect(course.minZScore, 1.85);
    expect(course.subjects, ['Combined Mathematics', 'Physics']);
    expect(course.careerPaths, ['Software Engineer', 'Data Analyst']);
  });

  test('uses safe defaults for optional catalog fields', () {
    final course = Course.fromJson({
      '_id': 'course-2',
      'title': 'General Studies',
      'university': 'University of Example',
      'stream': 'Any',
      'durationYears': 3,
    });

    expect(course.description, isEmpty);
    expect(course.minZScore, isNull);
    expect(course.subjects, isEmpty);
    expect(course.applicationUrl, isEmpty);
  });
}