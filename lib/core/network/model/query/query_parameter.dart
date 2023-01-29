abstract class QueryParameter<T> {
  final String queryName;
  final T queryValue;

  QueryParameter(this.queryName, this.queryValue);
}

class BooleanQueryParameter extends QueryParameter<bool> {
  BooleanQueryParameter(String queryName, bool queryValue) : super(queryName, queryValue);
}

class StringQueryParameter extends QueryParameter<String> {
  StringQueryParameter(String queryName, String queryValue) : super(queryName, queryValue);
}

class IntQueryParameter extends QueryParameter<int> {
  IntQueryParameter(String queryName, int queryValue) : super(queryName, queryValue);
}

extension ListQueryParameterExtension on List<QueryParameter?> {
  Map<String, dynamic> toMap() => { for (var data in this) if (data != null) data.queryName : data.queryValue };
}