// Generated by CoffeeScript 1.10.0
var astro, chrono, component, dom, get, hub, inject, moment, nicedate, odoql, page, ql, ref, request, res, route, set, shortdate, simpledate;

ref = require('odojs'), component = ref.component, hub = ref.hub, dom = ref.dom;

inject = require('injectinto');

moment = require('moment-timezone');

chrono = require('chronological');

moment = chrono(moment);

astro = require('./astro');

route = require('odo-route');

odoql = require('odoql/odojs');

page = require('page');

request = require('superagent');

component.use(odoql);

ql = require('odoql');

ql = ql.use('store').use({
  params: {
    localstore: true
  }
});

get = function(key) {
  var error;
  try {
    return JSON.parse(localStorage.getItem(key));
  } catch (error) {
    return null;
  }
};

set = function(key, value) {
  return localStorage.setItem(key, JSON.stringify(value));
};

nicedate = 'dddd D MMMM YYYY';

shortdate = 'ddd D MMMM';

simpledate = 'YYYY-MM-DD';

require('./add');

require('./view');

module.exports = function(hub, scene, localstore) {
  hub.every('select date', function(p, cb) {
    cb();
    set('selectedDate', p);
    scene.refreshQueries(['selectedDate']);
    return hub.emit('update');
  });
  localstore.use('selectedDate', function(params, cb) {
    return cb(null, get('selectedDate'));
  });
  hub.every('add booking', function(p, cb) {
    var payload;
    payload = {
      name: p.name,
      start: moment(p.start).format(simpledate),
      end: moment(p.end).format(simpledate)
    };
    return request.post('/v0/addbooking').send(payload).end(function(err, res) {
      if (err != null) {
        alert(err);
        return;
      }
      if (!res.ok) {
        alert(res.text);
        return;
      }
      scene.refreshQueries(['bookings']);
      return page("/booking/" + p.id);
    });
  });
  hub.every('delete booking', function(p, cb) {
    return request.post('/v0/deletebooking').send({
      id: p.id
    }).end(function(err, res) {
      if (err != null) {
        alert(err);
        return;
      }
      if (!res.ok) {
        alert(res.text);
        return;
      }
      scene.refreshQueries(['bookings']);
      return page('/');
    });
  });
  return hub.every('change booking', function(p, cb) {
    var payload;
    payload = {
      id: p.id,
      name: p.name,
      start: moment(p.start).format(simpledate),
      end: moment(p.end).format(simpledate)
    };
    return request.post('/v0/changebooking').send(payload).end(function(err, res) {
      if (err != null) {
        alert(err);
        return;
      }
      if (!res.ok) {
        alert(res.text);
        return;
      }
      scene.refreshQueries(['bookings']);
      return page("/booking/" + p.id);
    });
  });
};

route('/', function(p) {
  return {
    page: 'list'
  };
});

res = component({
  query: function(state, params) {
    return {
      bookings: ql.store('bookings'),
      selectedDate: ql.localstore('selectedDate')
    };
  },
  render: function(state, params, hub) {
    var childparams, date, ids, ref1, ref2, ref3, today;
    today = moment().startOf('d');
    childparams = {
      selectedDate: (ref1 = state != null ? state.selectedDate : void 0) != null ? ref1 : today.format(simpledate)
    };
    date = moment(childparams.selectedDate);
    ids = (ref2 = (ref3 = state.bookings.timeline[childparams.selectedDate]) != null ? ref3.ids : void 0) != null ? ref2 : [];
    return dom('.grid.main', [
      dom('.scroll.right', [
        dom('h1', 'Bookings for the Tauranga House'), astro(state, childparams, hub.child({
          select: function(p, cb) {
            cb();
            return hub.emit('select date', p.format(simpledate));
          }
        }))
      ]), dom('.scroll', [
        dom('h2', date.format(nicedate)), dom('.bookings', ids.map(function(id) {
          var bookingend, bookingstart, e;
          e = state.bookings.events[id];
          bookingstart = moment(e.start);
          bookingend = moment(e.end);
          return dom('a.booking', {
            attributes: {
              href: "/booking/" + e.id
            }
          }, [dom('.booking-title', [e.name, date.isSame(bookingstart) ? bookingstart.isSame(bookingend) ? ' visiting' : ' arriving' : date.isSame(bookingend) ? ' leaving' : ' staying']), dom('.booking-dates', (bookingstart.format(shortdate)) + " — " + (bookingend.format(shortdate)))]);
        })), dom('.actions', dom('a.action', {
          attributes: {
            href: "/addbooking/" + childparams.selectedDate + "/" + (date.clone().add(2, 'd').format(simpledate)) + "/"
          }
        }, '＋  Add Booking'))
      ])
    ]);
  }
});

inject.bind('page:list', res);

inject.bind('page:default', res);
