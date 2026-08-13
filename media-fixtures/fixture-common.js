(function () {
  var v = document.getElementById('v');
  var s = document.getElementById('s');
  var t0 = performance.now();
  var tag = document.body.getAttribute('data-tag') || 'x';
  function beacon(ev) { try { fetch('/b-' + tag + '-' + ev, { mode: 'no-cors' }); } catch (e) {} }
  v.onplaying = function () { s.textContent = 'PLAYING after ' + Math.round(performance.now() - t0) + 'ms'; beacon('playing'); };
  v.onwaiting = function () { s.textContent = 'WAITING...'; beacon('waiting'); };
  v.onpause = function () { s.textContent = 'PAUSED'; beacon('paused'); };
  v.onerror = function () { s.textContent = 'ERROR: ' + (v.error && v.error.code); beacon('err' + (v.error && v.error.code)); };
  v.onended = function () { beacon('ended'); };
  setInterval(function () {
    beacon('t=' + Math.round(v.currentTime * 10) + '/' + v.readyState + (v.paused ? '/p' : '/r'));
  }, 2000);
})();
