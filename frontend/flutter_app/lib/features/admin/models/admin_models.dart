class AdminOverviewStats {
  const AdminOverviewStats({
    this.totalStudents = 1250,
    this.activeStudents = 1100,
    this.personalityTests = 850,
    this.growthRate = '+12.5%',
    this.activeRate = '88.0%',
    this.completionRate = '68.0%',
  });

  final int totalStudents;
  final int activeStudents;
  final int personalityTests;
  final String growthRate;
  final String activeRate;
  final String completionRate;
}

class AdminStudent {
  AdminStudent({
    required this.id,
    required this.fullName,
    required this.email,
    required this.school,
    required this.district,
    required this.stream,
    required this.alYear,
    required this.isActive,
    required this.hasCompletedTest,
    this.personalityCategory,
    this.joinedDate = 'Today',
  });

  final String id;
  final String fullName;
  final String email;
  final String school;
  final String district;
  final String stream;
  final int alYear;
  bool isActive;
  final bool hasCompletedTest;
  final String? personalityCategory;
  final String joinedDate;
}

class AdminUniversity {
  AdminUniversity({
    required this.id,
    required this.name,
    required this.shortName,
    required this.location,
    required this.type,
    required this.courseCount,
    required this.ranking,
    required this.website,
  });

  final String id;
  final String name;
  final String shortName;
  final String location;
  final String type;
  final int courseCount;
  final int ranking;
  final String website;
}

class AdminCourse {
  AdminCourse({
    required this.id,
    required this.title,
    required this.university,
    required this.stream,
    required this.durationYears,
    required this.minZScore,
  });

  final String id;
  final String title;
  final String university;
  final String stream;
  final double durationYears;
  final double minZScore;
}

class AdminCareer {
  AdminCareer({
    required this.id,
    required this.title,
    required this.category,
    required this.personalityMatch,
    required this.demandLevel,
    required this.salaryRange,
  });

  final String id;
  final String title;
  final String category;
  final String personalityMatch;
  final String demandLevel;
  final String salaryRange;
}

class AdminMockData {
  static List<AdminStudent> getInitialStudents() => [
    AdminStudent(
      id: 'std_001',
      fullName: 'Sanuthi Ranaweera',
      email: 'sanuthi.r@example.com',
      school: 'Visakha Vidyalaya',
      district: 'Colombo',
      stream: 'Mathematics',
      alYear: 2025,
      isActive: true,
      hasCompletedTest: true,
      personalityCategory: 'Analytical Thinker',
      joinedDate: '2 hours ago',
    ),
    AdminStudent(
      id: 'std_002',
      fullName: 'Kavindu Perera',
      email: 'kavindu.p@example.com',
      school: 'Ananda College',
      district: 'Colombo',
      stream: 'Technology',
      alYear: 2025,
      isActive: true,
      hasCompletedTest: true,
      personalityCategory: 'Practical Innovator',
      joinedDate: '5 hours ago',
    ),
    AdminStudent(
      id: 'std_003',
      fullName: 'Nethmi Fernando',
      email: 'nethmi.f@example.com',
      school: 'Ladies College',
      district: 'Colombo',
      stream: 'Commerce',
      alYear: 2024,
      isActive: true,
      hasCompletedTest: false,
      joinedDate: '1 day ago',
    ),
    AdminStudent(
      id: 'std_004',
      fullName: 'Tharindu Jayasuriya',
      email: 'tharindu.j@example.com',
      school: 'Dharmaraja College',
      district: 'Kandy',
      stream: 'Science',
      alYear: 2025,
      isActive: true,
      hasCompletedTest: true,
      personalityCategory: 'Analytical & Scientific',
      joinedDate: '1 day ago',
    ),
    AdminStudent(
      id: 'std_005',
      fullName: 'Dinithi Senanayake',
      email: 'dinithi.s@example.com',
      school: 'Mahamaya Girls College',
      district: 'Kandy',
      stream: 'Arts',
      alYear: 2024,
      isActive: false,
      hasCompletedTest: true,
      personalityCategory: 'Creative Visionary',
      joinedDate: '2 days ago',
    ),
    AdminStudent(
      id: 'std_006',
      fullName: 'Charith Wijesinghe',
      email: 'charith.w@example.com',
      school: 'Richmond College',
      district: 'Galle',
      stream: 'Mathematics',
      alYear: 2025,
      isActive: true,
      hasCompletedTest: false,
      joinedDate: '3 days ago',
    ),
  ];

  static List<AdminUniversity> getInitialUniversities() => [];

  static List<AdminCourse> getInitialCourses() => [
    AdminCourse(
      id: 'crs_001',
      title: 'B.Sc. (Hons) in Computer Science',
      university: 'University of Colombo',
      stream: 'Mathematics',
      durationYears: 4.0,
      minZScore: 1.85,
    ),
    AdminCourse(
      id: 'crs_002',
      title: 'B.Sc. (Hons) in Software Engineering',
      university: 'University of Moratuwa',
      stream: 'Mathematics',
      durationYears: 4.0,
      minZScore: 2.10,
    ),
    AdminCourse(
      id: 'crs_003',
      title: 'Bachelor of Medicine and Surgery (MBBS)',
      university: 'University of Peradeniya',
      stream: 'Science',
      durationYears: 5.0,
      minZScore: 2.25,
    ),
    AdminCourse(
      id: 'crs_004',
      title: 'B.Sc. in Information Technology',
      university: 'SLIIT',
      stream: 'Technology',
      durationYears: 4.0,
      minZScore: 1.20,
    ),
    AdminCourse(
      id: 'crs_005',
      title: 'B.Com. (Hons) in Finance',
      university: 'University of Colombo',
      stream: 'Commerce',
      durationYears: 4.0,
      minZScore: 1.70,
    ),
  ];

  static List<AdminCareer> getInitialCareers() => [
    AdminCareer(
      id: 'car_001',
      title: 'Software Engineer',
      category: 'Information Technology',
      personalityMatch: 'Analytical & Practical',
      demandLevel: 'Very High',
      salaryRange: 'LKR 180K - 550K/mo',
    ),
    AdminCareer(
      id: 'car_002',
      title: 'Data Scientist / AI Engineer',
      category: 'Artificial Intelligence',
      personalityMatch: 'Analytical Thinker',
      demandLevel: 'High',
      salaryRange: 'LKR 220K - 650K/mo',
    ),
    AdminCareer(
      id: 'car_003',
      title: 'Biomedical Scientist',
      category: 'Healthcare & Science',
      personalityMatch: 'Scientific & Investigative',
      demandLevel: 'Medium',
      salaryRange: 'LKR 140K - 380K/mo',
    ),
    AdminCareer(
      id: 'car_004',
      title: 'Investment & Financial Analyst',
      category: 'Finance & Banking',
      personalityMatch: 'Organized & Analytical',
      demandLevel: 'High',
      salaryRange: 'LKR 160K - 450K/mo',
    ),
    AdminCareer(
      id: 'car_005',
      title: 'UI/UX Product Designer',
      category: 'Design & Creative',
      personalityMatch: 'Creative Visionary',
      demandLevel: 'High',
      salaryRange: 'LKR 150K - 400K/mo',
    ),
  ];
}
