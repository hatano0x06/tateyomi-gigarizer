const String typeAdd     = "add";
const String typeEdit    = "edit";
const String typeDelete  = "delete";
class HistoryData{
  late String type;
  late dynamic data;

  HistoryData(
    this.type,
    this.data,
  );
}