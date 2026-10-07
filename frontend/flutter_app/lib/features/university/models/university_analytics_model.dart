class DailyTrendPoint {
  const DailyTrendPoint({
    required this.date,
    required this.label,
    required this.dayOfWeek,
    required this.count,
  });

  final String date;
  final String label;
  final String dayOfWeek;
  final int count;

  factory DailyTrendPoint.fromJson(Map<String, dynamic> json) {
    return DailyTrendPoint(
      date: (json['date'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      dayOfWeek: (json['dayOfWeek'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MonthlyTrendPoint {
  const MonthlyTrendPoint({
    required this.month,
    required this.count,
  });

  final String month;
  final int count;

  factory MonthlyTrendPoint.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendPoint(
      month: (json['month'] ?? '').toString(),
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class CourseAnalyticsItem {
  const CourseAnalyticsItem({
    required this.id,
    required this.title,
    required this.code,
    required this.stream,
    required this.degreeType,
    required this.durationYears,
    this.minZScore,
    required this.views,
    required this.interest,
  });

  final String id;
  final String title;
  final String code;
  final String stream;
  final String degreeType;
  final double durationYears;
  final double? minZScore;
  final int views;
  final int interest;

  factory CourseAnalyticsItem.fromJson(Map<String, dynamic> json) {
    return CourseAnalyticsItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      stream: (json['stream'] ?? '').toString(),
      degreeType: (json['degreeType'] ?? '').toString(),
      durationYears: (json['durationYears'] as num?)?.toDouble() ?? 4.0,
      minZScore: (json['minZScore'] as num?)?.toDouble(),
      views: (json['views'] as num?)?.toInt() ?? 0,
      interest: (json['interest'] as num?)?.toInt() ?? 0,
    );
  }
}

class ScholarshipPerformanceItem {
  const ScholarshipPerformanceItem({
    required this.id,
    required this.title,
    required this.scholarshipType,
    required this.amount,
    required this.applications,
  });

  final String id;
  final String title;
  final String scholarshipType;
  final String amount;
  final int applications;

  factory ScholarshipPerformanceItem.fromJson(Map<String, dynamic> json) {
    return ScholarshipPerformanceItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      scholarshipType: (json['scholarshipType'] ?? 'Merit').toString(),
      amount: (json['amount'] ?? '').toString(),
      applications: (json['applications'] as num?)?.toInt() ?? 0,
    );
  }
}

class AnalyticsOverview {
  const AnalyticsOverview({
    required this.profileViews,
    required this.studentsInterested,
    required this.favourites,
    required this.courseViews,
    required this.scholarshipApplications,
    required this.totalApplications,
    required this.comparisons,
    required this.searchAppearances,
  });

  final int profileViews;
  final int studentsInterested;
  final int favourites;
  final int courseViews;
  final int scholarshipApplications;
  final int totalApplications;
  final int comparisons;
  final int searchAppearances;

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      profileViews: (json['profileViews'] as num?)?.toInt() ?? 0,
      studentsInterested: (json['studentsInterested'] as num?)?.toInt() ?? 0,
      favourites: (json['favourites'] as num?)?.toInt() ?? 0,
      courseViews: (json['courseViews'] as num?)?.toInt() ?? 0,
      scholarshipApplications:
          (json['scholarshipApplications'] as num?)?.toInt() ?? 0,
      totalApplications: (json['totalApplications'] as num?)?.toInt() ?? 0,
      comparisons: (json['comparisons'] as num?)?.toInt() ?? 0,
      searchAppearances: (json['searchAppearances'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProfileViewsBreakdown {
  const ProfileViewsBreakdown({
    required this.current,
    required this.previous,
    this.trend,
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.allTime,
  });

  final int current;
  final int previous;
  final double? trend;
  final int today;
  final int thisWeek;
  final int thisMonth;
  final int allTime;

  factory ProfileViewsBreakdown.fromJson(Map<String, dynamic> json) {
    return ProfileViewsBreakdown(
      current: (json['current'] as num?)?.toInt() ?? 0,
      previous: (json['previous'] as num?)?.toInt() ?? 0,
      trend: (json['trend'] as num?)?.toDouble(),
      today: (json['today'] as num?)?.toInt() ?? 0,
      thisWeek: (json['thisWeek'] as num?)?.toInt() ?? 0,
      thisMonth: (json['thisMonth'] as num?)?.toInt() ?? 0,
      allTime: (json['allTime'] as num?)?.toInt() ?? 0,
    );
  }
}

class StudentInterestData {
  const StudentInterestData({
    required this.total,
    required this.newThisWeek,
    required this.newThisMonth,
  });

  final int total;
  final int newThisWeek;
  final int newThisMonth;

  factory StudentInterestData.fromJson(Map<String, dynamic> json) {
    return StudentInterestData(
      total: (json['total'] as num?)?.toInt() ?? 0,
      newThisWeek: (json['newThisWeek'] as num?)?.toInt() ?? 0,
      newThisMonth: (json['newThisMonth'] as num?)?.toInt() ?? 0,
    );
  }
}

class FavouritesAnalyticsData {
  const FavouritesAnalyticsData({
    required this.total,
    required this.newInPeriod,
    required this.trend,
  });

  final int total;
  final int newInPeriod;
  final List<MonthlyTrendPoint> trend;

  factory FavouritesAnalyticsData.fromJson(Map<String, dynamic> json) {
    return FavouritesAnalyticsData(
      total: (json['total'] as num?)?.toInt() ?? 0,
      newInPeriod: (json['newInPeriod'] as num?)?.toInt() ?? 0,
      trend: ((json['trend'] as List?) ?? const [])
          .map((item) =>
              MonthlyTrendPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CoursesAnalyticsData {
  const CoursesAnalyticsData({
    required this.total,
    required this.totalViews,
    required this.mostViewed,
    required this.popularCourses,
  });

  final int total;
  final int totalViews;
  final List<CourseAnalyticsItem> mostViewed;
  final List<CourseAnalyticsItem> popularCourses;

  factory CoursesAnalyticsData.fromJson(Map<String, dynamic> json) {
    return CoursesAnalyticsData(
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      mostViewed: ((json['mostViewed'] as List?) ?? const [])
          .map((item) =>
              CourseAnalyticsItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      popularCourses: ((json['popularCourses'] as List?) ?? const [])
          .map((item) =>
              CourseAnalyticsItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ScholarshipsAnalyticsData {
  const ScholarshipsAnalyticsData({
    required this.total,
    required this.active,
    required this.applications,
    required this.periodApplications,
    required this.performance,
  });

  final int total;
  final int active;
  final int applications;
  final int periodApplications;
  final List<ScholarshipPerformanceItem> performance;

  factory ScholarshipsAnalyticsData.fromJson(Map<String, dynamic> json) {
    return ScholarshipsAnalyticsData(
      total: (json['total'] as num?)?.toInt() ?? 0,
      active: (json['active'] as num?)?.toInt() ?? 0,
      applications: (json['applications'] as num?)?.toInt() ?? 0,
      periodApplications: (json['periodApplications'] as num?)?.toInt() ?? 0,
      performance: ((json['performance'] as List?) ?? const [])
          .map((item) => ScholarshipPerformanceItem.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ApplicationStatusData {
  const ApplicationStatusData({
    required this.pending,
    required this.underReview,
    required this.shortlisted,
    required this.approved,
    required this.rejected,
  });

  final int pending;
  final int underReview;
  final int shortlisted;
  final int approved;
  final int rejected;

  int get total => pending + underReview + shortlisted + approved + rejected;

  factory ApplicationStatusData.fromJson(Map<String, dynamic> json) {
    return ApplicationStatusData(
      pending: (json['pending'] as num?)?.toInt() ?? 0,
      underReview: (json['underReview'] as num?)?.toInt() ?? 0,
      shortlisted: (json['shortlisted'] as num?)?.toInt() ?? 0,
      approved: (json['approved'] as num?)?.toInt() ?? 0,
      rejected: (json['rejected'] as num?)?.toInt() ?? 0,
    );
  }
}

class ComparisonActivityData {
  const ComparisonActivityData({required this.selectedCount});

  final int selectedCount;

  factory ComparisonActivityData.fromJson(Map<String, dynamic> json) {
    return ComparisonActivityData(
      selectedCount: (json['selectedCount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SearchDiscoveryData {
  const SearchDiscoveryData({
    required this.searchAppearances,
    required this.profileViews,
    required this.rate,
  });

  final int searchAppearances;
  final int profileViews;
  final double rate;

  factory SearchDiscoveryData.fromJson(Map<String, dynamic> json) {
    return SearchDiscoveryData(
      searchAppearances: (json['searchAppearances'] as num?)?.toInt() ?? 0,
      profileViews: (json['profileViews'] as num?)?.toInt() ?? 0,
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class AnalyticsTrendsData {
  const AnalyticsTrendsData({
    required this.profileViews,
    required this.scholarshipApplications,
    required this.courseViews,
  });

  final List<DailyTrendPoint> profileViews;
  final List<DailyTrendPoint> scholarshipApplications;
  final List<DailyTrendPoint> courseViews;

  factory AnalyticsTrendsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsTrendsData(
      profileViews: ((json['profileViews'] as List?) ?? const [])
          .map((item) => DailyTrendPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      scholarshipApplications:
          ((json['scholarshipApplications'] as List?) ?? const [])
              .map((item) =>
                  DailyTrendPoint.fromJson(item as Map<String, dynamic>))
              .toList(),
      courseViews: ((json['courseViews'] as List?) ?? const [])
          .map((item) => DailyTrendPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class UniversityAnalyticsData {
  const UniversityAnalyticsData({
    required this.range,
    required this.overview,
    required this.profileViews,
    required this.studentInterest,
    required this.favourites,
    required this.courses,
    required this.scholarships,
    required this.applicationStatus,
    required this.comparisonActivity,
    required this.searchDiscovery,
    required this.trends,
  });

  final String range;
  final AnalyticsOverview overview;
  final ProfileViewsBreakdown profileViews;
  final StudentInterestData studentInterest;
  final FavouritesAnalyticsData favourites;
  final CoursesAnalyticsData courses;
  final ScholarshipsAnalyticsData scholarships;
  final ApplicationStatusData applicationStatus;
  final ComparisonActivityData comparisonActivity;
  final SearchDiscoveryData searchDiscovery;
  final AnalyticsTrendsData trends;

  factory UniversityAnalyticsData.fromJson(Map<String, dynamic> json) {
    return UniversityAnalyticsData(
      range: (json['range'] ?? '30d').toString(),
      overview: AnalyticsOverview.fromJson(
        json['overview'] as Map<String, dynamic>? ?? {},
      ),
      profileViews: ProfileViewsBreakdown.fromJson(
        json['profileViews'] as Map<String, dynamic>? ?? {},
      ),
      studentInterest: StudentInterestData.fromJson(
        json['studentInterest'] as Map<String, dynamic>? ?? {},
      ),
      favourites: FavouritesAnalyticsData.fromJson(
        json['favourites'] as Map<String, dynamic>? ?? {},
      ),
      courses: CoursesAnalyticsData.fromJson(
        json['courses'] as Map<String, dynamic>? ?? {},
      ),
      scholarships: ScholarshipsAnalyticsData.fromJson(
        json['scholarships'] as Map<String, dynamic>? ?? {},
      ),
      applicationStatus: ApplicationStatusData.fromJson(
        json['applicationStatus'] as Map<String, dynamic>? ?? {},
      ),
      comparisonActivity: ComparisonActivityData.fromJson(
        json['comparisonActivity'] as Map<String, dynamic>? ?? {},
      ),
      searchDiscovery: SearchDiscoveryData.fromJson(
        json['searchDiscovery'] as Map<String, dynamic>? ?? {},
      ),
      trends: AnalyticsTrendsData.fromJson(
        json['trends'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

