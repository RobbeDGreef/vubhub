/// Handles information exchange with other objects
class InfoHandler {
  // Variables:
  //   Crawler object
  //   Cache object
  // Functions:
  //   getWeekData(int week)
  //   getUserEduType()
  //     ...
  //   setuserEduType()
  //     ...

  Crawler _crawler;
  Cache _cache;

  int _userColor;
  String _userEduType;
  String _userFac;
  String _userEdu;

  void initCrawler() async {
    await loadUserInfo();
    _crawler = Crawler(id: getUserId());
  }

  InfoHandler() {
    _cache = Cache();

    // The crawler initialisation has go be called after loadUserInfo()
    // meaning we have to do this in a seperate async function
    initCrawler();
  }

  String getUserId() => EducationData[this._userEduType][this._userFac][this._userEdu];
  String getUserEduType() => this._userEduType;
  int getUserColor() => this._userColor;

  void setUserColor(int color) {
    this._userColor = color;
    this._cache.storeInt("userColor", this._userColor);
  }

  void setUserEduType(String edu) {
    this._userEduType = edu;
    this._cache.storeString("userEduType", edu);
  }

  void setUserEdu(String edu) {
    this._userEdu = edu;
    this._cache.storeString("userEdu", edu);
  }

  void setUserFac(String fac) {
    this._userFac = fac;
    this._cache.storeString("userFac", fac);
  }

  Future<void> loadUserInfo() async {
    this._userColor = await _cache.tryToLoadInt("userColor", DefaultUserColor);
    this._userEduType = await _cache.tryToLoadString("userEduType", DefaultUserEduType);
    this._userFac = await _cache.tryToLoadString("userFac", DefaultUserFac);
    this._userEdu = await _cache.tryToLoadString("userEdu", DefaultUserEdu);
  }

  Future<List<Lecture>> getWeekData(int week) async {
    if (week == -1) {
      week = calcWeekFromDate(DateTime.now());
    }

    List<Lecture> data = _cache.getWeekData(week);
    if (data == null) {
      data = parseLectureList(await _crawler.getWeekData(week), week);
      _cache.populateWeekData(week, data);
    }

    return data;
  }

  Future<List<Lecture>> getClassesOfDay(DateTime day) async {
    DateTime toDay = DateTime(day.year, day.month, day.day);
    List<Lecture> list = List();

    for (Lecture lec in await getWeekData(-1)) {
      DateTime classDay = DateTime(lec.start.year, lec.start.month, lec.start.day);
      if (classDay == toDay) {
        list.add(lec);
      }
    }
    return list;
  }

  DateTime calcStartDate() {
    // TODO: URGENT: we need a way to calculate the year start date because this will
    // change every year.
    return DateTime(2020, 9, 14);
  }

  DateTime calcDateFromWeek(int week) {
    return calcStartDate().add(Duration(days: 7 * (week - 1)));
  }

  int calcWeekFromDate(DateTime date) {
    DateTime start = calcStartDate();
    DateTime thisWeekStart = date.subtract(Duration(days: date.weekday - 1));
    return thisWeekStart.difference(start).inDays ~/ 7 + 1;
  }

  bool isUserAllowed(int color) {
    return color == this._userColor;
  }

  void forceCacheUpdate() {
    _cache.doForcedCacheUpdate();
  }

  String colorIntToString(int color) {
    if (color == 1)
      return "orange";
    else
      return "blue";
  }

  int colorStringToInt(String color) {
    if (color == "orange")
      return 1;
    else
      return 0;
  }
}
