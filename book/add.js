// Generated by CoffeeScript 1.10.0
var astro, buildtimeline, chrono, component, defaultnames, dom, hub, inject, moment, nicedate, odoql, ql, ref, route, shortdate, simpledate;

ref = require('odojs'), component = ref.component, hub = ref.hub, dom = ref.dom;

inject = require('injectinto');

moment = require('moment-timezone');

chrono = require('chronological');

moment = chrono(moment);

astro = require('./astro');

route = require('odo-route');

odoql = require('odoql/odojs');

component.use(odoql);

buildtimeline = require('./buildtimeline');

defaultnames = require('./defaultnames');

ql = require('odoql');

ql = ql.use('store');

nicedate = 'dddd D MMMM YYYY';

shortdate = 'ddd D MMMM';

simpledate = 'YYYY-MM-DD';

route('/addbooking/:start/:end', function(p) {
  return {
    page: 'add',
    start: p.params.start,
    end: p.params.end
  };
});

inject.bind('page:add', component({
  query: function(state, params) {
    return {
      bookings: ql.store('bookings')
    };
  },
  render: function(state, params, hub) {
    var addBooking, cancelRename, childparams, edited, editing, keydown, keyup, ref1, rename, toggle;
    editing = (ref1 = params != null ? params.editing : void 0) != null ? ref1 : 'name';
    edited = params != null ? params.edited : void 0;
    if (edited == null) {
      edited = {
        name: '',
        start: moment(params.start),
        end: moment(params.end)
      };
    }
    childparams = {
      selectedRange: {
        start: edited.start,
        end: edited.end
      }
    };
    if (editing === 'start') {
      childparams.selectedDate = edited.start;
    } else if (editing === 'end') {
      childparams.selectedDate = edited.end;
    }
    toggle = function(key) {
      return function(e) {
        var value;
        e.preventDefault();
        value = key;
        if (editing === value) {
          value = 'nothing';
        }
        return hub.emit('update', {
          editing: value
        });
      };
    };
    addBooking = function(e) {
      e.preventDefault();
      return hub.emit('add booking', edited);
    };
    cancelRename = function(e) {
      e.preventDefault();
      return hub.emit('update', {
        editing: 'nothing'
      });
    };
    keydown = function(e) {
      if (e.which === 13) {
        return e.preventDefault();
      }
    };
    keyup = function(e) {
      var name;
      name = e.target.value;
      name = name.replace(/[\r\n\v]+/g, '');
      e.target.value = name;
      return hub.emit('update', {
        name: name,
        edited: edited
      });
    };
    rename = function(e) {
      e.preventDefault();
      if ((params != null ? params.name : void 0) != null) {
        edited.name = params.name;
      }
      edited.name = edited.name.replace(/\s{2,}/g, ' ').trim();
      return hub.emit('update', {
        edited: edited,
        editing: 'start',
        name: null
      });
    };
    return dom('.grid.main', [
      dom('.scroll.right', [
        dom('h1', 'Bookings for the Tauranga House'), astro(state, childparams, hub.child({
          select: function(p, cb) {
            cb();
            if (editing === 'start') {
              edited.start = p;
              if (edited.end.isBefore(edited.start)) {
                edited.end = edited.start;
              }
              return hub.emit('update', {
                edited: edited,
                editing: 'end'
              });
            } else if (editing === 'end') {
              edited.end = p;
              if (edited.start.isAfter(edited.end)) {
                edited.start = edited.end;
              }
              return hub.emit('update', {
                edited: edited,
                editing: 'nothing'
              });
            }
          }
        }))
      ]), dom('.scroll', [
        params.deleting ? [
          dom('h2', edited.name), dom('.grid', [dom('.booking.selection', [dom('.booking-dates', [dom('small', 'ARRIVE'), ' ⋅ ', edited.start.format(nicedate)])]), dom('.booking.selection', [dom('.booking-dates', [dom('small', 'LEAVE'), ' ⋅ ', edited.end.format(nicedate)])])]), dom('.actions', [
            dom('a.action.danger', {
              onclick: confirmDeleteBooking,
              attributes: {
                href: '#'
              }
            }, '⌫  Delete'), dom('a.action', {
              onclick: cancelDeleteBooking,
              attributes: {
                href: '#'
              }
            }, '⤺  Cancel')
          ])
        ] : editing === 'name' ? [
          dom('textarea', {
            onkeydown: keydown,
            onkeyup: keyup,
            attributes: {
              autofocus: 'autofocus',
              name: 'name',
              autocomplete: 'off',
              autocorrect: 'off',
              autocapitalize: 'on',
              spellcheck: 'false',
              placeholder: 'Enter name or select below…'
            }
          }, edited.name), dom('ul.defaultnames', defaultnames.map(function(name) {
            var choosename;
            choosename = function(e) {
              e.preventDefault();
              edited.name = name;
              return hub.emit('update', {
                edited: edited,
                editing: 'start',
                name: null
              });
            };
            return dom('li', dom('a', {
              onclick: choosename,
              attributes: {
                href: '#'
              }
            }, name));
          })), dom('.actions', [
            dom('a.action', {
              onclick: cancelRename,
              attributes: {
                href: '#'
              }
            }, '⤺  Cancel'), ((params != null ? params.name : void 0) != null) && params.name.replace(/\s{2,}/g, ' ').trim() !== edited.name ? dom('a.action.primary', {
              onclick: rename,
              attributes: {
                href: '#'
              }
            }, '✓  Change') : void 0
          ])
        ] : [
          dom('h2', dom('a', {
            onclick: toggle('name'),
            attributes: {
              href: '#'
            }
          }, [edited.name, dom('small', 'CHANGE NAME')])), dom('.grid', [
            dom("a.booking.selection" + (editing === 'start' ? '.selected' : ''), {
              onclick: toggle('start'),
              attributes: {
                href: '#'
              }
            }, [dom('.booking-dates', [dom('small', 'ARRIVE'), ' ⋅ ', edited.start.format(nicedate)])]), dom("a.booking.selection" + (editing === 'end' ? '.selected' : ''), {
              onclick: toggle('end'),
              attributes: {
                href: '#'
              }
            }, [dom('.booking-dates', [dom('small', 'LEAVE'), ' ⋅ ', edited.end.format(nicedate)])])
          ]), editing === 'start' ? [
            dom('h2', '← Select arrival date'), dom('.actions', dom('a.action', {
              onclick: toggle('end'),
              attributes: {
                href: '#'
              }
            }, 'Next  →'))
          ] : editing === 'end' ? [
            dom('h2', '← Select leaving date'), dom('.actions', dom('a.action', {
              onclick: toggle('nothing'),
              attributes: {
                href: '#'
              }
            }, 'Next  →'))
          ] : editing === 'nothing' ? dom('.actions', [
            dom('a.action', {
              attributes: {
                href: '/'
              }
            }, '⤺  Cancel'), dom('a.action.primary', {
              onclick: addBooking,
              attributes: {
                href: '#'
              }
            }, '＋  Add booking')
          ]) : void 0
        ]
      ])
    ]);
  }
}));
