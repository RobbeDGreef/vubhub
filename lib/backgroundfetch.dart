import 'package:f_logs/model/flog/flog.dart';
import 'package:workmanager/workmanager.dart';

import 'crawler.dart';
import 'parser.dart';
import 'infohandler.dart';
import 'event.dart';

Future backgroundFetch(String curId, int week, List<dynamic> groups, String path) async {
  Crawler crawler = Crawler();
  crawler.curId = curId;
  await crawler.updateConnection();

  var groupIds = crawler.getDepartmentGroups();

  int i = 0;
  for (String group in groups) {
    var unparsed = await crawler.getWeekData(week, groupIds[group]);
    var data = parseLectureList(unparsed, week);

    String content = "";
    for (Event ev in data) content += ev.toString() + '\n';
    Storage.writeFile("$path-$week-${groupIds[group]}", content);
    i++;
  }
}

void registerPeriodic(Duration d, InfoHandler info, [waitForNextUpdate = true]) {
  try {
    Workmanager.cancelByUniqueName("UpdateLectureView");
  } catch (e) {
    FLog.error(text: "Could not cancel UpdateLectureView periodic workmanager ($e)");
  }
  print("register");
  if (d != Duration.zero) {
    Map<String, dynamic> inputData = {
      'curId': info.getUserId(),
      'groups': info.user.selectedGroups,
      'path': "${info.user.educationType}-${info.user.faculty}-${info.user.education}"
          .replaceAll(' ', ''),
    };
    Workmanager.registerPeriodicTask(
      "UpdateLectureView",
      "UpdateLectureView",
      frequency: d,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      initialDelay: waitForNextUpdate ? d : Duration.zero,
      inputData: inputData,
    );
  }
}
