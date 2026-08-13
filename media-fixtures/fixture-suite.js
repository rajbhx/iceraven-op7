(function () {
  var s = document.getElementById('s');
  var t0 = performance.now();
  var videos = Array.prototype.slice.call(document.querySelectorAll('video[data-tag]'));
  function beacon(tag, ev) { try { fetch('/s-' + tag + '-' + ev, { mode: 'no-cors' }); } catch (e) {} }
  videos.forEach(function (v) {
    var tag = v.getAttribute('data-tag');
    v.onplaying = function () { s.textContent = 'PLAYING: ' + tag.toUpperCase() + (v.muted ? ' (muted)' : ' (sound)'); beacon(tag, 'playing' + (v.muted ? '-muted' : '')); };
    v.onwaiting = function () { beacon(tag, 'waiting'); };
    v.onerror = function () { s.textContent = 'ERROR: ' + tag.toUpperCase() + ' code ' + (v.error && v.error.code); beacon(tag, 'err' + (v.error && v.error.code)); };
    setInterval(function () { beacon(tag, 't=' + Math.round(v.currentTime * 10) + '/' + v.readyState + (v.paused ? '/p' : '/r')); }, 2000);
  });
  var taps = 0;
  document.addEventListener('click', function () {
    taps++;
    s.textContent = 'TAP ' + taps + ' -> enabling sound...';
    videos.forEach(function (v) { v.muted = false; v.play().catch(function () {}); });
  }, true);
})();
