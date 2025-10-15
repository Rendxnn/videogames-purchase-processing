function transform(line) {
  var o = JSON.parse(line);
  if (o.event_ts) {
    var d = new Date(o.event_ts);
    var yyyy = d.getUTCFullYear();
    var mm = String(d.getUTCMonth() + 1).padStart(2, '0');
    var dd = String(d.getUTCDate()).padStart(2, '0');
    o.event_date = yyyy + "-" + mm + "-" + dd;
  }
  return o;
}
