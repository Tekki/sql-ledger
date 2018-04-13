Vue.component('v-select', VueSelect.VueSelect);
Vue.filter('date', function(value, dateformat) {
  if (value) {
    if (!(typeof value === 'Date')) {
      value = new Date(value);
    }
    var year = String(value.getFullYear());
    var month = String(value.getMonth() + 1).padStart(2, '0');
    var day = String(value.getDate()).padStart(2, '0');
    var rv = dateformat.replace(/y+/i, year)
      .replace(/m+/i, month)
      .replace(/d+/i, day);
    return rv;
  }
});
Vue.filter('number', function(value, precision) {
  console.log(precision);
  if (value) {
    return value.toLocaleString(undefined, precision);
  }
});
